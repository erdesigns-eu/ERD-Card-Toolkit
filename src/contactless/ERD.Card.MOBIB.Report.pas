unit ERD.Card.MOBIB.Report;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Bytes, ERD.Card.EN1545, ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data,
  ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Lookup;

type
  /// <summary>One node of the report tree; nodes are stored parent-first.</summary>
  TMobibReportNode = record
    /// <summary>Index of the parent node, -1 for a top-level section.</summary>
    Parent: Integer;
    /// <summary>Stable machine key, for example contract.2.end.</summary>
    Key: string;
    /// <summary>Display caption.</summary>
    Caption: string;
    /// <summary>Display value; empty for section and group nodes.</summary>
    Value: string;
    /// <summary>published, observed, unknown, or empty for derived values.</summary>
    Confidence: string;
    /// <summary>True for personal data; Value is masked unless ShowPersonal was set.</summary>
    Personal: Boolean;
    /// <summary>True when Value was replaced by the mask text.</summary>
    Masked: Boolean;
  end;

  /// <summary>Report tree in parent-first order.</summary>
  TMobibReportNodes = array of TMobibReportNode;

  /// <summary>Explicit report options.</summary>
  TMobibReportOptions = record
    /// <summary>Show birth date, postal code, card and application serial numbers and holder data.</summary>
    ShowPersonal: Boolean;
    /// <summary>Operator context chosen by the caller.</summary>
    Context: TMobibOperatorContext;
    /// <summary>True when Now is used for contract status.</summary>
    HasNow: Boolean;
    /// <summary>Caller-supplied local date for contract status; the clock is never read.</summary>
    Now: TDateTime;
  end;

  /// <summary>Builds a structured, masked-by-default MOBIB report for text, tree and JSON views.</summary>
  TMobibReport = class
  public
    /// <summary>Replacement text for masked personal values.</summary>
    const MaskText = '[masked]';
    /// <summary>Returns options with masking on, no status date and no operator context.</summary>
    /// <returns>Default options.</returns>
    class function DefaultOptions: TMobibReportOptions; static;
    /// <summary>Builds the report tree.</summary>
    /// <param name="AData">Decoded MOBIB data.</param>
    /// <param name="ASubscriptions">Decoded contracts.</param>
    /// <param name="ALookup">Optional lookup; nil creates one for AOptions.Context.</param>
    /// <param name="AOptions">Masking, context and status date.</param>
    /// <returns>Nodes in parent-first order.</returns>
    class function Build(const AData: TMobibData;
      const ASubscriptions: TMobibSubscriptions; const ALookup: TMobibLookup;
      const AOptions: TMobibReportOptions): TMobibReportNodes; static;
    /// <summary>Formats the tree as indented text; non-published confidence is shown in brackets.</summary>
    /// <param name="ANodes">Report tree.</param>
    /// <returns>Text with CRLF or platform line breaks.</returns>
    class function ToText(const ANodes: TMobibReportNodes): string; static;
    /// <summary>Formats the tree as nested JSON objects with key, caption, value, confidence and flags.</summary>
    /// <param name="ANodes">Report tree.</param>
    /// <returns>ASCII JSON text; non-ASCII characters are escaped.</returns>
    class function ToJson(const ANodes: TMobibReportNodes): string; static;
    /// <summary>Returns true when a logical file in the ticketing folder may hold personal data.</summary>
    /// <param name="AFile">Acquired file.</param>
    /// <returns>True for environment 2001, holder 2002 and 3F1C, and master-file 0003.</returns>
    class function IsPersonalFile(const AFile: TCalypsoFile): Boolean; static;
    /// <summary>Returns a display label such as Environment (2001), ICC (3F00/0002) or File (SFI 07).</summary>
    /// <param name="AFile">Acquired file.</param>
    /// <returns>Known file name with its folder-qualified identifier.</returns>
    class function FileLabel(const AFile: TCalypsoFile): string; static;
  end;

implementation

type
  TBuilder = record
    Nodes: TMobibReportNodes;
    Options: TMobibReportOptions;
    function Add(const AParent: Integer; const AKey, ACaption, AValue: string;
      const AConfidence: string = ''; const APersonal: Boolean = False): Integer;
  end;

function TBuilder.Add(const AParent: Integer; const AKey, ACaption, AValue,
  AConfidence: string; const APersonal: Boolean): Integer;
begin
  Result := Length(Nodes);
  SetLength(Nodes, Result + 1);
  Nodes[Result].Parent := AParent;
  Nodes[Result].Key := AKey;
  Nodes[Result].Caption := ACaption;
  Nodes[Result].Confidence := AConfidence;
  Nodes[Result].Personal := APersonal;
  if APersonal and (AValue <> '') and not Options.ShowPersonal then
  begin
    Nodes[Result].Value := TMobibReport.MaskText;
    Nodes[Result].Masked := True;
  end
  else
    Nodes[Result].Value := AValue;
end;

function Iso(const ADate: TDateTime): string;
begin
  Result := TEn1545.IsoDate(ADate);
end;

function Stamp(const ADate: TDateTime; const AMinutes: Word): string;
begin
  Result := Iso(ADate) + Format(' %2.2d:%2.2d', [AMinutes div 60, AMinutes mod 60]);
end;

function Conf(const AConfidence: TEn1545Confidence): string;
begin
  Result := TEn1545.ConfidenceName(AConfidence);
end;

function FieldConfidence(const AParsed: TEn1545Parsed; const APath: string): string;
var
  V: TEn1545Value;
begin
  if TEn1545.Find(AParsed, APath, V) then
    Result := Conf(V.Confidence)
  else
    Result := '';
end;

function FileName(const AFile: TCalypsoFile): string;
begin
  if (AFile.Folder = $3F00) then
    case AFile.LogicalId of
      $0002:
        Exit('ICC');
      $0003:
        Exit('ID');
    end;
  if AFile.Folder = $1000 then
    case AFile.LogicalId of
      $1014:
        Exit('Purse load log');
      $1015:
        Exit('Purse purchase log');
    end;
  case AFile.LogicalId of
    $2001:
      Result := 'Environment';
    $2002:
      Result := 'Holder';
    $2010:
      Result := 'Validation events';
    $2020, $2030:
      Result := 'Contracts';
    $202A .. $202D, $2069:
      Result := 'Counters';
    $2040:
      Result := 'Special events';
    $2050:
      Result := 'Contract list';
    $3F1C:
      Result := 'Extended holder';
  else
    Result := 'File';
  end;
end;

function StructureName(const S: TCalypsoFileStructure): string;
begin
  case S of
    cfsBinary:
      Result := 'binary';
    cfsLinear:
      Result := 'linear';
    cfsCyclic:
      Result := 'cyclic';
    cfsSimulatedCounters:
      Result := 'simulated counters';
    cfsCounters:
      Result := 'counters';
  else
    Result := 'unknown';
  end;
end;

function ProductName(const P: TCalypsoProductType): string;
begin
  case P of
    cptPrimeRevision2:
      Result := 'Calypso Prime revision 2';
    cptPrimeRevision3:
      Result := 'Calypso Prime revision 3';
    cptLight:
      Result := 'Calypso Light';
    cptBasic:
      Result := 'Calypso Basic';
  else
    Result := 'unknown';
  end;
end;

function StatusName(const S: TMobibContractStatus): string;
begin
  case S of
    mcsNotYetValid:
      Result := 'not yet valid';
    mcsActive:
      Result := 'active';
    mcsExpired:
      Result := 'expired';
  else
    Result := 'unknown (no stored start and end date)';
  end;
end;

function KindName(const K: TMobibSubscriptionKind): string;
begin
  case K of
    mskTrips:
      Result := 'trip product';
    mskTime:
      Result := 'time product';
    mskPeriod:
      Result := 'period pass';
  else
    Result := 'unknown';
  end;
end;

function YesNo(const B: Boolean): string;
begin
  if B then
    Result := 'yes'
  else
    Result := 'no';
end;

class function TMobibReport.DefaultOptions: TMobibReportOptions;
begin
  Result := Default (TMobibReportOptions);
  Result.Context := mocUnspecified;
end;

class function TMobibReport.IsPersonalFile(const AFile: TCalypsoFile): Boolean;
begin
  if AFile.Folder = $3F00 then
    Result := AFile.LogicalId = $0003
  else if (AFile.Folder = 0) or (AFile.Folder = $2000) then
    Result := (AFile.LogicalId = $2001) or (AFile.LogicalId = $2002) or
      (AFile.LogicalId = $3F1C)
  else
    Result := False;
end;

class function TMobibReport.FileLabel(const AFile: TCalypsoFile): string;
var
  Id: string;
begin
  if AFile.BySfi then
    Id := 'SFI ' + IntToHex(AFile.Sfi, 2)
  else
    Id := IntToHex(AFile.LogicalId, 4);
  if (AFile.Folder <> 0) and (AFile.Folder <> $2000) then
    Id := IntToHex(AFile.Folder, 4) + '/' + Id;
  if AFile.BySfi then
    Result := 'File (' + Id + ')'
  else
    Result := FileName(AFile) + ' (' + Id + ')';
end;

procedure AddEvent(var B: TBuilder; const AParent: Integer; const AKey: string;
  const E: TMobibEvent; const L: TMobibLookup);
var
  N: Integer;
  K, V: string;
begin
  K := AKey + '.' + IntToStr(E.RecordNumber);
  N := B.Add(AParent, K, 'Record ' + IntToStr(E.RecordNumber), '');
  B.Add(N, K + '.time', 'Date and time', Stamp(E.Date, E.Minutes), 'published');
  B.Add(N, K + '.version', 'Layout', Format('version %d, %s', [E.Version,
    E.Fields.Layout]), 'published');
  if E.HasFirstStamp then
    B.Add(N, K + '.first', 'First validation', Stamp(E.FirstDate, E.FirstMinutes), 'published');
  if E.HasProvider then
    V := L.TransportName(E.TransportCode);
    if Pos('unknown', V) <> 1 then
      V := V + Format(' (provider code %d)', [E.TransportCode]);
    B.Add(N, K + '.transport', 'Transport', V, 'published');
  B.Add(N, K + '.location', 'Location', L.DescribeLocation(E));
  if E.HasRoute then
    B.Add(N, K + '.route', 'Route', IntToStr(E.RouteNumber), 'published');
  if E.HasBusLocation then
    B.Add(N, K + '.stop', 'Stop code', IntToStr(E.BusLocationId), 'published');
  if E.HasStationLocation then
    B.Add(N, K + '.station', 'Zone / sub-zone / station', Format('%d / %d / %d',
      [E.Zone, E.SubZone, E.Station]), 'published');
  if E.HasPassengerCount then
    B.Add(N, K + '.passengers', 'Passengers', IntToStr(E.PassengerCount), 'published');
  if E.HasSerialNumber then
    B.Add(N, K + '.serial', 'Serial number', IntToStr(E.SerialNumber), 'published');
  if E.HasTransferNumber then
    B.Add(N, K + '.transfer', 'Transfer number', IntToStr(E.TransferNumber), 'published');
  if not E.Complete then
    B.Add(N, K + '.incomplete', 'Note', 'record ended before the layout; trailing fields absent');
end;

class function TMobibReport.Build(const AData: TMobibData;
  const ASubscriptions: TMobibSubscriptions; const ALookup: TMobibLookup;
  const AOptions: TMobibReportOptions): TMobibReportNodes;
var
  B: TBuilder;
  L: TMobibLookup;
  Own: Boolean;
  Sec, N, I, Active: Integer;
  S: TMobibSubscription;
  K, V, Counters: string;
  App: TCalypsoApplicationInfo;
  F: TCalypsoFile;
begin
  B := Default (TBuilder);
  B.Options := AOptions;
  Own := ALookup = nil;
  if Own then
    L := TMobibLookup.Create(AOptions.Context)
  else
    L := ALookup;
  try
    Sec := B.Add(-1, 'card', 'MOBIB CARD', '');
    if AData.LayoutMatched then
      B.Add(Sec, 'card.profile', 'Data profile', 'MOBIB 056/001 (matched)')
    else
      B.Add(Sec, 'card.profile', 'Data profile', 'no matching semantic layout');
    if AData.HasNetwork then
    begin
      if AData.CountryCode = 56 then
        B.Add(Sec, 'card.country', 'Country', 'Belgium (056)', 'published')
      else
        B.Add(Sec, 'card.country', 'Country code', Format('%3.3d', [AData.CountryCode]),
          'published');
      B.Add(Sec, 'card.network', 'Network', Format('%3.3d', [AData.NetworkCode]), 'published');
    end;
    B.Add(Sec, 'card.operator', 'Operator context', TMobibLookup.ContextName(L.Context) +
      ' (chosen by you)');
    B.Add(Sec, 'card.operator.note', 'Operator note', TMobibLookup.ContextNote(L.Context));

    Sec := B.Add(-1, 'overview', 'CARD OVERVIEW', '');
    App := AData.Raw.Application;
    if App.Valid then
    begin
      B.Add(Sec, 'overview.product', 'Calypso product', ProductName(App.ProductType), 'published');
      B.Add(Sec, 'overview.serial', 'Application serial number', BytesToHex(App.SerialNumber),
        'published', True);
      V := '';
      if App.HasPin then
        V := V + 'PIN, ';
      if App.HasStoredValue then
        V := V + 'stored value, ';
      if App.ExtendedMode then
        V := V + 'extended mode, ';
      if App.Pki then
        V := V + 'PKI, ';
      if App.Hce then
        V := V + 'HCE, ';
      if V = '' then
        V := 'none flagged'
      else
        SetLength(V, Length(V) - 2);
      B.Add(Sec, 'overview.features', 'Features', V, 'published');
      if App.BufferSizeBytes > 0 then
        B.Add(Sec, 'overview.buffer', 'Session buffer', IntToStr(App.BufferSizeBytes) + ' bytes',
          'published');
      if App.HasRecommendedDialect then
      begin
        if App.RecommendedDialect = cdLegacy94 then
          B.Add(Sec, 'overview.dialect', 'Recommended dialect',
            'legacy CLA 94 (advice only; not applied)')
        else
          B.Add(Sec, 'overview.dialect', 'Recommended dialect',
            'ISO CLA 00 (advice only; not applied)');
      end;
    end
    else if (App.StatusWord <> 0) and (App.StatusWord <> $9000) then
      B.Add(Sec, 'overview.application', 'Application information',
        'application not selected (SW ' + IntToHex(App.StatusWord, 4) + ')')
    else if App.StatusWord = $9000 then
      B.Add(Sec, 'overview.application', 'Application information',
        'selected; no serial number or startup information in the response')
    else
      B.Add(Sec, 'overview.application', 'Application information',
        'not read (set ApplicationName, for example 1TIC.ICA)');
    if AData.Environment.Present then
    begin
      B.Add(Sec, 'overview.envversion', 'Environment version',
        IntToStr(AData.Environment.Version), 'published');
      if AData.Environment.HasExpiry then
        B.Add(Sec, 'overview.expiry', 'Card expiry', Iso(AData.Environment.Expiry),
          FieldConfidence(AData.Environment.Fields, 'EnvApplicationValidityEndDate'));
      if AData.Environment.HasCardNumber then
        B.Add(Sec, 'overview.cardnumber', 'Card number',
          string(AData.Environment.CardNumberFormatted), 'published', True);
      if AData.Environment.HasBirthDate then
        B.Add(Sec, 'overview.birthdate', 'Birth date', Iso(AData.Environment.BirthDate),
          'published', True);
      if AData.Environment.HasPostalCode then
        B.Add(Sec, 'overview.postal', 'Postal code', IntToStr(AData.Environment.PostalCode),
          'published', True);
      if AData.Environment.Personalised then
        B.Add(Sec, 'overview.type', 'Card type', 'personal (holder data present)')
      else
        B.Add(Sec, 'overview.type', 'Card type', 'anonymous (no holder data in environment)');
    end;
    if AData.HasCardPurchaseDate then
      B.Add(Sec, 'overview.purchase', 'Card purchase date', Iso(AData.CardPurchaseDate),
        'observed');
    if AData.Icc.Present then
    begin
      V := AData.Icc.ManufacturerName;
      if V = '' then
        V := 'unknown';
      V := Format('%s (code %d), country %s', [V, AData.Icc.ManufacturerCode,
        AData.Icc.CountryCode]);
      if AData.Icc.HasManufactureDate then
        V := V + ', manufactured ' + Iso(AData.Icc.ManufactureDate);
      B.Add(Sec, 'overview.chip', 'Chip', V, 'published');
    end;
    if AOptions.HasNow then
    begin
      Active := 0;
      for I := 0 to High(ASubscriptions) do
        if ASubscriptions[I].LayoutMatched and (ASubscriptions[I].DuplicateOf = 0) and
          (TMobibSubscriptionCodec.StatusAt(ASubscriptions[I], AOptions.Now) = mcsActive) then
          Inc(Active);
      B.Add(Sec, 'overview.active', 'Active contracts on ' + Iso(AOptions.Now), IntToStr(Active));
    end;

    Sec := B.Add(-1, 'holder', 'HOLDER', '');
    if AData.Holder.Present then
    begin
      B.Add(Sec, 'holder.name', 'Name', string(AData.Holder.Name), 'published', True);
      B.Add(Sec, 'holder.number', 'Cardholder number', string(AData.Holder.Number), 'published',
        True);
      if AData.Holder.HasBirthDate then
        B.Add(Sec, 'holder.birthdate', 'Birth date', Iso(AData.Holder.BirthDate), 'published',
          True);
      B.Add(Sec, 'holder.gender', 'Gender field', 'code ' + IntToStr(AData.Holder.GenderCode),
        'published', True);
    end
    else
      B.Add(Sec, 'holder.none', 'Holder details', 'not available in the decoded records');

    N := 0;
    for I := 0 to High(ASubscriptions) do
      if ASubscriptions[I].DuplicateOf > 0 then
        Inc(N);
    if N > 0 then
      V := Format('CONTRACTS (%d decoded, %d duplicate)', [Length(ASubscriptions), N])
    else
      V := Format('CONTRACTS (%d decoded)', [Length(ASubscriptions)]);
    Sec := B.Add(-1, 'contracts', V, '');
    if AData.HasContractCount then
      B.Add(Sec, 'contracts.count', 'Contract list count', IntToStr(AData.ContractCount),
        'published');
    if AData.ContractList.Present and (Length(AData.ContractList.Entries) > 0) then
    begin
      V := '';
      for I := 0 to High(AData.ContractList.Entries) do
      begin
        if I > 0 then
          V := V + ' ';
        V := V + IntToHex(AData.ContractList.Entries[I], 7);
      end;
      B.Add(Sec, 'contracts.list', 'Contract list entries (candidate 28-bit split)', V,
        Conf(AData.ContractList.Confidence));
    end;
    for I := 0 to High(ASubscriptions) do
    begin
      S := ASubscriptions[I];
      K := 'contract.' + IntToStr(S.RecordNumber);
      N := B.Add(Sec, K, 'Contract ' + IntToStr(S.RecordNumber), '');
      if not S.LayoutMatched then
      begin
        B.Add(N, K + '.unsupported', 'Unsupported record layout', 'version ' +
          IntToStr(S.Version));
        Continue;
      end;
      if S.DuplicateOf <> 0 then
        B.Add(N, K + '.duplicate', 'Duplicate', 'identical to contract ' +
          IntToStr(S.DuplicateOf) + '; not counted twice');
      B.Add(N, K + '.product', 'Product', L.TariffName(S.Tariff, S.ProductName), 'published');
      B.Add(N, K + '.kind', 'Kind', KindName(S.Kind), Conf(S.KindConfidence));
      if S.HasStartDate then
        B.Add(N, K + '.start', 'Valid from', Iso(S.StartDate), 'observed');
      if S.HasEndDate then
        B.Add(N, K + '.end', 'Valid until', Iso(S.EndDate),
          FieldConfidence(S.Fields, 'ContractEnd'));
      if AOptions.HasNow then
        B.Add(N, K + '.status', 'Status on ' + Iso(AOptions.Now),
          StatusName(TMobibSubscriptionCodec.StatusAt(S, AOptions.Now)));
      B.Add(N, K + '.price', 'Purchase price', Format('EUR %d.%2.2d',
        [S.PriceCents div 100, S.PriceCents mod 100]), 'published');
      if S.HasSaleDate and not S.HasStartDate then
        B.Add(N, K + '.sale', 'Purchase date', Iso(S.SaleDate), 'published');
      if S.HasDuration then
        if S.DurationUnit = mcdMonths then
        begin
          if S.DurationValue = 1 then
            V := '1 month'
          else
            V := IntToStr(S.DurationValue) + ' months';
          B.Add(N, K + '.duration', 'Duration', V + Format(' (unit code %d)',
            [S.DurationUnitCode]), 'observed');
        end
        else
          B.Add(N, K + '.duration', 'Duration', Format('%d (unit code %d; unit not mapped)',
            [S.DurationValue, S.DurationUnitCode]), 'unknown');
      if S.HasCounter then
      begin
        V := Format('%d (counter-use code %d', [S.Counter, S.CounterUse]);
        if S.CounterSourceFileId <> 0 then
          V := V + ', file ' + IntToHex(S.CounterSourceFileId, 4);
        B.Add(N, K + '.counter', 'Associated counter', V + ')', 'published');
        if S.HasRemainingTrips and (S.Kind = mskTrips) and (S.ProductName <> '') then
          B.Add(N, K + '.trips', 'Remaining trips', IntToStr(S.RemainingTrips), 'published');
      end
      else if S.Kind <> mskPeriod then
        B.Add(N, K + '.counter', 'Associated counter', 'not acquired');
    end;

    Sec := B.Add(-1, 'events', Format('VALIDATIONS (%d decoded)', [Length(AData.Events)]), '');
    if Length(AData.Events) = 0 then
      B.Add(Sec, 'events.none', 'Validation events', 'none recorded');
    for I := 0 to High(AData.Events) do
      AddEvent(B, Sec, 'event', AData.Events[I], L);
    Sec := B.Add(-1, 'special', Format('SPECIAL EVENTS (%d decoded)',
      [Length(AData.SpecialEvents)]), '');
    if Length(AData.SpecialEvents) = 0 then
      B.Add(Sec, 'special.none', 'Special events', 'none recorded');
    for I := 0 to High(AData.SpecialEvents) do
      AddEvent(B, Sec, 'special', AData.SpecialEvents[I], L);
    if AData.UnsupportedEventCount > 0 then
      B.Add(Sec, 'events.unsupported', 'Events with unsupported versions',
        IntToStr(AData.UnsupportedEventCount) + ' (kept raw)');

    Sec := B.Add(-1, 'counters', Format('COUNTERS (%d slots)', [Length(AData.Counters)]), '');
    Counters := '';
    for I := 0 to High(AData.Counters) do
    begin
      if I > 0 then
        Counters := Counters + '; ';
      Counters := Counters + Format('file %s record %d slot %d = %d',
        [IntToHex(AData.Counters[I].SourceFileId, 4), AData.Counters[I].RecordNumber,
        AData.Counters[I].Slot, AData.Counters[I].Value]);
    end;
    if Counters = '' then
      Counters := 'none acquired';
    B.Add(Sec, 'counters.values', 'Counters', Counters, 'published');

    Sec := -1;
    for I := 0 to High(AData.Raw.Files) do
    begin
      F := AData.Raw.Files[I];
      if not F.Info.Present then
        Continue;
      if Sec < 0 then
        Sec := B.Add(-1, 'files', 'FILE INFORMATION', '');
      if F.BySfi then
        K := Format('file.%s.sfi%s', [IntToHex(F.Folder, 4), IntToHex(F.Sfi, 2)])
      else
        K := Format('file.%s.%s', [IntToHex(F.Folder, 4), IntToHex(F.LogicalId, 4)]);
      V := Format('%s, SFI %s, %d records of %d bytes', [StructureName(F.Info.Structure),
        IntToHex(F.Info.Sfi, 2), F.Info.RecordCount, F.Info.RecordSize]);
      B.Add(Sec, K, FileLabel(F), V, 'published');
    end;
  finally
    if Own then
      L.Free;
  end;
  Result := B.Nodes;
end;

class function TMobibReport.ToText(const ANodes: TMobibReportNodes): string;
var
  Depth: array of Integer;
  I: Integer;
  Line: string;
begin
  Result := '';
  SetLength(Depth, Length(ANodes));
  for I := 0 to High(ANodes) do
  begin
    if ANodes[I].Parent < 0 then
    begin
      Depth[I] := 0;
      if I > 0 then
        Result := Result + sLineBreak;
      Result := Result + ANodes[I].Caption + sLineBreak;
      Continue;
    end;
    Depth[I] := Depth[ANodes[I].Parent] + 1;
    Line := StringOfChar(' ', 2 * (Depth[I] - 1)) + ANodes[I].Caption;
    if ANodes[I].Value <> '' then
      Line := Line + ': ' + ANodes[I].Value;
    if (ANodes[I].Confidence = 'observed') or (ANodes[I].Confidence = 'unknown') then
      Line := Line + ' [' + ANodes[I].Confidence + ']';
    if (Depth[I] = 1) and (ANodes[I].Value = '') then
      Result := Result + sLineBreak;
    Result := Result + Line + sLineBreak;
  end;
end;

function JsonString(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '"';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':
        Result := Result + '\"';
      '\':
        Result := Result + '\\';
      #8:
        Result := Result + '\b';
      #9:
        Result := Result + '\t';
      #10:
        Result := Result + '\n';
      #12:
        Result := Result + '\f';
      #13:
        Result := Result + '\r';
    else
      if (Ord(C) < 32) or (Ord(C) > 126) then
        Result := Result + '\u' + IntToHex(Ord(C), 4)
      else
        Result := Result + C;
    end;
  end;
  Result := Result + '"';
end;

function JsonNode(const ANodes: TMobibReportNodes; const AIndex: Integer): string;
var
  I: Integer;
  First: Boolean;
begin
  Result := '{"key":' + JsonString(ANodes[AIndex].Key) + ',"caption":' +
    JsonString(ANodes[AIndex].Caption);
  if ANodes[AIndex].Value <> '' then
    Result := Result + ',"value":' + JsonString(ANodes[AIndex].Value);
  if ANodes[AIndex].Confidence <> '' then
    Result := Result + ',"confidence":' + JsonString(ANodes[AIndex].Confidence);
  if ANodes[AIndex].Personal then
    Result := Result + ',"personal":true';
  if ANodes[AIndex].Masked then
    Result := Result + ',"masked":true';
  First := True;
  for I := AIndex + 1 to High(ANodes) do
    if ANodes[I].Parent = AIndex then
    begin
      if First then
        Result := Result + ',"children":['
      else
        Result := Result + ',';
      First := False;
      Result := Result + JsonNode(ANodes, I);
    end;
  if not First then
    Result := Result + ']';
  Result := Result + '}';
end;

class function TMobibReport.ToJson(const ANodes: TMobibReportNodes): string;
var
  I: Integer;
  First: Boolean;
begin
  Result := '{"format":"erd-card-mobib-report","version":1,"sections":[';
  First := True;
  for I := 0 to High(ANodes) do
    if ANodes[I].Parent < 0 then
    begin
      if not First then
        Result := Result + ',';
      First := False;
      Result := Result + JsonNode(ANodes, I);
    end;
  Result := Result + ']}';
end;

end.
