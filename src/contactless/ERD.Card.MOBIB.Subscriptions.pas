unit ERD.Card.MOBIB.Subscriptions;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.MOBIB.Data;

type
  /// <summary>Contract classification based on the documented MOBIB tariff counter-use bits.</summary>
  TMobibSubscriptionKind = (
    /// <summary>Unknown or unsupported contract layout; no rights inferred.</summary>
    mskUnknown,
    /// <summary>Supported non-time counter-use profile; a counter can represent remaining trips.</summary>
    mskTrips,
    /// <summary>Counter-use code four; time product whose counter is not a remaining-trip count.</summary>
    mskTime);

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
  end;

implementation

procedure Fail;
begin
  raise EMobibDecodeError.Create('Invalid MOBIB subscription layout.');
end;

class function TMobibSubscriptionCodec.Decode(const AData: TBytes;
  const ARecordNumber: Byte; const AHasCounter: Boolean;
  const ACounter: Cardinal): TMobibSubscription;
var
  Offset, I, N: Integer;
  Days: Cardinal;
  function Read(const Count: Integer): Cardinal;
  begin
    Result := TMobibCodec.Bits(AData, Offset, Count);
    Inc(Offset, Count);
  end;
  procedure Skip(const Count: Integer);
  begin
    if Int64(Offset) + Count > Int64(Length(AData)) * 8 then
      Fail;
    Inc(Offset, Count);
  end;
  procedure Sale;
  begin
    Days := Read(14);
    Result.HasSaleDate := Days <> 0;
    if Result.HasSaleDate then
      Result.SaleDate := EncodeDate(1997, 1, 1) + Days;
  end;

begin
  Result := Default (TMobibSubscription);
  if (Length(AData) < 1) or (Length(AData) > 256) or (ARecordNumber = 0) or
    (ACounter > $FFFFFF) then
    Fail;
  Result.Raw := Copy(AData, 0, Length(AData));
  Result.RecordNumber := ARecordNumber;
  Offset := 0;
  Result.Version := Byte(Read(6));
  Result.HasCounter := AHasCounter;
  if AHasCounter then
    Result.Counter := ACounter;
  if Result.Version > 4 then
    Exit;
  if Result.Version <= 3 then
  begin
    Skip(21);
    Result.Tariff := Word(Read(14));
    Sale;
    Skip(48);
    Result.PriceCents := Word(Read(16));
    Skip(113);
  end
  else
  begin
    Skip(19);
    Result.Tariff := Word(Read(14));
    Skip(50);
    Result.PriceCents := Word(Read(16));
    Skip(6);
    Result.PresenceBitmap := Byte(Read(5));
    for I := 0 to 4 do
      if (Result.PresenceBitmap and (1 shl I)) <> 0 then
        case I of
          0, 1:
            Skip(5);
          2:
            Sale;
          3:
            begin
              Result.HasDuration := True;
              Result.DurationUnitCode := Byte(Read(2));
              Result.DurationValue := Byte(Read(8));
            end;
          4:
            Skip(8);
        end;
    Skip(24);
  end;
  Result.DecodedBits := Word(Offset);
  Result.LayoutMatched := True;
  Result.CounterUse := Byte((Result.Tariff shr 10) and 7);
  if Result.CounterUse = 4 then
    Result.Kind := mskTime
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
  R: Byte;
begin
  Result := nil;
  if not AData.LayoutMatched then
    Exit;
  for I := 0 to High(AData.Raw.Files) do
    if AData.Raw.Files[I].LogicalId = $2020 then
      for J := 0 to High(AData.Raw.Files[I].Records) do
      begin
        B := AData.Raw.Files[I].Records[J].Data;
        Empty := True;
        for K := 0 to High(B) do
          if B[K] <> 0 then
            Empty := False;
        if Empty then
          Continue;
        R := AData.Raw.Files[I].Records[J].Number;
        Has := False;
        C := 0;
        for K := 0 to High(AData.Counters) do
          if (AData.Counters[K].RecordNumber = 1) and
            (AData.Counters[K].Slot = R) then
          begin
            if Has then
              Fail;
            Has := True;
            C := AData.Counters[K].Value;
          end;
        N := Length(Result);
        SetLength(Result, N + 1);
        Result[N] := Decode(B, R, Has, C);
      end;
end;

end.
