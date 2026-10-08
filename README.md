# CardStudio components

Modern Delphi components being extracted and rewritten from the original
CardStudio application. Public APIs use Delphi XML documentation for Help Insight.

The implemented foundation is a standalone RTL core:

- `ERD.Card.Bytes`: strict hex conversion, byte copying and comparison.
- `ERD.Card.APDU`: all short and extended command layouts, response codecs,
  explicit Le presence, error categories and byte offsets.
- `ERD.Card.ATR`: direct/inverse logical ATR decoding, interface groups, historical
  bytes, advertised protocols and mandatory TCK validation.
- `ERD.Card.ATR.Catalog`: immutable, source-attributed ATR hints with strict ATR
  validation and all matching descriptions; no automatic card-profile selection.
- `ERD.Card.TLV`: bounded definite-length ISO 7816 BER-TLV decoding, EMV encoded
  tags, immutable owned trees, deep cloning and canonical encoding.
- `ERD.Card.Transport`: shared `ICardTransport` and optional `ICardTransaction` contracts.

The core has no VCL, reader, vendor-DLL or external package dependency. It does
not send commands to a card. The obsolete application and its supporting assets
have been removed. Selected original protocol code remains in `reference/legacy`,
outside the library. See [the cleanup record](docs/LEGACY_CLEANUP.md).

## Components

| Component | Responsibility |
| --- | --- |
| `TMagStripeReaderWriter` | Tracks 1–3 and device adapters for magstripe readers/writers |
| `TSmartCardReader` | PC/SC connections, reader discovery, card events and byte transport |
| `TBelgianEIDReader` | Belgian eID identity, address, photograph and available certificates |
| `TICAODocumentReader` | ICAO BAC/PACE access, secure messaging and complete DG1/DG2/COM/SOD with encoded photos |
| `TEMVCardReader` | Available payment applications, card data and records |
| `TMemoryCardReaderWriter` | Supported memory-card families through appropriate reader adapters |
| `TContactlessCardReader` | Supported contactless families through distinct card profiles |
| `TType2NdefCardReader` | Public Ultralight/NTAG NDEF access with guarded multi-page updates |
| `TType4NdefCardReader` | Public ISO 7816 NDEF files with bounded CC/MLe/MLc and verified NLEN updates |
| `TIso15693CardReader` | Explicit addressed ISO 15693 system information and guarded block access |
| `TType5NdefCardReader` | Initialized public Type 5 NDEF memory with CC/security preflight and verified length-last updates |
| `TDesfireCardReader` | Native DESFire files, EV1/EV2 AES secure messaging, EV2 NonFirst, verified standard-data writes, owned backup/value/record transactions and explicit application/file/key/access management |

`TMagStripeReaderWriter` in `src/magstripe` provides exclusive read sessions and
capability-checked selected-track writes with same-card verification and explicit
uncertain completion. Pure Track 1/2/3 text/bit codecs implement odd parity/LRC;
optional financial codecs preserve issuer-defined discretionary data. Concrete
MagTek fixed HID and default ISO keyboard parsers/read adapters accept host-supplied
bounded frames. MSR206/MSR605 ISO profiles add native Windows COM reading and
explicit all-three-track programming through `ProgramTracks`, returning device
status without claiming host read-back. The separate MSR206-7HL profile adds all
seven track combinations with acquired same-swipe verified writing, USI1 checksums
and native 7O1 serial framing. See [MSR206/MSR605](docs/MSR206.md) and
[MSR206-7HL](docs/MSR206_7HL.md).
Native MagTek capture, additional writers, verified YL160/MSR DLL bindings and
physical validation remain pending; see [the magstripe guide](docs/MAGSTRIPE.md).

`TSmartCardReader` is implemented as a non-visual component in `src/pcsc`, with
reader discovery, T=0/T=1 connections, transactions, raw ATR reads and optional
monitoring. Its lifecycle is tested with an injected API; Windows/Delphi/hardware
validation remains pending. `TBelgianEIDReader` in `src/eid` reads identity, address,
JPEG photographs, raw signatures and five available public certificate files using
the documented Belpic 1.7/1.8 contact protocol. Its standalone decoders and injected
read sequences are tested; real-card validation and authenticity verification remain
pending. `TEMVCardReader` in `src/emv` provides PSE/PPSE discovery, explicit AID/PDOL
selection, GPO and bounded AFL record reads with optional PAN, expiry, name, IBAN
and Track 2 data. Separate GET DATA counters and transaction logs work without GPO.
It is a data reader; GPO can change card state, and payment-kernel or scheme
certification is not provided. See [the EMV guide](docs/EMV_READER.md).
`TEmvTagCatalog` adds 46 source-attributed tag descriptions for diagnostic tools.
Together with the curated ATR catalog, it is documented in
[the catalog guide](docs/CARD_CATALOGS.md); lookup hints do not establish card identity.
`TContactlessCardReader` in `src/contactless` adds explicit injectable reader profiles,
UID retrieval and authenticated MIFARE Classic block reads/data writes with supplied
keys. Original Ultralight, EV1-48/128 and NTAG213/215/216 add page reads, guarded user
writes and complete memory snapshots. A dedicated Gen2/CUID four/seven-byte UID
programming method preserves manufacturer metadata, verifies the block and reports
whether the active UID also changed. Ordinary data writers reject manufacturer,
trailer and lock/configuration regions. Uncertain write completion has its own
exception and commands are never replayed. The PC/SC storage profile has synthetic
tests; real-card/reader validation remains pending.
`TType2PasswordCardReader` adds supplied-password Ultralight EV1/NTAG213/215/216
user-page reads, complete memory snapshots and verified single-page writes. Each
operation validates PACK and retains authentication within one raw-RF session;
see [the Type 2 password guide](docs/TYPE2_PASSWORD.md).
`TNdefCodec` and `TNdefRecords` provide bounded NDEF framing/chunk reassembly,
strict Unicode Text/URI, MIME/external records and Smart Posters. `TType2NdefCardReader`
adds CC/TLV-aware public Ultralight/NTAG NDEF reads and verified length-last updates,
with lock, protection, mirror and capacity preflight; see [the NDEF guide](docs/NDEF.md).
`TType4NdefCardReader` adds explicit mapping 1.0/2.0 application/file selection,
complete Capability Containers, bounded public NDEF reads and verified NLEN-last
updates through an ISO 7816 transport. Multiple files require an explicit identifier;
see [the Type 4 guide](docs/TYPE4_NDEF.md).
`TIso15693CardReader` and `TType5NdefCardReader` add bounded addressed block access
and initialized public Type 5 NDEF reads/verified updates. An explicit
`TAcr1552Iso15693Session` supplies the ACR1552U-M/ACM1552U-Y/Z FF FB dialect, with
caller-selected 8/16-bit addressing and response framing. Reader firmware and
physical-card compatibility still require validation; see
[the ISO 15693/Type 5 guide](docs/ISO15693_TYPE5.md).
`TDesfireCardReader` adds native discovery, standard/backup data, signed values and
linear/cyclic record reads, plus verified standard-data range writes. Its explicit
EV1/EV2 AES profiles implement mutual authentication and Plain/MACed/Full messaging
with authenticated settings and caller-supplied keys. Optional EV2 NonFirst switches
to a second key while preserving the acquired transaction identifier/counter. Windows CNG and optional
Linux OpenSSL supply the AES/CSPRNG backends; see [the DESFire guide](docs/DESFIRE.md).
Retained sessions add owned backup/value/record transactions, explicit commit/abort and
post-commit verification, authenticated directories and basic application/file create/delete.
Legacy D40/3DES security, LRP, TMAC receipts and key/configuration management remain separate
extensions; physical reader/card coverage is still pending.
`TRawUidProgrammer` adds four-byte Gen1a/Gen1b/unsealed UFUID and seven-byte Type 2
DirectWrite UID programming, with an opt-in ACR122U/PN532 raw-RF adapter. It preserves
manufacturer metadata, verifies fresh RF selection and treats interrupted writes as
uncertain. Gen3 UID-register programming and Gen4 UMC Classic/Type 2 layouts add
four/seven/ten-byte profiles with explicit passwords and preserved configuration.
USCUID/GDM adds public/hidden four/seven-byte sources for both wakeup styles.
Separate UFUID/ZUID/PFUID profiles verify partial configurations and handle PFUID’s
reversed read command; see [Gen1b/partial-profile guide](docs/GEN1B_PARTIAL_UID.md).
A separate authenticated factory FUID method performs one UID write with explicit
uncertain-result and cached-UID handling. See [the raw-RF guide](docs/RAW_UID.md),
[Gen3/Gen4 guide](docs/GEN3_GEN4_UID.md) and [USCUID/FUID guide](docs/USCUID_FUID.md).
See [the contactless guide](docs/CONTACTLESS.md). [Payments are deferred](docs/PAYMENTS.md)
until the card read/write components are stable. Other MIFARE/UID-programming families
and additional NDEF tag-type access layers remain future work. See [the programmable UID support matrix](docs/PROGRAMMABLE_UID.md).
The remaining components are planned. See [the component plan](docs/COMPONENT_PLAN.md),
[the PC/SC guide](docs/PCSC_TRANSPORT.md) and [the Belgian eID guide](docs/BELGIAN_EID.md).

The eID package provides ICAO TD1/TD2/TD3 MRZ and DG1/DG2 decoders plus
`TICAODocumentReader`: explicit BAC or PACE ECDH-GM/AES-128 (NIST/brainpool),
MRZ/CAN, protected complete files and large encoded photos. An optional OpenSSL 3
provider supplies native crypto. Exact Dutch/Luxembourg/German card generations,
passive authentication, EAC and national services require further work. See
[the European eID support boundary](docs/EUROPEAN_EID.md).

## Using the core

Add `src/core` to the Delphi unit search path. Source-based use does not require
installing a package. `packages/runtime/ERDCardCore.dpk` is an optional runtime
package. The separate `ERDCardDesign` package registers thirteen inactive components
on the palette; runtime packages retain no design-time dependency. See
[installation and package builds](docs/INSTALLATION.md) and the two
[VCL read/write demos](docs/VCL_DEMOS.md). Actual Delphi/IDE validation is pending.
`ICardAesProvider`/AES-CMAC utilities are in Core. The optional separate
`ERDCardCryptoWindows.dpk` provides the CNG backend from `src/crypto`, without
adding an OS cryptographic-library import to the base core package.
`ERDCardCryptoOpenSSL.dpk` optionally supplies the dynamically loaded OpenSSL 3
BAC/PACE backend; install a matching native library for its actual tests/use.

```pascal
uses System.SysUtils, ERD.Card.Bytes, ERD.Card.APDU;

// A syntax example: two data bytes and short Le = 256.
Command := TApduCodec.DecodeCommand(HexToBytes('0000000002AABB00'));
// Command.Data = AA BB; Command.Le = 256; Command.HasLe = True.
WireBytes := TApduCodec.EncodeCommand(Command);
```

Declare `Command: TApduCommand` and `WireBytes: TBytes` in the calling routine.
The example only demonstrates APDU syntax; no instruction semantics are implied.
Use the `Try...` methods to obtain structured errors without conversion exceptions.
Hex offsets are one-based characters; APDU, ATR and TLV offsets are zero-based bytes.
Dynamic-array fields share storage on ordinary record assignment: use `CopyBytes`
before editing such a copy. Decode and encode operations allocate independent output.
Do not alias a decoder's input with its `out` record's Data field.

For ATR and TLV use, ownership rules, normalization and limits, see
[the protocol guide](docs/PROTOCOL_CORE.md). TLV documents own their nodes;
free the document when finished and clone a borrowed node if it must outlive its owner.

## Validation

Run the source-aware Pascal readers, including XML-documentation coverage:

```sh
python3 tools/pascalcheck/run.py --profile core --source-root src --source-root tests --source-root examples -v
python3 -m unittest discover -s tests/tools -v
```

With Free Pascal 3.2.2 or later installed:

```sh
python3 tools/run_core_tests.py
```

An extracted compiler can be supplied with `--fpc /path/to/ppcx64` and
`--rtl-dir /path/to/units/x86_64-linux/rtl`. Outputs stay in ignored `dist/core/fpc`.
The NDEF example `InspectNdef <message-hex>` works without hardware and prints only
record structure/lengths. `InspectType4Ndef --cc-hex <hex>` inspects a complete CC
without hardware; its explicit reader mode reads public files. Tests cover Type 4
CC/APDU bounds and updates as well as framing/chunk bounds, Unicode and guarded
Type 2 writes with injected failures; see [the NDEF guide](docs/NDEF.md).
`InspectType5Ndef --cc-hex <hex>` inspects Type 5 containers without hardware;
its explicit reader mode reads initialized public tags. `InspectCardTools`
looks up ATR hints or EMV tag metadata. Tests cover ISO 15693 adapter chains,
Type 5 updates, interrupted writes and both catalogs.
`InspectDesfire --settings-hex <hex> --file <number>` inspects native settings
without hardware; explicit reader modes inspect metadata, optionally using a
supplied raw AES key file. Crypto/DESFire tests include NIST/NXP vectors,
independently generated transcripts and the actual CNG adapter through a Linux ABI shim.
`AdminDesfire --help`/`--plan` demonstrate the new AES administration API offline.
`ReadIcaoDocument --cardaccess <hex>` inspects advertised PACE without a library or
reader. Its explicit hardware mode uses a password file and can save encoded photos.
Tests check official ICAO BAC/PACE vectors, native EC agreement, independent APDU
transcripts and complete large-photo reads with secure messaging.
The tests exercise the actual Pascal units with range and overflow checks, all
command cases, length boundaries, invalid inputs, independent buffers and responses,
ATR checksums, TLV normalization, tree ownership and resource limits. Transport
tests exercise transaction ownership, independent instances, serialized commands,
failure cleanup and monitor cancellation/join. eID tests cover exact APDUs, UTF-8,
additive TLV, DER framing, certificate availability, bounded status handling and
transaction cleanup. Linux with GCC also runs an isolated
C ABI shim against the actual Windows adapter branches. This validates buffers,
Unicode and record layouts, not Windows calling conventions or real drivers. FPC heap
tracing also checks the Pascal test executables for leaked allocations.
Free Pascal execution is additional validation; it does not establish Delphi
compiler, Windows package or IDE compatibility.
See [the validation record](docs/VALIDATION.md) for the current results and remaining checks.

The intended Delphi baseline is 10.4 or later; a Delphi build and Help Insight
inspection still need to establish the supported versions. From a RAD Studio
command prompt on Windows:

```bat
tools\run-core-tests.cmd dcc32
tools\run-core-tests.cmd dcc64
```

The Windows script builds the Pascal tests, console examples and all eight runtime
packages with XML documentation, range checks and overflow checks. Build the
optional palette with `tools\build-packages.cmd dcc32 design` (use the IDE architecture),
and both VCL applications with `tools\build-vcl-demos.cmd dcc32` or `dcc64`. The new BAC/PACE
tests require matching OpenSSL 3 `libcrypto-3.dll` available to their Windows
executables; application code can instead supply an explicit native-library path.
It has not been executed in the Linux development environment. Verify the generated
XML documentation and Help Insight in the target IDE as described in
[the documentation standard](docs/API_DOCUMENTATION.md).

No project-wide redistribution license has been selected yet. Existing third-party
code and datasets retain their own provenance and licensing requirements.
