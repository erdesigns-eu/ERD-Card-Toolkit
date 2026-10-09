object UltralightCDemoForm: TUltralightCDemoForm
  Caption = 'UltralightCDemo'
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
    Top = 118
    Width = 1080
    Height = 462
    Align = alClient
    ActivePage = ActPageTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActPageTab: TTabSheet
      Caption = 'Authenticate + read user page'
      Tag = 0
      object ActPageInputs: TScrollBox
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPagePageLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Physical user page (4..39)'
        end
        object ActPagePageEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '4'
        end
        object ActPageKeyLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = '16-byte supplied 2K3DES key (hex)'
        end
        object ActPageKeyEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActMemoryTab: TTabSheet
      Caption = 'Authenticate + read all 144 user bytes'
      Tag = 1
      object ActMemoryInputs: TScrollBox
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActMemoryKeyLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = '16-byte supplied 2K3DES key (hex)'
        end
        object ActMemoryKeyEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActWriteTab: TTabSheet
      Caption = 'Authenticate + write user page + verify'
      Tag = 2
      object ActWriteInputs: TScrollBox
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWritePageLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Physical user page (4..39)'
        end
        object ActWritePageEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '4'
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Exactly four replacement bytes (hex)'
        end
        object ActWriteDataEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActWriteKeyLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = '16-byte supplied 2K3DES key (hex)'
        end
        object ActWriteKeyEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActConfigurationTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read authentication configuration'
      Tag = 3
      object ActConfigurationInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActConfigurationKeyLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Supplied 16-byte current key (hex)'
        end
        object ActConfigurationKeyEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActConfigureTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Configure authentication + fresh RF proof'
      Tag = 4
      object ActConfigureInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActConfigureFirstpageLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'First protected page (3..48; 48 = disabled)'
        end
        object ActConfigureFirstpageEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '4'
        end
        object ActConfigureProtectreadsLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Protection scope'
        end
        object ActConfigureProtectreadsBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Writes only'
            'Reads and writes'
          )
          Text = 'Writes only'
        end
        object ActConfigureBeforeLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Exact pages 42/43 preimage (8 bytes, hex)'
        end
        object ActConfigureBeforeEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
        end
        object ActConfigureKeyLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied 16-byte current key (hex)'
        end
        object ActConfigureKeyEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActChangekeyTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Replace key + fresh RF proof'
      Tag = 5
      object ActChangekeyInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActChangekeyKeyLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Supplied 16-byte current key (hex)'
        end
        object ActChangekeyKeyEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangekeyNewkeyLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'New 16-byte key (hex)'
        end
        object ActChangekeyNewkeyEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
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
