program InspectType4Ndef;

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
  ERD.Card.Bytes, ERD.Card.PCSC.Reader, ERD.Card.Contactless.Type4.Ndef;

procedure PrintCapabilities(const Cc: TType4CapabilityContainer);
var I: Integer;
begin
  Writeln('Mapping: ', IntToHex(Cc.MappingVersion, 2));
  Writeln('MLe: ', Cc.MLe, ' MLc: ', Cc.MLc);
  Writeln('NDEF files: ', Length(Cc.Files));
  for I := 0 to High(Cc.Files) do
    Writeln('File ', IntToHex(Cc.Files[I].FileId, 4), ': bytes=', Cc.Files[I].MaxFileBytes,
      ' public-read=', Cc.Files[I].ReadAccess = 0, ' public-write=', Cc.Files[I].WriteAccess = 0);
end;

procedure Run;
var Card: TSmartCardReader; Reader: TType4NdefCardReader;
  Cc: TType4CapabilityContainer; Snapshot: TType4NdefSnapshot;
  Version: TType4ApplicationVersion; FileId: Word; B: TBytes;
begin
  if (ParamCount = 1) and (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectType4Ndef --cc-hex <complete-capability-container-hex>');
    Writeln('       InspectType4Ndef --reader <exact-reader-name> --mapping <1|2> [--file <ISO-file-id-hex>]');
    Writeln('CC inspection is hardware-free. Card mode reads public NDEF and reports only structure/lengths.');
    Writeln('No writes, authentication, application fallback or displayed payload contents.');
    Exit;
  end;
  if (ParamCount = 2) and (ParamStr(1) = '--cc-hex') then
  begin
    if Length(ParamStr(2)) > Type4MaxCapabilityBytes * 2 then
      raise EType4NdefError.Create('Capability Container exceeds the supported bound.');
    Cc := TType4NdefCodec.DecodeCapabilities(HexToBytes(ParamStr(2))); PrintCapabilities(Cc); Exit;
  end;
  if not (ParamCount in [4, 6]) or (ParamStr(1) <> '--reader') or (ParamStr(3) <> '--mapping') then
    raise EType4NdefError.Create('Use --help for explicit supported modes.');
  if ParamStr(4) = '1' then Version := t4av1
  else if ParamStr(4) = '2' then Version := t4av2
  else raise EType4NdefError.Create('Explicit mapping 1 or 2 required.');
  FileId := 0;
  if ParamCount = 6 then
  begin
    if ParamStr(5) <> '--file' then raise EType4NdefError.Create('Explicit ISO file identifier expected.');
    B := HexToBytes(ParamStr(6));
    if Length(B) <> 2 then raise EType4NdefError.Create('ISO identifier requires exactly two bytes.');
    FileId := (Word(B[0]) shl 8) or B[1];
    if FileId = 0 then raise EType4NdefError.Create('An explicit file identifier cannot be zero.');
  end;
  Card := TSmartCardReader.Create(nil);
  try
    Reader := TType4NdefCardReader.Create(nil);
    try
      Reader.ApplicationVersion := Version; Card.ReaderName := UnicodeString(ParamStr(2)); Card.Connect;
      Reader.Transport := Card.Transport; Snapshot := Reader.ReadMessage(FileId);
      PrintCapabilities(Snapshot.Capabilities);
      Writeln('Selected file: ', IntToHex(Snapshot.FileInfo.FileId, 4));
      Writeln('NDEF bytes: ', Length(Snapshot.MessageBytes), ' records: ', Length(Snapshot.Records));
      Card.Disconnect;
    finally Reader.Free; end;
  finally Card.Free; end;
end;

begin
  try Run;
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
