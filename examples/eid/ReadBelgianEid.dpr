program ReadBelgianEid;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.PCSC.Reader, ERD.Card.EID.Data, ERD.Card.EID.Reader;

var
  Card: TSmartCardReader;
  Eid: TBelgianEIDReader;
  Data: TBelgianEidData;
  Photo: TFileStream;
begin
  if (ParamCount <> 1) and (ParamCount <> 2) then
  begin
    Writeln('Usage: ReadBelgianEid <exact-reader-name> [photo-output.jpg]');
    Writeln('Reads identity, address and photo through Windows PC/SC.');
    Halt(0);
  end;
  if ParamStr(1) = '--help' then
  begin
    Writeln('Usage: ReadBelgianEid <exact-reader-name> [photo-output.jpg]');
    Writeln('Photo bytes are saved only when an output path is supplied.');
    Halt(0);
  end;
  try
    Card := TSmartCardReader.Create(nil);
    try
      Eid := TBelgianEIDReader.Create(nil);
      try
        Card.ReaderName := UnicodeString(ParamStr(1));
        Card.Connect;
        Eid.Transport := Card.Transport;
        Data := Eid.ReadCard;
        Writeln('Name: ', Data.Identity.GivenNames, ' ', Data.Identity.Surname);
        Writeln('Birth date: ', Data.Identity.BirthDate);
        Writeln('Address: ', Data.Address.StreetAndNumber, ', ', Data.Address.PostalCode,
          ' ', Data.Address.Municipality);
        Writeln('Photo bytes: ', Length(Data.Photo));
        if ParamCount = 2 then
        begin
          Photo := TFileStream.Create(ParamStr(2), fmCreate);
          try
            Photo.WriteBuffer(Data.Photo[0], Length(Data.Photo));
          finally
            Photo.Free;
          end;
        end;
        Card.Disconnect;
      finally
        Eid.Free;
      end;
    finally
      Card.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
