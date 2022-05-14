unit untMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls, Vcl.ToolWin,
  System.Actions, Vcl.ActnList, Vcl.StdActns, Vcl.BaseImageCollection,
  Vcl.ImageCollection, Vcl.VirtualImageList, System.ImageList, Vcl.ImgList, untUSB;

type
  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    StatusBar1: TStatusBar;
    File1: TMenuItem;
    MagStripe1: TMenuItem;
    ActionList: TActionList;
    MagStripeRead: TAction;
    Read1: TMenuItem;
    MagStripeWrite: TAction;
    Write1: TMenuItem;
    WindowCascade1: TWindowCascade;
    WindowTileHorizontal1: TWindowTileHorizontal;
    WindowTileVertical1: TWindowTileVertical;
    WindowMinimizeAll1: TWindowMinimizeAll;
    WindowArrange1: TWindowArrange;
    Window1: TMenuItem;
    Arrange1: TMenuItem;
    Cascade1: TMenuItem;
    ileHorizontally1: TMenuItem;
    ileVertically1: TMenuItem;
    MinimizeAll1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    EditSelectAll1: TEditSelectAll;
    EditUndo1: TEditUndo;
    EditDelete1: TEditDelete;
    Edit1: TMenuItem;
    SelectAll1: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    Delete1: TMenuItem;
    Undo1: TMenuItem;
    N5: TMenuItem;
    DecodeTracks: TAction;
    EncodeTracks: TAction;
    ools1: TMenuItem;
    DecodeTracks1: TMenuItem;
    EncodeTracks1: TMenuItem;
    About: TAction;
    Help1: TMenuItem;
    About1: TMenuItem;
    GenerateCC: TAction;
    N6: TMenuItem;
    CCGenerator1: TMenuItem;
    EnterLicense: TAction;
    N7: TMenuItem;
    EnterLicense1: TMenuItem;
    Preferences1: TAction;
    N8: TMenuItem;
    Preferences2: TMenuItem;
    CheckBIN: TAction;
    N9: TMenuItem;
    CheckBIN1: TMenuItem;
    BrowseDatabase1: TAction;
    Database1: TMenuItem;
    Browse1: TMenuItem;
    SearchCard1: TAction;
    Search1: TMenuItem;
    N10: TMenuItem;
    HashCalculator: TAction;
    N11: TMenuItem;
    HashCalculator1: TMenuItem;
    ATRChanger1: TAction;
    EMV1: TMenuItem;
    ATRChanger2: TMenuItem;
    UDKCalculator: TAction;
    UDKCalculator1: TMenuItem;
    N12: TMenuItem;
    CSKCalculator: TAction;
    CSKCalculator1: TMenuItem;
    ARQCCalculator: TAction;
    ARQCCalculator1: TMenuItem;
    FormatCard: TAction;
    N13: TMenuItem;
    FormatCard1: TMenuItem;
    ParseAPDU: TAction;
    N14: TMenuItem;
    New: TAction;
    OpenFile: TAction;
    Save: TAction;
    SaveAs: TAction;
    New1: TMenuItem;
    N15: TMenuItem;
    New2: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    CloseFile: TAction;
    Close1: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    Exit: TAction;
    Exit1: TMenuItem;
    CloseAll: TAction;
    N18: TMenuItem;
    CloseAll1: TMenuItem;
    Information1: TAction;
    N19: TMenuItem;
    Information2: TMenuItem;
    MemoryCard1: TMenuItem;
    MemoryCardRead: TAction;
    MemoryCardWrite: TAction;
    Read2: TMenuItem;
    Write2: TMenuItem;
    MemoryCardChangePin: TAction;
    N20: TMenuItem;
    ChangePIN1: TMenuItem;
    SmartCardRead: TAction;
    Read3: TMenuItem;
    InitializeSmartCard: TAction;
    Initialize1: TMenuItem;
    N22: TMenuItem;
    N21: TMenuItem;
    ParseAPDU1: TMenuItem;
    procedure MagStripeReadExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MagStripeWriteExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DecodeTracksExecute(Sender: TObject);
    procedure EncodeTracksExecute(Sender: TObject);
    procedure AboutExecute(Sender: TObject);
    procedure GenerateCCExecute(Sender: TObject);
    procedure EnterLicenseExecute(Sender: TObject);
    procedure Preferences1Execute(Sender: TObject);
    procedure CheckBINExecute(Sender: TObject);
    procedure BrowseDatabase1Execute(Sender: TObject);
    procedure SearchCard1Execute(Sender: TObject);
    procedure HashCalculatorExecute(Sender: TObject);
    procedure ATRChanger1Execute(Sender: TObject);
    procedure UDKCalculatorExecute(Sender: TObject);
    procedure CSKCalculatorExecute(Sender: TObject);
    procedure ARQCCalculatorExecute(Sender: TObject);
    procedure FormatCardExecute(Sender: TObject);
    procedure ParseAPDUExecute(Sender: TObject);
    procedure ExitExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure NewExecute(Sender: TObject);
    procedure MemoryCardReadExecute(Sender: TObject);
    procedure MemoryCardWriteExecute(Sender: TObject);
    procedure MemoryCardChangePinExecute(Sender: TObject);
    procedure SmartCardReadExecute(Sender: TObject);
    procedure InitializeSmartCardExecute(Sender: TObject);
  private
    { Private declarations }
    FYL160Connected       : Boolean;
    FMSRConnected         : Boolean;
    FYL160Busy            : Boolean;
    FMSRBusy              : Boolean;

    FUSBNotifier : TComponentUSB;

    procedure USBArrivalRemoval(Sender: TObject);
  public
    { Public declarations }
    property YL160Connected : Boolean read FYL160Connected write FYL160Connected;
    property MSRConnected   : Boolean read FMSRConnected   write FMSRConnected;

    property YL160Busy : Boolean read FYL160Busy write FYL160Busy;
    property MSRBusy   : Boolean read FMSRBusy   write FMSRBusy;

    procedure ConnectYL160;
    procedure ConnectMSR;
    procedure TryMagStripeConnect;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses untLIB160, untMSR_API, untConst, untLicense, untMagStripeRead,
     untMagStripeWrite, untDecodeTracks, untEncodeTracks, untGenerateCC,
     untBINCheck, untAbout, untEnterLicense, untSettings, Registry, untDatabase,
     untDatabaseSearch, untHashCalculator, untATRChanger, untUDKCalculator,
     untCSKCalculator, untARQCCalculator, untFormarCard, untParseAPDU,
  untCardStudioProject, untNew, untMemoryCardRead, untMemoryCardWrite,
  untMemoryCardChangePIN, untSmartCardRead, untInitializeSmartCard;

{*******************************************************}
{               USB Insert/Remove Event                 }
{*******************************************************}
procedure TfrmMain.USBArrivalRemoval(Sender: TObject);
var
  ReaderOpen, WriterOpen : Boolean;
begin
  // Set reader/writer window status, so we can restore the windows
  // after reconnecting
  ReaderOpen := Assigned(frmMagStripeRead);
  WriterOpen := Assigned(frmMagStripeWrite);

  // Close reader/writer windows
  if FYL160Connected or FMSRConnected then
  begin
    if ReaderOpen then frmMagStripeRead.Close;
    if WriterOpen then frmMagStripeWrite.Close;
  end;

  // Try to reconnect YL160
  ConnectYL160;
  // Try to reconnect to MSR
  ConnectMSR;

  // Reopen reader ?
  if (FYL160Connected or FMSRConnected) and ReaderOpen then MagStripeRead.Execute;
  // Reopen writer ?
  if FMSRConnected and WriterOpen then MagStripeWrite.Execute;
end;

{*******************************************************}
{      Try to connect the YL160 MagStripe Reader        }
{*******************************************************}
procedure TfrmMain.ConnectYL160;
var
  R : TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // MagStripe YL160
      if R.ValueExists(YL160AutoConnect) and R.ReadBool(YL160AutoConnect) then
      begin
        // Close YL160 multi/magstripe reader connection if connected
        if FYL160Connected then DelDev;
        // Reset MagStripe
        MagReset;
        // Try connect to YL160 multi/magstripe reader
        if R.ValueExists(YL160BaudRate) then
          FYL160Connected := (InitDev(YL160Port, StrToInt(R.ReadString(YL160BaudRate))) = 0)
        else
          FYL160Connected := (InitDev(YL160Port, 9600) = 0);
      end;
    end;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{    Try to connect the MSR MagStripe Reader/Writer     }
{*******************************************************}
procedure TfrmMain.ConnectMSR;
var
  R : TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // MagStripe MSR
      if R.ValueExists(MSRAutoConnect) and R.ReadBool(MSRAutoConnect) then
      begin
        // Close MSR magstripe reader/writer connection if connected
        if FMSRConnected then MSR_ExitComm;
        // Try connect to MSR magstripe reader/writer
        // ToDo: Check if connected to HID or COM
        if R.ValueExists(MSRPort) and R.ValueExists(MSRBaudRate) then
          FMSRConnected := MSR_InitComm(PAnsiChar(AnsiString(R.ReadString(MSRPort))), StrToInt(R.ReadString(MSRBaudRate)))
        else
          FMSRConnected := MSR_InitComm('HID', 9600);
        if FMSRConnected then
        begin
          // Reset MSR
          MSR_Reset();
          // Set MSR BPI
          MSR_Select_BPI($4b); // T2 Density - 75 BPI
          // Set leading zero
          MSR_Set_Leading_Zero(61, 22);
          // Set BPC
          MSR_Set_BPC(7, 5, 5);
          // Set HiCo/LoCo
          if R.ValueExists(MSRCardType) then
          case R.ReadInteger(MSRCardType) of
            0 : MSR_Set_HiCo;
            1 : MSR_Set_LoCo;
          end else
            MSR_Set_HiCo;
        end;
      end;
    end;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{      Try to connect the MagStripe reader/writer       }
{*******************************************************}
procedure TfrmMain.TryMagStripeConnect;
begin
  if not FYL160Connected then
    ConnectYL160;
  if not FMSRConnected then
    ConnectMSR;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Create USB insert/remove notifier component
  FUSBNotifier := TComponentUSB.Create(Self);
  FUSBNotifier.OnUSBArrival := USBArrivalRemoval;
  FUSBNotifier.OnUSBRemove  := USBArrivalRemoval;
  // Set Appication Title and Caption
  Application.Title := ApplicationTitle;
  Caption           := ApplicationTitle;
  // Set connections to false (default)
  FYL160Connected := False;
  FMSRConnected   := False;
  // Try to connect YL160
  ConnectYL160;
  // Try to connect to MSR
  ConnectMSR;
end;

{*******************************************************}
{                  Form Destroy Event                   }
{*******************************************************}
procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Close YL160 multi/magstripe reader connection if connected
  if FYL160Connected then DelDev;
  // Close MSR magstripe reader/writer connection if connected
  if FMSRConnected then MSR_ExitComm;
  // Free USB insert/remove notifier component
  FUSBNotifier.Destroy;
end;

{*******************************************************}
{                Read Magnetic Stripe                   }
{*******************************************************}
procedure TfrmMain.MagStripeReadExecute(Sender: TObject);
begin
  if not Assigned(frmMagStripeRead) then
  begin
    frmMagStripeRead := TfrmMagStripeRead.Create(Application);
    frmMagStripeRead.Show;
  end else
  begin
    if frmMagStripeRead.WindowState = wsMinimized then frmMagStripeRead.WindowState := wsNormal;
    frmMagStripeRead.BringToFront;
  end;
end;

{*******************************************************}
{                Write Magnetic Stripe                  }
{*******************************************************}
procedure TfrmMain.MagStripeWriteExecute(Sender: TObject);
begin
  if not Assigned(frmMagStripeWrite) then
  begin
    frmMagStripeWrite := TfrmMagStripeWrite.Create(Application);
    frmMagStripeWrite.Show;
  end else
  begin
    if frmMagStripeWrite.WindowState = wsMinimized then frmMagStripeWrite.WindowState := wsNormal;
    frmMagStripeWrite.BringToFront;
  end;
end;

{*******************************************************}
{                    Decode Tracks                      }
{*******************************************************}
procedure TfrmMain.DecodeTracksExecute(Sender: TObject);
begin
  with TfrmTracksDecode.Create(Application) do Show;
end;

{*******************************************************}
{                    Encode Tracks                      }
{*******************************************************}
procedure TfrmMain.EncodeTracksExecute(Sender: TObject);
begin
  with TfrmTracksEncode.Create(Application) do Show;
end;

{*******************************************************}
{             Generate Credit Card Numbers              }
{*******************************************************}
procedure TfrmMain.GenerateCCExecute(Sender: TObject);
begin
  with TfrmGenerateCC.Create(Application) do Show;
end;

{*******************************************************}
{                      Check BIN                        }
{*******************************************************}
procedure TfrmMain.CheckBINExecute(Sender: TObject);
begin
  with TfrmCheckBIN.Create(Application) do Execute;
end;

{*******************************************************}
{                   Hash Calculator                     }
{*******************************************************}
procedure TfrmMain.HashCalculatorExecute(Sender: TObject);
begin
  with TfrmHashCalculator.Create(Application) do Show;
end;


{*******************************************************}
{                   UDK Calculator                      }
{*******************************************************}
procedure TfrmMain.UDKCalculatorExecute(Sender: TObject);
begin
  with TfrmUDKCalculator.Create(Application) do Show;
end;

{*******************************************************}
{                   CSK Calculator                      }
{*******************************************************}
procedure TfrmMain.CSKCalculatorExecute(Sender: TObject);
begin
  with TfrmCSKCalculator.Create(Application) do Show;
end;

{*******************************************************}
{                   ARQC Calculator                     }
{*******************************************************}
procedure TfrmMain.ARQCCalculatorExecute(Sender: TObject);
begin
  with TfrmARQCCalculator.Create(Application) do Show;
end;

{*******************************************************}
{                     Format Card                       }
{*******************************************************}
procedure TfrmMain.FormatCardExecute(Sender: TObject);
begin
  with TfrmFormatCard.Create(Application) do Show;
end;

{*******************************************************}
{                      Parse APDU                       }
{*******************************************************}
procedure TfrmMain.ParseAPDUExecute(Sender: TObject);
begin
  with TfrmParseAPDU.Create(Application) do Show;
end;

{*******************************************************}
{                    Read SmartCard                     }
{*******************************************************}
procedure TfrmMain.SmartCardReadExecute(Sender: TObject);
begin
  with TfrmSmartCardRead.Create(Application) do Show;
end;

{*******************************************************}
{                 Initialize SmartCard                  }
{*******************************************************}
procedure TfrmMain.InitializeSmartCardExecute(Sender: TObject);
begin
  with TfrmInitializeSmartCard.Create(Application) do Show;
end;

{*******************************************************}
{                 Enter License Key                     }
{*******************************************************}
procedure TfrmMain.EnterLicenseExecute(Sender: TObject);
var
  L : string;
begin
  with TfrmEnterLicense.Create(Application) do
  case Execute of

      // Check entered License Key
      MROK:
      begin
        L := LicenseKey;
        // If License Key is valid - store Key in the registry
        // and load the mainform.
        if PKV_CheckKey(L) = KEY_VALID then
        // Store License Key
        PVK_LicenseKeyStoreRegistry(L) else
        // Error - invalid License Key
        PVK_LicenseKeyError(Application.Handle);
      end;

  end;
end;

{*******************************************************}
{                Show Settings Dialog                   }
{*******************************************************}
procedure TfrmMain.Preferences1Execute(Sender: TObject);
begin
  with TfrmSettings.Create(Application) do
  if Execute = MROK then SaveSettings;
end;

{*******************************************************}
{                    Show Database                      }
{*******************************************************}
procedure TfrmMain.BrowseDatabase1Execute(Sender: TObject);
begin
  if not Assigned(frmDatabase) then
  begin
    frmDatabase := TfrmDatabase.Create(Application);
    frmDatabase.Width  := 640;
    frmDatabase.Height := 450;
    frmDatabase.Show;
  end else
  begin
    if frmDatabase.WindowState = wsMinimized then frmDatabase.WindowState := wsNormal;
    frmDatabase.BringToFront;
  end;
end;

{*******************************************************}
{                   Search Database                     }
{*******************************************************}
procedure TfrmMain.SearchCard1Execute(Sender: TObject);
begin
  if not Assigned(frmDatabaseSearch) then
  begin
    frmDatabaseSearch := TfrmDatabaseSearch.Create(Application);
    frmDatabaseSearch.Show;
  end else
  begin
    if frmDatabaseSearch.WindowState = wsMinimized then frmDatabaseSearch.WindowState := wsNormal;
    frmDatabaseSearch.BringToFront;
  end;
end;

{*******************************************************}
{               Smart Card ATR Changer                  }
{*******************************************************}
procedure TfrmMain.ATRChanger1Execute(Sender: TObject);
begin
  with TfrmChangeATR.Create(Application) do Show;
end;

{*******************************************************}
{             New CardStudio Project File               }
{*******************************************************}
procedure TfrmMain.NewExecute(Sender: TObject);
begin
  with TfrmNew.Create(Application) do
  if Execute = MROK then
  with TfrmCardStudioProject.Create(Application) do
  begin
    NewFile(edtAuthor.Text, edtWebsite.Text, edtEmail.Text, edtTelegram.Text, memComment.Text);
    Show;
  end;
end;

{*******************************************************}
{                   Read Memory Card                    }
{*******************************************************}
procedure TfrmMain.MemoryCardReadExecute(Sender: TObject);
begin
  with TfrmMemoryCardRead.Create(Application) do Show;
end;

{*******************************************************}
{                   Write Memory Card                   }
{*******************************************************}
procedure TfrmMain.MemoryCardWriteExecute(Sender: TObject);
begin
  with TfrmMemoryCardWrite.Create(Application) do Show;
end;

{*******************************************************}
{             Change Memory Card PIN Code               }
{*******************************************************}
procedure TfrmMain.MemoryCardChangePinExecute(Sender: TObject);
begin
  with TfrmMemoryCardChangePIN.Create(Application) do Show;
end;

{*******************************************************}
{                   Show About Dialog                   }
{*******************************************************}
procedure TfrmMain.AboutExecute(Sender: TObject);
begin
  if not Assigned(frmAbout) then
  begin
    frmAbout := TfrmAbout.Create(Application);
    frmAbout.Show;
  end else
    frmAbout.BringToFront;
end;

{*******************************************************}
{               Exit Application Query                  }
{*******************************************************}
procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  case Application.MessageBox(ApplicationExitConfirm, PChar(ApplicationTitle), MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) of

    // Exit Application
    IDYES : CanClose := True;

    // Stay opened
    IDNO  : CanClose := False;

  end;
end;

{*******************************************************}
{                  Exit Application                     }
{*******************************************************}
procedure TfrmMain.ExitExecute(Sender: TObject);
begin
  Close;
end;


end.
