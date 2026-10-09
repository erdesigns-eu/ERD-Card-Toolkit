object MemoryCardDemoForm: TMemoryCardDemoForm
  Caption = 'MemoryCardDemo'
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
    ActivePage = ActCapabilitiesTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActCapabilitiesTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline reader-profile capabilities'
      Tag = 0
      object ActCapabilitiesInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActCapabilitiesDialectLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActCapabilitiesDialectBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
      end
    end
    object ActSnapshotTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read snapshot / protection / retry status'
      Tag = 1
      object ActSnapshotInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSnapshotModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActSnapshotModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActSnapshotDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActSnapshotDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
      end
    end
    object ActReadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read memory range'
      Tag = 2
      object ActReadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActReadModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActReadDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActReadDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
        object ActReadAddressLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Start byte / page / block (decimal)'
        end
        object ActReadAddressEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '0'
        end
        object ActReadCountLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Read byte count (decimal)'
        end
        object ActReadCountEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '16'
        end
      end
    end
    object ActVerifyTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Verify supplied PIN once'
      Tag = 3
      object ActVerifyInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActVerifyModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActVerifyModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActVerifyDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActVerifyDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
        object ActVerifyPinLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied PIN / user code (hex)'
        end
        object ActVerifyPinEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActVerifyAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActVerifyAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
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
      Caption = 'Write range + verify'
      Tag = 4
      object ActWriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriteModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActWriteModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActWriteDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActWriteDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
        object ActWriteAddressLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Start byte / page / block (decimal)'
        end
        object ActWriteAddressEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '0'
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWriteDataEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
        end
        object ActWritePinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Supplied PIN / user code (hex)'
        end
        object ActWritePinEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActWritePageLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Actual I2C write-page size'
        end
        object ActWritePageBox: TComboBox
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            '8 bytes'
            '16 bytes'
            '32 bytes'
            '64 bytes'
            '128 bytes'
          )
        end
        object ActWriteAttemptsLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActWriteAttemptsEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
      end
    end
    object ActChangepinTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Replace two-wire PIN + prove new PIN'
      Tag = 5
      object ActChangepinInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActChangepinModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActChangepinModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActChangepinDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActChangepinDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
        object ActChangepinPinLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied PIN / user code (hex)'
        end
        object ActChangepinPinEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangepinNewpinLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'New PIN (hex)'
        end
        object ActChangepinNewpinEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangepinAttemptsLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActChangepinAttemptsEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '1'
        end
      end
    end
    object ActProtectTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Permanently protect selected SLE bytes'
      Tag = 6
      object ActProtectInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActProtectModelLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual SLE / I2C model'
        end
        object ActProtectModelBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'SLE4432'
            'SLE4442'
            'SLE5532'
            'SLE5542'
            'SLE4418'
            'SLE4428'
            'SLE5518'
            'SLE5528'
            'I2C1Kbit'
            'I2C2Kbit'
            'I2C4Kbit'
            'I2C8Kbit'
            'I2C16Kbit'
            'I2C32Kbit'
            'I2C64Kbit'
            'I2C128Kbit'
            'I2C256Kbit'
            'I2C512Kbit'
            'I2C1024Kbit'
          )
        end
        object ActProtectDialectLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual reader dialect'
        end
        object ActProtectDialectBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'ACR38x CCID'
            'ACR39'
          )
        end
        object ActProtectPinLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Supplied PIN / user code (hex)'
        end
        object ActProtectPinEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActProtectAddressLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Start byte / page / block (decimal)'
        end
        object ActProtectAddressEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActProtectBeforeLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActProtectBeforeEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActProtectAttemptsLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActProtectAttemptsEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
          Text = '1'
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
