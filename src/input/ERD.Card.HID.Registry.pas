unit ERD.Card.HID.Registry;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes, SysUtils,{$ELSE}System.Classes, System.SysUtils,{$ENDIF}
  ERD.Card.HID, ERD.Card.HID.Monitor, ERD.Card.HID.Session, ERD.Card.Session;
type
  /// <summary>Explicit lazy device factory for injectable HID inventory registration.</summary>
  ICardHidDeviceFactory = interface
    ['{187245B0-34C7-4DE1-B09E-6A823B17E9A6}']
    /// <summary>Constructs an inactive exact-path device without native Open.</summary>
    /// <param name="APath">Observed opaque collection path.</param>
    /// <returns>Non-nil retained report device.</returns>
    function CreateDevice(const APath: UnicodeString): IHidReportDevice;
  end;
  /// <summary>Nonvisual HID hotplug-to-session binding; device presence never implies RFID card presence.</summary>
  /// <remarks>Main-thread lifecycle, case-normalized hid: path IDs and copied read/write policy. Native Start seeds
  /// initial inventory silently; injected hosts supply initial ObserveDeviceAdded calls explicitly.</remarks>
  TCardHidSessionRegistry = class(TComponent)
  private
    FMonitor: THidDeviceMonitor;
    FManager: TCardSessionManager;
    FFactory: ICardHidDeviceFactory;
    FPaths: array of UnicodeString;
    FWriteAccess,FNative: Boolean;
    FOnAdded,FOnRemoved: THidDevicePathEvent;
    procedure SetManager(const Value: TCardSessionManager);
    procedure SetFactory(const Value: ICardHidDeviceFactory);
    procedure Added(Sender: TObject; const Path: UnicodeString);
    procedure Removed(Sender: TObject; const Path: UnicodeString);
    procedure AddPath(const Path: UnicodeString; const Notify: Boolean);
  protected
    /// <summary>Stops/detaches before the shared manager is removed.</summary>
    /// <param name="AComponent">Removed dependency.</param>
    /// <param name="Operation">Notification kind.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Constructs inactive native notifications; no discovery, windows or device I/O.</summary>
    /// <param name="AOwner">Optional owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Constructs inactive injectable notifications without native initial enumeration.</summary>
    /// <param name="AOwner">Optional owner.</param>
    /// <param name="AApi">Non-nil notification adapter.</param>
    constructor CreateWithApi(AOwner: TComponent; const AApi: IHidDeviceNotifications);
    /// <summary>Unregisters notifications and invalidates owned device registrations.</summary>
    destructor Destroy; override;
    /// <summary>Starts native notifications; default native configuration seeds current devices without opening them.</summary>
    procedure Start;
    /// <summary>Stops synchronously and detaches owned inventory, preserving unrelated manager entries.</summary>
    procedure Stop;
    /// <summary>Registers an exact arriving path, deferring a reappearance behind a detached old lease.</summary>
    /// <param name="APath">Opaque nonempty device path.</param>
    procedure ObserveDeviceAdded(const APath: UnicodeString);
    /// <summary>Invalidates/removes one observed path; unknown paths are harmless.</summary>
    /// <param name="APath">Exact disappearing path.</param>
    procedure ObserveDeviceRemoved(const APath: UnicodeString);
    /// <summary>Optional retained inactive-device factory; change only with empty inactive inventory.</summary>
    property Factory: ICardHidDeviceFactory read FFactory write SetFactory;
  published
    /// <summary>Shared physical resource registry; change only with empty inactive inventory.</summary>
    property Manager: TCardSessionManager read FManager write SetManager;
    /// <summary>Explicit write access copied into newly registered providers, default false.</summary>
    property WriteAccess: Boolean read FWriteAccess write FWriteAccess default False;
    /// <summary>Hotplug arrival after lazy session registration.</summary>
    property OnDeviceAdded: THidDevicePathEvent read FOnAdded write FOnAdded;
    /// <summary>Removal after lease invalidation.</summary>
    property OnDeviceRemoved: THidDevicePathEvent read FOnRemoved write FOnRemoved;
  end;
implementation
function ResourceId(const Path: UnicodeString): string;
begin Result := 'hid:'+LowerCase(string(Path)); end;
procedure RequireMain;
begin
  if NativeUInt(TThread.CurrentThread.ThreadID)<>NativeUInt(MainThreadID) then
    raise ECardSessionError.Create('Inventory lifecycle belongs to the main thread.');
end;
constructor TCardHidSessionRegistry.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FNative := True; FMonitor := THidDeviceMonitor.Create(Self);
  FMonitor.OnDeviceAdded := Added; FMonitor.OnDeviceRemoved := Removed;
end;
constructor TCardHidSessionRegistry.CreateWithApi(AOwner: TComponent; const AApi: IHidDeviceNotifications);
begin
  inherited Create(AOwner); FMonitor := THidDeviceMonitor.CreateWithApi(Self,AApi);
  FMonitor.OnDeviceAdded := Added; FMonitor.OnDeviceRemoved := Removed;
end;
destructor TCardHidSessionRegistry.Destroy;
begin Stop; inherited Destroy; end;
procedure TCardHidSessionRegistry.SetManager(const Value: TCardSessionManager);
begin
  RequireMain;
  if FMonitor.Active or (Length(FPaths)<>0) then raise ECardSessionError.Create('Stop inventory first.');
  if FManager<>nil then FManager.RemoveFreeNotification(Self);
  FManager := Value; if Value<>nil then Value.FreeNotification(Self);
end;
procedure TCardHidSessionRegistry.SetFactory(const Value: ICardHidDeviceFactory);
begin
  RequireMain;
  if FMonitor.Active or (Length(FPaths)<>0) then raise ECardSessionError.Create('Stop inventory first.');
  FFactory := Value;
end;
procedure TCardHidSessionRegistry.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation=opRemove) and (AComponent=FManager) then begin Stop; FManager := nil; end;
  inherited Notification(AComponent,Operation);
end;
procedure TCardHidSessionRegistry.Start;
var Devices: THidDevices; I: Integer;
begin
  RequireMain;
  if FManager=nil then raise ECardSessionError.Create('A manager is required.');
  FMonitor.Start;
  try
    if FNative then begin
      Devices := EnumerateWindowsHidDevices;
      for I := 0 to High(Devices) do AddPath(Devices[I].DevicePath,False);
    end;
  except Stop; raise; end;
end;
procedure TCardHidSessionRegistry.Stop;
var I: Integer;
begin
  RequireMain; if FMonitor<>nil then FMonitor.Stop;
  if FManager<>nil then for I := 0 to High(FPaths) do FManager.DetachReader(ResourceId(FPaths[I]));
  FPaths := nil;
end;
procedure TCardHidSessionRegistry.AddPath(const Path: UnicodeString; const Notify: Boolean);
var I,N: Integer; Provider: THidSessionProvider;
begin
  RequireMain;
  if FManager=nil then raise ECardSessionError.Create('A manager is required.');
  if (Path='') or (Pos(#0,Path)<>0) then raise ECardSessionError.Create('An exact HID path is required.');
  for I := 0 to High(FPaths) do if ResourceId(FPaths[I])=ResourceId(Path) then Exit;
  if Length(FPaths)>=256 then raise ECardSessionError.Create('Inventory budget exceeded.');
  Provider := THidSessionProvider.Create(nil);
  try
    Provider.DevicePath := Path; Provider.WriteAccess := FWriteAccess;
    if FFactory<>nil then begin
      Provider.Device := FFactory.CreateDevice(Path);
      if Provider.Device=nil then raise ECardSessionError.Create('HID factory returned no device.');
    end;
    FManager.BindResourceConnectionWhenIdle(ResourceId(Path),Provider.CreateConnection);
  finally Provider.Free; end;
  N := Length(FPaths); SetLength(FPaths,N+1); FPaths[N] := Path;
  if Notify and Assigned(FOnAdded) then FOnAdded(Self,Path);
end;
procedure TCardHidSessionRegistry.ObserveDeviceAdded(const APath: UnicodeString);
begin AddPath(APath,True); end;
procedure TCardHidSessionRegistry.ObserveDeviceRemoved(const APath: UnicodeString);
var I,J: Integer;
begin
  RequireMain;
  for I := 0 to High(FPaths) do if ResourceId(FPaths[I])=ResourceId(APath) then begin
    FManager.DetachReader(ResourceId(APath));
    for J := I to High(FPaths)-1 do FPaths[J] := FPaths[J+1];
    SetLength(FPaths,Length(FPaths)-1);
    if Assigned(FOnRemoved) then FOnRemoved(Self,APath);
    Exit;
  end;
end;
procedure TCardHidSessionRegistry.Added(Sender: TObject; const Path: UnicodeString);
begin ObserveDeviceAdded(Path); end;
procedure TCardHidSessionRegistry.Removed(Sender: TObject; const Path: UnicodeString);
begin ObserveDeviceRemoved(Path); end;
end.
