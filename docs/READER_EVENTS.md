# Reader- en kaart-events

Voor eventgedreven applicaties zijn er drie inactief aangemaakte palettecomponenten.
Events, configuratie en Start/Stop horen op de hoofdthread. Geen constructor opent
hardware, start een thread of maakt een verborgen Windows-window.

| Component | Startpunt | Events |
| --- | --- | --- |
| `TSmartCardMonitor` (`ERD.Card.PCSC.Monitor`) | `Start`; geen readerselectie nodig | `OnReaderAdded`, `OnReaderRemoved`, `OnCardInserted`, `OnCardRemoved`, `OnStateChanged`, `OnError` |
| `THidDeviceMonitor` (`ERD.Card.HID.Monitor`) | `Start`; native Windows-device-notificaties | `OnDeviceAdded`, `OnDeviceRemoved` met exact HID-interfacepad |
| `TUsbHidInputMonitor` (`ERD.Card.HID.Monitor`) | `Device` instellen, daarna `Start` | `OnInputReport`, `OnError` |

## PC/SC

De monitor gebruikt een eigen PC/SC-context en één native `SCardGetStatusChangeW`
voor alle readers plus de PnP-notificatiereader. De eindige 250-ms wachttijd maakt
stoppen mogelijk als annulering net vóór een wait valt. Timeouts veroorzaken geen
reader-inventorypolling. Alleen bij starten of een PnP-wijziging wordt de readerlijst
opnieuw gelezen. Ook starten zonder aangesloten reader werkt.

`EmitInitialState=True` meldt bestaande readers en aangeboden kaarten bij starten.
Met `False` vormt de eerste waarneming de uitgangssituatie, zonder initiële events.
Een verdwenen reader veroorzaakt eerst kaartverwijdering als daarin een kaart zat.
Kaartverwijdering levert de laatst bekende snapshot, inclusief ATR; `OnStateChanged`
levert de nieuw waargenomen status. Ook een native tellerwijziging of een andere
ATR bij blijvende present-status kan een waargenomen kaartvervanging melden.
De monitor gebruikt geen kaartverbindingen of APDU's, wijzigt niets en kiest geen reader.

```pascal
FMonitor := TSmartCardMonitor.Create(Self);
FMonitor.OnReaderAdded := ReaderAdded;
FMonitor.OnReaderRemoved := ReaderRemoved;
FMonitor.OnCardInserted := CardInserted;
FMonitor.OnCardRemoved := CardRemoved;
FMonitor.OnError := MonitorError;
FMonitor.Start;
```

Handlers voor readers ontvangen `const AReaderName: UnicodeString`; handlers voor
kaarten ontvangen `const ASnapshot: TPcscReaderSnapshot`, inclusief `ReaderName`,
ruwe status en een onafhankelijk ATR-buffer. `OnError` ontvangt de oorspronkelijke
unsigned PC/SC-status of `PcscInternalError` bij een ongeldig backendresultaat/volle queue.

Voor één geselecteerde reader kan ook de bestaande `TSmartCardReader` worden gebruikt:

```pascal
FReader.ReaderName := SelectedReader;
FReader.OnReaderAdded := ReaderAdded;
FReader.OnReaderRemoved := ReaderRemoved;
FReader.OnCardInserted := CardInserted;
FReader.OnCardRemoved := CardRemoved;
FReader.OnMonitorError := MonitorError;
FReader.StartEventMonitoring;
```

Reader-events omvatten de volledige inventory; kaart-/state-events gelden alleen voor
`ReaderName`. `OnCardStateChange` wordt in deze modus automatisch afgeleverd.
`StopMonitoring` stopt zowel automatische als handmatige observatie.
De oudere `StartMonitoring`/`PollChanges`-modus blijft bestaan, maar vereist expliciete
polling. Beide modi kunnen niet tegelijk actief zijn. Connecties en transacties blijven
onafhankelijk: een event verbindt, herverbindt of leest de kaart niet automatisch.

## USB-HID en RFID

`THidDeviceMonitor` registreert de Windows HID-interfaceklasse via
`RegisterDeviceNotificationW` en een eigen verborgen window. Geen VID/PID-lijst of
periodieke enumeratie is nodig. Start meldt alleen nieuwe gebeurtenissen; de bestaande
inventory vraag je eenmaal op met `EnumerateWindowsHidDevices`. Een apparaat kan
meerdere HID-collecties hebben en dus meerdere interface-events geven. Native
hotplug-notificaties vereisen Delphi op Windows; de injecteerbare adapter is ook getest
zonder Windows. Metadata worden niet verzonnen uit alleen een interfacepad.

Voor doorlopende read-only input:

```pascal
FInput := TUsbHidInputMonitor.Create(Self);
FInput.Device := CreateWindowsHidReportDevice(SelectedPath);
FInput.OnInputReport := InputReport;
FInput.OnError := InputError;
FInput.Start;
```

De worker opent de expliciet gekozen collectie één keer, leest complete interruptreports
met een eindige wachttijd en sluit bij stoppen/falen. Reports bevatten de Windows-ID-byte;
ze worden niet op een willekeurig ID gefilterd of als een kaartprotocol geïnterpreteerd.
Alleen `EHidReceiveTimeout` na voltooide annulering is een normale vervolg-wachttoestand.
Andere fouten stoppen de listener, sluiten de device en leveren één gesaniteerd `OnError`.
Er worden geen output-/featurecommando's gestuurd of automatisch herhaald.

Een handler kan `TRfidHidReportReader.FeedReport(AReport, GetTickCount64)` aanroepen
als de reports bij zijn expliciete decoderprofiel passen. De decoder meldt complete
identifiers via `OnIdentifier`. Voor keyboard-wedge readers blijft
`TRfidKeyboardReader.FeedCharacter` plus `OnIdentifier` bruikbaar. Windows kan
keyboard-collecties exclusief bezetten; native reporttoegang is dan niet beschikbaar.

Een HID-apparaat verwijderen is geen fysieke kaartverwijdering. Gewone keyboard-/ID-
readers leveren vaak alleen de gelezen ID; daaruit volgt geen aanwezigheidssensor.
Kaartverwijdering kan alleen met een readerprotocol dat die informatie werkelijk geeft.
PC/SC biedt kaart-events als de betreffende driver die toestand rapporteert.

## Aflevering en levenscyclus

PC/SC- en inputreport-workers leveren hun events met `TThread.Queue` op de hoofdthread.
Een VCL-message-loop verzorgt dat automatisch. Console-/servicehosts gebruiken de
standaard RTL-dispatcher `CheckSynchronize`; er is geen eigen readerpolling nodig.
HID-hotplug-events komen rechtstreeks via het owner-thread-window.

`Stop` is herhaalbaar: eerst worden pending callbacks ongeldig gemaakt, daarna wordt
het wachten gestopt, de worker gejoined en zijn context/device vrijgegeven. Een handler
mag de monitor stoppen of vrijgeven; overige events uit dezelfde batch worden dan
weggegooid. Terminale workerfouten stoppen vóór het error-event. Herstarten is een
expliciete applicatiekeuze. De queues bewaren maximaal 1024 meldingen; een volle queue
wordt een terminale fout, zonder onbegrensd geheugen of stil verlies van gebeurtenissen.
Eventhandler-exceptions worden niet verborgen; behandel fouten in je eigen handlers.

Waarnemingen volgen de driver: zeer korte tussenliggende overgangen kunnen ontbreken.
Gebruik kaart-events om werk te starten, maar voer blokkerende kaartoperaties in een
worker uit. Alleen PC/SC en HID worden hier gemonitord; willekeurige COM-readers krijgen
geen verzonnen kaartaanbiedingsprotocol.

ReaderToolsDemo en UsbHidDemo hebben elk eigen DFM-knoppen en een apart eventlog.
ReaderToolsDemo werkt zijn readerkeuze bij via hotplug-events; UsbHidDemo ververst
metadata na een hotplugmelding zodra zijn eventuele operatie/inputlistener is gestopt.
Geen van beide verbindt of schrijft automatisch bij een event.
