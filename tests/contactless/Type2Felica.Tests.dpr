program Type2FelicaTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes,ERD.Card.Transport,ERD.Card.Contactless,ERD.Card.Contactless.Raw,
 ERD.Card.Contactless.Type2,ERD.Card.Contactless.Type2.Password,ERD.Card.Contactless.Type2.Ndef,
 ERD.Card.Contactless.Felica,ERD.Card.Contactless.ACR122.Felica,ERD.Card.Contactless.Type3.Ndef,
 Type2Felica.Vectors;
type
 TScript=class(TInterfacedObject,IFelicaReader,IRawContactlessReader,ICardTransport,ICardTransaction)
  Pairs:TProtocolPairs;Calls,Begins,Ends,Activations,FailCall,CorruptCall,CorruptByte,CorruptBit:Integer;
  Active,EndFails,SwapUid:Boolean;
  procedure BeginSession;procedure EndSession;procedure BeginTransaction;procedure EndTransaction;
  function Activate(const Code:Word):TFelicaTarget;overload;
  function Activate:TBytes;overload;
  function Exchange(const Frame:TBytes):TBytes;overload;
  function Exchange(const Frame:TBytes;const Bits:Integer):TRawRfResponse;overload;
 end;
var Checks:Integer=0;
procedure Check(const Value:Boolean;const Text:string);
begin Inc(Checks);if not Value then raise Exception.Create(Text);end;
procedure TScript.BeginSession;begin Check(not Active,'Exclusive acquisition');Active:=True;Inc(Begins);end;
procedure TScript.EndSession;begin Check(Active,'Owned release');Active:=False;Inc(Ends);if EndFails then raise ECardTransportError.Create('Synthetic release failure.');end;
procedure TScript.BeginTransaction;begin BeginSession;end;
procedure TScript.EndTransaction;begin EndSession;end;
function TScript.Activate(const Code:Word):TFelicaTarget;
begin Inc(Activations);Result.Idm:=HexToBytes('0102030405060708');Result.Pmm:=HexToBytes('1122334455667788');Result.SystemCode:=Code;end;
function TScript.Activate:TBytes;
begin Inc(Activations);Result:=HexToBytes('04112233445566');if SwapUid and (Activations>1) then Result[1]:=$22;end;
function TScript.Exchange(const Frame:TBytes):TBytes;
begin
 Inc(Calls);if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure.');
 if (Calls>Length(Pairs)) or not BytesEqual(Frame,HexToBytes(Pairs[Calls-1].Command)) then raise Exception.Create('Independent literal mismatch at exchange '+IntToStr(Calls));
 Result:=HexToBytes(Pairs[Calls-1].Response);
 if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
function TScript.Exchange(const Frame:TBytes;const Bits:Integer):TRawRfResponse;
begin
 Check(Bits=Length(Frame)*8,'Exact byte RF frame');Result:=Default(TRawRfResponse);Result.Data:=Exchange(Frame);Result.BitCount:=Length(Result.Data)*8;
 if Length(Result.Data)=1 then Result.BitCount:=4;
end;
function NewScript(const Name:string;out Held:IFelicaReader):TScript;
begin Result:=TScript.Create;Held:=Result;Result.Pairs:=ProtocolPairs(Name);end;
procedure TestNativeAdapter;
var T:TScript;Transport:ICardTransport;Reader:IFelicaReader;P:TProtocolPairs;Target:TFelicaTarget;
 Data:TBytes;Attempt,Rate:Integer;Failed:Boolean;
 procedure Pair(const Index:Integer;const Command,Response:string);
 begin P[Index].Command:=Command;P[Index].Response:=Response;end;
begin
 for Rate:=0 to 1 do begin
  SetLength(P,8);
  Pair(0,'FF00000006D43202000B0D','D5339000');
  Pair(1,'FF00000004D4320400','D5339000');
  Pair(2,'FF00000006D43205000000','D5339000');
  Pair(3,'FF00000004D4320100','D5339000');
  Pair(4,'FF00000004D4320101','D5339000');
  if Rate=0 then Pair(5,'FF00000009D44A01010012FC0100','D54B010114010102030405060708112233445566778812FC9000')
  else Pair(5,'FF00000009D44A01020012FC0100','D54B010114010102030405060708112233445566778812FC9000');
  Pair(6,'FF00000013D4400110060102030405060708010B00018000','D541001D070102030405060708000001000102030405060708090A0B0C0D0E0F9000');
  Pair(7,'FF00000004D4320100','D5339000');
  T:=TScript.Create;Transport:=T;T.Pairs:=P;Reader:=TAcr122FelicaReader.Create(Transport,TFelicaBitrate(Rate));
  Reader.BeginSession;Target:=Reader.Activate($12FC);
  Data:=Reader.Exchange(HexToBytes('10060102030405060708010B00018000'));Reader.EndSession;
  Check((T.Calls=8) and (T.Ends=1) and (BytesToHex(Target.Idm)='0102030405060708') and
    (BytesToHex(Data)='1D070102030405060708000001000102030405060708090A0B0C0D0E0F'),'Native PN532 polling/transport complete independent transcript');
  Reader:=nil;Transport:=nil;
  for Attempt:=1 to 8 do begin
   T:=TScript.Create;Transport:=T;T.Pairs:=P;T.FailCall:=Attempt;
   // Cleanup remains one RF-off attempt, even when native setup/selection/exchange fails.
   if Attempt<8 then begin SetLength(T.Pairs,Attempt+1);T.Pairs[Attempt].Command:='FF00000004D4320100';T.Pairs[Attempt].Response:='D5339000';end;
   Reader:=TAcr122FelicaReader.Create(Transport,TFelicaBitrate(Rate));Failed:=False;
   try
    Reader.BeginSession;
    try Target:=Reader.Activate($12FC);Data:=Reader.Exchange(HexToBytes('10060102030405060708010B00018000'));
    finally Reader.EndSession;end;
   except on E:Exception do Failed:=True;end;
   Check(Failed and (T.Ends=1) and not T.Active,'Native FeliCa every dispatch/release failure releases exclusivity');
   Check(T.Calls=Attempt+Ord(Attempt<8),'Native FeliCa never replays failed command');Reader:=nil;Transport:=nil;
  end;
 end;
end;

procedure TestManagementGuards;
var R:TType2PasswordCardReader;T:TScript;Held:IFelicaReader;C:TType2AuthenticationConfiguration;
 Password,Pack,Before,NewPassword,NewPack,Locked:TBytes;Failed,Uncertain:Boolean;
 T3:TType3NdefCardReader;S:TType3NdefSnapshot;A:TType3NdefAttribute;
begin
 Password:=HexToBytes('01020304');Pack:=HexToBytes('A1B2');Before:=HexToBytes('082200FF38556677');
 NewPassword:=HexToBytes('05060708');NewPack:=HexToBytes('C3D4');R:=TType2PasswordCardReader.Create(nil);
 try
  T:=NewScript('T2Config0',Held);R.Reader:=T;Failed:=False;
  try C:=R.ConfigureAuthenticationVerified(ttmUltralightEv1_48,4,True,3,HexToBytes('082201FF38556677'),Password,Pack);
  except on E:EContactlessError do Failed:=True;end;
  Check(Failed and (T.Calls=2) and (T.Ends=1),'Type 2 stale configuration never writes');
  T:=NewScript('T2Config0',Held);R.Reader:=T;
  // Fixed CRC-A for a locked ACCESS preimage; no write can be sent.
  Locked:=HexToBytes('082200FF78556677');T.Pairs[1].Response:=BytesToHex(TRawUidCodec.AppendCrcA(Locked));Failed:=False;
  try C:=R.ConfigureAuthenticationVerified(ttmUltralightEv1_48,4,True,3,Locked,Password,Pack);
  except on E:EContactlessError do Failed:=True;end;
  Check(Failed and (T.Calls=2) and (T.Ends=1),'CFGLCK blocks configuration but does not guess credential locks');
  T:=NewScript('T2Credentials0',Held);R.Reader:=T;T.EndFails:=True;Uncertain:=False;
  try R.ChangeCredentialsVerified(ttmUltralightEv1_48,Password,Pack,NewPassword,NewPack);
  except on E:EContactlessWriteUncertain do Uncertain:=True;end;
  Check(Uncertain and (T.Calls=4) and (T.Ends=1),'Credential proof plus failed release remains uncertain');
  T:=TScript.Create;Held:=T;R.Reader:=T;Failed:=False;
  try R.ReadCounter(ttmNtag210,2,Password,Pack);except on E:EContactlessError do Failed:=True;end;
  Check(Failed and (T.Begins=0),'NTAG210 absent counter profile rejected before I/O');
  Failed:=False;
  try C:=R.ConfigureAuthenticationVerified(ttmNtag213,4,True,8,Before,Password,Pack);except on E:EContactlessError do Failed:=True;end;
  Check(Failed and (T.Begins=0),'Invalid AUTHLIM rejected before I/O');
  T:=NewScript('T2Credentials0',Held);SetLength(T.Pairs,2);T.Pairs[1]:=T.Pairs[0];R.Reader:=T;
  Check(R.ChangeCredentialsVerified(ttmUltralightEv1_48,Password,Pack,Password,Pack) and
    (T.Calls=2) and (T.Activations=2),'Unchanged credentials get fresh proof without writes');
 finally R.Free;Held:=nil;end;
 T3:=TType3NdefCardReader.Create(nil);
 try
  T:=NewScript('Type3Read',Held);T3.Reader:=T;S:=T3.ReadMessage;
  T:=NewScript('Type3Read',Held);T3.Reader:=T;Failed:=False;
  try S:=T3.WriteMessageVerified(HexToBytes('100302012C000000000001000009004C'),HexToBytes('D101045402656E41'));
  except on E:EType3NdefError do Failed:=True;end;
  Check(Failed and (T.Calls=3),'Type 3 stale attribute preimage sends no write');
  T:=NewScript('Type3Write',Held);T3.Reader:=T;T.EndFails:=True;Before:=HexToBytes('D101295402656E');SetLength(Before,45);FillChar(Before[7],38,$42);Uncertain:=False;
  try S:=T3.WriteMessageVerified(HexToBytes('100302012C000000000001000008004B'),Before);
  except on E:EContactlessWriteUncertain do Uncertain:=True;end;
  Check(Uncertain and (T.Ends=1),'Type 3 full verification plus failed release remains uncertain');
  T:=NewScript('Type3Read',Held);T3.Reader:=T;
  S:=T3.WriteMessageVerified(HexToBytes('100302012C000000000001000008004B'),HexToBytes('D101045402656E41'));
  Check((T.Calls=3) and (BytesToHex(S.MessageBytes)='D101045402656E41'),'Type 3 unchanged message verifies without writing');
  A:=TType3NdefMapping.DecodeAttribute(HexToBytes('100302012C000000000F01000008005A'));
  Check(A.Updating,'Type 3 interrupted update is exposed as explicit state');
 finally T3.Free;Held:=nil;end;
end;

procedure TestFelica;
var R:TFelicaCardReader;T:TScript;Held:IFelicaReader;P:TProtocolPairs;B:TFelicaBlocks;
 Data,Expected,NewData:TBytes;Action,Attempt,I,J,K:Integer;Failed,Uncertain:Boolean;
begin
 R:=TFelicaCardReader.Create(nil);SetLength(B,2);B[0]:=3;B[1]:=256;
 Expected:=HexToBytes('000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F');
 NewData:=HexToBytes('202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F');
 try
  for Action:=0 to 1 do begin
   if Action=0 then P:=ProtocolPairs('FelicaRead') else P:=ProtocolPairs('FelicaWrite');
   for Attempt:=0 to Length(P) do begin
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.FailCall:=Attempt;R.Reader:=T;Failed:=False;Uncertain:=False;
    try if Action=0 then Data:=R.ReadBlocks($12FC,11,B) else Data:=R.WriteBlocksVerified($12FC,9,11,B,Expected,NewData);
    except on E:Exception do begin Failed:=True;Uncertain:=E is EContactlessWriteUncertain;if Attempt=0 then raise;end;end;
    Check(Failed=(Attempt>0),'FeliCa exact literal success and every failed exchange');
    Check(Uncertain=((Action=1) and (Attempt>=2)),'FeliCa dispatch uncertainty boundary');
    Check((T.Ends=1) and not T.Active and not R.Busy,'FeliCa exclusive cleanup');
    if Attempt=0 then Check(BytesEqual(Data,Expected) or ((Action=1) and BytesEqual(Data,NewData)),'FeliCa block order and long block-list element');
   end;
  end;
  P:=ProtocolPairs('FelicaRead');
  // Metadata/identity/status/count bits must fail; unencrypted payload has no application MAC.
  for I:=0 to 12 do for K:=0 to 7 do begin
   T:=TScript.Create;Held:=T;T.Pairs:=P;T.CorruptCall:=1;T.CorruptByte:=I;T.CorruptBit:=K;R.Reader:=T;Failed:=False;
   try Data:=R.ReadBlocks($12FC,11,B);except on E:Exception do Failed:=True;end;
   Check(Failed and (T.Ends=1),'FeliCa framing, status and identity corruption');
  end;
  T:=TScript.Create;Held:=T;T.Pairs:=ProtocolPairs('FelicaWrite');R.Reader:=T;Failed:=False;
  try Data:=R.WriteBlocksVerified($12FC,9,11,B,NewData,NewData);except on E:Exception do Failed:=True;end;
  Check(Failed and (T.Calls=1),'FeliCa stale preimage sends no write');
  B[1]:=B[0];T:=TScript.Create;Held:=T;R.Reader:=T;Failed:=False;
  try Data:=R.ReadBlocks($12FC,11,B);except on E:Exception do Failed:=True;end;
  Check(Failed and (T.Begins=0),'Duplicate blocks rejected before acquisition');
 finally R.Free;Held:=nil;end;
end;
procedure TestType3;
var R:TType3NdefCardReader;T:TScript;Held:IFelicaReader;P:TProtocolPairs;S:TType3NdefSnapshot;
 Attr,Message:TBytes;Action,Attempt,I,J,K,Boundary:Integer;Failed,Uncertain:Boolean;
 procedure Workflow;
 begin if Action=0 then S:=R.ReadMessage else S:=R.WriteMessageVerified(Attr,Message);end;
begin
 R:=TType3NdefCardReader.Create(nil);Attr:=HexToBytes('100302012C000000000001000008004B');
 try
  for Action:=0 to 2 do begin
   if Action=0 then P:=ProtocolPairs('Type3Read') else if Action=1 then P:=ProtocolPairs('Type3Write') else P:=ProtocolPairs('Type3Clear');
   Message:=HexToBytes('D101295402656E');SetLength(Message,45);for I:=7 to 44 do Message[I]:=$42;if Action=2 then Message:=nil;
   Boundary:=Length(P)+1;for I:=0 to High(P) do if Copy(P[I].Command,3,2)='08' then begin Boundary:=I+1;Break;end;
   for Attempt:=0 to Length(P) do begin
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.FailCall:=Attempt;R.Reader:=T;Failed:=False;Uncertain:=False;
    try Workflow;except on E:Exception do begin Failed:=True;Uncertain:=E is EContactlessWriteUncertain;if Attempt=0 then raise;end;end;
    Check(Failed=(Attempt>0),'Type 3 independent length-last transcript');
    Check(Uncertain=((Attempt>0) and (Attempt>=Boundary)),'Type 3 every mutation boundary');
    Check((T.Ends=1) and not T.Active and not R.Busy,'Type 3 exclusive cleanup');
    if Attempt=0 then begin Check(T.Calls=Length(P),'Type 3 complete transcript');if Action<>0 then Check(BytesEqual(S.MessageBytes,Message),'Type 3 exact parsed NDEF result');end;
   end;
   // Read responses must reject corrupt metadata/attribute checksum; post-write readback rejects every changed bit.
   if Action=1 then for I:=Boundary to High(P) do for J:=0 to Length(P[I].Response) div 2-1 do for K:=0 to 7 do begin
    if (J>=13) and (Copy(P[I].Command,Length(P[I].Command)-3,4)<>'8000') and
      (Copy(P[I-1].Command,3,2)<>'08') and not ((I=Length(P)-2) and (J<58)) then Continue;
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.CorruptCall:=I+1;T.CorruptByte:=J;T.CorruptBit:=K;R.Reader:=T;Failed:=False;
    try Workflow;except on E:Exception do Failed:=True;end;
    Check(Failed and (T.Ends=1) and not R.Busy,'Type 3 independent post-write verification bit corruption');
   end;
  end;
  for I:=0 to 15 do for K:=0 to 7 do begin
   Attr:=HexToBytes('100302012C000000000001000008004B');Attr[I]:=Attr[I] xor (1 shl K);Failed:=False;
   try TType3NdefMapping.DecodeAttribute(Attr);except on E:EType3NdefError do Failed:=True;end;
   Check(Failed,'Type 3 every attribute bit protected by checksum');
  end;
 finally R.Free;Held:=nil;end;
end;
procedure TestType2;
var R:TType2PasswordCardReader;T:TScript;Held:IFelicaReader;P:TProtocolPairs;
 Models:array[0..6] of TType2TagModel;M,Action,Attempt,I,J,K,Boundary:Integer;Failed,Uncertain:Boolean;
 Password,Pack,NewPassword,NewPack,Preimage:TBytes;C:TType2AuthenticationConfiguration;
 S:TType2NdefSnapshot;V:Cardinal;
 procedure Workflow;
 begin
  case Action of
   0:C:=R.ReadConfiguration(Models[M],Password,Pack);
   1:C:=R.ConfigureAuthenticationVerified(Models[M],4,True,3,Preimage,Password,Pack);
   2:Check(R.ChangeCredentialsVerified(Models[M],Password,Pack,NewPassword,NewPack),'Fresh replacement credentials verified');
   3:begin V:=R.ReadCounter(Models[M],Byte(Ord(M>=2)*2),Password,Pack);Check(V=$123456,'Little-endian 24-bit counter');end;
   4:S:=R.ReadNdef(Models[M],Password,Pack);
   5:S:=R.WriteNdefVerified(Models[M],HexToBytes('D101045402656E42'),Password,Pack);
  end;
 end;
begin
 Models[0]:=ttmUltralightEv1_48;Models[1]:=ttmUltralightEv1_128;Models[2]:=ttmNtag213;
 Models[3]:=ttmNtag215;Models[4]:=ttmNtag216;Models[5]:=ttmNtag210;Models[6]:=ttmNtag212;
 Password:=HexToBytes('01020304');Pack:=HexToBytes('A1B2');NewPassword:=HexToBytes('05060708');NewPack:=HexToBytes('C3D4');Preimage:=HexToBytes('082200FF38556677');
 R:=TType2PasswordCardReader.Create(nil);
 try
  for M:=0 to 6 do for Action:=0 to 5 do if ((Action<3) or ((Action=3) and (M<5)) or ((Action>3) and (M=0))) then begin
   case Action of 0:P:=ProtocolPairs('T2Config'+IntToStr(M));1:P:=ProtocolPairs('T2Configure'+IntToStr(M));
    2:P:=ProtocolPairs('T2Credentials'+IntToStr(M));3:P:=ProtocolPairs('T2Counter'+IntToStr(M));
    4:P:=ProtocolPairs('T2NdefRead');5:P:=ProtocolPairs('T2NdefWrite');end;
   Boundary:=Length(P)+1;for I:=0 to High(P) do if Pos('A2',P[I].Command)=1 then begin Boundary:=I+1;Break;end;
   for Attempt:=0 to Length(P) do begin
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.FailCall:=Attempt;R.Reader:=T;Failed:=False;Uncertain:=False;
    try Workflow;except on E:Exception do begin Failed:=True;Uncertain:=E is EContactlessWriteUncertain;if Attempt=0 then raise;end;end;
    Check(Failed=(Attempt>0),'Type 2 independent literal success/failure');
    Check(Uncertain=((Attempt>0) and (Attempt>=Boundary)),'Type 2 every management dispatch boundary');
    Check((T.Ends=1) and not T.Active and not R.Busy,'Type 2 session cleanup');
    if Attempt=0 then begin
     Check(T.Calls=Length(P),'Type 2 exact transcript');
     if Action in [1,2] then Check(T.Activations=2,'Type 2 fresh same-UID activation');
     if Action=1 then Check((C.FirstProtectedPage=4) and C.ProtectReads and (C.AuthenticationLimit=3) and (BytesToHex(C.RawPages)='08220004BB556677'),'Type 2 unrelated configuration preservation');
     if Action=5 then Check(BytesToHex(S.MessageBytes)='D101045402656E42','Protected NDEF full readback');
    end;
   end;
   for I:=0 to High(P) do for J:=0 to Length(P[I].Response) div 2-1 do for K:=0 to 7 do begin
    if (Length(P[I].Response)=2) and (K>3) then Continue;
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.CorruptCall:=I+1;T.CorruptByte:=J;T.CorruptBit:=K;R.Reader:=T;Failed:=False;
    try Workflow;except on E:Exception do Failed:=True;end;
    Check(Failed and (T.Ends=1) and not R.Busy,'Type 2 every response bit and retained-state cleanup');
   end;
   if Action in [1,2] then begin
    T:=TScript.Create;Held:=T;T.Pairs:=P;T.SwapUid:=True;R.Reader:=T;Uncertain:=False;
    try Workflow;except on E:EContactlessWriteUncertain do Uncertain:=True;end;
    Check(Uncertain and (T.Ends=1),'Different UID cannot verify changed credentials/configuration');
   end;
  end;
 finally R.Free;Held:=nil;end;
end;
begin
 try TestNativeAdapter;TestManagementGuards;TestFelica;TestType3;TestType2;Writeln('PASS: ',Checks,' Type 2 management/FeliCa/Type 3 assertions.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
