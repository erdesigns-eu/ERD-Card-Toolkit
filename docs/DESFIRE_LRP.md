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

## Component integration boundary

`TDesfireCardReader` does not yet select an automatic LRP transport session.
The new codec is directly usable with a caller-managed `ICardTransport`, but it
must not be advertised as automatic LRP card-reader, management, TMAC or
originality support. Those retained-session profiles remain on the protocol plan.
Existing EV1/EV2 profiles do not negotiate LRP implicitly. The implementation
uses a maintained AES backend and makes no certified side-channel claim.

## Validation

All 150 published AN12304 vectors are retained in
[lrp-nxp.json](../tests/contactless/fixtures/lrp-nxp.json) and checked by a separate
Python implementation. Pascal tests execute evaluation, MAC and nonwrapping
LRICB encryption/decryption known answers, and explicitly reject counter overflow.
Independent native transcripts cover first/NonFirst authentication and all three
communication modes, valid-MAC wrong capability/padding/length, every protected
response bit, every AES-provider call boundary and unchanged counters on failure.
See [VALIDATION.md](VALIDATION.md).
