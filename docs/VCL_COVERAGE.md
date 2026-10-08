# VCL-voorbeelden: dekking en volgende uitbreiding

De volgende uitbreiding krijgt **losse demo's per kaartfamilie**, met gedeelde
basiscode. Onderstaande projectnamen zijn gepland; alleen **SmartCardDemo** en
**MagStripeDemo** bestaan nu. Deze lijst is de afwerkchecklist, geen claim dat alle
knoppen of nieuwe projecten al aanwezig zijn. Betalingen blijven buiten scope.

| Demo | Te demonstreren aanwezige functionaliteit | Huidige VCL-dekking |
| --- | --- | --- |
| ReaderToolsDemo | PC/SC-lezers, verbinding/kaartstatus, ATR/protocol; offline APDU, ATR, BER-TLV, hex/bytes en catalogs | Readerlijst, ATR/protocol en UID in SmartCardDemo; overige tools ontbreken |
| MagStripeDemo | Track 1–3, framing/pariteit/LRC, financiële velden, MagTek-inputprofielen; MSR206/MSR605 statuswrites en MSR206-7HL geverifieerde writes | Offline tracks en MSR206-7HL lezen/schrijven aanwezig; overige profielen/decoders ontbreken |
| BelgianEidDemo | Identiteit, adres, foto opslaan, beschikbare certificaten en ruwe handtekeningen exporteren | Identiteit/adres/foto in SmartCardDemo; volledige bestandsexport ontbreekt |
| IcaoDocumentDemo | BAC/PACE, MRZ/CAN, CardAccess/DG1/DG2/COM/SOD, alle foto's bekijken/opslaan en ruwe bestanden exporteren | Toegang en identiteit/eerste foto in SmartCardDemo; volledige export en alle foto's ontbreken |
| EmvDemo | PSE/PPSE, expliciete applicatie/PDOL, GPO/AFL/records, beschikbare bankvelden, GET DATA en transactielogs; offline EMV/TLV-diagnostiek | Alleen applicatiedetectie in SmartCardDemo |
| MifareClassicDemo | Mini/1K/4K-layout, aangeleverde sleutel A/B, blokken lezen en ondersteunde datablokken geverifieerd schrijven | Alleen algemene UID-uitlezing in SmartCardDemo |
| Type2Demo | Ultralight/EV1/NTAG-modellen, pagina's/geheugen lezen, gebruikerspagina's schrijven, ondersteunde PWD_AUTH/PACK-profielen en Type 2 NDEF | Publieke NDEF lezen/vervangen in SmartCardDemo; pagina's en beveiligde toegang ontbreken |
| Type4NdefDemo | Ondersteunde capability/file-selectie en publieke NDEF lezen/vervangen met terugleescontrole | Lezen/vervangen in SmartCardDemo; apart voorbeeld en inspectie ontbreken |
| Iso15693Demo | Expliciete readerbackend, systeeminformatie, UID/wire-volgorde, blokken/status lezen en schrijven, publiek Type 5 NDEF | Nog geen VCL-voorbeeld |
| UidProgrammingDemo | Alle geïmplementeerde UID-profielen, expliciete kaart/readerkeuze, verwachte beginstaat, behoud van metadata, programmeeruitkomst en afzonderlijke RF-verificatie | Nog geen VCL-voorbeeld |
| DesfireDemo | Publieke informatie; EV1/EV2 AES, bestanden/waarden/records, writes, backuptransacties/commit/abort, directories, applicatie/bestandbeheer en sleutel/toegangsbeheer | Alleen publieke versie in SmartCardDemo |
| MemoryCardDemo | Alle aanwezige gewone SLE/I2C-modellen/dialecten, geheugen/protectie/retrypolicy, PIN, geverifieerde writes, ondersteunde PIN-vervanging en permanente bescherming | Snapshot/range, PIN en writes in SmartCardDemo; PIN-vervanging/bescherming ontbreken |
| SleCounterDemo | SLE4406/4436/5536/6636 met bekende vensters, bit/carry/backup-programmering en ruwe certificaatberekening | Alleen publieke reads in SmartCardDemo |
| Sle4404Demo | Bekende layout/counters, publiek/beveiligd lezen, user-codebewijs, bitprogrammering, scratchpad- en applicatie-erases met beide codes | Alleen publieke reads in SmartCardDemo |
| Twn4Demo | PRS/USB-CDC reader/version/tag inspection, supplied-key Classic and public Type 2 reads/verified writes, explicit CRC mode | Console/API example available; no VCL example yet |
| RfidInputDemo | Keyboard-invoer; 8/9-byte toetsenbordreports en vaste ASCII-velden; ASCII/hex/decimaal, framing/deadlines en expliciete byteconversie | Keyboard-invoertab in SmartCardDemo; ruwe reportprofielen/conversie ontbreken |

Naast de kaartoperaties krijgen de bijbehorende **offline encoders/decoders**
invoer en een zichtbaar resultaat: onder andere MRZ, NDEF-records, magstripe,
EMV-tags, ATR-hints en de aangeboden numerieke RFID-conversies. Cryptoproviders
worden expliciet ingesteld bij BAC/PACE en DESFire; beschikbare cryptoprimitieven
kunnen met de bestaande onafhankelijke testvectoren offline worden getoond.

## Gedeelde basis en uitvoervolgorde

De bestaande workerbasis wordt gedeeld. Elke demo krijgt eigen invoer en een kleine
kaartgerichte uitvoerlaag, zodat een ontwikkelaar het relevante voorbeeld kan
kopiëren zonder een applicatie met alle kaartfamilies te hoeven meenemen.

1. Reader/tools, RFID/TWN4 en gewone/SLE-counter/SLE4404-memorydemo's.
2. Belgische eID, ICAO en volledige EMV-uitlezing.
3. Classic/Type 2, Type 4 en ISO 15693/Type 5.
4. Programmeerbare UID's en DESFire-transacties/administratie.
5. Aanvullende magstripeprofielen en controle van de complete dekking.

Alle aanwezige lees-, schrijf-, beveiligings-, beheer- en toolmogelijkheden horen
in deze dekking. Een API zonder concrete hardwarebackend krijgt een voorbeeld met
een expliciete aangeleverde bron of een offline fixture. Dat wordt zichtbaar
vermeld; een decodervoorbeeld levert geen nieuwe hardwareondersteuning op.
Ontbrekende chipprotocollen, betalingen en niet-geïmplementeerde authenticiteitstests
worden niet als werkende demofuncties opgenomen.

## Afwerkcriteria per demo

- Native Delphi-project in de VCL-projectgroep en buildscript; BOM/CRLF en
  configuratieconventies blijven gelijk aan de gerepareerde projecten.
- Hardwareactie pas na expliciete reader-, kaart- en operatiekeuze; geen automatische
  probe, write, PIN-poging of herhaling van een onzekere uitkomst.
- Hardwarewerk op de gedeelde achtergrondbasis; credentials worden bij de
  threadgrens gekopieerd en na gebruik lokaal gewist. Geen secrets in foutmeldingen.
- Schrijf-/erase-/lock-/sleuteloperaties tonen hun specifieke gevolgen en vereisen
  expliciete invoer; verwachte beginstaat en terugleesbewijs worden waar aangeboden
  gebruikt. Status-only bewijs blijft als zodanig zichtbaar.
- Publieke Delphi XML-documentatie, validatiescripts en relevante geïnjecteerde
  uitvoertests; daarnaast echte Delphi/Windows/UI/hardware-smoketests.
- Deze tabel wordt per afgeronde demo bijgewerkt. Alle nieuwe projectnamen blijven
  gepland tot hun code en project daadwerkelijk in de repository staan.

De bestaande demo's en hun huidige teststappen staan in [VCL_DEMOS.md](VCL_DEMOS.md).
