object ClassicWorkflowDemoForm: TClassicWorkflowDemoForm
  Caption = 'ClassicWorkflowDemo'
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
    Caption = 'Classic data blocks; sector keys are supplied separately. For one reader: capture, swap card, restore.'
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
    Caption = 'Explicit model / profile / tracks'
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
      'Explicit sector key/access migration'
    )
  end
  object ModelBox: TComboBox
    Left = 360
    Top = 180
    Width = 624
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Mini'
      '1K'
      '4K'
    )
  end
  object SourceKeyLabel: TLabel
    Left = 16
    Top = 222
    Width = 310
    Height = 20
    Caption = 'Source Key A / new Key A (sector action)'
  end
  object TargetKeyLabel: TLabel
    Left = 360
    Top = 222
    Width = 420
    Height = 20
    Caption = 'Target Key A / Gen4 password (hex)'
  end
  object CoercivityLabel: TLabel
    Left = 750
    Top = 222
    Width = 220
    Height = 20
    Caption = 'Stripe coercivity'
  end
  object SourceKeyEdit: TEdit
    Left = 16
    Top = 245
    Width = 330
    Height = 25
    PasswordChar = '*'
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
      'Low coercivity'
      'High coercivity'
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
  object NewKeyBLabel: TLabel
    Left = 16
    Top = 328
    Width = 330
    Height = 20
    Caption = 'New Key B (sector action, hex)'
  end
  object NewKeyBEdit: TEdit
    Left = 16
    Top = 352
    Width = 330
    Height = 25
    PasswordChar = '*'
  end
  object AccessBitsLabel: TLabel
    Left = 360
    Top = 328
    Width = 620
    Height = 20
    Caption = 'Access bytes + GPB (hex); sector action uses one trailer address per line below'
  end
  object AccessBitsEdit: TEdit
    Left = 360
    Top = 352
    Width = 624
    Height = 25
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
