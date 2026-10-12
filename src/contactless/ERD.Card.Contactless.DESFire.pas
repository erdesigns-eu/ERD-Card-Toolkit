unit ERD.Card.Contactless.DESFire;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Transport, ERD.Card.Crypto, ERD.Card.Contactless,
  ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.DESFire.EV1,
  ERD.Card.Crypto.DES, ERD.Card.Contactless.DESFire.DES,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.DESFire.Extensions;

const
  /// <summary>Hard bound for an individual acquired/plain DESFire transfer; wire fields remain 24-bit.</summary>
  DesfireMaxTransferBytes = 1048500;
  /// <summary>Hard bound for additional-frame exchanges in one logical command.</summary>
  DesfireMaxFrames = 65536;

type
  /// <summary>Invalid or unsupported native DESFire configuration, response or access policy.</summary>
  EDesfireError = class(EContactlessError);

  /// <summary>Native DESFire status error retaining only its single status byte.</summary>
  EDesfireStatusError = class(EDesfireError)
  private
    FStatus: Byte;
  public
    /// <summary>Creates a native status failure without command or card contents.</summary>
    /// <param name="AStatus">Raw SW2 following SW1=91.</param>
    constructor Create(const AStatus: Byte); reintroduce;
    /// <summary>Native DESFire status; no automatic recovery or replay.</summary>
    property Status: Byte read FStatus;
  end;

  /// <summary>Explicit native access/security profile; no default keys or authentication fallback.</summary>
  TDesfireSecurity = (
    /// <summary>Unauthenticated legacy native commands, public plaintext access only.</summary>
    dfsPublic,
    /// <summary>AuthenticateEV2First with caller-supplied AES key and EV2 Plain/MACed/Full messaging.</summary>
    dfsEv2Aes,
    /// <summary>EV1 AuthenticateAES with chained-IV AES-CMAC and encrypted CRC32 messaging.</summary>
    dfsEv1Aes,
    /// <summary>ISO Authenticate 1A with an explicit 16-byte 2K3DES key; chained eight-byte CMAC/CRC32.</summary>
    dfsEv1TwoKey3Des,
    /// <summary>ISO Authenticate 1A with an explicit 24-byte 3K3DES key; sixteen-byte nonces and CMAC/CRC32.</summary>
    dfsEv1ThreeKey3Des,
    /// <summary>Legacy Authenticate 0A with an explicit eight-byte DES key; reset-IV CBC-MAC/CRC16.</summary>
    dfsD40Des,
    /// <summary>Legacy Authenticate 0A with an explicit sixteen-byte 2K3DES key; no ISO messaging.</summary>
    dfsD40TwoKey3Des);
  /// <summary>Explicit native application key-type bits, independent of the PICC authentication dialect.</summary>
  /// <remarks>Creation initializes card-default credentials. This selects storage type only and never supplies or changes keys.</remarks>
  TDesfireApplicationKeyType = (
    /// <summary>Native DES/2K3DES key storage; wire type bits 00.</summary>
    daktDesOrTwoKey3Des,
    /// <summary>Native three-key Triple DES storage; wire type bits 40.</summary>
    daktThreeKey3Des,
    /// <summary>Native AES storage; wire type bits 80.</summary>
    daktAes);
  /// <summary>Supported ordinary native DESFire file types; administration and transaction writes are separate.</summary>
  TDesfireFileType = (
    /// <summary>Standard data file; verified range writing is supported.</summary>
    dftStandard,
    /// <summary>Backup data file; retained sessions stage and verify transactional range updates.</summary>
    dftBackup,
    /// <summary>Signed value file; retained sessions support credit, debit and limited credit.</summary>
    dftValue,
    /// <summary>Linear record file; retained sessions append complete records or clear the file.</summary>
    dftLinearRecords,
    /// <summary>Cyclic record file; retained sessions append with oldest-record eviction or clear the file.</summary>
    dftCyclicRecords);

  /// <summary>Strict ordinary file settings in the selected native application.</summary>
  /// <remarks>RawBytes is owned; ordinary record assignment shares its array. Extended/SDM/TMAC settings are refused.</remarks>
  TDesfireFileSettings = record
    /// <summary>Explicit native file number, 0..31; not an ISO file identifier.</summary>
    FileNumber: Byte;
    /// <summary>Ordinary supported native file type.</summary>
    FileType: TDesfireFileType;
    /// <summary>Acquired Plain/MACed/Full communication requirement.</summary>
    Communication: TDesfireCommunication;
    /// <summary>Read access nibble; E means free and F denies this access route.</summary>
    ReadKey: Byte;
    /// <summary>Write access nibble; E means free and F denies this route.</summary>
    WriteKey: Byte;
    /// <summary>Alternative read/write access nibble.</summary>
    ReadWriteKey: Byte;
    /// <summary>Access-right modification nibble; this component never changes rights.</summary>
    ChangeKey: Byte;
    /// <summary>Data-file size, otherwise zero; little-endian 24-bit field.</summary>
    FileBytes: Integer;
    /// <summary>Signed lower value-file limit, otherwise zero.</summary>
    LowerLimit: Integer;
    /// <summary>Signed upper value-file limit, otherwise zero.</summary>
    UpperLimit: Integer;
    /// <summary>Acquired limited-credit allowance, otherwise zero; retained sessions validate limited credit against it.</summary>
    LimitedCreditValue: Integer;
    /// <summary>Raw value options 0..3: limited credit and free GetValue indicators.</summary>
    ValueOptions: Byte;
    /// <summary>Record byte size, otherwise zero; little-endian 24-bit field.</summary>
    RecordBytes: Integer;
    /// <summary>Record-file maximum capacity, otherwise zero.</summary>
    MaxRecords: Integer;
    /// <summary>Acquired record count, otherwise zero; does not establish an atomic snapshot.</summary>
    CurrentRecords: Integer;
    /// <summary>Independent complete settings response for coherence comparison.</summary>
    RawBytes: TBytes;
  end;

  /// <summary>Owned ordered array of acquired file settings.</summary>
  TDesfireFiles = array of TDesfireFileSettings;
  /// <summary>Ordered nonzero 24-bit native application identifiers as host integers.</summary>
  TDesfireApplicationIds = array of Cardinal;

  /// <summary>Strict independent 28-byte hardware/software/manufacturing version response.</summary>
  TDesfireVersion = record
    /// <summary>Complete owned version data; includes potentially identifying manufacturing information.</summary>
    RawBytes: TBytes;
    /// <summary>Hardware vendor identifier reported by the card; not authenticity proof.</summary>
    Vendor: Byte;
    /// <summary>Hardware product-type byte; not automatic profile selection.</summary>
    ProductType: Byte;
    /// <summary>Hardware major version byte.</summary>
    HardwareMajor: Byte;
    /// <summary>Software major version byte.</summary>
    SoftwareMajor: Byte;
    /// <summary>Software storage-size code, retained without guessed capacity.</summary>
    StorageCode: Byte;
  end;

  /// <summary>Explicit session authority; transport exclusivity alone does not prove a clean card transaction.</summary>
  TDesfireSessionAccess = (
    /// <summary>Read operations only; never sends commit, abort or administrative writes.</summary>
    dsaReadOnly,
    /// <summary>Explicit immediate application/file management; no backup transaction writes.</summary>
    dsaManage,
    /// <summary>Caller attests a fresh reset/RF activation under exclusive ownership, with no prior pending changes.</summary>
    dsaFreshTransaction,
    /// <summary>Explicitly discards existing application pending changes with a verified AbortTransaction before staging.</summary>
    dsaDiscardPending);
  /// <summary>Session completion evidence; commit acknowledgement and data verification remain distinct.</summary>
  TDesfireSessionOutcome = (
    /// <summary>Exclusive card session remains active.</summary>
    dsoActive,
    /// <summary>Commit acknowledgement was verified; inspect VerificationSucceeded for read-back/release completion.</summary>
    dsoCommitted,
    /// <summary>Abort acknowledgement was verified, or an owned session had no staged changes to abort.</summary>
    dsoAborted,
    /// <summary>Session closed with no unresolved mutation.</summary>
    dsoClosed,
    /// <summary>A mutation or commit/abort may have executed, or staged changes were abandoned; never replay blindly.</summary>
    dsoUncertain);

  /// <summary>Owned ordinary native file-creation configuration; unused geometry fields must be zero.</summary>
  TDesfireFileDefinition = record
    /// <summary>Native file number 0..31.</summary>
    FileNumber: Byte;
    /// <summary>Standard, backup, value, linear or cyclic record file.</summary>
    FileType: TDesfireFileType;
    /// <summary>Explicit Plain/MACed/Full data communication mode.</summary>
    Communication: TDesfireCommunication;
    /// <summary>Explicit read nibble, 0..13 key, E free or F denied.</summary>
    ReadKey: Byte;
    /// <summary>Explicit write nibble.</summary>
    WriteKey: Byte;
    /// <summary>Explicit alternative read/write nibble.</summary>
    ReadWriteKey: Byte;
    /// <summary>Explicit change-access nibble.</summary>
    ChangeKey: Byte;
    /// <summary>Data-file size 1..FFFFFF, otherwise zero.</summary>
    FileBytes: Integer;
    /// <summary>Signed value lower bound, otherwise zero.</summary>
    LowerLimit: Integer;
    /// <summary>Signed value upper bound, otherwise zero.</summary>
    UpperLimit: Integer;
    /// <summary>Initial signed value within the configured bounds, otherwise zero.</summary>
    InitialValue: Integer;
    /// <summary>Explicit limited-credit flag for value files, otherwise false.</summary>
    LimitedCreditEnabled: Boolean;
    /// <summary>Record byte size 1..FFFFFF, otherwise zero.</summary>
    RecordBytes: Integer;
    /// <summary>Record capacity 1..FFFFFF, otherwise zero.</summary>
    MaxRecords: Integer;
  end;

  /// <summary>Owned strict GetKeySettings result; optional native key-set extension is retained exactly.</summary>
  TDesfireApplicationSettings = record
    /// <summary>Acquired first key-settings byte, including management policy flags.</summary>
    KeySettings: Byte;
    /// <summary>Acquired second byte: key type, ISO-ID flag and key count.</summary>
    KeyConfiguration: Byte;
    /// <summary>Independent complete native response, including explicit key-set settings when present.</summary>
    RawBytes: TBytes;
  end;

  /// <summary>Retained single-thread DESFire session with immutable copied configuration and one exclusive acquisition.</summary>
  /// <remarks>Independent of its creating component's lifetime. Release the final interface reference on the opening
  /// thread. No automatic commit/abort, recovery or replay; Close/destruction only release transport and local keys.
  /// Journal snapshots and aggregate expected bytes are bounded by the copied MaxTransferBytes, at most 256 mutations.</remarks>
  IDesfireSession = interface
    ['{175579E0-7E28-4F21-BB43-B90824EAA511}']
    /// <summary>Reads native PICC application IDs under the configured public/AES profile.</summary>
    /// <returns>Owned unique nonzero AIDs; PICC-level sessions only.</returns>
    function ReadApplicationIds: TDesfireApplicationIds;
    /// <summary>Reads ordinary key settings in the selected PICC/application context.</summary>
    /// <returns>Owned exact settings; unsupported extensions fail.</returns>
    function ReadApplicationSettings: TDesfireApplicationSettings;
    /// <summary>Reads the authenticated ordinary file directory in the selected nonzero application.</summary>
    /// <returns>Owned file settings; unknown file types fail instead of returning a partial directory.</returns>
    function ReadFiles: TDesfireFiles;
    /// <summary>Reads one explicit bounded standard/backup range within the retained session.</summary>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <param name="AOffset">Nonnegative byte offset.</param>
    /// <param name="ACount">Positive exact bounded byte count.</param>
    /// <returns>Owned verified currently visible bytes; staged changes are not assumed visible.</returns>
    function ReadData(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    /// <summary>Reads a value file through a permitted Read, Write or ReadWrite route.</summary>
    /// <param name="AFile">Native value-file number.</param>
    /// <returns>Acquired signed value within file bounds.</returns>
    function ReadValue(const AFile: Byte): Integer;
    /// <summary>Reads explicit complete records in native newest-first order.</summary>
    /// <param name="AFile">Native linear/cyclic record-file number.</param>
    /// <param name="AOffset">Nonnegative newest-relative record offset.</param>
    /// <param name="ACount">Positive exact bounded record count.</param>
    /// <returns>Owned verified concatenated records.</returns>
    function ReadRecords(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    /// <summary>Stages a backup-data range; captures the full original file and verifies its expected contents after commit.</summary>
    /// <param name="AFile">Native backup file; standard-data writes use the separate component API.</param>
    /// <param name="AOffset">Nonnegative range offset.</param>
    /// <param name="AData">Nonempty copied data fitting file geometry and the aggregate journal bound.</param>
    procedure WriteBackup(const AFile: Byte; const AOffset: Integer;
      const AData: TBytes);
    /// <summary>Stages positive credit through ReadWrite access, with signed-limit preflight and post-commit verification.</summary>
    /// <param name="AFile">Native value-file number.</param>
    /// <param name="AAmount">Positive amount 1..High(Integer).</param>
    procedure Credit(const AFile: Byte; const AAmount: Integer);
    /// <summary>Stages positive debit through Read, Write or ReadWrite access, with signed-limit preflight.</summary>
    /// <param name="AFile">Native value-file number.</param>
    /// <param name="AAmount">Positive amount.</param>
    procedure Debit(const AFile: Byte; const AAmount: Integer);
    /// <summary>Stages one limited credit per touched value file when enabled and within its acquired allowance.</summary>
    /// <param name="AFile">Native value-file number; Write or ReadWrite access required.</param>
    /// <param name="AAmount">Positive amount fitting allowance and signed upper limit.</param>
    procedure LimitedCredit(const AFile: Byte; const AAmount: Integer);
    /// <summary>Stages one complete newest record, preserving prior records and modelling cyclic oldest-record eviction.</summary>
    /// <param name="AFile">Native linear/cyclic record file.</param>
    /// <param name="AData">Exactly the acquired record size; copied before I/O.</param>
    procedure AppendRecord(const AFile: Byte; const AData: TBytes);
    /// <summary>Explicitly stages removal of all records, verified as empty after commit.</summary>
    /// <param name="AFile">Native linear/cyclic record file.</param>
    procedure ClearRecords(const AFile: Byte);
    /// <summary>Commits owned staged changes exactly once, verifies all touched files, then releases the session.</summary>
    /// <exception cref="EContactlessWriteUncertain">Dispatch, integrity, verification or release fails; inspect Outcome.</exception>
    /// <remarks>EV2 sends option zero, without TMAC receipts; EV1/public sends no option. Ordinary file types only.</remarks>
    procedure Commit;
    /// <summary>Explicitly aborts owned staged changes, verifies acknowledgement and releases the session.</summary>
    /// <exception cref="EContactlessWriteUncertain">An abort or its release fails; no recovery command is sent.</exception>
    procedure Abort;
    /// <summary>Creates an AES native application from PICC-level management access and verifies directory presence.</summary>
    /// <param name="AAid">Explicit nonzero 24-bit AID.</param>
    /// <param name="AKeySettings">Explicit first settings byte; no policy default.</param>
    /// <param name="AKeyCount">Explicit AES key count 1..14.</param>
    /// <remarks>Native creation initializes card-default keys; no key is guessed or changed by this API.</remarks>
    procedure CreateApplication(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte);
    /// <summary>Explicitly deletes one existing application from PICC-level management access and verifies absence.</summary>
    /// <param name="AAid">Explicit nonzero 24-bit AID; never formats the PICC.</param>
    procedure DeleteApplication(const AAid: Cardinal);
    /// <summary>Creates an ordinary file and verifies acquired type, geometry and access settings.</summary>
    /// <param name="ADefinition">Explicit validated native configuration; no ISO/SDM/TMAC extensions.</param>
    /// <remarks>Creation is immediate; Commit/Abort cannot undo it. Initial value is an acknowledged creation input.</remarks>
    procedure CreateFile(const ADefinition: TDesfireFileDefinition);
    /// <summary>Explicitly deletes an existing ordinary file after strict settings preflight, then verifies directory absence.</summary>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <remarks>Deletion is immediate and cannot be undone with Abort.</remarks>
    procedure DeleteFile(const AFile: Byte);
    /// <summary>Releases an active session without commit or abort; abandoned staged changes produce Uncertain.</summary>
    /// <remarks>Idempotent after completion. A failed explicit release propagates; destruction suppresses cleanup errors.</remarks>
    procedure Close;
    /// <summary>Returns completion evidence without card I/O.</summary>
    /// <returns>Current session outcome, retained after closure.</returns>
    function GetOutcome: TDesfireSessionOutcome;
    /// <summary>Reports successful post-commit verification and transaction release.</summary>
    /// <returns>True only after Commit completed all checks.</returns>
    function GetVerificationSucceeded: Boolean;
    /// <summary>Reports acknowledged staged changes not yet committed or aborted.</summary>
    /// <returns>True while changes remain unresolved, including abandoned sessions.</returns>
    function GetPendingChanges: Boolean;
    /// <summary>Current completion evidence.</summary>
    property Outcome: TDesfireSessionOutcome read GetOutcome;
    /// <summary>All touched files were verified after commit and release succeeded.</summary>
    property VerificationSucceeded: Boolean read GetVerificationSucceeded;
    /// <summary>Owned staged changes remain unresolved.</summary>
    property PendingChanges: Boolean read GetPendingChanges;
  end;

  /// <summary>Optional native administration view; existing IDesfireSession ABI remains unchanged.</summary>
  /// <remarks>Mutations require dsaManage and take immediate effect. Policy/access mutations support explicit authenticated profiles; ChangeAesKey remains AES-only. ChangeAesKey explicitly authenticates the new
  /// key after dispatch; no retry/default key is used. The creating component's credentials are not changed.</remarks>
  IDesfireManagement = interface(IDesfireSession)
    ['{DD91AF14-E995-4C6B-A99E-0FC72D9D84DC}']
    /// <summary>Reads the native free-memory count from PICC context.</summary>
    /// <returns>Verified 24-bit available byte count; not a reservation.</returns>
    function ReadFreeMemory: Integer;
    /// <summary>Reads one existing native key version under acquired key settings.</summary>
    /// <param name="AKeyNumber">Existing key number 0..13; PICC only permits zero.</param>
    /// <returns>Acquired version byte; version alone does not prove possession of a key.</returns>
    function ReadKeyVersion(const AKeyNumber: Byte): Byte;
    /// <summary>Changes the selected context's key policy and verifies its exact settings.</summary>
    /// <param name="ASettings">Explicit settings byte; valid change-key policy for the acquired key count.</param>
    /// <remarks>Requires explicit native authentication with key zero and acquired configuration-change permission.</remarks>
    procedure ChangeKeySettings(const ASettings: Byte);
    /// <summary>Changes ordinary file communication/access nibbles, preserving and verifying its other settings.</summary>
    /// <param name="AFile">Existing ordinary native file 0..31.</param>
    /// <param name="ACommunication">Explicit Plain/MACed/Full mode.</param>
    /// <param name="AReadKey">Explicit read nibble 0..15.</param>
    /// <param name="AWriteKey">Explicit write nibble 0..15.</param>
    /// <param name="AReadWriteKey">Explicit ReadWrite nibble 0..15.</param>
    /// <param name="AChangeKey">Explicit rights-change nibble 0..15.</param>
    /// <remarks>Free-change EV1/D40 uses its Plain command policy; protected changes use Full messaging.
    /// Extended/SDM/TMAC settings require a separate profile.</remarks>
    procedure ChangeFileAccess(const AFile: Byte;
      const ACommunication: TDesfireCommunication;
      const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
    /// <summary>Rotates one existing AES key once, then proves the new key by fresh mutual authentication and version reading.</summary>
    /// <param name="AKeyNumber">Existing native number; PICC zero retains AES type.</param>
    /// <param name="ANewVersion">Explicit new version byte.</param>
    /// <param name="ANewKey">Exactly 16 copied new secret bytes.</param>
    /// <param name="AOldKey">Exactly 16 explicit old bytes for another key; empty when changing the authenticated key.</param>
    /// <remarks>Successful verification leaves the retained session authenticated with the new target key.
    /// A current-key change may have only a bare native acknowledgement; fresh authentication supplies the proof.
    /// Any failure after dispatch is uncertain. No key-type conversion or EV2 key-set change is inferred.</remarks>
    procedure ChangeAesKey(const AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
  end;

  /// <summary>Optional typed native application creation; existing session/management IIDs remain unchanged.</summary>
  /// <remarks>Works through the selected public/AES/ISO-3DES/legacy message dialect. A native error never triggers type conversion or retry.</remarks>
  IDesfireApplicationManagement = interface(IDesfireManagement)
    ['{CE26C6D2-D17E-4BF5-A226-5457B0E112F6}']
    /// <summary>Creates one explicitly typed native application from PICC management and verifies directory presence.</summary>
    /// <param name="AAid">Nonzero 24-bit AID absent from the acquired directory.</param>
    /// <param name="AKeySettings">Explicit native policy byte; change-key selector must fit the supplied key count.</param>
    /// <param name="AKeyCount">Explicit count 1..14.</param>
    /// <param name="AKeyType">DES/2K3DES, 3K3DES or AES key storage; not inferred from the authenticated PICC key.</param>
    /// <remarks>Immediate mutation, not reversible through Abort. No ISO names, extensions, key guessing or key provisioning.</remarks>
    procedure CreateApplicationWithKeyType(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte;
      const AKeyType: TDesfireApplicationKeyType);
  end;

  /// <summary>Optional supplied-key DES/3DES rotation view; existing interface IIDs and layouts remain unchanged.</summary>
  IDesfireDesManagement = interface(IDesfireApplicationManagement)
    ['{58432EE5-126F-479C-9F2B-A8F5C839A28B}']
    /// <summary>Rotates one same-type DES/2K3DES/3K3DES key and proves its new version by fresh authentication.</summary>
    /// <param name="AKeyNumber">Existing native key number 0..13; PICC permits zero only.</param>
    /// <param name="ANewVersion">Version encoded in the first subkey's least significant bits.</param>
    /// <param name="AOldVersion">Explicit stored version of another target key; ignored for the authenticated key.</param>
    /// <param name="ANewKey">Exactly 8/16/24 copied material bytes matching the explicit security profile.</param>
    /// <param name="AOldKey">Exactly matching stored bytes for another key, preserving second/third subkey version bits; empty for the authenticated key.</param>
    /// <remarks>DES repeats its eight bytes on the wire; 2K3DES uses complemented second-subkey version bits.
    /// No key-type conversion or fallback. Post-dispatch failures are uncertain; component credentials remain unchanged.</remarks>
    procedure ChangeDesKey(const AKeyNumber, ANewVersion, AOldVersion: Byte;
      const ANewKey, AOldKey: TBytes);
  end;

  /// <summary>Optional EV2 AES key-set, configuration and EV3 SDM management; existing interface layouts are unchanged.</summary>
  /// <remarks>Requires an explicit EV2 AES management session for mutations. No secret key defaults;
  /// initialization/finalization/configuration establish authenticated acknowledgement, not independent read-back.</remarks>
  IDesfireExtendedManagement = interface(IDesfireManagement)
    ['{FA7364B1-1965-4F1F-9A5D-730AB0040AE7}']
    /// <summary>Creates an AES application with explicit multiple-key-set geometry and verifies exact key settings.</summary>
    /// <param name="AAid">Nonzero 24-bit target AID; current session must select PICC.</param>
    /// <param name="ASettings">Explicit application key policy.</param>
    /// <param name="AKeyCount">One through fourteen keys per set.</param>
    /// <param name="ASetCount">Two through sixteen native key sets.</param>
    /// <param name="ASetVersion">Initial active-set version.</param>
    /// <param name="ARollKey">Explicit roll selector zero through seven, within key count.</param>
    /// <remarks>Fresh selection verifies settings then restores PICC authentication; failure after creation is uncertain.</remarks>
    procedure CreateApplicationWithKeySets(const AAid: Cardinal;
      const ASettings, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte);
    /// <summary>Reads one supplied inactive-set key version; version alone does not prove possession.</summary>
    /// <param name="ASet">Exact native set, zero for current or one through fifteen for configured inactive sets.</param>
    /// <param name="AKeyNumber">Existing key zero through thirteen.</param>
    /// <returns>Authenticated acquired version byte.</returns>
    function ReadKeySetKeyVersion(const ASet, AKeyNumber: Byte): Byte;
    /// <summary>Reads the complete native key-set version list without inferring undocumented state flags.</summary>
    /// <returns>Independent native version-list bytes.</returns>
    function ReadKeySetVersionList: TBytes;
    /// <summary>Initializes an explicit inactive AES set with authenticated acknowledgement.</summary>
    /// <param name="ASet">Configured inactive set one through fifteen.</param>
    procedure InitializeAesKeySet(const ASet: Byte);
    /// <summary>Replaces an inactive AES key and verifies its acquired version; possession is proven after rolling.</summary>
    /// <param name="ASet">Configured inactive set one through fifteen.</param>
    /// <param name="AKeyNumber">Explicit existing key zero through thirteen.</param>
    /// <param name="ANewVersion">Replacement version byte.</param>
    /// <param name="ANewKey">Exactly sixteen replacement secret bytes.</param>
    /// <param name="AOldKey">Exactly sixteen supplied stored secret bytes.</param>
    procedure ChangeInactiveAesKey(const ASet, AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
    /// <summary>Finalizes a configured inactive key set with authenticated acknowledgement.</summary>
    /// <param name="ASet">Explicit inactive set one through fifteen.</param>
    /// <param name="AVersion">Explicit final set version.</param>
    procedure FinalizeKeySet(const ASet, AVersion: Byte);
    /// <summary>Rolls an inactive set once and proves a supplied key by fresh active-set authentication/version.</summary>
    /// <param name="ASet">Configured finalized inactive set one through fifteen.</param>
    /// <param name="AVerifyKeyNumber">Key in the resulting active set used for fresh proof.</param>
    /// <param name="AVerifyVersion">Expected resulting key version.</param>
    /// <param name="AVerifyKey">Exactly sixteen supplied resulting active key bytes.</param>
    /// <remarks>Card lifecycle/finalization rules remain enforced by native status; no roll or authentication retry.</remarks>
    procedure RollKeySetVerified(const ASet, AVerifyKeyNumber, AVerifyVersion: Byte;
      const AVerifyKey: TBytes);
    /// <summary>Applies an explicit supported SetConfiguration option with encrypted command and protected acknowledgement.</summary>
    /// <param name="AOption">PICC 00, ATS 02, SAK 03, secure-messaging 04 or value-file 09.</param>
    /// <param name="AData">Exact validated option bytes, independently copied before dispatch.</param>
    /// <remarks>No general GetConfiguration command exists; this API does not claim independent read-back.</remarks>
    procedure SetConfigurationAcknowledged(const AOption: Byte; const AData: TBytes);
    /// <summary>Reads complete standard-data settings with optional EV3 AES SDM fields.</summary>
    /// <param name="AFile">Explicit native standard-data file zero through thirty-one.</param>
    /// <returns>Independent validated settings, preserving conditional mirror fields.</returns>
    function ReadSdmSettings(const AFile: Byte): TDesfireSdmSettings;
    /// <summary>Changes standard-data SDM/ordinary access configuration against an exact acquired preimage and verifies every setting.</summary>
    /// <param name="AFile">Existing standard-data file zero through thirty-one.</param>
    /// <param name="AExpected">Exact previously acquired complete settings bytes.</param>
    /// <param name="ADesired">Explicit settings with unchanged file geometry; no file data is written.</param>
    procedure ChangeSdmSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const ADesired: TDesfireSdmSettings);
  end;

  /// <summary>Optional EV2 ISO identifiers, multi-access data and transaction-MAC file management.</summary>
  /// <remarks>Existing interface layouts/IIDs remain unchanged. TMAC file/record metadata is separate from transaction receipt generation.</remarks>
  IDesfireFileManagement = interface(IDesfireExtendedManagement)
    ['{681D2C6B-4567-43BD-A6F7-824B1E733512}']
    /// <summary>Acquires frame-preserved authenticated ISO application directory entries.</summary>
    /// <returns>Owned bounded AID/FID/DF-name tuples; current selection must be PICC.</returns>
    function ReadIsoApplications: TDesfireIsoApplications;
    /// <summary>Acquires unique native ISO file identifiers in the selected application.</summary>
    /// <returns>Owned FID list, independent of native file-number order.</returns>
    function ReadIsoFileIds: TDesfireIsoFileIds;
    /// <summary>Creates an AES ISO application and verifies the exact acquired directory tuple.</summary>
    /// <param name="AAid">Explicit unused nonzero native 24-bit AID; current selection PICC.</param>
    /// <param name="APolicy">Explicit native application key policy.</param>
    /// <param name="AKeyCount">One-through-fourteen AES keys; no default secret keys are used.</param>
    /// <param name="AIsoFid">Explicit unused nonreserved ISO FID.</param>
    /// <param name="ADfName">Explicit unique one-through-sixteen-byte ISO DF name; frozen before I/O.</param>
    procedure CreateIsoApplicationVerified(const AAid: Cardinal;
      const APolicy, AKeyCount: Byte; const AIsoFid: Word; const ADfName: TBytes);
    /// <summary>Creates one ordinary ISO data/record file and verifies geometry and acquired FID presence.</summary>
    /// <param name="ADefinition">Explicit ordinary standard/backup/linear/cyclic file definition; value files have no ISO FID.</param>
    /// <param name="AIsoFid">Explicit unused nonreserved ISO FID in an ISO-enabled application.</param>
    procedure CreateIsoFileVerified(const ADefinition: TDesfireFileDefinition;
      const AIsoFid: Word);
    /// <summary>Reads complete ordinary/multi-access settings and validates geometry.</summary>
    /// <param name="AFile">Explicit native ordinary file number zero-through-thirty-one.</param>
    /// <returns>Owned exact raw/base bytes and all native access-right tuples.</returns>
    function ReadMultiAccessSettings(const AFile: Byte): TDesfireMultiAccessSettings;
    /// <summary>Changes ordinary/multiple access tuples against exact frozen settings and verifies complete read-back.</summary>
    /// <param name="AFile">Existing ordinary file number.</param>
    /// <param name="AExpected">Exact acquired complete prior settings, frozen before I/O.</param>
    /// <param name="ACommunication">Native Plain=0, MACed=1 or Full=3.</param>
    /// <param name="ARights">One-through-eight explicit primary/additional wire-order rights.</param>
    procedure ChangeMultiAccessVerified(const AFile: Byte; const AExpected: TBytes;
      const ACommunication: Byte; const ARights: TDesfireAccessRightSets);
    /// <summary>Reads ordinary data using any acquired valid primary/additional read authority and verifies unchanged settings.</summary>
    /// <param name="AFile">Explicit standard/backup file number.</param>
    /// <param name="AOffset">Explicit nonnegative byte offset.</param>
    /// <param name="ACount">Positive bounded exact byte count.</param>
    /// <returns>Owned acquired data under the file's communication mode.</returns>
    function ReadMultiAccessData(const AFile: Byte; const AOffset, ACount: Integer): TBytes;
    /// <summary>Writes standard data against an exact frozen preimage using any valid acquired write authority.</summary>
    /// <param name="AFile">Explicit standard-data file number; backup transactions are separate.</param>
    /// <param name="AOffset">Nonnegative byte offset.</param>
    /// <param name="AExpected">Exact previously acquired nonempty byte range.</param>
    /// <param name="AData">Same-sized replacement data; frozen before I/O.</param>
    procedure WriteMultiAccessDataVerified(const AFile: Byte; const AOffset: Integer;
      const AExpected, AData: TBytes);
    /// <summary>Reads acquired AES transaction-MAC file metadata with protected native settings exchange.</summary>
    /// <param name="AFile">Explicit type-05 native file number.</param>
    /// <returns>Owned metadata, not secret-key possession proof.</returns>
    function ReadTransactionMacSettings(const AFile: Byte): TDesfireTmacSettings;
    /// <summary>Creates one AES transaction-MAC file with encrypted supplied key and verifies exact metadata.</summary>
    /// <param name="AFile">Unused native file number zero-through-thirty-one.</param>
    /// <param name="AFileOption">Native communication 0/1/3 and optional exclude-unauthenticated flag 10 hex.</param>
    /// <param name="AAccessRights">Explicit CommitReaderID/change/read/write native tuples; write nibble must F.</param>
    /// <param name="AKeyVersion">Explicit supplied AES TMAC key version.</param>
    /// <param name="AKey">Exactly sixteen supplied AES bytes, frozen and temporarily wiped.</param>
    /// <remarks>Metadata/version verification is not offline TMAC validation. Ordinary transaction profiles still reject TMAC-enabled applications.</remarks>
    procedure CreateTransactionMacFileVerified(const AFile, AFileOption: Byte;
      const AAccessRights: Word; const AKeyVersion: Byte; const AKey: TBytes);
    /// <summary>Changes TMAC communication/access/exclusion/counter-limit settings against an exact preimage and verifies metadata.</summary>
    /// <param name="AFile">Existing AES TMAC file number.</param>
    /// <param name="AExpected">Exact six/ten-byte acquired settings, frozen before I/O.</param>
    /// <param name="AFileOption">Native communication plus exclude-unauthenticated/limit flags.</param>
    /// <param name="AAccessRights">Explicit CommitReaderID/change/read/write tuple, write nibble F.</param>
    /// <param name="ACounterLimit">One-through-FFFFFFFF when flag 20 hex is set, otherwise zero.</param>
    /// <remarks>Current change-key authority is required; key option/version are preserved. Card enforces current-counter/lifecycle restrictions.</remarks>
    procedure ChangeTransactionMacSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const AFileOption: Byte; const AAccessRights: Word; const ACounterLimit: Cardinal);
    /// <summary>Deletes one explicit TMAC file against exact metadata and verifies directory absence.</summary>
    /// <param name="AFile">Explicit existing native TMAC file number.</param>
    /// <param name="AExpected">Exact acquired metadata, frozen before I/O.</param>
    /// <remarks>Requires explicit management and selected application key zero; no transaction reset, retry or replacement is inferred.</remarks>
    procedure DeleteTransactionMacFileVerified(const AFile: Byte; const AExpected: TBytes);
    /// <summary>Reads a complete TMAC counter/tag record with acquired access/mode and unchanged settings.</summary>
    /// <param name="AFile">Explicit AES transaction-MAC file number.</param>
    /// <returns>Owned counter/MAC; Plain mode bytes need offline TMAC validation and are not authenticated by secure-session framing.</returns>
    function ReadTransactionMacRecord(const AFile: Byte): TDesfireTmacRecord;
  end;

  /// <summary>Explicit AES TMAC-owned transaction with canonical input tracking and offline receipt-key verification.</summary>
  /// <remarks>Existing ordinary transaction interfaces/IIDs retain their behavior. This profile supplies a real UID,
  /// trusted previous counter and TMAC key, accepts ordinary files plus one explicit TMAC file, and block-aligned records.</remarks>
  IDesfireTransactionMacSession = interface(IDesfireSession)
    ['{C64D0EC8-D935-40B5-87DF-A051842DB2D4}']
    /// <summary>Commits one explicit reader ID, verifies its secure-session response and decrypts the previous reader ID.</summary>
    /// <param name="AReaderId">Exactly sixteen caller-supplied bytes, frozen before dispatch.</param>
    /// <returns>Owned sixteen-byte previous reader ID decrypted with the supplied transaction key.</returns>
    /// <remarks>Only once per transaction; requires the acquired CommitReaderID access key. No default IDs.</remarks>
    function CommitReaderId(const AReaderId: TBytes): TBytes;
    /// <summary>Returns a copy of captured canonical plaintext transaction input, including successful reads.</summary>
    /// <returns>Independent personal-data-bearing input, bounded to 1048560 bytes; caller must clear it.</returns>
    function ReadTransactionMacInput: TBytes;
    /// <summary>Commits once, verifies exact next counter and TMAC under the supplied static key/UID, then verifies journaled file state and release.</summary>
    /// <returns>Owned protected counter/MAC receipt only after offline MAC and native journal proofs succeed.</returns>
    /// <exception cref="EContactlessWriteUncertain">Commit dispatch, offline receipt proof, file verification or release cannot be established.</exception>
    function CommitTransactionMacVerified: TDesfireTmacRecord;
  end;

  /// <summary>Optional ISO creation with independently acquired multiple-key-set geometry.</summary>
  /// <remarks>Existing file-management interface layout and IID are unchanged.</remarks>
  IDesfireIsoKeySetManagement = interface(IDesfireFileManagement)
    ['{A0926332-5E35-45D0-88F5-07BECA72F6B8}']
    /// <summary>Creates one ISO AES application and verifies its directory tuple and exact public key-set settings.</summary>
    /// <param name="AAid">Unused nonzero twenty-four-bit native application identifier.</param>
    /// <param name="APolicy">Explicit key policy; bit one must permit unauthenticated key-settings acquisition.</param>
    /// <param name="AKeyCount">One through fourteen keys per set.</param>
    /// <param name="ASetCount">Two through sixteen native key sets.</param>
    /// <param name="ASetVersion">Initial active-set version.</param>
    /// <param name="ARollKey">Existing roll selector zero through seven.</param>
    /// <param name="AIsoFid">Unused nonreserved native ISO FID.</param>
    /// <param name="ADfName">One through sixteen owned directory-name bytes, frozen before I/O.</param>
    /// <remarks>PICC selection and explicit EV2 AES management are required. No initial application key is guessed.</remarks>
    procedure CreateIsoApplicationWithKeySetsVerified(const AAid: Cardinal;
      const APolicy, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte;
      const AIsoFid: Word; const ADfName: TBytes);
  end;

  /// <summary>Optional verified standard-data writes inside an explicitly owned AES TMAC calculation.</summary>
  /// <remarks>Standard writes are immediate. Abort cancels the calculation but cannot restore written bytes.
  /// Existing transaction interface layout and IID are unchanged.</remarks>
  IDesfireTransactionMacDataSession = interface(IDesfireTransactionMacSession)
    ['{708CD4D7-CB26-42A6-AB97-78A24259F157}']
    /// <summary>Checks an exact range preimage, writes changed standard data, verifies it immediately and journals its final range for commit proof.</summary>
    /// <param name="AFile">Existing ordinary standard-data file number zero through thirty-one.</param>
    /// <param name="AOffset">Nonnegative byte offset within the acquired file.</param>
    /// <param name="AExpected">Exact current range bytes, frozen before I/O.</param>
    /// <param name="AData">Equal-length replacement bytes, frozen before I/O; equal data skips mutation.</param>
    /// <remarks>Both acquired read and write permissions are required. Overlapping writes update earlier range proofs.
    /// Reads and immediate verification contribute to canonical TMI. Commit verifies the receipt and every final journaled range.</remarks>
    /// <exception cref="EContactlessWriteUncertain">A write may have executed but its response, range/settings proof or subsequent receipt cannot be established.</exception>
    procedure WriteStandardDataVerified(const AFile: Byte; const AOffset: Integer;
      const AExpected, AData: TBytes);
  end;

  /// <summary>Optional combined standard-file SDM and multiple-access-right management.</summary>
  /// <remarks>Preserves existing interfaces and requires explicit EV2 AES management credentials.</remarks>
  IDesfireSdmAccessManagement = interface(IDesfireFileManagement)
    ['{776383E4-2312-47B5-9D8F-9E49AFC25369}']
    /// <summary>Acquires all primary/additional rights and conditional SDM fields without discarding combined flags.</summary>
    /// <param name="AFile">Existing standard-file number zero through thirty-one.</param>
    /// <returns>Owned validated settings; original ordinary getters still reject combined layouts.</returns>
    function ReadSdmAccessSettings(const AFile: Byte): TDesfireSdmAccessSettings;
    /// <summary>Changes combined settings against an exact frozen preimage and verifies the complete resulting layout.</summary>
    /// <param name="AFile">Existing ordinary or SDM standard-file number.</param>
    /// <param name="AExpected">Exact prior native settings bytes, frozen before I/O.</param>
    /// <param name="ADesired">Typed SDM and complete right tuples; RawBytes is ignored, geometry must remain unchanged.</param>
    /// <remarks>Validates every application key reference and primary change authority. Can remove SDM or additional tuples.</remarks>
    procedure ChangeSdmAccessSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const ADesired: TDesfireSdmAccessSettings);
  end;

  /// <summary>Optional owned EV2 AES full-record updates for the native sixteen-byte cyclic-record profile.</summary>
  /// <remarks>Also available through Supports on an owned AES TMAC session. Existing interfaces and IIDs are unchanged.</remarks>
  IDesfireRecordUpdateSession = interface(IDesfireSession)
    ['{A75C630D-C03D-427A-AC32-4793A9891569}']
    /// <summary>Stages one complete cyclic-record update against an exact owned-journal preimage.</summary>
    /// <param name="AFile">Existing sixteen-byte cyclic-record file number.</param>
    /// <param name="ARecord">Zero-based record number, newest first, within acquired record count.</param>
    /// <param name="AExpected">Exactly sixteen current owned-journal bytes, frozen before I/O.</param>
    /// <param name="AData">Exactly sixteen replacement bytes, frozen before I/O; equal data skips mutation.</param>
    /// <remarks>Native UpdateRecord requires read/write authority. Updates may repeat for the same record,
    /// but cannot mix append/clear or a different record within the same file transaction. Commit proves all journaled records.</remarks>
    procedure StageCyclicRecordUpdate(const AFile: Byte; const ARecord: Integer;
      const AExpected, AData: TBytes);
  end;

  /// <summary>Pure strict codecs for wrapped ordinary DESFire native commands and settings.</summary>
  TDesfireCodec = class
  public
    /// <summary>Validates an ordinary file-creation definition without acquiring or mutating a card.</summary>
    /// <param name="ADefinition">Explicit supported file geometry, rights and initial value.</param>
    class procedure ValidateDefinition(const ADefinition: TDesfireFileDefinition); static;
    /// <summary>Builds short native wrapping 90/INS/00/00 with trailing Le=00.</summary>
    /// <param name="AInstruction">Native command or AF continuation.</param>
    /// <param name="AData">Zero through 255 independent command data bytes.</param>
    /// <returns>Independent five-byte empty command, or six-byte framing plus data.</returns>
    /// <exception cref="EDesfireError">Data exceeds the short-command bound.</exception>
    class function Command(const AInstruction: Byte; const AData: TBytes)
      : TBytes; static;
    /// <summary>Encodes an explicitly selected 24-bit native AID in little-endian transmission order.</summary>
    /// <param name="AAid">Zero for PICC level, or a nonzero value through FFFFFF.</param>
    /// <returns>Independent three bytes.</returns>
    /// <exception cref="EDesfireError">Value is out of range.</exception>
    class function ApplicationBytes(const AAid: Cardinal): TBytes; static;
    /// <summary>Decodes complete acquired application identifiers, rejecting root/duplicate entries.</summary>
    /// <param name="AData">Zero through 3072 bytes, divisible by three.</param>
    /// <returns>Independent ordered identifiers, at most 1024.</returns>
    /// <exception cref="EDesfireError">Length, duplicate or root identifier is invalid.</exception>
    class function ApplicationIds(const AData: TBytes)
      : TDesfireApplicationIds; static;
    /// <summary>Decodes ordinary complete settings without inferring unsupported extensions.</summary>
    /// <param name="AFileNumber">Native number 0..31.</param>
    /// <param name="AData">Exact 7-byte data, 17-byte value or 13-byte record settings.</param>
    /// <returns>Independent validated file geometry/access settings.</returns>
    /// <exception cref="EDesfireError">Type, communication, size or geometry is unsupported.</exception>
    class function FileSettings(const AFileNumber: Byte; const AData: TBytes)
      : TDesfireFileSettings; static;
    /// <summary>Decodes a complete 28-byte native version response without identity authentication.</summary>
    /// <param name="AData">Exactly 28 acquired data bytes.</param>
    /// <returns>Independent version metadata and complete source bytes.</returns>
    /// <exception cref="EDesfireError">Length is invalid.</exception>
    class function Version(const AData: TBytes): TDesfireVersion; static;
    /// <summary>Builds a native file/range header using 24-bit little-endian offsets and counts.</summary>
    /// <param name="AFileNumber">Native number 0..31.</param>
    /// <param name="AOffset">Nonnegative byte or newest-relative record offset, through FFFFFF.</param>
    /// <param name="ACount">Positive byte/record count, through FFFFFF; zero/all is deliberately refused.</param>
    /// <returns>Independent seven-byte header.</returns>
    /// <exception cref="EDesfireError">Arguments are invalid.</exception>
    class function RangeHeader(const AFileNumber: Byte;
      const AOffset, ACount: Integer): TBytes; static;
    /// <summary>Decodes one signed little-endian 32-bit value without unsigned overflow casts.</summary>
    /// <param name="AData">Exactly four bytes.</param>
    /// <returns>Signed acquired value.</returns>
    /// <exception cref="EDesfireError">Length is invalid.</exception>
    class function SignedValue(const AData: TBytes): Integer; static;
  end;

  /// <summary>Nonvisual native DESFire discovery, data/value/record reading and verified standard-data writing.</summary>
  /// <remarks>One caller thread, no reentrancy. Every operation selects its explicit native application in an
  /// exclusive transaction, optionally authenticates afresh and clears session secrets at release. No retries,
  /// default keys, implicit reset, formatting or key changes. OpenSession adds explicit owned transactions and management.</remarks>
  TDesfireCardReader = class(TComponent)
  private
    FTransport, FActiveTransport: ICardTransport;
    FProvider: ICardAesProvider;
    FTransaction: ICardTransaction;
    FKey, FRekey, FSessionIv: TBytes;
    FRekeyNumber, FSessionKeyNumber: Byte;
    FReauthenticated: Boolean;
    FKeyNumber: Byte;
    FSecurity: TDesfireSecurity;
    FMinimum: TDesfireCommunication;
    FMaxTransfer, FMaxFrameData: Integer;
    FBusy, FAuthenticated, FWriteAttempt: Boolean;
    FKeys: TDesfireEv2Keys;
    FTi: TBytes;
    FCounter, FAttempts: Integer;
    FCaptureFrames: Boolean;
    FResponseSizes: array of Integer;
    FTmacCapture: Boolean;
    FTmacExcludedFile: Integer;
    FTmacInput: TBytes;
    procedure ReserveTmac(const ACommand: Byte; const AHeader: TBytes; const ADataLength: Integer);
    procedure TrackTmac(const ACommand: Byte; const AHeader, AData: TBytes);
    function Metadata(const AInstruction: Byte; const AHeader: TBytes;
      const AMaxBytes: Integer; const AMutation: Boolean): TBytes;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetProvider(const AValue: ICardAesProvider);
    procedure SetKey(const AValue: TBytes);
    function GetKey: TBytes;
    procedure SetKeyNumber(const AValue: Byte);
    procedure SetSecurity(const AValue: TDesfireSecurity);
    procedure SetMinimum(const AValue: TDesfireCommunication);
    procedure SetMaxTransfer(const AValue: Integer);
    procedure SetMaxFrameData(const AValue: Integer);
    procedure Start(const AAid: Cardinal; const AAuthenticate: Boolean);
    procedure Finish(const ASucceeded: Boolean);
    procedure ValidateCredentials;
    procedure Authenticate(const AReauthenticate: Boolean = False);
    procedure AuthenticateDes;
    function DesProvider: ICardDesProvider;
    function IsDes: Boolean;
    function IsLegacyDes: Boolean;
    procedure SetRekey(const AValue: TBytes);
    function GetRekey: TBytes;
    procedure SetRekeyNumber(const AValue: Byte);
    function Frame(const AInstruction: Byte; const AData: TBytes;
      out AStatus: Byte; const AWrite: Boolean): TBytes;
    function Exchange(const AInstruction: Byte; const AData: TBytes;
      const AMaxResponse: Integer; const AWrite: Boolean): TBytes;
    function Send(const AInstruction: Byte; const AHeader, AData: TBytes;
      const AMode: TDesfireCommunication; const AExpected: Integer;
      const AWrite: Boolean): TBytes;
    function Settings(const AFile: Byte): TDesfireFileSettings;
    procedure CheckAccess(const ASettings: TDesfireFileSettings;
      const AWrite: Boolean);
    function ReadSelected(const ASettings: TDesfireFileSettings;
      const AOffset, ACount: Integer): TBytes;
    procedure CheckSettings(const ASettings: TDesfireFileSettings);
  public
    /// <summary>Creates an inactive component with public access, a 64 KiB transfer bound and 48-byte command frames.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Clears both locally retained authentication credentials and session bytes; callers must not destroy a busy component.</summary>
    destructor Destroy; override;
    /// <summary>Selects PICC level and reads version without authentication or automatic family selection.</summary>
    /// <returns>Complete independent version only after successful transaction release.</returns>
    /// <exception cref="EContactlessError">Transport, status, framing or release fails.</exception>
    function ReadVersion: TDesfireVersion;
    /// <summary>Selects PICC level and lists publicly visible native application IDs without authentication.</summary>
    /// <returns>Independent ordered application identifiers after release.</returns>
    /// <exception cref="Exception">Transport, configured authentication, status or decoding fails.</exception>
    function ReadApplicationIds: TDesfireApplicationIds;
    /// <summary>Selects an application, lists public directory entries and optionally authenticates to retrieve settings.</summary>
    /// <param name="AAid">Explicit nonzero native 24-bit application identifier.</param>
    /// <returns>Independent ordered settings; unknown extended file types fail rather than yield a partial list.</returns>
    /// <exception cref="Exception">Selection, authentication, directory/settings or release fails.</exception>
    function ReadFiles(const AAid: Cardinal): TDesfireFiles;
    /// <summary>Reads an explicit bounded range from a standard or backup data file.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <param name="AOffset">Zero-based byte offset.</param>
    /// <param name="ACount">Positive exact byte count, at most MaxTransferBytes and within acquired file size.</param>
    /// <returns>Independent plaintext only after required MAC/CRC verification, settings coherence and release.</returns>
    /// <exception cref="Exception">Access, secure messaging, bounds or transport fails.</exception>
    function ReadData(const AAid: Cardinal; const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    /// <summary>Reads the signed current value from a value file; does not debit or credit.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <returns>Acquired signed value within its settings bounds, after release.</returns>
    /// <exception cref="Exception">Type, access, authentication, secure messaging or transport fails.</exception>
    function ReadValue(const AAid: Cardinal; const AFile: Byte): Integer;
    /// <summary>Reads a bounded count of complete records in native newest-first response order.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native linear/cyclic record file number.</param>
    /// <param name="AOffset">Zero-based offset from the newest record.</param>
    /// <param name="ACount">Positive exact record count; total bytes must fit MaxTransferBytes.</param>
    /// <returns>Independent concatenated records after settings coherence and release.</returns>
    /// <exception cref="Exception">Type, access, range, secure messaging or transport fails.</exception>
    function ReadRecords(const AAid: Cardinal; const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    /// <summary>Writes one explicit standard-data range and verifies it independently within the acquired session.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native standard-data file number; backup files are deliberately separate transactions.</param>
    /// <param name="AOffset">Zero-based byte offset.</param>
    /// <param name="AData">Nonempty plaintext, copied before I/O; at most MaxTransferBytes.</param>
    /// <exception cref="Exception">Preflight, read/write rights or authentication fails before dispatch.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any dispatched write, verification or release fails; never retry blindly.</exception>
    /// <remarks>Requires both read and write access. Matching acquired bytes are a verified no-op. Chained writes
    /// are not atomic; the component sends no rollback, commit or abort and preserves bytes outside the range.</remarks>
    procedure WriteData(const AAid: Cardinal; const AFile: Byte;
      const AOffset: Integer; const AData: TBytes);
    /// <summary>Opens an independent retained session using immutable copied configuration and explicit authority.</summary>
    /// <param name="AAid">Native AID; zero only for PICC reads/management, nonzero for owned transactions.</param>
    /// <param name="AAccess">Explicit read, management or transaction-ownership policy; no default.</param>
    /// <returns>Exclusive single-thread session; independent of component lifetime.</returns>
    /// <exception cref="Exception">Arguments, acquisition, authentication or ordinary-file preflight fails.</exception>
    function OpenSession(const AAid: Cardinal;
      const AAccess: TDesfireSessionAccess): IDesfireSession;
    /// <summary>Opens an immutable retained AES management session; construction opens no implicit default-key access.</summary>
    /// <param name="AAid">Explicit native AID, zero for PICC administration.</param>
    /// <returns>Owned management view with all ordinary session read/create/delete operations.</returns>
    function OpenManagementSession(const AAid: Cardinal): IDesfireManagement;
    /// <summary>Opens explicit EV2 AES key-set/configuration/EV3 SDM management, independent of component lifetime.</summary>
    /// <param name="AAid">Explicit 24-bit context; zero selects PICC.</param>
    /// <returns>Retained exclusive management session; callers must Close.</returns>
    function OpenExtendedManagementSession(const AAid: Cardinal): IDesfireExtendedManagement;
    /// <summary>Opens an explicit EV2 AES management session for ISO/multi-access/TMAC file APIs.</summary>
    /// <param name="AAid">Exact PICC zero or native application AID.</param>
    /// <returns>Owned optional file-management interface; no transaction ownership is inferred.</returns>
    function OpenFileManagementSession(const AAid: Cardinal): IDesfireFileManagement;
    /// <summary>Opens an owned fresh EV2 AES transaction with native sixteen-byte cyclic-record updates.</summary>
    /// <param name="AAid">Explicit nonzero native application identifier.</param>
    /// <param name="AAcknowledgeFresh">Required assertion that no external transaction is pending.</param>
    /// <returns>Owned optional record-update interface; use explicit Commit or Abort.</returns>
    function OpenRecordUpdateSession(const AAid: Cardinal;
      const AAcknowledgeFresh: Boolean): IDesfireRecordUpdateSession;
    /// <summary>Opens native combined SDM and multiple-access standard-file management.</summary>
    /// <param name="AAid">Nonzero exact native application identifier.</param>
    /// <returns>Owned optional management interface; no data-template writes are inferred.</returns>
    function OpenSdmAccessManagementSession(const AAid: Cardinal): IDesfireSdmAccessManagement;
    /// <summary>Opens explicit PICC AES management including ISO creation with multiple key sets.</summary>
    /// <returns>Owned optional management interface, independent of component lifetime.</returns>
    function OpenIsoKeySetManagementSession: IDesfireIsoKeySetManagement;
    /// <summary>Opens one explicit fresh AES TMAC transaction, verifies real card UID and captures canonical data operations.</summary>
    /// <param name="AAid">Nonzero native application AID.</param>
    /// <param name="ATmacFile">Exact existing type-05 AES TMAC file number.</param>
    /// <param name="AUid">Exactly seven trusted real card UID bytes, verified by protected GetCardUID.</param>
    /// <param name="ATmacKey">Exactly sixteen supplied static transaction key bytes, owned copy cleared on completion.</param>
    /// <param name="APreviousCounter">Trusted previously accepted counter, below FFFFFFFF; no counter guessing or rollover.</param>
    /// <param name="AAcknowledgeFresh">Explicit assertion that no external pending transaction exists.</param>
    /// <returns>Owned optional transaction interface; LRP, extended file layouts and unaligned record files are refused.</returns>
    function OpenTransactionMacSession(const AAid: Cardinal; const ATmacFile: Byte;
      const AUid, ATmacKey: TBytes; const APreviousCounter: Cardinal;
      const AAcknowledgeFresh: Boolean): IDesfireTransactionMacSession;
    /// <summary>Opens a fresh AES TMAC session that also supports immediate standard-data range writes.</summary>
    /// <param name="AAid">Nonzero native application AID.</param>
    /// <param name="ATmacFile">Exact existing AES TMAC file number.</param>
    /// <param name="AUid">Seven trusted real UID bytes, checked by protected acquisition.</param>
    /// <param name="ATmacKey">Sixteen supplied static TMAC key bytes, frozen before I/O.</param>
    /// <param name="APreviousCounter">Trusted previous counter below FFFFFFFF.</param>
    /// <param name="AAcknowledgeFresh">Explicit assertion that no external pending transaction exists.</param>
    /// <returns>Owned optional data interface; Abort does not reverse immediate standard writes.</returns>
    function OpenTransactionMacDataSession(const AAid: Cardinal; const ATmacFile: Byte;
      const AUid, ATmacKey: TBytes; const APreviousCounter: Cardinal;
      const AAcknowledgeFresh: Boolean): IDesfireTransactionMacDataSession;
    /// <summary>Opens retained native management with an optional explicit application key-type creation API.</summary>
    /// <param name="AAid">Zero for PICC application management, nonzero for ordinary file management.</param>
    /// <returns>Owned session; close explicitly. Authentication uses this component's selected profile.</returns>
    function OpenApplicationManagementSession(const AAid: Cardinal)
      : IDesfireApplicationManagement;
    /// <summary>Opens supplied-key native DES/3DES management, checking the explicit profile before acquisition.</summary>
    /// <param name="AAid">Zero for PICC, nonzero 24-bit application AID.</param>
    /// <returns>Retained independently owned management engine; close explicitly.</returns>
    function OpenDesManagementSession(const AAid: Cardinal)
      : IDesfireDesManagement;
    /// <summary>Retained connected native-wrapping transport with ICardTransaction; cannot change while busy.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
    /// <summary>Retained maintained backend; DES profiles require the optional ICardDesProvider capability.</summary>
    property CryptoProvider: ICardAesProvider read FProvider write SetProvider;
    /// <summary>Owned profile key: 8-byte DES, 16-byte AES/2K3DES or 24-byte 3K3DES; empty clears; getter copies.</summary>
    property AuthenticationKey: TBytes read GetKey write SetKey;
    /// <summary>Explicit application authentication key number 0..13; not automatically guessed.</summary>
    property KeyNumber: Byte read FKeyNumber write SetKeyNumber;
    /// <summary>Optional owned EV2 NonFirst AES key; empty disables switching. Getter returns an independent copy.</summary>
    /// <remarks>Data/value/record reads and standard writes first retrieve settings under AuthenticationKey, then switch
    /// once before checking data access. TI and command counter remain unchanged. ReadFiles uses the initial key.</remarks>
    property ReauthenticationKey: TBytes read GetRekey write SetRekey;
    /// <summary>Explicit target application key number 0..13 for the optional EV2 NonFirst switch.</summary>
    property ReauthenticationKeyNumber: Byte read FRekeyNumber
      write SetRekeyNumber;
    /// <summary>Explicit public, EV1/EV2 AES, ISO 2K/3K3DES or D40 DES/2K3DES profile; no downgrade/fallback.</summary>
    property Security: TDesfireSecurity read FSecurity write SetSecurity;
    /// <summary>Minimum acquired file mode for authenticated operations, default MACed; choose Plain explicitly if intended.</summary>
    property MinimumCommunication: TDesfireCommunication read FMinimum
      write SetMinimum;
    /// <summary>Per-operation plaintext transfer bound, 1..DesfireMaxTransferBytes, default 65536.</summary>
    property MaxTransferBytes: Integer read FMaxTransfer write SetMaxTransfer;
    /// <summary>Maximum native command data per short APDU, 16..255, default 48; select for actual card/reader.</summary>
    property MaxFrameDataBytes: Integer read FMaxFrameData
      write SetMaxFrameData;
    /// <summary>True throughout acquisition, authentication, commands and release; nested calls/configuration are refused.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

type
  TDesfireJournalEntry = record
    Settings: TDesfireFileSettings;
    Offset: Integer;
    Expected: TBytes;
    UsedLimitedCredit: Boolean;
    RecordOperation, UpdatedRecord: Integer;
  end;

  TDesfireSession = class(TInterfacedObject, IDesfireSession,
    IDesfireManagement, IDesfireApplicationManagement, IDesfireDesManagement, IDesfireExtendedManagement, IDesfireFileManagement, IDesfireTransactionMacSession, IDesfireIsoKeySetManagement, IDesfireTransactionMacDataSession, IDesfireSdmAccessManagement, IDesfireRecordUpdateSession)
  private
    FEngine: TDesfireCardReader;
    FAid: Cardinal;
    FAccess: TDesfireSessionAccess;
    FOutcome: TDesfireSessionOutcome;
    FPending, FVerified, FInCall: Boolean;
    FThread: NativeUInt;
    FJournal: array of TDesfireJournalEntry;
    FTmacFile: Integer;
    FTmacPreviousCounter: Cardinal;
    FTmacKey, FTmacUid: TBytes;
    FTmacSettings: TDesfireTmacSettings;
    FReaderIdCommitted: Boolean;
    FMutations: Integer;
    function CommitInternal(const ATmac: Boolean): TDesfireTmacRecord;
    function Enter: Integer;
    function Poison(const ABefore: Integer): Boolean;
    procedure RequireOwner;
    procedure RequireManagement;
    function FileIds: TBytes;
    function AppSettings: TDesfireApplicationSettings;
    function Granted(const AKey: Byte): Boolean;
    procedure ValueAccess(const S: TDesfireFileSettings; const ACommand: Byte);
    function Value(const S: TDesfireFileSettings): Integer;
    function Records(const S: TDesfireFileSettings;
      const AOffset, ACount: Integer): TBytes;
    function Journal(const S: TDesfireFileSettings): Integer;
    procedure CheckStatic(const A, B: TDesfireFileSettings);
    procedure AdjustValue(const AFile: Byte; const AAmount: Integer;
      const ACommand: Byte);
    procedure ClearJournal;
    function JournalBytes: Integer;
    procedure RequireEv2Management;
    procedure RequireKeySet(const ASet, AKeyNumber: Byte);
    function KeySetVersion(const ASet, AKeyNumber: Byte): Byte;
    procedure RequireFileManagement(const ACreation: Boolean = False);
    procedure CreateIsoApplicationInternal(const AAid: Cardinal; const AIsoFid: Word;
      const ADfName, AHeader, AExpectedSettings: TBytes);
    function IsoDirectory: TDesfireIsoApplications;
    function IsoIds: TDesfireIsoFileIds;
    function MultiSettings(const AFile: Byte): TDesfireMultiAccessSettings;
    procedure ValidateRightKeys(const ARights: TDesfireAccessRightSets);
    function MultiRead(const AFile: Byte; const S: TDesfireMultiAccessSettings;
      const AOffset, ACount: Integer; const AWriting: Boolean): TBytes;
    function TmacMetadata(const AFile: Byte): TDesfireTmacSettings;
    procedure RequireAesManagement;
    procedure RequireNativeManagement;
    function KeyVersion(const AKeyNumber: Byte): Byte;
  public
    constructor Create(const AReader: TDesfireCardReader; const AAid: Cardinal;
      const AAccess: TDesfireSessionAccess; const ATmacFile: Integer = -1;
      const ATmacUid: TBytes = nil; const ATmacKey: TBytes = nil;
      const APreviousCounter: Cardinal = 0);
    destructor Destroy; override;
    function ReadApplicationIds: TDesfireApplicationIds;
    function ReadApplicationSettings: TDesfireApplicationSettings;
    function ReadFiles: TDesfireFiles;
    function ReadData(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    function ReadValue(const AFile: Byte): Integer;
    function ReadRecords(const AFile: Byte;
      const AOffset, ACount: Integer): TBytes;
    procedure WriteBackup(const AFile: Byte; const AOffset: Integer;
      const AData: TBytes);
    procedure Credit(const AFile: Byte; const AAmount: Integer);
    procedure Debit(const AFile: Byte; const AAmount: Integer);
    procedure LimitedCredit(const AFile: Byte; const AAmount: Integer);
    procedure AppendRecord(const AFile: Byte; const AData: TBytes);
    procedure ClearRecords(const AFile: Byte);
    procedure Commit;
    procedure Abort;
    procedure CreateApplication(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte);
    procedure CreateApplicationWithKeyType(const AAid: Cardinal;
      const AKeySettings, AKeyCount: Byte;
      const AKeyType: TDesfireApplicationKeyType);
    procedure DeleteApplication(const AAid: Cardinal);
    procedure CreateFile(const ADefinition: TDesfireFileDefinition);
    procedure DeleteFile(const AFile: Byte);
    procedure Close;
    function ReadFreeMemory: Integer;
    function ReadKeyVersion(const AKeyNumber: Byte): Byte;
    procedure ChangeKeySettings(const ASettings: Byte);
    procedure ChangeFileAccess(const AFile: Byte;
      const ACommunication: TDesfireCommunication;
      const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
    procedure ChangeDesKey(const AKeyNumber, ANewVersion, AOldVersion: Byte;
      const ANewKey, AOldKey: TBytes);
    procedure ChangeAesKey(const AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
    procedure CreateApplicationWithKeySets(const AAid: Cardinal;
      const ASettings, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte);
    function ReadKeySetKeyVersion(const ASet, AKeyNumber: Byte): Byte;
    function ReadKeySetVersionList: TBytes;
    procedure InitializeAesKeySet(const ASet: Byte);
    procedure ChangeInactiveAesKey(const ASet, AKeyNumber, ANewVersion: Byte;
      const ANewKey, AOldKey: TBytes);
    procedure FinalizeKeySet(const ASet, AVersion: Byte);
    procedure RollKeySetVerified(const ASet, AVerifyKeyNumber, AVerifyVersion: Byte;
      const AVerifyKey: TBytes);
    procedure SetConfigurationAcknowledged(const AOption: Byte; const AData: TBytes);
    function ReadSdmSettings(const AFile: Byte): TDesfireSdmSettings;
    function ReadIsoApplications: TDesfireIsoApplications;
    function ReadIsoFileIds: TDesfireIsoFileIds;
    procedure CreateIsoApplicationVerified(const AAid: Cardinal;
      const APolicy, AKeyCount: Byte; const AIsoFid: Word; const ADfName: TBytes);
    procedure CreateIsoFileVerified(const ADefinition: TDesfireFileDefinition; const AIsoFid: Word);
    function ReadMultiAccessSettings(const AFile: Byte): TDesfireMultiAccessSettings;
    procedure ChangeMultiAccessVerified(const AFile: Byte; const AExpected: TBytes;
      const ACommunication: Byte; const ARights: TDesfireAccessRightSets);
    function ReadMultiAccessData(const AFile: Byte; const AOffset, ACount: Integer): TBytes;
    procedure WriteMultiAccessDataVerified(const AFile: Byte; const AOffset: Integer;
      const AExpected, AData: TBytes);
    function ReadTransactionMacSettings(const AFile: Byte): TDesfireTmacSettings;
    procedure CreateTransactionMacFileVerified(const AFile, AFileOption: Byte;
      const AAccessRights: Word; const AKeyVersion: Byte; const AKey: TBytes);
    function ReadTransactionMacRecord(const AFile: Byte): TDesfireTmacRecord;
    procedure ChangeTransactionMacSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const AFileOption: Byte; const AAccessRights: Word; const ACounterLimit: Cardinal);
    procedure DeleteTransactionMacFileVerified(const AFile: Byte; const AExpected: TBytes);
    function CommitReaderId(const AReaderId: TBytes): TBytes;
    function ReadTransactionMacInput: TBytes;
    function CommitTransactionMacVerified: TDesfireTmacRecord;
    procedure ChangeSdmSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const ADesired: TDesfireSdmSettings);
    procedure CreateIsoApplicationWithKeySetsVerified(const AAid: Cardinal;
      const APolicy, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte;
      const AIsoFid: Word; const ADfName: TBytes);
    procedure StageCyclicRecordUpdate(const AFile: Byte; const ARecord: Integer;
      const AExpected, AData: TBytes);
    function ReadSdmAccessSettings(const AFile: Byte): TDesfireSdmAccessSettings;
    procedure ChangeSdmAccessSettingsVerified(const AFile: Byte; const AExpected: TBytes;
      const ADesired: TDesfireSdmAccessSettings);
    procedure WriteStandardDataVerified(const AFile: Byte; const AOffset: Integer;
      const AExpected, AData: TBytes);
    function GetOutcome: TDesfireSessionOutcome;
    function GetVerificationSucceeded: Boolean;
    function GetPendingChanges: Boolean;
  end;

procedure InvalidDesfire;
begin
  raise EDesfireError.Create
    ('Invalid or unsupported DESFire configuration, response or access.');
end;

constructor EDesfireStatusError.Create(const AStatus: Byte);
begin
  inherited CreateFmt('DESFire native status %2.2x.', [AStatus]);
  FStatus := AStatus;
end;

function Le24(const A: TBytes; const Offset: Integer): Integer;
begin
  Result := Integer(A[Offset]) or (Integer(A[Offset + 1]) shl 8) or
    (Integer(A[Offset + 2]) shl 16);
end;

class function TDesfireCodec.Command(const AInstruction: Byte;
  const AData: TBytes): TBytes;
begin
  Result := nil;
  if Length(AData) > 255 then
    InvalidDesfire;
  if Length(AData) = 0 then
    SetLength(Result, 5)
  else
    SetLength(Result, Length(AData) + 6);
  Result[0] := $90;
  Result[1] := AInstruction;
  if Length(AData) > 0 then
  begin
    Result[4] := Length(AData);
    Move(AData[0], Result[5], Length(AData));
  end;
end;

class function TDesfireCodec.ApplicationBytes(const AAid: Cardinal): TBytes;
begin
  Result := nil;
  if AAid > $FFFFFF then
    InvalidDesfire;
  SetLength(Result, 3);
  Result[0] := AAid and $FF;
  Result[1] := (AAid shr 8) and $FF;
  Result[2] := AAid shr 16;
end;

class function TDesfireCodec.ApplicationIds(const AData: TBytes)
  : TDesfireApplicationIds;
var
  I, J: Integer;
begin
  Result := nil;
  if (Length(AData) > 3072) or (Length(AData) mod 3 <> 0) then
    InvalidDesfire;
  SetLength(Result, Length(AData) div 3);
  for I := 0 to High(Result) do
  begin
    Result[I] := Le24(AData, I * 3);
    if Result[I] = 0 then
      InvalidDesfire;
    for J := 0 to I - 1 do
      if Result[J] = Result[I] then
        InvalidDesfire;
  end;
end;

class function TDesfireCodec.SignedValue(const AData: TBytes): Integer;
var
  Value: Int64;
begin
  if Length(AData) <> 4 then
    InvalidDesfire;
  Value := Int64(AData[0]) or (Int64(AData[1]) shl 8) or
    (Int64(AData[2]) shl 16) or (Int64(AData[3]) shl 24);
  if Value > High(Integer) then
    Dec(Value, Int64($100000000));
  Result := Value;
end;

class function TDesfireCodec.FileSettings(const AFileNumber: Byte;
  const AData: TBytes): TDesfireFileSettings;
begin
  Result := Default (TDesfireFileSettings);
  if (AFileNumber > 31) or (Length(AData) < 4) or (AData[0] > 4) then
    InvalidDesfire;
  Result.FileNumber := AFileNumber;
  Result.FileType := TDesfireFileType(AData[0]);
  case AData[1] of
    0:
      Result.Communication := dfcPlain;
    1:
      Result.Communication := dfcMac;
    3:
      Result.Communication := dfcFull;
  else
    InvalidDesfire;
  end;
  Result.ReadWriteKey := AData[2] shr 4;
  Result.ChangeKey := AData[2] and $F;
  Result.ReadKey := AData[3] shr 4;
  Result.WriteKey := AData[3] and $F;
  case Result.FileType of
    dftStandard, dftBackup:
      begin
        if Length(AData) <> 7 then
          InvalidDesfire;
        Result.FileBytes := Le24(AData, 4);
        if Result.FileBytes = 0 then
          InvalidDesfire;
      end;
    dftValue:
      begin
        if Length(AData) <> 17 then
          InvalidDesfire;
        Result.LowerLimit := SignedValue(Copy(AData, 4, 4));
        Result.UpperLimit := SignedValue(Copy(AData, 8, 4));
        Result.LimitedCreditValue := SignedValue(Copy(AData, 12, 4));
        Result.ValueOptions := AData[16];
        if (Result.LowerLimit > Result.UpperLimit) or (Result.ValueOptions > 3)
        then
          InvalidDesfire;
      end;
    dftLinearRecords, dftCyclicRecords:
      begin
        if Length(AData) <> 13 then
          InvalidDesfire;
        Result.RecordBytes := Le24(AData, 4);
        Result.MaxRecords := Le24(AData, 7);
        Result.CurrentRecords := Le24(AData, 10);
        if (Result.RecordBytes = 0) or (Result.MaxRecords = 0) or
          (Result.CurrentRecords > Result.MaxRecords) then
          InvalidDesfire;
      end;
  end;
  Result.RawBytes := CopyBytes(AData);
end;

class function TDesfireCodec.Version(const AData: TBytes): TDesfireVersion;
begin
  Result := Default (TDesfireVersion);
  if Length(AData) <> 28 then
    InvalidDesfire;
  Result.RawBytes := CopyBytes(AData);
  Result.Vendor := AData[0];
  Result.ProductType := AData[1];
  Result.HardwareMajor := AData[3];
  Result.SoftwareMajor := AData[10];
  Result.StorageCode := AData[12];
end;

class function TDesfireCodec.RangeHeader(const AFileNumber: Byte;
  const AOffset, ACount: Integer): TBytes;
begin
  Result := nil;
  if (AFileNumber > 31) or (AOffset < 0) or (AOffset > $FFFFFF) or (ACount < 1)
    or (ACount > $FFFFFF) then
    InvalidDesfire;
  SetLength(Result, 7);
  Result[0] := AFileNumber;
  Result[1] := AOffset and $FF;
  Result[2] := (AOffset shr 8) and $FF;
  Result[3] := AOffset shr 16;
  Result[4] := ACount and $FF;
  Result[5] := (ACount shr 8) and $FF;
  Result[6] := ACount shr 16;
end;

constructor TDesfireCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinimum := dfcMac;
  FMaxTransfer := 65536;
  FMaxFrameData := 48;
end;

destructor TDesfireCardReader.Destroy;
begin
  TCardCrypto.Clear(FKey);
  TCardCrypto.Clear(FRekey);
  TDesfireEv2Codec.ClearKeys(FKeys);
  TCardCrypto.Clear(FTi);
  TCardCrypto.Clear(FSessionIv);
  inherited Destroy;
end;

procedure TDesfireCardReader.SetTransport(const AValue: ICardTransport);
begin
  if FBusy then
    InvalidDesfire;
  FTransport := AValue;
end;

procedure TDesfireCardReader.SetProvider(const AValue: ICardAesProvider);
begin
  if FBusy then
    InvalidDesfire;
  FProvider := AValue;
end;

procedure TDesfireCardReader.SetKey(const AValue: TBytes);
var
  B: TBytes;
begin
  if FBusy or not(Length(AValue) in [0, 8, 16, 24]) then
    InvalidDesfire;
  B := CopyBytes(AValue);
  TCardCrypto.Clear(FKey);
  FKey := B;
end;

function TDesfireCardReader.GetKey: TBytes;
begin
  Result := CopyBytes(FKey);
end;

procedure TDesfireCardReader.SetRekey(const AValue: TBytes);
var
  B: TBytes;
begin
  if FBusy or not(Length(AValue) in [0, 16]) then
    InvalidDesfire;
  B := CopyBytes(AValue);
  TCardCrypto.Clear(FRekey);
  FRekey := B;
end;

function TDesfireCardReader.GetRekey: TBytes;
begin
  Result := CopyBytes(FRekey);
end;

procedure TDesfireCardReader.SetRekeyNumber(const AValue: Byte);
begin
  if FBusy or (AValue > 13) then
    InvalidDesfire;
  FRekeyNumber := AValue;
end;

procedure TDesfireCardReader.ValidateCredentials;
begin
  if FSecurity <> dfsPublic then
  begin
    if FProvider = nil then
      InvalidDesfire;
    case FSecurity of
      dfsEv1ThreeKey3Des:
        if Length(FKey) <> 24 then
          InvalidDesfire;
      dfsD40Des:
        if Length(FKey) <> 8 then
          InvalidDesfire;
    else
      if Length(FKey) <> 16 then
        InvalidDesfire;
    end;
    if IsDes then
      DesProvider;
  end;
  if (Length(FRekey) > 0) and (FSecurity <> dfsEv2Aes) then
    InvalidDesfire;
end;

procedure TDesfireCardReader.SetKeyNumber(const AValue: Byte);
begin
  if FBusy or (AValue > 13) then
    InvalidDesfire;
  FKeyNumber := AValue;
end;

procedure TDesfireCardReader.SetSecurity(const AValue: TDesfireSecurity);
begin
  if FBusy or (Ord(AValue) < 0) or (Ord(AValue) > Ord(High(TDesfireSecurity)))
  then
    InvalidDesfire;
  FSecurity := AValue;
end;

procedure TDesfireCardReader.SetMinimum(const AValue: TDesfireCommunication);
begin
  if FBusy or (Ord(AValue) < 0) or
    (Ord(AValue) > Ord(High(TDesfireCommunication))) then
    InvalidDesfire;
  FMinimum := AValue;
end;

procedure TDesfireCardReader.SetMaxTransfer(const AValue: Integer);
begin
  if FBusy or (AValue < 1) or (AValue > DesfireMaxTransferBytes) then
    InvalidDesfire;
  FMaxTransfer := AValue;
end;

procedure TDesfireCardReader.SetMaxFrameData(const AValue: Integer);
begin
  if FBusy or (AValue < 16) or (AValue > 255) then
    InvalidDesfire;
  FMaxFrameData := AValue;
end;

function TDesfireCardReader.Frame(const AInstruction: Byte; const AData: TBytes;
  out AStatus: Byte; const AWrite: Boolean): TBytes;
var
  R: TApduResponse;
  CommandBytes: TBytes;
begin
  Result := nil;
  AStatus := 0;
  CommandBytes := TDesfireCodec.Command(AInstruction, AData);
  try
    if AWrite then
      FWriteAttempt := True;
    Inc(FAttempts);
    R := TApduCodec.DecodeResponse(FActiveTransport.Exchange(CommandBytes));
    if ((R.StatusWord shr 8) <> $91) or (Length(R.Data) > 256) then
      InvalidDesfire;
    AStatus := R.StatusWord and $FF;
    if not(AStatus in [0, $AF]) then
      raise EDesfireStatusError.Create(AStatus);
    Result := R.Data;
  finally
    TCardCrypto.Clear(CommandBytes);
  end;
end;

function TDesfireCardReader.Exchange(const AInstruction: Byte;
  const AData: TBytes; const AMaxResponse: Integer;
  const AWrite: Boolean): TBytes;
var
  Status, Instruction: Byte;
  Position, N, Received, Frames: Integer;
  Chunk, Part, Buffer: TBytes;
begin
  Result := nil;
  if (AMaxResponse < 0) or (AMaxResponse > DesfireMaxTransferBytes + 32) or
    (Length(AData) > DesfireMaxTransferBytes + 64) then
    InvalidDesfire;
  Buffer := nil;
  Chunk := nil;
  Part := nil;
  try
    SetLength(Buffer, AMaxResponse);
    Position := 0;
    Received := 0;
    Frames := 0;
    if FCaptureFrames then FResponseSizes := nil;
    Instruction := AInstruction;
    repeat
      Inc(Frames);
      if Frames > DesfireMaxFrames then
        InvalidDesfire;
      N := Length(AData) - Position;
      if N > FMaxFrameData then
        N := FMaxFrameData;
      Chunk := Copy(AData, Position, N);
      Inc(Position, N);
      Part := Frame(Instruction, Chunk, Status, AWrite);
      TCardCrypto.Clear(Chunk);
      if Position < Length(AData) then
      begin
        if (Status <> $AF) or (Length(Part) <> 0) then
          InvalidDesfire;
      end
      else
      begin
        if Length(Part) > AMaxResponse - Received then
          InvalidDesfire;
        if Length(Part) > 0 then
          Move(Part[0], Buffer[Received], Length(Part));
        Inc(Received, Length(Part));
        if FCaptureFrames then
        begin
          SetLength(FResponseSizes, Length(FResponseSizes) + 1);
          FResponseSizes[High(FResponseSizes)] := Length(Part);
        end;
        if (Status = $AF) and (Length(Part) = 0) then
          InvalidDesfire;
      end;
      TCardCrypto.Clear(Part);
      Instruction := $AF;
    until Status = 0;
    if Position <> Length(AData) then
      InvalidDesfire;
    Result := Copy(Buffer, 0, Received);
  finally
    TCardCrypto.Clear(Buffer);
    TCardCrypto.Clear(Chunk);
    TCardCrypto.Clear(Part);
  end;
end;

function TDesfireCardReader.IsDes: Boolean;
begin
  Result := FSecurity in [dfsEv1TwoKey3Des, dfsEv1ThreeKey3Des, dfsD40Des,
    dfsD40TwoKey3Des];
end;

function TDesfireCardReader.IsLegacyDes: Boolean;
begin
  Result := FSecurity in [dfsD40Des, dfsD40TwoKey3Des];
end;

function TDesfireCardReader.DesProvider: ICardDesProvider;
begin
  if not Supports(FProvider, ICardDesProvider, Result) then
    InvalidDesfire;
end;

procedure TDesfireCardReader.AuthenticateDes;
var
  P: ICardDesProvider;
  K, InitialVector, Header, Cipher, A, B, Plain, Challenge, Rotated,
    Received: TBytes;
  N, J: Integer;
  Status, Instruction: Byte;
begin
  P := DesProvider;
  K := CopyBytes(FKey);
  InitialVector := nil;
  Header := nil;
  Cipher := nil;
  A := nil;
  B := nil;
  Plain := nil;
  Challenge := nil;
  Rotated := nil;
  Received := nil;
  FAuthenticated := False;
  try
    N := 8;
    if FSecurity = dfsEv1ThreeKey3Des then
      N := 16;
    A := P.RandomBytes(N);
    if Length(A) <> N then
      InvalidDesfire;
    SetLength(InitialVector, 8);
    SetLength(Header, 1);
    Header[0] := FKeyNumber;
    Instruction := $1A;
    if IsLegacyDes then
      Instruction := $0A;
    Cipher := Frame(Instruction, Header, Status, False);
    if (Status <> $AF) or (Length(Cipher) <> N) then
      InvalidDesfire;
    B := TCardDesCrypto.Crypt(P, K, InitialVector, Cipher, False);
    if not IsLegacyDes then
    begin
      TCardCrypto.Clear(InitialVector);
      InitialVector := Copy(Cipher, N - 8, 8);
    end;
    SetLength(Plain, N * 2);
    Move(A[0], Plain[0], N);
    for J := 0 to N - 1 do
      Plain[N + J] := B[(J + 1) mod N];
    if IsLegacyDes then
      Challenge := TCardDesCrypto.LegacySend(P, K, Plain)
    else
      Challenge := TCardDesCrypto.Crypt(P, K, InitialVector, Plain, True);
    if not IsLegacyDes then
    begin
      TCardCrypto.Clear(InitialVector);
      InitialVector := Copy(Challenge, N * 2 - 8, 8);
    end;
    TCardCrypto.Clear(Cipher);
    Cipher := Frame($AF, Challenge, Status, False);
    if (Status <> 0) or (Length(Cipher) <> N) then
      InvalidDesfire;
    Received := TCardDesCrypto.Crypt(P, K, InitialVector, Cipher, False);
    SetLength(Rotated, N);
    for J := 0 to N - 1 do
      Rotated[J] := A[(J + 1) mod N];
    if not TCardCrypto.EqualSecret(Rotated, Received) then
      InvalidDesfire;
    TDesfireEv2Codec.ClearKeys(FKeys);
    FKeys.Encryption := TDesfireDesCodec.DeriveKey(A, B, Length(K));
    TCardCrypto.Clear(FSessionIv);
    SetLength(FSessionIv, 8);
    FSessionKeyNumber := FKeyNumber;
    FReauthenticated := False;
    FAuthenticated := True;
  finally
    TCardCrypto.Clear(K);
    TCardCrypto.Clear(InitialVector);
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(A);
    TCardCrypto.Clear(B);
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Challenge);
    TCardCrypto.Clear(Rotated);
    TCardCrypto.Clear(Received);
  end;
end;

procedure TDesfireCardReader.Authenticate(const AReauthenticate: Boolean);
var
  Key, Initial, Header, Cipher, RndA, RndB, Plain, Challenge, Rotated,
    Received: TBytes;
  Status, Instruction, Number: Byte;
  I, Expected, Offset: Integer;
begin
  if IsDes then
  begin
    if AReauthenticate then
      InvalidDesfire;
    AuthenticateDes;
    Exit;
  end;
  if AReauthenticate and ((FSecurity <> dfsEv2Aes) or not FAuthenticated or
    (Length(FRekey) <> 16) or FReauthenticated) then
    InvalidDesfire;
  Number := FKeyNumber;
  Key := CopyBytes(FKey);
  if AReauthenticate then
  begin
    TCardCrypto.Clear(Key);
    Key := CopyBytes(FRekey);
    Number := FRekeyNumber;
  end;
  Initial := nil;
  Header := nil;
  Cipher := nil;
  RndA := nil;
  RndB := nil;
  Plain := nil;
  Challenge := nil;
  Rotated := nil;
  Received := nil;
  FAuthenticated := False;
  try
    SetLength(Initial, 16);
    SetLength(Header, 1);
    Header[0] := Number;
    Instruction := $71;
    Expected := 32;
    Offset := 4;
    if FSecurity = dfsEv1Aes then
    begin
      Instruction := $AA;
      Expected := 16;
      Offset := 0;
    end
    else if AReauthenticate then
    begin
      Instruction := $77;
      Expected := 16;
      Offset := 0;
    end
    else
      SetLength(Header, 2); // LenCap=0, explicit all-zero PCD capabilities.
    Cipher := Frame(Instruction, Header, Status, False);
    if (Status <> $AF) or (Length(Cipher) <> 16) then
      InvalidDesfire;
    RndB := FProvider.DecryptCbc(Key, Initial, Cipher);
    if Length(RndB) <> 16 then
      InvalidDesfire;
    if FSecurity = dfsEv1Aes then
    begin
      TCardCrypto.Clear(Initial);
      Initial := CopyBytes(Cipher);
    end;
    RndA := FProvider.RandomBytes(16);
    if Length(RndA) <> 16 then
      InvalidDesfire;
    SetLength(Plain, 32);
    Move(RndA[0], Plain[0], 16);
    for I := 0 to 15 do
      Plain[16 + I] := RndB[(I + 1) mod 16];
    Challenge := FProvider.EncryptCbc(Key, Initial, Plain);
    if Length(Challenge) <> 32 then
      InvalidDesfire;
    if FSecurity = dfsEv1Aes then
    begin
      TCardCrypto.Clear(Initial);
      Initial := Copy(Challenge, 16, 16);
    end;
    TCardCrypto.Clear(Cipher);
    Cipher := Frame($AF, Challenge, Status, False);
    if (Status <> 0) or (Length(Cipher) <> Expected) then
      InvalidDesfire;
    TCardCrypto.Clear(Plain);
    Plain := FProvider.DecryptCbc(Key, Initial, Cipher);
    if Length(Plain) <> Expected then
      InvalidDesfire;
    SetLength(Rotated, 16);
    for I := 0 to 15 do
      Rotated[I] := RndA[(I + 1) mod 16];
    Received := Copy(Plain, Offset, 16);
    if not TCardCrypto.EqualSecret(Rotated, Received) then
      InvalidDesfire;
    TDesfireEv2Codec.ClearKeys(FKeys);
    if FSecurity = dfsEv1Aes then
    begin
      FKeys.Encryption := TDesfireEv1Codec.DeriveKey(RndA, RndB);
      TCardCrypto.Clear(FSessionIv);
      SetLength(FSessionIv, 16);
    end
    else
    begin
      if not AReauthenticate then
      begin
        for I := 26 to 31 do
          if Plain[I] <> 0 then
            InvalidDesfire;
        FTi := Copy(Plain, 0, 4);
        FCounter := 0;
      end;
      FKeys := TDesfireEv2Codec.DeriveKeys(FProvider, Key, RndA, RndB);
    end;
    FSessionKeyNumber := Number;
    FReauthenticated := AReauthenticate;
    FAuthenticated := True;
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Initial);
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(RndA);
    TCardCrypto.Clear(RndB);
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Challenge);
    TCardCrypto.Clear(Rotated);
    TCardCrypto.Clear(Received);
  end;
end;

procedure TDesfireCardReader.Start(const AAid: Cardinal;
  const AAuthenticate: Boolean);
var
  Data, Selected: TBytes;
  Owns: Boolean;
begin
  if FBusy or (FTransport = nil) or (AAid > $FFFFFF) then
    InvalidDesfire;
  if AAuthenticate then
    ValidateCredentials;
  if not Supports(FTransport, ICardTransaction, FTransaction) then
    InvalidDesfire;
  FBusy := True;
  FActiveTransport := FTransport;
  FWriteAttempt := False;
  FAuthenticated := False;
  FReauthenticated := False;
  Owns := False;
  Data := nil;
  Selected := nil;
  try
    try
      FTransaction.BeginTransaction;
      Owns := True;
      Data := TDesfireCodec.ApplicationBytes(AAid);
      Selected := Exchange($5A, Data, 0, False);
      if Length(Selected) <> 0 then
        InvalidDesfire;
      if AAuthenticate and (FSecurity <> dfsPublic) then
        Authenticate;
    except
      if Owns then
        try
          FTransaction.EndTransaction;
        except
        end;
      TDesfireEv2Codec.ClearKeys(FKeys);
      TCardCrypto.Clear(FTi);
      TCardCrypto.Clear(FSessionIv);
      FActiveTransport := nil;
      FTransaction := nil;
      FBusy := False;
      FAuthenticated := False;
      raise;
    end;
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Selected);
  end;
end;

procedure TDesfireCardReader.Finish(const ASucceeded: Boolean);
begin
  try
    if ASucceeded then
      FTransaction.EndTransaction
    else
      try
        FTransaction.EndTransaction;
      except
      end;
  finally
    TDesfireEv2Codec.ClearKeys(FKeys);
    TCardCrypto.Clear(FTi);
    TCardCrypto.Clear(FTmacInput);
    FTmacCapture := False;
    TCardCrypto.Clear(FSessionIv);
    FCounter := 0;
    FAuthenticated := False;
    FReauthenticated := False;
    FSessionKeyNumber := 0;
    FActiveTransport := nil;
    FTransaction := nil;
    FBusy := False;
  end;
end;

function TDesfireCardReader.Send(const AInstruction: Byte;
  const AHeader, AData: TBytes; const AMode: TDesfireCommunication;
  const AExpected: Integer; const AWrite: Boolean): TBytes;
var
  Packet, Wire: TBytes;
  Limit: Integer;
  ResponseMode: TDesfireCommunication;
  TmacLength: Integer;
begin
  TmacLength := AExpected;
  if Length(AData) > 0 then TmacLength := Length(AData);
  ReserveTmac(AInstruction, AHeader, TmacLength);
  Result := nil;
  Packet := nil;
  Wire := nil;
  try
    if FAuthenticated and IsDes then
    begin
      Packet := TDesfireDesCodec.EncodeCommand(DesProvider, FKeys.Encryption,
        FSessionIv, AInstruction, AHeader, AData, AMode, AWrite, IsLegacyDes);
      ResponseMode := AMode;
      if AWrite then
      begin
        if IsLegacyDes then
          ResponseMode := dfcPlain
        else
          ResponseMode := dfcMac;
      end;
      Limit := AExpected + 8;
      if IsLegacyDes then
        Limit := AExpected + 4;
      if ResponseMode = dfcPlain then
      begin
        if IsLegacyDes then
          Limit := AExpected;
      end;
      if ResponseMode = dfcFull then
      begin
        if IsLegacyDes then
          Limit := ((AExpected + 2 + 7) div 8) * 8
        else
          Limit := ((AExpected + 4 + 7) div 8) * 8;
      end;
      Wire := Exchange(AInstruction, Packet, Limit, AWrite);
      Result := TDesfireDesCodec.DecodeResponse(DesProvider, FKeys.Encryption,
        FSessionIv, Wire, ResponseMode, AExpected, IsLegacyDes);
    end
    else if FAuthenticated and (FSecurity = dfsEv1Aes) then
    begin
      Packet := TDesfireEv1Codec.EncodeCommand(FProvider, FKeys.Encryption,
        FSessionIv, AInstruction, AHeader, AData, AMode, AWrite);
      Limit := AExpected + 8;
      if (AMode = dfcFull) and not AWrite then
        Limit := ((AExpected + 4 + 15) div 16) * 16;
      Wire := Exchange(AInstruction, Packet, Limit, AWrite);
      if AWrite then
        Result := TDesfireEv1Codec.DecodeResponse(FProvider, FKeys.Encryption,
          FSessionIv, Wire, dfcMac, AExpected)
      else
        Result := TDesfireEv1Codec.DecodeResponse(FProvider, FKeys.Encryption,
          FSessionIv, Wire, AMode, AExpected);
    end
    else if FAuthenticated then
    begin
      Packet := TDesfireEv2Codec.EncodeCommand(FProvider, FKeys, FTi, FCounter,
        AInstruction, AHeader, AData, AMode);
      Limit := AExpected;
      if AMode = dfcFull then
      begin
        if Limit > 0 then
          Limit := ((Limit div 16) + 1) * 16;
      end;
      if AMode <> dfcPlain then
        Inc(Limit, 8);
      Wire := Exchange(AInstruction, Packet, Limit, AWrite);
      Inc(FCounter);
      Result := TDesfireEv2Codec.DecodeResponse(FProvider, FKeys, FTi, FCounter,
        Wire, AMode, AExpected);
    end
    else
    begin
      if (AMode <> dfcPlain) or (Length(AData) <> 0) then
        InvalidDesfire;
      Result := Exchange(AInstruction, AHeader, AExpected, AWrite);
      if Length(Result) <> AExpected then
        InvalidDesfire;
    end;
    if Length(AData) > 0 then TrackTmac(AInstruction, AHeader, AData)
    else TrackTmac(AInstruction, AHeader, Result);
  finally
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(Wire);
  end;
end;

function TDesfireCardReader.Settings(const AFile: Byte): TDesfireFileSettings;
var
  H, Wire, Packet: TBytes;
begin
  if AFile > 31 then
    InvalidDesfire;
  H := nil;
  Wire := nil;
  Packet := nil;
  try
    SetLength(H, 1);
    H[0] := AFile;
    if FAuthenticated and IsDes then
    begin
      Packet := TDesfireDesCodec.EncodeCommand(DesProvider, FKeys.Encryption,
        FSessionIv, $F5, H, nil, dfcPlain, False, IsLegacyDes);
      Wire := Exchange($F5, Packet, 25, False);
      if IsLegacyDes then
        Packet := TDesfireDesCodec.DecodeResponse(DesProvider, FKeys.Encryption,
          FSessionIv, Wire, dfcPlain, Length(Wire), True)
      else
      begin
        if Length(Wire) < 8 then
          InvalidDesfire;
        Packet := TDesfireDesCodec.DecodeResponse(DesProvider, FKeys.Encryption,
          FSessionIv, Wire, dfcMac, Length(Wire) - 8, False);
      end;
      Result := TDesfireCodec.FileSettings(AFile, Packet);
    end
    else if FAuthenticated and (FSecurity = dfsEv1Aes) then
    begin
      Packet := TDesfireEv1Codec.EncodeCommand(FProvider, FKeys.Encryption,
        FSessionIv, $F5, H, nil, dfcPlain, False);
      Wire := Exchange($F5, Packet, 25, False);
      if Length(Wire) < 8 then
        InvalidDesfire;
      Packet := TDesfireEv1Codec.DecodeResponse(FProvider, FKeys.Encryption,
        FSessionIv, Wire, dfcMac, Length(Wire) - 8);
      Result := TDesfireCodec.FileSettings(AFile, Packet);
    end
    else if FAuthenticated then
    begin
      Packet := TDesfireEv2Codec.EncodeCommand(FProvider, FKeys, FTi, FCounter,
        $F5, H, nil, dfcMac);
      Wire := Exchange($F5, Packet, 25, False);
      Inc(FCounter);
      if Length(Wire) < 8 then
        InvalidDesfire;
      Packet := TDesfireEv2Codec.DecodeResponse(FProvider, FKeys, FTi, FCounter,
        Wire, dfcMac, Length(Wire) - 8);
      Result := TDesfireCodec.FileSettings(AFile, Packet);
    end
    else
    begin
      Wire := Exchange($F5, H, 17, False);
      Result := TDesfireCodec.FileSettings(AFile, Wire);
    end;
  finally
    TCardCrypto.Clear(H);
    TCardCrypto.Clear(Wire);
    TCardCrypto.Clear(Packet);
  end;
end;

procedure TDesfireCardReader.CheckAccess(const ASettings: TDesfireFileSettings;
  const AWrite: Boolean);
var
  Key: Byte;
  FreeValue: Boolean;
  function Granted(const K: Byte): Boolean;
  begin
    Result := (K = $E) or (FAuthenticated and (K = FSessionKeyNumber));
  end;

begin
  if FAuthenticated then
  begin
    if Ord(ASettings.Communication) < Ord(FMinimum) then
      InvalidDesfire;
  end
  else if ASettings.Communication <> dfcPlain then
    InvalidDesfire;
  if FAuthenticated and (Length(FRekey) > 0) and not FReauthenticated then
    Authenticate(True);
  if AWrite then
    Key := ASettings.WriteKey
  else
    Key := ASettings.ReadKey;
  FreeValue := not AWrite and (ASettings.FileType = dftValue) and
    ((ASettings.ValueOptions and 2) <> 0);
  if not(Granted(Key) or Granted(ASettings.ReadWriteKey) or FreeValue) then
    InvalidDesfire;
end;

procedure TDesfireCardReader.CheckSettings(const ASettings
  : TDesfireFileSettings);
var
  Current: TDesfireFileSettings;
begin
  Current := Settings(ASettings.FileNumber);
  if not BytesEqual(Current.RawBytes, ASettings.RawBytes) then
    InvalidDesfire;
end;

function TDesfireCardReader.ReadSelected(const ASettings: TDesfireFileSettings;
  const AOffset, ACount: Integer): TBytes;
var
  Cmd: Byte;
begin
  Result := nil;
  if not(ASettings.FileType in [dftStandard, dftBackup]) or (AOffset < 0) or
    (ACount < 1) or (ACount > FMaxTransfer) or
    (AOffset > ASettings.FileBytes - ACount) then
    InvalidDesfire;
  CheckAccess(ASettings, False);
  Cmd := $BD;
  if FAuthenticated and (FSecurity = dfsEv2Aes) then
    Cmd := $AD;
  Result := Send(Cmd, TDesfireCodec.RangeHeader(ASettings.FileNumber, AOffset,
    ACount), nil, ASettings.Communication, ACount, False);
end;

function TDesfireCardReader.ReadVersion: TDesfireVersion;
var
  Snapshot: TDesfireVersion;
  Good: Boolean;
begin
  Result := Default (TDesfireVersion);
  Start(0, False);
  Good := False;
  try
    Snapshot := TDesfireCodec.Version(Exchange($60, nil, 28, False));
    Good := True;
  finally
    Finish(Good);
  end;
  Result := Snapshot;
end;

function TDesfireCardReader.ReadApplicationIds: TDesfireApplicationIds;
var
  Ids: TDesfireApplicationIds;
  Good: Boolean;
  Wire: TBytes;
begin
  Result := nil;
  Start(0, False);
  Good := False;
  Wire := nil;
  try
    if FAuthenticated and (FCounter >= 65535) then
      InvalidDesfire;
    Wire := Exchange($6A, nil, 3072, False);
    if FAuthenticated then
      Inc(FCounter);
    Ids := TDesfireCodec.ApplicationIds(Wire);
    Good := True;
  finally
    TCardCrypto.Clear(Wire);
    Finish(Good);
  end;
  Result := Ids;
end;

function TDesfireCardReader.ReadFiles(const AAid: Cardinal): TDesfireFiles;
var
  Files: TDesfireFiles;
  Ids: TBytes;
  I, J: Integer;
  Good: Boolean;
begin
  Result := nil;
  if (AAid = 0) or (AAid > $FFFFFF) then
    InvalidDesfire;
  ValidateCredentials;
  Start(AAid, False);
  Good := False;
  Ids := nil;
  try
    Ids := Exchange($6F, nil, 32, False);
    if FSecurity <> dfsPublic then
      Authenticate;
    SetLength(Files, Length(Ids));
    for I := 0 to High(Ids) do
    begin
      if Ids[I] > 31 then
        InvalidDesfire;
      for J := 0 to I - 1 do
        if Ids[J] = Ids[I] then
          InvalidDesfire;
      Files[I] := Settings(Ids[I]);
    end;
    Good := True;
  finally
    TCardCrypto.Clear(Ids);
    Finish(Good);
  end;
  Result := Files;
end;

function TDesfireCardReader.ReadData(const AAid: Cardinal; const AFile: Byte;
  const AOffset, ACount: Integer): TBytes;
var
  S: TDesfireFileSettings;
  Data: TBytes;
  Good: Boolean;
begin
  Result := nil;
  if (AAid = 0) or (AAid > $FFFFFF) or (AFile > 31) or (AOffset < 0) or
    (AOffset > $FFFFFF) or (ACount < 1) or (ACount > FMaxTransfer) then
    InvalidDesfire;
  Start(AAid, True);
  Good := False;
  try
    S := Settings(AFile);
    Data := ReadSelected(S, AOffset, ACount);
    CheckSettings(S);
    Good := True;
  finally
    Finish(Good);
  end;
  Result := Data;
end;

function TDesfireCardReader.ReadValue(const AAid: Cardinal;
  const AFile: Byte): Integer;
var
  S: TDesfireFileSettings;
  Data, H: TBytes;
  Value: Integer;
  Good: Boolean;
begin
  if (AAid = 0) or (AAid > $FFFFFF) or (AFile > 31) or (FMaxTransfer < 4) then
    InvalidDesfire;
  Start(AAid, True);
  Good := False;
  Data := nil;
  H := nil;
  try
    S := Settings(AFile);
    if S.FileType <> dftValue then
      InvalidDesfire;
    CheckAccess(S, False);
    SetLength(H, 1);
    H[0] := AFile;
    Data := Send($6C, H, nil, S.Communication, 4, False);
    Value := TDesfireCodec.SignedValue(Data);
    if (Value < S.LowerLimit) or (Value > S.UpperLimit) then
      InvalidDesfire;
    CheckSettings(S);
    Good := True;
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(H);
    Finish(Good);
  end;
  Result := Value;
end;

function TDesfireCardReader.ReadRecords(const AAid: Cardinal; const AFile: Byte;
  const AOffset, ACount: Integer): TBytes;
var
  S: TDesfireFileSettings;
  Data: TBytes;
  Cmd: Byte;
  Good: Boolean;
begin
  Result := nil;
  if (AAid = 0) or (AAid > $FFFFFF) or (AFile > 31) or (AOffset < 0) or
    (AOffset > $FFFFFF) or (ACount < 1) or (ACount > FMaxTransfer) then
    InvalidDesfire;
  Start(AAid, True);
  Good := False;
  try
    S := Settings(AFile);
    if not(S.FileType in [dftLinearRecords, dftCyclicRecords]) then
      InvalidDesfire;
    CheckAccess(S, False);
    if (AOffset > S.CurrentRecords - ACount) or
      (ACount > FMaxTransfer div S.RecordBytes) then
      InvalidDesfire;
    Cmd := $BB;
    if FAuthenticated and (FSecurity = dfsEv2Aes) then
      Cmd := $AB;
    Data := Send(Cmd, TDesfireCodec.RangeHeader(AFile, AOffset, ACount), nil,
      S.Communication, ACount * S.RecordBytes, False);
    CheckSettings(S);
    Good := True;
  finally
    Finish(Good);
  end;
  Result := Data;
end;

procedure TDesfireCardReader.WriteData(const AAid: Cardinal; const AFile: Byte;
  const AOffset: Integer; const AData: TBytes);
var
  S: TDesfireFileSettings;
  Data, Old, Reply, Header: TBytes;
  Good: Boolean;
  Cmd: Byte;
begin
  if (AAid = 0) or (AAid > $FFFFFF) or (AFile > 31) or (AOffset < 0) or
    (AOffset > $FFFFFF) or (Length(AData) < 1) or (Length(AData) > FMaxTransfer)
  then
    InvalidDesfire;
  Data := CopyBytes(AData);
  Old := nil;
  Reply := nil;
  Header := nil;
  try
    Start(AAid, True);
    Good := False;
    try
      try
        S := Settings(AFile);
        if S.FileType <> dftStandard then
          InvalidDesfire;
        CheckAccess(S, True);
        Old := ReadSelected(S, AOffset, Length(Data));
        CheckSettings(S);
        if not BytesEqual(Old, Data) then
        begin
          Header := TDesfireCodec.RangeHeader(AFile, AOffset, Length(Data));
          Cmd := $3D;
          if FAuthenticated and (FSecurity = dfsEv2Aes) then
            Cmd := $8D;
          if FAuthenticated then
            Reply := Send(Cmd, Header, Data, S.Communication, 0, True)
          else
          begin
            Reply := Copy(Header, 0, Length(Header));
            SetLength(Reply, Length(Header) + Length(Data));
            Move(Data[0], Reply[Length(Header)], Length(Data));
            Reply := Exchange(Cmd, Reply, 0, True);
          end;
          TCardCrypto.Clear(Old);
          Old := ReadSelected(S, AOffset, Length(Data));
          if not BytesEqual(Old, Data) then
            InvalidDesfire;
          CheckSettings(S);
        end;
        Good := True;
      finally
        Finish(Good);
      end;
    except
      on E: Exception do
      begin
        if FWriteAttempt then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Old);
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Header);
  end;
end;

function SignedBytes(const AValue: Integer): TBytes;
var
  V: Int64;
  I: Integer;
begin
  Result := nil;
  V := AValue;
  if V < 0 then
    Inc(V, Int64($100000000));
  SetLength(Result, 4);
  for I := 0 to 3 do
    Result[I] := (V shr (I * 8)) and $FF;
end;

function OneByte(const AValue: Byte): TBytes;
begin
  Result := nil;
  SetLength(Result, 1);
  Result[0] := AValue;
end;

function Joined(const A, B: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then
    Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then
    Move(B[0], Result[Length(A)], Length(B));
end;

function DefinitionHeader(const D: TDesfireFileDefinition;
  out Command: Byte): TBytes;
var
  Tail: TBytes;
  V: Integer;
  procedure Add24(const N: Integer);
  var
    L: Integer;
  begin
    if (N < 1) or (N > $FFFFFF) then
      InvalidDesfire;
    L := Length(Tail);
    SetLength(Tail, L + 3);
    Tail[L] := N and $FF;
    Tail[L + 1] := (N shr 8) and $FF;
    Tail[L + 2] := N shr 16;
  end;

begin
  Result := nil;
  Command := 0;
  Tail := nil;
  if (D.FileNumber > 31) or (Ord(D.FileType) < 0) or (Ord(D.FileType) > 4) or
    (Ord(D.Communication) < 0) or (Ord(D.Communication) > 2) or (D.ReadKey > 15)
    or (D.WriteKey > 15) or (D.ReadWriteKey > 15) or (D.ChangeKey > 15) then
    InvalidDesfire;
  case D.FileType of
    dftStandard, dftBackup:
      begin
        if (D.LowerLimit <> 0) or (D.UpperLimit <> 0) or (D.InitialValue <> 0)
          or D.LimitedCreditEnabled or (D.RecordBytes <> 0) or
          (D.MaxRecords <> 0) then
          InvalidDesfire;
        Command := $CD;
        if D.FileType = dftBackup then
          Command := $CB;
        Add24(D.FileBytes);
      end;
    dftValue:
      begin
        if (D.FileBytes <> 0) or (D.RecordBytes <> 0) or (D.MaxRecords <> 0) or
          (D.LowerLimit > D.UpperLimit) or (D.InitialValue < D.LowerLimit) or
          (D.InitialValue > D.UpperLimit) then
          InvalidDesfire;
        Command := $CC;
        Tail := Joined(SignedBytes(D.LowerLimit), SignedBytes(D.UpperLimit));
        Tail := Joined(Tail, SignedBytes(D.InitialValue));
        Tail := Joined(Tail, OneByte(Ord(D.LimitedCreditEnabled)));
      end;
    dftLinearRecords, dftCyclicRecords:
      begin
        if (D.FileBytes <> 0) or (D.LowerLimit <> 0) or (D.UpperLimit <> 0) or
          (D.InitialValue <> 0) or D.LimitedCreditEnabled then
          InvalidDesfire;
        Command := $C1;
        if D.FileType = dftCyclicRecords then
          Command := $C0;
        Add24(D.RecordBytes);
        Add24(D.MaxRecords);
      end;
  end;
  V := Ord(D.Communication);
  if D.Communication = dfcFull then
    V := 3;
  SetLength(Result, 4);
  Result[0] := D.FileNumber;
  Result[1] := V;
  Result[2] := (D.ReadWriteKey shl 4) or D.ChangeKey;
  Result[3] := (D.ReadKey shl 4) or D.WriteKey;
  Result := Joined(Result, Tail);
end;

class procedure TDesfireCodec.ValidateDefinition(const ADefinition: TDesfireFileDefinition);
var Command: Byte;
begin
  DefinitionHeader(ADefinition, Command);
end;

function TDesfireCardReader.Metadata(const AInstruction: Byte;
  const AHeader: TBytes; const AMaxBytes: Integer;
  const AMutation: Boolean): TBytes;
var
  Packet, Wire: TBytes;
begin
  if AInstruction = $EB then ReserveTmac(AInstruction, AHeader, 0);
  Result := nil;
  Packet := nil;
  Wire := nil;
  try
    if FAuthenticated and IsDes then
    begin
      Packet := TDesfireDesCodec.EncodeCommand(DesProvider, FKeys.Encryption,
        FSessionIv, AInstruction, AHeader, nil, dfcPlain, False, IsLegacyDes);
      Wire := Exchange(AInstruction, Packet, AMaxBytes + 8, AMutation);
      if IsLegacyDes then
        Result := TDesfireDesCodec.DecodeResponse(DesProvider, FKeys.Encryption,
          FSessionIv, Wire, dfcPlain, Length(Wire), True)
      else
      begin
        if Length(Wire) < 8 then
          InvalidDesfire;
        Result := TDesfireDesCodec.DecodeResponse(DesProvider, FKeys.Encryption,
          FSessionIv, Wire, dfcMac, Length(Wire) - 8, False);
      end;
    end
    else if FAuthenticated and (FSecurity = dfsEv2Aes) then
    begin
      Packet := TDesfireEv2Codec.EncodeCommand(FProvider, FKeys, FTi, FCounter,
        AInstruction, AHeader, nil, dfcMac);
      Wire := Exchange(AInstruction, Packet, AMaxBytes + 8, AMutation);
      Inc(FCounter);
      if Length(Wire) < 8 then
        InvalidDesfire;
      Result := TDesfireEv2Codec.DecodeResponse(FProvider, FKeys, FTi, FCounter,
        Wire, dfcMac, Length(Wire) - 8);
    end
    else if FAuthenticated then
    begin
      Packet := TDesfireEv1Codec.EncodeCommand(FProvider, FKeys.Encryption,
        FSessionIv, AInstruction, AHeader, nil, dfcPlain, False);
      Wire := Exchange(AInstruction, Packet, AMaxBytes + 8, AMutation);
      if Length(Wire) < 8 then
        InvalidDesfire;
      Result := TDesfireEv1Codec.DecodeResponse(FProvider, FKeys.Encryption,
        FSessionIv, Wire, dfcMac, Length(Wire) - 8);
    end
    else
      Result := Exchange(AInstruction, AHeader, AMaxBytes, AMutation);
    if AInstruction = $EB then TrackTmac(AInstruction, AHeader, nil);
  finally
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(Wire);
  end;
end;

function TDesfireCardReader.OpenSession(const AAid: Cardinal;
  const AAccess: TDesfireSessionAccess): IDesfireSession;
begin
  Result := nil;
  if FBusy then
    InvalidDesfire;
  Result := TDesfireSession.Create(Self, AAid, AAccess);
end;

function TDesfireCardReader.OpenManagementSession(const AAid: Cardinal)
  : IDesfireManagement;
var
  Session: IDesfireSession;
begin
  Session := OpenSession(AAid, dsaManage);
  if not Supports(Session, IDesfireManagement, Result) then
    InvalidDesfire;
end;

function TDesfireCardReader.OpenApplicationManagementSession
  (const AAid: Cardinal): IDesfireApplicationManagement;
var
  Session: IDesfireSession;
begin
  Session := OpenSession(AAid, dsaManage);
  if not Supports(Session, IDesfireApplicationManagement, Result) then
    InvalidDesfire;
end;

function TDesfireCardReader.OpenDesManagementSession(const AAid: Cardinal)
  : IDesfireDesManagement;
var
  Session: IDesfireSession;
begin
  if not IsDes then
    InvalidDesfire;
  Session := OpenSession(AAid, dsaManage);
  if not Supports(Session, IDesfireDesManagement, Result) then
    InvalidDesfire;
end;

constructor TDesfireSession.Create(const AReader: TDesfireCardReader;
  const AAid: Cardinal; const AAccess: TDesfireSessionAccess; const ATmacFile: Integer;
  const ATmacUid, ATmacKey: TBytes; const APreviousCounter: Cardinal);
var
  Ids, Reply: TBytes;
  I: Integer;
  S: TDesfireFileSettings;
  TmacFound: Boolean;
  Uid: TBytes;
begin
  inherited Create;
  if (AAid > $FFFFFF) or (Ord(AAccess) < 0) or (Ord(AAccess) > 3) or
    ((AAid = 0) and (AAccess in [dsaFreshTransaction, dsaDiscardPending])) or
    ((AAid = 0) and ((AReader.FKeyNumber <> 0) or (Length(AReader.FRekey) > 0)))
  then
    InvalidDesfire;
  FTmacFile := ATmacFile;
  if (ATmacFile < -1) or (ATmacFile > 31) then InvalidDesfire;
  if ATmacFile >= 0 then
  begin
    if (AAccess <> dsaFreshTransaction) or (AAid = 0) or (AReader.FSecurity <> dfsEv2Aes) or
      (Length(ATmacUid) <> 7) or (Length(ATmacKey) <> 16) or (APreviousCounter = High(Cardinal)) then InvalidDesfire;
    FTmacUid := CopyBytes(ATmacUid);
    FTmacKey := CopyBytes(ATmacKey);
    FTmacPreviousCounter := APreviousCounter;
  end;
  FEngine := TDesfireCardReader.Create(nil);
  FThread := NativeUInt(TThread.CurrentThread.ThreadID);
  FAid := AAid;
  FAccess := AAccess;
  FEngine.FTransport := AReader.FTransport;
  FEngine.FProvider := AReader.FProvider;
  FEngine.FKey := CopyBytes(AReader.FKey);
  FEngine.FRekey := CopyBytes(AReader.FRekey);
  FEngine.FKeyNumber := AReader.FKeyNumber;
  FEngine.FRekeyNumber := AReader.FRekeyNumber;
  FEngine.FSecurity := AReader.FSecurity;
  FEngine.FMinimum := AReader.FMinimum;
  FEngine.FMaxTransfer := AReader.FMaxTransfer;
  FEngine.FMaxFrameData := AReader.FMaxFrameData;
  Ids := nil;
  Reply := nil;
  try
    try
      FEngine.Start(FAid, True);
      if FAccess in [dsaFreshTransaction, dsaDiscardPending] then
      begin
        // Reject TMAC/extended files before changing the application's pending state.
        Ids := FileIds;
        TmacFound := False;
        for I := 0 to High(Ids) do
        begin
          if Ids[I] = FTmacFile then
          begin
            FTmacSettings := TmacMetadata(Ids[I]);
            TmacFound := True;
          end
          else
          begin
            S := FEngine.Settings(Ids[I]);
            if not(S.FileType in [dftStandard, dftBackup, dftValue,
              dftLinearRecords, dftCyclicRecords]) then InvalidDesfire;
            if (FTmacFile >= 0) and (S.FileType in [dftLinearRecords, dftCyclicRecords]) and
              (S.RecordBytes mod 16 <> 0) then InvalidDesfire;
          end;
        end;
        if FTmacFile >= 0 then
        begin
          if not TmacFound then InvalidDesfire;
          if FTmacSettings.CounterLimitEnabled and
            (FTmacPreviousCounter >= FTmacSettings.CounterLimit) then InvalidDesfire;
          Uid := FEngine.Send($51, nil, nil, dfcFull, 7, False);
          if not BytesEqual(Uid, FTmacUid) then InvalidDesfire;
          FEngine.FTmacExcludedFile := FTmacFile;
          FEngine.FTmacCapture := True;
        end;
        if FAccess = dsaDiscardPending then
        begin
          Reply := FEngine.Metadata($A7, nil, 0, True);
          if Length(Reply) <> 0 then
            InvalidDesfire;
          FEngine.FWriteAttempt := False;
        end;
      end;
    except
      on E: Exception do
      begin
        if FEngine.FWriteAttempt then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Ids);
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Uid);
  end;
end;

destructor TDesfireSession.Destroy;
begin
  if FEngine <> nil then
  begin
    if FEngine.FBusy then
      FEngine.Finish(False);
    FEngine.Free;
  end;
  ClearJournal;
  inherited Destroy;
end;

procedure TDesfireSession.ClearJournal;
var
  I: Integer;
begin
  for I := 0 to High(FJournal) do
    TCardCrypto.Clear(FJournal[I].Expected);
  FJournal := nil;
  TCardCrypto.Clear(FTmacKey);
  TCardCrypto.Clear(FTmacUid);
end;

function TDesfireSession.Enter: Integer;
begin
  if (FOutcome <> dsoActive) or FInCall or (FEngine = nil) or
    not FEngine.FBusy or (NativeUInt(TThread.CurrentThread.ThreadID) <> FThread)
  then
    InvalidDesfire;
  FInCall := True;
  Result := FEngine.FAttempts;
end;

function TDesfireSession.Poison(const ABefore: Integer): Boolean;
begin
  Result := False;
  if FEngine.FAttempts = ABefore then
    Exit;
  Result := FPending or FEngine.FWriteAttempt;
  if FOutcome = dsoActive then
    if Result then
      FOutcome := dsoUncertain
    else
      FOutcome := dsoClosed;
  if FEngine.FBusy then
    FEngine.Finish(False);
  ClearJournal;
end;

procedure TDesfireSession.RequireOwner;
begin
  if not(FAccess in [dsaFreshTransaction, dsaDiscardPending]) or (FAid = 0) then
    InvalidDesfire;
end;

procedure TDesfireSession.RequireManagement;
var
  S: TDesfireApplicationSettings;
begin
  if FAccess <> dsaManage then
    InvalidDesfire;
  S := AppSettings;
  if ((S.KeySettings and 4) = 0) and
    not(FEngine.FAuthenticated and (FEngine.FSessionKeyNumber = 0)) then
    InvalidDesfire;
end;

function TDesfireSession.AppSettings: TDesfireApplicationSettings;
var
  Wire: TBytes;
begin
  Result := Default (TDesfireApplicationSettings);
  Wire := FEngine.Metadata($45, nil, 7, False);
  TDesfireExtensionCodec.ValidateApplicationSettings(Wire);
  Result.KeySettings := Wire[0];
  Result.KeyConfiguration := Wire[1];
  Result.RawBytes := CopyBytes(Wire);
end;

function TDesfireSession.FileIds: TBytes;
var
  I, J: Integer;
begin
  if FAid = 0 then
    InvalidDesfire;
  Result := FEngine.Metadata($6F, nil, 32, False);
  for I := 0 to High(Result) do
  begin
    if Result[I] > 31 then
      InvalidDesfire;
    for J := 0 to I - 1 do
      if Result[I] = Result[J] then
        InvalidDesfire;
  end;
end;

function TDesfireSession.Granted(const AKey: Byte): Boolean;
begin
  Result := (AKey = $E) or (FEngine.FAuthenticated and
    (AKey = FEngine.FSessionKeyNumber));
end;

procedure TDesfireSession.ValueAccess(const S: TDesfireFileSettings;
  const ACommand: Byte);
var
  Allowed: Boolean;
begin
  if S.FileType <> dftValue then
    InvalidDesfire;
  if FEngine.FAuthenticated then
  begin
    if Ord(S.Communication) < Ord(FEngine.FMinimum) then
      InvalidDesfire;
    if (Length(FEngine.FRekey) > 0) and not FEngine.FReauthenticated then
      FEngine.Authenticate(True);
  end
  else if S.Communication <> dfcPlain then
    InvalidDesfire;
  Allowed := Granted(S.ReadWriteKey);
  case ACommand of
    $0C:
      ; // Credit specifically requires ReadWrite, not just Write.
    $1C:
      Allowed := Allowed or Granted(S.WriteKey);
    $DC, $6C:
      Allowed := Allowed or Granted(S.WriteKey) or Granted(S.ReadKey);
  else
    InvalidDesfire;
  end;
  if (ACommand = $6C) and ((S.ValueOptions and 2) <> 0) then
    Allowed := True;
  if not Allowed then
    InvalidDesfire;
end;

function TDesfireSession.Value(const S: TDesfireFileSettings): Integer;
var
  B: TBytes;
begin
  if FEngine.FMaxTransfer < 4 then
    InvalidDesfire;
  ValueAccess(S, $6C);
  B := nil;
  try
    B := FEngine.Send($6C, OneByte(S.FileNumber), nil, S.Communication,
      4, False);
    Result := TDesfireCodec.SignedValue(B);
    if (Result < S.LowerLimit) or (Result > S.UpperLimit) then
      InvalidDesfire;
  finally
    TCardCrypto.Clear(B);
  end;
end;

function TDesfireSession.Records(const S: TDesfireFileSettings;
  const AOffset, ACount: Integer): TBytes;
var
  Cmd: Byte;
begin
  Result := nil;
  if not(S.FileType in [dftLinearRecords, dftCyclicRecords]) or (AOffset < 0) or
    (ACount < 1) or (AOffset > S.CurrentRecords - ACount) or
    (ACount > FEngine.FMaxTransfer div S.RecordBytes) then
    InvalidDesfire;
  FEngine.CheckAccess(S, False);
  Cmd := $BB;
  if FEngine.FSecurity = dfsEv2Aes then
    Cmd := $AB;
  Result := FEngine.Send(Cmd, TDesfireCodec.RangeHeader(S.FileNumber, AOffset,
    ACount), nil, S.Communication, ACount * S.RecordBytes, False);
end;

procedure TDesfireSession.CheckStatic(const A, B: TDesfireFileSettings);
var
  Left, Right: TBytes;
begin
  Left := CopyBytes(A.RawBytes);
  Right := CopyBytes(B.RawBytes);
  if (A.FileType <> B.FileType) or (Length(Left) <> Length(Right)) then
    InvalidDesfire;
  case A.FileType of
    dftValue:
      begin
        FillChar(Left[12], 4, 0);
        FillChar(Right[12], 4, 0);
      end;
    dftLinearRecords, dftCyclicRecords:
      begin
        FillChar(Left[10], 3, 0);
        FillChar(Right[10], 3, 0);
      end;
  end;
  if not BytesEqual(Left, Right) then
    InvalidDesfire;
end;

function TDesfireSession.JournalBytes: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FJournal) do
    Inc(Result, Length(FJournal[I].Expected));
end;

function TDesfireSession.Journal(const S: TDesfireFileSettings): Integer;
var
  B: TBytes;
  Required: Integer;
begin
  for Result := 0 to High(FJournal) do
    if FJournal[Result].Settings.FileNumber = S.FileNumber then
    begin
      CheckStatic(FJournal[Result].Settings, S);
      Exit;
    end;
  case S.FileType of
    dftBackup:
      Required := S.FileBytes;
    dftValue:
      Required := 4;
    dftLinearRecords, dftCyclicRecords:
      begin
        if S.CurrentRecords > FEngine.FMaxTransfer div S.RecordBytes then
          InvalidDesfire;
        Required := S.CurrentRecords * S.RecordBytes;
      end;
  else
    InvalidDesfire;
    Required := 0;
  end;
  if Required > FEngine.FMaxTransfer - JournalBytes then
    InvalidDesfire;
  B := nil;
  try
    case S.FileType of
      dftBackup:
        B := FEngine.ReadSelected(S, 0, S.FileBytes);
      dftValue:
        B := SignedBytes(Value(S));
      dftLinearRecords, dftCyclicRecords:
        if Required > 0 then
          B := Records(S, 0, S.CurrentRecords)
        else
          FEngine.CheckAccess(S, False);
    end;
    FEngine.CheckSettings(S);
    Result := Length(FJournal);
    SetLength(FJournal, Result + 1);
    FJournal[Result].Settings := S;
    FJournal[Result].Expected := B;
    B := nil;
  finally
    TCardCrypto.Clear(B);
  end;
end;

function TDesfireSession.GetOutcome: TDesfireSessionOutcome;
begin
  Result := FOutcome;
end;

function TDesfireSession.GetVerificationSucceeded: Boolean;
begin
  Result := FVerified;
end;

function TDesfireSession.GetPendingChanges: Boolean;
begin
  Result := FPending or ((FTmacFile >= 0) and (Length(FEngine.FTmacInput) > 0));
end;

procedure TDesfireSession.Close;
begin
  if FOutcome <> dsoActive then
    Exit;
  if FInCall or (NativeUInt(TThread.CurrentThread.ThreadID) <> FThread) then
    InvalidDesfire;
  if GetPendingChanges then
    FOutcome := dsoUncertain
  else
    FOutcome := dsoClosed;
  try
    FEngine.Finish(True);
  finally
    ClearJournal;
  end;
end;

function TDesfireSession.ReadApplicationIds: TDesfireApplicationIds;
var
  Before: Integer;
begin
  Before := Enter;
  try
    try
      Result := nil;
      if FAid <> 0 then
        InvalidDesfire;
      Result := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil,
        3072, False));
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadApplicationSettings: TDesfireApplicationSettings;
var
  Before: Integer;
begin
  Before := Enter;
  try
    try
      Result := AppSettings;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadFiles: TDesfireFiles;
var
  Before: Integer;
  Ids: TBytes;
  I: Integer;
begin
  Before := Enter;
  try
    try
      Result := nil;
      Ids := FileIds;
      SetLength(Result, Length(Ids));
      for I := 0 to High(Ids) do
        Result[I] := FEngine.Settings(Ids[I]);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadData(const AFile: Byte;
  const AOffset, ACount: Integer): TBytes;
var
  Before: Integer;
  S: TDesfireFileSettings;
begin
  Before := Enter;
  try
    try
      Result := nil;
      if (AFile > 31) or (AOffset < 0) or (ACount < 1) or
        (ACount > FEngine.FMaxTransfer) then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      Result := FEngine.ReadSelected(S, AOffset, ACount);
      FEngine.CheckSettings(S);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadValue(const AFile: Byte): Integer;
var
  Before: Integer;
  S: TDesfireFileSettings;
begin
  Before := Enter;
  try
    try
      if (AFile > 31) or (FEngine.FMaxTransfer < 4) then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      Result := Value(S);
      FEngine.CheckSettings(S);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadRecords(const AFile: Byte;
  const AOffset, ACount: Integer): TBytes;
var
  Before: Integer;
  S: TDesfireFileSettings;
begin
  Before := Enter;
  try
    try
      Result := nil;
      if (AFile > 31) or (AOffset < 0) or (ACount < 1) then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      Result := Records(S, AOffset, ACount);
      FEngine.CheckSettings(S);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.WriteStandardDataVerified(const AFile: Byte; const AOffset: Integer;
  const AExpected, AData: TBytes);
var
  Before, Index, I, Left, Right, Size: Integer;
  S: TDesfireFileSettings;
  Expected, Data, Actual, Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if (FTmacFile < 0) or (FMutations >= 256) or (AFile > 31) or (AOffset < 0) or
        (Length(AData) < 1) or (Length(AExpected) <> Length(AData)) or
        (Length(AData) > FEngine.FMaxTransfer) then InvalidDesfire;
      Expected := CopyBytes(AExpected);
      Data := CopyBytes(AData);
      Size := Length(Data);
      S := FEngine.Settings(AFile);
      if (S.FileType <> dftStandard) or (AOffset > S.FileBytes - Size) then InvalidDesfire;
      FEngine.CheckAccess(S, True);
      Actual := FEngine.ReadSelected(S, AOffset, Size);
      FEngine.CheckSettings(S);
      if not BytesEqual(Actual, Expected) then InvalidDesfire;
      if BytesEqual(Expected, Data) then Exit;
      for I := 0 to High(FJournal) do
        if FJournal[I].Settings.FileNumber = AFile then CheckStatic(FJournal[I].Settings, S);
      if (Length(FJournal) >= 256) or (Size > FEngine.FMaxTransfer - JournalBytes) then InvalidDesfire;
      Index := Length(FJournal);
      SetLength(FJournal, Index + 1);
      FJournal[Index].Settings := S;
      FJournal[Index].Offset := AOffset;
      FJournal[Index].Expected := CopyBytes(Data);
      Reply := FEngine.Send($8D, TDesfireCodec.RangeHeader(AFile, AOffset, Size),
        Data, S.Communication, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      FPending := True;
      Inc(FMutations);
      for I := 0 to Index - 1 do
        if FJournal[I].Settings.FileNumber = AFile then
        begin
          Left := AOffset;
          if FJournal[I].Offset > Left then Left := FJournal[I].Offset;
          Right := AOffset + Size;
          if FJournal[I].Offset + Length(FJournal[I].Expected) < Right then
            Right := FJournal[I].Offset + Length(FJournal[I].Expected);
          if Right > Left then
            Move(Data[Left - AOffset], FJournal[I].Expected[Left - FJournal[I].Offset], Right - Left);
        end;
      TCardCrypto.Clear(Actual);
      Actual := FEngine.ReadSelected(S, AOffset, Size);
      if not BytesEqual(Actual, Data) then InvalidDesfire;
      FEngine.CheckSettings(S);
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Actual);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

procedure TDesfireSession.WriteBackup(const AFile: Byte; const AOffset: Integer;
  const AData: TBytes);
var
  Before: Integer;
  S: TDesfireFileSettings;
  Index: Integer;
  Cmd: Byte;
  Data, Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if FMutations >= 256 then
        InvalidDesfire;
      if (AFile > 31) or (AOffset < 0) or (Length(AData) < 1) or
        (Length(AData) > FEngine.FMaxTransfer) then
        InvalidDesfire;
      Data := CopyBytes(AData);
      S := FEngine.Settings(AFile);
      if (S.FileType <> dftBackup) or (AOffset > S.FileBytes - Length(Data))
      then
        InvalidDesfire;
      FEngine.CheckAccess(S, True);
      Index := Journal(S);
      if not BytesEqual(Copy(FJournal[Index].Expected, AOffset, Length(Data)),
        Data) then
      begin
        Cmd := $3D;
        if FEngine.FSecurity = dfsEv2Aes then
          Cmd := $8D;
        if FEngine.FAuthenticated then
          Reply := FEngine.Send(Cmd, TDesfireCodec.RangeHeader(AFile, AOffset,
            Length(Data)), Data, S.Communication, 0, True)
        else
          Reply := FEngine.Metadata(Cmd, Joined(TDesfireCodec.RangeHeader(AFile,
            AOffset, Length(Data)), Data), 0, True);
        Move(Data[0], FJournal[Index].Expected[AOffset], Length(Data));
        FPending := True;
        Inc(FMutations);
      end;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

procedure TDesfireSession.AdjustValue(const AFile: Byte; const AAmount: Integer;
  const ACommand: Byte);
var
  Before: Integer;
  S: TDesfireFileSettings;
  Index: Integer;
  Expected: Int64;
  Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if FMutations >= 256 then
        InvalidDesfire;
      if (AFile > 31) or (AAmount < 1) then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      ValueAccess(S, ACommand);
      Index := Journal(S);
      if ACommand = $1C then
        if ((S.ValueOptions and 1) = 0) or FJournal[Index].UsedLimitedCredit or
          (AAmount > S.LimitedCreditValue) then
          InvalidDesfire;
      Expected := TDesfireCodec.SignedValue(FJournal[Index].Expected);
      if ACommand = $DC then
        Dec(Expected, AAmount)
      else
        Inc(Expected, AAmount);
      if (Expected < S.LowerLimit) or (Expected > S.UpperLimit) then
        InvalidDesfire;
      if FEngine.FAuthenticated then
        Reply := FEngine.Send(ACommand, OneByte(AFile), SignedBytes(AAmount),
          S.Communication, 0, True)
      else
        Reply := FEngine.Metadata(ACommand, Joined(OneByte(AFile),
          SignedBytes(AAmount)), 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      TCardCrypto.Clear(FJournal[Index].Expected);
      FJournal[Index].Expected := SignedBytes(Integer(Expected));
      FJournal[Index].UsedLimitedCredit := FJournal[Index].UsedLimitedCredit or
        (ACommand = $1C);
      FPending := True;
      Inc(FMutations);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.Credit(const AFile: Byte; const AAmount: Integer);
begin
  AdjustValue(AFile, AAmount, $0C);
end;

procedure TDesfireSession.Debit(const AFile: Byte; const AAmount: Integer);
begin
  AdjustValue(AFile, AAmount, $DC);
end;

procedure TDesfireSession.LimitedCredit(const AFile: Byte;
  const AAmount: Integer);
begin
  AdjustValue(AFile, AAmount, $1C);
end;

procedure TDesfireSession.StageCyclicRecordUpdate(const AFile: Byte; const ARecord: Integer;
  const AExpected, AData: TBytes);
var
  Before, Index, Position: Integer;
  S: TDesfireFileSettings;
  Expected, Data, Header, Reply, Current: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if (FEngine.FSecurity <> dfsEv2Aes) or (FMutations >= 256) or (AFile > 31) or
        (ARecord < 0) or (Length(AExpected) <> 16) or (Length(AData) <> 16) then InvalidDesfire;
      Expected := CopyBytes(AExpected);
      Data := CopyBytes(AData);
      S := FEngine.Settings(AFile);
      if (S.FileType <> dftCyclicRecords) or (S.RecordBytes <> 16) or
        (ARecord >= S.CurrentRecords) or not Granted(S.ReadWriteKey) then InvalidDesfire;
      FEngine.CheckAccess(S, True);
      Index := Journal(S);
      if not (FJournal[Index].RecordOperation in [0, 3]) or
        ((FJournal[Index].RecordOperation = 3) and (FJournal[Index].UpdatedRecord <> ARecord)) then InvalidDesfire;
      Position := ARecord * 16;
      Current := Copy(FJournal[Index].Expected, Position, 16);
      if not BytesEqual(Current, Expected) then InvalidDesfire;
      if BytesEqual(Current, Data) then Exit;
      Header := TDesfireCodec.RangeHeader(AFile, ARecord, 16);
      SetLength(Header, 10);
      Header[4] := 0;
      Header[7] := 16;
      Reply := FEngine.Send($BA, Header, Data, S.Communication, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      Move(Data[0], FJournal[Index].Expected[Position], 16);
      FJournal[Index].RecordOperation := 3;
      FJournal[Index].UpdatedRecord := ARecord;
      FPending := True;
      Inc(FMutations);
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Current);
    FInCall := False;
  end;
end;

function TDesfireCardReader.OpenRecordUpdateSession(const AAid: Cardinal;
  const AAcknowledgeFresh: Boolean): IDesfireRecordUpdateSession;
var
  Session: IDesfireSession;
begin
  if (FSecurity <> dfsEv2Aes) or not AAcknowledgeFresh or (AAid = 0) then InvalidDesfire;
  Session := OpenSession(AAid, dsaFreshTransaction);
  Result := Session as IDesfireRecordUpdateSession;
end;

procedure TDesfireSession.AppendRecord(const AFile: Byte; const AData: TBytes);
var
  Before: Integer;
  S: TDesfireFileSettings;
  Index, Count, OldBytes: Integer;
  Cmd: Byte;
  Data, Expected, Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if FMutations >= 256 then
        InvalidDesfire;
      if (AFile > 31) or (Length(AData) < 1) or
        (Length(AData) > FEngine.FMaxTransfer) then
        InvalidDesfire;
      Data := CopyBytes(AData);
      S := FEngine.Settings(AFile);
      if not(S.FileType in [dftLinearRecords, dftCyclicRecords]) or
        (Length(Data) <> S.RecordBytes) then
        InvalidDesfire;
      FEngine.CheckAccess(S, True);
      Index := Journal(S);
      if FJournal[Index].RecordOperation = 3 then InvalidDesfire;
      Count := Length(FJournal[Index].Expected) div S.RecordBytes;
      if (S.FileType = dftLinearRecords) and (Count >= S.MaxRecords) then
        InvalidDesfire;
      OldBytes := Length(FJournal[Index].Expected);
      if Count >= S.MaxRecords then
        Dec(OldBytes, S.RecordBytes);
      if Length(Data) + OldBytes > FEngine.FMaxTransfer -
        (JournalBytes - Length(FJournal[Index].Expected)) then
        InvalidDesfire;
      Expected := Joined(Data, Copy(FJournal[Index].Expected, 0, OldBytes));
      Cmd := $3B;
      if FEngine.FSecurity = dfsEv2Aes then
        Cmd := $8B;
      if FEngine.FAuthenticated then
        Reply := FEngine.Send(Cmd, TDesfireCodec.RangeHeader(AFile, 0,
          Length(Data)), Data, S.Communication, 0, True)
      else
        Reply := FEngine.Metadata(Cmd, Joined(TDesfireCodec.RangeHeader(AFile,
          0, Length(Data)), Data), 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      TCardCrypto.Clear(FJournal[Index].Expected);
      FJournal[Index].Expected := Expected;
      Expected := nil;
      FJournal[Index].RecordOperation := 1;
      FPending := True;
      Inc(FMutations);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Expected);
    FInCall := False;
  end;
end;

procedure TDesfireSession.ClearRecords(const AFile: Byte);
var
  Before: Integer;
  S: TDesfireFileSettings;
  Index: Integer;
  Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if FMutations >= 256 then
        InvalidDesfire;
      if AFile > 31 then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      if not(S.FileType in [dftLinearRecords, dftCyclicRecords]) then
        InvalidDesfire;
      FEngine.CheckAccess(S, True);
      Index := Journal(S);
      if FJournal[Index].RecordOperation = 3 then InvalidDesfire;
      if Length(FJournal[Index].Expected) > 0 then
      begin
        Reply := FEngine.Metadata($EB, OneByte(AFile), 0, True);
        if Length(Reply) <> 0 then
          InvalidDesfire;
        TCardCrypto.Clear(FJournal[Index].Expected);
        FJournal[Index].RecordOperation := 2;
        FPending := True;
        Inc(FMutations);
      end;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.Commit;
begin
  CommitInternal(False);
end;

function TDesfireSession.CommitTransactionMacVerified: TDesfireTmacRecord;
begin
  if FTmacFile < 0 then InvalidDesfire;
  Result := CommitInternal(True);
end;

function TDesfireSession.CommitInternal(const ATmac: Boolean): TDesfireTmacRecord;
var
  Before: Integer;
  Reply, Header, Actual, Input, Mac: TBytes;
  TmacNow: TDesfireTmacSettings;
  ResponseLength: Integer;
  I, Count: Integer;
  S: TDesfireFileSettings;
begin
  Result := Default(TDesfireTmacRecord);
  Before := Enter;
  try
    try
      RequireOwner;
      if not GetPendingChanges then
        InvalidDesfire;
      Header := nil;
      if FEngine.FSecurity = dfsEv2Aes then
        Header := OneByte(0);
      ResponseLength := 0;
      if ATmac then
      begin
        if (FTmacFile < 0) or (Length(FEngine.FTmacInput) < 1) or
          (Length(FTmacKey) <> 16) then InvalidDesfire;
        TmacNow := TmacMetadata(FTmacFile);
        if not BytesEqual(TmacNow.RawBytes, FTmacSettings.RawBytes) then InvalidDesfire;
        if ((FTmacSettings.AccessRights shr 4) and $F <> $F) and not FReaderIdCommitted then InvalidDesfire;
        Header := OneByte(1);
        ResponseLength := 12;
        Input := CopyBytes(FEngine.FTmacInput);
        FEngine.FTmacCapture := False;
      end
      else if FTmacFile >= 0 then InvalidDesfire;
      Reply := FEngine.Metadata($C7, Header, ResponseLength, True);
      if ATmac then
      begin
        Result := TDesfireExtensionCodec.TmacRecord(Reply);
        Result.SessionProtected := True;
        if Result.Counter <> FTmacPreviousCounter + 1 then InvalidDesfire;
        Mac := TDesfireTmacCrypto.Mac(FEngine.FProvider, FTmacKey, FTmacUid, Result.Counter, Input);
        if not TCardCrypto.EqualSecret(Mac, Result.Mac) then InvalidDesfire;
        Result.KeyVerified := True;
      end
      else if Length(Reply) <> 0 then InvalidDesfire;
      FOutcome := dsoCommitted;
      FPending := False;
      for I := 0 to High(FJournal) do
      begin
        S := FEngine.Settings(FJournal[I].Settings.FileNumber);
        CheckStatic(FJournal[I].Settings, S);
        Actual := nil;
        case S.FileType of
          dftStandard:
            Actual := FEngine.ReadSelected(S, FJournal[I].Offset, Length(FJournal[I].Expected));
          dftBackup:
            Actual := FEngine.ReadSelected(S, 0, S.FileBytes);
          dftValue:
            Actual := SignedBytes(Value(S));
          dftLinearRecords, dftCyclicRecords:
            begin
              Count := Length(FJournal[I].Expected) div S.RecordBytes;
              if S.CurrentRecords <> Count then
                InvalidDesfire;
              if Count > 0 then
                Actual := Records(S, 0, Count);
            end;
        end;
        if not BytesEqual(Actual, FJournal[I].Expected) then
          InvalidDesfire;
        TCardCrypto.Clear(Actual);
        FEngine.CheckSettings(S);
      end;
      FEngine.Finish(True);
      FVerified := True;
      ClearJournal;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Actual);
    TCardCrypto.Clear(Input);
    TCardCrypto.Clear(Mac);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

procedure TDesfireSession.Abort;
var
  Before: Integer;
  Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireOwner;
      if GetPendingChanges then
      begin
        Reply := FEngine.Metadata($A7, nil, 0, True);
        if Length(Reply) <> 0 then
          InvalidDesfire;
      end;
      FOutcome := dsoAborted;
      FPending := False;
      FEngine.Finish(True);
      ClearJournal;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateApplication(const AAid: Cardinal;
  const AKeySettings, AKeyCount: Byte);
begin
  CreateApplicationWithKeyType(AAid, AKeySettings, AKeyCount, daktAes);
end;

procedure TDesfireSession.CreateApplicationWithKeyType(const AAid: Cardinal;
  const AKeySettings, AKeyCount: Byte;
  const AKeyType: TDesfireApplicationKeyType);
var
  Before: Integer;
  Ids: TDesfireApplicationIds;
  I: Integer;
  Found: Boolean;
  Header, Reply: TBytes;
  KeyTypeBits: Byte;
begin
  Before := Enter;
  try
    try
      if (FAccess <> dsaManage) or (FAid <> 0) or (AAid = 0) or (AAid > $FFFFFF)
        or (AKeyCount < 1) or (AKeyCount > 14) or
        (((AKeySettings shr 4) < 14) and ((AKeySettings shr 4) >= AKeyCount))
      then
        InvalidDesfire;
      case AKeyType of
        daktDesOrTwoKey3Des:
          KeyTypeBits := 0;
        daktThreeKey3Des:
          KeyTypeBits := $40;
        daktAes:
          KeyTypeBits := $80;
      else
        raise EDesfireError.Create
          ('Invalid or unsupported DESFire configuration, response or access.');
      end;
      RequireManagement;
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil,
        3072, False));
      for I := 0 to High(Ids) do
        if Ids[I] = AAid then
          InvalidDesfire;
      Header := Joined(TDesfireCodec.ApplicationBytes(AAid),
        Joined(OneByte(AKeySettings), OneByte(KeyTypeBits or AKeyCount)));
      Reply := FEngine.Metadata($CA, Header, 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil,
        3072, False));
      Found := False;
      for I := 0 to High(Ids) do
        Found := Found or (Ids[I] = AAid);
      if not Found then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.DeleteApplication(const AAid: Cardinal);
var
  Before: Integer;
  Ids: TDesfireApplicationIds;
  I: Integer;
  Found: Boolean;
  Reply: TBytes;
begin
  Before := Enter;
  try
    try
      if (FAccess <> dsaManage) or (FAid <> 0) or (AAid = 0) or (AAid > $FFFFFF)
      then
        InvalidDesfire;
      RequireManagement;
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil,
        3072, False));
      Found := False;
      for I := 0 to High(Ids) do
        Found := Found or (Ids[I] = AAid);
      if not Found then
        InvalidDesfire;
      Reply := FEngine.Metadata($DA, TDesfireCodec.ApplicationBytes(AAid),
        0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil,
        3072, False));
      for I := 0 to High(Ids) do
        if Ids[I] = AAid then
          InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateFile(const ADefinition: TDesfireFileDefinition);
var
  Before: Integer;
  Header, Ids, Reply: TBytes;
  Cmd: Byte;
  I: Integer;
  S: TDesfireFileSettings;
begin
  Before := Enter;
  try
    try
      if (FAccess <> dsaManage) or (FAid = 0) then
        InvalidDesfire;
      Header := DefinitionHeader(ADefinition, Cmd);
      RequireManagement;
      Ids := FileIds;
      for I := 0 to High(Ids) do
        if Ids[I] = ADefinition.FileNumber then
          InvalidDesfire;
      Reply := FEngine.Metadata(Cmd, Header, 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      S := FEngine.Settings(ADefinition.FileNumber);
      if (S.FileType <> ADefinition.FileType) or
        (S.Communication <> ADefinition.Communication) or
        (S.ReadKey <> ADefinition.ReadKey) or
        (S.WriteKey <> ADefinition.WriteKey) or
        (S.ReadWriteKey <> ADefinition.ReadWriteKey) or
        (S.ChangeKey <> ADefinition.ChangeKey) or
        (S.FileBytes <> ADefinition.FileBytes) or
        (S.LowerLimit <> ADefinition.LowerLimit) or
        (S.UpperLimit <> ADefinition.UpperLimit) or
        (S.RecordBytes <> ADefinition.RecordBytes) or
        (S.MaxRecords <> ADefinition.MaxRecords) or (S.CurrentRecords <> 0) or
        (S.ValueOptions <> Byte(Ord(ADefinition.LimitedCreditEnabled))) then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.DeleteFile(const AFile: Byte);
var
  Before: Integer;
  Ids, Reply: TBytes;
  I: Integer;
  Found: Boolean;
  S: TDesfireFileSettings;
begin
  Before := Enter;
  try
    try
      if (FAccess <> dsaManage) or (FAid = 0) or (AFile > 31) then
        InvalidDesfire;
      RequireManagement;
      Ids := FileIds;
      Found := False;
      for I := 0 to High(Ids) do
        Found := Found or (Ids[I] = AFile);
      if not Found then
        InvalidDesfire;
      S := FEngine.Settings(AFile);
      if not(S.FileType in [dftStandard, dftBackup, dftValue, dftLinearRecords,
        dftCyclicRecords]) then
        InvalidDesfire;
      Reply := FEngine.Metadata($DF, OneByte(AFile), 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      Ids := FileIds;
      for I := 0 to High(Ids) do
        if Ids[I] = AFile then
          InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.RequireNativeManagement;
begin
  if (FAccess <> dsaManage) or not FEngine.FAuthenticated or
    (Length(FEngine.FRekey) > 0) then
    InvalidDesfire;
end;

function TDesfireCardReader.OpenExtendedManagementSession(const AAid: Cardinal): IDesfireExtendedManagement;
var Session: IDesfireSession;
begin
  if FSecurity <> dfsEv2Aes then InvalidDesfire;
  Session := OpenSession(AAid,dsaManage);
  if not Supports(Session,IDesfireExtendedManagement,Result) then InvalidDesfire;
end;

procedure TDesfireSession.RequireEv2Management;
begin
  RequireAesManagement;
  if FEngine.FSecurity <> dfsEv2Aes then InvalidDesfire;
end;
procedure TDesfireSession.RequireKeySet(const ASet, AKeyNumber: Byte);
var S: TDesfireApplicationSettings;
begin
  RequireEv2Management;
  if FAid = 0 then InvalidDesfire;
  S := AppSettings;
  if (Length(S.RawBytes) <> 7) or (ASet > 15) or (ASet >= S.RawBytes[4]) or
    (AKeyNumber >= (S.KeyConfiguration and 15)) or ((S.KeyConfiguration and $C0) <> $80) then InvalidDesfire;
end;
function TDesfireSession.KeySetVersion(const ASet, AKeyNumber: Byte): Byte;
var H,B: TBytes;
begin
  if ASet = 0 then begin Result := KeyVersion(AKeyNumber); Exit; end;
  SetLength(H,2); H[0] := AKeyNumber or $40; H[1] := ASet;
  B := FEngine.Metadata($64,H,1,False); if Length(B) <> 1 then InvalidDesfire;
  Result := B[0];
end;
function TDesfireSession.ReadKeySetKeyVersion(const ASet, AKeyNumber: Byte): Byte;
var
  Before: Integer;
begin
  Before := Enter;
  try
    try
      RequireKeySet(ASet,AKeyNumber);
      Result := KeySetVersion(ASet,AKeyNumber);
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadKeySetVersionList: TBytes;
var
  Before: Integer;
begin
  Before := Enter;
  try
    try
      RequireKeySet(0,0);
      Result := FEngine.Metadata($64,HexToBytes('4080'),17,False);
      if Length(Result) = 0 then InvalidDesfire;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.InitializeAesKeySet(const ASet: Byte);
var
  Before: Integer;
  H,B: TBytes;
begin
  Before := Enter;
  try
    try
      RequireKeySet(ASet,0);
      if (ASet = 0) or (FEngine.FSessionKeyNumber <> 0) then InvalidDesfire;
      SetLength(H,2); H[0] := ASet; H[1] := 2;
      B := FEngine.Send($56,H,nil,dfcMac,0,True);
      if Length(B) <> 0 then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.FinalizeKeySet(const ASet, AVersion: Byte);
var
  Before: Integer;
  H,B: TBytes;
begin
  Before := Enter;
  try
    try
      RequireKeySet(ASet,0);
      if (ASet = 0) or (FEngine.FSessionKeyNumber <> 0) then InvalidDesfire;
      SetLength(H,2); H[0] := ASet; H[1] := AVersion;
      B := FEngine.Send($57,H,nil,dfcMac,0,True);
      if Length(B) <> 0 then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeInactiveAesKey(const ASet, AKeyNumber, ANewVersion: Byte;
  const ANewKey, AOldKey: TBytes);
var
  Before: Integer;
  H,Body,B,NewKey,OldKey,Crc: TBytes; I: Integer;
begin
  Before := Enter;
  try
    try
      if (ASet = 0) or (Length(ANewKey) <> 16) or (Length(AOldKey) <> 16) then InvalidDesfire;
      NewKey := CopyBytes(ANewKey); OldKey := CopyBytes(AOldKey);
      RequireKeySet(ASet,AKeyNumber);
      if FEngine.FSessionKeyNumber <> 0 then InvalidDesfire;
      SetLength(H,2); H[0] := ASet; H[1] := AKeyNumber;
      SetLength(Body,17); for I := 0 to 15 do Body[I] := NewKey[I] xor OldKey[I]; Body[16] := ANewVersion;
      Crc := TDesfireEv1Codec.Crc32(NewKey); Body := Joined(Body,Crc);
      B := FEngine.Send($C6,H,Body,dfcFull,0,True);
      if Length(B) <> 0 then InvalidDesfire;
      if KeySetVersion(ASet,AKeyNumber) <> ANewVersion then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(NewKey); TCardCrypto.Clear(OldKey); TCardCrypto.Clear(Body); TCardCrypto.Clear(Crc);
    FInCall := False;
  end;
end;

procedure TDesfireSession.RollKeySetVerified(const ASet, AVerifyKeyNumber, AVerifyVersion: Byte;
  const AVerifyKey: TBytes);
var
  Before: Integer;
  Key,H,Packet,B,V: TBytes; S: TDesfireApplicationSettings;
begin
  Before := Enter;
  try
    try
      if (ASet = 0) or (Length(AVerifyKey) <> 16) then InvalidDesfire;
      Key := CopyBytes(AVerifyKey);
      RequireKeySet(ASet,AVerifyKeyNumber);
      S := AppSettings;
      if FEngine.FSessionKeyNumber <> (S.RawBytes[6] and 7) then InvalidDesfire;
      H := OneByte(ASet);
      Packet := TDesfireEv2Codec.EncodeCommand(FEngine.FProvider,FEngine.FKeys,FEngine.FTi,
        FEngine.FCounter,$55,H,nil,dfcMac);
      B := FEngine.Exchange($55,Packet,8,True); Inc(FEngine.FCounter);
      if Length(B) <> 0 then V := TDesfireEv2Codec.DecodeResponse(FEngine.FProvider,
        FEngine.FKeys,FEngine.FTi,FEngine.FCounter,B,dfcMac,0);
      if Length(V) <> 0 then InvalidDesfire;
      FEngine.FAuthenticated := False; FEngine.FKeyNumber := AVerifyKeyNumber;
      TCardCrypto.Clear(FEngine.FKey); FEngine.FKey := CopyBytes(Key);
      FEngine.Authenticate(False);
      if KeyVersion(AVerifyKeyNumber) <> AVerifyVersion then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Key); TCardCrypto.Clear(Packet);
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateApplicationWithKeySets(const AAid: Cardinal;
  const ASettings, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte);
var
  Before: Integer;
  H,B,Expected: TBytes; S: TDesfireApplicationSettings; Ids: TDesfireApplicationIds; I: Integer;
begin
  Before := Enter;
  try
    try
      H := TDesfireExtensionCodec.ApplicationHeader(AAid,ASettings,AKeyCount,ASetCount,ASetVersion,ARollKey);
      RequireEv2Management; if FAid <> 0 then InvalidDesfire; RequireManagement;
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A,nil,3072,False));
      for I := 0 to High(Ids) do if Ids[I] = AAid then InvalidDesfire;
      B := FEngine.Metadata($CA,H,0,True);
      if Length(B) <> 0 then InvalidDesfire;
      FEngine.FAuthenticated := False;
      B := FEngine.Exchange($5A,TDesfireCodec.ApplicationBytes(AAid),0,False);
      if Length(B) <> 0 then InvalidDesfire;
      S := AppSettings; Expected := Copy(H,3,7);
      if not BytesEqual(S.RawBytes,Expected) then InvalidDesfire;
      B := FEngine.Exchange($5A,TDesfireCodec.ApplicationBytes(0),0,False);
      if Length(B) <> 0 then InvalidDesfire;
      FEngine.Authenticate(False); FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.SetConfigurationAcknowledged(const AOption: Byte; const AData: TBytes);
var
  Before: Integer;
  Data,B: TBytes;
begin
  Before := Enter;
  try
    try
      TDesfireExtensionCodec.ValidateConfiguration(AOption,AData);
      RequireEv2Management;
      if (FEngine.FSessionKeyNumber <> 0) or ((AOption <> 9) and (FAid <> 0)) or
        ((AOption = 9) and (FAid = 0)) then InvalidDesfire;
      Data := CopyBytes(AData);
      B := FEngine.Send($5C,OneByte(AOption),Data,dfcFull,0,True);
      if Length(B) <> 0 then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Data);
    FInCall := False;
  end;
end;

function TDesfireSession.ReadSdmSettings(const AFile: Byte): TDesfireSdmSettings;
var
  Before: Integer;
  B: TBytes;
begin
  Before := Enter;
  try
    try
      if (FAid = 0) or (AFile > 31) then InvalidDesfire;
      B := FEngine.Metadata($F5,OneByte(AFile),40,False);
      Result := TDesfireExtensionCodec.DecodeSdmSettings(B);
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeSdmSettingsVerified(const AFile: Byte; const AExpected: TBytes;
  const ADesired: TDesfireSdmSettings);
var
  Before: Integer;
  B,Expected,Body,After: TBytes; Original: TDesfireSdmSettings; S: TDesfireApplicationSettings; I,K: Integer;
begin
  Before := Enter;
  try
    try
      Expected := TDesfireExtensionCodec.EncodeSdmSettings(ADesired);
      Original := TDesfireExtensionCodec.DecodeSdmSettings(AExpected);
      RequireEv2Management; if (FAid = 0) or (AFile > 31) then InvalidDesfire;
      S := AppSettings; K := S.KeyConfiguration and 15;
      for I := 0 to 3 do if (((ADesired.AccessRights shr (I*4)) and 15) < 14) and
        (((ADesired.AccessRights shr (I*4)) and 15) >= K) then InvalidDesfire;
      if (ADesired.FileOption and $40) <> 0 then begin
        for I := 0 to 3 do if I <> 1 then
          if (((ADesired.SdmAccessRights shr (I*4)) and 15) < 14) and
            (((ADesired.SdmAccessRights shr (I*4)) and 15) >= K) then InvalidDesfire;
      end;
      if (ADesired.FileBytes <> Original.FileBytes) or not Granted(Byte(Original.AccessRights and 15)) then InvalidDesfire;
      B := FEngine.Metadata($F5,OneByte(AFile),40,False);
      if not BytesEqual(B,Original.RawBytes) then InvalidDesfire;
      if BytesEqual(B,Expected) then Exit;
      Body := Copy(Expected,1,3); Body := Joined(Body,Copy(Expected,7,Length(Expected)-7));
      B := FEngine.Send($5F,OneByte(AFile),Body,dfcFull,0,True);
      After := FEngine.Metadata($F5,OneByte(AFile),40,False);
      if not BytesEqual(After,Expected) then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadSdmAccessSettings(const AFile: Byte): TDesfireSdmAccessSettings;
var
  Before: Integer;
  Raw: TBytes;
begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      if (FAid = 0) or (AFile > 31) then InvalidDesfire;
      Raw := FEngine.Metadata($F5, OneByte(AFile), 64, False);
      Result := TDesfireExtensionCodec.DecodeSdmAccessSettings(Raw);
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Raw);
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeSdmAccessSettingsVerified(const AFile: Byte; const AExpected: TBytes;
  const ADesired: TDesfireSdmAccessSettings);
var
  Before, I, Key, Count: Integer;
  Original, Chosen: TDesfireSdmAccessSettings;
  App: TDesfireApplicationSettings;
  Expected, Desired, Acquired, Body, Reply: TBytes;
begin
  Before := Enter;
  try
    try
      Expected := CopyBytes(AExpected);
      Desired := TDesfireExtensionCodec.EncodeSdmAccessSettings(ADesired.Sdm, ADesired.Rights);
      Original := TDesfireExtensionCodec.DecodeSdmAccessSettings(Expected);
      Chosen := TDesfireExtensionCodec.DecodeSdmAccessSettings(Desired);
      if (FAid = 0) or (AFile > 31) or (Original.Sdm.FileBytes <> Chosen.Sdm.FileBytes) or
        not Granted(Original.Sdm.AccessRights and $F) then InvalidDesfire;
      RequireFileManagement;
      ValidateRightKeys(Chosen.Rights);
      App := AppSettings;
      Count := App.KeyConfiguration and $F;
      if (Chosen.Sdm.FileOption and $40) <> 0 then
        for I := 0 to 3 do
          if I <> 1 then
          begin
            Key := (Chosen.Sdm.SdmAccessRights shr (I * 4)) and $F;
            if (Key < 14) and (Key >= Count) then InvalidDesfire;
          end;
      Acquired := FEngine.Metadata($F5, OneByte(AFile), 64, False);
      if not BytesEqual(Acquired, Expected) then InvalidDesfire;
      if BytesEqual(Acquired, Desired) then Exit;
      Body := Joined(Copy(Desired, 1, 3), Copy(Desired, 7, Length(Desired) - 7));
      Reply := FEngine.Send($5F, OneByte(AFile), Body, dfcFull, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      TCardCrypto.Clear(Acquired);
      Acquired := FEngine.Metadata($F5, OneByte(AFile), 64, False);
      if not BytesEqual(Acquired, Desired) then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Desired);
    TCardCrypto.Clear(Acquired);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

function TDesfireCardReader.OpenSdmAccessManagementSession(const AAid: Cardinal): IDesfireSdmAccessManagement;
var
  Session: IDesfireFileManagement;
begin
  if AAid = 0 then InvalidDesfire;
  Session := OpenFileManagementSession(AAid);
  Result := Session as IDesfireSdmAccessManagement;
end;

procedure TDesfireSession.RequireAesManagement;
begin
  if (FAccess <> dsaManage) or not FEngine.FAuthenticated or
    not(FEngine.FSecurity in [dfsEv1Aes, dfsEv2Aes]) or
    (Length(FEngine.FRekey) > 0) then
    InvalidDesfire;
end;

function TDesfireSession.KeyVersion(const AKeyNumber: Byte): Byte;
var
  Wire: TBytes;
begin
  Wire := FEngine.Metadata($64, OneByte(AKeyNumber), 1, False);
  if Length(Wire) <> 1 then
    InvalidDesfire;
  Result := Wire[0];
end;

function TDesfireSession.ReadFreeMemory: Integer;
var
  Before: Integer;
  Wire: TBytes;
begin
  Before := Enter;
  try
    try
      if FAid <> 0 then
        InvalidDesfire;
      Wire := FEngine.Metadata($6E, nil, 3, False);
      if Length(Wire) <> 3 then
        InvalidDesfire;
      Result := Le24(Wire, 0);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadKeyVersion(const AKeyNumber: Byte): Byte;
var
  Before: Integer;
  Settings: TDesfireApplicationSettings;
begin
  Before := Enter;
  try
    try
      if (AKeyNumber > 13) or ((FAid = 0) and (AKeyNumber <> 0)) then
        InvalidDesfire;
      Settings := AppSettings;
      if AKeyNumber >= (Settings.KeyConfiguration and $F) then
        InvalidDesfire;
      Result := KeyVersion(AKeyNumber);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeKeySettings(const ASettings: Byte);
var
  Before: Integer;
  Settings, After: TDesfireApplicationSettings;
  Reply: TBytes;
begin
  Before := Enter;
  try
    try
      RequireNativeManagement;
      if FEngine.FSessionKeyNumber <> 0 then
        InvalidDesfire;
      Settings := AppSettings;
      if ((Settings.KeySettings and 8) = 0) or
        (((ASettings shr 4) < 14) and
        ((ASettings shr 4) >= (Settings.KeyConfiguration and $F))) then
        InvalidDesfire;
      Reply := FEngine.Send($54, nil, OneByte(ASettings), dfcFull, 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      After := AppSettings;
      if (After.KeySettings <> ASettings) or
        (After.KeyConfiguration <> Settings.KeyConfiguration) then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeFileAccess(const AFile: Byte;
  const ACommunication: TDesfireCommunication;
  const AReadKey, AWriteKey, AReadWriteKey, AChangeKey: Byte);
var
  Before, KeyCount: Integer;
  Original, After: TDesfireFileSettings;
  Body, Expected, Reply: TBytes;
  Mode: TDesfireCommunication;
  Application: TDesfireApplicationSettings;
begin
  Before := Enter;
  try
    try
      RequireNativeManagement;
      if (FAid = 0) or (AFile > 31) or (Ord(ACommunication) < 0) or
        (Ord(ACommunication) > 2) or (AReadKey > 15) or (AWriteKey > 15) or
        (AReadWriteKey > 15) or (AChangeKey > 15) then
        InvalidDesfire;
      Application := AppSettings;
      KeyCount := Application.KeyConfiguration and $F;
      if ((AReadKey < 14) and (AReadKey >= KeyCount)) or
        ((AWriteKey < 14) and (AWriteKey >= KeyCount)) or
        ((AReadWriteKey < 14) and (AReadWriteKey >= KeyCount)) or
        ((AChangeKey < 14) and (AChangeKey >= KeyCount)) then
        InvalidDesfire;
      Original := FEngine.Settings(AFile);
      if not Granted(Original.ChangeKey) then
        InvalidDesfire;
      Body := nil;
      SetLength(Body, 3);
      case ACommunication of
        dfcPlain:
          Body[0] := 0;
        dfcMac:
          Body[0] := 1;
        dfcFull:
          Body[0] := 3;
      end;
      Body[1] := (AReadWriteKey shl 4) or AChangeKey;
      Body[2] := (AReadKey shl 4) or AWriteKey;
      Expected := CopyBytes(Original.RawBytes);
      Move(Body[0], Expected[1], 3);
      Mode := dfcFull;
      if ((FEngine.FSecurity = dfsEv1Aes) or FEngine.IsDes) and
        (Original.ChangeKey = $E) then
        Mode := dfcPlain;
      Reply := FEngine.Send($5F, OneByte(AFile), Body, Mode, 0, True);
      if Length(Reply) <> 0 then
        InvalidDesfire;
      After := FEngine.Settings(AFile);
      if not BytesEqual(After.RawBytes, Expected) then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Body);
    FInCall := False;
  end;
end;

function DesCrc16(const Data: TBytes): TBytes;
var
  Framed: TBytes;
begin
  Framed := TRawUidCodec.AppendCrcA(Data);
  Result := Copy(Framed, Length(Data), 2);
  TCardCrypto.Clear(Framed);
end;

function DesVersionKey(const Material: TBytes; const Version: Byte;
  const NewMaterial: Boolean): TBytes;
var
  I, Bit: Integer;
begin
  Result := CopyBytes(Material);
  for I := 0 to 7 do
  begin
    Bit := (Version shr (7 - I)) and 1;
    Result[I] := (Result[I] and $FE) or Bit;
    if NewMaterial and (Length(Result) = 16) then
      Result[I + 8] := (Result[I + 8] and $FE) or (Bit xor 1);
  end;
end;

function DesWireKey(const Key: TBytes): TBytes;
begin
  if Length(Key) = 8 then
    Result := Joined(Key, Key)
  else
    Result := CopyBytes(Key);
end;

procedure AppendDesBytes(var Target: TBytes; const Extra: TBytes);
var
  Combined: TBytes;
begin
  Combined := Joined(Target, Extra);
  TCardCrypto.Clear(Target);
  Target := Combined;
end;

procedure TDesfireSession.ChangeDesKey(const AKeyNumber, ANewVersion,
  AOldVersion: Byte; const ANewKey, AOldKey: TBytes);
var
  Before, Size, I, N: Integer;
  Settings: TDesfireApplicationSettings;
  Current: Boolean;
  Number, Policy: Byte;
  NewKey, OldKey, NewWire, OldWire, Body, Header, Packet, Reply, Crc, Vector,
    NextIv: TBytes;
  P: ICardDesProvider;
begin
  Before := Enter;
  try
    try
      RequireNativeManagement;
      if not FEngine.IsDes then
        InvalidDesfire;
      Size := 16;
      if FEngine.FSecurity = dfsD40Des then
        Size := 8
      else if FEngine.FSecurity = dfsEv1ThreeKey3Des then
        Size := 24;
      if (AKeyNumber > 13) or (Length(ANewKey) <> Size) then
        InvalidDesfire;
      Current := AKeyNumber = FEngine.FSessionKeyNumber;
      if (Current and (Length(AOldKey) <> 0)) or
        (not Current and (Length(AOldKey) <> Size)) then
        InvalidDesfire;
      NewKey := DesVersionKey(ANewKey, ANewVersion, True);
      if not Current then
        OldKey := DesVersionKey(AOldKey, AOldVersion, False);
      Settings := AppSettings;
      Number := 0;
      if Size = 24 then
        Number := $40;
      if ((Settings.KeyConfiguration and $C0) <> Number) or
        (AKeyNumber >= (Settings.KeyConfiguration and $F)) or
        ((FAid = 0) and (AKeyNumber <> 0)) then
        InvalidDesfire;
      Policy := Settings.KeySettings shr 4;
      if AKeyNumber = 0 then
      begin
        if ((Settings.KeySettings and 1) = 0) or (FEngine.FSessionKeyNumber <> 0)
        then
          InvalidDesfire;
      end
      else if not(((Policy < 14) and (Policy = FEngine.FSessionKeyNumber)) or
        ((Policy = $E) and Current)) then
        InvalidDesfire;
      Number := AKeyNumber;
      if (FAid = 0) and (Size = 24) then
        Number := Number or $40;
      Header := OneByte(Number);
      NewWire := DesWireKey(NewKey);
      Body := CopyBytes(NewWire);
      if not Current then
      begin
        OldWire := DesWireKey(OldKey);
        for I := 0 to High(Body) do
          Body[I] := Body[I] xor OldWire[I];
      end;
      if FEngine.IsLegacyDes then
        Crc := DesCrc16(Body)
      else
      begin
        SetLength(Vector, Length(Body) + 2);
        Vector[0] := $C4;
        Vector[1] := Number;
        Move(Body[0], Vector[2], Length(Body));
        Crc := TDesfireEv1Codec.Crc32(Vector);
        TCardCrypto.Clear(Vector);
      end;
      AppendDesBytes(Body, Crc);
      if not Current then
      begin
        TCardCrypto.Clear(Crc);
        if FEngine.IsLegacyDes then
          Crc := DesCrc16(NewWire)
        else
          Crc := TDesfireEv1Codec.Crc32(NewWire);
        AppendDesBytes(Body, Crc);
      end;
      N := ((Length(Body) + 7) div 8) * 8;
      SetLength(Body, N);
      P := FEngine.DesProvider;
      if FEngine.IsLegacyDes then
        Packet := TCardDesCrypto.LegacySend(P, FEngine.FKeys.Encryption, Body)
      else
      begin
        Packet := TCardDesCrypto.Crypt(P, FEngine.FKeys.Encryption,
          FEngine.FSessionIv, Body, True);
        NextIv := Copy(Packet, N - 8, 8);
        TCardCrypto.Clear(FEngine.FSessionIv);
        FEngine.FSessionIv := NextIv;
        NextIv := nil;
      end;
      Packet := Joined(Header, Packet);
      Reply := FEngine.Exchange($C4, Packet, 8, True);
      if not(Current and (Length(Reply) = 0)) then
      begin
        if FEngine.IsLegacyDes then
          Vector := TDesfireDesCodec.DecodeResponse(P, FEngine.FKeys.Encryption,
            FEngine.FSessionIv, Reply, dfcPlain, 0, True)
        else
          Vector := TDesfireDesCodec.DecodeResponse(P, FEngine.FKeys.Encryption,
            FEngine.FSessionIv, Reply, dfcMac, 0, False);
        if Length(Vector) <> 0 then
          InvalidDesfire;
      end;
      FEngine.FAuthenticated := False;
      FEngine.FKeyNumber := AKeyNumber;
      TCardCrypto.Clear(FEngine.FKey);
      FEngine.FKey := CopyBytes(NewKey);
      FEngine.Authenticate(False);
      if KeyVersion(AKeyNumber) <> ANewVersion then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(NewKey);
    TCardCrypto.Clear(OldKey);
    TCardCrypto.Clear(NewWire);
    TCardCrypto.Clear(OldWire);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Crc);
    TCardCrypto.Clear(Vector);
    TCardCrypto.Clear(NextIv);
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeAesKey(const AKeyNumber, ANewVersion: Byte;
  const ANewKey, AOldKey: TBytes);
var
  Before, I, N: Integer;
  Settings: TDesfireApplicationSettings;
  Current: Boolean;
  Number, Policy: Byte;
  NewKey, OldKey, Body, Header, Packet, Reply, Crc, Vector, NextIv: TBytes;
begin
  Before := Enter;
  try
    try
      RequireAesManagement;
      if (AKeyNumber > 13) or (Length(ANewKey) <> 16) then
        InvalidDesfire;
      Current := AKeyNumber = FEngine.FSessionKeyNumber;
      if (Current and (Length(AOldKey) <> 0)) or
        (not Current and (Length(AOldKey) <> 16)) then
        InvalidDesfire;
      NewKey := CopyBytes(ANewKey);
      OldKey := CopyBytes(AOldKey);
      Settings := AppSettings;
      if ((Settings.KeyConfiguration and $C0) <> $80) or
        (AKeyNumber >= (Settings.KeyConfiguration and $F)) or
        ((FAid = 0) and (AKeyNumber <> 0)) then
        InvalidDesfire;
      Policy := Settings.KeySettings shr 4;
      if AKeyNumber = 0 then
      begin
        if ((Settings.KeySettings and 1) = 0) or (FEngine.FSessionKeyNumber <> 0)
        then
          InvalidDesfire;
      end
      else if not(((Policy < 14) and (Policy = FEngine.FSessionKeyNumber)) or
        ((Policy = $E) and Current)) then
        InvalidDesfire;
      Number := AKeyNumber;
      if FAid = 0 then
        Number := Number or $80;
      Header := OneByte(Number);
      Body := CopyBytes(NewKey);
      if not Current then
        for I := 0 to 15 do
          Body[I] := Body[I] xor OldKey[I];
      Body := Joined(Body, OneByte(ANewVersion));
      if FEngine.FSecurity = dfsEv1Aes then
      begin
        Vector := Joined(OneByte($C4), Joined(Header, Body));
        Crc := TDesfireEv1Codec.Crc32(Vector);
        Body := Joined(Body, Crc);
        if not Current then
        begin
          TCardCrypto.Clear(Crc);
          Crc := TDesfireEv1Codec.Crc32(NewKey);
          Body := Joined(Body, Crc);
        end;
        N := ((Length(Body) + 15) div 16) * 16;
        SetLength(Body, N);
        Packet := FEngine.FProvider.EncryptCbc(FEngine.FKeys.Encryption,
          FEngine.FSessionIv, Body);
        if Length(Packet) <> N then
          InvalidDesfire;
        NextIv := Copy(Packet, N - 16, 16);
        TCardCrypto.Clear(FEngine.FSessionIv);
        FEngine.FSessionIv := NextIv;
        NextIv := nil;
        Packet := Joined(Header, Packet);
      end
      else
      begin
        if not Current then
        begin
          Crc := TDesfireEv1Codec.Crc32(NewKey);
          Body := Joined(Body, Crc);
        end;
        Packet := TDesfireEv2Codec.EncodeCommand(FEngine.FProvider,
          FEngine.FKeys, FEngine.FTi, FEngine.FCounter, $C4, Header,
          Body, dfcFull);
      end;
      Reply := FEngine.Exchange($C4, Packet, 8, True);
      if FEngine.FSecurity = dfsEv2Aes then
        Inc(FEngine.FCounter);
      if not(Current and (Length(Reply) = 0)) then
      begin
        if FEngine.FSecurity = dfsEv2Aes then
          Vector := TDesfireEv2Codec.DecodeResponse(FEngine.FProvider,
            FEngine.FKeys, FEngine.FTi, FEngine.FCounter, Reply, dfcMac, 0)
        else
          Vector := TDesfireEv1Codec.DecodeResponse(FEngine.FProvider,
            FEngine.FKeys.Encryption, FEngine.FSessionIv, Reply, dfcMac, 0);
        if Length(Vector) <> 0 then
          InvalidDesfire;
      end;
      // This is explicit post-write verification, not recovery/replay of ChangeKey.
      FEngine.FAuthenticated := False;
      FEngine.FKeyNumber := AKeyNumber;
      TCardCrypto.Clear(FEngine.FKey);
      FEngine.FKey := CopyBytes(NewKey);
      FEngine.Authenticate(False);
      if KeyVersion(AKeyNumber) <> ANewVersion then
        InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(NewKey);
    TCardCrypto.Clear(OldKey);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Crc);
    TCardCrypto.Clear(Vector);
    TCardCrypto.Clear(NextIv);
    FInCall := False;
  end;
end;


function TDesfireCardReader.OpenFileManagementSession(const AAid: Cardinal): IDesfireFileManagement;
var
  Session: IDesfireExtendedManagement;
begin
  Session := OpenExtendedManagementSession(AAid);
  if not Supports(Session, IDesfireFileManagement, Result) then
    InvalidDesfire;
end;

procedure TDesfireSession.RequireFileManagement(const ACreation: Boolean);
begin
  RequireEv2Management;
  if ACreation then RequireManagement
  else AppSettings;
end;

function TDesfireSession.IsoDirectory: TDesfireIsoApplications;
var
  Data: TBytes;
  Item: TDesfireIsoApplication;
  I, J, P, N: Integer;
begin
  Result := nil;
  if FAid <> 0 then InvalidDesfire;
  FEngine.FCaptureFrames := True;
  try
    Data := FEngine.Metadata($6D, nil, 21504, False);
    P := 0;
    for I := 0 to High(FEngine.FResponseSizes) do
    begin
      N := FEngine.FResponseSizes[I];
      if I = High(FEngine.FResponseSizes) then Dec(N, 8);
      if N = 0 then Continue;
      if (N < 5) or (N > 21) or (P > Length(Data) - N) then InvalidDesfire;
      Item := TDesfireExtensionCodec.IsoApplication(Copy(Data, P, N));
      for J := 0 to High(Result) do
        if (Result[J].Aid = Item.Aid) or (Result[J].IsoFid = Item.IsoFid) or
          ((Length(Item.DfName) > 0) and BytesEqual(Result[J].DfName, Item.DfName)) then InvalidDesfire;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Item;
      Inc(P, N);
    end;
    if P <> Length(Data) then InvalidDesfire;
  finally
    FEngine.FCaptureFrames := False;
    FEngine.FResponseSizes := nil;
    TCardCrypto.Clear(Data);
  end;
end;

function TDesfireSession.IsoIds: TDesfireIsoFileIds;
begin
  if FAid = 0 then InvalidDesfire;
  Result := TDesfireExtensionCodec.IsoFileIds(FEngine.Metadata($61, nil, 64, False));
end;

procedure TDesfireSession.ValidateRightKeys(const ARights: TDesfireAccessRightSets);
var
  Settings: TDesfireApplicationSettings;
  I, J, Key: Integer;
begin
  Settings := AppSettings;
  for I := 0 to High(ARights) do
    for J := 0 to 3 do
    begin
      Key := (ARights[I] shr (J * 4)) and $F;
      if (Key < 14) and (Key >= (Settings.KeyConfiguration and $F)) then InvalidDesfire;
    end;
end;

function TDesfireSession.MultiSettings(const AFile: Byte): TDesfireMultiAccessSettings;
var
  Base: TDesfireFileSettings;
begin
  if (FAid = 0) or (AFile > 31) then InvalidDesfire;
  Result := TDesfireExtensionCodec.MultiAccessSettings(FEngine.Metadata($F5, OneByte(AFile), 32, False));
  Base := TDesfireCodec.FileSettings(AFile, Result.BaseBytes);
  if Length(Base.RawBytes) <> Length(Result.BaseBytes) then InvalidDesfire;
end;

function TDesfireSession.MultiRead(const AFile: Byte; const S: TDesfireMultiAccessSettings;
  const AOffset, ACount: Integer; const AWriting: Boolean): TBytes;
var
  Base: TDesfireFileSettings;
  I: Integer;
  ReadAllowed, WriteAllowed: Boolean;
begin
  Base := TDesfireCodec.FileSettings(AFile, S.BaseBytes);
  if not (Base.FileType in [dftStandard, dftBackup]) or (AOffset < 0) or
    (ACount < 1) or (ACount > FEngine.FMaxTransfer) or (AOffset > Base.FileBytes - ACount) or
    (Base.Communication < FEngine.FMinimum) then InvalidDesfire;
  if AWriting and (Base.FileType <> dftStandard) then InvalidDesfire;
  ReadAllowed := False;
  WriteAllowed := False;
  for I := 0 to High(S.Rights) do
  begin
    ReadAllowed := ReadAllowed or Granted((S.Rights[I] shr 12) and $F) or Granted((S.Rights[I] shr 4) and $F);
    WriteAllowed := WriteAllowed or Granted((S.Rights[I] shr 8) and $F) or Granted((S.Rights[I] shr 4) and $F);
  end;
  if not ReadAllowed or (AWriting and not WriteAllowed) then InvalidDesfire;
  Result := FEngine.Send($AD, TDesfireCodec.RangeHeader(AFile, AOffset, ACount), nil,
    Base.Communication, ACount, False);
end;

function TDesfireSession.TmacMetadata(const AFile: Byte): TDesfireTmacSettings;
begin
  if (FAid = 0) or (AFile > 31) then InvalidDesfire;
  Result := TDesfireExtensionCodec.TmacSettings(FEngine.Metadata($F5, OneByte(AFile), 10, False));
end;

function TDesfireSession.ReadIsoApplications: TDesfireIsoApplications;
var
  Before: Integer;

begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      Result := IsoDirectory;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.ReadIsoFileIds: TDesfireIsoFileIds;
var
  Before: Integer;

begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      Result := IsoIds;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateIsoApplicationVerified(const AAid: Cardinal;
  const APolicy, AKeyCount: Byte; const AIsoFid: Word; const ADfName: TBytes);
var
  Header: TBytes;
begin
  if (AKeyCount < 1) or (AKeyCount > 14) or
    (((APolicy shr 4) < 14) and ((APolicy shr 4) >= AKeyCount)) then InvalidDesfire;
  Header := Joined(TDesfireCodec.ApplicationBytes(AAid), HexToBytes('00A0'));
  Header[3] := APolicy;
  Header[4] := $A0 or AKeyCount;
  try
    CreateIsoApplicationInternal(AAid, AIsoFid, ADfName, Header, nil);
  finally
    TCardCrypto.Clear(Header);
  end;
end;

procedure TDesfireSession.CreateIsoApplicationWithKeySetsVerified(const AAid: Cardinal;
  const APolicy, AKeyCount, ASetCount, ASetVersion, ARollKey: Byte;
  const AIsoFid: Word; const ADfName: TBytes);
var
  Header, Expected: TBytes;
begin
  if (APolicy and 2) = 0 then InvalidDesfire;
  Header := TDesfireExtensionCodec.ApplicationHeader(AAid, APolicy, AKeyCount,
    ASetCount, ASetVersion, ARollKey);
  Header[4] := Header[4] or $20;
  Expected := Copy(Header, 3, 7);
  try
    CreateIsoApplicationInternal(AAid, AIsoFid, ADfName, Header, Expected);
  finally
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Expected);
  end;
end;

procedure TDesfireSession.CreateIsoApplicationInternal(const AAid: Cardinal; const AIsoFid: Word;
  const ADfName, AHeader, AExpectedSettings: TBytes);
var
  Before: Integer;
  Header, Name, Expected, Reply, Fid: TBytes;
  Directory: TDesfireIsoApplications;
  Ids: TDesfireApplicationIds;
  Settings: TDesfireApplicationSettings;
  I: Integer;
  Found: Boolean;
begin
  Before := Enter;
  try
    try
      if (FAid <> 0) or (AAid = 0) or (AAid > $FFFFFF) or
        (Length(ADfName) < 1) or (Length(ADfName) > 16) then InvalidDesfire;
      TDesfireExtensionCodec.ValidateIsoFid(AIsoFid);
      Name := CopyBytes(ADfName);
      Expected := CopyBytes(AExpectedSettings);
      Fid := nil;
      SetLength(Fid, 2);
      Fid[0] := Byte(AIsoFid and $FF);
      Fid[1] := Byte(AIsoFid shr 8);
      Header := Joined(Joined(AHeader, Fid), Name);
      RequireFileManagement(True);
      Ids := TDesfireCodec.ApplicationIds(FEngine.Metadata($6A, nil, 3072, False));
      for I := 0 to High(Ids) do if Ids[I] = AAid then InvalidDesfire;
      Directory := IsoDirectory;
      for I := 0 to High(Directory) do
        if (Directory[I].IsoFid = AIsoFid) or BytesEqual(Directory[I].DfName, Name) then InvalidDesfire;
      Reply := FEngine.Metadata($CA, Header, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      Directory := IsoDirectory;
      Found := False;
      for I := 0 to High(Directory) do
        if Directory[I].Aid = AAid then
          Found := (Directory[I].IsoFid = AIsoFid) and BytesEqual(Directory[I].DfName, Name);
      if not Found then InvalidDesfire;
      if Length(Expected) > 0 then
      begin
        FEngine.FAuthenticated := False;
        Reply := FEngine.Exchange($5A, TDesfireCodec.ApplicationBytes(AAid), 0, False);
        if Length(Reply) <> 0 then InvalidDesfire;
        Settings := AppSettings;
        if not BytesEqual(Settings.RawBytes, Expected) then InvalidDesfire;
        Reply := FEngine.Exchange($5A, TDesfireCodec.ApplicationBytes(0), 0, False);
        if Length(Reply) <> 0 then InvalidDesfire;
        FEngine.Authenticate(False);
      end;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Name);
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Fid);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateIsoFileVerified(const ADefinition: TDesfireFileDefinition;
  const AIsoFid: Word);
var
  Before: Integer;
  D: TDesfireFileDefinition;
  Header, OrdinaryHeader, Expected, Ids, Reply: TBytes;
  Fids: TDesfireIsoFileIds;
  S: TDesfireFileSettings;
  App: TDesfireApplicationSettings;
  Command: Byte;
  I: Integer;
  Found: Boolean;
begin
  Before := Enter;
  try
    try
      D := ADefinition;
      if D.FileType = dftValue then InvalidDesfire;
      TDesfireExtensionCodec.ValidateIsoFid(AIsoFid);
      OrdinaryHeader := DefinitionHeader(D, Command);
      Header := nil;
      SetLength(Header, 3);
      Header[0] := D.FileNumber;
      Header[1] := Byte(AIsoFid and $FF);
      Header[2] := Byte(AIsoFid shr 8);
      Header := Joined(Header, Copy(OrdinaryHeader, 1, Length(OrdinaryHeader) - 1));
      Expected := Joined(OneByte(Ord(D.FileType)), Copy(OrdinaryHeader, 1, Length(OrdinaryHeader) - 1));
      if D.FileType in [dftLinearRecords, dftCyclicRecords] then Expected := Joined(Expected, HexToBytes('000000'));
      RequireFileManagement(True);
      App := AppSettings;
      if (App.KeyConfiguration and $20) = 0 then InvalidDesfire;
      Ids := FileIds;
      for I := 0 to High(Ids) do if Ids[I] = D.FileNumber then InvalidDesfire;
      Fids := IsoIds;
      for I := 0 to High(Fids) do if Fids[I] = AIsoFid then InvalidDesfire;
      Reply := FEngine.Metadata(Command, Header, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      S := FEngine.Settings(D.FileNumber);
      if not BytesEqual(S.RawBytes, Expected) then InvalidDesfire;
      Fids := IsoIds;
      Found := False;
      for I := 0 to High(Fids) do Found := Found or (Fids[I] = AIsoFid);
      if not Found then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(OrdinaryHeader);
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

function TDesfireSession.ReadMultiAccessSettings(const AFile: Byte): TDesfireMultiAccessSettings;
var
  Before: Integer;

begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      Result := MultiSettings(AFile);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.ChangeMultiAccessVerified(const AFile: Byte; const AExpected: TBytes;
  const ACommunication: Byte; const ARights: TDesfireAccessRightSets);
var
  Before: Integer;
  Prior, Current, After: TDesfireMultiAccessSettings;
  Rights: TDesfireAccessRightSets;
  Body, Desired, Reply: TBytes;
  Base: TDesfireFileSettings;
  Prefix: Integer;
begin
  Before := Enter;
  try
    try
      Rights := Copy(ARights, 0, Length(ARights));
      Body := TDesfireExtensionCodec.AccessChange(ACommunication, Rights);
      Prior := TDesfireExtensionCodec.MultiAccessSettings(AExpected);
      Base := TDesfireCodec.FileSettings(AFile, Prior.BaseBytes);
      Prefix := Length(Prior.BaseBytes);
      Desired := CopyBytes(Prior.BaseBytes);
      Desired[1] := Body[0]; Desired[2] := Body[1]; Desired[3] := Body[2];
      if Length(Body) > 3 then Desired := Joined(Desired, Copy(Body, 3, Length(Body) - 3));
      if Length(Desired) < Prefix then InvalidDesfire;
      RequireFileManagement;
      if not Granted(Base.ChangeKey) then InvalidDesfire;
      ValidateRightKeys(Rights);
      Current := MultiSettings(AFile);
      if not BytesEqual(Current.RawBytes, Prior.RawBytes) then InvalidDesfire;
      if not BytesEqual(Current.RawBytes, Desired) then
      begin
        Reply := FEngine.Send($5F, OneByte(AFile), Body, dfcFull, 0, True);
        if Length(Reply) <> 0 then InvalidDesfire;
        After := MultiSettings(AFile);
        if not BytesEqual(After.RawBytes, Desired) then InvalidDesfire;
        FEngine.FWriteAttempt := False;
      end;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Desired);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

function TDesfireSession.ReadMultiAccessData(const AFile: Byte; const AOffset, ACount: Integer): TBytes;
var
  Before: Integer;
  S, After: TDesfireMultiAccessSettings;
begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      S := MultiSettings(AFile);
      ValidateRightKeys(S.Rights);
      Result := MultiRead(AFile, S, AOffset, ACount, False);
      After := MultiSettings(AFile);
      if not BytesEqual(S.RawBytes, After.RawBytes) then InvalidDesfire;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.WriteMultiAccessDataVerified(const AFile: Byte; const AOffset: Integer;
  const AExpected, AData: TBytes);
var
  Before: Integer;
  S, After: TDesfireMultiAccessSettings;
  Base: TDesfireFileSettings;
  Expected, Data, Actual, Reply: TBytes;
begin
  Before := Enter;
  try
    try
      Expected := CopyBytes(AExpected);
      Data := CopyBytes(AData);
      if (Length(Data) < 1) or (Length(Data) <> Length(Expected)) then InvalidDesfire;
      RequireFileManagement;
      S := MultiSettings(AFile);
      ValidateRightKeys(S.Rights);
      Base := TDesfireCodec.FileSettings(AFile, S.BaseBytes);
      Actual := MultiRead(AFile, S, AOffset, Length(Data), True);
      if not BytesEqual(Actual, Expected) then InvalidDesfire;
      After := MultiSettings(AFile);
      if not BytesEqual(S.RawBytes, After.RawBytes) then InvalidDesfire;
      if not BytesEqual(Expected, Data) then
      begin
        Reply := FEngine.Send($8D, TDesfireCodec.RangeHeader(AFile, AOffset, Length(Data)),
          Data, Base.Communication, 0, True);
        if Length(Reply) <> 0 then InvalidDesfire;
        Actual := MultiRead(AFile, S, AOffset, Length(Data), False);
        if not BytesEqual(Actual, Data) then InvalidDesfire;
        After := MultiSettings(AFile);
        if not BytesEqual(S.RawBytes, After.RawBytes) then InvalidDesfire;
        FEngine.FWriteAttempt := False;
      end;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Actual);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

function TDesfireSession.ReadTransactionMacSettings(const AFile: Byte): TDesfireTmacSettings;
var
  Before: Integer;

begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      Result := TmacMetadata(AFile);
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FInCall := False;
  end;
end;

procedure TDesfireSession.CreateTransactionMacFileVerified(const AFile, AFileOption: Byte;
  const AAccessRights: Word; const AKeyVersion: Byte; const AKey: TBytes);
var
  Before: Integer;
  Header, Body, Expected, Reply, Ids: TBytes;
  Settings: TDesfireTmacSettings;
  Rights: TDesfireAccessRightSets;
  I: Integer;
begin
  Before := Enter;
  try
    try
      if (AFile > 31) or (Length(AKey) <> 16) then InvalidDesfire;
      Expected := HexToBytes('050000000200');
      Expected[1] := AFileOption;
      Expected[2] := Byte(AAccessRights and $FF); Expected[3] := Byte(AAccessRights shr 8);
      Expected[5] := AKeyVersion;
      Settings := TDesfireExtensionCodec.TmacSettings(Expected);
      Body := nil;
      SetLength(Body, 17);
      Move(AKey[0], Body[0], 16);
      Body[16] := AKeyVersion;
      Header := Joined(OneByte(AFile), Copy(Expected, 1, 4));
      RequireFileManagement(True);
      if FEngine.FSessionKeyNumber <> 0 then InvalidDesfire;
      Rights := nil; SetLength(Rights, 1); Rights[0] := AAccessRights;
      ValidateRightKeys(Rights);
      Ids := FileIds;
      for I := 0 to High(Ids) do if Ids[I] = AFile then InvalidDesfire;
      Reply := FEngine.Send($CE, Header, Body, dfcFull, 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      Settings := TmacMetadata(AFile);
      if not BytesEqual(Settings.RawBytes, Expected) then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

function TDesfireSession.ReadTransactionMacRecord(const AFile: Byte): TDesfireTmacRecord;
var
  Before: Integer;
  S, After: TDesfireTmacSettings;
  Mode: TDesfireCommunication;
  Data: TBytes;
begin
  Before := Enter;
  try
    try
      RequireFileManagement;
      S := TmacMetadata(AFile);
      if not Granted((S.AccessRights shr 12) and $F) then InvalidDesfire;
      Mode := dfcPlain;
      case S.FileOption and 3 of
        1: Mode := dfcMac;
        3: Mode := dfcFull;
      end;
      if Mode < FEngine.FMinimum then InvalidDesfire;
      Data := FEngine.Send($AD, TDesfireCodec.RangeHeader(AFile, 0, 12), nil, Mode, 12, False);
      Result := TDesfireExtensionCodec.TmacRecord(Data);
      Result.SessionProtected := Mode <> dfcPlain;
      After := TmacMetadata(AFile);
      if not BytesEqual(S.RawBytes, After.RawBytes) then InvalidDesfire;
    except
      on E: Exception do
      begin
        if Poison(Before) then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Data);
    FInCall := False;
  end;
end;


function TDesfireCardReader.OpenTransactionMacSession(const AAid: Cardinal; const ATmacFile: Byte;
  const AUid, ATmacKey: TBytes; const APreviousCounter: Cardinal;
  const AAcknowledgeFresh: Boolean): IDesfireTransactionMacSession;
begin
  if FBusy or not AAcknowledgeFresh then InvalidDesfire;
  Result := TDesfireSession.Create(Self, AAid, dsaFreshTransaction, ATmacFile,
    AUid, ATmacKey, APreviousCounter);
end;

function TDesfireCardReader.OpenIsoKeySetManagementSession: IDesfireIsoKeySetManagement;
var
  Session: IDesfireFileManagement;
begin
  Session := OpenFileManagementSession(0);
  Result := Session as IDesfireIsoKeySetManagement;
end;

function TDesfireCardReader.OpenTransactionMacDataSession(const AAid: Cardinal; const ATmacFile: Byte;
  const AUid, ATmacKey: TBytes; const APreviousCounter: Cardinal;
  const AAcknowledgeFresh: Boolean): IDesfireTransactionMacDataSession;
var
  Session: IDesfireTransactionMacSession;
begin
  Session := OpenTransactionMacSession(AAid, ATmacFile, AUid, ATmacKey,
    APreviousCounter, AAcknowledgeFresh);
  Result := Session as IDesfireTransactionMacDataSession;
end;

procedure TDesfireCardReader.ReserveTmac(const ACommand: Byte;
  const AHeader: TBytes; const ADataLength: Integer);
var
  Required: Integer;
begin
  if not FTmacCapture or not (ACommand in [$AD, $8D, $AB, $8B, $6C, $0C, $DC, $1C, $EB, $C8, $BA]) then Exit;
  if (ACommand <> $C8) and (Length(AHeader) > 0) and (AHeader[0] = FTmacExcludedFile) then Exit;
  Required := 16;
  case ACommand of
    $AD, $8D: Required := 16 + ((ADataLength + 15) div 16) * 16;
    $BA: Required := 32;
    $AB, $8B:
      begin
        if ADataLength mod 16 <> 0 then InvalidDesfire;
        Required := 16 + ADataLength;
      end;
    $C8: Required := 48;
  end;
  if (Required > 1048560) or (Length(FTmacInput) > 1048560 - Required) then InvalidDesfire;
end;

procedure TDesfireCardReader.TrackTmac(const ACommand: Byte; const AHeader, AData: TBytes);
var
  Updated: TBytes;
begin
  if not FTmacCapture or not (ACommand in [$AD, $8D, $AB, $8B, $6C, $0C, $DC, $1C, $EB, $C8, $BA]) then Exit;
  if (ACommand <> $C8) and (Length(AHeader) > 0) and (AHeader[0] = FTmacExcludedFile) then Exit;
  Updated := TDesfireTmacCrypto.AppendInput(FTmacInput, ACommand, AHeader, AData);
  TCardCrypto.Clear(FTmacInput);
  FTmacInput := Updated;
end;

function TDesfireSession.ReadTransactionMacInput: TBytes;
var
  Before: Integer;
begin
  Before := Enter;
  try
    if FTmacFile < 0 then InvalidDesfire;
    Result := CopyBytes(FEngine.FTmacInput);
    if FEngine.FAttempts <> Before then InvalidDesfire;
  finally
    FInCall := False;
  end;
end;

function TDesfireSession.CommitReaderId(const AReaderId: TBytes): TBytes;
var
  Before: Integer;
  Id, Cipher: TBytes;
  Key: Byte;
begin
  Before := Enter;
  try
    Id := CopyBytes(AReaderId);
    try
      RequireOwner;
      if (FTmacFile < 0) or (Length(Id) <> 16) or FReaderIdCommitted then InvalidDesfire;
      Key := (FTmacSettings.AccessRights shr 4) and $F;
      if not Granted(Key) then InvalidDesfire;
      FEngine.ReserveTmac($C8, Id, 16);
      Cipher := FEngine.Metadata($C8, Id, 16, True);
      if Length(Cipher) <> 16 then InvalidDesfire;
      FEngine.TrackTmac($C8, Id, Cipher);
      Result := TDesfireTmacCrypto.DecryptReaderId(FEngine.FProvider, FTmacKey, FTmacUid,
        FTmacPreviousCounter + 1, Cipher);
      FReaderIdCommitted := True;
      FPending := True;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Id);
    TCardCrypto.Clear(Cipher);
    FInCall := False;
  end;
end;


procedure TDesfireSession.ChangeTransactionMacSettingsVerified(const AFile: Byte;
  const AExpected: TBytes; const AFileOption: Byte;
  const AAccessRights: Word; const ACounterLimit: Cardinal);
var
  Before, I: Integer;
  Prior, Current, DesiredSettings: TDesfireTmacSettings;
  Desired, Body, Reply: TBytes;
  Rights: TDesfireAccessRightSets;
begin
  Before := Enter;
  try
    try
      Prior := TDesfireExtensionCodec.TmacSettings(AExpected);
      Desired := Copy(Prior.RawBytes, 0, 6);
      Desired[1] := AFileOption;
      Desired[2] := Byte(AAccessRights and $FF);
      Desired[3] := Byte(AAccessRights shr 8);
      if (AFileOption and $20) <> 0 then
      begin
        SetLength(Desired, 10);
        for I := 0 to 3 do Desired[6 + I] := Byte((ACounterLimit shr (I * 8)) and $FF);
      end
      else if ACounterLimit <> 0 then InvalidDesfire;
      DesiredSettings := TDesfireExtensionCodec.TmacSettings(Desired);
      if DesiredSettings.KeyVersion <> Prior.KeyVersion then InvalidDesfire;
      Body := Copy(Desired, 1, 3);
      if Length(Desired) > 6 then Body := Joined(Body, Copy(Desired, 6, 4));
      RequireFileManagement;
      if not Granted(Prior.AccessRights and $F) then InvalidDesfire;
      Rights := nil; SetLength(Rights, 1); Rights[0] := AAccessRights;
      ValidateRightKeys(Rights);
      Current := TmacMetadata(AFile);
      if not BytesEqual(Current.RawBytes, Prior.RawBytes) then InvalidDesfire;
      if not BytesEqual(Current.RawBytes, Desired) then
      begin
        Reply := FEngine.Send($5F, OneByte(AFile), Body, dfcFull, 0, True);
        if Length(Reply) <> 0 then InvalidDesfire;
        Current := TmacMetadata(AFile);
        if not BytesEqual(Current.RawBytes, Desired) then InvalidDesfire;
        FEngine.FWriteAttempt := False;
      end;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Desired);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Reply);
    FInCall := False;
  end;
end;

procedure TDesfireSession.DeleteTransactionMacFileVerified(const AFile: Byte;
  const AExpected: TBytes);
var
  Before, I: Integer;
  Prior, Current: TDesfireTmacSettings;
  Reply, Ids: TBytes;
begin
  Before := Enter;
  try
    try
      Prior := TDesfireExtensionCodec.TmacSettings(AExpected);
      RequireFileManagement(True);
      if FEngine.FSessionKeyNumber <> 0 then InvalidDesfire;
      Current := TmacMetadata(AFile);
      if not BytesEqual(Current.RawBytes, Prior.RawBytes) then InvalidDesfire;
      Reply := FEngine.Metadata($DF, OneByte(AFile), 0, True);
      if Length(Reply) <> 0 then InvalidDesfire;
      Ids := FileIds;
      for I := 0 to High(Ids) do if Ids[I] = AFile then InvalidDesfire;
      FEngine.FWriteAttempt := False;
    except
      on E: Exception do
      begin
        if Poison(Before) then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Reply);
    TCardCrypto.Clear(Ids);
    FInCall := False;
  end;
end;

end.
