program InspectNdef;

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
  ERD.Card.Bytes, ERD.Card.Ndef;

var Message: TNdefMessage; Wire: TBytes; I: Integer;
begin
  try
    if (ParamCount = 1) and (ParamStr(1) = '--help') then
    begin
      Writeln('Usage: InspectNdef <complete-message-hex>');
      Writeln('Decodes NDEF structure without hardware or displaying payload/identifier contents.');
      Exit;
    end;
    if (ParamCount <> 1) or (Length(ParamStr(1)) > NdefMaxMessageBytes * 2) then
      raise ENdefError.Create('Supply one bounded complete NDEF message as hexadecimal.');
    Wire := HexToBytes(ParamStr(1)); Message := TNdefCodec.Decode(Wire);
    Writeln('Records: ', Length(Message));
    for I := 0 to High(Message) do
      Writeln('Record ', I, ': TNF=', Ord(Message[I].Tnf),
        ' TypeBytes=', Length(Message[I].RecordType),
        ' IdBytes=', Length(Message[I].Id), ' PayloadBytes=', Length(Message[I].Payload));
    Writeln('Canonical bytes: ', Length(TNdefCodec.Encode(Message)));
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
