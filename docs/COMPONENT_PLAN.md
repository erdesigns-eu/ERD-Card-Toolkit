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
   Runtime packages and an inspection example are supplied. Design-time registration
   and real Delphi/Windows/card checks remain pending.
4. **TBelgianEIDReader — implementation available; Delphi/hardware validation pending.**
   Independent additive-TLV/UTF-8 decoders and a transaction-scoped public-file reader
   targeting the documented Belpic 1.7/1.8 contact interfaces. Identity, address,
   JPEG bytes, raw signatures and five public certificate roles; optional certificate
   availability is explicit. Runtime package, console/photo example and exact APDU
   tests supplied. Cryptographic authenticity, contactless PACE and real-card profile
   certification remain separate work. See [the eID guide](BELGIAN_EID.md).
   Shared ICAO MRZ/DG1/DG2 data codecs are available for the European expansion.
   BAC/PACE, secure messaging and physical Dutch/Luxembourg/German card support
   are separate pending access-layer work; see [the support matrix](EUROPEAN_EID.md).
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
   See [native DESFire](DESFIRE.md). D40/3DES, LRP, TMAC receipts, key/rights/configuration
   management, originality and physical validation remain pending.
   **TMemoryCardReaderWriter** remains planned for contact memory-card families and
   matching readers. Non-Java chips do not share one universal protocol.
8. **Distribution.** Runtime/design-time packages, Delphi/Windows validation matrix,
   console and VCL examples, public API docs and dependency/data license inventory.

Magstripe codecs and input adapters now provide a base for concrete native reader/writer integrations.

Payment support will have terminal/provider and direct NFC-kernel adapters behind a
shared payment request/outcome contract. No payment adapter/kernel is implemented yet.
User-requested broad reader coverage and both payment routes guide subsequent work;
see [the concrete payment architecture and order](PAYMENTS.md). Adding a reader backend
does not automatically add all card protocols; maintain an operation-specific hardware matrix.

The obsolete application has been removed. Selected original protocol code is
retained in `reference/legacy` for implementation research, outside runtime packages
and validation coverage. See [the cleanup record](LEGACY_CLEANUP.md).

## Next coherent batches

The Type 2, Type 4 and Type 5 NDEF increments combine pure codecs, record/descriptor
handling, verified card components, examples, protocol failure tests and API
documentation. Use the same complete scope for upcoming batches:

1. **Further magstripe profiles:** additional MSR206 physical model combinations
   and native MagTek capture,
   then YL160/MSR DLL bindings with verified SDK headers and buffer lengths.
   Physical/firmware coverage and status-versus-read-back evidence stay explicit.
2. **DESFire expansion and additional chip families:** D40 and EV1 DES/2K3DES/3K3DES security,
   EV2 key sets, LRP, TMAC receipts and key/rights/configuration administration, followed by
   originality and physical card profiles. Owned ordinary transactions and basic create/delete
   management are implemented. EV1/EV2 AES secure
   file access and EV2 NonFirst through maintained providers are implemented. Then Plus profiles,
   additional ISO 15693 authentication/reader backends,
   then contact memory chips. Public ISO 15693/Type 5 access is already implemented.
3. **European eID access:** BAC/PACE and secure-messaging integration for the existing
   MRZ/DG codecs, with concrete Netherlands/Luxembourg/Germany card profiles.
4. **Payments:** a concrete terminal/provider integration, followed by a separately
   integrated direct NFC kernel where supported; data-reading alone cannot authorize payment.

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
  provider contract/CMAC composition; Windows CNG has a separate runtime package.
  Security modes and administrative/transactional commands need explicit profiles.
- Do not activate readers in constructors or in the IDE designer.

## Completion criteria

Each milestone includes documented declarations, tests for successful and failing
behavior, the existing Pascal readers on an explicit source selection, and a Delphi
build for the supported targets. Hardware features require real adapter/card tests.
Linux core tests and XML well-formedness do not substitute for Delphi or Help Insight.
