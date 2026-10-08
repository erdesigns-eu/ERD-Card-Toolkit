unit ERD.Card.Demo.Form;

interface

uses System.Classes, Vcl.Forms, Vcl.ExtCtrls, ERD.Card.Demo.Job;

type
  /// <summary>VCL polling host; keeps card work off the UI thread and defers closing until completion.</summary>
  TCardDemoForm = class(TForm)
  private
    FJob: TCardDemoJob;
    FTimer: TTimer;
    FClosing: Boolean;
    procedure Poll(Sender: TObject);
  protected
    /// <summary>Refuses normal window close while hardware work is active, then closes on completion.</summary>
    /// <returns>Inherited close permission only when no job is running.</returns>
    function CloseQuery: Boolean; override;
    /// <summary>Updates controls for the start or completion of one job.</summary>
    /// <param name="AValue">True while a job is pending; false after its thread has joined.</param>
    procedure SetBusy(const AValue: Boolean); virtual; abstract;
    /// <summary>Displays owned data on the UI thread after the worker has been freed.</summary>
    /// <param name="AResult">Completed data, retained by the form only when needed.</param>
    procedure Complete(const AResult: TCardDemoResult); virtual; abstract;
    /// <summary>Starts one request; a second concurrent job is refused.</summary>
    /// <param name="ARequest">Request whose byte buffers are copied by the worker.</param>
    procedure StartRequest(const ARequest: TCardDemoRequest);
  public
    /// <summary>Loads the descendant DFM and creates a disabled polling timer.</summary>
    /// <param name="AOwner">Standard VCL form owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Stops polling and joins any job before destroying VCL controls.</summary>
    destructor Destroy; override;
  end;

implementation

uses System.SysUtils, ERD.Card.Demo.Operations;

constructor TCardDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False; FTimer.Interval := 100; FTimer.OnTimer := Poll;
end;

destructor TCardDemoForm.Destroy;
begin
  if FTimer <> nil then FTimer.Enabled := False;
  FJob.Free;
  inherited Destroy;
end;

procedure TCardDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin
  if FJob <> nil then raise EInvalidOpException.Create('An operation is already active.');
  FJob := TCardDemoJob.Create(ARequest, CreateCardDemoOperations);
  SetBusy(True); FTimer.Enabled := True;
end;

procedure TCardDemoForm.Poll(Sender: TObject);
var Data: TCardDemoResult;
begin
  Data := Default(TCardDemoResult);
  if FJob = nil then Exit;
  if not FJob.TryTakeResult(Data) then Exit;
  FTimer.Enabled := False;
  FreeAndNil(FJob);
  if FClosing then
  begin Close; Exit; end;
  SetBusy(False);
  Complete(Data);
end;

function TCardDemoForm.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if not Result then Exit;
  if FJob <> nil then
  begin
    FClosing := True;
    Caption := 'Waiting for the active card operation to finish...';
    Result := False;
  end;
end;

end.
