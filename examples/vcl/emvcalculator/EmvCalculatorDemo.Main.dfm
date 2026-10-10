object EmvCalculatorDemoForm: TEmvCalculatorDemoForm
  Left = 0
  Top = 0
  Caption = 'ERD EMV Calculators'
  ClientHeight = 820
  ClientWidth = 970
  Position = poScreenCenter
  OnCreate = FormCreate
  object OperationLabel: TLabel
    Left = 16
    Top = 12
    Caption = 'Offline calculation'
  end
  object OperationBox: TComboBox
    Left = 16
    Top = 32
    Width = 450
    Height = 23
    Style = csDropDownList
    ItemIndex = 14
    OnChange = OperationChanged
    Items.Strings = (
      'DES odd parity'
      'Check DES odd parity'
      'DES encrypted-zero KCV'
      'AES encrypted-zero KCV'
      'UDK Option A'
      'UDK Option B'
      'Common session key (R)'
      'Common session key (ATC)'
      'Mastercard session key (ATC + UN)'
      'Visa script session key'
      'EMV 2000 tree session key'
      'Retail MAC - padding 1'
      'Retail MAC - padding 2'
      'Application cryptogram - padding 1'
      'Application cryptogram - padding 2'
      'Verify cryptogram - padding 1'
      'Verify cryptogram - padding 2'
      'ARPC method 1'
      'ARPC method 2'
      'AES CMAC'
      'Issuer-script MAC'
      'Visa script encryption'
      'Mastercard script encryption'
      'EMV script encryption'
      'ISO format 2 PIN block'
      'Visa PIN-change block'
      'Profile application cryptogram'
      'Profile ARPC method 1'
      'Profile ARPC method 2'
)
  end
  object ProfileLabel: TLabel
    Left = 490
    Top = 12
    Caption = 'Explicit cryptogram profile (profile operations only)'
  end
  object ProfileBox: TComboBox
    Left = 490
    Top = 32
    Width = 450
    Height = 23
    Style = csDropDownList
    ItemIndex = 1
    Items.Strings = (
      'Visa CVN 10'
      'Visa CVN 18'
      'Visa CVN 22'
      'Mastercard CVN 16'
      'Mastercard CVN 17'
      'Mastercard CVN 20'
      'Mastercard CVN 21'
      'Interac CVN 133')
  end
  object InputPages: TPageControl
    Left = 16
    Top = 68
    Width = 930
    Height = 500
    ActivePage = GeneralTab
    object GeneralTab: TTabSheet
      Caption = 'Key and calculation inputs'
      object GeneralScroll: TScrollBox
        Align = alClient
        TabOrder = 0
        object KeyEditLabel: TLabel
          Left = 16
          Top = 14
          Caption = 'Explicit key (hex)'
        end
        object KeyEdit: TEdit
          Left = 16
          Top = 34
          Width = 440
          Height = 23
          Text = ''
          PasswordChar = '*'
        end
        object DataEditLabel: TLabel
          Left = 16
          Top = 72
          Caption = 'Message / script data / common R (hex)'
        end
        object DataEdit: TEdit
          Left = 16
          Top = 92
          Width = 440
          Height = 23
          Text = ''
        end
        object PanEditLabel: TLabel
          Left = 16
          Top = 130
          Caption = 'PAN (decimal, UDK only)'
        end
        object PanEdit: TEdit
          Left = 16
          Top = 150
          Width = 440
          Height = 23
          Text = ''
          PasswordChar = '*'
        end
        object PsnEditLabel: TLabel
          Left = 16
          Top = 188
          Caption = 'PAN sequence number (two decimal digits)'
        end
        object PsnEdit: TEdit
          Left = 16
          Top = 208
          Width = 440
          Height = 23
          Text = '00'
        end
        object AtcEditLabel: TLabel
          Left = 16
          Top = 246
          Caption = 'ATC (two bytes, hex)'
        end
        object AtcEdit: TEdit
          Left = 16
          Top = 266
          Width = 440
          Height = 23
          Text = ''
        end
        object UnEditLabel: TLabel
          Left = 16
          Top = 304
          Caption = 'Unpredictable number (four bytes, hex)'
        end
        object UnEdit: TEdit
          Left = 16
          Top = 324
          Width = 440
          Height = 23
          Text = ''
        end
        object IvEditLabel: TLabel
          Left = 16
          Top = 362
          Caption = 'Tree IV (sixteen bytes, hex)'
        end
        object IvEdit: TEdit
          Left = 16
          Top = 382
          Width = 440
          Height = 23
          Text = '00000000000000000000000000000000'
        end
        object ExpectedEditLabel: TLabel
          Left = 480
          Top = 14
          Caption = 'Expected cryptogram (eight bytes; ARPC 2: four bytes)'
        end
        object ExpectedEdit: TEdit
          Left = 480
          Top = 34
          Width = 440
          Height = 23
          Text = ''
        end
        object ResponseEditLabel: TLabel
          Left = 480
          Top = 72
          Caption = 'Response code (two bytes, hex; ASCII 00 = 3030)'
        end
        object ResponseEdit: TEdit
          Left = 480
          Top = 92
          Width = 440
          Height = 23
          Text = ''
        end
        object CsuEditLabel: TLabel
          Left = 480
          Top = 130
          Caption = 'Card status update (four bytes, hex)'
        end
        object CsuEdit: TEdit
          Left = 480
          Top = 150
          Width = 440
          Height = 23
          Text = ''
        end
        object AuthEditLabel: TLabel
          Left = 480
          Top = 188
          Caption = 'Proprietary authentication data (zero to eight bytes)'
        end
        object AuthEdit: TEdit
          Left = 480
          Top = 208
          Width = 440
          Height = 23
          Text = ''
        end
        object PinEditLabel: TLabel
          Left = 480
          Top = 246
          Caption = 'New PIN (decimal, four to twelve digits)'
        end
        object PinEdit: TEdit
          Left = 480
          Top = 266
          Width = 440
          Height = 23
          Text = ''
          PasswordChar = '*'
        end
        object OldPinEditLabel: TLabel
          Left = 480
          Top = 304
          Caption = 'Current PIN (decimal; empty when absent)'
        end
        object OldPinEdit: TEdit
          Left = 480
          Top = 324
          Width = 440
          Height = 23
          Text = ''
          PasswordChar = '*'
        end
        object HeightEditLabel: TLabel
          Left = 480
          Top = 362
          Caption = 'Tree height (decimal)'
        end
        object HeightEdit: TEdit
          Left = 480
          Top = 382
          Width = 440
          Height = 23
          Text = '8'
        end
        object BranchEditLabel: TLabel
          Left = 480
          Top = 420
          Caption = 'Tree branch factor (decimal)'
        end
        object BranchEdit: TEdit
          Left = 480
          Top = 440
          Width = 440
          Height = 23
          Text = '4'
        end
      end
    end
    object ProfileTab: TTabSheet
      Caption = 'Profile transaction fields (hex)'
      object ProfileScroll: TScrollBox
        Align = alClient
        TabOrder = 0
        object AmountEditLabel: TLabel
          Left = 16
          Top = 14
          Caption = '9F02 Amount authorized'
        end
        object AmountEdit: TEdit
          Left = 16
          Top = 34
          Width = 440
          Height = 23
          Text = '000000000000'
        end
        object OtherEditLabel: TLabel
          Left = 16
          Top = 72
          Caption = '9F03 Amount other'
        end
        object OtherEdit: TEdit
          Left = 16
          Top = 92
          Width = 440
          Height = 23
          Text = '000000000000'
        end
        object CountryEditLabel: TLabel
          Left = 16
          Top = 130
          Caption = '9F1A Terminal country'
        end
        object CountryEdit: TEdit
          Left = 16
          Top = 150
          Width = 440
          Height = 23
          Text = ''
        end
        object TvrEditLabel: TLabel
          Left = 16
          Top = 188
          Caption = '95 Terminal verification results'
        end
        object TvrEdit: TEdit
          Left = 16
          Top = 208
          Width = 440
          Height = 23
          Text = ''
        end
        object CurrencyEditLabel: TLabel
          Left = 16
          Top = 246
          Caption = '5F2A Currency'
        end
        object CurrencyEdit: TEdit
          Left = 16
          Top = 266
          Width = 440
          Height = 23
          Text = ''
        end
        object DateEditLabel: TLabel
          Left = 16
          Top = 304
          Caption = '9A Transaction date (YYMMDD BCD)'
        end
        object DateEdit: TEdit
          Left = 16
          Top = 324
          Width = 440
          Height = 23
          Text = ''
        end
        object TypeEditLabel: TLabel
          Left = 16
          Top = 362
          Caption = '9C Transaction type'
        end
        object TypeEdit: TEdit
          Left = 16
          Top = 382
          Width = 440
          Height = 23
          Text = ''
        end
        object AipEditLabel: TLabel
          Left = 480
          Top = 14
          Caption = '82 Application interchange profile'
        end
        object AipEdit: TEdit
          Left = 480
          Top = 34
          Width = 440
          Height = 23
          Text = ''
        end
        object IadEditLabel: TLabel
          Left = 480
          Top = 72
          Caption = '9F10 Complete issuer application data (IAD profiles)'
        end
        object IadEdit: TEdit
          Left = 480
          Top = 92
          Width = 440
          Height = 23
          Text = ''
        end
        object CvrEditLabel: TLabel
          Left = 480
          Top = 130
          Caption = 'Extracted CVR (Visa 10 / Mastercard profiles)'
        end
        object CvrEdit: TEdit
          Left = 480
          Top = 150
          Width = 440
          Height = 23
          Text = ''
        end
        object CountersEditLabel: TLabel
          Left = 480
          Top = 188
          Caption = 'Decrypted counters (Mastercard 17/21 only)'
        end
        object CountersEdit: TEdit
          Left = 480
          Top = 208
          Width = 440
          Height = 23
          Text = ''
        end
      end
    end
  end
  object HelpMemo: TMemo
    Left = 16
    Top = 576
    Width = 930
    Height = 64
    ReadOnly = True
    TabOrder = 3
  end
  object CalculateButton: TButton
    Left = 16
    Top = 650
    Width = 180
    Height = 30
    Caption = 'Calculate offline'
    OnClick = CalculateClick
  end
  object ClearButton: TButton
    Left = 208
    Top = 650
    Width = 180
    Height = 30
    Caption = 'Clear inputs and output'
    OnClick = ClearClick
  end
  object OutputMemo: TMemo
    Left = 16
    Top = 692
    Width = 930
    Height = 112
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
  end
end
