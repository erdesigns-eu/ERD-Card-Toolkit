unit ERD.Card.MOBIB.Subscriptions;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.MOBIB.Data, ERD.Card.EN1545;

type
  /// <summary>Contract classification based on the documented MOBIB tariff counter-use bits.</summary>
  TMobibSubscriptionKind = (
    /// <summary>Unknown or unsupported contract layout; no rights inferred.</summary>
    mskUnknown,
    /// <summary>Supported non-time counter-use profile; a counter can represent remaining trips.</summary>
    mskTrips,
    /// <summary>Counter-use code four; time product whose counter is not a remaining-trip count.</summary>
    mskTime,
    /// <summary>Counter-use code zero with a stored end date: period pass (observed on cards, not published).</summary>
    mskPeriod);

  /// <summary>Duration unit of the version-four duration field.</summary>
  TMobibContractDurationUnit = (
    /// <summary>Unit code without a known meaning.</summary>
    mcdUnknown,
    /// <summary>Unit code 3: calendar months (observed: start plus value months equals the stored end date).</summary>
    mcdMonths);

  /// <summary>Date-based contract status at a caller-supplied moment.</summary>
  TMobibContractStatus = (
    /// <summary>No stored start or end date, or unsupported layout.</summary>
    mcsUnknown,
    /// <summary>The moment is before the stored start date.</summary>
    mcsNotYetValid,
    /// <summary>The moment is within the stored start and end dates (end date inclusive).</summary>
    mcsActive,
    /// <summary>The moment is after the stored end date.</summary>
    mcsExpired);

  /// <summary>Versioned MOBIB contract decoding; unknown fields and complete source bytes are preserved.</summary>
  TMobibSubscription = record
    /// <summary>Independent complete contract bytes for further issuer-specific interpretation.</summary>
    Raw: TBytes;
    /// <summary>Original absolute record number in file 2020.</summary>
    RecordNumber: Byte;
    /// <summary>Six-bit contract version, including unsupported versions.</summary>
    Version: Byte;
    /// <summary>True for decoded fixed versions zero to three and optional-field version four.</summary>
    LayoutMatched: Boolean;
    /// <summary>Fourteen-bit tariff code, meaningful only for a matched layout.</summary>
    Tariff: Word;
    /// <summary>Documented product label for four known codes; empty for all others.</summary>
    ProductName: string;
    /// <summary>Three-bit counter-use field extracted from tariff bits ten to twelve.</summary>
    CounterUse: Byte;
    /// <summary>Time versus trip interpretation for a matched profile.</summary>
    Kind: TMobibSubscriptionKind;
    /// <summary>Sixteen-bit contract price in euro cents; not a stored-value balance.</summary>
    PriceCents: Word;
    /// <summary>True when a nonzero sale-date field was present.</summary>
    HasSaleDate: Boolean;
    /// <summary>Sale date in civil days since 1997-01-01; not a validity-start date.</summary>
    SaleDate: TDateTime;
    /// <summary>True when version four's optional duration field was present, including a zero value.</summary>
    HasDuration: Boolean;
    /// <summary>Raw two-bit duration-unit code; no unsupported conversion to days or months.</summary>
    DurationUnitCode: Byte;
    /// <summary>Raw eight-bit duration amount; meaningful only when HasDuration is true.</summary>
    DurationValue: Byte;
    /// <summary>Five-bit version-four presence bitmap; zero for fixed legacy records.</summary>
    PresenceBitmap: Byte;
    /// <summary>True when an associated counter was acquired; not an authenticity statement.</summary>
    HasCounter: Boolean;
    /// <summary>Raw 24-bit counter associated with this absolute contract record.</summary>
    Counter: Cardinal;
    /// <summary>True only when a matched trip profile has its counter; zero remaining trips is valid.</summary>
    HasRemainingTrips: Boolean;
    /// <summary>Remaining-trip value; meaningful only when HasRemainingTrips is true.</summary>
    RemainingTrips: Cardinal;
    /// <summary>Number of interpreted bits; remaining bits are preserved in Raw.</summary>
    DecodedBits: Word;
    /// <summary>True when version four stores an end date (bit-inverted 14-bit date at bit 6; observed).</summary>
    HasEndDate: Boolean;
    /// <summary>Stored validity end date; meaningful only when HasEndDate is true.</summary>
    EndDate: TDateTime;
    /// <summary>True when a version-four sale date accompanies a stored end date and is used as validity start (observed).</summary>
    HasStartDate: Boolean;
    /// <summary>Validity start date (equals SaleDate); meaningful only when HasStartDate is true.</summary>
    StartDate: TDateTime;
    /// <summary>Interpretation of DurationUnitCode; mcdMonths is observed, not published.</summary>
    DurationUnit: TMobibContractDurationUnit;
    /// <summary>Confidence of Kind: published for trip/time kinds, observed for mskPeriod.</summary>
    KindConfidence: TEn1545Confidence;
    /// <summary>File that supplied the associated counter (2069 or 202A..202D); zero without counter.</summary>
    CounterSourceFileId: Word;
    /// <summary>Record number of an earlier byte-identical contract record; zero when unique.</summary>
    DuplicateOf: Byte;
    /// <summary>All parsed fields with positions and confidence, plus the unparsed remainder.</summary>
    Fields: TEn1545Parsed;
  end;

  /// <summary>Subscriptions in original nonempty file-2020 record order.</summary>
  TMobibSubscriptions = array of TMobibSubscription;

  /// <summary>Offline native MOBIB subscription decoder for explicitly matched network 056/001.</summary>
  TMobibSubscriptionCodec = class
  public
    /// <summary>Decodes one complete contract record without assuming issuer authorization or validity dates.</summary>
    /// <param name="AData">Complete nonempty contract record, 1..256 bytes.</param>
    /// <param name="ARecordNumber">Absolute record number, 1..255.</param>
    /// <param name="AHasCounter">Whether the caller acquired this contract's associated counter.</param>
    /// <param name="ACounter">Associated 24-bit value; zero is not treated as missing.</param>
    /// <returns>Owned source bytes and version-specific semantic fields; unsupported versions stay raw.</returns>
    class function Decode(const AData: TBytes; const ARecordNumber: Byte;
      const AHasCounter: Boolean; const ACounter: Cardinal)
      : TMobibSubscription; static;
    /// <summary>Decodes file 2020 after explicit legacy-network matching, associating counter record one by absolute slot.</summary>
    /// <param name="AData">Previously decoded matched MOBIB snapshot, retaining files and counters.</param>
    /// <returns>Available contracts; missing counters remain explicitly absent.</returns>
    /// <remarks>Does not use array positions as record numbers, nor infer activation, expiry, zones or issuer entitlement.</remarks>
    class function DecodeSnapshot(const AData: TMobibData)
      : TMobibSubscriptions; static;
    /// <summary>Compares the stored start and end dates with a caller-supplied moment.</summary>
    /// <param name="ASubscription">Decoded contract.</param>
    /// <param name="ANow">Moment to evaluate; never read from the system clock.</param>
    /// <returns>Status; mcsUnknown without stored dates. Not an issuer entitlement decision.</returns>
    class function StatusAt(const ASubscription: TMobibSubscription;
      const ANow: TDateTime): TMobibContractStatus; static;
  end;

implementation

uses ERD.Card.Contactless.Calypso;

procedure Fail;
begin
  raise EMobibDecodeError.Create('Invalid MOBIB subscription layout.');
end;

const
  ContractLegacyLayout = 'ContractVersion:int:6, ?ContractUnknownB:int:21,' +
    ' ContractTariff:int:14, ContractSale:date, ?ContractUnknownC:hex:48,' +
    ' ContractPriceAmount:int:16, ?ContractUnknownD:hex:113';
  ContractV4Layout = 'ContractVersion:int:6, ~ContractEnd:idate,' +
    ' ?ContractUnknownA:int:5, ContractTariff:int:14, ?ContractUnknownB:hex:50,' +
    ' ContractPriceAmount:int:16, ?ContractUnknownC:int:6,' +
    ' ContractBitmap:bitmap(?NeverSeen0:int:5, ?NeverSeen1:int:5, ContractSale:date,' +
    ' seq(ContractDurationUnits:int:2, ContractDuration:int:8), ?NeverSeen4:int:8),' +
    ' ?ContractUnknownD:int:24';
  LayoutSource = 'Metrodroid MOBIB contract layouts (facts only); end date observed';

class function TMobibSubscriptionCodec.Decode(const AData: TBytes;
  const ARecordNumber: Byte; const AHasCounter: Boolean;
  const ACounter: Cardinal): TMobibSubscription;
var
  L: TEn1545Layout;
  P: TEn1545Parsed;
  V: TEn1545Value;
  N: Integer;
begin
  Result := Default (TMobibSubscription);
  if (Length(AData) < 1) or (Length(AData) > 256) or (ARecordNumber = 0) or
    (ACounter > $FFFFFF) then
    Fail;
  Result.Raw := Copy(AData, 0, Length(AData));
  Result.RecordNumber := ARecordNumber;
  Result.Version := Byte(AData[0] shr 2);
  Result.HasCounter := AHasCounter;
  if AHasCounter then
    Result.Counter := ACounter;
  if Result.Version > 4 then
    Exit;
  if Result.Version <= 3 then
    L := TEn1545.Compile('MOBIB.Contract.V0-3', LayoutSource, ContractLegacyLayout)
  else
    L := TEn1545.Compile('MOBIB.Contract.V4', LayoutSource, ContractV4Layout);
  P := TEn1545.Parse(AData, L);
  if not P.Complete then
    Fail;
  Result.Fields := P;
  Result.Tariff := Word(TEn1545.IntOr(P, 'ContractTariff', 0));
  Result.PriceCents := Word(TEn1545.IntOr(P, 'ContractPriceAmount', 0));
  Result.PresenceBitmap := Byte(TEn1545.IntOr(P, 'ContractBitmap', 0));
  Result.HasSaleDate := TEn1545.DateOf(P, 'ContractSale', Result.SaleDate);
  Result.HasDuration := TEn1545.Find(P, 'ContractDurationUnits', V);
  if Result.HasDuration then
  begin
    Result.DurationUnitCode := Byte(V.Raw);
    Result.DurationValue := Byte(TEn1545.IntOr(P, 'ContractDuration', 0));
    if Result.DurationUnitCode = 3 then
      Result.DurationUnit := mcdMonths;
  end;
  Result.HasEndDate := TEn1545.DateOf(P, 'ContractEnd', Result.EndDate);
  Result.HasStartDate := Result.HasEndDate and Result.HasSaleDate;
  if Result.HasStartDate then
    Result.StartDate := Result.SaleDate;
  Result.DecodedBits := Word(P.RemainderOffset);
  Result.LayoutMatched := True;
  Result.CounterUse := Byte((Result.Tariff shr 10) and 7);
  Result.KindConfidence := ecPublished;
  if Result.CounterUse = 4 then
    Result.Kind := mskTime
  else if Result.CounterUse = 0 then
  begin
    if Result.HasEndDate then
      Result.Kind := mskPeriod
    else
      Result.Kind := mskUnknown;
    Result.KindConfidence := ecObserved;
  end
  else
    Result.Kind := mskTrips;
  Result.HasRemainingTrips := AHasCounter and (Result.Kind = mskTrips);
  if Result.HasRemainingTrips then
    Result.RemainingTrips := ACounter;
  N := Result.Tariff;
  case N of
    $2801:
      Result.ProductName := 'JUMP 1 trip';
    $2803:
      Result.ProductName := 'JUMP 10 trips';
    $0805:
      Result.ProductName := 'Airport bus';
    $303D:
      Result.ProductName := 'JUMP 24h including airport bus';
  end;
end;

class function TMobibSubscriptionCodec.DecodeSnapshot(const AData: TMobibData)
  : TMobibSubscriptions;
var
  I, J, K, N: Integer;
  B: TBytes;
  Has, Empty: Boolean;
  C: Cardinal;
  Source: Word;
  R: Byte;
  F: TCalypsoFile;
begin
  Result := nil;
  if not AData.LayoutMatched then
    Exit;
  for I := 0 to High(AData.Raw.Files) do
  begin
    F := AData.Raw.Files[I];
    if (F.LogicalId <> $2020) or F.BySfi or
      ((F.Folder <> 0) and (F.Folder <> $2000)) then
      Continue;
    for J := 0 to High(F.Records) do
    begin
      B := F.Records[J].Data;
      Empty := True;
      for K := 0 to High(B) do
        if B[K] <> 0 then
          Empty := False;
      if Empty then
        Continue;
      R := F.Records[J].Number;
      Has := False;
      C := 0;
      Source := 0;
      for K := 0 to High(AData.Counters) do
        if (AData.Counters[K].RecordNumber = 1) and
          (AData.Counters[K].Slot = R) then
        begin
          if Has then
            Fail;
          Has := True;
          C := AData.Counters[K].Value;
          Source := AData.Counters[K].SourceFileId;
        end;
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := Decode(B, R, Has, C);
      if Has then
        Result[N].CounterSourceFileId := Source;
      for K := 0 to N - 1 do
        if (Result[K].DuplicateOf = 0) and
          (Length(Result[K].Raw) = Length(B)) and
          CompareMem(@Result[K].Raw[0], @B[0], Length(B)) then
        begin
          Result[N].DuplicateOf := Result[K].RecordNumber;
          Break;
        end;
    end;
  end;
end;

class function TMobibSubscriptionCodec.StatusAt(const ASubscription
  : TMobibSubscription; const ANow: TDateTime): TMobibContractStatus;
var
  Day: TDateTime;
begin
  Result := mcsUnknown;
  if not ASubscription.LayoutMatched or not ASubscription.HasEndDate then
    Exit;
  Day := Int(ANow);
  if ASubscription.HasStartDate and (Day < Int(ASubscription.StartDate)) then
    Result := mcsNotYetValid
  else if Day > Int(ASubscription.EndDate) then
    Result := mcsExpired
  else
    Result := mcsActive;
end;

end.
