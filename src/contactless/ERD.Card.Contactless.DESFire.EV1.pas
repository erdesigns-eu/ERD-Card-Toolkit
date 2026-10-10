unit ERD.Card.Contactless.DESFire.EV1;

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
  ERD.Card.Crypto, ERD.Card.Contactless.DESFire.EV2;

type
  /// <summary>Pure DESFire EV1 AES session-key, chained-IV and native secure-message codec.</summary>
  /// <remarks>No card I/O or AES primitive. Failed sessions must be discarded, never retried with the old IV.
  /// Full responses use encrypted CRC32 integrity, not EV2's encrypt-then-MAC construction.</remarks>
  TDesfireEv1Codec = class
  public
    /// <summary>Derives the EV1 AES session key from both authenticated 16-byte nonces.</summary>
    /// <param name="ARndA">Exactly 16 fresh reader bytes.</param>
    /// <param name="ARndB">Exactly 16 decrypted card bytes.</param>
    /// <returns>Independent secret A[0..3], B[0..3], A[12..15], B[12..15].</returns>
    /// <exception cref="ECardCryptoError">Nonce sizes are invalid.</exception>
    class function DeriveKey(const ARndA, ARndB: TBytes): TBytes; static;
    /// <summary>Calculates native reflected CRC32, initial FFFFFFFF, without a final XOR.</summary>
    /// <param name="AData">Borrowed zero through 1048560 bytes.</param>
    /// <returns>Four independent little-endian CRC bytes.</returns>
    /// <exception cref="ECardCryptoError">Input exceeds the bound.</exception>
    class function Crc32(const AData: TBytes): TBytes; static;
    /// <summary>Encodes one complete native command and advances the exclusively owned IV on success.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly 16 session-key bytes.</param>
    /// <param name="AIv">Exactly 16 owned IV bytes; replaced with the complete CMAC or last ciphertext block.</param>
    /// <param name="ACommand">Native EV1 instruction; ISO wrapping and AF framing are external.</param>
    /// <param name="AHeader">Clear native header, at most 32 bytes.</param>
    /// <param name="AData">Command body, at most 1048500 bytes.</param>
    /// <param name="AMode">Acquired file communication mode.</param>
    /// <param name="AWrite">True for a write body: append CMAC in MACed mode or encrypt body/CRC in Full mode.</param>
    /// <returns>Independent command data. Read/metadata commands advance CMAC without transmitting it.</returns>
    /// <exception cref="ECardCryptoError">Arguments or provider fail; discard the enclosing session.</exception>
    class function EncodeCommand(const AProvider: ICardAesProvider;
      const AKey: TBytes; var AIv: TBytes; const ACommand: Byte;
      const AHeader, AData: TBytes; const AMode: TDesfireCommunication;
      const AWrite: Boolean): TBytes; static;
    /// <summary>Validates the complete successful response before returning plaintext and advancing the IV.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly 16 session-key bytes.</param>
    /// <param name="AIv">Exactly 16 owned command IV; advanced only after integrity validation.</param>
    /// <param name="AData">Complete response data excluding 9100.</param>
    /// <param name="AMode">Explicit response mode; write acknowledgements and metadata use MACed.</param>
    /// <param name="AExpectedBytes">Exact plaintext size, zero through 1048500.</param>
    /// <returns>Independent verified plaintext; no decrypted bytes escape CRC/padding failures.</returns>
    /// <exception cref="ECardCryptoError">Integrity, size, padding or provider fails.</exception>
    class function DecodeResponse(const AProvider: ICardAesProvider;
      const AKey: TBytes; var AIv: TBytes; const AData: TBytes;
      const AMode: TDesfireCommunication; const AExpectedBytes: Integer)
      : TBytes; static;
  end;

implementation

procedure InvalidEv1;
begin
  raise ECardCryptoError.Create('Invalid DESFire EV1 AES secure message.');
end;

function Join(const A, B: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then
    Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then
    Move(B[0], Result[Length(A)], Length(B));
end;

procedure Validate(const P: ICardAesProvider; const K, V: TBytes;
  const M: TDesfireCommunication);
begin
  if (P = nil) or (Length(K) <> 16) or (Length(V) <> 16) or (Ord(M) < 0) or
    (Ord(M) > Ord(High(TDesfireCommunication))) then
    InvalidEv1;
end;

class function TDesfireEv1Codec.DeriveKey(const ARndA, ARndB: TBytes): TBytes;
begin
  Result := nil;
  if (Length(ARndA) <> 16) or (Length(ARndB) <> 16) then
    InvalidEv1;
  SetLength(Result, 16);
  Move(ARndA[0], Result[0], 4);
  Move(ARndB[0], Result[4], 4);
  Move(ARndA[12], Result[8], 4);
  Move(ARndB[12], Result[12], 4);
end;

class function TDesfireEv1Codec.Crc32(const AData: TBytes): TBytes;
var
  Value: Cardinal;
  I, J: Integer;
begin
  Result := nil;
  if Length(AData) > 1048560 then
    InvalidEv1;
  Value := $FFFFFFFF;
  for I := 0 to High(AData) do
  begin
    Value := Value xor AData[I];
    for J := 0 to 7 do
      if (Value and 1) <> 0 then
        Value := (Value shr 1) xor $EDB88320
      else
        Value := Value shr 1;
  end;
  SetLength(Result, 4);
  for I := 0 to 3 do
    Result[I] := (Value shr (8 * I)) and $FF;
end;

class function TDesfireEv1Codec.EncodeCommand(const AProvider: ICardAesProvider;
  const AKey: TBytes; var AIv: TBytes; const ACommand: Byte;
  const AHeader, AData: TBytes; const AMode: TDesfireCommunication;
  const AWrite: Boolean): TBytes;
var
  Vector, Body, Crc, NextIv: TBytes;
  N: Integer;
begin
  Result := nil;
  Validate(AProvider, AKey, AIv, AMode);
  if (Length(AHeader) > 32) or (Length(AData) > 1048500) or
    (not AWrite and (Length(AData) <> 0)) or (AWrite and (Length(AData) = 0))
  then
    InvalidEv1;
  Vector := nil;
  Body := nil;
  Crc := nil;
  NextIv := nil;
  try
    Vector := nil;
    SetLength(Vector, 1);
    Vector[0] := ACommand;
    Vector := Join(Vector, Join(AHeader, AData));
    if AWrite and (AMode = dfcFull) then
    begin
      Crc := Crc32(Vector);
      N := ((Length(AData) + 4 + 15) div 16) * 16;
      SetLength(Body, N);
      Move(AData[0], Body[0], Length(AData));
      Move(Crc[0], Body[Length(AData)], 4);
      Result := AProvider.EncryptCbc(AKey, AIv, Body);
      if Length(Result) <> N then
        InvalidEv1;
      NextIv := Copy(Result, N - 16, 16);
      Result := Join(AHeader, Result);
    end
    else
    begin
      NextIv := TCardCrypto.CmacChained(AProvider, AKey, AIv, Vector);
      Result := Join(AHeader, AData);
      if AWrite and (AMode = dfcMac) then
        Result := Join(Result, Copy(NextIv, 0, 8));
    end;
    TCardCrypto.Clear(AIv);
    AIv := NextIv;
    NextIv := nil;
  finally
    TCardCrypto.Clear(Vector);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Crc);
    TCardCrypto.Clear(NextIv);
  end;
end;

class function TDesfireEv1Codec.DecodeResponse(const AProvider
  : ICardAesProvider; const AKey: TBytes; var AIv: TBytes; const AData: TBytes;
  const AMode: TDesfireCommunication; const AExpectedBytes: Integer): TBytes;
var
  Plain, Vector, Crc, NextIv: TBytes;
  I, N: Integer;
begin
  Result := nil;
  Validate(AProvider, AKey, AIv, AMode);
  if (AExpectedBytes < 0) or (AExpectedBytes > 1048500) then
    InvalidEv1;
  Plain := nil;
  Vector := nil;
  Crc := nil;
  NextIv := nil;
  try
    if AMode = dfcFull then
    begin
      N := ((AExpectedBytes + 4 + 15) div 16) * 16;
      if Length(AData) <> N then
        InvalidEv1;
      Plain := AProvider.DecryptCbc(AKey, AIv, AData);
      if Length(Plain) <> N then
        InvalidEv1;
      Vector := Copy(Plain, 0, AExpectedBytes);
      SetLength(Vector, AExpectedBytes + 1);
      Vector[AExpectedBytes] := 0;
      Crc := Crc32(Vector);
      if not TCardCrypto.EqualSecret(Crc, Copy(Plain, AExpectedBytes, 4)) then
        InvalidEv1;
      for I := AExpectedBytes + 4 to N - 1 do
        if (Plain[I] <> 0) and not((I = AExpectedBytes + 4) and (Plain[I] = $80))
        then
          InvalidEv1;
      NextIv := Copy(AData, N - 16, 16);
    end
    else
    begin
      if Length(AData) <> AExpectedBytes + 8 then
        InvalidEv1;
      Vector := Copy(AData, 0, AExpectedBytes);
      SetLength(Vector, AExpectedBytes + 1);
      Vector[AExpectedBytes] := 0;
      NextIv := TCardCrypto.CmacChained(AProvider, AKey, AIv, Vector);
      if not TCardCrypto.EqualSecret(Copy(NextIv, 0, 8),
        Copy(AData, AExpectedBytes, 8)) then
        InvalidEv1;
      Plain := Copy(AData, 0, AExpectedBytes);
    end;
    Result := Copy(Plain, 0, AExpectedBytes);
    TCardCrypto.Clear(AIv);
    AIv := NextIv;
    NextIv := nil;
  finally
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Vector);
    TCardCrypto.Clear(Crc);
    TCardCrypto.Clear(NextIv);
  end;
end;

end.
