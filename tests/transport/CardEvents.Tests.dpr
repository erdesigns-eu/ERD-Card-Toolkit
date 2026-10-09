program CardEventsTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
uses
{$IFDEF UNIX}cthreads,{$ENDIF}
{$IFDEF FPC}Classes,SysUtils,{$ELSE}System.Classes,System.SysUtils,System.SyncObjs,{$ENDIF}
 ERD.Card.Events,ERD.Card.Bytes,ERD.Card.PCSC.Api,ERD.Card.PCSC.Monitor,ERD.Card.PCSC.Reader,
 ERD.Card.HID,ERD.Card.HID.Monitor;
var Checks:Integer=0;
procedure Check(B:Boolean;const S:string);
begin Inc(Checks);if not B then raise Exception.Create(S);end;
type
{$IFDEF FPC}
 TMockLock=TRTLCriticalSection;
{$ELSE}
 TMockLock=TCriticalSection;
{$ENDIF}
 TMockPcsc=class(TInterfacedObject,IPcscApi,IPcscMonitorApi)
  Lock:TMockLock;Step,Version,Listed,Waited,ReleaseCount,Cancelled,Connected:Integer;
  ErrorCode:Cardinal;BadSnapshot,BadInventory:Boolean;
  constructor Create;destructor Destroy;override;
  procedure Enter;procedure Leave;
  procedure SetStep(const N:Integer);
  function Establish(out C:TPcscHandle):Cardinal;
  function Release(const C:TPcscHandle):Cardinal;
  function ListReaders(const C:TPcscHandle;out N:TPcscReaderNames):Cardinal;
  function Connect(const C:TPcscHandle;const N:UnicodeString;const S:TPcscShareMode;const P:Cardinal;out H:TPcscHandle;out A:Cardinal):Cardinal;
  function Disconnect(const C:TPcscHandle;const D:TPcscDisposition):Cardinal;
  function BeginTransaction(const C:TPcscHandle):Cardinal;
  function EndTransaction(const C:TPcscHandle;const D:TPcscDisposition):Cardinal;
  function Transmit(const C:TPcscHandle;const P:Cardinal;const B:TBytes;const Max:Integer;out R:TBytes):Cardinal;
  function ReadAtr(const C:TPcscHandle;out B:TBytes):Cardinal;
  function WaitStatus(const C:TPcscHandle;const N:UnicodeString;const S,T:Cardinal;out R:TPcscReaderSnapshot):Cardinal;
  function WaitReaders(const C:TPcscHandle;const A:TPcscReaderSnapshots;const T:Cardinal;out R:TPcscReaderSnapshots):Cardinal;
  function Cancel(const C:TPcscHandle):Cardinal;
 end;
 TNotifications=class(TInterfacedObject,IHidDeviceNotifications)
  H:THidNotification;Started,Stopped:Integer;FailStart:Boolean;
  procedure Start(const AHandler:THidNotification);procedure Stop;
  procedure Emit(const Path:UnicodeString;Added:Boolean);
 end;
 TReportDevice=class(TInterfacedObject,IHidReportDevice)
  Opened,Closed,Reads:Integer;Bad:Boolean;
  function Open(const W:Boolean):THidDeviceInfo;
  procedure Close;
  function Receive(const K:THidReportKind;const ID:Byte;const T:Cardinal):TBytes;
  procedure Send(const K:THidReportKind;const B:TBytes;const T:Cardinal);
 end;
 TRecorder=class
  Log:TStringList;M:TSmartCardMonitor;R:TSmartCardReader;HM:THidDeviceMonitor;Input:TUsbHidInputMonitor;
  StopOnInsert,FreeOnInsert,StopOnReport,FreeOnReport:Boolean;Reports,Errors:Integer;
  constructor Create;destructor Destroy;override;
  procedure ThreadCheck;
  procedure Added(Sender:TObject;const Name:UnicodeString);
  procedure Removed(Sender:TObject;const Name:UnicodeString);
  procedure Inserted(Sender:TObject;const S:TPcscReaderSnapshot);
  procedure CardRemoved(Sender:TObject;const S:TPcscReaderSnapshot);
  procedure State(Sender:TObject;const S:TPcscReaderSnapshot);
  procedure Error(Sender:TObject;const Code:Cardinal);
  procedure Report(Sender:TObject;const B:TBytes);
  procedure InputError(Sender:TObject);
 end;
 TQueued=class(TInterfacedObject,ICardQueuedEvent)
  Log:TStringList;Value:string;Queue:ICardEventQueue;Invalidate:Boolean;
  procedure Invoke;
 end;
constructor TMockPcsc.Create;
begin inherited Create;{$IFDEF FPC}InitCriticalSection(Lock);{$ELSE}Lock:=TCriticalSection.Create;{$ENDIF}Version:=0;end;
destructor TMockPcsc.Destroy;
begin {$IFDEF FPC}DoneCriticalSection(Lock);{$ELSE}Lock.Free;{$ENDIF}inherited Destroy;end;
procedure TMockPcsc.Enter;
begin {$IFDEF FPC}EnterCriticalSection(Lock);{$ELSE}Lock.Enter;{$ENDIF}end;
procedure TMockPcsc.Leave;
begin {$IFDEF FPC}LeaveCriticalSection(Lock);{$ELSE}Lock.Leave;{$ENDIF}end;
procedure TMockPcsc.SetStep(const N:Integer);
begin Enter;try Step:=N;Inc(Version);finally Leave;end;end;
function TMockPcsc.Establish(out C:TPcscHandle):Cardinal;
begin C:=1;Result:=0;end;
function TMockPcsc.Release(const C:TPcscHandle):Cardinal;
begin Inc(ReleaseCount);Result:=0;end;
function TMockPcsc.ListReaders(const C:TPcscHandle;out N:TPcscReaderNames):Cardinal;
begin
 Enter;try Inc(Listed);N:=nil;
 if ((Step>=1) and (Step<=3)) or (Step=5) then begin SetLength(N,1);N[0]:='Reader';end;
 if BadInventory then begin SetLength(N,2);N[0]:='Reader';N[1]:='Reader';end;
 Result:=0;finally Leave;end;
end;
function TMockPcsc.Connect(const C:TPcscHandle;const N:UnicodeString;const S:TPcscShareMode;const P:Cardinal;out H:TPcscHandle;out A:Cardinal):Cardinal;
begin Inc(Connected);H:=0;A:=0;Result:=PcscUnsupportedFeature;end;
function TMockPcsc.Disconnect(const C:TPcscHandle;const D:TPcscDisposition):Cardinal;begin Result:=0;end;
function TMockPcsc.BeginTransaction(const C:TPcscHandle):Cardinal;begin Result:=0;end;
function TMockPcsc.EndTransaction(const C:TPcscHandle;const D:TPcscDisposition):Cardinal;begin Result:=0;end;
function TMockPcsc.Transmit(const C:TPcscHandle;const P:Cardinal;const B:TBytes;const Max:Integer;out R:TBytes):Cardinal;begin R:=nil;Result:=PcscUnsupportedFeature;end;
function TMockPcsc.ReadAtr(const C:TPcscHandle;out B:TBytes):Cardinal;begin B:=nil;Result:=PcscUnsupportedFeature;end;
function TMockPcsc.WaitStatus(const C:TPcscHandle;const N:UnicodeString;const S,T:Cardinal;out R:TPcscReaderSnapshot):Cardinal;begin R:=Default(TPcscReaderSnapshot);Result:=PcscUnsupportedFeature;end;
function TMockPcsc.Cancel(const C:TPcscHandle):Cardinal;begin Inc(Cancelled);Result:=0;end;
function TMockPcsc.WaitReaders(const C:TPcscHandle;const A:TPcscReaderSnapshots;const T:Cardinal;out R:TPcscReaderSnapshots):Cardinal;
var I:Integer;Changed:Boolean;
begin
 Sleep(5);Enter;
 try
  Inc(Waited);R:=nil;if ErrorCode<>0 then Exit(ErrorCode);
  SetLength(R,Length(A));Changed:=False;
  for I:=0 to High(A) do begin
   R[I].ReaderName:=A[I].ReaderName;
   if A[I].ReaderName=PcscPnpNotification then R[I].State:=Cardinal(Version) shl 16 or PcscStateChanged
   else if (Step=2) or (Step=3) then begin R[I].State:=PcscStatePresent or (Cardinal(Step) shl 16);R[I].Atr:=HexToBytes('3B00');end
   else if Step=4 then R[I].State:=PcscStateUnknown else R[I].State:=PcscStateEmpty;
   if ((R[I].State xor A[I].State) and not PcscStateChanged)<>0 then Changed:=True;
  end;
  if BadSnapshot then begin R[0].ReaderName:='wrong';Changed:=True;end;
  if Changed or (A[High(A)].State=0) then Result:=0 else begin R:=nil;Result:=PcscTimeout;end;
 finally Leave;end;
end;
procedure TNotifications.Start(const AHandler:THidNotification);
begin Inc(Started);H:=AHandler;if FailStart then raise EHidError.Create('Mock acquisition failure.');end;
procedure TNotifications.Stop;begin Inc(Stopped);H:=nil;end;
procedure TNotifications.Emit(const Path:UnicodeString;Added:Boolean);
var Saved:THidNotification;begin Saved:=H;if Assigned(Saved) then Saved(Path,Added);end;
function TReportDevice.Open(const W:Boolean):THidDeviceInfo;
begin if W then raise Exception.Create('Listener must open read-only.');Inc(Opened);Result:=Default(THidDeviceInfo);Result.InputBytes:=4;end;
procedure TReportDevice.Close;begin Inc(Closed);end;
function TReportDevice.Receive(const K:THidReportKind;const ID:Byte;const T:Cardinal):TBytes;
begin
 if (K<>hrkInterrupt) or (T<>250) then raise Exception.Create('Finite interrupt input required.');Inc(Reads);Sleep(5);
 if Bad then raise EHidError.Create('Mock read failure.');
 if Reads>2 then raise EHidReceiveTimeout.Create('Mock timeout.');
 Result:=HexToBytes('00010203');
end;
procedure TReportDevice.Send(const K:THidReportKind;const B:TBytes;const T:Cardinal);
begin raise Exception.Create('Listener must never write.');end;
constructor TRecorder.Create;begin inherited Create;Log:=TStringList.Create;end;
destructor TRecorder.Destroy;begin Input.Free;HM.Free;R.Free;M.Free;Log.Free;inherited Destroy;end;
procedure TRecorder.ThreadCheck;begin Check(TThread.CurrentThread.ThreadID=MainThreadID,'Main-thread event delivery');end;
procedure TRecorder.Added(Sender:TObject;const Name:UnicodeString);begin ThreadCheck;Log.Add('added:'+string(Name));end;
procedure TRecorder.Removed(Sender:TObject;const Name:UnicodeString);begin ThreadCheck;Log.Add('removed:'+string(Name));end;
procedure TRecorder.Inserted(Sender:TObject;const S:TPcscReaderSnapshot);
begin ThreadCheck;Log.Add('inserted:'+BytesToHex(S.Atr));if StopOnInsert then M.Stop;if FreeOnInsert then FreeAndNil(M);end;
procedure TRecorder.CardRemoved(Sender:TObject;const S:TPcscReaderSnapshot);begin ThreadCheck;Log.Add('cardremoved:'+BytesToHex(S.Atr));end;
procedure TRecorder.State(Sender:TObject;const S:TPcscReaderSnapshot);begin ThreadCheck;Log.Add('state');end;
procedure TRecorder.Error(Sender:TObject;const Code:Cardinal);begin ThreadCheck;Inc(Errors);Check(not M.Active,'Stopped before error event');end;
procedure TRecorder.Report(Sender:TObject;const B:TBytes);
begin ThreadCheck;Check(BytesToHex(B)='00010203','Owned unfiltered report');Inc(Reports);if StopOnReport then Input.Stop;if FreeOnReport then FreeAndNil(Input);end;
procedure TRecorder.InputError(Sender:TObject);begin ThreadCheck;Inc(Errors);Check(not Input.Active,'Input stopped before failure');end;
procedure TQueued.Invoke;begin Log.Add(Value);if Invalidate then Queue.Disable;end;
procedure Pump(const Count:Integer=50);
var I:Integer;begin for I:=1 to Count do begin CheckSynchronize(1);Sleep(1);end;end;
procedure AwaitCount(Log:TStringList;const Count:Integer);
var I:Integer;begin for I:=1 to 1000 do begin if Log.Count>=Count then Exit;Pump(1);end;raise Exception.Create('Event deadline exceeded.');end;
procedure Bind(const O:TRecorder;const Api:IPcscApi);
begin
 O.M:=TSmartCardMonitor.CreateWithApi(nil,Api);O.M.OnReaderAdded:=O.Added;O.M.OnReaderRemoved:=O.Removed;
 O.M.OnCardInserted:=O.Inserted;O.M.OnCardRemoved:=O.CardRemoved;O.M.OnStateChanged:=O.State;O.M.OnError:=O.Error;
end;
procedure TestPcsc;
var A:TMockPcsc;Api:IPcscApi;O:TRecorder;N,I:Integer;
begin
 A:=TMockPcsc.Create;Api:=A;O:=TRecorder.Create;
 try
  Bind(O,Api);O.M.Start;Pump;
  Check(O.Log.Count=0,'Empty inventory emits no synthetic reader');N:=A.Listed;Pump;
  Check(A.Listed=N,'Native wait timeouts do not poll reader inventory');
  A.SetStep(1);AwaitCount(O.Log,2);Check((O.Log[0]='added:Reader') and (O.Log[1]='state'),'Arrival and initial empty state');
  A.SetStep(2);AwaitCount(O.Log,4);Check(O.Log[2]='inserted:3B00','Card offered');
  A.SetStep(3);AwaitCount(O.Log,7);Check((O.Log[4]='cardremoved:3B00') and (O.Log[5]='inserted:3B00'),'Counter observes replacement with identical ATR');
  A.SetStep(5);AwaitCount(O.Log,9);Check(O.Log[7]='cardremoved:3B00','Card removal while reader remains');
  A.SetStep(2);AwaitCount(O.Log,11);
  A.SetStep(4);AwaitCount(O.Log,14);Check((O.Log[11]='cardremoved:3B00') and (O.Log[13]='removed:Reader'),'Reader loss retains ATR and orders card before reader');
  O.M.Stop;Check((A.ReleaseCount=1) and (A.Cancelled=1) and (A.Connected=0),'Separate context cancelled/released without connecting');
  N:=O.Log.Count;A.SetStep(2);Pump;Check(O.Log.Count=N,'No callbacks after Stop');
 finally O.Free;Api:=nil;end;
 for I:=0 to 2 do begin
  A:=TMockPcsc.Create;Api:=A;A.SetStep(2);O:=TRecorder.Create;
  try
   Bind(O,Api);O.M.EmitInitialState:=I<>2;O.StopOnInsert:=I=0;O.FreeOnInsert:=I=1;O.M.Start;Pump;
   if I=2 then Check(O.Log.Count=0,'Initial cards suppressed')
   else Check((O.Log.Count=2) and (O.Log[1]='inserted:3B00'),'Callback stop/free discards pending state');
   if O.M<>nil then O.M.Stop;Check(A.ReleaseCount=1,'Callback lifecycle releases exactly once');
  finally O.Free;Api:=nil;end;
 end;
 A:=TMockPcsc.Create;Api:=A;A.BadInventory:=True;O:=TRecorder.Create;
 try Bind(O,Api);O.M.Start;Pump;Check((O.Errors=1) and (O.Log.Count=0),'Validate whole inventory before publishing arrivals');finally O.Free;Api:=nil;end;
 A:=TMockPcsc.Create;Api:=A;A.BadSnapshot:=True;O:=TRecorder.Create;
 try Bind(O,Api);O.M.Start;Pump;Check(O.Errors=1,'Invalid backend snapshot becomes terminal error');finally O.Free;Api:=nil;end;
 A:=TMockPcsc.Create;Api:=A;A.ErrorCode:=PcscUnsupportedFeature;O:=TRecorder.Create;
 try Bind(O,Api);O.M.Start;Pump;Check(O.Errors=1,'Native backend error delivered once');finally O.Free;Api:=nil;end;
 A:=TMockPcsc.Create;Api:=A;A.SetStep(2);O:=TRecorder.Create;
 try
  O.R:=TSmartCardReader.CreateWithApi(nil,Api);O.R.ReaderName:='Other';O.R.OnCardInserted:=O.Inserted;O.R.OnReaderAdded:=O.Added;
  O.R.StartEventMonitoring;Pump;Check(O.Log.Count=1,'Reader component filters cards by selected name but observes inventory');
  O.R.StopMonitoring;O.R.ReaderName:='Reader';O.R.StartEventMonitoring;Pump;
  Check(O.Log.Count=3,'Reader component forwards selected card without PollChanges');O.R.StopMonitoring;
 finally O.Free;Api:=nil;end;
end;
procedure TestHid;
var A:TNotifications;Api:IHidDeviceNotifications;D:TReportDevice;Device:IHidReportDevice;O:TRecorder;I:Integer;
begin
 A:=TNotifications.Create;Api:=A;O:=TRecorder.Create;
 try
  O.HM:=THidDeviceMonitor.CreateWithApi(nil,Api);O.HM.OnDeviceAdded:=O.Added;O.HM.OnDeviceRemoved:=O.Removed;
  O.HM.Start;A.Emit('Opaque path',True);A.Emit('Opaque path',False);
  Check((O.Log[0]='added:Opaque path') and (O.Log[1]='removed:Opaque path'),'HID native notification adapter forwards exact identity');
  O.HM.Stop;A.Emit('late',True);Check(O.Log.Count=2,'HID unregister discards later notifications');
  A.FailStart:=True;try O.HM.Start;raise Exception.Create('Expected acquisition failure');except on E:EHidError do Check(not O.HM.Active,'HID start rollback');end;
 finally O.Free;Api:=nil;end;
 for I:=0 to 3 do begin
  D:=TReportDevice.Create;Device:=D;O:=TRecorder.Create;
  try
   D.Bad:=I=2;O.StopOnReport:=I=1;O.FreeOnReport:=I=3;
   O.Input:=TUsbHidInputMonitor.Create(nil);O.Input.Device:=Device;O.Input.OnInputReport:=O.Report;O.Input.OnError:=O.InputError;
   O.Input.Start;Pump;
   if I=2 then Check(O.Errors=1,'Input failure event')
   else if (I=1) or (I=3) then Check(O.Reports=1,'Stop/free inside input callback discards pending reports')
   else Check(O.Reports=2,'Input reports arrive automatically; timeouts stay nonterminal');
   if O.Input<>nil then O.Input.Stop;Check((D.Opened=1) and (D.Closed=1),'One input acquisition/release');Pump;Check(O.Reports<=2,'No reports after stop');
  finally O.Free;Device:=nil;end;
 end;
end;
procedure TestQueue;
var Q:ICardEventQueue;E:ICardQueuedEvent;N:TQueued;L:TStringList;I:Integer;
begin
 L:=TStringList.Create;
 try
  Q:=CreateCardEventQueue(2);
  for I:=0 to 1 do begin N:=TQueued.Create;N.Log:=L;N.Value:=IntToStr(I);E:=N;Check(Q.Add(E)=(I=0),'Exactly one initial dispatcher scheduled');end;
  try Q.Add(E);raise Exception.Create('Overflow expected');except on X:ECardEventError do Check(True,'Bounded queue overflow explicit');end;
  Q.Dispatch;Check((L.Count=2) and (L[0]='0') and (L[1]='1'),'FIFO preserved');
  N:=TQueued.Create;N.Log:=L;N.Value:='stop';N.Queue:=Q;N.Invalidate:=True;E:=N;Q.Add(E);
  N:=TQueued.Create;N.Log:=L;N.Value:='discard';E:=N;Q.Add(E);Q.Dispatch;
  Check((L.Count=3) and (L[2]='stop'),'Lifetime invalidation discards current batch');
  Check(not Q.Add(E),'Disabled queue does not schedule');E:=nil;Q:=nil;
  Q:=CreateCardEventQueue(1);N:=TQueued.Create;N.Log:=L;N.Value:='old';E:=N;Q.Add(E);
  N:=TQueued.Create;N.Log:=L;N.Value:='terminal';E:=N;
  Check(not Q.Replace(E),'Terminal replacement reuses scheduled dispatcher');Q.Dispatch;
  Check((L.Count=4) and (L[3]='terminal'),'Terminal error replaces stale notifications');E:=nil;Q:=nil;
 finally L.Free;end;
end;
begin
 try TestQueue;TestPcsc;TestHid;Writeln('PASS: ',Checks,' reader/card/HID event and lifecycle assertions.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
