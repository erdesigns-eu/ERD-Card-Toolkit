object Type2DemoForm: TType2DemoForm
  Caption = 'Type2Demo'
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
    object ActPageTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read explicit physical page'
      Tag = 1
      object ActPageInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPageType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActPageType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActPagePageLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical page'
        end
        object ActPagePageEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '4'
        end
      end
    end
    object ActMemoryTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read full public user-memory snapshot'
      Tag = 2
      object ActMemoryInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActMemoryType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActMemoryType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
      end
    end
    object ActWritepageTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write user page: status receipt only'
      Tag = 3
      object ActWritepageInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWritepageType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActWritepageType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActWritepagePageLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical user page'
        end
        object ActWritepagePageEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '4'
        end
        object ActWritepageDataLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWritepageDataEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
        end
      end
    end
    object ActReadndefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read public NDEF'
      Tag = 4
      object ActReadndefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadndefType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActReadndefType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
      end
    end
    object ActWritendefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Replace public NDEF + verify'
      Tag = 5
      object ActWritendefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWritendefType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActWritendefType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActWritendefNdefLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete NDEF message (hex)'
        end
        object ActWritendefNdefEdit: TEdit
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
    object ActClearndefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Clear public NDEF + verify'
      Tag = 6
      object ActClearndefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActClearndefType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActClearndefType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
      end
    end
    object ActPwdpageTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'ACR122 PWD_AUTH + exact page'
      Tag = 7
      object ActPwdpageInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdpageType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActPwdpageType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActPwdpagePageLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical user page'
        end
        object ActPwdpagePageEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '4'
        end
        object ActPwdpagePasswordLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied four-byte password (hex)'
        end
        object ActPwdpagePasswordEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdpagePackLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdpagePackEdit: TEdit
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
    object ActPwdmemoryTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'ACR122 PWD_AUTH + user memory'
      Tag = 8
      object ActPwdmemoryInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdmemoryType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActPwdmemoryType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActPwdmemoryPasswordLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Supplied four-byte password (hex)'
        end
        object ActPwdmemoryPasswordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdmemoryPackLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdmemoryPackEdit: TEdit
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
    object ActPwdwriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'ACR122 authenticated page write + verify'
      Tag = 9
      object ActPwdwriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdwriteType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual Type 2 model'
        end
        object ActPwdwriteType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
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
          Text = 'Ultralight'
        end
        object ActPwdwritePageLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Physical user page'
        end
        object ActPwdwritePageEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '4'
        end
        object ActPwdwritePasswordLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied four-byte password (hex)'
        end
        object ActPwdwritePasswordEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdwritePackLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdwritePackEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdwriteDataLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActPwdwriteDataEdit: TEdit
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
    object ActPwdconfigTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read authentication configuration'
      Tag = 10
      object ActPwdconfigInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdconfigType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdconfigType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdconfigPasswordLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdconfigPasswordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdconfigPackLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdconfigPackEdit: TEdit
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
    object ActPwdconfigureTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Configure authentication + fresh RF proof'
      Tag = 11
      object ActPwdconfigureInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdconfigureType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdconfigureType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdconfigureFirstpageLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'AUTH0 byte (decimal; 255 disables protection)'
        end
        object ActPwdconfigureFirstpageEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '255'
        end
        object ActPwdconfigureProtectreadsLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Protection scope'
        end
        object ActPwdconfigureProtectreadsBox: TComboBox
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Writes only'
            'Reads and writes'
          )
          Text = 'Writes only'
        end
        object ActPwdconfigureAuthlimLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'AUTHLIM (0..7; 0 disables limit)'
        end
        object ActPwdconfigureAuthlimEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActPwdconfigureBeforeLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Exact eight-byte configuration preimage (hex)'
        end
        object ActPwdconfigureBeforeEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActPwdconfigurePasswordLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdconfigurePasswordEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdconfigurePackLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdconfigurePackEdit: TEdit
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
    object ActPwdcredentialsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Replace password/PACK + fresh RF proof'
      Tag = 12
      object ActPwdcredentialsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdcredentialsType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdcredentialsType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdcredentialsPasswordLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdcredentialsPasswordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdcredentialsPackLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdcredentialsPackEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdcredentialsNewpasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'New four-byte password (hex)'
        end
        object ActPwdcredentialsNewpasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdcredentialsNewpackLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'New two-byte PACK (hex)'
        end
        object ActPwdcredentialsNewpackEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActPwdcounterTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read supported 24-bit counter'
      Tag = 13
      object ActPwdcounterInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdcounterType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdcounterType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdcounterCounterLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Counter (EV1: 0..2; NTAG213/215/216: 2)'
        end
        object ActPwdcounterCounterEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '2'
        end
        object ActPwdcounterPasswordLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdcounterPasswordEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdcounterPackLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdcounterPackEdit: TEdit
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
    object ActPwdreadndefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read and parse protected NDEF'
      Tag = 14
      object ActPwdreadndefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdreadndefType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdreadndefType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdreadndefPasswordLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdreadndefPasswordEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdreadndefPackLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdreadndefPackEdit: TEdit
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
    object ActPwdwritendefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Replace/clear protected NDEF + verify'
      Tag = 15
      object ActPwdwritendefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPwdwritendefType2modelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit password-capable Type 2 model'
        end
        object ActPwdwritendefType2modelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Ultralight (no PWD_AUTH)'
            'EV1 48'
            'EV1 128'
            'NTAG213'
            'NTAG215'
            'NTAG216'
            'NTAG210'
            'NTAG212'
          )
        end
        object ActPwdwritendefNdefLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete NDEF bytes (hex; empty clears existing TLV)'
        end
        object ActPwdwritendefNdefEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActPwdwritendefPasswordLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Current four-byte password (hex)'
        end
        object ActPwdwritendefPasswordEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActPwdwritendefPackLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Expected two-byte PACK (hex)'
        end
        object ActPwdwritendefPackEdit: TEdit
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
