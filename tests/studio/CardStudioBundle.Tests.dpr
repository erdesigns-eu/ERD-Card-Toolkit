program CardStudioBundleTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF UNIX}cthreads,{$ENDIF}
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Session, ERD.Card.Operation,
  ERD.Card.Operation.Workflow, ERD.Card.Operation.Executor, ERD.Card.Workflow, ERD.Card.Project, ERD.Card.Project.Artifacts, ERD.Card.Project.Files,
  ERD.Card.Project.Secure, ERD.Card.Contactless.Project, ERD.Card.Contactless.Calypso,
  ERD.Card.Contactless.Workflow.DESFire, ERD.Card.MagStripe.Project, ERD.Card.MagStripe.Tracks;

type
  TWire = class(TInterfacedObject, ICardTransport)
  public
    Calls: Integer;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TConnection = class(TInterfacedObject, ICardSessionConnection)
  public
    Manager: TCardSessionManager;
    ProbeId, ChangeId: string;
    Backend: ICardTransport;
    Opens, Closes: Integer;
    FailOpen, FailClose, ReservedBeforeOpen: Boolean;
    function Open: ICardTransport;
    procedure Close;
  end;
  TMulti = class(TInterfacedObject, ICardMultiOperation)
  public
    Calls: Integer;
    Fail, Invalidate: Boolean;
    Manager: TCardSessionManager;
    function ExecuteMany(const ASessions: ICardSessionGroup;
      const ACancellation: ICardCancellation): TCardWorkflowState;
  end;
  TFakeWorkflow = class(TCardWorkflow)
  public
    Fail: Boolean;
  protected
    procedure ValidatePrepared; override;
    procedure DoExecute; override;
  end;
  TObserver = class
  public
    Binds, ProgressCount: Integer;
    Queue: TCardOperationQueue;
    procedure Bind(const Sessions: ICardSessionGroup; const Workflow: TCardWorkflow);
    procedure Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
  end;
  TProbe = class(TThread)
  public
    Group: ICardSessionGroup;
    Refused: Boolean;
    procedure Execute; override;
  end;
  TProtection = class(TInterfacedObject, ICardProjectProtection)
  public
    Plain, Cipher: TBytes;
    Fail: Boolean;
    ChangeProject: TCardProject;
    function Protect(const APlain: TBytes): TBytes;
    function Unprotect(const AProtected: TBytes): TBytes;
  end;
var Checks: Integer;
procedure Check(const Value: Boolean; const Name: string);
begin
  Inc(Checks); if not Value then raise Exception.Create(Name);
end;
function TWire.Exchange(const ACommand: TBytes): TBytes;
begin Inc(Calls); Result := HexToBytes('9000'); end;
function TConnection.Open: ICardTransport;
var L: ICardSessionLease;
begin
  Inc(Opens);
  if ProbeId<>'' then begin
    try L := Manager.Acquire(ProbeId); L.Close;
    except on E: ECardSessionError do ReservedBeforeOpen := True; end;
  end;
  if FailOpen then raise ECardSessionError.Create('Synthetic open failure.');
  if ChangeId<>'' then Manager.CardChanged(ChangeId);
  Result := Backend;
end;
procedure TConnection.Close;
begin
  Inc(Closes); if FailClose then raise ECardSessionError.Create('Synthetic close failure.');
end;
function TMulti.ExecuteMany(const ASessions: ICardSessionGroup;
  const ACancellation: ICardCancellation): TCardWorkflowState;
var Response: TBytes;
begin
  Inc(Calls); ASessions.Validate;
  Check(ASessions.Count=2,'Multi member count');
  Check(ASessions.ReaderId(0)='source','Caller order source');
  Check(ASessions.ReaderId(1)='target','Caller order target');
  Response := ASessions.Lease(0).Transport.Exchange(HexToBytes('00'));
  Check(BytesToHex(Response)='9000','Source exchange');
  if Fail then raise Exception.Create('Synthetic unknown write outcome.');
  if Invalidate then Manager.CardChanged('target');
  ASessions.Validate;
  Response := ASessions.Lease(1).Transport.Exchange(HexToBytes('00'));
  Check(BytesToHex(Response)='9000','Target exchange');
  if ACancellation.Requested then Result := cwsCancelled else Result := cwsCompleted;
end;
procedure TFakeWorkflow.ValidatePrepared;
begin end;
procedure TFakeWorkflow.DoExecute;
begin
  if Fail then raise ECardProjectError.Create('Synthetic workflow failure.');
  Progress(cwsReading,0,2); if CancelRequested then Exit;
  Progress(cwsReading,1,2);
end;
procedure TObserver.Bind(const Sessions: ICardSessionGroup; const Workflow: TCardWorkflow);
begin
  Inc(Binds); Check((Sessions.Count=2) and (Workflow<>nil),'Multi workflow binding');
end;
procedure TObserver.Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
begin
  Inc(ProgressCount); if Queue<>nil then Queue.CancelCurrent;
end;
procedure TProbe.Execute;
begin
  try Group.Validate;
  except on E: ECardSessionError do Refused := True; end;
end;
function TProtection.Protect(const APlain: TBytes): TBytes;
begin
  if Fail then raise ECardProjectProtectionError.Create('Synthetic protection failure.');
  if ChangeProject<>nil then ChangeProject.NewProject('changed-during-save');
  Plain := CopyBytes(APlain); Cipher := HexToBytes('1122334455667788'); Result := CopyBytes(Cipher);
end;
function TProtection.Unprotect(const AProtected: TBytes): TBytes;
begin
  if Fail or not BytesEqual(Cipher,AProtected) then raise ECardProjectProtectionError.Create('Synthetic authentication failure.');
  Result := CopyBytes(Plain);
end;

procedure Groups;
var M: TCardSessionManager; Q: TCardOperationQueue; W1,W2: TWire;
  B1,B2: ICardTransport; Group: ICardSessionGroup; L: ICardSessionLease;
  C1,C2: TConnection; P1,P2: ICardSessionConnection; Bad: Boolean;
  Executor: TCardOperationExecutor; I: Integer;
  Job: TMulti; Operation: ICardMultiOperation; R: TCardOperationResult; Probe: TProbe;
begin
  M := TCardSessionManager.Create(nil); Q := TCardOperationQueue.Create(nil);
  W1 := TWire.Create; B1 := W1; W2 := TWire.Create; B2 := W2;
  try
    M.BindReader('source',B1); M.BindReader('target',B2);
    L := M.Acquire('target'); Bad := False;
    try Group := M.AcquireMany(['source','target']); except on E: ECardSessionError do Bad := True; end;
    Check(Bad,'Busy member refuses group');
    Group := M.AcquireMany(['source']); Group.Close; Group := nil;
    Check(W1.Calls=0,'Refused group sent no command'); L.Close; L := nil;
    Bad := False;
    try Group := M.AcquireMany(['source','missing']); except on E: ECardSessionError do Bad := True; end;
    Check(Bad,'Missing member refuses group');
    Bad := False;
    try Group := M.AcquireMany(['source','source']); except on E: ECardSessionError do Bad := True; end;
    Check(Bad,'Duplicate members refused');
    Group := M.AcquireMany(['target','source']);
    Check(Group.ReaderId(0)='target','Reversed caller order preserved');
    Probe := TProbe.Create(True); Probe.Group := Group;
    try Probe.Start; Probe.WaitFor; Check(Probe.Refused,'Group rejects foreign thread'); finally Probe.Free; end;
    M.CardChanged('source'); Bad := False;
    try Group.Validate; except on E: ECardSessionError do Bad := True; end;
    Check(Bad,'One changed card invalidates group validation'); Group.Close; Group.Close; Group := nil;
    L := M.Acquire('source'); L.Close; L := nil;
    Check(True,'Invalidated group released all reservations');
    C1 := TConnection.Create; P1 := C1; C1.Backend := B1; C1.Manager := M; C1.ProbeId := 'target';
    C2 := TConnection.Create; P2 := C2; C2.Backend := B2; C2.Manager := M;
    M.BindConnection('source',P1); M.BindConnection('target',P2);
    C2.FailOpen := True; Bad := False;
    try Group := M.AcquireMany(['source','target']); except on E: ECardSessionError do Bad := True; end;
    Check(Bad and C1.ReservedBeforeOpen,'All members reserved before opening');
    Check((C1.Opens=1) and (C1.Closes=1) and (C2.Opens=1) and (C2.Closes=0),'Partial open rolled back once');
    L := M.Acquire('source'); L.Close; L := nil;
    C2.FailOpen := False; M.BindConnection('target',P2);
    Group := M.AcquireMany(['source','target']); C2.FailClose := True; Bad := False;
    try Group.Close; except on E: ECardSessionError do Bad := True; end;
    Check(Bad and (C1.Closes=3),'Cleanup continues after another member failure');
    Group.Close; Group := nil; C2.FailClose := False;
    M.BindConnection('target',P2);
    C2.ChangeId := 'source'; Bad := False;
    try Group := M.AcquireMany(['source','target']); except on E: ECardSessionError do Bad := True; end;
    Check(Bad,'Earlier card changed during another connection Open');
    C2.ChangeId := ''; Group := M.AcquireMany(['source','target']); Group.Close; Group := nil;
    Check(True,'Changed-during-open rollback releases every reader');
    Job := TMulti.Create; Operation := Job; Q.EnqueueMany('copy',['source','target'],Operation);
    Check(Q.ExecuteNext(M,R),'Multi queued');
    Check((R.State=cwsCompleted) and (R.ReaderCount=2) and (R.ReaderId='source'),'Multi terminal evidence');
    Check(Job.Calls=1,'Multi executes once'); Check(not Q.ExecuteNext(M,R),'No automatic replay');
    Job := TMulti.Create; Operation := Job; Job.Fail := True;
    Q.EnqueueMany('uncertain',['source','target'],Operation); Check(Q.ExecuteNext(M,R),'Failed multi consumed');
    Check((R.State=cwsUncertain) and (Job.Calls=1),'Dispatched failure remains uncertain');
    L := M.Acquire('target');
    Job := TMulti.Create; Operation := Job; Q.EnqueueMany('blocked',['source','target'],Operation);
    Check(Q.ExecuteNext(M,R),'Unavailable multi consumed');
    Check((R.State=cwsFailed) and (Job.Calls=0),'Acquire failure never invokes job'); L.Close; L := nil;
    Job := TMulti.Create; Operation := Job; Job.Invalidate := True; Job.Manager := M;
    Q.EnqueueMany('changed',['source','target'],Operation); Check(Q.ExecuteNext(M,R),'Changed multi consumed');
    Check(R.State=cwsUncertain,'Changed target refused before its command');
    Executor := TCardOperationExecutor.Create(nil);
    try
      Executor.Manager := M; Executor.Queue := Q;
      Job := TMulti.Create; Operation := Job; Q.EnqueueMany('background',['source','target'],Operation);
      Executor.Start;
      for I := 1 to 2000 do begin
        Executor.DispatchResults;
        if Executor.LastResult.Id='background' then Break;
        TThread.Sleep(1);
      end;
      R := Executor.LastResult; Executor.Stop;
      Check((R.Id='background') and (R.State=cwsCompleted) and (R.ReaderCount=2),'Background multi-reader dispatch');
    finally Executor.Free; end;
  finally Operation := nil; Group := nil; L := nil; Q.Free; M.Free; end;
end;

procedure Bridges;
var M: TCardSessionManager; Q: TCardOperationQueue; W: TFakeWorkflow; O: TObserver;
  Job: ICardMultiOperation; R: TCardOperationResult; Backend: ICardTransport;
begin
  M := TCardSessionManager.Create(nil); Q := TCardOperationQueue.Create(nil); O := TObserver.Create;
  W := TFakeWorkflow.Create(nil);
  try
    Backend := TWire.Create; M.BindReader('source',Backend);
    Backend := TWire.Create; M.BindReader('target',Backend);
    W.OnProgress := O.Progress; Job := CreateCardMultiWorkflowOperation(W,O.Bind);
    Q.EnqueueMany('bridge',['source','target'],Job); Check(Q.ExecuteNext(M,R),'Multi bridge consumed');
    Check((R.State=cwsCompleted) and (O.Binds=1) and (O.ProgressCount>0),'Multi bridge preserves progress');
    O.ProgressCount := 0; W.Execute; Check(O.ProgressCount>0,'Original progress restored');
    Q.EnqueueMany('consumed',['source','target'],Job); Check(Q.ExecuteNext(M,R),'Consumed bridge dequeued');
    Check((R.State=cwsUncertain) and (O.Binds=1),'Consumed bridge never binds again');
    Job := nil; W.Fail := True; Job := CreateCardMultiWorkflowOperation(W,O.Bind);
    Q.EnqueueMany('failed',['source','target'],Job); Check(Q.ExecuteNext(M,R),'Failing bridge consumed');
    Check((R.State=cwsFailed) and (R.ErrorClass='ECardProjectError'),'Precise workflow error class');
    Job := nil; W.Fail := False; O.Queue := Q; Job := CreateCardMultiWorkflowOperation(W,O.Bind);
    Q.EnqueueMany('cancel',['source','target'],Job); Check(Q.ExecuteNext(M,R),'Cancelled bridge consumed');
    Check(R.State=cwsCancelled,'Multi bridge cancellation at progress');
  finally Job := nil; W.Free; O.Free; Q.Free; M.Free; end;
end;

procedure Artifacts;
var P: TCardProject; S,Got: TCardWorkflowSnapshot; D,DGot: TDesfireWorkflowSnapshot;
  B,BGot: TMobibSnapshot; T,TGot: TMagStripeProjectSnapshot; Item: TCardProjectArtifact;
  Bad: Boolean; I: Integer; Old: string;
begin
  P := TCardProject.Create(nil);
  try
    P.NewProject('bundle'); S := Default(TCardWorkflowSnapshot); S.Layout := 'classic.1k';
    S.Uid := HexToBytes('01020304'); SetLength(S.Units,1); S.Units[0].Address := 4;
    S.Units[0].Data := HexToBytes('01020304');
    TCardProjectArtifacts.PutMemory(P,'memory',S); Got := TCardProjectArtifacts.GetMemory(P,'memory');
    Check((Got.Layout=S.Layout) and BytesEqual(Got.Units[0].Data,S.Units[0].Data),'Typed memory roundtrip');
    Got.Units[0].Data[0] := 99; Got := TCardProjectArtifacts.GetMemory(P,'memory');
    Check(Got.Units[0].Data[0]=1,'Decoded memory copy isolation');
    D := Default(TDesfireWorkflowSnapshot); D.Aid := 1; D.Identity := HexToBytes('01020304050607');
    TContactlessProjectArtifacts.PutDesfire(P,'desfire',D); DGot := TContactlessProjectArtifacts.GetDesfire(P,'desfire');
    Check((DGot.Aid=1) and BytesEqual(DGot.Identity,D.Identity),'Typed DESFire roundtrip');
    B := Default(TMobibSnapshot); SetLength(B.Files,1); B.Files[0].LogicalId := $2020;
    B.Files[0].SelectionStatus := $9000; SetLength(B.Files[0].Records,1);
    B.Files[0].Records[0].Number := 1; B.Files[0].Records[0].Data := HexToBytes('1234');
    TContactlessProjectArtifacts.PutMobib(P,'mobib',B); BGot := TContactlessProjectArtifacts.GetMobib(P,'mobib');
    Check((BGot.Files[0].SelectionStatus=$9000) and BytesEqual(BGot.Files[0].Records[0].Data,B.Files[0].Records[0].Data),'Typed MOBIB evidence');
    T := Default(TMagStripeProjectSnapshot); T.Tracks := [mstTrack1,mstTrack2];
    T.Data[mstTrack1] := 'TEST'; T.Data[mstTrack2] := '12345=6789';
    TMagStripeProjectArtifacts.Put(P,'stripe',T); TGot := TMagStripeProjectArtifacts.Get(P,'stripe');
    Check((TGot.Tracks=T.Tracks) and (TGot.Data[mstTrack2]=T.Data[mstTrack2]),'Typed stripe roundtrip');
    Bad := False;
    try Got := TCardProjectArtifacts.GetMemory(P,'stripe'); except on E: ECardProjectError do Bad := True; end;
    Check(Bad,'Cross-family artifact refused');
    Item := P.Get('memory'); Item.Profile := 'memory.v2'; P.Put(Item); Bad := False;
    try Got := TCardProjectArtifacts.GetMemory(P,'memory'); except on E: ECardProjectError do Bad := True; end;
    Check(Bad,'Unsupported memory version refused');
    Item := P.Get('stripe');
    for I := 0 to Length(Item.Data)-1 do begin
      Item.Data := Copy(Item.Data,0,I); P.Put(Item); Bad := False;
      try TGot := TMagStripeProjectArtifacts.Get(P,'stripe'); except on E: Exception do Bad := True; end;
      Check(Bad,'Truncated stripe artifact refused'); Item := Default(TCardProjectArtifact);
      TMagStripeProjectArtifacts.Put(P,'stripe',T); Item := P.Get('stripe');
    end;
    Old := P.ExportText; T.Data[mstTrack3] := '9'; Bad := False;
    try TMagStripeProjectArtifacts.Put(P,'stripe',T); except on E: ECardProjectError do Bad := True; end;
    Check(Bad and (P.ExportText=Old),'Invalid typed put preserves project');
  finally P.Free; end;
end;

procedure Files;
var P,Loaded: TCardProject; Store: TCardProjectFileStore; Secure: TCardProtectedProjectStore;
  Policy: TProtection; Provider: ICardProjectProtection; DirectoryName,Name,Old: string;
  Guid: TGUID; Bad: Boolean; Raw: TFileStream; Data: Byte; Search: TSearchRec;
begin
  CreateGUID(Guid); DirectoryName := IncludeTrailingPathDelimiter(GetCurrentDir)+ 'dist'+PathDelim+'project-'+GUIDToString(Guid);
  if not ForceDirectories(DirectoryName) then raise Exception.Create('Test directory');
  Name := IncludeTrailingPathDelimiter(DirectoryName)+'project.erd';
  P := TCardProject.Create(nil); Loaded := TCardProject.Create(nil); Store := TCardProjectFileStore.Create(nil);
  Secure := TCardProtectedProjectStore.Create(nil); Policy := TProtection.Create; Provider := Policy;
  try
    P.NewProject('first'); Bad := False;
    try Store.Save(P,Name); except on E: ECardProjectFileError do Bad := True; end;
    Check(Bad and P.Dirty and not FileExists(Name),'Protected save requires policy');
    Store.SavePlain(P,Name); Check(not P.Dirty and Store.LastSaveReplaced,'Plain atomic save');
    Store.LoadPlain(Loaded,Name); Check(Loaded.ProjectId='first','Plain file roundtrip');
    P.NewProject('second'); Store.SavePlain(P,Name); Store.LoadPlain(Loaded,Name);
    Check((Loaded.ProjectId='second') and not P.Dirty,'Replace existing file');
    P.NewProject('failure'); Bad := False;
    try Store.SavePlain(P,DirectoryName); except on E: ECardProjectFileError do Bad := True; end;
    Check(Bad and P.Dirty and not Store.LastSaveReplaced,'Failed rename keeps Dirty');
    Store.LoadPlain(Loaded,Name); Check(Loaded.ProjectId='second','Failed save preserves previous file');
    Secure.Protection := Provider; Store.ProtectedStore := Secure; Policy.Fail := True; Bad := False;
    try Store.Save(P,Name); except on E: ECardProjectProtectionError do Bad := True; end;
    Check(Bad and P.Dirty and not Store.LastSaveReplaced,'Protection failure before replacement');
    Store.LoadPlain(Loaded,Name); Check(Loaded.ProjectId='second','Protection failure preserved destination');
    Policy.Fail := False; Store.Save(P,Name); Store.Load(Loaded,Name);
    Check((Loaded.ProjectId='failure') and not P.Dirty,'Protected native file roundtrip');
    P.NewProject('before-policy'); Policy.ChangeProject := P; Store.Save(P,Name);
    Check(P.Dirty and (P.ProjectId='changed-during-save'),'Reentrant source change remains Dirty');
    Policy.ChangeProject := nil; Store.Load(Loaded,Name);
    Check(Loaded.ProjectId='before-policy','Saved archive is exact initial snapshot');
    Old := Loaded.ExportText; Raw := TFileStream.Create(Name,fmOpenReadWrite); Data := 0;
    try Raw.Position := Raw.Size-1; Raw.WriteBuffer(Data,1); finally Raw.Free; end;
    Bad := False; try Store.Load(Loaded,Name); except on E: ECardProjectProtectionError do Bad := True; end;
    Check(Bad and (Loaded.ExportText=Old),'Tampered file preserves project');
    Secure.Free; Secure := nil; Check(Store.ProtectedStore=nil,'File store clears destroyed policy');
    Bad := False; try Store.Load(Loaded,Name); except on E: ECardProjectFileError do Bad := True; end;
    Check(Bad,'Removed policy never falls back');
    if FindFirst(IncludeTrailingPathDelimiter(DirectoryName)+'.erd-project-*.tmp',faAnyFile,Search)=0 then begin
      FindClose(Search); Check(False,'Temporary file leaked');
    end else Check(True,'Temporary files cleaned');
  finally
    Secure.Free; Store.Free; Loaded.Free; P.Free; Provider := nil;
    DeleteFile(Name); RemoveDir(DirectoryName);
  end;
end;

begin
  try Groups; Bridges; Artifacts; Files; Writeln('PASS: ',Checks,' studio bundle assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
