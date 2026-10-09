unit ERD.Card.Reader.TWN4.Serial;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Reader.TWN4;

/// <summary>Creates an inactive Windows byte channel for a caller-selected TWN4 PRS USB-CDC COM port.</summary>
/// <param name="APortName">Bare COM1 through COM65535; no paths, automatic discovery or device fallback.</param>
/// <returns>Retained exclusive channel; opens only when the component starts an explicit operation.</returns>
/// <remarks>Uses the existing tested native serial-byte implementation at 9600/8N1, with no reader
/// commands or magstripe framing. USB-CDC must expose a compatible virtual port and PRS ASCII firmware.
/// Keyboard HID cannot be opened as COM. Native RS232 baud variants and firmware switching are not implied.
/// Other platforms can construct the channel but Open raises unsupported.</remarks>
function CreateWindowsTwn4CdcChannel(const APortName: string): ITwn4ByteChannel;

implementation

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.MagStripe.Serial;

type
  TTwn4SerialChannel = class(TInterfacedObject,ITwn4ByteChannel)
  private
    FPort: IMagStripeSerialPort;
  public
    constructor Create(const AName: string);
    procedure Open;
    procedure Close;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
  end;

constructor TTwn4SerialChannel.Create(const AName: string);
begin inherited Create; FPort := CreateWindowsMagStripeSerialPort(AName); end;

procedure TTwn4SerialChannel.Open;
begin
  FPort.Open;
  try FPort.DiscardInput;
  except try FPort.Close; except end; raise; end;
end;

procedure TTwn4SerialChannel.Close;
begin FPort.Close; end;

procedure TTwn4SerialChannel.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
begin FPort.Send(ABytes,ATimeoutMs); end;

function TTwn4SerialChannel.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
begin Result := FPort.ReceiveByte(ATimeoutMs); end;

function TTwn4SerialChannel.NowMs: UInt64;
begin Result := FPort.NowMs; end;

function CreateWindowsTwn4CdcChannel(const APortName: string): ITwn4ByteChannel;
begin Result := TTwn4SerialChannel.Create(APortName); end;

end.
