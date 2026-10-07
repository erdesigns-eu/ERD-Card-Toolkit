# Library validation record

Validated in the Linux cloud environment on 2026-10-07 after the legacy cleanup.

| Check | Result |
| --- | --- |
| Actual Pascal bytes/APDU tests | 521 assertions in seven groups passed |
| Actual Pascal ATR/TLV tests | 1826 assertions in seven groups passed |
| Injected PC/SC transport tests | 86 assertions in seven groups passed, including real thread execution and transport transaction capability |
| Belgian eID decoders and reader | 1821 assertions in seven groups passed using synthetic exact APDU transcripts |
| ICAO MRZ and DG1/DG2 data codecs | 297 assertions passed: published MRZ examples, synthetic FAC/CBEFF records and malformed inputs |
| EMV data codecs, application reader and diagnostics | 1605 assertions in nine groups passed, including exact PSE/PPSE/GPO/AFL/GET DATA/log transcripts and resource limits |
| Contactless Classic/Type 2 storage and programmable UID | 6365 assertions in twelve groups passed, including protected pages, complete snapshots, four/seven-byte Gen2 programming, separate factory FUID one-time writes and uncertain outcomes |
| Raw RF UID programming and ACR122U adapter | 8179 assertions in twenty-three groups passed, including Gen1a/Gen1b/unsealed UFUID, partial UFUID/ZUID/PFUID, Type 2 DirectWrite, Gen3, all six Gen4 layouts, partial writes, USCUID/GDM hidden/public sources, password-command wiping, bit framing and complete adapter-chain transcripts |
| Native Windows adapter branches | 38 assertions passed against an isolated Linux C ABI shim |
| Console examples | APDU valid/invalid cases passed; PC/SC, eID, EMV and contactless help work without hardware |
| FPC range/overflow/heap checks | Passed; no unfreed allocations in passing test programs |
| Python checker regression tests | All 15 passed |
| Pascalcheck core profile | All 21 readers passed on thirty-six explicitly selected source files |
| XML documentation | 705 visible API declarations inspected; zero findings |
| Reference integrity | All 26 retained files match the original Git bytes and manifest hashes |
| Patch whitespace | `git diff --check` passed |

Compiler: Free Pascal 3.2.2, Delphi mode, Linux x86-64. Compiler/RTL Debian packages
were extracted outside the repository. This run used:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 tools/run_core_tests.py \
  --fpc /workspace/.toolchains/fpc/root/usr/lib/x86_64-linux-gnu/fpc/3.2.2/ppcx64 \
  --rtl-dir /workspace/.toolchains/fpc/root/usr/lib/x86_64-linux-gnu/fpc/3.2.2/units/x86_64-linux/rtl
```

With a normally installed compiler, run `python3 tools/run_core_tests.py`.
Build outputs are ignored under `dist/core/fpc` and `dist/core/native`. The C shim
is compiled with GCC using `-Wall -Wextra -Werror`. The Windows adapter is recompiled
with `MSWINDOWS` into a separate output directory and linked against this shim.
The test covers pointer-sized handles, UTF-16 MULTI_SZ, IO-request/state layout,
native argument forwarding, bounded receive/ATR sizes and no command replay.
It uses the host Linux ABI, not Windows calling conventions or an actual driver.

FPC reports an intentional private-constructor warning for the internal TLV
constructor, a platform-dependent unreachable branch in the test handle factory,
and unused test-result variable notes. None has been suppressed. Production PC/SC
and eID/EMV/contactless units compile without additional FPC warnings in the tested branches.

The eID suite checks independent buffers, unknown and empty fields, additive FF
length boundaries, malformed and supplementary Unicode, certificate DER envelope
lengths/padding, exact AID/MF/DF/EF selection, grouped reads, optional certificate
states, bounded 61xx/6Cxx handling, EOF probes, 15-bit offsets, partial failures,
no transport replay and transaction-release exception precedence. Its JPEG and
certificate payloads are synthetic protocol fixtures, not decoded image or X.509
validation tests. A total of 20738 Pascal assertions passed across the suites.
The ICAO additions decode acquired files only; BAC/PACE, secure messaging and
direct access to Dutch/Luxembourg/German documents are still pending.
EMV tests exercise supplied PDOL values, GPO 80/77, optional fields, Track 2 fallback,
equal/conflicting duplicates, opaque issuer records, exact AID validation, status
and field-count bounds, transaction failures and no replay of GPO/transport failures.
The diagnostics additions cover optional counters/absence statuses, exact returned
tags and sizes, cyclic logs without GPO, format/record lengths, missing/empty logs,
record 255, capacity limits and release precedence. Contactless tests cover exact
storage commands, explicit profile selection, UID ownership, all Mini/1K/4K trailer
boundaries, supplied key A/B, slot one, local key-command overwriting, failed
load/authentication, protected writes before I/O, no write replay and uncertain
completion after transport/parse/release failures. All keys and card data are synthetic.
Type 2 tests validate all six datasheet layouts and excluded pages, masked configuration
reads, exact page APDUs, complete ascending-page snapshots, read failures and release
failures. Gen2/CUID tests validate explicit four/seven-byte manufacturer layouts,
cascade-marker constraints, BCC/metadata preservation, current UID/block consistency,
dedicated one-attempt writes, complete read-back and active UID verification. Matching
UIDs are no-op writes; a cached previous UID remains explicitly pending reactivation.
Failures after accepted programming cannot return completed snapshots. Original
Classic-only profiles still work and reject new optional capabilities before I/O.
Raw UID tests additionally check CRC-A golden vectors, four-bit ACKs, seven-bit
wakeup, HALT's explicit RF timeout, each partial Type 2 write, preserved static locks
and OTP/CC, fresh RF activation and full programmer/ACR122/transport integration.
Gen3 tests check fixed 07 framing and its independent UID register without block-zero
changes. Gen4 tests exercise all six existing Classic/Type 2 four/seven/ten-byte
layouts, 30/32-byte configurations, shadow/restore rejection, explicit supplied
passwords, local command wiping, complete hidden-byte preservation, original-byte
no-op snapshots, each partial write, persistent post-activation verification and
configuration/RATS cleanup. The concrete adapter chain also programs a synthetic
ten-byte UMC UID with automatic RATS disabled and a finite extended timeout.
USCUID tests exercise all six source/wakeup routes, every personalization byte9,
full persistent configuration, shadow rejection, hidden BCC/SAK cascade checks,
unchanged no-op snapshots, two-block partial writes and fresh RF verification.
A complete concrete GDM adapter chain verifies hidden/public writes and RF cleanup.
FUID tests enforce the factory UID/block precondition, a single authenticated write,
metadata preservation, cached-versus-active UID state, capability checks and
uncertain post-dispatch errors including denied status.
Gen1b tests verify appended enum ordinals, seven-bit40-only wakeup, no-op and
manufacturer-block consistency before and after RF activation. Partial UFUID/ZUID/
PFUID tests validate documented shapes, flag/SAK preservation, sixteen-byte
configuration responses, variant markers, reversed E1 PFUID reads, initial
UID/BCC checks, interrupted writes and persistent block/configuration comparisons.
Complete Gen1b and PFUID chains also pass through the concrete ACR122U/PN532 adapter.
Real payment-card behavior, contact/contactless schemes and Delphi package/IDE
integration remain pending; no payment kernel or scheme certification is claimed.

Pending: Delphi dcc32/dcc64 builds, runtime package builds, generated XML/Help
Insight inspection in RAD Studio, and real Belpic 1.7/1.8 contact-card checks for
T=0/T=1, padded files, photographs, issued/unissued certificates and card removal.
Contactless reader/firmware/card compatibility and physical write/read-back tests
remain pending, including fresh RF activation after UID programming. Implemented raw Gen1a/unsealed
UFUID and Type 2 DirectWrite profiles are described in [RAW_UID.md](RAW_UID.md).
Implemented Gen3 and Gen4 UMC four/seven/ten-byte profiles are described in
[GEN3_GEN4_UID.md](GEN3_GEN4_UID.md). Implemented USCUID/GDM and factory FUID
profiles are described in [USCUID_FUID.md](USCUID_FUID.md). Gen1b and documented
partial UFUID/ZUID/PFUID profiles are described in [GEN1B_PARTIAL_UID.md](GEN1B_PARTIAL_UID.md).
Remaining UID families and one-time fuses need
further concrete protocols and hardware validation;
see [the programmable UID matrix](PROGRAMMABLE_UID.md). No broad reader certification
or payment-processing support is claimed.
The scripts detect selected common errors; they do not prove compiler or hardware
compatibility. Refer to [the protocol guide](PROTOCOL_CORE.md),
[the PC/SC guide](PCSC_TRANSPORT.md) and [the eID guide](BELGIAN_EID.md) for the API boundaries.
