# Type 4 NDEF access

`ERD.Card.Contactless.Type4.Ndef` supplies a pure CC/APDU codec and the non-visual
`TType4NdefCardReader`. It is included in `ERDCardContactless.dpk`; add `src/core`
and `src/contactless` to the unit search path. Add `src/pcsc` for the existing
Windows `TSmartCardReader` adapter. The component uses ordinary ISO 7816 APDUs
through `ICardTransport` and requires `ICardTransaction`; no storage pseudo-APDU
or raw seven-bit RF profile is involved.

This implements access to an already existing public NDEF application. It can
operate on a correctly preformatted DESFire NDEF application, without implementing
DESFire native authentication, file creation, application management or secure
messaging. EMV and national eID applications remain separate protocols.

## Supported mappings and limits

| Setting | Supported behavior |
| --- | --- |
| Application selection | Explicit 1.0 AID `D2760000850100`, or default 2.0 AID `D2760000850101` |
| SELECT application | P1=04, P2=00; 1.0 without Le, 2.0 short Le=256 with optional bounded FCI |
| SELECT file | CC `E103` or resolved ordinary NDEF ISO identifier; P2=00 for 1.0, P2=0C for 2.0; no Le |
| CC mapping version | Exact 10/20 hexadecimal, matching the selected application dialect |
| CC length | 15..4096 bytes, exactly matching CCLEN; first NDEF descriptor at offset seven |
| Descriptors | Tag 04, length six, at most sixteen distinct ordinary NDEF files |
| NDEF file size | 5..32767 bytes including two-byte NLEN; maximum message bytes 32765 |
| Reads | Short READ BINARY, 15-bit offsets; chunks clamped by MLe and local `MaxReadChunk` (15..256) |
| Writes | Short UPDATE BINARY, chunks clamped by MLc and local `MaxWriteChunk` (2..255) |
| Access | Read access zero for message reads; both access bytes zero for writes |

Mapping 3.x, unknown mapping minor versions, extended tag-06/ENLEN descriptors,
extended-offset B1/D7 commands, extended APDUs, proprietary authentication and
formatting are explicitly outside this implementation. A CC advertising MLc=1 can
be inspected/read, but writes are refused: both NLEN bytes must fit one update.
No application, mapping dialect or reader fallback is attempted after a failure.

The CC decoder validates CCLEN, MLe (at least fifteen), MLc (at least one), mandatory
descriptor position/length, reserved identifiers, file sizes, access RFU values and
duplicate ordinary NDEF identifiers. Proprietary access bytes 80..FE and write FF
are exposed for inspection, without being treated as public access. Unknown optional
single-byte-length TLVs are bounds-checked and preserved in `RawBytes`; their
semantics are not implemented. NULL/terminator and extended length markers in CC
TLVs are refused. These CC TLVs are distinct from the Type 2 storage mapping.

`ReadCapabilities` selects the configured application, selects E103 and bootstraps
with the mandatory minimum fifteen-byte READ. It acquires any remainder in bounded
MLe chunks before parsing the complete CC. A reader advertising more than 256/255
does not automatically enable extended APDUs: local short limits still apply.

For a one-file CC, `AFileId=0` resolves the single descriptor. With multiple NDEF
files, specify the ISO identifier explicitly. A requested missing/reserved identifier
or ambiguous default raises `EType4NdefError`; the component never silently chooses
the first file. ISO identifiers are not DESFire native file numbers.

## Using the component

```pascal
uses ERD.Card.PCSC.Reader, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Ndef, ERD.Card.Ndef.Records;

var
  Card: TSmartCardReader;
  Ndef: TType4NdefCardReader;
  Snapshot: TType4NdefSnapshot;
  Message: TNdefMessage;
begin
  Card := TSmartCardReader.Create(nil);
  try
    Ndef := TType4NdefCardReader.Create(nil);
    try
      Card.ReaderName := ApplicationReaderName; // Caller-selected exact Unicode reader name.
      Card.Connect;
      Ndef.Transport := Card.Transport;
      Ndef.ApplicationVersion := t4av2;
      Snapshot := Ndef.ReadMessage; // Requires a single-file CC.
      SetLength(Message, 1);
      Message[0] := TNdefRecords.Text('Welkom', 'nl-BE');
      Ndef.WriteMessage(Message); // Explicitly intended replacement of the public message.
      Card.Disconnect;
    finally
      Ndef.Free;
    end;
  finally
    Card.Free;
  end;
end;
```

Declare `ApplicationReaderName: UnicodeString` in the calling application.
`ReadMessage($E104)` / `WriteMessage(Message, $E104)` select a specific descriptor.
`ClearMessage($E104)` publishes NLEN zero; it preserves former payload bytes.
It is not secure erasure. No hardware is opened in the constructor or IDE designer.
Configure and invoke an instance on one thread without reentrancy.

Each call acquires one non-nested exclusive transaction. Selection changes the
active application/file; previous selection is not restored. No RF reset or
disconnect is initiated by this component. Keep the same physical card present;
a host transaction does not prevent someone swapping tags. ISO-DEP framing,
link-layer behavior and reader/driver compatibility belong to the supplied transport.

Message reads validate NLEN against the selected descriptor before allocation,
read exactly that many bytes, decode nonempty messages with the existing bounded
[NDEF codecs](NDEF.md), and reread NLEN. A changed length fails without restarting
or returning a partial snapshot. This detects observed length changes; it does not
prove atomicity, authenticity or prevent same-length changes by a card application.
NLEN zero returns no records; it differs from an encoded empty NDEF record.

Decoded CC bytes, descriptor arrays, message bytes and logical records are
independent of input/transport buffers. Ordinary record assignment shares arrays:
use `CopyBytes` or `TNdefCodec.Clone` before editing assigned copies.

## Verified updates and error behavior

`WriteMessage` encodes the requested records before acquiring hardware. Preflight
selects/acquires the complete CC, resolves a file, requires public read/write access,
checks capacity and MLc, and reads/decodes the existing message. Malformed existing
data requires an explicit separate recovery decision; clearing does not bypass this
validation. Otherwise eligible identical message bytes are a no-op.

For a changed message:

1. If NLEN is nonzero, send one two-byte zero-NLEN update and read it back before
   payload changes. An already observed zero length needs no redundant invalidation.
2. Write payload chunks starting at offset two, bounded by MLc/local limit. Read
   back and compare each whole chunk before continuing; verification may need
   multiple MLe reads when MLc exceeds MLe.
3. Publish nonempty final NLEN in one two-byte update and verify it. Clearing
   needs only the zero-NLEN update.
4. Reselect/read the complete original CC and require identical bytes. Reselect
   the NDEF file, reread/decode the published message, recheck NLEN and compare
   exact requested bytes before releasing the transaction.

The CC file, access bytes, application keys and unneeded bytes after the replacement
are never updated. This is a multi-command operation, **not an atomic update** or
proof of EEPROM persistence across a power cycle. Reads acquire reader-visible
application bytes; dynamic/mirrored application content can fail exact verification.
No vendor-specific mirroring configuration is inspected or changed. Interrupted writes may leave
NLEN zero, partial payload or a published message whose completion was not verified.

Only status 9000 is accepted, with exact response sizes. 61xx, 6Cxx, warnings,
short/oversized data and transport exceptions stop immediately; there is no APDU
replay, GET RESPONSE chaining, reset, automatic rollback or fallback application.
Any failure after the first UPDATE dispatch—including denied status, read-back
mismatch, later selection/CC/message error or transaction-release failure—becomes
`EContactlessWriteUncertain`. Its `OriginalErrorClass` preserves the class name
without copying a potentially sensitive exception message. Stop and inspect current
storage before deciding recovery; absence of a success result is not proof of no write.

Before dispatch, ordinary mapping/status/transport/NDEF exceptions retain their type.
Failed acquisition does not release an unowned transaction. During a failed operation,
release is still attempted without replacing the primary error. A failed release after
successful reading prevents a completed result; after writing it is uncertain.

## Example, validation and sources

`examples/contactless/InspectType4Ndef.dpr` has two modes:

```text
InspectType4Ndef --cc-hex 000F20003A00340406E10401000000
InspectType4Ndef --reader "Exact Windows reader name" --mapping 2 --file E104
```

`--help` and `--cc-hex` need no hardware. Card mode reports only CC/file structure,
message lengths and record counts; it does not display personal payloads, authenticate
or write. Both validation runners build the example, test valid/truncated CC input
and include the runtime package in the Windows Delphi workflow.

`tests/contactless/Type4Ndef.Tests.dpr` uses independent synthetic CC/APDU fixtures
and exact mapping 1.0/2.0 transcripts. Its injected memory backend exercises the
maximum ordinary file, MLe/MLc/local segmentation, Le=256, second-file selection,
complete CC reads, no-op/clear, payload-tail preservation, NLEN coherence and every
partial update and later-command failure. No physical reader or card is accessed.
The [validation record](VALIDATION.md) separates FPC/static results from pending
Delphi package/compiler, IDE Help Insight and physical-card checks. Every visible
API declaration has Embarcadero-style XML comments; these checks do not substitute
for the compiler or NFC Forum interoperability certification.

Protocol facts were researched from these references; third-party implementations
were not copied or bundled:

- [NXP AN11004 Rev. 2.4, MIFARE DESFire as Type 4 Tag](https://www.nxp.com/docs/en/application-note/AN11004.pdf),
  SHA-256 `8c3b4f6b905b95d9205dc53a1f460a27848a5041a62367b053ac893a9ae9d6ba`:
  ISO command boundary, CC/file identifiers, public NDEF access and mapping 2.0
  MLe=003A/MLc=0034. The test file size 256 is synthetic.
- [nfcpy 1.0.4 Type 4 implementation](https://github.com/nfcpy/nfcpy/blob/v1.0.4/src/nfc/tag/tt4.py),
  SHA-256 `443e967f46c10fd2aa8bf250949af076556352fcd833db7b78418dd406ecf8c8`:
  application AIDs, version-specific SELECT FILE dialects, CC/NLEN framing and
  read/update segmentation. Its automatic probing, link-layer retries and broader
  extended-descriptor behavior are not adopted by this API.
