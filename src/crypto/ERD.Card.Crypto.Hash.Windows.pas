unit ERD.Card.Crypto.Hash.Windows;

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
  /// <summary>Windows CNG or Linux OpenSSL 3 SHA-1 backend, with per-call native handles.</summary>
  TCardWindowsHashProvider = class(TInterfacedObject, ICardHashProvider)
  public
    /// <summary>Hashes bounded borrowed bytes without retaining input or logging data.</summary>
    /// <param name="AData">Zero through one MiB of input.</param>
    /// <returns>Independent twenty-byte SHA-1 digest.</returns>
    /// <exception cref="ECardCryptoError">Platform, bounds or maintained backend fails.</exception>
    function Sha1(const AData: TBytes): TBytes;
  end;

implementation

{$IFDEF MSWINDOWS}
function BCryptOpenAlgorithmProvider(var Handle: Pointer;
  Id, ProviderName: PWideChar; Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptCreateHash(Algorithm: Pointer; var Handle: Pointer;
  HashObject: Pointer; ObjectLength: Cardinal; Secret: Pointer;
  SecretLength, Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptHashData(Handle, Input: Pointer; Count, Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptFinishHash(Handle, Output: Pointer; Count, Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptDestroyHash(Handle: Pointer): LongInt; stdcall; external 'bcrypt.dll';
function BCryptCloseAlgorithmProvider(Handle: Pointer; Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
{$ENDIF}

procedure HashError;
begin
  raise ECardCryptoError.Create('Native SHA-1 operation failed.');
end;

function TCardWindowsHashProvider.Sha1(const AData: TBytes): TBytes;
var
  Input: Pointer;
{$IFDEF MSWINDOWS}
  Algorithm, Hash: Pointer;
{$ENDIF}
begin
  Result := nil;
  if Length(AData) > 1048576 then
    HashError;
  Input := nil;
  if Length(AData) > 0 then
    Input := @AData[0];
  SetLength(Result, 20);
  try
{$IFDEF MSWINDOWS}
    Algorithm := nil;
    Hash := nil;
    try
      if BCryptOpenAlgorithmProvider(Algorithm, 'SHA1', nil, 0) <> 0 then
        HashError;
      if BCryptCreateHash(Algorithm, Hash, nil, 0, nil, 0, 0) <> 0 then
        HashError;
      if Length(AData) > 0 then
        if BCryptHashData(Hash, Input, Length(AData), 0) <> 0 then
          HashError;
      if BCryptFinishHash(Hash, @Result[0], 20, 0) <> 0 then
        HashError;
    finally
      if Hash <> nil then
        BCryptDestroyHash(Hash);
      if Algorithm <> nil then
        BCryptCloseAlgorithmProvider(Algorithm, 0);
    end;
{$ELSE}
    HashError;
{$ENDIF}
  except
    TCardCrypto.Clear(Result);
    raise;
  end;
end;

end.
