# FeliCa and NFC Forum Type 3 NDEF

`TFelicaCardReader` supplies explicit-system polling, owned IDm/PMm and unencrypted
service block reads/writes. `TType3NdefCardReader` adds existing version 1.0 NDEF
mapping. Both are nonvisual components in ERDCardContactless and the standalone
ERDCardDesign package, with English Help Insight documentation.

## Reader and service access

Assign an `IFelicaReader`. The concrete `TAcr122FelicaReader` requires a connected
ACR122U/PN532-compatible FF00 direct-transmit transport with exclusive transactions.
Choose `fbr212` or `fbr424` explicitly; reader names/ATR do not select a dialect.
The adapter cycles RF, uses InListPassiveTarget with a system-code request, and
transfers complete length-prefixed FeliCa frames through InDataExchange. PN532
handles RF framing/CRC. No Type A CRC-A or MIFARE authentication is inserted.

One card must be present. The adapter requires exactly one returned target, exact
polling framing, explicit system matching and native success status. RF timeouts
are finite (409.6 ms); communication/activation retries are disabled. Those timing
settings persist until reader reset or deliberate reconfiguration. EndSession
turns RF off and attempts exclusive release even when RF cleanup fails.

`ReadTarget(SystemCode)` returns the acquired identity and parameters. FFFF selects
any system. `ReadBlocks(SystemCode, Service, Blocks)` reads 1..15 unique ordered
blocks from one explicit service. Service codes are little-endian on the wire;
block numbers 0..65535 use the two/three-byte FeliCa block-list forms. Each block
is sixteen bytes. There is no service guessing or interpreting arbitrary services
as NDEF, bank data or transit operator records.

`WriteBlocksVerified(SystemCode, WriteService, ReadService, Blocks, Expected, Data)`
accepts 1..12 blocks and exact sixteen-byte-per-block preimage/replacement buffers.
It checks current bytes before dispatch, writes once, and independently reads all
bytes through the explicitly supplied verification service before release. Failures
after dispatch remain uncertain and never generate replay or rollback. Unencrypted
service data have no application MAC; a successful status is not cryptographic
card authenticity. Encrypted services, FeliCa authentication/key provisioning,
formatting and payments are separate work.

## Type 3 mapping

NDEF selects system **12FC**, read service **000B** and write service **0009**.
Block zero contains the sixteen-byte Attribute Information Block. The mapping
validates version 1.0, additive big-endian checksum, Nbr/Nbw, capacity Nmaxb,
WriteF, RWFlag and 24-bit length. Unsupported versions or invalid bounds fail.
Read batches honor Nbr and the 15-block frame limit; writes honor Nbw and at most
12 blocks, with verification reads respecting Nbr too.

`ReadAttribute` exposes read-only/updating state. `ReadMessage` reads exact published
bytes, decodes NDEF records and rereads the attribute to require stable metadata.
A pending WriteF 0F is refused as an interrupted message, not reported as empty.

`WriteMessageVerified(ExpectedAttribute, NdefBytes)` requires the exact previous
attribute block. It refuses stale, read-only or updating mappings and oversized
messages. It publishes and verifies WriteF 0F before payload changes; writes and
verifies bounded data batches; preserves the unused part of the final block; and
publishes length/WriteF 00 last with a new checksum. It then independently reads
and compares the complete final message and attribute. Empty bytes publish length
zero without erasing unrelated storage. No-op messages still read/verify but do
not write. Partial updates are uncertain and can leave WriteF 0F; no automatic
recovery, formatting or locking is attempted.

## VCL example and validation

`examples/vcl/felica/FelicaDemo.dproj` owns its own TForm/DFM, reader combobox,
reader/card event label and six operation tabs: target, blocks read/write,
attribute and NDEF read/write. Type 3 results expose individual records plus Text
and URI RTD interpretation. Artifacts include exact NDEF bytes and attribute
preimages. The existing Type2Demo offers corresponding protected NDEF operations.

Tests use independent fixed synthetic transcripts, long block addresses,
metadata/identity/status corruption, attribute checksums, every write/read/release
failure boundary, stale preimages, no-op behavior and complete length-last
verification. Native adapter tests verify exact direct-transmit packets at both
bitrates. This is protocol/backend evidence, not a claim that every reader or
FeliCa product supports the same services.

Protocol references, without copying or linking an external implementation:

- [Sony FeliCa Card User's Manual 2.3](https://www.sony.net/Products/felica/business/tech-support/data/card_usersmanual_2.3e.pdf),
  polling, service/block lists, Read/Write Without Encryption and status flags.
- [NXP PN532 User Manual](https://www.nxp.com/docs/en/user-guide/141520.pdf),
  InListPassiveTarget FeliCa polling and InDataExchange complete-frame transfer.
- [nfcpy Type 3 reference at 8a195262](https://github.com/nfcpy/nfcpy/blob/8a195262fe86167845d282ba5bc9cdaadf6441c4/src/nfc/tag/tt3.py),
  corroboration of Type 3 attribute layout/checksum and standard NDEF services.
