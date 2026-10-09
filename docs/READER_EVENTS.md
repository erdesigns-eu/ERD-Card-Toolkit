# Reader and card events

Event-driven applications can use the inactive, non-visual palette components
below. Configure events and properties, and call `Start`/`Stop`, on the main
thread. No constructor opens hardware, starts a thread, or creates a hidden
Windows window.

| Component | Entry point | Events |
| --- | --- | --- |
| `TSmartCardMonitor` (`ERD.Card.PCSC.Monitor`) | `Start`; no reader selection required | `OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`, `OnCardRemoved`, `OnStateChanged`, `OnError` |
| `TSmartCardReader` (`ERD.Card.PCSC.Reader`) | Set `ReaderName`, then `StartEventMonitoring`; `StartMonitoring`/`PollChanges` remains available for manual polling | `OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`, `OnCardRemoved`, `OnCardStateChange`, `OnMonitorError` |
| `THidDeviceMonitor` (`ERD.Card.HID.Monitor`) | `Start`; native Windows device notifications | `OnDeviceAdded`, `OnDeviceRemoved` with the exact HID interface path |
| `TUsbHidInputMonitor` (`ERD.Card.HID.Monitor`) | Set `Device`, then `Start` | `OnInputReport`, `OnError` |

## PC/SC

The monitor uses its own PC/SC context and one native `SCardGetStatusChangeW`
wait for all readers plus the PnP notification reader. The finite 250 ms wait
lets stopping complete if cancellation falls just before a wait. Timeouts do not
cause reader-inventory polling. The reader list is read again only at startup or
when PnP changes. Starting with no connected reader also works.

`EmitInitialState=True` reports existing readers and presented cards at startup.
With `False`, the first observation becomes the baseline without initial events.
A reader that disappears first raises card removal when it contained a card.
Card removal delivers the last known snapshot, including the ATR; `OnStateChanged`
delivers the newly observed state. A native counter change, or a different ATR
while the present status remains set, can also report an observed card
replacement. The monitor does not use card connections or APDUs, changes
nothing, and selects no reader.

```pascal
FMonitor := TSmartCardMonitor.Create(Self);
FMonitor.OnReaderAdded := ReaderAdded;
FMonitor.OnReaderRemoved := ReaderRemoved;
FMonitor.OnCardInserted := CardInserted;
FMonitor.OnCardRemoved := CardRemoved;
FMonitor.OnStateChanged := StateChanged;
FMonitor.OnError := MonitorError;
FMonitor.Start;
```

Reader handlers receive `const AReaderName: UnicodeString`; card handlers receive
`const ASnapshot: TPcscReaderSnapshot`, including `ReaderName`, the raw state, and
an independent ATR buffer. `OnError` receives the original unsigned PC/SC status
or `PcscInternalError` for an invalid backend result or a full queue.

For one selected reader, the existing `TSmartCardReader` can also be used:

```pascal
FReader.ReaderName := SelectedReader;
FReader.OnReaderAdded := ReaderAdded;
FReader.OnReaderRemoved := ReaderRemoved;
FReader.OnCardInserted := CardInserted;
FReader.OnCardRemoved := CardRemoved;
FReader.OnCardStateChange := CardStateChange;
FReader.OnMonitorError := MonitorError;
FReader.StartEventMonitoring;
```

Reader events cover the full inventory; card and state events apply only to
`ReaderName`. `OnCardStateChange` is delivered automatically in this mode.
`StopMonitoring` stops both automatic and manual observation. The older
`StartMonitoring`/`PollChanges` mode remains available, but requires explicit
polling. The two modes cannot be active at the same time. Connections and
transactions remain independent: an event does not connect, reconnect, or read
the card automatically.

## USB-HID and RFID

`THidDeviceMonitor` registers the Windows HID interface class through
`RegisterDeviceNotificationW` and its own hidden window. No VID/PID list or
periodic enumeration is needed. Starting reports only new events; request the
existing inventory once with `EnumerateWindowsHidDevices`. A device can have
multiple HID collections and therefore produce multiple interface events. Native
hotplug notifications require Delphi on Windows; the injectable adapter is also
tested without Windows. Metadata is not invented from an interface path alone.

For continuous read-only input:

```pascal
FInput := TUsbHidInputMonitor.Create(Self);
FInput.Device := CreateWindowsHidReportDevice(SelectedPath);
FInput.OnInputReport := InputReport;
FInput.OnError := InputError;
FInput.Start;
```

The worker opens the explicitly chosen collection once, reads complete interrupt
reports with a finite timeout, and closes on stop or failure. Reports contain the
Windows ID byte; they are not filtered by an arbitrary ID or interpreted as a
card protocol. Only `EHidReceiveTimeout` after completed cancellation is a normal
follow-up wait condition. Other errors stop the listener, close the device, and
deliver one sanitized `OnError`. No output or feature commands are sent or
retried automatically.

A handler can call `TRfidHidReportReader.FeedReport(AReport, GetTickCount64)`
when the reports match its explicit decoder profile. The decoder reports complete
identifiers through `OnIdentifier`. For keyboard-wedge readers,
`TRfidKeyboardReader.FeedCharacter` plus `OnIdentifier` remains usable. Windows
can own keyboard collections exclusively; native report access is then
unavailable.

Removing a HID device is not physical card removal. Ordinary keyboard/ID readers
often provide only the read ID; that does not imply a presence sensor. Card
removal is available only with a reader protocol that actually supplies that
information. PC/SC provides card events when the relevant driver reports that
state.

## Delivery and lifecycle

PC/SC and input-report workers deliver their events on the main thread with
`TThread.Queue`. A VCL message loop handles that automatically. Console and
service hosts use the standard RTL dispatcher `CheckSynchronize`; no custom
reader polling is needed. HID hotplug events arrive directly through the owner
thread window.

`Stop` is repeatable: first pending callbacks are invalidated, then waiting is
stopped, the worker is joined, and its context or device is released. A handler
may stop or free the monitor; remaining events from the same batch are then
discarded. Terminal worker failures stop before the error event. Restarting is
an explicit application choice. The queues keep at most 1024 notifications; a
full queue becomes a terminal error, without unbounded memory growth or silent
event loss. Event-handler exceptions are not hidden; handle errors in your own
handlers.

Observations follow the driver: very short intermediate transitions can be
missed. Use card events to start work, but run blocking card operations in a
worker. Only PC/SC and HID are monitored here; arbitrary COM readers do not get a
fictional card-presentation protocol.

ReaderToolsDemo and UsbHidDemo each have their own DFM buttons and a separate
event log. ReaderToolsDemo updates its reader selection through hotplug events;
UsbHidDemo refreshes metadata after a hotplug notification once any operation or
input listener has stopped. Neither demo connects or writes automatically on an
event.

All PC/SC family demos and SmartCardDemo now start native observation when shown.
Their own reader comboboxes update from inventory events; each family DFM has a
separate presence label. Refresh explicitly restarts observation. ReaderToolsDemo
retains its own Watch/Stop buttons and detailed log. The shared
`ERD.Card.Demo.ReaderEvents` helper contains no form or visual controls. Worker
timers only collect explicit operation completion; they do not poll card presence.
