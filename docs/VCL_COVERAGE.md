# VCL examples: current coverage

There are **twenty-eight separately executable applications** in
`examples/vcl/CardDemos.groupproj`. Each application has its own `TForm`,
`.Main.pas`, and `.Main.dfm`. All visual controls are in that application's own
DFM, including input fields and action controls. Hardware demos include reader
selection; the offline calculator requires no reader or worker timer. There is
no shared form and no shared form ancestor. Only non-visual card execution, input
metadata, and worker lifecycle remain shared. Payments are outside this component
set.

| Project | Included features |
| --- | --- |
| MagStripeDemo | Tracks and MSR206-7HL reads/verified writes |
| SmartCardDemo | Existing combined PC/SC, eID, EMV, contactless, memory, and RFID pages |
| EmvCalculatorDemo | All EMV calculator operations, explicit scheme/CVN profiles and transaction fields, AC/ARPC verification; entirely offline |
| CardCatalogDemo | Valid ATR/tag/path/APDU/AID inventories and offline lookup; native reader/card events and offered ATR inspection without connecting |
| ReaderToolsDemo | Native reader/card events with its own DFM controls and event log; PC/SC list/status, APDU command/response, ATR/catalog, BER-TLV, EMV tags, and NDEF codecs |
| MemoryCardDemo | All SLE/I²C models, two ACS dialects, snapshots/ranges, PIN, writes, PIN replacement, and permanent protection |
| SleCounterDemo | Public windows, bit/carry/backup programming, and raw certificate calculation |
| Sle4404Demo | Known layout/counters, supplied-code reads/proof, bit programming, scratchpad and application erases |
| Twn4Demo | PRS/CDC version/tag, supplied-key Classic, and public Type 2 reads/verified writes |
| RfidInputDemo | Foreground keyboard, boot/ID/fixed-ASCII reports, ASCII/hex/decimal profiles, and byte conversion |
| SimCardDemo | Classic SIM/UICC-USIM, files/records/identities/services, PIN/PUK status, verify/change/unblock, ADN contact writes, PBR/IAP/EXT contact reads, explicit linked record plans, alpha/EMAIL/ANR/SMS/segment codecs |
| MifareClassicDemo | UID, offline layout/trailers, supplied-key block reads, and status-only data writes |
| TopazDemo | Topaz 96/512 full memory/locks, byte-range reads and verified writes, initialized parsed Type 1 NDEF replace/clear; own DFM, reader selection and native events |
| FelicaDemo | Explicit 212/424 kbit polling, FeliCa service block reads/verified writes, Type 3 attributes and NDEF with Text/URI interpretation |
| Type2Demo | Ultralight/EV1/NTAG210/212/213/215/216, UID/page/memory, public NDEF, ACR122 PWD_AUTH/PACK user access, verified configuration/credential management, supported counter reads and protected NDEF |
| UltralightCDemo | Supplied 16-byte key, mutual authentication, exact pages 4–39, full 144-byte memory and verified user-page writes through ACR122 raw RF |
| Type4NdefDemo | Offline CC, mapping 1.0/2.0, file descriptors/FID, public NDEF read/write/clear |
| EmvDemo | PSE/PPSE, PDOL inspection, explicit AID/terminal values, GPO/AFL records plus bounded extra SFI/record scan, visible raw records/statuses, GET DATA, advertised logs, DOL/log decoders, and exact exports |
| BelgianEidDemo | All public sections, identity/address, JPEG, RAW/DER certificate export, and raw signature export |
| IcaoDocumentDemo | BAC/PACE with MRZ/CAN/curve/provider, all document sections/face images, CardAccess/DG1/DG2/COM/SOD export, JPEG preview, and JPEG2000 export |
| Slix2Demo | Supplied SLIX2 read/write passwords, physical data and parsed Type 5 NDEF; decoded AB protection, password replacement and page protection verified after RF reset; own reader/events form |
| St25DvDemo | Original ST25DV RF passwords, ordinary/extended blocks and parsed Type 5 NDEF; decoded RF areas, configuration/user-password replacement and area policy verified after RF reset; own reader/events form |
| Iso15693Demo | ACR1552 explicit address/response dialects, UID/geometry, block reads/verified writes, and Type 5 NDEF read/write/clear |
| UidProgrammingDemo | PC/SC Gen2/FUID; ACR122 Gen1a/Gen1b/unsealed UFUID, DirectWrite, Gen3, six Gen4 layouts, USCUID/GDM, and partial UFUID/ZUID/PFUID |
| DesfireDemo | Public/EV1/EV2 AES, EV1 2K3DES/3K3DES and D40 DES/2K3DES, directories/data/values/records, standard writes, backup/value/record transactions with commit/abort, application/file create-delete across those profiles, explicit new application key type/count, AES key/access-policy mutations |
| MagStripeProfilesDemo | Track bit/parity/LRC and financial decoders, MagTek keyboard/HID, MSR206/MSR605 reads, and status-only all-track programming |
| UsbHidDemo | Reader hotplug and continuous input-report events with its own DFM controls/event log; native HID collections/VID/PID/usage/lengths, exact interface path, interrupt and feature report read/send/export |
| MobibDemo | Calypso legacy-94/revision-3-00, MOBIB file profile and custom FID plan, explicit FID/record reading, holder/events, subscription versions 0–4 with tariff/price/duration/counter assignment, native SAM authentication with two reader choices, offline activation/validity/zone evaluation with an explicitly sourced profile, raw data/status/truncation, and exact exports; no implicit issuer rules |

All PC/SC demos automatically observe reader hotplug and card insertion/removal through
native events. Their own DFM status label shows presence; the worker timer only
collects explicit operation completion. Observation never connects, authenticates or writes.
The shared event bridge is nonvisual. Refresh devices explicitly restarts observation.

## Reader selection in every demo

Hardware demos fill their own dropdown through background discovery or native
reader events and have their
own refresh button. PC/SC demos show installed smart-card readers; TWN4 and
magstripe show present Windows COM ports; RFID/native HID show HID collections
with VID/PID/usage. The visible name and operational address remain linked. No
reader is preselected. On refresh, the selection is kept only when the same
reader is still present; an error clears the old list.

Detection does not open a card connection or send card commands. COM detection
does not prove that a port is a suitable writer; choose the correct protocol.
HID collections are likewise not automatic card writers. Foreground keyboard
capture receives Windows keystrokes and does not filter a separate USB device;
native HID report I/O does use the selected interface path.

## Behavior you can reuse

- Hardware work runs on the shared background worker; the thread starts only
  after construction. Every action requires concrete input and opens no hardware
  during form construction.
- Writes, PIN attempts, and management require an explicit acknowledgement.
  Card/reader profiles are not detected through programming attempts.
- Credential buffers are copied at the thread boundary and wiped locally. Error
  messages do not show card data or keys. An error leaves no new exports behind.
- A vendor status is named separately; HID transfer and MSR206/MSR605 status are
  not independent proof of card read-back. Uncertain writes are not retried.
- Photos/files are saved only after successful acquisition and an explicit Save
  choice. JPEG2000 remains exact, with no conversion.

## Limits of these examples

Generic HID transports reports; a vendor protocol decides which card functions
they mean. Keyboard-only EM4100/TK4100 readers therefore do not get memory write
support. Windows can deny raw access to keyboard collections. Foreground keyboard
input remains available for that in RfidInputDemo.

SIM linked writes use an explicit, complete record plan; the demo does not
automatically allocate free contact/EXT/EMAIL records. DESFire shows one retained
transaction per job; this UI is not a session that remains alive between separate
button clicks. NDEF demos do not change lock bits, formatting, passwords, or
access rights outside the offered family methods. Photo/certificate export does
not perform passive eID or certificate trust validation.

The projects share the repaired BOM/CRLF and MSBuild conventions. Reproducible
build and validation commands are in [VCL_DEMOS.md](VCL_DEMOS.md) and
[VALIDATION.md](VALIDATION.md).
