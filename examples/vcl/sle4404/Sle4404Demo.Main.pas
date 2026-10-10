unit Sle4404Demo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent Sle4404Demo form; all visual controls belong to its own editable DFM.</summary>
  TSle4404DemoForm = class(TForm)
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
    /// <summary>Public / supplied-code memory read page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Public / supplied-code memory read inputs.</summary>
    ActReadInputs: TScrollBox;
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
    /// <summary>User counter address (decimal) label.</summary>
    ActReadUsercounterLabel: TLabel;
    /// <summary>User counter address (decimal).</summary>
    ActReadUsercounterEdit: TEdit;
    /// <summary>Four-bit user counter mask (hex) label.</summary>
    ActReadUsermaskLabel: TLabel;
    /// <summary>Four-bit user counter mask (hex).</summary>
    ActReadUsermaskEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActReadAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActReadAttemptsEdit: TEdit;
    /// <summary>Supplied PIN / user code (hex) label.</summary>
    ActReadPinLabel: TLabel;
    /// <summary>Supplied PIN / user code (hex).</summary>
    ActReadPinEdit: TEdit;
    /// <summary>Verify supplied user code once page.</summary>
    ActVerifyTab: TTabSheet;
    /// <summary>Verify supplied user code once inputs.</summary>
    ActVerifyInputs: TScrollBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActVerifyWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActVerifyWindowEdit: TEdit;
    /// <summary>User counter address (decimal) label.</summary>
    ActVerifyUsercounterLabel: TLabel;
    /// <summary>User counter address (decimal).</summary>
    ActVerifyUsercounterEdit: TEdit;
    /// <summary>Four-bit user counter mask (hex) label.</summary>
    ActVerifyUsermaskLabel: TLabel;
    /// <summary>Four-bit user counter mask (hex).</summary>
    ActVerifyUsermaskEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActVerifyAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActVerifyAttemptsEdit: TEdit;
    /// <summary>Supplied PIN / user code (hex) label.</summary>
    ActVerifyPinLabel: TLabel;
    /// <summary>Supplied PIN / user code (hex).</summary>
    ActVerifyPinEdit: TEdit;
    /// <summary>One-to-zero programming + verify page.</summary>
    ActProgramTab: TTabSheet;
    /// <summary>One-to-zero programming + verify inputs.</summary>
    ActProgramInputs: TScrollBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActProgramWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActProgramWindowEdit: TEdit;
    /// <summary>Start byte / page / block (decimal) label.</summary>
    ActProgramAddressLabel: TLabel;
    /// <summary>Start byte / page / block (decimal).</summary>
    ActProgramAddressEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActProgramBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActProgramBeforeEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActProgramDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActProgramDataEdit: TEdit;
    /// <summary>User counter address (decimal) label.</summary>
    ActProgramUsercounterLabel: TLabel;
    /// <summary>User counter address (decimal).</summary>
    ActProgramUsercounterEdit: TEdit;
    /// <summary>Four-bit user counter mask (hex) label.</summary>
    ActProgramUsermaskLabel: TLabel;
    /// <summary>Four-bit user counter mask (hex).</summary>
    ActProgramUsermaskEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActProgramAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActProgramAttemptsEdit: TEdit;
    /// <summary>Supplied PIN / user code (hex) label.</summary>
    ActProgramPinLabel: TLabel;
    /// <summary>Supplied PIN / user code (hex).</summary>
    ActProgramPinEdit: TEdit;
    /// <summary>Explicit scratchpad erase + verify page.</summary>
    ActScratchTab: TTabSheet;
    /// <summary>Explicit scratchpad erase + verify inputs.</summary>
    ActScratchInputs: TScrollBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActScratchWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActScratchWindowEdit: TEdit;
    /// <summary>Known scratchpad address label.</summary>
    ActScratchScratchaddressLabel: TLabel;
    /// <summary>Known scratchpad address.</summary>
    ActScratchScratchaddressEdit: TEdit;
    /// <summary>Known scratchpad bytes label.</summary>
    ActScratchScratchbytesLabel: TLabel;
    /// <summary>Known scratchpad bytes.</summary>
    ActScratchScratchbytesEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActScratchBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActScratchBeforeEdit: TEdit;
    /// <summary>User counter address (decimal) label.</summary>
    ActScratchUsercounterLabel: TLabel;
    /// <summary>User counter address (decimal).</summary>
    ActScratchUsercounterEdit: TEdit;
    /// <summary>Four-bit user counter mask (hex) label.</summary>
    ActScratchUsermaskLabel: TLabel;
    /// <summary>Four-bit user counter mask (hex).</summary>
    ActScratchUsermaskEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActScratchAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActScratchAttemptsEdit: TEdit;
    /// <summary>Supplied PIN / user code (hex) label.</summary>
    ActScratchPinLabel: TLabel;
    /// <summary>Supplied PIN / user code (hex).</summary>
    ActScratchPinEdit: TEdit;
    /// <summary>Explicit application erase using both codes page.</summary>
    ActApplicationTab: TTabSheet;
    /// <summary>Explicit application erase using both codes inputs.</summary>
    ActApplicationInputs: TScrollBox;
    /// <summary>Known accessible window (bytes, decimal) label.</summary>
    ActApplicationWindowLabel: TLabel;
    /// <summary>Known accessible window (bytes, decimal).</summary>
    ActApplicationWindowEdit: TEdit;
    /// <summary>Known application area address label.</summary>
    ActApplicationApplicationaddressLabel: TLabel;
    /// <summary>Known application area address.</summary>
    ActApplicationApplicationaddressEdit: TEdit;
    /// <summary>Known application area bytes label.</summary>
    ActApplicationApplicationbytesLabel: TLabel;
    /// <summary>Known application area bytes.</summary>
    ActApplicationApplicationbytesEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActApplicationBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActApplicationBeforeEdit: TEdit;
    /// <summary>User counter address (decimal) label.</summary>
    ActApplicationUsercounterLabel: TLabel;
    /// <summary>User counter address (decimal).</summary>
    ActApplicationUsercounterEdit: TEdit;
    /// <summary>Four-bit user counter mask (hex) label.</summary>
    ActApplicationUsermaskLabel: TLabel;
    /// <summary>Four-bit user counter mask (hex).</summary>
    ActApplicationUsermaskEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActApplicationAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActApplicationAttemptsEdit: TEdit;
    /// <summary>Supplied PIN / user code (hex) label.</summary>
    ActApplicationPinLabel: TLabel;
    /// <summary>Supplied PIN / user code (hex).</summary>
    ActApplicationPinEdit: TEdit;
    /// <summary>Memory counter first-byte address label.</summary>
    ActApplicationMemorycounterLabel: TLabel;
    /// <summary>Memory counter first-byte address.</summary>
    ActApplicationMemorycounterEdit: TEdit;
    /// <summary>Minimum remaining memory-code attempts label.</summary>
    ActApplicationMemoryattemptsLabel: TLabel;
    /// <summary>Minimum remaining memory-code attempts.</summary>
    ActApplicationMemoryattemptsEdit: TEdit;
    /// <summary>Supplied four-byte memory code (hex) label.</summary>
    ActApplicationMemorycodeLabel: TLabel;
    /// <summary>Supplied four-byte memory code (hex).</summary>
    ActApplicationMemorycodeEdit: TEdit;
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
Sle4404DemoForm: TSle4404DemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TSle4404DemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfSle4404; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TSle4404DemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TSle4404DemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActReadWindowEdit;
      FInputs[1] := ActReadAddressEdit;
      FInputs[2] := ActReadCountEdit;
      FInputs[3] := ActReadUsercounterEdit;
      FInputs[4] := ActReadUsermaskEdit;
      FInputs[5] := ActReadAttemptsEdit;
      FInputs[6] := ActReadPinEdit;
    end;
    1:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActVerifyWindowEdit;
      FInputs[1] := ActVerifyUsercounterEdit;
      FInputs[2] := ActVerifyUsermaskEdit;
      FInputs[3] := ActVerifyAttemptsEdit;
      FInputs[4] := ActVerifyPinEdit;
    end;
    2:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActProgramWindowEdit;
      FInputs[1] := ActProgramAddressEdit;
      FInputs[2] := ActProgramBeforeEdit;
      FInputs[3] := ActProgramDataEdit;
      FInputs[4] := ActProgramUsercounterEdit;
      FInputs[5] := ActProgramUsermaskEdit;
      FInputs[6] := ActProgramAttemptsEdit;
      FInputs[7] := ActProgramPinEdit;
    end;
    3:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActScratchWindowEdit;
      FInputs[1] := ActScratchScratchaddressEdit;
      FInputs[2] := ActScratchScratchbytesEdit;
      FInputs[3] := ActScratchBeforeEdit;
      FInputs[4] := ActScratchUsercounterEdit;
      FInputs[5] := ActScratchUsermaskEdit;
      FInputs[6] := ActScratchAttemptsEdit;
      FInputs[7] := ActScratchPinEdit;
    end;
    4:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActApplicationWindowEdit;
      FInputs[1] := ActApplicationApplicationaddressEdit;
      FInputs[2] := ActApplicationApplicationbytesEdit;
      FInputs[3] := ActApplicationBeforeEdit;
      FInputs[4] := ActApplicationUsercounterEdit;
      FInputs[5] := ActApplicationUsermaskEdit;
      FInputs[6] := ActApplicationAttemptsEdit;
      FInputs[7] := ActApplicationPinEdit;
      FInputs[8] := ActApplicationMemorycounterEdit;
      FInputs[9] := ActApplicationMemoryattemptsEdit;
      FInputs[10] := ActApplicationMemorycodeEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TSle4404DemoForm.ClearCredentials;
begin
  ActReadPinEdit.Clear;
  ActVerifyPinEdit.Clear;
  ActProgramPinEdit.Clear;
  ActScratchPinEdit.Clear;
  ActApplicationPinEdit.Clear;
  ActApplicationMemorycodeEdit.Clear;
end;

function TSle4404DemoForm.Request: TCardDemoRequest;
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

procedure TSle4404DemoForm.RunClick(Sender: TObject);
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

procedure TSle4404DemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TSle4404DemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TSle4404DemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TSle4404DemoForm.SetBusy(const AValue: Boolean);
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

procedure TSle4404DemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TSle4404DemoForm.PreviewArtifact(Sender: TObject);
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

procedure TSle4404DemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TSle4404DemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TSle4404DemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TSle4404DemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TSle4404DemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TSle4404DemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TSle4404DemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TSle4404DemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TSle4404DemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TSle4404DemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
