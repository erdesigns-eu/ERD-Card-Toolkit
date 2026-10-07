# Raw RF UID programming

`TRawUidProgrammer` in `ERD.Card.Contactless.Raw` adds actual programming paths for
caller-identified **four-byte Gen1a**, **unsealed four-byte UFUID using Gen1a wakeup**,
and **reprogrammable seven-byte Ultralight/NTAG-style DirectWrite** cards. These
protocols and the concrete ACR122U adapter are implemented and tested with synthetic
transcripts. Physical card/reader/driver compatibility still needs validation.
They are separate from the existing authenticated Gen2/CUID storage operation.

The optional adapter is `TAcr122RawReader` in `ERD.Card.Contactless.ACR122`. Both
units are included in `ERDCardContactless.dpk`; its dependencies remain RTL and
CardCore. Source-based use needs `src/core`, `src/contactless` and, for the Windows
PC/SC transport, `src/pcsc` on the unit search path. All visible API declarations
have Embarcadero-style English XML documentation.

## Reader contract and lifecycle

`IRawContactlessReader` makes raw RF available independently of a reader's storage
pseudo-APDUs. Other reader adapters can implement this interface without rewriting
the card programming sequence. A backend must provide:

- One exclusive, non-nesting session, retained RF selection and one caller thread.
- Fresh Type A selection after cycling the RF field, returning the selected UID.
- Explicit outgoing and incoming bit counts, including seven-bit commands and
  four-bit acknowledgments. Treating an acknowledgment as an eight-bit byte fails.
- Manual CRC-A bytes, bounded RF timeouts, no automatic frame retries or RF resets
  between exchanges, and independent response buffers.
- Cleanup that clears temporary card unlock state and attempts to release
  exclusivity even when framing restoration fails.

`TAcr122RawReader` targets the documented **ACR122U PICC direct-transmit/PN532**
dialect, `FF 00 00 00 Lc` followed by a PN532 command. It requires an already connected
`ICardTransport` supporting `ICardTransaction`; PC/SC support alone is insufficient.
There is no SCardControl/escape fallback, automatic device probing, or claim that
every ACR-branded reader uses this dialect. An incompatible reader fails explicitly.

`BeginSession` acquires the transaction and configures PN532 RF timing to 102.4 ms
for ATR response and 409.6 ms for non-DEP response. Communication retries are zero;
passive activation uses one attempt. These reader settings remain until hardware
reset or deliberate reconfiguration: dedicate the reader to this adapter while it
is in use. They bound reader RF operations, not an arbitrary blocked USB/driver call.

`Activate` restores prior temporary framing, switches RF off, waits 10 ms for power-down, switches RF on and uses
`InListPassiveTarget(1, Type A 106 kbps)`. It validates target/UID/ATS lengths and
then saves `CIU_TxMode` (6302), `CIU_RxMode` (6303) and `CIU_BitFraming` (633D).
Raw exchanges disable CRC generation/checking, align reception at bit zero and
set `TxLastBits` explicitly. `InCommunicateThru` sends each frame once;
`CIU_Control.RxLastBits` (633C) determines the exact received bit count. Only PN532
RF status 01 maps to `TimedOut=True`; other failures stay failures.

`EndSession` restores saved framing without replaying the StartSend strobe,
switches RF off to clear unlock state, and releases the transaction. A restoration
failure still attempts RF-off and release; the primary error wins over cleanup
errors. The destructor is best effort; explicit release is the observable path.
After cleanup failure, inspect/reset/reconfigure the reader before further use.
After a completed raw operation the field is off; subsequent storage/EMV/eID work
needs appropriate reader/card reconnection or activation. Do not run those paths
concurrently with this adapter or attempt to nest a PC/SC transaction around it.
Place exactly one card in the field; selecting at most one target does not establish
the absence of another card in a multi-card field.

## Usage

For an already connected, documented compatible `TSmartCardReader` named
`ConnectedCard`, retain it until after the programmer is freed:

```pascal
uses ERD.Card.Contactless.UID, ERD.Card.Contactless.Raw,
  ERD.Card.Contactless.ACR122;

Programmer := TRawUidProgrammer.Create(nil);
try
  Programmer.Reader := TAcr122RawReader.Create(ConnectedCard.Transport);
  ClassicResult := Programmer.ProgramClassicUid(crupGen1a, RequestedFourByteUid);
finally
  Programmer.Free;
end;
```

Declare `Programmer: TRawUidProgrammer`, `ClassicResult: TProgrammableUidResult`
and `RequestedFourByteUid: TBytes`. `crupUnsealedUfuid` selects the same volatile
unlock sequence for an identified, still-unsealed UFUID variant. It does not
unfuse a sealed card. No wipe, seal, permanent configuration or fuse command is sent.

For a known reprogrammable Type 2 DirectWrite variant, use
`Type2Result := Programmer.ProgramType2DirectWriteUid(RequestedSevenByteUid)`;
declare `Type2Result: TType2UidResult` and `RequestedSevenByteUid: TBytes`.
This is not a way to change the UID of a normal production Ultralight/NTAG chip.
Write-once clones and variants requiring another unlock/password/configuration
protocol are excluded. The caller identifies the concrete variant; marketing names
and UID length alone cannot establish it.

The examples perform explicit writes if executed. No CLI command containing real
keys or identifier values, card fuse, or physical write was run during development.

## Classic Gen1a and unsealed UFUID

1. Validate the explicit profile and four-byte UID before acquiring a session.
2. Freshly activate; require a four-byte UID.
3. Send `50 00 + CRC-A` (HALT), requiring its expected RF timeout. A USB/PC/SC
   exception is not mistaken for that timeout.
4. Send seven-bit `40`, then eight-bit `43`, requiring a four-bit ACK value A for
   each. Do not send the `41` wipe command or USCUID configuration/fuse commands.
5. Read block zero using `30 00 + CRC-A`. Validate all eighteen received bytes,
   CRC-A and the four-byte layout's BCC; require its UID to match fresh selection.
6. Prepare sixteen bytes, replacing UID0..3 and BCC4 while preserving bytes5..15.
   A matching UID returns a verified no-op without a write.
7. Otherwise send `A0 00 + CRC-A`, require ACK, send sixteen prepared bytes plus
   CRC-A and require ACK. No sector key is guessed or searched.
8. Read and compare all sixteen bytes, freshly reactivate and require the requested
   RF UID. Return the result only after successful session release.

`TProgrammableUidResult.ActiveUidVerified` is true on every returned raw result.
An old UID after **fresh** selection is a verification failure, not the cached UID
condition which the Gen2 PC/SC operation can report. Card-selected SAK/ATQA behavior
still depends on the particular clone. Existing manufacturer metadata is preserved,
not reconfigured to imitate another chip type.

## Type 2 DirectWrite

The operation freshly selects a seven-byte UID and reads pages0..3 with
`30 00 + CRC-A`. It checks BCC0=`88 XOR UID0 XOR UID1 XOR UID2` and
BCC1=`UID3 XOR UID4 XOR UID5 XOR UID6`, and verifies the pages against the selected UID.
`TRawUidCodec` exposes page preparation and validation for offline tools.

The prepared snapshot replaces UID bytes and both BCC bytes. Internal byte9,
static-lock bytes10..11 and all OTP/CC bytes in page3 are preserved exactly. Only
pages0,1,2 are written, in that order, with consecutive `A2 page data4 + CRC-A`
commands and four-bit ACKs, without reactivation between writes. The complete
sixteen-byte snapshot is read back and compared before fresh UID verification.
An already matching UID returns a verified no-op without page writes.

**The three-page operation is not atomic.** A failure can leave a mixed UID or
invalid BCC, possibly preventing normal selection. No completed result, rollback,
reset/replay loop or guessed recovery is returned. Use a reader/card-specific
recovery procedure after inspecting the actual state. The ordinary Type 2 user-page
writer remains unchanged and still rejects manufacturer pages.

## Errors and validation

Invalid parameters fail before I/O. Initial UID/checksum/unlock failures release
the session and retain their original error. From the first Classic write-handshake
dispatch or Type 2 page-write dispatch onward, **every failure**, including a NAK,
timeout, bad CRC, read-back mismatch, old/wrong fresh UID or release failure, becomes
`EContactlessWriteUncertain`. It records only the original exception class, not card
data or external exception messages. A native transaction cannot roll back EEPROM.
The component never blindly retries.

The test suite includes CRC-A golden vectors; both cascade checksums; protected
metadata preservation; exact seven/eight-bit transmit and four-bit receive framing;
Gen1a and unsealed-UFUID sequences; no-ops; failed unlocks, handshakes, data writes,
each Type 2 page, read-back, activation and release; exact ACR122/PN532 commands and
a complete programmer-through-adapter transcript. Real cards, Windows drivers,
Delphi packages and Help Insight still require independent checks.

Protocol facts checked on 2026-10-07:

- [ACS ACR122U API 2.04](https://downloads.acs.com.hk/drivers/en/API-ACR122U-2.04.pdf),
  section6.1 PICC direct transmit. Hash recorded in [CONTACTLESS.md](CONTACTLESS.md).
- [NXP PN532 user manual UM0701-02](https://www.nxp.com/docs/en/user-guide/141520.pdf),
  sections7.2.4/7.2.5,7.3.1,7.3.5,7.3.9, register access, RF configuration,
  activation and raw exchange. SHA-256
  `1826ce9f8e55ff43a8178fdd644a47c136160fc08cec16f38065796b0c27dd6f`.
- [NXP PN532/C1 datasheet rev3.6](https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf),
  CIU_Control, CIU_BitFraming, CIU_TxMode and CIU_RxMode register descriptions.
  SHA-256 `46c4f04c44a36dfded8088e62cbcfe8cd3f785c460bb14f161ce0160ef84822d`.
- [Pinned Proxmark3 magic-card notes](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/doc/magic_cards_notes.md),
  Gen1a, UFUID and Ultralight DirectWrite protocol/layout facts. Hash recorded in
  [PROGRAMMABLE_UID.md](PROGRAMMABLE_UID.md). No third-party implementation copied.
- NXP Ultralight/EV1/NTAG datasheet manufacturer-page layouts and AN10927 cascade
  rules, linked in [CONTACTLESS.md](CONTACTLESS.md) and [PROGRAMMABLE_UID.md](PROGRAMMABLE_UID.md).

Gen3/APDU, Gen4 UMC ten-byte layouts, other USCUID unlock/configuration modes,
write-once FUID, LF and UHF remain further concrete profiles. The shared raw-RF
foundation now supplies the bit framing, exclusive lifecycle and fresh selection
needed to add their independent protocols.
