object DesfireDemoForm: TDesfireDemoForm
  Caption = 'DesfireDemo'
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
    ActivePage = ActVersionTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActVersionTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read public native version'
      Tag = 0
      object ActVersionInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActVersionInfo: TLabel
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
    object ActApplicationsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read public native application IDs'
      Tag = 1
      object ActApplicationsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActApplicationsInfo: TLabel
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
    object ActFilesTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read acquired file directory'
      Tag = 2
      object ActFilesInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActFilesAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActFilesAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActFilesSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActFilesSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActFilesMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActFilesMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActFilesKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActFilesKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActFilesKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActFilesKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActFilesRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActFilesRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActFilesRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActFilesRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActReadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read data file'
      Tag = 3
      object ActReadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActReadAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActReadSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActReadSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActReadMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActReadMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActReadKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActReadKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActReadKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActReadKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActReadRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActReadRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActReadRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActReadRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActReadFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActReadFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActReadOffsetLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Byte / record offset'
        end
        object ActReadOffsetEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
          Text = '0'
        end
        object ActReadCountLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Byte / record count'
        end
        object ActReadCountEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '1'
        end
      end
    end
    object ActValueTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read signed value'
      Tag = 4
      object ActValueInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActValueAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActValueAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActValueSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActValueSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActValueMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActValueMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActValueKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActValueKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActValueKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActValueKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActValueRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActValueRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActValueRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActValueRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActValueFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActValueFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActRecordsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read complete records'
      Tag = 5
      object ActRecordsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActRecordsAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActRecordsAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActRecordsSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActRecordsSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActRecordsMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActRecordsMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActRecordsKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActRecordsKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActRecordsKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActRecordsKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActRecordsRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActRecordsRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActRecordsRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActRecordsRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActRecordsFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActRecordsFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActRecordsOffsetLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Byte / record offset'
        end
        object ActRecordsOffsetEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
          Text = '0'
        end
        object ActRecordsCountLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Byte / record count'
        end
        object ActRecordsCountEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '1'
        end
      end
    end
    object ActWriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write standard data + verify'
      Tag = 6
      object ActWriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriteAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActWriteAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActWriteSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActWriteMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActWriteMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActWriteKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActWriteKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActWriteKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWriteRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActWriteRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActWriteRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWriteFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActWriteFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteOffsetLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Byte / record offset'
        end
        object ActWriteOffsetEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWriteDataEdit: TEdit
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
    object ActBackupTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage backup write + explicit commit / abort'
      Tag = 7
      object ActBackupInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActBackupAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActBackupAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActBackupSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActBackupSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActBackupMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActBackupMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActBackupKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActBackupKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActBackupKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActBackupKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActBackupRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActBackupRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActBackupRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActBackupRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActBackupAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActBackupAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActBackupFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActBackupFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActBackupFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActBackupFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActBackupOffsetLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Byte / record offset'
        end
        object ActBackupOffsetEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
          Text = '0'
        end
        object ActBackupDataLabel: TLabel
          Left = 16
          Top = 690
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActBackupDataEdit: TEdit
          Left = 16
          Top = 712
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          MaxLength = 262144
        end
      end
    end
    object ActCreditTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage value credit + explicit commit / abort'
      Tag = 8
      object ActCreditInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActCreditAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActCreditAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActCreditSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActCreditSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActCreditMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActCreditMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActCreditKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActCreditKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActCreditKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActCreditKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreditRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActCreditRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActCreditRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActCreditRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreditAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActCreditAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActCreditFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActCreditFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActCreditFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActCreditFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActCreditAmountLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Positive amount'
        end
        object ActCreditAmountEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
      end
    end
    object ActDebitTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage value debit + explicit commit / abort'
      Tag = 9
      object ActDebitInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDebitAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActDebitAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActDebitSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActDebitSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActDebitMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActDebitMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActDebitKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActDebitKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActDebitKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActDebitKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDebitRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActDebitRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActDebitRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActDebitRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDebitAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActDebitAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActDebitFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActDebitFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActDebitFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActDebitFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActDebitAmountLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Positive amount'
        end
        object ActDebitAmountEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
      end
    end
    object ActLimitedTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage limited credit + explicit commit / abort'
      Tag = 10
      object ActLimitedInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActLimitedAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActLimitedAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActLimitedSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActLimitedSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActLimitedMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActLimitedMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActLimitedKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActLimitedKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActLimitedKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActLimitedKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActLimitedRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActLimitedRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActLimitedRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActLimitedRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActLimitedAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActLimitedAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActLimitedFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActLimitedFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActLimitedFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActLimitedFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActLimitedAmountLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Positive amount'
        end
        object ActLimitedAmountEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
      end
    end
    object ActAppendTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage complete record + explicit commit / abort'
      Tag = 11
      object ActAppendInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActAppendAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActAppendAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActAppendSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActAppendSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActAppendMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActAppendMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActAppendKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActAppendKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActAppendKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActAppendKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActAppendRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActAppendRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActAppendRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActAppendRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActAppendAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActAppendAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActAppendFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActAppendFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActAppendFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActAppendFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActAppendDataLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActAppendDataEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
      end
    end
    object ActClearTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Stage records clear + explicit commit / abort'
      Tag = 12
      object ActClearInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActClearAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActClearAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActClearSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActClearSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActClearMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActClearMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActClearKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActClearKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActClearKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActClearKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActClearRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActClearRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActClearRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActClearRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActClearAccessLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Transaction authority'
        end
        object ActClearAccessBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Fresh reset / no pending changes'
            'Discard existing pending changes'
          )
          Text = 'Fresh reset / no pending changes'
        end
        object ActClearFinishLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Explicit transaction decision'
        end
        object ActClearFinishBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Commit and verify'
            'Abort and verify'
          )
          Text = 'Commit and verify'
        end
        object ActClearFileLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActClearFileEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActSettingsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read acquired application settings'
      Tag = 13
      object ActSettingsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSettingsAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActSettingsAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActSettingsSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActSettingsSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActSettingsMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActSettingsMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActSettingsKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActSettingsKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActSettingsKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActSettingsKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActSettingsRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActSettingsRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActSettingsRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActSettingsRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActFreememoryTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read PICC free memory'
      Tag = 14
      object ActFreememoryInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActFreememoryAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActFreememoryAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActFreememorySecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActFreememorySecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActFreememoryMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActFreememoryMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActFreememoryKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActFreememoryKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActFreememoryKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActFreememoryKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActFreememoryRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActFreememoryRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActFreememoryRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActFreememoryRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActKeyversionTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read explicit key version'
      Tag = 15
      object ActKeyversionInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActKeyversionAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActKeyversionAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActKeyversionSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActKeyversionSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActKeyversionMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActKeyversionMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActKeyversionKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActKeyversionKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActKeyversionKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActKeyversionKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActKeyversionRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActKeyversionRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActKeyversionRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActKeyversionRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActKeyversionTargetkeyLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Target key number'
        end
        object ActKeyversionTargetkeyEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActKeysettingsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Change key settings + verify'
      Tag = 16
      object ActKeysettingsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActKeysettingsAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActKeysettingsAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActKeysettingsSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActKeysettingsSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
          )
          Text = 'Public'
        end
        object ActKeysettingsMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActKeysettingsMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActKeysettingsKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActKeysettingsKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActKeysettingsKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActKeysettingsKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActKeysettingsRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActKeysettingsRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActKeysettingsRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActKeysettingsRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActKeysettingsSettingsLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Exact settings byte (decimal)'
        end
        object ActKeysettingsSettingsEdit: TEdit
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
    object ActFileaccessTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Change file access + verify'
      Tag = 17
      object ActFileaccessInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActFileaccessAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActFileaccessAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActFileaccessSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActFileaccessSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
          )
          Text = 'Public'
        end
        object ActFileaccessMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActFileaccessMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActFileaccessKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActFileaccessKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActFileaccessKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActFileaccessKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActFileaccessRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActFileaccessRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActFileaccessRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActFileaccessRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActFileaccessFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActFileaccessFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActFileaccessCommunicationLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Requested communication'
        end
        object ActFileaccessCommunicationBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActFileaccessReadkeyLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Read nibble (decimal)'
        end
        object ActFileaccessReadkeyEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
        object ActFileaccessWritekeyLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Write nibble (decimal)'
        end
        object ActFileaccessWritekeyEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
        object ActFileaccessReadwritekeyLabel: TLabel
          Left = 16
          Top = 690
          Width = 940
          Height = 18
          Caption = 'ReadWrite nibble (decimal)'
        end
        object ActFileaccessReadwritekeyEdit: TEdit
          Left = 16
          Top = 712
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          MaxLength = 262144
        end
        object ActFileaccessChangekeyLabel: TLabel
          Left = 16
          Top = 752
          Width = 940
          Height = 18
          Caption = 'Change-access nibble (decimal)'
        end
        object ActFileaccessChangekeyEdit: TEdit
          Left = 16
          Top = 774
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 12
          MaxLength = 262144
        end
      end
    end
    object ActChangekeyTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Change AES key + fresh authentication proof'
      Tag = 18
      object ActChangekeyInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActChangekeyAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActChangekeyAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActChangekeySecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActChangekeySecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
          )
          Text = 'Public'
        end
        object ActChangekeyMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActChangekeyMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActChangekeyKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActChangekeyKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActChangekeyKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActChangekeyKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangekeyRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActChangekeyRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActChangekeyRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActChangekeyRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangekeyTargetkeyLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Target key number'
        end
        object ActChangekeyTargetkeyEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActChangekeyKeyversionLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'New key version'
        end
        object ActChangekeyKeyversionEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActChangekeyNewkeyLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'New 16-byte AES key (hex)'
        end
        object ActChangekeyNewkeyEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangekeyOldkeyLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Old 16-byte target key; empty if current key (hex)'
        end
        object ActChangekeyOldkeyEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActCreateappTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Create explicit application + verify'
      Tag = 19
      object ActCreateappInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActCreateappAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActCreateappAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActCreateappSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActCreateappSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActCreateappMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActCreateappMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActCreateappKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActCreateappKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActCreateappKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActCreateappKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreateappRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActCreateappRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActCreateappRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActCreateappRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreateappTargetaidLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'New nonzero native AID (decimal)'
        end
        object ActCreateappTargetaidEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActCreateappSettingsLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Exact key-settings byte (decimal)'
        end
        object ActCreateappSettingsEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActCreateappKeycountLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Application key count (1..14)'
        end
        object ActCreateappKeycountEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
        object ActCreateappKeytypeLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Explicit new application key-storage type'
        end
        object ActCreateappKeytypeBox: TComboBox
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          Style = csDropDownList
          ItemIndex = -1
          TabOrder = 10
          Items.Strings = (
            'DES / 2K3DES'
            '3K3DES'
            'AES'
          )
        end
      end
    end
    object ActDeleteappTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Delete explicit application + verify'
      Tag = 20
      object ActDeleteappInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDeleteappAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActDeleteappAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActDeleteappSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActDeleteappSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActDeleteappMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActDeleteappMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActDeleteappKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActDeleteappKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActDeleteappKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActDeleteappKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDeleteappRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActDeleteappRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActDeleteappRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActDeleteappRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDeleteappTargetaidLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Target nonzero native AID (decimal)'
        end
        object ActDeleteappTargetaidEdit: TEdit
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
    object ActDeletefileTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Delete explicit file + verify'
      Tag = 21
      object ActDeletefileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDeletefileAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActDeletefileAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActDeletefileSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActDeletefileSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActDeletefileMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActDeletefileMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActDeletefileKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActDeletefileKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActDeletefileKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActDeletefileKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDeletefileRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActDeletefileRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActDeletefileRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActDeletefileRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActDeletefileFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActDeletefileFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActCreatefileTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Create explicit ordinary file + verify'
      Tag = 22
      object ActCreatefileInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActCreatefileAidLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit native AID (decimal; 0 = PICC)'
        end
        object ActCreatefileAidEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileSecurityLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Explicit security profile'
        end
        object ActCreatefileSecurityBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'EV2 AES'
            'EV1 AES'
            'EV1 2K3DES'
            'EV1 3K3DES'
            'D40 DES'
            'D40 2K3DES'
          )
          Text = 'Public'
        end
        object ActCreatefileMinimumLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Minimum communication'
        end
        object ActCreatefileMinimumBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActCreatefileKeynumberLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key number'
        end
        object ActCreatefileKeynumberEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileKeyLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied authentication key (hex; 8/16/24 bytes by profile)'
        end
        object ActCreatefileKeyEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreatefileRekeynumberLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Secondary proof-context key number'
        end
        object ActCreatefileRekeynumberEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileRekeyLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional explicit secondary-context AES key (hex)'
        end
        object ActCreatefileRekeyEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActCreatefileFileLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActCreatefileFileEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileTypeLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Exact file type'
        end
        object ActCreatefileTypeBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Standard'
            'Backup'
            'Value'
            'Linear records'
            'Cyclic records'
          )
          Text = 'Standard'
        end
        object ActCreatefileCommunicationLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Requested communication'
        end
        object ActCreatefileCommunicationBox: TComboBox
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          Style = csDropDownList
          ItemIndex = 1
          Items.Strings = (
            'Plain'
            'MAC'
            'Full'
          )
          Text = 'MAC'
        end
        object ActCreatefileReadkeyLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Read nibble (decimal)'
        end
        object ActCreatefileReadkeyEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
        end
        object ActCreatefileWritekeyLabel: TLabel
          Left = 16
          Top = 690
          Width = 940
          Height = 18
          Caption = 'Write nibble (decimal)'
        end
        object ActCreatefileWritekeyEdit: TEdit
          Left = 16
          Top = 712
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          MaxLength = 262144
        end
        object ActCreatefileReadwritekeyLabel: TLabel
          Left = 16
          Top = 752
          Width = 940
          Height = 18
          Caption = 'ReadWrite nibble (decimal)'
        end
        object ActCreatefileReadwritekeyEdit: TEdit
          Left = 16
          Top = 774
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 12
          MaxLength = 262144
        end
        object ActCreatefileChangekeyLabel: TLabel
          Left = 16
          Top = 814
          Width = 940
          Height = 18
          Caption = 'Change-access nibble (decimal)'
        end
        object ActCreatefileChangekeyEdit: TEdit
          Left = 16
          Top = 836
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 13
          MaxLength = 262144
        end
        object ActCreatefileFilebytesLabel: TLabel
          Left = 16
          Top = 876
          Width = 940
          Height = 18
          Caption = 'Data-file bytes; otherwise 0'
        end
        object ActCreatefileFilebytesEdit: TEdit
          Left = 16
          Top = 898
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 14
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileLowerLabel: TLabel
          Left = 16
          Top = 938
          Width = 940
          Height = 18
          Caption = 'Value lower bound; otherwise 0'
        end
        object ActCreatefileLowerEdit: TEdit
          Left = 16
          Top = 960
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 15
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileUpperLabel: TLabel
          Left = 16
          Top = 1000
          Width = 940
          Height = 18
          Caption = 'Value upper bound; otherwise 0'
        end
        object ActCreatefileUpperEdit: TEdit
          Left = 16
          Top = 1022
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 16
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileInitialLabel: TLabel
          Left = 16
          Top = 1062
          Width = 940
          Height = 18
          Caption = 'Initial value; otherwise 0'
        end
        object ActCreatefileInitialEdit: TEdit
          Left = 16
          Top = 1084
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 17
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileLimitedLabel: TLabel
          Left = 16
          Top = 1124
          Width = 940
          Height = 18
          Caption = 'Limited credit enabled'
        end
        object ActCreatefileLimitedBox: TComboBox
          Left = 16
          Top = 1146
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 18
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'No'
            'Yes'
          )
          Text = 'No'
        end
        object ActCreatefileRecordbytesLabel: TLabel
          Left = 16
          Top = 1186
          Width = 940
          Height = 18
          Caption = 'Record bytes; otherwise 0'
        end
        object ActCreatefileRecordbytesEdit: TEdit
          Left = 16
          Top = 1208
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 19
          MaxLength = 262144
          Text = '0'
        end
        object ActCreatefileMaxrecordsLabel: TLabel
          Left = 16
          Top = 1248
          Width = 940
          Height = 18
          Caption = 'Record capacity; otherwise 0'
        end
        object ActCreatefileMaxrecordsEdit: TEdit
          Left = 16
          Top = 1270
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 20
          MaxLength = 262144
          Text = '0'
        end
      end
    end
    object ActDecodeTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline file settings decoder'
      Tag = 23
      object ActDecodeInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDecodeFileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Native file number'
        end
        object ActDecodeFileEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '0'
        end
        object ActDecodeHexLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete native settings bytes (hex)'
        end
        object ActDecodeHexEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
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
