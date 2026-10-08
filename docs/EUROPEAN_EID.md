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
They open no reader and require already acquired input files. The authenticated
reader below supplies that input where the document exposes the implemented ICAO
application/profile and grants access; the data codecs alone do not establish it.

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

## Implemented access and complete document reader

`TICAODocumentReader` now establishes **explicit BAC** or **PACE version 2,
ECDH Generic Mapping/AES-128**, then reads DG1/DG2 and optionally EF.COM/EF.SOD.
The PACE domain parameters are **12 (NIST P-256)** and **13 (brainpoolP256r1)**.
MRZ access information and six-digit CAN are explicit password references; BAC
accepts MRZ only. There is no automatic downgrade, password guessing or APDU replay.
The country table above remains an investigation/validation matrix, not a claim
that every national card application permits these reads. Some identity-card
biometric applications require EAC authorization beyond PACE, particularly for
restricted data; those profiles remain separate work.

The new units are `ERD.Card.EID.Access`, `ERD.Card.EID.SecureMessaging` and
`ERD.Card.EID.DocumentReader`, included in `ERDCardEID`. The core adds
`ICardEacProvider`/`ICardPaceAgreement` while preserving the existing AES interface
IID. The optional `ERDCardCryptoOpenSSL` runtime package supplies
`TCardEacOpenSslProvider`: dynamically loaded OpenSSL **3**, native EVP SHA-1/AES/
Triple DES, CSPRNG and validated native elliptic-curve operations. Production does
not contain a custom cipher, hash or curve arithmetic implementation. The host
installs/updates OpenSSL and selects a matching library architecture and policy.
Windows defaults to `libcrypto-3.dll`, Linux to `libcrypto.so.3`; an explicit path
supports distributions using names such as `libcrypto-3-x64.dll`. No cipher/RNG
fallback is provided if a library or operation is unavailable. SHA-1 and Triple DES
are used for the defined ICAO legacy protocols, not to introduce new algorithms.

PACE reads MF/EF.CardAccess, selects the ICAO AID **A0000002471001**, checks the
advertised version/OID/domain parameter, and executes MSE/GENERAL AUTHENTICATE.
The bounded EF.CardAccess parser checks canonical DER lengths, INTEGERs and SET
ordering, retains unsupported PACE infos, and rejects duplicate algorithm/parameter
pairs. The selected standardized parameter is sent as DO84 when multiple parameter
sets make it ambiguous. Private scalars come from bounded CSPRNG rejection sampling;
the backend checks scalar range, point encoding/membership, subgroup, infinity and
reflection. Terminal/card tokens must verify before any protected LDS file read.
BAC verifies the response MAC and both nonces before deriving the session.

Secure messaging checks DO85/DO87, DO99 and DO8E order/lengths, MAC before plaintext,
method-two padding and monotonic SSC without wrap. PACE uses AES-SSC-derived IVs;
BAC uses its defined Triple DES/Retail MAC profile. Integrity/protocol/I/O failure
invalidates the current secure session. A new `ReadDocument` always establishes
fresh access in its own exclusive `ICardTransaction`; it never retries failed APDUs.
Busy callbacks cannot replace credentials/provider/transport or reenter the read.
Application selection occurs before authentication and is not repeated under SM.
The result is returned only after complete acquisition/decoding and successful
transport release; the original error wins a secondary release failure.

File IDs are 0101 (DG1), 0102 (DG2), 011E (COM) and 011D (SOD). Reads use the
advertised canonical TLV length, without blind EOF probing. B0 reads transition to
**B1/DO54/DO53 beyond offset 32767**, including three-byte offsets above 65535.
Defaults are 208-byte chunks, one MiB per file and two MiB aggregate; configurable
hard bounds are 220 bytes, one MiB/file and four MiB aggregate, including CardAccess.
The reader returns exact raw files plus the existing identity/photo models.
COM/SOD are opaque bytes: access authentication and MACs do not verify document
hashes, issuer signatures, certificate chains or chip originality.

```pascal
uses ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.EID.Access,
  ERD.Card.EID.DocumentReader;

Reader := TICAODocumentReader.Create(nil);
try
  Reader.Transport := ConnectedCard.Transport; // exclusive ICardTransaction
  Reader.CryptoProvider := TCardEacOpenSslProvider.Create(CryptoLibraryPath);
  Reader.AccessPassword := TIcaoAccessCodec.MrzInformation(FullMrz);
  // Default: PACE ECDH-GM/AES-128, brainpoolP256r1, MRZ.
  Data := Reader.ReadDocument([idsIdentity, idsFace, idsSecurityObject]);
  // Data.Biometrics.Images[I].Data is encoded JPEG/JPEG 2000.
  // Data.SecurityObject is exact EF.SOD, not a verified signature result.
finally
  Reader.Free;
end;
```

Declare Reader as `TICAODocumentReader`, Data as `TIcaoDocumentData`,
CryptoLibraryPath as `string` and FullMrz as `UnicodeString`. Set `PasswordKind :=
ipkCan` and assign six raw ASCII digits for CAN, or explicitly select `Security :=
iasBac` for a documented BAC document. `PaceCurve := ppcNistP256` selects parameter
12; add `ERD.Card.Crypto.EAC` to that consumer's uses. AccessPassword is copied on
assignment and retrieval; clear it with nil when idle. Local/native secret buffers
are cleared where owned; normal managed-array assignments/temporaries and the
host's original credentials are not a guaranteed secure-memory boundary.

`ReadIcaoDocument --help` and `--cardaccess HEX` run without hardware/OpenSSL loading.
Explicit `--read` mode uses Windows exclusive PC/SC, a raw password file and an
explicit native-library path; encoded images are saved only for an explicit output
prefix. No real identities, CANs, keys or biometric data are in the fixtures.

Independent literal transcripts cover BAC, brainpool and NIST PACE, MRZ/CAN,
ambiguous advertised parameters, protected errors/invalid padding and a complete
66,000-byte synthetic encoded image crossing both offset boundaries. Official ICAO
Appendix D/G anchors check BAC mutual authentication, key derivation, Retail MAC,
protected APDUs and brainpool mapping/agreement/tokens. Fault tests cover every I/O
boundary, every protected-response bit, altered negotiation, entropy failure,
release precedence, reentrancy, bounds and buffer independence. Native tests run on
Linux OpenSSL 3; Delphi, Help Insight, Windows loader ABI/deployment and real cards
remain unvalidated.

## Next European eID work

1. Passive authentication: DG hashes, CMS/SOD signatures, document-signer/CSCA
   chains, caller-owned trust policy and explicit verification results.
2. Chip authentication, EAC terminal authentication/CVC credentials and additional
   PACE mappings/curves/ciphers where exact card profiles require them.
3. Real Netherlands/Luxembourg/Germany document generations and reader tests;
   national online-identification/PIN/signing via their documented middleware and
   service-provider authorization contracts. No country wrapper should imply access
   rights absent from the actual application.

Payments follows the current combined DESFire/eID batch; see [PAYMENTS.md](PAYMENTS.md).

## References reviewed on 2026-10-07 and 2026-10-08

- [ICAO Doc 9303 Part 4](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p4_cons_en.pdf),
  [Part 5](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p5_cons_en.pdf),
  [Part 6](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p6_cons_en.pdf): TD3/TD1/TD2 layouts and checksums.
- [ICAO Doc 9303 Part 10](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p10_cons_en.pdf):
  DG1/DG2, CBEFF format metadata and the distinction between 5F2E and 7F2E.
- [ICAO Doc 9303 Part 11](https://www.icao.int/sites/default/files/publications/DocSeries/9303_p11_cons_en.pdf):
  eighth edition (2021), sections 4.4.4.1, 9.7/9.8 and Appendices D/G:
  BAC, conditional PACE domain reference, KDF, SM and published vectors. Reviewed
  PDF SHA-256 `953bd8998c254f14617675f7d138301afda65d55107f8e751baf50d7e9a3db86`.
- [JMRTD AES secure-messaging reference](https://github.com/E3V3A/JMRTD/blob/59442057761513ea808dfd9fd8077c7e8995be55/jmrtd/src/org/jmrtd/AESSecureMessagingWrapper.java):
  corroboration of SM's explicit padding before AES-CMAC. SHA-256
  `38b70730760edd45b894baa39fdec96ca08a1a01eabdfa962b657f28dcebef63`.
  No implementation is copied or bundled.
- [OpenSSL EVP](https://docs.openssl.org/3.5/man3/EVP_EncryptInit/),
  [EC_POINT](https://docs.openssl.org/3.5/man3/EC_POINT_add/) and
  [RAND_bytes](https://docs.openssl.org/3.5/man3/RAND_bytes/): native provider contracts.
- [DigiD: identity-document login](https://www.digid.nl/inlogmethodes/identiteitskaart):
  activated login, personal PIN and NFC requirements.
- [Luxembourg government: identity-card application](https://guichet.public.lu/en/citoyens/citoyennete/papiers-identite/carte-identite/demande-carte-identite.html):
  authentication/signing certificates as separate electronic functions.
- [BSI: electronic identities](https://www.bsi.bund.de/EN/Themen/Oeffentliche-Verwaltung/Elektronische-Identitaeten/elektronische-identitaeten_node.html):
  electronic document and online-identification context.

Published synthetic ICAO MRZ examples and synthetic biometric records are tested;
no real identity or biometric records are committed. No external implementation
or standards PDF is bundled as runtime code or data.
