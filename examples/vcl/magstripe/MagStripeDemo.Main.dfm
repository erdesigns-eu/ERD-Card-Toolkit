object MagStripeDemoForm: TMagStripeDemoForm
  Left = 0
  Top = 0
  Caption = 'ERD Cards - magnetic tracks / MSR206-7HL demo'
  ClientHeight = 500
  ClientWidth = 900
  Color = clBtnFace
  Constraints.MinHeight = 500
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    900
    500)
  TextHeight = 15
  object InputPanel: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 300
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object PortLabel: TLabel
      Left = 16
      Top = 16
      Width = 124
      Height = 15
      Caption = 'MSR206-7HL COM port'
    end
    object TimeoutLabel: TLabel
      Left = 380
      Top = 16
      Width = 64
      Height = 15
      Caption = 'Timeout ms'
    end
    object CoercivityLabel: TLabel
      Left = 16
      Top = 52
      Width = 82
      Height = 15
      Caption = 'Write coercivity'
    end
    object GuideLabel: TLabel
      Left = 16
      Top = 268
      Width = 655
      Height = 15
      Caption = 
        'Payloads exclude sentinels and LRC. Write selected + verify prog' +
        'rams the selected tracks; device is MSR206-7HL (9600 / 7O1).'
    end
    object PortEdit: TEdit
      Left = 190
      Top = 12
      Width = 160
      Height = 23
      TabOrder = 0
    end
    object TimeoutEdit: TEdit
      Left = 480
      Top = 12
      Width = 120
      Height = 23
      TabOrder = 1
      Text = '10000'
    end
    object CoercivityBox: TComboBox
      Left = 190
      Top = 48
      Width = 210
      Height = 23
      Style = csDropDownList
      TabOrder = 2
    end
    object Track1Check: TCheckBox
      Left = 16
      Top = 92
      Width = 165
      Height = 25
      Caption = 'Select track 1'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object Track1Edit: TEdit
      Left = 190
      Top = 92
      Width = 680
      Height = 23
      MaxLength = 76
      TabOrder = 4
    end
    object Track2Check: TCheckBox
      Left = 16
      Top = 132
      Width = 165
      Height = 25
      Caption = 'Select track 2'
      Checked = True
      State = cbChecked
      TabOrder = 5
    end
    object Track2Edit: TEdit
      Left = 190
      Top = 132
      Width = 680
      Height = 23
      MaxLength = 37
      TabOrder = 6
    end
    object Track3Check: TCheckBox
      Left = 16
      Top = 172
      Width = 165
      Height = 25
      Caption = 'Select track 3'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object Track3Edit: TEdit
      Left = 190
      Top = 172
      Width = 680
      Height = 23
      MaxLength = 104
      TabOrder = 8
    end
    object InspectButton: TButton
      Left = 16
      Top = 222
      Width = 200
      Height = 28
      Caption = 'Inspect tracks offline'
      TabOrder = 9
      OnClick = InspectClick
    end
    object ReadButton: TButton
      Left = 236
      Top = 222
      Width = 200
      Height = 28
      Caption = 'Read one swipe'
      TabOrder = 10
      OnClick = ReadClick
    end
    object WriteButton: TButton
      Left = 456
      Top = 222
      Width = 250
      Height = 28
      Caption = 'Write selected + verify'
      TabOrder = 11
      OnClick = WriteClick
    end
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 312
    Width = 868
    Height = 172
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
