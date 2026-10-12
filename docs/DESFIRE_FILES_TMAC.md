# DESFire ISO files, multiple access rights and AES TMAC

These APIs extend `TDesfireCardReader` through two new optional interfaces.
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
CC/NDEF content and permissions explicitly. ISO creation combined with new
multi-key-set provisioning remains a separate creation profile.

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
backup/value/record transaction workflows, SDM combined with multiple access
rights and profiles that cannot expose the metadata remain separate. Backup data
is readable here; writes use the existing transaction APIs for ordinary layouts.

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
