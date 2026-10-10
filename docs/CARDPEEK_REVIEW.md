# CardPeek comparison and candidate extensions

Reviewed [L1L1/cardpeek](https://github.com/L1L1/cardpeek) at commit
[`de8cee209b870f3d7aa1c6bd55e84738765dc1e6`](https://github.com/L1L1/cardpeek/tree/de8cee209b870f3d7aa1c6bd55e84738765dc1e6),
after completing the offline EMV calculators and restored catalogs. This is a
source-level capability comparison, not a claim that CardPeek or new card families
were executed or added here.

## Concrete additions worth building

| Candidate | Evidence in CardPeek | Current components and proposed scope |
| --- | --- | --- |
| OpenPGP card reader | [`openpgp.lua`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/openpgp.lua): SELECT, GET DATA, application identity, cardholder data, algorithm attributes, fingerprints, password status, signature counter and certificate | No OpenPGP component. Add `TOpenPgpCardReader` and typed snapshot/codecs first. Then explicit PIN operations and documented writable data objects. Signing, key generation/import and deletion are separate operations requiring a fuller current specification; CardPeek's beta reader does not establish support for them. |
| Tachograph driver cards | [`tachograph.lua`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/tachograph.lua): file plans, activity/vehicle/place records, card signatures and binary `.ddd` export | No tachograph component. Add bounded file reading, version-specific codecs and compliant export. The older script is not evidence of complete second-generation/Gen2v2 support; define and validate those formats separately. |
| EMV semantic decoders | [`emv.lua`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/emv.lua): CVM lists and AIP/AUC/IAC/TVR bit explanations, currency and country labels | We already read AFL records, decode DOLs and read/parse advertised transaction logs. Book 3 4.3/4.4 typed offline explanations are now implemented for 8E, 82, 9F07, 95 and 9F0D/0E/0F, plus source-versioned ISO country/currency metadata. Return unknown/reserved bits, not guessed meanings. This is decoding, not running a payment kernel. |
| APDU recording and replay | [`smartcard.c`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/smartcard.c), [`replay.c`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/replay.c) and [`drivers/replay_driver.c`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/drivers/replay_driver.c) | Our tests have mock transports, but there is no reusable persisted recording/replay component. Add decorators around `ICardTransport`, explicit opt-in capture/export, deterministic strict command matching and a synthetic demo. Keep captured personal data, PINs and secure-session material out of default diagnostic output. |
| Other Calypso networks | [`calypso/`](https://github.com/L1L1/cardpeek/tree/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/calypso): Paris/Navigo, Lisbon/Viva, Israel/Rav-Kav and other layouts | The generic Calypso reader and provisioned-SAM sessions already exist; typed interpretation is MOBIB-specific. Add a versioned network-profile abstraction and one explicitly supported layout at a time. Historical route names and CardPeek layouts are not current operator activation/fare rules and supply no operator keys. |
| French Vitale 2 | [`vitale_2.lua`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/vitale_2.lua): application selection, file reading and beneficiary TLV fields | No French health-card profile. Add a dedicated read-only profile with original bytes and documented field decoding. Reading a certificate/signature is distinct from verifying its trust chain. |
| Thai identity cards | [`thai eID.lua`](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/dot_cardpeek_dir/scripts/thai%20eID.lua): selected application, binary fields/photo, Thai names/address and Buddhist-calendar dates | No Thai eID profile. Add explicit layout/version selection and text/calendar codecs; preserve partial dates and lifelong expiry without inventing a day/month. This is an optional non-European addition. |

## Already covered or not established by this review

- Belgian eID, BAC passport access, SIM reading, EMV application/record/log reading
  and basic MIFARE overlap with existing components. Our USIM, PACE, native HID,
  memory-chip and NDEF facilities go beyond the corresponding reviewed scripts.
- `emv.lua` explains SDA/DDA/CDA support/failure bits; that is not an implemented
  RSA offline-authentication engine. Such an engine remains useful future work,
  using EMV specifications and provisioned CA public keys.
- `moneo.lua` targets a historical purse. Payments remain outside this project;
  this is lower priority than current reusable card families.
- The inspected source does not provide a JavaCard CAP loader, GlobalPlatform
  secure-channel manager or generic ATR rewriting interface.

## Recommended batches

1. **APDU recording/replay (deferred).** EMV semantic codecs are now implemented. Recording/replay is useful
   in existing applications and provide reproducible input for later card-family
   development. Include independent DFM demos and synthetic fixtures.
2. **OpenPGP public reading + explicit data-object writes/PIN support.** A new
   practical card family; introduce management operations only with their own
   protocol coverage and caller-supplied credentials.
3. **Tachograph reading + `.ddd` export**, with declared generations, followed by
   **Calypso network profiles**. These have different data formats and deserve
   their own test vectors instead of being added as unverified labels.
4. **Vitale/Thai eID**, according to the actual cards needed by applications.

The original CardStudio **GlobalPlatform/CPLC + CAP loading/installing** batch is
now implemented within the explicit profiles in [GLOBALPLATFORM.md](GLOBALPLATFORM.md). This is distinct from the
CardPeek findings. ATR changes must target documented programmable-card commands;
an ATR is supplied by the chip/firmware and cannot generally be changed by a
standard PC/SC command.

## Implementation and licensing

CardPeek is [GPLv3 with an OpenSSL exemption](https://github.com/L1L1/cardpeek/blob/de8cee209b870f3d7aa1c6bd55e84738765dc1e6/COPYING).
No CardPeek source or lookup tables were copied by this review. Implement new
protocols independently from current public specifications; separately check
licenses and provenance before importing datasets or code. Existing archived
CardStudio material is outside this new source review.
