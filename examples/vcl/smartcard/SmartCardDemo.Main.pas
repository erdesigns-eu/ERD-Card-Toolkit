unit SmartCardDemo.Main;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, System.SysUtils,
  Vcl.Dialogs, ERD.Card.Bytes, ERD.Card.Demo.Job, ERD.Card.Demo.Form;

type
  /// <summary>Explicit PC/SC card operations with a background worker and optional face preview.</summary>
  TSmartCardDemoForm = class(TCardDemoForm)
  published
    /// <summary>Reader and explicit operation inputs.</summary>
    InputPanel: TPanel;
    /// <summary>Exact reader-name label.</summary>
    ReaderLabel: TLabel;
    /// <summary>Editable exact PC/SC reader name; no automatic reader selection.</summary>
    ReaderBox: TComboBox;
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
    /// <summary>Save the acquired encoded photo after choosing a destination.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SavePhotoClick(Sender: TObject);
  private
    FPhoto: TBytes;
    FPhotoIsJpeg2000: Boolean;
  protected
    /// <summary>Disables operation inputs while hardware work is pending.</summary>
    /// <param name="AValue">True while busy.</param>
    procedure SetBusy(const AValue: Boolean); override;
    /// <summary>Displays completion, reader names, NDEF and encoded face data on the UI thread.</summary>
    /// <param name="AResult">Owned worker completion data.</param>
    procedure Complete(const AResult: TCardDemoResult); override;
  end;

var
  /// <summary>Main form owned by the VCL Application.</summary>
  SmartCardForm: TSmartCardDemoForm;

implementation

uses
  Vcl.Imaging.jpeg, ERD.Card.Crypto, ERD.Card.Crypto.EAC,
  ERD.Card.EID.Access, ERD.Card.Contactless.Type2, ERD.Card.Ndef,
  ERD.Card.Ndef.Records;

{$R *.dfm}

procedure TSmartCardDemoForm.FormCreate(Sender: TObject);
begin
  OperationBox.Items.Text := 'Offline NDEF inspect'#13#10'Read UID (PC/SC storage)'#13#10+
    'Read Belgian eID + photo'#13#10'Read ICAO DG1/DG2 + photo'#13#10+
    'Discover EMV contact PSE'#13#10'Discover EMV contactless PPSE'#13#10+
    'Read DESFire version'#13#10'Read Type 2 NDEF'#13#10'Read Type 4 NDEF'#13#10+
    'Replace Type 2 NDEF + verify'#13#10'Replace Type 4 NDEF + verify';
  OperationBox.ItemIndex := 0;
  ModelBox.Items.Text := 'Ultralight'#13#10'Ultralight EV1 48'#13#10+
    'Ultralight EV1 128'#13#10'NTAG213'#13#10'NTAG215'#13#10'NTAG216';
  SecurityBox.Items.Text := 'BAC'#13#10'PACE ECDH-GM AES-128';
  PasswordKindBox.Items.Text := 'MRZ information'#13#10'CAN';
  CurveBox.Items.Text := 'NIST P-256 (12)'#13#10'brainpool P256 (13)';
end;

procedure TSmartCardDemoForm.SetBusy(const AValue: Boolean);
begin
  InputPanel.Enabled := not AValue;
  SavePhotoButton.Enabled := not AValue and (Length(FPhoto) > 0);
  if AValue then
  begin
    OutputMemo.Lines.Text := 'Operation running. Closing waits for completion; writes are never retried.';
    PhotoImage.Picture.Assign(nil); FPhoto := nil;
  end;
end;

procedure TSmartCardDemoForm.ReadersClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  R := Default(TCardDemoRequest); R.Operation := cdoReaders;
  StartRequest(R);
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
    else if AResult.ErrorClass = 'EContactlessWriteUncertain' then
      OutputMemo.Lines.Add('The write outcome is uncertain. Check card state before repeating.');
  end;
  if AResult.Success and (AResult.Operation = cdoReaders) then
  begin
    SelectedReader := ReaderBox.Text;
    ReaderBox.Items.Clear;
    for I := 0 to High(AResult.Readers) do ReaderBox.Items.Add(AResult.Readers[I]);
    ReaderBox.Text := SelectedReader;
  end;
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

end.
