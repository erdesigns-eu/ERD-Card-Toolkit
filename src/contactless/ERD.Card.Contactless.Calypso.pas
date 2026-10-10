unit ERD.Card.Contactless.Calypso;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes, {$ELSE}System.SysUtils, System.Classes, {$ENDIF}
  ERD.Card.APDU, ERD.Card.Transport;

type
  /// <summary>Explicit Calypso command dialect; no automatic alternate-class retry.</summary>
  TCalypsoDialect = (
    /// <summary>Legacy Calypso proprietary command class 94.</summary>
    cdLegacy94,
    /// <summary>Revision 3 compatible ISO class 00 with logical-path selection P1 09.</summary>
    cdIso00);

  /// <summary>Live read-only secure session supplied by a trusted Calypso SDK/SAM adapter.</summary>
  /// <remarks>The provider must return authenticated/decrypted APDU responses, enforce the requested
  /// read-only command policy and verify final session authentication. Keys remain owned by the provider.</remarks>
  ICalypsoSecureReadSession = interface
    ['{899FB7B8-C21C-47A7-ABBA-6CE2E1EFA140}']
    /// <summary>Returns a nonnil APDU adapter for this already-opened secure session.</summary>
    /// <returns>Authenticated plaintext exchange transport; never a raw unverified fallback.</returns>
    function GetTransport: ICardTransport;
    /// <summary>Closes and verifies the secure session; any authentication failure must raise.</summary>
    procedure Finish;
    /// <summary>Best-effort read-session abort after failure; must not commit a debit or update.</summary>
    procedure Abort;
  end;

  /// <summary>Card product family resolved from the startup-information application type byte.</summary>
  /// <remarks>Revision 1 cards return no FCI startup information and cannot be identified from it.</remarks>
  TCalypsoProductType = (
    /// <summary>No valid startup information, or application type FF.</summary>
    cptUnknown,
    /// <summary>Calypso Prime revision 2 (application type 01..1F); legacy class 94 commands.</summary>
    cptPrimeRevision2,
    /// <summary>Calypso Prime revision 3 (all other valid application types); ISO class 00 commands.</summary>
    cptPrimeRevision3,
    /// <summary>Calypso Light (application type 90..97).</summary>
    cptLight,
    /// <summary>Calypso Basic (application type 98..9F).</summary>
    cptBasic);

  /// <summary>Decoded application FCI: serial number, startup information and feature flags.</summary>
  /// <remarks>Decoding never changes a reader setting. RecommendedDialect is advice for the caller only.</remarks>
  TCalypsoApplicationInfo = record
    /// <summary>True when the selection succeeded and a complete FCI was decoded.</summary>
    Valid: Boolean;
    /// <summary>SELECT APPLICATION status word; zero when no selection was attempted, 6A82/6A81 when the name was not found.</summary>
    StatusWord: Word;
    /// <summary>Exact response bytes without status.</summary>
    Response: TBytes;
    /// <summary>DF name from FCI tag 84.</summary>
    DfName: TBytes;
    /// <summary>Eight-byte application serial number from tag C7.</summary>
    SerialNumber: TBytes;
    /// <summary>Discretionary data (startup information) from tag 53, at least seven bytes.</summary>
    StartupInfo: TBytes;
    /// <summary>Startup byte 0: session buffer size indicator.</summary>
    BufferSizeIndicator: Byte;
    /// <summary>Session buffer size in bytes for revision 3 and Light; zero when counted in commands or unknown.</summary>
    BufferSizeBytes: Cardinal;
    /// <summary>Startup byte 1: chip platform code.</summary>
    PlatformCode: Byte;
    /// <summary>Startup byte 2: application type.</summary>
    ApplicationType: Byte;
    /// <summary>Startup byte 3: application subtype.</summary>
    ApplicationSubtype: Byte;
    /// <summary>Startup byte 4: software issuer code.</summary>
    SoftwareIssuer: Byte;
    /// <summary>Startup byte 5: software version.</summary>
    SoftwareVersion: Byte;
    /// <summary>Startup byte 6: software revision.</summary>
    SoftwareRevision: Byte;
    /// <summary>Product family resolved from the application type.</summary>
    ProductType: TCalypsoProductType;
    /// <summary>Application type bit 01: PIN feature available.</summary>
    HasPin: Boolean;
    /// <summary>Application type bit 02: stored-value feature available.</summary>
    HasStoredValue: Boolean;
    /// <summary>Application type bit 04: explicit ratification command required (revision 3).</summary>
    RatificationCommandRequired: Boolean;
    /// <summary>Application type bit 08: revision 3.2 extended mode supported (revision 3).</summary>
    ExtendedMode: Boolean;
    /// <summary>Application type bit 10: PKI authentication supported (revision 3).</summary>
    Pki: Boolean;
    /// <summary>Serial number byte 3 high bit: host-card-emulation application.</summary>
    Hce: Boolean;
    /// <summary>True when the product type implies a command dialect.</summary>
    HasRecommendedDialect: Boolean;
    /// <summary>Dialect the caller may apply explicitly; never applied automatically.</summary>
    RecommendedDialect: TCalypsoDialect;
  end;

  /// <summary>Calypso file kind from FCI proprietary information byte 1.</summary>
  TCalypsoFileKind = (
    /// <summary>Unknown or missing file-type code.</summary>
    cfkUnknown,
    /// <summary>Master file (code 1).</summary>
    cfkMasterFile,
    /// <summary>Dedicated file / folder (code 2).</summary>
    cfkDedicatedFile,
    /// <summary>Elementary file (code 4).</summary>
    cfkElementaryFile);

  /// <summary>Elementary-file structure from FCI proprietary information byte 2.</summary>
  TCalypsoFileStructure = (
    /// <summary>Unknown code, or not an elementary file.</summary>
    cfsUnknown,
    /// <summary>Binary file (code 1).</summary>
    cfsBinary,
    /// <summary>Linear record file (code 2).</summary>
    cfsLinear,
    /// <summary>Cyclic record file (code 4).</summary>
    cfsCyclic,
    /// <summary>Simulated counter file (code 8).</summary>
    cfsSimulatedCounters,
    /// <summary>Counter file (code 9).</summary>
    cfsCounters);

  /// <summary>Decoded 23-byte FCI proprietary information (tag 85) of a SELECT FILE response.</summary>
  TCalypsoFileInfo = record
    /// <summary>True when a complete tag 85 was found.</summary>
    Present: Boolean;
    /// <summary>Exact 23 proprietary bytes.</summary>
    Raw: TBytes;
    /// <summary>Short file identifier, 0 when the file has none.</summary>
    Sfi: Byte;
    /// <summary>Raw file-type code.</summary>
    KindCode: Byte;
    /// <summary>Decoded file kind.</summary>
    Kind: TCalypsoFileKind;
    /// <summary>Raw elementary-file structure code.</summary>
    StructureCode: Byte;
    /// <summary>Decoded elementary-file structure.</summary>
    Structure: TCalypsoFileStructure;
    /// <summary>Record size in bytes for record files; binary files use a two-byte size in RecordSize.</summary>
    RecordSize: Word;
    /// <summary>Number of records; one for binary files.</summary>
    RecordCount: Byte;
    /// <summary>Four access-condition bytes (bytes 5..8).</summary>
    AccessConditions: array [0 .. 3] of Byte;
    /// <summary>Four key-index bytes (bytes 9..12).</summary>
    KeyIndexes: array [0 .. 3] of Byte;
    /// <summary>DF status byte (byte 13).</summary>
    DfStatus: Byte;
    /// <summary>Shared data reference for elementary files (bytes 14..15).</summary>
    DataReference: Word;
    /// <summary>Logical identifier from byte 21 (revision 3) or byte 20 (revision 2).</summary>
    LogicalId: Word;
  end;

  /// <summary>Offline BER-TLV FCI decoder for Calypso application and file selections.</summary>
  TCalypsoFci = class
  public
    /// <summary>Decodes an application FCI (tags 6F/84/A5/BF0C/C7/53).</summary>
    /// <param name="AResponse">SELECT APPLICATION response bytes without status.</param>
    /// <returns>Decoded info; Valid is false when C7 or a seven-byte tag 53 is missing.</returns>
    class function DecodeApplication(const AResponse: TBytes)
      : TCalypsoApplicationInfo; static;
    /// <summary>Decodes startup information and serial-number flags.</summary>
    /// <param name="ASerial">Eight-byte application serial number.</param>
    /// <param name="AStartupInfo">At least seven startup-information bytes.</param>
    /// <returns>Info with startup fields, product type, flags and recommended dialect.</returns>
    class function DecodeStartupInfo(const ASerial, AStartupInfo: TBytes)
      : TCalypsoApplicationInfo; static;
    /// <summary>Decodes the tag 85 proprietary file information of a SELECT FILE response.</summary>
    /// <param name="ASelection">SELECT FILE response bytes without status.</param>
    /// <param name="ARevision2">True to read the logical identifier at byte 20 instead of 21.</param>
    /// <returns>Decoded header; Present is false when no 23-byte tag 85 exists.</returns>
    class function DecodeFileInfo(const ASelection: TBytes;
      const ARevision2: Boolean = False): TCalypsoFileInfo; static;
    /// <summary>Returns the value of the first BER-TLV tag found at any constructed depth.</summary>
    /// <param name="AData">BER-TLV bytes.</param>
    /// <param name="ATag">One- or two-byte tag value, for example $85 or $BF0C.</param>
    /// <param name="AValue">Copied value when found.</param>
    /// <returns>True when the tag was found in well-formed data.</returns>
    class function FindTag(const AData: TBytes; const ATag: Word;
      out AValue: TBytes): Boolean; static;
  end;

  /// <summary>How a read-plan entry addresses its file.</summary>
  TCalypsoFileRefKind = (
    /// <summary>SELECT FILE by logical identifier, then READ RECORD on the current file.</summary>
    cfrLogicalId,
    /// <summary>READ RECORD by short file identifier in the folder, without SELECT FILE.</summary>
    cfrSfi);

  /// <summary>One explicit read-plan entry: folder plus logical or short file identifier.</summary>
  TCalypsoFileRef = record
    /// <summary>Addressing mode.</summary>
    Kind: TCalypsoFileRefKind;
    /// <summary>Folder LID: 0 means ticketing folder 2000, 3F00 the master file, otherwise a folder under the master file.</summary>
    Folder: Word;
    /// <summary>Nonzero logical file identifier for cfrLogicalId.</summary>
    LogicalId: Word;
    /// <summary>Short file identifier 1..30 for cfrSfi.</summary>
    Sfi: Byte;
  end;

  /// <summary>Ordered explicit read plan.</summary>
  TCalypsoFileRefs = array of TCalypsoFileRef;

  /// <summary>Injected authentication implementation using caller-owned legitimate keys or a SAM.</summary>
  /// <remarks>Use this interface for an external SDK, or the native SAM adapter in
  /// ERD.Card.Contactless.Calypso.SAM. No issuer keys, defaults, guesses or key searches are provided.</remarks>
  ICalypsoSecureSessionProvider = interface
    ['{48B73A50-BFB5-4A7C-A6AE-187985A0E9D6}']
    /// <summary>Authenticates and opens one read-only session inside the reader's exclusive transaction.</summary>
    /// <param name="ATransport">Raw connected transport, exclusively retained for this read.</param>
    /// <param name="ADialect">Explicit selected Calypso command dialect.</param>
    /// <param name="ASelectionData">Owned selection bytes of the current directory/file; do not retain mutable aliases.</param>
    /// <returns>Authenticated session; nil is an error, never permission to downgrade to public reads.</returns>
    /// <remarks>Provider cleans up a partially opened session if Open raises. It owns all key material
    /// and revision-specific authentication/SAM commands. Transport errors must not replay authentication.</remarks>
    function Open(const ATransport: ICardTransport;
      const ADialect: TCalypsoDialect; const ASelectionData: TBytes)
      : ICalypsoSecureReadSession;
  end;

  /// <summary>Calypso configuration, malformed response or unexpected card status.</summary>
  ECalypsoError = class(Exception);

  /// <summary>Unexpected card status, retaining no command or personal record data.</summary>
  ECalypsoStatusError = class(ECalypsoError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a sanitized failure carrying the returned status word.</summary>
    /// <param name="AStatusWord">Unexpected SW1/SW2.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Returned card status for diagnosing dialect or access failures.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>One successfully read, uninterpreted transit record.</summary>
  TCalypsoRecord = record
    /// <summary>Absolute record number, 1..255.</summary>
    Number: Byte;
    /// <summary>Independent raw record bytes; no issuer-specific schema is inferred.</summary>
    Data: TBytes;
  end;

  /// <summary>Successful records in ascending absolute-record order.</summary>
  TCalypsoRecords = array of TCalypsoRecord;

  /// <summary>One logical file selection and its public read outcomes.</summary>
  TCalypsoFile = record
    /// <summary>Explicit logical file identifier.</summary>
    LogicalId: Word;
    /// <summary>Exact successful SELECT response bytes, without status.</summary>
    SelectionData: TBytes;
    /// <summary>SELECT status; 6A82 means absent, 6982/6985 means restricted.</summary>
    SelectionStatus: Word;
    /// <summary>Successful public records; permission failures do not trigger authentication.</summary>
    Records: TCalypsoRecords;
    /// <summary>Last READ RECORD status; zero when no record was attempted.</summary>
    LastRecordStatus: Word;
    /// <summary>True when the caller's record bound was reached without an end marker.</summary>
    Truncated: Boolean;
    /// <summary>Folder LID used for this entry; 0 means ticketing folder 2000.</summary>
    Folder: Word;
    /// <summary>True when records were read by short file identifier without SELECT FILE.</summary>
    BySfi: Boolean;
    /// <summary>Short file identifier for SFI reads, otherwise the SFI reported by file information.</summary>
    Sfi: Byte;
    /// <summary>Decoded tag 85 header of SelectionData; Present is false for SFI reads.</summary>
    Info: TCalypsoFileInfo;
  end;

  /// <summary>Caller-owned file snapshots, retaining absent and restricted file states.</summary>
  TCalypsoFiles = array of TCalypsoFile;

  /// <summary>Raw MOBIB ticketing snapshot; no subscription validity or fare entitlement is inferred.</summary>
  TMobibSnapshot = record
    /// <summary>Exact successful selection response of ticketing directory 2000.</summary>
    TicketingSelection: TBytes;
    /// <summary>Environment, holder, events, contracts, counters, contract list and extended holder files.</summary>
    Files: TCalypsoFiles;
    /// <summary>Application selection outcome; Valid is false when ApplicationName was empty.</summary>
    Application: TCalypsoApplicationInfo;
  end;

  /// <summary>Inactive read-only Calypso logical-file/record component with a public MOBIB file profile.</summary>
  /// <remarks>Requires a connected contactless PC/SC/APDU transport, not a keyboard-only reader.
  /// Supplied dialect is explicit. Authentication requires an explicit secure-session provider (external SDK or the SAM adapter unit); no update, debit or reload is supplied.
  /// Raw files are preserved because schemas vary by issuer and card generation.</remarks>
  TCalypsoCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FDialect: TCalypsoDialect;
    FRecordBytes: Integer;
    FUseTransactions: Boolean;
    FRequireSecureSession: Boolean;
    FRecordSizeFromCard: Boolean;
    FApplicationName: string;
    FSecureSessionProvider: ICalypsoSecureSessionProvider;
    FSecureSession: ICalypsoSecureReadSession;
    FReadTransport: ICardTransport;
    FCurrentFolder: Word;
    procedure OpenSecureSession(const Selection: TBytes);
    procedure SetDialect(const V: TCalypsoDialect);
    procedure SetRecordBytes(const V: Integer);
    procedure SetApplicationName(const V: string);
    function Exchange(const C: TApduCommand): TApduResponse;
    function SelectFile(const Id: Word): TApduResponse;
    function SelectMasterFile: TApduResponse;
    function SelectApplicationInternal(const AName: string)
      : TCalypsoApplicationInfo;
    function ReadRecordsInto(var F: TCalypsoFile; const P2: Byte;
      const Le, Limit: Integer; const SfiRead: Boolean): Boolean;
    function ReadFileInternal(const Id: Word; const Limit: Integer)
      : TCalypsoFile;
    function ReadSfiInternal(const ASfi: Byte; const Limit: Integer)
      : TCalypsoFile;
    function EnterFolder(const AFolder: Word; out AStatus: Word): Boolean;
    function BeginRead: ICardTransaction;
    procedure EndRead(const T: ICardTransaction; const Success: Boolean);
  public
    /// <summary>Creates an inactive legacy-94 reader with 29-byte record Le and exclusive transactions.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Selects an application by DF name and decodes its FCI and startup information.</summary>
    /// <param name="AName">ASCII DF name, 1..16 characters, for example 1TIC.ICA.</param>
    /// <returns>Decoded information; the recommended dialect is not applied.</returns>
    /// <remarks>Uses ISO SELECT (CLA 00, P1 04). 6A82/6A81 (not found or not supported) return Valid false with StatusWord set;
    /// 6283 (invalidated) is decoded and keeps its status; any other non-9000 status raises ECalypsoStatusError.</remarks>
    function SelectApplication(const AName: string): TCalypsoApplicationInfo;
    /// <summary>Selects a known logical file and reads public records up to the caller's bound.</summary>
    /// <param name="ALogicalId">Known nonzero logical file identifier in the current application.</param>
    /// <param name="AMaxRecords">Maximum absolute records to attempt, 1..255.</param>
    /// <returns>Owned successful records plus absence/restriction/end or truncation state.</returns>
    /// <remarks>6A83 ends record reading. 6982/6985 preserves restriction status and any preceding reads.
    /// Unexpected statuses and transport errors abort without a snapshot. No fallback or authentication.</remarks>
    function ReadFile(const ALogicalId: Word; const AMaxRecords: Integer = 16)
      : TCalypsoFile;
    /// <summary>Reads records of a short file identifier in the current folder without SELECT FILE.</summary>
    /// <param name="ASfi">Short file identifier, 1..30.</param>
    /// <param name="AMaxRecords">Maximum absolute records to attempt, 1..255.</param>
    /// <returns>Records and terminal status; 6A82, 6981, 6B00 and 6A86 are recorded as unreadable.</returns>
    function ReadSfi(const ASfi: Byte; const AMaxRecords: Integer = 16)
      : TCalypsoFile;
    /// <summary>Selects ticketing directory 2000 and reads the defined public MOBIB logical-file profile.</summary>
    /// <param name="AMaxRecordsPerFile">Explicit per-file bound, 1..255.</param>
    /// <returns>Raw environment 2001, holder 2002, events 2010/2040, contracts 2020, counters 2069,
    /// contract list 2050 and extended holder 3F1C, with per-file status and truncation.</returns>
    /// <remarks>A missing or restricted ticketing directory aborts; missing/restricted elementary files
    /// are represented explicitly. A successful directory selection does not certify a card as MOBIB.</remarks>
    function ReadMobib(const AMaxRecordsPerFile: Integer = 16): TMobibSnapshot;
    /// <summary>Reads a caller-defined MOBIB logical-file plan within one ticketing and optional secure session.</summary>
    /// <param name="ALogicalIds">One to 64 nonzero unique logical IDs, in desired read order.</param>
    /// <param name="AMaxRecordsPerFile">Explicit record bound per file, 1..255.</param>
    /// <returns>Exact acquired files and status outcomes, without limiting reads to the standard eight-file profile.</returns>
    /// <remarks>Selects ticketing directory 2000 once. The selected reader and secure provider determine
    /// which files are accessible; there is no guessed enumeration or authentication fallback.</remarks>
    function ReadMobibFiles(const ALogicalIds: array of Word;
      const AMaxRecordsPerFile: Integer = 16): TMobibSnapshot;
    /// <summary>Reads an explicit plan of folder/LID and folder/SFI entries in one transaction.</summary>
    /// <param name="APlan">One to 128 unique entries, in read order.</param>
    /// <param name="AMaxRecordsPerFile">Explicit record bound per file, 1..255.</param>
    /// <returns>Snapshot with ticketing selection, optional application info and one file per entry.</returns>
    /// <remarks>Selects the application first when ApplicationName is set, then ticketing folder 2000.
    /// Entries in other folders select the master file 3F00 and then the folder; a folder that cannot
    /// be selected is recorded as that entry's SelectionStatus. Nothing is enumerated beyond the plan.</remarks>
    function ReadMobibPlan(const APlan: array of TCalypsoFileRef;
      const AMaxRecordsPerFile: Integer = 16): TMobibSnapshot;
    /// <summary>Creates a logical-identifier plan entry.</summary>
    /// <param name="AFolder">Folder LID; 0 for ticketing folder 2000.</param>
    /// <param name="ALogicalId">Nonzero logical file identifier.</param>
    /// <returns>Plan entry.</returns>
    class function FileRef(const AFolder, ALogicalId: Word): TCalypsoFileRef; static;
    /// <summary>Creates a short-file-identifier plan entry.</summary>
    /// <param name="AFolder">Folder LID; 0 for ticketing folder 2000.</param>
    /// <param name="ASfi">Short file identifier, 1..30.</param>
    /// <returns>Plan entry.</returns>
    class function SfiRef(const AFolder: Word; const ASfi: Byte): TCalypsoFileRef; static;
    /// <summary>Returns the bounded MOBIB/Intercode inventory: all known ticketing files plus ICC, ID and load-log files.</summary>
    /// <returns>Explicit list; it does not include an SFI sweep.</returns>
    class function MobibInventoryPlan: TCalypsoFileRefs; static;
    /// <summary>Returns SFI entries AFirst..ALast in one folder for an explicit, bounded sweep.</summary>
    /// <param name="AFolder">Folder LID; 0 for ticketing folder 2000.</param>
    /// <param name="AFirst">First SFI, 1..30.</param>
    /// <param name="ALast">Last SFI, AFirst..30.</param>
    /// <returns>Plan entries in ascending SFI order.</returns>
    class function SfiSweepPlan(const AFolder: Word; const AFirst: Byte = 1;
      const ALast: Byte = 30): TCalypsoFileRefs; static;
    /// <summary>Connected APDU transport retained by the reader.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Trusted external authentication/SAM adapter, used only when RequireSecureSession is true.</summary>
    /// <remarks>Its key material stays outside this component. The provider must outlive the read.</remarks>
    property SecureSessionProvider: ICalypsoSecureSessionProvider
      read FSecureSessionProvider write FSecureSessionProvider;
  published
    /// <summary>Explicit legacy-94 or ISO-00 dialect, default legacy-94.</summary>
    property Dialect: TCalypsoDialect read FDialect write SetDialect
      default cdLegacy94;
    /// <summary>Initial record Le, 1..256, default 29; one card-requested 6C length correction is permitted.</summary>
    property RecordBytes: Integer read FRecordBytes write SetRecordBytes
      default 29;
    /// <summary>Use the record size and count from each selected file's tag 85 header, default false.</summary>
    /// <remarks>When the header is missing or reports no record size, RecordBytes is used. SFI reads always use RecordBytes.</remarks>
    property RecordSizeFromCard: Boolean read FRecordSizeFromCard
      write FRecordSizeFromCard default False;
    /// <summary>Optional ASCII DF name selected before plan reads, for example 1TIC.ICA; empty by default.</summary>
    property ApplicationName: string read FApplicationName
      write SetApplicationName;
    /// <summary>Require verified provider-backed reads, default false; missing provider fails before card I/O.</summary>
    /// <remarks>No fallback to public reads on authentication or final-verification failure.</remarks>
    property RequireSecureSession: Boolean read FRequireSecureSession
      write FRequireSecureSession default False;
    /// <summary>Acquire one exclusive transaction for the whole read, default true; false requires caller exclusivity.</summary>
    property UseTransactions: Boolean read FUseTransactions
      write FUseTransactions default True;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail;
begin
  raise ECalypsoError.Create
    ('Calypso read failed; inspect configuration or card status.');
end;

const
  BufferSizes: array [0 .. $37] of Cardinal = (0, 0, 0, 0, 0, 0, 215, 256,
    304, 362, 430, 512, 608, 724, 861, 1024, 1217, 1448, 1722, 2048, 2435,
    2896, 3444, 4096, 4870, 5792, 6888, 8192, 9741, 11585, 13777, 16384,
    19483, 23170, 27554, 32768, 38967, 46340, 55108, 65536, 77935, 92681,
    110217, 131072, 155871, 185363, 220435, 262144, 311743, 370727, 440871,
    524288, 623487, 741455, 881743, 1048576);

function FindTlv(const D: TBytes; const Start, Stop: Integer; const Tag: Word;
  const Depth: Integer; out V: TBytes): Boolean;
var
  P, T, L: Integer;
  Constructed: Boolean;
begin
  Result := False;
  V := nil;
  P := Start;
  while P < Stop do
  begin
    if (D[P] = $00) or (D[P] = $FF) then
    begin
      Inc(P);
      Continue;
    end;
    T := D[P];
    Constructed := (T and $20) <> 0;
    Inc(P);
    if (T and $1F) = $1F then
    begin
      if (P >= Stop) or ((D[P] and $80) <> 0) then
        Exit;
      T := (T shl 8) or D[P];
      Inc(P);
    end;
    if P >= Stop then
      Exit;
    L := D[P];
    Inc(P);
    if L = $81 then
    begin
      if P >= Stop then
        Exit;
      L := D[P];
      Inc(P);
    end
    else if L = $82 then
    begin
      if P + 1 >= Stop then
        Exit;
      L := (D[P] shl 8) or D[P + 1];
      Inc(P, 2);
    end
    else if L > $7F then
      Exit;
    if L > Stop - P then
      Exit;
    if T = Tag then
    begin
      V := Copy(D, P, L);
      Result := True;
      Exit;
    end;
    if Constructed and (Depth < 8) and FindTlv(D, P, P + L, Tag, Depth + 1, V)
    then
    begin
      Result := True;
      Exit;
    end;
    Inc(P, L);
  end;
end;

class function TCalypsoFci.FindTag(const AData: TBytes; const ATag: Word;
  out AValue: TBytes): Boolean;
begin
  AValue := nil;
  if Length(AData) > 4096 then
    Fail;
  Result := FindTlv(AData, 0, Length(AData), ATag, 0, AValue);
end;

class function TCalypsoFci.DecodeStartupInfo(const ASerial,
  AStartupInfo: TBytes): TCalypsoApplicationInfo;
var
  T: Byte;
begin
  Result := Default (TCalypsoApplicationInfo);
  if (Length(ASerial) <> 8) or (Length(AStartupInfo) < 7) then
    Exit;
  Result.SerialNumber := CopyBytes(ASerial);
  Result.StartupInfo := CopyBytes(AStartupInfo);
  Result.BufferSizeIndicator := AStartupInfo[0];
  Result.PlatformCode := AStartupInfo[1];
  Result.ApplicationType := AStartupInfo[2];
  Result.ApplicationSubtype := AStartupInfo[3];
  Result.SoftwareIssuer := AStartupInfo[4];
  Result.SoftwareVersion := AStartupInfo[5];
  Result.SoftwareRevision := AStartupInfo[6];
  Result.Hce := (ASerial[3] and $80) <> 0;
  T := Result.ApplicationType;
  if (T = 0) or (T = $FF) then
    Result.ProductType := cptUnknown
  else if T <= $1F then
    Result.ProductType := cptPrimeRevision2
  else if (T >= $90) and (T <= $97) then
    Result.ProductType := cptLight
  else if (T >= $98) and (T <= $9F) then
    Result.ProductType := cptBasic
  else
    Result.ProductType := cptPrimeRevision3;
  if Result.ProductType in [cptPrimeRevision2, cptPrimeRevision3] then
  begin
    Result.HasPin := (T and $01) <> 0;
    Result.HasStoredValue := (T and $02) <> 0;
  end;
  if Result.ProductType = cptPrimeRevision3 then
  begin
    Result.RatificationCommandRequired := (T and $04) <> 0;
    Result.ExtendedMode := (T and $08) <> 0;
    Result.Pki := (T and $10) <> 0;
  end;
  if (Result.ProductType in [cptPrimeRevision3, cptLight]) and
    (Result.BufferSizeIndicator >= $06) and (Result.BufferSizeIndicator <= $37)
  then
    Result.BufferSizeBytes := BufferSizes[Result.BufferSizeIndicator];
  case Result.ProductType of
    cptPrimeRevision2:
      begin
        Result.HasRecommendedDialect := True;
        Result.RecommendedDialect := cdLegacy94;
      end;
    cptPrimeRevision3, cptLight, cptBasic:
      begin
        Result.HasRecommendedDialect := True;
        Result.RecommendedDialect := cdIso00;
      end;
  end;
  Result.Valid := Result.ProductType <> cptUnknown;
end;

class function TCalypsoFci.DecodeApplication(const AResponse: TBytes)
  : TCalypsoApplicationInfo;
var
  Name, Serial, Startup: TBytes;
begin
  Result := Default (TCalypsoApplicationInfo);
  if FindTag(AResponse, $C7, Serial) and FindTag(AResponse, $53, Startup) then
    Result := DecodeStartupInfo(Serial, Startup);
  if FindTag(AResponse, $84, Name) then
    Result.DfName := Name;
  Result.Response := CopyBytes(AResponse);
end;

class function TCalypsoFci.DecodeFileInfo(const ASelection: TBytes;
  const ARevision2: Boolean): TCalypsoFileInfo;
var
  P: TBytes;
  I: Integer;
begin
  Result := Default (TCalypsoFileInfo);
  if not FindTag(ASelection, $85, P) or (Length(P) <> 23) then
    Exit;
  Result.Present := True;
  Result.Raw := P;
  Result.Sfi := P[0];
  Result.KindCode := P[1];
  case P[1] of
    1:
      Result.Kind := cfkMasterFile;
    2:
      Result.Kind := cfkDedicatedFile;
    4:
      Result.Kind := cfkElementaryFile;
  end;
  if Result.Kind = cfkElementaryFile then
  begin
    Result.StructureCode := P[2];
    case P[2] of
      1:
        Result.Structure := cfsBinary;
      2:
        Result.Structure := cfsLinear;
      4:
        Result.Structure := cfsCyclic;
      8:
        Result.Structure := cfsSimulatedCounters;
      9:
        Result.Structure := cfsCounters;
    end;
    if Result.Structure = cfsBinary then
    begin
      Result.RecordSize := (Word(P[3]) shl 8) or P[4];
      Result.RecordCount := 1;
    end
    else
    begin
      Result.RecordSize := P[3];
      Result.RecordCount := P[4];
    end;
    Result.DataReference := (Word(P[14]) shl 8) or P[15];
  end;
  for I := 0 to 3 do
  begin
    Result.AccessConditions[I] := P[5 + I];
    Result.KeyIndexes[I] := P[9 + I];
  end;
  Result.DfStatus := P[13];
  if ARevision2 then
    Result.LogicalId := (Word(P[20]) shl 8) or P[21]
  else
    Result.LogicalId := (Word(P[21]) shl 8) or P[22];
end;

constructor ECalypsoStatusError.Create(const AStatusWord: Word);
begin
  inherited Create('Calypso card status ' + IntToHex(AStatusWord, 4) + '.');
  FStatusWord := AStatusWord;
end;

constructor TCalypsoCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRecordBytes := 29;
  FUseTransactions := True;
end;

procedure TCalypsoCardReader.SetDialect(const V: TCalypsoDialect);
begin
  if (Ord(V) < Ord(Low(TCalypsoDialect))) or
    (Ord(V) > Ord(High(TCalypsoDialect))) then
    Fail;
  FDialect := V;
end;

procedure TCalypsoCardReader.SetRecordBytes(const V: Integer);
begin
  if (V < 1) or (V > 256) then
    Fail;
  FRecordBytes := V;
end;

procedure CheckApplicationName(const V: string);
var
  I: Integer;
begin
  if Length(V) > 16 then
    Fail;
  for I := 1 to Length(V) do
    if (Ord(V[I]) < $21) or (Ord(V[I]) > $7E) then
      Fail;
end;

procedure TCalypsoCardReader.SetApplicationName(const V: string);
begin
  CheckApplicationName(V);
  FApplicationName := V;
end;

function TCalypsoCardReader.BeginRead: ICardTransaction;
begin
  Result := nil;
  if (FTransport = nil) or (FReadTransport <> nil) or
    (FRequireSecureSession and (FSecureSessionProvider = nil)) then
    Fail;
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Result) then
      Fail;
    Result.BeginTransaction;
  end;
  FReadTransport := FTransport;
end;

procedure TCalypsoCardReader.OpenSecureSession(const Selection: TBytes);
begin
  if not FRequireSecureSession or (FSecureSession <> nil) then
    Exit;
  FSecureSession := FSecureSessionProvider.Open(FTransport, FDialect,
    CopyBytes(Selection));
  if FSecureSession = nil then
    Fail;
  FReadTransport := FSecureSession.GetTransport;
  if FReadTransport = nil then
    Fail;
end;

procedure TCalypsoCardReader.EndRead(const T: ICardTransaction;
  const Success: Boolean);
begin
  if Success and (FSecureSession <> nil) then
    try
      FSecureSession.Finish;
    except
      try
        FSecureSession.Abort;
      except
      end;
      FSecureSession := nil;
      FReadTransport := nil;
      if T <> nil then
        try
          T.EndTransaction;
        except
        end;
      raise;
    end
  else if FSecureSession <> nil then
    try
      FSecureSession.Abort;
    except
    end;
  FSecureSession := nil;
  FReadTransport := nil;
  if T = nil then
    Exit;
  if Success then
    T.EndTransaction
  else
  begin
    try
      T.EndTransaction;
    except
    end;
  end;
end;

function TCalypsoCardReader.Exchange(const C: TApduCommand): TApduResponse;
var
  Command: TApduCommand;
  R: TApduResponse;
  Data: TBytes;
  Step, I, N: Integer;
  Corrected: Boolean;
begin
  Command := C;
  Data := nil;
  Corrected := False;
  Result := Default (TApduResponse);
  for Step := 1 to 16 do
  begin
    R := TApduCodec.DecodeResponse
      (FReadTransport.Exchange(TApduCodec.EncodeCommand(Command)));
    if ((R.StatusWord shr 8) = $6C) and not Corrected then
    begin
      if Length(R.Data) <> 0 then
        Fail;
      Command.HasLe := True;
      Command.Le := (R.StatusWord and $FF);
      if Command.Le = 0 then
        Command.Le := 256;
      Corrected := True;
      Continue;
    end;
    if (Length(Data) + Length(R.Data) > 4096) then
      Fail;
    N := Length(Data);
    SetLength(Data, N + Length(R.Data));
    for I := 0 to High(R.Data) do
      Data[N + I] := R.Data[I];
    if (R.StatusWord shr 8) <> $61 then
    begin
      Result := R;
      Result.Data := Data;
      Exit;
    end;
    Command := Default (TApduCommand);
    Command.CLA := C.CLA;
    Command.INS := $C0;
    Command.HasLe := True;
    Command.Le := (R.StatusWord and $FF);
    if Command.Le = 0 then
      Command.Le := 256;
    Corrected := False;
  end;
  Fail;
end;

function TCalypsoCardReader.SelectFile(const Id: Word): TApduResponse;
var
  C: TApduCommand;
begin
  C := Default (TApduCommand);
  if FDialect = cdLegacy94 then
    C.CLA := $94;
  if FDialect = cdIso00 then
    C.P1 := $09;
  C.INS := $A4;
  SetLength(C.Data, 2);
  C.Data[0] := Byte(Id shr 8);
  C.Data[1] := Byte(Id and $FF);
  C.HasLe := True;
  C.Le := 256;
  Result := Exchange(C);
end;

function TCalypsoCardReader.SelectMasterFile: TApduResponse;
var
  C: TApduCommand;
begin
  C := Default (TApduCommand);
  if FDialect = cdLegacy94 then
    C.CLA := $94;
  C.INS := $A4;
  SetLength(C.Data, 2);
  C.Data[0] := $3F;
  C.Data[1] := $00;
  C.HasLe := True;
  C.Le := 256;
  Result := Exchange(C);
end;

function TCalypsoCardReader.SelectApplicationInternal(const AName: string)
  : TCalypsoApplicationInfo;
var
  C: TApduCommand;
  R: TApduResponse;
  I: Integer;
begin
  C := Default (TApduCommand);
  C.INS := $A4;
  C.P1 := $04;
  SetLength(C.Data, Length(AName));
  for I := 1 to Length(AName) do
    C.Data[I - 1] := Byte(Ord(AName[I]));
  C.HasLe := True;
  C.Le := 256;
  R := Exchange(C);
  if (R.StatusWord = $6A82) or (R.StatusWord = $6A81) then
  begin
    Result := Default (TCalypsoApplicationInfo);
    Result.StatusWord := R.StatusWord;
    Exit;
  end;
  if (R.StatusWord <> $9000) and (R.StatusWord <> $6283) then
    raise ECalypsoStatusError.Create(R.StatusWord);
  Result := TCalypsoFci.DecodeApplication(R.Data);
  Result.StatusWord := R.StatusWord;
end;

function TCalypsoCardReader.ReadRecordsInto(var F: TCalypsoFile;
  const P2: Byte; const Le, Limit: Integer; const SfiRead: Boolean): Boolean;
var
  R: TApduResponse;
  C: TApduCommand;
  N, I: Integer;
begin
  Result := True;
  for N := 1 to Limit do
  begin
    C := Default (TApduCommand);
    if FDialect = cdLegacy94 then
      C.CLA := $94;
    C.INS := $B2;
    C.P1 := Byte(N);
    C.P2 := P2;
    C.HasLe := True;
    C.Le := Cardinal(Le);
    R := Exchange(C);
    F.LastRecordStatus := R.StatusWord;
    case R.StatusWord of
      $6A83, $6982, $6985:
        Exit;
      $9000:
        ;
    else
      if SfiRead and ((R.StatusWord = $6A82) or (R.StatusWord = $6981) or
        (R.StatusWord = $6B00) or (R.StatusWord = $6A86)) then
        Exit;
      raise ECalypsoStatusError.Create(R.StatusWord);
    end;
    if (Length(R.Data) = 0) or (Length(R.Data) > 256) then
      Fail;
    I := Length(F.Records);
    SetLength(F.Records, I + 1);
    F.Records[I].Number := Byte(N);
    F.Records[I].Data := R.Data;
  end;
  Result := False;
end;

function TCalypsoCardReader.ReadFileInternal(const Id: Word;
  const Limit: Integer): TCalypsoFile;
var
  R: TApduResponse;
  Le, Bound: Integer;
  CardBound: Boolean;
begin
  Result := Default (TCalypsoFile);
  Result.LogicalId := Id;
  R := SelectFile(Id);
  Result.SelectionStatus := R.StatusWord;
  case R.StatusWord of
    $6A82, $6982, $6985:
      Exit;
    $9000:
      ;
  else
    raise ECalypsoStatusError.Create(R.StatusWord);
  end;
  Result.SelectionData := R.Data;
  Result.Info := TCalypsoFci.DecodeFileInfo(R.Data);
  Result.Sfi := Result.Info.Sfi;
  OpenSecureSession(R.Data);
  Le := FRecordBytes;
  Bound := Limit;
  CardBound := False;
  if FRecordSizeFromCard and Result.Info.Present and
    (Result.Info.Kind = cfkElementaryFile) and
    (Result.Info.Structure in [cfsLinear, cfsCyclic, cfsSimulatedCounters,
    cfsCounters]) and (Result.Info.RecordSize > 0) then
  begin
    Le := Result.Info.RecordSize;
    if (Result.Info.RecordCount > 0) and (Result.Info.RecordCount <= Bound) then
    begin
      Bound := Result.Info.RecordCount;
      CardBound := True;
    end;
  end;
  if ReadRecordsInto(Result, 4, Le, Bound, False) then
    Exit;
  Result.Truncated := not CardBound;
end;

function TCalypsoCardReader.ReadSfiInternal(const ASfi: Byte;
  const Limit: Integer): TCalypsoFile;
begin
  Result := Default (TCalypsoFile);
  Result.BySfi := True;
  Result.Sfi := ASfi;
  if ReadRecordsInto(Result, Byte((ASfi shl 3) or 4), FRecordBytes, Limit,
    True) then
    Exit;
  Result.Truncated := True;
end;

function TCalypsoCardReader.EnterFolder(const AFolder: Word;
  out AStatus: Word): Boolean;
var
  Target: Word;
  R: TApduResponse;
begin
  Target := AFolder;
  if Target = 0 then
    Target := $2000;
  AStatus := $9000;
  Result := True;
  if Target = FCurrentFolder then
    Exit;
  FCurrentFolder := 0;
  R := SelectMasterFile;
  if R.StatusWord = $9000 then
  begin
    FCurrentFolder := $3F00;
    if Target <> $3F00 then
    begin
      R := SelectFile(Target);
      if R.StatusWord = $9000 then
        FCurrentFolder := Target;
    end;
  end;
  if R.StatusWord = $9000 then
    Exit;
  case R.StatusWord of
    $6A82, $6982, $6985, $6A86, $6B00:
      ;
  else
    raise ECalypsoStatusError.Create(R.StatusWord);
  end;
  FCurrentFolder := 0;
  AStatus := R.StatusWord;
  Result := False;
end;

function TCalypsoCardReader.SelectApplication(const AName: string)
  : TCalypsoApplicationInfo;
var
  T: ICardTransaction;
  D: TCalypsoApplicationInfo;
  Success: Boolean;
begin
  Result := Default (TCalypsoApplicationInfo);
  if AName = '' then
    Fail;
  CheckApplicationName(AName);
  T := BeginRead;
  Success := False;
  try
    D := SelectApplicationInternal(AName);
    Success := True;
  finally
    EndRead(T, Success);
  end;
  Result := D;
end;

function TCalypsoCardReader.ReadFile(const ALogicalId: Word;
  const AMaxRecords: Integer): TCalypsoFile;
var
  T: ICardTransaction;
  D: TCalypsoFile;
  Success: Boolean;
begin
  Result := Default (TCalypsoFile);
  if (ALogicalId = 0) or (AMaxRecords < 1) or (AMaxRecords > 255) then
    Fail;
  T := BeginRead;
  Success := False;
  try
    OpenSecureSession(nil);
    D := ReadFileInternal(ALogicalId, AMaxRecords);
    Success := True;
  finally
    EndRead(T, Success);
  end;
  Result := D;
end;

function TCalypsoCardReader.ReadSfi(const ASfi: Byte;
  const AMaxRecords: Integer): TCalypsoFile;
var
  T: ICardTransaction;
  D: TCalypsoFile;
  Success: Boolean;
begin
  Result := Default (TCalypsoFile);
  if (ASfi < 1) or (ASfi > 30) or (AMaxRecords < 1) or (AMaxRecords > 255) then
    Fail;
  T := BeginRead;
  Success := False;
  try
    OpenSecureSession(nil);
    D := ReadSfiInternal(ASfi, AMaxRecords);
    Success := True;
  finally
    EndRead(T, Success);
  end;
  Result := D;
end;

function TCalypsoCardReader.ReadMobib(const AMaxRecordsPerFile: Integer)
  : TMobibSnapshot;
const
  Ids: array [0 .. 7] of Word = ($2001, $2002, $2010, $2020, $2069, $2050,
    $2040, $3F1C);
begin
  Result := ReadMobibFiles(Ids, AMaxRecordsPerFile);
end;

function TCalypsoCardReader.ReadMobibFiles(const ALogicalIds: array of Word;
  const AMaxRecordsPerFile: Integer): TMobibSnapshot;
var
  Plan: TCalypsoFileRefs;
  I: Integer;
begin
  if (Length(ALogicalIds) < 1) or (Length(ALogicalIds) > 64) then
    Fail;
  SetLength(Plan, Length(ALogicalIds));
  for I := 0 to High(ALogicalIds) do
  begin
    if ALogicalIds[I] = 0 then
      Fail;
    Plan[I] := FileRef(0, ALogicalIds[I]);
  end;
  Result := ReadMobibPlan(Plan, AMaxRecordsPerFile);
end;

function SameRef(const A, B: TCalypsoFileRef): Boolean;
var
  FA, FB: Word;
begin
  FA := A.Folder;
  FB := B.Folder;
  if FA = 0 then
    FA := $2000;
  if FB = 0 then
    FB := $2000;
  Result := (A.Kind = B.Kind) and (FA = FB) and (A.LogicalId = B.LogicalId) and
    (A.Sfi = B.Sfi);
end;

function TCalypsoCardReader.ReadMobibPlan(const APlan: array of TCalypsoFileRef;
  const AMaxRecordsPerFile: Integer): TMobibSnapshot;
var
  T: ICardTransaction;
  D: TMobibSnapshot;
  R: TApduResponse;
  F: TCalypsoFile;
  Status: Word;
  Success: Boolean;
  I, J: Integer;
begin
  Result := Default (TMobibSnapshot);
  D := Default (TMobibSnapshot);
  if (AMaxRecordsPerFile < 1) or (AMaxRecordsPerFile > 255) or
    (Length(APlan) < 1) or (Length(APlan) > 128) then
    Fail;
  for I := 0 to High(APlan) do
  begin
    case APlan[I].Kind of
      cfrLogicalId:
        if (APlan[I].LogicalId = 0) or (APlan[I].Sfi <> 0) then
          Fail;
      cfrSfi:
        if (APlan[I].Sfi < 1) or (APlan[I].Sfi > 30) or
          (APlan[I].LogicalId <> 0) then
          Fail;
    else
      Fail;
    end;
    for J := 0 to I - 1 do
      if SameRef(APlan[I], APlan[J]) then
        Fail;
  end;
  T := BeginRead;
  Success := False;
  try
    FCurrentFolder := 0;
    if FApplicationName <> '' then
      D.Application := SelectApplicationInternal(FApplicationName);
    R := SelectFile($2000);
    if R.StatusWord <> $9000 then
      raise ECalypsoStatusError.Create(R.StatusWord);
    D.TicketingSelection := R.Data;
    FCurrentFolder := $2000;
    OpenSecureSession(R.Data);
    SetLength(D.Files, Length(APlan));
    for I := 0 to High(APlan) do
    begin
      if not EnterFolder(APlan[I].Folder, Status) then
      begin
        F := Default (TCalypsoFile);
        F.LogicalId := APlan[I].LogicalId;
        F.BySfi := APlan[I].Kind = cfrSfi;
        F.Sfi := APlan[I].Sfi;
        F.SelectionStatus := Status;
      end
      else if APlan[I].Kind = cfrSfi then
        F := ReadSfiInternal(APlan[I].Sfi, AMaxRecordsPerFile)
      else
        F := ReadFileInternal(APlan[I].LogicalId, AMaxRecordsPerFile);
      F.Folder := APlan[I].Folder;
      D.Files[I] := F;
    end;
    Success := True;
  finally
    FCurrentFolder := 0;
    EndRead(T, Success);
  end;
  Result := D;
end;

class function TCalypsoCardReader.FileRef(const AFolder, ALogicalId: Word)
  : TCalypsoFileRef;
begin
  Result := Default (TCalypsoFileRef);
  Result.Kind := cfrLogicalId;
  Result.Folder := AFolder;
  Result.LogicalId := ALogicalId;
end;

class function TCalypsoCardReader.SfiRef(const AFolder: Word; const ASfi: Byte)
  : TCalypsoFileRef;
begin
  Result := Default (TCalypsoFileRef);
  Result.Kind := cfrSfi;
  Result.Folder := AFolder;
  Result.Sfi := ASfi;
end;

class function TCalypsoCardReader.MobibInventoryPlan: TCalypsoFileRefs;
const
  Ticketing: array [0 .. 17] of Word = ($2001, $2002, $2004, $2010, $2020,
    $202A, $202B, $202C, $202D, $2030, $2040, $2050, $2060, $2062, $2069,
    $206A, $20F0, $3F1C);
  Master: array [0 .. 3] of Word = ($0002, $0003, $3F04, $2F10);
  Purse: array [0 .. 1] of Word = ($1014, $1015);
var
  I, N: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Ticketing) + Length(Master) + Length(Purse));
  N := 0;
  for I := 0 to High(Ticketing) do
  begin
    Result[N] := FileRef(0, Ticketing[I]);
    Inc(N);
  end;
  for I := 0 to High(Master) do
  begin
    Result[N] := FileRef($3F00, Master[I]);
    Inc(N);
  end;
  for I := 0 to High(Purse) do
  begin
    Result[N] := FileRef($1000, Purse[I]);
    Inc(N);
  end;
end;

class function TCalypsoCardReader.SfiSweepPlan(const AFolder: Word;
  const AFirst, ALast: Byte): TCalypsoFileRefs;
var
  I: Integer;
begin
  Result := nil;
  if (AFirst < 1) or (ALast > 30) or (AFirst > ALast) then
    Fail;
  SetLength(Result, ALast - AFirst + 1);
  for I := AFirst to ALast do
    Result[I - AFirst] := SfiRef(AFolder, Byte(I));
end;

end.
