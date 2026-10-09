unit UidProgrammingDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent UidProgrammingDemo form; all visual controls belong to its own editable DFM.</summary>
  TUidProgrammingDemoForm = class(TForm)
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
    /// <summary>PC/SC Classic Gen2 UID + verify page.</summary>
    ActGen2Tab: TTabSheet;
    /// <summary>PC/SC Classic Gen2 UID + verify inputs.</summary>
    ActGen2Inputs: TScrollBox;
    /// <summary>Existing UID size label.</summary>
    ActGen2SizeLabel: TLabel;
    /// <summary>Existing UID size.</summary>
    ActGen2SizeBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActGen2UidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActGen2UidEdit: TEdit;
    /// <summary>Supplied key type label.</summary>
    ActGen2KeytypeLabel: TLabel;
    /// <summary>Supplied key type.</summary>
    ActGen2KeytypeBox: TComboBox;
    /// <summary>Supplied six-byte sector-zero key (hex) label.</summary>
    ActGen2KeyLabel: TLabel;
    /// <summary>Supplied six-byte sector-zero key (hex).</summary>
    ActGen2KeyEdit: TEdit;
    /// <summary>Actual volatile reader key slot label.</summary>
    ActGen2SlotLabel: TLabel;
    /// <summary>Actual volatile reader key slot.</summary>
    ActGen2SlotEdit: TEdit;
    /// <summary>PC/SC FUID one-time UID + verify page.</summary>
    ActFuidTab: TTabSheet;
    /// <summary>PC/SC FUID one-time UID + verify inputs.</summary>
    ActFuidInputs: TScrollBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActFuidUidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActFuidUidEdit: TEdit;
    /// <summary>Supplied key type label.</summary>
    ActFuidKeytypeLabel: TLabel;
    /// <summary>Supplied key type.</summary>
    ActFuidKeytypeBox: TComboBox;
    /// <summary>Supplied six-byte sector-zero key (hex) label.</summary>
    ActFuidKeyLabel: TLabel;
    /// <summary>Supplied six-byte sector-zero key (hex).</summary>
    ActFuidKeyEdit: TEdit;
    /// <summary>Actual volatile reader key slot label.</summary>
    ActFuidSlotLabel: TLabel;
    /// <summary>Actual volatile reader key slot.</summary>
    ActFuidSlotEdit: TEdit;
    /// <summary>ACR122 existing Gen1 dialect + verify page.</summary>
    ActGen1Tab: TTabSheet;
    /// <summary>ACR122 existing Gen1 dialect + verify inputs.</summary>
    ActGen1Inputs: TScrollBox;
    /// <summary>Explicit existing raw profile label.</summary>
    ActGen1ProfileLabel: TLabel;
    /// <summary>Explicit existing raw profile.</summary>
    ActGen1ProfileBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActGen1UidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActGen1UidEdit: TEdit;
    /// <summary>ACR122 Type 2 DirectWrite UID + verify page.</summary>
    ActDirectTab: TTabSheet;
    /// <summary>ACR122 Type 2 DirectWrite UID + verify inputs.</summary>
    ActDirectInputs: TScrollBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActDirectUidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActDirectUidEdit: TEdit;
    /// <summary>ACR122 Gen3 UID register + verify page.</summary>
    ActGen3Tab: TTabSheet;
    /// <summary>ACR122 Gen3 UID register + verify inputs.</summary>
    ActGen3Inputs: TScrollBox;
    /// <summary>Existing register size label.</summary>
    ActGen3SizeLabel: TLabel;
    /// <summary>Existing register size.</summary>
    ActGen3SizeBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActGen3UidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActGen3UidEdit: TEdit;
    /// <summary>ACR122 Gen4 UID + verify unchanged configuration page.</summary>
    ActGen4Tab: TTabSheet;
    /// <summary>ACR122 Gen4 UID + verify unchanged configuration inputs.</summary>
    ActGen4Inputs: TScrollBox;
    /// <summary>Existing emulation layout label.</summary>
    ActGen4LayoutLabel: TLabel;
    /// <summary>Existing emulation layout.</summary>
    ActGen4LayoutBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActGen4UidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActGen4UidEdit: TEdit;
    /// <summary>Supplied four-byte backdoor password (hex) label.</summary>
    ActGen4PasswordLabel: TLabel;
    /// <summary>Supplied four-byte backdoor password (hex).</summary>
    ActGen4PasswordEdit: TEdit;
    /// <summary>ACR122 USCUID existing UID source + verify page.</summary>
    ActUscuidTab: TTabSheet;
    /// <summary>ACR122 USCUID existing UID source + verify inputs.</summary>
    ActUscuidInputs: TScrollBox;
    /// <summary>Existing enabled wakeup label.</summary>
    ActUscuidWakeupLabel: TLabel;
    /// <summary>Existing enabled wakeup.</summary>
    ActUscuidWakeupBox: TComboBox;
    /// <summary>Existing UID source label.</summary>
    ActUscuidLayoutLabel: TLabel;
    /// <summary>Existing UID source.</summary>
    ActUscuidLayoutBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActUscuidUidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActUscuidUidEdit: TEdit;
    /// <summary>ACR122 partial USCUID + verify page.</summary>
    ActPartialTab: TTabSheet;
    /// <summary>ACR122 partial USCUID + verify inputs.</summary>
    ActPartialInputs: TScrollBox;
    /// <summary>Explicit existing variant label.</summary>
    ActPartialProfileLabel: TLabel;
    /// <summary>Explicit existing variant.</summary>
    ActPartialProfileBox: TComboBox;
    /// <summary>Explicit requested UID (hex) label.</summary>
    ActPartialUidLabel: TLabel;
    /// <summary>Explicit requested UID (hex).</summary>
    ActPartialUidEdit: TEdit;
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
UidProgrammingDemoForm: TUidProgrammingDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TUidProgrammingDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfUid; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  ActionChanged(nil);
end;

destructor TUidProgrammingDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TUidProgrammingDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActGen2SizeBox;
      FInputs[1] := ActGen2UidEdit;
      FInputs[2] := ActGen2KeytypeBox;
      FInputs[3] := ActGen2KeyEdit;
      FInputs[4] := ActGen2SlotEdit;
    end;
    1:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActFuidUidEdit;
      FInputs[1] := ActFuidKeytypeBox;
      FInputs[2] := ActFuidKeyEdit;
      FInputs[3] := ActFuidSlotEdit;
    end;
    2:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActGen1ProfileBox;
      FInputs[1] := ActGen1UidEdit;
    end;
    3:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActDirectUidEdit;
    end;
    4:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActGen3SizeBox;
      FInputs[1] := ActGen3UidEdit;
    end;
    5:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActGen4LayoutBox;
      FInputs[1] := ActGen4UidEdit;
      FInputs[2] := ActGen4PasswordEdit;
    end;
    6:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActUscuidWakeupBox;
      FInputs[1] := ActUscuidLayoutBox;
      FInputs[2] := ActUscuidUidEdit;
    end;
    7:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActPartialProfileBox;
      FInputs[1] := ActPartialUidEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TUidProgrammingDemoForm.ClearCredentials;
begin
  ActGen2KeyEdit.Clear;
  ActFuidKeyEdit.Clear;
  ActGen4PasswordEdit.Clear;
end;

function TUidProgrammingDemoForm.Request: TCardDemoRequest;
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

procedure TUidProgrammingDemoForm.RunClick(Sender: TObject);
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

procedure TUidProgrammingDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TUidProgrammingDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TUidProgrammingDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TUidProgrammingDemoForm.SetBusy(const AValue: Boolean);
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

procedure TUidProgrammingDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TUidProgrammingDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TUidProgrammingDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TUidProgrammingDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TUidProgrammingDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TUidProgrammingDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TUidProgrammingDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TUidProgrammingDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TUidProgrammingDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TUidProgrammingDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
