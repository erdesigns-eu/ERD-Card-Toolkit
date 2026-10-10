unit ERD.Card.EID.Access;

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
  ERD.Card.Crypto, ERD.Card.Crypto.EAC, ERD.Card.EID.MRZ;

type
  /// <summary>Invalid ICAO access configuration or cryptographic protocol input; contains no document/password bytes.</summary>
  EIcaoAccessError = class(Exception);
  /// <summary>Explicit ICAO BAC or implemented PACE ECDH-GM/AES-128 access profile; no automatic fallback.</summary>
  TIcaoAccessSecurity = (
    /// <summary>MRZ-derived Basic Access Control with two-key Triple DES secure messaging.</summary>
    iasBac,
    /// <summary>PACE version 2, ECDH Generic Mapping, AES-128, parameter 12 or 13.</summary>
    iasPaceGmAes128);
  /// <summary>Explicit PACE password reference; PIN/PUK and national authorization are separate profiles.</summary>
  TIcaoPasswordKind = (
    /// <summary>Validated MRZ access information, reference 1.</summary>
    ipkMrz,
    /// <summary>Six ASCII decimal CAN characters, reference 2.</summary>
    ipkCan);

  /// <summary>Pure ICAO access-key composition through a maintained cryptographic provider.</summary>
  TIcaoAccessCodec = class
  public
    /// <summary>Builds checked document-number/date access information from a complete validated TD1/TD2/TD3 MRZ.</summary>
    /// <param name="AMrz">Full MRZ, optionally CR/LF separated; extended TD1/TD2 numbers are supported.</param>
    /// <returns>Owned ASCII access bytes preserving the printed nine-character number and fillers, or its full extension.</returns>
    class function MrzInformation(const AMrz: UnicodeString): TBytes; static;
    /// <summary>Checks an already constructed MRZ-information or CAN password before acquisition.</summary>
    /// <param name="APassword">Borrowed ASCII bytes; MRZ document/check digit plus birth/expiry/check digits, or six-digit CAN.</param>
    /// <param name="AKind">Explicit password type.</param>
    /// <exception cref="EIcaoAccessError">Alphabet, layout or check digits fail.</exception>
    class procedure ValidatePassword(const APassword: TBytes;
      const AKind: TIcaoPasswordKind); static;
    /// <summary>Derives an ICAO AES-128 or parity-adjusted two-key Triple DES key from an explicit seed/counter.</summary>
    /// <param name="AProvider">Non-nil maintained SHA-1 backend.</param>
    /// <param name="ASeed">Borrowed nonempty seed, at most 64 bytes.</param>
    /// <param name="ACounter">1 encryption, 2 MAC, 3 PACE password encryption.</param>
    /// <param name="ATripleDes">True to apply odd DES parity; false for AES.</param>
    /// <returns>Owned 16-byte key; caller clears it.</returns>
    class function DeriveKey(const AProvider: ICardEacProvider;
      const ASeed: TBytes; const ACounter: Byte; const ATripleDes: Boolean)
      : TBytes; static;
    /// <summary>Calculates ICAO ISO 9797-1 algorithm-3 Retail MAC with method-two padding through native Triple DES.</summary>
    /// <param name="AProvider">Non-nil maintained native backend.</param>
    /// <param name="AKey">16-byte two-key MAC key.</param>
    /// <param name="AMessage">Unpadded borrowed message, zero through 1048560 bytes.</param>
    /// <returns>Owned eight-byte MAC; no supplied data is logged.</returns>
    class function RetailMac(const AProvider: ICardEacProvider;
      const AKey, AMessage: TBytes): TBytes; static;
    /// <summary>Expands a two-key Triple DES key as K1,K2,K1 for the native 24-byte primitive.</summary>
    /// <param name="AKey">16 borrowed bytes.</param>
    /// <returns>Owned 24-byte key.</returns>
    class function ExpandDesKey(const AKey: TBytes): TBytes; static;
    /// <summary>Applies ISO 9797-1 method-two padding, including one extra block for aligned input.</summary>
    /// <param name="AData">Zero through 1048560 borrowed bytes.</param>
    /// <param name="ABlockBytes">Eight or sixteen.</param>
    /// <returns>Owned padded bytes.</returns>
    class function Pad(const AData: TBytes; const ABlockBytes: Integer)
      : TBytes; static;
    /// <summary>Removes exact method-two padding with no guessed plaintext length.</summary>
    /// <param name="AData">Nonempty complete eight/sixteen-byte blocks.</param>
    /// <param name="ABlockBytes">Eight or sixteen.</param>
    /// <returns>Owned plaintext, possibly empty.</returns>
    class function Unpad(const AData: TBytes; const ABlockBytes: Integer)
      : TBytes; static;
  end;

implementation

procedure InvalidAccess;
begin
  raise EIcaoAccessError.Create('Invalid ICAO access protocol data.');
end;

class function TIcaoAccessCodec.MrzInformation
  (const AMrz: UnicodeString): TBytes;
var
  Identity: TMrzIdentity;
  Number, Dates, Text: UnicodeString;
  Digit: WideChar;
  I: Integer;
begin
  Identity := TMrzCodec.Decode(AMrz);
  case Identity.Format of
    mfTD1:
      begin
        Number := Copy(Identity.Raw, 6, 9);
        Digit := Identity.Raw[15];
        Dates := Copy(Identity.Raw, 31, 7) + Copy(Identity.Raw, 39, 7);
      end;
    mfTD2:
      begin
        Number := Copy(Identity.Raw, 37, 9);
        Digit := Identity.Raw[46];
        Dates := Copy(Identity.Raw, 50, 7) + Copy(Identity.Raw, 58, 7);
      end;
    mfTD3:
      begin
        Number := Copy(Identity.Raw, 45, 9);
        Digit := Identity.Raw[54];
        Dates := Copy(Identity.Raw, 58, 7) + Copy(Identity.Raw, 66, 7);
      end;
  else
    raise EIcaoAccessError.Create('Invalid ICAO access protocol data.');
  end;
  if Digit = '<' then
  begin
    Number := Identity.DocumentNumber;
    Digit := TMrzCodec.CheckDigit(Number);
  end;
  Text := Number + Digit + Dates;
  Result := nil;
  SetLength(Result, Length(Text));
  for I := 1 to Length(Text) do
    Result[I - 1] := Ord(Text[I]);
  ValidatePassword(Result, ipkMrz);
end;

class procedure TIcaoAccessCodec.ValidatePassword(const APassword: TBytes;
  const AKind: TIcaoPasswordKind);
var
  I, DocumentLength: Integer;
  Text: UnicodeString;
begin
  if (Ord(AKind) < 0) or (Ord(AKind) > 1) or (Length(APassword) > 64) then
    InvalidAccess;
  if AKind = ipkCan then
  begin
    if Length(APassword) <> 6 then
      InvalidAccess;
    for I := 0 to 5 do
      if not(APassword[I] in [Ord('0') .. Ord('9')]) then
        InvalidAccess;
    Exit;
  end;
  if Length(APassword) < 16 then
    InvalidAccess;
  Text := '';
  SetLength(Text, Length(APassword));
  for I := 0 to High(APassword) do
  begin
    if not(APassword[I] in [Ord('A') .. Ord('Z'), Ord('0') .. Ord('9'),
      Ord('<')]) then
      InvalidAccess;
    Text[I + 1] := WideChar(APassword[I]);
  end;
  DocumentLength := Length(Text) - 15;
  for I := DocumentLength + 2 to Length(Text) do
    if not(APassword[I - 1] in [Ord('0') .. Ord('9'), Ord('<')]) then
      InvalidAccess;
  if (DocumentLength < 1) or (DocumentLength > 30) or
    (TMrzCodec.CheckDigit(Copy(Text, 1, DocumentLength)) <>
    Text[DocumentLength + 1]) or
    (TMrzCodec.CheckDigit(Copy(Text, DocumentLength + 2, 6)) <>
    Text[DocumentLength + 8]) or
    (TMrzCodec.CheckDigit(Copy(Text, DocumentLength + 9, 6)) <>
    Text[DocumentLength + 15]) then
    InvalidAccess;
end;

class function TIcaoAccessCodec.DeriveKey(const AProvider: ICardEacProvider;
  const ASeed: TBytes; const ACounter: Byte; const ATripleDes: Boolean): TBytes;
var
  Input, Digest: TBytes;
  I, J, Ones: Integer;
begin
  Result := nil;
  if (AProvider = nil) or (Length(ASeed) < 1) or (Length(ASeed) > 64) or
    not(ACounter in [1, 2, 3]) then
    InvalidAccess;
  Input := Copy(ASeed, 0, Length(ASeed));
  SetLength(Input, Length(Input) + 4);
  Input[High(Input)] := ACounter;
  try
    Digest := AProvider.Sha1(Input);
    if Length(Digest) <> 20 then
      InvalidAccess;
    Result := Copy(Digest, 0, 16);
    if ATripleDes then
      for I := 0 to 15 do
      begin
        Result[I] := Result[I] and $FE;
        Ones := 0;
        for J := 1 to 7 do
          Inc(Ones, (Result[I] shr J) and 1);
        if Ones mod 2 = 0 then
          Result[I] := Result[I] or 1;
      end;
  finally
    TCardCrypto.Clear(Input);
    TCardCrypto.Clear(Digest);
  end;
end;

class function TIcaoAccessCodec.ExpandDesKey(const AKey: TBytes): TBytes;
begin
  Result := nil;
  if Length(AKey) <> 16 then
    InvalidAccess;
  SetLength(Result, 24);
  Move(AKey[0], Result[0], 16);
  Move(AKey[0], Result[16], 8);
end;

class function TIcaoAccessCodec.Pad(const AData: TBytes;
  const ABlockBytes: Integer): TBytes;
begin
  Result := nil;
  if not(ABlockBytes in [8, 16]) or (Length(AData) > 1048560) then
    InvalidAccess;
  SetLength(Result, ((Length(AData) div ABlockBytes) + 1) * ABlockBytes);
  if Length(AData) > 0 then
    Move(AData[0], Result[0], Length(AData));
  Result[Length(AData)] := $80;
end;

class function TIcaoAccessCodec.Unpad(const AData: TBytes;
  const ABlockBytes: Integer): TBytes;
var
  Last: Integer;
begin
  Result := nil;
  if not(ABlockBytes in [8, 16]) or (Length(AData) = 0) or
    (Length(AData) > 1048576) or (Length(AData) mod ABlockBytes <> 0) then
    InvalidAccess;
  Last := High(AData);
  while (Last >= 0) and (AData[Last] = 0) do
    Dec(Last);
  if (Last < 0) or (AData[Last] <> $80) or (Length(AData) - Last > ABlockBytes)
  then
    InvalidAccess;
  Result := Copy(AData, 0, Last);
end;

class function TIcaoAccessCodec.RetailMac(const AProvider: ICardEacProvider;
  const AKey, AMessage: TBytes): TBytes;
var
  Padded, SingleKey, Zero, Buffer: TBytes;
  I: Integer;
begin
  Result := nil;
  if (AProvider = nil) or (Length(AKey) <> 16) then
    InvalidAccess;
  Padded := Pad(AMessage, 8);
  SingleKey := nil;
  Zero := nil;
  Buffer := nil;
  try
    SetLength(SingleKey, 24);
    SetLength(Zero, 8);
    for I := 0 to 2 do
      Move(AKey[0], SingleKey[I * 8], 8);
    Buffer := AProvider.TripleDesCbc(SingleKey, Zero, Padded, True);
    if Length(Buffer) <> Length(Padded) then
      InvalidAccess;
    Result := Copy(Buffer, Length(Buffer) - 8, 8);
    for I := 0 to 2 do
      Move(AKey[8], SingleKey[I * 8], 8);
    TCardCrypto.Clear(Buffer);
    Buffer := AProvider.TripleDesCbc(SingleKey, Zero, Result, False);
    if Length(Buffer) <> 8 then
      InvalidAccess;
    for I := 0 to 2 do
      Move(AKey[0], SingleKey[I * 8], 8);
    TCardCrypto.Clear(Result);
    Result := AProvider.TripleDesCbc(SingleKey, Zero, Buffer, True);
    if Length(Result) <> 8 then
      InvalidAccess;
  finally
    TCardCrypto.Clear(Padded);
    TCardCrypto.Clear(SingleKey);
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Buffer);
  end;
end;

end.
