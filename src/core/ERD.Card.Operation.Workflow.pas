unit ERD.Card.Operation.Workflow;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  ERD.Card.Operation, ERD.Card.Session, ERD.Card.Workflow;

type
  /// <summary>Binds a prepared single-card workflow to its reserved transport on the executor thread.</summary>
  /// <param name="ASession">Owned reader lease; do not close, retain or exchange cards inside this callback.</param>
  /// <param name="AWorkflow">Prepared workflow; configure its backend to ASession.Transport.</param>
  TCardWorkflowBindEvent = procedure(const ASession: ICardSessionLease;
    const AWorkflow: TCardWorkflow) of object;
  /// <summary>Binds ordered source/target transports to an existing prepared workflow on its worker.</summary>
  /// <param name="ASessions">Complete reserved group; do not close or retain it.</param>
  /// <param name="AWorkflow">Prepared workflow; configure its source/target backends explicitly.</param>
  TCardMultiWorkflowBindEvent = procedure(const ASessions: ICardSessionGroup;
    const AWorkflow: TCardWorkflow) of object;

/// <summary>Creates a single-use queue adapter for an existing prepared single-card workflow.</summary>
/// <param name="AWorkflow">Non-nil inactive workflow; caller keeps it alive unless ownership is transferred.</param>
/// <param name="ABind">Required binding callback; its target object must outlive the operation.</param>
/// <param name="AOwnsWorkflow">True transfers destruction responsibility after successful adapter creation.</param>
/// <returns>Retained job; forwards cooperative cancellation through workflow progress/stage boundaries.</returns>
/// <remarks>Existing observers are chained and restored in finally. Single-reader source/target swaps need
/// separate acquisition jobs because card change invalidates a lease. No credentials or prepared plans are persisted.</remarks>
function CreateCardWorkflowOperation(const AWorkflow: TCardWorkflow;
  const ABind: TCardWorkflowBindEvent; const AOwnsWorkflow: Boolean = False): ICardOperation;

/// <summary>Creates a single-use multi-reader adapter retaining the existing workflow cancellation and observer bridge.</summary>
/// <param name="AWorkflow">Inactive prepared workflow; kept alive until the operation is released.</param>
/// <param name="ABind">Required source/target binding callback; target object must outlive the operation.</param>
/// <param name="AOwnsWorkflow">True transfers workflow destruction after successful creation.</param>
/// <returns>Job for EnqueueMany; checks all generations before binding and after workflow execution.</returns>
/// <remarks>The workflow owns native transactions and target verification; reservations do not make multi-card writes atomic.</remarks>
function CreateCardMultiWorkflowOperation(const AWorkflow: TCardWorkflow;
  const ABind: TCardMultiWorkflowBindEvent; const AOwnsWorkflow: Boolean = False): ICardMultiOperation;

implementation

uses
{$IFDEF FPC}SysUtils, Classes;{$ELSE}System.SysUtils, System.Classes;{$ENDIF}

type
  TWorkflowOperation = class(TInterfacedObject, ICardOperation, ICardOperationFailure)
  private
    FWorkflow: TCardWorkflow;
    FBind: TCardWorkflowBindEvent;
    FOwns, FConsumed: Boolean;
    FCancel: ICardCancellation;
    FProgress: TCardWorkflowProgressEvent;
    FStage: TNotifyEvent;
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState;
      const ADone, ATotal: Integer);
    procedure Stage(Sender: TObject);
    procedure CheckCancel;
  public
    constructor Create(const Workflow: TCardWorkflow; const Bind: TCardWorkflowBindEvent; const Owns: Boolean);
    destructor Destroy; override;
    function FailureClass: string;
    function Execute(const ASession: ICardSessionLease;
      const ACancellation: ICardCancellation): TCardWorkflowState;
  end;

  TMultiWorkflowOperation = class(TInterfacedObject, ICardMultiOperation, ICardOperationFailure)
  private
    FInner: ICardOperation;
    FBind: TCardMultiWorkflowBindEvent;
    FGroup: ICardSessionGroup;
    procedure Bind(const Lease: ICardSessionLease; const Workflow: TCardWorkflow);
  public
    constructor Create(const Workflow: TCardWorkflow; const Callback: TCardMultiWorkflowBindEvent;
      const Owns: Boolean);
    function ExecuteMany(const ASessions: ICardSessionGroup;
      const ACancellation: ICardCancellation): TCardWorkflowState;
    function FailureClass: string;
  end;

constructor TMultiWorkflowOperation.Create(const Workflow: TCardWorkflow;
  const Callback: TCardMultiWorkflowBindEvent; const Owns: Boolean);
begin
  inherited Create;
  if not Assigned(Callback) then raise ECardOperationError.Create('A group workflow binding is required.');
  FBind := Callback; FInner := CreateCardWorkflowOperation(Workflow,Bind,Owns);
end;

procedure TMultiWorkflowOperation.Bind(const Lease: ICardSessionLease; const Workflow: TCardWorkflow);
begin
  if Lease=nil then raise ECardOperationError.Create('A group member is required.');
  FGroup.Validate; FBind(FGroup,Workflow);
end;

function TMultiWorkflowOperation.ExecuteMany(const ASessions: ICardSessionGroup;
  const ACancellation: ICardCancellation): TCardWorkflowState;
begin
  if (ASessions=nil) or (FGroup<>nil) then raise ECardOperationError.Create('A reader group is required.');
  ASessions.Validate; FGroup := ASessions;
  try
    Result := FInner.Execute(ASessions.Lease(0),ACancellation);
    ASessions.Validate;
  finally FGroup := nil; end;
end;

function TMultiWorkflowOperation.FailureClass: string;
var Failure: ICardOperationFailure;
begin
  Result := ''; if Supports(FInner,ICardOperationFailure,Failure) then Result := Failure.FailureClass;
end;

constructor TWorkflowOperation.Create(const Workflow: TCardWorkflow;
  const Bind: TCardWorkflowBindEvent; const Owns: Boolean);
begin
  inherited Create;
  if (Workflow=nil) or not Assigned(Bind) or Workflow.Busy then
    raise ECardOperationError.Create('An inactive workflow and binding are required.');
  FWorkflow := Workflow; FBind := Bind; FOwns := Owns;
end;

destructor TWorkflowOperation.Destroy;
begin
  if FOwns then FWorkflow.Free;
  inherited Destroy;
end;

function TWorkflowOperation.FailureClass: string;
begin
  Result := FWorkflow.ErrorClass;
end;

procedure TWorkflowOperation.CheckCancel;
begin
  if (FCancel<>nil) and FCancel.Requested then FWorkflow.Cancel;
end;

procedure TWorkflowOperation.Progress(Sender: TObject; const AState: TCardWorkflowState;
  const ADone, ATotal: Integer);
begin
  CheckCancel; if Assigned(FProgress) then FProgress(Sender,AState,ADone,ATotal);
end;

procedure TWorkflowOperation.Stage(Sender: TObject);
begin
  CheckCancel; if Assigned(FStage) then FStage(Sender);
end;

function TWorkflowOperation.Execute(const ASession: ICardSessionLease;
  const ACancellation: ICardCancellation): TCardWorkflowState;
begin
  if FConsumed or (ASession=nil) or (ACancellation=nil) then
    raise ECardOperationError.Create('Invalid or consumed workflow operation.');
  FConsumed := True; FWorkflow.CheckPrepared;
  if ACancellation.Requested then Exit(cwsCancelled);
  FBind(ASession,FWorkflow);
  FCancel := ACancellation; FProgress := FWorkflow.OnProgress; FStage := FWorkflow.OnStageChanged;
  FWorkflow.OnProgress := Progress; FWorkflow.OnStageChanged := Stage;
  try Result := FWorkflow.Execute;
  finally
    FWorkflow.OnProgress := FProgress; FWorkflow.OnStageChanged := FStage;
    FCancel := nil; FProgress := nil; FStage := nil;
  end;
end;

function CreateCardWorkflowOperation(const AWorkflow: TCardWorkflow;
  const ABind: TCardWorkflowBindEvent; const AOwnsWorkflow: Boolean): ICardOperation;
begin
  Result := TWorkflowOperation.Create(AWorkflow,ABind,AOwnsWorkflow);
end;

function CreateCardMultiWorkflowOperation(const AWorkflow: TCardWorkflow;
  const ABind: TCardMultiWorkflowBindEvent; const AOwnsWorkflow: Boolean): ICardMultiOperation;
begin
  Result := TMultiWorkflowOperation.Create(AWorkflow,ABind,AOwnsWorkflow);
end;

end.
