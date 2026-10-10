# Offline EMV semantic decoding

`ERD.Card.EMV.Semantics` is part of `ERDCardEMV`. Its static `TEmvSemanticCodec`
requires no reader, cryptographic provider or payment connection.

- `DecodeBits` accepts **82 (AIP), 9F07 (AUC), 95 (TVR), 9F0D/0E/0F (IAC),
  9F33 (Terminal Capabilities) and 9F40 (Additional Terminal Capabilities)**,
  with exact two-/three-/five-byte sizes. It returns every bit, byte/bit position, raw
  state, known/reserved classification and meaning.
- `DecodeCvmList` accepts **8E** with unsigned big-endian binary Amount X/Y and
  ordered two-byte rules. It retains method identifiers, condition codes,
  continue-on-failure and the reserved high bit. Proprietary values are visible
  and labelled, not discarded or executed.
- `DecodeCvmResults` accepts **9F34**, exactly three bytes. It returns the last
  reported CVM rule and raw outcome: zero unknown, one failed, two successful;
  all other outcome values remain reserved. Exact method `3F` means no CVM was
  performed, distinct from method `1F` (no CVM required). Method flags and unusual
  method/condition/outcome combinations are retained, never silently repaired.

Choose `esv43` or `esv44` explicitly. The default is EMV 4.4: XDA and biometric
allocations are included. Selecting 4.3 keeps later allocations reserved and uses
its online-PIN meaning. Terminal capabilities use Book 4 Annex A2/A3: 4.4
adds biometric/ECC PIN/XDA allocations that remain reserved under 4.3. The
4.4 output-capability labels include electronic receipt/signature support.
Contactless-reserved AIP bits remain reserved for their kernel specification, even if set; no universal contactless interpretation is
assumed. IAC flags describe issuer action criteria, not evidence that an error has
occurred. CVM thresholds require application-currency context and are not BCD or
automatically compared against a transaction.

```pascal
Bits := TEmvSemanticCodec.DecodeBits($82, ApplicationData.Aip, esv44);
Cvm := TEmvSemanticCodec.DecodeCvmList(CvmListValue, esv44);
CvmResult := TEmvSemanticCodec.DecodeCvmResults(CvmResultsValue, esv44);
TerminalBits := TEmvSemanticCodec.DecodeBits($9F33, TerminalCapabilities, esv44);
```

The independent `examples/vcl/emvsemantics/EmvSemanticsDemo.dproj` owns a direct
TForm and DFM with tag/version selectors, raw input, reserved/unset-bit filters
and synthetic examples. This offline demo needs no reader combobox.

Tests exhaust every input-byte value and every CVM method/condition/flag
combination, every CVM Results method/condition/result encoding, terminal bit
positions and code tables. They verify unsigned amount boundaries, exact lengths
and version changes:
**2,549,439 assertions** with range/overflow checks and no unfreed heap blocks.
These are semantic decoders, not cardholder-verification, risk-management or
SDA/DDA/CDA/XDA authentication engines.

Source: EMV Book 3 4.3/4.4 Annex C, with 4.4 Tables 41–46. The pinned 4.4 document
and checksum are recorded in [CARD_CATALOGS.md](CARD_CATALOGS.md). No CardPeek
lookup tables or source code were copied.

Terminal metadata source: [EMV 4.4 Book 4, October 2022, Annex A2–A4,
Tables 25–33](https://github.com/mvallim/emv-qrcode/blob/8d8ff6fcaac3cf2905e9e659fb6d4cfc4e43cbed/docs/EMV_v4.4_Book_4_Other_Interfaces.pdf),
SHA-256 `8ead1c71713520bdefad12c04811ebc82c87da5895bb467e1a175fd218430694`.
Terminal-reported capabilities/outcomes do not establish card support or verify
that the reported CVM was actually performed. No payment operation is added.
