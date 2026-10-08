# Overdracht: Delphi-packages en VCL-threadproblemen

Gebruik dit document als opdracht/context voor een agent die vergelijkbare
Delphi-projecten buiten Windows heeft gegenereerd. Onderzoek het eigen project;
kopieer oplossingen niet blind. Haal eerst de laatste gebruikerswijzigingen op
en behoud werkende, door Delphi opgeslagen projectbestanden.

## Bevestigde situatie in dit project

- RAD Studio 12 / Studio 23.0, Debug/Win32.
- Gegenereerde packages crashten met een access violation in
  `delphicoreide290.bpl`, lezen van adres nul.
- Een door de gebruiker zelf in Delphi aangemaakt `Core.dproj` + `Core.dpk`
  compileerde wel. Dat was het referentieproject.
- Na correctie van projectmetadata/resources/encoding bevestigde de gebruiker
  dat de packages compileerden en installeerden.
- Na afzonderlijke broncodecorrecties bevestigde de gebruiker een warningvrije
  package-build.
- Beide VCL-demo's kregen daarna EThread: **Cannot call Start on a running or
  suspended thread**. De stack liep via `TThread.InternalStart` en
  `TThread.AfterConstruction`. De gedeelde fix is gemerged; een succesvolle
  Delphi-runtimehertest daarvan is nog niet bevestigd.

## 1. Vergelijk met een native IDE-project

Vraag bij een IDE-crash om een minimale, door dezelfde Delphi-versie gemaakte
package en controleer of die wel bouwt. Vergelijk daarna:

- `Borland.ProjectType`: packages moeten `Package` bevatten. In onze gegenereerde
  bestanden was dit leeg; dat was een concrete metadatafout.
- `MainSource`, `ProjectName`, `SanitizedProjectName`, unieke project-GUID en
  `AppType`, plus `GenDll=true` en `GenPackage=true` voor packages.
- Base/Debug/Release-configuraties, hun keys en parents, plus daadwerkelijke
  Win32/Win64-overerving. Controleer effectieve properties voor alle combinaties.
  De IDE kan lege platformgroepen verwijderen; dat is niet automatisch een fout.
- Native compilerproperties: **DCC_IntegerOverflowCheck**, niet de verzonnen
  `DCC_OverflowChecking`. `DCC_DebugInformation` gebruikt numerieke waarden;
  in ons native voorbeeld is Release `0`, geen boolean `false`.
- Named DCP-references moeten overeenkomen met `requires`. Bronreferences moeten
  overeenkomen met `contains` en echte relatieve bestanden.
- Native `CodeGear.Delphi.Targets`-import, framework/personality en resources.
  Houd output voor platform/configuratie/compiler-versie gescheiden.

Volg de projectversie van het concrete IDE-voorbeeld. Kopieer geen onnodige
mobile deploymentblokken of gebruikersspecifieke absolute paden. Claim geen
compatibiliteit met oudere Delphi-versies op basis van een XML-lezer.

## 2. Encoding en resourcegeneratie

Ons native IDE-voorbeeld gebruikte UTF-8 **met BOM** en **CRLF**. We hebben deze
formattering voor `.dproj`, `.dpk`, `.groupproj` en VCL `.dpr` behouden/gebruikt.
De eerdere gegenereerde bestanden hadden al CRLF: de crash was niet bewezen
uitsluitend door line endings veroorzaakt. Normale ASCII `.pas`-bestanden hoeven
niet voor dit probleem massaal herschreven te worden.

Bij schrijven vanuit Python: decodeer bestaande BOM met `utf-8-sig`; schrijf
bewust BOM + UTF-8 + CRLF en voorkom dubbele CR's. Git kan CRLF normaliseren naar
LF in de index; controleer de werkelijke Windows/worktree-bytes, niet alleen de
diff. Bewaar formatting met passende `.gitattributes`.

Packages en VCL-applicaties gebruiken `{$R *.res}`. Laat IDE/MSBuild die resource
maken voordat DCC compileert. Een rechtstreekse DCC-call vóór resourcegeneratie is
geen equivalente projectbuild. Bijvoorbeeld, vanuit een RAD Studio prompt:

```bat
msbuild packages\runtime\ERDCardCore.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /p:DCC_BuildAllUnits=true /nologo /v:normal
```

Gebruik dit pad alleen als het in het eigen project bestaat. Bouw eerst een kleine
core-package, daarna consumers en het designpackage in dependencyvolgorde.

## 3. Designpackage: kies één consistente eigendomsstrategie

Een designpackage dat runtime-BPL's gebruikt, moet die packages in `requires`
hebben. Hun units horen dan niet ook in zijn `contains`. Matching BPL's moeten
vindbaar zijn voor de IDE-loader en dezelfde compiler/architectuur/configuratie
gebruiken. De IDE-architectuur kan afwijken van het applicatietarget. Bewaar de
volledige installatiefout en de naam van de ontbrekende/conflicterende package;
een onvolledige melding bewijst geen specifieke oorzaak.

Het weglaten van runtime-dependencies terwijl registratie hun sources gebruikt
kan **W1033 implicit imports** geven: Delphi compileert die units dan opnieuw in
het designpackage. Onze gebruiker liet deze dependencies bewust weg omdat de
installatie met dependencies mislukte. Zet ze niet zonder afstemming terug.

Een alternatief is een **zelfstandig design-sourcebundle**: `{$DESIGNONLY}`, alleen
SDK-dependencies (`rtl`, `vcl`, `designide`), en alle benodigde registratie-/runtime-
units expliciet in `contains` plus projectreferences. De losse runtimepackages
blijven dan voor applicaties beschikbaar. Combineer dat bundle niet met het laden
van runtime-BPL's die dezelfde units bevatten. Deze alternatiefopzet is een nieuwe
wijziging in dit project; Delphi-installatie ervan moet nog worden getest.

## 4. Start een Delphi-thread na constructie

Roep `TThread.Start` niet vanuit de constructor van een `TThread`-subclass aan.
In deze demo's botste dat met Delphi's latere `AfterConstruction`.

De oplossing gebruikt:

```pascal
// In de workerconstructor:
inherited Create(True);
FreeOnTerminate := False;
// Initialiseer locks, maak eigen bufferkopieën en bewaar de executor.
// Hier nog niet Start aanroepen.

// Vanuit de caller, nadat Create is teruggekeerd:
Job := TMyJob.Create(Request, Executor);
try
  Job.StartWork; // Eigen methode: bewaakt één start en roept inherited Start aan.
except
  FreeAndNil(Job);
  raise;
end;
```

Gebruik geen extra `Resume`/`Start`-calls om de fout te verbergen. Test uitvoering
op de worker, dubbele start, vernietiging vóór start, join, constructorfouten en
buffer-/resultaateigendom. De UI mag niet door de worker worden aangeraakt; herstel
UI-status bij startupfouten. Bij hardwarewrites betekent threadbeëindiging niet
dat kaartstaat bekend is.

## 5. Corrigeer warnings bij hun oorzaak

- W1021: een `Length > MaxInt`-check is zinloos op een 32-bit native lengte. Behoud
  de beveiliging conditioneel wanneer `SizeOf(NativeInt) > SizeOf(Integer)`.
- W1023: vergelijk passende types. Byte-tagsets en een expliciete bytecast van een
  booleaanse optie hielpen hier zonder betekenisverlies.
- W1036: een foutpad dat een helper aanroept die altijd raise't, wordt niet altijd
  door Delphi als terminatie herkend. Maak het raise-pad expliciet.
- H2077: verwijder dode assignments, maar behoud function calls met validatie of
  andere side effects. Zo bleef EMV-logvalidatie actief zonder ongebruikte return.
- W1033: herstel expliciete package-eigendom/dependencies of het bewuste sourcebundle.

Schakel warnings niet uit en verlaag geen range/overflow-checks om een build groen
te krijgen. Gebruik `///` XML-documentatie voor publieke Delphi API's.

## 6. Validatie en oplevering

Voer passende bronlezers en protocol/regressietests uit. In dit project zijn dat
`tools/check_distribution.py`, `tools/pascalcheck/run.py` en de FPC-testworkflow.
Ze vinden veel fouten, maar vervangen Delphi/Windows/IDE/hardware niet.

Vraag om een volledige Delphi **Build**, niet alleen een Make met oude DCU's.
Test beide VCL-demo's offline, readerenumeratie zonder kaart en sluiten tijdens
actief werk. Meld precies welke builds de gebruiker heeft bevestigd en welke
checks de agent zelf heeft uitgevoerd. Een Linux-test is geen geslaagde Delphi-
installatie of IDE Help Insight-test.
