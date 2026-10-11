object DesfirePersonalizationDemoForm: TDesfirePersonalizationDemoForm
  Caption = 'DesfirePersonalizationDemo'
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
    Caption = 'Explicit ordered DESFire creation, population, key rotation and access policy. Keys stay in the masked field; the profile contains credential indexes only.'
    AutoSize = False
    WordWrap = True
  end
  object SourceLabel: TLabel
    Left = 16
    Top = 60
    Width = 400
    Height = 20
    Caption = 'Available reader / writer'
  end
  object SourceReaderBox: TComboBox
    Left = 16
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
    Caption = 'Explicit workflow action'
  end
  object ModelLabel: TLabel
    Left = 360
    Top = 157
    Width = 420
    Height = 20
    Caption = 'Explicit model / security'
  end
  object ActionBox: TComboBox
    Left = 16
    Top = 180
    Width = 330
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Execute profile / checked resume'
      'Verify entire completed prefix only'
      'Acquire native manufacturing UID'
    )
  end
  object ModelBox: TComboBox
    Left = 360
    Top = 180
    Width = 624
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Public'
      'EV2 AES'
      'EV1 AES'
      'ISO 2K3DES'
      'ISO 3K3DES'
      'Legacy DES'
      'Legacy 2K3DES'
    )
  end
  object SourceKeyLabel: TLabel
    Left = 16
    Top = 222
    Width = 310
    Height = 20
    Caption = 'Key list (hex keys separated by semicolons)'
  end
  object TargetKeyLabel: TLabel
    Left = 360
    Top = 222
    Width = 420
    Height = 20
    Caption = 'Content snapshot file path (optional)'
  end
  object CoercivityLabel: TLabel
    Left = 750
    Top = 222
    Width = 220
    Height = 20
    Caption = 'Unused'
    Visible = False
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
      'ACR38x CCID only'
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
    Lines.Strings = (
      'ERD-DESFIRE-PERSONALIZE 1'
      '1|2|0|0|0|1|0|1|-1'
      '1|4|0|1|0|2|0|0|0|0'
      '1|5|0|1|15'
    )
  end
  object LoadButton: TButton
    Left = 16
    Top = 510
    Width = 150
    Height = 30
    Caption = 'Load plan/profile'
    OnClick = LoadClick
  end
  object SaveButton: TButton
    Left = 180
    Top = 510
    Width = 150
    Height = 30
    Caption = 'Save displayed text'
    OnClick = SaveClick
  end
  object RangeEdit: TEdit
    Left = 16
    Top = 555
    Width = 968
    Height = 25
    ParentShowHint = False
    Text = '00000000000000|0|65536|48|0'
    Hint = 'Native UID hex|completed prefix|transfer bytes|frame bytes|minimum communication'
    ShowHint = True
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 592
    Width = 968
    Height = 152
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
