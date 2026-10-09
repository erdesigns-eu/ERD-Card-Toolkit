program MobibRuleTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,Math,{$ELSE}System.SysUtils,System.Math,{$ENDIF}
 ERD.Card.MOBIB.Rules, ERD.Card.MOBIB.Subscriptions;
var Checks:Integer;
procedure Check(const V:Boolean;const Why:string);
begin Inc(Checks);if not V then raise Exception.Create(Why);end;
procedure Base(out R:TMobibProductRule;out S:TMobibSubscription;out E:TMobibRuleEvidence);
begin
 R:=Default(TMobibProductRule);R.OperatorId:='test-operator';R.Source:='Synthetic documented fixture v1';
 R.CountryCode:=56;R.NetworkCode:=1;R.Tariff:=$2803;R.MaxVersion:=4;R.ClockBasis:=mcbUtc;
 R.ActivationSource:=mavExplicitStart;R.DurationUnit:=mduHours;R.DurationAmount:=24;
 S:=Default(TMobibSubscription);S.LayoutMatched:=True;S.Version:=3;S.Tariff:=$2803;
 E:=Default(TMobibRuleEvidence);E.OperatorId:=R.OperatorId;E.CountryCode:=56;E.NetworkCode:=1;E.ClockBasis:=mcbUtc;
 E.Now:=EncodeDate(2026,3,29)+EncodeTime(10,0,0,0);E.HasStart:=True;E.Start:=E.Now;
end;
procedure Temporal;
var R:TMobibProductRule;S:TMobibSubscription;E:TMobibRuleEvidence;A:TMobibRuleAssessment;I,Y,D:Integer;
begin
 Base(R,S,E);A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Inclusive start');Check(A.EndTime=E.Start+1,'UTC elapsed day across operator DST');
 E.Now:=A.EndTime;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Exclusive end');Check(mrrExpired in A.Reasons,'Expiry reason');
 E.Now:=E.Start-1/86400;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Before start');Check(mrrBeforeStart in A.Reasons,'Start reason');
 E.HasStart:=False;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing start not failure');Check(mrrMissingStart in A.Reasons,'Missing start reason');
 Base(R,S,E);E.ClockBasis:=mcbOperatorLocal;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Clock mismatch');Check(mrrClockMismatch in A.Reasons,'Clock reason');
 for I:=0 to 2 do begin
  Base(R,S,E);R.ActivationSource:=mavActivation;E.HasStart:=False;E.ActivationState:=TMobibActivationState(I);
  A:=TMobibRuleEngine.Evaluate(R,S,E);
  if I=1 then Check(A.Verdict=mrvIneligible,'Known unactivated') else Check(A.Verdict=mrvUnknown,'Missing activation evidence');
  if I=2 then begin E.HasActivationTime:=True;E.ActivationTime:=E.Now;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Explicit activation timestamp');end;
 end;
 Base(R,S,E);R.ActivationSource:=mavFirstValidation;E.HasStart:=False;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'No latest-event substitution');
 E.HasFirstValidation:=True;E.FirstValidation:=E.Now;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Known first validation');
 Base(R,S,E);R.DurationUnit:=mduExplicitEnd;R.DurationAmount:=0;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing explicit end');
 E.Now:=E.Start-1/86400;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Known future start despite missing end');E.Now:=E.Start;
 E.HasEnd:=True;E.EndTime:=E.Start+1;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Explicit complete window');
 E.HasStart:=False;E.Now:=E.EndTime;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Known past end despite missing start');E.HasStart:=True;E.Now:=E.Start;
 E.EndTime:=E.Start;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Invalid zero window');Check(mrrInvalidWindow in A.Reasons,'Invalid window reason');
 Base(R,S,E);R.ClockBasis:=mcbOperatorLocal;E.ClockBasis:=mcbOperatorLocal;R.DurationUnit:=mduCalendarMonths;R.DurationAmount:=1;
 for Y:=1900 to 2299 do begin
  E.Start:=EncodeDate(Y,1,31)+EncodeTime(12,30,0,0);E.Now:=E.Start;A:=TMobibRuleEngine.Evaluate(R,S,E);
  D:=28;if IsLeapYear(Y) then D:=29;
  Check(A.EndTime=EncodeDate(Y,2,D)+EncodeTime(12,30,0,0),'Gregorian month-end clamp');Check(A.Verdict=mrvEligible,'Month window');
  E.Start:=EncodeDate(Y,1,15);E.Now:=E.Start;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.EndTime=EncodeDate(Y,2,15),'Ordinary day preserved');
 end;
 E.Start:=EncodeDate(2024,2,29);E.Now:=E.Start;R.DurationUnit:=mduCalendarYears;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.EndTime=EncodeDate(2025,2,28),'Leap-year end');
 R.DurationUnit:=mduCalendarDays;R.EndFromMidnight:=True;E.Start:=EncodeDate(2026,3,29)+EncodeTime(15,30,0,0);E.Now:=E.Start;
 A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Start=E.Start,'Activation time retained');Check(A.EndTime=EncodeDate(2026,3,30),'Calendar ticket ends midnight');
 E.Start:=EncodeDate(9999,12,31);E.Now:=E.Start;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Date overflow unknown');Check(mrrInvalidWindow in A.Reasons,'Overflow reason');
 Base(R,S,E);R.ClockBasis:=mcbOperatorLocal;E.ClockBasis:=mcbOperatorLocal;R.ActivationSource:=mavSaleDate;R.DurationUnit:=mduCalendarDays;
 A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Absent sale date');
 S.HasSaleDate:=True;S.SaleDate:=E.Start;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Sale only with explicit sale-based rule');
end;
procedure ZonesAndTrips;
var R:TMobibProductRule;S:TMobibSubscription;E:TMobibRuleEvidence;A:TMobibRuleAssessment;
begin
 Base(R,S,E);R.ZoneMode:=mzmPolicySet;SetLength(R.Zones,2);R.Zones[0]:=1;R.Zones[1]:=65535;
 A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing journey zone evidence');
 E.HasJourneyZones:=True;SetLength(E.JourneyZones,2);E.JourneyZones[0]:=65535;E.JourneyZones[1]:=1;
 A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'All requested zones in set');
 E.JourneyZones[1]:=2;E.HasStart:=False;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Known failure dominates unknown start');Check(mrrOutsideZones in A.Reasons,'Zone failure reason');Check(mrrMissingStart in A.Reasons,'Independent missing reason retained');
 R.ZoneMode:=mzmContractSet;R.Zones:=nil;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing contract zones');Check(mrrMissingContractZones in A.Reasons,'Contract zones reason');
 E.HasContractZones:=True;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Known empty permitted set');
 E.ContractZones:=Copy(E.JourneyZones,0,2);E.HasStart:=True;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Explicit contract zones');
 R.RequireRemainingTrip:=True;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing trip evidence');
 S.HasRemainingTrips:=True;S.RemainingTrips:=0;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvIneligible,'Zero trips retained');Check(mrrNoTrips in A.Reasons,'No trips reason');
 S.RemainingTrips:=7;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Positive new-journey count');
end;
procedure ProfilesAndDuration;
var R:TMobibProductRule;S:TMobibSubscription;E:TMobibRuleEvidence;A:TMobibRuleAssessment;I:Integer;
begin
 for I:=0 to 5 do begin
  Base(R,S,E);case I of
   0:S.LayoutMatched:=False;
   1:E.OperatorId:='other';
   2:E.CountryCode:=250;
   3:E.NetworkCode:=2;
   4:S.Tariff:=$2801;
   5:S.Version:=5;
  end;
  A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Exact profile match');Check(mrrProfileMismatch in A.Reasons,'Mismatch reason');
 end;
 Base(R,S,E);R.DurationUnit:=mduContractField;R.DurationAmount:=0;
 for I:=0 to 3 do begin
  S.HasDuration:=True;S.DurationValue:=2;S.DurationUnitCode:=I;
  A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Unmapped raw duration code');
  R.ContractUnits[I]:=mduHours;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvEligible,'Explicit code mapping');Check(A.EndTime=E.Start+2/24,'Mapped duration amount');
 end;
 S.DurationValue:=0;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Zero duration not valid');
 S.HasDuration:=False;A:=TMobibRuleEngine.Evaluate(R,S,E);Check(A.Verdict=mrvUnknown,'Missing duration field');
end;
procedure Invalid;
var R:TMobibProductRule;S:TMobibSubscription;E:TMobibRuleEvidence;A:TMobibRuleAssessment;I:Integer;Failed:Boolean;
begin
 for I:=0 to 13 do begin
  Base(R,S,E);
  case I of
   0:R.Source:='';
   1:R.OperatorId:='';
   2:R.DurationAmount:=0;
   3:R.ClockBasis:=mcbOperatorLocal;
   4:R.DurationUnit:=mduCalendarMonths;
   5:R.MaxVersion:=5;
   6:R.ZoneMode:=mzmPolicySet;
   7:begin R.ZoneMode:=mzmPolicySet;SetLength(R.Zones,2);R.Zones[0]:=1;R.Zones[1]:=1;end;
   8:begin E.ActivationState:=masInactive;E.HasFirstValidation:=True;E.FirstValidation:=E.Now;end;
   9:E.Now:=NaN;
   10:E.HasEnd:=True;
   11:R.EndFromMidnight:=True;
   12:SetLength(E.ContractZones,65);
   13:R.Tariff:=$FFFF;
  end;
  Failed:=False;try A:=TMobibRuleEngine.Evaluate(R,S,E);except on X:EMobibRuleError do Failed:=True;end;
  Check(Failed,'Invalid rule or evidence rejected');
 end;
end;
begin try Temporal;ZonesAndTrips;ProfilesAndDuration;Invalid;Writeln('MOBIB rules: ',Checks,' assertions passed.');
 except on X:Exception do begin Writeln(X.ClassName,': ',X.Message);Halt(1);end;end;end.
