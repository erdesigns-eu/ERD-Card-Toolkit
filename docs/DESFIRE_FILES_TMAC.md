# DESFire ISO files, multiple access rights and AES TMAC

These APIs extend `TDesfireCardReader` through optional management and transaction interfaces.
Existing interface layouts and IIDs are unchanged. Select an explicit EV2 AES
profile and supply valid application/PICC credentials and an AES/CSPRNG provider.
No reader, key or card generation is guessed.

## ISO application and file management

`OpenFileManagementSession(Aid)` returns `IDesfireFileManagement` with retained
exclusive ownership. Use PICC AID zero for application directories/creation and
an explicit application AID for file operations.

| API | Acquired or verified result |
| --- | --- |
| `ReadIsoApplications` | Native AID, ISO FID and DF name; preserves native response-frame boundaries |
| `ReadIsoFileIds` | Unique native ISO FID list, independent of file-number ordering |
| `CreateIsoApplicationVerified` | AES application creation acknowledgement and exact acquired AID/FID/DF-name directory tuple |
| `CreateIsoApplicationWithKeySetsVerified` | Combined AES key-set/ISO creation; exact directory tuple, acquired key-set geometry and restored PICC authentication |
| `CreateIsoFileVerified` | Standard/backup/linear/cyclic file settings and newly acquired ISO FID presence |

Creation validates unused native/ISO identifiers and, for applications, an unused
one-through-sixteen-byte DF name. Existing unnamed directory entries are retained.
Native FIDs use little-endian bytes; ISO SELECT APDUs use their ISO representation.
Null/MF/current-directory/reserved FIDs are refused for these profiles. ISO file
creation requires the acquired application's ISO-FID support flag. Value files do
not have an ISO creation parameter in this API.

GetDFNames returns one variable-length tuple per native frame. The engine preserves
these boundaries and verifies the complete secure-message MAC before parsing.
Flattening those frames would lose DF-name lengths. Duplicate/invalid tuples,
truncation and extra data are refused. Temporary frame capture is cleared on every exit.

Application key policy/count are acknowledged creation inputs; the directory
independently proves the ISO tuple. No guessed initial application key is used to
read back a new application's key policy. File creation independently verifies
ordinary geometry, mode, rights and FID presence under exclusive ownership.
ISO identifiers do not automatically make a complete NFC Forum mapping: provision
CC/NDEF content and permissions explicitly.

`OpenIsoKeySetManagementSession` returns `IDesfireIsoKeySetManagement`, a new
optional extension of file management. `CreateIsoApplicationWithKeySetsVerified`
places the ISO FID and name after the complete key-set header, enabling both ISO
and multiple-set flags. It accepts one-through-fourteen AES keys, two-through-sixteen
sets, an explicit initial set version and roll selector. It verifies the directory
then selects the new application and acquires all seven key-settings bytes before
restoring PICC selection and authentication. A subsequent management operation
therefore starts with the restored session's counters and credentials.

The creation policy must allow public key-settings acquisition (bit one set).
A policy that closes this access is refused before creation; no initial application
key is inferred to obtain the proof. Native/ISO/name collisions are checked before
mutation. Wrong acquired FID/name/geometry and any failure after creation through
reauthentication retain dispatch uncertainty. These optional interfaces preserve
all existing interface layouts and IIDs.

## Multiple access-right tuples

| API | Behavior |
| --- | --- |
| `ReadMultiAccessSettings` | Complete ordinary geometry plus primary and up to seven additional tuples |
| `ChangeMultiAccessVerified` | Frozen exact preimage, encrypted settings change and complete settings read-back |
| `ReadMultiAccessData` | Standard/backup data, using acquired primary or additional read authority |
| `WriteMultiAccessDataVerified` | Standard data, exact prior-content check and read-back using acquired additional rights |

Rights are native wire-order words: low-byte read/write/change nibbles, high-byte
read/write nibbles. The primary change key governs policy changes. Both read and
write authority are needed for verified writes. Key references are checked against
acquired application settings. The application's create/delete policy does not
replace an ordinary file's data/change authority.

One tuple encodes ordinary settings; two-through-eight encode the multi-access
flag and exact count/suffix. Removing additional tuples is supported. Settings
changes preserve ordinary file geometry and key versions. Writes compare the
frozen acquired byte range, preserve settings across the operation and skip equal
data. Ordinary getters continue to reject extended layouts rather than silently
losing additional rights.

These management operations require readable application/file metadata. Extended
backup/value/record transaction workflows and profiles that cannot expose the
metadata remain separate. Combined SDM/right settings are now managed through the dedicated API described below. Backup data
is readable here; writes use the existing transaction APIs for ordinary layouts.

## Combined SDM and multiple-access settings

`OpenSdmAccessManagementSession(Aid)` exposes `IDesfireSdmAccessManagement`.
`ReadSdmAccessSettings(File)` preserves ordinary geometry, every right tuple and
all conditional SDM fields. `ChangeSdmAccessSettingsVerified(File, Expected,
Desired)` freezes the complete desired encoding and exact preimage before I/O,
validates every ordinary/SDM application-key reference and primary change authority,
sends encrypted native `5F` and verifies the complete resulting raw settings.

Native additional tuples follow ordinary file geometry and precede conditional
SDM fields. `TDesfireExtensionCodec.EncodeSdmAccessSettings` and
`DecodeSdmAccessSettings` validate this combined framing without changing the
existing ordinary/SDM codecs. The primary tuple must agree with typed SDM rights;
file size remains unchanged. SDM still requires Plain file communication and
valid, nonoverlapping mirror regions. Enabling/removing SDM and adding/removing
additional tuples can be combined in one change. Equal settings skip mutation.

The API changes policy/settings only; it does not write templates or define an
automatic combined-layout data/migration workflow. Original getters continue to
refuse layouts they cannot preserve. Returned arrays are owned but shared by
ordinary record assignment. See [SDM fields/crypto](DESFIRE_EXTENDED.md).

## TMAC file management

`IDesfireFileManagement` also exposes:

- `CreateTransactionMacFileVerified`: encrypted supplied AES key/version; exact
  acquired file option/access/key-option/version verification.
- `ReadTransactionMacSettings`: owned six-byte base or ten-byte AES counter-limit settings.
- `ChangeTransactionMacSettingsVerified`: exact preimage, encrypted communication,
  access, exclusion and counter-limit change, complete metadata verification.
- `DeleteTransactionMacFileVerified`: explicit key-zero management and verified
  directory absence against acquired metadata.
- `ReadTransactionMacRecord`: complete unsigned counter and eight-byte stored MAC,
  using acquired access/communication mode and unchanged settings.

Creation and deletion require selected application key zero. Settings changes use
the acquired change-key authority. The write access nibble must remain F; the
read/write nibble specifies CommitReaderID authority, not ordinary write permission.
AES limits are explicit nonzero unsigned 32-bit values; clearing the limit requires
its flag unset and a zero supplied limit. Key option/version are preserved by
settings changes. Creation starts without a configured limit; set one explicitly.
Native lifecycle/current-counter restrictions are enforced by card status.

`TDesfireTmacRecord.SessionProtected` identifies a verified secure-session response
MAC. Plain record acquisition requires explicit `MinimumCommunication := dfcPlain`
and returns this flag false. `KeyVerified` is false for ordinary record acquisition:
metadata and channel verification do not independently prove the static TMAC key.

## Complete AES TMAC transactions

`OpenTransactionMacSession(Aid, TmacFile, RealUid, TmacKey, PreviousCounter, True)`
returns `IDesfireTransactionMacSession`. The final Boolean explicitly asserts that
there is no externally pending transaction. The profile owns the transaction and
requires:

- The exact existing AES TMAC file and ordinary file layouts; record sizes must be multiples of sixteen bytes.
- A seven-byte real UID, checked by protected GetCardUID before data manipulation.
- A supplied sixteen-byte static TMAC key and trusted previous counter below FFFFFFFF.
- Valid ordinary read/write credentials; readable metadata and sufficient journal/TMI budget.

The session copies UID/key inputs before I/O. The static key is cleared on commit,
abort, failure and closure. Existing ordinary transaction sessions still reject
TMAC-enabled applications; callers choose the dedicated profile explicitly.

Inherited backup/value/record operations use the existing owned journal.
Successful plaintext reads and changes are captured in exact canonical TMI,
including reads used to acquire journal preimages. Metadata, authentication,
chaining overhead and secure-message MAC/padding are excluded. TMI is bounded to
1,048,560 bytes before dispatch, with published per-command zero padding. Record
data must be AES-block-aligned. Implicit zero/all counts are not accepted.

`ReadTransactionMacInput` returns an independent copy for inspection/backend use.
It contains card data and must be cleared by the caller. It is not a credential
archive. Reads create a pending TMAC calculation: explicitly commit or abort it.
Abandoning a pending session does not perform an automatic abort or rollback.

`CommitReaderId(ReaderId)` sends one explicit sixteen-byte reader identifier under
CommMode.MAC. The response contains transaction-key-encrypted `EncTMRI`, protected
by the secure-session MAC. It has no additional session-CBC layer. The static
transaction encryption key decrypts the previous reader identifier. Canonical TMI
retains the current ReaderID and encrypted previous-ID bytes. Reader commitment
can occur only once and must satisfy its acquired access key.

`CommitTransactionMacVerified` performs one native commit requesting TMC/TMV. It:

1. Verifies unchanged TMAC configuration and required reader commitment.
2. Requires the exact trusted next counter and a secure-session-authenticated receipt.
3. Derives the AES TMAC key from that resulting counter and real UID and checks the receipt against captured TMI.
4. Verifies all journaled file contents/settings after commit and successfully releases ownership.

Only then is the receipt returned with both `SessionProtected` and `KeyVerified`
true, and session `VerificationSucceeded` true. Wrong keys, counters, receipts,
file state or release after dispatch produce `EContactlessWriteUncertain`; no
commit is retried. The card may restrict post-commit data reads when its counter
limit is reached; a failed journal read-back is reported, never treated as verified.
Abort uses the ordinary native abort path and clears the owned calculation/key.

The ordinary `Commit` method is refused on this profile, so it cannot silently
discard the receipt. A read-only calculation can also be committed and verified.
It updates the counter/receipt without inventing file mutations.

## Immediate standard data inside a TMAC calculation

`OpenTransactionMacDataSession` accepts the same explicit application, TMAC file,
real UID, static transaction key, trusted previous counter and fresh-state
acknowledgement. It returns `IDesfireTransactionMacDataSession`, a new optional
extension of the existing TMAC transaction interface.

`WriteStandardDataVerified(File, Offset, Expected, Data)`:

1. Freezes both equal-length nonempty buffers before I/O.
2. Acquires ordinary standard-file type, geometry and read/write authority.
3. Reads the exact range and checks unchanged settings and the supplied preimage.
4. Skips a write when data is equal; otherwise dispatches one native immediate write.
5. Verifies the written range immediately and checks unchanged settings.
6. Journals the expected final range for another content/settings proof after a
   separately verified TMAC commit.

Both primary read and write rights must grant access. The profile does not silently
extend to SDM or multiple-access layouts. Bounds use acquired file geometry.
Journal bytes and entry counts are bounded before mutation. Repeated and
overlapping writes update earlier expected ranges; disjoint ranges remain
independent. The post-commit proof covers every journaled range and its settings,
not untouched file bytes. No-op preimage reads still contribute to TMI and require
an explicit calculation commit or abort.

**Standard writes are immediate and survive Abort.** `Abort` cancels the native
transaction/TMAC calculation and clears its owned secrets; `dsoAborted` does not
mean standard data was restored. Closing does not perform an automatic rollback.
A caller needing rollback-capable file updates must use backup files and the
existing transaction operations. Unverified write/receipt/read-back/release after
mutation raises `EContactlessWriteUncertain`, even if the write itself was
acknowledged. Never retry such a write solely because commit proof failed.

## Native cyclic-record updates

`OpenRecordUpdateSession(Aid, True)` exposes `IDesfireRecordUpdateSession` under
fresh, exclusively owned EV2 AES transaction state. The same optional interface
is available through `Supports` on `IDesfireTransactionMacSession`.

`StageCyclicRecordUpdate(File, Record, Expected, Data)` implements native `BA` for
an existing sixteen-byte cyclic record. The explicit index is newest-first.
It freezes both complete sixteen-byte buffers, checks acquired geometry and
native read/write authority, and compares the current owned-journal preimage.
A first update acquires all existing records; a repeated update uses the owned
staged expectation. Equal data skips native mutation.

The update is staged. Ordinary `Commit` or TMAC `CommitTransactionMacVerified`
proves all final records/settings. TMAC captures `BA`, its complete ten-byte
header with five zero padding bytes and the complete record data exactly once,
independent of outbound `AF` chaining. Explicit Abort cancels staged updates.

A file cannot mix record update with append/clear within the same transaction;
updates may repeat only for the same record index. Conflicts in either order
are refused before another mutation. Failures after staging retain uncertainty.
The published Light profile defines the aligned sixteen-byte case; partial or
unaligned TMAC record updates are not inferred. Other card generations must
support the explicitly selected native command profile.

## Offline tools and references

`TDesfireTmacCrypto` provides exact AES key derivation, canonical input append,
truncated transaction MAC and previous reader-ID decryption. It uses the published
SV1/SV2 vectors, resulting counter and actual native command opcodes. LRP and
unaligned record TMI use different profiles and are not inferred.

Protocol references:

- [NXP MF2DLHX0 Rev. 3.3](https://www.nxp.com/docs/en/data-sheet/MF2DLHX0.pdf), sections 10.3 and command tables for TMAC input/keys, CommitReaderID and AES limits.
- [NXP AN12343](https://www.nxp.com/docs/en/application-note/AN12343.pdf), protected native TMAC file creation examples.
- [Native ISO and multi-access reference](https://github.com/liblogicalaccess/liblogicalaccess/tree/5a23140333ffc0c5dd60b2af4dcee3a435c82b29/plugins/logicalaccess/plugins/readers/iso7816/commands), cross-checked against native ISO examples.

The shared AES framing does not imply DESFire Light supports general application
creation. No external library code is included or required. See
[VALIDATION.md](VALIDATION.md) for independent transcripts and failure coverage.

## LRP transport and TMAC profile

Explicit LRP First/NonFirst data and owned transaction sessions now use the same
reader, ordinary journal, aligned-record TMI and verification contracts. Select
`dfsLrp` and use `OpenLrpTransactionMacSession` for an existing TMAC file. The
counter has two sixteen-bit subparts; LRP derives the transaction keys while
ordinary AES computes the receipt and EncTMRI. Unknown internal-session counters
are acquired from a verified receipt, with an optional deferred ReaderID result.
Protected real-UID and stored LRP-TMAC inspection helpers are also available. See [DESFIRE_LRP.md](DESFIRE_LRP.md) for exact input, counter and release rules.
LRP file/key/configuration provisioning and partial/unaligned record profiles
remain separate; the AES management interfaces retain their existing profile.


## Owned multiple-access transactions

`OpenMultiAccessTransactionSession(Aid, True)` opens an explicit fresh EV2 AES
owner for ordinary and multiple-access backup/value/linear/cyclic-record files.
It retains the existing `IDesfireSession` ABI and operations: WriteBackup,
Credit/Debit/LimitedCredit, AppendRecord/ClearRecords, Commit and Abort. Existing
OpenSession remains strict ordinary access. The new entry requires a nonzero AID
and explicit fresh-transaction acknowledgement before acquisition; SDM, TMAC and
unknown/invalid settings are refused before pending-state mutation.

All primary/additional tuples participate in command-specific authorization.
Credit requires ReadWrite, LimitedCredit allows Write or ReadWrite, and Debit/
GetValue retain their documented Read/Write/ReadWrite rules. Data/record writes
require Write/ReadWrite; journal acquisition and final proof also require reading.
An extra Write grant alone does not imply a readable backup or permit Credit.
Minimum communication and explicit NonFirst reauthentication still apply.

The decoded ordinary geometry remains available in TDesfireFileSettings; its
RawBytes retain the **complete** combined settings. Use MultiAccessSettings for
typed access to all tuples. Journal static comparison preserves every tuple and
option while masking only the established mutable value/record-count fields.
Commit verifies complete final content/count/settings and exclusive release;
verified commit acknowledgement alone does not make VerificationSucceeded true.
Abort does not claim final-content readback. Limits and mutation budgets remain
those of the ordinary journal. Application workflow archive v2 now retains these
layouts; see [the workflow profiles](PROTOCOL_COMPLETION.md).

Plain, MACed and Full are supported with explicit minimum communication. Plain
content is not cryptographically authenticated: an altered full-file preimage can
remain unobservable when the entire file is replaced. Postimage equality remains
checked; MACed/Full additionally verify protected responses. SDM mirrors and TMAC
combination/partial-record canonical input require their own profiles.

## Combined workflow profiles

Multiple-right AES TMAC owners, profile-aware application workflows and authenticated
stored SDM template backup/compare/restore are described in
[protocol/workflow profiles](PROTOCOL_COMPLETION.md). SDM/TMAC combined data operations
remain separate; the template profile refuses an application containing a TMAC file.
