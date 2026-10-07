program RawUidTests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Contactless,
  ERD.Card.Contactless.UID, ERD.Card.Contactless.Raw, ERD.Card.Contactless.ACR122;

type
  TStep = record
    Wire, Response: TBytes;
    Bits, ReceivedBits: Integer;
    Timeout, Fails: Boolean;
  end;
  TRawScript = class(TInterfacedObject, IRawContactlessReader)
  public
    Steps: array of TStep;
    Uids: array of TBytes;
    Position, Selections, Begins, Ends: Integer;
    EndFails, BeginFails, Active: Boolean;
    procedure Add(const AWire, AResponse: string; const ABits, AReceivedBits: Integer;
      const ATimeout: Boolean = False; const AFails: Boolean = False);
    procedure SelectUid(const AUid: string);
    procedure BeginSession;
    procedure EndSession;
    function Activate: TBytes;
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
  end;
  TPcscScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    BeginFails, EndFails: Boolean;
    procedure Add(const APayload, AResponse: string; const AFails: Boolean = False);
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

const
  OldBlock = '11223344440804006263646566676869';
  NewBlock = 'A1B2C3D4040804006263646566676869';
  OldPages = '041122BF334455664448ABCDE1101200';
  NewPages = '04AABB9DCCDDEEFF0048ABCDE1101200';
var Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

procedure TRawScript.Add(const AWire, AResponse: string; const ABits, AReceivedBits: Integer;
  const ATimeout: Boolean; const AFails: Boolean);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Wire := HexToBytes(AWire);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Bits := ABits;
  Steps[I].ReceivedBits := AReceivedBits;
  Steps[I].Timeout := ATimeout;
  Steps[I].Fails := AFails;
end;

procedure TRawScript.SelectUid(const AUid: string);
var I: Integer;
begin
  I := Length(Uids);
  SetLength(Uids, I + 1);
  Uids[I] := HexToBytes(AUid);
end;

procedure TRawScript.BeginSession;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic begin');
  Check(not Active, 'No nested raw session');
  Active := True;
end;

procedure TRawScript.EndSession;
begin
  Inc(Ends);
  Check(Active, 'End active session');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic release');
end;

function TRawScript.Activate: TBytes;
begin
  Check(Active and (Selections < Length(Uids)), 'Exact fresh RF activation');
  Result := CopyBytes(Uids[Selections]);
  Inc(Selections);
end;

function TRawScript.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
begin
  Check(Active and (Position < Length(Steps)), 'No unexpected frame or replay');
  Check(BytesEqual(AFrame, Steps[Position].Wire) and (ABitCount = Steps[Position].Bits), 'Exact RF frame and bit count');
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic RF exchange');
  Result := Default(TRawRfResponse);
  Result.Data := CopyBytes(Steps[Position - 1].Response);
  Result.BitCount := Steps[Position - 1].ReceivedBits;
  Result.TimedOut := Steps[Position - 1].Timeout;
end;

procedure TPcscScript.Add(const APayload, AResponse: string; const AFails: Boolean);
var I: Integer; Payload: TBytes;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Payload := HexToBytes(APayload);
  Steps[I].Wire := HexToBytes('FF000000' + IntToHex(Length(Payload), 2) + APayload);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Fails := AFails;
end;

function TPcscScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(Steps), 'No unexpected PN532 command or retry');
  Check(BytesEqual(ACommand, Steps[Position].Wire), 'Exact ACR122 direct-transmit APDU');
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic PCSC exchange');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

procedure TPcscScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic acquisition');
end;

procedure TPcscScript.EndTransaction;
begin
  Inc(Ends);
  if EndFails then raise ECardTransportError.Create('synthetic release');
end;

function WithCrc(const AHex: string): string;
begin
  Result := BytesToHex(TRawUidCodec.AppendCrcA(HexToBytes(AHex)));
end;

procedure AddRead(Script: TRawScript; const AData: string);
begin Script.Add('300002A8', WithCrc(AData), 32, 144); end;

procedure AddUnlock(Script: TRawScript);
begin
  Script.Add('500057CD', '', 32, 0, True);
  Script.Add('40', '0A', 7, 4);
  Script.Add('43', '0A', 8, 4);
end;

procedure TestCodecs;
var Data, Prepared, Uid: TBytes; Response: TRawRfResponse;
  I: Integer; Raised: Boolean;
begin
  Check(WithCrc('5000') = '500057CD', 'Published HALT CRC-A vector');
  Check(WithCrc('3000') = '300002A8', 'Known MIFARE READ CRC-A vector');
  Check(WithCrc('') = '6363', 'CRC initial state, little endian');
  Data := HexToBytes(OldPages);
  Uid := HexToBytes('04AABBCCDDEEFF');
  Prepared := TRawUidCodec.PrepareType2Pages(Data, Uid);
  Check(BytesToHex(Prepared) = NewPages, 'Exact both BCC values and metadata preservation');
  Check(BytesToHex(TRawUidCodec.DecodeType2Uid(Prepared)) = '04AABBCCDDEEFF', 'Cascade UID extraction');
  Prepared[9] := 0;
  Check((Data[9] = $48) and (Uid[0] = $04), 'Prepared pages independent');
  for I := 0 to 15 do
  begin
    Data := HexToBytes(OldPages);
    Data[I] := Data[I] xor 1;
    Raised := False;
    try Prepared := TRawUidCodec.DecodeType2Uid(Data);
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised = (I <= 8), 'Both cascade checksums; metadata not misinterpreted');
  end;
  for I := 0 to 6 do
  begin
    Response := Default(TRawRfResponse);
    Response.Data := TRawUidCodec.AppendCrcA(HexToBytes('010203'));
    Response.BitCount := 40;
    case I of
      0: Response.TimedOut := True;
      1: Response.BitCount := 39;
      2: SetLength(Response.Data, 4);
      3: Response.Data[4] := Response.Data[4] xor 1;
      4: SetLength(Response.Data, 6);
    end;
    Raised := False;
    try
      if I = 5 then Prepared := TRawUidCodec.DecodeCrcA(Response, -1)
      else if I = 6 then Prepared := TRawUidCodec.DecodeCrcA(Response, 254)
      else Prepared := TRawUidCodec.DecodeCrcA(Response, 3);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised, 'Reject malformed RF framing or checksum');
  end;
  SetLength(Data, 254);
  Raised := False;
  try Prepared := TRawUidCodec.AppendCrcA(Data);
  except on E: EContactlessError do Raised := True; end;
  Check(Raised, 'Bound CRC input');
  Writeln('PASS: CRC-A vectors, Type 2 cascade checksums, metadata and framing bounds.');
end;

procedure TestClassicProgramming;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TProgrammableUidResult;
  Profile: TClassicRawUidProfile;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for Profile := Low(TClassicRawUidProfile) to High(TClassicRawUidProfile) do
    begin
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid('11223344');
      Script.SelectUid('A1B2C3D4');
      AddUnlock(Script);
      AddRead(Script, OldBlock);
      Script.Add(WithCrc('A000'), '0A', 32, 4);
      Script.Add(WithCrc(NewBlock), '0A', 144, 4);
      AddRead(Script, NewBlock);
      Data := Programmer.ProgramClassicUid(Profile, HexToBytes('A1B2C3D4'));
      Check(Data.ActiveUidVerified and (BytesToHex(Data.ManufacturerBlock) = NewBlock), 'Full block and fresh UID verification');
      Check((Script.Position = 7) and (Script.Selections = 2) and (Script.Begins = 1) and (Script.Ends = 1), 'One unlock/write operation and fresh RF check');
      Check(BytesToHex(Data.PreviousUid) = '11223344', 'Original RF UID snapshot');
    end;
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Script.SelectUid('11223344');
    AddUnlock(Script);
    AddRead(Script, OldBlock);
    Data := Programmer.ProgramClassicUid(crupGen1a, HexToBytes('11223344'));
    Check(Data.ActiveUidVerified and (Script.Position = 4), 'Classic already matching no-op');
  finally Programmer.Free; end;
  Writeln('PASS: Gen1a/unsealed UFUID exact seven-bit unlock, metadata, write and fresh RF UID.');
end;

procedure TestClassicFailures;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TProgrammableUidResult;
  I: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for I := 0 to 13 do
    begin
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid('11223344');
      Script.SelectUid('11223344'); // Stale UID after fresh activation must fail.
      if I = 0 then Script.Add('500057CD', '0A', 32, 4)
      else
      begin
        Script.Add('500057CD', '', 32, 0, True);
        if I = 1 then Script.Add('40', '0A', 7, 8)
        else if I = 2 then Script.Add('40', '00', 7, 4)
        else if I = 3 then Script.Add('40', '', 7, 0, True)
        else
        begin
          Script.Add('40', '0A', 7, 4);
          Script.Add('43', '0A', 8, 4);
          if I = 4 then AddRead(Script, '00000000000804006263646566676869')
          else if I = 5 then AddRead(Script, '11223344450804006263646566676869')
          else AddRead(Script, OldBlock);
        end;
      end;
      if I >= 6 then
      begin
        if I = 6 then Script.Add(WithCrc('A000'), '00', 32, 4)
        else if I = 7 then Script.Add(WithCrc('A000'), '', 32, 0, False, True)
        else Script.Add(WithCrc('A000'), '0A', 32, 4);
      end;
      if I >= 8 then
      begin
        if I = 8 then Script.Add(WithCrc(NewBlock), '', 144, 0, False, True)
        else if I = 9 then Script.Add(WithCrc(NewBlock), '00', 144, 4)
        else Script.Add(WithCrc(NewBlock), '0A', 144, 4);
      end;
      if I = 10 then AddRead(Script, OldBlock);
      if I = 11 then Script.Add('300002A8', '019000', 32, 24);
      if I >= 12 then AddRead(Script, NewBlock);
      if I = 13 then Script.Uids[1] := HexToBytes('A1B2C3D4');
      Script.EndFails := I in [1, 10, 13];
      Raised := False;
      try Data := Programmer.ProgramClassicUid(crupGen1a, HexToBytes('A1B2C3D4'));
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := I >= 6;
          if I = 10 then Check(E.OriginalErrorClass = 'EContactlessError', 'Read-back error wins over release');
        end;
        on E: EContactlessError do Raised := I <= 4;
        on E: EProgrammableUidError do Raised := I = 5;
      end;
      Check(Raised and (Script.Ends = 1) and not Script.Active, 'Failure classification, no replay and cleanup');
    end;
  finally Programmer.Free; end;
  Writeln('PASS: sealed/rejecting cards, invalid original block, write/CRC/activation/release failure.');
end;

procedure AddType2Writes(Script: TRawScript; const AFailPage: Integer = -1);
const Pages: array[0..2] of string = ('A20004AABB9D', 'A201CCDDEEFF', 'A2020048ABCD');
var I: Integer;
begin
  for I := 0 to 2 do
  begin
    Script.Add(WithCrc(Pages[I]), '0A', 64, 4, False, I = AFailPage);
    if I = AFailPage then Exit;
  end;
end;

procedure TestType2Programming;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TType2UidResult;
  Uid: TBytes; I: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    Uid := HexToBytes('04AABBCCDDEEFF');
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Script.SelectUid('04112233445566');
    Script.SelectUid('04AABBCCDDEEFF');
    AddRead(Script, OldPages);
    AddType2Writes(Script);
    AddRead(Script, NewPages);
    Data := Programmer.ProgramType2DirectWriteUid(Uid);
    Check(Data.ActiveUidVerified and (BytesToHex(Data.ManufacturerPages) = NewPages), 'All three UID pages, lock and CC bytes verified');
    Check((Script.Position = 5) and (Script.Selections = 2) and (Script.Ends = 1), 'Three consecutive retained-selection writes, one read-back and fresh activation');
    Data.RequestedUid[0] := 0;
    Check(Uid[0] = $04, 'Result independent from caller UID');
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Script.SelectUid('04112233445566');
    AddRead(Script, OldPages);
    Data := Programmer.ProgramType2DirectWriteUid(HexToBytes('04112233445566'));
    Check(Data.ActiveUidVerified and (Script.Position = 1), 'Type 2 matching no-op');
    for I := 0 to 6 do
    begin
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid('04112233445566');
      Script.SelectUid('00112233445566');
      AddRead(Script, OldPages);
      if I <= 2 then AddType2Writes(Script, I)
      else AddType2Writes(Script);
      if I = 3 then AddRead(Script, OldPages);
      if I = 4 then Script.Add('300002A8', '', 32, 0, True);
      if I >= 5 then AddRead(Script, NewPages);
      if I = 6 then Script.Uids[1] := HexToBytes('04AABBCCDDEEFF');
      Script.EndFails := I in [3, 6];
      Raised := False;
      try Data := Programmer.ProgramType2DirectWriteUid(Uid);
      except on E: EContactlessWriteUncertain do Raised := True; end;
      Check(Raised and (Script.Ends = 1), 'Each partial page write, read-back and fresh activation failure uncertain');
      if I <= 2 then Check(Script.Position = I + 2, 'Stop at failing page, no rollback or replay');
    end;
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Raised := False;
    try Data := Programmer.ProgramType2DirectWriteUid(HexToBytes('04112288445566'));
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid cascade before session');
    Raised := False;
    try Data := Programmer.ProgramType2DirectWriteUid(HexToBytes('00112233445566778899'));
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Wrong UID size before session');
  finally Programmer.Free; end;
  Writeln('PASS: Type 2 DirectWrite, independent results, no-op and all partial-write stages.');
end;

procedure AddConfiguration(Script: TPcscScript);
begin
  Script.Add('D43202000B0D', 'D5339000');
  Script.Add('D4320400', 'D5339000');
  Script.Add('D43205000000', 'D5339000');
end;

procedure AddActivation(Script: TPcscScript; const AUid: string = '11223344');
begin
  Script.Add('D4320100', 'D5339000');
  Script.Add('D4320101', 'D5339000');
  Script.Add('D44A0100', 'D54B0101000408' + IntToHex(Length(AUid) div 2, 2) + AUid + '9000');
  Script.Add('D40663026303633D', 'D5078080009000');
  Script.Add('D408630200630300633D00', 'D5099000');
end;

procedure AddRelease(Script: TPcscScript; const AFailRestore: Boolean = False);
begin
  Script.Add('D408630280630380633D00', 'D5099000', AFailRestore);
  Script.Add('D4320100', 'D5339000');
end;

procedure TestAcr122Frames;
var Script: TPcscScript; Reader: IRawContactlessReader; Response: TRawRfResponse;
  Uid, Frame: TBytes; Raised: Boolean; I: Integer;
begin
  for I := 0 to 2 do
  begin
    Script := TPcscScript.Create;
    Reader := TAcr122RawReader.Create(Script);
    AddConfiguration(Script);
    if I = 0 then AddActivation(Script, '11223344')
    else if I = 1 then AddActivation(Script, '04112233445566')
    else AddActivation(Script, '00112233445566778899');
    Script.Add('D408630200630300633D07', 'D5099000');
    Script.Add('D44240', 'D543000A9000');
    Script.Add('D406633C', 'D507049000');
    Script.Add('D408630200630300633D00', 'D5099000');
    Script.Add('D442500057CD', 'D543019000');
    AddRelease(Script);
    Reader.BeginSession;
    Uid := Reader.Activate;
    Check(Length(Uid) = 4 + I * 3, 'Selected UID size from fresh PN532 response');
    Frame := HexToBytes('40');
    Response := Reader.Exchange(Frame, 7);
    Check((Response.BitCount = 4) and (BytesToHex(Response.Data) = '0A') and not Response.TimedOut, 'Exact four-bit ACK with manual CRC');
    Check(BytesToHex(Frame) = '40', 'Outgoing frame untouched');
    Response := Reader.Exchange(HexToBytes('500057CD'), 32);
    Check(Response.TimedOut and (Response.BitCount = 0) and (Length(Response.Data) = 0), 'Only PN532 RF timeout mapped to explicit timeout');
    Raised := False;
    try Response := Reader.Exchange(Frame, 9);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Position = 13), 'Invalid frame rejected without reader I/O');
    Reader.EndSession;
    Check((Script.Position = Length(Script.Steps)) and (Script.Begins = 1) and (Script.Ends = 1), 'All exact APDUs, framing restored, RF off and exclusive release');
    Reader := nil;
  end;
  Writeln('PASS: ACR122U PN532 exact commands, 4/7/10 selection, seven-bit TX, four-bit RX and timeout.');
end;

procedure TestAcr122Failures;
var Script: TPcscScript; Reader: IRawContactlessReader; Response: TRawRfResponse;
  Uid: TBytes; I: Integer; Raised: Boolean;
begin
  for I := 0 to 9 do
  begin
    Script := TPcscScript.Create;
    Reader := TAcr122RawReader.Create(Script);
    if I = 0 then Script.BeginFails := True
    else if I = 1 then Script.Add('D43202000B0D', 'D5339000', True)
    else AddConfiguration(Script);
    if I = 1 then Script.Add('D4320100', 'D5339000');
    if I = 2 then
    begin
      Script.Add('D4320100', 'D5339000');
      Script.Add('D4320101', 'D5339000');
      Script.Add('D44A0100', 'D54B009000');
      Script.Add('D4320100', 'D5339000');
    end;
    if I >= 3 then
    begin
      AddActivation(Script);
      if I in [3..7] then
      begin
        Script.Add('D408630200630300633D00', 'D5099000');
        case I of
          3: Script.Add('D44243', 'D543029000');
          4: Script.Add('D44243', 'D543010A9000');
          5: Script.Add('D44243', 'D541000A9000');
          6: Script.Add('D44243', 'D5439000');
          7: Script.Add('D44243', 'D543000A9000');
        end;
        if I = 7 then Script.Add('D406633C', 'D5079000');
      end;
      AddRelease(Script, I = 8);
      Script.EndFails := I in [3, 8, 9];
    end;
    Raised := False;
    try
      Reader.BeginSession;
      try
        Uid := Reader.Activate;
        if I in [3..7] then Response := Reader.Exchange(HexToBytes('43'), 8);
      except
        try Reader.EndSession;
        except
          // Test primary error remains observable.
        end;
        raise;
      end;
      Reader.EndSession;
    except on E: Exception do Raised := True; end;
    Check(Raised, 'Failed configuration, target, status, envelope, bit count or cleanup');
    Check(Script.Ends = Ord(I <> 0), 'Release acquisition exactly once, even on restoration failure');
    Check(Script.Position = Length(Script.Steps), 'No hidden retries; restore and RF-off attempted');
    Reader := nil;
  end;
  Writeln('PASS: ACR122 errors, malformed PN532 envelopes, restoration/release and acquisition failures.');
end;

procedure AddAcrExchange(Script: TPcscScript; const AFrame, AResponse: string;
  const ATransmitLastBits, AReceiveLastBits: Byte; const ATimeout: Boolean = False);
begin
  Script.Add('D408630200630300633D' + IntToHex(ATransmitLastBits, 2), 'D5099000');
  if ATimeout then Script.Add('D442' + AFrame, 'D543019000')
  else
  begin
    Script.Add('D442' + AFrame, 'D54300' + AResponse + '9000');
    Script.Add('D406633C', 'D507' + IntToHex(AReceiveLastBits, 2) + '9000');
  end;
end;

procedure TestAdapterIntegration;
var Script: TPcscScript; Programmer: TRawUidProgrammer; Data: TProgrammableUidResult;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    Script := TPcscScript.Create;
    Programmer.Reader := TAcr122RawReader.Create(Script);
    AddConfiguration(Script);
    AddActivation(Script);
    AddAcrExchange(Script, '500057CD', '', 0, 0, True);
    AddAcrExchange(Script, '40', '0A', 7, 4);
    AddAcrExchange(Script, '43', '0A', 0, 4);
    AddAcrExchange(Script, '300002A8', WithCrc(OldBlock), 0, 0);
    AddAcrExchange(Script, WithCrc('A000'), '0A', 0, 4);
    AddAcrExchange(Script, WithCrc(NewBlock), '0A', 0, 4);
    AddAcrExchange(Script, '300002A8', WithCrc(NewBlock), 0, 0);
    Script.Add('D408630280630380633D00', 'D5099000');
    AddActivation(Script, 'A1B2C3D4');
    AddRelease(Script);
    Data := Programmer.ProgramClassicUid(crupGen1a, HexToBytes('A1B2C3D4'));
    Check(Data.ActiveUidVerified and (BytesToHex(Data.ManufacturerBlock) = NewBlock), 'Complete programmer/ACR122/PCSC integration');
    Check((Script.Position = Length(Script.Steps)) and (Script.Begins = 1) and (Script.Ends = 1), 'Whole operation under one native transaction');
  finally Programmer.Free; end;
  Writeln('PASS: full Gen1a operation through the concrete ACR122 adapter and PC/SC transport.');
end;

begin
  try
    TestCodecs;
    TestClassicProgramming;
    TestClassicFailures;
    TestType2Programming;
    TestAcr122Frames;
    TestAcr122Failures;
    TestAdapterIntegration;
    Writeln('PASS: ', Checks, ' assertions across seven raw UID test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
