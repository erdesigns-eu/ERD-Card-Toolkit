object ProtectedType2WorkflowDemoForm: TProtectedType2WorkflowDemoForm
  Caption = 'Protected Type 2 memory and reviewed security workflows'
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
    Caption = 'Type 2: PWD(4)+PACK(2) bytes. ISO: wire-order password; SLIX2 read+write uses 8 bytes. Security actions require uid/before options. Review before apply.'
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
    Caption = 'Explicit card profile'
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
      'Restore snapshot'
      'Preview credential replacement (no I/O)'
      'Apply credential replacement'
      'Preview protection policy (no I/O)'
      'Apply protection policy'
      'Read current protection configuration'
    )
  end
  object ModelBox: TComboBox
    Left = 360
    Top = 180
    Width = 624
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Original Ultralight (no PWD_AUTH)'
      'Ultralight EV1 48'
      'Ultralight EV1 128'
      'NTAG213'
      'NTAG215'
      'NTAG216'
      'NTAG210'
      'NTAG212'
    )
  end
  object SourceKeyLabel: TLabel
    Left = 16
    Top = 222
    Width = 310
    Height = 20
    Caption = 'Source password (hex)'
  end
  object TargetKeyLabel: TLabel
    Left = 360
    Top = 222
    Width = 420
    Height = 20
    Caption = 'Current target password (hex)'
  end
  object ReplacementKeyLabel: TLabel
    Left = 750
    Top = 222
    Width = 220
    Height = 20
    Caption = 'Replacement password (hex)'
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
  object ReplacementKeyEdit: TEdit
    Left = 750
    Top = 245
    Width = 234
    Height = 25
    PasswordChar = '*'
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
  object ConfigMemo: TMemo
    Left = 16
    Top = 328
    Width = 480
    Height = 170
    ScrollBars = ssBoth
    WordWrap = False
    Lines.Strings = (
      'first=4'
      'count=1'
      'uid='
      'before='
      'auth0=255'
      'protectReads=0'
      'authlim=0'
    )
  end
  object SnapshotMemo: TMemo
    Left = 512
    Top = 328
    Width = 472
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
