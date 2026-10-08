object SmartCardForm: TSmartCardDemoForm
  Caption = 'ERD Cards - PC/SC read and write demo'
  ClientHeight = 650
  ClientWidth = 1000
  Constraints.MinHeight = 650
  Constraints.MinWidth = 1000
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  object InputPanel: TPanel
    TabOrder = 0
    Left = 0
    Top = 0
    Width = 1000
    Height = 320
    Align = alTop
    BevelOuter = bvNone
    object ReaderLabel: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 20
      Caption = 'Exact PC/SC reader'
    end
    object ReaderBox: TComboBox
      TabOrder = 0
      Left = 160
      Top = 12
      Width = 660
      Height = 25
      Style = csDropDown
    end
    object ReadersButton: TButton
      TabOrder = 1
      Left = 840
      Top = 12
      Width = 140
      Height = 28
      Caption = 'List readers'
      OnClick = ReadersClick
    end
    object OperationLabel: TLabel
      Left = 16
      Top = 52
      Width = 120
      Height = 20
      Caption = 'Operation'
    end
    object OperationBox: TComboBox
      TabOrder = 2
      Left = 160
      Top = 48
      Width = 400
      Height = 25
      Style = csDropDownList
    end
    object RunButton: TButton
      TabOrder = 3
      Left = 590
      Top = 48
      Width = 230
      Height = 28
      Caption = 'Run selected operation'
      OnClick = RunClick
    end
    object ModelLabel: TLabel
      Left = 16
      Top = 88
      Width = 120
      Height = 20
      Caption = 'Type 2 model'
    end
    object ModelBox: TComboBox
      TabOrder = 4
      Left = 160
      Top = 84
      Width = 400
      Height = 25
      Style = csDropDownList
    end
    object AccessLabel: TLabel
      Left = 16
      Top = 124
      Width = 120
      Height = 20
      Caption = 'ICAO access'
    end
    object SecurityBox: TComboBox
      TabOrder = 5
      Left = 160
      Top = 120
      Width = 240
      Height = 25
      Style = csDropDownList
    end
    object PasswordKindBox: TComboBox
      TabOrder = 6
      Left = 410
      Top = 120
      Width = 170
      Height = 25
      Style = csDropDownList
    end
    object CurveBox: TComboBox
      TabOrder = 7
      Left = 590
      Top = 120
      Width = 230
      Height = 25
      Style = csDropDownList
    end
    object PasswordLabel: TLabel
      Left = 16
      Top = 160
      Width = 120
      Height = 20
      Caption = 'MRZ info / CAN'
    end
    object PasswordEdit: TEdit
      TabOrder = 8
      Left = 160
      Top = 156
      Width = 400
      Height = 25
      Text = ''
      PasswordChar = '*'
      MaxLength = 24
    end
    object LibraryLabel: TLabel
      Left = 16
      Top = 196
      Width = 120
      Height = 20
      Caption = 'OpenSSL 3 library'
    end
    object LibraryEdit: TEdit
      TabOrder = 9
      Left = 160
      Top = 192
      Width = 660
      Height = 25
      Text = ''
    end
    object NdefLabel: TLabel
      Left = 16
      Top = 232
      Width = 120
      Height = 20
      Caption = 'NDEF hex'
    end
    object NdefEdit: TEdit
      TabOrder = 10
      Left = 160
      Top = 228
      Width = 820
      Height = 25
      Text = 'D101055402656E4869'
      MaxLength = 2097152
    end
    object TextLabel: TLabel
      Left = 16
      Top = 268
      Width = 120
      Height = 20
      Caption = 'Offline NDEF text'
    end
    object TextEdit: TEdit
      TabOrder = 11
      Left = 160
      Top = 264
      Width = 660
      Height = 25
      Text = 'Hello'
    end
    object EncodeButton: TButton
      TabOrder = 12
      Left = 840
      Top = 264
      Width = 140
      Height = 28
      Caption = 'Encode text'
      OnClick = EncodeClick
    end
    object ProfileLabel: TLabel
      Left = 16
      Top = 300
      Width = 965
      Height = 20
      Caption = 'UID / Type 2: explicit FF CA / FF B0 / FF D6 profile. Replace operations overwrite existing NDEF and verify read-back.'
    end
  end
  object OutputMemo: TMemo
    TabOrder = 1
    Left = 16
    Top = 336
    Width = 680
    Height = 298
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
  end
  object PhotoImage: TImage
    Left = 716
    Top = 336
    Width = 264
    Height = 252
    Anchors = [akTop, akRight]
    Center = True
    Proportional = True
    Stretch = True
  end
  object SavePhotoButton: TButton
    TabOrder = 2
    Left = 716
    Top = 606
    Width = 264
    Height = 28
    Anchors = [akRight, akBottom]
    Enabled = False
    Caption = 'Save encoded photo...'
    OnClick = SavePhotoClick
  end
  object PhotoDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Left = 940
    Top = 360
  end
end
