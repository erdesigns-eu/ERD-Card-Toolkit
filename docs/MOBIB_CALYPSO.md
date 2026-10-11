# Reading and parsing MOBIB / Calypso

`TCalypsoCardReader` reads logical files and records. `TMobibCodec` from
`ERD.Card.MOBIB.Data` returns the known fields as typed data.
`TMobibSubscriptionCodec` decodes the documented contract versions.
`TCalypsoSamSessionProvider` provides native authentication through an attached
SAM. These units are in `ERDCardContactless` and the standalone design package.
`MobibDemo` has its own DFM and its own PC/SC reader selection.

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

## Product/provider and journey catalogs

`TMobibCatalog` from `ERD.Card.MOBIB.Catalog` resolves exact country/network,
contract-version and tariff keys. The built-in dictionary contains the four
published products listed above. Their provider remains unspecified where the
product is shared or the source does not identify a provider. A network ID does
not identify the card issuer. Tariff `000F` has no built-in provider/product name.

Applications can call `RegisterProduct` and `RegisterJourneyLabel`, or import
pipe-separated mappings with `LoadMappings`. Every custom entry requires a source
reference. Duplicate journey keys and overlapping product-version ranges are
rejected. Imports are atomic: any invalid line rolls back all entries from that
import. Values are bounded; numeric fields are decimal except the four-digit
hexadecimal tariff. Names/source fields cannot contain pipes or line breaks.

Formats (one mapping per line):

```text
P|country|network|min-version|max-version|tariff-hex|provider|product|source
L|country|network|transport-mode|location-decimal|stop-name|source
R|country|network|15|route-decimal|route-name|source
```

For example, this is **synthetic application configuration**, not a real tariff
identification or an included operator rule:

```text
P|56|1|0|4|000F|Example provider|Example subscription|Synthetic example v1
L|56|1|15|123|Example bus stop|Synthetic example v1
R|56|1|15|7|Example bus route|Synthetic example v1
```

The built-in historical Brussels table contains 69 location identifiers,
matched separately to metro (0) and premetro (7). Unknown stops keep their raw
IDs. Bus/tram names and routes require application-supplied mappings; bus route
numbers remain readable without a name. Historical names do not establish current
service, the operator that issued a card, or the contract used for a validation.
The identifiers/names are factual pairs from the MOBIB Extractor historical table,
exposed by [Cardpeek's Brussels metro data](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/etc/brussels-metro.lua).
The originating extractor is credited to Gildas Avoine, Tania Martin and
Jean-Pierre Szikora (UCLouvain); the original layout is also referenced below.

`TMobibPresentation.Summary(DecodedData, Catalog)` is a reusable, nonvisual API.
It formats purchase amounts, civil dates/times, source references, provider and
product names, layout versions, tariff IDs, counters and stop/route labels. Passing
nil uses the built-in catalog. A label does not supply activation/expiry rules;
`TMobibRuleEngine` remains the explicit policy API for those assessments.

## Offline snapshot analysis

Snapshot reads export **`snapshot.mobib`** alongside individual binary artifacts.
Select that artifact and save it with the demo's existing export button. The new
**Analyse saved MOBIB snapshot** DFM page loads or accepts that text, with its own
layout/raw selectors and optional custom catalog memo. No reader selection,
card connection or credential is required. The live snapshot page has the same
catalog input; mappings are validated before card acquisition.

`TMobibArchive.Encode` / `Decode` from `ERD.Card.MOBIB.Archive` preserve directory
selection bytes, file IDs, selection response bytes/statuses, last-record statuses,
truncation flags, record numbers and all record bytes. Empty/protected files remain
present. Offline analysis is marked as imported data and performs no card
authentication. The format is an offline data interchange, not APDU recording or
replay, and contains no reader commands or credentials.

```text
MOBIB-RECORDS 1
T -
F 2001 9000 6A83 0 -
R 2001 1 00082B0008000000000000000000000000000000000000000000000000
F 2002 6A82 0000 0 -
```

`T` stores ticketing selection bytes. `F` stores hexadecimal FID, SELECT status,
last READ status, a 0/1 truncation flag and selection bytes. Subsequent `R` lines
store the same FID, decimal record number and bytes. A dash represents an empty
byte array. Only unique nonzero FIDs/record numbers are accepted, with at most
64 files, 255 records per file, 256 bytes per record, 4096 selection bytes and
16 MiB ASCII input. Unknown file IDs are preserved without invented interpretation.
The demo limits pasted/loaded text to 262144 characters/bytes. The example above
is synthetic; archived status words are preserved evidence, not independently
verified authenticity. Pre-existing `.bin` files are not automatically identified
as a whole snapshot; their explicit file/record identifiers and captured statuses
can be assembled in this documented format.

```pascal
Raw := TMobibArchive.Decode(SavedText);
Decoded := TMobibCodec.Decode(Raw, mlLegacy056001);
Catalog := TMobibCatalog.Create;
try
  Catalog.LoadMappings(MySourcedMappings);
  DisplayText := TMobibPresentation.Summary(Decoded, Catalog);
finally
  Catalog.Free;
end;
```

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
and [Keyple SELECT forms](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib/blob/main/src/main/java/org/eclipse/keyple/card/calypso/CommandSelectFile.java).
No implementation code from these projects has been copied.

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
