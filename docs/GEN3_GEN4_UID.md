# Gen3 and Gen4 UMC UID profiles

`TRawUidProgrammer` now includes `ProgramGen3Uid` and `ProgramGen4Uid`, using the
existing `IRawContactlessReader` contract. Stateless layout/command helpers and
result types live in `ERD.Card.Contactless.UID.Profiles`. The runtime package includes
that unit; dependencies remain RTL and CardCore. All visible declarations have
English Embarcadero-style XML documentation.

These are independently implemented protocol paths with synthetic transcript
validation. Physical chip/reader/firmware/driver validation and Delphi/RAD Studio
checks remain pending. Gen4 **UMC/GTU** here means the password-bearing `CF` command
dialect. It is separate from USCUID/GDM configuration or alternate seven-bit unlock
modes, despite products sometimes sharing a marketing generation number. The
separate implemented USCUID/GDM profiles are described in
[USCUID_FUID.md](USCUID_FUID.md).

## Reader setup

Use a documented raw-RF backend with retained selection, manual CRC-A, exact bit
counts, exclusive sessions and one card in the field. Gen3 commands need a response
budget of at least two seconds; Gen4 needs at least one second. For the concrete
ACR122U/PN532 PICC adapter:

```pascal
Programmer := TRawUidProgrammer.Create(nil);
try
  Programmer.Reader := TAcr122RawReader.Create(ConnectedCard.Transport, $10, True);
  Gen3Result := Programmer.ProgramGen3Uid(g3us7Byte, RequestedUid);
finally
  Programmer.Free;
end;
```

Add `ERD.Card.Contactless.Raw`, `ERD.Card.Contactless.ACR122` and
`ERD.Card.Contactless.UID.Profiles` to uses. Declare `Programmer: TRawUidProgrammer`,
`Gen3Result: TGen3UidResult` and `RequestedUid: TBytes`; `ConnectedCard` is an already
connected compatible `TSmartCardReader`, kept alive until the programmer is freed.
The example performs an explicit write when executed, not automatic card probing.

The adapter constructor now accepts optional `AResponseTimeoutCode` and
`ASkipAutomaticRats` arguments, preserving the previous defaults. PN532 codes
01..10 hex represent 100 microseconds through 3276.8 ms in powers of two; zero
(infinite) and codes above10 are rejected before hardware access. Code10 provides
the longer bounded response window. ATR timing remains 102.4 ms; retries remain zero.
These timing/retry settings persist until reader reset or deliberate reconfiguration.

With `ASkipAutomaticRats=True`, sessions explicitly set PN532 parameters24, disabling
automatic RATS while retaining the documented baseline's other enabled parameters.
Selection then accepts a SAK indicating ISO 14443-4 without requiring an ATS response:
the raw vendor commands are issued before entering the ISO 14443-4 state.
Cleanup restores documented baseline parameters34, **not an unknown caller's previous
custom parameter set**. That restoration is attempted even after framing restoration
or RF-off failure, and exclusivity is still released. Dedicate the reader to this
adapter during use and reconfigure it deliberately before other workflows.

The existing [raw-reader lifecycle](RAW_UID.md) still applies: no escape fallback,
RF-off/power-down/fresh selection for activation, temporary register restoration,
RF off on release, and no concurrent EMV/eID/storage transactions.

## Gen3: an independent UID register

Select `g3us4Byte` or `g3us7Byte`. The requested size must match fresh RF selection.
The raw UID-only payload is `90 FB CC CC 07` followed by four or seven UID bytes,
then CRC-A. The legacy07 field stays fixed for both variants, as in the inspected
protocol implementation. This APDU-shaped command is **raw RF**; do not feed it to
the ISO 7816 command codec or send it directly as a PC/SC application APDU.

The operation:

1. Validates size, UID length and cascade position before acquisition.
2. Freshly selects and reads all sixteen manufacturer-block bytes with `30 00`.
3. If the active UID matches, returns an unchanged, verified no-op snapshot.
4. Otherwise sends one UID-only command and requires exactly `90 00 FD 07`:
   status 9000 plus valid CRC-A, as a complete 32-bit RF response. Four-bit ACK,
   truncated CRC, unexpected status or timeout is not accepted.
5. Waits one second for the documented card-memory reset interval, then freshly
   selects the requested UID and rereads block zero, requiring all bytes unchanged.
6. Returns only after successful session release.

Gen3's UID register is independent of block zero. Its embedded old UID/BCC may
already differ from the active RF UID; that is permitted. `TGen3UidResult` exposes
the explicit size, previous/requested UIDs, unchanged manufacturer block and
`ActiveUidVerified=True`. Buffers are independent on return; ordinary record
assignment shares arrays. The method never sends manufacturer-block commandF0
or permanent-freeze commandFD. It blocks on the caller thread during I/O and the
one-second settling interval; applications can put the complete session on a
dedicated worker thread, without moving an active transaction between threads.

## Gen4 UMC: existing configured layouts

Call `Programmer.ProgramGen4Uid(Layout, RequestedUid, BackdoorPassword)` with
`TGen4UidResult` output and an explicit four-byte password. No default password,
key discovery, password change or configuration write is supplied.

| Layout | Configured protocol / UID length | Manufacturer blocks and preparation |
| --- | --- | --- |
| `g4ulClassic4` | Classic /4 | Block0 bytes0..3 UID, byte4 corrected XOR BCC; bytes5..15 preserved |
| `g4ulClassic7` | Classic /7 | Block0 bytes0..6 UID; bytes7..15 preserved without inserting a BCC into metadata |
| `g4ulClassic10` | Classic /10 | Block0 bytes0..9 UID; bytes10..15 preserved |
| `g4ulType2_4` | Type2 /4 | Block0 bytes0..3 UID; all remaining bytes preserved |
| `g4ulType2_7` | Type2 /7 | UID0..2/BCC0 in block0's first four bytes, UID3..6 in block1, BCC1 at block2 byte0 |
| `g4ulType2_10` | Type2 /10 | Block0 bytes0..9 UID; all remaining bytes preserved |

The four/ten-byte Type2 layouts are special UMC emulation layouts, not ordinary
Ultralight/NTAG manufacturer-page layouts. In split seven-byte Type2 mode, `CF`
reads/writes still operate on **sixteen-byte backdoor blocks**; only their first
four bytes map into a Type2 page. Preserve every hidden twelve-byte tail as well
as internal/static-lock bytes in block2. The OTP/CC block3 is not written.

The operation freshly selects, verifies the configured UID length and reads
`CF password C6 + CRC-A`. Configuration responses must contain 30 or 32 bytes plus
valid RF CRC. Bytes0/1 must match the requested protocol/UID size, GTU mode byte6
must be02 (stable storage), and ATS length byte7 must be at most16. Shadow mode00,
restore/split mode01/04, high-speed mode03 and unknown modes fail before writes.
The method does not change modes to make a profile fit.

Read required blocks with `CF password CE block + CRC-A`; each response must be
sixteen bytes plus valid CRC. Decode the UID and require equality with fresh
selection. Split Type2 mode also validates both original stored BCCs. Other UMC
layouts calculate RF BCC on-card; an original stored Classic BCC need not be used
by its RF selection. A no-op returns the **actual original blocks** unchanged,
including any differing stored BCC, and dispatches no write.

For a changed UID, deep-copy and prepare the required blocks, then send each
`CF password CD block data16 + CRC-A` once. Each write needs a full 32-bit 9000/CRC
response, not a four-bit ACK. After writes, freshly select and compare the UID,
reread and compare the entire configuration, then reread and compare **all sixteen bytes
of every required block**. Verification happens after RF reactivation, so a
transient shadow read-back cannot be presented as persistent programming success.
Only then release and return `TGen4UidResult`, with layout, independent identifiers,
independent full manufacturer blocks and `ActiveUidVerified=True`.

UID size must already be configured. There are no CF68 UID-length, CF69 protocol,
CF35 ATQA/SAK, CF34 ATS, CFFE password, CFF0 configuration or CFF1 fuse commands in
this operation. Changing chip type, identifier size or permanent settings is a
separate future API, not an implicit side effect of UID programming.

## Failure, ownership and validation

Both methods reject invalid inputs before I/O and retain preparation errors until
the first programming dispatch. Every failure from that dispatch onward becomes
`EContactlessWriteUncertain`, including a denied status, transport loss, malformed
CRC/framing, wrong/stale freshly selected UID, changed Gen3 block, changed Gen4
configuration/hidden bytes, or cleanup failure. Only the original error class is
retained. A primary failure wins over release errors. No automatic replay, rollback,
partial success snapshot or permanent lock operation occurs.

Gen4 split writes are not atomic: interrupted programming may leave an inconsistent
UID/BCC and prevent normal activation. Inspect/recover the actual card through an
appropriate backend before attempting further programming. Reader transactions
cannot roll back EEPROM. No real card, fuse or access-controller operation was
performed during development.

The programmer overwrites its local password-bearing command and configuration
buffers on success and failure; the concrete adapter also overwrites its command
and response copies. Caller password/UID arrays are not modified. This does not
provide secure-memory allocation or control external backend/transport logging or
copies. Configuration/password data is not returned in the result.

Tests cover fixed Gen3 framing, independent UID/block semantics, one dispatch per operation,
all six Gen4 layouts,30/32-byte configurations, shadow/restore rejection, cascade
rules including ten-byte UID3, complete visible/hidden-byte preservation, no-ops,
local password-command overwriting, each partial block write, fresh activation,
configuration/CRC/metadata failures and cleanup precedence. A complete ten-byte
Gen4 transcript runs through the concrete ACR122 adapter with RATS disabled and
baseline restoration. Compiler/static-check results are in [VALIDATION.md](VALIDATION.md).

## Protocol sources

Checked on 2026-10-07 against protocol/layout facts at Proxmark3 commit
`305b259fbe8e582ba0f55d6237d45ad580264e42`. Only facts were used; implementation
was independently written and no third-party source or binary was bundled.

- [Magic-card notes](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/doc/magic_cards_notes.md),
  Gen3 and Gen4 UMC sections; hash recorded in [PROGRAMMABLE_UID.md](PROGRAMMABLE_UID.md).
- [Gen3/Gen4 RF command framing and responses](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/armsrc/mifarecmd.c),
  inspected for fixed07,9000/CRC response, memory reset delay and CE/CD block lengths.
  SHA-256 `a69a79400ea54635997120d449483fce9da4ef14cd130346f6d2def3169e2d3c`.
- [Gen4 configuration framing](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/client/src/mifare/gen4.c),
  SHA-256 `f4579c03fbee71324c749f51449d2ab68bdd8a3ecb00689107ea5d267accecdc`;
  configuration field offsets checked against the notes and `client/src/cmdhfmf.c`
  at the same commit.
- [NXP PN532 user manual](https://www.nxp.com/docs/en/user-guide/141520.pdf),
  sections 7.2.9/7.3.1 for SetParameters, automatic RATS and finite RF timing codes;
  hash recorded in [RAW_UID.md](RAW_UID.md).
- [NXP AN10927 UID handling](https://www.nxp.com/docs/en/application-note/AN10927.pdf),
  cascade restrictions for four/seven/ten-byte identifiers.
