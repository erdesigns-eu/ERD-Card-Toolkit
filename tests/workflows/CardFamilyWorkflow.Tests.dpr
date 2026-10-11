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
  ERD.Card.Demo.FamilyWorkflows, ERD.Card.Demo.Personalization,
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Workflow.Batch,
  ERD.Card.Memory, ERD.Card.Memory.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.Workflow.DESFire,
  ERD.Card.Memory.Sle4404, ERD.Card.Memory.Counter, ERD.Card.Memory.Workflow.Sle,
  ERD.Card.Contactless.Workflow.Personalization;

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
    FailCommit, FailClose, ChangeOnTransaction, FailAdmin: Boolean;
    AdminWrites: Integer;
    Versions: array[0..13] of Byte;
    Material: TBytes;
    constructor Create;
    function TransferLimit: Integer;
    function ReadIdentity: TBytes;
    function OpenSession(const AAid: Cardinal; const AAccess: TDesfireSessionAccess): IDesfireSession;
    procedure ValidateWrite(const ASettings: TDesfireFileSettings; const AValueIncrease: Boolean);
    procedure WriteStandard(const AAid: Cardinal; const AFile: Byte; const AData: TBytes);
  end;
  TKeyProof = class(TInterfacedObject, IDesfirePersonalizationKeyProof)
    Card: IDesfireWorkflowCard;
    ObjectCard: TCard;
    Calls: Integer;
    Fail: Boolean;
    procedure Verify(const AAid: Cardinal; const AKeyNumber, AVersion: Byte);
    function ReadIdentity: TBytes;
  end;
  TSleCard = class(TInterfacedObject, ISleWorkflowCard)
    Data: TBytes;
    Writes, Reads, FailAt: Integer;
    Mismatch: Boolean;
    function Layout: string;
    function Address: Integer;
    function ByteCount: Integer;
    procedure ValidateStep(const AStep: TSleWorkflowStep);
    function ReadWindow: TBytes;
    procedure Apply(const AStep: TSleWorkflowStep);
  end;
  TCounterWire = class(TInterfacedObject, ICardTransport, ICardTransaction)
    Data: TBytes;
    Writes, Exchanges, Begins, Ends, FailAt: Integer;
    Active, EndFail, Sle4404: Boolean;
    Authentications: Integer;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
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
  Result := Card.Versions[AKeyNumber];
end;

procedure TSession.ChangeKeySettings(const ASettings: Byte);
begin
  Inc(Card.AdminWrites); Card.KeySettings := ASettings;
  if Card.FailAdmin then raise EContactlessWriteUncertain.Create('Injected dispatch');
end;

procedure TSession.ChangeFileAccess(const AFile: Byte;
      const ACommunication: TDesfireCommunication;
      const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
begin
  Inc(Card.AdminWrites);
  with Card.Snapshot.Files[Index(AFile)].Settings do
  begin Communication := ACommunication; ReadKey := AReadKey; WriteKey := AWriteKey;
    ReadWriteKey := AReadWriteKey; ChangeKey := AChangeKey; end;
  if Card.FailAdmin then raise EContactlessWriteUncertain.Create('Injected dispatch');
end;

procedure TSession.ChangeAesKey(const AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
begin
  Inc(Card.AdminWrites); Card.Versions[AKeyNumber] := ANewVersion;
  Card.Material := CopyBytes(ANewKey);
  if Card.FailAdmin then raise EContactlessWriteUncertain.Create('Injected dispatch');
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

procedure TKeyProof.Verify(const AAid: Cardinal; const AKeyNumber, AVersion: Byte);
begin
  Inc(Calls);
  if Fail or (ObjectCard.Versions[AKeyNumber] <> AVersion) then raise ECardWorkflowError.Create('Proof');
end;
function TKeyProof.ReadIdentity: TBytes;
begin Result := Card.ReadIdentity; end;
function TSleCard.Layout: string;
begin Result := 'INJECTED-SLE'; end;
function TSleCard.Address: Integer;
begin Result := 0; end;
function TSleCard.ByteCount: Integer;
begin Result := Length(Data); end;
procedure TSleCard.ValidateStep(const AStep: TSleWorkflowStep);
begin
  if (Length(AStep.Before) <> Length(Data)) or (Length(AStep.After) <> Length(Data)) then
    raise ECardWorkflowError.Create('Invalid geometry');
end;
function TSleCard.ReadWindow: TBytes;
begin Inc(Reads); Result := CopyBytes(Data); end;
procedure TSleCard.Apply(const AStep: TSleWorkflowStep);
begin
  Inc(Writes); Data := CopyBytes(AStep.After);
  if Writes = FailAt then raise EMemoryCardWriteUncertain.Create('Dispatch', False);
  if Mismatch then Data[0] := Data[0] xor 1;
end;
procedure TCounterWire.BeginTransaction;
begin Check(not Active, 'Exclusive counter transaction'); Active := True; Inc(Begins); end;
procedure TCounterWire.EndTransaction;
begin Check(Active, 'Release acquired transaction'); Active := False; Inc(Ends);
  if EndFail and (Writes > 0) then raise ECardTransportError.Create('Release'); end;
function TCounterWire.Exchange(const ACommand: TBytes): TBytes;
var I: Integer;
begin
  Check(Active, 'Counter APDU inside transaction'); Inc(Exchanges);
  if Exchanges = FailAt then raise ECardTransportError.Create('Injected boundary');
  Check((Length(ACommand) >= 5) and (ACommand[0] = $FF), 'ACS command framing');
  case ACommand[1] of
    $A4: begin
      if Sle4404 then Check(BytesToHex(ACommand) = 'FFA400000108', 'Literal SLE4404 selector')
      else Check(BytesToHex(ACommand) = 'FFA400000107', 'Literal counter selector'); Result := nil; end;
    $B0: begin Result := Copy(Data, ACommand[3], ACommand[4]);
      Check(Length(Result) = ACommand[4], 'Exact readable counter range'); end;
    $D0: begin
      Inc(Writes);
      if Sle4404 then
      begin
        Check(Length(ACommand) = 5 + ACommand[4], 'Literal SLE4404 programming framing');
        for I := 0 to ACommand[4] - 1 do Data[ACommand[3] + I] := ACommand[5 + I];
      end
      else
      begin
        Check(Length(ACommand) = 7, 'Literal counter write framing');
        Check(ACommand[5] = 0, 'Explicit plain mode'); Data[ACommand[3]] := ACommand[6];
      end;
      Result := nil;
    end;
    $D2: begin
      Check(Sle4404 and (BytesToHex(ACommand) = 'FFD2003000'), 'Literal scratchpad erase');
      Inc(Writes); Data[48] := $FF; Data[49] := $FF; Result := nil;
    end;
    $20: begin
      Check(Sle4404, 'Explicit SLE4404 code command');
      if ACommand[2] = 4 then
      begin
        Check(BytesToHex(ACommand) = 'FF200408021234', 'Literal caller user code');
        Inc(Authentications); Data[0] := $FF;
      end
      else
      begin
        Check(BytesToHex(ACommand) = 'FF2040280401020304', 'Literal caller memory code');
        Inc(Writes); Data[16] := $FE; Data[50] := $FF; Data[51] := $FF;
      end;
      Result := nil;
    end;
  else raise ECardTransportError.Create('Unexpected command');
  end;
  I := Length(Result); SetLength(Result, I + 2); Result[I] := $90; Result[I + 1] := 0;
end;
procedure SleWorkflowTests;
var Card: TSleCard; C: ISleWorkflowCard; Flow: TSleCounterWorkflow;
  Steps: TSleWorkflowSteps; Rejected: Boolean; Snapshot: TSleWorkflowSnapshot;
  Native: TSleCounterCardReaderWriter; Wire: TCounterWire; Transport: ICardTransport;
  I, N: Integer; State: TCardWorkflowState; S4404: TSle4404CardReaderWriter;
begin
  Card := TSleCard.Create; C := Card; Card.Data := HexToBytes('FFFF');
  SetLength(Steps, 2);
  Steps[0].Action := swaCounterByte; Steps[0].Count := 1;
  Steps[0].Before := HexToBytes('FFFF'); Steps[0].After := HexToBytes('FEFF');
  Steps[1] := Steps[0]; Steps[1].Address := 1;
  Steps[1].Before := HexToBytes('FEFF'); Steps[1].After := HexToBytes('FEFC');
  Flow := TSleCounterWorkflow.Create(nil);
  try
    Flow.Prepare(C, Steps, True); Check(Card.Reads = 0, 'SLE preparation no I/O');
    Check(Flow.Execute = cwsCompleted, 'SLE preview complete'); Check(Card.Writes = 0, 'Preview no mutations');
    Snapshot := Flow.Snapshot; Snapshot.Data[0] := 0;
    Check(Flow.Snapshot.Data[0] = $FF, 'Independent SLE snapshot');
    Flow.Prepare(C, Steps); Steps[0].After[0] := 0;
    Check(Flow.Execute = cwsCompleted, 'Copied two-step plan');
    Check((Card.Writes = 2) and (Flow.Results[0].State = cwusVerified), 'Verified SLE ledger');
    Steps[0].After[0] := $FE;
    Flow.Prepare(C, Steps, False, 2); Check(Flow.Execute = cwsCompleted, 'Freshly verified complete prefix');
    Check(Card.Writes = 2, 'Prefix never replayed');
    Card.Data := HexToBytes('FFFF'); Flow.Prepare(C, Steps, False, 1);
    Check(Flow.Execute = cwsFailed, 'Wrong prefix rejected'); Check(Card.Writes = 2, 'No write on stale resume');
    Card.FailAt := 4; Flow.Prepare(C, Steps);
    Check(Flow.Execute = cwsUncertain, 'Partial uncertain SLE write');
    Check((Flow.Results[0].State = cwusVerified) and (Flow.Results[1].State = cwusUncertain), 'Per-step partial ledger');
    Steps[1].Before[0] := $FF; Rejected := False;
    try Flow.Prepare(C, Steps); except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'Whole chain validated offline'); Steps[1].Before[0] := $FE;
    SetLength(Steps, 1); Steps[0].Before := CopyBytes(Card.Data); Steps[0].After := CopyBytes(Card.Data);
    Steps[0].Mode := scwCarry; Flow.Prepare(C, Steps);
    Check(Flow.Execute = cwsCompleted, 'Explicit identical-image carry remains executable');
    Check(Card.Writes = 5, 'Carry side effects are never silently skipped');
  finally Flow.Free; C := nil; end;
  // Literal native transcript with every exchange boundary failed in turn.
  SetLength(Steps, 1); Steps[0].Before := HexToBytes('FFFF'); Steps[0].After := HexToBytes('FEFF');
  Steps[0].Address := 0; Steps[0].Mode := scwProgram;
  N := 0;
  for I := 0 to 15 do
  begin
    Wire := TCounterWire.Create; Transport := Wire; Wire.Data := HexToBytes('FFFF'); Wire.FailAt := I;
    Native := TSleCounterCardReaderWriter.Create(nil); Flow := TSleCounterWorkflow.Create(nil);
    try
      Native.ReadableBytes := 2; Native.Transport := Transport;
      C := TSleCounterWorkflowCard.Create(Native); Native.Free; Native := nil;
      Flow.Prepare(C, Steps); Check(Wire.Exchanges = 0, 'Native prepare no acquisition');
      State := Flow.Execute; if I = 0 then N := Wire.Exchanges;
      if (I = 0) or (I > N) then Check(State = cwsCompleted, 'Native counter completed')
      else if Wire.Writes > 0 then Check(State = cwsUncertain, 'After native mutation failure uncertain')
      else Check(State in [cwsFailed, cwsUncertain], 'Pre-dispatch failure retained');
      Check(Wire.Writes <= 1, 'Native mutation never retried');
      Check((not Wire.Active) and (Wire.Begins = Wire.Ends), 'Native transaction balanced');
    finally Flow.Free; C := nil; Native.Free; Transport := nil; end;
  end;
  Check(N = 10, 'All ten native ACS exchange boundaries covered');
  Native := TSleCounterCardReaderWriter.Create(nil);
  try
    Native.ReadableBytes := 2; Native.Model := scmSle4406; C := TSleCounterWorkflowCard.Create(Native);
    Steps[0].Mode := scwBackup; Rejected := False;
    try C.ValidateStep(Steps[0]); except on E: ECardWorkflowError do Rejected := True;
      on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected, 'SLE4406 backup rejected offline'); C := nil;
  finally Native.Free; end;
  S4404 := TSle4404CardReaderWriter.Create(nil);
  try
    S4404.ReadableBytes := 64; Rejected := False;
    try C := TSle4404WorkflowCard.Create(S4404, 8, 2, nil, nil);
    except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'Secret code storage excluded from public snapshots');
    C := TSle4404WorkflowCard.Create(S4404, 16, 2, nil, nil);
    Steps[0].Mode := scwProgram; Steps[0].Action := swaProgram; Steps[0].Address := 16;
    Steps[0].Before := HexToBytes('00FF'); Steps[0].After := HexToBytes('FFFF'); Rejected := False;
    try C.ValidateStep(Steps[0]); except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'SLE4404 zero-to-one never converted to erase'); C := nil;
  finally S4404.Free; end;
end;
procedure SlePlannerAndNativeTests;
var Native: TSleCounterCardReaderWriter; S4404: TSle4404CardReaderWriter;
  C: ISleWorkflowCard; Snapshot: TSleWorkflowSnapshot; Desired: TBytes;
  Steps, Decoded: TSleWorkflowSteps; Text: string; I, J, Fail: Integer; Rejected: Boolean;
  Wire: TCounterWire; Transport: ICardTransport; Flow: TSle4404Workflow;
  Layout: TSle4404AccessLayout; Before: TBytes;
begin
  Native := TSleCounterCardReaderWriter.Create(nil);
  try
    for I := 1 to 256 do
    begin
      C := nil; Native.ReadableBytes := I; C := TSleCounterWorkflowCard.Create(Native);
      Snapshot.Layout := C.Layout; Snapshot.Address := 0;
      SetLength(Snapshot.Data, I); SetLength(Desired, I);
      for J := 0 to I - 1 do begin Snapshot.Data[J] := $FF; Desired[J] := $7F; end;
      Steps := TSleWorkflowPlanner.ProgramPlan(Snapshot, Desired, C, swaCounterByte);
      Check(Length(Steps) = I, 'Complete bounded offline counter allocation');
      Check(Length(TSleWorkflowPlanner.Compare(Snapshot, Desired)) = I, 'Physical byte comparison');
      Text := TSleWorkflowArchive.EncodePlan(Steps); Decoded := TSleWorkflowArchive.DecodePlan(Text);
      Check(TSleWorkflowArchive.EncodePlan(Decoded) = Text, 'Canonical complete plan archive');
      Check(BytesEqual(Decoded[High(Decoded)].After, Desired), 'Whole final desired image');
      Text := TSleWorkflowArchive.EncodeSnapshot(Snapshot);
      Check(TSleWorkflowArchive.EncodeSnapshot(TSleWorkflowArchive.DecodeSnapshot(Text)) = Text, 'Canonical snapshot archive');
    end;
    Snapshot.Data[0] := 0; Rejected := False;
    try Steps := TSleWorkflowPlanner.ProgramPlan(Snapshot, Desired, C, swaCounterByte);
    except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'Planner rejects zero-to-one before constructing writes');
    Rejected := False;
    try TSleWorkflowArchive.DecodeSnapshot(StringReplace(Text, #13#10, #10, [rfReplaceAll]));
    except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'Noncanonical snapshot archive rejected'); C := nil;
  finally Native.Free; end;
  // Explicit program, scratchpad erase, program and application erase; both supplied codes.
  for Fail := 0 to 1 do
  begin
    Wire := TCounterWire.Create; Transport := Wire; Wire.Sle4404 := True;
    SetLength(Wire.Data, 64); for I := 0 to 63 do Wire.Data[I] := $FF;
    Wire.EndFail := Fail = 1;
    S4404 := TSle4404CardReaderWriter.Create(nil); Flow := TSle4404Workflow.Create(nil);
    try
      S4404.ReadableBytes := 64; S4404.Transport := Transport; Layout := S4404.Layout;
      Layout.UserCounterAddress := 0; Layout.UserCounterMask := $0F; Layout.MemoryCounterAddress := 16;
      Layout.ScratchPadAddress := 48; Layout.ScratchPadBytes := 2;
      Layout.ApplicationAddress := 50; Layout.ApplicationBytes := 2; S4404.Layout := Layout;
      C := TSle4404WorkflowCard.Create(S4404, 48, 4, HexToBytes('1234'), HexToBytes('01020304'));
      S4404.Free; S4404 := nil;
      SetLength(Steps, 4); Before := HexToBytes('FFFFFFFF');
      for I := 0 to 3 do
      begin
        Steps[I] := Default(TSleWorkflowStep); Steps[I].Before := CopyBytes(Before);
        Steps[I].After := CopyBytes(Before);
        case I of
          0: begin Steps[I].Action := swaProgram; Steps[I].Address := 48;
            Steps[I].Count := 1; Steps[I].After[0] := $0F; end;
          1: begin Steps[I].Action := swaEraseScratchPad; Steps[I].Address := 48;
            Steps[I].Count := 2; Steps[I].After[0] := $FF; Steps[I].After[1] := $FF; end;
          2: begin Steps[I].Action := swaProgram; Steps[I].Address := 50;
            Steps[I].Count := 1; Steps[I].After[2] := $F0; end;
          3: begin Steps[I].Action := swaEraseApplication; Steps[I].Address := 50;
            Steps[I].Count := 2; Steps[I].After[2] := $FF; Steps[I].After[3] := $FF; end;
        end;
        Before := CopyBytes(Steps[I].After);
      end;
      Flow.Prepare(C, Steps); Check(Wire.Exchanges = 0, 'SLE4404 complete profile pure validation');
      if Fail = 0 then
      begin
        Check(Flow.Execute = cwsCompleted, 'Native SLE4404 program/erase plan verified');
        Check((Wire.Writes = 4) and (Wire.Authentications = 4), 'Four explicit mutations and four code presentations');
        Check(BytesToHex(Flow.Snapshot.Data) = 'FFFFFFFF', 'Independent final public window');
        Check(Wire.Data[16] = $FE, 'Memory-code counter consumption is not silently restored');
      end
      else
      begin
        Check(Flow.Execute = cwsUncertain, 'SLE4404 release after verified dispatch remains uncertain');
        Check((Wire.Writes = 1) and (Flow.Results[0].State = cwusUncertain) and
          (Flow.Results[1].State = cwusPending), 'No automatic erase/retry after cleanup failure');
      end;
    finally Flow.Free; C := nil; S4404.Free; Transport := nil; end;
  end;
end;
procedure PersonalizationDemoTests;
var O: ICardDemoOperations; Factory: TReaders; Readers: ICardWorkflowDemoReaders;
  Request: TCardDemoRequest; D: TCardDemoResult; Native: TSleCounterCardReaderWriter;
  C: ISleWorkflowCard; Snapshot: TSleWorkflowSnapshot; Counter: Integer;
begin
  Factory := TReaders.Create; Readers := Factory; O := CreateCardPersonalizationDemoOperations(Readers);
  Request := Default(TCardDemoRequest); Request.Operation := cdoFamily;
  Request.FamilyName := 'SleCounterWorkflowDemo'; Request.FamilyAction := 3;
  SetLength(Request.Arguments, 4); Request.Arguments[0] := 'FEFF'; Request.Arguments[1] := '0';
  Request.Arguments[3] := '2|0'; SetLength(Request.Credentials, 2);
  Native := TSleCounterCardReaderWriter.Create(nil);
  try
    Native.ReadableBytes := 2; C := TSleCounterWorkflowCard.Create(Native);
    Snapshot.Layout := C.Layout; Snapshot.Address := 0; Snapshot.Data := HexToBytes('FFFF');
    Request.Arguments[2] := UnicodeString(TSleWorkflowArchive.EncodeSnapshot(Snapshot));
    O.Run(Request, D);
    Check(D.Success and (Length(D.Artifacts) = 1), 'Offline SLE demo builds reviewed plan');
    Check(Factory.Created = 0, 'Offline generation does not request reader/connection');
    Request.FamilyAction := 2; Request.MutationAcknowledged := True; Request.ReaderName := 'target';
    Request.Arguments[2] := 'ERD-SLE-PLAN 1' + #13#10 + '3|0|1|2|FFFF|FEFF' + #13#10;
    O.Run(Request, D); Check(not D.Success and (Factory.Created = 0), 'Unsupported backup profile rejected before factory');
    Request.FamilyName := 'DesfirePersonalizationDemo'; Request.FamilyAction := 0;
    Request.Arguments[1] := '2'; Request.Arguments[2] := 'ERD-DESFIRE-PERSONALIZE 1' + #13#10 + '1|2|0|0|0|1|0|1|-1';
    Request.Arguments[3] := '01020304050607|0|65536|48|0';
    Request.Credentials[0] := HexToBytes('00000000000000000000000000000000');
    Request.Credentials[1] := HexToBytes('11111111111111111111111111111111'); Request.Arguments[0] := '';
    Request.Arguments[2] := Request.Arguments[2] + #13#10 + '1|2|0|0|0|2|0|1|-1' + #13#10;
    O.Run(Request, D);
    Check(not D.Success and (Factory.Created = 0), 'Whole malformed DESFire profile validated before factory');
    for Counter := 0 to 15 do
    begin
      Request.Credentials[0] := nil;
      SetLength(Request.Credentials[0], Counter);
      O.Run(Request, D);
      Check(not D.Success and (Factory.Created = 0), 'Every undersized AES credential refused without I/O');
    end;
    C := nil;
  finally Native.Free; O := nil; Readers := nil; end;
end;
procedure PersonalizationChildTests;
var Card: TCard; C: IDesfireWorkflowCard; Flow: TDesfirePersonalizationWorkflow;
  Steps: TDesfirePersonalizationSteps; Observer: TObserver; Mode: Integer;
  R: TDesfirePersonalizationResults;
begin
  for Mode := 0 to 1 do
  begin
    Card := TCard.Create; C := Card; Flow := TDesfirePersonalizationWorkflow.Create(nil);
    Observer := TObserver.Create;
    try
      SetLength(Steps, 1); Steps[0] := Default(TDesfirePersonalizationStep);
      Steps[0].Action := dpaContent; Steps[0].Aid := 1; Steps[0].Card := C;
      Steps[0].Access := dsaFreshTransaction; Steps[0].Content := Card.Snapshot;
      Steps[0].Content.Files := CopyFiles(Card.Snapshot.Files);
      Steps[0].Content.Files[0].Data := HexToBytes('01020304');
      if Mode = 0 then Card.DenyFile := 0
      else
      begin Observer.Phase := cwsVerifying; Observer.After := 0; Flow.OnProgress := Observer.Progress; end;
      Flow.Prepare(Steps, Card.Snapshot.Identity);
      if Mode = 0 then
      begin
        Check(Flow.Execute = cwsFailed, 'Content live preflight failure preserves failed request outcome');
        R := Flow.Results;
        Check(R[0].Attempted and (R[0].State = cwsFailed), 'Attempted child failure distinct from unattempted');
        Check((Card.Writes = 0) and (Flow.LastChild.State = cwsFailed), 'No write before denied content access');
      end
      else
      begin
        Check(Flow.Execute = cwsCancelled, 'Child cancellation propagates without success exception');
        R := Flow.Results;
        Check(R[0].Attempted and (R[0].State = cwsCancelled), 'Partially cancelled child request retained');
        Check((Card.Writes = 1) and (Flow.LastChild.State = cwsCancelled), 'Earlier verified standard write retained');
        Check(TDesfireApplicationWorkflow(Flow.LastChild).Results[0].State = cwusVerified, 'Detailed partial child proof available');
      end;
    finally Flow.OnProgress := nil; Flow.Free; Observer.Free; C := nil; Steps := nil; end;
  end;
end;
procedure PersonalizationTests;
var Card: TCard; C: IDesfireWorkflowCard; P: TKeyProof; Proof: IDesfirePersonalizationKeyProof;
  Flow: TDesfirePersonalizationWorkflow; Steps: TDesfirePersonalizationSteps;
  Rejected: Boolean; Observer: TObserver; R: TDesfirePersonalizationResults;
begin
  Card := TCard.Create; C := Card; P := TKeyProof.Create; Proof := P;
  P.Card := C; P.ObjectCard := Card; Flow := TDesfirePersonalizationWorkflow.Create(nil);
  try
    SetLength(Steps, 3);
    Steps[0].Action := dpaAesKey; Steps[0].Card := C; Steps[0].Aid := 1;
    Steps[0].KeyProof := Proof; Steps[0].NewKey := HexToBytes('000102030405060708090A0B0C0D0E0F'); Steps[0].NewVersion := 4;
    Steps[1].Action := dpaFileAccess; Steps[1].Card := C; Steps[1].Aid := 1;
    Steps[1].FileNumber := 0; Steps[1].Communication := dfcFull;
    Steps[1].ReadKey := 0; Steps[1].WriteKey := 1; Steps[1].ReadWriteKey := 2; Steps[1].ChangeKey := 0;
    Steps[2].Action := dpaKeyPolicy; Steps[2].Card := C; Steps[2].Aid := 1; Steps[2].KeySettings := $0F;
    Flow.Prepare(Steps, Card.Snapshot.Identity); Check(Card.Opens = 0, 'Personalization prepare no I/O');
    Steps[0].NewKey[0] := $FF;
    Check(Flow.Execute = cwsCompleted, 'AES/access/policy profile completed');
    Check((Card.AdminWrites = 3) and (Card.Material[0] = 0), 'Copied keys and one native call per action');
    R := Flow.Results; Check((Length(R) = 3) and (R[2].State = cwsCompleted), 'Personalization ledger complete');
    Flow.Prepare(Steps, Card.Snapshot.Identity, 3);
    Check(Flow.Execute = cwsCompleted, 'Completed prefix freshly verified');
    Check(Flow.Results[0].Revalidated and not Flow.Results[0].Attempted, 'Prefix proof is distinct from execution');
    Check((Card.AdminWrites = 3) and (P.Calls = 1), 'Resume requires key proof and never mutates prefix');
    P.Fail := True; Flow.Prepare(Steps, Card.Snapshot.Identity, 1);
    Check(Flow.Execute = cwsFailed, 'Wrong replacement proof rejects resume');
    Check(Card.AdminWrites = 3, 'No write before all prefix proof'); P.Fail := False;
    Card.FailAdmin := True; Flow.Prepare(Steps, Card.Snapshot.Identity);
    Check(Flow.Execute = cwsUncertain, 'Native dispatch uncertainty preserved');
    Check((Card.AdminWrites = 4) and (Flow.Results[0].State = cwsUncertain) and
      (Flow.Results[1].State = cwsIdle), 'Uncertain profile stops and retains unattempted steps');
    Card.FailAdmin := False; Flow.Prepare(Steps, HexToBytes('99887766554433'));
    Check(Flow.Execute = cwsFailed, 'Wrong manufacturing UID rejected'); Check(Card.AdminWrites = 4, 'Wrong UID no mutation');
    Steps[2] := Steps[0]; Rejected := False;
    try Flow.Prepare(Steps, Card.Snapshot.Identity); except on E: ECardWorkflowError do Rejected := True; end;
    Check(Rejected, 'Repeated overwrite of key proof refused offline');
    SetLength(Steps, 1); Observer := TObserver.Create;
    try
      Observer.Phase := cwsWriting; Flow.OnProgress := Observer.Progress;
      Flow.Prepare(Steps, Card.Snapshot.Identity); Check(Flow.Execute = cwsCancelled, 'Cancel before key dispatch');
      Check(Card.AdminWrites = 4, 'Cancelled profile no mutation');
    finally Flow.OnProgress := nil; Observer.Free; end;
    Card.FailClose := True; Flow.Prepare(Steps, Card.Snapshot.Identity);
    Check(Flow.Execute = cwsUncertain, 'Verified key mutation followed by release failure remains uncertain');
    Check(Flow.Results[0].Attempted and (Flow.Results[0].State = cwsUncertain), 'Release failure retains attempted step');
    Card.FailClose := False;
    // Composition with existing provision/content workflows is verified against native child evidence.
    SetLength(Steps, 1); Steps[0] := Default(TDesfirePersonalizationStep);
    Steps[0].Action := dpaContent; Steps[0].Aid := 1; Steps[0].Card := C;
    Steps[0].Access := dsaFreshTransaction; Steps[0].Content := Card.Snapshot;
    // Restore original fake settings with matching raw fields.
    Card.Snapshot.Files[0].Settings := TDesfireCodec.FileSettings(0, HexToBytes('0000EEEE040000'));
    Steps[0].Content := Card.Snapshot;
    Flow.Prepare(Steps, Card.Snapshot.Identity);
    Check(Flow.Execute = cwsCompleted, 'Content child composes into profile');
    Check(Flow.LastChild is TDesfireApplicationWorkflow, 'Detailed content evidence retained');
    Flow.Prepare(Steps, Card.Snapshot.Identity, 1);
    Check(Flow.Execute = cwsCompleted, 'Content prefix independently reacquired');
    Steps[0] := Default(TDesfirePersonalizationStep); Steps[0].Action := dpaProvision;
    Steps[0].Aid := 2; Steps[0].Card := C; Steps[0].ApplicationCard := C;
    Steps[0].KeyCount := 1; Steps[0].KeySettings := $0F; Steps[0].KeyType := daktAes;
    Card.Snapshot.Files := nil; Flow.Prepare(Steps, Card.Snapshot.Identity);
    Check(Flow.Execute = cwsCompleted, 'Provision child composes into profile');
    Check(Flow.LastChild is TDesfireProvisionWorkflow, 'Detailed provision evidence retained');
    Flow.Prepare(Steps, Card.Snapshot.Identity, 1);
    Check(Flow.Execute = cwsCompleted, 'Created application prefix freshly inspected');
  finally Flow.Free; Proof := nil; C := nil; end;
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
    SleWorkflowTests; SlePlannerAndNativeTests; PersonalizationTests; PersonalizationChildTests; PersonalizationDemoTests;
    Writeln('PASS: ', Checks, ' contact-memory/DESFire workflow assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
