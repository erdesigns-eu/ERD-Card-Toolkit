unit ERD.Card.PCSC.Api;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Transport;

const
  /// <summary>PC/SC completed the operation successfully.</summary>
  PcscSuccess: Cardinal = 0;
  /// <summary>PC/SC or its adapter returned inconsistent data.</summary>
  PcscInternalError: Cardinal = $80100001;
  /// <summary>The pending PC/SC operation was cancelled.</summary>
  PcscCancelled: Cardinal = $80100002;
  /// <summary>The supplied native arguments are invalid.</summary>
  PcscInvalidParameter: Cardinal = $80100004;
  /// <summary>A supplied receive buffer is too small.</summary>
  PcscInsufficientBuffer: Cardinal = $80100008;
  /// <summary>A status wait reached its timeout without a change.</summary>
  PcscTimeout: Cardinal = $8010000A;
  /// <summary>The requested feature or operating system is unsupported.</summary>
  PcscUnsupportedFeature: Cardinal = $80100022;
  /// <summary>The resource manager has no readers; discovery treats this as an empty list.</summary>
  PcscNoReaders: Cardinal = $8010002E;
  /// <summary>The native T=0 protocol mask.</summary>
  PcscProtocolT0: Cardinal = 1;
  /// <summary>The native T=1 protocol mask.</summary>
  PcscProtocolT1: Cardinal = 2;
  /// <summary>An unknown initial reader state, requesting an immediate snapshot.</summary>
  PcscStateUnaware: Cardinal = 0;
  /// <summary>The returned state differs from the supplied current state.</summary>
  PcscStateChanged: Cardinal = $0002;
  /// <summary>The resource manager does not recognize the selected reader.</summary>
  PcscStateUnknown: Cardinal = $0004;
  /// <summary>The reader is currently unavailable.</summary>
  PcscStateUnavailable: Cardinal = $0008;
  /// <summary>No card is present in the reader.</summary>
  PcscStateEmpty: Cardinal = $0010;
  /// <summary>A card is present; this does not establish a connection.</summary>
  PcscStatePresent: Cardinal = $0020;
  /// <summary>The card is exclusively in use by another connection.</summary>
  PcscStateExclusive: Cardinal = $0080;
  /// <summary>One or more connections are using the card.</summary>
  PcscStateInUse: Cardinal = $0100;
  /// <summary>The inserted card is unresponsive.</summary>
  PcscStateMute: Cardinal = $0200;
  /// <summary>The inserted card has not been powered.</summary>
  PcscStateUnpowered: Cardinal = $0400;
  /// <summary>Windows PC/SC pseudo-reader waking status waits on reader arrival/removal.</summary>
  PcscPnpNotification: UnicodeString = '\\?PnP?\Notification';
  /// <summary>The Windows SCARD_READERSTATE ATR buffer size, including alignment bytes.</summary>
  PcscMaxAtrBytes = 36;

type
  /// <summary>A pointer-sized Windows SCARDCONTEXT or SCARDHANDLE, never a 32-bit index.</summary>
  TPcscHandle = NativeUInt;
  /// <summary>An ordered discovery result containing Unicode reader names.</summary>
  TPcscReaderNames = array of UnicodeString;
  /// <summary>The sharing policy negotiated when opening a card connection.</summary>
  TPcscShareMode = (
    /// <summary>This connection exclusively owns the card.</summary>
    psmExclusive,
    /// <summary>Other applications may also connect to the card.</summary>
    psmShared);
  /// <summary>An explicit card action when ending a transaction or connection.</summary>
  TPcscDisposition = (
    /// <summary>Leave the card powered and its current state unchanged.</summary>
    pcdLeave,
    /// <summary>Reset the card.</summary>
    pcdReset,
    /// <summary>Power down the card.</summary>
    pcdUnpower,
    /// <summary>Request ejection where the reader supports it.</summary>
    pcdEject);
  /// <summary>The single negotiated command transport protocol.</summary>
  TPcscProtocol = (
    /// <summary>No card is connected.</summary>
    pcpNone,
    /// <summary>T=0 was negotiated.</summary>
    pcpT0,
    /// <summary>T=1 was negotiated.</summary>
    pcpT1);

  /// <summary>A raw reader snapshot independent of connection state.</summary>
  /// <remarks>Ordinary record assignment shares Atr storage; publishers must copy it for independent ownership.</remarks>
  TPcscReaderSnapshot = record
    /// <summary>The exact Unicode reader identity used for the observation.</summary>
    ReaderName: UnicodeString;
    /// <summary>Native state bits and event counter; the Changed bit is normalized away.</summary>
    State: Cardinal;
    /// <summary>Uninterpreted ATR bytes, possibly a reader-generated contactless identifier.</summary>
    Atr: TBytes;
  end;

  /// <summary>Owned snapshots/current states for a bounded multi-reader status wait.</summary>
  TPcscReaderSnapshots = array of TPcscReaderSnapshot;

  /// <summary>Optional native multi-reader status wait; supports the PC/SC PnP notification pseudo-reader.</summary>
  IPcscMonitorApi = interface
    ['{40801DA5-2D15-41E1-A147-0D8DE2E4A1CA}']
    /// <summary>Waits for any selected reader/PnP transition on a dedicated monitor context.</summary>
    /// <param name="AContext">Live monitor context, independently cancellable.</param>
    /// <param name="ACurrent">One to 1025 unique exact reader names; normalized states except the raw PnP state.</param>
    /// <param name="ATimeoutMs">Finite timeout; timeout does not trigger reader-list polling.</param>
    /// <param name="ASnapshots">Owned ordered snapshots matching names; normalized reader states, raw PnP state; cleared on failure.</param>
    /// <returns>Native success, timeout, cancellation or error; no APDU or card connection is opened.</returns>
    function WaitReaders(const AContext: TPcscHandle;
      const ACurrent: TPcscReaderSnapshots; const ATimeoutMs: Cardinal;
      out ASnapshots: TPcscReaderSnapshots): Cardinal;
  end;

  /// <summary>A PC/SC failure preserving the unsigned 32-bit native status code.</summary>
  EPcscError = class(ECardTransportError)
  private
    FStatusCode: Cardinal;
    FOperation: string;
  public
    /// <summary>Creates a native failure without logging card data or reader identities.</summary>
    /// <param name="AOperation">A fixed operation label, not user/card data.</param>
    /// <param name="AStatusCode">The original PC/SC error bits.</param>
    constructor Create(const AOperation: string; const AStatusCode: Cardinal);
      reintroduce;
    /// <summary>The unsigned native PC/SC status code.</summary>
    property StatusCode: Cardinal read FStatusCode;
    /// <summary>The fixed operation label.</summary>
    property Operation: string read FOperation;
  end;

  /// <summary>An injectable, thread-safe boundary around native PC/SC operations.</summary>
  /// <remarks>
  /// All outputs are cleared on native failure. Returned arrays must be independent.
  /// A successful context/card creation returns a nonzero pointer-sized handle.
  /// Implementations must support Cancel concurrently with WaitStatus on the same
  /// context and honor finite status timeouts. No callback or command replay occurs.
  /// Cleanup methods return a status and must not raise; allocation failures in
  /// other methods may propagate. Handles are owned by callers, not by this interface.
  /// </remarks>
  IPcscApi = interface
    ['{90538C45-FDD4-431D-9329-5F37EA010F1C}']
    /// <summary>Creates a user-scoped resource-manager context.</summary>
    /// <param name="AContext">The owned context, or zero on failure.</param>
    /// <returns>The native status code.</returns>
    function Establish(out AContext: TPcscHandle): Cardinal;
    /// <summary>Releases a context after its card handles/waits have been closed.</summary>
    /// <param name="AContext">The context to release.</param>
    /// <returns>The native status code; does not raise.</returns>
    function Release(const AContext: TPcscHandle): Cardinal;
    /// <summary>Discovers Unicode reader identities.</summary>
    /// <param name="AContext">A live resource-manager context.</param>
    /// <param name="ANames">Independent reader names, empty on failure or PcscNoReaders.</param>
    /// <returns>The native status code; PcscNoReaders denotes an empty discovery result.</returns>
    function ListReaders(const AContext: TPcscHandle;
      out ANames: TPcscReaderNames): Cardinal;
    /// <summary>Connects to one exact reader name with a protocol mask.</summary>
    /// <param name="AContext">A live context.</param>
    /// <param name="AReaderName">The exact Unicode reader name, without embedded nulls.</param>
    /// <param name="AShareMode">The requested sharing policy.</param>
    /// <param name="AProtocols">A nonzero combination of PcscProtocolT0 and PcscProtocolT1.</param>
    /// <param name="ACard">The owned card handle, or zero on failure.</param>
    /// <param name="AActiveProtocol">The single negotiated native protocol, or zero on failure.</param>
    /// <returns>The native status code.</returns>
    function Connect(const AContext: TPcscHandle;
      const AReaderName: UnicodeString; const AShareMode: TPcscShareMode;
      const AProtocols: Cardinal; out ACard: TPcscHandle;
      out AActiveProtocol: Cardinal): Cardinal;
    /// <summary>Closes a card connection with an explicit card action.</summary>
    /// <param name="ACard">The connected card handle.</param>
    /// <param name="ADisposition">The requested card action.</param>
    /// <returns>The native status code; does not raise.</returns>
    function Disconnect(const ACard: TPcscHandle;
      const ADisposition: TPcscDisposition): Cardinal;
    /// <summary>Acquires the native card transaction lock.</summary>
    /// <param name="ACard">The connected card handle.</param>
    /// <returns>The native status code; this synchronous call may block.</returns>
    function BeginTransaction(const ACard: TPcscHandle): Cardinal;
    /// <summary>Ends the native transaction with an explicit card action.</summary>
    /// <param name="ACard">The connected card handle.</param>
    /// <param name="ADisposition">The requested card action.</param>
    /// <returns>The native status code.</returns>
    function EndTransaction(const ACard: TPcscHandle;
      const ADisposition: TPcscDisposition): Cardinal;
    /// <summary>Sends one command without retrying it.</summary>
    /// <param name="ACard">The connected card handle.</param>
    /// <param name="AProtocol">The single negotiated native protocol.</param>
    /// <param name="ACommand">Bytes sent once; not retained.</param>
    /// <param name="AMaxResponseBytes">The allocated receive capacity.</param>
    /// <param name="AResponse">Independent received bytes, empty on native failure.</param>
    /// <returns>The native status code; an insufficient buffer must not trigger a resend.</returns>
    function Transmit(const ACard: TPcscHandle; const AProtocol: Cardinal;
      const ACommand: TBytes; const AMaxResponseBytes: Integer;
      out AResponse: TBytes): Cardinal;
    /// <summary>Reads the current ATR associated with a card connection.</summary>
    /// <param name="ACard">The connected card handle.</param>
    /// <param name="AAtr">Independent uninterpreted bytes, empty on failure.</param>
    /// <returns>The native status code.</returns>
    function ReadAtr(const ACard: TPcscHandle; out AAtr: TBytes): Cardinal;
    /// <summary>Waits for a reader state transition within a finite timeout.</summary>
    /// <param name="AContext">A dedicated monitoring context.</param>
    /// <param name="AReaderName">The exact reader identity.</param>
    /// <param name="ACurrentState">The last normalized state, or PcscStateUnaware initially.</param>
    /// <param name="ATimeoutMs">The finite timeout in milliseconds.</param>
    /// <param name="ASnapshot">Independent normalized state/ATR, cleared on failure.</param>
    /// <returns>Native success, timeout, cancellation or another failure.</returns>
    function WaitStatus(const AContext: TPcscHandle;
      const AReaderName: UnicodeString; const ACurrentState: Cardinal;
      const ATimeoutMs: Cardinal; out ASnapshot: TPcscReaderSnapshot): Cardinal;
    /// <summary>Cancels an in-flight status wait without affecting other contexts.</summary>
    /// <param name="AContext">The dedicated monitoring context.</param>
    /// <returns>The native status code; does not raise.</returns>
    function Cancel(const AContext: TPcscHandle): Cardinal;
  end;

implementation

constructor EPcscError.Create(const AOperation: string;
  const AStatusCode: Cardinal);
begin
  inherited Create(AOperation + ' failed (PC/SC 0x' + IntToHex(AStatusCode,
    8) + ').');
  FOperation := AOperation;
  FStatusCode := AStatusCode;
end;

end.
