# European identity documents: support boundary and next steps

The target countries are **the Netherlands, Luxembourg and Germany**, with other
European cards following when their actual applications and profiles are documented.
Country alone is not a protocol selector: an identity document may expose separate
travel-document, online-identification and certificate/signing applications.

| Document family | Shared data path to investigate | Separate integration |
| --- | --- | --- |
| Dutch identity documents | ICAO eMRTD/LDS where that document generation exposes it | DigiD's activated identity-document login and personal PIN |
| Luxembourg identity documents | ICAO eMRTD/LDS where exposed | National authentication/signing certificates, PIN and middleware |
| German identity documents | ICAO eMRTD/LDS where exposed | Online-Ausweisfunktion, PACE/EAC and service-provider authorization |
| Belgian contact eID | Existing Belpic public-file reader | Cryptographic verification and contactless access |

This table records implementation routes, **not a tested compatibility list**.
Exact card models/editions, AIDs and access controls require conformance and hardware
checks before marking them supported. A generic ISO 7816 reader or recognition of
an ATR does not unlock the data. BAC/PACE establish access and secure messaging;
reading the protected files then requires authenticated, integrity-checked APDUs.
National online-identification functions are not interchangeable with the travel
application. Fingerprint access has additional restrictions; the current work
decodes identity and face data, not fingerprint files.

## Implemented reusable data layer

`ERD.Card.EID.MRZ` and `ERD.Card.EID.ICAO` are RTL-only units in `ERDCardEID`.
They open no reader and require already acquired input files. They do **not** make
Dutch, Luxembourg or German cards readable through raw `TSmartCardReader.Transport`.

- `TMrzCodec`: TD1 (3×30), TD2 (2×36), TD3 (2×44); 7/3/1 check digits,
  composite checksums, TD1/TD2 extended document numbers and CR/LF presentation.
- `TIcaoDataCodec.DecodeDG1`: LDS tag 61 and MRZ tag 5F1F, with typed document
  number, issuing-state/nationality codes, name transliterations and date codes.
- `TIcaoDataCodec.DecodeDG2`: bounded CBEFF templates and ISO/IEC 19794-5
  first-edition `FAC 010` records; encoded JPEG/JPEG 2000 images and dimensions.
  Unsupported biometric formats, including newer 7F2E ISO/IEC 39794 templates,
  remain explicitly preserved without fabricated images.

All public declarations have Delphi `///` XML documentation. Inputs are copied;
ordinary record assignment shares dynamic arrays. DG2 keeps exact original bytes
for future SOD/hash verification, while individual encoded blocks are normalized
by the BER-TLV encoder. No data authenticity, certificate trust or biometric matching
is inferred from successful parsing or MRZ checksums. Image pixels are not decoded;
JPEG 2000 needs an application-selected decoder. Face data contains at most sixteen
templates/images and each DG is bounded to one MiB, 1024 BER nodes and depth sixteen.

```pascal
uses ERD.Card.EID.MRZ, ERD.Card.EID.ICAO;

Identity := TIcaoDataCodec.DecodeDG1(DG1Bytes);
Biometrics := TIcaoDataCodec.DecodeDG2(DG2Bytes);
// Identity.IssuingState preserves codes such as 'D<<'; dates remain YYMMDD.
// Biometrics.Images[I].Data is encoded JPEG/JPEG 2000, not a VCL image.
```

Declare Identity as `TMrzIdentity`, Biometrics as `TIcaoBiometrics` and DG1Bytes /
DG2Bytes as `TBytes`. MRZ transliteration cannot reconstruct accents or reliably
infer a full century from a two-digit year. Original strings remain available.
Visas, national nonstandard MRZ formats and newer facial-record revisions are not
silently interpreted as the implemented profiles.

## Access-layer implementation sequence

1. Add an independently testable BAC/PACE and secure-messaging provider using a
   maintained cryptographic implementation, with official known-answer vectors.
   Keep passwords/CAN/MRZ input and derived keys out of logs and parser exceptions.
2. Add `TICAODocumentReader` on that authenticated session. Select the correct
   application before access establishment; subsequent application selection must
   not accidentally discard the secure session. Keep acquisition/read operations
   exclusive, fail on MAC errors and invalidate failed sessions without replay.
3. Read length-delimited LDS files, including odd `READ BINARY B1`/DO54/DO53 for
   photos beyond the 15-bit B0 offset. Feed DG1/DG2 into these implemented codecs.
4. Add SOD/hash/certificate verification separately, then test exact Dutch,
   Luxembourg and German card generations/readers. Add national eID services only
   through their corresponding authorization and middleware contracts.

The EMV component is the next component milestone while the protected eID-access
provider remains tracked as its own work. Avoid describing decoder availability
as complete physical-card support.

## References reviewed on 2026-10-07

- [ICAO Doc 9303 Part 4](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p4_cons_en.pdf),
  [Part 5](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p5_cons_en.pdf),
  [Part 6](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p6_cons_en.pdf): TD3/TD1/TD2 layouts and checksums.
- [ICAO Doc 9303 Part 10](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p10_cons_en.pdf):
  DG1/DG2, CBEFF format metadata and the distinction between 5F2E and 7F2E.
- [ICAO Doc 9303 Part 11](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p11_cons_en.pdf):
  BAC, PACE, secure messaging and their transition requirements.
- [DigiD: identity-document login](https://www.digid.nl/inlogmethodes/identiteitskaart):
  activated login, personal PIN and NFC requirements.
- [Luxembourg government: identity-card application](https://guichet.public.lu/en/citoyens/citoyennete/papiers-identite/carte-identite/demande-carte-identite.html):
  authentication/signing certificates as separate electronic functions.
- [BSI: electronic identities](https://www.bsi.bund.de/EN/Themen/Oeffentliche-Verwaltung/Elektronische-Identitaeten/elektronische-identitaeten_node.html):
  electronic document and online-identification context.

Published synthetic ICAO MRZ examples and synthetic biometric records are tested;
no real identity or biometric records are committed. No external implementation
or standards PDF is bundled as runtime code or data.
