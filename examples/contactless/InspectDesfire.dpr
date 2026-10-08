program InspectDesfire;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,Classes,
{$ELSE}
  System.SysUtils,System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.Windows,
  ERD.Card.PCSC.Reader, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2;

procedure PrintSettings(const S:TDesfireFileSettings);
begin
  Writeln('File: ',S.FileNumber,' type: ',Ord(S.FileType),' communication: ',Ord(S.Communication));
  Writeln('Data bytes: ',S.FileBytes,' record bytes: ',S.RecordBytes,' records: ',S.CurrentRecords);
end;

procedure Run;
var Reader:TDesfireCardReader; Card:TSmartCardReader; Files:TDesfireFiles;
  Settings:TDesfireFileSettings; Aid:Cardinal; Number,I:Integer; AidBytes,Key:TBytes; Stream:TFileStream;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: InspectDesfire --settings-hex HEX --file 0..31');
    Writeln('       InspectDesfire --reader EXACT_NAME --aid NATIVE_HEX');
    Writeln('       InspectDesfire --reader EXACT_NAME --aid NATIVE_HEX --ev2-key-file PATH --key-number 0..13 --minimum plain|mac|full');
    Writeln('       Replace --ev2-key-file with --ev1-key-file for the explicit EV1 AES profile.');
    Writeln('Metadata only; native wrapped DESFire profile, no writes or key/UID/payload output.');
    Writeln('Key file is exactly 16 raw bytes. Never use production keys in test transcripts.'); Exit;
  end;
  if (ParamCount=4) and (ParamStr(1)='--settings-hex') then
  begin
    if (Length(ParamStr(2))>34) or (ParamStr(3)<>'--file') or
      not TryStrToInt(ParamStr(4),Number) or (Number<0) or (Number>31) then
      raise EDesfireError.Create('Invalid offline settings arguments.');
    Settings:=TDesfireCodec.FileSettings(Number,HexToBytes(ParamStr(2))); PrintSettings(Settings); Exit;
  end;
  if not (ParamCount in [4,10]) or (ParamStr(1)<>'--reader') or (ParamStr(3)<>'--aid') or
    (Length(ParamStr(4))<>6) then raise EDesfireError.Create('Use --help for supported arguments.');
  AidBytes:=HexToBytes(ParamStr(4)); Aid:=(Cardinal(AidBytes[0]) shl 16) or (Cardinal(AidBytes[1]) shl 8) or AidBytes[2];
  if Aid=0 then raise EDesfireError.Create('Select a nonzero application explicitly.');
  Key:=nil; Reader:=TDesfireCardReader.Create(nil);
  try
    if ParamCount=10 then
    begin
      if not ((ParamStr(5)='--ev2-key-file') or (ParamStr(5)='--ev1-key-file')) or (ParamStr(7)<>'--key-number') or (ParamStr(9)<>'--minimum') or
        not TryStrToInt(ParamStr(8),Number) or (Number<0) or (Number>13) then
        raise EDesfireError.Create('Invalid explicit AES profile arguments.');
      Stream:=TFileStream.Create(ParamStr(6),fmOpenRead or fmShareDenyWrite);
      try
        if Stream.Size<>16 then raise EDesfireError.Create('Authentication key file must contain exactly 16 raw bytes.');
        SetLength(Key,16); Stream.ReadBuffer(Key[0],16);
      finally Stream.Free; end;
      Reader.CryptoProvider:=TCardWindowsAesProvider.Create; Reader.AuthenticationKey:=Key;
      Reader.KeyNumber:=Number;
      if ParamStr(5)='--ev1-key-file' then Reader.Security:=dfsEv1Aes else Reader.Security:=dfsEv2Aes;
      if ParamStr(10)='plain' then Reader.MinimumCommunication:=dfcPlain
      else if ParamStr(10)='mac' then Reader.MinimumCommunication:=dfcMac
      else if ParamStr(10)='full' then Reader.MinimumCommunication:=dfcFull
      else raise EDesfireError.Create('Explicit minimum communication mode required.');
    end;
    Card:=TSmartCardReader.Create(nil);
    try
      Card.ReaderName:=UnicodeString(ParamStr(2)); Card.Connect;
      Reader.Transport:=Card.Transport; Files:=Reader.ReadFiles(Aid);
      Writeln('Files: ',Length(Files)); for I:=0 to High(Files) do PrintSettings(Files[I]);
      Card.Disconnect;
    finally Card.Free; end;
  finally TCardCrypto.Clear(Key); Reader.Free; end;
end;

begin
  try Run; except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
