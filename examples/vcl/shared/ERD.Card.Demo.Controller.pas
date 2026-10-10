unit ERD.Card.Demo.Controller;

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
  ERD.Card.Demo.Job, ERD.Card.Demo.Devices;

type
  /// <summary>Caller-thread notification for one worker's busy state; contains no visual controls.</summary>
  /// <param name="AValue">True after request acquisition, false after completion or failed start.</param>
  TCardDemoBusyEvent = procedure(const AValue: Boolean) of object;
  /// <summary>Caller-thread notification carrying independent worker output after the thread has joined.</summary>
  /// <param name="AResult">Owned immutable result; no UI object crosses the thread boundary.</param>
  TCardDemoResultEvent = procedure(const AResult: TCardDemoResult) of object;
  /// <summary>Caller-thread notification allowing a previously deferred form close.</summary>
  TCardDemoCloseEvent = procedure of object;
  /// <summary>Nonvisual worker lifecycle controller; forms and timers remain owned by individual demos.</summary>
  /// <remarks>Call StartRequest, Poll and CanClose from one caller/UI thread. Destruction joins active work.
  /// No form, control, timer or resource is created, inherited or shared by this class.</remarks>
  TCardDemoController = class
  private
    FJob: TCardDemoJob;
    FOperations: ICardDemoOperations;
    FValidator: ICardDemoRequestValidator;
    FBusyEvent: TCardDemoBusyEvent;
    FResultEvent: TCardDemoResultEvent;
    FCloseEvent: TCardDemoCloseEvent;
    FClosing: Boolean;
  public
    /// <summary>Creates an inactive controller without starting a worker or opening hardware.</summary>
    /// <param name="ADeviceKind">Transport to discover for this demo.</param>
    /// <param name="ADeviceSource">Optional injected source; nil uses native discovery.</param>
    /// <param name="AOperations">Retained explicit executor; cannot be nil.</param>
    /// <param name="ABusyEvent">Required synchronous busy notification.</param>
    /// <param name="AResultEvent">Required synchronous completion notification.</param>
    /// <param name="ACloseEvent">Required deferred-close notification.</param>
    constructor Create(const ADeviceKind: TCardDemoDeviceKind; const AOperations: ICardDemoOperations; const ABusyEvent: TCardDemoBusyEvent;
      const AResultEvent: TCardDemoResultEvent; const ACloseEvent: TCardDemoCloseEvent;
      const ADeviceSource: ICardDemoDeviceSource = nil);
    /// <summary>Joins any outstanding worker before discarding callbacks and its executor.</summary>
    destructor Destroy; override;
    /// <summary>Checks optional request metadata, then starts work only after worker construction has completed.</summary>
    /// <param name="ARequest">Explicit request; worker deep-copies credentials and argument arrays.</param>
    /// <exception cref="EInvalidOpException">Another request or deferred close is active.</exception>
    /// <remarks>Rejected metadata is reported synchronously through the result event without creating a worker.</remarks>
    procedure StartRequest(const ARequest: TCardDemoRequest);
    /// <summary>Checks completion from the demo's own DFM timer, joins the worker, then notifies its form.</summary>
    /// <remarks>A deferred close discards display output and invokes ACloseEvent instead.</remarks>
    procedure Poll;
    /// <summary>Defers closing until an outstanding job has completed; never cancels or replays card work.</summary>
    /// <returns>True when no worker is retained; otherwise false and Poll finishes the deferred close.</returns>
    function CanClose: Boolean;
  end;

implementation

type
  TControllerOperations = class(TInterfacedObject, ICardDemoOperations)
    Kind: TCardDemoDeviceKind;
    Source: ICardDemoDeviceSource;
    Operations: ICardDemoOperations;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure TControllerOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
begin
  if ARequest.Operation <> cdoDemoDevices then begin Operations.Run(ARequest,AResult); Exit; end;
  AResult := Default(TCardDemoResult); AResult.Operation := cdoDemoDevices;
  AResult.Devices := Source.Enumerate(Kind); AResult.Success := True;
end;

constructor TCardDemoController.Create(const ADeviceKind: TCardDemoDeviceKind; const AOperations: ICardDemoOperations;
  const ABusyEvent: TCardDemoBusyEvent; const AResultEvent: TCardDemoResultEvent;
  const ACloseEvent: TCardDemoCloseEvent; const ADeviceSource: ICardDemoDeviceSource);
var Wrapper: TControllerOperations;
begin
  inherited Create;
  if (AOperations = nil) or not Assigned(ABusyEvent) or not Assigned(AResultEvent) or
    not Assigned(ACloseEvent) then raise EArgumentException.Create('Configure the demo controller callbacks.');
  Supports(AOperations, ICardDemoRequestValidator, FValidator);
  Wrapper := TControllerOperations.Create; FOperations := Wrapper;
  Wrapper.Kind := ADeviceKind; Wrapper.Operations := AOperations; Wrapper.Source := ADeviceSource;
  if Wrapper.Source = nil then Wrapper.Source := CreateCardDemoDeviceSource; FBusyEvent := ABusyEvent; FResultEvent := AResultEvent; FCloseEvent := ACloseEvent;
end;

destructor TCardDemoController.Destroy;
begin FJob.Free; inherited Destroy; end;

procedure TCardDemoController.StartRequest(const ARequest: TCardDemoRequest);
var ErrorText: UnicodeString; Rejected: TCardDemoResult;
begin
  if (FJob <> nil) or FClosing then raise EInvalidOpException.Create('An operation or deferred close is already active.');
  if (ARequest.Operation <> cdoDemoDevices) and (FValidator <> nil) then
    if not FValidator.TryValidateRequest(ARequest, ErrorText) then
    begin
      Rejected := Default(TCardDemoResult); Rejected.Operation := ARequest.Operation;
      Rejected.ErrorClass := 'EArgumentException'; Rejected.Text := ErrorText;
      FResultEvent(Rejected); Exit;
    end;
  FJob := TCardDemoJob.Create(ARequest,FOperations);
  try
    FBusyEvent(True); FJob.StartWork;
  except
    FreeAndNil(FJob); FBusyEvent(False); raise;
  end;
end;

procedure TCardDemoController.Poll;
var Data: TCardDemoResult;
begin
  Data := Default(TCardDemoResult);
  if FJob = nil then Exit;
  if not FJob.TryTakeResult(Data) then Exit;
  FreeAndNil(FJob);
  if FClosing then begin FCloseEvent; Exit; end;
  FBusyEvent(False); FResultEvent(Data);
end;

function TCardDemoController.CanClose: Boolean;
begin Result := FJob = nil; if not Result then FClosing := True; end;

end.
