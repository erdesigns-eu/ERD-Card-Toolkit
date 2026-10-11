program SimWorkflowTests;

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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.SIM.Data, ERD.Card.SIM.Reader, ERD.Card.SIM.Workflow, ERD.Card.SIM.Inspection, ERD.Card.Workflow, ERD.Card.Demo.Job, ERD.Card.Demo.Workflows, ERD.Card.Demo.SimWorkflows;

type
  TStep = record Command, Response: TBytes; end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends, FailAt, Writes, PinAttempts: Integer;
    Active, BeginFails, EndFails: Boolean;
    MutatePin, MutateBefore, MutateData, RetainedPinCommand: TBytes;
    RetainedCredentialCommand: TBytes; CredentialAttempts: Integer;
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
  if (Length(Command) = 21) and ((Command[1] = $24) or (Command[1] = $2C)) then begin Inc(CredentialAttempts); RetainedCredentialCommand := Command; end;
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


type
  TFake = class(TInterfacedObject, ISimWorkflowCard)
    Snapshot: TSimWorkflowSnapshot;
    Reads, Auths, Applies, FailAfter: Integer;
    Pin: TBytes;
    IdentityValue: UnicodeString;
    MissingEvidence: Boolean;
    constructor Create;
    function Profile: TSimCardProfile;
    function ApplicationAid: TBytes;
    function Identity: UnicodeString;
    procedure Authenticate(const APin: TBytes);
    function ReadRecords(const AFile: TSimFileAddress): TSimRecords;
    procedure Apply(const APlan: TSimWorkflowPlan; out AResults: TSimRecordWriteResults);
  end;
  TObserver = class
    Flow: TCardWorkflow;
    procedure Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
  end;
constructor TFake.Create;
begin inherited Create; FailAfter := -1; IdentityValue := '8912345678901234567'; end;
function TFake.Profile: TSimCardProfile;
begin Result := Snapshot.Profile; end;
function TFake.ApplicationAid: TBytes;
begin Result := CopyBytes(Snapshot.ApplicationAid); end;
function TFake.Identity: UnicodeString;
begin Result := IdentityValue; end;
procedure TFake.Authenticate(const APin: TBytes);
begin Inc(Auths); Pin := CopyBytes(APin); end;
function TFake.ReadRecords(const AFile: TSimFileAddress): TSimRecords;
var I, J: Integer;
begin Result := nil; Inc(Reads); for I := 0 to High(Snapshot.Files) do
  if Snapshot.Files[I].Address.Path[High(Snapshot.Files[I].Address.Path)] = AFile.Path[High(AFile.Path)] then
  begin SetLength(Result, Length(Snapshot.Files[I].Records)); for J := 0 to High(Result) do Result[J] := CopyBytes(Snapshot.Files[I].Records[J]); Exit; end;
  raise ESimCardStatusError.Create($6A82);
end;
procedure TFake.Apply(const APlan: TSimWorkflowPlan; out AResults: TSimRecordWriteResults);
var I: Integer;
begin Inc(Applies); AResults := nil; if MissingEvidence then Exit;
  SetLength(AResults, Length(APlan.Changes)); for I := 0 to High(AResults) do
  begin AResults[I].Dispatched := True; if I = FailAfter then raise ESimCardWriteUncertain.Create('Injected', False);
    AResults[I].Verified := True; end;
end;
procedure TObserver.Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
begin if State = cwsWriting then Flow.Cancel; end;
function Standalone(const Kind: TSimWorkflowKind; const Count: Integer): TSimWorkflowSnapshot;
var I, N: Integer;
begin Result := Default(TSimWorkflowSnapshot); Result.Kind := Kind; Result.Profile := scpGsmSim;
  Result.Iccid := '8912345678901234567'; SetLength(Result.Files, 1);
  Result.Files[0].Address := TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F3A]); N := 20;
  if Kind = swkSms then begin N := 176; Result.Files[0].Address.Path[1] := $6F3C; end;
  SetLength(Result.Files[0].Records, Count); for I := 0 to Count - 1 do Result.Files[0].Records[I] := HexToBytes(StringOfChar('F', N * 2));
end;
procedure OfflineAndWorkflowTests;
var S, Target, RoundTrip: TSimWorkflowSnapshot; P, P2: TSimWorkflowPlan;
  Entries: TSimPhonebookEntries; Sms: TSimRecords; C: TFake; Card: ISimWorkflowCard;
  Flow: TSimPhonebookWorkflow; SmsFlow: TSimSmsWorkflow; Observer: TObserver;
  I: Integer; Rejected: Boolean; Pin: TBytes; Text: string;
begin
  Target := Standalone(swkPhonebook, 3); S := Standalone(swkPhonebook, 3);
  S.Files[0].Records[0] := TSimCodec.EncodeAdn('ALICE', '+12345', 20);
  S.Files[0].Records[1] := TSimCodec.EncodeAdn('BOB', '999', 20);
  Text := TSimWorkflowCodec.EncodeSnapshot(S); RoundTrip := TSimWorkflowCodec.DecodeSnapshot(Text);
  Check(TSimWorkflowCodec.EncodeSnapshot(RoundTrip) = Text, 'Snapshot strict roundtrip');
  Check(Pos('ALICE', string(TSimWorkflowCodec.Report(S))) > 0, 'Parsed contact report');
  P := TSimWorkflowCodec.RestorePlan(S, Target); Check(Length(P.Changes) = 2, 'Only differing records planned');
  P2 := TSimWorkflowCodec.DecodePlan(TSimWorkflowCodec.EncodePlan(P)); Check(Length(P2.Changes) = 2, 'Plan archive roundtrip');
  SetLength(Entries, 2); for I := 0 to 1 do Entries[I] := TSimCodec.DecodeAdn(S.Files[0].Records[I]);
  P := TSimWorkflowCodec.ImportContacts(Target, Entries); Check((Length(P.Changes) = 2) and (P.Changes[1].RecordNumber = 2), 'Free ADN allocation');
  Target.Files[0].Records[0] := S.Files[0].Records[0]; P := TSimWorkflowCodec.ImportContacts(Target, Entries);
  Check((P.Changes[0].RecordNumber = 2) and (P.Changes[1].RecordNumber = 3), 'Occupied contact preserved');
  Target.Files[0].Records[1] := S.Files[0].Records[1]; Rejected := False;
  try P := TSimWorkflowCodec.ImportContacts(Target, Entries); except on E: ECardWorkflowError do Rejected := True; end;
  Check(Rejected, 'Insufficient capacity rejects complete import');
  Target := Standalone(swkSms, 3); SetLength(Sms, 2);
  Sms[0] := TSimCodec.EncodeSms($03, HexToBytes('009100FF')); Sms[1] := TSimCodec.EncodeSms($07, HexToBytes('00ABCDEF'));
  Target.Files[0].Records[0] := Sms[0]; P := TSimWorkflowCodec.ImportSms(Target, Sms);
  Check((P.Changes[0].RecordNumber = 2) and BytesEqual(P.Changes[1].Data, Sms[1]), 'SMS allocation preserves full status/padding');
  Check(Pos('Unsupported TPDU; raw', string(TSimWorkflowCodec.Report(Target))) > 0, 'Unsupported TPDU remains raw');
  for I := 0 to 3 do begin Rejected := False; try
    case I of
      0: RoundTrip := TSimWorkflowCodec.DecodeSnapshot(Text + 'garbage');
      1: RoundTrip := TSimWorkflowCodec.DecodeSnapshot(StringReplace(Text, '6F3A', '6f3a', []));
      2: P2 := TSimWorkflowCodec.DecodePlan(TSimWorkflowCodec.EncodePlan(P) + 'garbage');
      3: begin P2 := P; P2.Changes[1] := P2.Changes[0]; TSimWorkflowCodec.ValidatePlan(P2); end;
    end;
  except on E: Exception do Rejected := True; end; Check(Rejected, 'Malformed/noncanonical input rejected'); end;
  C := TFake.Create; Card := C; C.Snapshot := Standalone(swkPhonebook, 3);
  Flow := TSimPhonebookWorkflow.Create(nil); Observer := TObserver.Create;
  try
    Flow.PreparePreview(Card, S); Check((C.Reads = 0) and (C.Auths = 0), 'Prepare has no I/O');
    Check(Flow.Execute = cwsCompleted, 'Preview reads target');
    P := Flow.Plan; Check((Length(P.Changes) = 2) and (C.Applies = 0), 'Preview never writes');
    Pin := HexToBytes('31323334'); Flow.PrepareApply(Card, P, Pin); Pin[0] := Ord('9');
    P.Changes[0].Data[0] := 0; Check(Flow.Execute = cwsCompleted, 'Apply complete plan');
    Check((C.Auths = 2) and (C.Pin[0] = Ord('1')) and (Flow.Results[0].State = cwusVerified), 'Independent PIN and per-record proof');
    P := TSimWorkflowCodec.RestorePlan(S, C.Snapshot); C.FailAfter := 1;
    Flow.PrepareApply(Card, P); Check(Flow.Execute = cwsUncertain, 'Partial failure remains uncertain');
    Check((Flow.Results[0].State = cwusVerified) and (Flow.Results[1].State = cwusUncertain), 'Earlier verified record retained');
    C.FailAfter := -1; C.MissingEvidence := True; Flow.PrepareApply(Card, P);
    Check(Flow.Execute = cwsUncertain, 'Backend success without proof refused');
    Check(Flow.Results[0].State = cwusUncertain, 'Missing backend evidence is conservatively unknown per record');
    C.MissingEvidence := False; Observer.Flow := Flow; Flow.OnProgress := Observer.Progress;
    Flow.PrepareApply(Card, P); I := C.Applies; Check(Flow.Execute = cwsCancelled, 'Cancellation before apply');
    Check(C.Applies = I, 'Cancelled request does not dispatch'); Flow.OnProgress := nil;
    C.IdentityValue := '8912345678901234568'; Flow.PrepareApply(Card, P); I := C.Auths;
    Check(Flow.Execute = cwsFailed, 'Wrong physical card refused'); Check(C.Auths = I, 'Wrong card refused before authentication');
  finally Observer.Free; Flow.Free; Card := nil; end;
  C := TFake.Create; Card := C; C.Snapshot := Standalone(swkSms, 2); SmsFlow := TSimSmsWorkflow.Create(nil);
  try SmsFlow.PrepareBackup(Card, C.Snapshot.Files[0].Address); Check(SmsFlow.Execute = cwsCompleted, 'SMS complete capture');
    Check(Length(SmsFlow.Snapshot.Files[0].Records) = 2, 'SMS physical capacity retained');
  finally SmsFlow.Free; Card := nil; end;
end;
procedure LinkedTests;
var S, Target: TSimWorkflowSnapshot; P: TSimWorkflowPlan; I: Integer; Flow: TSimPhonebookWorkflow;
  C: TFake; Card: ISimWorkflowCard; Report: UnicodeString;
begin
  S := Standalone(swkPhonebook, 1); S.Profile := scpUiccUsim; S.ApplicationAid := HexToBytes(Aid); S.PbrRecord := 1;
  S.Files[0].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F3A]);
  SetLength(S.Files, 5); for I := 1 to 4 do SetLength(S.Files[I].Records, 1);
  S.Files[1].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F30]);
  S.Files[1].Records[0] := HexToBytes('A80EC0034F3A01C1034F1702C2024F4AA905CA034F5003');
  S.Files[2].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F17]); S.Files[2].Records[0] := HexToBytes('01');
  S.Files[3].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F4A]); S.Files[3].Records[0] := HexToBytes('020176FFFFFFFFFFFFFFFFFFFF');
  S.Files[4].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F50]); S.Files[4].Records[0] := HexToBytes('41420101');
  S.Files[0].Records[0] := TSimCodec.EncodeAdn('ALICE', '123', 20); S.Files[0].Records[0][19] := 1;
  TSimWorkflowCodec.Validate(S); Report := TSimWorkflowCodec.Report(S);
  Check((Pos('12367', string(Report)) > 0) and (Pos('AB', string(Report)) > 0), 'PBR EMAIL/EXT parsed report');
  Target := TSimWorkflowCodec.DecodeSnapshot(TSimWorkflowCodec.EncodeSnapshot(S));
  Target.Files[0].Records[0] := HexToBytes(BlankContact); Target.Files[2].Records[0] := HexToBytes('FF');
  Target.Files[3].Records[0] := HexToBytes(StringOfChar('F', 26)); Target.Files[4].Records[0] := HexToBytes('FFFFFFFF');
  P := TSimWorkflowCodec.RestorePlan(S, Target);
  Check((Length(P.Changes) = 4) and (P.Changes[0].FileAddress.Path[1] = $4F4A) and
    (P.Changes[2].FileAddress.Path[1] = $4F17) and (P.Changes[3].FileAddress.Path[1] = $4F3A), 'Linked data precedes IAP and ADN');
  C := TFake.Create; Card := C; C.Snapshot := S; Flow := TSimPhonebookWorkflow.Create(nil);
  try Flow.PrepareBackup(Card, S.Files[0].Address, 1); Check(Flow.Execute = cwsCompleted, 'PBR discovers complete referenced files');
    Check(Length(Flow.Snapshot.Files) = 5, 'Whole linked EF set captured');
  finally Flow.Free; Card := nil; end;
end;
procedure PlanScript(const S: TScript; const Stale: Boolean);
var I: Integer; Original: string;
  procedure ReadAdn(const N: Integer; const Data: string);
  begin SelectLegacy(S, '3F00', LegacyMf); SelectLegacy(S, '7F10', LegacyTelecom);
    SelectLegacy(S, '6F3A', '000000286F3A040000000001020114'); S.Add('A0B2' + IntToHex(N,2) + '0414', Data + '9000'); end;
begin
  SelectLegacy(S, '3F00', LegacyMf); SelectLegacy(S, '2FE2', '0000000A2FE2040000000001020000');
  S.Add('A0B000000A', '982143658709214365F79000');
  for I := 1 to 2 do begin Original := BlankContact; if Stale and (I = 2) then Original := Contact; ReadAdn(I, Original); end;
  if Stale then Exit;
  for I := 1 to 2 do begin ReadAdn(I, BlankContact); S.Add('A0DC' + IntToHex(I,2) + '0414' + Contact, '9000');
    S.Add('A0B2' + IntToHex(I,2) + '0414', Contact + '9000'); end;
  for I := 1 to 2 do ReadAdn(I, Contact);
end;
procedure NativePlanTest(const Failure: Integer; const Cleanup, Stale: Boolean);
var S: TScript; T: ICardTransport; Reader: TSimCardReaderWriter; Changes: TSimRecordChanges;
  Results: TSimRecordWriteResults; Failed, Uncertain: Boolean; I: Integer;
begin
  S := TScript.Create; T := S; PlanScript(S, Stale); S.FailAt := Failure; S.EndFails := Cleanup;
  Reader := TSimCardReaderWriter.Create(nil);
  try Reader.Transport := T; SetLength(Changes, 2); for I := 0 to 1 do begin
    Changes[I].FileAddress := TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F3A]); Changes[I].RecordNumber := I + 1;
    Changes[I].ExpectedBefore := HexToBytes(BlankContact); Changes[I].Data := HexToBytes(Contact); end;
    Failed := False; Uncertain := False;
    try Reader.WriteRecordPlan(Changes, '8912345678901234567', nil, Results);
    except on E: ESimCardWriteUncertain do begin Failed := True; Uncertain := True;
      if Failure < 0 then Check(E.VerifiedReadBack, 'Cleanup retains complete verification'); end;
      on E: Exception do Failed := True;
    end;
    Check(Failed = ((Failure >= 0) or Cleanup or Stale), 'Native plan exact failure boundary');
    Check(Uncertain = (Failed and (S.Writes > 0)), 'Native plan only uncertain after UPDATE');
    Check((S.Begins = 1) and (S.Ends = 1) and not S.Active and (S.Writes <= 2), 'Native plan one exclusive transaction/no replay');
    if Stale then Check(S.Writes = 0, 'Late stale original prevents all writes');
    if (Failure < 0) and not Stale then begin Check(Results[0].Verified and Results[1].Verified, 'Native per-record independent evidence'); Complete(S); end;
    if Failure = 36 then Check(Results[0].Verified and Results[1].Dispatched, 'Earlier proof retained after second write/read boundary');
  finally Reader.Free; T := nil; end;
end;
procedure RichImportTests;
var S, Applied: TSimWorkflowSnapshot; C: TSimWorkflowContacts; P: TSimWorkflowPlan;
  I, J, K: Integer; Rejected: Boolean; Text: UnicodeString;
  Backend: TFake; Card: ISimWorkflowCard; Flow: TSimPhonebookWorkflow;
begin
  S := Standalone(swkPhonebook, 2); S.Profile := scpUiccUsim; S.ApplicationAid := HexToBytes(Aid); S.PbrRecord := 1;
  S.Files[0].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F3A]);
  SetLength(S.Files, 6);
  S.Files[1].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F30]); SetLength(S.Files[1].Records, 1);
  S.Files[1].Records[0] := HexToBytes('A80EC0034F3A01C1034F1702C2024F4AA90ACA034F5003C4034F1104');
  S.Files[2].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F17]); SetLength(S.Files[2].Records, 2);
  S.Files[3].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F4A]); SetLength(S.Files[3].Records, 2);
  S.Files[4].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F50]); SetLength(S.Files[4].Records, 2);
  S.Files[5].Address := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F11]); SetLength(S.Files[5].Records, 2);
  for I := 0 to 1 do begin S.Files[2].Records[I] := HexToBytes('FFFF'); S.Files[3].Records[I] := HexToBytes(StringOfChar('F',26));
    S.Files[4].Records[I] := HexToBytes(StringOfChar('F',44)); S.Files[5].Records[I] := HexToBytes(StringOfChar('F',34)); end;
  SetLength(C, 1); C[0].Name := 'ALICE'; C[0].Number := '+123456789012345678901234567890123456789012';
  C[0].Email := 'a@b'; C[0].AdditionalNumber := '+987'; P := TSimWorkflowCodec.ImportLinkedContacts(S, C);
  Check((Length(P.Changes) = 6) and (P.Changes[5].FileAddress.Path[1] = $4F3A), 'EXT/EMAIL/ANR/IAP before ADN');
  Check((P.Changes[0].Data[12] = 2) and (P.Changes[1].Data[12] = $FF), 'Allocated EXT chain complete and terminated');
  Applied := TSimWorkflowCodec.DecodeSnapshot(TSimWorkflowCodec.EncodeSnapshot(S));
  for I := 0 to High(P.Changes) do begin K := -1; for J := 0 to High(Applied.Files) do
    if Applied.Files[J].Address.Path[1] = P.Changes[I].FileAddress.Path[1] then K := J;
    Applied.Files[K].Records[P.Changes[I].RecordNumber - 1] := CopyBytes(P.Changes[I].Data); end;
  Text := TSimWorkflowCodec.Report(Applied);
  Check((Pos(string(C[0].Number), string(Text)) > 0) and (Pos('a@b', string(Text)) > 0) and
    (Pos('+987', string(Text)) > 0), 'Portable import resolves original long number EMAIL and ANR');
  Check(BytesEqual(S.Files[2].Records[0], HexToBytes('FFFF')), 'Offline planning never mutates target snapshot');
  S.Files[3].Records[1][0] := 0; Rejected := False;
  try P := TSimWorkflowCodec.ImportLinkedContacts(S, C); except on E: ECardWorkflowError do Rejected := True; end;
  Check(Rejected, 'Insufficient EXT capacity rejects whole logical contact');
  S := Standalone(swkPhonebook, 2); SetLength(S.Files, 2);
  S.Files[1].Address := TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F4A]); SetLength(S.Files[1].Records, 2);
  for I := 0 to 1 do S.Files[1].Records[I] := HexToBytes(StringOfChar('F',26));
  Backend := TFake.Create; Card := Backend; Backend.Snapshot := S; Flow := TSimPhonebookWorkflow.Create(nil);
  try
    Flow.PrepareClassicBackup(Card); Check(Backend.Reads = 0, 'Explicit classic EXT acquisition prepares without I/O');
    Check((Flow.Execute = cwsCompleted) and (Length(Flow.Snapshot.Files) = 2), 'Empty classic phonebook retains explicit EXT capacity');
    C[0].Email := ''; C[0].AdditionalNumber := ''; P := TSimWorkflowCodec.ImportLinkedContacts(Flow.Snapshot, C);
    Check((Length(P.Changes) = 3) and (P.Changes[2].FileAddress.Path[1] = $6F3A), 'Classic long-number import allocates EXT then ADN');
  finally Flow.Free; Card := nil; end;
end;
type
  TNoReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
    Connections: Integer;
    function CreateTransport(const Name: UnicodeString): ICardTransport;
  end;
function TNoReaders.CreateTransport(const Name: UnicodeString): ICardTransport;
begin Result := nil; Inc(Connections); raise Exception.Create('No offline hardware'); end;
procedure OfflineDemoTests;
var Factory: TNoReaders; F: ICardWorkflowDemoReaders; Ops: ICardDemoOperations;
  R: TCardDemoRequest; D: TCardDemoResult; S: TSimWorkflowSnapshot; Records: TSimRecords; Plan: TSimWorkflowPlan; Rejected: Boolean;
begin
  Factory := TNoReaders.Create; F := Factory; Ops := CreateSimWorkflowDemoOperations(F);
  R := Default(TCardDemoRequest); R.Operation := cdoFamily; R.FamilyName := 'SimWorkflowDemo';
  SetLength(R.Arguments, 7); SetLength(R.Credentials, 1); R.Arguments[1] := '0'; R.FamilyAction := 4;
  S := Standalone(swkPhonebook, 2); R.Arguments[2] := UnicodeString(TSimWorkflowCodec.EncodeSnapshot(S));
  R.Arguments[6] := 'ALICE' + #9 + '+12345'; Ops.Run(R,D);
  Check(D.Success and (Length(TSimWorkflowCodec.DecodePlan(string(TEncoding.UTF8.GetString(D.Artifacts[0].Data))).Changes) = 1), 'Offline contact demo produces usable plan');
  SetLength(Records, 2); Records[0] := TSimCodec.EncodeSms(7, HexToBytes('0041000491214300080A0500037A020100480069'));
  Records[1] := TSimCodec.EncodeSms(7, HexToBytes('0041000491214300080C0500037A0202004200790065'));
  R.FamilyAction := 7; R.Arguments[6] := UnicodeString(BytesToHex(Records[1]) + ';' + BytesToHex(Records[0])); Ops.Run(R,D);
  Check(D.Success and (D.Text = 'HiBye'), 'Demo explicit multipart assembly preserves order');
  R.FamilyAction := 5; S := Standalone(swkSms, 2); R.Arguments[2] := UnicodeString(TSimWorkflowCodec.EncodeSnapshot(S)); Ops.Run(R,D);
  Check(D.Success and (Length(TSimWorkflowCodec.DecodePlan(string(TEncoding.UTF8.GetString(D.Artifacts[0].Data))).Changes) = 2), 'SMS import plans complete group');
  R.FamilyAction := 9; Ops.Run(R,D); Check(D.Success, 'Complete multipart group import validated');
  SetLength(Records, 1); Rejected := False;
  try Plan := TSimWorkflowCodec.ImportSmsGroup(S, Records); except on E: ESimCardError do Rejected := True; end;
  Check(Rejected and (Length(Plan.Changes) = 0), 'Incomplete group is refused before plan creation');
  R.FamilyAction := 2; R.Arguments[0] := 'Target'; R.Arguments[2] := 'malformed';
  try Ops.Run(R,D); except on E: ECardWorkflowError do begin end; end;
  Check(Factory.Connections = 0, 'Offline and malformed archives never create hardware');
  Ops := nil; F := nil;
end;
procedure NativeUsimPlanTest;
var S: TScript; T: ICardTransport; Reader: TSimCardReaderWriter; Changes: TSimRecordChanges; Evidence: TSimRecordWriteResults;
  procedure SelectEmail;
  begin S.Add('00A4040407A000000087100200', UiccAdf + '9000');
    S.Add('00A40004025F3A00', '62088202782183025F3A9000');
    S.Add('00A40004024F5000', '620F8205422100040183024F50800200049000'); end;
begin
  S := TScript.Create; T := S; S.Add('00A40004023F0000', UiccMf + '9000');
  S.Add('00A40004022FE200', '620C8202412183022FE28002000A9000'); S.Add('00B000000A', '982143658709214365F79000');
  S.Add('00A4040407A000000087100200', UiccAdf + '9000'); S.Add('00200001', '63C3');
  S.Add('002000010831323334FFFFFFFF', '9000');
  SelectEmail; S.Add('00B2010404', '414201019000'); SelectEmail; S.Add('00B2010404', '414201019000');
  S.Add('00DC01040442420101', '9000'); S.Add('00B2010404', '424201019000');
  SelectEmail; S.Add('00B2010404', '424201019000'); Reader := TSimCardReaderWriter.Create(nil);
  try Reader.Profile := scpUiccUsim; Reader.ApplicationAid := HexToBytes(Aid); Reader.Transport := T;
    SetLength(Changes, 1); Changes[0].FileAddress := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F50]);
    Changes[0].RecordNumber := 1; Changes[0].ExpectedBefore := HexToBytes('41420101'); Changes[0].Data := HexToBytes('42420101');
    Reader.WriteRecordPlan(Changes, '8912345678901234567', HexToBytes('31323334'), Evidence);
    Check(Evidence[0].Verified and (S.PinAttempts = 1), 'Native USIM plan authenticates exactly once and verifies'); Complete(S);
    Check(S.RetainedPinCommand[5] = 0, 'Native retained PIN command wiped');
  finally Reader.Free; T := nil; end;
end;
procedure InspectionTests;
var S: TScript; T: ICardTransport; Reader: TSimCardReaderWriter; Flow: TSimInspectionWorkflow; Id: Integer;
  procedure Iccid;
  begin SelectLegacy(S, '3F00', LegacyMf); SelectLegacy(S, '2FE2', '0000000A2FE2040000000001020000');
    S.Add('A0B000000A', '982143658709214365F79000'); end;
begin
  S := TScript.Create; T := S; Iccid;
  SelectLegacy(S, '3F00', LegacyMf); SelectLegacy(S, '7F20', LegacyGsm);
  for Id := 0 to 2 do begin SelectLegacy(S, '3F00', LegacyMf); SelectLegacy(S, '7F20', LegacyGsm);
    case Id of 0: S.Add('A0A40000026F07', '6A82'); 1: S.Add('A0A40000026F46', '6982'); 2: S.Add('A0A40000026F38', '6A82'); end; end;
  Iccid; Reader := TSimCardReaderWriter.Create(nil); Flow := TSimInspectionWorkflow.Create(nil);
  try Reader.Transport := T; Flow.Prepare(Reader); Reader.Free; Reader := nil;
    Check(S.Begins = 0, 'Inspection preparation has no I/O and owns reader configuration');
    Check(Flow.Execute = cwsCompleted, 'Card refusals become inspection section evidence');
    Check(Flow.Sections[0].Available and (Flow.Sections[0].Text = '8912345678901234567') and
      not Flow.Sections[3].Available and (Flow.Sections[3].StatusWord = $6982), 'Exact inspection identity and refusal');
    Check(Pos('Not applicable', string(Flow.Report)) > 0, 'Classic EF.DIR not advertised');
    Check((S.Position = Length(S.Steps)) and (S.Begins = S.Ends) and (S.Writes = 0) and (S.PinAttempts = 0), 'Inspection no PIN/mutation and balanced ownership');
  finally Reader.Free; Flow.Free; T := nil; end;
end;
var I: Integer;
begin
  try
    OfflineAndWorkflowTests; LinkedTests; RichImportTests; OfflineDemoTests; InspectionTests; NativeUsimPlanTest; NativePlanTest(-1,False,False); NativePlanTest(-1,True,False); NativePlanTest(-1,False,True);
    for I := 0 to 50 do NativePlanTest(I,False,False);
    Writeln('PASS: ',Checks,' SIM workflow/planner/native failure-boundary assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
