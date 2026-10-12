unit ERD.Card.HID.Session;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Session, ERD.Card.HID;
type
  /// <summary>Inactive lazy HID session configuration with copied device identity and explicit write access.</summary>
  THidSessionProvider = class(TComponent)
  private
    FDevice: IHidReportDevice;
    FDevicePath: UnicodeString;
    FWriteAccess: Boolean;
  public
    /// <summary>Copies the current device policy into a lazy guarded connection.</summary>
    /// <returns>Retained independent provider; no device is opened.</returns>
    function CreateConnection: ICardResourceConnection;
    /// <summary>Registers one guarded lazy HID provider without opening hardware.</summary>
    /// <param name="AManager">Shared physical reader/device registry.</param>
    /// <param name="AId">Exact unique physical resource identity.</param>
    procedure RegisterDevice(const AManager: TCardSessionManager; const AId: string);
    /// <summary>Optional injected retained device; nil uses the copied Windows device path.</summary>
    property Device: IHidReportDevice read FDevice write FDevice;
  published
    /// <summary>Exact Windows collection path, used only when Device is nil.</summary>
    property DevicePath: UnicodeString read FDevicePath write FDevicePath;
    /// <summary>Explicit native read/write access, false by default.</summary>
    property WriteAccess: Boolean read FWriteAccess write FWriteAccess default False;
  end;
implementation
type
  TGuardedHid = class(TInterfacedObject, IHidReportDevice)
  public
    Device: IHidReportDevice;
    Guard: ICardResourceGuard;
    Info: THidDeviceInfo;
    Writable, LogicalOpen: Boolean;
    function Open(const AWriteAccess: Boolean): THidDeviceInfo;
    procedure Close;
    function Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
    procedure Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
  end;
  TConnection = class(TInterfacedObject, ICardResourceConnection)
  public
    Device: IHidReportDevice;
    WriteAccess, Opened: Boolean;
    function Open(const AGuard: ICardResourceGuard): IInterface;
    function Identity: IInterface;
    procedure Close;
  end;
function TGuardedHid.Open(const AWriteAccess: Boolean): THidDeviceInfo;
begin
  Guard.BeginCall;
  try
    if LogicalOpen or (AWriteAccess and not Writable) then raise EHidError.Create('Invalid HID session acquisition.');
    LogicalOpen := True; Result := Info;
  except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
procedure TGuardedHid.Close;
begin
  Guard.BeginCall;
  try LogicalOpen := False; except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
function TGuardedHid.Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
begin
  Guard.BeginCall;
  try
    if not LogicalOpen then raise EHidError.Create('Acquire HID device first.');
    Result := Device.Receive(AKind,AReportId,ATimeoutMs);
  except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
procedure TGuardedHid.Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
begin
  Guard.BeginCall;
  try
    if not LogicalOpen or not Writable then raise EHidError.Create('Writable HID acquisition is required.');
    Device.Send(AKind,AReport,ATimeoutMs);
  except Guard.CancelCall; raise; end;
  try Guard.EndCall;
  except raise EHidSendUncertain.Create('HID generation changed after submission.'); end;
end;
function TConnection.Open(const AGuard: ICardResourceGuard): IInterface;
var Wrapper: TGuardedHid; Retained: IHidReportDevice; Info: THidDeviceInfo;
begin
  if Opened then raise EHidError.Create('HID connection already open.');
  Info := Device.Open(WriteAccess); Opened := True;
  try
    Wrapper := TGuardedHid.Create; Retained := Wrapper;
    Wrapper.Device := Device; Wrapper.Guard := AGuard; Wrapper.Info := Info; Wrapper.Writable := WriteAccess;
    Result := Retained;
  except try Close; except end; raise; end;
end;
function TConnection.Identity: IInterface;
begin Result := Device; end;
procedure TConnection.Close;
begin
  if not Opened then Exit;
  Opened := False; Device.Close;
end;
function THidSessionProvider.CreateConnection: ICardResourceConnection;
var Connection: TConnection;
begin
  Connection := TConnection.Create; Result := Connection;
  Connection.Device := FDevice;
  if Connection.Device=nil then Connection.Device := CreateWindowsHidReportDevice(FDevicePath);
  Connection.WriteAccess := FWriteAccess;
end;
procedure THidSessionProvider.RegisterDevice(const AManager: TCardSessionManager; const AId: string);
begin
  if AManager=nil then raise ECardSessionError.Create('A session manager is required.');
  AManager.BindResourceConnection(AId,CreateConnection);
end;
end.
