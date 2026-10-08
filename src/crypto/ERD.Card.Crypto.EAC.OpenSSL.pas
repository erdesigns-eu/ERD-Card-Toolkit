unit ERD.Card.Crypto.EAC.OpenSSL;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Crypto, ERD.Card.Crypto.EAC;

type
  /// <summary>Optional dynamically loaded OpenSSL 3 provider for ICAO BAC/PACE, AES, SHA-1, Triple DES and ECDH.</summary>
  /// <remarks>Linux defaults to libcrypto.so.3; Windows to libcrypto-3.dll. An explicit library path may be supplied.
  /// OpenSSL installation, updates and deployment policy belong to the host. No primitives or RNG fallback are bundled.</remarks>
  TCardEacOpenSslProvider = class(TInterfacedObject,ICardAesProvider,ICardEacProvider)
  private
    FNative:TObject;
    function Crypt(const AKey,AIv,AData:TBytes; const AEncrypt,ATripleDes:Boolean):TBytes;
  public
    /// <summary>Loads the selected native library and checks its version and required symbols without card I/O.</summary>
    /// <param name="ALibraryName">Explicit library name/path, or empty for the platform's documented default.</param>
    /// <exception cref="ECardCryptoError">Loading, symbol resolution or native version fails.</exception>
    constructor Create(const ALibraryName:string='');
    /// <summary>Unloads the provider's library reference after all owned agreement contexts have released it.</summary>
    destructor Destroy; override;
    /// <summary>Encrypts complete AES-128 CBC blocks without padding.</summary>
    /// <param name="AKey">16 borrowed bytes.</param>
    /// <param name="AIv">16 borrowed bytes.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Owned exact-length ciphertext.</returns>
    function EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    /// <summary>Decrypts complete AES-128 CBC blocks without padding.</summary>
    /// <param name="AKey">16 borrowed bytes.</param>
    /// <param name="AIv">16 borrowed bytes.</param>
    /// <param name="AData">Positive complete blocks, at most one MiB.</param>
    /// <returns>Owned exact-length plaintext.</returns>
    function DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    /// <summary>Obtains OpenSSL CSPRNG bytes with no fallback.</summary>
    /// <param name="ACount">1..65536.</param>
    /// <returns>Owned fresh random bytes.</returns>
    function RandomBytes(const ACount:Integer):TBytes;
    /// <summary>Calculates SHA-1 through OpenSSL EVP.</summary>
    /// <param name="AData">Zero through one MiB.</param>
    /// <returns>Owned 20-byte digest.</returns>
    function Sha1(const AData:TBytes):TBytes;
    /// <summary>Performs exact-length Triple DES CBC with no padding.</summary>
    /// <param name="AKey">24 borrowed bytes.</param>
    /// <param name="AIv">Eight borrowed bytes.</param>
    /// <param name="AData">Positive complete eight-byte blocks, at most one MiB.</param>
    /// <param name="AEncrypt">Encryption/decryption direction.</param>
    /// <returns>Owned exact-length result.</returns>
    function TripleDesCbc(const AKey,AIv,AData:TBytes; const AEncrypt:Boolean):TBytes;
    /// <summary>Creates a validated one-use native Generic Mapping agreement retaining this provider.</summary>
    /// <param name="ACurve">NIST P-256 or brainpoolP256r1.</param>
    /// <param name="AMappingSecret">Fresh valid 32-byte mapping scalar.</param>
    /// <param name="AAgreementSecret">Separate fresh valid 32-byte agreement scalar.</param>
    /// <returns>Owned agreement; private BIGNUM storage is cleared at destruction.</returns>
    function CreatePaceAgreement(const ACurve:TCardPaceCurve;
      const AMappingSecret,AAgreementSecret:TBytes):ICardPaceAgreement;
  end;

implementation

uses
{$IFDEF FPC}
  Dynlibs;
{$ELSE}
  Winapi.Windows;
{$ENDIF}

type
  TNativeNew=function:Pointer;cdecl;
  TNativeFree=procedure(P:Pointer);cdecl;
  TVersion=function:NativeUInt;cdecl;
  TCipherInit=function(Ctx,Cipher,Engine,Key,Iv:Pointer;Encrypt:Integer):Integer;cdecl;
  TPadding=function(Ctx:Pointer;Padding:Integer):Integer;cdecl;
  TUpdate=function(Ctx,Output:Pointer;var Count:Integer;Input:Pointer;Length:Integer):Integer;cdecl;
  TFinal=function(Ctx,Output:Pointer;var Count:Integer):Integer;cdecl;
  TRandom=function(Output:Pointer;Count:Integer):Integer;cdecl;
  TDigest=function(Data:Pointer;Count:NativeUInt;Output:Pointer;var OutCount:Cardinal;Md,Engine:Pointer):Integer;cdecl;
  TTextNid=function(Name:PAnsiChar):Integer;cdecl;
  TGroupNew=function(Nid:Integer):Pointer;cdecl;
  TPointNew=function(Group:Pointer):Pointer;cdecl;
  TBinBn=function(Data:Pointer;Count:Integer;Bn:Pointer):Pointer;cdecl;
  TBnCmp=function(A,B:Pointer):Integer;cdecl;
  TBnFlags=procedure(Bn:Pointer;Flags:Integer);cdecl;
  TGroupOrder=function(Group,Order,Ctx:Pointer):Integer;cdecl;
  TPointMul=function(Group,R,N,Q,M,Ctx:Pointer):Integer;cdecl;
  TPointAdd=function(Group,R,A,B,Ctx:Pointer):Integer;cdecl;
  TPointToOct=function(Group,Point:Pointer;Form:Integer;Output:Pointer;Count:NativeUInt;Ctx:Pointer):NativeUInt;cdecl;
  TOctToPoint=function(Group,Point,Input:Pointer;Count:NativeUInt;Ctx:Pointer):Integer;cdecl;
  TPointCheck=function(Group,Point,Ctx:Pointer):Integer;cdecl;
  TPointInfinity=function(Group,Point:Pointer):Integer;cdecl;
  TPointCmp=function(Group,A,B,Ctx:Pointer):Integer;cdecl;
  TPointAffine=function(Group,Point,X,Y,Ctx:Pointer):Integer;cdecl;
  TBnToBin=function(Bn,Output:Pointer;Count:Integer):Integer;cdecl;
  TOpenSslBackend=class
  private
    FHandle:NativeUInt;
    function Symbol(const Name:AnsiString):Pointer;
  public
    Version:TVersion;
    CipherNew:TNativeNew; CipherFree:TNativeFree; AesCipher,TdesCipher,ShaMd:TNativeNew;
    CipherInit:TCipherInit; Padding:TPadding; Update:TUpdate; FinalizeCipher:TFinal; Random:TRandom; Digest:TDigest;
    TextNid:TTextNid; GroupNew:TGroupNew; GroupFree:TNativeFree; PointNew:TPointNew; PointFree:TNativeFree;
    BnNew,ContextNew:TNativeNew; BnFree,ContextFree:TNativeFree; BinBn:TBinBn; BnCmp:TBnCmp; BnFlags:TBnFlags;
    GroupOrder:TGroupOrder; PointMul:TPointMul; PointAdd:TPointAdd; PointToOct:TPointToOct; OctToPoint:TOctToPoint;
    PointCheck:TPointCheck; PointInfinity:TPointInfinity; PointCmp:TPointCmp; PointAffine:TPointAffine; BnToBin:TBnToBin;
    constructor Create(const LibraryName:string);
    destructor Destroy; override;
  end;
  TOpenSslPaceAgreement=class(TInterfacedObject,ICardPaceAgreement)
  private
    FProvider:ICardEacProvider;
    FBackend:TOpenSslBackend;
    FGroup,FContext,FOrder,FMapping,FSecret,FMapped,FPublic:Pointer;
    FDidMap,FDidAgree,FMapSucceeded:Boolean;
    function Scalar(const Bytes:TBytes):Pointer;
    function DecodePoint(const Bytes:TBytes):Pointer;
    function EncodePoint(const Point:Pointer):TBytes;
  public
    constructor Create(const Provider:TCardEacOpenSslProvider; const Curve:TCardPaceCurve;
      const Mapping,Secret:TBytes);
    destructor Destroy; override;
    function MappingPublicKey:TBytes;
    function MapAndGenerate(const ACardMappingKey,ANonce:TBytes):TBytes;
    function Agree(const ACardAgreementKey:TBytes):TBytes;
  end;

procedure InvalidEacCrypto;
begin raise ECardCryptoError.Create('Native ICAO cryptographic operation failed.'); end;

function TOpenSslBackend.Symbol(const Name:AnsiString):Pointer;
begin
{$IFDEF FPC}
  Result:=GetProcedureAddress(TLibHandle(FHandle),Name);
{$ELSE}
  Result:=GetProcAddress(HMODULE(FHandle),PAnsiChar(Name));
{$ENDIF}
  if Result=nil then InvalidEacCrypto;
end;

constructor TOpenSslBackend.Create(const LibraryName:string);
var Name:string;
begin
  inherited Create; Name:=LibraryName;
  if Name='' then
{$IFDEF MSWINDOWS}
    Name:='libcrypto-3.dll';
{$ELSE}
    Name:='libcrypto.so.3';
{$ENDIF}
{$IFDEF FPC}
  FHandle:=NativeUInt(LoadLibrary(Name));
{$ELSE}
  FHandle:=NativeUInt(LoadLibrary(PChar(Name)));
{$ENDIF}
  if FHandle=0 then InvalidEacCrypto;
  Version:=TVersion(Symbol('OpenSSL_version_num'));
  CipherNew:=TNativeNew(Symbol('EVP_CIPHER_CTX_new'));
  CipherFree:=TNativeFree(Symbol('EVP_CIPHER_CTX_free'));
  AesCipher:=TNativeNew(Symbol('EVP_aes_128_cbc'));
  TdesCipher:=TNativeNew(Symbol('EVP_des_ede3_cbc'));
  ShaMd:=TNativeNew(Symbol('EVP_sha1'));
  CipherInit:=TCipherInit(Symbol('EVP_CipherInit_ex'));
  Padding:=TPadding(Symbol('EVP_CIPHER_CTX_set_padding'));
  Update:=TUpdate(Symbol('EVP_CipherUpdate'));
  FinalizeCipher:=TFinal(Symbol('EVP_CipherFinal_ex'));
  Random:=TRandom(Symbol('RAND_bytes'));
  Digest:=TDigest(Symbol('EVP_Digest'));
  TextNid:=TTextNid(Symbol('OBJ_txt2nid'));
  GroupNew:=TGroupNew(Symbol('EC_GROUP_new_by_curve_name'));
  GroupFree:=TNativeFree(Symbol('EC_GROUP_free'));
  PointNew:=TPointNew(Symbol('EC_POINT_new'));
  PointFree:=TNativeFree(Symbol('EC_POINT_clear_free'));
  BnNew:=TNativeNew(Symbol('BN_secure_new'));
  ContextNew:=TNativeNew(Symbol('BN_CTX_secure_new'));
  BnFree:=TNativeFree(Symbol('BN_clear_free'));
  ContextFree:=TNativeFree(Symbol('BN_CTX_free'));
  BinBn:=TBinBn(Symbol('BN_bin2bn'));
  BnCmp:=TBnCmp(Symbol('BN_cmp'));
  BnFlags:=TBnFlags(Symbol('BN_set_flags'));
  GroupOrder:=TGroupOrder(Symbol('EC_GROUP_get_order'));
  PointMul:=TPointMul(Symbol('EC_POINT_mul'));
  PointAdd:=TPointAdd(Symbol('EC_POINT_add'));
  PointToOct:=TPointToOct(Symbol('EC_POINT_point2oct'));
  OctToPoint:=TOctToPoint(Symbol('EC_POINT_oct2point'));
  PointCheck:=TPointCheck(Symbol('EC_POINT_is_on_curve'));
  PointInfinity:=TPointInfinity(Symbol('EC_POINT_is_at_infinity'));
  PointCmp:=TPointCmp(Symbol('EC_POINT_cmp'));
  PointAffine:=TPointAffine(Symbol('EC_POINT_get_affine_coordinates'));
  BnToBin:=TBnToBin(Symbol('BN_bn2binpad'));
  if Version<$30000000 then InvalidEacCrypto;
end;

destructor TOpenSslBackend.Destroy;
begin
  if FHandle<>0 then
{$IFDEF FPC}
    UnloadLibrary(TLibHandle(FHandle));
{$ELSE}
    FreeLibrary(HMODULE(FHandle));
{$ENDIF}
  inherited Destroy;
end;

constructor TCardEacOpenSslProvider.Create(const ALibraryName:string);
begin inherited Create; FNative:=TOpenSslBackend.Create(ALibraryName); end;
destructor TCardEacOpenSslProvider.Destroy;
begin FNative.Free; inherited Destroy; end;

function TCardEacOpenSslProvider.Crypt(const AKey,AIv,AData:TBytes; const AEncrypt,ATripleDes:Boolean):TBytes;
var B:TOpenSslBackend; Ctx,Cipher:Pointer; Buffer:TBytes; First,Last:Integer;
begin
  Result:=nil; B:=TOpenSslBackend(FNative);
  if ATripleDes then
  begin
    if (Length(AKey)<>24) or (Length(AIv)<>8) or (Length(AData)=0) or
      (Length(AData)>1048576) or (Length(AData) mod 8<>0) then InvalidEacCrypto;
    Cipher:=B.TdesCipher;
  end
  else begin TCardCrypto.ValidateCbc(AKey,AIv,AData); Cipher:=B.AesCipher; end;
  Ctx:=B.CipherNew; if Ctx=nil then InvalidEacCrypto;
  try
    if B.CipherInit(Ctx,Cipher,nil,@AKey[0],@AIv[0],Ord(AEncrypt))<>1 then InvalidEacCrypto;
    if B.Padding(Ctx,0)<>1 then InvalidEacCrypto;
    SetLength(Buffer,Length(AData)+16); First:=0; Last:=0;
    if B.Update(Ctx,@Buffer[0],First,@AData[0],Length(AData))<>1 then InvalidEacCrypto;
    if (First<0) or (First>Length(AData)) then InvalidEacCrypto;
    if B.FinalizeCipher(Ctx,@Buffer[First],Last)<>1 then InvalidEacCrypto;
    if (Last<0) or (First+Last<>Length(AData)) then InvalidEacCrypto;
    Result:=Copy(Buffer,0,First+Last);
  finally TCardCrypto.Clear(Buffer); B.CipherFree(Ctx); end;
end;

function TCardEacOpenSslProvider.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=Crypt(AKey,AIv,AData,True,False); end;
function TCardEacOpenSslProvider.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=Crypt(AKey,AIv,AData,False,False); end;
function TCardEacOpenSslProvider.TripleDesCbc(const AKey,AIv,AData:TBytes; const AEncrypt:Boolean):TBytes;
begin Result:=Crypt(AKey,AIv,AData,AEncrypt,True); end;

function TCardEacOpenSslProvider.RandomBytes(const ACount:Integer):TBytes;
begin
  Result:=nil; if (ACount<1) or (ACount>65536) then InvalidEacCrypto;
  SetLength(Result,ACount);
  if TOpenSslBackend(FNative).Random(@Result[0],ACount)<>1 then
  begin TCardCrypto.Clear(Result); InvalidEacCrypto; end;
end;

function TCardEacOpenSslProvider.Sha1(const AData:TBytes):TBytes;
var B:TOpenSslBackend; Input:Pointer; Count:Cardinal;
begin
  Result:=nil; if Length(AData)>1048576 then InvalidEacCrypto;
  B:=TOpenSslBackend(FNative); Input:=nil; if Length(AData)>0 then Input:=@AData[0];
  SetLength(Result,20); Count:=0;
  if (B.Digest(Input,Length(AData),@Result[0],Count,B.ShaMd,nil)<>1) or (Count<>20) then
  begin TCardCrypto.Clear(Result); InvalidEacCrypto; end;
end;

function TCardEacOpenSslProvider.CreatePaceAgreement(const ACurve:TCardPaceCurve;
  const AMappingSecret,AAgreementSecret:TBytes):ICardPaceAgreement;
begin Result:=TOpenSslPaceAgreement.Create(Self,ACurve,AMappingSecret,AAgreementSecret); end;

constructor TOpenSslPaceAgreement.Create(const Provider:TCardEacOpenSslProvider;
  const Curve:TCardPaceCurve; const Mapping,Secret:TBytes);
var Name:AnsiString;
begin
  inherited Create; FProvider:=Provider; FBackend:=TOpenSslBackend(Provider.FNative);
  case Curve of ppcNistP256:Name:='prime256v1'; ppcBrainpoolP256:Name:='brainpoolP256r1'; else InvalidEacCrypto; end;
  FGroup:=FBackend.GroupNew(FBackend.TextNid(PAnsiChar(Name)));
  FContext:=FBackend.ContextNew; FOrder:=FBackend.BnNew;
  if (FGroup=nil) or (FContext=nil) or (FOrder=nil) then InvalidEacCrypto;
  if FBackend.GroupOrder(FGroup,FOrder,FContext)<>1 then InvalidEacCrypto;
  FMapping:=Scalar(Mapping); FSecret:=Scalar(Secret);
end;

destructor TOpenSslPaceAgreement.Destroy;
begin
  if FBackend<>nil then
  begin
    if FPublic<>nil then FBackend.PointFree(FPublic);
    if FMapped<>nil then FBackend.PointFree(FMapped);
    if FMapping<>nil then FBackend.BnFree(FMapping);
    if FSecret<>nil then FBackend.BnFree(FSecret);
    if FOrder<>nil then FBackend.BnFree(FOrder);
    if FContext<>nil then FBackend.ContextFree(FContext);
    if FGroup<>nil then FBackend.GroupFree(FGroup);
  end;
  FProvider:=nil; inherited Destroy;
end;

function TOpenSslPaceAgreement.Scalar(const Bytes:TBytes):Pointer;
var Zero:Pointer; Success:Boolean;
begin
  Result:=nil; if Length(Bytes)<>32 then InvalidEacCrypto;
  Result:=FBackend.BnNew; Zero:=FBackend.BnNew; Success:=False;
  try
    if (Result=nil) or (Zero=nil) then InvalidEacCrypto;
    if FBackend.BinBn(@Bytes[0],Length(Bytes),Result)=nil then InvalidEacCrypto;
    if (FBackend.BnCmp(Result,Zero)<=0) or (FBackend.BnCmp(Result,FOrder)>=0) then InvalidEacCrypto;
    FBackend.BnFlags(Result,4); Success:=True;
  finally
    if Zero<>nil then FBackend.BnFree(Zero);
    if not Success and (Result<>nil) then begin FBackend.BnFree(Result); Result:=nil; end;
  end;
end;

function TOpenSslPaceAgreement.EncodePoint(const Point:Pointer):TBytes;
begin
  Result:=nil;
  if (Point=nil) or (FBackend.PointInfinity(FGroup,Point)<>0) then InvalidEacCrypto;
  SetLength(Result,65);
  if FBackend.PointToOct(FGroup,Point,4,@Result[0],65,FContext)<>65 then InvalidEacCrypto;
end;

function TOpenSslPaceAgreement.DecodePoint(const Bytes:TBytes):Pointer;
var CheckPoint:Pointer; Success:Boolean;
begin
  Result:=nil; if (Length(Bytes)<>65) or (Bytes[0]<>4) then InvalidEacCrypto;
  Result:=FBackend.PointNew(FGroup); CheckPoint:=FBackend.PointNew(FGroup); Success:=False;
  try
    if (Result=nil) or (CheckPoint=nil) then InvalidEacCrypto;
    if (FBackend.OctToPoint(FGroup,Result,@Bytes[0],65,FContext)<>1) or
      (FBackend.PointCheck(FGroup,Result,FContext)<>1) or
      (FBackend.PointInfinity(FGroup,Result)<>0) then InvalidEacCrypto;
    if (FBackend.PointMul(FGroup,CheckPoint,nil,Result,FOrder,FContext)<>1) or
      (FBackend.PointInfinity(FGroup,CheckPoint)<>1) then InvalidEacCrypto;
    Success:=True;
  finally
    if CheckPoint<>nil then FBackend.PointFree(CheckPoint);
    if not Success and (Result<>nil) then begin FBackend.PointFree(Result); Result:=nil; end;
  end;
end;

function TOpenSslPaceAgreement.MappingPublicKey:TBytes;
var Point:Pointer;
begin
  Result:=nil; if FDidMap then InvalidEacCrypto; Point:=FBackend.PointNew(FGroup);
  try
    if Point=nil then InvalidEacCrypto;
    if FBackend.PointMul(FGroup,Point,FMapping,nil,nil,FContext)<>1 then InvalidEacCrypto;
    Result:=EncodePoint(Point);
  finally if Point<>nil then FBackend.PointFree(Point); end;
end;

function TOpenSslPaceAgreement.MapAndGenerate(const ACardMappingKey,ANonce:TBytes):TBytes;
var CardPoint,H,NonceBn,OwnPoint:Pointer; NonceBytes,OwnBytes:TBytes;
begin
  Result:=nil; if FDidMap or (Length(ANonce)<>16) then InvalidEacCrypto;
  FDidMap:=True; CardPoint:=nil; H:=nil; NonceBn:=nil; OwnPoint:=nil;
  try
    CardPoint:=DecodePoint(ACardMappingKey); H:=FBackend.PointNew(FGroup); OwnPoint:=FBackend.PointNew(FGroup);
    if (H=nil) or (OwnPoint=nil) then InvalidEacCrypto;
    if FBackend.PointMul(FGroup,OwnPoint,FMapping,nil,nil,FContext)<>1 then InvalidEacCrypto;
    if FBackend.PointCmp(FGroup,CardPoint,OwnPoint,FContext)=0 then InvalidEacCrypto;
    NonceBytes:=nil; SetLength(NonceBytes,32); Move(ANonce[0],NonceBytes[16],16);
    // The 128-bit nonce may be zero; only private agreement scalars must be positive.
    NonceBn:=FBackend.BnNew; if NonceBn=nil then InvalidEacCrypto;
    if FBackend.BinBn(@NonceBytes[0],32,NonceBn)<>NonceBn then InvalidEacCrypto;
    FBackend.BnFlags(NonceBn,4);
    FMapped:=FBackend.PointNew(FGroup); FPublic:=FBackend.PointNew(FGroup);
    if (FMapped=nil) or (FPublic=nil) then InvalidEacCrypto;
    if FBackend.PointMul(FGroup,H,nil,CardPoint,FMapping,FContext)<>1 then InvalidEacCrypto;
    if FBackend.PointMul(FGroup,FMapped,NonceBn,nil,nil,FContext)<>1 then InvalidEacCrypto;
    if FBackend.PointAdd(FGroup,FMapped,FMapped,H,FContext)<>1 then InvalidEacCrypto;
    OwnBytes:=EncodePoint(FMapped); // Reject a zero mapped generator before secret multiplication.
    if FBackend.PointMul(FGroup,FPublic,nil,FMapped,FSecret,FContext)<>1 then InvalidEacCrypto;
    Result:=EncodePoint(FPublic); FMapSucceeded:=True;
  finally
    if CardPoint<>nil then FBackend.PointFree(CardPoint);
    if H<>nil then FBackend.PointFree(H);
    if OwnPoint<>nil then FBackend.PointFree(OwnPoint);
    if NonceBn<>nil then FBackend.BnFree(NonceBn);
    TCardCrypto.Clear(NonceBytes); TCardCrypto.Clear(OwnBytes);
  end;
end;

function TOpenSslPaceAgreement.Agree(const ACardAgreementKey:TBytes):TBytes;
var CardPoint,Shared,X:Pointer;
begin
  Result:=nil; if not FMapSucceeded or FDidAgree or (FPublic=nil) then InvalidEacCrypto;
  FDidAgree:=True; CardPoint:=nil; Shared:=nil; X:=nil;
  try
    CardPoint:=DecodePoint(ACardAgreementKey);
    if FBackend.PointCmp(FGroup,CardPoint,FPublic,FContext)=0 then InvalidEacCrypto;
    Shared:=FBackend.PointNew(FGroup); X:=FBackend.BnNew;
    if (Shared=nil) or (X=nil) then InvalidEacCrypto;
    if FBackend.PointMul(FGroup,Shared,nil,CardPoint,FSecret,FContext)<>1 then InvalidEacCrypto;
    if (FBackend.PointInfinity(FGroup,Shared)<>0) or
      (FBackend.PointAffine(FGroup,Shared,X,nil,FContext)<>1) then InvalidEacCrypto;
    SetLength(Result,32); if FBackend.BnToBin(X,@Result[0],32)<>32 then InvalidEacCrypto;
  finally
    if CardPoint<>nil then FBackend.PointFree(CardPoint);
    if Shared<>nil then FBackend.PointFree(Shared);
    if X<>nil then FBackend.BnFree(X);
  end;
end;

end.
