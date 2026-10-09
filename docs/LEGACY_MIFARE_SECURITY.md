# Ultralight C and DESFire DES/3DES

These are explicit supplied-key profiles. They discover no keys and do not try
alternate authentication dialects after failure. Keys are copied into local owned
buffers and cleared on completion; examples start with empty credential fields.
Existing AES interface identifiers and security enum ordinals remain unchanged.

## Ultralight C

`TUltralightCCardReaderWriter` uses `IRawContactlessReader` and
`ICardDesProvider`. `TAcr122RawReader` supplies raw Type A RF through a connected
ACR122U-compatible PC/SC transport. It is not a generic storage-card pseudo-APDU
profile or a password/PACK profile.

| Method | Result |
| --- | --- |
| `ReadUserPage(Page, Key)` | Exactly four bytes from physical user page 4–39 |
| `ReadUserMemory(Key)` | All 144 user bytes, pages 4–39 in order |
| `WriteUserPageVerified(Page, Data, Key)` | Four independently read-back bytes after ACK and successful RF-session release |

Authentication uses a supplied 16-byte K1/K2 key in cryptographic byte order,
a fresh eight-byte system nonce, `1A 00` / `AF` frames with CRC-A and mutual nonce
verification. A single exclusive RF session retains authentication until readback
and release. Memory commands remain plaintext after authentication; Ultralight C
does not encrypt those memory exchanges.

The component excludes manufacturer/static locks/OTP (pages 0–3) and dynamic
locks, counter, authentication configuration and key storage (pages 40–47).
READs at the user-region tail start at page 36, avoiding the configuration pages.
Card lock/access policy still applies. Configuration and key changes are not
implemented. No operation retries authentication or a write. After write dispatch,
failed ACK, readback, integrity or release raises `EContactlessWriteUncertain`.

Use `examples/vcl/ultralightc/UltralightCDemo.dproj`: it owns its own editable
form/DFM, reader combobox, presence label and three operation pages. Enter a key
and explicitly acknowledge the authentication attempt or write.

## DESFire profiles

Set `TDesfireCardReader.Security` deliberately and supply `AuthenticationKey`,
`KeyNumber`, `Transport` and a `CryptoProvider` supporting `ICardDesProvider`.
Card generation/version and ATR do not select a security dialect.

| Security | Key bytes | Authentication | Messaging |
| --- | --- | --- | --- |
| `dfsEv1TwoKey3Des` | 16 | ISO `1A`, eight-byte nonces | Chained eight-byte CMAC, CRC32, eight-byte cipher blocks |
| `dfsEv1ThreeKey3Des` | 24 | ISO `1A`, sixteen-byte nonces | Chained eight-byte CMAC, CRC32, eight-byte cipher blocks |
| `dfsD40Des` | 8 | Legacy `0A`, eight-byte nonces | Reset IV, inverse-send transform, four-byte CBC-MAC, CRC16 |
| `dfsD40TwoKey3Des` | 16 | Legacy `0A`, eight-byte nonces | Reset IV, inverse-send transform, four-byte CBC-MAC, CRC16 |

DES and 2K3DES are distinct explicit profiles even when authentication key
components happen to coincide. No parity/version-bit normalization, key reversal
or dialect fallback is performed. A D40 send XORs each plaintext block with the
previous wire block and applies the native decrypt primitive; ordinary CBC
decryption is not a substitute for that transform.

Ordinary standard/backup/value/linear/cyclic file reads, verified standard range
writes and retained backup/value/record transactions use the existing APIs.
Sessions authenticate once, own their engine independently of the component,
retain the selected dialect and require explicit commit/abort. Commit verifies the
complete expected backup, value and record state. Native AF framing operates on
the complete secured message; fragments do not independently advance the MAC/IV.

ISO 3DES metadata and successful write acknowledgements carry CMAC. Legacy D40
metadata and acknowledgements are plaintext, and legacy Plain file data have no
transmitted integrity MAC. A successful legacy status is not an authenticated
receipt. The profile does not invent MACs absent from that protocol. Select
`MinimumCommunication` according to acquired file settings and application policy;
failed authentication/integrity never falls back to public access.

Native application/ordinary-file create/delete, application settings, PICC free
memory and key-version reading also work through the explicit DES/3DES profiles.
The optional `IDesfireApplicationManagement` interface adds explicit application
key-storage selection; see [DESFIRE_APPLICATIONS.md](DESFIRE_APPLICATIONS.md).
Creation initializes card-default credentials, not caller-supplied keys.

EV2 NonFirst, AES key rotation and key/access-policy changes remain AES-specific.
DES/3DES key rotation, key-type conversion of existing applications, policy/access
changes, EV2 key sets, LRP, SDM and TMAC extensions are not implemented by these
profiles. DesfireDemo exposes the new choices on file, transaction and ordinary
management pages; AES key/access mutation pages retain the existing choices.

## Native cryptography

`ICardDesProvider` is an optional capability with a new IID, extending the unchanged
AES contract. Its primitive accepts exactly 24 EDE key bytes, an eight-byte borrowed
IV and bounded whole blocks without padding. `TCardDesCrypto` explicitly expands
8-byte DES to K1/K1/K1 and 16-byte 2K3DES to K1/K2/K1, composes 64-bit CMAC and
legacy inverse send, and validates backend output sizes.

`TCardWindowsAesProvider` supplies AES and 3DES through Windows CNG.
`TCardOpenSslAesProvider` supplies both through OpenSSL 3 on Linux.
`TCardEacOpenSslProvider` also exposes the optional DES interface through its
existing dynamically loaded native 3DES implementation. No primitive cipher is
implemented in Pascal. Native provider/policy failures remain explicit failures.

Core and Contactless packages explicitly contain the new units. The standalone
design package keeps its own complete source closure and registers
`TUltralightCCardReaderWriter`; it acquires no runtime BPL dependencies.

## Validation and protocol references

`LegacyMifare.Tests.dpr` consumes fixed synthetic literal transcripts, generated
independently with Python cryptography's native Triple DES implementation.
`tools/generate_legacy_mifare_fixtures.py` is optional developer tooling; the
Pascal test runner does not require Python cryptography. Credentials and nonces
in these fixtures are public synthetic values, not card/customer credentials.

Coverage includes a published NIST TDEA CMAC vector, a two-key EDE block vector,
all four DESFire profiles and three communication modes, complete transaction
verification, AF chains in both directions, every one-shot I/O failure boundary,
protected response bit corruption, Ultralight C mutual authentication/CRC and
user-page bounds, failed RNG and failed session release. Native CNG ABI tests
exercise DES buffers, wrong returned lengths, IV ownership and native failure
cleanup through the existing OpenSSL-backed C shim. These scripts supplement
compiler/device evidence; they are not a Delphi compiler.

Protocol composition was cross-checked against these pinned public references;
no external implementation is copied, compiled or linked:

- [libfreefare DESFire authentication](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire.c),
  [message composition](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_crypto.c),
  [session-key nonce slices](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_key.c)
  and [Ultralight C frames](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_ultralight.c).
- [NIST SP 800-38B](https://csrc.nist.gov/pubs/sp/800/38/b/upd1/final), 64-bit CMAC
  subkey polynomial and TDEA known-answer example.
- [Microsoft BCryptEncrypt](https://learn.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptencrypt)
  and [OpenSSL EVP cipher APIs](https://docs.openssl.org/3.5/man3/EVP_EncryptInit/).

Hardware compatibility is scoped to the declared reader adapter and explicit card
protocol, not inferred for every reader or every product carrying the same brand.
