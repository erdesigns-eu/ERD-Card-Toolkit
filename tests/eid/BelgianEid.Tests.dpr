program BelgianEidTests;

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
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Transport, ERD.Card.EID.Data, ERD.Card.EID.Reader;

type
  TStep = record
    Command: TBytes;
    Response: TBytes;
    Fail: Boolean;
  end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  private
    FSteps: array of TStep;
  public
    Position, Begins, Ends: Integer;
    BeginFails, EndFails, Active: Boolean;
    procedure Add(const ACommand, AResponse: string; const AFail: Boolean = False);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TBareTransport = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;

var
  Checks: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure TScript.Add(const ACommand, AResponse: string; const AFail: Boolean);
var
  I: Integer;
begin
  I := Length(FSteps);
  SetLength(FSteps, I + 1);
  FSteps[I].Command := HexToBytes(ACommand);
  FSteps[I].Response := HexToBytes(AResponse);
  FSteps[I].Fail := AFail;
end;

procedure TScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic begin failure');
  Check(not Active, 'No nested transaction');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Inc(Ends);
  Check(Active, 'Transaction active on release');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic end failure');
end;

function TScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(FSteps), 'No unexpected command or replay');
  Check(BytesEqual(ACommand, FSteps[Position].Command), 'Exact APDU at step ' + IntToStr(Position));
  Inc(Position);
  if FSteps[Position - 1].Fail then
    raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(FSteps[Position - 1].Response);
end;

function TBareTransport.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Bare transport must not be invoked');
end;

function Field(const ATag: Byte; const AValue: TBytes): TBytes;
var
  Count, Size, Offset, I: Integer;
begin
  Result := nil;
  Size := Length(AValue);
  Count := Size div 255;
  SetLength(Result, 2 + Count + Size);
  Result[0] := ATag;
  for I := 1 to Count do Result[I] := $FF;
  Result[Count + 1] := Byte(Size mod 255);
  Offset := Count + 2;
  for I := 0 to Size - 1 do Result[Offset + I] := AValue[I];
end;

procedure InvalidFile(const AHex: string);
var
  Data: TEidFileData;
  Raised: Boolean;
begin
  Raised := False;
  try
    Data := TBelgianEidCodec.DecodeFile(HexToBytes(AHex));
  except
    on E: EBelgianEidError do Raised := True;
  end;
  Check(Raised, 'Malformed simplified TLV rejected');
end;

procedure TestFields;
var
  Data: TEidFileData;
  Identity: TBelgianEidIdentity;
  Address: TBelgianEidAddress;
  Wire, Value, Getter: TBytes;
  I, Size: Integer;
begin
  Wire := HexToBytes('00020002010241420202FF0014007F03F0FF000000');
  Data := TBelgianEidCodec.DecodeFile(Wire);
  Check(Length(Data.Fields) = 5, 'Version and unknown fields preserved');
  Check(Data.EncodedLength = Length(Wire) - 2, 'Only trailing padding excluded');
  Check(Data.HasField($14) and (Length(Data.GetBytes($14)) = 0), 'Presence-only field');
  Check(not Data.HasField($15), 'Missing field distinct from empty');
  Check(Data.GetText(1) = 'AB', 'Text getter');
  Getter := Data.GetBytes(2);
  Getter[0] := 0;
  Wire[6] := 0;
  Check((Data.RawData[6] = Ord('A')) and (Data.Fields[2].Value[0] = $FF), 'Input/getter buffers copied');
  Data.RawData[6] := 0;
  Check(Data.GetText(1) = 'AB', 'Raw and decoded buffers independent');
  for Size := 254 to 511 do
  begin
    SetLength(Value, Size);
    for I := 0 to Size - 1 do Value[I] := Byte(I and $FF);
    Data := TBelgianEidCodec.DecodeFile(Field($7F, Value));
    Check(BytesEqual(Data.GetBytes($7F), Value), 'Additive lengths across 255 and 510');
  end;
  SetLength(Value, 32000);
  Data := TBelgianEidCodec.DecodeFile(Field($FF, Value));
  Check(Length(Data.GetBytes($FF)) = 32000, 'Large unknown field bounded and preserved');
  for I := 0 to 255 do
  begin
    if I = 0 then Wire := Field(0, HexToBytes('0002'))
    else
    begin
      Getter := Field(Byte(I), HexToBytes('AA'));
      Size := Length(Wire);
      SetLength(Wire, Size + Length(Getter));
      Move(Getter[0], Wire[Size], Length(Getter));
    end;
  end;
  Data := TBelgianEidCodec.DecodeFile(Wire);
  Check(Length(Data.Fields) = 256, 'All unique byte tags bounded');
  InvalidFile('');
  InvalidFile('0000');
  InvalidFile('01');
  InvalidFile('01FF');
  InvalidFile('01FF00AA');
  InvalidFile('0102AA');
  InvalidFile('010101010102');
  InvalidFile('010100000101');
  InvalidFile('010100000001');
  SetLength(Wire, EidMaxFileBytes + 1);
  InvalidFile(BytesToHex(Wire));
  SetLength(Wire, 130);
  Wire[0] := 1;
  for I := 1 to 129 do Wire[I] := $FF;
  InvalidFile(BytesToHex(Wire));
  Wire := HexToBytes('01034142430202FF00060B303031323334353637383907034AC3A90801410C04313938301102FF0014007F01FF');
  Identity := TBelgianEidCodec.DecodeIdentity(Wire);
  Check(Identity.CardNumber = 'ABC', 'Typed card number');
  Check(Identity.NationalNumber = '00123456789', 'National number leading zeroes');
  Check((Length(Identity.Surname) = 2) and (Ord(Identity.Surname[2]) = $E9), 'UTF-8 surname');
  Check(Identity.BirthDate = '1980', 'Partial birth date retained');
  Check(Identity.MemberOfFamily, 'Family presence boolean');
  Check((Identity.PhotoHash[0] = $FF) and (Identity.ChipNumber[0] = $FF), 'Binary values not text decoded');
  Check(Identity.Data.HasField($7F), 'Unknown binary identity tag preserved');
  Identity.ChipNumber[0] := 0;
  Check(Identity.Data.Fields[1].Value[0] = $FF, 'Typed binary value independent from fields');
  Address := TBelgianEidCodec.DecodeAddress(HexToBytes('00020002010A54657374737472616174020430313233030447656E740000'));
  Check((Address.StreetAndNumber = 'Teststraat') and (Address.PostalCode = '0123') and
    (Address.Municipality = 'Gent'), 'Typed address values');
  Writeln('PASS: simplified TLV, typed data and independent buffers.');
end;

procedure InvalidIdentity(const AHex: string);
var
  Identity: TBelgianEidIdentity;
  Raised: Boolean;
begin
  Raised := False;
  try
    Identity := TBelgianEidCodec.DecodeIdentity(HexToBytes(AHex));
  except
    on E: EBelgianEidError do Raised := True;
  end;
  Check(Raised, 'Invalid identity text/flag rejected');
end;

procedure TestUnicode;
var
  Identity: TBelgianEidIdentity;
  Data: TEidFileData;
  Wire: TBytes;
  I: Integer;
begin
  Identity := TBelgianEidCodec.DecodeIdentity(HexToBytes('070CC3A9E282ACF09F9880410042'));
  Check((Length(Identity.Surname) = 7) and (Ord(Identity.Surname[1]) = $E9) and
    (Ord(Identity.Surname[2]) = $20AC) and (Ord(Identity.Surname[3]) = $D83D) and
    (Ord(Identity.Surname[4]) = $DE00) and (Ord(Identity.Surname[6]) = 0), 'UTF-16 scalar decoding without trimming');
  Identity := TBelgianEidCodec.DecodeIdentity(HexToBytes('0707007FDFBFEFBFBF'));
  Check(Length(Identity.Surname) = 4, 'UTF-8 boundary scalars');
  InvalidIdentity('070180');
  InvalidIdentity('0702C080');
  InvalidIdentity('0702C1BF');
  InvalidIdentity('0703E08080');
  InvalidIdentity('0703EDA080');
  InvalidIdentity('0704F0808080');
  InvalidIdentity('0704F4908080');
  InvalidIdentity('0704F5808080');
  InvalidIdentity('0701FF');
  InvalidIdentity('0701C2');
  InvalidIdentity('0702E282');
  InvalidIdentity('0703F09F98');
  InvalidIdentity('0702C241');
  InvalidIdentity('1201FF'); // Optional known text must also be validated.
  InvalidIdentity('140100');
  for I := $80 to $BF do
  begin
    Wire := Field(7, HexToBytes('41'));
    Wire[2] := Byte(I);
    InvalidIdentity(BytesToHex(Wire));
  end;
  Data := TBelgianEidCodec.DecodeFile(HexToBytes('7F01FF'));
  Check(Data.HasField($7F), 'Unknown non-UTF8 data retained');
  Writeln('PASS: strict Unicode and optional identity field validation.');
end;

procedure InvalidCertificate(const AHex: string);
var
  Certificate: TEidCertificate;
  Raised: Boolean;
begin
  Raised := False;
  try
    Certificate := TBelgianEidCodec.DecodeCertificate(HexToBytes(AHex), eckSigning);
  except
    on E: EBelgianEidError do Raised := True;
  end;
  Check(Raised, 'Malformed certificate envelope rejected');
end;

procedure TestCertificates;
var
  Certificate: TEidCertificate;
  Wire: TBytes;
  I: Integer;
begin
  Wire := HexToBytes('3003020101000000'); // Synthetic envelope, no certificate/trust claim.
  Certificate := TBelgianEidCodec.DecodeCertificate(Wire, eckAuthentication);
  Check((Certificate.Kind = eckAuthentication) and (Certificate.State = ecsPresent), 'Certificate role/state');
  Check(BytesToHex(Certificate.DerData) = '3003020101', 'Zero padding removed using DER length');
  Check(BytesEqual(Certificate.RawData, Wire), 'Raw padded certificate preserved');
  Certificate.RawData[2] := 0;
  Wire[2] := 0;
  Check(Certificate.DerData[2] = 2, 'DER independent from input and raw');
  Certificate := TBelgianEidCodec.DecodeCertificate(HexToBytes('000000'), eckSigning);
  Check((Certificate.State = ecsEmpty) and (Length(Certificate.DerData) = 0), 'Unissued all-zero certificate');
  SetLength(Wire, 133);
  Wire[0] := $30;
  Wire[1] := $81;
  Wire[2] := $80;
  for I := 3 to 132 do Wire[I] := 0;
  Certificate := TBelgianEidCodec.DecodeCertificate(Wire, eckRootCa);
  Check(Length(Certificate.DerData) = 131, 'Long-form DER length');
  SetLength(Wire, 260);
  Wire[1] := $82;
  Wire[2] := 1;
  Wire[3] := 0;
  Certificate := TBelgianEidCodec.DecodeCertificate(Wire, eckRootCa);
  Check(Length(Certificate.DerData) = 260, 'Two-byte DER length');
  for I := 0 to Length(Wire) - 1 do
    InvalidCertificate(BytesToHex(Copy(Wire, 0, I)));
  InvalidCertificate('3000');
  InvalidCertificate('310102');
  InvalidCertificate('30800201010000');
  InvalidCertificate('30810100');
  InvalidCertificate('3082008000');
  InvalidCertificate('308301000000');
  InvalidCertificate('3082FFFF');
  InvalidCertificate('300202');
  InvalidCertificate('30010201');
  Writeln('PASS: certificate envelope bounds, minimal lengths and absent certificates.');
end;

procedure Applet(const AScript: TScript; const AStatus: string = '9000');
begin
  AScript.Add('00A4040C0F' + EidBelpicAidHex, AStatus);
end;

procedure SelectFile(const AScript: TScript; const ADirectory, AFile: Word;
  const AStatus: string = '9000');
begin
  AScript.Add('00A4020C023F00', '9000');
  AScript.Add('00A4020C02' + IntToHex(ADirectory, 4), '9000');
  AScript.Add('00A4020C02' + IntToHex(AFile, 4), AStatus);
end;

procedure FileBytes(const AScript: TScript; const ADirectory, AFile: Word;
  const AHex: string; const AChunk: Integer = 4);
var
  Wire: TBytes;
  Offset, Count: Integer;
  Command: string;
begin
  SelectFile(AScript, ADirectory, AFile);
  Wire := HexToBytes(AHex);
  Offset := 0;
  while Offset < Length(Wire) do
  begin
    Command := '00B0' + IntToHex(Offset, 4);
    Count := Length(Wire) - Offset;
    if Count > AChunk then Count := AChunk;
    if Count < AChunk then AScript.Add(Command + IntToHex(AChunk mod 256, 2), '6C' + IntToHex(Count, 2));
    AScript.Add(Command + IntToHex(Count mod 256, 2), BytesToHex(Copy(Wire, Offset, Count)) + '9000');
    Inc(Offset, Count);
  end;
  AScript.Add('00B0' + IntToHex(Offset, 4) + IntToHex(AChunk mod 256, 2), '6B00');
end;

procedure TestSnapshot;
var
  Script: TScript;
  Reader: TBelgianEIDReader;
  Data: TBelgianEidData;
begin
  Script := TScript.Create;
  Reader := TBelgianEIDReader.Create(nil);
  try
    Reader.Transport := Script;
    Reader.ChunkSize := 4;
    Check((Reader.MaxFileBytes = EidMaxFileBytes) and Reader.UseTransactions, 'Inactive constructor defaults');
    Applet(Script);
    FileBytes(Script, $DF01, $4031, '0103414243060B3030313233343536373839070241420000');
    FileBytes(Script, $DF01, $4033, '01045374722E020430313233030447656E740000');
    FileBytes(Script, $DF01, $4035, 'FFD8FFAABBCCDDEE');
    FileBytes(Script, $DF01, $4032, 'AABBCCDD');
    FileBytes(Script, $DF01, $4034, 'AABBCCDD0000');
    FileBytes(Script, $DF00, $5038, '30030201010000');
    FileBytes(Script, $DF00, $5039, '00000000');
    SelectFile(Script, $DF00, $503A, '6A82');
    FileBytes(Script, $DF00, $503B, '3003020101000000');
    FileBytes(Script, $DF00, $503C, '3003020101');
    Data := Reader.ReadCard([esIdentity, esAddress, esPhoto, esSignatures, esCertificates]);
    Check(Data.Sections = [esIdentity, esAddress, esPhoto, esSignatures, esCertificates], 'All groups complete');
    Check((Data.Identity.CardNumber = 'ABC') and (Data.Address.Municipality = 'Gent'), 'Snapshot typed data');
    Check(BytesToHex(Data.Photo) = 'FFD8FFAABBCCDDEE', 'Raw photo bytes');
    Check(BytesToHex(Data.AddressSignature) = 'AABBCCDD0000', 'Signature padding preserved');
    Check(Length(Data.Certificates) = 5, 'Five certificate roles');
    Check((Data.Certificates[0].State = ecsPresent) and (Data.Certificates[1].State = ecsEmpty) and
      (Data.Certificates[2].State = ecsMissing), 'Present, unissued and missing distinguished');
    Check((Script.Begins = 1) and (Script.Ends = 1) and not Script.Active, 'Whole snapshot in one transaction');
    Check(Script.Position = Length(Script.FSteps), 'All scripted commands consumed');
  finally
    Reader.Free;
  end;
  Writeln('PASS: complete eID read, file selection, offsets, correction and certificate states.');
end;

procedure ReadFails(const AReader: TBelgianEIDReader; const ASections: TEidSections;
  const AClass: ExceptClass; const AExpectedMessage: string = '');
var
  Data: TBelgianEidData;
  Raised: Boolean;
begin
  Raised := False;
  try
    Data := AReader.ReadCard(ASections);
  except
    on E: Exception do
    begin
      Raised := True;
      Check(E.ClassType = AClass, 'Correct failure class: ' + E.ClassName);
      if AExpectedMessage <> '' then Check(E.Message = AExpectedMessage, 'Primary error preserved');
    end;
  end;
  Check(Raised, 'Read must fail');
end;

procedure TestFailures;
var
  Reader: TBelgianEIDReader;
  Script: TScript;
  I: Integer;
  Raised: Boolean;
begin
  Reader := TBelgianEIDReader.Create(nil);
  try
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Reader.Transport := TBareTransport.Create;
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    ReadFails(Reader, [], EBelgianEidError);
    for I := 0 to 3 do
    begin
      Raised := False;
      try
        case I of
          0: Reader.ChunkSize := 0;
          1: Reader.ChunkSize := 257;
          2: Reader.MaxFileBytes := 0;
          3: Reader.MaxFileBytes := EidMaxFileBytes + 1;
        end;
      except
        on E: EBelgianEidError do Raised := True;
      end;
      Check(Raised, 'Configuration bounds');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.BeginFails := True;
    ReadFails(Reader, [esPhoto], ECardTransportError);
    Check((Script.Position = 0) and (Script.Ends = 0), 'Failed begin sends no command and no end');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script, '6A82');
    Script.EndFails := True;
    ReadFails(Reader, [esPhoto], EBelgianEidStatusError);
    Check((Script.Position = 1) and (Script.Ends = 1), 'Read failure releases transaction once');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A4040C0F' + EidBelpicAidHex, '', True);
    Script.EndFails := True;
    ReadFails(Reader, [esPhoto], ECardTransportError, 'synthetic exchange failure');
    Check(Script.Position = 1, 'No replay after transport failure');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A4040C0F' + EidBelpicAidHex, '90');
    ReadFails(Reader, [esPhoto], EApduFormatError);
    Check(Script.Ends = 1, 'Malformed APDU releases transaction');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    Script.Add('00A4020C023F00', '6A82');
    ReadFails(Reader, [esCertificates], EBelgianEidStatusError);
    Check(Script.Position = 2, 'Missing MF is not treated as missing certificate');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035, '6A82');
    ReadFails(Reader, [esPhoto], EBelgianEidStatusError);
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    FileBytes(Script, $DF01, $4035, 'FFD8FFAA', 248);
    Script.EndFails := True;
    ReadFails(Reader, [esPhoto], ECardTransportError, 'synthetic end failure');
    Check(Script.Ends = 1, 'Successful read propagates release failure');
  finally
    Reader.Free;
  end;
  Writeln('PASS: configuration, transaction failures, release and no replay.');
end;

procedure TestResponseLimits;
const
  Responses: array[0..9] of string = ('9000', '6B00', 'AA6B00', 'FFD8FFAAAA9000',
    '6C05', 'AA6C02', '6105', 'FF6982', '6282', '6982');
var
  Reader: TBelgianEIDReader;
  Script: TScript;
  Data: TBelgianEidData;
  I: Integer;
begin
  Reader := TBelgianEIDReader.Create(nil);
  try
    Reader.ChunkSize := 4;
    for I := Low(Responses) to High(Responses) do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      Applet(Script);
      SelectFile(Script, $DF01, $4035);
      Script.Add('00B0000004', Responses[I]);
      if (I = 1) or (I = 8) or (I = 9) then
        ReadFails(Reader, [esPhoto], EBelgianEidStatusError)
      else ReadFails(Reader, [esPhoto], EBelgianEidError);
      Check((Script.Position = 5) and (Script.Ends = 1), 'Malformed reply stops immediately');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000004', '6C02');
    Script.Add('00B0000002', '6C01');
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Check(Script.Position = 6, 'At most one correction per APDU');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    for I := 1 to 32 do
      if I = 1 then Script.Add('00B0000004', '6104')
      else Script.Add('00C0000004', '6104');
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Check(Script.Position = 36, 'GET RESPONSE cannot loop indefinitely');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000004', 'FF6103');
    Script.Add('00C0000003', '6C02');
    Script.Add('00C0000002', 'D8FF6101');
    Script.Add('00C0000001', 'AA9000');
    Script.Add('00B0000404', '6B00');
    Data := Reader.ReadCard([esPhoto]);
    Check(BytesToHex(Data.Photo) = 'FFD8FFAA', '61xx collection and GET RESPONSE correction');
    Check((Data.Sections = [esPhoto]) and (Length(Data.Certificates) = 0), 'Only requested sections returned');
    Reader.MaxFileBytes := 4;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000004', 'FFD8FFAA9000');
    Script.Add('00B0000401', '6B00');
    Data := Reader.ReadCard([esPhoto]);
    Check(Length(Data.Photo) = 4, 'Exact limit with EOF probe accepted');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000004', 'FFD8FFAA9000');
    Script.Add('00B0000401', 'AA9000');
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Reader.MaxFileBytes := EidMaxFileBytes;
    Reader.UseTransactions := False;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    FileBytes(Script, $DF01, $4035, 'FFD8FFAA');
    Data := Reader.ReadCard([esPhoto]);
    Check((Script.Begins = 0) and (Script.Ends = 0), 'Explicit caller serialization mode');
    Reader.ChunkSize := 256;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000000', '6C04');
    Script.Add('00B0000004', 'FFD8FFAA9000');
    Script.Add('00B0000400', '6B00');
    Data := Reader.ReadCard([esPhoto]);
    Check(Length(Data.Photo) = 4, 'Le 256 uses wire zero');
  finally
    Reader.Free;
  end;
  Writeln('PASS: read bounds, 61xx/6Cxx, EOF proof and caller serialization.');
end;

procedure TestLargeFilesAndPartialFailures;
var
  Reader: TBelgianEIDReader;
  Script: TScript;
  Data: TBelgianEidData;
  Block: TBytes;
  Offset, I: Integer;
begin
  Reader := TBelgianEIDReader.Create(nil);
  try
    Reader.ChunkSize := 256;
    SetLength(Block, 256);
    for I := 0 to 255 do Block[I] := $AA;
    Block[0] := $FF;
    Block[1] := $D8;
    Block[2] := $FF;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000000', '6C00');
    Script.Add('00B0000000', BytesToHex(Block) + '9000');
    Script.Add('00B0010000', '6B00');
    Data := Reader.ReadCard([esPhoto]);
    Check((Length(Data.Photo) = 256) and (Script.Position = 7), '6C00 correction means 256');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    for I := 0 to 126 do
      Script.Add('00B0' + IntToHex(I * 256, 4) + '00', BytesToHex(Block) + '9000');
    Script.Add('00B07F0000', '6CFF');
    Script.Add('00B07F00FF', BytesToHex(Copy(Block, 0, 255)) + '9000');
    Script.Add('00B07FFF01', '6B00');
    Data := Reader.ReadCard([esPhoto]);
    Check(Length(Data.Photo) = 32767, 'Largest provably complete 15-bit file accepted');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    for I := 0 to 127 do
    begin
      Offset := I * 256;
      Script.Add('00B0' + IntToHex(Offset, 4) + '00', BytesToHex(Block) + '9000');
    end;
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Check((Script.Position = 132) and (Script.Ends = 1), '32768-byte file rejected before offset bit 8 would be set');
    Reader.ChunkSize := 4;
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    FileBytes(Script, $DF01, $4031, '01024142');
    SelectFile(Script, $DF01, $4033, '6982');
    ReadFails(Reader, [esIdentity, esAddress], EBelgianEidStatusError);
    Check(Script.Ends = 1, 'Later file failure still releases whole read');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    FileBytes(Script, $DF01, $4031, '0702C080');
    ReadFails(Reader, [esIdentity, esAddress], EBelgianEidError);
    Check(Script.Position = 6, 'Invalid identity aborts before address selection');
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    FileBytes(Script, $DF01, $4035, 'FF');
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Script := TScript.Create;
    Reader.Transport := Script;
    Applet(Script);
    SelectFile(Script, $DF01, $4035);
    Script.Add('00B0000004', '6C02');
    Script.Add('00B0000002', '6104');
    ReadFails(Reader, [esPhoto], EBelgianEidError);
    Check(Script.Position = 6, 'Corrected READ BINARY bounds its whole response');
  finally
    Reader.Free;
  end;
  Writeln('PASS: 15-bit offsets, Le 256 and failures after partial reads.');
end;

begin
  try
    TestFields;
    TestUnicode;
    TestCertificates;
    TestSnapshot;
    TestFailures;
    TestResponseLimits;
    TestLargeFilesAndPartialFailures;
    Writeln('PASS: ', Checks, ' assertions across seven eID test groups.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
