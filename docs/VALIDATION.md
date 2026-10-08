# Library validation record

The complete protocol/component/example suite was rebuilt and rerun in Linux on
2026-10-08 after adding ordinary/counter memory, SLE4404, USB-HID RFID input and TWN4 memory,
seven separate VCL family projects and SIM/USIM, the memory/RFID pages and standalone design bundle, starting from the
maintainer's latest IDE changes (`951ea62`). The full run passed **2,153,059 assertions
across 38 program runs**: 1,789,463 existing protocol assertions, 65,619 RFID
input/profile, 60,114 SLE4404, 34,280 counter/profile, 2,955 ordinary-memory,
85 demo-worker and 1,464 family-executor, 127,696 TWN4 and 21 registration assertions and 71,362 SIM/USIM assertions. All 34 Python regression tests,
21 Pascal readers on 141 sources and distribution checks for twenty-two projects passed.

The maintainer confirmed warning-free compilation and installation of the prior
packages in RAD Studio 12 (Studio 23.0), Debug/Win32. Both VCL demos subsequently
reported EThread during startup; the shared post-construction StartWork fix was
merged. The maintainer also intentionally removed the design package's runtime
BPL dependencies after an installation failure. This follow-up keeps that choice
and explicitly bundles all 46 registration/runtime source units. Fresh Delphi
builds and IDE installation of this new bundle/Memory/Input/TWN4/SIM packages, VCL execution,
Help Insight and physical memory-card compatibility remain unverified.

| Check | Result |
| --- | --- |
| Actual Pascal bytes/APDU tests | 521 assertions in seven groups passed |
| Actual Pascal ATR/TLV tests | 1826 assertions in seven groups passed |
| ATR hint and EMV tag catalogs | 65812 assertions in two groups passed: exact/masked overlaps, ambiguous models, every bad TCK, copied catalog buffers, invalid definitions and all two-byte tag identifiers |
| AES-CBC/CMAC and EV2 secure-message codecs | 734 assertions in two groups passed through OpenSSL and again through the actual CNG adapter/Linux shim: NIST/NXP vectors, every encrypted-response bit, counters and exact padding/lengths |
| Native DESFire component | 30382 assertions in eight groups passed through OpenSSL and again through CNG/Linux shim: public/EV1/EV2/NonFirst Plain/MACed/Full chains, 52 independent transcripts, verified writes, all I/O/protected-response bits, access/nonce/release failures |
| Retained DESFire sessions and management | 106508 assertions passed through OpenSSL and again through CNG/Linux shim: 51 independent transcripts, backup/value/record staging and verification, authenticated directories, all ordinary create/delete forms, commit/abort evidence, every protected transaction response bit and transaction/admin I/O boundary, rights/bounds/quota/thread/lifetime failures |
| DESFire AES key/access administration | 204490 assertions passed through OpenSSL and again through actual CNG/Linux shim: 26 independent transcripts, policy/count preflight, EV1 free/protected rights, current/other/PICC rotation with fresh new-key proof, protected wrong versions/settings/geometry, all I/O/protected-response bits, denied policy and no replay |
| Native ICAO EAC primitives/SM | 505 assertions passed through dynamically loaded OpenSSL 3: official BAC SHA1/KDF/Retail MAC/protected APDUs and PACE brainpool mapping/shared keys, both native curves, scalar/point/reflection/failure/lifetime checks, zero nonce, padding/SSC overflow and canonical CardAccess |
| ICAO BAC/PACE document component | 555397 assertions passed: nine independent exact transcripts, BAC and brainpool/NIST PACE, MRZ/CAN/ambiguous parameters, complete DG1/DG2/COM/SOD, 66000-byte photo/B1 offsets above 32767 and 65535, every I/O/protected-response bit, invalid padding/inner errors, entropy/release/bounds/reentrancy and owned results |
| Injected PC/SC transport tests | 86 assertions in seven groups passed, including real thread execution and transport transaction capability |
| Belgian eID decoders and reader | 1821 assertions in seven groups passed using synthetic exact APDU transcripts |
| ICAO MRZ and DG1/DG2 data codecs | 297 assertions passed: published MRZ examples, synthetic FAC/CBEFF records and malformed inputs |
| EMV data codecs, application reader and diagnostics | 1605 assertions in nine groups passed, including exact PSE/PPSE/GPO/AFL/GET DATA/log transcripts and resource limits |
| TWN4 PRS/CDC memory | 127696 assertions passed: literal ASCII/CRC/tag/Classic/Type 2 chains, all byte-I/O failure boundaries and block/page read-back bits, stale/changed IDs/content, both key types, no-ops, pre/post-dispatch deadlines/reversal, ownership and cleanup; native TWN4 hardware not tested |
| SIM / USIM | 71362 assertions: independent identity/alpha/ADN/SMS/service/PBR vectors, literal classic/UICC APDU chains, PIN budgets and proof, continuation/length bounds, caller ownership, full-file/record writes, every I/O failure and read-back bit, no replay and cleanup uncertainty |
| RFID input/report profiles | 65619 assertions passed: exhaustive two-byte decimal conversion plus independent wide/overflow vectors, literal boot/report-ID/ASCII fields, framing/deadlines/discard recovery, held keys/errors, event ownership and reentrancy; no physical USB opening |
| SLE4404 | 60114 assertions passed: literal code/program/scratchpad/application erase transcripts, budgets/success proof, all I/O boundaries and read-back bits, chunking, stale state, owned caller buffers and release uncertainty; no physical card |
| Contact memory profiles | 2955 assertions in nine groups passed: nineteen geometries, literal ACR38/ACR39/SLE/PIN/protection/page/bank transcripts, wrong/blocked retry counters, every write/PIN-chain I/O failure, every acknowledgement status/read-back data bit, no-op/locked ranges, release evidence, credential copies and acquisition recovery; no physical chip access |
| SLE counter chips / capabilities | Full run: 34,280 assertions passed; four explicit models, all write modes/address boundaries, literal select/program/carry/backup/challenge/retrieval commands, every write-chain I/O failure, wrong statuses/lengths, all window data bits, stale preflight, zero-to-one refusal, release evidence, owned input arrays, failed acquisition recovery and mandatory carry dispatch; ACR39 counter support is not claimed |
| Contactless Classic/Type 2 storage and programmable UID | 6365 assertions in twelve groups passed, including protected pages, complete snapshots, four/seven-byte Gen2 programming, separate factory FUID one-time writes and uncertain outcomes |
| Raw RF UID programming and ACR122U adapter | 8179 assertions in twenty-three groups passed, including Gen1a/Gen1b/unsealed UFUID, partial UFUID/ZUID/PFUID, Type 2 DirectWrite, Gen3, all six Gen4 layouts, partial writes, USCUID/GDM hidden/public sources, password-command wiping, bit framing and complete adapter-chain transcripts |
| Password-authenticated Type 2 user memory | 2062 assertions in seven groups passed for both EV1 sizes and NTAG213/215/216, including retained-session PWD_AUTH/PACK, bounded snapshots, verified writes and concrete adapter integration |
| NDEF codecs, RTDs and public Type 2 access | 36962 assertions in five groups passed: bounded framing/chunks, strict Unicode, factory CC/TLV mapping and guarded write failures |
| Public Type 4 NDEF files | 48480 assertions in four groups passed: mapping 1.0/2.0 CC/APDU transcripts, whole-file bounds, explicit file selection, MLe/MLc segmentation and every partial/later-command failure |
| ISO 15693 memory and public Type 5 NDEF | 280409 assertions in five groups passed: literal addressed commands, concrete ACS adapter chains, all block sizes, 65535-byte TLV maximum, cross-block length fields, protected/partial writes and session cleanup |
| Magstripe codecs, component and MagTek input adapters | 57326 assertions in four groups passed: published parity/LRC vectors, all track lengths and single-bit errors, financial fields, synthetic HID/keyboard frames and verified-write failure contracts |
| MSR206/MSR605 ISO serial profiles and generic status programming | 9052 assertions in six groups passed: published frames, all statuses/combinations, complete chains, every I/O failure and programming reply corruption, aggregate deadlines and poisoned-session cleanup |
| MSR206-7HL USI1 and same-swipe verified writing | 28393 assertions in five groups passed: all seven combinations, literal BCC/commands, complete read/write chains, every I/O failure/response corruption, independent mismatches, streaming bounds and inter-character timing |
| Native Windows serial branches | 48 assertions passed against a Linux C ABI shim, including complete 8N1 status programming and 7O1 acquired verified-writing component/adapter/COM transcripts |
| Native Windows adapter branches | 38 assertions passed against an isolated Linux C ABI shim |
| Native Windows CNG branches | 51 assertions passed: native argument/length/IV handling, every encrypt/decrypt call failure, handle cleanup and system RNG failure without fallback |
| Console examples | All nineteen built; hardware-free help/inspection checks passed, including TWN4 offline framing/help and SLE4404 help/window and invalid-before-hardware checks, memory-model geometry and DESFire key/access administration offline help/plan, ICAO help/CardAccess inspection, DESFire management offline help/plan and invalid arguments, APDU/NDEF/Type 4/Type 5/DESFire valid/invalid cases, ATR known/unknown/bad-TCK and EMV known/private tags, magstripe parity and MSR206 frame/status cases |
| Demo worker and offline operations | 85 assertions passed: nested credential deep copies/wiping, copied argument arrays, real worker/caller separation, request ownership, single delivery, join, nil executor, sanitized errors, verified-write evidence, offline operations and hardware preflight, suspended destruction, duplicate start and completed restart |
| Family demo executors | 1464 assertions passed: offline APDU command/response, ATR, TLV, EMV metadata, NDEF and RFID conversion/report profiles; all valid device-action preflights; invalid choices, PIN lengths, expected ranges, acknowledgement and credentials in public fields refused before hardware; literal memory/counter/SLE4404 and TWN4 command chains; no replay; uncertain writes and completed proof across transaction/connection/CDC cleanup failures |
| Palette registration / RTL streaming | 20 assertions passed: actual Register routine captures nineteen classes; inactive construction and FPC component stream round-trip for each; DesignIntf capture is not an IDE/ABI test |
| Distribution / VCL source readers | Twenty-two MSBuild projects (all four Debug/Release × Win32/Win64 property combinations), two groups and three DFM forms passed: references, package ownership/order, explicit IDE package identity, native Base/configuration/platform activation, GenDll/GenPackage, named DCP dependencies, native integer-overflow/debug settings, BOM/CRLF/resources, runtime/design dependency separation, palette completeness, field/event bindings, form creation and Platform/Config output isolation; no Delphi/VCL execution |
| FPC range/overflow/heap checks | Passed; no unfreed allocations in passing test programs |
| Python checker regression tests | All 34 passed, including nineteen distribution-reader cases; coverage includes IDE package identity, native configuration inheritance, omitted empty IDE platform groups, owning-package dependencies, explicit standalone design copies without dependency-owned duplicates, group target order, named DCPs, resources, BOM/CRLF, compiler property types and bounded condition parsing |
| Pascalcheck core profile | All 21 readers passed on 141 explicitly selected source files |
| XML documentation | 1708 visible production API declarations and 226 VCL example declarations inspected; zero findings; exported test-vector declarations also pass the full profile |
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
and unused test-result variable notes. None has been suppressed. Production TWN4/RFID/SLE4404/PCSC
and eID/EMV/contactless units compile without additional FPC warnings in the tested branches.

The suite reported 2,153,059 passing assertions across 38 program runs, including
65,619 RFID, 60,114 SLE4404, 34,280 counter/profile, 2,955 memory-card,
85 demo-worker and 1,464 family-executor, 127,696 TWN4 and 21 registration assertions and 71,362 SIM/USIM assertions.
The full 21-reader profile covers 141 Pascal sources, including the VCL units.
Only the non-VCL workers/executors and inactive component registration/streaming
were compiled/executed under FPC. The actual forms, MSBuild projects, package BPLs
and batch scripts require [Delphi/Windows validation](INSTALLATION.md).
The supplied [VCL smoke-test guide](VCL_DEMOS.md) records the remaining manual steps.

The eID suite checks independent buffers, unknown and empty fields, additive FF
length boundaries, malformed and supplementary Unicode, certificate DER envelope
lengths/padding, exact AID/MF/DF/EF selection, grouped reads, optional certificate
states, bounded 61xx/6Cxx handling, EOF probes, 15-bit offsets, partial failures,
no transport replay and transaction-release exception precedence. Its JPEG and
certificate payloads are synthetic protocol fixtures, not decoded image or X.509
validation tests. A total of 2081652 Pascal assertions passed across 37 test-program
runs, including all three native ABI shims and the crypto/DESFire suites repeated
through the actual CNG adapter.
NDEF tests exercise complete MB/ME/chunk framing, independent Text/URI vectors,
message/record/physical-chunk bounds, Unicode errors, all URI prefixes, Smart Poster
semantics and deep buffer ownership. Its PC/SC memory backend checks all six Type 2
layouts, factory NTAG213 control TLVs, advertised/physical capacity differences,
short/extended header transitions, unchanged out-of-capacity bytes, lock/AUTH0/mirror
preflight, every partial write, page/full-memory verification, changed CC and release
precedence. All writes use synthetic memory; there is no physical tag write.
The hardware-free NDEF example accepts a complete Text RTD vector and rejects
truncated data. Delphi compilation, IDE Help Insight and hardware checks remain pending.
Type 4 NDEF tests add strict CC parsing/descriptor limits, explicit mapping 1.0/2.0
APDU sequences, no application fallback, multiple-file disambiguation, NLEN range
and coherence checks, maximum ordinary file capacity, MLe/MLc/local limits,
verified invalidation/chunks/publication, preserved tails and no-op/clear behavior.
Every partial update and every later command failure stops without replay; changed
CC, malformed responses, denied statuses, protected access and release precedence
are tested through injected transports. The new console example inspects CC fixtures
without hardware; neither the tests nor smoke checks access a physical card.
ISO 15693/Type 5 tests additionally exercise both explicit address and response
conventions through the actual ACS FF-FB adapter, native error-code retention,
poisoned-session behavior and release failures. Independent CC/system-information
vectors cover geometry bounds, MLEN excluding CC and extended request placement.
Memory tests cover all physical block sizes 1..32, partial-block tails, opaque prefix
preservation, short/extended transitions, length fields spanning blocks, exact maximum
TLV length, locked later blocks before any dispatch and every I/O/partial-write
failure. Every staged block is checked independently and published length remains
zero until the final update. All card memory and transports are synthetic.
The catalog suite validates strict ATR/TCK before masked matching, shared/emulated
model hints, all matches, construction ownership and bounded invalid definitions.
It probes all 65536 two-byte tag identifiers and independently checks selected
EMV representation/length facts. The console examples inspect only supplied bytes
and metadata in smoke tests; no physical ISO 15693/NFC reader was accessed.
DESFire tests add native public/EV1/EV2 command framing, authenticated settings, all
ordinary file types, signed/24-bit bounds and Plain/MACed/Full AES sessions. Fixed
transcripts come from an independent optional Python cryptography generator, with
NXP published authentication/KDF/Full-message vectors and NIST CBC/CMAC vectors as
known-answer anchors. Tests inject every transport boundary and every protected
response bit, covering wrong rights, minimum-mode downgrade, failed/malformed RNG,
no-op writes, request/response AF chains, primary/release errors and post-dispatch
uncertainty. EV1 adds native AA authentication, chained-IV CMAC, first-eight-byte
tags, encrypted CRC32 and exact AES/CRC boundaries, including valid ciphertext
with invalid CRC/padding. NonFirst uses a distinct second key and two fresh test
nonces, preserving TI and counter 1 across the switch; backup/value/record reads
and verified standard writes are covered. All invalid EV1/NonFirst authentication
response lengths 0..40 stop immediately, and minimum mode is checked before switching.
Retained sessions add 51 independently generated literal transcripts for public/EV1/EV2
transactions and administration, including NonFirst and both AF directions. They verify
complete backup preservation with overlapping updates/no-ops; signed credit/debit/limited
credit and distinct native access routes; linear/cyclic append, eviction, clearing and
post-commit contents; protected directories; five ordinary create/delete file layouts;
and PICC-level AES application creation/deletion. Every transaction/admin I/O boundary
is injected, as is every bit of protected EV1/EV2 transaction responses. Valid integrity
with wrong committed data still fails verification. Tests distinguish lost commit/abort
acknowledgement from failed read-back/release after verified acknowledgement, and cover
TMAC/extended-file preflight, unrequested value options, bare NoChanges, local authority,
whole-backup/aggregate/record-growth bounds, signed extremes, limited-credit reuse,
256-write quota with permitted commit, component-independent lifetime, real wrong-thread
calls, reentrancy and destruction without implicit commit/abort. No management batch
rollback or TMAC receipt is claimed. The management example compiles and exercises only
offline help/plan and invalid arguments; no destructive hardware action runs in CI.
AES administration adds 26 independent transcripts for free-memory/key-version
reads, key settings, ordinary-file rights/mode changes and existing AES current/
other/PICC key rotation. Fresh mutual authentication with the new key and a matching
version are required; bare current-key acknowledgement alone is not success.
Valid-integrity wrong key versions/settings/file geometry, every operation I/O
boundary and every protected-response bit fail without replay; lost post-dispatch
proof is uncertain. Acquired key counts/permissions, read-only authority, invalid
arguments, fixed settings, authenticated source credentials and retained ownership
are checked. New-key proof does not replace a host credential-provisioning policy.
All four fixture generators reproduce the checked-in units exactly after EOL
normalization; original reference files still match Git/manifest hashes.
The identical crypto/DESFire suites also exercise the Windows CNG
adapter against a Linux OpenSSL-backed ABI shim. Native tests cover every CNG
encrypt/decrypt call failure, native lengths/IV mutation and handle cleanup.
OpenSSL 3 and its development headers are needed for this Linux crypto workflow;
Python cryptography is only needed to regenerate the checked-in fixtures.
No physical DESFire card was accessed. Windows CNG ABI/policy, Delphi, IDE and
real EV1/EV2/EV3/Light compatibility remain separate checks; see [DESFIRE.md](DESFIRE.md).
Magstripe tests check published MagTek bit vectors, complete character ranges,
all supported payload sizes and every single-bit error at every size, including SS,
ES and LRC parity. Typed financial fields retain opaque issuer suffixes. Synthetic
fixed HID/default keyboard input covers independent offsets, explicit report IDs,
undefined padding, selected decoder errors, all HID truncations and unsupported
encodings. Complete injected source/adapter/component chains verify bounded deadlines,
exclusive lifecycle, preflight, unselected-track preservation, same-card write-result
comparison, partial-write uncertainty, no retries and primary/release precedence.
No physical stripe was read or written. MSR206/MSR605 status programming and
native Windows COM I/O are now implemented and tested with injected streams/native
call shims. These tests cover shared deadlines, explicit coercivity confirmation,
exact all-three selections, poisoned sessions, uncertain partial programming and
cleanup. Status-only receipts never claim acquired read-back or trigger a second
swipe. Native host MagTek capture, additional backends and physical/Windows checks
remain pending. See [magstripe support](MAGSTRIPE.md) and [serial profiles](MSR206.md).
The ICAO additions now include native-provider BAC and PACE ECDH-GM/AES-128
(parameter 12/13, MRZ/CAN), secure messaging and complete acquired LDS files.
Official ICAO Part 11 Appendix D/G anchors and nine independent literal transcripts
verify the cryptographic/protocol composition. The component returns owned DG1/DG2,
COM and opaque SOD after exclusive release, including a complete synthetic 66,000-byte
encoded JPEG payload through B1/DO54/DO53 at both offset boundaries. No JPEG pixel
decode, SOD signature, issuer trust or national eID authorization is inferred.
Tests cover every read I/O boundary and protected-response bit, altered negotiation,
canonical CardAccess/version/domain selection, corrupted padding with valid MAC,
protected errors, failed entropy, bounded scalar rejection, acquisition/release,
reentrancy/configuration locking, file/aggregate limits and password copies.
Standalone native tests cover both curves, published brainpool mapping/shared key,
scalar/point/subgroup/infinity/reflection checks, failed-context lifetime, zero nonce,
provider loading, method-two padding and command/response SSC exhaustion.
The OpenSSL 3 backend runs dynamically on Linux; Windows loader/calling conventions,
Delphi and physical Netherlands/Luxembourg/Germany card generations remain pending.
Additional PACE/EAC, chip/passive authentication, SOD verification and national
services remain separate features; see [EUROPEAN_EID.md](EUROPEAN_EID.md).
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
Password-access tests cover five PWD_AUTH models, all excluded pages, mandatory
credential sizes, exact single-page FAST_READ and complete bounded snapshots.
Authentication NAK/timeout/transport/framing/CRC/PACK failures never replay or send
memory commands. Local credential copies are wiped and caller arrays remain
unchanged; same-session writes verify all four page bytes and report every
post-dispatch failure as uncertain. A complete ACR122U/PN532 write/read-back
transcript verifies retained authentication and cleanup.
Real payment-card behavior, contact/contactless schemes and Delphi package/IDE
integration remain pending; no payment kernel or scheme certification is claimed.

Pending: a fresh Delphi rebuild after the warning fixes, other configurations and
architectures, both VCL applications, designer/DFM loading,
DPI/layout and Help Insight checks, Windows
OpenSSL loader/deployment/ABI checks, generated XML/Help
Insight inspection in RAD Studio, and real Belpic 1.7/1.8 contact-card checks for
T=0/T=1, padded files, photographs, issued/unissued certificates and card removal.
Contactless reader/firmware/card compatibility and physical write/read-back tests
remain pending, including fresh RF activation after UID programming. Implemented raw Gen1a/unsealed
UFUID and Type 2 DirectWrite profiles are described in [RAW_UID.md](RAW_UID.md).
Implemented Gen3 and Gen4 UMC four/seven/ten-byte profiles are described in
[GEN3_GEN4_UID.md](GEN3_GEN4_UID.md). Implemented USCUID/GDM and factory FUID
profiles are described in [USCUID_FUID.md](USCUID_FUID.md). Gen1b and documented
partial UFUID/ZUID/PFUID profiles are described in [GEN1B_PARTIAL_UID.md](GEN1B_PARTIAL_UID.md).
Password-authenticated EV1/NTAG user-memory access is described in
[TYPE2_PASSWORD.md](TYPE2_PASSWORD.md). Remaining UID families and one-time fuses need
further concrete protocols and hardware validation;
see [the programmable UID matrix](PROGRAMMABLE_UID.md). No broad reader certification
or payment-processing support is claimed.
The scripts detect selected common errors; they do not prove compiler or hardware
compatibility. Refer to [the protocol guide](PROTOCOL_CORE.md),
[the PC/SC guide](PCSC_TRANSPORT.md) and [the eID guide](BELGIAN_EID.md) for the API boundaries.


## Native package-project repair

The user supplied `Delphi Packages/Core.dproj` and `Core.dpk` after reporting an
IDE access violation in `delphicoreide290.bpl`. The user confirmed that this native
Core package compiles successfully in Delphi. Both files are unchanged and are
used as the reference for this repair; this is user-reported evidence for the Core
source units, not a completed test of the rewritten ERD project set.
The nine package projects now declare `Borland.ProjectType=Package`; this was empty
in the earlier generated files. All eleven shipped project files now have
Base/Debug/Release configuration keys/parents, Windows activation groups, native
package generation flags/names and valid numeric debug-information metadata.
All 24 shipped project/package/group/application-source files use UTF-8 with BOM
and CRLF. Their `.res` files are generated through the IDE/MSBuild pipeline.
The package and VCL build scripts now invoke MSBuild rather than bypassing that
resource-generation step with direct DCC calls.

The new bounded property reader evaluates only the explicit comparison/and/or
conditions and property assignments in these files. It rejects unsupported syntax;
it does not execute MSBuild tasks/imports, generate resources or build BPLs.
Negative tests detect the old empty IDE package type, missing Base/activation/package flags, boolean debug
metadata, incorrect overflow property, missing dependencies/resources and encoding.
The maintainer subsequently confirmed that the packages build and install
successfully. This establishes a working Debug/Win32 package baseline in the
reported IDE; other targets and the warning-fix rebuild remain pending.
See [installation and retest steps](INSTALLATION.md).

## Delphi compiler-warning follow-up

The source changes address the supplied W1021, W1023, W1036 and H2077 diagnostics:
the TLV buffer-size check is compiled only when native lengths can exceed MaxInt;
Belgian identity tags use byte-set membership; DESFire Boolean options use a
matching byte comparison; unsupported MRZ formats explicitly raise before any
unassigned digit is used. Dead result assignments are removed, EMV log-format
validation still executes without storing its unused return value, and PC/SC
discovery assigns its exhausted-retry status after the loop.

The earlier W1033 repair restored six runtime dependencies and matching DCP
references. After the maintainer intentionally removed them for installation,
the current batch replaces implicit imports with an explicit standalone source
bundle and retains the design-only role. The maintainer's combined project group is retained with dependencies before
consumers in both project order and Build/Make/Clean targets. Runtime `.dproj`
files remain unchanged. No warning/hint directives are disabled.

The distribution checker now detects cross-package owned-unit imports without
the required owning DCP and inconsistent group target order. It accepts empty
platform configuration groups omitted by the IDE while still checking active
overrides and effective Debug/Release × Win32/Win64 settings. These are bounded
source readers, not a substitute for Delphi's package linker or IDE.


## Contact memory and standalone palette batch

The ACS ACR38x CCID 6.05 and ACR39 Series 1.05 documents are the protocol sources
for the eight SLE models and eleven I2C geometries. ACR39 two-wire reads require
an additional four-byte protection trailer; ACR38 CCID reads do not. Authentication
requires 9007 or 90FF and an independently restored counter, not ordinary 9000.
The tests use literal synthetic transcripts and cover 64-KiB bank transitions,
physical I2C pages, whole-range SLE protection preflight, irreversible compare-and-
lock operations and fresh new-PIN proof after reset. These are implemented profiles,
not physical reader/firmware certification. See [memory access](MEMORY_CARDS.md).

The new design bundle uses only rtl/vcl/designide SDK dependencies and explicitly
contains the complete 40-unit registration source closure, including Memory.
All fifteen inactive components construct and round-trip through the FPC RTL
streaming test. The bounded reader rejects missing source ownership and a bundle
that also loads a runtime package owning the same units. This does not test the
Delphi package linker/loader: the standalone installation change still needs a
fresh build and install in the user's IDE. Runtime packages remain separate for
applications. See [installation](INSTALLATION.md).

## VCL memory page and counter scope

The worker copies memory payload/PIN arrays before starting. Synthetic worker tests
exercise mutation of caller buffers, owned completion arrays, suppression of partial
ordinary/counter data on failure, offline ACS profile capabilities and invalid
memory requests before hardware creation. Form/DFM readers inspect both tabs and
bindings; actual VCL rendering and Delphi compilation remain untested here.

Counter geometry is a caller-declared readable window, not an inferred chip size.
Programming verifies the expected-before and expected-after window and refuses
zero-to-one transitions at the programmed address. Carry arithmetic, personalisation
code proof and host certificate verification are not implemented. The raw code
builder explicitly documents consumption of the presentation counter; it is never
automatically executed by the high-level component.

## Separate VCL family batch

Six native projects now share `ERD.Card.Demo.FamilyForm`, the family input catalog,
family executors and the existing post-construction worker lifecycle. The two older
VCL projects retain their forms. The shared DFM/aliases and all twenty MSBuild
projects pass the bounded distribution readers with the native BOM/CRLF conventions.
This does not execute Delphi's resource loader, IDE form designer or VCL controls.

The family executor uses the actual component validation against a rejecting
acquisition boundary, then opens only the explicitly selected native adapter.
Scripted tests verify complete command chains and malformed arguments without
using invented successful preflight card responses. Deep-copied credential arrays
are wiped on worker success/failure; caller buffers survive. Known write proof and
uncertainty remain separate when later cleanup fails. RFID raw-report examples are
host-fed decoding; no native USB enumeration/read/write backend was added.

[The family smoke tests](VCL_DEMOS.md#family-smoke-tests-on-delphiwindows) remain
pending on Delphi/Windows and real hardware. No payments or additional physical
card support are claimed by this demo batch.

## SIM follow-up validation

The full 38-program suite passed 2,153,042 assertions before the PBR extension.
After that extension, the focused SIM suite passed 71,362 (17 additional PBR
assertions) and the family executor passed 1,464 again; aggregate distinct final
program results are 2,153,059. InspectSim was separately built and checked against
literal ICCID/IMSI/alpha output and help; malformed input exits with failure.
Source validation, distribution readers and XML documentation were rerun after
these additions. Physical SIM/USIM and Delphi/Windows tests remain outstanding.
