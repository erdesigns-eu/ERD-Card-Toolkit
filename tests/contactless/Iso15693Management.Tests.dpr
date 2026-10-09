program Iso15693ManagementTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes,ERD.Card.Transport,ERD.Card.Contactless,ERD.Card.Contactless.ISO15693;
type
 TTestReader=class(TInterfacedObject,ICardTransport,ICardTransaction)
 public
  Slix,PayloadOnly,Active,Transparent,Vcc,FailEnd,BadManage,SwapUid,SuppressWrite,BadVerify:Boolean;
  Calls,Begins,Ends,Resets,Auths,Writes,FailCall,MalformedAt,AfterWriteFailureAt:Integer;
  Pwd:array[0..3] of TBytes;
  Authenticated:array[0..3] of Boolean;
  NxpInfo,StConfig:TBytes;
  Manager:TIso15693SecurityManager;
  ReenterChecks:Integer;
  procedure BeginTransaction;
  procedure EndTransaction;
  function Exchange(const ACommand:TBytes):TBytes;
 end;
 TWithoutReset=class(TInterfacedObject,IIso15693Session,IIso15693CustomCommands)
 public
  Inner:IIso15693Session;
  function BeginSession:TIso15693SystemInfo;
  procedure EndSession;
  function ReadBlock(const ABlock:Integer):TBytes;
  function SecurityStatus(const ABlock:Integer):Byte;
  procedure WriteBlock(const ABlock:Integer;const AData:TBytes);
  function ExchangeCustom(const AManufacturer,ACommand:Byte;const AParameters:TBytes):TBytes;
 end;
var Assertions:Integer;
function TWithoutReset.BeginSession:TIso15693SystemInfo;begin Result:=Inner.BeginSession;end;
procedure TWithoutReset.EndSession;begin Inner.EndSession;end;
function TWithoutReset.ReadBlock(const ABlock:Integer):TBytes;begin Result:=Inner.ReadBlock(ABlock);end;
function TWithoutReset.SecurityStatus(const ABlock:Integer):Byte;begin Result:=Inner.SecurityStatus(ABlock);end;
procedure TWithoutReset.WriteBlock(const ABlock:Integer;const AData:TBytes);begin Inner.WriteBlock(ABlock,AData);end;
function TWithoutReset.ExchangeCustom(const AManufacturer,ACommand:Byte;const AParameters:TBytes):TBytes;
begin Result:=(Inner as IIso15693CustomCommands).ExchangeCustom(AManufacturer,ACommand,AParameters);end;
procedure Check(const B:Boolean;const M:string);
begin Inc(Assertions);if not B then raise Exception.Create(M);end;
procedure TTestReader.BeginTransaction;
begin Check(not Active,'Non-nested transaction');Inc(Begins);Active:=True;end;
procedure TTestReader.EndTransaction;
begin Check(Active,'Owned release');Active:=False;Inc(Ends);if FailEnd then raise Exception.Create('release');end;
function TTestReader.Exchange(const ACommand:TBytes):TBytes;
var C,B,U,Param,Value,Expected:TBytes;N,I,Id:Integer;Failed:Boolean;
begin
 Check(Active,'Exclusive command');Inc(Calls);
 if Calls=FailCall then raise Exception.Create('exchange');
 if (Writes>0) and (AfterWriteFailureAt>0) then begin
  Dec(AfterWriteFailureAt);if AfterWriteFailureAt=0 then raise Exception.Create('after write');
 end;
 if Manager<>nil then begin
  Check(Manager.Busy,'Busy throughout transport callback');Failed:=False;
  try Manager.Session:=nil;except on E:EIso15693Error do Failed:=True;end;
  Check(Failed,'Configuration cannot change during I/O');Inc(ReenterChecks);
 end;
 U:=HexToBytes('05040302012402E0');if Slix then U:=HexToBytes('05040302080104E0');
 if BytesEqual(ACommand,HexToBytes('FFCA800000')) then begin
  B:=nil;SetLength(B,9);B[0]:=0;Move(U[0],B[1],8);
 end else if (Length(ACommand)>4) and (ACommand[1]=$C2) then begin
  Check(BytesEqual(Copy(ACommand,0,4),HexToBytes('FFC20000')),'Manage session header');
  Check(ACommand[4]=Length(ACommand)-5,'Manage session Lc');C:=Copy(ACommand,5,Length(ACommand)-5);
  if BytesEqual(C,HexToBytes('8100')) then begin Check(not Transparent,'Start transparent once');Transparent:=True;end
  else if BytesEqual(C,HexToBytes('83005F4604102700008400')) then begin
   Check(Transparent,'RF cycle in transparent session');Inc(Resets);
   for I:=0 to 3 do Authenticated[I]:=False;
  end else if BytesEqual(C,HexToBytes('8200')) then Transparent:=False
  else raise Exception.Create('Wrong RF timer/reset packet');
  B:=HexToBytes('C003009000');if BadManage then B:=HexToBytes('C003016401');
 end else begin
  Check((Length(ACommand)>=14) and (ACommand[0]=$FF) and (ACommand[1]=$FB) and
   (ACommand[3]=$22) and (ACommand[4]=Length(ACommand)-5),'Addressed FF-FB envelope');
  C:=Copy(ACommand,5,Length(ACommand)-5);B:=nil;
  if C[0]=$2B then begin
   if Slix then B:=HexToBytes('0405040302080104E04F03') else B:=HexToBytes('0C05040302012402E07F0324');
   if SwapUid and (Resets>0) then B[1]:=$99;
  end else begin
   Check(BytesEqual(Copy(C,2,8),U),'Manufacturer-command acquired UID');Param:=Copy(C,10,Length(C)-10);
   if Slix then Check(C[1]=4,'NXP manufacturer') else Check(C[1]=2,'ST manufacturer');
   case C[0] of
    $B2:begin Check(Slix and (Length(Param)=0),'NXP random');B:=HexToBytes('1234');end;
    $B3:begin
     Inc(Auths);Id:=Param[0];Value:=Copy(Param,1,Length(Param)-1);
     Expected:=HexToBytes('1234');
     if Slix then for I:=0 to 3 do Value[I]:=Value[I] xor Expected[I mod 2]
     else for I:=0 to 3 do Authenticated[I]:=False;
     Check((Id<=3) and (Length(Value)=Length(Pwd[Id])),'Password frame size/id');
     if not BytesEqual(Value,Pwd[Id]) then raise EIso15693StatusError.Create($0F);
     Authenticated[Id]:=True;
    end;
    $AB:begin Check(Slix,'AB NXP only');B:=CopyBytes(NxpInfo);if BadVerify and (Writes>0) then B[0]:=B[0] xor 1;end;
    $A0:begin
     Check(not Slix and (Length(Param)=1),'ST static read');Id:=Param[0]-4;if Param[0]=$0F then Id:=7;
     Check((Id>=0) and (Id<8),'Scoped static register');SetLength(B,1);B[0]:=StConfig[Id];
     if BadVerify and (Writes>0) and (Id=5) then B[0]:=B[0] xor 1;
    end;
    $AD:begin Check(BytesToHex(Param)='02','EH_CTRL_Dyn pointer');SetLength(B,1);B[0]:=0;if Vcc then B[0]:=8;end;
    $B4,$B1:begin
     Id:=Param[0];Check(Authenticated[Id],'Password write needs matching old authentication');
     Value:=Copy(Param,1,Length(Param)-1);
     if Slix then Expected:=HexToBytes('FFFB00220FB40405040302080104E00155667788')
     else Expected:=HexToBytes('FFFB002213B10205040302012402E0018877665544332211');
     if Slix and (Id=2) then Expected:=HexToBytes('FFFB00220FB40405040302080104E00255667788');
     if not Slix then case Id of
      0:Expected:=HexToBytes('FFFB002213B10205040302012402E0008877665544332211');
      2:Expected:=HexToBytes('FFFB002213B10205040302012402E0028877665544332211');
      3:Expected:=HexToBytes('FFFB002213B10205040302012402E0038877665544332211');
     end;
     Check(BytesEqual(ACommand,Expected),'Literal password replacement frame');Inc(Writes);
     if not SuppressWrite then Pwd[Id]:=CopyBytes(Value);
    end;
    $B6:begin
     Check(Slix and Authenticated[1] and Authenticated[2],'Protection requires both passwords');
     Check(BytesEqual(ACommand,HexToBytes('FFFB00220CB60405040302080104E00A23')),'Literal SLIX2 protection frame');
     Inc(Writes);if not SuppressWrite then begin NxpInfo[0]:=Param[0];NxpInfo[1]:=Param[1];end;
    end;
    $A1:begin
     Check(not Slix and Authenticated[0],'Static update requires configuration password');
     Check(BytesEqual(ACommand,HexToBytes('FFFB00220CA10205040302012402E006A6')),'Literal preserved RF policy frame');
     Inc(Writes);if not SuppressWrite then StConfig[Param[0]-4]:=Param[1];
    end;
   else raise Exception.Create('unexpected command');end;
  end;
  if not PayloadOnly then begin N:=Length(B);SetLength(B,N+1);if N>0 then Move(B[0],B[1],N);B[0]:=0;end;
 end;
 if Calls=MalformedAt then B:=HexToBytes('FF');
 Result:=B;N:=Length(Result);SetLength(Result,N+2);Result[N]:=$90;Result[N+1]:=0;
end;
function NewReader(const Slix:Boolean;out W:TTestReader):IIso15693Session;
var T:ICardTransport;I:Integer;
begin
 W:=TTestReader.Create;T:=W;W.Slix:=Slix;
 for I:=0 to 3 do W.Pwd[I]:=HexToBytes('1122334455667788');
 if Slix then begin W.Pwd[1]:=HexToBytes('11223344');W.Pwd[2]:=HexToBytes('99AABBCC');end;
 W.NxpInfo:=HexToBytes('0533007F070000');W.StConfig:=HexToBytes('0003A00400050000');
 Result:=TAcr1552Iso15693Session.Create(T,iam8Bit,irfNativeFlags);
end;
procedure TestDecoders;
var P:TSlix2Protection;S:TSt25RfConfiguration;Info:TIso15693SystemInfo;B:TBytes;I:Integer;Failed:Boolean;
begin
 P:=TIso15693Codec.DecodeSlix2Protection(HexToBytes('0533087F07008001020304'));
 Check((P.PointerBlock=5) and (P.Conditions=$33) and (P.LockBits=8) and (P.ExtendedFeatures=$04030201),'SLIX extended flags little endian');
 Info:=Default(TIso15693SystemInfo);Info.Uid:=HexToBytes('E002240102030405');Info.BlockCount:=128;
 Info.BlockSize:=4;Info.HasIcReference:=True;Info.IcReference:=$24;
 for I:=0 to 15 do begin
  B:=HexToBytes('0003000400050000');B[2]:=I;
  S:=TIso15693Codec.DecodeSt25Configuration(B,Info);
  Check((S.Areas[0].BlockCount=32) and (S.Areas[1].FirstBlock=32) and (S.Areas[1].BlockCount=8) and
   (S.Areas[3].FirstBlock=48) and (S.Areas[3].BlockCount=80),'ST boundaries');
  Check(S.Areas[1].PasswordNumber=I mod 4,'ST password selection');
  Check(S.Areas[1].ReadRequiresPassword=(I div 4>=2),'ST read protection');
 end;
 for I:=0 to 4 do begin
  Failed:=False;
  try case I of
   0:P:=TIso15693Codec.DecodeSlix2Protection(HexToBytes('4F00007F070000'));
   1:P:=TIso15693Codec.DecodeSlix2Protection(HexToBytes('0504007F070000'));
   2:P:=TIso15693Codec.DecodeSlix2Protection(HexToBytes('0500007F070080'));
   3:S:=TIso15693Codec.DecodeSt25Configuration(HexToBytes('0004000300050000'),Info);
   4:S:=TIso15693Codec.DecodeSt25Configuration(HexToBytes('0003000400050002'),Info);
  end;except on E:EIso15693Error do Failed:=True;end;Check(Failed,'Malformed configuration rejected');
 end;
 B:=HexToBytes('000F000F000F0000');S:=TIso15693Codec.DecodeSt25Configuration(B,Info);
 Check((S.Areas[0].BlockCount=128) and (S.Areas[1].BlockCount=0) and not S.Areas[1].WriteForbidden,'Inactive areas');
end;
procedure Perform(const M:TIso15693SecurityManager;const Kind:Integer;const Expected:TBytes);
begin
 case Kind of
  0:M.ChangeSlix2Password(1,HexToBytes('11223344'),HexToBytes('55667788'));
  1:M.ConfigureSlix2Protection(HexToBytes('11223344'),HexToBytes('99AABBCC'),Expected,10,$23);
  2:M.ChangeSt25Password(1,HexToBytes('1122334455667788'),HexToBytes('8877665544332211'),False);
  3:M.ConfigureSt25Area(2,HexToBytes('1122334455667788'),Expected,2,1,False);
 end;
end;
procedure TestSuccessful;
var M:TIso15693SecurityManager;W:TTestReader;S:IIso15693Session;B:TBytes;P:TSlix2Protection;C:TSt25RfConfiguration;I:Integer;
begin
 for I:=0 to 3 do begin
  S:=NewReader(I<2,W);M:=TIso15693SecurityManager.Create(nil);W.Manager:=M;
  try
   M.Session:=S;if I<2 then begin P:=M.ReadSlix2Protection;B:=P.Raw;end else begin C:=M.ReadSt25Configuration;B:=C.Raw;end;
   Check((W.Auths=0) and (W.Resets=0),'Public snapshot has no password or reset');
   Perform(M,I,B);
   Check((W.Writes=1) and (W.Resets=2) and (W.Begins=2) and (W.Ends=2) and not M.Busy,'Fresh verified mutation lifecycle');
   Check(W.ReenterChecks>0,'Busy setter exercised');
   if I=1 then Check(BytesToHex(W.NxpInfo)='0A23007F070000','Protection exact state');
   if I=3 then Check(BytesToHex(W.StConfig)='0003A60400050000','ST only policy changed');
  finally W.Manager:=nil;M.Free;end;S:=nil;
 end;
end;
procedure TestAdditionalCases;
var S:IIso15693Session;T:ICardTransport;W:TTestReader;M:TIso15693SecurityManager;
 I,N:Integer;P:TBytes;Failed:Boolean;NoRf:TWithoutReset;
begin
 for I:=0 to 3 do begin
  S:=NewReader(False,W);M:=TIso15693SecurityManager.Create(nil);
  try M.Session:=S;M.ChangeSt25Password(I,HexToBytes('1122334455667788'),HexToBytes('8877665544332211'),False);
   Check((W.Resets=2) and (W.Writes=1) and (W.Auths=2),'All RF password identifiers');
  finally M.Free;end;S:=nil;
 end;
 S:=NewReader(True,W);M:=TIso15693SecurityManager.Create(nil);
 try M.Session:=S;M.ChangeSlix2Password(2,HexToBytes('99AABBCC'),HexToBytes('55667788'));
  Check((W.Resets=2) and (W.Writes=1),'SLIX write-password rotation');
 finally M.Free;end;S:=nil;
 for I:=0 to 1 do begin
  S:=NewReader(I=0,W);M:=TIso15693SecurityManager.Create(nil);
  try
   M.Session:=S;P:=HexToBytes('11223344');if I=1 then P:=HexToBytes('1122334455667788');
   if I=0 then M.ChangeSlix2Password(1,P,P) else M.ChangeSt25Password(1,P,P,False);
   Check((W.Resets=1) and (W.Auths=1) and (W.Writes=0),'Same-password verified no-op');
   Check(BytesToHex(P)='11223344'+Copy('55667788',1,8*I),'Caller credential not wiped or changed');
  finally M.Free;end;S:=nil;
 end;
 S:=NewReader(False,W);W.Vcc:=True;M:=TIso15693SecurityManager.Create(nil);
 try M.Session:=S;M.ChangeSt25Password(1,HexToBytes('1122334455667788'),HexToBytes('8877665544332211'),True);
  Check(W.Writes=1,'Explicit stable external VCC');
 finally M.Free;end;S:=nil;
 S:=NewReader(True,W);T:=W;W.PayloadOnly:=True;
 S:=TAcr1552Iso15693Session.Create(T,iam8Bit,irfPayloadOnly);M:=TIso15693SecurityManager.Create(nil);
 try M.Session:=S;M.ChangeSlix2Password(1,HexToBytes('11223344'),HexToBytes('55667788'));
  Check((W.Writes=1) and (W.Resets=2),'Explicit stripped-payload reset/proof');
 finally M.Free;end;S:=nil;T:=nil;
 S:=NewReader(True,W);S.BeginSession;W.BadManage:=True;Failed:=False;
 try (S as IIso15693FieldReset).ResetField;except on E:EIso15693Error do Failed:=True;end;
 Check(Failed and not W.Transparent,'Manage TLV error rejects and ends transparent session');
 N:=W.Calls;Failed:=False;try (S as IIso15693FieldReset).ResetField;
 except on E:EIso15693Error do Failed:=True;end;
 Check(Failed and (W.Calls=N),'No automatic RF reset recovery');S.EndSession;S:=nil;
 S:=NewReader(True,W);NoRf:=TWithoutReset.Create;NoRf.Inner:=S;S:=NoRf;
 M:=TIso15693SecurityManager.Create(nil);
 try
  M.Session:=S;M.ReadSlix2Protection;N:=W.Calls;Failed:=False;
  try M.ChangeSlix2Password(1,HexToBytes('11223344'),HexToBytes('55667788'));
  except on E:EIso15693Error do Failed:=True;end;
  Check(Failed and (W.Calls=N) and (W.Begins=1),'No-reset backend reads snapshots but refuses mutation before I/O');
 finally M.Free;end;S:=nil;
end;

procedure TestFailures;
var S:IIso15693Session;W:TTestReader;M:TIso15693SecurityManager;B:TBytes;
 Kind,I,Total,N:Integer;Failed,Uncertain:Boolean;
begin
 for Kind:=0 to 3 do begin
  S:=NewReader(Kind<2,W);M:=TIso15693SecurityManager.Create(nil);
  try M.Session:=S;B:=CopyBytes(W.NxpInfo);if Kind>=2 then B:=CopyBytes(W.StConfig);Perform(M,Kind,B);Total:=W.Calls;finally M.Free;end;S:=nil;
  for I:=1 to Total do begin
   S:=NewReader(Kind<2,W);M:=TIso15693SecurityManager.Create(nil);
   try
    M.Session:=S;B:=CopyBytes(W.NxpInfo);if Kind>=2 then B:=CopyBytes(W.StConfig);W.FailCall:=I;
    Failed:=False;Uncertain:=False;
    try Perform(M,Kind,B);
    except on E:EContactlessWriteUncertain do begin Failed:=True;Uncertain:=True;end;
     on E:Exception do Failed:=True;end;
    Check(Failed and (W.Ends=1) and not W.Active and not M.Busy,'Every exchange failure cleans up');
    Check(W.Writes<=1,'Mutation never replayed');if W.Writes>0 then Check(Uncertain,'Post-write failures uncertain');
   finally M.Free;end;S:=nil;
  end;
  for I:=0 to 2 do begin
   S:=NewReader(Kind<2,W);M:=TIso15693SecurityManager.Create(nil);
   try
    M.Session:=S;B:=CopyBytes(W.NxpInfo);if Kind>=2 then B:=CopyBytes(W.StConfig);
    W.SuppressWrite:=I=0;W.BadVerify:=I=1;W.FailEnd:=I=2;
    if (I=1) and (Kind in [0,2]) then W.SuppressWrite:=True;
    Failed:=False;try Perform(M,Kind,B);except on E:EContactlessWriteUncertain do Failed:=True;end;
    Check(Failed and (W.Writes=1) and (W.Ends=1),'Wrong write/readback/release uncertain');
   finally M.Free;end;S:=nil;
  end;
 end;
 for I:=0 to 4 do begin
  S:=NewReader(I<2,W);M:=TIso15693SecurityManager.Create(nil);
  try
   M.Session:=S;B:=CopyBytes(W.NxpInfo);if I>=2 then B:=CopyBytes(W.StConfig);
   case I of 0:B[0]:=6;1:W.NxpInfo[2]:=8;2:B[1]:=4;3:W.StConfig[7]:=1;4:W.Vcc:=True;end;
   Failed:=False;
   try if I<2 then Perform(M,1,B) else Perform(M,3,B);except on E:EIso15693Error do Failed:=True;end;
   Check(Failed and (W.Writes=0) and (W.Ends=1),'Stale/locked/VCC preflight prevents write');
  finally M.Free;end;S:=nil;
 end;
 S:=NewReader(True,W);S.BeginSession;W.SwapUid:=True;Failed:=False;
 try (S as IIso15693FieldReset).ResetField;except on E:EIso15693Error do Failed:=True;end;
 Check(Failed,'Changed UID after reset');N:=W.Calls;Failed:=False;
 try S.ReadBlock(2);except on E:EIso15693Error do Failed:=True;end;
 Check(Failed and (W.Calls=N),'Reset failure poisons adapter');S.EndSession;S:=nil;
end;
begin
 try TestDecoders;TestSuccessful;TestAdditionalCases;TestFailures;Writeln('PASS: ',Assertions,' NFC-V RF-reset/password/protection management assertions.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
