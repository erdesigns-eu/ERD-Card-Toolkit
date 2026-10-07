# Original protocol references

These files are byte-for-byte copies from original commit
`01faaefae9a3938817ddcae5761736952c3aa877`. They are research material, not library
units, supported APIs or a buildable application. Do not add this directory to a
unit search path. Dependencies, DFM resources and application units are intentionally
absent; some files still contain form declarations because protocol logic was
embedded in event handlers.

`manifest.json` records each original path, retained path and SHA-256 hash.
Headers and original bytes are preserved. No license has been changed or inferred.

| Directory | Purpose |
| --- | --- |
| `pcsc` | Original reader wrapper, Windows declarations and USB notification approach |
| `emv` | Application/record reads, tag descriptions, APDU status descriptions and helpers |
| `magstripe` | YL160/MSR declarations, SDK call examples and track formats |
| `memory` | Memory card read/write/PIN operations and reader/card setup examples |
| `catalogs` | Original ATR-identification catalog, separate from ATR syntax |
| `common` | Original constants and checksum implementations |
| `notes` | Original mixed smart-card command notes; provenance is unverified |

The original code contains known unsafe design choices. Do not copy handle sizes,
buffers, watchers, string-based binary parsing or ownership patterns without review.
Vendor declarations do not establish an ABI or hardware compatibility guarantee.
Validate future adapters against current official headers, SDKs and card specifications.

The Windows declarations include Microsoft/Project JEDI attribution and MPL 1.1
notices. Other files and catalogs have their original headers; those headers do not
establish a project-wide redistribution license. This material is not included in
`ERDCardCore.dpk`. The full application is recoverable from the source commit in Git.
