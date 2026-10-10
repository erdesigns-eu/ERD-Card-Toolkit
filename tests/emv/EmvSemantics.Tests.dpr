program EmvSemanticsTests;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{$IFNDEF FPC}
{$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.EMV.Semantics;

var
  Assertions: Integer;

procedure Check(const Condition: Boolean; const Message: string);
begin
  Inc(Assertions);
  if not Condition then raise Exception.Create(Message);
end;

procedure BitTests;
const
  Tags: array[0..5] of Cardinal = ($82, $9F07, $95, $9F0D, $9F0E, $9F0F);
var
  T, I, J, B, V, Size: Integer;
  Bytes: TBytes;
  Bits: TEmvBitMeanings;
begin
  for T := 0 to High(Tags) do
  begin
    Size := 5; if T < 2 then Size := 2;
    for V := 0 to 1 do
      for I := 0 to Size - 1 do
        for B := 0 to 255 do
        begin
          Bytes := nil; SetLength(Bytes, Size); Bytes[I] := B;
          Bits := TEmvSemanticCodec.DecodeBits(Tags[T], Bytes, TEmvSemanticVersion(V));
          Check(Length(Bits) = Size * 8, 'All bits returned');
          for J := 0 to High(Bits) do
          begin
            Check((Bits[J].ByteNumber = J div 8 + 1) and
              (Bits[J].BitNumber = 8 - J mod 8), 'Stable EMV byte/MSB order');
            Check(Bits[J].IsSet = (Bytes[J div 8] and (1 shl (7 - J mod 8)) <> 0), 'Raw bit preserved');
            Check(Bits[J].Meaning <> '', 'Reserved bits retained with explanation');
          end;
        end;
  end;
  Bits := TEmvSemanticCodec.DecodeBits($82, HexToBytes('8000'), esv44);
  Check(Bits[0].Known and (Bits[0].Meaning = 'XDA supported'), 'EMV 4.4 XDA');
  Bits := TEmvSemanticCodec.DecodeBits($82, HexToBytes('8000'), esv43);
  Check(not Bits[0].Known and Bits[0].IsSet, '4.3 retains future bit without guessing');
  Bits := TEmvSemanticCodec.DecodeBits($82, HexToBytes('0281'), esv44);
  Check(not Bits[6].Known and not Bits[8].Known and not Bits[15].Known, 'Contactless bits remain kernel-specific');
  Bits := TEmvSemanticCodec.DecodeBits($95, HexToBytes('0000040000'), esv43);
  Check(Bits[21].Meaning = 'Online PIN entered', '4.3 online PIN meaning');
  Bits := TEmvSemanticCodec.DecodeBits($95, HexToBytes('0000040000'), esv44);
  Check(Bits[21].Meaning = 'Online CVM captured', '4.4 online CVM meaning');
  Bits := TEmvSemanticCodec.DecodeBits($9F0D, HexToBytes('8000000000'), esv44);
  Check(Pos('Issuer action criterion:', Bits[0].Meaning) = 1, 'IAC is policy, not an observed failure');
  Writeln('PASS: Every input-byte value for AIP/AUC/TVR/IAC and explicit 4.3/4.4 semantics.');
end;

procedure CvmTests;
var
  Method, Condition, Flags: Integer;
  Data: TBytes;
  List: TEmvCvmList;
begin
  for Method := 0 to 63 do
    for Condition := 0 to 255 do
      for Flags := 0 to 3 do
      begin
        Data := HexToBytes('FFFFFFFF800000000000');
        Data[8] := Method or (Flags shl 6); Data[9] := Condition;
        List := TEmvSemanticCodec.DecodeCvmList(Data, esv44);
        Check((List.AmountX = High(Cardinal)) and (List.AmountY = $80000000), 'Unsigned binary thresholds');
        Check((Length(List.Rules) = 1) and (List.Rules[0].Method = Method) and
          (List.Rules[0].Condition = Condition), 'All method/condition values retained');
        Check((List.Rules[0].ContinueOnFailure = (Flags and 1 <> 0)) and
          (List.Rules[0].ReservedBitSet = (Flags and 2 <> 0)), 'Method flags retained independently');
        Check(List.Rules[0].ConditionKnown = (Condition < 10), 'Proprietary/reserved condition');
      end;
  List := TEmvSemanticCodec.DecodeCvmList(HexToBytes('000000010000000246030900'), esv44);
  Check((Length(List.Rules) = 2) and List.Rules[0].MethodKnown and
    List.Rules[0].ContinueOnFailure, 'Ordered biometric/continuation rules');
  List := TEmvSemanticCodec.DecodeCvmList(HexToBytes('000000010000000246030900'), esv43);
  Check(not List.Rules[0].MethodKnown and not List.Rules[1].MethodKnown, 'Old version never infers biometric support');
  Writeln('PASS: All CVM method/condition/flag combinations and unsigned amount boundaries.');
end;

procedure BoundsTests;
var
  I: Integer;
  Data: TBytes;
  Bits: TEmvBitMeanings;
  List: TEmvCvmList;
  Failed: Boolean;
begin
  for I := 0 to 260 do
  begin
    Data := nil; SetLength(Data, I);
    if (I <> 2) then
    begin
      Failed := False;
      try Bits := TEmvSemanticCodec.DecodeBits($82, Data);
      except on EEmvSemanticError do Failed := True; end;
      Check(Failed, 'AIP exact length');
    end;
    if (I < 10) or (I > 254) or (I mod 2 <> 0) then
    begin
      Failed := False;
      try List := TEmvSemanticCodec.DecodeCvmList(Data);
      except on EEmvSemanticError do Failed := True; end;
      Check(Failed, 'CVM list structural bound');
    end;
  end;
  Failed := False;
  try Bits := TEmvSemanticCodec.DecodeBits($FF, HexToBytes('0000'));
  except on EEmvSemanticError do Failed := True; end;
  Check(Failed, 'Unknown semantic tag refused');
  Bits := TEmvSemanticCodec.DecodeBits($95, HexToBytes('0000000000'));
  List := TEmvSemanticCodec.DecodeCvmList(HexToBytes('00000000000000001F00'));
  Check((Length(Bits) = 40) and (Length(List.Rules) = 1), 'Independent outputs');
end;

begin
  try
    BitTests; CvmTests; BoundsTests;
    Writeln('PASS: ', Assertions, ' EMV semantic assertions.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.Message); Halt(1); end;
  end;
end.
