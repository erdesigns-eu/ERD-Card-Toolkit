object MagStripeForm: TMagStripeDemoForm
  Caption = 'ERD Cards - magnetic tracks / MSR206-7HL demo'
  ClientHeight = 500
  ClientWidth = 900
  Constraints.MinHeight = 500
  Constraints.MinWidth = 900
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
    Width = 900
    Height = 300
    Align = alTop
    BevelOuter = bvNone
    object PortLabel: TLabel
      Left = 16
      Top = 16
      Width = 165
      Height = 20
      Caption = 'MSR206-7HL COM port'
    end
    object PortEdit: TEdit
      TabOrder = 0
      Left = 190
      Top = 12
      Width = 160
      Height = 25
      Text = ''
    end
    object TimeoutLabel: TLabel
      Left = 380
      Top = 16
      Width = 120
      Height = 20
      Caption = 'Timeout ms'
    end
    object TimeoutEdit: TEdit
      TabOrder = 1
      Left = 480
      Top = 12
      Width = 120
      Height = 25
      Text = '10000'
    end
    object CoercivityLabel: TLabel
      Left = 16
      Top = 52
      Width = 165
      Height = 20
      Caption = 'Write coercivity'
    end
    object CoercivityBox: TComboBox
      TabOrder = 2
      Left = 190
      Top = 48
      Width = 210
      Height = 25
      Style = csDropDownList
    end
    object Track1Check: TCheckBox
      TabOrder = 3
      Left = 16
      Top = 92
      Width = 165
      Height = 25
      Caption = 'Select track 1'
      Checked = True
      State = cbChecked
    end
    object Track1Edit: TEdit
      TabOrder = 4
      Left = 190
      Top = 92
      Width = 680
      Height = 25
      Text = ''
      MaxLength = 76
    end
    object Track2Check: TCheckBox
      TabOrder = 5
      Left = 16
      Top = 132
      Width = 165
      Height = 25
      Caption = 'Select track 2'
      Checked = True
      State = cbChecked
    end
    object Track2Edit: TEdit
      TabOrder = 6
      Left = 190
      Top = 132
      Width = 680
      Height = 25
      Text = ''
      MaxLength = 37
    end
    object Track3Check: TCheckBox
      TabOrder = 7
      Left = 16
      Top = 172
      Width = 165
      Height = 25
      Caption = 'Select track 3'
      Checked = True
      State = cbChecked
    end
    object Track3Edit: TEdit
      TabOrder = 8
      Left = 190
      Top = 172
      Width = 680
      Height = 25
      Text = ''
      MaxLength = 104
    end
    object InspectButton: TButton
      TabOrder = 9
      Left = 16
      Top = 222
      Width = 200
      Height = 28
      Caption = 'Inspect tracks offline'
      OnClick = InspectClick
    end
    object ReadButton: TButton
      TabOrder = 10
      Left = 236
      Top = 222
      Width = 200
      Height = 28
      Caption = 'Read one swipe'
      OnClick = ReadClick
    end
    object WriteButton: TButton
      TabOrder = 11
      Left = 456
      Top = 222
      Width = 250
      Height = 28
      Caption = 'Write selected + verify'
      OnClick = WriteClick
    end
    object GuideLabel: TLabel
      Left = 16
      Top = 268
      Width = 868
      Height = 20
      Caption = 'Payloads exclude sentinels and LRC. Write selected + verify programs the selected tracks; device is MSR206-7HL (9600 / 7O1).'
    end
  end
  object OutputMemo: TMemo
    TabOrder = 1
    Left = 16
    Top = 312
    Width = 868
    Height = 172
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
  end
end
