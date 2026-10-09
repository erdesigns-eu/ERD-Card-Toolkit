object St25DvDemoForm: TSt25DvDemoForm
  Caption = 'St25DvDemo'
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
    ActivePage = ActInformationTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActInformationTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate and read identity / geometry'
      Tag = 0
      object ActInformationInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActInformationModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActInformationModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActInformationFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual ACR1552 firmware response format'
        end
        object ActInformationFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActInformationIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF user password number (1..3)'
        end
        object ActInformationIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActInformationPasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF password, 8 bytes in RF wire order'
        end
        object ActInformationPasswordEdit: TEdit
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
    object ActReadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate and read physical blocks'
      Tag = 1
      object ActReadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActReadModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActReadFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual ACR1552 firmware response format'
        end
        object ActReadFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActReadIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF user password number (1..3)'
        end
        object ActReadIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActReadPasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF password, 8 bytes in RF wire order'
        end
        object ActReadPasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActReadBlockLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'First physical block (write: 2 or greater)'
        end
        object ActReadBlockEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '2'
        end
        object ActReadCountLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Number of complete blocks'
        end
        object ActReadCountEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '1'
        end
        object ActReadBulkLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Explicit multiple-block command selection'
        end
        object ActReadBulkBox: TComboBox
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Single blocks'
            'Read Multiple Blocks'
          )
          Text = 'Single blocks'
        end
      end
    end
    object ActWriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate and write data block + verify'
      Tag = 2
      object ActWriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriteModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActWriteModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActWriteFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual ACR1552 firmware response format'
        end
        object ActWriteFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActWriteIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF user password number (1..3)'
        end
        object ActWriteIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActWritePasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF password, 8 bytes in RF wire order'
        end
        object ActWritePasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWriteBlockLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'First physical block (write: 2 or greater)'
        end
        object ActWriteBlockEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '2'
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Replacement full block bytes (hex)'
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
    object ActReadndefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate and parse Type 5 NDEF'
      Tag = 3
      object ActReadndefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadndefModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActReadndefModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActReadndefFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual ACR1552 firmware response format'
        end
        object ActReadndefFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActReadndefIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF user password number (1..3)'
        end
        object ActReadndefIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActReadndefPasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF password, 8 bytes in RF wire order'
        end
        object ActReadndefPasswordEdit: TEdit
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
    object ActWritendefTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Authenticate and replace/clear NDEF + verify'
      Tag = 4
      object ActWritendefInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWritendefModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActWritendefModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActWritendefFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual ACR1552 firmware response format'
        end
        object ActWritendefFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActWritendefIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF user password number (1..3)'
        end
        object ActWritendefIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActWritendefPasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF password, 8 bytes in RF wire order'
        end
        object ActWritendefPasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWritendefNdefLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Complete NDEF bytes (hex; empty clears existing message)'
        end
        object ActWritendefNdefEdit: TEdit
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
    object ActConfigurationTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read decoded RF area geometry / access / lock information'
      Tag = 5
      object ActConfigurationInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActConfigurationModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActConfigurationModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActConfigurationFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual firmware response format'
        end
        object ActConfigurationFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
      end
    end
    object ActChangepasswordTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Change RF password + proof after RF reset'
      Tag = 6
      object ActChangepasswordInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActChangepasswordModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActChangepasswordModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActChangepasswordFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual firmware response format'
        end
        object ActChangepasswordFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActChangepasswordIdentifierLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'RF password number: 0 configuration, 1..3 user'
        end
        object ActChangepasswordIdentifierEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActChangepasswordOldpasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Current password in RF wire order (hex)'
        end
        object ActChangepasswordOldpasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangepasswordNewpasswordLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'New password in RF wire order (hex)'
        end
        object ActChangepasswordNewpasswordEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangepasswordStablevccLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'External VCC guaranteed stable if VCC_ON is set'
        end
        object ActChangepasswordStablevccBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'No guarantee'
            'Guaranteed stable'
          )
          Text = 'No guarantee'
        end
      end
    end
    object ActConfigureTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Configure one RF area + post-reset verification'
      Tag = 7
      object ActConfigureInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActConfigureModeLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit block address dialect'
        end
        object ActConfigureModeBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Ordinary 8-bit'
            'Extended 16-bit'
          )
          Text = 'Ordinary 8-bit'
        end
        object ActConfigureFormatLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual firmware response format'
        end
        object ActConfigureFormatBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Native flags'
            'Payload only'
          )
          Text = 'Native flags'
        end
        object ActConfigureAreaLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Active RF area number (1..4)'
        end
        object ActConfigureAreaEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActConfigurePasswordLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Supplied RF configuration password 0, eight wire-order bytes'
        end
        object ActConfigurePasswordEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActConfigureExpectedLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Exact eight-register configuration preimage (hex)'
        end
        object ActConfigureExpectedEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActConfigureIdentifierLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Area user password number (0..3)'
        end
        object ActConfigureIdentifierEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '1'
        end
        object ActConfigureProtectionLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Area protection code'
        end
        object ActConfigureProtectionBox: TComboBox
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Public'
            'Write password'
            'Read/write password (area 1 stays readable)'
            'Write forbidden (areas 2..4 need read password)'
          )
          Text = 'Public'
        end
        object ActConfigureStablevccLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'External VCC guaranteed stable if VCC_ON is set'
        end
        object ActConfigureStablevccBox: TComboBox
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'No guarantee'
            'Guaranteed stable'
          )
          Text = 'No guarantee'
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
