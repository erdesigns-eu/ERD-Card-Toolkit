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
| `ReadConfiguration(Key)` | Owned pages 40–43 snapshot, AUTH0/AUTH1 and lock flags; no key-page reads |
| `ConfigureAuthenticationVerified(FirstPage, ProtectReads, ExpectedPages, Key)` | Preserved reserved bytes, exact pages 42/43 preimage and lock checks, fresh same-UID authentication and configuration readback |
| `ChangeKeyVerified(CurrentKey, NewKey)` | Key pages 44–47 programmed once; new key proved after same-UID RF reset and successful release |

Authentication uses a supplied 16-byte K1/K2 key in cryptographic byte order,
a fresh eight-byte system nonce, `1A 00` / `AF` frames with CRC-A and mutual nonce
verification. A single exclusive RF session retains authentication until readback
and release. Memory commands remain plaintext after authentication; Ultralight C
does not encrypt those memory exchanges.

Generic user-page writes exclude pages outside 4–39. Dedicated configuration
and key APIs explicitly handle pages 42–47. No method programs manufacturer,
static/dynamic locks, OTP or the counter. User-region tail READs start at page 36.
Configuration updates preserve reserved bytes and existing locks/counter bytes;
AUTH1 is written before AUTH0. First protected page is 3–48; 48 disables protection.
`ProtectReads=True` protects both reads and writes; false protects writes only.
Supply the exact eight bytes `AuthenticationPages` from `ReadConfiguration` as
preimage. Read protection is never disabled automatically.

Key pages cannot be read back. The API reverses each eight-byte subkey for EEPROM
storage, writes all four pages once and resets the RF field before proving the new
key. One exclusive session covers programming and fresh activation; the same UID
must be selected. A no-op still obtains fresh authentication proof. Partial key
programming can leave the card requiring device-specific recovery; the component
never retries, rolls back or claims verification after a failure. No operation retries authentication or a write. After write dispatch,
failed ACK, readback, integrity or release raises `EContactlessWriteUncertain`.

Use `examples/vcl/ultralightc/UltralightCDemo.dproj`: it owns its own editable
form/DFM, reader combobox, presence label and six operation pages. Enter a key
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

`ChangeKeySettings` and `ChangeFileAccess` support all explicit authenticated
AES/DES/3DES profiles. Acquired policy, key count and ordinary-file access are
checked before mutation. Free-change EV1/D40 settings use the native Plain command
policy; protected changes use Full messaging.

Open `OpenDesManagementSession(Aid)` for `IDesfireDesManagement`.
`ChangeDesKey(KeyNumber, NewVersion, OldVersion, NewKey, OldKey)` retains the selected
DES/2K3DES/3K3DES type. New material must match that profile's key size. Supply an
empty OldKey for the authenticated key; otherwise supply the target's stored bytes
and explicit old first-subkey version. Second/third-subkey stored version bits in
OldKey are preserved, not inferred. New first-subkey version bits are encoded from
NewVersion; new 2K3DES second-subkey version bits are complementary. Eight-byte DES
is duplicated only for the native payload. Fresh authentication with the new key
and an exact key-version check must succeed before verification is reported.
Failures after ChangeKey dispatch remain uncertain and never generate a retry.

EV2 NonFirst and `ChangeAesKey` remain AES-specific. Existing application key-type
conversion, EV2 key sets, LRP, SDM and TMAC are outside these profiles. DesfireDemo
has DES/3DES policy/access choices and a dedicated key rotation tab.

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
user-page bounds, failed RNG and failed session release. Management transcripts
cover all four DES profiles, current/other/PICC key rotation, protected/free file
settings and key policy. ULC tests cover fresh key proof, configuration preimages,
lock checks, reserved-byte preservation, response-bit corruption, every I/O
failure, same-UID reactivation and release failure. Native CNG ABI tests
exercise DES buffers, wrong returned lengths, IV ownership and native failure
cleanup through the existing OpenSSL-backed C shim. These scripts supplement
compiler/device evidence; they are not a Delphi compiler.

Protocol composition was cross-checked against these pinned public references;
no external implementation is copied, compiled or linked:

- [libfreefare DESFire authentication](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire.c),
  [message composition](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_crypto.c),
  [session-key nonce slices](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_desfire_key.c)
  and [Ultralight C frames](https://github.com/nfc-tools/libfreefare/blob/c2b0cfa4b9fb0e4be88604f00b7a2405618d5abc/libfreefare/mifare_ultralight.c).
- [NXP MF0ICU2 Ultralight C datasheet](https://www.nxp.com/docs/en/data-sheet/MF0ICU2.pdf), revision 3.5, 30 January 2026, memory/configuration/key storage and RF-reset activation rules.
- [NIST SP 800-38B](https://csrc.nist.gov/pubs/sp/800/38/b/upd1/final), 64-bit CMAC
  subkey polynomial and TDEA known-answer example.
- [Microsoft BCryptEncrypt](https://learn.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptencrypt)
  and [OpenSSL EVP cipher APIs](https://docs.openssl.org/3.5/man3/EVP_EncryptInit/).

Hardware compatibility is scoped to the declared reader adapter and explicit card
protocol, not inferred for every reader or every product carrying the same brand.
