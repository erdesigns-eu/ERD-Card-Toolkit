unit ERD.Card.PCSC.Monitor;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}Classes, SysUtils, {$ELSE}System.Classes, System.SysUtils, {$ENDIF}
  ERD.Card.PCSC.Api;

type
  /// <summary>Main-thread reader arrival/removal notification; contains the exact PC/SC identity.</summary>
  /// <param name="Sender">Monitor publishing the event.</param>
  /// <param name="AReaderName">Exact Unicode reader name, usable for explicit card connection.</param>
  TPcscReaderEvent = procedure(Sender: TObject;
    const AReaderName: UnicodeString) of object;
  /// <summary>Main-thread card/state notification; provides owned raw state and ATR without opening the card.</summary>
  /// <param name="Sender">Monitor publishing the event.</param>
  /// <param name="ASnapshot">Independent snapshot; removal carries the last known snapshot, insertion/state the newly observed state.</param>
  TPcscCardEvent = procedure(Sender: TObject;
    const ASnapshot: TPcscReaderSnapshot) of object;
  /// <summary>Main-thread terminal monitor failure; monitor is stopped before invoking the handler.</summary>
  /// <param name="Sender">Stopped monitor; no reconnect is attempted.</param>
  /// <param name="AStatusCode">Unsigned native error or PcscInternalError for invalid data/queue overflow.</param>
  TPcscMonitorErrorEvent = procedure(Sender: TObject;
    const AStatusCode: Cardinal) of object;

  /// <summary>Nonvisual event-driven PC/SC reader inventory and card-presence monitor.</summary>
  /// <remarks>Uses dedicated context and native multi-reader/PnP waits, never card connections/APDUs.
  /// All lifecycle/configuration and callbacks belong to the main thread. VCL delivers queued callbacks
  /// automatically; console/service hosts must run the RTL CheckSynchronize event dispatcher.
  /// Stop invalidates queued callbacks before cancel/join. A handler may stop or free the component.
  /// This monitors physical presence/state, not eID/EMV/RFID content; connect/read explicitly in a worker.</remarks>
  TSmartCardMonitor = class(TComponent)
  private
    FApi: IPcscApi;
    FWorker: TThread;
    FEmitInitial: Boolean;
    FOnReaderAdded, FOnReaderRemoved: TPcscReaderEvent;
    FOnCardInserted, FOnCardRemoved, FOnStateChanged: TPcscCardEvent;
    FOnError: TPcscMonitorErrorEvent;
    procedure SetEmitInitial(const AValue: Boolean);
    function GetActive: Boolean;
  public
    /// <summary>Constructs inactive native observation; opens no context or hardware.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Constructs inactive observation through an injectable PC/SC API supporting IPcscMonitorApi.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    /// <param name="AApi">Retained thread-safe API; multi-reader support is checked at Start.</param>
    constructor CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
    /// <summary>Invalidates notifications, cancels/joins the wait and releases the dedicated context.</summary>
    destructor Destroy; override;
    /// <summary>Starts native event observation after full component construction; no selected reader is needed.</summary>
    /// <exception cref="EPcscError">Context acquisition or multi-reader API support fails.</exception>
    /// <remarks>Existing readers/cards are initially reported when EmitInitialState=True; no application polling is required.</remarks>
    procedure Start;
    /// <summary>Stops observation and discards queued events; safe to repeat from callbacks.</summary>
    /// <remarks>Missed cancellation is bounded by the native 250-ms timeout; card commands are unaffected.</remarks>
    procedure Stop;
    /// <summary>True while the monitor owns its worker; terminal failures stop it before OnError.</summary>
    property Active: Boolean read GetActive;
  published
    /// <summary>Report existing readers/cards at startup; defaults true. Change only while inactive.</summary>
    property EmitInitialState: Boolean read FEmitInitial write SetEmitInitial
      default True;
    /// <summary>Exact reader arrival; never selects or connects automatically.</summary>
    property OnReaderAdded: TPcscReaderEvent read FOnReaderAdded
      write FOnReaderAdded;
    /// <summary>Exact reader removal; a present card is reported removed before its reader.</summary>
    property OnReaderRemoved: TPcscReaderEvent read FOnReaderRemoved
      write FOnReaderRemoved;
    /// <summary>Card presence or replacement observed by the driver; not every RF approach is guaranteed detectable.</summary>
    property OnCardInserted: TPcscCardEvent read FOnCardInserted
      write FOnCardInserted;
    /// <summary>Card removal or reader loss, retaining the last known ATR.</summary>
    property OnCardRemoved: TPcscCardEvent read FOnCardRemoved
      write FOnCardRemoved;
    /// <summary>State/ATR change, including presence, availability, mute and usage flags.</summary>
    property OnStateChanged: TPcscCardEvent read FOnStateChanged
      write FOnStateChanged;
    /// <summary>Terminal sanitized failure; restart is an explicit application decision.</summary>
    property OnError: TPcscMonitorErrorEvent read FOnError write FOnError;
  end;

implementation

uses ERD.Card.Events, ERD.Card.Bytes, ERD.Card.PCSC.Windows;

type
  TNoticeKind = (nkAdded, nkRemoved, nkInserted, nkCardRemoved,
    nkState, nkError);

  TNotice = class(TInterfacedObject, ICardQueuedEvent)
    Owner: TSmartCardMonitor;
    Kind: TNoticeKind;
    Snapshot: TPcscReaderSnapshot;
    Status: Cardinal;
    procedure Invoke;
  end;

  TMonitorWorker = class(TThread)
  private
    FApi: IPcscApi;
    FBulk: IPcscMonitorApi;
    FContext: TPcscHandle;
    FOwner: TSmartCardMonitor;
    FQueue: ICardEventQueue;
    FCreated, FStarted, FEmitInitial: Boolean;
    procedure Deliver;
    procedure Post(const Kind: TNoticeKind; const Snapshot: TPcscReaderSnapshot;
      const Status: Cardinal = 0);
  protected
    procedure Execute; override;
  public
    constructor Create(const Owner: TSmartCardMonitor; const Api: IPcscApi;
      const Bulk: IPcscMonitorApi; const Context: TPcscHandle);
    destructor Destroy; override;
    procedure BeginWatching;
  end;

procedure RequireMain;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID) <> NativeUInt(MainThreadID) then
    raise ECardEventError.Create
      ('Monitor lifecycle belongs to the main thread.');
end;

procedure TNotice.Invoke;
var
  ReaderEvent: TPcscReaderEvent;
  CardEvent: TPcscCardEvent;
  ErrorEvent: TPcscMonitorErrorEvent;
begin
  ReaderEvent := nil;
  CardEvent := nil;
  case Kind of
    nkAdded:
      ReaderEvent := Owner.FOnReaderAdded;
    nkRemoved:
      ReaderEvent := Owner.FOnReaderRemoved;
    nkInserted:
      CardEvent := Owner.FOnCardInserted;
    nkCardRemoved:
      CardEvent := Owner.FOnCardRemoved;
    nkState:
      CardEvent := Owner.FOnStateChanged;
    nkError:
      begin
        ErrorEvent := Owner.FOnError;
        Owner.Stop;
        if Assigned(ErrorEvent) then
          ErrorEvent(Owner, Status);
        Exit;
      end;
  end;
  if Assigned(ReaderEvent) then
    ReaderEvent(Owner, Snapshot.ReaderName)
  else if Assigned(CardEvent) then
    CardEvent(Owner, Snapshot);
end;

constructor TMonitorWorker.Create(const Owner: TSmartCardMonitor;
  const Api: IPcscApi; const Bulk: IPcscMonitorApi; const Context: TPcscHandle);
begin
  inherited Create(True);
  FCreated := True;
  FreeOnTerminate := False;
  FApi := Api;
  FBulk := Bulk;
  FOwner := Owner;
  FEmitInitial := Owner.EmitInitialState;
  FQueue := CreateCardEventQueue;
  FContext := Context;
end;

procedure TMonitorWorker.BeginWatching;
begin
  FStarted := True;
  Start;
end;

destructor TMonitorWorker.Destroy;
begin
  if FQueue <> nil then
    FQueue.Disable;
  if FCreated then
  begin
    Terminate;
    if FContext <> 0 then
      FApi.Cancel(FContext);
    if not FStarted then
      BeginWatching;
    WaitFor;
    TThread.RemoveQueuedEvents(Self);
  end;
  if FContext <> 0 then
    FApi.Release(FContext);
  FContext := 0;
  inherited Destroy;
end;

procedure TMonitorWorker.Deliver;
var
  Q: ICardEventQueue;
begin
  Q := FQueue;
  Q.Dispatch;
end;

procedure TMonitorWorker.Post(const Kind: TNoticeKind;
  const Snapshot: TPcscReaderSnapshot; const Status: Cardinal);
var
  N: TNotice;
  Event: ICardQueuedEvent;
  Schedule: Boolean;
begin
  N := TNotice.Create;
  Event := N;
  N.Owner := FOwner;
  N.Kind := Kind;
  N.Status := Status;
  N.Snapshot := Snapshot;
  N.Snapshot.Atr := CopyBytes(Snapshot.Atr);
  if Kind = nkError then
    Schedule := FQueue.Replace(Event)
  else
    Schedule := FQueue.Add(Event);
  if Schedule then
    TThread.Queue(Self, Deliver);
end;

function Present(const S: TPcscReaderSnapshot): Boolean;
begin
  Result := ((S.State and PcscStatePresent) <> 0) and
    ((S.State and (PcscStateUnknown or PcscStateUnavailable)) = 0);
end;

function Find(const A: TPcscReaderSnapshots; const Name: UnicodeString)
  : Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(A) do
    if A[I].ReaderName = Name then
      Exit(I);
end;

procedure TMonitorWorker.Execute;
var
  Current, Next, Rebuilt: TPcscReaderSnapshots;
  Names: TPcscReaderNames;
  I, K: Integer;
  Status, Delta: Cardinal;
  Initial, FirstInventory, Changed, Replacement: Boolean;
  Snapshot: TPcscReaderSnapshot;
  procedure Refresh;
  var
    X, Y, N: Integer;
  begin
    Status := FApi.ListReaders(FContext, Names);
    if Status = PcscNoReaders then
      Names := nil
    else if Status <> PcscSuccess then
      raise EPcscError.Create('ListMonitorReaders', Status);
    if Length(Names) > 1024 then
      raise EPcscError.Create('MonitorInventory', PcscInternalError);
    Rebuilt := nil;
    SetLength(Rebuilt, Length(Names) + 1);
    for X := 0 to High(Names) do
    begin
      if (Names[X] = '') or (Names[X] = PcscPnpNotification) or
        (Pos(#0, Names[X]) <> 0) then
        raise EPcscError.Create('MonitorInventory', PcscInternalError);
      for Y := 0 to X - 1 do
        if Names[X] = Names[Y] then
          raise EPcscError.Create('MonitorInventory', PcscInternalError);
    end;
    for X := 0 to High(Names) do
    begin
      N := Find(Current, Names[X]);
      if N >= 0 then
        Rebuilt[X] := Current[N]
      else
      begin
        Rebuilt[X].ReaderName := Names[X];
        if not FirstInventory or FEmitInitial then
          Post(nkAdded, Rebuilt[X]);
      end;
    end;
    for X := 0 to High(Current) - 1 do
      if Find(Rebuilt, Current[X].ReaderName) < 0 then
      begin
        if Present(Current[X]) then
          Post(nkCardRemoved, Current[X]);
        Post(nkRemoved, Current[X]);
      end;
    Rebuilt[High(Rebuilt)].ReaderName := PcscPnpNotification;
    if Length(Current) > 0 then
      Rebuilt[High(Rebuilt)].State := Current[High(Current)].State;
    Current := Rebuilt;
    FirstInventory := False;
  end;

begin
  Initial := True;
  FirstInventory := True;
  try
    if Terminated then
      Exit;
    Refresh;
    while not Terminated do
    begin
      Status := FBulk.WaitReaders(FContext, Current, 250, Next);
      if Terminated then
        Exit;
      if Status = PcscTimeout then
        Continue;
      if Status <> PcscSuccess then
        raise EPcscError.Create('MonitorReaders', Status);
      if Length(Next) <> Length(Current) then
        raise EPcscError.Create('MonitorResponse', PcscInternalError);
      for I := 0 to High(Next) do
        if (Next[I].ReaderName <> Current[I].ReaderName) or
          (Length(Next[I].Atr) > PcscMaxAtrBytes) then
          raise EPcscError.Create('MonitorResponse', PcscInternalError);
      K := High(Next);
      if (Next[K].State and (PcscStateUnknown or PcscStateUnavailable)) <> 0
      then
        raise EPcscError.Create('MonitorPnP', PcscUnsupportedFeature);
      Changed := False;
      for I := 0 to K - 1 do
      begin
        Next[I].State := Next[I].State and not PcscStateChanged;
        if (Current[I].State <> Next[I].State) or not BytesEqual(Current[I].Atr,
          Next[I].Atr) then
        begin
          Changed := True;
          Snapshot := Next[I];
          if not Initial or FEmitInitial then
          begin
            Replacement := Present(Current[I]) and Present(Next[I]) and
              (((Current[I].State xor Next[I].State) and $FFFF0000 <> 0) or
              not BytesEqual(Current[I].Atr, Next[I].Atr));
            if Present(Current[I]) and (not Present(Next[I]) or Replacement)
            then
              Post(nkCardRemoved, Current[I]);
            if Present(Next[I]) and (not Present(Current[I]) or Replacement)
            then
              Post(nkInserted, Next[I]);
            Post(nkState, Snapshot);
          end;
        end;
      end;
      Delta := (Next[K].State xor Current[K].State) and not PcscStateChanged;
      { Keep a nonzero PnP current-state marker even when its native inventory counter is zero. }
      Next[K].State := Next[K].State or PcscStateChanged;
      Current := Next;
      if Initial or (Delta <> 0) then
      begin
        Changed := True;
        Refresh;
      end;
      Initial := False;
      if not Changed then
        Sleep(10);
    end;
  except
    on E: EPcscError do
      Post(nkError, Default (TPcscReaderSnapshot), E.StatusCode);
    on E: Exception do
      Post(nkError, Default (TPcscReaderSnapshot), PcscInternalError);
  end;
end;

constructor TSmartCardMonitor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FApi := CreateSystemPcscApi;
  FEmitInitial := True;
end;

constructor TSmartCardMonitor.CreateWithApi(AOwner: TComponent;
  const AApi: IPcscApi);
begin
  inherited Create(AOwner);
  if AApi = nil then
    raise ECardEventError.Create('A monitor API is required.');
  FApi := AApi;
  FEmitInitial := True;
end;

destructor TSmartCardMonitor.Destroy;
begin
  Stop;
  inherited Destroy;
end;

function TSmartCardMonitor.GetActive: Boolean;
begin
  Result := FWorker <> nil;
end;

procedure TSmartCardMonitor.SetEmitInitial(const AValue: Boolean);
begin
  RequireMain;
  if Active then
    raise ECardEventError.Create('Stop monitoring before configuration.');
  FEmitInitial := AValue;
end;

procedure TSmartCardMonitor.Start;
var
  Bulk: IPcscMonitorApi;
  Context: TPcscHandle;
  Status: Cardinal;
  W: TMonitorWorker;
begin
  RequireMain;
  if Active then
    raise ECardEventError.Create('The monitor is already active.');
  if not Supports(FApi, IPcscMonitorApi, Bulk) then
    raise EPcscError.Create('MonitorApi', PcscUnsupportedFeature);
  Context := 0;
  Status := FApi.Establish(Context);
  if Status <> PcscSuccess then
    raise EPcscError.Create('MonitorContext', Status);
  if Context = 0 then
    raise EPcscError.Create('MonitorContext', PcscInternalError);
  try
    W := TMonitorWorker.Create(Self, FApi, Bulk, Context);
  except
    FApi.Release(Context);
    raise;
  end;
  FWorker := W;
  try
    W.BeginWatching;
  except
    FWorker := nil;
    W.Free;
    raise;
  end;
end;

procedure TSmartCardMonitor.Stop;
var
  W: TThread;
begin
  RequireMain;
  W := FWorker;
  FWorker := nil;
  W.Free;
end;

end.
