object SimCardDemoForm: TSimCardDemoForm
  Caption = 'SimCardDemo'
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
    ActivePage = ActIccidTab
    MultiLine = True
    TabOrder = 1
    OnChange = ActionChanged
    object ActIccidTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read ICCID'
      Tag = 0
      object ActIccidInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActIccidProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActIccidProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActIccidAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActIccidAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActIccidPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActIccidPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActIccidAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActIccidAttemptsEdit: TEdit
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
    object ActApplicationsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Enumerate UICC applications'
      Tag = 1
      object ActApplicationsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActApplicationsProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActApplicationsProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActApplicationsAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActApplicationsAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActApplicationsPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActApplicationsPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActApplicationsAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActApplicationsAttemptsEdit: TEdit
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
    object ActPinstatusTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Query PIN status without attempt'
      Tag = 2
      object ActPinstatusInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPinstatusProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActPinstatusProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActPinstatusAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActPinstatusAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActPinstatusPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActPinstatusPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActPinstatusAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActPinstatusAttemptsEdit: TEdit
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
    object ActPukstatusTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Query known PUK budget without attempt'
      Tag = 3
      object ActPukstatusInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActPukstatusProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActPukstatusProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActPukstatusAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActPukstatusAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActPukstatusPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActPukstatusPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActPukstatusAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActPukstatusAttemptsEdit: TEdit
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
    object ActChangepinTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Change PIN once: command receipt'
      Tag = 4
      object ActChangepinInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActChangepinProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActChangepinProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActChangepinAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActChangepinAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActChangepinPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActChangepinPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActChangepinAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActChangepinAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActChangepinPinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActChangepinPinEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActChangepinNewpinLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'New ASCII-digit PIN bytes (hex)'
        end
        object ActChangepinNewpinEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActUnblockpinTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Unblock PIN once: command receipt'
      Tag = 5
      object ActUnblockpinInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActUnblockpinProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActUnblockpinProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActUnblockpinAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActUnblockpinAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActUnblockpinPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActUnblockpinPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActUnblockpinAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActUnblockpinAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActUnblockpinPukLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Eight supplied ASCII PUK digits (hex)'
        end
        object ActUnblockpinPukEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 128
          PasswordChar = '*'
        end
        object ActUnblockpinNewpinLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'New ASCII-digit PIN bytes (hex)'
        end
        object ActUnblockpinNewpinEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActLinkedwriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Explicit linked record plan + verify'
      Tag = 6
      object ActLinkedwriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActLinkedwriteProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActLinkedwriteProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActLinkedwriteAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActLinkedwriteAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActLinkedwritePinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActLinkedwritePinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedwriteAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActLinkedwriteAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedwritePlanLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Ordered FIDhex:record:beforehex:datahex rows separated by semicolon'
        end
        object ActLinkedwritePlanEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
        end
        object ActLinkedwritePinLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActLinkedwritePinEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActVerifyTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Verify supplied PIN once'
      Tag = 7
      object ActVerifyInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActVerifyProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActVerifyProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActVerifyAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActVerifyAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActVerifyPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActVerifyPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
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
        object ActVerifyPinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActVerifyPinEdit: TEdit
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
    object ActImsiTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read IMSI'
      Tag = 8
      object ActImsiInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActImsiProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActImsiProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActImsiAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActImsiAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActImsiPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActImsiPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActImsiAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActImsiAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActImsiPinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActImsiPinEdit: TEdit
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
    object ActSpnTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read service provider'
      Tag = 9
      object ActSpnInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSpnProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActSpnProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActSpnAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActSpnAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActSpnPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActSpnPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActSpnAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActSpnAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActSpnPinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActSpnPinEdit: TEdit
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
    object ActServicesTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read SST / UST service bits'
      Tag = 10
      object ActServicesInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActServicesProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActServicesProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActServicesAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActServicesAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActServicesPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActServicesPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActServicesAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActServicesAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActServicesPinLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActServicesPinEdit: TEdit
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
    object ActInspectTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Inspect explicit file'
      Tag = 11
      object ActInspectInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActInspectProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActInspectProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActInspectAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActInspectAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActInspectPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActInspectPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActInspectAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActInspectAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActInspectRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActInspectRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActInspectPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActInspectPathEdit: TEdit
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
    object ActReadTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read complete transparent file'
      Tag = 12
      object ActReadInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActReadProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActReadProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActReadAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActReadAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActReadPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActReadPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActReadAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActReadAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActReadRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActReadRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActReadPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActReadPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActReadPinLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActReadPinEdit: TEdit
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
    object ActRangeTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read transparent range'
      Tag = 13
      object ActRangeInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActRangeProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActRangeProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActRangeAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActRangeAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActRangePinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActRangePinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActRangeAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActRangeAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActRangeRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActRangeRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActRangePathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActRangePathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActRangeAddressLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Start byte / page / block (decimal)'
        end
        object ActRangeAddressEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '0'
        end
        object ActRangeCountLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Read byte count (decimal)'
        end
        object ActRangeCountEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
          Text = '16'
        end
        object ActRangePinLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActRangePinEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActRecordTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read absolute record'
      Tag = 14
      object ActRecordInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActRecordProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActRecordProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActRecordAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActRecordAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActRecordPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActRecordPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActRecordAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActRecordAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActRecordRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActRecordRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActRecordPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActRecordPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActRecordRecordLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'One-based record'
        end
        object ActRecordRecordEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
        object ActRecordPinLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActRecordPinEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActRecordsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read all records'
      Tag = 15
      object ActRecordsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActRecordsProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActRecordsProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActRecordsAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActRecordsAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActRecordsPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActRecordsPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActRecordsAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActRecordsAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActRecordsRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActRecordsRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActRecordsPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActRecordsPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActRecordsPinLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActRecordsPinEdit: TEdit
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
    object ActContactsTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read explicit ADN contacts'
      Tag = 16
      object ActContactsInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActContactsProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActContactsProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActContactsAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActContactsAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActContactsPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActContactsPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActContactsAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActContactsAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActContactsRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActContactsRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActContactsPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActContactsPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActContactsPinLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActContactsPinEdit: TEdit
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
    object ActWriteTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write complete transparent file + verify'
      Tag = 17
      object ActWriteInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriteProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActWriteProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActWriteAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActWriteAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActWritePinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActWritePinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActWriteAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActWriteAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActWriteRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActWriteRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActWritePathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActWritePathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActWriteBeforeLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActWriteBeforeEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
        end
        object ActWriteDataLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWriteDataEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActWritePinLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActWritePinEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActWriterecordTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write linear-fixed record + verify'
      Tag = 18
      object ActWriterecordInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActWriterecordProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActWriterecordProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActWriterecordAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActWriterecordAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActWriterecordPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActWriterecordPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActWriterecordAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActWriterecordAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActWriterecordRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActWriterecordRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActWriterecordPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActWriterecordPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActWriterecordRecordLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'One-based record'
        end
        object ActWriterecordRecordEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
        object ActWriterecordBeforeLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActWriterecordBeforeEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActWriterecordDataLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Replacement bytes (hex)'
        end
        object ActWriterecordDataEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActWriterecordPinLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActWriterecordPinEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActContactTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Write standalone ADN contact + verify'
      Tag = 19
      object ActContactInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActContactProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActContactProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActContactAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActContactAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActContactPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActContactPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActContactAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActContactAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActContactRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActContactRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActContactPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActContactPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActContactRecordLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'One-based record'
        end
        object ActContactRecordEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
        object ActContactBeforeLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActContactBeforeEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActContactNameLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Contact name'
        end
        object ActContactNameEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 262144
        end
        object ActContactNumberLabel: TLabel
          Left = 16
          Top = 566
          Width = 940
          Height = 18
          Caption = 'Contact number'
        end
        object ActContactNumberEdit: TEdit
          Left = 16
          Top = 588
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 9
          MaxLength = 262144
        end
        object ActContactPinLabel: TLabel
          Left = 16
          Top = 628
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActContactPinEdit: TEdit
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
    object ActLinkedcontactTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Read explicit USIM PBR / IAP / EXT contact'
      Tag = 20
      object ActLinkedcontactInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActLinkedcontactProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActLinkedcontactProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActLinkedcontactAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActLinkedcontactAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActLinkedcontactPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActLinkedcontactPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedcontactAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActLinkedcontactAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedcontactPbrrecordLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'One-based PBR record'
        end
        object ActLinkedcontactPbrrecordEdit: TEdit
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedcontactAdnfidLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'Actual PBR-reported ADN FID (decimal)'
        end
        object ActLinkedcontactAdnfidEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActLinkedcontactRecordLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'One-based ADN record'
        end
        object ActLinkedcontactRecordEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
        object ActLinkedcontactPinLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActLinkedcontactPinEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActDeletecontactTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Delete standalone ADN contact + verify'
      Tag = 21
      object ActDeletecontactInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDeletecontactProfileLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Explicit SIM dialect'
        end
        object ActDeletecontactProfileBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Classic GSM SIM'
            'UICC / USIM'
          )
          Text = 'Classic GSM SIM'
        end
        object ActDeletecontactAidLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete selected USIM AID (hex)'
        end
        object ActDeletecontactAidEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
        end
        object ActDeletecontactPinrefLabel: TLabel
          Left = 16
          Top = 132
          Width = 940
          Height = 18
          Caption = 'PIN reference (decimal)'
        end
        object ActDeletecontactPinrefEdit: TEdit
          Left = 16
          Top = 154
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 2
          MaxLength = 262144
          Text = '1'
        end
        object ActDeletecontactAttemptsLabel: TLabel
          Left = 16
          Top = 194
          Width = 940
          Height = 18
          Caption = 'Minimum remaining PIN attempts'
        end
        object ActDeletecontactAttemptsEdit: TEdit
          Left = 16
          Top = 216
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          MaxLength = 262144
          Text = '1'
        end
        object ActDeletecontactRootLabel: TLabel
          Left = 16
          Top = 256
          Width = 940
          Height = 18
          Caption = 'Explicit file root'
        end
        object ActDeletecontactRootBox: TComboBox
          Left = 16
          Top = 278
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 4
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Master file'
            'USIM application'
          )
          Text = 'Master file'
        end
        object ActDeletecontactPathLabel: TLabel
          Left = 16
          Top = 318
          Width = 940
          Height = 18
          Caption = 'File path: slash-separated four-digit hex FIDs'
        end
        object ActDeletecontactPathEdit: TEdit
          Left = 16
          Top = 340
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 5
          MaxLength = 262144
        end
        object ActDeletecontactRecordLabel: TLabel
          Left = 16
          Top = 380
          Width = 940
          Height = 18
          Caption = 'One-based record'
        end
        object ActDeletecontactRecordEdit: TEdit
          Left = 16
          Top = 402
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          MaxLength = 262144
          Text = '1'
        end
        object ActDeletecontactBeforeLabel: TLabel
          Left = 16
          Top = 442
          Width = 940
          Height = 18
          Caption = 'Expected current bytes (hex)'
        end
        object ActDeletecontactBeforeEdit: TEdit
          Left = 16
          Top = 464
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 7
          MaxLength = 262144
        end
        object ActDeletecontactPinLabel: TLabel
          Left = 16
          Top = 504
          Width = 940
          Height = 18
          Caption = 'Optional supplied ASCII-digit PIN bytes (hex)'
        end
        object ActDeletecontactPinEdit: TEdit
          Left = 16
          Top = 526
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 8
          MaxLength = 128
          PasswordChar = '*'
        end
      end
    end
    object ActDecodeTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline SIM record / identity decoder'
      Tag = 22
      object ActDecodeInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActDecodeKindLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Exact record format'
        end
        object ActDecodeKindBox: TComboBox
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'ICCID'
            'IMSI'
            'Alpha'
            'SPN'
            'ADN'
            'SMS'
            'EF.DIR'
            'USIM PBR'
            'SMS text'
          )
          Text = 'ICCID'
        end
        object ActDecodeHexLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Complete raw bytes (hex)'
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
    object ActSmsjoinTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline complete SMS segment set'
      Tag = 23
      object ActSmsjoinInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActSmsjoinRecordsLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Complete EF.SMS records (hex), separated by semicolon'
        end
        object ActSmsjoinRecordsEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
        end
      end
    end
    object ActEmailTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline EMAIL record'
      Tag = 24
      object ActEmailInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActEmailHexLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Exact EMAIL bytes (hex)'
        end
        object ActEmailHexEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
        end
        object ActEmailFooterLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual linkage footer'
        end
        object ActEmailFooterBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Absent'
            'Two bytes'
          )
          Text = 'Absent'
        end
      end
    end
    object ActAnrTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline ANR record'
      Tag = 25
      object ActAnrInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActAnrHexLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Exact ANR bytes (hex)'
        end
        object ActAnrHexEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
        end
        object ActAnrFooterLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Actual linkage footer'
        end
        object ActAnrFooterBox: TComboBox
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Style = csDropDownList
          ItemIndex = 0
          Items.Strings = (
            'Absent'
            'Two bytes'
          )
          Text = 'Absent'
        end
      end
    end
    object ActEncodealphaTab: TTabSheet
      Left = 4
      Top = 44
      Width = 1072
      Height = 438
      Caption = 'Offline GSM / UCS-2 name encoder'
      Tag = 26
      object ActEncodealphaInputs: TScrollBox
        Left = 0
        Top = 0
        Width = 1072
        Height = 438
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        object ActEncodealphaNameLabel: TLabel
          Left = 16
          Top = 8
          Width = 940
          Height = 18
          Caption = 'Name'
        end
        object ActEncodealphaNameEdit: TEdit
          Left = 16
          Top = 30
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          MaxLength = 262144
        end
        object ActEncodealphaWidthLabel: TLabel
          Left = 16
          Top = 70
          Width = 940
          Height = 18
          Caption = 'Exact field byte width'
        end
        object ActEncodealphaWidthEdit: TEdit
          Left = 16
          Top = 92
          Width = 940
          Height = 25
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          MaxLength = 262144
          Text = '16'
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
