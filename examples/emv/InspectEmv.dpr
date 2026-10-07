program InspectEmv;

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
  ERD.Card.Bytes, ERD.Card.PCSC.Reader, ERD.Card.EMV.Data, ERD.Card.EMV.Reader;

var
  Card: TSmartCardReader;
  Emv: TEMVCardReader;
  Directory: TEmvDirectory;
  Discovery: TEmvDirectoryData;
  Data: TEmvApplicationData;
  Log: TEmvTransactionLogData;
  ObjectData: TEmvDataObjectResult;
  DataObject: TEmvDataObject;
  I: Integer;
begin
  if not (ParamCount in [2, 3]) or (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectEmv <exact-reader-name> --pse | --ppse | <exact-AID-hex>');
    Writeln('       InspectEmv <exact-reader-name> --log | --atc | --last-online-atc | --pin-tries <exact-AID-hex>');
    Writeln('Discovery selects no payment application. An explicit AID sends GPO.');
    Writeln('Application reads require an empty PDOL; otherwise supply terminal data through the API.');
    Writeln('Log/counter modes select an AID but do not send GPO or perform a payment.');
    Halt(0);
  end;
  try
    if (ParamCount = 3) and (ParamStr(2) <> '--log') and (ParamStr(2) <> '--atc') and
      (ParamStr(2) <> '--last-online-atc') and (ParamStr(2) <> '--pin-tries') then
      raise EEmvDataError.Create('Unknown log/counter mode.');
    Card := TSmartCardReader.Create(nil);
    try
      Emv := TEMVCardReader.Create(nil);
      try
        Card.ReaderName := UnicodeString(ParamStr(1));
        Card.Connect;
        Emv.Transport := Card.Transport;
        if ParamCount = 3 then
        begin
          if ParamStr(2) = '--log' then
          begin
            Log := Emv.ReadTransactionLog(HexToBytes(ParamStr(3)));
            Writeln('Log advertised: ', Log.Supported);
            Writeln('Log records: ', Length(Log.Records));
          end
          else
          begin
            if ParamStr(2) = '--atc' then DataObject := edoAtc
            else if ParamStr(2) = '--last-online-atc' then DataObject := edoLastOnlineAtc
            else DataObject := edoPinTryCounter;
            ObjectData := Emv.ReadDataObject(HexToBytes(ParamStr(3)), DataObject);
            Writeln('Object available: ', ObjectData.Present);
            Writeln('Status: ', IntToHex(ObjectData.StatusWord, 4));
          end;
        end
        else if (ParamStr(2) = '--pse') or (ParamStr(2) = '--ppse') then
        begin
          if ParamStr(2) = '--pse' then Directory := edContactPse
          else Directory := edContactlessPpse;
          Discovery := Emv.DiscoverApplications(Directory);
          Writeln('Directory present: ', Discovery.Present);
          for I := 0 to Length(Discovery.Applications) - 1 do
            Writeln(BytesToHex(Discovery.Applications[I].Aid), ' ', Discovery.Applications[I].LabelText);
        end
        else
        begin
          Data := Emv.ReadApplication(HexToBytes(ParamStr(2)), nil);
          Writeln('Application: ', Data.ApplicationInfo.LabelText);
          Writeln('Records: ', Length(Data.Records));
          Writeln('PAN available: ', Data.Pan <> '');
          Writeln('Expiry month available: ', Data.ExpiryMonth <> '');
          Writeln('IBAN available: ', Data.Iban <> '');
        end;
        Card.Disconnect;
      finally Emv.Free; end;
    finally Card.Free; end;
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
