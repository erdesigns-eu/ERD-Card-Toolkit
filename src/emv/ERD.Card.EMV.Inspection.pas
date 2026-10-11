unit ERD.Card.EMV.Inspection;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Inspection, ERD.Card.EMV.Data, ERD.Card.EMV.Reader;

type
  /// <summary>One explicit application with independently copied terminal PDOL inputs.</summary>
  TEmvInspectionApplication = record
    /// <summary>Full application AID, five through sixteen bytes.</summary>
    Aid: TBytes;
    /// <summary>Explicit unique terminal values; no fabricated defaults.</summary>
    TerminalValues: TEmvValues;
  end;
  /// <summary>One through sixteen explicitly selected applications.</summary>
  TEmvInspectionApplications = array of TEmvInspectionApplication;
  /// <summary>Explicit directory, log, counter and bounded additional record selection.</summary>
  TEmvInspectionOptions = record
    /// <summary>Acquire a directory as a separate section; no implicit application selection.</summary>
    ReadDirectory: Boolean;
    /// <summary>Explicit contact PSE or contactless PPSE.</summary>
    Directory: TEmvDirectory;
    /// <summary>Acquire ATC, last online ATC and PIN retry counter, without PIN verification.</summary>
    ReadCounters: Boolean;
    /// <summary>Acquire advertised transaction logs without payment execution.</summary>
    ReadLog: Boolean;
    /// <summary>Probe additional explicitly bounded records after AFL acquisition.</summary>
    ScanRecords: Boolean;
    /// <summary>First requested SFI, one through thirty.</summary>
    FirstSfi: Integer;
    /// <summary>Last SFI, not below FirstSfi.</summary>
    LastSfi: Integer;
    /// <summary>First absolute record, one through 255.</summary>
    FirstRecord: Integer;
    /// <summary>Last absolute record, not below FirstRecord.</summary>
    LastRecord: Integer;
  end;
  /// <summary>Explicit multi-application EMV inspection with all AFL records, optional scans, logs and counters.</summary>
  /// <remarks>One exclusive transaction, one GPO per requested application; no retries after
  /// a failed GPO, no PIN verification or payment cryptograms. Earlier completed sections
  /// survive later failure; each underlying application/log read is atomic. Unknown and
  /// repeated tags remain indexed byte fields, treated conservatively as personal data.</remarks>
  TEmvInspectionWorkflow = class(TCardInspectionWorkflow)
  public
    /// <summary>Copies reader settings, exact AIDs and terminal inputs without card I/O.</summary>
    /// <param name="AReader">Configured reader with transaction-capable transport.</param>
    /// <param name="AApplications">Explicit unique AIDs with corresponding PDOL values.</param>
    /// <param name="AOptions">Explicit acquisition selection and scan limits.</param>
    procedure PrepareEmv(const AReader: TEMVCardReader;
      const AApplications: TEmvInspectionApplications; const AOptions: TEmvInspectionOptions);
  end;

implementation

uses ERD.Card.Workflow;

type
  TEmvSource = class(TInterfacedObject, ICardInspectionSource)
  private
    R: TEMVCardReader;
    Apps: TEmvInspectionApplications;
    O: TEmvInspectionOptions;
    function Width: Integer;
    procedure DecodeIndex(const AIndex: Integer; out AApp, APart: Integer);
  public
    constructor Create(const AReader: TEMVCardReader; const AApplications: TEmvInspectionApplications; const AOptions: TEmvInspectionOptions);
    destructor Destroy; override;
    procedure Validate;
    function Family: string;
    function SectionCount: Integer;
    function Describe(const AIndex: Integer): TCardInspectionSection;
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;

constructor TEmvSource.Create(const AReader: TEMVCardReader; const AApplications: TEmvInspectionApplications; const AOptions: TEmvInspectionOptions);
var I, J: Integer;
begin
  inherited Create;
  R := TEMVCardReader.Create(nil); R.Transport := AReader.Transport; R.UseTransactions := False;
  R.MaxRecords := AReader.MaxRecords; R.MaxDirectoryRecords := AReader.MaxDirectoryRecords; R.MaxLogRecords := AReader.MaxLogRecords;
  O := AOptions; SetLength(Apps, Length(AApplications));
  for I := 0 to High(Apps) do
  begin
    if (Length(AApplications[I].TerminalValues) > 256) or
      (Length(AApplications[I].Aid) < 5) or (Length(AApplications[I].Aid) > 16) then
      raise ECardWorkflowError.Create('Invalid EMV application inputs.');
    for J := 0 to High(AApplications[I].TerminalValues) do
      if (Length(AApplications[I].TerminalValues[J].Tag) < 1) or
        (Length(AApplications[I].TerminalValues[J].Tag) > 3) or
        (Length(AApplications[I].TerminalValues[J].Value) > 255) then
        raise ECardWorkflowError.Create('Invalid terminal value bounds.');
    Apps[I].Aid := CopyBytes(AApplications[I].Aid);
    SetLength(Apps[I].TerminalValues, Length(AApplications[I].TerminalValues));
    for J := 0 to High(Apps[I].TerminalValues) do
    begin
      Apps[I].TerminalValues[J].Tag := CopyBytes(AApplications[I].TerminalValues[J].Tag);
      Apps[I].TerminalValues[J].Value := CopyBytes(AApplications[I].TerminalValues[J].Value);
    end;
  end;
end;
destructor TEmvSource.Destroy;
begin R.Free; inherited Destroy; end;
procedure TEmvSource.Validate;
var I, J: Integer;
begin
  if (R.Transport = nil) or (Length(Apps) > 16) or ((Length(Apps) = 0) and not O.ReadDirectory) then
    raise ECardWorkflowError.Create('Select explicit EMV applications or a directory.');
  if not (O.Directory in [edContactPse, edContactlessPpse]) then raise ECardWorkflowError.Create('Invalid directory.');
  if O.ScanRecords and ((O.FirstSfi < 1) or (O.LastSfi > 30) or (O.LastSfi < O.FirstSfi) or
    (O.FirstRecord < 1) or (O.LastRecord > 255) or (O.LastRecord < O.FirstRecord) or
    ((O.LastSfi - O.FirstSfi + 1) * (O.LastRecord - O.FirstRecord + 1) > R.MaxRecords)) then
    raise ECardWorkflowError.Create('Invalid EMV scan bounds.');
  for I := 0 to High(Apps) do
  begin
    if (Length(Apps[I].Aid) < 5) or (Length(Apps[I].Aid) > 16) or (Length(Apps[I].TerminalValues) > 256) then
      raise ECardWorkflowError.Create('Invalid EMV application inputs.');
    for J := 0 to I - 1 do if BytesEqual(Apps[I].Aid, Apps[J].Aid) then raise ECardWorkflowError.Create('Duplicate EMV AID.');
    for J := 0 to High(Apps[I].TerminalValues) do
      if (Length(Apps[I].TerminalValues[J].Tag) < 1) or (Length(Apps[I].TerminalValues[J].Tag) > 3) or
        (Length(Apps[I].TerminalValues[J].Value) > 255) then raise ECardWorkflowError.Create('Invalid terminal value.');
    // BuildDolData validates unique primitive tags even before the card PDOL is known.
    TEmvCodec.BuildDolData(nil, Apps[I].TerminalValues);
  end;
end;
function TEmvSource.Family: string;
begin Result := 'EMV'; end;
function TEmvSource.Width: Integer;
begin Result := 1; if O.ReadCounters then Inc(Result, 3); if O.ReadLog then Inc(Result); end;
function TEmvSource.SectionCount: Integer;
begin Result := Length(Apps) * Width; if O.ReadDirectory then Inc(Result); end;
procedure TEmvSource.DecodeIndex(const AIndex: Integer; out AApp, APart: Integer);
var N: Integer;
begin N := AIndex; if O.ReadDirectory then Dec(N); AApp := N div Width; APart := N mod Width; end;
function TEmvSource.Describe(const AIndex: Integer): TCardInspectionSection;
var App, Part: Integer; Suffix: string;
begin
  Result := Default(TCardInspectionSection);
  if O.ReadDirectory and (AIndex = 0) then
  begin Result.Key := 'directory'; Result.Caption := 'Application directory'; Exit; end;
  DecodeIndex(AIndex, App, Part);
  Suffix := 'application';
  if O.ReadCounters and (Part in [1, 2, 3]) then
    case Part of 1: Suffix := 'atc'; 2: Suffix := 'lastOnlineAtc'; 3: Suffix := 'pinRetries'; end
  else if Part > 0 then Suffix := 'log';
  Result.Key := 'aid.' + BytesToHex(Apps[App].Aid) + '.' + Suffix;
  Result.Caption := UnicodeString(BytesToHex(Apps[App].Aid) + ' / ' + Suffix);
end;
function TEmvSource.ReadSection(const AIndex: Integer): TCardInspectionSection;
var App, Part, I, J: Integer; D: TEmvDirectoryData; A: TEmvApplicationData;
  C: TEmvDataObjectResult; L: TEmvTransactionLogData;
begin
  Result := Describe(AIndex); Result.Status := cisRead;
  try
    if O.ReadDirectory and (AIndex = 0) then
    begin
      D := R.DiscoverApplications(O.Directory);
      if not D.Present then begin CardInspectionRefusal(Result, $6A82); Exit; end;
      AddCardInspectionField(Result, 'fci', 'Directory FCI', '', True, True, D.Fci);
      for I := 0 to High(D.Applications) do
      begin
        AddCardInspectionField(Result, 'aid.' + IntToStr(I), 'Application AID', UnicodeString(BytesToHex(D.Applications[I].Aid)));
        AddCardInspectionField(Result, 'label.' + IntToStr(I), 'Application label', D.Applications[I].LabelText);
      end;
      Exit;
    end;
    DecodeIndex(AIndex, App, Part);
    if Part = 0 then
    begin
      if O.ScanRecords then A := R.ReadApplicationWithRecordScan(Apps[App].Aid, Apps[App].TerminalValues, O.FirstSfi, O.LastSfi, O.FirstRecord, O.LastRecord)
      else A := R.ReadApplication(Apps[App].Aid, Apps[App].TerminalValues);
      AddCardInspectionField(Result, 'label', 'Application label', A.ApplicationInfo.LabelText);
      AddCardInspectionField(Result, 'pan', 'PAN', A.Pan, True);
      AddCardInspectionField(Result, 'name', 'Cardholder name', A.CardholderName, True);
      AddCardInspectionField(Result, 'iban', 'IBAN (unverified)', A.Iban, True);
      AddCardInspectionField(Result, 'expiry', 'Expiry YYMM', A.ExpiryMonth, True);
      AddCardInspectionField(Result, 'expiryDate', 'Expiry YYMMDD (when present)', A.ExpiryDate, True);
      AddCardInspectionField(Result, 'serviceCode', 'Service code', A.ServiceCode, True);
      AddCardInspectionField(Result, 'track2', 'Track 2 equivalent', '', True, True, A.Track2Equivalent);
      for I := 0 to High(A.Afl) do
        AddCardInspectionField(Result, 'afl.' + IntToStr(I), 'AFL entry', UnicodeString('SFI ' + IntToStr(A.Afl[I].Sfi) +
          ', records ' + IntToStr(A.Afl[I].FirstRecord) + '-' + IntToStr(A.Afl[I].LastRecord) +
          ', offline authentication records ' + IntToStr(A.Afl[I].OfflineAuthRecords)));
      AddCardInspectionField(Result, 'aip', 'Application interchange profile', UnicodeString(BytesToHex(A.Aip)));
      AddCardInspectionField(Result, 'recordCount', 'Acquired record count', UnicodeString(IntToStr(Length(A.Records))));
      AddCardInspectionField(Result, 'fci', 'FCI', '', True, True, A.Fci);
      AddCardInspectionField(Result, 'gpo', 'GPO', '', True, True, A.Gpo);
      for I := 0 to High(A.Fields) do
        AddCardInspectionField(Result, 'field.' + IntToStr(I), 'Tag ' + UnicodeString(BytesToHex(A.Fields[I].Tag)), '', True, True, A.Fields[I].Value);
      for I := 0 to High(A.Records) do
        AddCardInspectionField(Result, 'record.' + IntToStr(I), UnicodeString('SFI ' + IntToStr(A.Records[I].Sfi) + ' record ' + IntToStr(A.Records[I].Number)), '', True, True, A.Records[I].RawData);
      for I := 0 to High(A.Probes) do
      begin
        AddCardInspectionField(Result, 'probe.' + IntToStr(I), UnicodeString('SFI ' + IntToStr(A.Probes[I].Sfi) + ' record ' + IntToStr(A.Probes[I].Number) + ' status'), UnicodeString(IntToHex(A.Probes[I].StatusWord, 4)));
        if ((A.Probes[I].StatusWord = $6982) or (A.Probes[I].StatusWord = $6985)) then begin Result.Status := cisAuthenticationRequired; Result.StatusWord := A.Probes[I].StatusWord; end;
      end;
    end
    else if O.ReadCounters and (Part in [1, 2, 3]) then
    begin
      C := R.ReadDataObject(Apps[App].Aid, TEmvDataObject(Part - 1));
      if not C.Present then begin CardInspectionRefusal(Result, C.StatusWord); Exit; end;
      AddCardInspectionField(Result, 'counter', 'Counter', UnicodeString(IntToStr(C.NumericValue)), True);
    end
    else
    begin
      L := R.ReadTransactionLog(Apps[App].Aid);
      if not L.Supported then begin Result.Status := cisUnavailable; Exit; end;
      AddCardInspectionField(Result, 'recordCount', 'Transaction log records', UnicodeString(IntToStr(Length(L.Records))));
      for I := 0 to High(L.Records) do
      begin
        AddCardInspectionField(Result, 'record.' + IntToStr(I), 'Log record', '', True, True, L.Records[I].RawData);
        for J := 0 to High(L.Records[I].Fields) do
          AddCardInspectionField(Result, 'record.' + IntToStr(I) + '.field.' + IntToStr(J), 'Tag ' + UnicodeString(BytesToHex(L.Records[I].Fields[J].Tag)), '', True, True, L.Records[I].Fields[J].Value);
      end;
    end;
  except on E: EEmvStatusError do begin CardInspectionRefusal(Result, E.StatusWord); Result.ErrorClass := E.ClassName; end; end;
end;

procedure TEmvInspectionWorkflow.PrepareEmv(const AReader: TEMVCardReader;
  const AApplications: TEmvInspectionApplications; const AOptions: TEmvInspectionOptions);
var S: ICardInspectionSource;
begin
  RequireIdle;
  if AReader = nil then raise ECardWorkflowError.Create('Configure an EMV reader.');
  if Length(AApplications) > 16 then raise ECardWorkflowError.Create('Too many EMV applications.');
  S := TEmvSource.Create(AReader, AApplications, AOptions); inherited Prepare(S, AReader.Transport);
end;

end.
