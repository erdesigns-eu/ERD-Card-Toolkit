program Msr206Tests;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe,
  ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR206;

type
  TExchange = record
    Command, Reply: TBytes;
  end;
  TScriptPort = class(TInterfacedObject, IMagStripeSerialPort)
  private
    FScript: array of TExchange;
    FStep, FReplyOffset: Integer;
    FOpenCount, FCloseCount, FDiscardCount, FSends, FReceives: Integer;
    FFailSend, FFailReceive: Integer;
    FOpenFail, FCloseFail, FResetFail, FOpen, FClockBackwards: Boolean;
    FClock, FTickPerByte: UInt64;
    FDeadlines: array of Cardinal;
    FComponent: TMagStripeReaderWriter;
    procedure Add(const ACommandHex, AReplyHex: string);
    procedure Setup(const AProfile: TMsr206Profile);
    procedure Open;
    procedure Close;
    procedure DiscardInput;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
  end;

type
  TSelectionDevice = class(TInterfacedObject, IMagStripeDevice, IMagStripeStatusWriter)
  private
    FSelection: TMagStripeWriteSelection;
    FExpected: TMagStripeTrackSet;
    FAcquires, FReleases, FPrograms: Integer;
    function GetCapabilities: TMagStripeCapabilities;
    function GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
    procedure Acquire;
    procedure Release;
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
  end;

var
  Assertions: Integer;

procedure Check(const ACondition: Boolean; const AText: string);
begin
  Inc(Assertions);
  if not ACondition then raise Exception.Create(AText);
end;

function DataFixture: TMagStripeTracks;
begin
  Result[mstTrack1] := '01'; Result[mstTrack2] := '23'; Result[mstTrack3] := '45';
end;

procedure TScriptPort.Add(const ACommandHex, AReplyHex: string);
var
  N: Integer;
begin
  N := Length(FScript);
  SetLength(FScript, N + 1);
  FScript[N].Command := HexToBytes(ACommandHex);
  FScript[N].Reply := HexToBytes(AReplyHex);
end;

procedure TScriptPort.Setup(const AProfile: TMsr206Profile);
begin
  Add('1B61', ''); Add('1B65', '1B79'); Add('1B74', '1B3353');
  Add('1B6F070505', '1B30070505'); Add('1B624B', '1B30');
  if AProfile = msrp605ThreeTrack then begin Add('1B62A1', '1B30'); Add('1B62C1', '1B30'); end;
end;

procedure TScriptPort.Open;
begin
  Inc(FOpenCount);
  Check(not FOpen, 'One exclusive channel open');
  if FOpenFail then raise EMagStripeError.Create('Open primary');
  FOpen := True;
end;

procedure TScriptPort.Close;
begin
  Inc(FCloseCount);
  Check(FOpen, 'Close owned channel');
  FOpen := False;
  if FCloseFail then raise EMagStripeError.Create('Close secondary');
end;

procedure TScriptPort.DiscardInput;
begin
  Inc(FDiscardCount);
  Check(FOpen, 'Discard only acquired input');
end;

procedure TScriptPort.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
var
  Raised: Boolean;
  N: Integer;
  Scratch: TMagStripeTracks;
begin
  Check(FOpen, 'Send only acquired channel');
  Inc(FSends);
  Check((ATimeoutMs >= 1) and (ATimeoutMs <= 600000), 'Positive bounded remaining deadline');
  N := Length(FDeadlines); SetLength(FDeadlines, N + 1); FDeadlines[N] := ATimeoutMs;
  if ATimeoutMs = 500 then
  begin
    Check(BytesToHex(ABytes) = '1B61', 'Cleanup is reset only, never a replay');
    if FResetFail then raise EMagStripeError.Create('Reset primary');
    Exit;
  end;
  Check(FStep < Length(FScript), 'No extra protocol sends');
  if FStep > 0 then Check(FReplyOffset = Length(FScript[FStep - 1].Reply), 'Previous reply consumed before new command');
  Check(BytesEqual(ABytes, FScript[FStep].Command), 'Exact published command sequence');
  Inc(FStep);
  FReplyOffset := 0;
  if FComponent <> nil then
  begin
    Check(FComponent.Busy, 'Component busy during actual protocol I/O');
    Raised := False;
    try Scratch := FComponent.ReadTracks([mstTrack2]);
    except on E: EMagStripeError do Raised := True; end;
    Check(Raised, 'No nested operation during source callbacks');
  end;
  if FFailSend = FSends then raise EMagStripeError.Create('secret partial transport send');
end;

function TScriptPort.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
begin
  Inc(FReceives);
  Check(FOpen and (FStep > 0), 'Receive only after a command');
  Check(ATimeoutMs > 0, 'No receive with expired deadline');
  if FFailReceive = FReceives then raise EMagStripeError.Create('secret receive primary');
  Check(FReplyOffset < Length(FScript[FStep - 1].Reply), 'No extra reply reads');
  Result := FScript[FStep - 1].Reply[FReplyOffset];
  Inc(FReplyOffset);
  Inc(FClock, FTickPerByte);
end;

function TScriptPort.NowMs: UInt64;
begin
  Result := FClock;
  if FClockBackwards and (FReceives > 0) then Result := 0;
end;

procedure CodecTests;
var
  D, R: TMagStripeTracks;
  B, Bad: TBytes;
  I, J: Integer;
  Raised: Boolean;
begin
  D := DataFixture;
  // PM017-U Rev G section 8 independent literal write/read examples.
  B := HexToBytes('1B771B731B0130311B0232331B0334353F1C');
  Check(BytesEqual(TMsr206Codec.WriteCommand(D), B), 'Published 01/23/45 write vector');
  B := HexToBytes('1B731B012530313F1B023B32333F1B033B34353F3F1C1B30');
  R := TMsr206Codec.DecodeRead(B, [mstTrack1, mstTrack2, mstTrack3]);
  Check((R[mstTrack1] = '01') and (R[mstTrack2] = '23') and (R[mstTrack3] = '45'), 'Published independent read vector');
  R := TMsr206Codec.DecodeRead(B, [mstTrack2]);
  Check((R[mstTrack1] = '') and (R[mstTrack2] = '23') and (R[mstTrack3] = ''), 'Physical selection without mirroring');
  R := TMsr206Codec.DecodeRead(HexToBytes('1B731B011B023B32333F3F1C1B30'), [mstTrack1, mstTrack2, mstTrack3]);
  Check((R[mstTrack1] = '') and (R[mstTrack2] = '23') and (R[mstTrack3] = ''), 'Empty field and omitted field');
  R := TMsr206Codec.DecodeRead(HexToBytes('1B733F1C1B30'), [mstTrack2]);
  Check(R[mstTrack2] = '', 'Blank data block');
  Check(TMsr206Codec.DecodeSuccess(HexToBytes('1B30')) = $30, 'Raw success is status, not read-back');
  for I := 0 to Length(B) - 1 do
  begin
    Raised := False;
    try R := TMsr206Codec.DecodeRead(Copy(B, 0, I), [mstTrack2]);
    except on E: EMagStripeError do Raised := True;
      on E: EMagStripeFormatError do Raised := True;
    end;
    Check(Raised, 'All read frame truncations');
  end;
  for I := 0 to 15 do
  begin
    Bad := CopyBytes(B);
    Raised := False;
    try
      case I of
        0: Bad[0] := 0;
        1: Bad[1] := $72;
        2: Bad[3] := 0;
        3: Bad[3] := 4;
        4: Bad[9] := 1;
        5: Bad[15] := 2;
        6: Bad[4] := $3B;
        7: Bad[11] := $2B;
        8: Bad[18] := $2B;
        9: Bad[7] := 0;
        10: Bad[Length(Bad) - 4] := 0;
        11: Bad[Length(Bad) - 3] := 0;
        12: Bad[Length(Bad) - 2] := 0;
        13: Bad[Length(Bad) - 1] := $31;
        14: begin SetLength(Bad, Length(Bad) + 1); Bad[Length(Bad) - 1] := 0; end;
        15: Bad := nil;
      end;
      R := TMsr206Codec.DecodeRead(Bad, [mstTrack2]);
    except on E: EMagStripeError do Raised := True;
      on E: EMagStripeFormatError do Raised := True;
    end;
    Check(Raised, 'Malformed framing, duplicate/order and statuses');
  end;
  for I := 0 to 255 do
  begin
    Bad := HexToBytes('1B30'); Bad[1] := I;
    Raised := False;
    try J := TMsr206Codec.DecodeSuccess(Bad); except on E: EMagStripeError do Raised := True; end;
    Check(Raised = (I <> $30), 'All status byte values');
  end;
  D[mstTrack1] := StringOfChar('A', 76); D[mstTrack2] := StringOfChar('1', 37); D[mstTrack3] := StringOfChar('2', 104);
  B := TMsr206Codec.WriteCommand(D);
  Check(Length(B) = 229, 'Maximum write command capacity');
  Bad := HexToBytes('1B731B01');
  for I := 1 to 78 do
  begin
    J := Length(Bad); SetLength(Bad, J + 1);
    if I = 1 then Bad[J] := Ord('%') else if I = 78 then Bad[J] := Ord('?') else Bad[J] := Ord('A');
  end;
  J := Length(Bad); SetLength(Bad, J + 41); Bad[J] := $1B; Bad[J+1] := 2; Bad[J+2] := Ord(';');
  for I := 0 to 36 do Bad[J+3+I] := Ord('1'); Bad[J+40] := Ord('?');
  J := Length(Bad); SetLength(Bad, J + 108); Bad[J] := $1B; Bad[J+1] := 3; Bad[J+2] := Ord(';');
  for I := 0 to 103 do Bad[J+3+I] := Ord('2'); Bad[J+107] := Ord('?');
  J := Length(Bad); SetLength(Bad, J+4); Bad[J] := $3F; Bad[J+1] := $1C; Bad[J+2] := $1B; Bad[J+3] := $30;
  Check(Length(Bad) = 235, 'Maximum read frame capacity');
  R := TMsr206Codec.DecodeRead(Bad, [mstTrack1, mstTrack2, mstTrack3]);
  Check((Length(R[mstTrack1]) = 76) and (Length(R[mstTrack3]) = 104), 'Maximum read payloads');
  for I := 0 to 5 do
  begin
    D := DataFixture;
    if I < 3 then D[TMagStripeTrack(I)] := '' else D[TMagStripeTrack(I-3)] := 'secret';
    Raised := False;
    try B := TMsr206Codec.WriteCommand(D);
    except on E: EMagStripeError do Raised := True;
      on E: EMagStripeFormatError do Raised := True;
    end;
    Check(Raised, 'Empty/invalid input before encoding');
  end;
  Writeln('PASS: MSR206 published framing vectors, limits, selection and malformed statuses.');
end;

procedure AdapterTests;
var
  Obj: TScriptPort;
  Port: IMagStripeSerialPort;
  Device: IMagStripeDevice;
  Writer: IMagStripeStatusWriter;
  C: TMagStripeReaderWriter;
  Receipt: TMagStripeProgrammingReceipt;
  D, R: TMagStripeTracks;
  P: TMsr206Profile;
  I, Before, SendCount: Integer;
  Raised: Boolean;
begin
  for P := Low(TMsr206Profile) to High(TMsr206Profile) do
    for I := 0 to 10 do
    begin
      Obj := TScriptPort.Create; Port := Obj;
      Obj.Setup(P);
      if I = 0 then Obj.Add('1B64','1B48')
      else if I = 1 then begin Obj.Add('1B79','1B30'); Obj.Add('1B64','1B4C'); end
      else begin Obj.Add('1B78','1B30'); Obj.Add('1B64','1B48'); end;
      Obj.Add('1B771B731B0130311B0232331B0334353F1C', '1B30');
      Device := TMsr206MagStripeAdapter.Create(Port, P);
      Check(Obj.FOpenCount = 0, 'Inactive adapter constructor');
      C := TMagStripeReaderWriter.Create(nil);
      try
        C.Device := Device; C.TimeoutMs := 4321; Obj.FComponent := C;
        D := DataFixture;
        case I of
          3: Obj.FOpenFail := True;
          4: Obj.FFailSend := Length(Obj.FScript);
          5: Obj.FScript[High(Obj.FScript)].Reply := HexToBytes('1B31');
          6: Obj.FCloseFail := True;
          7: Obj.FResetFail := True;
          8: begin Obj.FResetFail := True; Obj.FCloseFail := True; end;
          9: begin D[mstTrack3] := ''; end;
          10: Obj.FScript[2].Reply := HexToBytes('1B3553');
        end;
        Raised := False;
        try
          if I = 0 then Receipt := C.ProgramTracks([mstTrack1,mstTrack2,mstTrack3],D)
          else if I = 1 then Receipt := C.ProgramTracks([mstTrack1,mstTrack2,mstTrack3],D,mscLow)
          else Receipt := C.ProgramTracks([mstTrack1,mstTrack2,mstTrack3],D,mscHigh);
        except
          on E: EMagStripeWriteUncertain do
          begin
            Raised := True;
            Check(I in [4,5,6,7,8,10], 'Only programming invocation or cleanup failures uncertain');
            Check(Pos('secret',E.Message)=0, 'No transport payload in programming errors');
          end;
          on E: EMagStripeError do begin Raised := True; Check(I in [0,3,9], 'Ordinary preflight/acquire error'); end;
        end;
        Check(Raised = ((I=0) or (I >= 3)), 'Expected programming outcome');
        Check(not C.Busy, 'Component busy cleared');
        if I in [1,2] then
        begin
          Check(not Receipt.HostReadBackVerified, 'Status receipt never masquerades as read-back');
          Check((Receipt.DeviceStatus=$30) and (Receipt.RequestedTracks=[mstTrack1,mstTrack2,mstTrack3]), 'Status and request metadata');
          Check(Obj.FStep = Length(Obj.FScript), 'Complete command chain without additional swipe');
        end;
        if I = 3 then Check((Obj.FSends=0) and (Obj.FCloseCount=0), 'Failed opening grants nothing')
        else if I in [0,9] then Check((Obj.FOpenCount=0) and (Obj.FSends=0), 'Explicit coercivity/empty input before all I/O')
        else Check(Obj.FCloseCount=1, 'Close once after acquired operation');
        Before := Obj.FOpenCount;
        Raised := False;
        D := DataFixture; D[mstTrack1] := ''; D[mstTrack3] := '';
        try Receipt := C.ProgramTracks([mstTrack2],D,mscHigh);
        except on E: EMagStripeError do Raised := True; end;
        Check(Raised and (Obj.FOpenCount=Before), 'Partial selection rejected before acquisition');
        Raised := False;
        D := DataFixture;
        try R := C.WriteTracks([mstTrack1,mstTrack2,mstTrack3],D);
        except on E: EMagStripeError do Raised := True; end;
        Check(Raised and (Obj.FOpenCount=Before), 'Status-only adapter cannot weaken verified writing');
      finally C.Free; end;
      Device := nil; Port := nil;
    end;
  for P := Low(TMsr206Profile) to High(TMsr206Profile) do
  begin
    Obj := TScriptPort.Create; Port := Obj; Obj.Setup(P);
    Obj.Add('1B72','1B731B012530313F1B023B32333F1B033B34353F3F1C1B30');
    Device := TMsr206MagStripeAdapter.Create(Port,P);
    C := TMagStripeReaderWriter.Create(nil);
    try
      C.Device := Device; C.TimeoutMs := 4321;
      R := C.ReadTracks([mstTrack2]);
      Check((R[mstTrack2]='23') and (R[mstTrack1]='') and (R[mstTrack3]=''), 'Complete reader chain');
      Check((Obj.FStep=Length(Obj.FScript)) and (Obj.FCloseCount=1), 'Read once then reset/close');
      SendCount := Obj.FSends;
      Raised := False;
      D := DataFixture;
      try Receipt := C.ProgramTracks([],D); except on E: EMagStripeError do Raised := True; end;
      Check(Raised and (Obj.FSends=SendCount), 'Empty programming selection before I/O');
    finally C.Free; end;
    Device := nil; Port := nil;
  end;
  // Direct programmer preflight and poisoned-session behavior.
  Obj := TScriptPort.Create; Port := Obj; Obj.Setup(msrp206ThreeTrackHL);
  Obj.Add('1B78','1B30'); Obj.Add('1B64','1B48');
  Obj.Add('1B771B731B0130311B0232331B0334353F1C','1B30');
  Obj.FFailSend := Length(Obj.FScript);
  Device := TMsr206MagStripeAdapter.Create(Port,msrp206ThreeTrackHL);
  Check(Supports(Device,IMagStripeStatusWriter,Writer),'Optional status writer discovered');
  Device.Acquire;
  Raised := False;
  try I := Writer.ProgramStatus([mstTrack2],DataFixture,mscHigh,4321); except on E: EMagStripeError do Raised := True; end;
  Check(Raised and (Obj.FSends=0),'Direct partial preflight sends nothing');
  Raised := False;
  try I := Writer.ProgramStatus([mstTrack1,mstTrack2,mstTrack3],DataFixture,mscHigh,4321);
  except on E: EMagStripeWriteUncertain do Raised := True; end;
  Check(Raised,'Partial physical send uncertain directly');
  Before := Obj.FSends;
  Raised := False;
  try R := Device.Read([mstTrack2],4321); except on E: EMagStripeError do Raised := True; end;
  Check(Raised and (Before=Obj.FSends),'Poisoned session cannot start another operation');
  Device.Release;
  Check(Obj.FCloseCount=1,'Poisoned release still closes');
  Writer := nil; Device := nil; Port := nil;
  Writeln('PASS: Complete MSR206/MSR605 read/program chains, status receipts and failure cleanup.');
end;

procedure DeadlineTests;
var
  Obj: TScriptPort;
  Port: IMagStripeSerialPort;
  Device: IMagStripeDevice;
  R: TMagStripeTracks;
  I, Limit, J, Before: Integer;
  Raised: Boolean;
begin
  // Every send and receive failure stops immediately, without continuing to read/write.
  for I := 0 to 41 do
  begin
    Obj := TScriptPort.Create; Port := Obj; Obj.Setup(msrp206ThreeTrackHL);
    Obj.Add('1B72','1B731B012530313F1B023B32333F1B033B34353F3F1C1B30');
    if I < 6 then Obj.FFailSend := I+1 else Obj.FFailReceive := I-5;
    Device := TMsr206MagStripeAdapter.Create(Port,msrp206ThreeTrackHL);
    Device.Acquire;
    Raised := False;
    try R := Device.Read([mstTrack2],4321); except on E: EMagStripeError do Raised := True; end;
    Check(Raised,'Each protocol send/receive failure stops');
    if I < 6 then Check(Obj.FSends=I+1,'No sends after send failure')
    else Check(Obj.FReceives=I-5,'No receives after receive failure');
    Before := Obj.FSends;
    Raised := False;
    try R := Device.Read([mstTrack2],4321); except on E: EMagStripeError do Raised := True; end;
    Check(Raised and (Obj.FSends=Before),'No reuse or replay after failed receive');
    Device.Release;
    Check(Obj.FSends=Before+1,'Only cleanup reset after failure');
    Device := nil; Port := nil;
  end;
  // Preparation consumes twelve response bytes; a 20ms total budget must expire during swipe data.
  for I := 0 to 1 do
  begin
    Obj := TScriptPort.Create; Port := Obj; Obj.Setup(msrp206ThreeTrackHL);
    Obj.Add('1B72','1B731B012530313F1B023B32333F1B033B34353F3F1C1B30');
    Obj.FClock := 1000; Obj.FTickPerByte := 1; Obj.FClockBackwards := I=1;
    Device := TMsr206MagStripeAdapter.Create(Port,msrp206ThreeTrackHL);
    Device.Acquire;
    Raised := False;
    try R := Device.Read([mstTrack2],20); except on E: EMagStripeError do Raised := True; end;
    Check(Raised,'Aggregate deadline/backwards clock refused');
    if I=0 then
    begin
      Check(Obj.FReceives=20,'Whole operation expires rather than restarting each I/O timeout');
      Limit := 20;
      for J := 0 to High(Obj.FDeadlines) do
      begin Check(Obj.FDeadlines[J] <= Cardinal(Limit),'Deadlines never grow'); Limit := Obj.FDeadlines[J]; end;
    end;
    Device.Release;
    Device := nil; Port := nil;
  end;
  Writeln('PASS: Every protocol failure, shared deadline and poisoned-session rejection.');
end;

procedure ProgrammingFaultTests;
var
  Obj: TScriptPort;
  Port: IMagStripeSerialPort;
  Device: IMagStripeDevice;
  Writer: IMagStripeStatusWriter;
  I, J, K, Offset, Before: Integer;
  Raised, Uncertain: Boolean;
begin
  for I := 0 to 43 do
  begin
    Obj := TScriptPort.Create; Port := Obj; Obj.Setup(msrp206ThreeTrackHL);
    Obj.Add('1B78','1B30'); Obj.Add('1B64','1B48');
    Obj.Add('1B771B731B0130311B0232331B0334353F1C','1B30');
    if I < 8 then Obj.FFailSend := I+1
    else if I < 26 then Obj.FFailReceive := I-7
    else
    begin
      Offset := I-26;
      for J := 0 to High(Obj.FScript) do
        if Offset < Length(Obj.FScript[J].Reply) then
        begin
          Obj.FScript[J].Reply[Offset] := Obj.FScript[J].Reply[Offset] xor 1;
          Break;
        end
        else Dec(Offset,Length(Obj.FScript[J].Reply));
    end;
    Device := TMsr206MagStripeAdapter.Create(Port,msrp206ThreeTrackHL);
    Check(Supports(Device,IMagStripeStatusWriter,Writer),'Direct optional writer');
    Device.Acquire;
    Raised := False; Uncertain := False;
    try K := Writer.ProgramStatus([mstTrack1,mstTrack2,mstTrack3],DataFixture,mscHigh,4321);
    except
      on E: EMagStripeWriteUncertain do begin Raised:=True; Uncertain:=True; Check(Pos('secret',E.Message)=0,'No sensitive error text'); end;
      on E: EMagStripeError do Raised:=True;
    end;
    Check(Raised,'Every programming send/receive and reply-byte mutation fails');
    Check(Uncertain=((I=7) or (I in [24,25,42,43])),'Direct dispatch boundary preserves pre-program certainty');
    Before := Obj.FSends;
    Device.Release;
    Check((Obj.FSends=Before+1) and (Obj.FCloseCount=1),'Single cleanup reset and close, no retry');
    Writer:=nil; Device:=nil; Port:=nil;
  end;
  Writeln('PASS: Every programming send/receive failure and every reply-byte corruption.');
end;

function TSelectionDevice.GetCapabilities: TMagStripeCapabilities;
begin
  Result.ReadTracks:=[]; Result.WriteTracks:=[]; Result.Coercivities:=[]; Result.VerifiedWrite:=False;
end;
function TSelectionDevice.GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
begin Result.Selections:=[FSelection]; Result.Coercivities:=[mscCurrent]; end;
procedure TSelectionDevice.Acquire;
begin Inc(FAcquires); end;
procedure TSelectionDevice.Release;
begin Inc(FReleases); end;
function TSelectionDevice.Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
var T:TMagStripeTrack;
begin
  for T:=Low(TMagStripeTrack) to High(TMagStripeTrack) do Result[T]:='';
  raise EMagStripeError.Create('Unexpected extra read');
end;
function TSelectionDevice.Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
var T:TMagStripeTrack;
begin
  for T:=Low(TMagStripeTrack) to High(TMagStripeTrack) do Result[T]:='';
  raise EMagStripeError.Create('Unexpected verified write');
end;
function TSelectionDevice.ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
begin
  Check((ATracks=FExpected) and (ACoercivity=mscCurrent) and (ATimeoutMs=10000),'Exact generic programming selection');
  Inc(FPrograms);
  Result:=$42; // Synthetic vendor success; generic receipt must not assume MSR206's 30.
end;

procedure SelectionTests;
var
  Obj:TSelectionDevice;
  Device:IMagStripeDevice;
  C:TMagStripeReaderWriter;
  Data:TMagStripeTracks;
  Receipt:TMagStripeProgrammingReceipt;
  I:Integer;
  T:TMagStripeTrack;
begin
  for I:=0 to 6 do
  begin
    Obj:=TSelectionDevice.Create; Device:=Obj; Obj.FSelection:=TMagStripeWriteSelection(I);
    case I of
      0:Obj.FExpected:=[mstTrack1]; 1:Obj.FExpected:=[mstTrack2]; 2:Obj.FExpected:=[mstTrack1,mstTrack2];
      3:Obj.FExpected:=[mstTrack3]; 4:Obj.FExpected:=[mstTrack1,mstTrack3];
      5:Obj.FExpected:=[mstTrack2,mstTrack3]; 6:Obj.FExpected:=[mstTrack1,mstTrack2,mstTrack3];
    end;
    for T:=Low(TMagStripeTrack) to High(TMagStripeTrack) do
      if T in Obj.FExpected then Data[T]:='1' else Data[T]:='';
    C:=TMagStripeReaderWriter.Create(nil);
    try
      C.Device:=Device;
      Receipt:=C.ProgramTracks(Obj.FExpected,Data);
      Check((Receipt.RequestedTracks=Obj.FExpected) and (Receipt.DeviceStatus=$42) and
        not Receipt.HostReadBackVerified,'Each exact combination supports status-only vendor receipt');
      Check((Obj.FAcquires=1) and (Obj.FPrograms=1) and (Obj.FReleases=1),'Generic programming does not require reading capability');
    finally C.Free; end;
    Device:=nil;
  end;
  Writeln('PASS: All seven generic write combinations and vendor-neutral status receipts.');
end;

procedure FactoryTests;
var
  Port: IMagStripeSerialPort;
  Device: IMagStripeDevice;
  Name: string;
  I: Integer;
  Raised: Boolean;
begin
  for I := 0 to 8 do
  begin
    case I of
      0: Name := ''; 1: Name := 'COM0'; 2: Name := 'COM01'; 3: Name := 'COM65536';
      4: Name := 'COM1x'; 5: Name := '\\.\COM1'; 6: Name := '/dev/ttyS0';
      7: Name := 'COM1 '; 8: Name := 'COM';
    end;
    Raised := False;
    try Port := CreateWindowsMagStripeSerialPort(Name);
    except on E: EMagStripeError do Raised := True; end;
    Check(Raised,'Strict native port names without arbitrary file access');
  end;
  Port := CreateWindowsMagStripeSerialPort('com12');
{$IFNDEF MSWINDOWS}
  Raised := False;
  try Port.Open; except on E: EMagStripeError do Raised := True; end;
  Check(Raised,'Native COM explicitly unsupported on this platform');
{$ENDIF}
  Port := nil;
  Raised := False;
  try Device := TMsr206MagStripeAdapter.Create(nil,msrp206ThreeTrackHL);
  except on E: EMagStripeError do Raised := True; end;
  Check(Raised,'Nil port before I/O');
  Writeln('PASS: Native factory preflight and explicit platform boundary.');
end;

begin
  try
    CodecTests; AdapterTests; DeadlineTests; ProgrammingFaultTests; SelectionTests; FactoryTests;
    Writeln('PASS: 6 MSR206 groups; ',Assertions,' assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
