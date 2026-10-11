# Native workflow adapters

These nonvisual adapters extend the existing workflow engines. Preparation does
not open hardware. This increment adds no demos and does not modify existing forms.

## Ultralight C

`CreateUltralightCWorkflowMemory` in
`ERD.Card.Contactless.Workflow.UltralightC` owns a native
`TUltralightCCardReaderWriter`, a retained raw RF reader and an explicit
`ICardDesProvider`. Supply the current 16-byte 2K3DES key and optionally the exact
seven-byte UID. Identity is checked before authentication; otherwise the first
acquisition pins the identity for subsequent operations.

```pascal
Memory := CreateUltralightCWorkflowMemory(RawReader, DesProvider, CurrentKey, Uid);
Workflow.PrepareProtectedBackup(Memory, SelectedPages);
Outcome := Workflow.Execute;
Snapshot := Workflow.Snapshot;
```

Use `TProtectedMemoryWorkflow` for backup, copy, comparison and restore. Its archive
layout is `ULTRALIGHT-C`, with four-byte units for user pages 4 through 39. It cannot
restore a Type 2 snapshot under another layout. Static and dynamic user locks are
checked before writing; manufacturer, OTP, counter, key and configuration pages
are excluded. Writes authenticate and verify native read-back.

`CreateUltralightCKeyOperation` and `CreateUltralightCProtectionOperation` in
`ERD.Card.Contactless.Workflow.Security` create operations for
`TCardSecurityWorkflow`. Supply an exact UID and current/new keys for replacement,
or the exact eight-byte pages 42/43 preimage, current key, AUTH0 and ProtectReads
for protection changes. Review `Plan` before executing. Key material is omitted
from public plans. Reserved configuration bytes are preserved; fresh same-card
authentication verifies the resulting state. A dispatched change without complete
proof is uncertain.

## Protected NDEF

`TProtectedNdefWorkflow` in `ERD.Card.Contactless.Workflow.Ndef.Protected` supports:

- `PrepareCopy(Source, nil)`: capture logical NDEF bytes without a target.
- `PrepareCopy(Source, Target, CompareOnly, AllowClear)`: copy or compare.
- `PrepareWrite(Target, Message, CompareOnly, AllowClear)`: frozen template/restore.

An empty message requires explicit `AllowClear` when writing. Comparison permits
empty messages. Matching target content skips writing and retains read-back proof.
Use `MessageBytes`, `Different`, `ReadBackVerified` and the inherited workflow
state/error/events. Requests are single-use.

```pascal
Source := CreateType2PasswordWorkflowNdef(
  RawReader, ttmNtag213, Password, ExpectedPack, SourceUid);
Target := CreateIso15693PasswordWorkflowNdef(
  IsoSession, ippSlix2, Passwords, 80, TargetUid);
Workflow.PrepareCopy(Source, Target);
Outcome := Workflow.Execute;
```

The Type 2 backend uses native PWD_AUTH/PACK. The Type 5 backend owns an addressed,
exact-geometry password session for SLIX2 (80 four-byte blocks) or original
ST25DV04K/16K/64K (128/512/2048 four-byte blocks). Required password identifiers
and values must be supplied; no defaults or credential discovery are attempted.
Logical transfer can cross mapping families without copying physical layout,
UID, passwords or access policy. Existing public `ICardWorkflowNdef` adapters can
also participate; their own reader lifetime contracts still apply.

Both mappings must already be initialized. Native updates preflight writable
blocks/pages, invalidate the length, stage/verify content and publish length last.
Type 5 CC access code two is accepted only through an explicit authenticated
session profile. `TType5NdefCardReader.AllowProprietaryAccess` defaults to false;
setting it does not authenticate a session. Reserved access code one is rejected,
and write access code three remains read-only. SLIX2 mappings whose acquired
physical range includes counter block 79 are refused before any NDEF write.

Unknown backend errors after write dispatch preserve an uncertain result. A
backend may raise `ECardWorkflowWriteRefused` only when it can establish that no
write was dispatched. No formatting, locks or credential changes are implicit.

## TWN4 memory

`ERD.Card.Reader.TWN4.Workflow` provides:

- `CreateTwn4ClassicWorkflowMemory`: Classic Mini/1K/4K with application-supplied
  `IClassicWorkflowKeys` and optional expected identifier.
- `CreateTwn4Type2WorkflowMemory`: ordinary user memory for an explicit Type 2 model,
  optionally pinned to a seven-byte UID.

The adapter owns a separate native reader with frozen Channel, UseCrc and TimeoutMs.
The configuration component can be freed after construction; the channel interface
is retained. A suitable TWN4 PRS firmware/USB-CDC channel is required.

These backends implement `ICardWorkflowMemory`, so they can participate in existing
backup/copy/compare/restore engines, including `TProtectedMemoryWorkflow`. Classic
and Type 2 layout identifiers match their existing family adapters. Block zero,
sector trailers and Type 2 configuration/lock pages are excluded.

Classic 4K requires `ITwn4WorkflowSectors.ReaderSector` for each high block
128 through 255. This metadata mapping is frozen at construction without card I/O;
it supplies the firmware's login sector identifier rather than guessing it.

The adapter checks tag family and pins the complete identifier before login,
retains the target preimage, rechecks it before dispatch and uses native verified
writes. Permission preflight uses reads with the intended write credentials;
it cannot establish all lock/write conditions that firmware does not expose.
No TWN4 PWD_AUTH, Ultralight C, UID programming or protected Type 2 protocol is
added by these adapters.

## Ownership and results

Protected backends own copies of supplied credentials. Execution, cancelled
execution, replacement preparation, failed preparation and destruction clear
their owned credential buffers. A cleaned backend is consumed; create a fresh
backend for the next request. Give a workflow exclusive ownership of these
consumable backends. Caller-owned credential arrays remain caller-owned.

TWN4 adapters release their key-provider reference on cleanup and wipe temporary
key buffers. They cannot clear keys stored by an application-owned provider.
Raw/session/channel/crypto interfaces are retained by their owned native adapters.

Events run on the executing thread. Run blocking work on the application worker
and marshal UI updates. Cancellation prevents later writes but lets in-flight
verification finish. Multi-unit operations are not atomic; inspect per-unit
results and overall state after any failure. Uncertain writes are never retried
implicitly.
