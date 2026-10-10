object GlobalPlatformDemoForm: TGlobalPlatformDemoForm
  Caption = 'GlobalPlatform / JavaCard management'
  ClientHeight = 760
  ClientWidth = 1020
  Font.Name = 'Segoe UI'
  Font.Height = -13
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnCloseQuery = FormCloseQuery
  object ContentScroll: TScrollBox
    Align = alClient
    TabOrder = 0
    object ReaderLabel: TLabel
      Left = 16
      Top = 12
      Width = 790
      Height = 17
      Caption = 'Available reader'
    end
    object ReaderBox: TComboBox
      Left = 16
      Top = 32
      Width = 790
      Height = 25
      Style = csDropDownList
    end
    object RefreshButton: TButton
      Left = 824
      Top = 32
      Width = 175
      Height = 25
      Caption = 'Refresh readers'
      OnClick = RefreshClick
    end
    object ActionLabel: TLabel
      Left = 16
      Top = 70
      Width = 360
      Height = 17
      Caption = 'Operation'
    end
    object ActionBox: TComboBox
      Left = 16
      Top = 90
      Width = 360
      Height = 25
      Style = csDropDownList
      Items.Strings = (
        'Read CPLC'
        'Issuer domain registry'
        'Applications / security domains'
        'Executable load files'
        'Load files and modules'
        'Authenticate only'
        'Load CAP package'
        'Install applet / make selectable'
        'Delete object'
        'Set application status'
        'Read key information'
        'PUT KEY: one symmetric key'
        'PUT KEY: ENC/MAC/DEK set'
        'Delete exact key'
        'PUT KEY: RSA verification key'
        'Make application selectable'
        'Extradite application')
      OnChange = ActionChanged
    end
    object ProtocolLabel: TLabel
      Left = 395
      Top = 70
      Width = 220
      Height = 17
      Caption = 'Secure channel'
    end
    object ProtocolBox: TComboBox
      Left = 395
      Top = 90
      Width = 220
      Height = 25
      Style = csDropDownList
      Items.Strings = (
        'SCP02 i=15'
        'SCP03 AES-128'
      )
    end
    object LevelLabel: TLabel
      Left = 635
      Top = 70
      Width = 365
      Height = 17
      Caption = 'Protection'
    end
    object LevelBox: TComboBox
      Left = 635
      Top = 90
      Width = 365
      Height = 25
      Style = csDropDownList
      Items.Strings = (
        'C-MAC'
        'C-MAC + C-ENC'
        'C-MAC + R-MAC'
        'C-MAC + C-ENC + R-MAC'
        'C-MAC + C-ENC + R-MAC + R-ENC'
      )
    end
    object DomainLabel: TLabel
      Left = 16
      Top = 130
      Width = 360
      Height = 17
      Caption = 'Security-domain AID (hex)'
    end
    object DomainEdit: TEdit
      Left = 16
      Top = 150
      Width = 360
      Height = 25
      Text = 'A000000151000000'
    end
    object VersionLabel: TLabel
      Left = 395
      Top = 130
      Width = 160
      Height = 17
      Caption = 'Key version (decimal)'
    end
    object VersionEdit: TEdit
      Left = 395
      Top = 150
      Width = 160
      Height = 25
      Text = '0'
    end
    object KeyIdLabel: TLabel
      Left = 575
      Top = 130
      Width = 160
      Height = 17
      Caption = 'Key identifier (decimal)'
    end
    object KeyIdEdit: TEdit
      Left = 575
      Top = 150
      Width = 160
      Height = 25
      Text = '0'
    end
    object S16Check: TCheckBox
      Left = 755
      Top = 150
      Width = 240
      Height = 24
      Caption = 'SCP03 S16 authentication'
    end
    object EncLabel: TLabel
      Left = 16
      Top = 190
      Width = 475
      Height = 17
      Caption = 'ENC key (16 bytes hex; no default)'
    end
    object EncEdit: TEdit
      Left = 16
      Top = 210
      Width = 475
      Height = 25
      Text = ''
      PasswordChar = '*'
    end
    object MacLabel: TLabel
      Left = 515
      Top = 190
      Width = 485
      Height = 17
      Caption = 'MAC key (16 bytes hex; no default)'
    end
    object MacEdit: TEdit
      Left = 515
      Top = 210
      Width = 485
      Height = 25
      Text = ''
      PasswordChar = '*'
    end
    object AuthReadCheck: TCheckBox
      Left = 16
      Top = 248
      Width = 475
      Height = 22
      Caption = 'Authenticate before read operations'
    end
    object TaggedCheck: TCheckBox
      Left = 515
      Top = 248
      Width = 485
      Height = 22
      Caption = 'Tagged GET STATUS (uncheck for legacy)'
      Checked = True
      State = cbChecked
    end
    object CapLabel: TLabel
      Left = 16
      Top = 280
      Width = 790
      Height = 17
      Caption = 'CAP archive path'
    end
    object CapEdit: TEdit
      Left = 16
      Top = 300
      Width = 790
      Height = 25
      Text = ''
    end
    object BrowseButton: TButton
      Left = 824
      Top = 300
      Width = 175
      Height = 25
      Caption = 'Choose CAP...'
      OnClick = BrowseClick
    end
    object ModuleLabel: TLabel
      Left = 16
      Top = 338
      Width = 475
      Height = 17
      Caption = 'Applet module AID (hex)'
    end
    object ModuleEdit: TEdit
      Left = 16
      Top = 358
      Width = 475
      Height = 25
      Text = ''
    end
    object InstanceLabel: TLabel
      Left = 515
      Top = 338
      Width = 485
      Height = 17
      Caption = 'Instance / object AID (hex)'
    end
    object InstanceEdit: TEdit
      Left = 515
      Top = 358
      Width = 485
      Height = 25
      Text = ''
    end
    object PrivilegeLabel: TLabel
      Left = 16
      Top = 396
      Width = 260
      Height = 17
      Caption = 'Privilege mask (1 or 3 bytes hex)'
    end
    object PrivilegeEdit: TEdit
      Left = 16
      Top = 416
      Width = 260
      Height = 25
      Text = '00'
    end
    object ParameterLabel: TLabel
      Left = 296
      Top = 396
      Width = 704
      Height = 17
      Caption = 'Application / load parameters (hex)'
    end
    object ParameterEdit: TEdit
      Left = 296
      Top = 416
      Width = 704
      Height = 25
      Text = ''
    end
    object BlockLabel: TLabel
      Left = 16
      Top = 454
      Width = 240
      Height = 17
      Caption = 'LOAD block bytes (1..220)'
    end
    object BlockEdit: TEdit
      Left = 16
      Top = 474
      Width = 240
      Height = 25
      Text = '220'
    end
    object LifeLabel: TLabel
      Left = 276
      Top = 454
      Width = 220
      Height = 17
      Caption = 'Application lifecycle (hex)'
    end
    object LifeEdit: TEdit
      Left = 276
      Top = 474
      Width = 220
      Height = 25
      Text = '07'
    end
    object RelatedCheck: TCheckBox
      Left = 515
      Top = 474
      Width = 485
      Height = 24
      Caption = 'Delete related objects (explicit DELETE flag)'
    end
    object AcknowledgeCheck: TCheckBox
      Left = 16
      Top = 520
      Width = 635
      Height = 24
      Caption = 'I acknowledge this authentication / card-management action'
    end
    object RunButton: TButton
      Left = 670
      Top = 518
      Width = 150
      Height = 28
      Caption = 'Run selected action'
      OnClick = RunClick
    end
    object ClearButton: TButton
      Left = 840
      Top = 518
      Width = 160
      Height = 28
      Caption = 'Clear keys / output'
      OnClick = ClearClick
    end
    object HelpMemo: TMemo
      Left = 16
      Top = 1002
      Width = 984
      Height = 62
      ReadOnly = True
      TabStop = False
      ScrollBars = ssVertical
    end
    object OutputMemo: TMemo
      Left = 16
      Top = 1078
      Width = 984
      Height = 90
      ReadOnly = True
      ScrollBars = ssBoth
      Font.Name = 'Consolas'
      WordWrap = False
    end
    object StatusLabel: TLabel
      Left = 16
      Top = 1182
      Width = 984
      Height = 17
      Caption = 'Reader observation starting...'
    end
    object ManagementGroup: TGroupBox
      Left = 16
      Top = 558
      Width = 984
      Height = 430
      Caption = 'Keys, delegated management and receipt policy (explicit profiles)'
      object DekEditLabel: TLabel
        Left = 12
        Top = 24
        Caption = 'Session DEK'
      end
      object DekEdit: TEdit
        Left = 12
        Top = 42
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object NewEncEditLabel: TLabel
        Left = 332
        Top = 24
        Caption = 'New key / ENC'
      end
      object NewEncEdit: TEdit
        Left = 332
        Top = 42
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object NewMacEditLabel: TLabel
        Left = 652
        Top = 24
        Caption = 'New MAC'
      end
      object NewMacEdit: TEdit
        Left = 652
        Top = 42
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object NewDekEditLabel: TLabel
        Left = 12
        Top = 74
        Caption = 'New DEK'
      end
      object NewDekEdit: TEdit
        Left = 12
        Top = 92
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object NewVersionEditLabel: TLabel
        Left = 332
        Top = 74
        Caption = 'New version (decimal)'
      end
      object NewVersionEdit: TEdit
        Left = 332
        Top = 92
        Width = 304
        Height = 25
        Text = '2'
      end
      object NewKeyIdEditLabel: TLabel
        Left = 652
        Top = 74
        Caption = 'First key ID (decimal)'
      end
      object NewKeyIdEdit: TEdit
        Left = 652
        Top = 92
        Width = 304
        Height = 25
        Text = '1'
      end
      object OldVersionEditLabel: TLabel
        Left = 12
        Top = 124
        Caption = 'Old version: 0 adds'
      end
      object OldVersionEdit: TEdit
        Left = 12
        Top = 142
        Width = 304
        Height = 25
        Text = '0'
      end
      object KeyTypeBoxLabel: TLabel
        Left = 332
        Top = 124
        Caption = 'New symmetric key type'
      end
      object KeyTypeBox: TComboBox
        Left = 332
        Top = 142
        Width = 304
        Height = 25
        Style = csDropDownList
        ItemIndex = 0
        Items.Strings = (
          'DES / 2K3DES'
          'AES-128')
      end
      object TokenTypeBoxLabel: TLabel
        Left = 652
        Top = 124
        Caption = 'Issuer token policy'
      end
      object TokenTypeBox: TComboBox
        Left = 652
        Top = 142
        Width = 304
        Height = 25
        Style = csDropDownList
        ItemIndex = 0
        Items.Strings = (
          'No issuer token'
          'AES-CMAC (GP 2.3.1)'
          'RSA SHA-1 (legacy GP)')
      end
      object TokenKeyEditLabel: TLabel
        Left = 12
        Top = 174
        Caption = 'AES token key'
      end
      object TokenKeyEdit: TEdit
        Left = 12
        Top = 192
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object ReceiptTypeBoxLabel: TLabel
        Left = 332
        Top = 174
        Caption = 'Receipt policy'
      end
      object ReceiptTypeBox: TComboBox
        Left = 332
        Top = 192
        Width = 304
        Height = 25
        Style = csDropDownList
        ItemIndex = 0
        Items.Strings = (
          'No receipt policy'
          'DES retail MAC'
          'AES-CMAC')
      end
      object ReceiptKeyEditLabel: TLabel
        Left = 652
        Top = 174
        Caption = 'Receipt key'
      end
      object ReceiptKeyEdit: TEdit
        Left = 652
        Top = 192
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object ReceiptUidEditLabel: TLabel
        Left = 12
        Top = 224
        Caption = 'Expected receipt UID'
      end
      object ReceiptUidEdit: TEdit
        Left = 12
        Top = 242
        Width = 304
        Height = 25
      end
      object ReceiptCounterEditLabel: TLabel
        Left = 332
        Top = 224
        Caption = 'Last receipt counter'
      end
      object ReceiptCounterEdit: TEdit
        Left = 332
        Top = 242
        Width = 304
        Height = 25
        Text = '-1'
      end
      object LoadHashEditLabel: TLabel
        Left = 652
        Top = 224
        Caption = 'Load hash (legacy SHA-1 if blank)'
      end
      object LoadHashEdit: TEdit
        Left = 652
        Top = 242
        Width = 304
        Height = 25
      end
      object DapEditLabel: TLabel
        Left = 12
        Top = 274
        Caption = 'Complete E2 DAP block(s)'
      end
      object DapEdit: TEdit
        Left = 12
        Top = 292
        Width = 304
        Height = 25
      end
      object NewDomainEditLabel: TLabel
        Left = 332
        Top = 274
        Caption = 'New domain AID'
      end
      object NewDomainEdit: TEdit
        Left = 332
        Top = 292
        Width = 304
        Height = 25
      end
      object RsaNEditLabel: TLabel
        Left = 652
        Top = 274
        Caption = 'RSA modulus (hex)'
      end
      object RsaNEdit: TEdit
        Left = 652
        Top = 292
        Width = 304
        Height = 25
      end
      object RsaEEditLabel: TLabel
        Left = 12
        Top = 324
        Caption = 'RSA exponent (hex)'
      end
      object RsaEEdit: TEdit
        Left = 12
        Top = 342
        Width = 304
        Height = 25
        Text = '010001'
      end
      object RsaDEditLabel: TLabel
        Left = 332
        Top = 324
        Caption = 'RSA private exponent'
      end
      object RsaDEdit: TEdit
        Left = 332
        Top = 342
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object RsaPEditLabel: TLabel
        Left = 652
        Top = 324
        Caption = 'RSA first prime'
      end
      object RsaPEdit: TEdit
        Left = 652
        Top = 342
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
      object RsaQEditLabel: TLabel
        Left = 12
        Top = 374
        Caption = 'RSA second prime'
      end
      object RsaQEdit: TEdit
        Left = 12
        Top = 392
        Width = 304
        Height = 25
        PasswordChar = '*'
      end
    end
  end
  object JobTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = JobTick
    Left = 944
    Top = 4
  end
  object CapDialog: TOpenDialog
    Filter = 'JavaCard CAP (*.cap)|*.cap|ZIP archives (*.zip)|*.zip'
    Options = [ofFileMustExist, ofPathMustExist]
    Left = 976
    Top = 4
  end
end
