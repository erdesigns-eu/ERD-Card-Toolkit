unit ERD.Card.MOBIB.Inspection;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Inspection, ERD.Card.Contactless.Calypso,
  ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Report;

type
  /// <summary>MOBIB inspection with decoded environment, holder, events, contracts, counters and operator evidence.</summary>
  /// <remarks>One bounded native read plan and one optional authenticated Calypso session.
  /// Existing operator confidence and caller-selected context remain explicit. Missing files,
  /// restricted records and reached bounds prevent Complete. No ticket update or entitlement
  /// is inferred. Raw records are conservatively personal, including travel history.</remarks>
  TMobibInspectionWorkflow = class(TCardInspectionWorkflow)
  public
    /// <summary>Copies reader settings and a bounded explicit plan without card I/O.</summary>
    /// <param name="AReader">Configured Calypso reader, with optional legitimate secure-session provider.</param>
    /// <param name="APlan">Explicit unique folder/LID or SFI entries.</param>
    /// <param name="ALayout">Explicit raw or supported legacy layout.</param>
    /// <param name="AOptions">Operator context and optional caller-supplied status date; export masking is configured separately.</param>
    /// <param name="AMaxRecordsPerFile">Record bound, one through 255; reached bounds remain partial.</param>
    procedure PrepareMobib(const AReader: TCalypsoCardReader; const APlan: TCalypsoFileRefs;
      const ALayout: TMobibLayout; const AOptions: TMobibReportOptions;
      const AMaxRecordsPerFile: Integer = 16);
  end;

implementation

uses ERD.Card.Workflow, ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Lookup;

type
  TMobibSource = class(TInterfacedObject, ICardInspectionSource)
  private
    R: TCalypsoCardReader;
    Plan: TCalypsoFileRefs;
    Layout: TMobibLayout;
    Options: TMobibReportOptions;
    MaxRecords: Integer;
  public
    constructor Create(const AReader: TCalypsoCardReader; const APlan: TCalypsoFileRefs;
      const ALayout: TMobibLayout; const AOptions: TMobibReportOptions; const AMaxRecords: Integer);
    destructor Destroy; override;
    procedure Validate;
    function Family: string;
    function SectionCount: Integer;
    function Describe(const AIndex: Integer): TCardInspectionSection;
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;

constructor TMobibSource.Create(const AReader: TCalypsoCardReader; const APlan: TCalypsoFileRefs;
  const ALayout: TMobibLayout; const AOptions: TMobibReportOptions; const AMaxRecords: Integer);
begin
  inherited Create; R := TCalypsoCardReader.Create(nil);
  R.Transport := AReader.Transport; R.Dialect := AReader.Dialect;
  R.RecordBytes := AReader.RecordBytes; R.RecordSizeFromCard := AReader.RecordSizeFromCard;
  R.ApplicationName := AReader.ApplicationName; R.UseTransactions := True;
  R.RequireSecureSession := AReader.RequireSecureSession; R.SecureSessionProvider := AReader.SecureSessionProvider;
  Plan := Copy(APlan, 0, Length(APlan)); Layout := ALayout; Options := AOptions;
  Options.ShowPersonal := True; MaxRecords := AMaxRecords;
end;
destructor TMobibSource.Destroy;
begin R.Free; inherited Destroy; end;
procedure TMobibSource.Validate;
var I, J: Integer;
begin
  if (R.Transport = nil) or (Length(Plan) < 1) or (Length(Plan) > 160) or
    (MaxRecords < 1) or (MaxRecords > 255) or
    not (Options.Context in [mocUnspecified, mocStib, mocDeLijn, mocTec, mocSncb]) or not (Layout in [mlRaw, mlLegacy056001]) then
    raise ECardWorkflowError.Create('Invalid MOBIB inspection configuration.');
  for I := 0 to High(Plan) do
  begin
    if not (Plan[I].Kind in [cfrLogicalId, cfrSfi]) or
      ((Plan[I].Kind = cfrLogicalId) and (Plan[I].LogicalId = 0)) or
      ((Plan[I].Kind = cfrSfi) and ((Plan[I].Sfi < 1) or (Plan[I].Sfi > 30))) then
      raise ECardWorkflowError.Create('Invalid MOBIB file reference.');
    for J := 0 to I - 1 do
      if (Plan[I].Kind = Plan[J].Kind) and ((Plan[I].Folder = Plan[J].Folder) or
        (((Plan[I].Folder = 0) or (Plan[I].Folder = $2000)) and
        ((Plan[J].Folder = 0) or (Plan[J].Folder = $2000)))) and
        (((Plan[I].Kind = cfrLogicalId) and (Plan[I].LogicalId = Plan[J].LogicalId)) or
        ((Plan[I].Kind = cfrSfi) and (Plan[I].Sfi = Plan[J].Sfi))) then
        raise ECardWorkflowError.Create('Duplicate MOBIB file reference.');
  end;
end;
function TMobibSource.Family: string;
begin Result := 'MOBIB / Calypso'; end;
function TMobibSource.SectionCount: Integer;
begin Result := 1; end;
function TMobibSource.Describe(const AIndex: Integer): TCardInspectionSection;
begin Result := Default(TCardInspectionSection); Result.Key := 'mobib'; Result.Caption := 'MOBIB inventory and decoded report'; end;
function TMobibSource.ReadSection(const AIndex: Integer): TCardInspectionSection;
var S: TMobibSnapshot; D: TMobibData; Nodes: TMobibReportNodes; I, J, P, Field: Integer; Prefix: string; Caption: UnicodeString; SW: Word;
begin
  Result := Describe(AIndex);
  if R.RequireSecureSession and (R.SecureSessionProvider = nil) then
  begin Result.Status := cisAuthenticationRequired; Exit; end;
  try
    S := R.ReadMobibPlan(Plan, MaxRecords);
    Result.Status := cisRead;
    // Keep acquired bytes before decoding; malformed semantic data is still a failed section.
    AddCardInspectionField(Result, 'ticketingSelection', 'Ticketing selection', '', True, True, S.TicketingSelection);
    for I := 0 to High(S.Files) do
    begin
      Prefix := 'file.' + IntToStr(I);
      AddCardInspectionField(Result, Prefix + '.selectStatus', UnicodeString(TMobibReport.FileLabel(S.Files[I]) + ' SELECT status'), UnicodeString(IntToHex(S.Files[I].SelectionStatus, 4)));
      AddCardInspectionField(Result, Prefix + '.readStatus', 'Last record status', UnicodeString(IntToHex(S.Files[I].LastRecordStatus, 4)));
      AddCardInspectionField(Result, Prefix + '.boundReached', 'Record bound reached', UnicodeString(BoolToStr(S.Files[I].Truncated, True)));
      AddCardInspectionField(Result, Prefix + '.selection', 'File selection', '', True, True, S.Files[I].SelectionData);
      SW := S.Files[I].SelectionStatus;
      if S.Files[I].BySfi or (SW = $9000) then SW := S.Files[I].LastRecordStatus;
      if ((SW = $6982) or (SW = $6985)) then begin Result.Status := cisAuthenticationRequired; Result.StatusWord := SW; end
      else if ((S.Files[I].SelectionStatus <> $9000) and not S.Files[I].BySfi) or
        S.Files[I].Truncated then
        if Result.Status = cisRead then Result.Status := cisPartial;
      for J := 0 to High(S.Files[I].Records) do
        AddCardInspectionField(Result, Prefix + '.record.' + IntToStr(S.Files[I].Records[J].Number),
          UnicodeString(TMobibReport.FileLabel(S.Files[I]) + ' record ' + IntToStr(S.Files[I].Records[J].Number)), '', True, True, S.Files[I].Records[J].Data);
    end;
    D := TMobibCodec.Decode(S, Layout);
    Nodes := TMobibReport.Build(D, TMobibSubscriptionCodec.DecodeSnapshot(D), nil, Options);
    for I := 0 to High(Nodes) do
    begin
      Caption := UnicodeString(Nodes[I].Caption); P := Nodes[I].Parent;
      while P >= 0 do
      begin
        Caption := UnicodeString(Nodes[P].Caption) + ' / ' + Caption;
        P := Nodes[P].Parent;
      end;
      Field := Length(Result.Fields);
      // Identity, entitlements and travel history remain private; generic card/operator notes are public.
      AddCardInspectionField(Result, 'parsed.' + IntToStr(I) + '.' + Nodes[I].Key,
        Caption, UnicodeString(Nodes[I].Value), Nodes[I].Personal or
          ((Copy(Nodes[I].Key, 1, 5) <> 'card.') and (Nodes[I].Value <> '')));
      Result.Fields[Field].Confidence := Nodes[I].Confidence;
      if Nodes[I].Parent >= 0 then
        Result.Fields[Field].ParentKey := 'parsed.' + IntToStr(Nodes[I].Parent) + '.' + Nodes[Nodes[I].Parent].Key;
    end;
  except
    on E: ECalypsoStatusError do begin CardInspectionRefusal(Result, E.StatusWord); Result.ErrorClass := E.ClassName; end;
    on E: EMobibDecodeError do begin Result.Status := cisFailed; Result.ErrorClass := E.ClassName; end;
  end;
end;

procedure TMobibInspectionWorkflow.PrepareMobib(const AReader: TCalypsoCardReader;
  const APlan: TCalypsoFileRefs; const ALayout: TMobibLayout; const AOptions: TMobibReportOptions;
  const AMaxRecordsPerFile: Integer);
var S: ICardInspectionSource;
begin
  RequireIdle;
  if (AReader = nil) or (Length(APlan) < 1) or (Length(APlan) > 160) then
    raise ECardWorkflowError.Create('Configure a Calypso reader and bounded explicit plan.');
  S := TMobibSource.Create(AReader, APlan, ALayout, AOptions, AMaxRecordsPerFile);
  inherited Prepare(S);
end;

end.
