# Hardware validation matrix

Protocol tests use independent synthetic transcripts. No physical contact-memory
combination below has been validated in this cloud environment. Record the exact
reader model, firmware, driver, Windows/Delphi architecture and chip revision when
a maintainer completes a check; reader names and successful ATR negotiation are
not evidence that programming works.

| Reader dialect | Card family | Public read | Verified program | PIN / protection / carry / certificate |
| --- | --- | --- | --- | --- |
| ACR38x CCID | SLE4432/4442/5532/5542 | Pending | Pending | Pending where applicable |
| ACR39 | SLE4432/4442/5532/5542 | Pending | Pending | Pending where applicable |
| ACR38x CCID | SLE4418/4428/5518/5528 | Pending | Pending | PIN/protection pending; PIN replacement unavailable |
| ACR39 | SLE4418/4428/5518/5528 | Pending | Pending | PIN/protection pending; PIN replacement unavailable |
| ACR38x CCID / ACR39 | I2C 1–1024 kbit | Pending | Pending for each actual page size/bank | No PIN/protection profile claimed |
| ACR38x CCID | SLE4406 | Pending with known readable window | Pending | Carry pending; backup/certificate unavailable |
| ACR38x CCID | SLE4436 | Pending with known readable window | Pending | Carry/backup/non-CBC certificate pending |
| ACR38x CCID | SLE5536/6636 | Pending with known readable window | Pending | Carry/backup/CBC/non-CBC certificate pending |
| ACR39 | SLE4406/4436/5536/6636 | Not implemented | Not implemented | Not implemented |

For completed checks retain a redacted before/after result and describe intentional
failure/removal cases separately. Never record PINs or keys in this matrix or traces.
See [memory API scope](MEMORY_CARDS.md) and [VCL operations](VCL_DEMOS.md).
