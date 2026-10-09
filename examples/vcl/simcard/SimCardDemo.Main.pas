unit SimCardDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Imaging.jpeg,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Families, ERD.Card.RFID.Input;

type
  /// <summary>Independent SimCardDemo form; all visual controls belong to its own editable DFM.</summary>
  TSimCardDemoForm = class(TForm)
  published
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
    /// <summary>Read ICCID page.</summary>
    ActIccidTab: TTabSheet;
    /// <summary>Read ICCID inputs.</summary>
    ActIccidInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActIccidProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActIccidProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActIccidAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActIccidAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActIccidPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActIccidPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActIccidAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActIccidAttemptsEdit: TEdit;
    /// <summary>Enumerate UICC applications page.</summary>
    ActApplicationsTab: TTabSheet;
    /// <summary>Enumerate UICC applications inputs.</summary>
    ActApplicationsInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActApplicationsProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActApplicationsProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActApplicationsAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActApplicationsAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActApplicationsPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActApplicationsPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActApplicationsAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActApplicationsAttemptsEdit: TEdit;
    /// <summary>Query PIN status without attempt page.</summary>
    ActPinstatusTab: TTabSheet;
    /// <summary>Query PIN status without attempt inputs.</summary>
    ActPinstatusInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActPinstatusProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActPinstatusProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActPinstatusAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActPinstatusAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActPinstatusPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActPinstatusPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActPinstatusAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActPinstatusAttemptsEdit: TEdit;
    /// <summary>Query known PUK budget without attempt page.</summary>
    ActPukstatusTab: TTabSheet;
    /// <summary>Query known PUK budget without attempt inputs.</summary>
    ActPukstatusInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActPukstatusProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActPukstatusProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActPukstatusAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActPukstatusAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActPukstatusPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActPukstatusPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActPukstatusAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActPukstatusAttemptsEdit: TEdit;
    /// <summary>Change PIN once: command receipt page.</summary>
    ActChangepinTab: TTabSheet;
    /// <summary>Change PIN once: command receipt inputs.</summary>
    ActChangepinInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActChangepinProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActChangepinProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActChangepinAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActChangepinAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActChangepinPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActChangepinPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActChangepinAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActChangepinAttemptsEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActChangepinPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActChangepinPinEdit: TEdit;
    /// <summary>New ASCII-digit PIN bytes (hex) label.</summary>
    ActChangepinNewpinLabel: TLabel;
    /// <summary>New ASCII-digit PIN bytes (hex).</summary>
    ActChangepinNewpinEdit: TEdit;
    /// <summary>Unblock PIN once: command receipt page.</summary>
    ActUnblockpinTab: TTabSheet;
    /// <summary>Unblock PIN once: command receipt inputs.</summary>
    ActUnblockpinInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActUnblockpinProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActUnblockpinProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActUnblockpinAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActUnblockpinAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActUnblockpinPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActUnblockpinPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActUnblockpinAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActUnblockpinAttemptsEdit: TEdit;
    /// <summary>Eight supplied ASCII PUK digits (hex) label.</summary>
    ActUnblockpinPukLabel: TLabel;
    /// <summary>Eight supplied ASCII PUK digits (hex).</summary>
    ActUnblockpinPukEdit: TEdit;
    /// <summary>New ASCII-digit PIN bytes (hex) label.</summary>
    ActUnblockpinNewpinLabel: TLabel;
    /// <summary>New ASCII-digit PIN bytes (hex).</summary>
    ActUnblockpinNewpinEdit: TEdit;
    /// <summary>Explicit linked record plan + verify page.</summary>
    ActLinkedwriteTab: TTabSheet;
    /// <summary>Explicit linked record plan + verify inputs.</summary>
    ActLinkedwriteInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActLinkedwriteProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActLinkedwriteProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActLinkedwriteAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActLinkedwriteAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActLinkedwritePinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActLinkedwritePinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActLinkedwriteAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActLinkedwriteAttemptsEdit: TEdit;
    /// <summary>Ordered FIDhex:record:beforehex:datahex rows separated by semicolon label.</summary>
    ActLinkedwritePlanLabel: TLabel;
    /// <summary>Ordered FIDhex:record:beforehex:datahex rows separated by semicolon.</summary>
    ActLinkedwritePlanEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActLinkedwritePinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActLinkedwritePinEdit: TEdit;
    /// <summary>Verify supplied PIN once page.</summary>
    ActVerifyTab: TTabSheet;
    /// <summary>Verify supplied PIN once inputs.</summary>
    ActVerifyInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActVerifyProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActVerifyProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActVerifyAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActVerifyAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActVerifyPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActVerifyPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActVerifyAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActVerifyAttemptsEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActVerifyPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActVerifyPinEdit: TEdit;
    /// <summary>Read IMSI page.</summary>
    ActImsiTab: TTabSheet;
    /// <summary>Read IMSI inputs.</summary>
    ActImsiInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActImsiProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActImsiProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActImsiAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActImsiAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActImsiPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActImsiPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActImsiAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActImsiAttemptsEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActImsiPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActImsiPinEdit: TEdit;
    /// <summary>Read service provider page.</summary>
    ActSpnTab: TTabSheet;
    /// <summary>Read service provider inputs.</summary>
    ActSpnInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActSpnProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActSpnProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActSpnAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActSpnAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActSpnPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActSpnPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActSpnAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActSpnAttemptsEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActSpnPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActSpnPinEdit: TEdit;
    /// <summary>Read SST / UST service bits page.</summary>
    ActServicesTab: TTabSheet;
    /// <summary>Read SST / UST service bits inputs.</summary>
    ActServicesInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActServicesProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActServicesProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActServicesAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActServicesAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActServicesPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActServicesPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActServicesAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActServicesAttemptsEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActServicesPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActServicesPinEdit: TEdit;
    /// <summary>Inspect explicit file page.</summary>
    ActInspectTab: TTabSheet;
    /// <summary>Inspect explicit file inputs.</summary>
    ActInspectInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActInspectProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActInspectProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActInspectAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActInspectAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActInspectPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActInspectPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActInspectAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActInspectAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActInspectRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActInspectRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActInspectPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActInspectPathEdit: TEdit;
    /// <summary>Read complete transparent file page.</summary>
    ActReadTab: TTabSheet;
    /// <summary>Read complete transparent file inputs.</summary>
    ActReadInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActReadProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActReadProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActReadAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActReadAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActReadPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActReadPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActReadAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActReadAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActReadRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActReadRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActReadPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActReadPathEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActReadPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActReadPinEdit: TEdit;
    /// <summary>Read transparent range page.</summary>
    ActRangeTab: TTabSheet;
    /// <summary>Read transparent range inputs.</summary>
    ActRangeInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActRangeProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActRangeProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActRangeAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActRangeAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActRangePinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActRangePinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActRangeAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActRangeAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActRangeRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActRangeRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActRangePathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActRangePathEdit: TEdit;
    /// <summary>Start byte / page / block (decimal) label.</summary>
    ActRangeAddressLabel: TLabel;
    /// <summary>Start byte / page / block (decimal).</summary>
    ActRangeAddressEdit: TEdit;
    /// <summary>Read byte count (decimal) label.</summary>
    ActRangeCountLabel: TLabel;
    /// <summary>Read byte count (decimal).</summary>
    ActRangeCountEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActRangePinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActRangePinEdit: TEdit;
    /// <summary>Read absolute record page.</summary>
    ActRecordTab: TTabSheet;
    /// <summary>Read absolute record inputs.</summary>
    ActRecordInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActRecordProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActRecordProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActRecordAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActRecordAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActRecordPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActRecordPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActRecordAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActRecordAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActRecordRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActRecordRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActRecordPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActRecordPathEdit: TEdit;
    /// <summary>One-based record label.</summary>
    ActRecordRecordLabel: TLabel;
    /// <summary>One-based record.</summary>
    ActRecordRecordEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActRecordPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActRecordPinEdit: TEdit;
    /// <summary>Read all records page.</summary>
    ActRecordsTab: TTabSheet;
    /// <summary>Read all records inputs.</summary>
    ActRecordsInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActRecordsProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActRecordsProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActRecordsAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActRecordsAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActRecordsPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActRecordsPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActRecordsAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActRecordsAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActRecordsRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActRecordsRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActRecordsPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActRecordsPathEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActRecordsPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActRecordsPinEdit: TEdit;
    /// <summary>Read explicit ADN contacts page.</summary>
    ActContactsTab: TTabSheet;
    /// <summary>Read explicit ADN contacts inputs.</summary>
    ActContactsInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActContactsProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActContactsProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActContactsAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActContactsAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActContactsPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActContactsPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActContactsAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActContactsAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActContactsRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActContactsRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActContactsPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActContactsPathEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActContactsPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActContactsPinEdit: TEdit;
    /// <summary>Write complete transparent file + verify page.</summary>
    ActWriteTab: TTabSheet;
    /// <summary>Write complete transparent file + verify inputs.</summary>
    ActWriteInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActWriteProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActWriteProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActWriteAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActWriteAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActWritePinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActWritePinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActWriteAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActWriteAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActWriteRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActWriteRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActWritePathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActWritePathEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActWriteBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActWriteBeforeEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActWriteDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActWriteDataEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActWritePinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActWritePinEdit: TEdit;
    /// <summary>Write linear-fixed record + verify page.</summary>
    ActWriterecordTab: TTabSheet;
    /// <summary>Write linear-fixed record + verify inputs.</summary>
    ActWriterecordInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActWriterecordProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActWriterecordProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActWriterecordAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActWriterecordAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActWriterecordPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActWriterecordPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActWriterecordAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActWriterecordAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActWriterecordRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActWriterecordRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActWriterecordPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActWriterecordPathEdit: TEdit;
    /// <summary>One-based record label.</summary>
    ActWriterecordRecordLabel: TLabel;
    /// <summary>One-based record.</summary>
    ActWriterecordRecordEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActWriterecordBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActWriterecordBeforeEdit: TEdit;
    /// <summary>Replacement bytes (hex) label.</summary>
    ActWriterecordDataLabel: TLabel;
    /// <summary>Replacement bytes (hex).</summary>
    ActWriterecordDataEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActWriterecordPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActWriterecordPinEdit: TEdit;
    /// <summary>Write standalone ADN contact + verify page.</summary>
    ActContactTab: TTabSheet;
    /// <summary>Write standalone ADN contact + verify inputs.</summary>
    ActContactInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActContactProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActContactProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActContactAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActContactAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActContactPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActContactPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActContactAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActContactAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActContactRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActContactRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActContactPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActContactPathEdit: TEdit;
    /// <summary>One-based record label.</summary>
    ActContactRecordLabel: TLabel;
    /// <summary>One-based record.</summary>
    ActContactRecordEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActContactBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActContactBeforeEdit: TEdit;
    /// <summary>Contact name label.</summary>
    ActContactNameLabel: TLabel;
    /// <summary>Contact name.</summary>
    ActContactNameEdit: TEdit;
    /// <summary>Contact number label.</summary>
    ActContactNumberLabel: TLabel;
    /// <summary>Contact number.</summary>
    ActContactNumberEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActContactPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActContactPinEdit: TEdit;
    /// <summary>Read explicit USIM PBR / IAP / EXT contact page.</summary>
    ActLinkedcontactTab: TTabSheet;
    /// <summary>Read explicit USIM PBR / IAP / EXT contact inputs.</summary>
    ActLinkedcontactInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActLinkedcontactProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActLinkedcontactProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActLinkedcontactAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActLinkedcontactAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActLinkedcontactPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActLinkedcontactPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActLinkedcontactAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActLinkedcontactAttemptsEdit: TEdit;
    /// <summary>One-based PBR record label.</summary>
    ActLinkedcontactPbrrecordLabel: TLabel;
    /// <summary>One-based PBR record.</summary>
    ActLinkedcontactPbrrecordEdit: TEdit;
    /// <summary>Actual PBR-reported ADN FID (decimal) label.</summary>
    ActLinkedcontactAdnfidLabel: TLabel;
    /// <summary>Actual PBR-reported ADN FID (decimal).</summary>
    ActLinkedcontactAdnfidEdit: TEdit;
    /// <summary>One-based ADN record label.</summary>
    ActLinkedcontactRecordLabel: TLabel;
    /// <summary>One-based ADN record.</summary>
    ActLinkedcontactRecordEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActLinkedcontactPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActLinkedcontactPinEdit: TEdit;
    /// <summary>Delete standalone ADN contact + verify page.</summary>
    ActDeletecontactTab: TTabSheet;
    /// <summary>Delete standalone ADN contact + verify inputs.</summary>
    ActDeletecontactInputs: TScrollBox;
    /// <summary>Explicit SIM dialect label.</summary>
    ActDeletecontactProfileLabel: TLabel;
    /// <summary>Explicit SIM dialect.</summary>
    ActDeletecontactProfileBox: TComboBox;
    /// <summary>Complete selected USIM AID (hex) label.</summary>
    ActDeletecontactAidLabel: TLabel;
    /// <summary>Complete selected USIM AID (hex).</summary>
    ActDeletecontactAidEdit: TEdit;
    /// <summary>PIN reference (decimal) label.</summary>
    ActDeletecontactPinrefLabel: TLabel;
    /// <summary>PIN reference (decimal).</summary>
    ActDeletecontactPinrefEdit: TEdit;
    /// <summary>Minimum remaining PIN attempts label.</summary>
    ActDeletecontactAttemptsLabel: TLabel;
    /// <summary>Minimum remaining PIN attempts.</summary>
    ActDeletecontactAttemptsEdit: TEdit;
    /// <summary>Explicit file root label.</summary>
    ActDeletecontactRootLabel: TLabel;
    /// <summary>Explicit file root.</summary>
    ActDeletecontactRootBox: TComboBox;
    /// <summary>File path: slash-separated four-digit hex FIDs label.</summary>
    ActDeletecontactPathLabel: TLabel;
    /// <summary>File path: slash-separated four-digit hex FIDs.</summary>
    ActDeletecontactPathEdit: TEdit;
    /// <summary>One-based record label.</summary>
    ActDeletecontactRecordLabel: TLabel;
    /// <summary>One-based record.</summary>
    ActDeletecontactRecordEdit: TEdit;
    /// <summary>Expected current bytes (hex) label.</summary>
    ActDeletecontactBeforeLabel: TLabel;
    /// <summary>Expected current bytes (hex).</summary>
    ActDeletecontactBeforeEdit: TEdit;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex) label.</summary>
    ActDeletecontactPinLabel: TLabel;
    /// <summary>Optional supplied ASCII-digit PIN bytes (hex).</summary>
    ActDeletecontactPinEdit: TEdit;
    /// <summary>Offline SIM record / identity decoder page.</summary>
    ActDecodeTab: TTabSheet;
    /// <summary>Offline SIM record / identity decoder inputs.</summary>
    ActDecodeInputs: TScrollBox;
    /// <summary>Exact record format label.</summary>
    ActDecodeKindLabel: TLabel;
    /// <summary>Exact record format.</summary>
    ActDecodeKindBox: TComboBox;
    /// <summary>Complete raw bytes (hex) label.</summary>
    ActDecodeHexLabel: TLabel;
    /// <summary>Complete raw bytes (hex).</summary>
    ActDecodeHexEdit: TEdit;
    /// <summary>Offline complete SMS segment set page.</summary>
    ActSmsjoinTab: TTabSheet;
    /// <summary>Offline complete SMS segment set inputs.</summary>
    ActSmsjoinInputs: TScrollBox;
    /// <summary>Complete EF.SMS records (hex), separated by semicolon label.</summary>
    ActSmsjoinRecordsLabel: TLabel;
    /// <summary>Complete EF.SMS records (hex), separated by semicolon.</summary>
    ActSmsjoinRecordsEdit: TEdit;
    /// <summary>Offline EMAIL record page.</summary>
    ActEmailTab: TTabSheet;
    /// <summary>Offline EMAIL record inputs.</summary>
    ActEmailInputs: TScrollBox;
    /// <summary>Exact EMAIL bytes (hex) label.</summary>
    ActEmailHexLabel: TLabel;
    /// <summary>Exact EMAIL bytes (hex).</summary>
    ActEmailHexEdit: TEdit;
    /// <summary>Actual linkage footer label.</summary>
    ActEmailFooterLabel: TLabel;
    /// <summary>Actual linkage footer.</summary>
    ActEmailFooterBox: TComboBox;
    /// <summary>Offline ANR record page.</summary>
    ActAnrTab: TTabSheet;
    /// <summary>Offline ANR record inputs.</summary>
    ActAnrInputs: TScrollBox;
    /// <summary>Exact ANR bytes (hex) label.</summary>
    ActAnrHexLabel: TLabel;
    /// <summary>Exact ANR bytes (hex).</summary>
    ActAnrHexEdit: TEdit;
    /// <summary>Actual linkage footer label.</summary>
    ActAnrFooterLabel: TLabel;
    /// <summary>Actual linkage footer.</summary>
    ActAnrFooterBox: TComboBox;
    /// <summary>Offline GSM / UCS-2 name encoder page.</summary>
    ActEncodealphaTab: TTabSheet;
    /// <summary>Offline GSM / UCS-2 name encoder inputs.</summary>
    ActEncodealphaInputs: TScrollBox;
    /// <summary>Name label.</summary>
    ActEncodealphaNameLabel: TLabel;
    /// <summary>Name.</summary>
    ActEncodealphaNameEdit: TEdit;
    /// <summary>Exact field byte width label.</summary>
    ActEncodealphaWidthLabel: TLabel;
    /// <summary>Exact field byte width.</summary>
    ActEncodealphaWidthEdit: TEdit;
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
SimCardDemoForm: TSimCardDemoForm;

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

constructor TSimCardDemoForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFamily := dfSim; FActions := CardFamilyActions(FFamily);
  FController := TCardDemoController.Create(ddkPcsc,CreateCardFamilyOperations(FFamily),SetBusy,Complete,Close);
  FReaderEvents := TCardDemoReaderEvents.Create(ReaderInventory,ReaderStatus);
  ActionChanged(nil);
end;

destructor TSimCardDemoForm.Destroy;
begin
  if WorkerTimer <> nil then WorkerTimer.Enabled := False; StopCapture; FReaderEvents.Free; FController.Free; inherited Destroy;
end;

procedure TSimCardDemoForm.ActionChanged(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  ClearCredentials; FInputs := nil; AcknowledgeCheck.Checked := False;
  case ActionPages.ActivePageIndex of
    0:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActIccidProfileBox;
      FInputs[1] := ActIccidAidEdit;
      FInputs[2] := ActIccidPinrefEdit;
      FInputs[3] := ActIccidAttemptsEdit;
    end;
    1:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActApplicationsProfileBox;
      FInputs[1] := ActApplicationsAidEdit;
      FInputs[2] := ActApplicationsPinrefEdit;
      FInputs[3] := ActApplicationsAttemptsEdit;
    end;
    2:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActPinstatusProfileBox;
      FInputs[1] := ActPinstatusAidEdit;
      FInputs[2] := ActPinstatusPinrefEdit;
      FInputs[3] := ActPinstatusAttemptsEdit;
    end;
    3:
    begin
      SetLength(FInputs,4);
      FInputs[0] := ActPukstatusProfileBox;
      FInputs[1] := ActPukstatusAidEdit;
      FInputs[2] := ActPukstatusPinrefEdit;
      FInputs[3] := ActPukstatusAttemptsEdit;
    end;
    4:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActChangepinProfileBox;
      FInputs[1] := ActChangepinAidEdit;
      FInputs[2] := ActChangepinPinrefEdit;
      FInputs[3] := ActChangepinAttemptsEdit;
      FInputs[4] := ActChangepinPinEdit;
      FInputs[5] := ActChangepinNewpinEdit;
    end;
    5:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActUnblockpinProfileBox;
      FInputs[1] := ActUnblockpinAidEdit;
      FInputs[2] := ActUnblockpinPinrefEdit;
      FInputs[3] := ActUnblockpinAttemptsEdit;
      FInputs[4] := ActUnblockpinPukEdit;
      FInputs[5] := ActUnblockpinNewpinEdit;
    end;
    6:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActLinkedwriteProfileBox;
      FInputs[1] := ActLinkedwriteAidEdit;
      FInputs[2] := ActLinkedwritePinrefEdit;
      FInputs[3] := ActLinkedwriteAttemptsEdit;
      FInputs[4] := ActLinkedwritePlanEdit;
      FInputs[5] := ActLinkedwritePinEdit;
    end;
    7:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActVerifyProfileBox;
      FInputs[1] := ActVerifyAidEdit;
      FInputs[2] := ActVerifyPinrefEdit;
      FInputs[3] := ActVerifyAttemptsEdit;
      FInputs[4] := ActVerifyPinEdit;
    end;
    8:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActImsiProfileBox;
      FInputs[1] := ActImsiAidEdit;
      FInputs[2] := ActImsiPinrefEdit;
      FInputs[3] := ActImsiAttemptsEdit;
      FInputs[4] := ActImsiPinEdit;
    end;
    9:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActSpnProfileBox;
      FInputs[1] := ActSpnAidEdit;
      FInputs[2] := ActSpnPinrefEdit;
      FInputs[3] := ActSpnAttemptsEdit;
      FInputs[4] := ActSpnPinEdit;
    end;
    10:
    begin
      SetLength(FInputs,5);
      FInputs[0] := ActServicesProfileBox;
      FInputs[1] := ActServicesAidEdit;
      FInputs[2] := ActServicesPinrefEdit;
      FInputs[3] := ActServicesAttemptsEdit;
      FInputs[4] := ActServicesPinEdit;
    end;
    11:
    begin
      SetLength(FInputs,6);
      FInputs[0] := ActInspectProfileBox;
      FInputs[1] := ActInspectAidEdit;
      FInputs[2] := ActInspectPinrefEdit;
      FInputs[3] := ActInspectAttemptsEdit;
      FInputs[4] := ActInspectRootBox;
      FInputs[5] := ActInspectPathEdit;
    end;
    12:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActReadProfileBox;
      FInputs[1] := ActReadAidEdit;
      FInputs[2] := ActReadPinrefEdit;
      FInputs[3] := ActReadAttemptsEdit;
      FInputs[4] := ActReadRootBox;
      FInputs[5] := ActReadPathEdit;
      FInputs[6] := ActReadPinEdit;
    end;
    13:
    begin
      SetLength(FInputs,9);
      FInputs[0] := ActRangeProfileBox;
      FInputs[1] := ActRangeAidEdit;
      FInputs[2] := ActRangePinrefEdit;
      FInputs[3] := ActRangeAttemptsEdit;
      FInputs[4] := ActRangeRootBox;
      FInputs[5] := ActRangePathEdit;
      FInputs[6] := ActRangeAddressEdit;
      FInputs[7] := ActRangeCountEdit;
      FInputs[8] := ActRangePinEdit;
    end;
    14:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActRecordProfileBox;
      FInputs[1] := ActRecordAidEdit;
      FInputs[2] := ActRecordPinrefEdit;
      FInputs[3] := ActRecordAttemptsEdit;
      FInputs[4] := ActRecordRootBox;
      FInputs[5] := ActRecordPathEdit;
      FInputs[6] := ActRecordRecordEdit;
      FInputs[7] := ActRecordPinEdit;
    end;
    15:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActRecordsProfileBox;
      FInputs[1] := ActRecordsAidEdit;
      FInputs[2] := ActRecordsPinrefEdit;
      FInputs[3] := ActRecordsAttemptsEdit;
      FInputs[4] := ActRecordsRootBox;
      FInputs[5] := ActRecordsPathEdit;
      FInputs[6] := ActRecordsPinEdit;
    end;
    16:
    begin
      SetLength(FInputs,7);
      FInputs[0] := ActContactsProfileBox;
      FInputs[1] := ActContactsAidEdit;
      FInputs[2] := ActContactsPinrefEdit;
      FInputs[3] := ActContactsAttemptsEdit;
      FInputs[4] := ActContactsRootBox;
      FInputs[5] := ActContactsPathEdit;
      FInputs[6] := ActContactsPinEdit;
    end;
    17:
    begin
      SetLength(FInputs,9);
      FInputs[0] := ActWriteProfileBox;
      FInputs[1] := ActWriteAidEdit;
      FInputs[2] := ActWritePinrefEdit;
      FInputs[3] := ActWriteAttemptsEdit;
      FInputs[4] := ActWriteRootBox;
      FInputs[5] := ActWritePathEdit;
      FInputs[6] := ActWriteBeforeEdit;
      FInputs[7] := ActWriteDataEdit;
      FInputs[8] := ActWritePinEdit;
    end;
    18:
    begin
      SetLength(FInputs,10);
      FInputs[0] := ActWriterecordProfileBox;
      FInputs[1] := ActWriterecordAidEdit;
      FInputs[2] := ActWriterecordPinrefEdit;
      FInputs[3] := ActWriterecordAttemptsEdit;
      FInputs[4] := ActWriterecordRootBox;
      FInputs[5] := ActWriterecordPathEdit;
      FInputs[6] := ActWriterecordRecordEdit;
      FInputs[7] := ActWriterecordBeforeEdit;
      FInputs[8] := ActWriterecordDataEdit;
      FInputs[9] := ActWriterecordPinEdit;
    end;
    19:
    begin
      SetLength(FInputs,11);
      FInputs[0] := ActContactProfileBox;
      FInputs[1] := ActContactAidEdit;
      FInputs[2] := ActContactPinrefEdit;
      FInputs[3] := ActContactAttemptsEdit;
      FInputs[4] := ActContactRootBox;
      FInputs[5] := ActContactPathEdit;
      FInputs[6] := ActContactRecordEdit;
      FInputs[7] := ActContactBeforeEdit;
      FInputs[8] := ActContactNameEdit;
      FInputs[9] := ActContactNumberEdit;
      FInputs[10] := ActContactPinEdit;
    end;
    20:
    begin
      SetLength(FInputs,8);
      FInputs[0] := ActLinkedcontactProfileBox;
      FInputs[1] := ActLinkedcontactAidEdit;
      FInputs[2] := ActLinkedcontactPinrefEdit;
      FInputs[3] := ActLinkedcontactAttemptsEdit;
      FInputs[4] := ActLinkedcontactPbrrecordEdit;
      FInputs[5] := ActLinkedcontactAdnfidEdit;
      FInputs[6] := ActLinkedcontactRecordEdit;
      FInputs[7] := ActLinkedcontactPinEdit;
    end;
    21:
    begin
      SetLength(FInputs,9);
      FInputs[0] := ActDeletecontactProfileBox;
      FInputs[1] := ActDeletecontactAidEdit;
      FInputs[2] := ActDeletecontactPinrefEdit;
      FInputs[3] := ActDeletecontactAttemptsEdit;
      FInputs[4] := ActDeletecontactRootBox;
      FInputs[5] := ActDeletecontactPathEdit;
      FInputs[6] := ActDeletecontactRecordEdit;
      FInputs[7] := ActDeletecontactBeforeEdit;
      FInputs[8] := ActDeletecontactPinEdit;
    end;
    22:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActDecodeKindBox;
      FInputs[1] := ActDecodeHexEdit;
    end;
    23:
    begin
      SetLength(FInputs,1);
      FInputs[0] := ActSmsjoinRecordsEdit;
    end;
    24:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActEmailHexEdit;
      FInputs[1] := ActEmailFooterBox;
    end;
    25:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActAnrHexEdit;
      FInputs[1] := ActAnrFooterBox;
    end;
    26:
    begin
      SetLength(FInputs,2);
      FInputs[0] := ActEncodealphaNameEdit;
      FInputs[1] := ActEncodealphaWidthEdit;
    end;
  else Exit; end;
  AcknowledgeCheck.Enabled := FActions[ActionPages.ActivePageIndex].Mutation;
end;

procedure TSimCardDemoForm.ClearCredentials;
begin
  ActChangepinPinEdit.Clear;
  ActChangepinNewpinEdit.Clear;
  ActUnblockpinPukEdit.Clear;
  ActUnblockpinNewpinEdit.Clear;
  ActLinkedwritePinEdit.Clear;
  ActVerifyPinEdit.Clear;
  ActImsiPinEdit.Clear;
  ActSpnPinEdit.Clear;
  ActServicesPinEdit.Clear;
  ActReadPinEdit.Clear;
  ActRangePinEdit.Clear;
  ActRecordPinEdit.Clear;
  ActRecordsPinEdit.Clear;
  ActContactsPinEdit.Clear;
  ActWritePinEdit.Clear;
  ActWriterecordPinEdit.Clear;
  ActContactPinEdit.Clear;
  ActLinkedcontactPinEdit.Clear;
  ActDeletecontactPinEdit.Clear;
end;

function TSimCardDemoForm.Request: TCardDemoRequest;
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

procedure TSimCardDemoForm.RunClick(Sender: TObject);
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

procedure TSimCardDemoForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  CaptureInputMemo.Enabled := False; RunButton.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TSimCardDemoForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      OutputMemo.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TSimCardDemoForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(OutputMemo.Text) > 8192 then OutputMemo.Clear;
  OutputMemo.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

procedure TSimCardDemoForm.SetBusy(const AValue: Boolean);
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

procedure TSimCardDemoForm.Complete(const AResult: TCardDemoResult);
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

procedure TSimCardDemoForm.PreviewArtifact(Sender: TObject);
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

procedure TSimCardDemoForm.SaveArtifact(Sender: TObject);
var Stream: TFileStream; Index: Integer;
begin
  Index := ArtifactBox.ItemIndex; if FBusy or (Index < 0) or (Index >= Length(FArtifacts)) then Exit;
  ExportDialog.FileName := FArtifacts[Index].Name;
  if not ExportDialog.Execute then Exit;
  Stream := TFileStream.Create(ExportDialog.FileName,fmCreate);
  try if Length(FArtifacts[Index].Data) > 0 then Stream.WriteBuffer(FArtifacts[Index].Data[0],Length(FArtifacts[Index].Data));
  finally Stream.Free; end;
end;

function TSimCardDemoForm.SelectedAddress: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then Result := FDevices[ReaderBox.ItemIndex].Address;
end;

procedure TSimCardDemoForm.ReaderChanged(Sender: TObject);
begin ReaderBox.Hint := SelectedAddress; end;

procedure TSimCardDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TSimCardDemoForm.ReaderStatus(const AText: string);
begin EventStatusLabel.Caption := AText; end;

procedure TSimCardDemoForm.RefreshReadersClick(Sender: TObject);
begin
  if FBusy or (FCapture <> nil) then Exit;
  FPreviousAddress := SelectedAddress;
  try FReaderEvents.Start; EventStatusLabel.Caption := 'Watching reader and card events.';
  except on E: Exception do EventStatusLabel.Caption := 'Reader events could not start: '+E.ClassName+'. Use Refresh devices to retry.'; end;
end;

procedure TSimCardDemoForm.FormShow(Sender: TObject);
begin if FDiscoveryStarted then Exit; FDiscoveryStarted := True; RefreshReadersClick(nil); end;

procedure TSimCardDemoForm.PollTimer(Sender: TObject);
begin if FController <> nil then FController.Poll; end;

procedure TSimCardDemoForm.StartRequest(const ARequest: TCardDemoRequest);
begin FController.StartRequest(ARequest); end;

function TSimCardDemoForm.CloseQuery: Boolean;
begin
  StopCapture; Result := inherited CloseQuery;
  if Result and (FController <> nil) then Result := FController.CanClose;
  if not Result then Caption := 'Waiting for this demo’s card operation to finish...';
end;

end.
