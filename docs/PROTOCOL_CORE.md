# ATR and BER-TLV core

Both codecs depend only on the RTL. They decode binary `TBytes` and never open a
reader or send commands. All public declarations use Delphi XML documentation;
see [the Help Insight standard](API_DOCUMENTATION.md).

## ATR

```pascal
uses System.SysUtils, ERD.Card.Bytes, ERD.Card.ATR;

var
  Info: TAtrInfo;
begin
  Info := TAtrCodec.Decode(HexToBytes('3B800181'));
  // TS = 3B, one interface group, T=1, validated TCK = 81.
end;
```

The codec validates TS, declared interface and historical bytes, the 33-byte
limit, mandatory TCK and absence of trailing data. XOR from T0 through TCK must
be zero whenever a TD advertises a nonzero protocol, including global-interface
T=15. T=15 is excluded from the transmission-protocol set. If no transmission
protocol is advertised, `Protocols` contains implicit T=0.

3B and 3F select direct/inverse convention. Supply logical bytes as returned by
PC/SC; raw electrical bit inversion/reversal is outside this API. Historical bytes
remain uninterpreted. ATR identification and card capability interpretation belong
to separate profiles/catalog providers. `ERD.Card.ATR.Catalog` supplies a small
immutable, source-attributed hint catalog; it validates the complete ATR before
matching and returns all applicable hints. See [the catalog guide](CARD_CATALOGS.md).

`TryDecode` returns false with a cleared `TAtrInfo` and structured `TAtrError` on
syntax failure. `Decode` raises `EAtrFormatError` containing the same details.
Error offsets are zero-based; a missing byte uses the input length. Successful
decoding returns independent arrays, but ordinary record assignment shares them.

## BER-TLV

```pascal
uses System.SysUtils, ERD.Card.Bytes, ERD.Card.TLV;

var
  Document: TTlvDocument;
  Wire: TBytes;
begin
  Document := TTlvCodec.Decode(HexToBytes('E1099F0206000000000100'));
  try
    // One constructed E1 root containing the primitive EMV identifier 9F02.
    Wire := TTlvCodec.Encode(Document);
  finally
    Document.Free;
  end;
end;
```

Tags are encoded byte identifiers, not ASN.1 numeric tag numbers. This permits
EMV identifiers such as 9F02. The codec validates identifier continuations,
definite lengths and constructed child boundaries. It does not validate a schema,
EMV field lengths/types or an issuer's tag dictionary.

`TTlvDocument` owns its roots and descendants. Indexed roots/children are borrowed:
do not free them and do not retain them after their owner is freed. `Clone` creates
a deep copy owned by the caller. Explicit document/constructed-node constructors
also clone supplied nodes; they never take ownership. Primitive constructors copy
their tag/value inputs, and Tag/Value properties return independent buffers.
Free any previous document before reusing a `TryDecode` output variable.

Encoding produces minimal definite lengths with no padding. Nonminimal definite
input lengths are accepted and normalized; indefinite lengths are rejected.
Optional 00/FF padding between nodes, including within constructed values, requires
`AllowPadding := True`. Padding never removes bytes from a primitive value.
Preserve the original wire bytes separately for signature verification or any
operation requiring an exact byte representation.

Default limits are depth 32, 10000 total nodes, one MiB of input and 32 tag bytes.
Obtain an initialized options record with `DefaultTlvOptions`, then change only
the desired fields and call the options overload of `TryDecode`. Root depth is
one. A containing-span boundary cannot be crossed even when extra bytes follow
the parent. Hard bounds of depth 256 and one million nodes also apply to cloning
and explicit construction; buffers must fit in `MaxInt`.

Syntax/limit errors return false, nil document and `TTlvError`. The throwing
wrapper raises `ETlvFormatError`. Offsets are zero-based, the containing-span end
for missing bytes, or minus one for options/construction failures without a
position. Allocation failures can propagate. Partial trees are freed before failure
is returned. Error messages contain categories and offsets, not input card data.

## Verification boundary

The Pascal regression programs cover successful vectors, every one-byte input,
truncated constructed prefixes, length transitions, 32-byte tags, depth 256,
broad node limits, ownership and failed-construction cleanup. FPC runs range,
overflow and heap checks. Its warning that the internal node constructor should
be public reflects the intentional private constructor used by the decoder;
external callers use `CreatePrimitive` or `CreateConstructed`.

The core static profile checks the selected source files and XML-documentation
coverage. Neither these scripts nor FPC establish Delphi compatibility or actual
Help Insight rendering. The Windows Delphi scripts/package and target IDE still
need verification; the codecs have not been tested with physical readers/cards.
