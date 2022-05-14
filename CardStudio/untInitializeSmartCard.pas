unit untInitializeSmartCard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, untPCSC, untUSB, Registry;

type
  TfrmInitializeSmartCard = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnCheck: TButton;
    gbReader: TGroupBox;
    cbReader: TComboBox;
    gbLog: TGroupBox;
    memLog: TMemo;
    Panel4: TPanel;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    rbT1: TRadioButton;
    rbT0: TRadioButton;
    cbFuse: TCheckBox;
    cbLock: TCheckBox;
    Panel3: TPanel;
    GroupBox4: TGroupBox;
    cbScheme: TComboBox;
    GroupBox5: TGroupBox;
    cbCountry: TComboBox;
    GroupBox6: TGroupBox;
    cbIssuer: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCheckClick(Sender: TObject);
    procedure cbSchemeChange(Sender: TObject);
  private
    { Private declarations }
    PCSC         : TPCSC;
    FUSBNotifier : TComponentUSB;

    procedure USBArrivalRemoval(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmInitializeSmartCard: TfrmInitializeSmartCard;

implementation

{$R *.dfm}

uses untEMVTools, untATR, untATRList, untConst, untBIN, untBIN_AMEX,
     untBIN_DINERSCLUB, untBIN_DISCOVER, untBIN_JCB, untBIN_MAESTRO,
     untBIN_MASTERCARD, untBIN_VISA;

{*******************************************************}
{               USB Insert/Remove Event                 }
{*******************************************************}
procedure TfrmInitializeSmartCard.USBArrivalRemoval(Sender: TObject);
begin
  // Reload SmartCard Reader/Writers
  PCSC.Init;
  // Populate list
  cbReader.Items.Assign(PCSC.ReaderList);
  if cbReader.Items.Count > 0 then
  begin
    PCSC.UseReaderNum := 0;
    cbReader.ItemIndex := 0;
  end;
  // Disconnect PCSC
  PCSC.Disconnect;
  PCSC.Close;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmInitializeSmartCard.FormCreate(Sender: TObject);
var
  I : Integer;
  R : TRegistry;
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Create PCSC
  PCSC := TPCSC.Create;
  PCSC.Init;
  // Populate SmartCard readers/writers
  cbReader.Items.Assign(PCSC.ReaderList);
  if cbReader.Items.Count > 0 then
  begin
    R := TRegistry.Create;
    try
      R.RootKey := HKEY_CURRENT_USER;
      if R.OpenKey(ApplicationRegKey, True) and R.ValueExists(PCSCDefault) then
      begin
        cbReader.ItemIndex := cbReader.Items.IndexOf(R.ReadString(PCSCDefault));
        PCSC.UseReaderNum := cbReader.ItemIndex;
      end else
      begin
        PCSC.UseReaderNum := 0;
        cbReader.ItemIndex := 0;
      end;
    finally
      R.Free;
    end;
  end;
  // Disconnect PCSC
  PCSC.Disconnect;
  PCSC.Close;
  // Create USB insert/remove notifier component
  FUSBNotifier := TComponentUSB.Create(Self);
  FUSBNotifier.OnUSBArrival := USBArrivalRemoval;
  FUSBNotifier.OnUSBRemove  := USBArrivalRemoval;
  // Clear Log memo
  memLog.Clear;
  // Populate card schemes (AMEX/.../VISA)
  for I := Low(CardSchemes) to High(CardSchemes) do
  cbScheme.Items.AddObject(CardSchemeToStr(CardSchemes[I]), TObject(CardSchemes[I]));
  cbScheme.ItemIndex := 0;
  // Populate countries
  for I := Low(CountryCodes) to High(CountryCodes) do
  cbCountry.Items.AddObject(CountryCodeToStr(CountryCodes[I]), TObject(CountryCodes[I]));
  cbCountry.ItemIndex := 0;
  // Load ATR's
  cbSchemeChange(Sender);
  // Set default ATR
  if cbIssuer.Items.Count > 0 then
  cbIssuer.ItemIndex := 0;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmInitializeSmartCard.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  // Free USB insert/remove notifier component
  FUSBNotifier.Destroy;
  // Free PCSC
  PCSC.Free;
  // Free Form
  Action := caFree;
  Release;
end;

{*******************************************************}
{                   Initialize Card                     }
{*******************************************************}
procedure TfrmInitializeSmartCard.btnCheckClick(Sender: TObject);

  function SendADPU(const ADPU: AnsiString) : Boolean;
  begin
    Result := Bin2HexExt(PCSC.GetResponseFromCard(Hex2Bin(ADPU))) = '90 00';
  end;

  function SendHistoricalBytesADPU(const ADPU: AnsiString; const HistoricalBytes: AnsiString; const HBLength: Integer) : Boolean;
  var
    L1, L2 : AnsiString;
  begin
    L1 := IntToHex(HBLength +1, 2);
    L2 := IntToHex(HBLength, 2);
    Result := SendADPU(ADPU + L1 + L2 + Bin2HexExt(HistoricalBytes, False));
  end;

const
  B : Array [Boolean] of string = ('Failed', 'Success');
var
  R   : TRegistry;
  X   : Boolean;
  S   : string;
  ATR : ATRrec;
begin
  if cbLock.Checked then
  if Application.MessageBox(InitializeLockWarning, PChar(ApplicationTitle), MB_ICONWARNING + MB_YESNO) <> ID_YES then Exit;
  //
  if (cbReader.ItemIndex = -1) then Exit;
  // Clear log
  memLog.Clear;
  //
  X := True;
  // Create ATR record
  ATR.Load(Hex2Bin(ATRS[Integer(cbIssuer.Items.Objects[cbIssuer.ItemIndex])].atr_value));
  //
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // Initialize Card Reader/Writer
      PCSC.Init;
      PCSC.UseReaderNum := cbReader.ItemIndex;
      if PCSC.Open and PCSC.Connect then
      with memLog.Lines do
      begin
        BeginUpdate;
        Clear;
        // Header
        Add(InitializeHeader);
        // Connect to reader message
        Add(Format(InitializeCardCon, [B[X]]));
        // Initialize Card
        if R.ValueExists(PCSCTransportKey) then
        begin
          // Send Transport Key
          S := R.ReadString(PCSCTransportKey);
          Add(Format(InitializeTK, [B[X]]));
          if not SendADPU(Format('00A40400%.*x%s', [2, Length(S) div 2, S])) then X := False;
          // Wipe existing applets
          Add(InitializeClear);
          if not SendADPU('00F00000') then X := False;
          // Set Transmission Mode
          if rbT1.Checked then
          begin
            Add(Format(InitializeTMode, ['T=1']));
            if not SendADPU('C0D6012301DA') then X := False;
            if not SendADPU('C0D6014601DA') then X := False;
            if not SendADPU('C0D6012201FE') then X := False;
            Add(Format(InitializeId, ['T=1']));
            if not SendADPU('C0D60124010F') then X := False;
            if not SendADPU('C0D60147010F') then X := False;
          end else
          begin
            Add(Format(InitializeTMode, ['T=0']));
            if not SendADPU('c0d601240108') then X := False;
            if not SendADPU('c0d601470108') then X := False;
            Add(Format(InitializeId, ['T=0']));
            if not SendADPU('c0d6012604036000ff') then X := False;
            if not SendADPU('c0d6014904036000ff') then X := False;
          end;
          // Unknown 1
          if not SendADPU(ATRSet1) then X := False;
          // Unknown 2
          if not SendADPU(ATRSet2) then X := False;
          // Unknown 3
          if not SendADPU(ATRSet3) then X := False;
          // Unknown 4
          if not SendADPU(ATRSet4) then X := False;
          // Unknown 5
          if not SendADPU(ATRSet5) then X := False;
          // Unknown 6
          if not SendADPU(ATRSet6) then X := False;
          Add('');
          // Set COLD ATR Historical Bytes
          Add(ATRSetCold);
          if not SendHistoricalBytesADPU(ATRSetATRCold, ATR.HistoricalBytes, ATR.HistoricalBytesCount) then X := False;
          // Set HOT ATR istorical Bytes
          Add(ATRSetHot);
          if not SendHistoricalBytesADPU(ATRSetATRHot, ATR.HistoricalBytes, ATR.HistoricalBytesCount) then X := False;
          //
          // Unknown 7
          if not SendADPU(ATRSet7) then X := False;
          // Set Card Authentication Key - Encryption
          if R.ValueExists(PCSCEncryptionKey) then
          begin
            Add(Format(InitializeAuth, ['Encryption']));
            S := R.ReadString(PCSCEncryptionKey);
            if not SendADPU(Format('c0d60305%.*x%s', [2, length(S) div 2, S])) then X := False;
          end else
          begin
            Add(Format(InitializeAuth, [InitializeAUError]));
            X := False;
          end;
          // Unknown 8
          if not SendADPU(ATRSet8) then X := False;
          // Set Card Authentication Key - MAC
          if R.ValueExists(PCSCEncryptionKey) then
          begin
            Add(Format(InitializeAuth, ['MAC']));
            S := R.ReadString(PCSCMACKey);
            if not SendADPU(Format('c0d60321%.*x%s', [2, length(S) div 2, S])) then X := False;
          end else
          begin
            Add(Format(InitializeAuth, [InitializeAUError]));
            X := False;
          end;
          // unknown 9
          if not SendADPU(ATRSet9) then X := False;
          // Set Card Authentication Key - DATA
          if R.ValueExists(PCSCEncryptionKey) then
          begin
            Add(Format(InitializeAuth, ['Data']));
            S := R.ReadString(PCSCDataKey);
            if not SendADPU(Format('c0d6033D%.*x%s', [2, length(S) div 2, S])) then X := False;
          end else
          begin
            Add(Format(InitializeAuth, [InitializeAUError]));
            X := False;
          end;
          // Lock card
          if cbLock.Checked then if not SendADPU(ATRSetLock) then X := False;
          // Fuse card
          if cbFuse.Checked then if not SendADPU(ATRFuseCard) then X := False;
        end else
        begin
          Add(Format(InitializeTK, [InitializeTKError]));
          X := False;
        end;
        //
        EndUpdate;
      end;
    end;
    // Success message
    if X then
      Application.MessageBox(InitializeSuccess, PChar(Application.Title), MB_ICONINFORMATION + MB_OK)
    else
      Application.MessageBox(InitializeError, PChar(Application.Title), MB_ICONERROR + MB_OK);
  finally
    R.Free;
  end;
end;

{*******************************************************}
{                Load List with Issuers                 }
{*******************************************************}
procedure TfrmInitializeSmartCard.cbSchemeChange(Sender: TObject);
var
  I : Integer;
begin
  cbIssuer.Clear;
  for I := Low(ATRS) to High(ATRS) do
  if (ATRS[I].atr_scheme = TCardScheme(cbScheme.Items.Objects[cbScheme.ItemIndex])) and
     (ATRS[I].atr_country = TCountryCode(cbCountry.Items.Objects[cbCountry.ItemIndex])) then
  begin
    cbIssuer.Items.AddObject(Format('%s'{'%s (%s)'}, [ATRS[I].atr_issuer, CardTypeToStr(ATRS[I].atr_type)]), TObject(I));
  end;
end;

end.
