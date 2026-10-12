# Protected memory and reviewed security workflows

`TProtectedMemoryWorkflow` coordinates selected-memory backup, copy, comparison
and restore through the native supplied-password Type 2 and ISO15693 APIs.
`TCardSecurityWorkflow` coordinates a separate reviewed credential or protection
change. Both are nonvisual **ERD Workflows** palette components.

## Implemented profiles

| Family | Memory backend | Reviewed security operation |
| --- | --- | --- |
| Ultralight EV1 48/128, NTAG210/212/213/215/216 | Four-byte ordinary user pages through raw PWD_AUTH and explicit expected PACK | Replace PWD/PACK; update AUTH0, PROT and AUTHLIM against exact configuration preimage |
| SLIX2 | Four-byte blocks through supplied read/write passwords | Replace password 1 or 2; update Page L/H read/write protection against complete AB snapshot |
| Original ST25DV04K/16K/64K | Four-byte blocks through one explicit user password 1..3 | Replace password 0..3; update one active area's password/access policy against complete eight-register configuration |

Type 2 requires an exclusive `IRawContactlessReader`, such as the explicit
ACR122 raw adapter. ISO15693 requires an addressed `IIso15693Session` with
manufacturer commands, such as the explicit ACR1552 address/response dialect.
Security changes additionally require real RF-reset capability. A PC/SC reader
name alone does not establish these vendor command capabilities.

Original Ultralight has no PWD_AUTH profile. ST25DVxxKC and other lookalike chips
are not inferred from the family name. No passwords are guessed or recovered.
Memory workflows exclude UID/configuration/password/lock pages, reserved ISO
blocks zero/one and SLIX2 counter block 79 from writes. They never copy access
policies implicitly. Reads remain subject to the actual card's access policy.

## Prepare, execute and retain evidence

Create a fresh backend for each request. Factories independently copy credentials
and perform no card I/O. Use `PrepareProtectedBackup`, `PrepareProtectedCopy`
or `PrepareProtectedRestore`; inherited generic preparation methods do not
register protected credential cleanup. Ordinary compatible backends may be mixed
with protected backends.

```pascal
SourceMemory := CreateType2PasswordWorkflowMemory(
  SourceRaw, ttmNtag213, SourcePassword, SourcePack);
TargetMemory := CreateType2PasswordWorkflowMemory(
  TargetRaw, ttmNtag213, TargetPassword, TargetPack);
Workflow.PrepareProtectedCopy(SourceMemory, TargetMemory, SelectedPages);
Outcome := Workflow.Execute;
Snapshot := Workflow.Snapshot;
Evidence := Workflow.Results;
```

Use `True` as the final preparation argument for comparison only. Backups and
restores use the existing `TCardWorkflowArchive` selected-memory format and exact
layout identifiers. Raw snapshots contain application data and observed UID;
they contain no supplied passwords/PACKs, and are not encrypted.

Each backend pins the first acquired UID and verifies subsequent acquisitions
**before authentication**. ISO also checks exact geometry. All source data and
all target original data/lock preflights are acquired before the first write.
Type 2 conservatively refuses mirrored memory or any user-memory static/dynamic
lock, even when a selected page might itself remain writable. Authentication is
once per native operation, not once for an entire workflow. Card-defined retry
limits and authentication/counter side effects still apply; failures are never
retried automatically.

`OnProgress`, `OnCardRequired`, `OnCompleted` and `OnError` use the existing
same-thread workflow contract. Run `Execute` on your application worker. Cancellation
is observed between operations; an in-flight write completes verification first.
Credentials are cleared on execution exit, failed protected preparation,
replacement preparation or workflow destruction. A retained backend is consumed
and must be recreated. Caller-owned credential arrays and UI text remain the
caller's responsibility.

Pre-dispatch refusals are `Failed` with pending unit evidence. Only a backend that
can guarantee no memory write was dispatched may raise `ECardWorkflowWriteRefused`.
A lost write response, failed read-back or failed release after possible mutation
remains `Uncertain`. Earlier verified units remain visible. There is no automatic
rollback, retry or write replay.

## Review credential and protection changes

Prepare one native operation with the **exact intended UID**, supplied credentials
and, for policy changes, the complete actual configuration preimage. No hardware
is accessed while creating the operation, calling `Prepare` or reading `Plan`.

```pascal
Operation := CreateType2ProtectionOperation(
  TargetRaw, ttmNtag213, TargetUid, ExpectedConfigPages,
  CurrentPassword, CurrentPack, FirstProtectedPage, ProtectReads, AuthLimit);
SecurityWorkflow.Prepare(Operation);
Review := SecurityWorkflow.Plan;
// Present Review.Before and Review.After in the application before execution.
Outcome := SecurityWorkflow.Execute;
```

The public plan contains family, operation, exact UID, identifier/area and
independent non-secret before/after bytes. Unreadable credential storage has empty
before/after arrays: replacement is proved through authentication, not by claiming
password read-back. Policy operations preserve unrelated configuration bits and
verify the complete preimage again on the live card.

Native factories are `CreateType2CredentialOperation`,
`CreateType2ProtectionOperation`, `CreateIso15693CredentialOperation`,
`CreateSlix2ProtectionOperation` and `CreateSt25ProtectionOperation`.

Successful changes require fresh RF selection, the same UID, successful new/current
credential authentication as appropriate, complete policy verification and successful
release. Type 2 PACK/PWD replacement can partially succeed: both native dispatch
and verification failures retain uncertain evidence. ISO security operations reset
before authentication and after the change. ST25DV operations retain the native
VCC checks; `AExternalPowerStable` is an explicit application guarantee where required,
not an inferred property of a reader connection.

The workflow consumes its operation and clears credentials after execution or
on destruction/replacement. `ResultState` is Pending or Verified, or Uncertain
when mutation could have occurred. Use the overall workflow state/error class
for pre-dispatch failures. Permanent lock programming, area resizing, AFI/DSFID,
privacy and counter mutations are outside these operations.

## Independent VCL demos

`ProtectedType2WorkflowDemo` and `ProtectedIso15693WorkflowDemo` each own their
TForm, editable Main.dfm, source/target reader dropdowns and native reader/card
events. Shared code is nonvisual. Nine actions cover current configuration capture, backup, copy, compare,
restore, credential preview/apply and protection preview/apply. Previews and input
validation perform no card I/O; applies run on the existing background worker.

The left memo contains explicit `key=value` options. The right memo contains a
selected-memory snapshot or review result. Copy/compare uses two distinct readers;
backup uses the source and restore/security actions use the target. Mutation actions
require acknowledgement for each submission. Credential edit fields are masked;
they are never saved into snapshots/review artifacts.

| Option | Type 2 | ISO15693 |
| --- | --- | --- |
| `first`, `count` | Ordinary user-page selection | Block selection; reserved writes rejected |
| `uid` | Seven-byte target UID in hex for security actions | Canonical eight-byte target UID in hex for security actions |
| `before` | Eight configuration bytes for policy changes | SLIX2 seven/eleven-byte AB snapshot or ST25DV eight-register snapshot |
| `auth0`, `protectReads`, `authlim` | Byte AUTH0, 0/1 PROT, 0..7 AUTHLIM | Unused |
| `blocks`, `blockBytes` | Derived from selected model | Exact expected geometry; default SLIX2 80x4; ST25DV 128/512/2048 x4 |
| `addressing`, `responseFormat` | Explicit raw adapter | 0 ordinary / 1 extended block addressing; 0 native flags / 1 payload-only |
| `sourceId`, `targetId` | Password/PACK concatenation | SLIX2 1/2, ST25DV user password 1..3 for memory; password 0 also allowed for explicit ST25DV credential changes |
| `pointer`, `conditions` | Unused | SLIX2 Page H first block 0..78 and RL/WL/RH/WH mask |
| `area`, `passwordNumber`, `protectionCode` | Unused | ST25DV active area 1..4 and explicit two-bit policy |
| `powerStable` | Unused | 0/1 explicit ST25DV external VCC guarantee |

Type 2 credentials are four PWD bytes followed by two PACK bytes. SLIX2 memory
accepts four wire-order bytes with explicit identifier, or eight bytes containing
read then write passwords; protection changes require both. ST25DV credentials
are eight wire-order bytes; protection changes use configuration password zero.
Use **Read current protection configuration** to fill `uid`, `before` and the
current policy options in this same demo. This action runs on the worker; Type 2
requires its supplied password/PACK, while ISO public configuration needs no
password attempt. Both acquisitions guard the same UID across selections.

No known or default passwords are prefilled. Replace geometry/profile/options
explicitly when changing card family.

## Native workflow adapters

See [CARD_WORKFLOW_ADAPTERS.md](CARD_WORKFLOW_ADAPTERS.md) for Ultralight C
user-memory/security operations, protected Type 2/Type 5 NDEF transfer and TWN4
Classic/Type 2 memory adapters. Type 5 proprietary CC access code two is permitted
only with an explicitly authenticated session profile; the flag does not perform
authentication, and read-only code three still prohibits writes.
