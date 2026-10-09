# ISO 15693 memory and Type 5 NDEF

`TIso15693CardReader` provides bounded system information, contiguous block reads
and verified single-block data writes. `TType5NdefCardReader` provides public NDEF
access on existing initialized NFC Forum Type 5 tags. Both retain an
`IIso15693Session`; `TAcr1552Iso15693Session` supplies a concrete addressed ACS
FF-FB pass-through backend over an existing connected PC/SC transport.

Source use needs `src/core` and `src/contactless`. The optional existing
`ERDCardContactless` runtime package requires `rtl` and `ERDCardCore`; no additional
crypto, vendor DLL or USB dependency is introduced. Constructors open no hardware.
All visible APIs have Delphi `///` XML documentation.

## Implemented profile and evidence

| Layer | Implemented operations | Separate validation/boundary |
| --- | --- | --- |
| Pure ISO 15693 codec | Canonical/wire UID conversion, ordinary/extended system information, addressed read/write/security command builders, explicit response normalization | Optional commands and memory/protection semantics depend on the card |
| ACS pass-through | FF-CA-80 activation data; addressed FF-FB 2B/3B, 20/30, 23/33, 21/31, 2C/3C; optional SLIX2/ST25DV password wrapper in one PC/SC transaction | ACR1552U-M firmware 1.03.00+, ACM1552U-Y/Z 2.03.00+, real firmware/driver framing and card tests |
| Raw memory component | Information, selected block ranges and unlocked verified single-block writes | Blocks zero/one reserved by the wrapper; no generic write authorization or automatic card detection |
| Type 5 component | Mapping 1.0 E1/E2 four/eight-byte CC, existing public contiguous NDEF TLV, read/replace/clear, verified no-op | No formatting, inline authentication, permanent locks or manufacturer/configuration updates; explicit password session can authenticate before CC acquisition |

The ACS manual lists those firmware requirements for ISO 15693 pass-through. It
does not list the ACR1552U-A in that section; support for the -A is **not inherited**.
The implementation does not query or certify firmware, and a PC/SC reader name or
ATR hint does not prove the profile. Select the actual supported reader deliberately.
Other readers need a concrete `IIso15693Session` implementation.

Ordinary mode uses one-byte block addresses and requires memory information from
`2B`. Extended mode uses `3B` with parameter request `14` **before the addressed UID**,
requires the returned two-byte memory-address indication, and uses extended block
commands. There is no fallback after an unsupported optional command. Geometry is
one through 32 bytes per block, at most 65536 blocks, additionally bounded to
262144 total physical bytes. The Type 5 CC address indication must agree with the
explicit session mode; CC capacity cannot exceed acquired physical memory.

The UID returned by the library is eight bytes in canonical MSB-first order,
beginning with `E0`. ISO transmission order is reversed. ACS `FF CA 80 00 00`
returns DSFID plus UID in transmission order; addressed system information must
report the same UID, and DSFID must agree when present. UID bytes are copied,
not authenticated. UID writing is not an ordinary ISO 15693 storage operation.

### Explicit response convention

Choose `irfNativeFlags` when APDU data contains native response flags followed by
payload, excluding RF CRC. Native success requires flags zero; an exact native
error response raises `EIso15693StatusError` with its raw `ErrorCode`. RFU flags,
malformed errors and unexpected lengths fail.

Choose `irfPayloadOnly` only when the actual reader/firmware strips native response
flags and reports native failures through APDU SW1/SW2. The ACS reference describes
FF-FB data/status but does not fully specify flag forwarding for each firmware.
**Verify this convention on the actual device**; the adapter never guesses or
tries both formats. Both explicit conventions have injected complete-chain tests,
not a claim that both occur on every ACS firmware.

Reader firmware supplies RF framing/CRC and timing. Write-single-block commands
use high-data-rate/addressed flags `22`, with the option flag clear. Cards needing
option/EOF handshakes, custom authentication or manufacturer-specific protection
require a separate profile. No inventory flood, select/quiet, reset, retry,
retransmission, lock, AFI, DSFID or UID-programming command is sent. The
base adapter does not submit a password automatically; the explicit password
wrapper described below adds manufacturer authentication before memory access.

## Example

```pascal
uses ERD.Card.PCSC.Reader, ERD.Card.Contactless.ISO15693,
  ERD.Card.Contactless.Type5.Ndef, ERD.Card.Ndef.Records;

var
  Card: TSmartCardReader;
  Ndef: TType5NdefCardReader;
  Snapshot: TType5NdefSnapshot;
begin
  Card := TSmartCardReader.Create(nil);
  try
    Card.ReaderName := 'Exact compatible reader name';
    Card.Connect;
    Ndef := TType5NdefCardReader.Create(nil);
    try
      // Explicit mode/convention verified for this card and firmware.
      Ndef.Session := TAcr1552Iso15693Session.Create(
        Card.Transport, iam8Bit, irfNativeFlags);
      Snapshot := Ndef.ReadMessage;
      // Snapshot contains acquired UID/geometry, CC, NDEF bytes and logical records.
      // WriteMessage and ClearMessage are explicit separate operations.
    finally
      Ndef.Free;
    end;
    Card.Disconnect;
  finally
    Card.Free;
  end;
end;
```

`TIso15693CardReader.Session` accepts the same backend for `ReadInformation`,
`ReadBlocks(First, Count)` or `WriteBlock(Index, Data)`. Raw wrapper writes require
index at least two, exact acquired block size, zero standard security status and
independent read-back. A matching block is a verified no-op. Raw writes are not
NDEF edits and can invalidate application data; use the structured Type 5 component
for NDEF updates. Direct backend use leaves protection/preflight/uncertain-write
handling to the caller; the component wrappers provide these contracts.

The supplied console is read-only and omits UID/payload contents:

```text
InspectType5Ndef --help
InspectType5Ndef --cc-hex E1403F00 --blocks 128 --block-size 4 --address 8
InspectType5Ndef --cc-hex E2400001000003FF --blocks 2048 --block-size 4 --address 16
InspectType5Ndef --reader "Exact compatible reader name" --address 8 --response native
```

The CC examples are the NFC Forum-compatible ST AN4911 examples. Offline geometry
is explicit input; it is not measured from a card.

## Type 5 mapping and update sequence

CC magic is E1/E2, mapping version exactly 1.0. Byte two selects a four-byte CC when
nonzero, otherwise an eight-byte CC with reserved bytes four/five zero and big-endian
MLEN in bytes six/seven. **MLEN describes the following data area in units of eight
bytes, excluding the CC.** Legacy Android full-memory MLEN variants are not guessed.
Reserved feature bits and proprietary/read-only access are explicit; proprietary
read/write descriptors can be decoded but public access methods refuse them.

This profile permits NULL/proprietary TLVs before one canonical short/extended NDEF
TLV, followed immediately by a terminator. It refuses lock/memory-control TLVs,
unsupported sparse mappings, noncanonical extended lengths, missing NDEF,
multiple-message layouts and malformed nonempty NDEF. Short length covers 0..254;
extended length covers 255..65535. Formatting an uninitialized tag is separate work.

Every operation retains one exclusive session. Reads validate CC/geometry, acquire
all physical blocks covering the mapped area, decode the message and recheck CC/TLV
header coherence. This does not establish cryptographic authenticity or prevent an
external interface from changing same-length contents. ST25DV has a separate I2C
interface, so application-level coordination still matters. Single-block reads avoid
crossing manufacturer area boundaries in multi-block commands.

An update:

1. Acquires the old initialized message, checks public access/capacity and constructs
   complete block images preserving CC, opaque prefix and partial-block tails.
2. Checks standard security status for **every affected block before the first write**.
   An unsupported security command or locked later block prevents all modification.
3. Sets the first NDEF length byte to zero and verifies the complete modified block.
4. Stages the new header/payload/terminator with that first length byte still zero;
   every changed full block is independently read back before continuing.
5. Publishes one first-length byte last: the short length, or `FF` after the two extended
   length bytes have already been staged. This supports length fields spanning blocks.
6. Acquires and verifies CC, complete message and the complete expected block image
   before releasing and returning success.

Clear publishes `03 00 FE`, retaining unused former payload bytes after the new
terminator; it is not a secure erase. Matching acquired contents are a verified
no-op. Full-block read-modify-write can physically rewrite a block shared with CC
bytes, while preserving those bytes; a locked shared block is refused. There are
no CC edits, protection changes, rollback or automatic retries. Multi-block updates
are not atomic and interrupted staging may leave an empty or incomplete mapping.

After a backend write invocation, failed sending/status/read-back/final comparison
or release raises `EContactlessWriteUncertain`. Error text retains the original
exception class, not card data. Preflight/acquisition errors remain ordinary.
The ACS backend poisons a failed acquired session until release, clears ownership
even on release failure and preserves acquisition errors over cleanup failures.
No APDU is replayed after a timeout, unsupported status or response failure.

## Sources and validation

Independently implemented protocol facts, not redistributed PDFs or external code:

- [ACS ACR1552U Series Reference Manual 1.09](https://www.acs.com.hk/download-manual/13473/REF-ACR1552U-Series-1.09.pdf),
  sections 5.3.3.1, 5.3.4.2 and 5.3.8. SHA-256
  `ab9dc769d8a856913350cc4195b5823587267466f5415e9ddf763356c3f88a6a`.
- [ST AN4911 Rev 5](https://www.st.com/resource/en/application_note/an4911-ndef-management-with-st25dvi2c-series-and-st25tv-series-stmicroelectronics.pdf),
  Type 5 CC/access/MLEN and examples. SHA-256
  `33dd528b1bd52882d5edec4761a55bba591ccb80166b8f168b8d5e59a05b696c`.
- [ST25DV04K/16K/64K DS10925 Rev 11](https://www.st.com/resource/en/datasheet/st25dv04k.pdf),
  system information, extended parameter placement, block commands/security status.
  SHA-256 `bb6a621b7d3b26fd2e9bf3d824f3d51309342543c484148f51a3388cfc0a48e0`.

The test suite covers literal addressed commands, both explicit response/address
modes through a complete concrete adapter chain, all block sizes 1..32, CC examples,
exact 65535-byte TLV maximum, cross-block length fields, ownership/preserved bytes,
all I/O boundaries and partial writes, locked later blocks, no-op/clear, malformed
mapping/messages, native session poisoning and release/acquisition failures.
No physical card or payment was accessed. See [VALIDATION.md](VALIDATION.md): real
Delphi/Windows/firmware, driver framing and physical preservation/writing remain pending.

## Multiple-block reads and supplied-password profiles

`IIso15693Session` keeps its original GUID and methods. Two optional interfaces
extend an active session: `IIso15693BlockReader` for commands 23/33 and
`IIso15693CustomCommands` for addressed manufacturer commands. The built-in ACS
FF-FB adapter implements both. A third-party adapter can implement either without
changing the original interface. Select `TIso15693CardReader.UseMultipleBlockRead`
explicitly (default false); no unsupported-command fallback or retry occurs.
Commands encode count minus one and, in extended mode, both block address and
count in little-endian order. The ACS adapter chunks at 240 data bytes, validates
exact reply lengths, and returns a result only after all chunks succeed. Physical
geometry and total capacity remain bounded by `Iso15693MaxMemoryBytes`.

`TIso15693PasswordSession` is an injectable nonvisual session wrapper, supplied to
the existing `TIso15693CardReader.Session` or `TType5NdefCardReader.Session`.
Its constructor copies credentials and validates identifiers, lengths and
uniqueness without I/O. Acquisition first checks addressed identity and geometry,
then submits each provided password exactly once. No default-password probes,
password search, retry candidates or unprotected fallback are performed.

| Explicit profile | Acquired identity / geometry | Authentication |
| --- | --- | --- |
| `ippSlix2` | NXP SL2S2602: UID E0/04/01, type-indicator bits 37/36 = 0/1, 80 four-byte blocks | Identifier 1 (read) and/or 2 (write); B2 Get Random Number followed by B3 Set Password; each four-byte wire-order password is XORed with the received two-byte random number repeated twice |
| `ippSt25Dv` | Original ST25DV04K: UID product 24 and IC_REF 24, 128 blocks; ST25DV16K/64K: product 26 and IC_REF 26, 512/2048 blocks; all blocks four bytes | B3 Present Password; exactly one eight-byte RF user password with number 1, 2 or 3; use extended addressing for 16K/64K |

Passwords are byte arrays **in RF transmission order**, least significant byte
first. These are not numeric hex strings to be silently reversed. SLIX2 can retain
read and write authentication together; ST25DV closes the previous RF security
session when a different password is presented, so the wrapper rejects a list of
ST25DV passwords. Reads/writes crossing areas assigned to another ST25DV password
can fail; split them into separate explicit operations. Area configuration is not
changed to make an operation succeed. SLIX2 block 79 is the counter and is refused
by the wrapper's ordinary data-write method. Standard lock checks and independent
read-back remain in the existing memory and NDEF components.

Example for an already connected ACS reader transport, with a supplied original
ST25DV16K RF password (local variables include `S: IIso15693Session`,
`P: TIso15693Passwords`, `Memory: TIso15693CardReader`, and `Data: TBytes`):

```pascal
SetLength(P, 1);
P[0].Identifier := 1;
P[0].Value := CopyBytes(SuppliedWireOrderPassword);
try
  S := TAcr1552Iso15693Session.Create(Reader.Transport, iam16Bit, irfNativeFlags);
  S := TIso15693PasswordSession.Create(S, ippSt25Dv, P);
finally
  if Length(P[0].Value) > 0 then
    FillChar(P[0].Value[0], Length(P[0].Value), 0);
end;
Memory := TIso15693CardReader.Create(nil);
try
  Memory.Session := S;
  Memory.UseMultipleBlockRead := True;
  Data := Memory.ReadBlocks(256, 8);
finally
  Memory.Free;
  S := nil;
end;
```

Choose the actual reader response convention. The wrapper can also be assigned
to `TType5NdefCardReader.Session`; acquisition authenticates before that component
reads the CC/TLV or updates NDEF. Existing strict CC access checks still apply:
only the implemented initialized Type 5 mapping is accepted. An RF password does
not authorize overwriting reserved CC access fields or guessing an unsupported
NDEF mapping.

Authentication failure releases the acquired transaction and exposes no memory
session. Later I/O failures poison the wrapper until release. A dispatched write
with failed status, verification or transaction release remains
`EContactlessWriteUncertain` through the existing components, without replay.
Owned password and outgoing command buffers are wiped; strings, OS buffers and
transport-held copies remain outside that guarantee. Exceptions contain no
passwords or card data.

**Transaction release is not an RF power-on reset.** A tag may retain its RF
security state after `EndSession`; a new acquisition resubmits supplied credentials
but is not advertised as a fresh-field credential proof. NXP specifies that a
wrong SLIX2 password prevents further commands until a power-on reset; remove the
card from the field or perform a supported explicit reader RF reset before a new
attempt. Do not assume ending a PC/SC transaction clears tag authentication.

The password-session wrapper implements authenticated user-memory access.
The separate security manager below adds password replacement and controlled
protection updates, including ST25DV RF configuration password 0. Permanent
locking, SLIX2 privacy/destroy/EAS, ST25DV mailbox/I²C, ST25DVxxKC and ST25TV
passwords remain outside this implementation.
ST25DV I²C activity can still modify memory while RF access is exclusive on the
PC/SC connection. These limits are explicit rather than claiming all ST25 chips.

`Slix2Demo` and `St25DvDemo` each have an independent TForm/DFM with reader
selection, native reader/card events, masked credential inputs and background
execution. Both demonstrate identity, physical reads, verified writes and parsed
Type 5 NDEF read/replace/clear. `Iso15693Demo` adds a separate native-bulk-read tab.
The profile/password transcript tests use literal manufacturer frames and cover
acquisition failures, malformed replies, poisoned sessions, counter protection,
credential ownership, Type 5 integration and uncertain writes.

Protocol sources:

- NXP **SL2S2602 Rev. 4.2**, sections 9.2.1, 9.5.3.1 and 9.5.3.2:
  <https://www.nxp.com/docs/en/data-sheet/SL2S2602.pdf>.
- ST **DS10925 Rev. 11**, sections 5.6, 7.6.12/13 and 7.6.36,
  IC_REF/UID tables 83/85: <https://www.st.com/resource/en/datasheet/st25dv04k.pdf>.
- ACS **ACR1552U Series Reference Manual v1.09**, section 5.3.4.2:
  explicit FF-FB flags and custom manufacturer-byte placement. The selected-state
  random-number example uses flags 12; these implementations use addressed flags
  22 and include the acquired UID. No automatic UID insertion (flags 00) is used
  for custom commands.

## Verified password and protection management

`TIso15693SecurityManager` is an inactive nonvisual palette component in the
existing ISO15693 unit. Assign its `Session` to a connected explicitly configured
ACS FF-FB session, just as for the memory component. Public methods have Delphi
XML documentation; configuration changes while `Busy` are rejected.

| Method | Result / change |
| --- | --- |
| `ReadSlix2Protection` | Public AB snapshot: Page H pointer, RL/WL/RH/WH conditions, AFI/EAS/DSFID/PPL locks and one/two feature bitmaps; seven/eleven-byte `Raw` is the complete preimage |
| `ConfigureSlix2Protection` | Both supplied read/write passwords, complete expected AB preimage, new pointer 0..78 and condition bits 0/1/4/5; one B6 change; exact snapshot verification after reset |
| `ChangeSlix2Password` | Supplied old and new four-byte wire-order passwords, identifier 1 (read) or 2 (write); one B4 replacement and new-password acceptance after reset |
| `ReadSt25Configuration` | Static registers 04..0A plus LOCK_CFG at 0F; derives four areas, inactive areas, password numbers and read/write policy from ENDA geometry |
| `ConfigureSt25Area` | Supplied eight-byte configuration password 0, complete expected eight-register snapshot, active area 1..4 and new password/protection selection; one A1 update to RFAxSS only |
| `ChangeSt25Password` | Supplied old/new eight-byte wire-order password for RF number 0..3; one B1 replacement and new-password acceptance after reset |

Snapshot methods perform no password attempt or RF reset. The ST `Raw` array is
in register order 04,05,06,07,08,09,0A,0F; ENDA units are eight blocks, with the last
area ending at the acquired memory limit. Repeated ending boundaries produce
inactive zero-length areas. Area 1 remains readable even for protection code 2
or 3; areas 2..4 require a user password for code 2/3, and code 3 forbids writing.
Unrelated high RFAxSS bits, all area boundaries and LOCK_CFG are preserved by
policy changes. Requests that would make a protected area unopenable with
password number 0 are refused, except area 1's readable/write-forbidden policy.
No area partitioning, automatic password allocation or permanent configuration
locking is performed. A locked SLIX2 PPL or ST LOCK_CFG denies configuration
changes. ST password replacement remains possible when static configuration is
locked, as specified by ST.

Mutations require `IIso15693FieldReset` and `IIso15693CustomCommands` before the
first transaction. A backend lacking explicit RF reset may still read public
snapshots, but cannot claim verified password/protection changes. No reset is
added to ordinary memory/password-session operations.

The concrete `TAcr1552Iso15693Session.ResetField` uses the ACS v1.09 manage-session
protocol (sections 5.3.5.3.1..5):

1. `FF C2 00 00 02 81 00` starts transparent mode and disables polling.
2. `FF C2 00 00 0B 83 00 5F 46 04 10 27 00 00 84 00` turns RF off, waits
   10,000 microseconds (little-endian timer) and turns it on.
3. `FF C2 00 00 02 82 00` ends transparent mode and restores prior polling.
4. Addressed 2B/3B reacquires system information and verifies unchanged UID,
   block count/size and IC-reference presence/value.

For these manage APDUs the adapter accepts only the documented empty success
payload or `C0 03 00 90 00`, together with APDU SW=9000. Error/index/status TLVs
are not treated as success merely because the outer status is 9000. A failure
ends transparent mode best-effort and poisons the ISO session; no RF command is
retried. A reader failure can still leave the physical field/polling state
unknown. These are explicit PC/SC APDUs, not E0 escape commands sent through the
wrong transport interface.

Password updates reset RF before authenticating the old credential, dispatch the
replacement once, reset again, verify the same identity/geometry and authenticate
the new credential. Identical old/new credentials are a verified no-op after
one reset and one supplied-password proof. Protection changes similarly acquire
fresh authentication, compare the complete supplied configuration preimage,
write once and compare the complete public snapshot after another reset. Neither
successful verification nor ending the transaction revokes the last accepted
RF password; the card can remain authenticated until another RF reset.

ST mutations read `EH_CTRL_Dyn` via AD pointer 02. If VCC_ON bit 3 is set, the
caller must explicitly guarantee stable external VCC for the programming cycle
(`AExternalPowerStable=True`); otherwise programming is refused before dispatch.
This is a caller guarantee, not an automatic power-control feature. ST recommends
this check for password writes because a VCC loss during programming may corrupt
the password. A separate I²C host can still modify configuration between RF
reads; PC/SC exclusivity does not lock that host, and preimage/read-back checks
cannot make the entire operation atomic across both interfaces.

After any mutation dispatch, a status, RF reset, identity, password proof,
read-back or transaction-release failure produces `EContactlessWriteUncertain`.
The component performs no retry or rollback. Supplied password arrays are owned
copies, temporary authentication/command buffers are wiped and exceptions omit
password/card contents. Destructive privacy/destroy commands, permanent password
locks, 64-bit irreversible mode changes and ST25TV/KC dialects are not exposed.

The own DFM forms in `Slix2Demo` and `St25DvDemo` add three pages each for these
operations. Snapshot output includes the exact preimage and decoded state; the
raw bytes can also be exported. Replacement credentials are masked and wiped
through the existing worker lifecycle. No keys or default passwords are embedded.

Additional protocol references: NXP SL2S2602 Rev.4.2 sections 9.5.3.3, 9.5.3.6
and 9.5.3.18; ST DS10925 Rev.11 sections 5.6, 7.6.26/27, 7.6.28 (EH_CTRL_Dyn)
and 7.6.35/36. The RF snapshot covers user-area policy, not a dump of every system
register or I²C setting.
