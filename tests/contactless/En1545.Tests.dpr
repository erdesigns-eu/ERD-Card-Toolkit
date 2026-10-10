program En1545Tests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.EN1545;

var
  Checks: Integer;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then
    raise Exception.Create('EN1545 regression: ' + AMessage);
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

function Raises(const ADefinition: string): Boolean;
begin
  Result := False;
  try
    TEn1545.Compile('Bad', 'Test', ADefinition);
  except
    on E: EEn1545Error do
      Result := True;
  end;
end;

procedure Tests;
var
  L: TEn1545Layout;
  P: TEn1545Parsed;
  V: TEn1545Value;
  B: TBytes;
  D: TDateTime;
  Failed: Boolean;
begin
  SetLength(B, 4);
  B[0] := $A5; B[1] := $0F; B[2] := $F0; B[3] := $01;
  Check(TEn1545.Bits(B, 0, 4) = $A, 'High nibble');
  Check(TEn1545.Bits(B, 4, 8) = $50, 'Cross-byte field');
  Check(TEn1545.Bits(B, 0, 32) = $A50FF001, 'Full width');
  Check(TEn1545.BitsHex(B, 4, 12) = '50F', 'Hex of unaligned field');
  Check(TEn1545.BitsHex(B, 0, 6) = '29', 'Short hex is right aligned');
  Failed := False;
  try
    TEn1545.Bits(B, 30, 3);
  except
    on E: EEn1545Error do
      Failed := True;
  end;
  Check(Failed, 'Out-of-range bits raise');

  { Fixed fields, dates, inverted dates, time and confidence markers. }
  L := TEn1545.Compile('Fixed', 'Synthetic', 'Version:int:6, Start:date, ~End:idate,' +
    ' ?Unknown:int:5, At:time, Code:bcd:8, Name:str:20, Blob:hex:12');
  SetLength(B, 16);
  FillChar(B[0], Length(B), 0);
  Put(B, 0, 6, 4); Put(B, 6, 14, 100); Put(B, 20, 14, $3FFF - 200);
  Put(B, 34, 5, 9); Put(B, 39, 11, 754); Put(B, 50, 8, $42);
  Put(B, 58, 5, 1); Put(B, 63, 5, 2); Put(B, 68, 5, 3); Put(B, 73, 5, 0);
  Put(B, 78, 12, $ABC);
  P := TEn1545.Parse(B, L);
  Check(P.Complete and (P.Layout = 'Fixed'), 'Complete fixed parse');
  Check(TEn1545.IntOr(P, 'Version', -1) = 4, 'Integer value');
  Check(TEn1545.DateOf(P, 'Start', D) and (D = EncodeDate(1997, 1, 1) + 100), 'Date epoch');
  Check(TEn1545.DateOf(P, 'End', D) and (D = EncodeDate(1997, 1, 1) + 200), 'Inverted date');
  Check(TEn1545.Find(P, 'End', V) and (V.Confidence = ecObserved) and
    (V.BitOffset = 20) and (V.BitWidth = 14), 'Observed confidence and position');
  Check(TEn1545.Find(P, 'unknown', V) and (V.Confidence = ecUnknown) and (V.Raw = 9),
    'Case-insensitive path and unknown confidence');
  Check(TEn1545.Find(P, 'At', V) and (V.Text = '12:34') and V.Valid, 'Time text');
  Check(TEn1545.Find(P, 'Code', V) and (V.Text = '42'), 'BCD digits');
  Check(TEn1545.Find(P, 'Name', V) and (V.Text = 'ABC'), 'Five-bit text trimmed');
  Check(TEn1545.Find(P, 'Blob', V) and (V.Text = 'ABC'), 'Hex field');
  Check(P.RemainderOffset = 90, 'Remainder offset');
  Check((P.RemainderBits = 38) and P.RemainderZero, 'Zero remainder');
  Check(TEn1545.ConfidenceName(ecPublished) = 'published', 'Confidence label');
  Put(B, 20, 14, $3FFF);
  P := TEn1545.Parse(B, L);
  Check(not TEn1545.DateOf(P, 'End', D), 'All-ones inverted date is absent');
  Put(B, 6, 14, 0); Put(B, 39, 11, 1500); Put(B, 50, 8, $4F);
  B[15] := 1;
  P := TEn1545.Parse(B, L);
  Check(not TEn1545.DateOf(P, 'Start', D), 'Zero date is absent');
  Check(TEn1545.Find(P, 'At', V) and not V.Valid, 'Invalid minutes flagged');
  Check(TEn1545.Find(P, 'Code', V) and not V.Valid and (V.Text = '4?'), 'Invalid BCD flagged');
  Check(not P.RemainderZero, 'Nonzero remainder detected');
  Check(TEn1545.IntOr(P, 'Missing', 77) = 77, 'Default for missing path');

  { Short data stops at the last complete field. }
  SetLength(B, 2);
  P := TEn1545.Parse(B, L);
  Check(not P.Complete and (Length(P.Values) = 1) and (P.RemainderOffset = 6),
    'Truncated parse keeps complete fields only');

  { Bitmaps: least significant bit is the first child; reversed is MSB first. }
  L := TEn1545.Compile('Bitmap', 'Synthetic',
    'Map:bitmap(A:int:4, B:int:4, seq(C:int:2, D:int:2)), Tail:int:3');
  SetLength(B, 4);
  FillChar(B[0], Length(B), 0);
  Put(B, 0, 3, 5); Put(B, 3, 4, 9); Put(B, 7, 2, 1); Put(B, 9, 2, 2); Put(B, 11, 3, 7);
  P := TEn1545.Parse(B, L);
  Check(P.Complete and (TEn1545.IntOr(P, 'Map', -1) = 5), 'Named bitmap value');
  Check(TEn1545.IntOr(P, 'A', -1) = 9, 'Bitmap child zero present');
  Check(not TEn1545.Find(P, 'B', V), 'Absent bitmap child');
  Check((TEn1545.IntOr(P, 'C', -1) = 1) and (TEn1545.IntOr(P, 'D', -1) = 2), 'Nested sequence');
  Check(TEn1545.IntOr(P, 'Tail', -1) = 7, 'Field after bitmap');
  L := TEn1545.Compile('Reversed', 'Synthetic', 'rbitmap(A:int:4, B:int:4, C:int:4)');
  FillChar(B[0], Length(B), 0);
  Put(B, 0, 3, 4); Put(B, 3, 4, 6);
  P := TEn1545.Parse(B, L);
  Check((TEn1545.IntOr(P, 'A', -1) = 6) and not TEn1545.Find(P, 'B', V), 'Reversed bitmap');

  { Repeat counters create indexed paths. }
  L := TEn1545.Compile('Repeat', 'Synthetic', 'List:repeat:2(Item:int:4, Flag:int:1)');
  FillChar(B[0], Length(B), 0);
  Put(B, 0, 2, 2); Put(B, 2, 4, 3); Put(B, 6, 1, 1); Put(B, 7, 4, 12);
  P := TEn1545.Parse(B, L);
  Check(TEn1545.IntOr(P, 'List', -1) = 2, 'Repeat count');
  Check((TEn1545.IntOr(P, 'Item[1]', -1) = 3) and (TEn1545.IntOr(P, 'Flag[1]', -1) = 1) and
    (TEn1545.IntOr(P, 'Item[2]', -1) = 12) and (TEn1545.IntOr(P, 'Flag[2]', -1) = 0),
    'Indexed repeat paths');

  { Other types. }
  L := TEn1545.Compile('Types', 'Synthetic',
    'Stamp:dt, Birth:bcddate, Day:pdate, Clock:ptime16, Short:ptime11, Wide:int:40');
  SetLength(B, 24);
  FillChar(B[0], Length(B), 0);
  Put(B, 0, 30, 86400 * 2 + 3661);
  Put(B, 30, 32, $19900423);
  Put(B, 62, 14, (24 shl 9) or (5 shl 5) or 17);
  Put(B, 76, 16, (13 shl 11) or (45 shl 5) or 10);
  Put(B, 92, 11, (7 shl 6) or 30);
  Put(B, 103, 40, $123456789A);
  P := TEn1545.Parse(B, L);
  Check(TEn1545.Find(P, 'Stamp', V) and (V.Text = '1997-01-03 01:01:01'), 'Seconds timestamp');
  Check(TEn1545.DateOf(P, 'Birth', D) and (D = EncodeDate(1990, 4, 23)), 'BCD date');
  Check(TEn1545.DateOf(P, 'Day', D) and (D = EncodeDate(2024, 5, 17)), 'Packed date');
  Check(TEn1545.Find(P, 'Clock', V) and (V.Text = '13:45:20'), 'Packed 16-bit time');
  Check(TEn1545.Find(P, 'Short', V) and (V.Text = '07:30'), 'Packed 11-bit time');
  Check(TEn1545.IntOr(P, 'Wide', -1) = $123456789A, 'Forty-bit integer');
  Check(TEn1545.IsoDate(EncodeDate(2026, 8, 12)) = '2026-08-12', 'ISO date');
  Put(B, 30, 32, $20230230);
  P := TEn1545.Parse(B, L);
  Check(TEn1545.Find(P, 'Birth', V) and not V.Valid and not V.HasDate, 'Impossible BCD date flagged');

  { Layout definitions fail explicitly. }
  Check(Raises(''), 'Empty definition');
  Check(Raises('A:int'), 'Missing integer width');
  Check(Raises('A:int:65'), 'Integer wider than 64 bits');
  Check(Raises('A:bcd:6'), 'BCD width not a nibble multiple');
  Check(Raises('A:nope:4'), 'Unknown type');
  Check(Raises('bitmap()'), 'Empty group');
  Check(Raises('bitmap(A:int:4'), 'Unclosed group');
  Check(Raises('repeat:9(A:int:1)'), 'Repeat counter too wide');
  Check(Raises('A:int:4,'), 'Trailing separator');
  Check(Raises('A:int:4 B:int:4'), 'Missing separator');
  Check(not Raises('A:int:4, B:date, ?C:hex:300'), 'Valid definition compiles');
end;

begin
  try
    Tests;
    Writeln('EN1545: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
