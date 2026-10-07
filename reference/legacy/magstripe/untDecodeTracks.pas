unit untDecodeTracks;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, Vcl.Menus;

type
  TfrmTracksDecode = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnCheckBIN: TButton;
    btnDecode: TButton;
    gbTrack: TGroupBox;
    memTrack: TMemo;
    Panel3: TPanel;
    cbTrack: TComboBox;
    Label3: TLabel;
    gbDecodedData: TGroupBox;
    memDecodedData: TMemo;
    SaveDialog: TSaveDialog;
    PopupMenu: TPopupMenu;
    SelectAll1: TMenuItem;
    N2: TMenuItem;
    Copy1: TMenuItem;
    N1: TMenuItem;
    Savetofile1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDecodeClick(Sender: TObject);
    procedure Savetofile1Click(Sender: TObject);
    procedure btnCheckBINClick(Sender: TObject);
  private
    { Private declarations }
    FPAN : string;
    procedure SetDecoderPAN(const PAN: string);
  public
    { Public declarations }
    procedure ParseTrack1(const Track: string);
    procedure ParseTrack2(const Track: string);
    procedure ParseTrack3(const Track: string);

    property DecoderPAN: string read FPAN write SetDecoderPAN;
  end;

var
  frmTracksDecode: TfrmTracksDecode;

implementation

{$R *.dfm}

uses untMain, untConst, untBIN, System.RegularExpressions, StrUtils,
     untBIN_AMEX, untBIN_DINERSCLUB, untBIN_DISCOVER, untBIN_JCB,
     untBIN_MAESTRO, untBIN_MASTERCARD, untBIN_VISA, untBINCheck;

{*******************************************************}
{           Srrvice Code Digit Explaination             }
{*******************************************************}
function ServiceCodeDigit(const SC: Integer; const D: Integer) : string;
var
  S : string;
begin
  // Convert to string
  S := Format('%.*d', [3, SC]);
  // Digit 1
  if (D = 1) then
  case StrToInt(Copy(S, 1, 1)) of
    0 : Result := 'No restrictions';
    1 : Result := 'International interchange OK';
    2 : Result := 'International interchange, use IC (chip) where feasible';
    5 : Result := 'National interchange only except under bilateral agreement';
    6 : Result := 'National interchange only except under bilateral agreement, use IC (chip) where feasible';
    7 : Result := 'No interchange except under bilateral agreement (closed loop)';
    9 : Result := 'Test';
  end;
  // Digit 2
  if (D = 2) then
  case StrToInt(Copy(S, 2, 1)) of
    0 : Result := 'Normal';
    2 : Result := 'Contact issuer via online means';
    4 : Result := 'Contact issuer via online means except under bilateral agreement';
  end;
  // Digit 3
  if (D = 3) then
  case StrToInt(Copy(S, 3, 1)) of
    0 : Result := 'No restrictions, PIN required';
    1 : Result := 'No restrictions';
    2 : Result := 'Goods and services only (no cash)';
    3 : Result := 'ATM only, PIN required';
    4 : Result := 'Cash only';
    5 : Result := 'Goods and services only (no cash), PIN required';
    6 : Result := 'No restrictions, use PIN where feasible';
    7 : Result := 'Goods and services only (no cash), use PIN where feasible';
  end;
end;

{*******************************************************}
{                   BIN Information                     }
{*******************************************************}
function FormatBIN(const C: TCardScheme; const PAN: string) : string;
var
  I : Integer;
  B : string;
begin
  // Default Empty
  Result := '';
  // Copy BIN from PAN
  B := Copy(PAN, 1, 6);
  case C of
    csAMEX:
    begin
      I := FindBIN(BINS_AMEX, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_AMEX[I].iin_country),
        CurrencyCodeToStr(BINS_AMEX[I].iin_currency){,
        BINS_AMEX[I].iin_issuer,
        BINS_AMEX[I].iin_issuer_url,
        BINS_AMEX[I].iin_category}
      ]);
    end;

    csDISCOVER:
    begin
      I := FindBIN(BINS_DISCOVER, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_DISCOVER[I].iin_country),
        CurrencyCodeToStr(BINS_DISCOVER[I].iin_currency){,
        BINS_DISCOVER[I].iin_issuer,
        BINS_DISCOVER[I].iin_issuer_url,
        BINS_DISCOVER[I].iin_category}
      ]);
    end;

    csDINERSCLUBINTERNATIONAL:
    begin
      I := FindBIN(BINS_DINERSCLUB, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_DINERSCLUB[I].iin_country),
        CurrencyCodeToStr(BINS_DINERSCLUB[I].iin_currency){,
        BINS_DINERSCLUB[I].iin_issuer,
        BINS_DINERSCLUB[I].iin_issuer_url,
        BINS_DINERSCLUB[I].iin_category}
      ]);
    end;

    csJCB:
    begin
      I := FindBIN(BINS_JCB, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_JCB[I].iin_country),
        CurrencyCodeToStr(BINS_JCB[I].iin_currency){,
        BINS_JCB[I].iin_issuer,
        BINS_JCB[I].iin_issuer_url,
        BINS_JCB[I].iin_category}
      ]);
    end;

    csMASTERCARD:
    begin
      I := FindBIN(BINS_MASTERCARD, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_MASTERCARD[I].iin_country),
        CurrencyCodeToStr(BINS_MASTERCARD[I].iin_currency){,
        BINS_MASTERCARD[I].iin_issuer,
        BINS_MASTERCARD[I].iin_issuer_url,
        BINS_MASTERCARD[I].iin_category}
      ]);
    end;

    csMAESTRO:
    begin
      I := FindBIN(BINS_MAESTRO, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_MAESTRO[I].iin_country),
        CurrencyCodeToStr(BINS_MAESTRO[I].iin_currency){,
        BINS_MAESTRO[I].iin_issuer,
        BINS_MAESTRO[I].iin_issuer_url,
        BINS_MAESTRO[I].iin_category}
      ]);
    end;

    csVISA:
    begin
      I := FindBIN(BINS_VISA, B);
      if I >= 0 then Result := Format(TrackLogBIN, [
        CountryCodeToStr(BINS_VISA[I].iin_country),
        CurrencyCodeToStr(BINS_VISA[I].iin_currency){,
        BINS_VISA[I].iin_issuer,
        BINS_VISA[I].iin_issuer_url,
        BINS_VISA[I].iin_category}
      ]);
    end;
  end;
end;

{*******************************************************}
{                Set PAN for decoder                    }
{*******************************************************}
procedure TfrmTracksDecode.SetDecoderPAN(const PAN: string);
begin
  FPAN := PAN;
  btnCheckBIN.Enabled := Length(FPAN) > 0;
end;

{*******************************************************}
{                    Parse Track 1                      }
{*******************************************************}
procedure TfrmTracksDecode.ParseTrack1(const Track: string);

  function IsValidData : Boolean;
  begin
    Result := TRegEx.IsMatch(Track, Track1RegEx);
  end;

  function PAN : string;
  var
    PS, PE : Integer;
  begin
    // Start Position
    PS := 1;
    // If there is a start sentinel, move the start position
    if (Track[PS] = MST1StartSentinel) then Inc(PS);
    // If the first character is a B, move the start position
    if (Track[PS] = 'B') then Inc(PS);
    // Get the position of the field seperator
    PE := Pos(Track1FieldSeperator, Track) - PS;
    // Extract PAN from track
    Result := Copy(Track, PS, PE);
  end;

  function CardHolder(const FirstName: Boolean) : string;
  var
    PS, PE : Integer;
    FullNm : string;
  begin
    // Start Position
    PS := Pos(Track1FieldSeperator, Track);
    // Get the position of the field seperator
    PE := Pos(Track1FieldSeperator, Track, PS + 1) - PS;
    // Extract Name from track
    FullNm := Copy(Track, PS +1, PE -1);
    if (Pos(Track1NameSeperator, FullNm) > 0) then
    begin
      PE := Pos(Track1NameSeperator, FullNm);
      if FirstName then
        Result := Trim(Copy(FullNm, PE +1, Length(FullNm)))
      else
        Result := Trim(Copy(FullNm, 1, PE -1));
    end else
    begin
      if FirstName then
        Result := ''
      else
        Result := Trim(FullNm);
    end;
  end;

  function AditionalData : string;
  var
    PS : Integer;
  begin
    PS := Pos(Track1FieldSeperator, Track);
    PS := Pos(Track1FieldSeperator, Track, PS +1);
    Result := Copy(Track, PS +1, Length(Track));
  end;

  function ExpiryYear : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 1, 2), X) then
    begin
      Result := 2000 + X;
    end else
      Result := 2000;
  end;

  function ExpiryMonth : string;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 3, 2), X) then
    begin
      Result := Format('%.*d (%s)', [2, X, LongMonthNames[X]]);
    end else
      Result := 'N/A';
  end;

  function ServiceCode : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 5, 3));
  end;

  function PVKI : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 8, 1));
  end;

  function PVV : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 9, 4));
  end;

  function CVV : Integer;
  var
    S : string;
  begin
    S := AditionalData;
    Result := StrToInt(Copy(S, Length(S) - 8, 3));
  end;

var
  P, B : string;
  C    : TCardScheme;
  X    : Integer;
begin
  // Check if data is valid Track 1
  if not IsValidData then
    Application.MessageBox(TrackInvalidData, PChar(Application.Title), MB_ICONWARNING + MB_OK)
  else
  // Parse / Decode track data
  with memDecodedData.Lines do
  begin
    // Begin Update
    BeginUpdate;
    // Log Header
    Add(Format(TrackLogHeader, [1]));
    // PAN
    P := PAN;
    // Save PAN for decoder
    DecoderPAN := P;
    // Find card scheme
    C := FindCardScheme(P);
    Add(Format(TrackLogPAN, [FormatPAN(P, C), CardSchemeToStr(C), IfThen(IsLuhnValid(P), TrackLogLUHNValid, TrackLogLUHNInValid)]));
    // BIN
    B := FormatBIN(C, P);
    if Length(B) > 0 then Add(B);
    // Card Holder
    Add(Format(TrackLogName, [CardHolder(True), CardHolder(False)]));
    // Expiry
    Add(Format(TrackLogEXP, [ExpiryYear, ExpiryMonth]));
    // Service Code
    X := ServiceCode;
    Add(Format(TrackLogSC, [3, X, ServiceCodeDigit(X, 1), ServiceCodeDigit(X, 2), ServiceCodeDigit(X, 3)]));
    // PVKI
    Add(Format(TrackLogPVKI, [PVKI]));
    // PVV
    Add(Format(TrackLogPVV, [4, PVV]));
    // CVV
    Add(Format(TrackLogCVV, [3, CVV]));
    // End Update
    EndUpdate;
  end;
end;

{*******************************************************}
{                    Parse Track 2                      }
{*******************************************************}
procedure TfrmTracksDecode.ParseTrack2(const Track: string);

  function IsValidData : Boolean;
  begin
    Result := TRegEx.IsMatch(Track, Track2RegEx);
  end;

  function PAN : string;
  var
    PS, PE : Integer;
  begin
    // Start Position
    PS := 1;
    // If there is a start sentinel, move the start position
    if (Track[PS] = MST2StartSentinel) then Inc(PS);
    // Get the position of the field seperator
    PE := Pos(Track2FieldSeperator, Track) - PS;
    // Extract PAN from track
    Result := Copy(Track, PS, PE);
  end;

  function AditionalData : string;
  var
    PS : Integer;
  begin
    PS := Pos(Track2FieldSeperator, Track);
    Result := Copy(Track, PS +1, Length(Track));
  end;

  function ExpiryYear : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 1, 2), X) then
    begin
      Result := 2000 + X;
    end else
      Result := CurrentYear;
  end;

  function ExpiryMonth : string;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 3, 2), X) then
    begin
      Result := Format('%.*d (%s)', [2, X, LongMonthNames[X]]);
    end else
      Result := 'N/A';
  end;

  function ServiceCode : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 5, 3));
  end;

  function PVKI : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 8, 1));
  end;

  function PVV : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 9, 4));
  end;

  function CVV : Integer;
  begin
    Result := StrToInt(Copy(AditionalData, 13, 3));
  end;
var
  P, B : string;
  C    : TCardScheme;
  X    : Integer;
begin
  // Check if data is valid Track 2
  if not IsValidData then
    Application.MessageBox(TrackInvalidData, PChar(Application.Title), MB_ICONWARNING + MB_OK)
  else
  // Parse / Decode track data
  with memDecodedData.Lines do
  begin
    // Begin Update
    BeginUpdate;
    // Log Header
    Add(Format(TrackLogHeader, [2]));
    // PAN
    P := PAN;
    // Save PAN for decoder
    DecoderPAN := P;
    // Find card scheme
    C := FindCardScheme(P);
    Add(Format(TrackLogPAN, [FormatPAN(P, C), CardSchemeToStr(C), IfThen(IsLuhnValid(P), TrackLogLUHNValid, TrackLogLUHNInValid)]));
    // BIN
    B := FormatBIN(C, P);
    if Length(B) > 0 then Add(B);
    // Expiry
    Add(Format(TrackLogEXP, [ExpiryYear, ExpiryMonth]));
    // Service Code
    X := ServiceCode;
    Add(Format(TrackLogSC, [3, X, ServiceCodeDigit(X, 1), ServiceCodeDigit(X, 2), ServiceCodeDigit(X, 3)]));
    // PVKI
    Add(Format(TrackLogPVKI, [PVKI]));
    // PVV
    Add(Format(TrackLogPVV, [4, PVV]));
    // CVV
    Add(Format(TrackLogCVV, [3, CVV]));
    // End Update
    EndUpdate;
  end;
end;

{*******************************************************}
{                    Parse Track 3                      }
{*******************************************************}
procedure TfrmTracksDecode.ParseTrack3(const Track: string);

  function IsValidData : Boolean;
  begin
    Result := TRegEx.IsMatch(Track, Track3RegEx);
  end;

  function PAN : string;
  var
    PS, PE : Integer;
  begin
    // Start Position
    PS := 1;
    // If there is a start sentinel, move the start position
    if (Track[PS] = MST2StartSentinel) then Inc(PS);
    // First 2 digits are format code
    Inc(PS, 2);
    // Get the position of the field seperator
    PE := Pos(Track2FieldSeperator, Track) - PS;
    // Extract PAN from track
    Result := Copy(Track, PS, PE);
  end;

  function AditionalData : string;
  var
    PS : Integer;
  begin
    PS := Pos(Track2FieldSeperator, Track);
    Result := Copy(Track, PS +1, Length(Track));
  end;

  function ExpiryYear : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 35, 2), X) then
    begin
      Result := 2000 + X;
    end else
      Result := CurrentYear;
  end;

  function ExpiryMonth : string;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 37, 2), X) then
    begin
      Result := Format('%.*d (%s)', [2, X, LongMonthNames[X]]);
    end else
      Result := 'N/A';
  end;

  function CountryCode : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 1, 3), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function CurrencyCode : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 4, 3), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function CurrencyExponent : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 7, 1), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function AmountAuthorized : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 8, 4), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function AmountRemaining : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 12, 4), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function CycleBeginYear : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 16, 2), X) then
    begin
      Result := 2000 + X;
    end else
      Result := 0;
  end;

  function CycleBeginMonth : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 18, 2), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function CycleLength : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 20, 2), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function RetryCount : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 22, 1), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function PCP : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 23, 6), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function IC : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 29, 1), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function PSR : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 30, 2), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function SAN1 : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 32, 2), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function SAN2 : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 34, 2), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

  function CSN : Integer;
  var
    X : Integer;
  begin
    if TryStrToInt(Copy(AditionalData, 40, 1), X) then
    begin
      Result := X;
    end else
      Result := 0;
  end;

var
  P, B : string;
  C    : TCardScheme;
  X    : Integer;
begin
  // Check if data is valid Track 2
  if not IsValidData then
    Application.MessageBox(TrackInvalidData, PChar(Application.Title), MB_ICONWARNING + MB_OK)
  else
  // Parse / Decode track data
  with memDecodedData.Lines do
  begin
    // Begin Update
    BeginUpdate;
    // Log Header
    Add(Format(TrackLogHeader, [3]));
    // PAN
    P := PAN;
    // Save PAN for decoder
    DecoderPAN := P;
    // Find card scheme
    C := FindCardScheme(P);
    Add(Format(TrackLogPAN, [FormatPAN(P, C), CardSchemeToStr(C), IfThen(IsLuhnValid(P), TrackLogLUHNValid, TrackLogLUHNInValid)]));
    // BIN
    B := FormatBIN(C, P);
    if Length(B) > 0 then Add(B);
    // Expiry
    Add(Format(TrackLogEXP, [ExpiryYear, ExpiryMonth]));
    // Country Code
    X := CountryCode;
    Add(Format(TrackLogCtyCode, [3, X, CountryCodeToStr(X)]));
    // Currency Code
    X := CurrencyCode;
    Add(Format(TrackLogCurCode, [3, X, CurrencyCodeToStr(X)]));
    // Currency Exponent
    Add(Format(TrackLogCExp, [1, CurrencyExponent]));
    // Amount Authorized
    Add(Format(TrackLogAmntA, [4, AmountAuthorized]));
    // Amount Remaining
    Add(Format(TrackLogAmntR, [4, AmountRemaining]));
    // Retry count
    Add(Format(TrackLogRetryC, [RetryCount]));
    // Cycle Begin
    X := CycleBeginMonth;
    Add(Format(TrackLogCycleB, [2, X, LongMonthNames[X], 4, CycleBeginYear]));
    // Cycle Length
    Add(Format(TrackLogCycleL, [2, CycleLength]));
    // Pin Control Parameters
    Add(Format(TrackLogPCP, [6, PCP]));
    // Interchange Control
    Add(Format(TrackLogIC, [IC]));
    // PAN Service Restriction
    Add(Format(TrackLogPSR, [2, PSR]));
    // Card Sequence Number
    Add(Format(TrackLogCSN, [CSN]));
    // SAN-1 Service Restriction
    Add(Format(TrackLogSAN1, [2, SAN1]));
    // SAN-2 Service Restriction
    Add(Format(TrackLogSAN1, [2, SAN2]));
    // End Update
    EndUpdate;
  end;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmTracksDecode.FormCreate(Sender: TObject);
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Set default to track 1
  cbTrack.ItemIndex := 0;
  // Clear memo's
  memTrack.Clear;
  memDecodedData.Clear;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmTracksDecode.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  Release;
  frmTracksDecode := nil;
end;

{*******************************************************}
{                   Decode Track Data                   }
{*******************************************************}
procedure TfrmTracksDecode.btnDecodeClick(Sender: TObject);
begin
  // Clear output memo
  memDecodedData.Clear;
  // Decode / Parse track data
  case cbTrack.ItemIndex of
    0 : ParseTrack1(memTrack.Text);
    1 : ParseTrack2(memTrack.Text);
    2 : ParseTrack3(memTrack.Text);
  end;
end;

{*******************************************************}
{                      Check BIN                        }
{*******************************************************}
procedure TfrmTracksDecode.btnCheckBINClick(Sender: TObject);
begin
  with TfrmCheckBIN.Create(Application) do Execute(DecoderPAN);
end;

{*******************************************************}
{           Save Decoded Track Data to file             }
{*******************************************************}
procedure TfrmTracksDecode.Savetofile1Click(Sender: TObject);
begin
  if SaveDialog.Execute(Handle) and (Length(SaveDialog.FileName) > 0) then
  begin
    memDecodedData.Lines.SaveToFile(SaveDialog.FileName);
  end;
end;

end.
