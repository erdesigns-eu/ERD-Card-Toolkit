# Library validation record

## Latest run: Calypso application/plans, EN1545 and extended MOBIB (2026-10-10)

What was added:
- `TCalypsoCardReader` now decodes application selection (startup
  information and a dialect recommendation that is never applied), tag `85`
  file information, an opt-in record size from the card, SFI reads and
  folder-qualified plans.
- `ERD.Card.EN1545` decodes fields from tables.
- The MOBIB decoder covers version-3 environments, version-0–2 and
  bitmap events, and version-4 contract end dates with monthly durations. It
  also covers counter fallback, ICC data and a candidate split of the
  contract list.
- `ERD.Card.MOBIB.Lookup` adds operator contexts, bundled Brussels stops and
  CSV tables.
- `ERD.Card.Calypso.Networks` recommends Intercode, Lisboa Viva, Rav-Kav,
  OPUS, Venezia and Pisa profiles but never applies one by itself.
- `ERD.Card.MOBIB.Report` produces text and JSON with confidence labels,
  and masks personal fields by default.
- MobibDemo gains operator, personal-field, record-size and read-plan
  options, plus a JSON export.

New test programs:

| Test program | Assertions |
| --- | --- |
| `CalypsoReader.Tests` (exact APDU transcripts) | 373 |
| `En1545.Tests` | 53 |
| `MobibExtended.Tests` (includes real De Lijn rows; see below) | 88 |
| `MobibLookup.Tests` | 31 |
| `CalypsoNetworks.Tests` | 49 |
| `MobibReport.Tests` | 88 |

The real De Lijn contract, special-event and contract-list rows are used with
the card holder's permission. Environment and holder fixtures stay synthetic.
The family-executor tests cover the new demo options against exact
transcripts.

Not covered:
- Folder selection through `3F00` has not been checked on a physical card.
- The other network profiles are marked `CheckedOnCard = False`.

## Latest run: Delphi Topaz timer import (2026-10-10)

The supplied RAD Studio 12 Win32 log reports E2003 for GetTickCount64 in the
ACR122 Topaz adapter. Delphi declares that API in Winapi.Windows, whereas Free
Pascal exposes it through SysUtils. The adapter now imports Winapi.Windows in
its Delphi-only implementation uses clause; RF timing and protocol behavior
are unchanged. The focused Topaz suite passed **26,938 assertions**, all **21
Pascal readers** passed on the changed unit, and distribution checks passed for
**39 projects, two groups and 26 DFM forms**. This records the source correction
and supplemental validation, not a new native Delphi compilation.

## Latest run: Topaz / Type 1 and reported Delphi diagnostics (2026-10-10)

The complete supplemental runner passed with Topaz 96/512 memory and initialized
Type 1 NDEF components, an explicit ACR122U/PN532 Jewel/CIU adapter and an independent
TopazDemo form/DFM. The focused Topaz suite passed **26,938 assertions** after adding
nonzero Terminator-TLV padding coverage. It covers all static/dynamic locks, exact
capacities, preimages, length-last updates, metadata preservation, independently
authored native transcripts, every RF response bit and dispatched failure/cleanup.
Family-executor tests passed **2,395 assertions**, including Topaz input preflight,
parsed Text records, identity and artifact exports. Inactive component registration/
streaming passed **32 assertions** for **31 palette components**. Distribution checks
passed for **39 projects, two groups and 26 independent DFM forms**. All **36 Python
regressions** and **21 Pascal readers**, including public XML documentation, passed.

The supplied RAD Studio 12 Win32 log contained six distinct diagnostics repeated
across packages. Redundant scalar Result initializations were removed from Type 2
credential/counter and Ultralight C key operations. HID exception cleanup no longer
assigns an unread Opened flag; its normal pre-close assignment remains to prevent a
second close after close failure. Calypso SAM READ RECORD validates Le directly in
its initialized command branch. DESFire's unsupported key-type branch raises directly,
so the compiler can prove that KeyTypeBits is assigned on every continuing path.
No hints/warnings were disabled. The existing SAM/DESFire/credential/event suites
passed after these edits. These are source fixes with supplemental regression evidence;
this environment did not perform a native Delphi compilation. Pre-existing Free
Pascal notes and its private TLV-constructor warning remain separate from the supplied
Delphi diagnostics. Earlier validation runs follow.

## Latest run: DESFire native application/file management (2026-10-09)

The full runner passed after extending explicit native application creation and
DES/3DES ordinary management. The independent legacy suite passed **24,326
assertions** through OpenSSL and the production CNG adapter/native shim, including
all five ordinary file types, all three new application storage types, metadata,
retained ownership, invalid counts and every management I/O failure boundary.
Family-executor tests passed **2,146 assertions**, including unselected type and
incorrect count rejection before hardware acquisition. Existing AES/session/key
administration suites remain included. All 21 source readers, distribution checks
and 36 Python regressions passed. The existing interface IIDs are unchanged; a new
optional interface exposes typed application creation. This records supplemental
Linux/compiler/shim evidence, not a native Delphi build.

## Latest run: Ultralight C, DES/3DES and demo events (2026-10-09)

The complete `tools/run_core_tests.py` run passed after adding native DES providers,
Ultralight C user memory and DESFire EV1 2K3DES/3K3DES plus D40 DES/2K3DES.
The new fixed-transcript suite passed **20,646 assertions** through OpenSSL and
again through the production CNG adapter with the Linux native ABI shim. It covers
all communication modes, complete retained transactions, both AF directions,
every transaction I/O boundary, response corruption, RNG and release failures.
The CNG native suite passed **72 assertions**, including its new 3DES paths.

Reader/card/HID and nonvisual demo-bridge tests passed **96 assertions**. A later
focused family-executor run passed **2,086 assertions**, including the new valid
and invalid credential/acknowledgement preflights before hardware acquisition.
The existing AES, document, SIM, memory, UID, NDEF, EMV and transport regressions
passed. All **36 Python regressions** passed. The source readers selected **191
Pascal sources**; all **21 checkers**, including XML documentation, passed.
Distribution checks passed for **35 projects, two groups and 22 independent DFM
forms**. The palette now registers **26 components**, with the standalone design
package retaining its explicit source closure and no ERD runtime BPL dependencies.

Every PC/SC demo uses native reader/card notifications. Each has its own form and
DFM; the shared event bridge is nonvisual. The new UltralightCDemo is independent.
Delphi-native BOM/CRLF formats remain checked by the distribution reader.
These Linux/compiler/shim checks are supplemental validation, not a Delphi build
or a claim of physical reader/card compatibility. Earlier run records follow.

The complete suite was rebuilt on Linux on 2026-10-09 after finishing SIM/USIM
management, twenty VCL applications, native USB-HID report transport and
NTAG210/212 profiles. The full run passed **2,159,328 assertions across 40 program
configurations**. It includes 74,402 SIM/USIM, 1,857 family-executor, 88 worker,
341 portable HID and 392 native HID ABI-shim assertions. All 34 Python regressions,
21 Pascal readers on 166 selected sources and distribution checks for 33 projects,
two groups and three DFM forms passed. The XML Help Insight reader inspected
1,796 production declarations and 267 VCL declarations with zero findings.

The maintainer confirmed warning-free compilation and installation of the prior
packages in RAD Studio 12 (Studio 23.0), Debug/Win32. Both VCL demos subsequently
reported EThread during startup; the shared post-construction StartWork fix was
merged. The maintainer also intentionally removed the design package's runtime
BPL dependencies after an installation failure. This follow-up keeps that choice
and explicitly bundles all 47 registration/runtime source units. Fresh Delphi
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
| SIM / USIM | 74402 assertions: independent identity/alpha/ADN/SMS/service/PBR vectors, literal classic/UICC APDU chains, PIN budgets and proof, continuation/length bounds, caller ownership, full-file/record writes, every I/O failure and read-back bit, no replay and cleanup uncertainty |
| RFID input/report profiles | 65619 assertions passed: exhaustive two-byte decimal conversion plus independent wide/overflow vectors, literal boot/report-ID/ASCII fields, framing/deadlines/discard recovery, held keys/errors, event ownership and reentrancy; no physical USB opening |
| Native HID report component | 341 assertions passed: endpoint/length/ID checks, read/output ownership, wiping, reentrancy, acquisition/release failures and uncertain submission |
| Native HID API branch | 392 assertions through the isolated Linux C shim: Unicode SetupDi enumeration, descriptor buffers/sizes, input/output/features, pending I/O, timeout/cancel/drain, incomplete completion, inaccessible metadata and handle cleanup; no Windows driver execution |
| SLE4404 | 60114 assertions passed: literal code/program/scratchpad/application erase transcripts, budgets/success proof, all I/O boundaries and read-back bits, chunking, stale state, owned caller buffers and release uncertainty; no physical card |
| Contact memory profiles | 2955 assertions in nine groups passed: nineteen geometries, literal ACR38/ACR39/SLE/PIN/protection/page/bank transcripts, wrong/blocked retry counters, every write/PIN-chain I/O failure, every acknowledgement status/read-back data bit, no-op/locked ranges, release evidence, credential copies and acquisition recovery; no physical chip access |
| SLE counter chips / capabilities | Full run: 34,280 assertions passed; four explicit models, all write modes/address boundaries, literal select/program/carry/backup/challenge/retrieval commands, every write-chain I/O failure, wrong statuses/lengths, all window data bits, stale preflight, zero-to-one refusal, release evidence, owned input arrays, failed acquisition recovery and mandatory carry dispatch; ACR39 counter support is not claimed |
| Contactless Classic/Type 2 storage and programmable UID | 6619 assertions in twelve groups passed, including protected pages, complete snapshots, four/seven-byte Gen2 programming, separate factory FUID one-time writes and uncertain outcomes |
| Raw RF UID programming and ACR122U adapter | 8179 assertions in twenty-three groups passed, including Gen1a/Gen1b/unsealed UFUID, partial UFUID/ZUID/PFUID, Type 2 DirectWrite, Gen3, all six Gen4 layouts, partial writes, USCUID/GDM hidden/public sources, password-command wiping, bit framing and complete adapter-chain transcripts |
| Password-authenticated Type 2 user memory | 2388 assertions in seven groups passed for both EV1 sizes and NTAG210/212/213/215/216, including retained-session PWD_AUTH/PACK, bounded snapshots, verified writes and concrete adapter integration |
| NDEF codecs, RTDs and public Type 2 access | 38481 assertions in five groups passed: bounded framing/chunks, strict Unicode, factory CC/TLV mapping and guarded write failures |
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
| Family demo executors | 1857 assertions passed: offline APDU command/response, ATR, TLV, EMV metadata, NDEF and RFID conversion/report profiles; all valid device-action preflights; invalid choices, PIN lengths, expected ranges, acknowledgement and credentials in public fields refused before hardware; literal memory/counter/SLE4404 and TWN4 command chains; no replay; uncertain writes and completed proof across transaction/connection/CDC cleanup failures |
| Palette registration / RTL streaming | 22 assertions passed: actual Register routine captures twenty-one classes; inactive construction and FPC component stream round-trip for each; DesignIntf capture is not an IDE/ABI test |
| Distribution / VCL source readers | Thirty-three MSBuild projects (all four Debug/Release × Win32/Win64 property combinations), two groups and three DFM forms passed: references, package ownership/order, explicit IDE package identity, native Base/configuration/platform activation, GenDll/GenPackage, named DCP dependencies, native integer-overflow/debug settings, BOM/CRLF/resources, runtime/design dependency separation, palette completeness, field/event bindings, form creation and Platform/Config output isolation; no Delphi/VCL execution |
| FPC range/overflow/heap checks | Passed; no unfreed allocations in passing test programs |
| Python checker regression tests | All 34 passed, including nineteen distribution-reader cases; coverage includes IDE package identity, native configuration inheritance, omitted empty IDE platform groups, owning-package dependencies, explicit standalone design copies without dependency-owned duplicates, group target order, named DCPs, resources, BOM/CRLF, compiler property types and bounded condition parsing |
| Pascalcheck core profile | All 21 readers passed on 166 explicitly selected source files |
| XML documentation | 1796 visible production API declarations and 267 VCL example declarations inspected; zero findings; exported test-vector declarations also pass the full profile |
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

The current suite reports 2,159,328 passing assertions across 40 configurations.
Native HID adds portable contract tests and an x64 Linux ABI shim for actual Windows
imports, descriptor layouts, exact paths/report buffers and cancel/drain lifetime.
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

An earlier revision shared `ERD.Card.Demo.FamilyForm` across six projects. That
form has since been removed in favor of the twenty individual designer forms
documented below. At that revision the family input catalog,
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
After that extension, the focused SIM suite passed 71,363 (18 additional PBR
assertions); the final family-executor run passed 1,596 after the extra demos.
That batch ended at 2,153,192 aggregate assertions. InspectSim was separately built and checked against
literal ICCID/IMSI/alpha output and help; malformed input exits with failure.
Source validation, distribution readers and XML documentation were rerun after
these additions. Physical SIM/USIM and Delphi/Windows tests remain outstanding.

## Additional contactless family demos

The focused family-executor suite passed 1,596 assertions after adding separate
Classic, public Type 2 and Type 4 projects (132 more). Tests cover every new live
action's acquisition boundary, required acknowledgements and invalid choices,
literal key loading/authentication/block/page/CC APDUs and connection/transaction
lifetime. Status-only block/page writes never set WriteVerified. NDEF operations
route to the already tested components. The distribution readers passed 25
projects and the 21-reader source profile passed 147 sources. Native VCL remains
unexecuted here. This follow-up changes demos, not the underlying card protocols.

## Linked USIM contacts and SMS text (2026-10-09)

The full 38-program run passed 2,154,129 assertions. Final focused reruns add
two ADN backlink checks and six demo-route checks: SIM 72,302 and family 1,602,
for 2,154,137 distinct final assertions. Both focused programs report zero leaks.
The full run also passed all 34 Python regressions, distribution readers and
21 source checkers; the latter were rerun after the final tests. XML readers
inspect 1,743 production and 235 VCL declarations with zero findings.

Independent literals cover received GSM text, outgoing UCS-2, UDH-fill alignment,
concatenation metadata and binary application ports. SMS malformed direction,
bounds, timestamp/DCS and payload lengths are refused. Linked-contact tests
cover a complete PBR/ADN/IAP/EMAIL/EXT read under one transaction and every one
of its 21 I/O failure positions with secondary cleanup errors. Original contact,
linked field and extension bytes remain owned; loops, out-of-range pointers and
wrong ADN backlinks are refused. No linked writes, SMS sending or hardware
validation is claimed. InspectSim's literal --sms-text output was separately
checked; its check is now in the automated runner.

## EMAIL/ANR and explicit SMS assembly

Focused SIM tests pass 72,312 and the family-executor tests pass 1,604 after this
follow-up. Literal out-of-order UCS-2 and binary messages assemble correctly;
binary UDH is removed only from joined payloads, while exact segment bytes remain.
Missing/duplicate segments, mixed recipients and DCS are refused; caller buffers
remain independent. EMAIL and ANR have explicit footer layouts and ANR preserves
unresolved CCP/EXT. Family actions expose the codecs; source and distribution
checks pass. This batch changes no PIN/write protocol.

## PIN/PUK and linked write plans; three document/EMV demos

The complete 38-program suite passed 2,156,246 assertions after SIM management
(SIM 74,402, family 1,611). Credential tests cover classic/UICC CHANGE and UNBLOCK
literal commands, no retries, every transmit failure, cleanup uncertainty and
owned command wiping. Linked plans check all pre-states before mutation, each
write pre-state and all final records; one- and two-EF transcripts cover every
I/O position, partial writes, stale second records and complete proof across
cleanup failure. Credential success is a command receipt, not fresh-PIN proof.

After adding Belgian/ICAO/EMV projects and acquired-file export, focused family
tests pass 1,664 and worker tests 88 (56 more final assertions). EMV literal
directory/GPO/GET DATA/log routes, raw export, offline codecs and Belgian
preflight pass. Worker failures never publish exportable artifacts. Source and
distribution readers cover 28 projects. This follows the existing native project
settings; no Delphi compiler execution is implied.

## Completed PR #28 expansion

SIM/USIM now includes explicit PIN/PUK status, once-only PIN change/unblock receipts,
linked contact reads and caller-ordered expected-state record plans for linked
phonebook writes. Every target is compared before the first update; final independent
read-back covers all records. Partial updates are uncertain and never replayed. No
automatic record allocation or fabricated reset/new-PIN proof is reported.

The twenty VCL applications include separate eID/ICAO/EMV, DESFire, UID, ISO 15693,
protected Type 2, SIM/USIM, memory, TWN4, RFID/native HID and magstripe profile paths.
Tests cover action preflight before acquisition, literal acquired responses and
exports, native HID selection/submission uncertainty and background result ownership.
The source-aware reader also caught and corrected a Delphi field-after-method
ordering issue in the shared artifact form.

NTAG210/212 tests extend model bounds, every excluded page, complete snapshots,
PWD_AUTH/PACK, NDEF read/write/no-op/clear and explicit MIRROR_PAGE write refusal.
The layouts/config pages come from NXP's published data sheet, retaining previous
enum ordinals. All generated native projects use the established BOM/CRLF and
Delphi Base/configuration/platform settings. See [VCL_COVERAGE.md](VCL_COVERAGE.md),
[USB_HID.md](USB_HID.md) and [NTAG210_212.md](NTAG210_212.md) for exact boundaries.


## Independent designer forms and in-demo reader discovery

The previous shared family form has been removed. All twenty VCL applications
now own direct TForm descendants and individual Main.dfm resources. Their visual
controls, action tabs, masked inputs, dropdowns and timers are defined in those
resources rather than created in Pascal. Only nonvisual worker/protocol code is shared.

PC/SC, serial and native HID demos discover their devices within the application,
using background reader-name, QueryDosDeviceW COM-alias or HID-metadata enumeration.
Selection is explicit; refreshing preserves only still-present addresses and clears
stale choices on failure. Foreground keyboard capture remains OS input, without
pretending to filter a selected HID keyboard. Device discovery issues no card command.

Controller regression tests exercise all three discovery kinds, dispatch separation,
owned result delivery, sanitized failures, overlapping-job refusal, caller-thread
callbacks, deferred closing, failed starts and destruction joining outstanding work.
The worker tests also reject partial device lists on failure. Distribution regressions
check keypress signatures, direct TForm ownership, required individual resources and
visual controls placed in Pascal. These readers complement the headless compiled tests.

Validation after this change: the full FPC range/overflow/heap suite passes
2,159,475 assertions across 41 configurations (144 controller and 91 worker
assertions). All 35 Python regressions and 21 Pascal readers pass on 167 sources.
Distribution checks pass for 33 projects, two groups and twenty DFM resources;
Help Insight checks cover 1,796 production and 2,367 VCL public declarations with
zero findings. The Linux checks do not compile or render VCL forms in Delphi.

## EMV record scan, parsed MOBIB and secure-provider boundary

The EMV reader now supports inspecting an application's PDOL without GPO, and
an explicit bounded extra record sweep after the standard AFL reads. Demo output
prints each actual record and additional absence/access status, retaining the
individual exports. Tests cover gaps, skipped duplicate AFL records, exact APDUs,
required terminal inputs, bounds and unexpected-error cleanup.

`TCalypsoCardReader` adds legacy/revision-3 logical-file and absolute-record reads,
a standard MOBIB profile and caller-defined file plans. `TMobibCodec` provides
explicitly matched legacy country/network decoding for holder, events, known
contract dates and 24-bit counter slots, preserving independently owned raw files.
`MobibDemo` has its own designer DFM, reader dropdown, layout and FID-plan fields.

A required secure read can use `ICalypsoSecureSessionProvider` and
`ICalypsoSecureReadSession`: one provider-backed read-only session, authenticated
transport dispatch, verified completion before snapshot delivery and abort on
failure. Missing providers fail before I/O; failed verification cannot downgrade
to a public read. The tests use provider fixtures and do not implement or validate
Calypso cryptography, real issuer keys or physical SAM hardware. A real SDK/SAM
adapter and legitimate credentials remain required for protected data.

Final full FPC suite: **2,160,336 assertions across 43 configurations**, including
1,650 EMV, 192 Calypso, 545 MOBIB codec and 1,935 family-executor assertions.
All **36 Python regressions** and **21 source-aware Pascal checkers** pass on
**173 sources**. Distribution readers validate **34 projects, two groups and
21 independent DFMs**. Aggregate Build/Make/Clean now covers every shipped demo,
with regressions preventing omissions and duplicate targets. XML Help Insight
coverage: **1,892 production and 2,434 VCL declarations**, zero findings.
These headless tests/readers do not replace Delphi compilation or real-card testing.


## Native Calypso SAM authentication and MOBIB subscriptions

The built-in `TCalypsoSamSessionProvider` now orchestrates revision-1, revision-2,
revision-3 compatibility and revision-3.2 extended plaintext sessions through a
separate provisioned SAM. It requires exclusive SAM ownership, an explicit
serial/key index/KIF/KVC/class, fresh SAM challenges, exact opening response
framing and final SAM verification of the card MAC. It includes successful
read/selection APDUs and full responses in the transcript, excluding Le from
case-4 commands. The strict profile aborts on failed/chained responses, denies
all writes, never downgrades, and returns no acquired result on verification
failure. It does not implement encrypted sessions, PKI or software-only issuer keys.

**609 native SAM assertions** cover four explicit generations, literal independent
card/SAM command expectations, transcript framing, invalid/mismatched keys,
malformed challenges, digest/authentication errors, transport failure, abort,
abandoned sessions, post-close rejection, read-only allowlisting and preservation
of the primary exception across failed cleanup. Synthetic MACs validate the
native protocol engine; the SAM performs the actual secret-key cryptography.

**370 MOBIB subscription assertions** cover fixed contract versions 0–3 and
optional-field version 4, all 32 presence bitmaps, tariff/known product labels,
price and sale date, duration fields, time-versus-trip counters, zero values,
unknown versions, strict truncation, deep ownership and absolute-record counter
association. The legacy codec no longer applies its fixed purchase-date offset
to newer contracts. Unknown validity/zone/operator rules remain explicit.

The independent MobibDemo DFM adds an authenticated read page with its own SAM
reader dropdown populated by the existing in-demo discovery. Executor tests
exercise both real protocol engines through separate injected transports,
verified file exports, withheld exports on bad MAC and release of both readers.
**2,041 family-executor assertions** pass.

Final full FPC suite: **2,161,421 assertions across 45 configurations**.
All **36 Python regressions** and **21 source-aware Pascal checkers** pass on
**177 sources**. Distribution validation covers **34 projects, two groups and
21 independent DFM forms**, including the new SAM selector and package source
closure. English public XML documentation coverage: **1,929 production and
2,461 VCL declarations**, zero findings. Native project BOM/CRLF conventions remain intact.


## Native MOBIB operator-rule assessment

`TMobibRuleEngine` now evaluates explicitly supplied product policies against
versioned subscriptions and acquired evidence. Exact operator/network/tariff/
version matching precedes all policy checks. Inclusive start and exclusive end
can come from explicit validity dates, known activation, contract-specific first
use or an explicitly sale-based policy. UTC elapsed minutes/hours, operator-local
calendar days/months/years, midnight-aligned ends and explicit contract-duration
unit maps are implemented. Gregorian target-month clamping handles leap years.

Fixed or decoded-contract zone sets require every requested journey zone to
match. An optional remaining-trip condition assesses starting a new journey.
Independent checks retain unknown evidence separately from proved failures;
known matched failures dominate unknown conditions, including a future start
without an end or a past end without a start. Unmatched profiles never evaluate
as eligible. The engine never acquires a reader, reads a system clock, infers
card-field meanings or installs an implicit issuer profile.

**1,282 rule-engine assertions** cover temporal boundaries, activation states,
missing versus invalid evidence, all four duration codes, a Gregorian 400-year
month-clamping sweep, leap-year and midnight cases, clock-domain mismatch,
profile identity/version matching, zone subsets, missing/zero trips, invalid
configuration, nonfinite dates and independent failure precedence.

MobibDemo adds a fourth, independent designer page for offline policy assessment,
with explicit rule source, acquired timestamps, duration semantics, journey zones
and counters. Blank zone policy remains unknown; unrestricted zones require an
explicit `*`. **2,051 family-executor assertions** include actual rule evaluation,
readable source/check/reason/date output, no card/SAM acquisition, malformed
civil-date rejection and rejection of nondecimal timestamp fields.

Final full FPC suite: **2,162,713 assertions across 46 configurations**.
All **36 Python regressions** and **21 source-aware Pascal checkers** pass on
**179 sources**. Distribution checks pass for **34 projects, two groups and
21 independent DFM forms**, with runtime/design package source closure and native
BOM/CRLF conventions preserved. Public English XML documentation covers
**2,036 production and 2,499 VCL declarations**, with zero findings.

These are native policy mechanics with application-supplied, sourced rules.
Complete automatic De Lijn/STIB/TEC/NMBS card-field mappings and issuer product
profiles are not claimed. Public product terms alone do not define the missing
card bytes; operator-specific activation/zone decoders must supply that evidence.


## Reader/card and USB-HID events

Automatic PC/SC observation uses a separate multi-reader/PnP wait context, not
application reader-list polling. Reader inventory changes, card insertion/removal,
same-ATR replacement counters and raw state changes reach the main thread.
`TSmartCardReader.StartEventMonitoring` forwards selected-reader card events and
all reader arrivals/removals; legacy manual observation remains compatible.

Native Windows HID arrival/removal uses device-interface notification registration.
Continuous HID input uses one explicit read-only device acquisition and complete
interrupt reports. Only completed input timeout cancellation is nonterminal;
uncertain writes remain unreplayed. No generic HID card-memory protocol or inferred
physical card-removal event has been added.

**82 asynchronous event/lifecycle assertions** cover empty inventory startup,
reader hotplug, card offers/removal, replacement with an identical ATR, selected
reader filtering, initial-state suppression, main-thread callbacks, callback
stop/free, cancellation/release ownership, whole-inventory validation before publishing, malformed backend states, terminal
failures, HID notification acquisition rollback, continuous report reception,
timeouts, queue ordering/overflow/replacement and invalidation. The full existing
FPC regression suite passes; focused event tests were rerun after final inventory
validation changes. The native PC/SC ABI shim now passes **51 assertions**,
including multi-record layouts, exact Unicode/PnP inputs, high counter bits,
invalid batch outputs and no native calls on duplicate/empty inputs. The native
HID ABI shim passes **448 assertions**, including explicit timeout classification
versus uncertain writes and other failures. These shims do not use Windows drivers.
The Windows hidden-window hotplug implementation is not executed by FPC on Linux;
its injectable registration/event lifecycle is covered by the event tests.

All **36 Python regressions** and **21 source-aware Pascal checkers** pass on
**183 sources**. Distribution checks pass for **34 projects, two groups and
21 independent DFM forms**. Runtime/design package source closure, native
BOM/CRLF conventions and the standalone design package are preserved.
Inactive registration/RTL streaming passes for **25 palette components**.
Public English XML documentation covers **2,098 production and 2,511 VCL
API declarations**, with zero findings. ReaderToolsDemo and UsbHidDemo retain
separate own DFM forms and now include explicit event controls/logs.

## DES/3DES key and Ultralight C configuration management

`LegacyMifare.Tests.dpr` now checks 42,422 assertions against independent fixed
native-3DES transcripts. Coverage includes all four DESFire profiles, policy and
protected/free file-access updates, current/other/PICC key rotation, CRC/version
bit composition, fresh authentication and exact version checks. Every I/O boundary
and protected replacement-response bit is exercised; invalid replacement inputs
send no mutation and preserve an otherwise active session.

Ultralight C coverage includes configuration snapshots, exact preimages, preserved
reserved bytes, locked configuration/key rejection, storage key byte order,
no-op fresh proof, every exchange failure and response bit, replacement-card UID
rejection and failed release after verification. One exclusive session covers both
RF activations; partial programming is explicitly uncertain and never replayed.

Family demo validation covers six Ultralight C actions and the separate DES/3DES
rotation page. Each retains its own DFM, reader combobox, native presence events
and masked credential fields. Distribution validation checks their bindings and
project source closure. Existing AES rotation and ordinary DES application/file
management remain regression coverage.

Validation completed for this change: the full `run_core_tests.py` suite passed,
including both native crypto backends and existing AES regressions. The final key
management tests passed again with 42,422 assertions through OpenSSL and the CNG
ABI shim after secret-buffer cleanup changes. Family demos passed 2,167 assertions,
Python tool regressions passed all 36 tests, all 21 Pascal checkers were clean, and
distribution validation reported zero findings across 35 projects and 22 DFM forms.
Fixture regeneration produced identical committed transcripts. These checks do
not substitute for Delphi compilation or physical-card evidence.

## Combined Type 2 management and FeliCa/Type 3 expansion

The full `run_core_tests.py` suite passed after this change, including existing
AES/DES, SIM, eID and reader regressions. `Type2Felica.Tests.dpr` passed 43,881
assertions using fixed independently generated transcripts: seven password models,
configuration preimage/CFGLCK checks, preserved unrelated bits, credential replacement
and same-UID fresh proof, supported 24-bit counters, protected NDEF length-last writes,
FeliCa long block-list addresses, status/identity framing, Type 3 attribute checksums,
full-message verification, no-op and every exchange/release failure boundary.
The concrete PN532 adapter was exercised at both 212 and 424 kbit/s with exact native
packets, finite timings, zero retries and cleanup after every failed operation.

Family demo tests passed 2,224 assertions, including every new FeliCa/Type 3 action,
choice validation and mutation acknowledgement before hardware acquisition. Inactive
palette/RTL streaming passed 29 assertions for 28 components. Distribution validation
reported zero findings across 36 projects, two groups and 23 DFM forms. All 36 Python
tool regressions and 21 Pascal source/documentation checkers passed; runtime test
executables reported zero leaked heap blocks. New projects retain BOM/CRLF and the
standalone design package retains its complete source closure without runtime BPL
dependencies. The fixture generator uses standard Python only and is reproducible.

These are compiler/protocol/backend/script checks; they do not constitute a Delphi
IDE build or physical-card qualification. Unencrypted FeliCa data and PWD_AUTH/PACK
are not cryptographic card-authenticity claims.

## ISO 15693 bulk access and SLIX2/ST25DV password sessions

The complete `run_core_tests.py` regression workflow passed, including native
crypto backends and the existing card families. The final focused
`Iso15693Profiles.Tests.dpr` run passed 1,295 assertions with range/overflow checking
and heap tracing. Independent literal FF-FB transcripts verify 23/33 block/count
encoding, 240-byte chunk boundaries, SLIX2 random/XOR/B3 wire frames and ST25DV
B3 wire frames. Coverage includes all three original ST25DV geometries, wrong
manufacturer/geometry/missing IC reference before password dispatch, copied
credentials, duplicate/invalid identifier and size preflight, every acquisition
and authentication exchange failure, poisoned-session refusal, reserved SLIX2
counter block, verified user-memory writes, uncertain dispatch/read-back/release
and password-session integration with Type 5 NDEF read/write.

Family execution/preflight tests passed 2,278 assertions, including every new
SLIX2/ST25DV action and malformed passwords/acknowledgement before hardware
acquisition. Distribution validation reported zero findings across 38 projects,
two groups and 25 independent DFM forms; the component palette remains 28.
All 36 Python tool regressions and all 21 Pascal checkers passed. Existing
ISO 15693/Type 5 tests retain their 280,409 assertions. New project files use
BOM/CRLF; the existing runtime/design package source closures require no new unit
or runtime BPL dependency. Test executables reported no leaked heap blocks.

These results are compiler/protocol/backend/script checks, not a Delphi IDE
build or physical-card qualification. RF password acceptance is not cryptographic
card authenticity, and ending a PC/SC transaction is not a fresh RF power-on reset.

## NFC-V password/protection management and explicit RF reset

The full `run_core_tests.py` workflow passed after the management expansion.
`Iso15693Management.Tests.dpr` passed 6,149 assertions with runtime range/overflow
checking and heap tracing. Literal ACS FF-C2 start/reset/end packets validate the
10,000-us RF timer and strict manage-TLV acknowledgement. Literal SLIX2 B4/B6 and
ST25DV B1/A1 packets validate password replacement, protection settings and
preserved unrelated RF access bits. Tests exercise all exposed password IDs,
extended feature snapshots, ST area geometry/policy decoding, stable external VCC,
same-password no-op, native/stripped ISO replies, no-reset backends, stale/locked
settings, changed UID, busy setters, every I/O failure, failed fresh password proof,
wrong read-back and release failure without replay. Both real adapter interfaces
and component boundaries are exercised; reset failures poison the adapter.

Existing profile tests retain 1,295 assertions; family demos passed 2,304
assertions including all six new management actions and preflight/acknowledgement.
Inactive palette and RTL streaming passed 30 assertions for 29 components.
Distribution validation reported zero findings across 38 projects, two groups
and 25 independent DFM forms. All 36 Python tool regressions and all 21 Pascal
checkers passed. Runtime test executables reported no leaked heap blocks.
The standalone design package still needs no ERD runtime BPL dependency, and no
new source unit/package dependency was introduced.

These are compiler/protocol/backend/script results, not Delphi IDE or physical
card/firmware qualification. A tag's final accepted password may remain active
until a later RF reset; verified replacement is not cryptographic card authenticity.
ST RF exclusivity does not lock an external I²C host or guarantee its power supply.

## eID / EMV / MOBIB inspection workflows

The common report engine and three native family adapters add independently owned
section evidence, authentication/partial-read events, and explicit personal/raw
text and JSON export policies. Three independent inspection DFM applications,
package references and 54 registered palette classes are included.

The full FPC/native runner passed, including 38 Python checks and 55 inactive
palette/RTL streaming assertions. Final focused inspection tests passed 1,097
assertions with zero heap leaks, covering cancellation, primary/cleanup failure,
observer isolation, consumed requests, privacy combinations, Unicode, synthetic
native EMV/eID/MOBIB transcripts and hardware-free demo validation. All 21 common
Pascal source readers passed on the new sources; distribution checks reported
60 projects, two groups and 46 DFM forms with zero findings. FPC reports the
pre-existing TLV constructor visibility warning. No Delphi/VCL build was executed
in the Linux environment.

## Protected memory and reviewed security workflow extension

The focused `ProtectedWorkflow.Tests` program passes 8,462 assertions with zero
heap leaks. It exercises every password-capable Type 2 model, both ISO password
profiles, backup/archive restore, copy/compare, static/dynamic locks, mirror
refusal, cancellation, wrong passwords, pre-authentication UID/geometry changes,
known pre-dispatch refusals, post-dispatch loss/read-back mismatch and credential
cleanup. Security changes exercise Type 2 password/PACK and AUTH0/PROT/AUTHLIM,
SLIX2 password/protection and ST25DV password/area policy with fresh RF proof.
Injected demo transports throw on every hardware operation: validation and
credential previews pass without I/O or secret exports. Native ACR122/ACR1552
transport fixtures also exercise in-demo configuration capture, same-card UID
guards, exact configuration artifacts and password-free ISO public reads.

The complete FPC/native runner passed before this final capture action; the final
focused suite covers the added path with zero leaks. The regression run includes
38 Python tests and 57 inactive component registration/streaming checks.

All 21 selected-source checkers pass. Distribution readers report 62 projects,
two groups and 48 DFM forms without findings; registration includes 56 palette
components. These are Linux FPC/RTL/static checks; they do not establish Delphi
IDE rendering, Windows ABI or physical-reader/card behavior.

## Ultralight C, protected NDEF and TWN4 workflow adapters

The complete FPC/native regression runner passed after integration, including
38 Python tests, all 21 source checkers and 58 inactive registration/RTL streaming
assertions. The final focused `CardAdapterWorkflow.Tests` suite passes 5,092
assertions with range/overflow checking and zero heap leaks.

It uses real OpenSSL 3DES and random nonces for Ultralight C authentication,
user-memory restore, key rotation and AUTH0/AUTH1 changes. Type 2 and Type 5 NDEF
fixtures cover native password access, length-last writes, logical transfer,
comparison/no-op/clear/cancellation, identity and lock refusals, lost writes,
read-back mismatch and credential cleanup. Proprietary Type 5 access requires an
explicit profile, reserved access codes and read-only writes are refused, and
SLIX2 counter overlap stops before length invalidation. Unknown post-dispatch
backend errors remain uncertain. TWN4 transcripts cover Type 2 and Classic 1K/4K
restores/comparisons, literal high-block/sector encoding, frozen reader lifetime,
wrong-family/UID checks before login, lost write responses and balanced close.

The final boundary tests were rerun separately after the full regression pass.
Distribution checks cover 62 projects, two groups and 48 DFM forms with zero
findings. Registration includes 57 palette components. No demo files changed in
this increment. These Linux/static tests do not substitute for the Delphi compiler
or physical reader/card validation; the pre-existing TLV constructor visibility
warning remains outside this change.

## DESFire key sets, configuration/SDM and native MIFARE Plus (2026-10-11)

The full `tools/run_core_tests.py` regression run passed. The new suite passed **48,029 assertions** with range/overflow checks and no heap leaks. Seventeen independently generated literal transcripts cover native Plus MACed/Full authentication, reads, writes, 4K high sectors, the ACR122 ISO14443-4 chain and DESFire key-set/configuration/SDM management. Failure injection covers every transcript I/O boundary and protected response bits, UID/preimage refusal, frozen input buffers and cleanup uncertainty. Published NXP AN12196 SDM PICC, session-key, MAC and encrypted-file vectors also pass. Plus backup/compare/restore exercises the existing protected-memory engine.

The reproducible generator is `tools/generate_desfire_plus_fixtures.py --check`. All 21 source checkers passed. Palette registration covers **58 components** and inactive registration/streaming covers **59 cases**. Distribution validation reports **62 projects, 2 groups and 48 DFM files**, with no findings. No demo files were changed in this increment. These results establish synthetic protocol/ABI behavior, not physical device certification. Existing unrelated compiler notes/warnings have not been suppressed.

## Plus SL0 personalization and SL3 sector key replacement (2026-10-11)

The extended DESFire/Plus suite passes **117,396 assertions** (69,367 added in
this increment), with range/overflow checking and zero heap leaks. Four additional
independently generated literal transcripts bring the fixture set to **21**:
self-key and same-sector A/B replacement, 4K high-sector key replacement, and SL0
WritePerso/CommitPerso followed by fresh sector/master/configuration authentication
and encrypted ordinary-data read-back. Replacement uses encrypted messaging even
when the caller selects MACed ordinary communication.

Failure injection covers every exchange, every acquisition/release stage,
identity changes between fresh sessions, acknowledgement/MAC bits and encrypted
nonce proof corruption. Tests verify frozen caller key/plan buffers, restored
component configuration, invalid/duplicate/manufacturer/trailer/model-mismatched
plans before acquisition, and persistent uncertainty after any mutation dispatch.
Switch-key personalization has acknowledgement only, as documented; there is no
invented secret-memory read-back or SL1/SL2 fallback.

The complete FPC/native regression runner and all **21 source checkers** passed.
Fixture reproducibility and distribution checks passed: **62 projects, 2 groups,
48 DFM forms**, no findings. No demo/package format changes were required. Existing
unrelated FPC notes/warnings remain unsuppressed. These are synthetic protocol
results; the exact direct-SL3 commit profile is an explicit caller prerequisite.

## Plus SL1 level management and signed value blocks (2026-10-11)

The focused DESFire/Plus suite passed **149,648 assertions** (32,252 added here)
with range/overflow checks and zero heap leaks. The independent fixture generator
now produces **28 literal transcripts**. Added vectors cover raw CRC-A 76/72 SL1
card authentication, the SL2 switch key, the SL3 switch plus fresh protected data
proof, a complete no-RATS ACR122 raw chain with register/parameter restoration,
and signed value-block reads and ordinary secure writes.

Level tests inject every native I/O boundary, CRC/status/nonce bits, partial-bit
responses, explicit timeouts, acquisition/release failures and UID changes between
raw and ISO14443-4 sessions. Borrowed switch/proof-key and expected-data mutation
during raw I/O cannot change frozen inputs. Invalid profiles fail before activation.
SL2 results are authenticated acknowledgement only; SL3 also proves acquired data.

Value tests cover both signed endpoints, all 256 logical addresses, every bit of
value/address redundancy, checked arithmetic overflow, preimage refusal, no-op
writes and every protected write/read-back response bit. These are ordinary secure
memory writes, not native increment/decrement/restore/transfer commands.

The full FPC/native regression runner and all **21 source checkers** passed.
Inactive palette/RTL streaming now covers **60 cases** for **59 registered
components**. Distribution checks report **62 projects, 2 groups, 48 DFM forms**
and no findings; fixture reproducibility and BOM/CRLF checks pass. No demo files
changed. Existing unrelated compiler notes/warnings remain unsuppressed.

## Plus native value workflows and SL2→SL3 (2026-10-12)

The complete FPC/native regression runner passed. Final focused verification passed
**331,970 assertions** (182,322 added in this increment) with range/overflow checks
and zero heap leaks. The independent fixture generator now produces **43 literal
transcripts**, adding explicit raw first-authentication SL2→SL3 with fresh SL3 data
proof, all five staged/combined native value workflows, same/separate-block paths,
4K high addresses and full unsigned amounts spanning both signed endpoints.

Tests inject every native I/O boundary and protected response bit, preimage errors,
signed overflow, malformed value/address redundancy, and caller buffer mutation.
They distinguish volatile-buffer failure from persistent-transfer dispatch and
verify unchanged distinct sources. Two additional transcripts carry valid response
MACs with wrong destination or changed source data; both fail at the precise proof
boundary. Authentication tests also corrupt nonces/status with recomputed valid
CRC-A, exercising nonce/capability checks independently of RF CRC rejection.

All **21 source checkers**, fixture reproducibility and distribution checks pass.
Distribution remains **62 projects, 2 groups and 48 DFM forms**, with no findings;
registration/streaming remains **60 cases** for **59 palette components**. Pascal
BOM/CRLF is preserved and no demos changed. Native value support is explicitly the
Plus X-compatible command profile, within one authenticated sector. SL2 sector
data sessions/key modifiers remain separate. Existing unrelated compiler notes
and warnings have not been suppressed.

## DESFire ISO, multiple rights and AES TMAC (2026-10-12)

The focused DESFire/Plus suite passes **695,388 assertions** with range/overflow
checks and zero heap leaks. The independent generator now produces **71 literal
transcripts**, including variable-length ISO directory frames, ISO application and
four file types, additional access-right authority, TMAC lifecycle/settings and
counter limits, plain/MAC/full record reads, owned transactions and CommitReaderID.

Transaction tests cover read-only calculations, backup changes, abort, every I/O
boundary, protected response corruption, wrong static keys/UIDs/counters and
release failures. Two receipts have valid session MACs but an invalid transaction
MAC or counter; neither is accepted as independent proof. Offline AES key
vectors and canonical transaction inputs are checked against separate generated
cryptographic results and the official NXP specification. CommitReaderID uses
MAC communication with transaction-key-encrypted previous ReaderID, without an
additional session-CBC layer.

All **21 source checkers**, fixture reproducibility and distribution checks pass.
Distribution remains **62 projects, 2 groups and 48 DFM forms**, with no findings;
registration/streaming remains **60 cases** for **59 palette components**. Existing
Pascal source encoding and CRLF are retained; no demos changed. The complete
FPC/native regression runner passed. Existing unrelated compiler notes/warnings
remain unsuppressed. LRP, combined extended transaction layouts and ISO creation
combined with new key sets are separate remaining profiles.

## Combined DESFire ISO key sets and TMAC standard ranges (2026-10-12)

The focused DESFire/Plus suite passes **1,451,063 assertions** with range/overflow
checks and zero heap leaks. The independently generated fixture set now contains
**88 transcripts**. New vectors cover combined native ISO/key-set creation,
public seven-byte key-settings proof, PICC reauthentication and subsequent
protected directory use, plus standard-data immediate/range/commit verification.

Tests cover repeated, overlapping and disjoint writes, no-op data, explicit abort,
wrong preimages, acquired read/write denial, wrong file type and out-of-file bounds.
All exchange boundaries and every protected response data/MAC bit are injected.
Additional vectors carry valid MACs with wrong ISO FID/name, key-set geometry or
immediate/post-commit range contents. Caller buffers are mutated during I/O to
prove that frozen inputs control dispatch. Invalid local parameters and policies
that cannot expose new key-set settings are rejected without additional I/O.

The complete FPC/native regression runner, all **21 source checkers**, independent
fixture reproducibility and distribution checks pass. Distribution remains
**62 projects, 2 groups, 48 DFM forms** with no findings; **59 registered components**
and **60 inactive registration/RTL streaming cases**. Existing source encoding,
CRLF and formatting are retained; no demos changed. Existing unrelated compiler
notes/warnings remain unsuppressed. Abort semantics are explicit: cancellation of
a TMAC calculation does not undo immediate standard writes.

## Native LRP, combined SDM rights and cyclic-record updates (2026-10-12)

The focused DESFire/Plus suite passes **2,123,006 assertions** with range/overflow
checks and zero heap leaks. The independent generator now emits **131 literal
fixture sets**, including **150 published NXP AN12304 known answers** for
LRP evaluation, LRICB and CMAC. The published wrapping-counter case is explicitly
refused by the library's nonwrapping counter contract; other LRICB cases execute
both encryption and decryption.

Independent native LRP fixtures cover master-key derivation, first/NonFirst MACs,
TI/capability verification and Plain/MAC/Full command/response framing. Tests
corrupt every protected response bit, accept no correct-MAC wrong capability or
padding/length, inject every provider encryption/decryption call boundary and
prove that MAC rejection occurs before any AES decryption. Failed codec operations
preserve caller-owned encryption counters.

Combined SDM tests cover enable/disable, additional-right removal, no-op changes,
strict conditional framing, wrong preimage and valid-MAC wrong postimage, every
I/O/response boundary, and mutation of caller rights/preimages during I/O. Record
tests cover ordinary and TMAC owners, native BA outbound AF chaining, repeated
updates, abort, no-op, wrong preimages, append/clear conflicts in both orders,
different-record conflicts, every native boundary/response bit and valid-MAC wrong
post-commit record content. Owned dispatch uncertainty and release are checked.

The complete FPC/native regression runner, **21 source checkers**, fixture
reproducibility and distribution checks pass. Distribution remains **62 projects,
2 groups, 48 DFM forms**, no findings; **59 components** and **60 inactive streaming
cases**. Runtime/design packages include the new LRP unit with native BOM/CRLF;
existing source formatting is preserved and no demos changed. Existing unrelated
compiler notes/warnings remain unsuppressed. Automatic LRP card-reader sessions,
LRP TMAC and partial/unaligned-record TMAC profiles are not claimed by these tests.

## Automatic LRP sessions, owned TMAC and inspection (2026-10-12)

The focused DESFire/Plus suite passes **3,332,287 assertions** with range/overflow
checks and zero heap leaks. The independent generator now emits **174 literal
fixture sets**, retaining all **150 published AN12304 vectors**. New fixtures
exercise automatic native LRP Plain/MAC/Full reads and verified standard writes,
NonFirst nonce proof with retained TI/command count and reset encryption count,
owned backup/value/cyclic-record commit/abort, and BA outbound additional frames.

Owned TMAC tests cover fixed expected and acquired hidden-session counters,
unsigned sixteen-bit limits, actual-count wrap refusal, counters 1/7/FFFF, real UID
proof, frozen keys/UIDs, reader commitment and deferred previous-ID release.
Correct session MACs with wrong receipt MAC, actual/session counts or final data
are refused. Deferred IDs remain unavailable before commit and after any failed
receipt, read-back or ownership release. Returned ID copies do not share storage.
Tests inject every native exchange boundary and protected response bit, plus
CSPRNG/provider failure before authentication part two. The AES TMAC entry refuses
LRP before acquisition; both allowed profiles remain separately exercised.

Reader inspection adds protected real UID under EV2 AES/LRP and stored LRP TMAC
under Plain/MAC/Full modes, with exact metadata and release checks. It does not
mutate or invent static transaction-key proof; Plain requires explicit minimum.
The stored session count is not used to guess the next hidden counter.

The complete FPC/native regression runner, **21 source checkers**, fixture
reproducibility and distribution checks pass. Distribution remains **62 projects,
2 groups, 48 DFM forms**, no findings; **59 registered components**, **60 inactive
streaming cases**. Existing security enum ordinals and interface layouts/IIDs are
preserved; source encoding/CRLF is retained and no demos changed. Existing unrelated
compiler notes/warnings remain unsuppressed. LRP provisioning, originality and
combined/partial/unaligned transaction layouts remain separate profiles.

After the final AES/LRP entry guard, an additional focused build of the latest
sources passed **333 assertions**, covering the guard, allowed AES TMAC, known and
acquired-counter LRP TMAC, and both UID/stored-record inspection paths. No new
compiler hints/warnings were introduced in the changed units/tests.


## 2026-10-12 — native DESFire Light LRP management

Added an explicit optional Light application management interface without changing
any of the **11 existing interface layouts/IIDs**. Light uses a fixed five-key
application profile and does not issue unsupported GetKeySettings. Independent
literal transcripts cover key 0, 1 and 4 rotation, XOR/CRC data, bare master-key
acknowledgement, fresh LRP authentication, protected version proof and a
valid-response-MAC wrong-version failure. Ten persistent configuration options use
Light-specific lengths, RFU checks, LRP ATS timing, explicit ISO identifiers,
signed value geometry and failed-authentication counter validation. Persistent
acknowledgement is required; no generic configuration readback is claimed.

Focused native management tests pass **126,905 assertions**, including every
exchange boundary and response-data bit, caller-buffer mutation and exclusive
release failures. Focused local-input tests pass **106 assertions**, including
all truncated configuration inputs and no-dispatch profile/context/authority/
acknowledgement guards; valid commands remain usable after local input errors.
The separate generator reproduces **188 literal fixture sets**. Both **21 source
checkers** over the library and the contactless tests pass. Distribution remains
**62 projects, 2 groups, 48 DFM forms**, with zero findings. Source BOM/CRLF is
retained; no demo, form, package or registered component has changed.

The full native DESFire/Plus regression suite passes **3,459,299 assertions** with
zero unfreed heap blocks. This includes the earlier AES/DES/3DES, ISO, multiple
rights, SDM, TMAC and LRP profiles alongside the new Light administration paths.
