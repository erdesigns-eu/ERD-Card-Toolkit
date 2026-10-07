# Programmable UID card profiles

UID programming is a dedicated operation in `TContactlessCardReader`. The shipped
implementation targets explicitly identified **reprogrammable Classic Gen2/CUID**
cards with a four-byte or seven-byte manufacturer-block layout. It is independently
written and exercised with synthetic readers; actual chip/reader compatibility has
not been established. A successful PC/SC UID read does not identify this capability.

"Unfused" is a product state/description, not one universal protocol. Some chips permit
repeated writes, others write once or expose an irreversible fuse, and others need
proprietary RF commands. Reader-command support and the card's exact programmable
variant are separate requirements. Normal production MIFARE UID fields are not
general-purpose writable user memory.

## Support matrix

| Family | Current support |
| --- | --- |
| Reprogrammable Classic Gen2/CUID, four-byte UID | Explicit layout, sector-zero authentication, standard direct manufacturer-block write and verification implemented |
| Reprogrammable Classic Gen2/CUID, seven-byte UID | Explicit seven-byte layout and verification implemented; no four-byte BCC inserted into metadata |
| Gen1a/Gen1b and UFUID variants | Pending exact card/reader profiles for raw RF unlock/activation; no unlock or fuse command is sent by this release |
| FUID/OTP or other write-once/fusing variants | Pending separate one-time programming semantics and verified vendor protocol; not covered by the reprogrammable Gen2 API |
| Gen3/APDU, Gen4/USCUID/GDM/UMC variants | Pending proprietary protocol/reader adapters; commands cannot be inferred from a marketing generation alone |
| Programmable Ultralight/NTAG-style seven-byte UID | Pending manufacturer-page protocol and multi-page recovery; ordinary Type 2 writers reject pages 0..3 |
| Ten-byte UID variants | Pending concrete supported chip layout/command profile; rejected by the current Gen2 API before I/O |
| LF 125 kHz and UHF RFID identifiers | Pending suitable hardware, family codecs and device adapters; not accessible through this NFC storage profile |

The aim is broad coverage through explicit profiles, with a matrix of tested chip,
reader, firmware, driver and operation. Do not infer capability from a UID length,
ATR, UID contents or the terms "magic", "CUID" or "unfused" alone. This release does
not promise every product sold under those names or automatic card identification.
No physical UID write, card fuse or access-controller operation was executed during
development or validation.

## API and exact behavior

Add `ERD.Card.Contactless.UID` to uses. Configure a connected transport and a matching
reader profile as in [the contactless guide](CONTACTLESS.md). The existing base
`IContactlessReaderProfile` is unchanged; an optional `IGen2UidReaderProfile` builds
the dedicated manufacturer-block write. `TPcscStorageProfile` implements that command
shape; its capability does not assert that the connected card is programmable.

```pascal
ResultData := Contactless.ProgramClassicGen2Uid(
  cgum4Byte, RequestedUid, mckA, SectorZeroKey);
```

Declare `ResultData: TProgrammableUidResult`, `RequestedUid, SectorZeroKey: TBytes`.
`RequestedUid` is four bytes for `cgum4Byte` or seven bytes for `cgum7Byte`.
`SectorZeroKey` is a supplied six-byte key for sector zero; `mckB` is also supported.
An optional fifth argument selects a supported volatile reader slot. The component
never supplies default keys or searches for keys. Existing key-slot lifetime and
local command-buffer overwriting rules apply.

The operation runs in one exclusive card transaction by default:

1. Validate the requested UID/model, supplied key and optional reader capability
   before I/O. ISO 14443-A cascade-tag value 88 is rejected at UID0 for a four-byte
   UID and at UID3 for a seven-byte UID. Ten-byte or mismatched lengths fail immediately.
2. Read the current reader-reported UID, requiring the selected size. Load the supplied
   volatile sector-zero key, authenticate and read all sixteen manufacturer-block bytes.
3. Validate the four-byte layout's existing BCC and ensure the block's UID equals the
   reader-reported UID, byte-for-byte. Seven-byte layouts have no stored BCC in byte seven.
   No byte reversal, guessed conversion or guessed layout is applied.
4. Prepare an independent block. For four-byte UIDs replace bytes 0..3 and set byte 4
   to their XOR, preserving bytes 5..15 exactly. For seven-byte UIDs replace bytes 0..6,
   preserving bytes 7..15 exactly. SAK/ATQA/manufacturer metadata is not rewritten.
5. If the requested UID already matches, return a verified no-op result without a
   write. Otherwise dispatch one dedicated `FF D6 00 00 10` manufacturer-block write.
6. Read back and compare all sixteen bytes, then read the reader-reported UID again.
   Return a snapshot only after verification and successful transaction release.

`TProgrammableUidCodec` provides stateless length/cascade validation, UID decoding and
block preparation for offline tools. It neither detects writable chips nor sends
commands. Four-byte BCC preparation does not assert global UID uniqueness, identifier
ownership or acceptance by a particular access controller.

## EEPROM verification and active UID

`TProgrammableUidResult` contains the selected model, independent previous/requested
UID buffers, the verified complete manufacturer block and `ActiveUidVerified`.

- True means the reader reports the requested UID after the block write, or the
  requested UID already matched the original.
- False means the complete manufacturer block matched on read-back, but the reader
  still reports the original UID. Reader/card RF reactivation and a fresh UID check
  are required before the application treats provisioning as complete.

Some card/driver combinations expose the new UID only after reactivation, and a
driver can cache selection data. The method does not reset RF, disconnect/reconnect,
consume fuse operations or repeat the write to make verification appear successful.
Re-present/reactivate the card according to the reader's documented behavior, then
call `ReadUid` and compare against the requested bytes. A false verification state
does not guarantee that reactivation will make the new UID effective. Hardware tests
must check fresh selection and actual identifier presentation for each supported variant.

If the post-write UID is neither the previous nor requested value, the operation
fails with an uncertain outcome rather than reporting success on a potentially
different card. The library does not configure access controllers or read their
credential databases.

## Failure handling and scope

Parameter, capability, BCC or initial UID/block mismatch fails before dispatch.
General Classic/Type 2 data writers still block manufacturer and lock/configuration
regions. The dedicated Gen2 method is the explicit programming path; it does not
alter access bits, sector keys, fuse flags, card type or issuer applications.

A write status failure remains `EContactlessStatusError.StatusWord`; it does not
guarantee unchanged memory. A transport/parse failure after dispatch, a failed or
mismatched read-back, a failed UID check, or a release failure after accepted writing
raises `EContactlessWriteUncertain`. Only the original error class is retained, not
APDU/key/identifier payloads or external exception messages. A primary verification
failure wins over cleanup failure. No completed snapshot is returned on those errors.
Inspect and reconcile the card before retrying; PC/SC transactions cannot roll back
card EEPROM or fuse behavior.

## Validation and sources

Synthetic tests check exact preparation/write/read-back/UID APDUs, both layouts,
all accepted first-byte values in the four-byte BCC calculation, cascade rejection,
metadata preservation, independent buffers, no-op behavior, pending activation,
wrong-card/malformed-block rejection, denied writes, transport loss, failed read-back
and release precedence. No real card/key/access-system fixture is committed.
Delphi/Help Insight and physical reader/card tests remain pending.

Protocol facts were checked on 2026-10-07 against:

- [Proxmark3 magic-card notes](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/doc/magic_cards_notes.md),
  sections "MIFARE Classic block0" and "MIFARE Classic DirectWrite aka Gen2 aka CUID".
  The inspected notes match that pinned commit; SHA-256
  `9409de8f160a5124d751915ba237dd33a73f01d76a71afbf3ca942943f282821`.
- [NXP AN10927: MIFARE product and handling of UIDs](https://www.nxp.com/docs/en/application-note/AN10927.pdf),
  cascade-level and identifier-size rules. This reference describes UID framing, not
  support for reprogramming normal production cards.
- PC/SC Part 3 and ACS ACR122U API 2.04 for reader storage/authentication command
  framing, linked with hashes in [the contactless guide](CONTACTLESS.md).

The implementation is independently written from protocol/layout facts. No Proxmark3
implementation, RF unlock sequence or third-party binary is copied into the library.
