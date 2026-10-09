unit SleCounterDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent SleCounterDemo form; all visual controls belong to its own editable DFM.</summary>
  TSleCounterDemoForm = class(TForm)
  published
    /// <summary>Reader discovery and transport guidance.</summary>
    HeaderPanel: TPanel;
    /// <summary>Native card offered/removed status, independent of operation output.</summary>
    EventStatusLabel: TLabel;
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
    /// <summary>Read explicit public window page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Read explicit public window inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Actual counter chip label.</summary>
    ActReadCountermodelLabel: TLabel;
    /// <summary>Actual counter chip.</summary>
    ActReadCountermodelBox: TComboBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActReadWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActReadWindowEdit: TEdit;
    /// <summary>Start byte / page / block (decimal) label.</summary>
    ActReadAddressLabel: TLabel;
    /// <summary>Start byte / page / block (decimal).</summary>
    ActReadAddressEdit: TEdit;
    /// <summary>Read byte count (decimal) label.</summary>
    ActReadCountLabel: TLabel;
    /// <summary>Read byte count (decimal).</summary>
    ActReadCountEdit: TEdit;
    /// <summary>Bit / carry / backup programming + verify page.</summary>
    ActWriteTab: TTabSheet;
    /// <summary>Bit / carry / backup programming + verify inputs.</summary>
    ActWriteInputs: TScrollBox;
    /// <summary>Actual counter chip label.</summary>
    ActWriteCountermodelLabel: TLabel;
    /// <summary>Actual counter chip.</summary>
    ActWriteCountermodelBox: TComboBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActWriteWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActWriteWindowEdit: TEdit;
    /// <summary>Start byte / page / block (decimal) label.</summary>
    ActWriteAddressLabel: TLabel;
    /// <summary>Start byte / page / block (decimal).</summary>
    ActWriteAddressEdit: TEdit;
    /// <summary>Requested programmed byte (hex) label.</summary>
    ActWriteValueLabel: TLabel;
    /// <summary>Requested programmed byte (hex).</summary>
    ActWriteValueEdit: TEdit;
    /// <summary>Explicit programming mode label.</summary>
    ActWriteModeLabel: TLabel;
    /// <summary>Explicit programming mode.</summary>
    ActWriteModeBox: TComboBox;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActWriteBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActWriteBeforeEdit: TEdit;
    /// <summary>Expected complete window after (hex) label.</summary>
    ActWriteAfterLabel: TLabel;
    /// <summary>Expected complete window after (hex).</summary>
    ActWriteAfterEdit: TEdit;
    /// <summary>Calculate raw certificate once page.</summary>
    ActCertificateTab: TTabSheet;
    /// <summary>Calculate raw certificate once inputs.</summary>
    ActCertificateInputs: TScrollBox;
    /// <summary>Actual counter chip label.</summary>
    ActCertificateCountermodelLabel: TLabel;
    /// <summary>Actual counter chip.</summary>
    ActCertificateCountermodelBox: TComboBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActCertificateWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActCertificateWindowEdit: TEdit;
    /// <summary>Explicit key / CBC byte (hex) label.</summary>
    ActCertificateKeyselectLabel: TLabel;
    /// <summary>Explicit key / CBC byte (hex).</summary>
    ActCertificateKeyselectEdit: TEdit;
    /// <summary>Clock pulses per bit (hex) label.</summary>
    ActCertificateClocksLabel: TLabel;
    /// <summary>Clock pulses per bit (hex).</summary>
    ActCertificateClocksEdit: TEdit;
    /// <summary>Six challenge bytes (hex) label.</summary>
    ActCertificateChallengeLabel: TLabel;
    /// <summary>Six challenge bytes (hex).</summary>
    ActCertificateChallengeEdit: TEdit;
    /// <summary>Offline code-presentation command only page.</summary>
    ActCodeframeTab: TTabSheet;
    /// <summary>Offline code-presentation command only inputs.</summary>
    ActCodeframeInputs: TScrollBox;
    /// <summary>Supplied three-byte code (hex) label.</summary>
    ActCodeframeCodeLabel: TLabel;
    /// <summary>Supplied three-byte code (hex).</summary>
    ActCodeframeCodeEdit: TEdit;
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
    FFamily: TCardDemoFamily;
    FActions: TCardFamilyActions;
    FInputs: TArray<TWinControl>;
    FCapture: TRfidKeyboardReader;
    FBusy, FDiscoveryStarted: Boolean;
    FArtifacts: TCardDemoArtifacts;
    FDevices: TCardDemoDevices;
    FPreviousAddress: UnicodeString;
    FController: TCardDemoController;
    FReaderEvents: TCardDemoReaderEvents;
    procedure ReaderInventory(const ADevices: TCardDemoDevices);
    procedure ReaderStatus(const AText: string);
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
SleCounterDemoForm: TSleCounterDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TSleCounterDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfCounter; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TSleCounterDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TSleCounterDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActReadCountermodelBox;
      FInputs[1] := ActReadWindowEdit;
      FInputs[2] := ActReadAddressEdit;
      FInputs[3] := ActReadCountEdit;
    end;
    1:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActWriteCountermodelBox;
      FInputs[1] := ActWriteWindowEdit;
      FInputs[2] := ActWriteAddressEdit;
      FInputs[3] := ActWriteValueEdit;
      FInputs[4] := ActWriteModeBox;
      FInputs[5] := ActWriteBeforeEdit;
      FInputs[6] := ActWriteAfterEdit;
    end;
    2:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActCertificateCountermodelBox;
      FInputs[1] := ActCertificateWindowEdit;
      FInputs[2] := ActCertificateKeyselectEdit;
      FInputs[3] := ActCertificateClocksEdit;
      FInputs[4] := ActCertificateChallengeEdit;
    end;
    3:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActCodeframeCodeEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TSleCounterDemoForm.ClearCredentials;
begin
  ActCodeframeCodeEdit.Clear;
end;

function TSleCounterDemoForm.Request: TCardDemoRequest;
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

procedure TSleCounterDemoForm.RunClick(Sender: TObject);
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

procedure TSleCounterDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TSleCounterDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TSleCounterDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TSleCounterDemoForm.SetBusy(const AValue: Boolean);
var I: Integer; Frozen: Boolean;
begin
  FBusy := AValue; Frozen := AValue or (FCapture <> nil);
  ActionPages.Enabled := not Frozen;
  ReaderBox.Enabled := not Frozen; RefreshReadersButton.Enabled := not Frozen;
  AcknowledgeCheck.Enabled := not Frozen and FActions[ActionPages.ActivePageIndex].Mutation;
  for I := 0 to High(FInputs) do FInputs[I].Enabled := not Frozen;
  RunButton.Enabled := not AValue;
  ArtifactBox.Enabled := not Frozen; SaveButton.Enabled := not Frozen and (Length(FArtifacts) > 0);
end;

procedure TSleCounterDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TSleCounterDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TSleCounterDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TSleCounterDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TSleCounterDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TSleCounterDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var I: Integer; Previous: UnicodeString;
begin
  Previous := SelectedAddress;
  if Previous = '' then Previous := FPreviousAddress;
  FDevices := Copy(ADevices,0,Length(ADevices)); ReaderBox.Items.Clear; ReaderBox.ItemIndex := -1;
  for I := 0 to High(FDevices) do
  begin
    ReaderBox.Items.Add(string(FDevices[I].DisplayName));
    if FDevices[I].Address = Previous then ReaderBox.ItemIndex := I;
  end;
  ReaderChanged(nil);
end;

procedure TSleCounterDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TSleCounterDemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TSleCounterDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TSleCounterDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TSleCounterDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TSleCounterDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
