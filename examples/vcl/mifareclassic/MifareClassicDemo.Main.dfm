object MifareClassicDemoForm: TMifareClassicDemoForm
  Caption = 'MifareClassicDemo'
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
    ActivePage = ActUidTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActUidTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read reader-order UID'
      Tag = 0
      object ActUidInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActUidInfo: TLabel
          Left = 16
          Top = 16
          Width = 920
          Height = 40
          Caption = 'No extra parameters. Select the reader above when required, then run this action.'
          AutoSize = False
          WordWrap = True
        end
      end
    end
    object ActLayoutTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline block / trailer layout'
      Tag = 1
      object ActLayoutInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActLayoutClassicmodelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Classic model'
        end
        object ActLayoutClassicmodelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Mini'
            '1K'
            '4K'
          )
          Text = 'Mini'
        end
      end
    end
    object ActReadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate + read block'
      Tag = 2
      object ActReadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadClassicmodelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Classic model'
        end
        object ActReadClassicmodelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Mini'
            '1K'
            '4K'
          )
          Text = 'Mini'
        end
        object ActReadBlockLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical block'
        end
        object ActReadBlockEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '1'
        end
        object ActReadKeytypeLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied key type'
        end
        object ActReadKeytypeBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'A'
            'B'
          )
          Text = 'A'
        end
        object ActReadKeyLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied six-byte key (hex)'
        end
        object ActReadKeyEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActReadSlotLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Actual volatile reader key slot'
        end
        object ActReadSlotEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActWriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write data block: status receipt only'
      Tag = 3
      object ActWriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriteClassicmodelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Classic model'
        end
        object ActWriteClassicmodelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Mini'
            '1K'
            '4K'
          )
          Text = 'Mini'
        end
        object ActWriteBlockLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical block'
        end
        object ActWriteBlockEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '1'
        end
        object ActWriteKeytypeLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied key type'
        end
        object ActWriteKeytypeBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'A'
            'B'
          )
          Text = 'A'
        end
        object ActWriteKeyLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied six-byte key (hex)'
        end
        object ActWriteKeyEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWriteSlotLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Actual volatile reader key slot'
        end
        object ActWriteSlotEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWriteDataEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
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
