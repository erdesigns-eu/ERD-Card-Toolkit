object SmartCardDemoForm: TSmartCardDemoForm
  Left = 0
  Top = 0
  Caption = 'ERD Cards - PC/SC read and write demo'
  ClientHeight = 650
  ClientWidth = 1000
  Color = clBtnFace
  Constraints.MinHeight = 650
  Constraints.MinWidth = 1000
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    1000
    650)
  TextHeight = 15
  object PhotoImage: TImage
    Left = 716
    Top = 360
    Width = 264
    Height = 228
    Anchors = [akTop, akRight]
    Center = True
    Proportional = True
    Stretch = True
  end
  object InputPanel: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 344
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ReaderLabel: TLabel
      Left = 16
      Top = 16
      Width = 100
      Height = 15
      Caption = 'Exact PC/SC reader'
    end
    object ReaderBox: TComboBox
      Left = 160
      Top = 12
      Width = 660
      Height = 23
      TabOrder = 0
    end
    object ReadersButton: TButton
      Left = 840
      Top = 12
      Width = 140
      Height = 28
      Caption = 'List readers'
      TabOrder = 1
      OnClick = ReadersClick
    end
    object OperationPages: TPageControl
      Left = 8
      Top = 48
      Width = 984
      Height = 296
      ActivePage = CardTab
      TabOrder = 2
      object CardTab: TTabSheet
        Caption = 'Smart cards / NDEF'
        object OperationLabel: TLabel
          Left = 8
          Top = 4
          Width = 53
          Height = 15
          Caption = 'Operation'
        end
        object ModelLabel: TLabel
          Left = 8
          Top = 40
          Width = 71
          Height = 15
          Caption = 'Type 2 model'
        end
        object AccessLabel: TLabel
          Left = 8
          Top = 76
          Width = 65
          Height = 15
          Caption = 'ICAO access'
        end
        object PasswordLabel: TLabel
          Left = 8
          Top = 112
          Width = 85
          Height = 15
          Caption = 'MRZ info / CAN'
        end
        object LibraryLabel: TLabel
          Left = 8
          Top = 148
          Width = 92
          Height = 15
          Caption = 'OpenSSL 3 library'
        end
        object NdefLabel: TLabel
          Left = 8
          Top = 184
          Width = 50
          Height = 15
          Caption = 'NDEF hex'
        end
        object TextLabel: TLabel
          Left = 8
          Top = 220
          Width = 90
          Height = 15
          Caption = 'Offline NDEF text'
        end
        object ProfileLabel: TLabel
          Left = 8
          Top = 244
          Width = 604
          Height = 15
          Caption =
            'UID / Type 2: explicit FF CA / FF B0 / FF D6 profile. Replace op' +
            'erations overwrite existing NDEF and verify read-back.'
        end
        object OperationBox: TComboBox
          Left = 152
          Top = 0
          Width = 400
          Height = 23
          Style = csDropDownList
          TabOrder = 2
        end
        object RunButton: TButton
          Left = 582
          Top = 0
          Width = 230
          Height = 28
          Caption = 'Run selected operation'
          TabOrder = 3
          OnClick = RunClick
        end
        object ModelBox: TComboBox
          Left = 152
          Top = 36
          Width = 400
          Height = 23
          Style = csDropDownList
          TabOrder = 4
        end
        object SecurityBox: TComboBox
          Left = 152
          Top = 72
          Width = 240
          Height = 23
          Style = csDropDownList
          TabOrder = 5
        end
        object PasswordKindBox: TComboBox
          Left = 402
          Top = 72
          Width = 170
          Height = 23
          Style = csDropDownList
          TabOrder = 6
        end
        object CurveBox: TComboBox
          Left = 582
          Top = 72
          Width = 230
          Height = 23
          Style = csDropDownList
          TabOrder = 7
        end
        object PasswordEdit: TEdit
          Left = 152
          Top = 108
          Width = 400
          Height = 23
          MaxLength = 24
          PasswordChar = '*'
          TabOrder = 8
        end
        object LibraryEdit: TEdit
          Left = 152
          Top = 144
          Width = 660
          Height = 23
          TabOrder = 9
        end
        object NdefEdit: TEdit
          Left = 152
          Top = 180
          Width = 820
          Height = 23
          MaxLength = 2097152
          TabOrder = 10
          Text = 'D101055402656E4869'
        end
        object TextEdit: TEdit
          Left = 152
          Top = 216
          Width = 660
          Height = 23
          TabOrder = 11
          Text = 'Hello'
        end
        object EncodeButton: TButton
          Left = 832
          Top = 216
          Width = 140
          Height = 28
          Caption = 'Encode text'
          TabOrder = 12
          OnClick = EncodeClick
        end
      end
      object MemoryTab: TTabSheet
        Caption = 'Contact memory / reader capabilities'
        ImageIndex = 1
        object MemoryActionLabel: TLabel
          Left = 8
          Top = 4
          Width = 130
          Height = 23
          Caption = 'Operation'
        end
        object MemoryActionBox: TComboBox
          Left = 152
          Top = 0
          Width = 430
          Height = 23
          TabOrder = 0
          Style = csDropDownList
        end
        object MemoryRunButton: TButton
          Left = 600
          Top = 0
          Width = 350
          Height = 23
          Caption = 'Run memory operation'
          TabOrder = 1
          OnClick = MemoryRunClick
        end
        object MemoryModelLabel: TLabel
          Left = 8
          Top = 40
          Width = 130
          Height = 23
          Caption = 'Actual chip / reader'
        end
        object MemoryModelBox: TComboBox
          Left = 152
          Top = 36
          Width = 300
          Height = 23
          TabOrder = 2
          Style = csDropDownList
        end
        object MemoryDialectBox: TComboBox
          Left = 470
          Top = 36
          Width = 480
          Height = 23
          TabOrder = 3
          Style = csDropDownList
        end
        object MemoryRangeLabel: TLabel
          Left = 8
          Top = 76
          Width = 330
          Height = 23
          Caption = 'Address / count / special-chip readable bytes'
        end
        object MemoryAddressEdit: TEdit
          Left = 352
          Top = 72
          Width = 120
          Height = 23
          TabOrder = 4
          Text = '0'
          MaxLength = 6
        end
        object MemoryCountEdit: TEdit
          Left = 488
          Top = 72
          Width = 120
          Height = 23
          TabOrder = 5
          Text = '16'
          MaxLength = 6
        end
        object CounterWindowEdit: TEdit
          Left = 624
          Top = 72
          Width = 120
          Height = 23
          TabOrder = 6
          Text = '0'
          MaxLength = 3
        end
        object MemoryDataLabel: TLabel
          Left = 8
          Top = 112
          Width = 130
          Height = 23
          Caption = 'Write bytes (hex)'
        end
        object MemoryDataEdit: TEdit
          Left = 152
          Top = 108
          Width = 798
          Height = 23
          TabOrder = 7
          MaxLength = 262144
        end
        object MemoryPinLabel: TLabel
          Left = 8
          Top = 148
          Width = 130
          Height = 23
          Caption = 'PIN (hex, card order)'
        end
        object MemoryPinEdit: TEdit
          Left = 152
          Top = 144
          Width = 160
          Height = 23
          TabOrder = 8
          MaxLength = 6
          PasswordChar = '*'
        end
        object MemoryWriteCheck: TCheckBox
          Left = 352
          Top = 144
          Width = 598
          Height = 23
          Caption = 'Allow changing the selected main-memory range'
          TabOrder = 9
        end
        object MemoryPolicyLabel: TLabel
          Left = 8
          Top = 184
          Width = 330
          Height = 23
          Caption = 'I2C page size / minimum PIN attempts'
        end
        object MemoryPageBox: TComboBox
          Left = 352
          Top = 180
          Width = 220
          Height = 23
          TabOrder = 10
          Style = csDropDownList
        end
        object MemoryAttemptsEdit: TEdit
          Left = 592
          Top = 180
          Width = 120
          Height = 23
          TabOrder = 11
          Text = '1'
          MaxLength = 1
        end
        object MemoryGuidance: TLabel
          Left = 8
          Top = 220
          Width = 944
          Height = 23
          Caption = 'Select the actual chip and reader profile. Special-chip window comes from the chip layout. No automatic retry.'
        end
      end
    end
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 360
    Width = 680
    Height = 274
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object SavePhotoButton: TButton
    Left = 716
    Top = 606
    Width = 264
    Height = 28
    Anchors = [akRight, akBottom]
    Caption = 'Save encoded photo...'
    Enabled = False
    TabOrder = 2
    OnClick = SavePhotoClick
  end
  object PhotoDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Left = 940
    Top = 360
  end
end
