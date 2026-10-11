program CalypsoReaderTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
{$R+}
{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Contactless.Calypso;

{ Exact APDU transcripts for application selection, file information, record size from the card,
  short-file-identifier reads and folder-qualified read plans. All values are synthetic. }

const
  Fci = '6F228408315449432E494341A516BF0C13C708000000001234567853070A3C2B05141001';
  FileSelection = '6F19851707040230011F101F100103010300200100000000002001';

type
  TStep = record
    Command, Response: TBytes;
    Fails: Boolean;
  end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    Active, EndFails, BeginFails: Boolean;
    procedure Add(const ACommand, AResponse: string; const AFails: Boolean = False);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TBareTransport = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;

var
  Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create('Calypso reader regression: ' + AMessage);
end;

procedure TScript.Add(const ACommand, AResponse: string; const AFails: Boolean);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Command := HexToBytes(ACommand);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Fails := AFails;
end;

procedure TScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic begin failure');
  Check(not Active, 'Exclusive transaction is not nested');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Inc(Ends);
  Check(Active, 'Transaction active on release');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic end failure');
end;

function TScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(Steps), 'No unexpected APDU');
  Check(BytesEqual(ACommand, Steps[Position].Command), 'Exact APDU at step ' + IntToStr(Position) +
    ': ' + BytesToHex(ACommand));
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

function TBareTransport.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Bare transport must not be invoked');
end;

procedure TestDecoding;
var
  App: TCalypsoApplicationInfo;
  Info: TCalypsoFileInfo;
begin
  App := TCalypsoFci.DecodeApplication(HexToBytes(Fci));
  Check(App.Valid and (App.ProductType = cptPrimeRevision3), 'Revision 3 startup information');
  Check(BytesToHex(App.SerialNumber) = '0000000012345678', 'Serial number from tag C7');
  Check(BytesToHex(App.DfName) = '315449432E494341', 'DF name from tag 84');
  Check(App.HasPin and App.HasStoredValue and App.ExtendedMode and not App.Pki and not App.Hce,
    'Application type flags');
  Check((App.BufferSizeIndicator = $0A) and (App.BufferSizeBytes = 430), 'Session buffer size');
  Check(App.HasRecommendedDialect and (App.RecommendedDialect = cdIso00), 'Dialect advice');
  App := TCalypsoFci.DecodeStartupInfo(HexToBytes('0000000012345678'), HexToBytes('0A3C0505141001'));
  Check((App.ProductType = cptPrimeRevision2) and (App.RecommendedDialect = cdLegacy94) and
    (App.BufferSizeBytes = 0), 'Revision 2 startup information');
  App := TCalypsoFci.DecodeStartupInfo(HexToBytes('0000008012345678'), HexToBytes('0A3C9105141001'));
  Check((App.ProductType = cptLight) and App.Hce, 'Light product and HCE serial flag');
  App := TCalypsoFci.DecodeStartupInfo(HexToBytes('00'), HexToBytes('0A3C2B05141001'));
  Check(not App.Valid, 'Short serial rejected without guessing');
  Info := TCalypsoFci.DecodeFileInfo(HexToBytes(FileSelection));
  Check(Info.Present and (Info.Sfi = 7) and (Info.Kind = cfkElementaryFile) and
    (Info.Structure = cfsLinear), 'File information structure');
  Check((Info.RecordSize = 48) and (Info.RecordCount = 1) and (Info.LogicalId = $2001),
    'File information size, count and LID');
  Check((Info.AccessConditions[0] = $1F) and (Info.KeyIndexes[1] = 3) and (Info.DataReference = $2001),
    'Access conditions, key indexes and data reference');
  Info := TCalypsoFci.DecodeFileInfo(HexToBytes('6F03850100'));
  Check(not Info.Present, 'Short tag 85 ignored');
end;

procedure TestPlan;
var
  S: TScript;
  T: ICardTransport;
  C: TCalypsoCardReader;
  Plan: TCalypsoFileRefs;
  M: TMobibSnapshot;
begin
  S := TScript.Create; T := S;
  S.Add('00A4040008315449432E49434100', Fci + '9000');
  S.Add('94A4000002200000', '9000');
  S.Add('94A4000002200100', FileSelection + '9000');
  S.Add('94B2010430', '1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119000');
  S.Add('94B2013C1D', '22229000');
  S.Add('94B2023C1D', '6A83');
  S.Add('94A40000023F0000', '9000');
  S.Add('94A4000002000200', '9000');
  S.Add('94B201041D', '33339000');
  S.Add('94B202041D', '6A83');
  S.Add('94A40000023F0000', '9000');
  S.Add('94A4000002100000', '6A82');
  S.Add('94A40000023F0000', '9000');
  S.Add('94A4000002200000', '9000');
  S.Add('94A4000002201000', '6A82');
  SetLength(Plan, 5);
  Plan[0] := TCalypsoCardReader.FileRef(0, $2001);
  Plan[1] := TCalypsoCardReader.SfiRef(0, 7);
  Plan[2] := TCalypsoCardReader.FileRef($3F00, $0002);
  Plan[3] := TCalypsoCardReader.FileRef($1000, $1014);
  Plan[4] := TCalypsoCardReader.FileRef(0, $2010);
  C := TCalypsoCardReader.Create(nil);
  try
    C.Transport := T;
    C.ApplicationName := '1TIC.ICA';
    C.RecordSizeFromCard := True;
    M := C.ReadMobibPlan(Plan, 4);
    Check(C.Dialect = cdLegacy94, 'Recommended dialect is not applied');
  finally
    C.Free;
  end;
  Check((S.Position = Length(S.Steps)) and (S.Begins = 1) and (S.Ends = 1), 'Complete plan in one transaction');
  Check(M.Application.Valid and (M.Application.StatusWord = $9000), 'Application information kept');
  Check((Length(M.Files) = 5) and (Length(M.Files[0].Records) = 1) and
    (Length(M.Files[0].Records[0].Data) = 48) and not M.Files[0].Truncated, 'Card record size and count used');
  Check(M.Files[1].BySfi and (M.Files[1].Sfi = 7) and (BytesToHex(M.Files[1].Records[0].Data) = '2222') and
    (M.Files[1].LastRecordStatus = $6A83), 'SFI read without SELECT');
  Check((M.Files[2].Folder = $3F00) and (M.Files[2].LogicalId = $0002) and
    (BytesToHex(M.Files[2].Records[0].Data) = '3333') and not M.Files[2].Info.Present,
    'Master-file entry falls back to RecordBytes');
  Check((M.Files[3].Folder = $1000) and (M.Files[3].SelectionStatus = $6A82) and
    (Length(M.Files[3].Records) = 0), 'Missing folder recorded per entry');
  Check((M.Files[4].Folder = 0) and (M.Files[4].SelectionStatus = $6A82), 'Ticketing folder re-entered');

  S := TScript.Create; T := S;
  S.Add('00A4040008315449432E49434100', '6A82');
  S.Add('94A4000002200000', '9000');
  S.Add('94A4000002200100', '6A82');
  C := TCalypsoCardReader.Create(nil);
  try
    C.Transport := T;
    C.ApplicationName := '1TIC.ICA';
    M := C.ReadMobibPlan([TCalypsoCardReader.FileRef(0, $2001)]);
  finally
    C.Free;
  end;
  Check((S.Position = 3) and not M.Application.Valid and (M.Application.StatusWord = $6A82),
    'Missing application recorded, read continues');

  S := TScript.Create; T := S;
  S.Add('00A4040008315449432E49434100', '6985');
  C := TCalypsoCardReader.Create(nil);
  try
    C.Transport := T;
    try
      C.SelectApplication('1TIC.ICA');
      Check(False, 'Unexpected application status raises');
    except
      on E: ECalypsoStatusError do Check(E.StatusWord = $6985, 'Status kept in exception');
    end;
  finally
    C.Free;
  end;
  Check(S.Ends = 1, 'Transaction released after failure');
end;

procedure TestPlans;
var
  P: TCalypsoFileRefs;
  I, J: Integer;
  HasIcc: Boolean;
  C: TCalypsoCardReader;
begin
  P := TCalypsoCardReader.MobibInventoryPlan;
  HasIcc := False;
  for I := 0 to High(P) do
  begin
    if (P[I].Folder = $3F00) and (P[I].LogicalId = $0002) then
      HasIcc := True;
    Check(P[I].Kind = cfrLogicalId, 'Inventory has no SFI sweep');
    for J := 0 to I - 1 do
      Check((P[I].Folder <> P[J].Folder) or (P[I].LogicalId <> P[J].LogicalId), 'Inventory entries unique');
  end;
  Check(HasIcc and (Length(P) <= 128), 'Inventory includes ICC and fits one plan');
  P := TCalypsoCardReader.SfiSweepPlan(0, 1, 30);
  Check((Length(P) = 30) and (P[0].Sfi = 1) and (P[29].Sfi = 30) and (P[5].Kind = cfrSfi), 'Bounded SFI sweep');
  C := TCalypsoCardReader.Create(nil);
  try
    C.Transport := TBareTransport.Create;
    try
      C.ReadMobibPlan([TCalypsoCardReader.SfiRef(0, 31)]);
      Check(False, 'SFI 31 rejected');
    except
      on E: ECalypsoError do Check(True, 'Invalid SFI rejected before I/O');
    end;
    try
      C.ReadMobibPlan([TCalypsoCardReader.FileRef(0, $2001), TCalypsoCardReader.FileRef(0, $2001)]);
      Check(False, 'Duplicate entry rejected');
    except
      on E: ECalypsoError do Check(True, 'Duplicate entry rejected before I/O');
    end;
    try
      C.ApplicationName := 'BAD NAME WITH SEVENTEEN';
      Check(False, 'Long application name rejected');
    except
      on E: ECalypsoError do Check(C.ApplicationName = '', 'Invalid name not stored');
    end;
  finally
    C.Free;
  end;
end;

begin
  try
    TestDecoding;
    TestPlan;
    TestPlans;
    Writeln('Calypso reader: ', Checks, ' assertions passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
