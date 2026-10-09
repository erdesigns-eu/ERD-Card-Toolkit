unit ERD.Card.Contactless.DESFire.DES;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Crypto.DES,ERD.Card.Contactless.DESFire.EV2;
type
  /// <summary>Explicit DESFire ISO-3DES versus D40 legacy session-key and native-message composition.</summary>
  /// <remarks>No primitive cipher or card I/O. ISO authentication uses chained CMAC/CRC32; legacy
  /// authentication uses reset-IV CBC-MAC/CRC16 and inverse send transforms. Never mix these dialects.</remarks>
  TDesfireDesCodec=class
  public
    /// <summary>Derives DES/2K3DES/3K3DES session material from explicitly sized authenticated nonces.</summary>
    /// <param name="ARndA">Fresh reader nonce, eight bytes for DES/2K3DES, sixteen for 3K3DES.</param>
    /// <param name="ARndB">Card nonce with the same exact size.</param>
    /// <param name="AKeyBytes">Explicit selected key type: 8, 16 or 24 bytes.</param>
    /// <returns>Independent 8/16/24-byte session key using the profile's nonce slices.</returns>
    class function DeriveKey(const ARndA,ARndB:TBytes;const AKeyBytes:Integer):TBytes;static;
    /// <summary>Encodes a complete native command using the selected DES dialect.</summary>
    /// <param name="AProvider">Maintained DES backend.</param>
    /// <param name="AKey">Owned session key: 8/16 legacy or 16/24 ISO bytes.</param>
    /// <param name="AIv">Eight exclusively owned ISO chaining bytes; legacy resets per message.</param>
    /// <param name="ACommand">Native instruction without wrapping or AF frames.</param>
    /// <param name="AHeader">Clear header, zero through 32 bytes.</param>
    /// <param name="AData">Write body, up to 1048500 bytes; empty for reads.</param>
    /// <param name="AMode">Acquired file communication mode.</param>
    /// <param name="AWrite">True secures a write body; false updates only ISO command CMAC.</param>
    /// <param name="ALegacy">True selects D40 CRC16/CBC-MAC/inverse-send; false selects ISO CRC32/CMAC.</param>
    /// <returns>Owned wire data; ISO IV advances only after successful encoding.</returns>
    class function EncodeCommand(const AProvider:ICardDesProvider;const AKey:TBytes;var AIv:TBytes;
      const ACommand:Byte;const AHeader,AData:TBytes;const AMode:TDesfireCommunication;
      const AWrite,ALegacy:Boolean):TBytes;static;
    /// <summary>Validates one complete successful native response before returning plaintext.</summary>
    /// <param name="AProvider">Maintained DES backend.</param>
    /// <param name="AKey">Explicit session key.</param>
    /// <param name="AIv">Eight owned ISO command-IV bytes; unchanged on validation failure.</param>
    /// <param name="AData">Complete response excluding final 9100.</param>
    /// <param name="AMode">Response mode; ISO metadata/acks use MACed, legacy metadata/acks Plain.</param>
    /// <param name="AExpectedBytes">Exact expected plaintext length, zero through 1048500.</param>
    /// <param name="ALegacy">True uses legacy four-byte MAC/CRC16; false uses eight-byte CMAC/CRC32.</param>
    /// <returns>Independent validated data; no plaintext escapes integrity/padding failures.</returns>
    class function DecodeResponse(const AProvider:ICardDesProvider;const AKey:TBytes;var AIv:TBytes;
      const AData:TBytes;const AMode:TDesfireCommunication;const AExpectedBytes:Integer;
      const ALegacy:Boolean):TBytes;static;
  end;
implementation
uses ERD.Card.Bytes,ERD.Card.Crypto,ERD.Card.Contactless.Raw,ERD.Card.Contactless.DESFire.EV1;
procedure Invalid;
begin raise ECardCryptoError.Create('Invalid DESFire DES secure message.');end;
function Join(const A,B:TBytes):TBytes;
begin Result:=nil;SetLength(Result,Length(A)+Length(B));if Length(A)>0 then Move(A[0],Result[0],Length(A));if Length(B)>0 then Move(B[0],Result[Length(A)],Length(B));end;
function Crc16(const B:TBytes):TBytes;
var V:Word;I,J:Integer;
begin
 V:=$6363;for I:=0 to High(B) do begin V:=V xor B[I];for J:=1 to 8 do if V and 1<>0 then V:=(V shr 1) xor $8408 else V:=V shr 1;end;
 Result:=nil;SetLength(Result,2);Result[0]:=V and $FF;Result[1]:=V shr 8;
end;
procedure Validate(const P:ICardDesProvider;const K,V:TBytes;const M:TDesfireCommunication;const Legacy:Boolean);
begin
 if (P=nil) or (Length(V)<>8) or (Ord(M)<0) or (Ord(M)>Ord(High(TDesfireCommunication))) then Invalid;
 if Legacy then begin if not (Length(K) in [8,16]) then Invalid;end
 else if not (Length(K) in [16,24]) then Invalid;
end;
function LegacyMac(const P:ICardDesProvider;const K,B:TBytes):TBytes;
var Zero,Body,Cipher:TBytes;N:Integer;
begin
 Result:=nil;Zero:=nil;Body:=nil;Cipher:=nil;
 try
  N:=((Length(B)+7) div 8)*8;if N=0 then N:=8;SetLength(Zero,8);SetLength(Body,N);
  if Length(B)>0 then Move(B[0],Body[0],Length(B));Cipher:=TCardDesCrypto.Crypt(P,K,Zero,Body,True);
  Result:=Copy(Cipher,N-8,4);
 finally TCardCrypto.Clear(Zero);TCardCrypto.Clear(Body);TCardCrypto.Clear(Cipher);end;
end;
class function TDesfireDesCodec.DeriveKey(const ARndA,ARndB:TBytes;const AKeyBytes:Integer):TBytes;
var N:Integer;
begin
 Result:=nil;if not (AKeyBytes in [8,16,24]) then Invalid;N:=8;if AKeyBytes=24 then N:=16;
 if (Length(ARndA)<>N) or (Length(ARndB)<>N) then Invalid;
 SetLength(Result,AKeyBytes);Move(ARndA[0],Result[0],4);Move(ARndB[0],Result[4],4);
 if AKeyBytes=16 then begin Move(ARndA[4],Result[8],4);Move(ARndB[4],Result[12],4);end;
 if AKeyBytes=24 then begin Move(ARndA[6],Result[8],4);Move(ARndB[6],Result[12],4);Move(ARndA[12],Result[16],4);Move(ARndB[12],Result[20],4);end;
end;
class function TDesfireDesCodec.EncodeCommand(const AProvider:ICardDesProvider;const AKey:TBytes;var AIv:TBytes;
 const ACommand:Byte;const AHeader,AData:TBytes;const AMode:TDesfireCommunication;const AWrite,ALegacy:Boolean):TBytes;
var Vector,Body,Crc,NextIv,Mac:TBytes;N:Integer;
begin
 Result:=nil;Validate(AProvider,AKey,AIv,AMode,ALegacy);
 if (Length(AHeader)>32) or (Length(AData)>1048500) or (not AWrite and (Length(AData)<>0)) or (AWrite and (Length(AData)=0)) then Invalid;
 Vector:=nil;Body:=nil;Crc:=nil;NextIv:=nil;Mac:=nil;
 try
  SetLength(Vector,1);Vector[0]:=ACommand;Vector:=Join(Vector,Join(AHeader,AData));
  if AWrite and (AMode=dfcFull) then begin
   if ALegacy then Crc:=Crc16(AData) else Crc:=TDesfireEv1Codec.Crc32(Vector);
   N:=((Length(AData)+Length(Crc)+7) div 8)*8;SetLength(Body,N);Move(AData[0],Body[0],Length(AData));Move(Crc[0],Body[Length(AData)],Length(Crc));
   if ALegacy then Result:=TCardDesCrypto.LegacySend(AProvider,AKey,Body)
   else begin Result:=TCardDesCrypto.Crypt(AProvider,AKey,AIv,Body,True);NextIv:=Copy(Result,N-8,8);end;
   Result:=Join(AHeader,Result);
  end else begin
   Result:=Join(AHeader,AData);
   if ALegacy then begin if AWrite and (AMode=dfcMac) then begin Mac:=LegacyMac(AProvider,AKey,AData);Result:=Join(Result,Mac);end;end
   else begin NextIv:=TCardDesCrypto.CmacChained(AProvider,AKey,AIv,Vector);if AWrite and (AMode=dfcMac) then Result:=Join(Result,NextIv);end;
  end;
  if not ALegacy then begin TCardCrypto.Clear(AIv);AIv:=NextIv;NextIv:=nil;end;
 finally TCardCrypto.Clear(Vector);TCardCrypto.Clear(Body);TCardCrypto.Clear(Crc);TCardCrypto.Clear(NextIv);TCardCrypto.Clear(Mac);end;
end;
class function TDesfireDesCodec.DecodeResponse(const AProvider:ICardDesProvider;const AKey:TBytes;var AIv:TBytes;
 const AData:TBytes;const AMode:TDesfireCommunication;const AExpectedBytes:Integer;const ALegacy:Boolean):TBytes;
var Plain,Vector,Crc,NextIv,Mac,Zero:TBytes;I,N,Size,MacBytes:Integer;
begin
 Result:=nil;Validate(AProvider,AKey,AIv,AMode,ALegacy);if (AExpectedBytes<0) or (AExpectedBytes>1048500) then Invalid;
 Plain:=nil;Vector:=nil;Crc:=nil;NextIv:=nil;Mac:=nil;Zero:=nil;
 try
  if AMode=dfcFull then begin
   Size:=4;if ALegacy then Size:=2;N:=((AExpectedBytes+Size+7) div 8)*8;if Length(AData)<>N then Invalid;
   SetLength(Zero,8);if ALegacy then Plain:=TCardDesCrypto.Crypt(AProvider,AKey,Zero,AData,False)
   else begin Plain:=TCardDesCrypto.Crypt(AProvider,AKey,AIv,AData,False);NextIv:=Copy(AData,N-8,8);end;
   Vector:=Copy(Plain,0,AExpectedBytes);
   if ALegacy then Crc:=Crc16(Vector) else begin SetLength(Vector,AExpectedBytes+1);Vector[AExpectedBytes]:=0;Crc:=TDesfireEv1Codec.Crc32(Vector);end;
   if not TCardCrypto.EqualSecret(Crc,Copy(Plain,AExpectedBytes,Size)) then Invalid;
   for I:=AExpectedBytes+Size to N-1 do if (Plain[I]<>0) and not ((I=AExpectedBytes+Size) and (Plain[I]=$80)) then Invalid;
   Result:=Copy(Plain,0,AExpectedBytes);
  end else if ALegacy then begin
   MacBytes:=0;if AMode=dfcMac then MacBytes:=4;if Length(AData)<>AExpectedBytes+MacBytes then Invalid;
   Plain:=Copy(AData,0,AExpectedBytes);
   if MacBytes>0 then begin Mac:=LegacyMac(AProvider,AKey,Plain);if not TCardCrypto.EqualSecret(Mac,Copy(AData,AExpectedBytes,4)) then Invalid;end;
   Result:=CopyBytes(Plain);
  end else begin
   if Length(AData)<>AExpectedBytes+8 then Invalid;Vector:=Copy(AData,0,AExpectedBytes);SetLength(Vector,AExpectedBytes+1);Vector[AExpectedBytes]:=0;
   NextIv:=TCardDesCrypto.CmacChained(AProvider,AKey,AIv,Vector);
   if not TCardCrypto.EqualSecret(NextIv,Copy(AData,AExpectedBytes,8)) then Invalid;Result:=Copy(AData,0,AExpectedBytes);
  end;
  if not ALegacy then begin TCardCrypto.Clear(AIv);AIv:=NextIv;NextIv:=nil;end;
 finally TCardCrypto.Clear(Plain);TCardCrypto.Clear(Vector);TCardCrypto.Clear(Crc);TCardCrypto.Clear(NextIv);TCardCrypto.Clear(Mac);TCardCrypto.Clear(Zero);end;
end;
end.
