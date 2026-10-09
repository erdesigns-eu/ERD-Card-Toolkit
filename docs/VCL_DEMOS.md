# VCL read/write demos

Eight applications demonstrate implemented APIs: the original SmartCardDemo and
MagStripeDemo plus six separate family projects sharing a form/input/worker base.
The complete current/missing coverage is recorded in [VCL_COVERAGE.md](VCL_COVERAGE.md).

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

## Separate family projects

All six projects open without accessing hardware. Choose one action; its named
fields appear below. Enum choices have no default card/reader profile. Public
bytes use hexadecimal text; numeric addresses/counts use decimal unless the label
says hexadecimal. Credentials are masked, decoded into separate byte buffers,
copied at the worker boundary, cleared from input controls after submission and
wiped from owned buffers after execution. Strings/OS/backend copies are outside
that byte-buffer wiping guarantee. Errors display their class, never backend text.

| Project | Actual actions |
| --- | --- |
| `readertools/ReaderToolsDemo.dproj` | Offline command/response APDU decode/encode, validated ATR/protocol/catalog hints, decoded BER-TLV tree/roundtrip, EMV tag metadata, NDEF roundtrip; PC/SC reader list and connected ATR/protocol |
| `rfidinput/RfidInputDemo.dproj` | Offline ASCII/hex/decimal identifier inspection and explicit width/order conversion; live foreground keyboard capture; decoding host-provided boot 8-byte, report-ID 9-byte and fixed ASCII reports |
| `twn4/Twn4Demo.dproj` | Explicit PRS/USB-CDC port, CRC and deadline; version/tag identity, supplied-key Classic block reads/data writes, public Type 2 user-page reads/writes; ID/expected-state/read-back checks |
| `memorycard/MemoryCardDemo.dproj` | ACS capabilities, all implemented SLE/I2C snapshots/ranges, supplied PIN proof, verified writes with physical I2C page size, supported two-wire PIN replacement, irreversible compare-and-protect |
| `slecounter/SleCounterDemo.dproj` | Explicit SLE4406/4436/5536/6636/window, public range reads, program/carry/backup modes with expected complete before/after windows, raw certificates; credential-bearing code command validation offline only |
| `sle4404/Sle4404Demo.dproj` | Known window/layout/retry budgets, reads with optional supplied user code, user-code proof, one-to-zero programming, scratchpad erase and application erase with both supplied codes |

For PC/SC operations enter the **exact reader name** returned by ReaderToolsDemo.
An ACS dialect is a known protocol configuration, not a guess from the name/ATR.
TWN4 uses its own COM field and suitable Simple Protocol firmware; it does not
send memory commands to keyboard-only HID readers. Firmware changes are not made
by the demo. See [TWN4.md](TWN4.md) and [memory profiles](MEMORY_CARDS.md).

State-changing/code-attempt actions require per-submission acknowledgement. This
is cleared after each request. Permanent protection, code consumption and erase
are explicitly named actions, with no automatic retries. Expected-before fields
must contain the actual bytes from the selected card/window. A counter-mode write
requires the full expected-after window; the demo does not calculate carry rules.
An application erase requires known user/memory-counter locations and a non-erased
expected application area so the component can prove the supplied memory code.

Worker preflight runs the actual component's argument validation against an
acquisition-only rejecting transport/channel. It stops before BeginTransaction or
Open acquires hardware, then repeats the validated action against the selected
real adapter once. No simulated successful card response is supplied. Card-state
checks necessarily happen after connection, under the component's transaction.
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

1. Build Debug/Release in Win32 and Win64 and open all six projects. ReaderTools'
   first APDU action and RFID's first text action work without a reader. Other
   demos must refuse incomplete reader/profile/window/port inputs without I/O.
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
9600 baud, seven data bits, odd parity and one stop bit. Enter the exact COM port,
selected tracks and a timeout between 1 and 600000 ms. `Read one swipe` updates
only the selected track fields. `Write selected + verify` additionally requires
nonempty payloads and an explicit low/high coercivity choice. It uses the verified
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

The job constructor creates a suspended worker. The form calls `StartWork` only
after construction returns, so Delphi's `TThread.AfterConstruction` finishes before
the explicit start. Starting inside the constructor caused the reported EThread
exception in both demos. A second start is refused; freeing a never-started job
does not execute its request. If starting fails, the form releases the job and
restores its controls. This follow-up has passed the headless worker tests; a
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

Gebruik een contact-PC/SC-lezer met SIM-adapter. Kies eerst het exacte klassieke
SIM- of UICC-profiel; lees ICCID en bij UICC EF.DIR voordat je een volledige AID
invult. De demo kiest geen applicatie automatisch. Zie [SIM.md](SIM.md) voor paths.
PIN-input is ASCII-hex (`31323334` voor `1234`), geen BCD.

Test eerst offline ICCID `981032547698103254F6` → `8901234567890123456` en
alpha `414C494345FF` → `ALICE`. Controleer daarna reader/ICCID, metadata en
read-only records. Test writes alleen met een test-SIM en exact uitgelezen beforebytes.
De terugleesstatus en eventuele cleanup-onzekerheid moeten zichtbaar blijven.
Standalone contacten met CCP/EXT-links worden expliciet geweigerd. De offline SMS-textactie decodeert een compleet EF.SMS-record, inclusief UDH.
De linked-contactactie gebruikt een expliciet PBR-record/ADN-FID en toont IAP/EXT.
Ruwe SMS-records blijven volledig behouden; er is geen SMS-verzendactie. Compileer alle twaalf demos
Win32/Win64: de gedeelde executors gebruiken nu ook `src/sim`.

## MifareClassicDemo, Type2Demo en Type4NdefDemo

Deze projecten gebruiken expliciet het PC/SC storage-profiel (Classic/Type 2)
of ISO APDU's (Type 4). Readerondersteuning voor dat profiel is vereist.

- Classic: controleer offline layout/trailers, selecteer het werkelijke model,
  block, reader-slot en aangeleverde A/B-key. Lees eerst. Manufacturer- en
  trailerwrites blijven door de component geweigerd. De writeactie levert
  uitsluitend readerstatus; lees zelf opnieuw voor een aparte controle.
- Type 2: kies het werkelijke Ultralight/EV1/NTAG-model. Lees een fysieke pagina
  of volledige gebruikerszone. Paginawrites zijn status-only; NDEF vervangen
  of wissen gebruikt de bestaande volledige terugleescontrole. PWD_AUTH/PACK
  via raw RF is nog niet in dit voorbeeld opgenomen.
- Type 4: inspecteer offline CC `000F20003A00340406E10401000000`. Op hardware
  kies je mapping 1.0/2.0 expliciet; lees CC en selecteer de werkelijke FID
  (decimal 57604 voor E104). FID 0 werkt alleen met een ondubbelzinnige CC.
  Proprietaire toegangsrechten worden niet als publieke NDEF behandeld.

Geen constructor opent hardware. Test ack/ongeldige modellen/keys en beschermde
pagina’s vóór writes op testkaarten; onzekere uitkomsten mogen niet worden herhaald.
