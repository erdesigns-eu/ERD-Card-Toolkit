# ELATEC TWN4 memory profile

`TTwn4CardReaderWriter` adds a concrete memory-command backend for suitable
**ELATEC TWN4 Simple Protocol (PRS) firmware, ASCII mode, USB-CDC virtual COM**.
It does not turn a keyboard HID reader into a writer and does not configure or
flash reader firmware. Match the installed firmware's CRC setting explicitly.

## Available functions

| Operation | Scope |
| --- | --- |
| ReadVersion | Bounded PRS version string; does not certify supported commands/firmware |
| ReadTag | Reader-reported tag type, identifier bits and bytes; LF/HF capabilities depend on the actual TWN4 hardware |
| ReadClassicBlock | Explicit Mini/1K/4K model/block, supplied six-byte A/B key, expected ID and explicit reader-sector byte |
| WriteClassicDataBlock | Expected ID/current data, one write and independent sixteen-byte read-back; manufacturer/trailer blocks refused |
| ReadType2UserPage | Explicit Ultralight/EV1/NTAG model/user page and expected seven-byte ID; returns only the first four bytes of the reader's sixteen-byte READ |
| WriteType2UserPage | Public user page only, expected ID/current data, one four-byte write and independent read-back; lock/manufacturer/configuration regions refused |
| TTwn4Codec | Strict ASCII/CR framing, optional documented CRC, bounded SearchTag decoding |

The model is supplied by the application, not inferred from an ID. Firmware must
support the actual chip and command; a shared category `80` only means the reported
ISO14443A/MIFARE family. Four-K Classic reader-sector encoding differs across SDK/
firmware conventions: supply it explicitly from the corresponding documentation.
For blocks below 128 the component additionally requires sector = block div four.
There is no speculative sector remapping or automatic command fallback.

Type 2 commands cover public user memory only. PWD_AUTH/PACK, Ultralight C 3DES,
DESFire, ISO15693, EMV/APDU transport, UID programming and low-frequency memory
writes are **not yet TWN4 backends**. Their existing PC/SC/component support does
not automatically imply support through this reader. Classic keys enable the
specified supported block access; no default-key search is performed.

## Use in an application

```pascal
uses ERD.Card.Reader.TWN4, ERD.Card.Reader.TWN4.Serial;

Reader := TTwn4CardReaderWriter.Create(nil);
try
  Reader.Channel := CreateWindowsTwn4CdcChannel('COM17'); // Known PRS/CDC reader.
  Reader.UseCrc := False; // Must match installed firmware; no auto-detection.
  Reader.TimeoutMs := 3000;
  Tag := Reader.ReadTag;
  // After explicit model/page selection, use Tag.Id as expected identity:
  Page := Reader.ReadType2UserPage(ttmNtag213, 4, Tag.Id);
  // To change this page, explicitly supply Page as expected-before and four new bytes:
  // Reader.WriteType2UserPage(ttmNtag213, 4, Tag.Id, Page, Replacement);
finally
  Reader.Free;
end;
```

Add `ERD.Card.Contactless.Type2` to uses for the model enum. Run hardware operations
on the application's worker thread, not a blocking UI event. Every call opens the
selected channel exclusively and closes it afterwards. Successful chains turn RF
off before closing. After a failed/incomplete chain, the component closes without
sending speculative recovery commands. Native Open/Close driver latency is outside
the shared bounded command-I/O deadline.

The native CDC factory reuses the existing tested Windows serial-byte implementation
at 9600/8N1. It sends no magstripe commands. Select the known virtual COM port;
other native serial baud modes, USB-HID opening, VID/PID detection and automatic
firmware-mode switching are not supplied. Native opening is explicitly unsupported
on non-Windows hosts. The runtime package is `ERDCardTWN4`, requiring Core,
Contactless and MagStripe (the existing native serial-byte implementation).

## Write evidence and ownership

Writes compare an explicit expected-before array, recheck the expected tag ID and
re-read expected contents immediately before dispatch. Classic reauthenticates
after that final SearchTag because reselection may invalidate authentication.
Matching no-ops do not send a write. Caller arrays are copied before opening the
channel; local key and credential-bearing command copies are wiped. Backend copies
are outside that guarantee.

A post-dispatch failure, false/malformed acknowledgement, failed read-back, RF-off
failure or channel-release failure raises `ETwn4WriteUncertain`. Its
`VerifiedReadBack` distinguishes already acquired read-back proof from an unproven
write. There is no automatic replay. Expected IDs are collision-prone reader data,
not card authenticity or a guarantee against physical removal between commands.

## Examples and validation

`examples/readers/InspectTwn4.dpr` offers hardware-free `--help` and `--frame 0005
--crc`, plus explicit `--port COM17 [--crc] [--version]` read-only inspection.
Writes are deliberate API calls with the required identity/before/data inputs.
A separate family VCL example is on the [requested next-batch checklist](VCL_COVERAGE.md).

Independent literal command/CRC/tag/Classic/Type 2 transcripts execute under FPC.
Tests inject failures at every byte-I/O boundary, every selected-page/block
read-back bit, stale/changed IDs/content, response shapes/status, clock reversal,
shared deadlines, owned caller arrays and cleanup failures. Native serial APIs
have prior Linux ABI-shim evidence; real Windows CDC driver, TWN4 firmware, native
Delphi/IDE and physical card compatibility remain pending.

## Sources

- [ELATEC TWN4 MultiTech 2 LF/HF product page](https://www.elatec-rfid.com/en-us/product-detail/twn4-multitech-2-lf-hf)
  and its [manufacturer data sheet](https://www.elatec-rfid.com/fileadmin/Documents/Data-Sheet/elatec-twn4-multitech-2-lf-hf-data-sheet-en.pdf).
  The linked reseller's HF variant must not be assumed to include LF hardware.
- **ELATEC TWN4 Simple Protocol DocRev17, June 1, 2018**, sections 1–1.4,
  1.5.1.4, 1.5.4.1–2, 1.5.10.1–3 and 1.5.11.1–2.
  [Public copy](https://github.com/thenewwazoo/elatec-twn4-simple/blob/master/doc/TWN4%20Simple%20Protocol%20DocRev17.pdf);
  SHA-256 `12b4991b74f16afd30c74b22384b6875d3008d5c1e852a4462d59315ec0e0020`.
  The serial PRS firmware requirement is explicit on page 9. No arbitrary HID
  memory-command compatibility is inferred from this protocol.
- [Independent ELATEC.NET key enum](https://github.com/c3rebro/Elatec.NET/blob/master/src/Api/Cards/Mifare/MifareKey.cs)
  and reader implementations corroborate A/B = 0/1; its reader notes describe the
  separate 4K-sector mapping issue. No third-party implementation was copied.
