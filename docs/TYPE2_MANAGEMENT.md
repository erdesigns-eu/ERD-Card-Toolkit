# Type 2 authentication management and protected NDEF

`TType2PasswordCardReader` now covers Ultralight EV1 48/128 and NTAG210/212/213/215/216
management through the existing `IRawContactlessReader` / ACR122U adapter. Select
the actual model explicitly; no UID/ATR-based guessing or alternative password attempts.

| Method | Behavior |
| --- | --- |
| `ReadConfiguration(Model, Password, Pack)` | Owned eight-byte configuration snapshot; AUTH0, PROT, AUTHLIM, CFGLCK and model-specific mirror/counter flags; no stored PWD/PACK reads |
| `ConfigureAuthenticationVerified(Model, Auth0, ProtectReads, Authlim, Preimage, Password, Pack)` | Exact preimage and CFGLCK checks; ACCESS before AUTH0; preserves all other bits; fresh same-UID authentication and exact configuration verification |
| `ChangeCredentialsVerified(Model, OldPassword, OldPack, NewPassword, NewPack)` | PACK then PWD, each once; fresh same-UID selection and mandatory replacement PACK verification |
| `ReadCounter(Model, Counter, Password, Pack)` | EV1 counters 0..2 or NTAG213/215/216 NFC counter 2, returned as a 24-bit value; NTAG210/212 are rejected |
| `ReadNdef(Model, Password, Pack)` | Complete CC/user memory and parsed NDEF in one authenticated RF session |
| `WriteNdefVerified(Model, Bytes, Password, Pack)` | Existing contiguous NDEF TLV replacement/clear with invalidation, length-last publication, per-page and full-memory/CC verification |

Passwords are exactly four bytes; expected PACK values are exactly two bytes.
AUTH0 accepts an explicit byte 0..255; values beyond the final user page disable
user-memory protection. AUTHLIM is 0..7, with zero disabling the negative-attempt
limit. Successful authentication may reset its internal failed-attempt counter;
the component does not infer a remaining budget. Reads can change enabled NFC counters.

Configuration updates preserve CFGLCK, mirror/counter modes, reserved bytes and
model-specific fields. No API programs irreversible configuration locks, user lock
bits, OTP, mirror modes or counter increments. Credential pages remain separately
writable even when CFGLCK is set. PWD/PACK storage cannot be read back; PACK-page
RFUI bytes are written as the specified zeros. Replacement proof uses fresh
selection, not a cached previous authentication result. Unchanged credentials still
receive fresh proof without writes.

NDEF operates entirely through raw FAST_READ/A2 inside one retained authentication
session. It never mixes reader storage pseudo-APDUs into that session. It reuses the
strict contiguous CC/TLV mapping, rejects mirrors and existing static/dynamic user
locks, preserves unrelated memory, and publishes message length last. Empty bytes
clear an existing TLV; absent TLVs or unsupported reserved holes are not formatted.
Multi-page changes are not atomic. Post-dispatch failures, including partial
credentials, readback, fresh proof or release, raise `EContactlessWriteUncertain`.
No retry, rollback or password discovery is generated. Password authentication
remains plaintext access control, not encrypted communication or card authenticity.

The existing Type2Demo has its own DFM tab for each operation, reader combobox and
native reader/card events. Secrets are masked, copied into worker credentials and
cleared. Configuration preimages and NDEF are exportable; passwords/PACK are not.

Public protocol references:

- [NXP MF0ULX1](https://www.nxp.com/docs/en/data-sheet/MF0ULX1.pdf), configuration,
  PWD_AUTH, credential pages and READ_CNT.
- [NXP NTAG213/215/216](https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf),
  AUTH0/PROT/AUTHLIM/CFGLCK, mirror/counter bits and counter address 02.
- [NXP NTAG210/212](https://www.nxp.com/docs/en/data-sheet/NTAG210_212.pdf), distinct
  UID-mirror configuration and absence of the NTAG213/215/216 READ_CNT profile.

Fixed independent synthetic transcripts and native-reader error tests are in
`tests/contactless/Type2Felica.Tests.dpr`; the optional fixture generator uses only
Python's standard library and never imports Pascal implementation code.
