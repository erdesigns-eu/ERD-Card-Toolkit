unit Twn4Demo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent Twn4Demo form; all visual controls belong to its own editable DFM.</summary>
  TTwn4DemoForm = class(TForm)
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
    /// <summary>Read PRS version page.</summary>
    ActVersionTab: TTabSheet;
    /// <summary>Read PRS version inputs.</summary>
    ActVersionInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActVersionCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActVersionCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActVersionTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActVersionTimeoutEdit: TEdit;
    /// <summary>Read selected tag identity page.</summary>
    ActTagTab: TTabSheet;
    /// <summary>Read selected tag identity inputs.</summary>
    ActTagInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActTagCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActTagCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActTagTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActTagTimeoutEdit: TEdit;
    /// <summary>Read authenticated Classic block page.</summary>
    ActClassicreadTab: TTabSheet;
    /// <summary>Read authenticated Classic block inputs.</summary>
    ActClassicreadInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActClassicreadCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActClassicreadCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActClassicreadTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActClassicreadTimeoutEdit: TEdit;
    /// <summary>Actual Classic model label.</summary>
    ActClassicreadClassicmodelLabel: TLabel;
    /// <summary>Actual Classic model.</summary>
    ActClassicreadClassicmodelBox: TComboBox;
    /// <summary>Physical block (decimal) label.</summary>
    ActClassicreadBlockLabel: TLabel;
    /// <summary>Physical block (decimal).</summary>
    ActClassicreadBlockEdit: TEdit;
    /// <summary>Explicit TWN4 reader-sector byte (decimal) label.</summary>
    ActClassicreadSectorLabel: TLabel;
    /// <summary>Explicit TWN4 reader-sector byte (decimal).</summary>
    ActClassicreadSectorEdit: TEdit;
    /// <summary>Key type label.</summary>
    ActClassicreadKeytypeLabel: TLabel;
    /// <summary>Key type.</summary>
    ActClassicreadKeytypeBox: TComboBox;
    /// <summary>Supplied six-byte key (hex) label.</summary>
    ActClassicreadKeyLabel: TLabel;
    /// <summary>Supplied six-byte key (hex).</summary>
    ActClassicreadKeyEdit: TEdit;
    /// <summary>Expected reader-order tag ID (hex) label.</summary>
    ActClassicreadIdLabel: TLabel;
    /// <summary>Expected reader-order tag ID (hex).</summary>
    ActClassicreadIdEdit: TEdit;
    /// <summary>Write Classic data block + verify page.</summary>
    ActClassicwriteTab: TTabSheet;
    /// <summary>Write Classic data block + verify inputs.</summary>
    ActClassicwriteInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActClassicwriteCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActClassicwriteCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActClassicwriteTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActClassicwriteTimeoutEdit: TEdit;
    /// <summary>Actual Classic model label.</summary>
    ActClassicwriteClassicmodelLabel: TLabel;
    /// <summary>Actual Classic model.</summary>
    ActClassicwriteClassicmodelBox: TComboBox;
    /// <summary>Physical block (decimal) label.</summary>
    ActClassicwriteBlockLabel: TLabel;
    /// <summary>Physical block (decimal).</summary>
    ActClassicwriteBlockEdit: TEdit;
    /// <summary>Explicit TWN4 reader-sector byte (decimal) label.</summary>
    ActClassicwriteSectorLabel: TLabel;
    /// <summary>Explicit TWN4 reader-sector byte (decimal).</summary>
    ActClassicwriteSectorEdit: TEdit;
    /// <summary>Key type label.</summary>
    ActClassicwriteKeytypeLabel: TLabel;
    /// <summary>Key type.</summary>
    ActClassicwriteKeytypeBox: TComboBox;
    /// <summary>Supplied six-byte key (hex) label.</summary>
    ActClassicwriteKeyLabel: TLabel;
    /// <summary>Supplied six-byte key (hex).</summary>
    ActClassicwriteKeyEdit: TEdit;
    /// <summary>Expected reader-order tag ID (hex) label.</summary>
    ActClassicwriteIdLabel: TLabel;
    /// <summary>Expected reader-order tag ID (hex).</summary>
    ActClassicwriteIdEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActClassicwriteBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActClassicwriteBeforeEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActClassicwriteDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActClassicwriteDataEdit: TEdit;
    /// <summary>Read public Type 2 user page page.</summary>
    ActType2readTab: TTabSheet;
    /// <summary>Read public Type 2 user page inputs.</summary>
    ActType2readInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActType2readCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActType2readCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActType2readTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActType2readTimeoutEdit: TEdit;
    /// <summary>Actual Type 2 model label.</summary>
    ActType2readType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActType2readType2modelBox: TComboBox;
    /// <summary>Physical user page (decimal) label.</summary>
    ActType2readPageLabel: TLabel;
    /// <summary>Physical user page (decimal).</summary>
    ActType2readPageEdit: TEdit;
    /// <summary>Expected seven-byte tag ID (hex) label.</summary>
    ActType2readIdLabel: TLabel;
    /// <summary>Expected seven-byte tag ID (hex).</summary>
    ActType2readIdEdit: TEdit;
    /// <summary>Write public Type 2 user page + verify page.</summary>
    ActType2writeTab: TTabSheet;
    /// <summary>Write public Type 2 user page + verify inputs.</summary>
    ActType2writeInputs: TScrollBox;
    /// <summary>Actual firmware CRC mode label.</summary>
    ActType2writeCrcLabel: TLabel;
    /// <summary>Actual firmware CRC mode.</summary>
    ActType2writeCrcBox: TComboBox;
    /// <summary>Shared command deadline (ms) label.</summary>
    ActType2writeTimeoutLabel: TLabel;
    /// <summary>Shared command deadline (ms).</summary>
    ActType2writeTimeoutEdit: TEdit;
    /// <summary>Actual Type 2 model label.</summary>
    ActType2writeType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActType2writeType2modelBox: TComboBox;
    /// <summary>Physical user page (decimal) label.</summary>
    ActType2writePageLabel: TLabel;
    /// <summary>Physical user page (decimal).</summary>
    ActType2writePageEdit: TEdit;
    /// <summary>Expected seven-byte tag ID (hex) label.</summary>
    ActType2writeIdLabel: TLabel;
    /// <summary>Expected seven-byte tag ID (hex).</summary>
    ActType2writeIdEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActType2writeBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActType2writeBeforeEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActType2writeDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActType2writeDataEdit: TEdit;
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
Twn4DemoForm: TTwn4DemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TTwn4DemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfTwn4; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkSerial,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  ActionChanged(nil);
end;

destructor TTwn4DemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TTwn4DemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActVersionCrcBox;
      FInputs[2] := ActVersionTimeoutEdit;
    end;
    1:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActTagCrcBox;
      FInputs[2] := ActTagTimeoutEdit;
    end;
    2:
    begin
      SetLength(FInputs,9);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActClassicreadCrcBox;
      FInputs[2] := ActClassicreadTimeoutEdit;
      FInputs[3] := ActClassicreadClassicmodelBox;
      FInputs[4] := ActClassicreadBlockEdit;
      FInputs[5] := ActClassicreadSectorEdit;
      FInputs[6] := ActClassicreadKeytypeBox;
      FInputs[7] := ActClassicreadKeyEdit;
      FInputs[8] := ActClassicreadIdEdit;
    end;
    3:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActClassicwriteCrcBox;
      FInputs[2] := ActClassicwriteTimeoutEdit;
      FInputs[3] := ActClassicwriteClassicmodelBox;
      FInputs[4] := ActClassicwriteBlockEdit;
      FInputs[5] := ActClassicwriteSectorEdit;
      FInputs[6] := ActClassicwriteKeytypeBox;
      FInputs[7] := ActClassicwriteKeyEdit;
      FInputs[8] := ActClassicwriteIdEdit;
      FInputs[9] := ActClassicwriteBeforeEdit;
      FInputs[10] := ActClassicwriteDataEdit;
    end;
    4:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActType2readCrcBox;
      FInputs[2] := ActType2readTimeoutEdit;
      FInputs[3] := ActType2readType2modelBox;
      FInputs[4] := ActType2readPageEdit;
      FInputs[5] := ActType2readIdEdit;
    end;
    5:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActType2writeCrcBox;
      FInputs[2] := ActType2writeTimeoutEdit;
      FInputs[3] := ActType2writeType2modelBox;
      FInputs[4] := ActType2writePageEdit;
      FInputs[5] := ActType2writeIdEdit;
      FInputs[6] := ActType2writeBeforeEdit;
      FInputs[7] := ActType2writeDataEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TTwn4DemoForm.ClearCredentials;
begin
  ActClassicreadKeyEdit.Clear;
  ActClassicwriteKeyEdit.Clear;
end;

function TTwn4DemoForm.Request: TCardDemoRequest;
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

procedure TTwn4DemoForm.RunClick(Sender: TObject);
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

procedure TTwn4DemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TTwn4DemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TTwn4DemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TTwn4DemoForm.SetBusy(const AValue: Boolean);
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

procedure TTwn4DemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TTwn4DemoForm.PreviewArtifact(Sender: TObject);
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

procedure TTwn4DemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TTwn4DemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TTwn4DemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TTwn4DemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TTwn4DemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TTwn4DemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TTwn4DemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TTwn4DemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
