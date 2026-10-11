unit ERD.Card.EN1545;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF};

type
  /// <summary>Invalid layout definition or field request; retains no record data.</summary>
  EEn1545Error = class(Exception);

  /// <summary>Evidence level of a field definition.</summary>
  TEn1545Confidence = (
    /// <summary>Layout documented by a public source (specification or open-source decoder).</summary>
    ecPublished,
    /// <summary>Meaning inferred from observed cards only; not confirmed by a public source.</summary>
    ecObserved,
    /// <summary>Position known, meaning unknown.</summary>
    ecUnknown);

  /// <summary>Primitive EN1545 field encodings.</summary>
  TEn1545FieldType = (
    /// <summary>Unsigned MSB-first integer, 0..64 bits.</summary>
    eftInteger,
    /// <summary>Raw bits shown as hexadecimal, any width.</summary>
    eftHex,
    /// <summary>Days since 1997-01-01; zero means absent.</summary>
    eftDate,
    /// <summary>Bit-inverted days since 1997-01-01 (all-ones means absent).</summary>
    eftInvertedDate,
    /// <summary>Minutes since midnight, 0..1439.</summary>
    eftTime,
    /// <summary>Seconds since 1997-01-01 00:00; zero means absent.</summary>
    eftDateTime,
    /// <summary>Binary-coded decimal digits; width is a multiple of four.</summary>
    eftBcd,
    /// <summary>Eight BCD digits YYYYMMDD; all zero means absent.</summary>
    eftBcdDate,
    /// <summary>Packed date: year-2000 (5 bits), month (4 bits), day (5 bits).</summary>
    eftPackedDate,
    /// <summary>Packed time: hours (5 bits), minutes (6 bits), seconds/2 (5 bits).</summary>
    eftPackedTime16,
    /// <summary>Packed time: hours (5 bits), minutes (6 bits).</summary>
    eftPackedTime11,
    /// <summary>EN1545 five-bit alphabet: 1..26 = A..Z, 0 and 31 = space.</summary>
    eftString);

  /// <summary>Layout tree node kinds.</summary>
  TEn1545NodeKind = (
    /// <summary>Primitive field.</summary>
    enkField,
    /// <summary>Children in sequence.</summary>
    enkContainer,
    /// <summary>Presence bitmap, one bit per child, least significant bit for the first child.</summary>
    enkBitmap,
    /// <summary>Presence bitmap, most significant bit for the first child.</summary>
    enkReversedBitmap,
    /// <summary>Counter of Width bits followed by that many repetitions of the children.</summary>
    enkRepeat);

  /// <summary>One compiled layout node; children are indexes into the layout node array.</summary>
  TEn1545Node = record
    /// <summary>Node kind.</summary>
    Kind: TEn1545NodeKind;
    /// <summary>Field or group name; empty for anonymous groups.</summary>
    Name: string;
    /// <summary>Primitive encoding for fields.</summary>
    FieldType: TEn1545FieldType;
    /// <summary>Field width, or repeat-counter width, in bits.</summary>
    Width: Integer;
    /// <summary>Evidence level of this definition.</summary>
    Confidence: TEn1545Confidence;
    /// <summary>Child node indexes for groups.</summary>
    Children: array of Integer;
  end;

  /// <summary>Compiled, immutable table-driven layout.</summary>
  TEn1545Layout = record
    /// <summary>Layout identifier, for example MOBIB.Event.V3.</summary>
    Name: string;
    /// <summary>Public source reference of the layout.</summary>
    Source: string;
    /// <summary>All nodes; Root is the top-level container.</summary>
    Nodes: array of TEn1545Node;
    /// <summary>Index of the root container node.</summary>
    Root: Integer;
  end;

  /// <summary>One decoded field occurrence.</summary>
  TEn1545Value = record
    /// <summary>Field name from the layout.</summary>
    Name: string;
    /// <summary>Name plus one-based repeat indexes, for example ContractTariff[2].</summary>
    Path: string;
    /// <summary>Zero-based MSB-first bit offset in the record.</summary>
    BitOffset: Integer;
    /// <summary>Field width in bits.</summary>
    BitWidth: Integer;
    /// <summary>Primitive encoding.</summary>
    FieldType: TEn1545FieldType;
    /// <summary>Evidence level from the layout.</summary>
    Confidence: TEn1545Confidence;
    /// <summary>True when the field fits in 64 bits and Raw holds its value.</summary>
    HasRaw: Boolean;
    /// <summary>Unsigned raw value for fields up to 64 bits.</summary>
    Raw: UInt64;
    /// <summary>Raw bits as right-aligned hexadecimal.</summary>
    Hex: string;
    /// <summary>Decoded human-readable value; empty for absent dates.</summary>
    Text: string;
    /// <summary>False when the encoding is invalid (bad BCD digit, impossible date or time).</summary>
    Valid: Boolean;
    /// <summary>True when DateTime holds a decoded date or timestamp.</summary>
    HasDate: Boolean;
    /// <summary>Decoded civil date or timestamp, without time-zone conversion.</summary>
    DateTime: TDateTime;
  end;

  /// <summary>Decoded field occurrences in record order.</summary>
  TEn1545Values = array of TEn1545Value;

  /// <summary>Result of parsing one record with one layout.</summary>
  TEn1545Parsed = record
    /// <summary>Layout name used.</summary>
    Layout: string;
    /// <summary>Decoded fields.</summary>
    Values: TEn1545Values;
    /// <summary>True when every present field fitted in the record.</summary>
    Complete: Boolean;
    /// <summary>First bit after the parsed layout.</summary>
    RemainderOffset: Integer;
    /// <summary>Unparsed trailing bits.</summary>
    RemainderBits: Integer;
    /// <summary>True when all unparsed trailing bits are zero.</summary>
    RemainderZero: Boolean;
    /// <summary>Unparsed trailing bits as hexadecimal, at most 2048 bits.</summary>
    RemainderHex: string;
  end;

  /// <summary>Offline table-driven EN1545 bit-field engine.</summary>
  /// <remarks>Layout definition syntax: comma-separated items. A field is
  /// <c>[~|?]Name:type[:width]</c> where ~ marks observed and ? unknown confidence. Types: int, hex,
  /// date, idate, time, dt, bcd, bcddate, pdate, ptime16, ptime11, str. Groups are
  /// <c>seq(...)</c>, <c>bitmap(...)</c>, <c>rbitmap(...)</c> and <c>repeat:width(...)</c>, optionally
  /// named as <c>Name:bitmap(...)</c>; a named bitmap or repeat records its own raw value.</remarks>
  TEn1545 = class
  public
    /// <summary>Reads an unsigned MSB-first bit field.</summary>
    /// <param name="AData">Source bytes.</param>
    /// <param name="ABitOffset">Zero-based bit offset.</param>
    /// <param name="ABitCount">Width, 1..64.</param>
    /// <returns>Unsigned value.</returns>
    class function Bits(const AData: TBytes;
      const ABitOffset, ABitCount: Integer): UInt64; static;
    /// <summary>Formats a bit run as right-aligned hexadecimal.</summary>
    /// <param name="AData">Source bytes.</param>
    /// <param name="ABitOffset">Zero-based bit offset.</param>
    /// <param name="ABitCount">Width, 0..2048.</param>
    /// <returns>Uppercase hexadecimal, empty for zero width.</returns>
    class function BitsHex(const AData: TBytes;
      const ABitOffset, ABitCount: Integer): string; static;
    /// <summary>Compiles a textual layout definition.</summary>
    /// <param name="AName">Layout identifier.</param>
    /// <param name="ASource">Public source reference.</param>
    /// <param name="ADefinition">Layout definition text.</param>
    /// <returns>Compiled layout.</returns>
    class function Compile(const AName, ASource, ADefinition: string)
      : TEn1545Layout; static;
    /// <summary>Parses one record; fields that do not fit stop parsing and clear Complete.</summary>
    /// <param name="AData">Record bytes, at most 256.</param>
    /// <param name="ALayout">Compiled layout.</param>
    /// <param name="AStartBit">First bit to parse.</param>
    /// <returns>Decoded values and the unparsed remainder.</returns>
    class function Parse(const AData: TBytes; const ALayout: TEn1545Layout;
      const AStartBit: Integer = 0): TEn1545Parsed; static;
    /// <summary>Finds a value by path.</summary>
    /// <param name="AParsed">Parsed record.</param>
    /// <param name="APath">Field path, case-insensitive.</param>
    /// <param name="AValue">Found value.</param>
    /// <returns>True when present.</returns>
    class function Find(const AParsed: TEn1545Parsed; const APath: string;
      out AValue: TEn1545Value): Boolean; static;
    /// <summary>Returns a raw integer value or a default.</summary>
    /// <param name="AParsed">Parsed record.</param>
    /// <param name="APath">Field path.</param>
    /// <param name="ADefault">Value returned when the field is absent.</param>
    /// <returns>Raw value or default.</returns>
    class function IntOr(const AParsed: TEn1545Parsed; const APath: string;
      const ADefault: Int64): Int64; static;
    /// <summary>Returns the decoded date of a field.</summary>
    /// <param name="AParsed">Parsed record.</param>
    /// <param name="APath">Field path.</param>
    /// <param name="ADate">Decoded date.</param>
    /// <returns>True when present, valid and not marked absent.</returns>
    class function DateOf(const AParsed: TEn1545Parsed; const APath: string;
      out ADate: TDateTime): Boolean; static;
    /// <summary>Formats a date as ISO yyyy-mm-dd, independent of locale.</summary>
    /// <param name="ADate">Date.</param>
    /// <returns>ISO date text.</returns>
    class function IsoDate(const ADate: TDateTime): string; static;
    /// <summary>Returns the label of a confidence level.</summary>
    /// <param name="AConfidence">Confidence.</param>
    /// <returns>published, observed or unknown.</returns>
    class function ConfidenceName(const AConfidence: TEn1545Confidence)
      : string; static;
  end;

implementation

const
  MaxValues = 4096;

procedure Bad;
begin
  raise EEn1545Error.Create('Invalid EN1545 layout or field request.');
end;

function EpochDate: TDateTime;
begin
  Result := EncodeDate(1997, 1, 1);
end;

class function TEn1545.Bits(const AData: TBytes;
  const ABitOffset, ABitCount: Integer): UInt64;
var
  I, P: Integer;
begin
  if (ABitOffset < 0) or (ABitCount < 1) or (ABitCount > 64) or
    (Int64(ABitOffset) + ABitCount > Int64(Length(AData)) * 8) then
    Bad;
  Result := 0;
  for I := 0 to ABitCount - 1 do
  begin
    P := ABitOffset + I;
    Result := (Result shl 1) or ((AData[P div 8] shr (7 - P mod 8)) and 1);
  end;
end;

class function TEn1545.BitsHex(const AData: TBytes;
  const ABitOffset, ABitCount: Integer): string;
const
  Digits: string = '0123456789ABCDEF';
var
  P, W: Integer;
begin
  Result := '';
  if (ABitCount < 0) or (ABitCount > 2048) or (ABitOffset < 0) or
    (Int64(ABitOffset) + ABitCount > Int64(Length(AData)) * 8) then
    Bad;
  P := ABitOffset;
  W := ABitCount mod 4;
  if W = 0 then
    W := 4;
  while P < ABitOffset + ABitCount do
  begin
    Result := Result + Digits[Integer(Bits(AData, P, W)) + 1];
    Inc(P, W);
    W := 4;
  end;
end;

class function TEn1545.IsoDate(const ADate: TDateTime): string;
var
  Y, M, D: Word;
begin
  DecodeDate(ADate, Y, M, D);
  Result := Format('%.4d-%.2d-%.2d', [Y, M, D]);
end;

class function TEn1545.ConfidenceName(const AConfidence
  : TEn1545Confidence): string;
begin
  case AConfidence of
    ecPublished:
      Result := 'published';
    ecObserved:
      Result := 'observed';
  else
    Result := 'unknown';
  end;
end;

function IsIdentChar(const C: Char): Boolean;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
    ((C >= '0') and (C <= '9')) or (C = '_');
end;

class function TEn1545.Compile(const AName, ASource, ADefinition: string)
  : TEn1545Layout;
var
  L: TEn1545Layout;
  P: Integer;

  function Peek: Char;
  begin
    while (P <= Length(ADefinition)) and (ADefinition[P] <= ' ') do
      Inc(P);
    if P > Length(ADefinition) then
      Result := #0
    else
      Result := ADefinition[P];
  end;

  procedure Expect(const C: Char);
  begin
    if Peek <> C then
      Bad;
    Inc(P);
  end;

  function Ident: string;
  begin
    Peek;
    Result := '';
    while (P <= Length(ADefinition)) and IsIdentChar(ADefinition[P]) do
    begin
      Result := Result + ADefinition[P];
      Inc(P);
    end;
    if (Result = '') or (Length(Result) > 64) then
      Bad;
  end;

  function Number: Integer;
  var
    S: string;
  begin
    S := Ident;
    if not TryStrToInt(S, Result) or (Result < 0) or (Result > 2048) then
      Bad;
  end;

  function AddNode(const AKind: TEn1545NodeKind; const ANodeName: string)
    : Integer;
  begin
    if Length(L.Nodes) >= 1024 then
      Bad;
    Result := Length(L.Nodes);
    SetLength(L.Nodes, Result + 1);
    L.Nodes[Result].Kind := AKind;
    L.Nodes[Result].Name := ANodeName;
  end;

  procedure AddChild(const AParent, AChild: Integer);
  var
    N: Integer;
  begin
    N := Length(L.Nodes[AParent].Children);
    if N >= 64 then
      Bad;
    SetLength(L.Nodes[AParent].Children, N + 1);
    L.Nodes[AParent].Children[N] := AChild;
  end;

  function IsGroupKeyword(const S: string): Boolean;
  begin
    Result := (S = 'seq') or (S = 'bitmap') or (S = 'rbitmap') or
      (S = 'repeat');
  end;

  function ParseItem(const ADepth: Integer): Integer;
  var
    Conf: TEn1545Confidence;
    N, T: string;
    FT: TEn1545FieldType;
    W, DefaultWidth: Integer;
    HasWidth: Boolean;

    function Group(const AKeyword, ANodeName: string): Integer;
    var
      K: TEn1545NodeKind;
      GW: Integer;
    begin
      GW := 0;
      K := enkContainer;
      if AKeyword = 'bitmap' then
        K := enkBitmap
      else if AKeyword = 'rbitmap' then
        K := enkReversedBitmap
      else if AKeyword = 'repeat' then
      begin
        K := enkRepeat;
        Expect(':');
        GW := Number;
        if (GW < 1) or (GW > 8) then
          Bad;
      end;
      Result := AddNode(K, ANodeName);
      L.Nodes[Result].Width := GW;
      L.Nodes[Result].Confidence := Conf;
      Expect('(');
      AddChild(Result, ParseItem(ADepth + 1));
      while Peek = ',' do
      begin
        Inc(P);
        AddChild(Result, ParseItem(ADepth + 1));
      end;
      Expect(')');
    end;

  begin
    if ADepth > 16 then
      Bad;
    Conf := ecPublished;
    if Peek = '~' then
    begin
      Conf := ecObserved;
      Inc(P);
    end
    else if Peek = '?' then
    begin
      Conf := ecUnknown;
      Inc(P);
    end;
    N := Ident;
    if IsGroupKeyword(N) and ((Peek = '(') or ((N = 'repeat') and
      (Peek = ':'))) then
    begin
      Result := Group(N, '');
      Exit;
    end;
    Expect(':');
    T := Ident;
    if IsGroupKeyword(T) then
    begin
      Result := Group(T, N);
      Exit;
    end;
    DefaultWidth := -1;
    if T = 'int' then
      FT := eftInteger
    else if T = 'hex' then
      FT := eftHex
    else if T = 'date' then
    begin
      FT := eftDate;
      DefaultWidth := 14;
    end
    else if T = 'idate' then
    begin
      FT := eftInvertedDate;
      DefaultWidth := 14;
    end
    else if T = 'time' then
    begin
      FT := eftTime;
      DefaultWidth := 11;
    end
    else if T = 'dt' then
    begin
      FT := eftDateTime;
      DefaultWidth := 30;
    end
    else if T = 'bcd' then
      FT := eftBcd
    else if T = 'bcddate' then
    begin
      FT := eftBcdDate;
      DefaultWidth := 32;
    end
    else if T = 'pdate' then
    begin
      FT := eftPackedDate;
      DefaultWidth := 14;
    end
    else if T = 'ptime16' then
    begin
      FT := eftPackedTime16;
      DefaultWidth := 16;
    end
    else if T = 'ptime11' then
    begin
      FT := eftPackedTime11;
      DefaultWidth := 11;
    end
    else if T = 'str' then
      FT := eftString
    else
    begin
      FT := eftHex;
      Bad;
    end;
    HasWidth := Peek = ':';
    if HasWidth then
    begin
      Inc(P);
      W := Number;
    end
    else
    begin
      if DefaultWidth < 0 then
        Bad;
      W := DefaultWidth;
    end;
    case FT of
      eftInteger:
        if W > 64 then
          Bad;
      eftDate, eftInvertedDate, eftTime, eftDateTime, eftPackedDate,
        eftPackedTime16, eftPackedTime11:
        if W <> DefaultWidth then
          Bad;
      eftBcd:
        if (W = 0) or (W mod 4 <> 0) or (W > 256) then
          Bad;
      eftBcdDate:
        if W <> 32 then
          Bad;
    end;
    Result := AddNode(enkField, N);
    L.Nodes[Result].FieldType := FT;
    L.Nodes[Result].Width := W;
    L.Nodes[Result].Confidence := Conf;
  end;

begin
  L := Default (TEn1545Layout);
  if (Length(ADefinition) = 0) or (Length(ADefinition) > 16384) then
    Bad;
  L.Name := AName;
  L.Source := ASource;
  P := 1;
  L.Root := AddNode(enkContainer, '');
  AddChild(L.Root, ParseItem(0));
  while Peek = ',' do
  begin
    Inc(P);
    AddChild(L.Root, ParseItem(0));
  end;
  if Peek <> #0 then
    Bad;
  Result := L;
end;

procedure DecodeValue(var V: TEn1545Value; const AData: TBytes);
const
  Alphabet: string = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ???? ';
var
  I, N, Y, M, D, H, Mi, S: Integer;
  Digits: string;
  Days: Int64;
  Dt: TDateTime;
begin
  V.Valid := True;
  V.HasRaw := V.BitWidth <= 64;
  if V.HasRaw and (V.BitWidth > 0) then
    V.Raw := TEn1545.Bits(AData, V.BitOffset, V.BitWidth);
  if V.BitWidth <= 2048 then
    V.Hex := TEn1545.BitsHex(AData, V.BitOffset, V.BitWidth);
  case V.FieldType of
    eftInteger:
      V.Text := UIntToStr(V.Raw);
    eftHex:
      V.Text := V.Hex;
    eftDate:
      if V.Raw <> 0 then
      begin
        V.HasDate := True;
        V.DateTime := EpochDate + V.Raw;
        V.Text := TEn1545.IsoDate(V.DateTime);
      end;
    eftInvertedDate:
      if V.Raw <> $3FFF then
      begin
        Days := $3FFF - Int64(V.Raw);
        V.HasDate := True;
        V.DateTime := EpochDate + Days;
        V.Text := TEn1545.IsoDate(V.DateTime);
      end;
    eftTime:
      if V.Raw > 1439 then
        V.Valid := False
      else
        V.Text := Format('%.2d:%.2d', [Integer(V.Raw div 60),
          Integer(V.Raw mod 60)]);
    eftDateTime:
      if V.Raw <> 0 then
      begin
        V.HasDate := True;
        V.DateTime := EpochDate + (V.Raw div 86400) +
          (V.Raw mod 86400) / 86400;
        S := Integer(V.Raw mod 86400);
        V.Text := TEn1545.IsoDate(V.DateTime) +
          Format(' %.2d:%.2d:%.2d', [S div 3600, (S div 60) mod 60, S mod 60]);
      end;
    eftBcd, eftBcdDate:
      begin
        Digits := '';
        for I := 0 to V.BitWidth div 4 - 1 do
        begin
          N := Integer(TEn1545.Bits(AData, V.BitOffset + I * 4, 4));
          if N > 9 then
          begin
            V.Valid := False;
            Digits := Digits + '?';
          end
          else
            Digits := Digits + Char(Ord('0') + N);
        end;
        if V.FieldType = eftBcd then
          V.Text := Digits
        else if V.Valid and (Digits <> '00000000') then
        begin
          Y := StrToInt(Copy(Digits, 1, 4));
          M := StrToInt(Copy(Digits, 5, 2));
          D := StrToInt(Copy(Digits, 7, 2));
          if TryEncodeDate(Y, M, D, Dt) then
          begin
            V.HasDate := True;
            V.DateTime := Dt;
            V.Text := TEn1545.IsoDate(Dt);
          end
          else
            V.Valid := False;
        end;
      end;
    eftPackedDate:
      if V.Raw <> 0 then
      begin
        Y := Integer(V.Raw shr 9) + 2000;
        M := Integer((V.Raw shr 5) and 15);
        D := Integer(V.Raw and 31);
        if TryEncodeDate(Y, M, D, Dt) then
        begin
          V.HasDate := True;
          V.DateTime := Dt;
          V.Text := TEn1545.IsoDate(Dt);
        end
        else
          V.Valid := False;
      end;
    eftPackedTime16, eftPackedTime11:
      begin
        if V.FieldType = eftPackedTime16 then
        begin
          H := Integer(V.Raw shr 11);
          Mi := Integer((V.Raw shr 5) and 63);
          S := Integer(V.Raw and 31) * 2;
        end
        else
        begin
          H := Integer(V.Raw shr 6);
          Mi := Integer(V.Raw and 63);
          S := 0;
        end;
        if (H > 23) or (Mi > 59) or (S > 59) then
          V.Valid := False
        else if V.FieldType = eftPackedTime16 then
          V.Text := Format('%.2d:%.2d:%.2d', [H, Mi, S])
        else
          V.Text := Format('%.2d:%.2d', [H, Mi]);
      end;
    eftString:
      begin
        V.Text := '';
        for I := 0 to V.BitWidth div 5 - 1 do
          V.Text := V.Text + Alphabet
            [Integer(TEn1545.Bits(AData, V.BitOffset + I * 5, 5)) + 1];
        V.Text := Trim(V.Text);
      end;
  end;
end;

class function TEn1545.Parse(const AData: TBytes; const ALayout: TEn1545Layout;
  const AStartBit: Integer): TEn1545Parsed;
var
  R: TEn1545Parsed;
  Off, Total: Integer;

  procedure Add(const ANode: TEn1545Node; const APath: string;
    const AOffset, AWidth: Integer; const AType: TEn1545FieldType);
  var
    N: Integer;
  begin
    N := Length(R.Values);
    if N >= MaxValues then
      Bad;
    SetLength(R.Values, N + 1);
    R.Values[N].Name := ANode.Name;
    R.Values[N].Path := APath;
    R.Values[N].BitOffset := AOffset;
    R.Values[N].BitWidth := AWidth;
    R.Values[N].FieldType := AType;
    R.Values[N].Confidence := ANode.Confidence;
    DecodeValue(R.Values[N], AData);
  end;

  function Walk(const AIndex: Integer; const ASuffix: string;
    const ADepth: Integer): Boolean;
  var
    Node: TEn1545Node;
    I, J, Count: Integer;
    Mask, Bit: UInt64;
  begin
    Result := False;
    if (AIndex < 0) or (AIndex > High(ALayout.Nodes)) or (ADepth > 32) then
      Bad;
    Node := ALayout.Nodes[AIndex];
    case Node.Kind of
      enkField:
        begin
          if Node.Width = 0 then
          begin
            Result := True;
            Exit;
          end;
          if Off + Node.Width > Total then
            Exit;
          Add(Node, Node.Name + ASuffix, Off, Node.Width, Node.FieldType);
          Inc(Off, Node.Width);
        end;
      enkContainer:
        for I := 0 to High(Node.Children) do
          if not Walk(Node.Children[I], ASuffix, ADepth + 1) then
            Exit;
      enkBitmap, enkReversedBitmap:
        begin
          Count := Length(Node.Children);
          if (Count < 1) or (Count > 64) or (Off + Count > Total) then
            Exit;
          Mask := Bits(AData, Off, Count);
          if Node.Name <> '' then
            Add(Node, Node.Name + ASuffix, Off, Count, eftInteger);
          Inc(Off, Count);
          for I := 0 to Count - 1 do
          begin
            if Node.Kind = enkBitmap then
              Bit := UInt64(1) shl I
            else
              Bit := UInt64(1) shl (Count - 1 - I);
            if (Mask and Bit) <> 0 then
              if not Walk(Node.Children[I], ASuffix, ADepth + 1) then
                Exit;
          end;
        end;
      enkRepeat:
        begin
          if Off + Node.Width > Total then
            Exit;
          Count := Integer(Bits(AData, Off, Node.Width));
          if Node.Name <> '' then
            Add(Node, Node.Name + ASuffix, Off, Node.Width, eftInteger);
          Inc(Off, Node.Width);
          for J := 1 to Count do
            for I := 0 to High(Node.Children) do
              if not Walk(Node.Children[I], ASuffix + '[' + IntToStr(J) + ']',
                ADepth + 1) then
                Exit;
        end;
    end;
    Result := True;
  end;

var
  I: Integer;
begin
  R := Default (TEn1545Parsed);
  if (Length(AData) > 256) or (Length(ALayout.Nodes) = 0) or (AStartBit < 0) or
    (AStartBit > Length(AData) * 8) then
    Bad;
  Total := Length(AData) * 8;
  Off := AStartBit;
  R.Layout := ALayout.Name;
  R.Complete := Walk(ALayout.Root, '', 0);
  R.RemainderOffset := Off;
  R.RemainderBits := Total - Off;
  R.RemainderZero := True;
  for I := Off to Total - 1 do
    if ((AData[I div 8] shr (7 - I mod 8)) and 1) <> 0 then
    begin
      R.RemainderZero := False;
      Break;
    end;
  if R.RemainderBits > 2048 then
    R.RemainderHex := BitsHex(AData, Off, 2048)
  else
    R.RemainderHex := BitsHex(AData, Off, R.RemainderBits);
  Result := R;
end;

class function TEn1545.Find(const AParsed: TEn1545Parsed; const APath: string;
  out AValue: TEn1545Value): Boolean;
var
  I: Integer;
begin
  AValue := Default (TEn1545Value);
  for I := 0 to High(AParsed.Values) do
    if SameText(AParsed.Values[I].Path, APath) then
    begin
      AValue := AParsed.Values[I];
      Result := True;
      Exit;
    end;
  Result := False;
end;

class function TEn1545.IntOr(const AParsed: TEn1545Parsed; const APath: string;
  const ADefault: Int64): Int64;
var
  V: TEn1545Value;
begin
  if Find(AParsed, APath, V) and V.HasRaw then
    Result := Int64(V.Raw)
  else
    Result := ADefault;
end;

class function TEn1545.DateOf(const AParsed: TEn1545Parsed;
  const APath: string; out ADate: TDateTime): Boolean;
var
  V: TEn1545Value;
begin
  ADate := 0;
  Result := Find(AParsed, APath, V) and V.Valid and V.HasDate;
  if Result then
    ADate := V.DateTime;
end;

end.
