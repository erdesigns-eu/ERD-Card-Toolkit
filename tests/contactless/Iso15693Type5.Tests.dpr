program Iso15693Type5Tests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Transport, ERD.Card.Ndef,
  ERD.Card.Contactless, ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.Type5.Ndef;

type
  TMemorySession = class(TInterfacedObject,IIso15693Session)
  public
    Info:TIso15693SystemInfo;
    Memory,Locks:TBytes;
    WriteImages:array of TBytes;
    WriteBlocks:array of Integer;
    Begins,Ends,Reads,Writes,WriteAttempts,Checks,Calls,FailCall,FailWrite,BadRead,MutateAt:Integer;
    Active,BeginFails,EndFails,SuppressWrite,PartialWrite:Boolean;
    Component:TType5NdefCardReader;
    procedure Tick;
    function BeginSession:TIso15693SystemInfo;
    procedure EndSession;
    function ReadBlock(const ABlock:Integer):TBytes;
    function SecurityStatus(const ABlock:Integer):Byte;
    procedure WriteBlock(const ABlock:Integer; const AData:TBytes);
  end;
  TNoTransaction = class(TInterfacedObject,ICardTransport)
    function Exchange(const ACommand:TBytes):TBytes;
  end;
  TApduMemory = class(TInterfacedObject,ICardTransport,ICardTransaction)
  public
    Backend:TMemorySession;
    Retained:IIso15693Session;
    Mode:TIso15693AddressMode;
    Format:TIso15693ResponseFormat;
    Commands:array of TBytes;
    BadStatus,NativeError,MalformedUid,MalformedInfo:Boolean;
    Begins,Ends:Integer;
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand:TBytes):TBytes;
  end;
var Assertions:Integer;

procedure Check(const B:Boolean; const Msg:string);
begin Inc(Assertions); if not B then raise Exception.Create(Msg); end;

function InfoOf(const Blocks,Size:Integer; const Extended:Boolean=False):TIso15693SystemInfo;
begin
  Result:=Default(TIso15693SystemInfo); Result.Uid:=HexToBytes('E002010203040506');
  Result.BlockCount:=Blocks; Result.BlockSize:=Size; Result.InformationFlags:=4;
  if Extended then Result.InformationFlags:=$14;
end;

function MessageOf(const Size:Integer):TNdefMessage;
var B:TBytes; I:Integer;
begin
  B:=nil; SetLength(B,Size); for I:=0 to High(B) do B[I]:=(I*17+3) and $FF;
  Result:=nil; SetLength(Result,1); Result[0]:=TNdefCodec.NewRecord(ntfUnknown,nil,nil,B);
end;

function NewMemory(const Size,BlockSize:Integer; const Extended:Boolean=False):TMemorySession;
var Units,I:Integer;
begin
  Result:=TMemorySession.Create; Result.Info:=InfoOf(Size div BlockSize,BlockSize,Extended);
  SetLength(Result.Memory,Size); SetLength(Result.Locks,Result.Info.BlockCount);
  for I:=0 to Size-1 do Result.Memory[I]:=$AA;
  if Extended then
  begin
    Units:=(Size-8) div 8; Result.Memory[0]:=$E2; Result.Memory[1]:=$40;
    Result.Memory[2]:=0; Result.Memory[3]:=1; Result.Memory[4]:=0; Result.Memory[5]:=0;
    Result.Memory[6]:=Units shr 8; Result.Memory[7]:=Units and $FF;
    Result.Memory[8]:=3; Result.Memory[9]:=0; Result.Memory[10]:=$FE;
  end
  else
  begin
    Units:=(Size-4) div 8; Check(Units<=255,'Fixture one-byte CC capacity');
    Result.Memory[0]:=$E1; Result.Memory[1]:=$40; Result.Memory[2]:=Units; Result.Memory[3]:=0;
    Result.Memory[4]:=3; Result.Memory[5]:=0; Result.Memory[6]:=$FE;
  end;
end;

procedure TMemorySession.Tick;
var Failed:Boolean; Scratch:TType5NdefSnapshot;
begin
  Inc(Calls); if Calls=FailCall then raise EIso15693Error.Create('secret injected transport fault');
  if Component<>nil then
  begin
    Check(Component.Busy,'Busy throughout actual backend callbacks'); Failed:=False;
    try Scratch:=Component.ReadMessage; except on EContactlessError do Failed:=True; end;
    Check(Failed,'Nested operations refused'); Failed:=False;
    try Component.Session:=nil; except on EContactlessError do Failed:=True; end;
    Check(Failed,'Backend replacement refused during operation');
  end;
end;

function TMemorySession.BeginSession:TIso15693SystemInfo;
begin
  Inc(Begins); Check(not Active,'One exclusive acquisition');
  if BeginFails then raise EIso15693Error.Create('Begin primary');
  Active:=True; Result:=Info; Result.Uid:=CopyBytes(Info.Uid);
end;

procedure TMemorySession.EndSession;
begin
  Inc(Ends); Check(Active,'Release owned session'); Active:=False;
  if EndFails then raise EIso15693Error.Create('End secondary');
end;

function TMemorySession.ReadBlock(const ABlock:Integer):TBytes;
begin
  Check(Active and (ABlock>=0) and (ABlock<Info.BlockCount),'Bounded owned read'); Tick; Inc(Reads);
  if Reads=MutateAt then Memory[0]:=$E2;
  Result:=Copy(Memory,ABlock*Info.BlockSize,Info.BlockSize);
  if (Reads=BadRead) and (Length(Result)>0) then Result[0]:=Result[0] xor 1;
end;

function TMemorySession.SecurityStatus(const ABlock:Integer):Byte;
begin
  Check(Active and (ABlock>=0) and (ABlock<Info.BlockCount),'Bounded owned security query');
  Tick; Inc(Checks); Result:=Locks[ABlock];
end;

procedure TMemorySession.WriteBlock(const ABlock:Integer; const AData:TBytes);
var N,Count:Integer;
begin
  Check(Active and (ABlock>=0) and (ABlock<Info.BlockCount),'Bounded owned write');
  Check(Length(AData)=Info.BlockSize,'Exact block size'); Inc(WriteAttempts); Tick; Inc(Writes);
  N:=Length(WriteImages); SetLength(WriteImages,N+1); SetLength(WriteBlocks,N+1);
  WriteBlocks[N]:=ABlock;
  if not SuppressWrite then
  begin
    Count:=Info.BlockSize; if PartialWrite and (Writes=FailWrite) then Count:=Count div 2;
    if Count>0 then Move(AData[0],Memory[ABlock*Info.BlockSize],Count);
  end;
  WriteImages[N]:=CopyBytes(Memory);
  if Writes=FailWrite then raise EIso15693Error.Create('secret partial write fault');
end;

function TNoTransaction.Exchange(const ACommand:TBytes):TBytes;
begin Result:=nil; raise Exception.Create('Unexpected I/O during constructor validation'); end;

procedure TApduMemory.BeginTransaction;
var Info:TIso15693SystemInfo;
begin Inc(Begins); Info:=Backend.BeginSession; end;
procedure TApduMemory.EndTransaction;
begin Inc(Ends); Backend.EndSession; end;

function TApduMemory.Exchange(const ACommand:TBytes):TBytes;
var P,C,N,Block,I:Integer; Data,Payload:TBytes; Op:Byte;
begin
  N:=Length(Commands); SetLength(Commands,N+1); Commands[N]:=CopyBytes(ACommand);
  if BytesToHex(ACommand)='FFCA800000' then
  begin
    SetLength(Data,9); Data[0]:=0;
    for I:=0 to 7 do Data[I+1]:=Backend.Info.Uid[7-I];
    if MalformedUid then Data[8]:=$E1;
  end
  else
  begin
    Check((Length(ACommand)>=14) and (ACommand[0]=$FF) and (ACommand[1]=$FB) and
      (ACommand[2]=0) and (ACommand[3]=$22) and (ACommand[4]=Length(ACommand)-5),'Independent FF-FB framing/flags/length');
    Op:=ACommand[5]; P:=6; if Op=$3B then begin Check(ACommand[P]=$14,'Extended request parameters precede UID'); Inc(P); end;
    for I:=0 to 7 do Check(ACommand[P+I]=Backend.Info.Uid[7-I],'Addressed wire UID matches selected card'); Inc(P,8);
    Payload:=nil;
    if Op in [$2B,$3B] then
    begin
      C:=1; if Op=$3B then C:=2;
      SetLength(Payload,10+C); Payload[0]:=4; if C=2 then Payload[0]:=$14;
      for I:=0 to 7 do Payload[I+1]:=Backend.Info.Uid[7-I];
      Payload[9]:=(Backend.Info.BlockCount-1) and $FF;
      if C=2 then Payload[10]:=(Backend.Info.BlockCount-1) shr 8;
      Payload[9+C]:=Backend.Info.BlockSize-1;
      if MalformedInfo then Payload[8]:=Payload[8] xor 1;
    end
    else
    begin
      Block:=ACommand[P]; Inc(P);
      if Mode=iam16Bit then begin Block:=Block or (Integer(ACommand[P]) shl 8); Inc(P); end;
      case Op of
        $20,$30: begin Check(P=Length(ACommand),'Read command has no tail'); Payload:=Backend.ReadBlock(Block); end;
        $2C,$3C: begin
          C:=1; if Mode=iam16Bit then C:=2;
          Check(P+C=Length(ACommand),'One-block security count width');
          for I:=0 to C-1 do Check(ACommand[P+I]=0,'Count minus one zero');
          SetLength(Payload,1); Payload[0]:=Backend.SecurityStatus(Block);
        end;
        $21,$31: Backend.WriteBlock(Block,Copy(ACommand,P,Length(ACommand)-P));
      else raise Exception.Create('Unexpected or destructive command'); end;
    end;
    if Format=irfNativeFlags then
    begin
      SetLength(Data,Length(Payload)+1); Data[0]:=0;
      if Length(Payload)>0 then Move(Payload[0],Data[1],Length(Payload));
      if NativeError then begin Data:=HexToBytes('0110'); end;
    end
    else Data:=CopyBytes(Payload);
  end;
  Result:=CopyBytes(Data); N:=Length(Result); SetLength(Result,N+2); Result[N]:=$90; Result[N+1]:=0;
  if BadStatus then begin Result[N]:=$69; Result[N+1]:=$82; end;
end;

procedure CodecTests;
var U,B,R:TBytes; I,J:Integer; Failed:Boolean; Info:TIso15693SystemInfo; C:TType5CapabilityContainer;
begin
  U:=HexToBytes('E002010203040506');
  Check(BytesToHex(TIso15693Codec.SystemInfoCommand(U,iam8Bit))='FFFB0022092B06050403020102E0','Independent addressed system-info vector');
  Check(BytesToHex(TIso15693Codec.SystemInfoCommand(U,iam16Bit))='FFFB00220A3B1406050403020102E0','Extended parameters before UID');
  Check(BytesToHex(TIso15693Codec.ReadCommand(U,iam8Bit,255))='FFFB00220A2006050403020102E0FF','Last ordinary block');
  Check(BytesToHex(TIso15693Codec.ReadCommand(U,iam16Bit,256))='FFFB00220B3006050403020102E00001','First extended block, little endian');
  Check(BytesToHex(TIso15693Codec.SecurityCommand(U,iam16Bit,511))='FFFB00220D3C06050403020102E0FF010000','One extended security block');
  Check(BytesToHex(TIso15693Codec.WriteCommand(U,iam8Bit,2,HexToBytes('01020304')))='FFFB00220E2106050403020102E00201020304','Exact full-block write vector');
  B:=HexToBytes('0F06050403020102E011227F0324');
  Info:=TIso15693Codec.DecodeSystemInfo(B,iam8Bit);
  Check((Info.BlockCount=128) and (Info.BlockSize=4) and Info.HasDsfid and (Info.Dsfid=$11) and
    Info.HasAfi and (Info.Afi=$22) and Info.HasIcReference and (Info.IcReference=$24),'Optional standard information fields');
  Info:=TIso15693Codec.DecodeSystemInfo(HexToBytes('1406050403020102E0FF0703'),iam16Bit);
  Check((Info.BlockCount=2048) and (Info.BlockSize=4),'ST25DV64K extended information shape');
  for I:=0 to Length(B)-1 do
  begin
    Failed:=False; try Info:=TIso15693Codec.DecodeSystemInfo(Copy(B,0,I),iam8Bit); except on EContactlessError do Failed:=True; end;
    Check(Failed,'Every truncated system-information field');
  end;
  for I:=0 to 255 do
  begin
    Failed:=False; B:=HexToBytes('001122'); B[0]:=I;
    try R:=TIso15693Codec.DecodePayload(B,irfNativeFlags); except on EContactlessError do Failed:=True; end;
    Check(Failed=(I<>0),'Every native response flag, no error masking');
  end;
  for I:=0 to 3 do
  begin
    Failed:=False;
    try case I of
      0:R:=TIso15693Codec.ReadCommand(U,iam8Bit,256);
      1:R:=TIso15693Codec.ReadCommand(U,iam16Bit,65536);
      2:R:=TIso15693Codec.ReadCommand(U,iam8Bit,-1);
      3:R:=TIso15693Codec.WriteCommand(U,iam8Bit,2,nil);
    end; except on EContactlessError do Failed:=True; end;
    Check(Failed,'Invalid command preflight');
  end;
  Info:=InfoOf(128,4);
  C:=TType5NdefCodec.DecodeCapabilities(HexToBytes('E1403F00'),Info);
  Check((C.DataAreaBytes=504) and (C.HeaderBytes=4),'AN4911 NFC Forum example: MLEN excludes CC');
  Info:=InfoOf(2048,4,True);
  C:=TType5NdefCodec.DecodeCapabilities(HexToBytes('E2400001000003FF'),Info);
  Check((C.DataAreaBytes=8184) and (C.HeaderBytes=8),'AN4911 extended NFC Forum example');
  B:=HexToBytes('E2400001000003FF');
  for I:=0 to High(B) do for J:=0 to 7 do
  begin
    R:=CopyBytes(B); R[I]:=R[I] xor (1 shl J); Failed:=False;
    try C:=TType5NdefCodec.DecodeCapabilities(R,Info); except on EContactlessError do Failed:=True; end;
    if not Failed then Check((C.DataAreaBytes<=8184) and (C.HeaderBytes=8) and (C.MappingVersion=$40),'Accepted CC variants stay bounded/versioned');
  end;
  Failed:=False;
  try C:=TType5NdefCodec.DecodeCapabilities(HexToBytes('E1404000'),InfoOf(128,4)); except on EContactlessError do Failed:=True; end;
  Check(Failed,'Legacy Android full-memory MLEN never guessed');
  Writeln('PASS: ISO 15693 independent addressed commands, information/flag checks and Type 5 CC examples.');
end;

procedure AdapterTests;
var M:TMemorySession; Raw:IIso15693Session; A:TApduMemory; T:ICardTransport;
  S:IIso15693Session; C:TIso15693CardReader; N:TType5NdefCardReader; R,Before:TBytes;
  Info:TIso15693SystemInfo; F:TIso15693ResponseFormat; Mode:TIso15693AddressMode; I:Integer; Failed:Boolean;
begin
  for F:=Low(TIso15693ResponseFormat) to High(TIso15693ResponseFormat) do
    for Mode:=Low(TIso15693AddressMode) to High(TIso15693AddressMode) do
    begin
      if Mode=iam8Bit then M:=NewMemory(512,4) else M:=NewMemory(8192,4,True); Raw:=M;
      A:=TApduMemory.Create; A.Backend:=M; A.Retained:=Raw; A.Format:=F; A.Mode:=Mode; T:=A;
      S:=TAcr1552Iso15693Session.Create(T,Mode,F); Check(M.Begins=0,'Inactive native adapter');
      C:=TIso15693CardReader.Create(nil); N:=TType5NdefCardReader.Create(nil);
      try
        C.Session:=S; N.Session:=S; Info:=C.ReadInformation;
        Check(BytesEqual(Info.Uid,M.Info.Uid),'Canonical UID independent of transmission order');
        R:=C.ReadBlocks(2,2); Check(Length(R)=8,'Contiguous selected blocks');
        C.WriteBlock(10,HexToBytes('10203040')); Check(BytesToHex(C.ReadBlocks(10,1))='10203040','Complete native block write chain');
        Before:=CopyBytes(M.Memory); N.WriteMessage(MessageOf(50));
        Check(Length(N.ReadMessage.MessageBytes)>50,'Full Type 5/component/FF-FB/transport chain');
        Check((M.Memory[0]=Before[0]) and (M.Memory[1]=Before[1]),'Native-chain CC bytes preserved');
        if Mode=iam16Bit then
        begin C.WriteBlock(256,HexToBytes('AABBCCDD')); Check(BytesToHex(C.ReadBlocks(256,1))='AABBCCDD','Extended physical address passes complete chain'); end;
        Check((M.Begins=M.Ends) and not M.Active,'Exclusive native sessions released');
      finally C.Free; N.Free; end;
      S:=nil; T:=nil; Raw:=nil;
    end;
  for I:=0 to 4 do
  begin
    M:=NewMemory(512,4); Raw:=M; A:=TApduMemory.Create; A.Backend:=M; A.Retained:=Raw;
    A.Format:=irfNativeFlags; A.Mode:=iam8Bit; T:=A;
    case I of 0:A.BadStatus:=True; 1:A.NativeError:=True; 2:A.MalformedUid:=True;
      3:A.MalformedInfo:=True; 4:M.BeginFails:=True; end;
    S:=TAcr1552Iso15693Session.Create(T,iam8Bit,irfNativeFlags); Failed:=False;
    try Info:=S.BeginSession; except on EContactlessError do Failed:=True; end;
    Check(Failed and not M.Active,'Failed native acquisition grants nothing');
    if I=4 then Check(M.Ends=0,'Failed transaction acquisition does not release unowned state')
    else Check(M.Ends=1,'Acquired failure releases once');
    S:=nil; T:=nil; Raw:=nil;
  end;
  Writeln('PASS: Concrete ACR1552 FF-FB raw-memory and Type 5 chains, both explicit framing/address modes.');
end;

procedure MappingAndTransitionTests;
var M:TMemorySession; S:IIso15693Session; C:TType5NdefCardReader;
  Snapshot:TType5NdefSnapshot; I,J,Size,LenPos,Header,DataEnd,BeforeWrites:Integer; Before,R:TBytes; Msg:TNdefMessage;
begin
  for Size:=1 to 32 do
  begin
    // Keep one-byte CC within 256 blocks, leaving an end-of-area partial block for many sizes.
    M:=NewMemory(64*Size,Size); S:=M; C:=TType5NdefCardReader.Create(nil);
    try
      C.Session:=S; M.Component:=C; Before:=CopyBytes(M.Memory);
      C.WriteMessage(MessageOf(5)); Snapshot:=C.ReadMessage;
      R:=TNdefCodec.Encode(MessageOf(5)); Check(BytesEqual(Snapshot.MessageBytes,R),'Every physical block size');
      DataEnd:=Snapshot.TlvOffset+Snapshot.TlvHeaderBytes+Length(R);
      for I:=0 to 3 do Check(M.Memory[I]=Before[I],'CC preserved even when it shares a writable block');
      for I:=DataEnd+1 to High(Before) do Check(M.Memory[I]=Before[I],'Physical partial-block tails preserved');
      BeforeWrites:=M.Writes; C.WriteMessage(MessageOf(5)); Check(M.Writes=BeforeWrites,'Verified no-op never writes');
      C.ClearMessage; Snapshot:=C.ReadMessage; Check(Length(Snapshot.MessageBytes)=0,'Clear returns initialized empty NDEF');
      Check(not C.Busy and (M.Begins=M.Ends),'Lifecycle released across all block sizes');
    finally C.Free; end; S:=nil;
  end;
  for J:=0 to 5 do
  begin
    M:=NewMemory(2048,4); S:=M; C:=TType5NdefCardReader.Create(nil);
    try
      C.Session:=S;
      // Proprietary TLV and NULL prefix shift extended length bytes across physical blocks.
      M.Memory[4]:=$FD; M.Memory[5]:=1; M.Memory[6]:=$A5;
      M.Memory[7]:=0; M.Memory[8]:=0; M.Memory[9]:=3; M.Memory[10]:=0; M.Memory[11]:=$FE;
      case J of 0:I:=250; 1:I:=251; 2:I:=252; 3:I:=253; 4:I:=255; else I:=600; end;
      Msg:=MessageOf(I); R:=TNdefCodec.Encode(Msg); C.WriteMessage(Msg);
      Snapshot:=C.ReadMessage; Header:=2; if Length(R)>=255 then Header:=4;
      Check((Snapshot.TlvOffset=9) and (Snapshot.TlvHeaderBytes=Header) and BytesEqual(Snapshot.MessageBytes,R),'Short/extended boundary and shifted opaque prefix');
      Check((M.Memory[4]=$FD) and (M.Memory[5]=1) and (M.Memory[6]=$A5),'Proprietary prefix preserved');
      LenPos:=10;
      if Header=4 then Check((LenPos div 4)<>((LenPos+2) div 4),
        'Extended length actually crosses a physical block boundary');
      for I:=0 to High(M.WriteImages)-1 do Check(M.WriteImages[I][LenPos]=0,'Every staged write retains unpublished zero length');
      if Header=4 then Check(M.WriteImages[High(M.WriteImages)][LenPos]=$FF,'FF is final publication byte');
      C.WriteMessage(MessageOf(5)); Snapshot:=C.ReadMessage;
      Check((Snapshot.TlvHeaderBytes=2) and BytesEqual(Snapshot.MessageBytes,TNdefCodec.Encode(MessageOf(5))),'Extended to short transition');
      C.ClearMessage; Check(Length(C.ReadMessage.MessageBytes)=0,'Extended-history clear');
    finally C.Free; end; S:=nil;
  end;
  Writeln('PASS: All physical block sizes, preserved partial tails/proprietary prefixes and short/extended transitions.');
end;

procedure FailureTests;
var M:TMemorySession; S:IIso15693Session; C:TType5NdefCardReader; I,J,N,WriteCount:Integer;
  Failed,Uncertain:Boolean; Old:TBytes; Snapshot:TType5NdefSnapshot;
begin
  M:=NewMemory(128,4); S:=M; C:=TType5NdefCardReader.Create(nil);
  try C.Session:=S; C.WriteMessage(MessageOf(20)); N:=M.Calls; WriteCount:=M.Writes;
  finally C.Free; end; S:=nil;
  for I:=1 to N do
  begin
    M:=NewMemory(128,4); S:=M; M.FailCall:=I; C:=TType5NdefCardReader.Create(nil);
    try
      C.Session:=S; Failed:=False; Uncertain:=False;
      try C.WriteMessage(MessageOf(20));
      except on E:EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; Check(Pos('secret',E.Message)=0,'No sensitive transport text'); end;
        on EContactlessError do Failed:=True; end;
      Check(Failed and not C.Busy and (M.Ends=1),'Every I/O boundary stops and releases once');
      Check(Uncertain=(M.WriteAttempts>0),'Failures after actual dispatch are uncertain');
      Check(M.Calls=I,'No later operation or replay after failure');
    finally C.Free; end; S:=nil;
  end;
  for I:=1 to WriteCount do
  begin
    M:=NewMemory(128,4); S:=M; M.FailWrite:=I; M.PartialWrite:=True; C:=TType5NdefCardReader.Create(nil);
    try
      C.Session:=S; Failed:=False;
      try C.WriteMessage(MessageOf(20)); except on EContactlessWriteUncertain do Failed:=True; end;
      Check(Failed and (M.Writes=I) and (M.Ends=1),'Every partial block write uncertain without repeat');
    finally C.Free; end; S:=nil;
  end;
  for I:=0 to 8 do
  begin
    M:=NewMemory(128,4); S:=M; Old:=CopyBytes(M.Memory); C:=TType5NdefCardReader.Create(nil);
    case I of
      0:M.Locks[1]:=1; 1:M.Locks[6]:=1; 2:M.Memory[1]:=$43;
      3:M.SuppressWrite:=True; 4:M.EndFails:=True; 5:M.BeginFails:=True;
      6:M.Memory[3]:=4; 7:M.Memory[4]:=1; 8:M.MutateAt:=3;
    end;
    try
      C.Session:=S; Failed:=False; Uncertain:=False;
      try C.WriteMessage(MessageOf(20));
      except on E:EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; end;
        on EContactlessError do Failed:=True; end;
      Check(Failed and not C.Busy,'Lock/access/format/coherence/verification/lifecycle failure');
      Check(Uncertain=(I in [3,4]),'Only dispatched/cleanup write failures uncertain');
      if I in [0,1] then Check((M.Writes=0) and BytesEqual(Old,M.Memory),'Every touched lock checked before any modification');
      if I=5 then Check(M.Ends=0,'Failed acquisition no release') else Check(M.Ends=1,'Acquired operation releases once');
    finally C.Free; end; S:=nil;
  end;
  // Corruption and malformed TLVs are rejected independently of the live backend.
  for I:=0 to 9 do
  begin
    M:=NewMemory(128,4); S:=M; Failed:=False;
    case I of
      0:M.Memory[0]:=0; 1:M.Memory[1]:=$50; 2:M.Memory[2]:=0; 3:M.Memory[3]:=$80;
      4:M.Memory[4]:=1; 5:M.Memory[4]:=2; 6:M.Memory[4]:=$FE;
      7:begin M.Memory[5]:=$FF; M.Memory[6]:=0; M.Memory[7]:=2; end;
      8:begin M.Memory[5]:=5; M.Memory[11]:=$FE; end;
      9:M.Memory[6]:=3;
    end;
    try Snapshot:=TType5NdefCodec.DecodeSnapshot(M.Info,M.Memory);
    except on EContactlessError do Failed:=True; on ENdefError do Failed:=True; end;
    Check(Failed,'Malformed CC/TLV/message never accepted'); S:=nil;
  end;
  // Oversize requests and protected raw blocks are refused before acquisition.
  M:=NewMemory(128,4); S:=M; C:=TType5NdefCardReader.Create(nil);
  try
    C.Session:=S; Failed:=False;
    try C.WriteMessage(MessageOf(65530)); except on EContactlessError do Failed:=True; end;
    Check(Failed and (M.Begins=0),'TLV 16-bit maximum enforced before hardware');
  finally C.Free; end; S:=nil;
  J:=N; Check(J>WriteCount,'Failure coverage includes preparation and final verification');
  Writeln('PASS: Every I/O/partial write, locked later blocks, failed verification, CC/TLV corruption and cleanup.');
end;

procedure MemorySafetyTests;
var M:TMemorySession; S,Adapter:IIso15693Session; C:TIso15693CardReader;
  A:TApduMemory; Transport:ICardTransport; Info:TIso15693SystemInfo;
  Snapshot:TType5NdefSnapshot; Data,Wire:TBytes; I,Index,Before:Integer;
  Failed,Uncertain:Boolean;
begin
  for I:=0 to 1 do
  begin
    Transport:=nil; if I=1 then Transport:=TNoTransaction.Create;
    Failed:=False;
    try Adapter:=TAcr1552Iso15693Session.Create(Transport,iam8Bit,irfNativeFlags);
    except on EIso15693Error do Failed:=True; end;
    Check(Failed and (Adapter=nil),'Invalid constructor raises before hardware and grants no adapter'); Transport:=nil;
  end;
  for I:=0 to 10 do
  begin
    M:=NewMemory(512,4); S:=M; C:=TIso15693CardReader.Create(nil);
    try
      C.Session:=S; Data:=HexToBytes('01020304'); Index:=10;
      case I of
        0:Index:=0; 1:Index:=1; 2:Index:=-1; 3:Index:=128; 4:Data:=HexToBytes('0102');
        5:M.Locks[10]:=1; 6:M.SuppressWrite:=True; 7:begin M.FailWrite:=1; M.PartialWrite:=True; end;
        8:M.EndFails:=True; 9:Data:=HexToBytes('AAAAAAAA'); 10:M.Info.BlockCount:=0;
      end;
      Failed:=False; Uncertain:=False;
      try C.WriteBlock(Index,Data);
      except on EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; end;
        on EContactlessError do Failed:=True; end;
      Check(Failed=(I<>9),'Raw-block guard/no-op/failure outcomes');
      Check(Uncertain=(I in [6,7,8]),'Raw dispatched failures and failed release uncertain');
      Check(not C.Busy,'Raw component busy always clears');
      if I in [0,1,2] then Check((M.Begins=0) and (M.Writes=0),'Protected/out-of-range raw inputs rejected before acquisition')
      else Check((M.Ends=1) and not M.Active,'Raw acquired sessions release once');
      if I in [3,4,5,9,10] then Check(M.Writes=0,'Preflight, lock and matching data do not write');
    finally C.Free; end; S:=nil;
  end;
  M:=NewMemory(512,4); S:=M; A:=TApduMemory.Create; A.Backend:=M; A.Retained:=S;
  A.Mode:=iam8Bit; A.Format:=irfNativeFlags; Transport:=A;
  Adapter:=TAcr1552Iso15693Session.Create(Transport,iam8Bit,irfNativeFlags);
  Info:=Adapter.BeginSession; Info.Uid[0]:=0;
  Data:=Adapter.ReadBlock(2); Check(Length(Data)=4,'Returned information UID does not mutate adapter address');
  A.NativeError:=True; Failed:=False;
  try Data:=Adapter.ReadBlock(2);
  except on E:EIso15693StatusError do begin Failed:=True; Check(E.ErrorCode=$10,'Native error code retained without payload data'); end; end;
  Check(Failed,'Native card failure not converted to success'); Before:=Length(A.Commands); Failed:=False;
  try I:=Adapter.SecurityStatus(2); except on EContactlessError do Failed:=True; end;
  Check(Failed and (Length(A.Commands)=Before),'Failed native session poisoned without later I/O');
  M.EndFails:=True; Failed:=False;
  try Adapter.EndSession; except on EContactlessError do Failed:=True; end;
  Check(Failed and not M.Active,'Failed native release still clears underlying ownership');
  M.EndFails:=False; A.NativeError:=False; Info:=Adapter.BeginSession;
  Adapter.EndSession; Check(M.Begins=M.Ends,'Explicit reacquisition after failed release works');
  Adapter:=nil; Transport:=nil; S:=nil;
  // Exact largest ordinary TLV length; input is acquired memory, not an implementation-produced TLV.
  M:=NewMemory(65552,4,True); S:=M; Wire:=TNdefCodec.Encode(MessageOf(65529));
  Check(Length(Wire)=65535,'Independent NDEF fixture at ordinary TLV maximum');
  M.Memory[8]:=3; M.Memory[9]:=$FF; M.Memory[10]:=$FF; M.Memory[11]:=$FF;
  Move(Wire[0],M.Memory[12],Length(Wire)); M.Memory[65547]:=$FE;
  Snapshot:=TType5NdefCodec.DecodeSnapshot(M.Info,M.Memory);
  Check((Length(Snapshot.MessageBytes)=65535) and (Length(Snapshot.Records)=1),'Exact Type 5 extended TLV maximum accepted');
  Data:=CopyBytes(Snapshot.PhysicalBytes); Snapshot.PhysicalBytes[0]:=0;
  Check(M.Memory[0]=$E2,'Decoded snapshot memory is independently owned'); S:=nil;
  Writeln('PASS: Raw-memory preflight/uncertainty, native poisoning, failed release, independent ownership and TLV maximum.');
end;

begin
  try
    CodecTests; AdapterTests; MappingAndTransitionTests; FailureTests; MemorySafetyTests;
    Writeln('PASS: 5 ISO 15693/Type 5 groups; ',Assertions,' assertions.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); {$IFDEF FPC}DumpExceptionBackTrace(Output);{$ENDIF} ExitCode:=1; end; end;
end.
