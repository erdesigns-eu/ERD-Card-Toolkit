# SIM / USIM-kaarten

`TSimCardReaderWriter` is een inactieve, VCL-onafhankelijke component in
`ERDCardSIM`. Gebruik een PC/SC-lezer met een passende fysieke SIM-adapter.
Een keyboard-RFID-lezer en een gewone contactless NFC-lezer bieden hiervoor geen
contactinterface. Een geschikte lezer transporteert APDU's; de SIM bepaalt de rechten.

## Aanwezig

- Expliciete klassieke GSM SIM (`A0`) en UICC/USIM (`00`) profielen.
- ICCID, IMSI, service-providernaam en SST/UST-servicebits uitlezen.
- UICC EF.DIR-applicaties enumereren; de volledige USIM AID zelf kiezen.
- Bestandstype, grootte en recordgeometrie inspecteren; transparante bestanden,
  bereiken en absolute linear-fixed/cyclic records uitlezen.
- Transparante bestanden en linear-fixed records vervangen met exacte verwachte
  begininhoud en onafhankelijke terugleescontrole. Geen automatische write-herhaling.
- Standalone ADN-contacten lezen, schrijven en wissen; GSM/UCS-2 namen en TBCD-nummers.
- USIM PBR-decoder met expliciete A8/A9/AA-templates, file-role/FID/SFI en IAP-posities; gekoppelde writes worden nog niet automatisch beheerd.
- Gekoppelde USIM-contacten lezen: expliciet ADN-FID/PBR-record, IAP-posities, ruwe gekoppelde velden en gevalideerde EXT-nummerketens in één transactie.
- SMS-tekstdecoder voor DELIVER/SUBMIT: GSM zeven-bit, UCS-2, binaire payloadbehoud, UDH/segmentreferenties en applicatiepoorten; expliciete volledige segmentsets samenvoegen zonder automatisch berichten te groeperen.
- SMS-recordcodec met status en behoud van alle 175 bodybytes (SMSC/TPDU/padding).
  SMS-geheugen lezen/schrijven via de expliciete recordmethoden.
- Een aangeleverde PIN één keer presenteren als het resterende budget bekend en
  voldoende is. PIN-status opvragen zonder een codepoging.
- Offline ICCID/IMSI, GSM/UCS-2, SPN, ADN, SMS, EF.DIR en bestandsmetadata-codecs.

De component vereist `ICardTransport` met `ICardTransaction`; iedere actie bezit
één exclusieve transactie. Inputs worden voor acquisitie gekopieerd. PIN- en
commandokopieën worden gewist. Na een verzonden UPDATE blijft een fout expliciet
`ESimCardWriteUncertain`, inclusief `VerifiedReadBack` wanneer alle bytes al bewezen
zijn maar de afsluiting mislukte. Een geslaagde UPDATE-status alleen is geen writebewijs.

## Adressen en authenticatie

`TSimCodec.FileAddress` neemt een expliciete root en één tot acht FIDs. Voeg `3F00`
niet toe aan het pad: de component selecteert het masterbestand zelf.

| Bestand | Klassieke SIM vanaf master | UICC/USIM |
| --- | --- | --- |
| ICCID | `2FE2` | Master: `2FE2` |
| Applicatiecatalogus | Niet aangeboden | Master: `2F00` |
| IMSI | `7F20/6F07` | Geselecteerde USIM-applicatie: `6F07` |
| SPN | `7F20/6F46` | USIM: `6F46` |
| SST / UST | `7F20/6F38` | USIM: `6F38` |
| ADN | `7F10/6F3A`, indien aanwezig | Werkelijke EF uit PBR zelf aanleveren |
| SMS | `7F10/6F3C`, indien aanwezig | USIM: `6F3C`, indien aanwezig |

Aanwezigheid en toegang variëren per operator. USIM-contacten worden **niet**
automatisch op `6F3A` verondersteld. Lees zo nodig `5F3A/4F30` (PBR), decodeer met `DecodePhonebookReferences` en gebruik
het daadwerkelijke ADN-pad. Hoge niveau contactwrites weigeren bestaande CCP/EXT-links
om verlies van gekoppelde gegevens te voorkomen. De generieke record-API behoudt
het door de applicatie aangeleverde volledige record.

Een PIN bestaat uit vier tot acht ASCII-cijferbytes. In de VCL-demo wordt hij als
hex ingevoerd: `1234` wordt `31323334`. Dit is geen numerieke BCD-PIN.
UICC-applicatietoegang vereist de gekozen volledige AID; een aangeleverde USIM-PIN
wordt niet gebruikt voor master-rootbestanden. Een reeds geverifieerde UICC-sessie
mag voor toegang worden hergebruikt; dat bewijst geen opnieuw aangeleverde PIN.
`VerifyPin` weigert zo'n sessie en weigert onbekende budgets. De bibliotheek raadt
geen PIN/ADM-code en verlaagt nooit automatisch de ingestelde retrygrens.

SST toont afzonderlijk allocated/active-bits. UST toont beschikbaarheid; zijn
`Active`-veld spiegelt beschikbaarheid en beweert geen EF.EST-activatiestatus.

## Delphi-voorbeeld

```pascal
Sim := TSimCardReaderWriter.Create(nil);
try
  Sim.Transport := Reader; // connected PC/SC transport with transaction support
  Sim.Profile := scpUiccUsim;
  Applications := Sim.ReadApplications;
  Sim.ApplicationAid := ChosenFullAid;
  Identity := Sim.ReadImsi(SuppliedAsciiPin);
  Address := TSimCodec.FileAddress(sfrUsimApplication, [$6F3C]);
  SmsRecords := Sim.ReadRecords(Address, SuppliedAsciiPin);
finally
  Sim.Free;
end;
```

`SimCardDemo` biedt alle kaartmethoden, expliciete paths, verwachte bytes,
terugleesbewijs en offline decoders. Geen verbinding of PIN-poging bij opstarten.

## Grenzen en verdere uitbreidingen

Dit is geen telefonie-stack: geen netwerkregistratie, telefoonmodem, SMS verzenden,
GSM/AKA-authenticatie, Ki-uitlezing, eSIM-download/provisioning of SIM Toolkit.
ADM-authenticatie, automatische recordallocatie voor USIM-contacten,
automatische SMS-berichtgroepering, nationale taaltabellen en extra telefoonbestanden zijn vervolgstappen.
Cyclic-recordwrites ontbreken; absolute cyclic reads zijn aanwezig. Binary-offsets
zijn beperkt tot 32767; volledige transparante files tot 32768 bytes. Records zijn
maximaal 255 bytes/255 records. Grotere profielen worden geweigerd, niet afgekapt.

Praktische volgende uitbreidingen: eerst automatische link-/recordallocatie,
daarna automatische recordallocatie/telefoniebestandprofielen waar een concreet protocol beschikbaar is.
Andere kaartfamilies: de resterende VCL-demo's, native USB-HID-bronnen, MIFARE Plus
of CryptoMemory vereisen elk hun eigen reader/protocolprofiel; betalingen blijven buiten scope.

## Validatie en bronnen

De protocolindeling volgt ETSI TS 151 011 / 3GPP TS 51.011 (klassieke SIM),
ETSI TS 102 221 (UICC), TS 131 102 / 3GPP TS 31.102 (USIM) en
3GPP TS 23.038 (tekencodering). Publieke pySim-protocoldefinities zijn gebruikt
als secundaire crosscheck; de Pascal-implementatie is zelfstandig geschreven.

74.402 SIM/USIM-assertions zijn uitgevoerd onder FPC met range/overflow/heapchecks:
literal APDU's/codecs, PIN-budgetten, buffers, elke write-I/O-grens, volledige
terugleesbits, chunking en cleanup-onzekerheid. De aparte familie-executor heeft
ook literal SIM-leesroutes en preflighttests. **Delphi/Windows en fysieke SIMs zijn
nog niet getest.** Bronvalidatiescripts vervangen die tests niet.

## Gekoppelde contacten en SMS-tekst

`ReadLinkedUsimContact(PbrRecord, ActualAdnFid, Record, Pin)` leest de gerefereerde
linear-fixed EFs onder één exclusieve transactie. De ADN-keuze is expliciet;
ontbrekende/ambigue IAP/EXT-referenties, pointers buiten het bestand en loops worden
geweigerd. EXT type 2 wordt als extra nummerdigits gevolgd; overige gekoppelde
velden blijven volledige bytes inclusief footer. EMAIL/ANR-codecs vereisen een expliciete footer-layout; ANR retourneert het inline nummer en behoudt CCP/EXT-verwijzingen.
Gekoppelde writes gebruiken een expliciet caller-plan; er wordt geen vrije record/link gegokt. Dit profiel vereist precies één ADN en ondubbelzinnige IAP/EXT-referenties in het gekozen PBR-record. Type-2 EMAIL/ANR/SNE-terugverwijzingen worden tegen de gekozen ADN-record/SFI gecontroleerd.
Maximaal 32 verschillende EFs worden
ingelezen. Type-3 referenties worden alleen gevolgd voor de ondersteunde EXT-keten.

`DecodeSmsMessage` accepteert een volledig toegewezen 176-byte EF.SMS-record en
controleert dat DELIVER/SUBMIT overeenkomt met de opgeslagen richting. GSM-text
wordt met UDH-fillbits gedecodeerd. UCS-2 behoudt ook nul/FF-codepunten; surrogates
worden geweigerd. Acht-bit berichten geven `TextDecoded=False` en exacte user data.
SCTS blijft origineel in `TimestampBytes`; er wordt geen UTC/jaartal geraden.
Ondersteunde DCS-groepen: algemene ongecomprimeerde 00..3F, geldige C/D/E message-waiting en F0..F7 class-coding.
Onbekende UDH-elementen blijven behouden, maar nationale language-shift-IEs,
gecomprimeerde/reserved DCS, enhanced validity en STATUS-REPORT TPDUs worden
expliciet geweigerd. `AssembleSms` voegt expliciet aangeleverde volledige sets samen; ontbrekende, dubbele of gemengde richting/adres/DCS/PID/UDH worden geweigerd. Acht- en zestien-bit referenties worden onderscheiden.

`InspectSim --sms-text <complete-record-hex>` en de offline SMS-textactie in
`SimCardDemo` tonen de inhoud. De linked-contactactie toont originele ADN, exact
gelinkte records en EXT-keten. Gebruik de werkelijke USIM AID en decimal ADN-FID.

De offline VCL-acties EMAIL, ANR en SMS-join tonen deze codecs. SMS-join neemt
complete EF.SMS-records gescheiden door puntkomma en ordent de segmenten.
Onbekende UDH-elementen moeten gelijk zijn voor de hele set. Bij binaire SMS
worden de payloads zonder hun headers samengevoegd; originele segmentbytes blijven
in `Segments` beschikbaar. De caller bepaalt welk bericht de set vormt.

## PIN/PUK-beheer en gekoppelde writes

`GetPukStatus` leest classic PUK-counters of gebruikt een expliciete UICC
RESET RETRY query. Kaarten die daarbij geen bekend budget rapporteren worden
voor unblock geweigerd; er wordt geen codepoging gebruikt om het budget te raden.
`ChangePin` en `UnblockPin` sturen één CHANGE/UNBLOCK met supplied ASCII-cijfers.
`MinimumPinAttempts` geldt ook voor het bekende PUK-budget. Geen voorafgaande
VERIFY die een extra poging kan verbruiken. Zowel caller-input als backend errors
worden beschermd door owned/wiped commandokopieën en gesaniteerde fouten.

De returnwaarde `TSimCredentialReceipt.CommandAccepted` is uitsluitend het
commandostatusbewijs na geslaagde afsluiting. **Geen nieuw-PIN-bewijs wordt geclaimd.**
Een applicatie kan na een expliciete reset/nieuwe sessie `VerifyPin` gebruiken.
De component doet zelf geen reset, automatische retry of tweede codepoging.

`WriteLinkedPhonebookRecords` neemt één tot 32 expliciet geordende veranderingen
met USIM `5F3A/FID`, record, exacte before/data. Alle beginrecords worden onder één
transactie gecheckt vóór de eerste UPDATE; elk gewijzigd record opnieuw vlak vóór
zijn write; alle eindrecords worden onafhankelijk teruggelezen. De volgorde is
caller-defined, bijvoorbeeld eerst een nieuwe EMAIL/EXT-recordinhoud en pas daarna
de IAP/ADN-link. Meerdere writes zijn **niet atomair**. Na partial dispatch geen
rollback/replay: `ESimCardWriteUncertain` blijft expliciet, met readback proof waar
aanwezig. PBR-wijzigingen, duplicate records en onbekende geometrie zijn geweigerd.
Geen automatische allocatie of impliciete wijziging van andere contacten.

De VCL-planactie gebruikt `FIDhex:record:beforehex:datahex` per puntkommaregel,
bijvoorbeeld `4F50:1:41420101:42420101`. PIN/PUK wordt uitsluitend als ASCII-hex
ingevoerd; credential-acties tonen statusreceipt, linked writes volledig readback.
