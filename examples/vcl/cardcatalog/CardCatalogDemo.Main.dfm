object CardCatalogDemoForm: TCardCatalogDemoForm
  Left = 0
  Top = 0
  Caption = 'ERD Card Catalogs'
  ClientHeight = 760
  ClientWidth = 1100
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  object ReaderLabel: TLabel
    Left = 16
    Top = 12
    Caption = 'Available PC/SC reader'
  end
  object ReaderBox: TComboBox
    Left = 16
    Top = 32
    Width = 660
    Height = 23
    Style = csDropDownList
  end
  object RefreshButton: TButton
    Left = 690
    Top = 30
    Width = 180
    Height = 28
    Caption = 'Refresh readers'
    OnClick = RefreshClick
  end
  object ReadAtrButton: TButton
    Left = 888
    Top = 30
    Width = 180
    Height = 28
    Caption = 'Inspect offered card ATR'
    OnClick = ReadAtrClick
  end
  object CatalogLabel: TLabel
    Left = 16
    Top = 74
    Caption = 'Inventory / lookup dictionary'
  end
  object CatalogBox: TComboBox
    Left = 16
    Top = 94
    Width = 380
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    OnChange = CatalogChanged
    Items.Strings = (
      'ATR reports'
      'EMV tag / path labels'
      'APDU instructions'
      'APDU statuses'
      'Known AID suggestions')
  end
  object FilterLabel: TLabel
    Left = 416
    Top = 74
    Caption = 'Filter inventory by issuer, country, value or description'
  end
  object FilterEdit: TEdit
    Left = 416
    Top = 94
    Width = 652
    Height = 23
    OnChange = CatalogChanged
  end
  object LookupLabel: TLabel
    Left = 16
    Top = 134
    Caption = 'Exact lookup value (hex)'
  end
  object LookupEdit: TEdit
    Left = 16
    Top = 154
    Width = 854
    Height = 23
  end
  object LookupButton: TButton
    Left = 888
    Top = 152
    Width = 180
    Height = 28
    Caption = 'Lookup offline'
    OnClick = LookupClick
  end
  object InventoryBox: TListBox
    Left = 16
    Top = 194
    Width = 1052
    Height = 302
    OnClick = InventorySelected
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 510
    Width = 1052
    Height = 230
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
  object StatusLabel: TLabel
    Left = 16
    Top = 744
    Caption = 'Reader observation inactive'
  end
end
