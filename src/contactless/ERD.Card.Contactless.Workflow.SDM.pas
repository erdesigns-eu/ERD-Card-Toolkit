unit ERD.Card.Contactless.Workflow.SDM;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Project, ERD.Card.Contactless.DESFire;
type
  /// <summary>Stored SDM template image, with explicit application/file identity and complete policy.</summary>
  TDesfireSdmSnapshot = record
    /// <summary>Nonzero native application identifier.</summary>
    Aid: Cardinal;
    /// <summary>Native standard-file number zero through thirty-one.</summary>
    FileNumber: Byte;
    /// <summary>Captured real UID, SDM/access settings and stored bytes; no credentials or mirrored sample.</summary>
    Template: TDesfireSdmStoredTemplate;
  end;
  /// <summary>Offline stored-template validation, archive and typed project adapter.</summary>
  TDesfireSdmArchive = class
  public
    /// <summary>Validates complete stored data, UID and canonical settings without I/O.</summary>
    /// <param name="ASnapshot">Bounded complete image, with independently owned buffers.</param>
    class procedure Validate(const ASnapshot: TDesfireSdmSnapshot); static;
    /// <summary>Encodes deterministic ASCII settings and stored data, excluding keys.</summary>
    /// <param name="ASnapshot">Complete validated stored-template capture.</param>
    /// <returns>Version-one archive; Plain file bytes are not asserted cryptographically authentic.</returns>
    class function Encode(const ASnapshot: TDesfireSdmSnapshot): string; static;
    /// <summary>Decodes strict canonical bounded ASCII data without contacting a reader.</summary>
    /// <param name="AText">At most three MiB of canonical archive text.</param>
    /// <returns>Independent stored image; target rights must still be checked live.</returns>
    class function Decode(const AText: string): TDesfireSdmSnapshot; static;
    /// <summary>Stores an independently encoded sdm-template.v1 artifact.</summary>
    /// <param name="AProject">Initialized project with its normal artifact budgets.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Complete stored template.</param>
    class procedure PutProject(const AProject: TCardProject; const AId: string; const ASnapshot: TDesfireSdmSnapshot); static;
    /// <summary>Checks schema and returns a validated stored template.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Existing template artifact.</param>
    /// <returns>Independent archive image.</returns>
    class function GetProject(const AProject: TCardProject; const AId: string): TDesfireSdmSnapshot; static;
  end;
  /// <summary>Explicit stored-template backend, with per-session identity and full live-preimage checks.</summary>
  IDesfireSdmWorkflowCard = interface
    ['{5AE7F490-692D-481F-97E2-CFB7C2C6C670}']
    /// <summary>Captures stored data and policy, with successful native session release.</summary>
    /// <param name="AAid">Explicit nonzero application.</param>
    /// <param name="AFile">Existing standard file.</param>
    /// <returns>Independent complete capture.</returns>
    function Capture(const AAid: Cardinal; const AFile: Byte): TDesfireSdmSnapshot;
    /// <summary>Writes against exact captured target evidence and verifies completion including release.</summary>
    /// <param name="AExpected">Live target preimage, UID and settings.</param>
    /// <param name="AData">Complete desired stored bytes; no policy/key changes inferred.</param>
    procedure WriteVerified(const AExpected: TDesfireSdmSnapshot; const AData: TBytes);
  end;
  /// <summary>Nonvisual backup, compare and restore workflow for stored SDM/multiple-right standard templates.</summary>
  TDesfireSdmTemplateWorkflow = class(TCardWorkflow)
  private
    FSource,FTarget: IDesfireSdmWorkflowCard;
    FSnapshot: TDesfireSdmSnapshot;
    FAid: Cardinal;
    FFile: Byte;
    FPrepared,FConsumed,FCompareOnly,FMatches,FVerified: Boolean;
    function GetSnapshot: TDesfireSdmSnapshot;
  protected
    /// <summary>Requires a prepared single-use explicit request.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Captures before mutation, checks complete policy and invokes verified target writing once.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares read-only stored-template acquisition without card I/O.</summary>
    /// <param name="ASource">Retained explicit backend.</param>
    /// <param name="AAid">Nonzero native application.</param>
    /// <param name="AFile">Existing standard file.</param>
    procedure PrepareBackup(const ASource: IDesfireSdmWorkflowCard; const AAid: Cardinal; const AFile: Byte);
    /// <summary>Prepares comparison or restore to a separately identified target, without copying credentials.</summary>
    /// <param name="ASnapshot">Copied complete source stored image.</param>
    /// <param name="ATarget">Retained target backend.</param>
    /// <param name="ATargetAid">Explicit target application.</param>
    /// <param name="ATargetFile">Explicit target standard file.</param>
    /// <param name="ACompareOnly">True prevents writes; full captured policy must match.</param>
    procedure PrepareRestore(const ASnapshot: TDesfireSdmSnapshot; const ATarget: IDesfireSdmWorkflowCard;
      const ATargetAid: Cardinal; const ATargetFile: Byte; const ACompareOnly: Boolean = False);
    /// <summary>Independent stored image; empty before successful capture.</summary>
    property Snapshot: TDesfireSdmSnapshot read GetSnapshot;
    /// <summary>True when the captured target initially matched the complete requested stored bytes.</summary>
    property Matches: Boolean read FMatches;
    /// <summary>True after verified write or same-content live no-op; does not assert Plain-data cryptographic authenticity.</summary>
    property Verified: Boolean read FVerified;
  end;
/// <summary>Copies an EV2 AES reader configuration into an inactive independent SDM workflow backend.</summary>
/// <param name="AReader">Explicit reader with maintained provider, credentials and Plain minimum.</param>
/// <returns>Owned adapter; stored operations verify UID in the same exclusive session and never change SDM policy.</returns>
function CreateDesfireSdmWorkflowCard(const AReader: TDesfireCardReader): IDesfireSdmWorkflowCard;
implementation
uses ERD.Card.Contactless.DESFire.EV2, ERD.Card.Crypto, ERD.Card.Contactless, ERD.Card.Contactless.DESFire.Extensions, ERD.Card.Project.Artifacts;
type
  TNative = class(TInterfacedObject, IDesfireSdmWorkflowCard)
    Reader: TDesfireCardReader;
    constructor Create(const Config: TDesfireCardReader);
    destructor Destroy; override;
    function Capture(const AAid: Cardinal; const AFile: Byte): TDesfireSdmSnapshot;
    procedure WriteVerified(const AExpected: TDesfireSdmSnapshot; const AData: TBytes);
  end;
procedure Invalid;
begin raise ECardWorkflowError.Create('Invalid stored SDM template or incompatible target policy.'); end;
class procedure TDesfireSdmArchive.Validate(const ASnapshot: TDesfireSdmSnapshot);
var Settings: TDesfireSdmAccessSettings;
begin
  if (ASnapshot.Aid<1) or (ASnapshot.Aid>$FFFFFF) or (ASnapshot.FileNumber>31) or
    (Length(ASnapshot.Template.Uid)<>7) or (Length(ASnapshot.Template.Data)<1) or
    (Length(ASnapshot.Template.Data)>DesfireMaxTransferBytes) then Invalid;
  Settings := TDesfireExtensionCodec.DecodeSdmAccessSettings(ASnapshot.Template.Settings.RawBytes);
  if (Settings.Sdm.FileBytes<>Length(ASnapshot.Template.Data)) or ((Settings.Sdm.FileOption and 3)<>0) or
    not BytesEqual(Settings.RawBytes,TDesfireExtensionCodec.EncodeSdmAccessSettings(ASnapshot.Template.Settings.Sdm,
      ASnapshot.Template.Settings.Rights)) then Invalid;
end;
class function TDesfireSdmArchive.Encode(const ASnapshot: TDesfireSdmSnapshot): string;
begin
  Validate(ASnapshot);
  Result := 'ERD-SDM 1'+#10+IntToStr(ASnapshot.Aid)+#10+IntToStr(ASnapshot.FileNumber)+#10+
    BytesToHex(ASnapshot.Template.Uid)+#10+BytesToHex(ASnapshot.Template.Settings.RawBytes)+#10+
    BytesToHex(ASnapshot.Template.Data)+#10;
end;
class function TDesfireSdmArchive.Decode(const AText: string): TDesfireSdmSnapshot;
var Lines: TStringList; I,J,N: Integer;
begin
  Result := Default(TDesfireSdmSnapshot);
  if (Length(AText)<1) or (Length(AText)>3*1024*1024) then Invalid;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count<>6) or (Lines[0]<>'ERD-SDM 1') then Invalid;
    if not TryStrToInt(Lines[1],N) or (N<1) or (N>$FFFFFF) then Invalid; Result.Aid := Cardinal(N);
    if not TryStrToInt(Lines[2],N) or (N<0) or (N>31) then Invalid; Result.FileNumber := Byte(N);
    for I := 3 to 5 do begin
      if Odd(Length(Lines[I])) then Invalid;
      for J := 1 to Length(Lines[I]) do if not CharInSet(Lines[I][J],['0'..'9','A'..'F']) then Invalid;
    end;
    Result.Template.Uid := HexToBytes(Lines[3]);
    Result.Template.Settings := TDesfireExtensionCodec.DecodeSdmAccessSettings(HexToBytes(Lines[4]));
    Result.Template.Data := HexToBytes(Lines[5]); Validate(Result);
    if Encode(Result)<>AText then Invalid;
  finally Lines.Free; end;
end;
class procedure TDesfireSdmArchive.PutProject(const AProject: TCardProject; const AId: string; const ASnapshot: TDesfireSdmSnapshot);
begin TCardProjectArtifacts.PutArchive(AProject,AId,'sdm-template.v1',Encode(ASnapshot)); end;
class function TDesfireSdmArchive.GetProject(const AProject: TCardProject; const AId: string): TDesfireSdmSnapshot;
begin Result := Decode(TCardProjectArtifacts.GetArchive(AProject,AId,'sdm-template.v1')); end;
constructor TNative.Create(const Config: TDesfireCardReader);
var Key: TBytes;
begin
  inherited Create;
  if (Config=nil) or Config.Busy or (Config.Security<>dfsEv2Aes) or (Config.MinimumCommunication<>dfcPlain) then Invalid;
  Reader := TDesfireCardReader.Create(nil); Reader.Transport := Config.Transport; Reader.Security := Config.Security;
  Reader.CryptoProvider := Config.CryptoProvider; Reader.KeyNumber := Config.KeyNumber;
  Reader.ReauthenticationKeyNumber := Config.ReauthenticationKeyNumber;
  Reader.MinimumCommunication := Config.MinimumCommunication; Reader.MaxTransferBytes := Config.MaxTransferBytes;
  Reader.MaxFrameDataBytes := Config.MaxFrameDataBytes;
  Key := Config.AuthenticationKey; try Reader.AuthenticationKey := Key; finally TCardCrypto.Clear(Key); end;
  Key := Config.ReauthenticationKey; try Reader.ReauthenticationKey := Key; finally TCardCrypto.Clear(Key); end;
end;
destructor TNative.Destroy;
begin Reader.Free; inherited Destroy; end;
function TNative.Capture(const AAid: Cardinal; const AFile: Byte): TDesfireSdmSnapshot;
var Session: IDesfireSdmTemplateManagement;
begin
  Result := Default(TDesfireSdmSnapshot); Result.Aid := AAid; Result.FileNumber := AFile;
  Session := Reader.OpenSdmTemplateManagementSession(AAid);
  try Result.Template := Session.ReadStoredTemplate(AFile); Session.Close;
  except TCardCrypto.Clear(Result.Template.Data); try Session.Close; except end; raise; end;
  TDesfireSdmArchive.Validate(Result);
end;
procedure TNative.WriteVerified(const AExpected: TDesfireSdmSnapshot; const AData: TBytes);
var Session: IDesfireSdmTemplateManagement; Dispatched: Boolean;
begin
  TDesfireSdmArchive.Validate(AExpected); Dispatched := False;
  Session := Reader.OpenSdmTemplateManagementSession(AExpected.Aid);
  try
    Session.WriteStoredTemplateVerified(AExpected.FileNumber,AExpected.Template,AData);
    Dispatched := not BytesEqual(AExpected.Template.Data,AData); Session.Close;
  except
    on E: Exception do begin
      try Session.Close; except end;
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise;
    end;
  end;
end;
function CreateDesfireSdmWorkflowCard(const AReader: TDesfireCardReader): IDesfireSdmWorkflowCard;
begin Result := TNative.Create(AReader); end;
function TDesfireSdmTemplateWorkflow.GetSnapshot: TDesfireSdmSnapshot;
begin
  Result := Default(TDesfireSdmSnapshot);
  if FSnapshot.Aid<>0 then Result := TDesfireSdmArchive.Decode(TDesfireSdmArchive.Encode(FSnapshot));
end;
procedure TDesfireSdmTemplateWorkflow.PrepareBackup(const ASource: IDesfireSdmWorkflowCard; const AAid: Cardinal; const AFile: Byte);
begin
  RequireIdle; FPrepared := False;
  if (ASource=nil) or (AAid<1) or (AAid>$FFFFFF) or (AFile>31) then Invalid;
  FSource := ASource; FTarget := nil; FAid := AAid; FFile := AFile;
  FSnapshot := Default(TDesfireSdmSnapshot); FConsumed := False; FMatches := False; FVerified := False; FPrepared := True;
end;
procedure TDesfireSdmTemplateWorkflow.PrepareRestore(const ASnapshot: TDesfireSdmSnapshot;
  const ATarget: IDesfireSdmWorkflowCard; const ATargetAid: Cardinal; const ATargetFile: Byte; const ACompareOnly: Boolean);
begin
  RequireIdle; FPrepared := False; TDesfireSdmArchive.Validate(ASnapshot);
  if (ATarget=nil) or (ATargetAid<1) or (ATargetAid>$FFFFFF) or (ATargetFile>31) then Invalid;
  FSnapshot := TDesfireSdmArchive.Decode(TDesfireSdmArchive.Encode(ASnapshot));
  FSource := nil; FTarget := ATarget; FAid := ATargetAid; FFile := ATargetFile; FCompareOnly := ACompareOnly;
  FConsumed := False; FMatches := False; FVerified := False; FPrepared := True;
end;
procedure TDesfireSdmTemplateWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
procedure TDesfireSdmTemplateWorkflow.DoExecute;
var Current: TDesfireSdmSnapshot; Role: TCardWorkflowRole;
begin
  FConsumed := True; Role := cwrTarget; if FSource<>nil then Role := cwrSource;
  if not RequestCard(Role) then begin Cancel; Exit; end;
  Progress(cwsReading,0,1); if CancelRequested then Exit;
  if FSource<>nil then begin
    Current := FSource.Capture(FAid,FFile); TDesfireSdmArchive.Validate(Current);
    if (Current.Aid<>FAid) or (Current.FileNumber<>FFile) then Invalid;
    FSnapshot := TDesfireSdmArchive.Decode(TDesfireSdmArchive.Encode(Current)); Progress(cwsReading,1,1); Exit;
  end;
  Current := FTarget.Capture(FAid,FFile); TDesfireSdmArchive.Validate(Current);
  if (Current.Aid<>FAid) or (Current.FileNumber<>FFile) or
    not BytesEqual(Current.Template.Settings.RawBytes,FSnapshot.Template.Settings.RawBytes) then Invalid;
  FMatches := BytesEqual(Current.Template.Data,FSnapshot.Template.Data);
  Progress(cwsChecking,1,1); if CancelRequested or FCompareOnly then Exit;
  if not FMatches then begin
    Progress(cwsWriting,0,1); if CancelRequested then Exit;
    MutationPending(True);
    try FTarget.WriteVerified(Current,FSnapshot.Template.Data);
    except
      on E: EContactlessWriteUncertain do raise;
      on E: Exception do begin MutationPending(False); raise; end;
    end;
    MutationPending(False); Progress(cwsVerifying,1,1);
  end;
  FVerified := True;
end;
end.
