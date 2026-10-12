# Native DESFire LRP codec

`TDesfireLrpCodec` in `ERD.Card.Contactless.DESFire.LRP` implements the explicit
m=4 LRP profile from [NXP AN12304 Rev. 1.1](https://www.nxp.com/docs/en/application-note/AN12304.pdf)
and the authentication/secure-message rules of
[MF2DLHX0 Rev. 3.3 section 9.2](https://www.nxp.com/docs/en/data-sheet/MF2DLHX0.pdf).
The runtime contactless and standalone design packages include the unit. It needs
an `ICardAesProvider`; no additional native DLL is introduced.

## API coverage

| API | Result |
| --- | --- |
| `Evaluate` | m=4 secret-plaintext/updated-key generation, exact nibble evaluation and optional final whitening |
| `Cmac` | Complete LRP-CMAC, including empty and block-aligned messages |
| `Crypt` | LRICB encrypt/decrypt, raw blocks or strict ISO method-two padding, explicit updated key and fixed-width big-endian counter |
| `FirstCommand`, `FirstChallenge` | Explicit native first-authentication request and checked mode/card-nonce framing |
| `DeriveSessionKey`, `ReaderResponse` | Native LRP session-master derivation and complete reader nonce MAC |
| `VerifyFirstResponse` | Complete PICC nonce/ciphertext MAC, TI decryption and exact capability echo |
| `VerifyNonFirstResponse` | Complete NonFirst nonce MAC, without resetting TI or command counter |
| `EncodeCommand`, `DecodeResponse` | Plain/MAC/Full command/response framing, ciphertext MAC verification before decryption, odd-index truncation, exact lengths and padding |

Updated key zero is used for MAC, updated key one for session encryption. The
session derivation vector is `00010080 || RndA[0:2] || (RndA[2:8] xor RndB[0:6]) ||
RndB[6:16] || RndA[8:16] || 9669`, with slices in normal wire byte order. This
produces one session master rather than the two independent EV2 AES session keys.

First authentication explicitly requests the six-byte capability vector with
first byte `02`. The card's native **AuthMode is `01`**, following command table 35;
it is a different field from the requested capability bit. An AES-mode answer,
wrong length or extra bytes is refused rather than retried under another profile.
First response MAC covers `RndB || RndA || encrypted TI/capabilities`. The complete
six-byte PCD echo must match. NonFirst verifies `RndB || RndA` without a TI echo.
The caller supplies fresh CSPRNG reader nonces; no nonce/default-key fallback exists.

## Caller-owned session lifecycle

The codec performs **no card I/O**. A caller-managed transport must:

1. Acquire the card exclusively and select the exact application.
2. Dispatch native `71` with `FirstCommand`, require `91AF` and parse
   `FirstChallenge`; generate a fresh sixteen-byte reader nonce.
3. Derive the master, send `ReaderResponse` under native `AF`, require `9100` and
   verify the complete first response before trusting TI/capabilities.
4. Start command counter at zero and the four-byte encryption counter at
   `00000001`. NonFirst uses native `77`, retains TI/command counter and resets
   the encryption counter to `00000000` only after full authentication proof.
5. Construct command data, handle native outbound/inbound chaining, and decode
   only a complete successful response with command counter incremented once.
6. Invalidate the session after dispatch/status/MAC/padding/transport failure;
   never retry with reused counters. Clear owned master/nonces/plaintext on exit.

Command counters are sixteen-bit **little-endian** in MAC input. Encryption
counters are thirty-two-bit **big-endian** in this protocol and advance per
LRICB block, including the padding block. They cannot wrap. Generic `Crypt`
also supports caller-selected one-through-sixteen-byte counters, but refuses
an operation whose next counter would overflow. This includes the wrapping
counter test case published for the generic AN12304 algorithm.

Counter buffers are exclusively owned mutable inputs. Provider/MAC/padding/length
failure preserves their bytes; output and advancement are released only on
complete codec success. Successful command construction advances the encryption
counter before transport dispatch; failed dispatch requires invalidation, not a
counter rollback. Temporary owned key material is cleared. Plain communication
carries no response MAC; returned Plain bytes do not establish channel authenticity.

## Automatic reader sessions

Set `TDesfireCardReader.Security := dfsLrp`, supply an `ICardAesProvider`, exact
application key/number and `ICardTransport`. The reader acquires/selects the
nonzero application, runs explicit native LRP First authentication, verifies TI
and capabilities, and owns both counters through data operations and release.
No AES fallback or persistent card-mode configuration is performed. The card must
support the explicitly requested LRP profile. Existing security enum ordinals are
unchanged; the new value is appended.

The profile supports ordinary standard/backup/value/record reads and verified
standard writes in Plain/MAC/Full communication. `MinimumCommunication` retains
its explicit policy; Plain file data requires selecting Plain as the minimum.
Metadata remains LRP-MAC protected. Native AD/8D/AB/8B/BA commands are selected
with ordinary owned transaction, journal, commit/abort and read-back semantics.
`OpenRecordUpdateSession` supports the same sixteen-byte cyclic-record profile
under LRP, including outbound additional frames.

`ReauthenticationKey` and `ReauthenticationKeyNumber` enable one explicit LRP
NonFirst transition before data access. It verifies fresh nonce MACs, retains TI
and command counter, and resets only the encryption counter. Wrong modes,
capabilities/nonces, provider/CSPRNG failures, counters, statuses, protected data
or transport/release errors fail the acquired operation. A mutation dispatch
retains `EContactlessWriteUncertain`; no failed session is reused or retried.
Temporary session master/counter state is cleared on success, failure and closure.
Configured component authentication credentials remain caller-controlled, as in
the existing reader profiles.

`ReadCardUid(Aid)` acquires the protected real seven-byte UID and releases the
session before returning it; it supports EV2 AES and LRP. This can be used when
an application's transport identity is a random RF ID rather than the real UID.
`ReadLrpTransactionMacRecord(Aid, File)` acquires the stored counter/tag under
unchanged metadata without requiring the static TMAC key or creating a new
receipt. `SessionProtected` follows the acquired communication mode and
`KeyVerified` stays false. Plain acquisition requires an explicitly Plain minimum.
The stored session subpart describes the prior committed receipt, not the current
hidden counter; backend trust/freshness policy remains explicit.

PICC-level LRP originality authentication and provisioning beyond the explicit
Light application management below remain separate profiles. Public unauthenticated GetVersion remains
available. The automatic profile does not infer a card generation or enable LRP
permanently on an AES-only card. Low-level codec use with caller-managed transports
remains supported. AES comes from the maintained backend; no certified side-channel
claim is made for this implementation.

## Native DESFire Light management

`OpenLrpLightManagementSession(Aid)` selects an explicit **DESFire Light**
application with `Security = dfsLrp`, a nonzero AID, key number zero and a supplied
sixteen-byte master key. It does not autodetect the family or send
`GetKeySettings`, which Light does not support. Existing AES administration and
all previous interface layouts remain unchanged.

`ChangeLrpLightKey(Number, Version, NewKey, OldKey)` supports Light application
keys **0 through 4**. Master-key replacement requires an empty old-key argument;
other keys require sixteen explicit old bytes. Native C4 uses LRP Full messaging,
new-key XOR old-key and CRC32 for keys 1..4. A bare acknowledgement when replacing
key zero is followed by fresh mutual LRP authentication with the supplied new key
and a protected native GetKeyVersion. No success is returned on a version mismatch.
The session then uses the new target key; the component's configured credentials
are unchanged. Reopen with master key zero for subsequent administration after
rotating another key. No key-set, key-type or original-card key is inferred.

`ConfigureLrpLightAcknowledged(Option, Data, True)` requires explicit acknowledgement
of persistent effects. Native 5C is protected in LRP Full mode; RFU bits, exact
lengths, identifier geometry, signed limits and LRP ATS timing are validated before
dispatch, independently of general EV2 configuration rules.

| Option | Validated Light data |
| --- | --- |
| `00` | Random-ID configuration; legacy UID0 requires the enable bit |
| `02` | Complete 5..20-byte ATS, T0 75/77, TB1 81 for LRP and TC1 02 |
| `03` | Two explicit SAK bytes |
| `04` | Two-byte secure messaging configuration, only the documented bit 2 |
| `05` | Ten-byte capability configuration; RFU bytes/bits checked, LRP cannot be disabled |
| `06` | One-time DF-name/ISO-ID rename: 19 bytes with name length 1..16, zero padding and explicit valid ISO ID |
| `08` | One-time rename of one/two files, optionally with explicit valid ISO IDs |
| `09` | One-time value-file limits/current value/options |
| `0A` | Failed-authentication counter enable/limit/decrement; an enabled limit must be nonzero |
| `0B` | Standard/strong back-modulation selector |

Acceptance means a verified command acknowledgement, **not independent settings
readback**: Light provides no generic GetConfiguration command. One-time settings
may already be locked and their native errors propagate. After renaming, close the
session and select the new identifiers explicitly. Any failure after dispatch is
uncertain; no configuration replay, rollback or implicit commit/abort is attempted.
These APIs operate on an **already enabled LRP application** and do not silently
switch an AES card permanently to LRP.

The native layouts follow [NXP MF2DLHX0, revision 3.3](https://www.nxp.com/docs/en/data-sheet/MF2DLHX0.pdf),
sections 11.5.1 and 11.6.1. They are not advertised as generic EV2/EV3 provisioning.

## Owned LRP TMAC

`OpenLrpTransactionMacSession(Aid, File, Uid, Key, PreviousActCounter,
ExpectedSessionCounter, True)` returns `IDesfireLrpTransactionMacSession`.
Select `dfsLrp` first and explicitly attest fresh exclusive transaction state.
The supplied static transaction key and real UID are copied before I/O; protected
GetCardUID proves the acquired physical UID before data commands.

LRP TMC consists of two unsigned sixteen-bit fields on the wire:
`actTMC little-endian || sesTMC little-endian`. `TDesfireTmacRecord.Counter` retains
those exact four bytes as a cardinal: low sixteen bits are the commit counter,
high sixteen the internal-session counter. `PreviousActCounter` is the trusted
last accepted commit count and must be below FFFF. The receipt must contain
exactly that count plus one and a nonzero session count.

The hidden session counter can increase after abandoned/aborted calculations;
its previous stored value does not predict its current value. Choose explicitly:

- Supply a nonzero `ExpectedSessionCounter` to require that exact value. The
  inherited immediate `CommitReaderId` can decrypt with that expected value;
  static-key proof still completes with the verified receipt.
- Supply zero to acquire the session counter from the authenticated receipt and
  verify it independently with the transaction key. Use `CommitReaderIdDeferred`
  when ReaderID commitment is required. It sends one protected C8 and retains
  EncTMRI, without releasing an unverified previous ID.

`CommitTransactionMacVerified` checks the expected commit count, acquired or
expected session count, unchanged TMAC settings, required ReaderID commitment,
static-key receipt, all journaled file/range contents and ownership release.
Only complete success returns `SessionProtected` and `KeyVerified` true.
`ReadVerifiedPreviousReaderId` returns an independent previous-ID copy only after
that complete success. Receipt/journal/release failure leaves it unavailable.
Immediate ReaderID decryption with an unknown session count is refused before
C8 dispatch; no counter is guessed.

The key vector is `00010080 || nextActLE || resultingSesLE || UID7 || label`, with
label 5A for TMAC and A5 for ReaderID. LRP-CMAC derives the keys, but **ordinary
AES-CMAC** produces the transaction MAC and **ordinary AES-CBC with zero IV**
encrypts/decrypts EncTMRI, as specified in section 10.3.2. The live session's LRP
MAC independently protects C8/C7 responses. No extra session-encryption layer is
removed from EncTMRI.

Canonical TMI is shared with the existing aligned-record AES TMAC profile and
includes successful reads, writes and one complete C8 independently of native
chaining. Backup/value/record operations are staged; standard range writes are
immediate and survive Abort. TMAC metadata accepts exactly six bytes or eight
with an explicit unsigned sixteen-bit actTMC limit. A reached supplied prior count
is refused before data mutation. Card-enforced terminal counter/limit restrictions
may prevent post-commit read-back; this is reported as uncertain rather than
returning a verified result.

Owned TMAC key/UID/ciphertext inputs are cleared on completion/abort/failure.
A successfully verified previous-ID buffer remains in the result owner until it
is freed; returned copies belong to the caller. These native APIs do not change
ordinary application archive formats or add automatic LRP provisioning workflows.

## Validation

All 150 published AN12304 vectors are retained in
[lrp-nxp.json](../tests/contactless/fixtures/lrp-nxp.json) and checked by a separate
Python implementation. Pascal tests execute evaluation, MAC and nonwrapping
LRICB encryption/decryption known answers, and explicitly reject counter overflow.
Independent native transcripts cover first/NonFirst authentication and all three
communication modes, valid-MAC wrong capability/padding/length, every protected
response bit, every AES-provider call boundary and unchanged counters on failure.
Automatic reader tests add exclusive ownership, native command/chaining selection,
NonFirst TI/command-counter retention and ordinary owned transaction proof.
LRP TMAC tests add explicit/acquired counter modes, hidden counts 1/7/FFFF,
ReaderID deferral, valid-session-MAC wrong receipts/counters/postimages, key/UID
input freezing, every exchange boundary and cleanup/release faults.
Light management adds literal key-zero/one/four exchanges, bare master-key reset,
fresh authentication/version proof, valid-MAC wrong version, all ten configuration
options, every response-data bit and exchange boundary, persistent-acknowledgement
and exact local-input guards.
See [VALIDATION.md](VALIDATION.md).
