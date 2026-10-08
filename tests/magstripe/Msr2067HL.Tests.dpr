program Msr2067HLTests;

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
  ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL;

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
    FOpenFail, FCloseFail, FResetFail, FOpen, FClockBackwards, FHostGap: Boolean;
    FGapClockCalls: Integer;
    FClock, FTickPerByte: UInt64;
    FDeadlines, FReadDeadlines: array of Cardinal;
    FComponent: TMagStripeReaderWriter;
    procedure Add(const ACommandHex, AReplyHex: string);
    procedure Setup(const AFramedReset: Boolean = False);
    procedure ReadScript(const ATracks: TMagStripeTrackSet);
    procedure WriteScript(const ATracks: TMagStripeTrackSet; const ALow: Boolean = False);
    procedure Open;
    procedure Close;
    procedure DiscardInput;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
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

procedure TScriptPort.Setup(const AFramedReset: Boolean);
begin
  if AFramedReset then Add('7F','023A033B') else Add('7F','3A');
  Add('02230322','02770376');
end;

procedure TScriptPort.ReadScript(const ATracks: TMagStripeTrackSet);
begin
  Add('02500351','025E035F025E035F');
  if mstTrack1 in ATracks then Add('02510350','0230310300');
  if mstTrack2 in ATracks then Add('02520353','0232330300');
  if mstTrack3 in ATracks then Add('02530352','0234350300');
end;

procedure TScriptPort.WriteScript(const ATracks: TMagStripeTrackSet; const ALow: Boolean);
begin
  if ALow then begin Add('023C3033360308','025E035F'); Add('023E033F','023033360334'); end
  else begin Add('023C323535030F','025E035F'); Add('023E033F','023235350333'); end;
  Add('024F034E','025E035F'); Add('026E036F','025E035F');
  if mstTrack1 in ATracks then begin Add('02410340','025E035F'); Add('023031040304','025E035F'); end;
  if mstTrack2 in ATracks then begin Add('02420343','025E035F'); Add('023233040304','025E035F'); end;
  if mstTrack3 in ATracks then begin Add('02430342','025E035F'); Add('023435040304','025E035F'); end;
  Add('02400341','025E035F025E035F');
  if mstTrack1 in ATracks then Add('02510350','0230310300');
  if mstTrack2 in ATracks then Add('02520353','0232330300');
  if mstTrack3 in ATracks then Add('02530352','0234350300');
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
  if (ATimeoutMs = 500) and (BytesToHex(ABytes) = '7F') and (FStep > 0) then
  begin
    Check(BytesToHex(ABytes) = '7F', 'Cleanup is reset only, never a replay');
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
var N: Integer;
begin
  N:=Length(FReadDeadlines); SetLength(FReadDeadlines,N+1); FReadDeadlines[N]:=ATimeoutMs;
  Inc(FReceives);
  Check(FOpen and (FStep > 0), 'Receive only after a command');
  Check(ATimeoutMs > 0, 'No receive with expired deadline');
  if FFailReceive = FReceives then raise EMagStripeError.Create('secret receive primary');
  if FReplyOffset >= Length(FScript[FStep - 1].Reply) then
    raise EMagStripeError.Create('Scripted receive timeout.');
  Result := FScript[FStep - 1].Reply[FReplyOffset];
  Inc(FReplyOffset);
  Inc(FClock, FTickPerByte);
end;

function TScriptPort.NowMs: UInt64;
begin
  if FHostGap and (FReceives=2) then
  begin
    Inc(FGapClockCalls);
    if FGapClockCalls=2 then Inc(FClock,70);
  end;
  Result := FClock;
  if FClockBackwards and (FReceives > 0) then Result := 0;
end;

function Selection(const AMask: Integer): TMagStripeTrackSet;
var T: TMagStripeTrack;
begin
  Result := [];
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if (AMask and (1 shl Ord(T))) <> 0 then Include(Result,T);
end;

function SelectedData(const ATracks: TMagStripeTrackSet): TMagStripeTracks;
var T: TMagStripeTrack;
begin
  Result := DataFixture;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if not (T in ATracks) then Result[T] := '';
end;

procedure CodecTests;
var B, Bad, R: TBytes; I,J,K: Integer; Raised: Boolean; Text: string; T: TMagStripeTrack;
begin
  // Independently calculated PM036 section 5.3 BCC: 02 xor 23 xor 03 = 22.
  Check(BytesEqual(TMsr2067HLCodec.Encode(HexToBytes('23')),HexToBytes('02230322')),'Configuration wire vector');
  Check(BytesEqual(TMsr2067HLCodec.Decode(HexToBytes('025E035F')),HexToBytes('5E')),'ACK wire vector');
  Check(BytesEqual(TMsr2067HLCodec.Encode(HexToBytes('323304')),HexToBytes('023233040304')),'EOT remains inside USI1 message');
  B := HexToBytes('0230310300');
  for I := 0 to Length(B)-1 do
  begin
    Raised := False;
    try R := TMsr2067HLCodec.Decode(Copy(B,0,I)); except on E: EMagStripeError do Raised:=True; end;
    Check(Raised,'Every truncated frame refused');
  end;
  for I := 0 to High(B) do for J := 0 to 255 do if J<>B[I] then
  begin
    Bad := Copy(B); Bad[I]:=J; Raised:=False;
    try R:=TMsr2067HLCodec.Decode(Bad); except on E: EMagStripeError do Raised:=True; end;
    Check(Raised,'Every one-byte frame corruption refused');
  end;
  for I := 0 to 255 do
  begin
    Raised:=False;
    try R:=TMsr2067HLCodec.Encode(HexToBytes(IntToHex(I,2))); except on E: EMagStripeError do Raised:=True; end;
    Check(Raised=((I>127) or (I in [2,3])),'Seven-bit message framing constraints');
  end;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    K:=TMagStripeTrackCodec.MaxPayloadLength(T); SetLength(B,K);
    for I:=0 to K-1 do B[I]:=Ord('1');
    Text:=TMsr2067HLCodec.DecodeTrack(T,B); Check(Length(Text)=K,'Exact track capacity');
    SetLength(B,K+1); B[K]:=Ord('1'); Raised:=False;
    try Text:=TMsr2067HLCodec.DecodeTrack(T,B); except on E: EMagStripeError do Raised:=True; end;
    Check(Raised,'Track capacity plus one refused');
    Check(TMsr2067HLCodec.DecodeTrack(T,HexToBytes('2B'))='','Documented no-data response');
    for I:=0 to 5 do
    begin
      case I of 0:B:=HexToBytes('21'); 1:B:=HexToBytes('2A'); 2:B:=HexToBytes('2D');
        3:B:=HexToBytes('2F'); 4:B:=HexToBytes('3F'); 5:B:=HexToBytes('7E'); end;
      Raised:=False;
      try Text:=TMsr2067HLCodec.DecodeTrack(T,B); except on E: EMagStripeError do Raised:=True; end;
      Check(Raised,'Singleton status is never successful payload');
    end;
  end;
  SetLength(B,105); for I:=0 to High(B) do B[I]:=$31; B[104]:=4;
  R:=TMsr2067HLCodec.Encode(B); Check(Length(R)=108,'Largest Track 3 data plus EOT frame');
  Check(BytesEqual(TMsr2067HLCodec.Decode(R),B),'Maximum frame accepted');
  SetLength(B,106); B[105]:=$31; Raised:=False;
  try R:=TMsr2067HLCodec.Encode(B); except on E: EMagStripeError do Raised:=True; end;
  Check(Raised,'Maximum message plus one rejected');
  Writeln('PASS: USI1 independent vectors, complete byte corruption and payload bounds.');
end;

procedure CombinationTests;
var Obj:TScriptPort; Port:IMagStripeSerialPort; Device:IMagStripeDevice;
  C:TMagStripeReaderWriter; S:TMagStripeTrackSet; D,R:TMagStripeTracks;
  I,J:Integer; T:TMagStripeTrack;
begin
  for I:=1 to 7 do for J:=0 to 3 do
  begin
    S:=Selection(I); D:=SelectedData(S);
    Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup((J and 1)<>0);
    if J<2 then Obj.ReadScript(S) else Obj.WriteScript(S,J=2);
    Device:=TMsr2067HLMagStripeAdapter.Create(Port);
    Check(Obj.FOpenCount=0,'Inactive constructor');
    C:=TMagStripeReaderWriter.Create(nil);
    try
      C.Device:=Device; C.TimeoutMs:=4321; Obj.FComponent:=C;
      if J<2 then R:=C.ReadTracks(S)
      else if J=2 then R:=C.WriteTracks(S,D,mscLow)
      else R:=C.WriteTracks(S,D,mscHigh);
      for T:=Low(TMagStripeTrack) to High(TMagStripeTrack) do Check(R[T]=D[T],'Selected acquired payload and empty unselected');
      Check((Obj.FStep=Length(Obj.FScript)) and (Obj.FReceives>0),'Exact wire chain, no extra swipe or write to unselected tracks');
      Check((Obj.FOpenCount=1) and (Obj.FCloseCount=1) and not C.Busy,'Single acquisition and cleanup');
    finally C.Free; end;
    Device:=nil; Port:=nil;
  end;
  Writeln('PASS: All seven read/write combinations, both reset reports, low/high and same-swipe read-back.');
end;

procedure FaultTests;
var Obj:TScriptPort; Port:IMagStripeSerialPort; Device:IMagStripeDevice;
  D,R:TMagStripeTracks; I,J,K,N,Before,Offset:Integer;
  Raised,Uncertain:Boolean;
begin
  D:=DataFixture;
  // Full write chain has 16 sends and 70 response bytes (one raw reset report).
  // Derive counts from independent literal script, then inject every boundary and mutate every response byte.
  Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.WriteScript([mstTrack1,mstTrack2,mstTrack3]);
  N:=0; for J:=0 to High(Obj.FScript) do Inc(N,Length(Obj.FScript[J].Reply));
  K:=Length(Obj.FScript); Port:=nil;
  for I:=0 to K+2*N-1 do
  begin
    Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.WriteScript([mstTrack1,mstTrack2,mstTrack3]);
    if I<K then Obj.FFailSend:=I+1
    else if I<K+N then Obj.FFailReceive:=I-K+1
    else
    begin
      Offset:=I-K-N;
      for J:=0 to High(Obj.FScript) do
        if Offset<Length(Obj.FScript[J].Reply) then
        begin Obj.FScript[J].Reply[Offset]:=Obj.FScript[J].Reply[Offset] xor $80; Break; end
        else Dec(Offset,Length(Obj.FScript[J].Reply));
    end;
    Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire;
    Raised:=False; Uncertain:=False;
    try R:=Device.Write([mstTrack1,mstTrack2,mstTrack3],D,mscHigh,4321);
    except
      on E:EMagStripeWriteUncertain do begin Raised:=True; Uncertain:=True; Check(Pos('secret',E.Message)=0,'No transport/card data in uncertain errors'); end;
      on E:EMagStripeError do Raised:=True;
    end;
    Check(Raised,'Every send/receive failure and frame byte corruption fails');
    Check(Uncertain=(Obj.FStep>=13),'Only arm-dispatched operations uncertain directly');
    Before:=Obj.FSends; Raised:=False;
    try R:=Device.Read([mstTrack2],4321); except on E:EMagStripeError do Raised:=True; end;
    Check(Raised and (Before=Obj.FSends),'Failed session poisoned, no automatic replay');
    Device.Release;
    Check((Obj.FSends=Before+1) and (Obj.FCloseCount=1),'Only bounded cleanup reset after failure');
    Device:=nil; Port:=nil;
  end;
  Writeln('PASS: Every programming send, receive and response-byte corruption; dispatch boundary and no replay.');
end;

procedure SemanticTests;
var Obj:TScriptPort; Port:IMagStripeSerialPort; Device:IMagStripeDevice;
  C:TMagStripeReaderWriter; D,R:TMagStripeTracks; I,Before:Integer; Raised:Boolean;
begin
  for I:=0 to 12 do
  begin
    Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.WriteScript([mstTrack2]);
    case I of
      0: Obj.FScript[1].Reply:=HexToBytes('02630362'); // Missing physical Track 3.
      1: Obj.FScript[3].Reply:=HexToBytes('023033360334'); // Wrong temporary current.
      2: Obj.FScript[8].Reply:=HexToBytes('025E035F02320333'); // Track 2 RAW error.
      3: Obj.FScript[9].Reply:=HexToBytes('0232340307'); // Valid BCC, wrong data.
      4: Obj.FScript[9].Reply:=HexToBytes('022B032A'); // Missing acquired selected data.
      5: Obj.FScript[9].Reply:=HexToBytes('022A032B'); // Card decode error.
      6: Obj.FCloseFail:=True;
      7: Obj.FResetFail:=True;
      8: begin Obj.FResetFail:=True; Obj.FCloseFail:=True; end;
      9: Obj.FOpenFail:=True;
      10: begin Obj.FClock:=1000; Obj.FTickPerByte:=1; end;
      11: begin Obj.FClock:=1000; Obj.FClockBackwards:=True; end;
      12: Obj.FScript[8].Reply:=HexToBytes('025E035F02320333025E035F'); // Trailing ACK cannot turn RAW error into success.
    end;
    Device:=TMsr2067HLMagStripeAdapter.Create(Port); C:=TMagStripeReaderWriter.Create(nil);
    try
      C.Device:=Device; C.TimeoutMs:=4321; if I=10 then C.TimeoutMs:=20;
      D:=SelectedData([mstTrack2]); Raised:=False;
      try R:=C.WriteTracks([mstTrack2],D,mscHigh);
      except
        on E:EMagStripeWriteUncertain do begin Raised:=True; Check(I<>9,'Open failure stays ordinary'); end;
        on E:EMagStripeError do begin Raised:=True; Check(I=9,'Only acquisition failure ordinary at component boundary'); end;
      end;
      Check(Raised and not C.Busy,'Semantic/protocol/deadline/cleanup failure refuses success');
      if I<>9 then Check(Obj.FCloseCount=1,'Always closes after acquired failure')
      else Check((Obj.FSends=0) and (Obj.FCloseCount=0),'Failed open grants nothing');
      if I=10 then Check(Obj.FReceives=20,'Shared total deadline includes preparation');
      Before:=Obj.FOpenCount; D:=SelectedData([mstTrack2]);
      Raised:=False;
      try R:=C.WriteTracks([mstTrack2],D,mscCurrent); except on E:EMagStripeError do Raised:=True; end;
      Check(Raised and (Obj.FOpenCount=Before),'Current mode refused before hardware acquisition');
    finally C.Free; end;
    Device:=nil; Port:=nil;
  end;
  // Direct preflight never sends a byte even in an acquired session.
  Obj:=TScriptPort.Create; Port:=Obj; Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire;
  for I:=0 to 5 do
  begin
    D:=SelectedData([mstTrack2]);
    case I of 0:D[mstTrack2]:=''; 1:D[mstTrack1]:='01'; 2:D[mstTrack2]:='secret';
      3:D[mstTrack2]:=StringOfChar('1',38); 4:D[mstTrack2]:='?'; 5:D[mstTrack2]:='+'; end;
    Raised:=False;
    try R:=Device.Write([mstTrack2],D,mscHigh,4321);
    except on E:EMagStripeError do Raised:=True; on E:EMagStripeFormatError do Raised:=True; end;
    Check(Raised and (Obj.FSends=0),'Invalid payload before I/O');
  end;
  Device.Release; Device:=nil; Port:=nil;
  Port:=CreateWindowsMagStripeSerialPort('COM12',mssf7O1); Check(Port<>nil,'Inactive explicit 7O1 factory'); Port:=nil;
  Writeln('PASS: RAW failure, independent mismatch/missing read-back, config/current checks, deadlines and cleanup.');
end;

procedure BoundaryTests;
var Obj:TScriptPort; Port:IMagStripeSerialPort; Device:IMagStripeDevice;
  D,R:TMagStripeTracks; I,J,Before:Integer; Raised:Boolean; PayloadHex:string;
begin
  PayloadHex:=''; for J:=1 to 104 do PayloadHex:=PayloadHex+'37';
  for I:=0 to 4 do
  begin
    Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.WriteScript([mstTrack3]);
    D:=SelectedData([mstTrack3]); D[mstTrack3]:=StringOfChar('7',104);
    // Independent even-length XOR: data cancels, so EOT download BCC=05, read BCC=01.
    Obj.FScript[7].Command:=HexToBytes('02'+PayloadHex+'040305');
    Obj.FScript[9].Reply:=HexToBytes('02'+PayloadHex+'0301');
    case I of
      1:Obj.FScript[9].Reply:=HexToBytes('02'+PayloadHex+'370336'); // Valid BCC but 105-byte track.
      2:Obj.FScript[9].Reply:=HexToBytes('02'+PayloadHex+'3737'); // No ETX, global receive bound.
      3:Obj.FScript[8].Reply:=HexToBytes('5E5E'); // USI0 must not be guessed after USI1 selection.
      4:Obj.FScript[9].Reply:=HexToBytes('02'+PayloadHex+'0300'); // Maximum-size invalid BCC.
    end;
    Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire; Raised:=False;
    try R:=Device.Write([mstTrack3],D,mscHigh,4321);
    except on E:EMagStripeWriteUncertain do Raised:=True; end;
    Check(Raised=(I<>0),'Maximum streaming frame, oversize, unterminated and no protocol fallback');
    if I=0 then Check(R[mstTrack3]=D[mstTrack3],'Acquired maximum Track 3 payload');
    Device.Release; Device:=nil; Port:=nil;
  end;
  Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.ReadScript([mstTrack2]);
  Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire;
  R:=Device.Read([mstTrack2],4321);
  Check(Length(Obj.FReadDeadlines)=18,'Exact complete read sequence');
  for I:=0 to High(Obj.FReadDeadlines) do
    if I in [0,1,5,9,13] then Check(Obj.FReadDeadlines[I]=4321,'First byte and physical swipe can use total remaining budget')
    else Check(Obj.FReadDeadlines[I]=65,'Every in-frame continuation and BCC uses USI1 inter-character limit');
  Device.Release; Device:=nil; Port:=nil;
  Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.ReadScript([mstTrack2]);
  Obj.FTickPerByte:=66;
  Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire; Raised:=False;
  try R:=Device.Read([mstTrack2],4321); except on E:EMagStripeError do Raised:=True; end;
  Check(Raised and (Obj.FSends=2),'Late intra-frame byte refused even if transport reports it received');
  Device.Release; Device:=nil; Port:=nil;
  Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.ReadScript([mstTrack2]);
  Obj.FHostGap:=True;
  Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire; Raised:=False;
  try R:=Device.Read([mstTrack2],4321); except on E:EMagStripeError do Raised:=True; end;
  Check(Raised and (Obj.FReceives=2),'Host processing time between bytes also consumes the 65 ms budget');
  Device.Release; Device:=nil; Port:=nil;
  Obj:=TScriptPort.Create; Port:=Obj; Obj.Setup; Obj.ReadScript([mstTrack2]);
  Device:=TMsr2067HLMagStripeAdapter.Create(Port); Device.Acquire;
  R:=Device.Read([mstTrack2],4321); Obj.FResetFail:=True; Obj.FCloseFail:=True;
  Raised:=False;
  try Device.Release;
  except on E:EMagStripeError do begin Raised:=True; Check(E.Message='Reset primary','Cleanup keeps reset error over close error'); end; end;
  Check(Raised and (Obj.FCloseCount=1),'Release closes on reset failure');
  Before:=Obj.FCloseCount; Device:=nil; Check(Obj.FCloseCount=Before,'Ownership clears even if both cleanup stages fail'); Port:=nil;
  Writeln('PASS: Streaming maximum bounds, USI1 inter-character timing, no fallback and primary cleanup error.');
end;

begin
  try
    CodecTests; CombinationTests; FaultTests; SemanticTests; BoundaryTests;
    Writeln('PASS: 5 MSR206-7HL groups; ',Assertions,' assertions.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
