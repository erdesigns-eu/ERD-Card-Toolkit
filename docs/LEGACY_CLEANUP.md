# Legacy cleanup

The project now has library sources in `src`, runtime packages in `packages`,
console examples in `examples`, tests in `tests` and validation scripts in `tools`.

Removed from the working tree:

- `CardStudio/`: the obsolete executable project, forms, resources, build outputs,
  bundled binaries, database/storage code and Java/GlobalPlatform application work.
- The seven embedded BIN datasets and the BIN database/filter application. These
  are not necessary for card syntax or reads; any future issuer catalog is an
  optional provider with its own data provenance and update policy.
- `Filter + Array Maker/`, `KeyGen/`, `KeyGen.exe` and application artwork in `Images/`.
- `lockbox2-master/`: unused vendored crypto package, examples and build projects.
  The new core does not depend on LockBox. Future authentication/signature work
  must select and validate a maintained provider before introducing a dependency.
- Unrelated icon, playlist, translation and application-layout tools and baselines.

Before removal, 26 useful source/reference files were copied without modification
to [the reference directory](../reference/legacy/README.md) and verified by SHA-256.
These retain protocol examples, SDK declarations, tag/status descriptions and the
ATR catalog needed to investigate future components. Their original headers remain.
They are excluded from runtime packages and source validation of the new library.

Nothing has been removed from Git history. The complete original application is
available at commit `01faaefae9a3938817ddcae5761736952c3aa877`. To inspect an original file:

```sh
git show 01faaefae9a3938817ddcae5761736952c3aa877:CardStudio/untPCSC.pas
```

New core units require only the RTL. Vendor DLLs, drivers, issuer catalogs and
cryptographic packages are not part of their dependencies.
