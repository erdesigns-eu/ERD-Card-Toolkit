object RfidInputDemoForm: TRfidInputDemoForm
  Caption = 'RfidInputDemo'
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
      Caption = 'Detected HID devices are listed here. Foreground keyboard capture receives OS keyboard input; it does not filter one USB keyboard.'
    end
    object ReaderLabel: TLabel
      Left = 16
      Top = 32
      Width = 850
      Height = 18
      Caption = 'Available USB-HID collections:'
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
      Visible = True
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
      Visible = False
      Style = csDropDownList
      TabOrder = 3
      OnChange = PreviewArtifact
    end
    object SaveButton: TButton
      Left = 892
      Top = 36
      Width = 164
      Height = 30
      Visible = False
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
    ActivePage = ActTextTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActTextTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Decode presented text'
      Tag = 0
      object ActTextInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActTextTextLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Reader-presented identifier'
        end
        object ActTextTextEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
          Text = '001234'
        end
        object ActTextEncodingLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual output encoding'
        end
        object ActTextEncodingBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'ASCII'
            'Hexadecimal'
            'Decimal'
          )
          Text = 'ASCII'
        end
        object ActTextExpectedLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Exact identifier characters; 0 = variable'
        end
        object ActTextExpectedEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '0'
        end
        object ActTextWidthLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Explicit numeric byte width; 0 = no conversion'
        end
        object ActTextWidthEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '0'
        end
        object ActTextOrderLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit numeric byte order'
        end
        object ActTextOrderBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Big endian'
            'Little endian'
          )
          Text = 'Big endian'
        end
      end
    end
    object ActKeyboardTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Live foreground keyboard capture'
      Tag = 1
      object ActKeyboardInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActKeyboardEncodingLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual output encoding'
        end
        object ActKeyboardEncodingBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'ASCII'
            'Hexadecimal'
            'Decimal'
          )
          Text = 'ASCII'
        end
        object ActKeyboardTerminatorLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual delimiter'
        end
        object ActKeyboardTerminatorBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'CR'
            'CRLF'
            'LF'
            'Tab'
          )
          Text = 'CR'
        end
        object ActKeyboardExpectedLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Exact identifier characters; 0 = variable'
        end
        object ActKeyboardExpectedEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '0'
        end
        object ActKeyboardGapLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Inter-character gap budget (ms)'
        end
        object ActKeyboardGapEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '500'
        end
        object ActKeyboardPrefixLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Exact prefix'
        end
        object ActKeyboardPrefixEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActKeyboardSuffixLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Exact suffix'
        end
        object ActKeyboardSuffixEdit: TEdit
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
    object ActReportsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Decode host-provided HID reports'
      Tag = 2
      object ActReportsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReportsEncodingLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Actual output encoding'
        end
        object ActReportsEncodingBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'ASCII'
            'Hexadecimal'
            'Decimal'
          )
          Text = 'ASCII'
        end
        object ActReportsTerminatorLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual delimiter'
        end
        object ActReportsTerminatorBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'CR'
            'CRLF'
            'LF'
            'Tab'
          )
          Text = 'CR'
        end
        object ActReportsExpectedLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'Exact identifier characters; 0 = variable'
        end
        object ActReportsExpectedEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '0'
        end
        object ActReportsGapLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Inter-character gap budget (ms)'
        end
        object ActReportsGapEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '500'
        end
        object ActReportsPrefixLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Exact prefix'
        end
        object ActReportsPrefixEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActReportsSuffixLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Exact suffix'
        end
        object ActReportsSuffixEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActReportsKindLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Actual report format'
        end
        object ActReportsKindBox: TComboBox
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          Style = csDropDownList
          ItemIndex = -1
          Items.Strings = (
            'Boot 8 bytes'
            'Boot + report ID'
            'Fixed ASCII field'
          )
        end
        object ActReportsReportidLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Explicit report ID (decimal)'
        end
        object ActReportsReportidEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '0'
        end
        object ActReportsCapsLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Initial codec caps lock'
        end
        object ActReportsCapsBox: TComboBox
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Off'
            'On'
          )
          Text = 'Off'
        end
        object ActReportsReportbytesLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Exact fixed-field report bytes'
        end
        object ActReportsReportbytesEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
          Text = '0'
        end
        object ActReportsOffsetLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Fixed-field zero-based offset'
        end
        object ActReportsOffsetEdit: TEdit
          Left = 16
          Top = 650
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 10
          MaxLength = 262144
          Text = '0'
        end
        object ActReportsFieldbytesLabel: TLabel
          Left = 16
          Top = 690
          Width = 940
          Height = 18
          Caption = 'Fixed-field width'
        end
        object ActReportsFieldbytesEdit: TEdit
          Left = 16
          Top = 712
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 11
          MaxLength = 262144
          Text = '0'
        end
        object ActReportsHasidLabel: TLabel
          Left = 16
          Top = 752
          Width = 940
          Height = 18
          Caption = 'Fixed-field report ID present'
        end
        object ActReportsHasidBox: TComboBox
          Left = 16
          Top = 774
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 12
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'No'
            'Yes'
          )
          Text = 'No'
        end
        object ActReportsPaddingLabel: TLabel
          Left = 16
          Top = 814
          Width = 940
          Height = 18
          Caption = 'Fixed-field trailing padding'
        end
        object ActReportsPaddingBox: TComboBox
          Left = 16
          Top = 836
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 13
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'NUL'
            'Space'
          )
          Text = 'NUL'
        end
        object ActReportsReportsLabel: TLabel
          Left = 16
          Top = 876
          Width = 940
          Height = 18
          Caption = 'Complete reports (hex), separated by semicolon'
        end
        object ActReportsReportsEdit: TEdit
          Left = 16
          Top = 898
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 14
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
