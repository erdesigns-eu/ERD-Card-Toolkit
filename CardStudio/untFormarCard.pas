unit untFormarCard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, untUSB, System.Win.Registry, System.IOUtils;

const
  LIBNAME: WideString = 'gppcscconnectionplugin';
  LIBVERS: WideString = '211';

type
  // Object for holding *.CAP filename
  TCapFilename = class(TObject)
    Filename : string;
    constructor Create(const F: string);
  end;

  TfrmFormatCard = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    gbReader: TGroupBox;
    cbReader: TComboBox;
    Panel2: TPanel;
    btnHelp: TButton;
    btnFormat: TButton;
    gbLog: TGroupBox;
    memLog: TMemo;
    GroupBox1: TGroupBox;
    cbApplet: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure btnFormatClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FUSBNotifier : TComponentUSB;

    procedure USBArrivalRemoval(Sender: TObject);
    procedure GPLoadReaders;
  public
    { Public declarations }
  end;

var
  frmFormatCard: TfrmFormatCard;

implementation

{$R *.dfm}

uses untConst, untGP, untGPConnection, untGPSecurity, untEMVTools;

{*******************************************************}
{              Cap Filename Constructor                 }
{*******************************************************}
constructor TCapFilename.Create(const F: string);
begin
  inherited Create;
  Filename := F;
end;

{*******************************************************}
{               USB Insert/Remove Event                 }
{*******************************************************}
procedure TfrmFormatCard.USBArrivalRemoval(Sender: TObject);
begin
  // Reload SmartCard Reader/Writers
  GPLoadReaders;
end;

{*******************************************************}
{           Load Readers - use GlobalPlatform           }
{*******************************************************}
procedure TfrmFormatCard.GPLoadReaders;
var
  SE, SR  : OPGP_ERROR_STATUS;
  Context : OPGP_CARD_CONTEXT;
  Names   : array [0..1024] of WideChar;
  Len     : DWord;
  S, L    : string;
  P       : PWideChar;
  R       : TRegistry;
begin
  // Clear list of readers
  cbReader.Clear;
  // Free memory if context already exists
  ZeroMemory(@Context, SizeOf(Context));
  // Set GPSC connector library name
  FillChar(Context.libraryName, 64, #0);
  Move(LIBNAME[1], Context.libraryName, length(LIBNAME) * SizeOf(WideChar));
  // Set GPSC connector library version
  FillChar(Context.libraryVersion, 32, #0);
  Move(LIBVERS[1], Context.libraryVersion, length(LIBVERS) * SizeOf(WideChar));
  // Establish context
  SE := OPGP_establish_context(Context);
  if SE.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
  begin
    Len := 1024;
    // Try to get list of readers
    SR := OPGP_list_readers(Context, Names, Len);
    if SR.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
    begin
      // Check if there are readers
      if Len > 0 then
      begin
        // Copy from record to string
        SetString(S, Names, Length(Names) * SizeOf(WideChar));
        P := @S[1];
        // Split by NULL character
        while P^ <> #0 do
        begin
          L := P;
          // Add reader to the list
          cbReader.Items.Add(L);
          Inc(P, Length(L) +1);
        end;
      end;
    end;
    // Release context
    OPGP_release_context(Context);
  end;
  // Set default reader
  if cbReader.Items.Count > 0 then
  begin
    R := TRegistry.Create;
    try
      R.RootKey := HKEY_CURRENT_USER;
      if R.OpenKey(ApplicationRegKey, True) and R.ValueExists(PCSCDefault) then
        cbReader.ItemIndex := cbReader.Items.IndexOf(R.ReadString(PCSCDefault))
      else
        cbReader.ItemIndex := 0;
    finally
      R.Free;
    end;
  end;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmFormatCard.FormCreate(Sender: TObject);
var
  D, S : string;
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Create USB insert/remove notifier component
  FUSBNotifier := TComponentUSB.Create(Self);
  FUSBNotifier.OnUSBArrival := USBArrivalRemoval;
  FUSBNotifier.OnUSBRemove  := USBArrivalRemoval;
  // Load Applets
  cbApplet.Items.Clear;
  D := ExtractFilePath(Application.ExeName) + 'Applets';
  if DirectoryExists(D) then for S in TDirectory.GetFiles(D, '*.cap') do
  cbApplet.Items.AddObject(ExtractFilename(S), TCapFilename.Create(S));
  if cbApplet.Items.Count > 0 then cbApplet.ItemIndex := 0;
  // Clear Log memo
  memLog.Clear;
  // Load list of readers
  GPLoadReaders;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmFormatCard.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  I : Integer;
begin
  // Free Cap filename objects
  for I := cbApplet.Items.Count -1 downto 0 do
  cbAPplet.Items.Objects[I].Free;
  // Free USB insert/remove notifier component
  FUSBNotifier.Destroy;
  // Free Form
  Action := caFree;
  Release;
end;

{*******************************************************}
{                     Format Card                       }
{*******************************************************}
procedure TfrmFormatCard.btnFormatClick(Sender: TObject);
var
  R         : TRegistry;

  // Create context and connect reader
  Status    : OPGP_ERROR_STATUS;
  Context   : OPGP_CARD_CONTEXT;
  CardInfo  : OPGP_CARD_INFO;
  Reader    : array [0..255] of WideChar;
  AID       : TBytes;
  AIDL      : DWord;
  I         : Integer;

  // Open secure channel
  SCP       : Byte; // scp
  SCPIMPL   : Byte; // scpImpl
  SecLevel  : Byte; // securityLevel
  KeyIndex  : Byte; // keyIndex
  KeySetVer : Byte; // keySetVersion
  KeyDeriv  : Byte; // keyDerivation
  Key       : TBytes;
  MacKey    : TBytes;
  EncKey    : TBytes;
  KekKey    : TBytes;
  SecInfo   : GP211_SECURITY_INFO;

  // Delete applet
  AIDS      : array of OPGP_AID;
  ReceiptD  : array of GP211_RECEIPT_DATA;
  ReceiptDL : DWORD;
  Success   : Boolean;

  // Install applet
  Filename             : string;
  loadFileParams       : OPGP_LOAD_FILE_PARAMETERS ;
  receiptDataAvailable : DWORD;
  receiptDataLen       : DWORD;
  receipt              : GP211_RECEIPT_DATA;
  pkgAIDLen            : DWORD;
  pkgAID               : array [0..16] of Byte;
  sdAIDLen             : DWORD;
  sdAID                : array [0..16] of Byte;
  nvCodeLimit          : DWORD;
  vDataLimit           : DWORD;
  nvDataLimit          : DWORD;
  
  privilege            : Byte;
  instParam            : array [0..128] of Byte;
  instParamLen         : DWORD;
begin
  //
  Success := False;
  // Make sure that there is a reader selected
  if (cbReader.ItemIndex = -1) or (cbApplet.ItemIndex = -1) then Exit;
  // Clear log
  memLog.Clear;
  Application.ProcessMessages;
  // Create Registry to read settings
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // Free memory if context already exists
      ZeroMemory(@Context, SizeOf(Context));
      // Set GPSC connector library name
      FillChar(Context.libraryName, 64, #0);
      Move(LIBNAME[1], Context.libraryName, length(LIBNAME) * SizeOf(WideChar));
      // Set GPSC connector library version
      FillChar(Context.libraryVersion, 32, #0);
      Move(LIBVERS[1], Context.libraryVersion, length(LIBVERS) * SizeOf(WideChar));
      // Set reader name
      FillChar(Reader, 256, #0);
      Move(cbReader.Text[1], Reader, 256 * SizeOf(WideChar));

      // Enable trace
      OPGP_enable_trace_mode(OPGP_TRACE_MODE_ENABLE, nil);

      // Log
      memLog.Lines.Add(FormatCardHeader);
      // Establish context
      Status := OPGP_establish_context(Context);
      if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
      begin
        // Try to connect to cardreader
        Status := OPGP_card_connect(Context, Reader, CardInfo, OPGP_CARD_PROTOCOL_T1);
        if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
        begin
          // Log
          memLog.Lines.Add(Format(FormatCardConnect, [Status.errorMessage]));

          // Select Application
          StrToByteArray(FormatCardSelect, AID);
          AIDL := Length(AID);
          Status := OPGP_select_application(Context, CardInfo, PByte(AID), AIDL);
          if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
          begin
            // Log
            memLog.Lines.Add(Format(FormatCardSelectA, [FormatCardSelect, Status.errorMessage]));

            // Open secure channel
            for I := 0 to AIDL -1 do SecInfo.invokingAid[I] := AID[I];
            SecInfo.invokingAidLength := Length(AID);
            SCP       := $2;
            SCPIMPL   := $15;
            SecLevel  := 1;
            KeyIndex  := 0;
            KeySetVer := 0;
            KeyDeriv  := OPGP_DERIVATION_METHOD_NONE;
            // Key
            if R.ValueExists(PCSCEncryptionKey) then StrToByteArray(R.ReadString(PCSCEncryptionKey), Key) else StrToByteArray('', Key);
            // KEK Key
            if R.ValueExists(PCSCEncryptionKey) then StrToByteArray(R.ReadString(PCSCEncryptionKey), KekKey) else StrToByteArray('', KekKey);
            // MAC Key
            if R.ValueExists(PCSCMACKey) then StrToByteArray(R.ReadString(PCSCMACKey), MacKey) else StrToByteArray('', MacKey);
            // Encryption Key
            if R.ValueExists(PCSCDataKey) then StrToByteArray(R.ReadString(PCSCDataKey), EncKey) else StrToByteArray('', EncKey);
            // Authenticate GP 2.1.1
            Status := GP211_mutual_authentication(Context, CardInfo, PByte(Key), PByte(EncKey), PByte(MACKey), PByte(KekKey),
              32, KeySetVer, KeyIndex, SCP, SCPIMPL, SecLevel, KeyDeriv, SecInfo);
            if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
            begin
              // Log
              memLog.Lines.Add(Format(FormatCardOpenSec, [Status.errorMessage]));

              // Delete applet
              SetLength(AIDS, 1);
              AIDS[0].AIDLength := Length(FormatCard1PAY) div 2;
              StrToByteArrayAlt(FormatCard1PAY, AIDS[0].AID);
              ReceiptDL := 10;
              SetLength(ReceiptD, ReceiptDL);
              Status := GP211_delete_application(Context, CardInfo, @SecInfo, @AIDS[0], 1, @ReceiptD[0], ReceiptDL);
              if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
              begin
                // Log
                memLog.Lines.Add(Format(FormatCardDelete, ['1PAY.SYS.DDF01', Status.errorMessage]));
              end else
              begin
                memLog.Lines.Add(Format(FormatCardDelete, ['1PAY.SYS.DDF01', Status.errorMessage]));
              end;
            end;
          end;

          // Install Applet
          Filename := (cbApplet.Items.Objects[cbApplet.ItemIndex] as TCapFilename).Filename;
          Status := OPGP_read_executable_load_file_parameters(PChar(Filename), @loadFileParams);
          if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
          begin
            pkgAIDLen   := loadFileParams.loadFileAID.AIDLength;
            Move(loadFileParams.loadFileAID.AID[0], pkgAID[0], SizeOf(Byte) * Length(loadFileParams.loadFileAID.AID));
            nvCodeLimit := loadFileParams.loadFileSize;
            sdAIDLen := AIDL;
            Move(AID[0], sdAID[0], SizeOf(Byte) * AIDL);

            // Install for load
            Status := GP211_install_for_load(Context, CardInfo, @SecInfo, @pkgAID[0], pkgAIDLen, @sdAID[0], sdAIDLen, nil, nil, nvCodeLimit, vDataLimit, nvDataLimit);
            if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
            begin

              // Load
              Status := GP211_load(Context, CardInfo, @SecInfo, nil, 0, PChar(Filename), nil, receiptDataLen, nil);
              if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
              begin
                // Log
                memLog.Lines.Add(Format(FormatCardInstall, [Status.errorMessage]));
                //
                privilege := 4;
                // Install for Install and make selectable
                for I := 0 to loadFileParams.numAppletAIDs -1 do
                begin
                  Status := GP211_install_for_install_and_make_selectable(Context, CardInfo, @SecInfo, @pkgAID[0], pkgAIDLen, @loadFileParams.appletAIDs[I].AID, loadFileParams.appletAIDs[I].AIDLength, @loadFileParams.appletAIDs[I].AID, loadFileParams.appletAIDs[I].AIDLength, privilege, vDataLimit, nvDataLimit, @instParam[0], instParamLen, nil, receipt, receiptDataAvailable);
                  if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
                  begin
                    Success := True;
                  end;
                end;
              end;
            end;
          end;

          // Disconnect cardreader
          Status := OPGP_card_disconnect(Context, CardInfo);
          if Status.errorStatus = OPGP_ERROR_STATUS_SUCCESS then
          begin
            // Log
            memLog.Lines.Add(Format(FormatCardDisConn, [Status.errorMessage]));
          end;
        end;

        // Release context
        Status := OPGP_release_context(Context);
      end;
    end;
  finally
    R.Free;
  end;
  //
  if Success then
    memLog.Lines.Add(FormatCardSuccess)
  else
    memLog.Lines.Add(FormatCardError);
end;

end.

