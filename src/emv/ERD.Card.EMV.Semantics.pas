unit ERD.Card.EMV.Semantics;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Invalid EMV semantic input length, tag or selected specification.</summary>
  EEmvSemanticError = class(EConvertError);

  /// <summary>Explicit EMV Book 3/4 version; later biometric/ECC/XDA allocations stay reserved on older profiles.</summary>
  TEmvSemanticVersion = (
    /// <summary>EMV 4.3 Book 3/4; later XDA/biometric/ECC terminal allocations stay reserved.</summary>
    esv43,
    /// <summary>EMV 4.4 Book 3/4, including XDA, biometric and ECC terminal allocations.</summary>
    esv44);

  /// <summary>One raw bit with its version-specific meaning.</summary>
  TEmvBitMeaning = record
    /// <summary>One-based byte offset.</summary>
    ByteNumber: Integer;
    /// <summary>EMV bit number, eight through one in output order.</summary>
    BitNumber: Integer;
    /// <summary>Whether the input bit is set.</summary>
    IsSet: Boolean;
    /// <summary>Whether Book 3 assigns a meaning; false includes contactless-reserved bits.</summary>
    Known: Boolean;
    /// <summary>Meaning or explicit reserved designation; no risk or authorization decision.</summary>
    Meaning: string;
  end;

  /// <summary>Every raw bit, including unset/reserved bits, in byte/MSB order.</summary>
  TEmvBitMeanings = array of TEmvBitMeaning;

  /// <summary>One CVM rule, preserving method flags and proprietary conditions.</summary>
  TEmvCvmRule = record
    /// <summary>Unmodified first rule byte.</summary>
    RawMethod: Byte;
    /// <summary>Low six-bit method identifier.</summary>
    Method: Byte;
    /// <summary>Unmodified condition code.</summary>
    Condition: Byte;
    /// <summary>Bit seven requests applying the next rule after unsuccessful verification.</summary>
    ContinueOnFailure: Boolean;
    /// <summary>Reserved bit eight was set; preserve rather than silently masking it away.</summary>
    ReservedBitSet: Boolean;
    /// <summary>Method is assigned by the selected Book 3 version.</summary>
    MethodKnown: Boolean;
    /// <summary>Condition is assigned by Book 3.</summary>
    ConditionKnown: Boolean;
    /// <summary>Version-specific method name or reserved/proprietary designation.</summary>
    MethodMeaning: string;
    /// <summary>Condition name; no currency or threshold comparison performed.</summary>
    ConditionMeaning: string;
  end;

  /// <summary>Ordered rules, with independent record storage.</summary>
  TEmvCvmRules = array of TEmvCvmRule;

  /// <summary>CVM List 8E; thresholds are unsigned binary values, not BCD.</summary>
  TEmvCvmList = record
    /// <summary>Four-byte unsigned binary Amount X; application currency interpretation is external.</summary>
    AmountX: Cardinal;
    /// <summary>Four-byte unsigned binary Amount Y.</summary>
    AmountY: Cardinal;
    /// <summary>Rules in supplied order; no automatic execution or PIN verification.</summary>
    Rules: TEmvCvmRules;
  end;

  /// <summary>Three-byte CVM Results 9F34, retaining the terminal's reported method and outcome.</summary>
  TEmvCvmResult = record
    /// <summary>Last performed rule with unmodified method flags and condition code.</summary>
    Rule: TEmvCvmRule;
    /// <summary>True only for the explicit 3F no-CVM-performed encoding.</summary>
    NoCvmPerformed: Boolean;
    /// <summary>Unmodified result byte; zero means unknown, one failed, two successful.</summary>
    ResultCode: Byte;
    /// <summary>Whether the result byte has an assigned encoding, including unknown outcome zero.</summary>
    ResultKnown: Boolean;
    /// <summary>Reported outcome or reserved designation; does not independently verify a CVM.</summary>
    ResultMeaning: string;
  end;

  /// <summary>Offline EMV Book 3/4 semantic decoding with exact lengths and explicit version.</summary>
  TEmvSemanticCodec = class
  public
    /// <summary>Decodes AIP 82, AUC 9F07, TVR 95, IAC 9F0D/0E/0F or terminal capabilities 9F33/9F40.</summary>
    /// <param name="ATag">One of the eight supported bit-field tags; unknown tags fail explicitly.</param>
    /// <param name="AValue">Exactly two bytes for AIP/AUC, three for 9F33 or five for TVR/IAC/9F40.</param>
    /// <param name="AVersion">Explicit EMV 4.3/4.4 allocation; no contactless kernel assumptions.</param>
    /// <returns>All bits including reserved/unknown values; IAC bits describe policy criteria.</returns>
    /// <exception cref="EEmvSemanticError">Unsupported tag/version or incorrect value size.</exception>
    class function DecodeBits(const ATag: Cardinal; const AValue: TBytes;
      const AVersion: TEmvSemanticVersion = esv44): TEmvBitMeanings; static;

    /// <summary>Decodes CVM List 8E, preserving proprietary methods/conditions and flags.</summary>
    /// <param name="AValue">Eight-byte thresholds followed by one through 123 two-byte rules.</param>
    /// <param name="AVersion">Explicit Book 3 version for biometric method meanings.</param>
    /// <returns>Unsigned amounts and ordered rules, without executing a CVM.</returns>
    /// <exception cref="EEmvSemanticError">Invalid version, incomplete/empty/oversized list.</exception>
    class function DecodeCvmList(const AValue: TBytes;
      const AVersion: TEmvSemanticVersion = esv44): TEmvCvmList; static;

    /// <summary>Decodes CVM Results 9F34, including no-CVM-performed and reserved outcomes.</summary>
    /// <param name="AValue">Exactly three bytes: method code, condition code and result code.</param>
    /// <param name="AVersion">Explicit EMV version for method allocation.</param>
    /// <returns>Raw rule and reported result; no verification or consistency repair is performed.</returns>
    /// <exception cref="EEmvSemanticError">Unsupported version or incorrect value size.</exception>
    class function DecodeCvmResults(const AValue: TBytes;
      const AVersion: TEmvSemanticVersion = esv44): TEmvCvmResult; static;
  end;

implementation

procedure Invalid;
begin
  raise EEmvSemanticError.Create('Invalid EMV semantic value, tag or version.');
end;

class function TEmvSemanticCodec.DecodeBits(const ATag: Cardinal;
  const AValue: TBytes; const AVersion: TEmvSemanticVersion): TEmvBitMeanings;
const
  Aip: array[0..15] of string = ('XDA supported', 'SDA supported', 'DDA supported',
    'Cardholder verification supported', 'Terminal risk management required',
    'Issuer authentication supported', '', 'CDA supported', '', '', '', '', '', '', '', '');
  Auc: array[0..15] of string = ('Domestic cash allowed', 'International cash allowed',
    'Domestic goods allowed', 'International goods allowed', 'Domestic services allowed',
    'International services allowed', 'ATM use allowed', 'Non-ATM terminal use allowed',
    'Domestic cashback allowed', 'International cashback allowed', '', '', '', '', '', '');
  Tvr: array[0..39] of string = ('Offline authentication not performed', 'SDA failed',
    'Required ICC data missing', 'Card on terminal exception list', 'DDA failed', 'CDA failed',
    'SDA selected', 'XDA selected', 'Application versions differ', 'Application expired',
    'Application not yet effective', 'Service disallowed by card product', 'New card', '',
    'Biometric performed successfully', 'Biometric template format unsupported',
    'Cardholder verification unsuccessful', 'CVM unrecognised', 'PIN try limit reached',
    'PIN required but PIN pad absent or unavailable', 'PIN required but entry bypassed',
    'Online CVM captured', 'Biometric required but capture device unavailable',
    'Biometric subtype entry bypassed', 'Amount exceeds floor limit',
    'Lower consecutive offline limit exceeded', 'Upper consecutive offline limit exceeded',
    'Randomly selected for online processing', 'Merchant forced online processing', '', '', '',
    'Default TDOL used', 'Issuer authentication failed', 'Script failed before final GENERATE AC',
    'Script failed after final GENERATE AC', '', 'Biometric try limit reached',
    'Selected biometric type unsupported', 'XDA signature failed');
  Terminal: array[0..23] of string = ('Manual key entry', 'Magnetic stripe',
    'IC with contacts', '', '', '', '', '', 'Plaintext PIN for ICC verification',
    'Enciphered PIN for online verification', 'Signature',
    'Enciphered PIN for offline verification (RSA ODE)', 'No CVM required',
    'Online biometric', 'Offline biometric', 'Enciphered PIN for offline verification (ECC ODE)',
    'SDA supported', 'DDA supported', 'Card capture', '', 'CDA supported', 'XDA supported', '', '');
  Additional: array[0..39] of string = ('Cash', 'Goods', 'Services', 'Cashback',
    'Inquiry', 'Transfer', 'Payment', 'Administrative', 'Cash deposit', '', '', '', '', '', '', '',
    'Numeric keys', 'Alphabetic and special character keys', 'Command keys', 'Function keys',
    '', '', '', '', 'Print or electronic, attendant', 'Print or electronic, cardholder',
    'Display, attendant', 'Display, cardholder', '', '', 'ISO/IEC 8859 code table 10',
    'ISO/IEC 8859 code table 9', 'ISO/IEC 8859 code table 8', 'ISO/IEC 8859 code table 7',
    'ISO/IEC 8859 code table 6', 'ISO/IEC 8859 code table 5', 'ISO/IEC 8859 code table 4',
    'ISO/IEC 8859 code table 3', 'ISO/IEC 8859 code table 2', 'ISO/IEC 8859 code table 1');
var
  I, N: Integer;
  Meaning: string;
  Iac: Boolean;
begin
  Result := nil;
  if Ord(AVersion) > Ord(High(TEmvSemanticVersion)) then Invalid;
  Iac := (ATag = $9F0D) or (ATag = $9F0E) or (ATag = $9F0F);
  if (ATag = $82) or (ATag = $9F07) then N := 2
  else if ATag = $9F33 then N := 3
  else if (ATag = $95) or Iac or (ATag = $9F40) then N := 5
  else begin Invalid; N := 0; end;
  if Length(AValue) <> N then Invalid;
  SetLength(Result, N * 8);
  for I := 0 to High(Result) do
  begin
    if ATag = $82 then Meaning := Aip[I]
    else if ATag = $9F07 then Meaning := Auc[I]
    else if ATag = $9F33 then Meaning := Terminal[I]
    else if ATag = $9F40 then Meaning := Additional[I]
    else Meaning := Tvr[I];
    if AVersion = esv43 then
    begin
      if (ATag = $82) and (I = 0) then Meaning := '';
      if (ATag = $9F33) and (I in [13, 14, 15, 21]) then Meaning := '';
      if (ATag = $9F33) and (I = 11) then Meaning := 'Enciphered PIN for offline verification';
      if (ATag = $9F40) and (I = 24) then Meaning := 'Print, attendant';
      if (ATag = $9F40) and (I = 25) then Meaning := 'Print, cardholder';
      if ((ATag = $95) or Iac) and (I in [7, 14, 15, 22, 23, 37, 38, 39]) then Meaning := '';
      if ((ATag = $95) or Iac) and (I = 21) then Meaning := 'Online PIN entered';
    end;
    Result[I].ByteNumber := I div 8 + 1;
    Result[I].BitNumber := 8 - I mod 8;
    Result[I].IsSet := AValue[I div 8] and (1 shl (7 - I mod 8)) <> 0;
    Result[I].Known := Meaning <> '';
    if Meaning = '' then
    begin
      Meaning := 'Reserved';
      if (ATag = $82) and (I in [6, 8, 9, 10, 15]) then
        Meaning := 'Reserved for contactless specifications';
    end
    else if Iac then Meaning := 'Issuer action criterion: ' + Meaning;
    Result[I].Meaning := Meaning;
  end;
end;

function DescribeCvmMethod(const Code: Byte; const Version: TEmvSemanticVersion): string;
const
  Biometrics: array[6..15] of string = ('Offline facial biometric', 'Online facial biometric',
    'Offline finger biometric', 'Online finger biometric', 'Offline palm biometric',
    'Online palm biometric', 'Offline iris biometric', 'Online iris biometric',
    'Offline voice biometric', 'Online voice biometric');
begin
  case Code of
    $00: Result := 'Fail CVM processing';
    $01: Result := 'Plaintext PIN verified by ICC';
    $02: Result := 'Enciphered online PIN';
    $03: Result := 'Plaintext ICC PIN and signature';
    $04: Result := 'Enciphered PIN verified by ICC';
    $05: Result := 'Enciphered ICC PIN and signature';
    $1E: Result := 'Signature';
    $1F: Result := 'No CVM required';
  else
    Result := '';
    if (Version = esv44) and (Code in [6..15]) then Result := Biometrics[Code];
  end;
end;

function DecodeCvmRule(const RawMethod, Condition: Byte;
  const Version: TEmvSemanticVersion): TEmvCvmRule;
const
  Conditions: array[0..9] of string = ('Always', 'Unattended cash',
    'Not unattended cash, manual cash or cashback', 'Terminal supports this CVM',
    'Manual cash', 'Purchase with cashback', 'Application currency and amount below X',
    'Application currency and amount above X', 'Application currency and amount below Y',
    'Application currency and amount above Y');
var
  Code: Byte;
begin
  Result := Default(TEmvCvmRule);
  Code := RawMethod and $3F;
  Result.RawMethod := RawMethod; Result.Method := Code; Result.Condition := Condition;
  Result.ContinueOnFailure := RawMethod and $40 <> 0;
  Result.ReservedBitSet := RawMethod and $80 <> 0;
  Result.MethodMeaning := DescribeCvmMethod(Code, Version);
  Result.MethodKnown := Result.MethodMeaning <> '';
  if not Result.MethodKnown then
  begin
    if Code in [$20..$2F] then Result.MethodMeaning := 'Payment-system-specific CVM'
    else if Code in [$30..$3E] then Result.MethodMeaning := 'Issuer-specific CVM'
    else Result.MethodMeaning := 'Reserved/unavailable CVM';
  end;
  Result.ConditionKnown := Condition <= 9;
  if Condition <= 9 then Result.ConditionMeaning := Conditions[Condition]
  else if Condition >= $80 then Result.ConditionMeaning := 'Payment-system-specific condition'
  else Result.ConditionMeaning := 'Reserved condition';
end;

class function TEmvSemanticCodec.DecodeCvmList(const AValue: TBytes;
  const AVersion: TEmvSemanticVersion): TEmvCvmList;
var
  I, Offset: Integer;
  function BinaryAmount(const Start: Integer): Cardinal;
  var
    J: Integer;
  begin
    Result := 0;
    for J := Start to Start + 3 do Result := (Result shl 8) or AValue[J];
  end;
begin
  Result := Default(TEmvCvmList);
  if (Ord(AVersion) > Ord(High(TEmvSemanticVersion))) or (Length(AValue) < 10) or
    (Length(AValue) > 254) or (Length(AValue) mod 2 <> 0) then Invalid;
  Result.AmountX := BinaryAmount(0); Result.AmountY := BinaryAmount(4);
  SetLength(Result.Rules, (Length(AValue) - 8) div 2);
  for I := 0 to High(Result.Rules) do
  begin
    Offset := 8 + I * 2;
    Result.Rules[I] := DecodeCvmRule(AValue[Offset], AValue[Offset + 1], AVersion);
  end;
end;

class function TEmvSemanticCodec.DecodeCvmResults(const AValue: TBytes;
  const AVersion: TEmvSemanticVersion): TEmvCvmResult;
begin
  Result := Default(TEmvCvmResult);
  if (Ord(AVersion) > Ord(High(TEmvSemanticVersion))) or (Length(AValue) <> 3) then Invalid;
  Result.Rule := DecodeCvmRule(AValue[0], AValue[1], AVersion);
  Result.NoCvmPerformed := AValue[0] = $3F;
  if Result.NoCvmPerformed then
  begin
    Result.Rule.MethodKnown := True;
    Result.Rule.MethodMeaning := 'No CVM performed';
    if AValue[1] = 0 then Result.Rule.ConditionMeaning := 'No CVM condition (no CVM performed)';
  end;
  Result.ResultCode := AValue[2];
  Result.ResultKnown := AValue[2] <= 2;
  case AValue[2] of
    0: Result.ResultMeaning := 'Unknown';
    1: Result.ResultMeaning := 'Failed';
    2: Result.ResultMeaning := 'Successful';
  else Result.ResultMeaning := 'Reserved result'; end;
end;

end.
