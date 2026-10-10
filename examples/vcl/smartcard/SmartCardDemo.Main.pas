unit SmartCardDemo.Main;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, System.SysUtils,
  Vcl.Dialogs, Vcl.ComCtrls, ERD.Card.RFID.Input, ERD.Card.Bytes, ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices, ERD.Card.Demo.ReaderEvents;

type
  /// <summary>Explicit PC/SC card operations with a background worker and optional face preview.</summary>
  TSmartCardDemoForm = class(TForm)
  published
    /// <summary>Own keyboard-input page.</summary>
    FRfidTab: TTabSheet;
    /// <summary>Reader-presented input profile.</summary>
    FRfidSettings: TPanel;
    /// <summary>Explicit ASCII, hex or decimal output.</summary>
    FRfidEncoding: TComboBox;
    /// <summary>Actual reader terminator.</summary>
    FRfidTerminator: TComboBox;
    /// <summary>Exact expected characters; zero means variable.</summary>
    FRfidLength: TEdit;
    /// <summary>Maximum inter-character gap in milliseconds.</summary>
    FRfidTimeout: TEdit;
    /// <summary>Exact reader prefix.</summary>
    FRfidPrefix: TEdit;
    /// <summary>Exact reader suffix.</summary>
    FRfidSuffix: TEdit;
    /// <summary>Own foreground keyboard capture control.</summary>
    FRfidCapture: TMemo;
    /// <summary>Start or stop explicit foreground capture.</summary>
    FRfidToggle: TButton;
    /// <summary>Foreground input and formatting guidance.</summary>
    RfidGuidance: TLabel;
    /// <summary>Starts or stops the configured foreground capture.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RfidToggleClick(Sender: TObject);
    /// <summary>Consumes keyboard characters from this form’s own DFM memo.</summary>
    /// <param name="Sender">Capture memo.</param>
    /// <param name="Key">Consumed input character.</param>
    procedure RfidKeyPress(Sender: TObject; var Key: Char);
  published
    /// <summary>Own DFM timer polling this form’s nonvisual controller.</summary>
    WorkerTimer: TTimer;
    /// <summary>Starts device discovery once when this form is shown.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormShow(Sender: TObject);
    /// <summary>Polls this form’s own worker from its DFM timer.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure PollTimer(Sender: TObject);
  published
    /// <summary>Card operations and contact-memory pages.</summary>
    OperationPages: TPageControl;
    /// <summary>Existing smart-card and NDEF operations.</summary>
    CardTab: TTabSheet;
    /// <summary>Explicit ACS memory-profile operations.</summary>
    MemoryTab: TTabSheet;
    /// <summary>Memory operation label.</summary>
    MemoryActionLabel: TLabel;
    /// <summary>Offline capabilities, ATR/status, reads, PIN verification or verified writing.</summary>
    MemoryActionBox: TComboBox;
    /// <summary>Run the selected memory operation asynchronously.</summary>
    MemoryRunButton: TButton;
    /// <summary>Actual chip model label.</summary>
    MemoryModelLabel: TLabel;
    /// <summary>Explicit ordinary-memory or counter-chip profile; never auto-detected.</summary>
    MemoryModelBox: TComboBox;
    /// <summary>Explicit ACR38x CCID or ACR39 reader dialect.</summary>
    MemoryDialectBox: TComboBox;
    /// <summary>Decimal byte range and counter-readable-window label.</summary>
    MemoryRangeLabel: TLabel;
    /// <summary>Zero-based decimal start address.</summary>
    MemoryAddressEdit: TEdit;
    /// <summary>Positive decimal read length.</summary>
    MemoryCountEdit: TEdit;
    /// <summary>Caller-declared counter readable window; zero is unconfigured.</summary>
    CounterWindowEdit: TEdit;
    /// <summary>Hexadecimal write payload label.</summary>
    MemoryDataLabel: TLabel;
    /// <summary>Explicit main-memory replacement bytes.</summary>
    MemoryDataEdit: TEdit;
    /// <summary>Card-order hexadecimal PIN label.</summary>
    MemoryPinLabel: TLabel;
    /// <summary>Masked PIN hex input; copied and cleared after job start.</summary>
    MemoryPinEdit: TEdit;
    /// <summary>Explicit acknowledgement that the supplied range may be changed.</summary>
    MemoryWriteCheck: TCheckBox;
    /// <summary>Physical I2C page size and remaining PIN-attempt budget label.</summary>
    MemoryPolicyLabel: TLabel;
    /// <summary>Known physical I2C page size; must be selected for I2C writes.</summary>
    MemoryPageBox: TComboBox;
    /// <summary>Minimum remaining PIN attempts, from one through eight.</summary>
    MemoryAttemptsEdit: TEdit;
    /// <summary>Explicit profile and no-retry guidance.</summary>
    MemoryGuidance: TLabel;
    /// <summary>Reader and explicit operation inputs.</summary>
    InputPanel: TPanel;
    /// <summary>Exact reader-name label.</summary>
    ReaderLabel: TLabel;
    /// <summary>Editable exact PC/SC reader name; no automatic reader selection.</summary>
    ReaderBox: TComboBox;
    /// <summary>Native reader/card event status independent of operation results.</summary>
    EventStatusLabel: TLabel;
    /// <summary>Explicit reader enumeration.</summary>
    ReadersButton: TButton;
    /// <summary>Operation selection label.</summary>
    OperationLabel: TLabel;
    /// <summary>Explicit operation selection; offline inspection is the initial mode.</summary>
    OperationBox: TComboBox;
    /// <summary>Explicit Type 2 model label.</summary>
    ModelLabel: TLabel;
    /// <summary>Type 2 memory layout; selected only when the operator chooses a model.</summary>
    ModelBox: TComboBox;
    /// <summary>ICAO access selection label.</summary>
    AccessLabel: TLabel;
    /// <summary>Explicit BAC or PACE access protocol.</summary>
    SecurityBox: TComboBox;
    /// <summary>MRZ information or CAN password kind.</summary>
    PasswordKindBox: TComboBox;
    /// <summary>PACE parameter 12 or 13.</summary>
    CurveBox: TComboBox;
    /// <summary>Access password label.</summary>
    PasswordLabel: TLabel;
    /// <summary>Masked ICAO access input, cleared after starting a job.</summary>
    PasswordEdit: TEdit;
    /// <summary>Optional OpenSSL path label.</summary>
    LibraryLabel: TLabel;
    /// <summary>Explicit optional OpenSSL 3 library path.</summary>
    LibraryEdit: TEdit;
    /// <summary>Complete NDEF wire message label.</summary>
    NdefLabel: TLabel;
    /// <summary>NDEF hexadecimal bytes for inspect or replacement.</summary>
    NdefEdit: TEdit;
    /// <summary>Offline text encoder label.</summary>
    TextLabel: TLabel;
    /// <summary>Text for one UTF-8 NDEF Text record with language en.</summary>
    TextEdit: TEdit;
    /// <summary>Offline text-to-NDEF encoder.</summary>
    EncodeButton: TButton;
    /// <summary>Runs the explicit selected read or replacement operation.</summary>
    RunButton: TButton;
    /// <summary>Reader profile and write semantics guidance.</summary>
    ProfileLabel: TLabel;
    /// <summary>Result text including acquired identity when requested.</summary>
    OutputMemo: TMemo;
    /// <summary>UI-thread JPEG preview; JPEG 2000 remains available for saving.</summary>
    PhotoImage: TImage;
    /// <summary>Saves acquired encoded bytes after explicit file selection.</summary>
    SavePhotoButton: TButton;
    /// <summary>Photo destination dialog.</summary>
    PhotoDialog: TSaveDialog;
    /// <summary>Initialize operation choices without touching hardware.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormCreate(Sender: TObject);
    /// <summary>Start an explicit asynchronous reader enumeration.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure ReadersClick(Sender: TObject);
    /// <summary>Copy selected operation inputs and start a worker.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RunClick(Sender: TObject);
    /// <summary>Encode an NDEF Text record offline.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure EncodeClick(Sender: TObject);
    /// <summary>Validate and copy explicit memory settings before starting one worker.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure MemoryRunClick(Sender: TObject);
    /// <summary>Save the acquired encoded photo after choosing a destination.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SavePhotoClick(Sender: TObject);
  private
    FController: TCardDemoController;
    FDiscoveryStarted: Boolean;
    procedure StartRequest(const ARequest: TCardDemoRequest);
  private
    FRfid: TRfidKeyboardReader;
    FReaderEvents: TCardDemoReaderEvents;
    FPreviousReader: UnicodeString;
    FPhoto: TBytes;
    FPhotoIsJpeg2000: Boolean;
    procedure ReaderInventory(const ADevices: TCardDemoDevices);
    procedure ReaderStatus(const AText: string);
    procedure RfidIdentified(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
  protected
    /// <summary>Defers close until this form’s owned background operation completes.</summary>
    /// <returns>True only when inherited close permission and worker lifecycle permit it.</returns>
    function CloseQuery: Boolean; override;
    /// <summary>Disables operation inputs while hardware work is pending.</summary>
    /// <param name="AValue">True while busy.</param>
    procedure SetBusy(const AValue: Boolean);
    /// <summary>Displays completion, reader names, NDEF and encoded face data on the UI thread.</summary>
    /// <param name="AResult">Owned worker completion data.</param>
    procedure Complete(const AResult: TCardDemoResult);
  public
    /// <summary>Stops this form’s timer and joins its worker before destroying controls.</summary>
    destructor Destroy; override;
  end;

var
  /// <summary>Main form owned by the VCL Application.</summary>
  SmartCardForm: TSmartCardDemoForm;

implementation

uses
  ERD.Card.Demo.Operations, Winapi.Windows, Vcl.Imaging.jpeg, ERD.Card.Crypto, ERD.Card.Crypto.EAC,
  ERD.Card.EID.Access, ERD.Card.Contactless.Type2, ERD.Card.Ndef,
  ERD.Card.Ndef.Records, ERD.Card.Memory, ERD.Card.Memory.Counter,
  ERD.Card.Memory.Capabilities;

{$R *.dfm}

procedure TSmartCardDemoForm.FormCreate(Sender: TObject);
var M: TMemoryCardModel; C: TSleCounterModel;
begin
  FController := TCardDemoController.Create(ddkPcsc,CreateCardDemoOperations,SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  OperationBox.Items.Text := 'Offline NDEF inspect'#13#10'Read UID (PC/SC storage)'#13#10+
    'Read Belgian eID + photo'#13#10'Read ICAO DG1/DG2 + photo'#13#10+
    'Discover EMV contact PSE'#13#10'Discover EMV contactless PPSE'#13#10+
    'Read DESFire version'#13#10'Read Type 2 NDEF'#13#10'Read Type 4 NDEF'#13#10+
    'Replace Type 2 NDEF + verify'#13#10'Replace Type 4 NDEF + verify';
  OperationBox.ItemIndex := 0;
  ModelBox.Items.Text := 'Ultralight'#13#10'Ultralight EV1 48'#13#10+
    'Ultralight EV1 128'#13#10'NTAG213'#13#10'NTAG215'#13#10'NTAG216'#13#10'NTAG210'#13#10'NTAG212';
  SecurityBox.Items.Text := 'BAC'#13#10'PACE ECDH-GM AES-128';
  PasswordKindBox.Items.Text := 'MRZ information'#13#10'CAN';
  CurveBox.Items.Text := 'NIST P-256 (12)'#13#10'brainpool P256 (13)';
  MemoryActionBox.Items.Text := 'Offline profile capabilities'#13#10'Connected ATR / protocol'#13#10+
    'Read memory snapshot'#13#10'Read selected range'#13#10'Verify supplied PIN once'#13#10'Write range + verify';
  MemoryActionBox.ItemIndex := 0;
  for M := Low(TMemoryCardModel) to High(TMemoryCardModel) do
    MemoryModelBox.Items.Add(TAcsMemoryCapabilityCatalog.ModelName(M));
  for C := Low(TSleCounterModel) to High(TSleCounterModel) do
    MemoryModelBox.Items.Add(TAcsMemoryCapabilityCatalog.CounterName(C));
  MemoryModelBox.Items.Add('SLE4404');
  MemoryDialectBox.Items.Text := 'ACR38x CCID (explicit)'#13#10'ACR39 (explicit)';
  FRfid := TRfidKeyboardReader.Create(Self); FRfid.OnIdentifier := RfidIdentified;
  MemoryPageBox.Items.Text := '8 bytes'#13#10'16 bytes'#13#10'32 bytes'#13#10'64 bytes'#13#10'128 bytes';
end;

procedure TSmartCardDemoForm.RfidToggleClick(Sender: TObject);
var N: Integer;
begin
  try
    if FRfid.Active then FRfid.Stop
    else
    begin
      if not TryStrToInt(FRfidLength.Text,N) then raise EArgumentException.Create('Invalid exact length.');
      FRfid.ExpectedCharacters := N;
      if not TryStrToInt(FRfidTimeout.Text,N) or (N < 1) or (N > 60000) then
        raise EArgumentException.Create('Gap must be 1 through 60000 ms.');
      FRfid.InterCharacterTimeoutMs := Cardinal(N);
      FRfid.Encoding := TRfidInputEncoding(FRfidEncoding.ItemIndex);
      FRfid.Terminator := TRfidInputTerminator(FRfidTerminator.ItemIndex);
      FRfid.Prefix := FRfidPrefix.Text; FRfid.Suffix := FRfidSuffix.Text; FRfid.Start;
      OutputMemo.Lines.Text := 'RFID capture active. This foreground input does not identify a physical USB device.';
    end;
    FRfidSettings.Enabled := not FRfid.Active; FRfidCapture.Enabled := FRfid.Active;
    CardTab.Enabled := not FRfid.Active; MemoryTab.Enabled := not FRfid.Active;
    ReaderBox.Enabled := not FRfid.Active; ReadersButton.Enabled := not FRfid.Active;
    if FRfid.Active then
    begin FRfidToggle.Caption := 'Stop RFID capture'; FRfidCapture.Clear; FRfidCapture.SetFocus; end
    else FRfidToggle.Caption := 'Start RFID capture';
  except on E: Exception do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
end;

procedure TSmartCardDemoForm.RfidKeyPress(Sender: TObject; var Key: Char);
var C: Char;
begin
  C := Key; Key := #0;
  try FRfid.FeedCharacter(C,GetTickCount64);
  except on E: ERfidInputError do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
end;

procedure TSmartCardDemoForm.RfidIdentified(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  OutputMemo.Lines.Text := 'Presented identifier: ' + AIdentifier.Text;
  if AIdentifier.Encoding = rieHexadecimal then
    OutputMemo.Lines.Add('Presented hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TSmartCardDemoForm.SetBusy(const AValue: Boolean);
begin
  OperationPages.Enabled := not AValue;
  InputPanel.Enabled := not AValue;
  SavePhotoButton.Enabled := not AValue and (Length(FPhoto) > 0);
  if AValue then
  begin
    OutputMemo.Lines.Text := 'Operation running. Closing waits for completion; writes are never retried.';
    PhotoImage.Picture.Assign(nil); FPhoto := nil;
  end;
end;

procedure TSmartCardDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var I: Integer; Previous: string;
begin
  Previous := ReaderBox.Text;
  if Previous = '' then Previous := string(FPreviousReader);
  ReaderBox.Items.Clear;
  for I := 0 to High(ADevices) do ReaderBox.Items.Add(string(ADevices[I].Address));
  ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(Previous);
end;

procedure TSmartCardDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TSmartCardDemoForm.ReadersClick(Sender: TObject);
begin
  FPreviousReader := ReaderBox.Text;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use List readers to retry.'; end;
end;

procedure TSmartCardDemoForm.RunClick(Sender: TObject);
var R: TCardDemoRequest; I: Integer; Password: string;
begin
  R := Default(TCardDemoRequest);
  try
    case OperationBox.ItemIndex of
      0: R.Operation := cdoNdefInspect;
      1: R.Operation := cdoUid;
      2: R.Operation := cdoBelgianEid;
      3: R.Operation := cdoIcao;
      4: R.Operation := cdoEmvPse;
      5: R.Operation := cdoEmvPpse;
      6: R.Operation := cdoDesfireVersion;
      7: R.Operation := cdoType2Read;
      8: R.Operation := cdoType4Read;
      9: R.Operation := cdoType2Write;
      10: R.Operation := cdoType4Write;
    else raise EArgumentException.Create('Select an operation.'); end;
    R.ReaderName := ReaderBox.Text;
    if R.Operation in [cdoType2Read, cdoType2Write] then
    begin
      if ModelBox.ItemIndex < 0 then raise EArgumentException.Create('Select the actual Type 2 model.');
      R.Type2Model := TType2TagModel(ModelBox.ItemIndex);
    end;
    if R.Operation in [cdoNdefInspect, cdoType2Write, cdoType4Write] then
    begin
      if Length(NdefEdit.Text) > NdefMaxMessageBytes * 2 then
        raise EArgumentException.Create('NDEF input exceeds the supported bound.');
      R.NdefBytes := HexToBytes(NdefEdit.Text);
    end;
    if R.Operation = cdoIcao then
    begin
      if (SecurityBox.ItemIndex < 0) or (PasswordKindBox.ItemIndex < 0) then
        raise EArgumentException.Create('Select access protocol and password kind explicitly.');
      if (SecurityBox.ItemIndex = 1) and (CurveBox.ItemIndex < 0) then
        raise EArgumentException.Create('Select the PACE curve explicitly.');
      R.Security := TIcaoAccessSecurity(SecurityBox.ItemIndex);
      R.PasswordKind := TIcaoPasswordKind(PasswordKindBox.ItemIndex);
      if SecurityBox.ItemIndex = 1 then R.PaceCurve := TCardPaceCurve(CurveBox.ItemIndex);
      R.CryptoLibrary := LibraryEdit.Text;
      Password := PasswordEdit.Text;
      if Length(Password) > 24 then raise EArgumentException.Create('Access input exceeds its bound.');
      SetLength(R.Password, Length(Password));
      for I := 1 to Length(Password) do
      begin
        if Ord(Password[I]) > 127 then raise EArgumentException.Create('Access input must be ASCII.');
        R.Password[I - 1] := Ord(Password[I]);
      end;
    end;
    StartRequest(R);
    PasswordEdit.Clear;
  except on E: Exception do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
  TCardCrypto.Clear(R.Password);
  Password := '';
end;

procedure TSmartCardDemoForm.MemoryRunClick(Sender: TObject);
var R: TCardDemoRequest; L: TMemoryCardLayout; CounterIndex: Integer;
begin
  R := Default(TCardDemoRequest);
  try
    try
      case MemoryActionBox.ItemIndex of
        0: R.Operation := cdoMemoryCapabilities;
        1: R.Operation := cdoReaderStatus;
        2: R.Operation := cdoMemorySnapshot;
        3: R.Operation := cdoMemoryRead;
        4: R.Operation := cdoMemoryVerify;
        5: R.Operation := cdoMemoryWrite;
      else raise EArgumentException.Create('Select a memory operation.'); end;
      R.ReaderName := ReaderBox.Text;
      if R.Operation <> cdoReaderStatus then
      begin
        if MemoryDialectBox.ItemIndex < 0 then
          raise EArgumentException.Create('Select the matching ACS reader dialect.');
        R.MemoryDialect := TAcsMemoryDialect(MemoryDialectBox.ItemIndex);
      end;
      if not (R.Operation in [cdoMemoryCapabilities, cdoReaderStatus]) then
      begin
        if MemoryModelBox.ItemIndex < 0 then raise EArgumentException.Create('Select the actual chip model.');
        CounterIndex := MemoryModelBox.ItemIndex - Ord(High(TMemoryCardModel)) - 1;
        if R.Operation in [cdoMemoryRead, cdoMemoryWrite] then
          R.MemoryAddress := StrToInt(MemoryAddressEdit.Text);
        if R.Operation = cdoMemoryRead then R.MemoryCount := StrToInt(MemoryCountEdit.Text);
        if CounterIndex > Ord(High(TSleCounterModel)) then
        begin
          if not (R.Operation in [cdoMemorySnapshot, cdoMemoryRead]) then
            raise EArgumentException.Create('The SLE4404 demo offers public reads; use the component API for supplied codes and explicit erases.');
          R.CounterReadableBytes := StrToInt(CounterWindowEdit.Text);
          if R.Operation = cdoMemorySnapshot then
          begin R.MemoryAddress := 0; R.MemoryCount := R.CounterReadableBytes; end;
          R.Operation := cdoSle4404Read;
        end
        else if CounterIndex >= 0 then
        begin
          if not (R.Operation in [cdoMemorySnapshot, cdoMemoryRead]) then
            raise EArgumentException.Create('The counter demo offers public reads; use the counter component for explicit programming.');
          R.CounterModel := TSleCounterModel(CounterIndex);
          R.CounterReadableBytes := StrToInt(CounterWindowEdit.Text);
          if R.Operation = cdoMemorySnapshot then
          begin R.MemoryAddress := 0; R.MemoryCount := R.CounterReadableBytes; end;
          R.Operation := cdoCounterRead;
        end
        else
        begin
          R.MemoryModel := TMemoryCardModel(MemoryModelBox.ItemIndex);
          L := TMemoryCardCodec.Layout(R.MemoryModel);
          R.MinimumPinAttempts := StrToInt(MemoryAttemptsEdit.Text);
          R.MemoryPageSize := mps8;
          if MemoryPageBox.ItemIndex >= 0 then R.MemoryPageSize := TMemoryCardPageSize(MemoryPageBox.ItemIndex);
          if R.Operation in [cdoMemoryVerify, cdoMemoryWrite] then
          begin
            if Length(MemoryPinEdit.Text) > 6 then raise EArgumentException.Create('PIN exceeds its bound.');
            R.Password := HexToBytes(MemoryPinEdit.Text);
          end;
          if R.Operation = cdoMemoryWrite then
          begin
            if not MemoryWriteCheck.Checked then raise EArgumentException.Create('Acknowledge the requested memory change.');
            if (L.Selector <= 2) and (MemoryPageBox.ItemIndex < 0) then
              raise EArgumentException.Create('Select the physical I2C page size from the chip data sheet.');
            if Length(MemoryDataEdit.Text) > MemoryCardMaxBytes * 2 then
              raise EArgumentException.Create('Write payload exceeds its bound.');
            R.MemoryBytes := HexToBytes(MemoryDataEdit.Text);
          end;
        end;
      end;
      StartRequest(R);
      MemoryPinEdit.Clear; MemoryWriteCheck.Checked := False;
    except on E: Exception do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
  finally TCardCrypto.Clear(R.Password); end;
end;

procedure TSmartCardDemoForm.EncodeClick(Sender: TObject);
var Message: TNdefMessage;
begin
  try
    SetLength(Message, 1); Message[0] := TNdefRecords.Text(TextEdit.Text, 'en');
    NdefEdit.Text := BytesToHex(TNdefCodec.Encode(Message));
    OutputMemo.Lines.Text := 'Encoded one UTF-8 Text record offline.';
  except on E: Exception do OutputMemo.Lines.Text := E.ClassName + ': ' + E.Message; end;
end;

procedure TSmartCardDemoForm.Complete(const AResult: TCardDemoResult);
var I: Integer; SelectedReader: string; Stream: TBytesStream; Jpeg: TJPEGImage;
begin
  OutputMemo.Lines.Text := AResult.Text;
  if not AResult.Success then
  begin
    OutputMemo.Lines.Add('Failed: ' + AResult.ErrorClass + '. No automatic retry.');
    if AResult.WriteVerified then OutputMemo.Lines.Add('The write was verified before cleanup failed.')
    else if (AResult.ErrorClass = 'EContactlessWriteUncertain') or
      (AResult.ErrorClass = 'EMemoryCardWriteUncertain') then
      OutputMemo.Lines.Add('The write outcome is uncertain. Check card state before repeating.');
  end;
  if AResult.Operation = cdoReaders then
  begin
    SelectedReader := ReaderBox.Text;
    ReaderBox.Items.Clear;
    if AResult.Success then
      for I := 0 to High(AResult.Readers) do ReaderBox.Items.Add(AResult.Readers[I]);
    ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(SelectedReader);
  end;
  if Length(AResult.CounterBytes) > 0 then
    OutputMemo.Lines.Add('Special-chip public memory hex: ' + BytesToHex(AResult.CounterBytes));
  if Length(AResult.Memory.Data) > 0 then
    OutputMemo.Lines.Add('Memory hex: ' + BytesToHex(AResult.Memory.Data));
  if Length(AResult.Memory.Protection) > 0 then
    OutputMemo.Lines.Add('Protection hex (zero bits are locked): ' + BytesToHex(AResult.Memory.Protection));
  if AResult.Memory.HasSecurity then
    OutputMemo.Lines.Add('Remaining PIN attempts: ' + IntToStr(AResult.Memory.Security.RemainingAttempts));
  if Length(AResult.NdefBytes) > 0 then NdefEdit.Text := BytesToHex(AResult.NdefBytes);
  FPhoto := AResult.Photo; FPhotoIsJpeg2000 := AResult.PhotoIsJpeg2000;
  SavePhotoButton.Enabled := Length(FPhoto) > 0;
  if Length(FPhoto) = 0 then Exit;
  if FPhotoIsJpeg2000 then
  begin OutputMemo.Lines.Add('JPEG 2000 face retained; use Save photo for the encoded bytes.'); Exit; end;
  Stream := TBytesStream.Create(FPhoto); Jpeg := TJPEGImage.Create;
  try
    try Jpeg.LoadFromStream(Stream); PhotoImage.Picture.Assign(Jpeg);
    except on E: Exception do OutputMemo.Lines.Add('JPEG preview failed: ' + E.ClassName + '. Encoded bytes can still be saved.'); end;
  finally Jpeg.Free; Stream.Free; end;
end;

procedure TSmartCardDemoForm.SavePhotoClick(Sender: TObject);
var Stream: TFileStream;
begin
  if Length(FPhoto) = 0 then Exit;
  if FPhotoIsJpeg2000 then
  begin PhotoDialog.DefaultExt := 'jp2'; PhotoDialog.Filter := 'JPEG 2000|*.jp2'; PhotoDialog.FileName := 'face.jp2'; end
  else begin PhotoDialog.DefaultExt := 'jpg'; PhotoDialog.Filter := 'JPEG|*.jpg'; PhotoDialog.FileName := 'face.jpg'; end;
  if not PhotoDialog.Execute then Exit;
  try
    Stream := TFileStream.Create(PhotoDialog.FileName, fmCreate);
    try Stream.WriteBuffer(FPhoto[0], Length(FPhoto)); finally Stream.Free; end;
    OutputMemo.Lines.Add('Encoded photo saved.');
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TSmartCardDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TSmartCardDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TSmartCardDemoForm.CloseQuery: Boolean;
begin
  if FRfid <> nil then FRfid.Stop;
  Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo card operation to finish...';
end;

destructor TSmartCardDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; if FRfid <> nil then FRfid.Stop;
  FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TSmartCardDemoForm.FormShow(Sender: TObject);
begin
  if FDiscoveryStarted then Exit; FDiscoveryStarted := True; ReadersClick(nil);
end;

end.
