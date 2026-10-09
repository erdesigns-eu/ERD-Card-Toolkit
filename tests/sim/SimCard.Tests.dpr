program SimCardTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.SIM.Data, ERD.Card.SIM.Reader;

type
  TStep = record Command, Response: TBytes; end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends, FailAt, Writes, PinAttempts: Integer;
    Active, BeginFails, EndFails: Boolean;
    MutatePin, MutateBefore, MutateData, RetainedPinCommand: TBytes;
    MutatePath: TSimFilePath;
    constructor Create;
    procedure Add(const Command, Response: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const Command: TBytes): TBytes;
  end;

const
  LegacyMf = '000000003F00010000000000090000000200838A838A';
  LegacyGsm = '000000007F20020000000000090000000200838A838A';
  LegacyTelecom = '000000007F10020000000000090000000200838A838A';
  LegacyAdn = '000000146F3A040000000001020114';
  UiccMf = '62088202782183023F00';
  UiccAdf = '620D820278218407A0000000871002';
  Aid = 'A0000000871002';
  Contact = '414C494345FF04912143F5FFFFFFFFFFFFFFFFFF';
  BlankContact = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';

var Checks: Integer;
procedure Check(const V: Boolean; const Why: string);
begin Inc(Checks); if not V then raise Exception.Create(Why); end;
constructor TScript.Create;
begin inherited Create; FailAt := -1; end;
procedure TScript.Add(const Command, Response: string);
var N: Integer;
begin N := Length(Steps); SetLength(Steps,N+1); Steps[N].Command := HexToBytes(Command); Steps[N].Response := HexToBytes(Response); end;
procedure TScript.BeginTransaction;
begin
  Check(not Active,'No nested transaction'); Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('Sensitive begin message');
  Active := True;
  if Length(MutatePin) > 0 then MutatePin[0] := Ord('9');
  if Length(MutateBefore) > 0 then MutateBefore[0] := 0;
  if Length(MutateData) > 0 then MutateData[0] := 0;
  if Length(MutatePath) > 0 then MutatePath[0] := $1234;
end;
procedure TScript.EndTransaction;
begin Check(Active,'Owned release'); Inc(Ends); Active := False;
  if EndFails then raise ECardTransportError.Create('Sensitive end message'); end;
function TScript.Exchange(const Command: TBytes): TBytes;
var N: Integer;
begin
  Check(Active,'Exclusive card I/O'); N := Position; Inc(Position);
  Check(N < Length(Steps),'No extra/replayed command');
  Check(BytesEqual(Command,Steps[N].Command),'Independent literal APDU transcript at ' + IntToStr(N));
  if Command[1] in [$D6,$DC] then Inc(Writes);
  if Command[1] = $20 then begin RetainedPinCommand := Command;
    if (Length(Command) = 13) and (Command[4] = 8) then Inc(PinAttempts); end;
  if N = FailAt then raise ECardTransportError.Create('Sensitive transmit message');
  Result := CopyBytes(Steps[N].Response);
end;
procedure Complete(const S: TScript);
begin Check((S.Position = Length(S.Steps)) and (S.Begins = 1) and (S.Ends = 1) and not S.Active,'Complete owned transcript'); end;
procedure SelectLegacy(const S: TScript; const Id, Header: string);
begin S.Add('A0A4000002'+Id,'9F'+IntToHex(Length(Header) div 2,2));
  S.Add('A0C00000'+IntToHex(Length(Header) div 2,2),Header+'9000'); end;
procedure AdnWriteScript(const S: TScript; const Pin: Boolean);
begin
  if Pin then
  begin SelectLegacy(S,'3F00',LegacyMf); SelectLegacy(S,'7F20',LegacyGsm); S.Add('A02000010831323334FFFFFFFF','9000'); end;
  SelectLegacy(S,'3F00',LegacyMf); SelectLegacy(S,'7F10',LegacyTelecom); SelectLegacy(S,'6F3A',LegacyAdn);
  S.Add('A0B2010414',BlankContact+'9000'); S.Add('A0DC010414'+Contact,'9000'); S.Add('A0B2010414',Contact+'9000');
end;

procedure TestCodecs;
var B: TBytes; P: TSimPhonebookEntry; S: TSimSmsRecord; A: TSimApplicationInfo;
  Info: TSimFileInfo; Services: TSimServices; Text, Name: UnicodeString; I,N: Integer; Rejected: Boolean;
begin
  Check(TSimCodec.DecodeIccid(HexToBytes('982143658709214365F7')) = '8912345678901234567','Literal ICCID');
  Check(BytesToHex(TSimCodec.EncodeIccid('8912345678901234567')) = '982143658709214365F7','ICCID encode');
  Check(TSimCodec.DecodeImsi(HexToBytes('082980102143658709')) = '208011234567890','Literal IMSI');
  Check(BytesToHex(TSimCodec.EncodeImsi('208011234567890')) = '082980102143658709','IMSI encode');
  for N := 5 to 15 do
  begin Text := UnicodeString(Copy('123456789012345',1,N)); B := TSimCodec.EncodeImsi(Text);
    Check(TSimCodec.DecodeImsi(B) = Text,'Every IMSI parity/length'); end;
  Check(TSimCodec.DecodeAlpha(HexToBytes('8012FF00FFFFFFFF')) = UnicodeString(#$12FF#$00FF),'UCS-2 FF is data, not byte padding');
  Check(TSimCodec.DecodeAlpha(HexToBytes('8103084190A1FFFF')) = UnicodeString('A'+#$0410+#$0421),'Compressed 81');
  Check(TSimCodec.DecodeAlpha(HexToBytes('8203039041A1A2FF')) = UnicodeString('A'+#$03B1+#$03B2),'Compressed 82');
  Check(TSimCodec.DecodeAlpha(HexToBytes('1B141B281B291B2F1B65')) = UnicodeString('^{}\'+#$20AC),'GSM extension alphabet');
  Check(BytesToHex(TSimCodec.EncodeAlpha(UnicodeString('^{}\'+#$20AC),10)) = '1B141B281B291B2F1B65','GSM extension encode');
  for I := 0 to $FFFE do
    if not ((I >= $D800) and (I <= $DFFF)) then
    begin Name := UnicodeString(WideChar(I)); B := TSimCodec.EncodeAlpha(Name,8);
      Check(TSimCodec.DecodeAlpha(B) = Name,'Every representable UCS-2 scalar'); end;
  P := TSimCodec.DecodeAdn(HexToBytes(Contact));
  Check((P.Name = 'ALICE') and (P.Number = '+12345') and (P.ExtensionRecord = $FF),'Literal ADN');
  Check(BytesToHex(TSimCodec.EncodeAdn('ALICE','+12345',20)) = Contact,'ADN encoder');
  B := HexToBytes(Contact); P := TSimCodec.DecodeAdn(B); B[0] := 0;
  Check(BytesToHex(P.Raw) = Contact,'ADN independent raw buffer');
  Check(TSimCodec.DecodeAdn(HexToBytes(BlankContact)).Empty,'Erased ADN');
  P := TSimCodec.DecodeAdn(TSimCodec.EncodeAdn('','12*#abc',14)); Check(P.Number = '12*#abc','TBCD symbols');
  A := TSimCodec.DecodeDirectoryRecord(HexToBytes('61094F07A00000008710FFFFFF'));
  Check(BytesToHex(A.Aid) = 'A00000008710FF','AID ends FF and is not padding');
  A := TSimCodec.DecodeDirectoryRecord(HexToBytes('61104F07A000000087100250055553494D31FFFF'));
  Check((BytesToHex(A.Aid) = Aid) and (A.LabelText = 'USIM1'),'EF.DIR entry');
  Info := TSimCodec.DecodeFileInfo(scpUiccUsim,HexToBytes('620F8205422100140183026F3A80020014'));
  Check((Info.RecordBytes = 20) and (Info.RecordCount = 1) and (Info.Size = 20),'UICC record descriptor');
  Info := TSimCodec.DecodeFileInfo(scpGsmSim,HexToBytes(LegacyAdn));
  Check((Info.RecordBytes = 20) and (Info.Structure = sfsLinearFixed),'Legacy record header');
  for I := 0 to 255 do
  begin B := HexToBytes('00'+StringOfChar('F',350)); B[0] := I; S := TSimCodec.DecodeSms(B);
    Check((Length(S.Body) = 175) and (S.Body[174] = $FF),'SMS full body preserved');
    if I and 1 = 0 then Check(S.State = sssFree,'SMS allocation bit'); end;
  B := HexToBytes(StringOfChar('F',352)); Check(TSimCodec.DecodeSms(B).State = sssFree,'Erased SMS is not a queued message');
  B[1] := 0; Check(TSimCodec.DecodeSms(B).State = sssUnknown,'Reserved SMS status is not inferred');
  Services := TSimCodec.DecodeServices(scpGsmSim,HexToBytes('E4'));
  Check((Length(Services) = 4) and Services[1].Available and not Services[1].Active and Services[3].Active,'Classic two-bit SST');
  Services := TSimCodec.DecodeServices(scpUiccUsim,HexToBytes('81'));
  Check((Length(Services) = 8) and Services[0].Available and Services[7].Available and not Services[1].Available,'USIM one-bit UST');
  B := TSimCodec.EncodeSms($03,HexToBytes('009100FF')); S := TSimCodec.DecodeSms(B);
  Check((S.State = sssReceivedUnread) and (BytesToHex(Copy(S.Body,0,4)) = '009100FF'),'SMS state and untrimmed PDU field');
  for I := 0 to 14 do
  begin
    Rejected := False;
    try case I of
      0: B := TSimCodec.EncodeIccid('12');
      1: Text := TSimCodec.DecodeIccid(HexToBytes('982143658709214365A7'));
      2: Text := TSimCodec.DecodeImsi(HexToBytes('082180102143658709'));
      3: Text := TSimCodec.DecodeAlpha(HexToBytes('8012'));
      4: Text := TSimCodec.DecodeAlpha(HexToBytes('1BFF'));
      5: Text := TSimCodec.DecodeAlpha(HexToBytes('81050841'));
      6: Text := TSimCodec.DecodeAlpha(HexToBytes('8201FFFEFF'));
      7: B := TSimCodec.EncodeAlpha(UnicodeString(#$D800),8);
      8: B := TSimCodec.EncodeAdn('TOO LONG','1',14);
      9: B := TSimCodec.EncodeAdn('','123456789012345678901',14);
      10: B := TSimCodec.EncodeAdn('','1+2',14);
      11: Info := TSimCodec.DecodeFileInfo(scpUiccUsim,HexToBytes('620E82008202412183022FE28002000A'));
      12: Info := TSimCodec.DecodeFileInfo(scpGsmSim,HexToBytes('000000156F3A040000000001020114'));
      13: A := TSimCodec.DecodeDirectoryRecord(HexToBytes('610B4F07A000000087100200'));
      14: B := TSimCodec.EncodeSms($FF,nil);
    end; except on E: Exception do Rejected := True; end;
    Check(Rejected,'Malformed codec case '+IntToStr(I));
  end;
end;

procedure TestIdentityReads;
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter;
begin
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; SelectLegacy(S,'3F00',LegacyMf); SelectLegacy(S,'2FE2','0000000A2FE2040000000001020000');
    S.Add('A0B000000A','982143658709214365F79000');
    Check(R.ReadIccid = '8912345678901234567','Classic ICCID component'); Complete(S);
  finally R.Free; T := nil; end;
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; R.Profile := scpUiccUsim; R.ApplicationAid := HexToBytes(Aid);
    S.Add('00A4040407'+Aid+'00',UiccAdf+'9000');
    S.Add('00A40004026F0700','620C8202412183026F07800200099000');
    S.Add('00B0000009','0829801021436587099000');
    Check(R.ReadImsi = '208011234567890','USIM IMSI component'); Complete(S);
  finally R.Free; T := nil; end;
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; R.Profile := scpUiccUsim;
    S.Add('00A40004023F0000',UiccMf+'9000'); S.Add('00A40004022FE200','610E');
    S.Add('00C000000E','6C0E'); S.Add('00C000000E','620C8202412183022FE28002000A9000');
    S.Add('00B000000A','982143658709214365F79000');
    Check(R.ReadIccid = '8912345678901234567','Bounded 61/6C chaining'); Complete(S);
  finally R.Free; T := nil; end;
end;

procedure TestPin(const Legacy: Boolean; const Status: string; const MinAttempts: Integer; const ExpectedAttempt: Boolean);
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; P: TBytes; State: TSimPinStatus; Rejected: Boolean; H: string;
begin
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil); P := HexToBytes('31323334');
  try
    R.Transport := T; R.MinimumPinAttempts := MinAttempts;
    if Legacy then
    begin SelectLegacy(S,'3F00',LegacyMf); H := LegacyGsm; H[37] := Status[1]; H[38] := Status[2]; SelectLegacy(S,'7F20',H); end
    else
    begin R.Profile := scpUiccUsim; R.ApplicationAid := HexToBytes(Aid);
      S.Add('00A4040407'+Aid+'00',UiccAdf+'9000'); S.Add('00200001',Status); end;
    if ExpectedAttempt then
      if Legacy then S.Add('A02000010831323334FFFFFFFF','9000')
      else S.Add('002000010831323334FFFFFFFF','9000');
    S.MutatePin := P; Rejected := False;
    try State := R.VerifyPin(P); except on E: ESimCardError do Rejected := True; end;
    Check(Rejected = not ExpectedAttempt,'Budget/proof status decision'); Complete(S);
    if ExpectedAttempt then
    begin Check(State.Verified and State.VerificationKnown,'Fresh supplied-code proof');
      Check(BytesToHex(S.RetainedPinCommand) = StringOfChar('0',26),'Credential command copy wiped'); end;
    Check(P[0] = Ord('9'),'Test actually mutated caller PIN at acquisition');
  finally R.Free; T := nil; end;
end;

procedure TestWrite(const FailAt: Integer; const EndFails: Boolean; const WithPin: Boolean);
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; F: TSimFileAddress;
  P, Before, Data: TBytes; Failed, Uncertain, Verified: Boolean; WriteAt: Integer;
begin
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; F := TSimCodec.FileAddress(sfrMasterFile,[$7F10,$6F3A]);
    Before := HexToBytes(BlankContact); Data := HexToBytes(Contact); P := nil;
    if WithPin then P := HexToBytes('31323334');
    AdnWriteScript(S,WithPin); S.FailAt := FailAt; S.EndFails := EndFails;
    S.MutatePin := P; S.MutateBefore := Before; S.MutateData := Data; S.MutatePath := F.Path;
    Failed := False; Uncertain := False; Verified := False; WriteAt := 7; if WithPin then Inc(WriteAt,5);
    try R.WriteRecord(F,1,Before,Data,P);
    except on E: ESimCardWriteUncertain do begin Failed := True; Uncertain := True; Verified := E.VerifiedReadBack; end;
      on E: ECardTransportError do Failed := True; end;
    Check(Failed = ((FailAt >= 0) or EndFails),'Expected failure');
    Check(Uncertain = ((FailAt >= WriteAt) or (EndFails and (FailAt < 0))),'Uncertain only after UPDATE dispatch');
    if Failed then Check(Verified = (EndFails and (FailAt < 0)),'Read-back proof retained') else Complete(S);
    Check((S.Begins = 1) and (S.Ends = 1) and not S.Active,'Release on all failures');
    if FailAt >= 0 then Check(S.Position = FailAt+1,'No replay after transport error');
    Check(S.Writes <= 1,'Exactly one record UPDATE');
    if WithPin and (FailAt < 0) then Check(BytesToHex(S.RetainedPinCommand) = StringOfChar('0',26),'Write PIN command wiped');
  finally R.Free; T := nil; end;
end;

procedure TestCorruptReadBack;
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; F: TSimFileAddress;
  ByteIndex, Bit: Integer; Rejected: Boolean;
begin
  F := TSimCodec.FileAddress(sfrMasterFile,[$7F10,$6F3A]);
  for ByteIndex := 0 to 19 do for Bit := 0 to 7 do
  begin
    S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
    try
      R.Transport := T; AdnWriteScript(S,False);
      S.Steps[8].Response[ByteIndex] := S.Steps[8].Response[ByteIndex] xor (1 shl Bit);
      Rejected := False;
      try R.WriteRecord(F,1,HexToBytes(BlankContact),HexToBytes(Contact));
      except on E: ESimCardWriteUncertain do begin Check(not E.VerifiedReadBack,'Corrupt data never verified'); Rejected := True; end; end;
      Check(Rejected and (S.Writes = 1),'Every read-back bit mismatch, no retry'); Complete(S);
    finally R.Free; T := nil; end;
  end;
end;

procedure TestInvalidBeforeAcquisition;
var R: TSimCardReaderWriter; S: TScript; T: ICardTransport; F: TSimFileAddress; I: Integer; Rejected: Boolean; B: TBytes;
begin
  R := TSimCardReaderWriter.Create(nil); S := TScript.Create; T := S;
  try
    R.Transport := T; F := TSimCodec.FileAddress(sfrMasterFile,[$6F3A]);
    for I := 0 to 9 do
    begin
      Rejected := False;
      try case I of
        0: B := R.ReadRecord(F,0);
        1: B := R.ReadBinaryRange(F,32767,2);
        2: R.WriteRecord(F,1,HexToBytes('FF'),HexToBytes('FFFF'));
        3: R.WriteFile(F,nil,nil);
        4: R.VerifyPin(HexToBytes('12345678'));
        5: begin R.Profile := scpUiccUsim; R.ReadImsi; end;
        6: R.ApplicationAid := HexToBytes('A0000000871004');
        7: begin R.Profile := scpGsmSim; R.PinReference := $81; B := R.ReadFile(F); end;
        8: begin R.PinReference := 1; B := HexToBytes(Contact); B[19] := 1; R.DeletePhonebookContact(F,1,B); end;
        9: begin F.Root := sfrUsimApplication; B := R.ReadFile(F); end;
      end; except on E: ESimCardError do Rejected := True; end;
      Check(Rejected and (S.Begins = 0) and (S.Position = 0),'Invalid argument before hardware');
    end;
  finally R.Free; T := nil; end;
end;

procedure TestWholeFile(const FailAt: Integer; const EndFails: Boolean);
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; F: TSimFileAddress;
  Failed, Uncertain, Verified: Boolean;
begin
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Profile := scpUiccUsim; R.ApplicationAid := HexToBytes(Aid); R.Transport := T;
    F := TSimCodec.FileAddress(sfrUsimApplication,[$6F01]);
    S.Add('00A4040407'+Aid+'00',UiccAdf+'9000');
    S.Add('00A40004026F0100','620C8202412183026F01800201909000');
    S.Add('00B0000000',StringOfChar('F',512)+'9000'); S.Add('00B0010090',StringOfChar('F',288)+'9000');
    S.Add('00D60000FF'+StringOfChar('A',510),'9107'); S.Add('00D600FF91'+StringOfChar('A',290),'9000');
    S.Add('00B0000000',StringOfChar('A',512)+'9000'); S.Add('00B0010090',StringOfChar('A',288)+'9000');
    S.FailAt := FailAt; S.EndFails := EndFails; Failed := False; Uncertain := False; Verified := False;
    try R.WriteFile(F,HexToBytes(StringOfChar('F',800)),HexToBytes(StringOfChar('A',800)));
    except on E: ESimCardWriteUncertain do begin Failed := True; Uncertain := True; Verified := E.VerifiedReadBack; end;
      on E: ECardTransportError do Failed := True; end;
    Check(Failed = ((FailAt >= 0) or EndFails),'Whole-file completion');
    Check(Uncertain = ((FailAt >= 4) or (EndFails and (FailAt < 0))),'Whole-file dispatch boundary');
    if Failed then Check(Verified = (EndFails and (FailAt < 0)),'Whole-file proof before cleanup failure') else Complete(S);
    Check((S.Begins = 1) and (S.Ends = 1) and not S.Active,'Whole-file release');
    if FailAt >= 0 then Check(S.Position = FailAt+1,'Partial UPDATE never replayed');
    Check(S.Writes <= 2,'Two bounded UPDATE chunks; proactive status not FETCHed');
  finally R.Free; T := nil; end;
end;

procedure TestProtectedReadAndDirectory;
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; Apps: TSimApplications;
begin
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; R.Profile := scpUiccUsim; R.ApplicationAid := HexToBytes(Aid);
    S.Add('00A4040407'+Aid+'00',UiccAdf+'9000'); S.Add('00200001','9000');
    S.Add('00A4040407'+Aid+'00',UiccAdf+'9000');
    S.Add('00A40004026F0700','620C8202412183026F07800200099000');
    S.Add('00B0000009','0829801021436587099000');
    Check(R.ReadImsi(HexToBytes('31323334')) = '208011234567890','Reuse existing verified access without claiming fresh PIN proof');
    Check(S.PinAttempts = 0,'No needless PIN attempt'); Complete(S);
  finally R.Free; T := nil; end;
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; R.Profile := scpUiccUsim;
    S.Add('00A40004023F0000',UiccMf+'9000');
    S.Add('00A40004022F0000','620F8205422100140283022F00800200289000');
    S.Add('00B2010414','61104F07A000000087100250055553494D31FFFF9000');
    S.Add('00B2020414',BlankContact+'9000'); Apps := R.ReadApplications;
    Check((Length(Apps) = 1) and (Apps[0].LabelText = 'USIM1') and (BytesToHex(Apps[0].Aid) = Aid),'Explicit EF.DIR enumeration'); Complete(S);
  finally R.Free; T := nil; end;
end;

procedure TestGeometryAndStatusFailures;
const SensitiveBytes: array[0..8] of Integer = (2,3,4,5,6,12,13,14,11);
var S: TScript; T: ICardTransport; R: TSimCardReaderWriter; F: TSimFileAddress;
  I, Bit, J: Integer; Rejected: Boolean; State: TSimPinStatus;
begin
  F := TSimCodec.FileAddress(sfrMasterFile,[$7F10,$6F3A]);
  for I := 0 to 7 do for Bit := 0 to 7 do
  begin
    S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
    try
      R.Transport := T; AdnWriteScript(S,False);
      S.Steps[5].Response[SensitiveBytes[I]] := S.Steps[5].Response[SensitiveBytes[I]] xor (1 shl Bit);
      Rejected := False;
      try R.WriteRecord(F,1,HexToBytes(BlankContact),HexToBytes(Contact));
      except on E: ESimCardError do Rejected := True; end;
      Check(Rejected and (S.Writes = 0),'Every relevant legacy descriptor bit refuses before UPDATE');
      Check((S.Ends = 1) and not S.Active,'Metadata failure releases transaction');
    finally R.Free; T := nil; end;
  end;
  for J := 0 to 3 do
  begin
    S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
    try
      R.Transport := T; AdnWriteScript(S,False); Rejected := False;
      if J = 0 then S.Steps[6].Response[0] := 0
      else if J = 1 then S.Steps[7].Response := HexToBytes('6C14')
      else if J = 2 then S.Steps[7].Response := HexToBytes('6982')
      else S.Steps[7].Response := HexToBytes('6190');
      try R.WriteRecord(F,1,HexToBytes(BlankContact),HexToBytes(Contact));
      except on E: ESimCardWriteUncertain do begin Check(J > 0,'No uncertainty before dispatch'); Check(not E.VerifiedReadBack,'Rejected status has no proof'); Rejected := True; end;
        on E: ESimCardError do Rejected := True; end;
      Check(Rejected and (S.Position = 7+Ord(J > 0)),'No UPDATE status correction, GET RESPONSE or retry');
    finally R.Free; T := nil; end;
  end;
  S := TScript.Create; T := S; R := TSimCardReaderWriter.Create(nil);
  try
    R.Transport := T; R.Profile := scpUiccUsim; R.ApplicationAid := HexToBytes(Aid);
    S.Add('00A4040407'+Aid+'00',UiccAdf+'9000'); S.Add('00200001','63C3');
    S.Add('002000010831323334FFFFFFFF','63C2'); Rejected := False; S.EndFails := True;
    try State := R.VerifyPin(HexToBytes('31323334'));
    except on E: ESimCardStatusError do begin Check(E.StatusWord = $63C2,'Primary PIN status survives cleanup failure'); Rejected := True; end; end;
    Check(Rejected and (S.PinAttempts = 1),'Wrong supplied PIN attempted only once'); Complete(S);
  finally R.Free; T := nil; end;
end;

procedure TestPbr;
const Bad: array[0..11] of string = ('A800','A804C0024F','A804C0020000','A804C0023F00','A804C002FFFF',
  'A805C0034F3000','A805C0034F301F','A804CC024F30','A808C0024F30C202FFFF','A780','FF00','A880');
var Ref: TSimPhonebookReferences; I: Integer; Failed: Boolean;
begin
  Ref := TSimCodec.DecodePhonebookReferences(HexToBytes('A809C0034F3A01C1024F17A908CA024F50C4024F11AA04C2024F4AFF'));
  Check(Length(Ref) = 5,'PBR literal role count');
  Check((Ref[0].TemplateTag = $A8) and (Ref[0].RoleTag = $C0) and (Ref[0].FileId = $4F3A) and (Ref[0].ShortFileId = 1),'PBR ADN / SFI');
  Check((Ref[2].TemplateIndex = 1) and (Ref[2].ReferenceIndex = 0) and (Ref[2].TemplateTag = $A9) and (Ref[2].RoleTag = $CA) and (Ref[2].ShortFileId = -1),'PBR email IAP position');
  Check((Ref[3].ReferenceIndex = 1) and (Ref[3].RoleTag = $C4) and (Ref[4].TemplateTag = $AA),'PBR ANR position / independent EXT');
  Check(Length(TSimCodec.DecodePhonebookReferences(HexToBytes('FFFF'))) = 0,'Erased PBR');
  Ref := TSimCodec.DecodePhonebookReferences(HexToBytes('A908C4024F11C4024F12'));
  Check((Length(Ref) = 2) and (Ref[0].RoleTag = $C4) and (Ref[1].RoleTag = $C4) and (Ref[1].ReferenceIndex = 1), 'Repeated ANR roles preserve separate IAP positions');
  for I := 0 to High(Bad) do
  begin Failed := False; try Ref := TSimCodec.DecodePhonebookReferences(HexToBytes(Bad[I])); except on E: Exception do Failed := True; end;
    Check(Failed,'Malformed PBR refused'); end;
end;

procedure TestSmsText;
const Body = '00040B912143658709F100006201902143650005E8329BFD06';
var Message: TSimSmsMessage; Data,B: TBytes; I: Integer; Failed: Boolean;
begin
  Data := TSimCodec.EncodeSms(3,HexToBytes(Body)); Message := TSimCodec.DecodeSmsMessage(Data);
  Check(Message.Incoming and Message.TextDecoded and (Message.Text = 'hello'),'Literal GSM packed SMS DELIVER');
  Check((Message.Address = '+12345678901') and (Message.MessageReference = -1) and (Length(Message.TimestampBytes) = 7),'SMS origin/time');
  Message := TSimCodec.DecodeSmsMessage(TSimCodec.EncodeSms(7,HexToBytes('0001000491214300080400480069')));
  Check(not Message.Incoming and Message.TextDecoded and (Message.Text = 'Hi') and (Message.Address = '+1234'),'Literal UCS2 SUBMIT');
  Message := TSimCodec.DecodeSmsMessage(TSimCodec.EncodeSms(7,HexToBytes('0041000491214300080A0500037A020100480069')));
  Check((Message.Text = 'Hi') and Message.Concatenated and (Message.ConcatenationReference = $7A) and (Message.SegmentCount = 2) and (Message.SegmentNumber = 1),'UCS2 concatenation UDH');
  Message := TSimCodec.DecodeSmsMessage(TSimCodec.EncodeSms(7,HexToBytes('0041000491214300040B06050415810000DEADBEEF')));
  Check(not Message.TextDecoded and Message.PortAddressed and (Message.DestinationPort = $1581) and (Message.SourcePort = 0),'Binary SMS port UDH');
  Check(BytesEqual(Message.UserData,HexToBytes('06050415810000DEADBEEF')),'Binary body exact retention');
  Message := TSimCodec.DecodeSmsMessage(TSimCodec.EncodeSms(7,HexToBytes('0041000491214300000C0500037A0201D06536FB0D')));
  Check((Message.Text = 'hello') and Message.Concatenated, 'GSM UDH septet fill alignment');
  for I := 0 to 175 do
  begin
    B := Copy(Data,0,Length(Data));
    case I of
      0: B[0] := 0;
      1: B[1] := 175;
      2: B[2] := $06;
      3: B[3] := 255;
      12: B[I] := $20;
      13: B[I] := $FF;
      20: B[I] := 161;
    else Continue; end;
    Failed := False; try Message := TSimCodec.DecodeSmsMessage(B); except on E: Exception do Failed := True; end;
    Check(Failed,'Malformed SMS text boundary '+IntToStr(I));
  end;
end;

procedure TestLinkedContact;
var Refs: TSimPhonebookReferences; Files: TSimPhonebookFiles; Contact: TSimLinkedContact;
  I: Integer; Failed: Boolean;
begin
  Refs := TSimCodec.DecodePhonebookReferences(HexToBytes('A809C0034F3A01C1024F17A904CA024F50AA04C2024F4A'));
  SetLength(Files,4);
  Files[0].FileId := $4F3A; SetLength(Files[0].Records,1);
  Files[0].Records[0] := HexToBytes('414C494345FF04912143F5FFFFFFFFFFFFFFFF01');
  Files[1].FileId := $4F17; SetLength(Files[1].Records,1); Files[1].Records[0] := HexToBytes('02');
  Files[2].FileId := $4F50; SetLength(Files[2].Records,2); Files[2].Records[0] := HexToBytes('FFFFFFFF'); Files[2].Records[1] := HexToBytes('41420101');
  Files[3].FileId := $4F4A; SetLength(Files[3].Records,1); Files[3].Records[0] := HexToBytes('020276F8FFFFFFFFFFFFFFFFFF');
  Contact := TSimCodec.ResolvePhonebookContact(Refs,Files,$4F3A,1);
  Check((Contact.Contact.Name = 'ALICE') and (Contact.Contact.Number = '+12345678'),'ADN extended number chain');
  Check((Length(Contact.Fields) = 2) and (Contact.Fields[1].RecordNumber = 2) and BytesEqual(Contact.Fields[1].Raw,HexToBytes('41420101')),'IAP linked email raw footer preserved');
  Check((Length(Contact.Extensions) = 1) and (Contact.Contact.Raw[19] = 1),'Original extension pointer preserved');
  Contact.Fields[1].Raw[0] := 0; Check(Files[2].Records[1][0] = $41,'Resolved contact owns bytes');
  for I := 0 to 6 do
  begin
    Files[1].Records[0][0] := 2; Files[3].Records[0][0] := 2; Files[3].Records[0][1] := 2; Files[3].Records[0][12] := $FF;
    Files[2].Records[1][2] := 1; Files[2].Records[1][3] := 1;
    case I of
      0: Files[1].Records[0][0] := 0;
      1: Files[1].Records[0][0] := 3;
      2: begin Files[1].Records[0][0] := 2; Files[3].Records[0][12] := 1; end;
      3: begin Files[3].Records[0][12] := $FF; Files[3].Records[0][1] := 11; end;
      4: begin Files[3].Records[0][1] := 2; Files[3].Records[0][0] := 1; end;
      5: Files[2].Records[1][3] := 2;
      6: Files[2].Records[1][2] := 2;
    end;
    Failed := False; try Contact := TSimCodec.ResolvePhonebookContact(Refs,Files,$4F3A,1); except on E: Exception do Failed := True; end;
    Check(Failed,'Invalid linked contact / cyclic EXT');
  end;
end;

procedure TestLinkedRead(const Failure: Integer; const CleanupFailure: Boolean);
var S: TScript; T: ICardTransport; Reader: TSimCardReaderWriter; Contact: TSimLinkedContact;
  Failed: Boolean;
  procedure FileSelect(const Fid,Metadata: string);
  begin
    S.Add('00A4040407A000000087100200',UiccAdf+'9000');
    S.Add('00A40004025F3A00','62088202782183025F3A9000');
    S.Add('00A4000402'+Fid+'00',Metadata+'9000');
  end;
begin
  S := TScript.Create; T := S; Reader := TSimCardReaderWriter.Create(nil);
  try
    Reader.Profile := scpUiccUsim; Reader.ApplicationAid := HexToBytes('A0000000871002'); Reader.Transport := T;
    FileSelect('4F30','620F8205422100170183024F3080020017');
    S.Add('00B2010417','A809C0034F3A01C1024F17A904CA024F50AA04C2024F4A9000');
    FileSelect('4F3A','620F8205422100140183024F3A80020014');
    S.Add('00B2010414','414C494345FF04912143F5FFFFFFFFFFFFFFFF019000');
    FileSelect('4F17','620F8205422100010183024F1780020001');
    S.Add('00B2010401','029000');
    FileSelect('4F50','620F8205422100040283024F5080020008');
    S.Add('00B2010404','FFFFFFFF9000'); S.Add('00B2020404','414201019000');
    FileSelect('4F4A','620F82054221000D0183024F4A8002000D');
    S.Add('00B201040D','020276F8FFFFFFFFFFFFFFFFFF9000');
    S.FailAt := Failure; S.EndFails := CleanupFailure; Failed := False;
    try Contact := Reader.ReadLinkedUsimContact(1,$4F3A,1); except on E: Exception do Failed := True; end;
    Check(Failed = ((Failure >= 0) or CleanupFailure),'Linked read failure result');
    Check((S.Begins = 1) and (S.Ends = 1) and not S.Active and (S.Writes = 0) and (S.PinAttempts = 0),'One owned read-only linked transaction');
    if Failure < 0 then Check(S.Position = Length(S.Steps),'Complete literal linked EF transcript');
    if not Failed then Check((Contact.Contact.Number = '+12345678') and (Contact.Fields[1].RecordNumber = 2),'Live extended number and IAP field');
  finally Reader.Free; T := nil; end;
end;

var I: Integer;
begin
  try
    TestLinkedRead(-1,False); TestLinkedRead(-1,True); for I := 0 to 20 do TestLinkedRead(I,True);
    TestSmsText; TestLinkedContact; TestPbr; TestCodecs; TestIdentityReads; TestProtectedReadAndDirectory; TestGeometryAndStatusFailures;
    TestWholeFile(-1,False); TestWholeFile(-1,True);
    for I := 0 to 7 do TestWholeFile(I,True);
    TestPin(False,'63C3',1,True); TestPin(False,'63C1',2,False);
    TestPin(False,'63C0',1,False); TestPin(False,'6983',1,False); TestPin(False,'9000',1,False);
    TestPin(True,'83',1,True); TestPin(True,'81',2,False); TestPin(True,'80',1,False);
    TestWrite(-1,False,False); TestWrite(-1,True,False); TestWrite(-1,False,True);
    for I := 0 to 8 do TestWrite(I,True,False);
    TestCorruptReadBack; TestInvalidBeforeAcquisition;
    Writeln('PASS: ',Checks,' SIM/USIM assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
