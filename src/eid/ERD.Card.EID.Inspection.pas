unit ERD.Card.EID.Inspection;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Inspection, ERD.Card.EID.Data, ERD.Card.EID.Reader,
  ERD.Card.EID.DocumentReader;

type
  /// <summary>Belgian contact-eID and explicit ICAO BAC/PACE inspection with independent report exports.</summary>
  /// <remarks>Belgian sections retain earlier successes on later failure. ICAO acquisition is
  /// one authenticated aggregate operation; no partial LDS result is fabricated. Reading
  /// signatures, certificates or SOD does not establish issuer authenticity or trust.</remarks>
  TEidInspectionWorkflow = class(TCardInspectionWorkflow)
  public
    /// <summary>Copies reader settings and acquires requested Belgian sections under one exclusive transaction.</summary>
    /// <param name="AReader">Configured contact-eID reader; transport must support transactions.</param>
    /// <param name="ASections">Explicit nonempty public section set.</param>
    procedure PrepareBelgian(const AReader: TBelgianEIDReader;
      const ASections: TEidSections = [esIdentity, esAddress, esPhoto]);
    /// <summary>Copies access configuration for one authenticated ICAO LDS acquisition.</summary>
    /// <param name="AReader">Idle explicit BAC/PACE reader with caller-supplied password and crypto provider.</param>
    /// <param name="ASections">Explicit nonempty supported LDS section set.</param>
    procedure PrepareIcao(const AReader: TICAODocumentReader;
      const ASections: TIcaoDocumentSections = [idsIdentity, idsFace]);
  end;

implementation

uses ERD.Card.Workflow, ERD.Card.Crypto, ERD.Card.EID.Access;

type
  TBelgianSource = class(TInterfacedObject, ICardInspectionSource)
  private
    R: TBelgianEIDReader;
    Selected: array of TEidSection;
  public
    constructor Create(const AReader: TBelgianEIDReader; const ASections: TEidSections);
    destructor Destroy; override;
    procedure Validate;
    function Family: string;
    function SectionCount: Integer;
    function Describe(const AIndex: Integer): TCardInspectionSection;
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;
  TIcaoSource = class(TInterfacedObject, ICardInspectionSource)
  private
    R: TICAODocumentReader;
    Selected: TIcaoDocumentSections;
  public
    constructor Create(const AReader: TICAODocumentReader; const ASections: TIcaoDocumentSections);
    destructor Destroy; override;
    procedure Validate;
    function Family: string;
    function SectionCount: Integer;
    function Describe(const AIndex: Integer): TCardInspectionSection;
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;

constructor TBelgianSource.Create(const AReader: TBelgianEIDReader; const ASections: TEidSections);
var S: TEidSection; N: Integer;
begin
  inherited Create;
  R := TBelgianEIDReader.Create(nil);
  R.Transport := AReader.Transport; R.UseTransactions := False;
  R.ChunkSize := AReader.ChunkSize; R.MaxFileBytes := AReader.MaxFileBytes;
  for S := Low(TEidSection) to High(TEidSection) do
    if S in ASections then begin N := Length(Selected); SetLength(Selected, N + 1); Selected[N] := S; end;
end;
destructor TBelgianSource.Destroy;
begin R.Free; inherited Destroy; end;
procedure TBelgianSource.Validate;
begin
  if (R.Transport = nil) or (Length(Selected) = 0) then raise ECardWorkflowError.Create('Belgian eID transport and sections required.');
end;
function TBelgianSource.Family: string;
begin Result := 'Belgian eID'; end;
function TBelgianSource.SectionCount: Integer;
begin Result := Length(Selected); end;
function TBelgianSource.Describe(const AIndex: Integer): TCardInspectionSection;
begin
  Result := Default(TCardInspectionSection);
  case Selected[AIndex] of
    esIdentity: begin Result.Key := 'identity'; Result.Caption := 'Identity'; end;
    esAddress: begin Result.Key := 'address'; Result.Caption := 'Residence address'; end;
    esPhoto: begin Result.Key := 'photo'; Result.Caption := 'Photograph'; end;
    esSignatures: begin Result.Key := 'signatures'; Result.Caption := 'Unverified signatures'; end;
    esCertificates: begin Result.Key := 'certificates'; Result.Caption := 'Unverified certificates'; end;
  end;
end;
function TBelgianSource.ReadSection(const AIndex: Integer): TCardInspectionSection;
var D: TBelgianEidData; I: Integer;
begin
  Result := Describe(AIndex);
  try
    D := R.ReadCard([Selected[AIndex]]);
    Result.Status := cisRead;
    case Selected[AIndex] of
      esIdentity:
      begin
        AddCardInspectionField(Result, 'surname', 'Surname', D.Identity.Surname, True);
        AddCardInspectionField(Result, 'givenNames', 'Given names', D.Identity.GivenNames, True);
        AddCardInspectionField(Result, 'cardNumber', 'Card number', D.Identity.CardNumber, True);
        AddCardInspectionField(Result, 'nationalNumber', 'National number', D.Identity.NationalNumber, True);
        AddCardInspectionField(Result, 'birthDate', 'Birth date (card text)', D.Identity.BirthDate, True);
        AddCardInspectionField(Result, 'birthLocation', 'Birth location', D.Identity.BirthLocation, True);
        AddCardInspectionField(Result, 'nationality', 'Nationality', D.Identity.Nationality, True);
        AddCardInspectionField(Result, 'sex', 'Sex', D.Identity.Sex, True);
        AddCardInspectionField(Result, 'validFrom', 'Valid from (card text)', D.Identity.ValidityBegin, True);
        AddCardInspectionField(Result, 'validUntil', 'Valid until (card text)', D.Identity.ValidityEnd, True);
        AddCardInspectionField(Result, 'issuer', 'Issuing municipality', D.Identity.IssuingMunicipality, True);
        AddCardInspectionField(Result, 'thirdInitial', 'Third given-name initial', D.Identity.ThirdNameInitial, True);
        AddCardInspectionField(Result, 'nobility', 'Nobility', D.Identity.Nobility, True);
        AddCardInspectionField(Result, 'documentType', 'Document type code', D.Identity.DocumentType, True);
        AddCardInspectionField(Result, 'specialStatus', 'Special status code', D.Identity.SpecialStatus, True);
        AddCardInspectionField(Result, 'familyMember', 'Member of family', UnicodeString(BoolToStr(D.Identity.MemberOfFamily, True)), True);
        AddCardInspectionField(Result, 'chipNumber', 'Chip number', '', True, True, D.Identity.ChipNumber);
        AddCardInspectionField(Result, 'photoHash', 'Photo hash', '', True, True, D.Identity.PhotoHash);
        for I := 0 to High(D.Identity.Data.Fields) do
          AddCardInspectionField(Result, 'tag.' + IntToStr(I), 'Identity tag ' + UnicodeString(IntToHex(D.Identity.Data.Fields[I].Tag, 2)), '', True, True, D.Identity.Data.Fields[I].Value);
      end;
      esAddress:
      begin
        AddCardInspectionField(Result, 'street', 'Street and number', D.Address.StreetAndNumber, True);
        AddCardInspectionField(Result, 'postalCode', 'Postal code', D.Address.PostalCode, True);
        AddCardInspectionField(Result, 'municipality', 'Municipality', D.Address.Municipality, True);
        for I := 0 to High(D.Address.Data.Fields) do
          AddCardInspectionField(Result, 'tag.' + IntToStr(I), 'Address tag ' + UnicodeString(IntToHex(D.Address.Data.Fields[I].Tag, 2)), '', True, True, D.Address.Data.Fields[I].Value);
      end;
      esPhoto: AddCardInspectionField(Result, 'jpeg', 'JPEG photograph', '', True, True, D.Photo);
      esSignatures:
      begin
        AddCardInspectionField(Result, 'identity', 'Identity signature', '', True, True, D.IdentitySignature);
        AddCardInspectionField(Result, 'address', 'Address signature', '', True, True, D.AddressSignature);
      end;
      esCertificates:
        for I := 0 to High(D.Certificates) do
        begin
          AddCardInspectionField(Result, 'certificate.' + IntToStr(I) + '.state', 'Certificate ' + UnicodeString(IntToStr(I)) + ' state', UnicodeString(IntToStr(Ord(D.Certificates[I].State))));
          AddCardInspectionField(Result, 'certificate.' + IntToStr(I) + '.der', 'Certificate DER', '', True, True, D.Certificates[I].DerData);
          if D.Certificates[I].State <> ecsPresent then Result.Status := cisPartial;
        end;
    end;
  except on E: EBelgianEidStatusError do begin CardInspectionRefusal(Result, E.StatusWord); Result.ErrorClass := E.ClassName; end; end;
end;

constructor TIcaoSource.Create(const AReader: TICAODocumentReader; const ASections: TIcaoDocumentSections);
var Password: TBytes;
begin
  inherited Create;
  R := TICAODocumentReader.Create(nil);
  R.Transport := AReader.Transport; R.CryptoProvider := AReader.CryptoProvider;
  R.Security := AReader.Security; R.PasswordKind := AReader.PasswordKind; R.PaceCurve := AReader.PaceCurve;
  Password := AReader.AccessPassword;
  try R.AccessPassword := Password; finally TCardCrypto.Clear(Password); end;
  R.ChunkSize := AReader.ChunkSize; R.MaxFileBytes := AReader.MaxFileBytes; R.MaxTotalBytes := AReader.MaxTotalBytes;
  Selected := ASections;
end;
destructor TIcaoSource.Destroy;
begin R.Free; inherited Destroy; end;
procedure TIcaoSource.Validate;
var Password: TBytes;
begin
  if (R.Transport = nil) or (Selected = []) then raise ECardWorkflowError.Create('ICAO transport and explicit sections required.');
  if (R.Security = iasBac) and (R.PasswordKind <> ipkMrz) then
    raise ECardWorkflowError.Create('BAC requires an explicit MRZ access password.');
  Password := R.AccessPassword;
  try
    if Length(Password) > 0 then TIcaoAccessCodec.ValidatePassword(Password, R.PasswordKind);
  finally TCardCrypto.Clear(Password); end;
end;
function TIcaoSource.Family: string;
begin Result := 'ICAO LDS'; end;
function TIcaoSource.SectionCount: Integer;
begin Result := 1; end;
function TIcaoSource.Describe(const AIndex: Integer): TCardInspectionSection;
begin
  Result := Default(TCardInspectionSection); Result.Key := 'document'; Result.Caption := 'Authenticated document data';
end;
function TIcaoSource.ReadSection(const AIndex: Integer): TCardInspectionSection;
var D: TIcaoDocumentData; I: Integer; Password: TBytes;
begin
  Result := Describe(AIndex);
  Password := R.AccessPassword;
  try
  if (Length(Password) = 0) or (R.CryptoProvider = nil) then
  begin Result.Status := cisAuthenticationRequired; Exit; end;
  try
    D := R.ReadDocument(Selected); Result.Status := cisRead;
    if idsIdentity in Selected then
    begin
      AddCardInspectionField(Result, 'surname', 'Surname (MRZ)', D.Identity.Surname, True);
      AddCardInspectionField(Result, 'givenNames', 'Given names (MRZ)', D.Identity.GivenNames, True);
      AddCardInspectionField(Result, 'number', 'Document number', D.Identity.DocumentNumber, True);
      AddCardInspectionField(Result, 'issuer', 'Issuing state', D.Identity.IssuingState, True);
      AddCardInspectionField(Result, 'nationality', 'Nationality', D.Identity.Nationality, True);
      AddCardInspectionField(Result, 'birthDate', 'Birth date YYMMDD', D.Identity.BirthDate, True);
      AddCardInspectionField(Result, 'expiryDate', 'Expiry YYMMDD', D.Identity.ExpiryDate, True);
      AddCardInspectionField(Result, 'sex', 'Sex (MRZ)', UnicodeString(D.Identity.Sex), True);
      AddCardInspectionField(Result, 'documentCode', 'Document code', D.Identity.DocumentCode, True);
      AddCardInspectionField(Result, 'optionalData', 'MRZ optional data', D.Identity.OptionalData, True);
      AddCardInspectionField(Result, 'optionalData2', 'MRZ second optional data', D.Identity.OptionalData2, True);
      AddCardInspectionField(Result, 'mrz', 'Original MRZ', D.Identity.Raw, True, True);
    end;
    AddCardInspectionField(Result, 'dg1', 'DG1', '', True, True, D.DG1);
    AddCardInspectionField(Result, 'dg2', 'DG2', '', True, True, D.DG2);
    AddCardInspectionField(Result, 'com', 'EF.COM', '', False, True, D.Common);
    AddCardInspectionField(Result, 'sod', 'EF.SOD (unverified)', '', True, True, D.SecurityObject);
    for I := 0 to High(D.Biometrics.Images) do
      AddCardInspectionField(Result, 'face.' + IntToStr(I), 'Encoded face image', '', True, True, D.Biometrics.Images[I].Data);
  except on E: EIcaoStatusError do begin CardInspectionRefusal(Result, E.StatusWord); Result.ErrorClass := E.ClassName; end; end;
  finally TCardCrypto.Clear(Password); R.AccessPassword := nil; end;
end;

procedure TEidInspectionWorkflow.PrepareBelgian(const AReader: TBelgianEIDReader; const ASections: TEidSections);
var S: ICardInspectionSource;
begin
  RequireIdle;
  if AReader = nil then raise ECardWorkflowError.Create('Configure a Belgian eID reader.');
  S := TBelgianSource.Create(AReader, ASections); inherited Prepare(S, AReader.Transport);
end;
procedure TEidInspectionWorkflow.PrepareIcao(const AReader: TICAODocumentReader; const ASections: TIcaoDocumentSections);
var S: ICardInspectionSource;
begin
  RequireIdle;
  if (AReader = nil) or AReader.Busy then raise ECardWorkflowError.Create('Configure an idle ICAO reader.');
  S := TIcaoSource.Create(AReader, ASections); inherited Prepare(S);
end;

end.
