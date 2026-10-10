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
| ACR38x CCID | SLE4404 | Pending with known window | Bit-program/scratchpad/application erase pending | Both code budgets and success proof pending |
| ACR39 | SLE4404 | Not implemented | Not implemented | Not implemented |
| ACR39 | SLE4406/4436/5536/6636 | Not implemented | Not implemented | Not implemented |

For completed checks retain a redacted before/after result and describe intentional
failure/removal cases separately. Never record PINs or keys in this matrix or traces.
See [memory API scope](MEMORY_CARDS.md) and [VCL operations](VCL_DEMOS.md).

USB-HID RFID checks are also pending: reader model/firmware, keyboard layout, actual
terminator/prefix/length and presented encoding; for raw reports record descriptor,
report-ID framing and known fixed-field/status protocol. Keyboard input, 8/9-byte
boot reports and declared ASCII fields are separate profiles. No AliExpress model
or generic HID card-memory/UID writing has been certified. See [RFID input](RFID_HID.md).

TWN4 PRS ASCII / USB-CDC is implemented for explicit supplied-key Classic
Mini/1K/4K block operations and public Ultralight/EV1/NTAG user pages. Expected ID,
current contents, final preflight and independent write read-back are exercised in
synthetic tests. Real TWN4 firmware/CDC driver, 4K reader-sector conventions and
every physical chip/model combination remain pending. No memory programming is
claimed for the supplied keyboard-only EM4100/TK4100 readers; see [TWN4](TWN4.md)
and [reader models](RFID_READER_MODELS.md).

Topaz 96/512 profiles now have an explicit ACR122U/PN532 Jewel/CIU adapter,
verified user writes and initialized Type 1 NDEF. Independent protocol fixtures
exercise byte-write acknowledgement dialects, CIU RF framing/parity/CRC and failure
cleanup. No physical Topaz/reader firmware pairing is certified by those tests.
See [Topaz/Type 1](TOPAZ_TYPE1.md) for the exact supported profile and mapping bounds.
