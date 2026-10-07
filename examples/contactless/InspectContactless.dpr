program InspectContactless;

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
  ERD.Card.PCSC.Reader, ERD.Card.Contactless;

var Card: TSmartCardReader; Contactless: TContactlessCardReader; Uid: TBytes;
begin
  if (ParamCount <> 2) or (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectContactless <exact-reader-name> --pcsc-storage');
    Writeln('Use only with a reader/driver supporting the storage pseudo-APDU profile.');
    Writeln('Reports UID length; does not authenticate or write a card.');
    Halt(0);
  end;
  try
    if ParamStr(2) <> '--pcsc-storage' then raise EContactlessError.Create('Explicit supported profile required.');
    Card := TSmartCardReader.Create(nil);
    try
      Contactless := TContactlessCardReader.Create(nil);
      try
        Card.ReaderName := UnicodeString(ParamStr(1));
        Card.Connect;
        Contactless.Transport := Card.Transport;
        Contactless.Profile := TPcscStorageProfile.Create;
        Uid := Contactless.ReadUid;
        Writeln('Reader-reported UID bytes: ', Length(Uid));
        Card.Disconnect;
      finally Contactless.Free; end;
    finally Card.Free; end;
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
