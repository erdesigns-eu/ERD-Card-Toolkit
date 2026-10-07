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
  ERD.Card.Contactless.UID, ERD.Card.Contactless.UID.Profiles,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.ACR122;

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
    PasswordFrames: array of TBytes;
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
var I: Integer;
begin
  Check(Active and (Position < Length(Steps)), 'No unexpected frame or replay');
  Check(BytesEqual(AFrame, Steps[Position].Wire) and (ABitCount = Steps[Position].Bits), 'Exact RF frame and bit count');
  if (Length(AFrame) > 0) and (AFrame[0] = $CF) then
  begin
    I := Length(PasswordFrames);
    SetLength(PasswordFrames, I + 1);
    PasswordFrames[I] := AFrame; // Deliberate alias to observe local command overwriting.
  end;
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

procedure CheckPasswordWiping(Script: TRawScript);
var I, J: Integer;
begin
  for I := 0 to Length(Script.PasswordFrames) - 1 do
    for J := 0 to Length(Script.PasswordFrames[I]) - 1 do
      Check(Script.PasswordFrames[I][J] = 0, 'Every local password-bearing command overwritten, including failures');
end;

procedure Gen4Fixture(const ALayout: TGen4UidLayout; out AOldUid, ANewUid: string;
  out AOld, ANew: TUidManufacturerBlocks);
begin
  SetLength(AOld, 1);
  SetLength(ANew, 1);
  case ALayout of
    g4ulClassic4:
    begin
      AOldUid := '11223344'; ANewUid := 'A1B2C3D4';
      AOld[0] := HexToBytes(OldBlock); ANew[0] := HexToBytes(NewBlock);
    end;
    g4ulClassic7:
    begin
      AOldUid := '04112233445566'; ANewUid := '04AABBCCDDEEFF';
      AOld[0] := HexToBytes('04112233445566884400C82000000000');
      ANew[0] := HexToBytes('04AABBCCDDEEFF884400C82000000000');
    end;
    g4ulClassic10, g4ulType2_10:
    begin
      AOldUid := '04112233445566778899'; ANewUid := '04AABBCCDDEEFF102030';
      AOld[0] := HexToBytes('04112233445566778899112233445566');
      ANew[0] := HexToBytes('04AABBCCDDEEFF102030112233445566');
    end;
    g4ulType2_4:
    begin
      AOldUid := '11223344'; ANewUid := 'A1B2C3D4';
      AOld[0] := HexToBytes('11223344AABBCCDDEEFF010203040506');
      ANew[0] := HexToBytes('A1B2C3D4AABBCCDDEEFF010203040506');
    end;
    g4ulType2_7:
    begin
      AOldUid := '04112233445566'; ANewUid := '04AABBCCDDEEFF';
      SetLength(AOld, 3); SetLength(ANew, 3);
      AOld[0] := HexToBytes('041122BF101112131415161718191A1B');
      AOld[1] := HexToBytes('33445566202122232425262728292A2B');
      AOld[2] := HexToBytes('4448ABCD303132333435363738393A3B');
      ANew[0] := HexToBytes('04AABB9D101112131415161718191A1B');
      ANew[1] := HexToBytes('CCDDEEFF202122232425262728292A2B');
      ANew[2] := HexToBytes('0048ABCD303132333435363738393A3B');
    end;
  end;
end;

function Gen4Config(const ALayout: TGen4UidLayout; const ALength: Integer = 32): TBytes;
begin
  Result := nil;
  SetLength(Result, ALength);
  if ALayout in [g4ulType2_4, g4ulType2_7, g4ulType2_10] then Result[0] := 1;
  case TGen4UidCodec.UidLength(ALayout) of
    4: Result[1] := 0;
    7: Result[1] := 1;
    10: Result[1] := 2;
  end;
  Result[2] := 1; Result[3] := 2; Result[4] := 3; Result[5] := 4; // Synthetic password.
  Result[6] := 2;
  Result[24] := $84;
  Result[26] := $28;
  Result[28] := $6B;
  Result[29] := 2;
  if ALength = 32 then begin Result[30] := $45; Result[31] := $AB; end;
end;

procedure AddGen4(Script: TRawScript; const ACommand, AData, AResponse: string;
  const AFails: Boolean = False; const ATimeout: Boolean = False; const AReceivedBits: Integer = -1);
var Payload: string; Bits: Integer;
begin
  Payload := 'CF01020304' + ACommand + AData;
  if AReceivedBits < 0 then Bits := Length(AResponse) * 4 else Bits := AReceivedBits;
  Script.Add(WithCrc(Payload), AResponse, (Length(Payload) div 2 + 2) * 8, Bits, ATimeout, AFails);
end;

procedure AddGen4Reads(Script: TRawScript; const ABlocks: TUidManufacturerBlocks);
var I: Integer;
begin
  for I := 0 to Length(ABlocks) - 1 do AddGen4(Script, 'CE', IntToHex(I, 2), WithCrc(BytesToHex(ABlocks[I])));
end;

procedure TestExtendedCodecs;
var Layout: TGen4UidLayout; OldUid, NewUid: string; OldData, NewData, Prepared: TUidManufacturerBlocks;
  Config, Uid, Command: TBytes; I, J: Integer; Raised: Boolean;
begin
  Check(WithCrc('9000') = '9000FD07', 'Gen3/Gen4 exact RF status CRC golden vector');
  Check(BytesToHex(TGen3UidCodec.BuildUidCommand(g3us4Byte, HexToBytes('A1B2C3D4'))) = '90FBCCCC07A1B2C3D4', 'Gen3 four-byte fixed 07 field');
  Check(BytesToHex(TGen3UidCodec.BuildUidCommand(g3us7Byte, HexToBytes('04AABBCCDDEEFF'))) = '90FBCCCC0704AABBCCDDEEFF', 'Gen3 seven-byte command');
  for Layout := Low(TGen4UidLayout) to High(TGen4UidLayout) do
  begin
    Gen4Fixture(Layout, OldUid, NewUid, OldData, NewData);
    Check(BytesToHex(TGen4UidCodec.DecodeUid(Layout, OldData)) = OldUid, 'All six existing Gen4 UID mappings');
    Prepared := TGen4UidCodec.PrepareBlocks(Layout, OldData, HexToBytes(NewUid));
    Check(Length(Prepared) = Length(NewData), 'One/three full Gen4 blocks');
    for I := 0 to Length(NewData) - 1 do
    begin
      Check(BytesEqual(Prepared[I], NewData[I]), 'Golden full-block metadata/BCC preservation');
      for J := 0 to 15 do
      begin
        Prepared[I][J] := Prepared[I][J] xor $FF;
        Check(BytesToHex(OldData[I]) <> BytesToHex(Prepared[I]), 'Preparation never aliases source blocks');
      end;
    end;
    for I := 0 to 7 do
    begin
      Config := Gen4Config(Layout, 30 + 2 * (I mod 2));
      case I of
        0: Config[0] := Config[0] xor 1;
        1: Config[1] := 3;
        2: Config[6] := 0;
        3: Config[6] := 1;
        4: Config[6] := 4;
        5: Config[7] := 17;
        6: SetLength(Config, 31);
      end;
      Raised := False;
      try TGen4UidCodec.ValidateConfiguration(Layout, Config);
      except on E: EProgrammableUidError do Raised := True; end;
      Check(Raised = (I <> 7), 'Only supported existing protocol/length/stable config');
    end;
    Uid := HexToBytes(NewUid);
    if Length(Uid) = 4 then Uid[0] := $88 else Uid[3] := $88;
    Raised := False;
    try TGen4UidCodec.ValidateUid(Layout, Uid);
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised, 'Four/seven/ten-byte cascade restrictions');
  end;
  Uid := HexToBytes('04112233445588778899');
  TGen4UidCodec.ValidateUid(g4ulClassic10, Uid);
  Check(Uid[6] = $88, 'AN10927 does not exclude 88 at ten-byte UID6');
  Raised := False;
  try Command := TGen3UidCodec.BuildUidCommand(g3us4Byte, Uid);
  except on E: EProgrammableUidError do Raised := True; end;
  Check(Raised, 'Gen3 does not accept a ten-byte request');
  Writeln('PASS: Gen3 fixed-field framing and six Gen4 layouts, metadata, config and ten-byte UID rules.');
end;

procedure TestGen3Programming;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TGen3UidResult;
  Size: TGen3UidSize; Uid: string;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for Size := Low(TGen3UidSize) to High(TGen3UidSize) do
    begin
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      if Size = g3us4Byte then begin Script.SelectUid('01020304'); Uid := 'A1B2C3D4'; end
      else begin Script.SelectUid('04010203040506'); Uid := '04AABBCCDDEEFF'; end;
      Script.SelectUid(Uid);
      AddRead(Script, OldBlock); // Deliberately independent of the selected RF UID.
      Script.Add(WithCrc('90FBCCCC07' + Uid), '9000FD07', (7 + Length(Uid) div 2) * 8, 32);
      AddRead(Script, OldBlock);
      Data := Programmer.ProgramGen3Uid(Size, HexToBytes(Uid));
      Check(Data.ActiveUidVerified and (BytesToHex(Data.ManufacturerBlock) = OldBlock), 'Gen3 UID-only change leaves block zero unchanged');
      Check((Script.Position = 3) and (Script.Selections = 2) and (Script.Ends = 1), 'One UID command, fresh activation and exact original block');
    end;
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Script.SelectUid('01020304');
    AddRead(Script, OldBlock);
    Data := Programmer.ProgramGen3Uid(g3us4Byte, HexToBytes('01020304'));
    Check(Data.ActiveUidVerified and (Script.Position = 1), 'Gen3 no-op does not freeze/write block or require its embedded UID');
  finally Programmer.Free; end;
  Writeln('PASS: four/seven-byte Gen3 independent UID register and verified no-op.');
end;

procedure TestGen3Failures;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TGen3UidResult;
  I: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for I := 0 to 9 do
    begin
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      if I = 0 then Script.SelectUid('04112233445566') else Script.SelectUid('01020304');
      if I = 6 then Script.SelectUid('01020304') else Script.SelectUid('A1B2C3D4');
      if I = 1 then Script.Add('300002A8', '', 32, 0, True)
      else if I > 0 then AddRead(Script, OldBlock);
      if I >= 2 then
        case I of
          2: Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), WithCrc('6300'), 88, 32);
          3: Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), '0A', 88, 4);
          4: Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), '9000FD06', 88, 32);
          5: Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), '', 88, 0, True);
          9: Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), '', 88, 0, False, True);
        else Script.Add(WithCrc('90FBCCCC07A1B2C3D4'), '9000FD07', 88, 32); end;
      if I = 7 then AddRead(Script, NewBlock);
      if I = 8 then AddRead(Script, OldBlock);
      Script.EndFails := I in [2, 7, 8];
      Raised := False;
      try Data := Programmer.ProgramGen3Uid(g3us4Byte, HexToBytes('A1B2C3D4'));
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := I >= 2;
          if I = 7 then Check(E.OriginalErrorClass = 'EContactlessError', 'Gen3 block change wins over cleanup error');
        end;
        on E: EContactlessError do Raised := I < 2;
      end;
      Check(Raised and (Script.Ends = 1), 'Gen3 failures classified before/after dispatch, no retries');
      Check(Script.Position = Length(Script.Steps), 'Stop at failed Gen3 stage');
    end;
  finally Programmer.Free; end;
  Writeln('PASS: Gen3 response CRC/status, timeout, transport, fresh UID, unchanged block and release failures.');
end;

procedure TestGen4Programming;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TGen4UidResult; Layout: TGen4UidLayout;
  OldUid, NewUid: string; OldData, NewData: TUidManufacturerBlocks; Config, Password, Uid: TBytes; I: Integer;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    Password := HexToBytes('01020304');
    for Layout := Low(TGen4UidLayout) to High(TGen4UidLayout) do
    begin
      Gen4Fixture(Layout, OldUid, NewUid, OldData, NewData);
      Config := Gen4Config(Layout, 30 + 2 * (Ord(Layout) mod 2));
      Uid := HexToBytes(NewUid);
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid(OldUid); Script.SelectUid(NewUid);
      AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
      AddGen4Reads(Script, OldData);
      for I := 0 to Length(NewData) - 1 do
        AddGen4(Script, 'CD', IntToHex(I, 2) + BytesToHex(NewData[I]), '9000FD07');
      AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
      AddGen4Reads(Script, NewData);
      Data := Programmer.ProgramGen4Uid(Layout, Uid, Password);
      Check(Data.ActiveUidVerified and (Data.Layout = Layout), 'Six Gen4 layouts activated and verified');
      for I := 0 to Length(NewData) - 1 do Check(BytesEqual(Data.ManufacturerBlocks[I], NewData[I]), 'Complete metadata and hidden-byte read-back after RF cycle');
      Check((Script.Position = 2 + 3 * Length(NewData)) and (Script.Selections = 2) and (Script.Ends = 1), 'Whole Gen4 programming, config unchanged, no guessed extra commands');
      Check((BytesToHex(Password) = '01020304') and (BytesToHex(Uid) = NewUid), 'Caller password and UID never modified');
      Data.RequestedUid[0] := 0;
      Check(Uid[0] <> 0, 'Independent Gen4 result UID');
      CheckPasswordWiping(Script);
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid(OldUid);
      AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
      AddGen4Reads(Script, OldData);
      Data := Programmer.ProgramGen4Uid(Layout, HexToBytes(OldUid), Password);
      Check(Data.ActiveUidVerified and (Script.Position = 1 + Length(OldData)), 'Each Gen4 layout is a verified no-op when already matching');
      CheckPasswordWiping(Script);
    end;
    // A Gen4 card can calculate RF BCC even if its stored Classic BCC differs.
    // A no-op must return the bytes actually read, not a prepared but unwritten correction.
    Gen4Fixture(g4ulClassic4, OldUid, NewUid, OldData, NewData);
    OldData[0][4] := $45;
    Config := Gen4Config(g4ulClassic4);
    Script := TRawScript.Create;
    Programmer.Reader := Script;
    Script.SelectUid(OldUid);
    AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
    AddGen4Reads(Script, OldData);
    Data := Programmer.ProgramGen4Uid(g4ulClassic4, HexToBytes(OldUid), Password);
    Check((Data.ManufacturerBlocks[0][4] = $45) and (Script.Position = 2), 'No-op snapshot retains actual stored BCC, no unwritten correction');
    CheckPasswordWiping(Script);
  finally Programmer.Free; end;
  Writeln('PASS: six Gen4 UMC layouts, password-only backdoor, stable config, hidden-byte verification and no-ops.');
end;

procedure TestGen4PreparationFailures;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TGen4UidResult; Layout: TGen4UidLayout;
  OldUid, NewUid: string; OldData, NewData: TUidManufacturerBlocks; Config, Password, Uid: TBytes;
  I: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for I := 0 to 16 do
    begin
      Layout := g4ulClassic4;
      if I in [11, 12] then Layout := g4ulType2_7;
      Gen4Fixture(Layout, OldUid, NewUid, OldData, NewData);
      Config := Gen4Config(Layout);
      Password := HexToBytes('01020304'); Uid := HexToBytes(NewUid);
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      if I = 0 then Script.SelectUid('04112233445566') else Script.SelectUid(OldUid);
      case I of
        1: Config[0] := 1;
        2: Config[1] := 2;
        3: Config[6] := 0;
        4: Config[6] := 1;
        5: Config[6] := 4;
        6: Config[7] := 17;
        7: SetLength(Config, 29);
        9: SetLength(OldData[0], 15);
        10: OldData[0][0] := 0;
        11: OldData[0][3] := 0;
        12: OldData[2][0] := 0;
        13: SetLength(Password, 3);
        14: SetLength(Uid, 10);
        15: Uid[0] := $88;
        16: Script.BeginFails := True;
      end;
      if I in [1..12] then
      begin
        if I = 8 then AddGen4(Script, 'C6', '', BytesToHex(Config) + '0000')
        else AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
        if I in [9..12] then AddGen4Reads(Script, OldData);
      end;
      Raised := False;
      try Data := Programmer.ProgramGen4Uid(Layout, Uid, Password);
      except
        on E: EContactlessWriteUncertain do Raised := False;
        on E: EContactlessError do Raised := True;
        on E: EProgrammableUidError do Raised := True;
        on E: ECardTransportError do Raised := I = 16;
      end;
      Check(Raised, 'Reject unsupported/malformed Gen4 setup before writing');
      Check(Script.Ends = Ord(I <= 12), 'Only acquired sessions are released');
      Check(Script.Position = Length(Script.Steps), 'No programming or config mutation on invalid setup');
      CheckPasswordWiping(Script);
    end;
  finally Programmer.Free; end;
  Writeln('PASS: Gen4 configuration, shadow/restore, password/UID, CRC/BCC, initial selection and acquisition validation.');
end;

procedure TestGen4WriteFailures;
var Programmer: TRawUidProgrammer; Script: TRawScript; Data: TGen4UidResult; Layout: TGen4UidLayout;
  OldUid, NewUid: string; OldData, NewData: TUidManufacturerBlocks; Config, Changed: TBytes;
  I, BlockIndex: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    for I := 0 to 14 do
    begin
      if I in [10, 11, 14] then Layout := g4ulType2_7 else Layout := g4ulClassic4;
      Gen4Fixture(Layout, OldUid, NewUid, OldData, NewData);
      Config := Gen4Config(Layout);
      Script := TRawScript.Create;
      Programmer.Reader := Script;
      Script.SelectUid(OldUid);
      if I = 5 then Script.SelectUid(OldUid)
      else if I = 13 then Script.SelectUid('00112233')
      else Script.SelectUid(NewUid);
      AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Config)));
      AddGen4Reads(Script, OldData);
      for BlockIndex := 0 to Length(NewData) - 1 do
      begin
        if (I = 0) or ((I = 10) and (BlockIndex = 1)) or ((I = 11) and (BlockIndex = 2)) then
        begin AddGen4(Script, 'CD', IntToHex(BlockIndex, 2) + BytesToHex(NewData[BlockIndex]), '', True); Break; end;
        case I of
          1: AddGen4(Script, 'CD', '00' + BytesToHex(NewData[0]), '', False, True, 0);
          2: AddGen4(Script, 'CD', '00' + BytesToHex(NewData[0]), WithCrc('6300'));
          3: AddGen4(Script, 'CD', '00' + BytesToHex(NewData[0]), '0A', False, False, 4);
          4: AddGen4(Script, 'CD', '00' + BytesToHex(NewData[0]), '9000FD06');
        else AddGen4(Script, 'CD', IntToHex(BlockIndex, 2) + BytesToHex(NewData[BlockIndex]), '9000FD07'); end;
      end;
      if I in [6..9, 12, 14] then
      begin
        Changed := CopyBytes(Config);
        if I = 6 then Changed[31] := Changed[31] xor 1;
        AddGen4(Script, 'C6', '', WithCrc(BytesToHex(Changed)), I = 12);
        if I in [7, 9, 14] then
        begin
          if I = 7 then NewData[0][15] := NewData[0][15] xor 1;
          if I = 14 then NewData[2][15] := NewData[2][15] xor 1;
          AddGen4Reads(Script, NewData);
        end;
        if I = 8 then AddGen4(Script, 'CE', '00', BytesToHex(NewData[0]) + '0000');
      end;
      Script.EndFails := I in [2, 7, 9];
      Raised := False;
      try Data := Programmer.ProgramGen4Uid(Layout, HexToBytes(NewUid), HexToBytes('01020304'));
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := True;
          if I = 7 then Check(E.OriginalErrorClass = 'EContactlessError', 'Gen4 metadata failure wins over release');
        end;
      end;
      Check(Raised and (Script.Ends = 1), 'Every post-dispatch failure uncertain, including status and partial blocks');
      Check(Script.Position = Length(Script.Steps), 'No repeat, rollback, freeze or configuration write');
      CheckPasswordWiping(Script);
    end;
  finally Programmer.Free; end;
  Writeln('PASS: Gen4 denied/partial writes, transport, CRC, old/wrong UID, config changes, hidden bytes and release failure.');
end;

procedure AddExtendedConfiguration(Script: TPcscScript);
begin
  Script.Add('D43202000B10', 'D5339000');
  Script.Add('D4320400', 'D5339000');
  Script.Add('D43205000000', 'D5339000');
  Script.Add('D41224', 'D5139000');
end;

procedure AddExtendedActivation(Script: TPcscScript; const AUid: string);
begin
  Script.Add('D4320100', 'D5339000');
  Script.Add('D4320101', 'D5339000');
  Script.Add('D44A0100', 'D54B0101008428' + IntToHex(Length(AUid) div 2, 2) + AUid + '9000');
  Script.Add('D40663026303633D', 'D5078080009000');
  Script.Add('D408630200630300633D00', 'D5099000');
end;

procedure TestExtendedAdapter;
var Script: TPcscScript; Programmer: TRawUidProgrammer; Backend: TAcr122RawReader;
  Reader: IRawContactlessReader; Data: TGen4UidResult; Config: TBytes;
  HeldTransport: ICardTransport;
  OldData, NewData: TUidManufacturerBlocks; OldUid, NewUid: string;
  I: Integer; Raised: Boolean;
begin
  Programmer := TRawUidProgrammer.Create(nil);
  try
    Script := TPcscScript.Create;
    Backend := TAcr122RawReader.Create(Script, $10, True);
    Programmer.Reader := Backend;
    Check((Backend.ResponseTimeoutCode = $10) and Backend.SkipAutomaticRats, 'Immutable long-timeout/raw-before-RATS options');
    Gen4Fixture(g4ulClassic10, OldUid, NewUid, OldData, NewData);
    Config := Gen4Config(g4ulClassic10);
    AddExtendedConfiguration(Script);
    AddExtendedActivation(Script, OldUid);
    AddAcrExchange(Script, WithCrc('CF01020304C6'), WithCrc(BytesToHex(Config)), 0, 0);
    AddAcrExchange(Script, WithCrc('CF01020304CE00'), WithCrc(BytesToHex(OldData[0])), 0, 0);
    AddAcrExchange(Script, WithCrc('CF01020304CD00' + BytesToHex(NewData[0])), '9000FD07', 0, 0);
    Script.Add('D408630280630380633D00', 'D5099000');
    AddExtendedActivation(Script, NewUid);
    AddAcrExchange(Script, WithCrc('CF01020304C6'), WithCrc(BytesToHex(Config)), 0, 0);
    AddAcrExchange(Script, WithCrc('CF01020304CE00'), WithCrc(BytesToHex(NewData[0])), 0, 0);
    AddRelease(Script);
    Script.Add('D41234', 'D5139000');
    Data := Programmer.ProgramGen4Uid(g4ulClassic10, HexToBytes(NewUid), HexToBytes('01020304'));
    Check(Data.ActiveUidVerified and (Script.Position = Length(Script.Steps)), 'Complete ten-byte Gen4 programming through ACR122, no automatic RATS/ATS required');
    Check((Script.Begins = 1) and (Script.Ends = 1), 'One exclusive session and baseline parameter restoration');
    for I := 0 to 3 do
    begin
      Script := TPcscScript.Create;
      Reader := TAcr122RawReader.Create(Script, $10, True);
      AddExtendedConfiguration(Script);
      if I = 0 then Script.Steps[3].Fails := True;
      if I <> 0 then AddExtendedActivation(Script, '11223344');
      if I <> 0 then AddRelease(Script, I = 1)
      else Script.Add('D4320100', 'D5339000');
      if I = 2 then Script.Steps[Length(Script.Steps) - 1].Fails := True;
      Script.Add('D41234', 'D5139000', I = 3);
      Script.EndFails := True;
      Raised := False;
      try
        Reader.BeginSession;
        Reader.Activate;
        Reader.EndSession;
      except on E: Exception do Raised := True; end;
      Check(Raised and (Script.Ends = 1) and (Script.Position = Length(Script.Steps)), 'Parameter restoration attempted after acquisition/framing/RF-off failure, primary error and lock release');
      Reader := nil;
    end;
    Script := TPcscScript.Create;
    Raised := False;
    HeldTransport := Script; // Retain the fake when constructor validation deliberately fails.
    try Reader := TAcr122RawReader.Create(Script, 0);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Infinite timeout is rejected before hardware access');
    Raised := False;
    try Reader := TAcr122RawReader.Create(HeldTransport, $11);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Unsupported timeout code rejected before hardware access');
    HeldTransport := nil;
  finally Programmer.Free; end;
  Writeln('PASS: concrete ten-byte Gen4 adapter chain, bounded timeout, RATS suppression and baseline cleanup.');
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
    TestExtendedCodecs;
    TestGen3Programming;
    TestGen3Failures;
    TestGen4Programming;
    TestGen4PreparationFailures;
    TestGen4WriteFailures;
    TestExtendedAdapter;
    Writeln('PASS: ', Checks, ' assertions across fourteen raw UID test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
