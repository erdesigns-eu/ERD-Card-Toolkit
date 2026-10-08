program EacCryptoTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Crypto, ERD.Card.Crypto.EAC,
  ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.EID.Access, ERD.Card.EID.SecureMessaging,
  ERD.Card.EID.DocumentReader, ERD.Card.EID.MRZ;
var Checks:Integer;P:ICardEacProvider;
procedure Check(const Value:Boolean;const Text:string);
begin Inc(Checks);if not Value then raise Exception.Create(Text);end;
function Ascii(const Text:AnsiString):TBytes;
var I:Integer;
begin Result:=nil;SetLength(Result,Length(Text));for I:=1 to Length(Text) do Result[I-1]:=Ord(Text[I]);end;
function MapScalar:TBytes;
begin Result:=HexToBytes('7F4EF07B9EA82FD78AD689B38D0BC78CF21F249D953BC46F4C6E19259C010F99');end;
function AgreementScalar:TBytes;
begin Result:=HexToBytes('A73FB703AC1436A18E0CFA5ABB3F7BEC7A070E7A6788486BEE230C4A22762595');end;
function CardMapping:TBytes;
begin Result:=HexToBytes('04824FBA91C9CBE26BEF53A0EBE7342A3BF178CEA9F45DE0B70AA601651FBA3F5730D8C879AAA9C9F73991E61B58F4D52EB87A0A0C709A49DC63719363CCD13C54');end;
function Nonce:TBytes;
begin Result:=HexToBytes('3F00C4D39D153F2B2A214A078D899B22');end;
procedure Primitives;
var B,K,Seed,Encoded:TBytes;I,J,Kind:Integer;Rejected:Boolean;Temporary:ICardEacProvider;
begin
  Check(BytesToHex(P.Sha1(nil))='DA39A3EE5E6B4B0D3255BFEF95601890AFD80709','SHA1 empty');
  Check(BytesToHex(P.Sha1(Ascii('abc')))='A9993E364706816ABA3E25717850C26C9CD0D89D','SHA1 published');
  Seed:=Copy(P.Sha1(Ascii('L898902C<369080619406236')),0,16);
  Check(BytesToHex(Seed)='239AB9CB282DAF66231DC5A4DF6BFBAE','ICAO BAC SHA1 seed');
  K:=TIcaoAccessCodec.DeriveKey(P,Seed,1,True);
  Check(BytesToHex(K)='AB94FDECF2674FDFB9B391F85D7F76F2','BAC encryption key');
  K:=TIcaoAccessCodec.DeriveKey(P,Seed,2,True);
  Check(BytesToHex(K)='7962D9ECE03D1ACD4C76089DCE131543','BAC MAC key');
  B:=HexToBytes('72C29C2371CC9BDB65B779B8E8D37B29ECC154AA56A8799FAE2F498F76ED92F2');
  Check(BytesToHex(TIcaoAccessCodec.RetailMac(P,K,B))='5F1448EEA8AD90A7','Published Retail MAC');
  K:=HexToBytes('2B7E151628AED2A6ABF7158809CF4F3C');
  B:=HexToBytes('6BC1BEE22E409F96E93D7E117393172A');Seed:=HexToBytes('000102030405060708090A0B0C0D0E0F');
  Encoded:=P.EncryptCbc(K,Seed,B);
  Check(BytesToHex(Encoded)='7649ABAC8119B246CEE98E9B12E9197D','NIST AES native');
  Check(BytesEqual(P.DecryptCbc(K,Seed,Encoded),B),'AES inverse');
  for Kind:=0 to 1 do
    for I:=0 to 64 do
    begin
      B:=nil;SetLength(B,I);for J:=0 to I-1 do B[J]:=J;
      Encoded:=TIcaoAccessCodec.Pad(B,8+Kind*8);
      Check(Length(Encoded)>I,'Method2 aligned extra block');
      Check(BytesEqual(TIcaoAccessCodec.Unpad(Encoded,8+Kind*8),B),'Padding roundtrip');
      Encoded[I]:=0;Rejected:=False;
      try B:=TIcaoAccessCodec.Unpad(Encoded,8+Kind*8);except on E:EIcaoAccessError do Rejected:=True;end;
      Check(Rejected,'Padding marker required');
    end;
  for I:=0 to 4 do
  begin
    Rejected:=False;
    try
      case I of
        0:B:=P.RandomBytes(0);
        1:B:=P.RandomBytes(65537);
        2:B:=P.TripleDesCbc(HexToBytes('00'),HexToBytes('00'),HexToBytes('00'),True);
        3:B:=TIcaoAccessCodec.DeriveKey(P,nil,1,False);
        4:Temporary:=TCardEacOpenSslProvider.Create('card-studio-deliberately-missing-libcrypto-3');
      end;
    except on E:Exception do Rejected:=True;end;
    Check(Rejected,'Native/provider primitive bounds/load fail');
  end;
  B:=P.RandomBytes(32);Check(Length(B)=32,'Actual native CSPRNG');
end;
procedure Passwords;
const TD1:UnicodeString='I<UTOD231458907<<<<<<<<<<<<<<<7408122F1204159UTO<<<<<<<<<<<6ERIKSSON<<ANNA<MARIA<<<<<<<<<<';
  TD2:UnicodeString='I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<D231458907UTO7408122F1204159<<<<<<<6';
  TD3:UnicodeString='P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<L898902C36UTO7408122F1204159ZE184226B<<<<<10';
var B,C:TBytes;I:Integer;Rejected:Boolean;
begin
  B:=TIcaoAccessCodec.MrzInformation(TD1);C:=TIcaoAccessCodec.MrzInformation(TD2);
  Check(BytesEqual(B,C),'TD1/TD2 identical access fields');
  Check(BytesEqual(B,Ascii('D23145890774081221204159')),'Exact TD1 access information');
  Check(BytesEqual(TIcaoAccessCodec.MrzInformation(TD3),Ascii('L898902C3674081221204159')),'Exact TD3 access information');
  TIcaoAccessCodec.ValidatePassword(Ascii('123456'),ipkCan);
  for I:=0 to High(B) do
  begin
    C:=Copy(B,0,Length(B));C[I]:=Ord('!');Rejected:=False;
    try TIcaoAccessCodec.ValidatePassword(C,ipkMrz);except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected,'Password alphabet/check field guard');
  end;
  for I:=0 to 5 do
  begin
    C:=Ascii('123456');C[I]:=Ord('A');Rejected:=False;
    try TIcaoAccessCodec.ValidatePassword(C,ipkCan);except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected,'CAN decimal only');
  end;
end;
procedure Agreements;
var C,Card:ICardPaceAgreement;Own,Other,Shared,Secret,B,ZeroNonce:TBytes;I,J:Integer;Rejected:Boolean;Curve:TCardPaceCurve;
begin
  C:=P.CreatePaceAgreement(ppcBrainpoolP256,MapScalar,AgreementScalar);
  Own:=C.MappingPublicKey;B:=C.MappingPublicKey;Own[1]:=0;
  Check(not BytesEqual(Own,B),'Independent mapping public copies');
  Own:=C.MapAndGenerate(CardMapping,Nonce);
  Check(BytesToHex(Own)='042DB7A64C0355044EC9DF190514C625CBA2CEA48754887122F3A5EF0D5EDD301C3556F3B3B186DF10B857B58F6A7EB80F20BA5DC7BE1D43D9BF850149FBB36462','Official PACE mapped agreement point');
  Shared:=C.Agree(HexToBytes('049E880F842905B8B3181F7AF7CAA9F0EFB743847F44A306D2D28C1D9EC65DF6DB7764B22277A2EDDC3C265A9F018F9CB852E111B768B326904B59A0193776F094'));
  Check(BytesToHex(Shared)='28768D20701247DAE81804C9E780EDE582A9996DB4A315020B2733197DB84925','Official PACE shared X');
  Check(BytesToHex(TIcaoAccessCodec.DeriveKey(P,Shared,1,False))='F5F0E35C0D7161EE6724EE513A0D9A7F','Official PACE encryption key');
  Check(BytesToHex(TIcaoAccessCodec.DeriveKey(P,Shared,2,False))='FE251C7858B356B24514B3BD5F4297D1','Official PACE MAC key');
  Rejected:=False;try Shared:=C.Agree(Own);except on E:ECardCryptoError do Rejected:=True;end;
  Check(Rejected,'Agreement one use');C:=nil;
  for I:=0 to 1 do
  begin
    Curve:=TCardPaceCurve(I);Secret:=AgreementScalar;
    C:=P.CreatePaceAgreement(Curve,MapScalar,Secret);
    Card:=P.CreatePaceAgreement(Curve,HexToBytes('498FF49756F2DC1587840041839A85982BE7761D14715FB091EFA7BCE9058560'),HexToBytes('107CF58696EF6155053340FD633392BA81909DF7B9706F226F32086C7AFF974A'));
    Own:=C.MappingPublicKey;Other:=Card.MappingPublicKey;
    B:=C.MapAndGenerate(Other,Nonce);Other:=Card.MapAndGenerate(Own,Nonce);
    Shared:=C.Agree(Other);Check(BytesEqual(Shared,Card.Agree(B)),'Both native curves mutual shared secret');C:=nil;Card:=nil;
    for J:=0 to 4 do
    begin
      B:=nil;SetLength(B,32);
      case J of
        1:B:=HexToBytes('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
        2:SetLength(B,31);
        3:if I=0 then B:=HexToBytes('FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551')
          else B:=HexToBytes('A9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7');
        4:SetLength(B,33);
      end;
      Rejected:=False;try C:=P.CreatePaceAgreement(Curve,B,Secret);except on E:ECardCryptoError do Rejected:=True;end;
      Check(Rejected,'Invalid scalar rejected');
    end;
    C:=P.CreatePaceAgreement(Curve,MapScalar,Secret);Own:=C.MappingPublicKey;
    Rejected:=False;try B:=C.MapAndGenerate(Own,Nonce);except on E:ECardCryptoError do Rejected:=True;end;
    Check(Rejected,'Mapping reflection refused');C:=nil;
    C:=P.CreatePaceAgreement(Curve,MapScalar,Secret);
    Other:=nil;SetLength(Other,65);Other[0]:=4;
    Rejected:=False;try B:=C.MapAndGenerate(Other,Nonce);except on E:ECardCryptoError do Rejected:=True;end;
    Check(Rejected,'Off-curve point refused');
    Rejected:=False;try B:=C.MapAndGenerate(Own,Nonce);except on E:ECardCryptoError do Rejected:=True;end;
    Check(Rejected,'Failed mapping cannot retry');
    Rejected:=False;try B:=C.Agree(Own);except on E:ECardCryptoError do Rejected:=True;end;
    Check(Rejected,'Failed mapping cannot continue to agreement');C:=nil;
    C:=P.CreatePaceAgreement(Curve,MapScalar,Secret);
    Card:=P.CreatePaceAgreement(Curve,HexToBytes('498FF49756F2DC1587840041839A85982BE7761D14715FB091EFA7BCE9058560'),HexToBytes('107CF58696EF6155053340FD633392BA81909DF7B9706F226F32086C7AFF974A'));
    Own:=C.MappingPublicKey;Other:=Card.MappingPublicKey;ZeroNonce:=nil;SetLength(ZeroNonce,16);
    B:=C.MapAndGenerate(Other,ZeroNonce);Other:=Card.MapAndGenerate(Own,ZeroNonce);
    Check(BytesEqual(C.Agree(Other),Card.Agree(B)),'Valid zero nonce maps to nonzero mutual group element');C:=nil;Card:=nil;
    C:=P.CreatePaceAgreement(Curve,MapScalar,Secret);
    Card:=P.CreatePaceAgreement(Curve,HexToBytes('498FF49756F2DC1587840041839A85982BE7761D14715FB091EFA7BCE9058560'),Secret);
    B:=C.MapAndGenerate(Card.MappingPublicKey,Nonce);
    Rejected:=False;try Shared:=C.Agree(B);except on E:ECardCryptoError do Rejected:=True;end;
    Check(Rejected,'Agreement reflection refused');C:=nil;Card:=nil;
  end;
  // Agreement retains the provider/library after the host drops its interface.
  C:=P.CreatePaceAgreement(ppcBrainpoolP256,MapScalar,AgreementScalar);P:=nil;
  Check(Length(C.MappingPublicKey)=65,'Native library retained by agreement');C:=nil;P:=TCardEacOpenSslProvider.Create;
end;
function BacSecure(const Counter:TBytes):TIcaoSecureMessaging;
begin Result:=TIcaoSecureMessaging.Create(P,iasBac,HexToBytes('979EC13B1CBFE9DCD01AB0FED307EAE5'),HexToBytes('F1CB1F1FB5ADF208806B89DC579DC1F8'),Counter);end;
procedure SecureMessages;
var S:TIcaoSecureMessaging;C:TApduCommand;R:TApduResponse;B,Counter:TBytes;I:Integer;Rejected:Boolean;
begin
  C:=Default(TApduCommand);C.INS:=$A4;C.P1:=2;C.P2:=$0C;C.Data:=HexToBytes('011E');
  S:=BacSecure(HexToBytes('887022120C06C226'));
  try
    B:=S.Protect(C);Check(BytesToHex(B)='0CA4020C158709016375432908C044F68E08BF8B92D635FF24F800','ICAO Appendix D protected SELECT');
    R:=S.Unprotect(HexToBytes('990290008E08FA855A5D4C50A8ED9000'));
    Check((R.StatusWord=$9000) and (Length(R.Data)=0),'Official protected acknowledgement');
    C:=Default(TApduCommand);C.INS:=$B0;C.HasLe:=True;C.Le:=4;
    Check(BytesToHex(S.Protect(C))='0CB000000D9701048E08ED6705417E96BA5500','Official protected READ');
    R:=S.Unprotect(HexToBytes('8709019FF0EC34F9922651990290008E08AD55CC17140B2DED9000'));
    Check(BytesToHex(R.Data)='60145F01','Official decrypted response');
  finally S.Free;end;
  C:=Default(TApduCommand);C.INS:=$A4;C.P1:=2;C.P2:=$0C;C.Data:=HexToBytes('011E');
  B:=HexToBytes('990290008E08FA855A5D4C50A8ED9000');
  for I:=0 to Length(B)-1 do
  begin
    S:=BacSecure(HexToBytes('887022120C06C226'));
    try
      S.Protect(C);Rejected:=False;
      try R:=S.Unprotect(Copy(B,0,I));except on E:EIcaoAccessError do Rejected:=True;end;
      Check(Rejected and not S.Active,'Every truncated response poisons session');
    finally S.Free;end;
  end;
  for I:=0 to 1 do
  begin
    Counter:=HexToBytes('FFFFFFFFFFFFFFFF');if I=1 then Counter[7]:=$FE;
    S:=BacSecure(Counter);
    try
      Rejected:=False;
      try S.Protect(C);if I=1 then R:=S.Unprotect(B);except on E:EIcaoAccessError do Rejected:=True;end;
      Check(Rejected and not S.Active,'No SSC wrap before command/response');
    finally S.Free;end;
  end;
end;
procedure CardAccess;
var Infos:TIcaoPaceInfos;I:Integer;Rejected:Boolean;B:TBytes;
const Valid:string='31143012060A04007F0007020204020202010202010D';
begin
  Infos:=TIcaoCardAccessCodec.Decode(HexToBytes(Valid));
  Check((Length(Infos)=1) and Infos[0].Supported and (Infos[0].ParameterId=13),'Exact PACE v2 parameter 13');
  Infos[0].AlgorithmOid[0]:=0;Infos:=TIcaoCardAccessCodec.Decode(HexToBytes(Valid));
  Check(Infos[0].AlgorithmOid[0]=4,'CardAccess owns decoded info');
  Infos:=TIcaoCardAccessCodec.Decode(HexToBytes('3100'));Check(Length(Infos)=0,'No advertised PACE remains explicit');
  Infos:=TIcaoCardAccessCodec.Decode(HexToBytes('31143012060A04007F0007020204020202010302010D'));
  Check(not Infos[0].Supported and (Infos[0].Version=3),'Unknown PACE version preserved');
  Infos:=TIcaoCardAccessCodec.Decode(HexToBytes('31143012060A04007F00070202040202020102020110'));
  Check(not Infos[0].Supported and (Infos[0].ParameterId=16),'Unknown domain parameter preserved');
  Infos:=TIcaoCardAccessCodec.Decode(HexToBytes('3111300F060A04007F00070202040202020102'));
  Check(not Infos[0].Supported and (Infos[0].ParameterId=-1),'Missing parameter is not guessed');
  for I:=0 to 8 do
  begin
    case I of
      0:B:=nil;
      1:B:=HexToBytes('3181143012060A04007F0007020204020202010202010D');
      2:B:=HexToBytes('31143012060A04007F0007020204020202018202010D');
      3:B:=HexToBytes('31153013060A04007F000702020402020202000202010D');
      4:B:=HexToBytes('31283012060A04007F0007020204020202010202010D3012060A04007F0007020204020202010202010D');
      5:B:=HexToBytes('31283012060A04007F0007020204020202010202010D3012060A04007F0007020204020202010202010C');
      6:B:=HexToBytes('31143012060A04007F0007020204020202010002010D');
      7:B:=HexToBytes(Valid+'00');
      8:B:=HexToBytes('30800000');
    end;
    Rejected:=False;try Infos:=TIcaoCardAccessCodec.Decode(B);except on E:EIcaoAccessError do Rejected:=True;end;
    Check(Rejected,'Invalid/ambiguous/noncanonical CardAccess rejected');
  end;
end;
begin
  try
    P:=TCardEacOpenSslProvider.Create;Primitives;Passwords;Agreements;SecureMessages;CardAccess;P:=nil;
    Writeln('PASS: native EAC primitives, official ICAO BAC/PACE vectors, both curves, invalid points/scalars and secure-message counters/padding.');
    Writeln('Assertions: ',Checks);
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
