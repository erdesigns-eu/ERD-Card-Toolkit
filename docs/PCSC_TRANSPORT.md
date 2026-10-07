# PC/SC connection and transport

`TSmartCardReader` is a non-visual RTL component. Add both `src/core` and `src/pcsc`
to a Delphi project's unit search path. Runtime packages are optional:
`ERDCardPCSC.dpk` requires `ERDCardCore.dpk` and the RTL. There is no design-time
registration package yet. Windows uses the operating system's `winscard.dll`;
other platforms report `PcscUnsupportedFeature` for system API operations.

## Connection use

```pascal
uses System.SysUtils, ERD.Card.PCSC.Api, ERD.Card.PCSC.Reader;

var
  Reader: TSmartCardReader;
  Names: TPcscReaderNames;
  Atr: TBytes;
begin
  Reader := TSmartCardReader.Create(nil);
  try
    Names := Reader.ListReaders;
    // Select an exact name from Names according to the application's configuration.
    Reader.ReaderName := SelectedReaderName;
    Reader.Connect;
    Atr := Reader.ReadAtr;
    Reader.Disconnect;
  finally
    Reader.Free;
  end;
end;
```

`SelectedReaderName` is application configuration. Discovery does not automatically
choose the first reader or connect to a card. Construction never establishes a
context. Discovery creates a context retained until Disconnect/destruction; Connect
opens a separate card handle owned by that instance. Names are Unicode identities,
not list indices. Failed Connect rolls back its context/handle. Close clears local
handles and attempts both disconnect and release, even if the first operation fails.
Destruction performs cleanup without raising native cleanup errors.

The default share mode is shared and the allowed protocol mask is T=0 or T=1.
Direct reader control, raw protocols and vendor SDK adapters are future family-specific
capabilities. Configure ReaderName, ShareMode, Protocols and MaxResponseBytes while
disconnected and not monitoring. An empty name may be configured but cannot be opened.
Connected describes a local handle; physical removal is detected by PC/SC operations.
No implicit reconnection/reset occurs. Explicit Disconnect/EndTransaction dispositions
default to leaving the card unchanged.

## Protocol boundary and transactions

`Reader.Transport` exposes reference-counted `ICardTransport`. Protocol readers and
test transports exchange `TBytes` without depending on this component or a UI. Each
Exchange sends exactly once, preserves SW1/SW2 and returns independent response bytes.
It does not select applications, retry, follow 61xx, correct 6Cxx, or parse an APDU.
Command bounds are 1..65544 bytes; response capacity is 2..65538 bytes. Device/protocol
limitations may be stricter and are reported as native errors. The native receive
buffer is allocated before sending; an insufficient-buffer failure never resends.
Transmit or response-framing failure closes the ambiguous connection.

Exchanges are serialized within a session. BeginTransaction additionally acquires
the PC/SC transaction lock against other native connections. Transactions cannot be
nested and belong to the thread that began them; exchanges/end/normal close from
other threads are rejected until the transaction ends. Native acquisition/transmit
calls can block; monitor cancellation does not interrupt them. EndTransaction failure
closes the connection. A failed BeginTransaction does not mark a transaction active.

Component configuration, lifecycle and polling belong to one application control
thread. Transport references can be retained and used from other threads subject to
transaction ownership. Freeing the component closes its connection; retained interfaces
remain valid and report disconnected. Their final release frees the session and adapter.
Serialize component destruction with other calls on the component itself.

`EPcscError` preserves the unsigned native status and a fixed operation label. Its
messages contain no command bytes, response bytes, reader names or personal card data.
Local argument/state/framing errors use `ECardTransportError`. Raw ATR bytes may contain
reader-generated contactless identification data; the transport does not force them
through an asynchronous ISO ATR parser.

## Monitoring and events

Call StartMonitoring after configuring the reader name. It creates a distinct context
and worker that waits in finite 250 ms intervals; it does not connect to a card.
StopMonitoring requests cancellation, joins that worker and then releases its context.
A cancellation just before a wait is covered by the finite timeout. No callbacks are
queued to a UI/message loop, so joining never waits for a component callback.

Call `PollChanges(out Snapshot)` regularly on the desired event thread, for example
from a VCL timer. It consumes the latest pending state and invokes OnCardStateChange
on that calling thread. An initial observation is included. Intermediate changes may
be coalesced: this API reports current observed state, not a complete transition log.
Returned/event snapshots have copied ATR buffers and preserve the native event counter;
only the transient Changed flag is cleared. Monitoring configuration is pinned until
the monitor stops; set the event handler while it is stopped.

A terminal worker failure is reported by PollChanges as EPcscError after the worker
has been joined. The card connection remains independent. Monitoring being True means
the worker is allocated; it does not guarantee the resource manager remains available.
An event handler can stop monitoring without joining itself, because events are never
dispatched on the worker. The injected IPcscApi must honor finite timeouts, support
concurrent cancellation and avoid exceptions from cleanup calls.

## Example and verification

`examples/pcsc/InspectReader.dpr` supports `--list` or an exact reader name to inspect
its raw ATR. `--help` performs no hardware operation. It sends no application APDU.

The executable test suite uses an injected API for lifecycle, independent instances,
transactions, serialization, shutdown and interface ownership. An isolated C shim
exercises the Windows adapter's native branches on Linux, including 64-bit handles,
Unicode discovery, native structures, bounded buffers and error outputs. This does
not establish Delphi, Windows calling-convention, reader-driver or card compatibility.
Those checks remain required before declaring supported targets/hardware.

Native definitions were checked against the
[Microsoft Windows SDK header](https://github.com/microsoft/win32metadata/blob/main/generation/WinSDK/RecompiledIdlHeaders/um/winscard.h)
on 2026-10-07. Relevant official references:

- [SCardConnectW](https://learn.microsoft.com/en-us/windows/win32/api/winscard/nf-winscard-scardconnectw)
- [SCardTransmit](https://learn.microsoft.com/en-us/windows/win32/api/winscard/nf-winscard-scardtransmit)
- [SCardGetStatusChangeW](https://learn.microsoft.com/en-us/windows/win32/api/winscard/nf-winscard-scardgetstatuschangew)
- [SCardCancel](https://learn.microsoft.com/en-us/windows/win32/api/winscard/nf-winscard-scardcancel)
