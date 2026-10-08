program DesfireTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Crypto,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows,
{$ELSE}
  ERD.Card.Crypto.OpenSSL,
{$ENDIF}
  ERD.Card.Contactless, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2, Desfire.Vectors;

type
  TFixedProvider = class(TInterfacedObject,ICardAesProvider)
  private
    FBase:ICardAesProvider;
  public
    RandomFails,MalformedRandom:Boolean;
    constructor Create(const Base:ICardAesProvider);
    function EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function RandomBytes(const ACount:Integer):TBytes;
  end;
  TTranscript = class(TInterfacedObject,ICardTransport,ICardTransaction)
  public
    Pairs:TDesfireWirePairs;
    Calls,Begins,Ends,Writes,FailCall,CorruptCall,CorruptByte,CorruptBit:Integer;
    Active,EndFails,BeginFails,Reenter:Boolean;
    Reader:TDesfireCardReader;
    constructor Create(const APairs:TDesfireWirePairs);
    function Exchange(const ACommand:TBytes):TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

var Assertions:Integer; Base:ICardAesProvider;
procedure Check(const Condition:Boolean; const Text:string);
begin Inc(Assertions); if not Condition then raise Exception.Create(Text); end;

constructor TFixedProvider.Create(const Base:ICardAesProvider);
begin inherited Create; FBase:=Base; end;
function TFixedProvider.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.EncryptCbc(AKey,AIv,AData); end;
function TFixedProvider.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.DecryptCbc(AKey,AIv,AData); end;
function TFixedProvider.RandomBytes(const ACount:Integer):TBytes;
begin
  if RandomFails then raise ECardCryptoError.Create('Synthetic RNG failure');
  if ACount<>16 then raise ECardCryptoError.Create('Unexpected nonce size');
  Result:=HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE');
  if MalformedRandom then SetLength(Result,15);
end;

constructor TTranscript.Create(const APairs:TDesfireWirePairs);
begin inherited Create; Pairs:=Copy(APairs,0,Length(APairs)); CorruptByte:=0; end;
procedure TTranscript.BeginTransaction;
begin
  Inc(Begins); if BeginFails then raise ECardTransportError.Create('Synthetic acquisition failure');
  if Active then raise ECardTransportError.Create('Nested transaction'); Active:=True;
end;
procedure TTranscript.EndTransaction;
begin
  Inc(Ends); if not Active then raise ECardTransportError.Create('Unexpected release');
  Active:=False; if EndFails then raise ECardTransportError.Create('Synthetic release failure');
end;
function TTranscript.Exchange(const ACommand:TBytes):TBytes;
var Failed:Boolean; Version:TDesfireVersion;
begin
  Result:=nil; if not Active then raise ECardTransportError.Create('Exchange without acquisition');
  Inc(Calls);
  if (Length(ACommand)>=2) and (ACommand[1] in [$3D,$8D]) then Inc(Writes);
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure');
  if Reenter then
  begin
    Reenter:=False; Failed:=False;
    try Version:=Reader.ReadVersion; except on E:EDesfireError do Failed:=True; end;
    Check(Failed,'Nested operation refused'); Check(Reader.Busy,'Busy remains true during callback');
    Failed:=False; try Reader.Transport:=nil; except on E:EDesfireError do Failed:=True; end;
    Check(Failed,'Busy transport setter refused');
    Failed:=False; try Reader.AuthenticationKey:=nil; except on E:EDesfireError do Failed:=True; end;
    Check(Failed,'Busy credential setter refused');
  end;
  if Calls>Length(Pairs) then raise ECardTransportError.Create('Command replay or unexpected continuation');
  if not BytesEqual(ACommand,HexToBytes(Pairs[Calls-1].Command)) then
    raise ECardTransportError.Create('Independent literal command mismatch at '+IntToStr(Calls));
  Result:=HexToBytes(Pairs[Calls-1].Response);
  if Calls=CorruptCall then
  begin
    if (CorruptByte<0) or (CorruptByte>=Length(Result)) then raise Exception.Create('Invalid test mutation');
    Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
  end;
end;

procedure Configure(const Reader:TDesfireCardReader; const T:TTranscript; const Mode:TDesfireCommunication);
var K:TBytes;
begin
  Reader.Transport:=T; Reader.Security:=dfsEv2Aes; Reader.CryptoProvider:=TFixedProvider.Create(Base);
  K:=HexToBytes('00000000000000000000000000000000'); Reader.AuthenticationKey:=K;
  Reader.MinimumCommunication:=Mode; T.Reader:=Reader;
  K[0]:=1; Check(Reader.AuthenticationKey[0]=0,'Caller key was copied');
  K:=Reader.AuthenticationKey; K[0]:=2; Check(Reader.AuthenticationKey[0]=0,'Getter key is independent');
  TCardCrypto.Clear(K);
end;

procedure CodecTests;
var Settings:TDesfireFileSettings; V:TDesfireVersion; Bytes:TBytes;
  Ids:TDesfireApplicationIds; I,J:Integer; Failed:Boolean;
begin
  Check(BytesEqual(TDesfireCodec.Command($60,nil),HexToBytes('9060000000')),'Literal GetVersion wrapping');
  Check(BytesEqual(TDesfireCodec.Command($5A,HexToBytes('563412')),HexToBytes('905A00000356341200')),'Literal selection wrapping');
  Check(BytesEqual(TDesfireCodec.ApplicationBytes($123456),HexToBytes('563412')),'Native AID is little endian');
  Check(BytesEqual(TDesfireCodec.RangeHeader(31,$123456,$654321),HexToBytes('1F563412214365')),'24-bit range header');
  Check(TDesfireCodec.SignedValue(HexToBytes('00000080'))=Low(Integer),'Signed minimum');
  Check(TDesfireCodec.SignedValue(HexToBytes('FFFFFF7F'))=High(Integer),'Signed maximum');
  Check(TDesfireCodec.SignedValue(HexToBytes('FFFFFFFF'))=-1,'Signed minus one');
  Settings:=TDesfireCodec.FileSettings(0,HexToBytes('00031234332211'));
  Check((Settings.ReadWriteKey=1) and (Settings.ChangeKey=2) and (Settings.ReadKey=3) and (Settings.WriteKey=4),'Independent access nibble vector');
  Check((Settings.FileBytes=$112233) and (Settings.Communication=dfcFull),'Settings geometry');
  Bytes:=HexToBytes('0000EEEFFFFF00'); Settings:=TDesfireCodec.FileSettings(31,Bytes);
  Bytes[2]:=0; Check(Settings.RawBytes[2]=$EE,'Settings source ownership');
  Ids:=TDesfireCodec.ApplicationIds(HexToBytes('56341201EFCD'));
  Check((Length(Ids)=2) and (Ids[0]=$123456) and (Ids[1]=$CDEF01),'Application IDs ordering');
  for I:=0 to 255 do
  begin
    Bytes:=HexToBytes('0000EEEE200000'); Bytes[1]:=I; Failed:=False;
    try Settings:=TDesfireCodec.FileSettings(0,Bytes); except on E:EDesfireError do Failed:=True; end;
    Check(Failed=not (I in [0,1,3]),'All communication/RFU variants');
  end;
  for I:=0 to 31 do
    for J:=0 to 20 do
    begin
      Bytes:=nil; SetLength(Bytes,J); if J>0 then Bytes[0]:=I;
      Failed:=False; try Settings:=TDesfireCodec.FileSettings(0,Bytes); except on E:EDesfireError do Failed:=True; end;
      // All-zero geometry is invalid, except the legitimate zero-bounded value file.
      Check(Failed=not ((I=2) and (J=17)),'Settings truncation/type/zero geometry');
    end;
  Failed:=False; try Ids:=TDesfireCodec.ApplicationIds(HexToBytes('563412563412'));
  except on E:EDesfireError do Failed:=True; end; Check(Failed,'Duplicate AIDs refused');
  Failed:=False; try Ids:=TDesfireCodec.ApplicationIds(HexToBytes('000000'));
  except on E:EDesfireError do Failed:=True; end; Check(Failed,'Root AID refused in listing');
  Bytes:=nil; SetLength(Bytes,28); V:=TDesfireCodec.Version(Bytes); Bytes[0]:=99;
  Check(V.RawBytes[0]=0,'Version output ownership');
  Writeln('PASS: Literal native wrapping, access nibbles, 24-bit/signed fields and strict settings.');
end;

procedure SuccessfulChains;
var T:TTranscript; Transport:ICardTransport; Reader:TDesfireCardReader; Data:TBytes;
  Pairs:TDesfireWirePairs; Mode:TDesfireCommunication; I,J:Integer;
  procedure ReadChain(const APairs:TDesfireWirePairs; const Kind:Integer);
  begin
    T:=TTranscript.Create(APairs); Transport:=T; Configure(Reader,T,dfcFull);
    case Kind of
      0,1:begin Data:=Reader.ReadData($CDEF01,0,0,25); Check(Length(Data)=25,'Data/backup read bytes'); end;
      2:Check(Reader.ReadValue($CDEF01,2)=-17,'Authenticated signed value');
      3,4:begin Data:=Reader.ReadRecords($CDEF01,Kind,0,2); Check(BytesEqual(Data,HexToBytes('1112131421222324')),'Record order preserved'); end;
    end;
    Check((T.Calls=Length(APairs)) and (T.Begins=1) and (T.Ends=1) and not T.Active,'Complete independent read chain');
  end;
begin
  Reader:=TDesfireCardReader.Create(nil);
  try
    for I:=0 to 2 do
    begin
      Mode:=TDesfireCommunication(I); Reader.MaxFrameDataBytes:=48;
      case Mode of dfcPlain:Pairs:=Ev2ReadPlain; dfcMac:Pairs:=Ev2ReadMac; dfcFull:Pairs:=Ev2ReadFull; end;
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,Mode); T.Reenter:=True;
      Data:=Reader.ReadData($CDEF01,0,0,25);
      Check(Length(Data)=25,'All authenticated communication modes');
      for J:=0 to High(Data) do Check(Data[J]=J,'Independent acquired data');
      Check((T.Calls=Length(Pairs)) and not Reader.Busy and not T.Active,'Read release before success');
      case Mode of dfcPlain:Pairs:=Ev2WritePlain; dfcMac:Pairs:=Ev2WriteMac; dfcFull:Pairs:=Ev2WriteFull; end;
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,Mode); FillChar(Data[0],Length(Data),$22);
      Reader.WriteData($CDEF01,0,0,Data); Check((T.Calls=Length(Pairs)) and (T.Writes=1),'Verified write complete');
      Reader.MaxFrameDataBytes:=16;
      case Mode of dfcPlain:Pairs:=Ev2WritePlainChained; dfcMac:Pairs:=Ev2WriteMacChained; dfcFull:Pairs:=Ev2WriteFullChained; end;
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,Mode);
      Reader.WriteData($CDEF01,0,0,Data); Check((T.Calls=Length(Pairs)) and (T.Writes=1),'Outbound/inbound AF chains and single logical write');
    end;
    Reader.MaxFrameDataBytes:=48;
    ReadChain(Ev2ReadBackup,1); ReadChain(Ev2ReadValue,2); ReadChain(Ev2ReadLinear,3); ReadChain(Ev2ReadCyclic,4);
    SetLength(Data,25); FillChar(Data[0],25,$22);
    Reader.Security:=dfsPublic; Reader.MaxFrameDataBytes:=16; Pairs:=PublicWriteChained;
    T:=TTranscript.Create(Pairs); Transport:=T; Reader.Transport:=Transport;
    Reader.WriteData($CDEF01,0,0,Data); Check((T.Calls=Length(Pairs)) and (T.Writes=1),'Public legacy BD/3D AF write/readback');
  finally Reader.Free; Transport:=nil; end;
  Writeln('PASS: Plain/MACed/Full AES sessions, legacy public writes, backup/value/record reads and both AF directions.');
end;

procedure FailureChains;
var T:TTranscript; Transport:ICardTransport; Reader:TDesfireCardReader; Data:TBytes;
  Pairs:TDesfireWirePairs; I,J,K,FirstWrite,Calls:Integer; Failed,Uncertain:Boolean;
begin
  Reader:=TDesfireCardReader.Create(nil); Data:=nil; SetLength(Data,25); FillChar(Data[0],25,$22);
  try
    Pairs:=Ev2WriteFullChained; FirstWrite:=0;
    for I:=0 to High(Pairs) do if Pos('908D',Pairs[I].Command)=1 then begin FirstWrite:=I+1; Break; end;
    Check(FirstWrite>0,'Fixture includes native write'); Reader.MaxFrameDataBytes:=16;
    for I:=1 to Length(Pairs) do
    begin
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull); T.FailCall:=I;
      Failed:=False; Uncertain:=False;
      try Reader.WriteData($CDEF01,0,0,Data);
      except on E:Exception do begin Failed:=True; Uncertain:=E is EContactlessWriteUncertain; end; end;
      Check(Failed and (Uncertain=(I>=FirstWrite)),'Every I/O failure has correct dispatch boundary');
      Check((T.Calls=I) and (T.Ends=1) and not T.Active and not Reader.Busy,'Failure cleanup and no replay');
    end;
    // Every bit in every protected response must fail; no plaintext or successful receipt escapes.
    Reader.MaxFrameDataBytes:=48; Pairs:=Ev2WriteFull; FirstWrite:=7;
    for I:=0 to High(Pairs) do
      for J:=0 to Length(Pairs[I].Response) div 2-1 do
        for K:=0 to 7 do
        begin
          T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull);
          T.CorruptCall:=I+1; T.CorruptByte:=J; T.CorruptBit:=K; Failed:=False;
          try Reader.WriteData($CDEF01,0,0,Data); except on E:Exception do Failed:=True; end;
          Check(Failed,'All protected responses/statuses reject single-bit corruption');
          Check((T.Ends=1) and not T.Active and not Reader.Busy,'Corruption cleanup');
          Check(T.Calls<=Length(Pairs)+1,'No unbounded continuation or retry');
        end;
    T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull); T.EndFails:=True;
    Uncertain:=False; try Reader.WriteData($CDEF01,0,0,Data); except on E:EContactlessWriteUncertain do Uncertain:=True; end;
    Check(Uncertain and not Reader.Busy and not T.Active,'Verified write with failed release stays uncertain');
    T:=TTranscript.Create(Ev2ReadFull); Transport:=T; Configure(Reader,T,dfcFull); T.FailCall:=2; T.EndFails:=True;
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:ECardTransportError do Failed:=True; end;
    Check(Failed,'Acquisition/auth primary failure wins over release');
    T:=TTranscript.Create(Ev2ReadFull); Transport:=T; Configure(Reader,T,dfcFull); T.BeginFails:=True;
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:ECardTransportError do Failed:=True; end;
    Check(Failed and (T.Ends=0) and (T.Calls=0) and not Reader.Busy,'Failed acquisition owns no transaction');
    T:=TTranscript.Create(Ev2ReadPlain); Transport:=T; Configure(Reader,T,dfcMac);
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=4),'Minimum communication prevents downgrade before file read');
    Calls:=T.Calls; Reader.AuthenticationKey:=nil;
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=Calls),'Missing AES credentials refused before any I/O');
  finally Reader.Free; Transport:=nil; end;
  Writeln('PASS: Every I/O and protected-response bit, dispatch uncertainty, no downgrade, reentrancy and cleanup.');
end;

procedure DiscoveryAndPolicy;
var T:TTranscript; Transport:ICardTransport; Reader:TDesfireCardReader;
  Pairs:TDesfireWirePairs; V:TDesfireVersion; Ids:TDesfireApplicationIds;
  Files:TDesfireFiles; Data:TBytes; Failed:Boolean; I:Integer;
  procedure Pair(const Index:Integer; const Command,Response:string);
  begin Pairs[Index].Command:=Command; Pairs[Index].Response:=Response; end;
begin
  Reader:=TDesfireCardReader.Create(nil);
  try
    Pairs:=nil; SetLength(Pairs,4);
    Pair(0,'905A00000300000000','9100');
    Pair(1,'9060000000','0401010100180591AF');
    Pair(2,'90AF000000','0401010100180591AF');
    Pair(3,'90AF000000','04010203040506010203040520259100');
    T:=TTranscript.Create(Pairs); Transport:=T; Reader.Transport:=Transport;
    V:=Reader.ReadVersion; Check((Length(V.RawBytes)=28) and (V.Vendor=4) and (T.Calls=4),'Published version three-frame shape');
    SetLength(Pairs,3); Pair(0,'905A00000300000000','9100');
    Pair(1,'906A000000','563491AF'); Pair(2,'90AF000000','1201EFCD9100');
    T:=TTranscript.Create(Pairs); Transport:=T; Reader.Transport:=Transport;
    Ids:=Reader.ReadApplicationIds; Check((Length(Ids)=2) and (Ids[0]=$123456) and (Ids[1]=$CDEF01),'AID split across continuation frames');
    Pairs:=Ev2Directory; T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull);
    Files:=Reader.ReadFiles($CDEF01);
    Check((Length(Files)=5) and (T.Calls=Length(Pairs)),'Directory plus authenticated metadata');
    for I:=0 to 4 do Check(Ord(Files[I].FileType)=I,'All ordinary file types in order');
    Pairs:=Ev2DeniedRead; T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull); Failed:=False;
    try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=4),'Wrong acquired key rights prevent data command');
    Pairs:=Ev2WriteWithoutRead; T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull); Failed:=False;
    SetLength(Data,25); FillChar(Data[0],25,$22);
    try Reader.WriteData($CDEF01,0,0,Data); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=4) and (T.Writes=0),'Write without verification rights rejected before dispatch');
    Pairs:=Ev2ReadBackup; T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull); Failed:=False;
    try Reader.WriteData($CDEF01,0,0,Data); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=4) and (T.Writes=0),'Backup transaction write is not inferred from standard write');
    Pairs:=nil; SetLength(Pairs,2); Pair(0,'905A00000300000000','9100'); Pair(1,'9060000000','91AF');
    T:=TTranscript.Create(Pairs); Transport:=T; Reader.Transport:=Transport; Failed:=False;
    try V:=Reader.ReadVersion; except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=2),'Nonprogress read continuation stops immediately');
    Pairs:=PublicWriteChained; Pairs[1].Response:='0000EEEE0000009100';
    T:=TTranscript.Create(Pairs); Transport:=T; Reader.Transport:=Transport; Reader.Security:=dfsPublic; Failed:=False;
    try Reader.WriteData($CDEF01,0,0,Data); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=2) and (T.Writes=0),'Invalid acquired capacity prevents writing');
  finally Reader.Free; Transport:=nil; end;
  Writeln('PASS: Version/app/file discovery, authenticated settings and operation-specific access policy.');
end;

procedure BoundsAndNoop;
var T:TTranscript; Transport:ICardTransport; Reader:TDesfireCardReader; Data:TBytes;
  Pairs:TDesfireWirePairs; Provider:TFixedProvider; Failed:Boolean; I:Integer;
  procedure DeniedBeforeIo(const Action:Integer);
  begin
    Failed:=False;
    try
      case Action of
        0:Data:=Reader.ReadData(0,0,0,1);
        1:Data:=Reader.ReadData($CDEF01,32,0,1);
        2:Data:=Reader.ReadData($CDEF01,0,-1,1);
        3:Data:=Reader.ReadData($CDEF01,0,0,0);
        4:Data:=Reader.ReadRecords($CDEF01,0,0,0);
        5:Reader.WriteData($CDEF01,0,0,nil);
        6:Reader.MaxFrameDataBytes:=15;
        7:Reader.KeyNumber:=14;
        8:Reader.MaxTransferBytes:=0;
      end;
    except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=0) and (T.Begins=0),'Local bounds refused before I/O');
  end;
begin
  Reader:=TDesfireCardReader.Create(nil);
  try
    Pairs:=Ev2ReadFull; T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull);
    for I:=0 to 8 do DeniedBeforeIo(I);
    Data:=nil; SetLength(Data,25); for I:=0 to High(Data) do Data[I]:=I;
    Reader.WriteData($CDEF01,0,0,Data);
    Check((T.Writes=0) and (T.Calls=Length(Pairs)),'Verified no-op omits native write');
    T:=TTranscript.Create(Ev2ReadFull); Transport:=T; Configure(Reader,T,dfcFull);
    Reader.MaxTransferBytes:=24; Failed:=False;
    try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=0),'Configured transfer cap before I/O'); Reader.MaxTransferBytes:=65536;
    Reader.MaxTransferBytes:=1; Failed:=False;
    try I:=Reader.ReadValue($CDEF01,0); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=0),'Value payload also observes configured transfer cap'); Reader.MaxTransferBytes:=65536;
    T:=TTranscript.Create(Ev2ReadFull); Transport:=T; Configure(Reader,T,dfcFull);
    Provider:=TFixedProvider.Create(Base); Provider.RandomFails:=True; Reader.CryptoProvider:=Provider;
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:ECardCryptoError do Failed:=True; end;
    Check(Failed and (T.Calls=2) and (T.Ends=1),'CSPRNG failure never sends a challenge');
    T:=TTranscript.Create(Ev2ReadFull); Transport:=T; Configure(Reader,T,dfcFull);
    Provider:=TFixedProvider.Create(Base); Provider.MalformedRandom:=True; Reader.CryptoProvider:=Provider;
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=2) and (T.Ends=1),'Malformed provider nonce refused');
    Pairs:=Ev2ReadFull; Pairs[3].Response:=Copy(Pairs[3].Response,1,Length(Pairs[3].Response)-2)+'AE';
    T:=TTranscript.Create(Pairs); Transport:=T; Configure(Reader,T,dfcFull);
    Failed:=False; try Data:=Reader.ReadData($CDEF01,0,0,25); except on E:EDesfireStatusError do begin Failed:=True; Check(E.Status=$AE,'Native status retained'); end; end;
    Check(Failed and (T.Calls=4),'Denied native status has no replay or fallback');
  finally Reader.Free; Transport:=nil; end;
  Writeln('PASS: Local bounds, credential/nonce failures, no-op writes and typed native status.');
end;

begin
  try
{$IFDEF MSWINDOWS}
    Base:=TCardWindowsAesProvider.Create;
{$ELSE}
    Base:=TCardOpenSslAesProvider.Create;
{$ENDIF}
    CodecTests; SuccessfulChains; FailureChains; DiscoveryAndPolicy; BoundsAndNoop;
    Writeln('PASS: 5 DESFire groups; ',Assertions,' assertions.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
