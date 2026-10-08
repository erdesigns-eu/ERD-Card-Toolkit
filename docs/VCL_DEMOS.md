# VCL read/write demos

Open `examples/vcl/CardDemos.groupproj` or either application's `.dproj` in RAD
Studio. They link source directly, so installing the component palette is optional.
From a RAD Studio command prompt:

```bat
tools\build-vcl-demos.cmd dcc32
tools\build-vcl-demos.cmd dcc64
```

Executables go to `dist/vcl/<Platform>/Debug`, with separate DCUs for each demo.
IDE/MSBuild Release builds go to the corresponding Release directory. These are
Windows VCL applications; they have not been built or rendered in the Linux cloud
environment. The provided scripts are an executable validation path for a Delphi
host, not evidence that those builds already pass.

## SmartCardDemo

The initial operation inspects the included synthetic `Hi` NDEF Text message
without accessing hardware. `Encode text` generates a UTF-8 Text record with the
explicit language `en`. `List readers` enumerates PC/SC readers on a worker; it
does not connect a card or pick a reader automatically. Select or enter its exact
name before choosing a card operation.

| Operation | Required selection / scope |
| --- | --- |
| UID | Explicit PC/SC storage profile using `FF CA`; requires a compatible reader |
| Belgian eID | Contact-card identity/address/photo through the implemented Belgian profile |
| ICAO document | Explicit BAC or PACE ECDH-GM/AES-128, MRZ information or CAN, PACE parameter 12/13, and an OpenSSL 3 library matching the executable architecture |
| EMV PSE / PPSE | Explicit contact/contactless directory discovery; displays AIDs without starting payment or issuing GPO |
| DESFire | Public native version only; secure administration remains in the console examples |
| Type 2 NDEF read / replace | Explicit actual Ultralight/EV1/NTAG model, compatible `FF B0`/`FF D6` storage reader |
| Type 4 NDEF read / replace | Mapping 2.0, uniquely selectable public NDEF file; no automatic formatting or authenticated-file inference |

ICAO MRZ input is the 24-character MRZ information string: document-number field
and check digit, YYMMDD birth date and check digit, YYMMDD expiry and check digit.
CAN is six decimal digits and requires PACE. Use the ICAO/MRZ codecs when deriving
this input in your application. Select the access settings explicitly; there is
no PACE-to-BAC fallback. BAC/PACE provides file access and secure messaging, not
issuer authenticity. SOD verification and national-service/EAC integration remain
separate future work; not every European identity card exposes this LDS profile.

Identity text stays in the result memo. JPEG is previewed on the UI thread;
JPEG 2000 is retained without conversion. `Save encoded photo` writes those acquired
bytes only after file selection. The demo retains the first ICAO face image; the
component API returns all images. A new operation clears the previous face result.

`Replace ... + verify` explicitly replaces existing NDEF using the component's
write and independent read-back checks. It does not format unknown tags or unlock
protected data. Successful replacement shows the canonical wire message that was
written. An uncertain-write exception is displayed as uncertain; the demo never
repeats a write automatically.

## MagStripeDemo

`Inspect tracks offline` validates selected unframed payloads and reports bit counts
including odd parity and LRC. Do not include sentinels or an LRC character in the
editable track fields. Empty payloads are allowed by the offline codec.

Hardware operations use only the explicit **MSR206-7HL** serial adapter at
9600 baud, seven data bits, odd parity and one stop bit. Enter the exact COM port,
selected tracks and a timeout between 1 and 600000 ms. `Read one swipe` updates
only the selected track fields. `Write selected + verify` additionally requires
nonempty payloads and an explicit low/high coercivity choice. It uses the verified
writer, which returns independent same-swipe raw read-back rather than treating a
status acknowledgement as proof of the programmed contents. Firmware and physical
reader validation are still pending. Other magstripe backends remain accessible
through the component API and console examples; this demo does not guess their
physical model or protocol.

## Threading and smoke checks

Every operation owns its components, transport and backend on a worker thread.
`TCardDemoJob` copies access/NDEF bytes before starting, clears its owned access
password after execution, and moves results to the form once under a lock. Polling
uses a VCL timer; the worker neither touches controls nor queues callbacks that
could outlive a form. Closing during an operation waits for completion. There is
no forced abort, and a blocking driver may extend this wait; the serial swipe
bound is not a PC/SC timeout. Writes are never cancelled or retried behind the UI.
Access input is cleared after starting, but this is not a guarantee of erasure
of the Windows edit control's or Delphi strings' historical allocations.

On a Delphi/Windows host, check both platforms: open both forms, inspect/encode
NDEF and raw tracks offline, enumerate readers with no card, and close while a job
is active. Then use known disposable test cards and the correct explicit profile
to verify identity/photo acquisition, NDEF replacement and magstripe read-back.
Also check missing reader/card, unsupported profile, driver failures, closing while
waiting for a swipe, and ambiguous write results. Verify designer DFM loading,
Help Insight for public APIs, and layout at your target DPI. These IDE/hardware
checks remain outstanding; see [VALIDATION.md](VALIDATION.md).
