# Componenten en gereedheid voor CardStudio

Stand: 12 oktober 2026. Dit overzicht omvat de gemergede PR #50 en de nieuwe
sessie-, bewerkings- en projectcomponenten op de opvolgbranch.
Het is een overzicht van geïmplementeerde profielen, geen compatibiliteitsgarantie
voor iedere kaart of reader met een vergelijkbare productnaam.

## Waar we staan

**We hebben genoeg componenten voor een uitgebreide CardStudio met kaartinspectie,
back-up, vergelijking, geselecteerde kopieeracties en gecontroleerd schrijven.**
De belangrijkste transports, kaartfamilies en herbruikbare workflows bestaan.
We zijn nog niet compleet voor alle beveiligingsvarianten en vendorprotocollen.

Een eerlijk percentage is niet te geven: het eindpunt “alle kaarten” is geen
begrensde verzameling. De praktische grens is welk expliciet kaartprofiel en welke
reader de gekozen bewerking ondersteunen. Een brede eerste studio kan op de
bestaande basis worden gebouwd; volledige dekking van de resterende profielen is
nog afzonderlijk componentwerk. Volgens de afgesproken volgorde bouwen we die
profielen eerst verder uit, zonder nu nieuwe demo's of een applicatie te maken.

## Beschikbare basis

De library telt **75 geregistreerde componenten** en **25 gedocumenteerde
workflowklassen**, inclusief de generieke geheugenworkflow. Dat is geen maat voor
het aantal volledig ondersteunde kaarten: één klasse kan meerdere profielen bevatten.

| Onderdeel | Aanwezig | Betekenis voor een studio |
| --- | --- | --- |
| PC/SC | Readerkeuze, connecties, ATR, APDU, exclusieve transacties en reader/kaart-events | Een readerlijst en kaartdetectie hoeven niet opnieuw in de protocollaag gebouwd te worden |
| USB-HID | Windows-enumeratie, input/output/feature-reports, hot-plug en invoerevents | Apparaten aansluiten en uitlezen; geheugencommando's vragen nog een bekend vendorprotocol |
| Readeradapters | Onder meer expliciete ACS ACR122/PN532, ACS contact-memory/NFC-V en ELATEC TWN4 PRS-profielen | Readercapaciteiten bepalen welke acties een studio mag aanbieden |
| Toolkit | APDU, ATR, BER-TLV, bytes/hex, ATR/AID/APDU-catalogs, NDEF, EMV-decoders en calculators | Inspectiepanelen en offline gereedschappen zijn grotendeels beschikbaar |
| Workflows | Voorbereiding, invoerkopieën, voortgang, kaartwissel, annulering, vergelijking, verificatie en gedeeltelijke resultaten | De app kan bewerkingen orkestreren zonder zelf kaartcommando's te implementeren |
| Packages/API | Delphi-packages, XML-documentatie en bestaande niet-visuele componentregistratie | Hergebruik in een VCL-applicatie; Windows Win32/Win64 voor hardwaretoegang |

## Kaartfamilies

| Familie | Direct bruikbaar binnen het beschreven profiel | Belangrijkste resterende grens |
| --- | --- | --- |
| Magstripe | Tracks 1–3, lezen, parsers, kopieer/template-workflows en readerafhankelijk schrijven/verifiëren | Extra vendor-SDK's, versleutelde MagTek en AAMVA/JIS |
| MIFARE Classic | Mini/1K/4K datablokken, opgegeven sectorcredentials, kopie/back-up/restore, expliciete sleutel/accessbit-migratie | Geen herstel van onbekende of onleesbare sleutels; data, trailers en UID zijn afzonderlijke bewerkingen |
| Programmeerbare UID | Expliciete Gen1/2/3/4, FUID/UFUID, USCUID/GDM en genoemde partial/Type 2-profielen | Normale productie-UID's zijn niet programmeerbaar; verificatie en readervereisten verschillen per variant |
| Ultralight/NTAG | Gebruikersgeheugen, NTAG/EV1 wachtwoordprofielen, counters lezen, NDEF en beschermde workflows | Extra chipvarianten en onomkeerbare OTP/lock/counter-programmering |
| Ultralight C | 2K3DES-authenticatie, geheugen, verificatie, security-instellingen en sleutelvervanging | OTP, lock- en counterprogrammering |
| MIFARE Plus | SL2/SL3 2K/4K geheugen, SL2-trailers met verse sleutelbewijzen, supplied-key AES, sleutelvervanging, expliciete SL0/SL1/SL2→SL3-overgangen en native Plus X-valuebewerkingen | SL3-trailers/globale configuratie, EV2 LRP en extra kaartgebonden overgangsprofielen |
| DESFire | Ordinary bestanden/transacties, AES/DES/3DES, administratie, ISO/keysets, SDM, multiple rights, AES/LRP TMAC, multiple-right TMAC, opgeslagen SDM-templateworkflows en Light LRP-beheer | Gecombineerde SDM/TMAC-data, bredere LRP-provisioning, originality en partial/unaligned TMAC |
| NDEF Type 1–5 | Berichten/records, lezen/vervangen/wissen op de ondersteunde geïnitialiseerde mappings; beschermde Type 2/5-workflows | Formatteren van lege/onbekende mappings en vendorafhankelijke locks |
| Topaz/FeliCa | Topaz-geheugen en Type 1; ongeëncrypteerde FeliCa-services en Type 3 | Topaz-formatting/OTP en versleutelde FeliCa/keyprovisioning |
| ISO 15693 | Gewoon/extended geheugen, NDEF Type 5, SLIX2/originele ST25DV wachtwoorden en beveiligingsbeheer | Extra vendors, onomkeerbare locks/privacy/destroy, ST25DV-mailbox/area resizing en ST25TV/KC |
| Contact-memory | SLE4432/4442/5532/5542, SLE4418/4428/5518/5528, I²C, SLE4404 en counterchips; opgegeven ACS-readerprofielen | AT88SC/CryptoMemory, aanvullende readerdialecten en gespecialiseerde chipprogrammering |
| SIM/USIM | Identificatie/services, bestanden, PIN/PUK, ADN/linked contacts en SMS-data; restore/import-workflows | Bredere PBR/ANR-allocatie; geen netwerkfuncties of eSIM-provisioning |
| Belgische eID | Identiteit, adres, foto, certificaten en handtekeningbestanden | Geen volledige documentauthenticiteitsverificatie |
| Europese reis/eID-documenten | ICAO BAC/PACE voor de beschreven curves/profielen, MRZ/DG1, DG2 en COM/SOD-acquisitie | Extra PACE-profielen, passive/chip authentication, EAC en nationale eID-diensten; geen algemene landcompatibiliteitsclaim |
| EMV | Directory/GPO/AFL, extra recordscan, GET DATA/logs, geparste kaartgegevens, semantiek en offline berekeningen | EMV blijft uitlezing/offline tooling; betalingen zijn bewust buiten scope |
| MOBIB/Calypso | Records, holder/events/contracts/counters, inspectierapporten en native SAM-backed secure sessions | Geldige geprovisioneerde SAM nodig voor beveiligde toegang; operatorabonnementen/zones vragen expliciete regels, geen ingebouwde volledige De Lijn/STIB/TEC/NMBS-tabellen |
| JavaCard/GlobalPlatform | Native SCP02/SCP03-profielen, CAP LOAD/install/delete/status, sleutelbeheer, tokens/DAP en receipts | SCP01/SCP11, extra sleutelgroottes/diversificatie en overige beveiligingsprofielen; ATR wijzigen blijft kaart/firmware-specifiek |

De exacte grenzen staan in de [README](../README.md),
[contactlessdocumentatie](CONTACTLESS.md), [workflows](WORKFLOWS.md),
[Europese eID](EUROPEAN_EID.md) en [GlobalPlatform](GLOBALPLATFORM.md).

## Nieuw in deze uitbreiding

`OpenMultiAccessTransactionSession(Aid, True)` voegt een expliciet EV2 AES-profiel
toe voor backup-, value- en lineaire/cyclische recordtransacties. Alle primaire en
extra rechtentupels worden meegenomen in de commandospecifieke autorisatie.
Commit verifieert zowel de verwachte inhoud als de volledige statische instellingen,
inclusief extra rechten. Abort blijft een expliciete bewerking.

De bestaande gewone sessie behoudt zijn oorspronkelijke grens. Het nieuwe profiel
weigert SDM/TMAC/onbekende layouts vóór een mutatie. MACed/Full geven beschermde
dataverificatie; expliciet Plain geeft vergelijking van de teruggelezen inhoud,
geen cryptografische authenticiteit van de oorspronkelijke gegevens.

## Wat er nog in de componenten moet gebeuren

Voorgestelde bundels, op volgorde van aansluiting bij het huidige werk:

1. **DESFire:** gecombineerde SDM/TMAC-data, bredere LRP-administratie en
   originality. Multiple-right TMAC en opgeslagen SDM-templateworkflows zijn nu
   geïmplementeerd; template-restores wijzigen de bestaande doelpolicy niet.
2. **MIFARE Plus:** SL3-trailers/globale configuratie, EV2 LRP en aanvullende
   kaartgebonden overgangsprofielen. SL2-sectorgegevens en trailer/sleutelprogrammering
   zijn beschikbaar met een expliciete native AES/Crypto1-readeradapter.
3. **Europese eID-authenticiteit:** passive authentication (SOD/issuertrust), relevante
   chip-authentication/EAC- en extra PACE-profielen. Certificaten/SOD uitlezen alleen
   bewijst de echtheid van het document niet.
4. **Extra chip/securityprofielen:** kies concrete AT88SC/CryptoMemory,
   ISO15693-vendor- of versleutelde FeliCa-profielen met een passende readeradapter.
   Een generiek transport maakt een onbekend kaartprotocol niet automatisch bruikbaar.
5. **Workflowdekking:** gecombineerde SDM/TMAC- en aanvullende vendorprofielen.
   DESFire-archief v2 bewaart nu extra rechtensets, provisioning valideert alle
   tuples vooraf, en TMAC-workflows geven ontvangstbewijzen terug. SDM heeft een
   eigen opgeslagen-templatearchief. Zie [de nieuwe profielen](PROTOCOL_COMPLETION.md).

Dit zijn componentuitbreidingen. Betalingen, opname/replay en nieuwe VCL-demo's
staan niet op deze route.

## Wat een CardStudio-applicatie zelf nog nodig heeft

De UI is nog niet gebouwd. [Studio-componenten](STUDIO_COMPONENTS.md) leveren nu
readerreservering/generatiebewaking, een operation-queue, workflowbridge en
begrensde projecten met atomaire import. De volgende productuitbreidingen blijven:

- **Reader- en sessieregie:** centrale transportreservering en generatiebewaking bestaan;
  een signal-driven achtergrondexecutor en lazy PC/SC-connectiebeheer bestaan nu
  ook, inclusief atomische multi-readerreservering en queued groepsjobs. Typed HID/magstripe-leases en automatische PC/SC/HID-hotplugregistratie bestaan ook.
  Gemengde APDU/resourcegroepen en atomische multi-resource-acquisition ontbreken nog.
- **Profielkeuze en capaciteiten:** acties aanbieden op basis van kaart én reader;
  ATR/UID-herkenning is een hint en geen bewijs dat iedere schrijfactie past.
- **Inspectiemodel en schermen:** kaart/applicatie/fileboom, geparste velden, ruwe data,
  resultaten met betrouwbaarheidsniveau en behoud van gedeeltelijke uitlezingen.
- **Bewerkingsregie:** preview, bron/doelkeuze, expliciete sleutels/instellingen,
  voortgang/annulering en een zichtbaar onderscheid tussen Verified en Uncertain.
- **Projecten en geheimen:** het nieuwe begrensde projectformaat en streamopslag bestaan;
  Windows-user DPAPI en atomische bestandsopslag bestaan ook, met typed geheugen-,
  DESFire-, MOBIB-, magstripe-, NDEF-, SIM/USIM- en contact-memory-adapters.
  Expliciete artifact-schemamigraties en een gescheiden immutable in-memory sleutelprovider
  bestaan ook. Portable beschermde opslag, persistente credential-vaultpolicies en
  eventuele toekomstige container-versiemigraties blijven verdere uitbreidingen.
- **Heropening na fouten:** nieuwe kaartinspectie en gecontroleerde vervolgplannen;
  geen automatisch herhalen van een mogelijk al uitgevoerde schrijfactie.

Als de gerichte protocolbundels klaar zijn, kan deze laag worden gebouwd zonder
nieuwe kaartcommando's in de forms te stoppen. De belangrijkste open productkeuze
is de gewenste lijst van gegarandeerde kaart/readerprofielen; “alle bestaande en
nieuwe kaarten” blijft ook voor een volledige studio een uitbreidbare catalogus.

## Validatie

Geautomatiseerde native protocoltests, foutinjectie, onafhankelijk gegenereerde
transcripts, broncontroles en distributiecontroles zijn beschikbaar. De actuele
uitkomsten van deze PR staan in [VALIDATION.md](VALIDATION.md). Zij onderbouwen de
geïmplementeerde codepaden; dit rapport maakt geen universele hardwareclaim.
