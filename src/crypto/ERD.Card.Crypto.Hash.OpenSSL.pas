unit ERD.Card.Crypto.Hash.OpenSSL;

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
  ERD.Card.Crypto, ERD.Card.Crypto.Hash;

type
  /// <summary>Linux OpenSSL 3 SHA-1 backend, with per-call native handles.</summary>
  TCardOpenSSLHashProvider = class(TInterfacedObject, ICardHashProvider)
  public
    /// <summary>Hashes bounded borrowed bytes without retaining input or logging data.</summary>
    /// <param name="AData">Zero through one MiB of input.</param>
    /// <returns>Independent twenty-byte SHA-1 digest.</returns>
    /// <exception cref="ECardCryptoError">Platform, bounds or maintained backend fails.</exception>
    function Sha1(const AData: TBytes): TBytes;
  end;

implementation

{$IFDEF LINUX}
function EVP_Q_digest(Context: Pointer; Name, Properties: PAnsiChar;
  Data: Pointer; DataLength: NativeUInt; Output: Pointer;
  var OutputLength: NativeUInt): Integer; cdecl; external 'libcrypto.so.3';
{$ENDIF}

procedure HashError;
begin
  raise ECardCryptoError.Create('Native SHA-1 operation failed.');
end;

function TCardOpenSSLHashProvider.Sha1(const AData: TBytes): TBytes;
{$IFDEF LINUX}
var
  Input: Pointer;
  Count: NativeUInt;
{$ENDIF}

begin
  Result := nil;
  if Length(AData) > 1048576 then
    HashError;
{$IFDEF LINUX}
  Input := nil;
  if Length(AData) > 0 then
    Input := @AData[0];
{$ENDIF}
  SetLength(Result, 20);
  try
{$IFDEF LINUX}
    Count := 0;
    if EVP_Q_digest(nil, 'SHA1', nil, Input, Length(AData), @Result[0], Count) <> 1 then
      HashError;
    if Count <> 20 then
      HashError;
{$ELSE}
    HashError;
{$ENDIF}
  except
    TCardCrypto.Clear(Result);
    raise;
  end;
end;

end.
