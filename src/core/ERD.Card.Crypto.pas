unit ERD.Card.Crypto;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Invalid cryptographic arguments or a failed provider operation; contains no secret data.</summary>
  ECardCryptoError = class(Exception);

  /// <summary>Retained AES-128/CSPRNG backend; implementations use a maintained system cryptographic library.</summary>
  /// <remarks>Inputs are borrowed and never modified. Outputs have independent storage. CBC uses no padding;
  /// keys and IVs are exactly 16 bytes. Implementations must not log keys, nonces or plaintext.</remarks>
  ICardAesProvider = interface
    ['{49AC773E-CC60-433D-9ACD-AEF8A0A76B3F}']
    /// <summary>Encrypts complete AES blocks with CBC and no padding.</summary>
    /// <param name="AKey">Exactly 16 secret bytes.</param>
    /// <param name="AIv">Exactly 16 bytes; not advanced or modified.</param>
    /// <param name="AData">Positive multiple of 16 bytes, at most one MiB.</param>
    /// <returns>Independent ciphertext of exactly the input length.</returns>
    /// <exception cref="ECardCryptoError">Arguments or provider fail.</exception>
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Decrypts complete AES blocks with CBC and no padding.</summary>
    /// <param name="AKey">Exactly 16 secret bytes.</param>
    /// <param name="AIv">Exactly 16 bytes; not modified.</param>
    /// <param name="AData">Positive multiple of 16 bytes, at most one MiB.</param>
    /// <returns>Independent plaintext of exactly the input length; caller must clear secret output.</returns>
    /// <exception cref="ECardCryptoError">Arguments or provider fail.</exception>
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    /// <summary>Obtains fresh bytes from the provider's cryptographically secure random generator.</summary>
    /// <param name="ACount">One through 65536 bytes.</param>
    /// <returns>Independent random bytes; no deterministic/default fallback.</returns>
    /// <exception cref="ECardCryptoError">Arguments or random generator fail.</exception>
    function RandomBytes(const ACount: Integer): TBytes;
  end;

  /// <summary>AES-CMAC and buffer utilities; AES itself is delegated to the retained provider.</summary>
  TCardCrypto = class
  public
    /// <summary>Validates the shared bounded AES-128 CBC contract without I/O.</summary>
    /// <param name="AKey">Exactly 16 bytes.</param>
    /// <param name="AIv">Exactly 16 bytes.</param>
    /// <param name="AData">Positive multiple of 16 bytes, at most one MiB.</param>
    /// <exception cref="ECardCryptoError">Sizes are invalid.</exception>
    class procedure ValidateCbc(const AKey, AIv, AData: TBytes); static;
    /// <summary>Calculates a complete NIST SP 800-38B AES-CMAC, including the empty-message case.</summary>
    /// <param name="AProvider">Non-nil maintained AES backend.</param>
    /// <param name="AKey">Exactly 16 bytes, borrowed and not modified.</param>
    /// <param name="AMessage">Zero through 1048560 bytes; no secret input is logged.</param>
    /// <returns>Independent complete 16-byte MAC; no protocol-specific truncation.</returns>
    /// <exception cref="ECardCryptoError">Provider, bounds or primitive result fail.</exception>
    class function Cmac(const AProvider: ICardAesProvider;
      const AKey, AMessage: TBytes): TBytes; static;
    /// <summary>Calculates the DESFire EV1 chained AES-CMAC variant with an explicit starting IV.</summary>
    /// <param name="AProvider">Non-nil maintained AES backend.</param>
    /// <param name="AKey">Exactly 16 borrowed secret bytes.</param>
    /// <param name="AIv">Exactly 16 borrowed session-IV bytes, never modified.</param>
    /// <param name="AMessage">Zero through 1048560 bytes.</param>
    /// <returns>Independent full 16-byte result; caller advances its session IV explicitly.</returns>
    /// <remarks>A nonzero IV is a protocol variant, not ordinary NIST CMAC.</remarks>
    /// <exception cref="ECardCryptoError">Provider, bounds or primitive result fail.</exception>
    class function CmacChained(const AProvider: ICardAesProvider;
      const AKey, AIv, AMessage: TBytes): TBytes; static;
    /// <summary>Compares every byte of equal-length buffers without an early mismatch exit.</summary>
    /// <param name="ALeft">First borrowed buffer.</param>
    /// <param name="ARight">Second borrowed buffer.</param>
    /// <returns>True for identical bytes; length mismatch returns false immediately.</returns>
    /// <remarks>Source-level timing discipline; actual compiler/CPU timing has not been certified.</remarks>
    class function EqualSecret(const ALeft, ARight: TBytes): Boolean; static;
    /// <summary>Overwrites an exclusively owned dynamic buffer and releases its local reference.</summary>
    /// <param name="ABytes">Owned mutable buffer; aliases would observe the overwrite.</param>
    /// <remarks>Caller must copy borrowed arrays first. Managed temporaries/provider copies cannot be guaranteed erased.</remarks>
    class procedure Clear(var ABytes: TBytes); static;
  end;

implementation

class procedure TCardCrypto.ValidateCbc(const AKey, AIv, AData: TBytes);
begin
  if (Length(AKey) <> 16) or (Length(AIv) <> 16) or (Length(AData) = 0) or
    (Length(AData) > 1048576) or (Length(AData) mod 16 <> 0) then
    raise ECardCryptoError.Create('Invalid AES-128 CBC arguments.');
end;

class procedure TCardCrypto.Clear(var ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    FillChar(ABytes[0], Length(ABytes), 0);
  ABytes := nil;
end;

class function TCardCrypto.EqualSecret(const ALeft, ARight: TBytes): Boolean;
var
  I: Integer;
  Difference: Byte;
begin
  Result := False;
  if Length(ALeft) <> Length(ARight) then
    Exit;
  Difference := 0;
  for I := 0 to High(ALeft) do
    Difference := Difference or (ALeft[I] xor ARight[I]);
  Result := Difference = 0;
end;

class function TCardCrypto.Cmac(const AProvider: ICardAesProvider;
  const AKey, AMessage: TBytes): TBytes;
var
  Zero: TBytes;
begin
  Zero := nil;
  try
    SetLength(Zero, 16);
    Result := CmacChained(AProvider, AKey, Zero, AMessage);
  finally
    Clear(Zero);
  end;
end;

class function TCardCrypto.CmacChained(const AProvider: ICardAesProvider;
  const AKey, AIv, AMessage: TBytes): TBytes;
var
  Zero, L, K1, K2, Blocks, Cipher: TBytes;
  N, Last, Remaining, I: Integer;
  function DoubleBlock(const A: TBytes): TBytes;
  var
    J: Integer;
    Carry, Next: Byte;
  begin
    Result := nil;
    SetLength(Result, 16);
    Carry := 0;
    for J := 15 downto 0 do
    begin
      Next := A[J] shr 7;
      Result[J] := ((Integer(A[J]) shl 1) and $FF) or Carry;
      Carry := Next;
    end;
    if Carry <> 0 then
      Result[15] := Result[15] xor $87;
  end;

begin
  Result := nil;
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(AIv) <> 16) or
    (Length(AMessage) > 1048560) then
    raise ECardCryptoError.Create('Invalid AES-CMAC arguments.');
  Zero := nil;
  L := nil;
  K1 := nil;
  K2 := nil;
  Blocks := nil;
  Cipher := nil;
  try
    SetLength(Zero, 16);
    L := AProvider.EncryptCbc(AKey, Zero, Zero);
    if Length(L) <> 16 then
      raise ECardCryptoError.Create('Invalid AES provider result.');
    K1 := DoubleBlock(L);
    K2 := DoubleBlock(K1);
    N := (Length(AMessage) + 15) div 16;
    if N = 0 then
      N := 1;
    SetLength(Blocks, N * 16);
    if Length(AMessage) > 0 then
      Move(AMessage[0], Blocks[0], Length(AMessage));
    Last := (N - 1) * 16;
    Remaining := Length(AMessage) - Last;
    if Remaining = 16 then
      for I := 0 to 15 do
        Blocks[Last + I] := Blocks[Last + I] xor K1[I]
    else
    begin
      Blocks[Last + Remaining] := $80;
      for I := 0 to 15 do
        Blocks[Last + I] := Blocks[Last + I] xor K2[I];
    end;
    Cipher := AProvider.EncryptCbc(AKey, AIv, Blocks);
    if Length(Cipher) <> Length(Blocks) then
      raise ECardCryptoError.Create('Invalid AES provider result.');
    Result := Copy(Cipher, Last, 16);
  finally
    Clear(Zero);
    Clear(L);
    Clear(K1);
    Clear(K2);
    Clear(Blocks);
    Clear(Cipher);
  end;
end;

end.
