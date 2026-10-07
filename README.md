# CardStudio components

Modern Delphi components being extracted and rewritten from the original
CardStudio application. Public APIs use Delphi XML documentation for Help Insight.

The implemented foundation is a standalone RTL core:

- `ERD.Card.Bytes`: strict hex conversion, byte copying and comparison.
- `ERD.Card.APDU`: all short and extended command layouts, response codecs,
  explicit Le presence, error categories and byte offsets.
- `ERD.Card.ATR`: direct/inverse logical ATR decoding, interface groups, historical
  bytes, advertised protocols and mandatory TCK validation.
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
| `TEMVCardReader` | Available payment applications, card data and records |
| `TMemoryCardReaderWriter` | Supported memory-card families through appropriate reader adapters |
| `TContactlessCardReader` | Supported contactless families through distinct card profiles |

`TSmartCardReader` is implemented as a non-visual component in `src/pcsc`, with
reader discovery, T=0/T=1 connections, transactions, raw ATR reads and optional
monitoring. Its lifecycle is tested with an injected API; Windows/Delphi/hardware
validation remains pending. `TBelgianEIDReader` in `src/eid` reads identity, address,
JPEG photographs, raw signatures and five available public certificate files using
the documented Belpic 1.7/1.8 contact protocol. Its standalone decoders and injected
read sequences are tested; real-card validation and authenticity verification remain
pending. The other components are planned. See [the component plan](docs/COMPONENT_PLAN.md),
[the PC/SC guide](docs/PCSC_TRANSPORT.md) and [the Belgian eID guide](docs/BELGIAN_EID.md).

## Using the core

Add `src/core` to the Delphi unit search path. Source-based use does not require
installing a package. `packages/runtime/ERDCardCore.dpk` is an optional runtime
package; there is no design-time dependency or registration package yet.

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

The Windows script builds the Pascal tests, console examples and all three runtime
packages with XML documentation, range checks and overflow checks.
It has not been executed in the Linux development environment. Verify the generated
XML documentation and Help Insight in the target IDE as described in
[the documentation standard](docs/API_DOCUMENTATION.md).

No project-wide redistribution license has been selected yet. Existing third-party
code and datasets retain their own provenance and licensing requirements.
