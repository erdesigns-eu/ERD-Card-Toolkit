program MemoryCounterTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Memory, ERD.Card.Memory.Counter,
  ERD.Card.Memory.Capabilities;

type
  TStep = record Command, Response: TBytes; end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends, FailAt: Integer;
    Active, BeginFails, EndFails: Boolean;
    MutatePin: TBytes;
    constructor Create;
    procedure Add(const Command, Response: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const Command: TBytes): TBytes;
  end;
  TBare = class(TInterfacedObject, ICardTransport)
  public
    Calls: Integer;
    function Exchange(const Command: TBytes): TBytes;
  end;

var Checks: Integer;

procedure Check(const Condition: Boolean; const Message: string);
begin Inc(Checks); if not Condition then raise Exception.Create(Message); end;

constructor TScript.Create;
begin inherited Create; FailAt := -1; end;

procedure TScript.Add(const Command, Response: string);
var N: Integer;
begin
  N := Length(Steps); SetLength(Steps, N + 1);
  Steps[N].Command := HexToBytes(Command); Steps[N].Response := HexToBytes(Response);
end;

procedure TScript.BeginTransaction;
begin
  Check(not Active, 'Nested acquisition'); Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('Injected acquisition failure');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Check(Active, 'Release without acquisition'); Inc(Ends); Active := False;
  if EndFails then raise ECardTransportError.Create('Sensitive cleanup message');
end;

function TScript.Exchange(const Command: TBytes): TBytes;
var N: Integer;
begin
  Check(Active, 'Command without transaction'); N := Position; Inc(Position);
  Check(N < Length(Steps), 'Extra/replayed command');
  Check(BytesEqual(Command, Steps[N].Command), 'Literal wire transcript mismatch');
  if (N = 0) and (Length(MutatePin) <> 0) then MutatePin[0] := $EE;
  if N = FailAt then raise ECardTransportError.Create('Sensitive transport message');
  Result := CopyBytes(Steps[N].Response);
end;

function TBare.Exchange(const Command: TBytes): TBytes;
begin Inc(Calls); Result := HexToBytes('9000'); end;

procedure Complete(const Script: TScript);
begin
  Check(Script.Position = Length(Script.Steps), 'Missing command');
  Check((Script.Begins = 1) and (Script.Ends = 1) and not Script.Active, 'Transaction lifetime');
end;

procedure AddWrite(const S: TScript; const Mode: string = '00';
  const Before: string = 'FFFFFFFF'; const After: string = 'FF7FFFFF');
begin
  S.Add('FFA400000107', '9000'); S.Add('FFB0000004', Before + '9000');
  S.Add('FFD0000102' + Mode + '7F', '9000'); S.Add('FFB0000004', After + '9000');
end;

procedure TestCodecsAndCapabilities;
var Model: TSleCounterModel; Mode: TSleCounterWriteMode; A, I: Integer;
  B: TBytes; Rejected: Boolean; C: TAcsMemoryCapabilities; M: TMemoryCardModel;
begin
  for Model := Low(TSleCounterModel) to High(TSleCounterModel) do
  begin
    Check(BytesToHex(TSleCounterCodec.Select(Model)) = 'FFA400000107', 'Selector literal');
    Check(TAcsMemoryCapabilityCatalog.CounterName(Model) <> '', 'Counter name');
    for Mode := Low(TSleCounterWriteMode) to High(TSleCounterWriteMode) do
    begin
      Rejected := False;
      try B := TSleCounterCodec.Write(Model, 255, $7F, Mode);
      except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected = ((Model = scmSle4406) and (Mode in [scwBackup, scwCarryBackup])), 'Backup model restriction');
      if not Rejected then Check(BytesToHex(B) = 'FFD000FF02' + IntToHex(Ord(Mode), 2) + '7F', 'Mode literal');
    end;
  end;
  for A := 0 to 255 do
  begin
    Check(BytesToHex(TSleCounterCodec.Read(A, 1)) = 'FFB000' + IntToHex(A, 2) + '01', 'Read address');
    for I := 1 to 128 do
    begin
      Rejected := False;
      try B := TSleCounterCodec.Read(A, I); except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected = (I > 256 - A), 'Read boundary');
    end;
  end;
  Check(BytesToHex(TSleCounterCodec.PresentCode(HexToBytes('123456'))) = 'FF2000000409123456', 'Code presentation literal');
  Check(BytesToHex(TSleCounterCodec.Challenge(scmSle5536, $80, $A0,
    HexToBytes('010203040506'))) = 'FF8400000880A0010203040506', 'Challenge literal');
  Check(BytesToHex(TSleCounterCodec.GetCertificate) = 'FFC0000002', 'Retrieval literal');
  for I := 0 to 255 do
  begin
    Rejected := False;
    try B := TSleCounterCodec.Challenge(scmSle5536, Byte(I), $A0, HexToBytes('010203040506'));
    except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected = not (I in [0, 1, $80, $81]), 'Key selector restriction');
  end;
  Rejected := False;
  try B := TSleCounterCodec.Challenge(scmSle4436, $80, $A0, HexToBytes('010203040506'));
  except on E: EMemoryCardError do Rejected := True; end;
  Check(Rejected, 'No CBC on 4436');
  Rejected := False;
  try B := TSleCounterCodec.Challenge(scmSle4406, 0, $A0, HexToBytes('010203040506'));
  except on E: EMemoryCardError do Rejected := True; end;
  Check(Rejected, 'No certificate on 4406');
  Rejected := False;
  try B := TSleCounterCodec.Challenge(scmSle5536, 0, 0, HexToBytes('010203040506'));
  except on E: EMemoryCardError do Rejected := True; end;
  Check(Rejected, 'Zero clocks refused');
  for M := Low(TMemoryCardModel) to High(TMemoryCardModel) do
    Check(TAcsMemoryCapabilityCatalog.ModelName(M) <> '', 'Ordinary profile name');
  C := TAcsMemoryCapabilityCatalog.ForDialect(amdAcr38Ccid);
  Check((C.CounterModels = [scmSle4406..scmSle6636]) and
    (C.CertificateModels = [scmSle4436..scmSle6636]), 'ACR38 counter capability');
  Check(C.ReadModels = C.WriteModels, 'Ordinary writes available');
  Check(C.PinChangeModels = [mcmSle4442, mcmSle5542], 'No implicit three-wire PIN change');
  Check(not (mcmI2c8Kbit in C.ProtectionModels), 'I2C protection not claimed');
  C := TAcsMemoryCapabilityCatalog.ForDialect(amdAcr39);
  Check((C.CounterModels = []) and (C.CertificateModels = []), 'No ACR39 counter support claimed');
end;

procedure TestReadAndWrite;
var S: TScript; T: ICardTransport; C: TSleCounterCardReaderWriter;
  B: TBytes; Mode: TSleCounterWriteMode;
begin
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 256;
    S.Add('FFA400000107', '9000');
    S.Add('FFB0000080', StringOfChar('F', 256) + '9000');
    S.Add('FFB0008080', StringOfChar('0', 256) + '9000');
    B := C.ReadMemory(0, 256);
    Check((Length(B) = 256) and (B[0] = $FF) and (B[255] = 0), 'Chunked owned read');
    B[0] := 0; Check(S.Steps[1].Response[0] = $FF, 'Independent result'); Complete(S);
  finally C.Free; T := nil; end;
  for Mode := Low(TSleCounterWriteMode) to High(TSleCounterWriteMode) do
  begin
    S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
    try
      C.Model := scmSle5536; C.Transport := T; C.ReadableBytes := 4;
      AddWrite(S, IntToHex(Ord(Mode), 2));
      C.WriteByte(1, $7F, Mode, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF')); Complete(S);
    finally C.Free; T := nil; end;
  end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4;
    AddWrite(S, '01', 'FFFFFFFF', '007FFFFF');
    C.WriteByte(1, $7F, scwCarry, HexToBytes('FFFFFFFF'), HexToBytes('007FFFFF')); Complete(S);
  finally C.Free; T := nil; end;
end;

procedure TestPreflight;
var S: TScript; T: ICardTransport; C: TSleCounterCardReaderWriter;
  Rejected: Boolean; B: TBytes; I: Integer;
begin
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; Rejected := False;
    try B := C.ReadMemory(0, 1); except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected and (S.Begins = 0), 'No guessed geometry'); C.ReadableBytes := 4;
    for I := 0 to 3 do
    begin
      Rejected := False;
      try
        case I of
          0: C.WriteByte(1, $FF, scwProgram, HexToBytes('FF00FFFF'), HexToBytes('FFFFFFFF'));
          1: C.WriteByte(1, $7F, scwBackup, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF'));
          2: C.WriteByte(1, $7F, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('007FFFFF'));
          3: C.WriteByte(1, $7F, scwProgram, HexToBytes('FF'), HexToBytes('FF7FFFFF'));
        end;
      except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected and (S.Begins = 0), 'Invalid mutation touched hardware');
    end;
    S.Add('FFA400000107', '9000'); S.Add('FFB0000004', 'FFFFFFFF9000');
    C.WriteByte(1, $FF, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('FFFFFFFF'));
    Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4;
    S.Add('FFA400000107','9000'); S.Add('FFB0000004','000000009000');
    Rejected := False;
    try C.WriteByte(1, $7F, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF'));
    except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected, 'Stale expected state not refused'); Complete(S);
  finally C.Free; T := nil; end;
end;

procedure TestWriteFailures;
var S: TScript; T: ICardTransport; C: TSleCounterCardReaderWriter;
  I, Kind, Bit: Integer; Rejected, Uncertain, Verified: Boolean;
begin
  for Kind := 0 to 2 do
    for I := 0 to 3 do
    begin
      S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
      try
        C.Transport := T; C.ReadableBytes := 4; AddWrite(S);
        if Kind = 0 then S.FailAt := I;
        if Kind = 1 then S.Steps[I].Response := HexToBytes('6C02');
        if Kind = 2 then SetLength(S.Steps[I].Response, 1);
        Rejected := False; Uncertain := False;
        try C.WriteByte(1, $7F, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF'));
        except
          on E: EMemoryCardWriteUncertain do
          begin
            Rejected := True; Uncertain := True;
            Check(not E.Verified, 'Failure before proof marked verified');
            Check(Pos('Sensitive', E.Message) = 0, 'Sensitive failure leaked');
          end;
          on E: EMemoryCardError do Rejected := True;
          on E: ECardTransportError do Rejected := True;
        end;
        Check(Rejected and (Uncertain = (I >= 2)), 'Dispatch uncertainty boundary');
        Check((S.Position = I + 1) and (S.Ends = 1), 'Failure replay or missing release');
      finally C.Free; T := nil; end;
    end;
  for Bit := 0 to 31 do
  begin
    S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
    try
      C.Transport := T; C.ReadableBytes := 4; AddWrite(S);
      S.Steps[3].Response[Bit div 8] := S.Steps[3].Response[Bit div 8] xor Byte(1 shl (Bit mod 8));
      Rejected := False;
      try C.WriteByte(1, $7F, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF'));
      except on E: EMemoryCardWriteUncertain do Rejected := not E.Verified; end;
      Check(Rejected, 'Corrupted full-window verification accepted'); Complete(S);
    finally C.Free; T := nil; end;
  end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4; AddWrite(S); S.EndFails := True;
    Verified := False;
    try C.WriteByte(1, $7F, scwProgram, HexToBytes('FFFFFFFF'), HexToBytes('FF7FFFFF'));
    except on E: EMemoryCardWriteUncertain do Verified := E.Verified; end;
    Check(Verified, 'Release erased successful verification evidence'); Complete(S);
  finally C.Free; T := nil; end;
end;

procedure TestLifecycleAndOwnership;
var S: TScript; T: ICardTransport; C: TSleCounterCardReaderWriter;
  B, Before, After: TBytes; Bare: TBare; Rejected: Boolean;
begin
  Bare := TBare.Create; T := Bare; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4; Rejected := False;
    try B := C.ReadMemory(0, 1); except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected and (Bare.Calls = 0), 'Transaction-less transport dispatched a command');
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4; S.BeginFails := True; Rejected := False;
    try B := C.ReadMemory(0, 1); except on E: ECardTransportError do Rejected := True; end;
    Check(Rejected and (S.Ends = 0) and (S.Position = 0), 'Failed acquisition released or dispatched');
    S.BeginFails := False;
    S.Add('FFA400000107','9000'); S.Add('FFB0000001','AB9000');
    B := C.ReadMemory(0, 1);
    Check((BytesToHex(B) = 'AB') and (S.Begins = 2) and (S.Ends = 1), 'Failed acquisition left the component busy');
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4; Before := HexToBytes('FFFFFFFF'); After := HexToBytes('FF7FFFFF');
    S.MutatePin := Before; AddWrite(S);
    C.WriteByte(1, $7F, scwProgram, Before, After);
    Check(Before[0] = $EE, 'Caller mutation callback was not exercised'); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.ReadableBytes := 4;
    S.Add('FFA400000107','9000'); S.Add('FFB0000004','FFFFFFFF9000');
    S.Add('FFD000010201FF','9000'); S.Add('FFB0000004','FFFFFFFF9000');
    C.WriteByte(1, $FF, scwCarry, HexToBytes('FFFFFFFF'), HexToBytes('FFFFFFFF'));
    Complete(S); Check(S.Position = 4, 'Carry with unchanged target incorrectly skipped');
  finally C.Free; T := nil; end;
end;

procedure TestCertificate;
var S: TScript; T: ICardTransport; C: TSleCounterCardReaderWriter;
  B: TBytes; I: Integer; Rejected: Boolean;
begin
  for I := -1 to 2 do
  begin
    S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
    try
      C.Transport := T; C.Model := scmSle6636;
      S.Add('FFA400000107','9000'); S.Add('FF8400000881A0010203040506','6102');
      S.Add('FFC0000002','12349000'); S.FailAt := I; Rejected := False;
      try B := C.ReadCertificate($81, $A0, HexToBytes('010203040506'));
      except on E: ECardTransportError do Rejected := True; end;
      if I = -1 then begin Check(BytesToHex(B) = '1234','Certificate literal'); Complete(S); end
      else Check(Rejected and (S.Position = I + 1) and (S.Ends = 1), 'Challenge replay');
    finally C.Free; T := nil; end;
  end;
  S := TScript.Create; T := S; C := TSleCounterCardReaderWriter.Create(nil);
  try
    C.Transport := T; C.Model := scmSle5536;
    S.Add('FFA400000107','9000'); S.Add('FF8400000800A0010203040506','9000');
    Rejected := False;
    try B := C.ReadCertificate(0, $A0, HexToBytes('010203040506'));
    except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected and (S.Position = 2), 'Unexpected challenge status triggered retrieval'); Complete(S);
  finally C.Free; T := nil; end;
end;

begin
  try
    TestCodecsAndCapabilities; TestReadAndWrite; TestPreflight; TestWriteFailures; TestLifecycleAndOwnership; TestCertificate;
    Writeln('PASS: ', Checks, ' memory counter/profile assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
