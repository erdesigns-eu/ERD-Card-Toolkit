unit Type2Demo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent Type2Demo form; all visual controls belong to its own editable DFM.</summary>
  TType2DemoForm = class(TForm)
  published
    /// <summary>Read authentication configuration.</summary>
    ActPwdconfigTab: TTabSheet;
    /// <summary>Read authentication configuration inputs.</summary>
    ActPwdconfigInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdconfigType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdconfigType2modelBox: TComboBox;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdconfigPasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdconfigPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdconfigPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdconfigPackEdit: TEdit;
    /// <summary>Configure authentication + fresh RF proof.</summary>
    ActPwdconfigureTab: TTabSheet;
    /// <summary>Configure authentication + fresh RF proof inputs.</summary>
    ActPwdconfigureInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdconfigureType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdconfigureType2modelBox: TComboBox;
    /// <summary>AUTH0 byte (decimal; 255 disables protection) label.</summary>
    ActPwdconfigureFirstpageLabel: TLabel;
    /// <summary>AUTH0 byte (decimal; 255 disables protection).</summary>
    ActPwdconfigureFirstpageEdit: TEdit;
    /// <summary>Protection scope label.</summary>
    ActPwdconfigureProtectreadsLabel: TLabel;
    /// <summary>Protection scope.</summary>
    ActPwdconfigureProtectreadsBox: TComboBox;
    /// <summary>AUTHLIM (0..7; 0 disables limit) label.</summary>
    ActPwdconfigureAuthlimLabel: TLabel;
    /// <summary>AUTHLIM (0..7; 0 disables limit).</summary>
    ActPwdconfigureAuthlimEdit: TEdit;
    /// <summary>Exact eight-byte configuration preimage (hex) label.</summary>
    ActPwdconfigureBeforeLabel: TLabel;
    /// <summary>Exact eight-byte configuration preimage (hex).</summary>
    ActPwdconfigureBeforeEdit: TEdit;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdconfigurePasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdconfigurePasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdconfigurePackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdconfigurePackEdit: TEdit;
    /// <summary>Replace password/PACK + fresh RF proof.</summary>
    ActPwdcredentialsTab: TTabSheet;
    /// <summary>Replace password/PACK + fresh RF proof inputs.</summary>
    ActPwdcredentialsInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdcredentialsType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdcredentialsType2modelBox: TComboBox;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdcredentialsPasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdcredentialsPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdcredentialsPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdcredentialsPackEdit: TEdit;
    /// <summary>New four-byte password (hex) label.</summary>
    ActPwdcredentialsNewpasswordLabel: TLabel;
    /// <summary>New four-byte password (hex).</summary>
    ActPwdcredentialsNewpasswordEdit: TEdit;
    /// <summary>New two-byte PACK (hex) label.</summary>
    ActPwdcredentialsNewpackLabel: TLabel;
    /// <summary>New two-byte PACK (hex).</summary>
    ActPwdcredentialsNewpackEdit: TEdit;
    /// <summary>Read supported 24-bit counter.</summary>
    ActPwdcounterTab: TTabSheet;
    /// <summary>Read supported 24-bit counter inputs.</summary>
    ActPwdcounterInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdcounterType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdcounterType2modelBox: TComboBox;
    /// <summary>Counter (EV1: 0..2; NTAG213/215/216: 2) label.</summary>
    ActPwdcounterCounterLabel: TLabel;
    /// <summary>Counter (EV1: 0..2; NTAG213/215/216: 2).</summary>
    ActPwdcounterCounterEdit: TEdit;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdcounterPasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdcounterPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdcounterPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdcounterPackEdit: TEdit;
    /// <summary>Read and parse protected NDEF.</summary>
    ActPwdreadndefTab: TTabSheet;
    /// <summary>Read and parse protected NDEF inputs.</summary>
    ActPwdreadndefInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdreadndefType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdreadndefType2modelBox: TComboBox;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdreadndefPasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdreadndefPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdreadndefPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdreadndefPackEdit: TEdit;
    /// <summary>Replace/clear protected NDEF + verify.</summary>
    ActPwdwritendefTab: TTabSheet;
    /// <summary>Replace/clear protected NDEF + verify inputs.</summary>
    ActPwdwritendefInputs: TScrollBox;
    /// <summary>Explicit password-capable Type 2 model label.</summary>
    ActPwdwritendefType2modelLabel: TLabel;
    /// <summary>Explicit password-capable Type 2 model.</summary>
    ActPwdwritendefType2modelBox: TComboBox;
    /// <summary>Complete NDEF bytes (hex; empty clears existing TLV) label.</summary>
    ActPwdwritendefNdefLabel: TLabel;
    /// <summary>Complete NDEF bytes (hex; empty clears existing TLV).</summary>
    ActPwdwritendefNdefEdit: TEdit;
    /// <summary>Current four-byte password (hex) label.</summary>
    ActPwdwritendefPasswordLabel: TLabel;
    /// <summary>Current four-byte password (hex).</summary>
    ActPwdwritendefPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdwritendefPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdwritendefPackEdit: TEdit;
    /// <summary>Reader discovery and transport guidance.</summary>
    HeaderPanel: TPanel;
    /// <summary>Native card offered/removed status, independent of operation output.</summary>
    EventStatusLabel: TLabel;
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
    /// <summary>Read reader-order UID page.</summary>
    ActUidTab: TTabSheet;
    /// <summary>Read reader-order UID inputs.</summary>
    ActUidInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActUidInfo: TLabel;
    /// <summary>Read explicit physical page page.</summary>
    ActPageTab: TTabSheet;
    /// <summary>Read explicit physical page inputs.</summary>
    ActPageInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActPageType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActPageType2modelBox: TComboBox;
    /// <summary>Physical page label.</summary>
    ActPagePageLabel: TLabel;
    /// <summary>Physical page.</summary>
    ActPagePageEdit: TEdit;
    /// <summary>Read full public user-memory snapshot page.</summary>
    ActMemoryTab: TTabSheet;
    /// <summary>Read full public user-memory snapshot inputs.</summary>
    ActMemoryInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActMemoryType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActMemoryType2modelBox: TComboBox;
    /// <summary>Write user page: status receipt only page.</summary>
    ActWritepageTab: TTabSheet;
    /// <summary>Write user page: status receipt only inputs.</summary>
    ActWritepageInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActWritepageType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActWritepageType2modelBox: TComboBox;
    /// <summary>Physical user page label.</summary>
    ActWritepagePageLabel: TLabel;
    /// <summary>Physical user page.</summary>
    ActWritepagePageEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActWritepageDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActWritepageDataEdit: TEdit;
    /// <summary>Read public NDEF page.</summary>
    ActReadndefTab: TTabSheet;
    /// <summary>Read public NDEF inputs.</summary>
    ActReadndefInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActReadndefType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActReadndefType2modelBox: TComboBox;
    /// <summary>Replace public NDEF + verify page.</summary>
    ActWritendefTab: TTabSheet;
    /// <summary>Replace public NDEF + verify inputs.</summary>
    ActWritendefInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActWritendefType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActWritendefType2modelBox: TComboBox;
    /// <summary>Complete NDEF message (hex) label.</summary>
    ActWritendefNdefLabel: TLabel;
    /// <summary>Complete NDEF message (hex).</summary>
    ActWritendefNdefEdit: TEdit;
    /// <summary>Clear public NDEF + verify page.</summary>
    ActClearndefTab: TTabSheet;
    /// <summary>Clear public NDEF + verify inputs.</summary>
    ActClearndefInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActClearndefType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActClearndefType2modelBox: TComboBox;
    /// <summary>ACR122 PWD_AUTH + exact page page.</summary>
    ActPwdpageTab: TTabSheet;
    /// <summary>ACR122 PWD_AUTH + exact page inputs.</summary>
    ActPwdpageInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActPwdpageType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActPwdpageType2modelBox: TComboBox;
    /// <summary>Physical user page label.</summary>
    ActPwdpagePageLabel: TLabel;
    /// <summary>Physical user page.</summary>
    ActPwdpagePageEdit: TEdit;
    /// <summary>Supplied four-byte password (hex) label.</summary>
    ActPwdpagePasswordLabel: TLabel;
    /// <summary>Supplied four-byte password (hex).</summary>
    ActPwdpagePasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdpagePackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdpagePackEdit: TEdit;
    /// <summary>ACR122 PWD_AUTH + user memory page.</summary>
    ActPwdmemoryTab: TTabSheet;
    /// <summary>ACR122 PWD_AUTH + user memory inputs.</summary>
    ActPwdmemoryInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActPwdmemoryType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActPwdmemoryType2modelBox: TComboBox;
    /// <summary>Supplied four-byte password (hex) label.</summary>
    ActPwdmemoryPasswordLabel: TLabel;
    /// <summary>Supplied four-byte password (hex).</summary>
    ActPwdmemoryPasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdmemoryPackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdmemoryPackEdit: TEdit;
    /// <summary>ACR122 authenticated page write + verify page.</summary>
    ActPwdwriteTab: TTabSheet;
    /// <summary>ACR122 authenticated page write + verify inputs.</summary>
    ActPwdwriteInputs: TScrollBox;
    /// <summary>Actual Type 2 model label.</summary>
    ActPwdwriteType2modelLabel: TLabel;
    /// <summary>Actual Type 2 model.</summary>
    ActPwdwriteType2modelBox: TComboBox;
    /// <summary>Physical user page label.</summary>
    ActPwdwritePageLabel: TLabel;
    /// <summary>Physical user page.</summary>
    ActPwdwritePageEdit: TEdit;
    /// <summary>Supplied four-byte password (hex) label.</summary>
    ActPwdwritePasswordLabel: TLabel;
    /// <summary>Supplied four-byte password (hex).</summary>
    ActPwdwritePasswordEdit: TEdit;
    /// <summary>Expected two-byte PACK (hex) label.</summary>
    ActPwdwritePackLabel: TLabel;
    /// <summary>Expected two-byte PACK (hex).</summary>
    ActPwdwritePackEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActPwdwriteDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActPwdwriteDataEdit: TEdit;
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
    FReaderEvents: TCardDemoReaderEvents;
    procedure ReaderInventory(const ADevices: TCardDemoDevices);
    procedure ReaderStatus(const AText: string);
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
Type2DemoForm: TType2DemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TType2DemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfType2; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TType2DemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TType2DemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,0);
    end;
    1:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActPageType2modelBox;
      FInputs[1] := ActPagePageEdit;
    end;
    2:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActMemoryType2modelBox;
    end;
    3:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActWritepageType2modelBox;
      FInputs[1] := ActWritepagePageEdit;
      FInputs[2] := ActWritepageDataEdit;
    end;
    4:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActReadndefType2modelBox;
    end;
    5:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActWritendefType2modelBox;
      FInputs[1] := ActWritendefNdefEdit;
    end;
    6:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActClearndefType2modelBox;
    end;
    7:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActPwdpageType2modelBox;
      FInputs[1] := ActPwdpagePageEdit;
      FInputs[2] := ActPwdpagePasswordEdit;
      FInputs[3] := ActPwdpagePackEdit;
    end;
    8:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActPwdmemoryType2modelBox;
      FInputs[1] := ActPwdmemoryPasswordEdit;
      FInputs[2] := ActPwdmemoryPackEdit;
    end;
    9:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActPwdwriteType2modelBox;
      FInputs[1] := ActPwdwritePageEdit;
      FInputs[2] := ActPwdwritePasswordEdit;
      FInputs[3] := ActPwdwritePackEdit;
      FInputs[4] := ActPwdwriteDataEdit;
    end;
    10:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActPwdconfigType2modelBox;
      FInputs[1] := ActPwdconfigPasswordEdit;
      FInputs[2] := ActPwdconfigPackEdit;
    end;
    11:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActPwdconfigureType2modelBox;
      FInputs[1] := ActPwdconfigureFirstpageEdit;
      FInputs[2] := ActPwdconfigureProtectreadsBox;
      FInputs[3] := ActPwdconfigureAuthlimEdit;
      FInputs[4] := ActPwdconfigureBeforeEdit;
      FInputs[5] := ActPwdconfigurePasswordEdit;
      FInputs[6] := ActPwdconfigurePackEdit;
    end;
    12:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActPwdcredentialsType2modelBox;
      FInputs[1] := ActPwdcredentialsPasswordEdit;
      FInputs[2] := ActPwdcredentialsPackEdit;
      FInputs[3] := ActPwdcredentialsNewpasswordEdit;
      FInputs[4] := ActPwdcredentialsNewpackEdit;
    end;
    13:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActPwdcounterType2modelBox;
      FInputs[1] := ActPwdcounterCounterEdit;
      FInputs[2] := ActPwdcounterPasswordEdit;
      FInputs[3] := ActPwdcounterPackEdit;
    end;
    14:
    begin
      SetLength(FInputs,3);
      FInputs[0] := ActPwdreadndefType2modelBox;
      FInputs[1] := ActPwdreadndefPasswordEdit;
      FInputs[2] := ActPwdreadndefPackEdit;
    end;
    15:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActPwdwritendefType2modelBox;
      FInputs[1] := ActPwdwritendefNdefEdit;
      FInputs[2] := ActPwdwritendefPasswordEdit;
      FInputs[3] := ActPwdwritendefPackEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TType2DemoForm.ClearCredentials;
begin
  ActPwdconfigPasswordEdit.Clear;
  ActPwdconfigPackEdit.Clear;
  ActPwdconfigurePasswordEdit.Clear;
  ActPwdconfigurePackEdit.Clear;
  ActPwdcredentialsPasswordEdit.Clear;
  ActPwdcredentialsPackEdit.Clear;
  ActPwdcredentialsNewpasswordEdit.Clear;
  ActPwdcredentialsNewpackEdit.Clear;
  ActPwdcounterPasswordEdit.Clear;
  ActPwdcounterPackEdit.Clear;
  ActPwdreadndefPasswordEdit.Clear;
  ActPwdreadndefPackEdit.Clear;
  ActPwdwritendefPasswordEdit.Clear;
  ActPwdwritendefPackEdit.Clear;
  ActPwdpagePasswordEdit.Clear;
  ActPwdpagePackEdit.Clear;
  ActPwdmemoryPasswordEdit.Clear;
  ActPwdmemoryPackEdit.Clear;
  ActPwdwritePasswordEdit.Clear;
  ActPwdwritePackEdit.Clear;
end;

function TType2DemoForm.Request: TCardDemoRequest;
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

procedure TType2DemoForm.RunClick(Sender: TObject);
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

procedure TType2DemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TType2DemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TType2DemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TType2DemoForm.SetBusy(const AValue: Boolean);
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

procedure TType2DemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TType2DemoForm.PreviewArtifact(Sender: TObject);
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

procedure TType2DemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TType2DemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TType2DemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TType2DemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var I: Integer; Previous: UnicodeString;
begin
  Previous := SelectedAddress;
  if Previous = '' then Previous := FPreviousAddress;
  FDevices := Copy(ADevices,0,Length(ADevices)); ReaderBox.Items.Clear; ReaderBox.ItemIndex := -1;
  for I := 0 to High(FDevices) do
  begin
    ReaderBox.Items.Add(string(FDevices[I].DisplayName));
    if FDevices[I].Address = Previous then ReaderBox.ItemIndex := I;
  end;
  ReaderChanged(nil);
end;

procedure TType2DemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TType2DemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TType2DemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TType2DemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TType2DemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TType2DemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
