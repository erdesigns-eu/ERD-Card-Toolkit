program DesfirePlusTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Transport,
{$IFDEF MSWINDOWS}ERD.Card.Crypto.Windows,{$ELSE}ERD.Card.Crypto.OpenSSL,{$ENDIF}
  ERD.Card.Contactless, ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.DESFire.Extensions, ERD.Card.Contactless.Plus,
  ERD.Card.Contactless.Plus.ACR122, ERD.Card.Contactless.Plus.Workflow,
  ERD.Card.Workflow, ERD.Card.Contactless.Workflow.Password, DesfirePlus.Vectors;
type
  TFixed = class(TInterfacedObject,ICardAesProvider)
    function EncryptCbc(const K,V,D: TBytes): TBytes;
    function DecryptCbc(const K,V,D: TBytes): TBytes;
    function RandomBytes(const N: Integer): TBytes;
  end;
  TWire = class(TInterfacedObject,ICardTransport,ICardTransaction,IMifarePlusSession)
    Pairs: TExtendedPairs; Borrowed: TBytes; MutateCall: Integer;
    Calls,Begins,Ends,Writes,FailCall,CorruptCall,CorruptByte,CorruptBit: Integer;
    Active,EndFails,WrongUid: Boolean;
    BeginFailure, EndFailure, ChangedUidBegin: Integer;
    function Exchange(const B: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
    function BeginSession: TBytes;
    function ExchangeNative(const B: TBytes): TBytes;
    procedure EndSession;
  end;
  TKeys = class(TInterfacedObject,IPlusWorkflowKeys)
    Last: TBytes;
    function GetKey(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word): TBytes;
  end;
var Checks: Integer; Base: ICardAesProvider;
procedure Check(const V: Boolean; const Text: string);
begin Inc(Checks); if not V then raise Exception.Create(Text); end;
function TFixed.EncryptCbc(const K,V,D: TBytes): TBytes;
begin Result:=Base.EncryptCbc(K,V,D); end;
function TFixed.DecryptCbc(const K,V,D: TBytes): TBytes;
begin Result:=Base.DecryptCbc(K,V,D); end;
function TFixed.RandomBytes(const N: Integer): TBytes;
begin Check(N=16,'Bounded fresh nonce request'); Result:=HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE'); end;
procedure TWire.BeginTransaction;
begin
  Check(not Active,'Exclusive acquisition');
  if Begins + 1 = BeginFailure then
    raise ECardTransportError.Create('Synthetic acquisition lost');
  Active:=True; Inc(Begins);
end;
procedure TWire.EndTransaction;
begin Check(Active,'Owned release'); Active:=False; Inc(Ends); if EndFails or (Ends=EndFailure) then raise ECardTransportError.Create('Synthetic release lost'); end;
function TWire.BeginSession: TBytes;
begin BeginTransaction; Result:=HexToBytes('04112233445566'); if WrongUid or (Begins=ChangedUidBegin) then Result[0]:=$05; end;
procedure TWire.EndSession;
begin EndTransaction; end;
function TWire.ExchangeNative(const B: TBytes): TBytes;
begin Result:=Exchange(B); end;
function TWire.Exchange(const B: TBytes): TBytes;
begin
  Check(Active,'Exclusive exchange'); Inc(Calls); Check(Calls<=Length(Pairs),'No fallback or replay');
  Check(BytesEqual(B,HexToBytes(Pairs[Calls-1].Command)),'Independent native command '+IntToStr(Calls));
  if (B[0] in [$A1,$A3]) or ((B[0]=$90) and (B[1] in [$CA,$56,$C6,$57,$55,$5C,$5F])) then Inc(Writes);
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic response lost');
  if (Calls=MutateCall) and (Length(Borrowed)>0) then Borrowed[0]:=Borrowed[0] xor $FF;
  Result:=HexToBytes(Pairs[Calls-1].Response);
  if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
function TKeys.GetKey(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word): TBytes;
begin Check(ABlock=2,'Explicit Plus key block'); AKeyNumber:=$4000; Result:=HexToBytes('00000000000000000000000000000000'); Last:=Result; end;
function DfPairs(const Kind: Integer): TExtendedPairs;
begin
  case Kind of
    0:Result:=DfInitialize; 1:Result:=DfChangeInactive; 2:Result:=DfFinalize;
    3:Result:=DfRoll; 4:Result:=DfConfigAts; 5:Result:=DfConfigValue;
    6:Result:=DfSdmChange; 7:Result:=DfSdmRead; 8:Result:=DfSetVersions;
  else Result:=DfCreate; end;
end;
procedure DfOperation(const S: IDesfireExtendedManagement; const Kind: Integer);
var Settings: TDesfireSdmSettings;
begin
  case Kind of
    0:S.InitializeAesKeySet(1);
    1:S.ChangeInactiveAesKey(1,1,$34,HexToBytes('112233445566778899AABBCCDDEEFF00'),HexToBytes('00000000000000000000000000000000'));
    2:S.FinalizeKeySet(1,$21);
    3:S.RollKeySetVerified(1,0,$34,HexToBytes('112233445566778899AABBCCDDEEFF00'));
    4:S.SetConfigurationAcknowledged(2,HexToBytes('067777710280'));
    5:S.SetConfigurationAcknowledged(9,HexToBytes('0300000000E80300000000000001'));
    6:begin
      Settings:=TDesfireExtensionCodec.DecodeSdmSettings(HexToBytes('004000E0000100C1F121200000430000430000'));
      S.ChangeSdmSettingsVerified(0,HexToBytes('000000E0000100'),Settings);
    end;
    7:begin Settings:=S.ReadSdmSettings(0); Check(Settings.PiccOffset=32,'Parsed SDM metadata offset'); end;
    8:Check(BytesToHex(S.ReadKeySetVersionList)='0121','Exact key-set version list');
    9:S.CreateApplicationWithKeySets($123456,$0F,3,2,1,0);
  end;
end;
procedure RunDf(const Kind, Fail, Corrupt, ByteIndex, BitIndex: Integer);
var Wire: TWire; T: ICardTransport; R: TDesfireCardReader; S: IDesfireExtendedManagement;
  Failed,Uncertain: Boolean; Aid: Cardinal;
begin
  Wire:=TWire.Create; T:=Wire; Wire.Pairs:=DfPairs(Kind); Wire.FailCall:=Fail;
  Wire.CorruptCall:=Corrupt; Wire.CorruptByte:=ByteIndex; Wire.CorruptBit:=BitIndex;
  R:=TDesfireCardReader.Create(nil); Failed:=False; Uncertain:=False;
  try
    R.Transport:=T; R.CryptoProvider:=TFixed.Create; R.Security:=dfsEv2Aes;
    R.AuthenticationKey:=HexToBytes('00000000000000000000000000000000');
    Aid:=1; if Kind in [4,9] then Aid:=0;
    try S:=R.OpenExtendedManagementSession(Aid); DfOperation(S,Kind); S.Close;
    except on E: EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; end;
      on E: Exception do Failed:=True; end;
    if (Fail=0) and (Corrupt=0) then begin
      Check(not Failed,'Extended DESFire success '+IntToStr(Kind));
      Check(Wire.Calls=Length(Wire.Pairs),'Complete independent DESFire transcript');
    end else begin
      Check(Failed,'Injected DESFire fault observed');
      Check(Uncertain=(Wire.Writes>0),'DESFire mutation uncertainty evidence');
    end;
  finally S:=nil; R.Free; Check(not Wire.Active and (Wire.Begins=Wire.Ends),'DESFire release every exit'); T:=nil; end;
end;
procedure TestDf;
var Kind,I,J,Bits,WriteCall: Integer; P: TExtendedPairs;
begin
  for Kind:=0 to 9 do begin
    P:=DfPairs(Kind); RunDf(Kind,0,0,0,0);
    for I:=1 to Length(P) do RunDf(Kind,I,0,0,0);
    // Exercise every integrity bit of the final protected response, including verification after writes.
    I:=Length(P); if Kind=9 then I:=Length(P)-4;
    if Kind=9 then Continue; // Its final step is fresh authentication rather than a protected data response.
    Bits:=(Length(HexToBytes(P[I-1].Response))-2)*8;
    for J:=0 to Bits-1 do RunDf(Kind,0,I,J div 8,J mod 8);
    WriteCall:=0; for I:=0 to High(P) do if HexToBytes(P[I].Command)[1] in [$56,$57,$55,$C6,$5C,$5F,$CA] then WriteCall:=I+1;
    Check((WriteCall>0)=(not (Kind in [7,8])),'Mutation classification');
  end;
end;
function PlusPairs(const Mode: TMifarePlusMode; const Writing: Boolean): TExtendedPairs;
begin
  if Mode=mpcFull then begin if Writing then Result:=PlusFullWrite else Result:=PlusFullRead; end
  else begin if Writing then Result:=PlusMacWrite else Result:=PlusMacRead; end;
end;
procedure RunPlus(const Mode: TMifarePlusMode; const Writing: Boolean;
  const Fail,Corrupt,ByteIndex,BitIndex: Integer; const EndFails,WrongUid,WrongPreimage: Boolean);
var Wire: TWire; Native: IMifarePlusSession; R: TMifarePlusCardReaderWriter;
  Failed,Uncertain: Boolean; B: TBytes;
begin
  Wire:=TWire.Create; Native:=Wire; Wire.Pairs:=PlusPairs(Mode,Writing); Wire.FailCall:=Fail;
  Wire.CorruptCall:=Corrupt; Wire.CorruptByte:=ByteIndex; Wire.CorruptBit:=BitIndex;
  Wire.EndFails:=EndFails; Wire.WrongUid:=WrongUid;
  R:=TMifarePlusCardReaderWriter.Create(nil); Failed:=False; Uncertain:=False;
  try
    R.Session:=Native; R.CryptoProvider:=TFixed.Create; R.Communication:=Mode;
    R.Key:=HexToBytes('00000000000000000000000000000000'); R.KeyNumber:=$4000;
    R.ExpectedUid:=HexToBytes('04112233445566');
    try
      if Writing then begin
        B:=HexToBytes('000102030405060708090A0B0C0D0E0F'); if WrongPreimage then B[0]:=$FF;
        R.WriteBlockVerified(2,B,HexToBytes('101112131415161718191A1B1C1D1E1F'));
      end else Check(BytesToHex(R.ReadBlocks(2,1))='000102030405060708090A0B0C0D0E0F','Plus exact verified read');
    except on E: EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; end;
      on E: Exception do Failed:=True; end;
    if (Fail=0) and (Corrupt=0) and not EndFails and not WrongUid and not WrongPreimage then begin
      Check(not Failed,'Plus verified success'); Check(Wire.Calls=Length(Wire.Pairs),'Complete Plus transcript');
    end else begin Check(Failed,'Injected Plus fault observed'); Check(Uncertain=(Wire.Writes>0),'Plus dispatch uncertainty'); end;
    if WrongUid then Check(Wire.Calls=0,'Plus identity before authentication');
    if WrongPreimage then Check(Wire.Writes=0,'Plus preimage before mutation');
    Check(not R.Busy,'Plus busy cleared every exit');
  finally R.Free; Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Plus release every exit'); Native:=nil; end;
end;
procedure TestPlus;
var Mode: TMifarePlusMode; Writing: Boolean; P: TExtendedPairs; I,J: Integer;
begin
  for Mode:=Low(TMifarePlusMode) to High(TMifarePlusMode) do for Writing:=False to True do begin
    P:=PlusPairs(Mode,Writing); RunPlus(Mode,Writing,0,0,0,0,False,False,False);
    for I:=1 to Length(P) do RunPlus(Mode,Writing,I,0,0,0,False,False,False);
    for I:=3 to Length(P) do for J:=0 to Length(HexToBytes(P[I-1].Response))*8-1 do
      RunPlus(Mode,Writing,0,I,J div 8,J mod 8,False,False,False);
    RunPlus(Mode,Writing,0,0,0,0,True,False,False);
    RunPlus(Mode,Writing,0,0,0,0,False,True,False);
    if Writing then RunPlus(Mode,Writing,0,0,0,0,False,False,True);
  end;
end;
procedure Append(var P: TExtendedPairs; const A: TExtendedPairs);
var I,N: Integer;
begin N:=Length(P); SetLength(P,N+Length(A)); for I:=0 to High(A) do P[N+I]:=A[I]; end;
procedure TestPlusWorkflow;
var Wire: TWire; Session: IMifarePlusSession; Keys: IPlusWorkflowKeys;
  Provider: TKeys; M: ICardWorkflowMemory; W: TProtectedMemoryWorkflow;
  Snapshot: TCardWorkflowSnapshot; I,Mode: Integer; Failed: Boolean;
begin
  for Mode:=0 to 2 do begin
    Wire:=TWire.Create; Session:=Wire; Provider:=TKeys.Create; Keys:=Provider;
    Wire.Pairs:=PlusFullRead; Append(Wire.Pairs,PlusFullRead);
    if Mode=0 then begin Append(Wire.Pairs,PlusFullWrite); Append(Wire.Pairs,PlusFullReadNew); end;
    M:=CreatePlusWorkflowMemory(Session,TFixed.Create,mpm2K,Keys,HexToBytes('04112233445566'));
    W:=TProtectedMemoryWorkflow.Create(nil);
    try
      Snapshot:=Default(TCardWorkflowSnapshot); Snapshot.Layout:='PLUS-SL3-0';
      Snapshot.Uid:=HexToBytes('04112233445566'); SetLength(Snapshot.Units,1);
      Snapshot.Units[0].Address:=2; Snapshot.Units[0].Data:=HexToBytes('101112131415161718191A1B1C1D1E1F');
      W.PrepareProtectedRestore(Snapshot,M,Mode=1); Check(Wire.Calls=0,'Plus workflow preparation no I/O');
      if Mode=2 then Wire.WrongUid:=True;
      if Mode=2 then Check(W.Execute=cwsFailed,'Plus workflow wrong target failed')
      else Check(W.Execute=cwsCompleted,'Plus workflow restore/compare succeeds');
      if Mode<>0 then Check(Wire.Writes=0,'Plus comparison/identity does not write');
      if Mode=0 then Check(Wire.Calls=Length(Wire.Pairs),'Complete native Plus workflow chain');
      for I:=0 to High(Provider.Last) do Check(Provider.Last[I]=0,'Temporary Plus keys cleared');
      Failed:=False; try M.ReadUid; except on E:ECardWorkflowError do Failed:=True; end;
      Check(Failed,'Plus backend consumed after workflow');
      Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Plus workflow reader released');
    finally W.Free; M:=nil; Keys:=nil; Session:=nil; end;
  end;
end;
function DirectCommand(const B: TBytes): string;
var H: TBytes;
begin
  H:=HexToBytes('FF00000000'); H[4]:=Byte(Length(B)); SetLength(H,5+Length(B));
  Move(B[0],H[5],Length(B)); Result:=BytesToHex(H);
end;
function AcrPairs: TExtendedPairs;
var Native: TExtendedPairs; I,N: Integer;
  procedure Add(const Command,Response: string);
  begin N:=Length(Result); SetLength(Result,N+1); Result[N].Command:=DirectCommand(HexToBytes(Command)); Result[N].Response:=Response; end;
begin
  Result:=nil;
  Add('D43202000B0D','D5339000'); Add('D4320400','D5339000'); Add('D43205000000','D5339000');
  Add('D41234','D5139000'); Add('D4320100','D5339000'); Add('D4320101','D5339000');
  Add('D44A0100','D54B0101000420070411223344556602059000');
  Native:=PlusFullWrite;
  for I:=0 to High(Native) do Add('D44001'+Native[I].Command,'D54100'+Native[I].Response+'9000');
  Add('D4320100','D5339000');
end;
procedure RunAcr(const Fail: Integer; const BadTarget: Boolean);
var Wire: TWire; T: ICardTransport; Session: IMifarePlusSession; R: TMifarePlusCardReaderWriter;
  Failed,Uncertain: Boolean; B: TBytes; P: TExtendedPairs;
begin
  Wire:=TWire.Create; T:=Wire; Wire.Pairs:=AcrPairs; Wire.FailCall:=Fail;
  if (Fail>0) and (Fail<=7) then begin
    P:=Wire.Pairs; Wire.Pairs:=Copy(P,0,Fail); SetLength(Wire.Pairs,Fail+1);
    Wire.Pairs[Fail]:=P[High(P)];
  end;
  if BadTarget then begin B:=HexToBytes(Wire.Pairs[6].Response); B[6]:=0; Wire.Pairs[6].Response:=BytesToHex(B); end;
  R:=TMifarePlusCardReaderWriter.Create(nil); Failed:=False; Uncertain:=False;
  try
    Session:=CreateAcr122PlusSession(T); R.Session:=Session; R.CryptoProvider:=TFixed.Create;
    R.KeyNumber:=$4000; R.Key:=HexToBytes('00000000000000000000000000000000');
    Check(Wire.Calls=0,'ACR backend inactive constructor');
    try R.WriteBlockVerified(2,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
    except on E:EContactlessWriteUncertain do begin Failed:=True; Uncertain:=True; end;
      on E:Exception do Failed:=True; end;
    if (Fail=0) and not BadTarget then Check(not Failed and (Wire.Calls=Length(Wire.Pairs)),'Complete ACR native Plus write chain')
    else begin
      Check(Failed,'ACR failure visible');
      Check(Uncertain=(Fail>=11),'ACR dispatched write or RF-off failure uncertain');
    end;
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'ACR releases transaction every exit');
  finally R.Free; Session:=nil; T:=nil; end;
end;
procedure TestAcr;
var I: Integer;
begin
  RunAcr(0,False); RunAcr(0,True);
  // RF initialization faults still attempt exactly one explicit RF-off/transaction release.
  for I:=1 to 13 do RunAcr(I,False);
end;
procedure TestPlus4K;
var Wire: TWire; Session: IMifarePlusSession; R: TMifarePlusCardReaderWriter;
  Writing: Boolean; B: TBytes; I: Integer;
begin
  for Writing:=False to True do begin
    Wire:=TWire.Create; Session:=Wire;
    if Writing then Wire.Pairs:=Plus4KWrite else Wire.Pairs:=Plus4KRead;
    R:=TMifarePlusCardReaderWriter.Create(nil);
    try
      R.Session:=Session; R.CryptoProvider:=TFixed.Create; R.Model:=mpm4K; R.KeyNumber:=$4040;
      R.Key:=HexToBytes('00000000000000000000000000000000');
      if Writing then R.WriteBlockVerified(128,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'))
      else begin B:=R.ReadBlocks(128,15); Check(Length(B)=240,'Full Plus 4K sector read');
        for I:=0 to High(B) do Check(B[I]=I,'Independent complete bulk data'); end;
      Check(Wire.Calls=Length(Wire.Pairs),'Literal Plus high-sector protocol');
      Check(not Wire.Active,'Plus high-sector release');
    finally R.Free; Session:=nil; end;
  end;
end;
procedure TestFrozenInputs;
var Wire: TWire; T: ICardTransport; R: TDesfireCardReader; S: IDesfireExtendedManagement;
  B: TBytes; Desired: TDesfireSdmSettings; Kind: Integer;
begin
  for Kind:=0 to 1 do begin
    Wire:=TWire.Create; T:=Wire;
    if Kind=0 then begin Wire.Pairs:=DfChangeInactive; B:=HexToBytes('112233445566778899AABBCCDDEEFF00'); end
    else begin Wire.Pairs:=DfSdmChange; B:=HexToBytes('000000E0000100'); end;
    Wire.Borrowed:=B; Wire.MutateCall:=4;
    R:=TDesfireCardReader.Create(nil);
    try
      R.Transport:=T; R.CryptoProvider:=TFixed.Create; R.Security:=dfsEv2Aes;
      R.AuthenticationKey:=HexToBytes('00000000000000000000000000000000'); S:=R.OpenExtendedManagementSession(1);
      if Kind=0 then S.ChangeInactiveAesKey(1,1,$34,B,HexToBytes('00000000000000000000000000000000'))
      else begin Desired:=TDesfireExtensionCodec.DecodeSdmSettings(HexToBytes('004000E0000100C1F121200000430000430000'));
        S.ChangeSdmSettingsVerified(0,B,Desired); end;
      S.Close; Check(Wire.Calls=Length(Wire.Pairs),'Caller key/preimage mutation cannot alter prepared native operation');
    finally S:=nil; R.Free; T:=nil; end;
  end;
end;
procedure TestCodecs;
var P: TDesfireSdmPiccData; S: TDesfireSdmSettings; B,Key,Mac: TBytes;
  Keys: TMifarePlusKeys; I,J,Block,Expected,Sector: Integer; Failed: Boolean;
begin
  Key:=HexToBytes('00000000000000000000000000000000');
  P:=TDesfireSdmCrypto.DecodePicc(Base,Key,HexToBytes('EF963FF7828658A599F3041510671E88'));
  Check((BytesToHex(P.Uid)='04DE5F1EACC040') and (P.ReadCounter=61),'Published NXP metadata vector');
  B:=TDesfireSdmCrypto.DeriveKey(Base,Key,P.Uid,P.ReadCounter,False);
  Check(BytesToHex(B)='3FB5F6E3A807A03D5E3570ACE393776F','Published NXP SDM MAC key vector'); TCardCrypto.Clear(B);
  Mac:=TDesfireSdmCrypto.Mac(Base,Key,P.Uid,P.ReadCounter,nil);
  Check(BytesToHex(Mac)='94EED9EE65337086','Published NXP SDM MAC vector');
  for I:=0 to 63 do begin B:=CopyBytes(Mac); B[I div 8]:=B[I div 8] xor (1 shl (I mod 8));
    Check(not TDesfireSdmCrypto.VerifyMac(Base,Key,P.Uid,P.ReadCounter,nil,B),'Every SDM MAC bit detected'); end;
  B:=TDesfireSdmCrypto.DecryptFile(Base,Key,HexToBytes('04958CAA5C5E80'),1,HexToBytes('94592FDE69FA06E8E3B6CA686A22842B'));
  Check(BytesToHex(B)='78787878787878787878787878787878','Published NXP encrypted file vector');
  B:=HexToBytes('004000E0000100C1F121200000430000430000'); S:=TDesfireExtensionCodec.DecodeSdmSettings(B);
  Check(BytesEqual(TDesfireExtensionCodec.EncodeSdmSettings(S),B),'SDM exact settings round-trip');
  for I:=0 to Length(B)-1 do begin Failed:=False; try S:=TDesfireExtensionCodec.DecodeSdmSettings(Copy(B,0,I));
    except on E: EDesfireExtensionError do Failed:=True; end; Check(Failed,'Every truncated SDM field refused'); end;
  // Exhaust conditional option combinations and exact lengths for binary and ASCII mapping.
  for I:=0 to 31 do for J:=0 to 2 do begin
    S:=Default(TDesfireSdmSettings); S.FileBytes:=1024; S.FileOption:=$40; S.AccessRights:=$E000;
    S.Options:=Byte((I and 15) shl 4) or Byte(I shr 4); S.SdmAccessRights:=$21F1;
    if J=1 then S.SdmAccessRights:=$E1F1; if J=2 then S.SdmAccessRights:=$FFF1;
    S.UidOffset:=0; S.CounterOffset:=32; S.PiccOffset:=64; S.MacInputOffset:=128;
    S.EncOffset:=160; S.EncLength:=64; S.MacOffset:=512; S.CounterLimit:=1000;
    try B:=TDesfireExtensionCodec.EncodeSdmSettings(S); S:=TDesfireExtensionCodec.DecodeSdmSettings(B);
      Check(BytesEqual(B,TDesfireExtensionCodec.EncodeSdmSettings(S)),'Conditional SDM round-trip');
    except on E: EDesfireExtensionError do Check((((I and 3)<>0) and ((I and 4)=0)) or (((I and 1)<>0) and (((I and 12)<>12) or (J=2))),'Only explicit incompatible SDM conditions refused'); end;
  end;
  S:=TDesfireExtensionCodec.DecodeSdmSettings(HexToBytes('004000E0000100C1F121200000430000430000'));
  S.MacOffset:=40; Failed:=False; try B:=TDesfireExtensionCodec.EncodeSdmSettings(S); except on E: EDesfireExtensionError do Failed:=True; end;
  Check(Failed,'Overlapping mirror/MAC refused');
  S.FileOption := $41; Failed := False;
  try B := TDesfireExtensionCodec.EncodeSdmSettings(S); except on E: EDesfireExtensionError do Failed := True; end;
  Check(Failed,'SDM requires explicit Plain file profile');
  Failed := False;
  try TDesfireExtensionCodec.ValidateConfiguration(2,HexToBytes('0277'));
  except on E: EDesfireExtensionError do Failed := True; end;
  Check(Failed,'Truncated ATS interface bytes refused');
  Failed := False;
  try TDesfireExtensionCodec.ValidateConfiguration(9,HexToBytes('0301000000000000000000000001'));
  except on E: EDesfireExtensionError do Failed := True; end;
  Check(Failed,'Inverted signed value limits refused');
  TDesfireExtensionCodec.ValidateConfiguration(9,HexToBytes('03FFFFFFFF010000000000000001'));
  Check(True,'Signed value configuration spans zero');
  Check(BytesToHex(TDesfireExtensionCodec.ApplicationHeader($123456,$0F,3,2,1,0))='5634120F930101021000','Literal extended application header');
  Keys:=TMifarePlusCodec.DeriveKeys(Base,Key,HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE'),HexToBytes('0102030405060708090A0B0C0D0E0F10'));
  try
    Check(BytesToHex(Keys.Encryption)='B9293B13A52920E54DF012DD1CFA6C36','Independent Plus ENC derivation');
    Check(BytesToHex(Keys.Authentication)='362C19B3B303EC7C08D27B5FC4E6F803','Independent Plus MAC derivation');
  finally TMifarePlusCodec.ClearKeys(Keys); end;
  B:=TMifarePlusCodec.DataIv(HexToBytes('11223344'),$1234,$5678,False);
  Check(BytesToHex(B)='11223344341278563412785634127856','Full sixteen-bit Plus command IV');
  B:=TMifarePlusCodec.DataIv(HexToBytes('11223344'),$1234,$5678,True);
  Check(BytesToHex(B)='34127856341278563412785611223344','Full sixteen-bit Plus response IV');
  for Block:=-1 to 257 do begin
    Expected:=Block div 4; if Block>=128 then Expected:=32+(Block-128) div 16;
    Failed:=False; try Sector:=TMifarePlusCodec.DataSector(mpm4K,Block);
    except on E: EMifarePlusError do Failed:=True; end;
    if (Block<1) or (Block>255) or ((Block<128) and (Block mod 4=3)) or ((Block>=128) and ((Block-128) mod 16=15)) then Check(Failed,'Plus reserved block refused')
    else Check(not Failed and (Sector=Expected),'Plus exact 4K sector mapping');
  end;
end;
function PersonalizationEntries: TMifarePlusPersonalizationEntries;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, 5);
  Result[0].Address := $9000;
  Result[1].Address := $9001;
  Result[2].Address := $9003;
  for I := 0 to 2 do
    Result[I].Data := HexToBytes('00000000000000000000000000000000');
  Result[3].Address := $4000;
  Result[3].Data := HexToBytes('112233445566778899AABBCCDDEEFF00');
  Result[4].Address := 2;
  Result[4].Data := HexToBytes('101112131415161718191A1B1C1D1E1F');
end;

procedure RunPlusManagement(const Personalize: Boolean; const Target: Word;
  const Fail, Corrupt, ByteIndex, BitIndex, BeginFail, EndFail, UidChange: Integer;
  const Freeze: Boolean);
var
  Wire: TWire;
  Session: IMifarePlusSession;
  Reader: TMifarePlusCardReaderWriter;
  Entries: TMifarePlusPersonalizationEntries;
  Evidence: TMifarePlusPersonalizationResult;
  NewKey, OriginalKey: TBytes;
  Failed, Uncertain, ExpectedUncertain: Boolean;
  I: Integer;
begin
  Wire := TWire.Create;
  Session := Wire;
  if Personalize then
    Wire.Pairs := PlusPersonalize
  else
    case Target of
      $4000: Wire.Pairs := PlusRotate4000;
      $4001: Wire.Pairs := PlusRotate4001;
      $4040: Wire.Pairs := PlusRotate4040;
    end;
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.BeginFailure := BeginFail;
  Wire.EndFailure := EndFail;
  Wire.ChangedUidBegin := UidChange;
  Reader := TMifarePlusCardReaderWriter.Create(nil);
  Entries := PersonalizationEntries;
  NewKey := HexToBytes('112233445566778899AABBCCDDEEFF00');
  OriginalKey := HexToBytes('00000000000000000000000000000000');
  Failed := False;
  Uncertain := False;
  try
    Reader.Session := Session;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Key := OriginalKey;
    Reader.ExpectedUid := HexToBytes('04112233445566');
    Reader.KeyNumber := $4000;
    if Target = $4040 then
    begin
      Reader.Model := mpm4K;
      Reader.KeyNumber := Target;
    end;
    Reader.Communication := mpcMac; // Credential writes must still be encrypted.
    if Freeze then
    begin
      Wire.MutateCall := 1;
      if Personalize then
        Wire.Borrowed := Entries[3].Data
      else
        Wire.Borrowed := NewKey;
    end;
    try
      if Personalize then
      begin
        Evidence := Reader.PersonalizeAndCommitSl3Verified(Entries, True);
        Check(Evidence.AcknowledgedEntries=5, 'Exact acknowledged SL0 entry count');
        Check(Evidence.VerifiedKeys=3, 'Fresh sector/master/configuration key proofs');
        Check(Evidence.VerifiedBlocks=1, 'Fresh SL3 data proof');
        Check(Evidence.Sl3Verified, 'SL3 only proven after complete release');
      end
      else
        Reader.RotateSectorKeyVerified(Target, NewKey, True);
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
      end;
    end;
    Check(not Reader.Busy and not Wire.Active, 'Management releases exclusive ownership');
    Check(Wire.Begins=Wire.Ends, 'Every acquired management session released');
    Check(Reader.Communication=mpcMac, 'Caller mode restored after encrypted management');
    Check(BytesEqual(Reader.Key,OriginalKey), 'Caller configured credentials restored');
    Check(BytesToHex(Reader.ExpectedUid)='04112233445566', 'Caller identity retained');
    if (Fail=0) and (Corrupt=0) and (BeginFail=0) and (EndFail=0) and (UidChange=0) then
    begin
      Check(not Failed, 'Independent management transcript succeeds');
      Check(Wire.Calls=Length(Wire.Pairs), 'Complete write and fresh proof transcript');
    end
    else
    begin
      Check(Failed, 'Injected management failure observable');
      if Personalize then
        ExpectedUncertain := Wire.Calls > 0
      else
        ExpectedUncertain := Wire.Calls >= 3;
      Check(Uncertain=ExpectedUncertain, 'Mutation uncertainty persists across fresh sessions');
      Check(Wire.Calls<=Length(Wire.Pairs), 'No management replay/fallback');
    end;
  finally
    Reader.Free;
    TCardCrypto.Clear(NewKey);
    TCardCrypto.Clear(OriginalKey);
    for I := 0 to High(Entries) do
      TCardCrypto.Clear(Entries[I].Data);
  end;
end;

procedure TestPlusManagement;
var
  Personalize: Boolean;
  Target: Word;
  Pairs: TExtendedPairs;
  I, J, N, K: Integer;
  Entries: TMifarePlusPersonalizationEntries;
  Wire: TWire;
  Session: IMifarePlusSession;
  Reader: TMifarePlusCardReaderWriter;
  Failed: Boolean;
  Evidence: TMifarePlusPersonalizationResult;
begin
  for Personalize := False to True do
    for K := 0 to 2 do
    begin
      Target := $4000;
      if K=1 then Target := $4001;
      if K=2 then Target := $4040;
      if Personalize then
      begin
        if K<>0 then Continue;
        Pairs := PlusPersonalize;
        N := 6;
      end
      else
      begin
        case Target of
          $4000: Pairs := PlusRotate4000;
          $4001: Pairs := PlusRotate4001;
          $4040: Pairs := PlusRotate4040;
        end;
        N := 2;
      end;
      RunPlusManagement(Personalize,Target,0,0,0,0,0,0,0,False);
      RunPlusManagement(Personalize,Target,0,0,0,0,0,0,0,True);
      for I := 1 to Length(Pairs) do
        RunPlusManagement(Personalize,Target,I,0,0,0,0,0,0,False);
      for I := 1 to N do
      begin
        RunPlusManagement(Personalize,Target,0,0,0,0,I,0,0,False);
        RunPlusManagement(Personalize,Target,0,0,0,0,0,I,0,False);
        RunPlusManagement(Personalize,Target,0,0,0,0,0,0,I,False);
      end;
      // Every bit of plaintext native acknowledgements and protected key-write MAC.
      if Personalize then
        for I := 1 to 6 do
          for J := 0 to 7 do
            RunPlusManagement(True,Target,0,I,0,J,0,0,0,False)
      else
        for J := 0 to 71 do
          RunPlusManagement(False,Target,0,3,J div 8,J mod 8,0,0,0,False);
      // Corrupt all bits of each encrypted first nonce block in fresh proofs.
      for I := 1 to Length(Pairs) do
        if (Copy(Pairs[I-1].Command,1,2)='72') and
          ((Personalize and (I>6)) or (not Personalize and (I=5))) then
          for J := 8 to 135 do
            RunPlusManagement(Personalize,Target,0,I,J div 8,J mod 8,0,0,0,False);
      if Personalize then
        for J := 0 to 199 do
          RunPlusManagement(True,Target,0,Length(Pairs),J div 8,J mod 8,0,0,0,False);
    end;
  // Every invalid plan must fail before activation, never by trying WritePerso.
  for K := 0 to 8 do
  begin
    Entries := PersonalizationEntries;
    Wire := TWire.Create;
    Session := Wire;
    Reader := TMifarePlusCardReaderWriter.Create(nil);
    try
      Reader.Session := Session;
      Reader.CryptoProvider := TFixed.Create;
      Reader.ExpectedUid := HexToBytes('04112233445566');
      case K of
        0: Entries[0].Address := $9002;
        1: Entries[4].Address := 0;
        2: Entries[4].Address := 3;
        3: Entries[4].Address := 128;
        4: Entries[4].Address := $4000;
        5: SetLength(Entries[3].Data,15);
        6: Reader.ExpectedUid := nil;
        7: Entries[3].Address := $4040;
      end;
      Failed := False;
      try
        Evidence := Reader.PersonalizeAndCommitSl3Verified(Entries,K<>8);
        Check(not Evidence.Sl3Verified,'Invalid plan cannot produce successful evidence');
      except on E: EMifarePlusError do Failed := True; end;
      Check(Failed,'Invalid SL0 plan refused');
      Check(Wire.Calls=0,'Invalid SL0 plan never probes with writes');
      Check(Wire.Begins=0,'Invalid SL0 plan fails before acquisition');
    finally
      Reader.Free;
      for I := 0 to High(Entries) do TCardCrypto.Clear(Entries[I].Data);
    end;
  end;
end;

begin
  try
{$IFDEF MSWINDOWS} Base:=TCardWindowsAesProvider.Create; {$ELSE} Base:=TCardOpenSslAesProvider.Create; {$ENDIF}
    TestCodecs; TestDf; TestPlus; TestPlusWorkflow; TestAcr; TestPlus4K; TestFrozenInputs; TestPlusManagement;
    Writeln('PASS: ',Checks,' DESFire extension/Plus assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
