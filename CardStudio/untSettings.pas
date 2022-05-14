unit untSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, untUSB, untPCSC,
  Vcl.Imaging.pngimage;

type
  TfrmSettings = class(TForm)
    Panel2: TPanel;
    btnHelp: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    TV: TTreeView;
    PC: TPageControl;
    tsMagStripe: TTabSheet;
    PCMagStripe: TPageControl;
    tsMSMagStripe: TTabSheet;
    tsMSYL160: TTabSheet;
    tsMSMSR: TTabSheet;
    GroupBox1: TGroupBox;
    cbYL160AutoConnect: TCheckBox;
    GroupBox3: TGroupBox;
    cbYL160BaudRate: TComboBox;
    GroupBox2: TGroupBox;
    cbMSRAutoConnect: TCheckBox;
    GroupBox4: TGroupBox;
    cbMSRPort: TComboBox;
    GroupBox5: TGroupBox;
    cbMSRBaudRate: TComboBox;
    GroupBox6: TGroupBox;
    cbMSRCardType: TComboBox;
    GroupBox7: TGroupBox;
    Label1: TLabel;
    lblMSR: TLabel;
    btnMSRLEDG: TButton;
    btnMSRLEDY: TButton;
    btnMSRLEDR: TButton;
    btnMSRLEDAllOff: TButton;
    btnMSRLEDAllOn: TButton;
    GroupBox8: TGroupBox;
    Label2: TLabel;
    lblYL160: TLabel;
    btnMSRSensorTest: TButton;
    btnMSRRAMTest: TButton;
    tsSmartCard: TTabSheet;
    tsBINCheck: TTabSheet;
    pcBINCheck: TPageControl;
    tsBINCheckM: TTabSheet;
    GroupBox9: TGroupBox;
    Label3: TLabel;
    Image1: TImage;
    Image2: TImage;
    Label4: TLabel;
    tsBinCodes: TTabSheet;
    tsBinTable: TTabSheet;
    gbTrack: TGroupBox;
    memBinCodesAPIKey: TMemo;
    Label5: TLabel;
    Label6: TLabel;
    lblBinCodesRegister: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    GroupBox11: TGroupBox;
    memBinTableAPIKey: TMemo;
    GroupBox12: TGroupBox;
    cbDefaultBinCheck: TComboBox;
    tsAPILayer: TTabSheet;
    Label7: TLabel;
    Label8: TLabel;
    Label12: TLabel;
    GroupBox10: TGroupBox;
    memAPILayerAPIKey: TMemo;
    tsDatabase: TTabSheet;
    SaveDBDialog: TSaveDialog;
    OpenDBDialog: TOpenDialog;
    pcDB: TPageControl;
    tsDatabaseM: TTabSheet;
    gbDBFilename: TGroupBox;
    edtDBFilename: TEdit;
    btnBrowseDB: TButton;
    btnCreateDB: TButton;
    pcSmartCard: TPageControl;
    tsPCSC: TTabSheet;
    GroupBox13: TGroupBox;
    cbPCSCReader: TComboBox;
    tsPCSCJcop: TTabSheet;
    GroupBox14: TGroupBox;
    edtPCSCTransportKey: TEdit;
    GroupBox15: TGroupBox;
    edtPCSCEncryptionKey: TEdit;
    GroupBox16: TGroupBox;
    edtPCSCMACKey: TEdit;
    GroupBox17: TGroupBox;
    edtPCSCDataKey: TEdit;
    tsPCSCVisa: TTabSheet;
    tsPCSCMastercard: TTabSheet;
    tsPCSCMaestro: TTabSheet;
    GroupBox18: TGroupBox;
    edtPCSCVisaEKey: TEdit;
    GroupBox19: TGroupBox;
    edtPCSCVisaMKey: TEdit;
    GroupBox20: TGroupBox;
    edtPCSCVisaDKey: TEdit;
    GroupBox21: TGroupBox;
    edtPCSCMasterCardEKey: TEdit;
    GroupBox22: TGroupBox;
    edtPCSCMasterCardMKey: TEdit;
    GroupBox23: TGroupBox;
    edtPCSCMasterCardDKey: TEdit;
    GroupBox24: TGroupBox;
    edtPCSCMaestroEKey: TEdit;
    GroupBox25: TGroupBox;
    edtPCSCMaestroMKey: TEdit;
    GroupBox26: TGroupBox;
    edtPCSCMaestroDKey: TEdit;
    GroupBox27: TGroupBox;
    Label13: TLabel;
    Image3: TImage;
    Label14: TLabel;
    tsProject: TTabSheet;
    pcProject: TPageControl;
    tsProject1: TTabSheet;
    gbAuthor: TGroupBox;
    edtAuthor: TEdit;
    gbWebsite: TGroupBox;
    edtWebsite: TEdit;
    gbEmail: TGroupBox;
    edtEmail: TEdit;
    gbTelegram: TGroupBox;
    edtTelegram: TEdit;
    tsMemoryCard: TTabSheet;
    pcMemoryCard: TPageControl;
    tsMemoryCard1: TTabSheet;
    GroupBox28: TGroupBox;
    cbMCReader: TComboBox;
    GroupBox29: TGroupBox;
    Label15: TLabel;
    Image4: TImage;
    Label16: TLabel;
    tsMCSLE4442: TTabSheet;
    gbMCDefaultPIN: TGroupBox;
    edtMCDefaultPin: TEdit;
    gbMCSelectCard: TGroupBox;
    cbMCSLE4442SelectCard: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TVChange(Sender: TObject; Node: TTreeNode);
    procedure btnMSRLEDGClick(Sender: TObject);
    procedure lblBinCodesRegisterClick(Sender: TObject);
    procedure lblBinCodesRegisterMouseEnter(Sender: TObject);
    procedure lblBinCodesRegisterMouseLeave(Sender: TObject);
    procedure btnBrowseDBClick(Sender: TObject);
    procedure btnCreateDBClick(Sender: TObject);
  private
    { Private declarations }
    FUSBNotifier : TComponentUSB;
    FCOMPorts    : TStringList;
    PCSC         : TPCSC;

    procedure LoadCOMPorts;
    procedure USBArrivalRemoval(Sender: TObject);
  public
    { Public declarations }
    function Execute(const Index: Integer = -1) : TModalResult;
    procedure LoadSettings;
    procedure SaveSettings;
  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.dfm}

uses untLIB160, untMSR_API, untMain, untConst, Registry, ShellAPI,
     SQLite3, SQLite3Wrap;

{*******************************************************}
{                   Load COM Ports                      }
{*******************************************************}
procedure TfrmSettings.LoadCOMPorts;
var
  R : TRegistry;
  I : Integer;
  S : TStringList;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_LOCAL_MACHINE;
    R.OpenKey('hardware\devicemap\serialcomm', False);
    S := TStringList.Create;
    try
      R.GetValueNames(S);
      for I := 0 to S.Count - 1 do
      FCOMPorts.Add(R.Readstring(S[I]));
    finally
      S.Free;
    end;
    R.CloseKey;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{               USB Insert/Remove Event                 }
{*******************************************************}
procedure TfrmSettings.USBArrivalRemoval(Sender: TObject);

  function ReadYL160SN : string;
  var
    SN : array [0..255] of AnsiChar;
    SS : AnsiString;
  begin
    Result := 'Not Connected';
    if frmMain.YL160Connected and (ReadSN(SN) <> 0) then
    begin
      SetString(SS, SN, Length(SN));
      Result := Format('%s', [Copy(SS, 1, Pos(' ', SS, Pos(' ', SS) +1))]);
    end;
  end;

  function ReadMSR : string;
  var
    SN : array [0..255] of AnsiChar;
    SS : AnsiString;
  begin
    Result := 'Not Connected';
    if frmMain.MSRConnected and (MSR_Get_Firmware_Version(SN) <> 0) then
    begin
      SetString(SS, SN, Length(SN));
      Result := Format('%s', [SS]);
    end;
  end;

  procedure ReadPCSC(const Default: string);
  begin
    // Reload SmartCard Reader/Writers
    PCSC.Init;
    // Populate list
    cbPCSCReader.Items.Assign(PCSC.ReaderList);
    if cbPCSCReader.Items.Count > 0 then
    begin
      cbPCSCReader.ItemIndex := cbPCSCReader.Items.IndexOf(Default);
    end;
    // Disconnect PCSC
    PCSC.Disconnect;
    PCSC.Close;
  end;

  procedure ReadMC(const Default: string);
  begin
    // Reload Memory Card Reader/Writers
    PCSC.Init;
    // Populate list
    cbMCReader.Items.Assign(PCSC.ReaderList);
    if cbMCReader.Items.Count > 0 then
    begin
      cbMCReader.ItemIndex := cbMCReader.Items.IndexOf(Default);
    end;
    // Disconnect PCSC
    PCSC.Disconnect;
    PCSC.Close;
  end;

var
  S : string;
begin
  // Reload COM Ports
  LoadCOMPorts;
  // Update MSR list of ports
  S := cbMSRPort.Text;
  cbMSRPort.Clear;
  cbMSRPort.Items.Assign(FCOMPorts);
  cbMSRPort.Items.Insert(0, 'HID');
  cbMSRPort.ItemIndex := cbMSRPort.Items.IndexOf(S);
  // If YL160 is connected, get firmware version
  lblYL160.Caption := ReadYL160SN;
  // If MSR is connected, get firmware version
  lblMSR.Caption := ReadMSR;
  // Enable/Disable MSR test buttons
  btnMSRLEDG.Enabled       := frmMain.MSRConnected;
  btnMSRLEDY.Enabled       := frmMain.MSRConnected;
  btnMSRLEDR.Enabled       := frmMain.MSRConnected;
  btnMSRLEDAllOn.Enabled   := frmMain.MSRConnected;
  btnMSRLEDAllOff.Enabled  := frmMain.MSRConnected;
  btnMSRSensorTest.Enabled := frmMain.MSRConnected;
  btnMSRRAMTest.Enabled    := frmMain.MSRConnected;
  // Smartcard
  S := cbPCSCReader.Text;
  ReadPCSC(S);
  // Memory Card
  S := cbMCReader.Text;
  ReadMC(S);
end;

{*******************************************************}
{                   Execute Dialog                      }
{*******************************************************}
function TfrmSettings.Execute(const Index: Integer = -1): TModalResult;
begin
  LoadSettings;
  if (Index > -1) then TV.Select(TV.Items[Index]);
  Result := ShowModal;
end;

{*******************************************************}
{             Load Settings from Registry               }
{*******************************************************}
procedure TfrmSettings.LoadSettings;
var
  R : TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // MagStripe YL160
      if R.ValueExists(YL160AutoConnect) then
      cbYL160AutoConnect.Checked := R.ReadBool(YL160AutoConnect);
      if R.ValueExists(YL160BaudRate) then
      cbYL160BaudRate.ItemIndex  := cbYL160BaudRate.Items.IndexOf(R.ReadString(YL160BaudRate));
      // MagStripe MSR
      if R.ValueExists(MSRAutoConnect) then
      cbMSRAutoConnect.Checked := R.ReadBool(MSRAutoConnect);
      if R.ValueExists(MSRPort) then
      cbMSRPort.ItemIndex := cbMSRPort.Items.IndexOf(R.ReadString(MSRPort));
      if R.ValueExists(MSRBaudRate) then
      cbMSRBaudRate.ItemIndex := cbMSRBaudRate.Items.IndexOf(R.ReadString(MSRBaudRate));
      if R.ValueExists(MSRCardType) then
      cbMSRCardType.ItemIndex := R.ReadInteger(MSRCardType);
      // Default Smartcard Reader
      if R.ValueExists(PCSCDefault) then
      cbPCSCReader.ItemIndex := cbPCSCReader.Items.IndexOf(R.ReadString(PCSCDefault));
      // JCOP Transport Key
      if R.ValueExists(PCSCTransportKey) then
      edtPCSCTransportKey.Text := R.ReadString(PCSCTransportKey);
      // JCOP Encryption Key
      if R.ValueExists(PCSCEncryptionKey) then
      edtPCSCEncryptionKey.Text := R.ReadString(PCSCEncryptionKey);
      // JCOP MAC Key
      if R.ValueExists(PCSCMACKey) then
      edtPCSCMACKey.Text := R.ReadString(PCSCMACKey);
      // JCOP Data Key
      if R.ValueExists(PCSCDataKey) then
      edtPCSCDataKey.Text := R.ReadString(PCSCDataKey);

      // VISA Encryption Key
      if R.ValueExists(PCSCVisaEK) then
      edtPCSCVisaEKey.Text := R.ReadString(PCSCVisaEK);
      // VISA MAC Key
      if R.ValueExists(PCSCVisaMK) then
      edtPCSCVisaMKey.Text := R.ReadString(PCSCVisaMK);
      // VISA Data Key
      if R.ValueExists(PCSCVisaDK) then
      edtPCSCVisaDKey.Text := R.ReadString(PCSCVisaDK);
      // MASTERCARD Encryption Key
      if R.ValueExists(PCSCMasterCardEK) then
      edtPCSCMasterCardEKey.Text := R.ReadString(PCSCMasterCardEK);
      // MASTERCARD MAC Key
      if R.ValueExists(PCSCMasterCardMK) then
      edtPCSCMasterCardMKey.Text := R.ReadString(PCSCMasterCardMK);
      // MASTERCARD Data Key
      if R.ValueExists(PCSCMasterCardDK) then
      edtPCSCMasterCardDKey.Text := R.ReadString(PCSCMasterCardDK);
      // MAESTRO Encryption Key
      if R.ValueExists(PCSCMaestroEK) then
      edtPCSCMaestroEKey.Text := R.ReadString(PCSCMaestroEK);
      // MAESTRO MAC Key
      if R.ValueExists(PCSCMaestroMK) then
      edtPCSCMaestroMKey.Text := R.ReadString(PCSCMaestroMK);
      // MAESTRO Data Key
      if R.ValueExists(PCSCMaestroDK) then
      edtPCSCMaestroDKey.Text := R.ReadString(PCSCMaestroDK);

      // Default Memory Card Reader
      if R.ValueExists(MCDefault) then
      cbMCReader.ItemIndex := cbMCReader.Items.IndexOf(R.ReadString(MCDefault));
      // Default PIN code for SLE4442
      if R.ValueExists(MCSLE4442PIN) then
      edtMCDefaultPin.Text := R.ReadString(MCSLE4442PIN);
      if R.ValueExists(MCSLE4442Select) then
      cbMCSLE4442SelectCard.Checked := R.ReadBool(MCSLE4442Select);

      // BinCodes.com
      if R.ValueExists(BINCheckBinCodesAPIKEY) then
      memBinCodesAPIKey.Text := R.ReadString(BINCheckBinCodesAPIKEY);
      // BinTable.com
      if R.ValueExists(BINCheckBinTableAPIKEY) then
      memBinTableAPIKey.Text := R.ReadString(BINCheckBinTableAPIKEY);
      // APILayer.com
      if R.ValueExists(BINCheckAPILayerAPIKEY) then
      memAPILayerAPIKey.Text := R.ReadString(BINCheckAPILayerAPIKEY);
      // Default BIN check
      if R.ValueExists(BINCheckDefault) then
      cbDefaultBinCheck.ItemIndex := R.ReadInteger(BINCheckDefault);

      // Database File
      if R.ValueExists(DBFile) then
      edtDBFilename.Text := R.ReadString(DBFile);

      // Project Author
      if R.ValueExists(ProjectAuthor) then
      edtAuthor.Text := R.ReadString(ProjectAuthor);
      // Project Website
      if R.ValueExists(ProjectWebsite) then
      edtWebsite.Text := R.ReadString(ProjectWebsite);
      // Project Email
      if R.ValueExists(ProjectEmail) then
      edtEmail.Text := R.ReadString(ProjectEmail);
      // Project Telegram
      if R.ValueExists(ProjectTelegram) then
      edtTelegram.Text := R.ReadString(ProjectTelegram);

    end;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{              Save Settings to Registry                }
{*******************************************************}
procedure TfrmSettings.SaveSettings;
var
  R : TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if not R.KeyExists(ApplicationRegKey) then R.CreateKey(ApplicationRegKey);
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // MagStripe YL160
      R.WriteBool(YL160AutoConnect, cbYL160AutoConnect.Checked);
      R.WriteString(YL160BaudRate, cbYL160BaudRate.Text);
      // MagStripe MSR
      R.WriteBool(MSRAutoConnect, cbMSRAutoConnect.Checked);
      R.WriteString(MSRPort, cbMSRPort.Text);
      R.WriteString(MSRBaudRate, cbMSRBaudRate.Text);      
      R.WriteInteger(MSRCardType, cbMSRCardType.ItemIndex);
      // Default Smartcard reader
      R.WriteString(PCSCDefault, cbPCSCReader.Text);
      // JCOP Transport Key
      R.WriteString(PCSCTransportKey, edtPCSCTransportKey.Text);
      // JCOP Encryption Key
      R.WriteString(PCSCEncryptionKey, edtPCSCEncryptionKey.Text);
      // JCOP MAC Key
      R.WriteString(PCSCMACKey, edtPCSCMACKey.Text);
      // JCOP Data Key
      R.WriteString(PCSCDataKey, edtPCSCDataKey.Text);

      // VISA Encryption Key
      R.WriteString(PCSCVisaEK,edtPCSCVisaEKey.Text);
      // VISA MAC Key
      R.WriteString(PCSCVisaMK, edtPCSCVisaMKey.Text);
      // VISA Data Key
      R.WriteString(PCSCVisaDK, edtPCSCVisaDKey.Text);
      // MASTERCARD Encryption Key
      R.WriteString(PCSCMasterCardEK, edtPCSCMasterCardEKey.Text);
      // MASTERCARD MAC Key
      R.WriteString(PCSCMasterCardMK, edtPCSCMasterCardMKey.Text);
      // MASTERCARD Data Key
      R.WriteString(PCSCMasterCardDK, edtPCSCMasterCardDKey.Text);
      // MAESTRO Encryption Key
      R.WriteString(PCSCMaestroEK, edtPCSCMaestroEKey.Text);
      // MAESTRO MAC Key
      R.WriteString(PCSCMaestroMK, edtPCSCMaestroMKey.Text);
      // MAESTRO Data Key
      R.WriteString(PCSCMaestroDK, edtPCSCMaestroDKey.Text);

      // Default Memory Card Reader
      R.WriteString(MCDefault, cbMCReader.Text);
      // Default SLE4442 PIN Code
      R.WriteString(MCSLE4442PIN, edtMCDefaultPin.Text);
      // Select SLE4442 Card
      R.WriteBool(MCSLE4442Select, cbMCSLE4442SelectCard.Checked);

      // BinCodes.com
      R.WriteString(BINCheckBinCodesAPIKEY, memBinCodesAPIKey.Text);
      // BinTable.com
      R.WriteString(BINCheckBinTableAPIKEY, memBinTableAPIKey.Text);
      // APILayer.com
      R.WriteString(BINCheckAPILayerAPIKEY, memAPILayerAPIKey.Text);
      // Default BIN check
      R.WriteInteger(BINCheckDefault, cbDefaultBinCheck.ItemIndex);

      // Database File
      R.WriteString(DBFile, edtDBFilename.Text);

      // Project Author
      R.WriteString(ProjectAuthor, edtAuthor.Text);
      // Project Website
      R.WriteString(ProjectWebsite, edtWebsite.Text);
      // Project Email
      R.WriteString(ProjectEmail, edtEmail.Text);
      // Project Telegram
      R.WriteString(ProjectTelegram, edtTelegram.Text);

      // Reset MagStripe connections
      frmMain.ConnectYL160;
      frmMain.ConnectMSR;
    end;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmSettings.FormCreate(Sender: TObject);
var
  I : Integer;
begin
  // Window size
  Width  := 640;
  Height := 500;
  // Create PCSC
  PCSC := TPCSC.Create;
  PCSC.Init;
  // Create List with available COM Ports
  FCOMPorts := TStringList.Create;
  // Populate list of comports
  USBArrivalRemoval(Self);
  // Create USB Insert/Removal notifier
  FUSBNotifier := TComponentUSB.Create(Self);
  FUSBNotifier.OnUSBArrival := USBArrivalRemoval;
  FUSBNotifier.OnUSBRemove  := USBArrivalRemoval;
  // Reset controls
  for I := 0 to ComponentCount -1 do
  begin
    // Page Controls
    if Components[I].ClassNameIs('TPageControl') and ((Components[I] as TPageControl).Tag = 0) then
    (Components[I] as TPageControl).ActivePageIndex := 0;
    // Tab Sheets
    if Components[I].ClassNameIs('TTabSheet') and ((Components[I] as TTabSheet).Tag = 0) then
    (Components[I] as TTabSheet).TabVisible := False;
    // Memo's
    if Components[I].ClassNameIs('TMemo') and ((Components[I] as TMemo).Tag = 0) then
    (Components[I] as TMemo).Clear;
  end;
  // Select first item
  TV.Selected := TV.Items[0];
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Free list of available COM ports
  FCOMPorts.Free;
  // Free USB Notifier
  FUSBNotifier.Free;
  // Free PCSC
  PCSC.Free;
  // Free dialog
  Action := caFree;
  Release;
  frmSettings := nil;
end;

{*******************************************************}
{                Treeview Change Event                  }
{*******************************************************}
procedure TfrmSettings.TVChange(Sender: TObject; Node: TTreeNode);
begin
  case Node.AbsoluteIndex of

    0 : // MagStripe
    begin
      PC.ActivePageIndex := 0;
      PCMagStripe.ActivePageIndex := 0;
    end;

    1 : // YL160
    begin
      PC.ActivePageIndex := 0;
      PCMagStripe.ActivePageIndex := 1;
    end;

    2 : // MSR
    begin
      PC.ActivePageIndex := 0;
      PCMagStripe.ActivePageIndex := 2;
    end;

    3: // SmartCard
    begin
      PC.ActivePageIndex := 1;
      pcSmartCard.ActivePageIndex := 0;
    end;

    4: // JCOP
    begin
      PC.ActivePageIndex := 1;
      pcSmartCard.ActivePageIndex := 1;
    end;

    5: // VISA
    begin
      PC.ActivePageIndex := 1;
      pcSmartCard.ActivePageIndex := 2;
    end;

    6: // MASTERCARD
    begin
      PC.ActivePageIndex := 1;
      pcSmartCard.ActivePageIndex := 3;
    end;

    7: // MAESTRO
    begin
      PC.ActivePageIndex := 1;
      pcSmartCard.ActivePageIndex := 4;
    end;

    8: // Memory Card
    begin
      PC.ActivePageIndex := 2;
      pcMemoryCard.ActivePageIndex := 0;
    end;

    9: // SLE4442
    begin
      PC.ActivePageIndex := 2;
      pcMemoryCard.ActivePageIndex := 1;
    end;

    10: // BIN Check
    begin
      PC.ActivePageIndex := 3;
      pcBINCheck.ActivePageIndex := 0;
    end;

    11: // BinCodes.com
    begin
      PC.ActivePageIndex := 3;
      pcBINCheck.ActivePageIndex := 1;
    end;

    12: // BinTable.com
    begin
      PC.ActivePageIndex := 3;
      pcBINCheck.ActivePageIndex := 2;
    end;

    13: // APILayer.com
    begin
      PC.ActivePageIndex := 3;
      pcBINCheck.ActivePageIndex := 3;
    end;

    14: // Database
    begin
      PC.ActivePageIndex := 4;
      pcDB.ActivePageIndex := 0;
    end;

    15: // Project
    begin
      PC.ActivePageIndex := 5;
      pcProject.ActivePageIndex := 0;
    end;
    
  end;
end;

{*******************************************************}
{                   Test MSR Leds                       }
{*******************************************************}
procedure TfrmSettings.btnMSRLEDGClick(Sender: TObject);
const
  SensorTESTOK  = 'Sensor test succeeded.';
  SensorTESTNOK = 'Sensor test failed!';
  RamTESTOK     = 'RAM test succeeded.';
  RamTESTNOK    = 'RAM test failed!';
begin
  case (Sender as TComponent).Tag of
    1 : MSR_Green_LED_On;
    2 : MSR_Yellow_LED_On;
    3 : MSR_Red_LED_On;
    4 : MSR_All_LED_On;
    5 : MSR_All_LED_Off;
    6 : if (MSR_Sensor_Test = 48) then
          Application.MessageBox(SensorTESTOK, PChar(Application.Title), MB_ICONINFORMATION + MB_OK)
        else
          Application.MessageBox(SensorTESTNOK, PChar(Application.Title), MB_ICONERROR + MB_OK);
    7 : if (MSR_Ram_Test = 48) then
          Application.MessageBox(RamTESTOK, PChar(Application.Title), MB_ICONINFORMATION + MB_OK)
        else
          Application.MessageBox(RamTESTNOK, PChar(Application.Title), MB_ICONERROR + MB_OK);
  end;
end;

{*******************************************************}
{                     Visit Link                        }
{*******************************************************}
procedure TfrmSettings.lblBinCodesRegisterClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar((Sender as TLabel).Caption), nil, nil, SW_SHOWNORMAL);
end;

{*******************************************************}
{               (Link) Label Mouse Enter                }
{*******************************************************}
procedure TfrmSettings.lblBinCodesRegisterMouseEnter(Sender: TObject);
begin
  (Sender as TLabel).font.Style := [fsUnderline];
end;

{*******************************************************}
{               (Link) Label Mouse Leave                }
{*******************************************************}
procedure TfrmSettings.lblBinCodesRegisterMouseLeave(Sender: TObject);
begin
  (Sender as TLabel).font.Style := [];
end;

{*******************************************************}
{                 Select Database file                  }
{*******************************************************}
procedure TfrmSettings.btnBrowseDBClick(Sender: TObject);
begin
  if OpenDBDialog.Execute(Handle) and FileExists(OpenDBDialog.FileName) then
  edtDBFilename.Text := OpenDBDialog.FileName;
end;

{*******************************************************}
{               Create new Database file                }
{*******************************************************}
procedure TfrmSettings.btnCreateDBClick(Sender: TObject);
var
  DB : TSQLite3Database;
begin
  if SaveDBDialog.Execute(Handle) and (Length(SaveDBDialog.FileName) > 0) then
  begin
    DB := TSQLite3Database.Create;
    try
      DB.Open(SaveDBDialog.FileName);
      DB.Execute(DBCreateCCTable);
      edtDBFilename.Text := SaveDBDialog.FileName;
    finally
      DB.Free;
    end;
  end;
end;

end.
