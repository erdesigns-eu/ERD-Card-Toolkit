unit ERD.Card.HID;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$A8}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes;
{$ELSE}
  System.SysUtils, System.Classes;
{$ENDIF}

type
  /// <summary>HID device, descriptor, report, timeout or ownership failure; messages exclude report contents.</summary>
  EHidError = class(Exception);
  /// <summary>Interrupt input timed out and cancellation completed; no complete report was delivered.</summary>
  /// <remarks>Only this error permits a continuous input listener to wait again; feature requests never use it.</remarks>
  EHidReceiveTimeout = class(EHidError);
  /// <summary>An output/feature submission was attempted and completion cannot be established.</summary>
  /// <remarks>Do not automatically replay a vendor command. A successful HID transfer is not card read-back.</remarks>
  EHidSendUncertain = class(EHidError);
  /// <summary>One descriptor-advertised Windows HID top-level collection, not an inferred card protocol.</summary>
  THidDeviceInfo = record
    /// <summary>Exact opaque Unicode device-interface path; may change on reconnect.</summary>
    DevicePath: UnicodeString;
    /// <summary>Descriptor USB vendor identifier; not an authenticity claim.</summary>
    VendorId: Word;
    /// <summary>Descriptor USB product identifier.</summary>
    ProductId: Word;
    /// <summary>Descriptor device version number.</summary>
    Version: Word;
    /// <summary>HID top-level usage page.</summary>
    UsagePage: Word;
    /// <summary>HID top-level usage.</summary>
    Usage: Word;
    /// <summary>Maximum input report bytes, including Windows report-ID byte; zero means unavailable.</summary>
    InputBytes: Word;
    /// <summary>Maximum output report bytes, including report-ID byte; zero means unavailable.</summary>
    OutputBytes: Word;
    /// <summary>Maximum feature report bytes, including report-ID byte; zero means unavailable.</summary>
    FeatureBytes: Word;
  end;
  /// <summary>Independent enumerated collection metadata; enumeration opens no card session.</summary>
  THidDevices = array of THidDeviceInfo;
  /// <summary>Explicit report endpoint; never selected by probing alternate commands.</summary>
  THidReportKind = (
    /// <summary>Queued input read or output write through the interrupt endpoint.</summary>
    hrkInterrupt,
    /// <summary>GetFeature or SetFeature control request; driver controls synchronous request duration.</summary>
    hrkFeature
  );
  /// <summary>Injectable single-thread retained device for descriptor-sized complete HID reports.</summary>
  /// <remarks>Open failures grant no ownership; Close relinquishes ownership even if it raises.
  /// Do not replay failed requests. Native feature calls have driver-controlled duration.</remarks>
  IHidReportDevice = interface
    ['{C762BEB7-D240-4557-9496-CBFA4A1DAA23}']
    /// <summary>Opens the exact configured interface once and acquires its descriptor metadata.</summary>
    /// <param name="AWriteAccess">True requires OS read/write access; false only requires read access.</param>
    /// <returns>Acquired report lengths and identity for the retained session.</returns>
    function Open(const AWriteAccess: Boolean): THidDeviceInfo;
    /// <summary>Closes an acquired device once; callers preserve a primary exception.</summary>
    procedure Close;
    /// <summary>Reads one complete interrupt/feature report without replay.</summary>
    /// <param name="AKind">Explicit endpoint.</param>
    /// <param name="AReportId">Selected feature ID; interrupt reports are not filtered or discarded.</param>
    /// <param name="ATimeoutMs">Interrupt wait budget; ignored by synchronous feature API.</param>
    /// <returns>Independent descriptor-sized buffer including ID.</returns>
    function Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
    /// <summary>Submits one complete output/feature report once; does not interpret vendor status.</summary>
    /// <param name="AKind">Explicit endpoint.</param>
    /// <param name="AReport">Exact descriptor-sized buffer, including byte-zero report ID.</param>
    /// <param name="ATimeoutMs">Interrupt wait budget; ignored by synchronous feature API.</param>
    procedure Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
  end;
  /// <summary>Nonvisual one-operation HID report component with injectable device and strict ownership.</summary>
  /// <remarks>No VID/PID allowlist. Keyboard collections can be inaccessible under Windows driver ownership.
  /// Report transport does not implement unspecified card-memory commands or make read-only readers writable.
  /// Each call acquires/releases its own device session; use one caller thread, without reentrancy.</remarks>
  TUsbHidReaderWriter = class(TComponent)
  private
    FDevice: IHidReportDevice;
    FBusy: Boolean;
    FTimeoutMs: Cardinal;
    procedure SetTimeout(const AValue: Cardinal);
    procedure SetDevice(const AValue: IHidReportDevice);
  public
    /// <summary>Creates an inactive component; opens no hardware.</summary>
    /// <param name="AOwner">Optional owner, otherwise caller owns Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads a descriptor-sized complete report and checks its explicit ID before returning.</summary>
    /// <param name="AKind">Interrupt input or feature control request.</param>
    /// <param name="AReportId">Exact expected byte-zero ID, including zero for unnumbered reports.</param>
    /// <returns>Owned complete buffer, only after successful device release.</returns>
    /// <exception cref="EHidError">Configuration, acquisition, report length/ID, transfer or release fails.</exception>
    function ReadReport(const AKind: THidReportKind; const AReportId: Byte): TBytes;
    /// <summary>Submits one descriptor-sized output/feature report; never claims card write verification.</summary>
    /// <param name="AKind">Explicit output or feature endpoint.</param>
    /// <param name="AReport">Complete supplied buffer with exact report ID at byte zero; copied before acquisition.</param>
    /// <exception cref="EHidError">Configuration, acquisition or descriptor size fails before dispatch.</exception>
    /// <exception cref="EHidSendUncertain">Any failure after Send entry, including transfer rejection or release.</exception>
    procedure SendReport(const AKind: THidReportKind; const AReport: TBytes);
    /// <summary>Retained inactive device; nil disables operations. Cannot change while Busy.</summary>
    property Device: IHidReportDevice read FDevice write SetDevice;
    /// <summary>True only while an operation owns local component execution.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Interrupt wait budget in milliseconds, 1..600000; synchronous feature requests use driver timing.</summary>
    property TimeoutMs: Cardinal read FTimeoutMs write SetTimeout default 3000;
  end;

/// <summary>Enumerates Windows HID collections with readable metadata, without a VID/PID restriction.</summary>
/// <returns>Owned paths/descriptors; inaccessible metadata collections are omitted. No device is auto-selected.</returns>
/// <exception cref="EHidError">Platform or interface enumeration fails.</exception>
function EnumerateWindowsHidDevices: THidDevices;

/// <summary>Creates an inactive native Windows HID report device for one explicit interface.</summary>
/// <param name="ADevicePath">Exact enumeration-provided Unicode path; never inferred from a brand/frequency.</param>
/// <returns>Retained device; Open obtains access and descriptor. Construction opens no hardware.</returns>
/// <exception cref="EHidError">Platform, empty path or embedded NUL is invalid.</exception>
function CreateWindowsHidReportDevice(const ADevicePath: UnicodeString): IHidReportDevice;

implementation

uses ERD.Card.Bytes;

procedure Fail;
begin raise EHidError.Create('HID operation, descriptor or device access failed.'); end;

function ReportSize(const Info: THidDeviceInfo; const Kind: THidReportKind; const Writing: Boolean): Integer;
begin
  if not (Kind in [hrkInterrupt,hrkFeature]) then Fail;
  if Kind = hrkFeature then Result := Info.FeatureBytes
  else if Writing then Result := Info.OutputBytes else Result := Info.InputBytes;
  if (Result < 1) or (Result > 4096) then Fail;
end;

constructor TUsbHidReaderWriter.Create(AOwner: TComponent);
begin inherited Create(AOwner); FTimeoutMs := 3000; end;
procedure TUsbHidReaderWriter.SetTimeout(const AValue: Cardinal);
begin if FBusy or (AValue < 1) or (AValue > 600000) then Fail; FTimeoutMs := AValue; end;
procedure TUsbHidReaderWriter.SetDevice(const AValue: IHidReportDevice);
begin if FBusy then Fail; FDevice := AValue; end;

function TUsbHidReaderWriter.ReadReport(const AKind: THidReportKind; const AReportId: Byte): TBytes;
var Device: IHidReportDevice; Info: THidDeviceInfo; Data: TBytes; Size: Integer;
begin
  Result := nil;
  if FBusy or (FDevice = nil) or not (AKind in [hrkInterrupt,hrkFeature]) then Fail;
  Device := FDevice; FBusy := True;
  try
    Info := Device.Open(False);
    try
      Size := ReportSize(Info,AKind,False); Data := Device.Receive(AKind,AReportId,FTimeoutMs);
      if (Length(Data) <> Size) then Fail;
      if Data[0] <> AReportId then Fail;
      Data := CopyBytes(Data);
    except try Device.Close; except end; raise; end;
    Device.Close; Result := Data;
  finally FBusy := False; end;
end;

procedure TUsbHidReaderWriter.SendReport(const AKind: THidReportKind; const AReport: TBytes);
var Device: IHidReportDevice; Info: THidDeviceInfo; Data: TBytes; Dispatched: Boolean;
begin
  if FBusy or (FDevice = nil) or not (AKind in [hrkInterrupt,hrkFeature]) or
    (Length(AReport) < 1) or (Length(AReport) > 4096) then Fail;
  Data := CopyBytes(AReport); Device := FDevice; FBusy := True; Dispatched := False;
  try
    try
      Info := Device.Open(True);
      try
        if Length(Data) <> ReportSize(Info,AKind,True) then Fail;
        Dispatched := True; Device.Send(AKind,Data,FTimeoutMs);
      except try Device.Close; except end; raise; end;
      Device.Close;
    except
      on E: Exception do
        if Dispatched then raise EHidSendUncertain.Create('HID submission completion is uncertain; do not replay automatically.') else raise;
    end;
  finally if Length(Data) > 0 then FillChar(Data[0],Length(Data),0); FBusy := False; end;
end;

{$IFDEF MSWINDOWS}
const
  INVALID_HANDLE_VALUE = High(NativeUInt);
  GENERIC_READ = $80000000;
  GENERIC_WRITE = $40000000;
  FILE_SHARE_READ = 1;
  FILE_SHARE_WRITE = 2;
  OPEN_EXISTING = 3;
  FILE_FLAG_OVERLAPPED = $40000000;
  ERROR_IO_PENDING = 997;
  ERROR_IO_INCOMPLETE = 996;
  ERROR_NO_MORE_ITEMS = 259;
  ERROR_INSUFFICIENT_BUFFER = 122;
  WAIT_OBJECT_0 = 0;
type
  THidNativeHandle = NativeUInt;
  TOverlapped = record
    Internal,InternalHigh: NativeUInt;
    Offset,OffsetHigh: Cardinal;
    hEvent: THidNativeHandle;
  end;
  POverlapped = ^TOverlapped;
  THidAttributes = record Size: Cardinal; VendorId,ProductId,Version: Word; end;
  THidCaps = record
    Usage,UsagePage,InputBytes,OutputBytes,FeatureBytes: Word;
    Reserved: array[0..16] of Word;
    LinkNodes,InputButtons,InputValues,InputData,OutputButtons,OutputValues,OutputData,FeatureButtons,FeatureValues,FeatureData: Word;
  end;
  THidInterfaceData = record Size: Cardinal; ClassGuid: TGUID; Flags: Cardinal; Reserved: NativeUInt; end;
  TWindowsHidDevice = class(TInterfacedObject,IHidReportDevice)
  private
    FPath: UnicodeString;
    FHandle: THidNativeHandle;
    FInfo: THidDeviceInfo;
    FWritable: Boolean;
    procedure Transfer(var Data: TBytes; const Writing: Boolean; const Timeout: Cardinal);
  public
    constructor Create(const Path: UnicodeString);
    destructor Destroy; override;
    function Open(const AWriteAccess: Boolean): THidDeviceInfo;
    procedure Close;
    function Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
    procedure Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
  end;

function CreateFileW(Path: PWideChar; Access,Share: Cardinal; Security: Pointer; Disposition,Flags: Cardinal; Template: THidNativeHandle): THidNativeHandle; stdcall; external 'kernel32.dll' name 'CreateFileW';
function CloseHandle(Handle: THidNativeHandle): LongBool; stdcall; external 'kernel32.dll' name 'CloseHandle';
function CreateEvent(Security: Pointer; ManualReset,InitialState: LongBool; Name: PWideChar): THidNativeHandle; stdcall; external 'kernel32.dll' name 'CreateEventW';
function ReadFile(Handle: THidNativeHandle; var Buffer; Count: Cardinal; var Done: Cardinal; Overlap: POverlapped): LongBool; stdcall; external 'kernel32.dll' name 'ReadFile';
function WriteFile(Handle: THidNativeHandle; const Buffer; Count: Cardinal; var Done: Cardinal; Overlap: POverlapped): LongBool; stdcall; external 'kernel32.dll' name 'WriteFile';
function GetLastError: Cardinal; stdcall; external 'kernel32.dll' name 'GetLastError';
function WaitForSingleObject(Handle: THidNativeHandle; Timeout: Cardinal): Cardinal; stdcall; external 'kernel32.dll' name 'WaitForSingleObject';
function GetOverlappedResult(Handle: THidNativeHandle; var Overlap: TOverlapped; var Done: Cardinal; Wait: LongBool): LongBool; stdcall; external 'kernel32.dll' name 'GetOverlappedResult';

procedure HidGuid(var Guid: TGUID); stdcall; external 'hid.dll' name 'HidD_GetHidGuid';
function HidAttributes(Handle: THidNativeHandle; var Attributes: THidAttributes): ByteBool; stdcall; external 'hid.dll' name 'HidD_GetAttributes';
function HidPreparsed(Handle: THidNativeHandle; var Data: Pointer): ByteBool; stdcall; external 'hid.dll' name 'HidD_GetPreparsedData';
function HidFreePreparsed(Data: Pointer): ByteBool; stdcall; external 'hid.dll' name 'HidD_FreePreparsedData';
function HidCaps(Data: Pointer; var Caps: THidCaps): LongInt; stdcall; external 'hid.dll' name 'HidP_GetCaps';
function HidGetFeature(Handle: THidNativeHandle; Data: Pointer; Size: Cardinal): ByteBool; stdcall; external 'hid.dll' name 'HidD_GetFeature';
function HidSetFeature(Handle: THidNativeHandle; Data: Pointer; Size: Cardinal): ByteBool; stdcall; external 'hid.dll' name 'HidD_SetFeature';
function SetupInterfaces(Guid: Pointer; Enumerator: PWideChar; Parent: THidNativeHandle; Flags: Cardinal): THidNativeHandle; stdcall; external 'setupapi.dll' name 'SetupDiGetClassDevsW';
function SetupEnum(SetHandle: THidNativeHandle; Device: Pointer; Guid: Pointer; Index: Cardinal; var Data: THidInterfaceData): LongBool; stdcall; external 'setupapi.dll' name 'SetupDiEnumDeviceInterfaces';
function SetupDetail(SetHandle: THidNativeHandle; var Data: THidInterfaceData; Detail: Pointer; DetailBytes: Cardinal; var Required: Cardinal; Device: Pointer): LongBool; stdcall; external 'setupapi.dll' name 'SetupDiGetDeviceInterfaceDetailW';
function SetupDestroy(SetHandle: THidNativeHandle): LongBool; stdcall; external 'setupapi.dll' name 'SetupDiDestroyDeviceInfoList';
function HidCancel(Handle: THidNativeHandle; Overlap: POverlapped): LongBool; stdcall; external 'kernel32.dll' name 'CancelIoEx';

function Metadata(const Handle: THidNativeHandle; const Path: UnicodeString): THidDeviceInfo;
var A: THidAttributes; C: THidCaps; P: Pointer;
begin
  Result := Default(THidDeviceInfo); FillChar(A,SizeOf(A),0); A.Size := SizeOf(A);
  if not HidAttributes(Handle,A) then Fail;
  P := nil; if not HidPreparsed(Handle,P) then Fail;
  try FillChar(C,SizeOf(C),0); if HidCaps(P,C) <> $00110000 then Fail;
  finally HidFreePreparsed(P); end;
  Result.DevicePath := Path; Result.VendorId := A.VendorId; Result.ProductId := A.ProductId; Result.Version := A.Version;
  Result.UsagePage := C.UsagePage; Result.Usage := C.Usage; Result.InputBytes := C.InputBytes; Result.OutputBytes := C.OutputBytes; Result.FeatureBytes := C.FeatureBytes;
end;

constructor TWindowsHidDevice.Create(const Path: UnicodeString);
begin inherited Create; FHandle := INVALID_HANDLE_VALUE; FPath := Path; end;
destructor TWindowsHidDevice.Destroy;
begin if FHandle <> INVALID_HANDLE_VALUE then try Close; except end; inherited Destroy; end;
function TWindowsHidDevice.Open(const AWriteAccess: Boolean): THidDeviceInfo;
var Access: Cardinal; H: THidNativeHandle;
begin
  if FHandle <> INVALID_HANDLE_VALUE then Fail;
  Access := GENERIC_READ; if AWriteAccess then Access := Access or GENERIC_WRITE;
  H := CreateFileW(PWideChar(FPath),Access,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,FILE_FLAG_OVERLAPPED,0);
  if H = INVALID_HANDLE_VALUE then Fail;
  try Result := Metadata(H,FPath); except CloseHandle(H); raise; end;
  FHandle := H; FInfo := Result; FWritable := AWriteAccess;
end;
procedure TWindowsHidDevice.Close;
var H: THidNativeHandle;
begin
  if FHandle = INVALID_HANDLE_VALUE then Fail;
  H := FHandle; FHandle := INVALID_HANDLE_VALUE; FInfo := Default(THidDeviceInfo); FWritable := False;
  if not CloseHandle(H) then Fail;
end;
procedure TWindowsHidDevice.Transfer(var Data: TBytes; const Writing: Boolean; const Timeout: Cardinal);
var O: TOverlapped; Done,Waited: Cardinal; Pending: Boolean; Ok: Boolean;
begin
  FillChar(O,SizeOf(O),0); O.hEvent := CreateEvent(nil,True,False,nil); if O.hEvent = 0 then Fail;
  Pending := False; Done := 0;
  try
    if Writing then Ok := WriteFile(FHandle,Data[0],Length(Data),Done,@O)
    else Ok := ReadFile(FHandle,Data[0],Length(Data),Done,@O);
    if not Ok then
    begin
      if GetLastError <> ERROR_IO_PENDING then Fail;
      Pending := True; Waited := WaitForSingleObject(O.hEvent,Timeout);
      if (Waited = 258) and not Writing then
      begin
        HidCancel(FHandle,@O);
        Ok := GetOverlappedResult(FHandle,O,Done,True);
        Pending := False;
        if not Ok then
        begin
          if GetLastError = 995 then raise EHidReceiveTimeout.Create('HID input wait timed out.');
          Fail;
        end;
      end
      else
      begin
        if Waited <> WAIT_OBJECT_0 then Fail;
      Ok := GetOverlappedResult(FHandle,O,Done,False);
      if not Ok then
      begin
        Pending := GetLastError = ERROR_IO_INCOMPLETE; Fail;
      end;
      Pending := False;
      end;
    end;
    if Done <> Cardinal(Length(Data)) then Fail;
  finally
    if Pending then
    begin
      { Cancellation is not completion: keep buffer/OVERLAPPED/event alive until the driver completes. }
      HidCancel(FHandle,@O); GetOverlappedResult(FHandle,O,Done,True);
    end;
    CloseHandle(O.hEvent);
  end;
end;
function TWindowsHidDevice.Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
begin
  Result := nil; if FHandle = INVALID_HANDLE_VALUE then Fail;
  if (ATimeoutMs < 1) or (ATimeoutMs > 600000) then Fail;
  SetLength(Result,ReportSize(FInfo,AKind,False)); Result[0] := AReportId;
  if AKind = hrkFeature then begin if not HidGetFeature(FHandle,@Result[0],Length(Result)) then Fail; end
  else Transfer(Result,False,ATimeoutMs);
end;
procedure TWindowsHidDevice.Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
var Data: TBytes;
begin
  if (FHandle = INVALID_HANDLE_VALUE) or not FWritable then Fail;
  if (ATimeoutMs < 1) or (ATimeoutMs > 600000) or (Length(AReport) <> ReportSize(FInfo,AKind,True)) then Fail;
  Data := CopyBytes(AReport);
  try
    if AKind = hrkFeature then begin if not HidSetFeature(FHandle,@Data[0],Length(Data)) then Fail; end
    else Transfer(Data,True,ATimeoutMs);
  finally if Length(Data) > 0 then FillChar(Data[0],Length(Data),0); end;
end;
{$ENDIF}

function CreateWindowsHidReportDevice(const ADevicePath: UnicodeString): IHidReportDevice;
begin
  Result := nil; if (Trim(ADevicePath) = '') or (Pos(#0,ADevicePath) > 0) then Fail;
{$IFDEF MSWINDOWS}
  Result := TWindowsHidDevice.Create(ADevicePath);
{$ELSE}
  Fail;
{$ENDIF}
end;

function EnumerateWindowsHidDevices: THidDevices;
{$IFDEF MSWINDOWS}
var Guid: TGUID; SetHandle,H: THidNativeHandle; D: THidInterfaceData; Required,Index,DetailSize: Cardinal;
  Buffer: TBytes; Path: UnicodeString; Info: THidDeviceInfo; N: Integer;
{$ENDIF}
begin
  Result := nil;
{$IFDEF MSWINDOWS}
  HidGuid(Guid); SetHandle := SetupInterfaces(@Guid,nil,0,$12); { PRESENT | DEVICEINTERFACE }
  if SetHandle = INVALID_HANDLE_VALUE then Fail;
  try
    Index := 0;
    while True do
    begin
      FillChar(D,SizeOf(D),0); D.Size := SizeOf(D);
      if not SetupEnum(SetHandle,nil,@Guid,Index,D) then
      begin if GetLastError = ERROR_NO_MORE_ITEMS then Break; Fail; end;
      Inc(Index); if Index > 4096 then Fail; Required := 0;
      if SetupDetail(SetHandle,D,nil,0,Required,nil) then Fail;
      if (GetLastError <> ERROR_INSUFFICIENT_BUFFER) or (Required < 6) or (Required > 65536) or ((Required and 1) <> 0) then Fail;
      SetLength(Buffer,Required); FillChar(Buffer[0],Length(Buffer),0);
      {$IF Defined(WIN64) or Defined(CPU64)}
      DetailSize := 8;
      {$ELSE}
      DetailSize := 6;
      {$IFEND}
      Move(DetailSize,Buffer[0],4);
      if not SetupDetail(SetHandle,D,@Buffer[0],Length(Buffer),Required,nil) then Fail;
      { DevicePath starts at byte four for both pointer widths; cbSize is six/eight. }
      if (Buffer[High(Buffer)] <> 0) or (Buffer[High(Buffer)-1] <> 0) then Fail;
      Path := UnicodeString(PWideChar(@Buffer[4]));
      H := CreateFileW(PWideChar(Path),0,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,0,0);
      if H = INVALID_HANDLE_VALUE then Continue;
      try
        try Info := Metadata(H,Path); except on E: EHidError do Continue; end;
        N := Length(Result); SetLength(Result,N+1); Result[N] := Info;
      finally CloseHandle(H); end;
    end;
  finally SetupDestroy(SetHandle); end;
{$ELSE}
  Fail;
{$ENDIF}
end;

end.
