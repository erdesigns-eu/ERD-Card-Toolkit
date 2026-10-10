unit EmvCalculatorDemo.Main;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ComCtrls, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.DES,
  ERD.Card.Crypto.Windows, ERD.Card.Crypto.Hash.Windows, ERD.Card.EMV.Calculator;

type
  /// <summary>Independent offline EMV calculator form; every visual control is declared in its own DFM.</summary>
  TEmvCalculatorDemoForm = class(TForm)
  published
    /// <summary>Explicit key (hex) input label.</summary>
    KeyEditLabel: TLabel;

    /// <summary>Explicit key (hex) input.</summary>
    KeyEdit: TEdit;

    /// <summary>Message / script data / common R (hex) input label.</summary>
    DataEditLabel: TLabel;

    /// <summary>Message / script data / common R (hex) input.</summary>
    DataEdit: TEdit;

    /// <summary>PAN (decimal, UDK only) input label.</summary>
    PanEditLabel: TLabel;

    /// <summary>PAN (decimal, UDK only) input.</summary>
    PanEdit: TEdit;

    /// <summary>PAN sequence number (two decimal digits) input label.</summary>
    PsnEditLabel: TLabel;

    /// <summary>PAN sequence number (two decimal digits) input.</summary>
    PsnEdit: TEdit;

    /// <summary>ATC (two bytes, hex) input label.</summary>
    AtcEditLabel: TLabel;

    /// <summary>ATC (two bytes, hex) input.</summary>
    AtcEdit: TEdit;

    /// <summary>Unpredictable number (four bytes, hex) input label.</summary>
    UnEditLabel: TLabel;

    /// <summary>Unpredictable number (four bytes, hex) input.</summary>
    UnEdit: TEdit;

    /// <summary>Tree IV (sixteen bytes, hex) input label.</summary>
    IvEditLabel: TLabel;

    /// <summary>Tree IV (sixteen bytes, hex) input.</summary>
    IvEdit: TEdit;

    /// <summary>Expected cryptogram (eight bytes; ARPC 2: four bytes) input label.</summary>
    ExpectedEditLabel: TLabel;

    /// <summary>Expected cryptogram (eight bytes; ARPC 2: four bytes) input.</summary>
    ExpectedEdit: TEdit;

    /// <summary>Response code (two bytes, hex; ASCII 00 = 3030) input label.</summary>
    ResponseEditLabel: TLabel;

    /// <summary>Response code (two bytes, hex; ASCII 00 = 3030) input.</summary>
    ResponseEdit: TEdit;

    /// <summary>Card status update (four bytes, hex) input label.</summary>
    CsuEditLabel: TLabel;

    /// <summary>Card status update (four bytes, hex) input.</summary>
    CsuEdit: TEdit;

    /// <summary>Proprietary authentication data (zero to eight bytes) input label.</summary>
    AuthEditLabel: TLabel;

    /// <summary>Proprietary authentication data (zero to eight bytes) input.</summary>
    AuthEdit: TEdit;

    /// <summary>New PIN (decimal, four to twelve digits) input label.</summary>
    PinEditLabel: TLabel;

    /// <summary>New PIN (decimal, four to twelve digits) input.</summary>
    PinEdit: TEdit;

    /// <summary>Current PIN (decimal; empty when absent) input label.</summary>
    OldPinEditLabel: TLabel;

    /// <summary>Current PIN (decimal; empty when absent) input.</summary>
    OldPinEdit: TEdit;

    /// <summary>Tree height (decimal) input label.</summary>
    HeightEditLabel: TLabel;

    /// <summary>Tree height (decimal) input.</summary>
    HeightEdit: TEdit;

    /// <summary>Tree branch factor (decimal) input label.</summary>
    BranchEditLabel: TLabel;

    /// <summary>Tree branch factor (decimal) input.</summary>
    BranchEdit: TEdit;

    /// <summary>9F02 Amount authorized input label.</summary>
    AmountEditLabel: TLabel;

    /// <summary>9F02 Amount authorized input.</summary>
    AmountEdit: TEdit;

    /// <summary>9F03 Amount other input label.</summary>
    OtherEditLabel: TLabel;

    /// <summary>9F03 Amount other input.</summary>
    OtherEdit: TEdit;

    /// <summary>9F1A Terminal country input label.</summary>
    CountryEditLabel: TLabel;

    /// <summary>9F1A Terminal country input.</summary>
    CountryEdit: TEdit;

    /// <summary>95 Terminal verification results input label.</summary>
    TvrEditLabel: TLabel;

    /// <summary>95 Terminal verification results input.</summary>
    TvrEdit: TEdit;

    /// <summary>5F2A Currency input label.</summary>
    CurrencyEditLabel: TLabel;

    /// <summary>5F2A Currency input.</summary>
    CurrencyEdit: TEdit;

    /// <summary>9A Transaction date (YYMMDD BCD) input label.</summary>
    DateEditLabel: TLabel;

    /// <summary>9A Transaction date (YYMMDD BCD) input.</summary>
    DateEdit: TEdit;

    /// <summary>9C Transaction type input label.</summary>
    TypeEditLabel: TLabel;

    /// <summary>9C Transaction type input.</summary>
    TypeEdit: TEdit;

    /// <summary>82 Application interchange profile input label.</summary>
    AipEditLabel: TLabel;

    /// <summary>82 Application interchange profile input.</summary>
    AipEdit: TEdit;

    /// <summary>9F10 Complete issuer application data (IAD profiles) input label.</summary>
    IadEditLabel: TLabel;

    /// <summary>9F10 Complete issuer application data (IAD profiles) input.</summary>
    IadEdit: TEdit;

    /// <summary>Extracted CVR (Visa 10 / Mastercard profiles) input label.</summary>
    CvrEditLabel: TLabel;

    /// <summary>Extracted CVR (Visa 10 / Mastercard profiles) input.</summary>
    CvrEdit: TEdit;

    /// <summary>Decrypted counters (Mastercard 17/21 only) input label.</summary>
    CountersEditLabel: TLabel;

    /// <summary>Decrypted counters (Mastercard 17/21 only) input.</summary>
    CountersEdit: TEdit;

    /// <summary>Explicit calculation selection label.</summary>
    OperationLabel: TLabel;

    /// <summary>Every supported calculator operation; no reader or card command.</summary>
    OperationBox: TComboBox;

    /// <summary>Explicit scheme/CVN selection label.</summary>
    ProfileLabel: TLabel;

    /// <summary>Explicit cryptogram scheme and CVN.</summary>
    ProfileBox: TComboBox;

    /// <summary>Separate general and transaction input pages.</summary>
    InputPages: TPageControl;

    /// <summary>General calculation inputs.</summary>
    GeneralTab: TTabSheet;

    /// <summary>Scrollable general inputs.</summary>
    GeneralScroll: TScrollBox;

    /// <summary>Full profile transaction fields.</summary>
    ProfileTab: TTabSheet;

    /// <summary>Scrollable transaction fields.</summary>
    ProfileScroll: TScrollBox;

    /// <summary>Required-input explanation for the selected operation.</summary>
    HelpMemo: TMemo;

    /// <summary>Execute only the selected offline calculation.</summary>
    CalculateButton: TButton;

    /// <summary>Clear entered keys, PINs and calculated output.</summary>
    ClearButton: TButton;

    /// <summary>Explicit calculation result or sanitized validation error.</summary>
    OutputMemo: TMemo;

    /// <summary>Creates an inactive calculator and initializes the explicit operation list.</summary>
    /// <param name="Sender">The form loading its designer resource.</param>
    procedure FormCreate(Sender: TObject);

    /// <summary>Shows which inputs the selected operation consumes.</summary>
    /// <param name="Sender">The operation combo box.</param>
    procedure OperationChanged(Sender: TObject);

    /// <summary>Validates explicit fields and executes one offline operation.</summary>
    /// <param name="Sender">The calculate button.</param>
    procedure CalculateClick(Sender: TObject);

    /// <summary>Clears all key, PIN, message and result text.</summary>
    /// <param name="Sender">The clear button.</param>
    procedure ClearClick(Sender: TObject);
  private
    FCalculator: TEmvCalculator;
    function ProfileData: TEmvCryptogramData;
  end;

var
  /// <summary>Application-owned independent calculator form.</summary>
  EmvCalculatorDemoForm: TEmvCalculatorDemoForm;

implementation

{$R *.dfm}

function Bytes(const AEdit: TEdit): TBytes;
begin
  Result := HexToBytes(AEdit.Text, True);
end;

procedure TEmvCalculatorDemoForm.FormCreate(Sender: TObject);
begin
  FCalculator := TEmvCalculator.Create(Self);
  OperationBox.ItemIndex := 14;
  ProfileBox.ItemIndex := 1;
  OperationChanged(Self);
end;

procedure TEmvCalculatorDemoForm.OperationChanged(Sender: TObject);
begin
  OutputMemo.Clear;
  case OperationBox.ItemIndex of
    0 .. 3:
      HelpMemo.Text := 'Uses the explicit key. KCV output is the first three bytes of encrypted zeroes.';
    4, 5:
      HelpMemo.Text := 'Uses a sixteen-byte issuer master key, PAN and two-digit PSN. Option B hashes PANs longer than sixteen digits.';
    6:
      HelpMemo.Text := 'Uses a sixteen-byte ICC master key and eight-byte diversification R in Message/data.';
    7 .. 10:
      HelpMemo.Text := 'Uses ICC master key and ATC. Mastercard also requires UN; tree derivation requires IV, height and branch factor.';
    11 .. 16:
      HelpMemo.Text := 'Uses a sixteen-byte session key and complete unpadded cryptogram/MAC data. Verification also requires the expected cryptogram.';
    17:
      HelpMemo.Text := 'Uses the profile-derived ARPC key, eight-byte ARQC in Message/data and two response-code bytes.';
    18:
      HelpMemo.Text := 'Uses the profile-derived ARPC key, eight-byte ARQC in Message/data, four-byte CSU and optional authentication data.';
    19:
      HelpMemo.Text := 'Uses a sixteen-byte AES key and unpadded message. Outputs the full sixteen-byte CMAC.';
    20 .. 23:
      HelpMemo.Text := 'Uses the explicit SMI/SMC session key and complete authenticated bytes or clear script data. Sends no card command.';
    24, 25:
      HelpMemo.Text := 'Uses the new PIN. Visa formatting additionally uses the ICC AC master key and optional current PIN.';
    26:
      HelpMemo.Text := 'Uses ICC AC master key, ATC, UN and all transaction fields on the Profile page. Supply only the selected profile CVR/IAD/counters.';
    27, 28:
      HelpMemo.Text := 'Uses ICC AC master key, ATC, UN (method one), ARQC in Message/data and the applicable response code or CSU/authentication data.';
    29, 30:
      HelpMemo.Text := 'Uses an explicit ARPC key, ARQC in Message/data and expected ARPC (eight bytes for method one, four for method two). Supply response code or CSU/authentication data.';
  end;
end;

function TEmvCalculatorDemoForm.ProfileData: TEmvCryptogramData;
begin
  Result := Default(TEmvCryptogramData);
  Result.AmountAuthorized := Bytes(AmountEdit);
  Result.AmountOther := Bytes(OtherEdit);
  Result.TerminalCountry := Bytes(CountryEdit);
  Result.TerminalVerificationResults := Bytes(TvrEdit);
  Result.Currency := Bytes(CurrencyEdit);
  Result.TransactionDate := Bytes(DateEdit);
  Result.TransactionType := Bytes(TypeEdit);
  Result.UnpredictableNumber := Bytes(UnEdit);
  Result.ApplicationInterchangeProfile := Bytes(AipEdit);
  Result.Atc := Bytes(AtcEdit);
  Result.IssuerApplicationData := Bytes(IadEdit);
  Result.CardVerificationResults := Bytes(CvrEdit);
  Result.Counters := Bytes(CountersEdit);
end;

procedure TEmvCalculatorDemoForm.CalculateClick(Sender: TObject);
var
  Key, Data, Output: TBytes;
  Profile: TEmvCryptogramProfile;
  Verified: Boolean;
begin
  OutputMemo.Clear;
  Key := nil;
  Data := nil;
  Output := nil;
  try
    try
      FCalculator.DesProvider := TCardWindowsAesProvider.Create;
      FCalculator.AesProvider := FCalculator.DesProvider;
      FCalculator.HashProvider := TCardWindowsHashProvider.Create;
      if OperationBox.ItemIndex <> 24 then
        Key := Bytes(KeyEdit);
      if OperationBox.ItemIndex in [6, 11 .. 23, 27 .. 30] then
        Data := Bytes(DataEdit);
      if (ProfileBox.ItemIndex < 0) or (ProfileBox.ItemIndex > Ord(High(TEmvCryptogramProfile))) then
        raise EEmvCalculationError.Create('Select an explicit cryptogram profile.');
      Profile := TEmvCryptogramProfile(ProfileBox.ItemIndex);
      case OperationBox.ItemIndex of
        0: Output := TEmvCalculator.AdjustOddParity(Key);
        1:
          begin
            OutputMemo.Text := 'Odd parity: ' + BoolToStr(TEmvCalculator.HasOddParity(Key), True);
            Exit;
          end;
        2: Output := FCalculator.KeyCheckValue(Key);
        3: Output := FCalculator.AesKeyCheckValue(Key);
        4: Output := FCalculator.DeriveMasterKey(Key, PanEdit.Text, PsnEdit.Text, emkOptionA);
        5: Output := FCalculator.DeriveMasterKey(Key, PanEdit.Text, PsnEdit.Text, emkOptionB);
        6: Output := FCalculator.DeriveCommonSessionKey(Key, Data);
        7: Output := FCalculator.DeriveAtcSessionKey(Key, Bytes(AtcEdit));
        8: Output := FCalculator.DeriveMastercardSessionKey(Key, Bytes(AtcEdit), Bytes(UnEdit));
        9: Output := FCalculator.DeriveVisaScriptKey(Key, Bytes(AtcEdit));
        10: Output := FCalculator.DeriveTreeSessionKey(Key, Bytes(AtcEdit), Bytes(IvEdit), StrToInt(HeightEdit.Text), StrToInt(BranchEdit.Text));
        11: Output := FCalculator.RetailMac(Key, Data, empMethod1);
        12: Output := FCalculator.RetailMac(Key, Data, empMethod2);
        13: Output := FCalculator.ApplicationCryptogram(Key, Data, empMethod1);
        14: Output := FCalculator.ApplicationCryptogram(Key, Data, empMethod2);
        15, 16:
          begin
            if OperationBox.ItemIndex = 15 then
              Verified := FCalculator.VerifyApplicationCryptogram(Key, Data, Bytes(ExpectedEdit), empMethod1)
            else
              Verified := FCalculator.VerifyApplicationCryptogram(Key, Data, Bytes(ExpectedEdit), empMethod2);
            OutputMemo.Text := 'Cryptogram matches: ' + BoolToStr(Verified, True);
            Exit;
          end;
        17: Output := FCalculator.ArpcMethod1(Key, Data, Bytes(ResponseEdit));
        18: Output := FCalculator.ArpcMethod2(Key, Data, Bytes(CsuEdit), Bytes(AuthEdit));
        19: Output := FCalculator.AesCmac(Key, Data);
        20: Output := FCalculator.ScriptMac(Key, Data);
        21: Output := FCalculator.EncryptScriptData(Key, Data, eseVisa);
        22: Output := FCalculator.EncryptScriptData(Key, Data, eseMastercard);
        23: Output := FCalculator.EncryptScriptData(Key, Data, eseEmv);
        24: Output := TEmvCalculator.FormatPinBlock2(PinEdit.Text);
        25: Output := TEmvCalculator.FormatVisaPinBlock(Key, PinEdit.Text, OldPinEdit.Text);
        26: Output := FCalculator.ProfileCryptogram(Profile, Key, ProfileData);
        27: Output := FCalculator.ProfileArpc1(Profile, Key, Bytes(AtcEdit), Bytes(UnEdit), Data, Bytes(ResponseEdit));
        28: Output := FCalculator.ProfileArpc2(Profile, Key, Bytes(AtcEdit), Data, Bytes(CsuEdit), Bytes(AuthEdit));
        29, 30:
          begin
            if OperationBox.ItemIndex = 29 then
              Verified := FCalculator.VerifyArpcMethod1(Key, Data, Bytes(ResponseEdit), Bytes(ExpectedEdit))
            else
              Verified := FCalculator.VerifyArpcMethod2(Key, Data, Bytes(CsuEdit), Bytes(AuthEdit), Bytes(ExpectedEdit));
            OutputMemo.Text := 'ARPC matches: ' + BoolToStr(Verified, True);
            Exit;
          end;
      else
        raise EEmvCalculationError.Create('Select a calculation.');
      end;
      OutputMemo.Text := BytesToHex(Output);
    except
      on E: Exception do
        OutputMemo.Text := E.ClassName + ': calculation failed; check the required input fields.';
    end;
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Output);
  end;
end;

procedure TEmvCalculatorDemoForm.ClearClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TEdit then
      TEdit(Components[I]).Clear;
  OutputMemo.Clear;
end;

end.
