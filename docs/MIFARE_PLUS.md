# MIFARE Plus SL3

`TMifarePlusCardReaderWriter` implements native AES access to explicitly selected
Plus 2K/4K cards already operating in Security Level 3. It is registered on the
ERD Contactless palette and starts inactive.

| Operation | Behavior |
| --- | --- |
| `ReadUid` | Fresh acquisition and successful release, without authentication |
| `ReadBlocks` | Fresh mutual AES authentication; 1–15 ordinary blocks in one sector; response MAC checked before decrypting |
| `WriteBlockVerified` | Fresh authentication, exact sixteen-byte prior-state comparison, one write, protected acknowledgement and read-back proof |
| `RotateSectorKeyVerified` | Encrypted replacement authorized by the configured sector key, release and fresh same-card target-key authentication |
| `PersonalizeAndCommitSl3Verified` | Frozen explicit SL0 entries, one commit and fresh selected SL3 key/data proofs |
| `ReadValueBlock` / `WriteValueBlockVerified` | Signed value/address redundancy; preimage-checked ordinary secure write and read-back |
| MACed mode | Plain data, command and response MACs |
| Full mode (default) | AES-CBC data, command and response MACs |

Assign `Session`, a maintained AES/CSPRNG `CryptoProvider`, an explicit `Model`,
sector `KeyNumber` ($4000–$404F), and a supplied sixteen-byte AES `Key`.
`ExpectedUid` optionally pins a four/seven/ten-byte card identity before credentials
are transmitted. Key and UID setters copy their inputs; getters return copies.
Clear `Key` when finished. Components cannot change configuration while busy.

Block zero and sector trailers are excluded. For 4K cards, blocks 128–255 belong
to sixteen-block sectors; key addresses must match the selected sector. The model
and security level are not detected by trying different protocols or keys.

## Reader backends

`IMifarePlusSession` owns exclusive activation and release. Its `ExchangeNative`
returns complete **status-first Plus bytes**, without APDU status words, RF CRC or
ISO14443-4 PCB. This is a different contract from `ICardTransport`.

`CreateAcr122PlusSession(ConnectedTransport)` supplies a concrete ACR122U/PN532
backend through FF 00 direct transmit. The connected transport must implement
`ICardTransaction`; use a dedicated reader and one card in the field. The adapter
sets bounded PN532 timing and disables native retries, resets RF, freshly selects
one ISO14443-4 Type A card and validates its UID/ATS. Timing settings persist until
the reader resets. RF is turned off and the transaction released on completion.
Unsupported chaining/NAD responses are refused; commands are never replayed.

Typical assignments after connecting your PC/SC component are:

```pascal
Plus.Session := CreateAcr122PlusSession(Pcsc.Transport);
Plus.CryptoProvider := TCardWindowsAesProvider.Create;
Plus.Model := mpm4K;
Plus.Communication := mpcFull;
Plus.KeyNumber := $4002; // sector 1 key A
Plus.Key := SuppliedSectorKey;
Plus.ExpectedUid := ExpectedCardUid;
Data := Plus.ReadBlocks(4, 1);
Plus.WriteBlockVerified(4, Data, ReplacementBlock);
Plus.Key := nil;
```

Use your existing reader/card monitor events to schedule these blocking operations
on a worker. The component does not start a monitor or background worker itself.

## Application workflows

`CreatePlusWorkflowMemory(Session, Provider, Model, Keys, ExpectedUid)` supplies an
owned `ICardWorkflowMemory` backend for `TProtectedMemoryWorkflow` backup, copy,
compare and restore. `IPlusWorkflowKeys.GetKey` returns an independent temporary
AES key and the matching sector key number for each read/write direction. Temporary
keys are wiped after use. The application retains responsibility for its own key store.

The backend uses Full messaging and sixteen-byte units. Archives identify the
explicit `PLUS-SL3-ordinal` model; keys, block zero and trailers are excluded.
The supplied UID is checked, or the first acquisition pins identity. Restoration
checks acquired prior data before each write and verifies the result. Workflow
credential cleanup drops the key-provider reference and consumes the backend;
create a fresh backend for another execution.

A failure after a write was dispatched, including failed MAC/read-back or release,
raises `EContactlessWriteUncertain`. Acknowledgement loss must not trigger a retry.
Partial workflow results retain the existing engine's completed/uncertain evidence.

## Sector AES key replacement

`RotateSectorKeyVerified(TargetKey, NewKey, True)` uses the configured sector
key as authority to replace key A or B in that same sector. Native access policy
determines whether that key may perform the change. The target address is checked
against the selected 2K/4K model before activation. The command always encrypts
the new key, even when ordinary data communication is configured as MACed.

After protected acknowledgement, the old RF session is released. The acquired UID
is pinned and a fresh session authenticates with the replacement target key.
Successful release completes proof. Caller-configured key, key number, UID and
communication mode are restored; explicitly update your key store and component
configuration after success. The component does not overwrite application-owned
credentials. Callers clear their supplied replacement-key arrays after use.

A write or later proof/release failure raises `EContactlessWriteUncertain`.
Permission/authentication/profile failures before write dispatch are ordinary
errors. There is no retry or rollback. Authentication proves the new key, without
claiming independent read-back of secret key memory.

## SL0 personalization and commit

`PersonalizeAndCommitSl3Verified(Entries, True)` is an application-callable
personalization pipeline. It requires an explicit nonempty `ExpectedUid`, an
AES/CSPRNG provider and a card already in SL0 using ISO14443-4 activation whose
native CommitPerso results directly in SL3. The ACR122 backend never tries to
identify the level by writing to a card. There is no SL1/SL2 fallback.

Each `TMifarePlusPersonalizationEntry` contains an explicit sixteen-byte value and
native address. The entire ordered plan is copied and validated before I/O:

- Required supplied Card Master ($9000), Card Configuration ($9001) and L3 Switch
  ($9003) keys; no generated or default credentials.
- At least one supplied sector AES key; addresses must fit the explicit model.
- Optional ordinary data blocks, each with a supplied matching sector key in the plan.
- No duplicate addresses, block zero, trailers or unrecognized configuration addresses.

Include every additional sector key/data entry needed by your application. The
component verifies the selected entries; it does not infer or complete the rest
of a card's security policy. Keys belong to the caller and must be cleared after use.

WritePerso ($A8) is **plaintext** in SL0. Each native acknowledgement is counted;
no secret-memory read-back is invented. CommitPerso ($AA) is sent once, after all
selected writes are acknowledged. The session is released and SL3 is established
by fresh sector-key authentication. Every supplied sector/master/configuration
key then receives a fresh authentication proof, and every supplied ordinary data
block receives MAC-verified encrypted read-back. Every acquisition checks the
expected UID. Switch key $9003 remains acknowledgement-only.

The returned `TMifarePlusPersonalizationResult` contains only acknowledged-entry,
verified-key and verified-block counts plus `Sl3Verified`. It is returned only
after all selected proofs and releases succeed. Failures after the first WritePerso
dispatch raise `EContactlessWriteUncertain`, including failures during later fresh
sessions. There is no automatic resume, re-personalization, commit replay or
rollback of acknowledged steps. Application operators must inspect uncertain state
before choosing a subsequent operation.

## SL1 authentication and level transitions

`TMifarePlusLevelManager` is a separate inactive palette component for native SL1
AES authentication and explicit one-way transitions. Supply a maintained
`CryptoProvider`, required `ExpectedUid` and exclusive `RawReader` configured to
suppress automatic RATS. `CreateAcr122PlusLevelReader(ConnectedTransport)` supplies
that raw backend using the existing ACR122 manual-CRC implementation. It sets
bounded timing and no retries, checks full-byte CRC-A and restores saved framing,
turns RF off and restores PN532 parameter baseline on release.

| Method | Native key and evidence |
| --- | --- |
| `AuthenticateSl1` | $9004; native $76/$72 mutual AES nonce proof, no level mutation |
| `SwitchSl1ToSl2Acknowledged` | $9002; explicit acknowledgement, authenticated nonce proof and successful release; no independent SL2 sector proof |
| `SwitchSl1ToSl3Verified` | $9003; authenticated raw transition, then fresh same-UID SL3 AES authentication and encrypted MAC-verified data comparison |

The caller selects a card explicitly known to be SL1 and supplies valid provisioned
keys; the component does not infer levels or try keys. SL2 is a generation-specific
option and is not available on every Plus variant. Unsupported native commands
fail without fallback. The SL3 method requires an independent `Sl3Session`, proof
sector key number/key, ordinary proof block and exact sixteen-byte expected data.
Geometry, credentials and proof inputs are validated/frozen before transition I/O.
The two backends must refer to the same dedicated reader; acquisitions are sequential.

For an ACR122 reader:

```pascal
Levels.RawReader := CreateAcr122PlusLevelReader(Pcsc.Transport);
Levels.Sl3Session := CreateAcr122PlusSession(Pcsc.Transport);
Levels.CryptoProvider := TCardWindowsAesProvider.Create;
Levels.Model := mpm2K;
Levels.ExpectedUid := ExpectedCardUid;
Levels.SwitchSl1ToSl3Verified(SuppliedSwitchKey, $4000,
  SuppliedSectorKey, 2, KnownBlockData, True);
```

All keys remain caller-owned and must be cleared after use. Component-owned
temporary keys/nonces are wiped. `Busy` covers the complete transition and proof;
use the component on one worker thread. No monitor/thread starts implicitly.
Dispatch of the second authentication frame may perform the level change. Any
subsequent response, CRC, nonce, release or fresh SL3 proof failure raises
`EContactlessWriteUncertain`. The transition is never retried or rolled back.
`AuthenticateSl1` remains nonmutating and reports ordinary authentication/transport
errors. Successful SL2 acknowledgement is deliberately distinct from verified SL3.

## Signed value blocks

`TMifarePlusValueCodec` encodes/decodes the Classic-compatible sixteen-byte layout:
three copies of a signed little-endian 32-bit value, including its complement, and
four repeated/complemented logical address bytes. All redundancy is validated.
The logical address is retained and is independent of the physical block number.
`AddChecked` uses a wider intermediate and rejects signed overflow.

`ReadValueBlock` performs an authenticated ordinary block read before decoding.
`WriteValueBlockVerified(Block, ExpectedValue, NewValue, LogicalAddress)` constructs
the complete expected and new blocks, checks the acquired exact preimage and
verifies read-back. Equal values produce no write. For example, encode an expected
-42 at logical address 2 and explicitly replace it with 100; negative values and
both signed endpoints are supported.

These writes require ordinary native block-write permission. They do not implement
or substitute for native increment/decrement/restore/transfer commands granted by
different access conditions. Use explicit expected values and preserved logical
addresses; do not calculate updates from stale cached data.

## Scope and validation

SL2→SL3 transitions, SL2 sector data sessions, native increment/decrement/restore/transfer
commands, manufacturer/trailer/configuration programming and Plus EV2 LRP
negotiation are not implemented by these profiles.
SL0 personalization/commit applies only to an explicitly selected ISO14443-4
profile whose native commit results directly in SL3. Ordinary-content copying does not copy a card's keys or security state.

Literal independently generated transcripts cover both messaging modes, full
sixteen-bit counters, 4K high sectors, authentication, writes, reader acquisition,
workflow restoration and failures at every exchange boundary. See
[validation](VALIDATION.md). Protocol references include
[liblogicalaccess](https://github.com/liblogicalaccess/liblogicalaccess/tree/5a23140333ffc0c5dd60b2af4dcee3a435c82b29/plugins/logicalaccess/plugins/cards/mifareplus)
and [Proxmark3](https://github.com/RfidResearchGroup/proxmark3/blob/a48ce253f73a82a603da11bf3003864c65155a77/client/src/mifare/mifare4.c).
No source from those projects is compiled into the library.
