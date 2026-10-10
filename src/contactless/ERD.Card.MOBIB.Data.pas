unit ERD.Card.MOBIB.Data;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Contactless.Calypso;

type
  /// <summary>Explicit transit-data layout; matching is required before issuer-specific fields are decoded.</summary>
  TMobibLayout = (
    /// <summary>Preserve all files without interpreting issuer-specific fields.</summary>
    mlRaw,
    /// <summary>Published legacy MOBIB country 056/network 001 layout.</summary>
    mlLegacy056001);
  /// <summary>Invalid bit range, BCD, date or record layout; retains no personal input.</summary>
  EMobibDecodeError = class(Exception);

  /// <summary>Legacy extended holder record assembled from records one and two.</summary>
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

  /// <summary>One decoded legacy validation event, without station-name or fare inference.</summary>
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
  end;

  /// <summary>Decoded counter slots without guessing their contract association or fare units.</summary>
  TMobibCounters = array of TMobibCounter;

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
  end;

implementation

uses ERD.Card.Bytes;

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

function RecordData(const S: TMobibSnapshot; const Id: Word;
  const N: Byte): TBytes;
var
  I, J: Integer;
begin
  Result := nil;
  for I := 0 to High(S.Files) do
    if (S.Files[I].LogicalId = Id) and (S.Files[I].SelectionStatus = $9000) then
      for J := 0 to High(S.Files[I].Records) do
        if S.Files[I].Records[J].Number = N then
        begin
          if Length(Result) <> 0 then
            Fail;
          Result := S.Files[I].Records[J].Data;
        end;
end;

function DateValue(const Days: Cardinal): TDateTime;
begin
  Result := EncodeDate(1997, 1, 1) + Days;
end;

class function TMobibCodec.Decode(const ASnapshot: TMobibSnapshot;
  const ALayout: TMobibLayout): TMobibData;
var
  I, J, K, N, Count, Y, M, Day: Integer;
  B, B2: TBytes;
  Birth: UnicodeString;
  E: TMobibEvent;
begin
  Result := Default (TMobibData);
  if (Ord(ALayout) < Ord(Low(TMobibLayout))) or
    (Ord(ALayout) > Ord(High(TMobibLayout))) then
    Fail;
  if (Length(ASnapshot.Files) > 64) or
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
  SetLength(Result.Raw.Files, Length(ASnapshot.Files));
  for I := 0 to High(ASnapshot.Files) do
  begin
    Result.Raw.Files[I] := ASnapshot.Files[I];
    Result.Raw.Files[I].SelectionData :=
      CopyBytes(ASnapshot.Files[I].SelectionData);
    Result.Raw.Files[I].Records := nil;
    SetLength(Result.Raw.Files[I].Records, Length(ASnapshot.Files[I].Records));
    for J := 0 to High(ASnapshot.Files[I].Records) do
    begin
      Result.Raw.Files[I].Records[J].Number := ASnapshot.Files[I].Records
        [J].Number;
      Result.Raw.Files[I].Records[J].Data :=
        CopyBytes(ASnapshot.Files[I].Records[J].Data);
    end;
  end;
  if ALayout = mlRaw then
    Exit;
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
  B := RecordData(ASnapshot, $3F1C, 1);
  B2 := RecordData(ASnapshot, $3F1C, 2);
  if (Length(B) > 0) and (Length(B2) > 0) then
  begin
    if (Length(B) <> 29) or (Length(B2) <> 29) then
      Fail;
    Count := Length(B);
    if (Count > 256) or (Length(B2) > 256) then
      Fail;
    B := CopyBytes(B);
    SetLength(B, Count + Length(B2));
    for I := 0 to High(B2) do
      B[Count + I] := B2[I];
    if not Empty(B) then
    begin
      if Length(B) * 8 < 360 then
        Fail;
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
  B := RecordData(ASnapshot, $2050, 1);
  if Length(B) > 0 then
  begin
    Result.HasContractCount := True;
    Result.ContractCount := Byte(Bits(B, 0, 4));
  end;
  for I := 0 to High(ASnapshot.Files) do
    if ASnapshot.Files[I].SelectionStatus = $9000 then
      for J := 0 to High(ASnapshot.Files[I].Records) do
      begin
        B := ASnapshot.Files[I].Records[J].Data;
        if Empty(B) and (ASnapshot.Files[I].LogicalId <> $2069) then
          Continue;
        case ASnapshot.Files[I].LogicalId of
          $2010:
            begin
              if Length(B) * 8 < 211 then
                Fail;
              E := Default (TMobibEvent);
              E.RecordNumber := ASnapshot.Files[I].Records[J].Number;
              E.Date := DateValue(Bits(B, 6, 14));
              E.Minutes := Word(Bits(B, 20, 11));
              E.FirstDate := DateValue(Bits(B, 186, 14));
              E.FirstMinutes := Word(Bits(B, 200, 11));
              if (E.Minutes > 1439) or (E.FirstMinutes > 1439) then
                Fail;
              E.TransportCode := Byte(Bits(B, 99, 5));
              E.CouponCount := Bits(B, 139, 23);
              if E.TransportCode = 15 then
              begin
                E.HasLocation := True;
                E.LocationId := Bits(B, 71, 12);
                E.BusRoute := Byte(Bits(B, 92, 7));
              end
              else if (E.TransportCode = 0) or (E.TransportCode = 7) then
              begin
                E.HasLocation := True;
                E.LocationId := Bits(B, 104, 17);
              end;
              N := Length(Result.Events);
              SetLength(Result.Events, N + 1);
              Result.Events[N] := E;
            end;
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
              if Count > 9 then
                Count := 9;
              for K := 0 to Count - 1 do
              begin
                N := Length(Result.Counters);
                SetLength(Result.Counters, N + 1);
                Result.Counters[N].RecordNumber := ASnapshot.Files[I].Records
                  [J].Number;
                Result.Counters[N].Slot := Byte(K + 1);
                Result.Counters[N].Value := Bits(B, K * 24, 24);
              end;
            end;
        end;
      end;
end;

end.
