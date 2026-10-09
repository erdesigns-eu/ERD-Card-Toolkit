program CalypsoTests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.TLV, ERD.Card.Transport,
  ERD.Card.Contactless.Calypso;

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
  if not AValue then raise Exception.Create(AMessage);
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
  Check(Position < Length(Steps), 'No unexpected APDU or replay');
  Check(BytesEqual(ACommand, Steps[Position].Command), 'Exact APDU at step ' + IntToStr(Position));
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

function TBareTransport.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Bare transport must not be invoked');
end;



type
 ETestAuthentication = class(Exception);
 TSecureSession = class(TInterfacedObject,ICalypsoSecureReadSession)
  Transport: ICardTransport;
  Finishes,Aborts: Integer;
  FailFinish,FailAbort: Boolean;
  function GetTransport: ICardTransport;
  procedure Finish;
  procedure Abort;
 end;
 TSecureProvider = class(TInterfacedObject,ICalypsoSecureSessionProvider)
  Session: ICalypsoSecureReadSession;
  Opens: Integer;
  function Open(const ATransport: ICardTransport; const ADialect: TCalypsoDialect;
    const ASelectionData: TBytes): ICalypsoSecureReadSession;
 end;
function TSecureSession.GetTransport: ICardTransport;
begin Result := Transport; end;
procedure TSecureSession.Finish;
begin Inc(Finishes); if FailFinish then raise ETestAuthentication.Create('Verification failed'); end;
procedure TSecureSession.Abort;
begin Inc(Aborts); if FailAbort then raise ETestAuthentication.Create('Abort failed'); end;
function TSecureProvider.Open(const ATransport: ICardTransport; const ADialect: TCalypsoDialect;
 const ASelectionData: TBytes): ICalypsoSecureReadSession;
begin
 Inc(Opens); Check(ATransport <> nil,'Provider receives raw exclusive adapter');
 Check(ADialect = cdLegacy94,'Provider receives explicit dialect'); Result := Session;
end;
procedure TestSecureSessions;
var R: TCalypsoCardReader; Raw,Authenticated: TScript; Provider: TSecureProvider;
 ProviderRef: ICalypsoSecureSessionProvider; Session: TSecureSession; SessionRef: ICalypsoSecureReadSession;
 D: TCalypsoFile; Raised: Boolean; I: Integer;
begin
 R := TCalypsoCardReader.Create(nil);
 try
  Raw := TScript.Create; R.Transport := Raw; R.RequireSecureSession := True; Raised := False;
  try D := R.ReadFile($2001,4); except on E: ECalypsoError do Raised := True; end;
  Check(Raised and (Raw.Begins = 0) and (Raw.Position = 0),'Required auth without provider fails before card I/O');
  for I := 0 to 2 do begin
   Raw := TScript.Create; R.Transport := Raw; Authenticated := TScript.Create;
   Session := TSecureSession.Create; SessionRef := Session; Session.Transport := Authenticated;
   Provider := TSecureProvider.Create; ProviderRef := Provider; Provider.Session := SessionRef;
   R.SecureSessionProvider := ProviderRef;
   Authenticated.Add('94A4000002200100','9000');
   Authenticated.Add('94B201041D','CAFEBABE9000',I=2);
   if I <> 2 then Authenticated.Add('94B202041D','6A83');
   Session.FailFinish := I = 1; Session.FailAbort := I = 2;
   Raised := False;
   try D := R.ReadFile($2001,4);
   except
    on E: ETestAuthentication do begin Check(I = 1,'Final auth error preserved'); Raised := True; end;
    on E: ECardTransportError do begin Check(I = 2,'Primary transport error preserved despite abort error'); Raised := True; end;
   end;
   Check((Provider.Opens = 1) and (Raw.Position = 0) and (Raw.Begins = 1) and (Raw.Ends = 1),'One secure session, no raw fallback, exclusive cleanup');
   if I = 0 then begin
    Check(not Raised and (Length(D.Records) = 1) and (BytesToHex(D.Records[0].Data) = 'CAFEBABE'),'Authenticated provider output returned after success');
    Check((Session.Finishes = 1) and (Session.Aborts = 0),'Successful authenticated finish');
   end else Check(Raised and (Session.Aborts = 1),'Failed session aborts and does not publish data');
   R.SecureSessionProvider := nil; ProviderRef := nil; SessionRef := nil;
  end;
  R.RequireSecureSession := False; Raw := TScript.Create; R.Transport := Raw;
  Raw.Add('94A4000002200100','9000'); Raw.Add('94B201041D','6982'); D := R.ReadFile($2001,4);
  Check((Length(D.Records) = 0) and (D.LastRecordStatus = $6982),'Public restricted read never authenticates or fabricates content');
 finally R.Free; end;
end;


procedure TestCallerFilePlans;
var R: TCalypsoCardReader; S,Authenticated: TScript; D: TMobibSnapshot;
 Provider: TSecureProvider; ProviderRef: ICalypsoSecureSessionProvider;
 Session: TSecureSession; SessionRef: ICalypsoSecureReadSession; Raised: Boolean; I: Integer;
begin
 R := TCalypsoCardReader.Create(nil);
 try
  for I := 0 to 2 do begin
   S := TScript.Create; R.Transport := S; Raised := False;
   try case I of
    0: D := R.ReadMobibFiles([],4);
    1: D := R.ReadMobibFiles([$2001,$2001],4);
    2: D := R.ReadMobibFiles([0],4);
   end; except on E: ECalypsoError do Raised := True; end;
   Check(Raised and (S.Begins = 0) and (S.Position = 0),'File plan validated before I/O');
  end;
  S := TScript.Create; R.Transport := S;
  S.Add('94A4000002200000','9000'); S.Add('94A4000002202A00','9000');
  S.Add('94B201041D','0102039000'); S.Add('94B202041D','6A83'); S.Add('94A4000002203000','6A82');
  D := R.ReadMobibFiles([$202A,$2030],4);
  Check((Length(D.Files) = 2) and (D.Files[0].LogicalId = $202A) and
   (BytesToHex(D.Files[0].Records[0].Data) = '010203') and (D.Files[1].SelectionStatus = $6A82),'Additional caller-selected files preserved');
  S := TScript.Create; R.Transport := S; S.Add('94A4000002200000','CAFE9000');
  Authenticated := TScript.Create; Authenticated.Add('94A4000002202A00','9000');
  Authenticated.Add('94B201041D','0102039000'); Authenticated.Add('94B202041D','6A83');
  Session := TSecureSession.Create; SessionRef := Session; Session.Transport := Authenticated;
  Provider := TSecureProvider.Create; ProviderRef := Provider; Provider.Session := SessionRef;
  R.SecureSessionProvider := ProviderRef; R.RequireSecureSession := True;
  D := R.ReadMobibFiles([$202A],4);
  Check((S.Position = 1) and (Authenticated.Position = 3) and (Provider.Opens = 1) and
   (Session.Finishes = 1) and (S.Ends = 1),'MOBIB plan authenticates once after directory selection, with no raw fallback');
 finally R.Free; end;
end;

procedure TestFiles;
var R: TCalypsoCardReader; S: TScript; D: TCalypsoFile; Raised: Boolean; I: Integer;
begin
 R := TCalypsoCardReader.Create(nil);
 try
  Check((R.RecordBytes = 29) and R.UseTransactions and (R.Dialect = cdLegacy94),'Inactive defaults');
  S := TScript.Create; R.Transport := S;
  S.Add('94A4000002200100','01029000'); S.Add('94B201041D','6C02');
  S.Add('94B2010402','AABB9000'); S.Add('94B202041D','6A83');
  D := R.ReadFile($2001,4);
  Check((S.Position = 4) and (S.Begins = 1) and (S.Ends = 1),'Exact Calypso LFI/read sequence');
  Check((Length(D.Records) = 1) and (BytesToHex(D.Records[0].Data) = 'AABB') and
   (D.LastRecordStatus = $6A83) and not D.Truncated,'Length correction/owned record/end');
  for I := 0 to 2 do begin
   S := TScript.Create; R.Transport := S; R.Dialect := cdIso00;
   case I of
    0: S.Add('00A4090002200100','6A82');
    1: S.Add('00A4090002200100','6982');
    2: begin S.Add('00A4090002200100','9000'); S.Add('00B201041D','6985'); end;
   end;
   D := R.ReadFile($2001,4);
   Check((Length(D.Records) = 0) and not D.Truncated and (S.Ends = 1),'Absent/restricted files do not authenticate');
  end;
  S := TScript.Create; R.Transport := S;
  S.Add('00A4090002200100','9000'); S.Add('00B201041D','FF9000'); D := R.ReadFile($2001,1);
  Check(D.Truncated and (Length(D.Records) = 1),'Bound is explicit, not full-read claim');
  S := TScript.Create; R.Transport := S;
  S.Add('00A4090002200100','6102'); S.Add('00C0000002','12349000'); S.Add('00B201041D','6A83');
  D := R.ReadFile($2001,4); Check(BytesToHex(D.SelectionData) = '1234','Bounded SELECT GET RESPONSE');
  for I := 0 to 2 do begin
   S := TScript.Create; R.Transport := S; Raised := False;
   try
    case I of 0: D := R.ReadFile(0,4); 1: D := R.ReadFile($2001,0); 2: R.RecordBytes := 257; end;
   except on E: ECalypsoError do Raised := True; end;
   Check(Raised and (S.Position = 0) and (S.Begins = 0),'Invalid Calypso input before I/O');
  end;
  S := TScript.Create; R.Transport := S;
  S.Add('00A4090002200100','9000'); S.Add('00B201041D','6F00'); Raised := False;
  S.EndFails := True;
  try D := R.ReadFile($2001,4); except on E: ECalypsoError do Raised := True; end;
  Check(Raised and (S.Ends = 1) and (S.Position = 2),'Primary error preserved after release failure');
 finally R.Free; end;
end;
procedure TestMobib;
const Ids: array[0..7] of Word = ($2001,$2002,$2010,$2020,$2069,$2050,$2040,$3F1C);
var R: TCalypsoCardReader; S: TScript; D: TMobibSnapshot; I: Integer;
begin
 R := TCalypsoCardReader.Create(nil);
 try
  S := TScript.Create; R.Transport := S; S.Add('94A4000002200000','CAFE9000');
  for I := 0 to High(Ids) do begin
   S.Add('94A4000002'+IntToHex(Ids[I],4)+'00','9000');
   S.Add('94B201041D','01029000'); S.Add('94B202041D','6A83');
  end;
  D := R.ReadMobib(4);
  Check((S.Position = 25) and (S.Begins = 1) and (S.Ends = 1),'One complete MOBIB file-plan transaction');
  Check((BytesToHex(D.TicketingSelection) = 'CAFE') and (Length(D.Files) = 8),'Ticketing selection/files retained');
  for I := 0 to High(Ids) do Check((D.Files[I].LogicalId = Ids[I]) and
   (Length(D.Files[I].Records) = 1) and not D.Files[I].Truncated,'All MOBIB raw files read');
 finally R.Free; end;
end;
begin
 try TestCallerFilePlans; TestSecureSessions; TestFiles; TestMobib; Writeln('PASS: ',Checks,' Calypso/MOBIB read assertions.');
 except on E: Exception do begin Writeln('FAIL: ',E.ClassName,': ',E.Message); Halt(1); end; end;
end.
