program GpDemoOperationsTests;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{$IFNDEF FPC}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Demo.Job, ERD.Card.Demo.GlobalPlatform.Operations;

var
  Ops: ICardDemoOperations;
  Q: TCardDemoRequest;
  R: TCardDemoResult;
  I: Integer;
  Failed: Boolean;
begin
  try
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
