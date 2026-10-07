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
   validator. EMV tag descriptions and ATR-identification catalogs remain separate.
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
6. **TMagStripeReaderWriter.** Track codecs plus separate YL160/MSR adapters. Model
   device capabilities, errors, buffers and supported SDK/driver versions explicitly.
7. **TContactlessCardReader — first profile implemented; Delphi/hardware validation pending.**
   Explicit injectable PC/SC storage command profile, UID retrieval and supplied-key
   Classic Mini/1K/4K layout/block operations. Authenticated data writes exclude
   manufacturer/trailer blocks; uncertain write completion is explicit and never replayed.
   Runtime package, UID example and synthetic transcripts supplied.
   Ultralight/NTAG, DESFire/secure messaging, Plus, NDEF and broader reader backends
   remain separate profiles; see [the contactless guide](CONTACTLESS.md).
   **TMemoryCardReaderWriter** remains planned for contact memory-card families and
   matching readers. Non-Java chips do not share one universal protocol.
8. **Distribution.** Runtime/design-time packages, Delphi/Windows validation matrix,
   console and VCL examples, public API docs and dependency/data license inventory.

Magstripe work can progress independently once the byte/codec foundation is established.

Payment support will have terminal/provider and direct NFC-kernel adapters behind a
shared payment request/outcome contract. No payment adapter/kernel is implemented yet.
User-requested broad reader coverage and both payment routes guide subsequent work;
see [the concrete payment architecture and order](PAYMENTS.md). Adding a reader backend
does not automatically add all card protocols; maintain an operation-specific hardware matrix.

The obsolete application has been removed. Selected original protocol code is
retained in `reference/legacy` for implementation research, outside runtime packages
and validation coverage. See [the cleanup record](LEGACY_CLEANUP.md).

## Architecture

- Core codecs depend only on the RTL and return typed data.
- Reader adapters implement a common byte transport; parsers do not open hardware.
- Non-visual component wrappers expose configuration, lifecycle and events.
- VCL presenters turn results into UI; the data model does not hold controls.
- Vendor DLLs, data catalogs and optional providers stay out of the base runtime package.
- Do not activate readers in constructors or in the IDE designer.

## Completion criteria

Each milestone includes documented declarations, tests for successful and failing
behavior, the existing Pascal readers on an explicit source selection, and a Delphi
build for the supported targets. Hardware features require real adapter/card tests.
Linux core tests and XML well-formedness do not substitute for Delphi or Help Insight.
