# DESFire EV2/EV3 extended management and SDM

`TDesfireCardReader.OpenExtendedManagementSession(Aid)` exposes the optional
`IDesfireExtendedManagement` interface for explicit EV2 AES sessions. Existing
interfaces and IIDs remain unchanged. Supply the selected AID, valid key number,
owned AES key and maintained AES/CSPRNG provider as in [DESFIRE.md](DESFIRE.md).
This interface uses the retained session's existing exclusive ownership and
management acknowledgement policy.

## AES key sets

| API | Postcondition |
| --- | --- |
| `CreateApplicationWithKeySets` | Creates an AES application, checks exact acquired extended settings and restores PICC authentication |
| `ReadKeySetKeyVersion` | Authenticated acquired key version; version alone does not prove possession |
| `ReadKeySetVersionList` | Acquired native bytes, without inferred lifecycle flags |
| `InitializeAesKeySet` | Native initialization with protected acknowledgement |
| `ChangeInactiveAesKey` | Protected replacement using supplied old/new AES keys and checked resulting version |
| `FinalizeKeySet` | Native finalization/version with protected acknowledgement |
| `RollKeySetVerified` | One roll, then fresh active-key authentication and acquired version verification |

Application creation supplies key policy, 1–14 keys, native key-set count 2–16,
initial set version and roll-key selector. The component checks acquired settings,
set/key ranges and required key authority before dispatch. Inactive sets are
explicitly selected; old keys must be supplied rather than inferred after initialization.
Initialization, replacement and finalization require the application master key;
rolling requires the acquired configured roll key. The card enforces its native
lifecycle restrictions. There is no automatic initialization, roll or authentication retry.

The component copies key inputs before I/O and wipes its temporary buffers. The
caller remains responsible for clearing application-owned key arrays. A mutation
whose completion cannot be established poisons the session and retains uncertainty;
reopen and inspect state instead of repeating the operation. Protected acknowledgement
is distinguished from independent read-back in the API names and table above.

Combined ISO creation is available through `IDesfireIsoKeySetManagement`; it
verifies both the directory tuple and public key-set settings and restores PICC
authentication. See [ISO/TMAC profiles](DESFIRE_FILES_TMAC.md). Existing key-set
interfaces and their IIDs remain unchanged.

## Explicit configuration

`SetConfigurationAcknowledged(Option, Data)` validates and encrypts one supported
native configuration command and verifies its protected acknowledgement:

| Option | Validated input |
| --- | --- |
| $00 | One PICC configuration byte, supported low four bits |
| $02 | ATS with exact TL, supported FSCI and complete indicated interface bytes |
| $03 | Two SAK bytes |
| $04 | Two secure-messaging option bytes with supported reserved-bit policy |
| $09 | Fourteen-byte value-file configuration with checked signed bounds/value |

PICC options require PICC selection; $09 requires an application. All require key
zero. There is no general GetConfiguration command, so this API reports protected
acknowledgement rather than claiming independent read-back. Use only options
supported by the explicitly selected card generation. Other option layouts are refused.

## Secure Dynamic Messaging settings

`ReadSdmSettings(File)` acquires and strictly parses an existing standard-data
file's complete settings. `ChangeSdmSettingsVerified(File, ExpectedRaw, Desired)`
compares the frozen exact prior settings, sends one protected change and verifies
all resulting settings. File size and type must remain unchanged. Ordinary access
and SDM keys are validated against acquired application key count.

`TDesfireSdmSettings` preserves raw bytes and typed conditional fields: ordinary
access rights, SDM options/rights, UID/read-counter or encrypted PICC mirror,
MAC input/output offsets, encrypted-file region and optional counter limit.
`TDesfireExtensionCodec` encodes/decodes the native conditional layout and refuses
truncation, reserved flags, inconsistent permissions, overlapping output mirrors
and out-of-file regions. Binary/ASCII widths and suppressed counter offsets are
checked. SDM uses Plain file communication; management remains protected.

Offsets refer to the complete native file, including NLEN when that file carries
Type 4 NDEF. Supply an explicit template and matching offsets; the library does
not guess offsets from a URI. Provision/write the template before enabling dynamic
mirrors. This API changes settings only and does not write template data. It can
also disable SDM with verified ordinary settings.

This supports SDM on an existing compatible file. Native ISO application/FID creation is now available through [file management](DESFIRE_FILES_TMAC.md); automatic end-to-end phone-readable NDEF template provisioning remains separate.
Ordinary DESFire settings APIs still reject SDM layouts; select the extended API.

Combined SDM and additional access-right tuples are now available through
`IDesfireSdmAccessManagement`, with complete conditional framing and exact-preimage
change/read-back. See [combined settings](DESFIRE_FILES_TMAC.md). The original
SDM interface layout and codecs retain their strict ordinary-right profile.

## Offline SDM verification and decryption

`TDesfireSdmCrypto` provides:

- AES-128 encrypted PICC mirror decoding into UID and read counter, retaining the tag.
- MAC/encryption session-key derivation from the explicit UID/counter profile.
- Odd-index truncated CMAC calculation and verification over exact supplied bytes.
- Encrypted-file CBC decryption with the derived counter-dependent IV.

Callers must supply exact mirror bytes and MAC input boundaries, verify the MAC
before trusting/decrypting file content, and handle application freshness/counter
policy. Decryption preserves padding; use the declared data length. These helpers
do not authenticate a physical card or implement a server replay database.
Owned temporary keys/plaintext are cleared; returned buffers belong to the caller.

## Validation and remaining extensions

The new suite uses independently generated literal transcripts and published
[NXP AN12196](https://www.nxp.com/docs/en/application-note/AN12196.pdf) SDM vectors
for PICC data, session keys, MACs and encrypted content. Configuration validation
also follows [AN12343](https://www.nxp.com/docs/en/application-note/AN12343.pdf).
Key-set command layout was cross-checked against
[liblogicalaccess](https://github.com/liblogicalaccess/liblogicalaccess/tree/5a23140333ffc0c5dd60b2af4dcee3a435c82b29/plugins/logicalaccess/plugins/cards/desfire).
No external project source is compiled into the library.

Failure tests include every exchange boundary, corrupted protected responses,
cleanup uncertainty and caller-input mutation during I/O. See [VALIDATION.md](VALIDATION.md).
ISO identifiers, multi-access settings/data and AES TMAC file/transaction/receipt APIs are supplied by the new optional interfaces in [DESFIRE_FILES_TMAC.md](DESFIRE_FILES_TMAC.md). Combined SDM/multi-access settings are implemented. Native LRP authentication/secure-message codecs are available in [DESFIRE_LRP.md](DESFIRE_LRP.md); automatic LRP sessions and LRP TMAC are implemented there. LRP provisioning, originality and combined-layout data transactions remain separate profiles.

## Combined workflow profiles

Multiple-right AES TMAC owners, profile-aware application workflows and authenticated
stored SDM template backup/compare/restore are described in
[protocol/workflow profiles](PROTOCOL_COMPLETION.md). SDM/TMAC combined data operations
remain separate; the template profile refuses an application containing a TMAC file.
