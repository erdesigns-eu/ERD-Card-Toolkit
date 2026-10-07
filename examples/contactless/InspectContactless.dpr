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
  ERD.Card.PCSC.Reader, ERD.Card.Contactless, ERD.Card.Contactless.Type2;

function ParseType2Model(const AName: string): TType2TagModel;
begin
  if AName = 'ultralight' then Result := ttmUltralight
  else if AName = 'ev1-48' then Result := ttmUltralightEv1_48
  else if AName = 'ev1-128' then Result := ttmUltralightEv1_128
  else if AName = 'ntag213' then Result := ttmNtag213
  else if AName = 'ntag215' then Result := ttmNtag215
  else if AName = 'ntag216' then Result := ttmNtag216
  else raise EType2DataError.Create('Explicit supported Type 2 model required.');
end;

var
  Card: TSmartCardReader;
  Contactless: TContactlessCardReader;
  Uid: TBytes;
  Model: TType2TagModel;
  Memory: TType2UserMemory;
begin
  if not (ParamCount in [2, 4]) or (ParamStr(1) = '--help') then
  begin
    Writeln('Usage: InspectContactless <exact-reader-name> --pcsc-storage');
    Writeln('       InspectContactless <exact-reader-name> --pcsc-storage --type2 <model>');
    Writeln('Models: ultralight, ev1-48, ev1-128, ntag213, ntag215, ntag216.');
    Writeln('Use only with a reader/driver supporting the storage pseudo-APDU profile.');
    Writeln('Reports UID length and optional user-memory size; never authenticates or writes.');
    Halt(0);
  end;
  try
    if ParamStr(2) <> '--pcsc-storage' then raise EContactlessError.Create('Explicit supported profile required.');
    Model := ttmUltralight;
    if ParamCount = 4 then
    begin
      if ParamStr(3) <> '--type2' then raise EType2DataError.Create('Explicit Type 2 mode required.');
      Model := ParseType2Model(ParamStr(4));
    end;
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
        if ParamCount = 4 then
        begin
          Memory := Contactless.ReadType2UserMemory(Model);
          Writeln('User pages: ', Memory.PageCount);
          Writeln('User bytes: ', Length(Memory.Data));
        end;
        Card.Disconnect;
      finally Contactless.Free; end;
    finally Card.Free; end;
  except
    on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
