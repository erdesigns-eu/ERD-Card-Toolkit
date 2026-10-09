unit ERD.Card.Crypto.OpenSSL;

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
  /// <summary>Optional Linux OpenSSL 3 AES-128/3DES CBC/CSPRNG backend; uses libcrypto.so.3.</summary>
  /// <remarks>Not included in Windows runtime packages. No custom primitive cipher implementation, padding or RNG fallback.
  /// Per-call EVP contexts permit independent concurrent calls; OpenSSL installation/policy is the host's responsibility.</remarks>
  TCardOpenSslAesProvider = class(TInterfacedObject, ICardAesProvider, ICardDesProvider)
  private
    function Crypt(const AKey, AIv, AData: TBytes; const AEncrypt, ADes: Boolean): TBytes;
  public
    /// <summary>Checks OpenSSL 3 availability/version; opens no card or reader.</summary>
    /// <exception cref="ECardCryptoError">Platform or library version is unsupported.</exception>
    constructor Create;
    /// <summary>Encrypts bounded complete blocks without padding and leaves inputs unchanged.</summary>
    /// <param name="AKey">Exactly 16 bytes.</param>
    /// <param name="AIv">Exactly 16 bytes.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Independent exact-length ciphertext.</returns>
    /// <exception cref="ECardCryptoError">Arguments or OpenSSL fail.</exception>
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Decrypts bounded complete blocks without padding and leaves inputs unchanged.</summary>
    /// <param name="AKey">Exactly 16 bytes.</param>
    /// <param name="AIv">Exactly 16 bytes.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Independent exact-length plaintext.</returns>
    /// <exception cref="ECardCryptoError">Arguments or OpenSSL fail.</exception>
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Performs complete-block three-key Triple DES CBC through the maintained native backend.</summary>
    /// <param name="AKey">Exactly 24 borrowed bytes; explicitly expand shorter protocol keys.</param>
    /// <param name="AIv">Exactly eight borrowed bytes.</param>
    /// <param name="AData">Positive multiple of eight, at most one MiB.</param>
    /// <param name="AEncrypt">True encrypts, false decrypts; no padding.</param>
    /// <returns>Owned exact-length native result.</returns>
    /// <exception cref="ECardCryptoError">Bounds, backend policy or native operation fails.</exception>
    function TripleDesCbc(const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
    /// <summary>Uses OpenSSL RAND_bytes, without deterministic fallback.</summary>
    /// <param name="ACount">One through 65536 bytes.</param>
    /// <returns>Independent random bytes.</returns>
    /// <exception cref="ECardCryptoError">Size or OpenSSL CSPRNG fails.</exception>
    function RandomBytes(const ACount: Integer): TBytes;
  end;

implementation

{$IFDEF LINUX}
function OpenSSL_version_num: NativeUInt; cdecl; external 'libcrypto.so.3';
function EVP_CIPHER_CTX_new: Pointer; cdecl; external 'libcrypto.so.3';
procedure EVP_CIPHER_CTX_free(Ctx: Pointer); cdecl; external 'libcrypto.so.3';
function EVP_aes_128_cbc: Pointer; cdecl; external 'libcrypto.so.3';
function EVP_des_ede3_cbc: Pointer; cdecl; external 'libcrypto.so.3';
function EVP_CipherInit_ex(Ctx, Cipher, Engine, Key, Iv: Pointer; Encrypt: Integer): Integer;
  cdecl; external 'libcrypto.so.3';
function EVP_CIPHER_CTX_set_padding(Ctx: Pointer; Padding: Integer): Integer;
  cdecl; external 'libcrypto.so.3';
function EVP_CipherUpdate(Ctx, Output: Pointer; var OutLength: Integer; Input: Pointer;
  InputLength: Integer): Integer; cdecl; external 'libcrypto.so.3';
function EVP_CipherFinal_ex(Ctx, Output: Pointer; var OutLength: Integer): Integer;
  cdecl; external 'libcrypto.so.3';
function RAND_bytes(Buffer: Pointer; Count: Integer): Integer; cdecl; external 'libcrypto.so.3';
{$ENDIF}

procedure CryptoError;
begin raise ECardCryptoError.Create('OpenSSL cryptographic operation failed.'); end;

constructor TCardOpenSslAesProvider.Create;
begin
  inherited Create;
{$IFDEF LINUX}
  if OpenSSL_version_num<$30000000 then CryptoError;
{$ELSE}
  CryptoError;
{$ENDIF}
end;

function TCardOpenSslAesProvider.Crypt(const AKey, AIv, AData: TBytes;
  const AEncrypt, ADes: Boolean): TBytes;
{$IFDEF LINUX}
var Ctx,Cipher: Pointer; Buffer: TBytes; First,Last: Integer;
{$ENDIF}
begin
  Result:=nil;
  if ADes then TCardDesCrypto.ValidateCbc(AKey,AIv,AData) else TCardCrypto.ValidateCbc(AKey,AIv,AData);
{$IFDEF LINUX}
  Ctx:=EVP_CIPHER_CTX_new; if Ctx=nil then CryptoError;
  Buffer:=nil;
  try
    if ADes then Cipher:=EVP_des_ede3_cbc else Cipher:=EVP_aes_128_cbc;
    if Cipher=nil then CryptoError;
    if EVP_CipherInit_ex(Ctx,Cipher,nil,@AKey[0],@AIv[0],Ord(AEncrypt))<>1 then CryptoError;
    if EVP_CIPHER_CTX_set_padding(Ctx,0)<>1 then CryptoError;
    SetLength(Buffer,Length(AData)+16); First:=0; Last:=0;
    if EVP_CipherUpdate(Ctx,@Buffer[0],First,@AData[0],Length(AData))<>1 then CryptoError;
    if (First<0) or (First>Length(AData)) then CryptoError;
    if EVP_CipherFinal_ex(Ctx,@Buffer[First],Last)<>1 then CryptoError;
    if (Last<0) or (First+Last<>Length(AData)) then CryptoError;
    Result:=Copy(Buffer,0,First+Last);
  finally
    TCardCrypto.Clear(Buffer); EVP_CIPHER_CTX_free(Ctx);
  end;
{$ELSE}
  CryptoError;
{$ENDIF}
end;

function TCardOpenSslAesProvider.EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result:=Crypt(AKey,AIv,AData,True,False); end;

function TCardOpenSslAesProvider.DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result:=Crypt(AKey,AIv,AData,False,False); end;

function TCardOpenSslAesProvider.TripleDesCbc(const AKey,AIv,AData:TBytes;const AEncrypt:Boolean):TBytes;
begin Result:=Crypt(AKey,AIv,AData,AEncrypt,True);end;

function TCardOpenSslAesProvider.RandomBytes(const ACount: Integer): TBytes;
begin
  Result:=nil;
  if (ACount<1) or (ACount>65536) then CryptoError;
{$IFDEF LINUX}
  SetLength(Result,ACount);
  if RAND_bytes(@Result[0],ACount)<>1 then begin TCardCrypto.Clear(Result); CryptoError; end;
{$ELSE}
  CryptoError;
{$ENDIF}
end;

end.
