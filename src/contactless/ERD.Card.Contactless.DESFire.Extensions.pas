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

  /// <summary>One independently owned native ISO application directory frame.</summary>
  TDesfireIsoApplication = record
    /// <summary>Native nonzero 24-bit AID.</summary>
    Aid: Cardinal;
    /// <summary>Native little-endian ISO directory file identifier.</summary>
    IsoFid: Word;
    /// <summary>Independent zero-through-sixteen-byte ISO DF name; empty for an existing unnamed application.</summary>
    DfName: TBytes;
  end;
  /// <summary>Owned bounded ISO application directory; names are independent arrays.</summary>
  TDesfireIsoApplications = array of TDesfireIsoApplication;
  /// <summary>Explicit native ISO file identifiers, independent of native file numbers.</summary>
  TDesfireIsoFileIds = array of Word;
  /// <summary>Native access-right tuples in wire-byte order; first tuple governs ordinary change rights.</summary>
  TDesfireAccessRightSets = array of Word;
  /// <summary>Owned ordinary geometry with optional multiple access-right tuples.</summary>
  TDesfireMultiAccessSettings = record
    /// <summary>Exact acquired native settings bytes.</summary>
    RawBytes: TBytes;
    /// <summary>Independent ordinary settings with the multi-access flag stripped for strict geometry decoding.</summary>
    BaseBytes: TBytes;
    /// <summary>Primary plus zero-through-seven additional native right tuples.</summary>
    Rights: TDesfireAccessRightSets;
  end;
  /// <summary>Owned AES transaction-MAC file metadata; no secret key material.</summary>
  TDesfireTmacSettings = record
    /// <summary>Exact acquired native type-05 settings.</summary>
    RawBytes: TBytes;
    /// <summary>Supported communication, exclude-unauthenticated and optional AES counter-limit flags.</summary>
    FileOption: Byte;
    /// <summary>CommitReaderID/change/read/write nibbles in native wire-byte order.</summary>
    AccessRights: Word;
    /// <summary>Acquired AES TMAC key version; metadata does not prove key possession.</summary>
    KeyVersion: Byte;
    /// <summary>True when the native optional AES thirty-two-bit counter limit is present.</summary>
    CounterLimitEnabled: Boolean;
    /// <summary>Explicit one-through-FFFFFFFF limit when enabled, otherwise zero.</summary>
    CounterLimit: Cardinal;
  end;
  /// <summary>Owned transaction-MAC record; Plain acquisition requires separate offline authenticity verification.</summary>
  TDesfireTmacRecord = record
    /// <summary>Acquired unsigned thirty-two-bit transaction counter.</summary>
    Counter: Cardinal;
    /// <summary>Independent eight-byte transaction MAC; offline verification requires the TMAC key and transaction input.</summary>
    Mac: TBytes;
    /// <summary>True only when acquisition verified a secure-session response MAC; not offline TMAC key validation.</summary>
    SessionProtected: Boolean;
    /// <summary>True only after offline MAC verification with the supplied transaction key, UID and canonical input.</summary>
    KeyVerified: Boolean;
  end;
  /// <summary>Strict bounded extended settings and native creation codecs; no I/O.</summary>
  TDesfireExtensionCodec = class
  public
    /// <summary>Decodes one frame-preserved AID/FID/DF-name directory entry.</summary>
    /// <param name="AFrame">Exact five-byte native identifiers followed by zero-through-sixteen-byte DF name.</param>
    /// <returns>Independent typed directory entry.</returns>
    class function IsoApplication(const AFrame: TBytes): TDesfireIsoApplication; static;
    /// <summary>Decodes unique native little-endian ISO file identifiers.</summary>
    /// <param name="ABytes">Zero-through-sixty-four exact native bytes, without status/MAC.</param>
    /// <returns>Owned explicit FID list.</returns>
    class function IsoFileIds(const ABytes: TBytes): TDesfireIsoFileIds; static;
    /// <summary>Decodes ordinary or multi-access ordinary file settings with exact conditional length.</summary>
    /// <param name="ABytes">Native type 00..04 settings; SDM/TMAC combined layouts are refused.</param>
    /// <returns>Owned raw/base settings and one-through-eight right tuples.</returns>
    class function MultiAccessSettings(const ABytes: TBytes): TDesfireMultiAccessSettings; static;
    /// <summary>Encodes native ordinary/multi-access ChangeFileSettings payload.</summary>
    /// <param name="ACommunication">Native Plain=0, MACed=1 or Full=3 byte.</param>
    /// <param name="ARights">One-through-eight explicit native wire-order tuples.</param>
    /// <returns>Independent complete settings-change body.</returns>
    class function AccessChange(const ACommunication: Byte;
      const ARights: TDesfireAccessRightSets): TBytes; static;
    /// <summary>Decodes exact type-05 AES TMAC settings with an optional thirty-two-bit counter limit.</summary>
    /// <param name="ABytes">Exact six-byte base or ten-byte AES counter-limit settings.</param>
    /// <returns>Owned validated metadata; no key-possession claim.</returns>
    class function TmacSettings(const ABytes: TBytes): TDesfireTmacSettings; static;
    /// <summary>Decodes one complete native transaction counter and MAC.</summary>
    /// <param name="ABytes">Exactly twelve bytes, counter little-endian then eight MAC bytes.</param>
    /// <returns>Owned acquired record; offline TMAC validation is separate.</returns>
    class function TmacRecord(const ABytes: TBytes): TDesfireTmacRecord; static;
    /// <summary>Validates an explicit ISO FID, excluding reserved null/MF/current-directory identifiers.</summary>
    /// <param name="AFid">Explicit FID to create or acquire.</param>
    class procedure ValidateIsoFid(const AFid: Word); static;
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

  /// <summary>AES transaction-MAC derivation, aligned command input and receipt verification; no I/O.</summary>
  /// <remarks>Uses the published AES vectors and TMI rules of MF2DLHX0 section 10.3, with actual command opcodes.
  /// LRP and records whose complete data are not AES-block-aligned require a separate profile.</remarks>
  TDesfireTmacCrypto = class
  public
    /// <summary>Derives AES transaction MAC/encryption keys from the committed next counter and seven-byte UID.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly sixteen supplied transaction-MAC key bytes.</param>
    /// <param name="AUid">Exactly seven explicit real card UID bytes.</param>
    /// <param name="ANextCounter">One-through-FFFFFFFF resulting committed counter; already incremented.</param>
    /// <param name="AEncryption">False uses published 5A MAC vector, true A5 reader-ID encryption vector.</param>
    /// <returns>Independent sixteen-byte derived key; caller must clear it.</returns>
    class function DeriveKey(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextCounter: Cardinal; const AEncryption: Boolean): TBytes; static;
    /// <summary>Appends one supported authenticated data/reader-ID operation to exact aligned transaction input.</summary>
    /// <param name="AInput">Owned-or-borrowed existing aligned canonical input; never changed.</param>
    /// <param name="ACommand">AD/8D data, AB/8B records, 6C/0C/DC/1C values, EB clear or C8 reader ID.</param>
    /// <param name="AHeader">Exact explicit nonzero-count native parameters, excluding command/MAC; implicit all-record/data counts are refused.</param>
    /// <param name="AData">Complete plaintext request/response data; for C8, sixteen transaction-key-encrypted TMRI bytes.</param>
    /// <returns>Independent complete canonical input, bounded to 1048560 bytes.</returns>
    class function AppendInput(const AInput: TBytes; const ACommand: Byte;
      const AHeader, AData: TBytes): TBytes; static;
    /// <summary>Calculates an odd-index truncated AES transaction MAC over exact canonical input.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly sixteen transaction-MAC secret bytes.</param>
    /// <param name="AUid">Exactly seven real UID bytes.</param>
    /// <param name="ANextCounter">Explicit resulting counter, not the previous value.</param>
    /// <param name="AInput">Exact nonempty AES-aligned transaction input.</param>
    /// <returns>Independent eight-byte transaction MAC.</returns>
    class function Mac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextCounter: Cardinal; const AInput: TBytes): TBytes; static;
    /// <summary>Decrypts the previous reader ID from its transaction-key-encrypted TMRI.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly sixteen transaction-MAC key bytes.</param>
    /// <param name="AUid">Exactly seven real UID bytes.</param>
    /// <param name="ANextCounter">Counter for the current transaction, already incremented.</param>
    /// <param name="AEncryptedReaderId">Exactly sixteen transaction-key-encrypted TMRI bytes after secure-session MAC verification.</param>
    /// <returns>Independent sixteen-byte previous reader ID; caller owns and clears it.</returns>
    class function DecryptReaderId(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextCounter: Cardinal; const AEncryptedReaderId: TBytes): TBytes; static;
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
class procedure TDesfireExtensionCodec.ValidateIsoFid(const AFid: Word);
begin
  if (AFid = 0) or (AFid = $FFFF) or (AFid = $3F00) or (AFid = $3FFF) then
    Invalid;
end;

class function TDesfireExtensionCodec.IsoApplication(const AFrame: TBytes): TDesfireIsoApplication;
begin
  Result := Default(TDesfireIsoApplication);
  if (Length(AFrame) < 5) or (Length(AFrame) > 21) then
    Invalid;
  Result.Aid := Cardinal(AFrame[0]) or (Cardinal(AFrame[1]) shl 8) or (Cardinal(AFrame[2]) shl 16);
  if Result.Aid = 0 then
    Invalid;
  Result.IsoFid := Word(AFrame[3]) or (Word(AFrame[4]) shl 8);
  ValidateIsoFid(Result.IsoFid);
  Result.DfName := Copy(AFrame, 5, Length(AFrame) - 5);
end;

class function TDesfireExtensionCodec.IsoFileIds(const ABytes: TBytes): TDesfireIsoFileIds;
var
  I, J: Integer;
begin
  Result := nil;
  if (Length(ABytes) > 64) or (Length(ABytes) mod 2 <> 0) then
    Invalid;
  SetLength(Result, Length(ABytes) div 2);
  for I := 0 to High(Result) do
  begin
    Result[I] := Word(ABytes[I * 2]) or (Word(ABytes[I * 2 + 1]) shl 8);
    ValidateIsoFid(Result[I]);
    for J := 0 to I - 1 do
      if Result[J] = Result[I] then
        Invalid;
  end;
end;

class function TDesfireExtensionCodec.MultiAccessSettings(const ABytes: TBytes): TDesfireMultiAccessSettings;
var
  Base, Count, I: Integer;
begin
  Result := Default(TDesfireMultiAccessSettings);
  if (Length(ABytes) < 7) or (ABytes[0] > 4) or
    not ((ABytes[1] and $7F) in [0, 1, 3]) then
    Invalid;
  Base := 7;
  if ABytes[0] = 2 then Base := 17;
  if ABytes[0] in [3, 4] then Base := 13;
  Count := 0;
  if (ABytes[1] and $80) <> 0 then
  begin
    if Length(ABytes) <= Base then Invalid;
    Count := ABytes[Base];
    if (Count < 1) or (Count > 7) then Invalid;
    if Length(ABytes) <> Base + 1 + Count * 2 then Invalid;
  end
  else if Length(ABytes) <> Base then Invalid;
  Result.RawBytes := CopyBytes(ABytes);
  Result.BaseBytes := Copy(ABytes, 0, Base);
  Result.BaseBytes[1] := Result.BaseBytes[1] and $7F;
  SetLength(Result.Rights, Count + 1);
  Result.Rights[0] := Word(ABytes[2]) or (Word(ABytes[3]) shl 8);
  for I := 0 to Count - 1 do
    Result.Rights[I + 1] := Word(ABytes[Base + 1 + I * 2]) or
      (Word(ABytes[Base + 2 + I * 2]) shl 8);
end;

class function TDesfireExtensionCodec.AccessChange(const ACommunication: Byte;
  const ARights: TDesfireAccessRightSets): TBytes;
var
  I, P: Integer;
begin
  Result := nil;
  if not (ACommunication in [0, 1, 3]) or (Length(ARights) < 1) or
    (Length(ARights) > 8) then Invalid;
  SetLength(Result, 3);
  Result[0] := ACommunication;
  Result[1] := Byte(ARights[0] and $FF);
  Result[2] := Byte(ARights[0] shr 8);
  if Length(ARights) > 1 then
  begin
    Result[0] := Result[0] or $80;
    SetLength(Result, 4 + (Length(ARights) - 1) * 2);
    Result[3] := Byte(Length(ARights) - 1);
    for I := 1 to High(ARights) do
    begin
      P := 4 + (I - 1) * 2;
      Result[P] := Byte(ARights[I] and $FF);
      Result[P + 1] := Byte(ARights[I] shr 8);
    end;
  end;
end;

class function TDesfireExtensionCodec.TmacSettings(const ABytes: TBytes): TDesfireTmacSettings;
begin
  Result := Default(TDesfireTmacSettings);
  if not (Length(ABytes) in [6, 10]) or (ABytes[0] <> 5) or
    not ((ABytes[1] and $CF) in [0, 1, 3]) or (ABytes[4] <> 2) or
    ((ABytes[3] and $F) <> $F) then Invalid;
  Result.CounterLimitEnabled := (ABytes[1] and $20) <> 0;
  if Result.CounterLimitEnabled then
  begin
    if Length(ABytes) <> 10 then Invalid;
    Result.CounterLimit := Cardinal(ABytes[6]) or (Cardinal(ABytes[7]) shl 8) or
      (Cardinal(ABytes[8]) shl 16) or (Cardinal(ABytes[9]) shl 24);
    if Result.CounterLimit = 0 then Invalid;
  end
  else if Length(ABytes) <> 6 then Invalid;
  Result.RawBytes := CopyBytes(ABytes);
  Result.FileOption := ABytes[1];
  Result.AccessRights := Word(ABytes[2]) or (Word(ABytes[3]) shl 8);
  Result.KeyVersion := ABytes[5];
end;

class function TDesfireExtensionCodec.TmacRecord(const ABytes: TBytes): TDesfireTmacRecord;
begin
  Result := Default(TDesfireTmacRecord);
  if Length(ABytes) <> 12 then Invalid;
  Result.Counter := Cardinal(ABytes[0]) or (Cardinal(ABytes[1]) shl 8) or
    (Cardinal(ABytes[2]) shl 16) or (Cardinal(ABytes[3]) shl 24);
  Result.Mac := Copy(ABytes, 4, 8);
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


class function TDesfireTmacCrypto.DeriveKey(const AProvider: ICardAesProvider;
  const AKey, AUid: TBytes; const ANextCounter: Cardinal; const AEncryption: Boolean): TBytes;
var
  Vector: TBytes;
  I: Integer;
begin
  if (AProvider = nil) or (Length(AKey) <> 16) or (Length(AUid) <> 7) or
    (ANextCounter = 0) then Invalid;
  Vector := nil;
  SetLength(Vector, 16);
  Vector[0] := $5A;
  Vector[2] := 1;
  Vector[4] := $80;
  try
    if AEncryption then Vector[0] := $A5;
    for I := 0 to 3 do Vector[5 + I] := Byte((ANextCounter shr (I * 8)) and $FF);
    Move(AUid[0], Vector[9], 7);
    Result := TCardCrypto.Cmac(AProvider, AKey, Vector);
  finally
    TCardCrypto.Clear(Vector);
  end;
end;

class function TDesfireTmacCrypto.AppendInput(const AInput: TBytes;
  const ACommand: Byte; const AHeader, AData: TBytes): TBytes;
var
  Body: TBytes;
  Prefix, Size, Count: Integer;
  procedure FinishBlock;
  begin
    SetLength(Body, ((Length(Body) + 15) div 16) * 16);
  end;
begin
  Result := nil;
  Body := nil;
  if (Length(AInput) mod 16 <> 0) or (Length(AInput) > 1048560) then Invalid;
  try
    case ACommand of
      $AD, $8D, $AB, $8B:
        begin
          if (Length(AHeader) <> 7) or (Length(AData) < 1) or (AHeader[0] > 31) then Invalid;
          Count := Integer(AHeader[4]) or (Integer(AHeader[5]) shl 8) or (Integer(AHeader[6]) shl 16);
          if Count = 0 then Invalid;
          if (ACommand in [$AD, $8D, $8B]) and (Count <> Length(AData)) then Invalid;
          if (ACommand = $AB) and ((Length(AData) mod Count <> 0) or (Length(AData) div Count < 16)) then Invalid;
          if (ACommand in [$AB, $8B]) and (Length(AData) mod 16 <> 0) then Invalid;
          SetLength(Body, 16);
          Body[0] := ACommand;
          Move(AHeader[0], Body[1], 7);
          Prefix := Length(Body);
          SetLength(Body, Prefix + Length(AData));
          Move(AData[0], Body[Prefix], Length(AData));
          FinishBlock;
        end;
      $6C, $0C, $DC, $1C:
        begin
          if (Length(AHeader) <> 1) or (Length(AData) <> 4) then Invalid;
          if AHeader[0] > 31 then Invalid;
          SetLength(Body, 16);
          Body[0] := ACommand; Body[1] := AHeader[0];
          Move(AData[0], Body[2], 4);
        end;
      $EB:
        begin
          if (Length(AHeader) <> 1) or (Length(AData) <> 0) then Invalid;
          if AHeader[0] > 31 then Invalid;
          SetLength(Body, 16);
          Body[0] := ACommand; Body[1] := AHeader[0];
        end;
      $C8:
        begin
          if (Length(AHeader) <> 16) or (Length(AData) <> 16) then Invalid;
          SetLength(Body, 48);
          Body[0] := ACommand;
          Move(AHeader[0], Body[1], 16);
          Move(AData[0], Body[17], 16);
        end;
    else Invalid;
    end;
    Size := Length(AInput) + Length(Body);
    if Size > 1048560 then Invalid;
    SetLength(Result, Size);
    if Length(AInput) > 0 then Move(AInput[0], Result[0], Length(AInput));
    Move(Body[0], Result[Length(AInput)], Length(Body));
  finally
    TCardCrypto.Clear(Body);
  end;
end;

class function TDesfireTmacCrypto.Mac(const AProvider: ICardAesProvider;
  const AKey, AUid: TBytes; const ANextCounter: Cardinal; const AInput: TBytes): TBytes;
var
  Key, Full: TBytes;
  I: Integer;
begin
  if (Length(AInput) < 16) or (Length(AInput) mod 16 <> 0) or (Length(AInput) > 1048560) then Invalid;
  Key := DeriveKey(AProvider, AKey, AUid, ANextCounter, False);
  Full := nil;
  try
    Full := TCardCrypto.Cmac(AProvider, Key, AInput);
    Result := nil;
    SetLength(Result, 8);
    for I := 0 to 7 do Result[I] := Full[I * 2 + 1];
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Full);
  end;
end;

class function TDesfireTmacCrypto.DecryptReaderId(const AProvider: ICardAesProvider;
  const AKey, AUid: TBytes; const ANextCounter: Cardinal; const AEncryptedReaderId: TBytes): TBytes;
var
  Key, Iv: TBytes;
begin
  if Length(AEncryptedReaderId) <> 16 then Invalid;
  Key := DeriveKey(AProvider, AKey, AUid, ANextCounter, True);
  Iv := nil;
  try
    SetLength(Iv, 16);
    Result := AProvider.DecryptCbc(Key, Iv, AEncryptedReaderId);
    if Length(Result) <> 16 then Invalid;
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Iv);
  end;
end;

end.
