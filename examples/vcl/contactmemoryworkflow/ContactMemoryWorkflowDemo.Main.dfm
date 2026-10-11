object ContactMemoryWorkflowDemoForm: TContactMemoryWorkflowDemoForm
  Caption = 'ContactMemoryWorkflowDemo'
  ClientHeight = 760
  ClientWidth = 1000
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  object GuideLabel: TLabel
    Left = 16
    Top = 12
    Width = 968
    Height = 40
    Caption = 'Complete SLE/I2C backup and selected-byte restore. Existing protected bytes are checked before writing; no general chip UID is available.'
    AutoSize = False
    WordWrap = True
  end
  object SourceLabel: TLabel
    Left = 16
    Top = 60
    Width = 400
    Height = 20
    Caption = 'Source reader / port'
  end
  object TargetLabel: TLabel
    Left = 510
    Top = 60
    Width = 400
    Height = 20
    Caption = 'Target reader / port'
  end
  object SourceReaderBox: TComboBox
    Left = 16
    Top = 84
    Width = 474
    Height = 25
    Style = csDropDownList
  end
  object TargetReaderBox: TComboBox
    Left = 510
    Top = 84
    Width = 474
    Height = 25
    Style = csDropDownList
  end
  object EventStatusLabel: TLabel
    Left = 16
    Top = 120
    Width = 770
    Height = 20
    Caption = 'Reader/card events appear here.'
    AutoSize = False
  end
  object RefreshButton: TButton
    Left = 810
    Top = 115
    Width = 174
    Height = 30
    Caption = 'Refresh devices'
    OnClick = RefreshClick
  end
  object ActionLabel: TLabel
    Left = 16
    Top = 157
    Width = 350
    Height = 20
    Caption = 'Action (copy/compare require two readers)'
  end
  object ModelLabel: TLabel
    Left = 360
    Top = 157
    Width = 420
    Height = 20
    Caption = 'Explicit contact-memory model'
  end
  object ActionBox: TComboBox
    Left = 16
    Top = 180
    Width = 330
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Capture source / backup'
      'Copy source to target'
      'Compare memory only'
      'Restore snapshot / write template'
    )
  end
  object ModelBox: TComboBox
    Left = 360
    Top = 180
    Width = 624
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'SLE4432'
      'SLE4442'
      'SLE5532'
      'SLE5542'
      'SLE4418'
      'SLE4428'
      'SLE5518'
      'SLE5528'
      'I2C 1 Kbit'
      'I2C 2 Kbit'
      'I2C 4 Kbit'
      'I2C 8 Kbit'
      'I2C 16 Kbit'
      'I2C 32 Kbit'
      'I2C 64 Kbit'
      'I2C 128 Kbit'
      'I2C 256 Kbit'
      'I2C 512 Kbit'
      'I2C 1024 Kbit'
    )
  end
  object SourceKeyLabel: TLabel
    Left = 16
    Top = 222
    Width = 310
    Height = 20
    Caption = 'I2C page bytes (8/16/32/64/128)'
  end
  object TargetKeyLabel: TLabel
    Left = 360
    Top = 222
    Width = 420
    Height = 20
    Caption = 'Target PIN (hex; empty for unsecured chips)'
  end
  object CoercivityLabel: TLabel
    Left = 750
    Top = 222
    Width = 220
    Height = 20
    Caption = 'ACS reader dialect'
  end
  object SourceKeyEdit: TEdit
    Left = 16
    Top = 245
    Width = 330
    Height = 25
  end
  object TargetKeyEdit: TEdit
    Left = 360
    Top = 245
    Width = 370
    Height = 25
    PasswordChar = '*'
  end
  object CoercivityBox: TComboBox
    Left = 750
    Top = 245
    Width = 234
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'ACR38 CCID'
      'ACR39'
    )
  end
  object AcknowledgeCheck: TCheckBox
    Left = 16
    Top = 284
    Width = 660
    Height = 25
    Caption = 'I intend to write the selected target card.'
  end
  object RunButton: TButton
    Left = 810
    Top = 280
    Width = 174
    Height = 32
    Caption = 'Run workflow once'
    OnClick = RunClick
  end
  object SnapshotMemo: TMemo
    Left = 16
    Top = 328
    Width = 968
    Height = 170
    ScrollBars = ssBoth
    WordWrap = False
  end
  object LoadButton: TButton
    Left = 16
    Top = 510
    Width = 150
    Height = 30
    Caption = 'Load snapshot/template'
    OnClick = LoadClick
  end
  object SaveButton: TButton
    Left = 180
    Top = 510
    Width = 150
    Height = 30
    Caption = 'Save snapshot/template'
    OnClick = SaveClick
  end
  object RangeEdit: TEdit
    Left = 535
    Top = 513
    Width = 220
    Height = 25
    Text = '0,256,1'
    Hint = 'First byte,count,minimum PIN attempts'
    ShowHint = True
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 555
    Width = 968
    Height = 189
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object WorkerTimer: TTimer
    Interval = 100
    OnTimer = PollTimer
    Left = 400
    Top = 510
  end
  object OpenDialog: TOpenDialog
    Left = 440
    Top = 510
  end
  object SaveDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofPathMustExist, ofEnableSizing]
    Left = 480
    Top = 510
  end
end
