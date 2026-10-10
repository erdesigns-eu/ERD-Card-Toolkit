program CalypsoNetworksTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.EN1545, ERD.Card.Contactless.Calypso, ERD.Card.Calypso.Networks;

type
  TBitWriter = record
    Data: TBytes;
    Pos: Integer;
    procedure Init(const ABytes: Integer);
    procedure Put(const AValue: UInt64; const AWidth: Integer);
  end;

var
  Checks: Integer;

procedure TBitWriter.Init(const ABytes: Integer);
begin
  SetLength(Data, ABytes);
  FillChar(Data[0], ABytes, 0);
  Pos := 0;
end;

procedure TBitWriter.Put(const AValue: UInt64; const AWidth: Integer);
var
  I: Integer;
begin
  for I := AWidth - 1 downto 0 do
  begin
    if ((AValue shr I) and 1) <> 0 then
      Data[Pos shr 3] := Data[Pos shr 3] or (1 shl (7 - (Pos and 7)));
    Inc(Pos);
  end;
end;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then
    raise Exception.Create('Calypso network regression: ' + AMessage);
end;

function Days(const Y, M, D: Word): UInt64;
begin
  Result := Round(EncodeDate(Y, M, D) - EncodeDate(1997, 1, 1));
end;

function Env24(const AId: Cardinal): TBytes;
var
  W: TBitWriter;
begin
  W.Init(29);
  W.Put(1, 6);
  W.Put(0, 7);
  W.Put(AId, 24);
  Result := W.Data;
end;

procedure AddFile(var S: TMobibSnapshot; const AFolder, AId: Word; const ARecords: array of TBytes);
var
  N, I: Integer;
begin
  N := Length(S.Files);
  SetLength(S.Files, N + 1);
  S.Files[N].LogicalId := AId;
  S.Files[N].Folder := AFolder;
  S.Files[N].SelectionStatus := $9000;
  SetLength(S.Files[N].Records, Length(ARecords));
  for I := 0 to High(ARecords) do
  begin
    S.Files[N].Records[I].Number := I + 1;
    S.Files[N].Records[I].Data := ARecords[I];
  end;
end;

function Text(const P: TEn1545Parsed; const APath: string): string;
var
  V: TEn1545Value;
begin
  if TEn1545.Find(P, APath, V) then
    Result := V.Text
  else
    Result := '<absent>';
end;

procedure RecommendTests;
var
  M: TCalypsoNetworkMatch;
  W: TBitWriter;
begin
  M := TCalypsoNetworks.Recommend(Env24($056001));
  Check(M.Matched and (M.Kind = cnkMobib) and (M.NetworkCode = '056001'), 'MOBIB discriminator');
  M := TCalypsoNetworks.Recommend(Env24($250901));
  Check(M.Matched and (M.Kind = cnkIntercode) and (M.NetworkName = 'Navigo (Ile-de-France)'),
    'Navigo discriminator');
  M := TCalypsoNetworks.Recommend(Env24($250777));
  Check((M.Kind = cnkIntercode) and (M.NetworkName = '') and (Pos('777', M.Reason) > 0),
    'Other French network');
  Check(TCalypsoNetworks.Recommend(Env24($124001)).Kind = cnkOpus, 'OPUS discriminator');
  Check(TCalypsoNetworks.Recommend(Env24($131000)).Kind = cnkLisboaViva, 'Lisboa discriminator');
  W.Init(29);
  W.Put(1, 3);
  W.Put($37603, 20);
  Check(TCalypsoNetworks.Recommend(W.Data).Kind = cnkRavKav, 'Rav-Kav discriminator');
  W.Init(29);
  W.Put($7D0, 32);
  Check(TCalypsoNetworks.Recommend(W.Data).Kind = cnkVenezia, 'Venezia discriminator');
  W.Init(29);
  W.Put(1, 5);
  W.Put($380100, 24);
  Check(TCalypsoNetworks.Recommend(W.Data).Kind = cnkPisa, 'Pisa discriminator');
  M := TCalypsoNetworks.Recommend(Env24($999001));
  Check((not M.Matched) and (M.Kind = cnkUnknown) and (M.NetworkCode = '999001'),
    'Unknown network never guessed');
  M := TCalypsoNetworks.Recommend(TBytes.Create(1, 2, 3));
  Check((not M.Matched) and (Pos('shorter', M.Reason) > 0), 'Short environment');
end;

procedure IntercodeTests;
var
  S: TMobibSnapshot;
  W: TBitWriter;
  Env, List, C1, C2, Ev, Ctr, Icc: TBytes;
  V: TCalypsoNetworkView;
  I, Contracts: Integer;
  M: TCalypsoNetworkMatch;
begin
  W.Init(29);
  W.Put(1, 6);
  W.Put(5, 7);
  W.Put($250901, 24);
  W.Put(Days(2030, 1, 31), 14);
  W.Put(0, 8);
  Env := W.Data;

  W.Init(29);
  W.Put(1, 4);
  W.Put(7, 3);
  W.Put($250901, 24);
  W.Put($0FF0, 16);
  W.Put(1, 5);
  List := W.Data;

  W.Init(29);
  W.Put((1 shl 1) or (1 shl 2) or (1 shl 10) or (1 shl 13), 20);
  W.Put(3, 8);
  W.Put($0FF0, 16);
  W.Put(7500, 16);
  W.Put(5, 9);
  W.Put(Days(2026, 7, 1), 14);
  W.Put(Days(2026, 7, 31), 14);
  C1 := W.Data;
  C2 := TBytes.Create($12, $34);

  W.Init(29);
  W.Put(Days(2026, 7, 2), 14);
  W.Put(8 * 60 + 15, 11);
  W.Put((1 shl 4) or (1 shl 11), 28);
  W.Put(3, 8);
  W.Put(42, 16);
  Ev := W.Data;

  Ctr := TBytes.Create(0, 0, 5, 0, 0, 0);
  Icc := TBytes.Create(1, 2, 3);
  S := Default (TMobibSnapshot);
  AddFile(S, 0, $2001, [Env]);
  AddFile(S, 0, $2050, [List]);
  AddFile(S, 0, $2020, [C1, C2, TBytes.Create(0, 0)]);
  AddFile(S, 0, $2010, [Ev, TBytes.Create(0, 0, 0)]);
  AddFile(S, 0, $2069, [Ctr]);
  AddFile(S, $3F00, $0002, [Icc]);

  M := TCalypsoNetworks.RecommendSnapshot(S);
  Check(M.Kind = cnkIntercode, 'Snapshot recommendation');
  V := TCalypsoNetworks.Decode(S, cnkIntercode);
  Check((V.Kind = cnkIntercode) and (not V.CheckedOnCard) and (Pos('Not checked', V.Note) = 1),
    'Profile is marked as not checked on a card');
  Check((V.Records[0].Role = crrEnvironment) and V.Records[0].Decoded and
    V.Records[0].Parsed.Complete, 'Environment decoded');
  Check(Text(V.Records[0].Parsed, 'EnvNetworkId') = '250901', 'Environment network');
  Check(Text(V.Records[0].Parsed, 'EnvApplicationValidityEndDate') = '2030-01-31', 'Validity end');
  Contracts := 0;
  for I := 0 to High(V.Records) do
    case V.Records[I].Role of
      crrContractList:
        Check(V.Records[I].Decoded and
          (TEn1545.IntOr(V.Records[I].Parsed, 'ContractsPointer[1]', 0) = 1), 'Contract list');
      crrContract:
        begin
          Inc(Contracts);
          Check(V.Records[I].ContractNumber = Contracts, 'Contract numbering');
          case Contracts of
            1:
              begin
                Check(V.Records[I].Decoded and V.Records[I].Parsed.Complete, 'Type FF contract');
                Check(Pos('variant FF', V.Records[I].Note) > 0, 'Variant noted');
                Check(TEn1545.IntOr(V.Records[I].Parsed, 'ContractPriceAmount', 0) = 7500,
                  'Contract price');
                Check((Text(V.Records[I].Parsed, 'ContractStartDate') = '2026-07-01') and
                  (Text(V.Records[I].Parsed, 'ContractEndDate') = '2026-07-31'), 'Contract dates');
                Check(V.Records[I].HasCounter and (V.Records[I].Counter = 5) and
                  (V.Records[I].CounterFileId = $2069), 'Counter from 2069');
              end;
            2:
              Check((not V.Records[I].Decoded) and (Pos('Not referenced', V.Records[I].Note) = 1)
                and (Length(V.Records[I].Data) = 2), 'Unreferenced contract stays raw');
            3:
              Check((not V.Records[I].Decoded) and (V.Records[I].Note = 'Empty record.'),
                'Empty contract');
          end;
        end;
      crrEvent:
        if V.Records[I].RecordNumber = 1 then
        begin
          Check(V.Records[I].Decoded and V.Records[I].Parsed.Complete, 'Event decoded');
          Check((TEn1545.IntOr(V.Records[I].Parsed, 'EventRouteNumber', 0) = 42) and
            (Text(V.Records[I].Parsed, 'EventDate') = '2026-07-02'), 'Event fields');
        end
        else
          Check(not V.Records[I].Decoded, 'Empty event');
      crrCounter:
        Check(not V.Records[I].Decoded, 'Counter raw');
      crrOther:
        Check((V.Records[I].Folder = $3F00) and (V.Records[I].FileId = 2) and
          not V.Records[I].Decoded, 'Other folder raw');
    end;
  Check(Contracts = 3, 'Three contract records');

  V := TCalypsoNetworks.Decode(S, cnkUnknown);
  Check(V.Records[0].Decoded and (Text(V.Records[0].Parsed, 'EnvNetworkId') = '250901'),
    'Generic header');
  for I := 1 to High(V.Records) do
    Check(not V.Records[I].Decoded, 'Generic view keeps records raw');
end;

procedure OtherProfileTests;
var
  S: TMobibSnapshot;
  W: TBitWriter;
  V: TCalypsoNetworkView;
  I: Integer;
  Found: Boolean;
begin
  W.Init(29);
  W.Put(1, 3);
  W.Put(Days(2026, 3, 1), 14);
  W.Put(2, 8);
  W.Put(123, 11);
  W.Put(Days(2026, 2, 27), 14);
  W.Put(77, 12);
  W.Put(9, 10);
  W.Put(1, 1);
  W.Put(1 shl 3, 9);
  W.Put(Days(2026, 3, 31), 14);
  S := Default (TMobibSnapshot);
  AddFile(S, 0, $202A, [TBytes.Create(0, 0, 12)]);
  AddFile(S, 0, $2020, [W.Data]);
  V := TCalypsoNetworks.Decode(S, cnkRavKav);
  Found := False;
  for I := 0 to High(V.Records) do
    if V.Records[I].Role = crrContract then
    begin
      Found := True;
      Check(V.Records[I].Decoded and V.Records[I].Parsed.Complete, 'Rav-Kav contract');
      Check((TEn1545.IntOr(V.Records[I].Parsed, 'ContractTariff', 0) = 123) and
        (Text(V.Records[I].Parsed, 'ContractEndDate') = '2026-03-31'), 'Rav-Kav fields');
      Check(V.Records[I].HasCounter and (V.Records[I].Counter = 12) and
        (V.Records[I].CounterFileId = $202A), 'Counter fallback to 202A');
    end;
  Check(Found, 'Rav-Kav contract present');

  S := Default (TMobibSnapshot);
  AddFile(S, 0, $2030, [TBytes.Create(1)]);
  V := TCalypsoNetworks.Decode(S, cnkOpus);
  Check((Length(V.Records) = 1) and (V.Records[0].Role = crrOther), 'OPUS 2030 is not a contract file');
  V := TCalypsoNetworks.Decode(S, cnkLisboaViva);
  Check((Length(V.Records) = 1) and (V.Records[0].Role = crrContract), 'Lisboa 2030 contracts');
  V := TCalypsoNetworks.Decode(S, cnkMobib);
  Check(Pos('TMobibCodec', V.Note) > 0, 'MOBIB profile points at the MOBIB codec');
  Check(TCalypsoNetworks.RoleName(crrSpecialEvent) = 'special event', 'Role name');
end;

begin
  try
    RecommendTests;
    IntercodeTests;
    OtherProfileTests;
    Writeln('Calypso networks: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
