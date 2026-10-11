# Application workflows

The workflow components coordinate existing card APIs without a VCL dependency.
They appear on the **ERD Workflows** palette. Constructors and preparation perform
no card I/O; the caller supplies configured readers, profiles and credentials.

| Component | Implemented workflows |
| --- | --- |
| `TMifareClassicCopyWorkflow` | Selected/all ordinary data-block copy, backup, comparison and restore for Mini/1K/4K |
| `TType2MemoryWorkflow` | Selected/all user-page copy, backup, comparison and restore for supported Ultralight/NTAG models |
| `TUidProgrammingWorkflow` | Explicit UID programming or copying a source UID using Gen2/CUID, factory FUID, raw Gen1a/Gen1b/unsealed UFUID, Type 2 DirectWrite, Gen3, Gen4, USCUID/GDM or documented partial UID profiles |
| `TClassicCredentialWorkflow` | Explicit multi-sector key/access-bit migration with supplied current/new credentials and fresh authentication verification |
| `TNdefTransferWorkflow` | Read-only acquisition, logical NDEF copy across mapping families, template writing and explicit clearing; native Type 1/2/3/4/5 adapters |
| `TMagStripeCopyWorkflow` | Read-only stripe acquisition, selected-track copy and template programming; same-card verified writing or explicit device-status-only programming |
| `TCardBatchWorkflow` | Application-defined per-card personalization templates across existing workflow families, prepared before I/O, with per-card outcomes and retained child evidence |
| `TIso15693MemoryWorkflow` | Selected-block backup, comparison, copy and restore with exact geometry, addressed UID checks and full target lock preflight |
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

Return an existing memory, NDEF, UID, credential or stripe workflow. The batch owns
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

## Further workflow extensions

These are future workflows, not shipped workflow components yet:

- DESFire application/file provisioning and migration with explicit keys, file
  types, rights and transaction boundaries.
- SLE/I2C contact-memory backup/restore, incorporating PIN retry budgets, protection
  maps and chip-specific irreversible operations.
- SIM/USIM contact/SMS import/export and eID/EMV/MOBIB acquisition/report pipelines.

Existing low-level components already support much of this work. These extensions
need family-specific workflow contracts; they are not implied by the generic
memory interface. Payment processing and APDU recording/replay remain outside this
work.
