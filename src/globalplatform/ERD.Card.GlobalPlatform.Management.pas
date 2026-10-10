unit ERD.Card.GlobalPlatform.Management;

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
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Crypto, ERD.Card.Crypto.DES,
  ERD.Card.Crypto.RSA, ERD.Card.Crypto.Hash;

type
  /// <summary>Delegated-management signer for one token-free INSTALL or DELETE command.</summary>
  ICardGpTokenSigner = interface
    ['{43778719-4FD3-4A27-9E08-5B6A2C1F58F4}']
    /// <summary>Signs P1, P2, Lc and data before the token length/tag is appended.</summary>
    /// <param name="ACommand">Explicit E6 or E4 plain short command with no token field.</param>
    /// <returns>Independent protocol token; never a signature over the protected wire command.</returns>
    function Sign(const ACommand: TApduCommand): TBytes;
  end;

  /// <summary>RSA PKCS#1 SHA-1 token signer for the GP legacy RSA delegated-management profile.</summary>
  TGpRsaTokenSigner = class(TInterfacedObject, ICardGpTokenSigner)
  private
    FProvider: ICardRsaProvider;
  public
    /// <summary>Retains an explicit native or HSM signer; no card or key I/O.</summary>
    /// <param name="AProvider">Provisioned non-nil RSA signer.</param>
    constructor Create(const AProvider: ICardRsaProvider);
    /// <summary>Generates a RSA delegated-management token over canonical token input.</summary>
    /// <param name="ACommand">Token-free INSTALL or DELETE command.</param>
    /// <returns>Owned RSA signature; manager independently checks its APDU budget.</returns>
    function Sign(const ACommand: TApduCommand): TBytes;
  end;

  /// <summary>AES-CMAC delegated-management token signer for GP 2.3.1 AES token profiles.</summary>
  TGpAesTokenSigner = class(TInterfacedObject, ICardGpTokenSigner)
  private
    FProvider: ICardAesProvider;
    FKey: TBytes;
  public
    /// <summary>Retains a native AES provider and copies an explicitly provisioned AES-128 token key.</summary>
    /// <param name="AProvider">Non-nil maintained AES backend.</param>
    /// <param name="AKey">Sixteen-byte token key; independent from secure-channel keys.</param>
    constructor Create(const AProvider: ICardAesProvider; const AKey: TBytes);
    /// <summary>Clears the owned token key.</summary>
    destructor Destroy; override;
    /// <summary>Calculates a complete sixteen-byte CMAC token.</summary>
    /// <param name="ACommand">Token-free INSTALL or DELETE command.</param>
    /// <returns>Owned AES token.</returns>
    function Sign(const ACommand: TApduCommand): TBytes;
  end;

  /// <summary>Receipt verification capability; throws on absent, malformed, invalid or replayed receipts.</summary>
  ICardGpReceiptVerifier = interface
    ['{386D5B55-ED02-4D2D-B87B-29433F9B45F6}']
    /// <summary>Authenticates receipt, explicit operation context, card identity and confirmation counter.</summary>
    /// <param name="AConfirmation">Complete outer length followed by receipt, counter and unique-data LVs.</param>
    /// <param name="AContext">Ordered AID length-values for the performed operation.</param>
    procedure Verify(const AConfirmation, AContext: TBytes);
  end;

  /// <summary>DES retail-MAC or AES-CMAC receipt verifier with explicit identity and replay protection.</summary>
  TGpReceiptVerifier = class(TInterfacedObject, ICardGpReceiptVerifier)
  private
    FAes: ICardAesProvider;
    FDes: ICardDesProvider;
    FKey, FIdentity: TBytes;
    FCounter: Integer;
  public
    /// <summary>Creates an AES receipt verifier and copies supplied receipt key and expected identity.</summary>
    /// <param name="AProvider">Native AES provider.</param>
    /// <param name="AKey">Explicit sixteen-byte receipt key.</param>
    /// <param name="ACardUniqueData">Expected nonempty card unique data; never discovered from the receipt.</param>
    /// <param name="ALastCounter">Last accepted counter, or minus one for first authenticated receipt.</param>
    constructor CreateAes(const AProvider: ICardAesProvider; const AKey,
      ACardUniqueData: TBytes; const ALastCounter: Integer = -1);
    /// <summary>Creates a legacy double-length DES receipt verifier.</summary>
    /// <param name="AProvider">Native DES provider.</param>
    /// <param name="AKey">Explicit sixteen-byte receipt key.</param>
    /// <param name="ACardUniqueData">Expected nonempty card unique data.</param>
    /// <param name="ALastCounter">Last accepted counter, or minus one for first receipt.</param>
    constructor CreateDes(const AProvider: ICardDesProvider; const AKey,
      ACardUniqueData: TBytes; const ALastCounter: Integer = -1);
    /// <summary>Clears the owned receipt key and identity buffers.</summary>
    destructor Destroy; override;
    /// <summary>Verifies MAC, identity and a strictly increasing confirmation counter.</summary>
    /// <param name="AConfirmation">Complete framed card confirmation; no receipt is an error.</param>
    /// <param name="AContext">Explicit nonempty operation context, at most 100 bytes.</param>
    /// <remarks>Counter advances only after successful verification; preserve it across application sessions.</remarks>
    procedure Verify(const AConfirmation, AContext: TBytes);
    /// <summary>Last authenticated counter; persist this together with the card identity to prevent replay.</summary>
    property LastCounter: Integer read FCounter;
  end;

  /// <summary>GP token, DAP and receipt framing and cryptographic composition.</summary>
  TGpManagementCrypto = class
  public
    /// <summary>Builds P1/P2/Lc/data token-signature input, excluding token LV/TLV.</summary>
    /// <param name="ACommand">Token-free E6 or E4 basic-channel short command.</param>
    /// <returns>Independent canonical signed bytes.</returns>
    class function TokenInput(const ACommand: TApduCommand): TBytes; static;
    /// <summary>Computes GP ISO 9797-1 algorithm 3 retail MAC with padding method 2 and zero ICV.</summary>
    /// <param name="AProvider">Native DES backend.</param>
    /// <param name="AKey">Explicit double-length sixteen-byte DES key.</param>
    /// <param name="AData">Zero through 1048560 input bytes.</param>
    /// <returns>Owned complete eight-byte MAC.</returns>
    class function RetailMac(const AProvider: ICardDesProvider;
      const AKey, AData: TBytes): TBytes; static;
    /// <summary>Calculates protocol-specific three-byte key check value.</summary>
    /// <param name="AAes">AES provider, required for AES keys.</param>
    /// <param name="ADes">DES provider, required for DES keys.</param>
    /// <param name="AKey">Sixteen-byte key.</param>
    /// <param name="AIsAes">AES encrypts sixteen 01 bytes; DES encrypts eight zero bytes.</param>
    /// <returns>Independent first three encryption bytes.</returns>
    class function KeyCheckValue(const AAes: ICardAesProvider; const ADes: ICardDesProvider;
      const AKey: TBytes; const AIsAes: Boolean): TBytes; static;
    /// <summary>Encodes one E2 DAP block containing a security-domain 4F and signature C3.</summary>
    /// <param name="ADomain">Five- through sixteen-byte DAP domain AID.</param>
    /// <param name="ASignature">Eight-byte DES MAC, sixteen-byte AES MAC or 128- through 512-byte RSA signature.</param>
    /// <returns>Complete canonical BER-TLV DAP block.</returns>
    class function DapBlock(const ADomain, ASignature: TBytes): TBytes; static;
    /// <summary>Produces a legacy RSA DAP signature over SHA-1 of the raw load-file data block hash.</summary>
    /// <param name="AHash">Native SHA-1 provider used for the load-file hash.</param>
    /// <param name="ASigner">Provisioned RSA PKCS#1 SHA-1 signer; hashes the digest again per GP 2.1.1.</param>
    /// <param name="ALoadFileData">Raw concatenated CAP components, excluding C4 and its BER length.</param>
    /// <returns>Owned RSA DAP signature.</returns>
    class function RsaDap(const AHash: ICardHashProvider; const ASigner: ICardRsaProvider;
      const ALoadFileData: TBytes): TBytes; static;
    /// <summary>Verifies a legacy RSA DAP signature over the SHA-1 load-file hash.</summary>
    /// <param name="AHash">Maintained SHA-1 provider.</param>
    /// <param name="AVerifier">Provisioned public-key RSA verifier.</param>
    /// <param name="ALoadFileData">Raw canonical CAP components without C4 or DAP framing.</param>
    /// <param name="ASignature">Explicit legacy 128-byte DAP signature.</param>
    /// <returns>True only for a valid signature; invalid signature sizes return false.</returns>
    class function VerifyRsaDap(const AHash: ICardHashProvider; const AVerifier: ICardRsaProvider;
      const ALoadFileData, ASignature: TBytes): Boolean; static;

    /// <summary>Signs a supplied load-file hash using legacy DES retail MAC or AES-CMAC.</summary>
    /// <param name="AAes">Native AES provider required for the AES profile.</param>
    /// <param name="ADes">Native DES provider required for the legacy profile.</param>
    /// <param name="AKey">Explicit sixteen-byte DAP key.</param>
    /// <param name="ALoadHash">Explicit 20/32/48/64-byte load-file hash; legacy DES requires SHA-1 length 20.</param>
    /// <param name="AIsAes">True signs with full sixteen-byte AES CMAC; false returns eight-byte retail MAC.</param>
    /// <returns>Independent DAP signature for DapBlock; input hash framing is not included.</returns>
    class function SymmetricDap(const AAes: ICardAesProvider; const ADes: ICardDesProvider;
      const AKey, ALoadHash: TBytes; const AIsAes: Boolean): TBytes; static;

    /// <summary>Verifies an explicit DES or AES DAP signature with constant-time byte comparison.</summary>
    /// <param name="AAes">Native AES provider for the AES profile.</param>
    /// <param name="ADes">Native DES provider for the legacy profile.</param>
    /// <param name="AKey">Sixteen-byte DAP key.</param>
    /// <param name="ALoadHash">Explicit protocol load-file hash.</param>
    /// <param name="ASignature">Eight-byte DES or sixteen-byte AES signature.</param>
    /// <param name="AIsAes">True for AES-CMAC, false for retail MAC.</param>
    /// <returns>True only if the entire expected signature matches.</returns>
    class function VerifySymmetricDap(const AAes: ICardAesProvider; const ADes: ICardDesProvider;
      const AKey, ALoadHash, ASignature: TBytes; const AIsAes: Boolean): Boolean; static;

    /// <summary>Builds an ordered length-value AID context for receipt verification.</summary>
    /// <param name="AAids">Load: package/domain; install: package/instance; delete: object; extradite: old domain/object/new domain.</param>
    /// <returns>Independent concatenated length-values; each AID is five through sixteen bytes.</returns>
    class function ReceiptContext(const AAids: array of TBytes): TBytes; static;
  end;

implementation

procedure Invalid;
begin
  raise ECardCryptoError.Create('Invalid GlobalPlatform management cryptography.');
end;

function Join(const A, B: TBytes): TBytes;
begin
  Result := CopyBytes(A); SetLength(Result, Length(A) + Length(B));
  if Length(B) > 0 then Move(B[0], Result[Length(A)], Length(B));
end;

function Len(const N: Integer): TBytes;
begin
  Result := nil;
  if (N < 0) or (N > 65535) then Invalid;
  if N < 128 then begin SetLength(Result, 1); Result[0] := N; end
  else if N <= 255 then begin SetLength(Result, 2); Result[0] := $81; Result[1] := N; end
  else begin SetLength(Result, 3); Result[0] := $82; Result[1] := N shr 8; Result[2] := N and $FF; end;
end;

class function TGpManagementCrypto.TokenInput(const ACommand: TApduCommand): TBytes;
begin
  Result := nil;
  if (ACommand.CLA <> $80) or not (ACommand.INS in [$E6, $E4]) or
    (Length(ACommand.Data) > 255) or ACommand.IsExtended then Invalid;
  SetLength(Result, 3); Result[0] := ACommand.P1; Result[1] := ACommand.P2;
  Result[2] := Length(ACommand.Data); Result := Join(Result, ACommand.Data);
end;

class function TGpManagementCrypto.RetailMac(const AProvider: ICardDesProvider;
  const AKey, AData: TBytes): TBytes;
var Body, Iv, Cipher, Tail, Key1, Key2: TBytes;
begin
  Result := nil; Body := nil; Iv := nil; Cipher := nil; Tail := nil; Key1 := nil; Key2 := nil;
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(AData) > 1048560) then Invalid;
  try
    Key1 := Copy(AKey, 0, 8); Key2 := Copy(AKey, 8, 8);
    Body := CopyBytes(AData); SetLength(Body, (Length(AData) div 8 + 1) * 8);
    Body[Length(AData)] := $80; SetLength(Iv, 8);
    Cipher := TCardDesCrypto.Crypt(AProvider, Key1, Iv, Body, True);
    Tail := Copy(Cipher, Length(Cipher) - 8, 8);
    TCardCrypto.Clear(Cipher);
    Cipher := TCardDesCrypto.Crypt(AProvider, Key2, Iv, Tail, False);
    Result := TCardDesCrypto.Crypt(AProvider, Key1, Iv, Cipher, True);
  finally
    TCardCrypto.Clear(Body); TCardCrypto.Clear(Iv); TCardCrypto.Clear(Cipher); TCardCrypto.Clear(Tail);
    TCardCrypto.Clear(Key1); TCardCrypto.Clear(Key2);
  end;
end;

class function TGpManagementCrypto.KeyCheckValue(const AAes: ICardAesProvider;
  const ADes: ICardDesProvider; const AKey: TBytes; const AIsAes: Boolean): TBytes;
var Data, Iv, Cipher: TBytes; I: Integer;
begin
  Result := nil; Data := nil; Iv := nil; Cipher := nil;
  if Length(AKey) <> 16 then Invalid;
  try
    if AIsAes then
    begin
      if AAes = nil then Invalid;
      SetLength(Data, 16); SetLength(Iv, 16);
      for I := 0 to 15 do Data[I] := 1;
      Cipher := AAes.EncryptCbc(AKey, Iv, Data);
      if Length(Cipher) <> 16 then Invalid;
    end
    else
    begin
      SetLength(Data, 8); SetLength(Iv, 8);
      Cipher := TCardDesCrypto.Crypt(ADes, AKey, Iv, Data, True);
    end;
    Result := Copy(Cipher, 0, 3);
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(Iv); TCardCrypto.Clear(Cipher); end;
end;

class function TGpManagementCrypto.DapBlock(const ADomain, ASignature: TBytes): TBytes;
var Body: TBytes;
begin
  if (Length(ADomain) < 5) or (Length(ADomain) > 16) or
    not ((Length(ASignature) in [8, 16, 128, 192]) or
    (Length(ASignature) = 256) or (Length(ASignature) = 384) or
    (Length(ASignature) = 512)) then Invalid;
  Body := Join(HexToBytes('4F'), Join(Len(Length(ADomain)), ADomain));
  Body := Join(Body, Join(HexToBytes('C3'), Join(Len(Length(ASignature)), ASignature)));
  Result := Join(HexToBytes('E2'), Join(Len(Length(Body)), Body));
end;

class function TGpManagementCrypto.RsaDap(const AHash: ICardHashProvider;
  const ASigner: ICardRsaProvider; const ALoadFileData: TBytes): TBytes;
var Digest: TBytes;
begin
  Result := nil; Digest := nil;
  if (AHash = nil) or (ASigner = nil) or (Length(ALoadFileData) = 0) then Invalid;
  try
    Digest := AHash.Sha1(ALoadFileData);
    if Length(Digest) <> 20 then Invalid;
    Result := ASigner.SignSha1(Digest);
    if Length(Result) <> 128 then Invalid;
  finally TCardCrypto.Clear(Digest); end;
end;

class function TGpManagementCrypto.VerifyRsaDap(const AHash: ICardHashProvider;
  const AVerifier: ICardRsaProvider; const ALoadFileData, ASignature: TBytes): Boolean;
var Digest: TBytes;
begin
  Result := False; Digest := nil;
  if (AHash = nil) or (AVerifier = nil) or (Length(ALoadFileData) = 0) then Invalid;
  if Length(ASignature) <> 128 then Exit;
  try
    Digest := AHash.Sha1(ALoadFileData);
    if Length(Digest) <> 20 then Invalid;
    Result := AVerifier.VerifySha1(Digest, ASignature);
  finally TCardCrypto.Clear(Digest); end;
end;

class function TGpManagementCrypto.VerifySymmetricDap(const AAes: ICardAesProvider;
  const ADes: ICardDesProvider; const AKey, ALoadHash, ASignature: TBytes;
  const AIsAes: Boolean): Boolean;
var Expected: TBytes;
begin
  Result := False; Expected := nil;
  if (AIsAes and (Length(ASignature) <> 16)) or
    ((not AIsAes) and (Length(ASignature) <> 8)) then Exit;
  try
    Expected := SymmetricDap(AAes, ADes, AKey, ALoadHash, AIsAes);
    Result := TCardCrypto.EqualSecret(Expected, ASignature);
  finally TCardCrypto.Clear(Expected); end;
end;

class function TGpManagementCrypto.SymmetricDap(const AAes: ICardAesProvider;
  const ADes: ICardDesProvider; const AKey, ALoadHash: TBytes; const AIsAes: Boolean): TBytes;
begin
  Result := nil;
  if not (Length(ALoadHash) in [20, 32, 48, 64]) or
    ((not AIsAes) and (Length(ALoadHash) <> 20)) then Invalid;
  if AIsAes then Result := TCardCrypto.Cmac(AAes, AKey, ALoadHash)
  else Result := RetailMac(ADes, AKey, ALoadHash);
end;

class function TGpManagementCrypto.ReceiptContext(const AAids: array of TBytes): TBytes;
var I: Integer;
begin
  Result := nil;
  if (Length(AAids) < 1) or (Length(AAids) > 3) then Invalid;
  for I := 0 to High(AAids) do
  begin
    if (Length(AAids[I]) < 5) or (Length(AAids[I]) > 16) then Invalid;
    Result := Join(Result, Join(Len(Length(AAids[I])), AAids[I]));
  end;
end;

constructor TGpRsaTokenSigner.Create(const AProvider: ICardRsaProvider);
begin
  inherited Create; if AProvider = nil then Invalid; FProvider := AProvider;
end;

function TGpRsaTokenSigner.Sign(const ACommand: TApduCommand): TBytes;
begin
  Result := FProvider.SignSha1(TGpManagementCrypto.TokenInput(ACommand));
  if Length(Result) <> 128 then Invalid;
end;

constructor TGpAesTokenSigner.Create(const AProvider: ICardAesProvider; const AKey: TBytes);
begin
  inherited Create; if (AProvider = nil) or (Length(AKey) <> 16) then Invalid;
  FProvider := AProvider; FKey := CopyBytes(AKey);
end;

destructor TGpAesTokenSigner.Destroy;
begin
  TCardCrypto.Clear(FKey); inherited Destroy;
end;

function TGpAesTokenSigner.Sign(const ACommand: TApduCommand): TBytes;
begin
  Result := TCardCrypto.Cmac(FProvider, FKey, TGpManagementCrypto.TokenInput(ACommand));
end;

constructor TGpReceiptVerifier.CreateAes(const AProvider: ICardAesProvider;
  const AKey, ACardUniqueData: TBytes; const ALastCounter: Integer);
begin
  inherited Create;
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(ACardUniqueData) < 1) or
    (Length(ACardUniqueData) > 255) or (ALastCounter < -1) or (ALastCounter > 65535) then Invalid;
  FAes := AProvider; FKey := CopyBytes(AKey); FIdentity := CopyBytes(ACardUniqueData); FCounter := ALastCounter;
end;

constructor TGpReceiptVerifier.CreateDes(const AProvider: ICardDesProvider;
  const AKey, ACardUniqueData: TBytes; const ALastCounter: Integer);
begin
  inherited Create;
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(ACardUniqueData) < 1) or
    (Length(ACardUniqueData) > 255) or (ALastCounter < -1) or (ALastCounter > 65535) then Invalid;
  FDes := AProvider; FKey := CopyBytes(AKey); FIdentity := CopyBytes(ACardUniqueData); FCounter := ALastCounter;
end;

destructor TGpReceiptVerifier.Destroy;
begin
  TCardCrypto.Clear(FKey); TCardCrypto.Clear(FIdentity); inherited Destroy;
end;

procedure TGpReceiptVerifier.Verify(const AConfirmation, AContext: TBytes);
var Receipt, Counter, Identity, Expected, Body: TBytes;
  Posn, CounterValue, Start: Integer;
  function ReadLv: TBytes;
  var N: Integer;
  begin
    if Posn >= Length(AConfirmation) then Invalid;
    N := AConfirmation[Posn]; Inc(Posn);
    if Posn + N > Length(AConfirmation) then Invalid;
    Result := Copy(AConfirmation, Posn, N); Inc(Posn, N);
  end;
begin
  if (Length(AConfirmation) < 2) or (AConfirmation[0] <> Length(AConfirmation) - 1) or
    (Length(AContext) = 0) or (Length(AContext) > 100) then Invalid;
  Expected := nil; Body := nil;
  try
    Posn := 1; Receipt := ReadLv; Start := Posn; Counter := ReadLv; Identity := ReadLv;
    if (Posn <> Length(AConfirmation)) or (Length(Counter) <> 2) or
      not TCardCrypto.EqualSecret(Identity, FIdentity) then Invalid;
    CounterValue := Integer(Counter[0]) * 256 + Counter[1];
    if CounterValue <= FCounter then Invalid;
    Body := Join(Copy(AConfirmation, Start, Posn - Start), AContext);
    if FAes <> nil then Expected := TCardCrypto.Cmac(FAes, FKey, Body)
    else Expected := TGpManagementCrypto.RetailMac(FDes, FKey, Body);
    if not TCardCrypto.EqualSecret(Receipt, Expected) then Invalid;
    FCounter := CounterValue;
  finally TCardCrypto.Clear(Expected); TCardCrypto.Clear(Body); end;
end;

end.
