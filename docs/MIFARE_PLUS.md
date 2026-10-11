# MIFARE Plus SL3

`TMifarePlusCardReaderWriter` implements native AES access to explicitly selected
Plus 2K/4K cards already operating in Security Level 3. It is registered on the
ERD Contactless palette and starts inactive.

| Operation | Behavior |
| --- | --- |
| `ReadUid` | Fresh acquisition and successful release, without authentication |
| `ReadBlocks` | Fresh mutual AES authentication; 1–15 ordinary blocks in one sector; response MAC checked before decrypting |
| `WriteBlockVerified` | Fresh authentication, exact sixteen-byte prior-state comparison, one write, protected acknowledgement and read-back proof |
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

## Scope and validation

SL0/SL1/SL2 transitions, personalization, key replacement, value commands,
manufacturer/trailer programming and Plus EV2 LRP negotiation are not implemented
by this profile. Ordinary-content copying does not copy a card's keys or security state.

Literal independently generated transcripts cover both messaging modes, full
sixteen-bit counters, 4K high sectors, authentication, writes, reader acquisition,
workflow restoration and failures at every exchange boundary. See
[validation](VALIDATION.md). Protocol references include
[liblogicalaccess](https://github.com/liblogicalaccess/liblogicalaccess/tree/5a23140333ffc0c5dd60b2af4dcee3a435c82b29/plugins/logicalaccess/plugins/cards/mifareplus)
and [Proxmark3](https://github.com/RfidResearchGroup/proxmark3/blob/a48ce253f73a82a603da11bf3003864c65155a77/client/src/mifare/mifare4.c).
No source from those projects is compiled into the library.
