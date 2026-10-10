program GpDemoOperationsTests;

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
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Demo.Job, ERD.Card.Demo.GlobalPlatform.Operations;

type
  TProgressProducer = class(TThread)
  private
    FProgress: ICardGpDemoProgress;
  protected
    procedure Execute; override;
  public
    constructor Create(const AProgress: ICardGpDemoProgress);
  end;

  TReturnedFailure = class(TInterfacedObject, ICardDemoOperations)
  public
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

constructor TProgressProducer.Create(const AProgress: ICardGpDemoProgress);
begin
  inherited Create(True);
  FProgress := AProgress;
end;

procedure TProgressProducer.Execute;
var I: Integer;
begin
  for I := 1 to 4096 do
  begin
    FProgress.Publish(I, 4096);
    if I mod 128 = 0 then Sleep(1);
  end;
end;

procedure TReturnedFailure.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
begin
  AResult.Success := False; AResult.ErrorClass := 'EGpCardError';
  AResult.Text := 'Card status: 6985'; AResult.WriteUncertain := True;
end;

procedure ProgressTests;
var
  Channel: ICardGpDemoProgress;
  Snapshot, Previous: TCardGpDemoProgress;
  Producer: TProgressProducer;
  Deadline: UInt64;
  I: Integer;
  Failed: Boolean;
begin
  Channel := CreateGlobalPlatformDemoProgress;
  Snapshot := Channel.ReadSnapshot;
  if (Snapshot.AcknowledgedBytes <> 0) or (Snapshot.TotalBytes <> 0) or
    (Snapshot.AcknowledgedBlocks <> 0) then raise Exception.Create('Progress did not start empty.');
  Producer := TProgressProducer.Create(Channel);
  try
    Producer.Start;
    Deadline := GetTickCount64 + 10000;
    repeat
      Previous := Snapshot; Snapshot := Channel.ReadSnapshot;
      if (Snapshot.AcknowledgedBytes <> Snapshot.AcknowledgedBlocks) or
        (Snapshot.AcknowledgedBytes < Previous.AcknowledgedBytes) or
        ((Snapshot.TotalBytes <> 0) and (Snapshot.TotalBytes <> 4096)) then
        raise Exception.Create('Progress snapshot torn or regressed.');
      if GetTickCount64 > Deadline then raise Exception.Create('Progress publication timed out.');
      Sleep(0);
    until Snapshot.AcknowledgedBytes = 4096;
    Producer.WaitFor;
  finally Producer.Free; end;
  // Retained snapshots still work after the publishing thread has been destroyed.
  Snapshot := Channel.ReadSnapshot;
  if Snapshot.AcknowledgedBlocks <> 4096 then raise Exception.Create('Final block missing.');
  for I := 0 to 3 do
  begin
    Failed := False;
    try
      case I of
        0: Channel.Publish(4096, 4096);
        1: Channel.Publish(0, 4096);
        2: Channel.Publish(4097, 4096);
        3: Channel.Publish(4097, 4097);
      end;
    except on EArgumentException do Failed := True; end;
    if not Failed then raise Exception.Create('Invalid LOAD progress accepted.');
    Snapshot := Channel.ReadSnapshot;
    if (Snapshot.AcknowledgedBytes <> 4096) or (Snapshot.AcknowledgedBlocks <> 4096) then
      raise Exception.Create('Rejected progress changed the snapshot.');
  end;
  Writeln('PASS: Atomic live progress from 4096 worker updates, retained final state and invalid-update refusal.');
end;

procedure ReturnedFailureTests;
var
  Job: TCardDemoJob;
  Request: TCardDemoRequest;
  Completed: TCardDemoResult;
begin
  Request := Default(TCardDemoRequest); Completed := Default(TCardDemoResult);
  Job := TCardDemoJob.Create(Request, TReturnedFailure.Create);
  try
    Job.StartWork; Job.WaitFor;
    if not Job.TryTakeResult(Completed) or Completed.Success or
      (Completed.ErrorClass <> 'EGpCardError') or (Completed.Text <> 'Card status: 6985') or
      not Completed.WriteUncertain then raise Exception.Create('Returned card failure was overwritten.');
    if Job.TryTakeResult(Completed) then raise Exception.Create('Result delivered twice.');
  finally Job.Free; end;
  Writeln('PASS: Returned GP card failure, diagnostic status and uncertain-write state survive the worker.');
end;

var
  Ops: ICardDemoOperations;
  Q: TCardDemoRequest;
  R: TCardDemoResult;
  I: Integer;
  Failed: Boolean;
begin
  try
    ProgressTests; ReturnedFailureTests;
    Ops := CreateGlobalPlatformDemoOperations;
    for I := 0 to 5 do
    begin
      Q := Default(TCardDemoRequest); R := Default(TCardDemoResult);
      Q.Operation := cdoFamily; Q.FamilyName := 'GlobalPlatform'; Q.FamilyAction := 5;
      Q.MutationAcknowledged := True; Q.ReaderName := 'No hardware may be accessed';
      SetLength(Q.Arguments, 29); SetLength(Q.Credentials, 11);
      Q.Arguments[16] := '2'; Q.Arguments[17] := '1'; Q.Arguments[18] := '0';
      Q.Arguments[19] := '0'; Q.Arguments[20] := '0'; Q.Arguments[22] := '-1'; Q.Arguments[28] := '0';
      Q.Arguments[26] := '010001';
      Q.Credentials[0] := HexToBytes('000102030405060708090A0B0C0D0E0F');
      Q.Credentials[1] := HexToBytes('101112131415161718191A1B1C1D1E1F');
      Q.Arguments[0] := 'A000000151000000'; Q.Arguments[1] := '1'; Q.Arguments[2] := '1';
      Q.Arguments[3] := '0'; Q.Arguments[4] := '0'; Q.Arguments[5] := '0';
      Q.Arguments[12] := '07'; Q.Arguments[14] := '220';
      case I of
        0: Q.MutationAcknowledged := False;
        1: Q.Arguments[1] := '2';
        2: Q.Arguments[2] := '5';
        3: Q.Arguments[3] := '256';
        4: Q.Arguments[0] := '00';
        5: Q.Credentials[0] := HexToBytes('00');
      end;
      Failed := False;
      try Ops.Run(Q, R);
      except on EArgumentException do Failed := True; end;
      if not Failed then raise Exception.Create('Invalid request reached hardware.');
    end;
    Writeln('PASS: six GP demo validation paths reject before opening hardware.');
  except
    on E: Exception do begin Writeln('FAIL: ', E.ClassName); Halt(1); end;
  end;
end.
