program CardTransportTests;

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
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes, System.SyncObjs,
{$ENDIF}
  ERD.Card.Bytes,
  ERD.Card.Transport,
  ERD.Card.PCSC.Api,
  ERD.Card.PCSC.Windows,
  ERD.Card.PCSC.Reader;

type
{$IFDEF FPC}
  TTestCriticalSection = TRTLCriticalSection;
{$ELSE}
  TTestCriticalSection = TCriticalSection;
{$ENDIF}
  TFakeApi = class(TInterfacedObject, IPcscApi)
  private
    FLock: TTestCriticalSection;
    FContextCount: Integer;
    FCancelled: array[0..31] of Boolean;
    FWaitCalls: Integer;
    FWaitError: Cardinal;
    FState: Cardinal;
    FStateAtr: TBytes;
    FInFlight: Integer;
    procedure Enter;
    procedure Leave;
  public
    Base: TPcscHandle;
    EstablishCount: Integer;
    ReleaseCount: Integer;
    ConnectCount: Integer;
    DisconnectCount: Integer;
    TransmitCount: Integer;
    CancelCount: Integer;
    BeginCount: Integer;
    EndCount: Integer;
    MaxInFlight: Integer;
    EstablishResult: Cardinal;
    ConnectResult: Cardinal;
    ListResult: Cardinal;
    TransmitResult: Cardinal;
    DisconnectResult: Cardinal;
    ReleaseResult: Cardinal;
    BeginResult: Cardinal;
    EndResult: Cardinal;
    AtrResult: Cardinal;
    ActiveProtocol: Cardinal;
    Response: TBytes;
    LastCommand: TBytes;
    LastProtocol: Cardinal;
    LastCapacity: Integer;
    LastName: UnicodeString;
    LastShare: TPcscShareMode;
    LastAllowedProtocols: Cardinal;
    LastDisposition: TPcscDisposition;
    LastConnectContext: TPcscHandle;
    LastWaitContext: TPcscHandle;
    LastCancelContext: TPcscHandle;
    TransmitDelay: Integer;
    DropCancellation: Boolean;
    Trace: string;
    constructor Create;
    destructor Destroy; override;
    procedure ChangeState(const AState: Cardinal; const AAtr: TBytes);
    procedure FailWait(const AError: Cardinal);
    function WaitCalls: Integer;
    function Establish(out AContext: TPcscHandle): Cardinal;
    function Release(const AContext: TPcscHandle): Cardinal;
    function ListReaders(const AContext: TPcscHandle; out ANames: TPcscReaderNames): Cardinal;
    function Connect(const AContext: TPcscHandle; const AReaderName: UnicodeString;
      const AShareMode: TPcscShareMode; const AProtocols: Cardinal;
      out ACard: TPcscHandle; out AActiveProtocol: Cardinal): Cardinal;
    function Disconnect(const ACard: TPcscHandle; const ADisposition: TPcscDisposition): Cardinal;
    function BeginTransaction(const ACard: TPcscHandle): Cardinal;
    function EndTransaction(const ACard: TPcscHandle; const ADisposition: TPcscDisposition): Cardinal;
    function Transmit(const ACard: TPcscHandle; const AProtocol: Cardinal;
      const ACommand: TBytes; const AMaxResponseBytes: Integer; out AResponse: TBytes): Cardinal;
    function ReadAtr(const ACard: TPcscHandle; out AAtr: TBytes): Cardinal;
    function WaitStatus(const AContext: TPcscHandle; const AReaderName: UnicodeString;
      const ACurrentState: Cardinal; const ATimeoutMs: Cardinal;
      out ASnapshot: TPcscReaderSnapshot): Cardinal;
    function Cancel(const AContext: TPcscHandle): Cardinal;
  end;
  TExchangeThread = class(TThread)
  private
    FTransport: ICardTransport;
  protected
    procedure Execute; override;
  public
    Rejected: Boolean;
    Failure: string;
    constructor Create(const ATransport: ICardTransport);
  end;
  TListener = class
  public
    Calls: Integer;
    ThreadId: NativeUInt;
    Snapshot: TPcscReaderSnapshot;
    StopReader: TSmartCardReader;
    procedure Changed(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
  end;

var
  Checks: Integer = 0;
  DestroyedApis: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not ACondition then raise Exception.Create(AMessage);
end;

constructor TFakeApi.Create;
begin
  inherited Create;
{$IFDEF FPC}
  InitCriticalSection(FLock);
{$ELSE}
  FLock := TTestCriticalSection.Create;
{$ENDIF}
  if SizeOf(TPcscHandle) = 8 then Base := TPcscHandle(UInt64(High(Cardinal)) + 1)
  else Base := 1000;
  ActiveProtocol := PcscProtocolT1;
  Response := HexToBytes('9000');
  FState := PcscStateEmpty;
end;

destructor TFakeApi.Destroy;
begin
{$IFDEF FPC}
  DoneCriticalSection(FLock);
{$ELSE}
  FLock.Free;
{$ENDIF}
  Inc(DestroyedApis);
  inherited Destroy;
end;

procedure TFakeApi.Enter;
begin
{$IFDEF FPC}
  EnterCriticalSection(FLock);
{$ELSE}
  FLock.Enter;
{$ENDIF}
end;

procedure TFakeApi.Leave;
begin
{$IFDEF FPC}
  LeaveCriticalSection(FLock);
{$ELSE}
  FLock.Leave;
{$ENDIF}
end;

function TFakeApi.Establish(out AContext: TPcscHandle): Cardinal;
begin
  Enter;
  try
    AContext := 0;
    Inc(EstablishCount);
    Trace := Trace + 'establish;';
    Result := EstablishResult;
    if Result <> PcscSuccess then Exit;
    Inc(FContextCount);
    if FContextCount > High(FCancelled) then raise Exception.Create('Fake context capacity');
    AContext := Base + TPcscHandle(FContextCount);
  finally
    Leave;
  end;
end;

function TFakeApi.Release(const AContext: TPcscHandle): Cardinal;
begin
  Enter;
  try
    Inc(ReleaseCount);
    Trace := Trace + 'release;';
    Result := ReleaseResult;
  finally
    Leave;
  end;
end;

function TFakeApi.ListReaders(const AContext: TPcscHandle; out ANames: TPcscReaderNames): Cardinal;
begin
  ANames := nil;
  Result := ListResult;
  if Result <> PcscSuccess then Exit;
  SetLength(ANames, 2);
  ANames[0] := 'Reader A';
  ANames[1] := 'Reader ' + UnicodeString(WideChar($00E9));
end;

function TFakeApi.Connect(const AContext: TPcscHandle;
  const AReaderName: UnicodeString; const AShareMode: TPcscShareMode;
  const AProtocols: Cardinal; out ACard: TPcscHandle; out AActiveProtocol: Cardinal): Cardinal;
begin
  ACard := 0;
  AActiveProtocol := 0;
  Inc(ConnectCount);
  Trace := Trace + 'connect;';
  LastName := AReaderName;
  LastShare := AShareMode;
  LastAllowedProtocols := AProtocols;
  LastConnectContext := AContext;
  Result := ConnectResult;
  if Result <> PcscSuccess then Exit;
  ACard := Base + $100 + TPcscHandle(ConnectCount);
  AActiveProtocol := ActiveProtocol;
end;

function TFakeApi.Disconnect(const ACard: TPcscHandle;
  const ADisposition: TPcscDisposition): Cardinal;
begin
  Enter;
  try
    Inc(DisconnectCount);
    Trace := Trace + 'disconnect;';
    LastDisposition := ADisposition;
    Result := DisconnectResult;
  finally
    Leave;
  end;
end;

function TFakeApi.BeginTransaction(const ACard: TPcscHandle): Cardinal;
begin
  Inc(BeginCount);
  Result := BeginResult;
end;

function TFakeApi.EndTransaction(const ACard: TPcscHandle;
  const ADisposition: TPcscDisposition): Cardinal;
begin
  Inc(EndCount);
  LastDisposition := ADisposition;
  Result := EndResult;
end;

function TFakeApi.Transmit(const ACard: TPcscHandle; const AProtocol: Cardinal;
  const ACommand: TBytes; const AMaxResponseBytes: Integer; out AResponse: TBytes): Cardinal;
begin
  AResponse := nil;
  Enter;
  try
    Inc(TransmitCount);
    Inc(FInFlight);
    if FInFlight > MaxInFlight then MaxInFlight := FInFlight;
    LastCommand := ACommand;
    LastProtocol := AProtocol;
    LastCapacity := AMaxResponseBytes;
  finally
    Leave;
  end;
  try
    if TransmitDelay > 0 then Sleep(TransmitDelay);
    Result := TransmitResult;
    // Deliberately return an aliased buffer to test the session's boundary copy.
    if Result = PcscSuccess then AResponse := Response;
  finally
    Enter;
    try
      Dec(FInFlight);
    finally
      Leave;
    end;
  end;
end;

function TFakeApi.ReadAtr(const ACard: TPcscHandle; out AAtr: TBytes): Cardinal;
begin
  AAtr := nil;
  Result := AtrResult;
  if Result = PcscSuccess then AAtr := HexToBytes('3B800181');
end;

procedure TFakeApi.ChangeState(const AState: Cardinal; const AAtr: TBytes);
begin
  Enter;
  try
    FState := ((FState and $FFFF0000) + $10000) or AState;
    FStateAtr := CopyBytes(AAtr);
  finally
    Leave;
  end;
end;

procedure TFakeApi.FailWait(const AError: Cardinal);
begin
  Enter;
  try
    FWaitError := AError;
  finally
    Leave;
  end;
end;

function TFakeApi.WaitCalls: Integer;
begin
  Enter;
  try
    Result := FWaitCalls;
  finally
    Leave;
  end;
end;

function TFakeApi.WaitStatus(const AContext: TPcscHandle;
  const AReaderName: UnicodeString; const ACurrentState: Cardinal;
  const ATimeoutMs: Cardinal; out ASnapshot: TPcscReaderSnapshot): Cardinal;
var
  I: Integer;
  Index: Integer;
begin
  ASnapshot := Default(TPcscReaderSnapshot);
  Index := Integer(AContext - Base);
  Enter;
  try
    LastWaitContext := AContext;
    Inc(FWaitCalls);
  finally
    Leave;
  end;
  for I := 0 to Integer(ATimeoutMs) do
  begin
    Enter;
    try
      if FCancelled[Index] then
      begin
        FCancelled[Index] := False;
        Exit(PcscCancelled);
      end;
      if FWaitError <> PcscSuccess then Exit(FWaitError);
      if ACurrentState <> FState then
      begin
        ASnapshot.ReaderName := AReaderName;
        ASnapshot.State := FState or PcscStateChanged;
        ASnapshot.Atr := CopyBytes(FStateAtr);
        Exit(PcscSuccess);
      end;
    finally
      Leave;
    end;
    if I < Integer(ATimeoutMs) then Sleep(1);
  end;
  Result := PcscTimeout;
end;

function TFakeApi.Cancel(const AContext: TPcscHandle): Cardinal;
begin
  Enter;
  try
    Inc(CancelCount);
    LastCancelContext := AContext;
    if not DropCancellation then FCancelled[Integer(AContext - Base)] := True;
    Result := PcscSuccess;
  finally
    Leave;
  end;
end;

constructor TExchangeThread.Create(const ATransport: ICardTransport);
begin
  inherited Create(True);
  FTransport := ATransport;
end;

procedure TExchangeThread.Execute;
var
  Response: TBytes;
begin
  try
    Response := FTransport.Exchange(HexToBytes('00A4000000'));
    if BytesToHex(Response) <> '9000' then Failure := 'Unexpected response';
  except
    on E: ECardTransportError do Rejected := True;
    on E: Exception do Failure := E.ClassName;
  end;
end;

procedure TListener.Changed(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
begin
  Inc(Calls);
  ThreadId := NativeUInt(TThread.CurrentThread.ThreadID);
  Snapshot := ASnapshot;
  Snapshot.Atr := CopyBytes(ASnapshot.Atr);
  if StopReader <> nil then StopReader.StopMonitoring;
end;

procedure AwaitWaits(const AApi: TFakeApi; const ACount: Integer);
var
  I: Integer;
begin
  for I := 1 to 3000 do
  begin
    if AApi.WaitCalls >= ACount then Exit;
    Sleep(1);
  end;
  raise Exception.Create('Monitor did not reach its next wait');
end;

function AwaitSnapshot(const AReader: TSmartCardReader): TPcscReaderSnapshot;
var
  I: Integer;
begin
  for I := 1 to 3000 do
  begin
    if AReader.PollChanges(Result) then Exit;
    Sleep(1);
  end;
  raise Exception.Create('Monitor did not publish a snapshot');
end;

procedure TestConnection;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  Reader: TSmartCardReader;
  Names: TPcscReaderNames;
  Transport: ICardTransport;
  Command: TBytes;
  Response: TBytes;
  Raised: Boolean;
  DestroyedBefore: Integer;
begin
  Fake := TFakeApi.Create;
  Api := Fake;
  Reader := TSmartCardReader.CreateWithApi(nil, Api);
  try
    Check(Fake.EstablishCount = 0, 'Constructor never opens hardware');
    Check(not Reader.Connected and not Reader.Monitoring and (Reader.Protocol = pcpNone), 'Inactive defaults');
    Check((Reader.ShareMode = psmShared) and (Reader.Protocols = 3) and
      (Reader.MaxResponseBytes = CardMaxResponseBytes), 'Configuration defaults');
    Names := Reader.ListReaders;
    Check(Length(Names) = 2, 'Discovery');
    Reader.ReaderName := Names[1];
    Reader.Connect;
    Check(Reader.Connected and (Reader.Protocol = pcpT1), 'Negotiated T=1');
    Check(Fake.LastName = Names[1], 'Unicode reader identity preserved');
    Check((Fake.LastShare = psmShared) and (Fake.LastAllowedProtocols = 3), 'Connection policies');
    Check(Fake.LastConnectContext > Fake.Base, 'Pointer-sized context round-trips');
    if SizeOf(TPcscHandle) = 8 then Check(Fake.LastConnectContext > High(Cardinal), 'High handle bits preserved');
    Check(BytesToHex(Reader.ReadAtr) = '3B800181', 'Independent raw ATR');
    Command := HexToBytes('00A4000000');
    Transport := Reader.Transport;
    Response := Transport.Exchange(Command);
    Check(BytesToHex(Response) = '9000', 'Complete response status');
    Check((Fake.LastProtocol = 2) and (Fake.LastCapacity = CardMaxResponseBytes), 'PCI and capacity');
    Response[0] := 0;
    Fake.LastCommand[0] := $FF;
    Check((Fake.Response[0] = $90) and (Command[0] = 0), 'Independent boundary buffers');
    Raised := False;
    try Reader.ReaderName := 'Other'; except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Reader.ReaderName = Names[1]), 'Connected name cannot change');
    Reader.Disconnect(pcdReset);
    Check(not Reader.Connected and (Reader.Protocol = pcpNone), 'Disconnected state');
    Check((Fake.DisconnectCount = 1) and (Fake.ReleaseCount = 1) and
      (Fake.LastDisposition = pcdReset), 'Explicit close disposition and cleanup');
    Reader.Disconnect;
    Check(Fake.DisconnectCount = 1, 'Repeated close is idempotent');
    Reader.Protocols := 1;
    Reader.ShareMode := psmExclusive;
    Fake.ActiveProtocol := 1;
    Reader.Connect;
    Check((Reader.Protocol = pcpT0) and (Fake.LastShare = psmExclusive), 'T=0 and exclusive policy');
  finally
    Reader.Free;
  end;
  Raised := False;
  try Response := Transport.Exchange(Command); except on E: ECardTransportError do Raised := True; end;
  Check(Raised, 'Retained transport is valid but disconnected after component free');
  DestroyedBefore := DestroyedApis;
  Api := nil;
  Check(DestroyedApis = DestroyedBefore, 'Transport retains its adapter');
  Transport := nil;
  Check(DestroyedApis = DestroyedBefore + 1, 'Final interface releases session and adapter');
end;

procedure TestFailures;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  Reader: TSmartCardReader;
  Raised: Boolean;
  Response: TBytes;
  Names: TPcscReaderNames;
  I: Integer;
begin
  Raised := False;
  try Reader := TSmartCardReader.CreateWithApi(nil, nil); Reader.Free;
  except on E: ECardTransportError do Raised := True; end;
  Check(Raised, 'Nil adapter rejected without leaking component');
  Fake := TFakeApi.Create;
  Api := Fake;
  Reader := TSmartCardReader.CreateWithApi(nil, Api);
  try
    for I := 0 to 5 do
    begin
      Raised := False;
      try
        case I of
          0: Reader.Connect;
          1: Reader.ReaderName := 'Bad'#0'Name';
          2: Reader.Protocols := 0;
          3: Reader.Protocols := 4;
          4: Reader.MaxResponseBytes := 1;
          5: Reader.MaxResponseBytes := CardMaxResponseBytes + 1;
        end;
      except on E: ECardTransportError do Raised := True; end;
      Check(Raised, 'Invalid configuration rejected');
    end;
    Check(Fake.EstablishCount = 0, 'Invalid configuration never establishes a context');
    Reader.ReaderName := 'Reader A';
    Fake.EstablishResult := $8010001D;
    Raised := False;
    try Reader.Connect;
    except on E: EPcscError do begin
      Raised := True;
      Check((E.StatusCode = $8010001D) and (E.Operation = 'EstablishContext'), 'Original unsigned error code');
    end; end;
    Check(Raised and not Reader.Connected, 'Establish failure');
    Fake.EstablishResult := 0;
    Fake.ConnectResult := $8010000C;
    Raised := False;
    try Reader.Connect; except on E: EPcscError do Raised := True; end;
    Check(Raised and (Fake.ReleaseCount = 1) and (Fake.DisconnectCount = 0), 'Failed connect rolls back context');
    Fake.ConnectResult := 0;
    Fake.ActiveProtocol := 4;
    Raised := False;
    try Reader.Connect; except on E: EPcscError do Raised := True; end;
    Check(Raised and (Fake.DisconnectCount = 1) and not Reader.Connected, 'Invalid negotiated protocol closes native handle');
    Fake.ActiveProtocol := 2;
    Reader.Connect;
    Fake.TransmitResult := PcscInsufficientBuffer;
    Raised := False;
    try Response := Reader.Transport.Exchange(HexToBytes('00A4000000'));
    except on E: EPcscError do begin
      Raised := True;
      Check((E.StatusCode = PcscInsufficientBuffer) and (Pos('00A4', E.Message) = 0), 'Transmit error excludes command bytes');
    end; end;
    Check(Raised and not Reader.Connected and (Fake.TransmitCount = 1), 'Failed transmit closes connection without resend');
    Fake.TransmitResult := 0;
    for I := 0 to 1 do
    begin
      Reader.MaxResponseBytes := 2;
      Reader.Connect;
      if I = 0 then Fake.Response := HexToBytes('90') else Fake.Response := HexToBytes('009000');
      Raised := False;
      try Response := Reader.Transport.Exchange(HexToBytes('00A4000000'));
      except on E: ECardTransportError do Raised := True; end;
      Check(Raised and not Reader.Connected, 'Malformed receive framing closes connection');
    end;
    Fake.Response := HexToBytes('9000');
    Reader.Connect;
    Fake.DisconnectResult := $80100003;
    Fake.ReleaseResult := $80100001;
    Raised := False;
    try Reader.Disconnect;
    except on E: EPcscError do begin Raised := True;
      Check(E.StatusCode = $80100003, 'First cleanup failure preserved');
    end; end;
    Check(Raised and not Reader.Connected and (Pos('disconnect;release;', Fake.Trace) <> 0), 'Release still follows failed disconnect');
    Fake.DisconnectResult := 0;
    Fake.ReleaseResult := 0;
    Fake.ListResult := PcscNoReaders;
    Names := Reader.ListReaders;
    Check(Length(Names) = 0, 'No readers is an empty discovery result');
  finally
    Reader.Free;
    Api := nil;
  end;
end;

procedure TestTransactionsAndThreads;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  Reader: TSmartCardReader;
  First: TExchangeThread;
  Second: TExchangeThread;
  Raised: Boolean;
begin
  Fake := TFakeApi.Create;
  Api := Fake;
  Reader := TSmartCardReader.CreateWithApi(nil, Api);
  try
    Reader.ReaderName := 'Reader A';
    Reader.Connect;
    Reader.BeginTransaction;
    Check(Fake.BeginCount = 1, 'Native begin transaction');
    Raised := False;
    try Reader.BeginTransaction; except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Fake.BeginCount = 1), 'Nested transaction rejected before native call');
    First := TExchangeThread.Create(Reader.Transport);
    try
      First.Start;
      First.WaitFor;
      Check(First.Rejected and (First.Failure = '') and (Fake.TransmitCount = 0), 'Another thread cannot enter an owned transaction');
    finally
      First.Free;
    end;
    Reader.EndTransaction(pcdLeave);
    Check((Fake.EndCount = 1) and Reader.Connected, 'End leaves connection open');
    Raised := False;
    try Reader.EndTransaction; except on E: ECardTransportError do Raised := True; end;
    Check(Raised and (Fake.EndCount = 1), 'End without transaction rejected');
    Fake.TransmitDelay := 15;
    First := TExchangeThread.Create(Reader.Transport);
    Second := TExchangeThread.Create(Reader.Transport);
    try
      First.Start;
      Second.Start;
      First.WaitFor;
      Second.WaitFor;
      Check(not First.Rejected and not Second.Rejected and
        (First.Failure = '') and (Second.Failure = ''), 'Concurrent exchanges both complete');
      Check((Fake.MaxInFlight = 1) and (Fake.TransmitCount = 2), 'Native exchanges are serialized per session');
    finally
      First.Free;
      Second.Free;
    end;
    Reader.BeginTransaction;
    Fake.EndResult := $80100016;
    Raised := False;
    try Reader.EndTransaction; except on E: EPcscError do Raised := True; end;
    Check(Raised and not Reader.Connected, 'Failed end closes ambiguous connection');
  finally
    Reader.Free;
    Api := nil;
  end;
end;

procedure TestMonitoring;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  Reader: TSmartCardReader;
  Listener: TListener;
  Snapshot: TPcscReaderSnapshot;
  Response: TBytes;
  Raised: Boolean;
  I: Integer;
  NextWait: Integer;
begin
  Fake := TFakeApi.Create;
  Api := Fake;
  Reader := TSmartCardReader.CreateWithApi(nil, Api);
  Listener := TListener.Create;
  try
    Reader.ReaderName := 'Reader A';
    Reader.OnCardStateChange := Listener.Changed;
    Reader.Connect;
    Reader.StartMonitoring;
    AwaitWaits(Fake, 2);
    Check(Reader.Monitoring and Reader.Connected, 'Monitor does not replace connection');
    Check(Fake.LastWaitContext <> Fake.LastConnectContext, 'Separate monitoring context');
    Check(Listener.Calls = 0, 'Worker never invokes caller handlers');
    Check(Reader.PollChanges(Snapshot), 'Initial observation');
    Check((Snapshot.State = PcscStateEmpty) and (Snapshot.ReaderName = 'Reader A'), 'Normalized initial state');
    Check((Listener.Calls = 1) and (Listener.ThreadId = NativeUInt(TThread.CurrentThread.ThreadID)), 'Event dispatched on poll caller thread');
    Check(not Reader.PollChanges(Snapshot) and (Length(Snapshot.Atr) = 0), 'Empty poll clears output');
    Fake.ChangeState(PcscStatePresent, HexToBytes('3B00'));
    Snapshot := AwaitSnapshot(Reader);
    Check((Snapshot.State and PcscStatePresent) <> 0, 'Card insertion observed');
    Check(((Snapshot.State and PcscStatePresent) <> 0) and
      ((Snapshot.State and PcscStateChanged) = 0) and
      (BytesToHex(Snapshot.Atr) = '3B00'), 'ATR copied and Changed flag cleared');
    Snapshot.Atr[0] := 0;
    Check(Listener.Snapshot.Atr[0] = $3B, 'Consumer snapshots do not share buffers');
    Raised := False;
    try Reader.ReaderName := 'Other'; except on E: ECardTransportError do Raised := True; end;
    Check(Raised, 'Active monitor pins reader identity');
    Reader.StopMonitoring;
    Check(not Reader.Monitoring and Reader.Connected, 'Stopping monitor leaves card connection open');
    Check((Fake.CancelCount = 1) and (Fake.LastCancelContext = Fake.LastWaitContext), 'Only monitor context cancelled');
    Response := Reader.Transport.Exchange(HexToBytes('00A4000000'));
    Check(BytesToHex(Response) = '9000', 'Connection works after watcher join');
    Reader.StopMonitoring;
    Check(Fake.CancelCount = 1, 'Repeated monitor stop is idempotent');
    // A handler can stop monitoring synchronously without joining itself.
    Listener.StopReader := Reader;
    NextWait := Fake.WaitCalls + 2;
    Reader.StartMonitoring;
    AwaitWaits(Fake, NextWait);
    Check(Reader.PollChanges(Snapshot) and not Reader.Monitoring, 'Handler can stop monitor on caller thread');
    Listener.StopReader := nil;
    Reader.StartMonitoring;
    Fake.FailWait($8010001D);
    Raised := False;
    for I := 1 to 3000 do
    begin
      try Reader.PollChanges(Snapshot);
      except on E: EPcscError do begin
        Raised := True;
        Check((E.StatusCode = $8010001D) and (E.Operation = 'MonitorReader'), 'Worker error marshalled without card data');
      end; end;
      if Raised then Break;
      Sleep(1);
    end;
    Check(Raised and not Reader.Monitoring and Reader.Connected, 'Monitor error joins worker and preserves connection');
  finally
    Reader.Free;
    Listener.Free;
    Api := nil;
  end;
end;

procedure TestIsolationAndBounds;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  First: TSmartCardReader;
  Second: TSmartCardReader;
  Command: TBytes;
  Response: TBytes;
  Raised: Boolean;
  Before: Integer;
  I: Integer;
begin
  Fake := TFakeApi.Create;
  Api := Fake;
  First := TSmartCardReader.CreateWithApi(nil, Api);
  Second := TSmartCardReader.CreateWithApi(nil, Api);
  try
    First.ReaderName := 'Reader A';
    Second.ReaderName := 'Reader B';
    First.Connect;
    Second.Connect;
    Check(Fake.EstablishCount = 2, 'Instances establish independent contexts');
    First.Disconnect;
    Response := Second.Transport.Exchange(HexToBytes('00A4000000'));
    Check(Second.Connected and (BytesToHex(Response) = '9000'), 'Closing one reader preserves the other');
    Before := Fake.TransmitCount;
    for I := 0 to 1 do
    begin
      if I = 0 then Command := nil else SetLength(Command, CardMaxCommandBytes + 1);
      Raised := False;
      try Response := Second.Transport.Exchange(Command);
      except on E: ECardTransportError do Raised := True; end;
      Check(Raised and Second.Connected, 'Invalid command rejected without closing healthy connection');
    end;
    Check(Fake.TransmitCount = Before, 'Invalid command never reaches native API');
    SetLength(Command, CardMaxCommandBytes);
    Response := Second.Transport.Exchange(Command);
    Check((Length(Fake.LastCommand) = CardMaxCommandBytes) and (Length(Response) = 2), 'Maximum command capacity');
    SetLength(Fake.Response, CardMaxResponseBytes);
    Response := Second.Transport.Exchange(HexToBytes('00A4000000'));
    Check(Length(Response) = CardMaxResponseBytes, 'Maximum response capacity');
    for I := 0 to 1 do
    begin
      if I = 0 then Fake.Response := HexToBytes('6101') else Fake.Response := HexToBytes('6C10');
      Before := Fake.TransmitCount;
      Response := Second.Transport.Exchange(HexToBytes('00A4000000'));
      Check(BytesEqual(Response, Fake.Response) and (Fake.TransmitCount = Before + 1),
        '61xx/6Cxx statuses are returned without follow-up commands');
    end;
    Fake.BeginResult := $8010000B;
    Raised := False;
    try Second.BeginTransaction; except on E: EPcscError do Raised := True; end;
    Check(Raised and Second.Connected, 'Failed transaction acquisition keeps local connection');
    Fake.BeginResult := 0;
    Second.BeginTransaction;
    Second.EndTransaction;
    Check(Fake.EndCount = 1, 'Failed acquisition did not mark a transaction active');
    Second.Disconnect;
    Raised := False;
    try Second.BeginTransaction; except on E: ECardTransportError do Raised := True; end;
    Check(Raised, 'Disconnected transaction is rejected');
    Raised := False;
    try Response := Second.ReadAtr; except on E: ECardTransportError do Raised := True; end;
    Check(Raised, 'Disconnected ATR read is rejected');
    Fake.EstablishResult := $8010001D;
    Raised := False;
    try First.StartMonitoring; except on E: EPcscError do Raised := True; end;
    Check(Raised and not First.Monitoring, 'Failed monitor establishment has no worker');
  finally
    First.Free;
    Second.Free;
    Api := nil;
  end;
end;

procedure TestPlatformBoundary;
var
  Api: IPcscApi;
  Context: TPcscHandle;
begin
  Api := CreateSystemPcscApi;
  Check(Api <> nil, 'System adapter can be constructed without hardware');
{$IFNDEF MSWINDOWS}
  Check((Api.Establish(Context) = PcscUnsupportedFeature) and (Context = 0), 'Non-Windows native access fails explicitly');
{$ENDIF}
end;

procedure TestMonitorDestruction;
var
  Fake: TFakeApi;
  Api: IPcscApi;
  Reader: TSmartCardReader;
  Listener: TListener;
begin
  Fake := TFakeApi.Create;
  Api := Fake;
  Fake.DropCancellation := True; // Simulate a cancellation that misses the pending wait.
  Listener := TListener.Create;
  Reader := TSmartCardReader.CreateWithApi(nil, Api);
  try
    Reader.ReaderName := 'Reader A';
    Reader.OnCardStateChange := Listener.Changed;
    Reader.StartMonitoring;
    AwaitWaits(Fake, 2);
    Check(not Reader.Connected, 'Monitoring does not implicitly connect');
    Reader.Free;
    Reader := nil;
    Check((Fake.CancelCount = 1) and (Fake.ReleaseCount = 1), 'Destructor joins after a missed cancellation and releases the context');
    Check(Listener.Calls = 0, 'Destruction does not dispatch pending callbacks');
  finally
    Reader.Free;
    Listener.Free;
    Api := nil;
  end;
end;

begin
  try
    TestConnection;
    TestFailures;
    TestTransactionsAndThreads;
    TestMonitoring;
    TestIsolationAndBounds;
    TestMonitorDestruction;
    TestPlatformBoundary;
    Writeln('PASS: ', Checks, ' assertions across 7 transport test groups.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
