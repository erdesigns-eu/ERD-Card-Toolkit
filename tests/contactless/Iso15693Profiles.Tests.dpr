program Iso15693ProfilesTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Contactless,
 ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.Type5.Ndef, ERD.Card.Ndef;
type
 TWireReader=class(TInterfacedObject,ICardTransport,ICardTransaction)
 public
  IsSlix,Extended,Is64,PayloadOnly,WrongChip,WrongGeometry,MissingReference,BadAck,BadRandom,FailEnd:Boolean;
  Calls,Begins,Ends,Auths,Randoms,Reads,Writes,FailAt,BadReadAt,MultiCalls:Integer;
  Memory:TBytes;
  function Exchange(const ACommand:TBytes):TBytes;
  procedure BeginTransaction;
  procedure EndTransaction;
 end;
var Assertions:Integer;
procedure Check(const B:Boolean;const M:string);
begin Inc(Assertions);if not B then raise Exception.Create(M);end;
procedure TWireReader.BeginTransaction;begin Inc(Begins);end;
procedure TWireReader.EndTransaction;begin Inc(Ends);if FailEnd then raise Exception.Create('release');end;
function TWireReader.Exchange(const ACommand:TBytes):TBytes;
var C,Expected,WireUid,Info,Data:TBytes;First,Count,N:Integer;
begin
 Inc(Calls);if Calls=FailAt then raise Exception.Create('injected');
 if IsSlix then WireUid:=HexToBytes('05040302080104E0') else WireUid:=HexToBytes('05040302012402E0');
 if Extended then WireUid[5]:=$26;
 if WrongChip then WireUid[6]:=$05;
 if BytesEqual(ACommand,HexToBytes('FFCA800000')) then begin
  SetLength(Result,11);Result[0]:=0;Move(WireUid[0],Result[1],8);Result[9]:=$90;Result[10]:=0;Exit;
 end;
 Check((Length(ACommand)>=14) and (ACommand[0]=$FF) and (ACommand[1]=$FB) and
  (ACommand[2]=0) and (ACommand[3]=$22) and (ACommand[4]=Length(ACommand)-5),'FF-FB envelope');
 C:=Copy(ACommand,5,Length(ACommand)-5);Data:=nil;
 case C[0] of
  $2B,$3B:begin
   if Extended then Info:=HexToBytes('1C05040302012602E0FF010326')
   else if IsSlix then Info:=HexToBytes('0405040302080104E04F03')
   else Info:=HexToBytes('0C05040302012402E07F0324');
   if Is64 then Info:=HexToBytes('1C05040302012602E0FF070326');
   if WrongChip then Info[7]:=$05;
   if WrongGeometry then Info[9]:=$4F;
   if MissingReference and not IsSlix then begin Info[0]:=Info[0] and $F7;SetLength(Info,Length(Info)-1);end;
   Data:=Info;
  end;
  $B2:begin
   Check(BytesEqual(ACommand,HexToBytes('FFFB00220AB20405040302080104E0')),'Literal SLIX2 random request');
   Inc(Randoms);Data:=HexToBytes('1234');if BadRandom then Data:=HexToBytes('12');
  end;
  $B3:begin
   if IsSlix then begin
    if Auths=0 then Expected:=HexToBytes('FFFB00220FB30405040302080104E00103162170')
    else Expected:=HexToBytes('FFFB00220FB30405040302080104E002477265BC');
   end else if Extended then Expected:=HexToBytes('FFFB002213B30205040302012602E0011122334455667788')
   else Expected:=HexToBytes('FFFB002213B30205040302012402E0011122334455667788');
   Check(BytesEqual(ACommand,Expected),'Independent literal password wire bytes');Inc(Auths);
   if BadAck then Data:=HexToBytes('00');
  end;
  $20,$30,$23,$33,$21,$31,$2C,$3C:begin
   First:=C[9];N:=10;if C[0] in [$30,$33,$31,$3C] then begin First:=First+256*C[10];N:=11;end;
   Count:=1;
   if C[0] in [$23,$33] then begin
    Count:=1+C[N];if C[0]=$33 then Count:=Count+256*C[N+1];Inc(MultiCalls);
    if (not Extended) and (not IsSlix) then begin
     if MultiCalls=1 then Check(BytesEqual(ACommand,HexToBytes('FFFB00220B2305040302012402E0023B')),'Literal first 60-block chunk')
     else Check(BytesEqual(ACommand,HexToBytes('FFFB00220B2305040302012402E03E00')),'Literal final chunk');
    end;
   end;
   Check((First>=0) and ((First+Count)*4<=Length(Memory)),'Acquired memory range');
   if C[0] in [$20,$30,$23,$33] then begin
    Inc(Reads);Data:=Copy(Memory,First*4,Count*4);if Reads=BadReadAt then SetLength(Data,Length(Data)-1);
   end else if C[0] in [$2C,$3C] then Data:=HexToBytes('00')
   else begin Inc(Writes);Check(Length(C)=N+4,'Full block write');Move(C[N],Memory[First*4],4);end;
  end;
 else raise Exception.Create('unexpected command');end;
 if PayloadOnly then Result:=CopyBytes(Data) else begin
  SetLength(Result,Length(Data)+1);Result[0]:=0;if Length(Data)>0 then Move(Data[0],Result[1],Length(Data));
 end;
 N:=Length(Result);SetLength(Result,N+2);Result[N]:=$90;Result[N+1]:=0;
end;
function Backend(const Slix:Boolean;out W:TWireReader;const Extended:Boolean=False;
 const PayloadOnly:Boolean=False):IIso15693Session;
var T:ICardTransport;Mode:TIso15693AddressMode;Fmt:TIso15693ResponseFormat;I:Integer;
begin
 W:=TWireReader.Create;T:=W;W.IsSlix:=Slix;W.Extended:=Extended;W.PayloadOnly:=PayloadOnly;
 if Slix then SetLength(W.Memory,320) else if Extended then SetLength(W.Memory,2048) else SetLength(W.Memory,512);
 for I:=0 to High(W.Memory) do W.Memory[I]:=$AA;
 Mode:=iam8Bit;if Extended then Mode:=iam16Bit;Fmt:=irfNativeFlags;if PayloadOnly then Fmt:=irfPayloadOnly;
 Result:=TAcr1552Iso15693Session.Create(T,Mode,Fmt);
end;
function Passwords(const Slix:Boolean):TIso15693Passwords;
begin
 Result:=nil;if Slix then SetLength(Result,2) else SetLength(Result,1);
 Result[0].Identifier:=1;Result[0].Value:=HexToBytes('11223344');
 if Slix then begin Result[1].Identifier:=2;Result[1].Value:=HexToBytes('55467788');end
 else Result[0].Value:=HexToBytes('1122334455667788');
end;
procedure TestCodec;
var Failed:Boolean;I:Integer;B:TBytes;
begin
 Check(BytesToHex(TIso15693Codec.MultipleReadCommand(HexToBytes('E002240102030405'),iam8Bit,255,1))=
  'FFFB00220B2305040302012402E0FF00','8-bit last address');
 Check(BytesToHex(TIso15693Codec.MultipleReadCommand(HexToBytes('E002260102030405'),iam16Bit,256,257))=
  'FFFB00220D3305040302012602E000010001','16-bit count/address little endian');
 for I:=0 to 4 do begin
  Failed:=False;try
   case I of
    0:B:=TIso15693Codec.MultipleReadCommand(HexToBytes('E002240102030405'),iam8Bit,255,2);
    1:B:=TIso15693Codec.MultipleReadCommand(HexToBytes('E002240102030405'),iam16Bit,65535,2);
    2:B:=TIso15693Codec.MultipleReadCommand(HexToBytes('E002240102030405'),iam8Bit,0,0);
    3:B:=TIso15693Codec.CustomCommand(HexToBytes('E002240102030405'),4,$B3,nil);
    4:B:=TIso15693Codec.CustomCommand(HexToBytes('E002240102030405'),2,$20,nil);
   end;
  except on E:EIso15693Error do Failed:=True;end;Check(Failed,'Invalid codec arguments');
 end;
end;
procedure TestBulk;
var S:IIso15693Session;W:TWireReader;C:TIso15693CardReader;B:TBytes;Failed:Boolean;I,N:Integer;
begin
 for I:=0 to 1 do begin
  S:=Backend(False,W,False,I=1);C:=TIso15693CardReader.Create(nil);
  try C.Session:=S;C.UseMultipleBlockRead:=True;B:=C.ReadBlocks(2,61);
   Check((Length(B)=244) and (W.MultiCalls=2) and (W.Reads=2) and (W.Ends=1),'Bounded native bulk chain');
  finally C.Free;end;S:=nil;
 end;
 S:=Backend(False,W,True);C:=TIso15693CardReader.Create(nil);
 try C.Session:=S;C.UseMultipleBlockRead:=True;B:=C.ReadBlocks(256,61);
  Check((Length(B)=244) and (W.MultiCalls=2),'Extended bulk adapter');
 finally C.Free;end;S:=nil;
 S:=Backend(False,W);S.BeginSession;W.BadReadAt:=1;
 Failed:=False;try (S as IIso15693BlockReader).ReadMultipleBlocks(2,61);except on E:EIso15693Error do Failed:=True;end;
 Check(Failed,'Truncated chunk rejected');N:=W.Calls;Failed:=False;
 try S.ReadBlock(2);except on E:EIso15693Error do Failed:=True;end;
 Check(Failed and (N=W.Calls),'Failed bulk poisons session');S.EndSession;S:=nil;
end;
procedure TestPasswords;
var Inner,S:IIso15693Session;W:TWireReader;P:TIso15693Passwords;C:TIso15693CardReader;
 Profile:TIso15693PasswordProfile;I,J,N:Integer;Failed:Boolean;Info:TIso15693SystemInfo;B:TBytes;
begin
 for I:=0 to 1 do begin
  Inner:=Backend(I=0,W);P:=Passwords(I=0);Profile:=TIso15693PasswordProfile(I);
  S:=TIso15693PasswordSession.Create(Inner,Profile,P);FillChar(P[0].Value[0],Length(P[0].Value),0);
  C:=TIso15693CardReader.Create(nil);
  try C.Session:=S;B:=C.ReadBlocks(2,1);Check((Length(B)=4) and (W.Auths=2-I),'Owned passwords/read chain');
   W.Auths:=0;C.WriteBlock(2,HexToBytes('01020304'));
   Check((W.Writes=1) and (BytesToHex(Copy(W.Memory,8,4))='01020304'),'Authenticated verified write');
  finally C.Free;end;
  S:=nil;Inner:=nil;
 end;
 for J:=1 to 6 do begin
  Inner:=Backend(True,W);P:=Passwords(True);S:=TIso15693PasswordSession.Create(Inner,ippSlix2,P);W.FailAt:=J;
  Failed:=False;try Info:=S.BeginSession;except on E:Exception do Failed:=True;end;
  Check(Failed and (W.Ends=1),'Every acquisition/password I/O failure releases once');
  N:=W.Calls;Failed:=False;try S.ReadBlock(2);except on E:EIso15693Error do Failed:=True;end;
  Check(Failed and (N=W.Calls),'Failed auth never exposes data');S:=nil;Inner:=nil;
 end;
 for I:=0 to 3 do begin
  Inner:=Backend(True,W);P:=Passwords(True);S:=TIso15693PasswordSession.Create(Inner,ippSlix2,P);
  W.WrongChip:=I=0;W.BadRandom:=I=1;W.BadAck:=I=2;
  if I=3 then P[0].Identifier:=2;
  if I<3 then begin
   Failed:=False;try S.BeginSession;except on E:Exception do Failed:=True;end;
   Check(Failed and (W.Ends=1),'Chip/random/ack rejection');if I=0 then Check(W.Auths=0,'Wrong chip has no password attempt');
  end else begin
   S.BeginSession;Failed:=False;N:=W.Calls;
   try S.WriteBlock(79,HexToBytes('01020304'));except on E:EIso15693Error do Failed:=True;end;
   Check(Failed and (N=W.Calls),'SLIX2 counter reserved');W.FailEnd:=True;
   try S.EndSession;except on E:Exception do ;end;W.FailEnd:=False;
   Check(W.Ends=1,'Release failure clears ownership');
  end;S:=nil;Inner:=nil;
 end;
end;
procedure TestPreflightAndUncertainty;
var Inner,S:IIso15693Session;W:TWireReader;P:TIso15693Passwords;C:TIso15693CardReader;
 I,N:Integer;Failed:Boolean;Profile:TIso15693PasswordProfile;
begin
 for I:=0 to 5 do begin
  Inner:=Backend(I<3,W);P:=Passwords(I<3);Profile:=ippSlix2;if I>=3 then Profile:=ippSt25Dv;
  case I of
   0:P:=nil;
   1:P[1].Identifier:=1;
   2:SetLength(P[0].Value,3);
   3:P[0].Identifier:=0;
   4:begin SetLength(P,2);P[1].Identifier:=2;P[1].Value:=HexToBytes('1122334455667788');end;
   5:SetLength(P[0].Value,7);
  end;
  Failed:=False;try S:=TIso15693PasswordSession.Create(Inner,Profile,P);
  except on E:EIso15693Error do Failed:=True;end;
  Check(Failed and (W.Calls=0) and (W.Begins=0),'Credential preflight without hardware');Inner:=nil;
 end;
 for I:=0 to 2 do begin
  Inner:=Backend(False,W);P:=Passwords(False);S:=TIso15693PasswordSession.Create(Inner,ippSt25Dv,P);
  C:=TIso15693CardReader.Create(nil);
  try
   C.Session:=S;
   case I of 0:W.FailAt:=6;1:W.BadReadAt:=2;2:W.FailEnd:=True;end;
   Failed:=False;try C.WriteBlock(2,HexToBytes('01020304'));
   except on E:EContactlessWriteUncertain do Failed:=True;end;
   Check(Failed and (W.Ends=1) and not C.Busy,'Dispatched authenticated write uncertainty');
   if I=0 then Check(W.Writes=0,'Failed dispatch is not replayed') else Check(W.Writes=1,'One write only');
  finally C.Free;end;S:=nil;Inner:=nil;
 end;
 Inner:=Backend(False,W);P:=Passwords(False);S:=TIso15693PasswordSession.Create(Inner,ippSt25Dv,P);
 S.BeginSession;W.BadReadAt:=1;Failed:=False;
 try S.ReadBlock(2);except on E:EIso15693Error do Failed:=True;end;
 Check(Failed,'Authenticated malformed read');N:=W.Calls;Failed:=False;
 try S.SecurityStatus(2);except on E:EIso15693Error do Failed:=True;end;
 Check(Failed and (W.Calls=N),'Wrapper poisons further I/O');S.EndSession;S:=nil;Inner:=nil;
end;

procedure TestSt25Identities;
var Inner,S:IIso15693Session;W:TWireReader;P:TIso15693Passwords;
 Info:TIso15693SystemInfo;I:Integer;Failed:Boolean;
begin
 for I:=0 to 2 do begin
  Inner:=Backend(False,W,I>0);W.Is64:=I=2;if W.Is64 then SetLength(W.Memory,8192);
  P:=Passwords(False);S:=TIso15693PasswordSession.Create(Inner,ippSt25Dv,P);
  Info:=S.BeginSession;Check((Info.BlockCount*4=Length(W.Memory)) and (W.Auths=1),'ST25DV04K/16K/64K identity');
  S.EndSession;S:=nil;Inner:=nil;
 end;
 for I:=0 to 1 do begin
  Inner:=Backend(False,W);W.WrongGeometry:=I=0;W.MissingReference:=I=1;
  P:=Passwords(False);S:=TIso15693PasswordSession.Create(Inner,ippSt25Dv,P);
  Failed:=False;try S.BeginSession;except on E:EIso15693Error do Failed:=True;end;
  Check(Failed and (W.Auths=0) and (W.Ends=1),'ST25 chip identity fails before credential dispatch');
  S:=nil;Inner:=nil;
 end;
end;

procedure TestNdef;
var Inner,S:IIso15693Session;W:TWireReader;P:TIso15693Passwords;C:TType5NdefCardReader;
 Snapshot:TType5NdefSnapshot;M:TNdefMessage;I:Integer;
begin
 Inner:=Backend(False,W);P:=Passwords(False);S:=TIso15693PasswordSession.Create(Inner,ippSt25Dv,P);
 for I:=0 to High(W.Memory) do W.Memory[I]:=0;
 W.Memory[0]:=$E1;W.Memory[1]:=$40;W.Memory[2]:=$3F;W.Memory[4]:=3;W.Memory[6]:=$FE;
 C:=TType5NdefCardReader.Create(nil);
 try
  C.Session:=S;Snapshot:=C.ReadMessage;Check(Length(Snapshot.MessageBytes)=0,'Authenticated empty Type 5');
  W.Auths:=0;M:=TNdefCodec.Decode(HexToBytes('D101065402656E616263'));C.WriteMessage(M);
  W.Auths:=0;Snapshot:=C.ReadMessage;
  Check(BytesToHex(Snapshot.MessageBytes)='D101065402656E616263','Authenticated Type 5 verified write/read');
 finally C.Free;end;S:=nil;Inner:=nil;
end;
begin
 try TestCodec;TestBulk;TestPasswords;TestPreflightAndUncertainty;TestSt25Identities;TestNdef;
  Writeln('PASS: ',Assertions,' ISO 15693 bulk/profile/password/Type 5 assertions.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
