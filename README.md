# ERD Card Components

Interne Delphi-componentbibliotheek voor het **lezen en schrijven van kaarten**.
De oude CardStudio-applicatie is vervangen door losse componenten, tools en voorbeelden.
Betalingen vallen buiten de huidige scope.

Validatie en bekende grenzen staan in [VALIDATION.md](docs/VALIDATION.md).
Beoogd platform: **Delphi 10.4+, Windows Win32/Win64**.

## Wat zit erin?

| Onderdeel | Componenten | Aanwezige functionaliteit |
| --- | --- | --- |
| Kaartlezers | `TSmartCardReader`, `TSmartCardMonitor` | PC/SC-lezerselectie, verbindingen, ATR en commandotransport; events bij reader-hotplug en kaartaanbieding/verwijdering, zonder applicatiepolling. |
| Magstripe | `TMagStripeReaderWriter` | Tracks 1–3 lezen/schrijven; MSR206/MSR605 en MSR206-7HL-profielen; MagTek-inputadapters. |
| Belgische eID | `TBelgianEIDReader` | Identiteit, adres, JPEG-foto, beschikbare certificaten en ruwe handtekeningen. |
| ICAO-documenten | `TICAODocumentReader` | BAC/PACE-toegang; DG1-identiteit, DG2-foto’s en volledige COM/SOD-bestanden. |
| EMV | `TEMVCardReader` | PSE/PPSE, PDOL-inspectie, AFL-records en expliciete extra SFI/recordscan; beschikbare PAN, vervaldatum, naam, IBAN, Track 2 en transactielogs. |
| MIFARE Classic / Type 2 | `TContactlessCardReader`, `TType2PasswordCardReader` | Classic-blokken met aangeleverde sleutels; Ultralight/EV1/NTAG210/212/213/215/216-geheugen en ondersteunde wachtwoordprofielen. |
| Programmeerbare UID | `TRawUidProgrammer` + UID-methoden van `TContactlessCardReader` | Expliciete Gen1/2/3/4-, UFUID/FUID-, USCUID/GDM- en DirectWrite-profielen. |
| MOBIB / Calypso | `TCalypsoCardReader` | Logische bestanden/records, eigen FID-plannen, houder/events, versiegebonden abonnementen en tellers; native activatie-/geldigheids-/zoneregels met expliciete operatorprofielen; native Calypso-authenticatie via een provisioned SAM (revision 1/2/3/3.2), plus eigen providers. Zie [MOBIB](docs/MOBIB_CALYPSO.md). |
| DESFire | `TDesfireCardReader` | Bestanden lezen/schrijven, EV1/EV2 AES, transacties en applicatie/bestand/sleutel/toegangsbeheer. |
| NDEF | `TType2NdefCardReader`, `TType4NdefCardReader`, `TType5NdefCardReader` | Publieke NDEF lezen en vervangen met terugleescontrole, binnen het gekozen kaartprofiel. |
| ISO 15693 | `TIso15693CardReader` | Systeeminformatie en geadresseerde geheugenblokken lezen/schrijven. |
| Contact-memorychips | `TMemoryCardReaderWriter` | SLE4432/4442/5532/5542, SLE4418/4428/5518/5528 en I²C 1–1024 kilobit via expliciete ACS-profielen; PINs, geverifieerde writes en SLE-bescherming. |
| SLE-counterchips | `TSleCounterCardReaderWriter` | SLE4406/4436/5536/6636 via ACR38x CCID: publiek lezen, bit/carry/backup-programmering met controle en ruwe certificaatberekening; expliciet leesvenster vereist. |
| SLE4404 | `TSle4404CardReaderWriter` | ACR38x CCID: publiek/beveiligd lezen, user-codecontrole, bitprogrammering en expliciete scratchpad/applicatie-erases met terugleescontrole; bekende layout vereist. |
| RFID-invoer | `TRfidKeyboardReader`, `TRfidHidReportReader` | Keyboard-input en host-aangeleverde 8/9-byte toetsenbordreports of vaste ASCII-velden; expliciete ASCII/hex/decimale profielen. |
| Native USB-HID | `TUsbHidReaderWriter`, `THidDeviceMonitor`, `TUsbHidInputMonitor` | Windows HID-collecties vinden en een gekozen interface openen; input/output/feature-reports, expliciete IDs en lengtes, timeout/annulering voor interrupt-I/O; native reader-hotplug en doorlopende inputreport-events. |
| ELATEC TWN4 | `TTwn4CardReaderWriter` | PRS/USB-CDC: tag-ID, Classic-blokken met aangeleverde sleutel en publieke Type 2-pagina’s lezen/geverifieerd schrijven; geschikte firmware vereist. |
| SIM / USIM | `TSimCardReaderWriter` | ICCID/IMSI/SPN/servicebits, expliciete bestanden/records, PIN-budgetten, geverifieerde writes, standalone/gekoppelde USIM-contactuitlezing, EXT-nummers en SMS-tekst/UDH-codecs, expliciete segmentsets, EMAIL/ANR-codecs, PIN/PUK-commandobeheer en geverifieerde gekoppelde writeplannen. |
| Tools | Losse codecs en catalogs | APDU, ATR, BER-TLV, hex/bytes, MRZ, NDEF, magstripe-pariteit/LRC en ATR/EMV-metadata. |

**Schrijfcontrole:** MSR206/MSR605-programmering levert apparaatstatus; MSR206-7HL
ondersteunt onafhankelijke terugleescontrole. Een onzekere schrijfuitkomst blijft
expliciet onzeker en wordt niet automatisch opnieuw uitgevoerd.

Lezerondersteuning en kaartondersteuning zijn afzonderlijk: het juiste protocolprofiel
én een geschikte lezer zijn nodig. De exacte profielen staan in de gekoppelde handleidingen.

## Wat zit er nog niet in?

- **Uitgebreide SIM-diensten:** geen eSIM-provisioning, telefonie/netwerkauthenticatie, SMS-verzending, automatische recordallocatie of nieuw-PIN-bewijs na een cardreset.
- **Volledige MOBIB-dekking:** het expliciet gekozen netwerkprofiel 056/001 decodeert contractversies 0–4; onbekende versies/codes blijven herkenbaar onbekend. Activatie, vervaldata, kalenderduur, zones en rittentellers kunnen met `TMobibRuleEngine` worden beoordeeld. De juiste operatorprofielen en de koppeling naar aanvullende kaartvelden moeten expliciet worden aangeleverd; volledige ingebouwde De Lijn/STIB/TEC/NMBS-regelsets zijn niet beschikbaar. Native beveiligde reads gebruiken een provisioned SAM met geldige sleutels; software-only sleutelcryptografie, encrypted sessions en PKI ontbreken.
- **Betalingen:** geen terminal/providerintegratie, betaaltransacties of directe NFC-betaalkernel.
- **Overige contact-memorychips:** AT88SC/CryptoMemory en andere readerdialecten ontbreken nog. Voor SLE-counterchips ontbreken automatische tellerberekening en geverifieerde personalisatie/code-ontgrendeling.
- **Universele vendorprotocollen:** native HID-report-I/O is aanwezig; kaartgeheugen/UID-commando’s vereisen het echte readerprotocol. Keyboard-only readers krijgen geen schrijfinterface.
- **Volledige Europese eID-ondersteuning:** Nederlandse, Luxemburgse en Duitse kaartgeneraties/nationale diensten zijn nog niet gevalideerd; aanvullende PACE/EAC-profielen ontbreken.
- **Cryptografische documentauthenticiteit:** certificaten, handtekeningen en SOD kunnen worden gelezen, maar issuer/SOD-verificatie en chipauthenticatie ontbreken nog.
- **Alle MIFARE/DESFire-varianten:** onder andere MIFARE Plus, DESFire D40/3DES, LRP, TMAC en uitgebreid sleutelset/configuratiebeheer ontbreken.
- **Universele UID-programmering of lezerdekking:** alleen de beschreven programmeerbare kaart- en lezerprofielen zijn geïmplementeerd; gewone kaart-UID’s zijn niet algemeen schrijfbaar.

## Events gebruiken

`TSmartCardMonitor` meldt `OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`,
`OnCardRemoved`, `OnStateChanged` en `OnError`. Koppel handlers en roep `Start` aan;
`Stop` annuleert de monitor. VCL levert events op de hoofdthread, zonder `PollChanges`.
Ook `TSmartCardReader.StartEventMonitoring` biedt deze events, met kaartfiltering op
`ReaderName`. Uitlezen of schrijven start je vervolgens expliciet vanuit je applicatie.

`THidDeviceMonitor` meldt aangesloten/verwijderde USB-HID-collecties.
`TUsbHidInputMonitor.OnInputReport` levert ontvangen reports; de bestaande
RFID-inputcomponenten geven gedecodeerde scans via `OnIdentifier`.
Keyboard-only readers melden doorgaans geen fysieke kaartverwijdering.
Zie [events en levenscyclus](docs/READER_EVENTS.md).

## Packages en voorbeelden

- **12 runtime packages** en **1 zelfstandig design-time package** met **25 palette-componenten**. Runtimecomponenten hebben geen VCL/design-time-afhankelijkheid; het palette bevat zijn benodigde sources expliciet en vereist geen ERD-runtime-BPL's.
- **SmartCardDemo:** offline NDEF, UID, Belgische eID/foto, ICAO/foto, EMV-applicatiedetectie, DESFire-versie, Type 2/4 NDEF-vervanging en een contact-memorypagina met PIN, geverifieerde writes, counter/SLE4404-reads, expliciete ACS-profielcapabilities en een RFID-keyboardinvoertab.
- **MagStripeDemo:** offline trackcontrole, swipes lezen en geverifieerd schrijven via MSR206-7HL.
- **Negentien losse familiedemo’s**, elk met een eigen `TForm` en `.Main.dfm`, met alle visuele controls in de designer; alleen niet-visuele kaart- en workercode wordt gedeeld: tools, RFID, native HID, TWN4, drie contact-memoryfamilies, SIM/USIM, Classic, Type 2, Type 4, ISO 15693/Type 5, UID-programmering, DESFire, aanvullende magstripeprofielen, EMV, MOBIB/Calypso, Belgische eID en ICAO-documenten. Elke demo toont zelf een keuzelijst met beschikbare PC/SC-lezers, HID-apparaten of COM-poorten en een verversknop. Geen andere app nodig om lezernamen op te zoeken. Zie [de concrete dekking](docs/VCL_COVERAGE.md).
- **ReaderToolsDemo en UsbHidDemo:** eigen DFM-knoppen voor native events en een apart eventlog; HID biedt ook doorlopende read-only input van de geselecteerde reader.
- eID/ICAO-demo’s tonen JPEG-foto’s en exporteren originele foto-, certificaat- en databestanden. DESFire toont ook transacties en beheer; Type 2 ook PWD_AUTH/PACK.

De VCL-demo’s voeren kaartoperaties op een achtergrondthread uit en linken de source
rechtstreeks. Palette-installatie is daarvoor niet nodig. Interfaces zoals transport,
kaartprofiel, device en cryptoprovider worden tijdens runtime gekoppeld.
De meegeleverde BAC/PACE-cryptoprovider vereist een apart geïnstalleerde
**OpenSSL 3**-library met passende architectuur.

## Starten in Delphi

Open `packages/ERDCards.groupproj` en `examples/vcl/CardDemos.groupproj`,
of gebruik een RAD Studio command prompt:

```bat
tools\build-packages.cmd dcc32
tools\build-vcl-demos.cmd dcc32
tools\run-core-tests.cmd dcc32
```

Gebruik `dcc64` voor Win64. Voor het palette: `tools\build-packages.cmd dcc32 design`,
waarbij de compilerarchitectuur moet overeenkomen met de **IDE**, niet noodzakelijk met de applicatie.

## Verdere informatie

- [Installatie en packages](docs/INSTALLATION.md) · [VCL-demo’s en teststappen](docs/VCL_DEMOS.md)
- [Magstripe](docs/MAGSTRIPE.md) · [Belgische eID](docs/BELGIAN_EID.md) · [Europese eID/ICAO](docs/EUROPEAN_EID.md) · [EMV](docs/EMV_READER.md)
- [Contactless/MIFARE](docs/CONTACTLESS.md) · [DESFire](docs/DESFIRE.md) · [UID-profielen](docs/PROGRAMMABLE_UID.md) · [ISO 15693/Type 5](docs/ISO15693_TYPE5.md)
- [Contact-memorykaarten](docs/MEMORY_CARDS.md) · [SLE4404](docs/SLE4404.md) · [USB-HID RFID](docs/RFID_HID.md) · [TWN4-geheugen](docs/TWN4.md) · [Aangeleverde reader-modellen](docs/RFID_READER_MODELS.md) · [Delphi-problemen en oplossingen](docs/DELPHI_PROBLEMEN.md)
- [Planning](docs/COMPONENT_PLAN.md) · [Validatieresultaten](docs/VALIDATION.md) · [API-documentatiestandaard](docs/API_DOCUMENTATION.md)

Alle publieke API’s hebben Delphi XML-documentatie voor Help Insight.
De validatiescripts en FPC-tests helpen fouten vinden; ze vervangen Delphi of hardwaretests niet.
Een projectbrede redistributielicentie is nog niet vastgesteld.

SIM-profielen en testinstructies: [docs/SIM.md](docs/SIM.md).
