unit ERD.Card.EID.SecureMessaging;

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
  ERD.Card.APDU, ERD.Card.Crypto, ERD.Card.Crypto.EAC, ERD.Card.EID.Access;

type
  /// <summary>Owned stateful ICAO BAC/PACE secure messaging; plaintext is returned only after full response integrity checks.</summary>
  /// <remarks>One caller thread, no interleaved commands. This codec does not exchange APDUs, retry or recover.
  /// Cryptographic/response-protocol failures clear the session; invalid local Protect arguments preserve it.
  /// The transport owner must also discard it after I/O failure.</remarks>
  TIcaoSecureMessaging = class
  private
    FProvider: ICardEacProvider;
    FEnc, FMac, FCounter: TBytes;
    FSecurity: TIcaoAccessSecurity;
    FActive, FPending: Boolean;
    FInstruction: Byte;
    procedure IncrementCounter;
    function InitialVector: TBytes;
    function Crypt(const Data: TBytes; const Encrypt: Boolean): TBytes;
    function Mac(const Data: TBytes): TBytes;
    function BlockBytes: Integer;
  public
    /// <summary>Copies supplied session secrets and retains a maintained provider; performs no card I/O.</summary>
    /// <param name="AProvider">Non-nil native backend.</param>
    /// <param name="ASecurity">Explicit BAC or implemented PACE AES profile.</param>
    /// <param name="AEncryptionKey">Exact 16-byte derived session key.</param>
    /// <param name="AMacKey">Exact 16-byte derived MAC key.</param>
    /// <param name="ACounter">BAC's eight-byte initial SSC, or PACE's sixteen zero bytes.</param>
    constructor Create(const AProvider: ICardEacProvider;
      const ASecurity: TIcaoAccessSecurity; const AEncryptionKey, AMacKey,
      ACounter: TBytes);
    /// <summary>Clears exclusively owned secret buffers and releases the retained provider.</summary>
    destructor Destroy; override;
    /// <summary>Protects one short logical-channel-zero APDU and increments SSC once.</summary>
    /// <param name="ACommand">CLA=00, data up to 223 bytes, optional Le 1..256; no extended encoding.</param>
    /// <returns>Owned short protected command with DO85/87, optional DO97 and DO8E; outer Le=256.</returns>
    function Protect(const ACommand: TApduCommand): TBytes;
    /// <summary>Verifies canonical ordered DO85/87, mandatory DO99 and DO8E before decryption/unpadding.</summary>
    /// <param name="AResponse">Exact protected response with outer 9000; bounded to 258 bytes.</param>
    /// <returns>Owned authenticated plaintext and inner status, including valid protected error statuses.</returns>
    function Unprotect(const AResponse: TBytes): TApduResponse;
    /// <summary>Invalidates the session and clears its secrets without APDU I/O.</summary>
    procedure Clear;
    /// <summary>True while the session remains usable; false after Clear or a cryptographic/protocol failure.</summary>
    property Active: Boolean read FActive;
  end;

implementation

procedure InvalidSecureMessage;
begin
  raise EIcaoAccessError.Create('Invalid ICAO secure message.');
end;

function JoinBytes(const A, B: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then
    Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then
    Move(B[0], Result[Length(A)], Length(B));
end;

function EncodeSmObject(const Tag: Byte; const Value: TBytes): TBytes;
var
  Start: Integer;
begin
  Result := nil;
  if Length(Value) > 255 then
    InvalidSecureMessage;
  Start := 2;
  if Length(Value) >= 128 then
    Start := 3;
  SetLength(Result, Start + Length(Value));
  Result[0] := Tag;
  if Start = 2 then
    Result[1] := Length(Value)
  else
  begin
    Result[1] := $81;
    Result[2] := Length(Value);
  end;
  if Length(Value) > 0 then
    Move(Value[0], Result[Start], Length(Value));
end;

procedure ReadObject(const Bytes: TBytes; var Offset: Integer; out Tag: Byte;
  out Value, Raw: TBytes);
var
  Start, Count: Integer;
begin
  Value := nil;
  Raw := nil;
  Start := Offset;
  if Offset > Length(Bytes) - 2 then
    InvalidSecureMessage;
  Tag := Bytes[Offset];
  Inc(Offset);
  Count := Bytes[Offset];
  Inc(Offset);
  if Count = $81 then
  begin
    if Offset >= Length(Bytes) then
      InvalidSecureMessage;
    Count := Bytes[Offset];
    Inc(Offset);
    if Count < 128 then
      InvalidSecureMessage;
  end
  else if Count >= 128 then
    InvalidSecureMessage;
  if Count > Length(Bytes) - Offset then
    InvalidSecureMessage;
  Value := Copy(Bytes, Offset, Count);
  Inc(Offset, Count);
  Raw := Copy(Bytes, Start, Offset - Start);
end;

constructor TIcaoSecureMessaging.Create(const AProvider: ICardEacProvider;
  const ASecurity: TIcaoAccessSecurity; const AEncryptionKey, AMacKey,
  ACounter: TBytes);
var
  I: Integer;
begin
  inherited Create;
  if (AProvider = nil) or (Length(AEncryptionKey) <> 16) or
    (Length(AMacKey) <> 16) or (Ord(ASecurity) < 0) or (Ord(ASecurity) > 1) then
    InvalidSecureMessage;
  FSecurity := ASecurity;
  if Length(ACounter) <> BlockBytes then
    InvalidSecureMessage;
  if ASecurity = iasPaceGmAes128 then
    for I := 0 to High(ACounter) do
      if ACounter[I] <> 0 then
        InvalidSecureMessage;
  FProvider := AProvider;
  FEnc := Copy(AEncryptionKey, 0, 16);
  FMac := Copy(AMacKey, 0, 16);
  FCounter := Copy(ACounter, 0, Length(ACounter));
  FActive := True;
end;

destructor TIcaoSecureMessaging.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TIcaoSecureMessaging.Clear;
begin
  FActive := False;
  FPending := False;
  TCardCrypto.Clear(FEnc);
  TCardCrypto.Clear(FMac);
  TCardCrypto.Clear(FCounter);
  FProvider := nil;
end;

function TIcaoSecureMessaging.BlockBytes: Integer;
begin
  if FSecurity = iasBac then
    Result := 8
  else
    Result := 16;
end;

procedure TIcaoSecureMessaging.IncrementCounter;
var
  I: Integer;
begin
  for I := High(FCounter) downto 0 do
  begin
    if FCounter[I] < $FF then
    begin
      Inc(FCounter[I]);
      Exit;
    end;
    FCounter[I] := 0;
  end;
  InvalidSecureMessage;
end;

function TIcaoSecureMessaging.InitialVector: TBytes;
var
  Zero: TBytes;
begin
  Result := nil;
  SetLength(Result, BlockBytes);
  if FSecurity = iasPaceGmAes128 then
  begin
    Zero := nil;
    SetLength(Zero, 16);
    try
      Result := FProvider.EncryptCbc(FEnc, Zero, FCounter);
      if Length(Result) <> 16 then
        InvalidSecureMessage;
    finally
      TCardCrypto.Clear(Zero);
    end;
  end;
end;

function TIcaoSecureMessaging.Crypt(const Data: TBytes;
  const Encrypt: Boolean): TBytes;
var
  Iv, Key: TBytes;
begin
  Iv := InitialVector;
  Key := nil;
  try
    if FSecurity = iasBac then
    begin
      Key := TIcaoAccessCodec.ExpandDesKey(FEnc);
      Result := FProvider.TripleDesCbc(Key, Iv, Data, Encrypt);
    end
    else if Encrypt then
      Result := FProvider.EncryptCbc(FEnc, Iv, Data)
    else
      Result := FProvider.DecryptCbc(FEnc, Iv, Data);
    if Length(Result) <> Length(Data) then
      InvalidSecureMessage;
  finally
    TCardCrypto.Clear(Iv);
    TCardCrypto.Clear(Key);
  end;
end;

function TIcaoSecureMessaging.Mac(const Data: TBytes): TBytes;
var
  Full, Padded: TBytes;
begin
  Result := nil;
  Full := nil;
  Padded := nil;
  try
    if FSecurity = iasBac then
      Result := TIcaoAccessCodec.RetailMac(FProvider, FMac, Data)
    else
    begin
      Padded := TIcaoAccessCodec.Pad(Data, 16);
      Full := TCardCrypto.Cmac(FProvider, FMac, Padded);
      Result := Copy(Full, 0, 8);
    end;
    if Length(Result) <> 8 then
      InvalidSecureMessage;
  finally
    TCardCrypto.Clear(Full);
    TCardCrypto.Clear(Padded);
  end;
end;

function TIcaoSecureMessaging.Protect(const ACommand: TApduCommand): TBytes;
var
  C: TApduCommand;
  Header, Body, Payload, Encrypted, TagMac, MacInput: TBytes;
begin
  Result := nil;
  if not FActive or FPending or (ACommand.CLA <> 0) or ACommand.IsExtended or
    (Length(ACommand.Data) > 223) or
    (ACommand.HasLe and ((ACommand.Le < 1) or (ACommand.Le > 256))) or
    (not ACommand.HasLe and (ACommand.Le <> 0)) then
    InvalidSecureMessage;
  try
    try
      IncrementCounter;
      FInstruction := ACommand.INS;
      Header := nil;
      SetLength(Header, 4);
      Header[0] := $0C;
      Header[1] := ACommand.INS;
      Header[2] := ACommand.P1;
      Header[3] := ACommand.P2;
      Header := TIcaoAccessCodec.Pad(Header, BlockBytes);
      Body := nil;
      if Length(ACommand.Data) > 0 then
      begin
        Payload := TIcaoAccessCodec.Pad(ACommand.Data, BlockBytes);
        Encrypted := Crypt(Payload, True);
        if ACommand.INS and 1 = 0 then
        begin
          TCardCrypto.Clear(Payload);
          SetLength(Payload, 1);
          Payload[0] := 1;
          Body := EncodeSmObject($87, JoinBytes(Payload, Encrypted));
        end
        else
          Body := EncodeSmObject($85, Encrypted);
      end;
      if ACommand.HasLe then
      begin
        TCardCrypto.Clear(Payload);
        SetLength(Payload, 1);
        Payload[0] := ACommand.Le and $FF;
        Body := JoinBytes(Body, EncodeSmObject($97, Payload));
      end;
      MacInput := JoinBytes(FCounter, JoinBytes(Header, Body));
      TagMac := Mac(MacInput);
      C := ACommand;
      C.CLA := $0C;
      C.Data := JoinBytes(Body, EncodeSmObject($8E, TagMac));
      C.HasLe := True;
      C.Le := 256;
      if Length(C.Data) > 255 then
        InvalidSecureMessage;
      Result := TApduCodec.EncodeCommand(C);
      FPending := True;
    except
      Clear;
      raise;
    end;
  finally
    TCardCrypto.Clear(Header);
    TCardCrypto.Clear(Body);
    TCardCrypto.Clear(Payload);
    TCardCrypto.Clear(Encrypted);
    TCardCrypto.Clear(TagMac);
    TCardCrypto.Clear(MacInput);
  end;
end;

function TIcaoSecureMessaging.Unprotect(const AResponse: TBytes): TApduResponse;
var
  R: TApduResponse;
  Offset: Integer;
  Tag: Byte;
  Value, Raw, Message, Cipher, Status, ReceivedMac, ExpectedMac, Plain: TBytes;
begin
  Result := Default (TApduResponse);
  if not FActive or not FPending then
    InvalidSecureMessage;
  try
    try
      if (Length(AResponse) < 16) or (Length(AResponse) > 258) then
        InvalidSecureMessage;
      R := TApduCodec.DecodeResponse(AResponse);
      if R.StatusWord <> $9000 then
        InvalidSecureMessage;
      IncrementCounter;
      Offset := 0;
      Cipher := nil;
      Message := nil;
      ReadObject(R.Data, Offset, Tag, Value, Raw);
      if Tag in [$85, $87] then
      begin
        if ((FInstruction and 1 = 0) and (Tag <> $87)) or
          ((FInstruction and 1 <> 0) and (Tag <> $85)) then
          InvalidSecureMessage;
        if Tag = $87 then
        begin
          if (Length(Value) < 1) or (Value[0] <> 1) then
            InvalidSecureMessage;
          Cipher := Copy(Value, 1, Length(Value) - 1);
        end
        else
          Cipher := Copy(Value, 0, Length(Value));
        if (Length(Cipher) = 0) or (Length(Cipher) mod BlockBytes <> 0) then
          InvalidSecureMessage;
        Message := Copy(Raw, 0, Length(Raw));
        ReadObject(R.Data, Offset, Tag, Value, Raw);
      end;
      if (Tag <> $99) or (Length(Value) <> 2) then
        InvalidSecureMessage;
      Status := Copy(Value, 0, 2);
      Message := JoinBytes(Message, Raw);
      ReadObject(R.Data, Offset, Tag, ReceivedMac, Raw);
      if (Tag <> $8E) or (Length(ReceivedMac) <> 8) or (Offset <> Length(R.Data))
      then
        InvalidSecureMessage;
      ExpectedMac := Mac(JoinBytes(FCounter, Message));
      if not TCardCrypto.EqualSecret(ExpectedMac, ReceivedMac) then
        InvalidSecureMessage;
      if Length(Cipher) > 0 then
      begin
        Plain := Crypt(Cipher, False);
        Result.Data := TIcaoAccessCodec.Unpad(Plain, BlockBytes);
      end;
      Result.StatusWord := (Word(Status[0]) shl 8) or Status[1];
      FPending := False;
    except
      Clear;
      raise;
    end;
  finally
    TCardCrypto.Clear(Value);
    TCardCrypto.Clear(Raw);
    TCardCrypto.Clear(Message);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(Status);
    TCardCrypto.Clear(ReceivedMac);
    TCardCrypto.Clear(ExpectedMac);
    TCardCrypto.Clear(Plain);
  end;
end;

end.
