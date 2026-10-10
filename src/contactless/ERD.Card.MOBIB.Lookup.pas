unit ERD.Card.MOBIB.Lookup;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.MOBIB.Data;

type
  /// <summary>Operator context chosen explicitly by the caller; network 056/001 is shared by all Belgian operators.</summary>
  TMobibOperatorContext = (
    /// <summary>No operator chosen; generic STIB-published transport names, no stop tables.</summary>
    mocUnspecified,
    /// <summary>STIB-MIVB (Brussels); bundled MOBIB Extractor stop tables are used.</summary>
    mocStib,
    /// <summary>De Lijn (Flanders); no public stop or tariff table, caller tables only.</summary>
    mocDeLijn,
    /// <summary>TEC (Wallonia); caller tables only.</summary>
    mocTec,
    /// <summary>SNCB/NMBS (Belgian railways); caller tables only.</summary>
    mocSncb);

  /// <summary>Key kind of a stop-table entry.</summary>
  TMobibStopKind = (
    /// <summary>Keyed by provider and seventeen-bit zone/sub-zone/station location.</summary>
    mstStation,
    /// <summary>Keyed by provider, line and twelve-bit bus-location code.</summary>
    mstBusStop);

  /// <summary>One stop-table entry, bundled or caller supplied.</summary>
  TMobibStop = record
    /// <summary>Entry key kind.</summary>
    Kind: TMobibStopKind;
    /// <summary>Five-bit event provider code the entry applies to.</summary>
    Provider: Byte;
    /// <summary>Seventeen-bit station location (zone shl 11, sub-zone shl 7, station) for station entries.</summary>
    Location: Cardinal;
    /// <summary>Line number for bus-stop entries.</summary>
    LineNumber: Word;
    /// <summary>Twelve-bit bus-location code for bus-stop entries.</summary>
    Code: Word;
    /// <summary>Line label.</summary>
    Line: string;
    /// <summary>Stop or station name.</summary>
    Name: string;
    /// <summary>Direction, when the table provides one.</summary>
    Direction: string;
    /// <summary>Origin of the entry, e.g. bundled table or caller CSV.</summary>
    Source: string;
  end;

  /// <summary>Caller-owned stop list.</summary>
  TMobibStops = array of TMobibStop;

  /// <summary>Caller-supplied tariff label.</summary>
  TMobibTariffName = record
    /// <summary>Fourteen-bit tariff code.</summary>
    Tariff: Word;
    /// <summary>Product label supplied by the caller.</summary>
    Name: string;
  end;

  /// <summary>Operator, transport, stop and tariff names with explicit unknown fallbacks; never guesses.</summary>
  TMobibLookup = class
  private
    FContext: TMobibOperatorContext;
    FStops: TMobibStops;
    FTariffs: array of TMobibTariffName;
    function FindTariff(const ATariff: Word; out AName: string): Boolean;
  public
    /// <summary>Creates a lookup for an explicit operator context.</summary>
    /// <param name="AContext">Operator context; mocStib enables the bundled Brussels tables.</param>
    constructor Create(const AContext: TMobibOperatorContext);
    /// <summary>Returns the display name of an operator context.</summary>
    /// <param name="AContext">Context.</param>
    /// <returns>Operator name.</returns>
    class function ContextName(const AContext: TMobibOperatorContext): string; static;
    /// <summary>Returns what is and is not publicly known for an operator context.</summary>
    /// <param name="AContext">Context.</param>
    /// <returns>Plain-text note for reports.</returns>
    class function ContextNote(const AContext: TMobibOperatorContext): string; static;
    /// <summary>Decodes \uXXXX escapes used by bundled tables.</summary>
    /// <param name="AText">Escaped ASCII text.</param>
    /// <returns>Unicode text.</returns>
    class function Unescape(const AText: string): string; static;
    /// <summary>Adds one stop entry; later entries never replace earlier ones.</summary>
    /// <param name="AStop">Entry to add.</param>
    procedure AddStop(const AStop: TMobibStop);
    /// <summary>Adds or replaces a caller-supplied tariff label.</summary>
    /// <param name="ATariff">Fourteen-bit tariff code.</param>
    /// <param name="AName">Product label.</param>
    procedure AddTariff(const ATariff: Word; const AName: string);
    /// <summary>Loads caller CSV rows: station,provider,zone,subzone,station,line,name;
    /// stop,provider,line,code,name[,direction]; tariff,code,name. Blank lines and # comments are ignored.</summary>
    /// <param name="AText">CSV text; fields may be double-quoted.</param>
    /// <param name="ASource">Source label stored on each entry.</param>
    /// <returns>Number of rows loaded; malformed rows raise EMobibDecodeError.</returns>
    function LoadCsv(const AText, ASource: string): Integer;
    /// <summary>Returns a transport-mode name for an event provider code in this context.</summary>
    /// <param name="ACode">Five-bit provider code.</param>
    /// <returns>Name, or "unknown (code N)".</returns>
    function TransportName(const ACode: Byte): string;
    /// <summary>Returns the product label of a tariff: published, caller supplied, or "unknown (tariff 0xNNNN)".</summary>
    /// <param name="ATariff">Fourteen-bit tariff code.</param>
    /// <param name="APublishedName">Name already decoded by the subscription codec, or empty.</param>
    /// <returns>Label.</returns>
    function TariffName(const ATariff: Word; const APublishedName: string): string;
    /// <summary>Finds the stop of an event using the tables of this context.</summary>
    /// <param name="AEvent">Decoded event.</param>
    /// <param name="AStop">Matching entry.</param>
    /// <returns>True when an entry matched.</returns>
    function FindStop(const AEvent: TMobibEvent; out AStop: TMobibStop): Boolean;
    /// <summary>Describes an event location as text with an explicit unknown fallback.</summary>
    /// <param name="AEvent">Decoded event.</param>
    /// <returns>Stop name with line, or raw codes.</returns>
    function DescribeLocation(const AEvent: TMobibEvent): string;
    /// <summary>Number of loaded stop entries.</summary>
    /// <returns>Count.</returns>
    function StopCount: Integer;
    /// <summary>Operator context.</summary>
    property Context: TMobibOperatorContext read FContext;
  end;

implementation

uses
  ERD.Card.MOBIB.Brussels, ERD.Card.EN1545;

type
  TCsvFields = array of string;

procedure Fail;
begin
  raise EMobibDecodeError.Create('Invalid MOBIB lookup table row.');
end;

constructor TMobibLookup.Create(const AContext: TMobibOperatorContext);
var
  I: Integer;
  S: TMobibStop;
begin
  inherited Create;
  if (Ord(AContext) < Ord(Low(TMobibOperatorContext))) or
    (Ord(AContext) > Ord(High(TMobibOperatorContext))) then
    Fail;
  FContext := AContext;
  if AContext <> mocStib then
    Exit;
  for I := Low(MobibBrusselsStations) to High(MobibBrusselsStations) do
  begin
    S := Default (TMobibStop);
    S.Kind := mstStation;
    S.Provider := MobibBrusselsStations[I].Provider;
    S.Location := (Cardinal(MobibBrusselsStations[I].Zone) shl 11) or
      (Cardinal(MobibBrusselsStations[I].SubZone) shl 7) or
      MobibBrusselsStations[I].Station;
    S.Line := MobibBrusselsStations[I].Line;
    S.Name := Unescape(MobibBrusselsStations[I].Name);
    S.Source := 'MOBIB Extractor Metro.csv';
    AddStop(S);
  end;
  for I := Low(MobibBrusselsBusStops) to High(MobibBrusselsBusStops) do
  begin
    S := Default (TMobibStop);
    S.Kind := mstBusStop;
    S.Provider := 15;
    S.LineNumber := MobibBrusselsBusStops[I].Line;
    S.Code := MobibBrusselsBusStops[I].Code;
    S.Line := IntToStr(S.LineNumber);
    S.Name := Unescape(MobibBrusselsBusStops[I].Name);
    S.Direction := Unescape(MobibBrusselsBusStops[I].Direction);
    S.Source := 'MOBIB Extractor Bus.csv';
    AddStop(S);
  end;
end;

class function TMobibLookup.ContextName(const AContext
  : TMobibOperatorContext): string;
begin
  case AContext of
    mocStib:
      Result := 'STIB-MIVB';
    mocDeLijn:
      Result := 'De Lijn';
    mocTec:
      Result := 'TEC';
    mocSncb:
      Result := 'SNCB-NMBS';
  else
    Result := 'Unspecified operator';
  end;
end;

class function TMobibLookup.ContextNote(const AContext
  : TMobibOperatorContext): string;
const
  Shared = 'MOBIB network 056/001 is shared by STIB-MIVB, De Lijn, TEC and ' +
    'SNCB-NMBS; the card does not name the operator, so this context was chosen by the caller.';
begin
  case AContext of
    mocStib:
      Result := Shared + ' Stop names come from the MOBIB Extractor Brussels tables (2009); ' +
        'newer stops and line changes are missing.';
    mocDeLijn:
      Result := Shared + ' De Lijn (Flanders) publishes no stop-code or tariff-code ' +
        'table for MOBIB; load your own CSV to name stops and products. Publicly known ' +
        'De Lijn subscriptions include Buzzy Pazz (6-24), Omnipas (25-64) and ' +
        'Omnipas 65+, but their tariff codes are not published, so none is assigned.';
    mocTec:
      Result := Shared + ' TEC publishes no stop-code or tariff-code table for MOBIB; ' +
        'load your own CSV.';
    mocSncb:
      Result := Shared + ' SNCB-NMBS publishes no station-code or tariff-code table ' +
        'for MOBIB; load your own CSV.';
  else
    Result := Shared + ' Choose an operator context to enable stop tables.';
  end;
end;

class function TMobibLookup.Unescape(const AText: string): string;
var
  I, Code: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(AText) do
  begin
    if (AText[I] = '\') and (I < Length(AText)) and (AText[I + 1] = '\') then
    begin
      Result := Result + '\';
      Inc(I, 2);
    end
    else if (AText[I] = '\') and (I + 5 <= Length(AText)) and
      (AText[I + 1] = 'u') and
      TryStrToInt('$' + Copy(AText, I + 2, 4), Code) then
    begin
      Result := Result + string(WideChar(Code));
      Inc(I, 6);
    end
    else
    begin
      Result := Result + AText[I];
      Inc(I);
    end;
  end;
end;

procedure TMobibLookup.AddStop(const AStop: TMobibStop);
var
  N: Integer;
begin
  if (Length(FStops) >= 100000) or (AStop.Provider > 31) or
    (AStop.Location > $1FFFF) or (AStop.Code > $FFF) or (Trim(AStop.Name) = '') then
    Fail;
  N := Length(FStops);
  SetLength(FStops, N + 1);
  FStops[N] := AStop;
end;

procedure TMobibLookup.AddTariff(const ATariff: Word; const AName: string);
var
  I, N: Integer;
begin
  if (ATariff > $3FFF) or (Trim(AName) = '') or (Length(FTariffs) >= 16384) then
    Fail;
  for I := 0 to High(FTariffs) do
    if FTariffs[I].Tariff = ATariff then
    begin
      FTariffs[I].Name := AName;
      Exit;
    end;
  N := Length(FTariffs);
  SetLength(FTariffs, N + 1);
  FTariffs[N].Tariff := ATariff;
  FTariffs[N].Name := AName;
end;

function SplitCsv(const ALine: string): TCsvFields;
var
  I, N: Integer;
  Field: string;
  Quoted: Boolean;
begin
  Result := nil;
  Field := '';
  Quoted := False;
  I := 1;
  while I <= Length(ALine) do
  begin
    if Quoted then
    begin
      if ALine[I] = '"' then
      begin
        if (I < Length(ALine)) and (ALine[I + 1] = '"') then
        begin
          Field := Field + '"';
          Inc(I);
        end
        else
          Quoted := False;
      end
      else
        Field := Field + ALine[I];
    end
    else if ALine[I] = '"' then
      Quoted := True
    else if ALine[I] = ',' then
    begin
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := Trim(Field);
      Field := '';
    end
    else
      Field := Field + ALine[I];
    Inc(I);
  end;
  if Quoted then
    Fail;
  N := Length(Result);
  SetLength(Result, N + 1);
  Result[N] := Trim(Field);
end;

function ParseNumber(const AText: string; const AMax: Cardinal): Cardinal;
var
  V: Int64;
  T: string;
begin
  T := Trim(AText);
  if (Length(T) > 2) and (T[1] = '0') and ((T[2] = 'x') or (T[2] = 'X')) then
    T := '$' + Copy(T, 3, MaxInt);
  if not TryStrToInt64(T, V) or (V < 0) or (V > AMax) then
    Fail;
  Result := Cardinal(V);
end;

function TMobibLookup.LoadCsv(const AText, ASource: string): Integer;
var
  Lines: TCsvFields;
  F: TCsvFields;
  Line, Kind: string;
  S: TMobibStop;
  I, Start: Integer;
  Text: string;
begin
  Result := 0;
  if Length(AText) > 16 * 1024 * 1024 then
    Fail;
  Lines := nil;
  Text := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  Text := StringReplace(Text, #13, #10, [rfReplaceAll]);
  Start := 1;
  for I := 1 to Length(Text) + 1 do
    if (I > Length(Text)) or (Text[I] = #10) then
    begin
      SetLength(Lines, Length(Lines) + 1);
      Lines[High(Lines)] := Copy(Text, Start, I - Start);
      Start := I + 1;
    end;
  for I := 0 to High(Lines) do
  begin
    Line := Trim(Lines[I]);
    if (Line = '') or (Line[1] = '#') then
      Continue;
    F := SplitCsv(Line);
    Kind := LowerCase(F[0]);
    S := Default (TMobibStop);
    S.Source := ASource;
    if Kind = 'station' then
    begin
      if Length(F) <> 7 then
        Fail;
      S.Kind := mstStation;
      S.Provider := Byte(ParseNumber(F[1], 31));
      S.Location := (ParseNumber(F[2], 63) shl 11) or (ParseNumber(F[3], 15) shl 7) or
        ParseNumber(F[4], 127);
      S.Line := F[5];
      S.Name := F[6];
      AddStop(S);
    end
    else if Kind = 'stop' then
    begin
      if (Length(F) < 5) or (Length(F) > 6) then
        Fail;
      S.Kind := mstBusStop;
      S.Provider := Byte(ParseNumber(F[1], 31));
      S.LineNumber := Word(ParseNumber(F[2], $FFFF));
      S.Line := F[2];
      S.Code := Word(ParseNumber(F[3], $FFF));
      S.Name := F[4];
      if Length(F) = 6 then
        S.Direction := F[5];
      AddStop(S);
    end
    else if Kind = 'tariff' then
    begin
      if Length(F) <> 3 then
        Fail;
      AddTariff(Word(ParseNumber(F[1], $3FFF)), F[2]);
    end
    else if Kind = 'kind' then
      Continue
    else
      Fail;
    Inc(Result);
  end;
end;

function TMobibLookup.TransportName(const ACode: Byte): string;
begin
  Result := '';
  if FContext in [mocUnspecified, mocStib] then
    case ACode of
      0:
        Result := 'metro';
      7:
        Result := 'premetro';
      15:
        Result := 'bus';
      22:
        Result := 'tram';
    end;
  if Result = '' then
    Result := Format('unknown (code %d)', [ACode]);
end;

function TMobibLookup.FindTariff(const ATariff: Word; out AName: string): Boolean;
var
  I: Integer;
begin
  AName := '';
  for I := 0 to High(FTariffs) do
    if FTariffs[I].Tariff = ATariff then
    begin
      AName := FTariffs[I].Name;
      Result := True;
      Exit;
    end;
  Result := False;
end;

function TMobibLookup.TariffName(const ATariff: Word;
  const APublishedName: string): string;
begin
  if FindTariff(ATariff, Result) then
    Exit;
  if APublishedName <> '' then
    Result := APublishedName
  else
    Result := Format('unknown (tariff 0x%.4X)', [ATariff]);
end;

function TMobibLookup.FindStop(const AEvent: TMobibEvent;
  out AStop: TMobibStop): Boolean;
var
  I: Integer;
  Line: Word;
  V: TEn1545Value;
begin
  AStop := Default (TMobibStop);
  Result := False;
  if not AEvent.HasProvider then
    Exit;
  { MOBIB Extractor special case: one Gare Centrale reader reports the Roodebeek location. }
  if (FContext = mocStib) and (AEvent.TransportCode = 0) and
    AEvent.HasStationLocation and (AEvent.StationLocationId = (7 shl 11) or (3 shl 7) or 45) and
    (TEn1545.Find(AEvent.Fields, 'EventUnknownE', V) or
    TEn1545.Find(AEvent.Fields, 'EventUnknownE1', V)) and (V.Raw = $2EA) then
  begin
    AStop.Kind := mstStation;
    AStop.Location := AEvent.StationLocationId;
    AStop.Line := '1A/1B';
    AStop.Name := 'Gare Centrale';
    AStop.Source := 'MOBIB Extractor special case';
    Result := True;
    Exit;
  end;
  if AEvent.LayoutKind = melLegacyFixed then
    Line := AEvent.BusRoute
  else
    Line := AEvent.RouteNumber;
  for I := 0 to High(FStops) do
    if FStops[I].Provider = AEvent.TransportCode then
      case FStops[I].Kind of
        mstStation:
          if AEvent.HasStationLocation and
            (FStops[I].Location = AEvent.StationLocationId) then
          begin
            AStop := FStops[I];
            Result := True;
            Exit;
          end;
        mstBusStop:
          if AEvent.HasBusLocation and AEvent.HasRoute and
            (FStops[I].Code = AEvent.BusLocationId) and (FStops[I].LineNumber = Line) then
          begin
            AStop := FStops[I];
            Result := True;
            Exit;
          end;
      end;
end;

function TMobibLookup.DescribeLocation(const AEvent: TMobibEvent): string;
var
  S: TMobibStop;
begin
  if FindStop(AEvent, S) then
  begin
    Result := S.Name;
    if S.Line <> '' then
      Result := Result + ' (line ' + S.Line;
    if S.Direction <> '' then
      Result := Result + ', direction ' + S.Direction;
    if S.Line <> '' then
      Result := Result + ')';
    Exit;
  end;
  if not AEvent.HasProvider then
    Result := 'unknown location (no provider field)'
  else if AEvent.HasStationLocation and (AEvent.TransportCode <> 15) then
    Result := Format('unknown location (zone %d, sub-zone %d, station %d)',
      [AEvent.Zone, AEvent.SubZone, AEvent.Station])
  else if AEvent.HasBusLocation then
    Result := Format('unknown stop (code %d, route %d)',
      [AEvent.BusLocationId, AEvent.RouteNumber])
  else
    Result := 'unknown location';
end;

function TMobibLookup.StopCount: Integer;
begin
  Result := Length(FStops);
end;

end.
