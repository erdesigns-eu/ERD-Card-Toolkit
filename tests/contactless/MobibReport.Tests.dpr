program MobibReportTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Contactless.Calypso, ERD.Card.EN1545, ERD.Card.MOBIB.Data,
  ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Lookup, ERD.Card.MOBIB.Report;

{ Synthetic fixtures copy the structure of observed MOBIB cards, never personal values. }

var
  Checks: Integer;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then
    raise Exception.Create('MOBIB report regression: ' + AMessage);
end;

procedure Put(var B: TBytes; const Offset, Count: Integer; const V: UInt64);
var
  I, P: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    P := Offset + I;
    if (V and (UInt64(1) shl (Count - I - 1))) <> 0 then
      B[P div 8] := B[P div 8] or (1 shl (7 - P mod 8))
    else
      B[P div 8] := B[P div 8] and not (1 shl (7 - P mod 8));
  end;
end;

procedure PutBcd(var B: TBytes; const Offset: Integer; const Digits: string);
var
  I: Integer;
begin
  for I := 1 to Length(Digits) do
    Put(B, Offset + (I - 1) * 4, 4, Ord(Digits[I]) - Ord('0'));
end;

function Zero(const ACount: Integer): TBytes;
begin
  Result := nil;
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount, 0);
end;

function Days(const Y, M, D: Word): Cardinal;
begin
  Result := Cardinal(Trunc(EncodeDate(Y, M, D) - EncodeDate(1997, 1, 1)));
end;

function Environment(const AVersion: Byte; const APersonal: Boolean): TBytes;
var
  ExpiryAt: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, AVersion);
  Put(Result, 6, 7, 1);
  PutBcd(Result, 13, '056001');
  if AVersion <= 2 then
    ExpiryAt := 46
  else
    ExpiryAt := 42;
  Put(Result, ExpiryAt, 14, Days(2031, 3, 15));
  PutBcd(Result, 98, '1234567890123456789');
  if APersonal then
  begin
    PutBcd(Result, 66, '19800229');
    Put(Result, 179, 14, 1000);
  end;
end;

procedure AddFile(var S: TMobibSnapshot; const AFolder, AId: Word;
  const AStatus: Word; const ARecords: array of TBytes);
var
  N, I: Integer;
begin
  N := Length(S.Files);
  SetLength(S.Files, N + 1);
  S.Files[N] := Default (TCalypsoFile);
  S.Files[N].Folder := AFolder;
  S.Files[N].LogicalId := AId;
  S.Files[N].SelectionStatus := AStatus;
  SetLength(S.Files[N].Records, Length(ARecords));
  for I := 0 to High(ARecords) do
  begin
    S.Files[N].Records[I].Number := I + 1;
    S.Files[N].Records[I].Data := ARecords[I];
  end;
end;

function BitmapEvent(const AVersion: Byte; const AProvider: Byte;
  const ALocation: Cardinal): TBytes;
var
  O: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, AVersion);
  Put(Result, 6, 14, Days(2025, 6, 1));
  Put(Result, 20, 11, 17 * 60 + 5);
  O := 62;
  Put(Result, O, 5, 1 or 2 or 16);
  Inc(O, 5);
  Put(Result, O + 4, 12, 345);
  Inc(O, 16);
  Put(Result, O, 16, 1234);
  Inc(O, 16);
  Put(Result, O, 5, AProvider);
  Put(Result, O + 5, 17, ALocation);
  Inc(O, 32);
  Put(Result, O, 6, 1 or 4 or 16);
  Inc(O, 6);
  Put(Result, O, 24, 77);
  Inc(O, 24);
  Put(Result, O, 8, 2);
  Inc(O, 8);
  Put(Result, O, 14, Days(2025, 6, 1));
  Put(Result, O + 14, 11, 16 * 60 + 55);
end;

function ContractV4(const ATariff: Word; const AStart, AEnd: TDateTime): TBytes;
var
  O: Integer;
begin
  Result := Zero(29);
  Put(Result, 0, 6, 4);
  Put(Result, 6, 14, $3FFF - Cardinal(Trunc(AEnd - EncodeDate(1997, 1, 1))));
  Put(Result, 25, 14, ATariff);
  Put(Result, 89, 16, 6200);
  Put(Result, 111, 5, 4 or 8);
  O := 116;
  Put(Result, O, 14, Cardinal(Trunc(AStart - EncodeDate(1997, 1, 1))));
  Inc(O, 14);
  Put(Result, O, 2, 3);
  Put(Result, O + 2, 8, 1);
end;


function Snapshot: TMobibSnapshot;
var
  C: TBytes;
begin
  Result := Default (TMobibSnapshot);
  C := ContractV4($000F, EncodeDate(2026, 7, 12), EncodeDate(2026, 8, 12));
  AddFile(Result, 0, $2001, $9000, [Environment(3, True)]);
  AddFile(Result, 0, $2020, $9000, [C, ContractV4($000F, EncodeDate(2026, 6, 12),
    EncodeDate(2026, 7, 12)), Copy(C, 0, Length(C)), Zero(29)]);
  AddFile(Result, 0, $2040, $9000, [BitmapEvent(3, 0, 0), Zero(29)]);
  AddFile(Result, 0, $2010, $9000, [Zero(29)]);
  Result.Files[0].Info.Present := True;
  Result.Files[0].Info.Structure := cfsLinear;
  Result.Files[0].Info.Sfi := 7;
  Result.Files[0].Info.RecordSize := 29;
  Result.Files[0].Info.RecordCount := 1;
end;

function Balanced(const S: string): Boolean;
var
  I, Depth: Integer;
  InString: Boolean;
begin
  Depth := 0;
  InString := False;
  I := 1;
  Result := False;
  while I <= Length(S) do
  begin
    if InString then
    begin
      if S[I] = '\' then
        Inc(I)
      else if S[I] = '"' then
        InString := False;
    end
    else
      case S[I] of
        '"':
          InString := True;
        '{', '[':
          Inc(Depth);
        '}', ']':
          begin
            Dec(Depth);
            if Depth < 0 then
              Exit;
          end;
      else
        if Ord(S[I]) > 126 then
          Exit;
      end;
    Inc(I);
  end;
  Result := (Depth = 0) and not InString;
end;

function NodeValue(const N: TMobibReportNodes; const AKey: string): string;
var
  I: Integer;
begin
  Result := '<absent>';
  for I := 0 to High(N) do
    if N[I].Key = AKey then
      Exit(N[I].Value);
end;

procedure Tests;
var
  D: TMobibData;
  Subs: TMobibSubscriptions;
  O: TMobibReportOptions;
  N: TMobibReportNodes;
  T, J: string;
  L: TMobibLookup;
  I: Integer;
  F: TCalypsoFile;
begin
  D := TMobibCodec.Decode(Snapshot, mlLegacy056001);
  Subs := TMobibSubscriptionCodec.DecodeSnapshot(D);
  O := TMobibReport.DefaultOptions;
  Check((not O.ShowPersonal) and (not O.HasNow) and (O.Context = mocUnspecified), 'Default options');
  O.Context := mocDeLijn;
  O.HasNow := True;
  O.Now := EncodeDate(2026, 7, 20);
  N := TMobibReport.Build(D, Subs, nil, O);
  T := TMobibReport.ToText(N);
  J := TMobibReport.ToJson(N);
  for I := 0 to High(N) do
    if N[I].Parent >= 0 then
      Check(N[I].Parent < I, 'Parent-first order');
  Check(Pos('Operator context: De Lijn', T) > 0, 'De Lijn context shown');
  Check(Pos('publishes no stop-code', LowerCase(NodeValue(N, 'card.operator.note'))) > 0, 'De Lijn limits noted');
  Check(NodeValue(N, 'overview.cardnumber') = TMobibReport.MaskText, 'Card number masked');
  Check(NodeValue(N, 'overview.birthdate') = TMobibReport.MaskText, 'Birth date masked');
  Check(NodeValue(N, 'overview.postal') = TMobibReport.MaskText, 'Postal code masked');
  Check((Pos('1980', T) = 0) and (Pos('123456', T) = 0) and (Pos('1000', T) = 0),
    'No personal value in text');
  Check((Pos('1980', J) = 0) and (Pos('123456', J) = 0) and (Pos('"masked":true', J) > 0),
    'No personal value in JSON');
  Check(NodeValue(N, 'overview.expiry') = '2031-03-15', 'Card expiry is not personal');
  Check(NodeValue(N, 'overview.expiry.printed') = '2031-03-14', 'Printed expiry is one day earlier');
  Check(Pos('Card expiry (stored, first invalid day): 2031-03-15' + sLineBreak, T) > 0,
    'Expiry confidence found under the layout field name');
  Check(NodeValue(N, 'overview.type') = 'personal (holder data present)', 'Card type');
  Check(NodeValue(N, 'overview.active') = '1', 'Duplicate not counted as a second active contract');
  Check(NodeValue(N, 'contract.1.product') = 'De Lijn monthly subscription (confirmed on one card)',
    'De Lijn context names the holder-confirmed tariff');
  Check(Pos('Kind: period pass [observed]', T) > 0, 'Period pass with confidence');
  Check((NodeValue(N, 'contract.1.start') = '2026-07-12') and
    (NodeValue(N, 'contract.1.end') = '2026-08-12'), 'Validity dates');
  Check(Pos('Duration: 1 month (unit code 3) [observed]', T) > 0, 'Observed month unit');
  Check((NodeValue(N, 'contract.1.status') = 'active') and
    (NodeValue(N, 'contract.2.status') = 'expired'), 'Status at explicit date');
  Check(Pos('identical to contract 1', NodeValue(N, 'contract.3.duplicate')) = 1, 'Duplicate flagged');
  Check(NodeValue(N, 'contract.4') = '<absent>', 'Empty contract omitted');
  Check(Pos('SPECIAL EVENTS (1 decoded)', T) > 0, 'Special event section');
  Check(NodeValue(N, 'special.1.time') = '2025-06-01 17:05', 'Special event time');
  Check(Pos('VALIDATIONS (0 decoded)', T) > 0, 'Empty validations');
  Check(Pos('Environment (2001): linear, SFI 07, 1 records of 29 bytes', T) > 0, 'File information');
  Check((Pos('{"format":"erd-card-mobib-report","version":1,"sections":[', J) = 1) and Balanced(J),
    'JSON structure');
  Check(Pos('"confidence":"observed"', J) > 0, 'JSON confidence labels');

  O.ShowPersonal := True;
  O.Context := mocStib;
  L := TMobibLookup.Create(mocStib);
  try
    N := TMobibReport.Build(D, Subs, L, O);
  finally
    L.Free;
  end;
  Check(NodeValue(N, 'overview.cardnumber') = string(D.Environment.CardNumberFormatted), 'Explicit show');
  Check(NodeValue(N, 'overview.birthdate') = '1980-02-29', 'Birth date shown on request');
  T := TMobibReport.ToText(N);
  Check(Pos('[masked]', T) = 0, 'Nothing masked when shown');
  Check(Pos('Operator context: STIB-MIVB', T) > 0, 'Caller lookup context used');

  F := Default (TCalypsoFile);
  F.LogicalId := $2001;
  Check(TMobibReport.IsPersonalFile(F), 'Environment is personal');
  F.LogicalId := $2020;
  Check(not TMobibReport.IsPersonalFile(F), 'Contracts are not personal');
  F.Folder := $3F00;
  F.LogicalId := $0003;
  Check(TMobibReport.IsPersonalFile(F), 'ID file is personal');
  F.LogicalId := $0002;
  Check(not TMobibReport.IsPersonalFile(F), 'ICC file is not personal');
end;

begin
  try
    Tests;
    Writeln('MOBIB report: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
