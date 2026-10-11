object BatchWorkflowDemoForm: TBatchWorkflowDemoForm
  Caption = 'BatchWorkflowDemo'
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
    Caption = 'NDEF text personalization batch: add one identifier and template per reader. Keep all cards presented. Each row needs a distinct reader; application callbacks support card swaps.'
    AutoSize = False
    WordWrap = True
  end
  object SourceLabel: TLabel
    Left = 16
    Top = 60
    Width = 400
    Height = 20
    Caption = 'Each staged row has its own reader'
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
    Visible = False
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
    Caption = 'Batch action'
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
      'Execute prepared personalization batch'
    )
  end
  object ModelBox: TComboBox
    Left = 360
    Top = 180
    Width = 624
    Height = 25
    Style = csDropDownList
    Items.Strings = (
      'Ultralight'
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
    Caption = 'Card / job identifier'
  end
  object TargetKeyLabel: TLabel
    Left = 360
    Top = 222
    Width = 420
    Height = 20
    Caption = 'NDEF text for this card'
  end
  object CoercivityLabel: TLabel
    Left = 750
    Top = 222
    Width = 220
    Height = 20
    Caption = 'Stripe coercivity'
    Visible = False
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
    Visible = False
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
    Caption = 'Add card template'
    OnClick = AddClick
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
