unit ERD.Card.SIM.Reader;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  Classes, SysUtils,
{$ELSE}
  System.Classes, System.SysUtils,
{$ENDIF}
  ERD.Card.Transport, ERD.Card.SIM.Data;

type
  /// <summary>The card returned a non-success status; no command, credential or response data is retained.</summary>
  ESimCardStatusError = class(ESimCardError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a status-only sanitized card error.</summary>
    /// <param name="AStatusWord">Exact card status word.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Exact status word for diagnostics and explicit caller decisions.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>A dispatched mutating command has an uncertain outcome or cleanup; never replay it automatically.</summary>
  ESimCardWriteUncertain = class(ESimCardError)
  private
    FVerified: Boolean;
    FOriginalErrorClass: string;
  public
    /// <summary>Creates an uncertainty error without retaining backend exception text.</summary>
    /// <param name="AErrorClass">Original exception class only.</param>
    /// <param name="AVerified">Whether complete independent read-back had already matched.</param>
    constructor Create(const AErrorClass: string; const AVerified: Boolean);
      reintroduce;
    /// <summary>True only after complete independent read-back, even when subsequent cleanup failed.</summary>
    property VerifiedReadBack: Boolean read FVerified;
    /// <summary>Sanitized original exception class, without personal data or credentials.</summary>
    property OriginalErrorClass: string read FOriginalErrorClass;
  end;

  /// <summary>Inactive reusable classic SIM and UICC/USIM file/record reader with guarded, verified writes.</summary>
  /// <remarks>Needs an exclusive transaction-capable transport and a compatible SIM reader/adapter.
  /// Configuration and operations belong to one caller thread. No profile/AID/key probing, PUK guessing,
  /// PIN retry, toolkit FETCH, GSM network authentication or eSIM provisioning is performed.
  /// Reads/writes use actual card access rights; supplying a PIN does not grant operator/ADM rights.
  /// Owned PIN and command copies are wiped; strings, caller/native/backend copies are outside that guarantee.</remarks>
  TSimCardReaderWriter = class(TComponent)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FProfile: TSimCardProfile;
    FApplicationAid: TBytes;
    FPinReference: Byte;
    FMinimumPinAttempts: Integer;
    FBusy: Boolean;
    procedure RequireIdle;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetProfile(const AValue: TSimCardProfile);
    procedure SetApplicationAid(const AValue: TBytes);
    function GetApplicationAid: TBytes;
    procedure SetPinReference(const AValue: Byte);
    procedure SetMinimumPinAttempts(const AValue: Integer);
    procedure ValidateConfiguration;
    procedure ValidatePin(const APin: TBytes; const ARequired: Boolean);
    function OwnAddress(const AFile: TSimFileAddress; const APin: TBytes)
      : TSimFileAddress;
    procedure BeginOperation;
    procedure FinishOperation(const ASucceeded: Boolean);
    function Cla: Byte;
    function Send(const ACommand: TBytes; const AReadOnly: Boolean;
      const AHasLe: Boolean; const AMaxData: Integer;
      out AStatus: Word): TBytes;
    procedure RequireSuccess(const AStatus: Word);
    procedure Update(const ACommand: TBytes; var ADispatched: Boolean);
    function SelectFileId(const AFileId: Word): TSimFileInfo;
    procedure SelectRoot(const ARoot: TSimFileRoot);
    function SelectPath(const AFile: TSimFileAddress): TSimFileInfo;
    function ReadPinStatusSelected: TSimPinStatus;
    function PukStatusSelected: TSimPinStatus;
    function ReplaceCredential(const ACurrent, ANewPin: TBytes;
      const AUnblock: Boolean): TSimCredentialReceipt;
    function Authenticate(const APin: TBytes; const ARequireProof: Boolean)
      : TSimPinStatus;
    function InitializeFile(const AFile: TSimFileAddress; const APin: TBytes)
      : TSimFileInfo;
    function ReadBinarySelected(const AOffset, ACount: Integer): TBytes;
    function ReadRecordSelected(const ARecord, ACount: Integer): TBytes;
    procedure ValidateBinary(const AInfo: TSimFileInfo;
      const AOffset, ACount: Integer);
    procedure ValidateRecord(const AInfo: TSimFileInfo; const ARecord: Integer;
      const AWrite: Boolean);
    function IdentityAddress(const ALegacyDirectory, AFileId: Word)
      : TSimFileAddress;
  public
    /// <summary>True while one native operation owns the transport transaction.</summary>
    property Busy: Boolean read FBusy;
    /// <summary>Constructs an inactive classic SIM component with PIN1 and a one-attempt minimum budget.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases retained interfaces and clears locally owned application bytes; no card command is sent.</summary>
    destructor Destroy; override;
    /// <summary>Selects one explicit file and returns its strict geometry/access metadata without a PIN attempt.</summary>
    /// <param name="AFile">Explicit master/application root and numeric path.</param>
    /// <returns>Independent complete file metadata.</returns>
    function InspectFile(const AFile: TSimFileAddress): TSimFileInfo;
    /// <summary>Queries the configured PIN status without presenting a credential.</summary>
    /// <returns>Known retry/state information; unknown budgets remain minus one.</returns>
    function GetPinStatus: TSimPinStatus;
    /// <summary>Attempts one supplied PIN only with a known sufficient retry budget and an unverified enabled code.</summary>
    /// <param name="APin">Four through eight ASCII digit bytes; independently copied and wiped.</param>
    /// <returns>Proof of this supplied-code VERIFY; existing UICC verification alone is refused.</returns>
    function VerifyPin(const APin: TBytes): TSimPinStatus;
    /// <summary>Queries the configured PIN's unblock-code budget without presenting a PUK.</summary>
    /// <returns>Known PUK retries; unknown/unsupported card responses are explicit errors.</returns>
    function GetPukStatus: TSimPinStatus;
    /// <summary>Changes an enabled PIN once using supplied old/new ASCII digits and a known current retry budget.</summary>
    /// <param name="AOldPin">Four through eight ASCII digits; owned copies are wiped.</param>
    /// <param name="ANewPin">Four through eight ASCII digits.</param>
    /// <returns>Card acceptance receipt; fresh-session new-PIN verification is separate.</returns>
    /// <exception cref="ESimCardWriteUncertain">Credential mutation was dispatched but acceptance or cleanup cannot be established.</exception>
    function ChangePin(const AOldPin, ANewPin: TBytes): TSimCredentialReceipt;
    /// <summary>Resets PIN retries and replaces the PIN once using an explicit PUK with a known sufficient unblock budget.</summary>
    /// <param name="APuk">Exactly eight supplied ASCII digits; no guessed/default PUK.</param>
    /// <param name="ANewPin">Four through eight new ASCII digits.</param>
    /// <returns>Card acceptance receipt, not proof of a fresh-session new PIN.</returns>
    /// <exception cref="ESimCardWriteUncertain">UNBLOCK was dispatched but outcome or cleanup is uncertain.</exception>
    function UnblockPin(const APuk, ANewPin: TBytes): TSimCredentialReceipt;
    /// <summary>Applies an explicit bounded linear-fixed record plan under one exclusive transaction.</summary>
    /// <param name="AChanges">One through 8192 unique records, complete original and replacement bytes, in caller-defined order.</param>
    /// <param name="AExpectedIccid">Exact expected card ICCID, checked inside the retained transaction before authentication/writes.</param>
    /// <param name="APin">Optional borrowed ASCII PIN; owned copies are wiped, at most one authentication step.</param>
    /// <param name="AResults">Per-record dispatch/read-back evidence, retained on exceptions, including cleanup failure.</param>
    /// <remarks>All originals are checked before any UPDATE and again immediately before each UPDATE.
    /// Each mutation is verified before proceeding; multi-record changes are not atomic. Never retries.</remarks>
    /// <exception cref="ESimCardWriteUncertain">Any UPDATE occurred and the overall action or cleanup failed.</exception>
    procedure WriteRecordPlan(const AChanges: TSimRecordChanges;
      const AExpectedIccid: UnicodeString; const APin: TBytes;
      out AResults: TSimRecordWriteResults);
    /// <summary>Applies an explicit ordered linked-phonebook record plan under one exclusive transaction.</summary>
    /// <param name="AChanges">One through 32 unique phonebook records, exact expected/replacement bytes and explicit USIM paths; links remain caller-defined.</param>
    /// <param name="APin">Optional supplied ASCII PIN; authentication occurs at most once.</param>
    /// <remarks>All expected records are checked before the first UPDATE; each final record is read back. Multi-file writes are not atomic and are never rolled back/replayed.</remarks>
    /// <exception cref="ESimCardWriteUncertain">Any UPDATE was dispatched without complete outcome/cleanup proof.</exception>
    procedure WriteLinkedPhonebookRecords(const AChanges: TSimRecordChanges;
      const APin: TBytes = nil);
    /// <summary>Reads a complete transparent file using its actual selected geometry.</summary>
    /// <param name="AFile">Explicit root and directory/EF path.</param>
    /// <param name="APin">Optional supplied ASCII PIN, used only when authentication is needed.</param>
    /// <returns>Owned exact file bytes; files exceeding 32768 bytes are refused, never truncated.</returns>
    function ReadFile(const AFile: TSimFileAddress;
      const APin: TBytes = nil): TBytes;
    /// <summary>Reads one bounded range from a transparent file.</summary>
    /// <param name="AFile">Explicit root and path.</param>
    /// <param name="AOffset">Absolute byte offset zero through 32767.</param>
    /// <param name="ACount">One through 32768 bytes, entirely inside the addressable file range.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Owned complete requested range.</returns>
    function ReadBinaryRange(const AFile: TSimFileAddress;
      const AOffset, ACount: Integer; const APin: TBytes = nil): TBytes;
    /// <summary>Reads one absolute linear-fixed or cyclic record without advancing an implicit pointer.</summary>
    /// <param name="AFile">Explicit record EF path.</param>
    /// <param name="ARecord">One-based absolute record, checked against actual file geometry.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Owned complete record.</returns>
    function ReadRecord(const AFile: TSimFileAddress; const ARecord: Integer;
      const APin: TBytes = nil): TBytes;
    /// <summary>Reads all declared absolute records under one exclusive transaction.</summary>
    /// <param name="AFile">Explicit linear-fixed/cyclic EF path.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Independently allocated exact record buffers.</returns>
    function ReadRecords(const AFile: TSimFileAddress; const APin: TBytes = nil)
      : TSimRecords;
    /// <summary>Updates a complete transparent EF after exact expected-state comparison and verifies all bytes.</summary>
    /// <param name="AFile">Explicit EF path; access rights are enforced by the actual card.</param>
    /// <param name="AExpectedBefore">Exact current complete file, one through 32768 bytes.</param>
    /// <param name="AData">Replacement complete file of the same length.</param>
    /// <param name="APin">Optional supplied ASCII PIN; no default/ADM credential is inferred.</param>
    /// <exception cref="ESimCardWriteUncertain">An UPDATE was dispatched without complete outcome/cleanup proof.</exception>
    procedure WriteFile(const AFile: TSimFileAddress;
      const AExpectedBefore, AData: TBytes; const APin: TBytes = nil);
    /// <summary>Updates one linear-fixed record once after expected-state comparison and independent read-back.</summary>
    /// <param name="AFile">Explicit linear-fixed EF path; cyclic writes are refused.</param>
    /// <param name="ARecord">One-based absolute record.</param>
    /// <param name="AExpectedBefore">Exact current complete record.</param>
    /// <param name="AData">Replacement record of the same actual length.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <exception cref="ESimCardWriteUncertain">An UPDATE was dispatched without complete outcome/cleanup proof.</exception>
    procedure WriteRecord(const AFile: TSimFileAddress; const ARecord: Integer;
      const AExpectedBefore, AData: TBytes; const APin: TBytes = nil);
    /// <summary>Reads and decodes master-file EF.ICCID without a code attempt.</summary>
    /// <returns>Nineteen/twenty decimal digits; no network identity or Luhn proof.</returns>
    function ReadIccid: UnicodeString;
    /// <summary>Reads the selected profile's IMSI using the configured USIM AID when applicable.</summary>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Decoded IMSI; access depends on card permissions.</returns>
    function ReadImsi(const APin: TBytes = nil): UnicodeString;
    /// <summary>Reads and decodes classic SST or USIM UST; activation/rights beyond these bits are not guessed.</summary>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Numbered declared service states.</returns>
    function ReadServices(const APin: TBytes = nil): TSimServices;
    /// <summary>Reads the selected profile's service-provider-name file.</summary>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Decoded display condition and name; absence remains an explicit card error.</returns>
    function ReadSpn(const APin: TBytes = nil): TSimServiceProvider;
    /// <summary>Enumerates UICC EF.DIR without automatically choosing an application.</summary>
    /// <returns>Owned application entries; requires the explicit UICC profile.</returns>
    function ReadApplications: TSimApplications;
    /// <summary>Reads and decodes an explicitly addressed ADN/MSISDN-style file.</summary>
    /// <param name="AFile">Actual contact EF path; USIM PBR/IAP links are not guessed.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <returns>Owned contacts with physical record numbers and unresolved extension references.</returns>
    function ReadPhonebook(const AFile: TSimFileAddress;
      const APin: TBytes = nil): TSimPhonebookEntries;
    /// <summary>Reads one explicit PBR/ADN contact and referenced EFs under a single exclusive USIM transaction.</summary>
    /// <param name="APbrRecord">One-based record in USIM DF.PHONEBOOK EF.PBR.</param>
    /// <param name="AAdnFileId">Explicit actual ADN file identifier reported by PBR.</param>
    /// <param name="ARecord">One-based ADN record.</param>
    /// <param name="APin">Optional supplied ASCII PIN; at most one authentication step.</param>
    /// <returns>Owned contact, IAP-linked raw fields and validated extended number; no linked writes.</returns>
    function ReadLinkedUsimContact(const APbrRecord: Integer;
      const AAdnFileId: Word; const ARecord: Integer; const APin: TBytes = nil)
      : TSimLinkedContact;
    /// <summary>Encodes and verifies one standalone ADN contact without dropping linked CCP/EXT data.</summary>
    /// <param name="AFile">Explicit actual contact EF path.</param>
    /// <param name="ARecord">One-based absolute record.</param>
    /// <param name="AExpectedBefore">Exact current record; CCP/EXT references must both be absent FF.</param>
    /// <param name="AName">GSM/UCS-2 contact name, never truncated.</param>
    /// <param name="ANumber">Inline TBCD dial string with at most twenty symbols; optional initial plus.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <exception cref="ESimCardWriteUncertain">An UPDATE was dispatched without complete outcome/cleanup proof.</exception>
    procedure WritePhonebookContact(const AFile: TSimFileAddress;
      const ARecord: Integer; const AExpectedBefore: TBytes;
      const AName, ANumber: UnicodeString; const APin: TBytes = nil);
    /// <summary>Erases and verifies a standalone contact record; linked records are refused.</summary>
    /// <param name="AFile">Explicit contact EF path.</param>
    /// <param name="ARecord">One-based absolute record.</param>
    /// <param name="AExpectedBefore">Exact current record with absent CCP/EXT references.</param>
    /// <param name="APin">Optional supplied ASCII PIN.</param>
    /// <exception cref="ESimCardWriteUncertain">An UPDATE was dispatched without complete outcome/cleanup proof.</exception>
    procedure DeletePhonebookContact(const AFile: TSimFileAddress;
      const ARecord: Integer; const AExpectedBefore: TBytes;
      const APin: TBytes = nil);
    /// <summary>Retained external byte transport; operations require ICardTransaction.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
    /// <summary>Owned complete USIM AID, seven through sixteen bytes starting A0000000871002; no automatic choice.</summary>
    property ApplicationAid: TBytes read GetApplicationAid
      write SetApplicationAid;
  published
    /// <summary>Explicit classic A0 or UICC/USIM 00 dialect.</summary>
    property Profile: TSimCardProfile read FProfile write SetProfile
      default scpGsmSim;
    /// <summary>Exact PIN key reference: classic 1/2; UICC 01..08, 11 or 81..88.</summary>
    property PinReference: Byte read FPinReference write SetPinReference
      default 1;
    /// <summary>Known minimum retries required before a supplied-code attempt, one through fifteen.</summary>
    property MinimumPinAttempts: Integer read FMinimumPinAttempts
      write SetMinimumPinAttempts default 1;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.APDU;

procedure Fail(const AReason: string);
begin
  raise ESimCardError.Create('Invalid SIM operation: ' + AReason + '.');
end;

function Success(const S: Word): Boolean;
begin
  Result := (S = $9000) or (S shr 8 = $91);
end;

constructor ESimCardStatusError.Create(const AStatusWord: Word);
begin
  inherited Create('SIM card rejected the command; status ' +
    IntToHex(AStatusWord, 4) + '.');
  FStatusWord := AStatusWord;
end;

constructor ESimCardWriteUncertain.Create(const AErrorClass: string;
  const AVerified: Boolean);
begin
  inherited Create
    ('SIM UPDATE outcome or cleanup is uncertain; do not replay automatically.');
  FOriginalErrorClass := AErrorClass;
  FVerified := AVerified;
end;

constructor TSimCardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProfile := scpGsmSim;
  FPinReference := 1;
  FMinimumPinAttempts := 1;
end;

destructor TSimCardReaderWriter.Destroy;
begin
  FTransport := nil;
  FTransaction := nil;
  TCardCrypto.Clear(FApplicationAid);
  inherited Destroy;
end;

procedure TSimCardReaderWriter.RequireIdle;
begin
  if FBusy then
    Fail('operation already active');
end;

procedure TSimCardReaderWriter.SetTransport(const AValue: ICardTransport);
begin
  RequireIdle;
  FTransport := AValue;
end;

procedure TSimCardReaderWriter.SetProfile(const AValue: TSimCardProfile);
begin
  RequireIdle;
  if not(AValue in [scpGsmSim, scpUiccUsim]) then
    Fail('profile');
  FProfile := AValue;
end;

procedure TSimCardReaderWriter.SetApplicationAid(const AValue: TBytes);
var
  Prefix: TBytes;
  I: Integer;
begin
  RequireIdle;
  if Length(AValue) > 0 then
  begin
    if (Length(AValue) < 7) or (Length(AValue) > 16) then
      Fail('USIM AID length');
    Prefix := HexToBytes('A0000000871002');
    for I := 0 to 6 do
      if AValue[I] <> Prefix[I] then
        Fail('USIM AID prefix');
  end;
  FApplicationAid := CopyBytes(AValue);
end;

function TSimCardReaderWriter.GetApplicationAid: TBytes;
begin
  Result := CopyBytes(FApplicationAid);
end;

procedure TSimCardReaderWriter.SetPinReference(const AValue: Byte);
begin
  RequireIdle;
  if not((AValue in [1 .. 8]) or (AValue = $11) or (AValue in [$81 .. $88]))
  then
    Fail('PIN reference');
  FPinReference := AValue;
end;

procedure TSimCardReaderWriter.SetMinimumPinAttempts(const AValue: Integer);
begin
  RequireIdle;
  if (AValue < 1) or (AValue > 15) then
    Fail('minimum PIN attempts');
  FMinimumPinAttempts := AValue;
end;

procedure TSimCardReaderWriter.ValidateConfiguration;
begin
  RequireIdle;
  if (FProfile = scpGsmSim) and not(FPinReference in [1, 2]) then
    Fail('classic CHV reference');
end;

procedure TSimCardReaderWriter.ValidatePin(const APin: TBytes;
  const ARequired: Boolean);
var
  I: Integer;
begin
  if (Length(APin) = 0) and not ARequired then
    Exit;
  if (Length(APin) < 4) or (Length(APin) > 8) then
    Fail('ASCII PIN length');
  for I := 0 to High(APin) do
    if not(APin[I] in [Ord('0') .. Ord('9')]) then
      Fail('ASCII PIN digits');
end;

function TSimCardReaderWriter.OwnAddress(const AFile: TSimFileAddress;
  const APin: TBytes): TSimFileAddress;
begin
  ValidateConfiguration;
  ValidatePin(APin, False);
  Result := TSimCodec.FileAddress(AFile.Root, AFile.Path);
  if AFile.Root = sfrUsimApplication then
  begin
    if (FProfile <> scpUiccUsim) or (Length(FApplicationAid) = 0) then
      Fail('explicit USIM AID required');
  end;
  if (FProfile = scpUiccUsim) and (AFile.Root = sfrMasterFile) and
    (Length(APin) > 0) then
    Fail('USIM PIN belongs to the explicit application scope');
end;

procedure TSimCardReaderWriter.BeginOperation;
begin
  RequireIdle;
  if (FTransport = nil) or not Supports(FTransport, ICardTransaction,
    FTransaction) then
    Fail('exclusive transaction required');
  FBusy := True;
  try
    FTransaction.BeginTransaction;
  except
    FTransaction := nil;
    FBusy := False;
    raise;
  end;
end;

procedure TSimCardReaderWriter.FinishOperation(const ASucceeded: Boolean);
var
  T: ICardTransaction;
begin
  T := FTransaction;
  FTransaction := nil;
  try
    if ASucceeded then
      T.EndTransaction
    else
      try
        T.EndTransaction;
      except
      end;
  finally
    FBusy := False;
  end;
end;

function TSimCardReaderWriter.Cla: Byte;
begin
  if FProfile = scpGsmSim then
    Result := $A0
  else
    Result := $00;
end;

function TSimCardReaderWriter.Send(const ACommand: TBytes;
  const AReadOnly: Boolean; const AHasLe: Boolean; const AMaxData: Integer;
  out AStatus: Word): TBytes;
var
  Current, Wire, Data: TBytes;
  Response: TApduResponse;
  Calls, N: Integer;
  HasLe, Corrected: Boolean;
begin
  Result := nil;
  Current := CopyBytes(ACommand);
  Wire := nil;
  HasLe := AHasLe;
  Corrected := False;
  try
    for Calls := 1 to 16 do
    begin
      TCardCrypto.Clear(Wire);
      Wire := FTransport.Exchange(Current);
      if (Length(Wire) < 2) or (Length(Wire) > AMaxData + 2) then
        Fail('response bounds');
      Response := TApduCodec.DecodeResponse(Wire);
      AStatus := Response.StatusWord;
      Data := Response.Data;
      if AReadOnly and HasLe and (AStatus shr 8 = $6C) then
      begin
        if Corrected or (Length(Data) <> 0) or (Length(Result) <> 0) then
          Fail('repeated/ambiguous length correction');
        Current[High(Current)] := AStatus and $FF;
        Corrected := True;
        Continue;
      end;
      N := Length(Result);
      if Length(Data) > AMaxData - N then
        Fail('response accumulation');
      SetLength(Result, N + Length(Data));
      if Length(Data) > 0 then
        Move(Data[0], Result[N], Length(Data));
      if AReadOnly and ((AStatus shr 8 = $61) or ((FProfile = scpGsmSim) and
        (AStatus shr 8 = $9F))) then
      begin
        TCardCrypto.Clear(Current);
        Current := HexToBytes('00C0000000');
        Current[0] := Cla;
        Current[4] := AStatus and $FF;
        HasLe := True;
        Corrected := False;
        Continue;
      end;
      Exit;
    end;
    Fail('continuation limit');
  finally
    TCardCrypto.Clear(Current);
    TCardCrypto.Clear(Wire);
  end;
end;

procedure TSimCardReaderWriter.RequireSuccess(const AStatus: Word);
begin
  if not Success(AStatus) then
    raise ESimCardStatusError.Create(AStatus);
end;

procedure TSimCardReaderWriter.Update(const ACommand: TBytes;
  var ADispatched: Boolean);
var
  Cmd, Wire: TBytes;
  Response: TApduResponse;
begin
  Cmd := nil;
  Wire := nil;
  try
    Cmd := CopyBytes(ACommand);
    ADispatched := True;
    Wire := FTransport.Exchange(Cmd);
    if Length(Wire) <> 2 then
      Fail('UPDATE response framing');
    Response := TApduCodec.DecodeResponse(Wire);
    RequireSuccess(Response.StatusWord);
  finally
    TCardCrypto.Clear(Cmd);
    TCardCrypto.Clear(Wire);
  end;
end;

function TSimCardReaderWriter.SelectFileId(const AFileId: Word): TSimFileInfo;
var
  Cmd, B: TBytes;
  S: Word;
begin
  Cmd := HexToBytes('00A40000020000');
  Cmd[0] := Cla;
  Cmd[5] := AFileId shr 8;
  Cmd[6] := AFileId and $FF;
  if FProfile = scpUiccUsim then
  begin
    Cmd[3] := $04;
    SetLength(Cmd, 8);
    Cmd[7] := 0;
  end;
  B := Send(Cmd, True, FProfile = scpUiccUsim, 4096, S);
  RequireSuccess(S);
  Result := TSimCodec.DecodeFileInfo(FProfile, B);
  if Result.FileId <> AFileId then
    Fail('selected file identity mismatch');
end;

procedure TSimCardReaderWriter.SelectRoot(const ARoot: TSimFileRoot);
var
  Info: TSimFileInfo;
  Cmd, B: TBytes;
  S: Word;
begin
  if ARoot = sfrMasterFile then
    Info := SelectFileId($3F00)
  else
  begin
    if (FProfile <> scpUiccUsim) or (Length(FApplicationAid) = 0) then
      Fail('USIM application required');
    Cmd := HexToBytes('00A4040400');
    Cmd[4] := Length(FApplicationAid);
    SetLength(Cmd, 6 + Length(FApplicationAid));
    Move(FApplicationAid[0], Cmd[5], Length(FApplicationAid));
    Cmd[High(Cmd)] := 0;
    B := Send(Cmd, True, True, 4096, S);
    RequireSuccess(S);
    Info := TSimCodec.DecodeFileInfo(FProfile, B);
    if not BytesEqual(Info.ApplicationAid, FApplicationAid) then
      Fail('selected application identity mismatch');
  end;
  if Info.Structure <> sfsDirectory then
    Fail('root is not a directory');
end;

function TSimCardReaderWriter.SelectPath(const AFile: TSimFileAddress)
  : TSimFileInfo;
var
  I: Integer;
begin
  SelectRoot(AFile.Root);
  for I := 0 to High(AFile.Path) do
  begin
    Result := SelectFileId(AFile.Path[I]);
    if (I < High(AFile.Path)) and (Result.Structure <> sfsDirectory) then
      Fail('non-directory path segment');
  end;
  if Result.Structure = sfsDirectory then
    Fail('an elementary file is required');
end;

function TSimCardReaderWriter.ReadPinStatusSelected: TSimPinStatus;
var
  Info: TSimFileInfo;
  Cmd, B: TBytes;
  S: Word;
  StatusByte: Byte;
begin
  Result := Default (TSimPinStatus);
  Result.RemainingAttempts := -1;
  if FProfile = scpGsmSim then
  begin
    SelectRoot(sfrMasterFile);
    Info := SelectFileId($7F20);
    if (Info.Structure <> sfsDirectory) or (Length(Info.Raw) < 22) then
      Fail('GSM directory status');
    StatusByte := Info.Raw[18 + 2 * (FPinReference - 1)];
    Result.RemainingAttempts := StatusByte and 15;
    Result.Initialized := StatusByte and $80 <> 0;
    Result.Blocked := Result.RemainingAttempts = 0;
    Result.Disabled := (FPinReference = 1) and (Info.Raw[13] and $80 <> 0);
  end
  else
  begin
    SelectRoot(sfrUsimApplication);
    Cmd := HexToBytes('00200000');
    Cmd[3] := FPinReference;
    B := Send(Cmd, False, False, 0, S);
    if Length(B) <> 0 then
      Fail('PIN status data');
    Result.Initialized := True;
    Result.VerificationKnown := True;
    if Success(S) then
      Result.Verified := True
    else if S and $FFF0 = $63C0 then
    begin
      Result.RemainingAttempts := S and 15;
      Result.Blocked := Result.RemainingAttempts = 0;
    end
    else if S = $6983 then
    begin
      Result.RemainingAttempts := 0;
      Result.Blocked := True;
    end
    else
      raise ESimCardStatusError.Create(S);
  end;
end;

function TSimCardReaderWriter.Authenticate(const APin: TBytes;
  const ARequireProof: Boolean): TSimPinStatus;
var
  Cmd, B: TBytes;
  S: Word;
begin
  Result := ReadPinStatusSelected;
  if not ARequireProof and ((Result.VerificationKnown and Result.Verified) or
    Result.Disabled) then
    Exit;
  if Result.Disabled or (Result.VerificationKnown and Result.Verified) then
    Fail('fresh supplied-code proof unavailable in the current state');
  if not Result.Initialized or Result.Blocked or
    (Result.RemainingAttempts < FMinimumPinAttempts) then
    Fail('known PIN retry budget required');
  Cmd := nil;
  try
    Cmd := HexToBytes('0020000000');
    Cmd[0] := Cla;
    Cmd[3] := FPinReference;
    Cmd[4] := 8;
    SetLength(Cmd, 13);
    FillChar(Cmd[5], 8, $FF);
    Move(APin[0], Cmd[5], Length(APin));
    B := Send(Cmd, False, False, 0, S);
    RequireSuccess(S);
    if Length(B) <> 0 then
      Fail('VERIFY result data');
    Result.Verified := True;
    Result.VerificationKnown := True;
    Result.RemainingAttempts := -1;
  finally
    TCardCrypto.Clear(Cmd);
  end;
end;

function TSimCardReaderWriter.PukStatusSelected: TSimPinStatus;
var
  Info: TSimFileInfo;
  Cmd, B: TBytes;
  S: Word;
  Value: Byte;
begin
  Result := Default (TSimPinStatus);
  Result.RemainingAttempts := -1;
  if FProfile = scpGsmSim then
  begin
    SelectRoot(sfrMasterFile);
    Info := SelectFileId($7F20);
    if Length(Info.Raw) < 22 then
      Fail('GSM PUK status header');
    Value := Info.Raw[19 + 2 * (FPinReference - 1)];
    Result.Initialized := Value and $80 <> 0;
    Result.RemainingAttempts := Value and 15;
    Result.Blocked := Result.RemainingAttempts = 0;
  end
  else
  begin
    SelectRoot(sfrUsimApplication);
    Cmd := HexToBytes('002C0000');
    Cmd[3] := FPinReference;
    B := Send(Cmd, False, False, 0, S);
    if Length(B) <> 0 then
      Fail('PUK query data');
    if S and $FFF0 = $63C0 then
    begin
      Result.Initialized := True;
      Result.RemainingAttempts := S and 15;
      Result.Blocked := Result.RemainingAttempts = 0;
    end
    else if S = $6983 then
    begin
      Result.Initialized := True;
      Result.RemainingAttempts := 0;
      Result.Blocked := True;
    end
    else
      raise ESimCardStatusError.Create(S);
  end;
end;

function TSimCardReaderWriter.GetPukStatus: TSimPinStatus;
var
  Good: Boolean;
begin
  RequireIdle;
  ValidateConfiguration;
  BeginOperation;
  Good := False;
  try
    Result := PukStatusSelected;
    Good := True;
  finally
    FinishOperation(Good);
  end;
end;

function TSimCardReaderWriter.ReplaceCredential(const ACurrent, ANewPin: TBytes;
  const AUnblock: Boolean): TSimCredentialReceipt;
var
  Current, NewPin, Cmd: TBytes;
  Status: TSimPinStatus;
  Good, Dispatched: Boolean;
begin
  RequireIdle;
  ValidateConfiguration;
  ValidatePin(ACurrent, True);
  ValidatePin(ANewPin, True);
  if AUnblock and (Length(ACurrent) <> 8) then
    Fail('PUK must have eight ASCII digits');
  Current := nil;
  NewPin := nil;
  Cmd := nil;
  Result := Default (TSimCredentialReceipt);
  try
    Current := CopyBytes(ACurrent);
    NewPin := CopyBytes(ANewPin);
    BeginOperation;
    Good := False;
    Dispatched := False;
    try
      try
        if AUnblock then
          Status := PukStatusSelected
        else
          Status := ReadPinStatusSelected;
        if not Status.Initialized or Status.Disabled or Status.Blocked or
          (Status.RemainingAttempts < FMinimumPinAttempts) then
          Fail('known sufficient credential budget required');
        Cmd := HexToBytes('0024000010');
        Cmd[0] := Cla;
        Cmd[3] := FPinReference;
        if AUnblock then
          Cmd[1] := $2C;
        SetLength(Cmd, 21);
        FillChar(Cmd[5], 16, $FF);
        Move(Current[0], Cmd[5], Length(Current));
        Move(NewPin[0], Cmd[13], Length(NewPin));
        Update(Cmd, Dispatched);
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ESimCardWriteUncertain.Create(E.ClassName, False);
        raise;
      end;
    end;
    Result.CommandAccepted := True;
  finally
    TCardCrypto.Clear(Current);
    TCardCrypto.Clear(NewPin);
    TCardCrypto.Clear(Cmd);
  end;
end;

function TSimCardReaderWriter.ChangePin(const AOldPin, ANewPin: TBytes)
  : TSimCredentialReceipt;
begin
  Result := ReplaceCredential(AOldPin, ANewPin, False);
end;

function TSimCardReaderWriter.UnblockPin(const APuk, ANewPin: TBytes)
  : TSimCredentialReceipt;
begin
  Result := ReplaceCredential(APuk, ANewPin, True);
end;

procedure TSimCardReaderWriter.WriteRecordPlan(const AChanges: TSimRecordChanges;
  const AExpectedIccid: UnicodeString; const APin: TBytes;
  out AResults: TSimRecordWriteResults);
var
  Changes: TSimRecordChanges;
  Pin, Actual, Cmd: TBytes;
  Info: TSimFileInfo;
  I, J, K: Integer;
  Good, Dispatched, Verified, SamePath: Boolean;
begin
  RequireIdle;
  AResults := nil;
  if (Length(AChanges) < 1) or (Length(AChanges) > 8192) or
    (Length(AExpectedIccid) < 19) or (Length(AExpectedIccid) > 20) then
    Fail('explicit linked write budget');
  Changes := nil;
  Pin := nil;
  Cmd := nil;
  try
    ValidatePin(APin, False);
    SetLength(Changes, Length(AChanges));
    for I := 0 to High(Changes) do
    begin
      Changes[I].FileAddress := OwnAddress(AChanges[I].FileAddress, APin);
      Changes[I].RecordNumber := AChanges[I].RecordNumber;
      if (Changes[I].RecordNumber < 1) or (Changes[I].RecordNumber > 255) or
        (Length(AChanges[I].Data) < 1) or (Length(AChanges[I].Data) > 255) or
        (Length(AChanges[I].ExpectedBefore) <> Length(AChanges[I].Data)) then
        Fail('complete linked record');
      for J := 0 to I - 1 do
        if (Changes[J].FileAddress.Root = Changes[I].FileAddress.Root) and
          (Length(Changes[J].FileAddress.Path) = Length(Changes[I].FileAddress.Path)) and
          (Changes[J].RecordNumber = Changes[I].RecordNumber) then
        begin
          SamePath := True;
          for K := 0 to High(Changes[I].FileAddress.Path) do
            if Changes[J].FileAddress.Path[K] <> Changes[I].FileAddress.Path[K] then SamePath := False;
          if SamePath then
            Fail('duplicate record write');
        end;
      Changes[I].ExpectedBefore := CopyBytes(AChanges[I].ExpectedBefore);
      Changes[I].Data := CopyBytes(AChanges[I].Data);
    end;
    Actual := TSimCodec.EncodeIccid(AExpectedIccid);
    SetLength(AResults, Length(Changes));
    Pin := CopyBytes(APin);
    BeginOperation;
    Good := False;
    Dispatched := False;
    Verified := False;
    try
      try
        Info := SelectPath(TSimCodec.FileAddress(sfrMasterFile, [$2FE2]));
        ValidateBinary(Info, 0, Info.Size);
        Actual := ReadBinarySelected(0, Info.Size);
        if TSimCodec.DecodeIccid(Actual) <> AExpectedIccid then Fail('card identity changed');
        if Length(Pin) > 0 then
          Authenticate(Pin, False);
        for I := 0 to High(Changes) do
        begin
          Info := SelectPath(Changes[I].FileAddress);
          ValidateRecord(Info, Changes[I].RecordNumber, True);
          if Info.RecordBytes <> Length(Changes[I].Data) then
            Fail('linked record geometry');
          Actual := ReadRecordSelected(Changes[I].RecordNumber,
            Info.RecordBytes);
          if not BytesEqual(Actual, Changes[I].ExpectedBefore) then
            Fail('linked expected state mismatch');
        end;
        for I := 0 to High(Changes) do
          if not BytesEqual(Changes[I].ExpectedBefore, Changes[I].Data) then
          begin
            Info := SelectPath(Changes[I].FileAddress);
            ValidateRecord(Info, Changes[I].RecordNumber, True);
            if Info.RecordBytes <> Length(Changes[I].Data) then
              Fail('changed linked geometry');
            Actual := ReadRecordSelected(Changes[I].RecordNumber,
              Info.RecordBytes);
            if not BytesEqual(Actual, Changes[I].ExpectedBefore) then
              Fail('changed linked state');
            Cmd := HexToBytes('00DC000400');
            Cmd[0] := Cla;
            Cmd[2] := Changes[I].RecordNumber;
            Cmd[4] := Length(Changes[I].Data);
            SetLength(Cmd, 5 + Length(Changes[I].Data));
            Move(Changes[I].Data[0], Cmd[5], Length(Changes[I].Data));
            AResults[I].Dispatched := True;
            Update(Cmd, Dispatched);
            Actual := ReadRecordSelected(Changes[I].RecordNumber, Info.RecordBytes);
            if not BytesEqual(Actual, Changes[I].Data) then Fail('record read-back mismatch');
            AResults[I].Verified := True;
            TCardCrypto.Clear(Cmd);
          end;
        for I := 0 to High(Changes) do
        begin
          Info := SelectPath(Changes[I].FileAddress);
          ValidateRecord(Info, Changes[I].RecordNumber, False);
          if Info.RecordBytes <> Length(Changes[I].Data) then
            Fail('linked read-back geometry');
          Actual := ReadRecordSelected(Changes[I].RecordNumber,
            Info.RecordBytes);
          if not BytesEqual(Actual, Changes[I].Data) then
            Fail('linked read-back mismatch');
          AResults[I].Verified := True;
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ESimCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Pin);
    TCardCrypto.Clear(Cmd);
  end;
end;

procedure TSimCardReaderWriter.WriteLinkedPhonebookRecords(const AChanges
  : TSimRecordChanges; const APin: TBytes);
var
  Changes: TSimRecordChanges;
  Pin, Actual, Cmd: TBytes;
  Info: TSimFileInfo;
  I, J: Integer;
  Good, Dispatched, Verified: Boolean;
begin
  RequireIdle;
  if (FProfile <> scpUiccUsim) or (Length(AChanges) < 1) or
    (Length(AChanges) > 32) then
    Fail('explicit linked write budget');
  Changes := nil;
  Pin := nil;
  Cmd := nil;
  try
    ValidatePin(APin, False);
    SetLength(Changes, Length(AChanges));
    for I := 0 to High(Changes) do
    begin
      Changes[I].FileAddress := OwnAddress(AChanges[I].FileAddress, APin);
      if (Changes[I].FileAddress.Root <> sfrUsimApplication) or
        (Length(Changes[I].FileAddress.Path) <> 2) then
        Fail('explicit phonebook path');
      if (Changes[I].FileAddress.Path[0] <> $5F3A) or
        (Changes[I].FileAddress.Path[1] = $4F30) then
        Fail('phonebook data EF required');
      Changes[I].RecordNumber := AChanges[I].RecordNumber;
      if (Changes[I].RecordNumber < 1) or (Changes[I].RecordNumber > 255) or
        (Length(AChanges[I].Data) < 1) or (Length(AChanges[I].Data) > 255) or
        (Length(AChanges[I].ExpectedBefore) <> Length(AChanges[I].Data)) then
        Fail('complete linked record');
      for J := 0 to I - 1 do
        if (Changes[J].FileAddress.Path[1] = Changes[I].FileAddress.Path[1]) and
          (Changes[J].RecordNumber = Changes[I].RecordNumber) then
          Fail('duplicate linked write');
      Changes[I].ExpectedBefore := CopyBytes(AChanges[I].ExpectedBefore);
      Changes[I].Data := CopyBytes(AChanges[I].Data);
    end;
    Pin := CopyBytes(APin);
    BeginOperation;
    Good := False;
    Dispatched := False;
    Verified := False;
    try
      try
        if Length(Pin) > 0 then
          Authenticate(Pin, False);
        for I := 0 to High(Changes) do
        begin
          Info := SelectPath(Changes[I].FileAddress);
          ValidateRecord(Info, Changes[I].RecordNumber, True);
          if Info.RecordBytes <> Length(Changes[I].Data) then
            Fail('linked record geometry');
          Actual := ReadRecordSelected(Changes[I].RecordNumber,
            Info.RecordBytes);
          if not BytesEqual(Actual, Changes[I].ExpectedBefore) then
            Fail('linked expected state mismatch');
        end;
        for I := 0 to High(Changes) do
          if not BytesEqual(Changes[I].ExpectedBefore, Changes[I].Data) then
          begin
            Info := SelectPath(Changes[I].FileAddress);
            ValidateRecord(Info, Changes[I].RecordNumber, True);
            if Info.RecordBytes <> Length(Changes[I].Data) then
              Fail('changed linked geometry');
            Actual := ReadRecordSelected(Changes[I].RecordNumber,
              Info.RecordBytes);
            if not BytesEqual(Actual, Changes[I].ExpectedBefore) then
              Fail('changed linked state');
            Cmd := HexToBytes('00DC000400');
            Cmd[2] := Changes[I].RecordNumber;
            Cmd[4] := Length(Changes[I].Data);
            SetLength(Cmd, 5 + Length(Changes[I].Data));
            Move(Changes[I].Data[0], Cmd[5], Length(Changes[I].Data));
            Update(Cmd, Dispatched);
            TCardCrypto.Clear(Cmd);
          end;
        for I := 0 to High(Changes) do
        begin
          Info := SelectPath(Changes[I].FileAddress);
          ValidateRecord(Info, Changes[I].RecordNumber, False);
          if Info.RecordBytes <> Length(Changes[I].Data) then
            Fail('linked read-back geometry');
          Actual := ReadRecordSelected(Changes[I].RecordNumber,
            Info.RecordBytes);
          if not BytesEqual(Actual, Changes[I].Data) then
            Fail('linked read-back mismatch');
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ESimCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Pin);
    TCardCrypto.Clear(Cmd);
  end;
end;

function TSimCardReaderWriter.InitializeFile(const AFile: TSimFileAddress;
  const APin: TBytes): TSimFileInfo;
begin
  if Length(APin) > 0 then
    Authenticate(APin, False);
  Result := SelectPath(AFile);
end;

procedure TSimCardReaderWriter.ValidateBinary(const AInfo: TSimFileInfo;
  const AOffset, ACount: Integer);
begin
  if (AInfo.Structure <> sfsTransparent) or (AOffset < 0) or (AOffset > 32767)
    or (ACount < 0) or (ACount > 32768 - AOffset) or (AOffset > AInfo.Size) or
    (ACount > AInfo.Size - AOffset) then
    Fail('transparent range');
end;

procedure TSimCardReaderWriter.ValidateRecord(const AInfo: TSimFileInfo;
  const ARecord: Integer; const AWrite: Boolean);
begin
  if not(AInfo.Structure in [sfsLinearFixed, sfsCyclic]) or
    (AWrite and (AInfo.Structure <> sfsLinearFixed)) or (ARecord < 1) or
    (ARecord > AInfo.RecordCount) then
    Fail('absolute record geometry');
end;

function TSimCardReaderWriter.ReadBinarySelected(const AOffset,
  ACount: Integer): TBytes;
var
  Done, Count: Integer;
  Cmd, B: TBytes;
  S: Word;
begin
  Result := nil;
  SetLength(Result, ACount);
  Done := 0;
  while Done < ACount do
  begin
    Count := ACount - Done;
    if Count > 256 then
      Count := 256;
    Cmd := HexToBytes('00B0000000');
    Cmd[0] := Cla;
    Cmd[2] := (AOffset + Done) shr 8;
    Cmd[3] := (AOffset + Done) and $FF;
    Cmd[4] := Count mod 256;
    B := Send(Cmd, True, True, Count, S);
    RequireSuccess(S);
    if Length(B) <> Count then
      Fail('incomplete binary read');
    Move(B[0], Result[Done], Count);
    Inc(Done, Count);
  end;
end;

function TSimCardReaderWriter.ReadRecordSelected(const ARecord,
  ACount: Integer): TBytes;
var
  Cmd: TBytes;
  S: Word;
begin
  Cmd := HexToBytes('00B2000400');
  Cmd[0] := Cla;
  Cmd[1] := $B2;
  Cmd[2] := ARecord;
  Cmd[4] := ACount;
  Result := Send(Cmd, True, True, ACount, S);
  RequireSuccess(S);
  if Length(Result) <> ACount then
    Fail('incomplete record read');
end;

function TSimCardReaderWriter.InspectFile(const AFile: TSimFileAddress)
  : TSimFileInfo;
var
  FileAddress: TSimFileAddress;
  Good: Boolean;
begin
  FileAddress := OwnAddress(AFile, nil);
  BeginOperation;
  Good := False;
  try
    Result := SelectPath(FileAddress);
    Good := True;
  finally
    FinishOperation(Good);
  end;
end;

function TSimCardReaderWriter.GetPinStatus: TSimPinStatus;
var
  Good: Boolean;
begin
  ValidateConfiguration;
  if (FProfile = scpUiccUsim) and (Length(FApplicationAid) = 0) then
    Fail('USIM AID required');
  BeginOperation;
  Good := False;
  try
    Result := ReadPinStatusSelected;
    Good := True;
  finally
    FinishOperation(Good);
  end;
end;

function TSimCardReaderWriter.VerifyPin(const APin: TBytes): TSimPinStatus;
var
  Pin: TBytes;
  Good: Boolean;
begin
  ValidateConfiguration;
  ValidatePin(APin, True);
  if (FProfile = scpUiccUsim) and (Length(FApplicationAid) = 0) then
    Fail('USIM AID required');
  Pin := CopyBytes(APin);
  try
    BeginOperation;
    Good := False;
    try
      Result := Authenticate(Pin, True);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

function TSimCardReaderWriter.ReadFile(const AFile: TSimFileAddress;
  const APin: TBytes): TBytes;
var
  FileAddress: TSimFileAddress;
  Pin: TBytes;
  Info: TSimFileInfo;
  Good: Boolean;
begin
  FileAddress := OwnAddress(AFile, APin);
  Pin := CopyBytes(APin);
  try
    BeginOperation;
    Good := False;
    try
      Info := InitializeFile(FileAddress, Pin);
      ValidateBinary(Info, 0, Info.Size);
      Result := ReadBinarySelected(0, Info.Size);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

function TSimCardReaderWriter.ReadBinaryRange(const AFile: TSimFileAddress;
  const AOffset, ACount: Integer; const APin: TBytes): TBytes;
var
  FileAddress: TSimFileAddress;
  Pin: TBytes;
  Info: TSimFileInfo;
  Good: Boolean;
begin
  FileAddress := OwnAddress(AFile, APin);
  if (AOffset < 0) or (AOffset > 32767) or (ACount < 1) or
    (ACount > 32768 - AOffset) then
    Fail('binary range bounds');
  Pin := CopyBytes(APin);
  try
    BeginOperation;
    Good := False;
    try
      Info := InitializeFile(FileAddress, Pin);
      ValidateBinary(Info, AOffset, ACount);
      Result := ReadBinarySelected(AOffset, ACount);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

function TSimCardReaderWriter.ReadRecord(const AFile: TSimFileAddress;
  const ARecord: Integer; const APin: TBytes): TBytes;
var
  FileAddress: TSimFileAddress;
  Pin: TBytes;
  Info: TSimFileInfo;
  Good: Boolean;
begin
  FileAddress := OwnAddress(AFile, APin);
  if (ARecord < 1) or (ARecord > 255) then
    Fail('record number');
  Pin := CopyBytes(APin);
  try
    BeginOperation;
    Good := False;
    try
      Info := InitializeFile(FileAddress, Pin);
      ValidateRecord(Info, ARecord, False);
      Result := ReadRecordSelected(ARecord, Info.RecordBytes);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

function TSimCardReaderWriter.ReadRecords(const AFile: TSimFileAddress;
  const APin: TBytes): TSimRecords;
var
  FileAddress: TSimFileAddress;
  Pin: TBytes;
  Info: TSimFileInfo;
  Good: Boolean;
  I: Integer;
begin
  FileAddress := OwnAddress(AFile, APin);
  Pin := CopyBytes(APin);
  Result := nil;
  try
    BeginOperation;
    Good := False;
    try
      Info := InitializeFile(FileAddress, Pin);
      ValidateRecord(Info, 1, False);
      SetLength(Result, Info.RecordCount);
      for I := 1 to Info.RecordCount do
        Result[I - 1] := ReadRecordSelected(I, Info.RecordBytes);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

procedure TSimCardReaderWriter.WriteFile(const AFile: TSimFileAddress;
  const AExpectedBefore, AData, APin: TBytes);
var
  FileAddress: TSimFileAddress;
  Pin, Before, Data, Actual, Cmd: TBytes;
  Info: TSimFileInfo;
  Good, Dispatched, Verified: Boolean;
  Done, Count: Integer;
begin
  FileAddress := OwnAddress(AFile, APin);
  if (Length(AData) < 1) or (Length(AData) > 32768) or
    (Length(AExpectedBefore) <> Length(AData)) then
    Fail('complete expected file length');
  Pin := nil;
  Cmd := nil;
  try
    Pin := CopyBytes(APin);
    Before := CopyBytes(AExpectedBefore);
    Data := CopyBytes(AData);
    BeginOperation;
    Good := False;
    Dispatched := False;
    Verified := False;
    try
      try
        Info := InitializeFile(FileAddress, Pin);
        ValidateBinary(Info, 0, Info.Size);
        if Info.Size <> Length(Data) then
          Fail('replacement must cover the exact complete EF');
        Actual := ReadBinarySelected(0, Info.Size);
        if not BytesEqual(Actual, Before) then
          Fail('expected file mismatch');
        if not BytesEqual(Before, Data) then
        begin
          Done := 0;
          while Done < Length(Data) do
          begin
            Count := Length(Data) - Done;
            if Count > 255 then
              Count := 255;
            Cmd := HexToBytes('00D6000000');
            Cmd[0] := Cla;
            Cmd[2] := Done shr 8;
            Cmd[3] := Done and $FF;
            Cmd[4] := Count;
            SetLength(Cmd, 5 + Count);
            Move(Data[Done], Cmd[5], Count);
            Update(Cmd, Dispatched);
            TCardCrypto.Clear(Cmd);
            Inc(Done, Count);
          end;
          Actual := ReadBinarySelected(0, Info.Size);
          if not BytesEqual(Actual, Data) then
            Fail('file read-back mismatch');
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ESimCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Pin);
    TCardCrypto.Clear(Cmd);
  end;
end;

procedure TSimCardReaderWriter.WriteRecord(const AFile: TSimFileAddress;
  const ARecord: Integer; const AExpectedBefore, AData, APin: TBytes);
var
  FileAddress: TSimFileAddress;
  Pin, Before, Data, Actual, Cmd: TBytes;
  Info: TSimFileInfo;
  Good, Dispatched, Verified: Boolean;
begin
  FileAddress := OwnAddress(AFile, APin);
  if (ARecord < 1) or (ARecord > 255) or (Length(AData) < 1) or
    (Length(AData) > 255) or (Length(AExpectedBefore) <> Length(AData)) then
    Fail('complete expected record bounds');
  Pin := nil;
  Cmd := nil;
  try
    Pin := CopyBytes(APin);
    Before := CopyBytes(AExpectedBefore);
    Data := CopyBytes(AData);
    BeginOperation;
    Good := False;
    Dispatched := False;
    Verified := False;
    try
      try
        Info := InitializeFile(FileAddress, Pin);
        ValidateRecord(Info, ARecord, True);
        if Length(Data) <> Info.RecordBytes then
          Fail('replacement record length');
        Actual := ReadRecordSelected(ARecord, Info.RecordBytes);
        if not BytesEqual(Actual, Before) then
          Fail('expected record mismatch');
        if not BytesEqual(Before, Data) then
        begin
          Cmd := HexToBytes('00DC000400');
          Cmd[0] := Cla;
          Cmd[2] := ARecord;
          Cmd[4] := Length(Data);
          SetLength(Cmd, 5 + Length(Data));
          Move(Data[0], Cmd[5], Length(Data));
          Update(Cmd, Dispatched);
          TCardCrypto.Clear(Cmd);
          Actual := ReadRecordSelected(ARecord, Info.RecordBytes);
          if not BytesEqual(Actual, Data) then
            Fail('record read-back mismatch');
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ESimCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Pin);
    TCardCrypto.Clear(Cmd);
  end;
end;

function TSimCardReaderWriter.IdentityAddress(const ALegacyDirectory,
  AFileId: Word): TSimFileAddress;
begin
  if FProfile = scpGsmSim then
    Result := TSimCodec.FileAddress(sfrMasterFile, [ALegacyDirectory, AFileId])
  else
    Result := TSimCodec.FileAddress(sfrUsimApplication, [AFileId]);
end;

function TSimCardReaderWriter.ReadIccid: UnicodeString;
begin
  Result := TSimCodec.DecodeIccid(ReadFile(TSimCodec.FileAddress(sfrMasterFile,
    [$2FE2])));
end;

function TSimCardReaderWriter.ReadImsi(const APin: TBytes): UnicodeString;
begin
  Result := TSimCodec.DecodeImsi(ReadFile(IdentityAddress($7F20, $6F07), APin));
end;

function TSimCardReaderWriter.ReadServices(const APin: TBytes): TSimServices;
begin
  Result := TSimCodec.DecodeServices(FProfile,
    ReadFile(IdentityAddress($7F20, $6F38), APin));
end;

function TSimCardReaderWriter.ReadSpn(const APin: TBytes): TSimServiceProvider;
begin
  Result := TSimCodec.DecodeSpn(ReadFile(IdentityAddress($7F20, $6F46), APin));
end;

function TSimCardReaderWriter.ReadApplications: TSimApplications;
var
  Records: TSimRecords;
  Entry: TSimApplicationInfo;
  I, N: Integer;
begin
  if FProfile <> scpUiccUsim then
    Fail('EF.DIR requires the explicit UICC profile');
  Records := ReadRecords(TSimCodec.FileAddress(sfrMasterFile, [$2F00]));
  Result := nil;
  for I := 0 to High(Records) do
  begin
    Entry := TSimCodec.DecodeDirectoryRecord(Records[I]);
    if Length(Entry.Aid) > 0 then
    begin
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := Entry;
    end;
  end;
end;

function TSimCardReaderWriter.ReadPhonebook(const AFile: TSimFileAddress;
  const APin: TBytes): TSimPhonebookEntries;
var
  Records: TSimRecords;
  I: Integer;
begin
  Records := ReadRecords(AFile, APin);
  Result := nil;
  SetLength(Result, Length(Records));
  for I := 0 to High(Records) do
  begin
    Result[I] := TSimCodec.DecodeAdn(Records[I]);
    Result[I].RecordNumber := I + 1;
  end;
end;

function TSimCardReaderWriter.ReadLinkedUsimContact(const APbrRecord: Integer;
  const AAdnFileId: Word; const ARecord: Integer; const APin: TBytes)
  : TSimLinkedContact;
var
  Address: TSimFileAddress;
  Pin: TBytes;
  Info: TSimFileInfo;
  Refs: TSimPhonebookReferences;
  Files: TSimPhonebookFiles;
  Good, Found: Boolean;
  I, J, K, N: Integer;
begin
  RequireIdle;
  if (FProfile <> scpUiccUsim) or (APbrRecord < 1) or (APbrRecord > 255) or
    (ARecord < 1) or (ARecord > 255) or (AAdnFileId = 0) or (AAdnFileId = $3F00)
    or (AAdnFileId = $FFFF) then
    Fail('explicit USIM contact selection');
  Address := OwnAddress(TSimCodec.FileAddress(sfrUsimApplication,
    [$5F3A, $4F30]), APin);
  Pin := CopyBytes(APin);
  Files := nil;
  try
    BeginOperation;
    Good := False;
    try
      Info := InitializeFile(Address, Pin);
      ValidateRecord(Info, APbrRecord, False);
      Refs := TSimCodec.DecodePhonebookReferences(ReadRecordSelected(APbrRecord,
        Info.RecordBytes));
      Found := False;
      for I := 0 to High(Refs) do
        if (Refs[I].RoleTag = $C0) and (Refs[I].FileId = AAdnFileId) then
          Found := True;
      if not Found then
        Fail('ADN FID not reported by selected PBR');
      for I := 0 to High(Refs) do
      begin
        Found := False;
        for J := 0 to High(Files) do
          if Files[J].FileId = Refs[I].FileId then
            Found := True;
        if Found then
          Continue;
        N := Length(Files);
        if N >= 32 then
          Fail('phonebook file budget');
        SetLength(Files, N + 1);
        Files[N].FileId := Refs[I].FileId;
        Info := SelectPath(TSimCodec.FileAddress(sfrUsimApplication,
          [$5F3A, Refs[I].FileId]));
        ValidateRecord(Info, 1, False);
        if Info.Structure <> sfsLinearFixed then
          Fail('phonebook file must be linear fixed');
        SetLength(Files[N].Records, Info.RecordCount);
        for K := 1 to Info.RecordCount do
          Files[N].Records[K - 1] := ReadRecordSelected(K, Info.RecordBytes);
      end;
      Result := TSimCodec.ResolvePhonebookContact(Refs, Files, AAdnFileId,
        ARecord);
      Good := True;
    finally
      FinishOperation(Good);
    end;
  finally
    TCardCrypto.Clear(Pin);
  end;
end;

procedure TSimCardReaderWriter.WritePhonebookContact
  (const AFile: TSimFileAddress; const ARecord: Integer;
  const AExpectedBefore: TBytes; const AName, ANumber: UnicodeString;
  const APin: TBytes);
var
  Data: TBytes;
begin
  RequireIdle;
  if (Length(AExpectedBefore) < 14) or (Length(AExpectedBefore) > 255) then
    Fail('ADN expected record');
  if (AExpectedBefore[High(AExpectedBefore)] <> $FF) or
    (AExpectedBefore[High(AExpectedBefore) - 1] <> $FF) then
    Fail('linked ADN records need explicit extension/capability handling');
  Data := TSimCodec.EncodeAdn(AName, ANumber, Length(AExpectedBefore));
  WriteRecord(AFile, ARecord, AExpectedBefore, Data, APin);
end;

procedure TSimCardReaderWriter.DeletePhonebookContact
  (const AFile: TSimFileAddress; const ARecord: Integer;
  const AExpectedBefore, APin: TBytes);
begin
  WritePhonebookContact(AFile, ARecord, AExpectedBefore, '', '', APin);
end;

end.
