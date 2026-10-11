# Reading and parsing MOBIB / Calypso

`TCalypsoCardReader` reads logical files and records. `TMobibCodec` from
`ERD.Card.MOBIB.Data` returns the known fields as typed data.
`TMobibSubscriptionCodec` decodes the documented contract versions.
`TCalypsoSamSessionProvider` provides native authentication through an attached
SAM. These units are in `ERDCardContactless` and the standalone design package.
`MobibDemo` has its own DFM and its own PC/SC reader selection.

Newer units extend this:

- `ERD.Card.EN1545` is a table-driven EN1545 bit decoder. Each field reports
  its offset, width, raw value, decoded value and confidence.
- `ERD.Card.MOBIB.Lookup` holds operator contexts and stop and tariff names.
  `ERD.Card.MOBIB.Brussels` contains the bundled Brussels stop tables.
- `ERD.Card.MOBIB.Report` builds a result tree, text and JSON output, and
  masks personal fields by default.
- `ERD.Card.Calypso.Networks` recommends and applies EN1545 profiles for other
  Calypso networks.

A contactless smart-card reader must support ISO 7816 APDUs. A reader that only
passes a card number through as keyboard input cannot read these files.

## Files and records

`ReadMobib` selects ticketing directory `2000` and reads environment `2001`,
holder `2002`, events `2010`, contracts `2020`, counters `2069`, contract list
`2050`, special events `2040`, and extended holder `3F1C`.

`ReadMobibFiles` accepts a custom plan with at most 64 unique, known FIDs. This
lets you read additional files within the same transaction and secure session.
The demo has an editable field for this FID list. `ReadFile` reads one known
logical file in the current application.

Records are actually traversed; the limit is 1–255 per file, defaulting to 16.
`6A83` marks the end; `Truncated` distinguishes reaching the limit. SELECT and
record bytes, absent files (`6A82`), and access/state restrictions (`6982`/
`6985`) remain available. No authentication attempts are guessed. An unexpected
status returns `ECalypsoStatusError.StatusWord`.

Choose the dialect explicitly: legacy CLA `94`/SELECT P1 `00`, or revision-3
CLA `00`/SELECT P1 `09`. Record Le is 29 bytes by default; one `6Cxx` correction
and bounded `61xx` response chaining are supported. There is no dialect
fallback.

### Application selection, file information and read plans

- **Application select.** `SelectApplication('1TIC.ICA')`, or setting
  `ApplicationName` before `ReadMobibPlan`, sends an ISO SELECT by DF name
  (`00 A4 04 00`). `TCalypsoApplicationInfo` holds:
  - the 8-byte serial number and the startup information;
  - the product (revision 2, revision 3, Light or Basic);
  - PIN, stored-value, extended-mode, PKI and HCE flags;
  - the session buffer size;
  - a **recommended** dialect. The reader never applies it; you set `Dialect`
    yourself.

  A missing application (`6A82`/`6A81`) is recorded in `StatusWord` and the
  read continues. Any other unexpected status raises an error.
- **File information.** Every successful SELECT response is decoded into
  `TCalypsoFile.Info`. That covers the tag `85` header: SFI, file kind,
  linear/cyclic/counter structure, record size and count, access conditions,
  key indexes, DF status and LID.
- **Card record size.** `RecordSizeFromCard := True` (opt-in) reads each file
  with the record size from its header and stops at the record count in the
  header. Some revision-3 MOBIB cards use 48-byte records for `2001`, `2010`,
  `2020` and `3F1C`, so a 29-byte read cuts them short. When the header is
  missing, `RecordBytes` is used.
- **Read plans.** `ReadMobibPlan` reads an explicit list of entries in one
  transaction and secure session. Each entry is either a folder plus logical
  ID (`FileRef`) or a folder plus SFI (`SfiRef`). The folder can be ticketing
  `2000`, the master file `3F00` (`0002` ICC, `0003` ID), or another folder
  under `3F00`, such as `1000` for the purse logs `1014`/`1015`. A folder that
  cannot be selected is recorded as that entry's status. SFI reads use
  READ RECORD with P2 = `SFI<<3 | 4` and do not send a SELECT.
- **Built-in plans.** `MobibInventoryPlan` is the bounded list of known
  ticketing, ICC, ID and purse-log files. `SfiSweepPlan(folder, 1, 30)` is an
  explicit SFI sweep. Neither plan guesses files outside its list.

Folder selection through the master file has been tested against APDU
transcripts only. It has not been checked against a physical MOBIB card.

## Parsed data

In MobibDemo, choose **Legacy MOBIB 056/001** for the published legacy layout.
The parser checks the available environment network fields and applies that
layout only for country `056` and network `001`. The explicit profile selection
and match do not prove that every De Lijn/STIB/TEC/NMBS/SNCB card generation has
the same layout.

The current typed results contain:

- Country and network code, and the explicit layout match.
- From the two extended-holder records: a nineteen-digit number with leading
  zeros, name from the five-bit alphabet, valid BCD birth date, and raw gender
  code.
- Events: validation and first-validation date/time, transport code, the known
  metro/premetro/bus location fields, bus route, and the event count/coupon
  field.
- The known purchase-date field per contract and the contract-list count.
- Separate big-endian 24-bit counters. They are not summed or automatically
  interpreted as remaining trips; the contract association can differ.

Fields added by the EN1545-based decoder:

- **Environment.** The version selects the layout. The decoder reads the card
  expiry date, the 19-digit card number, the birth date and the postal code.
  A card counts as personal when one of these personal fields is set.
  - The card number is shown in the grouping printed on De Lijn cards: six
    digits, then `4 4 4 1` (`123456 / 7890 1234 5678 9`). On the checked card
    the last digit was a valid Luhn check digit.
  - On one De Lijn card the printed "valid until" date was **one day before**
    the stored expiry date. The stored date is therefore treated as the first
    day the card is no longer valid. The report shows both values, and labels
    the printed date *observed*.
- **Events.** Validation events (`2010`) and special events (`2040`) use the
  layout for versions 0–2, or the bitmap layout for version 3 and later. The
  bitmap layout adds passenger count, route number, bus or station location
  (zone / sub-zone / station), serial number and transfer number. Unknown
  versions are counted in `UnsupportedEventCount` and stay raw.
- **Counters.** When `2069` is missing, the counters come from `202A`–`202D`.
  `SourceFileId` records which file each counter came from.
- **Holder.** `3F1C` accepts 29- and 48-byte records.
- **Other files:**
  - ICC (`3F00/0002`): chip serial number, manufacturer, manufacture country
    and date;
  - card purchase date from the purse load log;
  - the contract list (`2050`) as a count plus a candidate split into 28-bit
    entries. That split is marked *observed* because no layout has been
    published.

`TMobibData.Raw` remains an independent copy of **all** acquired data, including
unknown fields. Unknown networks do not receive an invented name, product,
validity, or trip location. Wrong BCD/date/range values in a known layout produce
an explicit decode error. Choose raw mode to investigate a different layout. The
additional subscription codec below provides known product names and
version-bound contract semantics. Full contract validity, operator rules, and
operator-bound location names are not universally known.

```pascal
Reader := TCalypsoCardReader.Create(nil);
try
  Reader.Transport := ConnectedTransport;
  Reader.Dialect := cdLegacy94;
  Parsed := TMobibCodec.Decode(Reader.ReadMobib(16), mlLegacy056001);
  // Parsed.Holder, Events, Contracts, Counters, and Raw are caller-owned data.
finally
  Reader.Free;
end;
```

## Supplying valid keys or a SAM

MOBIB issuer keys are not publicly available configuration values. No default or
guessed keys are provided. Public Calypso test keys are not access keys for an
issued MOBIB card.

For parties that do have valid keys/SAM access, there is a concrete provider
hook:

```pascal
Reader.SecureSessionProvider := MyCalypsoSdkOrSamProvider;
Reader.RequireSecureSession := True;
Snapshot := Reader.ReadMobibFiles(KnownFileIds, 32);
```

Implement `ICalypsoSecureSessionProvider.Open` with the SDK/SAM for the real
card revision. The provider owns the supplied key materials, key index, version,
and authentication settings; they are not copied into records, error messages,
or demo input text. It receives the exclusive connected transport, the explicit
dialect, and selection data. For `ReadFile`, selection data is nil and the
provider can perform the required application preparation itself.

`Open` returns `ICalypsoSecureReadSession`. `GetTransport` supplies an adapter
that handles secure commands and returns verified/decrypted APDU responses.
`Finish` must check session authentication; only then does the reader return the
snapshot. On error, `Abort` is called and the primary error is preserved. There
is no fallback to public or unverified reading. A missing provider with
`RequireSecureSession=True` fails before card I/O.

## Native authentication via SAM

`ERD.Card.Contactless.Calypso.SAM` contains a concrete Delphi engine; no external
Calypso SDK is needed for it. Supported session forms:

| Setting | Card CLA | Challenge / session MAC |
| --- | --- | --- |
| `csrRevision1` | 94 | 4 / 4 bytes |
| `csrRevision2` | 94 | 4 / 4 bytes |
| `csrRevision3` | 00 | 4 / 4 bytes, compatibility |
| `csrRevision32` | 00 | 8 / 8 bytes, extended plaintext |

The SAM handles diversification, fresh challenge, MAC calculation, and
verification. Delphi sends SELECT DIVERSIFIER, GET CHALLENGE, DIGEST
INIT/UPDATE/CLOSE, and DIGEST AUTHENTICATE; the card receives OPEN/CLOSE SECURE
SESSION. Every successful SELECT/READ command and the complete response are
included, excluding Le for case-4 commands. A result leaves the reader only after
verification of the card MAC. Keys are not read from the SAM or logged.

Example after connecting **two separate** `TSmartCardReader` components:

```pascal
Reader.Transport := CardReader.Transport;
Reader.Dialect := cdIso00;
Reader.SecureSessionProvider := TCalypsoSamSessionProvider.Create(
  SamReader.Transport, csrRevision3, CardSerialEightBytes,
  AuthorizedKeyIndex, AuthorizedKif, AuthorizedKvc, $80);
Reader.RequireSecureSession := True;
FileData := Reader.ReadFile($2020, 1);
```

Requires a suitable legacy Calypso SAM with the valid issuer/working keys,
possibly preselected and unlocked according to its own provisioning. KIF/KVC must
match the card; a mismatch does not lead to a different key or downgrade. The
8-byte serial/diversifier must come from a trusted card selection or application
configuration; ticketing bytes are not guessed as the serial number. SAM CLA
80/94 is explicitly configurable.

The SAM connection gets its own exclusive transaction. Use both connections on
the same worker thread and do not share the SAM during a session. The engine
supports authenticated **plaintext reads** here, not encrypted sessions, PKI, key
arrays without a SAM, writes, debits, or contract updates.

This strict profile accepts only successful SELECT FILE/READ RECORD APDUs. Use
known existing files and an exact record count; an error status, 6C/61 chaining,
a response above 255 bytes including status, or READ Le above 253 aborts secure
acquisition. The public reader still supports its existing probe/chaining
behavior. A missing file can therefore appear as a status in a public snapshot,
while the native secure snapshot is aborted. For reading only record one, the
limit is one; the `Truncated` flag still indicates the reached acquisition
limit.

MobibDemo has a third, dedicated DFM page for this, with a separate SAM dropdown
populated by the demo itself. The example reports verified mutual MAC and exports
only after `Finish` has succeeded. On every error, both connections are released;
cleanup errors do not overwrite the primary read/authentication error.

## Subscriptions and contract semantics

`TMobibSubscriptionCodec.DecodeSnapshot(ParsedMobib)` works on the explicitly
matched 056/001 profile. `Decode` can also process a separate contract offline.
All original bytes remain independently available in `Raw`.

| Contract field | Versions 0–3 | Version 4 |
| --- | --- | --- |
| Tariff code | 14 bits from bit 27 | 14 bits from bit 25 |
| Price | 16 bits from bit 103 | 16 bits from bit 89 |
| Purchase date | 14 bits from bit 41 | optional, presence-bitmap bit 2 |
| Duration | not published | optional, bitmap bit 3: unit code 2 bits + value 8 bits |
| End date | not published | bits 6–19, bit-inverted 14-bit date (*observed*) |

On real version-4 contracts, the inverted end date always equalled the stored
"purchase date" plus the recorded duration. So when an end date is present,
the "purchase date" works as a **validity start** (`StartDate`), and duration
unit code `3` maps to **months**. Both facts are marked *observed*: they come
from card data, not from a published layout. The holder of the De Lijn card
behind these observations confirmed that it carries a monthly subscription.
Whether the stored end date is the last valid day or the first invalid day
(as for the card expiry) is not yet confirmed. `StatusAt` treats it as the
last valid day. Counter-use code `0` with an end
date is reported as a period pass (`mskPeriod`), not as a trip product with
zero trips.

`TMobibSubscriptionCodec.StatusAt(contract, Now)` returns active, expired,
future or unknown, using only the start and end dates stored on the card and
an explicit `Now` that you supply. It deliberately skips `TMobibRuleEngine`,
because that engine needs an operator profile, and no profile is published
for this check. `DuplicateOf` flags a contract record that is byte-identical
to an earlier one, so it isn't counted twice. `CounterSourceFileId` names the
counter file that was used.

The five-bit bitmap at bit 111 uses bit 0 as the first optional field; the
unknown optional fields are also skipped correctly. Unknown contract versions
from five onward remain raw and get `LayoutMatched=False`. A zero date is absent;
a zero price, zero duration, or zero counter is a present value.

Four known tariff codes have a product name: `2801` JUMP 1 trip, `2803` JUMP 10
trips, `0805` airport bus, and `303D` JUMP 24h including airport bus. Other
codes remain numerically available without an invented product name. Tariff bits
10–12 indicate counter-use: code four is a time product; the counter is then not
presented as remaining trips. For other counter-use profiles, an available linked
counter is offered separately as remaining trips.

The counter from `2069` record one is linked through the **absolute contract
record number**, not through the position in the list of found contracts. Missing
or protected counters remain absent. The price is euro cents for the purchase,
not an electronic balance. `HasSaleDate`, `HasDuration`, `HasCounter`, and
`HasRemainingTrips` distinguish a real zero from missing information.

## Readable demo output

The snapshot page defaults to **Summary only**. It groups the decoded holder,
contracts, validations, counters, and acquired files. Purchase prices are shown
as amounts such as `EUR 62.00`, with purchase dates in `yyyy-mm-dd` format.
Missing files and access restrictions have readable descriptions; zero-filled
records are counted rather than printed as long rows of zeros.

Choose **Summary and raw records** to include hexadecimal records in the output.
The raw-layout selector also includes them. Both display modes export every
acquired record unchanged, including empty and unsupported records. Single-file
and authenticated-file actions continue to show their raw records.

Unknown tariff codes remain visible, for example `unidentified (tariff 0x000F)`.
The summary labels their counters as associated counter values rather than
assuming they represent remaining trips. Duration unit codes are retained until
an operator profile supplies their meaning. A purchase date does not by itself
establish activation or expiry; the offline rule page accepts the evidence and
operator rules needed to assess those separately.

Since the report unit was added, the demo summary comes from
`TMobibReport` (see below):

- unknown tariffs read `unknown (tariff 0x000F)`;
- version-4 contracts show `Valid from`, `Valid until`, a `Kind`, and a status
  on the current date;
- observed fields carry an `[observed]` label;
- the duration reads, for example, `1 month (unit code 3) [observed]`.

Additional snapshot options:

- **Operator context:** Unspecified, STIB-MIVB, De Lijn, TEC or SNCB-NMBS.
- **Personal fields:** Masked (default) or Shown.
- **Record size:** the initial expected bytes, or the size the card reports.
- **Read plan:**
  - the listed files;
  - the listed files after selecting `1TIC.ICA`;
  - the MOBIB inventory plan after selecting `1TIC.ICA`.

With masking on, the raw lines of `2001`, `2002`, `3F1C` and `3F00/0003` read
`[masked]`. The exported `.bin` artifacts still contain every acquired byte;
handle them as personal data. A `mobib-report.json` artifact holds the
structured report, masked in the same way as the text.

## Operator context and De Lijn

MOBIB network `056/001` is shared by STIB-MIVB, De Lijn, TEC and SNCB-NMBS. The
card does not record which operator sold a contract, so you pass a context to
`TMobibLookup`; nothing is inferred from the card.

- **STIB-MIVB:** the 69 metro stations and the bus stops from MOBIB-Extractor
  (2009) are bundled in `ERD.Card.MOBIB.Brussels`. That data is under the project's
  permissive zlib-style licence; see `docs/third_party/MOBIB-Extractor-LICENSE.txt`. The
  generator dropped 442 bus rows whose stop code is above 4095, because the
  12-bit event field can never contain them. Stops and line changes after 2009
  are missing.
- **De Lijn, TEC, SNCB-NMBS:** none of them publishes a stop-code or
  tariff-code table for MOBIB, and the library doesn't invent one. The one
  exception: in the De Lijn context, tariff `0x000F` is named "De Lijn monthly
  subscription (confirmed on one card)", because the holder of a De Lijn card
  confirmed it. The product variant (for example Buzzy Pazz or Omnipas) is not
  stored in any known field. All other De Lijn tariff codes read `unknown`.
- **Your own tables:** use `TMobibLookup.LoadCsv` to load stop or tariff
  names, with row kinds `station`, `stop` and `tariff`. Any unknown code reads
  `unknown (code)`.

## Other Calypso networks

`TCalypsoNetworks.Recommend` reads the environment's country and network
codes and **recommends** one of these profiles. It never applies one:

- Intercode (France `250`, including Navigo);
- Lisboa Viva (Portugal);
- Rav-Kav (Israel `376`);
- OPUS (Canada `124`);
- Venezia Unica and Pisa (Italy `380`);
- MOBIB.

`Decode(snapshot, profile)` applies the profile you chose and returns
EN1545 field views for the environment, contracts, events and counters.
Intercode contract layouts are chosen from the contract list; unreferenced
contracts stay raw. Unknown networks get a generic view with the header fields
plus raw records. Every profile names its source and has
`CheckedOnCard = False` until someone verifies it on a physical card. Station
databases for these networks exist only as GPL-licensed Cardpeek data, so none
are bundled.

## Report, masking and JSON

`TMobibReport.Build(data, contracts, lookup, options)` returns a flat,
parent-first tree. Each node has a key, caption, value, confidence
(`published`, `observed` or `unknown`) and a `Personal` flag. The sections are:

- MOBIB CARD;
- CARD OVERVIEW (application, features, expiry, card number, card type,
  active contract count);
- HOLDER;
- CONTRACTS (duplicates included in the count);
- VALIDATIONS;
- SPECIAL EVENTS;
- COUNTERS;
- FILE INFORMATION.

`TMobibReportOptions` has these settings:

- `ShowPersonal` defaults to false. Personal values (card number, birth date,
  postal code, holder fields and application serial number) are then replaced
  by `[masked]`.
- `Context` sets the operator context.
- `HasNow`/`Now` set the date for contract status.

`ToText` produces the indented summary and `ToJson` produces ASCII JSON
(`erd-card-mobib-report`, version 1). `IsPersonalFile` and `FileLabel` help a
UI mask or label raw files the same way.

## Native operator rules: activation, validity, and zones

`ERD.Card.MOBIB.Rules` contains `TMobibRuleEngine`. This is executable, offline
Delphi logic; it does not need to call an external SDK to assess the conditions.
An application passes an **explicit product profile** (`TMobibProductRule`) and
the available data (`TMobibRuleEvidence`).

| Condition | Support |
| --- | --- |
| Activation | Explicit start, known activation time, contract-bound first use, or purchase date when the profile explicitly prescribes it |
| Validity | Inclusive start and exclusive end time; fixed end time or calculated duration |
| Duration | UTC minutes/hours; local calendar days/months/years; optionally an explicit mapping of the four contract-duration codes |
| Calendar boundaries | Months/years count with day clamping: 31 January + one month ends on 28/29 February; 29 February + one year on 28 February |
| Day tickets | Optionally calculate the end time from local midnight; the real activation start is retained |
| Zones | Explicitly unrestricted, a fixed operator profile set, or a decoded contract set; **all** requested trip zones must fit in it |
| Trips | Optionally require a positive remaining-trip counter to start a new trip |

The profile matches exactly on operator ID, country, network, tariff code, and
supported contract versions. `Source` must contain the source/specification
version. Network 056/001 alone is not proof that the operator is De Lijn or STIB.
There is no global implicit rule selection based on a product name.

`Evaluate` returns separate checks and `mrvUnknown`, `mrvEligible`, or
`mrvIneligible`. A missing activation time, unknown zone set, or unmapped
duration code remains **unknown**. A known not-activated state, an expired date, wrong
trip zone, or zero remaining trips gives a real rejection. Known errors dominate
missing information: a known expired end date rejects, even when the start date
is missing. The reasons remain separately visible. A contradictory/invalid date
window remains unknown; inconsistent caller configuration gives `EMobibRuleError`
without card data in the message.

The caller chooses the clock basis and supplies `Now` explicitly. Elapsed hours
are **UTC**, so a daylight-saving transition does not add or remove an hour.
Calendar days use **operator-local civil time**. The engine does not secretly
convert between time zones. A calendar month is not a fixed number of days; a
purchase date is not an automatic activation date. An inclusive end day from an
official layout must be explicitly converted by the caller to the next local
midnight.

Example of an **application profile**, with data from the application's own
official operator specification/decoder; this example is not a built-in operator
profile:

```pascal
Rule := Default(TMobibProductRule);
Rule.OperatorId := OperatorIdFromConfiguration;
Rule.Source := OperatorSpecificationRevision;
Rule.CountryCode := 56;
Rule.NetworkCode := 1;
Rule.Tariff := TariffFromSpecification;
Rule.MinVersion := 0;
Rule.MaxVersion := 4;
Rule.ClockBasis := mcbOperatorLocal;
Rule.ActivationSource := mavExplicitStart;
Rule.DurationUnit := mduCalendarMonths;
Rule.DurationAmount := 1;
Rule.ZoneMode := mzmContractSet;
Rule.RequireRemainingTrip := False;

Evidence := Default(TMobibRuleEvidence);
Evidence.OperatorId := Rule.OperatorId;
Evidence.CountryCode := ParsedMobib.CountryCode;
Evidence.NetworkCode := ParsedMobib.NetworkCode;
Evidence.ClockBasis := mcbOperatorLocal;
Evidence.Now := ExplicitOperatorLocalTime;
Evidence.HasStart := HasDecodedContractStart;
Evidence.Start := DecodedContractStart;
Evidence.HasContractZones := HasDecodedContractZones;
Evidence.ContractZones := DecodedContractZones;
Evidence.HasJourneyZones := True;
Evidence.JourneyZones := RequestedJourneyZones;

Assessment := TMobibRuleEngine.Evaluate(Rule, Subscription, Evidence);
```

`mduExplicitEnd` can assess directly supplied start/end dates, even when an
operator uses more complex calendar rules. `mduContractField` requires an
explicit `ContractUnits[0..3]` mapping; the existing two-bit unit codes are not
universally interpreted as days/months. A mapping may contain `mduUnknown` for
codes that are not known. Zone IDs are explicit codes; a numerically intermediate
zone is not automatically permitted.

### What is missing from automatic operator profiles?

The published MOBIB contract layout describes tariff, sale date, price, and some
duration fields. It does not fully describe which bytes contain activation, end
date, and zone codes for every De Lijn/STIB/TEC/NMBS/SNCB generation. Public
commercial ticket conditions do not fill in that card-field layout. Therefore
**no universal official operator profiles are installed**.

The application can supply valid profiles and pass known extra fields to the
engine. Protected bytes can be acquired through the SAM reader; an
operator-bound decoder must determine their meaning according to the correct
specification. The general event list is not used as a substitute for the first
validation of a particular contract. An unknown field remains available in the
raw snapshot so a documented decoder can process it.

`Eligible` means that the supplied conditions fit the supplied information. It
is not cryptographic authenticity, issuer authorization, or a complete transport-law
determination. Transfer rights, routes, exceptions, group fares, and backend blocks
are not inferred from absent data. No card is changed and no access gate is
controlled.

### VCL example

MobibDemo has a fourth **dedicated DFM page** for this offline assessment:
contract bytes, tariff/source/operator, clock basis, evaluation time, start
source, activation status, start/end, duration, zone sets, and acquired counter.
Timestamps use `YYYY-MM-DD hh:mm:ss`; zone IDs are separated by `;`.

For permitted zones, `*` means **explicitly unrestricted**; an empty field means
unknown contract zones. A missing field is therefore not silently unrestricted.
The page shows the used source, all checks, resolved dates, and separate reasons.
It opens no card or SAM connection and executes no commands.

## Protocol sources and validation

The implementation was written independently based on public protocol facts:
[Cardpeek Calypso/MOBIB layout](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/calypso/c56n1.lua),
[MOBIB extractor](https://github.com/zoobab/mobib-extractor),
[EN1545 encoding](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/lib/en1545.lua),
[Metrodroid MOBIB contract layout](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/mobib/MobibSubscription.kt),
[Metrodroid tariff codes](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/mobib/MobibLookup.kt),
[Keyple SAM protocol](https://github.com/eclipse-keyple/keyple-card-calypso-crypto-legacysam-java-lib),
[Keyple secure-session framing](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib),
and [Keyple SELECT forms](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib/blob/main/src/main/java/org/eclipse/keyple/card/calypso/CommandSelectFile.java),
the Keyple startup-information and FCI decoding,
[Metrodroid MOBIB environment and event layouts](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/mobib/MobibTransitData.kt),
and the Metrodroid Intercode, Lisboa Viva, Rav-Kav, OPUS and Venezia layouts.
No implementation code from these projects has been copied. Only facts such as
field widths and orders are used. The single exception is the bundled Brussels
stop data from MOBIB-Extractor, which is permissively licensed data with its licence
notice included.

`MobibExtended.Tests` also checks, with the holder's permission, eight real
De Lijn contract rows, four special-event rows and the contract list. Those
rows contain no name, birth date, postal code or card number, and the card's
environment record is not included. The tests check monthly start and end
dates, the duplicate record, version-3 special events and status on a
supplied date.

`CalypsoReader.Tests` uses exact APDU transcripts to cover application
selection, FCI and startup decoding, file information, record size from the
card, SFI reads, folder-qualified plans and plan validation. `En1545.Tests`,
`MobibExtended.Tests`, `MobibLookup.Tests`, `CalypsoNetworks.Tests` and
`MobibReport.Tests` use synthetic records that copy the structure of real
cards, never their personal values. They cover version-3 environments,
version-4 contracts with inverted end dates, bitmap events, 48-byte records,
counter fallback, masking, JSON and the network profiles.

Tests use synthetic data and exact APDU transcripts for reads, caller file plans,
errors, bounds, and session lifecycle. The codec has independent bit vectors,
holder/date/event/counter fixtures, and tests for ownership and unknown layouts.
Native SAM tests use separate exact card/SAM transcripts for all four session
forms, case-4 Le exclusion, wrong MAC/key/challenge, abort, transport errors, and
cleanup. Subscription tests cover all 32 presence bitmaps, versions 0–4, unknown
versions, zero values, truncation, and absolute counter assignment. The synthetic
MAC values test protocol orchestration, not the cryptographic internals of
physical SAM hardware; they certify no physical card generation.

The rule engine has independent boundary fixtures, a full Gregorian 400-year
check for month clamping, leap-year/midnight cases, UTC versus local clock
validation, exact profile matches, all contract-duration codes, zone subsets,
missing versus zero counters, and errors that dominate missing data. The VCL
executor is tested with an injected hardware boundary; the offline rules page
provably opens no reader.

## Offline snapshot analysis and demo CSV inputs

The snapshot action now exports **`snapshot.mobib`** alongside individual record
files and `mobib-report.json`. Select that artifact and save it using the demo's
export button. The fifth **Analyse saved MOBIB snapshot** DFM page loads or accepts
that snapshot text. It has its own layout, raw-record, operator-context and personal
field selectors. No reader selection or card connection is required.

Both the live snapshot page and offline page accept optional caller CSV mappings
using the existing `TMobibLookup.LoadCsv` format described above. They are applied
only to that request, in the explicitly selected operator context. Invalid live
CSV is rejected before acquiring a reader. The context is an application/user
choice; it is never inferred from country/network or purchase price. A rejected
import cannot change a later request's dictionary because each request owns a
fresh lookup. The richer `TMobibReport` tree, confidence labels and JSON export are
used by both paths, including the existing De Lijn holder-confirmed tariff note.

`TMobibArchive.Encode` / `Decode` from `ERD.Card.MOBIB.Archive` are nonvisual APIs
that retain ticketing selection bytes, application SELECT response/status, folder
and logical/SFI addresses, selection response bytes/status, last-record status,
truncation, original record numbers and bytes. Application and proprietary-file
metadata are reconstructed from the captured FCI/header bytes. Both revision-two
and revision-three file header layouts are retained. Files with the same LID in
different folders remain distinct; equivalent ticketing-folder aliases and duplicate
SFI/record addresses are rejected. Unknown file addresses remain available as raw
data without an invented interpretation.

Version-two format (ASCII text, empty byte arrays represented by a dash):

```text
MOBIB-RECORDS 2
T -
A 0000 -
F 0000 2001 0 0 9000 6A83 0 0 - -
R 2001 1 00082B0008000000000000000000000000000000000000000000000000
F 0000 2002 0 0 6A82 0000 0 0 - -
```

`T` holds ticketing selection bytes. `A` holds hexadecimal application SELECT
status and response bytes. `F` holds folder, LID, addressing-mode flag (0 LID / 1
SFI), decimal SFI, SELECT status, last READ status, truncation flag, revision-two
header flag, 23-byte proprietary header (or dash), and selection bytes. `R` holds
the current file's LID (zero is permitted for SFI files), decimal record number and
bytes. Each `R` belongs to its immediately preceding `F`. Flags are 0/1. The sample
is synthetic. Legacy version-one T/F/R archives are accepted as well; they contain
no application, folder or SFI metadata.

Bounds are 64 files, 255 records per file, 256 record bytes, 4096 selection/FCI
bytes and 16 MiB ASCII input. The demo limits pasted/loaded text to 262144
characters/bytes. Individual old `.bin` files can be assembled in this format only
when their explicit file/record identifiers and selection outcomes are known; they
are not automatically identified as a complete snapshot.

Offline output is explicitly marked as imported data; it performs no card
communication or authentication. The archive preserves supplied evidence, not an
independent authenticity proof. It is a data interchange format, not APDU recording
or replay. Complete binary exports and `.mobib` archives may contain personal card
data even while the text/JSON report is masked, matching the existing raw-export
behavior. Personal-field controls govern report display, not the original bytes.

```pascal
Raw := TMobibArchive.Decode(SavedText);
Decoded := TMobibCodec.Decode(Raw, mlLegacy056001);
Contracts := TMobibSubscriptionCodec.DecodeSnapshot(Decoded);
Lookup := TMobibLookup.Create(mocDeLijn); // explicit caller context
try
  Lookup.LoadCsv(MyCsv, 'My verified table v1');
  Options := TMobibReport.DefaultOptions;
  Options.Context := mocDeLijn;
  Nodes := TMobibReport.Build(Decoded, Contracts, Lookup, Options);
  DisplayText := TMobibReport.ToText(Nodes);
finally
  Lookup.Free;
end;
```
