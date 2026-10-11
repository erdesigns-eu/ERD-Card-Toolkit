unit ERD.Card.Calypso.Networks;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.EN1545, ERD.Card.Contactless.Calypso;

type
  /// <summary>Calypso network profiles known to the registry.</summary>
  TCalypsoNetworkKind = (
    /// <summary>No profile; generic EN1545 header plus raw records.</summary>
    cnkUnknown,
    /// <summary>MOBIB, Belgium 056/001; decode fully with TMobibCodec.</summary>
    cnkMobib,
    /// <summary>Intercode, France (country 250), including Navigo 250/901.</summary>
    cnkIntercode,
    /// <summary>Lisboa Viva, Portugal.</summary>
    cnkLisboaViva,
    /// <summary>Rav-Kav, Israel (376).</summary>
    cnkRavKav,
    /// <summary>OPUS, Quebec, Canada (124/001).</summary>
    cnkOpus,
    /// <summary>Venezia Unica, Italy.</summary>
    cnkVenezia,
    /// <summary>Pisa, Italy (380/100).</summary>
    cnkPisa);

  /// <summary>How a contract record chooses its layout variant.</summary>
  TCalypsoContractSelector = (
    /// <summary>One contract layout for every record.</summary>
    ccsNone,
    /// <summary>Intercode: bits 4..11 of the contract-list tariff that points at the record.</summary>
    ccsIntercodeListTariff);

  /// <summary>Contract layout used when the selector yields Code.</summary>
  TCalypsoContractVariant = record
    /// <summary>Selector value.</summary>
    Code: Integer;
    /// <summary>EN1545 layout definition.</summary>
    Definition: string;
  end;

  /// <summary>Contract layout variants.</summary>
  TCalypsoContractVariants = array of TCalypsoContractVariant;

  /// <summary>Data-only description of one network's public record layouts.</summary>
  TCalypsoNetworkProfile = record
    /// <summary>Profile identifier.</summary>
    Kind: TCalypsoNetworkKind;
    /// <summary>Display name.</summary>
    Name: string;
    /// <summary>Public source of the layouts.</summary>
    Source: string;
    /// <summary>True only when the layouts were checked against a physical card in this project.</summary>
    CheckedOnCard: Boolean;
    /// <summary>Caveats for the caller.</summary>
    Note: string;
    /// <summary>Layout of all environment (2001) records concatenated.</summary>
    Environment: string;
    /// <summary>Layout of contract list (2050) record 1; empty when the network has none.</summary>
    ContractList: string;
    /// <summary>Default contract layout; empty keeps contracts raw.</summary>
    Contract: string;
    /// <summary>Variant selection rule.</summary>
    ContractSelector: TCalypsoContractSelector;
    /// <summary>Contract variants checked before the default layout.</summary>
    ContractVariants: TCalypsoContractVariants;
    /// <summary>True when 2030 records follow 2020 records in the contract numbering.</summary>
    SecondContractFile: Boolean;
    /// <summary>Layout of event (2010) records; empty keeps them raw.</summary>
    Event: string;
    /// <summary>Layout of special-event (2040) records; empty keeps them raw.</summary>
    SpecialEvent: string;
  end;

  /// <summary>Registry recommendation; never applied automatically.</summary>
  TCalypsoNetworkMatch = record
    /// <summary>Recommended profile, cnkUnknown when none matched.</summary>
    Kind: TCalypsoNetworkKind;
    /// <summary>True when a profile discriminator matched.</summary>
    Matched: Boolean;
    /// <summary>Discriminator bits as hexadecimal, for example 250901.</summary>
    NetworkCode: string;
    /// <summary>Known network or card name, empty when unknown.</summary>
    NetworkName: string;
    /// <summary>Which bits matched which value.</summary>
    Reason: string;
  end;

  /// <summary>Role of a record in the network view.</summary>
  TCalypsoRecordRole = (
    /// <summary>All environment records concatenated (RecordNumber 0).</summary>
    crrEnvironment,
    /// <summary>Contract list record.</summary>
    crrContractList,
    /// <summary>Contract record.</summary>
    crrContract,
    /// <summary>Event (validation log) record.</summary>
    crrEvent,
    /// <summary>Special-event record.</summary>
    crrSpecialEvent,
    /// <summary>Counter record, raw.</summary>
    crrCounter,
    /// <summary>Any other record, raw.</summary>
    crrOther);

  /// <summary>One record with its decoded fields or raw bytes.</summary>
  TCalypsoRecordView = record
    /// <summary>Folder, 2000 for ticketing.</summary>
    Folder: Word;
    /// <summary>Logical file identifier.</summary>
    FileId: Word;
    /// <summary>Record number; 0 for the concatenated environment.</summary>
    RecordNumber: Byte;
    /// <summary>Contract number in the combined 2020/2030 numbering, 0 otherwise.</summary>
    ContractNumber: Integer;
    /// <summary>Record role.</summary>
    Role: TCalypsoRecordRole;
    /// <summary>True when Parsed holds a layout result.</summary>
    Decoded: Boolean;
    /// <summary>Layout result.</summary>
    Parsed: TEn1545Parsed;
    /// <summary>Independent copy of the record bytes.</summary>
    Data: TBytes;
    /// <summary>True when a counter value was found for this contract.</summary>
    HasCounter: Boolean;
    /// <summary>Raw 24-bit counter value.</summary>
    Counter: Cardinal;
    /// <summary>File the counter came from (2069 or 202A..202D).</summary>
    CounterFileId: Word;
    /// <summary>Why a record was kept raw, or other remarks.</summary>
    Note: string;
  end;

  /// <summary>Record views.</summary>
  TCalypsoRecordViews = array of TCalypsoRecordView;

  /// <summary>Profile-driven view of a snapshot.</summary>
  TCalypsoNetworkView = record
    /// <summary>Profile applied by the caller.</summary>
    Kind: TCalypsoNetworkKind;
    /// <summary>Profile name.</summary>
    ProfileName: string;
    /// <summary>Profile source.</summary>
    Source: string;
    /// <summary>Copied from the profile.</summary>
    CheckedOnCard: Boolean;
    /// <summary>Profile caveats.</summary>
    Note: string;
    /// <summary>Environment first, then other files in snapshot order, then contracts in 2020/2030 order.</summary>
    Records: TCalypsoRecordViews;
  end;

  /// <summary>Offline registry of public Calypso network layouts.</summary>
  /// <remarks>Recommend only inspects discriminator bits; the caller decides which profile to apply.</remarks>
  TCalypsoNetworks = class
  public
    /// <summary>Returns a profile description.</summary>
    /// <param name="AKind">Profile.</param>
    /// <returns>Profile data.</returns>
    class function Profile(const AKind: TCalypsoNetworkKind)
      : TCalypsoNetworkProfile; static;
    /// <summary>Returns the display name of a profile.</summary>
    /// <param name="AKind">Profile.</param>
    /// <returns>Display name.</returns>
    class function KindName(const AKind: TCalypsoNetworkKind): string; static;
    /// <summary>Recommends a profile from environment record 1.</summary>
    /// <param name="AEnvironment">Environment record bytes.</param>
    /// <returns>Recommendation.</returns>
    class function Recommend(const AEnvironment: TBytes)
      : TCalypsoNetworkMatch; static;
    /// <summary>Recommends a profile from ticketing environment 2001 record 1 of a snapshot.</summary>
    /// <param name="ASnapshot">Snapshot.</param>
    /// <returns>Recommendation.</returns>
    class function RecommendSnapshot(const ASnapshot: TMobibSnapshot)
      : TCalypsoNetworkMatch; static;
    /// <summary>Applies a profile to a snapshot; unparsed files stay raw.</summary>
    /// <param name="ASnapshot">Snapshot.</param>
    /// <param name="AKind">Profile chosen by the caller.</param>
    /// <returns>Record views.</returns>
    class function Decode(const ASnapshot: TMobibSnapshot;
      const AKind: TCalypsoNetworkKind): TCalypsoNetworkView; static;
    /// <summary>Returns the label of a record role.</summary>
    /// <param name="ARole">Role.</param>
    /// <returns>Label.</returns>
    class function RoleName(const ARole: TCalypsoRecordRole): string; static;
  end;

implementation

const
  MetrodroidSource = 'Metrodroid en1545 transit layouts (GPL-3.0; field facts only)';
  NotChecked = 'Not checked against a physical card in this project.';

  GenericEnvironment = '?EnvVersionNumber:int:6, ?EnvUnknownA:int:7, ?EnvNetworkId:hex:24';

  MobibEnvironment = 'EnvVersionNumber:int:6, ?EnvUnknownA:int:7, EnvNetworkId:bcd:24';

  IntercodeEnvFields = 'EnvVersionNumber:int:6, bitmap(EnvNetworkId:hex:24, ' +
    'EnvApplicationIssuerId:int:8, EnvApplicationValidityEndDate:date, EnvPayMethod:int:11, ' +
    'EnvAuthenticator:int:16, EnvSelectList:int:32, seq(EnvCardStatus:int:1, EnvExtra:hex:0))';

  IntercodeEnvironment = IntercodeEnvFields + ', bitmap(' +
    'bitmap(HolderSurname:str:85, HolderForename:str:85), ' +
    'bitmap(HolderBirthDate:bcddate, HolderBirthPlace:str:115), HolderBirthName:str:85, ' +
    'HolderIdNumber:int:32, HolderCountryAlpha:int:24, HolderCompany:int:32, ' +
    'repeat:2(bitmap(HolderProfileNetworkId:hex:24, HolderProfileNumber:int:8, ' +
    'HolderProfileDate:date)), ' +
    'bitmap(HolderCardType:int:4, HolderDataTeleReglement:int:4, HolderDataResidence:int:17, ' +
    'HolderDataCommercialId:int:6, HolderDataWorkPlace:int:17, HolderDataStudyPlace:int:17, ' +
    'HolderDataSaleDevice:int:16, HolderDataAuthenticator:int:16, ' +
    'HolderDataProfileStart1:date, HolderDataProfileStart2:date, ' +
    'HolderDataProfileStart3:date, HolderDataProfileStart4:date))';

  IntercodeContractList = 'repeat:4(bitmap(ContractsNetworkId:hex:24, ' +
    'ContractsTariff:int:16, ContractsPointer:int:5))';

  IntercodeEvent = 'EventDate:date, EventTime:time, bitmap(EventDisplayData:int:8, ' +
    'EventNetworkId:hex:24, EventCode:int:8, EventResult:int:8, EventServiceProvider:int:8, ' +
    'EventNotOkCounter:int:8, EventSerialNumber:int:24, EventDestination:int:16, ' +
    'EventLocationId:int:16, EventLocationGate:int:8, EventDevice:int:16, ' +
    'EventRouteNumber:int:16, EventRouteVariant:int:8, EventJourneyRun:int:16, ' +
    'EventVehicleId:int:16, EventVehicleClass:int:8, EventLocationType:int:5, ' +
    'EventEmployee:str:240, EventLocationReference:int:16, EventJourneyInterchanges:int:8, ' +
    'EventPeriodJourneys:int:16, EventTotalJourneys:int:16, EventJourneyDistance:int:16, ' +
    'EventPriceAmount:int:16, EventPriceUnit:int:16, EventContractPointer:int:5, ' +
    'EventAuthenticator:int:16, bitmap(EventFirstStampDate:date, EventFirstStampTime:time, ' +
    'EventDataSimulation:int:1, EventDataTrip:int:2, EventDataRouteDirection:int:2))';

  IntercodeContractFF = 'bitmap(ContractNetworkId:hex:24, ContractProvider:int:8, ' +
    'ContractTariff:int:16, ContractSerialNumber:int:32, ' +
    'bitmap(ContractCustomerProfile:int:6, ContractCustomerNumber:int:32), ' +
    'bitmap(ContractPassengerClass:int:8, ContractPassengerTotal:int:8), ' +
    'ContractVehicleClassAllowed:int:6, ContractPaymentPointer:int:32, ' +
    'ContractPayMethod:int:11, ContractServices:int:16, ContractPriceAmount:int:16, ' +
    'ContractPriceUnit:int:16, bitmap(ContractRestrictStart:time, ContractRestrictEnd:time, ' +
    'ContractRestrictDay:int:8, ContractRestrictTimeCode:int:8, ContractRestrictCode:int:8, ' +
    'ContractRestrictProduct:int:16, ContractRestrictLocation:int:16), ' +
    'bitmap(ContractStartDate:date, ContractStartTime:time, ContractEndDate:date, ' +
    'ContractEndTime:time, ContractDuration:int:8, ContractLimitDate:date, ' +
    'ContractZones:int:8, ContractJourneys:int:16, ContractPeriodJourneys:int:16), ' +
    'bitmap(ContractOrigin1:int:16, ContractDestination1:int:16, ' +
    'ContractRouteNumbers:int:16, ContractRouteVariants:int:8, ContractRun:int:16, ' +
    'ContractVia1:int:16, ContractDistance:int:16, ContractInterchange:int:8), ' +
    'bitmap(ContractSaleDate:date, ContractSaleTime:time, ContractSaleAgent:int:8, ' +
    'ContractSaleDevice:int:16), ContractStatus:int:8, ContractLoyaltyPoints:int:16, ' +
    'ContractAuthenticator:int:16, ContractExtra:hex:0)';

  IntercodeCommonHead = 'bitmap(ContractProvider:int:8, ContractTariff:int:16, ' +
    'ContractSerialNumber:int:32, ContractPassengerClass:int:8, ' +
    'bitmap(ContractStartDate:date, ContractEndDate:date), ContractStatus:int:8, ';

  IntercodeDataCommon = 'seq(ContractOrigin1:int:16, ContractVia1:int:16, ' +
    'ContractDestination1:int:16), seq(ContractOrigin2:int:16, ContractDestination2:int:16), ' +
    'ContractZones:int:16, seq(ContractSaleDate:date, ContractSaleDevice:int:16, ' +
    'ContractSaleAgent:int:8), seq(ContractPayMethod:int:11, ContractPriceAmount:int:16, ' +
    'ContractReceiptDelivered:int:1), ContractPassengerTotal:int:6, ' +
    'seq(ContractEndPeriod:int:14, ContractSoldPeriod:int:6), ' +
    'seq(ContractSold:int:8, ContractDebitSold:int:5), ContractVehicleClassAllowed:int:4, ' +
    'LinkedContract:int:5';

  IntercodeContract20 = IntercodeCommonHead + 'bitmap(' + IntercodeDataCommon + '))';

  IntercodeContract46 = IntercodeCommonHead + 'bitmap(' + IntercodeDataCommon +
    ', ContractStartTime:time, ContractEndTime:time, ContractDataEndInhibitionDate:date, ' +
    'ContractDataValidityLimitDate:date, ContractDataGeoLine:int:28, ContractJourneys:int:16, ' +
    'ContractDataSaleSecureDevice:int:32))';

  IntercodeContractOther = IntercodeCommonHead + 'ContractData:hex:0)';

  LisboaEnvironment = '?EnvUnknownA:int:13, EnvNetworkCountry:hex:12, ?EnvUnknownB:int:5, ' +
    'CardSerialPrefix:int:8, EnvCardSerial:int:24, EnvApplicationIssueDate:date, ' +
    'EnvApplicationValidityEndDate:date, ?EnvUnknownC:int:15, HolderBirthDate:bcddate, ' +
    '?EnvUnknownD:hex:95';

  LisboaContract = 'ContractProvider:int:7, ContractTariff:int:16, ?ContractUnknownA:int:2, ' +
    'ContractStartDate:date, ContractSaleAgent:int:5, ?ContractUnknownB:int:19, ' +
    'ContractPeriodUnits:int:16, ContractEndDate:date, ContractPeriod:int:7, ' +
    '?ContractUnknownC:hex:38';

  LisboaEvent = 'EventDateTime:dt, ?EventUnknownA:int:3, EventFirstStampDateTime:dt, ' +
    '?EventUnknownB:int:5, ContractsUsedBitmap:int:4, ?EventUnknownC:hex:29, ' +
    'Transition:int:3, EventServiceProvider:int:5, EventVehicleId:int:16, ' +
    '?EventUnknownD:int:4, EventDeviceId:int:16, EventRouteNumber:int:16, ' +
    'EventLocationId:int:8, ?EventUnknownE:hex:63';

  RavKavEnvironment = 'EnvVersionNumber:int:3, EnvNetworkId:hex:20, ?EnvUnknownA:int:26, ' +
    'EnvApplicationIssueDate:date, EnvApplicationValidityEndDate:date, PayMethod:int:3, ' +
    'HolderBirthDate:bcddate, ?EnvUnknownB:hex:44, HolderIdNumber:int:30';

  RavKavContract = 'ContractVersion:int:3, ContractStartDate:date, ContractProvider:int:8, ' +
    'ContractTariff:int:11, ContractSaleDate:date, ContractSaleDevice:int:12, ' +
    'ContractSaleNumber:int:10, ContractInterchange:int:1, bitmap(?ContractUnknownA:int:5, ' +
    'ContractRestrictCode:int:5, ContractRestrictDuration:int:6, ContractEndDate:date, ' +
    'ContractDuration:int:8, ?ContractUnknownB:int:32, ?ContractUnknownC:int:6, ' +
    '?ContractUnknownD:int:32, ?ContractUnknownE:int:32)';

  RavKavEvent = 'EventVersion:int:3, EventServiceProvider:int:8, EventContractPointer:int:4, ' +
    'EventCode:int:8, EventDateTime:dt, EventTransferFlag:int:1, ' +
    'EventFirstStampDateTime:dt, EventContractPrefs:int:32, bitmap(EventLocationId:int:16, ' +
    'EventRouteNumber:int:16, StopEnRoute:int:8, ?EventUnknownA:int:12, ' +
    'EventVehicleId:int:14, ?EventUnknownB:int:4, ?EventUnknownC:int:8), ' +
    'bitmap(seq(RouteSystem:int:10, FareCode:int:8, EventPriceAmount:int:16), ' +
    '?EventUnknownD:int:32, ?EventUnknownE:int:32)';

  OpusEnvironment = IntercodeEnvFields + ', bitmap(seq(?HolderUnknownA:int:3, ' +
    'HolderBirthDate:bcddate, ?HolderUnknownB:int:13, HolderProfileDate:date, ' +
    '?HolderUnknownC:int:8), ?HolderUnknownD:int:8)';

  OpusContractList = 'repeat:4(bitmap(ContractsProvider:int:8, ContractsTariff:int:16, ' +
    '?ContractsUnknownA:int:4, ContractsPointer:int:5))';

  OpusContract = '?ContractUnknownA:int:3, bitmap(ContractProvider:int:8, ' +
    'ContractTariff:int:16, bitmap(ContractStartDate:date, ContractEndDate:date), ' +
    'seq(?ContractUnknownB:int:17, ContractSaleDate:date, ContractSaleTime:time, ' +
    '?ContractUnknownC:hex:36, ContractStatus:int:8, ?ContractUnknownD:hex:36))';

  OpusEvent = 'EventDate:date, EventTime:time, ?UnknownX:int:19, ' +
    'bitmap(?EventUnknownA:int:8, ?EventUnknownB:int:8, EventServiceProvider:int:8, ' +
    '?EventUnknownC:int:16, EventRouteNumber:int:16, ?EventUnknownD:int:16, ' +
    '?EventUnknownE:int:16, EventContractPointer:int:5, bitmap(EventFirstStampDate:date, ' +
    'EventFirstStampTime:time, EventDataSimulation:int:1, ?EventUnknownF:int:4, ' +
    '?EventUnknownG:int:4, ?EventUnknownH:int:4, ?EventUnknownI:int:4))';

  VeneziaEnvironment = '?EnvUnknownA:hex:49, EnvApplicationValidityEndDate:pdate, ' +
    'HolderProfileNumber:int:8, ?EnvUnknownB:hex:2, HolderProfileDate:pdate';

  VeneziaContract = '?ContractUnknownA:int:6, ContractTariff:int:16, IdCounter:int:8, ' +
    '?ContractUnknownB:hex:82, ContractSaleDate:pdate, ContractSaleTime:ptime11';

  VeneziaEvent = 'seq(?ContractsUnknownA1:int:1, ContractsTariff1:int:16, ' +
    '?ContractsUnknownB1:int:1), seq(?ContractsUnknownA2:int:1, ContractsTariff2:int:16, ' +
    '?ContractsUnknownB2:int:1), seq(?ContractsUnknownA3:int:1, ContractsTariff3:int:16, ' +
    '?ContractsUnknownB3:int:1), seq(?ContractsUnknownA4:int:1, ContractsTariff4:int:16, ' +
    '?ContractsUnknownB4:int:1), ?EventUnknownA:int:1, EventContractTariff:int:16, ' +
    '?EventUnknownB:int:4, EventDate:pdate, EventFirstStampTime:ptime11, EventTime:ptime11, ' +
    '?EventUnknownC:int:9, TransportType:int:4, YValue:int:14, Z:int:16, ' +
    '?EventUnknownE:int:18, PreviousZ:int:16, ?EventUnknownF:int:26';

  PisaEnvironment = 'EnvVersionNumber:int:5, EnvNetworkId:hex:24, ?EnvUnknownA:hex:44, ' +
    'EnvApplicationIssueDate:date, EnvApplicationValidityEndDate:date, HolderBirthDate:bcddate';

  PisaContract = '?ContractUnknownA:int:21, ContractTariff:int:16, ?ContractUnknownB:hex:92, ' +
    'ContractSaleDate:date, ?ContractUnknownC:hex:241';

  PisaEvent = '?EventUnknownA:hex:71, EventDateTime:dt, ?EventUnknownB:hex:82, ' +
    'EventFirstStampDateTime:dt, ValueA:int:16, ?EventUnknownC:hex:92, ValueB:int:16, ' +
    '?EventUnknownD:hex:47';

  PisaSpecialEvent = '?EventUnknownA:int:13, EventDate:date, EventTime:time, ' +
    '?EventUnknownB:hex:194';

function Variant(const ACode: Integer; const ADefinition: string)
  : TCalypsoContractVariant;
begin
  Result.Code := ACode;
  Result.Definition := ADefinition;
end;

class function TCalypsoNetworks.KindName(const AKind: TCalypsoNetworkKind): string;
begin
  case AKind of
    cnkMobib:
      Result := 'MOBIB (Belgium)';
    cnkIntercode:
      Result := 'Intercode (France)';
    cnkLisboaViva:
      Result := 'Lisboa Viva (Portugal)';
    cnkRavKav:
      Result := 'Rav-Kav (Israel)';
    cnkOpus:
      Result := 'OPUS (Quebec, Canada)';
    cnkVenezia:
      Result := 'Venezia Unica (Italy)';
    cnkPisa:
      Result := 'Pisa (Italy)';
  else
    Result := 'Unknown network (generic EN1545 view)';
  end;
end;

class function TCalypsoNetworks.RoleName(const ARole: TCalypsoRecordRole): string;
begin
  case ARole of
    crrEnvironment:
      Result := 'environment';
    crrContractList:
      Result := 'contract list';
    crrContract:
      Result := 'contract';
    crrEvent:
      Result := 'event';
    crrSpecialEvent:
      Result := 'special event';
    crrCounter:
      Result := 'counter';
  else
    Result := 'other';
  end;
end;

class function TCalypsoNetworks.Profile(const AKind: TCalypsoNetworkKind)
  : TCalypsoNetworkProfile;
begin
  Result := Default (TCalypsoNetworkProfile);
  Result.Kind := AKind;
  Result.Name := KindName(AKind);
  Result.Source := MetrodroidSource;
  Result.Note := NotChecked;
  Result.SecondContractFile := True;
  case AKind of
    cnkUnknown:
      begin
        Result.Source := 'Common EN1545 header position; may not apply to this card';
        Result.Note := 'No profile applied: header fields only, all other records raw.';
        Result.Environment := GenericEnvironment;
      end;
    cnkMobib:
      begin
        Result.Source := 'Metrodroid, Cardpeek, MOBIB Extractor';
        Result.Note := 'Header only here; decode the full card with TMobibCodec.Decode and ' +
          'TMobibSubscriptionCodec.DecodeSnapshot.';
        Result.Environment := MobibEnvironment;
      end;
    cnkIntercode:
      begin
        Result.Environment := IntercodeEnvironment;
        Result.ContractList := IntercodeContractList;
        Result.ContractSelector := ccsIntercodeListTariff;
        SetLength(Result.ContractVariants, 3);
        Result.ContractVariants[0] := Variant($FF, IntercodeContractFF);
        Result.ContractVariants[1] := Variant($20, IntercodeContract20);
        Result.ContractVariants[2] := Variant($46, IntercodeContract46);
        Result.Contract := IntercodeContractOther;
        Result.Event := IntercodeEvent;
        Result.SpecialEvent := IntercodeEvent;
        Result.Note := NotChecked + ' Contracts not referenced by the contract list stay raw.';
      end;
    cnkLisboaViva:
      begin
        Result.Environment := LisboaEnvironment;
        Result.Contract := LisboaContract;
        Result.Event := LisboaEvent;
      end;
    cnkRavKav:
      begin
        Result.Environment := RavKavEnvironment;
        Result.Contract := RavKavContract;
        Result.Event := RavKavEvent;
      end;
    cnkOpus:
      begin
        Result.Environment := OpusEnvironment;
        Result.ContractList := OpusContractList;
        Result.Contract := OpusContract;
        Result.Event := OpusEvent;
        Result.SecondContractFile := False;
        Result.Note := NotChecked + ' File 2030 is a copy of the contract list on OPUS cards.';
      end;
    cnkVenezia:
      begin
        Result.Environment := VeneziaEnvironment;
        Result.Contract := VeneziaContract;
        Result.Event := VeneziaEvent;
      end;
    cnkPisa:
      begin
        Result.Environment := PisaEnvironment;
        Result.Contract := PisaContract;
        Result.Event := PisaEvent;
        Result.SpecialEvent := PisaSpecialEvent;
      end;
  end;
end;

function IntercodeNetworkName(const AId: Cardinal): string;
begin
  case AId of
    $250000:
      Result := 'Pass Pass';
    $250064:
      Result := 'TaM (Montpellier)';
    $250502:
      Result := 'OuRA (Auvergne-Rhone-Alpes)';
    $250901:
      Result := 'Navigo (Ile-de-France)';
    $250908:
      Result := 'KorriGo (Bretagne)';
    $250916:
      Result := 'Tisseo (Toulouse)';
    $250920:
      Result := 'Envibus (Sophia Antipolis)';
    $250921:
      Result := 'Gironde';
  else
    Result := '';
  end;
end;

class function TCalypsoNetworks.Recommend(const AEnvironment: TBytes)
  : TCalypsoNetworkMatch;
var
  Id24: Cardinal;

  procedure Hit(const AKind: TCalypsoNetworkKind; const ACode, AName, AReason: string);
  begin
    Result.Kind := AKind;
    Result.Matched := True;
    Result.NetworkCode := ACode;
    Result.NetworkName := AName;
    Result.Reason := AReason;
  end;

begin
  Result := Default (TCalypsoNetworkMatch);
  Result.Kind := cnkUnknown;
  Result.Reason := 'No profile discriminator matched; use the generic view.';
  if Length(AEnvironment) < 5 then
  begin
    Result.Reason := 'Environment record shorter than five bytes.';
    Exit;
  end;
  Id24 := Cardinal(TEn1545.Bits(AEnvironment, 13, 24));
  Result.NetworkCode := IntToHex(Id24, 6);
  if Id24 = $056001 then
    Hit(cnkMobib, '056001', 'MOBIB', 'Bits 13..36 = 056001 (Belgium, network 001).')
  else if Id24 = $124001 then
    Hit(cnkOpus, '124001', 'OPUS', 'Bits 13..36 = 124001.')
  else if (Id24 shr 12) = $250 then
    Hit(cnkIntercode, IntToHex(Id24, 6), IntercodeNetworkName(Id24),
      'Bits 13..24 = 250 (France), network ' + IntToHex(Id24 and $FFF, 3) + '.')
  else if (Id24 shr 12) = $131 then
    Hit(cnkLisboaViva, '131', 'Lisboa Viva', 'Bits 13..24 = 131.')
  else if (TEn1545.Bits(AEnvironment, 3, 20) = $37602) or
    (TEn1545.Bits(AEnvironment, 3, 20) = $37603) then
    Hit(cnkRavKav, IntToHex(TEn1545.Bits(AEnvironment, 3, 20), 5), 'Rav-Kav',
      'Bits 3..22 = ' + IntToHex(TEn1545.Bits(AEnvironment, 3, 20), 5) + ' (Israel).')
  else if TEn1545.Bits(AEnvironment, 0, 32) = $7D0 then
    Hit(cnkVenezia, '000007D0', 'Venezia Unica', 'Bytes 0..3 = 000007D0.')
  else if TEn1545.Bits(AEnvironment, 5, 24) = $380100 then
    Hit(cnkPisa, '380100', 'Pisa', 'Bits 5..28 = 380100 (Italy).');
end;

function TicketingFile(const F: TCalypsoFile): Boolean;
begin
  Result := (not F.BySfi) and (F.SelectionStatus = $9000) and
    ((F.Folder = 0) or (F.Folder = $2000));
end;

function FindRecord(const S: TMobibSnapshot; const AId: Word; const ANumber: Byte;
  out AData: TBytes): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  AData := nil;
  for I := 0 to High(S.Files) do
    if TicketingFile(S.Files[I]) and (S.Files[I].LogicalId = AId) then
      for J := 0 to High(S.Files[I].Records) do
        if S.Files[I].Records[J].Number = ANumber then
        begin
          AData := S.Files[I].Records[J].Data;
          Result := True;
          Exit;
        end;
end;

function HasTicketingFile(const S: TMobibSnapshot; const AId: Word): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(S.Files) do
    if TicketingFile(S.Files[I]) and (S.Files[I].LogicalId = AId) then
      Result := True;
end;

class function TCalypsoNetworks.RecommendSnapshot(const ASnapshot: TMobibSnapshot)
  : TCalypsoNetworkMatch;
var
  B: TBytes;
begin
  if FindRecord(ASnapshot, $2001, 1, B) then
    Result := Recommend(B)
  else
  begin
    Result := Default (TCalypsoNetworkMatch);
    Result.Kind := cnkUnknown;
    Result.Reason := 'Environment 2001 record 1 not present in the snapshot.';
  end;
end;

function AllZero(const B: TBytes): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to High(B) do
    if B[I] <> 0 then
      Exit(False);
end;

class function TCalypsoNetworks.Decode(const ASnapshot: TMobibSnapshot;
  const AKind: TCalypsoNetworkKind): TCalypsoNetworkView;
var
  View: TCalypsoNetworkView;
  P: TCalypsoNetworkProfile;
  ListParsed: TEn1545Parsed;
  HasList: Boolean;
  ContractNo: Integer;

  function Add(const F: TCalypsoFile; const ANumber: Byte; const AData: TBytes;
    const ARole: TCalypsoRecordRole): Integer;
  begin
    Result := Length(View.Records);
    SetLength(View.Records, Result + 1);
    View.Records[Result].Folder := F.Folder;
    if View.Records[Result].Folder = 0 then
      View.Records[Result].Folder := $2000;
    View.Records[Result].FileId := F.LogicalId;
    View.Records[Result].RecordNumber := ANumber;
    View.Records[Result].Role := ARole;
    View.Records[Result].Data := Copy(AData, 0, Length(AData));
  end;

  procedure Apply(const AIndex: Integer; const AName, ADefinition: string);
  var
    D: TBytes;
  begin
    if ADefinition = '' then
    begin
      View.Records[AIndex].Note := 'No layout in this profile; kept raw.';
      Exit;
    end;
    D := View.Records[AIndex].Data;
    if Length(D) > 256 then
    begin
      View.Records[AIndex].Note := 'Longer than 256 bytes; first 256 bytes parsed.';
      SetLength(D, 256);
    end;
    View.Records[AIndex].Parsed := TEn1545.Parse(D,
      TEn1545.Compile(P.Name + '.' + AName, P.Source, ADefinition));
    View.Records[AIndex].Decoded := True;
  end;

  function ContractDefinition(const ANumber: Integer; out ANote: string): string;
  var
    I, J, Code: Integer;
    V: TEn1545Value;
    Tariff: Int64;
  begin
    ANote := '';
    Result := P.Contract;
    if P.ContractSelector <> ccsIntercodeListTariff then
      Exit;
    Result := '';
    if not HasList then
    begin
      ANote := 'No contract list; the layout variant cannot be selected.';
      Exit;
    end;
    for I := 1 to 15 do
      if TEn1545.Find(ListParsed, 'ContractsPointer[' + IntToStr(I) + ']', V) and
        V.HasRaw and (Integer(V.Raw) = ANumber) then
      begin
        Tariff := TEn1545.IntOr(ListParsed, 'ContractsTariff[' + IntToStr(I) + ']', -1);
        if Tariff < 0 then
        begin
          ANote := 'Contract list entry has no tariff; the layout variant cannot be selected.';
          Exit;
        end;
        Code := Integer((Tariff shr 4) and $FF);
        Result := P.Contract;
        for J := 0 to High(P.ContractVariants) do
          if P.ContractVariants[J].Code = Code then
            Result := P.ContractVariants[J].Definition;
        ANote := 'Layout variant ' + IntToHex(Code, 2) + ' from contract list entry ' +
          IntToStr(I) + '.';
        Exit;
      end;
    ANote := 'Not referenced by the contract list; kept raw.';
  end;

  procedure AddCounter(const AIndex, ANumber: Integer);
  var
    B: TBytes;
  begin
    if FindRecord(ASnapshot, $2069, 1, B) then
    begin
      if Length(B) >= 3 * ANumber then
      begin
        View.Records[AIndex].HasCounter := True;
        View.Records[AIndex].Counter := (Cardinal(B[3 * ANumber - 3]) shl 16) or
          (Cardinal(B[3 * ANumber - 2]) shl 8) or B[3 * ANumber - 1];
        View.Records[AIndex].CounterFileId := $2069;
      end;
    end
    else if (ANumber <= 4) and FindRecord(ASnapshot, $2029 + ANumber, 1, B) and
      (Length(B) >= 3) then
    begin
      View.Records[AIndex].HasCounter := True;
      View.Records[AIndex].Counter := (Cardinal(B[0]) shl 16) or
        (Cardinal(B[1]) shl 8) or B[2];
      View.Records[AIndex].CounterFileId := $2029 + ANumber;
    end;
  end;

  procedure AddContracts(const AId: Word);
  var
    I, J, K: Integer;
    Def, Note: string;
  begin
    for I := 0 to High(ASnapshot.Files) do
      if TicketingFile(ASnapshot.Files[I]) and (ASnapshot.Files[I].LogicalId = AId) then
        for J := 0 to High(ASnapshot.Files[I].Records) do
        begin
          Inc(ContractNo);
          K := Add(ASnapshot.Files[I], ASnapshot.Files[I].Records[J].Number,
            ASnapshot.Files[I].Records[J].Data, crrContract);
          View.Records[K].ContractNumber := ContractNo;
          if AllZero(View.Records[K].Data) then
          begin
            View.Records[K].Note := 'Empty record.';
            Continue;
          end;
          Def := ContractDefinition(ContractNo, Note);
          if Def <> '' then
            Apply(K, 'Contract', Def);
          if Note <> '' then
            View.Records[K].Note := Note
          else if Def = '' then
            View.Records[K].Note := 'No layout in this profile; kept raw.';
          AddCounter(K, ContractNo);
        end;
  end;

var
  I, J, K: Integer;
  Env: TBytes;
  F: TCalypsoFile;
  Role: TCalypsoRecordRole;
  B: TBytes;
begin
  P := Profile(AKind);
  View := Default (TCalypsoNetworkView);
  View.Kind := AKind;
  View.ProfileName := P.Name;
  View.Source := P.Source;
  View.CheckedOnCard := P.CheckedOnCard;
  View.Note := P.Note;
  ContractNo := 0;

  Env := nil;
  F := Default (TCalypsoFile);
  for I := 0 to High(ASnapshot.Files) do
    if TicketingFile(ASnapshot.Files[I]) and (ASnapshot.Files[I].LogicalId = $2001) then
    begin
      F := ASnapshot.Files[I];
      for J := 0 to High(F.Records) do
      begin
        K := Length(Env);
        SetLength(Env, K + Length(F.Records[J].Data));
        if Length(F.Records[J].Data) > 0 then
          Move(F.Records[J].Data[0], Env[K], Length(F.Records[J].Data));
      end;
    end;
  if HasTicketingFile(ASnapshot, $2001) then
  begin
    K := Add(F, 0, Env, crrEnvironment);
    Apply(K, 'Environment', P.Environment);
    View.Records[K].Note := Trim(View.Records[K].Note +
      ' All environment records concatenated.');
  end;

  HasList := False;
  ListParsed := Default (TEn1545Parsed);
  if (P.ContractList <> '') and FindRecord(ASnapshot, $2050, 1, B) then
  begin
    ListParsed := TEn1545.Parse(B, TEn1545.Compile(P.Name + '.ContractList', P.Source,
      P.ContractList));
    HasList := True;
  end;

  for I := 0 to High(ASnapshot.Files) do
  begin
    F := ASnapshot.Files[I];
    if TicketingFile(F) and ((F.LogicalId = $2001) or (F.LogicalId = $2020) or
      ((F.LogicalId = $2030) and P.SecondContractFile)) then
      Continue;
    for J := 0 to High(F.Records) do
    begin
      Role := crrOther;
      if TicketingFile(F) then
        case F.LogicalId of
          $2050:
            Role := crrContractList;
          $2010:
            Role := crrEvent;
          $2040:
            Role := crrSpecialEvent;
          $2069, $202A .. $202D:
            Role := crrCounter;
        end;
      K := Add(F, F.Records[J].Number, F.Records[J].Data, Role);
      if (Role in [crrEvent, crrSpecialEvent]) and AllZero(F.Records[J].Data) then
        View.Records[K].Note := 'Empty record.'
      else
        case Role of
          crrContractList:
            if (P.ContractList <> '') and (F.Records[J].Number = 1) then
            begin
              View.Records[K].Parsed := ListParsed;
              View.Records[K].Decoded := True;
            end
            else
              View.Records[K].Note := 'No layout in this profile; kept raw.';
          crrEvent:
            Apply(K, 'Event', P.Event);
          crrSpecialEvent:
            Apply(K, 'SpecialEvent', P.SpecialEvent);
        end;
    end;
  end;

  AddContracts($2020);
  if P.SecondContractFile then
    AddContracts($2030);
  Result := View;
end;

end.
