unit ERD.Card.Crypto.DES;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Crypto;

type
  /// <summary>Optional maintained Triple DES/CSPRNG capability; existing AES interface identifiers remain unchanged.</summary>
  /// <remarks>Protocol layers explicitly expand DES/2K3DES keys; implementations borrow inputs and return independent buffers.</remarks>
  ICardDesProvider = interface(ICardAesProvider)
    ['{A812D471-B885-4E80-901A-2B4C4D25D744}']
    /// <summary>Performs three-key EDE CBC without padding through the native cryptographic backend.</summary>
    /// <param name="AKey">Exactly 24 secret bytes, including explicitly expanded DES/2K3DES keys.</param>
    /// <param name="AIv">Exactly eight borrowed bytes; never modified.</param>
    /// <param name="AData">Positive multiple of eight, at most one MiB.</param>
    /// <param name="AEncrypt">True for encryption, false for decryption.</param>
    /// <returns>Independent exact-length ciphertext/plaintext; owner clears secret outputs.</returns>
    /// <exception cref="ECardCryptoError">Bounds, backend policy or native operation fails.</exception>
    function TripleDesCbc(const AKey, AIv, AData: TBytes;
      const AEncrypt: Boolean): TBytes;
  end;

  /// <summary>DES key expansion and protocol MAC composition; ciphers remain delegated to maintained native libraries.</summary>
  TCardDesCrypto = class
  public
    /// <summary>Expands explicit DES, two-key or three-key material into native 24-byte EDE order.</summary>
    /// <param name="AKey">Exactly 8, 16 or 24 bytes; no default key or byte-order reversal.</param>
    /// <returns>Owned K1/K1/K1, K1/K2/K1 or unchanged K1/K2/K3 copy.</returns>
    class function ExpandKey(const AKey: TBytes): TBytes; static;
    /// <summary>Checks the native three-key CBC size contract without cryptographic I/O.</summary>
    /// <param name="AKey">Exactly 24 bytes.</param>
    /// <param name="AIv">Exactly eight bytes.</param>
    /// <param name="AData">Positive multiple of eight, at most one MiB.</param>
    class procedure ValidateCbc(const AKey, AIv, AData: TBytes); static;
    /// <summary>Expands explicit key material, performs bounded CBC and validates native output lengths.</summary>
    /// <param name="AProvider">Retained non-nil maintained DES backend.</param>
    /// <param name="AKey">8, 16 or 24 supplied bytes.</param>
    /// <param name="AIv">Eight borrowed IV bytes.</param>
    /// <param name="AData">Complete bounded eight-byte blocks.</param>
    /// <param name="AEncrypt">True for encryption, false for decryption.</param>
    /// <returns>Owned exact-length primitive result.</returns>
    class function Crypt(const AProvider: ICardDesProvider;
      const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes; static;
    /// <summary>Computes eight-byte NIST CMAC using 64-bit blocks and an explicit protocol chaining IV.</summary>
    /// <param name="AProvider">Maintained DES backend.</param>
    /// <param name="AKey">8, 16 or 24 supplied bytes.</param>
    /// <param name="AIv">Eight borrowed bytes; nonzero IV is a protocol variant.</param>
    /// <param name="AMessage">Zero through 1048560 borrowed bytes.</param>
    /// <returns>Independent complete eight-byte MAC.</returns>
    class function CmacChained(const AProvider: ICardDesProvider;
      const AKey, AIv, AMessage: TBytes): TBytes; static;
    /// <summary>Legacy DESFire send transform: CBC XOR before the native decrypt primitive; not ordinary CBC decryption.</summary>
    /// <param name="AProvider">Maintained DES backend.</param>
    /// <param name="AKey">8 or 16 explicit legacy bytes.</param>
    /// <param name="AData">Positive complete eight-byte blocks, at most one MiB.</param>
    /// <returns>Owned legacy wire blocks with a fresh zero IV for this command.</returns>
    class function LegacySend(const AProvider: ICardDesProvider;
      const AKey, AData: TBytes): TBytes; static;
  end;

implementation

procedure Invalid;
begin
  raise ECardCryptoError.Create('Invalid DES cryptographic operation.');
end;

class function TCardDesCrypto.ExpandKey(const AKey: TBytes): TBytes;
begin
  Result := nil;
  if not(Length(AKey) in [8, 16, 24]) then
    Invalid;
  SetLength(Result, 24);
  Move(AKey[0], Result[0], Length(AKey));
  if Length(AKey) = 8 then
  begin
    Move(AKey[0], Result[8], 8);
    Move(AKey[0], Result[16], 8);
  end
  else if Length(AKey) = 16 then
    Move(AKey[0], Result[16], 8);
end;

class procedure TCardDesCrypto.ValidateCbc(const AKey, AIv, AData: TBytes);
begin
  if (Length(AKey) <> 24) or (Length(AIv) <> 8) or (Length(AData) = 0) or
    (Length(AData) > 1048576) or (Length(AData) mod 8 <> 0) then
    Invalid;
end;

class function TCardDesCrypto.Crypt(const AProvider: ICardDesProvider;
  const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
var
  K: TBytes;
begin
  Result := nil;
  K := nil;
  if AProvider = nil then
    Invalid;
  try
    K := ExpandKey(AKey);
    ValidateCbc(K, AIv, AData);
    Result := AProvider.TripleDesCbc(K, AIv, AData, AEncrypt);
    if Length(Result) <> Length(AData) then
    begin
      TCardCrypto.Clear(Result);
      Invalid;
    end;
  finally
    TCardCrypto.Clear(K);
  end;
end;

class function TCardDesCrypto.CmacChained(const AProvider: ICardDesProvider;
  const AKey, AIv, AMessage: TBytes): TBytes;
var
  Zero, L, K1, K2, Body, Cipher: TBytes;
  N, Last, Remaining, I: Integer;
  function DoubleBlock(const B: TBytes): TBytes;
  var
    J: Integer;
    Carry, Next: Byte;
  begin
    Result := nil;
    SetLength(Result, 8);
    Carry := 0;
    for J := 7 downto 0 do
    begin
      Next := B[J] shr 7;
      Result[J] := ((Integer(B[J]) shl 1) and $FF) or Carry;
      Carry := Next;
    end;
    if Carry <> 0 then
      Result[7] := Result[7] xor $1B;
  end;

begin
  Result := nil;
  if (AProvider = nil) or (Length(AIv) <> 8) or (Length(AMessage) > 1048560)
  then
    Invalid;
  Zero := nil;
  L := nil;
  K1 := nil;
  K2 := nil;
  Body := nil;
  Cipher := nil;
  try
    SetLength(Zero, 8);
    L := Crypt(AProvider, AKey, Zero, Zero, True);
    K1 := DoubleBlock(L);
    K2 := DoubleBlock(K1);
    N := (Length(AMessage) + 7) div 8;
    if N = 0 then
      N := 1;
    SetLength(Body, N * 8);
    if Length(AMessage) > 0 then
      Move(AMessage[0], Body[0], Length(AMessage));
    Last := (N - 1) * 8;
    Remaining := Length(AMessage) - Last;
    if Remaining = 8 then
      for I := 0 to 7 do
        Body[Last + I] := Body[Last + I] xor K1[I]
    else
    begin
      Body[Last + Remaining] := $80;
      for I := 0 to 7 do
        Body[Last + I] := Body[Last + I] xor K2[I];
    end;
    Cipher := Crypt(AProvider, AKey, AIv, Body, True);
    Result := Copy(Cipher, Length(Cipher) - 8, 8);
  finally
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(L);
    TCardCrypto.Clear(K1);
    TCardCrypto.Clear(K2);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Cipher);
  end;
end;

class function TCardDesCrypto.LegacySend(const AProvider: ICardDesProvider;
  const AKey, AData: TBytes): TBytes;
var
  InitialVector, Block, Cipher: TBytes;
  I, J: Integer;
begin
  Result := nil;
  InitialVector := nil;
  Block := nil;
  Cipher := nil;
  if not(Length(AKey) in [8, 16]) or (Length(AData) = 0) or
    (Length(AData) mod 8 <> 0) or (Length(AData) > 1048576) then
    Invalid;
  try
    SetLength(InitialVector, 8);
    SetLength(Block, 8);
    SetLength(Result, Length(AData));
    try
      for I := 0 to Length(AData) div 8 - 1 do
      begin
        { Previous wire block is the CBC chaining value; first block uses zero. }
        if I > 0 then
          for J := 0 to 7 do
            Block[J] := AData[I * 8 + J] xor Result[(I - 1) * 8 + J]
        else
          Move(AData[0], Block[0], 8);
        TCardCrypto.Clear(Cipher);
        Cipher := Crypt(AProvider, AKey, InitialVector, Block, False);
        Move(Cipher[0], Result[I * 8], 8);
      end;
    except
      TCardCrypto.Clear(Result);
      raise;
    end;
  finally
    TCardCrypto.Clear(InitialVector);
    TCardCrypto.Clear(Block);
    TCardCrypto.Clear(Cipher);
  end;
end;

end.
