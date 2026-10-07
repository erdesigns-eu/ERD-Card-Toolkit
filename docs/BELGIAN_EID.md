# Belgian eID public-file reader

`TBelgianEIDReader` is a non-visual RTL component. Add `src/core` and `src/eid`
to the unit search path; add `src/pcsc` when using `TSmartCardReader` on Windows.
The optional `ERDCardEID.dpk` runtime package requires `rtl` and `ERDCardCore`.
It does not require PC/SC, VCL, a vendor SDK or the Belgian middleware: a custom
`ICardTransport` can supply the bytes.

The implementation targets the common public-file interface documented for the
**Belpic 1.7 and 1.8 contact applets**. These are specification targets, not a
hardware compatibility certification. Selecting their common AID does not detect
the generation, establish authenticity or prove the file contents are genuine.
Contactless PACE, PIN authentication, private-key signing, photo/signature/hash
verification and certificate-chain validation are separate future capabilities.
Real Delphi/Windows/card testing is still required for both profiles.

## Reading a card

```pascal
uses ERD.Card.PCSC.Reader, ERD.Card.EID.Data, ERD.Card.EID.Reader;

var
  Card: TSmartCardReader;
  Eid: TBelgianEIDReader;
  Data: TBelgianEidData;
begin
  Card := TSmartCardReader.Create(nil);
  try
    Eid := TBelgianEIDReader.Create(nil);
    try
      Card.ReaderName := SelectedReaderName; // An exact discovered/configured name.
      Card.Connect;
      Eid.Transport := Card.Transport;
      Data := Eid.ReadCard; // Identity, address and photo by default.
      // Data.Identity.Surname, Data.Identity.GivenNames, Data.Address.PostalCode...
      // Data.Photo contains the JPEG bytes; the application decides how to use them.
      Card.Disconnect;
    finally
      Eid.Free;
    end;
  finally
    Card.Free;
  end;
end;
```

Select groups explicitly when necessary:

```pascal
Data := Eid.ReadCard([esIdentity, esAddress, esPhoto, esSignatures, esCertificates]);
```

The component does no hardware work in its constructor. Configure and call it on
one application thread; it is not reentrant. Every read selects the Belpic applet
and changes the current file. `UseTransactions=True` requires `ICardTransaction`
on the assigned transport, which the PC/SC session implements. The entire operation
acquires one transaction and releases it leaving the card unchanged. Transactions
cannot nest. Set `UseTransactions=False` only when the caller provides exclusive
access for the complete operation, for example through an external transaction.

Transport errors propagate without replay, reset or reconnection. A failure returns
no partial result. When both reading and transaction release fail, the original read
exception wins; a release error after a successful read propagates. Card status
errors use `EBelgianEidStatusError.StatusWord`; parser/protocol errors use
`EBelgianEidError`. Malformed APDU responses use `EApduFormatError`. Library error
messages do not contain personal data or APDU contents.

## Data and ownership

Identity exposes common values directly, including card number, binary chip number,
national register number, Unicode names, nationality and birth-date text. National
numbers, postal codes, document types and special statuses remain strings, preserving
leading zeroes and future codes. Dates remain their original localized text; a
year-only or partially known birth date must not become an invented complete date.
Hash bytes do not assume one generation's algorithm or length.

`Identity.Data` and `Address.Data` retain every field, including unknown tags,
original order, exact raw bytes and the encoded length before zero padding. Use
`TEidIdentityTag` / `TEidAddressTag` with `Ord` for other values:

```pascal
WorkPermit := Data.Identity.Data.GetText(Ord(eitWorkPermit));
HasWorkPermit := Data.Identity.Data.HasField(Ord(eitWorkPermit));
```

Declare `WorkPermit: UnicodeString` and `HasWorkPermit: Boolean` in the caller.
`HasField` distinguishes missing tags from present empty values. MemberOfFamily
is a presence-only field with zero-length data. Structure versions and binary
identifiers/hashes use `GetBytes`, not `GetText`. Known identity/address text is
strictly checked for UTF-8, including optional fields. Unknown tags stay binary.
This is a structural decoder, not a mandatory-field or semantic identity validator.

Results are managed records owned by the caller; there is no object to Free.
Decoding copies inputs and getters copy byte values. Raw, parsed and convenient
binary fields have independent buffers. **Ordinary record assignment shares
dynamic arrays**, including nested Fields and Certificates arrays. Clone the array
and its nested byte arrays before editing an assigned copy. Input mutation during
decoding and aliasing decoder input with its output data are unsupported.

`Photo` preserves the file bytes and checks the JPEG start marker, without decoding
image dimensions or pixels. A VCL consumer can load it with its own `TJPEGImage`
and `TMemoryStream`, keeping the library independent of VCL:

```pascal
// Consumer units: System.Classes, Vcl.Imaging.jpeg, Vcl.ExtCtrls.
Stream := TMemoryStream.Create;
try
  Stream.WriteBuffer(Data.Photo[0], Length(Data.Photo));
  Stream.Position := 0;
  Jpeg := TJPEGImage.Create;
  try
    Jpeg.LoadFromStream(Stream);
    Image.Picture.Assign(Jpeg);
  finally
    Jpeg.Free;
  end;
finally
  Stream.Free;
end;
```

This snippet follows a successful read including `esPhoto`. Declare Stream and
Jpeg as their corresponding classes; Image is the application's existing TImage.
Image dimensions should come from the JPEG rather than a fixed assumed card size.
Identity/address signatures retain their exact file bytes, including any padding.
Raw address padding and its encoded length remain available for a later verification
implementation; merely reading these files makes no authenticity assertion.

## Files and protocol

| Group | Directory | Elementary files |
| --- | --- | --- |
| Identity / address | `3F00/DF01` | `4031` / `4033` |
| Photograph | `3F00/DF01` | `4035` |
| Identity / address signatures | `3F00/DF01` | `4032` / `4034` |
| Authentication / signing certificates | `3F00/DF00` | `5038` / `5039` |
| Citizen CA / root CA / national register certificates | `3F00/DF00` | `503A` / `503B` / `503C` |

Applet selection uses AID `A00000003029057000AD13100101FF` and `00 A4 04 0C`.
Each file is selected through MF, DF and EF identifiers with `00 A4 02 0C`.
No application selection or status handling is added to the generic transport.

Identity/address use **simplified TLV**, not BER: one-byte tag, then additive
length octets (`FF 00` = 255; `FF FF 00` = 510). The separate eID codec rejects
duplicates, truncated values/lengths and misplaced version tags. Trailing zero
padding is ignored for decoding and retained in raw bytes. Parsing is bounded to
32768 bytes and 256 unique tags.

Reads use `00 B0` with a 15-bit offset and short Le; chunk size defaults to 248 and
can be 1..256. One `6Cxx` correction per read/GET RESPONSE APDU is allowed within
the original request bound. `6C00` denotes 256. `61xx` output is collected with
GET RESPONSE, bounded by the read request and 32 exchanges. This applies only to
the eID read commands; selectors and arbitrary transport commands are never replayed.

Successful data advances the offset by the actual bytes received. Short successful
blocks do not by themselves prove EOF. A data-free `6B00` means EOF only after
some file data was read; at offset zero it remains an error. Zero-length success,
error statuses carrying data, inconsistent lengths and repeated corrections fail.
Other warning/error statuses, including `6282`, are not silently accepted by this
documented profile. A configurable file limit requires a one-byte EOF probe at that
limit. Reaching offset 32768 is rejected because the probe cannot be represented;
the reader never sets READ BINARY's offset high bit or silently truncates a file.

## Certificates and examples

When requested, Certificates contains five records in `TEidCertificateKind` order.
Only `6A82` on the certificate EF means `ecsMissing`; missing MF/DF and other card
errors fail the operation. All-zero files mean `ecsEmpty`, representing an unissued
certificate. Otherwise `ecsPresent` requires a nonempty, canonically length-encoded
DER SEQUENCE envelope with only zero padding. `DerData` excludes that padding;
`RawData` preserves it. X.509 contents, trust, validity and chain completeness remain
unchecked. Newer additional certificates such as the RRN CA are outside this initial
five-file profile. No certificate array is created when the group is not requested.

`examples/eid/ReadBelgianEid.dpr` prints names/address and can save the photograph
to an explicitly supplied output path. `--help` performs no hardware work. The
synthetic tests exercise real Pascal code with exact command transcripts, strict
UTF-8, additive lengths, DER envelopes, optional files, transaction cleanup,
partial failures, 61xx/6Cxx and EOF/buffer/offset limits. They contain no real
identity, bank, certificate or photograph records.

## Protocol sources

Reviewed on 2026-10-07 in the official [Fedict eID middleware documentation](https://github.com/Fedict/eid-mw/tree/5b2d101d09fcdb550098de1196cd64f82b431744/doc/sdk/documentation), pinned to commit
`5b2d101d09fcdb550098de1196cd64f82b431744`:

- [Belpic 1.7 reference manual](https://github.com/Fedict/eid-mw/blob/5b2d101d09fcdb550098de1196cd64f82b431744/doc/sdk/documentation/Applet%201.7%20eID%20Cards/Public_Belpic_Applet_v1%207_Ref_Manual%20-%20A01.pdf): AID and SELECT FILE / READ BINARY / GET RESPONSE.
- [Belpic 1.8 reference manual](https://github.com/Fedict/eid-mw/blob/5b2d101d09fcdb550098de1196cd64f82b431744/doc/sdk/documentation/Applet%201.8%20eID%20Cards/Public_Belpic_Applet_v1%208_Ref_Manual_v1%20.pdf): corresponding public command/status definitions.
- [Card content v5.4](https://github.com/Fedict/eid-mw/blob/5b2d101d09fcdb550098de1196cd64f82b431744/doc/sdk/documentation/Applet%201.8%20eID%20Cards/Belgian%20Electronic%20Identity%20Card%20content%20v5_4.pdf): file identifiers, additive TLV, JPEG, signed files and padded/unissued DER certificates.
- [Identity/address file v5](https://github.com/Fedict/eid-mw/blob/5b2d101d09fcdb550098de1196cd64f82b431744/doc/sdk/documentation/Applet%201.8%20eID%20Cards/ID_ADRESSE_File_applet1_8_v5.pdf): tags 00..1F and address field definitions.

The implementation is independently written from protocol facts. Middleware code
and PDFs are not copied or bundled as dependencies. Their existing licenses remain
with the source project; this repository's redistribution-license decision is pending.
