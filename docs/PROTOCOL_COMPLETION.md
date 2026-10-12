# DESFire and MIFARE Plus workflow profiles

These nonvisual APIs extend the existing session, project and workflow components.
They do not require a new application or demo. Both new components start inactive
and support RTL component streaming.

| Profile | Native API | Reusable workflow/project API |
| --- | --- | --- |
| DESFire multiple rights + AES TMAC | `OpenMultiAccessTransactionMacSession` | `TDesfireWorkflowCard.CreateMultiAccessTmac`; `TDesfireApplicationWorkflow.TransactionMacReceipt` |
| DESFire multiple-right application content | `OpenMultiAccessSession` / existing fresh transaction owner | `CreateMultiAccess`; `ERD-DESFIRE 2` / `desfire.v2` |
| Stored SDM template | `OpenSdmTemplateManagementSession` / `IDesfireSdmTemplateManagement` | `TDesfireSdmTemplateWorkflow`; `TDesfireSdmArchive`; `sdm-template.v1` |
| Plus SL2 data/trailer access | `TMifarePlusSl2ReaderWriter` / `IMifarePlusSl2Session` | `CreatePlusSl2WorkflowMemory`; existing `TProtectedMemoryWorkflow` |

## Multiple-right AES TMAC

Provide an EV2 AES reader, application ID, existing TMAC file number, trusted
seven-byte real UID, supplied sixteen-byte TMAC key and last accepted counter.
The acknowledgement explicitly asserts ownership of a fresh calculation. No key
or counter is guessed. The owned TMAC file is excluded from ordinary content
snapshots; its presence and settings are still checked natively.

`CreateMultiAccessTmac` freezes those inputs and reader configuration. Read capture
explicitly aborts a nonempty calculation before release, without committing or
advancing its counter. A write owner is single-use, even when acquisition fails.
Create a new adapter using the last independently accepted counter for another
mutation. `TransactionMacReceipt` exposes copied counter/MAC verification evidence,
never the static key. Persist receipt evidence separately from reusable content;
a content archive is not proof that a later target operation succeeded.

Backup/value/record writes and standard-file writes share the explicit owner.
Complete multiple-right settings are preserved and compared after commit.
Standard data remains an immediate mutation: Abort discards the calculation and
staged backup/value/record changes, but does not restore standard bytes. Cancellation
after an immediate change requires verification; failures after dispatch remain
uncertain. Neither native code nor workflows retry or compensate a failed write.
Combined SDM/TMAC data and unaligned/partial-record TMAC profiles remain separate.

## Application archives and provisioning

`CreateMultiAccess` selects the extended settings parser without weakening ordinary
interfaces. Snapshots retain every primary/additional right tuple. Encoding selects
`ERD-DESFIRE 2` and project profile `desfire.v2` when additional rights are present;
ordinary images retain version 1. Decoding is bounded and canonical, and checks that
raw and typed settings agree. Keys are excluded.

Optional per-file creation policies specify complete ordered tuples. Preparation
checks duplicate policies, matching primary definitions, every key index against
the new application key count, and change authority before creating an application.
The native sequence creates the ordinary file, then applies and verifies extended
rights. These are two immediate commands, not an atomic operation. A policy failure
after creation reports uncertainty; the file may already exist. Neither the file
nor application is automatically deleted or recreated.

## Stored SDM templates

Use EV2 AES authentication with an **explicit Plain minimum**. SDM files use Plain
communication for data, even when access requires authentication. The adapter
acquires protected real UID and settings on the same exclusive session, checks
all access tuples and returns complete stored bytes. Authenticated reads do not
perform the dynamic SDM mirrors used by unauthenticated reads (NXP AN12196).

`TDesfireSdmTemplateWorkflow.PrepareBackup` captures one complete standard file.
`PrepareRestore` first captures the target, requires identical complete SDM/right
policy, checks target UID/settings and full preimage again before dispatch, skips
same-content writes, and verifies complete read-back plus unchanged settings.
The target application/file can differ from the source; credentials are supplied
separately. `Matches` reports initial equality; `Verified` reports live no-op/write
verification. `Snapshot` and archived data are independent copies.

Plain data has no response MAC. Protected UID/settings and byte equality are
useful session/read-back evidence, but do **not** prove cryptographic authenticity
of the Plain template body. Use the existing offline SDM MAC/decrypt APIs for an
actual mirrored message. Never save a changing UID/counter/MAC mirror as a reusable
stored template. This profile refuses applications containing a TMAC file before
data I/O, does not change SDM policy, and does not automatically provision CC/NDEF
files or reset counters. The existing extended-management API remains available
for explicit verified policy administration.

Archives use bounded canonical `ERD-SDM 1` / `sdm-template.v1` and contain no keys.
The project component's existing per-artifact budget also applies; larger standalone
images are not silently truncated to fit a project.

## Plus SL2: AES followed by Crypto1

Configure `Session`, maintained AES/CSPRNG `CryptoProvider`, explicit 2K/4K `Model`,
sector AES `KeyNumber`/sixteen-byte `Key`, six-byte `ClassicKey`, Classic `KeyType`
and pinned four/seven-byte `ExpectedUid`. Ordinary operations exclude manufacturer
block zero and sector trailers. The 4K high sectors use their correct 16-block
geometry and 5/5/5 data access groups.

The component performs native layer-3 `$70/$72` AES mutual authentication, validates
the nonce/capability proof and derives the six-byte SL2 key modifier independently.
It then invokes reader-owned Crypto1 with the modified supplied Classic key,
without resetting RF or reselecting the card. Live trailer access conditions are
checked before data reads/writes; readable key B is treated as data, not authority.
Writes require a full preimage, dispatch once and verify sixteen-byte read-back.

`CreateAcr122PlusSl2Session` supplies the PN532 backend. It disables automatic RATS,
uses raw CRC-checked AES frames, restores framing before hardware Crypto1 on the
same acquisition, and restores registers/RF/native ownership on release. A generic
PC/SC Classic reader that reselects between authentication commands cannot satisfy
this interface merely by accepting the same key bytes.

`ReadSectorTrailer` returns only observed visible bytes. For explicit programming,
`WriteSectorTrailerVerified` requires the complete visible preimage, full supplied
new A/B keys plus access bytes/GPB and acknowledgement. It checks old write authority
and access complements before dispatch, then starts fresh same-UID acquisitions
for new key A and, when configured as a key, new key B. Readable B is instead
verified as stored data. `TMifarePlusSl2TrailerResult` distinguishes these proofs;
masked keys are never synthesized. Reader credentials are not silently changed.
General SL3 trailer/global configuration and Plus EV2 LRP are still separate work.

`CreatePlusSl2WorkflowMemory` binds scoped `IPlusSl2WorkflowKeys` to the existing
protected backup/copy/compare/restore engine. Archives use `PLUS-SL2-ordinal`, exclude
block zero, trailers and keys, and remain distinct from SL3 archives. Temporary
credentials are cleared after every use and the backend is consumed on workflow
cleanup. Trailer/key migration uses the explicit API above, not ordinary restore.

## Sessions and operation queue

Bind these prepared workflows through existing `CreateCardWorkflowOperation` or
`CreateCardMultiWorkflowOperation` callbacks and reader leases. Supply the leased
transport when constructing frozen DESFire readers or the ACR122 SL2 adapter.
The workflows own native transactions; the operation bridge handles cancellation,
progress and generation checks. Reservations do not make physical writes atomic.
Store successful snapshots with their typed project archive helpers. Persist
selected IDs/profiles, not reader objects, prepared mutation plans or credentials.

## References and validation

Protocol facts were cross-checked against NXP AN12196/AN12343 and the existing
native Plus layer-3 authentication definitions referenced in [MIFARE Plus](MIFARE_PLUS.md).
No third-party reader source is copied or compiled into these components.
Independent Python/OpenSSL fixtures cover secure-message bytes, TMAC receipts,
SL2 modifier derivation and the complete ACR122 framing transition. The Pascal
suite injects failures at every new transcript exchange and checks cleanup,
no replay, uncertainty, access conditions, independent archive ownership and
native workflow adapters. See [validation](VALIDATION.md).
