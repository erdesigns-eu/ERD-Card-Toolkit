# Core validation record

Validated in the Linux cloud environment on 2026-10-07 after the legacy cleanup.

| Check | Result |
| --- | --- |
| Actual Pascal bytes/APDU tests | 521 assertions in seven groups passed |
| Actual Pascal ATR/TLV tests | 1826 assertions in seven groups passed |
| Console example | Accepts valid APDU syntax and rejects truncated command data |
| FPC range/overflow/heap checks | Passed; no unfreed allocations in passing test programs |
| Python checker regression tests | All 15 passed |
| Pascalcheck core profile | All 21 readers passed on seven explicitly selected source files |
| XML documentation | 146 visible API declarations inspected; zero findings |
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
Build outputs are ignored under `dist/core/fpc`. FPC reports an intentional
private-constructor warning for the internal TLV constructor and an unused
test-result variable note. Neither has been suppressed.

Pending: Delphi dcc32/dcc64 builds, runtime package builds, generated XML/Help
Insight inspection in RAD Studio, and any future hardware/card adapter tests.
The scripts detect selected common errors; they do not prove compiler or hardware
compatibility. Refer to [the protocol guide](PROTOCOL_CORE.md) for the API boundaries.
