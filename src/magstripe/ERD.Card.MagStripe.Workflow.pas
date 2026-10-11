unit ERD.Card.MagStripe.Workflow;

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
  ERD.Card.Workflow, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks;

type
  /// <summary>Read, copy or template-program magstripe workflow with explicit evidence.</summary>
  /// <remarks>Reader components must outlive the workflow. OnCardRequired requests each swipe.
  /// Verified mode uses same-card device verification; status-only mode is explicit and never
  /// treats echoed data or a later arbitrary swipe as read-back. No automatic retry or payment.</remarks>
  TMagStripeCopyWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: TMagStripeReaderWriter;
    FTracks: TMagStripeTrackSet;
    FData: TMagStripeTracks;
    FCoercivity: TMagStripeCoercivity;
    FPrepared, FConsumed, FStatusOnly, FVerified: Boolean;
    FReceipt: TMagStripeProgrammingReceipt;
  protected
    /// <summary>Checks preparation and one-execution lifecycle.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Acquires optional source tracks, then writes once with explicit verification mode.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares track copy or a read-only backup without any I/O.</summary>
    /// <param name="ASource">Source stripe reader.</param>
    /// <param name="ATarget">Destination writer, or nil for a read-only backup.</param>
    /// <param name="ATracks">Nonempty physical track selection.</param>
    /// <param name="ACoercivity">Explicit destination coercivity.</param>
    /// <param name="AStatusOnly">True opts into status-only programming without read-back.</param>
    procedure PrepareCopy(const ASource, ATarget: TMagStripeReaderWriter;
      const ATracks: TMagStripeTrackSet; const ACoercivity: TMagStripeCoercivity = mscCurrent;
      const AStatusOnly: Boolean = False);
    /// <summary>Prepares a track template write without source acquisition.</summary>
    /// <param name="ATarget">Destination writer.</param>
    /// <param name="ATracks">Nonempty selected tracks; unselected data must be empty.</param>
    /// <param name="AData">Validated unframed track payloads.</param>
    /// <param name="ACoercivity">Explicit coercivity.</param>
    /// <param name="AStatusOnly">True permits device-status evidence only.</param>
    procedure PrepareWrite(const ATarget: TMagStripeReaderWriter;
      const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity = mscCurrent;
      const AStatusOnly: Boolean = False);
    /// <summary>Acquired source or supplied template payloads; contains potentially personal data.</summary>
    property Data: TMagStripeTracks read FData;
    /// <summary>True only after successful same-card verified writing.</summary>
    property ReadBackVerified: Boolean read FVerified;
    /// <summary>Device-status receipt for explicitly selected status-only programming.</summary>
    property Receipt: TMagStripeProgrammingReceipt read FReceipt;
  end;

implementation

procedure TMagStripeCopyWorkflow.PrepareCopy(const ASource, ATarget: TMagStripeReaderWriter;
  const ATracks: TMagStripeTrackSet; const ACoercivity: TMagStripeCoercivity;
  const AStatusOnly: Boolean);
var T: TMagStripeTrack; Cap: TMagStripeCapabilities;
begin
  RequireIdle;
  FPrepared := False;
  if (ASource = nil) or (ASource.Device = nil) or (ATracks = []) then
    raise ECardWorkflowError.Create('Source device and tracks required.');
  Cap := ASource.Device.GetCapabilities;
  if not (ATracks <= Cap.ReadTracks) then
    raise ECardWorkflowError.Create('Source tracks unsupported.');
  FSource := ASource;
  FTarget := ATarget;
  FTracks := ATracks;
  FCoercivity := ACoercivity;
  FStatusOnly := AStatusOnly;
  FConsumed := False;
  FVerified := False;
  FReceipt.RequestedTracks := [];
  FReceipt.RequestedCoercivity := mscCurrent;
  FReceipt.DeviceStatus := 0;
  FReceipt.HostReadBackVerified := False;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do FData[T] := '';
  FPrepared := True;
end;

procedure TMagStripeCopyWorkflow.PrepareWrite(const ATarget: TMagStripeReaderWriter;
  const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const AStatusOnly: Boolean);
var T: TMagStripeTrack;
begin
  RequireIdle;
  FPrepared := False;
  if (ATarget = nil) or (ATracks = []) then
    raise ECardWorkflowError.Create('Target and tracks required.');
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if T in ATracks then
    begin
      if AData[T] = '' then raise ECardWorkflowError.Create('Selected payload is empty.');
      TMagStripeTrackCodec.ValidatePayload(T, AData[T]);
    end
    else if AData[T] <> '' then raise ECardWorkflowError.Create('Unselected payload present.');
  FSource := nil;
  FTarget := ATarget;
  FTracks := ATracks;
  FData := AData;
  FCoercivity := ACoercivity;
  FStatusOnly := AStatusOnly;
  FConsumed := False;
  FVerified := False;
  FReceipt.RequestedTracks := [];
  FReceipt.RequestedCoercivity := mscCurrent;
  FReceipt.DeviceStatus := 0;
  FReceipt.HostReadBackVerified := False;
  FPrepared := True;
end;

procedure TMagStripeCopyWorkflow.ValidatePrepared;
var Cap: TMagStripeCapabilities; Status: IMagStripeStatusWriter;
  StatusCap: TMagStripeStatusWriteCapabilities;
  Track: TMagStripeTrack; Mask: Integer;
begin
  if not FPrepared or FConsumed then raise ECardWorkflowError.Create('Prepare a new stripe request.');
  if FTarget = nil then Exit;
  if FTarget.Device = nil then raise ECardWorkflowError.Create('Target device required.');
  if FStatusOnly then
  begin
    if not Supports(FTarget.Device, IMagStripeStatusWriter, Status) then
      raise ECardWorkflowError.Create('Status-only backend unavailable.');
    StatusCap := Status.GetStatusWriteCapabilities;
    if not (FCoercivity in StatusCap.Coercivities) then
      raise ECardWorkflowError.Create('Coercivity unsupported.');
    Mask := 0;
    for Track := Low(TMagStripeTrack) to High(TMagStripeTrack) do
      if Track in FTracks then Mask := Mask or (1 shl Ord(Track));
    if not(TMagStripeWriteSelection(Mask - 1) in StatusCap.Selections) then
      raise ECardWorkflowError.Create('Track combination unsupported.');
  end
  else
  begin
    Cap := FTarget.Device.GetCapabilities;
    if not Cap.VerifiedWrite or not (FTracks <= Cap.WriteTracks) or
      not (FCoercivity in Cap.Coercivities) then
      raise ECardWorkflowError.Create('Verified target writing unsupported.');
  end;
end;

procedure TMagStripeCopyWorkflow.DoExecute;
var Verified: TMagStripeTracks;
begin
  FConsumed := True;
  if FSource <> nil then
  begin
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, 1);
    if CancelRequested then Exit;
    FData := FSource.ReadTracks(FTracks);
    Progress(cwsReading, 1, 1);
  end;
  if FTarget = nil then Exit;
  if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
  Progress(cwsWriting, 0, 1);
  if CancelRequested then Exit;
  try
    if FStatusOnly then FReceipt := FTarget.ProgramTracks(FTracks, FData, FCoercivity)
    else
    begin
      Verified := FTarget.WriteTracks(FTracks, FData, FCoercivity);
      FVerified := True;
      FData := Verified;
    end;
  except
    on E: EMagStripeWriteUncertain do
    begin
      MutationPending(True);
      raise;
    end;
  end;
  if FVerified then Progress(cwsVerifying, 1, 1)
  else Progress(cwsChecking, 1, 1);
end;

end.
