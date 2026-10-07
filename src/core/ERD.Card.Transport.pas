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

implementation

end.
