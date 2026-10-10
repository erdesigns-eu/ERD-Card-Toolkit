unit DesfireDemo.Main;

{$CODEPAGE UTF8}

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent DesfireDemo form; all visual controls belong to its own editable DFM.</summary>
  TDesfireDemoForm = class(TForm)
  published
    /// <summary>Change DES/3DES key + fresh authentication proof.</summary>
    ActChangedeskeyTab: TTabSheet;
    /// <summary>Change DES/3DES key + fresh authentication proof inputs.</summary>
    ActChangedeskeyInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActChangedeskeyAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActChangedeskeyAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActChangedeskeySecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActChangedeskeySecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActChangedeskeyMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActChangedeskeyMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActChangedeskeyKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActChangedeskeyKeynumberEdit: TEdit;
    /// <summary>Supplied authentication key (hex; 8/16/24 bytes by profile) label.</summary>
    ActChangedeskeyKeyLabel: TLabel;
    /// <summary>Supplied authentication key (hex; 8/16/24 bytes by profile).</summary>
    ActChangedeskeyKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActChangedeskeyRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActChangedeskeyRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActChangedeskeyRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActChangedeskeyRekeyEdit: TEdit;
    /// <summary>Target key number label.</summary>
    ActChangedeskeyTargetkeyLabel: TLabel;
    /// <summary>Target key number.</summary>
    ActChangedeskeyTargetkeyEdit: TEdit;
    /// <summary>New key version label.</summary>
    ActChangedeskeyKeyversionLabel: TLabel;
    /// <summary>New key version.</summary>
    ActChangedeskeyKeyversionEdit: TEdit;
    /// <summary>New key (8/16/24 bytes for selected profile, hex) label.</summary>
    ActChangedeskeyNewkeyLabel: TLabel;
    /// <summary>New key (8/16/24 bytes for selected profile, hex).</summary>
    ActChangedeskeyNewkeyEdit: TEdit;
    /// <summary>Old stored target key including second/third subkey version bits; empty if current (hex) label.</summary>
    ActChangedeskeyOldkeyLabel: TLabel;
    /// <summary>Old stored target key including second/third subkey version bits; empty if current (hex).</summary>
    ActChangedeskeyOldkeyEdit: TEdit;
    /// <summary>Old first-subkey version (decimal; ignored for current key) label.</summary>
    ActChangedeskeyOldversionLabel: TLabel;
    /// <summary>Old first-subkey version (decimal; ignored for current key).</summary>
    ActChangedeskeyOldversionEdit: TEdit;
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
    /// <summary>Read public native version page.</summary>
    ActVersionTab: TTabSheet;
    /// <summary>Read public native version inputs.</summary>
    ActVersionInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActVersionInfo: TLabel;
    /// <summary>Read public native application IDs page.</summary>
    ActApplicationsTab: TTabSheet;
    /// <summary>Read public native application IDs inputs.</summary>
    ActApplicationsInputs: TScrollBox;
    /// <summary>This action has no additional parameters.</summary>
    ActApplicationsInfo: TLabel;
    /// <summary>Read acquired file directory page.</summary>
    ActFilesTab: TTabSheet;
    /// <summary>Read acquired file directory inputs.</summary>
    ActFilesInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActFilesAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActFilesAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActFilesSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActFilesSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActFilesMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActFilesMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActFilesKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActFilesKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActFilesKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActFilesKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActFilesRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActFilesRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActFilesRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActFilesRekeyEdit: TEdit;
    /// <summary>Read data file page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Read data file inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActReadAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActReadAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActReadSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActReadSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActReadMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActReadMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActReadKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActReadKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActReadKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActReadKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActReadRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActReadRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActReadRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActReadRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActReadFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActReadFileEdit: TEdit;
    /// <summary>Byte / record offset label.</summary>
    ActReadOffsetLabel: TLabel;
    /// <summary>Byte / record offset.</summary>
    ActReadOffsetEdit: TEdit;
    /// <summary>Byte / record count label.</summary>
    ActReadCountLabel: TLabel;
    /// <summary>Byte / record count.</summary>
    ActReadCountEdit: TEdit;
    /// <summary>Read signed value page.</summary>
    ActValueTab: TTabSheet;
    /// <summary>Read signed value inputs.</summary>
    ActValueInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActValueAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActValueAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActValueSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActValueSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActValueMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActValueMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActValueKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActValueKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActValueKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActValueKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActValueRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActValueRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActValueRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActValueRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActValueFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActValueFileEdit: TEdit;
    /// <summary>Read complete records page.</summary>
    ActRecordsTab: TTabSheet;
    /// <summary>Read complete records inputs.</summary>
    ActRecordsInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActRecordsAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActRecordsAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActRecordsSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActRecordsSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActRecordsMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActRecordsMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActRecordsKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActRecordsKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActRecordsKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActRecordsKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActRecordsRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActRecordsRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActRecordsRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActRecordsRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActRecordsFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActRecordsFileEdit: TEdit;
    /// <summary>Byte / record offset label.</summary>
    ActRecordsOffsetLabel: TLabel;
    /// <summary>Byte / record offset.</summary>
    ActRecordsOffsetEdit: TEdit;
    /// <summary>Byte / record count label.</summary>
    ActRecordsCountLabel: TLabel;
    /// <summary>Byte / record count.</summary>
    ActRecordsCountEdit: TEdit;
    /// <summary>Write standard data + verify page.</summary>
    ActWriteTab: TTabSheet;
    /// <summary>Write standard data + verify inputs.</summary>
    ActWriteInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActWriteAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActWriteAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActWriteSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActWriteSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActWriteMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActWriteMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActWriteKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActWriteKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActWriteKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActWriteKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActWriteRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActWriteRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActWriteRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActWriteRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActWriteFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActWriteFileEdit: TEdit;
    /// <summary>Byte / record offset label.</summary>
    ActWriteOffsetLabel: TLabel;
    /// <summary>Byte / record offset.</summary>
    ActWriteOffsetEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActWriteDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActWriteDataEdit: TEdit;
    /// <summary>Stage backup write + explicit commit / abort page.</summary>
    ActBackupTab: TTabSheet;
    /// <summary>Stage backup write + explicit commit / abort inputs.</summary>
    ActBackupInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActBackupAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActBackupAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActBackupSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActBackupSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActBackupMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActBackupMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActBackupKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActBackupKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActBackupKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActBackupKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActBackupRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActBackupRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActBackupRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActBackupRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActBackupAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActBackupAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActBackupFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActBackupFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActBackupFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActBackupFileEdit: TEdit;
    /// <summary>Byte / record offset label.</summary>
    ActBackupOffsetLabel: TLabel;
    /// <summary>Byte / record offset.</summary>
    ActBackupOffsetEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActBackupDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActBackupDataEdit: TEdit;
    /// <summary>Stage value credit + explicit commit / abort page.</summary>
    ActCreditTab: TTabSheet;
    /// <summary>Stage value credit + explicit commit / abort inputs.</summary>
    ActCreditInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActCreditAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActCreditAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActCreditSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActCreditSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActCreditMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActCreditMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActCreditKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActCreditKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActCreditKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActCreditKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActCreditRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActCreditRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActCreditRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActCreditRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActCreditAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActCreditAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActCreditFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActCreditFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActCreditFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActCreditFileEdit: TEdit;
    /// <summary>Positive amount label.</summary>
    ActCreditAmountLabel: TLabel;
    /// <summary>Positive amount.</summary>
    ActCreditAmountEdit: TEdit;
    /// <summary>Stage value debit + explicit commit / abort page.</summary>
    ActDebitTab: TTabSheet;
    /// <summary>Stage value debit + explicit commit / abort inputs.</summary>
    ActDebitInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActDebitAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActDebitAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActDebitSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActDebitSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActDebitMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActDebitMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActDebitKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActDebitKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActDebitKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActDebitKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActDebitRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActDebitRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActDebitRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActDebitRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActDebitAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActDebitAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActDebitFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActDebitFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActDebitFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActDebitFileEdit: TEdit;
    /// <summary>Positive amount label.</summary>
    ActDebitAmountLabel: TLabel;
    /// <summary>Positive amount.</summary>
    ActDebitAmountEdit: TEdit;
    /// <summary>Stage limited credit + explicit commit / abort page.</summary>
    ActLimitedTab: TTabSheet;
    /// <summary>Stage limited credit + explicit commit / abort inputs.</summary>
    ActLimitedInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActLimitedAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActLimitedAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActLimitedSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActLimitedSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActLimitedMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActLimitedMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActLimitedKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActLimitedKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActLimitedKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActLimitedKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActLimitedRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActLimitedRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActLimitedRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActLimitedRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActLimitedAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActLimitedAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActLimitedFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActLimitedFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActLimitedFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActLimitedFileEdit: TEdit;
    /// <summary>Positive amount label.</summary>
    ActLimitedAmountLabel: TLabel;
    /// <summary>Positive amount.</summary>
    ActLimitedAmountEdit: TEdit;
    /// <summary>Stage complete record + explicit commit / abort page.</summary>
    ActAppendTab: TTabSheet;
    /// <summary>Stage complete record + explicit commit / abort inputs.</summary>
    ActAppendInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActAppendAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActAppendAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActAppendSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActAppendSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActAppendMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActAppendMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActAppendKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActAppendKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActAppendKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActAppendKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActAppendRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActAppendRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActAppendRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActAppendRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActAppendAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActAppendAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActAppendFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActAppendFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActAppendFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActAppendFileEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActAppendDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActAppendDataEdit: TEdit;
    /// <summary>Stage records clear + explicit commit / abort page.</summary>
    ActClearTab: TTabSheet;
    /// <summary>Stage records clear + explicit commit / abort inputs.</summary>
    ActClearInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActClearAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActClearAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActClearSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActClearSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActClearMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActClearMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActClearKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActClearKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActClearKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActClearKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActClearRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActClearRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActClearRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActClearRekeyEdit: TEdit;
    /// <summary>Transaction authority label.</summary>
    ActClearAccessLabel: TLabel;
    /// <summary>Transaction authority.</summary>
    ActClearAccessBox: TComboBox;
    /// <summary>Explicit transaction decision label.</summary>
    ActClearFinishLabel: TLabel;
    /// <summary>Explicit transaction decision.</summary>
    ActClearFinishBox: TComboBox;
    /// <summary>Native file number label.</summary>
    ActClearFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActClearFileEdit: TEdit;
    /// <summary>Read acquired application settings page.</summary>
    ActSettingsTab: TTabSheet;
    /// <summary>Read acquired application settings inputs.</summary>
    ActSettingsInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActSettingsAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActSettingsAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActSettingsSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActSettingsSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActSettingsMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActSettingsMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActSettingsKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActSettingsKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActSettingsKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActSettingsKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActSettingsRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActSettingsRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActSettingsRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActSettingsRekeyEdit: TEdit;
    /// <summary>Read PICC free memory page.</summary>
    ActFreememoryTab: TTabSheet;
    /// <summary>Read PICC free memory inputs.</summary>
    ActFreememoryInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActFreememoryAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActFreememoryAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActFreememorySecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActFreememorySecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActFreememoryMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActFreememoryMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActFreememoryKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActFreememoryKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActFreememoryKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActFreememoryKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActFreememoryRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActFreememoryRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActFreememoryRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActFreememoryRekeyEdit: TEdit;
    /// <summary>Read explicit key version page.</summary>
    ActKeyversionTab: TTabSheet;
    /// <summary>Read explicit key version inputs.</summary>
    ActKeyversionInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActKeyversionAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActKeyversionAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActKeyversionSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActKeyversionSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActKeyversionMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActKeyversionMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActKeyversionKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActKeyversionKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActKeyversionKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActKeyversionKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActKeyversionRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActKeyversionRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActKeyversionRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActKeyversionRekeyEdit: TEdit;
    /// <summary>Target key number label.</summary>
    ActKeyversionTargetkeyLabel: TLabel;
    /// <summary>Target key number.</summary>
    ActKeyversionTargetkeyEdit: TEdit;
    /// <summary>Change key settings + verify page.</summary>
    ActKeysettingsTab: TTabSheet;
    /// <summary>Change key settings + verify inputs.</summary>
    ActKeysettingsInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActKeysettingsAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActKeysettingsAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActKeysettingsSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActKeysettingsSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActKeysettingsMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActKeysettingsMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActKeysettingsKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActKeysettingsKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActKeysettingsKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActKeysettingsKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActKeysettingsRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActKeysettingsRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActKeysettingsRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActKeysettingsRekeyEdit: TEdit;
    /// <summary>Exact settings byte (decimal) label.</summary>
    ActKeysettingsSettingsLabel: TLabel;
    /// <summary>Exact settings byte (decimal).</summary>
    ActKeysettingsSettingsEdit: TEdit;
    /// <summary>Change file access + verify page.</summary>
    ActFileaccessTab: TTabSheet;
    /// <summary>Change file access + verify inputs.</summary>
    ActFileaccessInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActFileaccessAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActFileaccessAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActFileaccessSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActFileaccessSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActFileaccessMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActFileaccessMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActFileaccessKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActFileaccessKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActFileaccessKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActFileaccessKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActFileaccessRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActFileaccessRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActFileaccessRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActFileaccessRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActFileaccessFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActFileaccessFileEdit: TEdit;
    /// <summary>Requested communication label.</summary>
    ActFileaccessCommunicationLabel: TLabel;
    /// <summary>Requested communication.</summary>
    ActFileaccessCommunicationBox: TComboBox;
    /// <summary>Read nibble (decimal) label.</summary>
    ActFileaccessReadkeyLabel: TLabel;
    /// <summary>Read nibble (decimal).</summary>
    ActFileaccessReadkeyEdit: TEdit;
    /// <summary>Write nibble (decimal) label.</summary>
    ActFileaccessWritekeyLabel: TLabel;
    /// <summary>Write nibble (decimal).</summary>
    ActFileaccessWritekeyEdit: TEdit;
    /// <summary>ReadWrite nibble (decimal) label.</summary>
    ActFileaccessReadwritekeyLabel: TLabel;
    /// <summary>ReadWrite nibble (decimal).</summary>
    ActFileaccessReadwritekeyEdit: TEdit;
    /// <summary>Change-access nibble (decimal) label.</summary>
    ActFileaccessChangekeyLabel: TLabel;
    /// <summary>Change-access nibble (decimal).</summary>
    ActFileaccessChangekeyEdit: TEdit;
    /// <summary>Change AES key + fresh authentication proof page.</summary>
    ActChangekeyTab: TTabSheet;
    /// <summary>Change AES key + fresh authentication proof inputs.</summary>
    ActChangekeyInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActChangekeyAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActChangekeyAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActChangekeySecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActChangekeySecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActChangekeyMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActChangekeyMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActChangekeyKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActChangekeyKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActChangekeyKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActChangekeyKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActChangekeyRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActChangekeyRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActChangekeyRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActChangekeyRekeyEdit: TEdit;
    /// <summary>Target key number label.</summary>
    ActChangekeyTargetkeyLabel: TLabel;
    /// <summary>Target key number.</summary>
    ActChangekeyTargetkeyEdit: TEdit;
    /// <summary>New key version label.</summary>
    ActChangekeyKeyversionLabel: TLabel;
    /// <summary>New key version.</summary>
    ActChangekeyKeyversionEdit: TEdit;
    /// <summary>New 16-byte AES key (hex) label.</summary>
    ActChangekeyNewkeyLabel: TLabel;
    /// <summary>New 16-byte AES key (hex).</summary>
    ActChangekeyNewkeyEdit: TEdit;
    /// <summary>Old 16-byte target key; empty if current key (hex) label.</summary>
    ActChangekeyOldkeyLabel: TLabel;
    /// <summary>Old 16-byte target key; empty if current key (hex).</summary>
    ActChangekeyOldkeyEdit: TEdit;
    /// <summary>Create explicit application + verify page.</summary>
    ActCreateappTab: TTabSheet;
    /// <summary>Create explicit application + verify inputs.</summary>
    ActCreateappInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActCreateappAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActCreateappAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActCreateappSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActCreateappSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActCreateappMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActCreateappMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActCreateappKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActCreateappKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActCreateappKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActCreateappKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActCreateappRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActCreateappRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActCreateappRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActCreateappRekeyEdit: TEdit;
    /// <summary>New nonzero native AID (decimal) label.</summary>
    ActCreateappTargetaidLabel: TLabel;
    /// <summary>New nonzero native AID (decimal).</summary>
    ActCreateappTargetaidEdit: TEdit;
    /// <summary>Exact key-settings byte (decimal) label.</summary>
    ActCreateappSettingsLabel: TLabel;
    /// <summary>Exact key-settings byte (decimal).</summary>
    ActCreateappSettingsEdit: TEdit;
    /// <summary>Exact key-configuration byte (decimal) label.</summary>
    ActCreateappKeycountLabel: TLabel;
    /// <summary>Exact key-configuration byte (decimal).</summary>
    ActCreateappKeycountEdit: TEdit;
    /// <summary>Explicit new application key-storage type label.</summary>
    ActCreateappKeytypeLabel: TLabel;
    /// <summary>DES/2K3DES, 3K3DES or AES; requires explicit selection.</summary>
    ActCreateappKeytypeBox: TComboBox;
    /// <summary>Delete explicit application + verify page.</summary>
    ActDeleteappTab: TTabSheet;
    /// <summary>Delete explicit application + verify inputs.</summary>
    ActDeleteappInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActDeleteappAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActDeleteappAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActDeleteappSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActDeleteappSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActDeleteappMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActDeleteappMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActDeleteappKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActDeleteappKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActDeleteappKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActDeleteappKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActDeleteappRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActDeleteappRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActDeleteappRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActDeleteappRekeyEdit: TEdit;
    /// <summary>Target nonzero native AID (decimal) label.</summary>
    ActDeleteappTargetaidLabel: TLabel;
    /// <summary>Target nonzero native AID (decimal).</summary>
    ActDeleteappTargetaidEdit: TEdit;
    /// <summary>Delete explicit file + verify page.</summary>
    ActDeletefileTab: TTabSheet;
    /// <summary>Delete explicit file + verify inputs.</summary>
    ActDeletefileInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActDeletefileAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActDeletefileAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActDeletefileSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActDeletefileSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActDeletefileMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActDeletefileMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActDeletefileKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActDeletefileKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActDeletefileKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActDeletefileKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActDeletefileRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActDeletefileRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActDeletefileRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActDeletefileRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActDeletefileFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActDeletefileFileEdit: TEdit;
    /// <summary>Create explicit ordinary file + verify page.</summary>
    ActCreatefileTab: TTabSheet;
    /// <summary>Create explicit ordinary file + verify inputs.</summary>
    ActCreatefileInputs: TScrollBox;
    /// <summary>Explicit native AID (decimal; 0 = PICC) label.</summary>
    ActCreatefileAidLabel: TLabel;
    /// <summary>Explicit native AID (decimal; 0 = PICC).</summary>
    ActCreatefileAidEdit: TEdit;
    /// <summary>Explicit security profile label.</summary>
    ActCreatefileSecurityLabel: TLabel;
    /// <summary>Explicit security profile.</summary>
    ActCreatefileSecurityBox: TComboBox;
    /// <summary>Minimum communication label.</summary>
    ActCreatefileMinimumLabel: TLabel;
    /// <summary>Minimum communication.</summary>
    ActCreatefileMinimumBox: TComboBox;
    /// <summary>Supplied authentication key number label.</summary>
    ActCreatefileKeynumberLabel: TLabel;
    /// <summary>Supplied authentication key number.</summary>
    ActCreatefileKeynumberEdit: TEdit;
    /// <summary>Supplied AES key (hex) label.</summary>
    ActCreatefileKeyLabel: TLabel;
    /// <summary>Supplied AES key (hex).</summary>
    ActCreatefileKeyEdit: TEdit;
    /// <summary>Secondary proof-context key number label.</summary>
    ActCreatefileRekeynumberLabel: TLabel;
    /// <summary>Secondary proof-context key number.</summary>
    ActCreatefileRekeynumberEdit: TEdit;
    /// <summary>Optional explicit secondary-context AES key (hex) label.</summary>
    ActCreatefileRekeyLabel: TLabel;
    /// <summary>Optional explicit secondary-context AES key (hex).</summary>
    ActCreatefileRekeyEdit: TEdit;
    /// <summary>Native file number label.</summary>
    ActCreatefileFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActCreatefileFileEdit: TEdit;
    /// <summary>Exact file type label.</summary>
    ActCreatefileTypeLabel: TLabel;
    /// <summary>Exact file type.</summary>
    ActCreatefileTypeBox: TComboBox;
    /// <summary>Requested communication label.</summary>
    ActCreatefileCommunicationLabel: TLabel;
    /// <summary>Requested communication.</summary>
    ActCreatefileCommunicationBox: TComboBox;
    /// <summary>Read nibble (decimal) label.</summary>
    ActCreatefileReadkeyLabel: TLabel;
    /// <summary>Read nibble (decimal).</summary>
    ActCreatefileReadkeyEdit: TEdit;
    /// <summary>Write nibble (decimal) label.</summary>
    ActCreatefileWritekeyLabel: TLabel;
    /// <summary>Write nibble (decimal).</summary>
    ActCreatefileWritekeyEdit: TEdit;
    /// <summary>ReadWrite nibble (decimal) label.</summary>
    ActCreatefileReadwritekeyLabel: TLabel;
    /// <summary>ReadWrite nibble (decimal).</summary>
    ActCreatefileReadwritekeyEdit: TEdit;
    /// <summary>Change-access nibble (decimal) label.</summary>
    ActCreatefileChangekeyLabel: TLabel;
    /// <summary>Change-access nibble (decimal).</summary>
    ActCreatefileChangekeyEdit: TEdit;
    /// <summary>Data-file bytes; otherwise 0 label.</summary>
    ActCreatefileFilebytesLabel: TLabel;
    /// <summary>Data-file bytes; otherwise 0.</summary>
    ActCreatefileFilebytesEdit: TEdit;
    /// <summary>Value lower bound; otherwise 0 label.</summary>
    ActCreatefileLowerLabel: TLabel;
    /// <summary>Value lower bound; otherwise 0.</summary>
    ActCreatefileLowerEdit: TEdit;
    /// <summary>Value upper bound; otherwise 0 label.</summary>
    ActCreatefileUpperLabel: TLabel;
    /// <summary>Value upper bound; otherwise 0.</summary>
    ActCreatefileUpperEdit: TEdit;
    /// <summary>Initial value; otherwise 0 label.</summary>
    ActCreatefileInitialLabel: TLabel;
    /// <summary>Initial value; otherwise 0.</summary>
    ActCreatefileInitialEdit: TEdit;
    /// <summary>Limited credit enabled label.</summary>
    ActCreatefileLimitedLabel: TLabel;
    /// <summary>Limited credit enabled.</summary>
    ActCreatefileLimitedBox: TComboBox;
    /// <summary>Record bytes; otherwise 0 label.</summary>
    ActCreatefileRecordbytesLabel: TLabel;
    /// <summary>Record bytes; otherwise 0.</summary>
    ActCreatefileRecordbytesEdit: TEdit;
    /// <summary>Record capacity; otherwise 0 label.</summary>
    ActCreatefileMaxrecordsLabel: TLabel;
    /// <summary>Record capacity; otherwise 0.</summary>
    ActCreatefileMaxrecordsEdit: TEdit;
    /// <summary>Offline file settings decoder page.</summary>
    ActDecodeTab: TTabSheet;
    /// <summary>Offline file settings decoder inputs.</summary>
    ActDecodeInputs: TScrollBox;
    /// <summary>Native file number label.</summary>
    ActDecodeFileLabel: TLabel;
    /// <summary>Native file number.</summary>
    ActDecodeFileEdit: TEdit;
    /// <summary>Complete native settings bytes (hex) label.</summary>
    ActDecodeHexLabel: TLabel;
    /// <summary>Complete native settings bytes (hex).</summary>
    ActDecodeHexEdit: TEdit;
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
DesfireDemoForm: TDesfireDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TDesfireDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfDesfire; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TDesfireDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TDesfireDemoForm.ActionChanged(Sender: TObject);
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
      SetLength(FInputs,0);
    end;
    2:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActFilesAidEdit;
      FInputs[1] := ActFilesSecurityBox;
      FInputs[2] := ActFilesMinimumBox;
      FInputs[3] := ActFilesKeynumberEdit;
      FInputs[4] := ActFilesKeyEdit;
      FInputs[5] := ActFilesRekeynumberEdit;
      FInputs[6] := ActFilesRekeyEdit;
    end;
    3:
    begin
      SetLength(FInputs,10);
      FInputs[0] := ActReadAidEdit;
      FInputs[1] := ActReadSecurityBox;
      FInputs[2] := ActReadMinimumBox;
      FInputs[3] := ActReadKeynumberEdit;
      FInputs[4] := ActReadKeyEdit;
      FInputs[5] := ActReadRekeynumberEdit;
      FInputs[6] := ActReadRekeyEdit;
      FInputs[7] := ActReadFileEdit;
      FInputs[8] := ActReadOffsetEdit;
      FInputs[9] := ActReadCountEdit;
    end;
    4:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActValueAidEdit;
      FInputs[1] := ActValueSecurityBox;
      FInputs[2] := ActValueMinimumBox;
      FInputs[3] := ActValueKeynumberEdit;
      FInputs[4] := ActValueKeyEdit;
      FInputs[5] := ActValueRekeynumberEdit;
      FInputs[6] := ActValueRekeyEdit;
      FInputs[7] := ActValueFileEdit;
    end;
    5:
    begin
      SetLength(FInputs,10);
      FInputs[0] := ActRecordsAidEdit;
      FInputs[1] := ActRecordsSecurityBox;
      FInputs[2] := ActRecordsMinimumBox;
      FInputs[3] := ActRecordsKeynumberEdit;
      FInputs[4] := ActRecordsKeyEdit;
      FInputs[5] := ActRecordsRekeynumberEdit;
      FInputs[6] := ActRecordsRekeyEdit;
      FInputs[7] := ActRecordsFileEdit;
      FInputs[8] := ActRecordsOffsetEdit;
      FInputs[9] := ActRecordsCountEdit;
    end;
    6:
    begin
      SetLength(FInputs,10);
      FInputs[0] := ActWriteAidEdit;
      FInputs[1] := ActWriteSecurityBox;
      FInputs[2] := ActWriteMinimumBox;
      FInputs[3] := ActWriteKeynumberEdit;
      FInputs[4] := ActWriteKeyEdit;
      FInputs[5] := ActWriteRekeynumberEdit;
      FInputs[6] := ActWriteRekeyEdit;
      FInputs[7] := ActWriteFileEdit;
      FInputs[8] := ActWriteOffsetEdit;
      FInputs[9] := ActWriteDataEdit;
    end;
    7:
    begin
      SetLength(FInputs,12);
      FInputs[0] := ActBackupAidEdit;
      FInputs[1] := ActBackupSecurityBox;
      FInputs[2] := ActBackupMinimumBox;
      FInputs[3] := ActBackupKeynumberEdit;
      FInputs[4] := ActBackupKeyEdit;
      FInputs[5] := ActBackupRekeynumberEdit;
      FInputs[6] := ActBackupRekeyEdit;
      FInputs[7] := ActBackupAccessBox;
      FInputs[8] := ActBackupFinishBox;
      FInputs[9] := ActBackupFileEdit;
      FInputs[10] := ActBackupOffsetEdit;
      FInputs[11] := ActBackupDataEdit;
    end;
    8:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActCreditAidEdit;
      FInputs[1] := ActCreditSecurityBox;
      FInputs[2] := ActCreditMinimumBox;
      FInputs[3] := ActCreditKeynumberEdit;
      FInputs[4] := ActCreditKeyEdit;
      FInputs[5] := ActCreditRekeynumberEdit;
      FInputs[6] := ActCreditRekeyEdit;
      FInputs[7] := ActCreditAccessBox;
      FInputs[8] := ActCreditFinishBox;
      FInputs[9] := ActCreditFileEdit;
      FInputs[10] := ActCreditAmountEdit;
    end;
    9:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActDebitAidEdit;
      FInputs[1] := ActDebitSecurityBox;
      FInputs[2] := ActDebitMinimumBox;
      FInputs[3] := ActDebitKeynumberEdit;
      FInputs[4] := ActDebitKeyEdit;
      FInputs[5] := ActDebitRekeynumberEdit;
      FInputs[6] := ActDebitRekeyEdit;
      FInputs[7] := ActDebitAccessBox;
      FInputs[8] := ActDebitFinishBox;
      FInputs[9] := ActDebitFileEdit;
      FInputs[10] := ActDebitAmountEdit;
    end;
    10:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActLimitedAidEdit;
      FInputs[1] := ActLimitedSecurityBox;
      FInputs[2] := ActLimitedMinimumBox;
      FInputs[3] := ActLimitedKeynumberEdit;
      FInputs[4] := ActLimitedKeyEdit;
      FInputs[5] := ActLimitedRekeynumberEdit;
      FInputs[6] := ActLimitedRekeyEdit;
      FInputs[7] := ActLimitedAccessBox;
      FInputs[8] := ActLimitedFinishBox;
      FInputs[9] := ActLimitedFileEdit;
      FInputs[10] := ActLimitedAmountEdit;
    end;
    11:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActAppendAidEdit;
      FInputs[1] := ActAppendSecurityBox;
      FInputs[2] := ActAppendMinimumBox;
      FInputs[3] := ActAppendKeynumberEdit;
      FInputs[4] := ActAppendKeyEdit;
      FInputs[5] := ActAppendRekeynumberEdit;
      FInputs[6] := ActAppendRekeyEdit;
      FInputs[7] := ActAppendAccessBox;
      FInputs[8] := ActAppendFinishBox;
      FInputs[9] := ActAppendFileEdit;
      FInputs[10] := ActAppendDataEdit;
    end;
    12:
    begin
      SetLength(FInputs,10);
      FInputs[0] := ActClearAidEdit;
      FInputs[1] := ActClearSecurityBox;
      FInputs[2] := ActClearMinimumBox;
      FInputs[3] := ActClearKeynumberEdit;
      FInputs[4] := ActClearKeyEdit;
      FInputs[5] := ActClearRekeynumberEdit;
      FInputs[6] := ActClearRekeyEdit;
      FInputs[7] := ActClearAccessBox;
      FInputs[8] := ActClearFinishBox;
      FInputs[9] := ActClearFileEdit;
    end;
    13:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActSettingsAidEdit;
      FInputs[1] := ActSettingsSecurityBox;
      FInputs[2] := ActSettingsMinimumBox;
      FInputs[3] := ActSettingsKeynumberEdit;
      FInputs[4] := ActSettingsKeyEdit;
      FInputs[5] := ActSettingsRekeynumberEdit;
      FInputs[6] := ActSettingsRekeyEdit;
    end;
    14:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActFreememoryAidEdit;
      FInputs[1] := ActFreememorySecurityBox;
      FInputs[2] := ActFreememoryMinimumBox;
      FInputs[3] := ActFreememoryKeynumberEdit;
      FInputs[4] := ActFreememoryKeyEdit;
      FInputs[5] := ActFreememoryRekeynumberEdit;
      FInputs[6] := ActFreememoryRekeyEdit;
    end;
    15:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActKeyversionAidEdit;
      FInputs[1] := ActKeyversionSecurityBox;
      FInputs[2] := ActKeyversionMinimumBox;
      FInputs[3] := ActKeyversionKeynumberEdit;
      FInputs[4] := ActKeyversionKeyEdit;
      FInputs[5] := ActKeyversionRekeynumberEdit;
      FInputs[6] := ActKeyversionRekeyEdit;
      FInputs[7] := ActKeyversionTargetkeyEdit;
    end;
    16:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActKeysettingsAidEdit;
      FInputs[1] := ActKeysettingsSecurityBox;
      FInputs[2] := ActKeysettingsMinimumBox;
      FInputs[3] := ActKeysettingsKeynumberEdit;
      FInputs[4] := ActKeysettingsKeyEdit;
      FInputs[5] := ActKeysettingsRekeynumberEdit;
      FInputs[6] := ActKeysettingsRekeyEdit;
      FInputs[7] := ActKeysettingsSettingsEdit;
    end;
    17:
    begin
      SetLength(FInputs,13);
      FInputs[0] := ActFileaccessAidEdit;
      FInputs[1] := ActFileaccessSecurityBox;
      FInputs[2] := ActFileaccessMinimumBox;
      FInputs[3] := ActFileaccessKeynumberEdit;
      FInputs[4] := ActFileaccessKeyEdit;
      FInputs[5] := ActFileaccessRekeynumberEdit;
      FInputs[6] := ActFileaccessRekeyEdit;
      FInputs[7] := ActFileaccessFileEdit;
      FInputs[8] := ActFileaccessCommunicationBox;
      FInputs[9] := ActFileaccessReadkeyEdit;
      FInputs[10] := ActFileaccessWritekeyEdit;
      FInputs[11] := ActFileaccessReadwritekeyEdit;
      FInputs[12] := ActFileaccessChangekeyEdit;
    end;
    18:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActChangekeyAidEdit;
      FInputs[1] := ActChangekeySecurityBox;
      FInputs[2] := ActChangekeyMinimumBox;
      FInputs[3] := ActChangekeyKeynumberEdit;
      FInputs[4] := ActChangekeyKeyEdit;
      FInputs[5] := ActChangekeyRekeynumberEdit;
      FInputs[6] := ActChangekeyRekeyEdit;
      FInputs[7] := ActChangekeyTargetkeyEdit;
      FInputs[8] := ActChangekeyKeyversionEdit;
      FInputs[9] := ActChangekeyNewkeyEdit;
      FInputs[10] := ActChangekeyOldkeyEdit;
    end;
    19:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActCreateappAidEdit;
      FInputs[1] := ActCreateappSecurityBox;
      FInputs[2] := ActCreateappMinimumBox;
      FInputs[3] := ActCreateappKeynumberEdit;
      FInputs[4] := ActCreateappKeyEdit;
      FInputs[5] := ActCreateappRekeynumberEdit;
      FInputs[6] := ActCreateappRekeyEdit;
      FInputs[7] := ActCreateappTargetaidEdit;
      FInputs[8] := ActCreateappSettingsEdit;
      FInputs[9] := ActCreateappKeycountEdit;
      FInputs[10] := ActCreateappKeytypeBox;
    end;
    20:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActDeleteappAidEdit;
      FInputs[1] := ActDeleteappSecurityBox;
      FInputs[2] := ActDeleteappMinimumBox;
      FInputs[3] := ActDeleteappKeynumberEdit;
      FInputs[4] := ActDeleteappKeyEdit;
      FInputs[5] := ActDeleteappRekeynumberEdit;
      FInputs[6] := ActDeleteappRekeyEdit;
      FInputs[7] := ActDeleteappTargetaidEdit;
    end;
    21:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActDeletefileAidEdit;
      FInputs[1] := ActDeletefileSecurityBox;
      FInputs[2] := ActDeletefileMinimumBox;
      FInputs[3] := ActDeletefileKeynumberEdit;
      FInputs[4] := ActDeletefileKeyEdit;
      FInputs[5] := ActDeletefileRekeynumberEdit;
      FInputs[6] := ActDeletefileRekeyEdit;
      FInputs[7] := ActDeletefileFileEdit;
    end;
    22:
    begin
      SetLength(FInputs,21);
      FInputs[0] := ActCreatefileAidEdit;
      FInputs[1] := ActCreatefileSecurityBox;
      FInputs[2] := ActCreatefileMinimumBox;
      FInputs[3] := ActCreatefileKeynumberEdit;
      FInputs[4] := ActCreatefileKeyEdit;
      FInputs[5] := ActCreatefileRekeynumberEdit;
      FInputs[6] := ActCreatefileRekeyEdit;
      FInputs[7] := ActCreatefileFileEdit;
      FInputs[8] := ActCreatefileTypeBox;
      FInputs[9] := ActCreatefileCommunicationBox;
      FInputs[10] := ActCreatefileReadkeyEdit;
      FInputs[11] := ActCreatefileWritekeyEdit;
      FInputs[12] := ActCreatefileReadwritekeyEdit;
      FInputs[13] := ActCreatefileChangekeyEdit;
      FInputs[14] := ActCreatefileFilebytesEdit;
      FInputs[15] := ActCreatefileLowerEdit;
      FInputs[16] := ActCreatefileUpperEdit;
      FInputs[17] := ActCreatefileInitialEdit;
      FInputs[18] := ActCreatefileLimitedBox;
      FInputs[19] := ActCreatefileRecordbytesEdit;
      FInputs[20] := ActCreatefileMaxrecordsEdit;
    end;
    23:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActDecodeFileEdit;
      FInputs[1] := ActDecodeHexEdit;
    end;
    24:
    begin
      SetLength(FInputs,12);
      FInputs[0] := ActChangedeskeyAidEdit;
      FInputs[1] := ActChangedeskeySecurityBox;
      FInputs[2] := ActChangedeskeyMinimumBox;
      FInputs[3] := ActChangedeskeyKeynumberEdit;
      FInputs[4] := ActChangedeskeyKeyEdit;
      FInputs[5] := ActChangedeskeyRekeynumberEdit;
      FInputs[6] := ActChangedeskeyRekeyEdit;
      FInputs[7] := ActChangedeskeyTargetkeyEdit;
      FInputs[8] := ActChangedeskeyKeyversionEdit;
      FInputs[9] := ActChangedeskeyNewkeyEdit;
      FInputs[10] := ActChangedeskeyOldkeyEdit;
      FInputs[11] := ActChangedeskeyOldversionEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TDesfireDemoForm.ClearCredentials;
begin
  ActChangedeskeyKeyEdit.Clear;
  ActChangedeskeyRekeyEdit.Clear;
  ActChangedeskeyNewkeyEdit.Clear;
  ActChangedeskeyOldkeyEdit.Clear;
  ActFilesKeyEdit.Clear;
  ActFilesRekeyEdit.Clear;
  ActReadKeyEdit.Clear;
  ActReadRekeyEdit.Clear;
  ActValueKeyEdit.Clear;
  ActValueRekeyEdit.Clear;
  ActRecordsKeyEdit.Clear;
  ActRecordsRekeyEdit.Clear;
  ActWriteKeyEdit.Clear;
  ActWriteRekeyEdit.Clear;
  ActBackupKeyEdit.Clear;
  ActBackupRekeyEdit.Clear;
  ActCreditKeyEdit.Clear;
  ActCreditRekeyEdit.Clear;
  ActDebitKeyEdit.Clear;
  ActDebitRekeyEdit.Clear;
  ActLimitedKeyEdit.Clear;
  ActLimitedRekeyEdit.Clear;
  ActAppendKeyEdit.Clear;
  ActAppendRekeyEdit.Clear;
  ActClearKeyEdit.Clear;
  ActClearRekeyEdit.Clear;
  ActSettingsKeyEdit.Clear;
  ActSettingsRekeyEdit.Clear;
  ActFreememoryKeyEdit.Clear;
  ActFreememoryRekeyEdit.Clear;
  ActKeyversionKeyEdit.Clear;
  ActKeyversionRekeyEdit.Clear;
  ActKeysettingsKeyEdit.Clear;
  ActKeysettingsRekeyEdit.Clear;
  ActFileaccessKeyEdit.Clear;
  ActFileaccessRekeyEdit.Clear;
  ActChangekeyKeyEdit.Clear;
  ActChangekeyRekeyEdit.Clear;
  ActChangekeyNewkeyEdit.Clear;
  ActChangekeyOldkeyEdit.Clear;
  ActCreateappKeyEdit.Clear;
  ActCreateappRekeyEdit.Clear;
  ActDeleteappKeyEdit.Clear;
  ActDeleteappRekeyEdit.Clear;
  ActDeletefileKeyEdit.Clear;
  ActDeletefileRekeyEdit.Clear;
  ActCreatefileKeyEdit.Clear;
  ActCreatefileRekeyEdit.Clear;
end;

function TDesfireDemoForm.Request: TCardDemoRequest;
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

procedure TDesfireDemoForm.RunClick(Sender: TObject);
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

procedure TDesfireDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TDesfireDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TDesfireDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TDesfireDemoForm.SetBusy(const AValue: Boolean);
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

procedure TDesfireDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TDesfireDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TDesfireDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TDesfireDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TDesfireDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TDesfireDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TDesfireDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TDesfireDemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TDesfireDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TDesfireDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TDesfireDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TDesfireDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
