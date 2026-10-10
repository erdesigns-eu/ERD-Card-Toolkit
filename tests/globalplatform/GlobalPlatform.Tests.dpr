program GlobalPlatformTests;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{$IFNDEF FPC}
{$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.APDU, ERD.Card.Crypto,
  ERD.Card.Crypto.DES, ERD.Card.GlobalPlatform,
  ERD.Card.GlobalPlatform.SecureChannel, ERD.Card.GlobalPlatform.CAP,
  ERD.Card.GlobalPlatform.Management, ERD.Card.Crypto.Hash, ERD.Card.Crypto.RSA,
  ERD.Card.Crypto.RSA.Native,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows, ERD.Card.Crypto.Hash.Windows;
{$ELSE}
  ERD.Card.Crypto.OpenSSL, ERD.Card.Crypto.Hash.OpenSSL;
{$ENDIF}

type
  TByteArrays = array of TBytes;
  TTranscript = record
    Keys: TGpCardKeys;
    Host, Domain, TokenKey, ReceiptKey: TBytes;
    RsaTokens: Boolean;
    Protocol: TGpSecureProtocol;
    Level: TGpSecurityLevel;
    S16, NewIsAes: Boolean;
    Commands, Responses, PlainCommands, PlainResponses: TByteArrays;
  end;
  TTranscripts = array of TTranscript;

  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Commands, Responses: TByteArrays;
    Calls, Begins, Ends, CorruptAt, FailAt, OverrideAt: Integer;
    OverrideResponse: TBytes;
    InTransaction: Boolean;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

  TProgress = class
  public
    Calls, Completed, Total: Integer;
    procedure Progress(Sender: TObject; const Done, Size: Integer);
  end;

  TFixedRandom = class(TInterfacedObject, ICardAesProvider, ICardDesProvider)
  private
    FBase: ICardDesProvider;
  public
    Host: TBytes;
    BadRandom: Boolean;
    constructor Create(const ABase: ICardDesProvider);
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function RandomBytes(const ACount: Integer): TBytes;
    function TripleDesCbc(const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
  end;

{$IFDEF CARDCRYPTO_ABI_TEST}
function test_crypto_live: Integer; cdecl; external 'bcrypt.dll';
function test_crypto_calls: Integer; cdecl; external 'bcrypt.dll';
procedure test_crypto_reset(Fail, Wrong: Integer); cdecl; external 'bcrypt.dll';
{$ENDIF}

var
  Assertions: Integer;

procedure Check(const Condition: Boolean; const Message: string);
begin
  Inc(Assertions);
  if not Condition then raise Exception.Create(Message);
end;

procedure Add(var List: TByteArrays; const Data: TBytes);
var N: Integer;
begin
  N := Length(List); SetLength(List, N + 1); List[N] := CopyBytes(Data);
end;

function TScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Inc(Calls);
  Check(InTransaction, 'All GP I/O is in an exclusive transaction');
  if Calls = FailAt then raise ECardTransportError.Create('Injected transport failure');
  Check(Calls <= Length(Commands), 'No unexpected retry or command');
  Check(BytesToHex(ACommand) = BytesToHex(Commands[Calls - 1]),
    'Independent protected command mismatch at ' + IntToStr(Calls));
  Result := CopyBytes(Responses[Calls - 1]);
  if Calls = OverrideAt then Result := CopyBytes(OverrideResponse);
  if Calls = CorruptAt then Result[Length(Result) - 3] := Result[Length(Result) - 3] xor 1;
end;

procedure TScript.BeginTransaction;
begin
  Check(not InTransaction, 'Non-nesting transaction');
  InTransaction := True; Inc(Begins);
end;

procedure TScript.EndTransaction;
begin
  Check(InTransaction, 'Release acquired transaction exactly once');
  InTransaction := False; Inc(Ends);
end;

procedure TProgress.Progress(Sender: TObject; const Done, Size: Integer);
begin
  Check((Done > Completed) and (Done <= Size), 'Monotonic acknowledged LOAD progress');
  Inc(Calls); Completed := Done; Total := Size;
end;

constructor TFixedRandom.Create(const ABase: ICardDesProvider);
begin
  inherited Create; FBase := ABase;
end;

function TFixedRandom.EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin
  Result := FBase.EncryptCbc(AKey, AIv, AData);
end;

function TFixedRandom.DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin
  Result := FBase.DecryptCbc(AKey, AIv, AData);
end;

function TFixedRandom.RandomBytes(const ACount: Integer): TBytes;
begin
  Check(ACount = Length(Host), 'Requested S8/S16 random length');
  Result := CopyBytes(Host);
  if BadRandom then SetLength(Result, Length(Result) - 1);
end;

function TFixedRandom.TripleDesCbc(const AKey, AIv, AData: TBytes;
  const AEncrypt: Boolean): TBytes;
begin
  Result := FBase.TripleDesCbc(AKey, AIv, AData, AEncrypt);
end;

function LoadTranscripts(const FileName: string): TTranscripts;
var
  Lines, Fields: TStringList;
  I, Index: Integer;
begin
  Result := nil; Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    Fields.Delimiter := '|'; Fields.StrictDelimiter := True; Index := -1;
    for I := 0 to Lines.Count - 1 do
    begin
      if (Lines[I] = '') or (Lines[I][1] = '#') then Continue;
      Fields.DelimitedText := Lines[I];
      if Fields[0] = 'S' then
      begin
        Index := Length(Result); SetLength(Result, Index + 1);
        Result[Index].Keys.Enc := HexToBytes(Fields[1]);
        Result[Index].Keys.Mac := HexToBytes(Fields[2]);
        Result[Index].Host := HexToBytes(Fields[3]);
        if Fields[4] = '2' then Result[Index].Protocol := gspScp02
        else Result[Index].Protocol := gspScp03;
        Result[Index].Level := TGpSecurityLevel(StrToInt(Fields[5]));
        Result[Index].S16 := Fields[6] = '1';
        Result[Index].Domain := HexToBytes(Fields[7]);
        if Fields.Count > 8 then begin Result[Index].Keys.Dek := HexToBytes(Fields[8]);
          Result[Index].NewIsAes := Fields[9] = '1'; end;
        if Fields.Count > 10 then begin Result[Index].TokenKey := HexToBytes(Fields[10]);
          Result[Index].ReceiptKey := HexToBytes(Fields[11]); Result[Index].RsaTokens := Fields[12] = '1'; end;
      end
      else if Fields[0] = 'A' then
      begin
        Add(Result[Index].Commands, HexToBytes(Fields[1]));
        Add(Result[Index].Responses, HexToBytes(Fields[2]));
      end
      else if Fields[0] = 'X' then
      begin
        Add(Result[Index].PlainCommands, HexToBytes(Fields[1]));
        Add(Result[Index].Commands, HexToBytes(Fields[2]));
        Add(Result[Index].Responses, HexToBytes(Fields[3]));
        Add(Result[Index].PlainResponses, HexToBytes(Fields[4]));
      end;
    end;
  finally Fields.Free; Lines.Free; end;
end;

procedure TranscriptTests(const All: TTranscripts; const Native: ICardDesProvider);
var
  I, J: Integer;
  Script: TScript;
  Transport, Retain: ICardTransport;
  Random: TFixedRandom;
  Backend: ICardDesProvider;
  Channel: TGpSecureChannel;
  Actual, Original: TBytes;
begin
  for I := 0 to High(All) do
  begin
    Script := TScript.Create; Transport := Script;
    Script.Commands := All[I].Commands; Script.Responses := All[I].Responses;
    Random := TFixedRandom.Create(Native); Random.Host := All[I].Host; Backend := Random;
    Channel := TGpSecureChannel.Create(Transport, Backend, Backend); Retain := Channel;
    try
      Original := CopyBytes(All[I].Keys.Enc);
      Channel.Open(All[I].Protocol, All[I].Keys, 1, 0, All[I].Level, All[I].S16, All[I].Domain);
      Check(Channel.Active, 'Verified authentication');
      for J := 0 to High(All[I].PlainCommands) do
      begin
        Actual := Retain.Exchange(All[I].PlainCommands[J]);
        Check(BytesToHex(Actual) = BytesToHex(All[I].PlainResponses[J]), 'Independent response decrypt/MAC');
      end;
      Check(BytesToHex(Original) = BytesToHex(All[I].Keys.Enc), 'Borrowed key preserved');
      Channel.Close; Channel.Close;
      Check((Script.Begins = 1) and (Script.Ends = 1) and not Script.InTransaction, 'Transaction lifecycle');
      Check(Script.Calls = Length(All[I].Commands), 'Exactly one send per command');
    finally Retain := nil; Transport := nil; Backend := nil; end;
  end;
  Writeln('PASS: 154 independent SCP02/SCP03 random/pseudo-random S8/S16 sessions; 1232 protected exchanges.');
end;

procedure FailureTests(const Vector: TTranscript; const Native: ICardDesProvider);
var
  Script: TScript;
  Transport, Retain: ICardTransport;
  Random: TFixedRandom;
  Backend: ICardDesProvider;
  Channel: TGpSecureChannel;
  I, Calls: Integer;
  Failed: Boolean;
  Actual: TBytes;
begin
  for I := 0 to 6 do
  begin
    Script := TScript.Create; Transport := Script;
    Script.Commands := Vector.Commands; Script.Responses := Vector.Responses;
    Random := TFixedRandom.Create(Native); Random.Host := Vector.Host; Backend := Random;
    Channel := TGpSecureChannel.Create(Transport, Backend, Backend); Retain := Channel;
    try
      case I of
        0: Script.CorruptAt := 1;
        1: Random.BadRandom := True;
        2: Script.FailAt := 1;
        3: Script.OverrideAt := 1;
      end;
      if I = 3 then Script.OverrideResponse := HexToBytes('9000');
      Failed := False; Actual := nil;
      try
        Channel.Open(Vector.Protocol, Vector.Keys, 1, 0, Vector.Level, Vector.S16, Vector.Domain);
        if I = 4 then Script.CorruptAt := 3;
        if I = 5 then Script.FailAt := 3;
        if I = 6 then
        begin
          Script.OverrideAt := 3; Script.OverrideResponse := HexToBytes('9000');
        end;
        if I >= 4 then Actual := Retain.Exchange(Vector.PlainCommands[0]);
      except
        on E: Exception do Failed := True;
      end;
      Check(Failed and not Channel.Active, 'Fault invalidates channel');
      Check(Length(Actual) = 0, 'No plaintext released after failed authentication');
      Check((Script.Begins = 1) and (Script.Ends = 1), 'Fault releases transaction');
      Calls := Script.Calls;
      try Actual := Retain.Exchange(Vector.PlainCommands[0]); except end;
      Check(Script.Calls = Calls, 'Failed channel never sends or retries');
    finally Retain := nil; Transport := nil; Backend := nil; end;
  end;
  Writeln('PASS: Wrong cryptogram/RNG, native I/O failure and absent/corrupt RMAC fail closed.');
end;

function Component(const Tag: Byte; const Body: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, 3 + Length(Body)); Result[0] := Tag;
  Result[1] := Length(Body) shr 8; Result[2] := Length(Body) and $FF;
  if Length(Body) > 0 then Move(Body[0], Result[3], Length(Body));
end;

function MinimalCap: TGpCapComponents;
var
  I: Integer;
  Directory: TBytes;
begin
  Result := nil; SetLength(Result, 9);
  Result[0] := Component(1, HexToBytes('DECAFFED020204000108A000000151000101'));
  Result[2] := Component(3, HexToBytes('0108A0000001510001020000'));
  Result[3] := Component(4, HexToBytes('00'));
  Result[4] := Component(5, HexToBytes('0000'));
  Result[5] := Component(6, HexToBytes('00'));
  Result[6] := Component(7, HexToBytes('00'));
  Result[7] := Component(8, HexToBytes('00000000000000000000'));
  Result[8] := Component(9, HexToBytes('00000000'));
  SetLength(Directory, 33);
  for I := 0 to High(Result) do
    if I <> 1 then
    begin
      Directory[(Result[I][0] - 1) * 2] := (Length(Result[I]) - 3) shr 8;
      Directory[(Result[I][0] - 1) * 2 + 1] := (Length(Result[I]) - 3) and $FF;
    end;
  Directory[2] := 0; Directory[3] := 33;
  Directory[31] := 1;
  Result[1] := Component(2, Directory);
end;

procedure CapTests;
var
  Parts: TGpCapComponents;
  Cap: TGpCapFile;
  Aids: TGpAppletAids;
  Bytes: TBytes;
  I: Integer;
  Failed: Boolean;
begin
  Parts := MinimalCap; Cap := TGpCapFile.FromComponents(Parts);
  try
    Check(BytesToHex(Cap.PackageAid) = 'A000000151000101', 'CAP package AID');
    Aids := Cap.Applets;
    Check((Length(Aids) = 1) and (BytesToHex(Aids[0]) = 'A000000151000102'), 'CAP applet AID');
    Bytes := Cap.LoadImage; Check(Bytes[0] = $C4, 'Canonical C4 load file');
    Parts[0][13] := 0; Bytes[0] := 0; Aids[0][0] := 0;
    Check(BytesToHex(Cap.PackageAid) = 'A000000151000101', 'CAP input/output independence');
    Bytes := Cap.LoadImage; Check(Bytes[0] = $C4, 'Independent load image');
  finally Cap.Free; end;
  for I := 0 to 5 do
  begin
    Parts := MinimalCap;
    case I of
      0: Parts[0][3] := 0;
      1: Parts[0][8] := 3;
      2: Parts[0][12] := 4;
      3: Parts[1][3] := 1;
      4: Parts[2][4] := 3;
      5: Parts[8] := Parts[7];
    end;
    Failed := False;
    try Cap := TGpCapFile.FromComponents(Parts); Cap.Free;
    except on EGpCapError do Failed := True; end;
    Check(Failed, 'Invalid CAP rejected before any card I/O');
  end;
  Writeln('PASS: CAP framing, directory consistency, identities, canonical order and borrowed-buffer ownership.');
end;

procedure ReaderTests;
var
  Script: TScript;
  Transport: ICardTransport;
  Manager: TGlobalPlatformCardManager;
  Fields: TGpCplcFields;
  Entries: TGpRegistryEntries;
  KeyInfo: TGpKeyInformationList;
  Failed: Boolean;
begin
  Script := TScript.Create; Transport := Script;
  Add(Script.Commands, HexToBytes('80CA9F7F00'));
  Add(Script.Responses, HexToBytes('9F7F2A000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728299000'));
  Add(Script.Commands, HexToBytes('80F24002024F0000'));
  Add(Script.Responses, HexToBytes('E3114F08A0000001510001029F700107C501006310'));
  Add(Script.Commands, HexToBytes('80F24003024F0000'));
  Add(Script.Responses, HexToBytes('E3114F08A0000001510001039F700103C501009000'));
  Add(Script.Commands, HexToBytes('80CA00E000'));
  Add(Script.Responses, HexToBytes('E00CC00401018810C004020180109000'));
  Manager := TGlobalPlatformCardManager.Create(nil);
  try
    Manager.Transport := Transport;
    Fields := Manager.ReadCplc;
    Check((Length(Fields) = 18) and (BytesToHex(Fields[6].Value) = '0C0D0E0F'), 'CPLC serial width/order');
    Entries := Manager.GetStatus(grkApplications);
    Check((Length(Entries) = 2) and (Entries[1].LifeCycle = 3), 'Bounded 6310 registry continuation');
    Check(Script.Ends = 2, 'Multi-page registry owns one transaction');
    KeyInfo := Manager.ReadKeyInformation;
    Check((Length(KeyInfo) = 2) and (KeyInfo[0].Version = 1) and
      (BytesToHex(KeyInfo[1].Components) = '8010'), 'Key metadata without secret material');
    Failed := False;
    try Manager.DeleteObject(HexToBytes('A000000151000102'));
    except on EGpCardError do Failed := True; end;
    Check(Failed and (Script.Calls = 4), 'Management requires authenticated session');
  finally Manager.Free; Transport := nil; end;
  Writeln('PASS: CPLC, tagged registry continuation and refused unauthenticated management.');
end;

procedure ManagementTests(const Native: ICardDesProvider);
var
  Vectors: TTranscripts;
  Script: TScript;
  Transport: ICardTransport;
  Random: TFixedRandom;
  Backend: ICardDesProvider;
  Manager: TGlobalPlatformCardManager;
  Cap: TGpCapFile;
  Progress: TProgress;
  I, Mode, Before: Integer;
  Failed: Boolean;
  R: TApduResponse;
begin
  Vectors := LoadTranscripts('tests/globalplatform/fixtures/management.txt');
  Check(Length(Vectors) = 3, 'Management transcript count');
  for I := 0 to High(Vectors) do
    for Mode := 0 to 1 do
    begin
      Script := TScript.Create; Transport := Script;
      Script.Commands := Vectors[I].Commands; Script.Responses := Vectors[I].Responses;
      Random := TFixedRandom.Create(Native); Random.Host := Vectors[I].Host; Backend := Random;
      Manager := TGlobalPlatformCardManager.Create(nil); Progress := TProgress.Create;
      Cap := TGpCapFile.FromComponents(MinimalCap);
      try
        Manager.Transport := Transport; Manager.AesProvider := Backend; Manager.DesProvider := Backend;
        Manager.OnLoadProgress := Progress.Progress;
        R := Manager.SelectSecurityDomain(Vectors[I].Domain);
        Check(R.StatusWord = $9000, 'Explicit domain selection');
        Manager.Authenticate(Vectors[I].Protocol, Vectors[I].Keys, 1, 0,
          Vectors[I].Level, Vectors[I].S16);
        Before := Script.Calls;
        Failed := False;
        try Manager.LoadCap(Cap, Vectors[I].Domain, 0);
        except on EGpCardError do Failed := True; end;
        Check(Failed and (Script.Calls = Before), 'Invalid load preflight sends no INSTALL');
        Failed := False;
        try Manager.InstallApplet(Cap, HexToBytes('A000000151000104'),
          HexToBytes('A000000151000103'), HexToBytes('00'), nil);
        except on EGpCardError do Failed := True; end;
        Check(Failed and (Script.Calls = Before), 'Unknown module refused before INSTALL');
        if Mode = 1 then Script.FailAt := 7;
        Failed := False;
        try Manager.LoadCap(Cap, Vectors[I].Domain, 20);
        except on ECardTransportError do Failed := True; end;
        if Mode = 1 then
        begin
          Check(Failed and not Manager.Authenticated, 'Partial load failure invalidates session');
          Check((Script.Calls = 7) and (Progress.Calls = 1) and (Progress.Completed = 20),
            'Failed LOAD never retried; progress only acknowledged bytes');
        end
        else
        begin
          Check(not Failed and (Progress.Completed = Length(Cap.LoadImage)), 'Complete CAP load progress');
          Manager.InstallApplet(Cap, HexToBytes('A000000151000102'),
            HexToBytes('A000000151000103'), HexToBytes('00'), HexToBytes('0102'));
          Check(BytesToHex(Manager.LastConfirmation) = '110801020304050607080200010401020304',
            'Receipt retained without verification claim');
          Manager.SetStatus(grkApplications, HexToBytes('A000000151000103'), 7);
          Manager.DeleteObject(HexToBytes('A000000151000103'), True);
          Check(Script.Calls = Length(Script.Commands), 'Independent INSTALL/LOAD/DELETE/SET STATUS bytes');
        end;
        Manager.CloseSession;
        Check((Script.Begins = 2) and (Script.Ends = 2), 'Selected domain reselected in owned secure transaction');
      finally Cap.Free; Manager.Free; Progress.Free; Transport := nil; Backend := nil; end;
    end;
  Writeln('PASS: Independent CAP LOAD/INSTALL, receipts, DELETE, SET STATUS and partial-load failures.');
end;

var
  All: TTranscripts;
  Native: ICardDesProvider;
  I, FullIndex: Integer;
procedure ManagementCryptoTests;
var Lines, Fields: TStringList; I, J: Integer;
  Native: ICardDesProvider; Hash: ICardHashProvider; Rsa: ICardRsaProvider;
  AesSigner: ICardGpTokenSigner; RsaSigner: ICardGpTokenSigner;
  Verifier: ICardGpReceiptVerifier; V: TGpReceiptVerifier;
  Command: TApduCommand; Key, Msg, Identity, Context, Confirmation, Signature, Bad: TBytes;
  Rejected: Boolean;
{$IFDEF CARDCRYPTO_ABI_TEST}
  Calls, Fault: Integer;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Native := TCardWindowsAesProvider.Create; Hash := TCardWindowsHashProvider.Create;
{$ELSE}
  Native := TCardOpenSslAesProvider.Create; Hash := TCardOpenSSLHashProvider.Create;
{$ENDIF}
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.LoadFromFile('tests/globalplatform/fixtures/management-crypto.txt');
    Fields.Delimiter := '|'; Fields.StrictDelimiter := True;
    for I := 0 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[I];
      if Fields[0] = 'RSA' then
      begin
        Rsa := TCardNativeRsaProvider.Create(Hash, HexToBytes(Fields[1]), HexToBytes(Fields[2]),
          HexToBytes(Fields[3]), HexToBytes(Fields[4]), HexToBytes(Fields[5]));
        RsaSigner := TGpRsaTokenSigner.Create(Rsa);
      end
      else if Fields[0] = 'M' then
      begin
        Key := HexToBytes(Fields[1]); Msg := HexToBytes(Fields[2]);
        Check(BytesToHex(TGpManagementCrypto.RetailMac(Native, Key, Msg)) = UpperCase(Fields[3]), 'Independent DES retail MAC');
        Check(BytesToHex(TCardCrypto.Cmac(Native, Key, Msg)) = UpperCase(Fields[4]), 'Independent AES CMAC');
        Check(BytesToHex(TGpManagementCrypto.KeyCheckValue(Native, Native, Key, False)) = UpperCase(Fields[5]), 'DES KCV zero input');
        Check(BytesToHex(TGpManagementCrypto.KeyCheckValue(Native, Native, Key, True)) = UpperCase(Fields[6]), 'GP AES KCV 01 input');
        AesSigner := TGpAesTokenSigner.Create(Native, Key);
      end
      else if Fields[0] = 'T' then
      begin
        Command := Default(TApduCommand); Command.CLA := $80; Command.INS := $E6; Command.P1 := $02;
        Command.Data := HexToBytes(Fields[1]); Signature := RsaSigner.Sign(Command);
        Check(BytesToHex(Signature) = UpperCase(Fields[2]), 'Independent native RSA token');
        Check(Rsa.VerifySha1(TGpManagementCrypto.TokenInput(Command), Signature), 'RSA verify');
        Signature[0] := Signature[0] xor 1;
        Check(not Rsa.VerifySha1(TGpManagementCrypto.TokenInput(Command), Signature), 'RSA corrupt signature');
        Check(not Rsa.VerifySha1(nil, nil), 'RSA wrong signature length');
        Check(BytesToHex(AesSigner.Sign(Command)) = UpperCase(Fields[3]), 'AES delegated token input');
      end
      else if Fields[0] = 'D' then
      begin
        Msg := HexToBytes(Fields[1]); Signature := TGpManagementCrypto.RsaDap(Hash, Rsa, Msg);
        Check(BytesToHex(Signature) = UpperCase(Fields[3]), 'Independent RSA DAP hash of hash');
        Check(TGpManagementCrypto.VerifyRsaDap(Hash, Rsa, Msg, Signature), 'DAP verify');
        Bad := CopyBytes(Signature); Bad[0] := Bad[0] xor 1;
        Check(not TGpManagementCrypto.VerifyRsaDap(Hash, Rsa, Msg, Bad), 'Corrupt RSA DAP');
        Bad := TGpManagementCrypto.SymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), False);
        Check(BytesToHex(Bad) = UpperCase(Fields[4]), 'Independent DES DAP');
        Check(TGpManagementCrypto.VerifySymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), Bad, False), 'DES DAP verify');
        Bad[0] := Bad[0] xor 1;
        Check(not TGpManagementCrypto.VerifySymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), Bad, False), 'Corrupt DES DAP');
        Bad := TGpManagementCrypto.SymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), True);
        Check(BytesToHex(Bad) = UpperCase(Fields[5]), 'Independent AES DAP');
        Check(TGpManagementCrypto.VerifySymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), Bad, True), 'AES DAP verify');
        Bad[0] := Bad[0] xor 1;
        Check(not TGpManagementCrypto.VerifySymmetricDap(Native, Native, Key, HexToBytes(Fields[2]), Bad, True), 'Corrupt AES DAP');
        Bad := TGpManagementCrypto.DapBlock(HexToBytes('A000000151000000'), Signature);
        Check((Bad[0] = $E2) and (Bad[1] = $81), 'DAP BER length');
      end
      else if Fields[0] = 'R' then
      begin
        Key := HexToBytes(Fields[2]); Identity := HexToBytes(Fields[3]);
        Context := HexToBytes(Fields[4]); Confirmation := HexToBytes(Fields[5]);
        if Fields[1] = '1' then V := TGpReceiptVerifier.CreateAes(Native, Key, Identity)
        else V := TGpReceiptVerifier.CreateDes(Native, Key, Identity);
        Verifier := V;
        // Each byte corruption must be rejected without advancing replay state.
        for J := 0 to High(Confirmation) do
        begin
          Bad := CopyBytes(Confirmation); Bad[J] := Bad[J] xor 1; Rejected := False;
          try Verifier.Verify(Bad, Context); except on E: ECardCryptoError do Rejected := True; end;
          Check(Rejected and (V.LastCounter = -1), 'Receipt corruption rejected atomically');
        end;
        Bad := CopyBytes(Context); Bad[High(Bad)] := Bad[High(Bad)] xor 1; Rejected := False;
        try Verifier.Verify(Confirmation, Bad); except on E: ECardCryptoError do Rejected := True; end;
        Check(Rejected and (V.LastCounter = -1), 'Wrong operation receipt context');
        Verifier.Verify(Confirmation, Context); Check(V.LastCounter > 0, 'Authenticated receipt advances counter');
        Rejected := False;
        try Verifier.Verify(Confirmation, Context); except on E: ECardCryptoError do Rejected := True; end;
        Check(Rejected, 'Replayed receipt refused'); Verifier := nil;
      end;
    end;
  finally Fields.Free; Lines.Free; TCardCrypto.Clear(Key); end;
{$IFDEF CARDCRYPTO_ABI_TEST}
  test_crypto_reset(0, 0); Signature := Rsa.SignSha1(HexToBytes('01020304'));
  Calls := test_crypto_calls;
  Check(test_crypto_live = 0, 'Native RSA success releases every handle');
  // Cleanup failures are suppressed after handles are released; mandatory native calls fail explicitly.
  for Fault := 1 to Calls - 2 do
  begin
    test_crypto_reset(Fault, 0); Rejected := False;
    try Signature := Rsa.SignSha1(HexToBytes('01020304'));
    except on E: ECardCryptoError do Rejected := True; end;
    Check(test_crypto_live = 0, 'Native RSA failure releases every handle');
    if not (Fault in [5, 6]) then Check(Rejected, 'Mandatory native RSA failures propagate');
  end;
  test_crypto_reset(0, 2); Rejected := False;
  try Signature := Rsa.SignSha1(nil); except on E: ECardCryptoError do Rejected := True; end;
  Check(Rejected and (test_crypto_live = 0), 'RSA wrong native signature length');
  test_crypto_reset(0, 0);
{$ENDIF}
  Writeln('PASS: Independent RSA/AES tokens, RSA DAP, AES/DES KCV and receipts including corruption/replay.');
end;

procedure KeyUpdateTests;
var List: TTranscripts; T: TTranscript; I, Mode: Integer;
  Script: TScript; Transport: ICardTransport; Fixed: TFixedRandom; Provider: ICardDesProvider;
  Manager: TGlobalPlatformCardManager; Keys: TGpCardKeys; Response: TApduResponse;
  Rejected: Boolean;
begin
  List := LoadTranscripts('tests/globalplatform/fixtures/key-updates.txt');
  Check(Length(List) = 10, 'Ten independent key wrapping profiles');
{$IFDEF MSWINDOWS}
  Provider := TCardWindowsAesProvider.Create;
{$ELSE}
  Provider := TCardOpenSslAesProvider.Create;
{$ENDIF}
  Keys := Default(TGpCardKeys);
  Keys.Enc := HexToBytes('101112131415161718191A1B1C1D1E1F');
  Keys.Mac := HexToBytes('202122232425262728292A2B2C2D2E2F');
  Keys.Dek := HexToBytes('303132333435363738393A3B3C3D3E3F');
  for I := 0 to High(List) do
  begin
    T := List[I];
    for Mode := 0 to 2 do
    begin
      Script := TScript.Create; Transport := Script;
      Script.Commands := T.Commands; Script.Responses := T.Responses;
      if Mode = 1 then Script.FailAt := Length(T.Commands);
      if Mode = 2 then
      begin
        // For command-MAC-only profiles return wrong KCV; encrypted profiles fail response authentication.
        Script.OverrideAt := Length(T.Commands); Script.OverrideResponse := HexToBytes('020000000000000000009000');
      end;
      Manager := TGlobalPlatformCardManager.Create(nil); Fixed := TFixedRandom.Create(Provider);
      try
        Fixed.Host := T.Host; Manager.DesProvider := Fixed; Manager.AesProvider := Manager.DesProvider;
        Manager.Transport := Transport; Response := Manager.SelectSecurityDomain(T.Domain);
        Check(Response.StatusWord = $9000, 'Key update select');
        Manager.Authenticate(T.Protocol, T.Keys, 1, 0, T.Level, T.S16);
        Rejected := False;
        try Manager.PutKeySet(1, 2, 1, Keys, T.NewIsAes);
        except on E: Exception do Rejected := True; end;
        Check(Rejected = (Mode <> 0), 'PUT KEY success/failure result');
        Check(not Manager.Authenticated and (Script.Ends = 2), 'Submitted PUT KEY always closes session');
        Check(Script.Calls = Length(T.Commands), 'Key update never retries');
        Check(BytesToHex(Keys.Enc) = '101112131415161718191A1B1C1D1E1F', 'New caller key unmodified');
      finally Manager.Free; Transport := nil; end;
    end;
  end;
  TCardCrypto.Clear(Keys.Enc); TCardCrypto.Clear(Keys.Mac); TCardCrypto.Clear(Keys.Dek);
  Writeln('PASS: Independent DEK key wrapping and PUT KEY; wrong KCV and I/O failures close without retries.');
end;

procedure DelegatedManagementTests;
var List: TTranscripts; T: TTranscript; I, Mode, Before: Integer;
  Native: ICardDesProvider; Hash: ICardHashProvider; Rsa: ICardRsaProvider;
  Fixed: TFixedRandom; Script: TScript; Transport: ICardTransport;
  Manager: TGlobalPlatformCardManager; Cap: TGpCapFile;
  Verifier: TGpReceiptVerifier; R: TApduResponse; Lines, Fields: TStringList;
  Dap, LoadHash: TBytes; Rejected: Boolean;
begin
{$IFDEF MSWINDOWS}
  Native := TCardWindowsAesProvider.Create; Hash := TCardWindowsHashProvider.Create;
{$ELSE}
  Native := TCardOpenSslAesProvider.Create; Hash := TCardOpenSSLHashProvider.Create;
{$ENDIF}
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.LoadFromFile('tests/globalplatform/fixtures/management-crypto.txt');
    Fields.Delimiter := '|'; Fields.StrictDelimiter := True; Fields.DelimitedText := Lines[0];
    Rsa := TCardNativeRsaProvider.Create(Hash, HexToBytes(Fields[1]), HexToBytes(Fields[2]),
      HexToBytes(Fields[3]), HexToBytes(Fields[4]), HexToBytes(Fields[5]));
    Lines.LoadFromFile('tests/globalplatform/fixtures/dap-block.txt'); Dap := HexToBytes(Lines[0]);
  finally Lines.Free; Fields.Free; end;
  List := LoadTranscripts('tests/globalplatform/fixtures/delegated-management.txt');
  Check(Length(List) = 6, 'Six issuer-token/DAP/receipt manager transcripts');
  for I := 0 to High(List) do
    for Mode := 0 to 2 do
    begin
      T := List[I]; Script := TScript.Create; Transport := Script;
      Script.Commands := T.Commands; Script.Responses := T.Responses;
      Manager := TGlobalPlatformCardManager.Create(nil); Cap := TGpCapFile.FromComponents(MinimalCap);
      try
        Fixed := TFixedRandom.Create(Native); Fixed.Host := T.Host;
        Manager.DesProvider := Fixed; Manager.AesProvider := Manager.DesProvider; Manager.Transport := Transport;
        R := Manager.SelectSecurityDomain(T.Domain); Check(R.StatusWord = $9000, 'Delegated domain select');
        Manager.Authenticate(T.Protocol, T.Keys, 1, 0, T.Level, T.S16);
        if T.RsaTokens then Manager.TokenSigner := TGpRsaTokenSigner.Create(Rsa)
        else Manager.TokenSigner := TGpAesTokenSigner.Create(Native, T.TokenKey);
        if T.Protocol = gspScp02 then Verifier := TGpReceiptVerifier.CreateDes(Native, T.ReceiptKey, HexToBytes('01020304'))
        else Verifier := TGpReceiptVerifier.CreateAes(Native, T.ReceiptKey, HexToBytes('01020304'));
        Manager.ReceiptVerifier := Verifier; LoadHash := Hash.Sha1(Cap.LoadFileData);
        Before := Script.Calls;
        if Mode = 1 then
        begin
          // Bad DAP is refused before INSTALL or any partial LOAD.
          Rejected := False;
          try Manager.LoadCap(Cap, T.Domain, 40, nil, LoadHash, HexToBytes('E200'));
          except on E: EGpCardError do Rejected := True; end;
          Check(Rejected and (Script.Calls = Before), 'Malformed DAP preflight before mutation');
        end
        else
        begin
          if Mode = 2 then
          begin
            // Return a correctly SCP-authenticated but invalid operation receipt.
            // Command-messaging authentication differs from receipt-key authentication.
            Manager.ReceiptVerifier := TGpReceiptVerifier.CreateAes(Native, T.TokenKey, HexToBytes('01020304'));
          end;
          Rejected := False;
          try Manager.LoadCap(Cap, T.Domain, 40, nil, LoadHash, Dap);
          except on E: ECardCryptoError do Rejected := True; end;
          if Mode = 2 then Check(Rejected and not Manager.Authenticated, 'Invalid final LOAD receipt closes channel')
          else
          begin
            Check(not Rejected and (Verifier.LastCounter = 1), 'Verified final LOAD receipt');
            Manager.InstallApplet(Cap, HexToBytes('A000000151000102'), HexToBytes('A000000151000103'),
              HexToBytes('00'), HexToBytes('0102'));
            Manager.Extradite(HexToBytes('A000000151000103'), T.Domain, HexToBytes('A000000151000001'));
            Manager.DeleteObject(HexToBytes('A000000151000103'), True);
            Check((Verifier.LastCounter = 4) and (Script.Calls = Length(T.Commands)), 'Tokens and all receipt contexts byte exact');
          end;
        end;
      finally Cap.Free; Manager.Free; Transport := nil; end;
    end;
  Writeln('PASS: Native delegated LOAD/DAP/INSTALL/EXTRADITE/DELETE with RSA/AES issuer tokens and verified receipts.');
end;

procedure KeyAdministrationTests;
var List: TTranscripts; T: TTranscript; I, Mode, Before: Integer;
  Native: ICardDesProvider; Fixed: TFixedRandom; Script: TScript; Transport: ICardTransport;
  Manager: TGlobalPlatformCardManager; R: TApduResponse; Lines, Fields: TStringList;
  N, E: TBytes; Info: TGpKeyInformationList; Rejected: Boolean;
begin
{$IFDEF MSWINDOWS}
  Native := TCardWindowsAesProvider.Create;
{$ELSE}
  Native := TCardOpenSslAesProvider.Create;
{$ENDIF}
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.LoadFromFile('tests/globalplatform/fixtures/management-crypto.txt');
    Fields.Delimiter := '|'; Fields.StrictDelimiter := True; Fields.DelimitedText := Lines[0];
    N := HexToBytes(Fields[1]); E := HexToBytes(Fields[2]);
  finally Lines.Free; Fields.Free; end;
  List := LoadTranscripts('tests/globalplatform/fixtures/key-administration.txt');
  Check(Length(List) = 4, 'Four independent RSA provision/key delete sessions');
  for I := 0 to High(List) do
    for Mode := 0 to 1 do
    begin
      T := List[I]; Script := TScript.Create; Transport := Script;
      Script.Commands := T.Commands; Script.Responses := T.Responses;
      Manager := TGlobalPlatformCardManager.Create(nil);
      try
        Fixed := TFixedRandom.Create(Native); Fixed.Host := T.Host;
        Manager.DesProvider := Fixed; Manager.AesProvider := Manager.DesProvider; Manager.Transport := Transport;
        R := Manager.SelectSecurityDomain(T.Domain); Check(R.StatusWord = $9000, 'Key admin select');
        Manager.Authenticate(T.Protocol, T.Keys, 1, 0, T.Level, T.S16);
        Before := Script.Calls; Rejected := False;
        try Manager.PutRsaPublicKey(1, 0, 1, N, E); except on X: EGpCardError do Rejected := True; end;
        Check(Rejected and (Before = Script.Calls) and Manager.Authenticated, 'Key admin local preflight before dispatch');
        if Mode = 1 then Script.FailAt := Length(T.Commands);
        Rejected := False;
        try
          if I mod 2 = 1 then Manager.DeleteKey(2, 1)
          else
          begin
            Info := Manager.ReadKeyInformation;
            Check((Length(Info) = 1) and (Info[0].KeyId = 1), 'Protected key metadata');
            Manager.MakeSelectable(HexToBytes('A000000151000103'), HexToBytes('00'));
            Manager.SetStatus(grkIssuerDomain, T.Domain, 7);
            Manager.PutRsaPublicKey(1, 2, 1, N, E);
          end;
        except on X: Exception do Rejected := True; end;
        Check(Rejected = (Mode <> 0), 'Key admin result');
        Check(not Manager.Authenticated and (Script.Ends = 2), 'Key admin submission always closes');
        Check(Script.Calls = Length(T.Commands), 'Key admin no retry');
      finally Manager.Free; Transport := nil; end;
    end;
  Writeln('PASS: Key information, make selectable, RSA verification-key provision and exact-key deletion.');
end;

begin
  try
{$IFDEF MSWINDOWS}
    Native := TCardWindowsAesProvider.Create;
{$ELSE}
    Native := TCardOpenSslAesProvider.Create;
{$ENDIF}
    All := LoadTranscripts('tests/globalplatform/fixtures/secure-channels.txt'); Check(Length(All) = 154, 'Committed transcript count');
    TranscriptTests(All, Native);
    FullIndex := -1;
    for I := 0 to High(All) do
      if (All[I].Protocol = gspScp03) and (All[I].Level = gslFull) and All[I].S16 and (Length(All[I].Domain) = 0) then FullIndex := I;
    Check(FullIndex >= 0, 'Full S16 fixture');
    FailureTests(All[FullIndex], Native);
    CapTests; ReaderTests; ManagementTests(Native);
    ManagementCryptoTests; KeyUpdateTests; DelegatedManagementTests; KeyAdministrationTests;
    Writeln('PASS: ', Assertions, ' GlobalPlatform assertions.');
  except
    on E: Exception do
    begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
