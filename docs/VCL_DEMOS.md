# VCL read/write demos

Thirty applications demonstrate implemented APIs: SmartCardDemo,
MagStripeDemo, twenty-five family projects and three independent offline-tool demos. Each application owns a direct TForm
class and its own designer-editable Main.dfm, including all action inputs and a
reader dropdown where hardware is involved. EmvCalculatorDemo is fully offline;
CardCatalogDemo uses native reader/card snapshots rather than card commands.
Only nonvisual operation, metadata and worker/controller units are shared.
The complete current/missing coverage is recorded in
[VCL_COVERAGE.md](VCL_COVERAGE.md).

Open `examples/vcl/CardDemos.groupproj` or any application's `.dproj` in RAD
Studio. They link source directly, so installing the component palette is optional.
From a RAD Studio command prompt:

```bat
tools\build-vcl-demos.cmd dcc32
tools\build-vcl-demos.cmd dcc64
```

The scripts build the `.dproj` through MSBuild, including generated application
resources and the same configuration settings used by the IDE.
Executables go to `dist/vcl/<Platform>/Debug`, with separate DCUs for each demo.
IDE/MSBuild Release builds go to the corresponding Release directory. These are
Windows VCL applications; they have not been built or rendered in the Linux cloud
environment. The provided scripts are an executable validation path for a Delphi
host, not evidence that those builds already pass.

PC/SC demos start native reader/card observation when shown. Their own reader
combobox updates on reader arrival/removal; presence is displayed independently
of card-operation output. Refresh explicitly restarts observation, and no event
starts authentication, reading or writing. ReaderToolsDemo additionally exposes
Watch/Stop controls and a detailed event log. Shared observation code is nonvisual.

## Separate family projects

All family forms construct without opening hardware. Their first OnShow starts
background discovery of reader names, HID metadata or COM aliases; no card
connection or card command is issued. Choose a device in the demo itself and
refresh there. Choose one action; its named fields appear below. Enum choices
have no default card/reader profile. Public bytes use hexadecimal text; numeric
addresses/counts use decimal unless the label
says hexadecimal. Credentials are masked, decoded into separate byte buffers,
copied at the worker boundary, cleared from input controls after submission and
wiped from owned buffers after execution. Strings/OS/backend copies are outside
that byte-buffer wiping guarantee. Errors display their class, never backend text.

| Project | Actual actions |
| --- | --- |
| `globalplatform/GlobalPlatformDemo.dproj` | Native reader/card events, explicit SCP02/SCP03 authentication, CPLC/registry and CAP/DAP load/install/delete/status/extradition, key management and RSA/AES token/receipt policies; snapshotted background worker |
| `emvsemantics/EmvSemanticsDemo.dproj` | Offline AIP/AUC/TVR/IAC/CVM List with explicit Book 3 4.3/4.4; no reader required |
| `emvcalculator/EmvCalculatorDemo.dproj` | All offline key/MAC/AC/ARPC/script/PIN calculations; explicit CVN transaction inputs and verification |
| `cardcatalog/CardCatalogDemo.dproj` | Filterable complete valid ATR/tag/path/APDU/AID inventories, offline lookup, native reader/card events and offered ATR snapshot |
| `readertools/ReaderToolsDemo.dproj` | Offline command/response APDU decode/encode, validated ATR/protocol/catalog hints, decoded BER-TLV tree/roundtrip, EMV tag metadata, NDEF roundtrip; PC/SC reader list and connected ATR/protocol |
| `rfidinput/RfidInputDemo.dproj` | Offline ASCII/hex/decimal identifier inspection and explicit width/order conversion; live foreground keyboard capture; decoding host-provided boot 8-byte, report-ID 9-byte and fixed ASCII reports |
| `twn4/Twn4Demo.dproj` | Explicit PRS/USB-CDC port, CRC and deadline; version/tag identity, supplied-key Classic block reads/data writes, public Type 2 user-page reads/writes; ID/expected-state/read-back checks |
| `memorycard/MemoryCardDemo.dproj` | ACS capabilities, all implemented SLE/I2C snapshots/ranges, supplied PIN proof, verified writes with physical I2C page size, supported two-wire PIN replacement, irreversible compare-and-protect |
| `slecounter/SleCounterDemo.dproj` | Explicit SLE4406/4436/5536/6636/window, public range reads, program/carry/backup modes with expected complete before/after windows, raw certificates; credential-bearing code command validation offline only |
| `sle4404/Sle4404Demo.dproj` | Known window/layout/retry budgets, reads with optional supplied user code, user-code proof, one-to-zero programming, scratchpad erase and application erase with both supplied codes |
| `simcard/SimCardDemo.dproj` | Classic SIM/UICC-USIM files, records, identities and services; PIN/PUK status, verify/change/unblock, ADN contact writes, PBR/IAP/EXT contact reads, explicit linked-record plans, alpha/EMAIL/ANR/SMS/segment codecs |
| `mifareclassic/MifareClassicDemo.dproj` | UID, offline layout/trailer inspection, supplied-key block reads and status-only data writes |
| `topaz/TopazDemo.dproj` | Topaz 96/512 identity, memory/locks, byte-range reads, verified user writes and initialized Type 1 NDEF read/parse/replace/clear |
| `felica/FelicaDemo.dproj` | Explicit 212/424 kbit FeliCa polling, service block reads/verified writes and Type 3 attribute/NDEF read/replace/clear |
| `type2/Type2Demo.dproj` | Ultralight/EV1/NTAG210/212/213/215/216 UID, page and memory reads, public NDEF, ACR122 PWD_AUTH/PACK user access, verified configuration/credential updates, counters and protected NDEF |
| `ultralightc/UltralightCDemo.dproj` | Supplied-key 2K3DES authentication, exact user-page/full-memory reads and independently verified page writes |
| `type4ndef/Type4NdefDemo.dproj` | Offline CC, mapping 1.0/2.0, file descriptors/FID, public NDEF read/write/clear |
| `emv/EmvDemo.dproj` | PSE/PPSE, PDOL inspection, explicit AID/terminal values, GPO/AFL records, bounded SFI/record scan, raw records/statuses, GET DATA, advertised logs, DOL/log decoders and exact exports |
| `belgianeid/BelgianEidDemo.dproj` | Public sections, identity/address/photo, JPEG preview, RAW/DER certificates and raw signature exports |
| `icaodocument/IcaoDocumentDemo.dproj` | BAC/PACE with MRZ/CAN/curve/provider, document sections and face images, CardAccess/DG1/DG2/COM/SOD exports, JPEG preview and JPEG2000 export |
| `slix2/Slix2Demo.dproj` | Supplied SLIX2 read/write passwords, physical blocks, parsed Type 5 NDEF read/replace/clear |
| `st25dv/St25DvDemo.dproj` | Original ST25DV RF user password, ordinary/extended physical blocks, parsed Type 5 NDEF read/replace/clear |
| `iso15693/Iso15693Demo.dproj` | ACR1552 explicit address/response dialects, UID/geometry, block reads/verified writes and Type 5 NDEF read/write/clear |
| `uid/UidProgrammingDemo.dproj` | PC/SC Gen2/FUID; ACR122 Gen1a/Gen1b/unsealed UFUID, DirectWrite, Gen3, six Gen4 layouts, USCUID/GDM and partial UFUID/ZUID/PFUID |
| `desfire/DesfireDemo.dproj` | Public/EV1/EV2 AES, EV1 2K3DES/3K3DES and D40 DES/2K3DES, directories/data/values/records, standard writes, backup/value/record transactions with commit/abort, application/file create-delete across those profiles, explicit new application key type/count, AES key/access-policy mutations |
| `magstripeprofiles/MagStripeProfilesDemo.dproj` | Track-bit/parity/LRC and financial decoders, MagTek keyboard/HID, MSR206/MSR605 reads and status-only all-track programming |
| `usbhid/UsbHidDemo.dproj` | Reader hotplug and continuous input-report events, native HID collection metadata/VID/PID/usage/lengths, exact interface path, interrupt and feature reports read/send/export |
| `mobib/MobibDemo.dproj` | Calypso legacy-94/revision-3-00, MOBIB file profile and explicit FID plan, holder/events and subscription decoding, two-reader SAM authentication, offline activation/validity/zone assessment, raw exports |

For PC/SC operations select the reader from **this demo’s own dropdown**.
Discovery runs on opening and can be refreshed without another application.
An ACS dialect is a known protocol configuration, not a guess from the name/ATR.
TWN4 uses its own discovered-COM dropdown and suitable Simple Protocol firmware;
it does not send memory commands to keyboard-only HID readers. Firmware changes
are not made by the demo. See [TWN4.md](TWN4.md) and
[memory profiles](MEMORY_CARDS.md).

State-changing/code-attempt actions require per-submission acknowledgement. This
is cleared after each request. Permanent protection, code consumption and erase
are explicitly named actions, with no automatic retries. Expected-before fields
must contain the actual bytes from the selected card/window. A counter-mode write
requires the full expected-after window; the demo does not calculate carry rules.
An application erase requires known user/memory-counter locations and a non-erased
expected application area so the component can prove the supplied memory code.

The worker executes the actual component once against a deferred connection.
Its argument validation runs before the component requests a transaction, channel
open or cryptographic provider. The connection then delegates to the selected real
adapter. Successful validation does not throw an exception or replay the action.
Card-state checks happen after connection, under the component's transaction.
Uncertain writes preserve any independently completed verification; a later
cleanup failure does not turn them into a clean success.

RFID live capture runs on the UI thread and requires focus in its dedicated memo.
It receives ordinary foreground keyboard events, without device identity/filtering,
USB enumeration or a global hook. Start freezes configuration until Stop. Enter
provides CR; boot-report profiles support CR/Tab. The fixed ASCII report profile
uses each report as a complete field and applies the explicitly configured framing.
Raw reports must be supplied by a host or pasted for inspection: this is not a
native USB reader driver.

### Family smoke tests on Delphi/Windows

1. Build Debug/Release in Win32 and Win64 and open the family projects you are
   validating. ReaderTools' first APDU action and RFID's first text action work
   without a reader. Other demos must refuse incomplete reader/profile/window/port
   inputs without I/O.
2. ReaderTools: confirm `00A4040000`, response `01029000`, ATR `3B00`, TLV
   `5A021234` and NDEF `D101055402656E4869` round-trip. A corrupt ATR/TLV/NDEF is
   rejected; known `5A` shows catalog metadata without sending an EMV command.
3. RFID text: Decimal `001234`, width 4, big endian produces `000004D2`. For boot
   reports use CR framing and paste `00001E0000000000;0000000000000000;0000280000000000`;
   exactly one identifier `1` completes. For fixed ASCII choose four report/field
   bytes, offset zero, no report ID and NUL padding; `30303100` produces `001`.
4. Live RFID: start CR capture, focus the memo, scan/type a complete identifier.
   Partial input, malformed input and timeout tails must not emit identifiers.
   Configuration stays frozen; Stop/close releases capture without a worker thread.
5. With confirmed ACS hardware, start with public reads and independently compare
   them to known card bytes. Then use expendable cards and known supplied codes for
   supported writes/PIN changes/protection/erases. Confirm retry budgets, exact
   expected windows and independent proof; locked/incorrect states must be refused.
6. With confirmed TWN4 PRS/CDC firmware, explicitly select port/CRC, inspect version
   and tag ID, then test the supported memory operations on expendable tags. An
   incorrect expected ID/prestate must not dispatch a write. Trailer/manufacturer/
   configuration writes remain refused by the component.
7. While a hardware worker is active, request another action/close. The form must
   freeze inputs, refuse concurrent work and wait for completion on close. Exercise
   disconnect/cleanup errors: uncertainty and completed proof must remain distinct,
   with no automatic retry or credential-bearing exception text.

The synthetic family executor tests cover offline codecs, valid-action preflight,
choice/PIN/acknowledgement rejection before hardware, literal memory/counter/SLE4404
and TWN4 transcripts, uncertain writes and evidence after cleanup failure. Worker
tests additionally verify nested credential copies/wiping and argument-array
ownership. They do not compile/render VCL or validate physical cards.

## SmartCardDemo

The initial operation inspects the included synthetic `Hi` NDEF Text message
without accessing hardware. `Encode text` generates a UTF-8 Text record with the
explicit language `en`. `List readers` enumerates PC/SC readers on a worker; it
does not connect a card or pick a reader automatically. Select or enter its exact
name before choosing a card operation.

| Operation | Required selection / scope |
| --- | --- |
| UID | Explicit PC/SC storage profile using `FF CA`; requires a compatible reader |
| Belgian eID | Contact-card identity/address/photo through the implemented Belgian profile |
| ICAO document | Explicit BAC or PACE ECDH-GM/AES-128, MRZ information or CAN, PACE parameter 12/13, and an OpenSSL 3 library matching the executable architecture |
| EMV PSE / PPSE | Explicit contact/contactless directory discovery; displays AIDs without starting payment or issuing GPO |
| DESFire | Public native version only; secure administration remains in the console examples |
| Type 2 NDEF read / replace | Explicit actual Ultralight/EV1/NTAG model, compatible `FF B0`/`FF D6` storage reader |
| Type 4 NDEF read / replace | Mapping 2.0, uniquely selectable public NDEF file; no automatic formatting or authenticated-file inference |

ICAO MRZ input is the 24-character MRZ information string: document-number field
and check digit, YYMMDD birth date and check digit, YYMMDD expiry and check digit.
CAN is six decimal digits and requires PACE. Use the ICAO/MRZ codecs when deriving
this input in your application. Select the access settings explicitly; there is
no PACE-to-BAC fallback. BAC/PACE provides file access and secure messaging, not
issuer authenticity. SOD verification and national-service/EAC integration remain
separate future work; not every European identity card exposes this LDS profile.

Identity text stays in the result memo. JPEG is previewed on the UI thread;
JPEG 2000 is retained without conversion. `Save encoded photo` writes those acquired
bytes only after file selection. The demo retains the first ICAO face image; the
component API returns all images. A new operation clears the previous face result.

`Replace ... + verify` explicitly replaces existing NDEF using the component's
write and independent read-back checks. It does not format unknown tags or unlock
protected data. Successful replacement shows the canonical wire message that was
written. An uncertain-write exception is displayed as uncertain; the demo never
repeats a write automatically.

## Contact-memory page

The exact reader selector remains above both tabs. The new memory tab exposes:

| Operation | Inputs and scope |
| --- | --- |
| Offline profile capabilities | Explicit ACR38x CCID/ACR39 dialect only; no device is opened or reader support detected |
| Connected ATR / protocol | Exact reader; displays raw ATR and actual negotiated T=0/T=1, without probing memory commands |
| Memory snapshot / range | Explicit SLE/I2C model and matching dialect; snapshot includes protection/retry status without attempting a PIN |
| Verify supplied PIN once | Explicit PIN-equipped model, card-order hexadecimal PIN and minimum remaining attempts |
| Write range + verify | Explicit range/payload and change acknowledgement; supplied PIN for secured SLE, empty for plain SLE/I2C; explicit physical page size for I2C |
| SLE4404 snapshot / range | ACR38x CCID and known readable window; public reads only; guarded codes/erases are separate API calls |
| Counter snapshot / range | SLE4406/4436/5536/6636, ACR38x CCID and application-known readable window; public reads only in this demo |

No model or dialect is automatically selected. PIN and write payload arrays are
copied before the worker starts. PIN input and change acknowledgement are cleared
after starting. PIN bytes and backend exception messages are not displayed.
Snapshot/range hex and protection are shown only after successful operation cleanup.
An uncertain memory write remains visible as uncertain; read-back proof is retained
if only later transaction/connection cleanup fails. The demo does not repeat it.

For an initial hardware check, inspect offline capabilities, obtain the connected
ATR/protocol, then read a known public range. Compare the snapshot to a known image.
Use disposable cards and a known unlocked location for deliberate writes; check
protection and retry budget first. Counter programming/carry, permanent locking
and PIN replacement are component APIs rather than buttons on this page.

## MagStripeDemo

`Inspect tracks offline` validates selected unframed payloads and reports bit counts
including odd parity and LRC. Do not include sentinels or an LRC character in the
editable track fields. Empty payloads are allowed by the offline codec.

Hardware operations use only the explicit **MSR206-7HL** serial adapter at
9600 baud, seven data bits, odd parity and one stop bit. Select the connected
device from this demo’s COM dropdown, selected tracks and a timeout between
1 and 600000 ms. `Read one swipe` updates only the selected track fields.
`Write selected + verify` additionally requires nonempty payloads and an
explicit low/high coercivity choice. It uses the verified
writer, which returns independent same-swipe raw read-back rather than treating a
status acknowledgement as proof of the programmed contents. Firmware and physical
reader validation are still pending. Other magstripe backends remain accessible
through the component API and console examples; this demo does not guess their
physical model or protocol.

## Threading and smoke checks

Every operation owns its components, transport and backend on a worker thread.
`TCardDemoJob` copies access/NDEF bytes before starting, clears its owned access
password after execution, and moves results to the form once under a lock. Polling
uses a VCL timer; the worker neither touches controls nor queues callbacks that
could outlive a form. Closing during an operation waits for completion. There is
no forced abort, and a blocking driver may extend this wait; the serial swipe
bound is not a PC/SC timeout. Writes are never cancelled or retried behind the UI.
Access input is cleared after starting, but this is not a guarantee of erasure
of the Windows edit control's or Delphi strings' historical allocations.

The job constructor creates a suspended worker. The nonvisual controller calls
`StartWork` only after construction returns, so Delphi's
`TThread.AfterConstruction` finishes before the explicit start. Starting inside
the constructor caused the reported EThread exception in both demos. A second
start is refused; freeing a never-started job does not execute its request. If
starting fails, the controller releases the job and restores its controls. This
follow-up has passed the headless worker tests; a
Delphi/Windows rebuild and retest of both demos is still required.

On a Delphi/Windows host, check both platforms: open both forms, inspect/encode
NDEF and raw tracks offline, enumerate readers with no card, and close while a job
is active. Then use known disposable test cards and the correct explicit profile
to verify identity/photo acquisition, NDEF replacement and magstripe read-back.
Also check missing reader/card, unsupported profile, driver failures, closing while
waiting for a swipe, and ambiguous write results. Verify designer DFM loading,
Help Insight for public APIs, and layout at your target DPI. These IDE/hardware
checks remain outstanding; see [VALIDATION.md](VALIDATION.md).

## RFID keyboard page

Select **RFID keyboard** in SmartCardDemo. Choose the actual output format
(ASCII, hexadecimal or decimal) and terminator (CR is the default). The four
settings underneath are exact identifier length (zero means variable), maximum
inter-character gap in milliseconds, exact prefix and exact suffix. Start capture,
then scan while the dedicated input box has focus. Stop capture before changing
configuration or using PC/SC pages. Leading zeros/case are preserved; only explicit
hexadecimal mode produces bytes. Repeated scans each produce an event.

Test correct scans, wrong length, partial/slow scans, mismatching delimiters and
recovery after a complete delimiter. This is foreground keyboard input: a physical
keyboard can also type into it and the source device is not authenticated. Reader
keyboard layout must match Windows. This page does not open raw USB, configure
reader firmware or write cards. Raw-report applications can use the distinct
[host-fed HID profiles](RFID_HID.md). Native Delphi/UI/device checks remain pending.

## SimCardDemo

Use a contact PC/SC reader with a SIM adapter. First choose the exact classic SIM
or UICC profile; read ICCID and, for UICC, EF.DIR before entering a complete AID.
The demo does not choose an application automatically. See [SIM.md](SIM.md) for
paths. PIN input is ASCII hex (`31323334` for `1234`), not BCD.

First test offline ICCID `981032547698103254F6` → `8901234567890123456` and
alpha `414C494345FF` → `ALICE`. Then check reader/ICCID, metadata and read-only
records. Test writes only with a test SIM and the exact before-bytes that were
read back. The read-back status and any cleanup uncertainty must remain visible.
Standalone contacts with CCP/EXT links are explicitly refused. The offline SMS
text action decodes a complete EF.SMS record, including UDH. The linked-contact
action uses an explicit PBR record/ADN FID and shows IAP/EXT. Raw SMS records are
fully preserved; there is no SMS send action. Build the demo group for
Win32/Win64; the shared executors now also use `src/sim`.

## MifareClassicDemo, Type2Demo and Type4NdefDemo

These projects explicitly use the PC/SC storage profile (Classic/Type 2) or ISO
APDUs (Type 4). Reader support for that profile is required.

- Classic: check the offline layout/trailers, select the actual model, block,
  reader slot and supplied A/B key. Read first. Manufacturer and trailer writes
  remain refused by the component. The write action returns reader status only;
  read again yourself for separate verification.
- Type 2: choose the actual Ultralight/EV1/NTAG model. Read a physical page or
  the full user area. Page writes are status-only; replacing or clearing NDEF
  uses the existing full read-back verification. The ACR122 actions perform an
  explicit PWD_AUTH with four password bytes and two expected PACK bytes;
  authenticated writes are read back.
- Type 4: inspect offline CC `000F20003A00340406E10401000000`. On hardware,
  choose mapping 1.0/2.0 explicitly; read CC and select the actual FID
  (decimal 57604 for E104). FID 0 works only with an unambiguous CC. Proprietary
  access rights are not treated as public NDEF.

No constructor opens hardware. Test acknowledgement, invalid models/keys and
protected pages before writes on test cards; uncertain outcomes must not be
repeated.

## BelgianEidDemo, IcaoDocumentDemo and EmvDemo

Each dedicated DFM form has a selector for exactly acquired files and an explicit
Save dialog with an overwrite prompt. There is no automatic export path. Failed
jobs publish no export files. Belgian eID and ICAO show selected JPEG photos;
JPEG2000 remains exactly exportable as .jp2 without codec conversion.

BelgianEidDemo: choose all public sections or identity/address/photo/certificates/
signatures. Missing certificates have explicit states; available certificates can
be exported as original RAW and DER. There is no issuer trust claim.

IcaoDocumentDemo: choose BAC/PACE, MRZ/CAN, curve and supplied password as
ASCII hex plus the OpenSSL library. Read obtains DG1/DG2/COM/SOD and, where
applicable, CardAccess; every face image appears in the selector. Offline
CardAccess works without a card.

EmvDemo: choose PSE/PPSE explicitly; there is no directory fallback.
ReadApplication takes AID and terminal values `taghex=valuehex;...` without
invented PDOL values. GPO initializes reading, not payment. FCI/GPO/records are
exportable; GET DATA counter/log format and advertised transaction log remain
optional. Offline DOL and raw-log decoding show exact tags/values without payment
interpretation.

## Iso15693Demo, UidProgrammingDemo and DesfireDemo

ISO 15693 uses the existing ACR1552 FF-FB profile. Choose ordinary/extended block
addressing and native-flags/payload-only according to the reader firmware. Raw
writes reserve blocks 0/1; Type 5 handles structured NDEF updates.

UID programming requires the actually present variant and existing emulation
layout. Gen3/Gen4 use the ACR122 raw backend with automatic RATS off. Gen4
preserves its configuration; USCUID/partial profiles do not change
personalization/fuses. FUID is an explicit one-time programming action.

DESFire uses public, EV1 AES or EV2 AES with the supplied key and minimum
communication. Optionally enter the separate key for verification in the
secondary context. A transactional action explicitly chooses fresh-reset or
discard-pending, then commit or abort. Each job keeps one session; there is no
implicit commit. Create/delete/access/key actions have their own explicit input.

## MagStripeProfilesDemo and UsbHidDemo

MagStripeProfilesDemo supports offline track bits/parity/LRC, financial fields
(no payment), MagTek unencrypted keyboard/HID and the exact MSR206-3HL Rev G /
MSR605 Rev B serial profiles. Programming requires all three tracks and high/low
coercivity. The outcome names device status without host read-back.

UsbHidDemo enumerates metadata-readable top-level collections regardless of
VID/PID. Copy the exact path, choose interrupt/feature and the descriptor-defined
report ID. Sending requires the full descriptor length including the byte-zero
ID. Interrupt I/O has a wait budget and cancel/drain; synchronous feature
requests have driver-controlled duration. A transfer is not a universal command
to change card memory. Read [USB_HID.md](USB_HID.md) for native integration and
report contracts.


## EMV records and MOBIB

EmvDemo now prints every acquired SFI/record and its raw bytes in the output,
besides offering individual record exports. Use the application-read page, an
explicit AID and required terminal values. The new PDOL-inspection page selects
that AID without GPO and lists the requested tag lengths. For the old CardStudio
style range sweep, select **AFL plus explicit range**, initially SFI 1–10 and
records 1–6. Existing AFL records are not repeated; holes and access restrictions
are reported, while unexpected failures abort. This does not guarantee every
issuer record is accessible. The range can be increased within component bounds.

MobibDemo is a separate designer form with its own PC/SC dropdown, explicit
Calypso dialect/record length and bound. Its three hardware actions read the MOBIB
file plan (editable FIDs), one caller-specified logical file, or one authenticated
logical file through a separately selected provisioned SAM. The SAM dropdown
is populated from the same in-demo PC/SC discovery. Both connections run in the
worker. An explicit layout selector enables known holder/events/counter and
versioned subscription decoding, including tariff, known product names,
sale price/date, optional duration and
associated remaining-trip counters. The authenticated action requires explicit
revision, eight-byte serial, key index, KIF/KVC and an exact existing-record count;
it aborts on missing/restricted/chained responses rather than guessing a MAC
transcript. The snapshot page defaults to a readable summary, with contracts,
purchase amounts/dates, validations, counters and file availability. Its raw-output
selector includes hexadecimal records when needed; every acquired record remains
exportable through the demo's own save dialog in either display mode. Unknown
products and duration units keep their codes without inferred entitlement or expiry.
See [MOBIB_CALYPSO.md](MOBIB_CALYPSO.md) for the concrete files,
status behavior, parsed fields, secure-provider integration and remaining
issuer-specific schemas.

The project group's Build/Make/Clean aggregates cover all twenty-six applications;
the standalone build script includes them too.


MobibDemo also has a fourth independent DFM page for offline operator-rule
assessment. It accepts complete decoded-layout contract bytes, exact policy
tariff/operator/source, explicit clock and time, activation evidence, inclusive
start/exclusive end or fixed elapsed/calendar duration, allowed/requested zones
and an acquired trip counter. No reader connection is acquired for this action.
Blank zone policy means unknown contract zones; `*` explicitly means unrestricted.
It prints each independent check and reason plus resolved dates, without claiming
issuer authorization. See [MOBIB_CALYPSO.md](MOBIB_CALYPSO.md) for the native API,
clock domains, contract-duration mappings and application-supplied rule profiles.

## Authenticated NFC-V examples

Open `slix2/Slix2Demo.dproj` or `st25dv/St25DvDemo.dproj`. Each has its own
editable DFM and direct TForm, discovers PC/SC readers inside that application,
and subscribes to native reader/card presence events. Select an ACR1552 FF-FB
reader and the explicit firmware response format. For ST25DV16K/64K choose
extended addressing. Password hex is in RF wire byte order; input is masked and
copied into worker-owned credential buffers. SLIX2 accepts read and/or write
passwords; ST25DV accepts one RF user password number 1..3. No default password
is supplied and no password list is tried.

Pages expose authenticated identity, bounded physical reads (optional native
bulk command), verified data writes and parsed Type 5 NDEF read/replace/clear.
An empty NDEF replacement clears an existing initialized message. NDEF output
shows decoded record types, identifiers and Text/URI content, and the original
message bytes remain available for export. `Iso15693Demo` separately adds a
native-multiple-block tab without a password profile.

Memory/NDEF pages do not change password/protection configuration. The explicit
management pages described below provide those changes. SLIX2 counter block
79 is reserved. A PC/SC transaction release does not clear the tag's RF security
state. A failed SLIX2 password requires a real RF power-on reset before another
attempt. See [the exact profile contract](ISO15693_TYPE5.md).

### NFC-V security management pages

Both own DFM forms now add three pages: decoded public security information,
password replacement and protection configuration. Password replacement requires
old/new credentials in RF wire order. SLIX2 identifiers are 1 (read) and 2 (write);
ST identifiers are 0 (RF configuration) and 1..3 (RF user). Successful output
means the replacement was accepted after an explicit RF power-on reset.

Read protection/configuration first and use its exact hex preimage on the update
page. SLIX2 page protection requires both supplied read/write passwords, pointer
0..78 and RL/WL/RH/WH mask bits 0/1/4/5. ST area policy requires the supplied
configuration password 0 and an active area; area boundaries remain unchanged.
The ST output decodes which areas require passwords and which forbid writing.
If external VCC is on, the ST mutation page requires an explicit stable-power
guarantee; the component does not control that external supply.

RF resets run only for these explicit management actions. Neither ending a
PC/SC transaction nor an ordinary password-session acquisition is advertised as
RF reset. No permanent lock, privacy/destroy or automatic recovery page is added.
See [the exact management contract](ISO15693_TYPE5.md#verified-password-and-protection-management).

## Topaz 96/512 / Type 1

Open `topaz/TopazDemo.dproj`. This application has its own direct TForm/DFM,
reader combobox and native reader/card events. Choose an ACR122U/PN532 FF00 reader,
exact Topaz model and explicit byte-write acknowledgement dialect. Run the full
snapshot action to view/export the UID, complete physical preimage and writable
map. Writes require the same UID and complete preimage, not just the changed range.
The NDEF page decodes records and exports the message; replacement accepts encoded
NDEF hex, with empty input clearing an existing message. The writer preserves CC,
control/lock/reserved bytes and verifies each phase. See [exact mapping, capacities
and native CIU protocol](TOPAZ_TYPE1.md). Formatting/permanent locks are excluded.

## Offline EMV and metadata tools

EmvCalculatorDemo owns its own designer form and exposes every calculation in
[EMV_CALCULATORS.md](EMV_CALCULATORS.md). Select the operation, supply only its
required inputs, and select an explicit scheme/CVN for profile operations.
Full profile transaction fields have their own DFM page. No reader is needed.
Check wrong-length inputs and changed expected AC/ARPC values: calculation errors
clear output, and mismatched cryptograms return false. Clear inputs removes all
entered keys/PINs and result text.

CardCatalogDemo owns a different designer form. Its reader combo is populated by
native reader arrival/removal events; nothing is preselected. Card-state events
retain independent ATR snapshots, and Inspect offered card ATR analyzes the latest
snapshot without connecting or sending application APDUs. Inventory filtering
works offline even without a PC/SC service. Card descriptions and issuer-context labels remain visible. The UI omits old
application names, source filenames, commit identifiers and source-row numbers. Invalid historical ATR/status/AID entries
have been removed. Lookup covers wildcard-index nested EMV paths as well as exact
identifiers. Refresh explicitly restarts reader observation.

GlobalPlatformDemo includes **Inspect CAP** for an offline package/applet/size
preview and live acknowledged LOAD byte/block counts with a progress bar. Its
worker never accesses VCL controls. Close still waits for the active operation.
EmvSemanticsDemo includes CVM Results (`9F34`) and terminal capabilities
(`9F33`, `9F40`) alongside the existing bit fields and CVM List. Select the EMV
version explicitly; reserved values remain visible in the offline output.

## Request validation

Family demos check missing reader selections, action choices and required
acknowledgements on the UI thread, before creating a worker. The result area
identifies the missing field. Reader discovery works independently of those fields.
Card components still validate typed values and credentials before communication.
The executor opens its connection at the first real I/O boundary and runs each
action once; successful validation does not raise a control-flow exception.

MobibDemo also includes a fifth independent DFM page for offline `.mobib` snapshot
analysis. Snapshot reads export a complete `snapshot.mobib` archive alongside
records and the report JSON. The offline page has its own load dialog, layout,
raw-record, operator-context and personal-field selectors. Live and offline pages
both accept caller CSV mappings through `TMobibLookup.LoadCsv`, and share the richer
`TMobibReport` output already used by the component library. Folder/SFI addresses,
application selection and file headers are preserved in the archive. See the
archive section of [MOBIB_CALYPSO.md](MOBIB_CALYPSO.md) for formats and bounds.

## Application workflow demos

The five independent workflow demos each own their DFM controls and source/target
selectors. They use the same nonvisual worker lifecycle as the family demos.
See [WORKFLOWS.md](WORKFLOWS.md) for operations, snapshots, evidence and the exact
profiles shown in each demo. For one device capture first, swap, then restore.

## ISO15693 and batch workflow demos

`iso15693workflow/Iso15693WorkflowDemo.dproj` has its own editable form and DFM.
Choose source/target readers from its device list, ordinary/extended address mode,
native-flags/payload-only responses, physical block count, bytes per block and
`first block,count` selection (at most 4096 blocks). The backend is ACS ACR1552
FF-FB. Use capture then restore for one-reader swaps, or copy/compare across two
readers. The workflow checks every differing target block's lock status before
writing; blocks zero and one cannot be restored or copied into the target.

`batchworkflow/BatchWorkflowDemo.dproj` has its own editable form and DFM.
Choose a Type2 model and a reader, supply an application identifier and NDEF text,
then Add card template. Repeat for each distinct reader with its card presented.
The editable list uses `identifier|reader|NDEF hex`. Acknowledge the writes and
execute once. All requests are prepared before I/O; the output lists each card's
outcome and identifies unattempted items after a failure. The demo rejects repeated
reader names; the underlying batch component supports application-managed
single-reader swaps through `OnCardRequired` and `CurrentIdentifier`.

Both use the existing nonvisual worker and native PC/SC inventory/presence events.
See [the workflow lifecycle and exact evidence](WORKFLOWS.md).
