unit ERD.Card.Contactless.Plus.SL2;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Transport, ERD.Card.Contactless,
  ERD.Card.Contactless.Plus, ERD.Card.Contactless.Classic.Access;
type
  /// <summary>Explicit SL2 RF backend combining native Type A AES and reader-owned Crypto1 in the same acquisition.</summary>
  IMifarePlusSl2Session = interface
    ['{CF843D5F-F79C-4D50-842F-75FA420492F6}']
    /// <summary>Acquires/selects one card with automatic RATS disabled; failed acquisition releases ownership.</summary>
    /// <returns>Independent selected four/seven-byte UID.</returns>
    function BeginSession: TBytes;
    /// <summary>Exchanges one CRC-checked native AES command without RF reset or replay.</summary>
    /// <param name="ACommand">Status-first native Plus authentication command.</param>
    /// <returns>Owned status-first native reply without CRC.</returns>
    function ExchangeNative(const ACommand: TBytes): TBytes;
    /// <summary>Authenticates Crypto1 using a supplied already modified sector key without reselecting the card.</summary>
    /// <param name="ABlock">Physical sector block.</param>
    /// <param name="AKeyType">Explicit Classic key A or B.</param>
    /// <param name="AModifiedKey">Exactly six temporary bytes; backend never retains them.</param>
    procedure AuthenticateClassic(const ABlock: Byte; const AKeyType: TMifareClassicKeyType; const AModifiedKey: TBytes);
    /// <summary>Reads exactly sixteen Crypto1-protected block bytes on the existing RF session.</summary>
    /// <param name="ABlock">Physical block, including explicitly requested trailer.</param>
    /// <returns>Owned complete block.</returns>
    function ReadBlock(const ABlock: Byte): TBytes;
    /// <summary>Writes one Crypto1 block once; failures after submission must remain uncertain.</summary>
    /// <param name="ABlock">Explicit physical data/trailer block.</param>
    /// <param name="AData">Exactly sixteen supplied bytes.</param>
    procedure WriteBlock(const ABlock: Byte; const AData: TBytes);
    /// <summary>Releases RF/native ownership and restores framing even after an error.</summary>
    procedure EndSession;
  end;
  /// <summary>Verified explicit trailer policy/key programming evidence without returned secret keys.</summary>
  TMifarePlusSl2TrailerResult = record
    /// <summary>Observed trailer bytes; unreadable keys remain masked by the card.</summary>
    VisibleTrailer: TBytes;
    /// <summary>Fresh modified-key Crypto1 proof using the supplied new key A.</summary>
    KeyAVerified: Boolean;
    /// <summary>Fresh new-key B proof; false when B is configured as readable data instead.</summary>
    KeyBVerified: Boolean;
    /// <summary>True when B is readable data and its exact supplied value was independently read back.</summary>
    KeyBReadBackVerified: Boolean;
  end;
  /// <summary>Pure SL2 modifier, sector geometry and Classic access-policy helpers.</summary>
  TMifarePlusSl2Codec = class
  public
    /// <summary>Derives the six-byte AES sector modifier from independently supplied sixteen-byte nonces.</summary>
    /// <param name="AProvider">Maintained AES provider.</param>
    /// <param name="AKey">Sixteen-byte supplied sector AES key.</param>
    /// <param name="ARndA">Fresh sixteen-byte reader nonce.</param>
    /// <param name="ARndB">Proved sixteen-byte card nonce.</param>
    /// <returns>First six bytes of AES of A[11..15], B[11..15], A[4..8] xor B[4..8], 33.</returns>
    class function Modifier(const AProvider: ICardAesProvider; const AKey, ARndA, ARndB: TBytes): TBytes; static;
    /// <summary>XORs an explicit six-byte Classic sector key with its six-byte session modifier.</summary>
    /// <param name="AKey">Caller-supplied static Classic key.</param>
    /// <param name="AModifier">Derived temporary modifier.</param>
    /// <returns>Owned six-byte temporary authentication key.</returns>
    class function ModifiedKey(const AKey, AModifier: TBytes): TBytes; static;
    /// <summary>Returns the exact trailer block for one explicit 2K/4K sector.</summary>
    /// <param name="AModel">Explicit geometry.</param>
    /// <param name="ASector">Zero through thirty-one or thirty-nine.</param>
    /// <returns>Physical trailer byte address.</returns>
    class function Trailer(const AModel: TMifarePlusModel; const ASector: Integer): Byte; static;
    /// <summary>Checks read/write permission from all complemented Classic access bits.</summary>
    /// <param name="ATrailer">Sixteen observed visible bytes.</param>
    /// <param name="AGroup">Data group zero through two.</param>
    /// <param name="AKeyType">Explicit authenticated key.</param>
    /// <param name="AWriting">True requires both read and write for verified writing.</param>
    class procedure CheckDataAccess(const ATrailer: TBytes; const AGroup: Integer;
      const AKeyType: TMifareClassicKeyType; const AWriting: Boolean); static;
  end;
  /// <summary>Inactive explicit Plus SL2 reader/writer; AES nonce proof precedes modified-key Crypto1 data access.</summary>
  /// <remarks>Requires supplied sector AES and Classic credentials. Never infers levels, tries keys or transitions to SL3.</remarks>
  TMifarePlusSl2ReaderWriter = class(TComponent)
  private
    FSession: IMifarePlusSl2Session;
    FProvider: ICardAesProvider;
    FKey,FClassicKey,FUid: TBytes;
    FKeyNumber: Word;
    FKeyType: TMifareClassicKeyType;
    FModel: TMifarePlusModel;
    FBusy: Boolean;
    procedure Ready;
    procedure SetSession(const Value: IMifarePlusSl2Session);
    procedure SetProvider(const Value: ICardAesProvider);
    procedure SetKey(const Value: TBytes);
    procedure SetClassicKey(const Value: TBytes);
    procedure SetUid(const Value: TBytes);
    procedure SetNumber(const Value: Word);
    procedure SetType(const Value: TMifareClassicKeyType);
    procedure SetModel(const Value: TMifarePlusModel);
    function GetKey: TBytes;
    function GetClassicKey: TBytes;
    function GetUid: TBytes;
    procedure Authenticate(const ABlock: Byte; const AClassicKey: TBytes; const AType: TMifareClassicKeyType);
    function ReadRange(const ABlock: Integer; const AWriting: Boolean): TBytes;
    function ProofTrailer(const ASector: Integer; const AKey: TBytes; const AType: TMifareClassicKeyType): TBytes;
  public
    /// <summary>Creates an inactive 2K profile with explicit key A and native sector address 4000.</summary>
    /// <param name="AOwner">Optional owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Clears copied static keys and releases retained adapters.</summary>
    destructor Destroy; override;
    /// <summary>Acquires/pins fresh RF UID without attempting authentication.</summary>
    /// <returns>Owned UID only after successful release.</returns>
    function ReadUid: TBytes;
    /// <summary>Reads one ordinary block after AES and Crypto1 proof and access-bit validation.</summary>
    /// <param name="ABlock">Ordinary non-manufacturer block in the configured sector.</param>
    /// <returns>Sixteen owned Crypto1-protected bytes after successful release.</returns>
    function ReadBlock(const ABlock: Integer): TBytes;
    /// <summary>Checks full data preimage and live access bits, writes once and verifies same-session read-back.</summary>
    /// <param name="ABlock">Ordinary physical block matching KeyNumber.</param>
    /// <param name="AExpected">Sixteen acquired previous bytes.</param>
    /// <param name="AData">Sixteen desired bytes, copied before dispatch.</param>
    /// <exception cref="EContactlessWriteUncertain">Dispatched write, read-back or release cannot be established.</exception>
    procedure WriteBlockVerified(const ABlock: Integer; const AExpected,AData: TBytes);
    /// <summary>Reads visible sector trailer/access/GPB data; unreadable key bytes are never invented.</summary>
    /// <param name="ASector">Exact configured sector.</param>
    /// <returns>Sixteen observed visible bytes; masked keys are not a credential backup.</returns>
    function ReadSectorTrailer(const ASector: Integer): TBytes;
    /// <summary>Programs an explicitly supplied complete trailer and proves policy plus new keys through fresh same-card sessions.</summary>
    /// <param name="ASector">Exact configured sector.</param>
    /// <param name="AExpectedVisible">Sixteen observed old trailer bytes; masked secrets are not inferred.</param>
    /// <param name="ANewTrailer">Sixteen explicit key A/access/GPB/key B bytes, copied and cleared after use.</param>
    /// <param name="AAcknowledge">Must be true for credential/access changes, including potential loss of old access.</param>
    /// <returns>Visible policy plus fresh A/B proof or readable B data verification after successful release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Dispatch, fresh key proof, policy read-back or release fails; no rollback or retry.</exception>
    function WriteSectorTrailerVerified(const ASector: Integer; const AExpectedVisible, ANewTrailer: TBytes;
      const AAcknowledge: Boolean): TMifarePlusSl2TrailerResult;
    /// <summary>Explicit native SL2/Crypto1 backend with continuous RF ownership.</summary>
    property Session: IMifarePlusSl2Session read FSession write SetSession;
    /// <summary>Maintained AES/CSPRNG provider.</summary>
    property CryptoProvider: ICardAesProvider read FProvider write SetProvider;
    /// <summary>Copied sixteen-byte static AES sector key; getter returns an independent secret.</summary>
    property Key: TBytes read GetKey write SetKey;
    /// <summary>Copied six-byte supplied Classic key; never copied from trailer read-back.</summary>
    property ClassicKey: TBytes read GetClassicKey write SetClassicKey;
    /// <summary>Required pinned four/seven-byte UID for authenticated operations.</summary>
    property ExpectedUid: TBytes read GetUid write SetUid;
    /// <summary>True across complete acquisition, proof, data and cleanup.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Explicit 2K/4K geometry, default 2K.</summary>
    property Model: TMifarePlusModel read FModel write SetModel default mpm2K;
    /// <summary>Explicit AES sector slot 4000..404F, matching the requested sector.</summary>
    property KeyNumber: Word read FKeyNumber write SetNumber default $4000;
    /// <summary>Explicit Classic key A/B for the same sector; default A.</summary>
    property KeyType: TMifareClassicKeyType read FKeyType write SetType default mckA;
  end;
/// <summary>Creates a lazy dedicated ACR122/PN532 SL2 backend sharing raw AES and hardware Crypto1 in one transaction.</summary>
/// <param name="ATransport">Connected PICC transport with ICardTransaction and FF00 direct-transmit support.</param>
/// <param name="ATimeoutCode">Explicit PN532 timeout 01..10 hex, default 0D.</param>
/// <returns>Retained inactive backend; fresh selection, CRC checks and RF/framing restoration.</returns>
function CreateAcr122PlusSl2Session(const ATransport: ICardTransport; const ATimeoutCode: Byte = $0D): IMifarePlusSl2Session;
implementation
uses ERD.Card.APDU, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Plus.ACR122;
type
  TBackend = class(TInterfacedObject, IMifarePlusSl2Session)
    Transport: ICardTransport;
    Raw: IRawContactlessReader;
    Uid: TBytes;
    Active, Classic: Boolean;
    function Send(const Data: TBytes; const Count: Integer): TBytes;
    function BeginSession: TBytes;
    function ExchangeNative(const ACommand: TBytes): TBytes;
    procedure AuthenticateClassic(const ABlock: Byte; const AKeyType: TMifareClassicKeyType; const AModifiedKey: TBytes);
    function ReadBlock(const ABlock: Byte): TBytes;
    procedure WriteBlock(const ABlock: Byte; const AData: TBytes);
    procedure EndSession;
    destructor Destroy; override;
  end;
procedure Invalid;
begin raise EMifarePlusError.Create('Invalid explicit Plus SL2 profile or response.'); end;
class function TMifarePlusSl2Codec.Modifier(const AProvider: ICardAesProvider; const AKey, ARndA, ARndB: TBytes): TBytes;
var Input,Zero,Encrypted: TBytes; I: Integer;
begin
  Result := nil;
  if (AProvider=nil) or (Length(AKey)<>16) or (Length(ARndA)<>16) or (Length(ARndB)<>16) then Invalid;
  SetLength(Input,16); SetLength(Zero,16);
  try
    Move(ARndA[11],Input[0],5); Move(ARndB[11],Input[5],5);
    for I := 0 to 4 do Input[10+I] := ARndA[4+I] xor ARndB[4+I]; Input[15] := $33;
    Encrypted := AProvider.EncryptCbc(AKey,Zero,Input); if Length(Encrypted)<>16 then Invalid;
    Result := Copy(Encrypted,0,6);
  finally TCardCrypto.Clear(Input); TCardCrypto.Clear(Encrypted); TCardCrypto.Clear(Zero); end;
end;
class function TMifarePlusSl2Codec.ModifiedKey(const AKey, AModifier: TBytes): TBytes;
var I: Integer;
begin
  if (Length(AKey)<>6) or (Length(AModifier)<>6) then Invalid;
  Result := nil; SetLength(Result,6); for I := 0 to 5 do Result[I] := AKey[I] xor AModifier[I];
end;
class function TMifarePlusSl2Codec.Trailer(const AModel: TMifarePlusModel; const ASector: Integer): Byte;
begin
  if not (AModel in [mpm2K,mpm4K]) or (ASector<0) or (ASector>39) or ((AModel=mpm2K) and (ASector>31)) then Invalid;
  if ASector<32 then Result := Byte(ASector*4+3) else Result := Byte(128+(ASector-32)*16+15);
end;
class procedure TMifarePlusSl2Codec.CheckDataAccess(const ATrailer: TBytes; const AGroup: Integer;
  const AKeyType: TMifareClassicKeyType; const AWriting: Boolean);
var Conditions: TClassicAccessConditions; Readable,Writable: Boolean; C: Byte;
begin
  if (Length(ATrailer)<>16) or (AGroup<0) or (AGroup>2) or not (AKeyType in [mckA,mckB]) then Invalid;
  Conditions := TClassicAccessCodec.Decode(Copy(ATrailer,6,3));
  if (AKeyType=mckB) and TClassicAccessCodec.KeyBReadable(Conditions[3]) then Invalid;
  C := Conditions[AGroup]; Readable := C in [0,1,2,4,6];
  if AKeyType=mckB then Readable := Readable or (C in [3,5]);
  Writable := (C=0) or ((AKeyType=mckB) and (C in [3,4,6]));
  if not Readable or (AWriting and not Writable) then Invalid;
end;
constructor TMifarePlusSl2ReaderWriter.Create(AOwner: TComponent);
begin inherited Create(AOwner); FKeyNumber := $4000; end;
destructor TMifarePlusSl2ReaderWriter.Destroy;
begin TCardCrypto.Clear(FKey); TCardCrypto.Clear(FClassicKey); inherited Destroy; end;
procedure TMifarePlusSl2ReaderWriter.Ready;
begin if FBusy then Invalid; end;
procedure TMifarePlusSl2ReaderWriter.SetSession(const Value: IMifarePlusSl2Session);
begin Ready; FSession := Value; end;
procedure TMifarePlusSl2ReaderWriter.SetProvider(const Value: ICardAesProvider);
begin Ready; FProvider := Value; end;
procedure TMifarePlusSl2ReaderWriter.SetKey(const Value: TBytes);
var CopyKey: TBytes;
begin Ready; if not (Length(Value) in [0,16]) then Invalid; CopyKey := CopyBytes(Value); TCardCrypto.Clear(FKey); FKey := CopyKey; end;
procedure TMifarePlusSl2ReaderWriter.SetClassicKey(const Value: TBytes);
var CopyKey: TBytes;
begin Ready; if not (Length(Value) in [0,6]) then Invalid; CopyKey := CopyBytes(Value); TCardCrypto.Clear(FClassicKey); FClassicKey := CopyKey; end;
procedure TMifarePlusSl2ReaderWriter.SetUid(const Value: TBytes);
begin Ready; if not (Length(Value) in [0,4,7]) then Invalid; FUid := CopyBytes(Value); end;
procedure TMifarePlusSl2ReaderWriter.SetNumber(const Value: Word);
begin Ready; if (Value<$4000) or (Value>$404F) then Invalid; FKeyNumber := Value; end;
procedure TMifarePlusSl2ReaderWriter.SetType(const Value: TMifareClassicKeyType);
begin Ready; if not (Value in [mckA,mckB]) then Invalid; FKeyType := Value; end;
procedure TMifarePlusSl2ReaderWriter.SetModel(const Value: TMifarePlusModel);
begin Ready; if not (Value in [mpm2K,mpm4K]) then Invalid; FModel := Value; end;
function TMifarePlusSl2ReaderWriter.GetKey: TBytes;
begin Result := CopyBytes(FKey); end;
function TMifarePlusSl2ReaderWriter.GetClassicKey: TBytes;
begin Result := CopyBytes(FClassicKey); end;
function TMifarePlusSl2ReaderWriter.GetUid: TBytes;
begin Result := CopyBytes(FUid); end;
procedure TMifarePlusSl2ReaderWriter.Authenticate(const ABlock: Byte; const AClassicKey: TBytes; const AType: TMifareClassicKeyType);
var Reply,Zero,A,B,Plain,Packet,Expected,Modifier,Key: TBytes; I: Integer;
begin
  SetLength(Zero,16);
  try
    Packet := HexToBytes('70000000'); Packet[1] := Byte(FKeyNumber and $FF); Packet[2] := Byte(FKeyNumber shr 8);
    Reply := FSession.ExchangeNative(Packet); if (Length(Reply)<>17) or (Reply[0]<>$90) then Invalid;
    B := FProvider.DecryptCbc(FKey,Zero,Copy(Reply,1,16)); if Length(B)<>16 then Invalid;
    A := FProvider.RandomBytes(16); if Length(A)<>16 then Invalid;
    SetLength(Plain,32); Move(A[0],Plain[0],16); for I := 0 to 15 do Plain[16+I] := B[(I+1) mod 16];
    Reply := FProvider.EncryptCbc(FKey,Zero,Plain); if Length(Reply)<>32 then Invalid;
    SetLength(Packet,33); Packet[0] := $72; Move(Reply[0],Packet[1],32);
    Reply := FSession.ExchangeNative(Packet); if (Length(Reply)<>33) or (Reply[0]<>$90) then Invalid;
    TCardCrypto.Clear(Plain); Plain := FProvider.DecryptCbc(FKey,Zero,Copy(Reply,1,32)); if Length(Plain)<>32 then Invalid;
    SetLength(Expected,16); for I := 0 to 15 do Expected[I] := A[(I+1) mod 16];
    if not TCardCrypto.EqualSecret(Expected,Copy(Plain,4,16)) then Invalid;
    for I := 26 to 31 do if Plain[I]<>0 then Invalid;
    Modifier := TMifarePlusSl2Codec.Modifier(FProvider,FKey,A,B);
    Key := TMifarePlusSl2Codec.ModifiedKey(AClassicKey,Modifier); FSession.AuthenticateClassic(ABlock,AType,Key);
  finally
    TCardCrypto.Clear(Reply); TCardCrypto.Clear(Zero); TCardCrypto.Clear(A); TCardCrypto.Clear(B);
    TCardCrypto.Clear(Plain); TCardCrypto.Clear(Packet); TCardCrypto.Clear(Expected); TCardCrypto.Clear(Modifier); TCardCrypto.Clear(Key);
  end;
end;
function TMifarePlusSl2ReaderWriter.ReadUid: TBytes;
var Ok: Boolean;
begin
  Ready; if FSession=nil then Invalid; FBusy := True; Ok := False;
  try
    Result := FSession.BeginSession;
    try
      if not (Length(Result) in [4,7]) or ((Length(FUid)>0) and not BytesEqual(FUid,Result)) then Invalid;
      Ok := True;
    finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
  finally FBusy := False; end;
end;
function TMifarePlusSl2ReaderWriter.ReadRange(const ABlock: Integer; const AWriting: Boolean): TBytes;
var Sector,Group: Integer; Trailer: TBytes;
begin
  Sector := TMifarePlusCodec.DataSector(FModel,ABlock);
  if ((FKeyNumber-$4000) div 2<>Sector) then Invalid;
  Trailer := FSession.ReadBlock(TMifarePlusSl2Codec.Trailer(FModel,Sector));
  Group := ABlock mod 4; if Sector>=32 then Group := (ABlock mod 16) div 5;
  TMifarePlusSl2Codec.CheckDataAccess(Trailer,Group,FKeyType,AWriting);
  Result := FSession.ReadBlock(Byte(ABlock)); if Length(Result)<>16 then Invalid;
end;
function TMifarePlusSl2ReaderWriter.ReadBlock(const ABlock: Integer): TBytes;
var Uid: TBytes; Sector: Integer; Ok: Boolean;
begin
  Ready; Sector := TMifarePlusCodec.DataSector(FModel,ABlock);
  if (FSession=nil) or (FProvider=nil) or (Length(FKey)<>16) or (Length(FClassicKey)<>6) or
    not (Length(FUid) in [4,7]) or ((FKeyNumber-$4000) div 2<>Sector) then Invalid;
  FBusy := True; Ok := False;
  try
    Uid := FSession.BeginSession;
    try
      if not BytesEqual(Uid,FUid) then Invalid;
      Authenticate(Byte(ABlock),FClassicKey,FKeyType); Result := ReadRange(ABlock,False); Ok := True;
    finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
  finally FBusy := False; end;
end;
procedure TMifarePlusSl2ReaderWriter.WriteBlockVerified(const ABlock: Integer; const AExpected,AData: TBytes);
var Expected,Desired,Uid,Actual: TBytes; Sector: Integer; Ok,Dispatched: Boolean;
begin
  Ready; Sector := TMifarePlusCodec.DataSector(FModel,ABlock);
  if (FSession=nil) or (FProvider=nil) or (Length(FKey)<>16) or (Length(FClassicKey)<>6) or
    not (Length(FUid) in [4,7]) or ((FKeyNumber-$4000) div 2<>Sector) or (Length(AExpected)<>16) or (Length(AData)<>16) then Invalid;
  Expected := CopyBytes(AExpected); Desired := CopyBytes(AData); FBusy := True; Ok := False; Dispatched := False;
  try
    try
      Uid := FSession.BeginSession;
      try
        if not BytesEqual(Uid,FUid) then Invalid;
        Authenticate(Byte(ABlock),FClassicKey,FKeyType); Actual := ReadRange(ABlock,True);
        if not BytesEqual(Actual,Expected) then Invalid;
        if not BytesEqual(Expected,Desired) then begin
          Dispatched := True; FSession.WriteBlock(Byte(ABlock),Desired); Actual := FSession.ReadBlock(Byte(ABlock));
          if not BytesEqual(Actual,Desired) then Invalid;
        end;
        Ok := True;
      finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
    except on E: Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally TCardCrypto.Clear(Expected); TCardCrypto.Clear(Desired); TCardCrypto.Clear(Actual); FBusy := False; end;
end;
function TMifarePlusSl2ReaderWriter.ReadSectorTrailer(const ASector: Integer): TBytes;
var Block: Byte; Uid: TBytes; Ok: Boolean; Conditions: TClassicAccessConditions;
begin
  Ready; Block := TMifarePlusSl2Codec.Trailer(FModel,ASector);
  if (FSession=nil) or (FProvider=nil) or (Length(FKey)<>16) or (Length(FClassicKey)<>6) or
    not (Length(FUid) in [4,7]) or ((FKeyNumber-$4000) div 2<>ASector) then Invalid;
  FBusy := True; Ok := False;
  try
    Uid := FSession.BeginSession;
    try
      if not BytesEqual(Uid,FUid) then Invalid;
      Authenticate(Block,FClassicKey,FKeyType); Result := FSession.ReadBlock(Block); if Length(Result)<>16 then Invalid;
      Conditions := TClassicAccessCodec.Decode(Copy(Result,6,3));
      if (FKeyType=mckB) and TClassicAccessCodec.KeyBReadable(Conditions[3]) then Invalid;
      Ok := True;
    finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
  finally FBusy := False; end;
end;
function TMifarePlusSl2ReaderWriter.ProofTrailer(const ASector: Integer;
  const AKey: TBytes; const AType: TMifareClassicKeyType): TBytes;
var Uid: TBytes; Ok: Boolean; Block: Byte;
begin
  Block := TMifarePlusSl2Codec.Trailer(FModel,ASector); Ok := False;
  Uid := FSession.BeginSession;
  try
    if not BytesEqual(Uid,FUid) then Invalid;
    Authenticate(Block,AKey,AType); Result := FSession.ReadBlock(Block);
    if Length(Result)<>16 then Invalid; Ok := True;
  finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
end;
function TMifarePlusSl2ReaderWriter.WriteSectorTrailerVerified(const ASector: Integer;
  const AExpectedVisible, ANewTrailer: TBytes; const AAcknowledge: Boolean): TMifarePlusSl2TrailerResult;
var Expected,Desired,Uid,Actual,Visible,ProofKey: TBytes; OldConditions,NewConditions: TClassicAccessConditions;
  Block: Byte; KeyWritable,AccessWritable,Ok,Dispatched: Boolean; I: Integer;
begin
  Result := Default(TMifarePlusSl2TrailerResult); Ready;
  Block := TMifarePlusSl2Codec.Trailer(FModel,ASector);
  if not AAcknowledge or (FSession=nil) or (FProvider=nil) or (Length(FKey)<>16) or
    (Length(FClassicKey)<>6) or not (Length(FUid) in [4,7]) or ((FKeyNumber-$4000) div 2<>ASector) or
    (Length(AExpectedVisible)<>16) or (Length(ANewTrailer)<>16) then Invalid;
  OldConditions := TClassicAccessCodec.Decode(Copy(AExpectedVisible,6,3));
  NewConditions := TClassicAccessCodec.Decode(Copy(ANewTrailer,6,3));
  if (FKeyType=mckB) and TClassicAccessCodec.KeyBReadable(OldConditions[3]) then Invalid;
  KeyWritable := ((FKeyType=mckA) and (OldConditions[3] in [0,1])) or
    ((FKeyType=mckB) and (OldConditions[3] in [3,4]));
  AccessWritable := ((FKeyType=mckA) and (OldConditions[3]=1)) or
    ((FKeyType=mckB) and (OldConditions[3] in [3,5]));
  if not KeyWritable or (not AccessWritable and not BytesEqual(Copy(AExpectedVisible,6,4),Copy(ANewTrailer,6,4))) then Invalid;
  Expected := CopyBytes(AExpectedVisible); Desired := CopyBytes(ANewTrailer); Visible := CopyBytes(Desired);
  for I := 0 to 5 do Visible[I] := 0;
  if not TClassicAccessCodec.KeyBReadable(NewConditions[3]) then for I := 10 to 15 do Visible[I] := 0;
  FBusy := True; Dispatched := False; Ok := False;
  try
    try
      Uid := FSession.BeginSession;
      try
        if not BytesEqual(Uid,FUid) then Invalid;
        Authenticate(Block,FClassicKey,FKeyType); Actual := FSession.ReadBlock(Block);
        if not BytesEqual(Actual,Expected) then Invalid;
        Dispatched := True; FSession.WriteBlock(Block,Desired); Ok := True;
      finally if Ok then FSession.EndSession else try FSession.EndSession; except end; end;
      ProofKey := Copy(Desired,0,6);
      try Actual := ProofTrailer(ASector,ProofKey,mckA); finally TCardCrypto.Clear(ProofKey); end;
      if not BytesEqual(Actual,Visible) then Invalid;
      Result.KeyAVerified := True;
      if TClassicAccessCodec.KeyBReadable(NewConditions[3]) then Result.KeyBReadBackVerified := True
      else begin
        ProofKey := Copy(Desired,10,6);
        try Actual := ProofTrailer(ASector,ProofKey,mckB); finally TCardCrypto.Clear(ProofKey); end;
        if not BytesEqual(Actual,Visible) then Invalid; Result.KeyBVerified := True;
      end;
      Result.VisibleTrailer := CopyBytes(Actual);
    except on E: Exception do begin
      Result := Default(TMifarePlusSl2TrailerResult);
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise;
    end; end;
  finally
    TCardCrypto.Clear(Expected); TCardCrypto.Clear(Desired); TCardCrypto.Clear(Visible); TCardCrypto.Clear(Actual); FBusy := False;
  end;
end;

function TBackend.BeginSession: TBytes;
begin
  if Active then Invalid;
  Raw.BeginSession; Active := True; Classic := False;
  try
    Uid := Raw.Activate; if not (Length(Uid) in [4,7]) then Invalid; Result := CopyBytes(Uid);
  except try EndSession; except end; raise; end;
end;
function TBackend.ExchangeNative(const ACommand: TBytes): TBytes;
var Frame: TBytes; Reply: TRawRfResponse; Count: Integer;
begin
  if not Active or Classic or (Length(ACommand)<1) then Invalid;
  Count := 17; if ACommand[0]=$72 then Count := 33;
  Frame := TRawUidCodec.AppendCrcA(ACommand); Reply := Default(TRawRfResponse);
  try Reply := Raw.Exchange(Frame,Length(Frame)*8); Result := TRawUidCodec.DecodeCrcA(Reply,Count);
  finally TCardCrypto.Clear(Frame); TCardCrypto.Clear(Reply.Data); end;
end;
function TBackend.Send(const Data: TBytes; const Count: Integer): TBytes;
var Packet: TBytes; Reply: TApduResponse;
begin
  if not Active or (Length(Data)<1) or (Length(Data)>32) then Invalid;
  Packet := nil; SetLength(Packet,8+Length(Data)); Packet[0] := $FF; Packet[4] := Byte(3+Length(Data));
  Packet[5] := $D4; Packet[6] := $40; Packet[7] := 1; Move(Data[0],Packet[8],Length(Data));
  try
    Reply := TApduCodec.DecodeResponse(Transport.Exchange(Packet));
    if (Reply.StatusWord<>$9000) or (Length(Reply.Data)<>3+Count) or (Reply.Data[0]<>$D5) or
      (Reply.Data[1]<>$41) or (Reply.Data[2]<>0) then Invalid;
    Result := Copy(Reply.Data,3,Count);
  finally TCardCrypto.Clear(Packet); TCardCrypto.Clear(Reply.Data); end;
end;
procedure TBackend.AuthenticateClassic(const ABlock: Byte; const AKeyType: TMifareClassicKeyType; const AModifiedKey: TBytes);
var Data,Packet: TBytes; Reply: TApduResponse;
begin
  if not Active or Classic or not (AKeyType in [mckA,mckB]) or (Length(AModifiedKey)<>6) then Invalid;
  Packet := HexToBytes('FF0000000BD408630280630380633D00');
  Reply := TApduCodec.DecodeResponse(Transport.Exchange(Packet));
  if (Reply.StatusWord<>$9000) or not BytesEqual(Reply.Data,HexToBytes('D509')) then Invalid;
  SetLength(Data,12); Data[0] := $60; if AKeyType=mckB then Data[0] := $61; Data[1] := ABlock;
  Move(AModifiedKey[0],Data[2],6); Move(Uid[Length(Uid)-4],Data[8],4);
  try Send(Data,0); Classic := True; finally TCardCrypto.Clear(Data); end;
end;
function TBackend.ReadBlock(const ABlock: Byte): TBytes;
begin if not Classic then Invalid; Result := Send(TBytes.Create($30,ABlock),16); end;
procedure TBackend.WriteBlock(const ABlock: Byte; const AData: TBytes);
var Data: TBytes;
begin
  if not Classic or (Length(AData)<>16) then Invalid;
  SetLength(Data,18); Data[0] := $A0; Data[1] := ABlock; Move(AData[0],Data[2],16);
  try Send(Data,0); finally TCardCrypto.Clear(Data); end;
end;
procedure TBackend.EndSession;
begin
  if not Active then Invalid; Active := False; Classic := False; TCardCrypto.Clear(Uid); Raw.EndSession;
end;
destructor TBackend.Destroy;
begin if Active then try EndSession; except end; inherited Destroy; end;
function CreateAcr122PlusSl2Session(const ATransport: ICardTransport; const ATimeoutCode: Byte): IMifarePlusSl2Session;
var Backend: TBackend;
begin
  Backend := TBackend.Create; Result := Backend; Backend.Transport := ATransport;
  Backend.Raw := CreateAcr122PlusLevelReader(ATransport,ATimeoutCode);
end;
end.
