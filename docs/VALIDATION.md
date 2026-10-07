# Library validation record

Validated in the Linux cloud environment on 2026-10-07 after the legacy cleanup.

| Check | Result |
| --- | --- |
| Actual Pascal bytes/APDU tests | 521 assertions in seven groups passed |
| Actual Pascal ATR/TLV tests | 1826 assertions in seven groups passed |
| Injected PC/SC transport tests | 86 assertions in seven groups passed, including real thread execution and transport transaction capability |
| Belgian eID decoders and reader | 1821 assertions in seven groups passed using synthetic exact APDU transcripts |
| Native Windows adapter branches | 38 assertions passed against an isolated Linux C ABI shim |
| Console examples | APDU valid/invalid cases passed; PC/SC and eID help work without hardware |
| FPC range/overflow/heap checks | Passed; no unfreed allocations in passing test programs |
| Python checker regression tests | All 15 passed |
| Pascalcheck core profile | All 21 readers passed on eighteen explicitly selected source files |
| XML documentation | 357 visible API declarations inspected; zero findings |
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
and eID units compile without additional FPC warnings in the tested branches.

The eID suite checks independent buffers, unknown and empty fields, additive FF
length boundaries, malformed and supplementary Unicode, certificate DER envelope
lengths/padding, exact AID/MF/DF/EF selection, grouped reads, optional certificate
states, bounded 61xx/6Cxx handling, EOF probes, 15-bit offsets, partial failures,
no transport replay and transaction-release exception precedence. Its JPEG and
certificate payloads are synthetic protocol fixtures, not decoded image or X.509
validation tests. A total of 4292 Pascal assertions passed across the suites.

Pending: Delphi dcc32/dcc64 builds, runtime package builds, generated XML/Help
Insight inspection in RAD Studio, and real Belpic 1.7/1.8 contact-card checks for
T=0/T=1, padded files, photographs, issued/unissued certificates and card removal.
The scripts detect selected common errors; they do not prove compiler or hardware
compatibility. Refer to [the protocol guide](PROTOCOL_CORE.md),
[the PC/SC guide](PCSC_TRANSPORT.md) and [the eID guide](BELGIAN_EID.md) for the API boundaries.
