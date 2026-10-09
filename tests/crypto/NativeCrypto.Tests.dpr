program NativeCryptoTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
uses SysUtils, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.DES, ERD.Card.Crypto.Windows;
function test_crypto_live:Integer; cdecl; external 'bcrypt.dll';
function test_crypto_calls:Integer; cdecl; external 'bcrypt.dll';
procedure test_crypto_reset(Fail,Wrong:Integer); cdecl; external 'bcrypt.dll';
var Assertions:Integer; P:ICardAesProvider; Des:ICardDesProvider; Key,Iv,Plain,Data,Original:TBytes;
  I,Mode:Integer; Failed:Boolean;
procedure Check(const Condition:Boolean; const Text:string);
begin Inc(Assertions); if not Condition then raise Exception.Create(Text); end;
begin
  try
    P:=TCardWindowsAesProvider.Create;
    Key:=HexToBytes('2B7E151628AED2A6ABF7158809CF4F3C'); Iv:=HexToBytes('000102030405060708090A0B0C0D0E0F');
    Original:=CopyBytes(Iv); Plain:=HexToBytes('6BC1BEE22E409F96E93D7E117393172A');
    test_crypto_reset(0,0); Data:=P.EncryptCbc(Key,Iv,Plain);
    Check(BytesEqual(Data,HexToBytes('7649ABAC8119B246CEE98E9B12E9197D')),'Native NIST CBC encrypt');
    Check(BytesEqual(P.DecryptCbc(Key,Iv,Data),Plain),'Native NIST CBC decrypt');
    Check(BytesEqual(Iv,Original),'Native IV mutation never touches caller');
    Check(test_crypto_live=0,'Native handles released');
    for Mode:=0 to 1 do
      for I:=1 to 7 do
      begin
        test_crypto_reset(I,0); Failed:=False;
        try if Mode=0 then Data:=P.EncryptCbc(Key,Iv,Plain) else Data:=P.DecryptCbc(Key,Iv,Plain);
        except on E:ECardCryptoError do Failed:=True; end;
        Check(Failed,'Every CNG native failure surfaces'); Check(test_crypto_live=0,'No native handle leaked');
        Check(BytesEqual(Iv,Original),'IV preserved on every failure');
      end;
    for I:=1 to 2 do
    begin
      test_crypto_reset(0,I); Failed:=False;
      try Data:=P.EncryptCbc(Key,Iv,Plain); except on E:ECardCryptoError do Failed:=True; end;
      Check(Failed and (test_crypto_live=0),'Native length mismatch cleans resources');
    end;
    test_crypto_reset(1,0); Failed:=False;
    try Data:=P.RandomBytes(16); except on E:ECardCryptoError do Failed:=True; end;
    Check(Failed and (test_crypto_calls=1),'CSPRNG failure never falls back');
    test_crypto_reset(0,0); Data:=P.RandomBytes(16); Check(Length(Data)=16,'Native system RNG argument forwarding');
    Failed:=False; try Data:=P.EncryptCbc(nil,Iv,Plain); except on E:ECardCryptoError do Failed:=True; end;
    Check(Failed and (test_crypto_calls=1),'Invalid key rejected before native call');
    Check(Supports(P,ICardDesProvider,Des),'Optional DES capability');
    Key:=HexToBytes('0123456789ABCDEFFEDCBA98765432100123456789ABCDEF');
    Iv:=HexToBytes('0000000000000000');Plain:=CopyBytes(Iv);Original:=CopyBytes(Iv);
    test_crypto_reset(0,0);Data:=Des.TripleDesCbc(Key,Iv,Plain,True);
    Check(BytesToHex(Data)='08D7B4FB629D0885','Native EDE known-answer block');
    Check(BytesEqual(Des.TripleDesCbc(Key,Iv,Data,False),Plain),'Native EDE decrypt');
    Check(BytesEqual(Iv,Original) and (test_crypto_live=0),'DES preserves IV and releases native handles');
    for Mode:=0 to 1 do for I:=1 to 7 do begin
      test_crypto_reset(I,0);Failed:=False;
      try Data:=Des.TripleDesCbc(Key,Iv,Plain,Mode=0);except on E:ECardCryptoError do Failed:=True;end;
      Check(Failed and (test_crypto_live=0) and BytesEqual(Iv,Original),'Every DES native failure cleans up');
    end;
    for I:=1 to 2 do begin
      test_crypto_reset(0,I);Failed:=False;
      try Data:=Des.TripleDesCbc(Key,Iv,Plain,True);except on E:ECardCryptoError do Failed:=True;end;
      Check(Failed and (test_crypto_live=0),'DES native length mismatch');
    end;
    test_crypto_reset(0,0);Failed:=False;
    try Data:=Des.TripleDesCbc(nil,Iv,Plain,True);except on E:ECardCryptoError do Failed:=True;end;
    Check(Failed and (test_crypto_calls=0),'Invalid DES arguments fail before native calls');
    Writeln('PASS: ',Assertions,' assertions against Linux native CNG ABI shim.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
