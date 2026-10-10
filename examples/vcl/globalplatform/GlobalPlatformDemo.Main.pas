unit GlobalPlatformDemo.Main;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls, ERD.Card.Bytes, ERD.Card.Crypto,
  ERD.Card.PCSC.Monitor, ERD.Card.PCSC.Api, ERD.Card.Demo.Job,
  ERD.Card.Demo.GlobalPlatform.Operations;

type
  /// <summary>Independent designer-editable GP demo; no shared form or visual ancestor.</summary>
  TGlobalPlatformDemoForm = class(TForm)
  published
    /// <summary>Designer-owned scrolling content for the extended management inputs.</summary>
    ContentScroll: TScrollBox;

    /// <summary>Designer-owned key and delegated-management configuration.</summary>
    ManagementGroup: TGroupBox;

    /// <summary>Masked static session DEK required for symmetric PUT KEY.</summary>
    DekEdit: TEdit;

    /// <summary>Masked new symmetric key or ENC key.</summary>
    NewEncEdit: TEdit;

    /// <summary>Masked new MAC key for PUT KEY set.</summary>
    NewMacEdit: TEdit;

    /// <summary>Masked new DEK key for PUT KEY set.</summary>
    NewDekEdit: TEdit;

    /// <summary>Explicit new persistent key version.</summary>
    NewVersionEdit: TEdit;

    /// <summary>First key identifier for key management.</summary>
    NewKeyIdEdit: TEdit;

    /// <summary>Zero adds a key; nonzero replaces the explicitly specified version.</summary>
    OldVersionEdit: TEdit;

    /// <summary>Explicit new key type, DES or AES.</summary>
    KeyTypeBox: TComboBox;

    /// <summary>Explicit delegated token policy: none, AES CMAC or legacy RSA SHA-1.</summary>
    TokenTypeBox: TComboBox;

    /// <summary>Masked AES issuer token key.</summary>
    TokenKeyEdit: TEdit;

    /// <summary>Explicit receipt policy: none, legacy DES or AES.</summary>
    ReceiptTypeBox: TComboBox;

    /// <summary>Masked receipt key, separate from session and token keys.</summary>
    ReceiptKeyEdit: TEdit;

    /// <summary>Expected card unique data for authenticated receipts.</summary>
    ReceiptUidEdit: TEdit;

    /// <summary>Persisted last accepted receipt counter, minus one for first verification.</summary>
    ReceiptCounterEdit: TEdit;

    /// <summary>Explicit load-file hash; blank with DAP computes SHA-1 for the legacy profile.</summary>
    LoadHashEdit: TEdit;

    /// <summary>Complete externally provisioned E2 DAP block or blocks.</summary>
    DapEdit: TEdit;

    /// <summary>Explicit new domain AID for extradition.</summary>
    NewDomainEdit: TEdit;

    /// <summary>Unsigned big-endian RSA modulus for tokens or verification-key provision.</summary>
    RsaNEdit: TEdit;

    /// <summary>Unsigned big-endian RSA public exponent.</summary>
    RsaEEdit: TEdit;

    /// <summary>Masked RSA private exponent for native Linux signing.</summary>
    RsaDEdit: TEdit;

    /// <summary>Masked first RSA prime for native Windows signing.</summary>
    RsaPEdit: TEdit;

    /// <summary>Masked second RSA prime for native Windows signing.</summary>
    RsaQEdit: TEdit;

    /// <summary>Label for DekEdit.</summary>
    DekEditLabel: TLabel;

    /// <summary>Label for NewEncEdit.</summary>
    NewEncEditLabel: TLabel;

    /// <summary>Label for NewMacEdit.</summary>
    NewMacEditLabel: TLabel;

    /// <summary>Label for NewDekEdit.</summary>
    NewDekEditLabel: TLabel;

    /// <summary>Label for NewVersionEdit.</summary>
    NewVersionEditLabel: TLabel;

    /// <summary>Label for NewKeyIdEdit.</summary>
    NewKeyIdEditLabel: TLabel;

    /// <summary>Label for OldVersionEdit.</summary>
    OldVersionEditLabel: TLabel;

    /// <summary>Label for KeyTypeBox.</summary>
    KeyTypeBoxLabel: TLabel;

    /// <summary>Label for TokenTypeBox.</summary>
    TokenTypeBoxLabel: TLabel;

    /// <summary>Label for TokenKeyEdit.</summary>
    TokenKeyEditLabel: TLabel;

    /// <summary>Label for ReceiptTypeBox.</summary>
    ReceiptTypeBoxLabel: TLabel;

    /// <summary>Label for ReceiptKeyEdit.</summary>
    ReceiptKeyEditLabel: TLabel;

    /// <summary>Label for ReceiptUidEdit.</summary>
    ReceiptUidEditLabel: TLabel;

    /// <summary>Label for ReceiptCounterEdit.</summary>
    ReceiptCounterEditLabel: TLabel;

    /// <summary>Label for LoadHashEdit.</summary>
    LoadHashEditLabel: TLabel;

    /// <summary>Label for DapEdit.</summary>
    DapEditLabel: TLabel;

    /// <summary>Label for NewDomainEdit.</summary>
    NewDomainEditLabel: TLabel;

    /// <summary>Label for RsaNEdit.</summary>
    RsaNEditLabel: TLabel;

    /// <summary>Label for RsaEEdit.</summary>
    RsaEEditLabel: TLabel;

    /// <summary>Label for RsaDEdit.</summary>
    RsaDEditLabel: TLabel;

    /// <summary>Label for RsaPEdit.</summary>
    RsaPEditLabel: TLabel;

    /// <summary>Label for RsaQEdit.</summary>
    RsaQEditLabel: TLabel;

    /// <summary>Available card reader.</summary>
    ReaderLabel: TLabel;

    /// <summary>Exact in-app reader selection.</summary>
    ReaderBox: TComboBox;

    /// <summary>Restart native reader/card observation.</summary>
    RefreshButton: TButton;

    /// <summary>Explicit operation label.</summary>
    ActionLabel: TLabel;

    /// <summary>Read or management operation.</summary>
    ActionBox: TComboBox;

    /// <summary>Secure-channel protocol label.</summary>
    ProtocolLabel: TLabel;

    /// <summary>SCP02 i=15 or SCP03.</summary>
    ProtocolBox: TComboBox;

    /// <summary>Protection label.</summary>
    LevelLabel: TLabel;

    /// <summary>Explicit command/response protection.</summary>
    LevelBox: TComboBox;

    /// <summary>Security-domain AID label.</summary>
    DomainLabel: TLabel;

    /// <summary>Explicit target security-domain AID.</summary>
    DomainEdit: TEdit;

    /// <summary>Key version label.</summary>
    VersionLabel: TLabel;

    /// <summary>Explicit decimal key-set version.</summary>
    VersionEdit: TEdit;

    /// <summary>Key identifier label.</summary>
    KeyIdLabel: TLabel;

    /// <summary>SCP02 key identifier, zero for SCP03.</summary>
    KeyIdEdit: TEdit;

    /// <summary>ENC key label.</summary>
    EncLabel: TLabel;

    /// <summary>Masked explicit ENC key.</summary>
    EncEdit: TEdit;

    /// <summary>MAC key label.</summary>
    MacLabel: TLabel;

    /// <summary>Masked explicit MAC key.</summary>
    MacEdit: TEdit;

    /// <summary>Explicit SCP03 S16 request.</summary>
    S16Check: TCheckBox;

    /// <summary>Authenticate before read operations.</summary>
    AuthReadCheck: TCheckBox;

    /// <summary>Explicit tagged versus legacy registry format.</summary>
    TaggedCheck: TCheckBox;

    /// <summary>CAP archive label.</summary>
    CapLabel: TLabel;

    /// <summary>CAP archive path, loaded with Delphi System.Zip.</summary>
    CapEdit: TEdit;

    /// <summary>Choose a CAP archive.</summary>
    BrowseButton: TButton;

    /// <summary>Applet module AID label.</summary>
    ModuleLabel: TLabel;

    /// <summary>Applet AID present in Applet.cap.</summary>
    ModuleEdit: TEdit;

    /// <summary>Instance AID label.</summary>
    InstanceLabel: TLabel;

    /// <summary>Explicit instance AID for install/delete/status.</summary>
    InstanceEdit: TEdit;

    /// <summary>Privilege mask label.</summary>
    PrivilegeLabel: TLabel;

    /// <summary>Explicit one- or three-byte privileges.</summary>
    PrivilegeEdit: TEdit;

    /// <summary>Application/load parameter label.</summary>
    ParameterLabel: TLabel;

    /// <summary>Hexadecimal explicit application or load parameters.</summary>
    ParameterEdit: TEdit;

    /// <summary>Clear LOAD block size label.</summary>
    BlockLabel: TLabel;

    /// <summary>One through 220 clear LOAD bytes.</summary>
    BlockEdit: TEdit;

    /// <summary>Lifecycle label.</summary>
    LifeLabel: TLabel;

    /// <summary>Explicit application lifecycle hex byte.</summary>
    LifeEdit: TEdit;

    /// <summary>Explicit delete-related-objects flag.</summary>
    RelatedCheck: TCheckBox;

    /// <summary>Per-action acknowledgement of authentication/management.</summary>
    AcknowledgeCheck: TCheckBox;

    /// <summary>Start one snapshotted background operation.</summary>
    RunButton: TButton;

    /// <summary>Clear entered key fields and output.</summary>
    ClearButton: TButton;

    /// <summary>Input requirements and partial-load behavior.</summary>
    HelpMemo: TMemo;

    /// <summary>Completed metadata and acknowledged LOAD progress.</summary>
    OutputMemo: TMemo;

    /// <summary>Inspects the local CAP package before any card connection.</summary>
    PreviewButton: TButton;

    /// <summary>Confirmed LOAD percentage; completion of other management steps is separate.</summary>
    LoadProgress: TProgressBar;

    /// <summary>Confirmed LOAD byte and block counts, separate from reader observation.</summary>
    ProgressLabel: TLabel;

    /// <summary>Native reader/card observation status.</summary>
    StatusLabel: TLabel;

    /// <summary>Reads worker progress and completion only; never polls readers or cards.</summary>
    JobTimer: TTimer;

    /// <summary>Designer-owned CAP chooser.</summary>
    CapDialog: TOpenDialog;

    /// <summary>Initializes inactive worker state and native reader/card events.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure FormCreate(Sender: TObject);

    /// <summary>Stops native observation and joins owned worker state.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure FormDestroy(Sender: TObject);

    /// <summary>Restarts native reader observation within this application.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure RefreshClick(Sender: TObject);

    /// <summary>Snapshots inputs and starts one background request.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure RunClick(Sender: TObject);

    /// <summary>Clears entered key text and completed output.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure ClearClick(Sender: TObject);

    /// <summary>Chooses a local CAP archive without accessing a card.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure BrowseClick(Sender: TObject);

    /// <summary>Displays validated package/applet AIDs and sizes without connecting a card.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure PreviewClick(Sender: TObject);

    /// <summary>Explains the explicitly chosen action.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure ActionChanged(Sender: TObject);

    /// <summary>Displays confirmed upload progress and consumes completed results without hardware polling.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure JobTick(Sender: TObject);

    /// <summary>Defers close until the current non-retried operation finishes.</summary>
    /// <param name="Sender">The form.</param>
    /// <param name="CanClose">False while a worker owns card operations.</param>
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

  private
    FMonitor: TSmartCardMonitor;
    FJob: TCardDemoJob;
    FProgress: ICardGpDemoProgress;
    FClosing: Boolean;
    FPreviousReader: string;
    procedure ReaderAdded(Sender: TObject; const AName: UnicodeString);
    procedure ReaderRemoved(Sender: TObject; const AName: UnicodeString);
    procedure CardChanged(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
    procedure MonitorError(Sender: TObject; const AStatus: Cardinal);
    procedure SetBusy(const Busy: Boolean);
    procedure UpdateProgress;
  end;

var
  /// <summary>Application-owned independent GlobalPlatform form.</summary>
  GlobalPlatformDemoForm: TGlobalPlatformDemoForm;

implementation

uses
  ERD.Card.GlobalPlatform.CAP;

{$R *.dfm}

procedure TGlobalPlatformDemoForm.FormCreate(Sender: TObject);
begin
  ActionBox.ItemIndex := 0; ProtocolBox.ItemIndex := 1; LevelBox.ItemIndex := 1;
  FMonitor := TSmartCardMonitor.Create(Self);
  FMonitor.OnReaderAdded := ReaderAdded; FMonitor.OnReaderRemoved := ReaderRemoved;
  FMonitor.OnStateChanged := CardChanged; FMonitor.OnError := MonitorError;
  ActionChanged(Self); RefreshClick(Self);
end;

procedure TGlobalPlatformDemoForm.FormDestroy(Sender: TObject);
begin
  FMonitor.Free; FJob.Free;
end;

procedure TGlobalPlatformDemoForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FJob = nil;
  if not CanClose then
  begin
    FClosing := True;
    StatusLabel.Caption := 'Waiting for current operation; no automatic cancellation or retry.';
  end;
end;

procedure TGlobalPlatformDemoForm.RefreshClick(Sender: TObject);
begin
  FPreviousReader := ReaderBox.Text; FMonitor.Stop; ReaderBox.Items.Clear;
  try FMonitor.Start;
  except StatusLabel.Caption := 'Reader observation unavailable.'; end;
end;

procedure TGlobalPlatformDemoForm.ReaderAdded(Sender: TObject; const AName: UnicodeString);
begin
  if ReaderBox.Items.IndexOf(AName) < 0 then ReaderBox.Items.Add(AName);
  if (FPreviousReader <> '') and (AName = FPreviousReader) then
    ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(AName);
  StatusLabel.Caption := 'Reader connected: ' + AName;
end;

procedure TGlobalPlatformDemoForm.ReaderRemoved(Sender: TObject; const AName: UnicodeString);
var
  I: Integer;
  Selected: string;
begin
  Selected := ReaderBox.Text; I := ReaderBox.Items.IndexOf(AName);
  if I >= 0 then ReaderBox.Items.Delete(I);
  ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(Selected);
  StatusLabel.Caption := 'Reader disconnected: ' + AName;
end;

procedure TGlobalPlatformDemoForm.CardChanged(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
begin
  if ASnapshot.State and PcscStatePresent <> 0 then
    StatusLabel.Caption := 'Card offered: ' + ASnapshot.ReaderName
  else StatusLabel.Caption := 'No card: ' + ASnapshot.ReaderName;
end;

procedure TGlobalPlatformDemoForm.MonitorError(Sender: TObject; const AStatus: Cardinal);
begin
  ReaderBox.Items.Clear;
  StatusLabel.Caption := 'Reader observation stopped: ' + IntToHex(AStatus, 8);
end;

procedure TGlobalPlatformDemoForm.SetBusy(const Busy: Boolean);
begin
  RunButton.Enabled := not Busy; RefreshButton.Enabled := not Busy;
  BrowseButton.Enabled := not Busy; PreviewButton.Enabled := not Busy;
  ReaderBox.Enabled := not Busy; ClearButton.Enabled := not Busy;
  JobTimer.Enabled := Busy;
end;

procedure TGlobalPlatformDemoForm.ActionChanged(Sender: TObject);
begin
  ModuleLabel.Caption := 'CAP applet module AID';
  if ActionBox.ItemIndex = 15 then ModuleLabel.Caption := 'Package AID for receipt verification';
  if ActionBox.ItemIndex = 16 then ModuleLabel.Caption := 'Old security-domain AID';
  case ActionBox.ItemIndex of
    0: HelpMemo.Text := 'Reads CPLC. Select the reader and explicit security-domain AID. Dates remain raw.';
    1..4: HelpMemo.Text := 'Reads one registry category. Select tagged or legacy format explicitly. Enable authenticated reads only when needed and provide keys.';
    5: HelpMemo.Text := 'Authenticates once with already diversified sixteen-byte ENC/MAC keys. SCP02 uses i=15; SCP03 uses the selected S8/S16 and protection. No default keys or automatic fallback.';
    6: HelpMemo.Text := 'Loads the CAP package only. Archive is validated before connecting. Uses explicit domain, block size and GP load parameters. A partial failure is not rolled back or retried.';
    7: HelpMemo.Text := 'Installs an applet from a previously loaded CAP. Supply its module AID, new instance AID, privilege mask and raw application parameters. No automatic loading/deletion.';
    8: HelpMemo.Text := 'Deletes the explicit instance/package AID. Delete-related-objects applies only when selected.';
    10: HelpMemo.Text := 'Reads key identifiers, versions and component metadata; never reads secret keys.';
    11..14: HelpMemo.Text := 'Explicit key management: supply old version (zero adds), new version and key identifier. Symmetric PUT KEY requires the session DEK. The session closes after submission, including failures.';
    15: HelpMemo.Text := 'Makes the specified installed instance selectable. Supply explicit privileges; Module AID is the owning package when receipt verification is enabled.';
    16: HelpMemo.Text := 'Extradites the instance from Module AID (old domain) to New domain. Receipt verification binds all three AIDs.';
    9: HelpMemo.Text := 'Sets the explicit application lifecycle byte for the supplied instance AID. Check the card specification.';
  end;
end;

procedure TGlobalPlatformDemoForm.RunClick(Sender: TObject);
var
  Q: TCardDemoRequest;
  I: Integer;
begin
  if FJob <> nil then Exit;
  Q := Default(TCardDemoRequest);
  try
    if (ReaderBox.ItemIndex < 0) or not FMonitor.Active then
      raise EArgumentException.Create('Select a connected reader.');
    if (ActionBox.ItemIndex < 0) or (ProtocolBox.ItemIndex < 0) or (LevelBox.ItemIndex < 0) then
      raise EArgumentException.Create('Select action, protocol and protection.');
    Q.Operation := cdoFamily; Q.FamilyName := 'GlobalPlatform'; Q.FamilyAction := ActionBox.ItemIndex;
    Q.ReaderName := ReaderBox.Text; Q.MutationAcknowledged := AcknowledgeCheck.Checked;
    SetLength(Q.Arguments, 29); SetLength(Q.Credentials, 11);
    Q.Arguments[0] := DomainEdit.Text; Q.Arguments[1] := IntToStr(ProtocolBox.ItemIndex);
    Q.Arguments[2] := IntToStr(LevelBox.ItemIndex); Q.Arguments[3] := VersionEdit.Text;
    Q.Arguments[4] := KeyIdEdit.Text; Q.Arguments[5] := IntToStr(Ord(S16Check.Checked));
    Q.Arguments[6] := CapEdit.Text; Q.Arguments[7] := ModuleEdit.Text;
    Q.Arguments[8] := InstanceEdit.Text; Q.Arguments[9] := PrivilegeEdit.Text;
    Q.Arguments[10] := ParameterEdit.Text; Q.Arguments[11] := IntToStr(Ord(RelatedCheck.Checked));
    Q.Arguments[12] := LifeEdit.Text; Q.Arguments[13] := IntToStr(Ord(TaggedCheck.Checked));
    Q.Arguments[14] := BlockEdit.Text; Q.Arguments[15] := IntToStr(Ord(AuthReadCheck.Checked));
    Q.Arguments[16] := NewVersionEdit.Text; Q.Arguments[17] := NewKeyIdEdit.Text;
    Q.Arguments[18] := IntToStr(KeyTypeBox.ItemIndex); Q.Arguments[19] := IntToStr(TokenTypeBox.ItemIndex);
    Q.Arguments[20] := IntToStr(ReceiptTypeBox.ItemIndex); Q.Arguments[21] := ReceiptUidEdit.Text;
    Q.Arguments[22] := ReceiptCounterEdit.Text; Q.Arguments[23] := LoadHashEdit.Text;
    Q.Arguments[24] := DapEdit.Text; Q.Arguments[25] := NewDomainEdit.Text;
    Q.Arguments[26] := RsaEEdit.Text; Q.Arguments[27] := RsaNEdit.Text;
    Q.Arguments[28] := OldVersionEdit.Text;
    if (ActionBox.ItemIndex in [5..9, 11..16]) or AuthReadCheck.Checked then
    begin
      if not Q.MutationAcknowledged then raise EArgumentException.Create('Acknowledge this action.');
      Q.Credentials[0] := HexToBytes(EncEdit.Text, True); Q.Credentials[1] := HexToBytes(MacEdit.Text, True);
      Q.Credentials[2] := HexToBytes(DekEdit.Text, True);
      Q.Credentials[3] := HexToBytes(NewEncEdit.Text, True); Q.Credentials[4] := HexToBytes(NewMacEdit.Text, True);
      Q.Credentials[5] := HexToBytes(NewDekEdit.Text, True); Q.Credentials[6] := HexToBytes(TokenKeyEdit.Text, True);
      Q.Credentials[7] := HexToBytes(ReceiptKeyEdit.Text, True); Q.Credentials[8] := HexToBytes(RsaDEdit.Text, True);
      Q.Credentials[9] := HexToBytes(RsaPEdit.Text, True); Q.Credentials[10] := HexToBytes(RsaQEdit.Text, True);
    end;
    OutputMemo.Clear; LoadProgress.Position := 0;
    ProgressLabel.Caption := 'No LOAD blocks acknowledged.';
    FProgress := CreateGlobalPlatformDemoProgress;
    FJob := TCardDemoJob.Create(Q, CreateGlobalPlatformDemoOperations(FProgress));
    try FJob.StartWork;
    except FreeAndNil(FJob); raise; end;
    SetBusy(True); AcknowledgeCheck.Checked := False;
  except
    on E: Exception do OutputMemo.Text := E.ClassName + ': check selected reader and required inputs.';
  end;
  for I := 0 to High(Q.Credentials) do TCardCrypto.Clear(Q.Credentials[I]);
end;

procedure TGlobalPlatformDemoForm.UpdateProgress;
var
  P: TCardGpDemoProgress;
begin
  if FProgress <> nil then
  begin
    P := FProgress.ReadSnapshot;
    if P.TotalBytes > 0 then
    begin
      LoadProgress.Position := Integer(Int64(P.AcknowledgedBytes) * 100 div P.TotalBytes);
      ProgressLabel.Caption := Format('Acknowledged LOAD: %d / %d bytes; %d blocks.',
        [P.AcknowledgedBytes, P.TotalBytes, P.AcknowledgedBlocks]);
    end;
  end;
end;

procedure TGlobalPlatformDemoForm.JobTick(Sender: TObject);
var
  R: TCardDemoResult;
begin
  if FJob = nil then Exit;
  UpdateProgress;
  R := Default(TCardDemoResult);
  if not FJob.TryTakeResult(R) then Exit;
  UpdateProgress;
  FreeAndNil(FJob); FProgress := nil; SetBusy(False);
  if R.Success then OutputMemo.Text := R.Text
  else
  begin
    OutputMemo.Text := R.ErrorClass + ': operation failed; no retry was performed.';
    if R.Text <> '' then OutputMemo.Lines.Add(R.Text);
    ProgressLabel.Caption := ProgressLabel.Caption + ' Operation failed.';
    if R.WriteUncertain then OutputMemo.Lines.Add('Management may be partially applied. Inspect card state before a new action.');
  end;
  if FClosing then Close;
end;

procedure TGlobalPlatformDemoForm.ClearClick(Sender: TObject);
begin
  LoadProgress.Position := 0; ProgressLabel.Caption := 'No LOAD blocks acknowledged.';
  EncEdit.Clear; MacEdit.Clear;
  DekEdit.Clear; NewEncEdit.Clear; NewMacEdit.Clear; NewDekEdit.Clear;
  TokenKeyEdit.Clear; ReceiptKeyEdit.Clear; RsaDEdit.Clear; RsaPEdit.Clear; RsaQEdit.Clear; OutputMemo.Clear; AcknowledgeCheck.Checked := False;
end;

procedure TGlobalPlatformDemoForm.BrowseClick(Sender: TObject);
begin
  if CapDialog.Execute then
  begin
    CapEdit.Text := CapDialog.FileName;
    PreviewClick(Self);
  end;
end;

procedure TGlobalPlatformDemoForm.PreviewClick(Sender: TObject);
var
  Cap: TGpCapFile;
  Source: TFileStream;
  Applets: TGpAppletAids;
  I: Integer;
begin
  if FJob <> nil then Exit;
  OutputMemo.Clear;
  try
    Cap := TGpCapFile.FromFile(CapEdit.Text);
    try
      Source := TFileStream.Create(CapEdit.Text, fmOpenRead or fmShareDenyWrite);
      try OutputMemo.Lines.Add(Format('Archive size: %d bytes.', [Source.Size]));
      finally Source.Free; end;
      OutputMemo.Lines.Add('Package AID: ' + BytesToHex(Cap.PackageAid));
      Applets := Cap.Applets;
      OutputMemo.Lines.Add(Format('Applets: %d', [Length(Applets)]));
      for I := 0 to High(Applets) do OutputMemo.Lines.Add('  ' + BytesToHex(Applets[I]));
      OutputMemo.Lines.Add(Format('Raw load-file data: %d bytes.', [Length(Cap.LoadFileData)]));
      OutputMemo.Lines.Add(Format('C4 load image: %d bytes (DAP blocks excluded).', [Length(Cap.LoadImage)]));
      OutputMemo.Lines.Add('Local structural preview; no card connection or upload performed.');
    finally Cap.Free; end;
  except
    on E: Exception do OutputMemo.Text := E.ClassName + ': CAP preview failed; check the archive and path.';
  end;
end;

end.
