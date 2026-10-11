unit ERD.Card.Contactless.Workflow.Password;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless.Raw,
  ERD.Card.Contactless.Type2, ERD.Card.Contactless.ISO15693;

type
  /// <summary>Optional local credential cleanup; performs no card I/O and must not raise.</summary>
  ICardWorkflowCredentialCleanup = interface
    ['{C0650AF4-3FAA-445D-B795-73E80C3A52B2}']
    /// <summary>Wipes owned credentials and permanently disables this backend request.</summary>
    procedure ClearCredentials;
  end;
  /// <summary>Supplied-password memory copy/backup/compare/restore with credential cleanup on every execution exit.</summary>
  /// <remarks>Use the protected preparation methods with the factories below; ordinary public
  /// backends can be mixed with protected backends. Each backend pins the first acquired UID,
  /// checks it before authentication, and never retries failed authentication. No UID, locks,
  /// password or policy is copied. Exports use the existing secret-free snapshot archive.</remarks>
  TProtectedMemoryWorkflow = class(TCardMemoryCopyWorkflow)
  private
    FSourceCredentials, FTargetCredentials: ICardWorkflowCredentialCleanup;
    procedure ClearOwnedCredentials;
    procedure RetainCredentials(const ASource, ATarget: ICardWorkflowMemory);
  protected
    /// <summary>Runs the prepared memory request and wipes retained credentials on every exit.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Wipes unexecuted credentials before destruction.</summary>
    destructor Destroy; override;
    /// <summary>Prepares a selected-memory backup and registers credential ownership for cleanup.</summary>
    /// <param name="ASource">Protected or public source backend.</param>
    /// <param name="AAddresses">Explicit selected readable units.</param>
    procedure PrepareProtectedBackup(const ASource: ICardWorkflowMemory; const AAddresses: TCardWorkflowAddresses);
    /// <summary>Prepares memory copy or comparison, acquiring all source and target data before writing.</summary>
    /// <param name="ASource">Protected or public source.</param>
    /// <param name="ATarget">Protected or public destination with identical layout.</param>
    /// <param name="AAddresses">Selected ordinary user-data units.</param>
    /// <param name="ACompareOnly">True performs no writes.</param>
    procedure PrepareProtectedCopy(const ASource, ATarget: ICardWorkflowMemory;
      const AAddresses: TCardWorkflowAddresses; const ACompareOnly: Boolean = False);
    /// <summary>Prepares restoration or comparison of a copied secret-free snapshot.</summary>
    /// <param name="ASnapshot">Independent compatible selected-memory snapshot.</param>
    /// <param name="ATarget">Protected or public destination.</param>
    /// <param name="ACompareOnly">True builds a difference plan without programming.</param>
    procedure PrepareProtectedRestore(const ASnapshot: TCardWorkflowSnapshot;
      const ATarget: ICardWorkflowMemory; const ACompareOnly: Boolean = False);
  end;

/// <summary>Creates a frozen native PWD_AUTH/PACK user-memory backend without hardware I/O.</summary>
/// <param name="AReader">Exclusive raw Type A reader, for example an explicit ACR122 adapter.</param>
/// <param name="AModel">Explicit password-capable EV1/NTAG model; original Ultralight is excluded.</param>
/// <param name="APassword">Four caller-owned password bytes, copied and wiped on cleanup.</param>
/// <param name="AExpectedPack">Two expected PACK bytes, copied; no default or guessed PACK.</param>
/// <returns>Owned four-byte user-page adapter compatible with ordinary Type 2 snapshots.</returns>
/// <remarks>One authentication per native page/preflight operation. Target preflight refuses
/// mirrored memory or any user lock conservatively. AUTHLIM/counter effects remain card-controlled.</remarks>
function CreateType2PasswordWorkflowMemory(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const APassword, AExpectedPack: TBytes): ICardWorkflowMemory;

/// <summary>Creates an authenticated addressed ISO15693 backend with identity/geometry checks before passwords.</summary>
/// <param name="ASession">Inactive addressed session supporting explicit manufacturer commands.</param>
/// <param name="AProfile">SLIX2 or original ST25DV password dialect.</param>
/// <param name="APasswords">Explicit wire-order read/write or user-password credentials, copied independently.</param>
/// <param name="ABlockCount">Exact expected block count.</param>
/// <param name="ABlockSize">Exact expected block width.</param>
/// <returns>Owned backend compatible with ordinary ISO15693 geometry snapshots.</returns>
/// <remarks>SLIX2 block 79 is excluded from writes before I/O. Standard lock status is checked
/// for each differing destination block; no AFI, DSFID, privacy, locks or area resizing.</remarks>
function CreateIso15693PasswordWorkflowMemory(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords;
  const ABlockCount, ABlockSize: Integer): ICardWorkflowMemory;

/// <summary>Wraps a raw Type A reader with an explicit same-UID guard, without I/O.</summary>
/// <param name="AReader">Exclusive reader retained by the wrapper.</param>
/// <param name="AExpectedUid">Exact seven-byte Type 2 UID, or empty to pin the first activation.</param>
/// <returns>Reader that rejects identity changes before forwarding authentication frames.</returns>
function CreateType2WorkflowIdentityGuard(const AReader: IRawContactlessReader;
  const AExpectedUid: TBytes = nil): IRawContactlessReader;

/// <summary>Wraps an addressed session with identity and exact geometry checks before manufacturer commands.</summary>
/// <param name="ASession">Retained inactive session with manufacturer commands.</param>
/// <param name="ABlockCount">Explicit expected geometry.</param>
/// <param name="ABlockSize">Explicit expected byte width.</param>
/// <param name="AExpectedUid">Canonical eight-byte UID, or empty to pin first acquisition.</param>
/// <param name="ARequireReset">True requires explicit field-reset capability before any I/O.</param>
/// <returns>Guarded session; optional reset forwarding checks the same identity and geometry.</returns>
function CreateIso15693WorkflowIdentityGuard(const ASession: IIso15693Session;
  const ABlockCount, ABlockSize: Integer; const AExpectedUid: TBytes = nil;
  const ARequireReset: Boolean = False): IIso15693Session;

implementation

uses ERD.Card.Crypto, ERD.Card.Contactless, ERD.Card.Contactless.Workflow,
  ERD.Card.Contactless.Workflow.ISO15693, ERD.Card.Contactless.Type2.Password;

type
  TRawGuard = class(TInterfacedObject, IRawContactlessReader)
  private
    Inner: IRawContactlessReader;
    Uid: TBytes;
    Active, Selected: Boolean;
  public
    constructor Create(const AReader: IRawContactlessReader; const AUid: TBytes);
    procedure BeginSession;
    procedure EndSession;
    function Activate: TBytes;
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
  end;
  TIsoGuard = class(TInterfacedObject, IIso15693Session, IIso15693CustomCommands, IIso15693FieldReset)
  private
    Inner: IIso15693Session;
    Custom: IIso15693CustomCommands;
    Reset: IIso15693FieldReset;
    Uid: TBytes;
    Count, Size: Integer;
    Active: Boolean;
    procedure Check(const Info: TIso15693SystemInfo);
    procedure RequireActive;
  public
    constructor Create(const ASession: IIso15693Session; const ACount, ASize: Integer;
      const AUid: TBytes; const ARequireReset: Boolean);
    function BeginSession: TIso15693SystemInfo;
    procedure EndSession;
    function ReadBlock(const ABlock: Integer): TBytes;
    function SecurityStatus(const ABlock: Integer): Byte;
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
    function ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
    function ResetField: TIso15693SystemInfo;
  end;
  TType2PasswordMemory = class(TInterfacedObject, ICardWorkflowMemory,
    ICardWorkflowWritePreflight, ICardWorkflowCredentialCleanup)
  private
    Raw: IRawContactlessReader;
    R: TType2PasswordCardReader;
    Model: TType2TagModel;
    Password, Pack: TBytes;
    procedure Ready;
  public
    constructor Create(const AReader: IRawContactlessReader; const AModel: TType2TagModel;
      const APassword, APack: TBytes);
    destructor Destroy; override;
    procedure ClearCredentials;
    function Layout: string;
    function UnitSize: Integer;
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    function ReadUid: TBytes;
    function ReadUnit(const AAddress: Integer): TBytes;
    procedure CheckWritable(const AAddress: Integer);
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
  end;
  TIsoPasswordMemory = class(TInterfacedObject, ICardWorkflowMemory,
    ICardWorkflowWritePreflight, ICardWorkflowCredentialCleanup)
  private
    Native: TIso15693WorkflowMemory;
    Memory: ICardWorkflowMemory;
    Preflight: ICardWorkflowWritePreflight;
    Profile: TIso15693PasswordProfile;
    Count, Size: Integer;
    procedure Ready;
  public
    constructor Create(const ASession: IIso15693Session; const AProfile: TIso15693PasswordProfile;
      const APasswords: TIso15693Passwords; const ACount, ASize: Integer);
    procedure ClearCredentials;
    function Layout: string;
    function UnitSize: Integer;
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    function ReadUid: TBytes;
    function ReadUnit(const AAddress: Integer): TBytes;
    procedure CheckWritable(const AAddress: Integer);
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
  end;

constructor TRawGuard.Create(const AReader: IRawContactlessReader; const AUid: TBytes);
begin
  inherited Create;
  if (AReader = nil) or ((Length(AUid) <> 0) and (Length(AUid) <> 7)) then
    raise ECardWorkflowError.Create('Type 2 reader and optional seven-byte identity required.');
  Inner := AReader; Uid := CopyBytes(AUid);
end;

procedure TRawGuard.BeginSession;
begin
  if Active then raise ECardWorkflowError.Create('Raw guard already active.');
  Inner.BeginSession; Active := True; Selected := False;
end;

procedure TRawGuard.EndSession;
begin
  if not Active then raise ECardWorkflowError.Create('Raw guard not active.');
  try Inner.EndSession; finally Active := False; Selected := False; end;
end;

function TRawGuard.Activate: TBytes;
begin
  if not Active then raise ECardWorkflowError.Create('Raw guard not active.');
  Selected := False; Result := Inner.Activate;
  if (Length(Result) <> 7) or ((Length(Uid) > 0) and not BytesEqual(Result, Uid)) then
    raise ECardWorkflowError.Create('Type 2 identity changed.');
  if Length(Uid) = 0 then Uid := CopyBytes(Result);
  Selected := True; Result := CopyBytes(Result);
end;

function TRawGuard.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
begin
  if not Active or not Selected then raise ECardWorkflowError.Create('Fresh guarded selection required.');
  Result := Inner.Exchange(AFrame, ABitCount);
end;

constructor TIsoGuard.Create(const ASession: IIso15693Session; const ACount, ASize: Integer;
  const AUid: TBytes; const ARequireReset: Boolean);
begin
  inherited Create;
  if (ASession = nil) or (ACount < 1) or (ACount > 65536) or (ASize < 1) or (ASize > 32) or
    (Int64(ACount) * ASize > Iso15693MaxMemoryBytes) or
    ((Length(AUid) <> 0) and ((Length(AUid) <> 8) or (AUid[0] <> $E0))) or
    not Supports(ASession, IIso15693CustomCommands, Custom) then
    raise ECardWorkflowError.Create('ISO identity, geometry and manufacturer capability required.');
  Supports(ASession, IIso15693FieldReset, Reset);
  if ARequireReset and (Reset = nil) then raise ECardWorkflowError.Create('Explicit RF reset required.');
  Inner := ASession; Count := ACount; Size := ASize; Uid := CopyBytes(AUid);
end;

procedure TIsoGuard.Check(const Info: TIso15693SystemInfo);
begin
  TIso15693Codec.ValidateInfo(Info);
  if (Info.BlockCount <> Count) or (Info.BlockSize <> Size) or
    ((Length(Uid) > 0) and not BytesEqual(Info.Uid, Uid)) then
    raise ECardWorkflowError.Create('ISO identity or geometry changed.');
  if Length(Uid) = 0 then Uid := CopyBytes(Info.Uid);
end;

procedure TIsoGuard.RequireActive;
begin if not Active then raise ECardWorkflowError.Create('ISO guard not active.'); end;

function TIsoGuard.BeginSession: TIso15693SystemInfo;
begin
  if Active then raise ECardWorkflowError.Create('ISO guard already active.');
  Result := Inner.BeginSession;
  try Check(Result); Active := True;
  except try Inner.EndSession; except end; raise; end;
end;

procedure TIsoGuard.EndSession;
begin
  RequireActive;
  try Inner.EndSession; finally Active := False; end;
end;

function TIsoGuard.ReadBlock(const ABlock: Integer): TBytes;
begin
  RequireActive;
  Result := Inner.ReadBlock(ABlock);
end;

function TIsoGuard.SecurityStatus(const ABlock: Integer): Byte;
begin
  RequireActive;
  Result := Inner.SecurityStatus(ABlock);
end;

procedure TIsoGuard.WriteBlock(const ABlock: Integer; const AData: TBytes);
begin
  RequireActive;
  Inner.WriteBlock(ABlock, AData);
end;

function TIsoGuard.ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
begin
  RequireActive;
  Result := Custom.ExchangeCustom(AManufacturer, ACommand, AParameters);
end;

function TIsoGuard.ResetField: TIso15693SystemInfo;
begin
  RequireActive;
  if Reset = nil then raise ECardWorkflowError.Create('ISO RF reset unsupported.');
  Result := Reset.ResetField;
  try Check(Result); except Active := False; try Inner.EndSession; except end; raise; end;
end;

constructor TType2PasswordMemory.Create(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const APassword, APack: TBytes);
begin
  inherited Create; TType2PasswordCodec.ValidateCredentials(AModel, APassword, APack);
  Model := AModel; Raw := CreateType2WorkflowIdentityGuard(AReader);
  R := TType2PasswordCardReader.Create(nil); R.Reader := Raw;
  Password := CopyBytes(APassword); Pack := CopyBytes(APack);
end;

destructor TType2PasswordMemory.Destroy;
begin
  ClearCredentials;
  R.Free;
  inherited Destroy;
end;

procedure TType2PasswordMemory.ClearCredentials;
begin
  TCardCrypto.Clear(Password);
  TCardCrypto.Clear(Pack);
end;

procedure TType2PasswordMemory.Ready;
begin if Length(Password) <> 4 then raise ECardWorkflowError.Create('Protected backend credentials cleared.'); end;

function TType2PasswordMemory.Layout: string;
begin
  Result := 'TYPE2-' + IntToStr(Ord(Model));
end;

function TType2PasswordMemory.UnitSize: Integer;
begin
  Result := 4;
end;

procedure TType2PasswordMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  Ready;
  TType2PasswordCodec.ValidateUserRange(Model, AAddress, 1);
end;

function TType2PasswordMemory.ReadUid: TBytes;
var
  Success: Boolean;
begin
  Ready; Raw.BeginSession; Success := False;
  try Result := Raw.Activate; Success := True;
  finally if Success then Raw.EndSession else try Raw.EndSession; except end; end;
end;

function TType2PasswordMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  Ready;
  Result := R.ReadUserPage(Model, AAddress, Password, Pack);
end;

procedure TType2PasswordMemory.CheckWritable(const AAddress: Integer);
begin
  ValidateUnit(AAddress, True);
  R.CheckUserMemoryWritable(Model, Password, Pack);
end;

procedure TType2PasswordMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  ValidateUnit(AAddress, True);
  if Length(AData) <> 4 then raise ECardWorkflowWriteRefused.Create('Exactly four page bytes required.');
  try
    R.CheckUserMemoryWritable(Model, Password, Pack);
    R.WriteUserPage(Model, AAddress, Password, Pack, AData);
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;

constructor TIsoPasswordMemory.Create(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords;
  const ACount, ASize: Integer);
var
  S: IIso15693Session;
begin
  inherited Create;
  if not (AProfile in [ippSlix2, ippSt25Dv]) or (ASize <> 4) or
    ((AProfile = ippSlix2) and (ACount <> 80)) or
    ((AProfile = ippSt25Dv) and (ACount <> 128) and (ACount <> 512) and (ACount <> 2048)) then
    raise ECardWorkflowError.Create('Explicit supported password profile and geometry required.');
  Profile := AProfile; Count := ACount; Size := ASize;
  S := CreateIso15693WorkflowIdentityGuard(ASession, Count, Size);
  S := TIso15693PasswordSession.Create(S, Profile, APasswords);
  Native := TIso15693WorkflowMemory.Create(S, Count, Size); Memory := Native; Preflight := Native;
end;

procedure TIsoPasswordMemory.ClearCredentials;
begin
  Preflight := nil;
  Memory := nil;
  Native := nil;
end;

procedure TIsoPasswordMemory.Ready;
begin if Memory = nil then raise ECardWorkflowError.Create('Protected backend credentials cleared.'); end;

function TIsoPasswordMemory.Layout: string;
begin
  Result := 'ISO15693-' + IntToStr(Count) + 'x' + IntToStr(Size);
end;

function TIsoPasswordMemory.UnitSize: Integer;
begin
  Result := Size;
end;

procedure TIsoPasswordMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  Ready; Native.ValidateUnit(AAddress, AWriting);
  if AWriting and (Profile = ippSlix2) and (AAddress = 79) then
    raise ECardWorkflowError.Create('SLIX2 counter block is excluded from memory restoration.');
end;

function TIsoPasswordMemory.ReadUid: TBytes;
begin
  Ready;
  Result := Native.ReadUid;
end;

function TIsoPasswordMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  Ready;
  Result := Native.ReadUnit(AAddress);
end;

procedure TIsoPasswordMemory.CheckWritable(const AAddress: Integer);
begin
  ValidateUnit(AAddress, True);
  Native.CheckWritable(AAddress);
end;

procedure TIsoPasswordMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  try
    ValidateUnit(AAddress, True); Native.WriteUnit(AAddress, AData);
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;

procedure TProtectedMemoryWorkflow.ClearOwnedCredentials;
begin
  if FSourceCredentials <> nil then FSourceCredentials.ClearCredentials;
  if FTargetCredentials <> nil then FTargetCredentials.ClearCredentials;
  FSourceCredentials := nil; FTargetCredentials := nil;
end;

procedure TProtectedMemoryWorkflow.RetainCredentials(const ASource, ATarget: ICardWorkflowMemory);
begin
  if ASource <> nil then Supports(ASource, ICardWorkflowCredentialCleanup, FSourceCredentials);
  if ATarget <> nil then Supports(ATarget, ICardWorkflowCredentialCleanup, FTargetCredentials);
end;

destructor TProtectedMemoryWorkflow.Destroy;
begin
  ClearOwnedCredentials;
  inherited Destroy;
end;

procedure TProtectedMemoryWorkflow.PrepareProtectedBackup(const ASource: ICardWorkflowMemory;
  const AAddresses: TCardWorkflowAddresses);
begin
  RequireIdle; ClearOwnedCredentials; RetainCredentials(ASource, nil);
  try inherited PrepareBackup(ASource, AAddresses); except ClearOwnedCredentials; raise; end;
end;

procedure TProtectedMemoryWorkflow.PrepareProtectedCopy(const ASource, ATarget: ICardWorkflowMemory;
  const AAddresses: TCardWorkflowAddresses; const ACompareOnly: Boolean);
begin
  RequireIdle; ClearOwnedCredentials; RetainCredentials(ASource, ATarget);
  try inherited PrepareCopy(ASource, ATarget, AAddresses, ACompareOnly); except ClearOwnedCredentials; raise; end;
end;

procedure TProtectedMemoryWorkflow.PrepareProtectedRestore(const ASnapshot: TCardWorkflowSnapshot;
  const ATarget: ICardWorkflowMemory; const ACompareOnly: Boolean);
begin
  RequireIdle; ClearOwnedCredentials; RetainCredentials(nil, ATarget);
  try inherited PrepareRestore(ASnapshot, ATarget, ACompareOnly); except ClearOwnedCredentials; raise; end;
end;

procedure TProtectedMemoryWorkflow.DoExecute;
begin try inherited DoExecute; finally ClearOwnedCredentials; end; end;

function CreateType2PasswordWorkflowMemory(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const APassword, AExpectedPack: TBytes): ICardWorkflowMemory;
begin
  Result := TType2PasswordMemory.Create(AReader, AModel, APassword, AExpectedPack);
end;

function CreateIso15693PasswordWorkflowMemory(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords;
  const ABlockCount, ABlockSize: Integer): ICardWorkflowMemory;
begin
  Result := TIsoPasswordMemory.Create(ASession, AProfile, APasswords, ABlockCount, ABlockSize);
end;

function CreateType2WorkflowIdentityGuard(const AReader: IRawContactlessReader;
  const AExpectedUid: TBytes): IRawContactlessReader;
begin
  Result := TRawGuard.Create(AReader, AExpectedUid);
end;

function CreateIso15693WorkflowIdentityGuard(const ASession: IIso15693Session;
  const ABlockCount, ABlockSize: Integer; const AExpectedUid: TBytes;
  const ARequireReset: Boolean): IIso15693Session;
begin
  Result := TIsoGuard.Create(ASession, ABlockCount, ABlockSize, AExpectedUid, ARequireReset);
end;

end.
