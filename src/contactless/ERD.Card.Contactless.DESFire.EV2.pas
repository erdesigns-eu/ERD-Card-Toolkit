unit ERD.Card.Contactless.DESFire.EV2;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Crypto;

type
  /// <summary>Explicit native DESFire file communication mode; codecs interpret it for their selected generation.</summary>
  TDesfireCommunication = (
    /// <summary>Plain file mode; EV2 has no transmitted MAC, while EV1 AES responses remain CMAC protected.</summary>
    dfcPlain,
    /// <summary>MACed file mode; generation-specific codec determines framing and truncation.</summary>
    dfcMac,
    /// <summary>Full encrypted file mode; EV1 AES uses CRC32, EV2 uses method-two padding and AES-CMAC.</summary>
    dfcFull
  );
  /// <summary>Owned EV2 AES session keys derived from the caller's authentication key and both fresh nonces.</summary>
  /// <remarks>Secret arrays share storage on ordinary assignment. Clear exclusively owned copies after use.</remarks>
  TDesfireEv2Keys = record
    /// <summary>Independent 16-byte encryption key; never log.</summary>
    Encryption: TBytes;
    /// <summary>Independent 16-byte authentication key; never log.</summary>
    Authentication: TBytes;
  end;
  /// <summary>Pure EV2 AES key derivation and secure-message framing through a maintained AES provider.</summary>
  /// <remarks>AN12343 section 7.1; no card I/O. Caller owns command-counter lifecycle and never reuses a failed session.
  /// MAC verification precedes decryption. Does not implement D40, EV1 secure messaging or LRP.</remarks>
  TDesfireEv2Codec = class
  public
    /// <summary>Derives independent AES ENC/MAC session keys using NXP's EV2 CMAC vectors.</summary>
    /// <param name="AProvider">Retained maintained AES backend.</param>
    /// <param name="AKey">Exactly 16 caller-owned authentication bytes.</param>
    /// <param name="ARndA">Exactly 16 freshly generated reader bytes.</param>
    /// <param name="ARndB">Exactly 16 independently decrypted card bytes.</param>
    /// <returns>Independent secret keys; caller clears them after the session.</returns>
    /// <exception cref="ECardCryptoError">Sizes or provider fail.</exception>
    class function DeriveKeys(const AProvider: ICardAesProvider;
      const AKey, ARndA, ARndB: TBytes): TDesfireEv2Keys; static;
    /// <summary>Builds command data, leaving header clear and adding encryption/MAC according to the explicit mode.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKeys">Owned session keys, not modified.</param>
    /// <param name="ATi">Exactly four acquired transaction-identifier bytes.</param>
    /// <param name="ACounter">Current command counter, 0..65534; no wraparound.</param>
    /// <param name="ACommand">Native instruction; additional frames are handled outside the MAC calculation.</param>
    /// <param name="AHeader">Clear native command header.</param>
    /// <param name="AData">Plain command body; empty read bodies are not padded/encrypted.</param>
    /// <param name="AMode">Explicit Plain, MACed or Full communication.</param>
    /// <returns>Independent header/body/MAC data, excluding ISO wrapping.</returns>
    /// <exception cref="ECardCryptoError">Arguments, bounds or provider fail.</exception>
    class function EncodeCommand(const AProvider: ICardAesProvider; const AKeys: TDesfireEv2Keys;
      const ATi: TBytes; const ACounter: Integer; const ACommand: Byte;
      const AHeader, AData: TBytes; const AMode: TDesfireCommunication): TBytes; static;
    /// <summary>Verifies the complete successful response before releasing plaintext.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKeys">Owned session keys, not modified.</param>
    /// <param name="ATi">Exactly four acquired transaction-identifier bytes.</param>
    /// <param name="ACounter">Response counter after exactly one increment, 1..65535.</param>
    /// <param name="AData">Complete concatenated response data, excluding status 9100.</param>
    /// <param name="AMode">Explicit communication mode used for the command.</param>
    /// <param name="AExpectedBytes">Exact plaintext size, 0..1048500; padding and length must agree.</param>
    /// <returns>Independent verified plaintext; empty for a successful write acknowledgement.</returns>
    /// <exception cref="ECardCryptoError">MAC, padding, sizes, counter or provider fail.</exception>
    class function DecodeResponse(const AProvider: ICardAesProvider; const AKeys: TDesfireEv2Keys;
      const ATi: TBytes; const ACounter: Integer; const AData: TBytes;
      const AMode: TDesfireCommunication; const AExpectedBytes: Integer): TBytes; static;
    /// <summary>Clears both exclusively owned session-key buffers.</summary>
    /// <param name="AKeys">Owned secret keys; aliases observe overwriting.</param>
    class procedure ClearKeys(var AKeys: TDesfireEv2Keys); static;
  end;

implementation

procedure CryptoError;
begin raise ECardCryptoError.Create('Invalid DESFire EV2 secure message or authentication data.'); end;

function Join(const A,B:TBytes):TBytes;
begin
  Result:=nil; SetLength(Result,Length(A)+Length(B));
  if Length(A)>0 then Move(A[0],Result[0],Length(A));
  if Length(B)>0 then Move(B[0],Result[Length(A)],Length(B));
end;

procedure Validate(const P:ICardAesProvider; const K:TDesfireEv2Keys;
  const Ti:TBytes; const Counter:Integer; const Mode:TDesfireCommunication);
begin
  if (P=nil) or (Length(K.Encryption)<>16) or (Length(K.Authentication)<>16) or
    (Length(Ti)<>4) or (Counter<0) or (Counter>65535) or
    (Ord(Mode)<0) or (Ord(Mode)>Ord(High(TDesfireCommunication))) then CryptoError;
end;

function Prefix(const Code:Byte; const Counter:Integer; const Ti:TBytes):TBytes;
begin
  Result:=nil; SetLength(Result,7); Result[0]:=Code;
  Result[1]:=Counter and $FF; Result[2]:=Counter shr 8; Move(Ti[0],Result[3],4);
end;

function Mac8(const P:ICardAesProvider; const Key,Data:TBytes):TBytes;
var Full:TBytes; I:Integer;
begin
  Result:=nil; Full:=TCardCrypto.Cmac(P,Key,Data);
  try
    SetLength(Result,8); for I:=0 to 7 do Result[I]:=Full[2*I+1];
  finally TCardCrypto.Clear(Full); end;
end;

function Iv(const P:ICardAesProvider; const K,Ti:TBytes; const Counter:Integer;
  const Response:Boolean):TBytes;
var Pattern,Zero:TBytes;
begin
  Result:=nil; Pattern:=nil; Zero:=nil;
  try
    SetLength(Pattern,16); SetLength(Zero,16);
    Pattern[0]:=$A5; Pattern[1]:=$5A;
    if Response then begin Pattern[0]:=$5A; Pattern[1]:=$A5; end;
    Move(Ti[0],Pattern[2],4); Pattern[6]:=Counter and $FF; Pattern[7]:=Counter shr 8;
    Result:=P.EncryptCbc(K,Zero,Pattern); if Length(Result)<>16 then CryptoError;
  finally TCardCrypto.Clear(Pattern); TCardCrypto.Clear(Zero); end;
end;

class function TDesfireEv2Codec.DeriveKeys(const AProvider:ICardAesProvider;
  const AKey,ARndA,ARndB:TBytes):TDesfireEv2Keys;
var Vector:TBytes; I:Integer; Success:Boolean;
begin
  Result:=Default(TDesfireEv2Keys); Vector:=nil; Success:=False;
  if (AProvider=nil) or (Length(AKey)<>16) or (Length(ARndA)<>16) or (Length(ARndB)<>16) then CryptoError;
  try
    SetLength(Vector,32); Vector[0]:=$A5; Vector[1]:=$5A;
    Vector[2]:=0; Vector[3]:=1; Vector[4]:=0; Vector[5]:=$80;
    Move(ARndA[0],Vector[6],2);
    for I:=0 to 5 do Vector[8+I]:=ARndA[2+I] xor ARndB[I];
    Move(ARndB[6],Vector[14],10); Move(ARndA[8],Vector[24],8);
    Result.Encryption:=TCardCrypto.Cmac(AProvider,AKey,Vector);
    Vector[0]:=$5A; Vector[1]:=$A5;
    Result.Authentication:=TCardCrypto.Cmac(AProvider,AKey,Vector); Success:=True;
  finally
    TCardCrypto.Clear(Vector); if not Success then ClearKeys(Result);
  end;
end;

class function TDesfireEv2Codec.EncodeCommand(const AProvider:ICardAesProvider;
  const AKeys:TDesfireEv2Keys; const ATi:TBytes; const ACounter:Integer;
  const ACommand:Byte; const AHeader,AData:TBytes; const AMode:TDesfireCommunication):TBytes;
var Body,Padded,Vector,Mac,Initial:TBytes;
begin
  Result:=nil; Validate(AProvider,AKeys,ATi,ACounter,AMode);
  if (ACounter=65535) or (Length(AHeader)>32) or (Length(AData)>1048500) then CryptoError;
  Body:=nil; Padded:=nil; Vector:=nil; Mac:=nil; Initial:=nil;
  try
    if (AMode=dfcFull) and (Length(AData)>0) then
    begin
      SetLength(Padded,((Length(AData) div 16)+1)*16);
      Move(AData[0],Padded[0],Length(AData)); Padded[Length(AData)]:=$80;
      Initial:=Iv(AProvider,AKeys.Encryption,ATi,ACounter,False);
      Body:=AProvider.EncryptCbc(AKeys.Encryption,Initial,Padded);
      if Length(Body)<>Length(Padded) then CryptoError;
    end
    else Body:=Copy(AData,0,Length(AData));
    Result:=Join(AHeader,Body);
    if AMode<>dfcPlain then
    begin
      Vector:=Join(Prefix(ACommand,ACounter,ATi),Result);
      Mac:=Mac8(AProvider,AKeys.Authentication,Vector); Result:=Join(Result,Mac);
    end;
  finally
    TCardCrypto.Clear(Body); TCardCrypto.Clear(Padded); TCardCrypto.Clear(Vector);
    TCardCrypto.Clear(Mac); TCardCrypto.Clear(Initial);
  end;
end;

class function TDesfireEv2Codec.DecodeResponse(const AProvider:ICardAesProvider;
  const AKeys:TDesfireEv2Keys; const ATi:TBytes; const ACounter:Integer;
  const AData:TBytes; const AMode:TDesfireCommunication; const AExpectedBytes:Integer):TBytes;
var Body,Vector,ExpectedMac,ReceivedMac,Plain,Initial:TBytes; I,ExpectedWire:Integer;
begin
  Result:=nil; Validate(AProvider,AKeys,ATi,ACounter,AMode);
  if (ACounter<1) or (AExpectedBytes<0) or (AExpectedBytes>1048500) or (Length(AData)>1048560) then CryptoError;
  Body:=nil; Vector:=nil; ExpectedMac:=nil; ReceivedMac:=nil; Plain:=nil; Initial:=nil;
  try
    if AMode=dfcPlain then Body:=Copy(AData,0,Length(AData))
    else
    begin
      if Length(AData)<8 then CryptoError;
      Body:=Copy(AData,0,Length(AData)-8); ReceivedMac:=Copy(AData,Length(AData)-8,8);
      Vector:=Join(Prefix(0,ACounter,ATi),Body); ExpectedMac:=Mac8(AProvider,AKeys.Authentication,Vector);
      if not TCardCrypto.EqualSecret(ExpectedMac,ReceivedMac) then CryptoError;
    end;
    if (AMode=dfcFull) and (AExpectedBytes>0) then
    begin
      ExpectedWire:=((AExpectedBytes div 16)+1)*16;
      if Length(Body)<>ExpectedWire then CryptoError;
      Initial:=Iv(AProvider,AKeys.Encryption,ATi,ACounter,True);
      Plain:=AProvider.DecryptCbc(AKeys.Encryption,Initial,Body);
      if Length(Plain)<>ExpectedWire then CryptoError;
      if Plain[AExpectedBytes]<>$80 then CryptoError;
      for I:=AExpectedBytes+1 to High(Plain) do if Plain[I]<>0 then CryptoError;
      Result:=Copy(Plain,0,AExpectedBytes);
    end
    else
    begin
      if Length(Body)<>AExpectedBytes then CryptoError;
      Result:=Copy(Body,0,Length(Body));
    end;
  finally
    TCardCrypto.Clear(Body); TCardCrypto.Clear(Vector); TCardCrypto.Clear(ExpectedMac);
    TCardCrypto.Clear(ReceivedMac); TCardCrypto.Clear(Plain); TCardCrypto.Clear(Initial);
  end;
end;

class procedure TDesfireEv2Codec.ClearKeys(var AKeys:TDesfireEv2Keys);
begin TCardCrypto.Clear(AKeys.Encryption); TCardCrypto.Clear(AKeys.Authentication); end;

end.
