unit MagStripeProfilesDemo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent MagStripeProfilesDemo form; all visual controls belong to its own editable DFM.</summary>
  TMagStripeProfilesDemoForm = class(TForm)
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
    /// <summary>Offline track encode / parity / LRC roundtrip page.</summary>
    ActBitsTab: TTabSheet;
    /// <summary>Offline track encode / parity / LRC roundtrip inputs.</summary>
    ActBitsInputs: TScrollBox;
    /// <summary>Physical track label.</summary>
    ActBitsTrackLabel: TLabel;
    /// <summary>Physical track.</summary>
    ActBitsTrackBox: TComboBox;
    /// <summary>Unframed track payload label.</summary>
    ActBitsPayloadLabel: TLabel;
    /// <summary>Unframed track payload.</summary>
    ActBitsPayloadEdit: TEdit;
    /// <summary>Offline complete track-bit decode page.</summary>
    ActDecodebitsTab: TTabSheet;
    /// <summary>Offline complete track-bit decode inputs.</summary>
    ActDecodebitsInputs: TScrollBox;
    /// <summary>Physical track label.</summary>
    ActDecodebitsTrackLabel: TLabel;
    /// <summary>Physical track.</summary>
    ActDecodebitsTrackBox: TComboBox;
    /// <summary>One byte per bit (hex) label.</summary>
    ActDecodebitsHexLabel: TLabel;
    /// <summary>One byte per bit (hex).</summary>
    ActDecodebitsHexEdit: TEdit;
    /// <summary>Offline financial-field decode page.</summary>
    ActFinancialTab: TTabSheet;
    /// <summary>Offline financial-field decode inputs.</summary>
    ActFinancialInputs: TScrollBox;
    /// <summary>Explicit financial track label.</summary>
    ActFinancialTrackLabel: TLabel;
    /// <summary>Explicit financial track.</summary>
    ActFinancialTrackBox: TComboBox;
    /// <summary>Unframed financial track payload label.</summary>
    ActFinancialPayloadLabel: TLabel;
    /// <summary>Unframed financial track payload.</summary>
    ActFinancialPayloadEdit: TEdit;
    /// <summary>Offline MagTek unencrypted ISO HID report page.</summary>
    ActHidTab: TTabSheet;
    /// <summary>Offline MagTek unencrypted ISO HID report inputs.</summary>
    ActHidInputs: TScrollBox;
    /// <summary>Exact physical track selection label.</summary>
    ActHidTracksLabel: TLabel;
    /// <summary>Exact physical track selection.</summary>
    ActHidTracksBox: TComboBox;
    /// <summary>Explicit OS zero report ID label.</summary>
    ActHidHasidLabel: TLabel;
    /// <summary>Explicit OS zero report ID.</summary>
    ActHidHasidBox: TComboBox;
    /// <summary>Complete 337/338-byte report (hex) label.</summary>
    ActHidHexLabel: TLabel;
    /// <summary>Complete 337/338-byte report (hex).</summary>
    ActHidHexEdit: TEdit;
    /// <summary>Offline MagTek ISO keyboard frame page.</summary>
    ActKeyboardTab: TTabSheet;
    /// <summary>Offline MagTek ISO keyboard frame inputs.</summary>
    ActKeyboardInputs: TScrollBox;
    /// <summary>Exact physical track selection label.</summary>
    ActKeyboardTracksLabel: TLabel;
    /// <summary>Exact physical track selection.</summary>
    ActKeyboardTracksBox: TComboBox;
    /// <summary>Complete ASCII frame including CR (hex) label.</summary>
    ActKeyboardHexLabel: TLabel;
    /// <summary>Complete ASCII frame including CR (hex).</summary>
    ActKeyboardHexEdit: TEdit;
    /// <summary>MSR206 / MSR605 selected-track read page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>MSR206 / MSR605 selected-track read inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Actual three-track profile label.</summary>
    ActReadProfileLabel: TLabel;
    /// <summary>Actual three-track profile.</summary>
    ActReadProfileBox: TComboBox;
    /// <summary>Total swipe deadline (ms) label.</summary>
    ActReadTimeoutLabel: TLabel;
    /// <summary>Total swipe deadline (ms).</summary>
    ActReadTimeoutEdit: TEdit;
    /// <summary>Exact physical track selection label.</summary>
    ActReadTracksLabel: TLabel;
    /// <summary>Exact physical track selection.</summary>
    ActReadTracksBox: TComboBox;
    /// <summary>MSR206 / MSR605 all-track status-only programming page.</summary>
    ActProgramTab: TTabSheet;
    /// <summary>MSR206 / MSR605 all-track status-only programming inputs.</summary>
    ActProgramInputs: TScrollBox;
    /// <summary>Actual three-track profile label.</summary>
    ActProgramProfileLabel: TLabel;
    /// <summary>Actual three-track profile.</summary>
    ActProgramProfileBox: TComboBox;
    /// <summary>Total swipe deadline (ms) label.</summary>
    ActProgramTimeoutLabel: TLabel;
    /// <summary>Total swipe deadline (ms).</summary>
    ActProgramTimeoutEdit: TEdit;
    /// <summary>Explicit coercivity label.</summary>
    ActProgramCoercivityLabel: TLabel;
    /// <summary>Explicit coercivity.</summary>
    ActProgramCoercivityBox: TComboBox;
    /// <summary>Nonempty Track 1 payload label.</summary>
    ActProgramTrack1Label: TLabel;
    /// <summary>Nonempty Track 1 payload.</summary>
    ActProgramTrack1Edit: TEdit;
    /// <summary>Nonempty Track 2 payload label.</summary>
    ActProgramTrack2Label: TLabel;
    /// <summary>Nonempty Track 2 payload.</summary>
    ActProgramTrack2Edit: TEdit;
    /// <summary>Nonempty Track 3 payload label.</summary>
    ActProgramTrack3Label: TLabel;
    /// <summary>Nonempty Track 3 payload.</summary>
    ActProgramTrack3Edit: TEdit;
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
MagStripeProfilesDemoForm: TMagStripeProfilesDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TMagStripeProfilesDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfMagProfiles; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkSerial,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  ActionChanged(nil);
end;

destructor TMagStripeProfilesDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TMagStripeProfilesDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActBitsTrackBox;
      FInputs[1] := ActBitsPayloadEdit;
    end;
    1:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActDecodebitsTrackBox;
      FInputs[1] := ActDecodebitsHexEdit;
    end;
    2:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActFinancialTrackBox;
      FInputs[1] := ActFinancialPayloadEdit;
    end;
    3:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActHidTracksBox;
      FInputs[1] := ActHidHasidBox;
      FInputs[2] := ActHidHexEdit;
    end;
    4:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActKeyboardTracksBox;
      FInputs[1] := ActKeyboardHexEdit;
    end;
    5:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActReadProfileBox;
      FInputs[2] := ActReadTimeoutEdit;
      FInputs[3] := ActReadTracksBox;
    end;
    6:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ReaderBox;
      FInputs[1] := ActProgramProfileBox;
      FInputs[2] := ActProgramTimeoutEdit;
      FInputs[3] := ActProgramCoercivityBox;
      FInputs[4] := ActProgramTrack1Edit;
      FInputs[5] := ActProgramTrack2Edit;
      FInputs[6] := ActProgramTrack3Edit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TMagStripeProfilesDemoForm.ClearCredentials;
begin
end;

function TMagStripeProfilesDemoForm.Request: TCardDemoRequest;
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

procedure TMagStripeProfilesDemoForm.RunClick(Sender: TObject);
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

procedure TMagStripeProfilesDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TMagStripeProfilesDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TMagStripeProfilesDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TMagStripeProfilesDemoForm.SetBusy(const AValue: Boolean);
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

procedure TMagStripeProfilesDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TMagStripeProfilesDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TMagStripeProfilesDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TMagStripeProfilesDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TMagStripeProfilesDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TMagStripeProfilesDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TMagStripeProfilesDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TMagStripeProfilesDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TMagStripeProfilesDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TMagStripeProfilesDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
