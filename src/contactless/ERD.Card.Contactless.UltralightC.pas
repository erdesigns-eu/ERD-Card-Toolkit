unit ERD.Card.Contactless.UltralightC;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes,SysUtils,{$ELSE}System.Classes,System.SysUtils,{$ENDIF}
 ERD.Card.Crypto.DES,ERD.Card.Contactless.Raw;
const
  /// <summary>First physical Ultralight C user page; manufacturer/static-lock/OTP bytes are excluded.</summary>
  UltralightCFirstUserPage=4;
  /// <summary>Last physical user page; dynamic locks, counter, authentication configuration and keys are excluded.</summary>
  UltralightCLastUserPage=39;
  /// <summary>Complete user region, 36 four-byte pages.</summary>
  UltralightCUserBytes=144;
type
  /// <summary>Nonvisual explicitly keyed Ultralight C mutual authentication and user-only memory access.</summary>
  /// <remarks>Uses one retained raw Type A session, explicit CRC-A, fresh eight-byte CSPRNG nonce and native
  /// two-key Triple DES. No key discovery, retries, key/configuration/lock writes or encrypted memory messaging.
  /// Ultralight C authenticates access but subsequent memory data remain plaintext. Configure/use on one thread.</remarks>
  TUltralightCCardReaderWriter=class(TComponent)
  private
    FReader:IRawContactlessReader;FProvider:ICardDesProvider;FBusy:Boolean;
    procedure SetReader(const AValue:IRawContactlessReader);
    procedure SetProvider(const AValue:ICardDesProvider);
    procedure Acquire(const AKey:TBytes);
    procedure Release(const ASucceeded:Boolean);
    procedure Authenticate(const AKey:TBytes);
    function ReadPage(const APage:Integer):TBytes;
  public
    /// <summary>Constructs inactive access without opening readers or retaining a key.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner:TComponent);override;
    /// <summary>Authenticates with a supplied key and returns one exact user page.</summary>
    /// <param name="APage">Physical page 4..39.</param>
    /// <param name="AKey">Exactly 16 K1/K2 bytes in cryptographic order; no default or reversal.</param>
    /// <returns>Owned four-byte page after successful session release.</returns>
    function ReadUserPage(const APage:Integer;const AKey:TBytes):TBytes;
    /// <summary>Authenticates once and reads all 36 user pages in ascending four-page READ blocks.</summary>
    /// <param name="AKey">Exactly 16 supplied bytes; borrowed, copied and locally wiped.</param>
    /// <returns>Owned 144 bytes corresponding to physical pages 4..39 after successful release.</returns>
    function ReadUserMemory(const AKey:TBytes):TBytes;
    /// <summary>Authenticates once, submits one four-byte user write and independently verifies the same RF session.</summary>
    /// <param name="APage">Physical page 4..39; manufacturer/configuration/key regions are excluded.</param>
    /// <param name="AData">Exactly four borrowed bytes, copied before I/O.</param>
    /// <param name="AKey">Exactly 16 supplied cryptographic-order bytes.</param>
    /// <returns>Independent verified four-byte read-back after successful release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch, including ACK/read-back/release.</exception>
    function WriteUserPageVerified(const APage:Integer;const AData,AKey:TBytes):TBytes;
    /// <summary>Explicit inactive raw RF adapter; change only outside an operation.</summary>
    property Reader:IRawContactlessReader read FReader write SetReader;
    /// <summary>Maintained DES/CSPRNG backend; change only outside an operation.</summary>
    property CryptoProvider:ICardDesProvider read FProvider write SetProvider;
    /// <summary>True while one operation owns its RF session and local execution.</summary>
    property Busy:Boolean read FBusy;
  end;
implementation
uses ERD.Card.Bytes,ERD.Card.Crypto,ERD.Card.Contactless,ERD.Card.Contactless.Type2.Password;
procedure Invalid;
begin raise EContactlessError.Create('Invalid Ultralight C operation or response.');end;
procedure CheckPage(const APage:Integer);
begin if (APage<UltralightCFirstUserPage) or (APage>UltralightCLastUserPage) then Invalid;end;
constructor TUltralightCCardReaderWriter.Create(AOwner:TComponent);
begin inherited Create(AOwner);end;
procedure TUltralightCCardReaderWriter.SetReader(const AValue:IRawContactlessReader);
begin if FBusy then Invalid;FReader:=AValue;end;
procedure TUltralightCCardReaderWriter.SetProvider(const AValue:ICardDesProvider);
begin if FBusy then Invalid;FProvider:=AValue;end;
procedure TUltralightCCardReaderWriter.Authenticate(const AKey:TBytes);
var Key,Zero,Nonce,Payload,Wire,Response,RndB,Plain,Challenge,Rotated,CheckNonce:TBytes;
  Dispatched:Boolean;I:Integer;Raw:TRawRfResponse;
begin
  Key:=CopyBytes(AKey);Zero:=nil;Nonce:=nil;Payload:=nil;Wire:=nil;Response:=nil;
  RndB:=nil;Plain:=nil;Challenge:=nil;Rotated:=nil;CheckNonce:=nil;Raw:=Default(TRawRfResponse);Dispatched:=False;
  try
    try
      Nonce:=FProvider.RandomBytes(8);if Length(Nonce)<>8 then Invalid;
      SetLength(Zero,8);Payload:=HexToBytes('1A00');Wire:=TRawUidCodec.AppendCrcA(Payload);
      Dispatched:=True;Raw:=FReader.Exchange(Wire,Length(Wire)*8);Response:=TRawUidCodec.DecodeCrcA(Raw,9);
      if Response[0]<>$AF then Invalid;
      RndB:=TCardDesCrypto.Crypt(FProvider,Key,Zero,Copy(Response,1,8),False);
      SetLength(Plain,16);Move(Nonce[0],Plain[0],8);for I:=0 to 7 do Plain[8+I]:=RndB[(I+1) mod 8];
      Challenge:=TCardDesCrypto.Crypt(FProvider,Key,Copy(Response,1,8),Plain,True);
      TCardCrypto.Clear(Payload);SetLength(Payload,17);Payload[0]:=$AF;Move(Challenge[0],Payload[1],16);
      TCardCrypto.Clear(Wire);Wire:=TRawUidCodec.AppendCrcA(Payload);
      TCardCrypto.Clear(Raw.Data);Raw:=FReader.Exchange(Wire,Length(Wire)*8);
      TCardCrypto.Clear(Response);Response:=TRawUidCodec.DecodeCrcA(Raw,9);if Response[0]<>0 then Invalid;
      CheckNonce:=TCardDesCrypto.Crypt(FProvider,Key,Copy(Challenge,8,8),Copy(Response,1,8),False);
      SetLength(Rotated,8);for I:=0 to 7 do Rotated[I]:=Nonce[(I+1) mod 8];
      if not TCardCrypto.EqualSecret(Rotated,CheckNonce) then Invalid;
    except on E:Exception do begin if Dispatched then raise EType2AuthenticationError.Create(E.ClassName);raise;end;end;
  finally
    TCardCrypto.Clear(Key);TCardCrypto.Clear(Zero);TCardCrypto.Clear(Nonce);TCardCrypto.Clear(Payload);TCardCrypto.Clear(Wire);
    TCardCrypto.Clear(Response);TCardCrypto.Clear(RndB);TCardCrypto.Clear(Plain);TCardCrypto.Clear(Challenge);
    TCardCrypto.Clear(Rotated);TCardCrypto.Clear(CheckNonce);TCardCrypto.Clear(Raw.Data);
  end;
end;
procedure TUltralightCCardReaderWriter.Acquire(const AKey:TBytes);
var Uid,Key:TBytes;
begin
  if FBusy or (FReader=nil) or (FProvider=nil) or (Length(AKey)<>16) then Invalid;
  Key:=CopyBytes(AKey);FBusy:=True;
  try
   try
    FReader.BeginSession;
    try Uid:=FReader.Activate;if Length(Uid)<>7 then Invalid;Authenticate(Key);
    except try FReader.EndSession;except end;raise;end;
   except FBusy:=False;raise;end;
  finally TCardCrypto.Clear(Key);end;
end;
procedure TUltralightCCardReaderWriter.Release(const ASucceeded:Boolean);
begin
  try if ASucceeded then FReader.EndSession else try FReader.EndSession;except end;
  finally FBusy:=False;end;
end;
function TUltralightCCardReaderWriter.ReadPage(const APage:Integer):TBytes;
var First:Integer;Payload,Wire,Block:TBytes;
begin
  CheckPage(APage);First:=APage;if First>36 then First:=36;
  SetLength(Payload,2);Payload[0]:=$30;Payload[1]:=First;Wire:=TRawUidCodec.AppendCrcA(Payload);
  Block:=TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,Length(Wire)*8),16);
  Result:=Copy(Block,(APage-First)*4,4);
end;
function TUltralightCCardReaderWriter.ReadUserPage(const APage:Integer;const AKey:TBytes):TBytes;
var Data:TBytes;Succeeded:Boolean;
begin
  Result:=nil;CheckPage(APage);Acquire(AKey);Succeeded:=False;
  try Data:=ReadPage(APage);Succeeded:=True;finally Release(Succeeded);end;Result:=Data;
end;
function TUltralightCCardReaderWriter.ReadUserMemory(const AKey:TBytes):TBytes;
var Data,Payload,Wire,Block:TBytes;Page:Integer;Succeeded:Boolean;
begin
  Result:=nil;Acquire(AKey);Succeeded:=False;
  try
    SetLength(Data,UltralightCUserBytes);Page:=4;
    while Page<=36 do begin
      SetLength(Payload,2);Payload[0]:=$30;Payload[1]:=Page;Wire:=TRawUidCodec.AppendCrcA(Payload);
      Block:=TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,Length(Wire)*8),16);
      Move(Block[0],Data[(Page-4)*4],16);Inc(Page,4);
    end;
    Succeeded:=True;
  finally Release(Succeeded);end;Result:=Data;
end;
function TUltralightCCardReaderWriter.WriteUserPageVerified(const APage:Integer;const AData,AKey:TBytes):TBytes;
var Data,Payload,Wire,Readback:TBytes;Raw:TRawRfResponse;Succeeded,Dispatched:Boolean;
begin
  Result:=nil;CheckPage(APage);if Length(AData)<>4 then Invalid;Data:=CopyBytes(AData);Dispatched:=False;
  try
    Acquire(AKey);Succeeded:=False;
    try
      SetLength(Payload,6);Payload[0]:=$A2;Payload[1]:=APage;Move(Data[0],Payload[2],4);
      Wire:=TRawUidCodec.AppendCrcA(Payload);Dispatched:=True;Raw:=FReader.Exchange(Wire,Length(Wire)*8);
      if Raw.TimedOut or (Raw.BitCount<>4) or (Length(Raw.Data)<>1) or ((Raw.Data[0] and $F)<>$A) then Invalid;
      Readback:=ReadPage(APage);if not BytesEqual(Data,Readback) then Invalid;Succeeded:=True;
    finally Release(Succeeded);end;
    Result:=Readback;
  except on E:Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);raise;end;end;
end;
end.
