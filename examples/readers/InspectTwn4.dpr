program InspectTwn4;

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
  ERD.Card.Bytes, ERD.Card.Reader.TWN4, ERD.Card.Reader.TWN4.Serial;

var Reader: TTwn4CardReaderWriter; Tag: TTwn4TagInfo;
  Port, Frame: string; UseCrc, Version: Boolean; I: Integer; B: TBytes;
begin
  try
    if (ParamCount = 1) and (ParamStr(1) = '--help') then
    begin
      Writeln('InspectTwn4 --port COM17 [--crc] [--version]');
      Writeln('InspectTwn4 --frame 0005 [--crc]  (offline, no hardware)');
      Writeln('Requires configured TWN4 PRS ASCII / USB-CDC, not keyboard HID.');
      Writeln('No writes, firmware changes, protocol guessing or automatic retries.');
      Exit;
    end;
    Port := ''; Frame := ''; UseCrc := False; Version := False; I := 1;
    while I <= ParamCount do
    begin
      if ParamStr(I) = '--crc' then begin if UseCrc then raise ETwn4Error.Create('Duplicate --crc.'); UseCrc := True; end
      else if ParamStr(I) = '--version' then begin if Version then raise ETwn4Error.Create('Duplicate --version.'); Version := True; end
      else if ParamStr(I) = '--port' then
      begin
        if (Port <> '') or (I = ParamCount) then raise ETwn4Error.Create('Invalid --port argument.');
        Inc(I); Port := ParamStr(I);
      end
      else if ParamStr(I) = '--frame' then
      begin
        if (Frame <> '') or (I = ParamCount) then raise ETwn4Error.Create('Invalid --frame argument.');
        Inc(I); Frame := ParamStr(I);
      end
      else raise ETwn4Error.Create('Unknown argument. See --help.');
      Inc(I);
    end;
    if Frame <> '' then
    begin
      if (Port <> '') or Version or (Length(Frame) > 512) then raise ETwn4Error.Create('Offline frame options are inconsistent.');
      B := TTwn4Codec.EncodeAscii(HexToBytes(Frame),UseCrc);
      Writeln('ASCII wire bytes: ',BytesToHex(B)); Exit;
    end;
    if Port = '' then raise ETwn4Error.Create('Supply an explicit --port or offline --frame.');
    Reader := TTwn4CardReaderWriter.Create(nil);
    try
      Reader.Channel := CreateWindowsTwn4CdcChannel(Port); Reader.UseCrc := UseCrc;
      if Version then Writeln('Version: ',Reader.ReadVersion)
      else
      begin
        Tag := Reader.ReadTag;
        if not Tag.Found then Writeln('No tag reported.')
        else Writeln('Type: ',IntToHex(Tag.TagType,2),'; bits: ',Tag.IdBitCount,'; reader-order ID: ',BytesToHex(Tag.Id));
      end;
    finally Reader.Free; end;
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
