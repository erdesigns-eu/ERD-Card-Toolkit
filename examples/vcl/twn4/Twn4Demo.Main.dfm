object Twn4DemoForm: TTwn4DemoForm
  Caption = 'Twn4Demo'
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
    Height = 94
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
      Caption = 'Available serial ports (select the connected reader/writer):'
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
    ActivePage = ActVersionTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActVersionTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read PRS version'
      Tag = 0
      object ActVersionInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActVersionCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActVersionCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActVersionTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActVersionTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
      end
    end
    object ActTagTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read selected tag identity'
      Tag = 1
      object ActTagInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActTagCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActTagCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActTagTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActTagTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
      end
    end
    object ActClassicreadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read authenticated Classic block'
      Tag = 2
      object ActClassicreadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActClassicreadCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActClassicreadCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActClassicreadTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActClassicreadTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
        object ActClassicreadClassicmodelLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Actual Classic model'
        end
        object ActClassicreadClassicmodelBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Mini'
            '1K'
            '4K'
          )
        end
        object ActClassicreadBlockLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Physical block (decimal)'
        end
        object ActClassicreadBlockEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActClassicreadSectorLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit TWN4 reader-sector byte (decimal)'
        end
        object ActClassicreadSectorEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActClassicreadKeytypeLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Key type'
        end
        object ActClassicreadKeytypeBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'A'
            'B'
          )
        end
        object ActClassicreadKeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Supplied six-byte key (hex)'
        end
        object ActClassicreadKeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActClassicreadIdLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Expected reader-order tag ID (hex)'
        end
        object ActClassicreadIdEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
      end
    end
    object ActClassicwriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write Classic data block + verify'
      Tag = 3
      object ActClassicwriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActClassicwriteCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActClassicwriteCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActClassicwriteTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActClassicwriteTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
        object ActClassicwriteClassicmodelLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Actual Classic model'
        end
        object ActClassicwriteClassicmodelBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Mini'
            '1K'
            '4K'
          )
        end
        object ActClassicwriteBlockLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Physical block (decimal)'
        end
        object ActClassicwriteBlockEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActClassicwriteSectorLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit TWN4 reader-sector byte (decimal)'
        end
        object ActClassicwriteSectorEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActClassicwriteKeytypeLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Key type'
        end
        object ActClassicwriteKeytypeBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'A'
            'B'
          )
        end
        object ActClassicwriteKeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Supplied six-byte key (hex)'
        end
        object ActClassicwriteKeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActClassicwriteIdLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Expected reader-order tag ID (hex)'
        end
        object ActClassicwriteIdEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActClassicwriteBeforeLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActClassicwriteBeforeEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActClassicwriteDataLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActClassicwriteDataEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
      end
    end
    object ActType2readTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read public Type 2 user page'
      Tag = 4
      object ActType2readInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActType2readCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActType2readCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActType2readTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActType2readTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
        object ActType2readType2modelLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActType2readType2modelBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActType2readPageLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Physical user page (decimal)'
        end
        object ActType2readPageEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActType2readIdLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Expected seven-byte tag ID (hex)'
        end
        object ActType2readIdEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
      end
    end
    object ActType2writeTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write public Type 2 user page + verify'
      Tag = 5
      object ActType2writeInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActType2writeCrcLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual firmware CRC mode'
        end
        object ActType2writeCrcBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Disabled'
            'Enabled'
          )
        end
        object ActType2writeTimeoutLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Shared command deadline (ms)'
        end
        object ActType2writeTimeoutEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '3000'
        end
        object ActType2writeType2modelLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActType2writeType2modelBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActType2writePageLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Physical user page (decimal)'
        end
        object ActType2writePageEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActType2writeIdLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Expected seven-byte tag ID (hex)'
        end
        object ActType2writeIdEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActType2writeBeforeLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActType2writeBeforeEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActType2writeDataLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActType2writeDataEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
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
