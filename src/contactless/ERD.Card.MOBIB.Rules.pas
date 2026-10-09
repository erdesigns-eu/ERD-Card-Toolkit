unit ERD.Card.MOBIB.Rules;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.MOBIB.Subscriptions;
type
 /// <summary>Rule configuration or inconsistent caller evidence; contains no card bytes.</summary>
 EMobibRuleError = class(Exception);
 /// <summary>Clock domain supplied by the application; the engine does not guess time zones.</summary>
 TMobibClockBasis = (
  /// <summary>UTC instants, required for elapsed minute/hour durations across DST changes.</summary>
  mcbUtc,
  /// <summary>Operator-local civil times, required for calendar day/month/year durations.</summary>
  mcbOperatorLocal
 );
 /// <summary>Independent activation evidence supplied by a documented operator decoder or application.</summary>
 TMobibActivationState = (
  /// <summary>No reliable activation state was acquired.</summary>
  masUnknown,
  /// <summary>Reliable evidence explicitly identifies an unactivated contract.</summary>
  masInactive,
  /// <summary>Reliable evidence identifies an activated contract; timestamp may still be missing.</summary>
  masActive
 );
 /// <summary>Explicit product-specific source of the validity start; never selected from the product label.</summary>
 TMobibActivationSource = (
  /// <summary>Use the application-provided contract validity start.</summary>
  mavExplicitStart,
  /// <summary>Use the acquired activation timestamp and activation state.</summary>
  mavActivation,
  /// <summary>Use the first-validation timestamp; never the latest generic card event.</summary>
  mavFirstValidation,
  /// <summary>Use the decoded sale date only when this explicit operator policy defines sale-based validity.</summary>
  mavSaleDate
 );
 /// <summary>Validity duration interpretation chosen by a sourced product policy.</summary>
 TMobibDurationUnit = (
  /// <summary>Unmapped card duration code; never interpreted as a time interval.</summary>
  mduUnknown,
  /// <summary>Use the application-provided exclusive contract end.</summary>
  mduExplicitEnd,
  /// <summary>Elapsed UTC minutes.</summary>
  mduMinutes,
  /// <summary>Elapsed UTC hours.</summary>
  mduHours,
  /// <summary>Operator-local calendar days.</summary>
  mduCalendarDays,
  /// <summary>Calendar months, preserving civil time and clamping to the last valid target-month day.</summary>
  mduCalendarMonths,
  /// <summary>Calendar years with February 29 clamped to February 28 where necessary.</summary>
  mduCalendarYears,
  /// <summary>Use the contract duration with the policy's explicit four-code unit mapping.</summary>
  mduContractField
 );
 /// <summary>Explicit mappings for the four raw duration-unit codes; unknown entries remain unknown.</summary>
 TMobibDurationMap = array[0..3] of TMobibDurationUnit;
 /// <summary>Owned operator zone identifiers; semantics come from the selected policy, not numeric proximity.</summary>
 TMobibZones = array of Word;
 /// <summary>How the policy obtains the zones permitted for a new journey.</summary>
 TMobibZoneMode = (
  /// <summary>The sourced policy explicitly has no zone restriction.</summary>
  mzmUnrestricted,
  /// <summary>Use the fixed allowed-zone set from the policy.</summary>
  mzmPolicySet,
  /// <summary>Use zones acquired through a documented operator-specific contract decoder.</summary>
  mzmContractSet
 );
 /// <summary>Explicit, sourced product policy; no issuer policy is inferred or installed implicitly.</summary>
 TMobibProductRule = record
  /// <summary>Nonempty stable operator identifier supplied by the application.</summary>
  OperatorId: string;
  /// <summary>Nonempty rule source/version reference for auditing, such as an issuer specification revision.</summary>
  Source: string;
  /// <summary>Network country code, 0..999, explicitly matched against caller evidence.</summary>
  CountryCode: Word;
  /// <summary>Network code, 0..999; does not itself identify the transport operator.</summary>
  NetworkCode: Word;
  /// <summary>Exact fourteen-bit contract tariff matched by this product policy.</summary>
  Tariff: Word;
  /// <summary>First supported contract layout version, 0..4.</summary>
  MinVersion: Byte;
  /// <summary>Last supported contract layout version, MinVersion..4.</summary>
  MaxVersion: Byte;
  /// <summary>Required clock domain; every supplied timestamp uses this same domain.</summary>
  ClockBasis: TMobibClockBasis;
  /// <summary>Explicit start-anchor interpretation.</summary>
  ActivationSource: TMobibActivationSource;
  /// <summary>Explicit end, fixed duration or documented contract-field mapping.</summary>
  DurationUnit: TMobibDurationUnit;
  /// <summary>Fixed positive duration amount; zero for explicit-end or contract-field mode.</summary>
  DurationAmount: Cardinal;
  /// <summary>Raw contract-unit mappings; only real duration units or mduUnknown are permitted.</summary>
  ContractUnits: TMobibDurationMap;
  /// <summary>For calendar durations only, calculate the end from the anchor's civil midnight; actual start remains the anchor.</summary>
  EndFromMidnight: Boolean;
  /// <summary>Explicit unrestricted, fixed or decoded-contract zone interpretation.</summary>
  ZoneMode: TMobibZoneMode;
  /// <summary>Allowed-zone set when ZoneMode=mzmPolicySet; no wildcard or range inference.</summary>
  Zones: TMobibZones;
  /// <summary>True only when starting a new journey requires at least one decoded remaining trip.</summary>
  RequireRemainingTrip: Boolean;
 end;
 /// <summary>Acquired/application evidence for one product and requested new journey; not an authenticity certificate.</summary>
 TMobibRuleEvidence = record
  /// <summary>Explicit operator identity; must equal the selected policy identifier.</summary>
  OperatorId: string;
  /// <summary>Acquired or explicitly supplied network country code.</summary>
  CountryCode: Word;
  /// <summary>Acquired or explicitly supplied network code.</summary>
  NetworkCode: Word;
  /// <summary>Clock domain of Now and every present timestamp.</summary>
  ClockBasis: TMobibClockBasis;
  /// <summary>Explicit evaluation time; the engine never reads the system clock.</summary>
  Now: TDateTime;
  /// <summary>Known activation state, independently distinguished from missing evidence.</summary>
  ActivationState: TMobibActivationState;
  /// <summary>True when an explicit contract start was acquired.</summary>
  HasStart: Boolean;
  /// <summary>Inclusive start, meaningful only when HasStart is true.</summary>
  Start: TDateTime;
  /// <summary>True when an explicit exclusive contract end was acquired.</summary>
  HasEnd: Boolean;
  /// <summary>Exclusive end, meaningful only when HasEnd is true.</summary>
  EndTime: TDateTime;
  /// <summary>True when the contract-specific activation timestamp was acquired.</summary>
  HasActivationTime: Boolean;
  /// <summary>Activation timestamp; never substituted from the sale date implicitly.</summary>
  ActivationTime: TDateTime;
  /// <summary>True when this contract's first-validation timestamp was acquired.</summary>
  HasFirstValidation: Boolean;
  /// <summary>Contract-specific first use; never substituted from the card's unrelated event log.</summary>
  FirstValidation: TDateTime;
  /// <summary>True when the decoded contract zone set is known, including an explicitly empty set.</summary>
  HasContractZones: Boolean;
  /// <summary>Allowed contract-zone identifiers when HasContractZones is true.</summary>
  ContractZones: TMobibZones;
  /// <summary>True when a nonempty complete requested journey-zone set is supplied.</summary>
  HasJourneyZones: Boolean;
  /// <summary>Every zone needed for this new journey; all must belong to the allowed set.</summary>
  JourneyZones: TMobibZones;
 end;
 /// <summary>Independent check result; lack of data is distinct from a proved failure.</summary>
 TMobibRuleCheck = (
  /// <summary>The explicit policy does not require this condition.</summary>
  mrcNotRequired,
  /// <summary>Required evidence or semantics are missing.</summary>
  mrcUnknown,
  /// <summary>The selected policy condition is satisfied by supplied evidence.</summary>
  mrcPass,
  /// <summary>The selected policy condition is contradicted by supplied evidence.</summary>
  mrcFail
 );
 /// <summary>Overall read-only assessment of the policy conditions for starting a new journey.</summary>
 TMobibRuleVerdict = (
  /// <summary>No condition proves failure, but at least one required condition remains unknown.</summary>
  mrvUnknown,
  /// <summary>Every required policy condition passes; this is not an issuer authorization or authenticity proof.</summary>
  mrvEligible,
  /// <summary>At least one matched policy condition fails, even if other evidence is missing.</summary>
  mrvIneligible
 );
 /// <summary>Machine-readable assessment reasons, without copying personal/card data into error text.</summary>
 TMobibRuleReason = (
  /// <summary>Unsupported layout or mismatched operator, country, network, tariff or contract version.</summary>
  mrrProfileMismatch,
  /// <summary>Caller timestamps use a different clock domain than the product policy.</summary>
  mrrClockMismatch,
  /// <summary>Activation is unknown or its required anchor is missing.</summary>
  mrrMissingActivation,
  /// <summary>Reliable evidence explicitly marks the contract as unactivated.</summary>
  mrrNotActivated,
  /// <summary>Explicit validity start is missing.</summary>
  mrrMissingStart,
  /// <summary>Required first-validation timestamp is missing.</summary>
  mrrMissingFirstValidation,
  /// <summary>Required sale date is missing.</summary>
  mrrMissingSaleDate,
  /// <summary>Explicit exclusive validity end is missing.</summary>
  mrrMissingEnd,
  /// <summary>Contract duration is absent, zero or its unit code is not mapped.</summary>
  mrrMissingDuration,
  /// <summary>Calculated or provided end precedes/equal start or lies outside supported date bounds.</summary>
  mrrInvalidWindow,
  /// <summary>Evaluation precedes the inclusive validity start.</summary>
  mrrBeforeStart,
  /// <summary>Evaluation reaches or passes the exclusive validity end.</summary>
  mrrExpired,
  /// <summary>Required decoded contract-zone set is missing.</summary>
  mrrMissingContractZones,
  /// <summary>Required nonempty requested journey-zone set is missing.</summary>
  mrrMissingJourneyZones,
  /// <summary>At least one requested zone is outside the acquired/fixed permitted set.</summary>
  mrrOutsideZones,
  /// <summary>Required remaining-trip evidence is missing.</summary>
  mrrMissingTrips,
  /// <summary>Required remaining-trip value is zero.</summary>
  mrrNoTrips
 );
 /// <summary>Set of independent explanations; a known failure can coexist with missing evidence.</summary>
 TMobibRuleReasons = set of TMobibRuleReason;
 /// <summary>Deterministic, read-only policy assessment with explicit boundaries and partial results.</summary>
 TMobibRuleAssessment = record
  /// <summary>Overall outcome after independently assessing required conditions.</summary>
  Verdict: TMobibRuleVerdict;
  /// <summary>Exact profile-match result; unmatched policies are not applied.</summary>
  Profile: TMobibRuleCheck;
  /// <summary>Start-anchor/activation evidence result.</summary>
  Activation: TMobibRuleCheck;
  /// <summary>Clock, date-window and evaluation-time result.</summary>
  Validity: TMobibRuleCheck;
  /// <summary>Journey-zone subset result.</summary>
  Zones: TMobibRuleCheck;
  /// <summary>Remaining-trip condition for a new journey.</summary>
  Trips: TMobibRuleCheck;
  /// <summary>Independent machine-readable reasons.</summary>
  Reasons: TMobibRuleReasons;
  /// <summary>True when an inclusive validity start was resolved.</summary>
  HasStart: Boolean;
  /// <summary>Resolved inclusive start in the policy clock domain.</summary>
  Start: TDateTime;
  /// <summary>True when an exclusive validity end was resolved.</summary>
  HasEnd: Boolean;
  /// <summary>Resolved exclusive end in the policy clock domain.</summary>
  EndTime: TDateTime;
 end;
 /// <summary>Native offline activation, validity, calendar-duration, zone and trip-rule evaluation.</summary>
 TMobibRuleEngine = class
 public
  /// <summary>Validates a sourced explicit policy without accessing hardware or the system clock.</summary>
  /// <param name="ARule">Policy with exact profile identity, version range and duration/zone semantics.</param>
  /// <exception cref="EMobibRuleError">Policy bounds, clock semantics or zone configuration are invalid.</exception>
  class procedure Validate(const ARule: TMobibProductRule); static;
  /// <summary>Assesses a new journey against an explicitly selected product policy and acquired evidence.</summary>
  /// <param name="ARule">Validated sourced policy; no built-in issuer mappings are assumed.</param>
  /// <param name="ASubscription">Decoded versioned contract; unknown layouts never become eligible.</param>
  /// <param name="AEvidence">Explicit time, identity, activation and journey-zone evidence.</param>
  /// <returns>Independent checks and unknown/eligible/ineligible outcome; no issuer authorization is issued.</returns>
  /// <remarks>Start is inclusive and end exclusive. Calendar-month ends clamp to the target month's last day.
  /// Missing information stays unknown. Known matched failures dominate unknown checks. No card is written,
  /// transfer entitlement inferred, system clock read or timezone conversion guessed.</remarks>
  class function Evaluate(const ARule: TMobibProductRule; const ASubscription: TMobibSubscription;
   const AEvidence: TMobibRuleEvidence): TMobibRuleAssessment; static;
 end;
implementation
uses
{$IFDEF FPC}Math;{$ELSE}System.Math;{$ENDIF}
procedure RuleError;
begin raise EMobibRuleError.Create('Invalid MOBIB rule configuration or evidence.'); end;
procedure CheckZones(const A: TMobibZones);
var I,J: Integer;
begin
 if Length(A)>64 then RuleError;
 for I:=0 to High(A) do for J:=0 to I-1 do if A[I]=A[J] then RuleError;
end;
procedure CheckTime(const A: TDateTime);
begin
 if IsNan(A) or IsInfinite(A) then RuleError;
 if (A<EncodeDate(1900,1,1)) or (A>=EncodeDate(9999,12,31)+1) then RuleError;
end;
class procedure TMobibRuleEngine.Validate(const ARule: TMobibProductRule);
var I: Integer; U: TMobibDurationUnit;
begin
 if (Length(Trim(ARule.OperatorId))=0) or (Length(ARule.OperatorId)>128) or
  (Length(Trim(ARule.Source))=0) or (Length(ARule.Source)>1024) or
  (ARule.CountryCode>999) or (ARule.NetworkCode>999) or (ARule.Tariff>$3FFF) or
  (ARule.MinVersion>ARule.MaxVersion) or (ARule.MaxVersion>4) or
  (Ord(ARule.ClockBasis)>Ord(High(TMobibClockBasis))) or
  (Ord(ARule.ActivationSource)>Ord(High(TMobibActivationSource))) or
  (Ord(ARule.ZoneMode)>Ord(High(TMobibZoneMode))) then RuleError;
 U:=ARule.DurationUnit;
 if (Ord(U)>Ord(High(TMobibDurationUnit))) or (U=mduUnknown) then RuleError;
 if U in [mduExplicitEnd,mduContractField] then begin if ARule.DurationAmount<>0 then RuleError; end
 else if (ARule.DurationAmount=0) or (ARule.DurationAmount>1000000) then RuleError;
 if (U in [mduMinutes,mduHours]) and (ARule.ClockBasis<>mcbUtc) then RuleError;
 if (U in [mduCalendarDays,mduCalendarMonths,mduCalendarYears]) and (ARule.ClockBasis<>mcbOperatorLocal) then RuleError;
 if ARule.EndFromMidnight and (ARule.ClockBasis<>mcbOperatorLocal) then RuleError;
 if ARule.EndFromMidnight and not (U in [mduCalendarDays,mduCalendarMonths,mduCalendarYears,mduContractField]) then RuleError;
 if (ARule.ActivationSource=mavSaleDate) and (ARule.ClockBasis<>mcbOperatorLocal) then RuleError;
 for I:=0 to 3 do begin
  U:=ARule.ContractUnits[I];
  if not (U in [mduUnknown,mduMinutes,mduHours,mduCalendarDays,mduCalendarMonths,mduCalendarYears]) then RuleError;
  if ARule.DurationUnit=mduContractField then begin
   if (U in [mduMinutes,mduHours]) and ((ARule.ClockBasis<>mcbUtc) or ARule.EndFromMidnight) then RuleError;
   if (U in [mduCalendarDays,mduCalendarMonths,mduCalendarYears]) and (ARule.ClockBasis<>mcbOperatorLocal) then RuleError;
  end;
 end;
 CheckZones(ARule.Zones);
 if (ARule.ZoneMode=mzmPolicySet) and (Length(ARule.Zones)=0) then RuleError;
 if (ARule.ZoneMode<>mzmPolicySet) and (Length(ARule.Zones)<>0) then RuleError;
end;
function CalendarEnd(const Start: TDateTime; const U: TMobibDurationUnit;
 const Amount: Cardinal; out EndTime: TDateTime): Boolean;
var Y,M,D: Word; MonthIndex,NewYear,NewMonth,Day: Int64; Date: TDateTime;
begin
 Result:=False; EndTime:=0;
 if U=mduCalendarDays then begin EndTime:=Start+Amount; Result:=EndTime<EncodeDate(9999,12,31)+1; Exit; end;
 DecodeDate(Start,Y,M,D); MonthIndex:=Int64(Y)*12+M-1;
 if U=mduCalendarYears then Inc(MonthIndex,Int64(Amount)*12) else Inc(MonthIndex,Amount);
 NewYear:=MonthIndex div 12; NewMonth:=MonthIndex mod 12+1;
 if NewYear>9999 then Exit;
 Day:=D;
 while not TryEncodeDate(Word(NewYear),Word(NewMonth),Word(Day),Date) do begin Dec(Day); if Day<1 then Exit; end;
 EndTime:=Date+Frac(Start); Result:=True;
end;
class function TMobibRuleEngine.Evaluate(const ARule: TMobibProductRule;
 const ASubscription: TMobibSubscription; const AEvidence: TMobibRuleEvidence): TMobibRuleAssessment;
var U: TMobibDurationUnit; Amount: Cardinal; Anchor: TDateTime; Allowed: TMobibZones;
 I,J: Integer; Found,Resolved,WindowReady: Boolean;
begin
 Allowed:=nil; Validate(ARule); CheckTime(AEvidence.Now);
 if (Length(AEvidence.OperatorId)>128) or (AEvidence.CountryCode>999) or (AEvidence.NetworkCode>999) or
  (Ord(AEvidence.ClockBasis)>Ord(High(TMobibClockBasis))) or
  (Ord(AEvidence.ActivationState)>Ord(High(TMobibActivationState))) then RuleError;
 if AEvidence.HasStart then CheckTime(AEvidence.Start);
 if AEvidence.HasEnd then CheckTime(AEvidence.EndTime);
 if AEvidence.HasActivationTime then CheckTime(AEvidence.ActivationTime);
 if AEvidence.HasFirstValidation then CheckTime(AEvidence.FirstValidation);
 if (AEvidence.ActivationState=masInactive) and (AEvidence.HasActivationTime or AEvidence.HasFirstValidation) then RuleError;
 CheckZones(AEvidence.ContractZones); CheckZones(AEvidence.JourneyZones);
 Result:=Default(TMobibRuleAssessment); Result.Profile:=mrcUnknown;
 Result.Activation:=mrcUnknown; Result.Validity:=mrcUnknown;
 Result.Zones:=mrcNotRequired; Result.Trips:=mrcNotRequired;
 if not ASubscription.LayoutMatched or (ASubscription.Version<ARule.MinVersion) or (ASubscription.Version>ARule.MaxVersion) or
  (ASubscription.Tariff<>ARule.Tariff) or (AEvidence.OperatorId<>ARule.OperatorId) or
  (AEvidence.CountryCode<>ARule.CountryCode) or (AEvidence.NetworkCode<>ARule.NetworkCode) then begin
  Include(Result.Reasons,mrrProfileMismatch); Exit;
 end;
 Result.Profile:=mrcPass;
 if AEvidence.ClockBasis<>ARule.ClockBasis then Include(Result.Reasons,mrrClockMismatch)
 else begin
  if ARule.DurationUnit=mduExplicitEnd then begin
   Result.HasEnd:=AEvidence.HasEnd; Result.EndTime:=AEvidence.EndTime;
   if not Result.HasEnd then Include(Result.Reasons,mrrMissingEnd);
  end;
  case ARule.ActivationSource of
   mavExplicitStart: begin Result.HasStart:=AEvidence.HasStart; Result.Start:=AEvidence.Start;
    if not Result.HasStart then Include(Result.Reasons,mrrMissingStart); end;
   mavActivation: begin
    if AEvidence.ActivationState=masInactive then begin Result.Activation:=mrcFail; Include(Result.Reasons,mrrNotActivated); end
    else if AEvidence.ActivationState=masActive then begin Result.Activation:=mrcPass;
     Result.HasStart:=AEvidence.HasActivationTime; Result.Start:=AEvidence.ActivationTime;
     if not Result.HasStart then Include(Result.Reasons,mrrMissingActivation);
    end else Include(Result.Reasons,mrrMissingActivation);
   end;
   mavFirstValidation: begin
    if AEvidence.ActivationState=masInactive then begin Result.Activation:=mrcFail; Include(Result.Reasons,mrrNotActivated); end
    else begin Result.HasStart:=AEvidence.HasFirstValidation; Result.Start:=AEvidence.FirstValidation;
     if not Result.HasStart then Include(Result.Reasons,mrrMissingFirstValidation); end;
   end;
   mavSaleDate: begin Result.HasStart:=ASubscription.HasSaleDate; Result.Start:=ASubscription.SaleDate;
    if Result.HasStart then CheckTime(Result.Start) else Include(Result.Reasons,mrrMissingSaleDate); end;
  end;
  if Result.HasStart then begin
   Result.Activation:=mrcPass; U:=ARule.DurationUnit; Amount:=ARule.DurationAmount; Resolved:=True;
   if U=mduContractField then begin
    if not ASubscription.HasDuration or (ASubscription.DurationValue=0) or (ASubscription.DurationUnitCode>3) then Resolved:=False
    else begin U:=ARule.ContractUnits[ASubscription.DurationUnitCode]; Amount:=ASubscription.DurationValue; Resolved:=U<>mduUnknown; end;
    if not Resolved then Include(Result.Reasons,mrrMissingDuration);
   end;
   if Resolved then begin
    Anchor:=Result.Start; if ARule.EndFromMidnight then Anchor:=Trunc(Anchor);
    WindowReady:=True;
    case U of
     mduExplicitEnd: begin Result.HasEnd:=AEvidence.HasEnd; Result.EndTime:=AEvidence.EndTime;
      if not Result.HasEnd then begin WindowReady:=False; Include(Result.Reasons,mrrMissingEnd); end; end;
     mduMinutes: begin Result.HasEnd:=True; Result.EndTime:=Anchor+Amount/1440; end;
     mduHours: begin Result.HasEnd:=True; Result.EndTime:=Anchor+Amount/24; end;
     mduCalendarDays,mduCalendarMonths,mduCalendarYears: begin
      Result.HasEnd:=CalendarEnd(Anchor,U,Amount,Result.EndTime); WindowReady:=Result.HasEnd;
      if not WindowReady then Include(Result.Reasons,mrrInvalidWindow);
     end;
     else WindowReady:=False;
    end;
    if Result.HasEnd and ((Result.EndTime<=Result.Start) or (Result.EndTime>=EncodeDate(9999,12,31)+1)) then begin
     WindowReady:=False; Include(Result.Reasons,mrrInvalidWindow);
    end;
    if WindowReady then begin
     Result.Validity:=mrcPass;
     if AEvidence.Now<Result.Start then begin Result.Validity:=mrcFail; Include(Result.Reasons,mrrBeforeStart); end
     else if AEvidence.Now>=Result.EndTime then begin Result.Validity:=mrcFail; Include(Result.Reasons,mrrExpired); end;
    end;
   end;
  end;
  { A known boundary can prove failure even while the other boundary is missing. }
  if not (mrrInvalidWindow in Result.Reasons) then begin
   if Result.HasStart and (AEvidence.Now<Result.Start) then begin Result.Validity:=mrcFail; Include(Result.Reasons,mrrBeforeStart); end
   else if Result.HasEnd and (AEvidence.Now>=Result.EndTime) then begin Result.Validity:=mrcFail; Include(Result.Reasons,mrrExpired); end;
  end;
 end;
 if ARule.ZoneMode<>mzmUnrestricted then begin
  Result.Zones:=mrcUnknown;
  if ARule.ZoneMode=mzmPolicySet then Allowed:=ARule.Zones
  else if AEvidence.HasContractZones then Allowed:=AEvidence.ContractZones
  else Include(Result.Reasons,mrrMissingContractZones);
  if not AEvidence.HasJourneyZones or (Length(AEvidence.JourneyZones)=0) then Include(Result.Reasons,mrrMissingJourneyZones)
  else if (ARule.ZoneMode=mzmPolicySet) or AEvidence.HasContractZones then begin
   Result.Zones:=mrcPass;
   for I:=0 to High(AEvidence.JourneyZones) do begin
    Found:=False; for J:=0 to High(Allowed) do if AEvidence.JourneyZones[I]=Allowed[J] then Found:=True;
    if not Found then begin Result.Zones:=mrcFail; Include(Result.Reasons,mrrOutsideZones); end;
   end;
  end;
 end;
 if ARule.RequireRemainingTrip then begin
  Result.Trips:=mrcUnknown;
  if not ASubscription.HasRemainingTrips then Include(Result.Reasons,mrrMissingTrips)
  else if ASubscription.RemainingTrips=0 then begin Result.Trips:=mrcFail; Include(Result.Reasons,mrrNoTrips); end
  else Result.Trips:=mrcPass;
 end;
 if (Result.Activation=mrcFail) or (Result.Validity=mrcFail) or (Result.Zones=mrcFail) or (Result.Trips=mrcFail) then Result.Verdict:=mrvIneligible
 else if (Result.Activation=mrcUnknown) or (Result.Validity=mrcUnknown) or (Result.Zones=mrcUnknown) or (Result.Trips=mrcUnknown) then Result.Verdict:=mrvUnknown
 else Result.Verdict:=mrvEligible;
end;
end.
