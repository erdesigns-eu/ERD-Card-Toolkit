# MOBIB / Calypso uitlezen en parsen

`TCalypsoCardReader` leest logische bestanden en records. `TMobibCodec` uit
`ERD.Card.MOBIB.Data` geeft de bekende velden als getypeerde gegevens terug.
Beide units zitten in `ERDCardContactless` en het zelfstandige designpackage.
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
Abonnementnamen, volledige contractgeldigheid, tariefregels en vervoerdergebonden
locatienamen zijn nog niet generiek geparsed.

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

Dit is een **providerintegratie**, geen ingebouwde Calypso MAC/SAM-engine of
standaardimplementatie waar je alleen een sleutelarray invult. De correcte
revision-specifieke cryptografie/authenticatie komt uit de gekozen SDK/SAM-adapter.
Ook die provider moet read-only werken; deze component geeft geen debit-, reload-
of contractupdate-commando’s uit. Zonder zo’n adapter en geldige toegang kunnen
beveiligde bestanden nog niet worden verworven.

## Protocolbronnen en validatie

De implementatie is onafhankelijk geschreven op basis van publieke protocolfeiten:
[Cardpeek Calypso/MOBIB-layout](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/calypso/c56n1.lua),
[MOBIB-extractor](https://github.com/zoobab/mobib-extractor),
[EN1545-encoding](https://github.com/L1L1/cardpeek/blob/master/dot_cardpeek_dir/scripts/lib/en1545.lua) en
[Keyple SELECT-vormen](https://github.com/eclipse-keyple/keyple-card-calypso-java-lib/blob/main/src/main/java/org/eclipse/keyple/card/calypso/CommandSelectFile.java).
Er is geen implementatiecode uit deze projecten overgenomen.

Tests gebruiken synthetische gegevens en exacte APDU-transcripten voor reads,
caller-fileplannen, fouten, bounds en sessielifecycle. De codec heeft onafhankelijke
bitvectors, houder-/datum-/event-/counterfixtures en tests voor ownership en
onbekende layouts. Providerfixtures testen dispatch en foutafhandeling; zij testen
geen echte SAM-cryptografie en certificeren geen fysieke kaartgeneratie.
