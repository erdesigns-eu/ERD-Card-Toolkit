program MobibAnalysisTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data,
  ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Catalog, ERD.Card.MOBIB.Archive,
  ERD.Card.MOBIB.Presentation;
var Checks: Integer;
procedure Check(const Value: Boolean; const Message: string);
begin Inc(Checks); if not Value then raise Exception.Create(Message); end;
procedure RejectArchive(const Text: UnicodeString);
var Failed: Boolean;
begin
  Failed := False;
  try TMobibArchive.Decode(Text); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Malformed archive accepted');
end;
procedure TestArchive;
var S, D: TMobibSnapshot; Text: UnicodeString; I, J: Integer; Failed: Boolean;
begin
  S := Default(TMobibSnapshot); S.TicketingSelection := HexToBytes('6F020102'); SetLength(S.Files,3);
  for I := 0 to 2 do begin
    S.Files[I].LogicalId := $2001+I; S.Files[I].SelectionStatus := $9000;
    S.Files[I].LastRecordStatus := $6A83; S.Files[I].Truncated := I=2;
    S.Files[I].SelectionData := HexToBytes('85020102');
  end;
  S.Files[1].SelectionStatus := $6982; S.Files[1].LastRecordStatus := 0;
  SetLength(S.Files[0].Records,3);
  for I := 0 to 2 do begin S.Files[0].Records[I].Number := I+2; S.Files[0].Records[I].Data := HexToBytes('000001'); end;
  Text := TMobibArchive.Encode(S); D := TMobibArchive.Decode(Text);
  Check(Text = TMobibArchive.Encode(D),'Non-lossless archive round trip');
  Check(BytesEqual(D.TicketingSelection,S.TicketingSelection),'Ticketing bytes lost');
  for I := 0 to 2 do begin
    Check(D.Files[I].LogicalId = S.Files[I].LogicalId,'File identifier changed');
    Check(D.Files[I].SelectionStatus = S.Files[I].SelectionStatus,'SELECT status changed');
    Check(D.Files[I].LastRecordStatus = S.Files[I].LastRecordStatus,'READ status changed');
    Check(D.Files[I].Truncated = S.Files[I].Truncated,'Truncation evidence lost');
    Check(BytesEqual(D.Files[I].SelectionData,S.Files[I].SelectionData),'SELECT data changed');
    for J := 0 to High(S.Files[I].Records) do begin
      Check(D.Files[I].Records[J].Number = S.Files[I].Records[J].Number,'Record number changed');
      Check(BytesEqual(D.Files[I].Records[J].Data,S.Files[I].Records[J].Data),'Record bytes changed');
    end;
  end;
  D.Files[0].Records[0].Data[0] := 255; Check(S.Files[0].Records[0].Data[0] = 0,'Archive output aliases input');
  RejectArchive(''); RejectArchive('MOBIB-RECORDS 2'+sLineBreak+'T -');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'R 2001 1 AA');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T 0');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T GG');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 0000 9000 0000 0 -');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 2001 9000 0000 2 -');
  RejectArchive(Text+sLineBreak+'F 2001 9000 0000 0 -');
  Text := 'MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 2001 9000 6A83 0 -'+sLineBreak;
  RejectArchive(Text+'R 2002 1 AA'); RejectArchive(Text+'R 2001 0 AA'); RejectArchive(Text+'R 2001 256 AA');
  RejectArchive(Text+'R 2001 $1 AA'); RejectArchive(Text+'R 2001 1 '+UnicodeString(StringOfChar('A',514)));
  RejectArchive(Text+'R 2001 1 AA'+sLineBreak+'R 2001 1 BB');
  D := TMobibArchive.Decode(Text+'R 2001 1 -'); Check(Length(D.Files[0].Records[0].Data) = 0,'Empty bytes not retained');
  SetLength(S.Files[0].Records[0].Data,257); Failed := False;
  try Text := TMobibArchive.Encode(S); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Oversized record exported');
end;
procedure TestCatalog;
var C: TMobibCatalog; D: TMobibData; S: TMobibSubscription; P: TMobibProductInfo;
  E: TMobibEvent; L: TMobibJourneyLabel; Failed: Boolean; I: Integer;
begin
  C := TMobibCatalog.Create;
  try
    D := Default(TMobibData); D.CountryCode := 56; D.NetworkCode := 1; D.HasNetwork := True; D.LayoutMatched := True;
    S := Default(TMobibSubscription); S.LayoutMatched := True; S.Version := 4; S.Tariff := $2803;
    Check(C.FindProduct(D,S,P) and (P.ProductName = 'JUMP 10 trips'),'Known product missing');
    Check((P.ProviderName = '') and (P.Source <> ''),'Shared tariff invented an issuer');
    S.Tariff := $000F; Check(not C.FindProduct(D,S,P),'Unknown tariff guessed');
    C.LoadMappings('P|56|1|0|4|000F|Example provider|Example subscription|Synthetic fixture v1');
    Check(C.FindProduct(D,S,P) and (P.ProviderName = 'Example provider'),'Application provider not resolved');
    Check(P.ProductName = 'Example subscription','Application product not resolved');
    D.NetworkCode := 2; Check(not C.FindProduct(D,S,P),'Cross-network mapping leaked'); D.NetworkCode := 1;
    D.LayoutMatched := False; Check(not C.FindProduct(D,S,P),'Unmatched layout interpreted'); D.LayoutMatched := True;
    E := Default(TMobibEvent); E.HasLocation := True; E.LocationId := 14668;
    for I := 0 to 1 do begin
      if I=0 then E.TransportCode := 0 else E.TransportCode := 7;
      Check(C.FindJourneyLabel(D,E,False,L) and (L.Name = 'Gare Centrale'),'Historical metro stop missing');
      Check(L.Source <> '','Journey label has no source');
    end;
    E.TransportCode := 15; E.LocationId := 123; E.BusRoute := 7;
    Check(not C.FindJourneyLabel(D,E,False,L),'Unknown bus stop guessed');
    C.LoadMappings('L|56|1|15|123|Example stop|Synthetic fixture'+sLineBreak+'R|56|1|15|7|Example route|Synthetic fixture');
    Check(C.FindJourneyLabel(D,E,False,L) and (L.Name='Example stop'),'Custom stop missing');
    Check(C.FindJourneyLabel(D,E,True,L) and (L.Name='Example route'),'Custom route missing');
    E.BusRoute := 8; Check(not C.FindJourneyLabel(D,E,True,L),'Route code ignored');
    Failed := False;
    try C.LoadMappings('P|56|1|0|4|000E|Example|Rollback product|Synthetic'+sLineBreak+'invalid');
    except on EMobibCatalogError do Failed := True; end;
    Check(Failed,'Malformed mappings accepted'); S.Tariff := $000E;
    Check(not C.FindProduct(D,S,P),'Failed import left a partial product');
    Failed := False;
    try C.LoadMappings('P|56|1|4|4|000F|Other|Conflicting|Synthetic'); except on EMobibCatalogError do Failed := True; end;
    Check(Failed,'Ambiguous provider mappings accepted'); S.Tariff := $000F;
    Check(C.FindProduct(D,S,P) and (P.ProviderName='Example provider'),'Conflict modified prior mapping');
    Failed := False;
    try C.LoadMappings('L|56|1|15|4096|Bad|Synthetic'); except on EMobibCatalogError do Failed := True; end;
    Check(Failed,'Out-of-range bus stop accepted');
  finally C.Free; end;
end;
procedure TestPresentation;
var C: TMobibCatalog; S: TMobibSnapshot; D: TMobibData; Text: UnicodeString;
begin
  S := Default(TMobibSnapshot); SetLength(S.Files,2);
  S.Files[0].LogicalId := $2001; S.Files[0].SelectionStatus := $9000; SetLength(S.Files[0].Records,1);
  S.Files[0].Records[0].Number := 1;
  S.Files[0].Records[0].Data := HexToBytes('00082B0008000000000000000000000000000000000000000000000000');
  S.Files[1].LogicalId := $2020; S.Files[1].SelectionStatus := $9000; SetLength(S.Files[1].Records,1);
  S.Files[1].Records[0].Number := 1; S.Files[1].Records[0].Data := HexToBytes('100000001E000000000000000000000000000000000000000000000000');
  D := TMobibCodec.Decode(S,mlLegacy056001); Check(D.LayoutMatched,'Synthetic network not matched');
  SetLength(D.Events,1); D.Events[0].Date := EncodeDate(2026,1,2); D.Events[0].Minutes := 607;
  D.Events[0].FirstDate := EncodeDate(2026,1,2); D.Events[0].FirstMinutes := 600;
  D.Events[0].RecordNumber := 2; D.Events[0].HasLocation := True; D.Events[0].LocationId := 14668;
  C := TMobibCatalog.Create;
  try
    Text := TMobibPresentation.Summary(D,C);
    Check(Pos('2026-01-02 10:07',string(Text)) > 0,'Civil event time not readable');
    Check(Pos('Stop: Gare Centrale',string(Text)) > 0,'Event location label missing');
    Check(Pos('Product: unidentified (tariff 0x000F)',string(Text)) > 0,'Unknown contract identification lost');
    C.LoadMappings('P|56|1|0|4|000F|Example provider|Example pass|Synthetic test');
    Text := TMobibPresentation.Summary(D,C);
    Check(Pos('Product provider: Example provider',string(Text)) > 0,'Provider mapping not displayed');
    Check(Pos('Product: Example pass',string(Text)) > 0,'Subscription label missing');
    Check(Pos('Layout version: 4; tariff: 0x000F',string(Text)) > 0,'Contract metadata hidden');
    Check(Pos('Product mapping source: Synthetic test',string(Text)) > 0,'Provider provenance hidden');
    Check(Pos('Card issuer: not determined',string(Text)) > 0,'Product provider confused with issuer');
  finally C.Free; end;
end;
begin
  try TestArchive; TestCatalog; TestPresentation; Writeln('PASS: ',Checks,' MOBIB catalog/archive/presentation assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
