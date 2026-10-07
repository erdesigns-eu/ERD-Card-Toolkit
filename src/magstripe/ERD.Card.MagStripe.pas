unit ERD.Card.MagStripe;

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
  ERD.Card.MagStripe.Tracks;

type
  /// <summary>Invalid reader configuration, unsupported operation or failed device operation.</summary>
  EMagStripeError = class(Exception);
  /// <summary>A dispatched write could have changed the stripe; never retry it automatically.</summary>
  EMagStripeWriteUncertain = class(EMagStripeError);
  /// <summary>Explicit write coercivity; the component never probes or guesses card media.</summary>
  TMagStripeCoercivity = (
    /// <summary>Use the device's current setting without a coercivity change.</summary>
    mscCurrent,
    /// <summary>Explicit low-coercivity setting supported by the backend.</summary>
    mscLow,
    /// <summary>Explicit high-coercivity setting supported by the backend.</summary>
    mscHigh
  );
  /// <summary>Supported explicit coercivity modes.</summary>
  TMagStripeCoercivitySet = set of TMagStripeCoercivity;
  /// <summary>Backend operation guarantees, queried without I/O.</summary>
  TMagStripeCapabilities = record
    /// <summary>Tracks the device can read, independently of a given card's contents.</summary>
    ReadTracks: TMagStripeTrackSet;
    /// <summary>Tracks the backend can write without modifying unselected tracks.</summary>
    WriteTracks: TMagStripeTrackSet;
    /// <summary>Supported explicit write coercivity modes.</summary>
    Coercivities: TMagStripeCoercivitySet;
    /// <summary>Write returns read-back from the same programmed card after device verification.</summary>
    VerifiedWrite: Boolean;
  end;
  /// <summary>Exclusive synchronous magstripe device session with bounded operations.</summary>
  /// <remarks>Implementations own connection, buffers, deadlines and cancellation cleanup.
  /// Acquire grants one non-nested caller-thread session; failure grants nothing.
  /// Release relinquishes it even when reporting a cleanup error. Never replay writes.
  /// No DLL ABI or cross-device capability is implied by implementing this contract.</remarks>
  IMagStripeDevice = interface
    ['{B973EDFC-2684-467B-B2D6-9FB580344B59}']
    /// <summary>Returns configured backend guarantees without opening hardware.</summary>
    /// <returns>Capabilities that stay stable for an acquired session.</returns>
    function GetCapabilities: TMagStripeCapabilities;
    /// <summary>Acquires exclusive caller-thread access; failure does not grant ownership.</summary>
    procedure Acquire;
    /// <summary>Ends acquired access, including outstanding receive/write cancellation cleanup.</summary>
    procedure Release;
    /// <summary>Receives one swipe within the deadline, without automatically retrying errors.</summary>
    /// <param name="ATracks">Requested tracks; return unselected tracks as empty strings.</param>
    /// <param name="ATimeoutMs">Total operation deadline in milliseconds, including swipe wait.</param>
    /// <returns>Unframed validated payloads; absent tracks are empty, decode errors must raise.</returns>
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    /// <summary>Writes only selected tracks once and returns same-card device-verified read-back.</summary>
    /// <param name="ATracks">Nonempty selected tracks; every selected payload must be nonempty.</param>
    /// <param name="AData">Unframed payloads; unselected entries are empty.</param>
    /// <param name="ACoercivity">Explicit supported mode; not inferred from data.</param>
    /// <param name="ATimeoutMs">Total deadline including waiting, programming and device verification.</param>
    /// <returns>Verified unframed read-back for selected tracks; others empty.</returns>
    /// <remarks>Do not substitute a later arbitrary swipe as verification. Timeout, cancellation,
    /// device errors or uncertain verification must raise and cancel pending work before release.</remarks>
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
  end;
  /// <summary>Non-visual reader/writer component with validation and mandatory exclusive sessions.</summary>
  /// <remarks>No I/O in constructor. Use one caller thread without concurrent or reentrant calls.
  /// Writes require selected-track preservation and same-card verification from the backend.
  /// All errors after dispatch, including release failure, are uncertain; no replay or rollback.</remarks>
  TMagStripeReaderWriter = class(TComponent)
  private
    FDevice: IMagStripeDevice;
    FTimeoutMs: Cardinal;
    FBusy: Boolean;
    procedure SetDevice(const ADevice: IMagStripeDevice);
    procedure SetTimeoutMs(const ATimeoutMs: Cardinal);
    function BeginOperation(const ATracks: TMagStripeTrackSet;
      const AWrite: Boolean; const ACoercivity: TMagStripeCoercivity): IMagStripeDevice;
    procedure EndOperation(const ADevice: IMagStripeDevice; const ASucceeded: Boolean);
    procedure ValidateData(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const AWriting: Boolean);
  public
    /// <summary>Creates an inactive component with a ten-second operation timeout.</summary>
    /// <param name="AOwner">Optional component owner; retains usual TComponent ownership.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Receives one swipe using the explicitly selected backend tracks.</summary>
    /// <param name="ATracks">Nonempty supported track set; no automatic alternate-reader fallback.</param>
    /// <returns>Validated payloads after successful release; empty entries mean absent tracks.</returns>
    /// <exception cref="EMagStripeError">Configuration, capabilities or operation lifecycle is invalid.</exception>
    /// <exception cref="EMagStripeFormatError">Returned payload is invalid.</exception>
    function ReadTracks(const ATracks: TMagStripeTrackSet): TMagStripeTracks;
    /// <summary>Programs selected tracks once and checks same-card verified read-back.</summary>
    /// <param name="ATracks">Nonempty supported selection; unselected tracks must remain unchanged.</param>
    /// <param name="AData">Nonempty selected payloads; unselected entries must be empty.</param>
    /// <param name="ACoercivity">Explicit supported mode; defaults to current device setting.</param>
    /// <returns>Verified selected payloads only after successful session release.</returns>
    /// <exception cref="EMagStripeError">Preflight or acquisition fails before dispatch.</exception>
    /// <exception cref="EMagStripeFormatError">Input track payload is invalid before dispatch.</exception>
    /// <exception cref="EMagStripeWriteUncertain">Dispatch, verification or release failed; media may have changed.</exception>
    function WriteTracks(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity = mscCurrent): TMagStripeTracks;
    /// <summary>Retained backend interface; assigning never opens a connection and is refused while busy.</summary>
    property Device: IMagStripeDevice read FDevice write SetDevice;
    /// <summary>Read-only same-thread operation flag, not a cross-thread synchronization primitive.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Total per-operation deadline, 1..600000 milliseconds; cannot change while busy.</summary>
    property TimeoutMs: Cardinal read FTimeoutMs write SetTimeoutMs default 10000;
  end;

implementation

constructor TMagStripeReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimeoutMs := 10000;
end;

procedure TMagStripeReaderWriter.SetDevice(const ADevice: IMagStripeDevice);
begin
  if FBusy then raise EMagStripeError.Create('Magstripe component is busy.');
  FDevice := ADevice;
end;

procedure TMagStripeReaderWriter.SetTimeoutMs(const ATimeoutMs: Cardinal);
begin
  if FBusy then raise EMagStripeError.Create('Magstripe component is busy.');
  if (ATimeoutMs < 1) or (ATimeoutMs > 600000) then
    raise EMagStripeError.Create('Invalid magstripe operation timeout.');
  FTimeoutMs := ATimeoutMs;
end;

procedure TMagStripeReaderWriter.ValidateData(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const AWriting: Boolean);
var
  T: TMagStripeTrack;
begin
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if T in ATracks then
    begin
      TMagStripeTrackCodec.ValidatePayload(T, AData[T]);
      if AWriting and (AData[T] = '') then
        raise EMagStripeError.Create('Empty selected writes require a separate erase operation.');
    end
    else if AData[T] <> '' then
      raise EMagStripeError.Create('Unselected magnetic stripe data is not allowed.');
end;

function TMagStripeReaderWriter.BeginOperation(const ATracks: TMagStripeTrackSet;
  const AWrite: Boolean; const ACoercivity: TMagStripeCoercivity): IMagStripeDevice;
var
  Caps: TMagStripeCapabilities;
begin
  if FBusy then raise EMagStripeError.Create('Magstripe component is busy.');
  if (ATracks = []) or (FDevice = nil) then
    raise EMagStripeError.Create('Magstripe device and tracks must be configured.');
  if (FTimeoutMs < 1) or (FTimeoutMs > 600000) then
    raise EMagStripeError.Create('Invalid magstripe operation timeout.');
  Result := FDevice;
  FBusy := True;
  try
    Caps := Result.GetCapabilities;
    if AWrite then
    begin
      if (Ord(ACoercivity) < Ord(Low(TMagStripeCoercivity))) or
        (Ord(ACoercivity) > Ord(High(TMagStripeCoercivity))) then
        raise EMagStripeError.Create('Invalid magstripe coercivity.');
      if not Caps.VerifiedWrite or not (ATracks <= Caps.WriteTracks) or
        not (ACoercivity in Caps.Coercivities) then
        raise EMagStripeError.Create('Verified selected-track writing is not supported.');
    end
    else if not (ATracks <= Caps.ReadTracks) then
      raise EMagStripeError.Create('Selected-track reading is not supported.');
    Result.Acquire;
  except
    FBusy := False;
    raise;
  end;
end;

procedure TMagStripeReaderWriter.EndOperation(const ADevice: IMagStripeDevice;
  const ASucceeded: Boolean);
begin
  try
    if ASucceeded then ADevice.Release
    else
      try ADevice.Release; except { Preserve the primary operation failure. } end;
  finally
    FBusy := False;
  end;
end;

function TMagStripeReaderWriter.ReadTracks(const ATracks: TMagStripeTrackSet): TMagStripeTracks;
var
  Session: IMagStripeDevice;
  Succeeded: Boolean;
begin
  Session := BeginOperation(ATracks, False, mscCurrent);
  Succeeded := False;
  try
    Result := Session.Read(ATracks, FTimeoutMs);
    ValidateData(ATracks, Result, False);
    Succeeded := True;
  finally
    EndOperation(Session, Succeeded);
  end;
end;

function TMagStripeReaderWriter.WriteTracks(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity): TMagStripeTracks;
var
  Session: IMagStripeDevice;
  Succeeded: Boolean;
  T: TMagStripeTrack;
begin
  if FBusy then raise EMagStripeError.Create('Magstripe component is busy.');
  ValidateData(ATracks, AData, True);
  Session := BeginOperation(ATracks, True, ACoercivity);
  Succeeded := False;
  try
    try
      try
        Result := Session.Write(ATracks, AData, ACoercivity, FTimeoutMs);
        ValidateData(ATracks, Result, True);
        for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
          if (T in ATracks) and (Result[T] <> AData[T]) then
            raise EMagStripeError.Create('Magstripe write read-back does not match.');
        Succeeded := True;
      finally
        EndOperation(Session, Succeeded);
      end;
    except
      on E: Exception do
        raise EMagStripeWriteUncertain.Create('Magstripe write completion is uncertain (' + E.ClassName + ').');
    end;
  finally
    Session := nil;
  end;
end;

end.
