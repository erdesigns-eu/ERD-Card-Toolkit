program CardCryptoTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows,
{$ELSE}
  ERD.Card.Crypto.OpenSSL,
{$ENDIF}
  ERD.Card.Contactless.DESFire.EV2;

type
  TDecryptSpy = class(TInterfacedObject,ICardAesProvider)
  private
    FBase:ICardAesProvider;
  public
    DecryptCalls:Integer;
    constructor Create(const ABase:ICardAesProvider);
    function EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
    function RandomBytes(const ACount:Integer):TBytes;
  end;
constructor TDecryptSpy.Create(const ABase:ICardAesProvider);
begin inherited Create; FBase:=ABase; end;
function TDecryptSpy.EncryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Result:=FBase.EncryptCbc(AKey,AIv,AData); end;
function TDecryptSpy.DecryptCbc(const AKey,AIv,AData:TBytes):TBytes;
begin Inc(DecryptCalls); Result:=FBase.DecryptCbc(AKey,AIv,AData); end;
function TDecryptSpy.RandomBytes(const ACount:Integer):TBytes;
begin Result:=FBase.RandomBytes(ACount); end;

var Assertions:Integer;
procedure Check(const Condition:Boolean; const Text:string);
begin Inc(Assertions); if not Condition then raise Exception.Create(Text); end;
procedure Equal(const Actual:TBytes; const Expected:string);
begin Check(BytesEqual(Actual,HexToBytes(Expected)),'Independent vector mismatch at assertion '+IntToStr(Assertions+1)); end;

procedure AesTests(const Provider:ICardAesProvider);
var Key,Iv,Plain,Cipher,Mac,Random,Original:TBytes; I,J:Integer; Failed:Boolean;
  procedure CmacVector(const Message,Expected:string);
  begin Mac:=TCardCrypto.Cmac(Provider,Key,HexToBytes(Message)); Equal(Mac,Expected); end;
begin
  Key:=HexToBytes('2B7E151628AED2A6ABF7158809CF4F3C'); Iv:=HexToBytes('000102030405060708090A0B0C0D0E0F');
  Plain:=HexToBytes('6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E5130C81C46A35CE411E5FBC1191A0A52EFF69F2445DF4F9B17AD2B417BE66C3710');
  Cipher:=Provider.EncryptCbc(Key,Iv,Plain);
  Equal(Cipher,'7649ABAC8119B246CEE98E9B12E9197D5086CB9B507219EE95DB113A917678B273BED6B8E3C1743B7116E69E222295163FF1CAA1681FAC09120ECA307586E1A7');
  Check(BytesEqual(Provider.DecryptCbc(Key,Iv,Cipher),Plain),'NIST CBC decrypt');
  Equal(Key,'2B7E151628AED2A6ABF7158809CF4F3C'); Equal(Iv,'000102030405060708090A0B0C0D0E0F');
  CmacVector('','BB1D6929E95937287FA37D129B756746');
  CmacVector('6BC1BEE22E409F96E93D7E117393172A','070A16B46B4D4144F79BDD9DD04A287C');
  CmacVector('6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E5130C81C46A35CE411','DFA66747DE9AE63030CA32611497C827');
  CmacVector(BytesToHex(Plain),'51F0BEBF7E3B9D92FC49741779363CFE');
  Random:=Provider.RandomBytes(16); Check(Length(Random)=16,'Native CSPRNG length');
  for I:=0 to 64 do
  begin
    Plain:=nil; SetLength(Plain,I); for J:=0 to High(Plain) do Plain[J]:=(J*37) and $FF;
    Failed:=False; try Cipher:=Provider.EncryptCbc(Key,Iv,Plain); except on E:ECardCryptoError do Failed:=True; end;
    Check(Failed=((I=0) or (I mod 16<>0)),'CBC size preflight');
    if not Failed then Check(BytesEqual(Provider.DecryptCbc(Key,Iv,Cipher),Plain),'CBC multiple-block roundtrip');
  end;
  Original:=CopyBytes(Key); Mac:=CopyBytes(Key); Check(TCardCrypto.EqualSecret(Key,Mac),'Secret comparison match');
  for I:=0 to High(Mac) do
  begin Mac[I]:=Mac[I] xor 1; Check(not TCardCrypto.EqualSecret(Key,Mac),'Every mismatch position'); Mac[I]:=Mac[I] xor 1; end;
  TCardCrypto.Clear(Mac); Check(Length(Mac)=0,'Clear releases reference'); Check(BytesEqual(Key,Original),'Caller key preserved');
  Writeln('PASS: NIST AES-CBC/CMAC vectors, provider contracts and secret ownership.');
end;

procedure Ev2Tests(const Provider:ICardAesProvider);
var Keys:TDesfireEv2Keys; Key,A,B,Ti,Encoded,Response,Decoded,Original:TBytes;
  I,J:Integer; Failed:Boolean; Spy:TDecryptSpy; Retained:ICardAesProvider;
begin
  Key:=HexToBytes('00000000000000000000000000000000');
  A:=HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE'); B:=HexToBytes('FA659AD0DCA738DD65DC7DC38612AD81');
  Keys:=TDesfireEv2Codec.DeriveKeys(Provider,Key,A,B);
  Equal(Keys.Encryption,'63DC07286289A7A6C0334CA31C314A04'); Equal(Keys.Authentication,'774F26743ECE6AF5033B6AE8522946F6');
  TDesfireEv2Codec.ClearKeys(Keys);
  Keys.Encryption:=HexToBytes('FFBCFE1F41840A09C9A88D0A4B10DF05');
  Keys.Authentication:=HexToBytes('37E7234B11BEBEFDE41A8F290090EF80'); Ti:=HexToBytes('CD73D8E5');
  Encoded:=TDesfireEv2Codec.EncodeCommand(Provider,Keys,Ti,0,$8D,HexToBytes('00000000190000'),HexToBytes('22222222222222222222222222222222222222222222222222'),dfcFull);
  Equal(Encoded,'00000000190000D7446FBC912580C0A65E738D28B609E43ADBB8FB2B4CA68744D1BBEBB37EBD32700ADF7BB9F62A6C');
  Equal(TDesfireEv2Codec.EncodeCommand(Provider,Keys,Ti,1,$AD,HexToBytes('00000000300000'),nil,dfcFull),'000000003000007CF94F122B3DB05F');
  Response:=HexToBytes('B9A534A7A73EE0DD');
  Check(Length(TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,1,Response,dfcFull,0))=0,'Published full write acknowledgement');
  Response:=HexToBytes('8848D0F9B9FD4495770C89925B2A85C7274D350FA9029C484D43804886662DC42D7F40A6D7A415E4A71EFF79EB8E5721AC3BF1CAAFE8EB2CAA2DC162E67A97A38ED7888F22B3A587');
  Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,2,Response,dfcFull,48);
  Equal(Decoded,'222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000');
  Original:=CopyBytes(Response);
  for I:=0 to High(Response) do
    for J:=0 to 7 do
    begin
      Response[I]:=Response[I] xor (1 shl J); Failed:=False;
      try Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,2,Response,dfcFull,48);
      except on E:ECardCryptoError do Failed:=True; end;
      Check(Failed,'All ciphertext/MAC single-bit corruptions refused'); Response[I]:=Response[I] xor (1 shl J);
    end;
  Check(BytesEqual(Response,Original),'Borrowed response preserved');
  Failed:=False; try Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,1,Response,dfcFull,48);
  except on E:ECardCryptoError do Failed:=True; end; Check(Failed,'Response replay with old counter refused');
  Failed:=False; try Encoded:=TDesfireEv2Codec.EncodeCommand(Provider,Keys,Ti,65535,$AD,nil,nil,dfcMac);
  except on E:ECardCryptoError do Failed:=True; end; Check(Failed,'Counter wrap refused');
  for I:=0 to 47 do
  begin
    Failed:=False; try Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,2,Response,dfcFull,I);
    except on E:ECardCryptoError do Failed:=True; end; Check(Failed,'Authenticated exact-length/padding enforced');
  end;
  // Independently encrypted/MACed malformed padding, using published NXP keys.
  Response:=HexToBytes('8848D0F9B9FD4495770C89925B2A85C7274D350FA9029C484D43804886662DC42D7F40A6D7A415E4A71EFF79EB8E5721E8601A97442B8CDD3B38B843E9001C9FD3402539F2C0B43F'); Failed:=False;
  try Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,2,Response,dfcFull,48);
  except on E:ECardCryptoError do Failed:=True; end; Check(Failed,'Authenticated malformed method-two padding refused');
  Response:=HexToBytes('8848D0F9B9FD4495770C89925B2A85C7274D350FA9029C484D43804886662DC42D7F40A6D7A415E4A71EFF79EB8E572165E411DB1686AC0A49D435B94056288AE8D60B69BD9211AA'); Failed:=False;
  try Decoded:=TDesfireEv2Codec.DecodeResponse(Provider,Keys,Ti,2,Response,dfcFull,48);
  except on E:ECardCryptoError do Failed:=True; end; Check(Failed,'Authenticated malformed method-two padding refused');
  Response:=CopyBytes(Original); Response[High(Response)]:=Response[High(Response)] xor 1;
  Spy:=TDecryptSpy.Create(Provider); Retained:=Spy; Failed:=False;
  try Decoded:=TDesfireEv2Codec.DecodeResponse(Retained,Keys,Ti,2,Response,dfcFull,48);
  except on E:ECardCryptoError do Failed:=True; end;
  Check(Failed and (Spy.DecryptCalls=0),'MAC rejection precedes every plaintext decryption');
  Retained:=nil;
  TDesfireEv2Codec.ClearKeys(Keys); Check((Length(Keys.Encryption)=0) and (Length(Keys.Authentication)=0),'Session keys cleared');
  Writeln('PASS: NXP EV2 session-key, encrypted-command/response vectors and every bit corruption.');
end;

var Provider:ICardAesProvider;
begin
  try
{$IFDEF MSWINDOWS}
    Provider:=TCardWindowsAesProvider.Create;
{$ELSE}
    Provider:=TCardOpenSslAesProvider.Create;
{$ENDIF}
    AesTests(Provider); Ev2Tests(Provider);
    Writeln('PASS: 2 crypto groups; ',Assertions,' assertions.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
