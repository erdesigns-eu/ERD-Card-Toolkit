program RfidInputTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$APPTYPE CONSOLE}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.RFID.Input, ERD.Card.RFID.HID;

type
  TObserver = class
  public
    Count: Integer;
    Text: UnicodeString;
    Reenter, RaiseEvent: Boolean;
    procedure Identified(Sender: TObject; const D: TRfidInputIdentifier);
  end;

var Checks: Integer;

procedure Check(const V: Boolean; const Why: string);
begin Inc(Checks); if not V then raise Exception.Create(Why); end;

procedure TObserver.Identified(Sender: TObject; const D: TRfidInputIdentifier);
var B: TBytes; Caught: Boolean;
begin
  Inc(Count); Text := D.Text;
  B := D.Bytes; if Length(B) > 0 then B[0] := $EE;
  if Reenter then
  begin
    Caught := False;
    try TRfidHidReportReader(Sender).FeedReport(HexToBytes('00001E0000000000'),0);
    except on ERfidInputError do Caught := True; end;
    Check(Caught,'Recursive report input must fail before state changes');
  end;
  if RaiseEvent then raise Exception.Create('Consumer failure');
end;

procedure Feed(const R: TRfidKeyboardReader; const S: UnicodeString; const Time: UInt64 = 0);
var I: Integer;
begin for I := 1 to Length(S) do R.FeedCharacter(S[I],Time); end;

procedure CodecTests;
var D: TRfidInputIdentifier; B: TBytes; I, V: Integer; Failed: Boolean;
begin
  D := TRfidInputCodec.Decode('000123',rieDecimal,6);
  Check((D.Text = '000123') and (Length(D.Bytes) = 0),'Decimal leading zeros');
  Check(BytesToHex(TRfidInputCodec.ToBytes(D,2,ribBigEndian)) = '007B','Decimal width');
  Check(BytesToHex(TRfidInputCodec.ToBytes(D,2,ribLittleEndian)) = '7B00','Explicit little endian');
  D := TRfidInputCodec.Decode('18446744073709551615',rieDecimal);
  Check(BytesToHex(TRfidInputCodec.ToBytes(D,8,ribBigEndian)) = 'FFFFFFFFFFFFFFFF','64 bit max');
  D := TRfidInputCodec.Decode('18446744073709551616',rieDecimal);
  Failed := False; try B := TRfidInputCodec.ToBytes(D,8,ribBigEndian); except on ERfidInputError do Failed := True; end;
  Check(Failed,'64 bit overflow');
  Check(BytesToHex(TRfidInputCodec.ToBytes(D,9,ribBigEndian)) = '010000000000000000','Beyond UInt64');
  D := TRfidInputCodec.Decode('00abCD',rieHexadecimal);
  D.Bytes[0] := $FF;
  Check(BytesToHex(TRfidInputCodec.ToBytes(D,3,ribBigEndian)) = '00ABCD','Revalidate text, not Bytes');
  for V := 0 to 65535 do
  begin
    D := TRfidInputCodec.Decode(UnicodeString(IntToStr(V)),rieDecimal);
    B := TRfidInputCodec.ToBytes(D,2,ribBigEndian);
    Check((B[0] = V div 256) and (B[1] = V mod 256),'Decimal two-byte exhaustive');
  end;
  for I := 0 to 7 do
  begin
    Failed := False;
    try
      case I of
        0: D := TRfidInputCodec.Decode('',rieAscii);
        1: D := TRfidInputCodec.Decode('abc',rieHexadecimal);
        2: D := TRfidInputCodec.Decode('GG',rieHexadecimal);
        3: D := TRfidInputCodec.Decode('123 ',rieDecimal);
        4: D := TRfidInputCodec.Decode('+1',rieDecimal);
        5: D := TRfidInputCodec.Decode('123',rieDecimal,4);
        6: D := TRfidInputCodec.Decode(#0,rieAscii);
        7: begin D := TRfidInputCodec.Decode('card',rieAscii); B := TRfidInputCodec.ToBytes(D,4,ribBigEndian); end;
      end;
    except on ERfidInputError do Failed := True; end;
    Check(Failed,'Strict text refusal');
  end;
end;

procedure FramingTests;
var R: TRfidKeyboardReader; O: TObserver; D: TRfidInputIdentifier;
  T: TRfidInputTerminator; EndText: UnicodeString; Failed: Boolean; I: Integer;
begin
  O := TObserver.Create; R := TRfidKeyboardReader.Create(nil);
  try
    Check(not R.Active,'Inactive construction');
    R.Encoding := rieHexadecimal; R.Prefix := '['; R.Suffix := ']'; R.ExpectedCharacters := 4;
    R.OnIdentifier := O.Identified;
    for T := Low(TRfidInputTerminator) to High(TRfidInputTerminator) do
    begin
      R.Terminator := T; R.Start;
      case T of ritCr: EndText := #13; ritCrLf: EndText := #13#10; ritLf: EndText := #10; ritTab: EndText := #9; end;
      Feed(R,'[00ab]' + EndText);
      Check(O.Text = '00ab','Exact prefix/suffix');
      D := R.LastIdentifier; Check(BytesToHex(D.Bytes) = '00AB','Event has independent bytes');
      D.Bytes[0] := $FF; D := R.LastIdentifier;
      Check(BytesToHex(D.Bytes) = '00AB','Getter has independent bytes');
      Failed := False; try R.Encoding := rieDecimal; except on ERfidInputError do Failed := True; end;
      Check(Failed,'Active config frozen');
      R.Stop;
    end;
    R.Prefix := ''; R.Suffix := ''; R.ExpectedCharacters := 0; R.Encoding := rieDecimal;
    R.Terminator := ritCr; R.MaxCharacters := 3; R.Start;
    Feed(R,'123'); Failed := False;
    try R.FeedCharacter('4',0); except on ERfidInputError do Failed := True; end;
    Check(Failed,'Frame overflow'); I := O.Count;
    Feed(R,'56'#13); Check(O.Count = I,'Overflow tail never accepted');
    Feed(R,'12'#13); Check(O.Count = I + 1,'Capture resumes after delimiter');
    Feed(R,'1',100); Failed := False;
    try R.FeedCharacter('2',601); except on ERfidInputTimeout do Failed := True; end;
    Check(Failed,'Deadline'); I := O.Count;
    Feed(R,'3'#13,602); Check(O.Count = I,'Late tail discarded');
    Feed(R,'1',1000); Failed := False;
    try R.FeedCharacter('2',999); except on ERfidInputError do Failed := True; end;
    Check(Failed,'Clock reversal'); Feed(R,#13,1001);
    Feed(R,'8'#13,1002); Check(O.Text = '8','Fresh scan after reversed clock');
    R.Stop; R.Terminator := ritCrLf; R.Start;
    Feed(R,'12'#13); Failed := False;
    try R.FeedCharacter('3',0); except on ERfidInputError do Failed := True; end;
    Check(Failed,'CRLF exact sequence'); I := O.Count;
    Feed(R,'4'#13#10); Check(O.Count = I,'Malformed CRLF tail discarded');
    Feed(R,'98'#13#10); Check(O.Text = '98','Valid CRLF after discarded scan');
    O.RaiseEvent := True; Failed := False;
    try Feed(R,'77'#13#10); except on Exception do Failed := True; end;
    Check(Failed,'Event failure propagates'); I := O.Count; O.RaiseEvent := False;
    Feed(R,'66'#13#10); Check(O.Count = I + 1,'No event replay');
    R.Stop; R.Stop;
  finally R.Free; O.Free; end;
end;

function Report(const Key: Byte; const Modifier: Byte = 0): TBytes;
begin Result := HexToBytes('0000000000000000'); Result[0] := Modifier; Result[2] := Key; end;

procedure HidTests;
var S, Before: TRfidHidKeyboardState; B: TBytes; Text: UnicodeString;
  I: Integer; Failed: Boolean; Field: TRfidHidAsciiField;
  R: TRfidHidReportReader; O: TObserver;
begin
  S := Default(TRfidHidKeyboardState);
  Check(TRfidHidCodec.DecodeKeyboard(Report($1E),False,0,S) = '1','Literal boot key');
  Check(TRfidHidCodec.DecodeKeyboard(Report($1E),False,0,S) = '','Held key suppressed');
  Check(TRfidHidCodec.DecodeKeyboard(Report(0),False,0,S) = '','Release');
  Check(TRfidHidCodec.DecodeKeyboard(Report($04,$02),False,0,S) = 'A','Shift');
  Text := TRfidHidCodec.DecodeKeyboard(Report(0),False,0,S);
  Text := TRfidHidCodec.DecodeKeyboard(Report($39),False,0,S);
  Check(S.CapsLock,'Caps lock toggle'); Text := TRfidHidCodec.DecodeKeyboard(Report(0),False,0,S);
  Check(TRfidHidCodec.DecodeKeyboard(Report($04),False,0,S) = 'A','Explicit caps');
  Text := TRfidHidCodec.DecodeKeyboard(Report(0),False,0,S);
  Check(TRfidHidCodec.DecodeKeyboard(Report($59),False,0,S) = '1','Keypad');
  for I := 0 to 9 do
  begin
    B := Report($1E); Before := S;
    case I of
      0: B[0] := $01;
      1: B[1] := 1;
      2: B[2] := 1;
      3: B[2] := 2;
      4: B[2] := 3;
      5: B[3] := B[2];
      6: B[3] := $1F;
      7: B[2] := $E0;
      8: B[2] := $65;
      9: SetLength(B,7);
    end;
    Failed := False;
    try Text := TRfidHidCodec.DecodeKeyboard(B,False,0,S); except on ERfidInputError do Failed := True; end;
    Check(Failed,'Malformed HID report');
    Check(CompareMem(@S,@Before,SizeOf(S)),'Malformed state unchanged');
  end;
  S := Default(TRfidHidKeyboardState);
  B := HexToBytes('0700001E0000000000');
  Check(TRfidHidCodec.DecodeKeyboard(B,True,7,S) = '1','Explicit report ID');
  Failed := False; try Text := TRfidHidCodec.DecodeKeyboard(B,True,8,S); except on ERfidInputError do Failed := True; end;
  Check(Failed,'Wrong report ID');
  Field := Default(TRfidHidAsciiField); Field.ReportBytes := 9; Field.Offset := 1;
  Field.FieldBytes := 8; Field.HasReportId := True; Field.ReportId := 7;
  B := HexToBytes('073030313233340000');
  Check(TRfidHidCodec.DecodeAsciiField(B,Field) = '001234','Declared ASCII field');
  B[2] := 0; Failed := False;
  try Text := TRfidHidCodec.DecodeAsciiField(B,Field); except on ERfidInputError do Failed := True; end;
  Check(Failed,'Internal NUL refused');
  R := TRfidHidReportReader.Create(nil); O := TObserver.Create;
  try
    R.Encoding := rieDecimal; R.OnIdentifier := O.Identified; R.Start;
    R.FeedReport(Report($1E),0); R.FeedReport(Report($1E),0); R.FeedReport(Report(0),0);
    R.FeedReport(Report($1F),0); R.FeedReport(Report(0),0); R.FeedReport(Report($28),0);
    Check((O.Count = 1) and (O.Text = '12'),'Boot report scan');
    R.FeedReport(Report(0),0); R.FeedReport(Report($1E),0);
    B := Report(1); Failed := False;
    try R.FeedReport(B,0); except on ERfidInputError do Failed := True; end;
    Check(Failed,'Adapter malformed report');
    R.FeedReport(Report(0),0); R.FeedReport(Report($1F),0); R.FeedReport(Report(0),0); R.FeedReport(Report($28),0);
    Check(O.Count = 1,'Lost report tail discarded');
    R.Stop; R.ReportKind := rhkAsciiField; R.AsciiField := Field; R.Encoding := rieHexadecimal; R.Start;
    O.Reenter := True;
    R.FeedReport(HexToBytes('073030414243440000'),0);
    Check((O.Count = 2) and (O.Text = '00ABCD'),'Hex fixed report');
    Check(BytesToHex(R.LastIdentifier.Bytes) = '00ABCD','Report event bytes independent');
    O.Reenter := False; R.Stop; R.Encoding := rieDecimal; R.Start;
    R.FeedReport(HexToBytes('073030313233340000'),0);
    Check(O.Text = '001234','Decimal fixed report');
    R.Stop; R.Encoding := rieAscii; R.Start;
    R.FeedReport(HexToBytes('076361726430310000'),0);
    Check((O.Text = 'card01') and (Length(R.LastIdentifier.Bytes) = 0),'ASCII fixed report');
  finally R.Free; O.Free; end;
end;

begin
  try CodecTests; FramingTests; HidTests;
    Writeln('PASS: ',Checks,' RFID input/profile assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
