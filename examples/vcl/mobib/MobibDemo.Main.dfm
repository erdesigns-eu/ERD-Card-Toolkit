object MobibDemoForm: TMobibDemoForm
  Caption = 'MobibDemo'
  ClientHeight = 900
  ClientWidth = 1080
  Constraints.MinHeight = 650
  Constraints.MinWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 13
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 1080
    Align = alTop
    Height = 118
    BevelOuter = bvNone
    TabOrder = 0
    object GuidanceLabel: TLabel
      Left = 16
      Top = 8
      Width = 1040
      Height = 18
      Caption = 'Select the reader and action here; discovery does not connect or program a card.'
    end
    object ReaderLabel: TLabel
      Left = 16
      Top = 32
      Width = 850
      Height = 18
      Caption = 'Available PC/SC card readers:'
    end
    object ReaderBox: TComboBox
      Left = 16
      Top = 54
      Width = 880
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Style = csDropDownList
      ShowHint = True
      TabOrder = 0
      OnChange = ReaderChanged
    end
    object RefreshReadersButton: TButton
      Left = 912
      Top = 52
      Width = 144
      Height = 29
      Anchors = [akTop, akRight]
      Caption = 'Refresh devices'
      TabOrder = 1
      OnClick = RefreshReadersClick
    end
    object EventStatusLabel: TLabel
      Left = 16
      Top = 88
      Width = 1040
      Height = 22
      AutoSize = False
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Reader events inactive.'
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 580
    Width = 1080
    Align = alBottom
    Height = 320
    BevelOuter = bvNone
    TabOrder = 2
    object AcknowledgeCheck: TCheckBox
      Left = 16
      Top = 8
      Width = 1020
      Height = 20
      Caption = 'I authorize this exact operation, including supplied-code attempts or permanent changes.'
      TabOrder = 0
    end
    object RunButton: TButton
      Left = 16
      Top = 36
      Width = 184
      Height = 30
      Caption = 'Run selected action'
      TabOrder = 1
      OnClick = RunClick
    end
    object CaptureInputMemo: TMemo
      Left = 216
      Top = 36
      Width = 840
      Height = 36
      Visible = False
      Enabled = False
      WantTabs = True
      WantReturns = True
      TabOrder = 2
      OnKeyPress = CaptureKey
    end
    object ArtifactBox: TComboBox
      Left = 216
      Top = 36
      Width = 660
      Height = 25
      Visible = True
      Style = csDropDownList
      TabOrder = 3
      OnChange = PreviewArtifact
    end
    object SaveButton: TButton
      Left = 892
      Top = 36
      Width = 164
      Height = 30
      Visible = True
      Enabled = False
      Caption = 'Save selected file'
      TabOrder = 4
      OnClick = SaveArtifact
    end
    object OutputMemo: TMemo
      Left = 16
      Top = 86
      Width = 1040
      Height = 218
      Anchors = [akLeft, akTop, akRight, akBottom]
      ReadOnly = True
      ScrollBars = ssBoth
      WordWrap = False
      TabOrder = 5
    end
    object PhotoImage: TImage
      Left = 800
      Top = 86
      Width = 256
      Height = 218
      Anchors = [akTop, akRight, akBottom]
      Visible = False
      Stretch = True
      Proportional = True
    end
  end
  object ActionPages: TPageControl
    Left = 0
    Top = 94
    Width = 1080
    Height = 486
    Align = alClient
    ActivePage = ActSnapshotTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActSnapshotTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read public MOBIB files and records'
      Tag = 0
      object ActSnapshotInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSnapshotDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit Calypso dialect'
        end
        object ActSnapshotDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09'
          )
        end
        object ActSnapshotLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Initial expected record bytes'
        end
        object ActSnapshotLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '29'
        end
        object ActSnapshotLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Maximum records per file'
        end
        object ActSnapshotLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '16'
        end
        object ActSnapshotLayoutLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Explicit MOBIB data layout'
        end
        object ActSnapshotLayoutBox: TComboBox
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Raw bytes only'
            'Legacy MOBIB 056/001'
          )
        end
        object ActSnapshotFilesLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Logical file IDs (hex), semicolon-separated; edit to include additional known files'
        end
        object ActSnapshotFilesEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '2001;2002;2010;2020;2069;2050;2040;3F1C'
        end
        object ActSnapshotRawLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Include raw hexadecimal records in output'
        end
        object ActSnapshotRawBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 23
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = 0
          Text = 'Summary only'
          Items.Strings = (
            'Summary only'
            'Summary and raw records')
        end
        object ActSnapshotCatalogLabel: TLabel
          Left = 16
          Top = 386
          Width = 740
          Height = 17
          Caption = 'Optional sourced P/L/R mappings (pipe-separated, one per line)'
        end
        object ActSnapshotCatalogMemo: TMemo
          Left = 16
          Top = 408
          Width = 940
          Height = 120
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssBoth
          WordWrap = False
          MaxLength = 262144
          TabOrder = 6
        end
      end
    end
    object ActFileTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read explicit Calypso logical file'
      Tag = 1
      object ActFileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActFileDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit Calypso dialect'
        end
        object ActFileDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09'
          )
        end
        object ActFileLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Initial expected record bytes'
        end
        object ActFileLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '29'
        end
        object ActFileLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Maximum records per file'
        end
        object ActFileLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '16'
        end
        object ActFileFidLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Logical file identifier (hex)'
        end
        object ActFileFidEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '2001'
        end
      end
    end
    object ActSamfileTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticated Calypso file via provisioned SAM'
      Tag = 2
      object ActSamfileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSamfileDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit Calypso dialect'
        end
        object ActSamfileDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09'
          )
        end
        object ActSamfileLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Exact expected record bytes (maximum 253)'
        end
        object ActSamfileLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '29'
        end
        object ActSamfileLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Exact record count; no missing-record probing'
        end
        object ActSamfileLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActSamfileFidLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Known logical file identifier (hex)'
        end
        object ActSamfileFidEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '2020'
        end
        object ActSamfileSamreaderLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Separate available PC/SC SAM reader'
        end
        object ActSamfileSamreaderEdit: TComboBox
          Style = csDropDownList
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActSamfileRevisionLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Explicit secure-session revision'
        end
        object ActSamfileRevisionBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Revision 1'
            'Revision 2'
            'Revision 3 compatibility'
            'Revision 3.2 extended plaintext'
          )
        end
        object ActSamfileSerialLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Exact eight-byte card serial/diversifier (hex)'
        end
        object ActSamfileSerialEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
        end
        object ActSamfileKeyindexLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Authorized card key index'
        end
        object ActSamfileKeyindexEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '1'
        end
        object ActSamfileKifLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Authorized SAM key identifier (decimal)'
        end
        object ActSamfileKifEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActSamfileKvcLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Authorized key version (decimal)'
        end
        object ActSamfileKvcEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
        object ActSamfileSamclassLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'SAM APDU class'
        end
        object ActSamfileSamclassBox: TComboBox
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            '80'
            '94'
          )
        end
      end
    end
    object ActRulesTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline activation / validity / zone assessment with explicit policy'
      Tag = 3
      object ActRulesInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActRulesContractLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Complete MOBIB contract record (hex)'
        end
        object ActRulesContractEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
        end
        object ActRulesRecordLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Absolute contract record number'
        end
        object ActRulesRecordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '1'
        end
        object ActRulesTariffLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Policy tariff code (hex)'
        end
        object ActRulesTariffEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
        end
        object ActRulesOperatorLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Explicit operator identifier'
        end
        object ActRulesOperatorEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActRulesSourceLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Rule source/specification revision (manual profile; no installed issuer rules)'
        end
        object ActRulesSourceEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActRulesClockLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Timestamp basis'
        end
        object ActRulesClockBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'UTC elapsed time'
            'Operator-local calendar time'
          )
        end
        object ActRulesNowLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Evaluation timestamp: YYYY-MM-DD hh:mm:ss'
        end
        object ActRulesNowEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
        end
        object ActRulesActivationLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Policy validity-start source'
        end
        object ActRulesActivationBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Explicit contract start'
            'Known activation'
            'Contract first validation'
            'Sale date by explicit policy'
          )
        end
        object ActRulesStateLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Acquired activation state'
        end
        object ActRulesStateBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Unknown'
            'Explicitly not activated'
            'Activated'
          )
        end
        object ActRulesAnchorLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Acquired start/activation/first-use timestamp; blank = unknown'
        end
        object ActRulesAnchorEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
        object ActRulesEndLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Acquired exclusive end timestamp; blank = unknown'
        end
        object ActRulesEndEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
        object ActRulesDurationLabel: TLabel
          Left = 16
          Top = 690
          Width = 940
          Height = 18
          Caption = 'Policy duration'
        end
        object ActRulesDurationBox: TComboBox
          Left = 16
          Top = 712
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Explicit end'
            'UTC minutes'
            'UTC hours'
            'Calendar days'
            'Calendar months'
            'Calendar years'
          )
        end
        object ActRulesAmountLabel: TLabel
          Left = 16
          Top = 752
          Width = 940
          Height = 18
          Caption = 'Fixed duration amount; zero for explicit-end mode'
        end
        object ActRulesAmountEdit: TEdit
          Left = 16
          Top = 774
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 12
          MaxLength = 262144
          Text = '0'
        end
        object ActRulesMidnightLabel: TLabel
          Left = 16
          Top = 814
          Width = 940
          Height = 18
          Caption = 'Calendar end calculated from start-day midnight'
        end
        object ActRulesMidnightBox: TComboBox
          Left = 16
          Top = 836
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 13
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'No'
            'Yes'
          )
        end
        object ActRulesZonesLabel: TLabel
          Left = 16
          Top = 876
          Width = 940
          Height = 18
          Caption = 'Allowed zones: semicolon IDs; * = explicitly unrestricted; blank = unknown'
        end
        object ActRulesZonesEdit: TEdit
          Left = 16
          Top = 898
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 14
          MaxLength = 262144
        end
        object ActRulesJourneyzonesLabel: TLabel
          Left = 16
          Top = 938
          Width = 940
          Height = 18
          Caption = 'All requested journey zone IDs (semicolon-separated)'
        end
        object ActRulesJourneyzonesEdit: TEdit
          Left = 16
          Top = 960
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 15
          MaxLength = 262144
        end
        object ActRulesRequiretripsLabel: TLabel
          Left = 16
          Top = 1000
          Width = 940
          Height = 18
          Caption = 'New journey requires remaining trips'
        end
        object ActRulesRequiretripsBox: TComboBox
          Left = 16
          Top = 1022
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 16
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Yes'
            'No'
          )
        end
        object ActRulesTripsLabel: TLabel
          Left = 16
          Top = 1062
          Width = 940
          Height = 18
          Caption = 'Acquired associated trip counter; blank = unknown'
        end
        object ActRulesTripsEdit: TEdit
          Left = 16
          Top = 1084
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 17
          MaxLength = 262144
        end
      end
    end
    object ActOfflineTab: TTabSheet
      Caption = 'Analyse saved MOBIB snapshot'
      ImageIndex = 4
      object ActOfflineInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1064
        Height = 404
        Align = alClient
        TabOrder = 0
        object ActOfflineArchiveLabel: TLabel
          Left = 16
          Top = 16
          Width = 740
          Height = 17
          Caption = 'MOBIB-RECORDS 1 snapshot text (paste or load snapshot.mobib)'
        end
        object ActOfflineArchiveMemo: TMemo
          Left = 16
          Top = 42
          Width = 940
          Height = 160
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssBoth
          WordWrap = False
          MaxLength = 262144
          TabOrder = 0
        end
        object ActOfflineLoadButton: TButton
          Left = 16
          Top = 212
          Width = 160
          Height = 30
          Caption = 'Load snapshot...'
          TabOrder = 1
          OnClick = LoadSnapshotClick
        end
        object ActOfflineLayoutLabel: TLabel
          Left = 16
          Top = 254
          Width = 740
          Height = 17
          Caption = 'Explicit offline layout'
        end
        object ActOfflineLayoutBox: TComboBox
          Left = 16
          Top = 276
          Width = 940
          Height = 25
          Style = csDropDownList
          ItemIndex = 1
          Text = 'Legacy MOBIB 056/001'
          TabOrder = 2
          Items.Strings = (
            'Raw bytes only'
            'Legacy MOBIB 056/001')
        end
        object ActOfflineRawLabel: TLabel
          Left = 16
          Top = 318
          Width = 740
          Height = 17
          Caption = 'Raw record display'
        end
        object ActOfflineRawBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Style = csDropDownList
          ItemIndex = 0
          Text = 'Summary only'
          TabOrder = 3
          Items.Strings = (
            'Summary only'
            'Summary and raw records')
        end
        object ActOfflineCatalogLabel: TLabel
          Left = 16
          Top = 386
          Width = 740
          Height = 17
          Caption = 'Optional sourced P/L/R mappings (pipe-separated, one per line)'
        end
        object ActOfflineCatalogMemo: TMemo
          Left = 16
          Top = 408
          Width = 940
          Height = 120
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssBoth
          WordWrap = False
          MaxLength = 262144
          TabOrder = 4
        end
      end
    end
  end
  object ImportDialog: TOpenDialog
    Filter = 'MOBIB snapshots (*.mobib)|*.mobib|All files (*.*)|*.*'
    Options = [ofFileMustExist, ofPathMustExist]
    Left = 96
    Top = 112
  end
  object ExportDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofPathMustExist]
    Left = 16
    Top = 112
  end
  object WorkerTimer: TTimer
    Interval = 100
    OnTimer = PollTimer
    Left = 56
    Top = 112
  end
end
