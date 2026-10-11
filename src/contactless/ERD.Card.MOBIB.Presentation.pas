unit ERD.Card.MOBIB.Presentation;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Catalog;

type
  /// <summary>Offline human-readable MOBIB summaries for application UIs, without card or file I/O.</summary>
  TMobibPresentation = class
  public
    /// <summary>Formats holder, contracts and validation history with exact sourced catalog names.</summary>
    /// <param name="Data">Decoded snapshot; unmatched and missing fields remain explicitly unknown.</param>
    /// <param name="ACatalog">Borrowed catalog; nil creates and releases the built-in dictionary.</param>
    /// <returns>Text with euro amounts, civil dates/times, raw identifiers and mapping provenance; no entitlement inference.</returns>
    class function Summary(const Data: TMobibData; const ACatalog: TMobibCatalog = nil): UnicodeString; static;
  end;

implementation

function MobibTransportName(const Code: Byte): string;
begin
  case Code of
    0: Result := 'Metro';
    7: Result := 'Premetro';
    15: Result := 'Bus';
    22: Result := 'Tram';
  else Result := 'Unknown mode (code ' + IntToStr(Code) + ')'; end;
end;

function MobibTime(const Date: TDateTime; const Minutes: Word): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', Date) + Format(' %2.2d:%2.2d', [Minutes div 60, Minutes mod 60]);
end;

class function TMobibPresentation.Summary(const Data: TMobibData; const ACatalog: TMobibCatalog): UnicodeString;
var Lines: TStringList; I: Integer; S: TMobibSubscription; Counters: string;
  Subscriptions: TMobibSubscriptions; Catalog: TMobibCatalog; Product: TMobibProductInfo; LabelInfo: TMobibJourneyLabel;
begin
  Subscriptions := TMobibSubscriptionCodec.DecodeSnapshot(Data);
  Catalog := ACatalog; if Catalog = nil then Catalog := TMobibCatalog.Create;
  Lines := nil;
  try
    Lines := TStringList.Create;
    Lines.Add('MOBIB CARD');
    if Data.LayoutMatched then Lines.Add('Data profile: MOBIB 056/001 (matched)')
    else Lines.Add('Data profile: no matching semantic layout');
    if Data.HasNetwork then
    begin
      if Data.CountryCode = 56 then Lines.Add('Country: Belgium (056)')
      else Lines.Add(Format('Country code: %3.3d', [Data.CountryCode]));
      Lines.Add(Format('Network: %3.3d', [Data.NetworkCode]));
    end;
    Lines.Add('Card issuer: not determined from the network identifier');
    Lines.Add(''); Lines.Add('HOLDER');
    if Data.Holder.Present then
    begin
      Lines.Add('Name: ' + string(Data.Holder.Name));
      Lines.Add('Cardholder number: ' + string(Data.Holder.Number));
      if Data.Holder.HasBirthDate then Lines.Add('Birth date: ' + FormatDateTime('yyyy-mm-dd', Data.Holder.BirthDate));
      Lines.Add('Gender field: code ' + IntToStr(Data.Holder.GenderCode));
    end
    else Lines.Add('Holder details: not available in the decoded records');
    Lines.Add(''); Lines.Add(Format('CONTRACTS (%d decoded)', [Length(Subscriptions)]));
    if Data.HasContractCount then Lines.Add('Contract list count: ' + IntToStr(Data.ContractCount));
    for I := 0 to High(Subscriptions) do
    begin
      S := Subscriptions[I]; Lines.Add(''); Lines.Add('Contract ' + IntToStr(S.RecordNumber));
      if not S.LayoutMatched then
      begin
        Lines.Add('Unsupported record layout: version ' + IntToStr(S.Version)); Continue;
      end;
      Lines.Add(Format('  Layout version: %d; tariff: 0x%s; decoded bits: %d', [S.Version,IntToHex(S.Tariff,4),S.DecodedBits]));
      if Catalog.FindProduct(Data,S,Product) then begin
        Lines.Add('  Product: ' + string(Product.ProductName));
        if Product.ProviderName <> '' then Lines.Add('  Product provider: ' + string(Product.ProviderName))
        else Lines.Add('  Product provider: unspecified / shared product');
        Lines.Add('  Product mapping source: ' + string(Product.Source));
      end else begin
        Lines.Add('  Product: unidentified (tariff 0x' + IntToHex(S.Tariff, 4) + ')');
        Lines.Add('  Product provider: unidentified');
      end;
      Lines.Add(Format('  Purchase price: EUR %d.%2.2d', [S.PriceCents div 100, S.PriceCents mod 100]));
      if S.HasSaleDate then Lines.Add('  Purchase date: ' + FormatDateTime('yyyy-mm-dd', S.SaleDate))
      else Lines.Add('  Purchase date: not recorded');
      if S.HasDuration then Lines.Add(Format('  Recorded duration: %d (unit code %d; unit not mapped)', [S.DurationValue, S.DurationUnitCode]));
      if S.HasCounter then
      begin
        Lines.Add(Format('  Associated counter: %d (counter-use code %d)', [S.Counter, S.CounterUse]));
        if S.HasRemainingTrips and (S.ProductName <> '') then Lines.Add('  Remaining trips: ' + IntToStr(S.RemainingTrips));
      end
      else Lines.Add('  Associated counter: not acquired');
    end;
    if Length(Subscriptions) > 0 then Lines.Add('Validity / activation / zones: not available from these decoded contract fields');
    Lines.Add(''); Lines.Add(Format('VALIDATIONS (%d decoded)', [Length(Data.Events)]));
    if Length(Data.Events) = 0 then Lines.Add('No nonempty validation events decoded');
    for I := 0 to High(Data.Events) do
    begin
      Lines.Add(Format('Event %d: %s - %s', [Data.Events[I].RecordNumber,
        MobibTime(Data.Events[I].Date, Data.Events[I].Minutes), MobibTransportName(Data.Events[I].TransportCode)]));
      Lines.Add('  First validation: ' + MobibTime(Data.Events[I].FirstDate, Data.Events[I].FirstMinutes));
      if Data.Events[I].HasLocation then begin
        Lines.Add('  Location identifier: ' + IntToStr(Data.Events[I].LocationId));
        if Catalog.FindJourneyLabel(Data,Data.Events[I],False,LabelInfo) then begin
          Lines.Add('  Stop: ' + string(LabelInfo.Name));
          Lines.Add('  Location mapping source: ' + string(LabelInfo.Source));
        end else Lines.Add('  Stop: unidentified');
      end;
      if Data.Events[I].TransportCode = 15 then begin
        Lines.Add('  Bus route: ' + IntToStr(Data.Events[I].BusRoute));
        if Catalog.FindJourneyLabel(Data,Data.Events[I],True,LabelInfo) then begin
          Lines.Add('  Route: ' + string(LabelInfo.Name));
          Lines.Add('  Route mapping source: ' + string(LabelInfo.Source));
        end;
      end;
      Lines.Add('  Recorded coupon/count value: ' + IntToStr(Data.Events[I].CouponCount));
    end;
    Lines.Add(''); Lines.Add(Format('COUNTERS (%d slots)', [Length(Data.Counters)]));
    Counters := '';
    for I := 0 to High(Data.Counters) do
    begin
      if I > 0 then Counters := Counters + '; ';
      Counters := Counters + Format('record %d slot %d = %d',
        [Data.Counters[I].RecordNumber, Data.Counters[I].Slot, Data.Counters[I].Value]);
    end;
    if Counters = '' then Counters := 'No counters acquired';
    Lines.Add(Counters);
    Result := UnicodeString(Lines.Text);
  finally Lines.Free; if ACatalog = nil then Catalog.Free; end;
end;

end.
