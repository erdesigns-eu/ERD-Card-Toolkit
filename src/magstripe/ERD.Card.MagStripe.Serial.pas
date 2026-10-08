unit ERD.Card.MagStripe.Serial;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$ALIGN 8}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.MagStripe;

type
  /// <summary>Explicit 9600-baud framing; never inferred by sending card commands.</summary>
  TMagStripeSerialFormat = (
    /// <summary>Eight data bits, no parity, one stop bit: MSR206/MSR605.</summary>
    mssf8N1,
    /// <summary>Seven data bits, odd parity, one stop bit: default MSR206-7HL Rev F.</summary>
    mssf7O1
  );
  /// <summary>Exclusive synchronous serial byte channel; no protocol framing or automatic resend.</summary>
  /// <remarks>Use on one caller thread without reentrancy. Open failure grants no ownership;
  /// Close cancels/releases owned resources and clears local ownership even on error.
  /// Each I/O enforces its supplied remaining deadline. A partial send is an error, never resumed.</remarks>
  IMagStripeSerialPort = interface
    ['{31C4C54E-E953-42A4-90C3-601B334282DD}']
    /// <summary>Opens the configured port exclusively with its explicitly configured serial format.</summary>
    /// <remarks>No hardware/software flow control. Does not send a reader command.</remarks>
    procedure Open;
    /// <summary>Closes an acquired channel once; pending device commands require protocol-specific cancellation.</summary>
    procedure Close;
    /// <summary>Discards buffered input without sending bytes or discarding output.</summary>
    procedure DiscardInput;
    /// <summary>Sends one bounded buffer once; partial sends and errors raise.</summary>
    /// <param name="ABytes">One through 4096 bytes, not retained.</param>
    /// <param name="ATimeoutMs">Remaining I/O deadline, 1..600000 milliseconds.</param>
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    /// <summary>Receives exactly one byte; timeout, cancellation and zero/invalid byte counts raise.</summary>
    /// <param name="ATimeoutMs">Remaining I/O deadline, 1..600000 milliseconds.</param>
    /// <returns>Received byte only on complete success.</returns>
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    /// <summary>Returns a monotonic millisecond clock without opening the port.</summary>
    /// <returns>Tick count used to share one deadline across all operation I/O.</returns>
    function NowMs: UInt64;
  end;

/// <summary>Creates an inactive Windows COM channel; validates the name without accessing hardware.</summary>
/// <param name="APortName">Bare COM1..COM65535, case-insensitive ASCII; paths and alternate device names are refused.</param>
/// <returns>Retained interface owning an exclusive handle after explicit Open; destructor best-effort closes it.</returns>
/// <exception cref="EMagStripeError">Port name is invalid.</exception>
/// <remarks>Default 9600/8N1. Uses Windows kernel32 serial APIs, no vendor DLL. On other platforms Open raises unsupported.
/// Synchronous driver timeouts require a conforming serial driver; Windows/driver validation remains separate.</remarks>
function CreateWindowsMagStripeSerialPort(const APortName: string): IMagStripeSerialPort; overload;

/// <summary>Creates an inactive exclusive Windows COM channel with explicit 9600-baud framing.</summary>
/// <param name="APortName">Bare COM1..COM65535; the same strict validation as the default factory.</param>
/// <param name="AFormat">8N1 or 7O1; must match the reader configuration.</param>
/// <returns>Retained channel; does not open hardware until Open.</returns>
/// <exception cref="EMagStripeError">Name or format is invalid.</exception>
/// <remarks>One stop bit and no flow control; parity checking is enabled for 7O1.</remarks>
function CreateWindowsMagStripeSerialPort(const APortName: string;
  const AFormat: TMagStripeSerialFormat): IMagStripeSerialPort; overload;

implementation

type
  TWindowsSerialPort = class(TInterfacedObject, IMagStripeSerialPort)
  private
    FPath: UnicodeString;
    FFormat: TMagStripeSerialFormat;
    FHandle: NativeUInt;
    FOpen: Boolean;
    procedure CheckOpen;
  public
    constructor Create(const APortName: string; const AFormat: TMagStripeSerialFormat);
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure DiscardInput;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
  end;

{$IFDEF MSWINDOWS}
type
  TNativeDcb = record
    Length, BaudRate, Flags: Cardinal;
    Reserved, XonLimit, XoffLimit: Word;
    ByteSize, Parity, StopBits, XonChar, XoffChar, ErrorChar, EofChar, EventChar: Byte;
    Reserved1: Word;
  end;
  TNativeTimeouts = record
    ReadInterval, ReadMultiplier, ReadConstant, WriteMultiplier, WriteConstant: Cardinal;
  end;

function NativeOpen(const AName: PWideChar; const AAccess, AShare: Cardinal;
  const ASecurity: Pointer; const ACreation, AFlags: Cardinal;
  const ATemplate: NativeUInt): NativeUInt; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function NativeClose(const AHandle: NativeUInt): LongBool; stdcall;
  external 'kernel32.dll' name 'CloseHandle';
function NativeSetState(const AHandle: NativeUInt; const ADcb: Pointer): LongBool; stdcall;
  external 'kernel32.dll' name 'SetCommState';
function NativeSetTimeouts(const AHandle: NativeUInt; const ATimeouts: Pointer): LongBool; stdcall;
  external 'kernel32.dll' name 'SetCommTimeouts';
function NativePurge(const AHandle: NativeUInt; const AFlags: Cardinal): LongBool; stdcall;
  external 'kernel32.dll' name 'PurgeComm';
function NativeWrite(const AHandle: NativeUInt; const ABuffer: Pointer; const ACount: Cardinal;
  out AWritten: Cardinal; const AOverlapped: Pointer): LongBool; stdcall;
  external 'kernel32.dll' name 'WriteFile';
function NativeRead(const AHandle: NativeUInt; const ABuffer: Pointer; const ACount: Cardinal;
  out ARead: Cardinal; const AOverlapped: Pointer): LongBool; stdcall;
  external 'kernel32.dll' name 'ReadFile';
function NativeError: Cardinal; stdcall; external 'kernel32.dll' name 'GetLastError';
function NativeClock: UInt64; stdcall; external 'kernel32.dll' name 'GetTickCount64';

function NativeLayoutValid: Boolean;
begin
  Result := (SizeOf(TNativeDcb) = 28) and (SizeOf(TNativeTimeouts) = 20);
end;

procedure SerialFailure;
begin
  raise EMagStripeError.CreateFmt('Windows serial operation failed (code %u).', [NativeError]);
end;

procedure ConfigureTimeout(const AHandle: NativeUInt; const ATimeoutMs: Cardinal);
var
  Timeouts: TNativeTimeouts;
begin
  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadConstant := ATimeoutMs;
  Timeouts.WriteConstant := ATimeoutMs;
  if not NativeSetTimeouts(AHandle, @Timeouts) then SerialFailure;
end;
{$ENDIF}

procedure CheckTimeout(const ATimeoutMs: Cardinal);
begin
  if (ATimeoutMs < 1) or (ATimeoutMs > 600000) then
    raise EMagStripeError.Create('Invalid serial I/O deadline.');
end;

function CreateWindowsMagStripeSerialPort(const APortName: string): IMagStripeSerialPort;
begin
  Result := TWindowsSerialPort.Create(APortName, mssf8N1);
end;

function CreateWindowsMagStripeSerialPort(const APortName: string;
  const AFormat: TMagStripeSerialFormat): IMagStripeSerialPort;
begin
  Result := TWindowsSerialPort.Create(APortName, AFormat);
end;

constructor TWindowsSerialPort.Create(const APortName: string; const AFormat: TMagStripeSerialFormat);
var
  I, Number: Integer;
  Name: string;
begin
  inherited Create;
  if (Ord(AFormat) < Ord(Low(TMagStripeSerialFormat))) or
    (Ord(AFormat) > Ord(High(TMagStripeSerialFormat))) then
    raise EMagStripeError.Create('Invalid serial format.');
  FFormat := AFormat;
  if (Length(APortName) < 4) or (Length(APortName) > 8) then
    raise EMagStripeError.Create('Expected a bare COM port name.');
  Name := UpperCase(APortName);
  if Copy(Name, 1, 3) <> 'COM' then raise EMagStripeError.Create('Expected a bare COM port name.');
  if Name[4] = '0' then raise EMagStripeError.Create('Invalid COM port number.');
  Number := 0;
  for I := 4 to Length(Name) do
  begin
    if not CharInSet(Name[I], ['0'..'9']) then raise EMagStripeError.Create('Invalid COM port number.');
    Number := Number * 10 + Ord(Name[I]) - Ord('0');
  end;
  if (Number < 1) or (Number > 65535) then raise EMagStripeError.Create('Invalid COM port number.');
  FPath := UnicodeString('\\.\COM' + IntToStr(Number));
end;

destructor TWindowsSerialPort.Destroy;
begin
  if FOpen then try Close; except { Explicit Close reports cleanup errors. } end;
  inherited Destroy;
end;

procedure TWindowsSerialPort.CheckOpen;
begin
  if not FOpen then raise EMagStripeError.Create('Serial port is not open.');
end;

procedure TWindowsSerialPort.Open;
{$IFDEF MSWINDOWS}
var
  Dcb: TNativeDcb;
  Handle: NativeUInt;
{$ENDIF}
begin
  if FOpen then raise EMagStripeError.Create('Serial port is already open.');
{$IFDEF MSWINDOWS}
  if not NativeLayoutValid then
    raise EMagStripeError.Create('Unexpected Windows serial structure layout.');
  Handle := NativeOpen(PWideChar(FPath), $C0000000, 0, nil, 3, 0, 0);
  if Handle = High(NativeUInt) then SerialFailure;
  try
    FillChar(Dcb, SizeOf(Dcb), 0);
    Dcb.Length := SizeOf(Dcb);
    Dcb.BaudRate := 9600;
    Dcb.Flags := 1; // fBinary; DTR/RTS and all flow-control flags disabled.
    Dcb.ByteSize := 8;
    if FFormat = mssf7O1 then
    begin
      Dcb.Flags := 3; // fBinary and fParity; no flow control.
      Dcb.ByteSize := 7;
      Dcb.Parity := 1; // ODDPARITY.
    end;
    Dcb.XonChar := $11;
    Dcb.XoffChar := $13;
    if not NativeSetState(Handle, @Dcb) then SerialFailure;
    ConfigureTimeout(Handle, 1000);
    if not NativePurge(Handle, 8) then SerialFailure; // PURGE_RXCLEAR only.
  except
    NativeClose(Handle);
    raise;
  end;
  FHandle := Handle;
  FOpen := True;
{$ELSE}
  raise EMagStripeError.Create('Native COM ports require Windows; supply another serial channel.');
{$ENDIF}
end;

procedure TWindowsSerialPort.Close;
{$IFDEF MSWINDOWS}
var
  Handle: NativeUInt;
{$ENDIF}
begin
  CheckOpen;
{$IFDEF MSWINDOWS}
  Handle := FHandle;
{$ENDIF}
  FHandle := 0;
  FOpen := False;
{$IFDEF MSWINDOWS}
  if not NativeClose(Handle) then SerialFailure;
{$ENDIF}
end;

procedure TWindowsSerialPort.DiscardInput;
begin
  CheckOpen;
{$IFDEF MSWINDOWS}
  if not NativePurge(FHandle, 8) then SerialFailure;
{$ENDIF}
end;

procedure TWindowsSerialPort.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
{$IFDEF MSWINDOWS}
var
  Count: Cardinal;
{$ENDIF}
begin
  CheckOpen;
  CheckTimeout(ATimeoutMs);
  if (Length(ABytes) < 1) or (Length(ABytes) > 4096) then
    raise EMagStripeError.Create('Invalid serial send size.');
{$IFDEF MSWINDOWS}
  ConfigureTimeout(FHandle, ATimeoutMs);
  Count := 0;
  if not NativeWrite(FHandle, @ABytes[0], Length(ABytes), Count, nil) then SerialFailure;
  if Count <> Cardinal(Length(ABytes)) then
    raise EMagStripeError.Create('Serial send was incomplete; it will not be resumed.');
{$ENDIF}
end;

function TWindowsSerialPort.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
{$IFDEF MSWINDOWS}
var
  Count: Cardinal;
{$ENDIF}
begin
  CheckOpen;
  CheckTimeout(ATimeoutMs);
  Result := 0;
{$IFDEF MSWINDOWS}
  ConfigureTimeout(FHandle, ATimeoutMs);
  Count := 0;
  if not NativeRead(FHandle, @Result, 1, Count, nil) then SerialFailure;
  if Count <> 1 then raise EMagStripeError.Create('Serial receive timed out or returned an invalid byte count.');
{$ENDIF}
end;

function TWindowsSerialPort.NowMs: UInt64;
begin
{$IFDEF MSWINDOWS}
  Result := NativeClock;
{$ELSE}
{$IFDEF FPC}
  Result := GetTickCount64;
{$ELSE}
  Result := 0;
  raise EMagStripeError.Create('Native serial clock requires Windows.');
{$ENDIF}
{$ENDIF}
end;

end.
