unit FelicaDemo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent FelicaDemo form; all visual controls belong to its own editable DFM.</summary>
  TFelicaDemoForm = class(TForm)
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
    /// <summary>Fresh FeliCa target information page.</summary>
    ActTargetTab: TTabSheet;
    /// <summary>Fresh FeliCa target information inputs.</summary>
    ActTargetInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActTargetBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActTargetBitrateBox: TComboBox;
    /// <summary>System code (decimal; 65535 = any) label.</summary>
    ActTargetSystemLabel: TLabel;
    /// <summary>System code (decimal; 65535 = any).</summary>
    ActTargetSystemEdit: TEdit;
    /// <summary>Read explicit unencrypted service blocks page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Read explicit unencrypted service blocks inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActReadBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActReadBitrateBox: TComboBox;
    /// <summary>System code (decimal; 65535 = any) label.</summary>
    ActReadSystemLabel: TLabel;
    /// <summary>System code (decimal; 65535 = any).</summary>
    ActReadSystemEdit: TEdit;
    /// <summary>Read service code (decimal) label.</summary>
    ActReadReadserviceLabel: TLabel;
    /// <summary>Read service code (decimal).</summary>
    ActReadReadserviceEdit: TEdit;
    /// <summary>First block number (decimal, including 16-bit addresses) label.</summary>
    ActReadFirstblockLabel: TLabel;
    /// <summary>First block number (decimal, including 16-bit addresses).</summary>
    ActReadFirstblockEdit: TEdit;
    /// <summary>Contiguous block count label.</summary>
    ActReadCountLabel: TLabel;
    /// <summary>Contiguous block count.</summary>
    ActReadCountEdit: TEdit;
    /// <summary>Write explicit service blocks + independent verification page.</summary>
    ActWriteTab: TTabSheet;
    /// <summary>Write explicit service blocks + independent verification inputs.</summary>
    ActWriteInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActWriteBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActWriteBitrateBox: TComboBox;
    /// <summary>System code (decimal; 65535 = any) label.</summary>
    ActWriteSystemLabel: TLabel;
    /// <summary>System code (decimal; 65535 = any).</summary>
    ActWriteSystemEdit: TEdit;
    /// <summary>Write service code (decimal) label.</summary>
    ActWriteWriteserviceLabel: TLabel;
    /// <summary>Write service code (decimal).</summary>
    ActWriteWriteserviceEdit: TEdit;
    /// <summary>Verification read service code (decimal) label.</summary>
    ActWriteReadserviceLabel: TLabel;
    /// <summary>Verification read service code (decimal).</summary>
    ActWriteReadserviceEdit: TEdit;
    /// <summary>First block number (decimal, including 16-bit addresses) label.</summary>
    ActWriteFirstblockLabel: TLabel;
    /// <summary>First block number (decimal, including 16-bit addresses).</summary>
    ActWriteFirstblockEdit: TEdit;
    /// <summary>Contiguous block count label.</summary>
    ActWriteCountLabel: TLabel;
    /// <summary>Contiguous block count.</summary>
    ActWriteCountEdit: TEdit;
    /// <summary>Exact current block preimage (hex) label.</summary>
    ActWriteBeforeLabel: TLabel;
    /// <summary>Exact current block preimage (hex).</summary>
    ActWriteBeforeEdit: TEdit;
    /// <summary>Replacement block bytes (16 per block, hex) label.</summary>
    ActWriteDataLabel: TLabel;
    /// <summary>Replacement block bytes (16 per block, hex).</summary>
    ActWriteDataEdit: TEdit;
    /// <summary>Read Type 3 attribute information page.</summary>
    ActAttributeTab: TTabSheet;
    /// <summary>Read Type 3 attribute information inputs.</summary>
    ActAttributeInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActAttributeBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActAttributeBitrateBox: TComboBox;
    /// <summary>Read and parse Type 3 NDEF page.</summary>
    ActReadndefTab: TTabSheet;
    /// <summary>Read and parse Type 3 NDEF inputs.</summary>
    ActReadndefInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActReadndefBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActReadndefBitrateBox: TComboBox;
    /// <summary>Replace/clear Type 3 NDEF + verify page.</summary>
    ActWritendefTab: TTabSheet;
    /// <summary>Replace/clear Type 3 NDEF + verify inputs.</summary>
    ActWritendefInputs: TScrollBox;
    /// <summary>Explicit FeliCa bitrate label.</summary>
    ActWritendefBitrateLabel: TLabel;
    /// <summary>Explicit FeliCa bitrate.</summary>
    ActWritendefBitrateBox: TComboBox;
    /// <summary>Exact sixteen-byte attribute preimage (hex) label.</summary>
    ActWritendefBeforeLabel: TLabel;
    /// <summary>Exact sixteen-byte attribute preimage (hex).</summary>
    ActWritendefBeforeEdit: TEdit;
    /// <summary>Complete NDEF bytes (hex; empty clears message) label.</summary>
    ActWritendefNdefLabel: TLabel;
    /// <summary>Complete NDEF bytes (hex; empty clears message).</summary>
    ActWritendefNdefEdit: TEdit;
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
FelicaDemoForm: TFelicaDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TFelicaDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfFelica; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TFelicaDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TFelicaDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActTargetBitrateBox;
      FInputs[1] := ActTargetSystemEdit;
    end;
    1:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActReadBitrateBox;
      FInputs[1] := ActReadSystemEdit;
      FInputs[2] := ActReadReadserviceEdit;
      FInputs[3] := ActReadFirstblockEdit;
      FInputs[4] := ActReadCountEdit;
    end;
    2:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActWriteBitrateBox;
      FInputs[1] := ActWriteSystemEdit;
      FInputs[2] := ActWriteWriteserviceEdit;
      FInputs[3] := ActWriteReadserviceEdit;
      FInputs[4] := ActWriteFirstblockEdit;
      FInputs[5] := ActWriteCountEdit;
      FInputs[6] := ActWriteBeforeEdit;
      FInputs[7] := ActWriteDataEdit;
    end;
    3:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActAttributeBitrateBox;
    end;
    4:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActReadndefBitrateBox;
    end;
    5:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActWritendefBitrateBox;
      FInputs[1] := ActWritendefBeforeEdit;
      FInputs[2] := ActWritendefNdefEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TFelicaDemoForm.ClearCredentials;
begin
end;

function TFelicaDemoForm.Request: TCardDemoRequest;
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

procedure TFelicaDemoForm.RunClick(Sender: TObject);
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

procedure TFelicaDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TFelicaDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TFelicaDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TFelicaDemoForm.SetBusy(const AValue: Boolean);
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

procedure TFelicaDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TFelicaDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TFelicaDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TFelicaDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TFelicaDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TFelicaDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TFelicaDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TFelicaDemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TFelicaDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TFelicaDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TFelicaDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TFelicaDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
