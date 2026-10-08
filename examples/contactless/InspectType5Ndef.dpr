program InspectType5Ndef;

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
  ERD.Card.Bytes, ERD.Card.PCSC.Reader, ERD.Card.Contactless.ISO15693,
  ERD.Card.Contactless.Type5.Ndef;

procedure Run;
var Card:TSmartCardReader; Reader:TType5NdefCardReader; Info:TIso15693SystemInfo;
  Cc:TType5CapabilityContainer; Snapshot:TType5NdefSnapshot; Mode:TIso15693AddressMode;
  Format:TIso15693ResponseFormat; Blocks,BlockSize:Integer;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: InspectType5Ndef --cc-hex HEX --blocks COUNT --block-size SIZE --address 8|16');
    Writeln('       InspectType5Ndef --reader EXACT_NAME --address 8|16 --response native|payload');
    Writeln('CC mode is offline with explicit geometry. Card mode targets ACR1552 ISO15693 pass-through.');
    Writeln('Reads only; reports structure/lengths, never card UID or message contents.'); Exit;
  end;
  if (ParamCount=8) and (ParamStr(1)='--cc-hex') then
  begin
    if (Length(ParamStr(2))>16) or (ParamStr(3)<>'--blocks') or (ParamStr(5)<>'--block-size') or
      (ParamStr(7)<>'--address') or not TryStrToInt(ParamStr(4),Blocks) or
      not TryStrToInt(ParamStr(6),BlockSize) then raise EType5NdefError.Create('Invalid offline arguments.');
    Info:=Default(TIso15693SystemInfo); Info.Uid:=HexToBytes('E002010203040506');
    Info.BlockCount:=Blocks; Info.BlockSize:=BlockSize; Info.InformationFlags:=4;
    if ParamStr(8)='16' then Info.InformationFlags:=$14
    else if ParamStr(8)<>'8' then raise EType5NdefError.Create('Explicit address width required.');
    if (ParamStr(8)='8') and (Blocks>256) then raise EType5NdefError.Create('One-byte addresses allow at most 256 blocks.');
    Cc:=TType5NdefCodec.DecodeCapabilities(HexToBytes(ParamStr(2)),Info);
    Writeln('CC bytes: ',Cc.HeaderBytes,' data-area bytes: ',Cc.DataAreaBytes); Exit;
  end;
  if (ParamCount<>6) or (ParamStr(1)<>'--reader') or (ParamStr(3)<>'--address') or
    (ParamStr(5)<>'--response') then raise EType5NdefError.Create('Use --help for supported arguments.');
  if ParamStr(4)='8' then Mode:=iam8Bit else if ParamStr(4)='16' then Mode:=iam16Bit
  else raise EType5NdefError.Create('Explicit address width required.');
  if ParamStr(6)='native' then Format:=irfNativeFlags else if ParamStr(6)='payload' then Format:=irfPayloadOnly
  else raise EType5NdefError.Create('Explicit response convention required.');
  Card:=TSmartCardReader.Create(nil);
  try
    Reader:=TType5NdefCardReader.Create(nil);
    try
      Card.ReaderName:=UnicodeString(ParamStr(2)); Card.Connect;
      Reader.Session:=TAcr1552Iso15693Session.Create(Card.Transport,Mode,Format);
      Snapshot:=Reader.ReadMessage;
      Writeln('Blocks: ',Snapshot.Information.BlockCount,' block bytes: ',Snapshot.Information.BlockSize);
      Writeln('CC bytes: ',Snapshot.Capabilities.HeaderBytes,' data-area bytes: ',Snapshot.Capabilities.DataAreaBytes);
      Writeln('NDEF bytes: ',Length(Snapshot.MessageBytes),' records: ',Length(Snapshot.Records));
      Card.Disconnect;
    finally Reader.Free; end;
  finally Card.Free; end;
end;

begin
  try Run; except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
