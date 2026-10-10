# GlobalPlatform and JavaCard management

`TGlobalPlatformCardManager` is an inactive nonvisual component in
`ERDCardGlobalPlatform`, registered on **ERD Cards**. Its protocol engine is Delphi
code over `ICardTransport`. Windows applications can use the existing PC/SC and
CNG adapters: no GlobalPlatform DLL, Java process or external crypto DLL is needed.
Linux validation uses the optional maintained OpenSSL backend.

## Implemented scope

| Area | Included |
| --- | --- |
| Selection | Explicit security-domain AID; authenticated operations reselect inside the owned exclusive transaction |
| Information | CPLC with eighteen raw fields; dates retain their encoded value without a guessed decade |
| Registry | Issuer domain, applications/security domains, executable load files and modules; explicit tagged E3 or legacy format, bounded 6310 continuation |
| SCP02 | Explicit i=15, sixteen-byte already diversified ENC/MAC keys, random eight-byte host challenge, session derivation, card/host cryptograms, C-MAC and optional C-ENC |
| SCP03 | AES-128; explicit S8 or S16; random or independently verified pseudo-random card challenges; C-MAC, optional C-ENC, advertised R-MAC/R-ENC capabilities |
| CAP | CAP 2.1/2.2/2.3 framing, required/duplicate components, directory sizes/counts, package/applet AIDs and canonical load ordering; C4-prefixed image |
| Loading | Explicit INSTALL for load, at most 256 numbered short LOAD blocks, final-block flag, progress after each acknowledged block |
| Installation | Explicit INSTALL for install and make selectable, known CAP module, new instance AID, supplied privileges and C9 application parameters |
| Management | Explicit DELETE/delete-related flag, SET STATUS, make-selectable and extradition |
| Keys | E0/C0 metadata; add/replace one symmetric key or ENC/MAC/DEK set, delete an exact version/identifier, provision a legacy RSA verification public key |
| Key protection | SCP02 derived S-DEK with ECB key wrapping; SCP03 static DEK with AES-CBC; protocol-specific three-byte KCVs, including AES 01 input; returned version/KCVs checked |
| Delegation | RSA PKCS#1 SHA-1 legacy issuer tokens and GP 2.3.1 AES-CMAC tokens on INSTALL/load/install/selectable/extradition and DELETE |
| DAP | DES retail-MAC, AES-CMAC and legacy RSA hash-of-hash signing/verification; canonical E2/4F/C3 blocks prepended before C4 |
| Receipts | DES retail-MAC and AES-CMAC, explicit operation AIDs, expected card unique data and strictly increasing confirmation counter |
| Results | Structured status exceptions; last confirmation; configured receipt policy requires cryptographic verification |

Registry entries retain unfamiliar TLVs in their canonical complete encoding.
Load-file/module and domain identities are not replaced by guesses or automatically
selected. An absent registry category (6A88) is empty; other failures are explicit.
Read-only metadata uses bounded GET RESPONSE for 61xx. Neither 6Cxx nor failed
commands are retried. GET STATUS continuation changes the explicit continuation
parameter, rather than repeating a state-changing command.

## Lifetime and credentials

Provide a connected **basic-channel** transport supporting `ICardTransaction`.
The component is not thread-safe: open, use and close on the same thread. Public
reads acquire one transaction for their complete operation. Authentication holds
one transaction until `CloseSession`, protecting domain selection and MAC state.
Close the manager session before disconnecting the reader.

Static ENC/MAC/DEK keys are supplied by the application and must already be diversified for
this card. DEK is optional for authentication, but mandatory for symmetric PUT KEY. Key version/identifier and protection are explicit. The manager never
tries default keys or weaker protection. The host challenge comes from the
provider CSPRNG. Owned session material and intermediate buffers are cleared on
success/failure; caller keys and returned buffers remain caller responsibilities.
Transport, cryptographic or protected-response failures invalidate the channel and
release the transaction. A normal card error status can be returned without
pretending that an unauthenticated SCP03 error response has a verified R-MAC.

```pascal
Reader := TSmartCardReader.Create(nil);
Manager := TGlobalPlatformCardManager.Create(nil);
try
  Reader.ReaderName := SelectedReaderName;
  Reader.Connect;
  Manager.Transport := Reader.Transport;
  Manager.DesProvider := TCardWindowsAesProvider.Create;
  Manager.AesProvider := Manager.DesProvider;
  Selected := Manager.SelectSecurityDomain(SecurityDomainAid);
  if Selected.StatusWord <> $9000 then
    raise EGpCardError.CreateStatus(Selected.StatusWord);
  // Keys.Enc and Keys.Mac are supplied by the application, never defaulted here.
  Manager.Authenticate(gspScp03, Keys, KeyVersion, 0, gslEncryptedResponseMac);
  Entries := Manager.GetStatus(grkApplications, True);
finally
  Manager.Free; // releases the session before reader destruction
  Reader.Free;
end;
```

`OnLoadProgress` runs on the initiating thread, after acknowledgement. UI callers
must marshal their own updates. A callback exception stops the workflow; it never
causes a block to be resent. Card status exceptions expose `StatusWord`, zero for
local failures, and contain no keys, cryptograms or APDU payloads.

## CAP files and management

`TGpCapFile.FromFile` uses Delphi `System.Zip`, checks archive and advertised
uncompressed sizes, reads bounded component streams with CRC checking enabled,
rejects encrypted/ambiguous packages, checks component names
against tags and then runs the same component validation as `FromComponents`.
The latter is portable and accepts explicit binary components, each including its
three-byte header. Descriptor/debug components are validated structurally but are
not included in the load image. Custom directory components are currently refused.
JavaCard class/method bytecode verification remains the card's responsibility;
structural validation does not certify that an applet will execute correctly.

Loading and installing are **separate calls**. `LoadCap` preflights the image,
domain, block size and numbering capacity before INSTALL for load. `InstallApplet`
requires a module listed in Applet.cap. It does not implicitly load the package,
remove an existing instance or install every applet in a CAP. After a partial
failure, inspect registry state before deciding what to do next. No automatic
rollback, deletion, reset or retry occurs.

Confirmations are retained in `LastConfirmation`. With `ReceiptVerifier` configured,
final LOAD and supported INSTALL/DELETE operations require an authenticated receipt.
An absent, corrupt, identity-mismatched or replayed receipt fails the operation and
closes the secure channel. Without a receipt policy, framing is checked and the raw
confirmation remains available without an authenticity claim. Both an empty
response used by some cards and a standard zero-length confirmation byte are
accepted. Management status 9000 is acknowledgement, not independent read-back or
a claim that applet business behavior was validated.

## Key management and delegated operations

Supply `Keys.Dek` during authentication before `PutKey` or `PutKeySet`. ENC/MAC
are still required. PUT KEY always encrypts key material through the session DEK,
including command-MAC-only sessions. New keys are borrowed, never modified or
logged. After a submitted PUT KEY or key deletion, the manager closes its old
session on both success and failure; a new session must use the provisioned keys.
A timeout is not evidence that replacement failed. No command is retried.

```pascal
// Both supplied records must contain explicit ENC/MAC/DEK material.
Manager.Authenticate(gspScp03, CurrentKeys, CurrentVersion, 0, gslFull);
Manager.PutKeySet(CurrentVersion, NewVersion, FirstKeyId, NewKeys, True);
// Manager.Authenticated is now false; each returned KCV was checked.
```

Issuer token keys, receipt keys and DAP keys are separate from secure-channel
keys. RSA signing uses `TCardNativeRsaProvider` with unsigned big-endian modulus,
public exponent and private components. Windows CNG imports N/E/P/Q and derives
private RSA values; Linux OpenSSL requires D (P/Q may also be supplied). For an
HSM, implement `ICardRsaProvider` and retain it in `TGpRsaTokenSigner`.

```pascal
Manager.TokenSigner := TGpAesTokenSigner.Create(Aes, IssuerTokenKey);
Receipt := TGpReceiptVerifier.CreateAes(Aes, ReceiptKey, ExpectedCardUniqueData, LastCounter);
Manager.ReceiptVerifier := Receipt; // retained interface keeps the object alive
LoadHash := Hash.Sha1(Cap.LoadFileData); // explicit legacy SHA-1 load profile
DapSignature := TGpManagementCrypto.RsaDap(Hash, RsaSigner, Cap.LoadFileData);
Dap := TGpManagementCrypto.DapBlock(DapDomainAid, DapSignature);
Manager.LoadCap(Cap, TargetDomainAid, 220, nil, LoadHash, Dap);
// Persist Receipt.LastCounter with its card identity after verified receipts,
// including a receipt accepted before a later operation failed.
```

`SymmetricDap` accepts an explicitly selected hash and DES/AES DAP key; `RsaDap`
implements the legacy specification's SHA-1 hash-of-hash signature. LOAD hash
excludes C4/BER framing and all DAP blocks. The manager validates DAP framing before
INSTALL and requires a load hash for delegated loading. Token signing covers
P1/P2/Lc and token-free data, before secure messaging. DELETE appends a 9E TLV;
INSTALL appends a token LV. Signers can also be provisioned externally through
`ICardGpTokenSigner` with an explicit per-command policy.

Receipts authenticate ordered context: load = package/domain, install =
package/instance, delete = object, extradition = old domain/object/new domain.
`MakeSelectable` needs its owning package AID when a receipt policy is configured.
Expected card identity is supplied in advance, never trusted from an unverified
receipt. Counters advance only after valid verification and must be persisted by
the application for protection across sessions. A policy is never downgraded to
accept a missing receipt. Card issuer privileges and actual provisioned keys
determine whether a card accepts the operation.

## Protocol profiles

No SCP01/SCP11, other SCP02 implementation options, SCP02 response MAC,
AES-192/256 or automatic key diversification. Issuer credentials are explicitly
provisioned by the caller. Legacy RSA management uses PKCS#1 v1.5/SHA-1 and a
1024-bit signature/public key; modern RSA-PSS/ECDSA issuer profiles and long
management command chaining still require separate implementations. These are
protocol additions, not replacements for the implemented key/delegation flows. SCP03 i options 00/20/60 and 10/30/70,
plus their S16 forms, are explicit; unsupported/reserved options fail. Short LOAD
numbering currently limits one image to 256 blocks of at most 220 clear bytes.
No general ATR rewriting command exists; programmable-card firmware protocols are
separate from GlobalPlatform loading. Recording/replay remains deferred.

## Demo and validation

`examples/vcl/globalplatform/GlobalPlatformDemo.dproj` owns its own form and DFM.
It discovers readers through native events and captures one background request
per click. Each action selects/authenticates and closes its own session. Key
inputs are masked and copied into the existing worker's cleared credential
buffers. Authentication/management requires per-action acknowledgement. LOAD
progress is collected by the worker and displayed with its completed result;
reader/card presence remains event-driven. No live form controls are accessed
from the worker. Close is deferred while an operation owns the card.

Committed independent Python/cryptography transcripts cover **154 sessions and
1,232 protected exchanges**, including all supported command/response protection
levels, S8/S16, random/pseudo-random challenges, empty/aligned messages and complete
manager-level load/install/delete/status sequences. Pascal tests also cover wrong
cryptograms/RNG lengths, absent/corrupt R-MAC, transport failures, structural CAP
errors, partial-load progress and no retries. Further independent vectors cover
ten key wrapping/update sessions and six complete delegated-management sessions,
including RSA/AES tokens, RSA DAP, final LOAD/INSTALL/extradition/delete receipts,
wrong KCVs, receipt corruption at every byte and replay/counter rejection. Windows CNG adapter code runs through
the existing Linux ABI shim. ZIP archive import is a Delphi RTL path; the portable
suite exercises `FromComponents`, not Delphi `System.Zip` or VCL execution.

Reference protocols: GlobalPlatform Card Specification 2.1.1 Appendices B/C/E and card
management sections; GP 2.3.1 AES token/receipt profiles; SCP03 Amendment D v1.1.1/v1.2 (S16); JavaCard CAP format.
See the [GlobalPlatform specification library](https://globalplatform.org/specs-library/)
and [Oracle JavaCard documentation](https://docs.oracle.com/en/java/javacard/).
The implementation is independent; no GlobalPlatformPro/CardPeek source was
imported or linked.
