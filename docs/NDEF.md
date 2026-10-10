# NDEF codecs and Type 2 access

Three RTL-only units are included in `ERDCardContactless.dpk`:

- `ERD.Card.Ndef`: complete-message encoding/decoding, independent buffers and chunk reassembly.
- `ERD.Card.Ndef.Records`: Text, URI, MIME, external and one-level Smart Poster helpers.
- `ERD.Card.Contactless.Type2.Ndef`: CC/TLV mapping, update planning and
  `TType2NdefCardReader`, a non-visual public-memory reader/writer.

Other access layers use the same message codecs: [Type 4 NDEF](TYPE4_NDEF.md)
provides public ISO 7816 files, and [ISO 15693/Type 5](ISO15693_TYPE5.md) provides
initialized public E1/E2 CC/TLV memory with guarded length-last updates.
[FeliCa/Type 3](FELICA_TYPE3.md) now supplies existing version 1.0 attribute/NDEF access. [Protected Type 2 NDEF](TYPE2_MANAGEMENT.md) retains supplied-password authentication during the entire mapping operation. [Topaz/Type 1](TOPAZ_TYPE1.md) supplies initialized Topaz 96/512 mapping with verified user/NDEF writes.

Add `src/core` and `src/contactless` to the Delphi search path. These units need
no VCL, vendor DLL, network connection or design-time package. Only the card
component performs I/O, through an explicitly supplied page profile and transport.
All visible declarations have Delphi XML comments for Help Insight; real IDE
inspection remains part of the [Delphi documentation check](API_DOCUMENTATION.md).

## Messages and record helpers

`TNdefCodec.Decode` consumes exactly one nonempty encoded message. It checks MB/ME,
payload lengths, type/identifier lengths, TNF constraints, continuation TNF six,
identifier/type absence on continuation chunks, incomplete chunks and trailing bytes.
Chunked physical records become one logical `TNdefRecord`; re-encoding deliberately
normalizes them to unchunked records. Unknown TNF five remains opaque. Reserved TNF
seven is rejected by policy. TNF zero is an empty **record**, represented by a
nonempty encoded message; zero storage-TLV length means no message instead.

The hard bounds are 1 MiB per encoded message, 256 logical records and 1024 physical
records/chunks. Decode callers can reduce the byte and logical-record limits.
Type and identifier fields are bounded at 255 bytes. Encode chooses SR for payloads
up to 255 bytes, four-byte big-endian lengths above that, and IL only for nonempty IDs.
The generic codec validates framing, not every application RTD's semantics.

```pascal
uses System.SysUtils, ERD.Card.Ndef, ERD.Card.Ndef.Records;

var
  Message, Children: TNdefMessage;
  Wire: TBytes;
  Title: TNdefText;
begin
  SetLength(Children, 2);
  Children[0] := TNdefRecords.Uri('https://example.org');
  Children[1] := TNdefRecords.Text('Welkom', 'nl-BE');
  SetLength(Message, 1);
  Message[0] := TNdefRecords.SmartPoster(Children);
  Wire := TNdefCodec.Encode(Message);
  Message := TNdefCodec.Decode(Wire);
  Children := TNdefRecords.DecodeSmartPoster(Message[0]);
  Title := TNdefRecords.DecodeText(Children[1]);
end;
```

Text RTD supports strict UTF-8 and UTF-16. UTF-16 encoding uses a big-endian BOM;
decoding accepts either BOM or big-endian without a BOM. Unpaired surrogates,
overlong UTF-8, truncated scalars, invalid status bits and invalid language-field
bounds fail instead of being replaced. Language codes receive an ASCII structural
check, not a BCP 47 registry lookup. Text strings use `UnicodeString` explicitly.

URI RTD supports all prefix codes 00–23 and chooses the longest matching prefix
when encoding. URI text is preserved; these helpers do not check URL syntax,
authorize a scheme, navigate or fetch anything. MIME builders accept bare ASCII
type/subtype tokens, without parameters. External builders validate ASCII domain
labels and type tokens; both builders lowercase their type fields and copy payloads.
Generic absolute-URI TNF three records can be carried by the framing codec; they
are distinct from well-known URI RTD `U` records.

Smart Posters require exactly one URI, distinct language codes for titles and at
most one action, size and resource-type child. Their lengths/action values are
checked. Opaque extensions and MIME icons are retained as child records. Nested
Smart Posters are explicitly rejected; decoding never recursively inspects arbitrary
payloads. No Signature RTD verification, handover protocol or executable action
dispatcher is supplied.

Codec outputs, cloned records and decoded child messages own independent buffers.
Ordinary record/array assignment shares them: call `TNdefCodec.Clone` or `CopyBytes`
before editing an assigned copy. Do not treat NFC payloads as authenticated data.

## Type 2 mapping and capacity

The caller identifies original Ultralight, EV1-48/128 or NTAG213/215/216; no probe
infers the chip model. `TType2NdefMapping.Decode` takes page-three CC bytes and the
complete physical user-memory snapshot. CC mapping **1.0**, public read access and
write access zero/F are supported. Invalid/reserved access values fail. The advertised
data area must fit physical user memory:

| Model | Physical user bytes | Typical CC data-area bytes |
| --- | ---: | ---: |
| Original Ultralight / EV1-48 | 48 | 48 when NDEF-initialized |
| EV1-128 | 128 | 128 when NDEF-initialized |
| NTAG213 | 144 | 144 |
| NTAG215 | 504 | 496 |
| NTAG216 | 888 | 872 |

The CC size includes TLV headers/control records; it is not the maximum NDEF payload.
NULL, terminator, NDEF, Lock Control, Memory Control and proprietary TLVs are recognized.
The factory NTAG213 prefix `01 03 A0 0C 34 03 00 FE` is supported: its lock bytes
start at physical byte 160, outside the 144-byte CC data area. Lock Control TLVs
must point into the selected model's three dynamic lock bytes. Memory Control TLVs
may describe an external range within physical memory. Internal reserved-memory
holes are rejected explicitly; no contiguous interpretation silently skips their
semantics. Other mapping versions and sector selection remain separate work. Type 3 and Type 5 have dedicated components; [Topaz/Type 1](TOPAZ_TYPE1.md) supplies initialized Topaz 96/512 mapping with verified user/NDEF writes. Public ISO 7816 Type 4 mapping 1.0/2.0 access is
now available in [TYPE4_NDEF.md](TYPE4_NDEF.md).

`HasNdef` distinguishes absence from an empty TLV. Empty length returns no records
and stops interpreting the tail, because it can denote an update in progress.
Writing such an empty TLV requires only NULL padding or a terminator immediately
before any opaque tail. Other trailing TLVs or leftover interrupted-update payloads
are refused; the component does not automatically recover them.

## Card component and writes

Supply a connected `TSmartCardReader.Transport` (or another `ICardTransport`
implementing `ICardTransaction`) and a reader-compatible `IType2ReaderProfile`:

```pascal
uses ERD.Card.Contactless, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Type2.Ndef, ERD.Card.Ndef, ERD.Card.Ndef.Records;

// Pcsc is an already connected TSmartCardReader.
Ndef := TType2NdefCardReader.Create(nil);
try
  Ndef.Transport := Pcsc.Transport;
  Ndef.Profile := TPcscStorageProfile.Create; // Only a matching reader/driver.
  Snapshot := Ndef.ReadMessage(ttmNtag213);
  SetLength(Message, 1);
  Message[0] := TNdefRecords.Uri('https://example.org');
  Ndef.WriteMessage(ttmNtag213, Message);
finally
  Ndef.Free;
end;
```

Declare `Ndef: TType2NdefCardReader`, `Snapshot: TType2NdefSnapshot`, and
`Message: TNdefMessage`. Construction does no hardware work. Each operation owns
one exclusive transaction on the calling thread; there is no unguarded transaction
opt-out, nested session, command replay, RF reset or fallback profile.

Reads return a complete snapshot only after successful release. Writes additionally:

1. Check EV1/NTAG configuration: AUTH0 must exclude all user pages; NTAG mirror
   mode bits must be zero. Inaccessible configuration fails preflight. No password
   attempt or implicit use of a prior authenticated state is performed.
2. Require an existing last NDEF TLV, public CC write permission and sufficient
   advertised capacity. Formatting CC or moving trailing proprietary/control TLVs
   is never implicit.
3. Read static user-page lock bits and all three dynamic lock bytes where present.
   Any static user lock or any nonzero dynamic byte refuses the write. CC/static
   block-lock bits alone do not make user pages read-only. Dynamic block-lock/RFUI
   rejection is deliberately conservative, even if a specific subset is writable.
4. Invalidate the existing length in one page and read it back. Switch to a short
   zero-length header before changing header width. Apply prepared pages descending,
   leaving the published length zero; verify every changed four-byte page.
5. Publish the final length in one page, then compare complete physical user memory
   and unchanged CC before transaction release.

Both bytes of an existing/new extended TLV length must fit one page. Offsets where
they straddle pages are refused before writing. This restriction prevents publishing
an intermediate nonzero length while changing either length byte. Page writes can
still tear on real hardware: the multi-page operation is **not atomic**.

Only changed user pages are dispatched, and identical message bytes are a no-op.
Prefix TLVs, bytes beyond the new terminator and bytes beyond CC capacity are
preserved. A larger message intentionally consumes formerly unused bytes after
the old terminator. Manufacturer, static/dynamic lock, CC and configuration pages
are never written. `ClearMessage` leaves an existing zero-length NDEF TLV; former
payload bytes beyond the new terminator remain present. It is not a secure-erasure operation.

Any exception after the first page-write dispatch, including denied status, read-back
mismatch, later read failure, changed CC or failed release, raises
`EContactlessWriteUncertain`. It carries the original exception class, without its
possibly sensitive message. Stop, inspect current storage and decide recovery in
the application; there is no automatic retry, rollback or claim of a completed write.
Preflight and read failures retain their ordinary exception type. Transport/backend
errors may still contain application-controlled messages; keep logging policy in the caller.

This is public-memory PC/SC access. The existing [password component](TYPE2_PASSWORD.md)
retains its separate raw authenticated session; mixing page commands into that session
is not supported. PC/SC four-byte requests may be implemented internally as a native
four-page RF READ; driver truncation, wraparound and protection boundaries require
real reader tests. Enabled NFC counters can advance on reads. Reader-visible mirrored
bytes are not backing EEPROM; writes reject mirror modes. Keep the same physical
card present throughout: a host transaction does not prevent someone swapping tags.

## Validation and references

`tests/contactless/Ndef.Tests.dpr` exercises independent wire vectors, all payload
length boundaries through 520, exact maximum message/record/chunk bounds, deterministic
wire mutations, ownership, malformed Unicode, all 36 URI prefixes and Smart Poster
constraints. Its injectable PC/SC memory backend exercises all six chip layouts,
the NTAG213 factory prefix, both TLV header widths, every allowed alignment,
reserved-tail preservation, page read-back and every partial write. Lock, AUTH0,
mirror, capacity, status, changed-CC and transaction failures stop without replay.
No physical tag has been changed by these tests.

`InspectNdef <message-hex>` is a hardware-free example; it prints only structure
and lengths. Both test runners include the new tests/example and the runtime package.
The [validation record](VALIDATION.md) distinguishes FPC/static-check results from
pending Delphi/Help Insight and physical-card validation. No NFC Forum certification
or universal reader/card support is claimed.

Protocol research used these pinned public references; third-party implementations
were consulted for interoperability facts, not bundled or copied into the library:

- [Android 13 NdefRecord](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-13.0.0_r1/core/java/android/nfc/NdefRecord.java),
  SHA-256 `e97ccf7f5ed7e2eb17cec625de13766f0e948e80bb98d53435ce523601a69751`:
  framing, chunk flags/TNF constraints and the standard URI-prefix table.
- [Android 13 NdefMessage](https://github.com/aosp-mirror/platform_frameworks_base/blob/android-13.0.0_r1/core/java/android/nfc/NdefMessage.java),
  SHA-256 `51c27643a468992bd56bd9c407134339987af562cb4f3c9983e6e222001fc930`.
- [ndeflib 0.3.3 Smart Poster](https://github.com/nfcpy/ndeflib/blob/v0.3.3/src/ndef/smartposter.py),
  SHA-256 `d049d67c1dcd6e59c3415d53dceb68f256f745711d9212c25ea767fda008ff66`:
  RTD child types and URI/title/action/size/resource-type interpretation.
- [nfcpy 1.0.4 Type 2 mapping](https://github.com/nfcpy/nfcpy/blob/v1.0.4/src/nfc/tag/tt2.py),
  SHA-256 `879b47fcfe7d7b6fa4cc33417a1d91ae6de7aa30a4baa4f7608b07cbbc8fdee4`:
  control-TLV address fields and length-last storage updates.
- [NXP NTAG213/215/216 Rev. 3.2](https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf),
  SHA-256 `8c2a81e144d1123ee0a9c3ddd4876144fd11e299893032315c4a34fbbc6b2ed1`,
  sections 8.5.2–8.5.7: lock bytes, CC capacities, factory content, AUTH0 and mirroring.
- [NXP Ultralight EV1 Rev. 3.3](https://www.nxp.com/docs/en/data-sheet/MF0ULX1.pdf),
  SHA-256 `53cc29c6c7d8d93b12ad11f9de9c2c1368ad537f56e363e29b8c1723504a07f8`:
  user/configuration regions and AUTH0. Original Ultralight layout is documented
  in the [contactless guide](CONTACTLESS.md).

NTAG210/212 layouts and mirror/configuration rules are documented in [NTAG210_212.md](NTAG210_212.md).
