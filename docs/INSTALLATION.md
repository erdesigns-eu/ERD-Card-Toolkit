# Installing the Delphi components

The library supplies eight runtime packages, one design-time palette package and
source-linked VCL examples. The intended target is Delphi 10.4 or later on Windows,
Win32 and Win64. Actual Delphi builds and IDE installation are still pending:
Linux source readers and FPC execution do not establish Delphi compatibility.

## Use source directly

Add the required `src` directories to your application's unit search path. The
core, PC/SC, eID, EMV, magstripe and contactless units have no VCL dependency.
Cryptographic providers are optional: Windows CNG supplies DESFire AES;
`ERD.Card.Crypto.EAC.OpenSSL` supplies ICAO BAC/PACE through an externally installed
OpenSSL 3 library. The library is not bundled; its architecture must match the
application. Consult [EUROPEAN_EID.md](EUROPEAN_EID.md) for supported access profiles.

## Build runtime packages

Open `packages/ERDCards.groupproj` in RAD Studio and build in the listed order:
Core, MagStripe, PCSC, EID, EMV, Contactless, CryptoWindows, CryptoOpenSSL.
The first six cover non-cryptographic components; either cryptographic provider
can be omitted when it is not needed. Each package owns its units exactly once.
No runtime package requires `vcl`, `designide` or the registration package.

Alternatively, from the matching RAD Studio command prompt:

```bat
tools\build-packages.cmd dcc32
tools\build-packages.cmd dcc64
```

These commands perform Debug builds with XML documentation, range and overflow
checks. IDE/MSBuild projects also provide a Release configuration with checks
retained. For example:

```bat
msbuild packages\ERDCards.groupproj /t:Build /p:Config=Release /p:Platform=Win64
```

BPL/DCP outputs are isolated in `dist/packages/<Platform>/<Config>`; DCUs are
further separated by package. Do not mix compiler versions, configurations or
architectures. Rebuild the entire set after switching the Delphi version.

## Install the palette

First determine the architecture of the **IDE process**. It can differ from your
application target: use the IDE-compatible compiler for the registration BPL.
Build the runtime group for that architecture and configuration, then build
`packages/design/ERDCardDesign.dproj`, or explicitly request the design package:

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
