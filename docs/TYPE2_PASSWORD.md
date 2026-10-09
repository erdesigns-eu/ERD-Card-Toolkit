# Password-authenticated Type 2 memory

`TType2PasswordCardReader` in `ERD.Card.Contactless.Type2.Password` adds supplied-
password user-memory access for Ultralight EV1 48/128 and NTAG213/215/216. It is an
RTL-only nonvisual component included in `ERDCardContactless.dpk`; every visible
API declaration has English Delphi XML documentation.

This is an independently implemented protocol path tested with synthetic command
transcripts and the concrete ACR122U/PN532 adapter. Physical card/reader/firmware
compatibility, Delphi builds and RAD Studio Help Insight remain to be verified.
Original MF0ICU1 Ultralight has no PWD_AUTH and is rejected. Ultralight C, EV2/AES,
NTAG I2C and other authentication variants require separate profiles.

## API and reader setup

Assign a matching `IRawContactlessReader` that supports exact bit counts, manual
CRC-A, retained selection and exclusive sessions. The concrete `TAcr122RawReader`
uses the documented ACR122U/PN532 PICC direct-transmit dialect. PC/SC discovery
alone does not establish raw-RF support; other devices can supply their own backend.
See [the lifecycle and hardware boundary](RAW_UID.md).

```pascal
MemoryReader := TType2PasswordCardReader.Create(nil);
try
  MemoryReader.Reader := TAcr122RawReader.Create(ConnectedCard.Transport);
  Page := MemoryReader.ReadUserPage(
    ttmNtag213, 4, ApplicationPassword, ExpectedPack);
  Memory := MemoryReader.ReadUserMemory(
    ttmNtag213, ApplicationPassword, ExpectedPack);
finally
  MemoryReader.Free;
end;
```

Add `ERD.Card.Contactless.Type2`, `ERD.Card.Contactless.Type2.Password` and
`ERD.Card.Contactless.ACR122` to uses. Declare `MemoryReader: TType2PasswordCardReader`,
`Page, ApplicationPassword, ExpectedPack: TBytes`, and `Memory: TType2UserMemory`.
`ConnectedCard` is an already connected compatible `TSmartCardReader` whose owner
stays alive during use. Supply exactly four password bytes and two expected PACK
bytes in their configured card/wire order; no byte reversal or integer conversion
is applied. There is no default password or optional PACK comparison.

Every call is a separate session and authenticates exactly once. A standalone
Authenticate method is deliberately not provided: release clears the RF state.
The existing `TContactlessCardReader` PC/SC storage methods remain separate; reader
firmware may reset/select between its pseudo-APDUs, so this implementation does not
mix raw authentication with those page commands.

## Models and bounded user ranges

| Model | User pages, inclusive | Complete user bytes |
| --- | --- | --- |
| `ttmUltralightEv1_48` | 4..15 | 48 |
| `ttmUltralightEv1_128` | 4..35 | 128 |
| `ttmNtag213` | 4..39 | 144 |
| `ttmNtag215` | 4..129 | 504 |
| `ttmNtag216` | 4..225 | 888 |

`ReadUserPage` reads exactly four bytes using `FAST_READ 3A page page + CRC-A`.
`ReadUserMemory` reads ascending ranges of at most sixteen pages and a shorter
final range. Both start/end addresses remain within user memory, with exact expected
response size and CRC-A. Unlike a four-page READ near a boundary, no wraparound or
adjacent lock/configuration pages are requested. The component never infers a model
from UID, ATQA, ATR or version bytes; caller identification is required.

The stateless `TType2PasswordCodec` validates credential lengths/model and bounded
user ranges, and builds independent FAST_READ frames for tooling. It rejects zero,
negative, oversized, overflow-prone or excluded ranges before I/O. Every read/write
excludes manufacturer pages0..3 and each model's dynamic locks/configuration tail.
Passwords/PACK are not exposed by a user snapshot. Existing lock bits and card
access conditions still apply after authentication.

## One authentication attempt, retained RF state

Each operation:

1. Validates model, credentials, page/range and any write-data size before I/O.
2. Acquires one exclusive session and freshly selects a seven-byte UID, checking
   the cascade-tag position. Failed acquisition owns its own cleanup; a selection
   failure releases without sending any password.
3. Sends one plaintext `1B password4 + CRC-A` PWD_AUTH frame. It requires exactly
   two PACK bytes plus valid CRC-A as a full 32-bit RF response. A four-bit ACK/NAK,
   wrong length, timeout, transport failure or malformed CRC is not success.
4. Compares both PACK bytes with the required expected value. A mismatch ends the
   operation before any memory command. PACK is not a cryptographic authenticity
   check, and the password is not encrypted or secure messaging.
5. Performs the requested FAST_READ ranges or page write/read-back without RF
   reset, reauthentication, retries or fallback commands.
6. Returns only after successful session release. The ACR122U adapter restores
   temporary framing/registers, switches RF off and releases its transaction.

AUTHLIM can permanently block protected memory after unsuccessful verification
attempts. A timeout/transport failure does not establish whether the card consumed
an attempt. A successful PWD_AUTH can reset the internal failed-attempt counter;
enabled NTAG NFC counters can also change on reading. The component does not inspect
or alter AUTH0, PROT, AUTHLIM, CFGLCK, mirror/counter settings or password/PACK pages.
It cannot report remaining attempts. The caller must supply known credentials and
reconcile a failed/ambiguous attempt before deciding whether to call again.

Every failure after PWD_AUTH dispatch raises `EType2AuthenticationError`, with only
`OriginalErrorClass`; the potentially sensitive backend message and response bytes
are not retained. It represents both a rejected and an unverified attempt. There
is no replay, key search, delivery-password fallback or cached authentication token.
Parameter, acquisition and selection failures before dispatch retain their original
type; memory/read/release errors after verified authentication are reported normally.

Local password-bearing payload/wire and PACK/response copies are overwritten on
all exits. Caller arrays are never modified. The concrete adapter also overwrites
its command/response copies. This is not secure-memory allocation and cannot control
external backend copies, logging, RF observation or reader firmware. The component
has no password/PACK fields. Configure/call on one thread without reentrancy and do
not move an active transaction between threads.

## One verified user-page write

```pascal
MemoryReader.WriteUserPage(
  ttmNtag213, 4, ApplicationPassword, ExpectedPack, ReplacementPage);
```

`ReplacementPage: TBytes` contains exactly four bytes. This explicitly changes that
page when executed; no command-line examples or tests access physical cards.
A page write can alter an existing NDEF message; there is no automatic formatting
or NDEF transaction. This API only changes ordinary user memory. Bounded NDEF
codecs and public PC/SC Type 2 NDEF transactions are now available separately in
[NDEF.md](NDEF.md); they do not inject page commands into a password-authenticated
raw session.

After the sole verified authentication, send one `A2 page data4 + CRC-A`, require
an exact four-bit ACK nibbleA, then FAST_READ that same page and compare all four
bytes. Successful return also requires successful release. There is no field cycle
or second authentication between the write and verification. Enabled mirror features
may affect reader-visible data; this is not a raw backing-EEPROM interpretation.

Every failure from A2 dispatch onward, including NAK, timeout, malformed ACK,
transport loss, mismatching/invalid read-back or release failure, is
`EContactlessWriteUncertain`. Only the original error class is retained; a primary
failure wins over cleanup. Authentication failures are separate and do not imply
a dispatched page write. The operation never returns partial success, rolls back,
replays or changes locks/configuration. Inspect actual page state before a retry.

## Validation and sources

Synthetic tests cover all five models and excluded page ranges, exact password/PACK
lengths, single-page FAST_READ, complete 48/128/144/504/888-byte snapshots, bounded
last chunks, one authentication per operation, PACK mismatches, partial framing,
CRC/NAK/timeouts, transport failures, buffer independence/wiping, failed acquisition,
selection and cleanup precedence. A complete authenticated write/read-back chain
passes through the concrete ACR122U/PN532 adapter and injected PC/SC transport.
Both FPC and Delphi test runners include the new test program; only FPC was executed
in this Linux environment. Results are recorded in [VALIDATION.md](VALIDATION.md).

Protocol facts checked on 2026-10-07 against official NXP documents. No third-party
implementation or standards PDF is bundled.

- [MF0ULX1 Ultralight EV1, rev3.3](https://www.nxp.com/docs/en/data-sheet/MF0ULX1.pdf),
  sections8.5.6/8.6 for configuration/PWD/PACK/AUTHLIM and sections10.3/10.4/10.8
  for FAST_READ, WRITE and PWD_AUTH.
  SHA-256 `53cc29c6c7d8d93b12ad11f9de9c2c1368ad537f56e363e29b8c1723504a07f8`.
- [NTAG213/215/216, rev3.2](https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf),
  sections8.5.7/8.8 and10.3/10.4/10.7 for configuration, retry-limit effects and
  exact command/response formats.
  SHA-256 `8c2a81e144d1123ee0a9c3ddd4876144fd11e299893032315c4a34fbbc6b2ed1`.
- [NXP PN532 user manual](https://www.nxp.com/docs/en/user-guide/141520.pdf)
  and [PN532/C1 datasheet](https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf),
  manual framing, bounded RF timeouts and register restoration; hashes in
  [RAW_UID.md](RAW_UID.md).

NTAG210/212 layouts and mirror/configuration rules are documented in [NTAG210_212.md](NTAG210_212.md).
