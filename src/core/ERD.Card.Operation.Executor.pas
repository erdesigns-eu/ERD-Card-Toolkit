unit ERD.Card.Operation.Executor;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Operation, ERD.Card.Session, ERD.Card.Events;

type
  /// <summary>Creator-thread lifecycle error in the background operation executor.</summary>
  ECardExecutorError = class(Exception);
  /// <summary>Nonvisual signal-driven background executor with creator-thread result delivery.</summary>
  /// <remarks>Configure/start/stop on the creating thread; producers may Enqueue from other threads.
  /// Stop cancels cooperatively and joins in-flight verification; it never kills or replays a job.
  /// Queue-level observers still run on the worker. Executor OnResult runs on the creator.</remarks>
  TCardOperationExecutor = class(TComponent)
  private
    FWorker: TThread;
    FState: IInterface;
    FResults: ICardEventQueue;
    FManager: TCardSessionManager;
    FQueue: TCardOperationQueue;
    FThread: NativeUInt;
    FOnResult: TCardOperationResultEvent;
    procedure RequireCreator;
    procedure SetManager(const Value: TCardSessionManager);
    procedure SetQueue(const Value: TCardOperationQueue);
    function GetRunning: Boolean;
    procedure SetOnResult(const Value: TCardOperationResultEvent);
  protected
    /// <summary>Stops and joins before a dependent manager or queue releases its state.</summary>
    /// <param name="AComponent">Dependency being removed.</param>
    /// <param name="Operation">Component notification kind.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Creates inactive state; no threads or hardware are opened.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Stops, joins and invalidates queued creator-thread notifications.</summary>
    destructor Destroy; override;
    /// <summary>Starts one suspended-then-configured worker and wakes any existing jobs.</summary>
    /// <remarks>Requires live Manager/Queue and no active executor. Never starts a partially constructed thread.</remarks>
    procedure Start;
    /// <summary>Requests cooperative stop without joining or blocking the UI.</summary>
    /// <remarks>Pending jobs remain queued. Call Stop later to release the finished worker before destruction.</remarks>
    procedure RequestStop;
    /// <summary>Requests cancellation and joins the worker without dispatching UI events.</summary>
    /// <remarks>Unexecuted jobs stay queued. Pending delivery is discarded; LastResult retains the last finished evidence.</remarks>
    procedure Stop;
    /// <summary>Dispatches a finite notification batch on the creator thread, useful without a GUI message loop.</summary>
    procedure DispatchResults;
    /// <summary>Reads a locked copy of the last completed result, including after Stop.</summary>
    /// <returns>Default record before any job has completed.</returns>
    function LastResult: TCardOperationResult;
    /// <summary>Reads a locked worker/notification failure class without exception messages.</summary>
    /// <returns>Empty until worker failure; reset by the next Start.</returns>
    function ErrorClass: string;
    /// <summary>True only while a started worker is alive; Stop still releases finished workers.</summary>
    property Running: Boolean read GetRunning;
  published
    /// <summary>Registry kept alive by the application; removal stops the worker before registry destruction.</summary>
    property Manager: TCardSessionManager read FManager write SetManager;
    /// <summary>Operation queue; Configure before Start and do not execute it through another host.</summary>
    property Queue: TCardOperationQueue read FQueue write SetQueue;
    /// <summary>Terminal copied result on the creator thread; callbacks may Stop the executor.</summary>
    property OnResult: TCardOperationResultEvent read FOnResult write SetOnResult;
  end;

implementation

{$IFNDEF FPC}uses System.SyncObjs;{$ENDIF}

type
{$IFDEF FPC}
  TExecutorLock = TRTLCriticalSection;
  TExecutorEvent = PRTLEvent;
{$ELSE}
  TExecutorLock = TCriticalSection;
  TExecutorEvent = TEvent;
{$ENDIF}
  TExecutorState = class(TInterfacedObject, ICardOperationWake)
  private
    FLock: TExecutorLock;
    FEvent: TExecutorEvent;
  public
    Stopping, Finished: Boolean;
    Last: TCardOperationResult;
    Error: string;
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
    procedure Signal;
    function AcceptingJobs: Boolean;
    procedure Wait;
    function StopRequested: Boolean;
  end;
  TResultNotice = class(TInterfacedObject, ICardQueuedEvent)
  public
    Owner: TObject;
    Callback: TCardOperationResultEvent;
    Value: TCardOperationResult;
    State: IInterface;
    procedure Invoke;
  end;
  TExecutorWorker = class(TThread)
  private
    FState: IInterface;
    FManager: TCardSessionManager;
    FQueue: TCardOperationQueue;
    FResults: ICardEventQueue;
    FOwner: TObject;
    FCallback: TCardOperationResultEvent;
    procedure Deliver;
  protected
    procedure Execute; override;
  public
    constructor Create(const State: IInterface; const Manager: TCardSessionManager;
      const Queue: TCardOperationQueue; const Results: ICardEventQueue;
      const Owner: TObject; const Callback: TCardOperationResultEvent);
  end;

constructor TExecutorState.Create;
begin
  inherited Create;
{$IFDEF FPC}InitCriticalSection(FLock); FEvent := RTLEventCreate;
{$ELSE}FLock := TCriticalSection.Create; FEvent := TEvent.Create(nil,False,False,'');{$ENDIF}
end;

destructor TExecutorState.Destroy;
begin
{$IFDEF FPC}RTLEventDestroy(FEvent); DoneCriticalSection(FLock);
{$ELSE}FEvent.Free; FLock.Free;{$ENDIF}
  inherited Destroy;
end;

procedure TExecutorState.Enter;
begin
{$IFDEF FPC}EnterCriticalSection(FLock);{$ELSE}FLock.Enter;{$ENDIF}
end;

procedure TExecutorState.Leave;
begin
{$IFDEF FPC}LeaveCriticalSection(FLock);{$ELSE}FLock.Leave;{$ENDIF}
end;

procedure TExecutorState.Signal;
begin
{$IFDEF FPC}RTLEventSetEvent(FEvent);{$ELSE}FEvent.SetEvent;{$ENDIF}
end;

procedure TExecutorState.Wait;
begin
{$IFDEF FPC}RTLEventWaitFor(FEvent);{$ELSE}FEvent.WaitFor(Cardinal($FFFFFFFF));{$ENDIF}
end;

function TExecutorState.AcceptingJobs: Boolean;
begin
  Result := not StopRequested;
end;

function TExecutorState.StopRequested: Boolean;
begin
  Enter; try Result := Stopping; finally Leave; end;
end;

procedure TResultNotice.Invoke;
var Event: TCardOperationResultEvent;
begin
  Event := Callback;
  if Assigned(Event) then
    try Event(Owner,Value);
    except on E: Exception do begin
      (State as TExecutorState).Enter;
      try (State as TExecutorState).Error := E.ClassName;
      finally (State as TExecutorState).Leave; end;
    end; end;
end;

constructor TExecutorWorker.Create(const State: IInterface; const Manager: TCardSessionManager;
  const Queue: TCardOperationQueue; const Results: ICardEventQueue;
  const Owner: TObject; const Callback: TCardOperationResultEvent);
begin
  inherited Create(True); FreeOnTerminate := False;
  FState := State; FManager := Manager; FQueue := Queue; FResults := Results;
  FOwner := Owner; FCallback := Callback;
end;

procedure TExecutorWorker.Deliver;
var Results: ICardEventQueue;
begin
  Results := FResults; Results.Dispatch;
end;

procedure TExecutorWorker.Execute;
var State: TExecutorState; Result: TCardOperationResult;
  Notice: TResultNotice; Event: ICardQueuedEvent;
begin
  State := FState as TExecutorState;
  try
    try
      while not State.StopRequested do begin
        State.Wait;
        while not State.StopRequested do begin
          if not FQueue.ExecuteNext(FManager,Result) then Break;
          State.Enter;
          try State.Last := Result; finally State.Leave; end;
          Notice := TResultNotice.Create; Event := Notice;
          Notice.Owner := FOwner; Notice.Callback := FCallback; Notice.Value := Result; Notice.State := FState;
          if FResults.Add(Event) then TThread.Queue(Self,Deliver);
        end;
      end;
    except on E: Exception do begin
      State.Enter; try State.Error := E.ClassName; finally State.Leave; end;
    end; end;
  finally State.Enter; try State.Finished := True; finally State.Leave; end; end;
end;

constructor TCardOperationExecutor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FThread := NativeUInt(TThread.CurrentThread.ThreadID);
end;

procedure TCardOperationExecutor.RequireCreator;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>FThread then
    raise ECardExecutorError.Create('Executor lifecycle belongs to its creating thread.');
end;

procedure TCardOperationExecutor.SetManager(const Value: TCardSessionManager);
begin
  RequireCreator; if FWorker<>nil then raise ECardExecutorError.Create('Stop the executor before configuring it.');
  if FManager<>nil then FManager.RemoveFreeNotification(Self);
  FManager := Value; if Value<>nil then Value.FreeNotification(Self);
end;

procedure TCardOperationExecutor.SetQueue(const Value: TCardOperationQueue);
begin
  RequireCreator; if FWorker<>nil then raise ECardExecutorError.Create('Stop the executor before configuring it.');
  if FQueue<>nil then FQueue.RemoveFreeNotification(Self);
  FQueue := Value; if Value<>nil then Value.FreeNotification(Self);
end;

procedure TCardOperationExecutor.SetOnResult(const Value: TCardOperationResultEvent);
begin
  RequireCreator; if FWorker<>nil then raise ECardExecutorError.Create('Stop the executor before configuring observers.');
  FOnResult := Value;
end;

procedure TCardOperationExecutor.Start;
var State: TExecutorState; Wake: ICardOperationWake;
begin
  RequireCreator;
  if FThread<>NativeUInt(MainThreadID) then raise ECardExecutorError.Create('Automatic dispatch requires the main thread.');
  if (FWorker<>nil) or (FManager=nil) or (FQueue=nil) then
    raise ECardExecutorError.Create('An inactive executor, manager and queue are required.');
  State := TExecutorState.Create; FState := State; Wake := State;
  FResults := CreateCardEventQueue(1024);
  try
    FQueue.SetWake(Wake);
    try
      FWorker := TExecutorWorker.Create(FState,FManager,FQueue,FResults,Self,FOnResult);
      FWorker.Start; Wake.Signal;
    except FQueue.SetWake(nil); raise; end;
  except
    FWorker.Free; FWorker := nil; FResults.Disable; raise;
  end;
end;

procedure TCardOperationExecutor.RequestStop;
var State: TExecutorState;
begin
  RequireCreator; if FWorker=nil then Exit;
  State := FState as TExecutorState;
  State.Enter; try State.Stopping := True; finally State.Leave; end;
  FQueue.CancelCurrent; State.Signal;
end;

procedure TCardOperationExecutor.Stop;
begin
  RequireCreator; if FWorker=nil then Exit;
  FResults.Disable; TThread.RemoveQueuedEvents(FWorker);
  RequestStop; FWorker.WaitFor;
  FQueue.SetWake(nil); FResults.Disable;
  TThread.RemoveQueuedEvents(FWorker); FWorker.Free; FWorker := nil;
end;

procedure TCardOperationExecutor.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation=opRemove) and ((AComponent=FManager) or (AComponent=FQueue)) then begin
    Stop;
    if AComponent=FManager then FManager := nil;
    if AComponent=FQueue then FQueue := nil;
  end;
  inherited Notification(AComponent,Operation);
end;

destructor TCardOperationExecutor.Destroy;
begin
  Stop; if FResults<>nil then FResults.Disable; inherited Destroy;
end;

procedure TCardOperationExecutor.DispatchResults;
var Results: ICardEventQueue;
begin
  RequireCreator; Results := FResults; if Results<>nil then Results.Dispatch;
end;

function TCardOperationExecutor.LastResult: TCardOperationResult;
var State: TExecutorState;
begin
  RequireCreator; Result := Default(TCardOperationResult); if FState=nil then Exit;
  State := FState as TExecutorState; State.Enter;
  try Result := State.Last; finally State.Leave; end;
end;

function TCardOperationExecutor.ErrorClass: string;
var State: TExecutorState;
begin
  RequireCreator; Result := ''; if FState=nil then Exit;
  State := FState as TExecutorState; State.Enter;
  try Result := State.Error; finally State.Leave; end;
end;

function TCardOperationExecutor.GetRunning: Boolean;
var State: TExecutorState;
begin
  RequireCreator; Result := False; if FWorker=nil then Exit;
  State := FState as TExecutorState; State.Enter;
  try Result := not State.Finished; finally State.Leave; end;
end;

end.
