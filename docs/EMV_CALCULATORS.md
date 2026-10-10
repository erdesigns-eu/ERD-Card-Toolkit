# Offline EMV calculations

`ERD.Card.EMV.Calculator` provides the nonvisual `TEmvCalculator`, registered on
**ERD Cards** and included in `ERDCardEMV`. The component performs deterministic
offline computations with keys supplied by the application. Construction opens no
reader, library or session. It stores provider interfaces, never keys.

## Implemented calculations

| Area | Implemented API |
| --- | --- |
| Key tools | Odd DES parity/checking; DES/2K3DES/3K3DES encrypted-zero KCV; AES-128 encrypted-zero KCV |
| ICC master keys / UDK | EMV Option A and B, with decimal PAN/PSN validation and odd DES parity |
| Session keys | Explicit eight-byte common diversification, ATC common key, ATC/UN Mastercard variant, Visa script-key XOR variant, EMV 2000 tree with explicit IV/height/branch factor |
| MAC/padding | ISO 9797-1 padding methods 1 and 2; algorithm-3 Retail MAC with explicit truncation; AES-128 CMAC |
| Application cryptograms | ARQC/TC/AAC over complete supplied data; full eight-byte recomputation/verification |
| Issuer authentication | ARPC methods 1 and 2, generation and verification; explicit response code, CSU and proprietary authentication data |
| Script tools | SMI Retail MAC over explicitly assembled authenticated bytes; Visa length-prefixed ECB, Mastercard conditionally padded CBC and EMV always-padded CBC confidentiality |
| PIN formatting | ISO 9564 format-two clear PIN block; Visa PIN-change block with optional current PIN |
| Complete profile assembly | Typed transaction fields, checked BCD/fixed lengths, selected CVR/IAD/counter tail, AC key derivation and profile-specific ARPC key choice |

The clear PIN formatting helpers do not verify a PIN or send a change command.
Script tools return bytes only; no issuer command, GENERATE AC, authorization,
payment connection or certified kernel is implemented.

## Explicit scheme/CVN profiles

These profiles describe the calculation formats covered by committed independent
vectors. Select the scheme **and** CVN explicitly; the number alone is insufficient.
Issuer-specific IAD offsets, encrypted counters and newer variants are not inferred.

| Profile | AC key | Appended issuer data | AC padding | ARPC |
| --- | --- | --- | --- | --- |
| Visa 10 | ICC AC master key directly | Four-byte extracted CVR | Method 1 | Method 1 with master key |
| Visa 18 / 22 | Common ATC-derived key | Complete IAD, 1–32 bytes | Method 2 | Method 2 with common ATC key |
| Mastercard 16 | ATC/UN-derived key | Six-byte extracted CVR | Method 2 | Method 1 with **master key**, not AC session key |
| Mastercard 17 | ATC/UN-derived key | Six-byte CVR + eight clear counter bytes | Method 2 | Method 1 with **master key** |
| Mastercard 20 | Common ATC-derived key | Six-byte extracted CVR | Method 2 | Method 1 with common ATC key |
| Mastercard 21 | Common ATC-derived key | Six-byte CVR + eight clear counter bytes | Method 2 | Method 1 with common ATC key |
| Interac 133 | ATC/UN-derived key | Complete IAD, 1–32 bytes | Method 2 | Method 1 with ATC/UN key |

`BuildCryptogramData` requires the common fields, in order:
9F02(6), 9F03(6), 9F1A(2), 95(5), 5F2A(2), 9A(3), 9C(1), 9F37(4), 82(2),
9F36(2), followed by the selected profile tail. CVR must already be extracted
using the issuer specification. Mastercard counter bytes must already be clear.
Unrelated IAD/CVR/counter tails are rejected rather than silently ignored.
Numeric fields require decimal BCD; date semantics and terminal risk evaluation
remain application responsibilities.

`ProfileCryptogram` composes data/key/padding. `ProfileArpc1` and `ProfileArpc2`
use the respective profile key rules and refuse profiles belonging to the other
ARPC method. General `ApplicationCryptogram` and `RetailMac` also permit explicit
custom messages when a documented profile has a different input sequence.

This is a complete toolkit for the declared profiles, not a claim that all
proprietary CVNs have the same mathematics. AES-128 CMAC and AES KCV are general
primitives here; AES-192/256, AES-specific EMV master/session-key profiles,
RSA/SDA/DDA/CDA key recovery and proprietary undocumented CVNs are not implemented.

## Provider setup and example

On Windows, use `TCardWindowsAesProvider` (Windows CNG, AES and DES capabilities)
and `TCardWindowsHashProvider` (CNG SHA-1). Linux tests use
`TCardOpenSslAesProvider` and `TCardOpenSSLHashProvider`, backed by OpenSSL 3.
Optional SHA-1 is needed only for Option B with PANs longer than sixteen digits.
It is part of that legacy derivation, not a choice of modern signature hash.
The standalone design package retains source-only ownership and needs no runtime
BPL dependencies. Native providers belong to their existing optional runtime
packages, not the EMV package.

```pascal
Calculator := TEmvCalculator.Create(nil);
try
  Calculator.DesProvider := TCardWindowsAesProvider.Create;
  Calculator.AesProvider := TCardWindowsAesProvider.Create;
  Calculator.HashProvider := TCardWindowsHashProvider.Create;
  // All inputs below are supplied by your application, with an explicit profile.
  IccKey := Calculator.DeriveMasterKey(IssuerKey, Pan, Psn, emkOptionA);
  SessionKey := Calculator.DeriveAtcSessionKey(IccKey, Atc);
  Cryptogram := Calculator.ApplicationCryptogram(SessionKey, CompleteData, empMethod2);
  Matches := Calculator.VerifyApplicationCryptogram(SessionKey, CompleteData,
    ReceivedCryptogram, empMethod2);
finally
  TCardCrypto.Clear(IccKey);
  TCardCrypto.Clear(SessionKey);
  TCardCrypto.Clear(Cryptogram);
  Calculator.Free;
end;
```

Arrays returned by calculations have independent storage. Borrowed keys/PAN data
are not changed. Owned intermediate key/MAC buffers are cleared on success and
failure; caller-owned output buffers must be cleared after use. Managed strings,
compiler temporaries and backend copies cannot be guaranteed erased.
Calculations are bounded to `EmvCalculatorMaxData`; no deterministic RNG or default
keys are supplied. Provider failures and wrong primitive/digest lengths propagate
without retry and without exposing input bytes in exception messages.

## Changes from the original calculators

The original UI fixed ARQC generation to CVN 18 and offered only Option A and one
ATC session-key method. Its common helper treated other cryptogram versions as a
single padding alternative. The new API explicitly separates diversification,
message assembly, padding, AC and ARPC key choice. Option B, tree/Visa/ATC-UN
variants, ARPC, verification, KCV, script helpers and PIN formatting are added.
Native libraries replace the old LockBox primitive wrappers; sizes and field
formats fail explicitly instead of returning empty results.

## Designer demo and validation

Open `examples/vcl/emvcalculator/EmvCalculatorDemo.dproj`. The standalone TForm and
DFM expose every calculator operation, explicit profiles, complete transaction
fields and required-input help. The calculator is offline, so it needs no reader
selector. Keys/PINs are masked; calculated output is displayed deliberately.
The clear button clears all entered text and output. Native providers are created
only when a calculation is requested; no card hardware is opened.

`tests/emv/fixtures/calculators.txt` contains **2,695 synthetic independent vectors**
computed with pinned **pyemv 1.5.0**, including all eight profile AC/ARPC workflows,
Option B long PANs, four tree geometries, empty/aligned/unaligned messages, both
ARPC methods, script modes, PIN blocks and AES-CMAC. The Pascal runner also checks
modified cryptograms, input preservation, primitive failures, output-length
contracts, missing capabilities and invalid bounds/fields. Actual Windows adapter
branches run through the existing OpenSSL-backed Linux CNG ABI shim, including
native SHA-1 lifecycle failures. These checks do not execute Windows or replace
Delphi compilation.

Optional fixture regeneration (outside normal build dependencies):

```sh
python3 -m pip install --target /tmp/emv-reference --no-deps pyemv==1.5.0
PYTHONPATH=/tmp/emv-reference python3 tools/generate_emv_calculator_fixtures.py
```

The generator additionally requires a maintained `cryptography` installation.
Sources: EMV Book 2, sections 8 and Annex A (key/cryptogram methods), ISO/IEC
9797-1 algorithm 3, NIST SP 800-38B (AES-CMAC), ISO 9564 PIN-block formats and
[pyemv 1.5.0](https://pypi.org/project/pyemv/1.5.0/) for independently computed
interoperability vectors. No pyemv implementation is shipped as runtime code.
