program TopazTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes,ERD.Card.Ndef,ERD.Card.Transport,ERD.Card.Contactless,
 ERD.Card.Contactless.Topaz,ERD.Card.Contactless.ACR122.Topaz,ERD.Card.Contactless.Type1.Ndef,Topaz.Vectors;
type
 TMemory=class(TInterfacedObject,ITopazSession)
  Model:TTopazModel;Memory:TBytes;Calls,Begins,Ends,Writes,FailCall:Integer;
  Active,EndFails,Corrupt,SwapUid:Boolean;
  procedure Step;
  function BeginSession(const AModel:TTopazModel):TTopazTarget;
  procedure EndSession;
  function ReadMemory:TBytes;
  function ReadBlock(const ABlock:Byte):TBytes;
  procedure WriteByte(const AAddress,AValue:Byte);
  procedure WriteBlock(const ABlock:Byte;const AData:TBytes);
 end;
 TNative=class(TInterfacedObject,ICardTransport,ICardTransaction)
  Pairs:TTopazPairs;Calls,Begins,Ends,FailCall:Integer;Active,Cleanup:Boolean;
  procedure BeginTransaction;procedure EndTransaction;
  function Exchange(const ACommand:TBytes):TBytes;
 end;
var Checks:Integer=0;
procedure Check(const V:Boolean;const S:string);
begin Inc(Checks);if not V then raise Exception.Create(S);end;
function Target(const Model:TTopazModel):TTopazTarget;
begin
 Result.SensRes:=HexToBytes('000C');Result.UidEcho:=HexToBytes('01020304');
 if Model=tmTopaz96 then Result.HeaderRom:=HexToBytes('1148') else Result.HeaderRom:=HexToBytes('124C');
end;
function Initial(const Model:TTopazModel):TBytes;
var Data:TBytes;
begin
 Result:=nil;SetLength(Result,TTopazCodec.MemorySize(Model));Data:=HexToBytes('01020304050607');Move(Data[0],Result[0],7);
 Result[8]:=$E1;Result[9]:=$10;Result[10]:=Length(Result) div 8-1;
 if Model=tmTopaz512 then begin Data:=HexToBytes('0103F230330203F002030300FE');Move(Data[0],Result[12],Length(Data));end
 else begin Result[12]:=3;Result[14]:=$FE;end;
end;
procedure TMemory.Step;begin Inc(Calls);if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure');end;
function TMemory.BeginSession(const AModel:TTopazModel):TTopazTarget;
begin Check(not Active,'Acquire once');Check(Model=AModel,'Exact model');Step;Inc(Begins);Active:=True;Result:=Target(Model);end;
procedure TMemory.EndSession;begin Check(Active,'Owned release');Active:=False;Inc(Ends);Step;if EndFails then raise ECardTransportError.Create('Synthetic release failure');end;
function TMemory.ReadMemory:TBytes;begin Check(Active,'Exclusive read');Step;Result:=CopyBytes(Memory);if SwapUid then Result[0]:=9;end;
function TMemory.ReadBlock(const ABlock:Byte):TBytes;begin Check(Active,'Exclusive block read');Step;Result:=Copy(Memory,ABlock*8,8);if Corrupt then Result[0]:=Result[0] xor 1;end;
procedure TMemory.WriteByte(const AAddress,AValue:Byte);begin Check(Active and (Model=tmTopaz96),'Static byte dispatch');Inc(Writes);Step;Memory[AAddress]:=AValue;end;
procedure TMemory.WriteBlock(const ABlock:Byte;const AData:TBytes);begin Check(Active and (Model=tmTopaz512) and (Length(AData)=8),'Dynamic block dispatch');Inc(Writes);Step;Move(AData[0],Memory[ABlock*8],8);end;
function NewMemory(const Model:TTopazModel;out Held:ITopazSession):TMemory;
begin Result:=TMemory.Create;Held:=Result;Result.Model:=Model;Result.Memory:=Initial(Model);end;
function Message(const Count:Integer):TBytes;
var I:Integer;
begin
 Result:=nil;SetLength(Result,Count+3);Result[0]:=$D5;Result[1]:=0;Result[2]:=Count and $FF;
 for I:=3 to High(Result) do Result[I]:=I and $FF;
 if Count>=256 then begin
  SetLength(Result,Count+6);Result[0]:=$C5;Result[1]:=0;Result[2]:=0;Result[3]:=0;Result[4]:=Count shr 8;Result[5]:=Count and $FF;
  for I:=6 to High(Result) do Result[I]:=I and $FF;
 end;
end;
procedure TNative.BeginTransaction;begin Check(not Active,'Native exclusive begin');Active:=True;Inc(Begins);end;
procedure TNative.EndTransaction;begin Check(Active,'Native exclusive end');Active:=False;Inc(Ends);end;
function TNative.Exchange(const ACommand:TBytes):TBytes;
var Text:string;
begin
 Inc(Calls);Text:=BytesToHex(ACommand);
 if Calls=FailCall then begin Cleanup:=True;raise ECardTransportError.Create('Synthetic native failure');end;
 // Failure paths can only restore the exact saved registers or turn RF off.
 if (Cleanup or (Calls>Length(Pairs)) or (Text<>Pairs[Calls-1].Command)) and
  ((Text='FF00000004D4320100') or (Text='FF00000014D408633100633A80630D20633D00630280630380')) then begin
  Cleanup:=True;if Text='FF00000004D4320100' then Result:=HexToBytes('D5339000') else Result:=HexToBytes('D5099000');Exit;
 end;
 Check((Calls<=Length(Pairs)) and (Text=Pairs[Calls-1].Command),'Independent native command mismatch at '+IntToStr(Calls));
 Result:=HexToBytes(Pairs[Calls-1].Response);
end;
procedure TestAdapter;
var T:TNative;Transport:ICardTransport;Reader:ITopazSession;P:TTopazPairs;TargetData:TTopazTarget;
 I,J:Integer;Failed:Boolean;Data:TBytes;
begin
 P:=DynamicPairs;T:=TNative.Create;Transport:=T;T.Pairs:=P;Reader:=TAcr122TopazSession.Create(Transport);
 TargetData:=Reader.BeginSession(tmTopaz512);Check(BytesToHex(TargetData.HeaderRom)='124C','Fresh exact RID');Data:=Reader.ReadBlock(16);Check(BytesToHex(Data)='1020304050607080','Independent native READ8 response');
 Reader.WriteBlock(16,Data);Reader.EndSession;Check((T.Calls=22) and (T.Ends=1),'Complete CIU literal transcript');Reader:=nil;Transport:=nil;
 for I:=1 to Length(P) do begin
  T:=TNative.Create;Transport:=T;T.Pairs:=P;T.FailCall:=I;Reader:=TAcr122TopazSession.Create(Transport);Failed:=False;
  try
   TargetData:=Reader.BeginSession(tmTopaz512);
   try Data:=Reader.ReadBlock(16);Reader.WriteBlock(16,Data);finally Reader.EndSession;end;
  except on E:Exception do Failed:=True;end;
  Check(Failed and (T.Ends=1) and not T.Active,'Native every dispatch/cleanup failure releases exclusivity');Reader:=nil;Transport:=nil;
 end;
 // Corrupt every RF bit, including all parity and CRC bits; no second operation may use a poisoned session.
 for I:=0 to 98 do begin
  T:=TNative.Create;Transport:=T;T.Pairs:=P;Data:=HexToBytes(T.Pairs[12].Response);Data[2+I div 8]:=Data[2+I div 8] xor (1 shl (I mod 8));
  T.Pairs[12].Response:=BytesToHex(Data);Reader:=TAcr122TopazSession.Create(Transport);TargetData:=Reader.BeginSession(tmTopaz512);Failed:=False;
  try Data:=Reader.ReadBlock(16);except on E:ETopazError do Failed:=True;end;Check(Failed,'Every corrupted CRC/parity/data bit refused');J:=T.Calls;Failed:=False;
  try Data:=Reader.ReadBlock(16);except on E:ETopazError do Failed:=True;end;Check(Failed and (T.Calls=J),'Poisoned session cannot continue');Reader.EndSession;Reader:=nil;Transport:=nil;
 end;
 // Static dialect exercises documented status-only WRITE-E and exact RALL response length.
 SetLength(P,10);P[6].Response:='D541001148010203049000';P[7].Command:='FF00000004D4400100';
 Data:=Initial(tmTopaz96);P[7].Response:='D541001148'+BytesToHex(Data)+'9000';
 P[8].Command:='FF00000006D440015314AA';P[8].Response:='D541009000';P[9].Command:='FF00000004D4320100';P[9].Response:='D5339000';
 T:=TNative.Create;Transport:=T;T.Pairs:=P;Reader:=TAcr122TopazSession.Create(Transport);TargetData:=Reader.BeginSession(tmTopaz96);
 Data:=Reader.ReadMemory;Check(Length(Data)=120,'Exact static RALL geometry');Reader.WriteByte(20,$AA);Reader.EndSession;Reader:=nil;Transport:=nil;
 T:=TNative.Create;Transport:=T;T.Pairs:=P;T.Pairs[8].Response:='D54100AA9000';Reader:=TAcr122TopazSession.Create(Transport,tbaByteEcho);
 TargetData:=Reader.BeginSession(tmTopaz96);Data:=Reader.ReadMemory;Reader.WriteByte(20,$AA);Reader.EndSession;Reader:=nil;Transport:=nil;
end;
procedure TestLocks;
var M:TTopazModel;S:TTopazSnapshot;Memory:TBytes;I,J,B:Integer;Locked:Boolean;
begin
 Check(TTopazCodec.CrcB(HexToBytes('313233343536373839'))=$906E,'Independent CRC X25 check vector');
 for M:=Low(TTopazModel) to High(TTopazModel) do begin
  Memory:=Initial(M);S:=TTopazCodec.Decode(M,Target(M),Memory);Check(BytesToHex(S.Uid)='01020304050607','UID wire order');
  S.Memory[0]:=9;Check(Memory[0]=1,'Snapshot owns memory');
  for I:=0 to 15 do begin
   Memory:=Initial(M);Memory[112+I div 8]:=1 shl (I mod 8);S:=TTopazCodec.Decode(M,Target(M),Memory);
   for J:=12 to 103 do begin
    Locked:=(J div 8=I) or ((M=tmTopaz512) and (J<22));Check((S.Writable[J]=0)=Locked,'Every static lock bit maps to exact block');
   end;
  end;
 end;
 for I:=0 to 47 do begin
  Memory:=Initial(tmTopaz512);Memory[122+I div 8]:=1 shl (I mod 8);S:=TTopazCodec.Decode(tmTopaz512,Target(tmTopaz512),Memory);
  for J:=128 to 511 do begin B:=(J-128) div 8;Check((S.Writable[J]=0)=(B=I),'Every dynamic lock maps to exact eight bytes');end;
 end;
end;
procedure TestMessages;
var M:TTopazModel;T:TMemory;Held:ITopazSession;R:TType1NdefCardReader;S:TType1NdefSnapshot;
 Before,Data,Uid:TBytes;I,Total:Integer;Failed,Uncertain:Boolean;
begin
 Uid:=HexToBytes('01020304050607');R:=TType1NdefCardReader.Create(nil);
 try
  for M:=Low(TTopazModel) to High(TTopazModel) do begin
   T:=NewMemory(M,Held);R.Session:=Held;R.Model:=M;S:=R.ReadMessage;Before:=CopyBytes(S.Card.Memory);Data:=Message(20);
   S:=R.WriteMessageVerified(Uid,Before,Data);Check(BytesEqual(S.MessageBytes,Data) and (Length(S.Records)=1),'Read/write decoded NDEF');
   Check(BytesEqual(Copy(S.Card.Memory,0,12),Copy(Before,0,12)),'CC and UID preserved');Check(BytesEqual(Copy(S.Card.Memory,104,16),Copy(Before,104,16)),'Static metadata preserved');
   Total:=T.Writes;S:=R.WriteMessageVerified(Uid,S.Card.Memory,Data);Check(T.Writes=Total,'Identical acquired message is no-op');
   S:=R.WriteMessageVerified(Uid,S.Card.Memory,nil);Check(Length(S.MessageBytes)=0,'Clear initialized NDEF');
   Before:=Initial(M);T:=NewMemory(M,Held);R.Session:=Held;S:=R.WriteMessageVerified(Uid,Before,Data);Total:=T.Calls;
   for I:=1 to Total do begin
    T:=NewMemory(M,Held);R.Session:=Held;T.FailCall:=I;Failed:=False;Uncertain:=False;
    try S:=R.WriteMessageVerified(Uid,Before,Data);except on E:EContactlessWriteUncertain do begin Failed:=True;Uncertain:=True;end;on E:Exception do Failed:=True;end;
    Check(Failed and not T.Active,'Every write/readback/release failure ends session');
    Check(Uncertain=(T.Writes>0),'Only dispatched failures uncertain');
   end;
   T:=NewMemory(M,Held);R.Session:=Held;T.Memory[112]:=$FF;T.Memory[113]:=$FF;Failed:=False;
   try S:=R.WriteMessageVerified(Uid,T.Memory,Data);except on E:ETopazError do Failed:=True;end;
   Check(Failed and (T.Writes=0),'All lock preflight before invalidation');
   T:=NewMemory(M,Held);R.Session:=Held;T.EndFails:=True;Uncertain:=False;
   try S:=R.WriteMessageVerified(Uid,Before,Data);except on E:EContactlessWriteUncertain do Uncertain:=True;end;
   Check(Uncertain and not T.Active,'Verified data plus release failure uncertain');
   T:=NewMemory(M,Held);R.Session:=Held;T.Corrupt:=True;Uncertain:=False;
   try S:=R.WriteMessageVerified(Uid,Before,Data);except on E:EContactlessWriteUncertain do Uncertain:=True;end;
   Check(Uncertain and (T.Writes=1),'Readback corruption stops before next dispatch');
   T:=NewMemory(M,Held);R.Session:=Held;T.Memory[40]:=1;Failed:=False;
   try S:=R.WriteMessageVerified(Uid,Before,Data);except on E:ETopazError do Failed:=True;end;
   Check(Failed and (T.Writes=0),'Complete stale preimage refuses write');
  end;
  M:=tmTopaz512;R.Model:=M;T:=NewMemory(M,Held);R.Session:=Held;Before:=CopyBytes(T.Memory);Data:=Message(300);
  S:=R.WriteMessageVerified(Uid,Before,Data);Check(BytesEqual(S.MessageBytes,Data) and (S.Card.Memory[23]=$FF),'Extended length and reserved-area crossing');
  Check(BytesEqual(Copy(S.Card.Memory,104,24),Copy(Before,104,24)),'Reserved and dynamic locks preserved');
  Data:=Message(456);S:=R.WriteMessageVerified(Uid,S.Card.Memory,Data);Check(Length(S.MessageBytes)=462,'Exact maximum dynamic payload');
  T:=NewMemory(M,Held);R.Session:=Held;Failed:=False;
  try S:=R.WriteMessageVerified(Uid,T.Memory,Message(457));except on E:ETopazError do Failed:=True;end;Check(Failed and (T.Writes=0),'Oversize refused without writes');
  R.Model:=tmTopaz96;T:=NewMemory(tmTopaz96,Held);R.Session:=Held;S:=R.WriteMessageVerified(Uid,T.Memory,Message(87));Check(Length(S.MessageBytes)=90,'Exact maximum static payload');
 finally R.Free;Held:=nil;end;
end;
procedure TestMappingGuards;
var M:TTopazModel;Memory,Before,Data,Image,Uid:TBytes;Card:TTopazSnapshot;S:TType1NdefSnapshot;
 R:TTopazCardReader;N:TType1NdefCardReader;T:TMemory;Held:ITopazSession;I,J,Offset:Integer;Failed:Boolean;
begin
 Uid:=HexToBytes('01020304050607');R:=TTopazCardReader.Create(nil);N:=TType1NdefCardReader.Create(nil);
 try
  for M:=Low(TTopazModel) to High(TTopazModel) do begin
   Before:=Initial(M);Card:=TTopazCodec.Decode(M,Target(M),Before);S:=TType1NdefMapping.Decode(Card);
   Offset:=TType1NdefMapping.Address(M,0);Data:=Message(5);Image:=TType1NdefMapping.Image(S,Data,True);Check(Image[Offset+1]=Length(Data),'Pure image owns canonical length');
   // Every truncated full-memory preimage and malformed CC access/version/capacity is refused before acquisition.
   for I:=0 to Length(Before)-1 do begin
    T:=NewMemory(M,Held);N.Session:=Held;N.Model:=M;Failed:=False;
    try S:=N.WriteMessageVerified(Uid,Copy(Before,0,I),Data);except on E:ETopazError do Failed:=True;end;
    Check(Failed and (T.Begins=0),'Every truncated preimage before I/O');
   end;
   for I:=8 to 11 do begin
    Memory:=CopyBytes(Before);Memory[I]:=Memory[I] xor $80;Failed:=False;
    try S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));except on E:ETopazError do Failed:=True;end;
    Check(Failed,'Invalid CC magic/version/capacity/read access');
   end;
   Memory:=CopyBytes(Before);Memory[11]:=$0F;S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));Check(S.ReadOnly,'Read-only CC can be read');
   T:=NewMemory(M,Held);N.Session:=Held;N.Model:=M;Failed:=False;
   try S:=N.WriteMessageVerified(Uid,Memory,Data);except on E:ETopazError do Failed:=True;end;Check(Failed and (T.Begins=0),'Read-only write rejected before I/O');
   Memory:=CopyBytes(Before);Memory[Offset+3]:=$AB;S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));
   Check(Length(S.MessageBytes)=0,'Terminator ignores nonzero storage padding');
   Memory:=CopyBytes(Before);Memory[Offset]:=1;Failed:=False;
   try S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));except on E:ETopazError do Failed:=True;end;Check(Failed,'Extra control layout rejected');
   Memory:=CopyBytes(Before);Memory[Offset+1]:=$FF;Memory[Offset+2]:=0;Memory[Offset+3]:=1;Failed:=False;
   try S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));except on E:ETopazError do Failed:=True;end;Check(Failed,'Noncanonical extended length rejected');
   Memory:=CopyBytes(Before);Memory[Offset+2]:=3;Memory[Offset+3]:=0;Failed:=False;
   try S:=TType1NdefMapping.Decode(TTopazCodec.Decode(M,Target(M),Memory));except on E:ETopazError do Failed:=True;end;Check(Failed,'Duplicate NDEF rejected');
   Memory:=CopyBytes(Before);Memory[Offset]:=$FD;Memory[Offset+1]:=2;Memory[Offset+2]:=$A1;Memory[Offset+3]:=$B2;
   Memory[Offset+4]:=3;Memory[Offset+5]:=0;Memory[Offset+6]:=$FE;
   T:=NewMemory(M,Held);T.Memory:=Memory;N.Session:=Held;S:=N.WriteMessageVerified(Uid,Memory,Data);
   Check(BytesEqual(Copy(Memory,Offset,4),Copy(S.Card.Memory,Offset,4)),'Proprietary TLV prefix retained');
   R.Model:=M;T:=NewMemory(M,Held);R.Session:=Held;Before:=CopyBytes(T.Memory);
   if M=tmTopaz96 then I:=20 else I:=128;
   Card:=R.WriteUserRangeVerified(Uid,Before,I,HexToBytes('A1B2C3'));Check(BytesToHex(Copy(Card.Memory,I,3))='A1B2C3','Raw range updated');
   Check(T.Writes=3-2*Ord(M=tmTopaz512),'Profile uses byte or eight-byte unit');
   J:=T.Writes;Card:=R.WriteUserRangeVerified(Uid,Card.Memory,I,HexToBytes('A1B2C3'));Check(T.Writes=J,'Raw identical range no-op');
   for I:=0 to Length(Before)-1 do begin
    if ((M=tmTopaz96) and (I>=12) and (I<104)) or ((M=tmTopaz512) and (((I>=22) and (I<104)) or (I>=128))) then Continue;
    T:=NewMemory(M,Held);R.Session:=Held;Failed:=False;
    try Card:=R.WriteUserRangeVerified(Uid,T.Memory,I,Copy(T.Memory,I,1));except on E:ETopazError do Failed:=True;end;
    Check(Failed and (T.Begins=0),'Every protected raw address rejected even unchanged');
   end;
  end;
  // Dynamic lock protecting later payload refuses the whole NDEF update before the initial length write.
  T:=NewMemory(tmTopaz512,Held);T.Memory[122]:=1;N.Model:=tmTopaz512;N.Session:=Held;Failed:=False;
  try S:=N.WriteMessageVerified(Uid,T.Memory,Message(120));except on E:ETopazError do Failed:=True;end;
  Check(Failed and (T.Begins=0) and (T.Writes=0),'Later locked payload preflight prevents invalidation');
 finally R.Free;N.Free;Held:=nil;end;
end;

begin
 try TestAdapter;TestLocks;TestMessages;TestMappingGuards;WriteLn('PASS: ',Checks,' Topaz/Type 1 checks.');
 except on E:Exception do begin WriteLn(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
