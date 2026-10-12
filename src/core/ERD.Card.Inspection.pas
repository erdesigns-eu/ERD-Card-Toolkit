unit ERD.Card.Inspection;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Workflow;

type
  /// <summary>Evidence for one requested inspection section.</summary>
  TCardInspectionStatus = (
    /// <summary>Not yet acquired, including cancellation before this section.</summary>
    cisPending,
    /// <summary>All requested data for this section was acquired.</summary>
    cisRead,
    /// <summary>The card explicitly reports absence or unsupported functionality.</summary>
    cisUnavailable,
    /// <summary>Access requires caller-supplied authentication or authorization.</summary>
    cisAuthenticationRequired,
    /// <summary>Some requested data was acquired, with explicit gaps.</summary>
    cisPartial,
    /// <summary>Acquisition failed; no success is inferred.</summary>
    cisFailed);
  /// <summary>Named decoded value or original bytes with explicit export classification.</summary>
  TCardInspectionField = record
    /// <summary>Stable machine key, unique within the section.</summary>
    Key: string;
    /// <summary>Readable field caption.</summary>
    Caption: UnicodeString;
    /// <summary>Optional parent field key, retaining report hierarchy without decoded values.</summary>
    ParentKey: string;
    /// <summary>Optional published, observed or unknown interpretation evidence.</summary>
    Confidence: string;
    /// <summary>Decoded text; raw bytes use Data instead.</summary>
    Value: UnicodeString;
    /// <summary>Independently owned encoded bytes, including images.</summary>
    Data: TBytes;
    /// <summary>True when export requires IncludePersonal.</summary>
    Personal: Boolean;
    /// <summary>True when export also requires IncludeRaw.</summary>
    Raw: Boolean;
  end;
  /// <summary>Ordered fields, preserving repeated EMV values through distinct indexed keys.</summary>
  TCardInspectionFields = array of TCardInspectionField;
  /// <summary>One section with exact card status and sanitized failure metadata.</summary>
  TCardInspectionSection = record
    /// <summary>Stable section identifier without card-derived personal content.</summary>
    Key: string;
    /// <summary>Readable section name.</summary>
    Caption: UnicodeString;
    /// <summary>Requested-section acquisition evidence.</summary>
    Status: TCardInspectionStatus;
    /// <summary>Exact refusal status, or zero when no refusal was received.</summary>
    StatusWord: Word;
    /// <summary>Failure class name only; no exception message or credentials.</summary>
    ErrorClass: string;
    /// <summary>Successfully acquired fields; missing data is never synthesized.</summary>
    Fields: TCardInspectionFields;
  end;
  /// <summary>Ordered independently owned sections.</summary>
  TCardInspectionSections = array of TCardInspectionSection;
  /// <summary>Explicit export policy; both flags default to false in a zero-initialized record.</summary>
  TCardInspectionExportOptions = record
    /// <summary>Permit personal decoded values and personal byte fields.</summary>
    IncludePersonal: Boolean;
    /// <summary>Permit encoded bytes and raw protocol fields; personal raw fields require both flags.</summary>
    IncludeRaw: Boolean;
  end;
  /// <summary>Structured snapshot; direct access includes personal data irrespective of export policy.</summary>
  TCardInspectionReport = record
    /// <summary>Stable family name.</summary>
    Family: string;
    /// <summary>True only after every section was read and transaction release succeeded.</summary>
    Complete: Boolean;
    /// <summary>Independent section results, including pending and failed requests.</summary>
    Sections: TCardInspectionSections;
  end;
  /// <summary>Frozen bounded inspection request; validation and metadata perform no hardware I/O.</summary>
  ICardInspectionSource = interface
    ['{85D81224-A2E2-4498-A3BA-6209E7750128}']
    /// <summary>Checks explicit settings and resource bounds without card I/O.</summary>
    procedure Validate;
    /// <summary>Returns the family identifier without I/O.</summary>
    /// <returns>Nonempty stable family name.</returns>
    function Family: string;
    /// <summary>Returns the requested section count without I/O.</summary>
    /// <returns>One through 256 sections.</returns>
    function SectionCount: Integer;
    /// <summary>Returns pending metadata without I/O.</summary>
    /// <param name="AIndex">Zero-based requested section index.</param>
    /// <returns>Stable section name with no acquired fields.</returns>
    function Describe(const AIndex: Integer): TCardInspectionSection;
    /// <summary>Reads one section once; known card refusals are returned explicitly.</summary>
    /// <param name="AIndex">Zero-based requested section index.</param>
    /// <returns>Acquired section; transport, malformed and unexpected failures raise.</returns>
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;
  /// <summary>Read-only inspection lifecycle with retained partial evidence and privacy-aware exports.</summary>
  /// <remarks>Events run on the executing thread. Complete is independent of workflow Completed:
  /// a finished inspection can contain unavailable sections. No automatic authentication, replay,
  /// payment or write is performed; an EMV source can initiate one GPO per application.</remarks>
  TCardInspectionWorkflow = class abstract(TCardWorkflow)
  private
    FSource: ICardInspectionSource;
    FTransport: ICardTransport;
    FReport: TCardInspectionReport;
    FPrepared, FConsumed: Boolean;
    FCurrentSection: Integer;
    FOnSectionRead, FOnAuthenticationRequired, FOnPartialRead: TNotifyEvent;
    FInspectionObserverErrorClass: string;
    function GetReport: TCardInspectionReport;
    procedure NotifyInspection(const AEvent: TNotifyEvent);
  protected
    /// <summary>Checks a fresh prepared request without I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Reads each section once, retaining evidence on interruption.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Freezes the source and optional outer transaction without hardware I/O.</summary>
    /// <param name="ASource">Independently configured source retained until preparation or destruction.</param>
    /// <param name="ATransport">Optional exclusive transaction covering all sections; source must disable nested acquisition.</param>
    procedure Prepare(const ASource: ICardInspectionSource; const ATransport: ICardTransport = nil);
    /// <summary>Deep copy of the complete or partial snapshot, including sensitive bytes.</summary>
    property Report: TCardInspectionReport read GetReport;
    /// <summary>Current zero-based section index during callbacks, minus one before execution.</summary>
    property CurrentSection: Integer read FCurrentSection;
    /// <summary>Last inspection-specific observer failure class; acquisition remains unchanged.</summary>
    property InspectionObserverErrorClass: string read FInspectionObserverErrorClass;
  published
    /// <summary>Emitted after one section outcome has been retained.</summary>
    property OnSectionRead: TNotifyEvent read FOnSectionRead write FOnSectionRead;
    /// <summary>Emitted for sections requiring explicit authentication.</summary>
    property OnAuthenticationRequired: TNotifyEvent read FOnAuthenticationRequired write FOnAuthenticationRequired;
    /// <summary>Emitted once when the final report is incomplete, including failure or cancellation.</summary>
    property OnPartialRead: TNotifyEvent read FOnPartialRead write FOnPartialRead;
  end;

/// <summary>Adds one independently owned field to a section.</summary>
/// <param name="ASection">Section to extend.</param>
/// <param name="AKey">Stable indexed field identifier.</param>
/// <param name="ACaption">Readable field name.</param>
/// <param name="AValue">Decoded value.</param>
/// <param name="APersonal">True for potentially personal data.</param>
/// <param name="ARaw">True for raw protocol content.</param>
/// <param name="AData">Optional encoded bytes, copied independently.</param>
procedure AddCardInspectionField(var ASection: TCardInspectionSection;
  const AKey: string; const ACaption, AValue: UnicodeString;
  const APersonal: Boolean = False; const ARaw: Boolean = False;
  const AData: TBytes = nil);

/// <summary>Maps a known refusal to explicit acquisition evidence.</summary>
/// <param name="ASection">Section receiving the exact status.</param>
/// <param name="AStatusWord">Card refusal, without guessed authorization semantics.</param>
procedure CardInspectionRefusal(var ASection: TCardInspectionSection; const AStatusWord: Word);

/// <summary>Exports readable text using the supplied privacy policy.</summary>
/// <param name="AReport">Structured snapshot; never modified.</param>
/// <param name="AOptions">Explicit personal and raw inclusion flags.</param>
/// <returns>Unicode text with section outcomes and eligible fields.</returns>
function CardInspectionToText(const AReport: TCardInspectionReport;
  const AOptions: TCardInspectionExportOptions): UnicodeString;

/// <summary>Exports ASCII JSON with escaped Unicode and explicit section status.</summary>
/// <param name="AReport">Structured snapshot; never modified.</param>
/// <param name="AOptions">Explicit personal and raw inclusion flags.</param>
/// <returns>JSON object; excluded field values and bytes are omitted completely.</returns>
function CardInspectionToJson(const AReport: TCardInspectionReport;
  const AOptions: TCardInspectionExportOptions): UnicodeString;

implementation

procedure AddCardInspectionField(var ASection: TCardInspectionSection;
  const AKey: string; const ACaption, AValue: UnicodeString;
  const APersonal, ARaw: Boolean; const AData: TBytes);
var N: Integer;
begin
  N := Length(ASection.Fields);
  if N >= 16384 then raise ECardWorkflowError.Create('Inspection field bound exceeded.');
  SetLength(ASection.Fields, N + 1);
  ASection.Fields[N].Key := AKey;
  ASection.Fields[N].Caption := ACaption;
  ASection.Fields[N].Value := AValue;
  ASection.Fields[N].Personal := APersonal;
  ASection.Fields[N].Raw := ARaw;
  ASection.Fields[N].Data := CopyBytes(AData);
end;

procedure CardInspectionRefusal(var ASection: TCardInspectionSection; const AStatusWord: Word);
begin
  ASection.StatusWord := AStatusWord;
  case AStatusWord of
    $6982, $6985, $6983: ASection.Status := cisAuthenticationRequired;
    $6A82, $6A83, $6A88, $6A81, $6D00: ASection.Status := cisUnavailable;
  else
    ASection.Status := cisFailed;
  end;
end;

function StatusName(const AStatus: TCardInspectionStatus): string;
begin
  case AStatus of
    cisPending: Result := 'Pending';
    cisRead: Result := 'Read';
    cisUnavailable: Result := 'Unavailable';
    cisAuthenticationRequired: Result := 'Authentication required';
    cisPartial: Result := 'Partial';
    cisFailed: Result := 'Failed';
  else Result := 'Unknown'; end;
end;

function CloneReport(const AReport: TCardInspectionReport): TCardInspectionReport;
var I, J: Integer;
begin
  Result := AReport;
  Result.Sections := Copy(AReport.Sections, 0, Length(AReport.Sections));
  for I := 0 to High(Result.Sections) do
  begin
    Result.Sections[I].Fields := Copy(AReport.Sections[I].Fields, 0, Length(AReport.Sections[I].Fields));
    for J := 0 to High(Result.Sections[I].Fields) do
      Result.Sections[I].Fields[J].Data := CopyBytes(AReport.Sections[I].Fields[J].Data);
  end;
end;

function TCardInspectionWorkflow.GetReport: TCardInspectionReport;
begin
  Result := CloneReport(FReport);
end;

procedure TCardInspectionWorkflow.Prepare(const ASource: ICardInspectionSource; const ATransport: ICardTransport);
var I, J, N: Integer; T: ICardTransaction; R: TCardInspectionReport;
begin
  RequireIdle; FPrepared := False;
  if ASource = nil then raise ECardWorkflowError.Create('Inspection source required.');
  ASource.Validate;
  N := ASource.SectionCount;
  if (N < 1) or (N > 256) or (ASource.Family = '') then
    raise ECardWorkflowError.Create('Invalid inspection request bounds.');
  if (ATransport <> nil) and not Supports(ATransport, ICardTransaction, T) then
    raise ECardWorkflowError.Create('Exclusive transaction required.');
  R := Default(TCardInspectionReport);
  R.Family := ASource.Family;
  SetLength(R.Sections, N);
  for I := 0 to N - 1 do
  begin
    R.Sections[I] := ASource.Describe(I);
    if (R.Sections[I].Key = '') or (R.Sections[I].Status <> cisPending) or
      (Length(R.Sections[I].Fields) <> 0) then
      raise ECardWorkflowError.Create('Invalid inspection metadata.');
    for J := 0 to I - 1 do
      if R.Sections[I].Key = R.Sections[J].Key then
        raise ECardWorkflowError.Create('Duplicate inspection section.');
  end;
  FReport := R; FSource := ASource; FTransport := ATransport;
  FPrepared := True; FConsumed := False; FCurrentSection := -1;
  FInspectionObserverErrorClass := '';
end;

procedure TCardInspectionWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then raise ECardWorkflowError.Create('Prepare a new inspection request.');
end;

procedure TCardInspectionWorkflow.NotifyInspection(const AEvent: TNotifyEvent);
begin
  if Assigned(AEvent) then
    try AEvent(Self);
    except on E: Exception do FInspectionObserverErrorClass := E.ClassName; end;
end;

procedure TCardInspectionWorkflow.DoExecute;
var I, J: Integer; T: ICardTransaction; Begun, Success: Boolean; S: TCardInspectionSection;
begin
  FConsumed := True; Begun := False; Success := False; T := nil;
  try
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, Length(FReport.Sections));
    if CancelRequested then Exit;
    if FTransport <> nil then
    begin
      if not Supports(FTransport, ICardTransaction, T) then
        raise ECardWorkflowError.Create('Transaction capability lost.');
      T.BeginTransaction; Begun := True;
    end;
    try
      for I := 0 to High(FReport.Sections) do
      begin
        if CancelRequested then Exit;
        FCurrentSection := I;
        try
          S := FSource.ReadSection(I);
          if (S.Key <> FReport.Sections[I].Key) or (S.Status = cisPending) or
            (Length(S.Fields) > 16384) then
            raise ECardWorkflowError.Create('Invalid inspection section evidence.');
          FReport.Sections[I] := S;
          FReport.Sections[I].Fields := Copy(S.Fields, 0, Length(S.Fields));
          for J := 0 to High(S.Fields) do
            FReport.Sections[I].Fields[J].Data := CopyBytes(S.Fields[J].Data);
        except
          on E: Exception do
          begin
            FReport.Sections[I].Status := cisFailed;
            FReport.Sections[I].ErrorClass := E.ClassName;
            NotifyInspection(FOnSectionRead);
            raise;
          end;
        end;
        NotifyInspection(FOnSectionRead);
        if S.Status = cisAuthenticationRequired then NotifyInspection(FOnAuthenticationRequired);
        Progress(cwsReading, I + 1, Length(FReport.Sections));
        if S.Status = cisFailed then raise ECardWorkflowError.Create('Inspection section failed.');
      end;
      Success := True;
    finally
      if Begun then
        if Success then T.EndTransaction
        else begin try T.EndTransaction; except end; end;
    end;
    FReport.Complete := not CancelRequested;
    for I := 0 to High(FReport.Sections) do
      if FReport.Sections[I].Status <> cisRead then FReport.Complete := False;
  finally
    if not FReport.Complete then NotifyInspection(FOnPartialRead);
  end;
end;

function Visible(const F: TCardInspectionField; const O: TCardInspectionExportOptions): Boolean;
begin
  Result := (not F.Personal or O.IncludePersonal) and (not F.Raw or O.IncludeRaw);
end;

function Json(const S: UnicodeString): UnicodeString;
var I: Integer; C: Word;
begin
  Result := '"';
  for I := 1 to Length(S) do
  begin
    C := Ord(S[I]);
    if (C = 34) or (C = 92) then Result := Result + WideChar(92) + S[I]
    else if (C < 32) or (C > 126) then Result := Result + '\u' + UnicodeString(IntToHex(C, 4))
    else Result := Result + S[I];
  end;
  Result := Result + '"';
end;

function CardInspectionToText(const AReport: TCardInspectionReport;
  const AOptions: TCardInspectionExportOptions): UnicodeString;
var I, J: Integer; F: TCardInspectionField;
begin
  Result := UnicodeString(AReport.Family + ', complete=' + BoolToStr(AReport.Complete, True)) + #13#10;
  for I := 0 to High(AReport.Sections) do
  begin
    Result := Result + AReport.Sections[I].Caption + ': ' + UnicodeString(StatusName(AReport.Sections[I].Status));
    if AReport.Sections[I].StatusWord <> 0 then
      Result := Result + UnicodeString(' (SW=' + IntToHex(AReport.Sections[I].StatusWord, 4) + ')');
    if AReport.Sections[I].ErrorClass <> '' then Result := Result + ' [' + UnicodeString(AReport.Sections[I].ErrorClass) + ']';
    Result := Result + #13#10;
    for J := 0 to High(AReport.Sections[I].Fields) do
    begin
      F := AReport.Sections[I].Fields[J];
      if not Visible(F, AOptions) then Continue;
      Result := Result + '  ' + F.Caption + ': ' + F.Value;
      if F.Confidence <> '' then Result := Result + ' [' + UnicodeString(F.Confidence) + ']';
      if Length(F.Data) > 0 then Result := Result + UnicodeString(BytesToHex(F.Data));
      Result := Result + #13#10;
    end;
  end;
end;

function CardInspectionToJson(const AReport: TCardInspectionReport;
  const AOptions: TCardInspectionExportOptions): UnicodeString;
var I, J: Integer; F: TCardInspectionField; First: Boolean;
begin
  Result := '{"family":' + Json(UnicodeString(AReport.Family)) + ',"complete":';
  if AReport.Complete then Result := Result + 'true' else Result := Result + 'false';
  Result := Result + ',"sections":[';
  for I := 0 to High(AReport.Sections) do
  begin
    if I > 0 then Result := Result + ',';
    Result := Result + '{"key":' + Json(UnicodeString(AReport.Sections[I].Key)) +
      ',"caption":' + Json(AReport.Sections[I].Caption) +
      ',"status":' + Json(UnicodeString(StatusName(AReport.Sections[I].Status))) +
      ',"statusWord":' + Json(UnicodeString(IntToHex(AReport.Sections[I].StatusWord, 4))) +
      ',"errorClass":' + Json(UnicodeString(AReport.Sections[I].ErrorClass)) + ',"fields":[';
    First := True;
    for J := 0 to High(AReport.Sections[I].Fields) do
    begin
      F := AReport.Sections[I].Fields[J];
      if not Visible(F, AOptions) then Continue;
      if not First then Result := Result + ',';
      First := False;
      Result := Result + '{"key":' + Json(UnicodeString(F.Key)) + ',"caption":' + Json(F.Caption) +
        ',"parentKey":' + Json(UnicodeString(F.ParentKey)) + ',"confidence":' + Json(UnicodeString(F.Confidence)) +
        ',"value":' + Json(F.Value) + ',"hex":' + Json(UnicodeString(BytesToHex(F.Data))) + '}';
    end;
    Result := Result + ']}';
  end;
  Result := Result + ']}';
end;

end.
