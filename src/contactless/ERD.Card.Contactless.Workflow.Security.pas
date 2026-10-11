unit ERD.Card.Contactless.Workflow.Security;

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
  /// <summary>Reviewed single-operation plan without any current or replacement credentials.</summary>
  TCardSecurityPlan = record
    /// <summary>Explicit native family/profile name.</summary>
    Family: string;
    /// <summary>Password/PACK replacement or protection policy change.</summary>
    Operation: string;
    /// <summary>Exact intended card UID, copied independently.</summary>
    Uid: TBytes;
    /// <summary>Credential identifier or area number; zero for Type 2 and SLIX2 protection.</summary>
    Identifier: Integer;
    /// <summary>Complete non-secret configuration preimage; empty for unreadable password storage.</summary>
    Before: TBytes;
    /// <summary>Complete desired non-secret configuration, preserving unrelated fields.</summary>
    After: TBytes;
  end;
  /// <summary>Prepared native change with copied private credentials and a secret-free review plan.</summary>
  ICardSecurityOperation = interface
    ['{0783AAD6-CC30-4E25-844A-1169366C544F}']
    /// <summary>Returns an independently owned review plan without I/O.</summary>
    /// <returns>Explicit same-card intended change; never includes credentials.</returns>
    function Plan: TCardSecurityPlan;
    /// <summary>Checks a fresh request without I/O.</summary>
    procedure Validate;
    /// <summary>Dispatches once and proves the change through fresh same-card authentication/configuration.</summary>
    /// <remarks>After possible mutation, raises EContactlessWriteUncertain; never retries.</remarks>
    procedure ApplyVerified;
    /// <summary>Wipes copied credentials, permanently consuming the operation; no hardware I/O or exceptions.</summary>
    procedure ClearCredentials;
  end;
  /// <summary>Reviewable password and protection workflow for Type 2, SLIX2 and original ST25DV.</summary>
  /// <remarks>Configure a native operation below, review Plan, then Execute once. The explicit
  /// expected UID is checked before authentication. Verified success requires native fresh RF
  /// proof and release. A pre-dispatch failure is Failed, an ambiguous dispatched mutation is
  /// Uncertain. No irreversible locks, guessing, automatic rollback or replay is performed.</remarks>
  TCardSecurityWorkflow = class(TCardWorkflow)
  private
    FOperation: ICardSecurityOperation;
    FPlan: TCardSecurityPlan;
    FPrepared, FConsumed: Boolean;
    FResult: TCardWorkflowUnitState;
    function GetPlan: TCardSecurityPlan;
  protected
    /// <summary>Checks a fresh prepared operation without card I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Applies one verified operation and wipes credentials on every exit.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Wipes credentials for an unexecuted prepared operation.</summary>
    destructor Destroy; override;
    /// <summary>Retains a validated explicit operation and independently copies its review plan.</summary>
    /// <param name="AOperation">Fresh single-use operation from a native factory or compatible application provider.</param>
    procedure Prepare(const AOperation: ICardSecurityOperation);
    /// <summary>Independently owned secret-free intended change.</summary>
    property Plan: TCardSecurityPlan read GetPlan;
    /// <summary>Pending, Verified or Uncertain completion evidence; no secret read-back is claimed.</summary>
    property ResultState: TCardWorkflowUnitState read FResult;
  end;

/// <summary>Prepares Type 2 password/PACK replacement with explicit same-card fresh authentication proof.</summary>
/// <param name="AReader">Inactive exclusive raw Type A reader.</param>
/// <param name="AModel">Explicit password-capable EV1/NTAG model.</param>
/// <param name="AExpectedUid">Exact intended seven-byte UID.</param>
/// <param name="ACurrentPassword">Four current supplied bytes.</param>
/// <param name="ACurrentPack">Two current expected PACK bytes.</param>
/// <param name="ANewPassword">Four replacement bytes.</param>
/// <param name="ANewPack">Two replacement PACK bytes.</param>
/// <returns>Single-use owned operation; its public plan contains no credentials.</returns>
function CreateType2CredentialOperation(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const AExpectedUid, ACurrentPassword, ACurrentPack,
  ANewPassword, ANewPack: TBytes): ICardSecurityOperation;

/// <summary>Prepares an exact-preimage AUTH0/PROT/AUTHLIM update preserving unrelated Type 2 configuration.</summary>
/// <param name="AReader">Inactive raw Type A reader.</param>
/// <param name="AModel">Explicit password-capable model.</param>
/// <param name="AExpectedUid">Exact intended seven-byte UID.</param>
/// <param name="AExpectedPages">Exact eight configuration bytes; excludes PWD/PACK storage.</param>
/// <param name="APassword">Four supplied current bytes.</param>
/// <param name="AExpectedPack">Two expected PACK bytes.</param>
/// <param name="AFirstProtectedPage">Explicit AUTH0 byte.</param>
/// <param name="AProtectReads">True protects reads and writes.</param>
/// <param name="AAuthenticationLimit">Explicit AUTHLIM zero through seven; zero disables negative attempt limit.</param>
/// <returns>Single-use operation with independently owned before/after review bytes.</returns>
function CreateType2ProtectionOperation(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const AExpectedUid, AExpectedPages, APassword,
  AExpectedPack: TBytes; const AFirstProtectedPage: Byte; const AProtectReads: Boolean;
  const AAuthenticationLimit: Byte): ICardSecurityOperation;

/// <summary>Prepares SLIX2 or original ST25DV password replacement with fresh same-card proof.</summary>
/// <param name="ASession">Inactive addressed session with manufacturer and RF-reset capabilities.</param>
/// <param name="AProfile">Explicit supported chip/password dialect.</param>
/// <param name="AExpectedUid">Exact canonical eight-byte target UID.</param>
/// <param name="ABlockCount">Exact expected memory geometry.</param>
/// <param name="ABlockSize">Exact expected byte width.</param>
/// <param name="AIdentifier">SLIX2 read/write identifier 1/2, or ST25DV password 0..3.</param>
/// <param name="ACurrentPassword">Current four/eight wire-order bytes.</param>
/// <param name="ANewPassword">Replacement four/eight wire-order bytes.</param>
/// <param name="AExternalPowerStable">Explicit stable VCC guarantee when required by ST25DV; false does not assume stability.</param>
/// <returns>Single-use owned operation with a secret-free plan.</returns>
function CreateIso15693CredentialOperation(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const AExpectedUid: TBytes;
  const ABlockCount, ABlockSize: Integer; const AIdentifier: Byte;
  const ACurrentPassword, ANewPassword: TBytes;
  const AExternalPowerStable: Boolean = False): ICardSecurityOperation;

/// <summary>Prepares SLIX2 paged protection with complete lock/feature preimage preservation.</summary>
/// <param name="ASession">Inactive addressed session with manufacturer and RF-reset capabilities.</param>
/// <param name="AExpectedUid">Exact intended canonical SLIX2 UID.</param>
/// <param name="AReadPassword">Four current read-password bytes.</param>
/// <param name="AWritePassword">Four current write-password bytes.</param>
/// <param name="AExpected">Exact previously acquired seven/eleven-byte AB snapshot.</param>
/// <param name="APointerBlock">First Page H block, zero through 78.</param>
/// <param name="AConditions">Only RL/WL/RH/WH bits 0/1/4/5.</param>
/// <returns>Single-use operation; no lock, privacy or counter change is included.</returns>
function CreateSlix2ProtectionOperation(const ASession: IIso15693Session;
  const AExpectedUid, AReadPassword, AWritePassword, AExpected: TBytes;
  const APointerBlock, AConditions: Byte): ICardSecurityOperation;

/// <summary>Prepares one original ST25DV RF-area access update without resizing or permanent locks.</summary>
/// <param name="ASession">Inactive session with manufacturer and RF-reset capabilities.</param>
/// <param name="AExpectedUid">Exact intended canonical UID.</param>
/// <param name="ABlockCount">Exact supported ST25DV geometry, 128/512/2048 blocks.</param>
/// <param name="AConfigurationPassword">Eight supplied RF password-zero bytes.</param>
/// <param name="AExpected">Exact previously acquired eight-register configuration.</param>
/// <param name="AArea">One active area, one through four.</param>
/// <param name="APasswordNumber">New user password number, zero through three.</param>
/// <param name="AProtectionCode">Explicit two-bit RF access policy.</param>
/// <param name="AExternalPowerStable">Explicit external power guarantee where required.</param>
/// <returns>Single-use operation with complete non-secret before/after review bytes.</returns>
function CreateSt25ProtectionOperation(const ASession: IIso15693Session;
  const AExpectedUid: TBytes; const ABlockCount: Integer;
  const AConfigurationPassword, AExpected: TBytes;
  const AArea, APasswordNumber, AProtectionCode: Byte;
  const AExternalPowerStable: Boolean = False): ICardSecurityOperation;

implementation

uses ERD.Card.Crypto, ERD.Card.Contactless, ERD.Card.Contactless.Type2.Password,
  ERD.Card.Contactless.Workflow.Password;

type
  TOperation = class(TInterfacedObject, ICardSecurityOperation)
  private
    Review: TCardSecurityPlan;
    Type2: TType2PasswordCardReader;
    Iso: TIso15693SecurityManager;
    Model: TType2TagModel;
    Profile: TIso15693PasswordProfile;
    Password, Pack, NewPassword, NewPack, SecondPassword: TBytes;
    CredentialChange, PowerStable, Cleared: Boolean;
    Auth0, Limit, Pointer, Conditions, Area, PasswordNumber, ProtectionCode: Byte;
    ProtectReads: Boolean;
  public
    destructor Destroy; override;
    function Plan: TCardSecurityPlan;
    procedure Validate;
    procedure ApplyVerified;
    procedure ClearCredentials;
  end;

function ClonePlan(const P: TCardSecurityPlan): TCardSecurityPlan;
begin
  Result := P; Result.Uid := CopyBytes(P.Uid); Result.Before := CopyBytes(P.Before); Result.After := CopyBytes(P.After);
end;

destructor TOperation.Destroy;
begin
  ClearCredentials;
  Type2.Free;
  Iso.Free;
  inherited Destroy;
end;

function TOperation.Plan: TCardSecurityPlan;
begin
  Result := ClonePlan(Review);
end;

procedure TOperation.Validate;
begin
  if Cleared or ((Type2 = nil) and (Iso = nil)) then raise ECardWorkflowError.Create('Prepare a fresh native security operation.');
end;

procedure TOperation.ClearCredentials;
begin
  TCardCrypto.Clear(Password); TCardCrypto.Clear(Pack); TCardCrypto.Clear(NewPassword);
  TCardCrypto.Clear(NewPack); TCardCrypto.Clear(SecondPassword); Cleared := True;
end;

procedure TOperation.ApplyVerified;
begin
  Validate;
  try
    if Type2 <> nil then
    begin
      if CredentialChange then Type2.ChangeCredentialsVerified(Model, Password, Pack, NewPassword, NewPack)
      else Type2.ConfigureAuthenticationVerified(Model, Auth0, ProtectReads, Limit, Review.Before, Password, Pack);
    end
    else if CredentialChange then
    begin
      if Profile = ippSlix2 then Iso.ChangeSlix2Password(Byte(Review.Identifier), Password, NewPassword)
      else Iso.ChangeSt25Password(Byte(Review.Identifier), Password, NewPassword, PowerStable);
    end
    else if Profile = ippSlix2 then Iso.ConfigureSlix2Protection(Password, SecondPassword, Review.Before, Pointer, Conditions)
    else Iso.ConfigureSt25Area(Area, Password, Review.Before, PasswordNumber, ProtectionCode, PowerStable);
  finally ClearCredentials; end;
end;

function CreateType2CredentialOperation(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const AExpectedUid, ACurrentPassword, ACurrentPack,
  ANewPassword, ANewPack: TBytes): ICardSecurityOperation;
var
  O: TOperation;
begin
  TType2PasswordCodec.ValidateCredentials(AModel, ACurrentPassword, ACurrentPack);
  TType2PasswordCodec.ValidateCredentials(AModel, ANewPassword, ANewPack);
  if Length(AExpectedUid) <> 7 then raise ECardWorkflowError.Create('Explicit seven-byte target UID required.');
  O := TOperation.Create; Result := O;
  O.Type2 := TType2PasswordCardReader.Create(nil);
  O.Type2.Reader := CreateType2WorkflowIdentityGuard(AReader, AExpectedUid); O.Model := AModel;
  O.Password := CopyBytes(ACurrentPassword); O.Pack := CopyBytes(ACurrentPack);
  O.NewPassword := CopyBytes(ANewPassword); O.NewPack := CopyBytes(ANewPack); O.CredentialChange := True;
  O.Review.Family := 'TYPE2-' + IntToStr(Ord(AModel)); O.Review.Operation := 'Replace password and PACK with fresh RF proof';
  O.Review.Uid := CopyBytes(AExpectedUid);
end;

function CreateType2ProtectionOperation(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const AExpectedUid, AExpectedPages, APassword,
  AExpectedPack: TBytes; const AFirstProtectedPage: Byte; const AProtectReads: Boolean;
  const AAuthenticationLimit: Byte): ICardSecurityOperation;
var
  O: TOperation;
  Desired: TBytes;
begin
  TType2PasswordCodec.ValidateCredentials(AModel, APassword, AExpectedPack);
  if (Length(AExpectedUid) <> 7) or (Length(AExpectedPages) <> 8) or (AAuthenticationLimit > 7) then
    raise ECardWorkflowError.Create('Explicit identity, configuration preimage and valid AUTHLIM required.');
  Desired := CopyBytes(AExpectedPages); Desired[3] := AFirstProtectedPage;
  Desired[4] := (Desired[4] and $78) or AAuthenticationLimit;
  if AProtectReads then Desired[4] := Desired[4] or $80;
  if ((AExpectedPages[4] and $40) <> 0) and not BytesEqual(Desired, AExpectedPages) then
    raise ECardWorkflowError.Create('Type 2 configuration permanently locked.');
  O := TOperation.Create; Result := O; O.Type2 := TType2PasswordCardReader.Create(nil);
  O.Type2.Reader := CreateType2WorkflowIdentityGuard(AReader, AExpectedUid); O.Model := AModel;
  O.Password := CopyBytes(APassword); O.Pack := CopyBytes(AExpectedPack);
  O.Auth0 := AFirstProtectedPage; O.ProtectReads := AProtectReads; O.Limit := AAuthenticationLimit;
  O.Review.Family := 'TYPE2-' + IntToStr(Ord(AModel)); O.Review.Operation := 'Update AUTH0/PROT/AUTHLIM';
  O.Review.Uid := CopyBytes(AExpectedUid); O.Review.Before := CopyBytes(AExpectedPages); O.Review.After := Desired;
end;

function NewIsoOperation(const ASession: IIso15693Session; const AProfile: TIso15693PasswordProfile;
  const AUid: TBytes; const ACount, ASize: Integer): ICardSecurityOperation;
var
  O: TOperation;
  Info: TIso15693SystemInfo;
begin
  if (Length(AUid) <> 8) or (AUid[0] <> $E0) then raise ECardWorkflowError.Create('Explicit canonical target UID required.');
  Info := Default(TIso15693SystemInfo); Info.Uid := CopyBytes(AUid);
  Info.BlockCount := ACount; Info.BlockSize := ASize;
  // ST profiles additionally require IC_REF from the live tag; UID/product and exact geometry are checked here.
  if AProfile = ippSlix2 then TIso15693Codec.ValidatePasswordProfile(Info, AProfile)
  else
  begin
    if (AUid[1] <> $02) or (ASize <> 4) or
      not (((AUid[2] = $24) and (ACount = 128)) or ((AUid[2] = $26) and ((ACount = 512) or (ACount = 2048)))) then
      raise ECardWorkflowError.Create('Explicit original ST25DV identity and geometry required.');
  end;
  O := TOperation.Create; Result := O; O.Profile := AProfile;
  O.Iso := TIso15693SecurityManager.Create(nil);
  O.Iso.Session := CreateIso15693WorkflowIdentityGuard(ASession, ACount, ASize, AUid, True);
  O.Review.Family := 'ISO15693-SLIX2'; if AProfile = ippSt25Dv then O.Review.Family := 'ISO15693-ST25DV';
  O.Review.Uid := CopyBytes(AUid);
end;

function CreateIso15693CredentialOperation(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const AExpectedUid: TBytes;
  const ABlockCount, ABlockSize: Integer; const AIdentifier: Byte;
  const ACurrentPassword, ANewPassword: TBytes; const AExternalPowerStable: Boolean): ICardSecurityOperation;
var
  O: TOperation;
  Size: Integer;
begin
  if not (AProfile in [ippSlix2, ippSt25Dv]) then raise ECardWorkflowError.Create('Explicit password dialect required.');
  Size := 4; if AProfile = ippSt25Dv then Size := 8;
  if (Length(ACurrentPassword) <> Size) or (Length(ANewPassword) <> Size) or
    ((AProfile = ippSlix2) and not (AIdentifier in [1, 2])) or
    ((AProfile = ippSt25Dv) and (AIdentifier > 3)) then raise ECardWorkflowError.Create('Invalid password replacement inputs.');
  Result := NewIsoOperation(ASession, AProfile, AExpectedUid, ABlockCount, ABlockSize);
  O := Result as TOperation; O.CredentialChange := True; O.PowerStable := AExternalPowerStable;
  O.Password := CopyBytes(ACurrentPassword); O.NewPassword := CopyBytes(ANewPassword);
  O.Review.Identifier := AIdentifier; O.Review.Operation := 'Replace supplied password with fresh RF proof';
end;

function CreateSlix2ProtectionOperation(const ASession: IIso15693Session;
  const AExpectedUid, AReadPassword, AWritePassword, AExpected: TBytes;
  const APointerBlock, AConditions: Byte): ICardSecurityOperation;
var
  O: TOperation;
  P: TSlix2Protection;
begin
  P := TIso15693Codec.DecodeSlix2Protection(AExpected);
  if (Length(AReadPassword) <> 4) or (Length(AWritePassword) <> 4) or
    (APointerBlock > 78) or ((AConditions and $CC) <> 0) then
    raise ECardWorkflowError.Create('Invalid SLIX2 protection inputs.');
  if (P.Features and 1) = 0 then raise ECardWorkflowError.Create('SLIX2 protection feature unavailable.');
  if (P.LockBits and 8) <> 0 then
    raise ECardWorkflowError.Create('SLIX2 protection permanently locked.');
  Result := NewIsoOperation(ASession, ippSlix2, AExpectedUid, 80, 4); O := Result as TOperation;
  O.Password := CopyBytes(AReadPassword); O.SecondPassword := CopyBytes(AWritePassword);
  O.Pointer := APointerBlock; O.Conditions := AConditions;
  O.Review.Operation := 'Update SLIX2 Page L/H password protection';
  O.Review.Before := CopyBytes(AExpected); O.Review.After := CopyBytes(AExpected);
  O.Review.After[0] := APointerBlock; O.Review.After[1] := AConditions;
end;

function CreateSt25ProtectionOperation(const ASession: IIso15693Session;
  const AExpectedUid: TBytes; const ABlockCount: Integer;
  const AConfigurationPassword, AExpected: TBytes;
  const AArea, APasswordNumber, AProtectionCode: Byte;
  const AExternalPowerStable: Boolean): ICardSecurityOperation;
var
  O: TOperation;
  Info: TIso15693SystemInfo;
  C: TSt25RfConfiguration;
  Index: Integer;
begin
  if (Length(AConfigurationPassword) <> 8) or (AArea < 1) or (AArea > 4) or
    (APasswordNumber > 3) or (AProtectionCode > 3) or
    ((APasswordNumber = 0) and (AProtectionCode <> 0) and not ((AArea = 1) and (AProtectionCode = 3))) then
    raise ECardWorkflowError.Create('Invalid ST25DV area/password policy inputs.');
  Result := NewIsoOperation(ASession, ippSt25Dv, AExpectedUid, ABlockCount, 4); O := Result as TOperation;
  Info := Default(TIso15693SystemInfo); Info.Uid := CopyBytes(AExpectedUid);
  Info.BlockCount := ABlockCount; Info.BlockSize := 4; Info.HasIcReference := True;
  Info.IcReference := AExpectedUid[2]; C := TIso15693Codec.DecodeSt25Configuration(AExpected, Info);
  Index := 2 * (AArea - 1);
  if C.Areas[AArea - 1].BlockCount = 0 then raise ECardWorkflowError.Create('ST25DV area inactive.');
  O.Review.Before := CopyBytes(AExpected); O.Review.After := CopyBytes(AExpected);
  O.Review.After[Index] := (O.Review.After[Index] and $F0) or APasswordNumber or (AProtectionCode shl 2);
  if C.ConfigurationLocked then
    raise ECardWorkflowError.Create('ST25DV RF configuration permanently locked.');
  O.Password := CopyBytes(AConfigurationPassword); O.Area := AArea; O.PasswordNumber := APasswordNumber;
  O.ProtectionCode := AProtectionCode; O.PowerStable := AExternalPowerStable;
  O.Review.Identifier := AArea; O.Review.Operation := 'Update one ST25DV RF area access policy';
end;

function TCardSecurityWorkflow.GetPlan: TCardSecurityPlan;
begin
  Result := ClonePlan(FPlan);
end;

destructor TCardSecurityWorkflow.Destroy;
begin if FOperation <> nil then FOperation.ClearCredentials; inherited Destroy; end;

procedure TCardSecurityWorkflow.Prepare(const AOperation: ICardSecurityOperation);
var
  P: TCardSecurityPlan;
begin
  RequireIdle; FPrepared := False;
  if FOperation <> nil then FOperation.ClearCredentials;
  FOperation := nil;
  if AOperation = nil then raise ECardWorkflowError.Create('Explicit security operation required.');
  AOperation.Validate; P := AOperation.Plan;
  if (P.Family = '') or (P.Operation = '') or not (Length(P.Uid) in [7, 8]) or
    (Length(P.Before) > 11) or (Length(P.After) <> Length(P.Before)) then
    raise ECardWorkflowError.Create('Invalid security review plan.');
  FOperation := AOperation; FPlan := ClonePlan(P); FResult := cwusPending;
  FPrepared := True; FConsumed := False;
end;

procedure TCardSecurityWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed or (FOperation = nil) then raise ECardWorkflowError.Create('Prepare a new security operation.');
  FOperation.Validate;
end;

procedure TCardSecurityWorkflow.DoExecute;
begin
  FConsumed := True;
  try
    if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Progress(cwsChecking, 0, 1); if CancelRequested then Exit;
    Progress(cwsWriting, 0, 1); if CancelRequested then Exit;
    try FOperation.ApplyVerified;
    except on E: EContactlessWriteUncertain do
      begin FResult := cwusUncertain; MutationPending(True); raise; end;
    end;
    FResult := cwusVerified; Progress(cwsVerifying, 1, 1);
  finally FOperation.ClearCredentials; end;
end;

end.
