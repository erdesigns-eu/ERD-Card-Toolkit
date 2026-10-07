program InspectApdu;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes,
  ERD.Card.APDU;

var
  Command: TApduCommand;
begin
  if ParamCount <> 1 then
  begin
    Writeln('Usage: InspectApdu <hexadecimal-command>');
    Halt(2);
  end;
  try
    Command := TApduCodec.DecodeCommand(HexToBytes(ParamStr(1)));
    Writeln('CLA: ', IntToHex(Command.CLA, 2));
    Writeln('INS: ', IntToHex(Command.INS, 2));
    Writeln('Data bytes: ', Length(Command.Data));
    Writeln('Extended: ', BoolToStr(Command.IsExtended, True));
    if Command.HasLe then
      Writeln('Le: ', Command.Le)
    else
      Writeln('Le: absent');
  except
    on E: EConvertError do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
