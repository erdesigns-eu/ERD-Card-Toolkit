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
  ERD.Card.Contactless.Plus.Levels, ERD.Card.Contactless.Raw,
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
    Active,EndFails,WrongUid,RepairRawCrc: Boolean;
    BeginFailure, EndFailure, ChangedUidBegin: Integer;
    function Exchange(const B: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
    function BeginSession: TBytes;
    function ExchangeNative(const B: TBytes): TBytes;
    procedure EndSession;
  end;
  TLevelRaw = class(TInterfacedObject, IRawContactlessReader)
  private
    FWire: TWire;
    FHold: ICardTransport;
  public
    PartialCall, TimeoutCall: Integer;
    constructor Create(const AWire: TWire);
    procedure BeginSession;
    procedure EndSession;
    function Activate: TBytes;
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
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
  if (B[0] in [$A1,$A3,$B5,$B7,$B9]) or ((B[0]=$90) and (B[1] in [$CA,$CD,$CB,$C1,$C0,$CE,$DF,$8D,$C7,$C8,$A7,$56,$C6,$57,$55,$5C,$5F])) then Inc(Writes);
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic response lost');
  if (Calls=MutateCall) and (Length(Borrowed)>0) then Borrowed[0]:=Borrowed[0] xor $FF;
  Result:=HexToBytes(Pairs[Calls-1].Response);
  if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
constructor TLevelRaw.Create(const AWire: TWire);
begin
  inherited Create;
  FWire := AWire;
  FHold := AWire;
end;
procedure TLevelRaw.BeginSession;
begin
  FWire.BeginTransaction;
end;
procedure TLevelRaw.EndSession;
begin
  FWire.EndTransaction;
end;
function TLevelRaw.Activate: TBytes;
begin
  Check(FWire.Active, 'Raw activation requires exclusive ownership');
  Result := HexToBytes('04112233445566');
  if FWire.WrongUid or (FWire.Begins=FWire.ChangedUidBegin) then
    Result[0] := $05;
end;
function TLevelRaw.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
begin
  Check(ABitCount=Length(AFrame)*8, 'Native SL1 authentication uses full-byte CRC framing');
  Result := Default(TRawRfResponse);
  Result.Data := FWire.Exchange(AFrame);
  if FWire.RepairRawCrc and (FWire.Calls=FWire.CorruptCall) then
    Result.Data := TRawUidCodec.AppendCrcA(Copy(Result.Data,0,Length(Result.Data)-2));
  Result.BitCount := Length(Result.Data)*8;
  if FWire.Calls=PartialCall then Dec(Result.BitCount);
  if FWire.Calls=TimeoutCall then
  begin
    Result.Data := nil;
    Result.BitCount := 0;
    Result.TimedOut := True;
  end;
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

procedure RunPlusLevel(const Kind, Fail, Corrupt, ByteIndex, BitIndex,
  BeginFail, EndFail, UidChange, Partial, Timeout, Freeze: Integer;
  const RepairCrc: Boolean = False);
var
  Wire: TWire;
  Sl3: IMifarePlusSession;
  Raw: TLevelRaw;
  RawInterface: IRawContactlessReader;
  Manager: TMifarePlusLevelManager;
  Key, ProofKey, Expected: TBytes;
  Failed, Uncertain, ExpectedUncertain: Boolean;
begin
  Wire := TWire.Create;
  Sl3 := Wire;
  case Kind of
    0: Wire.Pairs := PlusLevel9004;
    1: Wire.Pairs := PlusLevel9002;
    2: Wire.Pairs := PlusLevel3Proof;
    3: Wire.Pairs := PlusLevel2To3;
  end;
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.BeginFailure := BeginFail;
  Wire.EndFailure := EndFail;
  Wire.ChangedUidBegin := UidChange;
  Wire.RepairRawCrc := RepairCrc;
  Raw := TLevelRaw.Create(Wire);
  RawInterface := Raw;
  Raw.PartialCall := Partial;
  Raw.TimeoutCall := Timeout;
  Manager := TMifarePlusLevelManager.Create(nil);
  Key := HexToBytes('00000000000000000000000000000000');
  ProofKey := CopyBytes(Key);
  Expected := HexToBytes('000102030405060708090A0B0C0D0E0F');
  Failed := False;
  Uncertain := False;
  try
    Manager.RawReader := RawInterface;
    Manager.Sl3Session := Sl3;
    Manager.CryptoProvider := TFixed.Create;
    Manager.ExpectedUid := HexToBytes('04112233445566');
    if Freeze>0 then
    begin
      Wire.MutateCall := 1;
      case Freeze of
        1: Wire.Borrowed := Key;
        2: Wire.Borrowed := ProofKey;
        3: Wire.Borrowed := Expected;
      end;
    end;
    try
      case Kind of
        0: Manager.AuthenticateSl1(Key);
        1: Manager.SwitchSl1ToSl2Acknowledged(Key, True);
        2: Manager.SwitchSl1ToSl3Verified(Key, $4000, ProofKey, 2, Expected, True);
        3: Manager.SwitchSl2ToSl3Verified(Key, $4000, ProofKey, 2, Expected, True);
      end;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
      end;
    end;
    Check(not Manager.Busy and not Wire.Active, 'Level manager always releases its operation');
    Check(Wire.Begins=Wire.Ends, 'Raw and ISO14443-4 acquisitions released independently');
    if (Fail=0) and (Corrupt=0) and (BeginFail=0) and (EndFail=0) and
      (UidChange=0) and (Partial=0) and (Timeout=0) then
    begin
      Check(not Failed, 'Independent 76/72 level transcript succeeds');
      Check(Wire.Calls=Length(Wire.Pairs), 'Transition and fresh SL3 proof complete');
      Check(Wire.Begins=1+Ord(Kind>=2), 'No hidden level/authentication retries');
    end
    else
    begin
      Check(Failed, 'Every injected level failure is visible');
      ExpectedUncertain := (Kind<>0) and (Wire.Calls>=2);
      Check(Uncertain=ExpectedUncertain, 'Level dispatch uncertainty retained across release/proof');
    end;
  finally
    Manager.Free;
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(ProofKey);
    TCardCrypto.Clear(Expected);
  end;
end;

procedure TestPlusLevels;
var
  Kind, I, J, K, N: Integer;
  Pairs: TExtendedPairs;
  Wire: TWire;
  Hold: ICardTransport;
  Manager: TMifarePlusLevelManager;
  Raw: IRawContactlessReader;
  Key: TBytes;
  Failed: Boolean;
begin
  for Kind := 0 to 3 do
  begin
    case Kind of
      0: Pairs := PlusLevel9004;
      1: Pairs := PlusLevel9002;
      2: Pairs := PlusLevel3Proof;
      3: Pairs := PlusLevel2To3;
    end;
    RunPlusLevel(Kind,0,0,0,0,0,0,0,0,0,0);
    for I := 1 to 3 do
      if (Kind>=2) or (I=1) then
        RunPlusLevel(Kind,0,0,0,0,0,0,0,0,0,I);
    for I := 1 to Length(Pairs) do
      RunPlusLevel(Kind,I,0,0,0,0,0,0,0,0,0);
    for I := 1 to 2 do
    begin
      for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-1 do
        RunPlusLevel(Kind,0,I,J div 8,J mod 8,0,0,0,0,0,0);
      for J := 0 to (Length(HexToBytes(Pairs[I-1].Response))-2)*8-1 do
        RunPlusLevel(Kind,0,I,J div 8,J mod 8,0,0,0,0,0,0,True);
      RunPlusLevel(Kind,0,0,0,0,0,0,0,I,0,0);
      RunPlusLevel(Kind,0,0,0,0,0,0,0,0,I,0);
    end;
    N := 1+Ord(Kind>=2);
    for I := 1 to N do
    begin
      RunPlusLevel(Kind,0,0,0,0,I,0,0,0,0,0);
      RunPlusLevel(Kind,0,0,0,0,0,I,0,0,0,0);
      RunPlusLevel(Kind,0,0,0,0,0,0,I,0,0,0);
    end;
    if Kind>=2 then
      for J := 0 to 199 do
        RunPlusLevel(Kind,0,Length(Pairs),J div 8,J mod 8,0,0,0,0,0,0);
  end;
  // The actual raw ACR122 factory must suppress RATS, verify CRC and restore saved registers.
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := PlusLevelAcr;
  Manager := TMifarePlusLevelManager.Create(nil);
  try
    Raw := CreateAcr122PlusLevelReader(Hold);
    Check(Wire.Calls=0, 'Level-reader factory remains inactive');
    Manager.RawReader := Raw;
    Manager.CryptoProvider := TFixed.Create;
    Manager.ExpectedUid := HexToBytes('04112233445566');
    Manager.AuthenticateSl1(HexToBytes('00000000000000000000000000000000'));
    Check(Wire.Calls=Length(Wire.Pairs), 'Complete ACR122 no-RATS 76/72 CRC transcript');
    Check(not Wire.Active and (Wire.Begins=Wire.Ends), 'ACR122 baseline restored and released');
  finally
    Manager.Free;
    Raw := nil;
  end;
  for K := 0 to 5 do
  begin
    Wire := TWire.Create;
    Hold := Wire;
    Manager := TMifarePlusLevelManager.Create(nil);
    Key := HexToBytes('00000000000000000000000000000000');
    try
      Manager.RawReader := TLevelRaw.Create(Wire);
      Manager.Sl3Session := Wire;
      Manager.CryptoProvider := TFixed.Create;
      Manager.ExpectedUid := HexToBytes('04112233445566');
      if K=0 then Manager.ExpectedUid := nil;
      if K=1 then Manager.RawReader := nil;
      if K=2 then Manager.CryptoProvider := nil;
      if K=3 then SetLength(Key,15);
      if K=5 then Manager.Sl3Session := nil;
      Failed := False;
      try
        if K<4 then Manager.AuthenticateSl1(Key)
        else Manager.SwitchSl1ToSl3Verified(Key,$4000,Key,2,
          HexToBytes('000102030405060708090A0B0C0D0E0F'),K<>4);
      except on E: EMifarePlusError do Failed := True; end;
      Check(Failed and (Wire.Calls=0) and (Wire.Begins=0), 'Invalid level profile fails before activation');
      Check(not Manager.Busy, 'Invalid level profile clears busy state');
    finally
      Manager.Free;
      TCardCrypto.Clear(Key);
    end;
  end;
end;

procedure RunPlusValue(const Writing: Boolean; const Fail, Corrupt,
  ByteIndex, BitIndex: Integer; const WrongExpected, NoOp: Boolean);
var
  Wire: TWire;
  Session: IMifarePlusSession;
  Reader: TMifarePlusCardReaderWriter;
  Value: TMifarePlusValue;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Session := Wire;
  if Writing and not NoOp and not WrongExpected then Wire.Pairs := PlusValueWrite
  else Wire.Pairs := PlusValueRead;
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Reader := TMifarePlusCardReaderWriter.Create(nil);
  Failed := False;
  Uncertain := False;
  try
    Reader.Session := Session;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Key := HexToBytes('00000000000000000000000000000000');
    Reader.KeyNumber := $4000;
    try
      if Writing then
      begin
        if WrongExpected then Reader.WriteValueBlockVerified(2,-41,100,2)
        else if NoOp then Reader.WriteValueBlockVerified(2,-42,-42,2)
        else Reader.WriteValueBlockVerified(2,-42,100,2);
      end
      else
      begin
        Value := Reader.ReadValueBlock(2);
        Check((Value.Value=-42) and (Value.Address=2), 'MAC-verified signed value decoded');
      end;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
      end;
    end;
    Check(not Reader.Busy and not Wire.Active and (Wire.Begins=Wire.Ends), 'Value session released');
    if (Fail=0) and (Corrupt=0) and not WrongExpected then
    begin
      Check(not Failed, 'Independent signed value read/write transcript');
      Check(Wire.Calls=Length(Wire.Pairs), 'Exact value write/read-back chain');
      if NoOp then Check(Wire.Writes=0, 'Equal values do not dispatch a write');
    end
    else
    begin
      Check(Failed, 'Value failure/preimage refusal observable');
      Check(Uncertain=(Writing and (Wire.Calls>=4)), 'Value mutation uncertainty begins at native write');
      if WrongExpected then Check(Wire.Writes=0,'Wrong value preimage never written');
    end;
  finally
    Reader.Free;
  end;
end;

procedure TestPlusValues;
const
  Values: array[0..4] of Integer = (-2147483647-1, -1, 0, 1, 2147483647);
var
  I, J, Address: Integer;
  Block, Changed: TBytes;
  Value: TMifarePlusValue;
  Failed, Writing: Boolean;
  Pairs: TExtendedPairs;
begin
  Check(BytesToHex(TMifarePlusValueCodec.Encode(-42,2))=
    'D6FFFFFF29000000D6FFFFFF02FD02FD','Independent negative value-block vector');
  for Address := 0 to 255 do
    for I := 0 to High(Values) do
    begin
      Block := TMifarePlusValueCodec.Encode(Values[I],Byte(Address));
      Value := TMifarePlusValueCodec.Decode(Block);
      Check((Value.Value=Values[I]) and (Value.Address=Address),'Signed endpoint and all logical addresses round-trip');
    end;
  for I := 0 to High(Values) do
  begin
    Block := TMifarePlusValueCodec.Encode(Values[I],2);
    for J := 0 to 127 do
    begin
      Changed := CopyBytes(Block);
      Changed[J div 8] := Changed[J div 8] xor (1 shl (J mod 8));
      Failed := False;
      try Value := TMifarePlusValueCodec.Decode(Changed);
      except on E: EMifarePlusError do Failed := True; end;
      Check(Failed,'Every value/address redundancy bit checked');
    end;
    for J := 0 to High(Values) do
    begin
      Failed := False;
      try Address := TMifarePlusValueCodec.AddChecked(Values[I],Values[J]);
      except on E: EMifarePlusError do Failed := True; end;
      if (Int64(Values[I])+Values[J]<Low(Integer)) or (Int64(Values[I])+Values[J]>High(Integer)) then
        Check(Failed,'Signed addition overflow refused')
      else Check(not Failed and (Int64(Address)=Int64(Values[I])+Values[J]),'Exact signed value addition');
    end;
  end;
  for Writing := False to True do
  begin
    if Writing then Pairs := PlusValueWrite else Pairs := PlusValueRead;
    RunPlusValue(Writing,0,0,0,0,False,False);
    for I := 1 to Length(Pairs) do RunPlusValue(Writing,I,0,0,0,False,False);
    for I := 3 to Length(Pairs) do
      for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-1 do
        RunPlusValue(Writing,0,I,J div 8,J mod 8,False,False);
  end;
  RunPlusValue(True,0,0,0,0,True,False);
  RunPlusValue(True,0,0,0,0,False,True);
end;

function NativeValuePairs(const Operation: TMifarePlusNativeValueOperation;
  const Separate: Boolean): TExtendedPairs;
begin
  if Separate then
    case Operation of
      mnvoIncrementThenTransfer: Result := PlusNative0Cross;
      mnvoDecrementThenTransfer: Result := PlusNative1Cross;
      mnvoIncrementTransfer: Result := PlusNative2Cross;
      mnvoDecrementTransfer: Result := PlusNative3Cross;
    else Result := PlusNative4Cross;
    end
  else
    case Operation of
      mnvoIncrementThenTransfer: Result := PlusNative0Same;
      mnvoDecrementThenTransfer: Result := PlusNative1Same;
      mnvoIncrementTransfer: Result := PlusNative2Same;
      mnvoDecrementTransfer: Result := PlusNative3Same;
    else Result := PlusNative4Same;
    end;
end;

procedure RunNativeValue(const Operation: TMifarePlusNativeValueOperation;
  const Separate: Boolean; const Fail, Corrupt, ByteIndex, BitIndex,
  WrongPreimage, Freeze: Integer; const EndFail: Boolean);
var
  Wire: TWire;
  Session: IMifarePlusSession;
  Reader: TMifarePlusCardReaderWriter;
  Source, Target: TBytes;
  Amount: Cardinal;
  SourceBlock, PersistentCall, I: Integer;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Session := Wire;
  Wire.Pairs := NativeValuePairs(Operation, Separate);
  PersistentCall := 0;
  for I := 0 to High(Wire.Pairs) do
    if Copy(Wire.Pairs[I].Command,1,2)='B5' then PersistentCall := I+1
    else if (Copy(Wire.Pairs[I].Command,1,2)='B7') or
      (Copy(Wire.Pairs[I].Command,1,2)='B9') then PersistentCall := I+1;
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.EndFails := EndFail;
  SourceBlock := 2;
  if Separate then SourceBlock := 1;
  Source := TMifarePlusValueCodec.Encode(100,Byte(SourceBlock));
  Target := TMifarePlusValueCodec.Encode(100,2);
  if Separate then Target := TMifarePlusValueCodec.Encode(7,2);
  if WrongPreimage=1 then Source := TMifarePlusValueCodec.Encode(101,Byte(SourceBlock));
  if WrongPreimage=2 then Target := TMifarePlusValueCodec.Encode(8,2);
  Amount := 42;
  if Operation=mnvoRestoreTransfer then Amount := 0;
  if Freeze>0 then
  begin
    Wire.MutateCall := 1;
    if Freeze=1 then Wire.Borrowed := Source else Wire.Borrowed := Target;
  end;
  Reader := TMifarePlusCardReaderWriter.Create(nil);
  Failed := False;
  Uncertain := False;
  try
    Reader.Session := Session;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Key := HexToBytes('00000000000000000000000000000000');
    Reader.KeyNumber := $4000;
    Reader.Communication := mpcMac;
    try
      Reader.ExecuteNativeValueVerified(Operation,SourceBlock,2,Source,Target,Amount,2);
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
      end;
    end;
    Check(not Reader.Busy and not Wire.Active and (Wire.Begins=Wire.Ends),'Native value ownership released');
    Check(Reader.Communication=mpcMac,'Native Full messaging restores caller mode');
    if (Fail=0) and (Corrupt=0) and (WrongPreimage=0) and not EndFail then
    begin
      Check(not Failed,'Independent native value workflow succeeds');
      Check(Wire.Calls=Length(Wire.Pairs),'Native command and source/target proofs complete');
      if PersistentCall=0 then Check(Wire.Writes=0,'Equal native target skips buffer and transfer mutation')
      else Check(Wire.Writes=1,'Exactly one persistent native value command');
    end
    else
    begin
      Check(Failed,'Native value failure or wrong preimage observable');
      Check(Uncertain=((PersistentCall>0) and (Wire.Calls>=PersistentCall)),
        'Uncertainty starts at persistent transfer, not volatile buffer dispatch');
      if WrongPreimage>0 then Check(Wire.Writes=0,'Wrong native value preimage never transferred');
    end;
  finally
    Reader.Free;
  end;
end;

procedure TestNativeValues;
var
  Operation: TMifarePlusNativeValueOperation;
  Separate: Boolean;
  Pairs: TExtendedPairs;
  Wire: TWire;
  Session: IMifarePlusSession;
  Reader: TMifarePlusCardReaderWriter;
  Source, Target: TBytes;
  I, J, K, SourceBlock: Integer;
  Amount: Cardinal;
  Failed: Boolean;
begin
  for Operation := Low(TMifarePlusNativeValueOperation) to High(TMifarePlusNativeValueOperation) do
    for Separate := False to True do
    begin
      Pairs := NativeValuePairs(Operation,Separate);
      RunNativeValue(Operation,Separate,0,0,0,0,0,0,False);
      RunNativeValue(Operation,Separate,0,0,0,0,0,1,False);
      RunNativeValue(Operation,Separate,0,0,0,0,0,2,False);
      RunNativeValue(Operation,Separate,0,0,0,0,0,0,True);
      RunNativeValue(Operation,Separate,0,0,0,0,1,0,False);
      if Separate then RunNativeValue(Operation,True,0,0,0,0,2,0,False);
      for I := 1 to Length(Pairs) do
        RunNativeValue(Operation,Separate,I,0,0,0,0,0,False);
      for I := 3 to Length(Pairs) do
        for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-1 do
          RunNativeValue(Operation,Separate,0,I,J div 8,J mod 8,0,0,False);
    end;
  for K := 0 to 1 do
  begin
    Wire := TWire.Create;
    Session := Wire;
    if K=0 then Wire.Pairs := PlusNative4KIncrement else Wire.Pairs := PlusNative4KDecrement;
    Reader := TMifarePlusCardReaderWriter.Create(nil);
    try
      Reader.Session := Session;
      Reader.CryptoProvider := TFixed.Create;
      Reader.Key := HexToBytes('00000000000000000000000000000000');
      Reader.Model := mpm4K;
      Reader.KeyNumber := $4040;
      Target := TMifarePlusValueCodec.Encode(7,129);
      Operation := mnvoIncrementTransfer;
      Source := TMifarePlusValueCodec.Encode(Low(Integer),128);
      if K=1 then
      begin
        Operation := mnvoDecrementTransfer;
        Source := TMifarePlusValueCodec.Encode(High(Integer),128);
      end;
      Reader.ExecuteNativeValueVerified(Operation,128,129,Source,Target,High(Cardinal),129);
      Check(Wire.Calls=Length(Wire.Pairs),'Full unsigned amount and high 4K block addresses');
      Check(not Wire.Active and not Reader.Busy,'4K native boundary operation released');
    finally
      Reader.Free;
    end;
  end;
  // Valid MACs do not excuse incorrect read-back or changed source content.
  for K := 0 to 1 do
  begin
    Wire := TWire.Create;
    Session := Wire;
    if K=0 then Wire.Pairs := PlusNativeBadTarget else Wire.Pairs := PlusNativeBadSource;
    Reader := TMifarePlusCardReaderWriter.Create(nil);
    try
      Reader.Session := Session;
      Reader.CryptoProvider := TFixed.Create;
      Reader.Key := HexToBytes('00000000000000000000000000000000');
      Reader.KeyNumber := $4000;
      Source := TMifarePlusValueCodec.Encode(100,1);
      Target := TMifarePlusValueCodec.Encode(7,2);
      Failed := False;
      try Reader.ExecuteNativeValueVerified(mnvoIncrementTransfer,1,2,Source,Target,42,2);
      except on E: EContactlessWriteUncertain do Failed := True; end;
      Check(Failed,'Authenticated wrong target/changed source remains uncertain');
      Check(Wire.Calls=6+K,'Semantic failure stops at the exact proof boundary');
      Check(not Wire.Active and not Reader.Busy,'Authenticated semantic failure releases ownership');
    finally
      Reader.Free;
    end;
  end;
  for K := 0 to 7 do
  begin
    Wire := TWire.Create;
    Session := Wire;
    Reader := TMifarePlusCardReaderWriter.Create(nil);
    try
      Reader.Session := Session;
      Reader.CryptoProvider := TFixed.Create;
      Reader.Key := HexToBytes('00000000000000000000000000000000');
      Reader.KeyNumber := $4000;
      Source := TMifarePlusValueCodec.Encode(100,1);
      Target := TMifarePlusValueCodec.Encode(7,2);
      SourceBlock := 1;
      Operation := mnvoIncrementTransfer;
      Amount := 42;
      case K of
        0: Source := TMifarePlusValueCodec.Encode(High(Integer),1);
        1: begin Source := TMifarePlusValueCodec.Encode(Low(Integer),1); Operation := mnvoDecrementTransfer; end;
        2: Source[0] := Source[0] xor 1;
        3: Target[12] := 3;
        4: Operation := mnvoRestoreTransfer;
        5: SourceBlock := 0;
        6: SourceBlock := 4;
        7: SourceBlock := 2;
      end;
      Failed := False;
      try Reader.ExecuteNativeValueVerified(Operation,SourceBlock,2,Source,Target,Amount,2);
      except on E: EMifarePlusError do Failed := True; end;
      Check(Failed and (Wire.Calls=0) and (Wire.Begins=0),'Invalid native value profile/overflow refused before I/O');
      Check(not Reader.Busy,'Invalid native value profile retains inactive state');
    finally
      Reader.Free;
    end;
  end;
end;

function FilePairs(const Kind: Integer): TExtendedPairs;
begin
  case Kind of
    0: Result := DfIsoDirectory;
    1: Result := DfIsoCreateApplication;
    2: Result := DfIsoFileIds;
    3: Result := DfIsoCreateFile0;
    4: Result := DfIsoCreateFile1;
    5: Result := DfIsoCreateFile3;
    6: Result := DfIsoCreateFile4;
    7: Result := DfMultiSettings;
    8: Result := DfMultiChange;
    9: Result := DfMultiRead;
    10: Result := DfMultiWrite;
    11: Result := DfTmacCreate;
    12: Result := DfTmacSettings;
    14: Result := DfTmacRecordMac;
    15: Result := DfTmacRecordFull;
    16: Result := DfTmacLimitChange;
    17: Result := DfTmacDelete;
    18: Result := DfMultiNonMasterRead;
  else Result := DfTmacRecord;
  end;
end;

procedure FileOperation(const S: IDesfireFileManagement; const Kind: Integer;
  const Frozen: TBytes);
var
  Directory: TDesfireIsoApplications;
  Fids: TDesfireIsoFileIds;
  D: TDesfireFileDefinition;
  Settings: TDesfireMultiAccessSettings;
  Rights: TDesfireAccessRightSets;
  Tmac: TDesfireTmacSettings;
  RecordData: TDesfireTmacRecord;
begin
  case Kind of
    0: begin
      Directory := S.ReadIsoApplications;
      Check(Length(Directory)=3,'Frame-preserved ISO directory entries');
      Check((Directory[1].Aid=$123456) and (Directory[1].IsoFid=$E105), 'Native ISO FID uses little-endian');
      Check(Length(Directory[2].DfName)=16,'Maximum ISO DF name retained without concatenating adjacent entries');
    end;
    1: S.CreateIsoApplicationVerified($123456,$0F,3,$E105,Frozen);
    2: begin
      Fids := S.ReadIsoFileIds;
      Check((Length(Fids)=2) and (Fids[0]=$E103) and (Fids[1]=$E104), 'Exact native ISO FID list');
    end;
    3,4,5,6: begin
      D := Default(TDesfireFileDefinition);
      D.Communication := dfcFull;
      case Kind of
        3: D.FileType := dftStandard;
        4: D.FileType := dftBackup;
        5: D.FileType := dftLinearRecords;
        6: D.FileType := dftCyclicRecords;
      end;
      if Kind<5 then D.FileBytes := 4
      else begin D.RecordBytes := 4; D.MaxRecords := 2; end;
      S.CreateIsoFileVerified(D,$E104);
    end;
    7: begin
      Settings := S.ReadMultiAccessSettings(0);
      Check((Length(Settings.Rights)=2) and (Settings.Rights[1]=$000F), 'Additional acquired access tuple');
      Check(BytesToHex(Settings.BaseBytes)='0003F0FF040000','Ordinary geometry is independent of multi-access suffix');
    end;
    8: begin
      SetLength(Rights,2); Rights[0] := $FFF0; Rights[1] := $000F;
      S.ChangeMultiAccessVerified(0,Frozen,3,Rights);
    end;
    9,18: Check(BytesToHex(S.ReadMultiAccessData(0,0,4))='01020304','Additional-key authority enables protected data read');
    10: S.WriteMultiAccessDataVerified(0,0,HexToBytes('01020304'),Frozen);
    11: S.CreateTransactionMacFileVerified(1,0,$EFF0,$34,Frozen);
    12: begin
      Tmac := S.ReadTransactionMacSettings(1);
      Check((Tmac.KeyVersion=$34) and (Tmac.AccessRights=$EFF0), 'Acquired AES TMAC metadata');
    end;
    14,15: begin
      RecordData := S.ReadTransactionMacRecord(1);
      Check((RecordData.Counter=1) and RecordData.SessionProtected and not RecordData.KeyVerified,
        'Secure-session TMAC record is distinct from offline key verification');
    end;
    16: S.ChangeTransactionMacSettingsVerified(1,Frozen,$33,$EFF0,1000);
    17: S.DeleteTransactionMacFileVerified(1,Frozen);
    13: begin
      RecordData := S.ReadTransactionMacRecord(1);
      Check((RecordData.Counter=High(Cardinal)) and (BytesToHex(RecordData.Mac)='1122334455667788'), 'Unsigned counter and complete stored TMAC record');
      Check(not RecordData.SessionProtected and not RecordData.KeyVerified,'Plain stored TMAC bytes are not claimed as verified');
    end;
  end;
end;

procedure RunFileManagement(const Kind, Fail, Corrupt, ByteIndex, BitIndex: Integer;
  const Freeze: Boolean);
var
  Wire: TWire;
  Hold: ICardTransport;
  Reader: TDesfireCardReader;
  Session: IDesfireFileManagement;
  Frozen: TBytes;
  Aid: Cardinal;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := FilePairs(Kind);
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  case Kind of
    1: Frozen := HexToBytes('D276000085010100');
    8: Frozen := HexToBytes('0003F0FF040000');
    10: Frozen := HexToBytes('AABBCCDD');
    11: Frozen := HexToBytes('112233445566778899AABBCCDDEEFF00');
    16,17: Frozen := HexToBytes('0500F0EF0234');
  else Frozen := nil;
  end;
  if Freeze then
  begin
    Wire.MutateCall := 4;
    Wire.Borrowed := Frozen;
  end;
  Reader := TDesfireCardReader.Create(nil);
  Failed := False;
  Uncertain := False;
  try
    Reader.Transport := Hold;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Security := dfsEv2Aes;
    Reader.AuthenticationKey := HexToBytes('00000000000000000000000000000000');
    Aid := 1;
    if Kind in [0,1] then Aid := 0;
    if Kind=13 then Reader.MinimumCommunication := dfcPlain;
    if Kind=18 then Reader.KeyNumber := 1;
    try
      Session := Reader.OpenFileManagementSession(Aid);
      FileOperation(Session,Kind,Frozen);
      Session.Close;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
      end;
    end;
    if (Fail=0) and (Corrupt=0) then
    begin
      Check(not Failed,'Independent ISO/multi-access/TMAC transcript '+IntToStr(Kind));
      Check(Wire.Calls=Length(Wire.Pairs),'Complete native file-management postconditions');
    end
    else
    begin
      Check(Failed,'Every native file-management fault observable');
      Check(Uncertain=(Wire.Writes>0),'Native file mutation uncertainty begins at dispatch Kind='+IntToStr(Kind)+' Fail='+IntToStr(Fail)+' Corrupt='+IntToStr(Corrupt)+' Calls='+IntToStr(Wire.Calls)+' Writes='+IntToStr(Wire.Writes));
    end;
  finally
    Session := nil;
    Reader.Free;
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Native file-management lifetime always released');
    TCardCrypto.Clear(Frozen);
  end;
end;

procedure TestFileManagement;
var
  Kind, I, J: Integer;
  Pairs: TExtendedPairs;
  Settings: TDesfireMultiAccessSettings;
  Tmac: TDesfireTmacSettings;
  Directory: TDesfireIsoApplication;
  Fids: TDesfireIsoFileIds;
  Raw: TBytes;
  Failed: Boolean;
begin
  for Kind := 0 to 18 do
  begin
    Pairs := FilePairs(Kind);
    RunFileManagement(Kind,0,0,0,0,False);
    if Kind in [1,8,10,11,16,17] then RunFileManagement(Kind,0,0,0,0,True);
    for I := 1 to Length(Pairs) do RunFileManagement(Kind,I,0,0,0,False);
    // Every protected final response bit; directory frames are checked after aggregate MAC verification.
    for J := 0 to Length(HexToBytes(Pairs[High(Pairs)].Response))*8-17 do
      RunFileManagement(Kind,0,Length(Pairs),J div 8,J mod 8,False);
  end;
  for I := 0 to 31 do
  begin
    Raw := HexToBytes('0083F0FF040000010F00');
    SetLength(Raw,I);
    Failed := False;
    try Settings := TDesfireExtensionCodec.MultiAccessSettings(Raw);
    except on E: EDesfireExtensionError do Failed := True; end;
    Check(Failed=(I<>10),'Exact multi-access conditional length enforced');
    if not Failed then Check(Length(Settings.Rights)=2,'Decoded additional tuple count');
  end;
  Directory := TDesfireExtensionCodec.IsoApplication(HexToBytes('56341205E1D276000085010100'));
  Check((Directory.Aid=$123456) and (Directory.IsoFid=$E105),'Independent ISO application tuple codec');
  Failed := False;
  try
    Fids := TDesfireExtensionCodec.IsoFileIds(HexToBytes('04E104E1'));
    Check(Length(Fids)=2,'Invalid duplicate cannot produce a different list');
  except on E: EDesfireExtensionError do Failed := True; end;
  Check(Failed,'Duplicate ISO FIDs rejected');
  Failed := False;
  try TDesfireExtensionCodec.ValidateIsoFid($3F00);
  except on E: EDesfireExtensionError do Failed := True; end;
  Check(Failed,'ISO MF identifier not used as an application/file FID');
  Tmac := TDesfireExtensionCodec.TmacSettings(HexToBytes('0500F0EF0234'));
  Check(Tmac.KeyVersion=$34,'Exact AES TMAC key version decoded');
  Tmac := TDesfireExtensionCodec.TmacSettings(HexToBytes('0533F0EF0234FFFFFFFF'));
  Check(Tmac.CounterLimitEnabled and (Tmac.CounterLimit=High(Cardinal)), 'Full unsigned AES TMAC limit preserved');
  Directory := TDesfireExtensionCodec.IsoApplication(HexToBytes('02000000E2'));
  Check(Length(Directory.DfName)=0,'Existing unnamed ISO application retained');

end;

function TmacTransactionPairs(const Kind: Integer): TExtendedPairs;
begin
  case Kind of
    0: Result := DfTmacWrite;
    1: Result := DfTmacRead;
    2: Result := DfTmacAbort;
    3: Result := DfTmacReaderWrite;
    4: Result := DfTmacReaderRead;
    5: Result := DfTmacReaderAbort;
    6: Result := DfTmacBadMac;
  else Result := DfTmacBadCounter;
  end;
end;

procedure RunTmacTransaction(const Kind, Fail, Corrupt, ByteIndex, BitIndex: Integer;
  const WrongKey, WrongUid, ReleaseFails: Boolean);
var
  Wire: TWire;
  Hold: ICardTransport;
  Reader: TDesfireCardReader;
  Session: IDesfireTransactionMacSession;
  Receipt: TDesfireTmacRecord;
  Key, Uid, Previous, Input: TBytes;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := TmacTransactionPairs(Kind);
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.EndFails := ReleaseFails;
  Reader := TDesfireCardReader.Create(nil);
  Key := HexToBytes('112233445566778899AABBCCDDEEFF00');
  Uid := HexToBytes('04112233445566');
  if WrongKey then Key[0] := Key[0] xor $FF;
  if WrongUid then Uid[0] := Uid[0] xor $FF;
  Failed := False;
  Uncertain := False;
  try
    Reader.Transport := Hold;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Security := dfsEv2Aes;
    Reader.AuthenticationKey := HexToBytes('00000000000000000000000000000000');
    try
      Session := Reader.OpenTransactionMacSession(1,1,Uid,Key,0,True);
      if Kind in [3,4,5] then
      begin
        Previous := Session.CommitReaderId(HexToBytes('102132435465768798A9BACBDCEDFE0F'));
        if not WrongKey then Check(BytesToHex(Previous)='00000000000000000000000000000000','MAC-protected transaction-key reader ID decryption');
      end;
      if Kind in [0,3,6,7] then Session.WriteBackup(0,0,HexToBytes('AABBCCDD'))
      else Check(BytesToHex(Session.ReadData(0,0,4))='01020304','Read-only TMAC transaction data');
      Input := Session.ReadTransactionMacInput;
      Check((Length(Input)>0) and (Length(Input) mod 16=0),'Canonical TMI captures complete successful operations');
      Check(Session.PendingChanges,'Reads create an owned pending TMAC calculation');
      if Kind in [2,5] then Session.Abort
      else
      begin
        Receipt := Session.CommitTransactionMacVerified;
        Check((Receipt.Counter=1) and Receipt.SessionProtected, 'Protected TMAC receipt accepted only with exact counter');
        Check(Session.VerificationSucceeded and Receipt.KeyVerified,'Offline TMAC and native journal verification complete');
      end;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
        if (Kind<6) and (Fail=0) and (Corrupt=0) and not WrongKey and not WrongUid and not ReleaseFails then
          Writeln('TMAC diagnostic: ',E.ClassName,': ',E.Message,' calls=',Wire.Calls);
      end;
    end;
    if (Kind<6) and (Fail=0) and (Corrupt=0) and not WrongKey and not WrongUid and not ReleaseFails then
    begin
      Check(not Failed,'Independent TMAC transaction succeeds '+IntToStr(Kind));
      Check(Wire.Calls=Length(Wire.Pairs),'Complete TMAC transaction/journal/release chain');
    end
    else
    begin
      Check(Failed,'TMAC native/offline/identity/release fault observed');
      Check(Uncertain=(Wire.Writes>0),'TMAC mutation uncertainty survives receipt/journal/release failures');
    end;
  finally
    Session := nil;
    Reader.Free;
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'TMAC profile acquisition always released');
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Uid);
    TCardCrypto.Clear(Previous);
    TCardCrypto.Clear(Input);
  end;
end;

procedure TestTmacTransactions;
var
  Kind, I, J: Integer;
  Pairs, Crypto: TExtendedPairs;
  Key, Uid, Derived, Input, Block, Mac, Previous: TBytes;
  Failed: Boolean;
begin
  for Kind := 0 to 5 do
  begin
    Pairs := TmacTransactionPairs(Kind);
    RunTmacTransaction(Kind,0,0,0,0,False,False,False);
    RunTmacTransaction(Kind,0,0,0,0,False,True,False);
    RunTmacTransaction(Kind,0,0,0,0,False,False,True);
    if Kind in [0,1,3,4] then RunTmacTransaction(Kind,0,0,0,0,True,False,False);
    for I := 1 to Length(Pairs) do RunTmacTransaction(Kind,I,0,0,0,False,False,False);
    for I := 4 to Length(Pairs) do
      for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-17 do
        RunTmacTransaction(Kind,0,I,J div 8,J mod 8,False,False,False);
  end;
  RunTmacTransaction(6,0,0,0,0,False,False,False);
  RunTmacTransaction(7,0,0,0,0,False,False,False);
  Crypto := DfTmacCrypto;
  Key := HexToBytes('112233445566778899AABBCCDDEEFF00');
  Uid := HexToBytes('04112233445566');
  try
    Derived := TDesfireTmacCrypto.DeriveKey(Base,Key,Uid,1,False);
    Check(BytesEqual(Derived,HexToBytes(Crypto[0].Response)),'Independent published-vector-layout MAC key');
    TCardCrypto.Clear(Derived);
    Derived := TDesfireTmacCrypto.DeriveKey(Base,Key,Uid,1,True);
    Check(BytesEqual(Derived,HexToBytes(Crypto[1].Response)),'Independent published-vector-layout reader encryption key');
    Input := TDesfireTmacCrypto.AppendInput(nil,$AD,HexToBytes('00000000040000'),HexToBytes('01020304'));
    Block := TDesfireTmacCrypto.AppendInput(Input,$8D,HexToBytes('00000000040000'),HexToBytes('AABBCCDD'));
    Check(BytesEqual(Block,HexToBytes(Crypto[2].Command)),'Independent aligned read/write canonical input');
    Mac := TDesfireTmacCrypto.Mac(Base,Key,Uid,1,Block);
    Check(BytesEqual(Mac,HexToBytes(Crypto[2].Response)),'Independent offline transaction MAC');
    Previous := TDesfireTmacCrypto.DecryptReaderId(Base,Key,Uid,1,HexToBytes(Crypto[3].Response));
    Check(BytesEqual(Previous,HexToBytes(Crypto[3].Command)),'Independent previous reader ID AES vector');
    for I := 0 to 7 do
    begin
      Failed := False;
      try
        case I of
          0: TDesfireTmacCrypto.DeriveKey(Base,Key,Uid,0,False);
          1: TDesfireTmacCrypto.AppendInput(nil,$00,nil,nil);
          2: TDesfireTmacCrypto.AppendInput(nil,$AB,HexToBytes('00000000010000'),HexToBytes('0102'));
          3: TDesfireTmacCrypto.AppendInput(nil,$6C,HexToBytes('00'),HexToBytes('0102'));
          4: TDesfireTmacCrypto.AppendInput(nil,$EB,HexToBytes('00'),HexToBytes('01'));
          5: TDesfireTmacCrypto.AppendInput(nil,$C8,HexToBytes('01'),HexToBytes('02'));
          6: TDesfireTmacCrypto.Mac(Base,Key,Uid,1,HexToBytes('01'));
          7: TDesfireTmacCrypto.DecryptReaderId(Base,Key,Uid,1,HexToBytes('01'));
        end;
      except on E: EDesfireExtensionError do Failed := True; end;
      Check(Failed,'Malformed TMAC vector/input rejected');
    end;
  finally
    TCardCrypto.Clear(Key); TCardCrypto.Clear(Uid); TCardCrypto.Clear(Derived);
    TCardCrypto.Clear(Input); TCardCrypto.Clear(Block); TCardCrypto.Clear(Mac); TCardCrypto.Clear(Previous);
  end;
end;

function IsoKeySetPairs(const Kind: Integer): TExtendedPairs;
begin
  case Kind of
    0: Result := DfIsoCreateKeySets;
    1: Result := DfIsoCreateBadGeometry;
    2: Result := DfIsoCreateBadFid;
  else Result := DfIsoCreateBadName;
  end;
end;

procedure RunIsoKeySets(const Kind, Fail, Corrupt, ByteIndex, BitIndex: Integer;
  const Freeze, ReleaseFails: Boolean);
var
  Wire: TWire;
  Hold: ICardTransport;
  Reader: TDesfireCardReader;
  Session: IDesfireIsoKeySetManagement;
  Name: TBytes;
  Entries: TDesfireIsoApplications;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := IsoKeySetPairs(Kind);
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.EndFails := ReleaseFails;
  Name := HexToBytes('D276000085010100');
  if Freeze then
  begin
    Wire.MutateCall := 4;
    Wire.Borrowed := Name;
  end;
  Reader := TDesfireCardReader.Create(nil);
  Failed := False;
  Uncertain := False;
  try
    Reader.Transport := Hold;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Security := dfsEv2Aes;
    Reader.AuthenticationKey := HexToBytes('00000000000000000000000000000000');
    try
      Session := Reader.OpenIsoKeySetManagementSession;
      Session.CreateIsoApplicationWithKeySetsVerified($123456,$0F,3,4,$21,1,$E105,Name);
      Entries := Session.ReadIsoApplications;
      Check((Length(Entries)=2) and (Entries[1].Aid=$123456),'Restored PICC authentication and acquired ISO directory');
      Session.Close;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
        if (Kind=0) and (Fail=0) and (Corrupt=0) and not ReleaseFails then
          Writeln('ISO key-set diagnostic: ',E.ClassName,': ',E.Message,' calls=',Wire.Calls);
      end;
    end;
    if (Kind=0) and (Fail=0) and (Corrupt=0) and not ReleaseFails then
    begin
      Check(not Failed,'ISO and key sets verified in one native creation');
      Check(Wire.Calls=Length(Wire.Pairs),'Complete ISO tuple, geometry and restored authentication transcript');
    end
    else
    begin
      Check(Failed,'ISO tuple, key geometry or native/release fault is observable');
      Check(Uncertain=((Wire.Writes>0) and (Fail<=14) and (Corrupt<=14) and not ReleaseFails),
        'ISO creation uncertainty until geometry proof and reauthentication complete');
    end;
  finally
    Session := nil;
    Reader.Free;
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'ISO key-set owner released');
    TCardCrypto.Clear(Name);
  end;
end;

function StandardTmacPairs(const Kind: Integer): TExtendedPairs;
begin
  case Kind of
    0: Result := DfTmacStandardWrite;
    1: Result := DfTmacStandardOverlap;
    2: Result := DfTmacStandardDisjoint;
    3: Result := DfTmacStandardNoop;
    4: Result := DfTmacStandardAbort;
    5: Result := DfTmacStandardRepeat;
    6: Result := DfTmacStandardPreimage;
    7: Result := DfTmacStandardImmediateMismatch;
    8: Result := DfTmacStandardCommitMismatch;
    9: Result := DfTmacStandardDeniedWrite;
    10: Result := DfTmacStandardDeniedRead;
    11: Result := DfTmacStandardWrongFile;
  else Result := DfTmacStandardBounds;
  end;
end;

procedure RunStandardTmac(const Kind, Fail, Corrupt, ByteIndex, BitIndex, Freeze: Integer;
  const ReleaseFails: Boolean);
var
  Wire: TWire;
  Hold: ICardTransport;
  Reader: TDesfireCardReader;
  Session: IDesfireTransactionMacDataSession;
  Receipt: TDesfireTmacRecord;
  Expected, Data, Input: TBytes;
  Offset: Integer;
  Failed, Uncertain: Boolean;
begin
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := StandardTmacPairs(Kind);
  Wire.FailCall := Fail;
  Wire.CorruptCall := Corrupt;
  Wire.CorruptByte := ByteIndex;
  Wire.CorruptBit := BitIndex;
  Wire.EndFails := ReleaseFails;
  Offset := 2;
  Expected := HexToBytes('01020304');
  Data := HexToBytes('AABBCCDD');
  if Kind=2 then
  begin
    Offset := 0;
    Expected := HexToBytes('0102');
    Data := HexToBytes('AABB');
  end;
  if Kind=3 then Data := Copy(Expected);
  if Kind=6 then Expected[0] := $FF;
  if Kind=12 then Offset := 7;
  if Freeze>0 then
  begin
    Wire.MutateCall := 8;
    if Freeze=1 then Wire.Borrowed := Expected else Wire.Borrowed := Data;
  end;
  Reader := TDesfireCardReader.Create(nil);
  Failed := False;
  Uncertain := False;
  try
    Reader.Transport := Hold;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Security := dfsEv2Aes;
    Reader.AuthenticationKey := HexToBytes('00000000000000000000000000000000');
    try
      Session := Reader.OpenTransactionMacDataSession(1,1,HexToBytes('04112233445566'),
        HexToBytes('112233445566778899AABBCCDDEEFF00'),0,True);
      Session.WriteStandardDataVerified(0,Offset,Expected,Data);
      case Kind of
        1: Session.WriteStandardDataVerified(0,3,HexToBytes('BBCC'),HexToBytes('5566'));
        2: Session.WriteStandardDataVerified(0,6,HexToBytes('0708'),HexToBytes('CCDD'));
        5: Session.WriteStandardDataVerified(0,2,HexToBytes('AABBCCDD'),HexToBytes('22334455'));
      end;
      Input := Session.ReadTransactionMacInput;
      Check((Length(Input)>0) and (Length(Input) mod 16=0),'Range reads/write/read-back captured in canonical TMI');
      Check(Session.PendingChanges,'Explicit pending standard-data TMAC calculation');
      if Kind=4 then
      begin
        Session.Abort;
        Check(Session.Outcome=dsoAborted,'Abort calculation has no fabricated standard-data rollback');
      end
      else
      begin
        Receipt := Session.CommitTransactionMacVerified;
        Check((Receipt.Counter=1) and Receipt.KeyVerified and Receipt.SessionProtected and
          Session.VerificationSucceeded,'Standard range receipt and final range proofs both required');
      end;
    except
      on E: Exception do
      begin
        Failed := True;
        Uncertain := E is EContactlessWriteUncertain;
        if (Kind<6) and (Fail=0) and (Corrupt=0) and not ReleaseFails then
          Writeln('Standard TMAC diagnostic: ',E.ClassName,': ',E.Message,' calls=',Wire.Calls);
      end;
    end;
    if (Kind<6) and (Fail=0) and (Corrupt=0) and not ReleaseFails then
    begin
      Check(not Failed,'Independent standard TMAC range chain '+IntToStr(Kind));
      Check(Wire.Calls=Length(Wire.Pairs),'Every immediate and post-commit range proof executed');
    end
    else
    begin
      Check(Failed,'Native, preimage, valid-MAC wrong content or release fault observed');
      if (Kind>=9) and (Fail=0) and (Corrupt=0) then
        Check((Wire.Writes=0) and (Wire.Calls=Length(Wire.Pairs)), 'Acquired type/authority/bounds refused before data dispatch');
      Check(Uncertain=(Wire.Writes>0),'Immediate standard-data dispatch retains uncertainty through commit/abort/release');
    end;
  finally
    Session := nil;
    Reader.Free;
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Standard TMAC owner always released');
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Data);
    TCardCrypto.Clear(Input);
  end;
end;

procedure TestIsoAndRangeInputGuards;
var
  Wire: TWire;
  Hold: ICardTransport;
  Reader: TDesfireCardReader;
  Iso: IDesfireIsoKeySetManagement;
  Data: IDesfireTransactionMacDataSession;
  Failed: Boolean;
  I, Before: Integer;
  Name, Empty: TBytes;
begin
  Wire := TWire.Create;
  Hold := Wire;
  Wire.Pairs := DfIsoCreateKeySets;
  Reader := TDesfireCardReader.Create(nil);
  Name := HexToBytes('D276000085010100');
  Empty := nil;
  try
    Reader.Transport := Hold;
    Reader.CryptoProvider := TFixed.Create;
    Reader.Security := dfsEv2Aes;
    Reader.AuthenticationKey := HexToBytes('00000000000000000000000000000000');
    Iso := Reader.OpenIsoKeySetManagementSession;
    Before := Wire.Calls;
    for I := 0 to 6 do
    begin
      Failed := False;
      try
        case I of
          0: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$0D,3,4,$21,1,$E105,Name);
          1: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$0F,3,1,$21,1,$E105,Name);
          2: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$0F,3,4,$21,3,$E105,Name);
          3: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$0F,3,4,$21,1,$3F00,Name);
          4: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$0F,3,4,$21,1,$E105,Empty);
          5: Iso.CreateIsoApplicationWithKeySetsVerified(0,$0F,3,4,$21,1,$E105,Name);
          6: Iso.CreateIsoApplicationWithKeySetsVerified($123456,$3F,3,4,$21,1,$E105,Name);
        end;
      except on E: Exception do Failed := True; end;
      Check(Failed and (Wire.Calls=Before) and (Wire.Writes=0),'Invalid ISO/key-set inputs refused without card I/O');
    end;
    Iso.Close;
    Iso := nil;
    Wire.Pairs := DfTmacStandardWrite;
    Wire.Calls := 0;
    Data := Reader.OpenTransactionMacDataSession(1,1,HexToBytes('04112233445566'),
      HexToBytes('112233445566778899AABBCCDDEEFF00'),0,True);
    Before := Wire.Calls;
    for I := 0 to 4 do
    begin
      Failed := False;
      try
        case I of
          0: Data.WriteStandardDataVerified(32,0,Name,Name);
          1: Data.WriteStandardDataVerified(0,-1,Name,Name);
          2: Data.WriteStandardDataVerified(0,0,Empty,Empty);
          3: Data.WriteStandardDataVerified(0,0,Empty,Name);
          4: Data.WriteStandardDataVerified(0,0,Name,Empty);
        end;
      except on E: Exception do Failed := True; end;
      Check(Failed and (Wire.Calls=Before) and (Wire.Writes=0),'Invalid standard ranges refused before I/O');
    end;
    Data.Close;
  finally
    Iso := nil;
    Data := nil;
    Reader.Free;
    TCardCrypto.Clear(Name);
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Guard-only acquisitions released without hidden abort');
  end;
end;

procedure TestIsoKeySetsAndStandardTmac;
var
  Kind, I, J: Integer;
  Pairs: TExtendedPairs;
begin
  for Kind := 0 to 3 do RunIsoKeySets(Kind,0,0,0,0,False,False);
  RunIsoKeySets(0,0,0,0,0,True,False);
  RunIsoKeySets(0,0,0,0,0,False,True);
  Pairs := IsoKeySetPairs(0);
  for I := 1 to Length(Pairs) do RunIsoKeySets(0,I,0,0,0,False,False);
  for I := 4 to Length(Pairs) do
    for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-17 do
      RunIsoKeySets(0,0,I,J div 8,J mod 8,False,False);
  for Kind := 0 to 12 do RunStandardTmac(Kind,0,0,0,0,0,False);
  for Kind := 0 to 5 do
  begin
    RunStandardTmac(Kind,0,0,0,0,1,False);
    RunStandardTmac(Kind,0,0,0,0,2,False);
    RunStandardTmac(Kind,0,0,0,0,0,True);
    Pairs := StandardTmacPairs(Kind);
    for I := 1 to Length(Pairs) do RunStandardTmac(Kind,I,0,0,0,0,False);
    for I := 4 to Length(Pairs) do
      for J := 0 to Length(HexToBytes(Pairs[I-1].Response))*8-17 do
        RunStandardTmac(Kind,0,I,J div 8,J mod 8,0,False);
  end;
end;

begin
  try
{$IFDEF MSWINDOWS} Base:=TCardWindowsAesProvider.Create; {$ELSE} Base:=TCardOpenSslAesProvider.Create; {$ENDIF}
    TestCodecs; TestDf; TestPlus; TestPlusWorkflow; TestAcr; TestPlus4K; TestFrozenInputs; TestPlusManagement; TestPlusLevels; TestPlusValues; TestNativeValues; TestFileManagement; TestTmacTransactions; TestIsoKeySetsAndStandardTmac; TestIsoAndRangeInputGuards;
    Writeln('PASS: ',Checks,' DESFire extension/Plus assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
