unit ERD.Card.MagStripe.Tracks;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Invalid track characters, framing, bit count, parity, LRC or financial fields.</summary>
  /// <remarks>Messages never include the supplied track contents.</remarks>
  EMagStripeFormatError = class(EConvertError);
  /// <summary>Physical track and its standard character encoding.</summary>
  TMagStripeTrack = (
    /// <summary>Six data bits plus odd parity; up to 76 payload characters.</summary>
    mstTrack1,
    /// <summary>Four data bits plus odd parity; up to 37 payload characters.</summary>
    mstTrack2,
    /// <summary>Four data bits plus odd parity; up to 104 payload characters.</summary>
    mstTrack3
  );
  /// <summary>Explicit physical tracks; no inference from sentinel order.</summary>
  TMagStripeTrackSet = set of TMagStripeTrack;
  /// <summary>Payloads without sentinels or LRC, indexed by physical track.</summary>
  /// <remarks>Empty string represents absent data in read results; selected empty writes are refused.</remarks>
  TMagStripeTracks = array[TMagStripeTrack] of string;
  /// <summary>Optional financial interpretation shared by Track 1 format B and Track 2.</summary>
  /// <remarks>Issuer discretionary data remains opaque; no PIN, CVV or PVV identification is implied.</remarks>
  TMagStripeFinancialData = record
    /// <summary>One through nineteen decimal digits; no Luhn or issuer validation.</summary>
    PAN: string;
    /// <summary>Track 1 name field, zero through twenty-six characters; empty for Track 2.</summary>
    Name: string;
    /// <summary>Four YYMM digits; MM 01..12, or exactly 0000 for unspecified expiry.</summary>
    ExpiryYYMM: string;
    /// <summary>Exactly three decimal service-code digits; semantics are not validated.</summary>
    ServiceCode: string;
    /// <summary>Opaque issuer-defined suffix within the selected track's character and capacity limits.</summary>
    DiscretionaryData: string;
  end;
  /// <summary>Pure bounded character and bit codecs; no device, F2F timing or automatic track detection.</summary>
  /// <remarks>Canonical five-bit text uses semicolon for both Track 2 and Track 3.
  /// Bit arrays contain one byte (0 or 1) per bit, data LSB first and odd parity last.
  /// Exactly one SS/payload/ES/LRC frame is accepted; clocking zeros and reverse captures
  /// must be removed or normalized by the caller. Text framing excludes LRC.</remarks>
  TMagStripeTrackCodec = class
  public
    /// <summary>Returns the maximum payload excluding SS, ES and LRC.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <returns>76, 37 or 104 characters.</returns>
    /// <exception cref="EMagStripeFormatError">Track value is invalid.</exception>
    class function MaxPayloadLength(const ATrack: TMagStripeTrack): Integer; static;
    /// <summary>Checks standard character range, reserved sentinels and maximum payload.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <param name="APayload">Unframed payload; empty is valid for the pure codec.</param>
    /// <exception cref="EMagStripeFormatError">Track, character or capacity is invalid.</exception>
    class procedure ValidatePayload(const ATrack: TMagStripeTrack; const APayload: string); static;
    /// <summary>Adds canonical SS and ES; does not append LRC to text.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <param name="APayload">Validated unframed payload.</param>
    /// <returns>Independent framed text; Track 3 uses semicolon.</returns>
    /// <exception cref="EMagStripeFormatError">Payload or track is invalid.</exception>
    class function Frame(const ATrack: TMagStripeTrack; const APayload: string): string; static;
    /// <summary>Checks exactly one canonical text frame and removes SS and ES.</summary>
    /// <param name="ATrack">Explicit physical track; no plus-sign normalization here.</param>
    /// <param name="AFrame">Complete SS/payload/ES text, excluding LRC and terminators.</param>
    /// <returns>Independent unframed payload.</returns>
    /// <exception cref="EMagStripeFormatError">Framing, payload or capacity is invalid.</exception>
    class function Unframe(const ATrack: TMagStripeTrack; const AFrame: string): string; static;
    /// <summary>Calculates the data-bit LRC from SS, payload and ES, then adds its own odd parity.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <param name="APayload">Unframed validated payload.</param>
    /// <returns>Seven-bit or five-bit LRC symbol, parity in its highest used bit.</returns>
    /// <exception cref="EMagStripeFormatError">Payload or track is invalid.</exception>
    class function LrcSymbol(const ATrack: TMagStripeTrack; const APayload: string): Byte; static;
    /// <summary>Encodes SS, payload, ES and LRC into one-byte-per-bit forward order.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <param name="APayload">Unframed validated payload; not retained.</param>
    /// <returns>Independent bits, excluding leading and trailing clocking zeros.</returns>
    /// <exception cref="EMagStripeFormatError">Payload or track is invalid.</exception>
    class function EncodeBits(const ATrack: TMagStripeTrack; const APayload: string): TBytes; static;
    /// <summary>Decodes a complete forward frame with per-character odd parity and data-column LRC.</summary>
    /// <param name="ATrack">Explicit physical track.</param>
    /// <param name="ABits">Exactly one bounded frame; each byte must be zero or one.</param>
    /// <returns>Unframed payload only after all framing and integrity checks pass.</returns>
    /// <exception cref="EMagStripeFormatError">Bits, framing, parity, LRC or payload is invalid.</exception>
    class function DecodeBits(const ATrack: TMagStripeTrack; const ABits: TBytes): string; static;
  end;
  /// <summary>Strict optional financial-field interpretation; raw nonfinancial tracks remain supported.</summary>
  TMagStripeFinancialCodec = class
  public
    /// <summary>Decodes unframed Track 1 format B into typed fields.</summary>
    /// <param name="APayload">B/PAN/name/YYMM/service/discretionary with exactly two caret separators.</param>
    /// <returns>Validated fields, preserving name spacing and opaque suffix.</returns>
    /// <exception cref="EMagStripeFormatError">Format, field sizes, digits or expiry is invalid.</exception>
    class function DecodeTrack1(const APayload: string): TMagStripeFinancialData; static;
    /// <summary>Decodes unframed Track 2 financial data.</summary>
    /// <param name="APayload">PAN=YYMM/service/discretionary with exactly one equals separator.</param>
    /// <returns>Validated fields; Name is empty.</returns>
    /// <exception cref="EMagStripeFormatError">Format, field sizes, digits or expiry is invalid.</exception>
    class function DecodeTrack2(const APayload: string): TMagStripeFinancialData; static;
    /// <summary>Builds a validated unframed Track 1 format B payload.</summary>
    /// <param name="AData">Typed fields; name and opaque suffix must not contain caret separators.</param>
    /// <returns>B-prefixed payload without SS, ES or LRC.</returns>
    /// <exception cref="EMagStripeFormatError">Fields or resulting capacity are invalid.</exception>
    class function EncodeTrack1(const AData: TMagStripeFinancialData): string; static;
    /// <summary>Builds a validated unframed Track 2 payload.</summary>
    /// <param name="AData">Typed fields; Name must be empty and discretionary suffix must be decimal.</param>
    /// <returns>Financial payload without SS, ES or LRC.</returns>
    /// <exception cref="EMagStripeFormatError">Fields or resulting capacity are invalid.</exception>
    class function EncodeTrack2(const AData: TMagStripeFinancialData): string; static;
  end;

implementation

procedure InvalidTrack;
begin
  raise EMagStripeFormatError.Create('Invalid magnetic stripe format.');
end;

class function TMagStripeTrackCodec.MaxPayloadLength(const ATrack: TMagStripeTrack): Integer;
begin
  case ATrack of
    mstTrack1: Result := 76;
    mstTrack2: Result := 37;
    mstTrack3: Result := 104;
  else
    InvalidTrack;
    Result := 0;
  end;
end;

function DataBits(const ATrack: TMagStripeTrack): Integer;
begin
  TMagStripeTrackCodec.MaxPayloadLength(ATrack);
  if ATrack = mstTrack1 then Result := 6 else Result := 4;
end;

function StartChar(const ATrack: TMagStripeTrack): Char;
begin
  if ATrack = mstTrack1 then Result := '%' else Result := ';';
end;

function CharData(const ATrack: TMagStripeTrack; const AChar: Char): Byte;
begin
  if ATrack = mstTrack1 then Result := Ord(AChar) - $20
  else Result := Ord(AChar) - $30;
end;

function OddSymbol(const AData: Byte; const ADataBits: Integer): Byte;
var
  I, Ones: Integer;
begin
  Ones := 0;
  for I := 0 to ADataBits - 1 do
    Inc(Ones, (AData shr I) and 1);
  Result := AData;
  if not Odd(Ones) then Result := Result or Byte(1 shl ADataBits);
end;

class procedure TMagStripeTrackCodec.ValidatePayload(const ATrack: TMagStripeTrack;
  const APayload: string);
var
  I, LowChar, HighChar: Integer;
begin
  if Length(APayload) > MaxPayloadLength(ATrack) then InvalidTrack;
  if ATrack = mstTrack1 then begin LowChar := $20; HighChar := $5F; end
  else begin LowChar := $30; HighChar := $3F; end;
  for I := 1 to Length(APayload) do
    if (Ord(APayload[I]) < LowChar) or (Ord(APayload[I]) > HighChar) or
      (APayload[I] = StartChar(ATrack)) or (APayload[I] = '?') then InvalidTrack;
end;

class function TMagStripeTrackCodec.Frame(const ATrack: TMagStripeTrack;
  const APayload: string): string;
begin
  ValidatePayload(ATrack, APayload);
  Result := StartChar(ATrack) + APayload + '?';
end;

class function TMagStripeTrackCodec.Unframe(const ATrack: TMagStripeTrack;
  const AFrame: string): string;
begin
  if (Length(AFrame) < 2) or (Length(AFrame) > MaxPayloadLength(ATrack) + 2) then InvalidTrack;
  if (AFrame[1] <> StartChar(ATrack)) or (AFrame[Length(AFrame)] <> '?') then InvalidTrack;
  Result := Copy(AFrame, 2, Length(AFrame) - 2);
  ValidatePayload(ATrack, Result);
end;

class function TMagStripeTrackCodec.LrcSymbol(const ATrack: TMagStripeTrack;
  const APayload: string): Byte;
var
  S: string;
  I: Integer;
  Lrc: Byte;
begin
  S := Frame(ATrack, APayload);
  Lrc := 0;
  for I := 1 to Length(S) do Lrc := Lrc xor CharData(ATrack, S[I]);
  Result := OddSymbol(Lrc, DataBits(ATrack));
end;

class function TMagStripeTrackCodec.EncodeBits(const ATrack: TMagStripeTrack;
  const APayload: string): TBytes;
var
  S: string;
  I, J, Width: Integer;
  Symbol: Byte;
begin
  Result := nil;
  S := Frame(ATrack, APayload);
  Width := DataBits(ATrack) + 1;
  SetLength(Result, (Length(S) + 1) * Width);
  for I := 0 to Length(S) do
  begin
    if I = Length(S) then Symbol := LrcSymbol(ATrack, APayload)
    else Symbol := OddSymbol(CharData(ATrack, S[I + 1]), Width - 1);
    for J := 0 to Width - 1 do Result[I * Width + J] := (Symbol shr J) and 1;
  end;
end;

class function TMagStripeTrackCodec.DecodeBits(const ATrack: TMagStripeTrack;
  const ABits: TBytes): string;
var
  I, J, Width, Count, Ones, Base: Integer;
  Symbol, Data, Lrc, Mask: Byte;
  S: string;
begin
  Width := DataBits(ATrack) + 1;
  if (Length(ABits) < Width * 3) or
    (Length(ABits) > (MaxPayloadLength(ATrack) + 3) * Width) or
    (Length(ABits) mod Width <> 0) then InvalidTrack;
  Count := Length(ABits) div Width;
  Mask := Byte((1 shl (Width - 1)) - 1);
  if ATrack = mstTrack1 then Base := $20 else Base := $30;
  Lrc := 0;
  SetLength(S, Count - 1);
  for I := 0 to Count - 1 do
  begin
    Symbol := 0;
    Ones := 0;
    for J := 0 to Width - 1 do
    begin
      if ABits[I * Width + J] > 1 then InvalidTrack;
      Inc(Ones, ABits[I * Width + J]);
      Symbol := Symbol or Byte(ABits[I * Width + J] shl J);
    end;
    if not Odd(Ones) then InvalidTrack;
    Data := Symbol and Mask;
    Lrc := Lrc xor Data;
    if I < Count - 1 then S[I + 1] := Char(Base + Data);
  end;
  if Lrc <> 0 then InvalidTrack;
  Result := Unframe(ATrack, S);
end;

procedure Digits(const S: string; const AMin, AMax: Integer);
var
  I: Integer;
begin
  if (Length(S) < AMin) or (Length(S) > AMax) then InvalidTrack;
  for I := 1 to Length(S) do if not CharInSet(S[I], ['0'..'9']) then InvalidTrack;
end;

procedure FinancialFields(const D: TMagStripeFinancialData);
var
  Month: Integer;
begin
  Digits(D.PAN, 1, 19);
  Digits(D.ExpiryYYMM, 4, 4);
  Digits(D.ServiceCode, 3, 3);
  Month := (Ord(D.ExpiryYYMM[3]) - Ord('0')) * 10 + Ord(D.ExpiryYYMM[4]) - Ord('0');
  if (D.ExpiryYYMM <> '0000') and ((Month < 1) or (Month > 12)) then InvalidTrack;
end;

class function TMagStripeFinancialCodec.DecodeTrack1(const APayload: string): TMagStripeFinancialData;
var
  P, Q, I: Integer;
  Tail: string;
begin
  TMagStripeTrackCodec.ValidatePayload(mstTrack1, APayload);
  if (Length(APayload) < 1) or (APayload[1] <> 'B') then InvalidTrack;
  P := Pos('^', APayload);
  Q := 0;
  for I := P + 1 to Length(APayload) do
    if APayload[I] = '^' then begin if Q <> 0 then InvalidTrack; Q := I; end;
  if (P < 3) or (Q <= P) then InvalidTrack;
  Result.PAN := Copy(APayload, 2, P - 2);
  Result.Name := Copy(APayload, P + 1, Q - P - 1);
  if Length(Result.Name) > 26 then InvalidTrack;
  Tail := Copy(APayload, Q + 1, Length(APayload) - Q);
  if Length(Tail) < 7 then InvalidTrack;
  Result.ExpiryYYMM := Copy(Tail, 1, 4);
  Result.ServiceCode := Copy(Tail, 5, 3);
  Result.DiscretionaryData := Copy(Tail, 8, Length(Tail) - 7);
  FinancialFields(Result);
end;

class function TMagStripeFinancialCodec.DecodeTrack2(const APayload: string): TMagStripeFinancialData;
var
  P: Integer;
  Tail: string;
begin
  TMagStripeTrackCodec.ValidatePayload(mstTrack2, APayload);
  P := Pos('=', APayload);
  if P < 2 then InvalidTrack;
  Result.PAN := Copy(APayload, 1, P - 1);
  Result.Name := '';
  Tail := Copy(APayload, P + 1, Length(APayload) - P);
  if Length(Tail) < 7 then InvalidTrack;
  Result.ExpiryYYMM := Copy(Tail, 1, 4);
  Result.ServiceCode := Copy(Tail, 5, 3);
  Result.DiscretionaryData := Copy(Tail, 8, Length(Tail) - 7);
  FinancialFields(Result);
  Digits(Result.DiscretionaryData, 0, 37);
end;

class function TMagStripeFinancialCodec.EncodeTrack1(const AData: TMagStripeFinancialData): string;
begin
  FinancialFields(AData);
  if Length(AData.Name) > 26 then InvalidTrack;
  if Length(AData.DiscretionaryData) > 76 - 10 - Length(AData.PAN) - Length(AData.Name) then InvalidTrack;
  if (Pos('^', AData.Name) <> 0) or (Pos('^', AData.DiscretionaryData) <> 0) then InvalidTrack;
  TMagStripeTrackCodec.ValidatePayload(mstTrack1, AData.Name);
  TMagStripeTrackCodec.ValidatePayload(mstTrack1, AData.DiscretionaryData);
  Result := 'B' + AData.PAN + '^' + AData.Name + '^' + AData.ExpiryYYMM +
    AData.ServiceCode + AData.DiscretionaryData;
end;

class function TMagStripeFinancialCodec.EncodeTrack2(const AData: TMagStripeFinancialData): string;
begin
  FinancialFields(AData);
  if AData.Name <> '' then InvalidTrack;
  Digits(AData.DiscretionaryData, 0, 37 - 8 - Length(AData.PAN));
  Result := AData.PAN + '=' + AData.ExpiryYYMM + AData.ServiceCode + AData.DiscretionaryData;
end;

end.
