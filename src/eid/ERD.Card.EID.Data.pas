unit ERD.Card.EID.Data;

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

const
  /// <summary>Maximum file size supported by the Belpic 15-bit READ BINARY offset.</summary>
  EidMaxFileBytes = 32768;
  /// <summary>The applet instance AID shared by the documented Belpic 1.7 and 1.8 contact profiles.</summary>
  EidBelpicAidHex = 'A00000003029057000AD13100101FF';

type
  /// <summary>An invalid eID file, UTF-8 value, certificate envelope or read protocol.</summary>
  /// <remarks>Messages contain no identity, photograph, command or response data.</remarks>
  EBelgianEidError = class(Exception);

  /// <summary>Identity tags in the published eID identity file; numeric values are hexadecimal on the wire.</summary>
  /// <remarks>Unknown tags are retained. Binary fields and the presence-only MemberOfFamily tag are not text.</remarks>
  TEidIdentityTag = (
    /// <summary>Binary file structure version, tag 00.</summary>
    eitStructureVersion,
    /// <summary>Printed card number, tag 01.</summary>
    eitCardNumber,
    /// <summary>Binary chip number, tag 02.</summary>
    eitChipNumber,
    /// <summary>Validity start text, normally DD.MM.YYYY, tag 03.</summary>
    eitValidityBegin,
    /// <summary>Validity end text, normally DD.MM.YYYY, tag 04.</summary>
    eitValidityEnd,
    /// <summary>Card delivery municipality, tag 05.</summary>
    eitIssuingMunicipality,
    /// <summary>National register number retained as text, tag 06.</summary>
    eitNationalNumber,
    /// <summary>Surname, tag 07.</summary>
    eitSurname,
    /// <summary>First two given names in one field, tag 08.</summary>
    eitGivenNames,
    /// <summary>Initial of the third given name, tag 09.</summary>
    eitThirdNameInitial,
    /// <summary>Nationality, tag 0A.</summary>
    eitNationality,
    /// <summary>Birth location, tag 0B.</summary>
    eitBirthLocation,
    /// <summary>Localized birth-date text; a partial date is possible, tag 0C.</summary>
    eitBirthDate,
    /// <summary>Sex text exactly as personalized, tag 0D.</summary>
    eitSex,
    /// <summary>Noble condition, tag 0E.</summary>
    eitNobility,
    /// <summary>Document type code retained as text, tag 0F.</summary>
    eitDocumentType,
    /// <summary>Special status code retained as text, tag 10.</summary>
    eitSpecialStatus,
    /// <summary>Binary photo hash; the algorithm depends on the card generation, tag 11.</summary>
    eitPhotoHash,
    /// <summary>Duplicate card indicator, tag 12.</summary>
    eitDuplicate,
    /// <summary>Special organization code, tag 13.</summary>
    eitSpecialOrganization,
    /// <summary>Presence-only family-member flag with a zero-length value, tag 14.</summary>
    eitMemberOfFamily,
    /// <summary>Protection date and country text, tag 15.</summary>
    eitProtectionDateAndCountry,
    /// <summary>Work permit mention code, tag 16.</summary>
    eitWorkPermit,
    /// <summary>First employer VAT number, tag 17.</summary>
    eitEmployerVat1,
    /// <summary>Second employer VAT number, tag 18.</summary>
    eitEmployerVat2,
    /// <summary>Regional file number, tag 19.</summary>
    eitRegionalFileNumber,
    /// <summary>Binary basic public-key hash, tag 1A.</summary>
    eitBasicKeyHash,
    /// <summary>First Brexit mention, tag 1B.</summary>
    eitBrexitMention1,
    /// <summary>Second Brexit mention, tag 1C.</summary>
    eitBrexitMention2,
    /// <summary>First A-card mention, tag 1D.</summary>
    eitCardAMention1,
    /// <summary>Second A-card mention, tag 1E.</summary>
    eitCardAMention2,
    /// <summary>EU registration or residence start date text, tag 1F.</summary>
    eitEuStartDate
  );

  /// <summary>Address tags in the published eID address file.</summary>
  TEidAddressTag = (
    /// <summary>Binary file structure version, tag 00.</summary>
    eatStructureVersion,
    /// <summary>Street and house number, tag 01.</summary>
    eatStreetAndNumber,
    /// <summary>Postal code retained as text, tag 02.</summary>
    eatPostalCode,
    /// <summary>Residence municipality, tag 03.</summary>
    eatMunicipality
  );

  /// <summary>One simplified eID TLV entry with an independent value buffer.</summary>
  TEidField = record
    /// <summary>The one-byte tag, including unrecognized future tags.</summary>
    Tag: Byte;
    /// <summary>Exact value bytes, excluding tag and additive length bytes.</summary>
    Value: TBytes;
  end;
  /// <summary>Entries in original file order; at most 256 unique tags.</summary>
  TEidFields = array of TEidField;

  /// <summary>A decoded simplified-TLV file, retaining raw bytes and unknown fields.</summary>
  /// <remarks>Decoder outputs and getters allocate independent buffers. Ordinary record
  /// assignment shares dynamic arrays; copy buffers before modifying an assigned record.
  /// Instances contain mutable caller-owned data, with no hardware or UI dependency.</remarks>
  TEidFileData = record
    /// <summary>Exact input bytes, including trailing zero padding, for later signature verification.</summary>
    RawData: TBytes;
    /// <summary>Length of the encoded fields before trailing zero padding.</summary>
    EncodedLength: Integer;
    /// <summary>Decoded fields, including binary and unknown fields.</summary>
    Fields: TEidFields;
    /// <summary>Checks whether a tag is present, including a present empty value.</summary>
    /// <param name="ATag">The one-byte tag to find.</param>
    /// <returns>True if a field with the specified tag exists.</returns>
    function HasField(const ATag: Byte): Boolean;
    /// <summary>Copies the value of a tag.</summary>
    /// <param name="ATag">The one-byte tag to find.</param>
    /// <returns>Independent bytes; empty for missing or empty fields. Use HasField to distinguish them.</returns>
    function GetBytes(const ATag: Byte): TBytes;
    /// <summary>Decodes a tag as strictly validated UTF-8 without trimming or date conversion.</summary>
    /// <param name="ATag">A tag whose value is text, not a binary identifier or hash.</param>
    /// <returns>Unicode text; empty for missing or empty fields.</returns>
    /// <exception cref="EBelgianEidError">The value contains invalid UTF-8.</exception>
    function GetText(const ATag: Byte): UnicodeString;
  end;

  /// <summary>Convenient identity values plus the complete decoded file.</summary>
  /// <remarks>Missing text fields yield empty strings. Data.HasField distinguishes missing
  /// and empty fields. Dates and codes remain text; hashes and signatures are not verified.</remarks>
  TBelgianEidIdentity = record
    /// <summary>The full decoded identity, including optional and future fields.</summary>
    Data: TEidFileData;
    /// <summary>Printed card number.</summary>
    CardNumber: UnicodeString;
    /// <summary>Independent binary chip identifier.</summary>
    ChipNumber: TBytes;
    /// <summary>Card validity start, normally DD.MM.YYYY.</summary>
    ValidityBegin: UnicodeString;
    /// <summary>Card validity end, normally DD.MM.YYYY.</summary>
    ValidityEnd: UnicodeString;
    /// <summary>Municipality which issued the card.</summary>
    IssuingMunicipality: UnicodeString;
    /// <summary>National register number, preserving leading zeroes.</summary>
    NationalNumber: UnicodeString;
    /// <summary>Surname, preserving original Unicode spelling.</summary>
    Surname: UnicodeString;
    /// <summary>The first two given names as one string.</summary>
    GivenNames: UnicodeString;
    /// <summary>Initial of the third given name.</summary>
    ThirdNameInitial: UnicodeString;
    /// <summary>Nationality text.</summary>
    Nationality: UnicodeString;
    /// <summary>Birth location text.</summary>
    BirthLocation: UnicodeString;
    /// <summary>Localized or partial birth-date text, without inferred missing values.</summary>
    BirthDate: UnicodeString;
    /// <summary>Sex code exactly as personalized.</summary>
    Sex: UnicodeString;
    /// <summary>Noble condition text.</summary>
    Nobility: UnicodeString;
    /// <summary>Document type code as text, permitting future codes.</summary>
    DocumentType: UnicodeString;
    /// <summary>Special status code as text.</summary>
    SpecialStatus: UnicodeString;
    /// <summary>Independent photo-hash bytes; length does not establish verified authenticity.</summary>
    PhotoHash: TBytes;
    /// <summary>True when the presence-only MemberOfFamily field exists.</summary>
    MemberOfFamily: Boolean;
  end;

  /// <summary>Residence values and the complete address file.</summary>
  TBelgianEidAddress = record
    /// <summary>All decoded fields and exact raw bytes.</summary>
    Data: TEidFileData;
    /// <summary>Street and house number as one string.</summary>
    StreetAndNumber: UnicodeString;
    /// <summary>Postal code, preserving leading zeroes.</summary>
    PostalCode: UnicodeString;
    /// <summary>Residence municipality.</summary>
    Municipality: UnicodeString;
  end;

  /// <summary>The five public certificate files shared by the supported contact profiles.</summary>
  TEidCertificateKind = (
    /// <summary>Citizen authentication certificate, EF 5038.</summary>
    eckAuthentication,
    /// <summary>Citizen non-repudiation certificate, EF 5039.</summary>
    eckSigning,
    /// <summary>Citizen or foreigner issuing CA certificate, EF 503A.</summary>
    eckCitizenCa,
    /// <summary>Root CA certificate, EF 503B.</summary>
    eckRootCa,
    /// <summary>National register certificate, EF 503C.</summary>
    eckNationalRegister
  );
  /// <summary>Availability of a requested certificate, without any trust decision.</summary>
  TEidCertificateState = (
    /// <summary>The certificate was not requested.</summary>
    ecsNotRead,
    /// <summary>Only the selected certificate EF returned file-not-found, 6A82.</summary>
    ecsMissing,
    /// <summary>The selected file contained only zero bytes, indicating no issued certificate.</summary>
    ecsEmpty,
    /// <summary>A nonempty DER SEQUENCE envelope was read; X.509 structure and trust remain unchecked.</summary>
    ecsPresent
  );
  /// <summary>Certificate file bytes and its unpadded DER envelope.</summary>
  TEidCertificate = record
    /// <summary>The certificate file role.</summary>
    Kind: TEidCertificateKind;
    /// <summary>File availability; this is not a certificate-validation result.</summary>
    State: TEidCertificateState;
    /// <summary>Exact file bytes, including padding; empty when missing or not read.</summary>
    RawData: TBytes;
    /// <summary>Independent DER envelope excluding zero padding; empty unless present.</summary>
    DerData: TBytes;
  end;
  /// <summary>Certificate records in TEidCertificateKind order when requested.</summary>
  TEidCertificates = array of TEidCertificate;

  /// <summary>Public data groups that can be requested independently.</summary>
  TEidSection = (
    /// <summary>Identity TLV file.</summary>
    esIdentity,
    /// <summary>Address TLV file.</summary>
    esAddress,
    /// <summary>Raw JPEG photograph.</summary>
    esPhoto,
    /// <summary>Both identity and address signature files, without verification.</summary>
    esSignatures,
    /// <summary>All five public certificate files, accepting missing or unissued certificates.</summary>
    esCertificates
  );
  /// <summary>A selection of public data groups; no PIN or private-key operation is involved.</summary>
  TEidSections = set of TEidSection;

  /// <summary>A caller-owned result from one complete read operation.</summary>
  /// <remarks>Ordinary assignment shares dynamic arrays. No authenticity or certificate
  /// chain validation has been performed. No partial result is returned on failure.</remarks>
  TBelgianEidData = record
    /// <summary>The successfully requested groups; other fields retain default values.</summary>
    Sections: TEidSections;
    /// <summary>Decoded identity when esIdentity was requested.</summary>
    Identity: TBelgianEidIdentity;
    /// <summary>Decoded residence address when esAddress was requested.</summary>
    Address: TBelgianEidAddress;
    /// <summary>Exact JPEG file bytes when esPhoto was requested, with no image-decoder dependency.</summary>
    Photo: TBytes;
    /// <summary>Exact identity signature bytes when esSignatures was requested.</summary>
    IdentitySignature: TBytes;
    /// <summary>Exact address signature file bytes, including any padding.</summary>
    AddressSignature: TBytes;
    /// <summary>All five certificate records in enum order, or an empty array when not requested.</summary>
    Certificates: TEidCertificates;
  end;

  /// <summary>Stateless decoding of Belgian eID files, independent of transport and VCL.</summary>
  /// <remarks>All inputs are bounded by EidMaxFileBytes and copied. Known text tags
  /// require valid UTF-8. Unknown tags remain binary. Caller mutation of inputs during
  /// decoding is unsupported. These methods do not authenticate signed data.</remarks>
  TBelgianEidCodec = class
  public
    /// <summary>Parses one-byte tags and additive FF length encoding with trailing zero padding.</summary>
    /// <param name="ABytes">A nonempty identity or address file; never BER-TLV.</param>
    /// <returns>Independent raw bytes and unique fields in original order.</returns>
    /// <exception cref="EBelgianEidError">Input is empty, oversized, truncated or has duplicate or misplaced zero tags.</exception>
    class function DecodeFile(const ABytes: TBytes): TEidFileData; static;
    /// <summary>Decodes identity values, preserving dates, codes, binary hashes and unknown tags.</summary>
    /// <param name="ABytes">Complete identity EF bytes, including optional padding.</param>
    /// <returns>An independent identity record; absent optional values remain empty.</returns>
    /// <exception cref="EBelgianEidError">TLV, UTF-8 or the presence-only family flag is malformed.</exception>
    class function DecodeIdentity(const ABytes: TBytes): TBelgianEidIdentity; static;
    /// <summary>Decodes address text and preserves all original fields.</summary>
    /// <param name="ABytes">Complete address EF bytes, including optional padding.</param>
    /// <returns>An independent address record.</returns>
    /// <exception cref="EBelgianEidError">TLV or known text fields are malformed.</exception>
    class function DecodeAddress(const ABytes: TBytes): TBelgianEidAddress; static;
    /// <summary>Separates a certificate DER SEQUENCE envelope from zero padding.</summary>
    /// <param name="ABytes">Nonempty certificate EF bytes, possibly all zeroes.</param>
    /// <param name="AKind">The role assigned by the selected EF.</param>
    /// <returns>Independent raw and DER buffers, with state ecsPresent or ecsEmpty.</returns>
    /// <exception cref="EBelgianEidError">Size, DER envelope, canonical length or zero padding is invalid.</exception>
    /// <remarks>Does not validate X.509 contents, cryptographic signatures, validity or trust.</remarks>
    class function DecodeCertificate(const ABytes: TBytes;
      const AKind: TEidCertificateKind): TEidCertificate; static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EBelgianEidError.Create('Invalid Belgian eID data: ' + AReason + '.');
end;

procedure CheckFileSize(const ABytes: TBytes);
begin
  if (Length(ABytes) = 0) or (Length(ABytes) > EidMaxFileBytes) then
    Fail('file size');
end;

function AllZero(const ABytes: TBytes; const AStart: Integer): Boolean;
var
  I: Integer;
begin
  for I := AStart to Length(ABytes) - 1 do
    if ABytes[I] <> 0 then Exit(False);
  Result := True;
end;

function StrictUtf8(const ABytes: TBytes): UnicodeString;
var
  I, J, Count, Needed: Integer;
  Scalar, Minimum: Cardinal;
  B: Byte;
begin
  Result := '';
  SetLength(Result, Length(ABytes));
  I := 0;
  Count := 0;
  while I < Length(ABytes) do
  begin
    B := ABytes[I];
    Inc(I);
    Needed := 0;
    Minimum := 0;
    if B < $80 then Scalar := B
    else if (B >= $C2) and (B <= $DF) then
    begin
      Needed := 1;
      Scalar := B and $1F;
      Minimum := $80;
    end
    else if (B >= $E0) and (B <= $EF) then
    begin
      Needed := 2;
      Scalar := B and $0F;
      Minimum := $800;
    end
    else if (B >= $F0) and (B <= $F4) then
    begin
      Needed := 3;
      Scalar := B and $07;
      Minimum := $10000;
    end
    else
    begin
      Fail('UTF-8 leading byte');
      Scalar := 0;
    end;
    if Needed > Length(ABytes) - I then Fail('truncated UTF-8');
    for J := 1 to Needed do
    begin
      B := ABytes[I];
      Inc(I);
      if (B and $C0) <> $80 then Fail('UTF-8 continuation');
      Scalar := (Scalar shl 6) or (B and $3F);
    end;
    if (Scalar < Minimum) or (Scalar > $10FFFF) or
      ((Scalar >= $D800) and (Scalar <= $DFFF)) then Fail('UTF-8 scalar');
    Inc(Count);
    if Scalar <= $FFFF then Result[Count] := WideChar(Scalar)
    else
    begin
      Dec(Scalar, $10000);
      Result[Count] := WideChar($D800 or (Scalar shr 10));
      Inc(Count);
      Result[Count] := WideChar($DC00 or (Scalar and $3FF));
    end;
  end;
  SetLength(Result, Count);
end;

function TEidFileData.HasField(const ATag: Byte): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(Fields) - 1 do
    if Fields[I].Tag = ATag then Exit(True);
  Result := False;
end;

function TEidFileData.GetBytes(const ATag: Byte): TBytes;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Length(Fields) - 1 do
    if Fields[I].Tag = ATag then Exit(CopyBytes(Fields[I].Value));
end;

function TEidFileData.GetText(const ATag: Byte): UnicodeString;
begin
  Result := StrictUtf8(GetBytes(ATag));
end;

class function TBelgianEidCodec.DecodeFile(const ABytes: TBytes): TEidFileData;
var
  Offset, ValueLength, Count, Part: Integer;
  Tag: Byte;
  Seen: set of Byte;
begin
  Result := Default(TEidFileData);
  CheckFileSize(ABytes);
  Offset := 0;
  Count := 0;
  Seen := [];
  while Offset < Length(ABytes) do
  begin
    Tag := ABytes[Offset];
    if (Tag = 0) and AllZero(ABytes, Offset) then Break;
    if (Tag = 0) and (Count <> 0) then Fail('misplaced version tag');
    if Tag in Seen then Fail('duplicate tag');
    Include(Seen, Tag);
    Inc(Offset);
    ValueLength := 0;
    repeat
      if Offset >= Length(ABytes) then Fail('truncated length');
      Part := ABytes[Offset];
      Inc(Offset);
      if ValueLength > EidMaxFileBytes - Part then Fail('length limit');
      Inc(ValueLength, Part);
    until Part <> $FF;
    if ValueLength > Length(ABytes) - Offset then Fail('truncated value');
    SetLength(Result.Fields, Count + 1);
    Result.Fields[Count].Tag := Tag;
    Result.Fields[Count].Value := Copy(ABytes, Offset, ValueLength);
    Inc(Count);
    Inc(Offset, ValueLength);
  end;
  if Count = 0 then Fail('no fields');
  Result.EncodedLength := Offset;
  Result.RawData := CopyBytes(ABytes);
end;

class function TBelgianEidCodec.DecodeIdentity(const ABytes: TBytes): TBelgianEidIdentity;
var
  I: Integer;
  Tag: Byte;
  Text: UnicodeString;
begin
  Result := Default(TBelgianEidIdentity);
  Result.Data := DecodeFile(ABytes);
  for I := 0 to Length(Result.Data.Fields) - 1 do
  begin
    Tag := Result.Data.Fields[I].Tag;
    if (Tag = Ord(eitCardNumber)) or ((Tag >= Ord(eitValidityBegin)) and
      (Tag <= Ord(eitSpecialStatus))) or (Tag = Ord(eitDuplicate)) or
      (Tag = Ord(eitSpecialOrganization)) or ((Tag >= Ord(eitProtectionDateAndCountry)) and
      (Tag <= Ord(eitRegionalFileNumber))) or ((Tag >= Ord(eitBrexitMention1)) and
      (Tag <= Ord(eitEuStartDate))) then
    begin
      Text := StrictUtf8(Result.Data.Fields[I].Value);
      case Tag of
        Ord(eitCardNumber): Result.CardNumber := Text;
        Ord(eitValidityBegin): Result.ValidityBegin := Text;
        Ord(eitValidityEnd): Result.ValidityEnd := Text;
        Ord(eitIssuingMunicipality): Result.IssuingMunicipality := Text;
        Ord(eitNationalNumber): Result.NationalNumber := Text;
        Ord(eitSurname): Result.Surname := Text;
        Ord(eitGivenNames): Result.GivenNames := Text;
        Ord(eitThirdNameInitial): Result.ThirdNameInitial := Text;
        Ord(eitNationality): Result.Nationality := Text;
        Ord(eitBirthLocation): Result.BirthLocation := Text;
        Ord(eitBirthDate): Result.BirthDate := Text;
        Ord(eitSex): Result.Sex := Text;
        Ord(eitNobility): Result.Nobility := Text;
        Ord(eitDocumentType): Result.DocumentType := Text;
        Ord(eitSpecialStatus): Result.SpecialStatus := Text;
      end;
    end;
    if (Tag = Ord(eitMemberOfFamily)) and (Length(Result.Data.Fields[I].Value) <> 0) then
      Fail('family flag length');
  end;
  Result.ChipNumber := Result.Data.GetBytes(Ord(eitChipNumber));
  Result.PhotoHash := Result.Data.GetBytes(Ord(eitPhotoHash));
  Result.MemberOfFamily := Result.Data.HasField(Ord(eitMemberOfFamily));
end;

class function TBelgianEidCodec.DecodeAddress(const ABytes: TBytes): TBelgianEidAddress;
begin
  Result := Default(TBelgianEidAddress);
  Result.Data := DecodeFile(ABytes);
  Result.StreetAndNumber := Result.Data.GetText(Ord(eatStreetAndNumber));
  Result.PostalCode := Result.Data.GetText(Ord(eatPostalCode));
  Result.Municipality := Result.Data.GetText(Ord(eatMunicipality));
end;

class function TBelgianEidCodec.DecodeCertificate(const ABytes: TBytes;
  const AKind: TEidCertificateKind): TEidCertificate;
var
  Offset, Size, Count, I: Integer;
begin
  Result := Default(TEidCertificate);
  CheckFileSize(ABytes);
  Result.Kind := AKind;
  Result.RawData := CopyBytes(ABytes);
  if AllZero(ABytes, 0) then
  begin
    Result.State := ecsEmpty;
    Exit;
  end;
  if (Length(ABytes) < 2) or (ABytes[0] <> $30) then Fail('certificate SEQUENCE');
  Offset := 2;
  Size := ABytes[1];
  if Size >= $80 then
  begin
    Count := Size and $7F;
    if (Count = 0) or (Count > 2) or (Count > Length(ABytes) - Offset) then
      Fail('certificate length');
    if ABytes[Offset] = 0 then Fail('nonminimal certificate length');
    Size := 0;
    for I := 1 to Count do
    begin
      Size := (Size shl 8) or ABytes[Offset];
      Inc(Offset);
    end;
    if Size < $80 then Fail('nonminimal certificate length');
  end;
  if (Size = 0) or (Size > Length(ABytes) - Offset) then Fail('certificate size');
  if not AllZero(ABytes, Offset + Size) then Fail('certificate padding');
  Result.DerData := Copy(ABytes, 0, Offset + Size);
  Result.State := ecsPresent;
end;

end.
