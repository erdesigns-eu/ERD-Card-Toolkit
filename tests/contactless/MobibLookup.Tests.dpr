program MobibLookupTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Lookup;

var
  Checks: Integer;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then
    raise Exception.Create('MOBIB lookup regression: ' + AMessage);
end;

function BusEvent(const ALine, ACode: Word): TMobibEvent;
begin
  Result := Default (TMobibEvent);
  Result.LayoutKind := melLegacyFixed;
  Result.HasProvider := True;
  Result.TransportCode := 15;
  Result.HasRoute := True;
  Result.RouteNumber := ALine;
  Result.BusRoute := Byte(ALine and $7F);
  Result.HasBusLocation := True;
  Result.BusLocationId := ACode;
end;

function StationEvent(const AProvider, AZone, ASubZone, AStation: Byte): TMobibEvent;
begin
  Result := Default (TMobibEvent);
  Result.LayoutKind := melBitmap;
  Result.HasProvider := True;
  Result.TransportCode := AProvider;
  Result.HasStationLocation := True;
  Result.StationLocationId := (Cardinal(AZone) shl 11) or (Cardinal(ASubZone) shl 7) or AStation;
  Result.Zone := AZone;
  Result.SubZone := ASubZone;
  Result.Station := AStation;
end;

function CsvFails(const L: TMobibLookup; const AText: string): Boolean;
begin
  Result := False;
  try
    L.LoadCsv(AText, 'test');
  except
    on E: EMobibDecodeError do
      Result := True;
  end;
end;

procedure Tests;
var
  L: TMobibLookup;
  S: TMobibStop;
  E: TMobibEvent;
begin
  L := TMobibLookup.Create(mocStib);
  try
    Check(L.StopCount = 69 + 1761, 'Bundled Brussels tables loaded for STIB');
    Check(L.FindStop(BusEvent(13, 1074), S) and (S.Name = 'UZ Brussel') and
      (S.Direction = 'Simonis') and (S.Line = '13'), 'Bus stop by line and code');
    Check(L.FindStop(StationEvent(0, 7, 3, 84), S) and (S.Name = 'Stockel') and (S.Line = '1B'),
      'Metro station by zone/sub-zone/station');
    Check(not L.FindStop(StationEvent(7, 7, 3, 84), S), 'Provider is part of the key');
    Check(L.DescribeLocation(BusEvent(13, 1074)) = 'UZ Brussel (line 13, direction Simonis)',
      'Location text');
    Check(L.DescribeLocation(StationEvent(0, 1, 2, 3)) =
      'unknown location (zone 1, sub-zone 2, station 3)', 'Unknown station fallback');
    Check(L.DescribeLocation(BusEvent(13, 4000)) = 'unknown stop (code 4000, route 13)',
      'Unknown bus fallback');
    Check((L.TransportName(0) = 'metro') and (L.TransportName(22) = 'tram') and
      (L.TransportName(3) = 'unknown (code 3)'), 'STIB transport names');
    Check(L.TariffName($2803, 'JUMP 10 trips') = 'JUMP 10 trips', 'Published tariff name kept');
    Check(L.TariffName($000F, '') = 'unknown (tariff 0x000F)', 'Unknown tariff not invented');
    Check(TMobibLookup.ContextName(L.Context) = 'STIB-MIVB', 'Context name');
  finally
    L.Free;
  end;

  L := TMobibLookup.Create(mocDeLijn);
  try
    Check(L.StopCount = 0, 'No bundled tables for De Lijn');
    Check(not L.FindStop(BusEvent(13, 1074), S), 'STIB stops never applied to De Lijn');
    Check(L.TransportName(0) = 'unknown (code 0)', 'No STIB mode names for De Lijn');
    Check(Pos('De Lijn', TMobibLookup.ContextNote(mocDeLijn)) > 0, 'De Lijn note');
    Check(Pos('not published', TMobibLookup.ContextNote(mocDeLijn)) > 0, 'Tariff codes stated as unpublished');
    Check(L.TariffName($000F, '') = 'De Lijn monthly subscription (confirmed on one card)',
      'Holder-confirmed De Lijn monthly tariff');
    Check(L.TariffName($0010, '') = 'unknown (tariff 0x0010)', 'Other De Lijn tariffs not invented');
    Check(L.LoadCsv('# caller table'#13#10'kind,a,b'#10'stop,0,2007,2101,"Example, stop",Centrum'#10 +
      'station,0,0,4,110,X,Example station'#10'tariff,0x000F,Example monthly pass'#10#10, 'mine') = 3,
      'Caller CSV rows loaded');
    Check(L.FindStop(StationEvent(0, 0, 4, 110), S) and (S.Name = 'Example station') and
      (S.Source = 'mine'), 'Caller station');
    E := BusEvent(2007, 2101);
    E.TransportCode := 0;
    Check(not L.FindStop(E, S), 'Legacy layout keys bus stops by the seven-bit route');
    E.LayoutKind := melBitmap;
    Check(L.FindStop(E, S) and (S.Name = 'Example, stop') and (S.Direction = 'Centrum'),
      'Bitmap layout keys bus stops by the full route');
    Check(L.TariffName($000F, '') = 'Example monthly pass', 'Caller tariff label');
    Check(CsvFails(L, 'bogus,1'), 'Unknown row kind');
    Check(CsvFails(L, 'stop,32,1,1,X'), 'Provider range');
    Check(CsvFails(L, 'stop,0,1,4096,X'), 'Twelve-bit code range');
    Check(CsvFails(L, 'station,0,64,0,0,1,X'), 'Zone range');
    Check(CsvFails(L, 'tariff,0x4000,X'), 'Tariff range');
    Check(CsvFails(L, 'stop,0,1,1,"open'), 'Unclosed quote');
    Check(CsvFails(L, 'stop,0,1,1,'), 'Empty name');
  finally
    L.Free;
  end;
  Check(TMobibLookup.Unescape('\u0041\u0062c \\u \u12') = 'Abc \u \u12', 'Escape decoding');
end;

begin
  try
    Tests;
    Writeln('MOBIB lookup: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
