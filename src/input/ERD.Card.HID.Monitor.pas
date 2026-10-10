unit ERD.Card.HID.Monitor;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes,SysUtils,{$ELSE}System.Classes,System.SysUtils,{$ENDIF}
 ERD.Card.HID;
type
 /// <summary>Main-thread notification for one exact HID collection interface path.</summary>
 /// <param name="Sender">Component publishing the event.</param>
 /// <param name="ADevicePath">Opaque Unicode interface path; use explicit discovery for metadata.</param>
 THidDevicePathEvent=procedure(Sender:TObject;const ADevicePath:UnicodeString) of object;
 /// <summary>Internal/adapter notification on the owning main thread.</summary>
 /// <param name="ADevicePath">Exact arriving/disappearing HID collection path.</param>
 /// <param name="AAdded">True for arrival, false for removal.</param>
 THidNotification=procedure(const ADevicePath:UnicodeString;const AAdded:Boolean) of object;
 /// <summary>Injectable native device-notification registration; no enumeration/polling or card commands.</summary>
 IHidDeviceNotifications=interface
  ['{5F74A74F-F1D0-4873-A1CF-A2D594EA7ACA}']
  /// <summary>Registers owner-thread delivery; rollback is required if acquisition fails.</summary>
  /// <param name="AHandler">Retained method until Stop; may stop/free its monitor.</param>
  procedure Start(const AHandler:THidNotification);
  /// <summary>Unregisters synchronously and prevents future callbacks; safe to repeat.</summary>
  procedure Stop;
 end;
 /// <summary>Inactive nonvisual Windows HID hotplug monitor without VID/PID restrictions.</summary>
 /// <remarks>Native device notifications deliver on the main thread through a hidden window.
 /// Identifies HID collections, not card presence. Initial inventory is obtained with EnumerateWindowsHidDevices.
 /// All configuration/lifecycle belongs to the main thread. No timer or application polling is needed.</remarks>
 THidDeviceMonitor=class(TComponent)
 private
  FApi:IHidDeviceNotifications;FActive:Boolean;
  FOnAdded,FOnRemoved:THidDevicePathEvent;
  procedure DeviceNotification(const APath:UnicodeString;const AAdded:Boolean);
 public
  /// <summary>Constructs inactive native notification registration without opening hardware/windows.</summary>
  /// <param name="AOwner">Optional component owner.</param>
  constructor Create(AOwner:TComponent);override;
  /// <summary>Constructs inactive notification registration using an injected adapter.</summary>
  /// <param name="AOwner">Optional component owner.</param>
  /// <param name="AApi">Non-nil main-thread notification adapter.</param>
  constructor CreateWithApi(AOwner:TComponent;const AApi:IHidDeviceNotifications);
  /// <summary>Unregisters native notifications before releasing callbacks.</summary>
  destructor Destroy;override;
  /// <summary>Starts Windows HID collection arrival/removal events; no initial inventory is synthesized.</summary>
  /// <exception cref="EHidError">Unsupported platform or native registration failure.</exception>
  procedure Start;
  /// <summary>Stops and unregisters synchronously; safe from event handlers.</summary>
  procedure Stop;
  /// <summary>Whether native notification registration is owned.</summary>
  property Active:Boolean read FActive;
 published
  /// <summary>Arriving HID collection; no automatic opening, probing or selection.</summary>
  property OnDeviceAdded:THidDevicePathEvent read FOnAdded write FOnAdded;
  /// <summary>Disappearing HID collection path; does not claim a physical card removal.</summary>
  property OnDeviceRemoved:THidDevicePathEvent read FOnRemoved write FOnRemoved;
 end;
 /// <summary>One complete immutable interrupt input report, dispatched on the main thread.</summary>
 /// <param name="Sender">Input monitor publishing the notification.</param>
 /// <param name="AReport">Independent descriptor-sized report, including Windows report-ID byte.</param>
 THidInputReportEvent=procedure(Sender:TObject;const AReport:TBytes) of object;
 /// <summary>Terminal input failure after the listener releases its device.</summary>
 /// <param name="Sender">Stopped input monitor.</param>
 THidInputErrorEvent=procedure(Sender:TObject) of object;
 /// <summary>Continuous event-driven interrupt input, without application polling or output commands.</summary>
 /// <remarks>Opens one explicitly chosen device read-only on a dedicated worker. Main-thread callbacks
 /// use the RTL queue (VCL automatic, console/service CheckSynchronize). Keyboard collections may be
 /// owned exclusively by Windows; use TRfidKeyboardReader.OnIdentifier for foreground keyboard input.
 /// Report data can be fed to TRfidHidReportReader.FeedReport for explicit identifier decoding.
 /// Stop invalidates callbacks before joining; handlers may stop/free the monitor. No card removal is inferred.</remarks>
 TUsbHidInputMonitor=class(TComponent)
 private
  FDevice:IHidReportDevice;FWorker:TThread;
  FOnReport:THidInputReportEvent;FOnError:THidInputErrorEvent;
  procedure SetDevice(const AValue:IHidReportDevice);
  function GetActive:Boolean;
 public
  /// <summary>Constructs inactive observation; opens no device and starts no thread.</summary>
  /// <param name="AOwner">Optional component owner.</param>
  constructor Create(AOwner:TComponent);override;
  /// <summary>Discards queued callbacks and joins the input worker before destruction.</summary>
  destructor Destroy;override;
  /// <summary>Opens the configured device asynchronously and begins complete interrupt report events.</summary>
  /// <exception cref="EHidError">No device, active listener or invalid lifecycle thread.</exception>
  procedure Start;
  /// <summary>Stops and joins the worker; input waits use a finite 250-ms budget.</summary>
  /// <remarks>Injected backends must honor finite Receive timeouts. No commands are written or retried.</remarks>
  procedure Stop;
  /// <summary>Explicit inactive read-only report device; changes only while stopped.</summary>
  property Device:IHidReportDevice read FDevice write SetDevice;
  /// <summary>True while the worker is owned; terminal failures stop before OnError.</summary>
  property Active:Boolean read GetActive;
 published
  /// <summary>Complete unfiltered interrupt report; feed an explicit decoder if an identifier is needed.</summary>
  property OnInputReport:THidInputReportEvent read FOnReport write FOnReport;
  /// <summary>Terminal sanitized input/descriptor/queue failure; no automatic reconnect is attempted.</summary>
  property OnError:THidInputErrorEvent read FOnError write FOnError;
 end;
implementation
uses ERD.Card.Events,ERD.Card.Bytes
{$IFDEF MSWINDOWS}{$IFNDEF FPC},Winapi.Windows,Winapi.Messages{$ENDIF}{$ENDIF};
procedure RequireMain;
begin
 if NativeUInt(TThread.CurrentThread.ThreadID)<>NativeUInt(MainThreadID) then
  raise EHidError.Create('HID monitor lifecycle belongs to the main thread.');
end;
type
 TNativeNotifications=class(TInterfacedObject,IHidDeviceNotifications)
 private
  FHandler:THidNotification;
{$IFDEF MSWINDOWS}{$IFNDEF FPC}
  FWindow:HWND;FRegistration:NativeUInt;
  procedure WindowProc(var Msg:TMessage);
{$ENDIF}{$ENDIF}
 public
  destructor Destroy;override;
  procedure Start(const AHandler:THidNotification);
  procedure Stop;
 end;
{$IFDEF MSWINDOWS}{$IFNDEF FPC}
type
 TDeviceHeader=packed record Size,Kind,Reserved:Cardinal;end;
 TDeviceInterface=packed record Header:TDeviceHeader;ClassGuid:TGUID;Name:array[0..0] of WideChar;TailPadding:Word;end;
 PDeviceInterface=^TDeviceInterface;
function RegisterNotification(AWindow:HWND;AFilter:Pointer;AFlags:Cardinal):NativeUInt;stdcall;
 external 'user32.dll' name 'RegisterDeviceNotificationW';
function UnregisterNotification(AHandle:NativeUInt):BOOL;stdcall;
 external 'user32.dll' name 'UnregisterDeviceNotification';
procedure HidGuid(out AGuid:TGUID);stdcall;external 'hid.dll' name 'HidD_GetHidGuid';
procedure TNativeNotifications.WindowProc(var Msg:TMessage);
var P:PDeviceInterface;N,I:Integer;Path:UnicodeString;H:THidNotification;
begin
 Msg.Result:=0;
 if (Msg.Msg=WM_DEVICECHANGE) and ((Msg.WParam=$8000) or (Msg.WParam=$8004)) and (Msg.LParam<>0) then begin
  P:=PDeviceInterface(Msg.LParam);
  if (P.Header.Kind<>5) or (P.Header.Size<30) or (P.Header.Size>65536) then Exit;
  N:=(P.Header.Size-28) div SizeOf(WideChar);I:=0;
  while (I<N) and (PWideChar(@P.Name)[I]<>#0) do Inc(I);
  if (I=0) or (I=N) then Exit;
  SetString(Path,PWideChar(@P.Name),I);H:=FHandler;
  if Assigned(H) then H(Path,Msg.WParam=$8000);
  Exit;
 end;
 Msg.Result:=DefWindowProc(FWindow,Msg.Msg,Msg.WParam,Msg.LParam);
end;
{$ENDIF}{$ENDIF}
destructor TNativeNotifications.Destroy;
begin Stop;inherited Destroy;end;
procedure TNativeNotifications.Start(const AHandler:THidNotification);
{$IFDEF MSWINDOWS}{$IFNDEF FPC}var Filter:TDeviceInterface;{$ENDIF}{$ENDIF}
begin
 RequireMain;
{$IFDEF MSWINDOWS}{$IFNDEF FPC}
 if FWindow<>0 then raise EHidError.Create('HID notifications already active.');
 if not Assigned(AHandler) then raise EHidError.Create('HID notification callback required.');
 FHandler:=AHandler;FWindow:=AllocateHWnd(WindowProc);
 try
  FillChar(Filter,SizeOf(Filter),0);Filter.Header.Size:=SizeOf(Filter);Filter.Header.Kind:=5;HidGuid(Filter.ClassGuid);
  FRegistration:=RegisterNotification(FWindow,@Filter,0);
  if FRegistration=0 then raise EHidError.Create('Windows HID notification registration failed.');
 except Stop;raise;end;
{$ELSE}raise EHidError.Create('Native HID notifications require Delphi on Windows.');{$ENDIF}
{$ELSE}raise EHidError.Create('Native HID notifications require Windows.');{$ENDIF}
end;
procedure TNativeNotifications.Stop;
begin
 FHandler:=nil;
{$IFDEF MSWINDOWS}{$IFNDEF FPC}
 if FRegistration<>0 then UnregisterNotification(FRegistration);FRegistration:=0;
 if FWindow<>0 then DeallocateHWnd(FWindow);FWindow:=0;
{$ENDIF}{$ENDIF}
end;
constructor THidDeviceMonitor.Create(AOwner:TComponent);
begin inherited Create(AOwner);FApi:=TNativeNotifications.Create;end;
constructor THidDeviceMonitor.CreateWithApi(AOwner:TComponent;const AApi:IHidDeviceNotifications);
begin inherited Create(AOwner);if AApi=nil then raise EHidError.Create('HID notification adapter required.');FApi:=AApi;end;
destructor THidDeviceMonitor.Destroy;
begin Stop;inherited Destroy;end;
procedure THidDeviceMonitor.Start;
begin
 RequireMain;if FActive then raise EHidError.Create('HID notifications already active.');
 FActive:=True;try FApi.Start(DeviceNotification);except FActive:=False;FApi.Stop;raise;end;
end;
procedure THidDeviceMonitor.Stop;
begin RequireMain;FActive:=False;if FApi<>nil then FApi.Stop;end;
procedure THidDeviceMonitor.DeviceNotification(const APath:UnicodeString;const AAdded:Boolean);
var H:THidDevicePathEvent;
begin
 RequireMain;if not FActive then Exit;
 if (APath='') or (Pos(#0,APath)<>0) then raise EHidError.Create('Invalid HID notification path.');
 if AAdded then H:=FOnAdded else H:=FOnRemoved;
 if Assigned(H) then H(Self,APath);
end;
type
 TReportNotice=class(TInterfacedObject,ICardQueuedEvent)
  Owner:TUsbHidInputMonitor;Report:TBytes;Failed:Boolean;
  procedure Invoke;
 end;
 TInputWorker=class(TThread)
 private
  FOwner:TUsbHidInputMonitor;FDevice:IHidReportDevice;FQueue:ICardEventQueue;
  FCreated,FStarted:Boolean;
  procedure Deliver;
  procedure Post(const AReport:TBytes;const AFailed:Boolean);
 protected
  procedure Execute;override;
 public
  constructor Create(const AOwner:TUsbHidInputMonitor;const ADevice:IHidReportDevice);
  destructor Destroy;override;
  procedure BeginListening;
 end;
procedure TReportNotice.Invoke;
var H:THidInputErrorEvent;R:THidInputReportEvent;
begin
 if Failed then begin H:=Owner.FOnError;Owner.Stop;if Assigned(H) then H(Owner);end
 else begin R:=Owner.FOnReport;if Assigned(R) then R(Owner,Report);end;
end;
constructor TInputWorker.Create(const AOwner:TUsbHidInputMonitor;const ADevice:IHidReportDevice);
begin
 inherited Create(True);FCreated:=True;FreeOnTerminate:=False;
 FOwner:=AOwner;FDevice:=ADevice;FQueue:=CreateCardEventQueue;
end;
procedure TInputWorker.BeginListening;
begin FStarted:=True;Start;end;
destructor TInputWorker.Destroy;
begin
 if FQueue<>nil then FQueue.Disable;
 if FCreated then begin Terminate;if not FStarted then BeginListening;WaitFor;TThread.RemoveQueuedEvents(Self);end;
 inherited Destroy;
end;
procedure TInputWorker.Deliver;
var Q:ICardEventQueue;
begin Q:=FQueue;Q.Dispatch;end;
procedure TInputWorker.Post(const AReport:TBytes;const AFailed:Boolean);
var N:TReportNotice;E:ICardQueuedEvent;Schedule:Boolean;
begin
 N:=TReportNotice.Create;E:=N;N.Owner:=FOwner;N.Report:=CopyBytes(AReport);N.Failed:=AFailed;
 if AFailed then Schedule:=FQueue.Replace(E) else Schedule:=FQueue.Add(E);
 if Schedule then TThread.Queue(Self,Deliver);
end;
procedure TInputWorker.Execute;
var Info:THidDeviceInfo;Data:TBytes;Opened:Boolean;
begin
 Opened:=False;
 try
  if Terminated then Exit;
  Info:=FDevice.Open(False);Opened:=True;
  if (Info.InputBytes<1) then raise EHidError.Create('HID input descriptor missing.');
  while not Terminated do begin
   try
    Data:=FDevice.Receive(hrkInterrupt,0,250);
   except on E:EHidReceiveTimeout do Continue;end;
   if Terminated then Break;
   if Length(Data)<>Info.InputBytes then raise EHidError.Create('HID report length mismatch.');
   Post(Data,False);
  end;
  Opened:=False;FDevice.Close;
 except
  on E:Exception do begin
   if Opened then begin try FDevice.Close;except end;end;
   if not Terminated then Post(nil,True);
  end;
 end;
end;
constructor TUsbHidInputMonitor.Create(AOwner:TComponent);
begin inherited Create(AOwner);end;
destructor TUsbHidInputMonitor.Destroy;
begin Stop;inherited Destroy;end;
function TUsbHidInputMonitor.GetActive:Boolean;
begin Result:=FWorker<>nil;end;
procedure TUsbHidInputMonitor.SetDevice(const AValue:IHidReportDevice);
begin RequireMain;if Active then raise EHidError.Create('Stop input before changing its device.');FDevice:=AValue;end;
procedure TUsbHidInputMonitor.Start;
var W:TInputWorker;
begin
 RequireMain;if Active or (FDevice=nil) then raise EHidError.Create('Inactive configured HID input required.');
 W:=TInputWorker.Create(Self,FDevice);FWorker:=W;
 try W.BeginListening;except FWorker:=nil;W.Free;raise;end;
end;
procedure TUsbHidInputMonitor.Stop;
var W:TThread;
begin RequireMain;W:=FWorker;FWorker:=nil;W.Free;end;
end.
