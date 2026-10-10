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
  Tags: array[0..7] of Cardinal = ($82, $9F07, $95, $9F0D, $9F0E, $9F0F, $9F33, $9F40);
var
  T, I, J, B, V, Size: Integer;
  Bytes: TBytes;
  Bits: TEmvBitMeanings;
begin
  for T := 0 to High(Tags) do
  begin
    Size := 5; if T < 2 then Size := 2;
    if T = 6 then Size := 3;
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

procedure TerminalTests;
var
  Bits: TEmvBitMeanings;
begin
  Bits := TEmvSemanticCodec.DecodeBits($9F33, HexToBytes('E0F8C8'), esv43);
  Check(Bits[0].IsSet and (Bits[0].Meaning = 'Manual key entry'), 'Terminal manual input');
  Check(Bits[1].IsSet and (Bits[1].Meaning = 'Magnetic stripe'), 'Terminal magstripe input');
  Check(Bits[2].IsSet and (Bits[2].Meaning = 'IC with contacts'), 'Terminal contact input');
  Check(Bits[8].IsSet and (Bits[8].Meaning = 'Plaintext PIN for ICC verification'), 'Offline plaintext PIN');
  Check(Bits[12].IsSet and (Bits[12].Meaning = 'No CVM required'), 'Terminal no-CVM support');
  Check(Bits[20].IsSet and (Bits[20].Meaning = 'CDA supported'), 'Terminal CDA position');
  Bits := TEmvSemanticCodec.DecodeBits($9F33, HexToBytes('000704'), esv43);
  Check(not Bits[13].Known and not Bits[14].Known and not Bits[15].Known and
    not Bits[21].Known, '4.3 future biometric/ECC/XDA bits remain reserved');
  Bits := TEmvSemanticCodec.DecodeBits($9F33, HexToBytes('000704'), esv44);
  Check(Bits[13].IsSet and (Bits[13].Meaning = 'Online biometric'), '4.4 online biometric position');
  Check(Bits[14].IsSet and (Bits[14].Meaning = 'Offline biometric'), '4.4 offline biometric position');
  Check(Bits[15].IsSet and (Pos('ECC ODE', Bits[15].Meaning) > 0), '4.4 ECC PIN position');
  Check(Bits[21].IsSet and (Bits[21].Meaning = 'XDA supported'), '4.4 terminal XDA position');
  Bits := TEmvSemanticCodec.DecodeBits($9F40, HexToBytes('01800F03FF'), esv44);
  Check(Bits[7].IsSet and (Bits[7].Meaning = 'Administrative'), 'Transaction type low bit');
  Check(Bits[8].IsSet and (Bits[8].Meaning = 'Cash deposit'), 'Cash deposit byte two');
  Check(not Bits[20].Known and Bits[20].IsSet, 'Keypad reserved bit retained');
  Check(Bits[30].IsSet and (Bits[30].Meaning = 'ISO/IEC 8859 code table 10'), 'Code table ten position');
  Check(Bits[31].IsSet and (Bits[31].Meaning = 'ISO/IEC 8859 code table 9'), 'Code table nine position');
  Check(Bits[32].IsSet and (Bits[32].Meaning = 'ISO/IEC 8859 code table 8'), 'Code table eight position');
  Check(Bits[39].IsSet and (Bits[39].Meaning = 'ISO/IEC 8859 code table 1'), 'Code table one position');
  Bits := TEmvSemanticCodec.DecodeBits($9F40, HexToBytes('000000C000'), esv43);
  Check((Bits[24].Meaning = 'Print, attendant') and (Bits[25].Meaning = 'Print, cardholder'), '4.3 printing meanings');
  Bits := TEmvSemanticCodec.DecodeBits($9F40, HexToBytes('000000C000'), esv44);
  Check((Pos('electronic', Bits[24].Meaning) > 0) and (Pos('electronic', Bits[25].Meaning) > 0), '4.4 electronic output meanings');
  Writeln('PASS: Book 4 terminal capability positions, RFU bits, code tables and version changes.');
end;

procedure CvmResultTests;
var
  Method, Condition, Outcome, V: Integer;
  Data: TBytes;
  Decoded: TEmvCvmResult;
begin
  Data := HexToBytes('000000');
  for V := 0 to 1 do
    for Method := 0 to 255 do
      for Condition := 0 to 255 do
      begin
        Data[0] := Method; Data[1] := Condition; Data[2] := Condition mod 3;
        Decoded := TEmvSemanticCodec.DecodeCvmResults(Data, TEmvSemanticVersion(V));
        Check((Decoded.Rule.RawMethod = Method) and (Decoded.Rule.Condition = Condition) and
          (Decoded.ResultCode = Condition mod 3), 'CVM results retain all raw bytes');
        Check(Decoded.NoCvmPerformed = (Method = $3F), 'No-CVM sentinel is the exact 3F encoding');
        Check((Decoded.Rule.ContinueOnFailure = (Method and $40 <> 0)) and
          (Decoded.Rule.ReservedBitSet = (Method and $80 <> 0)), 'CVM result flags retained');
        Check(Decoded.Rule.ConditionKnown = (Condition <= 9), 'Unknown result condition retained');
      end;
  for Outcome := 0 to 255 do
  begin
    Data[2] := Outcome;
    Decoded := TEmvSemanticCodec.DecodeCvmResults(Data);
    Check((Decoded.ResultCode = Outcome) and (Decoded.ResultKnown = (Outcome <= 2)), 'Every result byte retained');
    Check(Decoded.ResultMeaning <> '', 'Reserved outcomes explained');
  end;
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('3F0000'));
  Check(Decoded.NoCvmPerformed and Decoded.Rule.MethodKnown and
    (Decoded.ResultMeaning = 'Unknown'), 'No CVM performed is not successful CVM');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('1F0002'));
  Check(not Decoded.NoCvmPerformed and (Decoded.Rule.MethodMeaning = 'No CVM required') and
    (Decoded.ResultMeaning = 'Successful'), 'No CVM required differs from no CVM performed');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('420300'));
  Check((Decoded.Rule.MethodMeaning = 'Enciphered online PIN') and Decoded.Rule.ContinueOnFailure and
    (Decoded.ResultMeaning = 'Unknown') and Decoded.ResultKnown, 'Online PIN outcome is not inferred');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('010001'));
  Check(Decoded.ResultMeaning = 'Failed', 'Failure outcome');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('3F0102'));
  Check(Decoded.NoCvmPerformed and (Decoded.Rule.Condition = 1) and
    (Decoded.ResultMeaning = 'Successful'), 'Inconsistent terminal report preserved without repair');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('060002'), esv43);
  Check(not Decoded.Rule.MethodKnown, '4.3 result does not infer future biometric method');
  Decoded := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('060002'), esv44);
  Check(Decoded.Rule.MethodKnown and (Decoded.Rule.MethodMeaning = 'Offline facial biometric'), '4.4 biometric result');
  Writeln('PASS: All CVM result method/condition bytes, outcome encodings, flags and no-CVM sentinel.');
end;

procedure BoundsTests;
var
  I: Integer;
  Data: TBytes;
  Bits: TEmvBitMeanings;
  List: TEmvCvmList;
  CvmResult: TEmvCvmResult;
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
    if I <> 3 then
    begin
      Failed := False;
      try CvmResult := TEmvSemanticCodec.DecodeCvmResults(Data);
      except on EEmvSemanticError do Failed := True; end;
      Check(Failed, 'CVM result exact three-byte length');
      Failed := False;
      try Bits := TEmvSemanticCodec.DecodeBits($9F33, Data);
      except on EEmvSemanticError do Failed := True; end;
      Check(Failed, 'Terminal capabilities exact three-byte length');
    end;
    if I <> 5 then
    begin
      Failed := False;
      try Bits := TEmvSemanticCodec.DecodeBits($9F40, Data);
      except on EEmvSemanticError do Failed := True; end;
      Check(Failed, 'Additional capabilities exact five-byte length');
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
  CvmResult := TEmvSemanticCodec.DecodeCvmResults(HexToBytes('1F0002'));
  Check((Length(Bits) = 40) and (Length(List.Rules) = 1) and
    (CvmResult.ResultCode = 2), 'Independent outputs');
end;

begin
  try
    BitTests; CvmTests; TerminalTests; CvmResultTests; BoundsTests;
    Writeln('PASS: ', Assertions, ' EMV semantic assertions.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.Message); Halt(1); end;
  end;
end.
