# Component implementation plan

Build new implementations where the legacy architecture obstructs correctness.
The original code supplies domain examples and catalogs; its bugs and API signatures
are not compatibility requirements.

## Milestones

1. **Bytes and APDU — implemented.** Strict hex conversion and independent buffers;
   command cases 1, 2S, 3S, 4S, 2E, 3E, 4E; response codecs; XML-documented API;
   executable regression tests and source-aware static checks.
2. **ATR and BER-TLV — implemented.** Bounded byte readers, TCK validation,
   explicit limits, immutable TLV trees, deep cloning and canonical definite-length
   encoding. EMV encoded tags are supported; this is not a general ASN.1 schema
   validator. Separate immutable ATR-identification hints and 46 EMV tag descriptions
   are implemented with source attribution; see [the catalog guide](CARD_CATALOGS.md).
3. **TSmartCardReader — implementation available; Windows/hardware validation pending.**
   Instance-owned PC/SC transport with pointer-sized handles, transaction thread
   ownership, deterministic watcher cancellation/join, caller-thread event polling
   and Unicode reader selection by identity. An injectable API supports lifecycle
   tests without hardware; a Linux C shim exercises native adapter arguments/layouts.
   Runtime packages, palette registration and inspection/VCL examples are supplied.
   Real Delphi/Windows/card checks remain pending.
4. **TBelgianEIDReader — implementation available; Delphi/hardware validation pending.**
   Independent additive-TLV/UTF-8 decoders and a transaction-scoped public-file reader
   targeting the documented Belpic 1.7/1.8 contact interfaces. Identity, address,
   JPEG bytes, raw signatures and five public certificate roles; optional certificate
   availability is explicit. Runtime package, console/photo example and exact APDU
   tests supplied. Cryptographic authenticity, contactless PACE and real-card profile
   certification remain separate work. See [the eID guide](BELGIAN_EID.md).
   Shared ICAO MRZ/DG1/DG2 data codecs are available for the European expansion.
   `TICAODocumentReader` now implements explicit BAC and PACE ECDH-GM/AES-128
   (NIST P-256/brainpoolP256r1, MRZ/CAN), protected complete DG1/DG2/COM/SOD reads
   and large-photo B1 offsets through an optional OpenSSL 3 provider. Passive/SOD
   verification, additional PACE/EAC/national services and physical
   Dutch/Luxembourg/German card coverage remain pending; see [the support matrix](EUROPEAN_EID.md).
5. **TEMVCardReader — implementation available; Delphi/hardware validation pending.**
   PSE/PPSE discovery, explicit AID/PDOL selection, GPO formats 80/77 and bounded AFL
   record reads. Optional PAN/expiry/name/IBAN and packed Track 2 data, with explicit
   terminal inputs and no GPO replay. Optional GET DATA counters/log format and cyclic
   transaction-log snapshots are implemented without GPO. Runtime package, console
   example and synthetic APDU tests supplied. Payment kernels, cryptogram generation,
   scheme certification and nested DDF discovery remain separate work.
   See [the EMV guide](EMV_READER.md).
6. **TMagStripeReaderWriter — codecs/component/input adapters implemented; hardware validation pending.**
   Strict Track 1/2/3 framing and forward bit codecs, odd parity/data-column LRC,
   financial Track 1 format B/Track 2 fields and exclusive capability-checked
   reader/writer sessions. MagTek unencrypted ISO fixed HID/default keyboard read
   adapters use bounded host sources. Runtime package, console example and injected
   tests supplied. MSR206/MSR605 ISO profiles add native Windows COM reads and
   all-three nonempty programming with explicit high/low coercivity and status-only
   receipts; see [the serial guide](MSR206.md). The separate [7HL profile](MSR206_7HL.md)
   supplies all seven combinations with acquired same-swipe verified writes, USI1
   framing and native 7O1. Native MagTek capture, additional
   writer profiles, physical validation and verified YL160/MSR DLL/ABI bindings
   remain pending. See [the magstripe guide](MAGSTRIPE.md).
7. **TContactlessCardReader — storage profiles implemented; Delphi/hardware validation pending.**
   Explicit injectable PC/SC storage command profile, UID retrieval and supplied-key
   Classic Mini/1K/4K layout/block operations. Authenticated data writes exclude
   manufacturer/trailer blocks; uncertain write completion is explicit and never replayed.
   Original Ultralight, both EV1 memory sizes and NTAG213/215/216 have explicit page
   layouts, guarded user-page writes and complete user-memory snapshots. Dedicated
   Gen2/CUID four/seven-byte UID programming preserves manufacturer metadata and
   distinguishes EEPROM read-back from active RF verification.
   `TRawUidProgrammer` additionally implements four-byte Gen1a/Gen1b/unsealed UFUID and
   seven-byte Type 2 DirectWrite UID programming. `TAcr122RawReader` supplies the
   ACR122U/PN532 seven-bit raw-RF adapter, explicit CRC, exclusive lifecycle and
   fresh UID selection. Gen3 adds independent four/seven-byte UID-register programming;
   Gen4 UMC adds Classic/Type 2 four/seven/ten-byte manufacturer layouts, explicit
   backdoor password, stable configuration and fresh verification. See [the raw UID
   guide](RAW_UID.md) and [Gen3/Gen4 guide](GEN3_GEN4_UID.md). USCUID/GDM adds
   public/hidden four/seven-byte sources with both wakeup styles and unchanged
   configuration. Factory FUID has a separate authenticated one-time write API;
   see [USCUID/FUID](USCUID_FUID.md). Configuration-verified partial UFUID/ZUID/PFUID
   profiles use distinct read opcodes and persistent verification; see
   [Gen1b/partial profiles](GEN1B_PARTIAL_UID.md).
   Runtime package, UID/Type 2 example and synthetic transcripts supplied.
   `TType2PasswordCardReader` implements supplied-password EV1/NTAG user-memory
   access, PACK verification and single-write read-back in a retained raw session;
   see [Type 2 password access](TYPE2_PASSWORD.md).
   Bounded NDEF framing/chunk reassembly, strict Text/URI/MIME/external/Smart Poster
   helpers and public contiguous Type 2 CC/TLV reads/verified length-last updates are
   implemented; see [NDEF](NDEF.md). Public Type 4 mapping 1.0/2.0 CC/file reads and
   verified NLEN-last writes through ISO 7816 are also implemented; see
   [Type 4 NDEF](TYPE4_NDEF.md). Addressed ISO 15693 information/block access and
   initialized public Type 5 NDEF reads/verified length-last updates are implemented
   through an explicit ACR1552U-M/ACM1552U-Y/Z session adapter; see
   [ISO 15693/Type 5](ISO15693_TYPE5.md). Additional NDEF tag-type access, further UID
   generations, other Type 2 authentication, additional DESFire security, Plus and
   broader reader backends remain separate profiles; see [the contactless guide](CONTACTLESS.md).
   `TDesfireCardReader` now implements native ordinary-file discovery, data/value/record
   reads and verified standard-data writes. Explicit EV1/EV2 AES profiles provide mutual
   authentication and Plain/MACed/Full messaging through maintained Windows CNG or
   optional Linux OpenSSL; settings are authenticated. EV2 NonFirst can switch to a
   second supplied key while preserving TI and command counter. Retained sessions provide
   owned backup/value/record transactions, explicit commit/abort, full post-commit
   verification, protected directories and basic AES application/ordinary-file create/delete.
   AES management also reads free memory/key versions and changes key policy/file
   access; rotation proves the new key through fresh authentication/version reads.
   See [native DESFire](DESFIRE.md). D40/3DES, LRP, TMAC receipts, key sets/extended
   configuration, originality and physical validation remain pending.
   **TMemoryCardReaderWriter** implements the eight SLE4432/4442/5532/5542 and
   SLE4418/4428/5518/5528 models plus I2C 1–1024-kilobit geometries through explicit
   ACR38 CCID/ACR39 profiles. It reads snapshots/retry/protection state, verifies
   supplied PINs, performs read-back-verified writes, changes two-wire PINs and
   explicitly locks SLE protection bits. See [memory profiles](MEMORY_CARDS.md).
   [SLE4404](SLE4404.md) adds distinct guarded code access, bit programming and
   explicit verified erases. Generic RFID keyboard and host-fed HID report adapters
   are supplied separately through ERDCardInput. The concrete [TWN4 backend](TWN4.md)
   adds supplied-key Classic and public Type 2 memory access through PRS/USB-CDC. Further chip families/readers remain planned. Non-Java chips do not share one universal protocol.
8. **Distribution — source/projects available; Delphi/IDE validation pending.**
   Eleven runtime packages, nineteen-component standalone palette registration, isolated Win32/Win64
   Debug/Release build projects, console examples and two worker-based VCL read/write
   demos are supplied. See [installation](INSTALLATION.md), [demos](VCL_DEMOS.md) and
   [validation](VALIDATION.md). Published scalar configuration is streamed; interface
   dependencies are supplied at runtime. Actual package installation, designer/Help
   Insight, Windows/DPI and hardware checks remain outstanding.

The next VCL expansion uses separate family demos with shared infrastructure,
covering the remaining read/write/authentication/administration/tool APIs; see
[the explicit coverage checklist](VCL_COVERAGE.md).

Magstripe codecs and input adapters now provide a base for concrete native reader/writer integrations.

Payments are deferred until the card read/write library has stabilized; see
[PAYMENTS.md](PAYMENTS.md). Broad reader and card coverage remains the active goal.
Adding a reader backend does not automatically add all card protocols: maintain an
operation-specific hardware matrix.

The obsolete application has been removed. Selected original protocol code is
retained in `reference/legacy` for implementation research, outside runtime packages
and validation coverage. See [the cleanup record](LEGACY_CLEANUP.md).

## Next coherent batches

Packages and VCL read/write examples are now supplied. Stabilization and broader
card coverage are the next priorities; payments are outside the active roadmap.

The Type 2, Type 4 and Type 5 NDEF increments combine pure codecs, record/descriptor
handling, verified card components, examples, protocol failure tests and API
documentation. Use the same complete scope for upcoming batches:

1. **Delphi/Windows and hardware validation:** build both architectures, install the
   palette in the matching IDE, verify DFM streaming, Help Insight and DPI, then
   exercise the demo operations on known cards/readers, including write/read-back
   and disconnect failures. Turn confirmed combinations into a coverage matrix.
2. **Further magstripe profiles:** additional MSR206 physical model combinations
   and native MagTek capture,
   then YL160/MSR DLL bindings with verified SDK headers and buffer lengths.
   Physical/firmware coverage and status-versus-read-back evidence stay explicit.
3. **DESFire expansion and additional chip families:** D40 and EV1 DES/2K3DES/3K3DES security,
   EV2 key sets, LRP, TMAC receipts and extended configuration/SDM/rights, followed by
   originality and physical card profiles. Owned ordinary transactions and basic create/delete
   management and verified AES key/policy/access administration are implemented. EV1/EV2 AES secure
   file access and EV2 NonFirst through maintained providers are implemented. Then Plus profiles,
   additional ISO 15693 authentication/reader backends,
   then authenticated AT88SC/CryptoMemory and additional reader backends.
   SLE4404 code access/programming/explicit erases are implemented through ACS38 CCID;
   [USB-HID RFID input](RFID_HID.md) supplies keyboard and explicit host-fed report profiles.
   SLE/I2C memory, explicit SLE4406/4436/5536/6636 counter commands and public
   ISO 15693/Type 5 access are implemented. Chip-specific counter arithmetic and
   personalisation-code proof remain separate extensions.
4. **European eID:** BAC and PACE ECDH-GM/AES-128 secure access with complete
   DG1/DG2/COM/SOD reads are implemented. Next: passive/SOD verification, chip/EAC
   authentication, more PACE profiles and concrete Netherlands/Luxembourg/Germany
   hardware/national-service integration.
5. **Additional read/write examples and protocols:** authenticated DESFire/eID demo
   flows after validation, Classic/Type 5/password Type 2 profiles, and concrete
   contact memory-card chips and reader protocols. No universal support is inferred.

Authentication, hardware coverage and successful operations remain explicit per
profile; each batch requires its own validation rather than inheriting a universal
read/write claim from the transport.

## Architecture

- Core codecs depend only on the RTL and return typed data.
- APDU reader adapters implement the shared byte transport; magstripe adapters
  implement the separate device/session contract. Parsers do not open hardware.
- Non-visual component wrappers expose configuration, lifecycle and events.
- VCL presenters turn results into UI; the data model does not hold controls.
- Vendor DLLs, large external data catalogs and optional providers stay out of the
  base runtime package. The small curated ATR hint catalog is an optional core unit;
  EMV metadata stays in the EMV package.
- Cryptographic primitives use a maintained system library. Core contains the
  AES/EAC provider contracts and MAC composition; Windows CNG and OpenSSL 3 have
  separate optional runtime packages.
  Security modes and administrative/transactional commands need explicit profiles.
- Do not activate readers in constructors or in the IDE designer.

## Completion criteria

Each milestone includes documented declarations, tests for successful and failing
behavior, the existing Pascal readers on an explicit source selection, and a Delphi
build for the supported targets. Hardware features require real adapter/card tests.
Linux core tests and XML well-formedness do not substitute for Delphi or Help Insight.

## Application workflows

Twenty-three palette components implement Classic/Type 2/ISO15693 memory copy,
backup/compare/restore, programmable UID, Classic credentials, Type 1-5 NDEF,
magstripe, contact-memory, DESFire application migration/provisioning and batch
personalization, SIM contact/SMS planning and inspection. Eighteen independent workflow demos have their own forms/DFMs.

Contact-memory workflows cover ordinary SLE/I2C data with explicit PIN retry
budgets and protection preflight. DESFire supports complete ordinary application
snapshots and standard/backup/value/record migration, with explicit transaction
ownership and application/file provisioning. Both can be prepared as batch
children through the existing factory contract. SLE4404/counterchip snapshot,
comparison, explicit programming/erase plans and checked resume, plus ordered
DESFire creation/content/key/access-policy personalization are implemented.
eID/EMV/MOBIB structured inspection and privacy-aware report pipelines are implemented;
see [INSPECTION_REPORTS.md](INSPECTION_REPORTS.md). Supplied-password Type 2/ISO15693
memory workflows and reviewed credential/protection plans are implemented; see
[PROTECTED_WORKFLOWS.md](PROTECTED_WORKFLOWS.md).
SIM/USIM now includes complete record snapshots, reviewed restore/apply, free-slot
ADN/EXT/EMAIL/ANR and SMS import plans, explicit multipart groups and inspection.
See [WORKFLOWS.md](WORKFLOWS.md) for exact contracts and evidence.
