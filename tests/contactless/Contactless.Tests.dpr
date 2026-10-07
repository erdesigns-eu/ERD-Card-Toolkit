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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.APDU, ERD.Card.Contactless;

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
var Checks: Integer = 0;
const
  KeyHex = '010203040506'; // Synthetic caller key, not a real card credential.
  BlockHex = '00112233445566778899AABBCCDDEEFF';

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

begin
  try
    TestLayout;
    TestUidAndProfiles;
    TestClassicReadWrite;
    TestProtectedAndInvalidOperations;
    TestFailureOutcomes;
    Writeln('PASS: ', Checks, ' assertions across five contactless test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
