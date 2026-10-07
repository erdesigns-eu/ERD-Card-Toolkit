unit ERD.Card.Transport;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

const
  /// <summary>The maximum complete extended command size: header, Lc, data and Le.</summary>
  CardMaxCommandBytes = 65544;
  /// <summary>The maximum complete response size: 65536 data bytes and two status bytes.</summary>
  CardMaxResponseBytes = 65538;

type
  /// <summary>A local transport lifecycle, argument or malformed-response failure.</summary>
  /// <remarks>Error text must not include card commands, responses or personal data.</remarks>
  ECardTransportError = class(Exception);

  /// <summary>A byte transport shared by card protocols and test implementations.</summary>
  /// <remarks>
  /// Exchange sends a command exactly once and returns independent response bytes,
  /// including SW1/SW2. It must not retry commands, process 61xx/6Cxx, select
  /// applications or reset a card implicitly. Implementations document their
  /// connection lifetime and concurrency rules. Holding this interface retains
  /// the transport object, but does not promise that its connection stays open.
  /// </remarks>
  ICardTransport = interface
    ['{00DE7543-AD13-4ED3-A8C4-5DA4A4971164}']
    /// <summary>Sends one binary command and returns its complete response.</summary>
    /// <param name="ACommand">Nonempty bytes, at most CardMaxCommandBytes; not retained.</param>
    /// <returns>Independent response bytes including at least SW1 and SW2.</returns>
    /// <exception cref="ECardTransportError">Lifecycle, bounds or response framing are invalid.</exception>
    /// <remarks>Hardware failures may raise a transport-specific exception. Never replay a failed command automatically.</remarks>
    function Exchange(const ACommand: TBytes): TBytes;
  end;

  /// <summary>Optional exclusive transaction capability for a multi-command card operation.</summary>
  /// <remarks>Query the transport with Supports. Transactions are non-nesting and owned by
  /// the calling thread. Retain the interface until EndTransaction has completed.
  /// Implementations must exclude other threads and other clients of the physical card.</remarks>
  ICardTransaction = interface
    ['{F2B6855C-4DC7-4FA7-BC38-45CDE11E0E0F}']
    /// <summary>Acquires exclusive access to the connected card for this thread.</summary>
    /// <exception cref="ECardTransportError">The connection or transaction state is invalid.</exception>
    /// <remarks>May block behind another client; hardware failures may raise transport-specific exceptions.</remarks>
    procedure BeginTransaction;
    /// <summary>Releases this thread's transaction, leaving the card powered and unchanged.</summary>
    /// <exception cref="ECardTransportError">No transaction belongs to the calling thread.</exception>
    /// <remarks>Release failures may close the connection and raise a transport-specific exception.</remarks>
    procedure EndTransaction;
  end;

implementation

end.
