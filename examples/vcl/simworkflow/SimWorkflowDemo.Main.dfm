object SimWorkflowDemoForm: TSimWorkflowDemoForm
  Caption = 'SIM / USIM workflows'
  ClientHeight = 890
  ClientWidth = 1040
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  object GuideLabel: TLabel
    AutoSize = False
    WordWrap = True
    Left = 16
    Top = 12
    Width = 1000
    Height = 30
    Caption = 'Capture/export, preview a restore or offline import, then explicitly apply the reviewed plan. Contacts and SMS stay on the card; no sending.'
  end
  object SourceLabel: TLabel
    Left = 16
    Top = 47
    Width = 470
    Height = 22
    Caption = 'Source / inspection reader'
  end
  object TargetLabel: TLabel
    Left = 530
    Top = 47
    Width = 480
    Height = 22
    Caption = 'Target reader for preview / apply'
  end
  object SourceReaderBox: TComboBox
    Left = 16
    Top = 72
    Width = 490
    Height = 25
    Style = csDropDownList
    Items.Strings = (
    )
  end
  object TargetReaderBox: TComboBox
    Left = 530
    Top = 72
    Width = 494
    Height = 25
    Style = csDropDownList
    Items.Strings = (
    )
  end
  object EventStatusLabel: TLabel
    Left = 16
    Top = 109
    Width = 830
    Height = 22
    Caption = 'Reader/card events appear here.'
  end
  object RefreshButton: TButton
    Left = 870
    Top = 104
    Width = 154
    Height = 30
    Caption = 'Refresh readers'
    OnClick = RefreshClick
  end
  object ActionLabel: TLabel
    Left = 16
    Top = 146
    Width = 700
    Height = 22
    Caption = 'Action'
  end
  object ModelLabel: TLabel
    Left = 790
    Top = 146
    Width = 234
    Height = 22
    Caption = 'Explicit SIM profile'
  end
  object ActionBox: TComboBox
    Left = 16
    Top = 172
    Width = 750
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Capture contacts'
      'Capture SMS'
      'Preview exact restore'
      'Apply reviewed plan'
      'Plan contact import (offline)'
      'Plan SMS import (offline)'
      'Inspect SIM / USIM'
      'Assemble explicit SMS group (offline)'
      'Report snapshot (offline)'
      'Plan multipart SMS import (offline)'
    )
  end
  object ModelBox: TComboBox
    Left = 790
    Top = 172
    Width = 234
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Classic GSM SIM'
      'UICC / USIM'
    )
  end
  object SourceKeyLabel: TLabel
    Left = 16
    Top = 210
    Width = 470
    Height = 22
    Caption = 'Full USIM AID (hex; empty for classic)'
  end
  object TargetKeyLabel: TLabel
    Left = 530
    Top = 210
    Width = 245
    Height = 22
    Caption = 'Optional PIN (ASCII digits)'
  end
  object CoercivityLabel: TLabel
    Left = 800
    Top = 210
    Width = 224
    Height = 22
    Caption = 'Minimum PIN retries'
  end
  object SourceKeyEdit: TEdit
    Left = 16
    Top = 235
    Width = 490
    Height = 25
  end
  object TargetKeyEdit: TEdit
    Left = 530
    Top = 235
    Width = 245
    Height = 25
    PasswordChar = '*'
  end
  object CoercivityBox: TComboBox
    Left = 800
    Top = 235
    Width = 224
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      '1'
      '2'
      '3'
      '4'
      '5'
      '6'
      '7'
      '8'
      '9'
      '10'
      '11'
      '12'
      '13'
      '14'
      '15'
    )
  end
  object AddressLabel: TLabel
    Left = 16
    Top = 272
    Width = 750
    Height = 22
    Caption = 'Actual EF: 0=master, 1=USIM root | comma-separated FIDs in hex'
  end
  object PbrLabel: TLabel
    Left = 800
    Top = 272
    Width = 224
    Height = 22
    Caption = 'PBR record (0=standalone/SMS)'
  end
  object RangeEdit: TEdit
    Left = 16
    Top = 297
    Width = 750
    Height = 25
    Text = '0|7F10,6F3A'
  end
  object PbrEdit: TEdit
    Left = 800
    Top = 297
    Width = 224
    Height = 25
    Text = '0'
  end
  object AcknowledgeCheck: TCheckBox
    Left = 16
    Top = 337
    Width = 750
    Height = 25
    Caption = 'I intend to apply this reviewed plan to the selected target SIM.'
  end
  object RunButton: TButton
    Left = 800
    Top = 332
    Width = 224
    Height = 32
    Caption = 'Run workflow once'
    OnClick = RunClick
  end
  object SnapshotLabel: TLabel
    Left = 16
    Top = 376
    Width = 720
    Height = 22
    Caption = 'Complete snapshot or reviewed target-bound plan'
  end
  object SnapshotMemo: TMemo
    Left = 16
    Top = 402
    Width = 1008
    Height = 145
    ScrollBars = ssBoth
    WordWrap = False
  end
  object LoadButton: TButton
    Left = 16
    Top = 557
    Width = 155
    Height = 30
    Caption = 'Load snapshot / plan'
    OnClick = LoadClick
  end
  object SaveButton: TButton
    Left = 186
    Top = 557
    Width = 155
    Height = 30
    Caption = 'Save snapshot / plan'
    OnClick = SaveClick
  end
  object ImportLabel: TLabel
    Left = 16
    Top = 604
    Width = 1008
    Height = 22
    Caption = 'Offline import: name TAB number [TAB email TAB ANR] per line; SMS import/group: complete record hex separated by semicolons'
  end
  object IncludeClassicExtCheck: TCheckBox
    Left = 530
    Top = 557
    Width = 490
    Height = 25
    Caption = 'Include standard classic EXT1 in contact backup'
  end
  object ImportMemo: TMemo
    Left = 16
    Top = 630
    Width = 1008
    Height = 90
    ScrollBars = ssBoth
    WordWrap = False
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 738
    Width = 1008
    Height = 140
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object WorkerTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = PollTimer
    Left = 940
    Top = 557
  end
  object OpenDialog: TOpenDialog
    Filter = 'SIM snapshot / plan|*.erdsnapshot;*.erdplan|All files|*.*'
    Left = 900
    Top = 557
  end
  object SaveDialog: TSaveDialog
    Filter = 'SIM snapshot / plan|*.erdsnapshot;*.erdplan|All files|*.*'
    Left = 860
    Top = 557
  end
end
