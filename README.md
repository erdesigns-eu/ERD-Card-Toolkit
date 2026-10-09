# ERD Card Components

A Delphi component library for **reading and writing smart cards, contactless tags,
magnetic stripes and RFID input** on Windows. It covers PC/SC readers, identity
documents (Belgian eID, ICAO eMRTD), EMV application data, MIFARE/NTAG/DESFire,
ISO 15693, Calypso/MOBIB, SIM/USIM, SLE/I²C contact-memory chips, magnetic-stripe
readers/writers, USB-HID and ELATEC TWN4 readers.

The library replaces the former CardStudio application with standalone,
non-visual components, codecs, console tools and VCL demos. Payment processing is
out of scope (see [Not supported](#not-supported)).

- **Target platform:** Delphi 10.4 or later, Windows Win32 and Win64.
- **Runtime dependencies:** the Delphi RTL only. No VCL, vendor DLLs or middleware are
  required by the runtime units. OpenSSL 3 is needed only for ICAO BAC/PACE.
- **Validation status:** see [docs/VALIDATION.md](docs/VALIDATION.md) and the
  [hardware matrix](docs/HARDWARE_MATRIX.md). Protocol behaviour is covered by
  synthetic transcript tests. Most physical reader/card combinations have not been
  certified yet.

## Contents

- [Features](#features)
- [Design principles](#design-principles)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Quick start](#quick-start)
- [Reader and card events](#reader-and-card-events)
- [Cryptographic providers](#cryptographic-providers)
- [Examples](#examples)
- [Building and testing](#building-and-testing)
- [Not supported](#not-supported)
- [Unit reference](#unit-reference)
- [Documentation](#documentation)

## Features

| Area | Components | What you can do |
| --- | --- | --- |
| **PC/SC readers** | `TSmartCardReader`, `TSmartCardMonitor` | List readers, connect (shared/exclusive, T=0/T=1), read the ATR, exchange APDUs through `ICardTransport` and use explicit PC/SC transactions. Event-driven reader hot-plug and card insertion/removal without polling. |
| **Protocol toolkit** | Codecs (no component) | ISO 7816 APDU encode/decode (short and extended), ATR parsing with TCK validation, BER-TLV decode/encode with configurable limits, hex/byte helpers, a curated ATR hint catalog and EMV tag metadata. |
| **Belgian eID** | `TBelgianEIDReader` | Read identity, address, JPEG photo, certificates (RAW/DER) and raw signature files from Belpic 1.7/1.8 contact cards. |
| **ICAO travel/ID documents** | `TICAODocumentReader` | BAC (MRZ) or PACE (MRZ/CAN, ECDH Generic Mapping, AES-128, NIST P-256 or brainpoolP256r1) secure messaging. Read DG1 (MRZ identity), DG2 (JPEG and JPEG 2000 face images), and complete EF.COM/EF.SOD files. Includes MRZ parsing with check digits (TD1/TD2/TD3) and EF.CardAccess PACEInfo decoding. |
| **EMV** | `TEMVCardReader` | PSE/PPSE directory discovery, PDOL inspection without GPO, GPO and AFL record reading, an optional bounded extra SFI/record scan, GET DATA objects, and transaction logs. Extracts PAN, expiry date, cardholder name, IBAN and Track 2 equivalent data where present. Reading only, no transactions. |
| **MIFARE Classic** | `TContactlessCardReader` | Classic Mini/1K/4K layouts. Read blocks with a supplied key A/B and write data blocks; block 0 and sector trailers are refused. |
| **Ultralight / NTAG (Type 2)** | `TContactlessCardReader`, `TType2PasswordCardReader` | Ultralight, Ultralight EV1 (48/128), NTAG210/212/213/215/216 page reads, user-memory snapshots and user-page writes. PWD_AUTH/PACK access, verified AUTH0/PROT/AUTHLIM configuration and password/PACK replacement, supported counter reads, and protected NDEF through an ACR122U adapter. |
| **Ultralight C** | `TUltralightCCardReaderWriter` | Supplied-key 2K3DES mutual authentication, exact user-page reads, a 144-byte user-memory snapshot and verified four-byte user-page writes through raw RF (ACR122U adapter). Read authentication configuration; verified AUTH0/AUTH1 updates and key replacement with same-UID fresh RF authentication. Manufacturer, OTP, lock and counter writes remain excluded. |
| **NDEF** | `TType2NdefCardReader`, `TType3NdefCardReader`, `TType4NdefCardReader`, `TType5NdefCardReader` | Complete NDEF message codec with chunk reassembly, plus Text, URI, MIME, external and Smart Poster record helpers. Read, replace and clear public NDEF messages on Type 2, Type 3 (mapping 1.0), Type 4 (mapping 1.0/2.0) and Type 5 tags, with read-back verification. Type 2 also supports NDEF within supplied-password sessions. |
| **FeliCa / NFC Forum Type 3** | `TFelicaCardReader`, `TType3NdefCardReader` | Fresh explicit-system polling, IDm/PMm, unencrypted service block reads and preimage-checked verified writes, including 16-bit block addresses. Type 3 attribute parsing and verified NDEF read/replace/clear through an ACR122U/PN532 adapter at explicit 212/424 kbit/s. |
| **ISO 15693 / NFC-V** | `TIso15693CardReader` | Ordinary/extended addressing, system information, single or explicit native multiple-block reads and verified data writes through ACS ACR1552 FF FB. `TIso15693PasswordSession` adds supplied-password user-memory access for ICODE SLIX2 and original ST25DV04K/16K/64K, including Type 5 NDEF. `TIso15693SecurityManager` adds decoded protection snapshots, RF password replacement with fresh RF proof, SLIX2 page protection and ST25DV RF area policy updates. |
| **MIFARE DESFire** | `TDesfireCardReader` | Public, EV1/EV2 AES, EV1 2K3DES/3K3DES and explicit D40 DES/2K3DES (Plain, MACed, Full) access. Discover applications/files, read standard/backup/value/record files and write standard data. Transactions with commit/abort; application and ordinary-file create/delete across the explicit profiles, including selectable DES/2K3DES, 3K3DES or AES application storage. AES/DES/3DES key rotation, key-policy and ordinary-file access administration. EV2 NonFirst re-authentication. |
| **Programmable (“magic”) UIDs** | `TRawUidProgrammer`, UID methods of `TContactlessCardReader` | Explicit profiles for Gen1a/Gen1b, unsealed UFUID, Gen2/CUID, factory FUID (one-time), Gen3, Gen4 UMC (4/7/10-byte), USCUID/GDM, partial UFUID/ZUID/PFUID and Type 2 DirectWrite. Raw RF access uses an ACS ACR122U/PN532 adapter. |
| **Calypso / MOBIB** | `TCalypsoCardReader` | Read Calypso files and records (legacy CLA 94 or ISO CLA 00) using the built-in MOBIB plan or your own FID plan. Decode holder, events, contracts (versions 0–4) and counters. Native Calypso secure sessions through a provisioned SAM (revisions 1, 2, 3 and 3.2) or a custom provider. Offline activation/validity/zone checks with `TMobibRuleEngine` and caller-supplied operator profiles. |
| **SIM / USIM** | `TSimCardReaderWriter` | Classic GSM SIM and UICC/USIM profiles. Read ICCID, IMSI, SPN, service tables and EF.DIR applications; inspect, read and verified-write transparent, linear-fixed and cyclic files. PIN/PUK status, verify, change and unblock with attempt budgets. Read, write and delete ADN contacts; read linked USIM contacts (PBR/IAP/EXT/EMAIL/ANR); verified linked write plans; SMS record and text/UDH codecs. |
| **Contact memory chips** | `TMemoryCardReaderWriter` | SLE4432/4442/5532/5542, SLE4418/4428/5518/5528 and I²C 1–1024 kbit chips through ACS ACR38x CCID and ACR39 dialects. Snapshots, range reads, PIN verification/change, verified writes and irreversible protection. |
| **SLE counter chips** | `TSleCounterCardReaderWriter` | SLE4406/4436/5536/6636 through ACR38x CCID: public reads within a known window, bit/carry/backup programming with verification, raw certificate calculation. |
| **SLE4404** | `TSle4404CardReaderWriter` | ACR38x CCID: public and code-protected reads, user-code verification, bit programming and explicit scratchpad/application erases with read-back verification. |
| **Magnetic stripe** | `TMagStripeReaderWriter` | Track 1–3 codecs (parity, LRC, financial Track 1 format B/Track 2 parsing). MSR206/MSR605 read and status-only programming; MSR206-7HL read and verified write; read-only MagTek keyboard and HID adapters. |
| **RFID keyboard/HID input** | `TRfidKeyboardReader`, `TRfidHidReportReader` | Decode identifiers from keyboard-wedge readers or from host-supplied HID boot-keyboard (8/9-byte) and fixed ASCII-field reports. ASCII, hexadecimal and decimal profiles with prefix/suffix/terminator framing. |
| **Native USB-HID** | `TUsbHidReaderWriter`, `THidDeviceMonitor`, `TUsbHidInputMonitor` | Enumerate Windows HID collections (VID/PID/usage/report lengths), open an exact interface, read/send input, output and feature reports with timeouts. Hot-plug notifications and continuous input-report events. |
| **ELATEC TWN4** | `TTwn4CardReaderWriter` | Simple Protocol over PRS/USB-CDC: firmware version, tag search, supplied-key Classic block reads/writes and public Type 2 user-page reads/writes with expected-ID and read-back checks. Requires suitable PRS firmware. |

Card support and reader support are separate: an operation needs both the correct
card profile **and** a reader that supports the required commands. The linked
[documentation](#documentation) lists the exact profiles for each family.

## Design principles

These rules apply to every component and are worth knowing before you start:

- **Inactive by construction.** Constructors, palette registration and DFM streaming
  never open hardware, start threads or connect to cards. You connect explicitly.
- **Explicit profiles, no guessing.** Card models, reader dialects, keys, AIDs and
  file plans are supplied by the caller. Nothing is detected by probing or ATR
  guessing, and there is no fallback to another protocol.
- **Transport abstraction.** Card components talk to an `ICardTransport` (optionally
  `ICardTransaction`). `TSmartCardReader.Transport` provides one for PC/SC, but you
  can supply your own, for example for testing or another reader stack.
- **No automatic retries.** Commands are sent exactly once. 61xx/6Cxx handling,
  PIN attempts and writes are never repeated implicitly.
- **Verified writes.** Writes compare the expected prior state and read back the
  result where the protocol permits. If the outcome cannot be proven, a
  `...WriteUncertain` exception is raised instead of a silent success.
- **Credential hygiene.** Owned key/PIN/password buffers are wiped after use, and
  exception messages never contain card data, keys or APDUs.
- **Threading.** Use a component on one thread. Blocking card operations belong in a
  worker thread; monitors deliver their events on the main thread.

## Repository layout

| Path | Contents |
| --- | --- |
| `src/core` | Byte helpers, APDU, ATR, ATR catalog, BER-TLV, transport, event queue and crypto contracts |
| `src/pcsc` | PC/SC API abstraction, Windows `winscard.dll` binding, `TSmartCardReader`, `TSmartCardMonitor` |
| `src/eid` | Belgian eID, ICAO document reader, MRZ, LDS, BAC/PACE access and secure messaging |
| `src/emv` | EMV reader, data model and tag catalog |
| `src/contactless` | MIFARE Classic, Type 2/3/4/5, FeliCa, NDEF, ISO 15693, DESFire, UID programming, Calypso/MOBIB |
| `src/memory` | SLE/I²C memory chips, SLE counter chips, SLE4404, ACS capability catalog |
| `src/sim` | SIM/USIM reader/writer and data codecs |
| `src/magstripe` | Track codecs, serial port, MSR206/MSR605, MSR206-7HL, MagTek adapters |
| `src/input` | Native USB-HID, HID monitors, RFID keyboard/HID decoders |
| `src/readers` | ELATEC TWN4 Simple Protocol and its serial channel |
| `src/crypto` | Optional providers: Windows CNG (AES) and OpenSSL 3 (AES, BAC/PACE) |
| `src/design` | IDE palette registration |
| `packages/` | `ERDCards.groupproj`: 12 runtime packages and the design-time package |
| `Delphi Packages/` | Native-format `Core` reference package used for IDE troubleshooting |
| `examples/` | 19 console examples and 22 VCL demos (`examples/vcl/CardDemos.groupproj`) |
| `tests/` | Pascal test programs (Free Pascal/Delphi), native ABI shims and Python tests |
| `tools/` | Build scripts, test runner, distribution checker, `pascalcheck` static analysis, fixture generators |
| `docs/` | Per-family guides, installation, validation and planning documents |
| `reference/legacy/` | Original CardStudio sources kept as protocol reference with SHA-256 manifest (not compiled) |

## Getting started

New to the library? [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) walks
through a first VCL application step by step. It covers which components to drop,
which events to handle, how to keep card I/O off the UI thread, and short recipes
for every card family.

### Option 1: use the sources directly

Add the `src` sub-directories you need to your project's unit search path. Most
families need `src/core` plus their own directory, and `src/pcsc` for PC/SC
readers on Windows. Add `src/crypto` when you need a cryptographic provider
(DESFire AES/DES/3DES, Ultralight C, ICAO BAC/PACE). This is how the bundled VCL
demos are built, so the palette doesn't have to be installed.

### Option 2: runtime packages

Open `packages/ERDCards.groupproj` in RAD Studio and build it, or use a RAD Studio
command prompt:

```bat
tools\build-packages.cmd dcc32        rem Win32 runtime packages
tools\build-packages.cmd dcc64        rem Win64 runtime packages
msbuild packages\ERDCards.groupproj /t:Build /p:Config=Release /p:Platform=Win64
```

Output goes to `dist/packages/<Platform>/<Config>`.

| Package | Contents | Requires |
| --- | --- | --- |
| `ERDCardCore` | Core codecs, transport, events, crypto contracts | `rtl` |
| `ERDCardCryptoWindows` | Windows CNG AES provider (optional) | `ERDCardCore` |
| `ERDCardCryptoOpenSSL` | OpenSSL 3 BAC/PACE/AES provider (optional) | `ERDCardCore` |
| `ERDCardPCSC` | PC/SC reader and monitor | `ERDCardCore` |
| `ERDCardEID` | Belgian eID and ICAO documents | `ERDCardCore` |
| `ERDCardEMV` | EMV reader and tag catalog | `ERDCardCore` |
| `ERDCardContactless` | Classic, Type 2/3/4/5, FeliCa, NDEF, ISO 15693, DESFire, UID, Calypso/MOBIB | `ERDCardCore` |
| `ERDCardMemory` | Memory, counter and SLE4404 chips | `ERDCardCore` |
| `ERDCardSIM` | SIM/USIM | `ERDCardCore` |
| `ERDCardInput` | USB-HID, HID monitors, RFID input | `ERDCardCore` |
| `ERDCardMagStripe` | Magnetic-stripe codecs and devices | `rtl` |
| `ERDCardTWN4` | ELATEC TWN4 | `ERDCardCore`, `ERDCardContactless`, `ERDCardMagStripe` |

No runtime package depends on the VCL or on design-time packages.

### Option 3: install the component palette

The design package `ERDCardDesign` is **standalone**: it contains its own copies of
the required units and needs only `rtl`, `vcl` and `designide`, not the ERD runtime
BPLs. Build it for the architecture of your **IDE** (usually Win32), which may differ
from your application's target:

```bat
tools\build-packages.cmd dcc32 design
```

Then use **Component > Install Packages > Add** and select `ERDCardDesign.bpl`.
It registers 29 components:

| Palette page | Components |
| --- | --- |
| **ERD Cards** | `TSmartCardMonitor`, `TSmartCardReader`, `TBelgianEIDReader`, `TICAODocumentReader`, `TSimCardReaderWriter`, `TEMVCardReader`, `TMagStripeReaderWriter`, `TMemoryCardReaderWriter`, `TSleCounterCardReaderWriter`, `TSle4404CardReaderWriter` |
| **ERD Input** | `THidDeviceMonitor`, `TUsbHidInputMonitor`, `TRfidKeyboardReader`, `TRfidHidReportReader`, `TUsbHidReaderWriter`, `TTwn4CardReaderWriter` |
| **ERD Contactless** | `TFelicaCardReader`, `TType3NdefCardReader`, `TUltralightCCardReaderWriter`, `TCalypsoCardReader`, `TContactlessCardReader`, `TType2NdefCardReader`, `TType4NdefCardReader`, `TIso15693CardReader`, `TIso15693SecurityManager`, `TType5NdefCardReader`, `TDesfireCardReader`, `TType2PasswordCardReader`, `TRawUidProgrammer` |

Scalar settings are stored in the DFM. Interface properties such as `Transport`,
`Profile`, `Device`, `Session`, `Channel` and `CryptoProvider` must be assigned at
runtime. Don't load the ERD runtime BPLs into the same IDE process as the
standalone design package. See [docs/INSTALLATION.md](docs/INSTALLATION.md) for
details and troubleshooting.

## Quick start

Read a Belgian eID card through a PC/SC reader:

```pascal
uses
  System.SysUtils, ERD.Card.PCSC.Api, ERD.Card.PCSC.Reader,
  ERD.Card.EID.Data, ERD.Card.EID.Reader;

var
  Card: TSmartCardReader;
  Eid: TBelgianEIDReader;
  Names: TPcscReaderNames;
  Data: TBelgianEidData;
begin
  Card := TSmartCardReader.Create(nil);
  Eid := TBelgianEIDReader.Create(nil);
  try
    Names := Card.ListReaders;            // Let the user pick an exact name.
    Card.ReaderName := Names[0];
    Card.Connect;
    Eid.Transport := Card.Transport;
    Data := Eid.ReadCard;                 // Identity, address and photo by default.
    Writeln(Data.Identity.Surname);
    // Data.Photo holds the JPEG bytes.
    Card.Disconnect;
  finally
    Eid.Free;
    Card.Free;
  end;
end;
```

All PC/SC card families follow the same pattern: connect a `TSmartCardReader`,
assign its `Transport` (plus a profile, session or crypto provider where needed) to
the card component and call its read/write methods. The console programs in
`examples/` show this pattern for each family.

## Reader and card events

`TSmartCardMonitor` uses native PC/SC status-change waits to report
`OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`, `OnCardRemoved`,
`OnStateChanged` and `OnError`. No polling is needed in your application:

```pascal
FMonitor := TSmartCardMonitor.Create(Self);
FMonitor.OnReaderAdded := ReaderAdded;
FMonitor.OnCardInserted := CardInserted;
FMonitor.OnCardRemoved := CardRemoved;
FMonitor.OnError := MonitorError;
FMonitor.Start;   // Stop cancels and joins the worker.
```

- `EmitInitialState` (default `True`) reports readers and cards already present
  when `Start` is called.
- `TSmartCardReader.StartEventMonitoring` provides the same events, with card events
  filtered to its `ReaderName`. The older `StartMonitoring`/`PollChanges` mode still
  exists.
- `THidDeviceMonitor` reports HID interfaces being plugged in (`OnDeviceAdded`) and
  removed (`OnDeviceRemoved`).
  `TUsbHidInputMonitor` delivers continuous input reports (`OnInputReport`) from a
  selected device. You can pass these to `TRfidHidReportReader.FeedReport` to get
  decoded identifiers via `OnIdentifier`.

Events are queued to the main thread (`TThread.Queue`). VCL apps handle this
automatically; console or service hosts call `CheckSynchronize`. Events never
connect to or read a card by themselves. Keyboard-only RFID readers usually can't
report card removal. See [docs/READER_EVENTS.md](docs/READER_EVENTS.md).

## Cryptographic providers

Cryptography is supplied through interfaces (`ICardAesProvider`, `ICardDesProvider`, `ICardEacProvider`)
so that the core stays dependency-free:

| Provider | Unit | Used for |
| --- | --- | --- |
| `TCardWindowsAesProvider` | `ERD.Card.Crypto.Windows` | AES-128/3DES CBC and system CSPRNG via Windows CNG; DESFire and Ultralight C |
| `TCardEacOpenSslProvider` | `ERD.Card.Crypto.EAC.OpenSSL` | ICAO BAC/PACE (AES, 3DES, SHA-1, ECDH) via a separately installed **OpenSSL 3** library whose architecture matches your application. Loads `libcrypto-3.dll` by default; you can also pass an explicit path. |
| `TCardOpenSslAesProvider` | `ERD.Card.Crypto.OpenSSL` | AES-128/3DES CBC via `libcrypto.so.3`; Linux test backend, not part of any package |

`TCardCrypto` in `ERD.Card.Crypto` adds AES-CMAC (including the DESFire chained
variant), timing-aware secret comparison and buffer clearing. `TCardDesCrypto` adds explicit DES/2K3DES key expansion, 64-bit CMAC and the D40 inverse-send transform through native ciphers. OpenSSL is not bundled.

## Examples

### Console examples

These programs build with Delphi or Free Pascal. Most have an offline mode that
needs no hardware. Run them with `--help` to see their arguments.

| Program | Purpose |
| --- | --- |
| `examples/core/InspectApdu` | Decode an APDU command |
| `examples/core/InspectCardTools` | Decode an ATR, show catalog hints and EMV tag metadata |
| `examples/pcsc/InspectReader` | List PC/SC readers or show a reader's ATR |
| `examples/eid/ReadBelgianEid` | Read a Belgian eID and optionally save the photo |
| `examples/eid/ReadIcaoDocument` | Inspect EF.CardAccess offline or read an ICAO document via BAC/PACE |
| `examples/emv/InspectEmv` | PSE/PPSE discovery or read an EMV application, log or ATC |
| `examples/contactless/InspectContactless` | UID and Classic/Type 2 storage via a PC/SC storage profile |
| `examples/contactless/InspectNdef` | Decode an NDEF message |
| `examples/contactless/InspectType4Ndef` | Decode a Type 4 capability container or read NDEF from a card |
| `examples/contactless/InspectType5Ndef` | Decode a Type 5 CC or read NDEF via ISO 15693 |
| `examples/contactless/InspectDesfire` | Decode DESFire file settings or read DESFire files |
| `examples/contactless/ManageDesfire` | DESFire application/file creation and deletion, transactional updates |
| `examples/contactless/AdminDesfire` | DESFire free memory, key versions/settings, file access rights and key rotation |
| `examples/memory/InspectMemoryCard` | Memory-chip geometry offline, or a read-only snapshot via an ACS reader |
| `examples/memory/InspectSle4404` | SLE4404 window check offline, or public reads via ACR38x CCID |
| `examples/sim/InspectSim` | Offline SIM codecs (ICCID, IMSI, ADN, SMS, EF.DIR, …) |
| `examples/magstripe/InspectMagStripe` | Frame/validate a track |
| `examples/magstripe/InspectMsr206` | Decode an MSR206 frame or read one swipe from an MSR206/MSR605/MSR206-7HL |
| `examples/readers/InspectTwn4` | TWN4 frame encoding offline, or version/tag via COM port |

### VCL demos

`examples/vcl/CardDemos.groupproj` contains 22 Windows VCL applications. Each one has
its own form and DFM, its own reader/HID/COM-port picker with a refresh button, and
runs card work on a background thread. Write, PIN and management actions require
an explicit acknowledgement. PC/SC demos update their reader list from native hotplug events
and show card offered/removed notifications without running a card operation.

| Demo | Covers |
| --- | --- |
| `SmartCardDemo` | Combined PC/SC, eID, EMV, contactless, NDEF, memory and RFID pages |
| `MagStripeDemo` | Track checks, swipes and verified MSR206-7HL writes |
| `MagStripeProfilesDemo` | Track codecs, MagTek keyboard/HID, MSR206/MSR605 reads and status-only programming |
| `ReaderToolsDemo` | Reader/card events log, PC/SC list/ATR, APDU, ATR catalog, BER-TLV, EMV tags, NDEF |
| `RfidInputDemo` | Keyboard capture, boot/ID/ASCII HID report decoding, identifier conversion |
| `UsbHidDemo` | HID hot-plug, continuous input reports, interrupt/feature report I/O and export |
| `Twn4Demo` | TWN4 version/tag, Classic and Type 2 reads/writes |
| `MemoryCardDemo` | All SLE/I²C models, both ACS dialects, PIN, writes and protection |
| `SleCounterDemo` | Counter-chip windows, programming and certificates |
| `Sle4404Demo` | SLE4404 layout, code verification, programming and erases |
| `SimCardDemo` | SIM/USIM files, identities, services, PIN/PUK, contacts, SMS and linked records |
| `MifareClassicDemo` | UID, layout/trailers, block reads and writes |
| `Type2Demo` | Ultralight/NTAG memory, public/protected NDEF, PWD_AUTH/PACK, verified configuration/credentials and counter reads |
| `FelicaDemo` | Explicit FeliCa system/services/blocks and Type 3 attributes/NDEF; own form, DFM, reader selection and presence events |
| `UltralightCDemo` | Supplied-key authentication, exact user-page/full user-memory reads and verified page writes, configuration and key replacement; own form and DFM |
| `Type4NdefDemo` | Capability container, file descriptors and NDEF read/write/clear |
| `Iso15693Demo` | ACR1552 ordinary/extended ISO 15693 blocks, native bulk reads and Type 5 NDEF |
| `Slix2Demo` | Supplied read/write passwords, physical blocks, parsed Type 5 NDEF, decoded protection, password replacement and page protection; own form/DFM and reader events |
| `St25DvDemo` | Original ST25DV04K/16K/64K passwords, ordinary/extended blocks, parsed Type 5 NDEF, decoded RF areas, password replacement and area policy; own form/DFM and reader events |
| `UidProgrammingDemo` | All programmable-UID profiles |
| `DesfireDemo` | Public/AES/DES/3DES reads, writes and transactions; native application/file create-delete with explicit application key type/count; AES/DES/3DES key/access-policy mutations |
| `EmvDemo` | PSE/PPSE, PDOL, GPO/AFL records, extra record scan, GET DATA, logs and exports |
| `MobibDemo` | Calypso/MOBIB files, contracts, SAM authentication and rule assessment |
| `BelgianEidDemo` | Identity, address, photo, certificates and signatures with export |
| `IcaoDocumentDemo` | BAC/PACE, DG1/DG2/COM/SOD, JPEG preview and JPEG 2000 export |

```bat
tools\build-vcl-demos.cmd dcc32
tools\build-vcl-demos.cmd dcc64
```

Executables go to `dist/vcl/<Platform>/Debug`. See
[docs/VCL_DEMOS.md](docs/VCL_DEMOS.md) for smoke tests and
[docs/VCL_COVERAGE.md](docs/VCL_COVERAGE.md) for coverage per demo.

## Building and testing

### On Windows with Delphi

From a RAD Studio command prompt (use `dcc64` for Win64):

```bat
tools\build-packages.cmd dcc32
tools\build-vcl-demos.cmd dcc32
tools\run-core-tests.cmd dcc32
```

The build scripts call MSBuild on the `.dproj` files (Debug, with range and
overflow checks). `run-core-tests.cmd` compiles and runs the console test programs
under `dist/core/<compiler>`.

### On any platform without Delphi

```sh
python3 tools/run_core_tests.py           # Free Pascal: all Pascal test programs and examples
python3 tools/check_distribution.py       # project/package/DFM consistency
python3 -m unittest discover -s tests/tools -p 'test_*.py'
python3 tools/pascalcheck/run.py --profile core --source-root src --source-root tests --source-root examples
```

`run_core_tests.py` needs Free Pascal 3.2+ (`--fpc` and `--rtl-dir` select a
specific compiler). It also builds small C shims with GCC to exercise the native
PC/SC, HID, serial and CNG bindings. `pascalcheck` is a set of Python static
checkers for Delphi pitfalls and XML documentation coverage; see
[tools/pascalcheck/README.md](tools/pascalcheck/README.md). These checks complement
a real Delphi build and hardware testing but don't replace them.

All public APIs carry Delphi XML documentation (`///`) for Help Insight; see
[docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md).

## Not supported

- **Payments:** no terminal/provider integration, transaction authorization or NFC
  payment kernel. EMV support is read-only ([docs/PAYMENTS.md](docs/PAYMENTS.md)).
- **Document authenticity:** certificates, signatures and EF.SOD can be read, but
  passive authentication (SOD/issuer verification), chip authentication and EAC are
  not implemented. The library doesn't decode fingerprints, include a JPEG 2000
  decoder or do biometric matching.
- **Other European eIDs:** Dutch, Luxembourg and German documents and their national
  online services are not validated; extra PACE/EAC profiles are missing
  ([docs/EUROPEAN_EID.md](docs/EUROPEAN_EID.md)).
- **MIFARE/DESFire variants:** MIFARE Plus, DESFire LRP,
  TMAC, SDM and extended key-set/configuration management. Ultralight C irreversible lock/counter/OTP programming. NFC Forum Type 1 tags; encrypted FeliCa services and FeliCa formatting/key provisioning.
- **ISO 15693 vendor management:** no irreversible lock programming, SLIX2
  privacy/destroy, ST25DV area resizing/mailbox/I²C or ST25TV/KC password dialects.
  Supplied-password access and verified password/protection management cover SLIX2
  and original ST25DV04K/16K/64K
  ([exact profiles and RF lifetime](docs/ISO15693_TYPE5.md)).
- **UID programming:** only the listed programmable profiles; regular card UIDs
  are not writable.
- **MOBIB:** no built-in De Lijn/STIB/TEC/NMBS-SNCB rule sets; operator profiles must be
  supplied. Secure reads need a provisioned SAM; software-only key cryptography and
  encrypted sessions are not implemented.
- **SIM:** no eSIM provisioning, network authentication, SMS sending or automatic
  record allocation.
- **Contact memory:** no AT88SC/CryptoMemory, no ACR39 for counter chips/SLE4404,
  no automatic counter arithmetic or personalisation-code unlocking.
- **Reader protocols:** generic HID moves reports but doesn't know any vendor card
  protocol. Keyboard-only RFID readers (e.g. EM4100/TK4100) can't write.
  Magstripe SDK DLLs (YL160, MSR605X), encrypted MagTek and AAMVA/JIS formats
  are not supported. TWN4 firmware is not changed automatically.
- **Platforms:** hardware access is Windows-only (Win32/Win64). On other platforms the
  PC/SC layer reports an unsupported feature.

## Unit reference

<details>
<summary>All 68 source units</summary>

| Unit | Purpose |
| --- | --- |
| `ERD.Card.Bytes` | Hex/byte conversion and copying |
| `ERD.Card.APDU` | ISO 7816-4 command/response APDU codec |
| `ERD.Card.ATR` | ATR parser with protocol and TCK validation |
| `ERD.Card.ATR.Catalog` | Curated, masked ATR hint catalog with sources |
| `ERD.Card.TLV` | Bounded BER-TLV tree decoder/encoder |
| `ERD.Card.Transport` | `ICardTransport` and `ICardTransaction` contracts |
| `ERD.Card.Events` | Bounded main-thread event queue used by monitors |
| `ERD.Card.Crypto` | AES provider contract, AES-CMAC and secret helpers |
| `ERD.Card.Crypto.DES` | Optional DES provider, explicit key expansion and protocol MAC composition |
| `ERD.Card.Crypto.EAC` | BAC/PACE provider contract (3DES, SHA-1, ECDH GM) |
| `ERD.Card.Crypto.Windows` | Windows CNG AES/CSPRNG provider |
| `ERD.Card.Crypto.OpenSSL` | Linux OpenSSL 3 AES/CSPRNG provider (tests) |
| `ERD.Card.Crypto.EAC.OpenSSL` | OpenSSL 3 BAC/PACE provider |
| `ERD.Card.PCSC.Api` | PC/SC abstraction, types and errors |
| `ERD.Card.PCSC.Windows` | `winscard.dll` binding |
| `ERD.Card.PCSC.Reader` | `TSmartCardReader` |
| `ERD.Card.PCSC.Monitor` | `TSmartCardMonitor` |
| `ERD.Card.EID.Data` | Belgian eID data model and TLV codec |
| `ERD.Card.EID.Reader` | `TBelgianEIDReader` |
| `ERD.Card.EID.MRZ` | ICAO MRZ parser with check digits |
| `ERD.Card.EID.ICAO` | LDS DG1/DG2 decoding |
| `ERD.Card.EID.Access` | BAC/PACE key derivation and protocol steps |
| `ERD.Card.EID.SecureMessaging` | ICAO secure messaging |
| `ERD.Card.EID.DocumentReader` | `TICAODocumentReader`, EF.CardAccess codec |
| `ERD.Card.EMV.Tags` | EMV tag catalog |
| `ERD.Card.EMV.Data` | EMV data model, DOL/AFL/log codec |
| `ERD.Card.EMV.Reader` | `TEMVCardReader` |
| `ERD.Card.Contactless` | `TContactlessCardReader`, reader profiles, Classic layout |
| `ERD.Card.Contactless.Felica` | Explicit-system target information, service block codec and verified block component |
| `ERD.Card.Contactless.ACR122.Felica` | Explicit PN532 FeliCa polling/transfer at 212 or 424 kbit/s |
| `ERD.Card.Contactless.Type3.Ndef` | Strict Type 3 attribute mapping, NDEF reader and verified length-last writer |
| `ERD.Card.Contactless.UltralightC` | Supplied-key Ultralight C authentication and verified user-memory access |
| `ERD.Card.Contactless.DESFire.DES` | Distinct EV1 3DES and D40 native-message codecs |
| `ERD.Card.Contactless.Type2` | Ultralight/NTAG layouts |
| `ERD.Card.Contactless.Type2.Ndef` | `TType2NdefCardReader` and Type 2 NDEF mapping |
| `ERD.Card.Contactless.Type2.Password` | `TType2PasswordCardReader` (PWD_AUTH/PACK) |
| `ERD.Card.Contactless.Type4.Ndef` | `TType4NdefCardReader` |
| `ERD.Card.Contactless.Type5.Ndef` | `TType5NdefCardReader` |
| `ERD.Card.Contactless.ISO15693` | `TIso15693CardReader`, codec, ACR1552 session, optional bulk/custom/RF-reset interfaces, SLIX2/ST25DV password session and `TIso15693SecurityManager` |
| `ERD.Card.Ndef` | NDEF message codec |
| `ERD.Card.Ndef.Records` | Text, URI, MIME, external and Smart Poster records |
| `ERD.Card.Contactless.DESFire` | `TDesfireCardReader`, sessions and management |
| `ERD.Card.Contactless.DESFire.EV1` | EV1 AES secure-messaging codec |
| `ERD.Card.Contactless.DESFire.EV2` | EV2 AES secure-messaging codec |
| `ERD.Card.Contactless.Raw` | `TRawUidProgrammer`, raw Type A codec |
| `ERD.Card.Contactless.ACR122` | ACR122U/PN532 raw-frame adapter |
| `ERD.Card.Contactless.UID` | Gen2/CUID UID codec |
| `ERD.Card.Contactless.UID.Profiles` | Gen3/Gen4 UID codecs |
| `ERD.Card.Contactless.UID.USCUID` | USCUID/GDM UID codec |
| `ERD.Card.Contactless.UID.Partial` | Partial UFUID/ZUID/PFUID codec |
| `ERD.Card.Contactless.Calypso` | `TCalypsoCardReader` |
| `ERD.Card.Contactless.Calypso.SAM` | SAM-based Calypso secure-session provider |
| `ERD.Card.MOBIB.Data` | MOBIB holder/event/contract/counter codec |
| `ERD.Card.MOBIB.Subscriptions` | MOBIB subscription (contract version) codec |
| `ERD.Card.MOBIB.Rules` | `TMobibRuleEngine` activation/validity/zone rules |
| `ERD.Card.Memory` | `TMemoryCardReaderWriter` and memory codec |
| `ERD.Card.Memory.Capabilities` | ACS memory capability catalog |
| `ERD.Card.Memory.Counter` | `TSleCounterCardReaderWriter` |
| `ERD.Card.Memory.Sle4404` | `TSle4404CardReaderWriter` |
| `ERD.Card.SIM.Data` | SIM/USIM data codecs (files, PIN, ADN, PBR, SMS) |
| `ERD.Card.SIM.Reader` | `TSimCardReaderWriter` |
| `ERD.Card.MagStripe.Tracks` | Track codecs and financial parsing |
| `ERD.Card.MagStripe` | `TMagStripeReaderWriter` and device contracts |
| `ERD.Card.MagStripe.Serial` | Windows COM port channel (8N1/7O1) |
| `ERD.Card.MagStripe.MSR206` | MSR206/MSR605 adapter |
| `ERD.Card.MagStripe.MSR2067HL` | MSR206-7HL adapter with verified writes |
| `ERD.Card.MagStripe.MagTek` | MagTek keyboard/HID read adapters |
| `ERD.Card.HID` | `TUsbHidReaderWriter`, HID enumeration and devices |
| `ERD.Card.HID.Monitor` | `THidDeviceMonitor`, `TUsbHidInputMonitor` |
| `ERD.Card.RFID.Input` | `TRfidKeyboardReader` and identifier codec |
| `ERD.Card.RFID.HID` | `TRfidHidReportReader` and report decoders |
| `ERD.Card.Reader.TWN4` | `TTwn4CardReaderWriter` and Simple Protocol codec |
| `ERD.Card.Reader.TWN4.Serial` | TWN4 USB-CDC COM channel |
| `ERD.Card.Design.Register` | Palette registration |

</details>

## Documentation

**Setup and project**

- [Getting started: your first application](docs/GETTING_STARTED.md)
- [Installation and packages](docs/INSTALLATION.md)
- [VCL demos and smoke tests](docs/VCL_DEMOS.md) · [VCL coverage](docs/VCL_COVERAGE.md)
- [Validation record](docs/VALIDATION.md) · [Hardware matrix](docs/HARDWARE_MATRIX.md)
- [Component plan and roadmap](docs/COMPONENT_PLAN.md) · [Payments (deferred)](docs/PAYMENTS.md)
- [API documentation standard](docs/API_DOCUMENTATION.md) · [Known Delphi issues](docs/DELPHI_ISSUES.md) · [Legacy cleanup](docs/LEGACY_CLEANUP.md)

**Core and readers**

- [PC/SC transport](docs/PCSC_TRANSPORT.md) · [Reader and card events](docs/READER_EVENTS.md)
- [ATR and BER-TLV](docs/PROTOCOL_CORE.md) · [ATR and EMV tag catalogs](docs/CARD_CATALOGS.md)
- [Native USB-HID](docs/USB_HID.md) · [RFID keyboard/HID input](docs/RFID_HID.md) · [RFID reader models](docs/RFID_READER_MODELS.md)
- [ELATEC TWN4](docs/TWN4.md)

**Card families**

- [Belgian eID](docs/BELGIAN_EID.md) · [European eID / ICAO](docs/EUROPEAN_EID.md) · [EMV](docs/EMV_READER.md)
- [FeliCa / Type 3](docs/FELICA_TYPE3.md) · [Type 2 management and protected NDEF](docs/TYPE2_MANAGEMENT.md)
- [Contactless / MIFARE](docs/CONTACTLESS.md) · [NDEF](docs/NDEF.md) · [Type 2 passwords](docs/TYPE2_PASSWORD.md) · [Ultralight C / DES security](docs/LEGACY_MIFARE_SECURITY.md) · [NTAG210/212](docs/NTAG210_212.md) · [Type 4 NDEF](docs/TYPE4_NDEF.md) · [ISO 15693 / Type 5](docs/ISO15693_TYPE5.md)
- [DESFire](docs/DESFIRE.md) · [DESFire application/file management](docs/DESFIRE_APPLICATIONS.md) · [MOBIB / Calypso](docs/MOBIB_CALYPSO.md)
- [Programmable UIDs](docs/PROGRAMMABLE_UID.md) · [Raw UID](docs/RAW_UID.md) · [Gen3/Gen4](docs/GEN3_GEN4_UID.md) · [USCUID/FUID](docs/USCUID_FUID.md) · [Gen1b/partial](docs/GEN1B_PARTIAL_UID.md)
- [Contact memory cards](docs/MEMORY_CARDS.md) · [SLE4404](docs/SLE4404.md) · [SIM / USIM](docs/SIM.md)
- [Magnetic stripe](docs/MAGSTRIPE.md) · [MSR206/MSR605](docs/MSR206.md) · [MSR206-7HL](docs/MSR206_7HL.md)
