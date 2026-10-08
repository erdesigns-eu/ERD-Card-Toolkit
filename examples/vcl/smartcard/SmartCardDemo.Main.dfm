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
    Top = 336
    Width = 264
    Height = 252
    Anchors = [akTop, akRight]
    Center = True
    Proportional = True
    Stretch = True
  end
  object InputPanel: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 320
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
    object OperationLabel: TLabel
      Left = 16
      Top = 52
      Width = 53
      Height = 15
      Caption = 'Operation'
    end
    object ModelLabel: TLabel
      Left = 16
      Top = 88
      Width = 71
      Height = 15
      Caption = 'Type 2 model'
    end
    object AccessLabel: TLabel
      Left = 16
      Top = 124
      Width = 65
      Height = 15
      Caption = 'ICAO access'
    end
    object PasswordLabel: TLabel
      Left = 16
      Top = 160
      Width = 85
      Height = 15
      Caption = 'MRZ info / CAN'
    end
    object LibraryLabel: TLabel
      Left = 16
      Top = 196
      Width = 92
      Height = 15
      Caption = 'OpenSSL 3 library'
    end
    object NdefLabel: TLabel
      Left = 16
      Top = 232
      Width = 50
      Height = 15
      Caption = 'NDEF hex'
    end
    object TextLabel: TLabel
      Left = 16
      Top = 268
      Width = 90
      Height = 15
      Caption = 'Offline NDEF text'
    end
    object ProfileLabel: TLabel
      Left = 16
      Top = 300
      Width = 604
      Height = 15
      Caption = 
        'UID / Type 2: explicit FF CA / FF B0 / FF D6 profile. Replace op' +
        'erations overwrite existing NDEF and verify read-back.'
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
    object OperationBox: TComboBox
      Left = 160
      Top = 48
      Width = 400
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
    object RunButton: TButton
      Left = 590
      Top = 48
      Width = 230
      Height = 28
      Caption = 'Run selected operation'
      TabOrder = 3
      OnClick = RunClick
    end
    object ModelBox: TComboBox
      Left = 160
      Top = 84
      Width = 400
      Height = 23
      Style = csDropDownList
      TabOrder = 4
    end
    object SecurityBox: TComboBox
      Left = 160
      Top = 120
      Width = 240
      Height = 23
      Style = csDropDownList
      TabOrder = 5
    end
    object PasswordKindBox: TComboBox
      Left = 410
      Top = 120
      Width = 170
      Height = 23
      Style = csDropDownList
      TabOrder = 6
    end
    object CurveBox: TComboBox
      Left = 590
      Top = 120
      Width = 230
      Height = 23
      Style = csDropDownList
      TabOrder = 7
    end
    object PasswordEdit: TEdit
      Left = 160
      Top = 156
      Width = 400
      Height = 23
      MaxLength = 24
      PasswordChar = '*'
      TabOrder = 8
    end
    object LibraryEdit: TEdit
      Left = 160
      Top = 192
      Width = 660
      Height = 23
      TabOrder = 9
    end
    object NdefEdit: TEdit
      Left = 160
      Top = 228
      Width = 820
      Height = 23
      MaxLength = 2097152
      TabOrder = 10
      Text = 'D101055402656E4869'
    end
    object TextEdit: TEdit
      Left = 160
      Top = 264
      Width = 660
      Height = 23
      TabOrder = 11
      Text = 'Hello'
    end
    object EncodeButton: TButton
      Left = 840
      Top = 264
      Width = 140
      Height = 28
      Caption = 'Encode text'
      TabOrder = 12
      OnClick = EncodeClick
    end
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 336
    Width = 680
    Height = 298
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
