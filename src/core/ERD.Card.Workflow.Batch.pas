unit ERD.Card.Workflow.Batch;

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
  ERD.Card.Workflow;

type
  /// <summary>Application identifiers for separately prepared personalization requests.</summary>
  TCardBatchIdentifiers = array of string;
  /// <summary>Creates a fresh, prepared workflow for one application-defined card template.</summary>
  /// <remarks>Creation and preparation must perform no hardware I/O. Return a new Owner=nil
  /// workflow; ownership transfers to the batch. The batch replaces child progress/card callbacks.
  /// Existing memory, NDEF, UID, credential and magstripe workflows can be returned.</remarks>
  ICardBatchFactory = interface
    ['{B970A201-614C-41BE-A5FC-D76CECF6C6CC}']
    /// <summary>Builds and validates one immutable request without reading or writing cards.</summary>
    /// <param name="AIdentifier">Unique application identifier; do not include keys or card payloads.</param>
    /// <returns>Fresh prepared workflow owned exclusively by the batch.</returns>
    function CreateWorkflow(const AIdentifier: string): TCardWorkflow;
  end;
  /// <summary>One batch request's outcome without keys or payload bytes.</summary>
  TCardBatchResult = record
    /// <summary>Application identifier supplied at preparation.</summary>
    Identifier: string;
    /// <summary>True only when this request has started; false means never attempted.</summary>
    Attempted: Boolean;
    /// <summary>Child outcome; Idle for an unattempted request.</summary>
    State: TCardWorkflowState;
    /// <summary>Failure class name only.</summary>
    ErrorClass: string;
    /// <summary>Last child observer failure class, if any.</summary>
    ObserverErrorClass: string;
  end;
  /// <summary>Independent array of per-card batch outcomes.</summary>
  TCardBatchResults = array of TCardBatchResult;
  /// <summary>Batch-owned prepared workflow components sharing one Delphi array type.</summary>
  TCardBatchChildren = array of TCardWorkflow;
  /// <summary>Bounded batch personalization using application-supplied prepared templates.</summary>
  /// <remarks>All templates are built before card I/O. Executes each child once, stopping on
  /// any non-completed outcome. Never retries, rolls back or resumes a consumed batch. Use
  /// CurrentIdentifier in OnCardRequired to ask for the next card. Reader ownership, card
  /// selection and prevention of presenting the same physical card remain application duties.
  /// Completed child instances and their detailed evidence remain available until preparation
  /// or destruction. Execute and events use the caller's thread.</remarks>
  TCardBatchWorkflow = class(TCardWorkflow)
  private
    FChildren: TCardBatchChildren;
    FResults: TCardBatchResults;
    FPrepared, FConsumed: Boolean;
    FCurrentIndex: Integer;
    function GetResults: TCardBatchResults;
    function GetCurrentIdentifier: string;
    procedure ChildProgress(Sender: TObject; const AState: TCardWorkflowState;
      const ADone, ATotal: Integer);
    procedure ChildCard(Sender: TObject; const ARole: TCardWorkflowRole;
      var AReady: Boolean);
    procedure ClearChildren;
  protected
    /// <summary>Rejects missing or already consumed batches.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Executes prepared children once, retaining each outcome.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Creates an inactive batch with no active request.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases all batch-owned child components.</summary>
    destructor Destroy; override;
    /// <summary>Builds all requests atomically, with no card I/O.</summary>
    /// <param name="AIdentifiers">One through 256 nonempty unique identifiers, at most 128 characters.</param>
    /// <param name="AFactory">Factory used only during this call; must return fresh prepared children.</param>
    procedure Prepare(const AIdentifiers: TCardBatchIdentifiers;
      const AFactory: ICardBatchFactory);
    /// <summary>Returns a retained child's detailed evidence; never execute or destroy it directly.</summary>
    /// <param name="AIndex">Zero-based prepared request index.</param>
    /// <returns>Borrowed component valid until next preparation or destruction.</returns>
    function Child(const AIndex: Integer): TCardWorkflow;
    /// <summary>Independent per-card outcomes, including requests never attempted.</summary>
    property Results: TCardBatchResults read GetResults;
    /// <summary>Zero-based active request index; minus one before execution.</summary>
    property CurrentIndex: Integer read FCurrentIndex;
    /// <summary>Application identifier for the active request; empty before execution.</summary>
    property CurrentIdentifier: string read GetCurrentIdentifier;
  end;

implementation

constructor TCardBatchWorkflow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurrentIndex := -1;
end;

procedure TCardBatchWorkflow.ClearChildren;
var I: Integer;
begin
  for I := 0 to High(FChildren) do FChildren[I].Free;
  FChildren := nil;
end;

destructor TCardBatchWorkflow.Destroy;
begin
  ClearChildren;
  inherited;
end;

procedure TCardBatchWorkflow.Prepare(const AIdentifiers: TCardBatchIdentifiers;
  const AFactory: ICardBatchFactory);
var I, J: Integer; Children: TCardBatchChildren; R: TCardBatchResults;
begin
  RequireIdle;
  if (AFactory = nil) or (Length(AIdentifiers) < 1) or
    (Length(AIdentifiers) > 256) then
    raise ECardWorkflowError.Create('Provide a bounded batch and factory.');
  for I := 0 to High(AIdentifiers) do
  begin
    if (Length(AIdentifiers[I]) < 1) or (Length(AIdentifiers[I]) > 128) then
      raise ECardWorkflowError.Create('Invalid batch identifier.');
    for J := 0 to I - 1 do
      if AIdentifiers[J] = AIdentifiers[I] then
        raise ECardWorkflowError.Create('Duplicate batch identifier.');
  end;
  Children := nil; R := nil;
  SetLength(Children, Length(AIdentifiers)); SetLength(R, Length(AIdentifiers));
  try
    for I := 0 to High(AIdentifiers) do
    begin
      Children[I] := AFactory.CreateWorkflow(AIdentifiers[I]);
      if (Children[I] = nil) or (Children[I] = Self) then
      begin
        Children[I] := nil;
        raise ECardWorkflowError.Create('Factory must return a fresh workflow.');
      end;
      for J := 0 to I - 1 do
        if Children[J] = Children[I] then
        begin
          Children[I] := nil;
          raise ECardWorkflowError.Create('Factory returned a reused workflow.');
        end;
      if (Children[I].Owner <> nil) or Children[I].Busy or
        (Children[I].State <> cwsIdle) then
      begin
        Children[I] := nil;
        raise ECardWorkflowError.Create('Factory returned a borrowed or used workflow.');
      end;
      for J := 0 to High(FChildren) do
        if Children[I] = FChildren[J] then
        begin
          Children[I] := nil;
          raise ECardWorkflowError.Create('Factory returned a retained workflow.');
        end;
      Children[I].CheckPrepared;
      Children[I].OnProgress := ChildProgress;
      Children[I].OnCardRequired := ChildCard;
      R[I].Identifier := AIdentifiers[I]; R[I].State := cwsIdle;
    end;
    ClearChildren;
    FChildren := Children; Children := nil;
    FResults := R; FCurrentIndex := -1;
    FConsumed := False; FPrepared := True;
  finally
    for I := 0 to High(Children) do Children[I].Free;
  end;
end;

procedure TCardBatchWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then
    raise ECardWorkflowError.Create('Prepare a new batch request.');
end;

procedure TCardBatchWorkflow.ChildProgress(Sender: TObject;
  const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin
  Progress(AState, ADone, ATotal);
  if CancelRequested then TCardWorkflow(Sender).Cancel;
end;

procedure TCardBatchWorkflow.ChildCard(Sender: TObject;
  const ARole: TCardWorkflowRole; var AReady: Boolean);
begin
  AReady := RequestCard(ARole);
end;

procedure TCardBatchWorkflow.DoExecute;
var I: Integer; Outcome: TCardWorkflowState;
begin
  FConsumed := True;
  for I := 0 to High(FChildren) do
  begin
    if CancelRequested then Exit;
    FCurrentIndex := I;
    FResults[I].Attempted := True;
    try
      Outcome := FChildren[I].Execute;
    except
      on E: Exception do
      begin
        FResults[I].State := cwsFailed;
        FResults[I].ErrorClass := E.ClassName;
        raise;
      end;
    end;
    FResults[I].State := Outcome;
    FResults[I].ErrorClass := FChildren[I].ErrorClass;
    FResults[I].ObserverErrorClass := FChildren[I].ObserverErrorClass;
    case Outcome of
      cwsCompleted: ;
      cwsCancelled: begin Cancel; Exit; end;
      cwsNeedsVerification: begin Progress(cwsNeedsVerification, I, Length(FChildren)); Exit; end;
      cwsUncertain: begin MutationPending(True);
        raise ECardWorkflowError.Create('Inspect the uncertain batch item.'); end;
    else
      raise ECardWorkflowError.Create('Batch item failed.');
    end;
    Progress(cwsChecking, I + 1, Length(FChildren));
  end;
end;

function TCardBatchWorkflow.GetResults: TCardBatchResults;
var I: Integer;
begin
  Result := nil; SetLength(Result, Length(FResults));
  for I := 0 to High(FResults) do Result[I] := FResults[I];
end;

function TCardBatchWorkflow.GetCurrentIdentifier: string;
begin
  Result := '';
  if FPrepared and (FCurrentIndex >= 0) and (FCurrentIndex < Length(FResults)) then
    Result := FResults[FCurrentIndex].Identifier;
end;

function TCardBatchWorkflow.Child(const AIndex: Integer): TCardWorkflow;
begin
  if (AIndex < 0) or (AIndex >= Length(FChildren)) then
    raise ECardWorkflowError.Create('Invalid batch item index.');
  Result := FChildren[AIndex];
end;

end.
