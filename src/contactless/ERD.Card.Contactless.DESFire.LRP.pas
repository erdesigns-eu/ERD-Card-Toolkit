unit ERD.Card.Contactless.DESFire.LRP;

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
  ERD.Card.Crypto, ERD.Card.Contactless.DESFire.EV2;

type
  /// <summary>Native LRP primitive, session derivation, mutual authentication and secure-message codec.</summary>
  /// <remarks>NXP AN12304 and MF2DLHX0 section 9.2. No card I/O or automatic negotiation.
  /// Callers own acquisition, command counters and session invalidation after dispatch failures.
  /// AES comes from a maintained provider; this implementation makes no certified side-channel claim.</remarks>
  TDesfireLrpCodec = class
  public
    /// <summary>Evaluates the m=4 LRP primitive with an explicitly selected updated key.</summary>
    /// <param name="AProvider">Non-nil maintained AES-128 backend.</param>
    /// <param name="AKey">Exactly sixteen base-key bytes, borrowed.</param>
    /// <param name="ANibbles">Zero through sixty-four values zero through fifteen, most significant first.</param>
    /// <param name="AUpdatedKey">Explicit updated-key index zero through three.</param>
    /// <param name="AFinal">Whether to apply final zero-block whitening.</param>
    /// <returns>Owned sixteen-byte result; no input buffer is modified.</returns>
    class function Evaluate(const AProvider: ICardAesProvider; const AKey, ANibbles: TBytes;
      const AUpdatedKey: Byte; const AFinal: Boolean): TBytes; static;
    /// <summary>Computes complete LRP-CMAC including empty and block-aligned messages.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen borrowed base-key bytes.</param>
    /// <param name="AMessage">Zero through 1048560 exact message bytes.</param>
    /// <returns>Owned sixteen-byte MAC using updated key zero; no truncation.</returns>
    class function Cmac(const AProvider: ICardAesProvider; const AKey, AMessage: TBytes): TBytes; static;
    /// <summary>Encrypts or decrypts LRICB blocks with a nonwrapping, fixed-width big-endian counter.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen borrowed base-key bytes.</param>
    /// <param name="AData">Exact complete blocks for raw/decrypt operations; bounded plaintext for padded encryption.</param>
    /// <param name="ACounter">Owned one-through-sixteen-byte counter, advanced only after the complete successful operation.</param>
    /// <param name="AUpdatedKey">Zero through three, normally one for session encryption.</param>
    /// <param name="AEncrypt">True to encrypt, false to decrypt.</param>
    /// <param name="APadding">ISO method-two padding; authentication instead selects raw blocks.</param>
    /// <returns>Owned complete output; invalid padding, overflow or provider errors preserve the supplied counter.</returns>
    class function Crypt(const AProvider: ICardAesProvider; const AKey, AData: TBytes;
      var ACounter: TBytes; const AUpdatedKey: Byte; const AEncrypt, APadding: Boolean): TBytes; static;
    /// <summary>Derives a native LRP transaction key; the resulting key is used with ordinary AES for receipt/ReaderID operations.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied static transaction key bytes.</param>
    /// <param name="AUid">Seven trusted real UID bytes.</param>
    /// <param name="ANextActCounter">Explicit resulting commit counter one through 65535.</param>
    /// <param name="ANextSessionCounter">Explicit resulting internal-session counter one through 65535; never inferred after aborts.</param>
    /// <param name="AEncryption">True selects ReaderID key label A5, false receipt label 5A.</param>
    /// <returns>Owned sixteen-byte key derived with LRP-CMAC of the exact native counter/UID vector.</returns>
    class function DeriveTransactionKey(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextActCounter, ANextSessionCounter: Word; const AEncryption: Boolean): TBytes; static;
    /// <summary>Computes a native LRP-profile transaction MAC with ordinary AES-CMAC and odd-index truncation.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied static transaction key bytes.</param>
    /// <param name="AUid">Seven trusted real UID bytes.</param>
    /// <param name="ANextActCounter">Explicit resulting commit counter.</param>
    /// <param name="ANextSessionCounter">Explicit resulting hidden-session counter.</param>
    /// <param name="AInput">Exact nonempty block-aligned canonical TMI, at most 1048560 bytes.</param>
    /// <returns>Owned eight-byte offline receipt MAC; LRP is used only in key derivation.</returns>
    class function TransactionMac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextActCounter, ANextSessionCounter: Word; const AInput: TBytes): TBytes; static;
    /// <summary>Decrypts native LRP-profile EncTMRI with its LRP-derived ordinary AES transaction key.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Sixteen supplied static transaction key bytes.</param>
    /// <param name="AUid">Seven trusted real UID bytes.</param>
    /// <param name="ANextActCounter">Explicit resulting commit counter.</param>
    /// <param name="ANextSessionCounter">Explicit resulting hidden-session counter.</param>
    /// <param name="AEncryptedReaderId">Sixteen acquired bytes, after secure-session MAC verification.</param>
    /// <returns>Owned sixteen-byte previous ReaderID; static-key proof completes only with verified transaction receipt.</returns>
    class function DecryptTransactionReaderId(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
      const ANextActCounter, ANextSessionCounter: Word; const AEncryptedReaderId: TBytes): TBytes; static;
    /// <summary>Builds native AuthenticateLRPFirst parameters with an explicit six-byte LRP capability request.</summary>
    /// <param name="AKeyNumber">Explicit application key selector zero through thirteen.</param>
    /// <param name="APcdCapabilities">Six supplied bytes with first byte 02, never inferred from card response.</param>
    /// <returns>Owned key selector, capability length six and exact capability bytes; native instruction is 71.</returns>
    class function FirstCommand(const AKeyNumber: Byte; const APcdCapabilities: TBytes): TBytes; static;
    /// <summary>Checks the native first-authentication mode indicator before accepting its plain card nonce.</summary>
    /// <param name="AResponse">Exactly seventeen bytes, native AuthMode 01 followed by sixteen card nonce bytes.</param>
    /// <returns>Owned RndB; AES-mode downgrade, truncation and surplus bytes are refused.</returns>
    class function FirstChallenge(const AResponse: TBytes): TBytes; static;
    /// <summary>Derives the LRP session master key with the native nonce vector and label 9669.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AKey">Exactly sixteen static authentication-key bytes.</param>
    /// <param name="ARndA">Sixteen fresh reader nonce bytes.</param>
    /// <param name="ARndB">Sixteen acquired card nonce bytes.</param>
    /// <returns>Owned sixteen-byte master; its updated keys zero/one are MAC/encryption.</returns>
    class function DeriveSessionKey(const AProvider: ICardAesProvider;
      const AKey, ARndA, ARndB: TBytes): TBytes; static;
    /// <summary>Builds native authentication part two from the derived master and both nonces.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AMaster">Sixteen derived LRP session master bytes.</param>
    /// <param name="ARndA">Sixteen fresh reader bytes.</param>
    /// <param name="ARndB">Sixteen acquired card bytes.</param>
    /// <returns>Owned RndA followed by complete LRP MAC of RndA/RndB; no APDU or status.</returns>
    class function ReaderResponse(const AProvider: ICardAesProvider;
      const AMaster, ARndA, ARndB: TBytes): TBytes; static;
    /// <summary>Verifies native first-authentication MAC before decrypting TI and capability echoes.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AMaster">Sixteen derived LRP session master bytes.</param>
    /// <param name="ARndA">Sixteen sent reader nonce bytes.</param>
    /// <param name="ARndB">Sixteen acquired card nonce bytes.</param>
    /// <param name="AResponse">Exactly sixteen encrypted TI/capability bytes and sixteen complete MAC bytes.</param>
    /// <param name="APcdCapabilities">Exactly six requested capabilities, with first byte 02.</param>
    /// <returns>Owned sixteen verified TI/PICC/PCD bytes; encryption counter subsequently starts at 00000001.</returns>
    class function VerifyFirstResponse(const AProvider: ICardAesProvider;
      const AMaster, ARndA, ARndB, AResponse, APcdCapabilities: TBytes): TBytes; static;
    /// <summary>Verifies complete NonFirst nonce MAC; existing TI and command counter are retained.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AMaster">New sixteen-byte derived LRP session master.</param>
    /// <param name="ARndA">Sixteen freshly sent reader bytes.</param>
    /// <param name="ARndB">Sixteen acquired card bytes.</param>
    /// <param name="AResponse">Exactly sixteen MAC bytes over RndB/RndA; no TI or capabilities.</param>
    /// <remarks>On success the caller resets only the encryption counter to four zero bytes.</remarks>
    class procedure VerifyNonFirstResponse(const AProvider: ICardAesProvider;
      const AMaster, ARndA, ARndB, AResponse: TBytes); static;
    /// <summary>Builds native LRP Plain/MAC/Full command data without ISO wrapping or chaining.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AMaster">Sixteen-byte derived session master.</param>
    /// <param name="ATi">Exactly four verified transaction identifier bytes.</param>
    /// <param name="ACommandCounter">Current counter zero through 65534, represented little-endian in the MAC.</param>
    /// <param name="ACommand">Actual native instruction.</param>
    /// <param name="AHeader">Clear native command parameters.</param>
    /// <param name="AData">Borrowed plaintext command body; empty read bodies are not encrypted.</param>
    /// <param name="AMode">Explicit Plain, MAC or Full profile.</param>
    /// <param name="AEncryptionCounter">Four big-endian bytes, advanced only after complete construction.</param>
    /// <returns>Owned header/body/truncated-MAC bytes.</returns>
    class function EncodeCommand(const AProvider: ICardAesProvider;
      const AMaster, ATi: TBytes; const ACommandCounter: Integer; const ACommand: Byte;
      const AHeader, AData: TBytes; const AMode: TDesfireCommunication;
      var AEncryptionCounter: TBytes): TBytes; static;
    /// <summary>Verifies a complete successful response MAC before decryption and exact length/padding checks.</summary>
    /// <param name="AProvider">Maintained AES backend.</param>
    /// <param name="AMaster">Sixteen-byte derived session master.</param>
    /// <param name="ATi">Exactly four verified TI bytes.</param>
    /// <param name="ACommandCounter">Response counter one through 65535 after one command increment.</param>
    /// <param name="AData">Complete concatenated response excluding successful native status.</param>
    /// <param name="AMode">Explicit communication mode used for the command.</param>
    /// <param name="AExpectedBytes">Exact plaintext size zero through 1048500.</param>
    /// <param name="AEncryptionCounter">Four big-endian bytes; preserved on MAC/padding/length/provider failure.</param>
    /// <returns>Owned verified plaintext; Plain mode does not imply MAC authenticity.</returns>
    class function DecodeResponse(const AProvider: ICardAesProvider;
      const AMaster, ATi: TBytes; const ACommandCounter: Integer; const AData: TBytes;
      const AMode: TDesfireCommunication; const AExpectedBytes: Integer;
      var AEncryptionCounter: TBytes): TBytes; static;
  end;

implementation

uses ERD.Card.Bytes;

type
  TLrpContext = class
  private
    FProvider: ICardAesProvider;
    FPlain: array[0..15] of TBytes;
    FUpdated, FZero: TBytes;
  public
    constructor Create(const AProvider: ICardAesProvider; const AKey: TBytes; const AIndex: Byte);
    destructor Destroy; override;
    function Block(const AKey, AData: TBytes; const AEncrypt: Boolean = True): TBytes;
    function Eval(const ANibbles: TBytes; const AFinal: Boolean): TBytes;
    function EvalBytes(const ABytes: TBytes): TBytes;
  end;

procedure InvalidLrp;
begin
  raise ECardCryptoError.Create('Invalid native LRP input or verification.');
end;

function JoinedLrp(const A, B: TBytes): TBytes;
begin
  Result := nil;
  if (Length(A) > 1048560 - Length(B)) then InvalidLrp;
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then Move(B[0], Result[Length(A)], Length(B));
end;

constructor TLrpContext.Create(const AProvider: ICardAesProvider; const AKey: TBytes; const AIndex: Byte);
var
  Seed, Next, Low, High: TBytes;
  I: Integer;
begin
  inherited Create;
  if (AProvider = nil) or (Length(AKey) <> 16) or (AIndex > 3) then InvalidLrp;
  FProvider := AProvider;
  SetLength(FZero, 16);
  SetLength(Low, 16);
  SetLength(High, 16);
  FillChar(Low[0], 16, $55);
  FillChar(High[0], 16, $AA);
  try
    Seed := Block(AKey, Low);
    for I := 0 to 15 do
    begin
      FPlain[I] := Block(Seed, High);
      Next := Block(Seed, Low);
      TCardCrypto.Clear(Seed);
      Seed := Next;
      Next := nil;
    end;
    TCardCrypto.Clear(Seed);
    Seed := Block(AKey, High);
    for I := 0 to AIndex do
    begin
      TCardCrypto.Clear(FUpdated);
      FUpdated := Block(Seed, High);
      Next := Block(Seed, Low);
      TCardCrypto.Clear(Seed);
      Seed := Next;
      Next := nil;
    end;
  finally
    TCardCrypto.Clear(Seed);
    TCardCrypto.Clear(Next);
    TCardCrypto.Clear(Low);
    TCardCrypto.Clear(High);
  end;
end;

destructor TLrpContext.Destroy;
var I: Integer;
begin
  for I := 0 to 15 do TCardCrypto.Clear(FPlain[I]);
  TCardCrypto.Clear(FUpdated);
  TCardCrypto.Clear(FZero);
  inherited;
end;

function TLrpContext.Block(const AKey, AData: TBytes; const AEncrypt: Boolean): TBytes;
begin
  if (Length(AKey) <> 16) or (Length(AData) <> 16) then InvalidLrp;
  if AEncrypt then Result := FProvider.EncryptCbc(AKey, FZero, AData)
  else Result := FProvider.DecryptCbc(AKey, FZero, AData);
  if Length(Result) <> 16 then
  begin
    TCardCrypto.Clear(Result);
    InvalidLrp;
  end;
end;

function TLrpContext.Eval(const ANibbles: TBytes; const AFinal: Boolean): TBytes;
var
  Key, Next: TBytes;
  I: Integer;
begin
  Result := nil;
  if Length(ANibbles) > 64 then InvalidLrp;
  for I := 0 to High(ANibbles) do if ANibbles[I] > 15 then InvalidLrp;
  Key := CopyBytes(FUpdated);
  try
    for I := 0 to High(ANibbles) do
    begin
      Next := Block(Key, FPlain[ANibbles[I]]);
      TCardCrypto.Clear(Key);
      Key := Next;
      Next := nil;
    end;
    if AFinal then Result := Block(Key, FZero) else Result := CopyBytes(Key);
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Next);
  end;
end;

function TLrpContext.EvalBytes(const ABytes: TBytes): TBytes;
var
  Nibbles: TBytes;
  I: Integer;
begin
  if Length(ABytes) > 32 then InvalidLrp;
  SetLength(Nibbles, Length(ABytes) * 2);
  try
    for I := 0 to High(ABytes) do
    begin
      Nibbles[I * 2] := ABytes[I] shr 4;
      Nibbles[I * 2 + 1] := ABytes[I] and $F;
    end;
    Result := Eval(Nibbles, True);
  finally
    TCardCrypto.Clear(Nibbles);
  end;
end;

class function TDesfireLrpCodec.Evaluate(const AProvider: ICardAesProvider; const AKey, ANibbles: TBytes;
  const AUpdatedKey: Byte; const AFinal: Boolean): TBytes;
var Context: TLrpContext;
begin
  Context := TLrpContext.Create(AProvider, AKey, AUpdatedKey);
  try Result := Context.Eval(ANibbles, AFinal); finally Context.Free; end;
end;

function DoubleLrp(const A: TBytes): TBytes;
var I, Carry, Next: Integer;
begin
  Result := nil;
  SetLength(Result, 16);
  Carry := 0;
  for I := 15 downto 0 do
  begin
    Next := A[I] shr 7;
    Result[I] := Byte(((Integer(A[I]) shl 1) and $FF) or Carry);
    Carry := Next;
  end;
  if Carry <> 0 then Result[15] := Result[15] xor $87;
end;

class function TDesfireLrpCodec.Cmac(const AProvider: ICardAesProvider; const AKey, AMessage: TBytes): TBytes;
var
  Context: TLrpContext;
  Zero, K1, K2, State, Block, Next: TBytes;
  I, J, Count, Remaining: Integer;
begin
  Result := nil;
  if Length(AMessage) > 1048560 then InvalidLrp;
  Context := TLrpContext.Create(AProvider, AKey, 0);
  try
    SetLength(Zero, 16);
    State := Context.EvalBytes(Zero);
    K1 := DoubleLrp(State);
    K2 := DoubleLrp(K1);
    TCardCrypto.Clear(State);
    SetLength(State, 16);
    Count := (Length(AMessage) + 15) div 16;
    if Count = 0 then Count := 1;
    for I := 0 to Count - 1 do
    begin
      TCardCrypto.Clear(Block);
      SetLength(Block, 16);
      Remaining := Length(AMessage) - I * 16;
      if Remaining > 16 then Remaining := 16;
      if Remaining > 0 then Move(AMessage[I * 16], Block[0], Remaining);
      if I = Count - 1 then
      begin
        if Remaining = 16 then
          for J := 0 to 15 do Block[J] := Block[J] xor K1[J]
        else
        begin
          Block[Remaining] := $80;
          for J := 0 to 15 do Block[J] := Block[J] xor K2[J];
        end;
      end;
      for J := 0 to 15 do Block[J] := Block[J] xor State[J];
      Next := Context.EvalBytes(Block);
      TCardCrypto.Clear(State);
      State := Next;
      Next := nil;
    end;
    Result := CopyBytes(State);
  finally
    Context.Free;
    TCardCrypto.Clear(Zero); TCardCrypto.Clear(K1); TCardCrypto.Clear(K2);
    TCardCrypto.Clear(State); TCardCrypto.Clear(Block); TCardCrypto.Clear(Next);
  end;
end;

procedure AdvanceLrp(var Counter: TBytes);
var I: Integer;
begin
  for I := High(Counter) downto 0 do
    if Counter[I] < $FF then
    begin
      Inc(Counter[I]);
      Exit;
    end
    else Counter[I] := 0;
  InvalidLrp;
end;

class function TDesfireLrpCodec.Crypt(const AProvider: ICardAesProvider; const AKey, AData: TBytes;
  var ACounter: TBytes; const AUpdatedKey: Byte; const AEncrypt, APadding: Boolean): TBytes;
var
  Context: TLrpContext;
  Counter, Input, Key, Chunk, Block, Output: TBytes;
  I, Size, Last: Integer;
begin
  Result := nil;
  if (Length(ACounter) < 1) or (Length(ACounter) > 16) or (Length(AData) > 1048500) then InvalidLrp;
  if (not AEncrypt or not APadding) and ((Length(AData) = 0) or (Length(AData) mod 16 <> 0)) then InvalidLrp;
  Context := TLrpContext.Create(AProvider, AKey, AUpdatedKey);
  try
    Counter := CopyBytes(ACounter);
    Input := CopyBytes(AData);
    if AEncrypt and APadding then
    begin
      Size := Length(Input);
      SetLength(Input, ((Size div 16) + 1) * 16);
      Input[Size] := $80;
    end;
    SetLength(Output, Length(Input));
    for I := 0 to Length(Input) div 16 - 1 do
    begin
      Key := Context.EvalBytes(Counter);
      Chunk := Copy(Input, I * 16, 16);
      Block := Context.Block(Key, Chunk, AEncrypt);
      TCardCrypto.Clear(Chunk);
      Move(Block[0], Output[I * 16], 16);
      TCardCrypto.Clear(Key);
      TCardCrypto.Clear(Block);
      AdvanceLrp(Counter);
    end;
    if not AEncrypt and APadding then
    begin
      Last := High(Output);
      while (Last >= 0) and (Output[Last] = 0) do Dec(Last);
      if (Last < 0) or (Output[Last] <> $80) or (Length(Output) - Last > 16) then InvalidLrp;
      for I := Last to High(Output) do Output[I] := 0;
      SetLength(Output, Last);
    end;
    Result := Output;
    Output := nil;
    TCardCrypto.Clear(ACounter);
    ACounter := Counter;
    Counter := nil;
  finally
    Context.Free;
    TCardCrypto.Clear(Counter); TCardCrypto.Clear(Input); TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Chunk); TCardCrypto.Clear(Block); TCardCrypto.Clear(Output);
  end;
end;

class function TDesfireLrpCodec.FirstCommand(const AKeyNumber: Byte; const APcdCapabilities: TBytes): TBytes;
begin
  if (AKeyNumber > 13) or (Length(APcdCapabilities) <> 6) or (APcdCapabilities[0] <> 2) then InvalidLrp;
  Result := nil;
  SetLength(Result, 8);
  Result[0] := AKeyNumber;
  Result[1] := 6;
  Move(APcdCapabilities[0], Result[2], 6);
end;

class function TDesfireLrpCodec.FirstChallenge(const AResponse: TBytes): TBytes;
begin
  if (Length(AResponse) <> 17) or (AResponse[0] <> 1) then InvalidLrp;
  Result := Copy(AResponse, 1, 16);
end;

class function TDesfireLrpCodec.DeriveSessionKey(const AProvider: ICardAesProvider;
  const AKey, ARndA, ARndB: TBytes): TBytes;
var V: TBytes; I: Integer;
begin
  if (Length(ARndA) <> 16) or (Length(ARndB) <> 16) then InvalidLrp;
  V := nil;
  SetLength(V, 32);
  V[1] := 1; V[3] := $80;
  Move(ARndA[0], V[4], 2);
  for I := 0 to 5 do V[I + 6] := ARndA[I + 2] xor ARndB[I];
  Move(ARndB[6], V[12], 10);
  Move(ARndA[8], V[22], 8);
  V[30] := $96; V[31] := $69;
  try Result := Cmac(AProvider, AKey, V); finally TCardCrypto.Clear(V); end;
end;

procedure ValidateLrpNonces(const AMaster, A, B: TBytes);
begin
  if (Length(AMaster) <> 16) or (Length(A) <> 16) or (Length(B) <> 16) then InvalidLrp;
end;

class function TDesfireLrpCodec.ReaderResponse(const AProvider: ICardAesProvider;
  const AMaster, ARndA, ARndB: TBytes): TBytes;
var Input, Mac: TBytes;
begin
  ValidateLrpNonces(AMaster, ARndA, ARndB);
  Input := JoinedLrp(ARndA, ARndB);
  try
    Mac := Cmac(AProvider, AMaster, Input);
    Result := JoinedLrp(ARndA, Mac);
  finally TCardCrypto.Clear(Input); TCardCrypto.Clear(Mac); end;
end;

class function TDesfireLrpCodec.VerifyFirstResponse(const AProvider: ICardAesProvider;
  const AMaster, ARndA, ARndB, AResponse, APcdCapabilities: TBytes): TBytes;
var Input, Mac, Cipher, Counter: TBytes;
begin
  Result := nil;
  ValidateLrpNonces(AMaster, ARndA, ARndB);
  if (Length(AResponse) <> 32) or (Length(APcdCapabilities) <> 6) or (APcdCapabilities[0] <> 2) then InvalidLrp;
  Cipher := Copy(AResponse, 0, 16);
  Input := JoinedLrp(ARndB, ARndA);
  Mac := JoinedLrp(Input, Cipher);
  TCardCrypto.Clear(Input);
  Input := Mac;
  Mac := nil;
  try
    Mac := Cmac(AProvider, AMaster, Input);
    if not TCardCrypto.EqualSecret(Mac, Copy(AResponse, 16, 16)) then InvalidLrp;
    SetLength(Counter, 4);
    Result := Crypt(AProvider, AMaster, Cipher, Counter, 1, False, False);
    if not TCardCrypto.EqualSecret(Copy(Result, 10, 6), APcdCapabilities) then
    begin
      TCardCrypto.Clear(Result);
      InvalidLrp;
    end;
  finally
    TCardCrypto.Clear(Input); TCardCrypto.Clear(Mac); TCardCrypto.Clear(Cipher); TCardCrypto.Clear(Counter);
  end;
end;

class procedure TDesfireLrpCodec.VerifyNonFirstResponse(const AProvider: ICardAesProvider;
  const AMaster, ARndA, ARndB, AResponse: TBytes);
var Input, Mac: TBytes;
begin
  ValidateLrpNonces(AMaster, ARndA, ARndB);
  if Length(AResponse) <> 16 then InvalidLrp;
  Input := JoinedLrp(ARndB, ARndA);
  try
    Mac := Cmac(AProvider, AMaster, Input);
    if not TCardCrypto.EqualSecret(Mac, AResponse) then InvalidLrp;
  finally TCardCrypto.Clear(Input); TCardCrypto.Clear(Mac); end;
end;

function LrpPrefix(const ACode: Byte; const ACounter: Integer; const ATi: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, 7);
  Result[0] := ACode; Result[1] := Byte(ACounter and $FF); Result[2] := Byte(ACounter shr 8);
  Move(ATi[0], Result[3], 4);
end;

function TruncateLrp(const A: TBytes): TBytes;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, 8);
  for I := 0 to 7 do Result[I] := A[I * 2 + 1];
end;

procedure ValidateLrpFraming(const Master, Ti, Counter: TBytes; const Mode: TDesfireCommunication);
begin
  if (Length(Master) <> 16) or (Length(Ti) <> 4) or (Length(Counter) <> 4) or
    (Ord(Mode) < 0) or (Ord(Mode) > 2) then InvalidLrp;
end;

class function TDesfireLrpCodec.EncodeCommand(const AProvider: ICardAesProvider;
  const AMaster, ATi: TBytes; const ACommandCounter: Integer; const ACommand: Byte;
  const AHeader, AData: TBytes; const AMode: TDesfireCommunication;
  var AEncryptionCounter: TBytes): TBytes;
var Counter, Body, Payload, Input, Mac, Tag: TBytes;
begin
  Result := nil;
  ValidateLrpFraming(AMaster, ATi, AEncryptionCounter, AMode);
  if (ACommandCounter < 0) or (ACommandCounter > 65534) or
    (Length(AHeader) > 1048500 - Length(AData)) then InvalidLrp;
  Counter := CopyBytes(AEncryptionCounter);
  try
    if (AMode = dfcFull) and (Length(AData) > 0) then
      Body := Crypt(AProvider, AMaster, AData, Counter, 1, True, True)
    else Body := CopyBytes(AData);
    Payload := JoinedLrp(AHeader, Body);
    if AMode = dfcPlain then Result := CopyBytes(Payload)
    else
    begin
      Input := JoinedLrp(LrpPrefix(ACommand, ACommandCounter, ATi), Payload);
      Mac := Cmac(AProvider, AMaster, Input);
      Tag := TruncateLrp(Mac);
      Result := JoinedLrp(Payload, Tag);
    end;
    TCardCrypto.Clear(AEncryptionCounter);
    AEncryptionCounter := Counter;
    Counter := nil;
  finally
    TCardCrypto.Clear(Counter); TCardCrypto.Clear(Body); TCardCrypto.Clear(Payload);
    TCardCrypto.Clear(Input); TCardCrypto.Clear(Mac); TCardCrypto.Clear(Tag);
  end;
end;

class function TDesfireLrpCodec.DecodeResponse(const AProvider: ICardAesProvider;
  const AMaster, ATi: TBytes; const ACommandCounter: Integer; const AData: TBytes;
  const AMode: TDesfireCommunication; const AExpectedBytes: Integer;
  var AEncryptionCounter: TBytes): TBytes;
var Counter, Body, Input, Mac, Tag, Plain: TBytes;
begin
  Result := nil;
  ValidateLrpFraming(AMaster, ATi, AEncryptionCounter, AMode);
  if (ACommandCounter < 1) or (ACommandCounter > 65535) or
    (AExpectedBytes < 0) or (AExpectedBytes > 1048500) or (Length(AData) > 1048560) then InvalidLrp;
  Counter := CopyBytes(AEncryptionCounter);
  try
    if AMode = dfcPlain then Body := CopyBytes(AData)
    else
    begin
      if Length(AData) < 8 then InvalidLrp;
      Body := Copy(AData, 0, Length(AData) - 8);
      Input := JoinedLrp(LrpPrefix(0, ACommandCounter, ATi), Body);
      Mac := Cmac(AProvider, AMaster, Input);
      Tag := TruncateLrp(Mac);
      if not TCardCrypto.EqualSecret(Tag, Copy(AData, Length(AData) - 8, 8)) then InvalidLrp;
    end;
    if (AMode = dfcFull) and (AExpectedBytes > 0) then
      Plain := Crypt(AProvider, AMaster, Body, Counter, 1, False, True)
    else Plain := CopyBytes(Body);
    if Length(Plain) <> AExpectedBytes then InvalidLrp;
    Result := Plain;
    Plain := nil;
    TCardCrypto.Clear(AEncryptionCounter);
    AEncryptionCounter := Counter;
    Counter := nil;
  finally
    TCardCrypto.Clear(Counter); TCardCrypto.Clear(Body); TCardCrypto.Clear(Input);
    TCardCrypto.Clear(Mac); TCardCrypto.Clear(Tag); TCardCrypto.Clear(Plain);
  end;
end;

class function TDesfireLrpCodec.DeriveTransactionKey(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ANextActCounter, ANextSessionCounter: Word; const AEncryption: Boolean): TBytes;
var Vector: TBytes;
begin
  if (Length(AKey) <> 16) or (Length(AUid) <> 7) or (ANextActCounter = 0) or
    (ANextSessionCounter = 0) then InvalidLrp;
  Vector := nil;
  SetLength(Vector, 16);
  Vector[1] := 1; Vector[3] := $80;
  Vector[4] := Byte(ANextActCounter and $FF); Vector[5] := Byte(ANextActCounter shr 8);
  Vector[6] := Byte(ANextSessionCounter and $FF); Vector[7] := Byte(ANextSessionCounter shr 8);
  Move(AUid[0], Vector[8], 7);
  Vector[15] := $5A;
  if AEncryption then Vector[15] := $A5;
  try Result := Cmac(AProvider, AKey, Vector); finally TCardCrypto.Clear(Vector); end;
end;

class function TDesfireLrpCodec.TransactionMac(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ANextActCounter, ANextSessionCounter: Word; const AInput: TBytes): TBytes;
var Key, Mac: TBytes;
begin
  if (Length(AInput) < 16) or (Length(AInput) mod 16 <> 0) or (Length(AInput) > 1048560) then InvalidLrp;
  Key := DeriveTransactionKey(AProvider, AKey, AUid, ANextActCounter, ANextSessionCounter, False);
  try
    Mac := TCardCrypto.Cmac(AProvider, Key, AInput);
    Result := TruncateLrp(Mac);
  finally TCardCrypto.Clear(Key); TCardCrypto.Clear(Mac); end;
end;

class function TDesfireLrpCodec.DecryptTransactionReaderId(const AProvider: ICardAesProvider; const AKey, AUid: TBytes;
  const ANextActCounter, ANextSessionCounter: Word; const AEncryptedReaderId: TBytes): TBytes;
var Key, Zero: TBytes;
begin
  if Length(AEncryptedReaderId) <> 16 then InvalidLrp;
  Key := DeriveTransactionKey(AProvider, AKey, AUid, ANextActCounter, ANextSessionCounter, True);
  try
    SetLength(Zero, 16);
    Result := AProvider.DecryptCbc(Key, Zero, AEncryptedReaderId);
    if Length(Result) <> 16 then
    begin
      TCardCrypto.Clear(Result);
      InvalidLrp;
    end;
  finally TCardCrypto.Clear(Key); TCardCrypto.Clear(Zero); end;
end;

end.
