program DesfireSessionTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
{$IFDEF FPC}
{$IFDEF UNIX}
  cthreads,
{$ENDIF}
  SysUtils,Classes,
{$ELSE}
  System.SysUtils,System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Crypto,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows,
{$ELSE}
  ERD.Card.Crypto.OpenSSL,
{$ENDIF}
  ERD.Card.Contactless, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.DESFire.EV1, Desfire.Vectors, Desfire.SessionVectors;

type
  TFixedProvider = class(TInterfacedObject,ICardAesProvider)
  private
    FBase:ICardAesProvider;
  public
    RandomFails,MalformedRandom:Boolean;
    RandomCalls,RandomFailCall:Integer;
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
    Session:IDesfireSession;
    constructor Create(const APairs:TDesfireWirePairs);
    function Exchange(const ACommand:TBytes):TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;

  TWrongThread = class(TThread)
  public
    Session:IDesfireSession;
    Rejected:Boolean;
    procedure Execute; override;
  end;

var Assertions:Integer; Base:ICardAesProvider;
procedure Check(const Condition:Boolean; const Text:string);
begin Inc(Assertions); if not Condition then raise Exception.Create(Text); end;

procedure TWrongThread.Execute;
begin
  try Session.WriteBackup(1,4,HexToBytes('AABBCCDD'));
  except on E:EDesfireError do Rejected:=True; end;
end;

constructor TFixedProvider.Create(const Base:ICardAesProvider);
begin inherited Create; FBase:=Base; end;
function TFixedProvider.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.EncryptCbc(AKey,AIv,AData); end;
function TFixedProvider.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.DecryptCbc(AKey,AIv,AData); end;
function TFixedProvider.RandomBytes(const ACount:Integer):TBytes;
begin
  Inc(RandomCalls);
  if RandomFails or (RandomCalls=RandomFailCall) then raise ECardCryptoError.Create('Synthetic RNG failure');
  if ACount<>16 then raise ECardCryptoError.Create('Unexpected nonce size');
  Result:=HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE');
  if RandomCalls>1 then Result:=HexToBytes('112233445566778899AABBCCDDEEFF00');
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
var Failed:Boolean;
begin
  Result:=nil; if not Active then raise ECardTransportError.Create('Exchange without acquisition');
  Inc(Calls);
  if (Length(ACommand)>=2) and (ACommand[1] in [$3D,$8D,$0C,$DC,$1C,$3B,$8B,$EB,$C7,$A7,$CA,$DA,$CD,$CB,$CC,$C1,$C0,$DF]) then Inc(Writes);
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure');
  if Reenter then
  begin
    Reenter:=False; Failed:=False;
    try Session.ReadApplicationSettings; except on E:EDesfireError do Failed:=True; end;
    Check(Failed,'Nested operation refused');
    Failed:=False; try Session.Close; except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (Session.Outcome=dsoActive),'Nested close refused without losing ownership');
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

procedure Configure(const Reader:TDesfireCardReader; const T:TTranscript;
  const Security:TDesfireSecurity; const Mode:TDesfireCommunication);
begin
  Reader.Transport:=T; Reader.Security:=Security; Reader.CryptoProvider:=TFixedProvider.Create(Base);
  Reader.AuthenticationKey:=HexToBytes('00000000000000000000000000000000');
  Reader.MinimumCommunication:=Mode;
end;

procedure Workflow(const S:IDesfireSession; const ClearCyclic:Boolean=False);
begin
  S.WriteBackup(1,4,HexToBytes('AABBCCDD'));
  Check(S.PendingChanges and (S.Outcome=dsoActive),'Staging retains active ownership');
  S.WriteBackup(1,6,HexToBytes('EEFF')); S.WriteBackup(1,6,HexToBytes('EEFF'));
  S.Credit(2,10); S.Debit(2,3); S.LimitedCredit(2,2);
  S.AppendRecord(3,HexToBytes('41424344'));
  S.AppendRecord(4,HexToBytes('51525354')); S.AppendRecord(4,HexToBytes('61626364'));
  S.ClearRecords(3); S.AppendRecord(3,HexToBytes('71727374'));
  if ClearCyclic then S.ClearRecords(4);
  S.Commit;
end;

function Definition(const Kind:Integer; const Mode:TDesfireCommunication):TDesfireFileDefinition;
begin
  Result:=Default(TDesfireFileDefinition); Result.FileNumber:=Kind;
  Result.FileType:=TDesfireFileType(Kind); Result.Communication:=Mode;
  case Kind of
    0,1:Result.FileBytes:=32;
    2:begin Result.LowerLimit:=-100; Result.UpperLimit:=100; Result.InitialValue:=10; Result.LimitedCreditEnabled:=True; end;
    3,4:begin Result.RecordBytes:=4; Result.MaxRecords:=3; end;
  end;
end;

procedure Success(const Pairs:TDesfireWirePairs; const Security:TDesfireSecurity;
  const Mode:TDesfireCommunication; const Kind:Integer;
  const Access:TDesfireSessionAccess=dsaFreshTransaction; const Frame:Integer=48;
  const NonFirst:Boolean=False);
var T:TTranscript; Transport:ICardTransport; R:TDesfireCardReader; S:IDesfireSession; I:Integer; Aid:Cardinal;
begin
  R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Pairs); Transport:=T;
  try
    Configure(R,T,Security,Mode); R.MaxFrameDataBytes:=Frame;
    if NonFirst then begin R.ReauthenticationKey:=HexToBytes('000102030405060708090A0B0C0D0E0F'); R.ReauthenticationKeyNumber:=1; end;
    Aid:=$CDEF01; if Kind=3 then Aid:=0;
    S:=R.OpenSession(Aid,Access);
    Check((T.Begins=1) and (T.Ends=0) and T.Active,'Session retains transport transaction');
    R.Free; R:=nil; // Session owns an immutable engine, credentials and transport reference.
    case Kind of
      0,4:begin
        T.Session:=S; T.Reenter:=True;
        try Workflow(S,Kind=4); finally T.Session:=nil; end;
        Check((S.Outcome=dsoCommitted) and S.VerificationSucceeded and not S.PendingChanges,'Known commit and verified data');
      end;
      1:begin S.WriteBackup(1,4,HexToBytes('AABBCCDD')); S.Abort;
        Check((S.Outcome=dsoAborted) and not S.PendingChanges and not S.VerificationSucceeded,'Known explicit abort'); end;
      2:begin
        for I:=0 to 4 do S.CreateFile(Definition(I,Mode));
        for I:=4 downto 0 do S.DeleteFile(I);
        S.Close; Check(S.Outcome=dsoClosed,'Management closes without commit or abort');
      end;
      3:begin S.CreateApplication($CDEF01,$0F,1); S.DeleteApplication($CDEF01); S.Close; end;
    end;
    Check((T.Calls=Length(Pairs)) and (T.Ends=1) and not T.Active,'Complete independent transcript exactly once');
    S.Close; S:=nil; Check(T.Ends=1,'Close and destructor cannot release twice');
  finally S:=nil; R.Free; Transport:=nil; end;
end;

procedure SuccessfulChains;
begin
  Success(PublicPlainTransaction,dfsPublic,dfcPlain,0);
  Success(Ev1PlainTransaction,dfsEv1Aes,dfcPlain,0);
  Success(Ev1MacTransaction,dfsEv1Aes,dfcMac,0);
  Success(Ev1FullTransaction,dfsEv1Aes,dfcFull,0);
  Success(Ev2PlainTransaction,dfsEv2Aes,dfcPlain,0);
  Success(Ev2MacTransaction,dfsEv2Aes,dfcMac,0);
  Success(Ev2FullTransaction,dfsEv2Aes,dfcFull,0);
  Success(PublicPlainAbort,dfsPublic,dfcPlain,1,dsaDiscardPending);
  Success(Ev1PlainAbort,dfsEv1Aes,dfcPlain,1,dsaDiscardPending);
  Success(Ev1MacAbort,dfsEv1Aes,dfcMac,1,dsaDiscardPending);
  Success(Ev1FullAbort,dfsEv1Aes,dfcFull,1,dsaDiscardPending);
  Success(Ev2PlainAbort,dfsEv2Aes,dfcPlain,1,dsaDiscardPending);
  Success(Ev2MacAbort,dfsEv2Aes,dfcMac,1,dsaDiscardPending);
  Success(Ev2FullAbort,dfsEv2Aes,dfcFull,1,dsaDiscardPending);
  Success(PublicPlainManageFiles,dfsPublic,dfcPlain,2,dsaManage);
  Success(Ev1PlainManageFiles,dfsEv1Aes,dfcPlain,2,dsaManage);
  Success(Ev1MacManageFiles,dfsEv1Aes,dfcMac,2,dsaManage);
  Success(Ev1FullManageFiles,dfsEv1Aes,dfcFull,2,dsaManage);
  Success(Ev2PlainManageFiles,dfsEv2Aes,dfcPlain,2,dsaManage);
  Success(Ev2MacManageFiles,dfsEv2Aes,dfcMac,2,dsaManage);
  Success(Ev2FullManageFiles,dfsEv2Aes,dfcFull,2,dsaManage);
  Success(PublicManageApplications,dfsPublic,dfcPlain,3,dsaManage);
  Success(Ev1ManageApplications,dfsEv1Aes,dfcPlain,3,dsaManage);
  Success(Ev2ManageApplications,dfsEv2Aes,dfcPlain,3,dsaManage);
  Success(Ev2NonFirstTransaction,dfsEv2Aes,dfcFull,0,dsaDiscardPending,48,True);
  Success(Ev2ChainedTransaction,dfsEv2Aes,dfcFull,0,dsaDiscardPending,16);
  Success(Ev1ChainedTransaction,dfsEv1Aes,dfcFull,0,dsaDiscardPending,16);
  Success(Ev2ClearTransaction,dfsEv2Aes,dfcFull,4);
  Writeln('PASS: Independent public/EV1/EV2 staged data/value/record, abort and management transcripts.');
end;

procedure FailureChains(const Pairs:TDesfireWirePairs; const Security:TDesfireSecurity; const Corrupt:Boolean);
var T:TTranscript; Transport:ICardTransport; R:TDesfireCardReader; S:IDesfireSession;
  I,J,K,FirstWrite,CommitCall:Integer; Failed,Uncertain:Boolean;
  procedure Attempt;
  begin
    S:=nil; Failed:=False; Uncertain:=False;
    try S:=R.OpenSession($CDEF01,dsaFreshTransaction); Workflow(S);
    except on E:Exception do begin Failed:=True; Uncertain:=E is EContactlessWriteUncertain; end; end;
    Check(Failed,'Injected failure cannot produce success');
    Check((T.Ends=1) and not T.Active,'Every acquired failed operation releases once');
    if S<>nil then
    begin
      Check(not S.VerificationSucceeded,'Failed commit cannot claim complete verification');
      if T.Calls>CommitCall then Check(S.Outcome=dsoCommitted,'Verified commit acknowledgement survives later failure')
      else if T.Calls>=FirstWrite then Check(S.Outcome=dsoUncertain,'Mutation or commit acknowledgement failure remains unknown')
      else Check(S.Outcome=dsoClosed,'Pre-mutation failures close without claiming write');
      S.Close;
    end;
    Check(T.Ends=1,'No implicit native recovery or duplicate release');
    S:=nil;
  end;
begin
  FirstWrite:=0; CommitCall:=0;
  for I:=0 to High(Pairs) do
  begin
    if (FirstWrite=0) and ((Pos('908D',Pairs[I].Command)=1) or (Pos('903D',Pairs[I].Command)=1)) then FirstWrite:=I+1;
    if Pos('90C7',Pairs[I].Command)=1 then CommitCall:=I+1;
  end;
  R:=TDesfireCardReader.Create(nil);
  try
    for I:=1 to Length(Pairs) do
    begin
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(R,T,Security,dfcFull); T.FailCall:=I;
      Attempt; Check((T.Calls=I) and (Uncertain=(I>=FirstWrite)),'Exact dispatch boundary and no retry');
    end;
    if Corrupt then
      for I:=0 to High(Pairs) do
        for J:=0 to Length(Pairs[I].Response) div 2-1 do
          for K:=0 to 7 do
          begin
            T:=TTranscript.Create(Pairs); Transport:=T; Configure(R,T,Security,dfcFull);
            T.CorruptCall:=I+1; T.CorruptByte:=J; T.CorruptBit:=K;
            Attempt; Check(T.Calls<=I+2,'Corrupted frame cannot trigger unbounded continuation or replay');
          end;
    T:=TTranscript.Create(Pairs); Transport:=T; Configure(R,T,Security,dfcFull); T.EndFails:=True;
    Failed:=False; S:=R.OpenSession($CDEF01,dsaFreshTransaction);
    try Workflow(S); except on E:EContactlessWriteUncertain do Failed:=True; end;
    Check(Failed and (S.Outcome=dsoCommitted) and not S.VerificationSucceeded and not S.PendingChanges,'Release failure preserves known commit');
    S:=nil;
    T:=TTranscript.Create(Pairs); Transport:=T; Configure(R,T,Security,dfcFull); T.BeginFails:=True;
    Failed:=False; try S:=R.OpenSession($CDEF01,dsaFreshTransaction); except on E:ECardTransportError do Failed:=True; end;
    Check(Failed and (T.Calls=0) and (T.Ends=0),'Failed acquisition never releases unowned transport');
  finally S:=nil; R.Free; Transport:=nil; end;
end;

procedure ManagementFailures(const Pairs:TDesfireWirePairs; const Security:TDesfireSecurity; const Apps:Boolean);
var T:TTranscript; Transport:ICardTransport; R:TDesfireCardReader; S:IDesfireSession;
  I,J:Integer; Failed:Boolean; Aid:Cardinal; Mode:TDesfireCommunication;
begin
  R:=TDesfireCardReader.Create(nil); Aid:=$CDEF01; if Apps then Aid:=0;
  Mode:=dfcFull; if Security=dfsPublic then Mode:=dfcPlain;
  try
    for I:=1 to Length(Pairs) do
    begin
      T:=TTranscript.Create(Pairs); Transport:=T; Configure(R,T,Security,Mode); T.FailCall:=I;
      Failed:=False; S:=nil;
      try
        S:=R.OpenSession(Aid,dsaManage);
        if Apps then begin S.CreateApplication($CDEF01,$0F,1); S.DeleteApplication($CDEF01); end
        else
        begin
          for J:=0 to 4 do S.CreateFile(Definition(J,Mode));
          for J:=4 downto 0 do S.DeleteFile(J);
        end;
      except on E:Exception do Failed:=True; end;
      Check(Failed and (T.Calls=I) and (T.Ends=1) and not T.Active,'Administrative I/O failure stops at first failing exchange');
      if S<>nil then Check(S.Outcome in [dsoClosed,dsoUncertain],'Management failure closes and retains uncertainty');
      S:=nil; Check(T.Ends=1,'No administrative replay or double release');
    end;
  finally S:=nil; R.Free; Transport:=nil; end;
end;

procedure SessionReads(const Pairs:TDesfireWirePairs; const Security:TDesfireSecurity);
var R:TDesfireCardReader; T:TTranscript; Transport:ICardTransport; S:IDesfireSession;
  Settings:TDesfireApplicationSettings; Files:TDesfireFiles; B:TBytes; Mode:TDesfireCommunication;
begin
  R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Pairs); Transport:=T;
  try
    Mode:=dfcFull; if Security=dfsPublic then Mode:=dfcPlain; Configure(R,T,Security,Mode);
    S:=R.OpenSession($CDEF01,dsaReadOnly); Settings:=S.ReadApplicationSettings;
    Check((Settings.KeySettings=$0F) and (Settings.KeyConfiguration=$81),'Authenticated application settings');
    Files:=S.ReadFiles; Check(Length(Files)=5,'Complete retained ordinary directory');
    B:=S.ReadData(1,4,4); Check(BytesEqual(B,HexToBytes('04050607')),'Retained explicit backup range');
    Check(S.ReadValue(2)=10,'Retained signed value');
    B:=S.ReadRecords(3,0,2); Check(BytesEqual(B,HexToBytes('1112131421222324')),'Retained newest-first records');
    S.Close; Check((S.Outcome=dsoClosed) and (T.Calls=Length(Pairs)) and (T.Writes=0),'Read-only session sends no native mutation');
  finally S:=nil; R.Free; Transport:=nil; end;
end;

procedure SemanticCases;
var R:TDesfireCardReader; T:TTranscript; Transport:ICardTransport; S:IDesfireSession;
  Pairs:TDesfireWirePairs; Failed:Boolean; I,Calls:Integer;
  procedure Setup(const Wire:TDesfireWirePairs; const Access:TDesfireSessionAccess=dsaFreshTransaction);
  begin
    S:=nil; R.Free; R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Wire); Transport:=T;
    Configure(R,T,dfsEv2Aes,dfcFull); S:=R.OpenSession($CDEF01,Access);
  end;
  procedure Refused(const Kind:Integer);
  begin
    Failed:=False;
    try
      case Kind of
        0:S.Credit(2,1);
        1:S.Credit(2,1);
        2:S.Debit(2,1);
        3:S.LimitedCredit(2,21);
        4:S.WriteBackup(1,4,HexToBytes('AABBCCDD'));
        5:S.AppendRecord(3,HexToBytes('41424344'));
      end;
    except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Writes=0),'Authenticated semantic/access failure occurs before mutation');
    Check((T.Calls=Length(T.Pairs)) and (S.Outcome=dsoClosed),'Protected preflight failure poisons only acquired session');
    S:=nil;
  end;
begin
  R:=nil;
  try
    Setup(Ev2CreditWriteOnlyDenied); Refused(0);
    Setup(Ev2UpperOverflow); Refused(1);
    Setup(Ev2LowerOverflow); Refused(2);
    Setup(Ev2LimitedAllowanceExceeded); Refused(3);
    Setup(Ev2BackupReadDenied); Refused(4);
    Setup(Ev2FullLinearDenied); Refused(5);
    Setup(Ev2DebitReadOnly); S.Debit(2,3); S.Commit;
    Check(S.VerificationSucceeded and (T.Calls=Length(T.Pairs)),'Debit succeeds through Read route');
    Setup(Ev2LimitedWriteOnly); S.LimitedCredit(2,2); S.Commit;
    Check(S.VerificationSucceeded and (T.Calls=Length(T.Pairs)),'Limited credit and GetValue succeed through Write route');
    for I:=0 to 1 do
    begin
      if I=0 then Pairs:=Ev2WrongCommittedData else Pairs:=Ev1WrongCommittedData;
      S:=nil; R.Free; R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Pairs); Transport:=T;
      if I=0 then Configure(R,T,dfsEv2Aes,dfcFull) else Configure(R,T,dfsEv1Aes,dfcFull);
      S:=R.OpenSession($CDEF01,dsaFreshTransaction); Failed:=False;
      try Workflow(S); except on E:EContactlessWriteUncertain do Failed:=True; end;
      Check(Failed and (S.Outcome=dsoCommitted) and not S.VerificationSucceeded,'Valid MAC/CRC with wrong committed bytes fails verification');
      Check((T.Ends=1) and not T.Active,'Wrong committed content releases without replay');
    end;
    S:=nil; R.Free; R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Ev2TransactionMacPreflight); Transport:=T;
    Configure(R,T,dfsEv2Aes,dfcFull); Failed:=False;
    try S:=R.OpenSession($CDEF01,dsaDiscardPending); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Writes=0) and (T.Ends=1),'TMAC is rejected before discarding previous pending state');
    T:=TTranscript.Create(Ev2AbortNoChanges); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull); Failed:=False;
    try S:=R.OpenSession($CDEF01,dsaDiscardPending); except on E:EContactlessWriteUncertain do Failed:=True; end;
    Check(Failed and (T.Calls=Length(T.Pairs)) and (T.Writes=1) and (T.Ends=1),'Unprotected NoChanges cannot establish ownership or continue authentication');
    S:=nil; R.Free; R:=TDesfireCardReader.Create(nil); T:=TTranscript.Create(Ev2DeniedManagement); Transport:=T;
    Configure(R,T,dfsEv2Aes,dfcFull); R.KeyNumber:=1; S:=R.OpenSession($CDEF01,dsaManage); Failed:=False;
    try S.CreateFile(Definition(0,dfcFull)); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Writes=0) and (T.Calls=Length(T.Pairs)),'Non-master key without free create/delete cannot administer');
    Setup(Ev2ExtendedDeleteDenied,dsaManage); Failed:=False;
    try S.DeleteFile(5); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Writes=0) and (T.Calls=Length(T.Pairs)),'Extended file deletion requires its own profile before mutation');
    Setup(Ev2UnexpectedValueOptions,dsaManage); Failed:=False;
    try S.CreateFile(Definition(2,dfcFull)); except on E:EContactlessWriteUncertain do Failed:=True; end;
    Check(Failed and (T.Writes=1) and (S.Outcome=dsoUncertain) and (T.Calls=Length(T.Pairs)),'Creation verification rejects unrequested free-GetValue option');
    S:=nil;
    T:=TTranscript.Create(PublicMutationQuota); Transport:=T; Configure(R,T,dfsPublic,dfcPlain); R.KeyNumber:=0;
    S:=R.OpenSession($CDEF01,dsaFreshTransaction);
    for I:=1 to 256 do S.Credit(2,1);
    Calls:=T.Calls; Failed:=False;
    try S.Credit(2,1); except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=Calls) and (S.Outcome=dsoActive) and S.PendingChanges,'Quota refusal remains local and permits explicit completion');
    S.Commit; Check(S.VerificationSucceeded and (T.Calls=Length(T.Pairs)),'Exactly 256 staged writes can still commit and verify');
  finally S:=nil; R.Free; Transport:=nil; end;
  Writeln('PASS: Authenticated rights, signed bounds, full linear capacity, wrong committed data, TMAC and mutation quota.');
end;

procedure JournalLimits;
var R:TDesfireCardReader; T:TTranscript; Transport:ICardTransport; S:IDesfireSession;
  I:Integer; Failed:Boolean;
begin
  R:=TDesfireCardReader.Create(nil);
  try
    for I:=0 to 3 do
    begin
      case I of
        0:begin T:=TTranscript.Create(Ev2OversizeBackupJournal); R.MaxTransferBytes:=31; end;
        1:begin T:=TTranscript.Create(Ev2AggregateJournalBound); R.MaxTransferBytes:=32; end;
        2:begin T:=TTranscript.Create(Ev2RecordGrowthBound); R.MaxTransferBytes:=8; end;
        3:begin T:=TTranscript.Create(Ev2RepeatedLimitedCredit); R.MaxTransferBytes:=32; end;
      end;
      Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull); S:=R.OpenSession($CDEF01,dsaFreshTransaction);
      Failed:=False;
      try
        case I of
          0:S.WriteBackup(1,4,HexToBytes('AABBCCDD'));
          1:begin S.WriteBackup(1,4,HexToBytes('AABBCCDD')); S.Credit(2,1); end;
          2:S.AppendRecord(3,HexToBytes('41424344'));
          3:begin S.LimitedCredit(2,2); S.LimitedCredit(2,1); end;
        end;
      except on E:EContactlessError do Failed:=True; end;
      Check(Failed and (T.Calls=Length(T.Pairs)) and (T.Ends=1),'Bound/duplicate refusal sends no further card command');
      if I in [1,3] then Check((T.Writes=1) and S.PendingChanges and (S.Outcome=dsoUncertain),'Prior acknowledged staging is never silently discarded')
      else Check((T.Writes=0) and (S.Outcome=dsoClosed),'Journal bound refuses first mutation');
      S:=nil;
    end;
  finally S:=nil; R.Free; Transport:=nil; end;
  Writeln('PASS: Whole-backup, aggregate-journal and record-growth bounds; limited-credit reuse refused.');
end;

procedure Lifecycle;
var R:TDesfireCardReader; T:TTranscript; Transport:ICardTransport; S:IDesfireSession;
  Failed:Boolean; I,Calls:Integer; D:TDesfireFileDefinition; Worker:TWrongThread;
begin
  R:=TDesfireCardReader.Create(nil);
  try
    T:=TTranscript.Create(Ev2FullTransaction); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaFreshTransaction); Calls:=T.Calls;
    Failed:=False; try S.Commit; except on E:EDesfireError do Failed:=True; end;
    Check(Failed and (T.Calls=Calls) and (S.Outcome=dsoActive),'Idle commit cannot commit unowned old pending data');
    Worker:=TWrongThread.Create(True);
    try
      Worker.Session:=S; Worker.Start; Worker.WaitFor;
      Check(Worker.Rejected and (T.Calls=Calls) and (S.Outcome=dsoActive),'Wrong-thread mutation is refused before I/O');
      Worker.Session:=nil;
    finally Worker.Free; end;
    S.WriteBackup(1,4,HexToBytes('AABBCCDD')); Calls:=T.Calls;
    for I:=0 to 4 do
    begin
      Failed:=False;
      try
        case I of
          0:S.Credit(2,0);
          1:S.WriteBackup(1,-1,HexToBytes('AA'));
          2:S.AppendRecord(3,nil);
          3:S.ReadData(1,0,0);
          4:S.DeleteFile(1);
        end;
      except on E:EDesfireError do Failed:=True; end;
      Check(Failed and (T.Calls=Calls) and (S.Outcome=dsoActive) and S.PendingChanges,'Invalid local arguments preserve active staged changes');
    end;
    S.Close; Check((S.Outcome=dsoUncertain) and S.PendingChanges and (T.Calls=Calls) and (T.Ends=1),'Abandoned changes remain unresolved with no implicit abort');
    S:=nil; Check(T.Ends=1,'Destructor cannot repeat explicit release');
    T:=TTranscript.Create(Ev2FullTransaction); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaFreshTransaction); S.WriteBackup(1,4,HexToBytes('AABBCCDD')); Calls:=T.Calls;
    S:=nil; Check((T.Calls=Calls) and (T.Ends=1),'Destructor releases only, never native commit/abort');
    T:=TTranscript.Create(Ev2FullManageFiles); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaReadOnly); Calls:=T.Calls;
    for I:=0 to 3 do
    begin
      Failed:=False; try
        case I of 0:S.Credit(2,1); 1:S.Abort; 2:S.CreateFile(Definition(0,dfcFull)); 3:S.DeleteFile(0); end;
      except on E:EDesfireError do Failed:=True; end;
      Check(Failed and (T.Calls=Calls) and (S.Outcome=dsoActive),'Read-only authority refuses all mutation categories before I/O');
    end;
    S.Close; S:=nil;
    T:=TTranscript.Create(Ev2FullManageFiles); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaManage); Calls:=T.Calls;
    for I:=0 to 5 do
    begin
      D:=Definition(0,dfcFull);
      case I of 0:D.FileBytes:=0; 1:D.FileNumber:=32; 2:D.ReadKey:=16;
        3:D.RecordBytes:=1; 4:begin D:=Definition(2,dfcFull); D.InitialValue:=101; end;
        5:begin D:=Definition(3,dfcFull); D.MaxRecords:=0; end;
      end;
      Failed:=False; try S.CreateFile(D); except on E:EDesfireError do Failed:=True; end;
      Check(Failed and (T.Calls=Calls) and (S.Outcome=dsoActive),'Invalid create geometry or access is rejected locally');
    end;
    S.Close; S:=nil;
    T:=TTranscript.Create(Ev2FullAbort); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaDiscardPending); S.WriteBackup(1,4,HexToBytes('AABBCCDD')); T.FailCall:=T.Calls+1;
    Failed:=False; try S.Abort; except on E:EContactlessWriteUncertain do Failed:=True; end;
    Check(Failed and (S.Outcome=dsoUncertain) and S.PendingChanges,'Lost abort acknowledgement remains unknown'); S:=nil;
    T:=TTranscript.Create(Ev2FullAbort); Transport:=T; Configure(R,T,dfsEv2Aes,dfcFull);
    S:=R.OpenSession($CDEF01,dsaDiscardPending); S.WriteBackup(1,4,HexToBytes('AABBCCDD')); T.EndFails:=True;
    Failed:=False; try S.Abort; except on E:EContactlessWriteUncertain do Failed:=True; end;
    Check(Failed and (S.Outcome=dsoAborted) and not S.PendingChanges,'Verified abort survives failed release'); S:=nil;
  finally S:=nil; R.Free; Transport:=nil; end;
  Writeln('PASS: Session ownership, local validation, no implicit commit/abort, teardown and known abort evidence.');
end;

begin
  try
{$IFDEF MSWINDOWS}
    Base:=TCardWindowsAesProvider.Create;
{$ELSE}
    Base:=TCardOpenSslAesProvider.Create;
{$ENDIF}
    SuccessfulChains;
    SessionReads(PublicSessionReads,dfsPublic); SessionReads(Ev1SessionReads,dfsEv1Aes); SessionReads(Ev2SessionReads,dfsEv2Aes);
    FailureChains(Ev1FullTransaction,dfsEv1Aes,True); FailureChains(Ev2FullTransaction,dfsEv2Aes,True);
    ManagementFailures(PublicPlainManageFiles,dfsPublic,False);
    ManagementFailures(Ev1FullManageFiles,dfsEv1Aes,False); ManagementFailures(Ev2FullManageFiles,dfsEv2Aes,False);
    ManagementFailures(PublicManageApplications,dfsPublic,True);
    ManagementFailures(Ev1ManageApplications,dfsEv1Aes,True); ManagementFailures(Ev2ManageApplications,dfsEv2Aes,True);
    SemanticCases; JournalLimits; Lifecycle;
    Base:=nil;
    Writeln('PASS: ',Assertions,' assertions in DESFire session tests.');
  except on E:Exception do begin Writeln('FAIL: ',E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
