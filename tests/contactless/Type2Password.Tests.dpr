program Type2PasswordTests;

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
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.ACR122,
  ERD.Card.Contactless.Type2, ERD.Card.Contactless.Type2.Password;

type
  TStep = record
    Wire, Data: TBytes;
    Bits, ResponseBits: Integer;
    Timeout, Fails: Boolean;
  end;
  TRawScript = class(TInterfacedObject, IRawContactlessReader)
  public
    Steps: array of TStep;
    Uid, PasswordAlias, PackAlias: TBytes;
    Position, Begins, Ends, Activations: Integer;
    Active, BeginFails, EndFails, ActivateFails: Boolean;
    constructor Create;
    procedure Add(const AWire, AData: string; const ABits, AResponseBits: Integer);
    procedure BeginSession;
    procedure EndSession;
    function Activate: TBytes;
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
  end;
  TPcscScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    PasswordAlias, PackAlias: TBytes;
    Position, Begins, Ends: Integer;
    procedure Add(const APayload, AData: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
const
  PasswordHex = '01020304'; // Synthetic fixture, never a real tag credential.
  PackHex = 'A1B2';
  PageHex = '11223344';
var Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

function WithCrc(const AHex: string): string;
begin Result := BytesToHex(TRawUidCodec.AppendCrcA(HexToBytes(AHex))); end;

constructor TRawScript.Create;
begin
  inherited Create;
  Uid := HexToBytes('04112233445566');
end;

procedure TRawScript.Add(const AWire, AData: string; const ABits, AResponseBits: Integer);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Wire := HexToBytes(AWire);
  Steps[I].Data := HexToBytes(AData);
  Steps[I].Bits := ABits;
  Steps[I].ResponseBits := AResponseBits;
end;

procedure TRawScript.BeginSession;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic acquisition');
  Check(not Active, 'No nested session');
  Active := True;
end;

procedure TRawScript.EndSession;
begin
  Inc(Ends);
  Check(Active, 'Release owns active session');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic release');
end;

function TRawScript.Activate: TBytes;
begin
  Check(Active, 'Fresh activation inside exclusive session');
  Inc(Activations);
  if ActivateFails then raise ECardTransportError.Create('synthetic selection');
  Check(Activations = 1, 'No reset/reactivation between authentication and memory operations');
  Result := CopyBytes(Uid);
end;

function TRawScript.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
begin
  Check(Active and (Position < Length(Steps)), 'No unplanned frame or retry');
  Check(BytesEqual(AFrame, Steps[Position].Wire) and (ABitCount = Steps[Position].Bits), 'Exact raw wire and bit count');
  if AFrame[0] = $1B then PasswordAlias := AFrame;
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('sensitive synthetic backend text ' + PasswordHex);
  Result := Default(TRawRfResponse);
  Result.Data := CopyBytes(Steps[Position - 1].Data);
  Result.BitCount := Steps[Position - 1].ResponseBits;
  Result.TimedOut := Steps[Position - 1].Timeout;
  if AFrame[0] = $1B then PackAlias := Result.Data;
end;

procedure TPcscScript.Add(const APayload, AData: string);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Wire := HexToBytes('FF000000' + IntToHex(Length(APayload) div 2, 2) + APayload);
  Steps[I].Data := HexToBytes(AData);
end;

procedure TPcscScript.BeginTransaction;
begin Inc(Begins); end;
procedure TPcscScript.EndTransaction;
begin Inc(Ends); end;

function TPcscScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(Steps), 'No extra adapter commands');
  Check(BytesEqual(ACommand, Steps[Position].Wire), 'Exact PN532 pseudo APDU');
  if (Length(ACommand) > 7) and (ACommand[5] = $D4) and (ACommand[6] = $42) and (ACommand[7] = $1B) then
    PasswordAlias := ACommand;
  Inc(Position);
  Result := CopyBytes(Steps[Position - 1].Data);
  if (Length(ACommand) > 7) and (ACommand[7] = $1B) then PackAlias := Result;
end;

procedure CheckWiped(const AData: TBytes);
var I: Integer;
begin
  for I := 0 to Length(AData) - 1 do Check(AData[I] = 0, 'Local credential-bearing copy overwritten');
end;

procedure AddAuthentication(Script: TRawScript);
begin Script.Add(WithCrc('1B' + PasswordHex), WithCrc(PackHex), 56, 32); end;

procedure AddRead(Script: TRawScript; const APage, ACount: Integer; const AData: string);
begin
  Script.Add(WithCrc('3A' + IntToHex(APage, 2) + IntToHex(APage + ACount - 1, 2)),
    WithCrc(AData), 40, (Length(AData) div 2 + 2) * 8);
end;

function MemoryFixture(const APage, ACount: Integer): TBytes;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, ACount * 4);
  for I := 0 to Length(Result) - 1 do Result[I] := Byte((APage * 4 + I) and $FF);
end;

procedure TestCodecsAndGuards;
var Model: TType2TagModel; Reader: TType2PasswordCardReader; Script: TRawScript;
  Data, Password, Pack: TBytes; I, Count, LastPage: Integer; Raised, Valid: Boolean;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    Script := TRawScript.Create;
    Reader.Reader := Script;
    Password := HexToBytes(PasswordHex);
    Pack := HexToBytes(PackHex);
    for Model := Low(TType2TagModel) to High(TType2TagModel) do
    begin
      LastPage := TType2Layout.LastUserPage(Model);
      for I := -1 to TType2Layout.PageCount(Model) do
      begin
        Valid := (Model <> ttmUltralight) and (I >= 4) and (I <= LastPage);
        Raised := False;
        try Data := TType2PasswordCodec.BuildFastReadCommand(Model, I, 1);
        except on E: EType2DataError do Raised := True; end;
        Check(Raised <> Valid, 'Every manufacturer/lock/configuration/out-of-model page excluded');
        if Valid then Check(BytesToHex(Data) = WithCrc('3A' + IntToHex(I, 2) + IntToHex(I, 2)), 'Single-page FAST_READ has no adjacent-page read');
        if not Valid then
        begin
          Raised := False;
          try Reader.WriteUserPage(Model, I, Password, Pack, HexToBytes(PageHex));
          except on E: EType2DataError do Raised := True; end;
          Check(Raised and (Script.Begins = 0), 'Protected writes rejected before authentication/acquisition');
        end;
      end;
      if Model = ttmUltralight then Continue;
      for Count := -1 to 17 do
      begin
        Raised := False;
        try TType2PasswordCodec.ValidateUserRange(Model, LastPage, Count);
        except on E: EType2DataError do Raised := True; end;
        Check(Raised = (Count <> 1), 'Cannot wrap into config or manufacturer pages');
      end;
      for I := 0 to 5 do
      begin
        SetLength(Password, I);
        Raised := False;
        try TType2PasswordCodec.ValidateCredentials(Model, Password, Pack);
        except on E: EType2DataError do Raised := True; end;
        Check(Raised = (I <> 4), 'Exactly four password bytes');
      end;
      Password := HexToBytes(PasswordHex);
      for I := 0 to 3 do
      begin
        SetLength(Pack, I);
        Raised := False;
        try TType2PasswordCodec.ValidateCredentials(Model, Password, Pack);
        except on E: EType2DataError do Raised := True; end;
        Check(Raised = (I <> 2), 'Exactly two expected PACK bytes, never optional');
      end;
      Pack := HexToBytes(PackHex);
      Raised := False;
      try Reader.WriteUserPage(Model, 4, Password, Pack, HexToBytes('010203'));
      except on E: EType2DataError do Raised := True; end;
      Check(Raised and (Script.Begins = 0), 'Exactly four write-data bytes before I/O');
    end;
    Raised := False;
    try Data := TType2PasswordCodec.BuildFastReadCommand(ttmNtag216, High(Integer), High(Integer));
    except on E: EType2DataError do Raised := True; end;
    Check(Raised, 'Integer bounds rejected without overflow');
    Raised := False;
    try Data := Reader.ReadUserPage(ttmNtag213, 4, nil, HexToBytes(PackHex));
    except on E: EType2DataError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid credentials rejected before raw reader use');
  finally Reader.Free; end;
  Writeln('PASS: seven password models, page guards, credential sizes and bounded FAST_READ without wraparound.');
end;

procedure TestReadsAndWrites;
var Reader: TType2PasswordCardReader; Script: TRawScript; Model: TType2TagModel;
  Password, Pack, Data, PageData: TBytes; LastPage: Integer;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    Password := HexToBytes(PasswordHex);
    Pack := HexToBytes(PackHex);
    PageData := HexToBytes(PageHex);
    for Model := ttmUltralightEv1_48 to High(TType2TagModel) do
    begin
      LastPage := TType2Layout.LastUserPage(Model);
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      AddRead(Script, LastPage, 1, PageHex);
      Data := Reader.ReadUserPage(Model, LastPage, Password, Pack);
      Check(BytesToHex(Data) = PageHex, 'Final user page read without trailing config');
      Check((Script.Position = 2) and (Script.Begins = 1) and (Script.Ends = 1), 'One authentication, one page read, release before output');
      Data[0] := 0;
      Check(BytesToHex(Script.Steps[1].Data) = WithCrc(PageHex), 'Returned page independent from backend response');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      Script.Add(WithCrc('A2' + IntToHex(LastPage, 2) + PageHex), '0A', 64, 4);
      AddRead(Script, LastPage, 1, PageHex);
      Reader.WriteUserPage(Model, LastPage, Password, Pack, PageData);
      Check((Script.Position = 3) and (Script.Activations = 1) and (Script.Ends = 1), 'One write and exact read-back within the same authenticated session');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
      Check((BytesToHex(Password) = PasswordHex) and (BytesToHex(Pack) = PackHex) and
        (BytesToHex(PageData) = PageHex), 'All caller-owned credentials/data remain unchanged');
    end;
  finally Reader.Free; end;
  Writeln('PASS: all seven supplied-password read/write paths, PACK comparison, buffer ownership and local wiping.');
end;

procedure TestCompleteMemory;
var Reader: TType2PasswordCardReader; Script: TRawScript; Model: TType2TagModel;
  Memory: TType2UserMemory; Expected: TBytes; Page, Count, LastPage, ExpectedFrames: Integer;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    for Model := ttmUltralightEv1_48 to High(TType2TagModel) do
    begin
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      LastPage := TType2Layout.LastUserPage(Model);
      Page := 4;
      ExpectedFrames := 1;
      while Page <= LastPage do
      begin
        Count := LastPage - Page + 1;
        if Count > 16 then Count := 16;
        AddRead(Script, Page, Count, BytesToHex(MemoryFixture(Page, Count)));
        Inc(Page, Count);
        Inc(ExpectedFrames);
      end;
      Memory := Reader.ReadUserMemory(Model, HexToBytes(PasswordHex), HexToBytes(PackHex));
      Expected := MemoryFixture(4, LastPage - 3);
      Check((Memory.Model = Model) and (Memory.FirstPage = 4) and (Memory.PageCount = LastPage - 3), 'Complete model/layout metadata');
      Check(BytesEqual(Memory.Data, Expected) and (Length(Memory.Data) = TType2Layout.UserByteCount(Model)), 'Complete ascending snapshot, including final partial chunk');
      Check((Script.Position = ExpectedFrames) and (Script.Activations = 1) and (Script.Ends = 1), 'One authentication for all bounded chunks, no field reset');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
    end;
  finally Reader.Free; end;
  Writeln('PASS: complete 48/128/144/504/888-byte user snapshots with bounded chunks and no excluded pages.');
end;

procedure TestAuthenticationFailures;
var Reader: TType2PasswordCardReader; Script: TRawScript; Data: TBytes;
  I: Integer; Raised: Boolean; Held: IRawContactlessReader;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    for I := 0 to 7 do
    begin
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      case I of
        0: Script.Steps[0].Fails := True;
        1: begin Script.Steps[0].Data := nil; Script.Steps[0].ResponseBits := 0; Script.Steps[0].Timeout := True; end;
        2: begin Script.Steps[0].Data := HexToBytes('04'); Script.Steps[0].ResponseBits := 4; end;
        3: begin Script.Steps[0].Data := HexToBytes('0A'); Script.Steps[0].ResponseBits := 4; end;
        4: Script.Steps[0].Data[3] := Script.Steps[0].Data[3] xor 1;
        5: begin Script.Steps[0].Data := TRawUidCodec.AppendCrcA(HexToBytes('A1B3')); end;
        6: Script.Steps[0].ResponseBits := 31;
        7: begin Script.Steps[0].Data := HexToBytes('9000'); Script.Steps[0].ResponseBits := 16; end;
      end;
      Script.EndFails := I in [0, 5];
      Raised := False;
      try Data := Reader.ReadUserPage(ttmNtag213, 4, HexToBytes(PasswordHex), HexToBytes(PackHex));
      except
        on E: EType2AuthenticationError do
        begin
          Raised := True;
          Check(Pos(PasswordHex, E.Message) = 0, 'Backend credential text is sanitized');
          if I = 0 then Check(E.OriginalErrorClass = 'ECardTransportError', 'Authentication transport failure wins over cleanup');
        end;
      end;
      Check(Raised and (Script.Position = 1) and (Script.Ends = 1), 'Exactly one password attempt, no data read, fallback or retry');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
    end;
    for I := 0 to 4 do
    begin
      Script := TRawScript.Create;
      Reader.Reader := Script;
      Held := Script;
      case I of
        0: Script.BeginFails := True;
        1: Script.ActivateFails := True;
        2: Script.Uid := HexToBytes('11223344');
        3: Script.Uid[3] := $88;
        4: Reader.Reader := nil;
      end;
      Raised := False;
      try Data := Reader.ReadUserPage(ttmNtag213, 4, HexToBytes(PasswordHex), HexToBytes(PackHex));
      except on E: Exception do Raised := not (E is EType2AuthenticationError); end;
      Check(Raised and (Script.Position = 0), 'No credentials dispatched before valid acquisition/selection');
      if I = 0 then Check(Script.Ends = 0, 'Failed Begin is not released twice')
      else if I < 4 then Check(Script.Ends = 1, 'Selection failure releases acquired session');
      Held := nil;
    end;
  finally Reader.Free; end;
  Writeln('PASS: authentication transport/NAK/PACK/framing/CRC failures, no replay and sanitized exception precedence.');
end;

procedure TestMemoryFailures;
var Reader: TType2PasswordCardReader; Script: TRawScript; Memory: TType2UserMemory;
  I: Integer; Raised: Boolean;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    for I := 0 to 4 do
    begin
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      AddRead(Script, 4, 16, BytesToHex(MemoryFixture(4, 16)));
      AddRead(Script, 20, 16, BytesToHex(MemoryFixture(20, 16)));
      case I of
        0: Script.Steps[2].Fails := True;
        1: Script.Steps[2].Data[65] := Script.Steps[2].Data[65] xor 1;
        2: begin Script.Steps[2].Data := HexToBytes('00'); Script.Steps[2].ResponseBits := 4; end;
        3: SetLength(Script.Steps[2].Data, 65);
        4: begin AddRead(Script, 36, 4, BytesToHex(MemoryFixture(36, 4))); Script.EndFails := True; end;
      end;
      Raised := False;
      try Memory := Reader.ReadUserMemory(ttmNtag213, HexToBytes(PasswordHex), HexToBytes(PackHex));
      except on E: Exception do Raised := True; end;
      Check(Raised and (Script.Position = Length(Script.Steps)) and (Script.Ends = 1), 'Failed chunk/release returns no completed snapshot and never reauthenticates');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
    end;
  finally Reader.Free; end;
  Writeln('PASS: mid-snapshot read/framing/CRC errors and release failure without partial output or replay.');
end;

procedure TestWriteFailures;
var Reader: TType2PasswordCardReader; Script: TRawScript; I, Last: Integer; Raised: Boolean;
begin
  Reader := TType2PasswordCardReader.Create(nil);
  try
    for I := 0 to 8 do
    begin
      Script := TRawScript.Create;
      Reader.Reader := Script;
      AddAuthentication(Script);
      Script.Add(WithCrc('A204' + PageHex), '0A', 64, 4);
      AddRead(Script, 4, 1, PageHex);
      Last := 2;
      case I of
        0: begin Script.Steps[1].Fails := True; Last := 1; end;
        1: begin Script.Steps[1].Data := nil; Script.Steps[1].ResponseBits := 0; Script.Steps[1].Timeout := True; Last := 1; end;
        2: begin Script.Steps[1].Data := HexToBytes('05'); Last := 1; end;
        3: begin Script.Steps[1].ResponseBits := 8; Last := 1; end;
        4: Script.Steps[2].Fails := True;
        5: Script.Steps[2].Data := TRawUidCodec.AppendCrcA(HexToBytes('11223345'));
        6: Script.Steps[2].Data[5] := Script.Steps[2].Data[5] xor 1;
        7: Script.EndFails := True;
        8: begin Script.Steps[2].Data := HexToBytes('00'); Script.Steps[2].ResponseBits := 4; Script.EndFails := True; end;
      end;
      SetLength(Script.Steps, Last + 1);
      Raised := False;
      try Reader.WriteUserPage(ttmNtag213, 4, HexToBytes(PasswordHex), HexToBytes(PackHex), HexToBytes(PageHex));
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := True;
          if I = 8 then Check(E.OriginalErrorClass = 'EContactlessError', 'Read-back failure wins over release error');
        end;
      end;
      Check(Raised and (Script.Position = Length(Script.Steps)) and (Script.Ends = 1), 'Every post-dispatch failure uncertain, with no write/auth replay');
      CheckWiped(Script.PasswordAlias);
      CheckWiped(Script.PackAlias);
    end;
    Script := TRawScript.Create;
    Reader.Reader := Script;
    AddAuthentication(Script);
    Script.Steps[0].Fails := True;
    Raised := False;
    try Reader.WriteUserPage(ttmNtag213, 4, HexToBytes(PasswordHex), HexToBytes(PackHex), HexToBytes(PageHex));
    except on E: EType2AuthenticationError do Raised := True; end;
    Check(Raised and (Script.Position = 1) and (Script.Ends = 1), 'Failed auth is not classified as a dispatched page write');
  finally Reader.Free; end;
  Writeln('PASS: single-write NAK/timeout/transport/framing, verification and release failures, with no replay.');
end;

procedure AddAcrExchange(Script: TPcscScript; const AFrame, AData: string; const ALastBits: Byte = 0);
begin
  Script.Add('D408630200630300633D00', 'D5099000');
  Script.Add('D442' + AFrame, 'D54300' + AData + '9000');
  Script.Add('D406633C', 'D507' + IntToHex(ALastBits, 2) + '9000');
end;

procedure TestAdapterIntegration;
var Script: TPcscScript; Reader: TType2PasswordCardReader;
begin
  Script := TPcscScript.Create;
  Reader := TType2PasswordCardReader.Create(nil);
  try
    Reader.Reader := TAcr122RawReader.Create(Script);
    Script.Add('D43202000B0D', 'D5339000');
    Script.Add('D4320400', 'D5339000');
    Script.Add('D43205000000', 'D5339000');
    Script.Add('D4320100', 'D5339000');
    Script.Add('D4320101', 'D5339000');
    Script.Add('D44A0100', 'D54B010100440007041122334455669000');
    Script.Add('D40663026303633D', 'D5078080009000');
    Script.Add('D408630200630300633D00', 'D5099000');
    AddAcrExchange(Script, WithCrc('1B' + PasswordHex), WithCrc(PackHex));
    AddAcrExchange(Script, WithCrc('A204' + PageHex), '0A', 4);
    AddAcrExchange(Script, WithCrc('3A0404'), WithCrc(PageHex));
    Script.Add('D408630280630380633D00', 'D5099000');
    Script.Add('D4320100', 'D5339000');
    Reader.WriteUserPage(ttmNtag213, 4, HexToBytes(PasswordHex), HexToBytes(PackHex), HexToBytes(PageHex));
    Check((Script.Position = Length(Script.Steps)) and (Script.Begins = 1) and (Script.Ends = 1), 'Complete authenticate/write/read-back ACR122/PN532 chain with retained state');
    CheckWiped(Script.PasswordAlias);
    CheckWiped(Script.PackAlias);
  finally Reader.Free; end;
  Writeln('PASS: concrete ACR122U/PN532 authentication, write, same-session read-back and credential-copy wiping.');
end;

begin
  try
    TestCodecsAndGuards;
    TestReadsAndWrites;
    TestCompleteMemory;
    TestAuthenticationFailures;
    TestMemoryFailures;
    TestWriteFailures;
    TestAdapterIntegration;
    Writeln('PASS: ', Checks, ' assertions across seven Type 2 password test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
