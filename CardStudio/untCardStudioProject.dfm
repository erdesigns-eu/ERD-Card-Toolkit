object frmCardStudioProject: TfrmCardStudioProject
  Left = 0
  Top = 0
  Caption = 'CardStudio Project'
  ClientHeight = 555
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Position = poDefault
  ScreenSnap = True
  Visible = True
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter: TSplitter
    Left = 231
    Top = 0
    Width = 6
    Height = 555
    ResizeStyle = rsUpdate
    ExplicitLeft = 233
    ExplicitTop = 15
    ExplicitHeight = 398
  end
  object tvCard: TTreeView
    AlignWithMargins = True
    Left = 8
    Top = 5
    Width = 223
    Height = 542
    Margins.Left = 8
    Margins.Top = 5
    Margins.Right = 0
    Margins.Bottom = 8
    Align = alLeft
    Indent = 19
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ExplicitLeft = 10
    ExplicitTop = 20
    ExplicitHeight = 385
  end
end
