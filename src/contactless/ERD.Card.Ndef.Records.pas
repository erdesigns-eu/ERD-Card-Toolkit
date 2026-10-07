unit ERD.Card.Ndef.Records;

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
  ERD.Card.Ndef;

type
  /// <summary>Decoded NFC Forum Text RTD with strict Unicode validation.</summary>
  TNdefText = record
    /// <summary>ASCII language code from the record, without locale conversion.</summary>
    Language: UnicodeString;
    /// <summary>Decoded text, preserving spelling and embedded characters.</summary>
    Text: UnicodeString;
    /// <summary>True when the source uses UTF-16 instead of UTF-8.</summary>
    Utf16: Boolean;
  end;
  /// <summary>Text, URI, MIME, external and one-level Smart Poster record helpers.</summary>
  /// <remarks>URI values are data only: no syntax validation, navigation, scheme authorization or URL normalization.
  /// Unknown Smart Poster child records are preserved. Nested Smart Posters are rejected.</remarks>
  TNdefRecords = class
  public
    /// <summary>Checks a logical record's TNF and exact type bytes.</summary>
    /// <param name="ARecord">Logical record to inspect.</param>
    /// <param name="ATnf">Expected type-name format.</param>
    /// <param name="AType">Expected ASCII type spelling, case sensitive.</param>
    /// <returns>True if both type fields match.</returns>
    /// <exception cref="ENdefError">Expected type is non-ASCII or exceeds 255 bytes.</exception>
    class function IsType(const ARecord: TNdefRecord; const ATnf: TNdefTypeNameFormat;
      const AType: UnicodeString): Boolean; static;
    /// <summary>Builds a Text RTD using UTF-8 or BOM-prefixed big-endian UTF-16.</summary>
    /// <param name="AText">Valid UTF-16 application string.</param>
    /// <param name="ALanguage">Zero through 63 ASCII letters, digits or hyphens; no BCP 47 registry lookup.</param>
    /// <param name="AUtf16">True for UTF-16; default uses UTF-8.</param>
    /// <returns>Independent well-known T record.</returns>
    /// <exception cref="ENdefError">Text, language or payload bounds are invalid.</exception>
    class function Text(const AText, ALanguage: UnicodeString;
      const AUtf16: Boolean = False): TNdefRecord; static;
    /// <summary>Decodes a Text RTD without replacing malformed Unicode.</summary>
    /// <param name="ARecord">Well-known T record.</param>
    /// <returns>Text, language and source encoding.</returns>
    /// <exception cref="ENdefError">Status, language, length, UTF-8 or UTF-16 is invalid.</exception>
    class function DecodeText(const ARecord: TNdefRecord): TNdefText; static;
    /// <summary>Builds a URI RTD using the longest matching standard prefix.</summary>
    /// <param name="AUri">Nonempty valid Unicode URI text; scheme spelling is preserved.</param>
    /// <returns>Independent well-known U record.</returns>
    /// <exception cref="ENdefError">Text is empty, malformed or oversized.</exception>
    class function Uri(const AUri: UnicodeString): TNdefRecord; static;
    /// <summary>Expands one of the 36 standard URI prefixes and decodes strict UTF-8.</summary>
    /// <param name="ARecord">Well-known U record.</param>
    /// <returns>Nonempty URI text without navigation or normalization.</returns>
    /// <exception cref="ENdefError">Type, prefix, payload or Unicode is invalid.</exception>
    class function DecodeUri(const ARecord: TNdefRecord): UnicodeString; static;
    /// <summary>Builds a MIME record with a validated bare ASCII media type.</summary>
    /// <param name="AMediaType">Type/subtype tokens without parameters; ASCII lowercased.</param>
    /// <param name="APayload">Opaque application bytes, copied.</param>
    /// <returns>Independent MIME record.</returns>
    /// <exception cref="ENdefError">Type tokens or payload bounds are invalid.</exception>
    class function Mime(const AMediaType: UnicodeString; const APayload: TBytes): TNdefRecord; static;
    /// <summary>Builds a lowercase external domain:type record.</summary>
    /// <param name="ADomain">Nonempty ASCII domain labels, without a scheme or port.</param>
    /// <param name="AType">Nonempty ASCII token identifying the external type.</param>
    /// <param name="APayload">Opaque application bytes, copied.</param>
    /// <returns>Independent external record.</returns>
    /// <exception cref="ENdefError">Domain, type or payload bounds are invalid.</exception>
    class function External(const ADomain, AType: UnicodeString; const APayload: TBytes): TNdefRecord; static;
    /// <summary>Encodes a validated Smart Poster child message.</summary>
    /// <param name="AChildren">Exactly one URI, optional distinct-language titles/action/size/type and opaque children.</param>
    /// <returns>Independent well-known Sp record containing one complete NDEF message.</returns>
    /// <exception cref="ENdefError">Child semantics or message bounds are invalid.</exception>
    class function SmartPoster(const AChildren: TNdefMessage): TNdefRecord; static;
    /// <summary>Decodes and validates one level of Smart Poster children.</summary>
    /// <param name="ARecord">Well-known Sp record.</param>
    /// <returns>Independent child records, including unknown extensions.</returns>
    /// <exception cref="ENdefError">Nested framing or child semantics are invalid.</exception>
    class function DecodeSmartPoster(const ARecord: TNdefRecord): TNdefMessage; static;
  end;

implementation

uses ERD.Card.Bytes;

const
  UriPrefixes: array[0..35] of UnicodeString = ('', 'http://www.', 'https://www.',
    'http://', 'https://', 'tel:', 'mailto:', 'ftp://anonymous:anonymous@',
    'ftp://ftp.', 'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
    'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:', 'pop:', 'sip:', 'sips:',
    'tftp:', 'btspp://', 'btl2cap://', 'btgoep://', 'tcpobex://', 'irdaobex://',
    'file://', 'urn:epc:id:', 'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:',
    'urn:epc:', 'urn:nfc:');

procedure Fail;
begin raise ENdefError.Create('Invalid or unsupported NDEF record data.'); end;

procedure ValidateUnicode(const S: UnicodeString);
var I, C: Integer;
begin
  if Length(S) > NdefMaxMessageBytes then Fail;
  I := 1;
  while I <= Length(S) do
  begin
    C := Ord(S[I]); Inc(I);
    if (C >= $D800) and (C <= $DBFF) then
    begin
      if I > Length(S) then Fail;
      C := Ord(S[I]); Inc(I);
      if (C < $DC00) or (C > $DFFF) then Fail;
    end
    else if (C >= $DC00) and (C <= $DFFF) then Fail;
  end;
end;

function Utf8Bytes(const S: UnicodeString): TBytes;
var Encoded: UTF8String;
begin
  ValidateUnicode(S);
  Encoded := UTF8Encode(S);
  if Length(Encoded) > NdefMaxMessageBytes then Fail;
  Result := nil; SetLength(Result, Length(Encoded));
  if Length(Encoded) > 0 then Move(Encoded[1], Result[0], Length(Encoded));
end;

function StrictUtf8(const B: TBytes): UnicodeString;
var I, J, Needed, Count: Integer; Scalar, Minimum: Cardinal; V: Byte;
begin
  if Length(B) > NdefMaxMessageBytes then Fail;
  Result := ''; SetLength(Result, Length(B)); I := 0; Count := 0;
  while I < Length(B) do
  begin
    V := B[I]; Inc(I); Needed := 0; Minimum := 0;
    if V < $80 then Scalar := V
    else if (V >= $C2) and (V <= $DF) then begin Needed := 1; Scalar := V and $1F; Minimum := $80; end
    else if (V >= $E0) and (V <= $EF) then begin Needed := 2; Scalar := V and $0F; Minimum := $800; end
    else if (V >= $F0) and (V <= $F4) then begin Needed := 3; Scalar := V and $07; Minimum := $10000; end
    else begin Fail; Scalar := 0; end;
    if Needed > Length(B) - I then Fail;
    for J := 1 to Needed do
    begin
      V := B[I]; Inc(I); if (V and $C0) <> $80 then Fail;
      Scalar := (Scalar shl 6) or (V and $3F);
    end;
    if (Scalar < Minimum) or (Scalar > $10FFFF) or
      ((Scalar >= $D800) and (Scalar <= $DFFF)) then Fail;
    Inc(Count);
    if Scalar <= $FFFF then Result[Count] := WideChar(Scalar)
    else
    begin
      Dec(Scalar, $10000); Result[Count] := WideChar($D800 or (Scalar shr 10));
      Inc(Count); Result[Count] := WideChar($DC00 or (Scalar and $3FF));
    end;
  end;
  SetLength(Result, Count);
end;

function Ascii(const S: UnicodeString): TBytes;
var I: Integer;
begin
  Result := nil; if Length(S) > 255 then Fail; SetLength(Result, Length(S));
  for I := 1 to Length(S) do
  begin if Ord(S[I]) > 127 then Fail; Result[I - 1] := Ord(S[I]); end;
end;

function LowerAscii(const S: UnicodeString): UnicodeString;
var I: Integer;
begin
  Result := S;
  for I := 1 to Length(Result) do
  begin
    if Ord(Result[I]) > 127 then Fail;
    if (Result[I] >= 'A') and (Result[I] <= 'Z') then Result[I] := WideChar(Ord(Result[I]) + 32);
  end;
end;

procedure Language(const S: UnicodeString);
var I: Integer;
begin
  if Length(S) > 63 then Fail;
  for I := 1 to Length(S) do
    if not (((S[I] >= 'a') and (S[I] <= 'z')) or ((S[I] >= 'A') and (S[I] <= 'Z')) or
      ((S[I] >= '0') and (S[I] <= '9')) or (S[I] = '-')) then Fail;
end;

function Token(const C: WideChar): Boolean;
begin
  Result := ((C >= 'a') and (C <= 'z')) or ((C >= 'A') and (C <= 'Z')) or
    ((C >= '0') and (C <= '9')) or (Pos(C, UnicodeString('!#$%&''*+-.^_`|~')) > 0);
end;

procedure MediaType(const S: UnicodeString);
var I, Slash: Integer;
begin
  if (Length(S) < 3) or (Length(S) > 255) then Fail;
  Slash := 0;
  for I := 1 to Length(S) do
    if S[I] = '/' then begin if Slash <> 0 then Fail; Slash := I; end
    else if not Token(S[I]) then Fail;
  if (Slash <= 1) or (Slash >= Length(S)) then Fail;
end;

class function TNdefRecords.IsType(const ARecord: TNdefRecord;
  const ATnf: TNdefTypeNameFormat; const AType: UnicodeString): Boolean;
begin Result := (ARecord.Tnf = ATnf) and BytesEqual(ARecord.RecordType, Ascii(AType)); end;

class function TNdefRecords.Text(const AText, ALanguage: UnicodeString;
  const AUtf16: Boolean): TNdefRecord;
var B, Encoded, Lang: TBytes; I, P: Integer;
begin
  Language(ALanguage); Lang := Ascii(ALanguage); ValidateUnicode(AText);
  if AUtf16 then
  begin
    if Length(AText) > (NdefMaxMessageBytes - 2) div 2 then Fail;
    SetLength(Encoded, 2 + Length(AText) * 2); Encoded[0] := $FE; Encoded[1] := $FF;
    for I := 1 to Length(AText) do
    begin Encoded[I * 2] := Ord(AText[I]) shr 8; Encoded[I * 2 + 1] := Ord(AText[I]) and $FF; end;
  end
  else Encoded := Utf8Bytes(AText);
  if Length(Encoded) > NdefMaxMessageBytes - 1 - Length(Lang) then Fail;
  SetLength(B, 1 + Length(Lang) + Length(Encoded)); B[0] := Length(Lang);
  if AUtf16 then B[0] := B[0] or $80;
  P := 1;
  for I := 0 to High(Lang) do begin B[P] := Lang[I]; Inc(P); end;
  if Length(Encoded) > 0 then Move(Encoded[0], B[P], Length(Encoded));
  Result := TNdefCodec.NewRecord(ntfWellKnown, Ascii('T'), nil, B);
end;

class function TNdefRecords.DecodeText(const ARecord: TNdefRecord): TNdefText;
var B: TBytes; L, P, I, C: Integer; Little: Boolean;
begin
  Result := Default(TNdefText); TNdefCodec.ValidateRecord(ARecord);
  if not IsType(ARecord, ntfWellKnown, 'T') then Fail;
  B := ARecord.Payload; if Length(B) < 1 then Fail;
  if (B[0] and $40) <> 0 then Fail;
  L := B[0] and $3F; if L > Length(B) - 1 then Fail;
  SetLength(Result.Language, L);
  for I := 0 to L - 1 do Result.Language[I + 1] := WideChar(B[I + 1]);
  Language(Result.Language); Result.Utf16 := (B[0] and $80) <> 0; P := L + 1;
  if not Result.Utf16 then Result.Text := StrictUtf8(Copy(B, P, Length(B) - P))
  else
  begin
    if (Length(B) - P) mod 2 <> 0 then Fail;
    Little := False;
    if Length(B) - P >= 2 then
    begin
      if (B[P] = $FF) and (B[P + 1] = $FE) then begin Little := True; Inc(P, 2); end
      else if (B[P] = $FE) and (B[P + 1] = $FF) then Inc(P, 2);
    end;
    SetLength(Result.Text, (Length(B) - P) div 2);
    for I := 1 to Length(Result.Text) do
    begin
      if Little then C := B[P] or (Integer(B[P + 1]) shl 8)
      else C := (Integer(B[P]) shl 8) or B[P + 1];
      Result.Text[I] := WideChar(C); Inc(P, 2);
    end;
    ValidateUnicode(Result.Text);
  end;
end;

class function TNdefRecords.Uri(const AUri: UnicodeString): TNdefRecord;
var I, Prefix, Size: Integer; B, Encoded: TBytes;
begin
  if AUri = '' then Fail;
  ValidateUnicode(AUri); Prefix := 0; Size := 0;
  for I := 1 to High(UriPrefixes) do
    if (Length(UriPrefixes[I]) > Size) and (Copy(AUri, 1, Length(UriPrefixes[I])) = UriPrefixes[I]) then
    begin Prefix := I; Size := Length(UriPrefixes[I]); end;
  Encoded := Utf8Bytes(Copy(AUri, Size + 1, Length(AUri) - Size));
  if Length(Encoded) >= NdefMaxMessageBytes then Fail;
  SetLength(B, Length(Encoded) + 1); B[0] := Prefix;
  if Length(Encoded) > 0 then Move(Encoded[0], B[1], Length(Encoded));
  Result := TNdefCodec.NewRecord(ntfWellKnown, Ascii('U'), nil, B);
end;

class function TNdefRecords.DecodeUri(const ARecord: TNdefRecord): UnicodeString;
begin
  TNdefCodec.ValidateRecord(ARecord);
  if not IsType(ARecord, ntfWellKnown, 'U') or (Length(ARecord.Payload) < 1) then Fail;
  if ARecord.Payload[0] > High(UriPrefixes) then Fail;
  Result := UriPrefixes[ARecord.Payload[0]] + StrictUtf8(Copy(ARecord.Payload, 1, Length(ARecord.Payload) - 1));
  if Result = '' then Fail;
end;

class function TNdefRecords.Mime(const AMediaType: UnicodeString; const APayload: TBytes): TNdefRecord;
begin
  MediaType(AMediaType);
  Result := TNdefCodec.NewRecord(ntfMime, Ascii(LowerAscii(AMediaType)), nil, APayload);
end;

class function TNdefRecords.External(const ADomain, AType: UnicodeString;
  const APayload: TBytes): TNdefRecord;
var I, LabelStart: Integer; S: UnicodeString;
begin
  if (ADomain = '') or (AType = '') or (Length(ADomain) + Length(AType) > 254) then Fail;
  S := LowerAscii(ADomain); LabelStart := 1;
  for I := 1 to Length(S) + 1 do
  begin
    if (I > Length(S)) or (S[I] = '.') then
    begin
      if (I = LabelStart) or (I - LabelStart > 63) or (S[LabelStart] = '-') or (S[I - 1] = '-') then Fail;
      LabelStart := I + 1;
    end
    else if not (((S[I] >= 'a') and (S[I] <= 'z')) or ((S[I] >= '0') and (S[I] <= '9')) or (S[I] = '-')) then Fail;
  end;
  for I := 1 to Length(AType) do if not Token(AType[I]) then Fail;
  Result := TNdefCodec.NewRecord(ntfExternal, Ascii(S + ':' + LowerAscii(AType)), nil, APayload);
end;

procedure ValidatePoster(const M: TNdefMessage);
var I, J, Uris, Actions, Sizes, Types: Integer; T, Previous: TNdefText; S: UnicodeString;
begin
  Uris := 0; Actions := 0; Sizes := 0; Types := 0;
  if (Length(M) < 1) or (Length(M) > NdefMaxRecords) then Fail;
  for I := 0 to High(M) do
  begin
    TNdefCodec.ValidateRecord(M[I]);
    if TNdefRecords.IsType(M[I], ntfWellKnown, 'U') then
    begin S := TNdefRecords.DecodeUri(M[I]); Inc(Uris); end
    else if TNdefRecords.IsType(M[I], ntfWellKnown, 'T') then
    begin
      T := TNdefRecords.DecodeText(M[I]);
      for J := 0 to I - 1 do if TNdefRecords.IsType(M[J], ntfWellKnown, 'T') then
      begin
        Previous := TNdefRecords.DecodeText(M[J]);
        if LowerAscii(Previous.Language) = LowerAscii(T.Language) then Fail;
      end;
    end
    else if TNdefRecords.IsType(M[I], ntfWellKnown, 'act') then
    begin
      Inc(Actions); if Length(M[I].Payload) <> 1 then Fail;
      if M[I].Payload[0] > 2 then Fail;
    end
    else if TNdefRecords.IsType(M[I], ntfWellKnown, 's') then
    begin Inc(Sizes); if Length(M[I].Payload) <> 4 then Fail; end
    else if TNdefRecords.IsType(M[I], ntfWellKnown, 't') then
    begin Inc(Types); S := StrictUtf8(M[I].Payload); MediaType(S); end
    else if TNdefRecords.IsType(M[I], ntfWellKnown, 'Sp') then Fail;
  end;
  if (Uris <> 1) or (Actions > 1) or (Sizes > 1) or (Types > 1) then Fail;
end;

class function TNdefRecords.SmartPoster(const AChildren: TNdefMessage): TNdefRecord;
begin
  ValidatePoster(AChildren);
  Result := TNdefCodec.NewRecord(ntfWellKnown, Ascii('Sp'), nil, TNdefCodec.Encode(AChildren));
end;

class function TNdefRecords.DecodeSmartPoster(const ARecord: TNdefRecord): TNdefMessage;
begin
  TNdefCodec.ValidateRecord(ARecord);
  if not IsType(ARecord, ntfWellKnown, 'Sp') then Fail;
  Result := TNdefCodec.Decode(ARecord.Payload); ValidatePoster(Result);
end;

end.
