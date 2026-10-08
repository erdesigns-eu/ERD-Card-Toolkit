# Delphi-problemen in dit project

## Packages veroorzaakten een IDE-crash

De gegenereerde packages gaven bij compilatie een access violation in
`delphicoreide290.bpl`. Een door Delphi zelf aangemaakt `Core.dproj` compileerde
wel. De gegenereerde projecten hadden afwijkende projectmetadata, waaronder een
lege `Borland.ProjectType` en onvolledige configuratie-instellingen.

De projecten zijn aangepast aan het werkende Delphi-voorbeeld, inclusief
`Borland.ProjectType = Package`, compilerinstellingen en package-resources.
Ook zijn BOM en CRLF afgestemd op het voorbeeld. De oorspronkelijke bestanden
hadden al CRLF: alleen de regeleinden waren dus geen verklaring. Omdat meerdere
instellingen tegelijk zijn aangepast, is niet bewezen welke afzonderlijke
instelling de crash veroorzaakte. Daarna bevestigde de gebruiker dat de packages
compileerden en geïnstalleerd konden worden.

## Compilerwarnings

Er waren onder andere warnings door typeconversies, overbodige toekenningen en
functiepadgevallen zonder expliciet resultaat of exception. De betreffende code
is aangepast; noodzakelijke functieaanroepen zijn behouden. De gebruiker
bevestigde daarna dat Delphi zonder warnings compileerde.

## Beide VCL-demo’s startten hun thread te vroeg

De fout was `EThread: Cannot call Start on a running or suspended thread`.
`TCardDemoJob` riep `Start` aan vanuit zijn constructor, voordat Delphi
`AfterConstruction` had afgerond.

De constructor maakt nu alleen de gesuspendeerde thread aan. De form roept
`StartWork` aan nadat `Create` teruggekeerd is. Beide demo’s gebruiken dezelfde
oplossing. Dit is gemerged in PR #27; werking in Delphi is nog niet door de
gebruiker bevestigd.

## Installatie van het designpackage

De gebruiker heeft de runtime-package-dependencies bewust verwijderd omdat het
designpackage anders niet wilde installeren. De exacte oorzaak van die
installatiefout is niet vastgesteld. Zonder dependencies konden impliciet
meegenomen units W1033-warnings opleveren.

In PR #28 bevat het designpackage daarom alle benodigde bronunits expliciet en
vereist het alleen `rtl`, `vcl` en `designide`. Deze zelfstandige bronbundel hoeft
de ERD-runtime-BPL’s niet te laden. Installatie van deze nieuwe variant in Delphi
moet nog worden getest; het is nog geen bevestigde oplossing voor de eerdere
installatiefout.
