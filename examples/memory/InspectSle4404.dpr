program InspectSle4404;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Memory, ERD.Card.Memory.Sle4404, ERD.Card.PCSC.Reader;

procedure Run;
var Window, Address, Count: Integer; Card: TSmartCardReader;
  Memory: TSle4404CardReaderWriter; Data: TBytes;
begin
  if (ParamCount = 0) or ((ParamCount = 1) and (ParamStr(1) = '--help')) then
  begin
    Writeln('InspectSle4404 --window <known-readable-bytes>');
    Writeln('Add --reader <exact-name> --dialect acr38-ccid [--address <byte> --count <bytes>]');
    Writeln('Window-only mode is offline. Hardware mode reads public bytes and reports length only.');
    Writeln('No supplied/default codes, programming, erasing, chip detection or contents display.');
    Exit;
  end;
  if not (ParamCount in [2,6,10]) or (ParamStr(1) <> '--window') or
    not TryStrToInt(ParamStr(2),Window) or (Window < 1) or (Window > 256) then
    raise EMemoryCardError.Create('Supply an explicit readable window from the actual chip layout.');
  Writeln('Caller-declared readable bytes: ',Window,'. This is not detected chip capacity.');
  if ParamCount = 2 then Exit;
  if (ParamStr(3) <> '--reader') or (Trim(ParamStr(4)) = '') or
    (ParamStr(5) <> '--dialect') or (ParamStr(6) <> 'acr38-ccid') then
    raise EMemoryCardError.Create('An exact reader and ACR38x CCID dialect are required.');
  Address := 0; Count := Window;
  if ParamCount = 10 then
    if (ParamStr(7) <> '--address') or (ParamStr(9) <> '--count') or
      not TryStrToInt(ParamStr(8),Address) or not TryStrToInt(ParamStr(10),Count) or
      (Address < 0) or (Address >= Window) or (Count < 1) or (Count > Window - Address) then
      raise EMemoryCardError.Create('Read range is outside the declared window.');
  Card := TSmartCardReader.Create(nil);
  try
    Memory := TSle4404CardReaderWriter.Create(nil);
    try
      Memory.ReadableBytes := Window; Card.ReaderName := UnicodeString(ParamStr(4));
      Card.Connect; Memory.Transport := Card.Transport;
      Data := Memory.ReadMemory(Address,Count,nil); Writeln('Acquired public bytes: ',Length(Data));
      Card.Disconnect;
    finally Memory.Free; end;
  finally Card.Free; end;
end;

begin
  try Run;
  except on E: Exception do begin Writeln(E.ClassName); ExitCode := 1; end; end;
end.
