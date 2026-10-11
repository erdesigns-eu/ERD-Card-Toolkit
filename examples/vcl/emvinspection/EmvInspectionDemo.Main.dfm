object EmvInspectionDemoForm: TEmvInspectionDemoForm
  Left = 0
  Top = 0
  Caption = 'EMV inspection and reports'
  ClientHeight = 760
  ClientWidth = 1040
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  object ReaderLabel: TLabel
    Left = 16
    Top = 16
    Width = 200
    Height = 17
    Caption = 'Available reader'
  end
  object ReaderBox: TComboBox
    Left = 16
    Top = 36
    Width = 710
    Height = 24
    Style = csDropDownList
  end
  object RefreshButton: TButton
    Left = 744
    Top = 34
    Width = 120
    Height = 28
    Caption = 'Refresh readers'
    OnClick = RefreshClick
  end
  object ProfileLabel: TLabel
    Left = 16
    Top = 70
    Width = 200
    Height = 17
    Caption = 'Explicit profile'
  end
  object ProfileBox: TComboBox
    Left = 16
    Top = 90
    Width = 560
    Height = 24
    Style = csDropDownList
    Items.Strings = (
      'Discover PPSE applications only'
      'Inspect exact AIDs / contact PSE'
      'Inspect exact AIDs / contactless PPSE')
  end
  object PasswordLabel: TLabel
    Left = 596
    Top = 70
    Width = 300
    Height = 17
    Caption = 'ICAO access password (MRZ/CAN)'
    Visible = False
  end
  object PasswordEdit: TEdit
    Left = 596
    Top = 90
    Width = 420
    Height = 24
    PasswordChar = '*'
    Visible = False
  end
  object GuideLabel: TLabel
    Left = 16
    Top = 124
    Width = 1000
    Height = 45
    Caption = 'Discover first, then enter exact AIDs separated by semicolons and required pdol.TAG=HEX inputs. GPO runs once per AID. No payments.'
    WordWrap = True
  end
  object ConfigMemo: TMemo
    Left = 16
    Top = 176
    Width = 400
    Height = 176
    ScrollBars = ssBoth
    Lines.Strings = (
      'aids='
      'counters=1'
      'log=1'
      'scan=0'
      'firstSfi=1'
      'lastSfi=10'
      'firstRecord=1'
      'lastRecord=10'
      'maxRecords=256')
  end
  object PersonalCheck: TCheckBox
    Left = 436
    Top = 182
    Width = 400
    Height = 24
    Caption = 'Include personal data in this report'
  end
  object RawCheck: TCheckBox
    Left = 436
    Top = 214
    Width = 400
    Height = 24
    Caption = 'Include raw fields (personal bytes require both options)'
  end
  object RunButton: TButton
    Left = 436
    Top = 256
    Width = 160
    Height = 32
    Caption = 'Read and report'
    OnClick = RunClick
  end
  object SaveTextButton: TButton
    Left = 612
    Top = 256
    Width = 160
    Height = 32
    Caption = 'Save text'
    OnClick = SaveTextClick
  end
  object SaveJsonButton: TButton
    Left = 788
    Top = 256
    Width = 160
    Height = 32
    Caption = 'Save JSON'
    OnClick = SaveJsonClick
  end
  object StatusLabel: TLabel
    Left = 436
    Top = 308
    Width = 568
    Height = 40
    Caption = 'Reader observation inactive'
    WordWrap = True
  end
  object TextMemo: TMemo
    Left = 16
    Top = 370
    Width = 1000
    Height = 190
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object JsonMemo: TMemo
    Left = 16
    Top = 576
    Width = 1000
    Height = 166
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object WorkerTimer: TTimer
    Interval = 50
    OnTimer = PollTimer
    Left = 960
    Top = 24
  end
  object SaveDialog: TSaveDialog
    Options = [ofOverwritePrompt, ofPathMustExist, ofEnableSizing]
    Left = 992
    Top = 24
  end
end
