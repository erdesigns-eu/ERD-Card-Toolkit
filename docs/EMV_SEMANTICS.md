# Offline EMV semantic decoding

`ERD.Card.EMV.Semantics` is part of `ERDCardEMV`. Its static `TEmvSemanticCodec`
requires no reader, cryptographic provider or payment connection.

- `DecodeBits` accepts **82 (AIP), 9F07 (AUC), 95 (TVR), 9F0D/0E/0F (IAC)**,
  with exact two-/five-byte sizes. It returns every bit, byte/bit position, raw
  state, known/reserved classification and meaning.
- `DecodeCvmList` accepts **8E** with unsigned big-endian binary Amount X/Y and
  ordered two-byte rules. It retains method identifiers, condition codes,
  continue-on-failure and the reserved high bit. Proprietary values are visible
  and labelled, not discarded or executed.

Choose `esv43` or `esv44` explicitly. The default is Book 3 4.4: XDA and biometric
allocations are included. Selecting 4.3 keeps later allocations reserved and uses
its online-PIN meaning. Contactless-reserved AIP bits remain reserved for their
kernel specification, even if set; no universal contactless interpretation is
assumed. IAC flags describe issuer action criteria, not evidence that an error has
occurred. CVM thresholds require application-currency context and are not BCD or
automatically compared against a transaction.

```pascal
Bits := TEmvSemanticCodec.DecodeBits($82, ApplicationData.Aip, esv44);
Cvm := TEmvSemanticCodec.DecodeCvmList(CvmListValue, esv44);
```

The independent `examples/vcl/emvsemantics/EmvSemanticsDemo.dproj` owns a direct
TForm and DFM with tag/version selectors, raw input, reserved/unset-bit filters
and synthetic examples. This offline demo needs no reader combobox.

Tests exhaust every input-byte value and every CVM method/condition/flag
combination, verify unsigned amount boundaries, exact lengths and version changes:
**1,601,944 assertions** with range/overflow checks and no unfreed heap blocks.
These are semantic decoders, not cardholder-verification, risk-management or
SDA/DDA/CDA/XDA authentication engines.

Source: EMV Book 3 4.3/4.4 Annex C, with 4.4 Tables 41–46. The pinned 4.4 document
and checksum are recorded in [CARD_CATALOGS.md](CARD_CATALOGS.md). No CardPeek
lookup tables or source code were copied.
