unit ERD.Card.Crypto.Windows;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Crypto, ERD.Card.Crypto.DES;

type
  /// <summary>Windows CNG AES-128/3DES CBC and system CSPRNG backend; requires Windows 7 or later.</summary>
  /// <remarks>Uses the operating system bcrypt.dll, no vendor DLL or custom primitive cipher. Per-call native
  /// handles and independent IV/key copies prevent shared mutable crypto state. No card I/O.</remarks>
  TCardWindowsAesProvider = class(TInterfacedObject, ICardAesProvider, ICardDesProvider)
  private
    function Crypt(const AKey, AIv, AData: TBytes; const AEncrypt, ADes: Boolean): TBytes;
  public
    /// <summary>Creates an inactive provider and rejects non-Windows platforms.</summary>
    /// <exception cref="ECardCryptoError">Platform is unsupported.</exception>
    constructor Create;
    /// <summary>Encrypts complete bounded AES blocks through Windows CNG without padding.</summary>
    /// <param name="AKey">Exactly 16 bytes; copied before native calls.</param>
    /// <param name="AIv">Exactly 16 bytes; native mutation affects only a local copy.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Independent exact-length ciphertext.</returns>
    /// <exception cref="ECardCryptoError">Arguments, native lengths or CNG fail.</exception>
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Decrypts complete bounded AES blocks through Windows CNG without padding.</summary>
    /// <param name="AKey">Exactly 16 bytes; not modified.</param>
    /// <param name="AIv">Exactly 16 bytes; not modified.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Independent exact-length plaintext.</returns>
    /// <exception cref="ECardCryptoError">Arguments, native lengths or CNG fail.</exception>
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Performs complete-block three-key Triple DES CBC through the maintained native backend.</summary>
    /// <param name="AKey">Exactly 24 borrowed bytes; explicitly expand shorter protocol keys.</param>
    /// <param name="AIv">Exactly eight borrowed bytes.</param>
    /// <param name="AData">Positive multiple of eight, at most one MiB.</param>
    /// <param name="AEncrypt">True encrypts, false decrypts; no padding.</param>
    /// <returns>Owned exact-length native result.</returns>
    /// <exception cref="ECardCryptoError">Bounds, backend policy or native operation fails.</exception>
    function TripleDesCbc(const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
    /// <summary>Uses BCryptGenRandom with BCRYPT_USE_SYSTEM_PREFERRED_RNG.</summary>
    /// <param name="ACount">One through 65536 bytes.</param>
    /// <returns>Independent fresh random bytes, without fallback.</returns>
    /// <exception cref="ECardCryptoError">Size or native RNG fails.</exception>
    function RandomBytes(const ACount: Integer): TBytes;
  end;

implementation

{$IFDEF MSWINDOWS}
function BCryptOpenAlgorithmProvider(var Handle: Pointer; Id, ProviderName: PWideChar;
  Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptSetProperty(Handle: Pointer; Name: PWideChar; Input: Pointer;
  Count,Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptGetProperty(Handle: Pointer; Name: PWideChar; Output: Pointer;
  Count: Cardinal; var Received: Cardinal; Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptGenerateSymmetricKey(Algorithm: Pointer; var Key: Pointer; KeyObject: Pointer;
  ObjectCount: Cardinal; Secret: Pointer; SecretCount,Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptEncrypt(Key,Input: Pointer; InputCount: Cardinal; Padding,Iv: Pointer;
  IvCount: Cardinal; Output: Pointer; OutputCount: Cardinal; var Received: Cardinal;
  Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptDecrypt(Key,Input: Pointer; InputCount: Cardinal; Padding,Iv: Pointer;
  IvCount: Cardinal; Output: Pointer; OutputCount: Cardinal; var Received: Cardinal;
  Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptDestroyKey(Key: Pointer): LongInt; stdcall; external 'bcrypt.dll';
function BCryptCloseAlgorithmProvider(Algorithm: Pointer; Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptGenRandom(Algorithm,Output: Pointer; Count,Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
{$ENDIF}

procedure CryptoError;
begin raise ECardCryptoError.Create('Windows CNG cryptographic operation failed.'); end;

constructor TCardWindowsAesProvider.Create;
begin
  inherited Create;
{$IFNDEF MSWINDOWS}
  CryptoError;
{$ENDIF}
end;

function TCardWindowsAesProvider.Crypt(const AKey, AIv, AData: TBytes;
  const AEncrypt, ADes: Boolean): TBytes;
{$IFDEF MSWINDOWS}
var Algorithm,Key: Pointer; ObjectBytes,Secret,Iv,Output: TBytes;
  ObjectLength,Received: Cardinal; Mode,AlgorithmName: UnicodeString; Status: LongInt; Success,CleanupFailed:Boolean;
{$ENDIF}
begin
  Result:=nil;
  if ADes then TCardDesCrypto.ValidateCbc(AKey,AIv,AData) else TCardCrypto.ValidateCbc(AKey,AIv,AData);
{$IFDEF MSWINDOWS}
  Algorithm:=nil; Key:=nil; ObjectBytes:=nil; Secret:=Copy(AKey,0,Length(AKey));
  Iv:=Copy(AIv,0,Length(AIv)); Output:=nil; Success:=False;
  try
    if ADes then AlgorithmName:='3DES' else AlgorithmName:='AES';
    if BCryptOpenAlgorithmProvider(Algorithm,PWideChar(AlgorithmName),nil,0)<0 then CryptoError;
    Mode:='ChainingModeCBC';
    if BCryptSetProperty(Algorithm,'ChainingMode',PWideChar(Mode),(Length(Mode)+1)*SizeOf(WideChar),0)<0 then CryptoError;
    ObjectLength:=0; Received:=0;
    if BCryptGetProperty(Algorithm,'ObjectLength',@ObjectLength,SizeOf(ObjectLength),Received,0)<0 then CryptoError;
    if (Received<>SizeOf(ObjectLength)) or (ObjectLength<1) or (ObjectLength>65536) then CryptoError;
    SetLength(ObjectBytes,ObjectLength);
    if BCryptGenerateSymmetricKey(Algorithm,Key,@ObjectBytes[0],ObjectLength,@Secret[0],Length(Secret),0)<0 then CryptoError;
    SetLength(Output,Length(AData)); Received:=0;
    if AEncrypt then
      Status:=BCryptEncrypt(Key,@AData[0],Length(AData),nil,@Iv[0],Length(Iv),@Output[0],Length(Output),Received,0)
    else
      Status:=BCryptDecrypt(Key,@AData[0],Length(AData),nil,@Iv[0],Length(Iv),@Output[0],Length(Output),Received,0);
    if (Status<0) or (Received<>Cardinal(Length(AData))) then CryptoError;
    Result:=Copy(Output,0,Length(Output)); Success:=True;
  finally
    CleanupFailed:=False;
    if Key<>nil then CleanupFailed:=BCryptDestroyKey(Key)<0;
    if Algorithm<>nil then if BCryptCloseAlgorithmProvider(Algorithm,0)<0 then CleanupFailed:=True;
    TCardCrypto.Clear(ObjectBytes); TCardCrypto.Clear(Secret); TCardCrypto.Clear(Iv); TCardCrypto.Clear(Output);
    if Success and CleanupFailed then begin TCardCrypto.Clear(Result); CryptoError; end;
  end;
{$ELSE}
  CryptoError;
{$ENDIF}
end;

function TCardWindowsAesProvider.EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result:=Crypt(AKey,AIv,AData,True,False); end;

function TCardWindowsAesProvider.DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result:=Crypt(AKey,AIv,AData,False,False); end;

function TCardWindowsAesProvider.TripleDesCbc(const AKey,AIv,AData:TBytes;const AEncrypt:Boolean):TBytes;
begin Result:=Crypt(AKey,AIv,AData,AEncrypt,True);end;

function TCardWindowsAesProvider.RandomBytes(const ACount: Integer): TBytes;
begin
  Result:=nil; if (ACount<1) or (ACount>65536) then CryptoError;
{$IFDEF MSWINDOWS}
  SetLength(Result,ACount);
  if BCryptGenRandom(nil,@Result[0],ACount,2)<0 then begin TCardCrypto.Clear(Result); CryptoError; end;
{$ELSE}
  CryptoError;
{$ENDIF}
end;

end.
