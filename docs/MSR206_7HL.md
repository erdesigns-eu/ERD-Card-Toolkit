# MSR206-7HL same-swipe verified reading and writing

`TMsr2067HLMagStripeAdapter` implements the **MSR206-7HL PM036 Rev F**
three-track, variable-current profile. It is a separate command family from the
MSR206/MSR605 adapter in [MSR206.md](MSR206.md). No protocol fallback or trial
programming selects a profile. Source use needs `src/magstripe`; the existing
`ERDCardMagStripe` runtime package still requires only `rtl`.

## Operations and boundaries

| Operation | Implemented behavior | Evidence still required |
| --- | --- | --- |
| Read | Any nonempty Track 1/2/3 combination; one swipe; selected ISO buffers; unselected results empty | Real three-track firmware, swipe behavior and physical card checks |
| `WriteTracks` | All seven nonempty combinations; explicit low/high temporary current; RAW status and independently acquired same-swipe read-back | Physical writing, preservation of unselected tracks and media/current suitability |
| Native Windows serial | Default 9600 baud, seven data bits, odd parity, one stop bit; no flow control | Windows driver behavior, Delphi Win32/Win64 and calling conventions |
| Pure USI1 codec | Bounded seven-bit STX/message/ETX/XOR framing; no retry | Actual reader transmission behavior |

This adapter advertises `VerifiedWrite=true`, all three physical write tracks and
`mscLow`/`mscHigh`. It implements `IMagStripeDevice`, rather than the weaker
status-only programming interface. `WriteTracks` returns the acquired payloads,
not a receipt or an echo of the request. It refuses empty selected payloads,
nonempty unselected entries and `mscCurrent` before sending a command.
Standard capacities are 76/37/104 payload characters.

PM036 section 7.2 explicitly states that only loaded tracks are written and other
tracks remain untouched. Preparation resets previous buffers; the adapter then
loads **only selected tracks**. `@` collects data from the same encode swipe in
read buffers; after successful RAW acknowledgement, `Q`/`R`/`S` retrieve those
buffers and the adapter compares every selected payload. It never sends `P`
between writing and retrieval and never requests a separate verification swipe.
The component also validates the returned payloads and closes the session before
returning success. A checksum-valid response with different contents fails.

The device checks physical ISO parity/LRC; the host validates USI1 BCC, payload
encoding, capacity and exact requested contents. BCC is an error check, not device
or card authentication. The configuration byte confirms three read/write tracks;
it does not authenticate manufacturer, firmware or the card's provenance.

## Example

```pascal
uses ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks,
  ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL;

var
  Component: TMagStripeReaderWriter;
  Data, ReadBack: TMagStripeTracks;
begin
  Component := TMagStripeReaderWriter.Create(nil);
  try
    Component.Device := TMsr2067HLMagStripeAdapter.Create(
      CreateWindowsMagStripeSerialPort('COM12', mssf7O1));
    Component.TimeoutMs := 10000;
    Data[mstTrack1] := '';
    Data[mstTrack2] := '23';
    Data[mstTrack3] := '';
    // Arms one physical encode swipe; only Track 2 is written.
    ReadBack := Component.WriteTracks([mstTrack2], Data, mscHigh);
    // ReadBack[mstTrack2] is acquired from that same swipe and equals '23'.
  finally
    Component.Free;
  end;
end;
```

The synthetic payload demonstrates programming, not a payment or financial-card
provisioning workflow. The supplied console stays read-only:

```text
InspectMsr206 --help
InspectMsr206 --port COM12 --profile msr206-7hl --timeout 10000
```

It reports track lengths and does not print card contents. The existing
`--frame-hex` option decodes the MSR206/MSR605 response family only; it does not
infer 7HL framing. `TMsr2067HLCodec` supplies separate pure USI1 decode functions.

## Wire and lifecycle

1. Discard buffered input; send unframed `DEL` warm reset. Accept exactly the
   documented `:` power-on report, either bare or STX/ETX/BCC-framed.
2. Send USI1 `#` to select USI1 and require configuration byte `77` hexadecimal
   (Track 1/2/3 read/write present, reserved bit clear).
3. A read sends `P`, consumes separate arm and swipe acknowledgements, then
   retrieves only requested `Q`/`R`/`S` buffers.
4. A write sets temporary current with `<036` or `<255`, requires ACK and queries
   `>` to confirm the exact setting. It sends `O`/`n` to set 210/75/210 BPI **before**
   loading any data. Each selected `A`/`B`/`C` load command and EOT-terminated data
   download requires its own ACK.
5. Send `@` once, require separate arm and successful RAW acknowledgements,
   retrieve selected buffers without rearming, then compare acquired contents.
6. Release attempts one unframed warm reset with a separate 500 ms send budget,
   closes once and always clears local ownership. An untouched acquired port is
   closed without a reset. Reset errors take precedence over secondary close errors.

USI1 frames are `STX(02) / message / ETX(03) / BCC`. BCC XORs message bytes **and**
STX/ETX. Download EOT (`04`) is inside the message. The largest supported message
is 105 bytes (104 Track 3 payload bytes plus EOT), giving 108 wire bytes. Incoming
messages are bounded before further reads or output; malformed checksums, seven-bit
violations, nested delimiters and unframed USI0 replies fail. No resynchronization,
repeat-last-command, retransmission or nonstandard-format probing occurs.

All protocol steps share one monotonic total deadline, including setup and waiting
for the physical swipe. A frame's first byte can use the remaining total budget;
continuation bytes, including BCC, have at most the documented **65 ms** USI1
inter-character budget. A channel that reports a received continuation after that
budget still fails. Backward clock movement is refused. The supplied native port
writes a whole frame in one `WriteFile` call; conforming driver transmission timing
needs hardware validation. Serial-channel acquisition and release are separate
lifecycle stages from the protocol deadline.

After any operation failure the acquired session is poisoned until release.
Before arm dispatch, direct-adapter failures are ordinary errors. Once `@` dispatch
starts, failed sending, RAW error, timeout, decode error, missing read-back or a
comparison mismatch raises `EMagStripeWriteUncertain`. The component conservatively
marks every failure after backend write invocation, including cleanup, uncertain.
No automatic replay occurs, and uncertain messages include exception class rather
than transport/card contents.

Release sends reset without awaiting its report; host transmission alone does not
prove physical cancellation. The manual says reset/abort bytes inside an incomplete
data download are treated as data. A failed download can therefore leave a pending
reader state until its timeout or physical reset. The next operation must receive
and validate reset/configuration replies before arming. Inspect/reinitialize an
uncertain device/card explicitly; closing COM alone does not prove it is disarmed.

## Explicit restrictions

- The profile covers standard ISO-length media and standard ISO tracks, not extended
  media, AAMVA, passbook or custom encoding. It never uses no-RAW `Z` or speed prompts.
- `036` and `255` are the manual's recommended typical low/high **current settings**,
  not measured coercivity or universal media compatibility. `mscCurrent` is refused
  because warm reset reloads the EEPROM default. No automatic coercivity detection,
  calibration or EEPROM/default-current modification occurs.
- Singleton status characters (`!`, `*`, `+`, `-`, `/`, `?`, `~`) cannot be distinguished
  from literal one-character Track 1 payloads in this protocol. Reads treat `+` as
  the documented no-data status and other such singleton messages as errors. Writes
  refuse these ambiguous singleton payloads before I/O. In particular, `*` is never
  converted to an empty successfully decoded track. Multi-character payloads still
  pass through the strict standard track codec and device format validation.
- The supplied port assumes the manual's default 9600/7O1 configuration. Inject a
  conforming channel for a deliberately reconfigured reader; framing is never guessed.
- This adapter does not imply support for other MSR models or payment authorization.

## Sources and validation

Commands and behavior are independently implemented from **MSR206-7HL
Programmer's Manual, PM036 Rev F, July 27, 2005**, sections 3, 5, 6 and 7.
The [pinned reference PDF](https://raw.githubusercontent.com/dev-zzo/libmsr/d0df43e3b7e69439932b9bf67c87d91cbed8a75f/docs/MSR206-7HL%20Programmer%27s%20Manual%28Rev.%20F%29.pdf)
has SHA-256 `087f8fbc7dbaae8284a927c8d655506754cf5b240cb6915fac940bd6ae6f0810`.
The PDF and third-party implementation code are not redistributed.

`Msr2067HL.Tests.dpr` exercises independent literal BCC/command vectors, all seven
read/write combinations, both power-report forms, low/high current, every send and
receive failure, every response-byte corruption, RAW failure, independently acquired
mismatch/missing data, global and inter-character deadlines, maximum/oversized frames,
no fallback and cleanup precedence. `NativeSerial.Tests.dpr` additionally executes
the actual Windows COM branch against a Linux C ABI shim: 7O1 DCB fields and a
complete component/adapter/native Track 2 write/read-back chain. This cannot prove
Windows ABI calling conventions or physical preservation/writing. All visible APIs
have Delphi XML comments; the Windows runner builds with `--doc`.

See [VALIDATION.md](VALIDATION.md). A real Delphi build, Help Insight inspection and
physical reader/card test matrix remain required before release claims.
