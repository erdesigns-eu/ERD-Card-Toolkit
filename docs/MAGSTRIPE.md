# Magstripe codecs, component and input adapters

`src/magstripe` supplies six RTL-only units and the optional
`packages/runtime/ERDCardMagStripe.dpk` runtime package. Add `src/magstripe` to the
unit search path for source-based use; the package requires only `rtl`. No VCL,
PC/SC, third-party DLL, USB library or design-time activation is needed.

## Operation-specific support

| Layer/profile | Implemented | Separate pending work |
| --- | --- | --- |
| Track 1 six-bit and Track 2/3 four-bit codecs | Character framing, forward bit encoding/decoding, odd parity, data-column LRC, strict capacity | F2F waveform decoding, clocking-bit removal and capture-direction normalization |
| Financial Track 1 format B / Track 2 | Typed PAN, name, expiry, service code and opaque discretionary suffix | Issuer semantics, authentication and payment authorization |
| `TMagStripeReaderWriter` | Exclusive read sessions; verified-result `WriteTracks`; separate status-only `ProgramTracks` with exact permitted combinations | Real reader/writer validation and additional backends |
| MSR206/MSR605 three-track ISO serial profiles | Windows COM reader and all-three nonempty status-only programmer with explicit high/low coercivity | Delphi/Windows/firmware and physical swipe/write checks; see [MSR206](MSR206.md) |
| MSR206-7HL Rev F three-track VC | Native 7O1 serial, USI1 framing, all seven selected-track combinations with same-swipe acquired verified writing | Delphi/Windows/firmware and physical preservation/write checks; see [7HL](MSR206_7HL.md) |
| MagTek D99875191 Rev 20 unencrypted HID ISO/ABA | Fixed 337-byte report parser and read adapter; explicit optional OS zero report-ID byte | Host HID opening, descriptor/identity checks, physical reader/firmware validation |
| MagTek D99875206 Rev 20 default keyboard ISO/ABA | Ordered complete CR-terminated frame parser and read adapter | Isolated host keyboard capture, key mapping and physical reader validation |
| YL160 `lib160.dll` / MSR605X `MSR_API.dll` | Legacy research retained; new common device contract available | Verified SDK headers, buffer capacities, return codes, bitness/calling convention and native bindings |
| Other/encrypted MagTek, AAMVA, CADL, JIS, seven-bit tracks 2/3 | Not implemented | Distinct descriptors, framing, keys and concrete device profiles |

MagTek adapters are read-only. Neither parser opens a physical reader.
MSR206/MSR605 have a separate native serial adapter, described in
[the serial guide](MSR206.md). Supply an
`IMagStripeFrameSource` that acquires one exclusive session and delivers exactly
one complete swipe within the supplied deadline and allocation limit. For HID,
validate the actual device/descriptor and use the documented unencrypted input
report. The optional zero byte is an explicit host API report-ID convention,
not a byte to guess or silently strip. USB transfer fragments must be assembled
by the source before parsing.

For keyboard input, isolate the reader stream and provide the intended keyboard
mapping. Keyboard text alone cannot establish which device produced it. Do not
feed an application's arbitrary text input or interleaved typing as a trusted
reader stream. The parser expects the documented default ISO configuration:
SS/ES enabled, LRC disabled, uppercase, no custom prefix/suffix/separators, one
final CR. It refuses LF, multiple swipes, out-of-order/duplicate tracks, error
markers and alternate encodings. Missing tracks may be omitted; CR alone is a
blank swipe. The adapter never changes device configuration or loads a DLL.

## Track representations

`TMagStripeTracks` holds **unframed payload strings**, indexed by physical track.
Empty read entries mean absent data. Decode failures raise and are not silently
converted to absence. Selected empty writes are refused: erasing needs its own
explicit, separately implemented device operation. Unselected entries must be
empty, and a writer backend must preserve unselected physical tracks.

| Track | Data + parity bits | Payload characters | Full card symbols including SS/ES/LRC | Canonical text SS |
| --- | --- | --- | --- | --- |
| 1 | 6 + 1 | 76 | 79 | `%` |
| 2 | 4 + 1 | 37 | 40 | `;` |
| 3 | 4 + 1 | 104 | 107 | `;` |

Track 1 maps ASCII 20..5F to data values 00..3F. Tracks 2/3 map ASCII 30..3F to
00..0F. Payloads refuse SS/ES characters, lowercase, non-ASCII, embedded NUL and
overcapacity input; no trimming, uppercasing or truncation is performed. Generic
numeric tracks allow the remaining representable symbols (`:`, `<`, `=`, `>`),
without pretending they are financial decimal fields. Track 3's physical start
symbol is hexadecimal B, like Track 2. The **keyboard adapter** normalizes its
documented Track 3 `+` presentation; the pure codec and HID parser use `;`.

`Frame`/`Unframe` operate on exactly SS + payload + ES, with **no textual LRC**.
`EncodeBits`/`DecodeBits` use one byte per bit, each exactly 0 or 1, LSB data first,
parity last. Output is SS + payload + ES + LRC; no clocking zeros, padding or
reverse-direction guessing. Maximum sizes are 553, 200 and 535 bits. Capture
normalization and physical timing belong to a separate adapter.

Every symbol, including LRC, has odd parity. LRC is the XOR of **data bits only**
from SS through ES, with its own independently calculated odd parity. XORing the
parity column is incorrect. `DecodeBits` validates the entire bounded frame
before returning any payload. Parity/LRC detect encoding errors; they are not
cryptographic authenticity or tamper protection. HID/keyboard ASCII contains no
source parity/LRC evidence; device decode status is handled explicitly for HID.
Generating bits from ASCII does not verify the original physical stripe.

```pascal
uses System.SysUtils, ERD.Card.MagStripe.Tracks;

var
  Bits: TBytes;
  Payload: string;
begin
  Bits := TMagStripeTrackCodec.EncodeBits(mstTrack2, '123');
  Payload := TMagStripeTrackCodec.DecodeBits(mstTrack2, Bits);
  // Published numeric vector: 11010 10000 01000 11001 11111 00100.
  // Payload = '123'; final five-bit LRC symbol = 04.
end;
```

Bit outputs are independently allocated and inputs are not retained. Ordinary
`TBytes` assignment shares storage; copy arrays before mutating a retained copy.
Strings retain normal Delphi managed-string semantics. Track-format exceptions
exclude supplied track contents.

## Optional financial interpretation

`TMagStripeFinancialCodec` decodes/builds **unframed** Track 1 format B and Track 2.
It requires PAN 1..19 decimal digits, name up to 26 Track 1 characters, four YYMM
digits (month 01..12, or exactly `0000` for unspecified expiry), and three service
code digits. A Track 2 name must be empty; its discretionary suffix is decimal.
Track 1 uses exactly two caret separators and preserves name spacing. Capacity
validation applies to the entire result, including format code and separators.
These are explicit library profile constraints, not a claim to cover every issuer
or alternate financial format. PAN length does not imply Luhn or issuer validity.

Discretionary data is opaque. Its positions must not be assumed to contain CVV,
PVKI or PVV. No secret is inferred, no PIN is verified and no payment is initiated.
Track 3 is a generic character codec; a full ISO 4909 financial schema is pending.
Packed EMV tag-57 Track 2 Equivalent Data is a different representation handled by
the existing EMV data codec, not by these text/physical-bit functions.

## Reader/writer lifecycle

```pascal
uses System.Classes, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks,
  ERD.Card.MagStripe.MagTek;

var
  Reader: TMagStripeReaderWriter;
  Source: IMagStripeFrameSource;
  Data: TMagStripeTracks;
begin
  // Assign a host implementation to Source before constructing the adapter.
  Reader := TMagStripeReaderWriter.Create(nil);
  try
    Reader.Device := TMagTekReadAdapter.Create(Source, False, False);
    Reader.TimeoutMs := 10000;
    Data := Reader.ReadTracks([mstTrack1, mstTrack2, mstTrack3]);
    // Consume Data without storing/logging card contents by default.
  finally
    Reader.Free;
  end;
end;
```

The example requires a real host source implementation; an unassigned Source is
rejected. Constructor, interface assignment and capability query do not open
hardware. Calls are synchronous, on one thread, without reentrancy; `Busy` is an
operation flag, not a cross-thread lock. Configuration changes during an operation
are refused. The backend/source enforces the total 1..600000 ms deadline, cancels
pending work on timeout/error and releases exclusive ownership even on a cleanup
error. The component does not pump VCL messages, spawn background work or sleep
in an unbounded polling loop. Device callbacks must not free/reconfigure it.

Reads acquire exactly once, consume one swipe, validate selected payloads and
release exactly once. Acquisition failure grants no ownership and is not followed
by release. Unselected output is refused by the component. The HID parser ignores
undefined field padding, honors length bytes and distinguishes selected decoder
errors from absent data. Unsupported encoding/status/shape is refused. An error
on an unrequested HID track does not block otherwise valid requested data.

A backend providing acquired verified write data implements `IMagStripeDevice`, advertising only tracks
it can preserve independently and supported explicit coercivity modes. It must
provide **same-programmed-card verified read-back** within its write operation.
A later arbitrary swipe is not verification. The component:

1. Validates input, timeout, track capabilities, coercivity and verification support
   before acquisition or programming.
2. Acquires one exclusive session and dispatches `Write` exactly once.
3. Checks all selected read-back payloads against the request, with no extra `Read`
   that could consume another card's swipe.
4. Returns only after successful release.

Every exception after `Write` dispatch, including device rejection, partial write,
timeout, cancellation, malformed/mismatched read-back and successful-write release
failure, becomes `EMagStripeWriteUncertain`. Its message includes the exception
class but not the underlying message or card data. A preflight/acquisition failure
remains an ordinary error. Cleanup cannot replace a primary failure. There is no
automatic retry, rollback, erase, track mirroring, coercivity guess or writer
fallback. This API contract does not establish physical writer compatibility.

`ProgramTracks` is a separate explicit method for `IMagStripeStatusWriter` backends
that supply device status rather than acquired read-back. It preflights exact
combinations/coercivity before acquisition and returns a receipt with
`HostReadBackVerified=false`. Programming invocation and cleanup errors are
conservatively uncertain. It does not weaken `WriteTracks`, echo inputs as measured
data or consume a later swipe as verification. The concrete MSR206/MSR605 serial
profiles implement all-three programming with explicit high/low modes;
see [their protocol and native transport boundaries](MSR206.md).

The MagTek adapter performs best-effort source release if destroyed while acquired.
Use explicit release to observe cleanup errors; destruction suppresses them.

## Evidence and remaining validation

Protocol facts were checked against these vendor-hosted PDFs, downloaded with TLS
verification. Documents and vendor implementation code are not redistributed.

- [Magnetic Stripe Card Standards, PN 9980004 Rev 1.08](https://www.magtek.com/content/documentationfiles/d99800004.pdf),
  September 2011; capacities and financial field layout.
  SHA-256 `378f0d04b0dfd246e05d99fb6e3fbd833cc3826f45759ce8d6ecc85b9e3e5044`.
- [I/O Interface for TTL Magnetic Stripe Readers, D99875148 Rev 6](https://www.magtek.com/content/documentationfiles/d99875148.pdf),
  December 2003; section 1's independent `AT3`/`123` bit vectors and section 3's
  data-column XOR plus independently odd-parity LRC.
  SHA-256 `f7485c3e3c3439af08fdfb80006a64786410ffa70081b406ab727d343d27a99e`.
- [USB HID SureSwipe / Swipe Reader, D99875191 Rev 20](https://www.magtek.com/content/documentationfiles/d99875191.pdf),
  April 2020; section 4 fixed report, lengths, decode status, encoding and padding.
  SHA-256 `3d703c4c2af1656e608b7e05c484e3f3b9671015945dac9c4680de2a68ce626a`.
- [USB KB SureSwipe / Swipe Reader, D99875206 Rev 20](https://www.magtek.com/content/documentationfiles/d99875206.pdf),
  April 2020; section 4 default frame, configuration and Track 3 `+` presentation.
  SHA-256 `2567dacaffca4dc88aec55935582d289c19bce80a78db9d99caa44efe6cd50fd`.

`tests/magstripe/MagStripe.Tests.dpr` covers published bit vectors, all supported
payload sizes, every single-bit error at every size, parity-preserving two-bit
errors caught by LRC, all byte-range character inputs, fields and malformed data.
Synthetic HID/keyboard fixtures verify independent offsets, explicit report-ID
handling, undefined padding, physical track selection, all truncated HID lengths
and unsupported formats. Injected device/source sessions exercise the complete
component/adapter chain, preflight, deadlines, no reentrancy, partial writes,
read-back mismatch, release precedence and destruction cleanup. All stripe writes
in these tests modify synthetic memory only.

`examples/magstripe/InspectMagStripe.dpr` inspects text or bit frames without
hardware and outputs lengths/LRC, not payloads. Its help, published vectors and
corrupt parity are exercised by both test runners. All visible APIs use Delphi
XML comments for Help Insight; the Windows runner supplies `--doc`.

The Free Pascal range/overflow/heap checks and all source validation readers
supplement Delphi. Pending: dcc32/dcc64, the runtime package, generated XML and
real IDE Help Insight, native MagTek host sources, reader/firmware matrix and real
swipe/write/verification/cancellation behavior. The MSR206/MSR605 serial backend
and Windows COM transport have injected/native-shim evidence; physical checks
remain pending. The legacy DLL declarations do not
specify safe output capacities and are not treated as a validated SDK binding.
See [validation](VALIDATION.md) and [the implementation plan](COMPONENT_PLAN.md).
