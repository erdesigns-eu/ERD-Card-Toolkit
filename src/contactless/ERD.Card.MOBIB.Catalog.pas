unit ERD.Card.MOBIB.Catalog;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Subscriptions;

type
  /// <summary>Invalid or ambiguous catalog configuration, without input values in the message.</summary>
  EMobibCatalogError = class(Exception);
  /// <summary>Documented product mapping scoped to a network, tariff and contract versions.</summary>
  TMobibProductInfo = record
    /// <summary>Three-digit country code, 0..999.</summary>
    CountryCode: Word;
    /// <summary>Three-digit network code, 0..999.</summary>
    NetworkCode: Word;
    /// <summary>Exact fourteen-bit tariff.</summary>
    Tariff: Word;
    /// <summary>First supported contract version, 0..4.</summary>
    MinVersion: Byte;
    /// <summary>Last supported contract version, MinVersion..4.</summary>
    MaxVersion: Byte;
    /// <summary>Documented transport provider for this product; empty when unspecified or shared.</summary>
    ProviderName: UnicodeString;
    /// <summary>Human-readable ticket or subscription name, without inferred validity.</summary>
    ProductName: UnicodeString;
    /// <summary>Nonempty reference identifying the mapping source or application policy.</summary>
    Source: UnicodeString;
  end;
  /// <summary>Exact event-code mapping; names are historical labels rather than current routing guarantees.</summary>
  TMobibJourneyLabel = record
    /// <summary>Three-digit country code.</summary>
    CountryCode: Word;
    /// <summary>Three-digit network code.</summary>
    NetworkCode: Word;
    /// <summary>Exact five-bit transport mode.</summary>
    TransportCode: Byte;
    /// <summary>True for a bus route code; false for a location identifier.</summary>
    IsRoute: Boolean;
    /// <summary>Raw event location or route identifier.</summary>
    Code: Cardinal;
    /// <summary>Readable name supplied by the documented mapping.</summary>
    Name: UnicodeString;
    /// <summary>Nonempty mapping source/version reference.</summary>
    Source: UnicodeString;
  end;
  /// <summary>Offline product and journey dictionaries; never identifies an issuer from the network alone.</summary>
  TMobibCatalog = class
  private
    FProducts: array of TMobibProductInfo;
    FLabels: array of TMobibJourneyLabel;
  public
    /// <summary>Creates four known shared products and historical Brussels metro/premetro locations.</summary>
    constructor Create;
    /// <summary>Registers one sourced product; overlapping version ranges for the same key are refused.</summary>
    /// <param name="AProduct">Owned scalar/text fields; provider may be empty.</param>
    /// <exception cref="EMobibCatalogError">Invalid fields or an ambiguous product key.</exception>
    procedure RegisterProduct(const AProduct: TMobibProductInfo);
    /// <summary>Registers a sourced journey label; duplicate exact keys are refused.</summary>
    /// <param name="ALabel">Network, transport, location/route key and nonempty name/source.</param>
    /// <exception cref="EMobibCatalogError">Invalid fields or duplicate key.</exception>
    procedure RegisterJourneyLabel(const ALabel: TMobibJourneyLabel);
    /// <summary>Loads bounded pipe-separated P/L/R mappings atomically, retaining defaults.</summary>
    /// <param name="AText">P|country|network|min|max|tariff-hex|provider|product|source or L/R|country|network|mode|code-decimal|name|source; one per line.</param>
    /// <exception cref="EMobibCatalogError">Malformed, excessive or conflicting mappings; no entries are applied.</exception>
    procedure LoadMappings(const AText: UnicodeString);
    /// <summary>Resolves a product only for a semantically matched network and supported contract.</summary>
    /// <param name="AData">Decoded network evidence.</param>
    /// <param name="ASubscription">Decoded tariff and version.</param>
    /// <param name="AProduct">Independent output; cleared if not found.</param>
    /// <returns>True for an exact sourced mapping; no price-based product inference.</returns>
    function FindProduct(const AData: TMobibData; const ASubscription: TMobibSubscription;
      out AProduct: TMobibProductInfo): Boolean;
    /// <summary>Resolves a location or bus-route label using the exact event and network.</summary>
    /// <param name="AData">Matched network evidence.</param>
    /// <param name="AEvent">Decoded validation event.</param>
    /// <param name="ARoute">True selects bus route; false selects location.</param>
    /// <param name="ALabel">Independent output; cleared when absent.</param>
    /// <returns>True for an exact key; unknown codes remain unknown.</returns>
    function FindJourneyLabel(const AData: TMobibData; const AEvent: TMobibEvent;
      const ARoute: Boolean; out ALabel: TMobibJourneyLabel): Boolean;
  end;

implementation

procedure Fail;
begin raise EMobibCatalogError.Create('Invalid or conflicting MOBIB catalog mapping.'); end;

function ValidText(const S: UnicodeString): Boolean;
begin Result := (Trim(S) <> '') and (Length(S) <= 512); end;

constructor TMobibCatalog.Create;
var P: TMobibProductInfo; L: TMobibJourneyLabel;
  procedure Product(const Tariff: Word; const Name: UnicodeString);
  begin P.Tariff := Tariff; P.ProductName := Name; RegisterProduct(P); end;
  procedure Location(const Code: Cardinal; const Name: UnicodeString);
  begin
    L.Code := Code; L.Name := Name; L.TransportCode := 0; RegisterJourneyLabel(L);
    L.TransportCode := 7; RegisterJourneyLabel(L);
  end;
begin
  inherited Create;
  P := Default(TMobibProductInfo); P.CountryCode := 56; P.NetworkCode := 1; P.MaxVersion := 4;
  P.Source := 'Metrodroid MOBIB published tariff dictionary';
  Product($2801,'JUMP 1 trip'); Product($2803,'JUMP 10 trips');
  Product($0805,'Airport bus'); Product($303D,'JUMP 24h including airport bus');
  L := Default(TMobibJourneyLabel); L.CountryCode := 56; L.NetworkCode := 1;
  L.Source := 'MOBIB Extractor historical Brussels metro identifiers (via Cardpeek)';
  Location(14658,'De Brouckere');
  Location(14668,'Gare Centrale');
  Location(14677,'Park');
  Location(14687,'Art-Loi');
  Location(14697,'Maelbeek');
  Location(14707,'Schuman');
  Location(14716,'Merode');
  Location(14726,'Montgomery');
  Location(14736,'Josephine-Charlotte');
  Location(14746,'Gribaumont');
  Location(14755,'Tomberg');
  Location(14765,'Roodebeek');
  Location(14775,'Vandervelde');
  Location(14785,'Alma');
  Location(14795,'Crainhem');
  Location(14804,'Stockel');
  Location(14912,'Sainte Catherine');
  Location(14921,'Comte de Flandres');
  Location(14931,'Etangs Noirs');
  Location(17314,'Gare de l''Ouest');
  Location(17324,'Beekant');
  Location(24707,'Trone');
  Location(24716,'Porte de Namur');
  Location(24726,'Louise');
  Location(24736,'Hotel des Monnaies');
  Location(24746,'Porte de Hal');
  Location(24755,'Gare du Midi');
  Location(24765,'Clemenceau');
  Location(24775,'Delacroix');
  Location(24814,'Madou');
  Location(24824,'Botanique');
  Location(24834,'Rogier');
  Location(24843,'Yser');
  Location(24863,'Ribaucourt');
  Location(27099,'Osseghem');
  Location(27109,'Simonis');
  Location(53906,'Thieffry');
  Location(53916,'Petillon');
  Location(53925,'Hankar');
  Location(53935,'Delta');
  Location(53945,'Beaulieu');
  Location(53955,'Demey');
  Location(53964,'Hermann-Debroux');
  Location(56289,'Erasme');
  Location(56299,'Eddy Merckx');
  Location(56308,'CERIA');
  Location(56318,'La Roue');
  Location(56328,'Bizet');
  Location(56337,'Veeweyde');
  Location(56347,'Saint Guidon');
  Location(56357,'Aumale');
  Location(56367,'Jacques Brel');
  Location(64732,'Georges Henri');
  Location(64742,'Diamant');
  Location(64820,'Boileau');
  Location(66181,'Belgica');
  Location(66191,'Pannehuis');
  Location(66201,'Bockstael');
  Location(66211,'Stuyvenbergh');
  Location(66220,'Houba-Brugmann');
  Location(66230,'Heysel');
  Location(66240,'Roi Baudouin');
  Location(93746,'Gare du Nord');
  Location(93824,'Bourse');
  Location(93833,'Anneessens');
  Location(93843,'Lemonnier');
  Location(93873,'Parvis Saint Gilles');
  Location(93882,'Horta');
  Location(93892,'Albert');
end;

procedure TMobibCatalog.RegisterProduct(const AProduct: TMobibProductInfo);
var I, N: Integer;
begin
  if (AProduct.CountryCode > 999) or (AProduct.NetworkCode > 999) or
    (AProduct.Tariff > $3FFF) or (AProduct.MinVersion > AProduct.MaxVersion) or
    (AProduct.MaxVersion > 4) or not ValidText(AProduct.ProductName) or
    not ValidText(AProduct.Source) or (Length(AProduct.ProviderName) > 512) then Fail;
  for I := 0 to High(FProducts) do
    if (FProducts[I].CountryCode = AProduct.CountryCode) and
      (FProducts[I].NetworkCode = AProduct.NetworkCode) and (FProducts[I].Tariff = AProduct.Tariff) and
      (FProducts[I].MinVersion <= AProduct.MaxVersion) and (FProducts[I].MaxVersion >= AProduct.MinVersion) then Fail;
  N := Length(FProducts); if N >= 4096 then Fail;
  SetLength(FProducts,N+1); FProducts[N] := AProduct;
end;

procedure TMobibCatalog.RegisterJourneyLabel(const ALabel: TMobibJourneyLabel);
var I, N: Integer;
begin
  if (ALabel.CountryCode > 999) or (ALabel.NetworkCode > 999) or
    (ALabel.TransportCode > 31) or not ValidText(ALabel.Name) or not ValidText(ALabel.Source) then Fail;
  if ALabel.IsRoute then begin if (ALabel.TransportCode <> 15) or (ALabel.Code > 127) then Fail; end
  else if ((ALabel.TransportCode = 15) and (ALabel.Code > $FFF)) or
    (((ALabel.TransportCode = 0) or (ALabel.TransportCode = 7)) and (ALabel.Code > $1FFFF)) then Fail;
  for I := 0 to High(FLabels) do
    if (FLabels[I].CountryCode = ALabel.CountryCode) and (FLabels[I].NetworkCode = ALabel.NetworkCode) and
      (FLabels[I].TransportCode = ALabel.TransportCode) and (FLabels[I].IsRoute = ALabel.IsRoute) and
      (FLabels[I].Code = ALabel.Code) then Fail;
  N := Length(FLabels); if N >= 8192 then Fail;
  SetLength(FLabels,N+1); FLabels[N] := ALabel;
end;

procedure TMobibCatalog.LoadMappings(const AText: UnicodeString);
var Lines, Fields: TStringList; I, ProductCount, LabelCount, Tariff: Integer;
  P: TMobibProductInfo; L: TMobibJourneyLabel;
  function Number(const Index, Maximum: Integer): Integer;
  var J: Integer;
  begin
    if Fields[Index] = '' then Fail;
    for J := 1 to Length(Fields[Index]) do if not (Fields[Index][J] in ['0'..'9']) then Fail;
    if not TryStrToInt(Fields[Index],Result) then Fail;
    if (Result < 0) or (Result > Maximum) then Fail;
  end;
begin
  if Length(AText) > 262144 then Fail;
  ProductCount := Length(FProducts); LabelCount := Length(FLabels);
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.Text := string(AText); Fields.StrictDelimiter := True; Fields.Delimiter := '|'; Fields.QuoteChar := #0;
    try
      for I := 0 to Lines.Count-1 do begin
        if Trim(Lines[I]) = '' then Continue;
        Fields.DelimitedText := Lines[I]; if Fields.Count = 0 then Fail;
        if Fields[0] = 'P' then begin
          if Fields.Count <> 9 then Fail;
          P := Default(TMobibProductInfo); P.CountryCode := Number(1,999); P.NetworkCode := Number(2,999);
          P.MinVersion := Number(3,4); P.MaxVersion := Number(4,4);
          if (Length(Fields[5]) <> 4) or not TryStrToInt('$'+Fields[5],Tariff) then Fail;
          if (Tariff < 0) or (Tariff > $3FFF) then Fail;
          P.Tariff := Tariff;
          P.ProviderName := UnicodeString(Fields[6]); P.ProductName := UnicodeString(Fields[7]); P.Source := UnicodeString(Fields[8]);
          RegisterProduct(P);
        end else if (Fields[0] = 'L') or (Fields[0] = 'R') then begin
          if Fields.Count <> 7 then Fail;
          L := Default(TMobibJourneyLabel); L.CountryCode := Number(1,999); L.NetworkCode := Number(2,999);
          L.TransportCode := Number(3,31); L.Code := Number(4,$1FFFF); L.IsRoute := Fields[0] = 'R';
          L.Name := UnicodeString(Fields[5]); L.Source := UnicodeString(Fields[6]); RegisterJourneyLabel(L);
        end else Fail;
      end;
    except SetLength(FProducts,ProductCount); SetLength(FLabels,LabelCount); raise; end;
  finally Fields.Free; Lines.Free; end;
end;

function TMobibCatalog.FindProduct(const AData: TMobibData; const ASubscription: TMobibSubscription;
  out AProduct: TMobibProductInfo): Boolean;
var I: Integer;
begin
  Result := False; AProduct := Default(TMobibProductInfo);
  if not AData.HasNetwork or not AData.LayoutMatched or not ASubscription.LayoutMatched then Exit;
  for I := 0 to High(FProducts) do
    if (FProducts[I].CountryCode = AData.CountryCode) and (FProducts[I].NetworkCode = AData.NetworkCode) and
      (FProducts[I].Tariff = ASubscription.Tariff) and (ASubscription.Version >= FProducts[I].MinVersion) and
      (ASubscription.Version <= FProducts[I].MaxVersion) then begin AProduct := FProducts[I]; Exit(True); end;
end;

function TMobibCatalog.FindJourneyLabel(const AData: TMobibData; const AEvent: TMobibEvent;
  const ARoute: Boolean; out ALabel: TMobibJourneyLabel): Boolean;
var I: Integer; Code: Cardinal;
begin
  Result := False; ALabel := Default(TMobibJourneyLabel);
  if not AData.HasNetwork or not AData.LayoutMatched then Exit;
  if ARoute then begin if AEvent.TransportCode <> 15 then Exit; Code := AEvent.BusRoute; end
  else begin if not AEvent.HasLocation then Exit; Code := AEvent.LocationId; end;
  for I := 0 to High(FLabels) do
    if (FLabels[I].CountryCode = AData.CountryCode) and (FLabels[I].NetworkCode = AData.NetworkCode) and
      (FLabels[I].TransportCode = AEvent.TransportCode) and (FLabels[I].IsRoute = ARoute) and
      (FLabels[I].Code = Code) then begin ALabel := FLabels[I]; Exit(True); end;
end;

end.
