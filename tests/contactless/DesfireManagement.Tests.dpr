program DesfireManagementTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}
{$IFDEF UNIX}
  cthreads,
{$ENDIF}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes,ERD.Card.Transport,ERD.Card.Crypto,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows,
{$ELSE}
  ERD.Card.Crypto.OpenSSL,
{$ENDIF}
  ERD.Card.Contactless,ERD.Card.Contactless.DESFire,ERD.Card.Contactless.DESFire.EV2,
  Desfire.Vectors,Desfire.ManagementVectors;
type
  TFixedProvider=class(TInterfacedObject,ICardAesProvider)
  private
    FBase:ICardAesProvider;
  public
    Calls,FailRandom:Integer;
    constructor Create(const Base:ICardAesProvider);
    function EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function RandomBytes(const ACount:Integer):TBytes;
  end;
  TTranscript=class(TInterfacedObject,ICardTransport,ICardTransaction)
  public
    Pairs:TDesfireWirePairs;
    Calls,Begins,Ends,Writes,FailCall,CorruptCall,CorruptByte,CorruptBit,ReplaceCall:Integer;
    Replacement:TBytes;
    Active,EndFails:Boolean;
    constructor Create(const APairs:TDesfireWirePairs);
    function Exchange(const ACommand:TBytes):TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
var Checks:Integer;Base:ICardAesProvider;
procedure Check(const Value:Boolean;const Text:string);
begin Inc(Checks);if not Value then raise Exception.Create(Text);end;
constructor TFixedProvider.Create(const Base:ICardAesProvider);
begin inherited Create;FBase:=Base;end;
function TFixedProvider.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.EncryptCbc(AKey,AIv,AData);end;
function TFixedProvider.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.DecryptCbc(AKey,AIv,AData);end;
function TFixedProvider.RandomBytes(const ACount:Integer):TBytes;
begin
  Inc(Calls);if Calls=FailRandom then raise ECardCryptoError.Create('Synthetic RNG failure');
  Check(ACount=16,'Native DESFire nonce count');
  if Calls=1 then Result:=HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE')
  else Result:=HexToBytes('112233445566778899AABBCCDDEEFF00');
end;
constructor TTranscript.Create(const APairs:TDesfireWirePairs);
begin inherited Create;Pairs:=Copy(APairs,0,Length(APairs));end;
procedure TTranscript.BeginTransaction;
begin Inc(Begins);Check(not Active,'Exclusive begin');Active:=True;end;
procedure TTranscript.EndTransaction;
begin Inc(Ends);Check(Active,'Owned release');Active:=False;
  if EndFails then raise ECardTransportError.Create('Synthetic release failure');end;
function TTranscript.Exchange(const ACommand:TBytes):TBytes;
begin
  Check(Active,'Acquired exchange');Inc(Calls);Check(Calls<=Length(Pairs),'No replay/extra exchange');
  if not ((CorruptCall=6) and (Calls in [7,8]) and ((Copy(Pairs[5].Command,3,2)='AA') or (Copy(Pairs[5].Command,3,2)='71'))) then
    Check(BytesEqual(ACommand,HexToBytes(Pairs[Calls-1].Command)),'Independent administration command '+IntToStr(Calls));
  if ACommand[1] in [$54,$5F,$C4] then Inc(Writes);
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure');
  Result:=HexToBytes(Pairs[Calls-1].Response);
  if Calls=ReplaceCall then Result:=Copy(Replacement,0,Length(Replacement));
  if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
procedure Configure(const R:TDesfireCardReader;const T:TTranscript;const Ev2:Boolean);
begin
  R.Transport:=T;R.CryptoProvider:=TFixedProvider.Create(Base);
  R.AuthenticationKey:=HexToBytes('00000000000000000000000000000000');R.MinimumCommunication:=dfcFull;
  if Ev2 then R.Security:=dfsEv2Aes else R.Security:=dfsEv1Aes;
end;
procedure Workflow(const S:IDesfireManagement;const Kind:Integer);
var Settings:TDesfireApplicationSettings;
begin
  case Kind of
    0:begin
      Check(S.ReadKeyVersion(1)=$21,'Acquired key version');S.ChangeKeySettings($EF);
      S.ChangeFileAccess(0,dfcMac,$E,1,1,0);
    end;
    1,2,3:begin
      if Kind=2 then S.ChangeAesKey(1,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'))
      else S.ChangeAesKey(0,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),nil);
      Settings:=S.ReadApplicationSettings;Check(Settings.KeySettings=$0F,'New authentication session remains usable');
    end;
    4:Check(S.ReadFreeMemory=$123456,'Root free memory 24-bit LE');
    5,7:S.ChangeKeySettings($EF);
    6,9:S.ChangeFileAccess(0,dfcMac,$E,1,1,0);
    8:S.ChangeAesKey(1,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
  end;
end;
procedure Run(const Pairs:TDesfireWirePairs;const Ev2:Boolean;const Kind,Fail,Corrupt,Position,Bit:Integer;
  const Replace:TBytes;const ReplaceCall:Integer;const ExpectedFailure,EndFails:Boolean;const RandomFailure:Integer=0);
var T:TTranscript;Transport:ICardTransport;R:TDesfireCardReader;S:IDesfireManagement;
  P:TFixedProvider;Aid:Cardinal;Rejected,Uncertain:Boolean;
begin
  T:=TTranscript.Create(Pairs);Transport:=T;R:=TDesfireCardReader.Create(nil);S:=nil;
  try
    Configure(R,T,Ev2);P:=TFixedProvider.Create(Base);R.CryptoProvider:=P;P.FailRandom:=RandomFailure;
    T.FailCall:=Fail;T.CorruptCall:=Corrupt;T.CorruptByte:=Position;T.CorruptBit:=Bit;T.Replacement:=Replace;
    T.ReplaceCall:=ReplaceCall;T.EndFails:=EndFails;Aid:=$CDEF01;if Kind in [3,4] then Aid:=0;
    Rejected:=False;Uncertain:=False;
    try
      S:=R.OpenManagementSession(Aid);
      Check((S.Outcome=dsoActive) and T.Active and (T.Ends=0),'Management retains acquired ownership');
      Workflow(S,Kind);
      Check((S.Outcome=dsoActive) and not S.PendingChanges,'Verified immediate change leaves active session');
      Check(BytesToHex(R.AuthenticationKey)='00000000000000000000000000000000','Source component credentials unchanged');
      S.Close;
    except
      on E:EContactlessWriteUncertain do begin Rejected:=True;Uncertain:=True;end;
      on E:Exception do Rejected:=True;
    end;
    Check(Rejected=ExpectedFailure,'Expected administration outcome');
    if S<>nil then
      if Uncertain then Check(S.Outcome=dsoUncertain,'Dispatched/unverified mutation uncertain')
      else Check(S.Outcome=dsoClosed,'Closed verified/read-only outcome');
    Check((T.Begins=1) and (T.Ends=1) and not T.Active,'Exactly one retained transaction release');
    if not ExpectedFailure then Check(T.Calls=Length(Pairs),'Every expected exchange consumed');
    if Fail>0 then Check(T.Calls=Fail,'No failure replay');
    if Corrupt>0 then
      if (Kind in [1,2,3]) and (Corrupt=6) then Check((T.Calls>=6) and (T.Calls<=8),'Changed reauthentication challenge fails before key proof')
      else Check(T.Calls=Corrupt,'Protected response mutation stops immediately');
    if ExpectedFailure and (Kind in [1,2,3]) and (Fail in [5,6,7,8]) then Check(Uncertain,'Key dispatch/reauth/version failure uncertain');
    S:=nil;
  finally S:=nil;R.Free;Transport:=nil;end;
end;
procedure Success(const Pairs:TDesfireWirePairs;const Ev2:Boolean;const Kind:Integer);
begin Run(Pairs,Ev2,Kind,0,0,0,0,nil,0,False,False);end;
procedure Faults(const Pairs:TDesfireWirePairs;const Ev2:Boolean;const Kind:Integer);
var I,J,Bit:Integer;B:TBytes;
begin
  for I:=1 to Length(Pairs) do Run(Pairs,Ev2,Kind,I,0,0,0,nil,0,True,True);
  for I:=4 to Length(Pairs) do
  begin
    B:=HexToBytes(Pairs[I-1].Response);
    for J:=0 to High(B) do
      for Bit:=0 to 7 do Run(Pairs,Ev2,Kind,0,I,J,Bit,nil,0,True,False);
  end;
  Run(Pairs,Ev2,Kind,0,0,0,0,nil,0,True,True);
  if Kind in [1,2,3] then Run(Pairs,Ev2,Kind,0,0,0,0,nil,0,True,False,2);
end;
procedure Guards(const Ev2:Boolean;const Pairs:TDesfireWirePairs);
var T:TTranscript;Transport:ICardTransport;R:TDesfireCardReader;S:IDesfireSession;M:IDesfireManagement;
  I,Before:Integer;Rejected:Boolean;B:TBytes;
begin
  T:=TTranscript.Create(Pairs);Transport:=T;R:=TDesfireCardReader.Create(nil);
  try
    Configure(R,T,Ev2);S:=R.OpenSession($CDEF01,dsaReadOnly);
    Check(Supports(S,IDesfireManagement,M),'Derived management API available without changing parent IID');
    for I:=0 to 2 do
    begin
      Before:=T.Calls;Rejected:=False;
      try
        case I of
          0:M.ChangeKeySettings($EF);
          1:M.ChangeFileAccess(0,dfcMac,$E,1,1,0);
          2:M.ChangeAesKey(0,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),nil);
        end;
      except on E:EDesfireError do Rejected:=True;end;
      Check(Rejected and (T.Calls=Before) and (M.Outcome=dsoActive),'Read-only management refuses before I/O');
    end;
    M.Close;M:=nil;S:=nil;
  finally M:=nil;S:=nil;R.Free;Transport:=nil;end;
  T:=TTranscript.Create(Pairs);Transport:=T;R:=TDesfireCardReader.Create(nil);
  try
    Configure(R,T,Ev2);M:=R.OpenManagementSession($CDEF01);Before:=T.Calls;
    for I:=0 to 4 do
    begin
      Rejected:=False;
      try
        case I of
          0:M.ChangeAesKey(0,$42,HexToBytes('00'),nil);
          1:M.ChangeAesKey(0,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('000102030405060708090A0B0C0D0E0F'));
          2:M.ChangeAesKey(1,$42,HexToBytes('000102030405060708090A0B0C0D0E0F'),nil);
          3:M.ChangeFileAccess(32,dfcFull,0,0,0,0);
          4:B:=nil; // Root-only free memory must not query an application.
        end;
        if I=4 then M.ReadFreeMemory;
      except on E:EDesfireError do Rejected:=True;end;
      Check(Rejected and (T.Calls=Before) and (M.Outcome=dsoActive),'Invalid local key/right/root arguments preserve session');
    end;
    M.Close;M:=nil;
  finally M:=nil;R.Free;Transport:=nil;end;
end;
procedure BadKeyReference(const Ev2:Boolean;const Pairs:TDesfireWirePairs);
var T:TTranscript;Transport:ICardTransport;R:TDesfireCardReader;M:IDesfireManagement;Rejected:Boolean;
begin
  T:=TTranscript.Create(Copy(Pairs,0,4));Transport:=T;R:=TDesfireCardReader.Create(nil);
  try
    Configure(R,T,Ev2);M:=R.OpenManagementSession($CDEF01);Rejected:=False;
    try M.ChangeFileAccess(0,dfcFull,2,0,0,0);except on E:EDesfireError do Rejected:=True;end;
    Check(Rejected and (T.Calls=4) and (T.Writes=0),'Acquired key count refuses nonexistent target before mutation');
    Check((M.Outcome=dsoClosed) and (T.Ends=1),'Acquired policy refusal closes without write uncertainty');
  finally M:=nil;R.Free;Transport:=nil;end;
end;
begin
  try
{$IFDEF MSWINDOWS}
    Base:=TCardWindowsAesProvider.Create;
{$ELSE}
    Base:=TCardOpenSslAesProvider.Create;
{$ENDIF}
    Success(Ev1Admin,False,0);Success(Ev2Admin,True,0);
    Success(Ev1FreeAccess,False,0);Success(Ev2FreeAccess,True,0);
    Success(Ev1RotateCurrent,False,1);Success(Ev2RotateCurrent,True,1);
    Success(Ev1RotateProtectedCurrent,False,1);Success(Ev2RotateProtectedCurrent,True,1);
    Success(Ev1RotateOther,False,2);Success(Ev2RotateOther,True,2);
    Success(Ev1RotateRoot,False,3);Success(Ev2RotateRoot,True,3);
    Success(Ev1FreeMemory,False,4);Success(Ev2FreeMemory,True,4);
    Faults(Ev1Admin,False,0);Faults(Ev2Admin,True,0);
    Faults(Ev1FreeAccess,False,0);Faults(Ev2FreeAccess,True,0);
    Faults(Ev1RotateCurrent,False,1);Faults(Ev2RotateCurrent,True,1);
    Faults(Ev1RotateOther,False,2);Faults(Ev2RotateOther,True,2);
    Run(Ev1SettingsMismatch,False,5,0,0,0,0,nil,0,True,False);
    Run(Ev2SettingsMismatch,True,5,0,0,0,0,nil,0,True,False);
    Run(Ev1GeometryMismatch,False,6,0,0,0,0,nil,0,True,False);
    Run(Ev2GeometryMismatch,True,6,0,0,0,0,nil,0,True,False);
    Run(Ev1FixedSettings,False,7,0,0,0,0,nil,0,True,False);
    Run(Ev2FixedSettings,True,7,0,0,0,0,nil,0,True,False);
    Run(Ev1DeniedRotation,False,8,0,0,0,0,nil,0,True,False);
    Run(Ev2DeniedRotation,True,8,0,0,0,0,nil,0,True,False);
    Run(Ev1DeniedFileChange,False,9,0,0,0,0,nil,0,True,False);
    Run(Ev2DeniedFileChange,True,9,0,0,0,0,nil,0,True,False);
    Run(Ev1RotateOther,False,2,0,0,0,0,HexToBytes('9100'),5,True,False);
    Run(Ev2RotateOther,True,2,0,0,0,0,HexToBytes('9100'),5,True,False);
    Run(Ev1WrongVersion,False,1,0,0,0,0,nil,0,True,False);
    Run(Ev2WrongVersion,True,1,0,0,0,0,nil,0,True,False);
    Run(Ev1DeniedRotation,False,1,0,0,0,0,nil,0,True,False);
    Run(Ev2DeniedRotation,True,1,0,0,0,0,nil,0,True,False);
    BadKeyReference(False,Ev1Admin);BadKeyReference(True,Ev2Admin);
    Guards(False,Ev1Admin);Guards(True,Ev2Admin);Base:=nil;
    Writeln('PASS: DESFire AES key/settings/access administration, fresh-key proof, retained ownership, every I/O/protected-response bit and denied policies.');
    Writeln('Assertions: ',Checks);
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
