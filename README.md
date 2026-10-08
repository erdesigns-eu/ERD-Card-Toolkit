# ERD Card Components

Interne Delphi-componentbibliotheek voor het **lezen en schrijven van kaarten**.
De oude CardStudio-applicatie is vervangen door losse componenten, tools en voorbeelden.
Betalingen vallen buiten de huidige scope.

**Status:** bestaande packages bouwen en installeren volgens de Delphi-hertest van
de gebruiker zonder warnings. De nieuwe Memory/Input/TWN4-profielen en het zelfstandige
designpackage moeten nog in Delphi en met echte lezers/kaarten worden getest.
Beoogd platform: **Delphi 10.4+, Windows Win32/Win64**.

## Wat zit erin?

| Onderdeel | Componenten | Aanwezige functionaliteit |
| --- | --- | --- |
| Kaartlezers | `TSmartCardReader` | PC/SC-lezerselectie, verbindingen, kaartdetectie, ATR en commandotransport. |
| Magstripe | `TMagStripeReaderWriter` | Tracks 1–3 lezen/schrijven; MSR206/MSR605 en MSR206-7HL-profielen; MagTek-inputadapters. |
| Belgische eID | `TBelgianEIDReader` | Identiteit, adres, JPEG-foto, beschikbare certificaten en ruwe handtekeningen. |
| ICAO-documenten | `TICAODocumentReader` | BAC/PACE-toegang; DG1-identiteit, DG2-foto’s en volledige COM/SOD-bestanden. |
| EMV | `TEMVCardReader` | Applicaties en records uitlezen; beschikbare PAN, vervaldatum, naam, IBAN, Track 2 en transactielogs. |
| MIFARE Classic / Type 2 | `TContactlessCardReader`, `TType2PasswordCardReader` | Classic-blokken met aangeleverde sleutels; Ultralight/EV1/NTAG-geheugen en ondersteunde wachtwoordprofielen. |
| Programmeerbare UID | `TRawUidProgrammer` + UID-methoden van `TContactlessCardReader` | Expliciete Gen1/2/3/4-, UFUID/FUID-, USCUID/GDM- en DirectWrite-profielen. |
| DESFire | `TDesfireCardReader` | Bestanden lezen/schrijven, EV1/EV2 AES, transacties en applicatie/bestand/sleutel/toegangsbeheer. |
| NDEF | `TType2NdefCardReader`, `TType4NdefCardReader`, `TType5NdefCardReader` | Publieke NDEF lezen en vervangen met terugleescontrole, binnen het gekozen kaartprofiel. |
| ISO 15693 | `TIso15693CardReader` | Systeeminformatie en geadresseerde geheugenblokken lezen/schrijven. |
| Contact-memorychips | `TMemoryCardReaderWriter` | SLE4432/4442/5532/5542, SLE4418/4428/5518/5528 en I²C 1–1024 kilobit via expliciete ACS-profielen; PINs, geverifieerde writes en SLE-bescherming. |
| SLE-counterchips | `TSleCounterCardReaderWriter` | SLE4406/4436/5536/6636 via ACR38x CCID: publiek lezen, bit/carry/backup-programmering met controle en ruwe certificaatberekening; expliciet leesvenster vereist. |
| SLE4404 | `TSle4404CardReaderWriter` | ACR38x CCID: publiek/beveiligd lezen, user-codecontrole, bitprogrammering en expliciete scratchpad/applicatie-erases met terugleescontrole; bekende layout vereist. |
| USB-HID RFID | `TRfidKeyboardReader`, `TRfidHidReportReader` | Keyboard-input en host-aangeleverde 8/9-byte toetsenbordreports of vaste ASCII-velden; expliciete ASCII/hex/decimale profielen. |
| ELATEC TWN4 | `TTwn4CardReaderWriter` | PRS/USB-CDC: tag-ID, Classic-blokken met aangeleverde sleutel en publieke Type 2-pagina’s lezen/geverifieerd schrijven; geschikte firmware vereist. |
| Tools | Losse codecs en catalogs | APDU, ATR, BER-TLV, hex/bytes, MRZ, NDEF, magstripe-pariteit/LRC en ATR/EMV-metadata. |

**Schrijfcontrole:** MSR206/MSR605-programmering levert apparaatstatus; MSR206-7HL
ondersteunt onafhankelijke terugleescontrole. Een onzekere schrijfuitkomst blijft
expliciet onzeker en wordt niet automatisch opnieuw uitgevoerd.

Lezerondersteuning en kaartondersteuning zijn afzonderlijk: het juiste protocolprofiel
én een geschikte lezer zijn nodig. De exacte profielen staan in de gekoppelde handleidingen.

## Wat zit er nog niet in?

- **Betalingen:** geen terminal/providerintegratie, betaaltransacties of directe NFC-betaalkernel.
- **Overige contact-memorychips:** AT88SC/CryptoMemory en andere readerdialecten ontbreken nog. Voor SLE-counterchips ontbreken automatische tellerberekening en geverifieerde personalisatie/code-ontgrendeling.
- **Universele USB-HID:** raw USB openen/enumereren, willekeurige vendorreports en generiek RFID-geheugen/UID schrijven ontbreken; keyboard-input is direct bruikbaar, raw profielen vereisen een hostbron.
- **Volledige Europese eID-ondersteuning:** Nederlandse, Luxemburgse en Duitse kaartgeneraties/nationale diensten zijn nog niet gevalideerd; aanvullende PACE/EAC-profielen ontbreken.
- **Cryptografische documentauthenticiteit:** certificaten, handtekeningen en SOD kunnen worden gelezen, maar issuer/SOD-verificatie en chipauthenticatie ontbreken nog.
- **Alle MIFARE/DESFire-varianten:** onder andere MIFARE Plus, DESFire D40/3DES, LRP, TMAC en uitgebreid sleutelset/configuratiebeheer ontbreken.
- **Universele UID-programmering of lezerdekking:** alleen de beschreven programmeerbare kaart- en lezerprofielen zijn geïmplementeerd; gewone kaart-UID’s zijn niet algemeen schrijfbaar.

## Packages en voorbeelden

- **11 runtime packages** en **1 zelfstandig design-time package** met **19 palette-componenten**. Runtimecomponenten hebben geen VCL/design-time-afhankelijkheid; het palette bevat zijn benodigde sources expliciet en vereist geen ERD-runtime-BPL's.
- **SmartCardDemo:** offline NDEF, UID, Belgische eID/foto, ICAO/foto, EMV-applicatiedetectie, DESFire-versie, Type 2/4 NDEF-vervanging en een contact-memorypagina met PIN, geverifieerde writes, counter/SLE4404-reads, expliciete ACS-profielcapabilities en een RFID-keyboardinvoertab.
- **MagStripeDemo:** offline trackcontrole, swipes lezen en geverifieerd schrijven via MSR206-7HL.
- **Consolevoorbeelden** voor de afzonderlijke componenten en uitgebreidere beheeroperaties.
- **VCL-dekking:** de huidige demo’s tonen nog niet alle API-functies. Losse demo’s per kaartfamilie met gedeelde basiscode zijn de volgende uitbreiding; zie [de concrete checklist](docs/VCL_COVERAGE.md).

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
