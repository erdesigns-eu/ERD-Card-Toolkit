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
  I: Integer;
begin
  if (ParamCount <> 2) or (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectEmv <exact-reader-name> --pse | --ppse | <exact-AID-hex>');
    Writeln('Discovery selects no payment application. An explicit AID sends GPO.');
    Writeln('Application reads require an empty PDOL; otherwise supply terminal data through the API.');
    Halt(0);
  end;
  try
    Card := TSmartCardReader.Create(nil);
    try
      Emv := TEMVCardReader.Create(nil);
      try
        Card.ReaderName := UnicodeString(ParamStr(1));
        Card.Connect;
        Emv.Transport := Card.Transport;
        if (ParamStr(2) = '--pse') or (ParamStr(2) = '--ppse') then
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
