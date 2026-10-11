unit ERD.Card.Workflow;

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
  ERD.Card.Bytes;

type
  /// <summary>Invalid workflow configuration or incompatible snapshot.</summary>
  ECardWorkflowError = class(Exception)
  end;
  /// <summary>Backend evidence that the requested data mutation was never dispatched.</summary>
  /// <remarks>Only raise when no memory programming was sent; authentication may still affect card state.</remarks>
  ECardWorkflowWriteRefused = class(ECardWorkflowError)
  end;
  /// <summary>Observable operation phase; completion is separate from uncertain mutation.</summary>
  TCardWorkflowState = (
    /// <summary>No operation has run.</summary>
    cwsIdle,
    /// <summary>Acquiring source data.</summary>
    cwsReading,
    /// <summary>Checking target and constructing the plan.</summary>
    cwsChecking,
    /// <summary>Dispatching one mutation.</summary>
    cwsWriting,
    /// <summary>Acquiring independent evidence after a mutation.</summary>
    cwsVerifying,
    /// <summary>All requested steps completed with their stated evidence.</summary>
    cwsCompleted,
    /// <summary>Stopped between steps; previous verified writes remain.</summary>
    cwsCancelled,
    /// <summary>A failure occurred without an outstanding uncertain write.</summary>
    cwsFailed,
    /// <summary>A mutation may have occurred and requires inspection.</summary>
    cwsUncertain,
    /// <summary>Programming succeeded but fresh active UID evidence is still required.</summary>
    cwsNeedsVerification);
  /// <summary>Card role requested from an application, including single-reader card swaps.</summary>
  TCardWorkflowRole = (
    /// <summary>Original card to acquire.</summary>
    cwrSource,
    /// <summary>Destination card to inspect or modify.</summary>
    cwrTarget);
  /// <summary>Observer called synchronously on the executing thread.</summary>
  /// <param name="Sender">Workflow emitting progress.</param>
  /// <param name="AState">Current phase.</param>
  /// <param name="ADone">Completed steps in this phase.</param>
  /// <param name="ATotal">Requested steps in this phase.</param>
  TCardWorkflowProgressEvent = procedure(Sender: TObject;
    const AState: TCardWorkflowState; const ADone, ATotal: Integer) of object;
  /// <summary>Application hook for selecting or presenting the required card.</summary>
  /// <param name="Sender">Requesting workflow.</param>
  /// <param name="ARole">Source or destination.</param>
  /// <param name="AReady">Set false to cancel before card I/O; initially true.</param>
  TCardWorkflowCardEvent = procedure(Sender: TObject;
    const ARole: TCardWorkflowRole; var AReady: Boolean) of object;
  /// <summary>Nonvisual synchronous workflow with bounded cancellation and observer isolation.</summary>
  /// <remarks>Execute on one thread; events run on that thread, with no VCL marshaling.
  /// Never destroy the workflow in a callback. Cancel is same-thread and takes effect between
  /// operations; an in-flight mutation and its verification are completed first. Execute never
  /// retries writes. Observer exceptions are recorded by class name and cannot replay a write.</remarks>
  TCardWorkflow = class abstract(TComponent)
  private
    FBusy, FCancel, FUncertain: Boolean;
    FState: TCardWorkflowState;
    FErrorClass, FObserverErrorClass: string;
    FOnProgress: TCardWorkflowProgressEvent;
    FOnCardRequired: TCardWorkflowCardEvent;
    FOnCompleted, FOnError, FOnStageChanged: TNotifyEvent;
    procedure Notify(const AEvent: TNotifyEvent);
  protected
    /// <summary>Rejects configuration changes during execution.</summary>
    procedure RequireIdle;
    /// <summary>Checks the prepared request before any callbacks or I/O.</summary>
    procedure ValidatePrepared; virtual; abstract;
    /// <summary>Executes one prepared request without retries.</summary>
    procedure DoExecute; virtual; abstract;
    /// <summary>Publishes phase progress while isolating observer failures.</summary>
    /// <param name="AState">New phase.</param>
    /// <param name="ADone">Completed phase steps.</param>
    /// <param name="ATotal">Total phase steps.</param>
    procedure Progress(const AState: TCardWorkflowState;
      const ADone, ATotal: Integer);
    /// <summary>Requests a card and checks cancellation before I/O.</summary>
    /// <param name="ARole">Required source or target.</param>
    /// <returns>True when the application is ready and has not cancelled.</returns>
    function RequestCard(const ARole: TCardWorkflowRole): Boolean;
    /// <summary>Records whether a dispatched mutation still lacks completion evidence.</summary>
    /// <param name="AValue">True before dispatch, false only after verification.</param>
    procedure MutationPending(const AValue: Boolean);
    /// <summary>Same-thread cancellation flag for use between atomic steps.</summary>
    property CancelRequested: Boolean read FCancel;
  public
    /// <summary>Validates and executes once; operational failures become State and ErrorClass.</summary>
    /// <returns>Terminal outcome; failed or uncertain operations are never automatically retried.</returns>
    /// <remarks>Invalid prepared configuration and reentrancy raise before execution. Calling
    /// Execute again on a finished request is refused; prepare a new request explicitly.</remarks>
    function Execute: TCardWorkflowState;
    /// <summary>Checks the single-use prepared request without events or card I/O.</summary>
    procedure CheckPrepared;
    /// <summary>Requests a stop before the next step; callable from same-thread events.</summary>
    procedure Cancel;
    /// <summary>True during execution and completion callbacks.</summary>
    property Busy: Boolean read FBusy;
    /// <summary>Current or terminal operation state.</summary>
    property State: TCardWorkflowState read FState;
    /// <summary>Failure class name only, excluding card data and keys.</summary>
    property ErrorClass: string read FErrorClass;
    /// <summary>Last observer failure class; does not alter mutation evidence.</summary>
    property ObserverErrorClass: string read FObserverErrorClass;
  published
    /// <summary>Notifies when the phase or terminal outcome changes.</summary>
    property OnStageChanged: TNotifyEvent read FOnStageChanged write FOnStageChanged;
    /// <summary>Phase and unit progress on the executing thread.</summary>
    property OnProgress: TCardWorkflowProgressEvent read FOnProgress write FOnProgress;
    /// <summary>Card presentation or single-reader swap hook.</summary>
    property OnCardRequired: TCardWorkflowCardEvent read FOnCardRequired write FOnCardRequired;
    /// <summary>Terminal completed, cancelled or needs-verification notification.</summary>
    property OnCompleted: TNotifyEvent read FOnCompleted write FOnCompleted;
    /// <summary>Terminal failed or uncertain notification.</summary>
    property OnError: TNotifyEvent read FOnError write FOnError;
  end;
  /// <summary>Outcome for an individual block or page.</summary>
  TCardWorkflowUnitState = (
    /// <summary>No write attempted.</summary>
    cwusPending,
    /// <summary>Target already matched the snapshot.</summary>
    cwusUnchanged,
    /// <summary>Written and independently read back.</summary>
    cwusVerified,
    /// <summary>Mutation completion could not be established.</summary>
    cwusUncertain);
  /// <summary>One independently owned snapshot block or page.</summary>
  TCardWorkflowUnit = record
    /// <summary>Physical block or page number.</summary>
    Address: Integer;
    /// <summary>Complete readable bytes; never synthesized for unreadable data.</summary>
    Data: TBytes;
    /// <summary>Write evidence for this unit.</summary>
    State: TCardWorkflowUnitState;
  end;
  /// <summary>Explicit selected addresses, validated before I/O.</summary>
  TCardWorkflowAddresses = array of Integer;
  /// <summary>Selected complete blocks or pages, with independent data buffers on API return.</summary>
  TCardWorkflowUnits = array of TCardWorkflowUnit;
  /// <summary>Complete selected-memory snapshot; credentials are supplied separately.</summary>
  TCardWorkflowSnapshot = record
    /// <summary>Exact family/model identifier; restores require an exact match.</summary>
    Layout: string;
    /// <summary>Observed source identity, not an authenticity certificate.</summary>
    Uid: TBytes;
    /// <summary>Only successfully read selected units; no missing-unit zero fill.</summary>
    Units: TCardWorkflowUnits;
  end;
  /// <summary>Application-extensible memory backend with exclusive caller-controlled connection ownership.</summary>
  /// <remarks>Layout and ValidateUnit perform no I/O. Never replace the card/connection during
  /// a phase except in OnCardRequired. Each mutation must be sent once; masked secrets cannot
  /// be represented as ordinary copyable memory. Implementations must bound all operations.</remarks>
  ICardWorkflowMemory = interface
    ['{A372CB0C-1F25-4912-93E0-8DDD2672B45E}']
    /// <summary>Returns a stable family/model identifier without I/O.</summary>
    /// <returns>Nonempty exact layout name.</returns>
    function Layout: string;
    /// <summary>Checks one permitted readable/writable address without I/O.</summary>
    /// <param name="AAddress">Physical address.</param>
    /// <param name="AWriting">True for a target data write.</param>
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    /// <summary>Returns the exact byte width without I/O.</summary>
    /// <returns>One through 256 bytes.</returns>
    function UnitSize: Integer;
    /// <summary>Acquires the connected card identity.</summary>
    /// <returns>Nonempty identifier used to detect accidental card swaps.</returns>
    function ReadUid: TBytes;
    /// <summary>Acquires one complete unit or raises, with no zero-filled fallback.</summary>
    /// <param name="AAddress">Previously validated address.</param>
    /// <returns>Independent complete unit bytes.</returns>
    function ReadUnit(const AAddress: Integer): TBytes;
    /// <summary>Dispatches one write; does not retry after uncertain outcomes.</summary>
    /// <param name="AAddress">Previously validated data address.</param>
    /// <param name="AData">Exact unit bytes; never modified.</param>
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
  end;
  /// <summary>Optional target protection checks performed for all differing units before writing.</summary>
  ICardWorkflowWritePreflight = interface
    ['{EA0D3A17-17EA-423B-8155-6DC2A9457405}']
    /// <summary>Checks live write permission without mutating the card.</summary>
    /// <param name="AAddress">Previously validated differing target unit.</param>
    procedure CheckWritable(const AAddress: Integer);
  end;
  /// <summary>Reusable backup, restore, compare and verified data-copy workflow.</summary>
  /// <remarks>Reads all source units and all target originals before the first write. Default
  /// skips equal units. Partial writes remain visible in Results. Identity is checked before
  /// each unit, but UID alone is not an authentication mechanism. No rollback or write replay.</remarks>
  TCardMemoryCopyWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: ICardWorkflowMemory;
    FSnapshot: TCardWorkflowSnapshot;
    FAddresses: TCardWorkflowAddresses;
    FResults: TCardWorkflowUnits;
    FPrepared, FConsumed, FCompareOnly: Boolean;
    function GetSnapshot: TCardWorkflowSnapshot;
    function GetResults: TCardWorkflowUnits;
    procedure CheckIdentity(const AStorage: ICardWorkflowMemory; const AUid: TBytes);
  protected
    /// <summary>Checks readiness and single-execution lifecycle.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Acquires, checks, writes and verifies the prepared selection.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares selected memory copy; no hardware I/O.</summary>
    /// <param name="ASource">Source backend retained until next preparation or destruction.</param>
    /// <param name="ATarget">Destination backend.</param>
    /// <param name="AAddresses">Nonempty unique permitted data addresses.</param>
    /// <param name="ACompareOnly">True builds a difference plan without any writes.</param>
    procedure PrepareCopy(const ASource, ATarget: ICardWorkflowMemory;
      const AAddresses: TCardWorkflowAddresses; const ACompareOnly: Boolean = False);
    /// <summary>Prepares a complete selected-memory backup without any target writes.</summary>
    /// <param name="ASource">Source backend.</param>
    /// <param name="AAddresses">Selected unique readable data addresses.</param>
    procedure PrepareBackup(const ASource: ICardWorkflowMemory;
      const AAddresses: TCardWorkflowAddresses);
    /// <summary>Prepares restoration or comparison of an independently copied snapshot.</summary>
    /// <param name="ASnapshot">Complete selected units, compatible with the target layout.</param>
    /// <param name="ATarget">Destination backend.</param>
    /// <param name="ACompareOnly">True performs comparison without writes.</param>
    procedure PrepareRestore(const ASnapshot: TCardWorkflowSnapshot;
      const ATarget: ICardWorkflowMemory; const ACompareOnly: Boolean = False);
    /// <summary>Independent snapshot from the last acquisition or prepared restore.</summary>
    property Snapshot: TCardWorkflowSnapshot read GetSnapshot;
    /// <summary>Independent per-unit plan/evidence; Pending differences in compare-only mode.</summary>
    property Results: TCardWorkflowUnits read GetResults;
  end;

/// <summary>Returns a readable stable English phase/outcome name for application output.</summary>
/// <param name="AState">Workflow phase or outcome.</param>
/// <returns>Readable phase name, or Unknown for an invalid enum.</returns>
function CardWorkflowStateName(const AState: TCardWorkflowState): string;

/// <summary>Returns readable per-unit completion evidence.</summary>
/// <param name="AState">Unit evidence.</param>
/// <returns>Pending, Unchanged, Verified, Uncertain or Unknown.</returns>
function CardWorkflowUnitStateName(const AState: TCardWorkflowUnitState): string;

implementation

function CardWorkflowStateName(const AState: TCardWorkflowState): string;
begin
  case AState of
    cwsIdle: Result := 'Idle';
    cwsReading: Result := 'Reading';
    cwsChecking: Result := 'Checking';
    cwsWriting: Result := 'Writing';
    cwsVerifying: Result := 'Verifying';
    cwsCompleted: Result := 'Completed';
    cwsCancelled: Result := 'Cancelled';
    cwsFailed: Result := 'Failed';
    cwsUncertain: Result := 'Uncertain';
    cwsNeedsVerification: Result := 'Needs active UID verification';
  else Result := 'Unknown'; end;
end;

function CardWorkflowUnitStateName(const AState: TCardWorkflowUnitState): string;
begin
  case AState of
    cwusPending: Result := 'Pending';
    cwusUnchanged: Result := 'Unchanged';
    cwusVerified: Result := 'Verified';
    cwusUncertain: Result := 'Uncertain';
  else Result := 'Unknown'; end;
end;



procedure TCardWorkflow.RequireIdle;
begin
  if FBusy then
    raise ECardWorkflowError.Create('Workflow is busy.');
end;

procedure TCardWorkflow.Notify(const AEvent: TNotifyEvent);
begin
  if Assigned(AEvent) then
    try
      AEvent(Self);
    except
      on E: Exception do FObserverErrorClass := E.ClassName;
    end;
end;

procedure TCardWorkflow.Progress(const AState: TCardWorkflowState;
  const ADone, ATotal: Integer);
begin
  if FState <> AState then
  begin
    FState := AState;
    Notify(FOnStageChanged);
  end;
  if Assigned(FOnProgress) then
    try
      FOnProgress(Self, AState, ADone, ATotal);
    except
      on E: Exception do FObserverErrorClass := E.ClassName;
    end;
end;

function TCardWorkflow.RequestCard(const ARole: TCardWorkflowRole): Boolean;
begin
  Result := not FCancel;
  if Result and Assigned(FOnCardRequired) then
    try
      FOnCardRequired(Self, ARole, Result);
    except
      on E: Exception do
      begin
        FObserverErrorClass := E.ClassName;
        Result := False;
      end;
    end;
  Result := Result and not FCancel;
end;

procedure TCardWorkflow.MutationPending(const AValue: Boolean);
begin
  FUncertain := AValue;
end;

procedure TCardWorkflow.CheckPrepared;
begin
  RequireIdle;
  ValidatePrepared;
end;

function TCardWorkflow.Execute: TCardWorkflowState;
begin
  RequireIdle;
  ValidatePrepared;
  FBusy := True;
  FCancel := False;
  FUncertain := False;
  FErrorClass := '';
  FObserverErrorClass := '';
  FState := cwsIdle;
  try
    try
      DoExecute;
      if FState <> cwsNeedsVerification then
        if FCancel then Progress(cwsCancelled, 0, 0) else Progress(cwsCompleted, 0, 0);
    except
      on E: Exception do
      begin
        FErrorClass := E.ClassName;
        if FUncertain then Progress(cwsUncertain, 0, 0) else Progress(cwsFailed, 0, 0);
      end;
    end;
    if FState in [cwsFailed, cwsUncertain] then Notify(FOnError)
    else Notify(FOnCompleted);
    Result := FState;
  finally
    FBusy := False;
  end;
end;

procedure TCardWorkflow.Cancel;
begin
  if FBusy then FCancel := True;
end;

function CloneUnits(const AUnits: TCardWorkflowUnits): TCardWorkflowUnits;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(AUnits));
  for I := 0 to High(AUnits) do
  begin
    Result[I] := AUnits[I];
    Result[I].Data := CopyBytes(AUnits[I].Data);
  end;
end;

function TCardMemoryCopyWorkflow.GetSnapshot: TCardWorkflowSnapshot;
begin
  Result.Layout := FSnapshot.Layout;
  Result.Uid := CopyBytes(FSnapshot.Uid);
  Result.Units := CloneUnits(FSnapshot.Units);
end;

function TCardMemoryCopyWorkflow.GetResults: TCardWorkflowUnits;
begin
  Result := CloneUnits(FResults);
end;

procedure TCardMemoryCopyWorkflow.PrepareCopy(const ASource,
  ATarget: ICardWorkflowMemory; const AAddresses: TCardWorkflowAddresses;
  const ACompareOnly: Boolean);
var I, J: Integer;
begin
  RequireIdle;
  FPrepared := False;
  if (ASource = nil) or (Length(AAddresses) < 1) or
    (Length(AAddresses) > 4096) then
    raise ECardWorkflowError.Create('Source and selected addresses required.');
  if (ASource.Layout = '') or (ASource.UnitSize < 1) or (ASource.UnitSize > 256) then
    raise ECardWorkflowError.Create('Invalid source geometry.');
  if (ATarget <> nil) and ((ASource.Layout <> ATarget.Layout) or
    (ASource.UnitSize <> ATarget.UnitSize)) then
    raise ECardWorkflowError.Create('Incompatible target layout.');
  for I := 0 to High(AAddresses) do
  begin
    ASource.ValidateUnit(AAddresses[I], False);
    if ATarget <> nil then ATarget.ValidateUnit(AAddresses[I], True);
    for J := 0 to I - 1 do
      if AAddresses[J] = AAddresses[I] then
        raise ECardWorkflowError.Create('Duplicate address.');
  end;
  FSource := ASource;
  FTarget := ATarget;
  FAddresses := Copy(AAddresses, 0, Length(AAddresses));
  FSnapshot.Layout := ASource.Layout;
  FSnapshot.Uid := nil;
  FSnapshot.Units := nil;
  FResults := nil;
  FCompareOnly := ACompareOnly;
  FConsumed := False;
  FPrepared := True;
end;

procedure TCardMemoryCopyWorkflow.PrepareBackup(const ASource: ICardWorkflowMemory;
  const AAddresses: TCardWorkflowAddresses);
begin
  PrepareCopy(ASource, nil, AAddresses, True);
end;

procedure TCardMemoryCopyWorkflow.PrepareRestore(const ASnapshot: TCardWorkflowSnapshot;
  const ATarget: ICardWorkflowMemory; const ACompareOnly: Boolean);
var I, J: Integer;
begin
  RequireIdle;
  FPrepared := False;
  if (ATarget = nil) or (ASnapshot.Layout <> ATarget.Layout) or
    (Length(ASnapshot.Units) < 1) or (Length(ASnapshot.Units) > 4096) or
    (Length(ASnapshot.Uid) < 1) or (Length(ASnapshot.Uid) > 64) or
    (ATarget.UnitSize < 1) or (ATarget.UnitSize > 256) then
    raise ECardWorkflowError.Create('Invalid restoration snapshot.');
  for I := 0 to High(ASnapshot.Units) do
  begin
    ATarget.ValidateUnit(ASnapshot.Units[I].Address, True);
    if Length(ASnapshot.Units[I].Data) <> ATarget.UnitSize then
      raise ECardWorkflowError.Create('Invalid snapshot unit width.');
    for J := 0 to I - 1 do
      if ASnapshot.Units[J].Address = ASnapshot.Units[I].Address then
        raise ECardWorkflowError.Create('Duplicate snapshot address.');
  end;
  FSource := nil;
  FTarget := ATarget;
  FSnapshot.Layout := ASnapshot.Layout;
  FSnapshot.Uid := CopyBytes(ASnapshot.Uid);
  FSnapshot.Units := CloneUnits(ASnapshot.Units);
  FResults := nil;
  FAddresses := nil;
  FCompareOnly := ACompareOnly;
  FConsumed := False;
  FPrepared := True;
end;

procedure TCardMemoryCopyWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then
    raise ECardWorkflowError.Create('Prepare a new workflow request.');
end;

procedure TCardMemoryCopyWorkflow.CheckIdentity(const AStorage: ICardWorkflowMemory;
  const AUid: TBytes);
begin
  if not BytesEqual(AStorage.ReadUid, AUid) then
    raise ECardWorkflowError.Create('Card changed during workflow.');
end;

procedure TCardMemoryCopyWorkflow.DoExecute;
var I: Integer; Uid, Data: TBytes; Acquired: TCardWorkflowUnits;
  Preflight: ICardWorkflowWritePreflight;
begin
  FConsumed := True;
  if FSource <> nil then
  begin
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, Length(FAddresses));
    if CancelRequested then Exit;
    Uid := FSource.ReadUid;
    if (Length(Uid) < 1) or (Length(Uid) > 64) then
      raise ECardWorkflowError.Create('Invalid source identity.');
    Acquired := nil;
    SetLength(Acquired, Length(FAddresses));
    for I := 0 to High(FAddresses) do
    begin
      if CancelRequested then Exit;
      CheckIdentity(FSource, Uid);
      Acquired[I].Address := FAddresses[I];
      Acquired[I].Data := CopyBytes(FSource.ReadUnit(FAddresses[I]));
      if Length(Acquired[I].Data) <> FSource.UnitSize then
        raise ECardWorkflowError.Create('Incomplete source unit.');
      Progress(cwsReading, I + 1, Length(FAddresses));
    end;
    FSnapshot.Uid := CopyBytes(Uid);
    FSnapshot.Units := Acquired;
  end;
  if FTarget = nil then Exit;
  if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
  Uid := FTarget.ReadUid;
  if (Length(Uid) < 1) or (Length(Uid) > 64) then
    raise ECardWorkflowError.Create('Invalid target identity.');
  FResults := CloneUnits(FSnapshot.Units);
  for I := 0 to High(FResults) do FResults[I].State := cwusPending;
  Progress(cwsChecking, 0, Length(FResults));
  for I := 0 to High(FResults) do
  begin
    if CancelRequested then Exit;
    CheckIdentity(FTarget, Uid);
    Data := FTarget.ReadUnit(FResults[I].Address);
    if Length(Data) <> FTarget.UnitSize then
      raise ECardWorkflowError.Create('Incomplete target unit.');
    if BytesEqual(Data, FResults[I].Data) then FResults[I].State := cwusUnchanged
    else if not FCompareOnly and Supports(FTarget, ICardWorkflowWritePreflight, Preflight) then
      Preflight.CheckWritable(FResults[I].Address);
    Progress(cwsChecking, I + 1, Length(FResults));
  end;
  if FCompareOnly or CancelRequested then Exit;
  for I := 0 to High(FResults) do
  begin
    if CancelRequested then Exit;
    if FResults[I].State = cwusUnchanged then Continue;
    CheckIdentity(FTarget, Uid);
    Progress(cwsWriting, I, Length(FResults));
    if CancelRequested then Exit;
    FResults[I].State := cwusUncertain;
    MutationPending(True);
    try
      FTarget.WriteUnit(FResults[I].Address, CopyBytes(FResults[I].Data));
    except
      on E: ECardWorkflowWriteRefused do
      begin
        FResults[I].State := cwusPending; MutationPending(False); raise;
      end;
    end;
    Progress(cwsVerifying, I, Length(FResults));
    CheckIdentity(FTarget, Uid);
    if not BytesEqual(FTarget.ReadUnit(FResults[I].Address), FResults[I].Data) then
      raise ECardWorkflowError.Create('Read-back mismatch.');
    FResults[I].State := cwusVerified;
    MutationPending(False);
    Progress(cwsVerifying, I + 1, Length(FResults));
  end;
end;

end.
