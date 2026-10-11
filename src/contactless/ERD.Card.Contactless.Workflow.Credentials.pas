unit ERD.Card.Contactless.Workflow.Credentials;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.Classic.Access;

type
  /// <summary>Explicit credential/access migration for one Classic sector.</summary>
  TClassicSectorChange = record
    /// <summary>Physical sector trailer block.</summary>
    TrailerBlock: Integer;
    /// <summary>Current authenticating credential type.</summary>
    CurrentKeyType: TMifareClassicKeyType;
    /// <summary>Independent six-byte current key.</summary>
    CurrentKey: TBytes;
    /// <summary>Sixteen bytes containing supplied new keys, validated access bits and GPB.</summary>
    NewTrailer: TBytes;
  end;
  /// <summary>Ordered explicit sector changes; credentials are never inferred from masked reads.</summary>
  TClassicSectorChanges = array of TClassicSectorChange;
  /// <summary>Sector key/access migration workflow with fresh authentication and per-sector evidence.</summary>
  /// <remarks>Separate from data copy. Apply data first, then explicit sector changes. Reader must
  /// outlive the component. Changes can restrict future access permanently; no rollback or retries.</remarks>
  TClassicCredentialWorkflow = class(TCardWorkflow)
  private
    FReader: TContactlessCardReader;
    FModel: TMifareClassicModel;
    FChanges: TClassicSectorChanges;
    FResults: TCardWorkflowUnits;
    FPrepared, FConsumed: Boolean;
    procedure ClearCredentials;
    function GetResults: TCardWorkflowUnits;
  protected
    /// <summary>Checks request lifecycle before hardware I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Applies each explicit trailer mutation once, with new-key verification.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Overwrites retained credential buffers before destruction.</summary>
    destructor Destroy; override;
    /// <summary>Validates and independently copies explicit sector changes without I/O.</summary>
    /// <param name="AReader">Caller-owned configured reader.</param>
    /// <param name="AModel">Explicit Mini, 1K or 4K geometry.</param>
    /// <param name="AChanges">Nonempty unique trailer addresses with supplied current/new credentials.</param>
    procedure Prepare(const AReader: TContactlessCardReader;
      const AModel: TMifareClassicModel; const AChanges: TClassicSectorChanges);
    /// <summary>Independent address/state evidence only; no credential payloads.</summary>
    property Results: TCardWorkflowUnits read GetResults;
  end;

implementation

procedure TClassicCredentialWorkflow.ClearCredentials;
var I, J: Integer;
begin
  for I := 0 to High(FChanges) do
  begin
    for J := 0 to High(FChanges[I].CurrentKey) do FChanges[I].CurrentKey[J] := 0;
    for J := 0 to High(FChanges[I].NewTrailer) do FChanges[I].NewTrailer[J] := 0;
  end;
  FChanges := nil;
end;

destructor TClassicCredentialWorkflow.Destroy;
begin ClearCredentials; inherited Destroy; end;

function TClassicCredentialWorkflow.GetResults: TCardWorkflowUnits;
begin
  Result := Copy(FResults, 0, Length(FResults));
end;

procedure TClassicCredentialWorkflow.Prepare(const AReader: TContactlessCardReader;
  const AModel: TMifareClassicModel; const AChanges: TClassicSectorChanges);
var I, J: Integer; Conditions: TClassicAccessConditions;
begin
  RequireIdle;
  FPrepared := False;
  ClearCredentials;
  if (AReader = nil) or (Length(AChanges) < 1) or (Length(AChanges) > 40) then
    raise ECardWorkflowError.Create('Reader and sector changes required.');
  for I := 0 to High(AChanges) do
  begin
    if (AChanges[I].TrailerBlock < 0) or
      (AChanges[I].TrailerBlock >= TMifareClassicLayout.BlockCount(AModel)) or
      not TMifareClassicLayout.IsTrailer(AModel, AChanges[I].TrailerBlock) or
      (Length(AChanges[I].CurrentKey) <> 6) or (Length(AChanges[I].NewTrailer) <> 16) or
      not (AChanges[I].CurrentKeyType in [mckA, mckB]) then
      raise ECardWorkflowError.Create('Invalid sector change.');
    Conditions := TClassicAccessCodec.Decode(Copy(AChanges[I].NewTrailer, 6, 3));
    if Conditions[3] > 7 then raise ECardWorkflowError.Create('Invalid access condition.');
    for J := 0 to I - 1 do
      if AChanges[I].TrailerBlock = AChanges[J].TrailerBlock then
        raise ECardWorkflowError.Create('Duplicate sector change.');
  end;
  SetLength(FChanges, Length(AChanges));
  SetLength(FResults, Length(AChanges));
  for I := 0 to High(AChanges) do
  begin
    FChanges[I] := AChanges[I];
    FChanges[I].CurrentKey := CopyBytes(AChanges[I].CurrentKey);
    FChanges[I].NewTrailer := CopyBytes(AChanges[I].NewTrailer);
    FResults[I].Address := AChanges[I].TrailerBlock;
    FResults[I].Data := nil;
    FResults[I].State := cwusPending;
  end;
  FReader := AReader; FModel := AModel; FConsumed := False; FPrepared := True;
end;

procedure TClassicCredentialWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then raise ECardWorkflowError.Create('Prepare a new credential request.');
end;

procedure TClassicCredentialWorkflow.DoExecute;
var I: Integer; Uid: TBytes;
begin
  FConsumed := True;
  try
    if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Uid := FReader.ReadUid;
    for I := 0 to High(FChanges) do
    begin
      if CancelRequested then Exit;
      if not BytesEqual(FReader.ReadUid, Uid) then raise ECardWorkflowError.Create('Target changed.');
      Progress(cwsWriting, I, Length(FChanges));
      if CancelRequested then Exit;
      try
        FReader.WriteClassicSectorTrailer(FModel, FChanges[I].TrailerBlock,
          FChanges[I].CurrentKeyType, FChanges[I].CurrentKey, FChanges[I].NewTrailer);
      except
        on E: EContactlessWriteUncertain do
        begin FResults[I].State := cwusUncertain; MutationPending(True); raise; end;
      end;
      FResults[I].State := cwusVerified;
      Progress(cwsVerifying, I + 1, Length(FChanges));
    end;
  finally ClearCredentials; end;
end;

end.
