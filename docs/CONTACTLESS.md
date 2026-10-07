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
| PC/SC storage profile | FF CA/82/86/B0/D6 dialect checked against PC/SC Part 3 and ACS ACR122U API 2.04 |
| NFC-EMV | Separate `TEMVCardReader` PPSE/AID/GPO/AFL path through ISO 7816 APDUs |
| Ultralight/NTAG, DESFire, Plus, ISO 15693, NDEF | Separate family/access implementations still pending |

The Mini model supplies the original memory layout, not a tested Mini/reader
compatibility claim. This release has synthetic command tests and no physical reader
validation. Supporting a command dialect does not establish support for every card
family, firmware revision, reader slot or platform.

## Reader coverage

PC/SC reader discovery is shared with EMV/eID. Its `TSmartCardReader` native adapter
currently targets Windows winscard and T=0/T=1; contactless storage readers commonly
expose these operations through a T=1 emulation. This is driver behavior, not a
claim that an unimplemented native raw/RF protocol is supported.

`TPcscStorageProfile` is opt-in and uses the standard storage pseudo-APDUs described
below. ACR122U API 2.04 is a concrete documented dialect reference, **not a hardware
test result**. Other compliant devices can use it after checking their documentation
and testing their firmware/driver. Readers with different commands can implement
`IContactlessReaderProfile` without replacing memory-layout checks or the component.
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
It does not provide key rotation, access-bit updates, value-block commands or clones.
Sector access conditions still determine which operations the supplied key permits.

The storage profile builds:

| Operation | Command |
| --- | --- |
| UID | `FF CA 00 00 00` |
| Volatile key load | `FF 82 00 slot 06` followed by six supplied bytes |
| Authenticate | `FF 86 00 00 05 01 00 block 60-or-61 slot` |
| Read block | `FF B0 00 block 10` |
| Write data block | `FF D6 00 block 10` followed by sixteen supplied bytes |

The profile does not append Le to load/authenticate/write. Successful load/auth/write
must return only 9000; read must return exactly sixteen data bytes plus 9000. Each
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

The next family implementations are Ultralight/NTAG with explicit variant bounds and
protected-page handling; DESFire with a maintained crypto/secure-messaging provider;
then NDEF mappings and further reader backends. These are planned, not advertised
as already readable/writable. Maintain a tested matrix of reader/firmware/driver/card
variant and operation, including card removal and write verification.

## Validation and sources

`examples/contactless/InspectContactless.dpr` requires the explicit
`--pcsc-storage` profile argument and reports UID length only. It never authenticates
or writes; `--help` needs no hardware. Tests use synthetic supplied keys and exact
command transcripts, cover every original layout/trailer, key wiping, failed
authentication, protected writes, uncertain completion and release precedence.
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

The implementation is independently written; no external implementation or standards
PDF is bundled. See [the payment architecture](PAYMENTS.md) for both payment routes.
