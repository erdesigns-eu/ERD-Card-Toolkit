unit ERD.Card.Contactless.Workflow.UID;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.UID,
  ERD.Card.Contactless.UID.Profiles, ERD.Card.Contactless.UID.USCUID,
  ERD.Card.Contactless.UID.Partial;

type
  /// <summary>Explicit programmable UID protocol; never inferred from the observed UID.</summary>
  TUidWorkflowProfile = (
    /// <summary>Authenticated Gen2/CUID manufacturer block.</summary>
    uwpGen2,
    /// <summary>Authenticated factory FUID one-time programming.</summary>
    uwpFuid,
    /// <summary>Raw Classic Gen1a, Gen1b or unsealed UFUID.</summary>
    uwpRawClassic,
    /// <summary>Raw seven-byte Type 2 DirectWrite.</summary>
    uwpType2Direct,
    /// <summary>Raw Gen3 independent UID register.</summary>
    uwpGen3,
    /// <summary>Raw Gen4 UMC configured UID source.</summary>
    uwpGen4,
    /// <summary>Raw full USCUID/GDM.</summary>
    uwpUscuid,
    /// <summary>Raw documented partial UFUID/ZUID/PFUID.</summary>
    uwpPartial);
  /// <summary>Profile-specific UID request; only fields relevant to Profile are used.</summary>
  TUidWorkflowOptions = record
    /// <summary>Explicit card protocol.</summary>
    Profile: TUidWorkflowProfile;
    /// <summary>Gen2 existing four/seven-byte layout.</summary>
    Gen2Model: TClassicGen2UidModel;
    /// <summary>Current sector-zero credential type for Gen2/FUID.</summary>
    KeyType: TMifareClassicKeyType;
    /// <summary>Independent supplied six-byte credential for Gen2/FUID.</summary>
    Key: TBytes;
    /// <summary>Gen1a/Gen1b/unsealed UFUID wakeup dialect.</summary>
    RawClassicProfile: TClassicRawUidProfile;
    /// <summary>Gen3 existing UID register width.</summary>
    Gen3Size: TGen3UidSize;
    /// <summary>Gen4 already configured UID layout.</summary>
    Gen4Layout: TGen4UidLayout;
    /// <summary>Independent supplied four-byte Gen4 password.</summary>
    Password: TBytes;
    /// <summary>Full USCUID/GDM configured wakeup dialect.</summary>
    UscuidWakeup: TUscuidWakeupStyle;
    /// <summary>Full USCUID configured public or hidden UID source.</summary>
    UscuidLayout: TUscuidUidLayout;
    /// <summary>Explicit documented partial configuration.</summary>
    PartialProfile: TPartialUscuidProfile;
  end;
  /// <summary>UID copy or explicit programming with profile-aware evidence and no replay.</summary>
  /// <remarks>Readers must outlive this workflow. SourceReader is optional: nil uses the explicit
  /// UID passed to Prepare. OnCardRequired supports source/target swaps. Gen2/FUID may return
  /// NeedsVerification when PC/SC caches the old UID; the application must reactivate the RF
  /// field and independently verify it. Source memory and access credentials are not copied.</remarks>
  TUidProgrammingWorkflow = class(TCardWorkflow)
  private
    FReader, FSource: TContactlessCardReader;
    FRaw: TRawUidProgrammer;
    FOptions: TUidWorkflowOptions;
    FRequested, FPrevious: TBytes;
    FPrepared, FConsumed, FActiveVerified: Boolean;
    procedure ClearCredentials;
    function GetRequested: TBytes;
    function GetPrevious: TBytes;
    procedure ValidateUid(const AUid: TBytes);
  protected
    /// <summary>Checks preparation and one-execution lifecycle.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Reads optional source and invokes the selected programmer once.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Overwrites retained credential buffers before releasing the workflow.</summary>
    destructor Destroy; override;
    /// <summary>Prepares explicit UID programming or source-card UID copy without I/O.</summary>
    /// <param name="AReader">Target PC/SC reader for Gen2/FUID; nil for raw profiles.</param>
    /// <param name="ARaw">Target raw programmer for raw profiles; nil for Gen2/FUID.</param>
    /// <param name="AOptions">Exact profile and supplied credentials, copied independently.</param>
    /// <param name="ANewUid">Target UID; ignored when ASourceReader is supplied.</param>
    /// <param name="ASourceReader">Optional source UID reader; nil means explicit programming.</param>
    procedure Prepare(const AReader: TContactlessCardReader; const ARaw: TRawUidProgrammer;
      const AOptions: TUidWorkflowOptions; const ANewUid: TBytes;
      const ASourceReader: TContactlessCardReader = nil);
    /// <summary>Independent requested UID, including a source UID acquired during execution.</summary>
    property RequestedUid: TBytes read GetRequested;
    /// <summary>Independent target UID observed by the selected programmer before mutation.</summary>
    property PreviousUid: TBytes read GetPrevious;
    /// <summary>True only when the programmer established the active requested UID.</summary>
    property ActiveUidVerified: Boolean read FActiveVerified;
  end;

implementation

procedure TUidProgrammingWorkflow.ClearCredentials;
var I: Integer;
begin
  for I := 0 to High(FOptions.Key) do FOptions.Key[I] := 0;
  for I := 0 to High(FOptions.Password) do FOptions.Password[I] := 0;
  FOptions.Key := nil;
  FOptions.Password := nil;
end;

destructor TUidProgrammingWorkflow.Destroy;
begin
  ClearCredentials;
  inherited Destroy;
end;

function TUidProgrammingWorkflow.GetRequested: TBytes;
begin
  Result := CopyBytes(FRequested);
end;

function TUidProgrammingWorkflow.GetPrevious: TBytes;
begin
  Result := CopyBytes(FPrevious);
end;

procedure TUidProgrammingWorkflow.ValidateUid(const AUid: TBytes);
var Size: Integer;
begin
  case FOptions.Profile of
    uwpGen2: Size := TProgrammableUidCodec.UidLength(FOptions.Gen2Model);
    uwpFuid, uwpRawClassic, uwpPartial: Size := 4;
    uwpType2Direct: Size := 7;
    uwpGen3: Size := TGen3UidCodec.UidLength(FOptions.Gen3Size);
    uwpGen4: Size := TGen4UidCodec.UidLength(FOptions.Gen4Layout);
    uwpUscuid: Size := TUscuidUidCodec.UidLength(FOptions.UscuidLayout);
  else
    raise ECardWorkflowError.Create('Invalid UID profile.');
  end;
  if Length(AUid) <> Size then raise ECardWorkflowError.Create('UID width does not match profile.');
  if Size = 4 then TProgrammableUidCodec.ValidateUid(cgum4Byte, AUid)
  else if Size = 7 then TProgrammableUidCodec.ValidateUid(cgum7Byte, AUid)
  else if FOptions.Profile = uwpGen4 then TGen4UidCodec.ValidateUid(FOptions.Gen4Layout, AUid)
  else raise ECardWorkflowError.Create('Invalid UID width.');
end;

procedure TUidProgrammingWorkflow.Prepare(const AReader: TContactlessCardReader;
  const ARaw: TRawUidProgrammer; const AOptions: TUidWorkflowOptions;
  const ANewUid: TBytes; const ASourceReader: TContactlessCardReader);
begin
  RequireIdle;
  FPrepared := False;
  ClearCredentials;
  FOptions := AOptions;
  FOptions.Key := CopyBytes(AOptions.Key);
  FOptions.Password := CopyBytes(AOptions.Password);
  try
    if not(FOptions.Profile in [uwpGen2 .. uwpPartial]) then
      raise ECardWorkflowError.Create('Invalid UID profile.');
    case FOptions.Profile of
      uwpGen2: TProgrammableUidCodec.UidLength(FOptions.Gen2Model);
      uwpRawClassic: if not(FOptions.RawClassicProfile in [crupGen1a .. crupGen1b]) then
        raise ECardWorkflowError.Create('Invalid raw Classic profile.');
      uwpGen3: TGen3UidCodec.UidLength(FOptions.Gen3Size);
      uwpGen4: TGen4UidCodec.UidLength(FOptions.Gen4Layout);
      uwpUscuid:
        begin
          TUscuidUidCodec.UidLength(FOptions.UscuidLayout);
          if not(FOptions.UscuidWakeup in [uwsGen1a, uwsGdm]) then
            raise ECardWorkflowError.Create('Invalid USCUID wakeup.');
        end;
      uwpPartial: if not(FOptions.PartialProfile in [pupUnsealedUfuid .. pupPfuid]) then
        raise ECardWorkflowError.Create('Invalid partial UID profile.');
    end;
    if FOptions.Profile in [uwpGen2, uwpFuid] then
    begin
      if (AReader = nil) or (Length(FOptions.Key) <> 6) or
        not(FOptions.KeyType in [mckA, mckB]) then
        raise ECardWorkflowError.Create('Target reader and sector-zero key required.');
    end
    else if ARaw = nil then raise ECardWorkflowError.Create('Raw programmer required.');
    if (FOptions.Profile = uwpGen4) and (Length(FOptions.Password) <> 4) then
      raise ECardWorkflowError.Create('Gen4 password required.');
    if ASourceReader = nil then ValidateUid(ANewUid);
    if ASourceReader = nil then FRequested := CopyBytes(ANewUid) else FRequested := nil;
    FPrevious := nil;
    FReader := AReader;
    FRaw := ARaw;
    FSource := ASourceReader;
    FActiveVerified := False;
    FConsumed := False;
    FPrepared := True;
  except
    ClearCredentials;
    raise;
  end;
end;

procedure TUidProgrammingWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then
    raise ECardWorkflowError.Create('Prepare a new UID request.');
end;

procedure TUidProgrammingWorkflow.DoExecute;
var
  Classic: TProgrammableUidResult;
  Fuid: TFuidUidResult;
  Type2: TType2UidResult;
  Gen3: TGen3UidResult;
  Gen4: TGen4UidResult;
  Uscuid: TUscuidUidResult;
  Partial: TPartialUscuidUidResult;
begin
  FConsumed := True;
  try
    if FSource <> nil then
    begin
      if not RequestCard(cwrSource) then begin Cancel; Exit; end;
      Progress(cwsReading, 0, 1);
      if CancelRequested then Exit;
      FRequested := CopyBytes(FSource.ReadUid);
      ValidateUid(FRequested);
      Progress(cwsReading, 1, 1);
    end;
    if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Progress(cwsWriting, 0, 1);
    if CancelRequested then Exit;
    try
      case FOptions.Profile of
        uwpGen2:
          begin
            Classic := FReader.ProgramClassicGen2Uid(FOptions.Gen2Model, FRequested,
              FOptions.KeyType, FOptions.Key);
            FPrevious := Classic.PreviousUid;
            FActiveVerified := Classic.ActiveUidVerified;
          end;
        uwpFuid:
          begin
            Fuid := FReader.ProgramFuidUidOnce(FRequested, FOptions.KeyType, FOptions.Key);
            FPrevious := Fuid.PreviousUid;
            FActiveVerified := Fuid.ActiveUidVerified;
          end;
        uwpRawClassic:
          begin
            Classic := FRaw.ProgramClassicUid(FOptions.RawClassicProfile, FRequested);
            FPrevious := Classic.PreviousUid;
            FActiveVerified := Classic.ActiveUidVerified;
          end;
        uwpType2Direct:
          begin
            Type2 := FRaw.ProgramType2DirectWriteUid(FRequested);
            FPrevious := Type2.PreviousUid;
            FActiveVerified := Type2.ActiveUidVerified;
          end;
        uwpGen3:
          begin
            Gen3 := FRaw.ProgramGen3Uid(FOptions.Gen3Size, FRequested);
            FPrevious := Gen3.PreviousUid;
            FActiveVerified := Gen3.ActiveUidVerified;
          end;
        uwpGen4:
          begin
            Gen4 := FRaw.ProgramGen4Uid(FOptions.Gen4Layout, FRequested, FOptions.Password);
            FPrevious := Gen4.PreviousUid;
            FActiveVerified := Gen4.ActiveUidVerified;
          end;
        uwpUscuid:
          begin
            Uscuid := FRaw.ProgramUscuidUid(FOptions.UscuidWakeup, FOptions.UscuidLayout, FRequested);
            FPrevious := Uscuid.PreviousUid;
            FActiveVerified := Uscuid.ActiveUidVerified;
          end;
        uwpPartial:
          begin
            Partial := FRaw.ProgramPartialUscuidUid(FOptions.PartialProfile, FRequested);
            FPrevious := Partial.PreviousUid;
            FActiveVerified := Partial.ActiveUidVerified;
          end;
      end;
    except
      on E: EContactlessWriteUncertain do
      begin
        MutationPending(True);
        raise;
      end;
    end;
    if FActiveVerified then Progress(cwsVerifying, 1, 1)
    else Progress(cwsNeedsVerification, 1, 1);
  finally
    ClearCredentials;
  end;
end;

end.
