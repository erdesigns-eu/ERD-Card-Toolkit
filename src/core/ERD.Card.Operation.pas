unit ERD.Card.Operation;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Session, ERD.Card.Workflow;

type
  /// <summary>Invalid operation queue input or concurrent executor.</summary>
  ECardOperationError = class(Exception);
  /// <summary>Thread-safe cancellation request, checked by a running operation between safe steps.</summary>
  ICardCancellation = interface
    ['{99A95939-10E1-4ADB-B7BF-77DF188CA318}']
    /// <summary>Returns whether cancellation has been requested; never interrupts an in-flight write.</summary>
    /// <returns>True after CancelCurrent.</returns>
    function Requested: Boolean;
    /// <summary>Sets the irreversible cancellation flag.</summary>
    procedure Request;
  end;
  /// <summary>Retained wake signal for a queue executor; callbacks never access component pointers.</summary>
  ICardOperationWake = interface
    ['{158312AE-D8D6-4425-9A60-ED675F610373}']
    /// <summary>Wakes an executor without blocking; must not raise or execute queued operations.</summary>
    procedure Signal;
    /// <summary>Returns whether a queued job may be admitted; false preserves pending work during Stop.</summary>
    /// <returns>Thread-safe acceptance flag; must not call back into the queue.</returns>
    function AcceptingJobs: Boolean;
  end;
  /// <summary>Prepared single-use operation with frozen owned inputs and explicitly retained evidence.</summary>
  ICardOperation = interface
    ['{A206F7DD-51B7-4517-AC5D-D9B64606F458}']
    /// <summary>Runs once on the executor thread; poll cancellation between atomic steps.</summary>
    /// <param name="ASession">Owned reservation for the selected reader; do not retain or close it.</param>
    /// <param name="ACancellation">Thread-safe flag; cancellation is cooperative.</param>
    /// <returns>Explicit terminal workflow evidence; do not report completion while a write is uncertain.</returns>
    function Execute(const ASession: ICardSessionLease;
      const ACancellation: ICardCancellation): TCardWorkflowState;
  end;
  /// <summary>Single-use operation requiring an exclusive complete reader group.</summary>
  ICardMultiOperation = interface
    ['{57BE4BDC-B386-41B0-A4A1-9A83D7ED59C1}']
    /// <summary>Runs once after every source/target reservation has opened successfully.</summary>
    /// <param name="ASessions">Caller-order reader group, owned and closed by the queue.</param>
    /// <param name="ACancellation">Cooperative cancellation flag.</param>
    /// <returns>Terminal workflow evidence; no distributed atomic write guarantee.</returns>
    function ExecuteMany(const ASessions: ICardSessionGroup;
      const ACancellation: ICardCancellation): TCardWorkflowState;
  end;
  /// <summary>Prepared one-shot operation using a typed magstripe/HID resource lease.</summary>
  ICardResourceOperation = interface
    ['{C2B5E9C3-099B-4DE2-85EA-4A1D9AE56048}']
    /// <summary>Executes on the acquiring worker, without retaining or closing the lease.</summary>
    /// <param name="ASession">Typed guarded device reservation.</param>
    /// <param name="ACancellation">Cooperative cancellation flag.</param>
    /// <returns>Terminal workflow evidence; uncertain submissions must remain uncertain.</returns>
    function ExecuteResource(const ASession: ICardResourceLease;
      const ACancellation: ICardCancellation): TCardWorkflowState;
  end;
  /// <summary>Optional precise failure evidence exposed by a completed operation.</summary>
  ICardOperationFailure = interface
    ['{7AB6F815-7863-42B5-A167-646DC1ED4197}']
    /// <summary>Returns only the operation's failure class name, excluding exception text and card data.</summary>
    /// <returns>Empty on success, cancellation or unavailable class evidence.</returns>
    function FailureClass: string;
  end;
  /// <summary>Owned immutable per-operation result without secrets, raw card data or exception messages.</summary>
  TCardOperationResult = record
    /// <summary>Caller operation identifier, unique within the current pending queue.</summary>
    Id: string;
    /// <summary>Selected reader identifier.</summary>
    ReaderId: string;
    /// <summary>Number of reserved readers; ReaderId identifies the first member.</summary>
    ReaderCount: Integer;
    /// <summary>Terminal evidence; unclassified Execute exceptions conservatively become Uncertain.</summary>
    State: TCardWorkflowState;
    /// <summary>Exception class name only.</summary>
    ErrorClass: string;
    /// <summary>Result observer exception class; does not change operation evidence or trigger replay.</summary>
    ObserverErrorClass: string;
  end;
  /// <summary>Terminal notification on the executor thread, after lease cleanup.</summary>
  /// <param name="Sender">Queue; do not free it inside this callback.</param>
  /// <param name="AResult">Copied scalar evidence without card data or keys.</param>
  TCardOperationResultEvent = procedure(Sender: TObject; const AResult: TCardOperationResult) of object;
  /// <summary>Bounded thread-safe FIFO with exactly one caller-supplied executor thread.</summary>
  /// <remarks>Execution is synchronous on that worker, without UI dependencies or hidden threads.
  /// Enqueue/CancelCurrent may run on other threads. Destruction requires an idle executor.
  /// Operations are consumed once; failures never trigger replay. Queue readers must share one session manager.</remarks>
  TCardOperationQueue = class(TComponent)
  private
    FState: IInterface;
    FOnResult: TCardOperationResultEvent;
    procedure AddJob(const AId: string; const AReaderIds: array of string;
      const AOperation: ICardOperation; const AMulti: ICardMultiOperation; const AResource: ICardResourceOperation);
  public
    /// <summary>Creates an inactive queue with capacity 256.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases pending jobs; caller must join its executor before destruction.</summary>
    destructor Destroy; override;
    /// <summary>Enqueues one retained prepared operation.</summary>
    /// <param name="AId">Nonempty identifier, at most 128 characters; duplicates while pending are refused.</param>
    /// <param name="AReaderId">Nonempty registered reader identifier, at most 1024 characters.</param>
    /// <param name="AOperation">Non-nil single-use job; implementation owns its prepared inputs.</param>
    procedure Enqueue(const AId, AReaderId: string; const AOperation: ICardOperation);
    /// <summary>Enqueues a guarded typed device operation in the same single-executor FIFO.</summary>
    /// <param name="AId">Unique job identifier.</param>
    /// <param name="AReaderId">Registered typed device identity.</param>
    /// <param name="AOperation">Retained prepared job, executed once after resource acquisition.</param>
    procedure EnqueueResource(const AId, AReaderId: string; const AOperation: ICardResourceOperation);
    /// <summary>Enqueues a source/target job with copied ordered reader IDs.</summary>
    /// <param name="AId">Unique pending/executing job identifier, at most 128 characters.</param>
    /// <param name="AReaderIds">One through sixteen distinct registered physical reader IDs.</param>
    /// <param name="AOperation">Retained prepared operation; failures never trigger retries.</param>
    procedure EnqueueMany(const AId: string; const AReaderIds: array of string;
      const AOperation: ICardMultiOperation);
    /// <summary>Consumes one job and releases its reader lease, even after an exception.</summary>
    /// <param name="AManager">Non-nil live reader registry, retained by the application during execution.</param>
    /// <param name="AResult">Independent terminal evidence; reset to default if no job exists.</param>
    /// <returns>True when one job was consumed; false for an empty queue.</returns>
    function ExecuteNext(const AManager: TCardSessionManager;
      out AResult: TCardOperationResult): Boolean;
    /// <summary>Installs or clears a retained executor wake signal while no job is executing.</summary>
    /// <param name="AWake">Signal implementation, or nil when stopping.</param>
    /// <remarks>Only one wake owner may attach. An existing different owner is refused.</remarks>
    procedure SetWake(const AWake: ICardOperationWake);
    /// <summary>Requests cooperative cancellation of the current operation from any thread.</summary>
    procedure CancelCurrent;
    /// <summary>Discards all pending jobs without affecting the current operation.</summary>
    procedure ClearPending;
    /// <summary>Returns a thread-safe count of pending jobs, excluding the executing job.</summary>
    /// <returns>Zero through 256.</returns>
    function PendingCount: Integer;
  published
    /// <summary>Terminal result on the executing thread; marshal UI updates through an event dispatcher.</summary>
    property OnResult: TCardOperationResultEvent read FOnResult write FOnResult;
  end;

implementation

{$IFNDEF FPC}uses System.SyncObjs;{$ENDIF}

type
{$IFDEF FPC}
  TOperationLock = TRTLCriticalSection;
{$ELSE}
  TOperationLock = TCriticalSection;
{$ENDIF}
  TCancel = class(TInterfacedObject, ICardCancellation)
  private
    FFlag: LongInt;
  public
    function Requested: Boolean;
    procedure Request;
  end;
  TJob = record
    Id, ReaderId: string;
    Operation: ICardOperation;
    Multi: ICardMultiOperation;
    Resource: ICardResourceOperation;
    ReaderIds: array of string;
  end;
  TQueueState = class(TInterfacedObject)
  public
    Lock: TOperationLock;
    Jobs: array of TJob;
    Busy: Boolean;
    Current: TJob;
    Cancellation: ICardCancellation;
    Wake: ICardOperationWake;
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;

function TCancel.Requested: Boolean;
begin
{$IFDEF FPC}Result := InterlockedCompareExchange(FFlag,0,0)<>0;{$ELSE}Result := TInterlocked.CompareExchange(FFlag,0,0)<>0;{$ENDIF}
end;

procedure TCancel.Request;
begin
{$IFDEF FPC}InterlockedExchange(FFlag,1);{$ELSE}TInterlocked.Exchange(FFlag,1);{$ENDIF}
end;

constructor TQueueState.Create;
begin
  inherited Create;
{$IFDEF FPC}InitCriticalSection(Lock);{$ELSE}Lock := TCriticalSection.Create;{$ENDIF}
end;

destructor TQueueState.Destroy;
begin
{$IFDEF FPC}DoneCriticalSection(Lock);{$ELSE}Lock.Free;{$ENDIF}
  inherited Destroy;
end;

procedure TQueueState.Enter;
begin
{$IFDEF FPC}EnterCriticalSection(Lock);{$ELSE}Lock.Enter;{$ENDIF}
end;

procedure TQueueState.Leave;
begin
{$IFDEF FPC}LeaveCriticalSection(Lock);{$ELSE}Lock.Leave;{$ENDIF}
end;

constructor TCardOperationQueue.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FState := TQueueState.Create;
end;

destructor TCardOperationQueue.Destroy;
begin
  inherited Destroy; FState := nil;
end;

function QueueState(const State: IInterface): TQueueState;
begin
  Result := State as TQueueState;
end;

procedure TCardOperationQueue.Enqueue(const AId, AReaderId: string; const AOperation: ICardOperation);
begin
  AddJob(AId,[AReaderId],AOperation,nil,nil);
end;

procedure TCardOperationQueue.EnqueueMany(const AId: string; const AReaderIds: array of string;
  const AOperation: ICardMultiOperation);
begin
  AddJob(AId,AReaderIds,nil,AOperation,nil);
end;

procedure TCardOperationQueue.EnqueueResource(const AId, AReaderId: string;
  const AOperation: ICardResourceOperation);
begin AddJob(AId,[AReaderId],nil,nil,AOperation); end;

procedure TCardOperationQueue.AddJob(const AId: string; const AReaderIds: array of string;
  const AOperation: ICardOperation; const AMulti: ICardMultiOperation; const AResource: ICardResourceOperation);
var S: TQueueState; I, J, N: Integer; Wake: ICardOperationWake; Job: TJob;
begin
  if (Length(AId)<1) or (Length(AId)>128) or (Length(AReaderIds)<1) or
    (Length(AReaderIds)>16) or (Ord(AOperation<>nil)+Ord(AMulti<>nil)+Ord(AResource<>nil)<>1) then
    raise ECardOperationError.Create('Invalid queued operation.');
  Job := Default(TJob); Job.Id := AId; Job.ReaderId := AReaderIds[0];
  Job.Operation := AOperation; Job.Multi := AMulti; Job.Resource := AResource;
  SetLength(Job.ReaderIds,Length(AReaderIds));
  for I := 0 to High(AReaderIds) do begin
    if (Length(AReaderIds[I])<1) or (Length(AReaderIds[I])>1024) then
      raise ECardOperationError.Create('Invalid queued reader.');
    for J := 0 to I-1 do if AReaderIds[I]=AReaderIds[J] then
      raise ECardOperationError.Create('Duplicate queued reader.');
    Job.ReaderIds[I] := AReaderIds[I];
  end;
  S := QueueState(FState); S.Enter;
  try
    if S.Busy and ((S.Current.Id=AId) or
      ((AOperation<>nil) and (S.Current.Operation=AOperation)) or
      ((AMulti<>nil) and (S.Current.Multi=AMulti)) or
      ((AResource<>nil) and (S.Current.Resource=AResource))) then
      raise ECardOperationError.Create('Operation is already executing.');
    N := Length(S.Jobs);
    if N>=256 then raise ECardOperationError.Create('Operation queue is full.');
    for I := 0 to N-1 do
      if (S.Jobs[I].Id=AId) or ((AOperation<>nil) and (S.Jobs[I].Operation=AOperation)) or
        ((AMulti<>nil) and (S.Jobs[I].Multi=AMulti)) or
        ((AResource<>nil) and (S.Jobs[I].Resource=AResource)) then
        raise ECardOperationError.Create('Duplicate queued operation.');
    SetLength(S.Jobs,N+1); S.Jobs[N] := Job; Wake := S.Wake;
  finally S.Leave; end;
  if Wake<>nil then Wake.Signal;
end;

function TCardOperationQueue.ExecuteNext(const AManager: TCardSessionManager;
  out AResult: TCardOperationResult): Boolean;
var S: TQueueState; Job: TJob; I: Integer;
  ResourceLease: ICardResourceLease; Lease: ICardSessionLease; Group: ICardSessionGroup; Cancellation: ICardCancellation; Executing: Boolean;
  Retained: IInterface; Observer: TCardOperationResultEvent; Failure: ICardOperationFailure;
begin
  AResult := Default(TCardOperationResult); Result := False;
  if AManager=nil then raise ECardOperationError.Create('A session manager is required.');
  Retained := FState; S := QueueState(Retained); S.Enter;
  try
    if S.Busy then raise ECardOperationError.Create('An executor is already active.');
    if (S.Wake<>nil) and not S.Wake.AcceptingJobs then Exit;
    if Length(S.Jobs)=0 then Exit;
    Job := S.Jobs[0];
    for I := 0 to High(S.Jobs)-1 do S.Jobs[I] := S.Jobs[I+1];
    SetLength(S.Jobs,Length(S.Jobs)-1);
    Cancellation := TCancel.Create; S.Cancellation := Cancellation; S.Busy := True; S.Current := Job;
  finally S.Leave; end;
  Result := True; Executing := False;
  AResult.Id := Job.Id; AResult.ReaderId := Job.ReaderId; AResult.ReaderCount := Length(Job.ReaderIds);
  try
    try
      if Job.Resource<>nil then ResourceLease := AManager.AcquireResource(Job.ReaderId)
      else if Job.Multi<>nil then Group := AManager.AcquireMany(Job.ReaderIds)
      else Lease := AManager.Acquire(Job.ReaderId);
      if Cancellation.Requested then AResult.State := cwsCancelled
      else begin
        Executing := True;
        if Job.Resource<>nil then AResult.State := Job.Resource.ExecuteResource(ResourceLease,Cancellation)
        else if Job.Multi<>nil then AResult.State := Job.Multi.ExecuteMany(Group,Cancellation)
        else AResult.State := Job.Operation.Execute(Lease,Cancellation);
      end;
      if not (AResult.State in [cwsCompleted,cwsCancelled,cwsFailed,cwsUncertain,cwsNeedsVerification]) then
        raise ECardOperationError.Create('Operation returned a nonterminal state.');
      if (AResult.State in [cwsFailed,cwsUncertain]) and
        ((Supports(Job.Operation,ICardOperationFailure,Failure)) or
        (Supports(Job.Multi,ICardOperationFailure,Failure)) or
        (Supports(Job.Resource,ICardOperationFailure,Failure))) then AResult.ErrorClass := Failure.FailureClass;
    except on E: Exception do begin
      AResult.ErrorClass := E.ClassName;
      AResult.State := cwsFailed; if Executing then AResult.State := cwsUncertain;
    end; end;
    if ResourceLease<>nil then
      try ResourceLease.Close;
      except on E: Exception do begin
        AResult.ErrorClass := E.ClassName; AResult.State := cwsUncertain;
      end; end;
    if Group<>nil then
      try Group.Close;
      except on E: Exception do begin
        AResult.ErrorClass := E.ClassName; AResult.State := cwsUncertain;
      end; end;
    if Lease<>nil then
      try Lease.Close;
      except on E: Exception do begin
        AResult.ErrorClass := E.ClassName; AResult.State := cwsUncertain;
      end; end;
  finally
    ResourceLease := nil; Group := nil; Lease := nil; S.Enter;
    try S.Busy := False; S.Cancellation := nil; S.Current := Default(TJob); finally S.Leave; end;
  end;
  Observer := FOnResult;
  if Assigned(Observer) then
    try Observer(Self,AResult);
    except on E: Exception do AResult.ObserverErrorClass := E.ClassName; end;
end;

procedure TCardOperationQueue.SetWake(const AWake: ICardOperationWake);
var S: TQueueState;
begin
  S := QueueState(FState); S.Enter;
  try
    if S.Busy or ((S.Wake<>nil) and (AWake<>nil) and (S.Wake<>AWake)) then
      raise ECardOperationError.Create('Executor wake ownership is unavailable.');
    S.Wake := AWake;
  finally S.Leave; end;
end;

procedure TCardOperationQueue.CancelCurrent;
var S: TQueueState; C: ICardCancellation;
begin
  S := QueueState(FState); S.Enter;
  try C := S.Cancellation; finally S.Leave; end;
  if C<>nil then C.Request;
end;

procedure TCardOperationQueue.ClearPending;
var S: TQueueState; Removed: array of TJob; I: Integer;
begin
  S := QueueState(FState); S.Enter;
  try Removed := S.Jobs; S.Jobs := nil; finally S.Leave; end;
  for I := 0 to High(Removed) do Removed[I].Operation := nil;
end;

function TCardOperationQueue.PendingCount: Integer;
var S: TQueueState;
begin
  S := QueueState(FState); S.Enter;
  try Result := Length(S.Jobs); finally S.Leave; end;
end;

end.
