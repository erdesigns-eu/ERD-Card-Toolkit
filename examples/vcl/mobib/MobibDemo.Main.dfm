object MobibDemoForm: TMobibDemoForm
  Left = 0
  Top = 0
  Caption = 'MobibDemo'
  ClientHeight = 900
  ClientWidth = 1080
  Color = clBtnFace
  Constraints.MinHeight = 650
  Constraints.MinWidth = 1000
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
    Height = 118
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      1080
      118)
    object GuidanceLabel: TLabel
      Left = 16
      Top = 8
      Width = 393
      Height = 13
      Caption = 
        'Select the reader and action here; discovery does not connect or' +
        ' program a card.'
    end
    object ReaderLabel: TLabel
      Left = 16
      Top = 32
      Width = 144
      Height = 13
      Caption = 'Available PC/SC card readers:'
    end
    object EventStatusLabel: TLabel
      Left = 16
      Top = 88
      Width = 1040
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Reader events inactive.'
    end
    object ReaderBox: TComboBox
      Left = 16
      Top = 54
      Width = 880
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      ParentShowHint = False
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
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 580
    Width = 1080
    Height = 320
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      1080
      320)
    object PhotoImage: TImage
      Left = 800
      Top = 86
      Width = 256
      Height = 218
      Anchors = [akTop, akRight, akBottom]
      Proportional = True
      Stretch = True
      Visible = False
    end
    object AcknowledgeCheck: TCheckBox
      Left = 16
      Top = 8
      Width = 1020
      Height = 20
      Caption = 
        'I authorize this exact operation, including supplied-code attemp' +
        'ts or permanent changes.'
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
      Enabled = False
      TabOrder = 2
      Visible = False
      WantTabs = True
      OnKeyPress = CaptureKey
    end
    object ArtifactBox: TComboBox
      Left = 216
      Top = 36
      Width = 660
      Height = 21
      Style = csDropDownList
      TabOrder = 3
      OnChange = PreviewArtifact
    end
    object SaveButton: TButton
      Left = 892
      Top = 36
      Width = 164
      Height = 30
      Caption = 'Save selected file'
      Enabled = False
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
      TabOrder = 5
      WordWrap = False
    end
  end
  object ActionPages: TPageControl
    Left = 0
    Top = 118
    Width = 1080
    Height = 462
    ActivePage = ActSnapshotTab
    Align = alClient
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActSnapshotTab: TTabSheet
      Caption = 'Read public MOBIB files and records'
      object ActSnapshotInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 434
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        DesignSize = (
          1072
          434)
        object ActSnapshotDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 108
          Height = 13
          Caption = 'Explicit Calypso dialect'
        end
        object ActSnapshotLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 138
          Height = 13
          Caption = 'Initial expected record bytes'
        end
        object ActSnapshotLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 119
          Height = 13
          Caption = 'Maximum records per file'
        end
        object ActSnapshotLayoutLabel: TLabel
          Left = 16
          Top = 194
          Width = 126
          Height = 13
          Caption = 'Explicit MOBIB data layout'
        end
        object ActSnapshotFilesLabel: TLabel
          Left = 16
          Top = 256
          Width = 382
          Height = 13
          Caption = 
            'Logical file IDs (hex), semicolon-separated; edit to include add' +
            'itional known files'
        end
        object ActSnapshotRawLabel: TLabel
          Left = 16
          Top = 318
          Width = 203
          Height = 13
          Caption = 'Include raw hexadecimal records in output'
        end
        object ActSnapshotDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09')
        end
        object ActSnapshotLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 1
          Text = '48'
        end
        object ActSnapshotLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 2
          Text = '16'
        end
        object ActSnapshotLayoutBox: TComboBox
          Left = 16
          Top = 216
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          Items.Strings = (
            'Raw bytes only'
            'Legacy MOBIB 056/001')
        end
        object ActSnapshotFilesEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 4
          Text = 
            '2001;2002;2010;2020;2069;2050;2040;3F1C;2030;202A;202B;202C;202D' +
            ';2004;2060;2062;206A;20F0'
        end
        object ActSnapshotRawBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          ItemIndex = 0
          TabOrder = 5
          Text = 'Summary only'
          Items.Strings = (
            'Summary only'
            'Summary and raw records')
        end
      end
    end
    object ActFileTab: TTabSheet
      Tag = 1
      Caption = 'Read explicit Calypso logical file'
      object ActFileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 434
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        DesignSize = (
          1072
          434)
        object ActFileDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 108
          Height = 13
          Caption = 'Explicit Calypso dialect'
        end
        object ActFileLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 138
          Height = 13
          Caption = 'Initial expected record bytes'
        end
        object ActFileLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 119
          Height = 13
          Caption = 'Maximum records per file'
        end
        object ActFileFidLabel: TLabel
          Left = 16
          Top = 194
          Width = 123
          Height = 13
          Caption = 'Logical file identifier (hex)'
        end
        object ActFileDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09')
        end
        object ActFileLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 1
          Text = '29'
        end
        object ActFileLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 2
          Text = '16'
        end
        object ActFileFidEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 3
          Text = '2001'
        end
      end
    end
    object ActSamfileTab: TTabSheet
      Tag = 2
      Caption = 'Authenticated Calypso file via provisioned SAM'
      object ActSamfileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 434
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        DesignSize = (
          1055
          434)
        object ActSamfileDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 108
          Height = 13
          Caption = 'Explicit Calypso dialect'
        end
        object ActSamfileLeLabel: TLabel
          Left = 16
          Top = 70
          Width = 215
          Height = 13
          Caption = 'Exact expected record bytes (maximum 253)'
        end
        object ActSamfileLimitLabel: TLabel
          Left = 16
          Top = 132
          Width = 221
          Height = 13
          Caption = 'Exact record count; no missing-record probing'
        end
        object ActSamfileFidLabel: TLabel
          Left = 16
          Top = 194
          Width = 155
          Height = 13
          Caption = 'Known logical file identifier (hex)'
        end
        object ActSamfileSamreaderLabel: TLabel
          Left = 16
          Top = 256
          Width = 181
          Height = 13
          Caption = 'Separate available PC/SC SAM reader'
        end
        object ActSamfileRevisionLabel: TLabel
          Left = 16
          Top = 318
          Width = 147
          Height = 13
          Caption = 'Explicit secure-session revision'
        end
        object ActSamfileSerialLabel: TLabel
          Left = 16
          Top = 380
          Width = 212
          Height = 13
          Caption = 'Exact eight-byte card serial/diversifier (hex)'
        end
        object ActSamfileKeyindexLabel: TLabel
          Left = 16
          Top = 442
          Width = 125
          Height = 13
          Caption = 'Authorized card key index'
        end
        object ActSamfileKifLabel: TLabel
          Left = 16
          Top = 504
          Width = 187
          Height = 13
          Caption = 'Authorized SAM key identifier (decimal)'
        end
        object ActSamfileKvcLabel: TLabel
          Left = 16
          Top = 566
          Width = 156
          Height = 13
          Caption = 'Authorized key version (decimal)'
        end
        object ActSamfileSamclassLabel: TLabel
          Left = 16
          Top = 628
          Width = 77
          Height = 13
          Caption = 'SAM APDU class'
        end
        object ActSamfileDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Items.Strings = (
            'Legacy CLA 94 / LFI 00'
            'Revision 3 CLA 00 / path 09')
        end
        object ActSamfileLeEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 1
          Text = '29'
        end
        object ActSamfileLimitEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 2
          Text = '1'
        end
        object ActSamfileFidEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 3
          Text = '2020'
        end
        object ActSamfileSamreaderEdit: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 4
        end
        object ActSamfileRevisionBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Items.Strings = (
            'Revision 1'
            'Revision 2'
            'Revision 3 compatibility'
            'Revision 3.2 extended plaintext')
        end
        object ActSamfileSerialEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 6
        end
        object ActSamfileKeyindexEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 7
          Text = '1'
        end
        object ActSamfileKifEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 8
        end
        object ActSamfileKvcEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 9
        end
        object ActSamfileSamclassBox: TComboBox
          Left = 16
          Top = 650
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          Items.Strings = (
            '80'
            '94')
        end
      end
    end
    object ActRulesTab: TTabSheet
      Tag = 3
      Caption = 
        'Offline activation / validity / zone assessment with explicit po' +
        'licy'
      object ActRulesInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 434
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        DesignSize = (
          1055
          434)
        object ActRulesContractLabel: TLabel
          Left = 16
          Top = 8
          Width = 186
          Height = 13
          Caption = 'Complete MOBIB contract record (hex)'
        end
        object ActRulesRecordLabel: TLabel
          Left = 16
          Top = 70
          Width = 158
          Height = 13
          Caption = 'Absolute contract record number'
        end
        object ActRulesTariffLabel: TLabel
          Left = 16
          Top = 132
          Width = 109
          Height = 13
          Caption = 'Policy tariff code (hex)'
        end
        object ActRulesOperatorLabel: TLabel
          Left = 16
          Top = 194
          Width = 123
          Height = 13
          Caption = 'Explicit operator identifier'
        end
        object ActRulesSourceLabel: TLabel
          Left = 16
          Top = 256
          Width = 355
          Height = 13
          Caption = 
            'Rule source/specification revision (manual profile; no installed' +
            ' issuer rules)'
        end
        object ActRulesClockLabel: TLabel
          Left = 16
          Top = 318
          Width = 78
          Height = 13
          Caption = 'Timestamp basis'
        end
        object ActRulesNowLabel: TLabel
          Left = 16
          Top = 380
          Width = 220
          Height = 13
          Caption = 'Evaluation timestamp: YYYY-MM-DD hh:mm:ss'
        end
        object ActRulesActivationLabel: TLabel
          Left = 16
          Top = 442
          Width = 126
          Height = 13
          Caption = 'Policy validity-start source'
        end
        object ActRulesStateLabel: TLabel
          Left = 16
          Top = 504
          Width = 120
          Height = 13
          Caption = 'Acquired activation state'
        end
        object ActRulesAnchorLabel: TLabel
          Left = 16
          Top = 566
          Width = 304
          Height = 13
          Caption = 'Acquired start/activation/first-use timestamp; blank = unknown'
        end
        object ActRulesEndLabel: TLabel
          Left = 16
          Top = 628
          Width = 251
          Height = 13
          Caption = 'Acquired exclusive end timestamp; blank = unknown'
        end
        object ActRulesDurationLabel: TLabel
          Left = 16
          Top = 690
          Width = 70
          Height = 13
          Caption = 'Policy duration'
        end
        object ActRulesAmountLabel: TLabel
          Left = 16
          Top = 752
          Width = 240
          Height = 13
          Caption = 'Fixed duration amount; zero for explicit-end mode'
        end
        object ActRulesMidnightLabel: TLabel
          Left = 16
          Top = 814
          Width = 231
          Height = 13
          Caption = 'Calendar end calculated from start-day midnight'
        end
        object ActRulesZonesLabel: TLabel
          Left = 16
          Top = 876
          Width = 358
          Height = 13
          Caption = 
            'Allowed zones: semicolon IDs; * = explicitly unrestricted; blank' +
            ' = unknown'
        end
        object ActRulesJourneyzonesLabel: TLabel
          Left = 16
          Top = 938
          Width = 258
          Height = 13
          Caption = 'All requested journey zone IDs (semicolon-separated)'
        end
        object ActRulesRequiretripsLabel: TLabel
          Left = 16
          Top = 1000
          Width = 176
          Height = 13
          Caption = 'New journey requires remaining trips'
        end
        object ActRulesTripsLabel: TLabel
          Left = 16
          Top = 1062
          Width = 244
          Height = 13
          Caption = 'Acquired associated trip counter; blank = unknown'
        end
        object ActRulesContractEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 0
        end
        object ActRulesRecordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 1
          Text = '1'
        end
        object ActRulesTariffEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 2
        end
        object ActRulesOperatorEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 3
        end
        object ActRulesSourceEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 4
        end
        object ActRulesClockBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Items.Strings = (
            'UTC elapsed time'
            'Operator-local calendar time')
        end
        object ActRulesNowEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 6
        end
        object ActRulesActivationBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Items.Strings = (
            'Explicit contract start'
            'Known activation'
            'Contract first validation'
            'Sale date by explicit policy')
        end
        object ActRulesStateBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Items.Strings = (
            'Unknown'
            'Explicitly not activated'
            'Activated')
        end
        object ActRulesAnchorEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 9
        end
        object ActRulesEndEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 10
        end
        object ActRulesDurationBox: TComboBox
          Left = 16
          Top = 712
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          Items.Strings = (
            'Explicit end'
            'UTC minutes'
            'UTC hours'
            'Calendar days'
            'Calendar months'
            'Calendar years')
        end
        object ActRulesAmountEdit: TEdit
          Left = 16
          Top = 774
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 12
          Text = '0'
        end
        object ActRulesMidnightBox: TComboBox
          Left = 16
          Top = 836
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 13
          Items.Strings = (
            'No'
            'Yes')
        end
        object ActRulesZonesEdit: TEdit
          Left = 16
          Top = 898
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 14
        end
        object ActRulesJourneyzonesEdit: TEdit
          Left = 16
          Top = 960
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 15
        end
        object ActRulesRequiretripsBox: TComboBox
          Left = 16
          Top = 1022
          Width = 940
          Height = 21
          Style = csDropDownList
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 16
          Items.Strings = (
            'Yes'
            'No')
        end
        object ActRulesTripsEdit: TEdit
          Left = 16
          Top = 1084
          Width = 940
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          MaxLength = 262144
          TabOrder = 17
        end
      end
    end
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
