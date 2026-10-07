program IcaoTests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.TLV, ERD.Card.EID.MRZ, ERD.Card.EID.ICAO;

const
  TD1: UnicodeString = 'I<UTOD231458907<<<<<<<<<<<<<<<' +
    '7408122F1204159UTO<<<<<<<<<<<6' + 'ERIKSSON<<ANNA<MARIA<<<<<<<<<<';
  TD2: UnicodeString = 'I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<' + 'D231458907UTO7408122F1204159<<<<<<<6';
  TD3: UnicodeString = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<' +
    'L898902C36UTO7408122F1204159ZE184226B<<<<<10';
var
  Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

procedure InvalidMrz(const AText: UnicodeString);
var
  Identity: TMrzIdentity;
  Raised: Boolean;
begin
  Raised := False;
  try Identity := TMrzCodec.Decode(AText);
  except on E: EMrzError do Raised := True; end;
  Check(Raised, 'Invalid MRZ rejected');
end;

function Wrap(const ATag: string; const AValue: TBytes): TBytes;
var
  Node: TTlvNode;
begin
  Node := TTlvNode.CreatePrimitive(HexToBytes(ATag), AValue);
  try Result := TTlvCodec.EncodeNode(Node); finally Node.Free; end;
end;

function Container(const ATag: string; const AContent: string): TBytes;
var
  LengthHex: string;
  Size: Integer;
begin
  Size := Length(AContent) div 2;
  if Size < 128 then LengthHex := IntToHex(Size, 2)
  else if Size < 256 then LengthHex := '81' + IntToHex(Size, 2)
  else LengthHex := '82' + IntToHex(Size, 4);
  Result := HexToBytes(ATag + LengthHex + AContent);
end;

function Ascii(const AText: UnicodeString): TBytes;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(AText));
  for I := 1 to Length(AText) do Result[I - 1] := Ord(AText[I]);
end;

procedure TestMrz;
var
  Identity: TMrzIdentity;
  Text, Optional, Line1, Line2: UnicodeString;
  I: Integer;
begin
  Check((Length(TD1) = 90) and (Length(TD2) = 72) and (Length(TD3) = 88), 'Published ICAO fixture dimensions');
  Check(TMrzCodec.CheckDigit('L898902C3') = '6', 'Published document check digit');
  Identity := TMrzCodec.Decode(TD1);
  Check((Identity.Format = mfTD1) and (Identity.DocumentNumber = 'D23145890'), 'TD1 document');
  Check((Identity.Surname = 'ERIKSSON') and (Identity.GivenNames = 'ANNA MARIA'), 'MRZ name transliteration');
  Check((Identity.BirthDate = '740812') and (Identity.ExpiryDate = '120415'), 'Dates remain century-free');
  Identity := TMrzCodec.Decode(TD2);
  Check(Identity.Format = mfTD2, 'TD2 layout');
  Identity := TMrzCodec.Decode(TD3);
  Check((Identity.Format = mfTD3) and (Identity.DocumentNumber = 'L898902C3'), 'TD3 layout');
  Identity := TMrzCodec.Decode(Copy(TD1, 1, 30) + #13#10 + Copy(TD1, 31, 30) + #13#10 + Copy(TD1, 61, 30));
  Check(Identity.Raw = TD1, 'CR/LF presentation separators');
  for I := 1 to Length(TD3) - 1 do InvalidMrz(Copy(TD3, 1, I));
  InvalidMrz('');
  InvalidMrz(LowerCase(TD1));
  InvalidMrz(' ' + Copy(TD1, 2, Length(TD1)));
  for I := 1 to 5 do
  begin
    Text := TD3;
    case I of
      1: Text[54] := '0';
      2: Text[64] := '0';
      3: Text[72] := '0';
      4: Text[87] := '0';
      5: Text[88] := '1';
    end;
    InvalidMrz(Text);
  end;
  Optional := '123' + TMrzCodec.CheckDigit('D23145890' + '123') + '<<<<<<<<<<<';
  Line1 := 'I<UTO' + 'D23145890' + '<' + Optional;
  Line2 := Copy(TD1, 31, 29);
  Line2 := Line2 + TMrzCodec.CheckDigit(Copy(Line1, 6, 25) + Copy(Line2, 1, 7) +
    Copy(Line2, 9, 7) + Copy(Line2, 19, 11));
  Identity := TMrzCodec.Decode(Line1 + Line2 + Copy(TD1, 61, 30));
  Check(Identity.DocumentNumber = 'D23145890123', 'TD1 long document number extension');
  Text := Line1 + Line2 + Copy(TD1, 61, 30);
  Text[19] := '0';
  InvalidMrz(Text);
  Optional := '123' + TMrzCodec.CheckDigit('D23145890123') + '<<<';
  Line2 := 'D23145890<' + Copy(TD2, 47, 18) + Optional;
  Line2 := Line2 + TMrzCodec.CheckDigit(Copy(Line2, 1, 10) + Copy(Line2, 14, 7) + Copy(Line2, 22, 14));
  Identity := TMrzCodec.Decode(Copy(TD2, 1, 36) + Line2);
  Check(Identity.DocumentNumber = 'D23145890123', 'TD2 long document number extension');
  Text := TD1;
  Text[4] := '0';
  InvalidMrz(Text);
  Text := TD1;
  Text[61] := '9';
  InvalidMrz(Text);
  Writeln('PASS: TD1/TD2/TD3, check digits, extended numbers and exact date codes.');
end;

procedure InvalidGroup(const ABytes: TBytes; const ADG1: Boolean);
var
  Biometrics: TIcaoBiometrics;
  Identity: TMrzIdentity;
  Raised: Boolean;
begin
  Raised := False;
  try
    if ADG1 then Identity := TIcaoDataCodec.DecodeDG1(ABytes)
    else Biometrics := TIcaoDataCodec.DecodeDG2(ABytes);
  except
    on E: EIcaoDataError do Raised := True;
    on E: ETlvFormatError do Raised := True;
    on E: EMrzError do Raised := True;
  end;
  Check(Raised, 'Invalid ICAO group rejected');
end;

function DG2(const AFace: TBytes; const ACount: Byte = 1;
  const AOwner: string = '0101'; const ABlockTag: string = '5F2E'): TBytes;
var
  Header, Template, Group, Block: TBytes;
begin
  Header := Container('A1', '8702' + AOwner + '88020008');
  if ABlockTag = '5F2E' then Block := Wrap(ABlockTag, AFace)
  else Block := Container(ABlockTag, BytesToHex(AFace));
  Template := Container('7F60', BytesToHex(Header) + BytesToHex(Block));
  Group := Container('7F61', '0201' + IntToHex(ACount, 2) + BytesToHex(Template));
  Result := Container('75', BytesToHex(Group));
end;

procedure TestGroups;
var
  Identity: TMrzIdentity;
  Biometrics: TIcaoBiometrics;
  Wire, Face, Damaged: TBytes;
  I: Integer;
begin
  Wire := Container('61', BytesToHex(Wrap('5F1F', Ascii(TD1))));
  Identity := TIcaoDataCodec.DecodeDG1(Wire);
  Check(Identity.Raw = TD1, 'DG1 exact MRZ');
  for I := 0 to Length(Wire) - 1 do InvalidGroup(Copy(Wire, 0, I), True);
  InvalidGroup(Container('61', '5F1F00'), True);
  InvalidGroup(Container('61', BytesToHex(Wrap('5F1F', Ascii(TD1))) + '5F1F00'), True);
  Face := HexToBytes('4641430030313000000000320001' +
    '0000002400000000000000000000000000000000' + '0000009600C3000000000000' + 'FFD8FFAA');
  Check(Length(Face) = 50, 'Synthetic FAC record dimensions');
  Wire := DG2(Face);
  Biometrics := TIcaoDataCodec.DecodeDG2(Wire);
  Check((Length(Biometrics.Images) = 1) and Biometrics.Blocks[0].ImagesDecoded, 'Supported FAC image');
  Check((Biometrics.Images[0].Format = iffJpeg) and (Biometrics.Images[0].Width = 150) and
    (Biometrics.Images[0].Height = 195), 'Image encoding and dimensions');
  Check(BytesToHex(Biometrics.Images[0].Data) = 'FFD8FFAA', 'Image payload extracted');
  Wire[0] := 0;
  Face[46] := 0;
  Biometrics.RawData[Length(Biometrics.RawData) - 4] := 0;
  Check(Biometrics.Images[0].Data[0] = $FF, 'Independent image buffers');
  Face[46] := $FF;
  Face[35] := 1;
  Biometrics := TIcaoDataCodec.DecodeDG2(DG2(Face));
  Check(Biometrics.Images[0].Format = iffJpeg2000, 'JPEG 2000 declared type preserved');
  Face[35] := 0;
  Wire := DG2(Face);
  for I := 0 to Length(Wire) - 1 do InvalidGroup(Copy(Wire, 0, I), False);
  for I := 1 to 7 do
  begin
    Damaged := CopyBytes(Face);
    case I of
      1: Damaged[0] := 0;
      2: Damaged[7] := 1;
      3: Damaged[11] := 49;
      4: Damaged[13] := 17;
      5: Damaged[19] := 35;
      6: Damaged[19] := 255;
      7: Damaged[35] := 2;
    end;
    InvalidGroup(DG2(Damaged), False);
  end;
  InvalidGroup(DG2(Face, 2), False);
  Biometrics := TIcaoDataCodec.DecodeDG2(DG2(HexToBytes('AA'), 1, '9999'));
  Check((Length(Biometrics.Images) = 0) and not Biometrics.Blocks[0].ImagesDecoded,
    'Unknown biometric format retained without invented image');
  Biometrics := TIcaoDataCodec.DecodeDG2(DG2(HexToBytes('020101'), 1, '0101', '7F2E'));
  Check((Length(Biometrics.Images) = 0) and (Length(Biometrics.Blocks[0].EncodedData) > 0),
    'ISO 39794 block preserved separately from ISO 19794');
  SetLength(Wire, IcaoMaxDataGroupBytes + 1);
  InvalidGroup(Wire, False);
  Writeln('PASS: DG1/DG2, bounded CBEFF/FAC, encoded photos and unsupported formats.');
end;

begin
  try
    TestMrz;
    TestGroups;
    Writeln('PASS: ', Checks, ' assertions across two ICAO test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
