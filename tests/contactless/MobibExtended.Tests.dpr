program MobibExtendedTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Contactless.Calypso, ERD.Card.EN1545, ERD.Card.MOBIB.Data,
  ERD.Card.MOBIB.Subscriptions;

{ Synthetic fixtures copy the structure of observed MOBIB cards, never personal values. }

var
  Checks: Integer;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then
    raise Exception.Create('MOBIB extended regression: ' + AMessage);
end;

procedure Put(var B: TBytes; const Offset, Count: Integer; const V: UInt64);
var
  I, P: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    P := Offset + I;
    if (V and (UInt64(1) shl (Count - I - 1))) <> 0 then
      B[P div 8] := B[P div 8] or (1 shl (7 - P mod 8))
    else
      B[P div 8] := B[P div 8] and not (1 shl (7 - P mod 8));
  end;
end;

procedure PutBcd(var B: TBytes; const Offset: Integer; const Digits: string);
var
  I: Integer;
begin
  for I := 1 to Length(Digits) do
    Put(B, Offset + (I - 1) * 4, 4, Ord(Digits[I]) - Ord('0'));
end;

function Zero(const ACount: Integer): TBytes;
begin
  Result := nil;
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount, 0);
end;

function Days(const Y, M, D: Word): Cardinal;
begin
  Result := Cardinal(Trunc(EncodeDate(Y, M, D) - EncodeDate(1997, 1, 1)));
end;

function Environment(const AVersion: Byte; const APersonal: Boolean): TBytes;
var
  ExpiryAt: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, AVersion);
  Put(Result, 6, 7, 1);
  PutBcd(Result, 13, '056001');
  if AVersion <= 2 then
    ExpiryAt := 46
  else
    ExpiryAt := 42;
  Put(Result, ExpiryAt, 14, Days(2031, 3, 15));
  PutBcd(Result, 98, '1234567890123456789');
  if APersonal then
  begin
    PutBcd(Result, 66, '19800229');
    Put(Result, 179, 14, 1000);
  end;
end;

procedure AddFile(var S: TMobibSnapshot; const AFolder, AId: Word;
  const AStatus: Word; const ARecords: array of TBytes);
var
  N, I: Integer;
begin
  N := Length(S.Files);
  SetLength(S.Files, N + 1);
  S.Files[N] := Default (TCalypsoFile);
  S.Files[N].Folder := AFolder;
  S.Files[N].LogicalId := AId;
  S.Files[N].SelectionStatus := AStatus;
  SetLength(S.Files[N].Records, Length(ARecords));
  for I := 0 to High(ARecords) do
  begin
    S.Files[N].Records[I].Number := I + 1;
    S.Files[N].Records[I].Data := ARecords[I];
  end;
end;

function BitmapEvent(const AVersion: Byte; const AProvider: Byte;
  const ALocation: Cardinal): TBytes;
var
  O: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, AVersion);
  Put(Result, 6, 14, Days(2025, 6, 1));
  Put(Result, 20, 11, 17 * 60 + 5);
  O := 62;
  Put(Result, O, 5, 1 or 2 or 16);
  Inc(O, 5);
  Put(Result, O + 4, 12, 345);
  Inc(O, 16);
  Put(Result, O, 16, 1234);
  Inc(O, 16);
  Put(Result, O, 5, AProvider);
  Put(Result, O + 5, 17, ALocation);
  Inc(O, 32);
  Put(Result, O, 6, 1 or 4 or 16);
  Inc(O, 6);
  Put(Result, O, 24, 77);
  Inc(O, 24);
  Put(Result, O, 8, 2);
  Inc(O, 8);
  Put(Result, O, 14, Days(2025, 6, 1));
  Put(Result, O + 14, 11, 16 * 60 + 55);
end;

function ContractV4(const ATariff: Word; const AStart, AEnd: TDateTime): TBytes;
var
  O: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, 4);
  Put(Result, 6, 14, $3FFF - Cardinal(Trunc(AEnd - EncodeDate(1997, 1, 1))));
  Put(Result, 25, 14, ATariff);
  Put(Result, 89, 16, 6200);
  Put(Result, 111, 5, 4 or 8);
  O := 116;
  Put(Result, O, 14, Cardinal(Trunc(AStart - EncodeDate(1997, 1, 1))));
  Inc(O, 14);
  Put(Result, O, 2, 3);
  Put(Result, O + 2, 8, 1);
end;

procedure EnvironmentTests;
var
  E: TMobibEnvironment;
  V: TEn1545Value;
begin
  E := TMobibCodec.DecodeEnvironment(Environment(3, True));
  Check(E.Present and (E.Version = 3), 'Version-three environment');
  Check(E.HasExpiry and (E.Expiry = EncodeDate(2031, 3, 15)), 'Version-three expiry offset');
  Check(E.HasCardNumber and (E.CardNumber = '1234567890123456789') and
    (E.CardNumberFormatted = '123456 / 7890 1234 5678 9'), 'Card number grouped as printed');
  Check(E.HasBirthDate and (E.BirthDate = EncodeDate(1980, 2, 29)), 'BCD birth date');
  Check(E.HasPostalCode and (E.PostalCode = 1000) and E.Personalised, 'Postal code and personalised');
  Check(TEn1545.Find(E.Fields, 'EnvNetworkId', V) and (V.Text = '056001'), 'Network field');
  Check(TEn1545.Find(E.Fields, 'EnvUnknownB', V) and (V.BitWidth = 5) and
    (V.Confidence = ecUnknown), 'Unknown fields carry their confidence');
  E := TMobibCodec.DecodeEnvironment(Environment(1, False));
  Check(E.Present and E.HasExpiry and (E.Expiry = EncodeDate(2031, 3, 15)), 'Legacy expiry offset');
  Check(not E.HasBirthDate and not E.HasPostalCode and not E.Personalised, 'Anonymous card');
  E := TMobibCodec.DecodeEnvironment(Environment(5, True));
  Check(not E.Present and (E.Version = 5) and (Length(E.Fields.Values) = 0), 'Unsupported version stays raw');
end;

procedure EventTests;
var
  E: TMobibEvent;
  B: TBytes;
begin
  Check(TMobibCodec.DecodeEvent(BitmapEvent(3, 0, (7 shl 11) or (3 shl 7) or 45), 2, $2010, E),
    'Bitmap event decoded');
  Check((E.LayoutKind = melBitmap) and E.Complete and (E.SourceFileId = $2010) and
    (E.RecordNumber = 2), 'Bitmap layout metadata');
  Check((E.Date = EncodeDate(2025, 6, 1)) and (E.Minutes = 17 * 60 + 5), 'Bitmap date and time');
  Check(E.HasBusLocation and (E.BusLocationId = 345) and E.HasRoute and (E.RouteNumber = 1234),
    'Bitmap bus location and route');
  Check(E.HasProvider and (E.TransportCode = 0) and E.HasStationLocation and
    (E.Zone = 7) and (E.SubZone = 3) and (E.Station = 45), 'Station zone split');
  Check(E.HasLocation and (E.LocationId = E.StationLocationId), 'Metro uses station location');
  Check(E.HasSerialNumber and (E.SerialNumber = 77) and E.HasTransferNumber and
    (E.TransferNumber = 2), 'Serial and transfer');
  Check(E.HasFirstStamp and (E.FirstDate = EncodeDate(2025, 6, 1)) and
    (E.FirstMinutes = 16 * 60 + 55), 'First stamp');
  Check(not E.HasPassengerCount and (E.CouponCount = 0), 'No legacy-only fields');
  Check(TMobibCodec.DecodeEvent(BitmapEvent(3, 15, 0), 1, $2040, E) and E.HasLocation and
    (E.LocationId = 345) and (E.BusRoute = 1234 and $7F), 'Bus event location');
  Check(not TMobibCodec.DecodeEvent(BitmapEvent(4, 0, 0), 1, $2010, E) and
    (E.LayoutKind = melUnsupported) and (E.Version = 4), 'Unsupported event version');
  B := Zero(29);
  Put(B, 0, 6, 1);
  Put(B, 52, 5, 2);
  Put(B, 83, 16, 300);
  Put(B, 99, 5, 15);
  Put(B, 71, 12, 99);
  Check(TMobibCodec.DecodeEvent(B, 1, $2010, E) and (E.LayoutKind = melLegacyFixed) and
    E.HasPassengerCount and (E.PassengerCount = 2) and (E.RouteNumber = 300) and
    (E.BusRoute = 300 and $7F) and (E.LocationId = 99), 'Legacy event extra fields');
  B := BitmapEvent(3, 0, 0);
  Put(B, 20, 11, 1500);
  try
    TMobibCodec.DecodeEvent(B, 1, $2010, E);
    Check(False, 'Invalid minutes accepted');
  except
    on EMobibDecodeError do
      Check(True, 'Invalid minutes rejected');
  end;
end;

procedure SnapshotTests;
var
  S: TMobibSnapshot;
  D: TMobibData;
  A: TMobibSubscriptions;
  Holder1, Holder2, Icc, Log, List, C36: TBytes;
  I: Integer;
begin
  S := Default (TMobibSnapshot);
  AddFile(S, 0, $2001, $9000, [Environment(3, False)]);
  AddFile(S, 0, $2010, $9000, [BitmapEvent(3, 15, 0), Zero(29), BitmapEvent(9, 0, 0)]);
  AddFile(S, $2000, $2040, $9000, [BitmapEvent(3, 0, 1)]);
  AddFile(S, 0, $2020, $9000, [ContractV4($000F, EncodeDate(2025, 7, 12), EncodeDate(2025, 8, 12)),
    ContractV4($000F, EncodeDate(2025, 1, 12), EncodeDate(2025, 2, 12)),
    ContractV4($000F, EncodeDate(2025, 1, 12), EncodeDate(2025, 2, 12))]);
  AddFile(S, 0, $2069, $6A82, []);
  AddFile(S, 0, $202A, $9000, [Zero(29)]);
  Put(S.Files[High(S.Files)].Records[0].Data, 0, 24, 5);
  AddFile(S, 0, $202B, $9000, [Zero(29)]);
  Holder1 := Zero(48);
  Holder2 := Zero(48);
  PutBcd(Holder1, 18, '0000000000000000042');
  AddFile(S, 0, $3F1C, $9000, [Holder1, Holder2]);
  List := Zero(29);
  Put(List, 0, 4, 3);
  Put(List, 4, 28, 11);
  Put(List, 32, 28, 12);
  Put(List, 60, 28, 13);
  AddFile(S, 0, $2050, $9000, [List]);
  Icc := Zero(29);
  Icc[12] := $AB; Icc[19] := $CD; Icc[20] := $00; Icc[21] := $56; Icc[22] := $04;
  Icc[25] := $2A; Icc[26] := $00;
  AddFile(S, $3F00, $0002, $9000, [Icc]);
  AddFile(S, 0, $0002, $9000, [Zero(29)]);
  Log := Zero(29);
  Put(Log, 2, 14, Days(2019, 9, 2));
  AddFile(S, $1000, $1014, $9000, [Log]);
  S.Files[0].Info.Raw := Zero(3);
  S.Application.SerialNumber := Zero(8);
  D := TMobibCodec.Decode(S, mlLegacy056001);
  Check(D.LayoutMatched and D.Environment.Present and not D.Environment.Personalised,
    'Environment decoded in snapshot');
  Check((Length(D.Events) = 1) and (D.Events[0].TransportCode = 15) and
    (D.UnsupportedEventCount = 1), 'Validation events and unsupported count');
  Check((Length(D.SpecialEvents) = 1) and (D.SpecialEvents[0].SourceFileId = $2040),
    'Special events kept separately');
  Check((Length(D.Counters) = 2) and (D.Counters[0].Slot = 1) and (D.Counters[0].Value = 5) and
    (D.Counters[0].SourceFileId = $202A) and (D.Counters[1].SourceFileId = $202B),
    'Counter fallback to 202A..202D');
  Check(D.Holder.Present and (D.Holder.Number = '0000000000000000042'), 'Zero-padded 48-byte holder');
  Check(D.ContractList.Present and (D.ContractList.Count = 3) and
    (Length(D.ContractList.Entries) = 3) and (D.ContractList.Entries[2] = 13) and
    (D.ContractList.Confidence = ecObserved), 'Contract-list candidate split');
  Check(D.Icc.Present and (Copy(D.Icc.SerialHex, 1, 2) = 'AB') and (D.Icc.CountryCode = '0056') and
    (D.Icc.ManufacturerName = 'Thales') and D.Icc.HasManufactureDate and
    (D.Icc.ManufactureDate = EncodeDate(1990, 1, 1) + $2A00), 'ICC from MF folder only');
  Check(D.HasCardPurchaseDate and (D.CardPurchaseDate = EncodeDate(2019, 9, 2)), 'Load-log purchase date');
  S.Files[0].Info.Raw[0] := $FF;
  S.Application.SerialNumber[0] := $FF;
  Check((D.Raw.Files[0].Info.Raw[0] = 0) and (D.Raw.Application.SerialNumber[0] = 0),
    'File info and application bytes are deep copies');
  A := TMobibSubscriptionCodec.DecodeSnapshot(D);
  Check(Length(A) = 3, 'Three contract records');
  Check((A[0].Kind = mskPeriod) and (A[0].KindConfidence = ecObserved) and
    not A[0].HasRemainingTrips, 'Counter-use zero with end date is a period pass');
  Check(A[0].HasEndDate and (A[0].EndDate = EncodeDate(2025, 8, 12)) and A[0].HasStartDate and
    (A[0].StartDate = EncodeDate(2025, 7, 12)), 'Inverted end date and start date');
  Check(A[0].HasDuration and (A[0].DurationUnit = mcdMonths) and (A[0].DurationValue = 1), 'Observed month unit');
  Check(A[0].HasCounter and (A[0].Counter = 5) and (A[0].CounterSourceFileId = $202A), 'Counter source');
  Check((A[1].DuplicateOf = 0) and (A[2].DuplicateOf = 2), 'Duplicate contract flagged');
  Check(TMobibSubscriptionCodec.StatusAt(A[0], EncodeDate(2025, 7, 11) + 0.9) = mcsNotYetValid, 'Before start');
  Check(TMobibSubscriptionCodec.StatusAt(A[0], EncodeDate(2025, 7, 12)) = mcsActive, 'Start inclusive');
  Check(TMobibSubscriptionCodec.StatusAt(A[0], EncodeDate(2025, 8, 12) + 0.99) = mcsActive, 'End inclusive');
  Check(TMobibSubscriptionCodec.StatusAt(A[0], EncodeDate(2025, 8, 13)) = mcsExpired, 'Expired');
  A[0].HasEndDate := False;
  Check(TMobibSubscriptionCodec.StatusAt(A[0], EncodeDate(2025, 7, 20)) = mcsUnknown, 'No end date');
  { A selected 2069 suppresses the fallback and yields twelve slots from 36 bytes. }
  C36 := Zero(36);
  Put(C36, 11 * 24, 24, 9);
  S.Files[4].SelectionStatus := $9000;
  SetLength(S.Files[4].Records, 1);
  S.Files[4].Records[0].Number := 1;
  S.Files[4].Records[0].Data := C36;
  D := TMobibCodec.Decode(S, mlLegacy056001);
  Check((Length(D.Counters) = 12) and (D.Counters[11].Value = 9) and
    (D.Counters[0].SourceFileId = $2069), 'Twelve 2069 slots, no fallback');
  { A 48-byte holder with data beyond the 29-byte payload is not decoded. }
  for I := 0 to High(S.Files) do
    if S.Files[I].LogicalId = $3F1C then
      S.Files[I].Records[1].Data[40] := 1;
  D := TMobibCodec.Decode(S, mlLegacy056001);
  Check(not D.Holder.Present, 'Unknown 48-byte holder layout stays raw');
  D := TMobibCodec.Decode(S, mlRaw);
  Check(not D.Icc.Present and not D.Environment.Present and (Length(D.SpecialEvents) = 0),
    'Raw mode decodes nothing');
end;

{ Real De Lijn MOBIB rows (contracts 2020, special events 2040, contract list 2050), used with the
  card holder's permission. They contain no name, birth date, postal code or card number; the
  environment record of that card is deliberately not included. }
const
  DeLijnContracts: array [0 .. 7] of string = (
    '115C01801E783E8004A3710C1C02CA88301200F400000000007C9F2E9F00000000000000000000000000000000000000',
    '116751801E783F0002CDB38C1C02CA5AF01200F400000000007CEAC64600000000000000000000000000000000000000',
    '116751801E783F0002CDB38C1C02CA5AF01200F400000000007CEAC64600000000000000000000000000000000000000',
    '116591801E783E800318C18C1C02CA62B01200F400000000007C59354500000000000000000000000000000000000000',
    '1163A1801E783E8003632F8C1C02CA69B01200F400000000007C600E3200000000000000000000000000000000000000',
    '1161C1801E783F0003AD348C1C02CA71701200F400000000007C93869800000000000000000000000000000000000000',
    '115FD1801E783F0003F5F70C1C02CA78F01200F400000000007C9BE55F00000000000000000000000000000000000000',
    '115DF1801E783F00043FB10C1C02CA80B01200F400000000007CC660E300000000000000000000000000000000000000');
  DeLijnSpecialEvents: array [0 .. 3] of string = (
    '0E9E27CE063410166106A0FAE00137046A80000D0053C4F9C00000000000000000000000000000000000000000000000',
    '0EA0080A0634101A6106A0FAE00134FD6A80000880540101400000000000000000000000000000000000000000000000',
    '0EA1C7C60634101E6106A0FE600136608A80000B005438F8C00000000000000000000000000000000000000000000000',
    '0EA3E7E8063410226106A0FE6001348FAA80000B80547CFD000000000000000000000000000000000000000000000000');
  DeLijnContractList =
    '823EF4D393E74D3A3EF4E333EF4F243EF501D3EF510E3EF520738F52F800000000000000000000000000000000000000';

procedure DeLijnVectorTests;
const
  StartMonths: array [0 .. 7] of Word = (7, 1, 1, 2, 3, 4, 5, 6);
  EventDays: array [0 .. 3] of Word = (11, 10, 8, 11);
  EventMonths: array [0 .. 3] of Word = (5, 6, 7, 8);
  EventMinutes: array [0 .. 3] of Word = (999, 1029, 995, 1012);
  EventRoutes: array [0 .. 3] of Word = (2007, 2007, 2035, 2035);
  EventStations: array [0 .. 3] of Byte = (110, 105, 108, 105);
var
  S: TMobibSnapshot;
  D: TMobibData;
  Subs: TMobibSubscriptions;
  R: array of TBytes;
  I: Integer;
  E: TMobibEvent;
begin
  S := Default (TMobibSnapshot);
  AddFile(S, 0, $2001, $9000, [Environment(3, False)]);
  SetLength(R, Length(DeLijnContracts));
  for I := 0 to High(DeLijnContracts) do
    R[I] := HexToBytes(DeLijnContracts[I]);
  AddFile(S, 0, $2020, $9000, R);
  SetLength(R, Length(DeLijnSpecialEvents));
  for I := 0 to High(DeLijnSpecialEvents) do
    R[I] := HexToBytes(DeLijnSpecialEvents[I]);
  AddFile(S, 0, $2040, $9000, R);
  AddFile(S, 0, $2050, $9000, [HexToBytes(DeLijnContractList)]);
  D := TMobibCodec.Decode(S, mlLegacy056001);
  Subs := TMobibSubscriptionCodec.DecodeSnapshot(D);
  Check(Length(Subs) = 8, 'De Lijn: eight contracts');
  for I := 0 to High(Subs) do
  begin
    Check(Subs[I].LayoutMatched and (Subs[I].Version = 4) and (Subs[I].Tariff = $000F) and
      (Subs[I].PriceCents = 6200) and (Subs[I].CounterUse = 0), 'De Lijn contract header ' + IntToStr(I + 1));
    Check((Subs[I].Kind = mskPeriod) and (Subs[I].DurationUnit = mcdMonths) and
      (Subs[I].DurationValue = 1), 'De Lijn monthly period pass ' + IntToStr(I + 1));
    Check(Subs[I].HasStartDate and (Subs[I].StartDate = EncodeDate(2026, StartMonths[I], 12)) and
      Subs[I].HasEndDate and (Subs[I].EndDate = IncMonth(Subs[I].StartDate, 1)),
      'De Lijn start and inverted end date ' + IntToStr(I + 1));
  end;
  Check((Subs[2].DuplicateOf = 2) and (Subs[1].DuplicateOf = 0) and (Subs[0].DuplicateOf = 0),
    'De Lijn duplicate record 3 flagged');
  Check(TMobibSubscriptionCodec.StatusAt(Subs[0], EncodeDate(2026, 7, 20)) = mcsActive,
    'De Lijn newest contract active in July');
  Check(TMobibSubscriptionCodec.StatusAt(Subs[1], EncodeDate(2026, 7, 20)) = mcsExpired,
    'De Lijn January contract expired');
  Check((Length(D.SpecialEvents) = 4) and (D.UnsupportedEventCount = 0), 'De Lijn special events');
  for I := 0 to High(D.SpecialEvents) do
  begin
    E := D.SpecialEvents[I];
    Check((E.Version = 3) and (E.LayoutKind = melBitmap) and E.Complete and (E.SourceFileId = $2040),
      'De Lijn special event layout ' + IntToStr(I + 1));
    Check((E.Date = EncodeDate(2026, EventMonths[I], EventDays[I])) and (E.Minutes = EventMinutes[I]) and
      (E.FirstDate = E.Date) and (E.FirstMinutes = E.Minutes), 'De Lijn special event time ' + IntToStr(I + 1));
    Check(E.HasRoute and (E.RouteNumber = EventRoutes[I]) and (E.Zone = 0) and (E.SubZone = 4) and
      (E.Station = EventStations[I]) and (E.TransferNumber = 0),
      'De Lijn special event location ' + IntToStr(I + 1));
  end;
  Check(D.ContractList.Present and (D.ContractList.Count = 8) and (Length(D.ContractList.Entries) = 8) and
    (D.ContractList.Confidence = ecObserved), 'De Lijn contract list candidate split');
end;

begin
  try
    EnvironmentTests;
    EventTests;
    SnapshotTests;
    DeLijnVectorTests;
    Writeln('MOBIB extended: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
