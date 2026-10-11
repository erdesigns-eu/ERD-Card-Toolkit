unit ERD.Card.Contactless.Workflow.Ndef.Protected;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Ndef,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.Workflow.Ndef,
  ERD.Card.Contactless.Workflow.Password;

type
  /// <summary>Credential-owning logical NDEF backup/copy/compare/restore/template and explicit clear workflow.</summary>
  /// <remarks>Native backends pin identity before authentication. Preparation performs no I/O;
  /// copied credentials are consumed on execution, failed preparation, replacement or destruction.
  /// Only logical records transfer; credentials, CC, locks and vendor configuration remain separate.</remarks>
  TProtectedNdefWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: ICardWorkflowNdef;
    FSourceCleanup, FTargetCleanup: ICardWorkflowCredentialCleanup;
    FBytes: TBytes;
    FPrepared, FConsumed, FCompareOnly, FAllowClear, FVerified, FDifferent: Boolean;
    procedure ClearCredentials;
    procedure Retain(const ASource, ATarget: ICardWorkflowNdef);
    function GetBytes: TBytes;
  protected
    /// <summary>Checks single-use readiness without card I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Acquires source/target, compares logical records, writes once and verifies, then clears credentials.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Clears unexecuted owned backend credentials.</summary>
    destructor Destroy; override;
    /// <summary>Prepares logical copy, read-only backup or comparison.</summary>
    /// <param name="ASource">Fresh protected or compatible public source backend.</param>
    /// <param name="ATarget">Destination; nil for source backup only.</param>
    /// <param name="ACompareOnly">True compares without writing.</param>
    /// <param name="AAllowClear">Explicit permission for an empty source to clear destination.</param>
    procedure PrepareCopy(const ASource, ATarget: ICardWorkflowNdef;
      const ACompareOnly: Boolean = False; const AAllowClear: Boolean = False);
    /// <summary>Prepares logical template/restore or comparison; empty records require explicit clear permission for writes.</summary>
    /// <param name="ATarget">Fresh destination backend.</param>
    /// <param name="AMessage">Independent logical records copied during preparation.</param>
    /// <param name="ACompareOnly">True compares without writing.</param>
    /// <param name="AAllowClear">Required for actual empty-message writes.</param>
    procedure PrepareWrite(const ATarget: ICardWorkflowNdef; const AMessage: TNdefMessage;
      const ACompareOnly: Boolean = False; const AAllowClear: Boolean = False);
    /// <summary>Independent acquired/template logical bytes; contains application data but no credentials.</summary>
    property MessageBytes: TBytes read GetBytes;
    /// <summary>True when the acquired destination differed; no-op writes are skipped.</summary>
    property Different: Boolean read FDifferent;
    /// <summary>True only after matching destination acquisition or successful post-write read-back and release.</summary>
    property ReadBackVerified: Boolean read FVerified;
  end;

/// <summary>Creates a frozen PWD_AUTH/PACK logical NDEF backend without I/O.</summary>
/// <param name="AReader">Inactive exclusive raw Type A reader.</param>
/// <param name="AModel">Explicit password-capable EV1/NTAG geometry.</param>
/// <param name="APassword">Four supplied bytes, copied.</param>
/// <param name="AExpectedPack">Two mandatory expected bytes, copied.</param>
/// <param name="AExpectedUid">Optional seven-byte UID, otherwise pin first selection.</param>
/// <returns>Owned native length-last NDEF backend with credential cleanup.</returns>
function CreateType2PasswordWorkflowNdef(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const APassword, AExpectedPack: TBytes;
  const AExpectedUid: TBytes = nil): ICardWorkflowNdef;

/// <summary>Creates a frozen authenticated Type 5 logical NDEF backend without I/O.</summary>
/// <param name="ASession">Inactive addressed manufacturer-capable session.</param>
/// <param name="AProfile">SLIX2 or original ST25DV dialect.</param>
/// <param name="APasswords">Explicit copied wire-order read/write credentials.</param>
/// <param name="ABlockCount">Exact SLIX2 80 or ST25DV 128/512/2048 geometry.</param>
/// <param name="AExpectedUid">Optional canonical eight-byte UID, else pin first acquisition.</param>
/// <returns>Owned initialized Type 5 mapping backend; proprietary CC access code two explicitly permitted.</returns>
/// <remarks>No formatting, CC changes or permanent locks. SLIX2 mappings containing counter block 79 are refused before writes.</remarks>
function CreateIso15693PasswordWorkflowNdef(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords;
  const ABlockCount: Integer; const AExpectedUid: TBytes = nil): ICardWorkflowNdef;

implementation

uses ERD.Card.Crypto, ERD.Card.Contactless, ERD.Card.Contactless.Type2.Password,
  ERD.Card.Contactless.Type5.Ndef;

type
  TProtectedNdef = class(TInterfacedObject, ICardWorkflowNdef, ICardWorkflowCredentialCleanup)
  private
    FType2: TType2PasswordCardReader;
    FType5: TType5NdefCardReader;
    FPassword, FPack: TBytes;
    FModel: TType2TagModel;
    FProfile: TIso15693PasswordProfile;
    FCleared: Boolean;
    procedure Ready;
  public
    destructor Destroy; override;
    procedure ClearCredentials;
    function ReadMessage: TBytes;
    procedure WriteMessage(const ABytes: TBytes);
  end;

function Canonical(const ABytes: TBytes): TBytes;
begin
  Result := nil;
  if Length(ABytes) > 0 then Result := TNdefCodec.Encode(TNdefCodec.Decode(ABytes));
end;

destructor TProtectedNdef.Destroy;
begin
  ClearCredentials;
  FType2.Free;
  FType5.Free;
  inherited Destroy;
end;

procedure TProtectedNdef.ClearCredentials;
begin
  TCardCrypto.Clear(FPassword);
  TCardCrypto.Clear(FPack);
  if FType5 <> nil then FType5.Session := nil;
  FCleared := True;
end;

procedure TProtectedNdef.Ready;
begin
  if FCleared then raise ECardWorkflowError.Create('Protected NDEF backend consumed.');
end;

function TProtectedNdef.ReadMessage: TBytes;
begin
  Ready;
  if FType2 <> nil then Result := Canonical(FType2.ReadNdef(FModel, FPassword, FPack).MessageBytes)
  else Result := Canonical(FType5.ReadMessage.MessageBytes);
end;

procedure TProtectedNdef.WriteMessage(const ABytes: TBytes);
var
  Bytes: TBytes;
  Message: TNdefMessage;
  Before: TType5NdefSnapshot;
begin
  try
    Ready;
    Bytes := Canonical(ABytes);
    if FType2 <> nil then FType2.WriteNdefVerified(FModel, Bytes, FPassword, FPack)
    else
    begin
      Before := FType5.ReadMessage;
      if (FProfile = ippSlix2) and (Length(Before.PhysicalBytes) > 79 * 4) then
        raise ECardWorkflowError.Create('SLIX2 counter overlaps NDEF mapping.');
      if Length(Bytes) = 0 then FType5.ClearMessage
      else
      begin
        Message := TNdefCodec.Decode(Bytes);
        FType5.WriteMessage(Message);
      end;
    end;
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;

function CreateType2PasswordWorkflowNdef(const AReader: IRawContactlessReader;
  const AModel: TType2TagModel; const APassword, AExpectedPack, AExpectedUid: TBytes): ICardWorkflowNdef;
var
  Adapter: TProtectedNdef;
begin
  TType2PasswordCodec.ValidateCredentials(AModel, APassword, AExpectedPack);
  Adapter := TProtectedNdef.Create;
  Result := Adapter;
  Adapter.FType2 := TType2PasswordCardReader.Create(nil);
  Adapter.FType2.Reader := CreateType2WorkflowIdentityGuard(AReader, AExpectedUid);
  Adapter.FModel := AModel;
  Adapter.FPassword := CopyBytes(APassword);
  Adapter.FPack := CopyBytes(AExpectedPack);
end;

function CreateIso15693PasswordWorkflowNdef(const ASession: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords;
  const ABlockCount: Integer; const AExpectedUid: TBytes): ICardWorkflowNdef;
var
  Adapter: TProtectedNdef;
  Session: IIso15693Session;
begin
  if not (AProfile in [ippSlix2, ippSt25Dv]) or
    ((AProfile = ippSlix2) and (ABlockCount <> 80)) or
    ((AProfile = ippSt25Dv) and (ABlockCount <> 128) and (ABlockCount <> 512) and (ABlockCount <> 2048)) then
    raise ECardWorkflowError.Create('Explicit supported protected Type 5 geometry required.');
  Session := CreateIso15693WorkflowIdentityGuard(ASession, ABlockCount, 4, AExpectedUid);
  Session := TIso15693PasswordSession.Create(Session, AProfile, APasswords);
  Adapter := TProtectedNdef.Create;
  Result := Adapter;
  Adapter.FProfile := AProfile;
  Adapter.FType5 := TType5NdefCardReader.Create(nil);
  Adapter.FType5.Session := Session;
  Adapter.FType5.AllowProprietaryAccess := True;
end;

procedure TProtectedNdefWorkflow.ClearCredentials;
begin
  if FSourceCleanup <> nil then FSourceCleanup.ClearCredentials;
  if FTargetCleanup <> nil then FTargetCleanup.ClearCredentials;
  FSourceCleanup := nil;
  FTargetCleanup := nil;
end;

procedure TProtectedNdefWorkflow.Retain(const ASource, ATarget: ICardWorkflowNdef);
begin
  ClearCredentials;
  FSource := ASource;
  FTarget := ATarget;
  if ASource <> nil then Supports(ASource, ICardWorkflowCredentialCleanup, FSourceCleanup);
  if ATarget <> nil then Supports(ATarget, ICardWorkflowCredentialCleanup, FTargetCleanup);
end;

destructor TProtectedNdefWorkflow.Destroy;
begin
  ClearCredentials;
  inherited Destroy;
end;

function TProtectedNdefWorkflow.GetBytes: TBytes;
begin
  Result := CopyBytes(FBytes);
end;

procedure TProtectedNdefWorkflow.PrepareCopy(const ASource, ATarget: ICardWorkflowNdef;
  const ACompareOnly, AAllowClear: Boolean);
begin
  RequireIdle;
  FPrepared := False;
  Retain(ASource, ATarget);
  try
    if ASource = nil then raise ECardWorkflowError.Create('Explicit NDEF source required.');
    FBytes := nil;
    FCompareOnly := ACompareOnly;
    FAllowClear := AAllowClear;
    FVerified := False;
    FDifferent := False;
    FConsumed := False;
    FPrepared := True;
  except
    ClearCredentials;
    raise;
  end;
end;

procedure TProtectedNdefWorkflow.PrepareWrite(const ATarget: ICardWorkflowNdef;
  const AMessage: TNdefMessage; const ACompareOnly, AAllowClear: Boolean);
begin
  RequireIdle;
  FPrepared := False;
  Retain(nil, ATarget);
  try
    if (ATarget = nil) or ((Length(AMessage) = 0) and not (ACompareOnly or AAllowClear)) then
      raise ECardWorkflowError.Create('Target and explicit empty-write permission required.');
    FBytes := nil;
    if Length(AMessage) > 0 then FBytes := TNdefCodec.Encode(AMessage);
    FCompareOnly := ACompareOnly;
    FAllowClear := AAllowClear;
    FVerified := False;
    FDifferent := False;
    FConsumed := False;
    FPrepared := True;
  except
    ClearCredentials;
    raise;
  end;
end;

procedure TProtectedNdefWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then raise ECardWorkflowError.Create('Prepare a fresh protected NDEF request.');
end;

procedure TProtectedNdefWorkflow.DoExecute;
var
  Before: TBytes;
begin
  FConsumed := True;
  try
    if FSource <> nil then
    begin
      if not RequestCard(cwrSource) then begin Cancel; Exit; end;
      Progress(cwsReading, 0, 1);
      if CancelRequested then Exit;
      FBytes := Canonical(FSource.ReadMessage);
      Progress(cwsReading, 1, 1);
    end;
    if (FTarget = nil) or CancelRequested then Exit;
    if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Progress(cwsChecking, 0, 1);
    if CancelRequested then Exit;
    Before := Canonical(FTarget.ReadMessage);
    FDifferent := not BytesEqual(Before, FBytes);
    if not FDifferent then
    begin
      FVerified := True;
      Exit;
    end;
    if FCompareOnly or CancelRequested then Exit;
    if (Length(FBytes) = 0) and not FAllowClear then
      raise ECardWorkflowError.Create('Source empty; target clear was not requested.');
    Progress(cwsWriting, 0, 1);
    if CancelRequested then Exit;
    MutationPending(True);
    try
      FTarget.WriteMessage(CopyBytes(FBytes));
    except
      on E: ECardWorkflowWriteRefused do begin MutationPending(False); raise; end;
    end;
    MutationPending(True);
    Progress(cwsVerifying, 0, 1);
    if not BytesEqual(Canonical(FTarget.ReadMessage), FBytes) then
      raise ECardWorkflowError.Create('Protected NDEF read-back mismatch.');
    FVerified := True;
    MutationPending(False);
    Progress(cwsVerifying, 1, 1);
  finally
    ClearCredentials;
  end;
end;

end.
