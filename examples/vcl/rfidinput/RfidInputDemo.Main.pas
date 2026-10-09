unit RfidInputDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent RfidInputDemo form; all visual controls belong to its own editable DFM.</summary>
  TRfidInputDemoForm = class(TForm)
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
    /// <summary>Decode presented text page.</summary>
    ActTextTab: TTabSheet;
    /// <summary>Decode presented text inputs.</summary>
    ActTextInputs: TScrollBox;
    /// <summary>Reader-presented identifier label.</summary>
    ActTextTextLabel: TLabel;
    /// <summary>Reader-presented identifier.</summary>
    ActTextTextEdit: TEdit;
    /// <summary>Actual output encoding label.</summary>
    ActTextEncodingLabel: TLabel;
    /// <summary>Actual output encoding.</summary>
    ActTextEncodingBox: TComboBox;
    /// <summary>Exact identifier characters; 0 = variable label.</summary>
    ActTextExpectedLabel: TLabel;
    /// <summary>Exact identifier characters; 0 = variable.</summary>
    ActTextExpectedEdit: TEdit;
    /// <summary>Explicit numeric byte width; 0 = no conversion label.</summary>
    ActTextWidthLabel: TLabel;
    /// <summary>Explicit numeric byte width; 0 = no conversion.</summary>
    ActTextWidthEdit: TEdit;
    /// <summary>Explicit numeric byte order label.</summary>
    ActTextOrderLabel: TLabel;
    /// <summary>Explicit numeric byte order.</summary>
    ActTextOrderBox: TComboBox;
    /// <summary>Live foreground keyboard capture page.</summary>
    ActKeyboardTab: TTabSheet;
    /// <summary>Live foreground keyboard capture inputs.</summary>
    ActKeyboardInputs: TScrollBox;
    /// <summary>Actual output encoding label.</summary>
    ActKeyboardEncodingLabel: TLabel;
    /// <summary>Actual output encoding.</summary>
    ActKeyboardEncodingBox: TComboBox;
    /// <summary>Actual delimiter label.</summary>
    ActKeyboardTerminatorLabel: TLabel;
    /// <summary>Actual delimiter.</summary>
    ActKeyboardTerminatorBox: TComboBox;
    /// <summary>Exact identifier characters; 0 = variable label.</summary>
    ActKeyboardExpectedLabel: TLabel;
    /// <summary>Exact identifier characters; 0 = variable.</summary>
    ActKeyboardExpectedEdit: TEdit;
    /// <summary>Inter-character gap budget (ms) label.</summary>
    ActKeyboardGapLabel: TLabel;
    /// <summary>Inter-character gap budget (ms).</summary>
    ActKeyboardGapEdit: TEdit;
    /// <summary>Exact prefix label.</summary>
    ActKeyboardPrefixLabel: TLabel;
    /// <summary>Exact prefix.</summary>
    ActKeyboardPrefixEdit: TEdit;
    /// <summary>Exact suffix label.</summary>
    ActKeyboardSuffixLabel: TLabel;
    /// <summary>Exact suffix.</summary>
    ActKeyboardSuffixEdit: TEdit;
    /// <summary>Decode host-provided HID reports page.</summary>
    ActReportsTab: TTabSheet;
    /// <summary>Decode host-provided HID reports inputs.</summary>
    ActReportsInputs: TScrollBox;
    /// <summary>Actual output encoding label.</summary>
    ActReportsEncodingLabel: TLabel;
    /// <summary>Actual output encoding.</summary>
    ActReportsEncodingBox: TComboBox;
    /// <summary>Actual delimiter label.</summary>
    ActReportsTerminatorLabel: TLabel;
    /// <summary>Actual delimiter.</summary>
    ActReportsTerminatorBox: TComboBox;
    /// <summary>Exact identifier characters; 0 = variable label.</summary>
    ActReportsExpectedLabel: TLabel;
    /// <summary>Exact identifier characters; 0 = variable.</summary>
    ActReportsExpectedEdit: TEdit;
    /// <summary>Inter-character gap budget (ms) label.</summary>
    ActReportsGapLabel: TLabel;
    /// <summary>Inter-character gap budget (ms).</summary>
    ActReportsGapEdit: TEdit;
    /// <summary>Exact prefix label.</summary>
    ActReportsPrefixLabel: TLabel;
    /// <summary>Exact prefix.</summary>
    ActReportsPrefixEdit: TEdit;
    /// <summary>Exact suffix label.</summary>
    ActReportsSuffixLabel: TLabel;
    /// <summary>Exact suffix.</summary>
    ActReportsSuffixEdit: TEdit;
    /// <summary>Actual report format label.</summary>
    ActReportsKindLabel: TLabel;
    /// <summary>Actual report format.</summary>
    ActReportsKindBox: TComboBox;
    /// <summary>Explicit report ID (decimal) label.</summary>
    ActReportsReportidLabel: TLabel;
    /// <summary>Explicit report ID (decimal).</summary>
    ActReportsReportidEdit: TEdit;
    /// <summary>Initial codec caps lock label.</summary>
    ActReportsCapsLabel: TLabel;
    /// <summary>Initial codec caps lock.</summary>
    ActReportsCapsBox: TComboBox;
    /// <summary>Exact fixed-field report bytes label.</summary>
    ActReportsReportbytesLabel: TLabel;
    /// <summary>Exact fixed-field report bytes.</summary>
    ActReportsReportbytesEdit: TEdit;
    /// <summary>Fixed-field zero-based offset label.</summary>
    ActReportsOffsetLabel: TLabel;
    /// <summary>Fixed-field zero-based offset.</summary>
    ActReportsOffsetEdit: TEdit;
    /// <summary>Fixed-field width label.</summary>
    ActReportsFieldbytesLabel: TLabel;
    /// <summary>Fixed-field width.</summary>
    ActReportsFieldbytesEdit: TEdit;
    /// <summary>Fixed-field report ID present label.</summary>
    ActReportsHasidLabel: TLabel;
    /// <summary>Fixed-field report ID present.</summary>
    ActReportsHasidBox: TComboBox;
    /// <summary>Fixed-field trailing padding label.</summary>
    ActReportsPaddingLabel: TLabel;
    /// <summary>Fixed-field trailing padding.</summary>
    ActReportsPaddingBox: TComboBox;
    /// <summary>Complete reports (hex), separated by semicolon label.</summary>
    ActReportsReportsLabel: TLabel;
    /// <summary>Complete reports (hex), separated by semicolon.</summary>
    ActReportsReportsEdit: TEdit;
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
RfidInputDemoForm: TRfidInputDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TRfidInputDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfRfid; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkHid,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  ActionChanged(nil);
end;

destructor TRfidInputDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TRfidInputDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActTextTextEdit;
      FInputs[1] := ActTextEncodingBox;
      FInputs[2] := ActTextExpectedEdit;
      FInputs[3] := ActTextWidthEdit;
      FInputs[4] := ActTextOrderBox;
    end;
    1:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActKeyboardEncodingBox;
      FInputs[1] := ActKeyboardTerminatorBox;
      FInputs[2] := ActKeyboardExpectedEdit;
      FInputs[3] := ActKeyboardGapEdit;
      FInputs[4] := ActKeyboardPrefixEdit;
      FInputs[5] := ActKeyboardSuffixEdit;
    end;
    2:
    begin
      SetLength(FInputs,15);
      FInputs[0] := ActReportsEncodingBox;
      FInputs[1] := ActReportsTerminatorBox;
      FInputs[2] := ActReportsExpectedEdit;
      FInputs[3] := ActReportsGapEdit;
      FInputs[4] := ActReportsPrefixEdit;
      FInputs[5] := ActReportsSuffixEdit;
      FInputs[6] := ActReportsKindBox;
      FInputs[7] := ActReportsReportidEdit;
      FInputs[8] := ActReportsCapsBox;
      FInputs[9] := ActReportsReportbytesEdit;
      FInputs[10] := ActReportsOffsetEdit;
      FInputs[11] := ActReportsFieldbytesEdit;
      FInputs[12] := ActReportsHasidBox;
      FInputs[13] := ActReportsPaddingBox;
      FInputs[14] := ActReportsReportsEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TRfidInputDemoForm.ClearCredentials;
begin
end;

function TRfidInputDemoForm.Request: TCardDemoRequest;
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

procedure TRfidInputDemoForm.RunClick(Sender: TObject);
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

procedure TRfidInputDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TRfidInputDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TRfidInputDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TRfidInputDemoForm.SetBusy(const AValue: Boolean);
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

procedure TRfidInputDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TRfidInputDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TRfidInputDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TRfidInputDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TRfidInputDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TRfidInputDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TRfidInputDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TRfidInputDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TRfidInputDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TRfidInputDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
