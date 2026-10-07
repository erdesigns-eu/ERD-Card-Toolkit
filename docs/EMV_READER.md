# EMV application-data reader

`TEMVCardReader` is an RTL-only non-visual component in `src/emv`. Add `src/core`
and `src/emv` to the unit search path, plus `src/pcsc` for a Windows reader.
`ERDCardEMV.dpk` requires only `rtl` and `ERDCardCore`; PC/SC and VCL are not
dependencies of the protocol component. Assign a connected `ICardTransport`.

## Application discovery and explicit selection

`DiscoverApplications(edContactPse)` selects `1PAY.SYS.DDF01`, obtains its SFI
and reads directory records through a data-free `6A83` end marker.
`DiscoverApplications(edContactlessPpse)` selects `2PAY.SYS.DDF01` and reads
application templates from the FCI. Only directory SELECT status `6A82` means
`Present=False`; other card errors propagate. There is no guessed AID list or
automatic fallback, and discovery never selects a payment application.

Entries retain their exact AID, label, optional priority and confirmation bit in
directory order. The application decides which explicit AID to use. Nested PSE
DDF directories, scheme-specific contactless kernels, preferred-name code pages,
transaction logs and issuer catalogs are outside this initial common profile.
Flat ADF entries are supported; an unsupported entry fails visibly rather than
returning an apparently complete discovery result.

```pascal
uses ERD.Card.EMV.Data, ERD.Card.EMV.Reader;

Emv := TEMVCardReader.Create(nil);
try
  Emv.Transport := ConnectedCard.Transport;
  Directory := Emv.DiscoverApplications(edContactlessPpse);
  // Choose an exact AID from Directory.Applications according to application policy.
  Data := Emv.ReadApplication(ChosenAid, TerminalValues);
finally
  Emv.Free;
end;
```

Declare Emv as `TEMVCardReader`, Directory as `TEmvDirectoryData`, Data as
`TEmvApplicationData`, ChosenAid as `TBytes` and TerminalValues as `TEmvValues`.
ConnectedCard is an already connected `TSmartCardReader` or equivalent adapter.
Do not automatically choose the first directory entry or treat discovery as
authorization to initiate a payment.

## PDOL and GPO

ReadApplication validates the exact AID returned by FCI, extracts PDOL, sends
GET PROCESSING OPTIONS (GPO), accepts response format 80 or 77 and reads the
complete validated AFL. GPO initiates application processing and may change card
state or counters. The component does not send GENERATE AC, VERIFY PIN, issuer
scripts or payment-completion commands. It is a data reader, not a certified
payment terminal or contactless kernel.

Supply PDOL values explicitly, using tag bytes and exact requested value lengths:

```pascal
SetLength(TerminalValues, 1);
TerminalValues[0].Tag := HexToBytes('9F37');
TerminalValues[0].Value := ApplicationProvidedUnpredictableNumber;
```

This example needs `ERD.Card.Bytes`. The value must be supplied by the application;
the unit does not invent amounts, countries, currencies, capabilities or randomness.
Missing or wrong-sized values fail before GPO. Extra terminal tags are allowed;
duplicate terminal tags are rejected. Empty PDOL produces `8300`. Zero-length
requests consume no bytes and need no input value. PDOL lengths are single-byte
sizes, unlike BER lengths; object 83 uses canonical BER encoding and fits short Lc.
This strict API does not implement a payment terminal's full DOL padding/truncation
and unknown-tag zero-filling policy: callers explicitly supply the intended bytes.

## Data, limits and ownership

The snapshot contains original FCI/GPO data, AIP, AFL, all records and primitive
fields, including unknown/repeated tags. Application records in SFI 1..10 must use
template 70. SFI 11..30 records are retained as opaque issuer bytes. Convenient
fields are optional:

- PAN from tag 5A or Track 2 equivalent tag 57, with leading zeroes retained.
- ExpiryDate from 5F24 as YYMMDD; ExpiryMonth from 5F24 or tag 57 as YYMM.
  A Track 2-only expiry does not invent a day or century.
- CardholderName from 5F20, with a byte-preserving Latin-1 rendering.
- IBAN from 5F53 only when present. An IBAN is not guaranteed on a bank card;
  its checksum and account ownership are not verified.
- Raw Track2Equivalent and its three-digit service code. This is packed EMV
  data, not the magstripe track-wire format.

Known decimal encodings and lengths are checked. Track 2 separators/padding are
validated and PAN/expiry sources must agree. Equal repeats of a known field are
tolerated for inspection; conflicting repeats fail. A payment kernel's stricter
redundant-object/mandatory-field policy is not implemented. Unknown primitive
fields and issuer records remain available rather than being assigned guessed meanings.
No cardholder verification, issuer authenticity, Luhn check, calendar validation,
certificate verification or bank ownership is inferred from parsed values.

Decode/read outputs allocate independent byte buffers. Ordinary record assignment
shares dynamic arrays; deep-copy arrays and nested buffers before modifying an
assigned copy. The standalone DecodeCardFields helper modifies convenient fields
in place and can leave some changed if it raises. The component's ReadApplication
returns a full result only after parsing and transaction release both succeed.

Limits: short APDUs with at most 256 response data bytes, up to three-byte tags,
BER depth 16 / 256 nodes per response, 64 directory applications, 32 directory
record probes by default, 256 AFL records by default and 8192 collected primitive
fields. Configurable record maxima are 255 directory probes and 1024 AFL records.
An unproven directory end fails at its configured limit. AFL reserved bits, file
identifiers, record ranges, authentication counts and overlapping ranges are checked
before reading records. Empty AFL is represented explicitly, including GPO-only data.

## Transactions and status handling

Construction does not touch hardware. Configure and call on one application thread;
the component is not reentrant. UseTransactions defaults to true and requires
`ICardTransaction` for each complete discovery/application sequence. Set false only
when the caller guarantees exclusive access, for example in an externally owned
transaction. Transactions cannot nest. Release leaves the card powered without a
reset. A primary read error wins over a subsequent cleanup error; a release failure
after successful reading propagates.

Every transport failure propagates without replay or reconnection. GPO is sent
once; a GPO `6Cxx` remains a status error instead of replaying initialization.
SELECT/READ RECORD allow one bounded Le correction per APDU. Bounded `61xx`
GET RESPONSE may collect output, including GPO output; total bytes remain within
the original request and at most 32 exchanges. A correction of zero denotes 256.
Error statuses carrying data, repeated corrections and malformed responses fail.
`EEmvStatusError.StatusWord` retains the status; library messages contain no PAN,
IBAN, cardholder data or APDU payloads. APDU/BER errors keep their core exception types.

## Examples, validation and sources

`examples/emv/InspectEmv.dpr` discovers PSE/PPSE or reads an explicitly supplied
AID with empty terminal input. Cards requesting nonempty PDOL values need the
application API instead. The example reports which bank fields are available.
`--help` performs no hardware operation.

Executable Pascal tests use exact synthetic APDU transcripts for both directories,
both GPO formats, PDOL order/lengths, AFL bounds, record 255/SFI 30, optional bank
fields, Track 2 fallback, malformed replies, no GPO replay, GET RESPONSE and cleanup.
Global field limits are exercised across large synthetic snapshots. No actual
payment-card/account capture is committed. Delphi/Help Insight, runtime-package
builds, reader/card hardware and payment-scheme behavior remain unverified.

Protocol facts were checked on 2026-10-07 against **EMV 4.4 Book 3, October 2022**,
sections 5.3/5.4, 6.5.8/6.5.11, 10.1/10.2 and Annex A, available via a
[public specification mirror](https://github.com/mvallim/emv-qrcode/blob/8d8ff6fcaac3cf2905e9e659fb6d4cfc4e43cbed/docs/EMV_v4.4_Book_3_Application_Specification.pdf).
The downloaded PDF SHA-256 was
`06d64d1b85d64a2939b6fd673273f5b8c3a5a37e6931a2488799ccc161c8f8a3`.
The [official EMVCo contact-chip page](https://www.emvco.com/emv-technologies/emv-contact-chip/)
and [specification index](https://www.emvco.com/specifications/) provide current editions.
This implementation is independently written; no standards PDF or external
implementation is bundled. This limited inspection profile is not a claim of
complete EMVCo conformance or certification.
