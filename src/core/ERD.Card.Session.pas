unit ERD.Card.Session;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Transport;

type
  /// <summary>Reader reservation, thread ownership or invalidated-session failure.</summary>
  ECardSessionError = class(Exception);
  /// <summary>Lazy reader connection, opened and closed on the lease owner thread.</summary>
  ICardSessionConnection = interface
    ['{A0E756A4-79A2-4E3E-9925-A7858CC18D56}']
    /// <summary>Opens once without replay, card reset or implicit protocol transaction.</summary>
    /// <returns>Non-nil retained connected transport.</returns>
    function Open: ICardTransport;
    /// <summary>Closes the owned connection once; failures propagate and invalidate its registration.</summary>
    procedure Close;
  end;
  /// <summary>Owner-thread generation guard for typed non-APDU device adapters.</summary>
  ICardResourceGuard = interface
    ['{07EEFD41-81D6-472E-8B02-2C879D620850}']
    /// <summary>Checks generation, ownership and idle state before one native call.</summary>
    procedure BeginCall;
    /// <summary>Ends a dispatched call and checks generation before exposing its result.</summary>
    procedure EndCall;
    /// <summary>Clears the in-call flag after a native exception, preserving that primary exception.</summary>
    procedure CancelCall;
  end;
  /// <summary>Lazy typed resource provider; Open must return a wrapper using the supplied guard for every I/O.</summary>
  ICardResourceConnection = interface
    ['{A72A6FE3-E0B1-4DFC-82DC-85814BC4632E}']
    /// <summary>Opens on the lease thread; cleans partial acquisition itself on failure.</summary>
    /// <param name="AGuard">Retained guard used before/after device calls; do not invoke card commands in Open.</param>
    /// <returns>Guarded typed interface, never a fabricated APDU transport.</returns>
    function Open(const AGuard: ICardResourceGuard): IInterface;
    /// <summary>Returns a stable retained backend identity without I/O, for rejecting duplicate device aliases.</summary>
    /// <returns>Non-nil identity; distinct adapters for the same physical reader still require one caller-selected ID.</returns>
    function Identity: IInterface;
    /// <summary>Releases device ownership once on the opening thread.</summary>
    procedure Close;
  end;
  /// <summary>Exclusive typed non-APDU resource reservation in the common reader registry.</summary>
  ICardResourceLease = interface
    ['{7F4AC0D6-2A61-4E1E-B053-AB9F3DB71A03}']
    /// <summary>Returns the guarded device interface; query its actual magstripe/HID capability.</summary>
    /// <returns>Retained adapter, unusable after Close, detach or card change.</returns>
    function Resource: IInterface;
    /// <summary>Releases native resource and registry ownership; refuses in-flight calls.</summary>
    procedure Close;
  end;
  /// <summary>Exclusive application reservation; protocol transactions remain separate.</summary>
  ICardSessionLease = interface
    ['{861E686D-8B63-4D4F-A722-50636750B8EC}']
    /// <summary>Returns a generation-checked transport restricted to the acquiring thread.</summary>
    /// <returns>Retained transport; becomes unusable after Close, card change or detach.</returns>
    function Transport: ICardTransport;
    /// <summary>Releases the application reservation; safe to repeat on its owner thread.</summary>
    procedure Close;
  end;
  /// <summary>Exclusive source/target reader group, acquired completely before any operation runs.</summary>
  /// <remarks>Reservations are atomic; opening connections is sequential and rolled back on failure.
  /// This is not a distributed card transaction: dispatched writes cannot be undone by Close.</remarks>
  ICardSessionGroup = interface
    ['{61295B81-91BC-488F-9A67-C27297A4ACD5}']
    /// <summary>Returns the number of selected readers in caller order.</summary>
    /// <returns>One through sixteen.</returns>
    function Count: Integer;
    /// <summary>Returns one exact reader identifier.</summary>
    /// <param name="AIndex">Zero-based caller-order position.</param>
    /// <returns>Owned identifier text.</returns>
    function ReaderId(const AIndex: Integer): string;
    /// <summary>Returns a guarded member lease; the group owns its release.</summary>
    /// <param name="AIndex">Zero-based caller-order position.</param>
    /// <returns>Retained owner-thread lease; do not close it separately.</returns>
    function Lease(const AIndex: Integer): ICardSessionLease;
    /// <summary>Checks all member generations without sending commands.</summary>
    /// <remarks>Call between workflow phases; every member transport also checks its own generation.</remarks>
    procedure Validate;
    /// <summary>Closes every member in reverse order, continuing after cleanup failures.</summary>
    /// <remarks>Raises on any cleanup failure. An active physical transaction must be ended by its owner first.</remarks>
    procedure Close;
  end;
  /// <summary>Central nonvisual registry and exclusive reservation of connected reader transports.</summary>
  /// <remarks>Bind distinct physical readers under unique IDs; aliases cannot establish physical exclusivity.
  /// Leases run on their acquiring thread. Protocol code still owns Begin/EndTransaction.
  /// Invalidation rejects future I/O and replies to already dispatched I/O; it cannot undo a write.</remarks>
  TCardSessionManager = class(TComponent)
  private
    FRegistry: IInterface;
  public
    /// <summary>Creates an inactive empty reader registry without hardware access.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Invalidates all retained sessions; their backend references survive until released.</summary>
    destructor Destroy; override;
    /// <summary>Registers one already connected backend or replaces its generation.</summary>
    /// <param name="AReaderId">Nonempty stable reader ID, at most 1024 characters.</param>
    /// <param name="ATransport">Connected retained backend; nil is refused.</param>
    /// <remarks>Replacement while reserved is refused. The manager does not connect, reset or retry.</remarks>
    procedure BindReader(const AReaderId: string; const ATransport: ICardTransport);
    /// <summary>Registers a lazy connection provider, copied/retained independently of its configuring component.</summary>
    /// <param name="AReaderId">Exact stable physical reader identifier.</param>
    /// <param name="AConnection">Non-nil provider; Open/Close execute on the acquiring worker.</param>
    /// <remarks>Reserved entries cannot be replaced. Acquisition failure never executes or retries the job.</remarks>
    procedure BindConnection(const AReaderId: string; const AConnection: ICardSessionConnection);
    /// <summary>Registers a reconnected reader, deferring replacement only behind a detached live lease.</summary>
    /// <param name="AReaderId">Physical reader identifier.</param>
    /// <param name="AConnection">Retained fresh lazy provider; never opened until acquired.</param>
    /// <remarks>An active registered connection is never replaced while busy.</remarks>
    procedure BindConnectionWhenIdle(const AReaderId: string; const AConnection: ICardSessionConnection);
    /// <summary>Registers a retained lazy non-APDU provider in the same exclusive reader namespace.</summary>
    /// <param name="AReaderId">Unique physical device identifier.</param>
    /// <param name="AConnection">Guarded typed resource provider; nil and duplicate aliases are refused.</param>
    procedure BindResourceConnection(const AReaderId: string; const AConnection: ICardResourceConnection);
    /// <summary>Stages a reappeared resource behind a detached old lease; no hardware is reopened here.</summary>
    /// <param name="AReaderId">Unique physical resource ID.</param>
    /// <param name="AConnection">Retained fresh guarded resource provider.</param>
    procedure BindResourceConnectionWhenIdle(const AReaderId: string; const AConnection: ICardResourceConnection);
    /// <summary>Reserves and opens one typed device on the caller thread.</summary>
    /// <param name="AReaderId">Registered resource identifier; APDU entries are refused.</param>
    /// <returns>Owned guarded resource lease; close after native workflow completion.</returns>
    function AcquireResource(const AReaderId: string): ICardResourceLease;
    /// <summary>Invalidates a reader and removes it from future reservations.</summary>
    /// <param name="AReaderId">Exact reader ID; absent IDs are harmless.</param>
    procedure DetachReader(const AReaderId: string);
    /// <summary>Invalidates current leases when a card is inserted, removed or replaced.</summary>
    /// <param name="AReaderId">Exact existing reader ID; backend remains registered.</param>
    procedure CardChanged(const AReaderId: string);
    /// <summary>Lists independent currently registered reader IDs.</summary>
    /// <returns>Owned list in registration order; caller frees it.</returns>
    function ReaderIds: TStringList;
    /// <summary>Reserves one registered reader without starting a physical transaction.</summary>
    /// <param name="AReaderId">Exact registered reader ID; concurrent reservations are refused.</param>
    /// <returns>Owned single-thread lease, independent of manager lifetime.</returns>
    function Acquire(const AReaderId: string): ICardSessionLease;
    /// <summary>Atomically reserves all selected readers before opening any lazy connection.</summary>
    /// <param name="AReaderIds">One through sixteen distinct exact registered IDs, in source/target order.</param>
    /// <returns>Owner-thread group; partial opening failure closes opened members and releases all reservations.</returns>
    /// <remarks>No waits, retries, card resets or distributed commit are inferred.</remarks>
    function AcquireMany(const AReaderIds: array of string): ICardSessionGroup;
  end;

implementation

{$IFNDEF FPC}uses System.SyncObjs;{$ENDIF}

type
{$IFDEF FPC}
  TSessionLock = TRTLCriticalSection;
{$ELSE}
  TSessionLock = TCriticalSection;
{$ENDIF}
  TBinding = record
    Id: string;
    Backend: ICardTransport;
    Connection: ICardSessionConnection;
    Resource: ICardResourceConnection;
    PendingConnection: ICardSessionConnection;
    PendingResource: ICardResourceConnection;
    Generation, Reservation: Int64;
    Busy: Boolean;
  end;
  IRegistry = interface
    ['{3B81A3F4-B8B2-4EEA-9991-F678FB54F807}']
    procedure Bind(const Id: string; const Backend: ICardTransport; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
    procedure Invalidate(const Id: string; const Remove: Boolean);
    procedure Disable;
    function List: TStringList;
    function Reserve(const Id: string): ICardSessionLease;
    function ReserveMany(const Ids: array of string): ICardSessionGroup;
    function ReserveResource(const Id: string): ICardResourceLease;
    procedure BindDeferred(const Id: string; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
    procedure Check(const Id: string; const Generation: Int64);
    procedure Release(const Id: string; const Generation: Int64);
  end;
  TRegistry = class(TInterfacedObject, IRegistry)
  private
    FLock: TSessionLock;
    FItems: array of TBinding;
    FGeneration: Int64;
    FEnabled: Boolean;
    procedure Enter;
    procedure Leave;
    function Index(const Id: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Bind(const Id: string; const Backend: ICardTransport; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
    procedure Invalidate(const Id: string; const Remove: Boolean);
    procedure Disable;
    function List: TStringList;
    function Reserve(const Id: string): ICardSessionLease;
    function ReserveMany(const Ids: array of string): ICardSessionGroup;
    function ReserveResource(const Id: string): ICardResourceLease;
    procedure BindDeferred(const Id: string; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
    procedure Check(const Id: string; const Generation: Int64);
    procedure Release(const Id: string; const Generation: Int64);
  end;
  TLease = class(TInterfacedObject, ICardSessionLease, ICardTransport)
  private
    FRegistry: IRegistry;
    FBackend: ICardTransport;
    FConnection: ICardSessionConnection;
    FTransaction: ICardTransaction;
    FId: string;
    FGeneration: Int64;
    FThread: NativeUInt;
    FClosed, FInCall, FInTransaction: Boolean;
    procedure CheckThread;
    procedure Check;
  public
    constructor Create(const Registry: IRegistry; const Id: string;
      const Generation: Int64; const Backend: ICardTransport;
      const Connection: ICardSessionConnection);
    destructor Destroy; override;
    function Transport: ICardTransport;
    procedure Close;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

  TTransactionLease = class(TLease, ICardTransaction)
  end;

  TGroup = class(TInterfacedObject, ICardSessionGroup)
  private
    FIds: array of string;
    FLeases: array of ICardSessionLease;
    FThread: NativeUInt;
    FClosed: Boolean;
    procedure CheckThread;
  public
    constructor Create(const Ids: array of string);
    destructor Destroy; override;
    function Count: Integer;
    function ReaderId(const AIndex: Integer): string;
    function Lease(const AIndex: Integer): ICardSessionLease;
    procedure Validate;
    procedure Close;
  end;

  TResourceGuard = class(TInterfacedObject, ICardResourceGuard)
  public
    Registry: IRegistry;
    Id: string;
    Generation: Int64;
    Thread: NativeUInt;
    Closed, InCall: Boolean;
    procedure Check;
    procedure BeginCall;
    procedure EndCall;
    procedure CancelCall;
  end;
  TResourceLease = class(TInterfacedObject, ICardResourceLease)
  public
    Guard: TResourceGuard;
    RetainedGuard: ICardResourceGuard;
    Device: IInterface;
    Connection: ICardResourceConnection;
    destructor Destroy; override;
    function Resource: IInterface;
    procedure Close;
  end;

procedure Invalid;
begin
  raise ECardSessionError.Create('Reader session is unavailable or invalid.');
end;

constructor TRegistry.Create;
begin
  inherited Create;
{$IFDEF FPC}InitCriticalSection(FLock);{$ELSE}FLock := TCriticalSection.Create;{$ENDIF}
  FEnabled := True;
end;

destructor TRegistry.Destroy;
begin
{$IFDEF FPC}DoneCriticalSection(FLock);{$ELSE}FLock.Free;{$ENDIF}
  inherited Destroy;
end;

procedure TRegistry.Enter;
begin
{$IFDEF FPC}EnterCriticalSection(FLock);{$ELSE}FLock.Enter;{$ENDIF}
end;

procedure TRegistry.Leave;
begin
{$IFDEF FPC}LeaveCriticalSection(FLock);{$ELSE}FLock.Leave;{$ENDIF}
end;

function TRegistry.Index(const Id: string): Integer;
begin
  for Result := 0 to High(FItems) do if FItems[Result].Id = Id then Exit;
  Result := -1;
end;

procedure TRegistry.Bind(const Id: string; const Backend: ICardTransport; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
var I, J: Integer;
begin
  if (Length(Id)<1) or (Length(Id)>1024) then Invalid;
  if Ord(Backend<>nil)+Ord(Connection<>nil)+Ord(Resource<>nil)<>1 then Invalid;
  if (Resource<>nil) and (Resource.Identity=nil) then Invalid;
  Enter;
  try
    if not FEnabled or (FGeneration=High(Int64)) then Invalid;
    I := Index(Id);
    if (I>=0) and FItems[I].Busy then Invalid;
    for J := 0 to High(FItems) do
      if (J<>I) and (((Backend<>nil) and (FItems[J].Backend=Backend)) or
        ((Connection<>nil) and ((FItems[J].Connection=Connection) or (FItems[J].PendingConnection=Connection))) or
        ((Resource<>nil) and (FItems[J].Resource=Resource))) then Invalid;
    if Resource<>nil then for J := 0 to High(FItems) do if J<>I then begin
      if (FItems[J].Resource<>nil) and (FItems[J].Resource.Identity=Resource.Identity) then Invalid;
      if (FItems[J].PendingResource<>nil) and (FItems[J].PendingResource.Identity=Resource.Identity) then Invalid;
    end;
    if I<0 then begin
      if Length(FItems)>=256 then Invalid;
      I := Length(FItems); SetLength(FItems,I+1); FItems[I].Id := Id;
    end;
    Inc(FGeneration); FItems[I].Generation := FGeneration;
    FItems[I].Backend := Backend; FItems[I].Connection := Connection; FItems[I].Resource := Resource; FItems[I].PendingConnection := nil; FItems[I].PendingResource := nil; FItems[I].Busy := False;
  finally Leave; end;
end;

procedure TRegistry.BindDeferred(const Id: string; const Connection: ICardSessionConnection; const Resource: ICardResourceConnection);
var I,J: Integer; Deferred: Boolean;
begin
  if (Length(Id)<1) or (Length(Id)>1024) or ((Connection=nil)=(Resource=nil)) then Invalid;
  Deferred := False; Enter;
  try
    if not FEnabled then Invalid;
    I := Index(Id);
    if (I>=0) and FItems[I].Busy then begin
      if (FItems[I].Backend<>nil) or (FItems[I].Connection<>nil) or (FItems[I].Resource<>nil) then Invalid;
      for J := 0 to High(FItems) do if (J<>I) and
        (((Connection<>nil) and ((FItems[J].Connection=Connection) or (FItems[J].PendingConnection=Connection))) or
        ((Resource<>nil) and ((FItems[J].Resource=Resource) or (FItems[J].PendingResource=Resource)))) then Invalid;
      if Resource<>nil then begin
        if Resource.Identity=nil then Invalid;
        for J := 0 to High(FItems) do if J<>I then begin
          if (FItems[J].Resource<>nil) and (FItems[J].Resource.Identity=Resource.Identity) then Invalid;
          if (FItems[J].PendingResource<>nil) and (FItems[J].PendingResource.Identity=Resource.Identity) then Invalid;
        end;
      end;
      FItems[I].PendingConnection := Connection; FItems[I].PendingResource := Resource; Deferred := True;
    end;
  finally Leave; end;
  if not Deferred then Bind(Id,nil,Connection,Resource);
end;

procedure TRegistry.Invalidate(const Id: string; const Remove: Boolean);
var I, J: Integer;
begin
  Enter;
  try
    I := Index(Id); if I<0 then Exit;
    if FGeneration=High(Int64) then Invalid;
    Inc(FGeneration); FItems[I].Generation := FGeneration;
    // Retain a live reservation until its lease releases; do not overlap old I/O.
    if Remove then begin
      FItems[I].Backend := nil; FItems[I].Connection := nil; FItems[I].Resource := nil; FItems[I].PendingConnection := nil; FItems[I].PendingResource := nil;
      if not FItems[I].Busy then begin
        for J := I to High(FItems)-1 do FItems[J] := FItems[J+1];
        SetLength(FItems,Length(FItems)-1);
      end;
    end;
  finally Leave; end;
end;

procedure TRegistry.Disable;
begin
  Enter;
  try FEnabled := False; finally Leave; end;
end;

function TRegistry.List: TStringList;
var I: Integer;
begin
  Result := TStringList.Create;
  Enter;
  try
    for I := 0 to High(FItems) do if (FItems[I].Backend<>nil) or (FItems[I].Connection<>nil) or (FItems[I].Resource<>nil) or (FItems[I].PendingConnection<>nil) or (FItems[I].PendingResource<>nil) then Result.Add(FItems[I].Id);
  finally Leave; end;
end;

procedure TResourceGuard.Check;
begin
  if (NativeUInt(TThread.CurrentThread.ThreadID)<>Thread) or Closed or InCall then Invalid;
  Registry.Check(Id,Generation);
end;
procedure TResourceGuard.BeginCall;
begin Check; InCall := True; end;
procedure TResourceGuard.EndCall;
begin
  if (NativeUInt(TThread.CurrentThread.ThreadID)<>Thread) or not InCall then Invalid;
  InCall := False; Check;
end;
procedure TResourceGuard.CancelCall;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>Thread then Invalid;
  InCall := False;
end;
function TResourceLease.Resource: IInterface;
begin Guard.Check; Result := Device; end;
procedure TResourceLease.Close;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>Guard.Thread then Invalid;
  if Guard.Closed then Exit;
  if Guard.InCall then Invalid;
  Guard.Closed := True;
  try
    try Connection.Close; except Guard.Registry.Invalidate(Guard.Id,True); raise; end;
  finally
    Guard.Registry.Release(Guard.Id,Guard.Generation); Device := nil; Connection := nil;
  end;
end;
destructor TResourceLease.Destroy;
begin
  if (Guard<>nil) and not Guard.Closed then
    if NativeUInt(TThread.CurrentThread.ThreadID)=Guard.Thread then
      try Close; except end
    else begin Guard.Closed := True; Guard.Registry.Invalidate(Guard.Id,True); end;
  inherited Destroy;
end;
function TRegistry.ReserveResource(const Id: string): ICardResourceLease;
var I: Integer; Connection: ICardResourceConnection; Generation: Int64;
  Guard: TResourceGuard; KeepGuard: ICardResourceGuard; Lease: TResourceLease;
  KeepLease: ICardResourceLease; Device: IInterface; Opened: Boolean;
begin
  Result := nil; Opened := False;
  Enter;
  try
    I := Index(Id); if not FEnabled or (I<0) then Invalid;
    if FItems[I].Busy or (FItems[I].Resource=nil) then Invalid;
    Connection := FItems[I].Resource; Generation := FItems[I].Generation;
    FItems[I].Busy := True; FItems[I].Reservation := Generation;
  finally Leave; end;
  try
    Guard := TResourceGuard.Create; KeepGuard := Guard;
    Guard.Registry := Self; Guard.Id := Id; Guard.Generation := Generation;
    Guard.Thread := NativeUInt(TThread.CurrentThread.ThreadID);
    Device := Connection.Open(KeepGuard); Opened := True;
    if Device=nil then Invalid;
    Guard.Check;
    Lease := TResourceLease.Create; KeepLease := Lease;
    Lease.Guard := Guard; Lease.RetainedGuard := KeepGuard;
    Lease.Device := Device; Lease.Connection := Connection; Result := KeepLease;
  except
    if KeepGuard<>nil then Guard.Closed := True;
    try if Opened then Connection.Close;
    finally Invalidate(Id,True); Release(Id,Generation); end;
    raise;
  end;
end;

constructor TGroup.Create(const Ids: array of string);
var I: Integer;
begin
  inherited Create;
  FThread := NativeUInt(TThread.CurrentThread.ThreadID);
  SetLength(FIds,Length(Ids)); SetLength(FLeases,Length(Ids));
  for I := 0 to High(Ids) do FIds[I] := Ids[I];
end;

destructor TGroup.Destroy;
begin
  if not FClosed and (NativeUInt(TThread.CurrentThread.ThreadID)=FThread) then
    try Close; except end;
  inherited Destroy;
end;

procedure TGroup.CheckThread;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>FThread then Invalid;
end;

function TGroup.Count: Integer;
begin
  CheckThread; Result := Length(FIds);
end;

function TGroup.ReaderId(const AIndex: Integer): string;
begin
  CheckThread;
  if (AIndex<0) or (AIndex>=Length(FIds)) then Invalid;
  Result := FIds[AIndex];
end;

function TGroup.Lease(const AIndex: Integer): ICardSessionLease;
begin
  Validate;
  if (AIndex<0) or (AIndex>=Length(FLeases)) then Invalid;
  Result := FLeases[AIndex];
end;

procedure TGroup.Validate;
var I: Integer; Transport: ICardTransport;
begin
  CheckThread; if FClosed then Invalid;
  for I := 0 to High(FLeases) do begin
    if FLeases[I]=nil then Invalid;
    Transport := FLeases[I].Transport;
    if Transport=nil then Invalid;
  end;
end;

procedure TGroup.Close;
var I: Integer; Failed: Boolean;
begin
  CheckThread; if FClosed then Exit;
  Failed := False;
  for I := High(FLeases) downto 0 do if FLeases[I]<>nil then
    try FLeases[I].Close; FLeases[I] := nil;
    except Failed := True; end;
  // Retain failed members so an owner can end a transaction and retry cleanup.
  FClosed := not Failed;
  if Failed then raise ECardSessionError.Create('Reader group cleanup failed.');
end;

function TRegistry.Reserve(const Id: string): ICardSessionLease;
var Group: ICardSessionGroup; Ids: array[0..0] of string;
begin
  Ids[0] := Id; Group := ReserveMany(Ids);
  Result := Group.Lease(0);
  // Transfer the sole member without releasing its reservation.
  (Group as TGroup).FLeases[0] := nil;
  (Group as TGroup).FClosed := True;
end;

function TRegistry.ReserveMany(const Ids: array of string): ICardSessionGroup;
var I, J, K: Integer; Bindings: array of TBinding; Group: TGroup;
  Retained: ICardSessionGroup; Backend: ICardTransport; Tx: ICardTransaction; Opened: Boolean;
begin
  Result := nil;
  if (Length(Ids)<1) or (Length(Ids)>16) then Invalid;
  for I := 0 to High(Ids) do begin
    if (Length(Ids[I])<1) or (Length(Ids[I])>1024) then Invalid;
    for J := 0 to I-1 do if Ids[I]=Ids[J] then Invalid;
  end;
  Group := TGroup.Create(Ids); Retained := Group;
  SetLength(Bindings,Length(Ids));
  Enter;
  try
    if not FEnabled then Invalid;
    // Validate every member before changing any Busy flag.
    for I := 0 to High(Ids) do begin
      K := Index(Ids[I]); if K<0 then Invalid;
      if FItems[K].Busy or ((FItems[K].Backend=nil) and (FItems[K].Connection=nil)) then Invalid;
      Bindings[I] := FItems[K];
    end;
    for I := 0 to High(Ids) do begin
      K := Index(Ids[I]); FItems[K].Busy := True;
      FItems[K].Reservation := FItems[K].Generation;
    end;
  finally Leave; end;
  try
    for I := 0 to High(Ids) do begin
      Backend := Bindings[I].Backend; Opened := False;
      try
        if Bindings[I].Connection<>nil then begin
          Backend := Bindings[I].Connection.Open; Opened := True;
          if Backend=nil then Invalid;
        end;
        Check(Ids[I],Bindings[I].Generation);
        if Supports(Backend,ICardTransaction,Tx) then
          Group.FLeases[I] := TTransactionLease.Create(Self,Ids[I],Bindings[I].Generation,Backend,Bindings[I].Connection)
        else Group.FLeases[I] := TLease.Create(Self,Ids[I],Bindings[I].Generation,Backend,Bindings[I].Connection);
      except
        try if Opened then Bindings[I].Connection.Close;
        finally Invalidate(Ids[I],True); end;
        raise;
      end;
    end;
    Group.Validate; Result := Retained;
  except
    // Every reservation is released, even when another member's Close raises.
    for J := High(Ids) downto 0 do begin
      if Group.FLeases[J]<>nil then
        try Group.FLeases[J].Close; except end;
      Release(Ids[J],Bindings[J].Generation);
    end;
    Group.FClosed := True;
    raise;
  end;
end;

procedure TRegistry.Check(const Id: string; const Generation: Int64);
var I: Integer;
begin
  Enter;
  try
    I := Index(Id);
    if not FEnabled or (I<0) then Invalid;
    if not FItems[I].Busy or (FItems[I].Generation<>Generation) then Invalid;
  finally Leave; end;
end;

procedure TRegistry.Release(const Id: string; const Generation: Int64);
var I, J: Integer;
begin
  Enter;
  try
    I := Index(Id);
    if (I>=0) and (FItems[I].Reservation=Generation) then begin
      FItems[I].Busy := False;
      if FItems[I].PendingConnection<>nil then begin
        FItems[I].Connection := FItems[I].PendingConnection; FItems[I].PendingConnection := nil;
      end;
      if FItems[I].PendingResource<>nil then begin
        FItems[I].Resource := FItems[I].PendingResource; FItems[I].PendingResource := nil;
      end;
      if (FItems[I].Backend=nil) and (FItems[I].Connection=nil) and (FItems[I].Resource=nil) then begin
        for J := I to High(FItems)-1 do FItems[J] := FItems[J+1];
        SetLength(FItems,Length(FItems)-1);
      end;
    end;
  finally Leave; end;
end;

constructor TLease.Create(const Registry: IRegistry; const Id: string;
  const Generation: Int64; const Backend: ICardTransport;
  const Connection: ICardSessionConnection);
begin
  inherited Create;
  FConnection := Connection; FRegistry := Registry; FId := Id; FGeneration := Generation; FBackend := Backend;
  FThread := NativeUInt(TThread.CurrentThread.ThreadID);
end;

destructor TLease.Destroy;
begin
  if not FClosed then begin
    if not FInTransaction and (NativeUInt(TThread.CurrentThread.ThreadID)=FThread) then
      try Close; except end
    else FRegistry.Invalidate(FId,True);
  end;
  inherited Destroy;
end;

procedure TLease.CheckThread;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>FThread then Invalid;
end;

procedure TLease.Check;
begin
  CheckThread;
  if FClosed or FInCall then Invalid;
  FRegistry.Check(FId,FGeneration);
end;

function TLease.Transport: ICardTransport;
begin
  Check; Result := Self;
end;

procedure TLease.Close;
begin
  CheckThread;
  if FClosed then Exit;
  if FInCall or FInTransaction then Invalid;
  FClosed := True;
  try
    if FConnection<>nil then
      try FConnection.Close;
      except FRegistry.Invalidate(FId,True); raise; end;
  finally
    FRegistry.Release(FId,FGeneration); FBackend := nil; FConnection := nil;
  end;
end;

function TLease.Exchange(const ACommand: TBytes): TBytes;
begin
  Check;
  if (Length(ACommand)<1) or (Length(ACommand)>CardMaxCommandBytes) then Invalid;
  FInCall := True;
  try
    Result := FBackend.Exchange(ACommand);
    if (Length(Result)<2) or (Length(Result)>CardMaxResponseBytes) then Invalid;
    FRegistry.Check(FId,FGeneration);
  finally FInCall := False; end;
end;

procedure TLease.BeginTransaction;
begin
  Check;
  if FInTransaction or not Supports(FBackend,ICardTransaction,FTransaction) then Invalid;
  FInCall := True;
  try
    try FTransaction.BeginTransaction; FInTransaction := True;
    except FRegistry.Invalidate(FId,True); raise; end;
  finally FInCall := False; end;
  try FRegistry.Check(FId,FGeneration);
  except EndTransaction; raise; end;
end;

procedure TLease.EndTransaction;
begin
  CheckThread;
  if not FInTransaction or FInCall then Invalid;
  FInCall := True;
  try
    try FTransaction.EndTransaction;
    except FRegistry.Invalidate(FId,True); raise; end;
  finally FInTransaction := False; FInCall := False; FTransaction := nil; end;
end;

constructor TCardSessionManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FRegistry := TRegistry.Create;
end;

destructor TCardSessionManager.Destroy;
begin
  inherited Destroy; (FRegistry as IRegistry).Disable; FRegistry := nil;
end;

procedure TCardSessionManager.BindReader(const AReaderId: string; const ATransport: ICardTransport);
begin
  (FRegistry as IRegistry).Bind(AReaderId,ATransport,nil,nil);
end;

procedure TCardSessionManager.BindConnection(const AReaderId: string; const AConnection: ICardSessionConnection);
begin
  (FRegistry as IRegistry).Bind(AReaderId,nil,AConnection,nil);
end;

procedure TCardSessionManager.DetachReader(const AReaderId: string);
begin
  (FRegistry as IRegistry).Invalidate(AReaderId,True);
end;

procedure TCardSessionManager.CardChanged(const AReaderId: string);
begin
  (FRegistry as IRegistry).Invalidate(AReaderId,False);
end;

function TCardSessionManager.ReaderIds: TStringList;
begin
  Result := (FRegistry as IRegistry).List;
end;

function TCardSessionManager.Acquire(const AReaderId: string): ICardSessionLease;
begin
  Result := (FRegistry as IRegistry).Reserve(AReaderId);
end;

function TCardSessionManager.AcquireMany(const AReaderIds: array of string): ICardSessionGroup;
begin
  Result := (FRegistry as IRegistry).ReserveMany(AReaderIds);
end;

procedure TCardSessionManager.BindResourceConnection(const AReaderId: string;
  const AConnection: ICardResourceConnection);
begin (FRegistry as IRegistry).Bind(AReaderId,nil,nil,AConnection); end;
function TCardSessionManager.AcquireResource(const AReaderId: string): ICardResourceLease;
begin Result := (FRegistry as IRegistry).ReserveResource(AReaderId); end;

procedure TCardSessionManager.BindConnectionWhenIdle(const AReaderId: string;
  const AConnection: ICardSessionConnection);
begin (FRegistry as IRegistry).BindDeferred(AReaderId,AConnection,nil); end;

procedure TCardSessionManager.BindResourceConnectionWhenIdle(const AReaderId: string;
  const AConnection: ICardResourceConnection);
begin (FRegistry as IRegistry).BindDeferred(AReaderId,nil,AConnection); end;

end.
