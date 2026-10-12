unit ERD.Card.Contactless.Workflow.DESFire;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless, ERD.Card.Crypto,
  ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.DESFire.Extensions;

type
  /// <summary>Complete readable ordinary application file, excluding keys and hidden configuration.</summary>
  TDesfireWorkflowFile = record
    /// <summary>Acquired native file geometry, rights and independent raw settings.</summary>
    Settings: TDesfireFileSettings;
    /// <summary>Complete data bytes, signed little-endian value, or records in newest-first order.</summary>
    Data: TBytes;
  end;
  /// <summary>Independently owned complete ordinary application file images.</summary>
  TDesfireWorkflowFiles = array of TDesfireWorkflowFile;
  /// <summary>Selected application snapshot; no authentication keys or synthesized unreadable bytes.</summary>
  TDesfireWorkflowSnapshot = record
    /// <summary>Source native application identifier, one through FFFFFF.</summary>
    Aid: Cardinal;
    /// <summary>Observed native version UID, not an authentication certificate.</summary>
    Identity: TBytes;
    /// <summary>Complete readable ordinary files; empty applications are supported.</summary>
    Files: TDesfireWorkflowFiles;
  end;
  /// <summary>Explicit ordinary file-creation template array.</summary>
  TDesfireWorkflowDefinitions = array of TDesfireFileDefinition;
  /// <summary>Inactive application access factory; credentials and security dialect are supplied by the application.</summary>
  /// <remarks>Exclusive caller ownership spans each phase. All mutation methods dispatch once;
  /// post-dispatch failures must raise EContactlessWriteUncertain. Session implementations must
  /// implement native outcome/verification semantics, including commit verification and release.</remarks>
  IDesfireWorkflowCard = interface
    ['{402FF88B-B95C-498F-9D4E-779DC9047173}']
    /// <summary>Returns aggregate transfer/journal limit without I/O.</summary>
    /// <returns>One through DesfireMaxTransferBytes.</returns>
    function TransferLimit: Integer;
    /// <summary>Acquires an independent observed native card identity.</summary>
    /// <returns>Nonempty card identifier; not proof of authenticity.</returns>
    function ReadIdentity: TBytes;
    /// <summary>Opens one retained exclusive session with explicit authority.</summary>
    /// <param name="AAid">Application identifier; zero only for management.</param>
    /// <param name="AAccess">Read, management or explicit transaction ownership.</param>
    /// <returns>Owned session, closed by the workflow on the executing thread.</returns>
    function OpenSession(const AAid: Cardinal; const AAccess: TDesfireSessionAccess): IDesfireSession;
    /// <summary>Checks configured rights and communication mode without I/O.</summary>
    /// <param name="ASettings">Acquired target settings.</param>
    /// <param name="AValueIncrease">True requires ordinary Credit rights for a value file.</param>
    procedure ValidateWrite(const ASettings: TDesfireFileSettings; const AValueIncrease: Boolean);
    /// <summary>Writes and verifies one complete standard data file outside a backup transaction.</summary>
    /// <param name="AAid">Target application.</param>
    /// <param name="AFile">Native standard file number.</param>
    /// <param name="AData">Complete data bytes.</param>
    procedure WriteStandard(const AAid: Cardinal; const AFile: Byte; const AData: TBytes);
  end;
  /// <summary>Explicit complete rights for one provisioned file; no authentication key material.</summary>
  TDesfireWorkflowFilePolicy = record
    /// <summary>Native file number.</summary>
    FileNumber: Byte;
    /// <summary>Primary and optional additional complete rights tuples.</summary>
    Rights: TDesfireAccessRightSets;
  end;
  /// <summary>Unique caller-selected per-file provisioning policies.</summary>
  TDesfireWorkflowFilePolicies = array of TDesfireWorkflowFilePolicy;
  /// <summary>Optional profile-aware workflow lifecycle and commit evidence.</summary>
  IDesfireWorkflowSessionPolicy = interface
    ['{ED2FBC1A-AFC2-45E8-995A-7D3C1B0A19F9}']
    /// <summary>Closes captured reads; owned TMAC captures explicitly abort their read calculation.</summary>
    /// <param name="ASession">Captured session owned by the workflow.</param>
    procedure CloseCapture(const ASession: IDesfireSession);
    /// <summary>Returns whether standard writes must share the explicit verified TMAC owner.</summary>
    /// <returns>True for the TMAC profile; immediate standard writes still cannot be rolled back by Abort.</returns>
    function TransactionalStandard: Boolean;
    /// <summary>Commits ordinary or verified TMAC state and retains copied receipt evidence.</summary>
    /// <param name="ASession">Prepared owned transaction.</param>
    procedure CommitSession(const ASession: IDesfireSession);
    /// <summary>Creates a file using the configured complete rights policy, or the ordinary definition.</summary>
    /// <param name="ASession">Explicit management owner.</param>
    /// <param name="ADefinition">Validated ordinary geometry and primary rights.</param>
    procedure CreateFile(const ASession: IDesfireSession; const ADefinition: TDesfireFileDefinition);
    /// <summary>Checks every configured creation policy before any application mutation.</summary>
    /// <param name="ADefinitions">Requested file definitions.</param>
    /// <param name="AKeyCount">Explicit new application key count.</param>
    procedure ValidateProvisioning(const ADefinitions: TDesfireWorkflowDefinitions; const AKeyCount: Byte);
    /// <summary>Returns the last verified TMAC receipt, without supplied keys.</summary>
    /// <returns>Independent MAC bytes; empty before verified commit.</returns>
    function Receipt: TDesfireTmacRecord;
  end;
  /// <summary>Native adapter copying explicit reader configuration without card I/O.</summary>
  /// <remarks>The adapter owns a frozen reader and independently copied credentials, retaining
  /// its transport/provider interfaces. The original reader may be freed after construction;
  /// exclusively own its physical connection throughout each phase. Existing public, EV1/EV2 AES and DES/3DES profiles
  /// remain explicit; keys are never discovered, copied from a snapshot or replaced implicitly.</remarks>
  TDesfireWorkflowCard = class(TInterfacedObject, IDesfireWorkflowCard, IDesfireWorkflowSessionPolicy)
  private
    FReader: TDesfireCardReader;
    FMulti,FUseTmac,FTmacConsumed: Boolean;
    FTmacAid,FCounter: Cardinal;
    FTmacFile: Byte;
    FUid,FTmacKey: TBytes;
    FPolicies: TDesfireWorkflowFilePolicies;
    FReceipt: TDesfireTmacRecord;
    function Granted(const AKey: Byte): Boolean;
  public
    /// <summary>Copies reader configuration and keys without acquiring a card.</summary>
    /// <param name="AReader">Explicitly configured native reader.</param>
    constructor Create(const AReader: TDesfireCardReader);
    /// <summary>Releases the frozen native reader and wipes its retained credentials.</summary>
    destructor Destroy; override;
    /// <summary>Creates frozen multiple-right workflow configuration with optional per-file provisioning policies.</summary>
    /// <param name="AReader">Explicit EV2 AES reader configuration.</param>
    /// <param name="APolicies">Unique explicit primary/additional tuples; independently copied.</param>
    constructor CreateMultiAccess(const AReader: TDesfireCardReader; const APolicies: TDesfireWorkflowFilePolicies);
    /// <summary>Creates a single-use explicit TMAC workflow owner with trusted UID/key/counter.</summary>
    /// <param name="AReader">Explicit EV2 AES reader.</param>
    /// <param name="AAid">Pinned application identifier.</param>
    /// <param name="ATmacFile">Existing TMAC file excluded from ordinary snapshots.</param>
    /// <param name="AUid">Trusted seven-byte real UID.</param>
    /// <param name="ATmacKey">Sixteen supplied static TMAC bytes.</param>
    /// <param name="APreviousCounter">Trusted last accepted counter.</param>
    /// <param name="AAcknowledgeFresh">Required fresh ownership attestation, including read captures.</param>
    constructor CreateMultiAccessTmac(const AReader: TDesfireCardReader; const AAid: Cardinal; const ATmacFile: Byte;
      const AUid, ATmacKey: TBytes; const APreviousCounter: Cardinal; const AAcknowledgeFresh: Boolean);
    /// <summary>Closes read capture, explicitly discarding owned TMAC input.</summary>
    /// <param name="ASession">Owned read capture.</param>
    procedure CloseCapture(const ASession: IDesfireSession);
    /// <summary>Returns whether standard writes participate in the TMAC owner.</summary>
    /// <returns>True only for the explicitly configured TMAC profile.</returns>
    function TransactionalStandard: Boolean;
    /// <summary>Commits with native journal/receipt verification.</summary>
    /// <param name="ASession">Owned transaction.</param>
    procedure CommitSession(const ASession: IDesfireSession);
    /// <summary>Creates a file using frozen explicit rights.</summary>
    /// <param name="ASession">Management session.</param>
    /// <param name="ADefinition">Ordinary geometry and primary policy.</param>
    procedure CreateFile(const ASession: IDesfireSession; const ADefinition: TDesfireFileDefinition);
    /// <summary>Checks every configured creation policy before any application mutation.</summary>
    /// <param name="ADefinitions">Requested file definitions.</param>
    /// <param name="AKeyCount">Explicit new application key count.</param>
    procedure ValidateProvisioning(const ADefinitions: TDesfireWorkflowDefinitions; const AKeyCount: Byte);
    /// <summary>Returns independently owned last verified receipt.</summary>
    /// <returns>Empty before verified TMAC commit.</returns>
    function Receipt: TDesfireTmacRecord;
    /// <summary>Returns configured plaintext/journal bound without I/O.</summary>
    /// <returns>Native reader transfer limit.</returns>
    function TransferLimit: Integer;
    /// <summary>Reads native version manufacturing UID.</summary>
    /// <returns>Independent seven-byte version UID, separate from random anticollision IDs.</returns>
    function ReadIdentity: TBytes;
    /// <summary>Acquires one native exclusive session.</summary>
    /// <param name="AAid">Native AID.</param>
    /// <param name="AAccess">Explicit authority.</param>
    /// <returns>Independent native session.</returns>
    function OpenSession(const AAid: Cardinal; const AAccess: TDesfireSessionAccess): IDesfireSession;
    /// <summary>Checks selected native key rights and communication policy without I/O.</summary>
    /// <param name="ASettings">Acquired target file settings.</param>
    /// <param name="AValueIncrease">True for ordinary Credit, false for Debit.</param>
    procedure ValidateWrite(const ASettings: TDesfireFileSettings; const AValueIncrease: Boolean);
    /// <summary>Uses native independently verified standard-data writing.</summary>
    /// <param name="AAid">Native target AID.</param>
    /// <param name="AFile">Native file number.</param>
    /// <param name="AData">Complete data.</param>
    procedure WriteStandard(const AAid: Cardinal; const AFile: Byte; const AData: TBytes);
  end;
  /// <summary>Bounded readable application snapshot codec, independent of credentials.</summary>
  TDesfireWorkflowArchive = class
  public
    /// <summary>Validates complete file images and canonical raw settings without I/O.</summary>
    /// <param name="ASnapshot">Nonzero AID, identity and complete ordinary files.</param>
    class procedure Validate(const ASnapshot: TDesfireWorkflowSnapshot); static;
    /// <summary>Serializes application ID, identity, settings and data, excluding keys.</summary>
    /// <param name="ASnapshot">Complete snapshot.</param>
    /// <returns>ERD-DESFIRE 1 bounded ASCII.</returns>
    class function Encode(const ASnapshot: TDesfireWorkflowSnapshot): string; static;
    /// <summary>Decodes a strict bounded archive before any acquisition.</summary>
    /// <param name="AText">At most 2200000 ASCII characters.</param>
    /// <returns>Independent complete snapshot.</returns>
    class function Decode(const AText: string): TDesfireWorkflowSnapshot; static;
  end;
  /// <summary>Application backup, compatible data migration, comparison and verified restore.</summary>
  /// <remarks>Acquires every target original and checks all definitions/rights/transaction budgets
  /// before any writes. Standard files are immediate and independently verified. Backup, value
  /// and record changes share one explicit owned transaction and commit once, with verified
  /// read-back/release. Cancellation before commit explicitly aborts staged changes; failure does
  /// not trigger replay or recovery. Record order is preserved by appending oldest first. Keys,
  /// application creation and rights changes are separate explicit workflows. No global atomicity
  /// across standard files and transactional files; earlier standard-file successes remain visible.</remarks>
  TDesfireApplicationWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: IDesfireWorkflowCard;
    FSnapshot: TDesfireWorkflowSnapshot;
    FResults: TCardWorkflowUnits;
    FSourceAid, FTargetAid: Cardinal;
    FAccess: TDesfireSessionAccess;
    FPrepared, FConsumed, FCompare: Boolean;
    FReceipt: TDesfireTmacRecord;
    function GetSnapshot: TDesfireWorkflowSnapshot;
    function GetResults: TCardWorkflowUnits;
    function GetReceipt: TDesfireTmacRecord;
    function Capture(const ACard: IDesfireWorkflowCard; const AAid: Cardinal): TDesfireWorkflowSnapshot;
    procedure CheckIdentity(const ACard: IDesfireWorkflowCard; const AIdentity: TBytes);
    procedure Configure(const ASource, ATarget: IDesfireWorkflowCard;
      const ASourceAid, ATargetAid: Cardinal; const AAccess: TDesfireSessionAccess;
      const ACompareOnly: Boolean);
  protected
    /// <summary>Checks the single-use prepared request.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Captures, preflights, writes and independently verifies the prepared application.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares complete ordinary application backup with no target writes.</summary>
    /// <param name="ASource">Source backend.</param>
    /// <param name="AAid">Source native application identifier.</param>
    procedure PrepareBackup(const ASource: IDesfireWorkflowCard; const AAid: Cardinal);
    /// <summary>Prepares compatible ordinary application data migration.</summary>
    /// <param name="ASource">Source backend with supplied source credentials.</param>
    /// <param name="ATarget">Target backend with separately supplied credentials.</param>
    /// <param name="ASourceAid">Source native AID.</param>
    /// <param name="ATargetAid">Existing compatible target AID.</param>
    /// <param name="AAccess">Fresh transaction attestation or explicit discard-pending permission.</param>
    /// <param name="ACompareOnly">True checks differences without mutation or owned transaction.</param>
    procedure PrepareCopy(const ASource, ATarget: IDesfireWorkflowCard;
      const ASourceAid, ATargetAid: Cardinal; const AAccess: TDesfireSessionAccess;
      const ACompareOnly: Boolean = False);
    /// <summary>Prepares restoration into an existing compatible application.</summary>
    /// <param name="ASnapshot">Independently copied complete snapshot.</param>
    /// <param name="ATarget">Target backend.</param>
    /// <param name="ATargetAid">Existing target native AID.</param>
    /// <param name="AAccess">Explicit fresh/discard transaction policy.</param>
    /// <param name="ACompareOnly">True checks differences only.</param>
    procedure PrepareRestore(const ASnapshot: TDesfireWorkflowSnapshot;
      const ATarget: IDesfireWorkflowCard; const ATargetAid: Cardinal;
      const AAccess: TDesfireSessionAccess; const ACompareOnly: Boolean = False);
    /// <summary>Independent complete source image; never a partially acquired backup.</summary>
    property Snapshot: TDesfireWorkflowSnapshot read GetSnapshot;
    /// <summary>Independent per-file evidence, including earlier immediate writes and uncertain staged changes.</summary>
    property Results: TCardWorkflowUnits read GetResults;
    /// <summary>Independent verified TMAC receipt from the target profile; empty without verified TMAC commit.</summary>
    property TransactionMacReceipt: TDesfireTmacRecord read GetReceipt;
  end;
  /// <summary>Explicit creation of one new application and its ordinary file definitions.</summary>
  /// <remarks>Creation is immediate and can be partial; never deletes an existing application,
  /// rolls back or guesses keys. Supply PICC and newly created application's credentials
  /// separately. File creation verifies metadata using native sessions. Application creation
  /// initializes native default keys; this workflow neither guesses nor changes those keys.
  /// Pair provisioning with a separate prepared data-restore child in a batch factory.</remarks>
  TDesfireProvisionWorkflow = class(TCardWorkflow)
  private
    FPicc, FApplication: IDesfireWorkflowCard;
    FAid: Cardinal;
    FKeySettings, FKeyCount: Byte;
    FKeyType: TDesfireApplicationKeyType;
    FDefinitions: TDesfireWorkflowDefinitions;
    FResults: TCardWorkflowUnits;
    FApplicationCreated, FPrepared, FConsumed: Boolean;
    function GetResults: TCardWorkflowUnits;
  protected
    /// <summary>Checks the single-use prepared creation request.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Creates and verifies the application, then each explicit file.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Validates all ordinary creation definitions before any card I/O.</summary>
    /// <param name="APicc">PICC-level backend with explicitly supplied management credentials.</param>
    /// <param name="AApplication">Backend configured for new application authentication.</param>
    /// <param name="AAid">New nonzero native AID.</param>
    /// <param name="AKeySettings">Explicit native key-management policy.</param>
    /// <param name="AKeyCount">One through fourteen keys.</param>
    /// <param name="AKeyType">Explicit DES/2K3DES, 3K3DES or AES storage.</param>
    /// <param name="ADefinitions">Zero through 32 unique ordinary file definitions.</param>
    procedure Prepare(const APicc, AApplication: IDesfireWorkflowCard;
      const AAid: Cardinal; const AKeySettings, AKeyCount: Byte;
      const AKeyType: TDesfireApplicationKeyType; const ADefinitions: TDesfireWorkflowDefinitions);
    /// <summary>True only after native application-creation metadata verification and session release.</summary>
    property ApplicationCreated: Boolean read FApplicationCreated;
    /// <summary>Independent per-file metadata-creation evidence; no credentials.</summary>
    property Results: TCardWorkflowUnits read GetResults;
  end;

implementation

procedure Invalid;
begin raise ECardWorkflowError.Create('Invalid DESFire workflow request or incompatible application.'); end;
procedure ValidateAid(const AAid: Cardinal);
begin if (AAid = 0) or (AAid > $FFFFFF) then Invalid; end;
function Clone(const S: TDesfireWorkflowSnapshot): TDesfireWorkflowSnapshot;
var I: Integer;
begin
  Result.Aid := S.Aid; Result.Identity := CopyBytes(S.Identity);
  Result.Files := nil; SetLength(Result.Files, Length(S.Files));
  for I := 0 to High(S.Files) do
  begin
    Result.Files[I] := S.Files[I];
    Result.Files[I].Settings.RawBytes := CopyBytes(S.Files[I].Settings.RawBytes);
    Result.Files[I].Data := CopyBytes(S.Files[I].Data);
  end;
end;
function DecodeWorkflowSettings(const Number: Byte; const Raw: TBytes): TDesfireFileSettings;
var Multi: TDesfireMultiAccessSettings;
begin
  if (Length(Raw)>1) and ((Raw[1] and $80)<>0) then begin
    Multi := TDesfireExtensionCodec.MultiAccessSettings(Raw);
    Result := TDesfireCodec.FileSettings(Number,Multi.BaseBytes); Result.RawBytes := CopyBytes(Raw);
  end else Result := TDesfireCodec.FileSettings(Number,Raw);
end;
function StaticPolicyEqual(const A,B: TDesfireFileSettings): Boolean;
var Left,Right: TBytes;
begin
  Left := CopyBytes(A.RawBytes); Right := CopyBytes(B.RawBytes);
  if Length(Left)<>Length(Right) then Exit(False);
  case A.FileType of
    dftValue: begin if Length(Left)<17 then Invalid; FillChar(Left[12],4,0); FillChar(Right[12],4,0); end;
    dftLinearRecords,dftCyclicRecords: begin if Length(Left)<13 then Invalid; FillChar(Left[10],3,0); FillChar(Right[10],3,0); end;
  end;
  Result := BytesEqual(Left,Right);
end;
function SameSettings(const A, B: TDesfireFileSettings): Boolean;
begin
  Result := (A.FileNumber = B.FileNumber) and (A.FileType = B.FileType) and
    (A.Communication = B.Communication) and (A.ReadKey = B.ReadKey) and
    (A.WriteKey = B.WriteKey) and (A.ReadWriteKey = B.ReadWriteKey) and
    (A.ChangeKey = B.ChangeKey) and (A.FileBytes = B.FileBytes) and
    (A.LowerLimit = B.LowerLimit) and (A.UpperLimit = B.UpperLimit) and
    (A.RecordBytes = B.RecordBytes) and (A.MaxRecords = B.MaxRecords) and
    (A.ValueOptions = B.ValueOptions) and StaticPolicyEqual(A,B);
end;
constructor TDesfireWorkflowCard.Create(const AReader: TDesfireCardReader);
var Key: TBytes;
begin
  inherited Create; if (AReader = nil) or AReader.Busy then Invalid;
  FReader := TDesfireCardReader.Create(nil);
  FReader.Transport := AReader.Transport; FReader.Security := AReader.Security;
  FReader.CryptoProvider := AReader.CryptoProvider; FReader.KeyNumber := AReader.KeyNumber;
  FReader.ReauthenticationKeyNumber := AReader.ReauthenticationKeyNumber;
  FReader.MinimumCommunication := AReader.MinimumCommunication;
  FReader.MaxTransferBytes := AReader.MaxTransferBytes; FReader.MaxFrameDataBytes := AReader.MaxFrameDataBytes;
  Key := AReader.AuthenticationKey;
  try FReader.AuthenticationKey := Key; finally TCardCrypto.Clear(Key); end;
  Key := AReader.ReauthenticationKey;
  try FReader.ReauthenticationKey := Key; finally TCardCrypto.Clear(Key); end;
end;
destructor TDesfireWorkflowCard.Destroy;
begin TCardCrypto.Clear(FUid); TCardCrypto.Clear(FTmacKey); TCardCrypto.Clear(FReceipt.Mac); FReader.Free; inherited; end;
function TDesfireWorkflowCard.TransferLimit: Integer;
begin Result := FReader.MaxTransferBytes; end;
function TDesfireWorkflowCard.ReadIdentity: TBytes;
var V: TDesfireVersion;
begin
  if FUseTmac then begin Result := FReader.ReadCardUid(FTmacAid); if not BytesEqual(Result,FUid) then Invalid; end
  else begin V := FReader.ReadVersion; Result := Copy(V.RawBytes,14,7); end;
end;
function TDesfireWorkflowCard.OpenSession(const AAid: Cardinal;
  const AAccess: TDesfireSessionAccess): IDesfireSession;
begin
  if FUseTmac then begin
    if (AAid<>FTmacAid) or not (AAccess in [dsaReadOnly,dsaFreshTransaction]) or
      ((AAccess=dsaFreshTransaction) and FTmacConsumed) then Invalid;
    if AAccess=dsaFreshTransaction then FTmacConsumed := True;
    TCardCrypto.Clear(FReceipt.Mac); FReceipt := Default(TDesfireTmacRecord);
    Result := FReader.OpenMultiAccessTransactionMacSession(AAid,FTmacFile,FUid,FTmacKey,FCounter,True);
  end else if FMulti and (AAid<>0) then
    if AAccess=dsaFreshTransaction then Result := FReader.OpenMultiAccessTransactionSession(AAid,True)
    else Result := FReader.OpenMultiAccessSession(AAid,AAccess)
  else Result := FReader.OpenSession(AAid,AAccess);
end;
function TDesfireWorkflowCard.Granted(const AKey: Byte): Boolean;
var Key: Byte; Rekey: TBytes;
begin
  Key := FReader.KeyNumber; Rekey := FReader.ReauthenticationKey;
  try if Length(Rekey) > 0 then Key := FReader.ReauthenticationKeyNumber;
  finally TCardCrypto.Clear(Rekey); end;
  Result := (AKey = 14) or ((AKey < 14) and
    (FReader.Security <> dfsPublic) and (AKey = Key));
end;
procedure TDesfireWorkflowCard.ValidateWrite(const ASettings: TDesfireFileSettings;
  const AValueIncrease: Boolean);
var Allowed: Boolean; Multi: TDesfireMultiAccessSettings; I: Integer;
begin
  if FReader.Security = dfsPublic then
  begin if ASettings.Communication <> dfcPlain then Invalid; end
  else if Ord(ASettings.Communication) < Ord(FReader.MinimumCommunication) then Invalid;
  Allowed := Granted(ASettings.WriteKey) or Granted(ASettings.ReadWriteKey);
  if ASettings.FileType = dftValue then
    if AValueIncrease then Allowed := Granted(ASettings.ReadWriteKey)
    else Allowed := Allowed or Granted(ASettings.ReadKey);
  if FMulti then begin
    Multi := TDesfireExtensionCodec.MultiAccessSettings(ASettings.RawBytes); Allowed := False;
    for I := 0 to High(Multi.Rights) do
      if (ASettings.FileType=dftValue) and AValueIncrease then Allowed := Allowed or Granted((Multi.Rights[I] shr 4) and $F)
      else begin
        Allowed := Allowed or Granted((Multi.Rights[I] shr 8) and $F) or Granted((Multi.Rights[I] shr 4) and $F);
        if ASettings.FileType=dftValue then Allowed := Allowed or Granted((Multi.Rights[I] shr 12) and $F);
      end;
  end;
  if not Allowed then raise ECardWorkflowError.Create('Target credentials do not grant the requested write.');
end;
procedure TDesfireWorkflowCard.WriteStandard(const AAid: Cardinal;
  const AFile: Byte; const AData: TBytes);
var Session: IDesfireFileManagement; Old: TBytes;
begin
  if FUseTmac then Invalid;
  if not FMulti then begin FReader.WriteData(AAid,AFile,0,AData); Exit; end;
  Session := FReader.OpenFileManagementSession(AAid);
  try
    Old := Session.ReadMultiAccessData(AFile,0,Length(AData));
    Session.WriteMultiAccessDataVerified(AFile,0,Old,AData); Session.Close;
  except try Session.Close; except end; raise; end;
end;
constructor TDesfireWorkflowCard.CreateMultiAccess(const AReader: TDesfireCardReader; const APolicies: TDesfireWorkflowFilePolicies);
var I,J: Integer; Raw: TBytes;
begin
  Create(AReader); if AReader.Security<>dfsEv2Aes then Invalid; FMulti := True;
  if Length(APolicies)>32 then Invalid;
  SetLength(FPolicies,Length(APolicies));
  for I := 0 to High(APolicies) do begin
    if APolicies[I].FileNumber>31 then Invalid;
    for J := 0 to I-1 do if APolicies[J].FileNumber=APolicies[I].FileNumber then Invalid;
    if Length(APolicies[I].Rights)<1 then Invalid;
    Raw := TDesfireExtensionCodec.AccessChange(3,APolicies[I].Rights);
    if Length(Raw)=0 then Invalid;
    FPolicies[I].FileNumber := APolicies[I].FileNumber; FPolicies[I].Rights := Copy(APolicies[I].Rights,0,Length(APolicies[I].Rights));
  end;
end;
constructor TDesfireWorkflowCard.CreateMultiAccessTmac(const AReader: TDesfireCardReader;
  const AAid: Cardinal; const ATmacFile: Byte; const AUid,ATmacKey: TBytes;
  const APreviousCounter: Cardinal; const AAcknowledgeFresh: Boolean);
begin
  CreateMultiAccess(AReader,nil); ValidateAid(AAid);
  if not AAcknowledgeFresh or (ATmacFile>31) or (Length(AUid)<>7) or (Length(ATmacKey)<>16) or
    (APreviousCounter=High(Cardinal)) then Invalid;
  FUseTmac := True; FTmacAid := AAid; FTmacFile := ATmacFile; FUid := CopyBytes(AUid);
  FTmacKey := CopyBytes(ATmacKey); FCounter := APreviousCounter;
end;
procedure TDesfireWorkflowCard.CloseCapture(const ASession: IDesfireSession);
begin
  if FUseTmac then begin
    try if ASession.Outcome=dsoActive then ASession.Abort; finally ASession.Close; end;
  end else ASession.Close;
end;
function TDesfireWorkflowCard.TransactionalStandard: Boolean;
begin Result := FUseTmac; end;
procedure TDesfireWorkflowCard.CommitSession(const ASession: IDesfireSession);
var Tmac: IDesfireTransactionMacSession;
begin
  if not FUseTmac then begin ASession.Commit; Exit; end;
  if not Supports(ASession,IDesfireTransactionMacSession,Tmac) then Invalid;
  FReceipt := Tmac.CommitTransactionMacVerified;
end;
procedure TDesfireWorkflowCard.CreateFile(const ASession: IDesfireSession; const ADefinition: TDesfireFileDefinition);
var I: Integer; Management: IDesfireFileManagement; Settings: TDesfireMultiAccessSettings; Created: Boolean;
begin
  for I := 0 to High(FPolicies) do if FPolicies[I].FileNumber=ADefinition.FileNumber then begin
    if not Supports(ASession,IDesfireFileManagement,Management) then Invalid;
    if FPolicies[I].Rights[0]<>((Word(ADefinition.ReadKey) shl 12) or (Word(ADefinition.WriteKey) shl 8) or
      (Word(ADefinition.ReadWriteKey) shl 4) or ADefinition.ChangeKey) then Invalid;
    Created := False;
    try
      ASession.CreateFile(ADefinition); Created := True;
      Settings := Management.ReadMultiAccessSettings(ADefinition.FileNumber);
      Management.ChangeMultiAccessVerified(ADefinition.FileNumber,Settings.RawBytes,Settings.RawBytes[1] and 3,FPolicies[I].Rights);
    except on E: Exception do begin if Created then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
    Exit;
  end;
  ASession.CreateFile(ADefinition);
end;
procedure TDesfireWorkflowCard.ValidateProvisioning(const ADefinitions: TDesfireWorkflowDefinitions; const AKeyCount: Byte);
var I,J,K,N: Integer; Found: Boolean; Rights: Word; Definition: TDesfireFileDefinition;
begin
  if FUseTmac or (AKeyCount<1) or (AKeyCount>14) then Invalid;
  for I := 0 to High(FPolicies) do begin
    Found := False; Definition := Default(TDesfireFileDefinition);
    for J := 0 to High(ADefinitions) do if ADefinitions[J].FileNumber=FPolicies[I].FileNumber then begin
      Found := True; Definition := ADefinitions[J]; Break;
    end;
    if not Found then Invalid;
    if FPolicies[I].Rights[0]<>((Word(Definition.ReadKey) shl 12) or (Word(Definition.WriteKey) shl 8) or
      (Word(Definition.ReadWriteKey) shl 4) or Definition.ChangeKey) then Invalid;
    if not Granted(Definition.ChangeKey) then Invalid;
    for J := 0 to High(FPolicies[I].Rights) do begin
      Rights := FPolicies[I].Rights[J];
      for K := 0 to 3 do begin N := (Rights shr (K*4)) and 15; if (N<14) and (N>=AKeyCount) then Invalid; end;
    end;
  end;
end;
function TDesfireWorkflowCard.Receipt: TDesfireTmacRecord;
begin Result := FReceipt; Result.Mac := CopyBytes(FReceipt.Mac); end;

class procedure TDesfireWorkflowArchive.Validate(const ASnapshot: TDesfireWorkflowSnapshot);
var I, J, Size, Total, V: Integer; S: TDesfireFileSettings;
begin
  ValidateAid(ASnapshot.Aid);
  if (Length(ASnapshot.Identity) < 1) or (Length(ASnapshot.Identity) > 64) or
    (Length(ASnapshot.Files) > 32) then Invalid;
  Total := 0;
  for I := 0 to High(ASnapshot.Files) do
  begin
    S := DecodeWorkflowSettings(ASnapshot.Files[I].Settings.FileNumber,
      ASnapshot.Files[I].Settings.RawBytes);
    if not SameSettings(S, ASnapshot.Files[I].Settings) or
      (S.CurrentRecords <> ASnapshot.Files[I].Settings.CurrentRecords) or
      (S.LimitedCreditValue <> ASnapshot.Files[I].Settings.LimitedCreditValue) then Invalid;
    for J := 0 to I - 1 do if S.FileNumber = ASnapshot.Files[J].Settings.FileNumber then Invalid;
    Size := 0;
    case S.FileType of
      dftStandard, dftBackup: Size := S.FileBytes;
      dftValue: begin
        Size := 4; V := TDesfireCodec.SignedValue(ASnapshot.Files[I].Data);
        if (V < S.LowerLimit) or (V > S.UpperLimit) then Invalid;
      end;
      dftLinearRecords, dftCyclicRecords: begin
        if Int64(S.RecordBytes) * S.CurrentRecords > DesfireMaxTransferBytes then Invalid;
        Size := S.RecordBytes * S.CurrentRecords;
      end;
    end;
    if (Length(ASnapshot.Files[I].Data) <> Size) or
      (Size > DesfireMaxTransferBytes - Total) then Invalid;
    Inc(Total, Size);
  end;
end;
class function TDesfireWorkflowArchive.Encode(const ASnapshot: TDesfireWorkflowSnapshot): string;
var I,Version: Integer; Lines: TStringList; Data: string;
begin
  Validate(ASnapshot); Lines := TStringList.Create;
  try
    Version := 1; for I := 0 to High(ASnapshot.Files) do
      if (ASnapshot.Files[I].Settings.RawBytes[1] and $80)<>0 then Version := 2;
    Lines.Add('ERD-DESFIRE '+IntToStr(Version)); Lines.Add(IntToStr(ASnapshot.Aid)); Lines.Add(BytesToHex(ASnapshot.Identity));
    for I := 0 to High(ASnapshot.Files) do
    begin
      Data := '-'; if Length(ASnapshot.Files[I].Data) > 0 then Data := BytesToHex(ASnapshot.Files[I].Data);
      Lines.Add(IntToStr(ASnapshot.Files[I].Settings.FileNumber) + '|' +
        BytesToHex(ASnapshot.Files[I].Settings.RawBytes) + '|' + Data);
    end;
    Lines.LineBreak := #13#10; Result := Lines.Text;
  finally Lines.Free; end;
end;
class function TDesfireWorkflowArchive.Decode(const AText: string): TDesfireWorkflowSnapshot;
var Lines, Fields: TStringList; I, N: Integer;
begin
  Result := Default(TDesfireWorkflowSnapshot);
  if (Length(AText) < 1) or (Length(AText) > 2200000) then Invalid;
  for I := 1 to Length(AText) do if not (Ord(AText[I]) in [10, 13, 32 .. 126]) then Invalid;
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count < 3) or (Lines.Count > 35) or not ((Lines[0]='ERD-DESFIRE 1') or (Lines[0]='ERD-DESFIRE 2')) then Invalid;
    if not TryStrToInt(Lines[1], N) then Invalid;
    if (N < 1) or (N > $FFFFFF) or (IntToStr(N) <> Lines[1]) then Invalid;
    Result.Aid := N; Result.Identity := HexToBytes(Lines[2]);
    SetLength(Result.Files, Lines.Count - 3); Fields.StrictDelimiter := True; Fields.Delimiter := '|';
    for I := 3 to Lines.Count - 1 do
    begin
      Fields.DelimitedText := Lines[I]; if Fields.Count <> 3 then Invalid;
      if not TryStrToInt(Fields[0], N) then Invalid;
      if (N < 0) or (N > 31) or (IntToStr(N) <> Fields[0]) then Invalid;
      Result.Files[I - 3].Settings := DecodeWorkflowSettings(N,HexToBytes(Fields[1]));
      if (Lines[0]='ERD-DESFIRE 1') and ((Result.Files[I-3].Settings.RawBytes[1] and $80)<>0) then Invalid;
      if Fields[2] <> '-' then Result.Files[I - 3].Data := HexToBytes(Fields[2]);
    end;
    Validate(Result);
    if Encode(Result) <> StringReplace(StringReplace(AText, #13#10, #10, [rfReplaceAll]),
      #10, #13#10, [rfReplaceAll]) then Invalid;
  finally Fields.Free; Lines.Free; end;
end;
function TDesfireApplicationWorkflow.GetReceipt: TDesfireTmacRecord;
begin Result := FReceipt; Result.Mac := CopyBytes(FReceipt.Mac); end;
procedure TDesfireApplicationWorkflow.Configure(const ASource, ATarget: IDesfireWorkflowCard;
  const ASourceAid, ATargetAid: Cardinal; const AAccess: TDesfireSessionAccess; const ACompareOnly: Boolean);
begin
  RequireIdle; FReceipt := Default(TDesfireTmacRecord);
  if (ASource = nil) and (ATarget = nil) then Invalid;
  if ASource <> nil then begin ValidateAid(ASourceAid);
    if (ASource.TransferLimit < 1) or (ASource.TransferLimit > DesfireMaxTransferBytes) then Invalid; end;
  if ATarget <> nil then begin ValidateAid(ATargetAid);
    if (ATarget.TransferLimit < 1) or (ATarget.TransferLimit > DesfireMaxTransferBytes) then Invalid; end;
  if not (AAccess in [dsaFreshTransaction, dsaDiscardPending]) then Invalid;
  FSource := ASource; FTarget := ATarget; FSourceAid := ASourceAid; FTargetAid := ATargetAid;
  FAccess := AAccess; FCompare := ACompareOnly; FResults := nil; FPrepared := True; FConsumed := False;
end;
procedure TDesfireApplicationWorkflow.PrepareBackup(const ASource: IDesfireWorkflowCard; const AAid: Cardinal);
begin if ASource = nil then Invalid; Configure(ASource, nil, AAid, 0, dsaFreshTransaction, False);
  FSnapshot := Default(TDesfireWorkflowSnapshot); end;
procedure TDesfireApplicationWorkflow.PrepareCopy(const ASource, ATarget: IDesfireWorkflowCard;
  const ASourceAid, ATargetAid: Cardinal; const AAccess: TDesfireSessionAccess; const ACompareOnly: Boolean);
begin if (ASource = nil) or (ATarget = nil) then Invalid;
  Configure(ASource, ATarget, ASourceAid, ATargetAid, AAccess, ACompareOnly);
  FSnapshot := Default(TDesfireWorkflowSnapshot); end;
procedure TDesfireApplicationWorkflow.PrepareRestore(const ASnapshot: TDesfireWorkflowSnapshot;
  const ATarget: IDesfireWorkflowCard; const ATargetAid: Cardinal;
  const AAccess: TDesfireSessionAccess; const ACompareOnly: Boolean);
begin if ATarget = nil then Invalid; TDesfireWorkflowArchive.Validate(ASnapshot);
  Configure(nil, ATarget, 0, ATargetAid, AAccess, ACompareOnly); FSnapshot := Clone(ASnapshot); end;
procedure TDesfireApplicationWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
function TDesfireApplicationWorkflow.GetSnapshot: TDesfireWorkflowSnapshot;
begin Result := Clone(FSnapshot); end;
function TDesfireApplicationWorkflow.GetResults: TCardWorkflowUnits;
var I: Integer;
begin Result := nil; SetLength(Result, Length(FResults));
  for I := 0 to High(FResults) do begin Result[I] := FResults[I]; Result[I].Data := CopyBytes(FResults[I].Data); end; end;
procedure TDesfireApplicationWorkflow.CheckIdentity(const ACard: IDesfireWorkflowCard; const AIdentity: TBytes);
begin if not BytesEqual(ACard.ReadIdentity, AIdentity) then
  raise ECardWorkflowError.Create('DESFire card identity changed.'); end;
function TDesfireApplicationWorkflow.Capture(const ACard: IDesfireWorkflowCard;
  const AAid: Cardinal): TDesfireWorkflowSnapshot;
var Policy: IDesfireWorkflowSessionPolicy; Session: IDesfireSession; Files: TDesfireFiles; I, Total: Integer; V: Integer;
begin
  Result := Default(TDesfireWorkflowSnapshot); Result.Aid := AAid; Result.Identity := ACard.ReadIdentity;
  Session := ACard.OpenSession(AAid, dsaReadOnly);
  try
    Files := Session.ReadFiles; if Length(Files) > 32 then Invalid;
    SetLength(Result.Files, Length(Files)); Total := 0;
    for I := 0 to High(Files) do
    begin
      Result.Files[I].Settings := Files[I];
      case Files[I].FileType of
        dftStandard, dftBackup: Result.Files[I].Data := Session.ReadData(Files[I].FileNumber, 0, Files[I].FileBytes);
        dftValue: begin V := Session.ReadValue(Files[I].FileNumber);
          SetLength(Result.Files[I].Data, 4); Move(V, Result.Files[I].Data[0], 4); end;
        dftLinearRecords, dftCyclicRecords: if Files[I].CurrentRecords > 0 then
          Result.Files[I].Data := Session.ReadRecords(Files[I].FileNumber, 0, Files[I].CurrentRecords);
      end;
      if Length(Result.Files[I].Data) > ACard.TransferLimit - Total then Invalid;
      Inc(Total, Length(Result.Files[I].Data));
    end;
    TDesfireWorkflowArchive.Validate(Result);
  finally
    if Supports(ACard,IDesfireWorkflowSessionPolicy,Policy) then Policy.CloseCapture(Session) else Session.Close;
  end;
  CheckIdentity(ACard, Result.Identity);
end;
procedure TDesfireApplicationWorkflow.DoExecute;
var Policy: IDesfireWorkflowSessionPolicy; Standard: IDesfireTransactionMacDataSession; IncludeStandard: Boolean; Target: TDesfireWorkflowSnapshot; I, J, Found, Commands, StagedByteBudget, N, Count: Integer;
  Transaction: IDesfireSession; TransactionNeeded: Boolean; S: TDesfireFileSettings;
  Current, Wanted, Delta: Int64; Acquired: TDesfireWorkflowSnapshot; Live: TDesfireFiles; Data: TBytes;
  function TargetFile(const Number: Byte): Integer;
  var K: Integer;
  begin Result := -1; for K := 0 to High(Target.Files) do
    if Target.Files[K].Settings.FileNumber = Number then begin Result := K; Exit; end; end;
  procedure AbortCancelled;
  var K: Integer;
  begin
    Transaction.Abort; MutationPending(False);
    for K := 0 to High(FResults) do
      if FSnapshot.Files[K].Settings.FileType <> dftStandard then
        if FResults[K].State = cwusUncertain then FResults[K].State := cwusPending;
    for K := 0 to High(FResults) do if (FSnapshot.Files[K].Settings.FileType=dftStandard) and
      (FResults[K].State=cwusUncertain) then begin Progress(cwsNeedsVerification,0,Length(FResults)); Exit; end;
  end;
begin
  FConsumed := True; IncludeStandard := Supports(FTarget,IDesfireWorkflowSessionPolicy,Policy);
  if IncludeStandard then IncludeStandard := Policy.TransactionalStandard;
  if FSource <> nil then
  begin
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, 1); if CancelRequested then Exit;
    Acquired := Capture(FSource, FSourceAid); FSnapshot := Clone(Acquired); Progress(cwsReading, 1, 1);
  end;
  if FTarget = nil then Exit;
  if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
  Progress(cwsChecking, 0, Length(FSnapshot.Files)); if CancelRequested then Exit;
  Target := Capture(FTarget, FTargetAid);
  SetLength(FResults, Length(FSnapshot.Files)); Commands := 0; StagedByteBudget := 0; TransactionNeeded := False;
  for I := 0 to High(FSnapshot.Files) do
  begin
    S := FSnapshot.Files[I].Settings; Found := TargetFile(S.FileNumber);
    if (Found < 0) then Invalid;
    if not SameSettings(S, Target.Files[Found].Settings) then Invalid;
    FResults[I].Address := S.FileNumber; FResults[I].Data := CopyBytes(FSnapshot.Files[I].Data);
    FResults[I].State := cwusPending;
    if BytesEqual(FResults[I].Data, Target.Files[Found].Data) then FResults[I].State := cwusUnchanged
    else if not FCompare then
    begin
      Current := 0; Wanted := 0;
      if S.FileType = dftValue then begin
        Current := TDesfireCodec.SignedValue(Target.Files[Found].Data); Wanted := TDesfireCodec.SignedValue(FResults[I].Data); end;
      FTarget.ValidateWrite(Target.Files[Found].Settings, Wanted > Current);
      if Length(FResults[I].Data) > FTarget.TransferLimit then Invalid;
      if (S.FileType<>dftStandard) or IncludeStandard then
      begin
        TransactionNeeded := True; N := Length(FResults[I].Data);
        if Length(Target.Files[Found].Data) > N then N := Length(Target.Files[Found].Data);
        if N > FTarget.TransferLimit - StagedByteBudget then Invalid; Inc(StagedByteBudget, N);
        case S.FileType of
          dftStandard,dftBackup: Inc(Commands);
          dftValue: Inc(Commands, Integer((Abs(Wanted - Current) + High(Integer) - 1) div High(Integer)));
          dftLinearRecords, dftCyclicRecords: Inc(Commands, 1 + Length(FResults[I].Data) div S.RecordBytes);
        end;
        if Commands > 256 then raise ECardWorkflowError.Create('DESFire transaction exceeds mutation budget.');
      end;
    end;
    Progress(cwsChecking, I + 1, Length(FSnapshot.Files)); if CancelRequested then Exit;
  end;
  if FCompare then Exit;
  for I := 0 to High(FResults) do
    if not IncludeStandard and (FSnapshot.Files[I].Settings.FileType = dftStandard) and (FResults[I].State = cwusPending) then
    begin
      if CancelRequested then Exit; CheckIdentity(FTarget, Target.Identity);
      Progress(cwsWriting, I, Length(FResults)); if CancelRequested then Exit;
      MutationPending(True); FResults[I].State := cwusUncertain;
      try FTarget.WriteStandard(FTargetAid, FResults[I].Address, CopyBytes(FResults[I].Data));
      except
        on E: EContactlessWriteUncertain do raise;
        on E: Exception do begin MutationPending(False); FResults[I].State := cwusPending; raise; end;
      end;
      Progress(cwsVerifying, I, Length(FResults)); CheckIdentity(FTarget, Target.Identity);
      FResults[I].State := cwusVerified; MutationPending(False);
    end;
  if CancelRequested or not TransactionNeeded then Exit;
  CheckIdentity(FTarget, Target.Identity); Transaction := FTarget.OpenSession(FTargetAid, FAccess);
  try
    Live := Transaction.ReadFiles;
    for I := 0 to High(FResults) do
    begin
      S := FSnapshot.Files[I].Settings;
      if ((S.FileType=dftStandard) and not IncludeStandard) or (FResults[I].State<>cwusPending) then Continue;
      Found := -1;
      for J := 0 to High(Live) do if Live[J].FileNumber = S.FileNumber then Found := J;
      if Found < 0 then Invalid;
      if not SameSettings(S, Live[Found]) then Invalid;
      Data := nil;
      case S.FileType of
        dftStandard,dftBackup: Data := Transaction.ReadData(S.FileNumber, 0, S.FileBytes);
        dftValue: begin N := Transaction.ReadValue(S.FileNumber); SetLength(Data, 4); Move(N, Data[0], 4); end;
        dftLinearRecords, dftCyclicRecords: if Live[Found].CurrentRecords > 0 then
          Data := Transaction.ReadRecords(S.FileNumber, 0, Live[Found].CurrentRecords);
      end;
      if not BytesEqual(Data, Target.Files[TargetFile(S.FileNumber)].Data) then
        raise ECardWorkflowError.Create('Target application changed after preflight.');
    end;
    for I := 0 to High(FResults) do
    begin
      if CancelRequested then begin AbortCancelled; Exit; end;
      S := FSnapshot.Files[I].Settings;
      if ((S.FileType=dftStandard) and not IncludeStandard) or (FResults[I].State<>cwusPending) then Continue;
      Progress(cwsWriting, I, Length(FResults));
      if CancelRequested then begin AbortCancelled; Exit; end;
      MutationPending(True); FResults[I].State := cwusUncertain;
      case S.FileType of
        dftStandard: begin
          if not Supports(Transaction,IDesfireTransactionMacDataSession,Standard) then Invalid;
          Standard.WriteStandardDataVerified(S.FileNumber,0,Target.Files[TargetFile(S.FileNumber)].Data,FResults[I].Data);
        end;
        dftBackup: Transaction.WriteBackup(S.FileNumber, 0, CopyBytes(FResults[I].Data));
        dftValue: begin
          Found := TargetFile(S.FileNumber); Current := TDesfireCodec.SignedValue(Target.Files[Found].Data);
          Wanted := TDesfireCodec.SignedValue(FResults[I].Data); Delta := Wanted - Current;
          while Delta <> 0 do begin
            N := Integer(High(Integer)); if Abs(Delta) < N then N := Integer(Abs(Delta));
            if Delta > 0 then begin Transaction.Credit(S.FileNumber, N); Dec(Delta, N); end
            else begin Transaction.Debit(S.FileNumber, N); Inc(Delta, N); end;
          end;
        end;
        dftLinearRecords, dftCyclicRecords: begin
          Transaction.ClearRecords(S.FileNumber); Count := Length(FResults[I].Data) div S.RecordBytes;
          for J := Count - 1 downto 0 do
          begin
            if CancelRequested then begin AbortCancelled; Exit; end;
            Transaction.AppendRecord(S.FileNumber, Copy(FResults[I].Data, J * S.RecordBytes, S.RecordBytes));
          end;
        end;
      end;
    end;
    Progress(cwsVerifying, 0, Length(FResults));
    if CancelRequested then begin AbortCancelled; Exit; end;
    if Policy<>nil then begin Policy.CommitSession(Transaction); FReceipt := Policy.Receipt; end
    else Transaction.Commit;
    if (Transaction.Outcome <> dsoCommitted) or not Transaction.VerificationSucceeded then Invalid;
    CheckIdentity(FTarget, Target.Identity);
    for I := 0 to High(FResults) do if FResults[I].State = cwusUncertain then FResults[I].State := cwusVerified;
    MutationPending(False); Progress(cwsVerifying, Length(FResults), Length(FResults));
  finally Transaction.Close; end;
end;
procedure TDesfireProvisionWorkflow.Prepare(const APicc, AApplication: IDesfireWorkflowCard;
  const AAid: Cardinal; const AKeySettings, AKeyCount: Byte;
  const AKeyType: TDesfireApplicationKeyType; const ADefinitions: TDesfireWorkflowDefinitions);
var I, J: Integer; Policy: IDesfireWorkflowSessionPolicy;
begin
  RequireIdle; ValidateAid(AAid);
  if (APicc = nil) or (AApplication = nil) or (AKeyCount < 1) or (AKeyCount > 14) or
    not (AKeyType in [daktDesOrTwoKey3Des .. daktAes]) or (Length(ADefinitions) > 32) or
    (((AKeySettings shr 4) < 14) and ((AKeySettings shr 4) >= AKeyCount)) then Invalid;
  for I := 0 to High(ADefinitions) do
  begin
    TDesfireCodec.ValidateDefinition(ADefinitions[I]);
    for J := 0 to I - 1 do if ADefinitions[I].FileNumber = ADefinitions[J].FileNumber then Invalid;
    if ((ADefinitions[I].ReadKey < 14) and (ADefinitions[I].ReadKey >= AKeyCount)) or
      ((ADefinitions[I].WriteKey < 14) and (ADefinitions[I].WriteKey >= AKeyCount)) or
      ((ADefinitions[I].ReadWriteKey < 14) and (ADefinitions[I].ReadWriteKey >= AKeyCount)) or
      ((ADefinitions[I].ChangeKey < 14) and (ADefinitions[I].ChangeKey >= AKeyCount)) then Invalid;
  end;
  if Supports(AApplication,IDesfireWorkflowSessionPolicy,Policy) then Policy.ValidateProvisioning(ADefinitions,AKeyCount);
  FDefinitions := nil; SetLength(FDefinitions, Length(ADefinitions));
  for I := 0 to High(ADefinitions) do FDefinitions[I] := ADefinitions[I];
  FPicc := APicc; FApplication := AApplication; FAid := AAid; FKeySettings := AKeySettings;
  FKeyCount := AKeyCount; FKeyType := AKeyType; FResults := nil; FApplicationCreated := False;
  FPrepared := True; FConsumed := False;
end;
procedure TDesfireProvisionWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
function TDesfireProvisionWorkflow.GetResults: TCardWorkflowUnits;
var I: Integer;
begin Result := nil; SetLength(Result, Length(FResults));
  for I := 0 to High(FResults) do begin Result[I] := FResults[I]; Result[I].Data := CopyBytes(FResults[I].Data); end; end;
procedure TDesfireProvisionWorkflow.DoExecute;
var Policy: IDesfireWorkflowSessionPolicy; Session: IDesfireSession; Management: IDesfireApplicationManagement; I: Integer; Identity: TBytes;
  Settings: TDesfireApplicationSettings; TypeBits: Byte; AnyCreated, FailedUncertain: Boolean;
begin
  FConsumed := True;
  if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
  Identity := FPicc.ReadIdentity;
  Progress(cwsChecking, 0, Length(FDefinitions) + 1); if CancelRequested then Exit;
  Session := FPicc.OpenSession(0, dsaManage);
  try
    if not Supports(Session, IDesfireApplicationManagement, Management) then Invalid;
    Progress(cwsWriting, 0, Length(FDefinitions) + 1); if CancelRequested then Exit;
    MutationPending(True);
    try Management.CreateApplicationWithKeyType(FAid, FKeySettings, FKeyCount, FKeyType);
    except
      on E: EContactlessWriteUncertain do raise;
      on E: Exception do begin MutationPending(False); raise; end;
    end;
  finally Session.Close; Management := nil; end;
  FApplicationCreated := True; MutationPending(False);
  SetLength(FResults, Length(FDefinitions));
  for I := 0 to High(FResults) do begin FResults[I].Address := FDefinitions[I].FileNumber;
    FResults[I].State := cwusPending; end;
  Progress(cwsVerifying, 1, Length(FDefinitions) + 1);
  if CancelRequested then Exit;
  if not BytesEqual(FApplication.ReadIdentity, Identity) then Invalid;
  Session := FApplication.OpenSession(FAid, dsaManage);
  AnyCreated := False; FailedUncertain := False;
  try
    Settings := Session.ReadApplicationSettings; TypeBits := 0;
    case FKeyType of daktThreeKey3Des: TypeBits := $40; daktAes: TypeBits := $80; end;
    if (Settings.KeySettings <> FKeySettings) or
      (Settings.KeyConfiguration <> (TypeBits or FKeyCount)) then Invalid;
    for I := 0 to High(FDefinitions) do
    begin
      if CancelRequested then Exit;
      Progress(cwsWriting, I + 1, Length(FDefinitions) + 1); if CancelRequested then Exit;
      MutationPending(True); FResults[I].State := cwusUncertain;
      try
        if Supports(FApplication,IDesfireWorkflowSessionPolicy,Policy) then Policy.CreateFile(Session,FDefinitions[I])
        else Session.CreateFile(FDefinitions[I]);
      except
        on E: EContactlessWriteUncertain do begin FailedUncertain := True; raise; end;
        on E: Exception do begin MutationPending(False); FResults[I].State := cwusPending; raise; end;
      end;
      FResults[I].State := cwusVerified; AnyCreated := True;
      Progress(cwsVerifying, I + 2, Length(FDefinitions) + 1);
    end;
  finally
    if AnyCreated then MutationPending(True);
    Session.Close;
    if not FailedUncertain then MutationPending(False);
  end;
end;

end.
