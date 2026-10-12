# Sessieregie, bewerkingen en projecten

Deze componentlaag staat tussen de kaartprotocollen/workflows en een toekomstige
CardStudio-UI. Er zijn geen nieuwe schermen of demo's. De drie niet-visuele
componenten staan op de palette **ERD Studio** en worden geleverd in het bestaande
core- en designpackage.

| Component/API | Verantwoordelijkheid |
| --- | --- |
| `TCardSessionManager` | Registry van verbonden `ICardTransport`-readers, één applicatiereservering per reader, thread-eigenaarschap en ongeldig maken bij kaartwissel/loskoppeling |
| `TCardOperationQueue` | Begrensde FIFO, één executor, eenmalige consumptie per queue-entry, annulering, terminale resultaten en `OnResult` |
| `CreateCardWorkflowOperation` | Een bestaande voorbereide single-card workflow aansluiten op een lease; cancellation doorgeven via veilige voortgangsgrenzen en bestaande observers behouden |
| `TCardProject` | Gekopieerde artifacts, schema-ID's, dirty state, versiebeheer van het archiefformaat, atomaire import en streamopslag |

## Reader- en kaartlevensduur

Verbind de bestaande readercomponent en registreer diens transport met
`BindReader(ReaderId, Transport)`. Gebruik een vaste unieke ID voor iedere fysieke
reader. Twee verschillende adapters voor dezelfde fysieke reader kunnen niet door
interfacevergelijking als alias worden herkend; registreer die niet afzonderlijk.
Een manager opent geen hardware, doet geen kaartselectie en start geen eigen
PC/SC-transactie. De kaartcomponent blijft verantwoordelijk voor fysieke
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
multi-reader jobs, een eigen achtergrondexecutor en typed magstripe/HID-backendleases
zijn aanvullende infrastructuurprofielen; dit is geen generieke guard voor elk
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
voeg ze ook niet zelf toe aan artifacts. Een versleutelde storage/key-provider,
artifact-schema-adapters en migraties tussen toekomstige projectversies zijn
volgende componentuitbreidingen.

## Componentgrens voor de UI

De UI selecteert readers/projecten, preparet een bestaande workflow, bindt events
en toont de teruggegeven evidence. Reservering, invalidatie, FIFO-consumptie,
annulering en projectvalidatie horen bij deze componenten. Verdere achtergrond-
executors, typed opslag en meer readeradapters horen ook in deze laag; ze worden
niet in forms gebouwd.
