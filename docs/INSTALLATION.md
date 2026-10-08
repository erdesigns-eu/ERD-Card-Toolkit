# Installing the Delphi components

The library supplies eight runtime packages, one design-time palette package and
source-linked VCL examples. The intended target is Delphi 10.4 or later on Windows,
Win32 and Win64. The maintainer reports successful package builds and IDE
installation in RAD Studio 12 (Studio 23.0), Debug/Win32, after the project repair.
The compiler-warning follow-up still needs a fresh Delphi rebuild; other Delphi
versions, configurations and architectures remain unverified. Linux source readers
and FPC execution do not establish Delphi compatibility.

## Use source directly

Add the required `src` directories to your application's unit search path. The
core, PC/SC, eID, EMV, magstripe and contactless units have no VCL dependency.
Cryptographic providers are optional: Windows CNG supplies DESFire AES;
`ERD.Card.Crypto.EAC.OpenSSL` supplies ICAO BAC/PACE through an externally installed
OpenSSL 3 library. The library is not bundled; its architecture must match the
application. Consult [EUROPEAN_EID.md](EUROPEAN_EID.md) for supported access profiles.

## Build runtime packages

Open `packages/ERDCards.groupproj` in RAD Studio. It builds Core, CryptoWindows,
CryptoOpenSSL, PCSC, EID, EMV, MagStripe and Contactless, followed by the design
package. The order keeps dependencies before their consumers. Either cryptographic
provider can be omitted when building packages individually and it is not needed.
Each package owns its units exactly once.
No runtime package requires `vcl`, `designide` or the registration package.

Alternatively, from the matching RAD Studio command prompt:

```bat
tools\build-packages.cmd dcc32
tools\build-packages.cmd dcc64
```

These commands invoke MSBuild on the matching `.dproj` for a full Debug build,
including project resource generation, XML documentation, range and overflow checks. IDE/MSBuild projects also provide a Release configuration with checks
retained. For example:

```bat
msbuild packages\ERDCards.groupproj /t:Build /p:Config=Release /p:Platform=Win64
```

The project-group command also builds the design package. Use the batch script
without `design` when only runtime packages are required.

BPL/DCP outputs are isolated in `dist/packages/<Platform>/<Config>`; DCUs are
further separated by package. Do not mix compiler versions, configurations or
architectures. Rebuild the entire set after switching the Delphi version.

## Install the palette

First determine the architecture of the **IDE process**. It can differ from your
application target: use the IDE-compatible compiler for the registration BPL.
Build the project group for that architecture and configuration, or explicitly
request the runtime packages plus the design package through the script:

```bat
tools\build-packages.cmd dcc32 design
```

Use `dcc64 design` only when your installed IDE uses matching Win64 design-time
packages. The script compiles; it does not install anything automatically.
Make the six required runtime BPLs available to the IDE's DLL loader, for example
by adding their output directory to PATH before launching RAD Studio. Then use
**Component > Install Packages > Add** to select `ERDCardDesign.bpl`.
Add the matching DCP/DCU directories or source directories to the IDE library path
for projects that use installed components. Never add `tests/design` to this path:
its `DesignIntf` unit is a headless FPC test shim.

The `ERD Cards` palette contains `TSmartCardReader`, `TBelgianEIDReader`,
`TICAODocumentReader`, `TEMVCardReader` and `TMagStripeReaderWriter`.
`ERD Contactless` contains `TContactlessCardReader`, `TType2NdefCardReader`,
`TType4NdefCardReader`, `TIso15693CardReader`, `TType5NdefCardReader`,
`TDesfireCardReader`, `TType2PasswordCardReader` and `TRawUidProgrammer`.
Default IDE component icons are used. The optional cryptographic backends are
interface providers rather than palette components, so the design package does
not depend on or load them.

The design package must retain its six `ERDCard*` entries in `requires` and the
matching DCP references in the IDE project. Removing them causes Delphi W1033
implicit imports and recompiles runtime component classes into the design BPL.
After changing these dependencies, close the IDE, rebuild the complete set for
its architecture/configuration, and load the rebuilt design BPL. Avoid mixing
older copies with the rebuilt packages.

Constructors, registration and streaming do not connect to cards. Published scalar
configuration is persisted in DFM files. Interface properties such as `Transport`,
`Profile`, `Device` and `CryptoProvider` must be supplied at runtime; the IDE cannot
stream interface implementations. Create and use hardware components on their
owning thread, connect explicitly, and release them on that same thread. A component
dropped on a form is not made thread-safe by its presence on the palette.

If you use runtime packages in a deployed application, enable its matching runtime
package list and deploy those BPLs plus their transitive dependencies. The supplied
VCL demos link source statically and do not need palette installation or ERD BPLs.
See [VCL_DEMOS.md](VCL_DEMOS.md) for building and smoke testing them.

## Retesting the reported IDE package crash

The supplied `Delphi Packages/Core.dproj` and `.dpk` are the native-format reference;
they remain unchanged. The user confirmed that this native Core project builds
successfully in Delphi. The shipped projects now follow that configuration model:
Explicit IDE `Borland.ProjectType=Package`, Base/Debug/Release inheritance,
Win32/Win64 activation nodes, package generation,
project names, named DCP dependencies and numeric debug-information settings.
`DCC_IntegerOverflowCheck` replaces the incorrect `DCC_OverflowChecking` property.
Project/package files use UTF-8 with BOM and CRLF, matching the reference. They
already used CRLF before this repair; line endings alone do not explain the crash.
The project format version follows the supplied reference (20.2); earlier IDE
versions remain unverified.

The package and VCL sources now reference their standard generated `.res`. Use
IDE/MSBuild builds rather than compiling these `.dpk`/VCL `.dpr` files directly
with DCC before resources have been generated. The build scripts use that same
project pipeline. Console test builds still use DCC directly.

For a focused retest, close the old project group, reopen the updated project,
and build only `packages/runtime/ERDCardCore.dproj` as Debug/Win32 first. Old
outputs under `dist/packages` can be removed before rebuilding; this does not
require changing source files. From a matching RAD Studio command prompt:

```bat
msbuild packages\runtime\ERDCardCore.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /p:DCC_BuildAllUnits=true /nologo /v:normal
```

Then build the full runtime group, the design package for the IDE architecture,
and the VCL examples. The `Core` reference package and `ERDCardCore` contain the
same units; use the shipped ERD package set for installation.

The reported access violation is inside `delphicoreide290.bpl`. These corrections
address verified project defects, but the Linux checks cannot confirm that the
IDE crash is resolved. If it persists, compare building the user's native `Core`
reference and the shipped `ERDCardCore` project, and compare IDE versus command-line
MSBuild output. An IDE-only failure and an emitted compiler error require different
follow-up diagnosis; keep the first actual error from the build output.
