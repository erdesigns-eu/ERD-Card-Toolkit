unit ERD.Card.EMV.Calculator;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Crypto, ERD.Card.Crypto.DES, ERD.Card.Crypto.Hash;

const
  /// <summary>Maximum unpadded calculation input; padding remains within provider limits.</summary>
  EmvCalculatorMaxData = 1048560;

type
  /// <summary>Invalid explicit calculation input; error messages never include keys or card data.</summary>
  EEmvCalculationError = class(ECardCryptoError);

  /// <summary>Explicit ISO/IEC 9797-1 padding, independent of a guessed card brand or CVN.</summary>
  TEmvMacPadding = (
    /// <summary>Zero padding; aligned messages retain their length; empty input forms one zero block.</summary>
    empMethod1,
    /// <summary>Append 80 and zeroes; aligned and empty messages receive an additional block.</summary>
    empMethod2);

  /// <summary>EMV Book 2 Annex A1.4 ICC master-key diversification.</summary>
  TEmvMasterKeyMethod = (
    /// <summary>Rightmost sixteen PAN/PSN digits, left zero padded.</summary>
    emkOptionA,
    /// <summary>Option A for PANs up to sixteen digits; SHA-1 decimalization for longer PANs.</summary>
    emkOptionB);

  /// <summary>Explicit issuer-script confidentiality formatting; these methods perform no card I/O.</summary>
  TEmvScriptEncryption = (
    /// <summary>Length-prefixed method-two padded data encrypted with two-key Triple DES ECB.</summary>
    eseVisa,
    /// <summary>Zero-IV CBC; method-two padding only for unaligned data.</summary>
    eseMastercard,
    /// <summary>Zero-IV CBC with method-two padding for every input.</summary>
    eseEmv);

  /// <summary>Explicit independently checked legacy cryptogram profile; the issuer selects the profile.</summary>
  TEmvCryptogramProfile = (
    /// <summary>Visa CVN 10: static AC key, CVR and method-one padding.</summary>
    ecpVisa10,
    /// <summary>Visa CVN 18: common ATC key, complete IAD and ARPC method two.</summary>
    ecpVisa18,
    /// <summary>Visa CVN 22: common ATC AC key, complete IAD and ARPC method two.</summary>
    ecpVisa22,
    /// <summary>Mastercard CVN 16: ATC/UN key, CVR, static ARPC key.</summary>
    ecpMastercard16,
    /// <summary>Mastercard CVN 17: ATC/UN key, CVR and eight clear counter bytes.</summary>
    ecpMastercard17,
    /// <summary>Mastercard CVN 20: common ATC key and CVR.</summary>
    ecpMastercard20,
    /// <summary>Mastercard CVN 21: common ATC key, CVR and eight clear counter bytes.</summary>
    ecpMastercard21,
    /// <summary>Interac CVN 133: ATC/UN key and complete IAD.</summary>
    ecpInterac133);

  /// <summary>Explicit cryptogram fields; values are borrowed and never inferred from issuer data.</summary>
  TEmvCryptogramData = record
    /// <summary>Tag 9F02: six packed-numeric amount bytes.</summary>
    AmountAuthorized: TBytes;

    /// <summary>Tag 9F03: six packed-numeric amount bytes.</summary>
    AmountOther: TBytes;

    /// <summary>Tag 9F1A: two packed-numeric country bytes.</summary>
    TerminalCountry: TBytes;

    /// <summary>Tag 95: five binary TVR bytes.</summary>
    TerminalVerificationResults: TBytes;

    /// <summary>Tag 5F2A: two packed-numeric currency bytes.</summary>
    Currency: TBytes;

    /// <summary>Tag 9A: three packed-numeric YYMMDD bytes.</summary>
    TransactionDate: TBytes;

    /// <summary>Tag 9C: one packed-numeric transaction-type byte.</summary>
    TransactionType: TBytes;

    /// <summary>Tag 9F37: four binary bytes.</summary>
    UnpredictableNumber: TBytes;

    /// <summary>Tag 82: two binary AIP bytes.</summary>
    ApplicationInterchangeProfile: TBytes;

    /// <summary>Tag 9F36: two binary big-endian ATC bytes.</summary>
    Atc: TBytes;

    /// <summary>Complete tag 9F10: one through thirty-two bytes for profiles using IAD.</summary>
    IssuerApplicationData: TBytes;

    /// <summary>Explicit extracted CVR: four bytes for Visa 10; six for Mastercard.</summary>
    CardVerificationResults: TBytes;

    /// <summary>Eight decrypted counter bytes for Mastercard 17/21; other profiles require absence.</summary>
    Counters: TBytes;

  end;

  /// <summary>Nonvisual offline EMV calculation toolkit; construction opens no card or crypto library.</summary>
  /// <remarks>Supply maintained DES/AES/hash providers at runtime. Functions borrow inputs and return
  /// independent buffers. The component retains providers but never keys. Clear secret outputs after use.
  /// Configure on one thread; independent calculations are reentrant with thread-safe providers.
  /// No automatic CVN detection, GENERATE AC, PIN verification or payment processing occurs.</remarks>
  TEmvCalculator = class(TComponent)
  private
    FDesProvider: ICardDesProvider;
    FAesProvider: ICardAesProvider;
    FHashProvider: ICardHashProvider;
    function Ecb(const AKey, AData: TBytes; const AEncrypt: Boolean): TBytes;
    function TreeStep(const AKey, AValue: TBytes; const AIndex: Cardinal): TBytes;
  public
    /// <summary>Maintained DES capability; required for Triple DES-based calculations.</summary>
    property DesProvider: ICardDesProvider read FDesProvider write FDesProvider;

    /// <summary>Optional maintained AES-128 capability for CMAC and AES key check values.</summary>
    property AesProvider: ICardAesProvider read FAesProvider write FAesProvider;

    /// <summary>Optional SHA-1 backend; required only for Option B PANs longer than sixteen digits.</summary>
    property HashProvider: ICardHashProvider read FHashProvider write FHashProvider;

    /// <summary>Assembles and validates the complete cryptogram input for an explicit supported profile.</summary>
    /// <param name="AProfile">Explicit CVN and scheme; invalid enum values are refused.</param>
    /// <param name="AData">Exact tag fields plus profile CVR/IAD/counters; unrelated tails must be absent.</param>
    /// <returns>Owned unpadded cryptogram message; numeric fields require decimal BCD nibbles.</returns>
    class function BuildCryptogramData(const AProfile: TEmvCryptogramProfile;
      const AData: TEmvCryptogramData): TBytes; static;

    /// <summary>Derives the explicit profile's AC session key from the supplied ICC AC master key.</summary>
    /// <param name="AProfile">Explicit scheme and CVN.</param>
    /// <param name="AMasterKey">Exactly sixteen ICC AC master-key bytes.</param>
    /// <param name="AAtc">Exactly two counter bytes.</param>
    /// <param name="AUnpredictableNumber">Exactly four unpredictable-number bytes.</param>
    /// <returns>Independent sixteen-byte key; Visa 10 returns an unchanged master-key copy.</returns>
    function DeriveProfileSessionKey(const AProfile: TEmvCryptogramProfile;
      const AMasterKey, AAtc, AUnpredictableNumber: TBytes): TBytes;

    /// <summary>Assembles profile data, derives the profile key and calculates an eight-byte AC offline.</summary>
    /// <param name="AProfile">Explicit supported scheme/CVN; never inferred.</param>
    /// <param name="AMasterKey">Exactly sixteen ICC AC master-key bytes.</param>
    /// <param name="AData">Complete explicit cryptogram fields and required issuer-specific tail.</param>
    /// <returns>Independent eight-byte ARQC, TC or AAC calculation.</returns>
    function ProfileCryptogram(const AProfile: TEmvCryptogramProfile;
      const AMasterKey: TBytes; const AData: TEmvCryptogramData): TBytes;

    /// <summary>Calculates profile ARPC method one, including the static Mastercard 16/17 ARPC key.</summary>
    /// <param name="AProfile">Visa 10, Mastercard 16/17/20/21 or Interac 133.</param>
    /// <param name="AMasterKey">Exactly sixteen ICC AC master-key bytes.</param>
    /// <param name="AAtc">Exactly two counter bytes.</param>
    /// <param name="AUnpredictableNumber">Exactly four unpredictable-number bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="AResponseCode">Exactly two explicit response-code bytes.</param>
    /// <returns>Independent eight-byte ARPC; method-two profiles are refused.</returns>
    function ProfileArpc1(const AProfile: TEmvCryptogramProfile;
      const AMasterKey, AAtc, AUnpredictableNumber, AArqc, AResponseCode: TBytes): TBytes;

    /// <summary>Calculates Visa 18/22 ARPC method two using the common ATC-derived key.</summary>
    /// <param name="AProfile">Visa 18 or Visa 22 only.</param>
    /// <param name="AMasterKey">Exactly sixteen ICC AC master-key bytes.</param>
    /// <param name="AAtc">Exactly two counter bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="ACsu">Exactly four card-status-update bytes.</param>
    /// <param name="AAuthenticationData">Zero through eight proprietary bytes.</param>
    /// <returns>Independent four-byte ARPC; other profiles are refused.</returns>
    function ProfileArpc2(const AProfile: TEmvCryptogramProfile;
      const AMasterKey, AAtc, AArqc, ACsu, AAuthenticationData: TBytes): TBytes;

    /// <summary>Returns a copied DES key with odd parity in each byte.</summary>
    /// <param name="AKey">Eight, sixteen or twenty-four bytes.</param>
    /// <returns>Independent parity-adjusted key; cipher-effective bits are unchanged.</returns>
    class function AdjustOddParity(const AKey: TBytes): TBytes; static;

    /// <summary>Checks odd DES parity without modifying the supplied key.</summary>
    /// <param name="AKey">Eight, sixteen or twenty-four bytes.</param>
    /// <returns>True when every byte has odd parity.</returns>
    class function HasOddParity(const AKey: TBytes): Boolean; static;

    /// <summary>Applies an explicit ISO 9797-1 padding method.</summary>
    /// <param name="AData">Zero through EmvCalculatorMaxData borrowed bytes.</param>
    /// <param name="APadding">Method one or two; invalid enum values are refused.</param>
    /// <returns>Independent complete eight-byte blocks.</returns>
    class function Pad(const AData: TBytes; const APadding: TEmvMacPadding): TBytes; static;

    /// <summary>Calculates a Triple DES KCV by encrypting one all-zero block.</summary>
    /// <param name="AKey">Eight, sixteen or twenty-four explicit key bytes.</param>
    /// <param name="ALength">One through eight leading result bytes; usually three.</param>
    /// <returns>Independent truncated encrypted-zero result.</returns>
    function KeyCheckValue(const AKey: TBytes; const ALength: Integer = 3): TBytes;

    /// <summary>Calculates an AES-128 encrypted-zero KCV; this is not a CMAC-based KCV.</summary>
    /// <param name="AKey">Exactly sixteen AES key bytes.</param>
    /// <param name="ALength">One through sixteen leading result bytes.</param>
    /// <returns>Independent truncated encrypted-zero result.</returns>
    function AesKeyCheckValue(const AKey: TBytes; const ALength: Integer = 3): TBytes;

    /// <summary>Derives a two-key ICC master key using EMV Option A or B, with odd DES parity.</summary>
    /// <param name="AIssuerKey">Exactly sixteen issuer master-key bytes.</param>
    /// <param name="APan">One through nineteen ASCII decimal digits, preserving leading zeroes.</param>
    /// <param name="APsn">Exactly two ASCII decimal digits; use 00 when absent.</param>
    /// <param name="AMethod">Explicit Option A or B; no issuer inference.</param>
    /// <returns>Independent sixteen-byte ICC master key.</returns>
    function DeriveMasterKey(const AIssuerKey: TBytes; const APan, APsn: string;
      const AMethod: TEmvMasterKeyMethod): TBytes;

    /// <summary>Derives a common EMV session key using an explicit eight-byte diversification value.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC master-key bytes.</param>
    /// <param name="ADiversification">Exactly eight bytes; byte index two is replaced with F0/0F.</param>
    /// <returns>Independent sixteen-byte odd-parity session key.</returns>
    function DeriveCommonSessionKey(const AMasterKey, ADiversification: TBytes): TBytes;

    /// <summary>Derives an EMV common session key from ATC followed by six zero bytes.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC master-key bytes.</param>
    /// <param name="AAtc">Exactly two big-endian counter bytes.</param>
    /// <returns>Independent sixteen-byte odd-parity session key.</returns>
    function DeriveAtcSessionKey(const AMasterKey, AAtc: TBytes): TBytes;

    /// <summary>Derives a common session key from ATC, two zero bytes and unpredictable number.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC master-key bytes.</param>
    /// <param name="AAtc">Exactly two counter bytes.</param>
    /// <param name="AUnpredictableNumber">Exactly four bytes, explicitly supplied by the profile.</param>
    /// <returns>Independent sixteen-byte odd-parity session key.</returns>
    function DeriveMastercardSessionKey(const AMasterKey, AAtc,
      AUnpredictableNumber: TBytes): TBytes;

    /// <summary>Derives the Visa issuer-script session-key XOR variant.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC master-key bytes for SMI or SMC.</param>
    /// <param name="AAtc">Exactly two counter bytes; complemented for the right key half.</param>
    /// <returns>Independent sixteen-byte odd-parity key.</returns>
    function DeriveVisaScriptKey(const AMasterKey, AAtc: TBytes): TBytes;

    /// <summary>Derives the legacy EMV 2000 tree session key with an explicit tree and IV.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC master-key bytes.</param>
    /// <param name="AAtc">Exactly two counter bytes.</param>
    /// <param name="AIv">Exactly sixteen initialization-vector bytes.</param>
    /// <param name="AHeight">Tree height from two through sixteen.</param>
    /// <param name="ABranchFactor">Two through 256; capacity must cover all 65536 ATC values.</param>
    /// <returns>Independent sixteen-byte odd-parity session key.</returns>
    function DeriveTreeSessionKey(const AMasterKey, AAtc, AIv: TBytes;
      const AHeight: Integer = 8; const ABranchFactor: Integer = 4): TBytes;

    /// <summary>Computes ISO 9797-1 algorithm-three Retail MAC with explicit padding and truncation.</summary>
    /// <param name="AKey">Exactly sixteen two-key MAC key bytes.</param>
    /// <param name="AData">Complete profile-defined unpadded message; zero through EmvCalculatorMaxData bytes.</param>
    /// <param name="APadding">Explicit ISO method one or two.</param>
    /// <param name="ALength">One through eight leading MAC bytes.</param>
    /// <returns>Independent truncated MAC.</returns>
    function RetailMac(const AKey, AData: TBytes; const APadding: TEmvMacPadding;
      const ALength: Integer = 8): TBytes;

    /// <summary>Calculates ARQC, TC or AAC from an explicitly assembled application-cryptogram message.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-derived key bytes.</param>
    /// <param name="AData">Unpadded cryptogram input; CDOL data alone need not be the complete message.</param>
    /// <param name="APadding">Required profile padding; never guessed from a brand or IAD byte.</param>
    /// <returns>Independent eight-byte application cryptogram.</returns>
    function ApplicationCryptogram(const ASessionKey, AData: TBytes;
      const APadding: TEmvMacPadding): TBytes;

    /// <summary>Recomputes an application cryptogram and compares every equal-length byte.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-derived key bytes.</param>
    /// <param name="AData">Complete unpadded profile-defined message.</param>
    /// <param name="AExpected">Exactly eight received cryptogram bytes.</param>
    /// <param name="APadding">Explicit profile padding.</param>
    /// <returns>True when the independent recomputation matches.</returns>
    function VerifyApplicationCryptogram(const ASessionKey, AData, AExpected: TBytes;
      const APadding: TEmvMacPadding): Boolean;

    /// <summary>Calculates EMV ARPC method one: Triple DES of ARQC XOR response-code/zeroes.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-defined ARPC key bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="AResponseCode">Exactly two response bytes; ASCII and binary representations are not interchangeable.</param>
    /// <returns>Independent eight-byte ARPC.</returns>
    function ArpcMethod1(const ASessionKey, AArqc, AResponseCode: TBytes): TBytes;

    /// <summary>Calculates EMV ARPC method two, MACing ARQC, CSU and proprietary authentication data.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-defined ARPC key bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="ACsu">Exactly four card-status-update bytes.</param>
    /// <param name="AAuthenticationData">Zero through eight proprietary bytes.</param>
    /// <returns>Independent four-byte ARPC; CSU/authentication data are not appended to this result.</returns>
    function ArpcMethod2(const ASessionKey, AArqc, ACsu,
      AAuthenticationData: TBytes): TBytes;

    /// <summary>Recomputes and compares an eight-byte ARPC method-one result without early mismatch exit.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-defined ARPC key bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="AResponseCode">Exactly two response-code bytes.</param>
    /// <param name="AExpected">Exactly eight received ARPC bytes.</param>
    /// <returns>True only when the independently computed ARPC matches.</returns>
    function VerifyArpcMethod1(const ASessionKey, AArqc, AResponseCode, AExpected: TBytes): Boolean;

    /// <summary>Recomputes and compares a four-byte ARPC method-two result without early mismatch exit.</summary>
    /// <param name="ASessionKey">Exactly sixteen profile-defined ARPC key bytes.</param>
    /// <param name="AArqc">Exactly eight verified request cryptogram bytes.</param>
    /// <param name="ACsu">Exactly four card-status-update bytes.</param>
    /// <param name="AAuthenticationData">Zero through eight proprietary bytes.</param>
    /// <param name="AExpected">Exactly four received ARPC bytes.</param>
    /// <returns>True only when the independently computed ARPC matches.</returns>
    function VerifyArpcMethod2(const ASessionKey, AArqc, ACsu,
      AAuthenticationData, AExpected: TBytes): Boolean;

    /// <summary>Calculates AES-128 CMAC for profiles explicitly specifying AES, without DES padding.</summary>
    /// <param name="AKey">Exactly sixteen AES key bytes.</param>
    /// <param name="AData">Zero through EmvCalculatorMaxData bytes.</param>
    /// <param name="ALength">One through sixteen leading MAC bytes.</param>
    /// <returns>Independent truncated CMAC.</returns>
    function AesCmac(const AKey, AData: TBytes; const ALength: Integer = 16): TBytes;

    /// <summary>Computes issuer-script integrity over the exact caller-assembled authenticated bytes.</summary>
    /// <param name="ASessionKey">Exactly sixteen SMI session-key bytes.</param>
    /// <param name="AAuthenticatedData">Header, counters, cryptogram and data in explicit profile order.</param>
    /// <param name="ALength">Four through eight leading MAC bytes.</param>
    /// <returns>Independent method-two padded Retail MAC; no APDU is sent.</returns>
    function ScriptMac(const ASessionKey, AAuthenticatedData: TBytes;
      const ALength: Integer = 8): TBytes;

    /// <summary>Encrypts issuer-script data using an explicit legacy confidentiality format.</summary>
    /// <param name="ASessionKey">Exactly sixteen SMC session-key bytes.</param>
    /// <param name="AData">Unpadded command data; Visa limits length to 255 bytes.</param>
    /// <param name="AFormat">Explicit Visa ECB, Mastercard CBC or EMV CBC formatting.</param>
    /// <returns>Independent encrypted data; does not construct or transmit a command.</returns>
    function EncryptScriptData(const ASessionKey, AData: TBytes;
      const AFormat: TEmvScriptEncryption): TBytes;

    /// <summary>Formats an ISO 9564-1 format-two offline PIN block.</summary>
    /// <param name="APin">Four through twelve ASCII decimal digits.</param>
    /// <returns>Owned eight-byte 2/length/PIN/F-fill block; no PIN verification or card operation.</returns>
    class function FormatPinBlock2(const APin: string): TBytes; static;

    /// <summary>Formats the Visa PIN-change block from an explicit ICC AC key and optional current PIN.</summary>
    /// <param name="AMasterKey">Exactly sixteen ICC AC master-key bytes.</param>
    /// <param name="ANewPin">Four through twelve ASCII decimal digits.</param>
    /// <param name="ACurrentPin">Empty when absent; otherwise four through twelve ASCII decimal digits.</param>
    /// <returns>Owned eight-byte clear PIN-change block; caller clears it.</returns>
    class function FormatVisaPinBlock(const AMasterKey: TBytes;
      const ANewPin: string; const ACurrentPin: string = ''): TBytes; static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Invalid;
begin
  raise EEmvCalculationError.Create('Invalid EMV calculation input or provider result.');
end;

procedure RequireSize(const AData: TBytes; const ASize: Integer);
begin
  if Length(AData) <> ASize then
    Invalid;
end;

procedure RequireDigits(const AText: string; const AMinimum, AMaximum: Integer);
var
  I: Integer;
begin
  if (Length(AText) < AMinimum) or (Length(AText) > AMaximum) then
    Invalid;
  for I := 1 to Length(AText) do
    if not CharInSet(AText[I], ['0' .. '9']) then
      Invalid;
end;

function Join(const ALeft, ARight: TBytes): TBytes;
begin
  Result := nil;
  if (Length(ALeft) > EmvCalculatorMaxData) or
    (Length(ARight) > EmvCalculatorMaxData - Length(ALeft)) then
    Invalid;
  SetLength(Result, Length(ALeft) + Length(ARight));
  if Length(ALeft) > 0 then
    Move(ALeft[0], Result[0], Length(ALeft));
  if Length(ARight) > 0 then
    Move(ARight[0], Result[Length(ALeft)], Length(ARight));
end;

class function TEmvCalculator.BuildCryptogramData(const AProfile: TEmvCryptogramProfile;
  const AData: TEmvCryptogramData): TBytes;
var
  Offset: Integer;
  procedure Append(const AValue: TBytes; const ASize: Integer; const ANumeric: Boolean = False);
  var
    I: Integer;
  begin
    RequireSize(AValue, ASize);
    if ANumeric then
      for I := 0 to High(AValue) do
        if ((AValue[I] and $0F) > 9) or ((AValue[I] shr 4) > 9) then
          Invalid;
    SetLength(Result, Offset + ASize);
    if ASize > 0 then
      Move(AValue[0], Result[Offset], ASize);
    Inc(Offset, ASize);
  end;
begin
  Result := nil;
  Offset := 0;
  try
    Append(AData.AmountAuthorized, 6, True);
    Append(AData.AmountOther, 6, True);
    Append(AData.TerminalCountry, 2, True);
    Append(AData.TerminalVerificationResults, 5);
    Append(AData.Currency, 2, True);
    Append(AData.TransactionDate, 3, True);
    Append(AData.TransactionType, 1, True);
    Append(AData.UnpredictableNumber, 4);
    Append(AData.ApplicationInterchangeProfile, 2);
    Append(AData.Atc, 2);
    case AProfile of
      ecpVisa10:
        begin
          RequireSize(AData.IssuerApplicationData, 0);
          RequireSize(AData.Counters, 0);
          Append(AData.CardVerificationResults, 4);
        end;
      ecpVisa18, ecpVisa22, ecpInterac133:
        begin
          RequireSize(AData.CardVerificationResults, 0);
          RequireSize(AData.Counters, 0);
          if (Length(AData.IssuerApplicationData) < 1) or
            (Length(AData.IssuerApplicationData) > 32) then
            Invalid;
          Append(AData.IssuerApplicationData, Length(AData.IssuerApplicationData));
        end;
      ecpMastercard16, ecpMastercard17, ecpMastercard20, ecpMastercard21:
        begin
          RequireSize(AData.IssuerApplicationData, 0);
          Append(AData.CardVerificationResults, 6);
          if AProfile in [ecpMastercard17, ecpMastercard21] then
            Append(AData.Counters, 8)
          else
            RequireSize(AData.Counters, 0);
        end;
    else
      Invalid;
    end;
  except
    TCardCrypto.Clear(Result);
    raise;
  end;
end;

function TEmvCalculator.DeriveProfileSessionKey(const AProfile: TEmvCryptogramProfile;
  const AMasterKey, AAtc, AUnpredictableNumber: TBytes): TBytes;
begin
  RequireSize(AMasterKey, 16);
  RequireSize(AAtc, 2);
  RequireSize(AUnpredictableNumber, 4);
  case AProfile of
    ecpVisa10:
      Result := Copy(AMasterKey, 0, 16);
    ecpVisa18, ecpVisa22, ecpMastercard20, ecpMastercard21:
      Result := DeriveAtcSessionKey(AMasterKey, AAtc);
    ecpMastercard16, ecpMastercard17, ecpInterac133:
      Result := DeriveMastercardSessionKey(AMasterKey, AAtc, AUnpredictableNumber);
  else
    Invalid;
    Result := nil;
  end;
end;

function TEmvCalculator.ProfileCryptogram(const AProfile: TEmvCryptogramProfile;
  const AMasterKey: TBytes; const AData: TEmvCryptogramData): TBytes;
var
  Data, Key: TBytes;
  Padding: TEmvMacPadding;
begin
  Data := nil;
  Key := nil;
  try
    Data := BuildCryptogramData(AProfile, AData);
    Key := DeriveProfileSessionKey(AProfile, AMasterKey, AData.Atc, AData.UnpredictableNumber);
    Padding := empMethod2;
    if AProfile = ecpVisa10 then
      Padding := empMethod1;
    Result := ApplicationCryptogram(Key, Data, Padding);
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Key);
  end;
end;

function TEmvCalculator.ProfileArpc1(const AProfile: TEmvCryptogramProfile;
  const AMasterKey, AAtc, AUnpredictableNumber, AArqc, AResponseCode: TBytes): TBytes;
var
  Key: TBytes;
begin
  if not (AProfile in [ecpVisa10, ecpMastercard16, ecpMastercard17,
    ecpMastercard20, ecpMastercard21, ecpInterac133]) then
    Invalid;
  RequireSize(AMasterKey, 16);
  RequireSize(AAtc, 2);
  RequireSize(AUnpredictableNumber, 4);
  Key := nil;
  try
    if AProfile in [ecpMastercard16, ecpMastercard17] then
      Key := Copy(AMasterKey, 0, 16)
    else
      Key := DeriveProfileSessionKey(AProfile, AMasterKey, AAtc, AUnpredictableNumber);
    Result := ArpcMethod1(Key, AArqc, AResponseCode);
  finally
    TCardCrypto.Clear(Key);
  end;
end;

function TEmvCalculator.ProfileArpc2(const AProfile: TEmvCryptogramProfile;
  const AMasterKey, AAtc, AArqc, ACsu, AAuthenticationData: TBytes): TBytes;
var
  Key: TBytes;
begin
  if not (AProfile in [ecpVisa18, ecpVisa22]) then
    Invalid;
  Key := DeriveAtcSessionKey(AMasterKey, AAtc);
  try
    Result := ArpcMethod2(Key, AArqc, ACsu, AAuthenticationData);
  finally
    TCardCrypto.Clear(Key);
  end;
end;

class function TEmvCalculator.AdjustOddParity(const AKey: TBytes): TBytes;
var
  I, J, Ones: Integer;
begin
  Result := nil;
  if not (Length(AKey) in [8, 16, 24]) then
    Invalid;
  Result := Copy(AKey, 0, Length(AKey));
  for I := 0 to High(Result) do
  begin
    Ones := 0;
    for J := 1 to 7 do
      Inc(Ones, (Result[I] shr J) and 1);
    Result[I] := (Result[I] and $FE) or Byte(1 - (Ones and 1));
  end;
end;

class function TEmvCalculator.HasOddParity(const AKey: TBytes): Boolean;
var
  Adjusted: TBytes;
begin
  Adjusted := AdjustOddParity(AKey);
  try
    Result := TCardCrypto.EqualSecret(AKey, Adjusted);
  finally
    TCardCrypto.Clear(Adjusted);
  end;
end;

class function TEmvCalculator.Pad(const AData: TBytes;
  const APadding: TEmvMacPadding): TBytes;
var
  N: Integer;
begin
  Result := nil;
  if Length(AData) > EmvCalculatorMaxData then
    Invalid;
  case APadding of
    empMethod1:
      begin
        N := ((Length(AData) + 7) div 8) * 8;
        if N = 0 then
          N := 8;
      end;
    empMethod2:
      N := ((Length(AData) div 8) + 1) * 8;
  else
    Invalid;
    Exit;
  end;
  SetLength(Result, N);
  if Length(AData) > 0 then
    Move(AData[0], Result[0], Length(AData));
  if APadding = empMethod2 then
    Result[Length(AData)] := $80;
end;

function TEmvCalculator.Ecb(const AKey, AData: TBytes;
  const AEncrypt: Boolean): TBytes;
var
  I: Integer;
  Block, Zero, Output: TBytes;
begin
  Result := nil;
  if (Length(AData) = 0) or (Length(AData) mod 8 <> 0) or
    (Length(AData) > 1048576) then
    Invalid;
  Block := nil;
  Zero := nil;
  Output := nil;
  try
    SetLength(Zero, 8);
    SetLength(Result, Length(AData));
    try
      for I := 0 to (Length(AData) div 8) - 1 do
      begin
        Block := Copy(AData, I * 8, 8);
        Output := TCardDesCrypto.Crypt(FDesProvider, AKey, Zero, Block, AEncrypt);
        Move(Output[0], Result[I * 8], 8);
        TCardCrypto.Clear(Block);
        TCardCrypto.Clear(Output);
      end;
    except
      TCardCrypto.Clear(Result);
      raise;
    end;
  finally
    TCardCrypto.Clear(Block);
    TCardCrypto.Clear(Output);
    TCardCrypto.Clear(Zero);
  end;
end;

function TEmvCalculator.KeyCheckValue(const AKey: TBytes;
  const ALength: Integer): TBytes;
var
  Zero, Cipher: TBytes;
begin
  Result := nil;
  if (ALength < 1) or (ALength > 8) then
    Invalid;
  Zero := nil;
  Cipher := nil;
  try
    SetLength(Zero, 8);
    Cipher := Ecb(AKey, Zero, True);
    Result := Copy(Cipher, 0, ALength);
  finally
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Cipher);
  end;
end;

function TEmvCalculator.AesKeyCheckValue(const AKey: TBytes;
  const ALength: Integer): TBytes;
var
  Zero, Cipher: TBytes;
begin
  Result := nil;
  RequireSize(AKey, 16);
  if (FAesProvider = nil) or (ALength < 1) or (ALength > 16) then
    Invalid;
  Zero := nil;
  Cipher := nil;
  try
    SetLength(Zero, 16);
    Cipher := FAesProvider.EncryptCbc(AKey, Zero, Zero);
    RequireSize(Cipher, 16);
    Result := Copy(Cipher, 0, ALength);
  finally
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Cipher);
  end;
end;

function TEmvCalculator.DeriveMasterKey(const AIssuerKey: TBytes;
  const APan, APsn: string; const AMethod: TEmvMasterKeyMethod): TBytes;
var
  Digits, DigestText: string;
  Data, Digest, Diversification, Cipher: TBytes;
  I: Integer;
begin
  Result := nil;
  RequireSize(AIssuerKey, 16);
  RequireDigits(APan, 1, 19);
  RequireDigits(APsn, 2, 2);
  if not (AMethod in [emkOptionA, emkOptionB]) then
    Invalid;
  Data := nil;
  Digest := nil;
  Diversification := nil;
  Cipher := nil;
  try
    Digits := APan + APsn;
    if (AMethod = emkOptionB) and (Length(APan) > 16) then
    begin
      if FHashProvider = nil then
        Invalid;
      if Length(Digits) mod 2 <> 0 then
        Digits := '0' + Digits;
      Data := HexToBytes(Digits);
      Digest := FHashProvider.Sha1(Data);
      RequireSize(Digest, 20);
      DigestText := BytesToHex(Digest);
      Digits := '';
      for I := 1 to Length(DigestText) do
        if CharInSet(DigestText[I], ['0' .. '9']) and (Length(Digits) < 16) then
          Digits := Digits + DigestText[I];
      for I := 1 to Length(DigestText) do
        if CharInSet(DigestText[I], ['A' .. 'F']) and (Length(Digits) < 16) then
          Digits := Digits + Char(Ord('0') + Ord(DigestText[I]) - Ord('A'));
    end
    else
    begin
      while Length(Digits) < 16 do
        Digits := '0' + Digits;
      Digits := Copy(Digits, Length(Digits) - 15, 16);
    end;
    TCardCrypto.Clear(Data);
    Data := HexToBytes(Digits);
    SetLength(Diversification, 16);
    for I := 0 to 7 do
    begin
      Diversification[I] := Data[I];
      Diversification[I + 8] := Data[I] xor $FF;
    end;
    Cipher := Ecb(AIssuerKey, Diversification, True);
    Result := AdjustOddParity(Cipher);
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Digest);
    TCardCrypto.Clear(Diversification);
    TCardCrypto.Clear(Cipher);
    Digits := '';
    DigestText := '';
  end;
end;

function TEmvCalculator.DeriveCommonSessionKey(const AMasterKey,
  ADiversification: TBytes): TBytes;
var
  Data, Cipher: TBytes;
begin
  Result := nil;
  RequireSize(AMasterKey, 16);
  RequireSize(ADiversification, 8);
  Data := nil;
  Cipher := nil;
  try
    Data := Join(ADiversification, ADiversification);
    Data[2] := $F0;
    Data[10] := $0F;
    Cipher := Ecb(AMasterKey, Data, True);
    Result := AdjustOddParity(Cipher);
  finally
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Cipher);
  end;
end;

function TEmvCalculator.DeriveAtcSessionKey(const AMasterKey,
  AAtc: TBytes): TBytes;
var
  Data: TBytes;
begin
  RequireSize(AAtc, 2);
  Data := nil;
  try
    SetLength(Data, 8);
    Move(AAtc[0], Data[0], 2);
    Result := DeriveCommonSessionKey(AMasterKey, Data);
  finally
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.DeriveMastercardSessionKey(const AMasterKey,
  AAtc, AUnpredictableNumber: TBytes): TBytes;
var
  Data: TBytes;
begin
  RequireSize(AAtc, 2);
  RequireSize(AUnpredictableNumber, 4);
  Data := nil;
  try
    SetLength(Data, 8);
    Move(AAtc[0], Data[0], 2);
    Move(AUnpredictableNumber[0], Data[4], 4);
    Result := DeriveCommonSessionKey(AMasterKey, Data);
  finally
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.DeriveVisaScriptKey(const AMasterKey,
  AAtc: TBytes): TBytes;
var
  I: Integer;
  Data: TBytes;
begin
  RequireSize(AMasterKey, 16);
  RequireSize(AAtc, 2);
  Data := Copy(AMasterKey, 0, 16);
  try
    for I := 0 to 1 do
    begin
      Data[6 + I] := Data[6 + I] xor AAtc[I];
      Data[14 + I] := Data[14 + I] xor AAtc[I] xor $FF;
    end;
    Result := AdjustOddParity(Data);
  finally
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.TreeStep(const AKey, AValue: TBytes;
  const AIndex: Cardinal): TBytes;
var
  Data: TBytes;
  I: Integer;
begin
  Data := Copy(AValue, 0, 16);
  try
    for I := 0 to 3 do
    begin
      Data[7 - I] := Data[7 - I] xor Byte((AIndex shr (I * 8)) and $FF);
      Data[15 - I] := Data[15 - I] xor Byte((AIndex shr (I * 8)) and $FF);
    end;
    Data[15] := Data[15] xor $F0;
    Result := Ecb(AKey, Data, True);
  finally
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.DeriveTreeSessionKey(const AMasterKey, AAtc,
  AIv: TBytes; const AHeight, ABranchFactor: Integer): TBytes;
var
  Parent, Grandparent, Next: TBytes;
  Capacity, Index, Atc: Cardinal;
  I, J: Integer;
begin
  Result := nil;
  RequireSize(AMasterKey, 16);
  RequireSize(AAtc, 2);
  RequireSize(AIv, 16);
  if (AHeight < 2) or (AHeight > 16) or
    (ABranchFactor < 2) or (ABranchFactor > 256) then
    Invalid;
  Capacity := 1;
  for I := 1 to AHeight do
    if Capacity < 65536 then
      Capacity := Capacity * Cardinal(ABranchFactor);
  if Capacity < 65536 then
    Invalid;
  Atc := Cardinal(AAtc[0]) * 256 + AAtc[1];
  Parent := Copy(AMasterKey, 0, 16);
  Grandparent := Copy(AIv, 0, 16);
  Next := nil;
  try
    for I := AHeight - 1 downto 1 do
    begin
      Index := Atc;
      for J := 1 to I do
        Index := Index div Cardinal(ABranchFactor);
      Next := TreeStep(Parent, Grandparent, Index mod Cardinal(ABranchFactor));
      TCardCrypto.Clear(Grandparent);
      Grandparent := Parent;
      Parent := Next;
      Next := nil;
    end;
    Next := TreeStep(Parent, Grandparent, Atc mod Cardinal(ABranchFactor));
    for I := 0 to 15 do
      Next[I] := Next[I] xor Grandparent[I];
    Result := AdjustOddParity(Next);
  finally
    TCardCrypto.Clear(Parent);
    TCardCrypto.Clear(Grandparent);
    TCardCrypto.Clear(Next);
  end;
end;

function TEmvCalculator.RetailMac(const AKey, AData: TBytes;
  const APadding: TEmvMacPadding; const ALength: Integer): TBytes;
var
  Padded, Zero, Key1, Key2, Cipher, Last, Decipher, Mac: TBytes;
begin
  Result := nil;
  RequireSize(AKey, 16);
  if (ALength < 1) or (ALength > 8) then
    Invalid;
  Padded := nil;
  Zero := nil;
  Key1 := nil;
  Key2 := nil;
  Cipher := nil;
  Last := nil;
  Decipher := nil;
  Mac := nil;
  try
    Padded := Pad(AData, APadding);
    SetLength(Zero, 8);
    Key1 := Copy(AKey, 0, 8);
    Key2 := Copy(AKey, 8, 8);
    Cipher := TCardDesCrypto.Crypt(FDesProvider, Key1, Zero, Padded, True);
    Last := Copy(Cipher, Length(Cipher) - 8, 8);
    Decipher := Ecb(Key2, Last, False);
    Mac := Ecb(Key1, Decipher, True);
    Result := Copy(Mac, 0, ALength);
  finally
    TCardCrypto.Clear(Padded);
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Key1);
    TCardCrypto.Clear(Key2);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(Last);
    TCardCrypto.Clear(Decipher);
    TCardCrypto.Clear(Mac);
  end;
end;

function TEmvCalculator.ApplicationCryptogram(const ASessionKey,
  AData: TBytes; const APadding: TEmvMacPadding): TBytes;
begin
  Result := RetailMac(ASessionKey, AData, APadding, 8);
end;

function TEmvCalculator.VerifyApplicationCryptogram(const ASessionKey,
  AData, AExpected: TBytes; const APadding: TEmvMacPadding): Boolean;
var
  Actual: TBytes;
begin
  RequireSize(AExpected, 8);
  Actual := ApplicationCryptogram(ASessionKey, AData, APadding);
  try
    Result := TCardCrypto.EqualSecret(Actual, AExpected);
  finally
    TCardCrypto.Clear(Actual);
  end;
end;

function TEmvCalculator.ArpcMethod1(const ASessionKey, AArqc,
  AResponseCode: TBytes): TBytes;
var
  Data: TBytes;
begin
  RequireSize(ASessionKey, 16);
  RequireSize(AArqc, 8);
  RequireSize(AResponseCode, 2);
  Data := Copy(AArqc, 0, 8);
  try
    Data[0] := Data[0] xor AResponseCode[0];
    Data[1] := Data[1] xor AResponseCode[1];
    Result := Ecb(ASessionKey, Data, True);
  finally
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.ArpcMethod2(const ASessionKey, AArqc, ACsu,
  AAuthenticationData: TBytes): TBytes;
var
  Prefix, Data: TBytes;
begin
  RequireSize(ASessionKey, 16);
  RequireSize(AArqc, 8);
  RequireSize(ACsu, 4);
  if Length(AAuthenticationData) > 8 then
    Invalid;
  Prefix := nil;
  Data := nil;
  try
    Prefix := Join(AArqc, ACsu);
    Data := Join(Prefix, AAuthenticationData);
    Result := RetailMac(ASessionKey, Data, empMethod2, 4);
  finally
    TCardCrypto.Clear(Prefix);
    TCardCrypto.Clear(Data);
  end;
end;

function TEmvCalculator.VerifyArpcMethod1(const ASessionKey, AArqc,
  AResponseCode, AExpected: TBytes): Boolean;
var
  Actual: TBytes;
begin
  RequireSize(AExpected, 8);
  Actual := ArpcMethod1(ASessionKey, AArqc, AResponseCode);
  try
    Result := TCardCrypto.EqualSecret(Actual, AExpected);
  finally
    TCardCrypto.Clear(Actual);
  end;
end;

function TEmvCalculator.VerifyArpcMethod2(const ASessionKey, AArqc, ACsu,
  AAuthenticationData, AExpected: TBytes): Boolean;
var
  Actual: TBytes;
begin
  RequireSize(AExpected, 4);
  Actual := ArpcMethod2(ASessionKey, AArqc, ACsu, AAuthenticationData);
  try
    Result := TCardCrypto.EqualSecret(Actual, AExpected);
  finally
    TCardCrypto.Clear(Actual);
  end;
end;

function TEmvCalculator.AesCmac(const AKey, AData: TBytes;
  const ALength: Integer): TBytes;
var
  Mac: TBytes;
begin
  if (ALength < 1) or (ALength > 16) then
    Invalid;
  Mac := TCardCrypto.Cmac(FAesProvider, AKey, AData);
  try
    Result := Copy(Mac, 0, ALength);
  finally
    TCardCrypto.Clear(Mac);
  end;
end;

function TEmvCalculator.ScriptMac(const ASessionKey,
  AAuthenticatedData: TBytes; const ALength: Integer): TBytes;
begin
  if (ALength < 4) or (ALength > 8) then
    Invalid;
  Result := RetailMac(ASessionKey, AAuthenticatedData, empMethod2, ALength);
end;

function TEmvCalculator.EncryptScriptData(const ASessionKey, AData: TBytes;
  const AFormat: TEmvScriptEncryption): TBytes;
var
  Body, Padded, Zero: TBytes;
begin
  Result := nil;
  RequireSize(ASessionKey, 16);
  if Length(AData) > EmvCalculatorMaxData then
    Invalid;
  Body := nil;
  Padded := nil;
  Zero := nil;
  try
    SetLength(Zero, 8);
    case AFormat of
      eseVisa:
        begin
          if Length(AData) > 255 then
            Invalid;
          SetLength(Body, Length(AData) + 1);
          Body[0] := Length(AData);
          if Length(AData) > 0 then
            Move(AData[0], Body[1], Length(AData));
          Padded := Pad(Body, empMethod2);
          Result := Ecb(ASessionKey, Padded, True);
        end;
      eseMastercard, eseEmv:
        begin
          if (AFormat = eseEmv) or (Length(AData) mod 8 <> 0) then
            Padded := Pad(AData, empMethod2)
          else
            Padded := Copy(AData, 0, Length(AData));
          if Length(Padded) = 0 then
            Exit;
          Result := TCardDesCrypto.Crypt(FDesProvider, ASessionKey, Zero, Padded, True);
        end;
    else
      Invalid;
    end;
  finally
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Padded);
    TCardCrypto.Clear(Zero);
  end;
end;

class function TEmvCalculator.FormatPinBlock2(const APin: string): TBytes;
begin
  RequireDigits(APin, 4, 12);
  Result := HexToBytes('2' + IntToHex(Length(APin), 1) + APin +
    StringOfChar('F', 14 - Length(APin)));
end;

class function TEmvCalculator.FormatVisaPinBlock(const AMasterKey: TBytes;
  const ANewPin, ACurrentPin: string): TBytes;
var
  Old: TBytes;
  I: Integer;
begin
  Result := nil;
  RequireSize(AMasterKey, 16);
  RequireDigits(ANewPin, 4, 12);
  if ACurrentPin <> '' then
    RequireDigits(ACurrentPin, 4, 12);
  Result := HexToBytes(IntToHex(Length(ANewPin), 2) + ANewPin +
    StringOfChar('F', 14 - Length(ANewPin)));
  for I := 0 to 3 do
    Result[4 + I] := Result[4 + I] xor AMasterKey[4 + I];
  if ACurrentPin <> '' then
  begin
    Old := HexToBytes(ACurrentPin + StringOfChar('0', 16 - Length(ACurrentPin)));
    try
      for I := 0 to 7 do
        Result[I] := Result[I] xor Old[I];
    finally
      TCardCrypto.Clear(Old);
    end;
  end;
end;

end.
