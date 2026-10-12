# Application workflows

The workflow components coordinate existing card APIs without a VCL dependency.
They appear on the **ERD Workflows** palette. Constructors and preparation perform
no card I/O; the caller supplies configured readers, profiles and credentials.

| Component | Implemented workflows |
| --- | --- |
| `TProtectedNdefWorkflow` | Logical NDEF backup/copy/compare/template/explicit clear through supplied-password Type 2/SLIX2/original ST25DV backends |
| `TProtectedMemoryWorkflow` | Supplied-key Ultralight C and supplied-password Type 2/SLIX2/original ST25DV selected-memory backup/copy/compare/restore with pre-authentication identity guards and credential cleanup |
| `TCardSecurityWorkflow` | Offline secret-free credential/policy review; exact same-card verified Ultralight C/Type 2/SLIX2/ST25DV native change with fresh RF proof |
| `TEidInspectionWorkflow` | Belgian identity/address/photo/signatures/certificates or one explicit BAC/PACE ICAO LDS acquisition, structured section evidence and exports |
| `TEmvInspectionWorkflow` | Explicit AIDs and PDOL values, directory/AFL acquisition, optional extra record rectangle, counters and transaction logs |
| `TMobibInspectionWorkflow` | Explicit native Calypso read plan, parsed MOBIB report with operator context/confidence, exact gaps and privacy policy |
| `TMifareClassicCopyWorkflow` | Selected/all ordinary data-block copy, backup, comparison and restore for Mini/1K/4K |
| `TType2MemoryWorkflow` | Selected/all user-page copy, backup, comparison and restore for supported Ultralight/NTAG models |
| `TUidProgrammingWorkflow` | Explicit UID programming or copying a source UID using Gen2/CUID, factory FUID, raw Gen1a/Gen1b/unsealed UFUID, Type 2 DirectWrite, Gen3, Gen4, USCUID/GDM or documented partial UID profiles |
| `TClassicCredentialWorkflow` | Explicit multi-sector key/access-bit migration with supplied current/new credentials and fresh authentication verification |
| `TNdefTransferWorkflow` | Read-only acquisition, logical NDEF copy across mapping families, template writing and explicit clearing; native Type 1/2/3/4/5 adapters |
| `TMagStripeCopyWorkflow` | Read-only stripe acquisition, selected-track copy and template programming; same-card verified writing or explicit device-status-only programming |
| `TCardBatchWorkflow` | Application-defined per-card personalization templates across existing workflow families, prepared before I/O, with per-card outcomes and retained child evidence |
| `TIso15693MemoryWorkflow` | Selected-block backup, comparison, copy and restore with exact geometry, addressed UID checks and full target lock preflight |
| `TSle4404Workflow` | Public selected-window snapshot, offline comparison/one-way program planner, explicit scratchpad/application erase plans, checked prefix resume |
| `TSleCounterWorkflow` | Full declared counter window snapshot, one-way program planner, explicit carry/backup before/after plans, checked prefix resume |
| `TDesfirePersonalizationWorkflow` | Ordered application/file creation, complete ordinary content population, AES/DES/3DES key rotation and rights/policy steps, with checked prefix resume |
| `TContactMemoryWorkflow` | Complete SLE/I2C backup; selected-range copy, comparison and restore with protection/retry preflight and per-range verification |
| `TDesfireApplicationWorkflow` | Complete ordinary or multiple-right application backup/copy/compare/restore; optional explicitly owned TMAC with verified receipt |
| `TDesfireProvisionWorkflow` | Explicit application key policy/type/count and ordinary-file creation; optional prevalidated multiple-right policy with verified settings |
| `TDesfireSdmTemplateWorkflow` | Complete stored SDM template backup, comparison and restore under the same combined target policy; no dynamic mirror copying |
| `TSimPhonebookWorkflow` | Standalone ADN/standard classic EXT1 or explicit PBR-linked contact backup, compatible-layout restore preview and reviewed apply |
| `TSimSmsWorkflow` | Complete EF.SMS backup, status-preserving restore preview and reviewed apply; offline free-slot/multipart import planners |
| `TSimInspectionWorkflow` | Explicit ICCID/PIN state/IMSI/provider/services/EF.DIR inspection with per-section refusal evidence |
| `TCardMemoryCopyWorkflow` | The reusable memory engine, also usable with application-supplied `ICardWorkflowMemory` backends |

## Lifecycle and evidence

1. Create inactive readers and configure the correct transport/profile.
2. Supply separate source and destination backends. Classic uses
   `IClassicWorkflowKeys.GetKey` for each block, direction and verification read.
   This supports different keys per sector and different source/destination keys.
3. Call `PrepareCopy`, `PrepareBackup`, `PrepareRestore`, `PrepareWrite` or `Prepare`.
   Preparation copies request buffers, checks geometry and rejects duplicate addresses.
4. Execute once on the caller's worker thread. A consumed request cannot execute
   again; prepare another request explicitly.
5. Inspect `State`, `ErrorClass` and per-unit `Results`. Restore/copy checks every
   source unit and every target original before the first write, skips equal units,
   and independently verifies each modified unit.

`OnCardRequired` identifies source or target. For one connected reader, the
application can arrange the swap in this callback before returning ready. It can
also perform a backup first, then prepare a restore after the user swaps cards.
For two readers, configure each backend for its respective connection.

`OnStageChanged`, `OnProgress`, `OnCompleted` and `OnError` run on the executing
thread. Marshal UI updates yourself; never free a workflow from its callbacks.
Observer failures are isolated and exposed as `ObserverErrorClass`. A failed
card-presentation callback cancels before acquisition. `Cancel` is same-thread:
call it from an event, or have the worker consume your application cancellation
flag there. Verification of an in-flight write finishes before cancellation takes
effect. Device deadlines still bound individual blocking calls.

Completed means all requested operations finished with the stated evidence.
`Cancelled` can still contain earlier verified writes. `Failed` can also retain
previous verified steps. `Uncertain` means a dispatch or its verification could
have changed the card; inspect it before preparing a new write. There is no
rollback, resume-by-replay or automatic retry. Each unit records Pending,
Unchanged, Verified or Uncertain. Compare-only differences remain Pending.

Keep exclusive control of each backend/connection for the whole phase. The memory
engine checks UID before each unit and after a write; this catches accidental
card changes but does not authenticate the card or make multiple commands atomic.
Do not change connections from progress callbacks. Adapters hold caller-owned
reader references, so readers must outlive their adapters and prepared workflows.

## Classic data, credentials and UID

A data copy excludes block zero and every trailer. Trailer reads can mask keys;
those bytes are not complete credentials and are never put into a data backup.
For a broader migration, copy data first, optionally use a UID workflow for an
explicit programmable variant, then run explicit sector changes with supplied
keys/access conditions. Sector changes can permanently restrict future access.

`TClassicAccessCodec` encodes/decodes four C1/C2/C3 conditions and validates every
inverted bit. `WriteClassicSectorTrailer` writes once, authenticates with new
Key A, verifies access bytes/GPB, and verifies new Key B through authentication
or readable bytes according to the trailer condition. The credential workflow
returns only addresses and states, and wipes its independently retained key/trailer
buffers after execution or destruction. It cannot recover unreadable source keys.

Ordinary production UIDs are immutable. UID protocols require an explicitly
identified programmable chip and matching reader capability. The raw adapters
retain their existing configuration/metadata-preservation checks. Gen2/FUID can
return `cwsNeedsVerification` if the reader still reports a cached UID; after RF
reactivation the application must independently verify the active UID. This state
never triggers another write automatically.

## Snapshots and NDEF

`TCardWorkflowArchive.Encode/Decode` uses the bounded `ERD-MEMORY 1` ASCII format.
It stores layout, observed source UID and exact selected units. It rejects malformed
headers, duplicate addresses, inconsistent widths and control characters. Runtime
write-evidence states and supplied credentials are excluded. Backups contain raw
application data and are not encrypted or signed. Restores require the exact
layout identifier; arbitrary cross-geometry raw restoration is refused.

NDEF transfer copies logical records, normalizing physical chunk framing through
`TNdefCodec`. Destination mapping writers check capacity and preserve their own
hardware metadata. `AAllowClear` must be explicitly true to clear a destination
from an empty source/message. Mapping versions, public/protected access and reader
requirements remain those of each existing NDEF component.

## Magnetic stripes

Source and destination devices can differ. Explicit track selection and coercivity
are checked against their capabilities. Verified mode requires the backend to
provide same-card verified read-back. Status-only mode must be selected explicitly,
returns a device receipt, and leaves `ReadBackVerified` false. A later arbitrary
swipe is never substituted for evidence from the programmed card. Empty selected
source tracks cannot silently erase destination tracks.

## Independent VCL examples

Five separate projects have their own editable form/DFM, source/target comboboxes,
input fields, file dialogs and worker controller:

- `ClassicWorkflowDemo`: complete ordinary-data backup/copy/compare/restore. The
  demo accepts one Key A per side; production uses the per-block key provider.
  An explicit sector action takes trailer addresses, current/new keys and access
  bytes/GPB; it verifies each trailer without exporting credentials.
- `Type2WorkflowDemo`: complete user-memory backup/copy/compare/restore.
- `UidWorkflowDemo`: source UID acquisition, two-reader UID copy and explicit UID
  templates; Gen2/FUID and ACR122 raw Gen1a/Gen1b/UFUID/Type 2/Gen3/Gen4 Classic.
  USCUID/GDM, partial UID and Gen4 Type 2 variants remain available through the
  workflow API and existing `UidProgrammingDemo`.
- `NdefWorkflowDemo`: source capture, copy or template programming for the selected
  Type 2 model or Type 4 mapping 2.0. The workflow API additionally adapts Type 1/3/5
  and can use different source/destination mapping families.
- `MagStripeWorkflowDemo`: MSR206-7HL selected-track acquisition/copy/template writing
  with explicit low/high coercivity and same-card verified writing. Status-only
  backend support is available through the workflow API and existing stripe demos.

For one reader use Capture, swap cards, then Restore/template. Direct copy/compare
requires different source/target device names in these demos. PC/SC device lists
and presence use native events. Serial devices are discovered inside the stripe
demo. Workers do not touch VCL controls; phase logs are displayed on completion.
Templates are raw, potentially personal data; save/export is explicit.

## Batch personalization

`TCardBatchWorkflow.Prepare(Identifiers, Factory)` builds all requests before card
I/O. `ICardBatchFactory.CreateWorkflow(Identifier)` must return a fresh, prepared
workflow with `Owner=nil`, without touching hardware. Preparation also calls each
child's `CheckPrepared`. It accepts one through 256 unique application identifiers,
at most 128 characters each. The application generates those identifiers and the
family-specific contents; the batch does not invent identities or credentials.

Return an existing memory, NDEF, UID, credential, stripe, contact-memory, DESFire or SIM workflow. The batch owns
and retains the returned component. Factories must retain any caller-owned readers
until the batch and its children are destroyed. The batch replaces child progress
and card-presentation callbacks. Its own `OnCardRequired` uses `CurrentIdentifier`
and `CurrentIndex`, so an application can ask for the correct card or perform a
single-reader swap on the worker thread. Preventing presentation of the same
physical card is an application responsibility. A UID alone does not prove that
cards are distinct.

Each child executes once. Any failure, cancellation, uncertain write or pending
active-UID verification stops the batch; later items remain unattempted. `Results`
contains identifier, attempted flag, outcome and sanitized error class. `Child(I)`
is a borrowed component exposing detailed family-specific evidence, including
per-block partial results. Do not execute, reconfigure or destroy it yourself.
Prepare a new explicit batch after inspecting interrupted results; there is no
implicit retry or continuation. Cancellation from a progress callback reaches the
active child, which finishes verification of an already dispatched write first.

`BatchWorkflowDemo` has its own DFM and reader selector. Add a card identifier and
NDEF text for each selected reader. The staged rows hold identifier, reader name
and NDEF hex, making the templates editable. This concrete demo keeps one card
presented in a distinct reader for each row, avoiding worker-thread modal prompts.
The API's card-request callback supports single-reader applications. All templates
are validated before acquisition. Existing Type2 NDEF public-write, lock, mirror
and capacity restrictions apply; the batch does not format blank tags.

## ISO15693 selected-memory workflows

Create `TIso15693WorkflowMemory(Session, BlockCount, BlockSize)` for each source or
target and pass it to `TIso15693MemoryWorkflow`. Geometry is explicit, constructor
and `Addresses` perform no I/O, and layout names include both physical block count
and byte width. Source and destination must have exactly matching geometry; this
does not imply matching vendor application semantics.

The first `ReadUid` pins the observed identity. Every acquired addressed session
checks that UID and geometry, including the session that dispatches the write.
The optional `ICardWorkflowWritePreflight` contract lets the memory engine check
live security status for **all differing target blocks before the first write**.
Locked or unsupported protection fails the request without earlier block writes.
Comparison can still inspect readable locked blocks. Writes recheck protection,
send once, read back within the retained session and verify again in the workflow.
A release failure after dispatch remains uncertain.

`Addresses(FirstBlock, Count, Writing)` selects at most 4096 contiguous blocks.
Process larger chips in explicit windows. Reads can include blocks zero and one;
writes exclude them because they can hold Type5 capability metadata. UID, AFI,
DSFID, passwords, protection bits and vendor configuration are separate operations.
Supplied `TIso15693PasswordSession` wrappers can provide authenticated access;
their chip-specific restrictions remain in force. Backups never fill unreadable
blocks with zeros.

`Iso15693WorkflowDemo` has its own DFM, source/target reader selectors, physical
geometry fields, selected block range, address dialect and response format. It
uses the existing ACR1552 FF-FB session. Other applications can supply their own
`IIso15693Session`. Capture and restore support a card swap on one reader; direct
copy/compare in the demo uses separate readers.

## Contact-memory workflows

`TContactMemoryWorkflow` supports the eight ordinary SLE models and eleven I2C
geometries supported by `TMemoryCardReaderWriter`. `PrepareBackup` captures the
complete chip (up to 128 KiB), public protection map and available retry counter
without PIN authentication. `PrepareCopy` and `PrepareRestore` select an explicit
byte range; `ACompare=True` reads and compares without writing.

Preparation performs no hardware I/O. Before the first write, both complete
snapshots are read, every differing protected byte is rejected, and the target
PIN retry budget is checked. Unchanged protected bytes remain untouched. Only
differing runs are written, bounded by native chunks and physical I2C page size.
Each run is verified by the native writer and independently read back by the
workflow. A later failure retains earlier verified byte ranges. Authentication
rejection before data dispatch is a failed action; an uncertain dispatched write
is retained as uncertain and is never retried automatically.

`TContactMemoryWorkflowArchive` encodes complete data, model and diagnostic
protection/retry information in `ERD-CONTACT-MEMORY 1`. It contains no PIN and does
not apply archived protection bits or retry counters. `TContactMemoryWorkflowCard`
retains a caller-owned reader, which must outlive the workflow; configuration
changes are refused. These memory chips have no reliable UID. The application
must keep exclusive ownership of the presented physical card throughout an
operation. Counter chips and SLE4404 use separate APIs and are not accepted here.

## DESFire application workflows

`TDesfireApplicationWorkflow.PrepareBackup` reads every ordinary file in an
explicit application: standard/backup bytes, signed values, and complete linear
or cyclic records. Records are stored newest first. `TDesfireWorkflowArchive`
encodes the AID, manufacturing UID, native file settings and complete data as
`ERD-DESFIRE 1`; authentication keys are never serialized. Aggregate transfer and
journal budgets remain bounded. Unknown/special file types are rejected.

Copy/restore requires a pre-existing target application with compatible file
types, communication modes, key rights, sizes, record capacity and value policy.
All target file data and write rights are checked before the first mutation.
Standard files are immediate verified writes. Backup/value/record changes share
one retained transaction, with originals checked again inside that transaction.
Values use explicit credit/debit deltas; records are appended oldest first to
preserve snapshot order. Completion requires a successful commit, native
read-back evidence and matching card identity. This is not atomic across
immediate standard files and transactional files; earlier standard-file evidence
is preserved after a later failure.

The caller must explicitly choose `dsaFreshTransaction` (attest no pending
transaction) or `dsaDiscardPending` (allow a deliberate initial abort).
Cancellation before commit explicitly aborts staged changes; errors never trigger
automatic retries, destructive rollback or implicit recovery. A lost commit
response remains uncertain. Use the native session API for explicit recovery.
`TDesfireWorkflowCard` owns a frozen copy of reader configuration/keys and retains
its transport/provider interfaces; the source configuration object may be freed.
Public and native authenticated profiles use the same configured backend contract.

`TDesfireProvisionWorkflow.Prepare` takes separate explicit PICC/application
security contexts, new AID, key policy/count/type and ordinary file definitions.
Every definition is validated before I/O. Application creation is followed by
key-policy verification, then each file is created once with native metadata
verification. `ApplicationCreated` and per-file results retain partial progress;
a later failure never deletes the new application or repeats creation. The card
initializes its native default keys; supplied application credentials must match
those keys. Key rotation remains an explicit native administration operation.
For personalization, provision the layout and then restore a separately prepared
snapshot using the appropriate credentials. Provisioning evidence covers metadata;
restoration supplies and verifies file payloads.

Both family workflows can be returned by an `ICardBatchFactory` as freshly
prepared, ownerless children. Batch preparation remains free of hardware I/O and
stops on a failed, cancelled or uncertain child. See the mixed-family batch case
in `tests/workflows/CardFamilyWorkflow.Tests.dpr`.

## SIM/USIM contact and SMS workflows

`TSimPhonebookWorkflow` and `TSimSmsWorkflow` use an explicitly configured
`ISimWorkflowCard`. `TSimWorkflowCard` owns frozen copies of a native reader's
profile, AID and PIN retry policy and retains its transport. The original reader
may be freed. Preparation never connects or authenticates. Use exclusive caller
ownership of the physical connection between workflow steps; no competing
operation, reset or card swap during one execution.

The application supplies the real ADN/SMS root/path. A nonzero PBR record captures
all linear-fixed EFs referenced by that selected USIM PBR record, including IAP,
EXT, EMAIL and ANR. No USIM ADN FID or application is guessed. Standard classic
ADN captures EXT1 if existing numbers require it; `PrepareClassicBackup` explicitly
captures both standard ADN and EXT1 even on an empty phonebook. Both EFs must be
present. Cyclic/unknown geometries and incomplete/unresolvable contact links fail
rather than creating partial snapshots.

The workflow has three distinct requests:

1. `PrepareBackup` captures all physical records and ICCID; the codec report shows
   decoded names/numbers, supported linked fields, SMS status/text and capacity.
2. `PreparePreview` reads a fresh target and builds an exact-layout restore plan.
   PBR records must match and remain read-only. EXT/EMAIL/ANR data precedes IAP
   and ADN links. Every original/replacement byte is visible in the plan.
3. `PrepareApply` uses a previously reviewed target-bound plan. It checks profile,
   full AID and ICCID, authenticates at most once when a supplied PIN is needed,
   then checks ICCID and **every original record again inside one retained native
   transaction before any UPDATE**. Each original is rechecked immediately before
   its update, each record is independently read back, and a final complete
   verification precedes release.

`TSimWorkflowCodec.ImportContacts` allocates standalone inline ADN contacts in
fully erased free slots. `ImportLinkedContacts` allocates logical names/numbers,
long-number EXT chains and optional EMAIL/ANR using a complete supported PBR
layout (or standard classic ADN/EXT1). It supports one ADN/IAP/EXT/EMAIL/ANR
reference each, type-1 same-index and type-2 IAP bindings, explicit ADN SFI
back-references, and erased/unreferenced helper records. Ambiguous/unknown
bindings, insufficient capacity and names/numbers that do not fit reject the
entire offline request. No existing contact is overwritten or silently shortened.
ANR is inline up to twenty dial symbols; extended ANR and broader PBR schemas
remain outside this logical importer. Exact compatible-layout backup/restore
retains the full raw linked records supported by the snapshot resolver.

`ImportSms` allocates explicit complete 176-byte stored records in free target
slots without changing status/SMSC/TPDU/padding. `ImportSmsGroup` first validates
one explicitly supplied complete multipart group through `AssembleSms`, rejecting
missing, duplicate or mixed segments. There is no inferred grouping of unrelated
records. Unsupported text remains complete raw bytes in a snapshot/report; text
decode failure does not discard an otherwise readable SMS record. This stores
messages on the card and does not transmit SMS through a mobile network.

`ERD-SIM-SNAPSHOT 1` and `ERD-SIM-PLAN 1` archives are canonical bounded ASCII
containing personal data, actual paths and physical records. Plans include target
ICCID/profile/AID plus all original and replacement bytes; neither format contains
a PIN. Snapshot limits are 32 EFs, 255 records per EF and 255 bytes per record.
Native plans accept at most 8192 unique linear-fixed records. An empty plan causes
no PIN attempt or write. Unknown budgets are never treated as permission to try.

All writes are non-atomic across records. Cancellation is accepted before the
retained native plan starts; once started, the bounded plan and its read-back run
to completion or failure. Earlier verified records survive a later failure, while
outstanding dispatch remains uncertain. Cleanup failure can retain per-record
verification while the overall result remains uncertain. No retry, reset or
rollback is automatic. Contact/SMS workflows and the inspection component can be
returned as fresh ownerless children by the existing batch factory.

`TSimInspectionWorkflow` acquires ICCID, PIN state, IMSI, SPN, service bits and
UICC EF.DIR using the supplied profile/AID. Card status refusals are recorded per
section with the exact SW; transport/malformed-response errors fail the workflow.
A completed inspection does not claim every section was available. Service bits
are declarations, not proof that an operation is permitted by card access rules.
The component never chooses an AID, attempts ADM credentials, registers a phone,
sends SMS or performs network authentication.

## Further workflow extensions

These are future workflows, not shipped workflow components yet:

- Broader SIM PBR schemas and additional operator-specific allocation rules.
- Additional authenticated chip families and reader adapters with documented native protocols.

Existing low-level components already support much of this work. These extensions
need family-specific workflow contracts; they are not implied by the generic
memory interface. Payment processing and APDU recording/replay remain outside this
work.


## SLE4404 and counterchip plan workflows

`TSle4404Workflow` and `TSleCounterWorkflow` use frozen owning native adapters:
`TSle4404WorkflowCard` and `TSleCounterWorkflowCard`. The original reader can be
freed after adapter construction. ACR38x CCID is the supported reader dialect;
actual chip model, readable window, code-counter locations and erase-area geometry
are supplied explicitly. The application exclusively owns the physical connection
and keeps the same card present; these chips do not expose a general trustworthy UID.

`PrepareBackup` acquires the complete selected public window without presenting a
code. SLE4404 windows exclude code storage and configured error counters; counter
snapshots cover the complete declared readable window. `TSleWorkflowArchive`
exports strict `ERD-SLE-SNAPSHOT 1` and `ERD-SLE-PLAN 1` text, excluding secrets.
`TSleWorkflowPlanner.Compare` returns differing physical addresses. `ProgramPlan`
constructs a chained plan for explicit SLE4404 programming or plain counter-byte
programming, rejecting every zero-to-one transition before card access. It returns
an empty selection when equal; no execution is needed then. Erase/carry/backup
plans are supplied explicitly with complete before/after images.

Each reviewed `TSleWorkflowStep` has an action, physical address, count, mode and
full selected-window before/after images. `Prepare(Card, Steps, True)` reads/checks
without code attempts or writes. Execution checks all structural constraints
before I/O, checks the original image, then rechecks current bytes before each
native mutation. Native retry budgets and expected-state checks remain active.
Each native mutation is sent once and independently read back by both layers.
`Results` retain pending, unchanged, verified and uncertain steps. Authentication
failure can consume code attempts even when no public data write occurs.

`ACompletedPrefix` explicitly skips a prefix only after a fresh read equals its
final planned image; this proves current public data, not prior authentication or
an issuer certificate. A mismatch stops before writes. Equal programming/erase
images skip unnecessary operations; explicit counter carry operations are never
silently skipped. A snapshot cannot restore irreversible counters/protection or
recover hidden credentials. Application erase presents both supplied codes once,
consumes a non-restorable memory-counter bit and requires a previously non-erased
application region. Neither erase nor carry is an automatic rollback strategy.

## Ordered DESFire personalization

`TDesfirePersonalizationWorkflow.Prepare(Steps, ExpectedNativeUid, CompletedPrefix)`
accepts 1–256 explicit ordered steps and a previously acquired seven-byte native
manufacturing UID. Each step retains its own immutable `IDesfireWorkflowCard`
credential context. Supply the correct credential for that point in the profile:
rotating a key does not silently update later reader configurations.

The actions are provisioning an absent application with ordinary file definitions,
populating compatible complete standard/backup/value/record files, rotating an
existing AES or same-type DES/2K3DES/3K3DES key, changing ordinary file access/mode,
and changing native key policy. Provision/content reuse the established native
workflows; `LastChild` exposes detailed partial application/file/content evidence.
Each request result records attempted/revalidated flags, its terminal state and
failure class. A failed or cancelled content child can retain earlier verified
writes; inspect `LastChild`, which remains available until the next child or
preparation/destruction. Creation leaves native initial keys until an explicit
subsequent rotation step.
All structural child validation precedes hardware access. Live permissions for a
future application are checked when it exists; this is not a global atomic operation.

Native key/access/policy mutations verify their exact result. Key rotation requires
fresh mutual authentication with the replacement, not just its public version.
`CreateDesfirePersonalizationKeyProof` freezes a supplied authenticated reader
configured with the replacement key; public profiles are refused. Keys are copied
and local workflow key buffers are wiped on completion/destruction. Retained
native contexts keep their own credentials until released; no key bytes appear in
reports, snapshots or plan templates. A native post-dispatch or final release
failure is uncertain; the profile stops without retries or automatic deletion.

Checked resume re-acquires and verifies **every** requested completed prefix step
before dispatching any remaining mutation. It checks application key type/count,
ordinary file geometry and the planned completed access/policy state, complete
content bytes, and replacement-key possession/version. Optional `VerificationCard`
provides a final authorized context after key/access changes. A prefix that cannot
be observed with supplied credentials is refused. Duplicate rotations of a key,
repeated policy/access overwrites and repeated content population for the same
application are refused because they destroy independently checkable prefix
semantics. UID comparison detects accidental swaps; it is not issuer authenticity.

The three independent workflow demos and their text grammar are documented in
[VCL_DEMOS.md](VCL_DEMOS.md#sle-and-desfire-personalization-demos).

## Inspection and report workflows

The three read-only family workflows and common report API are described in
[INSPECTION_REPORTS.md](INSPECTION_REPORTS.md). Workflow completion is separate
from report completeness: a finished inspection can include absent or restricted
sections. Partial data survives later errors; exports omit personal and raw values
unless explicitly selected.

## Protected memory and security plans

See [PROTECTED_WORKFLOWS.md](PROTECTED_WORKFLOWS.md) for native profiles, credential
ownership, exact preimage requirements, independent DFM demos and partial-write
evidence. These workflows extend compatible memory snapshots without implicitly
copying credentials or access policies.

## Additional native adapters

[Ultralight C, protected NDEF and TWN4 adapters](CARD_WORKFLOW_ADAPTERS.md)
extend the existing nonvisual workflow engines. This increment adds no demos;
the existing VCL projects remain unchanged.

## MIFARE Plus SL3 ordinary memory

`CreatePlusWorkflowMemory` provides an owned `ICardWorkflowMemory` backend for `TProtectedMemoryWorkflow` backup, copy, compare and restore. Supply an `IMifarePlusSession`, AES/CSPRNG provider, explicit 2K/4K model and `IPlusWorkflowKeys`. Keys are requested per sector/direction and never serialized into archives. Full secure messaging, expected-UID checks, preimage checks and read-back verification apply. Block zero and trailers are excluded; this copies ordinary content rather than card keys/security state. See [MIFARE_PLUS.md](MIFARE_PLUS.md).


## Plus personalization and credential replacement

Alongside the protected-memory adapter, `TMifarePlusCardReaderWriter` exposes
`RotateSectorKeyVerified` and `PersonalizeAndCommitSl3Verified` as complete native
pipelines for application workers. They freeze caller inputs before I/O, retain
identity across fresh sessions, require explicit mutation acknowledgement and
report post-dispatch uncertainty. Personalization returns credential-free counts
only after all selected key/data proofs. The supplied personalization entries contain caller-owned secrets; returned evidence
and ordinary memory archives contain no keys.
See [MIFARE_PLUS.md](MIFARE_PLUS.md) for the direct-SL3 commit profile and
acknowledgement-versus-verification contract. These calls do not add automatic
resume or batch serialization of secret plans.


## Plus SL1 transitions and value-block operations

`TMifarePlusLevelManager` supplies native SL1 mutual authentication, an acknowledged
SL1→SL2 pipeline and an SL1→SL3 pipeline with fresh same-card protected data proof.
Assign an explicit no-RATS raw backend and, for SL3 proof, a separate ISO14443-4
backend for the same reader. Transition dispatch uncertainty is retained across
both acquisitions. These worker-callable operations require supplied keys and
explicit one-way-change acknowledgement; they do not infer levels or replay.

`ReadValueBlock` and `WriteValueBlockVerified` add integrity-checked signed ordinary
value-block access to the Plus component. They retain logical addresses and check
exact prior content; native increment/decrement/transfer permissions are separate.
See [MIFARE_PLUS.md](MIFARE_PLUS.md) for exact API and evidence contracts.


## Native Plus value and SL2→SL3 pipelines

`ExecuteNativeValueVerified` performs native staged increment/decrement or restore
followed by transfer, or native combined increment/decrement-transfer. It pins
both exact ordinary-value preimages, checks signed arithmetic, keeps volatile
buffer state inside one exclusive session and verifies target/source content.
Persistent-transfer uncertainty is distinct from a failed volatile-buffer step;
there is no retry or exposed pending transfer buffer. Source/target must fit the
same authenticated sector and the selected Plus X-compatible command profile.

`SwitchSl2ToSl3Verified` adds explicit raw first authentication with the supplied
L3 switch key, then a separate fresh same-card protected SL3 data proof. SL2 sector
data/key-modifier access and verified trailer programming are documented in
[the protocol/workflow guide](PROTOCOL_COMPLETION.md). See [MIFARE_PLUS.md](MIFARE_PLUS.md).


## DESFire ISO/multi-access and AES TMAC native pipelines

Optional file-management sessions provide verified ISO application/file creation,
exact multi-access policy changes, additional-key standard-data read/write and
TMAC file/communication/access/counter-limit management. They retain frozen
preimages and stop on unresolved dispatch without replay.

The dedicated `IDesfireTransactionMacSession` reuses ordinary backup/value/record
journals while capturing exact canonical plaintext operations. It requires real
UID, supplied static TMAC key, trusted previous counter and an explicit fresh-state
assertion. ReaderID, read-only commit, abort and offline-verified counter/MAC
receipts are supported; commit also verifies journaled files and release. Default
ordinary sessions do not silently adopt the profile. See
[DESFIRE_FILES_TMAC.md](DESFIRE_FILES_TMAC.md). This extends native pipelines;
existing workflow archives do not yet serialize ISO mappings or combined extended
layouts, and no CardStudio/demo layer has been added.

## DESFire ISO key sets and immediate TMAC standard ranges

The native optional interfaces now combine ISO application creation with AES key
sets and support exact-preimage standard-data range writes in an owned TMAC
calculation. ISO creation verifies the tuple and public key settings and restores
PICC authentication. Standard writes verify immediately, update overlapping range
proofs and verify all final ranges after the authenticated/offline-verified receipt.

These APIs do not change ordinary application archives or add an automatic
application migration profile. Standard writes are immediate: aborting the
calculation does not restore them. See [native profile contracts](DESFIRE_FILES_TMAC.md).

## Combined SDM rights, record updates and native LRP codec

Native optional APIs now preserve combined SDM/additional-right settings through
exact-preimage change and full read-back, and stage full sixteen-byte cyclic
record updates with owned journal/commit/abort and optional TMAC receipt proof.
Record update cannot mix append/clear or a different record index in one file
transaction. These APIs do not silently extend the ordinary archive format.

The native [LRP codec](DESFIRE_LRP.md) includes published primitive, authentication
and Plain/MAC/Full framing. The codec itself performs no I/O. `TDesfireCardReader` now adds explicit LRP
First/NonFirst retained sessions with native chaining and fail-closed cleanup.
Owned LRP TMAC verifies split counters, offline receipt and journal content, with
deferred previous ReaderID available only after complete success. LRP provisioning
and combined-layout application archives remain separate profiles.

See [protocol/workflow profiles](PROTOCOL_COMPLETION.md) for SL2 memory backends,
DESFire archive v2, TMAC lifecycle, SDM stored-byte evidence and operation-queue binding.
