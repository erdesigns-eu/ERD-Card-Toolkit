program LegacyCatalogsTests;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{$IFNDEF FPC}
{$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.ATR, ERD.Card.ATR.Catalog, ERD.Card.ATR.Legacy,
  ERD.Card.APDU.Catalog, ERD.Card.EMV.LegacyTags, ERD.Card.EMV.Tags, ERD.Card.EMV.Aids;

var
  Assertions: Integer;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Assertions);
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure AtrTests;
var
  Reports: TLegacyAtrReports;
  Catalog: TAtrCatalog;
  Matches: TAtrCatalogMatches;
  I, J, Eligible: Integer;
  Found: Boolean;
begin
  Reports := TLegacyAtrCatalog.GetReports;
  Check(Length(Reports) = 1316, 'Every valid original ATR report retained');
  Eligible := 0;
  Catalog := CreateDefaultAtrCatalog;
  try
    for I := 0 to High(Reports) do
      begin
        Inc(Eligible);
        Matches := Catalog.FindMatches(HexToBytes(Reports[I].AtrHex));
        Found := False;
        for J := 0 to High(Matches) do
          if Matches[J].Id = 'cardstudio-legacy-' + IntToStr(Reports[I].SourceRow) then
            Found := True;
        Check(Found, 'Valid historical report reachable');
      end;
    Matches := Catalog.FindMatches(HexToBytes('3B670000B84040729B9000'));
    Check(Length(Matches) >= 2, 'Shared issuer fingerprints preserved');
    Check((Matches[0].Issuer <> Matches[1].Issuer) and
      (Matches[0].Kind = ahkHistoricalReport), 'Historical metadata and advisory scope preserved');
    Matches := Catalog.FindMatches(HexToBytes(Reports[0].AtrHex));
    Check((Length(Matches) > 0) and (Matches[0].Country = 'BELGIUM'), 'Belgian eID historical entry restored');
    Writeln('PASS: ', Eligible, ' valid ATR reports restored; malformed reports removed.');
  finally
    Catalog.Free;
  end;
end;

procedure DictionaryTests;
var
  Tags: TLegacyEmvTags;
  Descriptions: TEmvTagDescriptions;
  Statuses: TApduStatusDescriptions;
  Instructions: TApduInstructionDescriptions;
  Aids: TEmvAidDescriptions;
  I, Excluded: Integer;
begin
  Tags := TLegacyEmvTagCatalog.GetEntries;
  Check(Length(Tags) = 515, 'All original EMV labels');
  for I := 0 to High(Tags) do
  begin
    if Tags[I].Tag = 0 then
      Continue;
    Descriptions := TEmvTagCatalog.FindDescriptions(Tags[I].Tag);
    Check(Length(Descriptions) > 0, 'Every historical tag reachable');
  end;
  Check(Length(TLegacyEmvTagCatalog.FindByPath('7A9F21')) > 0, 'Symbolic historical nested path restored');
  Descriptions := TEmvTagCatalog.FindDescriptions($9F26);
  Check((Length(Descriptions) >= 2) and (Descriptions[0].Encoding = eteBinary) and
    (Descriptions[1].Encoding = eteUnknown), 'Verified metadata precedes context-dependent historical labels');
  Check(Length(TEmvTagCatalog.FindDescriptions(0)) = 0, 'Symbolic paths are not tag zero');
  Descriptions := TEmvTagCatalog.FindDescriptions($FFFF);
  Check(Length(Descriptions) = 0, 'Unknown tags remain unknown');
  Instructions := TApduCatalog.GetInstructions;
  Check(Length(Instructions) = 35, 'All instruction labels');
  Instructions := TApduCatalog.FindInstructions($A4);
  Check((Length(Instructions) > 0) and (Pos('Select', Instructions[0].Description) > 0), 'SELECT instruction explanation');
  Statuses := TApduCatalog.GetHistoricalStatuses;
  Check(Length(Statuses) = 205, 'All valid historical status rows');
  Excluded := 0;
  for I := 0 to High(Statuses) do
    if Statuses[I].Mask = 0 then
      Inc(Excluded);
  Check(Excluded = 0, 'No malformed status placeholders retained');
  Statuses := TApduCatalog.FindStatusDescriptions($6100);
  Check((Length(Statuses) > 0) and (Pos('256', Statuses[0].Description) > 0), '61xx dynamic response count');
  Statuses := TApduCatalog.FindStatusDescriptions($6C0A);
  Check((Length(Statuses) > 0) and (Pos('10', Statuses[0].Description) > 0), '6Cxx dynamic expected Le');
  Statuses := TApduCatalog.FindStatusDescriptions($63C2);
  Check((Length(Statuses) > 0) and (Pos('2', Statuses[0].Description) > 0), '63Cx retry count');
  Aids := TEmvAidCatalog.GetEntries;
  Check(Length(Aids) = 61, 'All valid AID suggestions restored');
  for I := 0 to High(Aids) do
  begin
    Check(Length(HexToBytes(Aids[I].AidHex)) in [5 .. 16], 'AID bounds');
    Check(Aids[I].PrefixOnly = (Length(Aids[I].AidHex) = 10), 'RID prefixes explicitly distinguished');
  end;
  Writeln('PASS: Historical EMV labels, APDU instruction/status dictionaries and AID suggestions.');
end;

begin
  try
    AtrTests;
    DictionaryTests;
    Writeln('PASS: ', Assertions, ' legacy catalog assertions.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
