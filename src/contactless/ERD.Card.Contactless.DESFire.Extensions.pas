unit ERD.Card.Contactless.DESFire.Extensions;

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
  ERD.Card.Bytes, ERD.Card.Crypto;

type
  /// <summary>Invalid extended DESFire settings or an unsupported explicit profile.</summary>
  EDesfireExtensionError = class(Exception);

  /// <summary>Owned standard-data settings with optional EV3 secure dynamic messaging.</summary>
  /// <remarks>Offsets address the complete native file, including NDEF NLEN where present; no URI offsets are guessed.</remarks>
  TDesfireSdmSettings = record
    /// <summary>Independent complete GetFileSettings bytes; assignment shares arrays.</summary>
    RawBytes: TBytes;
    /// <summary>Native standard-data file length, one through FFFFFF.</summary>
    FileBytes: Integer;
    /// <summary>Complete native file option; ordinary Plain/MACed/Full, or SDM on a Plain standard file.</summary>
    FileOption: Byte;
    /// <summary>Native read/write/change nibbles in their two wire bytes.</summary>
    AccessRights: Word;
    /// <summary>SDM option bits: UID, counter, counter limit, encrypted data and ASCII.</summary>
    Options: Byte;
    /// <summary>Native SDM access rights; high RFU nibble must be F.</summary>
    SdmAccessRights: Word;
    /// <summary>Plain UID mirror offset; relevant only for free metadata and UID mirroring.</summary>
    UidOffset: Integer;
    /// <summary>Plain counter mirror offset; FFFFFF explicitly suppresses the counter mirror.</summary>
    CounterOffset: Integer;
    /// <summary>Encrypted PICC metadata offset, for a supplied metadata key.</summary>
    PiccOffset: Integer;
    /// <summary>Beginning of exact dynamic file bytes authenticated by SDM.</summary>
    MacInputOffset: Integer;
    /// <summary>Encrypted file-data mirror offset.</summary>
    EncOffset: Integer;
    /// <summary>Mirrored encrypted-data length; ASCII lengths count encoded characters.</summary>
    EncLength: Integer;
    /// <summary>SDM MAC mirror offset; excluded from its own MAC input.</summary>
    MacOffset: Integer;
    /// <summary>Explicit maximum 24-bit read counter when its option is enabled.</summary>
    CounterLimit: Integer;
  end;

  /// <summary>Independent decoded AES PICC metadata; it needs MAC verification to establish authenticity.</summary>
  TDesfireSdmPiccData = record
    /// <summary>Exact decoded PICC data tag.</summary>
    Tag: Byte;
    /// <summary>Mirrored seven-byte UID, or empty when disabled.</summary>
    Uid: TBytes;
    /// <summary>Mirrored little-endian read counter, or minus one when disabled.</summary>
    ReadCounter: Integer;
  end;

  /// <summary>Strict bounded extended settings and native creation codecs; no I/O.</summary>
  TDesfireExtensionCodec = class
  public
    /// <summary>Validates ordinary or explicit key-set-enabled GetKeySettings framing.</summary>
    /// <param name="ABytes">Exact two, three or seven native bytes; no ISO VC/capability data is inferred.</param>
    /// <exception cref="EDesfireExtensionError">Key count/type, flags or key-set geometry is invalid.</exception>
    class procedure ValidateApplicationSettings(const ABytes: TBytes); static;
    /// <summary>Builds a native AES application header with multiple key sets.</summary>
    /// <param name="AAid">Nonzero 24-bit application identifier.</param>
    /// <param name="ASettings">Explicit valid application key policy.</param>
    /// <param name="AKeyCount">One through fourteen keys per set.</param>
    /// <param name="ASetCount">Two through sixteen total native key sets.</param>
    /// <param name="ASetVersion">Initial active key-set version.</param>
    /// <param name="ARollKey">Explicit roll-key selector zero through seven, within the key count.</param>
    /// <returns>Independent ten-byte native CreateApplication header.</returns>
    class function ApplicationHeader(const AAid: Cardinal;
      const ASettings, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte): TBytes; static;
    /// <summary>Decodes a complete standard-data settings response, including conditional SDM fields.</summary>
    /// <param name="ABytes">Exact acquired bytes, with no native status or response MAC.</param>
    /// <returns>Independent validated settings; unsupported multi-right/TMAC extensions are refused.</returns>
    class function DecodeSdmSettings(const ABytes: TBytes): TDesfireSdmSettings; static;
    /// <summary>Validates and encodes standard-data settings with bounded, nonoverlapping mirror regions.</summary>
    /// <param name="ASettings">Explicit file geometry, access nibbles and conditional SDM fields.</param>
    /// <returns>Complete expected GetFileSettings bytes; no credentials or file data.</returns>
    class function EncodeSdmSettings(const ASettings: TDesfireSdmSettings): TBytes; static;
    /// <summary>Validates supported SetConfiguration option framing without I/O.</summary>
    /// <param name="AOption">Explicit PICC 00, ATS 02, SAK 03, secure-messaging 04 or value-file 09.</param>
    /// <param name="AData">Exact native option data; no implicit irreversible bit changes.</param>
    class procedure ValidateConfiguration(const AOption: Byte; const AData: TBytes); static;
  end;

  /// <summary>AES-128 SDM calculations shared by the explicit EV3 AES SDM profile.</summary>
  /// <remarks>Caller supplies exact mirrored bytes and offsets. A valid MAC does not establish freshness; track counters per UID.</remarks>
  TDesfireSdmCrypto = class
  public
    /// <summary>Decrypts one metadata block with a supplied AES metadata-read key and zero IV.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen caller-owned secret bytes.</param>
    /// <param name="ACipher">Sixteen encrypted PICC bytes, already decoded from ASCII if needed.</param>
    /// <returns>Independent UID/counter metadata, not yet authenticated.</returns>
    class function DecodePicc(const AProvider: ICardAesProvider;
      const AKey, ACipher: TBytes): TDesfireSdmPiccData; static;
    /// <summary>Derives an SDM file-read AES session key from mirrored UID/counter.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen caller-owned file-read key bytes.</param>
    /// <param name="AUid">Zero or seven mirrored UID bytes.</param>
    /// <param name="ACounter">Mirrored 24-bit counter, or minus one when disabled.</param>
    /// <param name="AEncryption">True for C33C encryption vector; false for 3CC3 MAC vector.</param>
    /// <returns>Independent secret AES key; caller must clear it.</returns>
    class function DeriveKey(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ACounter: Integer; const AEncryption: Boolean): TBytes; static;
    /// <summary>Calculates the eight-byte odd-index truncated SDM MAC.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied file-read secret bytes.</param>
    /// <param name="AUid">Zero or seven mirrored UID bytes.</param>
    /// <param name="ACounter">Mirrored counter, or minus one when disabled.</param>
    /// <param name="AInput">Exact dynamic file slice before its MAC field; no text normalization.</param>
    /// <returns>Independent eight-byte SDM MAC.</returns>
    class function Mac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ACounter: Integer; const AInput: TBytes): TBytes; static;
    /// <summary>Checks every byte of a supplied eight-byte SDM MAC.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied file-read secret bytes.</param>
    /// <param name="AUid">Zero or seven mirrored UID bytes.</param>
    /// <param name="ACounter">Mirrored counter, or minus one when disabled.</param>
    /// <param name="AInput">Exact dynamic MAC input bytes.</param>
    /// <param name="AMac">Exactly eight acquired MAC bytes.</param>
    /// <returns>True only for an exact cryptographic match; malformed size is refused.</returns>
    class function VerifyMac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ACounter: Integer; const AInput, AMac: TBytes): Boolean; static;
    /// <summary>Decrypts encrypted SDM file data after the caller has verified its MAC.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied file-read secret bytes.</param>
    /// <param name="AUid">Exactly seven mirrored UID bytes.</param>
    /// <param name="ACounter">Mirrored 24-bit counter.</param>
    /// <param name="ACipher">Positive complete AES blocks; ASCII must already be decoded.</param>
    /// <returns>Independent complete plaintext, retaining native padding for the application's declared length.</returns>
    class function DecryptFile(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ACounter: Integer; const ACipher: TBytes): TBytes; static;
  end;

implementation

procedure Invalid;
begin
  raise EDesfireExtensionError.Create('Invalid extended DESFire profile or data.');
end;
procedure Put24(var B: TBytes; const N: Integer);
var P: Integer;
begin
  if (N < 0) or (N > $FFFFFF) then Invalid;
  P := Length(B); SetLength(B,P+3);
  B[P] := Byte(N and $FF); B[P+1] := Byte((N shr 8) and $FF); B[P+2] := Byte(N shr 16);
end;
function Get24(const B: TBytes; var P: Integer): Integer;
begin
  if (P < 0) or (P > Length(B)-3) then Invalid;
  Result := Integer(B[P]) or (Integer(B[P+1]) shl 8) or (Integer(B[P+2]) shl 16); Inc(P,3);
end;
class procedure TDesfireExtensionCodec.ValidateApplicationSettings(const ABytes: TBytes);
var N: Integer;
begin
  if not (Length(ABytes) in [2,3,7]) then Invalid;
  N := ABytes[1] and $F;
  if (N < 1) or (N > 14) or ((ABytes[1] and $C0) = $C0) or
    (((ABytes[0] shr 4) < 14) and ((ABytes[0] shr 4) >= N)) then Invalid;
  if (ABytes[1] and $10) = 0 then begin if Length(ABytes) <> 2 then Invalid; Exit; end;
  if Length(ABytes) < 3 then Invalid;
  if (ABytes[2] and $F8) <> 0 then Invalid;
  if (ABytes[2] and 1) = 0 then begin if Length(ABytes) <> 3 then Invalid; Exit; end;
  if (Length(ABytes) <> 7) or (ABytes[4] < 2) or (ABytes[4] > 16) or
    not (ABytes[5] in [16,24]) or ((ABytes[6] and $F8) <> 0) or ((ABytes[6] and 7) >= N) then Invalid;
end;
class function TDesfireExtensionCodec.ApplicationHeader(const AAid: Cardinal;
  const ASettings, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte): TBytes;
begin
  if (AAid = 0) or (AAid > $FFFFFF) or (AKeyCount < 1) or (AKeyCount > 14) or
    (ASetCount < 2) or (ASetCount > 16) or (ARollKey > 7) or (ARollKey >= AKeyCount) or
    (((ASettings shr 4) < 14) and ((ASettings shr 4) >= AKeyCount)) then Invalid;
  Result := nil; Put24(Result,Integer(AAid)); SetLength(Result,9);
  Result[3] := ASettings; Result[4] := $90 or AKeyCount; Result[5] := 1;
  Result[6] := ASetVersion; Result[7] := ASetCount; Result[8] := 16;
  // AppKeySetSett is a separate byte after MaxKeySize.
  SetLength(Result,10); Result[9] := ARollKey;
end;
class function TDesfireExtensionCodec.EncodeSdmSettings(const ASettings: TDesfireSdmSettings): TBytes;
var S: TDesfireSdmSettings; Meta, FileKey, Width, Count, I, J: Integer;
  Starts, Sizes: array[0..4] of Integer;
  procedure Region(const O,L: Integer);
  begin
    if (O < 0) or (L < 1) or (O > S.FileBytes-L) or (Count >= 5) then Invalid;
    Starts[Count] := O; Sizes[Count] := L; Inc(Count);
  end;
begin
  S := ASettings; Count := 0;
  if (S.FileBytes < 1) or (S.FileBytes > $FFFFFF) or ((S.FileOption and $BC) <> 0) or
    ((S.FileOption and 3) = 2) then Invalid;
  Result := nil; SetLength(Result,4); Result[0] := 0; Result[1] := S.FileOption;
  Result[2] := Byte(S.AccessRights and $FF); Result[3] := Byte(S.AccessRights shr 8); Put24(Result,S.FileBytes);
  if (S.FileOption and $40) = 0 then Exit;
  if (S.FileOption and 3) <> 0 then Invalid; // Explicit SDM profile requires Plain file communication.
  if (S.Options and $0E) <> 0 then Invalid;
  if (S.SdmAccessRights and $F0) <> $F0 then Invalid;
  Meta := (S.SdmAccessRights shr 12) and $F; FileKey := (S.SdmAccessRights shr 8) and $F;
  if FileKey = 14 then Invalid;
  Width := 1; if (S.Options and 1) <> 0 then Width := 2;
  SetLength(Result,10); Result[7] := S.Options;
  Result[8] := Byte(S.SdmAccessRights and $FF); Result[9] := Byte(S.SdmAccessRights shr 8);
  if ((S.Options and $30) <> 0) and ((S.Options and $40) = 0) then Invalid;
  if ((S.Options and $10) <> 0) and (((S.Options and $C0) <> $C0) or (FileKey = 15)) then Invalid;
  if Meta = 14 then begin
    if (S.Options and $80) <> 0 then begin Region(S.UidOffset,7*Width); Put24(Result,S.UidOffset); end;
    if (S.Options and $40) <> 0 then begin
      if S.CounterOffset <> $FFFFFF then Region(S.CounterOffset,3*Width);
      Put24(Result,S.CounterOffset);
    end;
  end else if Meta < 14 then begin Region(S.PiccOffset,16*Width); Put24(Result,S.PiccOffset); end;
  if FileKey <> 15 then begin
    if (S.MacInputOffset < 0) or (S.MacInputOffset > S.MacOffset) then Invalid;
    Put24(Result,S.MacInputOffset);
    if (S.Options and $10) <> 0 then begin
      if (S.EncLength < 16*Width) or (S.EncLength mod (16*Width) <> 0) or
        (S.EncOffset < S.MacInputOffset) or (S.EncOffset > S.MacOffset-S.EncLength) then Invalid;
      Region(S.EncOffset,S.EncLength); Put24(Result,S.EncOffset); Put24(Result,S.EncLength);
    end;
    Region(S.MacOffset,8*Width); Put24(Result,S.MacOffset);
  end;
  if (S.Options and $20) <> 0 then Put24(Result,S.CounterLimit);
  for I := 0 to Count-1 do for J := I+1 to Count-1 do
    if (Starts[I] < Starts[J]+Sizes[J]) and (Starts[J] < Starts[I]+Sizes[I]) then Invalid;
end;
class function TDesfireExtensionCodec.DecodeSdmSettings(const ABytes: TBytes): TDesfireSdmSettings;
var P, Meta, FileKey: Integer; Encoded: TBytes;
begin
  Result := Default(TDesfireSdmSettings);
  if (Length(ABytes) < 7) or (ABytes[0] <> 0) then Invalid;
  Result.FileOption := ABytes[1]; Result.AccessRights := Word(ABytes[2]) or (Word(ABytes[3]) shl 8);
  P := 4; Result.FileBytes := Get24(ABytes,P);
  if (Result.FileOption and $40) <> 0 then begin
    if Length(ABytes) < 10 then Invalid;
    Result.Options := ABytes[7]; Result.SdmAccessRights := Word(ABytes[8]) or (Word(ABytes[9]) shl 8); P := 10;
    Meta := (Result.SdmAccessRights shr 12) and 15; FileKey := (Result.SdmAccessRights shr 8) and 15;
    if Meta = 14 then begin
      if (Result.Options and $80) <> 0 then Result.UidOffset := Get24(ABytes,P);
      if (Result.Options and $40) <> 0 then Result.CounterOffset := Get24(ABytes,P);
    end else if Meta < 14 then Result.PiccOffset := Get24(ABytes,P);
    if FileKey <> 15 then begin
      Result.MacInputOffset := Get24(ABytes,P);
      if (Result.Options and $10) <> 0 then begin Result.EncOffset := Get24(ABytes,P); Result.EncLength := Get24(ABytes,P); end;
      Result.MacOffset := Get24(ABytes,P);
    end;
    if (Result.Options and $20) <> 0 then Result.CounterLimit := Get24(ABytes,P);
  end;
  if P <> Length(ABytes) then Invalid;
  Encoded := EncodeSdmSettings(Result);
  if not BytesEqual(Encoded,ABytes) then Invalid;
  Result.RawBytes := CopyBytes(ABytes);
end;
class procedure TDesfireExtensionCodec.ValidateConfiguration(const AOption: Byte; const AData: TBytes);
var Minimum, Maximum, Value: Int64; Required: Integer;
  function Signed32(const P: Integer): Int64;
  begin
    Result := Int64(AData[P]) or (Int64(AData[P+1]) shl 8) or
      (Int64(AData[P+2]) shl 16) or (Int64(AData[P+3]) shl 24);
    if (AData[P+3] and $80) <> 0 then Dec(Result,Int64(4294967296));
  end;
begin
  case AOption of
    0: if (Length(AData) <> 1) or ((AData[0] and $F0) <> 0) then Invalid;
    2: begin
      if (Length(AData) < 2) or (Length(AData) > 20) or (AData[0] <> Length(AData)) or
        ((AData[1] and $80) <> 0) or ((AData[1] and $F) > 8) then Invalid;
      Required := 2;
      if (AData[1] and $10) <> 0 then Inc(Required);
      if (AData[1] and $20) <> 0 then Inc(Required);
      if (AData[1] and $40) <> 0 then Inc(Required);
      if Length(AData) < Required then Invalid;
    end;
    3: if Length(AData) <> 2 then Invalid;
    4: if (Length(AData) <> 2) or (AData[0] <> 0) or ((AData[1] and $F8) <> 0) then Invalid;
    9: begin
      if (Length(AData) <> 14) or (AData[0] > 31) or ((AData[13] and $FC) <> 0) then Invalid;
      Minimum := Signed32(1); Maximum := Signed32(5); Value := Signed32(9);
      if (Minimum > Maximum) or (Value < Minimum) or (Value > Maximum) then Invalid;
    end;
  else Invalid; end;
end;
class function TDesfireSdmCrypto.DecodePicc(const AProvider: ICardAesProvider;
  const AKey, ACipher: TBytes): TDesfireSdmPiccData;
var Plain, Zero: TBytes; P: Integer;
begin
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(ACipher) <> 16) then Invalid;
  Plain := nil; SetLength(Zero,16);
  Result := Default(TDesfireSdmPiccData); Result.ReadCounter := -1;
  try
    Plain := AProvider.DecryptCbc(AKey,Zero,ACipher); if Length(Plain) <> 16 then Invalid;
    Result.Tag := Plain[0]; if (Plain[0] and $30) <> 0 then Invalid; P := 1;
    if (Plain[0] and $80) <> 0 then begin if (Plain[0] and 15) <> 7 then Invalid; Result.Uid := Copy(Plain,P,7); Inc(P,7); end
    else if (Plain[0] and 15) <> 0 then Invalid;
    if (Plain[0] and $40) <> 0 then Result.ReadCounter := Get24(Plain,P);
  finally TCardCrypto.Clear(Plain); end;
end;
class function TDesfireSdmCrypto.DeriveKey(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ACounter: Integer; const AEncryption: Boolean): TBytes;
var V: TBytes; P,I: Integer;
begin
  if (AProvider = nil) or (Length(AKey) <> 16) or not (Length(AUid) in [0,7]) or
    (ACounter < -1) or (ACounter > $FFFFFF) then Invalid;
  if AEncryption and ((Length(AUid) <> 7) or (ACounter < 0)) then Invalid;
  V := HexToBytes('3CC300010080'); if AEncryption then begin V[0] := $C3; V[1] := $3C; end;
  P := Length(V); SetLength(V,P+Length(AUid)); for I := 0 to High(AUid) do V[P+I] := AUid[I];
  if ACounter >= 0 then Put24(V,ACounter); SetLength(V,16);
  try Result := TCardCrypto.Cmac(AProvider,AKey,V); finally TCardCrypto.Clear(V); end;
end;
class function TDesfireSdmCrypto.Mac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ACounter: Integer; const AInput: TBytes): TBytes;
var Key, Full: TBytes; I: Integer;
begin
  Key := nil; Full := nil;
  try
    Key := DeriveKey(AProvider,AKey,AUid,ACounter,False); Full := TCardCrypto.Cmac(AProvider,Key,AInput);
    Result := nil; SetLength(Result,8); for I := 0 to 7 do Result[I] := Full[I*2+1];
  finally TCardCrypto.Clear(Key); TCardCrypto.Clear(Full); end;
end;
class function TDesfireSdmCrypto.VerifyMac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ACounter: Integer; const AInput, AMac: TBytes): Boolean;
var Expected: TBytes;
begin
  if Length(AMac) <> 8 then Invalid;
  Expected := Mac(AProvider,AKey,AUid,ACounter,AInput);
  try Result := TCardCrypto.EqualSecret(Expected,AMac); finally TCardCrypto.Clear(Expected); end;
end;
class function TDesfireSdmCrypto.DecryptFile(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ACounter: Integer; const ACipher: TBytes): TBytes;
var Key, V, Iv, Zero: TBytes; I: Integer;
begin
  if (Length(ACipher) = 0) or (Length(ACipher) mod 16 <> 0) or (Length(ACipher) > 1048576) then Invalid;
  Key := nil; Iv := nil; SetLength(V,16); SetLength(Zero,16);
  try
    Key := DeriveKey(AProvider,AKey,AUid,ACounter,True);
    for I := 0 to 2 do V[I] := Byte((ACounter shr (8*I)) and $FF);
    Iv := AProvider.EncryptCbc(Key,Zero,V); Result := AProvider.DecryptCbc(Key,Iv,ACipher);
    if Length(Result) <> Length(ACipher) then Invalid;
  finally TCardCrypto.Clear(Key); TCardCrypto.Clear(Iv); end;
end;

end.
