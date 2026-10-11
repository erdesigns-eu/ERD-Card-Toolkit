unit ERD.Card.Contactless.Plus;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Contactless;

type
  /// <summary>Invalid explicit Plus SL3 profile, framing, authentication or integrity.</summary>
  EMifarePlusError = class(EContactlessError);
  /// <summary>Explicit native Plus memory geometry; neither model nor security level is probed.</summary>
  TMifarePlusModel = (
    /// <summary>Two kilobytes, 128 sixteen-byte blocks.</summary>
    mpm2K,
    /// <summary>Four kilobytes, 256 blocks with larger sectors above block 127.</summary>
    mpm4K);
  /// <summary>Both modes authenticate commands and responses; no unauthenticated data mode is provided.</summary>
  TMifarePlusMode = (
    /// <summary>Plain data with transmitted command/response MACs.</summary>
    mpcMac,
    /// <summary>AES-CBC data with transmitted command/response MACs.</summary>
    mpcFull);
  /// <summary>Exclusive native ISO14443-4 reader backend with owned RF-session lifecycle.</summary>
  /// <remarks>ExchangeNative returns status-first Plus bytes, without ISO PCB/CRC or APDU SW.
  /// It sends once, with no automatic card authentication, fallback, RF reset or replay.</remarks>
  IMifarePlusSession = interface
    ['{A7446D2C-EB86-466D-B638-E9561EF9D98B}']
    /// <summary>Activates one ISO14443-4 Type A card under exclusive reader ownership.</summary>
    /// <returns>Independent freshly acquired four/seven/ten-byte UID; failure must release acquisition.</returns>
    function BeginSession: TBytes;
    /// <summary>Exchanges one bounded native command exactly once.</summary>
    /// <param name="ACommand">One through 247 bytes, borrowed and never retained.</param>
    /// <returns>Independent complete status-first native response; no CRC/SW translation by the caller.</returns>
    function ExchangeNative(const ACommand: TBytes): TBytes;
    /// <summary>Turns RF off and releases exclusivity; failure is observable and acquisition is still released.</summary>
    procedure EndSession;
  end;
  /// <summary>Owned Plus SL3 session keys, distinct from DESFire EV2 key derivation.</summary>
  TMifarePlusKeys = record
    /// <summary>Independent sixteen-byte encryption key; clear after use.</summary>
    Encryption: TBytes;
    /// <summary>Independent sixteen-byte MAC key; clear after use.</summary>
    Authentication: TBytes;
  end;
  /// <summary>One explicitly supplied SL0 personalization entry; data is borrowed by the caller and frozen before I/O.</summary>
  TMifarePlusPersonalizationEntry = record
    /// <summary>Native ordinary block, sector AES key address, or 9000/9001/9003 management key address.</summary>
    Address: Word;
    /// <summary>Exactly sixteen data/key bytes; caller must clear secret entries after use.</summary>
    Data: TBytes;
  end;
  /// <summary>Ordered explicit SL0 entries; no inferred defaults, duplicate addresses or automatic key generation.</summary>
  TMifarePlusPersonalizationEntries = array of TMifarePlusPersonalizationEntry;
  /// <summary>Completed personalization evidence without credentials or card contents.</summary>
  TMifarePlusPersonalizationResult = record
    /// <summary>Entries whose native plaintext WritePerso acknowledgement was received.</summary>
    AcknowledgedEntries: Integer;
    /// <summary>Sector/master/configuration keys proven by fresh SL3 mutual authentication.</summary>
    VerifiedKeys: Integer;
    /// <summary>Ordinary data entries proven by fresh SL3 authenticated read-back.</summary>
    VerifiedBlocks: Integer;
    /// <summary>True only after commit, fresh authentication, all selected proofs and successful release.</summary>
    Sl3Verified: Boolean;
  end;
  /// <summary>Pure explicit Plus SL3 geometry, key derivation, IV and MAC codecs.</summary>
  TMifarePlusCodec = class
  public
    /// <summary>Validates ordinary data blocks and returns their sector.</summary>
    /// <param name="AModel">Explicit 2K/4K geometry.</param>
    /// <param name="ABlock">Physical ordinary block; zero and trailers are refused.</param>
    /// <returns>Exact Classic-compatible native sector zero through thirty-nine.</returns>
    class function DataSector(const AModel: TMifarePlusModel; const ABlock: Integer): Integer; static;
    /// <summary>Derives fresh session keys by AES encryption of the Plus nonce vectors.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly sixteen supplied static key bytes.</param>
    /// <param name="ARndA">Exactly sixteen CSPRNG reader nonce bytes.</param>
    /// <param name="ARndB">Exactly sixteen independently decrypted card nonce bytes.</param>
    /// <returns>Independent owned keys; caller must clear them.</returns>
    class function DeriveKeys(const AProvider: ICardAesProvider;
      const AKey, ARndA, ARndB: TBytes): TMifarePlusKeys; static;
    /// <summary>Builds an SL3 data IV from full sixteen-bit counters; no low-byte shortcut.</summary>
    /// <param name="ATi">Four acquired transaction-ID bytes.</param>
    /// <param name="AReadCounter">Read counter zero through FFFF.</param>
    /// <param name="AWriteCounter">Write counter zero through FFFF.</param>
    /// <param name="AResponse">True puts TI last for response decrypting; false puts TI first.</param>
    /// <returns>Independent sixteen-byte IV.</returns>
    class function DataIv(const ATi: TBytes; const AReadCounter, AWriteCounter: Integer;
      const AResponse: Boolean): TBytes; static;
    /// <summary>Calculates odd-index truncated SL3 CMAC over a fully assembled native MAC input.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied MAC key bytes.</param>
    /// <param name="AInput">Exact protocol MAC input; not normalized.</param>
    /// <returns>Independent eight-byte MAC.</returns>
    class function Mac(const AProvider: ICardAesProvider; const AKey, AInput: TBytes): TBytes; static;
    /// <summary>Clears both owned session-key arrays.</summary>
    /// <param name="AKeys">Exclusive owned session keys, cleared in place.</param>
    class procedure ClearKeys(var AKeys: TMifarePlusKeys); static;
  end;
  /// <summary>Inactive native Plus SL3 AES reader/writer with fresh mutual authentication for each operation.</summary>
  /// <remarks>Ordinary reads/writes and explicit acknowledged key replacement/SL0 personalization; no implicit level transition, trailers or manufacturer writes.
  /// Reads verify response MAC before decrypting. Writes compare a supplied preimage and verify read-back in the same exclusive session.</remarks>
  TMifarePlusCardReaderWriter = class(TComponent)
  private
    FSession: IMifarePlusSession;
    FProvider: ICardAesProvider;
    FKey, FExpectedUid, FTi: TBytes;
    FKeys: TMifarePlusKeys;
    FModel: TMifarePlusModel;
    FMode: TMifarePlusMode;
    FKeyNumber: Word;
    FReadCounter, FWriteCounter: Integer;
    FBusy, FActive, FDispatched: Boolean;
    procedure Ready;
    procedure SetSession(const V: IMifarePlusSession);
    procedure SetProvider(const V: ICardAesProvider);
    procedure SetKey(const V: TBytes);
    procedure SetUid(const V: TBytes);
    procedure SetModel(const V: TMifarePlusModel);
    procedure SetMode(const V: TMifarePlusMode);
    procedure SetKeyNumber(const V: Word);
    function GetKey: TBytes;
    function GetUid: TBytes;
    function BeginOperation: TBytes;
    procedure Finish(const AOk: Boolean);
    procedure Authenticate;
    procedure ValidateRange(const ABlock, ACount: Integer);
    function MacInput(const AStatus: Byte; const ACounter: Integer; const ATail: TBytes): TBytes;
    function ReadNative(const ABlock, ACount: Integer): TBytes;
    procedure WriteNative(const AAddress: Word; const AData: TBytes);
  public
    /// <summary>Creates an inactive 2K/Full component without selecting a reader or key.</summary>
    /// <param name="AOwner">Optional owning component.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Clears retained static and transient secrets; constructor remains inactive.</summary>
    destructor Destroy; override;
    /// <summary>Acquires the current UID without attempting authentication.</summary>
    /// <returns>Independent fresh UID only after successful reader release.</returns>
    function ReadUid: TBytes;
    /// <summary>Reads one through fifteen ordinary blocks within the explicitly authenticated sector.</summary>
    /// <param name="ABlock">First ordinary block, excluding zero and trailers.</param>
    /// <param name="ACount">One through fifteen contiguous blocks, fitting one sector.</param>
    /// <returns>Independent complete MAC-verified data, sixteen bytes per block.</returns>
    function ReadBlocks(const ABlock, ACount: Integer): TBytes;
    /// <summary>Writes one ordinary block against an exact preimage and verifies native read-back.</summary>
    /// <param name="ABlock">Ordinary block covered by the supplied sector AES key.</param>
    /// <param name="AExpected">Exactly sixteen acquired previous data bytes.</param>
    /// <param name="AData">Exactly sixteen new data bytes; copied before I/O.</param>
    /// <exception cref="EContactlessWriteUncertain">Write dispatch, MAC, read-back or release cannot be proven complete.</exception>
    procedure WriteBlockVerified(const ABlock: Integer; const AExpected, AData: TBytes);
    /// <summary>Replaces one sector AES key with encrypted secure messaging and fresh same-card new-key proof.</summary>
    /// <param name="ATargetKey">Sector key A/B address in the currently authenticated sector.</param>
    /// <param name="ANewKey">Exactly sixteen supplied replacement bytes, frozen before I/O.</param>
    /// <param name="AAcknowledge">Explicit acknowledgement that key replacement changes credentials immediately.</param>
    /// <remarks>Uses the configured sector key as authority. Native ACLs determine permission. Original component credentials remain configured.</remarks>
    /// <exception cref="EContactlessWriteUncertain">Dispatch or subsequent fresh proof/release cannot be established.</exception>
    procedure RotateSectorKeyVerified(const ATargetKey: Word; const ANewKey: TBytes;
      const AAcknowledge: Boolean);
    /// <summary>Executes an explicit SL0 plan, commits once and proves selected keys/data through fresh SL3 sessions.</summary>
    /// <param name="AEntries">Unique sixteen-byte ordinary-block/sector-key entries and required 9000/9001/9003 keys.</param>
    /// <param name="AAcknowledge">Explicit acknowledgement of plaintext personalization and irreversible level commit.</param>
    /// <returns>Credential-free counts after every selected postcondition and release has succeeded.</returns>
    /// <remarks>Requires a nonempty ExpectedUid and an explicitly SL0 ISO14443-4 card. Data entries require a supplied same-sector key.
    /// All entries are frozen and validated before I/O. Switch key 9003 has native acknowledgement only; no SL1/SL2 or fallback.</remarks>
    /// <exception cref="EContactlessWriteUncertain">Any dispatched personalization/commit or subsequent proof cannot be established.</exception>
    function PersonalizeAndCommitSl3Verified(const AEntries: TMifarePlusPersonalizationEntries;
      const AAcknowledge: Boolean): TMifarePlusPersonalizationResult;
    /// <summary>Retained explicit native ISO14443-4 backend; immutable while busy.</summary>
    property Session: IMifarePlusSession read FSession write SetSession;
    /// <summary>Retained maintained AES/CSPRNG provider; immutable while busy.</summary>
    property CryptoProvider: ICardAesProvider read FProvider write SetProvider;
    /// <summary>Independently copied static sector AES key; empty clears it; getter returns a copy.</summary>
    property Key: TBytes read GetKey write SetKey;
    /// <summary>Optional copied four/seven/ten-byte expected UID checked before sending credentials.</summary>
    property ExpectedUid: TBytes read GetUid write SetUid;
    /// <summary>Explicit sector key address 4000 through 404F; validated against model and accessed sector.</summary>
    property KeyNumber: Word read FKeyNumber write SetKeyNumber;
    /// <summary>True throughout exclusive acquisition, protocol operations and cleanup.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Explicit physical geometry; default 2K, never auto-detected.</summary>
    property Model: TMifarePlusModel read FModel write SetModel default mpm2K;
    /// <summary>Authenticated data mode; default Full, no silent downgrade.</summary>
    property Communication: TMifarePlusMode read FMode write SetMode default mpcFull;
  end;

implementation

procedure Invalid;
begin raise EMifarePlusError.Create('Invalid Plus SL3 profile, framing or authentication.'); end;
function Joined(const A,B: TBytes): TBytes;
begin
  Result := nil; SetLength(Result,Length(A)+Length(B));
  if Length(A)>0 then Move(A[0],Result[0],Length(A));
  if Length(B)>0 then Move(B[0],Result[Length(A)],Length(B));
end;
function Rotate(const B: TBytes): TBytes;
var I: Integer;
begin
  Result := nil; SetLength(Result,Length(B)); if Length(B)=0 then Invalid;
  for I:=0 to High(B) do Result[I]:=B[(I+1) mod Length(B)];
end;
class function TMifarePlusCodec.DataSector(const AModel: TMifarePlusModel; const ABlock: Integer): Integer;
var N: Integer;
begin
  if not (AModel in [mpm2K,mpm4K]) then Invalid;
  N:=128; if AModel=mpm4K then N:=256;
  if (ABlock<1) or (ABlock>=N) then Invalid;
  if ABlock<128 then begin if ABlock mod 4=3 then Invalid; Result:=ABlock div 4; end
  else begin if (ABlock-128) mod 16=15 then Invalid; Result:=32+(ABlock-128) div 16; end;
end;
class function TMifarePlusCodec.DeriveKeys(const AProvider: ICardAesProvider;
  const AKey, ARndA, ARndB: TBytes): TMifarePlusKeys;
var V,Zero: TBytes; I: Integer;
begin
  Result:=Default(TMifarePlusKeys);
  if (AProvider=nil) or (Length(AKey)<>16) or (Length(ARndA)<>16) or (Length(ARndB)<>16) then Invalid;
  SetLength(V,16); SetLength(Zero,16);
  try
    try
    for I:=0 to 4 do begin V[I]:=ARndA[11+I]; V[5+I]:=ARndB[11+I]; V[10+I]:=ARndA[4+I] xor ARndB[4+I]; end;
    V[15]:=$11; Result.Encryption:=AProvider.EncryptCbc(AKey,Zero,V);
    for I:=0 to 4 do begin V[I]:=ARndA[7+I]; V[5+I]:=ARndB[7+I]; V[10+I]:=ARndA[I] xor ARndB[I]; end;
    V[15]:=$22; Result.Authentication:=AProvider.EncryptCbc(AKey,Zero,V);
    if (Length(Result.Encryption)<>16) or (Length(Result.Authentication)<>16) then Invalid;
    except ClearKeys(Result); raise;
    end;
  finally TCardCrypto.Clear(V); end;
end;
class function TMifarePlusCodec.DataIv(const ATi: TBytes; const AReadCounter, AWriteCounter: Integer;
  const AResponse: Boolean): TBytes;
var I,P: Integer;
begin
  if (Length(ATi)<>4) or (AReadCounter<0) or (AReadCounter>65535) or
    (AWriteCounter<0) or (AWriteCounter>65535) then Invalid;
  Result := nil; SetLength(Result,16); P:=4; if AResponse then P:=0;
  for I:=0 to 2 do begin
    Result[P+I*4]:=Byte(AReadCounter and $FF); Result[P+I*4+1]:=Byte(AReadCounter shr 8);
    Result[P+I*4+2]:=Byte(AWriteCounter and $FF); Result[P+I*4+3]:=Byte(AWriteCounter shr 8);
  end;
  P:=0; if AResponse then P:=12; Move(ATi[0],Result[P],4);
end;
class function TMifarePlusCodec.Mac(const AProvider: ICardAesProvider; const AKey, AInput: TBytes): TBytes;
var Full: TBytes; I: Integer;
begin
  Full:=TCardCrypto.Cmac(AProvider,AKey,AInput);
  try Result := nil; SetLength(Result,8); for I:=0 to 7 do Result[I]:=Full[I*2+1]; finally TCardCrypto.Clear(Full); end;
end;
class procedure TMifarePlusCodec.ClearKeys(var AKeys: TMifarePlusKeys);
begin TCardCrypto.Clear(AKeys.Encryption); TCardCrypto.Clear(AKeys.Authentication); end;
procedure TMifarePlusCardReaderWriter.Ready;
begin if FBusy then Invalid; end;
procedure TMifarePlusCardReaderWriter.SetSession(const V: IMifarePlusSession);
begin Ready; FSession:=V; end;
procedure TMifarePlusCardReaderWriter.SetProvider(const V: ICardAesProvider);
begin Ready; FProvider:=V; end;
procedure TMifarePlusCardReaderWriter.SetKey(const V: TBytes);
var B: TBytes;
begin Ready; if not (Length(V) in [0,16]) then Invalid; B:=CopyBytes(V); TCardCrypto.Clear(FKey); FKey:=B; end;
procedure TMifarePlusCardReaderWriter.SetUid(const V: TBytes);
begin Ready; if not (Length(V) in [0,4,7,10]) then Invalid; FExpectedUid:=CopyBytes(V); end;
procedure TMifarePlusCardReaderWriter.SetModel(const V: TMifarePlusModel);
begin Ready; if not (V in [mpm2K,mpm4K]) then Invalid; FModel:=V; end;
procedure TMifarePlusCardReaderWriter.SetMode(const V: TMifarePlusMode);
begin Ready; if not (V in [mpcMac,mpcFull]) then Invalid; FMode:=V; end;
procedure TMifarePlusCardReaderWriter.SetKeyNumber(const V: Word);
begin Ready; if (V<$4000) or (V>$404F) then Invalid; FKeyNumber:=V; end;
function TMifarePlusCardReaderWriter.GetKey: TBytes;
begin Result:=CopyBytes(FKey); end;
function TMifarePlusCardReaderWriter.GetUid: TBytes;
begin Result:=CopyBytes(FExpectedUid); end;
constructor TMifarePlusCardReaderWriter.Create(AOwner: TComponent);
begin inherited Create(AOwner); FMode:=mpcFull; end;
destructor TMifarePlusCardReaderWriter.Destroy;
begin TCardCrypto.Clear(FKey); TMifarePlusCodec.ClearKeys(FKeys); inherited Destroy; end;
function TMifarePlusCardReaderWriter.BeginOperation: TBytes;
begin
  Ready; if FSession=nil then Invalid; FBusy:=True; FDispatched:=False;
  try
    Result:=FSession.BeginSession; FActive:=True;
    if not (Length(Result) in [4,7,10]) or
      ((Length(FExpectedUid)>0) and not BytesEqual(Result,FExpectedUid)) then Invalid;
  except
    if FActive then try FSession.EndSession; except end;
    FActive:=False; FBusy:=False; raise;
  end;
end;
procedure TMifarePlusCardReaderWriter.Finish(const AOk: Boolean);
begin
  try
    if FActive then begin
      FActive:=False;
      if AOk then FSession.EndSession else try FSession.EndSession; except end;
    end;
  finally TMifarePlusCodec.ClearKeys(FKeys); TCardCrypto.Clear(FTi); FBusy:=False; end;
end;
procedure TMifarePlusCardReaderWriter.Authenticate;
var H,C,B,A,Zero,Plain,Expected,Capabilities: TBytes; I: Integer;
begin
  if (FProvider=nil) or (Length(FKey)<>16) or not (((FKeyNumber>=$4000) and (FKeyNumber<=$404F)) or
    (FKeyNumber=$9000) or (FKeyNumber=$9001)) then Invalid;
  H:=HexToBytes('70000000'); H[1]:=Byte(FKeyNumber and $FF); H[2]:=Byte(FKeyNumber shr 8);
  C:=nil; B:=nil; A:=nil; Plain:=nil; Expected:=nil; SetLength(Zero,16);
  try
    C:=FSession.ExchangeNative(H); if (Length(C)<>17) or (C[0]<>$90) then Invalid;
    B:=FProvider.DecryptCbc(FKey,Zero,Copy(C,1,16)); if Length(B)<>16 then Invalid;
    A:=FProvider.RandomBytes(16); if Length(A)<>16 then Invalid;
    Plain:=Joined(A,Rotate(B)); C:=FProvider.EncryptCbc(FKey,Zero,Plain);
    H:=HexToBytes('72'); H:=Joined(H,C); C:=FSession.ExchangeNative(H);
    if (Length(C)<>33) or (C[0]<>$90) then Invalid;
    TCardCrypto.Clear(Plain); Plain:=FProvider.DecryptCbc(FKey,Zero,Copy(C,1,32));
    if Length(Plain)<>32 then Invalid;
    Expected:=Rotate(A); if not TCardCrypto.EqualSecret(Expected,Copy(Plain,4,16)) then Invalid;
    for I:=26 to 31 do if Plain[I]<>0 then Invalid;
    Capabilities:=Copy(Plain,20,6); // Retained only within authentication; no EV2/LRP fallback.
    if Length(Capabilities)<>6 then Invalid;
    FTi:=Copy(Plain,0,4); FReadCounter:=0; FWriteCounter:=0;
    FKeys:=TMifarePlusCodec.DeriveKeys(FProvider,FKey,A,B);
  finally
    TCardCrypto.Clear(H); TCardCrypto.Clear(C); TCardCrypto.Clear(B); TCardCrypto.Clear(A);
    TCardCrypto.Clear(Plain); TCardCrypto.Clear(Expected);
  end;
end;
procedure TMifarePlusCardReaderWriter.ValidateRange(const ABlock, ACount: Integer);
var S,I: Integer;
begin
  S:=TMifarePlusCodec.DataSector(FModel,ABlock);
  if (ACount<1) or (ACount>15) or (ABlock>255-ACount+1) or
    (FKeyNumber<$4000) or (FKeyNumber>$404F) or ((FKeyNumber-$4000) div 2<>S) then Invalid;
  for I:=1 to ACount-1 do if TMifarePlusCodec.DataSector(FModel,ABlock+I)<>S then Invalid;
end;
function TMifarePlusCardReaderWriter.MacInput(const AStatus: Byte; const ACounter: Integer; const ATail: TBytes): TBytes;
begin
  if (ACounter<0) or (ACounter>65535) then Invalid;
  Result := nil; SetLength(Result,7); Result[0]:=AStatus; Result[1]:=Byte(ACounter and $FF); Result[2]:=Byte(ACounter shr 8);
  Move(FTi[0],Result[3],4); Result:=Joined(Result,ATail);
end;
function TMifarePlusCardReaderWriter.ReadNative(const ABlock, ACount: Integer): TBytes;
var H,Packet,R,Expected,Tail,Data,Iv: TBytes;
begin
  if FReadCounter>=65535 then Invalid;
  H:=HexToBytes('31000000'); if FMode=mpcMac then H[0]:=$33;
  H[1]:=Byte(ABlock); H[3]:=Byte(ACount);
  Expected:=TMifarePlusCodec.Mac(FProvider,FKeys.Authentication,MacInput(H[0],FReadCounter,Copy(H,1,3)));
  Packet:=Joined(H,Expected); R:=FSession.ExchangeNative(Packet); Inc(FReadCounter);
  if (Length(R)<>1+ACount*16+8) or (R[0]<>$90) then Invalid;
  Data:=Copy(R,1,ACount*16); Tail:=Joined(Copy(H,1,3),Data);
  Expected:=TMifarePlusCodec.Mac(FProvider,FKeys.Authentication,MacInput($90,FReadCounter,Tail));
  if not TCardCrypto.EqualSecret(Expected,Copy(R,1+ACount*16,8)) then Invalid;
  if FMode=mpcFull then begin
    Iv:=TMifarePlusCodec.DataIv(FTi,FReadCounter,FWriteCounter,True);
    Result:=FProvider.DecryptCbc(FKeys.Encryption,Iv,Data);
  end else Result:=CopyBytes(Data);
  if Length(Result)<>ACount*16 then Invalid;
end;
procedure TMifarePlusCardReaderWriter.WriteNative(const AAddress: Word; const AData: TBytes);
var H,Data,Iv,Expected,R: TBytes;
begin
  if FWriteCounter>=65535 then Invalid;
  H:=HexToBytes('A10000'); if FMode=mpcMac then H[0]:=$A3;
  H[1]:=Byte(AAddress and $FF); H[2]:=Byte(AAddress shr 8);
  Data:=CopyBytes(AData);
  try
    if FMode=mpcFull then begin
      Iv:=TMifarePlusCodec.DataIv(FTi,FReadCounter,FWriteCounter,False);
      Data:=FProvider.EncryptCbc(FKeys.Encryption,Iv,AData);
      if Length(Data)<>16 then Invalid;
    end;
    H:=Joined(H,Data);
    Expected:=TMifarePlusCodec.Mac(FProvider,FKeys.Authentication,MacInput(H[0],FWriteCounter,Copy(H,1,Length(H)-1)));
    H:=Joined(H,Expected); FDispatched:=True;
    R:=FSession.ExchangeNative(H); Inc(FWriteCounter);
    if (Length(R)<>9) or (R[0]<>$90) then Invalid;
    Expected:=TMifarePlusCodec.Mac(FProvider,FKeys.Authentication,MacInput($90,FWriteCounter,nil));
    if not TCardCrypto.EqualSecret(Expected,Copy(R,1,8)) then Invalid;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(H); end;
end;
function TMifarePlusCardReaderWriter.ReadUid: TBytes;
var Ok: Boolean;
begin
  Result:=BeginOperation; Ok:=False;
  try Ok:=True; finally Finish(Ok); end;
end;
function TMifarePlusCardReaderWriter.ReadBlocks(const ABlock, ACount: Integer): TBytes;
var Ok: Boolean;
begin
  Ready; ValidateRange(ABlock,ACount);
  if (FProvider=nil) or (Length(FKey)<>16) then Invalid;
  BeginOperation; Ok:=False;
  try Authenticate; Result:=ReadNative(ABlock,ACount); Ok:=True; finally Finish(Ok); end;
end;
procedure TMifarePlusCardReaderWriter.WriteBlockVerified(const ABlock: Integer; const AExpected, AData: TBytes);
var Old,NewData,B: TBytes; Ok: Boolean;
begin
  Ready; ValidateRange(ABlock,1);
  if (Length(AExpected)<>16) or (Length(AData)<>16) or (Length(FKey)<>16) or (FProvider=nil) then Invalid;
  Old:=CopyBytes(AExpected); NewData:=CopyBytes(AData); Ok:=False;
  try
    BeginOperation;
    try
      try
        Authenticate; B:=ReadNative(ABlock,1); if not BytesEqual(B,Old) then Invalid;
        if not BytesEqual(Old,NewData) then begin
          WriteNative(ABlock,NewData); B:=ReadNative(ABlock,1);
          if not BytesEqual(B,NewData) then Invalid;
        end;
        Ok:=True;
      finally Finish(Ok); end;
    except on E: Exception do begin if FDispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally TCardCrypto.Clear(Old); TCardCrypto.Clear(NewData); end;
end;

procedure TMifarePlusCardReaderWriter.RotateSectorKeyVerified(const ATargetKey: Word;
  const ANewKey: TBytes; const AAcknowledge: Boolean);
var
  NewKey, SavedKey, SavedUid, Uid: TBytes;
  SavedNumber: Word;
  SavedMode: TMifarePlusMode;
  Ok, Mutation: Boolean;
  SectorCount: Integer;
begin
  Ready;
  SectorCount := 32;
  if FModel = mpm4K then
    SectorCount := 40;
  if not AAcknowledge or (Length(ANewKey) <> 16) or (Length(FKey) <> 16) or
    (FProvider = nil) or (ATargetKey < $4000) or (ATargetKey >= $4000 + SectorCount * 2) or
    (FKeyNumber < $4000) or (FKeyNumber >= $4000 + SectorCount * 2) or
    ((ATargetKey - $4000) div 2 <> (FKeyNumber - $4000) div 2) then
    Invalid;
  NewKey := CopyBytes(ANewKey);
  SavedKey := FKey;
  FKey := CopyBytes(SavedKey);
  SavedNumber := FKeyNumber;
  SavedMode := FMode;
  SavedUid := FExpectedUid;
  Ok := False;
  Mutation := False;
  try
    try
      Uid := BeginOperation;
      FExpectedUid := CopyBytes(Uid);
      try
        Authenticate;
        FMode := mpcFull;
        try
          WriteNative(ATargetKey, NewKey);
        finally
          Mutation := FDispatched;
        end;
        Ok := True;
      finally
        Finish(Ok);
      end;
      TCardCrypto.Clear(FKey);
      FKey := CopyBytes(NewKey);
      FKeyNumber := ATargetKey;
      BeginOperation;
      Ok := False;
      try
        Authenticate;
        Ok := True;
      finally
        Finish(Ok);
      end;
    except
      on E: Exception do
      begin
        if Mutation then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(FKey);
    TCardCrypto.Clear(NewKey);
    FKey := SavedKey;
    FKeyNumber := SavedNumber;
    FMode := SavedMode;
    FExpectedUid := SavedUid;
  end;
end;

function TMifarePlusCardReaderWriter.PersonalizeAndCommitSl3Verified(
  const AEntries: TMifarePlusPersonalizationEntries;
  const AAcknowledge: Boolean): TMifarePlusPersonalizationResult;
var
  Entries: TMifarePlusPersonalizationEntries;
  SavedKey, Packet, Response, Data: TBytes;
  SavedNumber: Word;
  SavedMode: TMifarePlusMode;
  I, J, Sector, SectorCount, KeyIndex, Master, Config, SwitchKey: Integer;
  Ok, Mutation: Boolean;
  procedure SelectKey(const AIndex: Integer);
  begin
    TCardCrypto.Clear(FKey);
    FKey := CopyBytes(Entries[AIndex].Data);
    FKeyNumber := Entries[AIndex].Address;
  end;
  procedure Ack(const B: TBytes);
  begin
    Mutation := True;
    Response := FSession.ExchangeNative(B);
    if (Length(Response) <> 1) or (Response[0] <> $90) then
      Invalid;
  end;
begin
  Result.AcknowledgedEntries := 0;
  Result.VerifiedKeys := 0;
  Result.VerifiedBlocks := 0;
  Result.Sl3Verified := False;
  Ready;
  if not AAcknowledge or (FProvider = nil) or (Length(FExpectedUid) = 0) or
    (Length(AEntries) < 4) or (Length(AEntries) > 339) then
    Invalid;
  Entries := nil;
  SetLength(Entries, Length(AEntries));
  SavedKey := nil;
  Master := -1;
  Config := -1;
  SwitchKey := -1;
  Mutation := False;
  try
    // Freeze the complete caller plan before reader or provider callbacks.
    for I := 0 to High(Entries) do
    begin
      Entries[I].Address := AEntries[I].Address;
      Entries[I].Data := CopyBytes(AEntries[I].Data);
    end;
    SectorCount := 32;
    if FModel = mpm4K then
      SectorCount := 40;
    for I := 0 to High(Entries) do
    begin
      if Length(Entries[I].Data) <> 16 then
        Invalid;
      for J := 0 to I - 1 do
        if Entries[J].Address = Entries[I].Address then
          Invalid;
      case Entries[I].Address of
        $9000: Master := I;
        $9001: Config := I;
        $9003: SwitchKey := I;
      else
        if (Entries[I].Address >= $4000) and
          (Entries[I].Address < $4000 + SectorCount * 2) then
          Continue;
        Sector := TMifarePlusCodec.DataSector(FModel, Entries[I].Address);
        KeyIndex := -1;
        for J := 0 to High(Entries) do
          if (Entries[J].Address >= $4000) and
            (Entries[J].Address < $4000 + SectorCount * 2) and
            ((Entries[J].Address - $4000) div 2 = Sector) then
            KeyIndex := J;
        if KeyIndex < 0 then
          Invalid;
      end;
    end;
    if (Master < 0) or (Config < 0) or (SwitchKey < 0) then
      Invalid;
    KeyIndex := -1;
    for I := 0 to High(Entries) do
      if (Entries[I].Address >= $4000) and
        (Entries[I].Address < $4000 + SectorCount * 2) then
        KeyIndex := I;
    if KeyIndex < 0 then
      Invalid;
    SavedKey := FKey;
    FKey := nil;
    SavedNumber := FKeyNumber;
    SavedMode := FMode;
    FMode := mpcFull;
    try
      try
        BeginOperation;
        Ok := False;
        try
          for I := 0 to High(Entries) do
          begin
            Packet := HexToBytes('A80000');
            Packet[1] := Byte(Entries[I].Address and $FF);
            Packet[2] := Byte(Entries[I].Address shr 8);
            Packet := Joined(Packet, Entries[I].Data);
            try
              Ack(Packet);
            finally
              TCardCrypto.Clear(Packet);
            end;
            Inc(Result.AcknowledgedEntries);
          end;
          Ack(HexToBytes('AA'));
          Ok := True;
        finally
          Finish(Ok);
        end;
        // Prove SL3 with a selected sector key before authenticating management keys.
        SelectKey(KeyIndex);
        BeginOperation;
        Ok := False;
        try
          Authenticate;
          Ok := True;
        finally
          Finish(Ok);
        end;
        for I := 0 to High(Entries) do
        begin
          if Entries[I].Address = $9003 then
            Continue; // No invented read-back or switching-key proof.
          if Entries[I].Address >= $4000 then
            SelectKey(I)
          else
          begin
            Sector := TMifarePlusCodec.DataSector(FModel, Entries[I].Address);
            KeyIndex := -1;
            for J := 0 to High(Entries) do
              if (Entries[J].Address >= $4000) and
                (Entries[J].Address < $4000 + SectorCount * 2) and
                ((Entries[J].Address - $4000) div 2 = Sector) then
                KeyIndex := J;
            SelectKey(KeyIndex);
          end;
          BeginOperation;
          Ok := False;
          try
            Authenticate;
            if Entries[I].Address < $4000 then
            begin
              Data := ReadNative(Entries[I].Address, 1);
              if not BytesEqual(Data, Entries[I].Data) then
                Invalid;
              Inc(Result.VerifiedBlocks);
            end
            else
              Inc(Result.VerifiedKeys);
            Ok := True;
          finally
            TCardCrypto.Clear(Data);
            Finish(Ok);
          end;
        end;
        Result.Sl3Verified := True;
      except
        on E: Exception do
        begin
          if Mutation then
            raise EContactlessWriteUncertain.Create(E.ClassName);
          raise;
        end;
      end;
    finally
      TCardCrypto.Clear(FKey);
      FKey := SavedKey;
      FKeyNumber := SavedNumber;
      FMode := SavedMode;
    end;
  finally
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(Response);
    for I := 0 to High(Entries) do
      TCardCrypto.Clear(Entries[I].Data);
  end;
end;

end.
