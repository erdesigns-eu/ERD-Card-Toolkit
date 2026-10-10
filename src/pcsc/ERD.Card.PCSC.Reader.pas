unit ERD.Card.PCSC.Reader;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes, System.SysUtils,
{$ENDIF}
  ERD.Card.Transport,
  ERD.Card.PCSC.Api, ERD.Card.PCSC.Monitor;

type
  /// <summary>A caller-thread notification containing the latest independent reader snapshot.</summary>
  /// <param name="Sender">The component that dispatched PollChanges.</param>
  /// <param name="ASnapshot">The latest state; not a complete history of intermediate transitions.</param>
  TCardStateChangeEvent = procedure(Sender: TObject;
    const ASnapshot: TPcscReaderSnapshot) of object;

  /// <summary>A non-visual PC/SC card connection with independent optional reader monitoring.</summary>
  /// <remarks>
  /// Construction never opens hardware. Configuration and lifecycle methods belong
  /// to one caller/control thread. Retained Transport interfaces serialize exchanges
  /// and remain valid after the component is freed, but its connection is then closed.
  /// Transactions belong to their initiating thread. Monitoring uses a separate
  /// context. StartMonitoring retains the legacy latest-state/PollChanges mode;
  /// StartEventMonitoring delivers ordered main-thread events automatically through
  /// the RTL dispatcher. No automatic reconnects or command retries occur. Native transmit/transaction calls may block; stop monitoring does not
  /// cancel card commands. The optional ERDCardDesign package registers this inactive component.
  /// </remarks>
  TSmartCardReader = class(TComponent)
  private
    FApi: IPcscApi;
    FSession: TObject;
    FTransport: ICardTransport;
    FWatcher: TThread;
    FEventMonitor: TSmartCardMonitor;
    FOnCardInserted, FOnCardRemoved: TPcscCardEvent;
    FOnReaderAdded, FOnReaderRemoved: TPcscReaderEvent;
    FOnMonitorError: TPcscMonitorErrorEvent;
    procedure EventInserted(Sender: TObject;
      const ASnapshot: TPcscReaderSnapshot);
    procedure EventRemoved(Sender: TObject;
      const ASnapshot: TPcscReaderSnapshot);
    procedure EventState(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
    procedure EventReaderAdded(Sender: TObject;
      const AReaderName: UnicodeString);
    procedure EventReaderRemoved(Sender: TObject;
      const AReaderName: UnicodeString);
    procedure EventError(Sender: TObject; const AStatusCode: Cardinal);
  private
    FReaderName: UnicodeString;
    FShareMode: TPcscShareMode;
    FProtocols: Cardinal;
    FMaxResponseBytes: Integer;
    FOnCardStateChange: TCardStateChangeEvent;
    procedure Initialize(const AApi: IPcscApi);
    procedure RequireConfigurable;
    procedure SetReaderName(const AValue: UnicodeString);
    procedure SetShareMode(const AValue: TPcscShareMode);
    procedure SetProtocols(const AValue: Cardinal);
    procedure SetMaxResponseBytes(const AValue: Integer);
    procedure SetOnCardStateChange(const AValue: TCardStateChangeEvent);
    function GetConnected: Boolean;
    function GetProtocol: TPcscProtocol;
    function GetMonitoring: Boolean;
  public
    /// <summary>Creates an inactive component using the system PC/SC adapter.</summary>
    /// <param name="AOwner">The optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Creates an inactive component using an injected API adapter.</summary>
    /// <param name="AOwner">The optional component owner.</param>
    /// <param name="AApi">A non-nil thread-safe native or test adapter.</param>
    /// <exception cref="ECardTransportError">The adapter is nil.</exception>
    constructor CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
    /// <summary>Stops/joins monitoring and closes the connection without raising cleanup errors.</summary>
    /// <remarks>Retained transports become disconnected; the adapter remains alive while they are retained.</remarks>
    destructor Destroy; override;
    /// <summary>Returns Unicode reader names without connecting to a card.</summary>
    /// <returns>Independent reader names; empty if PC/SC reports no readers.</returns>
    /// <exception cref="EPcscError">The context or discovery operation failed.</exception>
    function ListReaders: TPcscReaderNames;
    /// <summary>Opens the configured reader by exact name and negotiates T=0 or T=1.</summary>
    /// <exception cref="ECardTransportError">Configuration or the connection state is invalid.</exception>
    /// <exception cref="EPcscError">A native context or connection operation failed.</exception>
    procedure Connect;
    /// <summary>Closes the connection and its context; optional monitoring remains active.</summary>
    /// <param name="ADisposition">Explicit card action; leave unchanged by default.</param>
    /// <exception cref="EPcscError">Cleanup failed; local handles are still cleared.</exception>
    /// <exception cref="ECardTransportError">Another thread owns the active transaction.</exception>
    procedure Disconnect(const ADisposition: TPcscDisposition = pcdLeave);
    /// <summary>Acquires a non-nested card transaction owned by the calling thread.</summary>
    /// <exception cref="ECardTransportError">Disconnected or already inside a transaction.</exception>
    /// <exception cref="EPcscError">Native transaction acquisition failed.</exception>
    procedure BeginTransaction;
    /// <summary>Ends this thread's active transaction with an explicit card action.</summary>
    /// <param name="ADisposition">Explicit card action; leave unchanged by default.</param>
    /// <exception cref="ECardTransportError">No transaction exists or another thread owns it.</exception>
    /// <exception cref="EPcscError">Ending failed; the ambiguous connection is closed.</exception>
    procedure EndTransaction(const ADisposition: TPcscDisposition = pcdLeave);
    /// <summary>Reads independent raw ATR bytes from the connected card.</summary>
    /// <returns>Uninterpreted ATR bytes; card profiles decide their meaning.</returns>
    /// <exception cref="ECardTransportError">Disconnected or another thread owns the transaction.</exception>
    /// <exception cref="EPcscError">The native ATR operation failed.</exception>
    function ReadAtr: TBytes;
    /// <summary>Starts observation of the selected reader without connecting to a card.</summary>
    /// <exception cref="ECardTransportError">The name is invalid or monitoring already exists.</exception>
    /// <exception cref="EPcscError">Creating the independent monitor context failed.</exception>
    procedure StartMonitoring;
    /// <summary>Starts main-thread events for the selected reader's cards and all reader arrivals/removals.</summary>
    /// <remarks>Uses native PnP waits without PollChanges. VCL dispatches automatically; other hosts use CheckSynchronize.
    /// Configure on the main thread while monitoring is stopped. Initially present readers/cards are reported.</remarks>
    /// <exception cref="EPcscError">Native context acquisition or multi-reader support fails.</exception>
    procedure StartEventMonitoring;
    /// <summary>Cancels and joins the monitor, then releases its context; safe to repeat.</summary>
    /// <remarks>A finite 250 ms wait bounds a missed cancellation race; backend timeouts must be honored.</remarks>
    procedure StopMonitoring;
    /// <summary>Takes the latest pending snapshot and dispatches its event on the calling thread.</summary>
    /// <param name="ASnapshot">Independent latest state, or a cleared record when nothing is pending.</param>
    /// <returns>True when a new state was consumed.</returns>
    /// <exception cref="EPcscError">A monitor operation failed; monitoring is stopped before raising.</exception>
    /// <remarks>Call regularly from the desired event thread, such as a UI timer. Intermediate states may be coalesced.</remarks>
    function PollChanges(out ASnapshot: TPcscReaderSnapshot): Boolean;
    /// <summary>A reference-counted byte transport tied to this component's connection lifecycle.</summary>
    property Transport: ICardTransport read FTransport;
    /// <summary>Whether a local card handle is open; physical removal is detected by native operations.</summary>
    property Connected: Boolean read GetConnected;
    /// <summary>The negotiated protocol, or pcpNone when disconnected.</summary>
    property Protocol: TPcscProtocol read GetProtocol;
    /// <summary>Whether manual or automatic observation is active; automatic failures use OnMonitorError.</summary>
    property Monitoring: Boolean read GetMonitoring;
  published
    /// <summary>The exact Unicode reader name; configure only while disconnected and not monitoring.</summary>
    property ReaderName: UnicodeString read FReaderName write SetReaderName;
    /// <summary>The sharing policy; defaults to shared access and changes only while inactive.</summary>
    property ShareMode: TPcscShareMode read FShareMode write SetShareMode
      default psmShared;
    /// <summary>The allowed native protocol mask: T=0, T=1 or both; configure only while inactive.</summary>
    property Protocols: Cardinal read FProtocols write SetProtocols default 3;
    /// <summary>The receive capacity from 2 through CardMaxResponseBytes; configure only while inactive.</summary>
    property MaxResponseBytes: Integer read FMaxResponseBytes
      write SetMaxResponseBytes default CardMaxResponseBytes;
    /// <summary>State change from PollChanges or main-thread StartEventMonitoring; configure while stopped.</summary>
    property OnCardStateChange: TCardStateChangeEvent read FOnCardStateChange
      write SetOnCardStateChange;
    /// <summary>Selected reader card insertion/replacement, delivered by StartEventMonitoring on the main thread.</summary>
    property OnCardInserted: TPcscCardEvent read FOnCardInserted
      write FOnCardInserted;
    /// <summary>Selected reader card removal or reader loss, retaining the previous ATR.</summary>
    property OnCardRemoved: TPcscCardEvent read FOnCardRemoved
      write FOnCardRemoved;
    /// <summary>Any PC/SC reader arrival; exact name, without changing the selected reader.</summary>
    property OnReaderAdded: TPcscReaderEvent read FOnReaderAdded
      write FOnReaderAdded;
    /// <summary>Any PC/SC reader disappearance, delivered after its card removal.</summary>
    property OnReaderRemoved: TPcscReaderEvent read FOnReaderRemoved
      write FOnReaderRemoved;
    /// <summary>Terminal automatic monitor failure; monitoring is already stopped before this handler.</summary>
    property OnMonitorError: TPcscMonitorErrorEvent read FOnMonitorError
      write FOnMonitorError;
  end;

implementation

uses
{$IFNDEF FPC}
  System.SyncObjs,
{$ENDIF}
  ERD.Card.Bytes,
  ERD.Card.PCSC.Windows;

type
{$IFDEF FPC}
  TInternalCriticalSection = TRTLCriticalSection;
{$ELSE}
  TInternalCriticalSection = TCriticalSection;
{$ENDIF}

  TInternalLock = class
  private
    FLock: TInternalCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;

  TPcscSession = class(TInterfacedObject, ICardTransport, ICardTransaction)
  private
    FApi: IPcscApi;
    FLock: TInternalLock;
    FContext: TPcscHandle;
    FCard: TPcscHandle;
    FProtocol: Cardinal;
    FMaxResponseBytes: Integer;
    FInTransaction: Boolean;
    FTransactionThread: NativeUInt;
    procedure EnsureContext;
    procedure RequireConnected;
    procedure RequireTransactionThread;
    function CloseInternal(const ADisposition: TPcscDisposition): Cardinal;
  public
    constructor Create(const AApi: IPcscApi);
    destructor Destroy; override;
    function ListReaders: TPcscReaderNames;
    procedure Connect(const AName: UnicodeString; const AShare: TPcscShareMode;
      const AProtocols: Cardinal; const ACapacity: Integer);
    procedure Close(const ADisposition: TPcscDisposition;
      const AReportErrors: Boolean);
    procedure BeginTransaction;
    procedure EndTransaction; overload;
    procedure EndTransaction(const ADisposition: TPcscDisposition); overload;
    function ReadAtr: TBytes;
    function Exchange(const ACommand: TBytes): TBytes;
    function Connected: Boolean;
    function Protocol: TPcscProtocol;
  end;

  TPcscWatcher = class(TThread)
  private
    FApi: IPcscApi;
    FContext: TPcscHandle;
    FName: UnicodeString;
    FLock: TInternalLock;
    FThreadCreated: Boolean;
    FStarted: Boolean;
    FPending: Boolean;
    FSnapshot: TPcscReaderSnapshot;
    FError: Cardinal;
    procedure Publish(const ASnapshot: TPcscReaderSnapshot;
      const AError: Cardinal);
  protected
    procedure Execute; override;
  public
    constructor Create(const AApi: IPcscApi; const AName: UnicodeString;
      const AContext: TPcscHandle);
    destructor Destroy; override;
    procedure StartWatching;
    function Take(out ASnapshot: TPcscReaderSnapshot;
      out AError: Cardinal): Boolean;
  end;

constructor TInternalLock.Create;
begin
  inherited Create;
{$IFDEF FPC}
  InitCriticalSection(FLock);
{$ELSE}
  FLock := TCriticalSection.Create;
{$ENDIF}
end;

destructor TInternalLock.Destroy;
begin
{$IFDEF FPC}
  DoneCriticalSection(FLock);
{$ELSE}
  FLock.Free;
{$ENDIF}
  inherited Destroy;
end;

procedure TInternalLock.Enter;
begin
{$IFDEF FPC}
  EnterCriticalSection(FLock);
{$ELSE}
  FLock.Enter;
{$ENDIF}
end;

procedure TInternalLock.Leave;
begin
{$IFDEF FPC}
  LeaveCriticalSection(FLock);
{$ELSE}
  FLock.Leave;
{$ENDIF}
end;

procedure CheckStatus(const AStatus: Cardinal; const AOperation: string);
begin
  if AStatus <> PcscSuccess then
    raise EPcscError.Create(AOperation, AStatus);
end;

procedure ValidateName(const AName: UnicodeString);
begin
  if (AName = '') or (Pos(#0, AName) <> 0) then
    raise ECardTransportError.Create
      ('A nonempty reader name without null characters is required.');
end;

function CopySnapshot(const ASnapshot: TPcscReaderSnapshot)
  : TPcscReaderSnapshot;
begin
  Result.ReaderName := ASnapshot.ReaderName;
  Result.State := ASnapshot.State and not PcscStateChanged;
  Result.Atr := CopyBytes(ASnapshot.Atr);
end;

constructor TPcscSession.Create(const AApi: IPcscApi);
begin
  inherited Create;
  FApi := AApi;
  FLock := TInternalLock.Create;
end;

destructor TPcscSession.Destroy;
begin
  if FLock <> nil then
    Close(pcdLeave, False);
  FLock.Free;
  inherited Destroy;
end;

procedure TPcscSession.EnsureContext;
var
  Context: TPcscHandle;
begin
  if FContext <> 0 then
    Exit;
  CheckStatus(FApi.Establish(Context), 'EstablishContext');
  if Context = 0 then
    raise EPcscError.Create('EstablishContext', PcscInternalError);
  FContext := Context;
end;

procedure TPcscSession.RequireConnected;
begin
  if FCard = 0 then
    raise ECardTransportError.Create('The card transport is disconnected.');
  RequireTransactionThread;
end;

procedure TPcscSession.RequireTransactionThread;
begin
  if FInTransaction and
    (FTransactionThread <> NativeUInt(TThread.CurrentThread.ThreadID)) then
    raise ECardTransportError.Create
      ('The transaction belongs to another thread.');
end;

function TPcscSession.CloseInternal(const ADisposition: TPcscDisposition)
  : Cardinal;
var
  Card: TPcscHandle;
  Context: TPcscHandle;
  Status: Cardinal;
begin
  Card := FCard;
  Context := FContext;
  FCard := 0;
  FContext := 0;
  FProtocol := 0;
  FInTransaction := False;
  FTransactionThread := 0;
  Result := PcscSuccess;
  if Card <> 0 then
    Result := FApi.Disconnect(Card, ADisposition);
  if Context <> 0 then
  begin
    Status := FApi.Release(Context);
    if Result = PcscSuccess then
      Result := Status;
  end;
end;

procedure TPcscSession.Close(const ADisposition: TPcscDisposition;
  const AReportErrors: Boolean);
var
  Status: Cardinal;
begin
  FLock.Enter;
  try
    if AReportErrors then
      RequireTransactionThread;
    Status := CloseInternal(ADisposition);
    if AReportErrors then
      CheckStatus(Status, 'CloseConnection');
  finally
    FLock.Leave;
  end;
end;

function TPcscSession.ListReaders: TPcscReaderNames;
var
  Status: Cardinal;
begin
  FLock.Enter;
  try
    RequireTransactionThread;
    EnsureContext;
    Status := FApi.ListReaders(FContext, Result);
    if Status = PcscNoReaders then
      Result := nil
    else
      CheckStatus(Status, 'ListReaders');
  finally
    FLock.Leave;
  end;
end;

procedure TPcscSession.Connect(const AName: UnicodeString;
  const AShare: TPcscShareMode; const AProtocols: Cardinal;
  const ACapacity: Integer);
begin
  FLock.Enter;
  try
    if FCard <> 0 then
      raise ECardTransportError.Create
        ('The card transport is already connected.');
    ValidateName(AName);
    EnsureContext;
    try
      CheckStatus(FApi.Connect(FContext, AName, AShare, AProtocols, FCard,
        FProtocol), 'Connect');
      if (FCard = 0) or ((FProtocol <> PcscProtocolT0) and
        (FProtocol <> PcscProtocolT1)) or ((FProtocol and AProtocols) = 0) then
        raise EPcscError.Create('Connect', PcscInternalError);
      FMaxResponseBytes := ACapacity;
    except
      CloseInternal(pcdLeave);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TPcscSession.BeginTransaction;
begin
  FLock.Enter;
  try
    RequireConnected;
    if FInTransaction then
      raise ECardTransportError.Create('Nested transactions are unsupported.');
    CheckStatus(FApi.BeginTransaction(FCard), 'BeginTransaction');
    FInTransaction := True;
    FTransactionThread := NativeUInt(TThread.CurrentThread.ThreadID);
  finally
    FLock.Leave;
  end;
end;

procedure TPcscSession.EndTransaction;
begin
  EndTransaction(pcdLeave);
end;

procedure TPcscSession.EndTransaction(const ADisposition: TPcscDisposition);
begin
  FLock.Enter;
  try
    RequireConnected;
    if not FInTransaction then
      raise ECardTransportError.Create('No transaction is active.');
    try
      CheckStatus(FApi.EndTransaction(FCard, ADisposition), 'EndTransaction');
    except
      CloseInternal(pcdLeave);
      raise;
    end;
    FInTransaction := False;
    FTransactionThread := 0;
  finally
    FLock.Leave;
  end;
end;

function TPcscSession.ReadAtr: TBytes;
begin
  FLock.Enter;
  try
    RequireConnected;
    CheckStatus(FApi.ReadAtr(FCard, Result), 'ReadAtr');
    if Length(Result) > PcscMaxAtrBytes then
      raise EPcscError.Create('ReadAtr', PcscInternalError);
    Result := CopyBytes(Result);
  finally
    FLock.Leave;
  end;
end;

function TPcscSession.Exchange(const ACommand: TBytes): TBytes;
var
  Command: TBytes;
begin
  Result := nil;
  if (Length(ACommand) = 0) or (Length(ACommand) > CardMaxCommandBytes) then
    raise ECardTransportError.Create('The command exceeds transport bounds.');
  Command := CopyBytes(ACommand);
  FLock.Enter;
  try
    RequireConnected;
    try
      CheckStatus(FApi.Transmit(FCard, FProtocol, Command, FMaxResponseBytes,
        Result), 'Transmit');
      if (Length(Result) < 2) or (Length(Result) > FMaxResponseBytes) then
        raise ECardTransportError.Create
          ('The response exceeds transport bounds or lacks status bytes.');
      Result := CopyBytes(Result);
    except
      Result := nil;
      CloseInternal(pcdLeave);
      raise;
    end;
  finally
    FLock.Leave;
  end;
end;

function TPcscSession.Connected: Boolean;
begin
  FLock.Enter;
  try
    Result := FCard <> 0;
  finally
    FLock.Leave;
  end;
end;

function TPcscSession.Protocol: TPcscProtocol;
begin
  FLock.Enter;
  try
    case FProtocol of
      1:
        Result := pcpT0;
      2:
        Result := pcpT1;
    else
      Result := pcpNone;
    end;
  finally
    FLock.Leave;
  end;
end;

constructor TPcscWatcher.Create(const AApi: IPcscApi;
  const AName: UnicodeString; const AContext: TPcscHandle);
begin
  inherited Create(True);
  FThreadCreated := True;
  FreeOnTerminate := False;
  FApi := AApi;
  FName := AName;
  FLock := TInternalLock.Create;
  // Transfer context ownership last; a failed constructor leaves it with the caller.
  FContext := AContext;
end;

procedure TPcscWatcher.StartWatching;
begin
  FStarted := True;
  Start;
end;

destructor TPcscWatcher.Destroy;
begin
  if FThreadCreated then
  begin
    Terminate;
    if FContext <> 0 then
      FApi.Cancel(FContext);
    // Start a never-started thread only after termination, so Execute cannot wait.
    if not FStarted then
      StartWatching;
    WaitFor;
  end;
  if FContext <> 0 then
    FApi.Release(FContext);
  FContext := 0;
  FLock.Free;
  inherited Destroy;
end;

procedure TPcscWatcher.Publish(const ASnapshot: TPcscReaderSnapshot;
  const AError: Cardinal);
begin
  FLock.Enter;
  try
    FSnapshot := CopySnapshot(ASnapshot);
    FError := AError;
    FPending := True;
  finally
    FLock.Leave;
  end;
end;

procedure TPcscWatcher.Execute;
var
  Current: Cardinal;
  Snapshot: TPcscReaderSnapshot;
  PreviousAtr: TBytes;
  Status: Cardinal;
  Initial: Boolean;
begin
  Current := PcscStateUnaware;
  PreviousAtr := nil;
  Initial := True;
  try
    while not Terminated do
    begin
      Status := FApi.WaitStatus(FContext, FName, Current, 250, Snapshot);
      if Terminated then
        Exit;
      if Status = PcscTimeout then
        Continue;
      if Status <> PcscSuccess then
      begin
        Publish(Default (TPcscReaderSnapshot), Status);
        Exit;
      end;
      if (Snapshot.ReaderName <> FName) or
        (Length(Snapshot.Atr) > PcscMaxAtrBytes) then
      begin
        Publish(Default (TPcscReaderSnapshot), PcscInternalError);
        Exit;
      end;
      Snapshot.State := Snapshot.State and not PcscStateChanged;
      if Initial or (Snapshot.State <> Current) or
        (not BytesEqual(PreviousAtr, Snapshot.Atr)) then
      begin
        Publish(Snapshot, PcscSuccess);
        Current := Snapshot.State;
        PreviousAtr := CopyBytes(Snapshot.Atr);
        Initial := False;
      end
      else
        Sleep(10);
      // Ignored/unknown readers may return an immediate unchanged state.
    end;
  except
    on E: EPcscError do
      Publish(Default (TPcscReaderSnapshot), E.StatusCode);
    on E: Exception do
      Publish(Default (TPcscReaderSnapshot), PcscInternalError);
  end;
end;

function TPcscWatcher.Take(out ASnapshot: TPcscReaderSnapshot;
  out AError: Cardinal): Boolean;
begin
  ASnapshot := Default (TPcscReaderSnapshot);
  AError := PcscSuccess;
  FLock.Enter;
  try
    Result := FPending;
    if not Result then
      Exit;
    ASnapshot := CopySnapshot(FSnapshot);
    AError := FError;
    FPending := False;
  finally
    FLock.Leave;
  end;
end;

procedure TSmartCardReader.Initialize(const AApi: IPcscApi);
begin
  if AApi = nil then
    raise ECardTransportError.Create('A PC/SC adapter is required.');
  FApi := AApi;
  FSession := TPcscSession.Create(AApi);
  FTransport := TPcscSession(FSession);
  FShareMode := psmShared;
  FProtocols := PcscProtocolT0 or PcscProtocolT1;
  FMaxResponseBytes := CardMaxResponseBytes;
end;

constructor TSmartCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Initialize(CreateSystemPcscApi);
end;

constructor TSmartCardReader.CreateWithApi(AOwner: TComponent;
  const AApi: IPcscApi);
begin
  inherited Create(AOwner);
  Initialize(AApi);
end;

destructor TSmartCardReader.Destroy;
begin
  StopMonitoring;
  if FSession <> nil then
    TPcscSession(FSession).Close(pcdLeave, False);
  FSession := nil;
  FTransport := nil;
  FApi := nil;
  inherited Destroy;
end;

procedure TSmartCardReader.RequireConfigurable;
begin
  if Connected or Monitoring then
    raise ECardTransportError.Create
      ('Configuration requires a disconnected, non-monitoring reader.');
end;

procedure TSmartCardReader.SetReaderName(const AValue: UnicodeString);
begin
  RequireConfigurable;
  if Pos(#0, AValue) <> 0 then
    raise ECardTransportError.Create
      ('Reader names cannot contain null characters.');
  FReaderName := AValue;
end;

procedure TSmartCardReader.SetShareMode(const AValue: TPcscShareMode);
begin
  RequireConfigurable;
  if (AValue <> psmShared) and (AValue <> psmExclusive) then
    raise ECardTransportError.Create('The sharing policy is invalid.');
  FShareMode := AValue;
end;

procedure TSmartCardReader.SetProtocols(const AValue: Cardinal);
begin
  RequireConfigurable;
  if (AValue = 0) or ((AValue and not Cardinal(3)) <> 0) then
    raise ECardTransportError.Create
      ('Only T=0 and T=1 protocol masks are supported.');
  FProtocols := AValue;
end;

procedure TSmartCardReader.SetMaxResponseBytes(const AValue: Integer);
begin
  RequireConfigurable;
  if (AValue < 2) or (AValue > CardMaxResponseBytes) then
    raise ECardTransportError.Create
      ('The receive capacity exceeds transport bounds.');
  FMaxResponseBytes := AValue;
end;

procedure TSmartCardReader.SetOnCardStateChange(const AValue
  : TCardStateChangeEvent);
begin
  if Monitoring then
    raise ECardTransportError.Create
      ('Stop monitoring before replacing its event handler.');
  FOnCardStateChange := AValue;
end;

function TSmartCardReader.GetConnected: Boolean;
begin
  Result := (FSession <> nil) and TPcscSession(FSession).Connected;
end;

function TSmartCardReader.GetProtocol: TPcscProtocol;
begin
  Result := TPcscSession(FSession).Protocol;
end;

function TSmartCardReader.GetMonitoring: Boolean;
begin
  Result := (FWatcher <> nil) or
    ((FEventMonitor <> nil) and FEventMonitor.Active);
end;

function TSmartCardReader.ListReaders: TPcscReaderNames;
begin
  Result := TPcscSession(FSession).ListReaders;
end;

procedure TSmartCardReader.Connect;
begin
  TPcscSession(FSession).Connect(FReaderName, FShareMode, FProtocols,
    FMaxResponseBytes);
end;

procedure TSmartCardReader.Disconnect(const ADisposition: TPcscDisposition);
begin
  TPcscSession(FSession).Close(ADisposition, True);
end;

procedure TSmartCardReader.BeginTransaction;
begin
  TPcscSession(FSession).BeginTransaction;
end;

procedure TSmartCardReader.EndTransaction(const ADisposition: TPcscDisposition);
begin
  TPcscSession(FSession).EndTransaction(ADisposition);
end;

function TSmartCardReader.ReadAtr: TBytes;
begin
  Result := TPcscSession(FSession).ReadAtr;
end;

procedure TSmartCardReader.StartEventMonitoring;
begin
  ValidateName(FReaderName);
  if Monitoring then
    raise ECardTransportError.Create('Monitoring already exists.');
  FreeAndNil(FEventMonitor);
  FEventMonitor := TSmartCardMonitor.CreateWithApi(nil, FApi);
  try
    FEventMonitor.OnReaderAdded := EventReaderAdded;
    FEventMonitor.OnReaderRemoved := EventReaderRemoved;
    FEventMonitor.OnCardInserted := EventInserted;
    FEventMonitor.OnCardRemoved := EventRemoved;
    FEventMonitor.OnStateChanged := EventState;
    FEventMonitor.OnError := EventError;
    FEventMonitor.Start;
  except
    FreeAndNil(FEventMonitor);
    raise;
  end;
end;

procedure TSmartCardReader.EventInserted(Sender: TObject;
  const ASnapshot: TPcscReaderSnapshot);
begin
  if (ASnapshot.ReaderName = FReaderName) and Assigned(FOnCardInserted) then
    FOnCardInserted(Self, ASnapshot);
end;

procedure TSmartCardReader.EventRemoved(Sender: TObject;
  const ASnapshot: TPcscReaderSnapshot);
begin
  if (ASnapshot.ReaderName = FReaderName) and Assigned(FOnCardRemoved) then
    FOnCardRemoved(Self, ASnapshot);
end;

procedure TSmartCardReader.EventState(Sender: TObject;
  const ASnapshot: TPcscReaderSnapshot);
begin
  if (ASnapshot.ReaderName = FReaderName) and Assigned(FOnCardStateChange) then
    FOnCardStateChange(Self, ASnapshot);
end;

procedure TSmartCardReader.EventReaderAdded(Sender: TObject;
  const AReaderName: UnicodeString);
begin
  if Assigned(FOnReaderAdded) then
    FOnReaderAdded(Self, AReaderName);
end;

procedure TSmartCardReader.EventReaderRemoved(Sender: TObject;
  const AReaderName: UnicodeString);
begin
  if Assigned(FOnReaderRemoved) then
    FOnReaderRemoved(Self, AReaderName);
end;

procedure TSmartCardReader.EventError(Sender: TObject;
  const AStatusCode: Cardinal);
begin
  if Assigned(FOnMonitorError) then
    FOnMonitorError(Self, AStatusCode);
end;

procedure TSmartCardReader.StartMonitoring;
var
  Context: TPcscHandle;
  Watcher: TPcscWatcher;
begin
  ValidateName(FReaderName);
  if Monitoring then
    raise ECardTransportError.Create('Monitoring already exists.');
  CheckStatus(FApi.Establish(Context), 'EstablishMonitorContext');
  if Context = 0 then
    raise EPcscError.Create('EstablishMonitorContext', PcscInternalError);
  try
    Watcher := TPcscWatcher.Create(FApi, FReaderName, Context);
  except
    FApi.Release(Context);
    raise;
  end;
  try
    Watcher.StartWatching;
  except
    Watcher.Free;
    raise;
  end;
  FWatcher := Watcher;
end;

procedure TSmartCardReader.StopMonitoring;
var
  Watcher: TThread;
begin
  Watcher := FWatcher;
  FWatcher := nil;
  Watcher.Free;
  FreeAndNil(FEventMonitor);
end;

function TSmartCardReader.PollChanges(out ASnapshot
  : TPcscReaderSnapshot): Boolean;
var
  Status: Cardinal;
begin
  ASnapshot := Default (TPcscReaderSnapshot);
  Result := False;
  if FWatcher = nil then
    Exit;
  if not TPcscWatcher(FWatcher).Take(ASnapshot, Status) then
    Exit;
  if Status <> PcscSuccess then
  begin
    StopMonitoring;
    raise EPcscError.Create('MonitorReader', Status);
  end;
  Result := True;
  // Event dispatch is last: a handler may stop monitoring or free the component.
  if Assigned(FOnCardStateChange) then
    FOnCardStateChange(Self, ASnapshot);
end;

end.
