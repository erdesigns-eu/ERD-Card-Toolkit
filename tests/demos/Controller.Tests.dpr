program ControllerTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF UNIX}cthreads,{$ENDIF}
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
 ERD.Card.Demo.Controller, ERD.Card.Demo.Job, ERD.Card.Demo.Devices;
type
 TSource = class(TInterfacedObject, ICardDemoDeviceSource)
  Calls: Integer;
  Kind: TCardDemoDeviceKind;
  Failure: Boolean;
  function Enumerate(const AKind: TCardDemoDeviceKind): TCardDemoDevices;
 end;
 TOperations = class(TInterfacedObject, ICardDemoOperations)
  Calls: Integer;
  procedure Run(const R: TCardDemoRequest; var D: TCardDemoResult);
 end;
 TValidatedOperations = class(TOperations, ICardDemoRequestValidator)
  Validations: Integer;
  Accept: Boolean;
  function TryValidateRequest(const R: TCardDemoRequest; out ErrorText: UnicodeString): Boolean;
 end;
 TObserver = class
  BusyCalls, Results, Closes: Integer;
  Busy, FailBusy: Boolean;
  Caller: TThreadID;
  Data: TCardDemoResult;
  procedure OnBusy(const V: Boolean);
  procedure OnResult(const D: TCardDemoResult);
  procedure OnClose;
 end;
var Checks: Integer;
procedure Check(const V: Boolean; const M: string);
begin Inc(Checks); if not V then raise Exception.Create(M); end;
function TSource.Enumerate(const AKind: TCardDemoDeviceKind): TCardDemoDevices;
begin
 Result := nil; Inc(Calls); Kind := AKind;
 if Failure then raise EInvalidOpException.Create('secret discovery message');
 SetLength(Result,2); Result[0].DisplayName := 'friendly'; Result[0].Address := 'exact device path';
 Result[1].DisplayName := 'second'; Result[1].Address := 'another path';
end;
procedure TOperations.Run(const R: TCardDemoRequest; var D: TCardDemoResult);
begin Inc(Calls); D.Operation := R.Operation; D.Text := 'owned card output'; end;
function TValidatedOperations.TryValidateRequest(const R: TCardDemoRequest; out ErrorText: UnicodeString): Boolean;
begin Inc(Validations); Result := Accept; ErrorText := 'Select a reader before running this action.'; end;
procedure TObserver.OnBusy(const V: Boolean);
begin
 Check(TThread.CurrentThread.ThreadID = Caller,'Busy callback ran on worker');
 Inc(BusyCalls); Busy := V;
 if V and FailBusy then raise EInvalidOpException.Create('busy callback failure');
end;
procedure TObserver.OnResult(const D: TCardDemoResult);
begin
 Check(TThread.CurrentThread.ThreadID = Caller,'Result callback ran on worker');
 Check(not Busy,'Result arrived before clearing busy'); Inc(Results); Data := D;
end;
procedure TObserver.OnClose;
begin Check(TThread.CurrentThread.ThreadID = Caller,'Close callback ran on worker'); Inc(Closes); end;
procedure Await(const C: TCardDemoController; const O: TObserver; const Closing: Boolean);
var Deadline: UInt64;
begin
 Deadline := GetTickCount64+5000;
 repeat
  C.Poll;
  if (Closing and (O.Closes > 0)) or (not Closing and not O.Busy) then Exit;
  if GetTickCount64 >= Deadline then raise Exception.Create('Controller timed out');
  Sleep(1);
 until False;
end;
procedure Test(const Kind: TCardDemoDeviceKind; const Failure, Closing: Boolean);
var S: TSource; P: TOperations; SI: ICardDemoDeviceSource; PI: ICardDemoOperations;
 O: TObserver; C: TCardDemoController; R: TCardDemoRequest; Refused: Boolean;
begin
 S := TSource.Create; SI := S; S.Failure := Failure; P := TOperations.Create; PI := P;
 O := TObserver.Create; O.Caller := TThread.CurrentThread.ThreadID;
 C := TCardDemoController.Create(Kind,PI,O.OnBusy,O.OnResult,O.OnClose,SI);
 try
  Check((S.Calls = 0) and (P.Calls = 0),'Construction touched hardware');
  Check(C.CanClose,'Idle controller refused close'); C.Poll;
  Check(O.Results = 0,'Idle poll delivered result');
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices; C.StartRequest(R);
  Refused := False;
  try C.StartRequest(R); except on E: EInvalidOpException do Refused := True; end;
  Check(Refused,'Controller accepted overlapping work');
  if Closing then Check(not C.CanClose,'Active close was not deferred');
  Await(C,O,Closing); C.Poll;
  Check((S.Calls = 1) and (S.Kind = Kind),'Wrong discovery count or kind');
  Check(P.Calls = 0,'Discovery called card executor');
  if Closing then begin
   Check((O.Closes = 1) and (O.Results = 0),'Deferred close leaked result or repeated close');
   Refused := False; try C.StartRequest(R); except on E: EInvalidOpException do Refused := True; end;
   Check(Refused,'Deferred closing allowed new work');
  end else begin
   Check((O.Results = 1) and (O.BusyCalls = 2),'Completion count differs');
   Check(O.Data.Operation = cdoDemoDevices,'Discovery operation lost');
   Check(O.Data.Success = not Failure,'Discovery success differs');
   if Failure then begin
    Check(Length(O.Data.Devices) = 0,'Failed discovery published devices');
    Check((O.Data.ErrorClass = 'EInvalidOpException') and (Pos('secret',string(O.Data.Text)) = 0),'Discovery leaked error text');
   end else begin
    Check((Length(O.Data.Devices) = 2) and (O.Data.Devices[0].Address = 'exact device path'),'Device address differs');
    R.Operation := cdoReaders; C.StartRequest(R); Await(C,O,False);
    Check((P.Calls = 1) and (S.Calls = 1),'Card operation dispatched to discovery');
    Check(O.Data.Text = 'owned card output','Card result lost');
   end;
  end;
 finally C.Free; O.Free; end;
end;
procedure TestFailedStartAndJoin;
var S: TSource; P: TOperations; SI: ICardDemoDeviceSource; PI: ICardDemoOperations;
 O: TObserver; C: TCardDemoController; R: TCardDemoRequest; Refused: Boolean;
begin
 S := TSource.Create; SI := S; P := TOperations.Create; PI := P;
 O := TObserver.Create; O.Caller := TThread.CurrentThread.ThreadID; O.FailBusy := True;
 C := TCardDemoController.Create(ddkPcsc,PI,O.OnBusy,O.OnResult,O.OnClose,SI);
 try
  R := Default(TCardDemoRequest); R.Operation := cdoDemoDevices; Refused := False;
  try C.StartRequest(R); except on E: EInvalidOpException do Refused := True; end;
  Check(Refused and not O.Busy,'Failed busy callback retained request');
  Check(C.CanClose and (S.Calls = 0),'Failed start executed discovery');
  O.FailBusy := False; C.StartRequest(R);
 finally C.Free; end;
 try
  Check((S.Calls = 1) and (O.Results = 0) and (O.Closes = 0),'Destroy failed to join or dispatched callbacks');
 finally O.Free; end;
end;
procedure TestInputValidation;
var S: TSource; P: TValidatedOperations; SI: ICardDemoDeviceSource; PI: ICardDemoOperations;
 O: TObserver; C: TCardDemoController; R: TCardDemoRequest;
begin
 S := TSource.Create; SI := S; P := TValidatedOperations.Create; PI := P;
 O := TObserver.Create; O.Caller := TThread.CurrentThread.ThreadID;
 C := TCardDemoController.Create(ddkPcsc,PI,O.OnBusy,O.OnResult,O.OnClose,SI);
 try
  R := Default(TCardDemoRequest); R.Operation := cdoFamily;
  C.StartRequest(R);
  Check((P.Validations = 1) and (P.Calls = 0) and (S.Calls = 0),'Rejected input touched hardware');
  Check((O.Results = 1) and (O.BusyCalls = 0) and C.CanClose,'Rejected input created worker');
  Check((O.Data.ErrorClass = 'EArgumentException') and not O.Data.Success,'Rejected input reported success');
  Check(O.Data.Text = 'Select a reader before running this action.','Field-specific validation message lost');
  R.Operation := cdoDemoDevices; C.StartRequest(R); Await(C,O,False);
  Check((P.Validations = 1) and (S.Calls = 1),'Reader discovery was blocked by input validation');
  P.Accept := True; R.Operation := cdoFamily; C.StartRequest(R); Await(C,O,False);
  Check((P.Validations = 2) and (P.Calls = 1) and (O.Results = 3),'Valid retry did not execute once');
 finally C.Free; O.Free; end;
end;
var Kind: TCardDemoDeviceKind;
begin
 try
  for Kind := Low(TCardDemoDeviceKind) to High(TCardDemoDeviceKind) do begin
   Test(Kind,False,False); Test(Kind,True,False); Test(Kind,False,True);
  end;
  TestFailedStartAndJoin; TestInputValidation;
  Writeln('PASS: ',Checks,' nonvisual demo controller assertions.');
 except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
