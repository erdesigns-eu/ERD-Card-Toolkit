unit UsbHidDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.HID.Monitor, ERD.Card.HID, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent UsbHidDemo form; all visual controls belong to its own editable DFM.</summary>
  TUsbHidDemoForm = class(TForm)
  published
    /// <summary>Start native reader arrival/removal notifications without a polling loop.</summary>
    WatchButton: TButton;
    /// <summary>Stop observation and discard pending notifications.</summary>
    StopWatchButton: TButton;
    /// <summary>Persistent bounded event log, separate from operation results.</summary>
    EventsMemo: TMemo;
    /// <summary>Start event observation; no card is automatically connected or written.</summary>
    /// <param name="Sender">This form's own DFM button.</param>
    procedure WatchClick(Sender: TObject);
    /// <summary>Stop native observation before reconfiguration or form destruction.</summary>
    /// <param name="Sender">This form's own DFM button.</param>
    procedure StopWatchClick(Sender: TObject);
  published
    /// <summary>Start read-only interrupt report events for this demo's selected collection.</summary>
    ListenButton: TButton;
    /// <summary>Starts explicit read-only input, disabling conflicting one-shot operations.</summary>
    /// <param name="Sender">This form's own DFM button.</param>
    procedure ListenClick(Sender: TObject);
  published
    /// <summary>Reader discovery and transport guidance.</summary>
    HeaderPanel: TPanel;
    /// <summary>Explicit operation guidance.</summary>
    GuidanceLabel: TLabel;
    /// <summary>Available device transport.</summary>
    ReaderLabel: TLabel;
    /// <summary>Discovered devices; the selection retains its exact backend address.</summary>
    ReaderBox: TComboBox;
    /// <summary>Refresh this demo’s device list without connecting a card.</summary>
    RefreshReadersButton: TButton;
    /// <summary>Own DFM pages for every implemented action.</summary>
    ActionPages: TPageControl;
    /// <summary>Run, capture, output and export controls.</summary>
    BottomPanel: TPanel;
    /// <summary>Explicit authorization of the selected mutation or credential attempt.</summary>
    AcknowledgeCheck: TCheckBox;
    /// <summary>Execute the selected action on the background worker.</summary>
    RunButton: TButton;
    /// <summary>Foreground keyboard capture, only used by the RFID input demo.</summary>
    CaptureInputMemo: TMemo;
    /// <summary>Acquired files available for explicit export.</summary>
    ArtifactBox: TComboBox;
    /// <summary>Save only the selected successfully acquired artifact.</summary>
    SaveButton: TButton;
    /// <summary>Sanitized results and explicit verification status.</summary>
    OutputMemo: TMemo;
    /// <summary>JPEG preview of a successfully acquired photo.</summary>
    PhotoImage: TImage;
    /// <summary>Native save dialog owned by this individual form.</summary>
    ExportDialog: TSaveDialog;
    /// <summary>Own DFM timer polling the nonvisual worker controller.</summary>
    WorkerTimer: TTimer;
    /// <summary>Enumerate descriptor / VID / PID / usage / lengths page.</summary>
    ActDevicesTab: TTabSheet;
    /// <summary>Enumerate descriptor / VID / PID / usage / lengths inputs.</summary>
    ActDevicesInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActDevicesInfo: TLabel;
    /// <summary>Receive complete report + export page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Receive complete report + export inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Explicit report endpoint label.</summary>
    ActReadKindLabel: TLabel;
    /// <summary>Explicit report endpoint.</summary>
    ActReadKindBox: TComboBox;
    /// <summary>Interrupt wait budget (ms) label.</summary>
    ActReadTimeoutLabel: TLabel;
    /// <summary>Interrupt wait budget (ms).</summary>
    ActReadTimeoutEdit: TEdit;
    /// <summary>Exact expected report ID (decimal) label.</summary>
    ActReadReportidLabel: TLabel;
    /// <summary>Exact expected report ID (decimal).</summary>
    ActReadReportidEdit: TEdit;
    /// <summary>Submit exact output / feature report once page.</summary>
    ActSendTab: TTabSheet;
    /// <summary>Submit exact output / feature report once inputs.</summary>
    ActSendInputs: TScrollBox;
    /// <summary>Explicit report endpoint label.</summary>
    ActSendKindLabel: TLabel;
    /// <summary>Explicit report endpoint.</summary>
    ActSendKindBox: TComboBox;
    /// <summary>Interrupt wait budget (ms) label.</summary>
    ActSendTimeoutLabel: TLabel;
    /// <summary>Interrupt wait budget (ms).</summary>
    ActSendTimeoutEdit: TEdit;
    /// <summary>Complete descriptor-sized report including ID (hex) label.</summary>
    ActSendReportLabel: TLabel;
    /// <summary>Complete descriptor-sized report including ID (hex).</summary>
    ActSendReportEdit: TEdit;
    /// <summary>Select this form’s own action page.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure ActionChanged(Sender: TObject);
    /// <summary>Discover available devices inside this demo.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RefreshReadersClick(Sender: TObject);
    /// <summary>Expose the selected backend address as a hint.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure ReaderChanged(Sender: TObject);
    /// <summary>Start initial background device discovery once.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormShow(Sender: TObject);
    /// <summary>Poll this form’s own worker from its DFM timer.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure PollTimer(Sender: TObject);
    /// <summary>Start the explicitly selected operation.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RunClick(Sender: TObject);
    /// <summary>Preview the selected acquired JPEG.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure PreviewArtifact(Sender: TObject);
    /// <summary>Save the chosen acquired artifact after a native dialog.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SaveArtifact(Sender: TObject);
    /// <summary>Feeds foreground keyboard characters to the explicit capture profile.</summary>
    /// <param name="Sender">This form’s own capture memo.</param>
    /// <param name="Key">Character consumed by the capture adapter.</param>
    procedure CaptureKey(Sender: TObject; var Key: Char);
  private
    FMonitor: THidDeviceMonitor;
    FInputMonitor: TUsbHidInputMonitor;
    FRefreshPending: Boolean;
    procedure DeviceAdded(Sender: TObject; const Path: UnicodeString);
    procedure DeviceRemoved(Sender: TObject; const Path: UnicodeString);
    procedure InputReport(Sender: TObject; const Report: TBytes);
    procedure InputError(Sender: TObject);
    procedure LogEvent(const Text: string);
  private
    FFamily: TCardDemoFamily;
    FActions: TCardFamilyActions;
    FInputs: TArray<TWinControl>;
    FCapture: TRfidKeyboardReader;
    FBusy, FDiscoveryStarted: Boolean;
    FArtifacts: TCardDemoArtifacts;
    FDevices: TCardDemoDevices;
    FPreviousAddress: UnicodeString;
    FController: TCardDemoController;
    function SelectedAddress: UnicodeString;
    procedure Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
    procedure StopCapture;
    function Request: TCardDemoRequest;
    procedure ClearCredentials;
    procedure SetBusy(const AValue: Boolean);
    procedure Complete(const AResult: TCardDemoResult);
    procedure StartRequest(const ARequest: TCardDemoRequest);
  protected
    /// <summary>Defers window closing until the owned worker completes, stopping foreground capture first.</summary>
    /// <returns>Inherited close permission only when this demo has no active job.</returns>
    function CloseQuery: Boolean; override;
  public
    /// <summary>Loads this demo’s own DFM, binds existing inputs and creates an inactive nonvisual controller.</summary>
    /// <param name="AOwner">Optional VCL form owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Stops capture and its own DFM timer, then joins the owned job before controls are destroyed.</summary>
    destructor Destroy; override;
  end;

var
  /// <summary>Application-owned instance of this independent form.</summary>
UsbHidDemoForm: TUsbHidDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

procedure TUsbHidDemoForm.LogEvent(const Text: string);
begin
  while EventsMemo.Lines.Count >= 1000 do EventsMemo.Lines.Delete(0);
  EventsMemo.Lines.Add(Text);
end;
procedure TUsbHidDemoForm.WatchClick(Sender: TObject);
begin
  try FMonitor.Start; WatchButton.Enabled := False; StopWatchButton.Enabled := True;
    LogEvent('Native reader notifications active.');
  except on E: Exception do LogEvent('Observation could not start: '+E.ClassName+'.'); end;
end;
procedure TUsbHidDemoForm.StopWatchClick(Sender: TObject);
begin
  FMonitor.Stop;
  FInputMonitor.Stop; SetBusy(FBusy);
  WatchButton.Enabled := True; StopWatchButton.Enabled := False;
end;
procedure TUsbHidDemoForm.DeviceAdded(Sender: TObject; const Path: UnicodeString);
begin LogEvent('HID connected: '+string(Path)); FRefreshPending := True; end;
procedure TUsbHidDemoForm.DeviceRemoved(Sender: TObject; const Path: UnicodeString);
begin
  LogEvent('HID disconnected: '+string(Path)); FRefreshPending := True;
  if Path=SelectedAddress then begin FInputMonitor.Stop; SetBusy(FBusy); end;
end;
procedure TUsbHidDemoForm.ListenClick(Sender: TObject);
begin
  if FBusy or FInputMonitor.Active then Exit;
  try
    FInputMonitor.Device := CreateWindowsHidReportDevice(SelectedAddress);
    FInputMonitor.Start; StopWatchButton.Enabled := True; SetBusy(False);
    LogEvent('Read-only interrupt input active; Windows may reserve keyboard collections.');
  except on E: Exception do LogEvent('Input could not start: '+E.ClassName+'.'); end;
end;
procedure TUsbHidDemoForm.InputReport(Sender: TObject; const Report: TBytes);
begin LogEvent('Input report: '+BytesToHex(Report)); end;
procedure TUsbHidDemoForm.InputError(Sender: TObject);
begin
  SetBusy(False); StopWatchButton.Enabled := FMonitor.Active;
  LogEvent('Input stopped after acquisition/descriptor/transfer failure.');
end;

constructor TUsbHidDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfNativeHid; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkHid,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FMonitor := THidDeviceMonitor.Create(nil);
  FMonitor.OnDeviceAdded := DeviceAdded; FMonitor.OnDeviceRemoved := DeviceRemoved;
  FInputMonitor := TUsbHidInputMonitor.Create(nil);
  FInputMonitor.OnInputReport := InputReport; FInputMonitor.OnError := InputError;
  ActionChanged(nil);
end;

destructor TUsbHidDemoForm.Destroy;
begin
  FInputMonitor.Free; FMonitor.Free;
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TUsbHidDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) or FInputMonitor.Active then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,0);
    end;
    1:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActReadKindBox;
      FInputs[2] := ActReadTimeoutEdit;
      FInputs[3] := ActReadReportidEdit;
    end;
    2:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActSendKindBox;
      FInputs[2] := ActSendTimeoutEdit;
      FInputs[3] := ActSendReportEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TUsbHidDemoForm.ClearCredentials;
begin
end;

function TUsbHidDemoForm.Request: TCardDemoRequest;
var I: Integer;
begin
  Result := Default(TCardDemoRequest);
  if ActionPages.ActivePageIndex < 0 then raise EArgumentException.Create('Select an action.');
  Result.Operation := cdoFamily; Result.FamilyName := CardFamilyName(FFamily);
  Result.FamilyAction := ActionPages.ActivePageIndex; Result.ReaderName := SelectedAddress;
  Result.MutationAcknowledged := AcknowledgeCheck.Checked;
  SetLength(Result.Arguments,Length(FInputs)); SetLength(Result.Credentials,Length(FInputs));
  try
    for I := 0 to High(FInputs) do
      if FInputs[I] = ReaderBox then Result.Arguments[I] := SelectedAddress
      else if FInputs[I] is TComboBox then
        Result.Arguments[I] := IntToStr(TComboBox(FInputs[I]).ItemIndex)
      else if FActions[ActionPages.ActivePageIndex].Fields[I].Secret then
        Result.Credentials[I] := HexToBytes(TEdit(FInputs[I]).Text)
      else Result.Arguments[I] := TEdit(FInputs[I]).Text;
  except
    for I := 0 to High(Result.Credentials) do TCardCrypto.Clear(Result.Credentials[I]);
    raise;
  end;
end;

procedure TUsbHidDemoForm.RunClick(Sender: TObject);
var R: TCardDemoRequest; I: Integer;
begin
  if FCapture <> nil then begin StopCapture; Exit; end;
  R := Default(TCardDemoRequest);
  try
    try
      R := Request;
      if (FFamily = dfRfid) and (FActions[ActionPages.ActivePageIndex].Id = 'keyboard') then
      begin
        FCapture := CreateCardFamilyRfidCapture(R);
        try FCapture.OnIdentifier := Identifier; FCapture.Start;
        except FreeAndNil(FCapture); raise; end;
        SetBusy(False); CaptureInputMemo.Enabled := True; CaptureInputMemo.SetFocus;
        RunButton.Caption := 'Stop capture';
        OutputMemo.Text := 'Capture active. Use the reader actual delimiter; Enter emits CR. No USB device is opened.';
      end else begin OutputMemo.Clear; StartRequest(R); end;
    except
      on E: Exception do OutputMemo.Text := 'Operation refused / failed: ' + E.ClassName + '. Check the inputs; no automatic retry.';
    end;
  finally
    for I := 0 to High(R.Credentials) do TCardCrypto.Clear(R.Credentials[I]);
    ClearCredentials; AcknowledgeCheck.Checked := False;
  end;
end;

procedure TUsbHidDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TUsbHidDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TUsbHidDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TUsbHidDemoForm.SetBusy(const AValue: Boolean);
var I: Integer; Frozen: Boolean;
begin
  FBusy := AValue; Frozen := AValue or (FCapture <> nil) or FInputMonitor.Active;
  ActionPages.Enabled := not Frozen;
  ReaderBox.Enabled := not Frozen; RefreshReadersButton.Enabled := not Frozen;
  AcknowledgeCheck.Enabled := not Frozen and FActions[ActionPages.ActivePageIndex].Mutation;
  for I := 0 to High(FInputs) do FInputs[I].Enabled := not Frozen;
  RunButton.Enabled := not AValue and not FInputMonitor.Active;
  ListenButton.Enabled := not Frozen;
  ArtifactBox.Enabled := not Frozen; SaveButton.Enabled := not Frozen and (Length(FArtifacts) > 0);
end;

procedure TUsbHidDemoForm.Complete(const AResult: TCardDemoResult);
var I: Integer;
begin
  if AResult.Operation = cdoDemoDevices then
  begin
    FDevices := nil; ReaderBox.Items.Clear; ReaderBox.ItemIndex := -1;
    if AResult.Success then FDevices := AResult.Devices;
    for I := 0 to High(FDevices) do
    begin
      ReaderBox.Items.Add(string(FDevices[I].DisplayName));
      if FDevices[I].Address = FPreviousAddress then ReaderBox.ItemIndex := I;
    end;
    ReaderChanged(nil);
    if AResult.Success then OutputMemo.Text := 'Found '+IntToStr(Length(FDevices))+' devices. Choose the connected reader/writer in this demo.'
    else OutputMemo.Text := 'Device discovery failed: '+AResult.ErrorClass+'. Use Refresh devices to try discovery again.';
    Exit;
  end;
  PhotoImage.Picture.Assign(nil); FArtifacts := nil; ArtifactBox.Items.Clear; SaveButton.Enabled := False;
  if AResult.Success then FArtifacts := AResult.Artifacts;
  for I := 0 to High(FArtifacts) do ArtifactBox.Items.Add(FArtifacts[I].Name);
  if Length(FArtifacts) > 0 then begin ArtifactBox.ItemIndex := 0; SaveButton.Enabled := True; end;
  OutputMemo.Text := AResult.Text;
  for I := 0 to High(AResult.Readers) do OutputMemo.Lines.Add(AResult.Readers[I]);
  if AResult.WriteVerified then OutputMemo.Lines.Add('Independent verification completed.');
  if AResult.WriteUncertain then OutputMemo.Lines.Add('WRITE OUTCOME / CLEANUP UNCERTAIN. Inspect the card; do not repeat automatically.');
  if not AResult.Success then OutputMemo.Lines.Add('Operation failed: ' + AResult.ErrorClass + '. No automatic retry.');
  PreviewArtifact(nil);
end;

procedure TUsbHidDemoForm.PreviewArtifact(Sender: TObject);
var Index: Integer; Stream: TBytesStream; Jpeg: TJPEGImage;
begin
  PhotoImage.Picture.Assign(nil); Index := ArtifactBox.ItemIndex;
  if not PhotoImage.Visible or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  if not SameText(ExtractFileExt(FArtifacts[Index].Name),'.jpg') then Exit;
  Stream := TBytesStream.Create(FArtifacts[Index].Data); Jpeg := nil;
  try
    Jpeg := TJPEGImage.Create;
    try Jpeg.LoadFromStream(Stream); PhotoImage.Picture.Assign(Jpeg);
    except on E: Exception do OutputMemo.Lines.Add('Image preview failed: '+E.ClassName+'. Exact file export remains available.'); end;
  finally Jpeg.Free; Stream.Free; end;
end;

procedure TUsbHidDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TUsbHidDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TUsbHidDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TUsbHidDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) or FInputMonitor.Active then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TUsbHidDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TUsbHidDemoForm.PollTimer(Sender: TObject);
begin
  if FController <> nil then FController.Poll;
  if FRefreshPending and not FBusy and not FInputMonitor.Active then begin
    FRefreshPending := False; RefreshReadersClick(nil);
  end;
end;

procedure TUsbHidDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TUsbHidDemoForm.CloseQuery: Boolean;
begin
  FInputMonitor.Stop; FMonitor.Stop; StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
