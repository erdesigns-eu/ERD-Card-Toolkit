unit ERD.Card.Crypto.RSA.Native;

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
  ERD.Card.Crypto, ERD.Card.Crypto.Hash, ERD.Card.Crypto.RSA;

type
  /// <summary>Native CNG on Windows or OpenSSL 3 on Linux RSA signer; no GlobalPlatform DLL.</summary>
  /// <remarks>Keys are explicit unsigned big-endian integers. Per-call native handles are released.
  /// Private copies are cleared on destruction; caller must clear its own copies.</remarks>
  TCardNativeRsaProvider = class(TInterfacedObject, ICardRsaProvider)
  private
    FHash: ICardHashProvider;
    FN, FE, FD, FP, FQ: TBytes;
    function Process(const AData, ASignature: TBytes; const ASign: Boolean): TBytes;
  public
    /// <summary>Creates an inactive provisioned RSA provider without opening native handles.</summary>
    /// <param name="AHash">Maintained SHA-1 provider for this explicitly selected GP signature profile.</param>
    /// <param name="AModulus">Unsigned big-endian 1024- through 4096-bit modulus, top bit set.</param>
    /// <param name="AExponent">Unsigned big-endian public exponent, one through eight bytes, odd.</param>
    /// <param name="APrivateExponent">Private exponent, required for Linux signing; nil for public verification.</param>
    /// <param name="APrime1">First RSA prime, half modulus width; required for Windows signing.</param>
    /// <param name="APrime2">Second RSA prime, half modulus width; required for Windows signing.</param>
    constructor Create(const AHash: ICardHashProvider; const AModulus, AExponent: TBytes;
      const APrivateExponent: TBytes = nil; const APrime1: TBytes = nil;
      const APrime2: TBytes = nil);
    /// <summary>Clears all owned integer buffers and releases the retained hash interface.</summary>
    destructor Destroy; override;
    /// <summary>Signs explicit data using native RSA PKCS#1 v1.5 and SHA-1.</summary>
    /// <param name="AData">Zero through one MiB; never retained or logged.</param>
    /// <returns>Owned modulus-sized signature; raises ECardCryptoError for missing private key/backend failure.</returns>
    function SignSha1(const AData: TBytes): TBytes;
    /// <summary>Verifies an explicit RSA PKCS#1 v1.5 SHA-1 signature.</summary>
    /// <param name="AData">Exact signed bytes, zero through one MiB.</param>
    /// <param name="ASignature">Signature; wrong size or signature returns false.</param>
    /// <returns>True only after native signature verification.</returns>
    function VerifySha1(const AData, ASignature: TBytes): Boolean;
  end;

implementation

uses ERD.Card.Bytes;

{$IFDEF MSWINDOWS}
function BCryptOpenAlgorithmProvider(var H: Pointer; Id, ProviderName: PWideChar;
  Flags: Cardinal): LongInt; stdcall; external 'bcrypt.dll';
function BCryptCloseAlgorithmProvider(H: Pointer; Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptImportKeyPair(Algorithm, ImportKey: Pointer; BlobType: PWideChar;
  var Key: Pointer; Input: Pointer; Count, Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptDestroyKey(Key: Pointer): LongInt; stdcall; external 'bcrypt.dll';
function BCryptSignHash(Key, PaddingInfo, Input: Pointer; Count: Cardinal;
  Output: Pointer; OutputSize: Cardinal; var Actual: Cardinal; Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
function BCryptVerifySignature(Key, PaddingInfo, Input: Pointer; Count: Cardinal;
  Signature: Pointer; SignatureSize, Flags: Cardinal): LongInt;
  stdcall; external 'bcrypt.dll';
{$ENDIF}
{$IFDEF LINUX}
function BN_bin2bn(Data: Pointer; Count: Integer; Existing: Pointer): Pointer;
  cdecl; external 'libcrypto.so.3';
function BN_secure_new: Pointer; cdecl; external 'libcrypto.so.3';
procedure BN_clear_free(B: Pointer); cdecl; external 'libcrypto.so.3';
function OSSL_PARAM_BLD_new: Pointer; cdecl; external 'libcrypto.so.3';
procedure OSSL_PARAM_BLD_free(B: Pointer); cdecl; external 'libcrypto.so.3';
function OSSL_PARAM_BLD_push_BN(B: Pointer; Name: PAnsiChar; N: Pointer): Integer;
  cdecl; external 'libcrypto.so.3';
function OSSL_PARAM_BLD_to_param(B: Pointer): Pointer; cdecl; external 'libcrypto.so.3';
procedure OSSL_PARAM_free(P: Pointer); cdecl; external 'libcrypto.so.3';
function EVP_PKEY_CTX_new_from_name(C: Pointer; Name, Properties: PAnsiChar): Pointer;
  cdecl; external 'libcrypto.so.3';
function EVP_PKEY_fromdata_init(C: Pointer): Integer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_fromdata(C: Pointer; var Key: Pointer; Selection: Integer; Params: Pointer): Integer;
  cdecl; external 'libcrypto.so.3';
procedure EVP_PKEY_free(Key: Pointer); cdecl; external 'libcrypto.so.3';
procedure EVP_PKEY_CTX_free(C: Pointer); cdecl; external 'libcrypto.so.3';
function EVP_PKEY_CTX_new_from_pkey(C, Key: Pointer; Properties: PAnsiChar): Pointer;
  cdecl; external 'libcrypto.so.3';
function EVP_PKEY_sign_init(C: Pointer): Integer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_verify_init(C: Pointer): Integer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_CTX_set_rsa_padding(C: Pointer; Padding: Integer): Integer;
  cdecl; external 'libcrypto.so.3';
function EVP_sha1: Pointer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_CTX_set_signature_md(C, Md: Pointer): Integer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_sign(C, Signature: Pointer; var Size: NativeUInt;
  Digest: Pointer; DigestSize: NativeUInt): Integer; cdecl; external 'libcrypto.so.3';
function EVP_PKEY_verify(C, Signature: Pointer; Size: NativeUInt;
  Digest: Pointer; DigestSize: NativeUInt): Integer; cdecl; external 'libcrypto.so.3';
{$ENDIF}

procedure Invalid;
begin
  raise ECardCryptoError.Create('Native RSA operation failed.');
end;

constructor TCardNativeRsaProvider.Create(const AHash: ICardHashProvider;
  const AModulus, AExponent, APrivateExponent, APrime1, APrime2: TBytes);
begin
  inherited Create;
  if (AHash = nil) or not ((Length(AModulus) in [128, 192]) or (Length(AModulus) = 256) or
    (Length(AModulus) = 384) or (Length(AModulus) = 512)) or
    (AModulus[0] < $80) or (Length(AExponent) < 1) or (Length(AExponent) > 8) then Invalid;
  if (AExponent[0] = 0) or (AExponent[High(AExponent)] and 1 = 0) or
    ((Length(AExponent) = 1) and (AExponent[0] < 3)) then Invalid;
  if (Length(APrivateExponent) > Length(AModulus)) or
    ((Length(APrime1) <> 0) and (Length(APrime1) <> Length(AModulus) div 2)) or
    (Length(APrime1) <> Length(APrime2)) then Invalid;
  FHash := AHash; FN := CopyBytes(AModulus); FE := CopyBytes(AExponent);
  FD := CopyBytes(APrivateExponent); FP := CopyBytes(APrime1); FQ := CopyBytes(APrime2);
end;

destructor TCardNativeRsaProvider.Destroy;
begin
  TCardCrypto.Clear(FN); TCardCrypto.Clear(FE); TCardCrypto.Clear(FD);
  TCardCrypto.Clear(FP); TCardCrypto.Clear(FQ);
  inherited Destroy;
end;

function TCardNativeRsaProvider.Process(const AData, ASignature: TBytes;
  const ASign: Boolean): TBytes;
var
  Digest: TBytes;
{$IFDEF MSWINDOWS}
  Algorithm, Key: Pointer;
  Blob: TBytes;
  Padding: PWideChar;
  N, Posn: Integer;
  Actual: Cardinal;
  Status: LongInt;
  procedure U32(const V: Cardinal);
  begin
    Blob[Posn] := V and $FF; Blob[Posn + 1] := (V shr 8) and $FF;
    Blob[Posn + 2] := (V shr 16) and $FF; Blob[Posn + 3] := (V shr 24) and $FF;
    Inc(Posn, 4);
  end;
  procedure Bytes(const B: TBytes);
  begin
    if Length(B) > 0 then Move(B[0], Blob[Posn], Length(B));
    Inc(Posn, Length(B));
  end;
{$ENDIF}
{$IFNDEF MSWINDOWS}
{$IFDEF LINUX}
  Builder, Params, ImportContext, Key, Context: Pointer;
  Bn: array[0..4] of Pointer;
  Count: NativeUInt;
  I, Selection, Status: Integer;
  procedure Param(const Index: Integer; const Name: PAnsiChar; const B: TBytes);
  begin
    if Length(B) = 0 then Exit;
    if Index >= 2 then
    begin
      Bn[Index] := BN_secure_new;
      if Bn[Index] = nil then Invalid;
      if BN_bin2bn(@B[0], Length(B), Bn[Index]) = nil then Invalid;
    end
    else Bn[Index] := BN_bin2bn(@B[0], Length(B), nil);
    if (Bn[Index] = nil) or (OSSL_PARAM_BLD_push_BN(Builder, Name, Bn[Index]) <> 1) then Invalid;
  end;
{$ENDIF}
{$ENDIF}
begin
  Result := nil; Digest := nil;
  if (Length(AData) > 1048576) then Invalid;
  if not ASign and (Length(ASignature) <> Length(FN)) then Exit;
  Digest := FHash.Sha1(AData);
  try
    if Length(Digest) <> 20 then Invalid;
{$IFDEF MSWINDOWS}
    Algorithm := nil; Key := nil; Blob := nil;
    try
      if ASign and (Length(FP) = 0) then Invalid;
      N := 24 + Length(FE) + Length(FN);
      if ASign then Inc(N, Length(FP) + Length(FQ));
      SetLength(Blob, N); Posn := 0;
      if ASign then U32($32415352) else U32($31415352);
      U32(Length(FN) * 8); U32(Length(FE)); U32(Length(FN));
      if ASign then begin U32(Length(FP)); U32(Length(FQ)); end
      else begin U32(0); U32(0); end;
      Bytes(FE); Bytes(FN);
      if ASign then begin Bytes(FP); Bytes(FQ); end;
      if BCryptOpenAlgorithmProvider(Algorithm, 'RSA', nil, 0) <> 0 then Invalid;
      if ASign then Padding := 'RSAPRIVATEBLOB' else Padding := 'RSAPUBLICBLOB';
      if BCryptImportKeyPair(Algorithm, nil, Padding, Key, @Blob[0], Length(Blob), 0) <> 0 then Invalid;
      Padding := 'SHA1';
      if ASign then
      begin
        SetLength(Result, Length(FN)); Actual := 0;
        if BCryptSignHash(Key, @Padding, @Digest[0], 20, @Result[0], Length(Result), Actual, 2) <> 0 then Invalid;
        if Actual <> Cardinal(Length(FN)) then Invalid;
      end
      else
      begin
        Status := BCryptVerifySignature(Key, @Padding, @Digest[0], 20,
          @ASignature[0], Length(ASignature), 2);
        if Status = 0 then begin SetLength(Result, 1); Result[0] := 1; end
        else if Cardinal(Status) <> $C000A000 then Invalid;
      end;
    finally
      if Key <> nil then BCryptDestroyKey(Key);
      if Algorithm <> nil then BCryptCloseAlgorithmProvider(Algorithm, 0);
      TCardCrypto.Clear(Blob);
    end;
{$ELSE}
{$IFDEF LINUX}
    Builder := nil; Params := nil; ImportContext := nil; Key := nil; Context := nil;
    for I := 0 to 4 do Bn[I] := nil;
    try
      if ASign and (Length(FD) = 0) then Invalid;
      Builder := OSSL_PARAM_BLD_new;
      if Builder = nil then Invalid;
      Param(0, 'n', FN); Param(1, 'e', FE);
      if ASign then begin Param(2, 'd', FD); Param(3, 'rsa-factor1', FP); Param(4, 'rsa-factor2', FQ); end;
      Params := OSSL_PARAM_BLD_to_param(Builder);
      if Params = nil then Invalid;
      ImportContext := EVP_PKEY_CTX_new_from_name(nil, 'RSA', nil);
      if ImportContext = nil then Invalid;
      if EVP_PKEY_fromdata_init(ImportContext) <> 1 then Invalid;
      Selection := $86; if ASign then Selection := $87;
      if EVP_PKEY_fromdata(ImportContext, Key, Selection, Params) <> 1 then Invalid;
      Context := EVP_PKEY_CTX_new_from_pkey(nil, Key, nil);
      if Context = nil then Invalid;
      if ASign then Status := EVP_PKEY_sign_init(Context) else Status := EVP_PKEY_verify_init(Context);
      if Status <> 1 then Invalid;
      if EVP_PKEY_CTX_set_rsa_padding(Context, 1) <> 1 then Invalid;
      if EVP_PKEY_CTX_set_signature_md(Context, EVP_sha1) <> 1 then Invalid;
      if ASign then
      begin
        Count := Length(FN); SetLength(Result, Count);
        if EVP_PKEY_sign(Context, @Result[0], Count, @Digest[0], 20) <> 1 then Invalid;
        if Count <> NativeUInt(Length(FN)) then Invalid;
      end
      else
      begin
        Status := EVP_PKEY_verify(Context, @ASignature[0], Length(ASignature), @Digest[0], 20);
        if Status = 1 then begin SetLength(Result, 1); Result[0] := 1; end
        else if Status <> 0 then Invalid;
      end;
    finally
      if Context <> nil then EVP_PKEY_CTX_free(Context);
      if Key <> nil then EVP_PKEY_free(Key);
      if ImportContext <> nil then EVP_PKEY_CTX_free(ImportContext);
      if Params <> nil then OSSL_PARAM_free(Params);
      if Builder <> nil then OSSL_PARAM_BLD_free(Builder);
      for I := 0 to 4 do if Bn[I] <> nil then BN_clear_free(Bn[I]);
    end;
{$ELSE}
    Invalid;
{$ENDIF}
{$ENDIF}
  finally
    TCardCrypto.Clear(Digest);
  end;
end;

function TCardNativeRsaProvider.SignSha1(const AData: TBytes): TBytes;
begin
  Result := nil;
  try Result := Process(AData, nil, True);
  except TCardCrypto.Clear(Result); raise; end;
end;

function TCardNativeRsaProvider.VerifySha1(const AData, ASignature: TBytes): Boolean;
var B: TBytes;
begin
  B := Process(AData, ASignature, False);
  Result := Length(B) = 1;
end;

end.
