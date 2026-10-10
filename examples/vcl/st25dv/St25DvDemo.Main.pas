unit St25DvDemo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent St25DvDemo form; all visual controls belong to its own editable DFM.</summary>
  TSt25DvDemoForm = class(TForm)
  published
    /// <summary>Read decoded RF area geometry / access / lock information.</summary>
    ActConfigurationTab: TTabSheet;
    /// <summary>Read decoded RF area geometry / access / lock information inputs.</summary>
    ActConfigurationInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActConfigurationModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActConfigurationModeBox: TComboBox;
    /// <summary>Actual firmware response format label.</summary>
    ActConfigurationFormatLabel: TLabel;
    /// <summary>Actual firmware response format.</summary>
    ActConfigurationFormatBox: TComboBox;
    /// <summary>Change RF password + proof after RF reset.</summary>
    ActChangepasswordTab: TTabSheet;
    /// <summary>Change RF password + proof after RF reset inputs.</summary>
    ActChangepasswordInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActChangepasswordModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActChangepasswordModeBox: TComboBox;
    /// <summary>Actual firmware response format label.</summary>
    ActChangepasswordFormatLabel: TLabel;
    /// <summary>Actual firmware response format.</summary>
    ActChangepasswordFormatBox: TComboBox;
    /// <summary>RF password number: 0 configuration, 1..3 user label.</summary>
    ActChangepasswordIdentifierLabel: TLabel;
    /// <summary>RF password number: 0 configuration, 1..3 user.</summary>
    ActChangepasswordIdentifierEdit: TEdit;
    /// <summary>Current password in RF wire order (hex) label.</summary>
    ActChangepasswordOldpasswordLabel: TLabel;
    /// <summary>Current password in RF wire order (hex).</summary>
    ActChangepasswordOldpasswordEdit: TEdit;
    /// <summary>New password in RF wire order (hex) label.</summary>
    ActChangepasswordNewpasswordLabel: TLabel;
    /// <summary>New password in RF wire order (hex).</summary>
    ActChangepasswordNewpasswordEdit: TEdit;
    /// <summary>External VCC guaranteed stable if VCC_ON is set label.</summary>
    ActChangepasswordStablevccLabel: TLabel;
    /// <summary>External VCC guaranteed stable if VCC_ON is set.</summary>
    ActChangepasswordStablevccBox: TComboBox;
    /// <summary>Configure one RF area + post-reset verification.</summary>
    ActConfigureTab: TTabSheet;
    /// <summary>Configure one RF area + post-reset verification inputs.</summary>
    ActConfigureInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActConfigureModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActConfigureModeBox: TComboBox;
    /// <summary>Actual firmware response format label.</summary>
    ActConfigureFormatLabel: TLabel;
    /// <summary>Actual firmware response format.</summary>
    ActConfigureFormatBox: TComboBox;
    /// <summary>Active RF area number (1..4) label.</summary>
    ActConfigureAreaLabel: TLabel;
    /// <summary>Active RF area number (1..4).</summary>
    ActConfigureAreaEdit: TEdit;
    /// <summary>Supplied RF configuration password 0, eight wire-order bytes label.</summary>
    ActConfigurePasswordLabel: TLabel;
    /// <summary>Supplied RF configuration password 0, eight wire-order bytes.</summary>
    ActConfigurePasswordEdit: TEdit;
    /// <summary>Exact eight-register configuration preimage (hex) label.</summary>
    ActConfigureExpectedLabel: TLabel;
    /// <summary>Exact eight-register configuration preimage (hex).</summary>
    ActConfigureExpectedEdit: TEdit;
    /// <summary>Area user password number (0..3) label.</summary>
    ActConfigureIdentifierLabel: TLabel;
    /// <summary>Area user password number (0..3).</summary>
    ActConfigureIdentifierEdit: TEdit;
    /// <summary>Area protection code label.</summary>
    ActConfigureProtectionLabel: TLabel;
    /// <summary>Area protection code.</summary>
    ActConfigureProtectionBox: TComboBox;
    /// <summary>External VCC guaranteed stable if VCC_ON is set label.</summary>
    ActConfigureStablevccLabel: TLabel;
    /// <summary>External VCC guaranteed stable if VCC_ON is set.</summary>
    ActConfigureStablevccBox: TComboBox;
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
    /// <summary>Authenticate and read identity / geometry page.</summary>
    ActInformationTab: TTabSheet;
    /// <summary>Authenticate and read identity / geometry inputs.</summary>
    ActInformationInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActInformationModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActInformationModeBox: TComboBox;
    /// <summary>Actual ACR1552 firmware response format label.</summary>
    ActInformationFormatLabel: TLabel;
    /// <summary>Actual ACR1552 firmware response format.</summary>
    ActInformationFormatBox: TComboBox;
    /// <summary>RF user password number (1..3) label.</summary>
    ActInformationIdentifierLabel: TLabel;
    /// <summary>RF user password number (1..3).</summary>
    ActInformationIdentifierEdit: TEdit;
    /// <summary>Supplied RF password, 8 bytes in RF wire order label.</summary>
    ActInformationPasswordLabel: TLabel;
    /// <summary>Supplied RF password, 8 bytes in RF wire order.</summary>
    ActInformationPasswordEdit: TEdit;
    /// <summary>Authenticate and read physical blocks page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Authenticate and read physical blocks inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActReadModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActReadModeBox: TComboBox;
    /// <summary>Actual ACR1552 firmware response format label.</summary>
    ActReadFormatLabel: TLabel;
    /// <summary>Actual ACR1552 firmware response format.</summary>
    ActReadFormatBox: TComboBox;
    /// <summary>RF user password number (1..3) label.</summary>
    ActReadIdentifierLabel: TLabel;
    /// <summary>RF user password number (1..3).</summary>
    ActReadIdentifierEdit: TEdit;
    /// <summary>Supplied RF password, 8 bytes in RF wire order label.</summary>
    ActReadPasswordLabel: TLabel;
    /// <summary>Supplied RF password, 8 bytes in RF wire order.</summary>
    ActReadPasswordEdit: TEdit;
    /// <summary>First physical block (write: 2 or greater) label.</summary>
    ActReadBlockLabel: TLabel;
    /// <summary>First physical block (write: 2 or greater).</summary>
    ActReadBlockEdit: TEdit;
    /// <summary>Number of complete blocks label.</summary>
    ActReadCountLabel: TLabel;
    /// <summary>Number of complete blocks.</summary>
    ActReadCountEdit: TEdit;
    /// <summary>Explicit multiple-block command selection label.</summary>
    ActReadBulkLabel: TLabel;
    /// <summary>Explicit multiple-block command selection.</summary>
    ActReadBulkBox: TComboBox;
    /// <summary>Authenticate and write data block + verify page.</summary>
    ActWriteTab: TTabSheet;
    /// <summary>Authenticate and write data block + verify inputs.</summary>
    ActWriteInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActWriteModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActWriteModeBox: TComboBox;
    /// <summary>Actual ACR1552 firmware response format label.</summary>
    ActWriteFormatLabel: TLabel;
    /// <summary>Actual ACR1552 firmware response format.</summary>
    ActWriteFormatBox: TComboBox;
    /// <summary>RF user password number (1..3) label.</summary>
    ActWriteIdentifierLabel: TLabel;
    /// <summary>RF user password number (1..3).</summary>
    ActWriteIdentifierEdit: TEdit;
    /// <summary>Supplied RF password, 8 bytes in RF wire order label.</summary>
    ActWritePasswordLabel: TLabel;
    /// <summary>Supplied RF password, 8 bytes in RF wire order.</summary>
    ActWritePasswordEdit: TEdit;
    /// <summary>First physical block (write: 2 or greater) label.</summary>
    ActWriteBlockLabel: TLabel;
    /// <summary>First physical block (write: 2 or greater).</summary>
    ActWriteBlockEdit: TEdit;
    /// <summary>Replacement full block bytes (hex) label.</summary>
    ActWriteDataLabel: TLabel;
    /// <summary>Replacement full block bytes (hex).</summary>
    ActWriteDataEdit: TEdit;
    /// <summary>Authenticate and parse Type 5 NDEF page.</summary>
    ActReadndefTab: TTabSheet;
    /// <summary>Authenticate and parse Type 5 NDEF inputs.</summary>
    ActReadndefInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActReadndefModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActReadndefModeBox: TComboBox;
    /// <summary>Actual ACR1552 firmware response format label.</summary>
    ActReadndefFormatLabel: TLabel;
    /// <summary>Actual ACR1552 firmware response format.</summary>
    ActReadndefFormatBox: TComboBox;
    /// <summary>RF user password number (1..3) label.</summary>
    ActReadndefIdentifierLabel: TLabel;
    /// <summary>RF user password number (1..3).</summary>
    ActReadndefIdentifierEdit: TEdit;
    /// <summary>Supplied RF password, 8 bytes in RF wire order label.</summary>
    ActReadndefPasswordLabel: TLabel;
    /// <summary>Supplied RF password, 8 bytes in RF wire order.</summary>
    ActReadndefPasswordEdit: TEdit;
    /// <summary>Authenticate and replace/clear NDEF + verify page.</summary>
    ActWritendefTab: TTabSheet;
    /// <summary>Authenticate and replace/clear NDEF + verify inputs.</summary>
    ActWritendefInputs: TScrollBox;
    /// <summary>Explicit block address dialect label.</summary>
    ActWritendefModeLabel: TLabel;
    /// <summary>Explicit block address dialect.</summary>
    ActWritendefModeBox: TComboBox;
    /// <summary>Actual ACR1552 firmware response format label.</summary>
    ActWritendefFormatLabel: TLabel;
    /// <summary>Actual ACR1552 firmware response format.</summary>
    ActWritendefFormatBox: TComboBox;
    /// <summary>RF user password number (1..3) label.</summary>
    ActWritendefIdentifierLabel: TLabel;
    /// <summary>RF user password number (1..3).</summary>
    ActWritendefIdentifierEdit: TEdit;
    /// <summary>Supplied RF password, 8 bytes in RF wire order label.</summary>
    ActWritendefPasswordLabel: TLabel;
    /// <summary>Supplied RF password, 8 bytes in RF wire order.</summary>
    ActWritendefPasswordEdit: TEdit;
    /// <summary>Complete NDEF bytes (hex; empty clears existing message) label.</summary>
    ActWritendefNdefLabel: TLabel;
    /// <summary>Complete NDEF bytes (hex; empty clears existing message).</summary>
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
St25DvDemoForm: TSt25DvDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TSt25DvDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfSt25Dv; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TSt25DvDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TSt25DvDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActInformationModeBox;
      FInputs[1] := ActInformationFormatBox;
      FInputs[2] := ActInformationIdentifierEdit;
      FInputs[3] := ActInformationPasswordEdit;
    end;
    1:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActReadModeBox;
      FInputs[1] := ActReadFormatBox;
      FInputs[2] := ActReadIdentifierEdit;
      FInputs[3] := ActReadPasswordEdit;
      FInputs[4] := ActReadBlockEdit;
      FInputs[5] := ActReadCountEdit;
      FInputs[6] := ActReadBulkBox;
    end;
    2:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActWriteModeBox;
      FInputs[1] := ActWriteFormatBox;
      FInputs[2] := ActWriteIdentifierEdit;
      FInputs[3] := ActWritePasswordEdit;
      FInputs[4] := ActWriteBlockEdit;
      FInputs[5] := ActWriteDataEdit;
    end;
    3:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActReadndefModeBox;
      FInputs[1] := ActReadndefFormatBox;
      FInputs[2] := ActReadndefIdentifierEdit;
      FInputs[3] := ActReadndefPasswordEdit;
    end;
    4:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActWritendefModeBox;
      FInputs[1] := ActWritendefFormatBox;
      FInputs[2] := ActWritendefIdentifierEdit;
      FInputs[3] := ActWritendefPasswordEdit;
      FInputs[4] := ActWritendefNdefEdit;
    end;
    5:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActConfigurationModeBox;
      FInputs[1] := ActConfigurationFormatBox;
    end;
    6:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActChangepasswordModeBox;
      FInputs[1] := ActChangepasswordFormatBox;
      FInputs[2] := ActChangepasswordIdentifierEdit;
      FInputs[3] := ActChangepasswordOldpasswordEdit;
      FInputs[4] := ActChangepasswordNewpasswordEdit;
      FInputs[5] := ActChangepasswordStablevccBox;
    end;
    7:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActConfigureModeBox;
      FInputs[1] := ActConfigureFormatBox;
      FInputs[2] := ActConfigureAreaEdit;
      FInputs[3] := ActConfigurePasswordEdit;
      FInputs[4] := ActConfigureExpectedEdit;
      FInputs[5] := ActConfigureIdentifierEdit;
      FInputs[6] := ActConfigureProtectionBox;
      FInputs[7] := ActConfigureStablevccBox;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TSt25DvDemoForm.ClearCredentials;
begin
  ActChangepasswordOldpasswordEdit.Clear;
  ActChangepasswordNewpasswordEdit.Clear;
  ActConfigurePasswordEdit.Clear;
  ActInformationPasswordEdit.Clear;
  ActReadPasswordEdit.Clear;
  ActWritePasswordEdit.Clear;
  ActReadndefPasswordEdit.Clear;
  ActWritendefPasswordEdit.Clear;
end;

function TSt25DvDemoForm.Request: TCardDemoRequest;
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

procedure TSt25DvDemoForm.RunClick(Sender: TObject);
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

procedure TSt25DvDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TSt25DvDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TSt25DvDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TSt25DvDemoForm.SetBusy(const AValue: Boolean);
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

procedure TSt25DvDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TSt25DvDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TSt25DvDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TSt25DvDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TSt25DvDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TSt25DvDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TSt25DvDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TSt25DvDemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TSt25DvDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TSt25DvDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TSt25DvDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TSt25DvDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
