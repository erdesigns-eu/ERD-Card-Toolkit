program AdminDesfire;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}
  SysUtils,Classes,
{$ELSE}
  System.SysUtils,System.Classes,
{$ENDIF}
  ERD.Card.Bytes,ERD.Card.Crypto,ERD.Card.Crypto.Windows,
  ERD.Card.PCSC.Api,ERD.Card.PCSC.Reader,ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2;
function Number(const Index,Maximum:Integer):Byte;
var Value:Integer;
begin
  if not TryStrToInt(ParamStr(Index),Value) or (Value<0) or (Value>Maximum) then
    raise EDesfireError.Create('Invalid explicit numeric argument.');Result:=Value;
end;
function HexByte(const Index:Integer):Byte;
var Bytes:TBytes;
begin Bytes:=HexToBytes(ParamStr(Index));if Length(Bytes)<>1 then raise EDesfireError.Create('One exact hex byte required.');Result:=Bytes[0];end;
function KeyFile(const Path:string):TBytes;
var Stream:TFileStream;
begin
  Result:=nil;Stream:=TFileStream.Create(Path,fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Size<>16 then raise EDesfireError.Create('AES key files contain exactly 16 raw bytes.');
    SetLength(Result,16);Stream.ReadBuffer(Result[0],16);
  finally Stream.Free;end;
end;
procedure Run;
var R:TDesfireCardReader;Card:TSmartCardReader;S:IDesfireManagement;
  Aid:Cardinal;Bytes,Key,NewKey,OldKey:TBytes;Action:string;Mode:TDesfireCommunication;
  AuthKey,Target,Version,FileId,ReadKey,WriteKey,RwKey,ChangeKey:Byte;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: AdminDesfire EXACT_READER AID_HEX ev1|ev2 KEY_FILE AUTH_KEY ACTION [ACTION_ARGUMENTS]');
    Writeln('Actions: free-memory | version KEY | key-settings SETTINGS_HEX');
    Writeln('         file-access FILE plain|mac|full READ WRITE READ_WRITE CHANGE');
    Writeln('         rotate-key TARGET VERSION_HEX NEW_KEY_FILE OLD_KEY_FILE_OR_DASH');
    Writeln('AID 000000 selects the PICC; free-memory is PICC-only. Keys/rights are decimal, E=14/F=15.');
    Writeln('Use - for OLD_KEY_FILE only when replacing the authenticated key; otherwise supply its current 16 raw bytes.');
    Writeln('Changes take immediate effect. New key is proven with fresh authentication and version verification.');
    Writeln('An uncertain outcome requires independent reconciliation; this example never retries a mutation.');
    Writeln('Use --plan for a hardware-free API explanation.');Exit;
  end;
  if (ParamCount=1) and (ParamStr(1)='--plan') then
  begin
    Writeln('AES administration: acquired free memory/version; verified settings/access; fresh-key authentication proof.');
    Writeln('Immediate operations share one acquired management session. No Abort rollback and no mutation replay.');Exit;
  end;
  if ParamCount<6 then raise EDesfireError.Create('Use --help for explicit arguments.');
  if not ((ParamStr(3)='ev1') or (ParamStr(3)='ev2')) then raise EDesfireError.Create('Explicit AES generation required.');
  Bytes:=HexToBytes(ParamStr(2));if Length(Bytes)<>3 then raise EDesfireError.Create('Three-byte AID required.');
  Aid:=(Cardinal(Bytes[0]) shl 16) or (Cardinal(Bytes[1]) shl 8) or Bytes[2];AuthKey:=Number(5,13);
  Action:=ParamStr(6);Target:=0;Version:=0;FileId:=0;Mode:=dfcFull;ReadKey:=0;WriteKey:=0;RwKey:=0;ChangeKey:=0;
  if Action='free-memory' then begin if (ParamCount<>6) or (Aid<>0) then raise EDesfireError.Create('PICC free-memory arguments required.');end
  else if Action='version' then begin if ParamCount<>7 then raise EDesfireError.Create('Explicit key number required.');Target:=Number(7,13);end
  else if Action='key-settings' then begin if ParamCount<>7 then raise EDesfireError.Create('Explicit settings byte required.');Version:=HexByte(7);end
  else if Action='file-access' then
  begin
    if (ParamCount<>12) or (Aid=0) then raise EDesfireError.Create('Explicit application/file/access arguments required.');
    FileId:=Number(7,31);
    if ParamStr(8)='plain' then Mode:=dfcPlain else if ParamStr(8)='mac' then Mode:=dfcMac
    else if ParamStr(8)<>'full' then raise EDesfireError.Create('Explicit communication mode required.');
    ReadKey:=Number(9,15);WriteKey:=Number(10,15);RwKey:=Number(11,15);ChangeKey:=Number(12,15);
  end
  else if Action='rotate-key' then
  begin
    if ParamCount<>10 then raise EDesfireError.Create('Explicit new/old key files required.');Target:=Number(7,13);Version:=HexByte(8);
    if ((Target=AuthKey) and (ParamStr(10)<>'-')) or ((Target<>AuthKey) and (ParamStr(10)='-')) then
      raise EDesfireError.Create('Old-key presence must match the explicit target.');
  end
  else raise EDesfireError.Create('Unknown explicit action.');
  R:=TDesfireCardReader.Create(nil);Card:=nil;Key:=nil;NewKey:=nil;OldKey:=nil;
  try
    Key:=KeyFile(ParamStr(4));
    if Action='rotate-key' then begin NewKey:=KeyFile(ParamStr(9));if ParamStr(10)<>'-' then OldKey:=KeyFile(ParamStr(10));end;
    R.AuthenticationKey:=Key;R.KeyNumber:=AuthKey;R.CryptoProvider:=TCardWindowsAesProvider.Create;
    R.MinimumCommunication:=dfcFull;if ParamStr(3)='ev1' then R.Security:=dfsEv1Aes else R.Security:=dfsEv2Aes;
    Card:=TSmartCardReader.Create(nil);Card.ReaderName:=UnicodeString(ParamStr(1));Card.ShareMode:=psmExclusive;Card.Connect;
    R.Transport:=Card.Transport;S:=R.OpenManagementSession(Aid);
    try
      try
        if Action='free-memory' then Writeln('Free bytes: ',S.ReadFreeMemory)
        else if Action='version' then Writeln('Key version: ',IntToHex(S.ReadKeyVersion(Target),2))
        else if Action='key-settings' then S.ChangeKeySettings(Version)
        else if Action='file-access' then S.ChangeFileAccess(FileId,Mode,ReadKey,WriteKey,RwKey,ChangeKey)
        else if Action='rotate-key' then S.ChangeAesKey(Target,Version,NewKey,OldKey);
        S.Close;
      except on E:Exception do begin Writeln('Outcome: ',Ord(S.Outcome));raise;end;end;
      Writeln('Outcome: ',Ord(S.Outcome));
    finally S:=nil;end;
    Card.Disconnect;
  finally S:=nil;R.Free;Card.Free;TCardCrypto.Clear(Key);TCardCrypto.Clear(NewKey);TCardCrypto.Clear(OldKey);end;
end;
begin
  try Run;except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
