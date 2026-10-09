# VCL-voorbeelden: huidige dekking

Er zijn **twintig afzonderlijk uitvoerbare toepassingen** in
`examples/vcl/CardDemos.groupproj`. Achttien familiedemo’s delen hun formulier,
invoercontrole, achtergrondworker en expliciete bestands-export. Betalingen vallen
buiten deze componentset.

| Project | Aanwezige functies |
| --- | --- |
| SmartCardDemo | Bestaande gecombineerde PC/SC-, eID-, EMV-, contactless-, memory- en RFID-pagina’s |
| MagStripeDemo | Tracks en MSR206-7HL reads/geverifieerde writes |
| ReaderToolsDemo | PC/SC-lijst/status, APDU command/response, ATR/catalog, BER-TLV, EMV-tags en NDEF-codecs |
| RfidInputDemo | Foreground keyboard, boot/ID/fixed-ASCII-reports, ASCII/hex/decimale profielen en byteconversie |
| UsbHidDemo | Native HID-collecties/VID/PID/usage/lengtes, exact interfacepad, interrupt- en feature-reports lezen/verzenden/exporteren |
| Twn4Demo | PRS/CDC versie/tag, supplied-key Classic en publieke Type 2 reads/geverifieerde writes |
| MemoryCardDemo | Alle SLE/I²C-modellen, twee ACS-dialecten, snapshots/ranges, PIN, writes, PIN-vervanging en permanente bescherming |
| SleCounterDemo | Publieke vensters, bit/carry/backup-programmering en ruwe certificaatberekening |
| Sle4404Demo | Bekende layout/counters, supplied-code reads/proof, bitprogrammering, scratchpad- en applicatie-erases |
| SimCardDemo | Classic SIM/UICC-USIM, bestanden/records/identiteiten/services, PIN/PUK-status, verify/change/unblock, ADN-contactwrites, PBR/IAP/EXT-contactreads, expliciete gekoppelde recordplannen, alpha/EMAIL/ANR/SMS/segmentcodecs |
| MifareClassicDemo | UID, offline layout/trailers, supplied-key blokreads en status-only datawrites |
| Type2Demo | Ultralight/EV1/NTAG210/212/213/215/216, UID/pagina/geheugen, publieke NDEF, ACR122 PWD_AUTH/PACK-page/memory/geverifieerde pagewrite |
| Type4NdefDemo | Offline CC, mapping 1.0/2.0, file descriptors/FID, publieke NDEF read/write/clear |
| Iso15693Demo | ACR1552 expliciete address/response-dialecten, UID/geometry, blokreads/geverifieerde writes en Type 5 NDEF read/write/clear |
| UidProgrammingDemo | PC/SC Gen2/FUID; ACR122 Gen1a/Gen1b/unsealed UFUID, DirectWrite, Gen3, zes Gen4-layouts, USCUID/GDM en partial UFUID/ZUID/PFUID |
| DesfireDemo | Public/EV1/EV2 AES, directories/data/values/records, standard writes, backup/value/record-transacties met commit/abort, applicatie/bestand/key/access-beheer |
| MagStripeProfilesDemo | Track-bit/parity/LRC en financial decoders, MagTek keyboard/HID, MSR206/MSR605 reads en status-only all-track programming |
| EmvDemo | PSE/PPSE, explicit AID/terminal values, GPO/AFL/all records, GET DATA, advertised logs, DOL/log decoders en exacte exports |
| BelgianEidDemo | Alle publieke sections, identiteit/adres, JPEG, RAW/DER-certificaten en ruwe handtekeningen exporteren |
| IcaoDocumentDemo | BAC/PACE met MRZ/CAN/curve/provider, alle documentsections/face images, CardAccess/DG1/DG2/COM/SOD-export, JPEG-preview en JPEG2000-export |

## Gedrag dat je kunt overnemen

- Hardwarewerk draait op de gedeelde achtergrondworker; threadstart gebeurt pas
  na constructie. Elke actie vereist concrete invoer en opent geen hardware bij
  formulierconstructie.
- Writes, PIN-pogingen en beheer vereisen een expliciete acknowledgement.
  Kaart-/readerprofielen worden niet door programmeerpogingen gedetecteerd.
- Credentialbuffers worden bij de threadgrens gekopieerd en lokaal gewist.
  Foutmeldingen tonen geen kaartdata of keys. Een fout laat geen nieuwe exports achter.
- Een vendorstatus wordt afzonderlijk benoemd; HID-transfer en MSR206/MSR605-status
  zijn geen zelfstandig kaart-terugleesbewijs. Onzekere writes worden niet herhaald.
- Foto’s/bestanden worden alleen na geslaagde acquisitie en een expliciete
  Save-keuze opgeslagen. JPEG2000 blijft exact behouden zonder conversie.

## Grenzen van deze voorbeelden

Generieke HID transporteert reports; een vendorprotocol bepaalt welke kaartfuncties
ze betekenen. Keyboard-only EM4100/TK4100-readers krijgen daardoor geen geheugenwrite.
Windows kan raw toegang tot keyboard-collecties weigeren. Foreground keyboard
blijft daarvoor beschikbaar in RfidInputDemo.

SIM gekoppelde writes gebruiken een expliciet, volledig recordplan; de demo wijst
geen vrije contact-/EXT-/EMAIL-records automatisch toe. DESFire toont één behouden
transactie per job; deze UI is geen sessie die tussen losse buttonclicks blijft leven.
NDEF-demo’s wijzigen geen lockbits, formatting, passwords of toegangsrechten buiten
de aangeboden familymethoden. Foto/certificaat-export voert geen passieve eID-
of certificaattrustvalidatie uit.

De projecten delen de gerepareerde BOM/CRLF- en MSBuild-conventies. Reproduceerbare
bouw- en validatiecommando’s staan in [VCL_DEMOS.md](VCL_DEMOS.md) en
[VALIDATION.md](VALIDATION.md).
