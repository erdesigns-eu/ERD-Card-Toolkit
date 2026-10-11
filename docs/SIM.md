# SIM / USIM cards

`TSimCardReaderWriter` is an inactive, VCL-independent component in the
`ERD.Card.SIM.Reader` unit (`ERDCardSIM` package). Use a PC/SC reader with a
suitable physical SIM adapter. A keyboard RFID reader and a normal contactless
NFC reader do not provide the required contact interface. A suitable reader
transports APDUs; the SIM determines the rights.

## Available

- Explicit classic GSM SIM (`A0`) and UICC/USIM (`00`) profiles.
- Read ICCID, IMSI, service-provider name and SST/UST service bits via
  `ReadIccid`, `ReadImsi`, `ReadSpn` and `ReadServices`.
- Enumerate UICC EF.DIR applications with `ReadApplications`; choose the full
  USIM AID yourself.
- Inspect file type, size and record geometry with `InspectFile`; read
  transparent files, ranges and absolute linear-fixed/cyclic records with
  `ReadFile`, `ReadBinaryRange`, `ReadRecord` and `ReadRecords`.
- Replace transparent files and linear-fixed records with `WriteFile` and
  `WriteRecord`, using exact expected initial content and independent read-back
  verification. No automatic write retry.
- Read, write and delete standalone ADN contacts with `ReadPhonebook`,
  `WritePhonebookContact` and `DeletePhonebookContact`; GSM/UCS-2 names and
  TBCD numbers.
- USIM PBR decoder with explicit A8/A9/AA templates, file role/FID/SFI and IAP
  positions; snapshot/plan workflows add allocation for explicitly supported layouts.
- Read linked USIM contacts with `ReadLinkedUsimContact`: explicit ADN FID/PBR
  record, IAP positions, raw linked fields and validated EXT number chains in
  one transaction.
- Apply explicit caller-planned linked phonebook record changes with
  `WriteLinkedPhonebookRecords`; no free record or link is guessed.
- SMS text decoder for DELIVER/SUBMIT: GSM seven-bit, UCS-2, binary payload
  preservation, UDH/segment references and application ports; explicit complete
  segment sets can be assembled without automatic message grouping.
- SMS record codec with status and preservation of all 175 body bytes
  (SMSC/TPDU/padding). SMS memory can be read/written through the explicit
  record methods.
- Present a supplied PIN once with `VerifyPin` when the remaining budget is
  known and sufficient. Query PIN status with `GetPinStatus` without a code
  attempt.
- Query PUK status with `GetPukStatus` and unblock/change credentials once with
  `UnblockPin` or `ChangePin`, using guarded known budgets.
- Offline ICCID/IMSI, GSM/UCS-2, SPN, ADN, SMS, EF.DIR and file-metadata codecs.

The component requires `ICardTransport` with `ICardTransaction`; every action
owns one exclusive transaction. Inputs are copied before acquisition. PIN and
command copies are wiped. After a dispatched UPDATE, an error remains explicitly
`ESimCardWriteUncertain`, including `VerifiedReadBack` when all bytes had
already been proven but cleanup failed. A successful UPDATE status alone is not
write proof.

## Addresses and authentication

`TSimCodec.FileAddress` takes an explicit root and one to eight FIDs. Do not add
`3F00` to the path: the component selects the master file itself.

| File | Classic SIM from master | UICC/USIM |
| --- | --- | --- |
| ICCID | `2FE2` | Master: `2FE2` |
| Application catalog | Not offered | Master: `2F00` |
| IMSI | `7F20/6F07` | Selected USIM application: `6F07` |
| SPN | `7F20/6F46` | USIM: `6F46` |
| SST / UST | `7F20/6F38` | USIM: `6F38` |
| ADN | `7F10/6F3A`, if present | Supply the actual EF from PBR yourself |
| SMS | `7F10/6F3C`, if present | USIM: `6F3C`, if present |

Presence and access vary by operator. USIM contacts are **not** automatically
assumed to be on `6F3A`. If needed, read `5F3A/4F30` (PBR), decode it with
`DecodePhonebookReferences` and use the actual ADN path. High-level contact
writes refuse existing CCP/EXT links to prevent loss of linked data. The generic
record API preserves the full record supplied by the application.

A PIN consists of four to eight ASCII digit bytes. In the VCL demo it is entered
as hex: `1234` becomes `31323334`. This is not a numeric BCD PIN. UICC
application access requires the selected full AID; a supplied USIM PIN is not
used for master-root files. An already verified UICC session may be reused for
access; that does not prove a newly supplied PIN. `VerifyPin` refuses such a
session and refuses unknown budgets. The library does not guess a PIN/ADM code
and never automatically lowers the configured retry threshold.

SST shows allocated/active bits separately. UST shows availability; its `Active`
field mirrors availability and does not claim EF.EST activation status.

## Delphi example

```pascal
Sim := TSimCardReaderWriter.Create(nil);
try
  Sim.Transport := Reader; // connected PC/SC transport with transaction support
  Sim.Profile := scpUiccUsim;
  Applications := Sim.ReadApplications;
  Sim.ApplicationAid := ChosenFullAid;
  Identity := Sim.ReadImsi(SuppliedAsciiPin);
  Address := TSimCodec.FileAddress(sfrUsimApplication, [$6F3C]);
  SmsRecords := Sim.ReadRecords(Address, SuppliedAsciiPin);
finally
  Sim.Free;
end;
```

`SimCardDemo` exposes all card methods, explicit paths, expected bytes,
read-back proof and offline decoders. It makes no connection or PIN attempt at
startup.

## Limits and further extensions

This is not a telephony stack: no network registration, phone modem, SMS
sending, GSM/AKA authentication, Ki readout, eSIM download/provisioning or SIM
Toolkit. ADM authentication, broader USIM PBR allocation schemas,
automatic SMS message grouping, national language tables and additional
phonebook files are next steps. Cyclic-record writes are absent; absolute cyclic
reads are available. Binary offsets are limited to 32767; complete transparent
files to 32768 bytes. Records are limited to 255 bytes/255 records. Larger
profiles are refused, not truncated.

Practical next extensions include broader PBR schemas and extended ANR allocation
where an explicit compatible layout is available. Other card families--the remaining VCL demos, native USB-HID sources,
MIFARE Plus or CryptoMemory--each require their own reader/protocol profile;
payments remain out of scope.

## Application workflows

`TSimPhonebookWorkflow`, `TSimSmsWorkflow`, `TSimInspectionWorkflow` and
`TSimWorkflowCodec` add complete snapshots, readable reports, reviewed
restore/apply plans and offline free-slot imports. Standard classic ADN/EXT1 and
selected PBR-linked USIM EFs retain all physical records. The logical importer
supports supported type-1/type-2 EMAIL/ANR bindings and allocated EXT chains for
long primary numbers, with explicit SFI/IAP links and complete capacity checks.
Unknown/ambiguous schemas are refused before any write. SMS records preserve
all status/body bytes; explicitly supplied complete multipart groups can be
validated and allocated together.

`TSimCardReaderWriter.WriteRecordPlan` adds bounded general linear-fixed plan
execution with target ICCID and all original records checked inside one exclusive
transaction, one optional PIN authentication, independent per-record verification
and retained evidence after later failure or cleanup uncertainty. Existing
`WriteLinkedPhonebookRecords` remains the smaller explicit low-level USIM API.
Both are non-atomic and never replay writes. The workflow separates snapshot,
preview and apply, and accepts cancellation before the retained plan starts.

The new `SimWorkflowDemo` has its own DFM, source/target reader selectors,
masked ASCII PIN, snapshot/plan editing, import fields and native reader events.
See [WORKFLOWS.md](WORKFLOWS.md#simusim-contact-and-sms-workflows) and
[VCL_DEMOS.md](VCL_DEMOS.md#sim-workflow-demo).

## Validation and sources

The protocol layout follows ETSI TS 151 011 / 3GPP TS 51.011 (classic SIM),
ETSI TS 102 221 (UICC), TS 131 102 / 3GPP TS 31.102 (USIM) and 3GPP TS 23.038
(character encoding). Public pySim protocol definitions were used as a secondary
cross-check; the Pascal implementation was written independently.

74,402 SIM/USIM assertions have been run under FPC with range/overflow/heap
checks: literal APDUs/codecs, PIN budgets, buffers, every write I/O boundary,
complete read-back bits, chunking and cleanup uncertainty. The separate family
executor also covers literal SIM read paths and preflight tests. Another 4,833
workflow/planner assertions cover linked allocation, archives, offline demos,
inspection, complete multipart imports and every native record-plan I/O boundary.
**Delphi/Windows and physical SIMs have not been tested yet.** Source validation
scripts do not replace those tests.

## Linked contacts and SMS text

`ReadLinkedUsimContact(PbrRecord, ActualAdnFid, Record, Pin)` reads the
referenced linear-fixed EFs under one exclusive transaction. The ADN choice is
explicit; missing/ambiguous IAP/EXT references, pointers outside the file and
loops are refused. EXT type 2 is followed as extra number digits; other linked
fields remain complete bytes including footer. EMAIL/ANR codecs require an
explicit footer layout; ANR returns the inline number and preserves CCP/EXT
references. Linked writes use an explicit caller plan; no free record/link is
guessed. This profile requires exactly one ADN and unambiguous IAP/EXT
references in the selected PBR record. Type-2 EMAIL/ANR/SNE back-references are
checked against the selected ADN record/SFI. At most 32 different EFs are read.
Type-3 references are followed only for the supported EXT chain.

`DecodeSmsMessage` accepts a complete allocated 176-byte EF.SMS record and
checks that DELIVER/SUBMIT matches the stored direction. GSM text is decoded
with UDH fill bits. UCS-2 also preserves zero/FF code points; surrogates are
refused. Eight-bit messages return `TextDecoded=False` and exact user data. SCTS
stays original in `TimestampBytes`; no UTC/year is guessed. Supported DCS
groups: general uncompressed 00..3F, valid C/D/E message-waiting and F0..F7
class coding. Unknown UDH elements are preserved, but national language-shift
IEs, compressed/reserved DCS, enhanced validity and STATUS-REPORT TPDUs are
explicitly refused. `AssembleSms` assembles explicitly supplied complete sets;
missing, duplicate or mixed direction/address/DCS/PID/UDH records are refused.
Eight- and sixteen-bit references are distinguished.

`InspectSim --sms-text <complete-record-hex>` and the offline SMS text action in
`SimCardDemo` show the content. The linked-contact action shows the original ADN,
exact linked records and EXT chain. Use the actual USIM AID and decimal ADN FID.

The offline VCL actions EMAIL, ANR and SMS-join show these codecs. SMS-join takes
complete EF.SMS records separated by semicolons and orders the segments. Unknown
UDH elements must be identical across the whole set. For binary SMS, payloads are
joined without their headers; original segment bytes remain available in
`Segments`. The caller decides which message forms the set.

## PIN/PUK management and linked writes

`GetPukStatus` reads classic PUK counters or uses an explicit UICC RESET RETRY
query. Cards that do not report a known budget there are refused for unblock; no
code attempt is used to guess the budget. `ChangePin` and `UnblockPin` send one
CHANGE/UNBLOCK with supplied ASCII digits. `MinimumPinAttempts` also applies to
the known PUK budget. There is no preceding VERIFY that could consume an extra
attempt. Both caller input and backend errors are protected by owned/wiped
command copies and sanitized errors.

The return value `TSimCredentialReceipt.CommandAccepted` is only command-status
proof after successful cleanup. **No new-PIN proof is claimed.** An application
can use `VerifyPin` after an explicit reset/new session. The component does not
reset, automatically retry or make a second code attempt itself.

`WriteLinkedPhonebookRecords` takes one to 32 explicitly ordered changes with
USIM `5F3A/FID`, record, exact before/data. All initial records are checked under
one transaction before the first UPDATE; each changed record is checked again
immediately before its write; all final records are independently read back. The
order is caller-defined, for example new EMAIL/EXT record content first and only
then the IAP/ADN link. Multiple writes are **not atomic**. After partial dispatch
there is no rollback/replay: `ESimCardWriteUncertain` remains explicit, with
read-back proof where present. PBR changes, duplicate records and unknown
geometry are refused. There is no automatic allocation or implicit change to
other contacts.

The VCL plan action uses `FIDhex:record:beforehex:datahex` per semicolon line,
for example `4F50:1:41420101:42420101`. PIN/PUK is entered only as ASCII hex;
credential actions show the status receipt, and linked writes show complete
read-back.
