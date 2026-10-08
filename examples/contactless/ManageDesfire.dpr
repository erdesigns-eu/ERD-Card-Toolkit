program ManageDesfire;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,Classes,
{$ELSE}
  System.SysUtils,System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.Windows,
  ERD.Card.PCSC.Api, ERD.Card.PCSC.Reader, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2;

function DemoFile(const Number:Integer):TDesfireFileDefinition;
begin
  Result:=Default(TDesfireFileDefinition); Result.FileNumber:=Number;
  Result.FileType:=TDesfireFileType(Number); Result.Communication:=dfcFull;
  // Explicit demo policy: all access routes use the application's supplied key 0.
  case Number of
    0,1:Result.FileBytes:=32;
    2:begin Result.LowerLimit:=0; Result.UpperLimit:=1000; Result.InitialValue:=100; Result.LimitedCreditEnabled:=True; end;
    3,4:begin Result.RecordBytes:=4; Result.MaxRecords:=8; end;
  end;
end;

procedure Perform(const S:IDesfireSession; const Action:string; const Aid:Cardinal);
var I:Integer;
begin
  if Action='create-application' then S.CreateApplication(Aid,$0F,1)
  else if Action='delete-application' then S.DeleteApplication(Aid)
  else if Action='create-files' then for I:=0 to 4 do S.CreateFile(DemoFile(I))
  else if Action='delete-files' then for I:=4 downto 0 do S.DeleteFile(I)
  else if Action='update-demo' then
  begin
    S.WriteBackup(1,0,HexToBytes('AABBCCDD'));
    S.Credit(2,5); S.Debit(2,2); S.LimitedCredit(2,1);
    S.AppendRecord(3,HexToBytes('01020304')); S.AppendRecord(4,HexToBytes('05060708'));
    S.Commit;
  end
  else if Action='clear-records' then
  begin
    S.ClearRecords(3); S.ClearRecords(4);
    if S.PendingChanges then S.Commit else S.Abort; // Empty record files require no native commit.
  end;
  S.Close;
end;

procedure Run;
var Reader:TDesfireCardReader; Card:TSmartCardReader; S:IDesfireSession;
  Aid,SelectedAid:Cardinal; Key,AidBytes:TBytes; Stream:TFileStream;
  Action,Ownership:string; Number,I:Integer; Access:TDesfireSessionAccess; D:TDesfireFileDefinition;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: ManageDesfire --plan');
    Writeln('       ManageDesfire --reader EXACT_NAME --aid NATIVE_HEX --profile ev1|ev2 --key-file PATH --key-number 0..13 --action ACTION --ownership POLICY');
    Writeln('Actions: create-application, delete-application, create-files, delete-files, update-demo, clear-records.');
    Writeln('Policies: manage for immediate administration; fresh-reset or discard-pending for transactional actions.');
    Writeln('fresh-reset attests your fresh reset/RF activation and exclusive ownership with no earlier pending changes.');
    Writeln('discard-pending explicitly aborts earlier application changes; an unverified 910C NoChanges fails closed.');
    Writeln('Exclusive Windows PC/SC; exact 16-byte raw AES key file; no implicit default-key authentication.');
    Writeln('Application actions select PICC key 0; file actions use nonzero AID and demo key 0 rights.');
    Writeln('Creation/deletion is immediate and cannot be undone with Abort. Use owned disposable test cards.');
    Exit;
  end;
  if (ParamCount=1) and (ParamStr(1)='--plan') then
  begin
    Writeln('Demo files: 5; Full communication; explicit key 0 for every access route.');
    for I:=0 to 4 do
    begin D:=DemoFile(I); Writeln('File ',I,' type ',Ord(D.FileType),' bytes ',D.FileBytes,' record bytes ',D.RecordBytes,' capacity ',D.MaxRecords); end;
    Writeln('Transaction: backup range, credit/debit/limited credit, linear/cyclic append, commit and complete verification.');
    Writeln('Application and file management takes immediate effect. No hardware commands were sent.'); Exit;
  end;
  if (ParamCount<>14) or (ParamStr(1)<>'--reader') or (ParamStr(3)<>'--aid') or
    (ParamStr(5)<>'--profile') or (ParamStr(7)<>'--key-file') or (ParamStr(9)<>'--key-number') or
    (ParamStr(11)<>'--action') or (ParamStr(13)<>'--ownership') or (Length(ParamStr(4))<>6) or
    not TryStrToInt(ParamStr(10),Number) or (Number<0) or (Number>13) then
    raise EDesfireError.Create('Use --help for explicit arguments.');
  AidBytes:=HexToBytes(ParamStr(4)); Aid:=(Cardinal(AidBytes[0]) shl 16) or (Cardinal(AidBytes[1]) shl 8) or AidBytes[2];
  if Aid=0 then raise EDesfireError.Create('Explicit nonzero target AID required.');
  Action:=ParamStr(12); Ownership:=ParamStr(14);
  if (Action='create-application') or (Action='delete-application') or (Action='create-files') or (Action='delete-files') then
  begin
    if Ownership<>'manage' then raise EDesfireError.Create('Management authority required.'); Access:=dsaManage;
  end
  else if (Action='update-demo') or (Action='clear-records') then
  begin
    if Ownership='fresh-reset' then Access:=dsaFreshTransaction
    else if Ownership='discard-pending' then Access:=dsaDiscardPending
    else raise EDesfireError.Create('Explicit transaction ownership required.');
  end
  else raise EDesfireError.Create('Unknown explicit action.');
  if not ((ParamStr(6)='ev1') or (ParamStr(6)='ev2')) then raise EDesfireError.Create('Explicit AES profile required.');
  SelectedAid:=Aid;
  if (Action='create-application') or (Action='delete-application') then
  begin if Number<>0 then raise EDesfireError.Create('PICC management requires supplied key 0.'); SelectedAid:=0; end;
  Reader:=TDesfireCardReader.Create(nil); Key:=nil;
  try
    Stream:=TFileStream.Create(ParamStr(8),fmOpenRead or fmShareDenyWrite);
    try
      if Stream.Size<>16 then raise EDesfireError.Create('Key file must contain exactly 16 raw bytes.');
      SetLength(Key,16); Stream.ReadBuffer(Key[0],16);
    finally Stream.Free; end;
    Reader.CryptoProvider:=TCardWindowsAesProvider.Create; Reader.AuthenticationKey:=Key; Reader.KeyNumber:=Number;
    Reader.MinimumCommunication:=dfcFull;
    if ParamStr(6)='ev1' then Reader.Security:=dfsEv1Aes else Reader.Security:=dfsEv2Aes;
    Card:=TSmartCardReader.Create(nil);
    try
      Card.ReaderName:=UnicodeString(ParamStr(2)); Card.ShareMode:=psmExclusive; Card.Connect;
      Reader.Transport:=Card.Transport;
      S:=Reader.OpenSession(SelectedAid,Access);
      try
        try Perform(S,Action,Aid);
        except on E:Exception do
          begin Writeln('Outcome: ',Ord(S.Outcome),' verified: ',S.VerificationSucceeded,' pending: ',S.PendingChanges); raise; end;
        end;
        Writeln('Outcome: ',Ord(S.Outcome),' verified: ',S.VerificationSucceeded,' pending: ',S.PendingChanges);
      finally S:=nil; end;
      Card.Disconnect;
    finally Card.Free; end;
  finally TCardCrypto.Clear(Key); Reader.Free; end;
end;

begin
  try Run; except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
