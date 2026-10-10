# Topaz memory and NFC Forum Type 1 NDEF

`TTopazCardReader` reads complete physical memory and writes unlocked user bytes.
`TType1NdefCardReader` reads, parses, replaces and clears existing initialized NDEF.
Both are nonvisual palette components with English Delphi XML Help Insight comments.
The runtime and standalone design packages include their complete source closure.

## Exact profiles

| Model | Header ROM | Physical bytes | Raw user-write addresses | NDEF maximum, no prefix TLVs |
| --- | --- | --- | --- | --- |
| `tmTopaz96` (BCM20203T96) | `11 48` | 120 | 12–103 | 90 encoded message bytes |
| `tmTopaz512` (BCM20203T512) | `12 4C` | 512 | 22–103, 128–511 | 462 encoded message bytes |

Identification uses fresh Jewel polling and RID. The four RID UID bytes must match
polling and memory; the complete seven-byte UID is returned in card memory order.
Unknown header ROM values are refused, rather than inferred from capacity or ATR.
Full snapshots include UID/internal bytes, CC, control bytes, locks, reserved
storage and OTP. The owned `Writable` map has one 00/01 byte per physical byte.

Static locks at 112/113 protect their corresponding eight-byte blocks. Topaz 512
dynamic locks at 122–127 protect 48 eight-byte regions starting at address 128.
The conservative writer excludes UID/internal bytes 0–7, CC 8–11, static reserved/
lock/OTP bytes 104–119, dynamic reserved/control bytes 120–127 and the canonical
Topaz 512 control-TLV region 12–21. Permanent locks and OTP are never programmed.
A raw write must consist entirely of permitted user addresses, even for a no-op.
Topaz 512 writes use complete eight-byte units, preserving unchanged neighboring
bytes, including the control bytes beside user addresses 22/23.

## Reader adapter

Assign an `ITopazSession`. The concrete `TAcr122TopazSession` is an explicit
ACR122U/PN532 **FF00 direct-transmit** adapter; ordinary PC/SC storage commands
are insufficient. Reader names and ATR do not automatically select this dialect.
The transport must support `ICardTransaction`. One card must be present.

The adapter configures finite 409.6 ms RF timeout and zero communication/activation
retries, cycles RF, and polls BrTy 04 (Jewel). RID/RALL and static WRITE-E use PN532
InDataExchange. Select the documented status-only byte-write acknowledgement or
an explicit firmware byte-echo dialect; malformed status, target counts, identity
and response lengths fail. RF timing/retry settings persist until reader reset or
deliberate reconfiguration. EndSession attempts RF-off and transaction release.

PN532 firmware cannot be assumed to implement arbitrary RSEG/READ8/WRITE-E8.
Topaz 512 therefore uses native READ8/WRITE-E8 through **CIU register commands**:
software CRC-B, separate seven-bit command and eight-bit data frames, manual parity
handling, bounded receive polling, exact FIFO length/last-bit count, odd parity,
CRC, block echo and write-data echo checks. Saved parity/framing/CRC settings are
restored after each exchange. Full memory uses RALL plus READ8 blocks 15–63.
A failed exchange poisons the active adapter; only release is allowed afterwards.
No firmware fallback or automatic replay is attempted.

## Reads and verified raw writes

`ReadSnapshot` returns identity, all memory and the lock map. `ReadRange` returns
an explicit physical byte range, including readable metadata. To write, retain the
snapshot and call `WriteUserRangeVerified(ExpectedUid, ExpectedMemory, Address,
Data)`. The UID must be seven bytes and the preimage must be all 120/512 bytes.
Arguments, permissions and bounds are checked before reader acquisition; a fresh
snapshot must then match the exact UID and complete preimage under exclusivity.

Only changed bytes (96) or eight-byte blocks (512) are sent. Each programming unit
has independent readback, followed by a complete image comparison. Identical data
is an acquired verified no-op. Every failure after dispatch, including final RF/
transaction release, raises `EContactlessWriteUncertain`. The library neither
retries nor rolls back a dispatched write.

## Initialized NDEF mapping

The CC must be `E1 10 0E 00/0F` for Topaz 96 or `E1 10 3F 00/0F` for Topaz 512.
Read access must be public; write access is writable 00 or read-only 0F. Only mapping
version 1.0 is supported. Topaz 512 requires these existing control bytes at 12–21:

```text
01 03 F2 30 33 02 03 F0 02 03
```

The logical TLV stream starts at address 12 (96) or 22 (512), skipping 104–127 on
512. Leading NULL/proprietary TLVs are retained. One NDEF TLV is required; extra
control layouts, duplicate NDEF and unsupported trailing TLVs are refused. Bytes
after a Terminator TLV are padding and need not be zero. Short
lengths are 0–254; extended FF lengths must be at least 255 and fit the mapping.
`TNdefCodec` decodes exact message bytes to owned records; Text/URI and other RTDs
use the existing `TNdefRecords` helpers. Read-only initialized mappings can be read.

`WriteMessageVerified(ExpectedUid, ExpectedMemory, Ndef)` validates the whole
mapping, capacity, locks and every affected phase before the first write. It:

1. Publishes a zero length and independently verifies that image.
2. Writes/verifies the payload, extended length bytes and tail, keeping the length
   marker zero and preserving CC, prefix/control TLVs, UID, locks and reserved bytes.
3. Publishes the final length marker last and verifies the complete final image,
   decoded message and session release.

An empty byte array clears an existing message. An identical message is an acquired
verified no-op. Writes are not physically atomic: power loss during an eight-byte
programming operation can affect neighboring bytes. A failed update must be
inspected explicitly; normal reads do not invent a recovered message.

```pascal
uses ERD.Card.Contactless.Topaz, ERD.Card.Contactless.ACR122.Topaz,
  ERD.Card.Contactless.Type1.Ndef, ERD.Card.Ndef, ERD.Card.Ndef.Records;

// Card.Transport belongs to a connected, explicitly selected PC/SC reader.
Reader := TType1NdefCardReader.Create(nil);
try
  Reader.Model := tmTopaz512;
  Reader.Session := TAcr122TopazSession.Create(Card.Transport);
  Before := Reader.ReadMessage;
  SetLength(Records, 1);
  Records[0] := TNdefRecords.Text('Welkom', 'nl');
  After := Reader.WriteMessageVerified(Before.Card.Uid, Before.Card.Memory,
    TNdefCodec.Encode(Records));
finally
  Reader.Free;
end;
```

## VCL demo and boundaries

`examples/vcl/topaz/TopazDemo.dproj` owns its direct TForm and editable DFM. It
contains reader discovery/selection, native reader/card presence events, model and
acknowledgement choices, full snapshot/lock export, byte-range reads, verified raw
writes, parsed NDEF reads and verified NDEF replace/clear. UID and full-memory
preimages are shown and exportable in the demo. Writes require acknowledgement.

Not implemented: card formatting, CC/control-layout mutation, arbitrary Type 1
chips/control layouts, permanent lock/OTP/UID programming, other native reader
protocols or recovery of interrupted updates. A custom reader can implement
`ITopazSession`; this does not imply every PC/SC/NFC reader can access Topaz.

## Protocol references and supplemental checks

Protocol facts were reviewed on 2026-10-09 against:

- NXP **UM0701-02, PN532 User Manual, Rev. 02**, Jewel InListPassiveTarget and
  InDataExchange command examples, plus RFConfiguration/ReadRegister/WriteRegister.
  Reviewed PDF SHA-256:
  `1826ce9f8e55ff43a8178fdd644a47c136160fc08cec16f38065796b0c27dd6f`.
- [NXP PN532/C1 datasheet, Rev. 3.6](https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf),
  CIU Command/CommIRq/Error/FIFO/Control/BitFraming/ManualRCV/TxMode/RxMode registers.
  Reviewed PDF SHA-256:
  `46c4f04c44a36dfded8088e62cbcfe8cd3f785c460bb14f161ce0160ef84822d`.
- [nfcpy Topaz profiles](https://github.com/nfcpy/nfcpy/blob/master/src/nfc/tag/tt1_broadcom.py)
  for exact HR/profile identification and canonical initialized mapping. Reviewed
  file SHA-256 `3f16d86dde091196f5530a0e823f070939de746c5d300c4dcdda8a3f8ce088e7`.
- [nfcpy PN532 driver](https://github.com/nfcpy/nfcpy/blob/master/src/nfc/clf/pn532.py)
  for independent evidence of the firmware limitations and native CIU framing.
  Reviewed file SHA-256 `afdb485b6e74aa0efe67f7b9715b56c7616b403b55fce501ae9c138a6b668cc4`.
- [Proxmark3 Topaz inspection](https://github.com/RfidResearchGroup/proxmark3/blob/master/client/src/cmdhftopaz.c)
  for static lock-block indexing and dynamic lock/control interpretation. These
  references were used to check protocol facts; their implementation source is not
  distributed or copied into this library.

`tests/contactless/Topaz.Vectors.pas` holds independently authored literal host/RF
fixtures. `Topaz.Tests.dpr` exercises lock maps, CRC-B, every parity/data/CRC bit,
CIU transcripts, byte-write dialects, every I/O/cleanup failure, stale preimages,
metadata preservation, raw user ranges, capacity and length-last updates. Family
executor tests cover input rejection before acquisition and parsed/exported results.
These checks supplement Delphi/physical-reader validation; they do not certify a
reader firmware or physical card combination.
