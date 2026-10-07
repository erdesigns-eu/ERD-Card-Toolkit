program EmvTests;

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
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.TLV, ERD.Card.Transport,
  ERD.Card.EMV.Data, ERD.Card.EMV.Reader;

type
  TStep = record
    Command, Response: TBytes;
    Fails: Boolean;
  end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    Active, EndFails, BeginFails: Boolean;
    procedure Add(const ACommand, AResponse: string; const AFails: Boolean = False);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TBareTransport = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;

const
  AidHex = 'A0000000031010'; // Public scheme AID; no physical account/card fixture.
  SelectHex = '00A4040007' + AidHex + '00';
var
  Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

procedure TScript.Add(const ACommand, AResponse: string; const AFails: Boolean);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Command := HexToBytes(ACommand);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Fails := AFails;
end;

procedure TScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic begin failure');
  Check(not Active, 'Exclusive transaction is not nested');
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
  Check(Position < Length(Steps), 'No unexpected APDU or replay');
  Check(BytesEqual(ACommand, Steps[Position].Command), 'Exact APDU at step ' + IntToStr(Position));
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

function TBareTransport.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Bare transport must not be invoked');
end;

function Tlv(const ATag, ABody: string): string;
var N: Integer;
begin
  N := Length(ABody) div 2;
  if N < 128 then Result := ATag + IntToHex(N, 2) + ABody
  else Result := ATag + '81' + IntToHex(N, 2) + ABody;
end;

function Fci(const ADol: string = ''): string;
var Body: string;
begin
  Body := '500454455354';
  if ADol <> '' then Body := Body + Tlv('9F38', ADol);
  Result := Tlv('6F', '8407' + AidHex + Tlv('A5', Body));
end;

function Value(const ATag, AData: string): TEmvValue;
begin
  Result.Tag := HexToBytes(ATag);
  Result.Value := HexToBytes(AData);
end;

procedure TestDol;
var
  Values: TEmvValues;
  Entries: TEmvDolEntries;
  Wire, Dol: TBytes;
  I: Integer;
  Raised: Boolean;
begin
  Check(BytesToHex(TEmvCodec.BuildDolData(nil, nil)) = '8300', 'Absent PDOL produces 8300');
  Entries := TEmvCodec.DecodeDol(HexToBytes('9F02069F37049F02069F1A00'));
  Check((Length(Entries) = 4) and (Entries[3].Size = 0), 'Repeated and empty DOL requests');
  SetLength(Values, 2);
  Values[0] := Value('9F02', '000000000000');
  Values[1] := Value('9F37', '01020304');
  Wire := TEmvCodec.BuildDolData(HexToBytes('9F02069F37049F0206'), Values);
  Check(BytesToHex(Wire) = '831000000000000001020304000000000000', 'PDOL order and exact supplied bytes');
  for I := 0 to 5 do
  begin
    Raised := False;
    try
      case I of
        0: Entries := TEmvCodec.DecodeDol(HexToBytes('9F02'));
        1: Entries := TEmvCodec.DecodeDol(HexToBytes('9F800101'));
        2: Entries := TEmvCodec.DecodeDol(HexToBytes('0001'));
        3: Entries := TEmvCodec.DecodeDol(HexToBytes('A501'));
        4: Wire := TEmvCodec.BuildDolData(HexToBytes('9F0306'), Values);
        5: Wire := TEmvCodec.BuildDolData(HexToBytes('9F0205'), Values);
      end;
    except on E: EEmvDataError do Raised := True; end;
    Check(Raised, 'Malformed/missing PDOL input rejected');
  end;
  Values[1] := Values[0];
  Raised := False;
  try Wire := TEmvCodec.BuildDolData(HexToBytes('9F0206'), Values);
  except on E: EEmvDataError do Raised := True; end;
  Check(Raised, 'Duplicate terminal values rejected');
  SetLength(Values, 1);
  Values[0].Tag := HexToBytes('9F02');
  for I := 127 to 252 do
  begin
    SetLength(Values[0].Value, I);
    Dol := HexToBytes('9F02' + IntToHex(I, 2));
    Wire := TEmvCodec.BuildDolData(Dol, Values);
    if I = 127 then Check((Length(Wire) = 129) and (Wire[1] = 127), 'Short BER 83 length')
    else Check((Length(Wire) = I + 3) and (Wire[1] = $81) and (Wire[2] = I), 'Long BER 83 length within short Lc');
  end;
  Raised := False;
  try Wire := TEmvCodec.BuildDolData(HexToBytes('9F02FD'), Values);
  except on E: EEmvDataError do Raised := True; end;
  Check(Raised, 'Oversized GPO rejected');
  Writeln('PASS: PDOL tags, exact values, order and 83 length boundaries.');
end;

procedure TestAflAndFields;
const
  BadAfl: array[0..7] of string = ('0801', '09010100', '00010100', 'F8010100',
    '08000100', '08020100', '08010102', '0801020008020300');
var
  Afl: TEmvAfl;
  Data: TEmvApplicationData;
  I: Integer;
  Raised: Boolean;
begin
  Afl := TEmvCodec.DecodeAfl(HexToBytes('08010201F0FEFF00'));
  Check((Length(Afl) = 2) and (Afl[1].Sfi = 30) and (Afl[1].LastRecord = 255), 'AFL file/record boundaries');
  for I := Low(BadAfl) to High(BadAfl) do
  begin
    Raised := False;
    try Afl := TEmvCodec.DecodeAfl(HexToBytes(BadAfl[I]));
    except on E: EEmvDataError do Raised := True; end;
    Check(Raised, 'Bad AFL rejected');
  end;
  Raised := False;
  try Afl := TEmvCodec.DecodeAfl(HexToBytes('08010300'), 2);
  except on E: EEmvDataError do Raised := True; end;
  Check(Raised, 'AFL cumulative limit before reads');
  Data := Default(TEmvApplicationData);
  SetLength(Data.Fields, 3);
  Data.Fields[0] := Value('5A', '000000000000001F');
  Data.Fields[1] := Value('5F24', '251231');
  Data.Fields[2] := Value('5F20', '4AE9');
  TEmvCodec.DecodeCardFields(Data);
  Check(Data.Pan = '000000000000001', 'PAN leading zeroes and single nibble padding');
  Check(Data.ExpiryDate = '251231', 'Century-free expiry');
  Check((Length(Data.CardholderName) = 2) and (Ord(Data.CardholderName[2]) = $E9), 'ISO-8859-1 name');
  Check((Data.Iban = '') and (Length(Data.Track2Equivalent) = 0), 'Bank fields optional');
  SetLength(Data.Fields, 4);
  Data.Fields[3] := Data.Fields[0];
  TEmvCodec.DecodeCardFields(Data);
  Data.Fields[3] := Value('5A', '1234');
  Raised := False;
  try TEmvCodec.DecodeCardFields(Data);
  except on E: EEmvDataError do Raised := True; end;
  Check(Raised, 'Conflicting repeated PAN rejected');
  for I := 0 to 9 do
  begin
    SetLength(Data.Fields, 1);
    case I of
      0: Data.Fields[0] := Value('5A', '12F3');
      1: Data.Fields[0] := Value('5A', '12345678901234567890');
      2: Data.Fields[0] := Value('5F24', '2500');
      3: Data.Fields[0] := Value('5F24', '25FF31');
      4: Data.Fields[0] := Value('5F53', '4245');
      5: Data.Fields[0] := Value('5F53', '30303030303030303030303030303030');
      6: Data.Fields[0] := Value('57', '12D2512101FD');
      7: Data.Fields[0] := Value('57', '12D25F');
      8: Data.Fields[0] := Value('57', '12D2512D01');
      9: Data.Fields[0] := Value('57', '12342512101F');
    end;
    Raised := False;
    try TEmvCodec.DecodeCardFields(Data);
    except on E: EEmvDataError do Raised := True; end;
    Check(Raised, 'Malformed known card fields rejected');
  end;
  Data.Fields[0] := Value('57', '0000000000000000D2512101');
  TEmvCodec.DecodeCardFields(Data);
  Check((Data.Pan = '0000000000000000') and (Data.ExpiryMonth = '2512') and
    (Data.ExpiryDate = '') and (Data.ServiceCode = '101'), 'Track 2-only account data does not invent expiry day');
  SetLength(Data.Fields, 2);
  Data.Fields[1] := Value('5A', '1234');
  Raised := False;
  try TEmvCodec.DecodeCardFields(Data);
  except on E: EEmvDataError do Raised := True; end;
  Check(Raised, 'PAN/Track 2 source disagreement rejected');
  Writeln('PASS: AFL validation and optional account-field encoding.');
end;

procedure ReadFails(const AReader: TEMVCardReader; const AClass: ExceptClass;
  const AMessage: string = '');
var
  Data: TEmvApplicationData;
  Raised: Boolean;
begin
  Raised := False;
  try Data := AReader.ReadApplication(HexToBytes(AidHex), nil);
  except
    on E: Exception do
    begin
      Raised := True;
      Check(E.ClassType = AClass, 'Correct error class: ' + E.ClassName);
      if AMessage <> '' then Check(E.Message = AMessage, 'Primary error preserved');
    end;
  end;
  Check(Raised, 'Application read must fail');
end;

procedure TestApplicationRead;
var
  Reader: TEMVCardReader;
  Script: TScript;
  Data: TEmvApplicationData;
  Values: TEmvValues;
  RecordHex: string;
begin
  Reader := TEMVCardReader.Create(nil);
  try
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '80060000080101009000');
    RecordHex := Tlv('70', '5A0800000000000000005F24032512315F20024AE9' +
      '5F5310424530303030303030303030303030309F6301AA');
    Script.Add('00B2010C00', RecordHex + '9000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check((Script.Begins = 1) and (Script.Ends = 1) and (Script.Position = 3), 'Whole SELECT/GPO/records operation in one transaction');
    Check((Data.Pan = '0000000000000000') and (Data.ExpiryDate = '251231'), 'Snapshot PAN/expiry');
    Check(Data.Iban = 'BE00000000000000', 'IBAN present only when supplied by card');
    Check((Data.ApplicationInfo.LabelText = 'TEST') and (Length(Data.Records) = 1), 'Selected application and records');
    Check(BytesToHex(TEmvCodec.ConsistentValue(Data.Fields, HexToBytes('9F63'))) = 'AA', 'Unknown fields preserved');
    Data.Records[0].RawData[4] := $FF;
    Check(Data.Pan[1] = '0', 'Record bytes independent from fields');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci('9F3704') + '9000');
    Script.Add('80A800000683040102030400', Tlv('77', '820200009404580101005A021234') + '9000');
    Script.Add('00B2015C00', 'DEADBEEF9000'); // SFI 11 is issuer-defined, not required to be BER.
    SetLength(Values, 1);
    Values[0] := Value('9F37', '01020304');
    Data := Reader.ReadApplication(HexToBytes(AidHex), Values);
    Check((Data.Pan = '1234') and (BytesToHex(Data.Records[0].RawData) = 'DEADBEEF'), '77 fields and opaque issuer record');
    Check(Script.Position = 3, 'PDOL supplied exactly once without extra commands');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', Tlv('77', '820200009400') + '9000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check((Length(Data.Records) = 0) and (Data.Pan = '') and (Data.Iban = ''), 'Empty AFL and absent fields explicit');
  finally Reader.Free; end;
  Writeln('PASS: selected application, 80/77 GPO, exact PDOL and complete AFL reads.');
end;

procedure TestDirectories;
var
  Reader: TEMVCardReader;
  Script: TScript;
  Data: TEmvDirectoryData;
  Entry, DirectoryFci: string;
begin
  Reader := TEMVCardReader.Create(nil);
  try
    Entry := Tlv('61', '4F07' + AidHex + '500454455354870181');
    DirectoryFci := Tlv('6F', '840E325041592E5359532E4444463031' + Tlv('A5', Tlv('BF0C', Entry)));
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A404000E325041592E5359532E444446303100', DirectoryFci + '9000');
    Data := Reader.DiscoverApplications(edContactlessPpse);
    Check(Data.Present and (Length(Data.Applications) = 1), 'PPSE FCI applications');
    Check((Data.Applications[0].Priority = 1) and Data.Applications[0].ConfirmationRequired, 'Priority and confirmation preserved');
    Check(Script.Position = 1, 'Discovery selects no payment application');
    DirectoryFci := Tlv('6F', '840E315041592E5359532E4444463031' + Tlv('A5', '880101'));
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A404000E315041592E5359532E444446303100', DirectoryFci + '9000');
    Script.Add('00B2010C00', Tlv('70', Entry) + '9000');
    Script.Add('00B2020C00', '6A83');
    Data := Reader.DiscoverApplications(edContactPse);
    Check(Data.Present and (Length(Data.Applications) = 1) and (Script.Position = 3), 'PSE SFI records until 6A83');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A404000E315041592E5359532E444446303100', '6A82');
    Data := Reader.DiscoverApplications(edContactPse);
    Check(not Data.Present and (Length(Data.Applications) = 0), 'Missing directory is explicit, no guessed AIDs');
    Reader.MaxDirectoryRecords := 1;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add('00A404000E315041592E5359532E444446303100', DirectoryFci + '9000');
    Script.Add('00B2010C00', Tlv('70', Entry) + '9000');
    try
      Data := Reader.DiscoverApplications(edContactPse);
      raise Exception.Create('Directory bound must fail');
    except on E: EEmvDataError do Check(Script.Ends = 1, 'Unproven directory completeness releases transaction'); end;
  finally Reader.Free; end;
  Writeln('PASS: PSE/PPSE discovery, optional absence and bounded directory records.');
end;

procedure TestFailuresAndStatusHandling;
var
  Reader: TEMVCardReader;
  Script: TScript;
  Data: TEmvApplicationData;
  I: Integer;
  GpoHex: string;
  Raised: Boolean;
begin
  Reader := TEMVCardReader.Create(nil);
  try
    ReadFails(Reader, EEmvDataError);
    Reader.Transport := TBareTransport.Create;
    ReadFails(Reader, EEmvDataError);
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.BeginFails := True;
    ReadFails(Reader, ECardTransportError);
    Check((Script.Position = 0) and (Script.Ends = 0), 'Failed begin sends nothing');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '', True);
    Script.EndFails := True;
    ReadFails(Reader, ECardTransportError, 'synthetic exchange failure');
    Check((Script.Position = 2) and (Script.Ends = 1), 'Failed GPO never replayed and primary error wins');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '6C08');
    ReadFails(Reader, EEmvStatusError);
    Check(Script.Position = 2, 'GPO 6Cxx never reinitializes application');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '6985');
    ReadFails(Reader, EEmvStatusError);
    Check(Script.Position = 2, 'Application decline does not choose another AID');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    GpoHex := '80020000';
    Script.Add('80A8000002830000', '6104');
    Script.Add('00C0000004', '6C02');
    Script.Add('00C0000002', '80026102');
    Script.Add('00C0000002', '00009000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check(BytesToHex(Data.Gpo) = GpoHex, 'Bounded GET RESPONSE including correction after empty first fragment');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, '6C' + IntToHex(Length(Fci) div 2, 2));
    Script.Add(Copy(SelectHex, 1, Length(SelectHex) - 2) + IntToHex(Length(Fci) div 2, 2), Fci + '9000');
    Script.Add('80A8000002830000', '80060000080101009000');
    Script.Add('00B2010C00', '6C02');
    Script.Add('00B2010C02', '70009000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check((Length(Data.Records) = 1) and (Script.Position = 5), 'Read-only SELECT/record Le correction');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '800200009000');
    Script.EndFails := True;
    ReadFails(Reader, ECardTransportError, 'synthetic end failure');
    for I := 0 to 5 do
    begin
      Script := TScript.Create;
      Reader.Transport := Script;
      Script.Add(SelectHex, Fci + '9000');
      case I of
        0: GpoHex := '800100';
        1: GpoHex := Tlv('77', '8201009400');
        2: GpoHex := Tlv('77', '82020000820200009400');
        3: GpoHex := '8006000009010100';
        4: GpoHex := '800A00000801020008020300';
        5: GpoHex := '';
      end;
      Script.Add('80A8000002830000', GpoHex + '9000');
      ReadFails(Reader, EEmvDataError);
      Check((Script.Position = 2) and (Script.Ends = 1), 'Malformed GPO/AFL stops before record access');
    end;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci('9F3704') + '9000');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 1, 'Missing PDOL value fails before GPO');
    Reader.UseTransactions := False;
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '800200009000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check((Script.Begins = 0) and (Script.Ends = 0), 'Explicit caller serialization');
    for I := 0 to 3 do
    begin
      Raised := False;
      try
        case I of
          0: Reader.MaxRecords := 0;
          1: Reader.MaxRecords := 1025;
          2: Reader.MaxDirectoryRecords := 0;
          3: Reader.MaxDirectoryRecords := 256;
        end;
      except on E: EEmvDataError do Raised := True; end;
      Check(Raised, 'Configuration limits');
    end;
  finally Reader.Free; end;
  Writeln('PASS: no GPO replay, transaction cleanup, status recovery and malformed responses.');
end;

procedure TestResourceAndRecordBoundaries;
var
  Reader: TEMVCardReader;
  Script: TScript;
  Data: TEmvApplicationData;
  Body, RecordHex: string;
  I: Integer;
begin
  Reader := TEMVCardReader.Create(nil);
  try
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    for I := 1 to 32 do
      if I = 1 then Script.Add('80A8000002830000', '6104')
      else Script.Add('00C0000004', '6104');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 33, 'GET RESPONSE step bound');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', 'AA6100');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 2, 'Response total bound before follow-up');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, '90');
    ReadFails(Reader, EApduFormatError);
    Check(Script.Ends = 1, 'Malformed APDU closes operation');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Tlv('6F', '8407A0000000031011' + Tlv('A5', '500454455354')) + '9000');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 1, 'Exact selected AID checked before GPO');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', 'AA6985');
    ReadFails(Reader, EEmvDataError);
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '80060000080101009000');
    Script.Add('00B2010C00', '6C04');
    Script.Add('00B2010C04', '6C03');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 4, 'Repeated record correction rejected');
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '80060000F0FEFF009000');
    Script.Add('00B2FEF400', 'AA9000');
    Script.Add('00B2FFF400', 'BB9000');
    Data := Reader.ReadApplication(HexToBytes(AidHex), nil);
    Check((Length(Data.Records) = 2) and (Data.Records[1].Number = 255), 'Record 255 and SFI 30 without loop overflow');
    Body := '';
    for I := 1 to 60 do Body := Body + '9F6301AA';
    RecordHex := Tlv('70', Body);
    Script := TScript.Create;
    Reader.Transport := Script;
    Script.Add(SelectHex, Fci + '9000');
    Script.Add('80A8000002830000', '8006000008018C009000');
    for I := 1 to 140 do Script.Add('00B2' + IntToHex(I, 2) + '0C00', RecordHex + '9000');
    ReadFails(Reader, EEmvDataError);
    Check(Script.Position = 139, 'Global field-count limit stops large snapshots');
  finally Reader.Free; end;
  Writeln('PASS: response/field limits, selected AID and record-number boundaries.');
end;

begin
  try
    TestDol;
    TestAflAndFields;
    TestApplicationRead;
    TestDirectories;
    TestFailuresAndStatusHandling;
    TestResourceAndRecordBoundaries;
    Writeln('PASS: ', Checks, ' assertions across six EMV test groups.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
