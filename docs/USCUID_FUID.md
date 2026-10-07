# USCUID/GDM and factory FUID UID profiles

`TRawUidProgrammer.ProgramUscuidUid` adds explicit USCUID/GDM wakeup and UID-source
profiles. `TContactlessCardReader.ProgramFuidUidOnce` provides separate semantics
for a caller-identified four-byte factory FUID variant. Both are included in
`ERDCardContactless`; all visible declarations have English Delphi XML documentation.
The implementations use synthetic exact command transcripts. Physical card/reader
compatibility, Delphi builds and RAD Studio Help Insight remain to be verified.

## USCUID/GDM: preserve an existing configuration

Add `ERD.Card.Contactless.Raw`, `ERD.Card.Contactless.UID.USCUID` and the selected
raw-reader adapter to uses. The backend must retain RF selection and support manual
CRC-A, exact bit counts, explicit RF timeouts and exclusive sessions as described in
[RAW_UID.md](RAW_UID.md). The ACR122U/PN532 adapter is exercised through a complete
synthetic GDM hidden-seven-byte programming transcript. Configure automatic RATS
suppression when the existing card SAK advertises ISO 14443-4; see
[the adapter setup](GEN3_GEN4_UID.md#reader-setup).

```pascal
ResultData := Programmer.ProgramUscuidUid(
  uwsGdm, uulHiddenF0F1_7, RequestedUid);
```

Here `Programmer: TRawUidProgrammer` has an explicitly configured `Reader`,
`ResultData: TUscuidUidResult`, and `RequestedUid: TBytes` contains seven bytes.
This is an explicit write operation when executed; no examples or tests access
physical cards during validation.

| Existing layout | Configuration byte9 | UID source and write |
| --- | --- | --- |
| `uulPublic4` | 00 or FF | Public block0, four UID bytes followed by XOR BCC; `A0 00` |
| `uulHiddenF3_4` | 69 | Hidden block1, four UID bytes/BCC/final SAK; `A8 01`; public block0 unchanged |
| `uulHiddenF0F1_7` | 5A, C3 or A5 | Hidden block0 cascade layout; `A8 00`, then `A0 00` to mirror seven public UID bytes |

Each layout can use `uwsGen1a` (seven-bit40 then byte43) or `uwsGdm`
(seven-bit20 then byte23). The API never probes alternate wakeups or changes the
configured source to match the requested UID. Four-byte UID0 and seven-byte UID3
cannot equal cascade tag88.

The operation:

1. Validates style, layout and requested UID before acquisition, then freshly selects
   the existing UID, requiring the selected layout's size.
2. Sends HALT with CRC-A, requires an explicit RF timeout, then sends the chosen
   wakeup with exact seven/eight-bit framing and four-bit ACKs.
3. Reads configuration using `E0 00`. Its response must be exactly sixteen bytes
   plus valid CRC-A. Bytes0/1 must be7AFF, byte2 must be00 for Gen1a or85 for GDM,
   byte9 must match the table, and byte10 must be00 (persistent storage, shadow off).
   Partial configurations, disabled wakeup, random-UID mode and unsupported modes
   fail before any manufacturer write.
4. Reads public block0 with `30 00` and, when required, hidden block0/1 using
   `38 00`/`38 01`. Each read validates full-byte framing, length and CRC.
   The **configured source** UID must match fresh selection. A public block's
   embedded UID may differ from an active hidden UID, and is not used to guess it.
5. Validates stored BCCs. Hidden seven-byte source bytes0..11 are CT88,
   UID0..2, BCC0, SAK0, UID3..6, BCC1, SAK1. SAK0 must indicate another cascade;
   SAK1 must not. Hidden F3's SAK byte5 must indicate the final cascade.
6. For a matching UID, returns the actual original snapshots without writes or
   mirror corrections. Otherwise prepares independent source bytes, retaining SAK,
   metadata and hidden tails. Each write consists of its command/CRC ACK handshake
   and sixteen data bytes/CRC with a second ACK. Seven-byte mode also replaces
   public bytes0..6, preserving **every byte7..15**.
7. Cycles RF and freshly selects the requested UID, repeats the chosen wakeup,
   rereads and compares **all configuration and public/hidden block bytes**. This
   detects transient writes and metadata/configuration changes after reactivation.
8. Returns only after successful session release. The result contains explicit
   style/layout, independent previous/requested UIDs, unchanged configuration and
   full public/hidden blocks; `ActiveUidVerified=True`. Hidden data is empty for
   public mode. Ordinary record assignment shares arrays.

Seven-byte programming uses two EEPROM writes and is not atomic. From the first
write handshake onward, every failure is `EContactlessWriteUncertain`, including
NAK, RF timeout, malformed framing/CRC, partial writes, stale selection, altered
configuration/metadata and release failure. Only the original error class is
retained; a primary failure wins over cleanup. Inspect the actual card before any
further programming. No replay, rollback, partial success result or configuration
write is attempted.

The profile does not implement `E1` configuration writes, personalization changes,
wipe/seal/unfuse commands, Magic Auth/Crypto1 wakeup, Gen1b, partial eight-byte
UFUID/ZUID/PFUID configurations or their command variants. Those require distinct
profiles. It does not change CUID/direct-write, shadow, nonce, signature or SAK
configuration to make the card fit. UMC/GTU password-bearing `CF` commands remain
[a separate implemented dialect](GEN3_GEN4_UID.md).

## FUID: one authenticated factory write

Add `ERD.Card.Contactless` and `ERD.Card.Contactless.UID` to uses. Configure an
already connected transport and an explicitly matching reader profile as in
[CONTACTLESS.md](CONTACTLESS.md). Optional `IFuidUidReaderProfile` is separate
from `IGen2UidReaderProfile`; existing profile GUIDs/contracts remain unchanged.
`TPcscStorageProfile` supplies the documented FF D6 command shape, without implying
that a connected card is a supported FUID variant.

```pascal
ResultData := Contactless.ProgramFuidUidOnce(
  RequestedUid, mckA, SectorZeroKey);
```

Declare `ResultData: TFuidUidResult`; target UID is four bytes and the supplied
sector-zero key is six bytes. Key B and an explicit volatile slot are also accepted.
There is no default key. Local key-command overwriting, retained reader key slots
and exclusive caller-thread lifecycle follow the existing contactless contract.

The caller must identify the exact factory FUID variant. UID **AA55C396** is a
precondition, not a detection algorithm or proof of physical fuse state. Changing
it consumes the documented standard direct-write condition. Older revisions may
retain other backdoors; this API neither disables them nor claims permanent
unrewritability or access-controller compatibility.

The method rejects an unchanged factory target, invalid UID/key or missing optional
capability before I/O. In one exclusive transaction it reads the factory UID,
loads the supplied key, authenticates sector zero, reads block0, validates BCC and
requires its embedded UID to be the factory UID. It replaces bytes0..3, recomputes
byte4 as their XOR and preserves bytes5..15. It sends **one** authenticated direct
manufacturer-block write, reads back all sixteen bytes, then retrieves reader UID.

`TFuidUidResult` owns independent previous/requested UIDs and verified block data.
`ActiveUidVerified=True` means the reader also reports the target. False means it
still reports the factory UID: caller-controlled fresh RF activation followed by
`ReadUid` verification is needed before provisioning is complete. The method does
not reset/reconnect during the transaction. A third UID is a verification failure.

A non-factory current UID, including an already provisioned target, is rejected;
this method does not treat a repeated call as a no-op. **Every failure after write
dispatch**, including a denied status, transport loss, malformed success response,
read-back/UID mismatch or transaction release failure, becomes
`EContactlessWriteUncertain`. Do not retry the programming method to reconcile an
uncertain result; inspect/reselect/read the card first. Pre-dispatch errors retain
their original type. No fuse, lock, configuration, raw unlock or replay command is
sent. Ordinary Classic data writers still reject block zero and sector trailers.
Other OTP/OTP2.0 products or arbitrary one-time tags are not inferred from this
factory UID profile.

## Validation and protocol sources

Tests cover all six explicit USCUID layout/wakeup combinations, every byte9 mode,
full/partial configuration checks, shadow rejection, both hidden BCCs and SAK
cascades, complete metadata preservation, unmirrored no-ops, two-write interruptions,
persistent verification and cleanup precedence. A complete ACR122U/PN532 chain
covers seven-bit20/byte23, hidden/public writes, RF reset and restoration.
FUID tests cover dedicated capability, one write, supplied-key buffer ownership,
factory/block preconditions, cached UID state, denied/failed writes, malformed
responses, changed metadata and cleanup. See [VALIDATION.md](VALIDATION.md).

Protocol facts were checked on 2026-10-07 at Proxmark3 commit
`305b259fbe8e582ba0f55d6237d45ad580264e42`. Code was independently written; no
third-party implementation, binary or standards PDF is bundled.

- [Magic-card notes, USCUID and FUID sections](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/doc/magic_cards_notes.md):
  wakeup styles, configuration offsets, hidden layouts, factory UID and direct-write
  condition. SHA-256 `9409de8f160a5124d751915ba237dd33a73f01d76a71afbf3ca942943f282821`.
- [Client USCUID configuration/UID command facts](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/client/src/cmdhfmf.c):
  byte9 modes, A8 hidden writes and A0 public mirror sequence. SHA-256
  `849106f330660b5d18de776984b7050d40dac3dc0b4e0447aa75fc1d7f6b067f`.
  Its probing, configuration rewriting and metadata replacement are not behaviors
  of this independently implemented API.
- [PC/SC Part3 v2.01.09](https://pcscworkgroup.com/Download/Specifications/pcsc3_v2.01.09.pdf)
  and [ACS ACR122U API2.04](https://downloads.acs.com.hk/drivers/en/API-ACR122U-2.04.pdf):
  supplied-key storage command shapes; hashes in [CONTACTLESS.md](CONTACTLESS.md).
- [NXP PN532 user manual](https://www.nxp.com/docs/en/user-guide/141520.pdf):
  manual framing, bounded timing and automatic RATS; hash in [RAW_UID.md](RAW_UID.md).
- [NXP AN10927](https://www.nxp.com/docs/en/application-note/AN10927.pdf):
  ISO14443-A cascade-tag positions and UID lengths.
