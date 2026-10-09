unit ReaderToolsDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.PCSC.Monitor, ERD.Card.PCSC.Api, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent ReaderToolsDemo form; all visual controls belong to its own editable DFM.</summary>
  TReaderToolsDemoForm = class(TForm)
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
    /// <summary>Offline APDU decode + encode page.</summary>
    ActApduTab: TTabSheet;
    /// <summary>Offline APDU decode + encode inputs.</summary>
    ActApduInputs: TScrollBox;
    /// <summary>Command APDU (hex) label.</summary>
    ActApduHexLabel: TLabel;
    /// <summary>Command APDU (hex).</summary>
    ActApduHexEdit: TEdit;
    /// <summary>Offline APDU response decode + encode page.</summary>
    ActResponseTab: TTabSheet;
    /// <summary>Offline APDU response decode + encode inputs.</summary>
    ActResponseInputs: TScrollBox;
    /// <summary>Complete APDU response (hex) label.</summary>
    ActResponseHexLabel: TLabel;
    /// <summary>Complete APDU response (hex).</summary>
    ActResponseHexEdit: TEdit;
    /// <summary>Offline ATR decode + hints page.</summary>
    ActAtrTab: TTabSheet;
    /// <summary>Offline ATR decode + hints inputs.</summary>
    ActAtrInputs: TScrollBox;
    /// <summary>Complete ATR (hex) label.</summary>
    ActAtrHexLabel: TLabel;
    /// <summary>Complete ATR (hex).</summary>
    ActAtrHexEdit: TEdit;
    /// <summary>Offline BER-TLV decode + encode page.</summary>
    ActTlvTab: TTabSheet;
    /// <summary>Offline BER-TLV decode + encode inputs.</summary>
    ActTlvInputs: TScrollBox;
    /// <summary>Complete BER-TLV (hex) label.</summary>
    ActTlvHexLabel: TLabel;
    /// <summary>Complete BER-TLV (hex).</summary>
    ActTlvHexEdit: TEdit;
    /// <summary>Offline EMV tag catalog page.</summary>
    ActTagTab: TTabSheet;
    /// <summary>Offline EMV tag catalog inputs.</summary>
    ActTagInputs: TScrollBox;
    /// <summary>EMV tag identifier (hex) label.</summary>
    ActTagHexLabel: TLabel;
    /// <summary>EMV tag identifier (hex).</summary>
    ActTagHexEdit: TEdit;
    /// <summary>Offline NDEF decode + encode page.</summary>
    ActNdefTab: TTabSheet;
    /// <summary>Offline NDEF decode + encode inputs.</summary>
    ActNdefInputs: TScrollBox;
    /// <summary>Complete NDEF message (hex) label.</summary>
    ActNdefHexLabel: TLabel;
    /// <summary>Complete NDEF message (hex).</summary>
    ActNdefHexEdit: TEdit;
    /// <summary>List PC/SC readers page.</summary>
    ActReadersTab: TTabSheet;
    /// <summary>List PC/SC readers inputs.</summary>
    ActReadersInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActReadersInfo: TLabel;
    /// <summary>Read connected ATR / protocol page.</summary>
    ActStatusTab: TTabSheet;
    /// <summary>Read connected ATR / protocol inputs.</summary>
    ActStatusInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActStatusInfo: TLabel;
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
    FMonitor: TSmartCardMonitor;
    procedure ReaderAdded(Sender: TObject; const Name: UnicodeString);
    procedure ReaderRemoved(Sender: TObject; const Name: UnicodeString);
    procedure CardInserted(Sender: TObject; const State: TPcscReaderSnapshot);
    procedure CardRemoved(Sender: TObject; const State: TPcscReaderSnapshot);
    procedure MonitorError(Sender: TObject; const Status: Cardinal);
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
ReaderToolsDemoForm: TReaderToolsDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

procedure TReaderToolsDemoForm.LogEvent(const Text: string);
begin
  while EventsMemo.Lines.Count >= 1000 do EventsMemo.Lines.Delete(0);
  EventsMemo.Lines.Add(Text);
end;
procedure TReaderToolsDemoForm.WatchClick(Sender: TObject);
begin
  if FBusy then Exit;
  FPreviousAddress := SelectedAddress;
  try FMonitor.Start;
    FDevices := nil; ReaderBox.Items.Clear; ReaderBox.ItemIndex := -1;
    RefreshReadersButton.Enabled := False; WatchButton.Enabled := False; StopWatchButton.Enabled := True;
    LogEvent('Native reader notifications active.');
  except on E: Exception do LogEvent('Observation could not start: '+E.ClassName+'.'); end;
end;
procedure TReaderToolsDemoForm.StopWatchClick(Sender: TObject);
begin
  FMonitor.Stop;
  WatchButton.Enabled := True; StopWatchButton.Enabled := False;
  RefreshReadersButton.Enabled := not FBusy;
end;
procedure TReaderToolsDemoForm.ReaderAdded(Sender: TObject; const Name: UnicodeString);
var I,N: Integer;
begin
  LogEvent('Reader connected: '+string(Name));
  for I := 0 to High(FDevices) do if FDevices[I].Address = Name then Exit;
  N := Length(FDevices); SetLength(FDevices,N+1);
  FDevices[N].Address := Name; FDevices[N].DisplayName := Name; ReaderBox.Items.Add(string(Name));
  if Name=FPreviousAddress then ReaderBox.ItemIndex := N; ReaderChanged(nil);
end;
procedure TReaderToolsDemoForm.ReaderRemoved(Sender: TObject; const Name: UnicodeString);
var I,J,Selected: Integer;
begin
  LogEvent('Reader disconnected: '+string(Name)); Selected := ReaderBox.ItemIndex;
  for I := 0 to High(FDevices) do if FDevices[I].Address = Name then begin
    for J := I to High(FDevices)-1 do FDevices[J] := FDevices[J+1];
    SetLength(FDevices,Length(FDevices)-1); ReaderBox.Items.Delete(I);
    if Selected=I then ReaderBox.ItemIndex := -1
    else if Selected>I then ReaderBox.ItemIndex := Selected-1;
    ReaderChanged(nil); Exit;
  end;
end;
procedure TReaderToolsDemoForm.CardInserted(Sender: TObject; const State: TPcscReaderSnapshot);
begin LogEvent('Card offered: '+string(State.ReaderName)+'; ATR '+BytesToHex(State.Atr)); end;
procedure TReaderToolsDemoForm.CardRemoved(Sender: TObject; const State: TPcscReaderSnapshot);
begin LogEvent('Card removed: '+string(State.ReaderName)+'; last ATR '+BytesToHex(State.Atr)); end;
procedure TReaderToolsDemoForm.MonitorError(Sender: TObject; const Status: Cardinal);
begin
  WatchButton.Enabled := True; StopWatchButton.Enabled := False;
  RefreshReadersButton.Enabled := not FBusy;
  LogEvent('Observation stopped: PC/SC 0x'+IntToHex(Status,8)+'.');
end;

constructor TReaderToolsDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfTools; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FMonitor := TSmartCardMonitor.Create(nil);
  FMonitor.OnReaderAdded := ReaderAdded; FMonitor.OnReaderRemoved := ReaderRemoved;
  FMonitor.OnCardInserted := CardInserted; FMonitor.OnCardRemoved := CardRemoved;
  FMonitor.OnError := MonitorError;
  ActionChanged(nil);
end;

destructor TReaderToolsDemoForm.Destroy;
begin
  FMonitor.Free;
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FController.Free; inherited Destroy;
end;

procedure TReaderToolsDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActApduHexEdit;
    end;
    1:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActResponseHexEdit;
    end;
    2:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActAtrHexEdit;
    end;
    3:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActTlvHexEdit;
    end;
    4:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActTagHexEdit;
    end;
    5:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActNdefHexEdit;
    end;
    6:
    begin
      SetLength(FInputs,0);
    end;
    7:
    begin
      SetLength(FInputs,0);
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TReaderToolsDemoForm.ClearCredentials;
begin
end;

function TReaderToolsDemoForm.Request: TCardDemoRequest;
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

procedure TReaderToolsDemoForm.RunClick(Sender: TObject);
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

procedure TReaderToolsDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TReaderToolsDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TReaderToolsDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TReaderToolsDemoForm.SetBusy(const AValue: Boolean);
var I: Integer; Frozen: Boolean;
begin
  FBusy := AValue; Frozen := AValue or (FCapture <> nil);
  ActionPages.Enabled := not Frozen;
  ReaderBox.Enabled := not Frozen; RefreshReadersButton.Enabled := not Frozen and not FMonitor.Active;
  WatchButton.Enabled := not Frozen and not FMonitor.Active;
  AcknowledgeCheck.Enabled := not Frozen and FActions[ActionPages.ActivePageIndex].Mutation;
  for I := 0 to High(FInputs) do FInputs[I].Enabled := not Frozen;
  RunButton.Enabled := not AValue;
  ArtifactBox.Enabled := not Frozen; SaveButton.Enabled := not Frozen and (Length(FArtifacts) > 0);
end;

procedure TReaderToolsDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TReaderToolsDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TReaderToolsDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TReaderToolsDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TReaderToolsDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TReaderToolsDemoForm.RefreshReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  if FBusy or (FCapture <> nil) or FMonitor.Active then Exit;
  FPreviousAddress := SelectedAddress;
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices;
  try StartRequest(R); except on E: Exception do OutputMemo.Text := 'Discovery could not start: '+E.ClassName+'.'; end;
end;

procedure TReaderToolsDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TReaderToolsDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TReaderToolsDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TReaderToolsDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
