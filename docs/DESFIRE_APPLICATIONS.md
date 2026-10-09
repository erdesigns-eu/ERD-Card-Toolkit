# Native DESFire application and ordinary-file management

The existing public/AES and new ISO-3DES/legacy profiles can create/delete native
applications and all five ordinary file types. These are immediate management
operations, separate from backup/value/record staging. Commit and Abort do not
undo application/file creation or deletion.

## Explicit application storage type

The optional `IDesfireApplicationManagement` interface adds
`CreateApplicationWithKeyType`. Its IID is new; existing `IDesfireSession` and
`IDesfireManagement` identifiers and layouts are unchanged. Obtain it through
`Reader.OpenApplicationManagementSession(0)` or `Supports` on an existing native
management session.

| `TDesfireApplicationKeyType` | Native configuration type bits |
| --- | --- |
| `daktDesOrTwoKey3Des` | `00`, shared DES/2K3DES storage category |
| `daktThreeKey3Des` | `40`, 3K3DES |
| `daktAes` | `80`, AES |

Supply a separate key count **1–14** and explicit native policy byte. Do not pass
`129` (`81` hex) as a count. The API composes type and count bits itself. A policy
change-key selector must reference an existing supplied-count key or the native
special selector 14/15. AID must be nonzero, 24-bit and absent from the acquired
directory. Invalid local inputs produce no command and leave the session active.

Creation type is independent of the authentication profile of the PICC key.
Successful legacy authentication does not establish the card's physical generation
or which application storage types that chip supports. An unsupported native
command fails explicitly; there is no retry or type fallback.

```pascal
var
  Management: IDesfireApplicationManagement;
begin
  // Reader is already configured with a connected transaction-capable transport,
  // the explicit security profile, supplied authentication key and native provider.
  Management := Reader.OpenApplicationManagementSession(0);
  try
    Management.CreateApplicationWithKeyType($123456, $0B, 3,
      daktThreeKey3Des);
  finally
    Management.Close;
  end;
end;
```

Creation initializes the card's default credentials; this method does not provision
caller keys, rotate keys or choose default credentials for later authentication.
Verification establishes the new AID's directory presence. It does not claim fresh
authentication with a supplied new application key. Existing
`IDesfireSession.CreateApplication(Aid, Settings, Count)` retains its AES storage
behavior and delegates to the typed implementation.

## Operations and evidence

`ReadApplicationSettings`, `ReadFreeMemory` (PICC), `ReadKeyVersion`, application
create/delete and ordinary standard/backup/value/linear/cyclic file create/delete
use the selected native message dialect. File creation verifies acquired type,
geometry, rights and mode; file/application deletion verifies directory absence.
Policy and ownership checks remain mandatory. The legacy dialect's plaintext
metadata and acknowledgements have the integrity limits documented in
[LEGACY_MIFARE_SECURITY.md](LEGACY_MIFARE_SECURITY.md).

After mutation dispatch, failed response/integrity/readback remains uncertain and
no recovery command is generated. Once an individual immediate mutation is fully
verified, a later pre-mutation failure does not undo that verified operation.
A retained session owns its engine and credentials independently of its creating
component. Closing it emits no implicit commit, abort or formatting command.

DES/3DES key rotation, changes to existing application key type, key policy and
file access policy remain separate work. The existing AES mutation methods retain
their explicit AES guards. Extended ISO directories, application/file extensions,
SDM, TMAC, LRP and key-set administration are outside these APIs.

## VCL demo

DesfireDemo retains its own editable form and DFM. Application creation has
separate **key count** and **key-storage type** inputs; type has no preselection.
DES/3DES choices are available for native metadata and application/file
create-delete pages. AES key/access mutation pages retain the AES choices.
Reader inventory and card presence continue to arrive through native events.

Independent synthetic fixtures cover the four DES/3DES profiles, all three
file communication settings, all five ordinary file types and each application
storage type. Tests include exact complete commands, retained ownership, invalid
local counts and every I/O failure boundary. The existing AES tests still exercise
the unchanged AES creation call. Native providers, Help Insight, package source
closure and Delphi text formats use the same validation scripts as the rest of
the component set.
