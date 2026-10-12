# Native DESFire files and AES/DES secure messaging

`TDesfireCardReader` is an RTL-only nonvisual component for native ISO-wrapped
DESFire commands over a connected `ICardTransport` with `ICardTransaction`.
It supplies application/file discovery, data/value/record reading, verified
standard-data writing and retained transaction/management sessions. Explicit EV1 and EV2 AES profiles include mutual
authentication and Plain, MACed and Full messaging. EV2 additionally supports an
optional NonFirst switch to a second application key. Explicit EV1 2K3DES/3K3DES
and D40 DES/2K3DES profiles cover ordinary file access, transactions and native
application/file creation/deletion; see
[LEGACY_MIFARE_SECURITY.md](LEGACY_MIFARE_SECURITY.md). AES key/access-policy mutations
remain separate. No constructor opens a reader.

Source use requires `src/core` and `src/contactless`, plus `src/crypto` for a
concrete provider and `src/pcsc` for Windows readers. The existing contactless
package depends on Core/RTL. `ERDCardCryptoWindows.dpk` is a separate optional
runtime package for Windows CNG, keeping OS cryptography out of the base core
package. All exported declarations carry Delphi XML documentation.

## Implemented profiles

| Layer/operation | Implemented behavior | Separate work/evidence |
| --- | --- | --- |
| Native wrapping | `90 INS 00 00 [Lc Data] 00`, `91xx` status and bounded `AF` chains | Raw RF and arbitrary reader pseudo-APDUs are different backends |
| Discovery | One-shot public discovery and retained authenticated application/file directories and key settings | Native ISO directories use the optional file-management interface; other generation-specific extensions remain separate |
| Ordinary file settings | Standard, backup, signed value, linear/cyclic records; strict geometry/access parsing | SDM/multi-access/TMAC use separate strict codecs/interfaces; other generation-specific types remain separate |
| Public file access | Plaintext free-access reads and verified standard-data range writes | No key guessing or automatic authentication fallback |
| EV1 AES | `AuthenticateAES` (`AA`), fresh CSPRNG nonce, mutual verification, AES session key and chained IV | Native EV1 AES dialect; D40/DES/2K3DES/3K3DES are separate profiles |
| EV1 3DES | Explicit `1A` authentication, 16/24-byte keys, nonce sizes 8/16, chained eight-byte CMAC and CRC32 encryption | Same-type rotation and ordinary native management; extended key sets remain separate |
| D40 legacy | Explicit `0A` authentication, 8/16-byte keys, reset-IV legacy inverse send, four-byte CBC-MAC and CRC16 encryption | Plain legacy metadata/acks have no transmitted MAC; no security downgrade |
| EV2 AES | `AuthenticateEV2First`, fresh CSPRNG nonce, mutual nonce/capability-echo verification, session ENC/MAC keys and TI | Explicit AES profile, no LRP negotiation |
| EV2 NonFirst | Optional `77` authentication with a second explicit key after verified settings; new session keys, retained TI/counter | One key switch within each acquired data/value/record operation; key-set management is separate |
| Secure file access | Plain/MACed/Full data/value/record reads and standard-data range writes; authenticated settings | Physical EV1/EV2/EV3/Light, firmware and reader compatibility remain unvalidated |
| Backup/value/record modification | Owned sessions stage backup ranges, credit/debit/limited credit, linear/cyclic append and record clearing; explicit commit/abort and complete post-commit verification | Transaction-MAC files/receipts, readers/cards with additional transaction features |
| Administration | Explicit PICC-level application create/delete and all five ordinary file create/delete operations across public/AES/ISO-3DES/legacy profiles, selectable new application key storage, with verified directories/settings; AES key rotation, key policy and ordinary access/mode changes | Formatting and originality remain separate; ISO/multi-access/AES TMAC and key sets/configuration/SDM use optional interfaces |

EV2 is a **secure-messaging dialect**, not a guessed card generation. NXP AN12343
states that DESFire Light AES messaging works like DESFire EV2. The shared
`AuthenticateEV2First`/AES dialect is also used in compatible EV3 applications;
this implementation does not establish physical compatibility with every such
card or feature configuration. EV1 has different authentication and secure-message
rules even when its key type is AES. Select a profile deliberately; an ATR/version
hint does not authenticate a card or select a security mode.

Existing ISO/NDEF files are still accessed through [Type 4 NDEF](TYPE4_NDEF.md)
when appropriate. A native file number 0..31, a three-byte native AID and an ISO
file identifier/DF name are distinct identifiers.

## Cryptographic providers

`ICardAesProvider` supplies bounded AES-128 CBC without padding and a CSPRNG.
The component never implements its own AES cipher or substitutes a deterministic
random source. `TCardCrypto` implements NIST AES-CMAC composition through that
provider, the explicit EV1 chained-IV CMAC variant, and an equal-length comparison with no source-level early mismatch exit.
It is not a timing/side-channel certification.

`TCardWindowsAesProvider` uses Windows 7+ CNG `bcrypt.dll`, per-call algorithm/key
handles, independent IV/key buffers, checked native output lengths and system RNG.
Local secret copies/key-object bytes are overwritten and native handles released.
`TCardOpenSslAesProvider` is an optional Linux OpenSSL 3 backend using
`libcrypto.so.3`; it is not linked into Windows runtime packages. The Linux test
workflow also needs OpenSSL development headers/library for the CNG ABI shim.
The host maintains those cryptographic libraries and their security updates/policy.

No production key is supplied. Application code assigns the explicit key number
and exactly 16 key bytes. The component copies credentials; its getter returns an
independent copy. Set `AuthenticationKey := nil` or destroy the idle component to
clear its retained initial credential. `ReauthenticationKey := nil` clears the
optional second credential; destruction clears both. Do not embed real keys in tests, command-line
arguments or logs. A provider can implement hardware-backed key policy in a future
interface; this byte-key contract currently receives key material in host memory.

## Using protected files

```pascal
uses ERD.Card.Crypto.Windows, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2;

Reader := TDesfireCardReader.Create(nil);
try
  Reader.Transport := ConnectedCard.Transport;
  Reader.CryptoProvider := TCardWindowsAesProvider.Create;
  Reader.Security := dfsEv2Aes;
  Reader.KeyNumber := ApplicationKeyNumber;       // explicit 0..13
  Reader.AuthenticationKey := SuppliedAesKey;    // exactly 16 bytes, copied
  Reader.MinimumCommunication := dfcFull;
  Bytes := Reader.ReadData(NativeAid, NativeFileNumber, 0, RequestedBytes);
  // WriteData is an explicit separate operation with read-back verification.
finally
  Reader.Free;
end;
```

Declare `Reader: TDesfireCardReader`, `Bytes/SuppliedAesKey: TBytes`,
`NativeAid: Cardinal`, `NativeFileNumber/ApplicationKeyNumber: Byte` and
`RequestedBytes: Integer` in the calling scope. Key values and file IDs come from
the owner/application provisioning configuration, never from a guessed default.

The default security profile is `dfsPublic`. A public operation requires free
read/write access through the corresponding key nibble or the alternative
read/write nibble, and plaintext communication. The value-file free-GetValue flag
is decoded explicitly. Configuring a key alone does not silently change profiles.

In `dfsEv1Aes` and `dfsEv2Aes`, every file operation selects its exact native
application and authenticates afresh in one retained transaction. The currently
authenticated key or a free route must grant the operation. `GetFileSettings` is MACed after
EV2 authentication; metadata is verified before interpreting access/geometry/mode.
The default `MinimumCommunication` is MACed. An acquired weaker file mode is
refused before the data command. Select Plain explicitly for an intentionally
plaintext authenticated file. EV2 Plain data has no transmitted MAC; EV1 AES
Plain responses still carry a verified CMAC. Unexpected plaintext in an acquired
Full-mode response is rejected, including cards/configurations that bypass secure
messaging for free-access routes; no automatic weaker-mode retry is sent.

Use `Reader.Security := dfsEv1Aes` for the native EV1 AES dialect with the same
provider/key properties. File operations use `BD`/`3D`/`BB` instead of EV2's
`AD`/`8D`/`AB`. There is no automatic generation or authentication fallback.

For an EV2 application where the settings key and data-access key differ:

```pascal
Reader.Security := dfsEv2Aes;
Reader.KeyNumber := SettingsKeyNumber;
Reader.AuthenticationKey := SuppliedSettingsKey;
Reader.ReauthenticationKeyNumber := DataAccessKeyNumber;
Reader.ReauthenticationKey := SuppliedDataAccessKey; // exactly 16 bytes, copied
Bytes := Reader.ReadData(NativeAid, NativeFileNumber, 0, RequestedBytes);
```

The additional key numbers are `Byte`; both supplied keys are `TBytes`. NonFirst
is enabled solely by a nonempty second key, not guessed from access rights. Initial
settings are verified under the first session. The acquired minimum communication
mode is checked before switching, and the active second key must grant the intended
read/write access. The component never treats initial-key rights as second-key rights.
The key switch occurs at most once, also for read-back verification and subsequent
settings checks. A failed handshake ends the acquired operation without retry.
`ReadValue` and `ReadRecords` follow the same rule. `ReadFiles` deliberately uses
only the initial key for metadata; the metadata-only console example does likewise.
Configuring a NonFirst key with Public or EV1 file access is refused before acquisition.

`ReadFiles` acquires public file numbers before authenticating for individual
settings. A denied directory status is not retried or treated as an empty list.
Known native AID/file operations do not require directory enumeration.
`ReadVersion` and `ReadApplicationIds` deliberately use unauthenticated PICC
queries. The one-shot APIs never guess AIDs or modify directories. Retained management sessions provide explicit create/delete commands; they do not change existing access rights.

## Message and ownership rules

### EV2 AES and NonFirst

EV2 First authentication sends key-number/capability-length zero with `71`, decrypts the
16-byte card nonce, obtains a fresh independent 16-byte reader nonce and sends
`RndA || RotateLeft(RndB)` in a 32-byte AES-CBC challenge. Authentication uses a
zero IV for each message, unlike some earlier DESFire schemes. The 32-byte final
response must contain the rotated reader nonce, four-byte TI and matching echoed
zero reader capabilities. There is no success before mutual nonce verification.
The published NXP authentication/session-key vectors anchor those rules.

NonFirst sends `77` with the second key number alone, then the same fresh-nonce
32-byte zero-IV challenge. Its final response contains exactly the 16 rotated
reader-nonce bytes, without TI or capabilities. New ENC/MAC keys are derived from
the second key and both new nonces. TI and command counter are retained unchanged;
authentication itself does not increment that counter. In component operations,
the initial authenticated settings command has already consumed counter 1. No
application selection, transaction release or EV2 First restart occurs between
the two authentications.

EV2 session ENC/MAC keys are derived with the specified separate CMAC vectors.
The command MAC covers instruction, little-endian counter, TI, clear header and
transmitted body. Full mode encrypts data using the label-derived CBC IV and
ISO 9797-1 method-two padding; even aligned data receives a full padding block.
Header-only reads contain no padded encrypted command body. Truncated MAC uses
zero-based bytes 1,3,...,15 of the complete 16-byte CMAC.

The response MAC covers successful status, **incremented** counter, TI and the
complete transmitted response body. MAC verification precedes decryption. Full
responses must have exactly the ciphertext size and padding implied by the requested
plaintext length. A write acknowledgement contains its MAC without an encrypted
empty-data block. Plain authenticated commands still advance the counter.
Counter rollover is refused; there is no recovery from a stale/broken session.

### EV1 AES

EV1 authentication uses `AA` and a one-byte explicit key number. The first
16-byte card challenge is decrypted with a zero IV. Its ciphertext becomes the
IV for encrypting `RndA || RotateLeft(RndB)`; the last challenge ciphertext block
becomes the IV for decrypting the final 16-byte rotated reader nonce. Both fresh
16-byte nonces derive the single session key as A[0..3], B[0..3], A[12..15], B[12..15].
Only after nonce verification does the messaging IV start at zero.

EV1 CMAC uses the full previous 16-byte IV and advances it to the full new CMAC;
transmitted tags use the **first eight bytes**, unlike EV2's odd-byte truncation.
Read/metadata commands advance CMAC over instruction and clear header without
transmitting a command tag. Plain and MACed read responses verify CMAC over
plaintext plus successful status. MACed writes append their command CMAC.

Full writes leave headers clear and encrypt the body plus native CRC32 over
instruction/header/plaintext, rounded up with zero padding to complete AES blocks.
Aligned body-plus-CRC receives no extra block. The last ciphertext block advances
the IV. Full read responses encrypt plaintext plus CRC32 over plaintext/status;
exact requested length determines CRC and padding positions. Zero padding and an
optional leading `80` padding marker are accepted, with no search for a guessed
plaintext length. CRC is reflected polynomial EDB88320, preset FFFFFFFF, no final
XOR, little-endian bytes. Write acknowledgements remain CMAC protected even after
an encrypted command. No decrypted response escapes CRC/padding validation.
EV1 Full uses legacy encrypted-CRC integrity, not EV2 encrypt-then-MAC. Failed
responses never advance the codec's owned IV; the entire failed card session is
discarded regardless, since the card may already have advanced its own state.

### Shared lifecycle

`AF` frames continue exactly one logical command. Outbound continuations require
empty `91AF` acknowledgement until all command bytes have been sent. Incoming
continuations must make progress. Generation-specific IV/counter and final response integrity apply
to the complete logical message, not separately to each frame. Early success,
nonprogress, oversize data, unexpected status/length and transport errors stop.
Command payload defaults to 48 bytes, configurable 16..255 for the actual reader.
Authentication's mandatory 32-byte challenge is a separate frame and is not
split by that file-transfer setting. Maximum per-operation plaintext defaults
to 65536, is configurable up to 1048500 and is additionally bounded by acquired
file geometry. Every logical command has a hard 65536-frame ceiling.

Data/record ranges use positive explicit counts; zero/all wire requests are
refused. Record offsets are relative to the newest record and returned ordering
is preserved. Signed value responses must fit their acquired limits. Settings
are acquired again after reads to reject changed geometry/access. This is not a
cryptographic card-originality check or an atomic snapshot across operations.

The component rejects reentrancy/configuration changes while busy, retains its
transport throughout the operation and clears local nonces/session keys during
cleanup. It releases only a successfully acquired transaction and preserves a
primary error over failed cleanup. Local clearing cannot guarantee erasure of
managed temporaries, caller aliases or copies inside the cryptographic library.
PC/SC release leaves the card powered: clearing host keys is not PICC logout.
The next operation's explicit selection establishes a new context; the caller
owns disconnect/RF-deactivation policy when sharing a powered card connection.

## Verified writing

`WriteData` supports existing **standard** data files with both read and write
rights. It copies input before acquisition, acquires settings, independently
reads the requested old range and rechecks settings before dispatch. Matching
bytes are a verified no-op. Otherwise it sends exactly one logical native write
(`3D` public/EV1 or `8D` EV2), verifies its acknowledgement/MAC as required, reads
back the exact range and compares every byte before a final settings check/release.
It sends only the requested range; no whole-file preservation claim is inferred
from transport success.

After the first write invocation, any status, framing, MAC, comparison, later
command or release failure raises `EContactlessWriteUncertain`. Errors retain
only the original exception class, never keys or payloads. A chained update is
not atomic and may have written a partial range. No write/read fallback, replay,
rollback, backup commit/abort, credit/debit, record append or administrative
command is sent. Backup transactions need explicit ownership of pending card
changes; a standard-data API cannot safely commit unknown application state.

## Retained transactions and management

`Reader.OpenSession(Aid, Access)` returns an owned `IDesfireSession`. It copies the
component's credentials/configuration and retains its transport/provider references.
The component can then be destroyed or configured independently; its `Busy` property
describes its own one-shot operations. The session holds its own exclusive transport
transaction, so a second operation on that physical transport cannot nest. Use all
session operations and release its final interface reference on the opening thread.
Do not insert raw transport commands or externally mutate the selected application.
Reentrant calls and wrong-thread operations fail before card I/O.

Authority is explicit, without a default:

| Access | Authority and ownership contract |
| --- | --- |
| `dsaReadOnly` | Retained directory/settings/data/value/record reads; cannot mutate, commit or abort |
| `dsaManage` | Immediate application/file create/delete only; no backup transaction ownership |
| `dsaFreshTransaction` | Caller attests a fresh reset/RF activation under exclusive ownership with no prior pending application changes; the library does not infer this from transport acquisition or send a hidden reset |
| `dsaDiscardPending` | Explicitly discards earlier pending application changes through one verified `AbortTransaction` before staging; requires a normal successful response, including its MAC for AES |

Owned sessions preflight the complete ordinary file directory before any discard or
transaction write. Transaction-MAC/extended files are refused before mutation because
this transaction profile does not handle their receipt or commit rules. A bare `910C`
NoChanges response is a native error, not an authenticated clean-state proof: the
session is released and cannot continue or restart authentication automatically.
Choose the fresh-state policy only when the caller can meet its stated contract.

```pascal
Session := Reader.OpenSession(NativeAid, dsaFreshTransaction);
try
  Session.WriteBackup(BackupNumber, Offset, SuppliedBytes);
  Session.Credit(ValueNumber, CreditAmount);
  Session.Debit(ValueNumber, DebitAmount);
  Session.LimitedCredit(ValueNumber, LimitedAmount);
  Session.AppendRecord(RecordNumber, CompleteRecord);
  Session.Commit;
  // Success requires Outcome=dsoCommitted AND VerificationSucceeded=True.
finally
  Session := nil;
end;
```

Here `Session` is `IDesfireSession`; amounts/offset are `Integer`, native file numbers
are `Byte` and supplied bytes/record are `TBytes`. File IDs, amounts, keys and clean-state
attestation are supplied by the application owner. Each changed backup file is captured
in full; value snapshots are signed four-byte values; record snapshots retain native
newest-first order. Overlapping backup ranges compose against the journal. A matching
staged range and clearing an already empty journal are no-op mutations. Credit requires
ReadWrite access; debit/GetValue permit Read, Write or ReadWrite; limited credit requires
Write or ReadWrite, the acquired enable flag/allowance and at most one use per touched
file. Signed arithmetic uses a wider intermediate and acquired lower/upper limits.
Complete linear records fail when full; cyclic writes evict the oldest expected record.

Snapshot, staged-growth and aggregate expected bytes must fit the copied
`MaxTransferBytes` (64 KiB by default). This can reject a small range update of a larger
backup file: full-file preservation verification requires its complete snapshot.
At most 256 mutations are dispatched per session; reaching that bound still permits
explicit Commit or Abort. Staging acknowledgements do not claim that pending data is
visible through reads before commit. Commit sends one `C7` (EV2 option `00`, EV1/public
no option), checks its acknowledgement, reacquires settings and verifies **all touched
contents**, including unchanged backup bytes, signed values and record count/order.
Clear/append/eviction are checked against the same owned journal. No TMAC receipt is
requested or fabricated.

| Outcome | Evidence |
| --- | --- |
| `dsoActive` | Session remains acquired; acknowledged staging may be pending |
| `dsoCommitted` | Commit acknowledgement passed integrity checks; `VerificationSucceeded` is true only after all post-commit checks and release succeed |
| `dsoAborted` | Abort acknowledgement was verified, or an owned session had no staged changes |
| `dsoClosed` | Session released with no unresolved mutation |
| `dsoUncertain` | A mutation may have executed, its result is unknown, or pending changes were abandoned |

If the commit acknowledgement is lost, outcome is Uncertain. If it was verified but
read-back or release fails, outcome stays Committed with VerificationSucceeded=False.
A verified abort likewise retains Aborted if release fails. Mutation/integrity/verification
failures raise `EContactlessWriteUncertain` carrying only the originating exception
class. `PendingChanges` describes acknowledged unresolved staging; false does **not**
prove that a failed first write never reached the card. Inspect Outcome as well.
Local argument/authority errors before I/O preserve an active session; failures after
card I/O close it, since the secure-message state can no longer be assumed usable.
Close/destruction sends neither commit nor abort, never replays a mutation and never
resets the card. Explicitly closing pending changes records Uncertain; any later card
recovery belongs to a separate owner-directed operation.

Management sessions expose `ReadApplicationIds` at PICC level, and protected
`ReadApplicationSettings`/`ReadFiles` in their appropriate context. `CreateApplication`
requires PICC selection, key 0 or acquired free-create/delete permission and an explicit
nonzero AID/settings/AES key count (1..14). Native card creation initializes card-default
keys; this API never authenticates with a guessed default or changes those keys.
`DeleteApplication` is PICC-level only. `TDesfireFileDefinition` specifies all ordinary
file geometry, communication and access nibbles; unused fields must be zero.
`CreateFile` verifies acquired settings; a value's initial amount is acknowledged input,
not a fabricated GetValue result when read access is unavailable. `DeleteFile` preflights ordinary settings and verifies
directory absence. Administrative create/delete effects are immediate: Abort cannot
undo them, and a later failure cannot roll back earlier successful commands.
Authentication-gated directory access is MACed under EV2; EV1 advances its chained
command CMAC without appending a command tag and verifies the response CMAC.
DESFire Light is pre-provisioned; sharing its AES dialect does not imply that it accepts
application/file administration. Formatting remains separate; ISO creation is available through the optional file-management interface. AES key sets, explicit configuration and SDM are described in [extended management](DESFIRE_EXTENDED.md).

## Example and validation

```text
ManageDesfire --help
ManageDesfire --plan
InspectDesfire --help
InspectDesfire --settings-hex 00031234332211 --file 0
InspectDesfire --reader "Exact compatible reader name" --aid CDEF01
InspectDesfire --reader "Exact compatible reader name" --aid CDEF01 --ev2-key-file "owned-test-key.bin" --key-number 0 --minimum full
InspectDesfire --reader "Exact compatible reader name" --aid CDEF01 --ev1-key-file "owned-test-key.bin" --key-number 0 --minimum full
```

The example reads metadata, accepts an explicitly supplied exact 16-byte raw key
file for EV1 or EV2 and prints no key, UID or payload. Offline inspection needs no reader.
Its help and valid/truncated settings modes are smoke-tested without hardware.
`ManageDesfire` adds explicit administration and transactional actions. `--plan` shows
five demo file definitions without opening hardware. Hardware mode uses an exclusive
Windows PC/SC connection, supplied raw AES key and explicit authority. `--ownership
fresh-reset` attests caller-established fresh state; `discard-pending` authorizes discarding
earlier pending changes. Create/delete actions require `manage`. The demo creates
Full-mode key-0 files; update/clear actions operate on that explicit layout. Destructive
management actions are never executed by the smoke-test runner.

Tests combine NIST AES-CBC/CMAC vectors, NXP authentication/session-key/Full-message
vectors and 52 original plus 51 retained-session independently generated transcripts. The optional fixture
generator uses Python `cryptography`; neither runtime nor test runner needs it.
The transcripts cover both AES generations, EV2 NonFirst with distinct second
credentials/nonces and nonzero retained counter, all three communication modes,
public writes, backup/value/record reads, authenticated settings and both continuation
directions. EV1 cases cross CRC/AES block boundaries and use valid encrypted
responses containing deliberately invalid CRC/padding, plus optional marker padding.
EV1 and NonFirst authentication lengths 0..40 are checked against exact contracts.
Every transport boundary and every bit in protected responses is injected as a
failure; replay, downgrade, wrong rights, missing credentials, failed RNG, release
errors, no-op writes and independent buffers are checked. The same suites run
through real OpenSSL and the actual CNG adapter linked to an OpenSSL-based Linux
ABI shim, plus native-call failure/length/IV-mutation/handle-cleanup tests.
Retained-session tests additionally cover full-file backup preservation and overlapping
no-ops, signed credit/debit/limited credit, their distinct access routes, linear/cyclic
ordering/eviction/clearing, authenticated directories, all ordinary create/delete forms,
PICC AES application management, every transaction/administration I/O boundary,
every bit of protected EV1/EV2 transaction responses, valid-integrity wrong committed
contents, clean-state authority, TMAC preflight, signed overflow, mutation quota,
wrong-thread/reentrancy, component lifetime and known commit/abort evidence.
These prove tested protocol/buffer behavior, not real Windows ABI/policy or card
compatibility. See [VALIDATION.md](VALIDATION.md).

## AES key and access administration

`OpenManagementSession(Aid)` returns the new derived `IDesfireManagement`; the
existing `IDesfireSession` IID and method layout are unchanged. It provides native
PICC free-memory (`6E`) and existing-key version (`64`) reads, `ChangeKeySettings`
(`54`), `ChangeFileAccess` (`5F`) and `ChangeAesKey` (`C4`). The session retains the
transport/provider independently of the creating component. A queried management
view on a read-only/transactional session still refuses these mutations before I/O.
Mutations require an explicit AES management session, with no NonFirst credential
configured. They take **immediate effect** and cannot be rolled back by Abort.

Key policy changes require acquired configuration-change permission and auth key
zero. File access changes require the old ChangeAccessRights key/free route, acquired
valid target key numbers (or E free/F never), and an ordinary strict file layout.
The complete post-change settings must preserve geometry and every untouched byte.
EV1 free-rights changes use Plain command/CMAC response semantics; other EV1 changes
and EV2 changes use Full. ReadFreeMemory requires PICC context; key numbers/versions
are acquired metadata, never evidence of possession on their own.

AES rotation retains the key type and changes an existing 0..13 key only. The owner
supplies 16 new bytes and an explicit version. Another target also needs 16 current
old bytes, XORed into the native body; the authenticated target requires an empty
old-key argument. Acquired master-key/change-key policy and key count gate dispatch.
PICC AES uses native key-number type bit 80; application key numbers do not.
EV1 includes native command CRC32 and, for another key, the separate new-key CRC;
EV2 uses its Full-message frame and separate new-key CRC for another target.

A current-key change can return a bare successful status because the old session
has been invalidated. **Success requires fresh mutual authentication with the new
key and an acquired matching new version**, including for another target. This is
explicit post-write verification, not recovery or replay of ChangeKey. The retained
session subsequently uses that new target; the source component's initial credentials
remain unchanged. Save/provision credentials in the application's own policy.
Any dispatch, acknowledgement, entropy, reauthentication or version failure before
verification leaves the session uncertain, closes/releases it once and never repeats
the change. A later Close/release error propagates separately: the session is closed
and the already verified changes remain proven. The example reports that retained
outcome alongside the exception, without rolling back or retrying.

```pascal
Management := Reader.OpenManagementSession(NativeAid);
try
  Management.ChangeAesKey(TargetKeyNumber, NewVersion, NewKey, OldKeyOrEmpty);
  // The management session is now authenticated with the new target key.
  Management.Close;
finally
  Management := nil;
end;
```

Declare Management as `IDesfireManagement`, target/version as `Byte`, NativeAid as
`Cardinal` and keys as `TBytes`. All secrets are caller-provisioned, never defaults.
Use `ChangeFileAccess(FileId, dfcFull, ReadKey, WriteKey, ReadWriteKey, ChangeKey)`
only with the actual intended policy; setting ChangeKey F or disabling policy bits
may permanently prevent later changes under the current configuration.

`AdminDesfire --help` documents explicit version/free-memory/settings/access/rotation
arguments; `--plan` opens no hardware. Hardware mode uses exclusive Windows PC/SC
and exact raw key files; secrets never appear in output. The runner only exercises
offline modes. The new independent generator supplies 26 literal EV1/EV2 admin
transcripts, including current/other/PICC rotation, both current-key acknowledgement
forms, valid-integrity wrong versions/settings/geometry and denied policies.
Fault tests check all admin I/O boundaries, all protected-response bits, mutated
fresh-auth challenges, lost replies, RNG/release failures and no replay. The suite
also executes through the actual CNG adapter with the Linux ABI shim.

## Sources

Protocol facts were independently implemented; no PDF or external implementation
is redistributed or linked into this library:

- [NXP AN11004 Rev 2.4](https://www.nxp.com/docs/en/application-note/AN11004.pdf),
  native ISO wrapping, public file conditions and version examples.
  SHA-256 `8c3b4f6b905b95d9205dc53a1f460a27848a5041a62367b053ac893a9ae9d6ba`.
- [NXP AN12343 Rev 1.1](https://www.nxp.com/docs/en/application-note/AN12343.pdf),
  sections 6/7.1/8, Tables 10/15/16/21–26/32/33/35–37: AES EV2 authentication, KDF, communication
  and independently transcribed known-answer vectors. SHA-256
  `df0e07ac422c37290fbe795a6ae496ff109998c5679ffd58411fce16735789f6`.
- [NXP DESFire EV2 short data sheet Rev 3.2](https://www.nxp.com/docs/en/data-sheet/MF3DX2_MF3DHX2_SDS.pdf),
  distinct D40/EV1/EV2 crypto modes and ordinary file families. SHA-256
  `6b383984b3c5fd45e12e575edf54dc0f267062292296e2cdb127d9ea16df6802`.
- [libfreefare native protocol reference](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire.c)
  and its [public file/access layout](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/freefare.h).
  Protocol-only corroboration; source/headers are not copied or bundled.
- [libfreefare EV1 crypto framing](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_crypto.c)
  and [session-key layout](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_key.c),
  protocol facts for chained IV/CMAC, CRC, command/response modes and AES nonce layout.
  SHA-256 respectively `99aee3a26df78221612f4b0ac66aaca138b665b35b751b1db4f07b888f4e9d38`
  and `3bcebcda1f891f97b319f38f1d40912e3a4a206323b5efde0c828fba8fd669c7`.
  Implementation was independently authored; these files are not included or linked.
- [Independent EV2 authenticated-settings reference](https://github.com/MichaelsPlayground/TalkToYourDESFireCard/blob/8b8bf1d3c3661296fe369887ee304c8290509796/app/src/main/java/de/androidcrypto/talktoyourdesfirecard/DesfireEv3.java),
  `getFileSettingsMac` and `authenticateAesEv2NonFirst` wire format/counter/response semantics only. No implementation
  or logging patterns are imported. SHA-256
  `24bd621945872118819edf010e5250ef46285a3b53d2bca44c833fd3f95b788a`.
- [Proxmark3 native commands](https://github.com/RfidResearchGroup/proxmark3/blob/a48ce253f73a82a603da11bf3003864c65155a77/client/src/mifare/desfirecore.c)
  and [secure-channel command modes](https://github.com/RfidResearchGroup/proxmark3/blob/a48ce253f73a82a603da11bf3003864c65155a77/client/src/mifare/desfiresecurechan.c),
  protocol corroboration for AES directory/admin/commit/abort framing and distinct
  EV1/EV2 command policies. SHA-256 respectively
  `ff2df3680399aa5c13ade89845ed2bed65666a9429e5d01264712d791d40c3f7`
  and `0a25b22ce45178b81deb7351f83bee0c22e7b24fd272c70bba261f8e2ed0e44d`. No external implementation is copied or linked.
- [NIST SP 800-38A](https://csrc.nist.gov/pubs/sp/800/38/a/final) and
  [SP 800-38B](https://csrc.nist.gov/pubs/sp/800/38/b/upd1/final), published AES-CBC/CMAC vectors.
- [Microsoft CNG functions](https://learn.microsoft.com/en-us/windows/win32/seccng/cng-functions)
  and [OpenSSL EVP](https://docs.openssl.org/3.5/man3/EVP_EncryptInit/).

Next security/access additions are
Automatic LRP retained sessions and further generation-specific/combined-data extensions, additional
configuration, originality and hardware profiles. ISO/multi-access/AES TMAC and record updates are documented separately; native LRP codecs are available in [DESFIRE_LRP.md](DESFIRE_LRP.md). Basic AES key policy,
rotation and ordinary access administration are implemented. Broad support is built per implemented/tested operation, never inferred
from one successful AES session or PC/SC connection.

## Explicit application key storage

`OpenApplicationManagementSession` returns the new optional
`IDesfireApplicationManagement` extension without changing existing interface
IIDs. `CreateApplicationWithKeyType` selects DES/2K3DES, 3K3DES or AES storage
independently of PICC authentication. Existing `CreateApplication` retains its AES
behavior. Native create/delete operations and metadata reads now have independent
DES/3DES transcripts and every I/O failure boundary. See
[DESFIRE_APPLICATIONS.md](DESFIRE_APPLICATIONS.md) for the exact contract and demo.

## DES/3DES key administration

The four explicit DES/3DES profiles now support key policy and ordinary-file access
updates through `IDesfireManagement`. `OpenDesManagementSession` exposes the new
optional `IDesfireDesManagement` interface for same-type key replacement. It checks
acquired policy, secures the native ChangeKey command and verifies fresh mutual
authentication plus the new key version. Existing interface IIDs remain unchanged.
See [legacy MIFARE security](LEGACY_MIFARE_SECURITY.md) for stored version-bit
requirements, protocol differences and the dedicated DFM controls.

## EV2 extended management

`OpenExtendedManagementSession` exposes `IDesfireExtendedManagement` without changing existing interface IIDs. See [DESFIRE_EXTENDED.md](DESFIRE_EXTENDED.md) for AES key sets, acknowledged configuration, verified SDM settings and offline SDM verification/decryption. Ordinary file parsing continues to reject extended layouts; callers select the matching API explicitly.

## Native ISO, multi-access and AES TMAC

`OpenFileManagementSession` exposes native ISO identifiers/creation, additional rights and TMAC file management. `OpenTransactionMacSession` explicitly owns an AES TMAC transaction, verifies real UID, captures canonical plaintext input and checks the counter/static-key receipt before journal/release proof. Existing ordinary transaction sessions retain their strict TMAC rejection. See [DESFIRE_FILES_TMAC.md](DESFIRE_FILES_TMAC.md) for exact ownership, communication and profile contracts.
