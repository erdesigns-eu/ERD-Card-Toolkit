# Known Delphi issues and fixes

## Packages caused an IDE crash

The generated packages produced an access violation in `delphicoreide290.bpl`
during compilation. A `Core.dproj` created by Delphi itself did compile. The
generated projects had different project metadata, including an empty
`Borland.ProjectType` and incomplete configuration settings.

The projects were aligned with the working Delphi example, including
`Borland.ProjectType = Package`, compiler settings, and package resources. The
BOM and CRLF style were also aligned with the example. The original files already
had CRLF, so line endings alone were not an explanation. Because several settings
were changed at the same time, it is not proven which individual setting caused
the crash. Afterwards, the user confirmed that the packages compiled and could be
installed.

## Compiler warnings

There were warnings from, among other things, type conversions, redundant
assignments, and function paths without an explicit result or exception. The
relevant code was adjusted; necessary function calls were preserved. The user
then confirmed that Delphi compiled without warnings.

## Both VCL demos started their thread too early

The error was `EThread: Cannot call Start on a running or suspended thread`.
`TCardDemoJob` called `Start` from its constructor, before Delphi had completed
`AfterConstruction`.

The constructor now only creates the suspended thread. The form calls `StartWork`
after `Create` has returned. Both demos use the same fix. This was merged in PR
#27; operation in Delphi has not yet been confirmed by the user.

## Installing the design package

The user intentionally removed the runtime package dependencies because the
design package would otherwise not install. The exact cause of that installation
error has not been established. Without dependencies, implicitly included units
could produce W1033 warnings.

In PR #28, the design package therefore contains all required source units
explicitly and requires only `rtl`, `vcl`, and `designide`. This self-contained
source bundle does not have to load the ERD runtime BPLs. Installation of this
new variant in Delphi still needs to be tested; it is not yet a confirmed fix for
the earlier installation error.
