program InspectSim;

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
  ERD.Card.Bytes, ERD.Card.SIM.Data;

var Data: TBytes; Contact: TSimPhonebookEntry; Message: TSimSmsMessage; Sms: TSimSmsRecord;
  Application: TSimApplicationInfo; Provider: TSimServiceProvider; Kind: string;
begin
  try
    if (ParamCount = 1) and (ParamStr(1) = '--help') then
    begin
      Writeln('Usage: InspectSim --iccid|--imsi|--alpha|--spn|--adn|--sms|--sms-text|--directory <complete-hex>');
      Writeln('Offline codecs only. SimCardDemo demonstrates PC/SC reads and verified writes.');
      Exit;
    end;
    if (ParamCount <> 2) or (Length(ParamStr(2)) > 8192) then
      raise ESimCardError.Create('Supply an exact codec and bounded complete hexadecimal data.');
    Kind := ParamStr(1); Data := HexToBytes(ParamStr(2));
    if Kind = '--iccid' then Writeln(TSimCodec.DecodeIccid(Data))
    else if Kind = '--imsi' then Writeln(TSimCodec.DecodeImsi(Data))
    else if Kind = '--alpha' then Writeln(TSimCodec.DecodeAlpha(Data))
    else if Kind = '--spn' then begin Provider := TSimCodec.DecodeSpn(Data); Writeln(Provider.DisplayCondition, ': ', Provider.Name); end
    else if Kind = '--adn' then begin Contact := TSimCodec.DecodeAdn(Data); Writeln(Contact.Name, ': ', Contact.Number); Writeln('CCP=',Contact.CapabilityRecord,' EXT=',Contact.ExtensionRecord); end
    else if Kind = '--sms-text' then begin Message := TSimCodec.DecodeSmsMessage(Data); Writeln(Message.Address, ': ', Message.Text); Writeln('TextDecoded=',Message.TextDecoded,' Segments=',Message.SegmentNumber,'/',Message.SegmentCount,' RawUD=',BytesToHex(Message.UserData)); end
    else if Kind = '--sms' then begin Sms := TSimCodec.DecodeSms(Data); Writeln('Status=',Sms.StatusByte,' State=',Ord(Sms.State),' Body=',BytesToHex(Sms.Body)); end
    else if Kind = '--directory' then begin Application := TSimCodec.DecodeDirectoryRecord(Data); Writeln(BytesToHex(Application.Aid),' ',Application.LabelText); end
    else raise ESimCardError.Create('Unknown codec.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end; end;
end.
