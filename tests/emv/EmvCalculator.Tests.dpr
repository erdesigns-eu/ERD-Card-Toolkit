program EmvCalculatorTests;

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
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.DES,
  ERD.Card.EMV.Calculator, ERD.Card.Crypto.Hash,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Hash.Windows, ERD.Card.Crypto.Windows;
{$ELSE}
  ERD.Card.Crypto.Hash.OpenSSL, ERD.Card.Crypto.OpenSSL;
{$ENDIF}

type
  TProviderSpy = class(TInterfacedObject, ICardAesProvider, ICardDesProvider)
  private
    FBase: ICardDesProvider;
  public
    Calls: Integer;
    FailAt: Integer;
    WrongSize: Boolean;
    constructor Create(const ABase: ICardDesProvider);
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function RandomBytes(const ACount: Integer): TBytes;
    function TripleDesCbc(const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
  end;

  TBadHash = class(TInterfacedObject, ICardHashProvider)
  public
    function Sha1(const AData: TBytes): TBytes;
  end;

constructor TProviderSpy.Create(const ABase: ICardDesProvider);
begin
  inherited Create;
  FBase := ABase;
end;

function TProviderSpy.EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin
  Result := FBase.EncryptCbc(AKey, AIv, AData);
end;

function TProviderSpy.DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin
  Result := FBase.DecryptCbc(AKey, AIv, AData);
end;

function TProviderSpy.RandomBytes(const ACount: Integer): TBytes;
begin
  Result := nil;
  raise ECardCryptoError.Create('No random bytes needed for calculations.');
end;

function TProviderSpy.TripleDesCbc(const AKey, AIv, AData: TBytes;
  const AEncrypt: Boolean): TBytes;
begin
  Inc(Calls);
  if Calls = FailAt then
    raise ECardCryptoError.Create('Injected primitive failure.');
  if WrongSize then
  begin
    Result := nil;
    SetLength(Result, Length(AData) - 1);
  end
  else
    Result := FBase.TripleDesCbc(AKey, AIv, AData, AEncrypt);
end;

function TBadHash.Sha1(const AData: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, 19);
end;

var
  Assertions: Integer;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Assertions);
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function DecodeFields(const AData: TBytes): TEmvCryptogramData;
begin
  Result := Default(TEmvCryptogramData);
  Check(Length(AData) = 33, 'Fixture common-field length');
  Result.AmountAuthorized := Copy(AData, 0, 6);
  Result.AmountOther := Copy(AData, 6, 6);
  Result.TerminalCountry := Copy(AData, 12, 2);
  Result.TerminalVerificationResults := Copy(AData, 14, 5);
  Result.Currency := Copy(AData, 19, 2);
  Result.TransactionDate := Copy(AData, 21, 3);
  Result.TransactionType := Copy(AData, 24, 1);
  Result.UnpredictableNumber := Copy(AData, 25, 4);
  Result.ApplicationInterchangeProfile := Copy(AData, 29, 2);
  Result.Atc := Copy(AData, 31, 2);
end;

procedure VectorTests(const ACalculator: TEmvCalculator);
var
  Lines, Columns, TreeParameters: TStringList;
  I, ProfileNumber, Vectors: Integer;
  Operation: string;
  Key, A, B, C, Actual, Expected, Original: TBytes;
  Profile: TEmvCryptogramProfile;
  Data: TEmvCryptogramData;
begin
  Lines := TStringList.Create;
  Columns := TStringList.Create;
  TreeParameters := TStringList.Create;
  try
    Lines.LoadFromFile('tests/emv/fixtures/calculators.txt');
    Columns.Delimiter := '|';
    Columns.StrictDelimiter := True;
    TreeParameters.Delimiter := ',';
    TreeParameters.StrictDelimiter := True;
    Vectors := 0;
    for I := 0 to Lines.Count - 1 do
    begin
      if (Lines[I] = '') or (Lines[I][1] = '#') then
        Continue;
      Columns.DelimitedText := Lines[I];
      Check(Columns.Count = 6, 'Fixture column count');
      Operation := Columns[0];
      Key := HexToBytes(Columns[1]);
      Original := CopyBytes(Key);
      Expected := HexToBytes(Columns[5]);
      Actual := nil;
      if (Operation = 'UDKA') or (Operation = 'UDKB') then
      begin
        if Operation = 'UDKA' then
          Actual := ACalculator.DeriveMasterKey(Key, Columns[2], Columns[3], emkOptionA)
        else
          Actual := ACalculator.DeriveMasterKey(Key, Columns[2], Columns[3], emkOptionB);
        Check(TEmvCalculator.HasOddParity(Actual), 'Derived master-key parity');
      end
      else if Operation = 'PIN2' then
        Actual := TEmvCalculator.FormatPinBlock2(Columns[2])
      else if Operation = 'PINVISA' then
        Actual := TEmvCalculator.FormatVisaPinBlock(Key, Columns[2], Columns[3])
      else
      begin
        A := HexToBytes(Columns[2]);
        B := HexToBytes(Columns[3]);
        if Copy(Operation, 1, 7) = 'PROFILE' then
        begin
          if Copy(Operation, 1, 12) = 'PROFILE_ARPC' then
          begin
            ProfileNumber := StrToInt(Copy(Operation, 13, 2));
            Profile := TEmvCryptogramProfile(ProfileNumber);
            if Profile in [ecpVisa18, ecpVisa22] then
              Actual := ACalculator.ProfileArpc2(Profile, Key, Copy(A, 0, 2), B,
                HexToBytes('00000000'), nil)
            else
              Actual := ACalculator.ProfileArpc1(Profile, Key, Copy(A, 0, 2),
                Copy(A, 2, 4), B, HexToBytes('0000'));
          end
          else
          begin
            ProfileNumber := StrToInt(Copy(Operation, 8, 2));
            Profile := TEmvCryptogramProfile(ProfileNumber);
            Data := DecodeFields(A);
            if Profile in [ecpVisa18, ecpVisa22, ecpInterac133] then
              Data.IssuerApplicationData := B
            else
              Data.CardVerificationResults := B;
            Data.Counters := HexToBytes(Columns[4]);
            Actual := ACalculator.ProfileCryptogram(Profile, Key, Data);
          end;
        end
        else if Operation = 'COMMON' then
          Actual := ACalculator.DeriveCommonSessionKey(Key, A)
        else if Operation = 'ATC' then
          Actual := ACalculator.DeriveAtcSessionKey(Key, A)
        else if Operation = 'MC' then
          Actual := ACalculator.DeriveMastercardSessionKey(Key, A, B)
        else if Operation = 'VISA' then
          Actual := ACalculator.DeriveVisaScriptKey(Key, A)
        else if Operation = 'TREE' then
        begin
          TreeParameters.DelimitedText := Columns[4];
          Actual := ACalculator.DeriveTreeSessionKey(Key, A, B,
            StrToInt(TreeParameters[0]), StrToInt(TreeParameters[1]));
        end
        else if (Operation = 'AC1') or (Operation = 'AC2') then
        begin
          if Operation = 'AC1' then
            Actual := ACalculator.ApplicationCryptogram(Key, A, empMethod1)
          else
            Actual := ACalculator.ApplicationCryptogram(Key, A, empMethod2);
          if Operation = 'AC2' then
          begin
            Check(ACalculator.VerifyApplicationCryptogram(Key, A, Expected, empMethod2), 'Valid AC verification');
            Expected[7] := Expected[7] xor 1;
            Check(not ACalculator.VerifyApplicationCryptogram(Key, A, Expected, empMethod2), 'Modified AC verification');
            Expected[7] := Expected[7] xor 1;
          end;
        end
        else if Operation = 'ARPC1' then
        begin
          Actual := ACalculator.ArpcMethod1(Key, A, B);
          Check(ACalculator.VerifyArpcMethod1(Key, A, B, Expected), 'ARPC one verification');
          Expected[7] := Expected[7] xor 1;
          Check(not ACalculator.VerifyArpcMethod1(Key, A, B, Expected), 'Modified ARPC one verification');
          Expected[7] := Expected[7] xor 1;
        end
        else if Operation = 'ARPC2' then
        begin
          C := HexToBytes(Columns[4]);
          Actual := ACalculator.ArpcMethod2(Key, A, B, C);
          Check(ACalculator.VerifyArpcMethod2(Key, A, B, C, Expected), 'ARPC two verification');
          Expected[3] := Expected[3] xor 1;
          Check(not ACalculator.VerifyArpcMethod2(Key, A, B, C, Expected), 'Modified ARPC two verification');
          Expected[3] := Expected[3] xor 1;
        end
        else if Operation = 'KCV' then
          Actual := ACalculator.KeyCheckValue(Key, 8)
        else if Operation = 'PARITY' then
          Actual := TEmvCalculator.AdjustOddParity(Key)
        else if Operation = 'CMAC' then
          Actual := ACalculator.AesCmac(Key, A)
        else if Operation = 'HASH' then
          Actual := ACalculator.HashProvider.Sha1(A)
        else if Operation = 'SCRIPTMAC' then
          Actual := ACalculator.ScriptMac(Key, A)
        else if Operation = 'SCRIPT_VISA' then
          Actual := ACalculator.EncryptScriptData(Key, A, eseVisa)
        else if Operation = 'SCRIPT_MC' then
          Actual := ACalculator.EncryptScriptData(Key, A, eseMastercard)
        else if Operation = 'SCRIPT_EMV' then
          Actual := ACalculator.EncryptScriptData(Key, A, eseEmv)
        else
          raise Exception.Create('Unknown fixture operation');
      end;
      Check(BytesEqual(Actual, Expected), 'Independent vector mismatch at row ' + IntToStr(I + 1) + ': ' + Operation);
      Check(BytesEqual(Key, Original), 'Input key modified');
      Inc(Vectors);
    end;
    Check(Vectors = 2695, 'Independent vector count');
    Writeln('PASS: ', Vectors, ' independent EMV calculation vectors, including all eight CVN profiles.');
  finally
    Lines.Free;
    Columns.Free;
    TreeParameters.Free;
  end;
end;

procedure BoundaryTests(const ACalculator: TEmvCalculator);
var
  I: Integer;
  Key, Data, ResultBytes: TBytes;
  Failed: Boolean;
  Fields: TEmvCryptogramData;
begin
  Key := HexToBytes('0123456789ABCDEFFEDCBA9876543210');
  Check(BytesToHex(TEmvCalculator.Pad(nil, empMethod1)) = '0000000000000000', 'Method one empty');
  Check(BytesToHex(TEmvCalculator.Pad(nil, empMethod2)) = '8000000000000000', 'Method two empty');
  Check(Length(TEmvCalculator.Pad(Key, empMethod1)) = 16, 'Method one aligned');
  Check(Length(TEmvCalculator.Pad(Key, empMethod2)) = 24, 'Method two aligned extra block');
  Check(BytesToHex(ACalculator.AesKeyCheckValue(HexToBytes('00000000000000000000000000000000'))) = '66E94B', 'NIST AES encrypted-zero KCV');
  for I := 0 to 31 do
    if I <> 16 then
    begin
      Data := nil;
      SetLength(Data, I);
      Failed := False;
      try
        ResultBytes := ACalculator.DeriveMasterKey(Data, '1234567890123456', '00', emkOptionA);
      except
        on EEmvCalculationError do Failed := True;
      end;
      Check(Failed, 'Master-key length bound');
    end;
  for I := 0 to 15 do
  begin
    Failed := False;
    try
      case I of
        0: ResultBytes := ACalculator.DeriveMasterKey(Key, '', '00', emkOptionA);
        1: ResultBytes := ACalculator.DeriveMasterKey(Key, '1234F678', '00', emkOptionA);
        2: ResultBytes := ACalculator.DeriveMasterKey(Key, '12345678', '0', emkOptionA);
        3: ResultBytes := ACalculator.DeriveMasterKey(Key, '12345678901234567890', '00', emkOptionA);
        4: ResultBytes := ACalculator.DeriveAtcSessionKey(Key, nil);
        5: ResultBytes := ACalculator.DeriveCommonSessionKey(Key, Key);
        6: ResultBytes := ACalculator.KeyCheckValue(Key, 0);
        7: ResultBytes := ACalculator.RetailMac(Key, nil, empMethod2, 9);
        8: ResultBytes := ACalculator.ArpcMethod1(Key, Key, nil);
        9: ResultBytes := ACalculator.ArpcMethod2(Key, Copy(Key, 0, 8), Copy(Key, 0, 4), Key);
        10: ResultBytes := TEmvCalculator.FormatPinBlock2('12A4');
        11: ResultBytes := TEmvCalculator.FormatPinBlock2('123');
        12: ResultBytes := ACalculator.DeriveTreeSessionKey(Key, Copy(Key, 0, 2), Key, 2, 4);
        13: ResultBytes := ACalculator.ProfileArpc1(ecpVisa18, Key, nil, nil, nil, nil);
        14: ResultBytes := ACalculator.ProfileArpc2(ecpMastercard16, Key, nil, nil, nil, nil);
        15: ResultBytes := ACalculator.AesCmac(Key, nil, 17);
      end;
    except
      on EEmvCalculationError do Failed := True;
    end;
    Check(Failed, 'Invalid calculation refused: ' + IntToStr(I));
  end;
  Fields := DecodeFields(HexToBytes('0000000099990000000000000840800004800008409912310152BF458518000FFF'));
  Fields.CardVerificationResults := HexToBytes('01020304');
  Fields.AmountAuthorized[0] := $FA;
  Failed := False;
  try
    ResultBytes := ACalculator.ProfileCryptogram(ecpVisa10, Key, Fields);
  except
    on EEmvCalculationError do Failed := True;
  end;
  Check(Failed, 'Numeric profile field validation');
  Data := nil;
  SetLength(Data, EmvCalculatorMaxData + 1);
  Failed := False;
  try
    ResultBytes := TEmvCalculator.Pad(Data, empMethod2);
  except
    on EEmvCalculationError do Failed := True;
  end;
  Check(Failed, 'Bounded padding allocation');
  SetLength(Data, 256);
  Failed := False;
  try
    ResultBytes := ACalculator.EncryptScriptData(Key, Data, eseVisa);
  except
    on EEmvCalculationError do Failed := True;
  end;
  Check(Failed, 'Visa length prefix bounded to one byte');
  ACalculator.DesProvider := nil;
  Failed := False;
  try
    ResultBytes := ACalculator.ApplicationCryptogram(Key, nil, empMethod2);
  except
    on ECardCryptoError do Failed := True;
  end;
  Check(Failed, 'Missing backend cannot produce a cryptogram');
  ResultBytes := ACalculator.AesKeyCheckValue(Key, 1);
  Check(Length(ResultBytes) = 1, 'AES remains available independently of DES');
  Writeln('PASS: EMV bounds, profile validation, empty/aligned padding and absent providers.');
end;

procedure ProviderFailureTests(const ACalculator: TEmvCalculator);
var
  Saved, Broken: ICardDesProvider;
  SavedHash: ICardHashProvider;
  Spy: TProviderSpy;
  Key, Original, Data, Actual: TBytes;
  I: Integer;
  Failed: Boolean;
begin
  Saved := ACalculator.DesProvider;
  SavedHash := ACalculator.HashProvider;
  Spy := TProviderSpy.Create(Saved);
  Broken := Spy;
  Key := HexToBytes('0123456789ABCDEFFEDCBA9876543210');
  Original := CopyBytes(Key);
  Data := HexToBytes('01020304050607080910111213141516');
  try
    ACalculator.DesProvider := Broken;
    for I := 1 to 3 do
    begin
      Spy.Calls := 0;
      Spy.FailAt := I;
      Failed := False;
      try
        Actual := ACalculator.ApplicationCryptogram(Key, Data, empMethod2);
      except
        on ECardCryptoError do Failed := True;
      end;
      Check(Failed and (Spy.Calls = I), 'Primitive failure is surfaced without retry');
      Check(BytesEqual(Key, Original), 'Borrowed key preserved on primitive failure');
    end;
    Spy.FailAt := 0;
    Spy.WrongSize := True;
    Failed := False;
    try
      Actual := ACalculator.DeriveCommonSessionKey(Key, Copy(Data, 0, 8));
    except
      on ECardCryptoError do Failed := True;
    end;
    Check(Failed, 'Malformed primitive output length refused');
    ACalculator.HashProvider := TBadHash.Create;
    Failed := False;
    try
      Actual := ACalculator.DeriveMasterKey(Key, '1234567890123456789', '00', emkOptionB);
    except
      on ECardCryptoError do Failed := True;
    end;
    Check(Failed, 'Malformed SHA-1 result refused');
    ACalculator.HashProvider := nil;
    Failed := False;
    try
      Actual := ACalculator.DeriveMasterKey(Key, '1234567890123456789', '00', emkOptionB);
    except
      on ECardCryptoError do Failed := True;
    end;
    Check(Failed, 'Option B long PAN requires a hash provider');
    ACalculator.DesProvider := Saved;
    Actual := ACalculator.DeriveMasterKey(Key, '1234567890123456', '00', emkOptionB);
    Check(Length(Actual) = 16, 'Short Option B uses Option A without SHA-1 dependency');
  finally
    ACalculator.DesProvider := Saved;
    ACalculator.HashProvider := SavedHash;
  end;
  Writeln('PASS: Primitive failures, output-size contracts, no retries and optional SHA-1 capability.');
end;

var
  Calculator: TEmvCalculator;
  Provider: ICardDesProvider;
begin
  try
    Calculator := TEmvCalculator.Create(nil);
    try
{$IFDEF MSWINDOWS}
      Provider := TCardWindowsAesProvider.Create;
{$ELSE}
      Provider := TCardOpenSslAesProvider.Create;
{$ENDIF}
      Calculator.DesProvider := Provider;
      Calculator.AesProvider := Provider;
{$IFDEF MSWINDOWS}
      Calculator.HashProvider := TCardWindowsHashProvider.Create;
{$ELSE}
      Calculator.HashProvider := TCardOpenSslHashProvider.Create;
{$ENDIF}
      VectorTests(Calculator);
      ProviderFailureTests(Calculator);
      BoundaryTests(Calculator);
    finally
      Calculator.Free;
    end;
    Writeln('PASS: ', Assertions, ' EMV calculator assertions.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
