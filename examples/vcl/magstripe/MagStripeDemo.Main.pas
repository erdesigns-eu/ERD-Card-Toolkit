unit MagStripeDemo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  ERD.Card.MagStripe.Tracks, ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices;

type
  /// <summary>Offline magnetic-track codecs and explicit MSR206-7HL swipe/read-back operations.</summary>
  TMagStripeDemoForm = class(TForm)
  published
    /// <summary>Own DFM timer polling this form’s nonvisual controller.</summary>
    WorkerTimer: TTimer;
    /// <summary>Discover available serial ports within this demo.</summary>
    RefreshPortsButton: TButton;
    /// <summary>Refresh Windows serial aliases without probing the attached encoder.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RefreshPortsClick(Sender: TObject);
    /// <summary>Starts device discovery once when this form is shown.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormShow(Sender: TObject);
    /// <summary>Polls this form’s own worker from its DFM timer.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure PollTimer(Sender: TObject);
  published
    /// <summary>Explicit COM, track and operation inputs.</summary>
    InputPanel: TPanel;
    /// <summary>Serial adapter profile label.</summary>
    PortLabel: TLabel;
    /// <summary>Exact Windows COM port.</summary>
    PortBox: TComboBox;
    /// <summary>Swipe timeout label.</summary>
    TimeoutLabel: TLabel;
    /// <summary>Integer timeout in milliseconds.</summary>
    TimeoutEdit: TEdit;
    /// <summary>Explicit write coercivity label.</summary>
    CoercivityLabel: TLabel;
    /// <summary>Low or high coercivity; no inferred write setting.</summary>
    CoercivityBox: TComboBox;
    /// <summary>Select physical track 1.</summary>
    Track1Check: TCheckBox;
    /// <summary>Select physical track 2.</summary>
    Track2Check: TCheckBox;
    /// <summary>Select physical track 3.</summary>
    Track3Check: TCheckBox;
    /// <summary>Unframed track 1 payload.</summary>
    Track1Edit: TEdit;
    /// <summary>Unframed track 2 payload.</summary>
    Track2Edit: TEdit;
    /// <summary>Unframed track 3 payload.</summary>
    Track3Edit: TEdit;
    /// <summary>Offline parity and LRC frame inspection.</summary>
    InspectButton: TButton;
    /// <summary>Read one swipe with MSR206-7HL.</summary>
    ReadButton: TButton;
    /// <summary>Write selected tracks with independent read-back verification.</summary>
    WriteButton: TButton;
    /// <summary>Payload and verified-write guidance.</summary>
    GuideLabel: TLabel;
    /// <summary>Completion and framing lengths; payloads remain in track fields.</summary>
    OutputMemo: TMemo;
    /// <summary>Initialize choices without opening a serial port.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormCreate(Sender: TObject);
    /// <summary>Inspect selected payloads offline.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure InspectClick(Sender: TObject);
    /// <summary>Start one asynchronous swipe acquisition.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure ReadClick(Sender: TObject);
    /// <summary>Start explicit selected-track programming with verification.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure WriteClick(Sender: TObject);
  private
    FController: TCardDemoController;
    FDevices: TCardDemoDevices;
    FPreviousPort: UnicodeString;
    FDiscoveryStarted: Boolean;
    procedure StartRequest(const ARequest: TCardDemoRequest);
  private
    FSelectedTracks: TMagStripeTrackSet;
    procedure RunOperation(const AOperation: TCardDemoOperation);
  protected
    /// <summary>Defers close until this form’s owned background operation completes.</summary>
    /// <returns>True only when inherited close permission and worker lifecycle permit it.</returns>
    function CloseQuery: Boolean; override;
    /// <summary>Disables operation controls while one swipe is pending.</summary>
    /// <param name="AValue">True while busy.</param>
    procedure SetBusy(const AValue: Boolean);
    /// <summary>Displays completion and updates only selected track fields.</summary>
    /// <param name="AResult">Owned worker completion data.</param>
    procedure Complete(const AResult: TCardDemoResult);
  public
    /// <summary>Stops this form’s timer and joins its worker before destroying controls.</summary>
    destructor Destroy; override;
  end;

var
  /// <summary>Main form owned by the VCL Application.</summary>
  MagStripeForm: TMagStripeDemoForm;

implementation

uses ERD.Card.Demo.Operations, System.SysUtils, ERD.Card.MagStripe;

{$R *.dfm}

procedure TMagStripeDemoForm.FormCreate(Sender: TObject);
begin
  FController := TCardDemoController.Create(ddkSerial,CreateCardDemoOperations,SetBusy,Complete,Close);
  CoercivityBox.Items.Text := 'Low coercivity'#13#10'High coercivity';
end;

procedure TMagStripeDemoForm.SetBusy(const AValue: Boolean);
begin
  InputPanel.Enabled := not AValue;
  if AValue then OutputMemo.Lines.Text := 'Waiting for the selected operation. Swipe the card when prompted by the device.';
end;

procedure TMagStripeDemoForm.RunOperation(const AOperation: TCardDemoOperation);
var R: TCardDemoRequest; Timeout: Integer;
begin
  R := Default(TCardDemoRequest); R.Operation := AOperation;
  try
    if Track1Check.Checked then Include(R.TrackSelection, mstTrack1);
    if Track2Check.Checked then Include(R.TrackSelection, mstTrack2);
    if Track3Check.Checked then Include(R.TrackSelection, mstTrack3);
    R.Tracks[mstTrack1] := Track1Edit.Text; R.Tracks[mstTrack2] := Track2Edit.Text;
    R.Tracks[mstTrack3] := Track3Edit.Text;
    if (PortBox.ItemIndex >= 0) and (PortBox.ItemIndex < Length(FDevices)) then R.PortName := FDevices[PortBox.ItemIndex].Address;
    if AOperation <> cdoTrackInspect then
    begin
      if not TryStrToInt(TimeoutEdit.Text, Timeout) or (Timeout < 1) or (Timeout > 600000) then
        raise EArgumentException.Create('Timeout must be 1..600000 milliseconds.');
      R.TimeoutMs := Cardinal(Timeout);
    end;
    if AOperation = cdoTrackWrite then
    begin
      case CoercivityBox.ItemIndex of
        0: R.Coercivity := mscLow;
        1: R.Coercivity := mscHigh;
      else raise EArgumentException.Create('Select low or high coercivity.'); end;
    end;
    FSelectedTracks := R.TrackSelection;
    StartRequest(R);
  except on E: Exception do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
end;

procedure TMagStripeDemoForm.InspectClick(Sender: TObject);
begin RunOperation(cdoTrackInspect); end;

procedure TMagStripeDemoForm.ReadClick(Sender: TObject);
begin RunOperation(cdoTrackRead); end;

procedure TMagStripeDemoForm.WriteClick(Sender: TObject);
begin RunOperation(cdoTrackWrite); end;

procedure TMagStripeDemoForm.Complete(const AResult: TCardDemoResult);
var I: Integer;
begin
  if AResult.Operation = cdoDemoDevices then
  begin
    FDevices := nil; PortBox.Items.Clear; PortBox.ItemIndex := -1;
    if AResult.Success then FDevices := AResult.Devices;
    for I := 0 to High(FDevices) do
    begin
      PortBox.Items.Add(string(FDevices[I].DisplayName));
      if FDevices[I].Address = FPreviousPort then PortBox.ItemIndex := I;
    end;
    if AResult.Success then OutputMemo.Text := 'Choose the connected encoder from the available serial ports.'
    else OutputMemo.Text := 'Serial discovery failed: '+AResult.ErrorClass+'. Refresh ports to retry discovery.';
    Exit;
  end;
  OutputMemo.Lines.Text := AResult.Text;
  if not AResult.Success then
  begin
    OutputMemo.Lines.Add('Failed: ' + AResult.ErrorClass + '. No automatic retry.');
    if AResult.WriteVerified then OutputMemo.Lines.Add('Track write was verified before cleanup failed.')
    else if AResult.ErrorClass = 'EMagStripeWriteUncertain' then
      OutputMemo.Lines.Add('The write outcome is uncertain. Inspect the card before repeating.');
  end;
  if (AResult.Success or AResult.WriteVerified) and (AResult.Operation <> cdoTrackInspect) then
  begin
    if mstTrack1 in FSelectedTracks then Track1Edit.Text := AResult.Tracks[mstTrack1];
    if mstTrack2 in FSelectedTracks then Track2Edit.Text := AResult.Tracks[mstTrack2];
    if mstTrack3 in FSelectedTracks then Track3Edit.Text := AResult.Tracks[mstTrack3];
  end;
end;

procedure TMagStripeDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TMagStripeDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TMagStripeDemoForm.CloseQuery: Boolean;
begin

  Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo card operation to finish...';
end;

destructor TMagStripeDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False;
  FController.Free; inherited Destroy;
end;

procedure TMagStripeDemoForm.FormShow(Sender: TObject);
begin
  if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshPortsClick(nil);
end;

procedure TMagStripeDemoForm.RefreshPortsClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  FPreviousPort := '';
  if (PortBox.ItemIndex >= 0) and (PortBox.ItemIndex < Length(FDevices)) then FPreviousPort := FDevices[PortBox.ItemIndex].Address;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

end.
