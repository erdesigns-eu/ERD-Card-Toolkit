program LegacyMifareTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes,ERD.Card.Crypto,ERD.Card.Crypto.DES,ERD.Card.Transport,
{$IFDEF MSWINDOWS}ERD.Card.Crypto.Windows,{$ELSE}ERD.Card.Crypto.OpenSSL,{$ENDIF}
 ERD.Card.Contactless,ERD.Card.Contactless.DESFire,ERD.Card.Contactless.DESFire.DES,
 ERD.Card.Contactless.DESFire.EV2,ERD.Card.Contactless.Raw,ERD.Card.Contactless.UltralightC,
 ERD.Card.Contactless.Type2.Password,LegacyMifare.Vectors;
type
 TFixed=class(TInterfacedObject,ICardAesProvider,ICardDesProvider)
  Base:ICardDesProvider;RandomFails:Boolean;
  function EncryptCbc(const K,V,D:TBytes):TBytes;function DecryptCbc(const K,V,D:TBytes):TBytes;
  function TripleDesCbc(const K,V,D:TBytes;const E:Boolean):TBytes;
  function RandomBytes(const N:Integer):TBytes;
 end;
 TScript=class(TInterfacedObject,ICardTransport,ICardTransaction,IRawContactlessReader)
  Pairs:TLegacyWirePairs;Calls,Begins,Ends,FailCall,CorruptCall,CorruptByte,CorruptBit:Integer;
  EndFails,Active:Boolean;
  function Exchange(const C:TBytes):TBytes;overload;
  function Exchange(const C:TBytes;const Bits:Integer):TRawRfResponse;overload;
  procedure BeginTransaction;procedure EndTransaction;procedure BeginSession;procedure EndSession;
  function Activate:TBytes;
 end;
var Checks:Integer=0;Base:ICardDesProvider;
procedure Check(B:Boolean;const Text:string);
begin Inc(Checks);if not B then raise Exception.Create(Text);end;
function TFixed.EncryptCbc(const K,V,D:TBytes):TBytes;begin Result:=Base.EncryptCbc(K,V,D);end;
function TFixed.DecryptCbc(const K,V,D:TBytes):TBytes;begin Result:=Base.DecryptCbc(K,V,D);end;
function TFixed.TripleDesCbc(const K,V,D:TBytes;const E:Boolean):TBytes;begin Result:=Base.TripleDesCbc(K,V,D,E);end;
function TFixed.RandomBytes(const N:Integer):TBytes;
begin if RandomFails then raise ECardCryptoError.Create('Test RNG failure.');Result:=Copy(HexToBytes('102132435465768798A9BACBDCEDFE0F'),0,N);end;
function TScript.Exchange(const C:TBytes):TBytes;
begin
 Inc(Calls);if Calls=FailCall then raise ECardTransportError.Create('Test transport failure.');
 if (Calls>Length(Pairs)) or not BytesEqual(C,HexToBytes(Pairs[Calls-1].Command)) then raise Exception.Create('Literal command mismatch at '+IntToStr(Calls));
 Result:=HexToBytes(Pairs[Calls-1].Response);
 if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
function TScript.Exchange(const C:TBytes;const Bits:Integer):TRawRfResponse;
begin Check(Bits=Length(C)*8,'Exact raw frame bit count');Result:=Default(TRawRfResponse);Result.Data:=Exchange(C);Result.BitCount:=Length(Result.Data)*8;if (Length(Result.Data)=1) then Result.BitCount:=4;end;
procedure TScript.BeginTransaction;begin Check(not Active,'Exclusive acquire');Active:=True;Inc(Begins);end;
procedure TScript.EndTransaction;begin Check(Active,'Owned release');Active:=False;Inc(Ends);if EndFails then raise ECardTransportError.Create('Test release failure.');end;
procedure TScript.BeginSession;begin BeginTransaction;end;
procedure TScript.EndSession;begin EndTransaction;end;
function TScript.Activate:TBytes;begin Result:=HexToBytes('04112233445566');end;
function Fixed:ICardDesProvider;
var P:TFixed;begin P:=TFixed.Create;P.Base:=Base;Result:=P;end;
function PairsFor(const Profile,Mode:Integer;const Write:Boolean):TLegacyWirePairs;
begin
 case Profile*10+Mode of
  0:if Write then Result:=D0M0W1 else Result:=D0M0W0;
  1:if Write then Result:=D0M1W1 else Result:=D0M1W0;
  3:if Write then Result:=D0M3W1 else Result:=D0M3W0;
  10:if Write then Result:=D1M0W1 else Result:=D1M0W0;
  11:if Write then Result:=D1M1W1 else Result:=D1M1W0;
  13:if Write then Result:=D1M3W1 else Result:=D1M3W0;
  20:if Write then Result:=D2M0W1 else Result:=D2M0W0;
  21:if Write then Result:=D2M1W1 else Result:=D2M1W0;
  23:if Write then Result:=D2M3W1 else Result:=D2M3W0;
  30:if Write then Result:=D3M0W1 else Result:=D3M0W0;
  31:if Write then Result:=D3M1W1 else Result:=D3M1W0;
  33:if Write then Result:=D3M3W1 else Result:=D3M3W0;
 else raise Exception.Create('Invalid test mode.');end;
end;
procedure Configure(R:TDesfireCardReader;S:TScript;Profile,Mode:Integer);
var K:TBytes;
begin
 R.Transport:=S;R.CryptoProvider:=Fixed;
 case Profile of
  0:R.Security:=dfsEv1TwoKey3Des;
  1:R.Security:=dfsEv1ThreeKey3Des;
  2:R.Security:=dfsD40Des;
  3:R.Security:=dfsD40TwoKey3Des;
 end;
 K:=HexToBytes('0123456789ABCDEFFEDCBA98765432100123456789ABCDEF');
 if Profile=1 then SetLength(K,24) else if Profile=2 then SetLength(K,8) else SetLength(K,16);
 R.AuthenticationKey:=K;R.MinimumCommunication:=dfcPlain;
end;
procedure TestDesfire;
var R:TDesfireCardReader;S:TScript;T:ICardTransport;P:TLegacyWirePairs;
 Mode,Profile,W,I,J,K,Limit:Integer;Failed,Uncertain:Boolean;B:TBytes;
begin
 R:=TDesfireCardReader.Create(nil);
 try
  for Profile:=0 to 3 do for Mode:=0 to 3 do if Mode<>2 then for W:=0 to 1 do begin
   P:=PairsFor(Profile,Mode,W=1);S:=TScript.Create;T:=S;S.Pairs:=P;Configure(R,S,Profile,Mode);
   if W=1 then R.WriteData($CDEF01,0,4,HexToBytes('AABBCCDD'))
   else begin B:=R.ReadData($CDEF01,0,4,4);Check(BytesToHex(B)='04050607','Independent DES profile read');end;
   Check((S.Calls=Length(P)) and (S.Ends=1) and not S.Active and not R.Busy,'Complete literal transcript and release');
   for I:=1 to Length(P) do begin
    S:=TScript.Create;T:=S;S.Pairs:=P;S.FailCall:=I;Configure(R,S,Profile,Mode);Failed:=False;Uncertain:=False;
    try if W=1 then R.WriteData($CDEF01,0,4,HexToBytes('AABBCCDD')) else B:=R.ReadData($CDEF01,0,4,4);
    except on E:Exception do begin Failed:=True;Uncertain:=E is EContactlessWriteUncertain;end;end;
    Check(Failed and (S.Calls=I) and (S.Ends=1) and not S.Active and not R.Busy,'Every I/O failure stops without replay');
    Check(Uncertain=((W=1) and (I>=7)),'Exact write dispatch uncertainty boundary');
   end;
   if W=0 then for I:=1 to Length(P)-1 do begin
    if (I=1) or (I=2) or (Profile<2) or ((I=4) and (Mode<>0)) then begin
     Limit:=Length(P[I].Response) div 2;
     for J:=0 to Limit-1 do for K:=0 to 7 do begin
      S:=TScript.Create;T:=S;S.Pairs:=P;S.CorruptCall:=I+1;S.CorruptByte:=J;S.CorruptBit:=K;Configure(R,S,Profile,Mode);Failed:=False;
      try B:=R.ReadData($CDEF01,0,4,4);except on E:Exception do Failed:=True;end;
      Check(Failed and (S.Ends=1) and not R.Busy,'Every protected-response bit fails closed');
     end;
    end;
   end;
  end;
 finally R.Free;T:=nil;end;
end;
procedure TestUlc;
var R:TUltralightCCardReaderWriter;S:TScript;T:IRawContactlessReader;P:TLegacyWirePairs;
 Key,Data:TBytes;Action,I,J,K:Integer;Failed,Uncertain:Boolean;Provider:TFixed;Keeper:ICardDesProvider;
begin
 R:=TUltralightCCardReaderWriter.Create(nil);Key:=HexToBytes('0123456789ABCDEFFEDCBA9876543210');
 try
  R.CryptoProvider:=Fixed;
  for Action:=0 to 2 do begin
   case Action of 0:P:=Uread;1:P:=Umemory;2:P:=Uwrite;end;
   S:=TScript.Create;T:=S;S.Pairs:=P;R.Reader:=S;
   case Action of 0:Data:=R.ReadUserPage(39,Key);1:Data:=R.ReadUserMemory(Key);2:Data:=R.WriteUserPageVerified(39,HexToBytes('AABBCCDD'),Key);end;
   if Action=0 then Check(BytesToHex(Data)='9C9D9E9F','Tail user-page READ stays before configuration');
   if Action=1 then Check((Length(Data)=144) and (Data[0]=16) and (Data[143]=159),'Complete user memory');
   if Action=2 then Check(BytesToHex(Data)='AABBCCDD','Independent user-write read-back');
   Check((S.Calls=Length(P)) and (S.Ends=1) and not R.Busy,'One authenticated RF session');
   for I:=1 to Length(P) do begin
    S:=TScript.Create;T:=S;S.Pairs:=P;S.FailCall:=I;R.Reader:=S;Failed:=False;Uncertain:=False;
    try case Action of 0:Data:=R.ReadUserPage(39,Key);1:Data:=R.ReadUserMemory(Key);2:Data:=R.WriteUserPageVerified(39,HexToBytes('AABBCCDD'),Key);end;
    except on E:Exception do begin Failed:=True;Uncertain:=E is EContactlessWriteUncertain;end;end;
    Check(Failed and (S.Ends=1) and not R.Busy,'Ulc every I/O failure cleans up');Check(Uncertain=((Action=2) and (I>=3)),'Ulc write boundary');
   end;
  end;
  P:=Uread;
  for I:=0 to High(P) do for J:=0 to Length(P[I].Response) div 2-1 do for K:=0 to 7 do begin
   S:=TScript.Create;T:=S;S.Pairs:=P;S.CorruptCall:=I+1;S.CorruptByte:=J;S.CorruptBit:=K;R.Reader:=S;Failed:=False;
   try Data:=R.ReadUserPage(39,Key);except on E:Exception do Failed:=True;end;
   Check(Failed and not R.Busy and (S.Ends=1),'Ulc mutual proof and CRC response bit corruption');
  end;
  Provider:=TFixed.Create;Provider.Base:=Base;Provider.RandomFails:=True;Keeper:=Provider;R.CryptoProvider:=Keeper;
  S:=TScript.Create;T:=S;S.Pairs:=Uread;R.Reader:=S;Failed:=False;
  try Data:=R.ReadUserPage(39,Key);except on E:Exception do Failed:=True;end;
  Check(Failed and (S.Calls=0) and (S.Ends=1) and not R.Busy,'ULC failed CSPRNG sends no authentication attempt');
  R.CryptoProvider:=Fixed;Keeper:=nil;
  S:=TScript.Create;T:=S;S.Pairs:=Uwrite;S.EndFails:=True;R.Reader:=S;Uncertain:=False;
  try Data:=R.WriteUserPageVerified(39,HexToBytes('AABBCCDD'),Key);except on E:EContactlessWriteUncertain do Uncertain:=True;end;
  Check(Uncertain and (S.Calls=4) and (S.Ends=1) and not R.Busy,'ULC verified write with failed release remains uncertain');
  for I:=0 to 47 do if (I<4) or (I>39) then begin
   S:=TScript.Create;T:=S;R.Reader:=S;Failed:=False;
   try Data:=R.WriteUserPageVerified(I,HexToBytes('AABBCCDD'),Key);except on E:EContactlessError do Failed:=True;end;
   Check(Failed and (S.Begins=0),'No manufacturer/configuration/key writes');
  end;
 finally R.Free;T:=nil;end;
end;
procedure TestChaining;
var Profile,I:Integer;R:TDesfireCardReader;T:TScript;Transport:ICardTransport;P:TLegacyWirePairs;Data:TBytes;
begin
 for Profile:=0 to 3 do
 begin
  case Profile of 0:P:=C0;1:P:=C1;2:P:=C2;3:P:=C3;end;
  R:=TDesfireCardReader.Create(nil);T:=TScript.Create;Transport:=T;T.Pairs:=P;
  try
   Configure(R,T,Profile,3);R.MaxFrameDataBytes:=16;SetLength(Data,32);for I:=0 to 31 do Data[I]:=128+I;
   R.WriteData($CDEF01,0,0,Data);
   Check((T.Calls=Length(P)) and (T.Ends=1),'DES full command/response AF chains verify once');
  finally R.Free;Transport:=nil;end;
 end;
end;
procedure TestSessions;
var Profile,Mode,I,FirstWrite,CommitCall:Integer;Failed:Boolean;R:TDesfireCardReader;Transport:ICardTransport;T:TScript;
 S:IDesfireSession;P:TLegacyWirePairs;
 procedure Workflow;
 begin
   S.WriteBackup(1,4,HexToBytes('AABBCCDD'));S.WriteBackup(1,6,HexToBytes('EEFF'));
   S.WriteBackup(1,6,HexToBytes('EEFF'));S.Credit(2,10);S.Debit(2,3);S.LimitedCredit(2,2);
   S.AppendRecord(3,HexToBytes('41424344'));S.AppendRecord(4,HexToBytes('51525354'));
   S.AppendRecord(4,HexToBytes('61626364'));S.ClearRecords(3);S.AppendRecord(3,HexToBytes('71727374'));
   S.Commit;
 end;
begin
 for Profile:=0 to 3 do for Mode:=0 to 3 do if Mode<>2 then
 begin
  case Profile*10+Mode of
   0:P:=S0M0;
   1:P:=S0M1;
   3:P:=S0M3;
   10:P:=S1M0;
   11:P:=S1M1;
   13:P:=S1M3;
   20:P:=S2M0;
   21:P:=S2M1;
   23:P:=S2M3;
   30:P:=S3M0;
   31:P:=S3M1;
   33:P:=S3M3;
  end;
  R:=TDesfireCardReader.Create(nil);T:=TScript.Create;Transport:=T;T.Pairs:=P;
  try
   Configure(R,T,Profile,Mode);S:=R.OpenSession($CDEF01,dsaFreshTransaction);
   R.Free;R:=nil; // Retained session owns its independent engine and credentials.
   Workflow;
   Check((S.Outcome=dsoCommitted) and S.VerificationSucceeded and not S.PendingChanges,'DES session commit independently verifies backup/value/records');
   Check((T.Calls=Length(P)) and (T.Begins=1) and (T.Ends=1),'Retained DES session exact transcript and release');
  finally S:=nil;R.Free;Transport:=nil;end;
  FirstWrite:=0;CommitCall:=0;
  for I:=0 to High(P) do begin
   if (Pos('903D',P[I].Command)=1) and (FirstWrite=0) then FirstWrite:=I+1;
   if Pos('90C7',P[I].Command)=1 then CommitCall:=I+1;
  end;
  Check((FirstWrite>0) and (CommitCall>FirstWrite),'Explicit transaction mutation boundaries');
  for I:=1 to Length(P) do
  begin
   R:=TDesfireCardReader.Create(nil);T:=TScript.Create;Transport:=T;T.Pairs:=P;T.FailCall:=I;S:=nil;Failed:=False;
   try
    Configure(R,T,Profile,Mode);
    try S:=R.OpenSession($CDEF01,dsaFreshTransaction);Workflow;except on E:Exception do Failed:=True;end;
    Check(Failed and (T.Calls=I) and (T.Ends=1) and not T.Active,'DES transaction every I/O failure releases without replay');
    if S<>nil then begin
     Check(not S.VerificationSucceeded,'Failed transaction never claims full verification');
     if I>CommitCall then Check(S.Outcome=dsoCommitted,'Known commit survives later readback failure')
     else if I>=FirstWrite then Check(S.Outcome=dsoUncertain,'Staged/commit failure stays uncertain')
     else Check(S.Outcome=dsoClosed,'Pre-mutation failure only closes');
     S.Close;Check(T.Ends=1,'Closing poisoned DES session sends no recovery command');
    end;
   finally S:=nil;R.Free;Transport:=nil;end;
  end;
 end;
end;
procedure TestCrypto;
var K,V,B,Original:TBytes;
begin
 K:=HexToBytes('0123456789ABCDEFFEDCBA9876543210');V:=HexToBytes('0000000000000000');Original:=CopyBytes(V);
 B:=TCardDesCrypto.Crypt(Base,K,V,V,True);Check(BytesToHex(B)='08D7B4FB629D0885','Two-key EDE known-answer block');
 Check(BytesEqual(TCardDesCrypto.Crypt(Base,K,V,B,False),V),'DES decrypt round trip');Check(BytesEqual(V,Original),'Borrowed IV unchanged');
 K:=HexToBytes('8AA83BF8CBDA10620BC1BF19FBB6CD58BC313D4A371CA8B5');
 B:=TCardDesCrypto.CmacChained(Base,K,V,nil);Check(BytesToHex(B)='B7A688E122FFAF95','NIST 800-38B TDEA empty CMAC');
end;
begin
 try
{$IFDEF MSWINDOWS}Base:=TCardWindowsAesProvider.Create;{$ELSE}Base:=TCardOpenSslAesProvider.Create;{$ENDIF}
 TestCrypto;TestUlc;TestDesfire;TestChaining;TestSessions;Writeln('PASS: ',Checks,' independent legacy MIFARE assertions.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
