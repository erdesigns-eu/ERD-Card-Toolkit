unit ERD.Card.PCSC.Registry;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes, SysUtils,{$ELSE}System.Classes, System.SysUtils,{$ENDIF}
  ERD.Card.Session, ERD.Card.PCSC.Api, ERD.Card.PCSC.Monitor, ERD.Card.PCSC.Session;
type
  /// <summary>Inactive event-driven PC/SC inventory binding, owning its monitor without taking application handlers.</summary>
  /// <remarks>Main-thread lifecycle/observations. Reader IDs are exact names prefixed with pcsc:.
  /// Usage-only state changes do not invalidate jobs. Stop detaches only registered inventory members.</remarks>
  TCardPcscSessionRegistry = class(TComponent)
  private
    FMonitor: TSmartCardMonitor;
    FProvider: TCardPcscSessionProvider;
    FManager: TCardSessionManager;
    FSnapshots: array of TPcscReaderSnapshot;
    FOnReaderAdded,FOnReaderRemoved: TPcscReaderEvent;
    FOnCardChanged: TPcscCardEvent;
    FOnError: TPcscMonitorErrorEvent;
    procedure SetManager(const Value: TCardSessionManager);
    procedure Added(Sender: TObject; const Name: UnicodeString);
    procedure Removed(Sender: TObject; const Name: UnicodeString);
    procedure Changed(Sender: TObject; const Snapshot: TPcscReaderSnapshot);
    procedure CardRemoved(Sender: TObject; const Snapshot: TPcscReaderSnapshot);
    procedure Failed(Sender: TObject; const Status: Cardinal);
    function Index(const Name: UnicodeString): Integer;
    procedure Initialize(const Api: IPcscApi);
  protected
    /// <summary>Stops observation before a bound manager is removed.</summary>
    /// <param name="AComponent">Removed dependency.</param>
    /// <param name="Operation">Component notification kind.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Constructs an inactive native monitor/provider pair.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Constructs an inactive pair with injectable thread-safe PC/SC API.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    /// <param name="AApi">Non-nil injected adapter.</param>
    constructor CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
    /// <summary>Stops/joins monitoring and detaches owned inventory before destruction.</summary>
    destructor Destroy; override;
    /// <summary>Starts native PnP/status waits with initial reader/card enumeration.</summary>
    procedure Start;
    /// <summary>Stops observation and invalidates all inventory registrations.</summary>
    procedure Stop;
    /// <summary>Applies one exact reader arrival; also usable by an external inventory driver.</summary>
    /// <param name="AName">Exact Unicode reader name; registers pcsc: plus this name.</param>
    procedure ObserveReaderAdded(const AName: UnicodeString);
    /// <summary>Applies removal and invalidates old leases before a subsequent reappearance.</summary>
    /// <param name="AName">Exact known reader identity.</param>
    procedure ObserveReaderRemoved(const AName: UnicodeString);
    /// <summary>Applies presence/ATR/availability evidence, ignoring usage-only changes.</summary>
    /// <param name="ASnapshot">Owned native snapshot; connection is never opened here.</param>
    procedure ObserveState(const ASnapshot: TPcscReaderSnapshot);
  published
    /// <summary>Shared session registry; change only while monitoring is inactive and inventory is empty.</summary>
    property Manager: TCardSessionManager read FManager write SetManager;
    /// <summary>Arrival after lazy provider registration; callback belongs to the main thread.</summary>
    property OnReaderAdded: TPcscReaderEvent read FOnReaderAdded write FOnReaderAdded;
    /// <summary>Removal after session invalidation.</summary>
    property OnReaderRemoved: TPcscReaderEvent read FOnReaderRemoved write FOnReaderRemoved;
    /// <summary>Relevant card/availability change after generation invalidation.</summary>
    property OnCardChanged: TPcscCardEvent read FOnCardChanged write FOnCardChanged;
    /// <summary>Terminal monitor failure after owned registrations are detached.</summary>
    property OnError: TPcscMonitorErrorEvent read FOnError write FOnError;
  end;
implementation
uses ERD.Card.Bytes;
procedure RequireMain;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>NativeUInt(MainThreadID) then
    raise ECardSessionError.Create('Inventory lifecycle belongs to the main thread.');
end;
procedure TCardPcscSessionRegistry.Initialize(const Api: IPcscApi);
begin
  if Api=nil then begin FMonitor := TSmartCardMonitor.Create(Self); FProvider := TCardPcscSessionProvider.Create(Self); end
  else begin FMonitor := TSmartCardMonitor.CreateWithApi(Self,Api); FProvider := TCardPcscSessionProvider.CreateWithApi(Self,Api); end;
  FMonitor.OnReaderAdded := Added; FMonitor.OnReaderRemoved := Removed;
  FMonitor.OnCardInserted := Changed; FMonitor.OnCardRemoved := CardRemoved;
  FMonitor.OnStateChanged := Changed; FMonitor.OnError := Failed;
end;
constructor TCardPcscSessionRegistry.Create(AOwner: TComponent);
begin inherited Create(AOwner); Initialize(nil); end;
constructor TCardPcscSessionRegistry.CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
begin
  inherited Create(AOwner);
  if AApi=nil then raise ECardSessionError.Create('A PC/SC API is required.');
  Initialize(AApi);
end;
destructor TCardPcscSessionRegistry.Destroy;
begin Stop; inherited Destroy; end;
procedure TCardPcscSessionRegistry.SetManager(const Value: TCardSessionManager);
begin
  RequireMain;
  if FMonitor.Active or (Length(FSnapshots)<>0) then raise ECardSessionError.Create('Stop inventory before replacing its manager.');
  if FManager<>nil then FManager.RemoveFreeNotification(Self);
  FManager := Value; if Value<>nil then Value.FreeNotification(Self);
end;
procedure TCardPcscSessionRegistry.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation=opRemove) and (AComponent=FManager) then begin Stop; FManager := nil; end;
  inherited Notification(AComponent,Operation);
end;
function TCardPcscSessionRegistry.Index(const Name: UnicodeString): Integer;
begin
  for Result := 0 to High(FSnapshots) do if FSnapshots[Result].ReaderName=Name then Exit;
  Result := -1;
end;
procedure TCardPcscSessionRegistry.Start;
begin
  RequireMain;
  if FManager=nil then raise ECardSessionError.Create('A session manager is required.');
  FMonitor.Start;
end;
procedure TCardPcscSessionRegistry.Stop;
var I: Integer;
begin
  RequireMain;
  if FMonitor<>nil then FMonitor.Stop;
  if FManager<>nil then for I := 0 to High(FSnapshots) do FManager.DetachReader('pcsc:'+string(FSnapshots[I].ReaderName));
  FSnapshots := nil;
end;
procedure TCardPcscSessionRegistry.ObserveReaderAdded(const AName: UnicodeString);
var I: Integer;
begin
  RequireMain;
  if FManager=nil then raise ECardSessionError.Create('A session manager is required.');
  if Index(AName)>=0 then Exit;
  if Length(FSnapshots)>=256 then raise ECardSessionError.Create('Inventory budget exceeded.');
  FProvider.ReaderName := AName;
  FManager.BindConnectionWhenIdle('pcsc:'+string(AName),FProvider.CreateConnection);
  I := Length(FSnapshots); SetLength(FSnapshots,I+1); FSnapshots[I].ReaderName := AName;
  if Assigned(FOnReaderAdded) then FOnReaderAdded(Self,AName);
end;
procedure TCardPcscSessionRegistry.ObserveReaderRemoved(const AName: UnicodeString);
var I,J: Integer;
begin
  RequireMain; I := Index(AName); if I<0 then Exit;
  FManager.DetachReader('pcsc:'+string(AName));
  for J := I to High(FSnapshots)-1 do FSnapshots[J] := FSnapshots[J+1];
  SetLength(FSnapshots,Length(FSnapshots)-1);
  if Assigned(FOnReaderRemoved) then FOnReaderRemoved(Self,AName);
end;
procedure TCardPcscSessionRegistry.ObserveState(const ASnapshot: TPcscReaderSnapshot);
var Relevant: Cardinal; I: Integer; ChangedState: Boolean;
begin
  RequireMain;
  Relevant := PcscStateUnknown or PcscStateUnavailable or PcscStateEmpty or PcscStatePresent or PcscStateMute;
  I := Index(ASnapshot.ReaderName);
  if I<0 then Exit;
  ChangedState := ((FSnapshots[I].State and Relevant)<>(ASnapshot.State and Relevant)) or
    not BytesEqual(FSnapshots[I].Atr,ASnapshot.Atr);
  FSnapshots[I] := ASnapshot; FSnapshots[I].Atr := CopyBytes(ASnapshot.Atr);
  if ChangedState then begin
    FManager.CardChanged('pcsc:'+string(ASnapshot.ReaderName));
    if Assigned(FOnCardChanged) then FOnCardChanged(Self,ASnapshot);
  end;
end;
procedure TCardPcscSessionRegistry.Added(Sender: TObject; const Name: UnicodeString);
begin ObserveReaderAdded(Name); end;
procedure TCardPcscSessionRegistry.Removed(Sender: TObject; const Name: UnicodeString);
begin ObserveReaderRemoved(Name); end;
procedure TCardPcscSessionRegistry.Changed(Sender: TObject; const Snapshot: TPcscReaderSnapshot);
begin ObserveState(Snapshot); end;
procedure TCardPcscSessionRegistry.CardRemoved(Sender: TObject; const Snapshot: TPcscReaderSnapshot);
var Current: TPcscReaderSnapshot;
begin
  Current := Snapshot; Current.State := (Current.State and not PcscStatePresent) or PcscStateEmpty;
  Current.Atr := nil; ObserveState(Current);
end;
procedure TCardPcscSessionRegistry.Failed(Sender: TObject; const Status: Cardinal);
var Handler: TPcscMonitorErrorEvent;
begin
  Handler := FOnError; Stop;
  if Assigned(Handler) then Handler(Self,Status);
end;
end.
