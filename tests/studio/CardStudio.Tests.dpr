program CardStudioTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
uses
{$IFDEF UNIX}cthreads,{$ENDIF}
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Session, ERD.Card.Operation,
  ERD.Card.Project, ERD.Card.Workflow, ERD.Card.Operation.Workflow;

type
  TWire = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Calls, Begins, Ends: Integer;
    FailBegin, FailEnd, ChangeOnBegin, ChangeOnRead: Boolean;
    Manager: TCardSessionManager;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TJob = class(TInterfacedObject, ICardOperation)
  public
    Queue: TCardOperationQueue;
    Calls, Mode: Integer;
    function Execute(const ASession: ICardSessionLease;
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
    Queue: TCardOperationQueue;
    Seen: Integer;
    Fail: Boolean;
    procedure Bind(const Lease: ICardSessionLease; const Workflow: TCardWorkflow);
    procedure Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
    procedure Completed(Sender: TObject; const Result: TCardOperationResult);
  end;
  TFailStream = class(TMemoryStream)
  public
    function Write(const Buffer; Count: LongInt): LongInt; override;
  end;
  TPlain = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TProbe = class(TThread)
  public
    Lease: ICardSessionLease;
    Refused: Boolean;
    procedure Execute; override;
  end;
var Assertions: Integer;
procedure Check(const Value: Boolean; const Description: string);
begin
  Inc(Assertions); if not Value then raise Exception.Create(Description);
end;
function TWire.Exchange(const ACommand: TBytes): TBytes;
begin
  Inc(Calls); if ChangeOnRead then Manager.CardChanged('reader');
  Result := HexToBytes('9000');
end;
procedure TWire.BeginTransaction;
begin
  Inc(Begins);
  if FailBegin then raise ECardTransportError.Create('Synthetic begin failure');
  if ChangeOnBegin then Manager.CardChanged('reader');
end;
procedure TWire.EndTransaction;
begin
  Inc(Ends); if FailEnd then raise ECardTransportError.Create('Synthetic release failure');
end;
function TJob.Execute(const ASession: ICardSessionLease;
  const ACancellation: ICardCancellation): TCardWorkflowState;
var B: TBytes; Nested: TCardOperationResult; Refused: Boolean;
begin
  Inc(Calls);
  if Mode=1 then raise Exception.Create('Private secret must not reach result');
  if Mode=2 then begin Queue.CancelCurrent; Check(ACancellation.Requested,'Cross-thread capable cancellation flag'); Exit(cwsCancelled); end;
  if Mode=3 then Exit(cwsWriting);
  if Mode=4 then begin
    Refused := False; try Queue.ExecuteNext(nil,Nested); except on E: ECardOperationError do Refused := True; end;
    Check(Refused,'Invalid executor rejected');
  end;
  B := ASession.Transport.Exchange(HexToBytes('0084000000'));
  Check(BytesToHex(B)='9000','Managed job response'); Result := cwsCompleted;
end;
procedure TProbe.Execute;
begin
  try Lease.Transport.Exchange(HexToBytes('0084000000'));
  except on E: ECardSessionError do Refused := True; end;
end;
function TFailStream.Write(const Buffer; Count: LongInt): LongInt;
begin Result := 0; end;
function TPlain.Exchange(const ACommand: TBytes): TBytes;
begin Result := HexToBytes('9000'); end;
procedure TFakeWorkflow.ValidatePrepared;
begin end;
procedure TFakeWorkflow.DoExecute;
begin
  if Fail then raise ECardProjectError.Create('Private workflow exception text');
  Progress(cwsReading,0,2); Progress(cwsReading,1,2);
end;
procedure TObserver.Bind(const Lease: ICardSessionLease; const Workflow: TCardWorkflow);
begin
  Check((Lease.Transport<>nil) and (Workflow<>nil),'Workflow transport binding');
end;
procedure TObserver.Progress(Sender: TObject; const State: TCardWorkflowState; const Done, Total: Integer);
begin
  Inc(Seen); if Queue<>nil then Queue.CancelCurrent;
end;
procedure TObserver.Completed(Sender: TObject; const Result: TCardOperationResult);
begin
  Inc(Seen); if Fail then raise Exception.Create('Secret observer text');
end;
procedure Bridges;
var M: TCardSessionManager; Q: TCardOperationQueue; Plain: ICardTransport;
  Lease: ICardSessionLease; Transport: ICardTransport; Tx: ICardTransaction;
  W: TFakeWorkflow; Observer: TObserver; Job: ICardOperation; R: TCardOperationResult;
  Failed: Boolean;
begin
  M := TCardSessionManager.Create(nil); Q := TCardOperationQueue.Create(nil);
  Plain := TPlain.Create; M.BindReader('plain',Plain); Observer := TObserver.Create;
  W := TFakeWorkflow.Create(nil);
  try
    Lease := M.Acquire('plain'); Transport := Lease.Transport;
    Check(not Supports(Transport,ICardTransaction,Tx),'Physical transaction capability remains truthful');
    Lease.Close; Lease := nil; Transport := nil;
    Observer.Queue := Q; W.OnProgress := Observer.Progress;
    Job := CreateCardWorkflowOperation(W,Observer.Bind);
    Q.Enqueue('workflow','plain',Job); Q.OnResult := Observer.Completed; Observer.Fail := True;
    Check(Q.ExecuteNext(M,R) and (R.State=cwsCancelled),'Prepared workflow cancellation bridge');
    Check((R.ObserverErrorClass='Exception') and (R.ErrorClass=''),'Observer failure does not change card evidence');
    Check(Assigned(W.OnProgress) and (Observer.Seen>=3),'Workflow original observers chained/restored');
    Q.Enqueue('consumed','plain',Job); Q.OnResult := nil;
    Check(Q.ExecuteNext(M,R) and (R.State=cwsUncertain),'Consumed workflow adapter refuses replay');
    Failed := False; try Job := CreateCardWorkflowOperation(nil,Observer.Bind);
    except on E: ECardOperationError do Failed := True; end;
    Check(Failed,'Invalid workflow adapter input');
    Job := nil; W.Free; W := TFakeWorkflow.Create(nil); W.Fail := True;
    Observer.Queue := nil; Job := CreateCardWorkflowOperation(W,Observer.Bind);
    Q.Enqueue('failed-workflow','plain',Job);
    Check(Q.ExecuteNext(M,R) and (R.State=cwsFailed) and (R.ErrorClass='ECardProjectError'),
      'Workflow exact failure evidence reaches queue result');
  finally Job := nil; W.Free; Observer.Free; Q.Free; M.Free; end;
end;
procedure Sessions;
var M: TCardSessionManager; W: TWire; Backend, Guard: ICardTransport;
  A, B: ICardSessionLease; Tx: ICardTransaction; Failed: Boolean; Probe: TProbe;
  Mode, I: Integer; Data: TBytes; List: TStringList;
begin
  for Mode := 0 to 6 do begin
    M := TCardSessionManager.Create(nil); W := TWire.Create; Backend := W; W.Manager := M;
    try
      M.BindReader('reader',Backend); A := M.Acquire('reader'); Guard := A.Transport;
      Failed := False; try B := M.Acquire('reader'); except on E: ECardSessionError do Failed := True; end;
      Check(Failed and (B=nil),'One application owner per reader');
      Failed := False; try M.BindReader('reader',Backend); except on E: ECardSessionError do Failed := True; end;
      Check(Failed,'Cannot replace reserved backend');
      case Mode of
        0: begin
          Probe := TProbe.Create(True); try Probe.Lease := A; Probe.Start; Probe.WaitFor;
            Check(Probe.Refused and (W.Calls=0),'Wrong-thread I/O refused before dispatch');
          finally Probe.Free; end;
          Data := Guard.Exchange(HexToBytes('0084000000')); Check(BytesToHex(Data)='9000','Owner exchange');
        end;
        1: M.CardChanged('reader');
        2: M.DetachReader('reader');
        3: begin M.Free; M := nil; end;
        4: begin W.ChangeOnRead := True; end;
        5: begin W.ChangeOnBegin := True; Tx := Guard as ICardTransaction; end;
        6: begin W.FailEnd := True; Tx := Guard as ICardTransaction; Tx.BeginTransaction; end;
      end;
      if Mode>0 then begin
        Failed := False;
        try
          if Mode=5 then Tx.BeginTransaction else if Mode=6 then Tx.EndTransaction
          else Data := Guard.Exchange(HexToBytes('0084000000'));
        except on E: Exception do Failed := True; end;
        Check(Failed,'Invalidation or backend failure observable');
        if Mode in [1,2,3] then Check(W.Calls=0,'Invalid session never dispatches');
        if Mode=5 then Check((W.Begins=1) and (W.Ends=1),'Invalidation during Begin releases acquired physical transaction');
      end;
      A.Close; A.Close;
      Failed := False; try Data := Guard.Exchange(HexToBytes('0084000000'));
      except on E: ECardSessionError do Failed := True; end;
      Check(Failed,'Retained transport invalid after Close');
      if M<>nil then begin
        W.ChangeOnRead := False; W.ChangeOnBegin := False; W.FailEnd := False;
        M.BindReader('reader',Backend); B := M.Acquire('reader'); B.Close; B := nil;
        List := M.ReaderIds; try Check((List.Count=1) and (List[0]='reader'),'Reader registry snapshot'); finally List.Free; end;
        for I := 0 to 299 do begin
          A := M.Acquire('reader'); M.DetachReader('reader'); A.Close;
          M.BindReader('reader',Backend);
        end;
      end;
    finally A := nil; B := nil; Guard := nil; Tx := nil; M.Free; Backend := nil; end;
  end;
end;
procedure Operations;
var M: TCardSessionManager; Q: TCardOperationQueue; W: TWire;
  Backend: ICardTransport; J: TJob; Job: ICardOperation; R: TCardOperationResult;
  Mode: Integer; Failed: Boolean;
begin
  M := TCardSessionManager.Create(nil); Q := TCardOperationQueue.Create(nil);
  W := TWire.Create; Backend := W; M.BindReader('reader',Backend);
  try
    for Mode := 0 to 4 do begin
      J := TJob.Create; Job := J; J.Mode := Mode; J.Queue := Q;
      Q.Enqueue('job','reader',Job);
      Failed := False; try Q.Enqueue('job','reader',Job); except on E: ECardOperationError do Failed := True; end;
      Check(Failed and (Q.PendingCount=1),'Duplicate FIFO input rejected');
      Check(Q.ExecuteNext(M,R) and (J.Calls=1) and (Q.PendingCount=0),'Operation consumed once');
      if Mode in [1,3] then Check((R.State=cwsUncertain) and (R.ErrorClass<>''),'Execute exception/nonterminal result conservatively uncertain')
      else if Mode=2 then Check(R.State=cwsCancelled,'Cooperative cancellation')
      else Check(R.State=cwsCompleted,'Managed completion');
      Check(not Q.ExecuteNext(M,R) and (R.Id=''),'Empty FIFO no replay');
      Job := nil;
    end;
    J := TJob.Create; Job := J; Q.Enqueue('missing','absent',Job);
    Check(Q.ExecuteNext(M,R) and (R.State=cwsFailed) and (J.Calls=0),'Reservation refusal precedes execution');
    Q.Enqueue('clear','reader',Job); Q.ClearPending;
    Check(Q.PendingCount=0,'Clear pending does not execute jobs');
  finally Job := nil; Q.Free; M.Free; Backend := nil; end;
end;
procedure Projects;
var P, Q: TCardProject; A, B: TCardProjectArtifact; Text, Original: string;
  I: Integer; Failed: Boolean; List: TStringList; Stream: TMemoryStream;
begin
  P := TCardProject.Create(nil); Q := TCardProject.Create(nil);
  try
    P.NewProject('studio-1'); A.Id := 'card'; A.Profile := 'classic-1k'; A.Data := HexToBytes('001122FF');
    P.Put(A); A.Data[0] := $FF; B := P.Get('card'); Check(B.Data[0]=0,'Project freezes input');
    B.Data[0] := $EE; Check(P.Get('card').Data[0]=0,'Project copies output');
    Text := P.ExportText; Check(P.Dirty,'Export is not a filesystem save'); Q.ImportText(Text);
    Check(not Q.Dirty and (Q.ExportText=Text),'Deterministic project roundtrip');
    P.MarkSaved; B := P.Get('card'); P.Put(B); Check(not P.Dirty,'No-op does not dirty project');
    Original := Q.ExportText;
    for I := 0 to Length(Text)-2 do begin
      Failed := False; try Q.ImportText(Copy(Text,1,I)); except on E: Exception do Failed := True; end;
      // A complete header-only or complete shorter data artifact is a valid smaller project.
      if Failed then Check(Q.ExportText=Original,'Rejected imports preserve prior project');
      Q.ImportText(Original);
    end;
    Failed := False; try Q.ImportText(Text+'A card classic-1k 00'+#10);
    except on E: ECardProjectError do Failed := True; end;
    Check(Failed and (Q.ExportText=Original),'Duplicate archive entry rejected atomically');
    A.Id := 'empty'; A.Profile := 'inspection'; A.Data := nil; P.Put(A); Q.ImportText(P.ExportText);
    Check(Length(Q.Get('empty').Data)=0,'Empty artifact roundtrip');
    List := Q.ArtifactIds; try Check(List.Count=2,'Independent artifact index'); finally List.Free; end;
    P.Remove('card'); Check(P.Dirty,'Removal dirties project');
    Stream := TFailStream.Create;
    try
      Failed := False; try P.SaveToStream(Stream); except on E: Exception do Failed := True; end;
      Check(Failed and P.Dirty,'Failed storage does not mark project clean');
    finally Stream.Free; end;
    Stream := TMemoryStream.Create;
    try
      P.SaveToStream(Stream); Check(not P.Dirty,'Successful stream save marks clean');
      Stream.Position := 0; Q.LoadFromStream(Stream);
      Check(Q.ExportText=P.ExportText,'Seekable stream project roundtrip');
    finally Stream.Free; end;
    Original := P.ExportText; A.Id := 'oversized'; A.Profile := 'snapshot'; SetLength(A.Data,1024*1024+1);
    Failed := False; try P.Put(A); except on E: ECardProjectError do Failed := True; end;
    Check(Failed and (P.ExportText=Original),'Payload budget preserves project');
  finally P.Free; Q.Free; end;
end;
begin
  try Sessions; Operations; Projects; Bridges; Writeln('PASS: ',Assertions,' studio component assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
