program DemoJobTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFDEF UNIX}
  cthreads,
{$ENDIF}
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes, System.SyncObjs,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Demo.Job, ERD.Card.Demo.Operations,
  ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe;

type
  TTestOperations = class(TInterfacedObject, ICardDemoOperations)
  private
    FLock: TCardDemoLock;
    FReleased: Boolean;
    FFailure, FVerified: Boolean;
    FCalls: Integer;
    FWorker: UInt64;
    function Released: Boolean;
    procedure Lock;
    procedure Unlock;
  public
    constructor Create(const AFailure, AVerified: Boolean);
    destructor Destroy; override;
    procedure Release;
    procedure Run(const R: TCardDemoRequest; var D: TCardDemoResult);
    property Calls: Integer read FCalls;
    property Worker: UInt64 read FWorker;
  end;

var Checks: Integer;

procedure Check(const Condition: Boolean; const Message: string);
begin
  Inc(Checks);
  if not Condition then raise Exception.Create(Message);
end;

constructor TTestOperations.Create(const AFailure, AVerified: Boolean);
begin
  inherited Create;
{$IFDEF FPC}
  InitCriticalSection(FLock);
{$ELSE}
  FLock := TCriticalSection.Create;
{$ENDIF}
  FFailure := AFailure; FVerified := AVerified;
end;

destructor TTestOperations.Destroy;
begin
{$IFDEF FPC}
  DoneCriticalSection(FLock);
{$ELSE}
  FLock.Free;
{$ENDIF}
  inherited Destroy;
end;

procedure TTestOperations.Lock;
begin
{$IFDEF FPC}
  EnterCriticalSection(FLock);
{$ELSE}
  FLock.Acquire;
{$ENDIF}
end;

procedure TTestOperations.Unlock;
begin
{$IFDEF FPC}
  LeaveCriticalSection(FLock);
{$ELSE}
  FLock.Release;
{$ENDIF}
end;

procedure TTestOperations.Release;
begin
  Lock;
  try FReleased := True; finally Unlock; end;
end;

function TTestOperations.Released: Boolean;
begin
  Lock;
  try Result := FReleased; finally Unlock; end;
end;

procedure TTestOperations.Run(const R: TCardDemoRequest; var D: TCardDemoResult);
var Deadline: UInt64;
begin
  Inc(FCalls); FWorker := TThread.CurrentThread.ThreadID;
  Deadline := GetTickCount64 + 5000;
  while not Released do
  begin
    if GetTickCount64 >= Deadline then raise Exception.Create('Gate timed out.');
    Sleep(1);
  end;
  if (Length(R.Password) <> 2) or (R.Password[0] <> $31) or
    (Length(R.NdefBytes) <> 2) or (R.NdefBytes[0] <> $D1) then
    raise Exception.Create('Request copy was aliased.');
  D.Tracks := R.Tracks;
  D.Photo := HexToBytes('010203'); D.NdefBytes := HexToBytes('AABB');
  D.Text := 'owned result'; D.WriteVerified := FVerified;
  if FFailure then raise EInvalidOpException.Create('secret request text');
end;

procedure AwaitResult(const Job: TCardDemoJob; var D: TCardDemoResult);
var Deadline: UInt64;
begin
  Deadline := GetTickCount64 + 5000;
  while not Job.TryTakeResult(D) do
  begin
    if GetTickCount64 >= Deadline then raise Exception.Create('Worker timed out.');
    Sleep(1);
  end;
end;

procedure TestWorker(const Fail, Verified: Boolean);
var R: TCardDemoRequest; D, Again: TCardDemoResult;
  Job: TCardDemoJob; Executor: ICardDemoOperations; Backend: TTestOperations;
  CallerId: UInt64;
begin
  R := Default(TCardDemoRequest); D := Default(TCardDemoResult);
  R.Password := HexToBytes('3132'); R.NdefBytes := HexToBytes('D101');
  R.Tracks[mstTrack1] := 'ABC';
  Backend := TTestOperations.Create(Fail, Verified); Executor := Backend;
  CallerId := TThread.CurrentThread.ThreadID;
  Job := TCardDemoJob.Create(R, Executor);
  Job.StartWork;
  try
    Check(not Job.TryTakeResult(D), 'Running work published early.');
    R.Password[0] := 0; R.NdefBytes[0] := 0; R.Tracks[mstTrack1] := 'CHANGED';
    Backend.Release;
    AwaitResult(Job, D);
    Job.WaitFor;
    Check(Backend.Calls = 1, 'Operation was retried.');
    Check(Backend.Worker <> CallerId, 'Hardware executor ran on caller thread.');
    Again := Default(TCardDemoResult); Again.Text := 'unchanged';
    Check(not Job.TryTakeResult(Again), 'Completion delivered twice.');
    Check(Again.Text = 'unchanged', 'Unready poll modified existing result.');
    Check(D.Success = not Fail, 'Success state differs.');
    Check(D.WriteVerified = Verified, 'Verified write evidence was lost.');
    if not Fail or Verified then Check(D.Tracks[mstTrack1] = 'ABC', 'Request strings were aliased.');
    if Fail then
    begin
      Check(D.ErrorClass = 'EInvalidOpException', 'Failure class was not preserved.');
      Check(Pos('secret', string(D.Text)) = 0, 'Exception message leaked.');
      if not Verified then Check((D.Text = '') and (Length(D.Photo) = 0), 'Partial failure data published.');
    end;
  finally Job.Free; end;
  if not Fail or Verified then
    Check(BytesToHex(D.Photo) = '010203', 'Result ownership did not survive job destruction.');
  Executor := nil;
end;

procedure TestJoin;
var R: TCardDemoRequest; Job: TCardDemoJob;
  Executor: ICardDemoOperations; Backend: TTestOperations;
begin
  R := Default(TCardDemoRequest); R.Password := HexToBytes('3132');
  R.NdefBytes := HexToBytes('D101');
  Backend := TTestOperations.Create(False, False); Executor := Backend;
  Job := TCardDemoJob.Create(R, Executor);
  Job.StartWork;
  Backend.Release;
  Job.Free;
  Check(Backend.Calls = 1, 'Destroy did not join running work.');
  Executor := nil;
  try
    Job := TCardDemoJob.Create(R, nil);
    Job.Free;
    Check(False, 'Nil executor was accepted.');
  except on E: EArgumentException do Check(True, 'Nil executor rejected.'); end;
  Check(BytesToHex(R.Password) = '3132', 'Job wiped caller password.');
end;

procedure TestSuspendedAndRestart;
var R: TCardDemoRequest; D: TCardDemoResult; Job: TCardDemoJob;
  Executor: ICardDemoOperations; Backend: TTestOperations;
begin
  R := Default(TCardDemoRequest); D := Default(TCardDemoResult);
  R.Password := HexToBytes('3132'); R.NdefBytes := HexToBytes('D101');
  Backend := TTestOperations.Create(False, False); Executor := Backend;
  Job := TCardDemoJob.Create(R, Executor);
  Check(not Job.TryTakeResult(D), 'Suspended worker published a result.');
  Job.Free;
  Check(Backend.Calls = 0, 'Free executed a never-started request.');
  Check(BytesToHex(R.Password) = '3132', 'Suspended destruction wiped caller bytes.');
  Job := TCardDemoJob.Create(R, Executor);
  try
    Job.StartWork;
    try
      Job.StartWork;
      Check(False, 'A second start was accepted.');
    except on E: EInvalidOpException do Check(True, 'Duplicate start rejected.'); end;
    Backend.Release;
    AwaitResult(Job, D);
    Job.WaitFor;
    Check(Backend.Calls = 1, 'Duplicate start replayed work.');
    try
      Job.StartWork;
      Check(False, 'Completed worker was restarted.');
    except on E: EInvalidOpException do Check(True, 'Completed restart rejected.'); end;
  finally Job.Free; end;
  Executor := nil;
end;

procedure TestOffline;
var R: TCardDemoRequest; D: TCardDemoResult; Job: TCardDemoJob;
begin
  R := Default(TCardDemoRequest); D := Default(TCardDemoResult);
  R.Operation := cdoNdefInspect; R.NdefBytes := HexToBytes('D101055402656E4869');
  Job := TCardDemoJob.Create(R, CreateCardDemoOperations);
  Job.StartWork;
  try AwaitResult(Job, D); finally Job.Free; end;
  Check(D.Success and (D.Text = 'NDEF records: 1'), 'Offline NDEF failed.');
  Check(BytesToHex(D.NdefBytes) = 'D101055402656E4869', 'Offline NDEF changed bytes.');
  R.Operation := cdoTrackInspect; R.TrackSelection := [mstTrack2];
  R.Tracks[mstTrack2] := '12345';
  Job := TCardDemoJob.Create(R, CreateCardDemoOperations);
  Job.StartWork;
  try AwaitResult(Job, D); finally Job.Free; end;
  Check(D.Success and (Pos('40 bits', string(D.Text)) > 0), 'Offline track framing failed.');
  R.Operation := cdoTrackWrite; R.PortName := 'COM1'; R.TimeoutMs := 1000;
  R.Coercivity := mscHigh; R.Tracks[mstTrack2] := '';
  Job := TCardDemoJob.Create(R, CreateCardDemoOperations);
  Job.StartWork;
  try AwaitResult(Job, D); finally Job.Free; end;
  Check((not D.Success) and (D.ErrorClass = 'EArgumentException'), 'Empty selected write touched hardware.');
  R.Operation := cdoUid; R.ReaderName := '';
  Job := TCardDemoJob.Create(R, CreateCardDemoOperations);
  Job.StartWork;
  try AwaitResult(Job, D); finally Job.Free; end;
  Check((not D.Success) and (D.ErrorClass = 'EArgumentException'), 'Reader selection was implicit.');
  R.Operation := cdoType4Write; R.ReaderName := 'selected reader';
  R.NdefBytes := HexToBytes('D101055402');
  Job := TCardDemoJob.Create(R, CreateCardDemoOperations);
  Job.StartWork;
  try AwaitResult(Job, D); finally Job.Free; end;
  Check((not D.Success) and (D.ErrorClass = 'ENdefError'), 'Malformed NDEF touched hardware.');
end;

begin
  try
    TestWorker(False, False); TestWorker(True, False); TestWorker(True, True);
    TestJoin; TestSuspendedAndRestart; TestOffline;
    Writeln('PASS: ', Checks, ' demo worker assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
