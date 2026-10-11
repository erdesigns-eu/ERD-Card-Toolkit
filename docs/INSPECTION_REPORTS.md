# Inspection and report workflows

`TEidInspectionWorkflow`, `TEmvInspectionWorkflow` and `TMobibInspectionWorkflow`
are on **ERD Workflows**. They use existing native readers and the common
`ERD.Card.Inspection` snapshot/export API. Construction, preparation and
`CheckPrepared` do not connect or send commands. Reader settings and array inputs
are copied; caller readers may be released after preparation. Transport and
provider interfaces are retained, so the caller must keep their connection/card
ownership stable while executing.

| Family | Preparation | Acquired report |
| --- | --- | --- |
| Belgian contact eID | `PrepareBelgian(reader, sections)` | Separate identity, address, JPEG, raw signatures and certificate outcomes; decoded fields and all identity/address tags |
| ICAO LDS | `PrepareIcao(reader, sections)` | One authenticated aggregate DG1/DG2/COM/SOD request, MRZ identity and encoded faces; explicit BAC/PACE profile, password and provider |
| EMV | `PrepareEmv(reader, applications, options)` | Optional PSE/PPSE directory, each exact AID's AFL records and fields, optional bounded extra scans, counters and log records |
| MOBIB | `PrepareMobib(reader, plan, layout, options, bound)` | Folder/LID or SFI file outcomes, original records, decoded environment/holder/events/contracts/counters and existing operator report with hierarchy/confidence |

EMV directory discovery never silently chooses an application. You can inspect
the returned `aid.N` fields, then prepare a fresh exact-AID request with the
required terminal PDOL values. No missing terminal value is filled automatically.
The application section sends one GPO; GPO can advance card state/counters even
though this workflow sends no payment cryptogram, PIN verification or issuer
script. Additional records use explicit SFI/record bounds and do not repeat AFL
records. Unknown and repeated primitive fields retain unique indexed keys.

Belgian/EMV acquisition holds one exclusive transaction across all requested
sections. ICAO and MOBIB delegate transaction/session ownership to their native
reader for one aggregate operation. ICAO uses a single fresh BAC/PACE session;
MOBIB can use an explicit legitimate `SecureSessionProvider`. Missing ICAO access
credentials/provider or a required missing Calypso provider are reported as
`cisAuthenticationRequired` before card I/O. No keys are bundled or guessed.

## Results and events

`Execute` returns the common workflow outcome. `Report.Complete` is true only
when every requested section was read and transaction release succeeded.
`cwsCompleted` means the inspection finished; it can still contain unavailable,
restricted or partial sections. Each section has a stable key/caption, status,
exact refusal `StatusWord` when received, sanitized `ErrorClass` and fields.

Statuses are Pending, Read, Unavailable, Authentication required, Partial and
Failed. Known card refusals remain visible. Unexpected status, transport or
malformed data stops acquisition; previously retained section results survive.
Cancellation leaves unread sections Pending. A failed EMV application/log or
ICAO aggregate operation does not manufacture a partial native snapshot. MOBIB
preserves per-file gaps from the successfully returned native snapshot; transport
failure before that return has no aggregate snapshot. Successfully acquired MOBIB
raw data remains available if its subsequent semantic decoder fails. Reached
record bounds remain Partial, never an asserted end of file. Reading certificates,
signatures or SOD does not verify signatures, issuer trust or card authenticity.

`OnProgress`, `OnStageChanged`, `OnCompleted`, `OnError` and `OnCardRequired`
retain the common workflow contract. `OnSectionRead` fires after each retained
outcome; `CurrentSection` identifies it. `OnAuthenticationRequired` signals a
section requiring authentication. `OnPartialRead` fires once for an incomplete
final report, including cancellation/failure. Callbacks run on the executing
thread; applications marshal UI updates. Inspection callback exceptions are
isolated in `InspectionObserverErrorClass`; base callbacks use
`ObserverErrorClass`. Callbacks never trigger retries. Prepare a fresh request
before another execution.

`Report` returns independently copied arrays and byte buffers. It contains
personal information regardless of export policy. `ParentKey` and `Confidence`
preserve the MOBIB report structure and existing published/observed/unknown
interpretations. Operator context is caller-selected, not discovered from network
056/001. Existing issuer/profile limitations are unchanged.

## Exports

`CardInspectionToText` and `CardInspectionToJson` accept a
`TCardInspectionExportOptions` record. With zero-initialized options both
`IncludePersonal` and `IncludeRaw` are false. Excluded field values and bytes are
omitted completely. Personal raw data requires both flags. EMV original fields,
records and logs and MOBIB raw files are conservatively personal; MOBIB identity,
entitlements and travel history also require personal inclusion. Generic operator
notes and card/profile metadata remain available without personal export.

JSON is ASCII with Unicode escapes and hexadecimal binary fields; it needs no
System.JSON or VCL dependency. Text uses Unicode. Export to a file with an explicit
UTF-8 encoding. Exports are reports, not restore archives; they contain no reader
credentials. The policy does not anonymize direct snapshots or replace the host
application's handling of personal information.

```pascal
uses ERD.Card.Workflow, ERD.Card.Inspection, ERD.Card.EID.Inspection;

var
  Flow: TEidInspectionWorkflow;
  Policy: TCardInspectionExportOptions;
  Snapshot: TCardInspectionReport;
  Json: UnicodeString;
begin
  Flow := TEidInspectionWorkflow.Create(nil);
  try
    Flow.PrepareBelgian(ConfiguredReader); // configured transaction-capable transport
    Flow.Execute;                        // execute on the application's worker
    Snapshot := Flow.Report;             // retain partial results even after failure
    Policy := Default(TCardInspectionExportOptions);
    Json := CardInspectionToJson(Snapshot, Policy);
  finally
    Flow.Free;
  end;
end;
```

## Independent VCL applications

Open `EidInspectionDemo`, `EmvInspectionDemo` or `MobibInspectionDemo` in the VCL
project group. Each owns an editable DFM, available-reader selector, native device
and card events, background execution, explicit profile/settings and text/JSON
save buttons. The nonvisual request worker is shared; no visual forms are shared.
Privacy selections are frozen before acquisition and apply equally to displayed
and saved reports. Progress is shown as a phase log after worker completion.
These are inspection workflows; existing family demos remain available for other
low-level actions, custom MOBIB catalogs and provisioned SAM configuration.

## Validation

`tests/workflows/CardInspection.Tests.dpr` exercises lifecycle, cancellation,
observer isolation, independent result ownership, export combinations, Unicode,
primary/cleanup failure evidence, consumed-request refusal and native synthetic
EMV/Belgian/MOBIB transcripts, plus hardware-free demo validation. It is registered
in `tools/run_core_tests.py`. Palette streaming, project ownership, DFM bindings and
all common Pascal source readers remain part of the full validation runner.
