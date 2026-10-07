# Gen1b and partial USCUID UID profiles

`TRawUidProgrammer` adds four-byte **Gen1b** and explicit configuration-verified
**unsealed UFUID, ZUID and PFUID** programming. These are independently implemented
paths with synthetic transcript tests, including complete ACR122U/PN532 integration.
Physical chip/reader/firmware/driver testing, Delphi compilation and Help Insight
inspection remain pending. UID contents and a successful PC/SC read do not identify
one of these variants.

Use an exclusive raw Type A backend with manual CRC-A, exact bit counts, bounded
RF timeouts, retained selection and no automatic retry. Configure `Reader` explicitly
and keep one card in the RF field. The [raw-reader lifecycle](RAW_UID.md) and
[ACR122U/PN532 setup](GEN3_GEN4_UID.md#reader-setup) apply. For an existing SAK
advertising ISO14443-4, configure automatic RATS suppression before the session.

All visible API declarations use English Embarcadero XML comments, and the new
`ERD.Card.Contactless.UID.Partial` unit is included in `ERDCardContactless.dpk`.
Dependencies remain RTL and CardCore. Existing reader-interface GUIDs are unchanged.

## Gen1b: seven-bit40 only

Add `ERD.Card.Contactless.Raw` and `ERD.Card.Contactless.UID` to uses:

```pascal
ResultData := Programmer.ProgramClassicUid(crupGen1b, RequestedUid);
```

Here `Programmer: TRawUidProgrammer` has its raw `Reader` assigned,
`ResultData: TProgrammableUidResult`, and `RequestedUid: TBytes` has four bytes.
This is an explicit write operation when executed. The new enum value is appended:
existing `crupGen1a` and `crupUnsealedUfuid` retain their ordinals and sequences.

The operation validates the selected profile and target before acquisition, freshly
selects a four-byte UID, sends HALT with CRC-A and requires its explicit RF timeout.
It then sends **seven-bit40 only** and requires a four-bit ACK. There is no43,
second wakeup probe or attempt to reinterpret a failed Gen1a unlock as Gen1b.

Read public block0 with `30 00 + CRC-A`; validate full-byte framing, all eighteen
response bytes, CRC, stored XOR BCC and equality of embedded/current RF UID.
Prepare an independent sixteen-byte block, replacing UID0..3 and BCC4 and retaining
every byte5..15. A matching UID returns the actual original snapshot without writing.
Otherwise send `A0 00 + CRC-A`, require a four-bit ACK, send the prepared block/CRC
and require a second ACK. Read and compare all sixteen bytes before reactivation.

After fresh RF selection of the target UID, repeat HALT/seven-bit40 and reread the
entire manufacturer block, requiring unchanged written bytes after RF reset.
Return only after successful session release, with independent previous/requested
UIDs, verified full block, `Model=cgum4Byte` and `ActiveUidVerified=True`. No block
metadata, ATQA or SAK is reset to an assumed default. Ordinary record assignment
shares arrays.

## Partial USCUID: explicit configuration dialects

Add `ERD.Card.Contactless.UID.Partial` to uses:

```pascal
ResultData := Programmer.ProgramPartialUscuidUid(pupPfuid, RequestedUid);
```

Declare `ResultData: TPartialUscuidUidResult`; the target is exactly four bytes.
The profile must be selected by the caller **before any configuration command**.

| Profile | Existing documented configuration | Configuration read |
| --- | --- | --- |
| `pupUnsealedUfuid` | `7AFF000000000000BAFA000000000008` | `E0 00 + CRC-A` |
| `pupZuid` | `7AFF0000000000000000000000000008` | `E0 00 + CRC-A` |
| `pupPfuid` | `7AFF000000000000BAFA358500000008` | `E1 00 + CRC-A` |

These chips partially implement USCUID features but still return **sixteen**
configuration bytes, not an eight-byte response. Their opaque reserved markers
are distinct from full USCUID's personalization/shadow/Magic Auth settings.
PFUID's35/85 bytes must not be decoded as those full-feature settings.
`TPartialUscuidUidCodec` validates the documented shapes and supplies the selected
read opcode. Unknown marker revisions require another explicit profile.

Accepted shapes retain header bytes0..5=`7AFF00000000`; bytes6 and7 may each be00
or5A, while bytes8..14 must match the selected row. Byte15 is preserved SAK and
must not indicate another UID cascade. The method does not write or normalize any
of these bytes, change direct-write/key behavior or infer which optional features
an individual chip implements. Disabled/sealed headers and other wakeup styles
fail before manufacturer writing. There is no unseal operation.

**PFUID configuration commands are reversed.** `E1 00` is used only as the selected
PFUID read. On UFUID/full USCUID the same opcode can begin a configuration-write
handshake. This API does not probe alternate opcodes, infer PFUID after a failed
read, or send any sixteen-byte configuration data. An ACK, timeout or wrong-length
configuration response fails and releases the session without a UID write.

The operation:

1. Validates the profile/read opcode, four-byte target and cascade position before
   acquisition. Target UID0 cannot equal cascade tag88.
2. Acquires one session and freshly selects, requiring a four-byte UID. Sends
   HALT with expected RF timeout, then seven-bit40/byte43 with exact four-bit ACKs.
3. Reads and validates the selected sixteen-byte configuration with CRC-A.
4. Reads block0, verifies CRC/BCC and requires embedded UID equality with fresh
   selection. It never reads hidden blocks or applies full-USCUID source layouts.
5. For a matching target, returns the original block/configuration as a verified
   no-op. Otherwise prepares a copy preserving block bytes5..15 and sends one
   `A0 00`/sixteen-byte-data write with two ACKs and explicit CRC-A.
6. Cycles RF and freshly selects the target, repeats40/43, rereads the chosen
   configuration and full block, and compares **every byte** with the expected
   snapshots. Verification occurs after reactivation to establish persistence.
7. Returns only after successful session release. `TPartialUscuidUidResult` contains
   the explicit profile, independent UIDs, full unchanged configuration, full
   manufacturer block and `ActiveUidVerified=True`.

The older `ProgramClassicUid(crupUnsealedUfuid, ...)` remains the existing caller-
identified Gen1a-compatible operation. The new partial API additionally checks
its configuration dialect and verifies configuration/block persistence. Neither
operation seals, unfuses, writes configuration data or guesses sector keys.

## Failure and validation

Both new paths retain pre-write parameter/selection/unlock/read errors. From the
first manufacturer-write handshake dispatch onward, **every** failure becomes
`EContactlessWriteUncertain`: NAK, timeout, transport loss, malformed framing/CRC,
wrong freshly selected UID, changed stored metadata/configuration or release error.
The exception retains only the original error class, without identifiers, config
bytes or external messages. A primary operation failure wins over cleanup failures.
Failed acquisition owns its own cleanup and is not released as an acquired session.

Neither path returns partial success, automatically retries, replays, rolls back,
changes configuration, wipes, freezes or seals a card. Reader transactions cannot
roll back EEPROM. Inspect actual card state before deciding how to proceed after
an uncertain result. Physical card and access-controller operations were not run.

Tests cover appended enum ordinals, exact40-only Gen1b wakeup, all three explicit
configuration shapes/opcodes, bounded response lengths, marker/profile mismatch,
preserved flags/SAK, invalid/sealed headers, BCC/RF consistency, no-ops, failed write
handshakes/data frames, fresh selection, persistent full-block/configuration
comparison and release precedence. Exact adapter chains exercise Gen1b without43
and PFUID reading `E1 00` before/after writing. Compiler and checker results are
recorded in [VALIDATION.md](VALIDATION.md).

## Protocol sources

Protocol facts checked on 2026-10-07 against Proxmark3 commit
`305b259fbe8e582ba0f55d6237d45ad580264e42`; no third-party implementation or binary
is bundled. New code and synthetic fixtures were independently written.

- [Magic-card notes](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/doc/magic_cards_notes.md):
  Gen1B40-only access, USCUID variation table, partial-feature limitations,
  reversed PFUID configuration commands, and UFUID/ZUID characteristics.
  SHA-256 `9409de8f160a5124d751915ba237dd33a73f01d76a71afbf3ca942943f282821`.
- [Raw wakeup command facts](https://github.com/RfidResearchGroup/proxmark3/blob/305b259fbe8e582ba0f55d6237d45ad580264e42/armsrc/mifarecmd.c):
  `MF_WAKE_GEN1B` sends40 without43. Its probing/fallback behavior elsewhere is
  not part of this API. SHA-256
  `a69a79400ea54635997120d449483fce9da4ef14cd130346f6d2def3169e2d3c`.
- [NXP PN532 user manual](https://www.nxp.com/docs/en/user-guide/141520.pdf)
  and [PN532/C1 datasheet](https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf):
  manual framing, register access and RF selection; hashes in [RAW_UID.md](RAW_UID.md).
- [NXP AN10927](https://www.nxp.com/docs/en/application-note/AN10927.pdf):
  four-byte UID cascade-tag restrictions.

Full USCUID/GDM public/hidden layouts and factory FUID single writes remain in
[USCUID_FUID.md](USCUID_FUID.md). Magic Auth/Crypto1, other OTP variants and LF/UHF
families remain distinct future protocols. See [the support matrix](PROGRAMMABLE_UID.md).
