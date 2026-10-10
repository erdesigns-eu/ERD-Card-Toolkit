object EmvSemanticsDemoForm: TEmvSemanticsDemoForm
  Caption = 'Offline EMV semantic decoding'
  ClientHeight = 560
  ClientWidth = 900
  Font.Name = 'Segoe UI'
  Font.Height = -13
  Position = poScreenCenter
  OnCreate = FormCreate
  object TagLabel: TLabel
    Left = 16
    Top = 16
    Caption = 'Data object'
  end
  object TagBox: TComboBox
    Left = 16
    Top = 40
    Width = 400
    Height = 25
    Style = csDropDownList
    TabOrder = 0
    OnChange = TagChanged
    Items.Strings = (
      '82 - AIP'
      '9F07 - AUC'
      '95 - TVR'
      '9F0D - IAC Default'
      '9F0E - IAC Denial'
      '9F0F - IAC Online'
      '8E - CVM List')
  end
  object VersionLabel: TLabel
    Left = 440
    Top = 16
    Caption = 'Book 3 specification'
  end
  object VersionBox: TComboBox
    Left = 440
    Top = 40
    Width = 440
    Height = 25
    Style = csDropDownList
    TabOrder = 1
    OnChange = TagChanged
    Items.Strings = (
      'EMV 4.3'
      'EMV 4.4 (XDA / biometric meanings)')
  end
  object ValueLabel: TLabel
    Left = 16
    Top = 88
    Caption = 'Hexadecimal value'
  end
  object ValueEdit: TEdit
    Left = 16
    Top = 112
    Width = 864
    Height = 25
    TabOrder = 2
  end
  object ShowUnsetCheck: TCheckBox
    Left = 16
    Top = 156
    Width = 200
    Height = 24
    Caption = 'Show unset bits'
    TabOrder = 3
  end
  object ShowReservedCheck: TCheckBox
    Left = 230
    Top = 156
    Width = 270
    Height = 24
    Caption = 'Show reserved bits'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object ExampleButton: TButton
    Left = 520
    Top = 154
    Width = 170
    Height = 28
    Caption = 'Synthetic example'
    TabOrder = 5
    OnClick = ExampleClick
  end
  object DecodeButton: TButton
    Left = 710
    Top = 154
    Width = 170
    Height = 28
    Caption = 'Decode offline'
    TabOrder = 6
    OnClick = DecodeClick
  end
  object HelpMemo: TMemo
    Left = 16
    Top = 200
    Width = 864
    Height = 74
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 7
    TabStop = False
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 292
    Width = 864
    Height = 248
    ReadOnly = True
    ScrollBars = ssBoth
    Font.Name = 'Consolas'
    WordWrap = False
    TabOrder = 8
  end
end
