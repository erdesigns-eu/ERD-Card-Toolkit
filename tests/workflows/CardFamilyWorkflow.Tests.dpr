program CardFamilyWorkflowTests;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
{$R+}{$Q+}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Transport, ERD.Card.Demo.Job, ERD.Card.Demo.Workflows,
  ERD.Card.Demo.FamilyWorkflows,
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Workflow.Batch,
  ERD.Card.Memory, ERD.Card.Memory.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.Workflow.DESFire;

type
  TMemory = class(TInterfacedObject, IContactMemoryWorkflowCard)
    Image: TMemoryCardSnapshot;
    Writes, Reads, FailAt, MinAttempts: Integer;
    Page: TMemoryCardPageSize;
    LastPin: TBytes;
    AuthFail, Mismatch: Boolean;
    constructor Create(const AModel: TMemoryCardModel);
    function Model: TMemoryCardModel;
    function PageSize: TMemoryCardPageSize;
    function MinimumPinAttempts: Integer;
    function ReadSnapshot: TMemoryCardSnapshot;
    function ReadRange(const AAddress, ACount: Integer): TBytes;
    procedure WriteRange(const AAddress: Integer; const AData, APin: TBytes);
  end;
  TWire = class(TInterfacedObject, ICardTransport, ICardTransaction)
    Data, Protection: TBytes;
    Begins, Ends, Writes, Authentications, Exchanges: Integer;
    constructor Create;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
    Source, Target: ICardTransport;
    Created: Integer;
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;
  TCard = class;
  TSession = class(TInterfacedObject, IDesfireSession, IDesfireManagement,
    IDesfireApplicationManagement)
    Card: TCard;
    Staged: TDesfireWorkflowFiles;
    FPending, FVerified, FClosed: Boolean;
    FOutcome: TDesfireSessionOutcome;
    constructor Create(const ACard: TCard);
    function Index(const AFile: Byte): Integer;
    procedure SetRecords(const AIndex: Integer);
    function ReadApplicationIds: TDesfireApplicationIds;
    function ReadApplicationSettings: TDesfireApplicationSettings;
    function ReadFiles: TDesfireFiles;
    function ReadData(const AFile: Byte; const AOffset, ACount: Integer): TBytes;
    function ReadValue(const AFile: Byte): Integer;
    function ReadRecords(const AFile: Byte; const AOffset, ACount: Integer): TBytes;
    procedure WriteBackup(const AFile: Byte; const AOffset: Integer; const AData: TBytes);
    procedure Credit(const AFile: Byte; const AAmount: Integer);
    procedure Debit(const AFile: Byte; const AAmount: Integer);
    procedure LimitedCredit(const AFile: Byte; const AAmount: Integer);
    procedure AppendRecord(const AFile: Byte; const AData: TBytes);
    procedure ClearRecords(const AFile: Byte);
    procedure Commit;
    procedure Abort;
    procedure CreateApplication(const AAid: Cardinal; const AKeySettings, AKeyCount: Byte);
    procedure DeleteApplication(const AAid: Cardinal);
    procedure CreateFile(const ADefinition: TDesfireFileDefinition);
    procedure DeleteFile(const AFile: Byte);
    procedure Close;
    function GetOutcome: TDesfireSessionOutcome;
    function GetVerificationSucceeded: Boolean;
    function GetPendingChanges: Boolean;
    function ReadFreeMemory: Integer;
    function ReadKeyVersion(const AKeyNumber: Byte): Byte;
    procedure ChangeKeySettings(const ASettings: Byte);
    procedure ChangeFileAccess(const AFile: Byte; const ACommunication: TDesfireCommunication; const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
    procedure ChangeAesKey(const AKeyNumber, ANewVersion: Byte; const ANewKey, AOldKey: TBytes);
    procedure CreateApplicationWithKeyType(const AAid: Cardinal; const AKeySettings, AKeyCount: Byte; const AKeyType: TDesfireApplicationKeyType);
  end;
  TCard = class(TInterfacedObject, IDesfireWorkflowCard)
    Snapshot: TDesfireWorkflowSnapshot;
    Writes, Opens, Closes, Commits, Aborts, AppCreates, FileCreates: Integer;
    FailFileAt, DenyFile, Limit: Integer;
    KeySettings, KeyConfiguration: Byte;
    FailCommit, FailClose, ChangeOnTransaction: Boolean;
    constructor Create;
    function TransferLimit: Integer;
    function ReadIdentity: TBytes;
    function OpenSession(const AAid: Cardinal; const AAccess: TDesfireSessionAccess): IDesfireSession;
    procedure ValidateWrite(const ASettings: TDesfireFileSettings; const AValueIncrease: Boolean);
    procedure WriteStandard(const AAid: Cardinal; const AFile: Byte; const AData: TBytes);
  end;
  TFamilyFactory = class(TInterfacedObject, ICardBatchFactory)
    Memory: IContactMemoryWorkflowCard;
    MemoryImage: TMemoryCardSnapshot;
    Desfire: IDesfireWorkflowCard;
    DesfireImage: TDesfireWorkflowSnapshot;
    function CreateWorkflow(const AIdentifier: string): TCardWorkflow;
  end;
  TObserver = class
    Phase: TCardWorkflowState;
    After: Integer;
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
  end;
var Checks: Integer;
procedure Check(const Value: Boolean; const Text: string);
begin Inc(Checks); if not Value then raise Exception.Create(Text); end;
function CopyFiles(const AFiles: TDesfireWorkflowFiles): TDesfireWorkflowFiles;
var I: Integer;
begin
  Result := nil; SetLength(Result, Length(AFiles));
  for I := 0 to High(AFiles) do begin Result[I] := AFiles[I];
    Result[I].Data := CopyBytes(AFiles[I].Data); Result[I].Settings.RawBytes := CopyBytes(AFiles[I].Settings.RawBytes); end;
end;
function Join(const A, B: TBytes): TBytes;
begin Result := CopyBytes(A); SetLength(Result, Length(A) + Length(B));
  if Length(B) > 0 then Move(B[0], Result[Length(A)], Length(B)); end;
constructor TMemory.Create(const AModel: TMemoryCardModel);
var L: TMemoryCardLayout; I: Integer;
begin
  inherited Create; Image.Model := AModel; L := TMemoryCardCodec.Layout(AModel);
  SetLength(Image.Data, L.Capacity); SetLength(Image.Protection, (L.ProtectableBytes + 7) div 8);
  for I := 0 to High(Image.Protection) do Image.Protection[I] := $FF;
  Image.HasSecurity := L.PinBytes <> 0; Image.Security.Counter := 7;
  Image.Security.RemainingAttempts := 3; MinAttempts := 1; Page := mps8;
end;
function TMemory.Model: TMemoryCardModel;
begin Result := Image.Model; end;
function TMemory.PageSize: TMemoryCardPageSize;
begin Result := Page; end;
function TMemory.MinimumPinAttempts: Integer;
begin Result := MinAttempts; end;
function TMemory.ReadSnapshot: TMemoryCardSnapshot;
begin Inc(Reads); Result := Image; Result.Data := CopyBytes(Image.Data); Result.Protection := CopyBytes(Image.Protection); end;
function TMemory.ReadRange(const AAddress, ACount: Integer): TBytes;
begin Result := Copy(Image.Data, AAddress, ACount); if Mismatch then Result[0] := Result[0] xor 1; end;
procedure TMemory.WriteRange(const AAddress: Integer; const AData, APin: TBytes);
begin
  LastPin := CopyBytes(APin);
  if AuthFail then raise EMemoryCardAuthenticationError.Create('PIN');
  Inc(Writes); Move(AData[0], Image.Data[AAddress], Length(AData));
  if Writes = FailAt then raise EMemoryCardWriteUncertain.Create('Write', False);
end;
procedure TObserver.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin if (AState = Phase) and (ADone >= After) then TCardWorkflow(Sender).Cancel; end;
constructor TCard.Create;
begin
  inherited Create; Snapshot.Aid := 1; Snapshot.Identity := HexToBytes('01020304050607');
  Limit := 65536; DenyFile := -1;
  SetLength(Snapshot.Files, 4);
  Snapshot.Files[0].Settings := TDesfireCodec.FileSettings(0, HexToBytes('0000EEEE040000'));
  Snapshot.Files[0].Data := HexToBytes('00000000');
  Snapshot.Files[1].Settings := TDesfireCodec.FileSettings(1, HexToBytes('0100EEEE040000'));
  Snapshot.Files[1].Data := HexToBytes('00000000');
  Snapshot.Files[2].Settings := TDesfireCodec.FileSettings(2, HexToBytes('0200EEEE00000000640000000000000000'));
  Snapshot.Files[2].Data := HexToBytes('00000000');
  Snapshot.Files[3].Settings := TDesfireCodec.FileSettings(3, HexToBytes('0300EEEE020000040000010000'));
  Snapshot.Files[3].Data := HexToBytes('1122');
end;
function TCard.TransferLimit: Integer;
begin Result := Limit; end;
function TCard.ReadIdentity: TBytes;
begin Result := CopyBytes(Snapshot.Identity); end;
function TCard.OpenSession(const AAid: Cardinal; const AAccess: TDesfireSessionAccess): IDesfireSession;
begin
  Inc(Opens);
  if ChangeOnTransaction and (AAccess in [dsaFreshTransaction, dsaDiscardPending]) then Snapshot.Files[1].Data[0] := $99;
  Result := TSession.Create(Self);
end;
procedure TCard.ValidateWrite(const ASettings: TDesfireFileSettings; const AValueIncrease: Boolean);
begin if ASettings.FileNumber = DenyFile then raise ECardWorkflowError.Create('Rights'); end;
procedure TCard.WriteStandard(const AAid: Cardinal; const AFile: Byte; const AData: TBytes);
var I: Integer;
begin Inc(Writes); for I := 0 to High(Snapshot.Files) do if Snapshot.Files[I].Settings.FileNumber = AFile then Snapshot.Files[I].Data := CopyBytes(AData); end;
constructor TSession.Create(const ACard: TCard);
begin inherited Create; Card := ACard; Staged := CopyFiles(Card.Snapshot.Files); FOutcome := dsoActive; end;
function TSession.Index(const AFile: Byte): Integer;
var I: Integer;
begin Result := -1; for I := 0 to High(Staged) do if Staged[I].Settings.FileNumber = AFile then begin Result := I; Exit; end;
  raise ECardWorkflowError.Create('File'); end;
procedure TSession.SetRecords(const AIndex: Integer);
var N: Integer;
begin N := Staged[AIndex].Settings.CurrentRecords;
  Staged[AIndex].Settings.RawBytes[10] := N; Staged[AIndex].Settings.RawBytes[11] := 0; Staged[AIndex].Settings.RawBytes[12] := 0; end;
function TSession.ReadApplicationIds: TDesfireApplicationIds;
begin
  Result := nil; SetLength(Result, 1); Result[0] := Card.Snapshot.Aid;
end;

function TSession.ReadApplicationSettings: TDesfireApplicationSettings;
begin
  Result := Default(TDesfireApplicationSettings); Result.KeySettings := Card.KeySettings; Result.KeyConfiguration := Card.KeyConfiguration;
end;

function TSession.ReadFiles: TDesfireFiles;
var I: Integer;
begin
  Result := nil; SetLength(Result, Length(Staged)); for I := 0 to High(Staged) do Result[I] := Staged[I].Settings;
end;

function TSession.ReadData(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
begin
  Result := Copy(Staged[Index(AFile)].Data, AOffset, ACount);
end;

function TSession.ReadValue(const AFile: Byte): Integer;
begin
  Result := TDesfireCodec.SignedValue(Staged[Index(AFile)].Data);
end;

function TSession.ReadRecords(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
var I: Integer;
begin
  I := Index(AFile); Result := Copy(Staged[I].Data, AOffset * Staged[I].Settings.RecordBytes, ACount * Staged[I].Settings.RecordBytes);
end;

procedure TSession.WriteBackup(const AFile: Byte; const AOffset: Integer;
      const AData: TBytes);
var I: Integer;
begin
  I := Index(AFile); Move(AData[0], Staged[I].Data[AOffset], Length(AData)); FPending := True; Inc(Card.Writes);
end;

procedure TSession.Credit(const AFile: Byte; const AAmount: Integer);
var I, V: Integer;
begin
  I := Index(AFile); V := TDesfireCodec.SignedValue(Staged[I].Data) + AAmount; Move(V, Staged[I].Data[0], 4); FPending := True; Inc(Card.Writes);
end;

procedure TSession.Debit(const AFile: Byte; const AAmount: Integer);
var I, V: Integer;
begin
  I := Index(AFile); V := TDesfireCodec.SignedValue(Staged[I].Data) - AAmount; Move(V, Staged[I].Data[0], 4); FPending := True; Inc(Card.Writes);
end;

procedure TSession.LimitedCredit(const AFile: Byte; const AAmount: Integer);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: LimitedCredit');
end;

procedure TSession.AppendRecord(const AFile: Byte; const AData: TBytes);
var I: Integer;
begin
  I := Index(AFile); Staged[I].Data := Join(AData, Staged[I].Data); Inc(Staged[I].Settings.CurrentRecords); SetRecords(I); FPending := True; Inc(Card.Writes);
end;

procedure TSession.ClearRecords(const AFile: Byte);
var I: Integer;
begin
  I := Index(AFile); Staged[I].Data := nil; Staged[I].Settings.CurrentRecords := 0; SetRecords(I); FPending := True; Inc(Card.Writes);
end;

procedure TSession.Commit;
begin
  Inc(Card.Commits); Card.Snapshot.Files := CopyFiles(Staged); FPending := False;
  if Card.FailCommit then begin FOutcome := dsoUncertain; raise EContactlessWriteUncertain.Create('Commit'); end;
  FOutcome := dsoCommitted; FVerified := True; Close;
end;

procedure TSession.Abort;
begin
  Inc(Card.Aborts); FPending := False; FOutcome := dsoAborted; Close;
end;

procedure TSession.CreateApplication(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: CreateApplication');
end;

procedure TSession.DeleteApplication(const AAid: Cardinal);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: DeleteApplication');
end;

procedure TSession.CreateFile(const ADefinition: TDesfireFileDefinition);
var I: Integer;
begin
  Inc(Card.FileCreates); I := Length(Card.Snapshot.Files); SetLength(Card.Snapshot.Files, I + 1);
  Card.Snapshot.Files[I].Settings.FileNumber := ADefinition.FileNumber;
  if Card.FailFileAt = Card.FileCreates then raise EContactlessWriteUncertain.Create('Create');
end;

procedure TSession.DeleteFile(const AFile: Byte);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: DeleteFile');
end;

procedure TSession.Close;
begin
  if not FClosed then begin FClosed := True; Inc(Card.Closes);
    if FOutcome = dsoActive then if FPending then FOutcome := dsoUncertain else FOutcome := dsoClosed;
    if Card.FailClose then raise ECardWorkflowError.Create('Close'); end;
end;

function TSession.GetOutcome: TDesfireSessionOutcome;
begin
  Result := FOutcome;
end;

function TSession.GetVerificationSucceeded: Boolean;
begin
  Result := FVerified;
end;

function TSession.GetPendingChanges: Boolean;
begin
  Result := FPending;
end;

function TSession.ReadFreeMemory: Integer;
begin
  Result := 0; raise ECardWorkflowError.Create('Unexpected fake method: ReadFreeMemory');
end;

function TSession.ReadKeyVersion(const AKeyNumber: Byte): Byte;
begin
  Result := 0; raise ECardWorkflowError.Create('Unexpected fake method: ReadKeyVersion');
end;

procedure TSession.ChangeKeySettings(const ASettings: Byte);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: ChangeKeySettings');
end;

procedure TSession.ChangeFileAccess(const AFile: Byte;
      const ACommunication: TDesfireCommunication;
      const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: ChangeFileAccess');
end;

procedure TSession.ChangeAesKey(const AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
begin
  raise ECardWorkflowError.Create('Unexpected fake method: ChangeAesKey');
end;

procedure TSession.CreateApplicationWithKeyType(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte;
      const AKeyType: TDesfireApplicationKeyType);
begin
  Inc(Card.AppCreates); Card.Snapshot.Aid := AAid;
  Card.KeySettings := AKeySettings; Card.KeyConfiguration := AKeyCount;
  case AKeyType of daktThreeKey3Des: Card.KeyConfiguration := Card.KeyConfiguration or $40;
    daktAes: Card.KeyConfiguration := Card.KeyConfiguration or $80; end;
end;

constructor TWire.Create;
begin inherited; SetLength(Data, 256); Protection := HexToBytes('FFFFFFFF'); end;
procedure TWire.BeginTransaction;
begin Inc(Begins); end;
procedure TWire.EndTransaction;
begin Inc(Ends); end;
function TWire.Exchange(const ACommand: TBytes): TBytes;
var Address, Count: Integer;
begin
  Inc(Exchanges); Result := nil; Address := ACommand[2] * 256 + ACommand[3];
  case ACommand[1] of
    $A4: ;
    $B0: Result := Copy(Data, Address, ACommand[4]);
    $B2: Result := CopyBytes(Protection);
    $B1: Result := HexToBytes('07000000');
    $20: begin Inc(Authentications); Result := HexToBytes('9007'); Exit; end;
    $D0: begin Count := ACommand[4]; Move(ACommand[5], Data[Address], Count); Inc(Writes); end;
  else raise ECardTransportError.Create('Unexpected native memory APDU.'); end;
  SetLength(Result, Length(Result) + 2); Result[High(Result) - 1] := $90; Result[High(Result)] := 0;
end;
function TReaders.CreateTransport(const AName: UnicodeString): ICardTransport;
begin Inc(Created); if AName = 'source' then Result := Source else if AName = 'target' then Result := Target
  else raise ECardWorkflowError.Create('Unknown reader.'); end;
function TFamilyFactory.CreateWorkflow(const AIdentifier: string): TCardWorkflow;
var M: TContactMemoryWorkflow; D: TDesfireApplicationWorkflow;
begin
  if Pos('memory', AIdentifier) = 1 then begin
    M := TContactMemoryWorkflow.Create(nil);
    try M.PrepareRestore(MemoryImage, Memory, 0, 16, HexToBytes('010203')); except M.Free; raise; end;
    Result := M;
  end else begin
    D := TDesfireApplicationWorkflow.Create(nil);
    try D.PrepareRestore(DesfireImage, Desfire, DesfireImage.Aid, dsaFreshTransaction); except D.Free; raise; end;
    Result := D;
  end;
end;
procedure NativeDemoTests;
var Source, Target: TWire; Readers: TReaders; Factory: ICardWorkflowDemoReaders;
  Operations: ICardDemoOperations; Validator: ICardDemoRequestValidator;
  Request: TCardDemoRequest; Output: TCardDemoResult; Error: UnicodeString;
  Snapshot: TMemoryCardSnapshot; Before: Integer; Raised: Boolean;
begin
  Source := TWire.Create; Target := TWire.Create; Source.Data[4] := $55;
  Readers := TReaders.Create; Factory := Readers; Readers.Source := Source; Readers.Target := Target;
  Operations := CreateCardFamilyWorkflowOperations(Factory); Supports(Operations, ICardDemoRequestValidator, Validator);
  Request := Default(TCardDemoRequest); Request.Operation := cdoFamily;
  Request.FamilyName := 'ContactMemoryWorkflowDemo'; Request.FamilyAction := 0; Request.ReaderName := 'source';
  SetLength(Request.Arguments, 4); SetLength(Request.Credentials, 3);
  Request.Arguments[0] := 'target'; Request.Arguments[1] := '1'; Request.Arguments[3] := '8|0|0|32|1';
  Check(Validator.TryValidateRequest(Request, Error), 'Contact demo metadata');
  Operations.Run(Request, Output);
  Check(Output.Success and (Length(Output.Artifacts) = 1) and (Source.Authentications = 0), 'Native contact demo full public backup');
  Snapshot := TContactMemoryWorkflowArchive.Decode(string(TEncoding.UTF8.GetString(Output.Artifacts[0].Data)));
  Check((Length(Snapshot.Data) = 256) and (Snapshot.Data[4] = $55), 'Native contact archive complete bytes');
  Request.FamilyAction := 3; Request.MutationAcknowledged := True;
  Request.Credentials[1] := HexToBytes('010203'); Request.Arguments[2] := UnicodeString(TContactMemoryWorkflowArchive.Encode(Snapshot));
  Operations.Run(Request, Output);
  Check(Output.Success and (Target.Data[4] = $55) and (Target.Writes = 1), 'Native contact demo restore and verification');
  Check((Target.Authentications = 1) and (Target.Begins = Target.Ends), 'One explicit PIN attempt for one changed run');
  Before := Readers.Created; Request.Arguments[2] := 'invalid'; Raised := False;
  try Operations.Run(Request, Output); except on E: ECardWorkflowError do Raised := True; end;
  Check(Raised and (Readers.Created = Before), 'Invalid contact archive creates no readers');
  Request.FamilyName := 'DesfireWorkflowDemo'; Request.Arguments[1] := '0';
  Request.Credentials[1] := nil; Request.Arguments[3] := '1|1|0|0|65536|48|0'; Raised := False;
  try Operations.Run(Request, Output); except on E: ECardWorkflowError do Raised := True; end;
  Check(Raised and (Readers.Created = Before), 'Invalid DESFire archive creates no readers');
end;
procedure FamilyBatchTests;
var Factory: TFamilyFactory; F: ICardBatchFactory; Memory: TMemory; Card: TCard;
  Ids: TCardBatchIdentifiers; Batch: TCardBatchWorkflow;
begin
  Factory := TFamilyFactory.Create; F := Factory;
  Memory := TMemory.Create(mcmSle4442); Factory.Memory := Memory; Factory.MemoryImage := Memory.ReadSnapshot;
  Factory.MemoryImage.Data[1] := $44;
  Card := TCard.Create; Factory.Desfire := Card; Factory.DesfireImage := Card.Snapshot;
  Factory.DesfireImage.Files := CopyFiles(Card.Snapshot.Files); Factory.DesfireImage.Files[1].Data := HexToBytes('11223344');
  Card.FailCommit := True;
  SetLength(Ids, 3); Ids[0] := 'memory-1'; Ids[1] := 'desfire-1'; Ids[2] := 'memory-2';
  Batch := TCardBatchWorkflow.Create(nil);
  try
    Batch.Prepare(Ids, F);
    Check((Memory.Writes = 0) and (Card.Opens = 0), 'Mixed-family batch prepares before I/O');
    Check(Batch.Execute = cwsUncertain, 'Mixed-family batch propagates commit uncertainty');
    Check((Batch.Results[0].State = cwsCompleted) and not Batch.Results[2].Attempted, 'Mixed-family batch retains memory success and stops later cards');
    Check(TContactMemoryWorkflow(Batch.Child(0)).Results[0].State = cwusVerified, 'Retained family-specific child evidence');
  finally Batch.Free; F := nil; end;
end;

procedure MemoryTests;
var Source, Target: TMemory; S, T: IContactMemoryWorkflowCard;
  Flow: TContactMemoryWorkflow; Snapshot: TMemoryCardSnapshot;
  Pin: TBytes; Observer: TObserver; Text: string; Raised: Boolean;
begin
  Source := TMemory.Create(mcmSle4442); Target := TMemory.Create(mcmSle4442); S := Source; T := Target;
  Flow := TContactMemoryWorkflow.Create(nil); Observer := TObserver.Create;
  try
    Source.Image.Data[2] := $AA; Source.Image.Data[5] := $BB;
    Pin := HexToBytes('010203'); Flow.PrepareCopy(S, T, 0, 16, Pin); Pin[0] := $FF;
    Check((Source.Reads = 0) and (Target.Reads = 0), 'Contact preparation has no I/O');
    Target.Image.Protection[0] := $DF;
    Check(Flow.Execute = cwsFailed, 'Later protected contact byte rejected before writes');
    Check(Target.Writes = 0, 'No earlier write before complete protection preflight');
    Flow.PrepareCopy(S, T, 0, 16, nil, True);
    Check((Flow.Execute = cwsCompleted) and (Length(Flow.Results) = 2), 'Contact comparison reads protected differences');
    Target.Image.Protection[0] := $FB;
    Target.Image.Data[2] := $AA;
    Flow.PrepareCopy(S, T, 0, 16, HexToBytes('010203'));
    Check(Flow.Execute = cwsCompleted, 'Unchanged protected bytes remain untouched');
    Check((Target.Writes = 1) and BytesEqual(Target.LastPin, HexToBytes('010203')), 'Exactly one differing run and explicit PIN');
    Snapshot := Flow.Snapshot; Text := TContactMemoryWorkflowArchive.Encode(Snapshot);
    Check(BytesEqual(TContactMemoryWorkflowArchive.Decode(Text).Data, Snapshot.Data), 'Contact archive complete roundtrip');
    Snapshot.Data[2] := $11; Snapshot.Data[5] := $22; Target.Image.Protection[0] := $FF;
    Target.FailAt := Target.Writes + 2;
    Flow.PrepareRestore(Snapshot, T, 0, 16, HexToBytes('010203'));
    Check(Flow.Execute = cwsUncertain, 'Contact partial second-run failure');
    Check((Flow.Results[0].State = cwusVerified) and (Flow.Results[1].State = cwusUncertain), 'Contact partial ledger');
    Target.FailAt := 0; Target.AuthFail := True; Snapshot.Data[2] := $33;
    Flow.PrepareRestore(Snapshot, T, 0, 16, HexToBytes('010203'));
    Check(Flow.Execute = cwsFailed, 'PIN rejection is not reported as uncertain data mutation');
    Target.AuthFail := False; Target.MinAttempts := 4;
    Flow.PrepareRestore(Snapshot, T, 0, 16, HexToBytes('010203'));
    Check(Flow.Execute = cwsFailed, 'Retry threshold respected before authentication');
    Target.MinAttempts := 1;
    Observer.Phase := cwsWriting; Observer.After := 0; Flow.OnProgress := Observer.Progress;
    Flow.PrepareRestore(Snapshot, T, 0, 16, HexToBytes('010203'));
    Check(Flow.Execute = cwsCancelled, 'Contact cancellation before mutation');
    Raised := False; try TContactMemoryWorkflowArchive.Decode(Text + 'extra'); except on E: ECardWorkflowError do Raised := True; end;
    Check(Raised, 'Contact archive trailing input rejected');
  finally Observer.Free; Flow.Free; S := nil; T := nil; end;
  Source := TMemory.Create(mcmI2c1024Kbit); S := Source; Flow := TContactMemoryWorkflow.Create(nil);
  try
    Flow.PrepareBackup(S); Check(Flow.Execute = cwsCompleted, 'Complete 128KiB I2C backup');
    Check(Length(Flow.Snapshot.Data) = 131072, 'No contact snapshot window truncation');
  finally Flow.Free; S := nil; end;
end;
procedure DesfireTests;
var Source, Target: TCard; S, T: IDesfireWorkflowCard; Flow: TDesfireApplicationWorkflow;
  Snapshot: TDesfireWorkflowSnapshot; Observer: TObserver; Text: string; Raised: Boolean;
  Provision: TDesfireProvisionWorkflow; Definitions: TDesfireWorkflowDefinitions;
begin
  Source := TCard.Create; Target := TCard.Create; S := Source; T := Target;
  Source.Snapshot.Files[0].Data := HexToBytes('01020304'); Source.Snapshot.Files[1].Data := HexToBytes('11223344');
  Source.Snapshot.Files[2].Data := HexToBytes('32000000');
  Source.Snapshot.Files[3].Settings := TDesfireCodec.FileSettings(3, HexToBytes('0300EEEE020000040000020000'));
  Source.Snapshot.Files[3].Data := HexToBytes('AABBCCDD');
  Flow := TDesfireApplicationWorkflow.Create(nil); Observer := TObserver.Create;
  try
    Flow.PrepareCopy(S, T, 1, 1, dsaFreshTransaction);
    Check((Source.Opens = 0) and (Target.Opens = 0), 'DESFire prepare no I/O');
    Target.DenyFile := 3;
    Check(Flow.Execute = cwsFailed, 'Later DESFire write rights reject before all mutations');
    Check((Target.Writes = 0) and (Target.Commits = 0), 'No immediate writes before complete rights preflight');
    Target.DenyFile := -1; Flow.PrepareCopy(S, T, 1, 1, dsaFreshTransaction);
    Check(Flow.Execute = cwsCompleted, 'DESFire ordinary application data migration');
    Check((Target.Commits = 1) and (Target.Aborts = 0), 'One transaction commit');
    Check(BytesEqual(Target.Snapshot.Files[3].Data, HexToBytes('AABBCCDD')), 'Record newest-first order preserved');
    Check((Flow.Results[0].State = cwusVerified) and (Flow.Results[3].State = cwusVerified), 'Immediate and committed file evidence');
    Check(Target.Opens = Target.Closes, 'All DESFire sessions released');
    Snapshot := Flow.Snapshot; Text := TDesfireWorkflowArchive.Encode(Snapshot);
    Check(BytesEqual(TDesfireWorkflowArchive.Decode(Text).Files[3].Data, Snapshot.Files[3].Data), 'DESFire full archive roundtrip');
    Snapshot.Files[1].Data := HexToBytes('55667788'); Target.FailCommit := True;
    Flow.PrepareRestore(Snapshot, T, 1, dsaFreshTransaction);
    Check(Flow.Execute = cwsUncertain, 'Commit acknowledgement failure retained');
    Check(Flow.Results[1].State = cwusUncertain, 'No false commit verification');
    Target.FailCommit := False; Snapshot.Files[1].Data := HexToBytes('10203040');
    Target.ChangeOnTransaction := True; Flow.PrepareRestore(Snapshot, T, 1, dsaFreshTransaction);
    Check(Flow.Execute = cwsFailed, 'Retained transaction rechecks preflight originals');
    Check(Target.Aborts = 0, 'Preflight race does not invent abort/recovery');
    Target.ChangeOnTransaction := False;
    Observer.Phase := cwsVerifying; Observer.After := 0; Flow.OnProgress := Observer.Progress;
    Flow.PrepareRestore(Snapshot, T, 1, dsaFreshTransaction);
    Check(Flow.Execute = cwsCancelled, 'Cancellation before commit');
    Check((Target.Aborts = 1) and (Flow.Results[1].State = cwusPending), 'Owned staged changes explicitly aborted');
    Flow.OnProgress := nil; Target.Limit := 3;
    Flow.PrepareRestore(Snapshot, T, 1, dsaFreshTransaction);
    Check(Flow.Execute = cwsFailed, 'Configured transfer budget checked');
    Raised := False; try TDesfireWorkflowArchive.Decode(Text + 'extra'); except on E: ECardWorkflowError do Raised := True; end;
    Check(Raised, 'DESFire archive trailing garbage rejected');
  finally Flow.Free; Observer.Free; S := nil; T := nil; end;
  Target := TCard.Create; T := Target; Provision := TDesfireProvisionWorkflow.Create(nil);
  try
    SetLength(Definitions, 2); Definitions[0] := Default(TDesfireFileDefinition);
    Definitions[0].FileNumber := 5; Definitions[0].FileType := dftStandard;
    Definitions[0].Communication := dfcPlain; Definitions[0].ReadKey := 14;
    Definitions[0].WriteKey := 14; Definitions[0].ReadWriteKey := 14; Definitions[0].ChangeKey := 14;
    Definitions[0].FileBytes := 4; Definitions[1] := Definitions[0]; Definitions[1].FileNumber := 6;
    Target.FailFileAt := 2; Provision.Prepare(T, T, 2, $0F, 1, daktAes, Definitions);
    Check(Target.Opens = 0, 'Provisioning preflight does not acquire hardware');
    Check(Provision.Execute = cwsUncertain, 'Partial file creation failure');
    Check(Provision.ApplicationCreated and (Provision.Results[0].State = cwusVerified) and
      (Provision.Results[1].State = cwusUncertain), 'Provisioning retains immediate partial results');
    Definitions[1].FileNumber := 5; Raised := False;
    try Provision.Prepare(T, T, 3, $0F, 1, daktAes, Definitions); except on E: ECardWorkflowError do Raised := True; end;
    Check(Raised, 'Duplicate creation definitions rejected before mutation');
  finally Provision.Free; T := nil; end;
  Target := TCard.Create; T := Target; Provision := TDesfireProvisionWorkflow.Create(nil);
  try
    Definitions := nil; Provision.Prepare(T, T, 2, $0F, 1, daktAes, Definitions);
    Check(Provision.Execute = cwsCompleted, 'Empty application provisioning completes');
    Check(Provision.ApplicationCreated and (Target.Opens = 2) and (Target.Closes = 2),
      'Empty provisioning verifies application policy and closes both sessions');
  finally Provision.Free; T := nil; end;
end;
begin
  try
    MemoryTests; DesfireTests; NativeDemoTests; FamilyBatchTests;
    Writeln('PASS: ', Checks, ' contact-memory/DESFire workflow assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
