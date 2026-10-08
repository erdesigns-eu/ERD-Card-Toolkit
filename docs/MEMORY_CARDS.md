# Contact memory cards

`TMemoryCardReaderWriter` provides direct, non-Java main-memory access through the
published ACS pseudo-APDU protocols. Construction performs no I/O. The component
is available in `ERDCardMemory` and on the `ERD Cards` palette.

## Concrete profiles

| Models | Main memory | PIN | Protection |
| --- | --- | --- | --- |
| SLE4432 / SLE5532 | 256 bytes | None | One irreversible bit per first 32 bytes |
| SLE4442 / SLE5542 | 256 bytes | 3 supplied bytes | One irreversible bit per first 32 bytes |
| SLE4418 / SLE5518 | 1024 bytes | None | One irreversible bit per main-memory byte |
| SLE4428 / SLE5528 | 1024 bytes | 2 supplied bytes | One irreversible bit per main-memory byte |
| I2C 1/2/4/8/16 kilobit | 128/256/512/1024/2048 bytes | None in this profile | No supported lock bitmap |
| I2C 32/64/128/256/512/1024 kilobit | 4096 through 131072 bytes | None in this profile | No supported lock bitmap |

These are implemented protocol/geometry profiles, not hardware certification.
A suitable ACS contact reader and its memory-card driver/firmware are required.
A generic PC/SC CPU-card or NFC reader does not necessarily support them. Supply
both the actual chip model and the matching reader dialect; there is no automatic
ATR-based detection, command probing or fallback.

`amdAcr38Ccid` follows ACR38x **CCID** reference 6.05. `amdAcr39` follows ACR39
Series reference 1.05. The older non-CCID ACR38 API is not assumed compatible.
For the two-wire SLE models, ACR38 CCID returns exactly the requested memory
bytes; ACR39 additionally returns four protection bytes. The codec strictly checks
this selected shape and strips the ACR39 trailer. Three-wire/I2C reads have no
such trailer. Protection is acquired separately when needed.

For I2C, supply the physical page size from the actual chip's data sheet: 8, 16,
32, 64 or 128 bytes. Capacity does not identify page size or a particular 24Cxx
part. Other page sizes, protected I2C variants and other addressing dialects are
not implemented. The 1024-kilobit profile carries address bit 16 in the low INS
bit (B0/B1 and D0/D1); reads/writes are split at the 64-KiB bank boundary.

## Use from an application

Add `src/core`, `src/pcsc` and `src/memory` to the unit search path, or use matching
runtime packages. The PC/SC component supplies the required `ICardTransport` and
`ICardTransaction`; custom connected transports can implement the same contracts.

```pascal
uses ERD.Card.PCSC.Reader, ERD.Card.Memory;

procedure ReadMemoryExample(const ReaderName: UnicodeString);
var
  Card: TSmartCardReader;
  Memory: TMemoryCardReaderWriter;
  Snapshot: TMemoryCardSnapshot;
begin
  Card := TSmartCardReader.Create(nil);
  try
    Memory := TMemoryCardReaderWriter.Create(nil);
    try
      Card.ReaderName := ReaderName;
      Memory.Model := mcmSle4442;
      Memory.Dialect := amdAcr38Ccid; // Set amdAcr39 for the documented ACR39 profile.
      Card.Connect;
      Memory.Transport := Card.Transport;
      Snapshot := Memory.ReadSnapshot;
      // Snapshot.Data, .Protection and .Security are independent owned results.
      Card.Disconnect;
    finally
      Memory.Free;
    end;
  finally
    Card.Free;
  end;
end;
```

Use all configuration and operations on one owning thread; the component rejects
reentrant calls and changes while busy. Put application I/O on a worker, as in the
VCL demos. Interface references keep the transport object alive, not its physical
connection. Each operation requires an exclusive transaction, selects/resets the
card once, and releases exactly once. Selection power-cycles the card and clears
prior authentication. No reset occurs between ordinary chunks.

- `ReadMemory(Address, Count)` reads a bounded public range without authenticating.
- `ReadSnapshot` reads all main memory, the SLE protection bitmap and available
  retry status. No PIN or security-memory dummy bytes are returned.
- `VerifyPin(Pin)` presents the supplied PIN once, requires exact success status,
  and checks that the retry counter is restored. It does not retain authentication
  for a subsequent component call.
- `WriteMemory(Address, Data, Pin)` acquires current bytes and protection before
  authenticating or mutating. Changed locked SLE ranges are refused. Each write
  is sent once and verified independently; I2C chunks stay within physical pages.
  Plain SLE/I2C requires an empty PIN. Identical data is a no-op without a PIN
  attempt; it is not proof of the supplied PIN.
- `ChangePin(OldPin, NewPin)` supports SLE4442/5542 only. It verifies the current
  PIN, sends the documented update, explicitly resets, and proves the new PIN once.
  There is no old-PIN fallback. Three-wire PIN replacement is not documented by
  these reader references and is refused before I/O.
- `ProtectMemory(Address, ExpectedBytes, Pin)` explicitly and **irreversibly**
  programs matching SLE protection bits to zero. It checks current contents before
  dispatch, then checks locked bits and unchanged bytes. This is distinct from
  ordinary writing. An already locked matching range is a no-op.

## Authentication and uncertain mutations

The correct authentication status is **9007** for SLE4442/5542 and **90FF** for
SLE4428/5528, not ordinary 9000. Before authentication the retry bitmap is read;
`MinimumPinAttempts` controls the required remaining budget, default one.
Zero remaining bits prevents an attempt. Each wrong or ambiguous attempt can
consume a retry bit and eventually permanently block the PIN. No PIN is guessed,
reversed, remembered across calls, logged or retried automatically.

`EMemoryCardAuthenticationError` means an authentication command was dispatched
but its success could not be proven. Its message contains only an error class.
`EMemoryCardWriteUncertain` covers every failure after a main-memory, PIN or
protection mutation was dispatched, including bad status, read-back mismatch and
transaction release. `Verified` retains proof obtained before a later cleanup
failure; it does not make that failure a successful completion. Inspect actual
card state before deciding on another mutation. No rollback or replay is attempted.

The component copies PINs before I/O and wipes its owned PIN-bearing command,
response and credential arrays on exit. Transport/backend copies are outside this
guarantee. Managed arrays and the host process do not provide secure-memory
allocation. PIN verification is plaintext access control, not secure messaging or
cryptographic authenticity. Main-memory/ATR/manufacturer locations are not
interpreted: writing any unlocked address requires the application's knowledge
of the actual card layout.

## Protocol evidence and original CardStudio

The authoritative reader references are:

- [ACS ACR38x CCID Reference Manual 6.05](https://www.acs.com.hk/download-manual/3450/REF-ACR38x-CCID-6.05.pdf), sections 9.3.1/2/5/6.
- [ACS ACR39 Series Reference Manual 1.05](https://www.acs.com.hk/download-manual/6047/REF-ACR39-Series-1.05.pdf), sections 8.1–8.4.

Selection uses `FF A4 00 00 01` with selectors 01/02/05/06. Ordinary writes use
`FF D0`, protection uses `FF D1`, PIN presentation uses `FF 20`, and two-wire PIN
replacement uses `FF D2 00 01 03`. Security/protection reads use B1/B2.

The legacy CardStudio memory forms were SLE4442-specific and used D6/21 plus a
9000 authentication check. They did not identify a documented matching reader
profile or verify writes. Their commands were inspiration, not copied as a
universal protocol. The separate legacy card initialization/ATR-changing tools
are not covered by this ordinary memory component.

`InspectMemoryCard --model sle4442` reports geometry without hardware. To read:

```text
InspectMemoryCard --model sle4442 --reader "Exact PC/SC reader" --dialect acr39
InspectMemoryCard --model i2c64kbit --reader "Exact PC/SC reader" --dialect acr38-ccid --page-size 32
```

The console example reports lengths/status only and never authenticates or writes.
The test suite uses literal synthetic transcripts for reads, PINs, PIN replacement,
protection and I2C page/bank boundaries. It injects every I/O failure in write/PIN
chains and corrupts every acknowledgement status bit and read-back data bit.
Free Pascal execution and the source readers do not replace Delphi, driver or
physical read/write checks. Hardware validation of these new profiles remains pending.

## Counter-chip profiles and reader capabilities

`TSleCounterCardReaderWriter` implements the distinct SLE4406/4436/5536/6636
command profile from ACR38x CCID reference 6.05, section 9.3.7. These chips are
not treated as ordinary EEPROM. ACR39 counter commands are not documented in
our selected reference and are not claimed available.

| Operation | SLE4406 | SLE4436 | SLE5536 / SLE6636 |
| --- | --- | --- | --- |
| Public byte reads | Yes | Yes | Yes |
| One-to-zero byte programming / carry | Yes | Yes | Yes |
| Backup programming / carry-backup | No | Yes | Yes |
| Raw two-byte certificate calculation | No | Key 1/2, without CBC | Key 1/2, with or without CBC |

`ReadableBytes` is required and has **no guessed chip-capacity default**. It declares
an application-known accessible window starting at byte zero, up to the reader's
256-byte addressing limit. Actual chip geometry, reserved/partial bytes, readable
regions and counter stages must come from the specific card data sheet/application.
The shared ACS selector does not distinguish these models or establish capacity.

`ReadMemory(Address, Count)` reads this window without a code attempt. `WriteByte`
requires complete expected-before and expected-after images for the window. It
compares actual contents before dispatch, refuses zero-to-one changes in the
addressed byte and verifies the entire declared window after the single write.
Ordinary/backup programming permits no expected changes elsewhere; identical
ordinary data is a no-op. Carry operations always dispatch, even if the addressed
byte is unchanged, because they can erase a lower counter stage. Supply a window
covering **all affected stages** and derive the expected image from the actual
chip layout; the component does not compute balances or infer counter arithmetic.
A successful verification concerns this window, not all physical chip state.

```pascal
Counter := TSleCounterCardReaderWriter.Create(nil);
try
  Counter.Model := scmSle5536;
  Counter.ReadableBytes := KnownReadableBytes;
  Counter.Transport := Card.Transport; // Explicit ACR38x CCID reader.
  Before := Counter.ReadMemory(0, Counter.ReadableBytes);
  After := Copy(Before, 0, Length(Before));
  After[KnownWritableAddress] := Before[KnownWritableAddress] and $FE;
  Counter.WriteByte(KnownWritableAddress, After[KnownWritableAddress],
    scwBackup, Before, After);
finally
  Counter.Free;
end;
```

`ReadCertificate(Key, ClockPulses, Challenge)` performs one FF84 challenge,
requires exactly 6102, then performs one FFC0 retrieval and requires two bytes
plus 9000. Challenge length is six; clock pulses are explicitly supplied. Returned
bytes are raw card calculations, **not proof of authenticity**. No host algorithm,
issuer/key verification or generic GET RESPONSE fallback is implied.

`TSleCounterCodec.PresentCode` exposes the documented three-byte code command as
an explicit low-level builder. It consumes a presentation-counter bit; the reader
**does not restore that counter** and 9000 is not proof that the code is correct.
The high-level component therefore does not automatically present codes, unlock
personalisation or reset presentation counters. Callers of the low-level builder
own/wipe its credential-bearing command and must implement chip-specific proof.

`TAcsMemoryCapabilityCatalog.ForDialect` returns offline value sets for ordinary
reads/writes, supplied PIN, PIN replacement, permanent protection, counter profiles
and raw certificate calculation. It **does not query reader firmware or detect
hardware support**. This distinction is also visible in the VCL demo: offline
profile capabilities and connected ATR/negotiated protocol are separate operations.

The memory page offers snapshot/range reads, one supplied-PIN verification and
ordinary verified writes. PIN entry is hexadecimal in card byte order, never a
suggested/default PIN. I2C writes require explicitly selected physical page size.
Counter profiles offer public reads in the demo; deliberate carry/backup writes
are available through the component API. See [VCL steps](VCL_DEMOS.md) and the
[pending hardware matrix](HARDWARE_MATRIX.md).

SLE4404, authenticated AT88SC/CryptoMemory, additional reader dialects and
chip-specific counter arithmetic/personalisation proof remain future work.
