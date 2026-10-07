program InspectReader;

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
  ERD.Card.PCSC.Api,
  ERD.Card.PCSC.Reader;

var
  Reader: TSmartCardReader;
  Names: TPcscReaderNames;
  I: Integer;

begin
  if (ParamCount <> 1) or (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectReader --list | <exact-reader-name>');
    Writeln('Windows PC/SC discovery or raw ATR inspection; no application APDU is sent.');
    Halt(0);
  end;
  try
    Reader := TSmartCardReader.Create(nil);
    try
      if ParamStr(1) = '--list' then
      begin
        Names := Reader.ListReaders;
        for I := 0 to Length(Names) - 1 do Writeln(Names[I]);
      end
      else
      begin
        Reader.ReaderName := UnicodeString(ParamStr(1));
        Reader.Connect;
        Writeln('Protocol: ', Ord(Reader.Protocol));
        Writeln('ATR: ', BytesToHex(Reader.ReadAtr));
        Reader.Disconnect;
      end;
    finally
      Reader.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
