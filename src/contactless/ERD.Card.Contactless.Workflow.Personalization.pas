unit ERD.Card.Contactless.Workflow.Personalization;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.Workflow.DESFire;

type
  /// <summary>Fresh supplied-key proof, separate from publicly readable key-version metadata.</summary>
  IDesfirePersonalizationKeyProof = interface
    ['{88F66420-C345-4F63-8C7A-AE886231DBD1}']
    /// <summary>Proves possession by fresh mutual authentication, then verifies the exact stored version.</summary>
    /// <param name="AAid">Explicit application or PICC context.</param>
    /// <param name="AKeyNumber">Configured expected authentication key number.</param>
    /// <param name="AVersion">Expected stored version; version reading alone is insufficient.</param>
    procedure Verify(const AAid: Cardinal; const AKeyNumber, AVersion: Byte);
    /// <summary>Reads observed native identity through the same frozen connection.</summary>
    /// <returns>Independent observed native manufacturing UID.</returns>
    function ReadIdentity: TBytes;
  end;
  /// <summary>Explicit DESFire personalization operation; each retains its own current credential context.</summary>
  TDesfirePersonalizationAction = (
    /// <summary>Create an absent application and its explicit ordinary file definitions.</summary>
    dpaProvision,
    /// <summary>Populate compatible existing files from a complete explicit snapshot.</summary>
    dpaContent,
    /// <summary>Rotate one existing AES key and prove the replacement.</summary>
    dpaAesKey,
    /// <summary>Rotate one existing same-type DES/2K3DES/3K3DES key and prove the replacement.</summary>
    dpaDesKey,
    /// <summary>Change and independently verify ordinary file communication/access rights.</summary>
    dpaFileAccess,
    /// <summary>Change and independently verify the application's native key policy.</summary>
    dpaKeyPolicy);
  /// <summary>Complete explicit personalization step; secret fields never belong in reports or archives.</summary>
  TDesfirePersonalizationStep = record
    /// <summary>Explicit action.</summary>
    Action: TDesfirePersonalizationAction;
    /// <summary>Nonzero native target application AID.</summary>
    Aid: Cardinal;
    /// <summary>Current authorized context; PICC for provisioning, application otherwise.</summary>
    Card: IDesfireWorkflowCard;
    /// <summary>New application's explicit credential context for provisioning.</summary>
    ApplicationCard: IDesfireWorkflowCard;
    /// <summary>Optional final authorized context for prefix verification after later key/access changes.</summary>
    VerificationCard: IDesfireWorkflowCard;
    /// <summary>Fresh replacement-key proof for rotation and checked resume.</summary>
    KeyProof: IDesfirePersonalizationKeyProof;
    /// <summary>Explicit native key policy, for provision or policy change.</summary>
    KeySettings: Byte;
    /// <summary>Explicit provisioned key count 1..14.</summary>
    KeyCount: Byte;
    /// <summary>Explicit application key storage type for provision.</summary>
    KeyType: TDesfireApplicationKeyType;
    /// <summary>Complete ordinary file definitions for provision.</summary>
    Definitions: TDesfireWorkflowDefinitions;
    /// <summary>Complete content for population; source UID does not authorize target access.</summary>
    Content: TDesfireWorkflowSnapshot;
    /// <summary>Explicit ownership of the content transaction.</summary>
    Access: TDesfireSessionAccess;
    /// <summary>Existing key number to rotate.</summary>
    KeyNumber: Byte;
    /// <summary>Exact replacement version.</summary>
    NewVersion: Byte;
    /// <summary>Explicit previous DES version; ignored when rotating the authenticated key.</summary>
    OldVersion: Byte;
    /// <summary>Replacement key bytes, independently copied and wiped by the workflow.</summary>
    NewKey: TBytes;
    /// <summary>Previous key material for a different key; empty for the authenticated key.</summary>
    OldKey: TBytes;
    /// <summary>Ordinary file number for access modification.</summary>
    FileNumber: Byte;
    /// <summary>Explicit requested file communication.</summary>
    Communication: TDesfireCommunication;
    /// <summary>Explicit requested read access nibble.</summary>
    ReadKey: Byte;
    /// <summary>Explicit requested write access nibble.</summary>
    WriteKey: Byte;
    /// <summary>Explicit requested alternative read/write access nibble.</summary>
    ReadWriteKey: Byte;
    /// <summary>Explicit requested access-change nibble.</summary>
    ChangeKey: Byte;
  end;
  /// <summary>At most 256 ordered personalization steps.</summary>
  TDesfirePersonalizationSteps = array of TDesfirePersonalizationStep;
  /// <summary>Per-step request evidence without secret bytes or payloads.</summary>
  TDesfirePersonalizationResult = record
    /// <summary>Zero-based profile index.</summary>
    Index: Integer;
    /// <summary>Explicit requested action.</summary>
    Action: TDesfirePersonalizationAction;
    /// <summary>True once this step's execution begins; native preflight may still refuse before mutation.</summary>
    Attempted: Boolean;
    /// <summary>True when a completed prefix was freshly checked without mutation.</summary>
    Revalidated: Boolean;
    /// <summary>Idle for an unattempted step, Completed only for full evidence; child partial failure stays Failed.</summary>
    State: TCardWorkflowState;
    /// <summary>Failure class only; inspect LastChild for partial provision/content details.</summary>
    ErrorClass: string;
  end;
  /// <summary>Independent per-step evidence array.</summary>
  TDesfirePersonalizationResults = array of TDesfirePersonalizationResult;
  /// <summary>Application creation, content, credential and access-policy orchestration with retained evidence.</summary>
  /// <remarks>All structural validation precedes I/O. Each step uses its explicitly supplied current
  /// credentials, never guessed or automatically rewritten. Native key rotation already proves the new
  /// key; the separate proof backend supplies fresh evidence for resume. No automatic rollback, replay
  /// or transaction spanning immediate administrative changes. A content step may partially write.
  /// Resume verifies the entire completed prefix before dispatching any remaining mutation. Prefix
  /// operations must still be individually observable; profiles overwriting earlier evidence are refused.</remarks>
  TDesfirePersonalizationWorkflow = class(TCardWorkflow)
  private
    FSteps: TDesfirePersonalizationSteps;
    FResults: TDesfirePersonalizationResults;
    FIdentity: TBytes;
    FResume: Integer;
    FPrepared, FConsumed: Boolean;
    FCurrent: Integer;
    FChild: TCardWorkflow;
    procedure ClearSecrets;
    procedure CheckIdentity(const ACard: IDesfireWorkflowCard);
    procedure VerifyStep(const S: TDesfirePersonalizationStep);
    procedure ApplyStep(const S: TDesfirePersonalizationStep);
    procedure ChildProgress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    function GetResults: TDesfirePersonalizationResults;
  protected
    /// <summary>Checks immutable profile readiness and single-use lifecycle.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Verifies requested prefix, then executes each remaining step once.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Creates an inactive personalization component with no active step.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Wipes retained replacement/previous key bytes and releases child evidence.</summary>
    destructor Destroy; override;
    /// <summary>Copies a bounded explicit profile without hardware access.</summary>
    /// <param name="ASteps">Independent ordered contexts and content; application exclusively owns the physical connection.</param>
    /// <param name="AExpectedIdentity">Exactly seven native manufacturing UID bytes acquired earlier.</param>
    /// <param name="ACompletedPrefix">Explicit completed prefix to reverify without replay, zero for a fresh profile.</param>
    procedure Prepare(const ASteps: TDesfirePersonalizationSteps;
      const AExpectedIdentity: TBytes; const ACompletedPrefix: Integer = 0);
    /// <summary>Independent per-step request outcomes, including failed children with partial detailed evidence.</summary>
    property Results: TDesfirePersonalizationResults read GetResults;
    /// <summary>Current zero-based step; minus one before execution.</summary>
    property CurrentStep: Integer read FCurrent;
    /// <summary>Borrowed retained provision/content child evidence; never execute or free it.</summary>
    property LastChild: TCardWorkflow read FChild;
  end;

/// <summary>Creates fresh native replacement-key proof without card I/O.</summary>
/// <param name="AReader">Explicit authenticated security profile and replacement key number/material; public profiles are refused.</param>
/// <returns>Frozen owning backend; original reader may be freed afterwards.</returns>
function CreateDesfirePersonalizationKeyProof(const AReader: TDesfireCardReader): IDesfirePersonalizationKeyProof;

implementation

uses ERD.Card.Crypto;

type
  TNativeKeyProof = class(TInterfacedObject, IDesfirePersonalizationKeyProof)
    Card: IDesfireWorkflowCard;
    Number: Byte;
    procedure Verify(const AAid: Cardinal; const AKeyNumber, AVersion: Byte);
    function ReadIdentity: TBytes;
  end;

procedure Invalid;
begin raise ECardWorkflowError.Create('Invalid explicit DESFire personalization profile or acquired evidence.'); end;

function CreateDesfirePersonalizationKeyProof(const AReader: TDesfireCardReader): IDesfirePersonalizationKeyProof;
var P: TNativeKeyProof;
begin
  if (AReader = nil) or (AReader.Security = dfsPublic) then Invalid;
  P := TNativeKeyProof.Create; Result := P;
  P.Card := TDesfireWorkflowCard.Create(AReader); P.Number := AReader.KeyNumber;
end;
procedure TNativeKeyProof.Verify(const AAid: Cardinal; const AKeyNumber, AVersion: Byte);
var S: IDesfireSession; M: IDesfireManagement;
begin
  if AKeyNumber <> Number then Invalid;
  S := Card.OpenSession(AAid, dsaReadOnly);
  try
    if not Supports(S, IDesfireManagement, M) then Invalid;
    if M.ReadKeyVersion(AKeyNumber) <> AVersion then Invalid;
  finally M := nil; S.Close; end;
end;
function TNativeKeyProof.ReadIdentity: TBytes;
begin Result := Card.ReadIdentity; end;

procedure TDesfirePersonalizationWorkflow.ClearSecrets;
var I: Integer;
begin
  for I := 0 to High(FSteps) do
  begin TCardCrypto.Clear(FSteps[I].NewKey); TCardCrypto.Clear(FSteps[I].OldKey); end;
end;
constructor TDesfirePersonalizationWorkflow.Create(AOwner: TComponent);
begin inherited Create(AOwner); FCurrent := -1; end;
destructor TDesfirePersonalizationWorkflow.Destroy;
begin ClearSecrets; FChild.Free; inherited; end;

procedure Validate(const S: TDesfirePersonalizationStep);
var I, J: Integer; Provision: TDesfireProvisionWorkflow; Content: TDesfireApplicationWorkflow;
begin
  if (S.Card = nil) or (S.Aid = 0) or (S.Aid > $FFFFFF) then Invalid;
  case S.Action of
    dpaProvision:
      begin
        if (S.ApplicationCard = nil) or (S.KeyCount < 1) or (S.KeyCount > 14) or
          (Ord(S.KeyType) > Ord(High(TDesfireApplicationKeyType))) or
          (((S.KeySettings shr 4) < 14) and ((S.KeySettings shr 4) >= S.KeyCount)) or
          (Length(S.Definitions) > 32) then Invalid;
        for I := 0 to High(S.Definitions) do
        begin
          TDesfireCodec.ValidateDefinition(S.Definitions[I]);
          for J := 0 to I - 1 do if S.Definitions[I].FileNumber = S.Definitions[J].FileNumber then Invalid;
        end;
        Provision := TDesfireProvisionWorkflow.Create(nil);
        try
          Provision.Prepare(S.Card, S.ApplicationCard, S.Aid, S.KeySettings, S.KeyCount, S.KeyType, S.Definitions);
          Provision.CheckPrepared;
        finally Provision.Free; end;
      end;
    dpaContent:
      begin
        TDesfireWorkflowArchive.Validate(S.Content);
        if not (S.Access in [dsaFreshTransaction, dsaDiscardPending]) then Invalid;
        Content := TDesfireApplicationWorkflow.Create(nil);
        try Content.PrepareRestore(S.Content, S.Card, S.Aid, S.Access); Content.CheckPrepared;
        finally Content.Free; end;
      end;
    dpaAesKey, dpaDesKey:
      begin
        if (S.KeyProof = nil) or (S.KeyNumber > 13) then Invalid;
        if S.Action = dpaAesKey then
        begin if (Length(S.NewKey) <> 16) or not (Length(S.OldKey) in [0, 16]) then Invalid; end
        else if not (Length(S.NewKey) in [8, 16, 24]) or
          ((Length(S.OldKey) <> 0) and (Length(S.OldKey) <> Length(S.NewKey))) then Invalid;
      end;
    dpaFileAccess:
      if (S.FileNumber > 31) or (Ord(S.Communication) > 2) or
        (S.ReadKey > 15) or (S.WriteKey > 15) or (S.ReadWriteKey > 15) or (S.ChangeKey > 15) then Invalid;
    dpaKeyPolicy: ;
  else Invalid;
  end;
end;

procedure TDesfirePersonalizationWorkflow.Prepare(const ASteps: TDesfirePersonalizationSteps;
  const AExpectedIdentity: TBytes; const ACompletedPrefix: Integer);
var I, J: Integer; Steps: TDesfirePersonalizationSteps;
begin
  RequireIdle;
  if (Length(ASteps) < 1) or (Length(ASteps) > 256) or (Length(AExpectedIdentity) <> 7) or
    (ACompletedPrefix < 0) or (ACompletedPrefix > Length(ASteps)) then Invalid;
  for I := 0 to High(ASteps) do
  begin
    Validate(ASteps[I]);
    for J := 0 to I - 1 do
      if ASteps[J].Aid = ASteps[I].Aid then
      begin
        if (ASteps[I].Action = dpaProvision) or
          ((ASteps[J].Action = dpaContent) and (ASteps[I].Action = dpaContent)) or
          ((ASteps[J].Action = dpaKeyPolicy) and (ASteps[I].Action = dpaKeyPolicy)) or
          ((ASteps[J].Action in [dpaAesKey, dpaDesKey]) and
           (ASteps[I].Action in [dpaAesKey, dpaDesKey]) and (ASteps[J].KeyNumber = ASteps[I].KeyNumber)) or
          ((ASteps[J].Action = dpaFileAccess) and (ASteps[I].Action = dpaFileAccess) and
           (ASteps[J].FileNumber = ASteps[I].FileNumber)) then Invalid;
      end;
  end;
  Steps := Copy(ASteps, 0, Length(ASteps));
  for I := 0 to High(Steps) do
  begin
    Steps[I].Definitions := Copy(ASteps[I].Definitions, 0, Length(ASteps[I].Definitions));
    if Steps[I].Action = dpaContent then
      Steps[I].Content := TDesfireWorkflowArchive.Decode(TDesfireWorkflowArchive.Encode(ASteps[I].Content));
    Steps[I].NewKey := CopyBytes(ASteps[I].NewKey); Steps[I].OldKey := CopyBytes(ASteps[I].OldKey);
  end;
  ClearSecrets; FSteps := Steps; FIdentity := CopyBytes(AExpectedIdentity);
  FResume := ACompletedPrefix; FResults := nil; FreeAndNil(FChild); FCurrent := -1;
  FPrepared := True; FConsumed := False;
end;
procedure TDesfirePersonalizationWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
function TDesfirePersonalizationWorkflow.GetResults: TDesfirePersonalizationResults;
begin Result := Copy(FResults, 0, Length(FResults)); end;
procedure TDesfirePersonalizationWorkflow.CheckIdentity(const ACard: IDesfireWorkflowCard);
begin if not BytesEqual(ACard.ReadIdentity, FIdentity) then Invalid; end;
procedure TDesfirePersonalizationWorkflow.ChildProgress(Sender: TObject; const AState: TCardWorkflowState;
  const ADone, ATotal: Integer);
begin
  Progress(AState, ADone, ATotal);
  if CancelRequested then TCardWorkflow(Sender).Cancel;
end;

procedure TDesfirePersonalizationWorkflow.VerifyStep(const S: TDesfirePersonalizationStep);
var Session: IDesfireSession; Files: TDesfireFiles;
  App: TDesfireApplicationSettings; I, J, K, TypeBits: Integer; ExpectedPolicy: Byte;
  Definition: TDesfireFileDefinition; Found: Boolean;
  Reader: IDesfireWorkflowCard;
  Flow: TDesfireApplicationWorkflow; Snapshot: TDesfireWorkflowSnapshot; Settings: TDesfireFileSettings;
begin
  Reader := S.VerificationCard;
  if Reader = nil then
    if S.Action = dpaProvision then Reader := S.ApplicationCard else Reader := S.Card;
  CheckIdentity(Reader);
  if S.Action in [dpaAesKey, dpaDesKey] then
  begin
    if not BytesEqual(S.KeyProof.ReadIdentity, FIdentity) then Invalid;
    S.KeyProof.Verify(S.Aid, S.KeyNumber, S.NewVersion); Exit;
  end;
  if S.Action = dpaContent then
  begin
    Flow := TDesfireApplicationWorkflow.Create(nil);
    try
      Flow.PrepareBackup(Reader, S.Aid);
      if Flow.Execute <> cwsCompleted then Invalid;
      Snapshot := Flow.Snapshot;
      if Length(Snapshot.Files) <> Length(S.Content.Files) then Invalid;
      for I := 0 to High(S.Content.Files) do
      begin
        Found := False;
        for J := 0 to High(Snapshot.Files) do
          if S.Content.Files[I].Settings.FileNumber = Snapshot.Files[J].Settings.FileNumber then
          begin
            if (S.Content.Files[I].Settings.FileType <> Snapshot.Files[J].Settings.FileType) or
              (S.Content.Files[I].Settings.FileBytes <> Snapshot.Files[J].Settings.FileBytes) or
              (S.Content.Files[I].Settings.RecordBytes <> Snapshot.Files[J].Settings.RecordBytes) or
              (S.Content.Files[I].Settings.MaxRecords <> Snapshot.Files[J].Settings.MaxRecords) or
              (S.Content.Files[I].Settings.LowerLimit <> Snapshot.Files[J].Settings.LowerLimit) or
              (S.Content.Files[I].Settings.UpperLimit <> Snapshot.Files[J].Settings.UpperLimit) or
              not BytesEqual(S.Content.Files[I].Data, Snapshot.Files[J].Data) then Invalid;
            Found := True;
          end;
        if not Found then Invalid;
      end;
    finally Flow.Free; end;
    Exit;
  end;
  Session := Reader.OpenSession(S.Aid, dsaReadOnly);
  try
    App := Session.ReadApplicationSettings;
    case S.Action of
      dpaProvision:
        begin
          TypeBits := 0;
          if S.KeyType = daktThreeKey3Des then TypeBits := $40;
          if S.KeyType = daktAes then TypeBits := $80;
          if App.KeyConfiguration <> (TypeBits or S.KeyCount) then Invalid;
          ExpectedPolicy := S.KeySettings;
          for K := 0 to FResume - 1 do
            if (FSteps[K].Aid = S.Aid) and (FSteps[K].Action = dpaKeyPolicy) then
              ExpectedPolicy := FSteps[K].KeySettings;
          if App.KeySettings <> ExpectedPolicy then Invalid;
          Files := Session.ReadFiles;
          if Length(Files) <> Length(S.Definitions) then Invalid;
          for I := 0 to High(S.Definitions) do
          begin
            Definition := S.Definitions[I];
            for K := 0 to FResume - 1 do
              if (FSteps[K].Aid = S.Aid) and (FSteps[K].Action = dpaFileAccess) and
                (FSteps[K].FileNumber = Definition.FileNumber) then
              begin
                Definition.Communication := FSteps[K].Communication;
                Definition.ReadKey := FSteps[K].ReadKey; Definition.WriteKey := FSteps[K].WriteKey;
                Definition.ReadWriteKey := FSteps[K].ReadWriteKey; Definition.ChangeKey := FSteps[K].ChangeKey;
              end;
            Found := False;
            for J := 0 to High(Files) do if Files[J].FileNumber = S.Definitions[I].FileNumber then
            begin
              Settings := Files[J];
              if (Settings.Communication <> Definition.Communication) or
                (Settings.ReadKey <> Definition.ReadKey) or (Settings.WriteKey <> Definition.WriteKey) or
                (Settings.ReadWriteKey <> Definition.ReadWriteKey) or (Settings.ChangeKey <> Definition.ChangeKey) or
                (Settings.FileType <> S.Definitions[I].FileType) or
                (Settings.FileBytes <> S.Definitions[I].FileBytes) or
                (Settings.RecordBytes <> S.Definitions[I].RecordBytes) or
                (Settings.MaxRecords <> S.Definitions[I].MaxRecords) or
                (Settings.LowerLimit <> S.Definitions[I].LowerLimit) or
                (Settings.UpperLimit <> S.Definitions[I].UpperLimit) then Invalid;
              Found := True;
            end;
            if not Found then Invalid;
          end;
        end;
      dpaKeyPolicy: if App.KeySettings <> S.KeySettings then Invalid;
      dpaFileAccess:
        begin
          Files := Session.ReadFiles; Found := False;
          for I := 0 to High(Files) do if Files[I].FileNumber = S.FileNumber then
          begin
            if (Files[I].Communication <> S.Communication) or (Files[I].ReadKey <> S.ReadKey) or
              (Files[I].WriteKey <> S.WriteKey) or (Files[I].ReadWriteKey <> S.ReadWriteKey) or
              (Files[I].ChangeKey <> S.ChangeKey) then Invalid;
            Found := True;
          end;
          if not Found then Invalid;
        end;
    else Invalid;
    end;
  finally Session.Close; end;
end;

procedure TDesfirePersonalizationWorkflow.ApplyStep(const S: TDesfirePersonalizationStep);
var Session: IDesfireSession; M: IDesfireManagement; D: IDesfireDesManagement;
  Provision: TDesfireProvisionWorkflow; Content: TDesfireApplicationWorkflow; Outcome: TCardWorkflowState; Verified: Boolean;
begin
  if S.Action in [dpaProvision, dpaContent] then
  begin
    FreeAndNil(FChild);
    if S.Action = dpaProvision then
    begin
      Provision := TDesfireProvisionWorkflow.Create(nil); FChild := Provision;
      Provision.Prepare(S.Card, S.ApplicationCard, S.Aid, S.KeySettings, S.KeyCount, S.KeyType, S.Definitions);
    end
    else
    begin
      Content := TDesfireApplicationWorkflow.Create(nil); FChild := Content;
      Content.PrepareRestore(S.Content, S.Card, S.Aid, S.Access);
    end;
    FChild.OnProgress := ChildProgress; Outcome := FChild.Execute;
    if Outcome <> cwsCompleted then
    begin
      if Outcome = cwsCancelled then Exit;
      if Outcome = cwsUncertain then MutationPending(True);
      raise ECardWorkflowError.Create('Personalization child did not complete; inspect retained evidence.');
    end;
    Exit;
  end;
  Verified := False; Session := S.Card.OpenSession(S.Aid, dsaManage);
  try
    if not Supports(Session, IDesfireManagement, M) then Invalid;
    case S.Action of
      dpaAesKey: M.ChangeAesKey(S.KeyNumber, S.NewVersion, S.NewKey, S.OldKey);
      dpaDesKey:
        begin
          if not Supports(Session, IDesfireDesManagement, D) then Invalid;
          D.ChangeDesKey(S.KeyNumber, S.NewVersion, S.OldVersion, S.NewKey, S.OldKey);
        end;
      dpaFileAccess: M.ChangeFileAccess(S.FileNumber, S.Communication,
        S.ReadKey, S.WriteKey, S.ReadWriteKey, S.ChangeKey);
      dpaKeyPolicy: M.ChangeKeySettings(S.KeySettings);
    else Invalid;
    end;
    Verified := True;
  finally
    D := nil; M := nil;
    try Session.Close;
    except on E: Exception do
      begin
        if Verified then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  end;
end;

procedure TDesfirePersonalizationWorkflow.DoExecute;
var I: Integer;
begin
  FConsumed := True; SetLength(FResults, Length(FSteps));
  for I := 0 to High(FResults) do
  begin FResults[I].Index := I; FResults[I].Action := FSteps[I].Action; FResults[I].State := cwsIdle; end;
  try
    if not RequestCard(cwrTarget) then Exit;
    for I := 0 to FResume - 1 do
    begin
      if CancelRequested then Exit;
      FCurrent := I; Progress(cwsChecking, I, Length(FSteps)); CheckIdentity(FSteps[I].Card);
      if CancelRequested then Exit;
      FResults[I].State := cwsChecking;
      try VerifyStep(FSteps[I]);
      except on E: Exception do
        begin FResults[I].State := cwsFailed; FResults[I].ErrorClass := E.ClassName; raise; end;
      end;
      FResults[I].State := cwsCompleted; FResults[I].Revalidated := True;
    end;
    for I := FResume to High(FSteps) do
    begin
      CheckIdentity(FSteps[I].Card);
      if FSteps[I].ApplicationCard <> nil then CheckIdentity(FSteps[I].ApplicationCard);
      if (FSteps[I].KeyProof <> nil) and not BytesEqual(FSteps[I].KeyProof.ReadIdentity, FIdentity) then Invalid;
    end;
    for I := FResume to High(FSteps) do
    begin
      if CancelRequested then Exit;
      FCurrent := I; CheckIdentity(FSteps[I].Card); Progress(cwsWriting, I, Length(FSteps));
      if CancelRequested then Exit;
      FResults[I].Attempted := True; FResults[I].State := cwsWriting;
      try
        try ApplyStep(FSteps[I]);
        except
          on E: EContactlessWriteUncertain do
          begin FResults[I].State := cwsUncertain; MutationPending(True); raise; end;
        end;
        if (FChild <> nil) and (FChild.State = cwsCancelled) then
        begin FResults[I].State := cwsCancelled; Exit; end;
        MutationPending(True); FResults[I].State := cwsUncertain;
        // Each native administrative operation already verifies the exact mutation.
        // The child has verified its complete content/provision outcome before returning.
        CheckIdentity(FSteps[I].Card);
        FResults[I].State := cwsCompleted; MutationPending(False);
      except
        on E: Exception do
        begin
          FResults[I].ErrorClass := E.ClassName;
          if FResults[I].State = cwsWriting then FResults[I].State := cwsFailed;
          if (FChild <> nil) and (FChild.State = cwsUncertain) then FResults[I].State := cwsUncertain;
          raise;
        end;
      end;
      Progress(cwsVerifying, I + 1, Length(FSteps));
    end;
  finally ClearSecrets; end;
end;

end.
