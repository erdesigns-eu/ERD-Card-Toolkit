# Sessieregie, bewerkingen en projecten

Deze componentlaag staat tussen de kaartprotocollen/workflows en een toekomstige
CardStudio-UI. Er zijn geen nieuwe schermen of demo's. De acht niet-visuele
componenten staan op de palette **ERD Studio** en worden geleverd in het bestaande
core-, PC/SC-, Windows-crypto- en designpackage.

| Component/API | Verantwoordelijkheid |
| --- | --- |
| `TCardSessionManager` | Registry van verbonden `ICardTransport`-readers, één applicatiereservering per reader, thread-eigenaarschap en ongeldig maken bij kaartwissel/loskoppeling |
| `TCardOperationQueue` | Begrensde FIFO, één executor, eenmalige consumptie per queue-entry, annulering, terminale resultaten en `OnResult` |
| `CreateCardMultiWorkflowOperation` | Voorbereide bron/doelworkflow aansluiten op een volledige lezergroep |
| `TCardProjectFileStore` | Expliciete plain/protected bestandssaves, native flush, atomische replacement en replacement-evidence |
| `CreateCardWorkflowOperation` | Een bestaande voorbereide single-card workflow aansluiten op een lease; cancellation doorgeven via veilige voortgangsgrenzen en bestaande observers behouden |
| `TCardOperationExecutor` | Signaalgestuurde worker, veilig stoppen/joinen en creator-thread-resultaten |
| `TCardPcscSessionProvider` | Gekopieerde PC/SC-configuratie, openen/sluiten op de workerthread per lease |
| `TCardProtectedProjectStore` / `TCardWindowsUserProtection` | Geauthenticeerde projectstreamopslag met Windows-user DPAPI en componentbinding |
| `TCardProject` | Gekopieerde artifacts, schema-ID's, dirty state, versiebeheer van het archiefformaat, atomaire import en streamopslag |

## Reader- en kaartlevensduur

Verbind de bestaande readercomponent en registreer diens transport met
`BindReader(ReaderId, Transport)`. Gebruik een vaste unieke ID voor iedere fysieke
reader. Twee verschillende adapters voor dezelfde fysieke reader kunnen niet door
interfacevergelijking als alias worden herkend; registreer die niet afzonderlijk.
Constructie en registratie openen geen hardware. Acquisition kan een lazy provider
openen; de manager doet geen kaartselectie en start geen eigen PC/SC-transactie. De kaartcomponent blijft verantwoordelijk voor fysieke
Begin/EndTransaction, authenticatie, commit/abort en protocolverificatie.

`Acquire(ReaderId)` geeft een lease op de aanroepende workerthread. Geef
`Lease.Transport` aan de kaartcomponent. Het beschermde transport controleert de
lease vóór dispatch en na de response; een kaartwissel tijdens I/O levert dus geen
bruikbaar resultaat op. Een reeds verstuurde opdracht kan wel uitgevoerd zijn:
workflow- of queue-evidence moet die onzekerheid behouden. Een transport zonder
transaction-capability krijgt die capability niet toegevoegd.

Koppel de bestaande PC/SC/reader-events aan `CardChanged` en `DetachReader`.
Een invalidatie kan vanaf een andere thread komen. De huidige reservering blijft
geblokkeerd totdat de oude lease afsluit: een kaartwissel is geen toestemming voor
parallelle I/O. Vervang een gereserveerde backend niet. Na detach en lease-release
kan een nieuw verbonden transport worden geregistreerd. Een manager vernietigen
maakt alle leases ongeldig; de leases behouden hun eigen lifetime references.

Een fysieke Begin-fout verwijdert de backend uit nieuwe reserveringen. Invalidatie
na een succesvolle Begin voert End uit. End blijft toegestaan op een ongeldig
geworden lease, zodat protocolcleanup kan afronden; een End-fout verwijdert de
backend. Een lease met een nog actieve fysieke transactie mag niet sluiten.
Het verlaten van zo'n lease zonder End quarantainet de reservering: er volgt geen
stilzwijgende hardware-release, reset of replay. Houd de protocolcomponenten aan
hun gedocumenteerde cleanupcontracten.

## Bewerkingen en bestaande workflows

`Enqueue(Id, ReaderId, Operation)` accepteert een voorbereide `ICardOperation`.
Er zijn maximaal 256 pending entries. Dubbele pending IDs/operaties en het opnieuw
invoeren van de lopende operatie worden geweigerd. Iedere entry wordt één keer
verwijderd en uitgevoerd, ook bij een fout. Een eigen operation-implementatie
blijft verantwoordelijk voor het bevriezen van zijn invoer en single-use plannen.

Een applicatie/executor roept `ExecuteNext(Manager, Result)` op **één workerthread**
aan. De queue zelf maakt geen verborgen worker, timer of VCL-dispatcher. Enqueue,
CancelCurrent en ClearPending zijn thread-safe; join de executor vóór het
vernietigen van queue/manager of de betrokken readercomponenten. Configureer
callbacks voordat de executor begint en vernietig geen component vanuit callbacks.

Het resultaat bevat job-ID, reader-ID, terminale workflowstate en uitsluitend
exception-classnamen. Een reserveerfout wordt Failed. Een onverwachte Execute-fout
of nonterminale return wordt conservatief Uncertain: de queue kan niet weten of
de job al geschreven heeft. Een bestaande workflow kan zelf preciezere evidence
teruggeven; de optionele ICardOperationFailure-interface geeft de foutklasse door. Een cleanupfout blijft Uncertain. Er is geen automatische retry.

`OnResult` wordt na leasecleanup op de executor aangeroepen. Een observerfout
verschijnt apart als `ObserverErrorClass` en wijzigt de kaartevidence niet. Bestaande
workflowprogress-events blijven werken; gebruik de bestaande eventdispatcher of
UI-marshaling voor VCL-updatecallbacks.

`CreateCardWorkflowOperation(Workflow, BindCallback, OwnsWorkflow)` is de concrete
bridge naar bestaande `TCardWorkflow`-afstammelingen. Prepare eerst de workflow.
De bindcallback koppelt het gereserveerde transport aan de bijbehorende kaartreader
of workflowbackend. De adapter behoudt en herstelt bestaande progress/stage-events,
controleert cancellation op die grenzen en weigert een tweede uitvoering.
De workflow en callbacktarget moeten blijven bestaan tot de operation klaar is;
met `OwnsWorkflow=True` vernietigt de operation de overgenomen workflow.

Deze bridge is gericht op één kaartgeneratie. Voor single-reader bron/doelwissels:
maak eerst een acquisition/back-up job en daarna een expliciete restore job op de
nieuwe lease. Een wissel binnen dezelfde lease wordt terecht ongeldig. Gecoördineerde
multi-reader jobs zijn beschikbaar via AcquireMany/EnqueueMany. Typed magstripe/HID-backendleases
blijven aanvullende infrastructuurprofielen; dit is geen generieke guard voor elk
vendorprotocol dat geen `ICardTransport` implementeert.

## Projecten

Een project bevat een expliciet project-ID en maximaal 1024 artifacts. Elk artifact
heeft een unieke ID, expliciete schema/profile-ID en gekopieerde bytes. Put en Get
geven geen gedeelde mutable buffers door. Er is maximaal 1 MiB per artifact en
16 MiB totale payload. IDs zijn case-sensitive ASCII identifiers van 1..128 tekens;
UI-titels kunnen als metadata in een artifact worden opgeslagen.

`ExportText` produceert deterministisch `ERD-PROJECT 1`-tekst met hexdata en maakt
het project niet clean. `ImportText` valideert het complete begrensde formaat,
versie, identifiers, unieke entries en payloads voordat het bestaande project
wordt vervangen. Een fout bewaart het oude project. Er zijn geen I/O-acties bij
import en geen executable jobs, connecties of sessies in het formaat.

`SaveToStream` schrijft aan de huidige streampositie en maakt het project pas clean
als alle bytes door de stream zijn geaccepteerd. Een schrijfexception kan partial
bytes achterlaten in die stream; flush/durability en atomair vervangen van een
bestaand bestand zijn beleid van de opslagadapter. `LoadFromStream` valideert de
begrensde resterende bytes en importeert atomair. De caller bezit de stream.
`MarkSaved` is beschikbaar wanneer een eigen opslagbackend succesvol gepersisteerd
heeft. Use op één ownerthread; projectbuffers zijn geen concurrent database.

Artifacts kunnen persoonsgegevens bevatten. Het formaat is niet versleuteld of
ondertekend en is geen sleutelkluis. Credentials worden niet automatisch opgeslagen;
voeg ze ook niet zelf toe aan artifacts. Windows-user DPAPI streamopslag is beschikbaar via de aparte store/provider.
Portable key-providers en projectversiemigraties blijven
verdere componentuitbreidingen.

## Componentgrens voor de UI

De UI selecteert readers/projecten, preparet een bestaande workflow, bindt events
en toont de teruggegeven evidence. Reservering, invalidatie, FIFO-consumptie,
annulering en projectvalidatie horen bij deze componenten. Typed artifact-opslag en multi-reader coordination zijn hieronder uitgewerkt. Meer readeradapters
horen eveneens in deze laag en worden niet in forms gebouwd.

## Achtergrondexecutor en PC/SC-provider

`TCardOperationExecutor` levert nu de eigen signal-driven worker. Configureer
`Manager`, `Queue` en `OnResult` op de main/creator-thread en roep Start aan.
Enqueue wekt de worker via een retained signaal; er is geen queue-polling of timer.
De wake-admission check voorkomt dat pending jobs na de stopgrens worden opgenomen.
Stop vraagt cooperative cancellation, joinet de lopende job inclusief verificatie,
laat pending jobs staan en verwijdert pending resultaatnotificaties. LastResult
blijft beschikbaar. Start na Stop maakt een nieuwe worker/signal-generatie.

Executor OnResult wordt via TThread.Queue en de bounded eventdispatcher op de
main/creator-thread geleverd. DispatchResults is beschikbaar voor consoles zonder
GUI-message-loop. Queue/workflow-observers blijven op de worker; verbind UI-resultaten
met de executor. Observerexceptions worden als classnaam gerapporteerd, zonder
kaartuitkomsten te herschrijven of jobs opnieuw uit te voeren. Configureer handlers
voordat Start wordt aangeroepen. Bij notification-overflow stopt de worker met een
expliciete ErrorClass; LastResult bewaart de laatst afgeronde evidence. Er is geen
onbegrensde historybuffer. Free-notifications stoppen/joinen vóór queue/managerstate
wordt vrijgegeven. Vernietig deze afhankelijkheden op de main/creator-thread.

`TCardPcscSessionProvider` configureert exact ReaderName, Protocols en ShareMode.
RegisterReader(Manager, Id) kopieert de instellingen naar een lazy
ICardSessionConnection, zonder native connectie. Iedere Acquire opent de reader
op de lease/workerthread; Close sluit met pcdLeave op dezelfde thread. De provider
kan na registratie worden gewijzigd of vernietigd zonder de geregistreerde
instellingen te veranderen. Het bestaande maximale PC/SC-responsebudget blijft
CardMaxResponseBytes. Native transactions blijven bij de kaartprotocollen.

Open/Close wordt nooit automatisch herhaald. Bij een fout wordt de registratie
ongeldig/verwijderd: registreer pas een nieuwe verbinding na expliciete recovery.
Een kaartwissel tijdens Open leidt tot cleanup vóór jobuitvoering. Een actieve
fysieke transactie moet door de protocolcomponent beëindigd worden voordat de
lease sluit. Een verlaten idle lease sluit zijn provider op de eigen thread;
verkeerde-thread/actieve-transaction abandonment maakt de registratie ongeldig.
Dit is geen impliciete authenticatie, reset, reconnect, commit of abort.

De huidige automatische provider is PC/SC. Typed non-APDU leases, automatische
hot-plugregistratie, projectversiemigraties en portable protection/key-providers
blijven verdere componentuitbreidingen. Er zijn geen schermen of demos toegevoegd.

## Beveiligde projectopslag

`TCardProtectedProjectStore` beschermt de volledige projectarchive voordat een byte
naar de stream wordt geschreven. Koppel `Provider` aan
`TCardWindowsUserProtection` via de componentproperties. Voor andere expliciete
policies kan `Protection` een `ICardProjectProtection` krijgen. Het contract vereist
confidentiality én authenticatie vóór plaintext wordt teruggegeven; er is geen
onbeveiligde fallback. Een componentprovider vernietigen wist de koppeling veilig.

De Windows-provider gebruikt DPAPI voor het huidige gebruikersprofiel met
UI_FORBIDDEN. Openbare envelopeversie en een eveneens beschermde inner namespace
worden gecontroleerd. Een verkeerde profielcontext, corruptie, unsupported versie
of malformed archive wijzigt het bestaande project niet. Failed protection schrijft
geen plaintext en failed opslag maakt het project niet clean. Owned bytebuffers
worden gewist na gebruik; het geopende project blijft uiteraard plaintext in geheugen.
Dit beschermt de opgeslagen bytes, niet de volledige procesheap of actieve sessies.

DPAPI-opslag is gekoppeld aan Windows user/profile/recoverybeleid: het is geen
portable password-format, gedeelde machinepolicy of credential vault. Buiten Windows
faalt de native provider expliciet. De Linux-suite valideert storage via een
synthetische ciphertext-oracle en de platformgrens; de Windows testbranch bevat een
native DPAPI roundtrip/tamper-test. Die native branch is in deze omgeving niet
uitgevoerd. Het bestaande onversleutelde projectformaat blijft afzonderlijk
beschikbaar, en wordt nooit impliciet gebruikt bij een protectiefout.

`RequestStop` op de executor vraagt stoppen zonder join/wacht op de UI-thread.
De huidige job kan zijn verificatie afronden, nieuwe jobs worden niet meer
geaccepteerd voor uitvoering. Roep Stop later aan om de workerresources vrij te
geven; Stop/destructie joinet voordat afhankelijke componenten verdwijnen.


## Meerdere lezers in één job

`Manager.AcquireMany(['source', 'target'])` reserveert één tot zestien unieke
reader-ID's onder één registrylock. Een ontbrekende of bezette member weigert de
hele aanvraag voordat een provider wordt geopend. Er wordt niet gewacht op een
andere job: geen gedeeltelijk vastgehouden reserveringen of lock-order-deadlock.
Callerorder blijft behouden voor `Group.ReaderId(Index)` en `Group.Lease(Index)`.

Providers openen daarna op de acquiring thread. Een gedeeltelijke openfout sluit
reeds geopende members in omgekeerde volgorde en geeft alle reserveringen vrij,
ook wanneer een Close fout gaat. Een gefaalde verbinding wordt verwijderd en niet
opnieuw geprobeerd. `Group.Validate` controleert alle kaartgeneraties zonder I/O;
een wijziging tijdens het openen van een andere member wordt vóór oplevering geweigerd.
Gebruik Validate ook tussen bron- en doelfasen. Elk membertransport bewaakt zijn
eigen generatie bij iedere Exchange. Het systeem maakt geen gedistribueerde
kaarttransactie: een verstuurde doelwrite kan niet door Group.Close worden teruggedraaid.

`Queue.EnqueueMany(Id, ReaderIds, Operation)` kopieert de readerselectie en bewaart
een `ICardMultiOperation`. ExecuteMany ontvangt de complete groep pas na succesvolle
acquisition. De bestaande achtergrondexecutor, cancellation en eenmalige FIFO-consumptie
werken ook voor deze jobs. ReaderId in het resultaat is de eerste member; ReaderCount
is de groepsgrootte. Een acquisitionfout wordt Failed zonder ExecuteMany aan te roepen;
een niet-geclassificeerde uitvoerings- of cleanupfout wordt Uncertain. Close probeert
iedere member te sluiten, ook na een eerdere cleanupfout. De workflow moet eigen
native transacties eindigen voordat de queue de groep kan vrijgeven.

`CreateCardMultiWorkflowOperation(Workflow, BindGroup, OwnsWorkflow)` sluit bestaande
voorbereide bron/doelworkflows aan op EnqueueMany. De callback bindt beide expliciete
backends; de gedeelde bridge bewaart cancellation, observers en failure evidence.
Er is een groepsvalidatie vóór binding en na uitvoering. Native transacties en
inhoudsverificatie blijven bij de workflow. De adapter wordt maar één keer uitgevoerd.

Een groep reserveert uitsluitend `ICardTransport`-backends. Magstripe/HID-projectdata
worden ondersteund door adapters, maar krijgen hiermee geen fictieve APDU-sessies.

## Getypeerde project-artifacts

| Adapter | Methoden | Schema |
| --- | --- | --- |
| TCardProjectArtifacts | PutMemory/GetMemory | memory.v1 |
| TContactlessProjectArtifacts | PutDesfire/GetDesfire | desfire.v1 |
| TContactlessProjectArtifacts | PutMobib/GetMobib | mobib.v2 |
| TMagStripeProjectArtifacts | Put/Get | magstripe.v1 |

De geheugen-, DESFire- en MOBIB-adapters gebruiken de bestaande bounded archivecodecs.
Magstripe bewaart een expliciete trackselectie en gevalideerde unframed payloads;
onselected payloads, ongeldige lengtes, trailing bytes en ongeldige karakters worden
geweigerd. Iedere Get controleert het exacte schema en retourneert onafhankelijke
data. Een ongeldige Put verandert het project niet. De bestaande projectlimiet van
**1 MiB per artifact** blijft gelden, ook wanneer een los familiearchief groter kan
zijn. Schema-ID's en kaartgeometrie blijven onderscheiden. Geen sleutels, live readers,
queued jobs of restore-permissies worden afgeleid uit een opgeslagen snapshot.

## Atomische bestandsopslag

`TCardProjectFileStore` is een inactieve palettecomponent. Verbind ProtectedStore
met `TCardProtectedProjectStore`; `Save(Project, FileName)` en `Load` vereisen dat
beleid. `SavePlain`/`LoadPlain` zijn afzonderlijke expliciete plaintext-methoden.
Er bestaat geen automatische fallback wanneer een provider ontbreekt of weigert.

Save maakt eerst een onafhankelijk projectarchief. Daarna wordt een exclusief,
uniek tijdelijk bestand in dezelfde directory aangemaakt, volledig geschreven en
geflusht. Windows gebruikt CreateFile CREATE_NEW, FlushFileBuffers en MoveFileEx
REPLACE_EXISTING/WRITE_THROUGH; FPC Linux gebruikt O_EXCL met mode 0600, fsync,
rename en daarna een directory-fsync. Een bestaande destination blijft intact bij
fouten vóór replacement. Tijdelijke bestanden worden bij afgevangen fouten verwijderd.
Een procescrash kan een ongebruikt tijdelijk bestand achterlaten; er is geen scan die
bestanden van andere processen verwijdert. De parentdirectory moet bestaan.

`LastSaveReplaced` onderscheidt een fout vóór replacement van een fout ná replacement,
zoals een mislukte directorysync. Het project wordt pas clean na volledige succesvolle
opslag, en alleen als het intussen niet door een protection callback is gewijzigd.
Controleer bij een fout ná replacement het opgeslagen bestand vóór een eventuele nieuwe
save. Er is geen automatische retry. Gelijktijdige saves naar hetzelfde pad hebben
last-replacement-wins-semantiek; projectrevision-locking is nog geen onderdeel hiervan.
Netwerkfilesystem/power-lossgaranties hangen af van het filesystem. Native Windows
is geleverd; de native filesystem-tests hier draaien op Linux. Andere native targets
worden expliciet geweigerd. Load gebruikt bounded streamvalidatie en verandert het
project pas na volledige succesvolle import/authenticatie.
