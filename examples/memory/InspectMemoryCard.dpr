program InspectMemoryCard;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils, TypInfo,
{$ELSE}
  System.SysUtils, System.TypInfo,
{$ENDIF}
  ERD.Card.Memory, ERD.Card.PCSC.Reader;

procedure Run;
var Model: TMemoryCardModel; Dialect: TAcsMemoryDialect; Page: TMemoryCardPageSize;
  Name: string; I, N: Integer; Layout: TMemoryCardLayout; Found: Boolean;
  Card: TSmartCardReader; Memory: TMemoryCardReaderWriter; Snapshot: TMemoryCardSnapshot;
begin
  if (ParamCount = 0) or ((ParamCount = 1) and (ParamStr(1) = '--help')) then
  begin
    Writeln('Usage: InspectMemoryCard --model <sle4442|sle4432|sle5542|sle5532|sle4428|sle4418|sle5528|sle5518|i2c1kbit..i2c1024kbit>');
    Writeln('       Add --reader <exact-name> --dialect <acr38-ccid|acr39> [--page-size <8|16|32|64|128>]');
    Writeln('Model-only mode is hardware-free. Reader mode reads a snapshot and displays lengths/status only.');
    Writeln('No PIN attempts, writes, protection changes, automatic model detection or contents display.');
    Exit;
  end;
  if not (ParamCount in [2,6,8]) or (ParamStr(1) <> '--model') then
    raise EMemoryCardError.Create('Use --help for explicit supported modes.');
  Found := False; Model := mcmSle4442;
  for I := Ord(Low(TMemoryCardModel)) to Ord(High(TMemoryCardModel)) do
  begin
    Name := GetEnumName(TypeInfo(TMemoryCardModel), I);
    if SameText(Copy(Name,4,Length(Name)),ParamStr(2)) then begin Model := TMemoryCardModel(I); Found := True; Break; end;
  end;
  if not Found then raise EMemoryCardError.Create('Unknown memory model.');
  Layout := TMemoryCardCodec.Layout(Model);
  Writeln('Main bytes: ',Layout.Capacity,' PIN bytes: ',Layout.PinBytes,' protectable bytes: ',Layout.ProtectableBytes);
  if ParamCount = 2 then Exit;
  if (ParamStr(3) <> '--reader') or (ParamStr(5) <> '--dialect') then
    raise EMemoryCardError.Create('Explicit reader and dialect required.');
  if ParamStr(6) = 'acr38-ccid' then Dialect := amdAcr38Ccid
  else if ParamStr(6) = 'acr39' then Dialect := amdAcr39
  else raise EMemoryCardError.Create('Unknown ACS dialect.');
  Page := mps8;
  if ParamCount = 8 then
  begin
    if (ParamStr(7) <> '--page-size') or not TryStrToInt(ParamStr(8),N) then
      raise EMemoryCardError.Create('Explicit page size required.');
    case N of 8:Page:=mps8; 16:Page:=mps16; 32:Page:=mps32; 64:Page:=mps64; 128:Page:=mps128;
    else raise EMemoryCardError.Create('Unknown page size.'); end;
  end;
  Card := TSmartCardReader.Create(nil);
  try
    Memory := TMemoryCardReaderWriter.Create(nil);
    try
      Memory.Model := Model; Memory.Dialect := Dialect; Memory.PageSize := Page;
      Card.ReaderName := UnicodeString(ParamStr(4)); Card.Connect;
      Memory.Transport := Card.Transport; Snapshot := Memory.ReadSnapshot;
      Writeln('Acquired bytes: ',Length(Snapshot.Data),' protection bytes: ',Length(Snapshot.Protection));
      if Snapshot.HasSecurity then Writeln('Remaining PIN attempts: ',Snapshot.Security.RemainingAttempts);
      Card.Disconnect;
    finally Memory.Free; end;
  finally Card.Free; end;
end;

begin
  try Run;
  except on E: Exception do begin Writeln(E.ClassName); ExitCode := 1; end; end;
end.
