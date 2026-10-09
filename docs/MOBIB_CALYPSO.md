# MOBIB / Calypso uitlezen en parsen

`TCalypsoCardReader` leest logische bestanden en records. `TMobibCodec` uit
`ERD.Card.MOBIB.Data` geeft de bekende velden als getypeerde gegevens terug.
`TMobibSubscriptionCodec` decodeert de gedocumenteerde contractversies.
`TCalypsoSamSessionProvider` verzorgt native authenticatie via een aangesloten SAM.
Deze units zitten in `ERDCardContactless` en het zelfstandige designpackage.
`MobibDemo` heeft een eigen DFM en een eigen PC/SC-lezerkeuze.

Een contactless smartcardlezer moet ISO 7816 APDU’s ondersteunen. Een reader die
alleen een kaartnummer als toetsenbordinput doorgeeft kan deze bestanden niet lezen.

## Bestanden en records

`ReadMobib` selecteert ticketingdirectory `2000` en leest environment `2001`,
holder `2002`, events `2010`, contracts `2020`, counters `2069`, contract list
`2050`, special events `2040` en extended holder `3F1C`.

`ReadMobibFiles` accepteert een eigen plan met maximaal 64 unieke, bekende FIDs.
Hiermee kun je aanvullende bestanden uitlezen, binnen dezelfde transactie en
beveiligde sessie. De demo heeft een bewerkbaar veld voor deze FID-lijst.
`ReadFile` leest één bekend logisch bestand in de huidige toepassing.

Records worden echt doorlopen; de limiet is 1–255 per bestand, standaard 16.
`6A83` markeert het einde; `Truncated` onderscheidt het bereiken van de limiet.
SELECT- en recordbytes, afwezige bestanden (`6A82`) en toegangs-/toestandsbeperkingen
(`6982`/`6985`) blijven beschikbaar. Er worden geen authenticatiepogingen gegokt.
Een onverwachte status geeft `ECalypsoStatusError.StatusWord`.

Kies het dialect expliciet: legacy CLA `94`/SELECT P1 `00`, of revision-3
CLA `00`/SELECT P1 `09`. Record-Le is standaard 29 bytes; één `6Cxx`-correctie
en begrensde `61xx`-response chaining zijn ondersteund. Geen dialectfallback.

## Geparste gegevens

Kies in MobibDemo **Legacy MOBIB 056/001** voor de gepubliceerde legacy-layout.
De parser controleert de aanwezige environment-netwerkvelden en past die layout
alleen toe bij land `056` en netwerk `001`. De expliciete profielkeuze en match
bewijzen niet dat alle De Lijn/STIB/TEC/NMBS-kaartgeneraties dezelfde layout hebben.

De huidige typed resultaten bevatten:

- Land- en netwerkcode en expliciete layoutmatch.
- Uit de twee extended-holderrecords: negentiencijferig nummer met voorloopnullen,
  naam uit het vijf-bit alfabet, geldige BCD-geboortedatum en ruwe gendercode.
- Events: validatie- en eerste-validatiedatum/tijd, transportcode, de bekende
  metro/premetro/bus-locatievelden, busroute en het event count/couponveld.
- Het bekende aankoopdatumveld per contract en het contractlijst-aantal.
- Afzonderlijke big-endian 24-bit tellers. Ze worden niet opgeteld of automatisch
  als resterende ritten geïnterpreteerd; de contractassociatie kan verschillen.

`TMobibData.Raw` blijft een onafhankelijke kopie van **alle** verworven gegevens,
inclusief onbekende velden. Onbekende netwerken krijgen geen verzonnen naam,
product, geldigheid of ritlocatie. Verkeerde BCD/datum/range in een bekende layout
geeft een expliciete decodefout. Kies raw mode om een afwijkende layout te onderzoeken.
De aanvullende abonnementcodec hieronder geeft bekende productnamen en
versiegebonden contractsemantiek. Volledige contractgeldigheid, operatorregels
en vervoerdergebonden locatienamen zijn niet universeel bekend.

```pascal
Reader := TCalypsoCardReader.Create(nil);
try
  Reader.Transport := ConnectedTransport;
  Reader.Dialect := cdLegacy94;
  Parsed := TMobibCodec.Decode(Reader.ReadMobib(16), mlLegacy056001);
  // Parsed.Holder, Events, Contracts, Counters en Raw zijn caller-owned data.
finally
  Reader.Free;
end;
```

## Geldige sleutels of een SAM doorgeven

MOBIB-uitgeverssleutels zijn niet publiek beschikbare configuratiewaarden.
Er worden geen standaard- of gegokte sleutels aangeboden. Publieke testsleutels
van Calypso zijn geen toegangssleutels voor een uitgegeven MOBIB-kaart.

Voor partijen die wel geldige sleutels/SAM-toegang hebben is er een concrete
providerkoppeling:

```pascal
Reader.SecureSessionProvider := MyCalypsoSdkOrSamProvider;
Reader.RequireSecureSession := True;
Snapshot := Reader.ReadMobibFiles(KnownFileIds, 32);
```

Implementeer `ICalypsoSecureSessionProvider.Open` met de SDK/SAM voor de echte
kaartrevision. De provider bezit de aangeleverde sleutelmaterialen, sleutelindex,
versie en authenticatie-instellingen; die worden niet in records, foutmeldingen
of demo-invoertekst gekopieerd. Hij ontvangt de exclusieve verbonden transport,
het expliciete dialect en selectiegegevens. Voor `ReadFile` zijn selectiegegevens
nil en kan de provider zelf de vereiste applicatievoorbereiding uitvoeren.

`Open` geeft `ICalypsoSecureReadSession` terug. `GetTransport` levert een adapter
die beveiligde opdrachten afhandelt en geverifieerde/decrypted APDU-antwoorden
teruggeeft. `Finish` moet sessieauthenticatie controleren; pas daarna retourneert
de reader de snapshot. Bij een fout wordt `Abort` aangeroepen en blijft de
primaire fout behouden. Geen fallback naar publieke of ongeverifieerde uitlezing.
Een ontbrekende provider bij `RequireSecureSession=True` faalt vóór kaart-I/O.

## Native authenticatie via SAM

`ERD.Card.Contactless.Calypso.SAM` bevat een concrete Delphi-engine; een externe
Calypso-SDK is daarvoor niet nodig. Ondersteunde sessievormen:

| Instelling | Kaart-CLA | Challenge / sessie-MAC |
| --- | --- | --- |
| `csrRevision1` | 94 | 4 / 4 bytes |
| `csrRevision2` | 94 | 4 / 4 bytes |
| `csrRevision3` | 00 | 4 / 4 bytes, compatibility |
| `csrRevision32` | 00 | 8 / 8 bytes, extended plaintext |

De SAM verzorgt diversificatie, verse challenge, MAC-berekening en verificatie.
Delphi stuurt SELECT DIVERSIFIER, GET CHALLENGE, DIGEST INIT/UPDATE/CLOSE en
DIGEST AUTHENTICATE; de kaart krijgt OPEN/CLOSE SECURE SESSION. Iedere succesvolle
SELECT/READ-opdracht en het complete antwoord worden opgenomen, met uitsluiting
van Le bij case-4-opdrachten. Een resultaat verlaat de reader pas na verificatie
van de kaart-MAC. Sleutels worden niet uit de SAM gelezen of gelogd.

Voorbeeld na het verbinden van **twee afzonderlijke** `TSmartCardReader`-componenten:

```pascal
Reader.Transport := CardReader.Transport;
Reader.Dialect := cdIso00;
Reader.SecureSessionProvider := TCalypsoSamSessionProvider.Create(
  SamReader.Transport, csrRevision3, CardSerialEightBytes,
  AuthorizedKeyIndex, AuthorizedKif, AuthorizedKvc, $80);
Reader.RequireSecureSession := True;
FileData := Reader.ReadFile($2020, 1);
```

Vereist een geschikte legacy Calypso SAM met de geldige issuer-/werksleutels,
eventueel vooraf geselecteerd en unlocked volgens zijn eigen provisioning.
KIF/KVC moeten overeenkomen met de kaart; een mismatch leidt niet tot een andere
sleutel of downgrade. De achtbyte-serie/diversifier moet uit een betrouwbare
kaartselectie of applicatieconfiguratie komen; ticketingbytes worden niet als
serienummer gegokt. SAM-CLA 80/94 is expliciet instelbaar.

De SAM-verbinding krijgt een eigen exclusieve transactie. Gebruik beide
verbindingen op dezelfde workerthread en deel de SAM niet tijdens een sessie.
De engine ondersteunt hier geauthenticeerde **plaintext reads**, geen encrypted
sessies, PKI, sleutelarray zonder SAM, writes, debits of contractupdates.

Dit strikte profiel accepteert alleen succesvolle SELECT FILE/READ RECORD-APDU's.
Gebruik bekende bestaande bestanden en een exact recordaantal; een foutstatus,
6C/61-chaining, response boven 255 bytes inclusief status of READ-Le boven 253
breekt de beveiligde acquisitie af. De publieke reader ondersteunt nog steeds
zijn bestaande probe-/chaininggedrag. Een ontbrekend bestand kan dus in een
publieke snapshot als status verschijnen, terwijl de native beveiligde snapshot
wordt afgebroken. Voor het lezen van alleen record één is de limiet één; de
`Truncated`-vlag blijft de bereikte acquisitielimiet aangeven.

MobibDemo heeft hiervoor een derde, eigen DFM-pagina met aparte dropdown voor de
SAM, gevuld door de demo zelf. Het voorbeeld meldt geverifieerde mutual MAC en
exporteert pas nadat `Finish` gelukt is. Bij iedere fout worden beide verbindingen
vrijgegeven; cleanupfouten overschrijven de primaire lees-/authenticatiefout niet.

## Abonnementen en contractsemantiek

`TMobibSubscriptionCodec.DecodeSnapshot(ParsedMobib)` werkt op het expliciet
gematchte 056/001-profiel. `Decode` kan ook een los contract offline verwerken.
Alle originele bytes blijven onafhankelijk beschikbaar in `Raw`.

| Contractveld | Versies 0–3 | Versie 4 |
| --- | --- | --- |
| Tariefcode | 14 bits vanaf bit 27 | 14 bits vanaf bit 25 |
| Prijs | 16 bits vanaf bit 103 | 16 bits vanaf bit 89 |
| Aankoopdatum | 14 bits vanaf bit 41 | optioneel, presence-bitmap bit 2 |
| Duur | niet gepubliceerd | optioneel, bitmap bit 3: unitcode 2 bits + waarde 8 bits |

De vijfbit-bitmap bij bit 111 gebruikt bit 0 als eerste optionele veld; ook de
onbekende optionele velden worden correct overgeslagen. Onbekende contractversies
vanaf vijf blijven raw en krijgen `LayoutMatched=False`. Een nuldatum is afwezig;
een nulprijs, nulduur of nulteller is een aanwezige waarde.

Vier bekende tariefcodes hebben een productnaam: `2801` JUMP 1 trip, `2803` JUMP
10 trips, `0805` airport bus en `303D` JUMP 24h inclusief airport bus. Overige
codes blijven numeriek beschikbaar zonder verzonnen productnaam. Tariefbits
10–12 geven counter-use: code vier is een tijdproduct; de teller wordt dan niet
als resterende ritten gepresenteerd. Bij andere counter-use-profielen wordt een
beschikbare gekoppelde teller apart als remaining trips aangeboden.

De teller uit `2069` record één wordt gekoppeld via het **absolute contract-
recordnummer**, niet de positie in de lijst met gevonden contracten. Ontbrekende
of beveiligde tellers blijven afwezig. De prijs is eurocenten van de aankoop,
geen elektronisch saldo. `HasSaleDate`, `HasDuration`, `HasCounter` en
`HasRemainingTrips` onderscheiden een echte nul van ontbrekende informatie.

Dit vult de eerder ontbrekende getypeerde abonnementgegevens aan, maar vormt
geen universele issuer-entitlement-engine. De openbare layout geeft geen
betrouwbare activatie-/einddatum of volledige De Lijn/STIB/TEC/NMBS-productcatalogus.
Daarom wordt een aankoopdatum niet tot startdatum gemaakt en worden duurunits,
zones en operatorregels niet gegokt. De applicatie kan aanvullende officiële
operatorregels toepassen op de bewaarde velden/bytes. Kaartauthenticatie bewijst
ook niet op zichzelf dat een abonnement vandaag geldig is.

## Protocolbronnen en validatie

De implementatie is onafhankelijk geschreven op basis van publieke protocolfeiten:
[Cardpeek Calypso/MOBIB-layout](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/calypso/c56n1.lua),
[MOBIB-extractor](https://github.com/zoobab/mobib-extractor),
[EN1545-encoding](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/lib/en1545.lua) en
[Metrodroid MOBIB-contractlayout](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/mobib/MobibSubscription.kt),
[Metrodroid tariefcodes](https://github.com/metrodroid/metrodroid/blob/master/src/commonMain/kotlin/au/id/micolous/metrodroid/transit/mobib/MobibLookup.kt),
[Keyple SAM protocol](https://github.com/eclipse-keyple/keyple-card-calypso-crypto-legacysam-java-lib),
[Keyple secure-session framing](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib) en
[Keyple SELECT-vormen](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib/blob/main/src/main/java/org/eclipse/keyple/card/calypso/CommandSelectFile.java).
Er is geen implementatiecode uit deze projecten overgenomen.

Tests gebruiken synthetische gegevens en exacte APDU-transcripten voor reads,
caller-fileplannen, fouten, bounds en sessielifecycle. De codec heeft onafhankelijke
bitvectors, houder-/datum-/event-/counterfixtures en tests voor ownership en
onbekende layouts. Native SAM-tests gebruiken afzonderlijke exacte kaart-/SAM-transcripten voor alle
vier sessievormen, case-4-Le-uitsluiting, verkeerde MAC/sleutel/challenge, abort,
transportfouten en cleanup. Abonnementtests omvatten alle 32 presence-bitmaps,
versies 0–4, onbekende versies, nulwaarden, truncatie en absolute tellertoewijzing.
De synthetische MAC-waarden testen protocolorkestratie, niet het cryptografische
binnenwerk van fysieke SAM-hardware; ze certificeren geen fysieke kaartgeneratie.
