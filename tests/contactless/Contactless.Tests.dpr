program ContactlessTests;

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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.APDU, ERD.Card.Contactless,
  ERD.Card.Contactless.Type2, ERD.Card.Contactless.UID;

type
  TStep = record
    Wire, Response: TBytes;
    Fails: Boolean;
  end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    Active, BeginFails, EndFails: Boolean;
    KeyCommandAlias: TBytes;
    procedure Add(const AWire, AResponse: string; const AFails: Boolean = False);
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TBare = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TClassicOnlyProfile = class(TInterfacedObject, IContactlessReaderProfile)
  private
    FInner: IContactlessReaderProfile;
  public
    constructor Create;
    function UidCommand: TBytes;
    function LoadKeyCommand(const AKey: TBytes; const ASlot: Byte): TBytes;
    function AuthenticateCommand(const ABlock: Byte; const AKeyType: TMifareClassicKeyType;
      const ASlot: Byte): TBytes;
    function ReadBlockCommand(const ABlock: Byte): TBytes;
    function WriteBlockCommand(const ABlock: Byte; const AData: TBytes): TBytes;
  end;
var Checks: Integer = 0;
const
  KeyHex = '010203040506'; // Synthetic caller key, not a real card credential.
  BlockHex = '00112233445566778899AABBCCDDEEFF';
  OldUidHex = '11223344';
  NewUidHex = 'A1B2C3D4';
  OldManufacturerHex = '11223344440804006263646566676869';
  NewManufacturerHex = 'A1B2C3D4040804006263646566676869';

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

procedure TScript.Add(const AWire, AResponse: string; const AFails: Boolean);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Wire := HexToBytes(AWire);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Fails := AFails;
end;

function TScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(Steps), 'No unexpected command or replay');
  Check(BytesEqual(ACommand, Steps[Position].Wire), 'Exact profile command');
  if (Length(ACommand) >= 2) and (ACommand[1] = $82) then KeyCommandAlias := ACommand;
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

procedure TScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic acquisition failure');
  Check(not Active, 'Transaction is not nested');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Inc(Ends);
  Check(Active, 'Transaction is active during release');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic release failure');
end;

function TBare.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Unexpected bare transport exchange');
end;

constructor TClassicOnlyProfile.Create;
begin
  inherited Create;
  FInner := TPcscStorageProfile.Create;
end;

function TClassicOnlyProfile.UidCommand: TBytes;
begin Result := FInner.UidCommand; end;

function TClassicOnlyProfile.LoadKeyCommand(const AKey: TBytes; const ASlot: Byte): TBytes;
begin Result := FInner.LoadKeyCommand(AKey, ASlot); end;

function TClassicOnlyProfile.AuthenticateCommand(const ABlock: Byte;
  const AKeyType: TMifareClassicKeyType; const ASlot: Byte): TBytes;
begin Result := FInner.AuthenticateCommand(ABlock, AKeyType, ASlot); end;

function TClassicOnlyProfile.ReadBlockCommand(const ABlock: Byte): TBytes;
begin Result := FInner.ReadBlockCommand(ABlock); end;

function TClassicOnlyProfile.WriteBlockCommand(const ABlock: Byte; const AData: TBytes): TBytes;
begin Result := FInner.WriteBlockCommand(ABlock, AData); end;

procedure AddAuthentication(const AScript: TScript; const ABlock: Integer;
  const AType: TMifareClassicKeyType; const ASlot: Byte = 0);
begin
  AScript.Add('FF8200' + IntToHex(ASlot, 2) + '06' + KeyHex, '9000');
  AScript.Add('FF860000050100' + IntToHex(ABlock, 2) + IntToHex($60 + Ord(AType), 2) +
    IntToHex(ASlot, 2), '9000');
end;

procedure TestLayout;
var Model: TMifareClassicModel; N, Trailers: Integer; Raised: Boolean;
begin
  for Model := Low(TMifareClassicModel) to High(TMifareClassicModel) do
  begin
    Trailers := 0;
    for N := 0 to TMifareClassicLayout.BlockCount(Model) - 1 do
    begin
      if TMifareClassicLayout.IsTrailer(Model, N) then Inc(Trailers);
      if N < 128 then Check(TMifareClassicLayout.IsTrailer(Model, N) = ((N mod 4) = 3), 'Small sector trailers')
      else Check(TMifareClassicLayout.IsTrailer(Model, N) = ((N mod 16) = 15), 'Large 4K sector trailers');
    end;
    case Model of
      mcmMini: Check((Trailers = 5) and (TMifareClassicLayout.BlockCount(Model) = 20), 'Mini layout');
      mcm1K: Check((Trailers = 16) and (TMifareClassicLayout.BlockCount(Model) = 64), '1K layout');
      mcm4K: Check((Trailers = 40) and (TMifareClassicLayout.BlockCount(Model) = 256), '4K mixed sector layout');
    end;
    Raised := False;
    try TMifareClassicLayout.IsTrailer(Model, -1);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised, 'Negative block rejected');
    Raised := False;
    try TMifareClassicLayout.IsTrailer(Model, TMifareClassicLayout.BlockCount(Model));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised, 'Out-of-model block rejected');
  end;
  Check(not TMifareClassicLayout.IsTrailer(mcm4K, 131), '4K block 131 is a data block');
  Check(TMifareClassicLayout.IsTrailer(mcm4K, 143), '4K block 143 is a trailer');
  Writeln('PASS: original Classic Mini/1K/4K layout and mixed-sector boundaries.');
end;

procedure TestUidAndProfiles;
var Reader: TContactlessCardReader; Script: TScript; Data: TBytes; I: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Check(Reader.UseTransactions and (Reader.Profile = nil) and (Reader.Transport = nil), 'No hardware work or profile guessing in constructor');
    Script := TScript.Create;
    Reader.Transport := Script;
    Raised := False;
    try Data := Reader.ReadUid;
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'No selected profile rejects operation before acquisition');
    Reader.Profile := TPcscStorageProfile.Create;
    Script.Add('FFCA000000', '010203040506079000');
    Data := Reader.ReadUid;
    Check(BytesToHex(Data) = '01020304050607', 'UID preserved in reader order');
    Data[0] := 0;
    Check(Script.Steps[0].Response[0] = 1, 'Returned UID owns its buffer');
    for I := 0 to 5 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      case I of
        0: Script.Add('FFCA000000', '9000');
        1: Script.Add('FFCA000000', StringOfChar('A', 66) + '9000');
        2: Script.Add('FFCA000000', '6A81');
        3: Script.Add('FFCA000000', '6C07');
        4: Script.Add('FFCA000000', '6107');
        5: Script.Add('FFCA000000', '90');
      end;
      Raised := False;
      try Data := Reader.ReadUid;
      except
        on E: EContactlessError do Raised := I <= 4;
        on E: EApduFormatError do Raised := I = 5;
      end;
      Check(Raised and (Script.Position = 1) and (Script.Ends = 1), 'UID invalid/status response without replay');
    end;
    Reader.Transport := TBare.Create;
    Raised := False;
    try Data := Reader.ReadUid;
    except on E: EContactlessError do Raised := True; end;
    Check(Raised, 'Mandatory transaction capability');
    Reader.UseTransactions := False;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('FFCA000000', '019000');
    Data := Reader.ReadUid;
    Check((Length(Data) = 1) and (Script.Begins = 0) and (Script.Ends = 0), 'Explicit external-serialization mode');
  finally Reader.Free; end;
  Writeln('PASS: explicit profiles, UID ownership, unsupported statuses and no auto-correction.');
end;

procedure TestClassicReadWrite;
var Reader: TContactlessCardReader; Script: TScript; Key, Data, Payload: TBytes; I: Integer;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Key := HexToBytes(KeyHex);
    Payload := HexToBytes(BlockHex);
    Script := TScript.Create;
    Reader.Transport := Script;
    AddAuthentication(Script, 255, mckB, 1);
    Script.Add('FFB000FF10', BlockHex + '9000');
    Data := Reader.ReadClassicBlock(mcm4K, 255, mckB, Key, 1);
    Check(BytesToHex(Data) = BlockHex, 'Trailer read with key B and slot one');
    Check((Script.Position = 3) and (Script.Begins = 1) and (Script.Ends = 1), 'Key load/auth/read in one transaction');
    Check(BytesToHex(Key) = KeyHex, 'Caller key unchanged');
    Check(Length(Script.KeyCommandAlias) = 11, 'Local key command lifetime observable');
    for I := 0 to Length(Script.KeyCommandAlias) - 1 do Check(Script.KeyCommandAlias[I] = 0, 'Local key command overwritten');
    Script := TScript.Create;
    Reader.Transport := Script;
    AddAuthentication(Script, 131, mckA);
    Script.Add('FFD6008310' + BlockHex, '9000');
    Reader.WriteClassicDataBlock(mcm4K, 131, mckA, Key, Payload);
    Check((Script.Position = 3) and (Script.Ends = 1), 'One 4K data write, no verification replay');
    Check((BytesToHex(Payload) = BlockHex) and (BytesToHex(Key) = KeyHex), 'Caller data/key untouched by write');
  finally Reader.Free; end;
  Writeln('PASS: exact volatile load/auth/read/write commands, key B, independent buffers and key wiping.');
end;

procedure TestProtectedAndInvalidOperations;
var Reader: TContactlessCardReader; Script: TScript; Key, Data: TBytes;
  Model: TMifareClassicModel; N, I: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Script := TScript.Create;
    Reader.Transport := Script;
    Key := HexToBytes(KeyHex);
    Data := HexToBytes(BlockHex);
    for Model := Low(TMifareClassicModel) to High(TMifareClassicModel) do
      for N := 0 to TMifareClassicLayout.BlockCount(Model) - 1 do
        if (N = 0) or TMifareClassicLayout.IsTrailer(Model, N) then
        begin
          Raised := False;
          try Reader.WriteClassicDataBlock(Model, N, mckA, Key, Data);
          except on E: EContactlessError do Raised := True; end;
          Check(Raised and (Script.Position = 0) and (Script.Begins = 0), 'Protected write rejected before I/O');
        end;
    for I := 0 to 5 do
    begin
      Raised := False;
      try
        case I of
          0: Data := Reader.ReadClassicBlock(mcmMini, 20, mckA, Key);
          1: Data := Reader.ReadClassicBlock(mcm1K, 64, mckA, Key);
          2: Data := Reader.ReadClassicBlock(mcm4K, 256, mckA, Key);
          3: Data := Reader.ReadClassicBlock(mcm4K, -1, mckA, Key);
          4: Data := Reader.ReadClassicBlock(mcm1K, 1, mckA, nil);
          5: Reader.WriteClassicDataBlock(mcm1K, 1, mckA, Key, nil);
        end;
      except on E: EContactlessError do Raised := True; end;
      Check(Raised and (Script.Begins = 0), 'Invalid operation has no native effect');
    end;
  finally Reader.Free; end;
  Writeln('PASS: every manufacturer/trailer write and out-of-model block rejected before I/O.');
end;

procedure TestFailureOutcomes;
var Reader: TContactlessCardReader; Script: TScript; Key, Data: TBytes; I, J: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Key := HexToBytes(KeyHex);
    Data := HexToBytes(BlockHex);
    for I := 0 to 8 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      if I = 0 then Script.Add('FF82000006' + KeyHex, '6300')
      else if I = 1 then Script.Add('FF82000006' + KeyHex, '', True)
      else if I = 2 then Script.Add('FF82000006' + KeyHex, 'AA9000')
      else
      begin
        Script.Add('FF82000006' + KeyHex, '9000');
        if I = 3 then Script.Add('FF860000050100016000', '6300')
        else Script.Add('FF860000050100016000', '9000');
        if I = 4 then Script.Add('FFD6000110' + BlockHex, '', True);
        if I = 5 then Script.Add('FFD6000110' + BlockHex, '6C10');
        if I = 6 then Script.Add('FFD6000110' + BlockHex, '9000');
        if I = 7 then Script.Add('FFD6000110' + BlockHex, '6982');
        if I = 8 then Script.Add('FFD6000110' + BlockHex, 'AA9000');
      end;
      Script.EndFails := I in [6, 7];
      Raised := False;
      try Reader.WriteClassicDataBlock(mcm1K, 1, mckA, Key, Data);
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := I in [4, 6, 8];
          if I in [4, 6] then Check(E.OriginalErrorClass = 'ECardTransportError', 'Uncertain write retains error class');
        end;
        on E: EContactlessError do
        begin
          Raised := not (I in [1, 4, 6, 8]);
          if I = 7 then Check((E is EContactlessStatusError) and
            (EContactlessStatusError(E).StatusWord = $6982), 'Primary write status preserved on release failure');
        end;
        on E: ECardTransportError do Raised := I = 1;
      end;
      Check(Raised and (Script.Ends = 1) and not Script.Active, 'Write failure releases transaction');
      if I < 3 then Check(Script.Position = 1, 'Load failure blocks authentication/write')
      else if I = 3 then Check(Script.Position = 2, 'Auth failure blocks write')
      else Check(Script.Position = 3, 'Ambiguous/failed write never retried');
      for J := 0 to Length(Script.KeyCommandAlias) - 1 do Check(Script.KeyCommandAlias[J] = 0, 'Key wiped even on load exception');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.BeginFails := True;
    Raised := False;
    try Reader.WriteClassicDataBlock(mcm1K, 1, mckA, Key, Data);
    except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Script.Position = 0) and (Script.Ends = 0), 'Failed begin causes no writes or release');
    Script := TScript.Create;
    Reader.Transport := Script;
    AddAuthentication(Script, 1, mckA);
    Script.Add('FFB0000110', '019000');
    Raised := False;
    try Data := Reader.ReadClassicBlock(mcm1K, 1, mckA, Key);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Ends = 1), 'Short data block rejected');
  finally Reader.Free; end;
  Writeln('PASS: failed load/auth prevents writing, uncertain outcomes, no replay and exception precedence.');
end;

procedure TestType2LayoutsAndPages;
const
  Totals: array[TType2TagModel] of Integer = (16, 20, 41, 45, 135, 231, 20, 41);
  LastUsers: array[TType2TagModel] of Integer = (15, 15, 35, 39, 129, 225, 15, 35);
  UserBytes: array[TType2TagModel] of Integer = (48, 48, 128, 144, 504, 888, 48, 128);
var
  Reader: TContactlessCardReader;
  Script: TScript;
  Model: TType2TagModel;
  Data, Payload: TBytes;
  Memory: TType2UserMemory;
  Page, I: Integer;
  Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Payload := HexToBytes('10203040');
    for Model := Low(TType2TagModel) to High(TType2TagModel) do
    begin
      Check(TType2Layout.PageCount(Model) = Totals[Model], 'Datasheet physical page count');
      Check(TType2Layout.LastUserPage(Model) = LastUsers[Model], 'Datasheet last user page');
      Check(TType2Layout.UserByteCount(Model) = UserBytes[Model], 'Datasheet user capacity');
      Script := TScript.Create;
      Reader.Transport := Script;
      for Page := 0 to Totals[Model] - 1 do
      begin
        Check(TType2Layout.IsUserPage(Model, Page) =
          ((Page >= 4) and (Page <= LastUsers[Model])), 'Every user/protected region matches model');
        if not TType2Layout.IsUserPage(Model, Page) then
        begin
          Raised := False;
          try Reader.WriteType2UserPage(Model, Page, Payload);
          except on E: EContactlessError do Raised := True; end;
          Check(Raised and (Script.Begins = 0) and (Script.Position = 0), 'Manufacturer/OTP/CC/lock/config write rejected before I/O');
        end;
      end;
      for I := 0 to 1 do
      begin
        if I = 0 then Page := -1 else Page := Totals[Model];
        Raised := False;
        try Data := Reader.ReadType2Page(Model, Page);
        except on E: EType2DataError do Raised := True; end;
        Check(Raised and (Script.Begins = 0), 'Out-of-model page rejects operation before acquisition');
      end;
      Script.Add('FFB000' + IntToHex(Totals[Model] - 1, 2) + '04', '000000009000');
      Data := Reader.ReadType2Page(Model, Totals[Model] - 1);
      Check(BytesToHex(Data) = '00000000', 'Masked configuration read retained without interpretation');
      Script.Add('FFD600' + IntToHex(LastUsers[Model], 2) + '04' + BytesToHex(Payload), '9000');
      Reader.WriteType2UserPage(Model, LastUsers[Model], Payload);
      Check((Script.Begins = 2) and (Script.Ends = 2) and (Script.Position = 2), 'No Classic key loading/authentication for Type 2');
      Check(BytesToHex(Payload) = '10203040', 'Caller page payload unchanged');
      Script := TScript.Create;
      Reader.Transport := Script;
      for Page := 4 to LastUsers[Model] do
        Script.Add('FFB000' + IntToHex(Page, 2) + '04', IntToHex(Page, 2) + 'AABBCC9000');
      Memory := Reader.ReadType2UserMemory(Model);
      Check((Memory.Model = Model) and (Memory.FirstPage = 4) and
        (Memory.PageCount = LastUsers[Model] - 3), 'Complete memory snapshot metadata');
      Check(Length(Memory.Data) = UserBytes[Model], 'Complete memory length');
      for I := 0 to Memory.PageCount - 1 do
        Check((Memory.Data[I * 4] = I + 4) and (Memory.Data[I * 4 + 3] = $CC), 'Pages concatenated in order');
      Memory.Data[0] := 0;
      Check(Script.Steps[0].Response[0] = 4, 'Snapshot owns independent page data');
      Check((Script.Position = Memory.PageCount) and (Script.Begins = 1) and (Script.Ends = 1), 'Whole memory uses one transaction, no PC/SC requests outside user pages');
    end;
  finally Reader.Free; end;
  Writeln('PASS: eight Type 2 layouts, protected pages, complete memory and exact four-byte page operations.');
end;

procedure TestType2FailuresAndCapabilities;
var Reader: TContactlessCardReader; Script: TScript; Data: TBytes;
  Memory: TType2UserMemory; UidResult: TProgrammableUidResult; I: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Script := TScript.Create;
    Reader.Transport := Script;
    Reader.Profile := TClassicOnlyProfile.Create;
    Raised := False;
    try Data := Reader.ReadType2Page(ttmNtag213, 4);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Original profile remains compatible, lacks optional Type 2 capability');
    Raised := False;
    try UidResult := Reader.ProgramClassicGen2Uid(cgum4Byte, HexToBytes(NewUidHex), mckA, HexToBytes(KeyHex));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Original profile cannot silently acquire UID programming capability');
    Script.Add('FFCA000000', '112233449000');
    Data := Reader.ReadUid;
    Check(BytesToHex(Data) = '11223344', 'Original profile still performs its existing UID operation');
    Reader.Profile := TPcscStorageProfile.Create;
    for I := 0 to 6 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      case I of
        0: Script.Add('FFB0000404', '019000');
        1: Script.Add('FFB0000404', StringOfChar('A', 32) + '9000');
        2: Script.Add('FFB0000404', '6300');
        3: Script.Add('FFB0000404', '6C10');
        4: Script.Add('FFB0000404', '6104');
        5: Script.Add('FFB0000404', '90');
        6: Script.Add('FFB0000404', '', True);
      end;
      Raised := False;
      try Data := Reader.ReadType2Page(ttmNtag213, 4);
      except
        on E: EContactlessError do Raised := I < 5;
        on E: EApduFormatError do Raised := I = 5;
        on E: ECardTransportError do Raised := I = 6;
      end;
      Check(Raised and (Script.Position = 1) and (Script.Ends = 1), 'Short/oversized/failed page never corrected or replayed');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('FFB0000404', '102030409000');
    Script.Add('FFB0000504', '6300');
    Script.EndFails := True;
    Raised := False;
    try Memory := Reader.ReadType2UserMemory(ttmNtag216);
    except on E: EContactlessStatusError do Raised := E.StatusWord = $6300; end;
    Check(Raised and (Script.Position = 2) and (Script.Ends = 1), 'Snapshot failure retains primary error and returns no padded/partial data');
    Script := TScript.Create;
    Reader.Transport := Script;
    for I := 4 to 15 do Script.Add('FFB000' + IntToHex(I, 2) + '04', '102030409000');
    Script.EndFails := True;
    Raised := False;
    try Memory := Reader.ReadType2UserMemory(ttmUltralight);
    except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Script.Position = 12) and (Script.Ends = 1), 'Successful page reads cannot hide snapshot release failure');
    for I := 0 to 5 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      case I of
        0: Script.Add('FFD600040410203040', '', True);
        1: Script.Add('FFD600040410203040', '90');
        2: Script.Add('FFD600040410203040', 'AA9000');
        3: Script.Add('FFD600040410203040', '6982');
        4: Script.Add('FFD600040410203040', '9000');
        5: Script.Add('FFD600040410203040', '6C04');
      end;
      Script.EndFails := I in [3, 4];
      Raised := False;
      try Reader.WriteType2UserPage(ttmNtag213, 4, HexToBytes('10203040'));
      except
        on E: EContactlessWriteUncertain do Raised := I in [0, 1, 2, 4];
        on E: EContactlessStatusError do Raised := I in [3, 5];
      end;
      Check(Raised and (Script.Position = 1) and (Script.Ends = 1), 'Type 2 uncertain/denied write never replayed');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Raised := False;
    try Reader.WriteType2UserPage(ttmNtag213, 4, nil);
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid page payload rejected before I/O');
    Script.BeginFails := True;
    Raised := False;
    try Reader.WriteType2UserPage(ttmNtag213, 4, HexToBytes('10203040'));
    except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Script.Ends = 0) and (Script.Position = 0), 'Failed Type 2 acquisition sends no write');
  finally Reader.Free; end;
  Writeln('PASS: optional capabilities, Type 2 failures, primary errors and uncertain writes.');
end;

procedure TestProgrammableUidCodec;
var Block, Uid, Prepared, Decoded: TBytes; I, J: Integer; Raised: Boolean;
begin
  Block := HexToBytes(OldManufacturerHex);
  Uid := HexToBytes(NewUidHex);
  Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, Block, Uid);
  Check(BytesToHex(Prepared) = NewManufacturerHex, 'Four-byte UID replacement with BCC and preserved metadata');
  Check(BytesToHex(Block) = OldManufacturerHex, 'Original manufacturer block unchanged');
  Prepared[5] := 0;
  Check(Block[5] = 8, 'Prepared block owns independent storage');
  Decoded := TProgrammableUidCodec.DecodeGen2Uid(cgum4Byte, Block);
  Decoded[0] := 0;
  Check(Block[0] = $11, 'Decoded UID owns independent storage');
  for I := 0 to 255 do
  begin
    Uid[0] := Byte(I);
    if I = $88 then
    begin
      Raised := False;
      try Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, Block, Uid);
      except on E: EProgrammableUidError do Raised := True; end;
      Check(Raised, 'Four-byte UID cascade marker rejected');
      Continue;
    end;
    Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, Block, Uid);
    Check(Prepared[4] = (Uid[0] xor Uid[1] xor Uid[2] xor Uid[3]), 'Every UID byte value computes BCC');
    for J := 5 to 15 do Check(Prepared[J] = Block[J], 'All metadata bytes preserved');
  end;
  Block := HexToBytes('04112233445566884400C82000000000');
  Uid := HexToBytes('04AABBCCDDEEFF');
  Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum7Byte, Block, Uid);
  Check(BytesToHex(Prepared) = '04AABBCCDDEEFF884400C82000000000', 'Seven-byte layout preserves SAK/ATQA/manufacturer metadata');
  Check(BytesToHex(TProgrammableUidCodec.DecodeGen2Uid(cgum7Byte, Prepared)) = '04AABBCCDDEEFF', 'Seven-byte UID has no stored BCC in byte seven');
  Raised := False;
  try TProgrammableUidCodec.ValidateUid(cgum7Byte, HexToBytes('04AABB88DDEEFF'));
  except on E: EProgrammableUidError do Raised := True; end;
  Check(Raised, 'Seven-byte UID cascade marker at UID3 rejected');
  for I := 0 to 5 do
  begin
    Raised := False;
    try
      case I of
        0: Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, HexToBytes(OldManufacturerHex), nil);
        1: Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, HexToBytes(OldManufacturerHex), Uid);
        2: Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum7Byte, Block, HexToBytes(NewUidHex));
        3: Decoded := TProgrammableUidCodec.DecodeGen2Uid(cgum4Byte, HexToBytes('1122334445' + '0804006263646566676869'));
        4: Decoded := TProgrammableUidCodec.DecodeGen2Uid(cgum7Byte, nil);
        5: Prepared := TProgrammableUidCodec.PrepareGen2Block(cgum7Byte, Block, HexToBytes('00112233445566778899'));
      end;
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised, 'Invalid UID lengths, malformed block or BCC rejected');
  end;
  Writeln('PASS: four/seven-byte Gen2 layouts, checksum, metadata preservation and independent buffers.');
end;

procedure AddGen2Preparation(const AScript: TScript; const AUid, ABlock: string);
begin
  AScript.Add('FFCA000000', AUid + '9000');
  AddAuthentication(AScript, 0, mckA);
  AScript.Add('FFB0000010', ABlock + '9000');
end;

procedure TestGen2Programming;
var Reader: TContactlessCardReader; Script: TScript; Data: TProgrammableUidResult;
  Key, Uid: TBytes; I: Integer;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Key := HexToBytes(KeyHex);
    Uid := HexToBytes(NewUidHex);
    for I := 0 to 1 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      AddGen2Preparation(Script, OldUidHex, OldManufacturerHex);
      Script.Add('FFD6000010' + NewManufacturerHex, '9000');
      Script.Add('FFB0000010', NewManufacturerHex + '9000');
      if I = 0 then Script.Add('FFCA000000', NewUidHex + '9000')
      else Script.Add('FFCA000000', OldUidHex + '9000');
      Data := Reader.ProgramClassicGen2Uid(cgum4Byte, Uid, mckA, Key);
      Check(Data.ActiveUidVerified = (I = 0), 'Active UID differs from EEPROM-only verification');
      Check((BytesToHex(Data.PreviousUid) = OldUidHex) and (BytesToHex(Data.RequestedUid) = NewUidHex), 'Programming snapshot identifiers');
      Check(BytesToHex(Data.ManufacturerBlock) = NewManufacturerHex, 'All sixteen bytes read back');
      Check((Script.Position = 7) and (Script.Begins = 1) and (Script.Ends = 1), 'One write, no reset/reactivation or replay, exclusive operation');
      Check((BytesToHex(Uid) = NewUidHex) and (BytesToHex(Key) = KeyHex), 'Caller UID/key untouched');
      Data.RequestedUid[0] := 0;
      Check(Uid[0] = $A1, 'Snapshot UID independent from caller');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    AddGen2Preparation(Script, OldUidHex, OldManufacturerHex);
    Data := Reader.ProgramClassicGen2Uid(cgum4Byte, HexToBytes(OldUidHex), mckA, Key);
    Check(Data.ActiveUidVerified and (Script.Position = 4), 'Already matching UID is verified without a write');
    Script := TScript.Create;
    Reader.Transport := Script;
    AddGen2Preparation(Script, '04112233445566', '04112233445566884400C82000000000');
    Script.Add('FFD600001004AABBCCDDEEFF884400C82000000000', '9000');
    Script.Add('FFB0000010', '04AABBCCDDEEFF884400C820000000009000');
    Script.Add('FFCA000000', '04AABBCCDDEEFF9000');
    Data := Reader.ProgramClassicGen2Uid(cgum7Byte, HexToBytes('04AABBCCDDEEFF'), mckA, Key);
    Check(Data.ActiveUidVerified and (Data.Model = cgum7Byte), 'Seven-byte programming uses explicitly selected layout');
  finally Reader.Free; end;
  Writeln('PASS: dedicated four/seven-byte Gen2 UID programming, read-back, no-op and reactivation state.');
end;

procedure TestGen2Failures;
var Reader: TContactlessCardReader; Script: TScript; Data: TProgrammableUidResult;
  I: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    for I := 0 to 13 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      if I = 0 then Script.Add('FFCA000000', '041122334455669000')
      else if I = 1 then AddGen2Preparation(Script, '00000000', OldManufacturerHex)
      else if I = 2 then AddGen2Preparation(Script, OldUidHex, '11223344450804006263646566676869')
      else AddGen2Preparation(Script, OldUidHex, OldManufacturerHex);
      case I of
        3: Script.Add('FFD6000010' + NewManufacturerHex, '6300');
        4: Script.Add('FFD6000010' + NewManufacturerHex, '', True);
        5: Script.Add('FFD6000010' + NewManufacturerHex, '90');
        6: Script.Add('FFD6000010' + NewManufacturerHex, 'AA9000');
        7..13: Script.Add('FFD6000010' + NewManufacturerHex, '9000');
      end;
      if I >= 7 then
      begin
        if I = 7 then Script.Add('FFB0000010', OldManufacturerHex + '9000')
        else if I = 8 then Script.Add('FFB0000010', '6982')
        else if I = 9 then Script.Add('FFB0000010', '', True)
        else if I = 10 then Script.Add('FFB0000010', '019000')
        else Script.Add('FFB0000010', NewManufacturerHex + '9000');
      end;
      if I = 11 then Script.Add('FFCA000000', '001122339000');
      if I = 12 then Script.Add('FFCA000000', '6A81');
      if I = 13 then Script.Add('FFCA000000', NewUidHex + '9000');
      Script.EndFails := I in [3, 8, 13];
      Raised := False;
      try Data := Reader.ProgramClassicGen2Uid(cgum4Byte, HexToBytes(NewUidHex), mckA, HexToBytes(KeyHex));
      except
        on E: EContactlessWriteUncertain do
        begin
          Raised := I >= 4;
          if I = 8 then Check(E.OriginalErrorClass = 'EContactlessStatusError', 'Verification error takes precedence over release failure');
        end;
        on E: EContactlessStatusError do Raised := (I = 3) and (E.StatusWord = $6300);
        on E: EContactlessError do Raised := I in [0, 1];
        on E: EProgrammableUidError do Raised := I = 2;
      end;
      Check(Raised and (Script.Ends = 1), 'Invalid/uncertain programming reports no completed result');
      if I = 0 then Check(Script.Position = 1, 'UID-size mismatch stops before key loading')
      else if I in [1, 2] then Check(Script.Position = 4, 'UID/BCC mismatch stops before writing')
      else Check(Script.Position <= 7, 'Failure never retries programming');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Raised := False;
    try Data := Reader.ProgramClassicGen2Uid(cgum4Byte, HexToBytes('00112233445566778899'), mckA, HexToBytes(KeyHex));
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Unsupported ten-byte layout rejected before I/O');
    Raised := False;
    try Data := Reader.ProgramClassicGen2Uid(cgum4Byte, HexToBytes('88112233'), mckA, HexToBytes(KeyHex));
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid UID cascade marker rejected before I/O');
    Raised := False;
    try Reader.WriteClassicDataBlock(mcm1K, 0, mckA, HexToBytes(KeyHex), HexToBytes(NewManufacturerHex));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'General data writer still blocks manufacturer writes');
  finally Reader.Free; end;
  Writeln('PASS: programming validation, denied writes, read-back mismatch and uncertain outcome without replay.');
end;

procedure AddFuidPreparation(Script: TScript);
begin
  Script.Add('FFCA000000', 'AA55C3969000');
  AddAuthentication(Script, 0, mckA);
  Script.Add('FFB0000010', 'AA55C396AA08040062636465666768699000');
end;

procedure TestFuidProgramming;
var Reader: TContactlessCardReader; Script: TScript; Data: TFuidUidResult;
  Capability: IFuidUidReaderProfile; Uid, Key: TBytes; I, J: Integer;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    Check(Supports(Reader.Profile, IFuidUidReaderProfile, Capability), 'Dedicated FUID capability, independent of Gen2 interface');
    Check(BytesToHex(Capability.WriteFuidManufacturerCommand(HexToBytes(NewManufacturerHex))) =
      'FFD6000010' + NewManufacturerHex, 'FUID explicit authenticated write command golden vector');
    for I := 0 to 1 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      AddFuidPreparation(Script);
      Script.Add('FFD6000010' + NewManufacturerHex, '9000');
      Script.Add('FFB0000010', NewManufacturerHex + '9000');
      if I = 0 then Script.Add('FFCA000000', NewUidHex + '9000')
      else Script.Add('FFCA000000', 'AA55C3969000');
      Uid := HexToBytes(NewUidHex);
      Key := HexToBytes(KeyHex);
      Data := Reader.ProgramFuidUidOnce(Uid, mckA, Key);
      Check((Data.ActiveUidVerified = (I = 0)) and (BytesToHex(Data.PreviousUid) = 'AA55C396'), 'Cached factory UID remains explicit, no RF reconnect');
      Check((BytesToHex(Data.ManufacturerBlock) = NewManufacturerHex) and (Script.Position = 7), 'One write, full metadata/BCC read-back');
      Check((Script.Begins = 1) and (Script.Ends = 1), 'One transaction per FUID provisioning');
      Data.RequestedUid[0] := 0;
      Check((BytesToHex(Uid) = NewUidHex) and (BytesToHex(Key) = KeyHex), 'Caller UID/key unchanged and independent result');
      for J := 0 to Length(Script.KeyCommandAlias) - 1 do Check(Script.KeyCommandAlias[J] = 0, 'FUID local key command wiped');
    end;
  finally Reader.Free; end;
  Writeln('PASS: dedicated FUID single-write capability, factory precondition, metadata and cached UID semantics.');
end;

procedure TestFuidFailures;
var Reader: TContactlessCardReader; Script: TScript; Data: TFuidUidResult;
  I, Last: Integer; Raised: Boolean;
begin
  Reader := TContactlessCardReader.Create(nil);
  try
    Reader.Profile := TPcscStorageProfile.Create;
    for I := 0 to 11 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      AddFuidPreparation(Script);
      Script.Add('FFD6000010' + NewManufacturerHex, '9000');
      Script.Add('FFB0000010', NewManufacturerHex + '9000');
      Script.Add('FFCA000000', NewUidHex + '9000');
      Last := 6;
      case I of
        0: begin Script.Steps[0].Response := HexToBytes(NewUidHex + '9000'); Last := 0; end;
        1: begin Script.Steps[3].Response := HexToBytes(OldManufacturerHex + '9000'); Last := 3; end;
        2: begin Script.Steps[3].Response[4] := 0; Last := 3; end;
        3: begin Script.Steps[4].Response := HexToBytes('6982'); Last := 4; end;
        4: begin Script.Steps[4].Fails := True; Last := 4; end;
        5: begin Script.Steps[4].Response := HexToBytes('90'); Last := 4; end;
        6: begin Script.Steps[4].Response := HexToBytes('009000'); Last := 4; end;
        7: begin Script.Steps[5].Response[15] := 0; Last := 5; end;
        8: begin Script.Steps[6].Response := HexToBytes('010203049000'); end;
        9: Script.EndFails := True;
        10: begin Script.Steps[5].Response := HexToBytes('6982'); Last := 5; Script.EndFails := True; end;
        11: begin Script.Steps[1].Response := HexToBytes('6982'); Last := 1; end;
      end;
      SetLength(Script.Steps, Last + 1);
      Raised := False;
      try Data := Reader.ProgramFuidUidOnce(HexToBytes(NewUidHex), mckA, HexToBytes(KeyHex));
      except
        on E: EContactlessWriteUncertain do
        begin
          Check(I in [3..10], 'All post-dispatch failures uncertain, including explicit denial');
          if I = 10 then Check(E.OriginalErrorClass = 'EContactlessStatusError', 'Primary status wins over cleanup');
          Raised := True;
        end;
        on E: EProgrammableUidError do begin Check(I = 2, 'Invalid BCC before write'); Raised := True; end;
        on E: EContactlessStatusError do begin Check(I = 11, 'Authentication denied before write'); Raised := True; end;
        on E: EContactlessError do begin Check(I in [0, 1], 'Non-factory/mismatched source before write'); Raised := True; end;
      end;
      Check(Raised and (Script.Ends = 1) and (Script.Position = Length(Script.Steps)), 'FUID failure stops at exact stage without replay or additional writes');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Raised := False;
    try Data := Reader.ProgramFuidUidOnce(HexToBytes('AA55C396'), mckA, HexToBytes(KeyHex));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Unchanged factory target rejected before I/O');
    Raised := False;
    try Data := Reader.ProgramFuidUidOnce(HexToBytes('88112233'), mckA, HexToBytes(KeyHex));
    except on E: EProgrammableUidError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid cascade before I/O');
    Raised := False;
    try Data := Reader.ProgramFuidUidOnce(HexToBytes(NewUidHex), mckA, HexToBytes('0102'));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Invalid key size before I/O');
    Reader.Profile := TClassicOnlyProfile.Create;
    Raised := False;
    try Data := Reader.ProgramFuidUidOnce(HexToBytes(NewUidHex), mckA, HexToBytes(KeyHex));
    except on E: EContactlessError do Raised := True; end;
    Check(Raised and (Script.Begins = 0), 'Old profiles require explicit new FUID capability');
  finally Reader.Free; end;
  Writeln('PASS: factory/no-op/capability checks, single-write denial, transport, malformed response, read-back and release failures.');
end;

begin
  try
    TestLayout;
    TestUidAndProfiles;
    TestClassicReadWrite;
    TestProtectedAndInvalidOperations;
    TestFailureOutcomes;
    TestType2LayoutsAndPages;
    TestType2FailuresAndCapabilities;
    TestProgrammableUidCodec;
    TestGen2Programming;
    TestGen2Failures;
    TestFuidProgramming;
    TestFuidFailures;
    Writeln('PASS: ', Checks, ' assertions across twelve contactless test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
