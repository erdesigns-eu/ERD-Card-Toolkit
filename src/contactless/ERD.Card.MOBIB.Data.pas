unit ERD.Card.MOBIB.Data;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Contactless.Calypso, ERD.Card.EN1545;

type
  /// <summary>Explicit transit-data layout; matching is required before issuer-specific fields are decoded.</summary>
  TMobibLayout = (
    /// <summary>Preserve all files without interpreting issuer-specific fields.</summary>
    mlRaw,
    /// <summary>Published legacy MOBIB country 056/network 001 layout.</summary>
    mlLegacy056001);
  /// <summary>Invalid bit range, BCD, date or record layout; retains no personal input.</summary>
  EMobibDecodeError = class(Exception);

  /// <summary>Legacy extended holder record assembled from records one and two (29-byte payloads; zero-padded 48-byte records are accepted).</summary>
  TMobibHolder = record
    /// <summary>True when complete nonempty extended-holder data was decoded.</summary>
    Present: Boolean;
    /// <summary>Exact nineteen decimal identifier digits, including leading zeroes.</summary>
    Number: UnicodeString;
    /// <summary>Decoded five-bit alphabet name, without inferred surname/forename splitting.</summary>
    Name: UnicodeString;
    /// <summary>True when a nonzero valid YYYYMMDD birth date is present.</summary>
    HasBirthDate: Boolean;
    /// <summary>Civil birth date; meaningful only when HasBirthDate is true.</summary>
    BirthDate: TDateTime;
    /// <summary>Raw two-bit holder gender field; no social-title inference.</summary>
    GenderCode: Byte;
  end;

  /// <summary>Event structure used for one event record.</summary>
  TMobibEventLayoutKind = (
    /// <summary>Unsupported event version; only raw bytes are kept.</summary>
    melUnsupported,
    /// <summary>Fixed layout of event versions 0..2.</summary>
    melLegacyFixed,
    /// <summary>Presence-bitmap layout of event version 3.</summary>
    melBitmap);

  /// <summary>One decoded validation or special event, without station-name or fare inference.</summary>
  TMobibEvent = record
    /// <summary>Original absolute event record number.</summary>
    RecordNumber: Byte;
    /// <summary>Civil validation date from days since 1997-01-01.</summary>
    Date: TDateTime;
    /// <summary>Minutes since midnight, 0..1439.</summary>
    Minutes: Word;
    /// <summary>Civil first-validation date from days since 1997-01-01.</summary>
    FirstDate: TDateTime;
    /// <summary>First validation minutes since midnight, 0..1439.</summary>
    FirstMinutes: Word;
    /// <summary>Raw five-bit transport code; 0 metro, 7 premetro, 15 bus, 22 tram in this layout.</summary>
    TransportCode: Byte;
    /// <summary>True when this profile defines a location field for the recorded transport mode.</summary>
    HasLocation: Boolean;
    /// <summary>Raw location identifier using the layout's mode-specific field.</summary>
    LocationId: Cardinal;
    /// <summary>Raw seven-bit bus route number; zero for other modes.</summary>
    BusRoute: Byte;
    /// <summary>Raw twenty-three-bit event coupon/count field; no remaining-ticket inference.</summary>
    CouponCount: Cardinal;
    /// <summary>Logical file the event came from: 2010 (validations) or 2040 (special events).</summary>
    SourceFileId: Word;
    /// <summary>Six-bit event structure version.</summary>
    Version: Byte;
    /// <summary>Layout used: legacy fixed (versions 0..2) or presence-bitmap (version 3).</summary>
    LayoutKind: TMobibEventLayoutKind;
    /// <summary>False when the record ended before the last field of the selected layout.</summary>
    Complete: Boolean;
    /// <summary>True when the first-validation date/time fields were present.</summary>
    HasFirstStamp: Boolean;
    /// <summary>True when the five-bit service-provider/transport field was present.</summary>
    HasProvider: Boolean;
    /// <summary>True when the five-bit passenger-count field was present (legacy layout only).</summary>
    HasPassengerCount: Boolean;
    /// <summary>Raw passenger count; no fare inference.</summary>
    PassengerCount: Byte;
    /// <summary>True when the sixteen-bit route field was present.</summary>
    HasRoute: Boolean;
    /// <summary>Raw sixteen-bit route number; BusRoute keeps its low seven bits.</summary>
    RouteNumber: Word;
    /// <summary>True when the twelve-bit bus location field was present.</summary>
    HasBusLocation: Boolean;
    /// <summary>Raw twelve-bit bus stop location code.</summary>
    BusLocationId: Word;
    /// <summary>True when the seventeen-bit station location field was present.</summary>
    HasStationLocation: Boolean;
    /// <summary>Raw seventeen-bit station location: zone (6) / sub-zone (4) / station (7).</summary>
    StationLocationId: Cardinal;
    /// <summary>Six-bit zone part of StationLocationId.</summary>
    Zone: Byte;
    /// <summary>Four-bit sub-zone part of StationLocationId.</summary>
    SubZone: Byte;
    /// <summary>Seven-bit station part of StationLocationId.</summary>
    Station: Byte;
    /// <summary>True when the event serial (transaction) number was present.</summary>
    HasSerialNumber: Boolean;
    /// <summary>Raw 24-bit event serial number.</summary>
    SerialNumber: Cardinal;
    /// <summary>True when the transfer-number field was present.</summary>
    HasTransferNumber: Boolean;
    /// <summary>Raw transfer number (24 bits legacy, 8 bits bitmap layout).</summary>
    TransferNumber: Cardinal;
    /// <summary>Every parsed field with bit position, raw value and confidence, plus the unparsed remainder.</summary>
    Fields: TEn1545Parsed;
  end;

  /// <summary>Events in original file order, excluding entirely zero-filled records.</summary>
  TMobibEvents = array of TMobibEvent;

  /// <summary>Known legacy contract date; uninterpreted bytes remain in the raw snapshot.</summary>
  TMobibContract = record
    /// <summary>Absolute contract record number.</summary>
    RecordNumber: Byte;
    /// <summary>Legacy contract purchase date from the fourteen-bit field at bit 41.</summary>
    PurchaseDate: TDateTime;
  end;

  /// <summary>Available contract-date decodings; product/validity semantics are not inferred.</summary>
  TMobibContracts = array of TMobibContract;

  /// <summary>One unsigned 24-bit counter from a legacy counter record.</summary>
  TMobibCounter = record
    /// <summary>Original counter record number.</summary>
    RecordNumber: Byte;
    /// <summary>One-based three-byte slot within that record.</summary>
    Slot: Byte;
    /// <summary>Big-endian 24-bit value, never a sum of its bytes.</summary>
    Value: Cardinal;
    /// <summary>File the value came from: 2069, or 202A..202D when 2069 was not selected.</summary>
    SourceFileId: Word;
  end;

  /// <summary>Decoded counter slots without guessing their contract association or fare units.</summary>
  TMobibCounters = array of TMobibCounter;

  /// <summary>Decoded ticketing environment (file 2001) for a supported version.</summary>
  /// <remarks>Contains personal data on personalised cards; mask before display or export.</remarks>
  TMobibEnvironment = record
    /// <summary>True when a supported environment version (0..3) was decoded.</summary>
    Present: Boolean;
    /// <summary>Six-bit environment version.</summary>
    Version: Byte;
    /// <summary>True when the application expiry date is present.</summary>
    HasExpiry: Boolean;
    /// <summary>Application (card) expiry date.</summary>
    Expiry: TDateTime;
    /// <summary>True when the 19-digit card number is valid BCD and not all zero.</summary>
    HasCardNumber: Boolean;
    /// <summary>Card number digits, including leading zeroes.</summary>
    CardNumber: UnicodeString;
    /// <summary>Card number grouped as printed: 6 / 12 / 1 digits.</summary>
    CardNumberFormatted: UnicodeString;
    /// <summary>True when a valid nonzero BCD birth date is present.</summary>
    HasBirthDate: Boolean;
    /// <summary>Holder birth date (personal data).</summary>
    BirthDate: TDateTime;
    /// <summary>True when the postal-code field is nonzero.</summary>
    HasPostalCode: Boolean;
    /// <summary>Holder postal code (personal data).</summary>
    PostalCode: Word;
    /// <summary>True when the environment carries a birth date or postal code (personalised card).</summary>
    Personalised: Boolean;
    /// <summary>All parsed environment fields with positions and confidence.</summary>
    Fields: TEn1545Parsed;
  end;

  /// <summary>Chip production data from MF file 0002 record one.</summary>
  TMobibIcc = record
    /// <summary>True when a record of at least 27 bytes was read.</summary>
    Present: Boolean;
    /// <summary>Bytes 12..19 as hexadecimal (chip serial number).</summary>
    SerialHex: string;
    /// <summary>Bytes 20..21 as hexadecimal BCD manufacturing country, e.g. 0056.</summary>
    CountryCode: string;
    /// <summary>Byte 22 manufacturer code.</summary>
    ManufacturerCode: Byte;
    /// <summary>Manufacturer name from the MOBIB-Extractor list, or empty.</summary>
    ManufacturerName: string;
    /// <summary>True when the manufacturing date is nonzero.</summary>
    HasManufactureDate: Boolean;
    /// <summary>Manufacturing date (days since 1990-01-01 at bytes 25..26).</summary>
    ManufactureDate: TDateTime;
  end;

  /// <summary>Candidate split of contract list 2050; no published layout exists.</summary>
  TMobibContractList = record
    /// <summary>True when record one of 2050 was read.</summary>
    Present: Boolean;
    /// <summary>First nibble: number of entries.</summary>
    Count: Byte;
    /// <summary>Candidate 28-bit entries after the count nibble (observed split).</summary>
    Entries: array of Cardinal;
    /// <summary>Always ecObserved: the split is an observation, not a published layout.</summary>
    Confidence: TEn1545Confidence;
  end;

  /// <summary>Owned raw snapshot plus explicitly matched legacy MOBIB data.</summary>
  TMobibData = record
    /// <summary>Independent copy of every acquired file, record, response and status.</summary>
    Raw: TMobibSnapshot;
    /// <summary>True only when the selected legacy profile matches environment country 056 and network 001.</summary>
    LayoutMatched: Boolean;
    /// <summary>True when a nonempty environment contains a valid network identifier.</summary>
    HasNetwork: Boolean;
    /// <summary>Three-digit BCD environment country code as an integer, 56 for Belgium.</summary>
    CountryCode: Integer;
    /// <summary>Three-digit BCD network code; not a guessed operator name.</summary>
    NetworkCode: Integer;
    /// <summary>Decoded extended holder, when both required records are available.</summary>
    Holder: TMobibHolder;
    /// <summary>Decoded validation events from file 2010.</summary>
    Events: TMobibEvents;
    /// <summary>Decoded known purchase-date fields from file 2020.</summary>
    Contracts: TMobibContracts;
    /// <summary>Decoded 24-bit slots from file 2069.</summary>
    Counters: TMobibCounters;
    /// <summary>True when legacy contract-list file 2050 record one is available.</summary>
    HasContractCount: Boolean;
    /// <summary>Raw contract count from the first nibble of the matched legacy contract list.</summary>
    ContractCount: Byte;
    /// <summary>Decoded environment fields: version, expiry, card number, birth date, postal code.</summary>
    Environment: TMobibEnvironment;
    /// <summary>Decoded special events from file 2040, in record order.</summary>
    SpecialEvents: TMobibEvents;
    /// <summary>Nonempty event records whose version has no supported layout (kept raw).</summary>
    UnsupportedEventCount: Integer;
    /// <summary>Chip production data from MF file 0002, when read.</summary>
    Icc: TMobibIcc;
    /// <summary>True when the purse load log (1000/1014) holds a nonzero card purchase date.</summary>
    HasCardPurchaseDate: Boolean;
    /// <summary>Card purchase date from purse load log record one, bits 2..15.</summary>
    CardPurchaseDate: TDateTime;
    /// <summary>Candidate split of contract list 2050.</summary>
    ContractList: TMobibContractList;
  end;

  /// <summary>Offline bounded MOBIB bit, alphabet, BCD and known-layout decoding; opens no hardware.</summary>
  TMobibCodec = class
  public
    /// <summary>Extracts an unsigned MSB-first field across byte boundaries.</summary>
    /// <param name="AData">Source record bytes.</param>
    /// <param name="ABitOffset">Zero-based bit offset from the first byte's high bit.</param>
    /// <param name="ABitCount">Field width, 1..32.</param>
    /// <returns>Unsigned numeric field value.</returns>
    class function Bits(const AData: TBytes;
      const ABitOffset, ABitCount: Integer): Cardinal; static;
    /// <summary>Decodes nibble-aligned-in-bits BCD, preserving leading zeroes.</summary>
    /// <param name="AData">Source bytes.</param>
    /// <param name="ABitOffset">MSB-first starting bit.</param>
    /// <param name="ADigits">Number of decimal nibbles, 1..64.</param>
    /// <returns>Decimal text; invalid nibbles raise EMobibDecodeError.</returns>
    class function Bcd(const AData: TBytes; const ABitOffset, ADigits: Integer)
      : UnicodeString; static;
    /// <summary>Decodes the EN1545 five-bit alphabet without guessing Unicode names.</summary>
    /// <param name="AData">Source bytes.</param>
    /// <param name="ABitOffset">MSB-first starting bit.</param>
    /// <param name="ACharacters">Character count, 1..128.</param>
    /// <returns>Decoded text; reserved codes appear as question marks.</returns>
    class function Alpha(const AData: TBytes;
      const ABitOffset, ACharacters: Integer): UnicodeString; static;
    /// <summary>Clones raw acquisition and decodes only the explicitly selected, network-matched layout.</summary>
    /// <param name="ASnapshot">Acquired raw files and statuses.</param>
    /// <param name="ALayout">Raw mode or explicit legacy country/network profile.</param>
    /// <returns>Independent raw data and available typed fields; unmatched layouts retain raw bytes only.</returns>
    /// <remarks>Absent/restricted files do not become fabricated fields. Complete malformed known fields
    /// fail explicitly. No issuer authenticity, entitlement or counter-to-ticket meaning is inferred.</remarks>
    class function Decode(const ASnapshot: TMobibSnapshot;
      const ALayout: TMobibLayout): TMobibData; static;
    /// <summary>Decodes one event record (2010 or 2040) by its version.</summary>
    /// <param name="AData">Nonempty event record.</param>
    /// <param name="ARecordNumber">Absolute record number.</param>
    /// <param name="ASourceFileId">Logical file identifier the record came from.</param>
    /// <param name="AEvent">Decoded event.</param>
    /// <returns>False for unsupported versions; malformed times raise EMobibDecodeError.</returns>
    class function DecodeEvent(const AData: TBytes; const ARecordNumber: Byte;
      const ASourceFileId: Word; out AEvent: TMobibEvent): Boolean; static;
    /// <summary>Decodes an environment record (2001) by its version.</summary>
    /// <param name="AData">Environment record one.</param>
    /// <returns>Decoded environment; Present is false for unsupported versions.</returns>
    class function DecodeEnvironment(const AData: TBytes)
      : TMobibEnvironment; static;
    /// <summary>Returns the MOBIB-Extractor manufacturer name of an ICC code.</summary>
    /// <param name="ACode">Byte 22 of file 0002.</param>
    /// <returns>Manufacturer name, or empty when not listed.</returns>
    class function ManufacturerName(const ACode: Byte): string; static;
  end;

implementation

uses ERD.Card.Bytes;

const
  EnvLegacyLayout = 'EnvVersionNumber:int:6, ?EnvUnknownA:int:7, EnvNetworkId:bcd:24,' +
    ' ?EnvUnknownB:int:9, EnvApplicationValidityEnd:date, ?EnvUnknownC:int:6,' +
    ' HolderBirthDate:bcddate, EnvCardSerial:bcd:76, ?EnvUnknownD:int:5,' +
    ' HolderPostalCode:int:14, ?EnvUnknownE:hex:34';
  EnvV3Layout = 'EnvVersionNumber:int:6, ?EnvUnknownA:int:7, EnvNetworkId:bcd:24,' +
    ' ?EnvUnknownB:int:5, EnvApplicationValidityEnd:date, ?EnvUnknownC:int:10,' +
    ' HolderBirthDate:bcddate, EnvCardSerial:bcd:76, ?EnvUnknownD:int:5,' +
    ' HolderPostalCode:int:14, ?EnvUnknownE:hex:34';
  EventLegacyLayout = 'EventVersion:int:6, EventDate:date, EventTime:time,' +
    ' ?EventUnknownB:int:21, EventPassengerCount:int:5, ?EventUnknownC:int:14,' +
    ' EventLocationIdBus:int:12, EventRouteNumber:int:16, EventServiceProvider:int:5,' +
    ' EventLocationId:int:17, ?EventUnknownE:int:10, ?EventUnknownF:int:7,' +
    ' EventSerialNumber:int:24, EventTransferNumber:int:24, EventFirstStampDate:date,' +
    ' EventFirstStampTime:time, ?EventUnknownG:int:21';
  EventBitmapLayout = 'EventVersion:int:6, EventDate:date, EventTime:time,' +
    ' ?EventUnknownB1:int:31, EventBitmap1:bitmap(seq(?EventUnknownB2:int:4,' +
    ' EventLocationIdBus:int:12), EventRouteNumber:int:16, ?NeverSeen2:int:16,' +
    ' ?NeverSeen3:int:16, seq(EventServiceProvider:int:5, EventLocationId:int:17,' +
    ' ?EventUnknownE1:int:10)), EventBitmap2:bitmap(EventSerialNumber:int:24,' +
    ' ?EventUnknownF:int:16, EventTransferNumber:int:8, ?NeverSeenA3:int:16,' +
    ' seq(EventFirstStampDate:date, EventFirstStampTime:time), ?NeverSeenA5:int:16),' +
    ' ?EventUnknownG:int:21';
  LayoutSource = 'Metrodroid MOBIB layouts (GPL-3.0; facts only), Cardpeek, MOBIB-Extractor';

procedure Fail;
begin
  raise EMobibDecodeError.Create('Invalid MOBIB layout data.');
end;

class function TMobibCodec.Bits(const AData: TBytes;
  const ABitOffset, ABitCount: Integer): Cardinal;
var
  I, P: Integer;
begin
  if (ABitOffset < 0) or (ABitCount < 1) or (ABitCount > 32) or
    (Int64(ABitOffset) + ABitCount > Int64(Length(AData)) * 8) then
    Fail;
  Result := 0;
  for I := 0 to ABitCount - 1 do
  begin
    P := ABitOffset + I;
    Result := (Result shl 1) or ((AData[P div 8] shr (7 - P mod 8)) and 1);
  end;
end;

class function TMobibCodec.Bcd(const AData: TBytes;
  const ABitOffset, ADigits: Integer): UnicodeString;
var
  I, N: Integer;
begin
  Result := '';
  if (ADigits < 1) or (ADigits > 64) or (ABitOffset < 0) or
    (Int64(ABitOffset) + Int64(ADigits) * 4 > Int64(Length(AData)) * 8) then
    Fail;
  for I := 0 to ADigits - 1 do
  begin
    N := Integer(Bits(AData, ABitOffset + I * 4, 4));
    if N > 9 then
      Fail;
    Result := Result + WideChar(Ord('0') + N);
  end;
end;

class function TMobibCodec.Alpha(const AData: TBytes;
  const ABitOffset, ACharacters: Integer): UnicodeString;
const
  Alphabet: UnicodeString = '-ABCDEFGHIJKLMNOPQRSTUVWXYZ???? ';
var
  I: Integer;
begin
  Result := '';
  if (ACharacters < 1) or (ACharacters > 128) or (ABitOffset < 0) or
    (Int64(ABitOffset) + Int64(ACharacters) * 5 > Int64(Length(AData)) * 8) then
    Fail;
  for I := 0 to ACharacters - 1 do
    Result := Result + Alphabet
      [Integer(Bits(AData, ABitOffset + I * 5, 5)) + 1];
end;

function Empty(const B: TBytes): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to High(B) do
    if B[I] <> 0 then
    begin
      Result := False;
      Exit;
    end;
end;

function InFolder(const F: TCalypsoFile; const AFolder: Word): Boolean;
begin
  if F.BySfi or (F.SelectionStatus <> $9000) then
    Result := False
  else if AFolder = $2000 then
    Result := (F.Folder = 0) or (F.Folder = $2000)
  else
    Result := F.Folder = AFolder;
end;

function FolderRecord(const S: TMobibSnapshot; const AFolder, Id: Word;
  const N: Byte): TBytes;
var
  I, J: Integer;
begin
  Result := nil;
  for I := 0 to High(S.Files) do
    if (S.Files[I].LogicalId = Id) and InFolder(S.Files[I], AFolder) then
      for J := 0 to High(S.Files[I].Records) do
        if S.Files[I].Records[J].Number = N then
        begin
          if Length(Result) <> 0 then
            Fail;
          Result := S.Files[I].Records[J].Data;
        end;
end;

function RecordData(const S: TMobibSnapshot; const Id: Word;
  const N: Byte): TBytes;
begin
  Result := FolderRecord(S, $2000, Id, N);
end;

function HasFile(const S: TMobibSnapshot; const Id: Word): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(S.Files) do
    if (S.Files[I].LogicalId = Id) and InFolder(S.Files[I], $2000) then
      Result := True;
end;

function DateValue(const Days: Cardinal): TDateTime;
begin
  Result := EncodeDate(1997, 1, 1) + Days;
end;

class function TMobibCodec.ManufacturerName(const ACode: Byte): string;
begin
  case ACode of
    $00: Result := 'ASK';
    $01: Result := 'Intec';
    $02, $11, $20, $2E: Result := 'Calypso';
    $03: Result := 'Ascom';
    $04: Result := 'Thales';
    $05: Result := 'Sagem';
    $06: Result := 'Axalto';
    $07: Result := 'Bull';
    $08: Result := 'Spirtech';
    $09: Result := 'BMS';
    $0A: Result := 'Oberthur';
    $0B: Result := 'Gemplus';
    $0C: Result := 'Magnadata';
    $0D: Result := 'Calmell';
    $0E: Result := 'Mecstar';
    $0F: Result := 'ACG Identification';
    $10: Result := 'STMicroelectronics';
    $12: Result := 'Giesecke & Devrient';
    $13: Result := 'OTI';
    $14: Result := 'Gemalto';
    $15: Result := 'Watchdata';
    $16: Result := 'Alios';
    $17: Result := 'S-P-S';
    $18: Result := 'IRSA';
    $21: Result := 'Innovatron';
  else
    Result := '';
  end;
end;

class function TMobibCodec.DecodeEnvironment(const AData: TBytes)
  : TMobibEnvironment;
var
  L: TEn1545Layout;
  V: TEn1545Value;
  Digits: string;
begin
  Result := Default (TMobibEnvironment);
  if (Length(AData) < 1) or (Length(AData) > 256) then
    Fail;
  Result.Version := Byte(AData[0] shr 2);
  if Result.Version > 3 then
    Exit;
  if Result.Version <= 2 then
    L := TEn1545.Compile('MOBIB.Environment.V0-2', LayoutSource, EnvLegacyLayout)
  else
    L := TEn1545.Compile('MOBIB.Environment.V3', LayoutSource, EnvV3Layout);
  Result.Fields := TEn1545.Parse(AData, L);
  Result.Present := True;
  Result.HasExpiry := TEn1545.DateOf(Result.Fields, 'EnvApplicationValidityEnd',
    Result.Expiry);
  Result.HasBirthDate := TEn1545.DateOf(Result.Fields, 'HolderBirthDate',
    Result.BirthDate);
  if TEn1545.Find(Result.Fields, 'EnvCardSerial', V) and V.Valid then
  begin
    Digits := V.Text;
    if StringOfChar('0', Length(Digits)) <> Digits then
    begin
      Result.HasCardNumber := True;
      Result.CardNumber := UnicodeString(Digits);
      Result.CardNumberFormatted := UnicodeString(Copy(Digits, 1, 6) + ' / ' +
        Copy(Digits, 7, 12) + ' / ' + Copy(Digits, 19, 1));
    end;
  end;
  if TEn1545.Find(Result.Fields, 'HolderPostalCode', V) and (V.Raw <> 0) then
  begin
    Result.HasPostalCode := True;
    Result.PostalCode := Word(V.Raw);
  end;
  Result.Personalised := Result.HasBirthDate or Result.HasPostalCode;
end;

class function TMobibCodec.DecodeEvent(const AData: TBytes;
  const ARecordNumber: Byte; const ASourceFileId: Word;
  out AEvent: TMobibEvent): Boolean;
var
  E: TMobibEvent;
  L: TEn1545Layout;
  V: TEn1545Value;
  P: TEn1545Parsed;
  Has: Boolean;
begin
  E := Default (TMobibEvent);
  AEvent := E;
  Result := False;
  if (Length(AData) < 1) or (Length(AData) > 256) then
    Fail;
  E.RecordNumber := ARecordNumber;
  E.SourceFileId := ASourceFileId;
  E.Version := Byte(AData[0] shr 2);
  if E.Version <= 2 then
  begin
    if Length(AData) * 8 < 211 then
      Fail;
    E.LayoutKind := melLegacyFixed;
    L := TEn1545.Compile('MOBIB.Event.V0-2', LayoutSource, EventLegacyLayout);
  end
  else if E.Version = 3 then
  begin
    if Length(AData) * 8 < 62 then
      Fail;
    E.LayoutKind := melBitmap;
    L := TEn1545.Compile('MOBIB.Event.V3', LayoutSource, EventBitmapLayout);
  end
  else
  begin
    AEvent := E;
    Exit;
  end;
  P := TEn1545.Parse(AData, L);
  E.Fields := P;
  E.Complete := P.Complete;
  E.Date := DateValue(Bits(AData, 6, 14));
  E.Minutes := Word(Bits(AData, 20, 11));
  if E.Minutes > 1439 then
    Fail;
  E.HasFirstStamp := TEn1545.Find(P, 'EventFirstStampDate', V) and
    TEn1545.Find(P, 'EventFirstStampTime', V);
  if E.HasFirstStamp then
  begin
    E.FirstDate := DateValue(Cardinal(TEn1545.IntOr(P, 'EventFirstStampDate', 0)));
    E.FirstMinutes := Word(TEn1545.IntOr(P, 'EventFirstStampTime', 0));
    if E.FirstMinutes > 1439 then
      Fail;
  end;
  E.HasProvider := TEn1545.Find(P, 'EventServiceProvider', V);
  E.TransportCode := Byte(V.Raw);
  E.HasPassengerCount := TEn1545.Find(P, 'EventPassengerCount', V);
  E.PassengerCount := Byte(V.Raw);
  E.HasRoute := TEn1545.Find(P, 'EventRouteNumber', V);
  E.RouteNumber := Word(V.Raw);
  E.HasBusLocation := TEn1545.Find(P, 'EventLocationIdBus', V);
  E.BusLocationId := Word(V.Raw);
  E.HasStationLocation := TEn1545.Find(P, 'EventLocationId', V);
  E.StationLocationId := Cardinal(V.Raw);
  E.Zone := Byte(E.StationLocationId shr 11);
  E.SubZone := Byte((E.StationLocationId shr 7) and 15);
  E.Station := Byte(E.StationLocationId and 127);
  E.HasSerialNumber := TEn1545.Find(P, 'EventSerialNumber', V);
  E.SerialNumber := Cardinal(V.Raw);
  E.HasTransferNumber := TEn1545.Find(P, 'EventTransferNumber', V);
  E.TransferNumber := Cardinal(V.Raw);
  if E.LayoutKind = melLegacyFixed then
    E.CouponCount := Bits(AData, 139, 23);
  if E.HasProvider then
  begin
    Has := False;
    if E.TransportCode = 15 then
    begin
      Has := E.HasBusLocation;
      E.LocationId := E.BusLocationId;
      if E.HasRoute then
        E.BusRoute := Byte(E.RouteNumber and $7F);
    end
    else if (E.TransportCode = 0) or (E.TransportCode = 7) then
    begin
      Has := E.HasStationLocation;
      E.LocationId := E.StationLocationId;
    end;
    E.HasLocation := Has;
    if not Has then
      E.LocationId := 0;
  end;
  AEvent := E;
  Result := True;
end;

function CopyFile(const F: TCalypsoFile): TCalypsoFile;
var
  J: Integer;
begin
  Result := F;
  Result.SelectionData := CopyBytes(F.SelectionData);
  Result.Info.Raw := CopyBytes(F.Info.Raw);
  Result.Records := nil;
  SetLength(Result.Records, Length(F.Records));
  for J := 0 to High(F.Records) do
  begin
    Result.Records[J].Number := F.Records[J].Number;
    Result.Records[J].Data := CopyBytes(F.Records[J].Data);
  end;
end;

procedure AddCounter(var D: TMobibData; const ARecord, ASlot: Byte;
  const AValue: Cardinal; const ASource: Word);
var
  N: Integer;
begin
  N := Length(D.Counters);
  SetLength(D.Counters, N + 1);
  D.Counters[N].RecordNumber := ARecord;
  D.Counters[N].Slot := ASlot;
  D.Counters[N].Value := AValue;
  D.Counters[N].SourceFileId := ASource;
end;

procedure DecodeGeneric(const S: TMobibSnapshot; var D: TMobibData);
var
  B: TBytes;
  Days: Cardinal;
begin
  B := FolderRecord(S, $3F00, $0002, 1);
  if Length(B) >= 27 then
  begin
    D.Icc.Present := True;
    D.Icc.SerialHex := BytesToHex(Copy(B, 12, 8));
    D.Icc.CountryCode := BytesToHex(Copy(B, 20, 2));
    D.Icc.ManufacturerCode := B[22];
    D.Icc.ManufacturerName := TMobibCodec.ManufacturerName(B[22]);
    Days := (Cardinal(B[25]) shl 8) or B[26];
    D.Icc.HasManufactureDate := Days <> 0;
    if D.Icc.HasManufactureDate then
      D.Icc.ManufactureDate := EncodeDate(1990, 1, 1) + Days;
  end;
  B := FolderRecord(S, $1000, $1014, 1);
  if Length(B) >= 2 then
  begin
    Days := TMobibCodec.Bits(B, 2, 14);
    D.HasCardPurchaseDate := Days <> 0;
    if D.HasCardPurchaseDate then
      D.CardPurchaseDate := DateValue(Days);
  end;
end;

class function TMobibCodec.Decode(const ASnapshot: TMobibSnapshot;
  const ALayout: TMobibLayout): TMobibData;
const
  CounterFiles: array [0 .. 3] of Word = ($202A, $202B, $202C, $202D);
var
  I, J, K, N, Count, Y, M, Day: Integer;
  B, B2: TBytes;
  Birth: UnicodeString;
  E: TMobibEvent;
  HolderUsable: Boolean;
begin
  Result := Default (TMobibData);
  if (Ord(ALayout) < Ord(Low(TMobibLayout))) or
    (Ord(ALayout) > Ord(High(TMobibLayout))) then
    Fail;
  if (Length(ASnapshot.Files) > 160) or
    (Length(ASnapshot.TicketingSelection) > 4096) then
    Fail;
  for I := 0 to High(ASnapshot.Files) do
  begin
    if (Length(ASnapshot.Files[I].Records) > 255) or
      (Length(ASnapshot.Files[I].SelectionData) > 4096) then
      Fail;
    for J := 0 to High(ASnapshot.Files[I].Records) do
      if Length(ASnapshot.Files[I].Records[J].Data) > 256 then
        Fail;
  end;
  Result.Raw.TicketingSelection := CopyBytes(ASnapshot.TicketingSelection);
  Result.Raw.Application := ASnapshot.Application;
  Result.Raw.Application.Response := CopyBytes(ASnapshot.Application.Response);
  Result.Raw.Application.DfName := CopyBytes(ASnapshot.Application.DfName);
  Result.Raw.Application.SerialNumber :=
    CopyBytes(ASnapshot.Application.SerialNumber);
  Result.Raw.Application.StartupInfo :=
    CopyBytes(ASnapshot.Application.StartupInfo);
  SetLength(Result.Raw.Files, Length(ASnapshot.Files));
  for I := 0 to High(ASnapshot.Files) do
    Result.Raw.Files[I] := CopyFile(ASnapshot.Files[I]);
  if ALayout = mlRaw then
    Exit;
  DecodeGeneric(ASnapshot, Result);
  B := RecordData(ASnapshot, $2001, 1);
  if (Length(B) < 5) or Empty(B) then
    Exit;
  if (Bits(B, 6, 7) and 1) = 0 then
    Exit;
  Result.CountryCode := StrToInt(string(Bcd(B, 13, 3)));
  Result.NetworkCode := StrToInt(string(Bcd(B, 25, 3)));
  Result.HasNetwork := True;
  Result.LayoutMatched := (Result.CountryCode = 56) and
    (Result.NetworkCode = 1);
  if not Result.LayoutMatched then
    Exit;
  Result.Environment := DecodeEnvironment(B);
  B := RecordData(ASnapshot, $3F1C, 1);
  B2 := RecordData(ASnapshot, $3F1C, 2);
  if (Length(B) > 0) and (Length(B2) > 0) then
  begin
    if ((Length(B) <> 29) and (Length(B) <> 48)) or
      ((Length(B2) <> 29) and (Length(B2) <> 48)) then
      Fail;
    { 48-byte records are decoded only when their tail beyond the 29-byte payload is zero. }
    HolderUsable := Empty(Copy(B, 29, Length(B) - 29)) and
      Empty(Copy(B2, 29, Length(B2) - 29));
    if HolderUsable then
    begin
      B := Copy(B, 0, 29);
      SetLength(B, 58);
      for I := 0 to 28 do
        B[29 + I] := B2[I];
      if not Empty(B) then
      begin
        Result.Holder.Number := Bcd(B, 18, 19);
        Result.Holder.Name := Trim(Alpha(B, 205, 31));
        Result.Holder.GenderCode := Byte(Bits(B, 200, 2));
        Birth := Bcd(B, 168, 8);
        if Birth <> '00000000' then
        begin
          Y := StrToInt(string(Copy(Birth, 1, 4)));
          M := StrToInt(string(Copy(Birth, 5, 2)));
          Day := StrToInt(string(Copy(Birth, 7, 2)));
          if not TryEncodeDate(Y, M, Day, Result.Holder.BirthDate) then
            Fail;
          Result.Holder.HasBirthDate := True;
        end;
        Result.Holder.Present := True;
      end;
    end;
  end;
  B := RecordData(ASnapshot, $2050, 1);
  if Length(B) > 0 then
  begin
    Result.HasContractCount := True;
    Result.ContractCount := Byte(Bits(B, 0, 4));
    Result.ContractList.Present := True;
    Result.ContractList.Count := Result.ContractCount;
    Result.ContractList.Confidence := ecObserved;
    for I := 0 to Result.ContractCount - 1 do
      if 4 + (I + 1) * 28 <= Length(B) * 8 then
      begin
        N := Length(Result.ContractList.Entries);
        SetLength(Result.ContractList.Entries, N + 1);
        Result.ContractList.Entries[N] := Bits(B, 4 + I * 28, 28);
      end;
  end;
  for I := 0 to High(ASnapshot.Files) do
    if InFolder(ASnapshot.Files[I], $2000) then
      for J := 0 to High(ASnapshot.Files[I].Records) do
      begin
        B := ASnapshot.Files[I].Records[J].Data;
        if Empty(B) and (ASnapshot.Files[I].LogicalId <> $2069) then
          Continue;
        case ASnapshot.Files[I].LogicalId of
          $2010, $2040:
            if DecodeEvent(B, ASnapshot.Files[I].Records[J].Number,
              ASnapshot.Files[I].LogicalId, E) then
            begin
              if ASnapshot.Files[I].LogicalId = $2010 then
              begin
                N := Length(Result.Events);
                SetLength(Result.Events, N + 1);
                Result.Events[N] := E;
              end
              else
              begin
                N := Length(Result.SpecialEvents);
                SetLength(Result.SpecialEvents, N + 1);
                Result.SpecialEvents[N] := E;
              end;
            end
            else
              Inc(Result.UnsupportedEventCount);
          $2020:
            begin
              { The fixed purchase field belongs only to contract versions zero to three. }
              if Bits(B, 0, 6) > 3 then
                Continue;
              if Length(B) * 8 < 55 then
                Fail;
              N := Length(Result.Contracts);
              SetLength(Result.Contracts, N + 1);
              Result.Contracts[N].RecordNumber := ASnapshot.Files[I].Records
                [J].Number;
              Result.Contracts[N].PurchaseDate := DateValue(Bits(B, 41, 14));
            end;
          $2069:
            begin
              if Length(B) < 3 then
                Fail;
              Count := Length(B) div 3;
              if Count > 12 then
                Count := 12;
              for K := 0 to Count - 1 do
                AddCounter(Result, ASnapshot.Files[I].Records[J].Number,
                  Byte(K + 1), Bits(B, K * 24, 24), $2069);
            end;
        end;
      end;
  { Without file 2069, contracts one to four use the first counter of 202A..202D. }
  if not HasFile(ASnapshot, $2069) then
    for K := 0 to High(CounterFiles) do
    begin
      B := RecordData(ASnapshot, CounterFiles[K], 1);
      if Length(B) >= 3 then
        AddCounter(Result, 1, Byte(K + 1), Bits(B, 0, 24), CounterFiles[K]);
    end;
end;

end.
