# USB-HID RFID input

`TRfidKeyboardReader` accepts reader-presented identifiers from a dedicated host
keyboard input control. No brand or VID/PID whitelist is required. This works with
125 kHz and 13.56 MHz readers **when they are configured to type text**. Frequency
is a hardware characteristic; the component does not change it or identify a chip.
The actual Windows keyboard layout must match the reader's configuration.

## Available profiles

| Profile | Input | Configuration |
| --- | --- | --- |
| Generic keyboard | Mapped printable ASCII characters from the host | ASCII, even-width hex or decimal; exact optional length; prefix/suffix; CR, CRLF, LF or Tab; inter-character deadline |
| Boot keyboard HID | Exact eight-byte USB HID boot input report | US usage mapping, explicit initial caps lock; CR or Tab framing |
| Boot keyboard + report ID | Exact nine-byte report | Same mapping and framing, plus one explicitly required ID, including zero if the host includes it |
| Declared fixed ASCII field | One exact-length report with a documented field | Offset/width/report length, optional exact ID, NUL or space trailing padding; ASCII/hex/decimal interpretation inherited from the input component |

`TRfidHidReportReader` implements the last three formats. A fixed ASCII field is
an extraction profile, **not a claim that a particular vendor protocol is supported**.
It must describe the actual device protocol and its status semantics must be handled
by the host. Each such packet closes one identifier; fragments are never joined.

These components do not enumerate/open USB devices. Standard Windows keyboard
input is immediately usable through the VCL demo's RFID tab. Raw reports must be
supplied by the application's selected HID/Raw Input source, including the actual
OS report-ID framing. Windows keyboard-driver ownership is not bypassed. Raw HID
with arbitrary descriptors, NKRO, encrypted payloads or vendor commands is not
implicitly supported by an eight-byte keyboard format.

## Source-linked application example

```pascal
uses ERD.Card.RFID.Input;

// Create/own on the UI thread; connect OnIdentifier before Start.
Reader := TRfidKeyboardReader.Create(Self);
Reader.Encoding := rieHexadecimal;
Reader.ExpectedCharacters := 8; // Actual reader output, not guessed UID size.
Reader.Terminator := ritCr;
Reader.InterCharacterTimeoutMs := 500;
Reader.Start;

// In a dedicated input control's OnKeyPress:
Reader.FeedCharacter(Key, GetTickCount64);
Key := #0;
```

The palette supplies both input components through `ERDCardInput`. Interfaces and
raw report sources remain runtime dependencies of the application. See the
[SmartCardDemo steps](VCL_DEMOS.md) for an example requiring no raw USB backend.

## Identifier semantics and failure behavior

ASCII preserves printable text. Hex preserves presented byte order. Decimal
preserves leading zeros and does not assume facility code, Wiegand width or RF UID
ordering. `TRfidInputCodec.ToBytes` requires an explicit width/order, supports up
to 64 bytes and refuses overflow or implicit ASCII conversion. A number printed by
a reader is not proof of a physical UID or an authenticated card. Ordinary keyboard
events also do not establish the originating device.

Frames are bounded to 128 identifier characters, plus explicitly bounded framing.
Timeouts, overflow, invalid characters and malformed keyboard reports discard an
unfinished scan through its delimiter, preventing its tail from becoming another
identifier. Closed malformed frames are consumed. Held keyboard usages are not
repeated; rollover/error reports, duplicates, unsupported usages, control/alt/GUI
combinations and simultaneous new keys with unknown order are refused. US caps and
shift are explicit codec state, separate from OS keyboard state.

Events occur on the feeding thread once per valid frame. Results own their byte
arrays. Start clears results and keyboard state; Stop discards partial input.
Configuration changes and recursive feed from callbacks are refused. Reset is for
known source/frame boundaries only; DiscardFrame is for missing/invalid reports.

No generic HID card memory reading, writing, UID programming or reader configuration
commands are supplied. Those require documented reader/chip protocols. The separate [TWN4 memory backend](TWN4.md)
adds actual Classic/Type 2 commands through PRS/USB-CDC, not keyboard HID.
The [supplied reader investigation](RFID_READER_MODELS.md) distinguishes these interfaces. Physical
AliExpress reader checks, raw host integration and Delphi VCL execution remain pending.

## References

- [USB HID 1.11](https://www.usb.org/sites/default/files/hid1_11.pdf), Appendix B,
  boot keyboard input bytes: modifier, reserved, six usage slots.
- [USB HID Usage Tables 1.5](https://www.usb.org/sites/default/files/hut1_5.pdf),
  keyboard/keypad usage page 07, including modifiers and rollover/error usages.
- Executed framing/conversion/report checks: `tests/input/RfidInput.Tests.dpr`.
