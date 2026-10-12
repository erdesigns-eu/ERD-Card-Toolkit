unit ERD.Card.Session;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Transport;

type
  /// <summary>Reader reservation, thread ownership or invalidated-session failure.</summary>
  ECardSessionError = class(Exception);
  /// <summary>Exclusive application reservation; protocol transactions remain separate.</summary>
  ICardSessionLease = interface
    ['{861E686D-8B63-4D4F-A722-50636750B8EC}']
    /// <summary>Returns a generation-checked transport restricted to the acquiring thread.</summary>
    /// <returns>Retained transport; becomes unusable after Close, card change or detach.</returns>
    function Transport: ICardTransport;
    /// <summary>Releases the application reservation; safe to repeat on its owner thread.</summary>
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
    Generation, Reservation: Int64;
    Busy: Boolean;
  end;
  IRegistry = interface
    ['{3B81A3F4-B8B2-4EEA-9991-F678FB54F807}']
    procedure Bind(const Id: string; const Backend: ICardTransport);
    procedure Invalidate(const Id: string; const Remove: Boolean);
    procedure Disable;
    function List: TStringList;
    function Reserve(const Id: string): ICardSessionLease;
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
    procedure Bind(const Id: string; const Backend: ICardTransport);
    procedure Invalidate(const Id: string; const Remove: Boolean);
    procedure Disable;
    function List: TStringList;
    function Reserve(const Id: string): ICardSessionLease;
    procedure Check(const Id: string; const Generation: Int64);
    procedure Release(const Id: string; const Generation: Int64);
  end;
  TLease = class(TInterfacedObject, ICardSessionLease, ICardTransport)
  private
    FRegistry: IRegistry;
    FBackend: ICardTransport;
    FTransaction: ICardTransaction;
    FId: string;
    FGeneration: Int64;
    FThread: NativeUInt;
    FClosed, FInCall, FInTransaction: Boolean;
    procedure CheckThread;
    procedure Check;
  public
    constructor Create(const Registry: IRegistry; const Id: string;
      const Generation: Int64; const Backend: ICardTransport);
    destructor Destroy; override;
    function Transport: ICardTransport;
    procedure Close;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

  TTransactionLease = class(TLease, ICardTransaction)
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

procedure TRegistry.Bind(const Id: string; const Backend: ICardTransport);
var I, J: Integer;
begin
  if (Length(Id)<1) or (Length(Id)>1024) or (Backend=nil) then Invalid;
  Enter;
  try
    if not FEnabled or (FGeneration=High(Int64)) then Invalid;
    I := Index(Id);
    if (I>=0) and FItems[I].Busy then Invalid;
    for J := 0 to High(FItems) do
      if (J<>I) and (FItems[J].Backend=Backend) then Invalid;
    if I<0 then begin
      if Length(FItems)>=256 then Invalid;
      I := Length(FItems); SetLength(FItems,I+1); FItems[I].Id := Id;
    end;
    Inc(FGeneration); FItems[I].Generation := FGeneration;
    FItems[I].Backend := Backend; FItems[I].Busy := False;
  finally Leave; end;
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
      FItems[I].Backend := nil;
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
    for I := 0 to High(FItems) do if FItems[I].Backend<>nil then Result.Add(FItems[I].Id);
  finally Leave; end;
end;

function TRegistry.Reserve(const Id: string): ICardSessionLease;
var I: Integer; Tx: ICardTransaction;
begin
  Result := nil;
  Enter;
  try
    I := Index(Id);
    if not FEnabled or (I<0) then Invalid;
    if FItems[I].Busy or (FItems[I].Backend=nil) then Invalid;
    if Supports(FItems[I].Backend,ICardTransaction,Tx) then
      Result := TTransactionLease.Create(Self,Id,FItems[I].Generation,FItems[I].Backend)
    else Result := TLease.Create(Self,Id,FItems[I].Generation,FItems[I].Backend);
    FItems[I].Busy := True; FItems[I].Reservation := FItems[I].Generation;
  finally Leave; end;
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
      if FItems[I].Backend=nil then begin
        for J := I to High(FItems)-1 do FItems[J] := FItems[J+1];
        SetLength(FItems,Length(FItems)-1);
      end;
    end;
  finally Leave; end;
end;

constructor TLease.Create(const Registry: IRegistry; const Id: string;
  const Generation: Int64; const Backend: ICardTransport);
begin
  inherited Create;
  FRegistry := Registry; FId := Id; FGeneration := Generation; FBackend := Backend;
  FThread := NativeUInt(TThread.CurrentThread.ThreadID);
end;

destructor TLease.Destroy;
begin
  if not FClosed and not FInTransaction then FRegistry.Release(FId,FGeneration);
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
  FClosed := True; FRegistry.Release(FId,FGeneration); FBackend := nil;
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
  (FRegistry as IRegistry).Disable; FRegistry := nil; inherited Destroy;
end;

procedure TCardSessionManager.BindReader(const AReaderId: string; const ATransport: ICardTransport);
begin
  (FRegistry as IRegistry).Bind(AReaderId,ATransport);
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

end.
