# Contactless reader profiles and MIFARE storage

`TContactlessCardReader` in `src/contactless/ERD.Card.Contactless.pas` is an RTL-only
non-visual component. `ERDCardContactless.dpk` requires `rtl` and `ERDCardCore`.
Add `src/core` and `src/contactless` to the search path, and `src/pcsc` for Windows
hardware. Assign both a connected `ICardTransport` and an explicitly matching
`IContactlessReaderProfile`. No profile is selected in the constructor.

## What is available

| Function | Implementation and boundary |
| --- | --- |
| Reader-reported UID | `ReadUid`, 1..32 bytes in the reader's returned order; no card-family inference |
| Classic Mini/1K/4K layout | 20/64/256 sixteen-byte blocks, including mixed-size 4K sectors |
| Classic block reading | Supplied six-byte key A/B, volatile key-slot load, authentication and read in one transaction |
| Classic data-block writing | Six-byte supplied key and sixteen-byte payload; block zero and every sector trailer rejected before I/O |
| Ultralight/NTAG pages | Explicit original Ultralight, EV1-48/128 and NTAG213/215/216 layouts; four-byte page reads/user writes and complete user-memory snapshots |
| Password-authenticated EV1/NTAG user memory | Separate `TType2PasswordCardReader`: one supplied-password/PACK check per raw session, bounded FAST_READ snapshots and verified user-page writes |
| Programmable Classic UID | Explicit reprogrammable Gen2/CUID four/seven-byte layouts; dedicated manufacturer-block programming and verification |
| Factory FUID UID programming | Separate authenticated four-byte single-write API; factory/source checks, full read-back and explicit active/cached UID state |
| Raw RF UID programming | Separate `TRawUidProgrammer`: Gen1a/Gen1b/unsealed UFUID, Type 2 DirectWrite, Gen3, Gen4 UMC, USCUID/GDM public/hidden and partial UFUID/ZUID/PFUID sources; ACR122U/PN532 adapter, explicit bit framing and fresh selection |
| PC/SC storage profile | FF CA/82/86/B0/D6 dialect checked against PC/SC Part 3 and ACS ACR122U API 2.04 |
| NFC-EMV | Separate `TEMVCardReader` PPSE/AID/GPO/AFL path through ISO 7816 APDUs |
| NDEF codecs and public Type 2 storage | `TNdefCodec`/`TNdefRecords`, CC/TLV mapping and `TType2NdefCardReader`; bounded framing, strict RTDs, lock/access preflight and verified length-last updates |
| Public Type 4 NDEF files | `TType4NdefCardReader`: explicit mapping 1.0/2.0 ISO 7816 applications, CC/file descriptors, MLe/MLc-bounded reads and verified NLEN-last updates |
| Addressed ISO 15693 memory | `TIso15693CardReader`, explicit 8/16-bit geometry, single-block security and guarded writes; ACR1552U-M/ACM1552U-Y/Z FF FB adapter |
| Public Type 5 NDEF memory | `TType5NdefCardReader`: initialized E1/E2 CC/TLV mapping, lock preflight and verified length-last updates |
| Native DESFire files | `TDesfireCardReader`: discovery, ordinary data/value/record reads and verified standard-data writes; explicit EV2 AES authentication and Plain/MACed/Full secure messaging |
| Additional DESFire security/transactions, Plus, Type 1/3 NDEF, other programmable UID families | Separate profiles still pending |

The Mini model supplies the original memory layout, not a tested Mini/reader
compatibility claim. This release has synthetic command tests and no physical reader
validation. Supporting a command dialect does not establish support for every card
family, firmware revision, reader slot or platform.

## Reader coverage

PC/SC reader discovery is shared with EMV/eID. Its `TSmartCardReader` native adapter
currently targets Windows winscard and T=0/T=1; contactless storage readers commonly
expose these operations through a T=1 emulation. This is driver behavior, not a
claim that every reader has native raw/RF support. The explicit ACR122U/PN532
backend is documented in [the raw UID guide](RAW_UID.md).
The separate ISO 15693 adapter requires the documented ACR1552U-M or ACM1552U-Y/Z
firmware and explicit addressing/response choices; see
[ISO 15693 and Type 5](ISO15693_TYPE5.md). It does not cover ACR1552U-A.

`TPcscStorageProfile` is opt-in and uses the standard storage pseudo-APDUs described
below. ACR122U API 2.04 is a concrete documented dialect reference, **not a hardware
test result**. Other compliant devices can use it after checking their documentation
and testing their firmware/driver. Readers with different commands can implement
`IContactlessReaderProfile` without replacing memory-layout checks or the component.
Optional `IType2ReaderProfile` and `IGen2UidReaderProfile` expose page and Gen2
programming command capabilities. The existing base interface and its GUID are
unchanged. `TPcscStorageProfile` implements both additions; support by a command
builder is not proof that a connected card permits those operations. Old Classic-only
profiles still work and reject unsupported new operations before acquiring a transaction.
Devices requiring SCardControl, escape commands or vendor DLLs need a separate
transport/API extension; those backends are not implemented here.

Do not identify a card family from its UID or assume Classic support from an NFC
label. UID values can be random, nonunique or reader specific. PC/SC ATRs for
contactless storage cards can be synthetic descriptors. No fallback probes, key
search, hardcoded default keys or guessed card models are sent.

## Operations and ownership

```pascal
uses ERD.Card.Contactless;

Contactless := TContactlessCardReader.Create(nil);
try
  Contactless.Transport := ConnectedCard.Transport;
  Contactless.Profile := TPcscStorageProfile.Create;
  Uid := Contactless.ReadUid;
  Block := Contactless.ReadClassicBlock(mcm1K, 4, mckA, ApplicationKey);
finally
  Contactless.Free;
end;
```

Declare `Contactless: TContactlessCardReader`, `Uid, Block, ApplicationKey: TBytes`.
`ConnectedCard` is an already connected `TSmartCardReader`. Assign this profile only
when it matches the reader/driver and supply a key appropriate to the card and sector.
The sample performs no write. Applications can explicitly call
`WriteClassicDataBlock(Model, BlockNumber, KeyType, Key, Data, Slot)` for data blocks.
The component rejects block zero and trailers, including 4K blocks 143,159,...,255.
It does not provide key rotation, access-bit updates or value-block commands.
Sector access conditions still determine which operations the supplied key permits.

The storage profile builds:

| Operation | Command |
| --- | --- |
| UID | `FF CA 00 00 00` |
| Volatile key load | `FF 82 00 slot 06` followed by six supplied bytes |
| Authenticate | `FF 86 00 00 05 01 00 block 60-or-61 slot` |
| Read block | `FF B0 00 block 10` |
| Write data block | `FF D6 00 block 10` followed by sixteen supplied bytes |
| Read Type 2 page | `FF B0 00 page 04` |
| Write Type 2 user page | `FF D6 00 page 04` followed by four supplied bytes |

The profile does not append Le to load/authenticate/write. Successful load/auth/write
must return only 9000; Classic reads must return sixteen data bytes and Type 2 page
reads four data bytes, followed by 9000. Each
command is sent once. A 61xx or 6Cxx remains a status failure: storage pseudo-APDUs
are not automatically treated as application APDUs with GET RESPONSE/retry rules.

Key slots are reader dependent; ACR122U API 2.04 documents slots zero and one.
Slot zero is the default. Key loads use volatile reader memory, **not** card sector
key updates. The component retains no key field and overwrites its local key-bearing
command on success/failure without modifying caller buffers. This is not a secure
memory guarantee: profile/transport copies are outside its control, and the reader
may retain the loaded key until reset or physical disconnection according to its
documentation. A PC/SC transaction release is not key erasure; application/reader
lifecycle must handle this explicitly.

Configure and call on one thread without reentrancy. `UseTransactions=True` requires
`ICardTransaction` and holds one exclusive transaction around the full operation,
including load/auth/read or load/auth/write. Set false only for caller-guaranteed
exclusive access; existing transactions cannot nest. A primary operation failure
wins over a release failure. Output buffers are independent and reads return only
after successful release. No reset/reconnect/replay occurs on exceptions.

Writing is not rollback capable. An explicit reader/card failure is retained as
`EContactlessStatusError.StatusWord`. Transport, malformed-success-response or release
errors after write dispatch raise `EContactlessWriteUncertain`, retaining only the
original error's class. Check the card before retrying. A 9000 status does not provide
an independent read-back verification; a status failure also cannot promise unchanged
card bytes. Writes that fail before dispatch keep their original error type.

## Ultralight/NTAG memory

`ERD.Card.Contactless.Type2` supplies independent layout helpers and the
`TType2UserMemory` record. Card type is caller-selected, not guessed from UID/ATR.

| Model | Physical pages | User pages (inclusive) | User bytes | Excluded tail |
| --- | --- | --- | --- | --- |
| `ttmUltralight` (MF0ICU1) | 0..15 | 4..15 | 48 | None |
| `ttmUltralightEv1_48` (MF0UL11) | 0..19 | 4..15 | 48 | Configuration/password 16..19 |
| `ttmUltralightEv1_128` (MF0UL21) | 0..40 | 4..35 | 128 | Dynamic locks 36, configuration/password 37..40 |
| `ttmNtag213` | 0..44 | 4..39 | 144 | Dynamic locks 40, configuration/password 41..44 |
| `ttmNtag215` | 0..134 | 4..129 | 504 | Dynamic locks 130, configuration/password 131..134 |
| `ttmNtag216` | 0..230 | 4..225 | 888 | Dynamic locks 226, configuration/password 227..230 |

All models exclude pages 0..3 from user writes: manufacturer/UID, static locks and
OTP or Capability Container. `WriteType2UserPage(Model, Page, Data)` requires exactly
four bytes and rejects every excluded or out-of-model page before I/O. It does not
modify password, authentication configuration, counters, lock bits or the UID.
Locked/protected user pages may still be denied by the card. Original Ultralight,
EV1 variants and NTAG variants do not share one unrestricted memory size.

`ReadType2Page(Model, Page)` allows any in-range physical page; password/configuration
bytes can be masked or access denied. Returned bytes remain exactly as received.
`ReadType2UserMemory(Model)` reads pages four through the last user page in ascending
order, in one exclusive transaction. It returns a complete independent snapshot,
never a partial buffer padded after a failed page. The largest snapshot is 888 bytes.
No Classic key load/authentication is sent for these operations.

The PC/SC profile requests four bytes per page. This bounds application requests and
avoids issuing extra PC/SC reads into excluded regions. The reader may translate that
into a native four-page RF READ and truncate the result; RF wraparound and password
boundary behavior depend on the reader/card. Physical tests must establish those
details. The component rejects a driver returning sixteen bytes for a four-byte request.

The PC/SC storage path reads/writes publicly accessible user memory. Supplied-password
PWD_AUTH/PACK verification and protected user-memory operations are implemented
separately in [TYPE2_PASSWORD.md](TYPE2_PASSWORD.md), using retained raw-RF state.
Public contiguous Type 2 NDEF mapping and conservative whole-model lock checks are
implemented in the separate [NDEF component](NDEF.md). Ultralight C/EV2/AES, NTAG
I2C/sector selection, secure messaging and granular lock/configuration changes remain
separate profiles. Enabled mirror
features can affect reader-visible data; a snapshot is not a claim of raw backing EEPROM.

Declare `Memory: TType2UserMemory` and add `ERD.Card.Contactless.Type2` to uses:

```pascal
Memory := Contactless.ReadType2UserMemory(ttmNtag213);
// Explicit user-page write, if the application intends to replace that page:
Contactless.WriteType2UserPage(ttmNtag213, 4, ApplicationPageBytes);
```

`ApplicationPageBytes` is a caller-supplied `TBytes` containing exactly four bytes;
writing a page can alter an existing NDEF message. This low-level page API performs
no automatic message formatting, read-back, rollback or multi-page update. Use
`TType2NdefCardReader` for the guarded NDEF update protocol; see [NDEF.md](NDEF.md).

## Programmable UID

`ProgramClassicGen2Uid` is a separate explicit operation for identified reprogrammable
Gen2/CUID cards with a four-byte or seven-byte manufacturer-block layout. It validates
the existing UID/block, preserves metadata, writes once and checks the complete block
and reader-reported UID. Standard data writers continue rejecting manufacturer blocks.
See [the programmable UID guide](PROGRAMMABLE_UID.md) for verification states and the
support boundary for other unfused/card generations.

## NFC, RFID and EMV boundaries

NFC is the communication context; EMV is a payment application protocol. Contactless
bank cards commonly communicate with ISO 14443/ISO-DEP and ISO 7816 APDUs. Use the
EMV component, not Classic memory commands, for those applications. Ordinary EMV
records cannot be rewritten with MIFARE data-block commands.

MIFARE Classic is authenticated block storage. Ultralight/NTAG use page layouts,
lock/configuration regions and variant-specific authentication. DESFire uses files,
application keys and authenticated secure messaging. Plus modes need their own
security profiles. None is a substitute for a payment kernel. NDEF is a data format
on top of a specific NFC tag type and access layer. LF 125 kHz and UHF RFID require
suitable hardware/backends and are not implicitly supported by an NFC PC/SC reader.

Public Type 4 NDEF access is implemented separately in [TYPE4_NDEF.md](TYPE4_NDEF.md),
including already formatted public DESFire NDEF files. Native DESFire access is a
separate [component and EV2 AES profile](DESFIRE.md), with maintained crypto backends.
Further families include other Type 2
security variants, authenticated ISO 15693 access, further programmable UID profiles and native
DESFire D40/EV1/LRP, backup/value/record transaction writes and administration.
Public ISO 15693/Type 5 access is available through the separate components described
in [ISO15693_TYPE5.md](ISO15693_TYPE5.md).
Additional profiles are planned, not advertised
as already readable/writable. Maintain a tested matrix of reader/firmware/driver/card
variant and operation, including card removal and write verification.

## Validation and sources

`examples/contactless/InspectContactless.dpr` requires the explicit
`--pcsc-storage` profile argument and reports UID length. An additional
`--type2 <model>` reads a complete user-memory snapshot and reports page/byte counts
without printing identifiers or memory contents. It never authenticates
or writes; `--help` needs no hardware. Tests use synthetic supplied keys and exact
command transcripts, cover every original layout/trailer, key wiping, failed
authentication, protected writes, uncertain completion and release precedence.
Type 2 tests cover all six memory layouts, every excluded page, masked reads,
complete ascending-page snapshots and page failures. UID tests cover four/seven-byte
layouts, BCC/cascade validation, metadata preservation, read-back mismatch, no-op
programming and explicit pending RF activation. No actual UID programming is performed.
Real hardware, Delphi package builds and Help Insight remain pending.

Protocol facts were reviewed on 2026-10-07 against:

- [PC/SC Part 3 v2.01.09](https://pcscworkgroup.com/Download/Specifications/pcsc3_v2.01.09.pdf),
  section 3.2.2.1, downloaded SHA-256
  `29672bf0baa2e03b6ec7f4512d45dff12867a1f8d5000817659e5e1c8956c2ca`.
- [ACS ACR122U API 2.04](https://downloads.acs.com.hk/drivers/en/API-ACR122U-2.04.pdf),
  sections 4.1 and 5.1–5.4, downloaded SHA-256
  `ee13dad80d05d3befc0b7d36bc13813c4bea4514be0672ef549384f76aa5a322`.
- [NXP MIFARE families](https://www.nxp.com/products/rfid-nfc/mifare-hf:MC_53422).
- [NXP MIFARE Classic EV1 4K data sheet](https://www.nxp.com/docs/en/data-sheet/MF1S70YYX_V1.pdf),
  sections 8.6–8.7 for mixed-size sectors, manufacturer block and trailer/access layout.
- [NXP MF0ICU1 original Ultralight](https://www.nxp.com/docs/en/data-sheet/MF0ICU1.pdf),
  section 7.5; SHA-256 `12b11af185c235db4ff45b562de3f73c6aabd4346e093e661c8f648981b2fda3`.
- [NXP MF0ULX1 Ultralight EV1](https://www.nxp.com/docs/en/data-sheet/MF0ULX1.pdf),
  section 8.5; SHA-256 `53cc29c6c7d8d93b12ad11f9de9c2c1368ad537f56e363e29b8c1723504a07f8`.
- [NXP NTAG213/215/216](https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf),
  section 8.5; SHA-256 `8c2a81e144d1123ee0a9c3ddd4876144fd11e299893032315c4a34fbbc6b2ed1`.

The implementation is independently written; no external implementation or standards
PDF is bundled. See [the payment architecture](PAYMENTS.md) for both payment routes.

Factory FUID programming uses a separate optional `IFuidUidReaderProfile` and
`ProgramFuidUidOnce`, preserving existing Gen2/Classic profile contracts. USCUID/GDM
uses the raw programmer with explicitly configured public/hidden sources and
wakeup styles. See [USCUID_FUID.md](USCUID_FUID.md) for preconditions, one-time
semantics, cached UID handling and persistent raw-RF verification.

Gen1b adds an explicit seven-bit40-only wakeup profile. The partial-USCUID API
verifies documented UFUID/ZUID/PFUID configurations and their distinct read
opcodes, with full read-back after fresh selection. See
[GEN1B_PARTIAL_UID.md](GEN1B_PARTIAL_UID.md).
