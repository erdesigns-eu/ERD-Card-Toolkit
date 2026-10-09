# Native Windows USB-HID reports

`ERD.Card.HID` supplies `EnumerateWindowsHidDevices`, the inactive
`CreateWindowsHidReportDevice` factory and `TUsbHidReaderWriter`. They are included
in ERDCardInput and the standalone ERD Input palette. There is no brand/VID/PID
allowlist, frequency inference or guessed reader protocol.

Enumeration uses SetupDi's HID interface class, Unicode paths, `HidD_GetAttributes`
and `HidP_GetCaps`. Each result is a top-level collection with exact input/output/
feature lengths, USB identifiers and HID usage. Collections whose metadata cannot
be opened are omitted. The app chooses an exact path; no device is auto-selected.

`ReadReport(hrkInterrupt, id)` reads one queued input report with ReadFile.
`ReadReport(hrkFeature, id)` requests that explicit feature ID with HidD_GetFeature.
`SendReport` uses WriteFile for output or HidD_SetFeature for features. Buffers
include Windows' report-ID byte, even zero for unnumbered reports, and must equal
the descriptor's maximum size for that endpoint. Reports are bounded to 4096 bytes.
No automatic padding, retries, alternate-ID probing or discarded-report loop occurs.

```pascal
uses ERD.Card.HID;

Reader := TUsbHidReaderWriter.Create(nil);
try
  Reader.Device := CreateWindowsHidReportDevice(ChosenDevicePath);
  Reader.TimeoutMs := 3000;
  Report := Reader.ReadReport(hrkInterrupt, ExplicitReportId);
  // Decode the complete report using the actual documented descriptor/protocol.
finally
  Reader.Free;
end;
```

The component acquires/releases one handle per operation. Applications needing a
continuous report sequence can retain the factory's `IHidReportDevice`, call
Open(False), Receive repeatedly and Close once, preserving primary errors during
cleanup. Feed complete known-format reports into `TRfidHidReportReader`; boot
keyboard bytes delivered by Windows include the explicit zero/nonzero ID and
therefore use `rhkBootKeyboardWithId`. Arbitrary vendor/NKRO descriptors require
an explicit decoder; an unknown report is never interpreted as a UID automatically.

Interrupt transfers use a fresh OVERLAPPED/event. Timeout/wait failure cancels
that operation with CancelIoEx and drains completion before releasing its buffer,
event or handle. The wait budget does not impose a hard deadline on a defective
driver's cancellation. Feature requests are synchronous and have driver-controlled
duration. Component/device instances are single-threaded and not reentrant.
Handles permit normal Windows sharing; the API does not claim process-wide
exclusive hardware ownership.

After attempted Send, transfer/rejection/release failure raises EHidSendUncertain.
Do not replay blindly. A successful HID transfer means bytes were accepted by the
HID layer, not that a vendor command or card write succeeded. Interpret the actual
vendor reply and acquire independent card read-back through that vendor protocol.
Local output copies are overwritten on exit; copies in drivers/backends are outside
that guarantee. Plain report input/outputs are not encrypted by this transport.

Windows keyboard-driver ownership can deny raw ReadFile access even when metadata
is enumerable. Use the existing foreground keyboard component for keyboard-only
readers. EM4100/TK4100 scanners that only type an ID do not acquire a card-memory
write interface through this API. ELATEC TWN4 PRS/CDC remains its separately
documented reader protocol.

`UsbHidDemo` demonstrates enumeration, exact reports and explicit export. Portable
contract tests cover acquisition/cleanup, ID/length checks, copied output, wiping,
reentrancy, rejection and uncertain submission. The Linux C ABI shim exercises the
actual native-call branch, structure sizes, Unicode interface detail layout,
interrupt/feature calls, cancellation/drain and handles. This is an ABI/ownership
check, not execution against Windows drivers.

References: [Microsoft HID user-mode applications](https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/introduction-to-hid-concepts),
[HIDP_CAPS](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/hidpi/ns-hidpi-_hidp_caps),
[SetupDiGetDeviceInterfaceDetailW](https://learn.microsoft.com/en-us/windows/win32/api/setupapi/nf-setupapi-setupdigetdeviceinterfacedetailw),
[CancelIoEx](https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-cancelioex).
