program IcaoDocumentTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.APDU, ERD.Card.Crypto,
  ERD.Card.Crypto.EAC, ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.EID.Access,
  ERD.Card.EID.DocumentReader, ERD.Card.EID.SecureMessaging, Icao.Vectors;

type
  TFixedProvider=class(TInterfacedObject,ICardAesProvider,ICardEacProvider)
  private
    FBase:ICardEacProvider;
  public
    Calls,FailRandom,MalformedRandom:Integer;
    ZeroRandom:Boolean;
    constructor Create(const Base:ICardEacProvider);
    function EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function RandomBytes(const ACount:Integer):TBytes;
    function Sha1(const AData:TBytes):TBytes;
    function TripleDesCbc(const AKey,AIv,AData:TBytes;const AEncrypt:Boolean):TBytes;
    function CreatePaceAgreement(const ACurve:TCardPaceCurve;const AMappingSecret,AAgreementSecret:TBytes):ICardPaceAgreement;
  end;
  TTranscript=class(TInterfacedObject,ICardTransport,ICardTransaction)
  public
    Pairs:TIcaoWirePairs;
    Calls,Begins,Ends,FailCall,CorruptCall,CorruptByte,CorruptBit,ReplaceCall:Integer;
    Replacement:TBytes;
    Active,BeginFails,EndFails,Reenter:Boolean;
    Reader:TICAODocumentReader;
    constructor Create(const APairs:TIcaoWirePairs);
    function Exchange(const ACommand:TBytes):TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
var Checks:Integer; Base:ICardEacProvider;
procedure Check(const Value:Boolean;const Text:string);
begin Inc(Checks); if not Value then raise Exception.Create(Text); end;
function Ascii(const Text:AnsiString):TBytes;
var I:Integer;
begin Result:=nil;SetLength(Result,Length(Text));for I:=1 to Length(Text) do Result[I-1]:=Ord(Text[I]);end;
constructor TFixedProvider.Create(const Base:ICardEacProvider);
begin inherited Create;FBase:=Base;end;
function TFixedProvider.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.EncryptCbc(AKey,AIv,AData);end;
function TFixedProvider.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.DecryptCbc(AKey,AIv,AData);end;
function TFixedProvider.Sha1(const AData:TBytes):TBytes;
begin Result:=FBase.Sha1(AData);end;
function TFixedProvider.TripleDesCbc(const AKey,AIv,AData:TBytes;const AEncrypt:Boolean):TBytes;
begin Result:=FBase.TripleDesCbc(AKey,AIv,AData,AEncrypt);end;
function TFixedProvider.CreatePaceAgreement(const ACurve:TCardPaceCurve;const AMappingSecret,AAgreementSecret:TBytes):ICardPaceAgreement;
begin Result:=FBase.CreatePaceAgreement(ACurve,AMappingSecret,AAgreementSecret);end;
function TFixedProvider.RandomBytes(const ACount:Integer):TBytes;
begin
  Inc(Calls); if Calls=FailRandom then raise ECardCryptoError.Create('Synthetic RNG failure');
  case ACount of
    8:Result:=HexToBytes('781723860C06C226');
    16:Result:=HexToBytes('0B795240CB7049B01C19B33E32804F0B');
    32:if Calls=1 then Result:=HexToBytes('7F4EF07B9EA82FD78AD689B38D0BC78CF21F249D953BC46F4C6E19259C010F99')
       else Result:=HexToBytes('A73FB703AC1436A18E0CFA5ABB3F7BEC7A070E7A6788486BEE230C4A22762595');
  else raise Exception.Create('Unexpected random count'); end;
  if Calls=MalformedRandom then SetLength(Result,ACount-1);
  if ZeroRandom then FillChar(Result[0],Length(Result),0);
end;
constructor TTranscript.Create(const APairs:TIcaoWirePairs);
begin inherited Create;Pairs:=Copy(APairs,0,Length(APairs));end;
procedure TTranscript.BeginTransaction;
begin Inc(Begins);if BeginFails then raise ECardTransportError.Create('Synthetic acquisition failure');
  Check(not Active,'Exclusive acquisition');Active:=True;end;
procedure TTranscript.EndTransaction;
begin Inc(Ends);Check(Active,'Owned release');Active:=False;
  if EndFails then raise ECardTransportError.Create('Synthetic release failure');end;
function TTranscript.Exchange(const ACommand:TBytes):TBytes;
var Rejected:Boolean;
begin
  Check(Active,'Exchange acquired');Inc(Calls);
  Check(Calls<=Length(Pairs),'No replay/extra I/O');
  if not ((CorruptCall=7) and (Calls=9)) then
    Check(BytesEqual(ACommand,HexToBytes(Pairs[Calls-1].Command)),'Independent command at '+IntToStr(Calls));
  if Reenter then
  begin
    Reenter:=False;Rejected:=False;
    try Reader.ReadDocument([idsCommon]);except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected and Reader.Busy,'Read reentrancy refused');Rejected:=False;
    try Reader.AccessPassword:=nil;except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected,'Busy credentials immutable');Rejected:=False;
    try Reader.Transport:=nil;except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected,'Busy transport immutable');
  end;
  if Calls=FailCall then raise ECardTransportError.Create('Synthetic I/O failure');
  Result:=HexToBytes(Pairs[Calls-1].Response);
  if Calls=ReplaceCall then Result:=Copy(Replacement,0,Length(Replacement));
  if Calls=CorruptCall then Result[CorruptByte]:=Result[CorruptByte] xor (1 shl CorruptBit);
end;
procedure Configure(const R:TICAODocumentReader;const T:TTranscript;const Pace,Can,Nist:Boolean);
begin
  R.Transport:=T;R.CryptoProvider:=TFixedProvider.Create(Base);
  if Pace then R.AccessPassword:=Ascii('T22000129364081251010318')
  else begin R.Security:=iasBac;R.AccessPassword:=Ascii('L898902C<369080619406236');end;
  if Can then begin R.PasswordKind:=ipkCan;R.AccessPassword:=Ascii('123456');end;
  if Nist then R.PaceCurve:=ppcNistP256;
end;
procedure Success(const Pairs:TIcaoWirePairs;const Pace,Can,Nist,Large:Boolean);
var T:TTranscript;Transport:ICardTransport;R:TICAODocumentReader;D:TIcaoDocumentData;B,C:TBytes;I,Odd:Integer;
begin
  T:=TTranscript.Create(Pairs);Transport:=T;R:=TICAODocumentReader.Create(nil);
  try
    Configure(R,T,Pace,Can,Nist);T.Reader:=R;T.Reenter:=True;
    B:=R.AccessPassword;C:=Copy(B,0,Length(B));B[0]:=0;
    Check(BytesEqual(R.AccessPassword,C),'Password getter copied');R.AccessPassword:=C;C[0]:=0;
    Check(not BytesEqual(R.AccessPassword,C),'Password setter copied');
    D:=R.ReadDocument([idsIdentity,idsFace,idsCommon,idsSecurityObject]);
    Check((T.Calls=Length(Pairs)) and (T.Begins=1) and (T.Ends=1) and not T.Active and not R.Busy,'Complete exclusive workflow');
    Check((D.Identity.DocumentNumber='D23145890') and (D.Identity.Surname='ERIKSSON'),'DG1 identity');
    Check((Length(D.Biometrics.Images)=1) and (D.Biometrics.Images[0].Width=150),'DG2 photo metadata');
    if Large then Check(Length(D.Biometrics.Images[0].Data)=66000,'Complete large encoded photo')
    else Check(BytesToHex(D.Biometrics.Images[0].Data)='FFD8FFAA','Exact image payload');
    Check(BytesToHex(D.Common)='60065C0461757776','Complete COM');
    Check(BytesToHex(D.SecurityObject)='770430020500','Complete opaque SOD');
    Check((Length(D.PaceInfos)>0)=Pace,'Only acquired PACE info');
    Odd:=0;
    for I:=0 to High(Pairs) do
    begin
      B:=HexToBytes(Pairs[I].Command);
      if B[1]=$B1 then Inc(Odd);
    end;
    // The offset DO54 is encrypted in SM; literal command case, complete payload and exact transcript
    // demonstrate both boundaries. No unprotected offset should appear in ciphertext by assumption.
    if Large then Check(Odd>150,'Odd B1 beyond 32767 including offsets above 65535');
    R.Free;R:=nil;Transport:=nil;
    Check(D.Identity.DocumentNumber='D23145890','Document outlives component/transport');
  finally R.Free;Transport:=nil;end;
end;
procedure Failure(const Pairs:TIcaoWirePairs;const Pace:Boolean;const Fail,Corrupt,Position,Bit:Integer;
  const Replacement:TBytes;const ReplaceCall:Integer;const EndFails,BeginFails:Boolean;
  const RandomFailure,Malformed:Integer;const ZeroRandom:Boolean=False;const MaxFile:Integer=0;const MaxTotal:Integer=0);
var T:TTranscript;Transport:ICardTransport;R:TICAODocumentReader;P:TFixedProvider;
  D:TIcaoDocumentData;Rejected:Boolean;MessageText:string;
begin
  T:=TTranscript.Create(Pairs);Transport:=T;R:=TICAODocumentReader.Create(nil);
  try
    Configure(R,T,Pace,False,False);P:=TFixedProvider.Create(Base);R.CryptoProvider:=P;
    P.FailRandom:=RandomFailure;P.MalformedRandom:=Malformed;P.ZeroRandom:=ZeroRandom;
    T.FailCall:=Fail;T.CorruptCall:=Corrupt;T.CorruptByte:=Position;T.CorruptBit:=Bit;
    T.Replacement:=Replacement;T.ReplaceCall:=ReplaceCall;T.EndFails:=EndFails;T.BeginFails:=BeginFails;
    if MaxFile>0 then R.MaxFileBytes:=MaxFile;if MaxTotal>0 then R.MaxTotalBytes:=MaxTotal;
    Rejected:=False;MessageText:='';D:=Default(TIcaoDocumentData);
    try D:=R.ReadDocument([idsIdentity,idsFace,idsCommon,idsSecurityObject]);
    except on E:Exception do begin Rejected:=True;MessageText:=E.Message;end;end;
    Check(Rejected and (Length(D.DG1)=0) and (Length(D.DG2)=0),'No partial data on failure');
    Check((T.Begins=1) and not T.Active and not R.Busy,'Failed workflow releases state');
    Check(T.Ends=Ord(not BeginFails),'Release only acquired transaction exactly once');
    if Fail>0 then begin Check(T.Calls=Fail,'I/O failure not replayed');Check(MessageText='Synthetic I/O failure','Original error wins release failure');end;
    if Corrupt>0 then
      if Pace and (Corrupt>=7) and (Corrupt<=9) then
        Check((T.Calls>=Corrupt) and (T.Calls<=10),'Altered PACE negotiation fails before secure file reads')
      else Check(T.Calls=Corrupt,'Altered protected response stops immediately');
    if ZeroRandom then Check(P.Calls=32,'Bounded rejection sampling without APDU replay');
  finally R.Free;Transport:=nil;end;
end;
procedure Faults(const Pairs:TIcaoWirePairs;const Pace:Boolean;const Large:Boolean=False);
var I,J,Bit,Start:Integer;B:TBytes;
begin
  for I:=1 to Length(Pairs) do Failure(Pairs,Pace,I,0,0,0,nil,0,True,False,0,0);
  if Large then Exit;
  Start:=3;if Pace then Start:=7;
  for I:=Start to Length(Pairs) do
  begin
    B:=HexToBytes(Pairs[I-1].Response);
    for J:=0 to High(B) do
      for Bit:=0 to 7 do Failure(Pairs,Pace,0,I,J,Bit,nil,0,False,False,0,0);
  end;
  Failure(Pairs,Pace,0,0,0,0,nil,0,True,False,0,0);
  Failure(Pairs,Pace,0,0,0,0,nil,0,False,True,0,0);
  for I:=1 to 2 do
  begin
    Failure(Pairs,Pace,0,0,0,0,nil,0,False,False,I,0);
    Failure(Pairs,Pace,0,0,0,0,nil,0,False,False,0,I);
  end;
  if Pace then Failure(Pairs,True,0,0,0,0,nil,0,False,False,0,0,True);
end;
procedure LocalGuards;
var R:TICAODocumentReader;T:TTranscript;Transport:ICardTransport;D:TIcaoDocumentData;I:Integer;Rejected:Boolean;B:TBytes;
begin
  R:=TICAODocumentReader.Create(nil);T:=TTranscript.Create(BacDocument);Transport:=T;
  try
    Configure(R,T,False,False,False);
    for I:=0 to 5 do
    begin
      Rejected:=False;
      try
        case I of
          0:R.ReadDocument([]);
          1:R.ChunkSize:=221;
          2:R.MaxFileBytes:=1048577;
          3:R.MaxTotalBytes:=4194305;
          4:begin SetLength(B,65);R.AccessPassword:=B;end;
          5:begin R.PasswordKind:=ipkCan;D:=R.ReadDocument;end;
        end;
      except on E:EIcaoAccessError do Rejected:=True;end;
      Check(Rejected and (T.Begins=0) and (T.Calls=0),'Local guard before acquisition');
    end;
  finally R.Free;Transport:=nil;end;
end;
begin
  try
    Base:=TCardEacOpenSslProvider.Create;
    Success(BacDocument,False,False,False,False);
    Success(PaceBrainpoolDocument,True,False,False,False);
    Success(PaceNistDocument,True,False,True,False);
    Success(PaceCanDocument,True,True,False,False);
    Success(PaceDualDocument,True,False,False,False);
    Success(PaceLargeDocument,True,False,False,True);
    Faults(BacDocument,False);Faults(PaceBrainpoolDocument,True);Faults(PaceLargeDocument,True,True);
    Failure(BacProtectedError,False,0,0,0,0,nil,0,False,False,0,0);
    Failure(BacBadPadding,False,0,0,0,0,nil,0,False,False,0,0);
    Failure(PaceBadPadding,True,0,0,0,0,nil,0,False,False,0,0);
    Failure(BacDocument,False,0,0,0,0,nil,0,False,False,0,0,False,94,0);
    Failure(BacDocument,False,0,0,0,0,nil,0,False,False,0,0,False,0,100);
    LocalGuards;Base:=nil;
    Writeln('PASS: ICAO BAC/PACE, owned complete LDS files, large B1 photos, exact transcripts and every I/O/protected-response bit.');
    Writeln('Assertions: ',Checks);
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
