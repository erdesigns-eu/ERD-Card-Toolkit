object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Form4'
  ClientHeight = 721
  ClientWidth = 912
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    912
    721)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 912
    Height = 249
    Align = alTop
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Memo2: TMemo
    Left = 0
    Top = 249
    Width = 912
    Height = 192
    Align = alTop
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Button1: TButton
    Left = 8
    Top = 648
    Width = 97
    Height = 49
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Filter'
    TabOrder = 2
    OnClick = Button1Click
    ExplicitTop = 512
  end
  object Memo3: TMemo
    Left = 0
    Top = 441
    Width = 912
    Height = 188
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitTop = 257
    ExplicitHeight = 192
  end
  object Button2: TButton
    Left = 111
    Top = 648
    Width = 97
    Height = 49
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Process'
    TabOrder = 4
    OnClick = Button2Click
  end
end
