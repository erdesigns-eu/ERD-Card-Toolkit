unit MobibDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent MobibDemo form; all visual controls belong to its own editable DFM.</summary>
  TMobibDemoForm = class(TForm)
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
    /// <summary>Read public MOBIB files and records page.</summary>
    ActSnapshotTab: TTabSheet;
    /// <summary>Read public MOBIB files and records inputs.</summary>
    ActSnapshotInputs: TScrollBox;
    /// <summary>Explicit Calypso dialect label.</summary>
    ActSnapshotDialectLabel: TLabel;
    /// <summary>Explicit Calypso dialect.</summary>
    ActSnapshotDialectBox: TComboBox;
    /// <summary>Initial expected record bytes label.</summary>
    ActSnapshotLeLabel: TLabel;
    /// <summary>Initial expected record bytes.</summary>
    ActSnapshotLeEdit: TEdit;
    /// <summary>Maximum records per file label.</summary>
    ActSnapshotLimitLabel: TLabel;
    /// <summary>Maximum records per file.</summary>
    ActSnapshotLimitEdit: TEdit;
    /// <summary>Explicit MOBIB data layout label.</summary>
    ActSnapshotLayoutLabel: TLabel;
    /// <summary>Explicit MOBIB data layout.</summary>
    ActSnapshotLayoutBox: TComboBox;
    /// <summary>Logical file IDs (hex), semicolon-separated; edit to include additional known files label.</summary>
    ActSnapshotFilesLabel: TLabel;
    /// <summary>Logical file IDs (hex), semicolon-separated; edit to include additional known files.</summary>
    ActSnapshotFilesEdit: TEdit;
    /// <summary>Read explicit Calypso logical file page.</summary>
    ActFileTab: TTabSheet;
    /// <summary>Read explicit Calypso logical file inputs.</summary>
    ActFileInputs: TScrollBox;
    /// <summary>Explicit Calypso dialect label.</summary>
    ActFileDialectLabel: TLabel;
    /// <summary>Explicit Calypso dialect.</summary>
    ActFileDialectBox: TComboBox;
    /// <summary>Initial expected record bytes label.</summary>
    ActFileLeLabel: TLabel;
    /// <summary>Initial expected record bytes.</summary>
    ActFileLeEdit: TEdit;
    /// <summary>Maximum records per file label.</summary>
    ActFileLimitLabel: TLabel;
    /// <summary>Maximum records per file.</summary>
    ActFileLimitEdit: TEdit;
    /// <summary>Logical file identifier (hex) label.</summary>
    ActFileFidLabel: TLabel;
    /// <summary>Logical file identifier (hex).</summary>
    ActFileFidEdit: TEdit;
    /// <summary>Authenticated Calypso file via provisioned SAM page.</summary>
    ActSamfileTab: TTabSheet;
    /// <summary>Authenticated Calypso file via provisioned SAM inputs.</summary>
    ActSamfileInputs: TScrollBox;
    /// <summary>Explicit Calypso dialect label.</summary>
    ActSamfileDialectLabel: TLabel;
    /// <summary>Explicit Calypso dialect.</summary>
    ActSamfileDialectBox: TComboBox;
    /// <summary>Exact expected record bytes (maximum 253) label.</summary>
    ActSamfileLeLabel: TLabel;
    /// <summary>Exact expected record bytes (maximum 253).</summary>
    ActSamfileLeEdit: TEdit;
    /// <summary>Exact record count; no missing-record probing label.</summary>
    ActSamfileLimitLabel: TLabel;
    /// <summary>Exact record count; no missing-record probing.</summary>
    ActSamfileLimitEdit: TEdit;
    /// <summary>Known logical file identifier (hex) label.</summary>
    ActSamfileFidLabel: TLabel;
    /// <summary>Known logical file identifier (hex).</summary>
    ActSamfileFidEdit: TEdit;
    /// <summary>Separate available PC/SC SAM reader label.</summary>
    ActSamfileSamreaderLabel: TLabel;
    /// <summary>Separate available PC/SC SAM reader.</summary>
    ActSamfileSamreaderEdit: TComboBox;
    /// <summary>Explicit secure-session revision label.</summary>
    ActSamfileRevisionLabel: TLabel;
    /// <summary>Explicit secure-session revision.</summary>
    ActSamfileRevisionBox: TComboBox;
    /// <summary>Exact eight-byte card serial/diversifier (hex) label.</summary>
    ActSamfileSerialLabel: TLabel;
    /// <summary>Exact eight-byte card serial/diversifier (hex).</summary>
    ActSamfileSerialEdit: TEdit;
    /// <summary>Authorized card key index label.</summary>
    ActSamfileKeyindexLabel: TLabel;
    /// <summary>Authorized card key index.</summary>
    ActSamfileKeyindexEdit: TEdit;
    /// <summary>Authorized SAM key identifier (decimal) label.</summary>
    ActSamfileKifLabel: TLabel;
    /// <summary>Authorized SAM key identifier (decimal).</summary>
    ActSamfileKifEdit: TEdit;
    /// <summary>Authorized key version (decimal) label.</summary>
    ActSamfileKvcLabel: TLabel;
    /// <summary>Authorized key version (decimal).</summary>
    ActSamfileKvcEdit: TEdit;
    /// <summary>SAM APDU class label.</summary>
    ActSamfileSamclassLabel: TLabel;
    /// <summary>SAM APDU class.</summary>
    ActSamfileSamclassBox: TComboBox;
    /// <summary>Offline activation / validity / zone assessment with explicit policy page.</summary>
    ActRulesTab: TTabSheet;
    /// <summary>Offline activation / validity / zone assessment with explicit policy inputs.</summary>
    ActRulesInputs: TScrollBox;
    /// <summary>Complete MOBIB contract record (hex) label.</summary>
    ActRulesContractLabel: TLabel;
    /// <summary>Complete MOBIB contract record (hex).</summary>
    ActRulesContractEdit: TEdit;
    /// <summary>Absolute contract record number label.</summary>
    ActRulesRecordLabel: TLabel;
    /// <summary>Absolute contract record number.</summary>
    ActRulesRecordEdit: TEdit;
    /// <summary>Policy tariff code (hex) label.</summary>
    ActRulesTariffLabel: TLabel;
    /// <summary>Policy tariff code (hex).</summary>
    ActRulesTariffEdit: TEdit;
    /// <summary>Explicit operator identifier label.</summary>
    ActRulesOperatorLabel: TLabel;
    /// <summary>Explicit operator identifier.</summary>
    ActRulesOperatorEdit: TEdit;
    /// <summary>Rule source/specification revision (manual profile; no installed issuer rules) label.</summary>
    ActRulesSourceLabel: TLabel;
    /// <summary>Rule source/specification revision (manual profile; no installed issuer rules).</summary>
    ActRulesSourceEdit: TEdit;
    /// <summary>Timestamp basis label.</summary>
    ActRulesClockLabel: TLabel;
    /// <summary>Timestamp basis.</summary>
    ActRulesClockBox: TComboBox;
    /// <summary>Evaluation timestamp: YYYY-MM-DD hh:mm:ss label.</summary>
    ActRulesNowLabel: TLabel;
    /// <summary>Evaluation timestamp: YYYY-MM-DD hh:mm:ss.</summary>
    ActRulesNowEdit: TEdit;
    /// <summary>Policy validity-start source label.</summary>
    ActRulesActivationLabel: TLabel;
    /// <summary>Policy validity-start source.</summary>
    ActRulesActivationBox: TComboBox;
    /// <summary>Acquired activation state label.</summary>
    ActRulesStateLabel: TLabel;
    /// <summary>Acquired activation state.</summary>
    ActRulesStateBox: TComboBox;
    /// <summary>Acquired start/activation/first-use timestamp; blank = unknown label.</summary>
    ActRulesAnchorLabel: TLabel;
    /// <summary>Acquired start/activation/first-use timestamp; blank = unknown.</summary>
    ActRulesAnchorEdit: TEdit;
    /// <summary>Acquired exclusive end timestamp; blank = unknown label.</summary>
    ActRulesEndLabel: TLabel;
    /// <summary>Acquired exclusive end timestamp; blank = unknown.</summary>
    ActRulesEndEdit: TEdit;
    /// <summary>Policy duration label.</summary>
    ActRulesDurationLabel: TLabel;
    /// <summary>Policy duration.</summary>
    ActRulesDurationBox: TComboBox;
    /// <summary>Fixed duration amount; zero for explicit-end mode label.</summary>
    ActRulesAmountLabel: TLabel;
    /// <summary>Fixed duration amount; zero for explicit-end mode.</summary>
    ActRulesAmountEdit: TEdit;
    /// <summary>Calendar end calculated from start-day midnight label.</summary>
    ActRulesMidnightLabel: TLabel;
    /// <summary>Calendar end calculated from start-day midnight.</summary>
    ActRulesMidnightBox: TComboBox;
    /// <summary>Allowed zones: semicolon IDs; * = explicitly unrestricted; blank = unknown label.</summary>
    ActRulesZonesLabel: TLabel;
    /// <summary>Allowed zones: semicolon IDs; * = explicitly unrestricted; blank = unknown.</summary>
    ActRulesZonesEdit: TEdit;
    /// <summary>All requested journey zone IDs (semicolon-separated) label.</summary>
    ActRulesJourneyzonesLabel: TLabel;
    /// <summary>All requested journey zone IDs (semicolon-separated).</summary>
    ActRulesJourneyzonesEdit: TEdit;
    /// <summary>New journey requires remaining trips label.</summary>
    ActRulesRequiretripsLabel: TLabel;
    /// <summary>New journey requires remaining trips.</summary>
    ActRulesRequiretripsBox: TComboBox;
    /// <summary>Acquired associated trip counter; blank = unknown label.</summary>
    ActRulesTripsLabel: TLabel;
    /// <summary>Acquired associated trip counter; blank = unknown.</summary>
    ActRulesTripsEdit: TEdit;
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
MobibDemoForm: TMobibDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TMobibDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfMobib; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  ActionChanged(nil);
end;

destructor TMobibDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TMobibDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActSnapshotDialectBox;
      FInputs[1] := ActSnapshotLeEdit;
      FInputs[2] := ActSnapshotLimitEdit;
      FInputs[3] := ActSnapshotLayoutBox;
      FInputs[4] := ActSnapshotFilesEdit;
    end;
    1:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActFileDialectBox;
      FInputs[1] := ActFileLeEdit;
      FInputs[2] := ActFileLimitEdit;
      FInputs[3] := ActFileFidEdit;
    end;
    2:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActSamfileDialectBox;
      FInputs[1] := ActSamfileLeEdit;
      FInputs[2] := ActSamfileLimitEdit;
      FInputs[3] := ActSamfileFidEdit;
      FInputs[4] := ActSamfileSamreaderEdit;
      FInputs[5] := ActSamfileRevisionBox;
      FInputs[6] := ActSamfileSerialEdit;
      FInputs[7] := ActSamfileKeyindexEdit;
      FInputs[8] := ActSamfileKifEdit;
      FInputs[9] := ActSamfileKvcEdit;
      FInputs[10] := ActSamfileSamclassBox;
    end;
    3:
    begin
      SetLength(FInputs,18);
      FInputs[0] := ActRulesContractEdit;
      FInputs[1] := ActRulesRecordEdit;
      FInputs[2] := ActRulesTariffEdit;
      FInputs[3] := ActRulesOperatorEdit;
      FInputs[4] := ActRulesSourceEdit;
      FInputs[5] := ActRulesClockBox;
      FInputs[6] := ActRulesNowEdit;
      FInputs[7] := ActRulesActivationBox;
      FInputs[8] := ActRulesStateBox;
      FInputs[9] := ActRulesAnchorEdit;
      FInputs[10] := ActRulesEndEdit;
      FInputs[11] := ActRulesDurationBox;
      FInputs[12] := ActRulesAmountEdit;
      FInputs[13] := ActRulesMidnightBox;
      FInputs[14] := ActRulesZonesEdit;
      FInputs[15] := ActRulesJourneyzonesEdit;
      FInputs[16] := ActRulesRequiretripsBox;
      FInputs[17] := ActRulesTripsEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TMobibDemoForm.ClearCredentials;
begin
end;

function TMobibDemoForm.Request: TCardDemoRequest;
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
      else if FActions[ActionPages.ActivePageIndex].Fields[I].Name = 'samreader' then Result.Arguments[I] := TComboBox(FInputs[I]).Text
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

procedure TMobibDemoForm.RunClick(Sender: TObject);
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

procedure TMobibDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TMobibDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TMobibDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TMobibDemoForm.SetBusy(const AValue: Boolean);
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

procedure TMobibDemoForm.Complete(const AResult: TCardDemoResult);
var I: Integer;
begin
  if AResult.Operation = cdoDemoDevices then
  begin
    ActSamfileSamreaderEdit.Items.Clear; ActSamfileSamreaderEdit.ItemIndex := -1;
    FDevices := nil; ReaderBox.Items.Clear; ReaderBox.ItemIndex := -1;
    if AResult.Success then FDevices := AResult.Devices;
    for I := 0 to High(FDevices) do
    begin
      ReaderBox.Items.Add(string(FDevices[I].DisplayName));
      ActSamfileSamreaderEdit.Items.Add(string(FDevices[I].Address));
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

procedure TMobibDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TMobibDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TMobibDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TMobibDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TMobibDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TMobibDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TMobibDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TMobibDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TMobibDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
