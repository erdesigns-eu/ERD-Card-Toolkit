unit ERD.Card.GlobalPlatform.SecureChannel;

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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.APDU,
  ERD.Card.Crypto, ERD.Card.Crypto.DES, ERD.Card.GlobalPlatform.Management;

type
  /// <summary>Invalid arguments, authentication, protected response or channel state; contains no secrets.</summary>
  EGpSecureChannelError = class(ECardCryptoError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a card-status failure with no command or response data.</summary>
    /// <param name="AStatusWord">Returned SW1/SW2; zero is reserved for local failures.</param>
    constructor CreateStatus(const AStatusWord: Word);

    /// <summary>Returned card status, or zero for local format/crypto/state failures.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>Explicit secure-channel algorithm; no automatic fallback or key guessing.</summary>
  TGpSecureProtocol = (
    /// <summary>SCP02 explicit initiation, modified APDU MAC and encrypted ICV, implementation i=15.</summary>
    gspScp02,
    /// <summary>SCP03 AES-128 with explicit S8 or S16 authentication.</summary>
    gspScp03);

  /// <summary>Explicit command and response protection level.</summary>
  TGpSecurityLevel = (
    /// <summary>Command MAC only, wire security level 01.</summary>
    gslMac,
    /// <summary>Command MAC and encryption, wire level 03.</summary>
    gslEncrypted,
    /// <summary>Command MAC and SCP03 response MAC, wire level 11.</summary>
    gslResponseMac,
    /// <summary>Encrypted commands and SCP03 response MAC, wire level 13.</summary>
    gslEncryptedResponseMac,
    /// <summary>Encrypted commands and SCP03 response MAC/encryption, wire level 33.</summary>
    gslFull);

  /// <summary>Caller-supplied, already diversified static card keys; record assignment shares storage.</summary>
  TGpCardKeys = record
    /// <summary>Sixteen-byte ENC key; no default key or diversification assumption.</summary>
    Enc: TBytes;
    /// <summary>Sixteen-byte MAC key; independent from ENC when provisioned that way.</summary>
    Mac: TBytes;
    /// <summary>Optional sixteen-byte static DEK; required for PUT KEY and retained as owned session material.</summary>
    Dek: TBytes;
  end;

  /// <summary>Native Delphi SCP02 i=15 and SCP03 AES-128 S8/S16 byte transport.</summary>
  /// <remarks>Owns one exclusive transaction until Close. Use on the opening thread only.
  /// Any exchange/cryptographic failure invalidates the channel; commands are never retried.
  /// Plain error responses in SCP03 response protection are returned as unauthenticated errors.
  /// ENC/MAC are borrowed during Open; supplied DEK is retained as an owned copy/derived key; owned session buffers are cleared on Close.</remarks>
  TGpSecureChannel = class(TInterfacedObject, ICardTransport)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FAes: ICardAesProvider;
    FDes: ICardDesProvider;
    FProtocol: TGpSecureProtocol;
    FLevel: TGpSecurityLevel;
    FEnc, FMac, FRmac, FChain, FCounter, FDek: TBytes;
    FOpen: Boolean;
    FMacLength: Integer;
    function Protect(const ACommand: TApduCommand; const AEncrypt: Boolean): TBytes;
    function Unprotect(const AResponse: TApduResponse): TBytes;
  public
    /// <summary>Constructs an inactive channel retaining providers; performs no I/O.</summary>
    /// <param name="ATransport">Connected caller-owned transport with ICardTransaction capability.</param>
    /// <param name="AAes">AES-128/CSPRNG provider for SCP03; may be nil for SCP02.</param>
    /// <param name="ADes">DES/CSPRNG provider for SCP02; may be nil for SCP03.</param>
    constructor Create(const ATransport: ICardTransport;
      const AAes: ICardAesProvider; const ADes: ICardDesProvider);

    /// <summary>Clears session secrets and releases the owned card transaction.</summary>
    destructor Destroy; override;

    /// <summary>Runs one INITIALIZE UPDATE and verified EXTERNAL AUTHENTICATE.</summary>
    /// <param name="AProtocol">SCP02 i=15 or SCP03; response protocol must match.</param>
    /// <param name="AKeys">Borrowed sixteen-byte ENC/MAC and optional DEK; owned session copies/derivations are cleared on Close.</param>
    /// <param name="AKeyVersion">Explicit key-set version; zero requests card selection.</param>
    /// <param name="AKeyId">SCP02 key identifier; must be zero for SCP03.</param>
    /// <param name="ALevel">Requested command/response protection; no fallback.</param>
    /// <param name="AS16">SCP03 sixteen-byte challenges/cryptograms/MACs; false uses S8.</param>
    /// <param name="ASecurityDomainAid">Explicit domain to reselect inside the transaction; required for pseudo-random challenges.</param>
    /// <exception cref="EGpSecureChannelError">Unsupported variant, bad cryptogram, state or protection.</exception>
    /// <remarks>Random and verifiable pseudo-random SCP03 challenges are supported.
    /// With no explicit domain, caller is responsible for an already selected domain. No retry after failed authentication.</remarks>
    procedure Open(const AProtocol: TGpSecureProtocol; const AKeys: TGpCardKeys;
      const AKeyVersion, AKeyId: Byte; const ALevel: TGpSecurityLevel;
      const AS16: Boolean = False; const ASecurityDomainAid: TBytes = nil);

    /// <summary>Sends one protected basic-channel short APDU and verifies/decrypts its response.</summary>
    /// <param name="ACommand">Plain CLA 00 or 80 command; maximum protected Lc is 255.</param>
    /// <returns>Independent plain response with SW1/SW2; protected buffers are cleared.</returns>
    /// <exception cref="EGpSecureChannelError">No channel, size/CLA error or protection failure.</exception>
    function Exchange(const ACommand: TBytes): TBytes;

    /// <summary>Invalidates the channel and clears session material; never sends a card command.</summary>
    /// <remarks>Transaction release errors propagate; destruction suppresses release errors.</remarks>
    procedure Close;

    /// <summary>Encodes a symmetric PUT KEY entry using the active session DEK and protocol KCV.</summary>
    /// <param name="AKey">Explicit sixteen-byte DES or AES key; input is never modified.</param>
    /// <param name="AIsAes">True encodes AES type 88 and actual-length byte; false encodes DES type 80.</param>
    /// <returns>Independent key entry with encrypted material and three-byte KCV.</returns>
    /// <remarks>Requires a DEK supplied during Open; no plaintext-key fallback.</remarks>
    function EncodeKey(const AKey: TBytes; const AIsAes: Boolean): TBytes;

    /// <summary>True only after successful card and host authentication, until failure or Close.</summary>
    property Active: Boolean read FOpen;
  end;

implementation

constructor EGpSecureChannelError.CreateStatus(const AStatusWord: Word);
begin
  inherited Create('GlobalPlatform card status ' + IntToHex(AStatusWord, 4) + '.');
  FStatusWord := AStatusWord;
end;

procedure Fail;
begin
  raise EGpSecureChannelError.Create('Invalid GlobalPlatform secure-channel operation.');
end;

function Zero(const N: Integer): TBytes;
begin
  Result := nil;
  SetLength(Result, N);
end;

function Join(const A, B: TBytes): TBytes;
begin
  Result := CopyBytes(A);
  SetLength(Result, Length(A) + Length(B));
  if Length(B) > 0 then Move(B[0], Result[Length(A)], Length(B));
end;

function Pad(const A: TBytes; const Block: Integer): TBytes;
begin
  Result := CopyBytes(A);
  SetLength(Result, ((Length(A) div Block) + 1) * Block);
  Result[Length(A)] := $80;
end;

function Equal(const A, B: TBytes): Boolean;
var
  I, D: Integer;
begin
  Result := False;
  if Length(A) <> Length(B) then Exit;
  D := 0;
  for I := 0 to High(A) do D := D or (A[I] xor B[I]);
  Result := D = 0;
end;

function DesMac(const P: ICardDesProvider; const K, IV, Message: TBytes;
  const Retail: Boolean): TBytes;
var
  Body, Cipher, Key1, Last: TBytes;
begin
  Body := nil; Cipher := nil; Key1 := nil; Last := nil;
  try
    Body := Pad(Message, 8);
    if Retail then
    begin
      Key1 := Copy(K, 0, 8);
      // CBC under K1 until the final padded block, then EDE under the full key.
      if Length(Body) > 8 then
      begin
        Cipher := TCardDesCrypto.Crypt(P, Key1, IV, Copy(Body, 0, Length(Body) - 8), True);
        Last := Copy(Cipher, Length(Cipher) - 8, 8);
      end
      else Last := CopyBytes(IV);
      Result := TCardDesCrypto.Crypt(P, K, Last, Copy(Body, Length(Body) - 8, 8), True);
    end
    else
    begin
      Cipher := TCardDesCrypto.Crypt(P, K, IV, Body, True);
      Result := Copy(Cipher, Length(Cipher) - 8, 8);
    end;
  finally
    TCardCrypto.Clear(Body); TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(Key1); TCardCrypto.Clear(Last);
  end;
end;

function Derive02(const P: ICardDesProvider; const K, Sequence: TBytes;
  const ConstantValue: Word): TBytes;
var
  D: TBytes;
begin
  D := Zero(16);
  try
    D[0] := ConstantValue shr 8;
    D[1] := ConstantValue and $FF;
    Move(Sequence[0], D[2], 2);
    Result := TCardDesCrypto.Crypt(P, K, Zero(8), D, True);
  finally
    TCardCrypto.Clear(D);
  end;
end;

function Derive03(const P: ICardAesProvider; const K, Context: TBytes;
  const ConstantValue: Byte; const Bits: Integer): TBytes;
var
  D, Full: TBytes;
begin
  D := Zero(16); Full := nil;
  try
    D[11] := ConstantValue;
    D[13] := Bits shr 8;
    D[14] := Bits and $FF;
    D[15] := 1;
    D := Join(D, Context);
    Full := TCardCrypto.Cmac(P, K, D);
    Result := Copy(Full, 0, Bits div 8);
  finally
    TCardCrypto.Clear(D); TCardCrypto.Clear(Full);
  end;
end;

constructor TGpSecureChannel.Create(const ATransport: ICardTransport;
  const AAes: ICardAesProvider; const ADes: ICardDesProvider);
begin
  inherited Create;
  FTransport := ATransport;
  FAes := AAes;
  FDes := ADes;
end;

destructor TGpSecureChannel.Destroy;
begin
  try Close; except end;
  inherited Destroy;
end;

procedure TGpSecureChannel.Close;
var
  Transaction: ICardTransaction;
begin
  FOpen := False;
  TCardCrypto.Clear(FEnc); TCardCrypto.Clear(FMac); TCardCrypto.Clear(FDek);
  TCardCrypto.Clear(FRmac); TCardCrypto.Clear(FChain); TCardCrypto.Clear(FCounter);
  Transaction := FTransaction;
  FTransaction := nil;
  if Transaction <> nil then Transaction.EndTransaction;
end;

procedure TGpSecureChannel.Open(const AProtocol: TGpSecureProtocol;
  const AKeys: TGpCardKeys; const AKeyVersion, AKeyId: Byte;
  const ALevel: TGpSecurityLevel; const AS16: Boolean;
  const ASecurityDomainAid: TBytes);
var
  Cmd: TApduCommand;
  Response: TApduResponse;
  Host, Card, Expected, Context, HostCryptogram, Wire, Sequence: TBytes;
  Txn: ICardTransaction;
  ChallengeLength, CryptogramOffset, ExtraLength: Integer;
  LevelByte: Byte;
begin
  if FOpen or (FTransaction <> nil) or (FTransport = nil) or
    (Length(AKeys.Enc) <> 16) or (Length(AKeys.Mac) <> 16) or
    ((Length(AKeys.Dek) <> 0) and (Length(AKeys.Dek) <> 16)) or
    (Ord(AProtocol) > Ord(High(TGpSecureProtocol))) or
    (Ord(ALevel) > Ord(High(TGpSecurityLevel))) then Fail;
  if (AProtocol = gspScp02) and ((FDes = nil) or AS16 or
    (ALevel > gslEncrypted)) then Fail;
  if (AProtocol = gspScp03) and ((FAes = nil) or (AKeyId <> 0)) then Fail;
  if (Length(ASecurityDomainAid) <> 0) and
    ((Length(ASecurityDomainAid) < 5) or (Length(ASecurityDomainAid) > 16)) then Fail;
  if not Supports(FTransport, ICardTransaction, Txn) then Fail;
  Host := nil; Card := nil; Expected := nil; Context := nil;
  HostCryptogram := nil; Wire := nil; Sequence := nil;
  Response := Default(TApduResponse);
  try
    try
      Txn.BeginTransaction;
      FTransaction := Txn;
      if Length(ASecurityDomainAid) > 0 then
      begin
        Cmd := Default(TApduCommand);
        Cmd.INS := $A4; Cmd.P1 := $04; Cmd.Data := ASecurityDomainAid;
        Cmd.HasLe := True; Cmd.Le := 256;
        Response := TApduCodec.DecodeResponse(FTransport.Exchange(TApduCodec.EncodeCommand(Cmd)));
        if Response.StatusWord <> $9000 then raise EGpSecureChannelError.CreateStatus(Response.StatusWord);
        TCardCrypto.Clear(Response.Data);
      end;
      FProtocol := AProtocol;
      FLevel := gslMac;
      ChallengeLength := 8;
      if AS16 then ChallengeLength := 16;
      FMacLength := ChallengeLength;
      if AProtocol = gspScp02 then Host := FDes.RandomBytes(8)
      else Host := FAes.RandomBytes(ChallengeLength);
      if Length(Host) <> ChallengeLength then Fail;
      Cmd := Default(TApduCommand);
      Cmd.CLA := $80; Cmd.INS := $50; Cmd.P1 := AKeyVersion; Cmd.P2 := AKeyId;
      Cmd.Data := Host; Cmd.HasLe := True; Cmd.Le := 256;
      Response := TApduCodec.DecodeResponse(FTransport.Exchange(TApduCodec.EncodeCommand(Cmd)));
      if Response.StatusWord <> $9000 then raise EGpSecureChannelError.CreateStatus(Response.StatusWord);
      if AProtocol = gspScp02 then
      begin
        if (Length(Response.Data) <> 28) or (Response.Data[11] <> 2) then Fail;
        if (AKeyVersion <> 0) and (Response.Data[10] <> AKeyVersion) then Fail;
        Sequence := Copy(Response.Data, 12, 2);
        Card := Copy(Response.Data, 12, 8);
        FEnc := Derive02(FDes, AKeys.Enc, Sequence, $0182);
        FMac := Derive02(FDes, AKeys.Mac, Sequence, $0101);
        if Length(AKeys.Dek) <> 0 then FDek := Derive02(FDes, AKeys.Dek, Sequence, $0181);
        Expected := DesMac(FDes, FEnc, Zero(8), Join(Host, Card), False);
        HostCryptogram := DesMac(FDes, FEnc, Zero(8), Join(Card, Host), False);
        FChain := Zero(8);
        CryptogramOffset := 20;
      end
      else
      begin
        if (Length(Response.Data) < 13 + 2 * ChallengeLength) or
          (Response.Data[11] <> 3) then Fail;
        if not (Response.Data[12] in [$00, $20, $60, $01, $21, $61,
          $10, $30, $70, $11, $31, $71]) then Fail;
        ExtraLength := 0;
        if Response.Data[12] and $10 <> 0 then ExtraLength := 3;
        if Length(Response.Data) <> 13 + 2 * ChallengeLength + ExtraLength then Fail;
        if ((Response.Data[12] and 1) <> 0) <> AS16 then Fail;
        if (AKeyVersion <> 0) and (Response.Data[10] <> AKeyVersion) then Fail;
        if (ALevel >= gslResponseMac) and ((Response.Data[12] and $20) = 0) then Fail;
        if (ALevel = gslFull) and ((Response.Data[12] and $40) = 0) then Fail;
        Card := Copy(Response.Data, 13, ChallengeLength);
        CryptogramOffset := 13 + ChallengeLength;
        if ExtraLength <> 0 then
        begin
          if Length(ASecurityDomainAid) = 0 then Fail;
          Sequence := Copy(Response.Data, CryptogramOffset + ChallengeLength, 3);
          Context := Join(Sequence, ASecurityDomainAid);
          Expected := Derive03(FAes, AKeys.Enc, Context, $02, ChallengeLength * 8);
          if not Equal(Card, Expected) then Fail;
          TCardCrypto.Clear(Context); TCardCrypto.Clear(Expected);
        end;
        Context := Join(Host, Card);
        if Length(AKeys.Dek) <> 0 then FDek := CopyBytes(AKeys.Dek);
        FEnc := Derive03(FAes, AKeys.Enc, Context, $04, 128);
        FMac := Derive03(FAes, AKeys.Mac, Context, $06, 128);
        FRmac := Derive03(FAes, AKeys.Mac, Context, $07, 128);
        Expected := Derive03(FAes, FMac, Context, $00, ChallengeLength * 8);
        HostCryptogram := Derive03(FAes, FMac, Context, $01, ChallengeLength * 8);
        FChain := Zero(16); FCounter := Zero(16);
      end;
      if not Equal(Expected, Copy(Response.Data, CryptogramOffset, ChallengeLength)) then Fail;
      case ALevel of
        gslMac: LevelByte := $01;
        gslEncrypted: LevelByte := $03;
        gslResponseMac: LevelByte := $11;
        gslEncryptedResponseMac: LevelByte := $13;
        gslFull: LevelByte := $33;
      else
        Fail;
        LevelByte := 0;
      end;
      Cmd := Default(TApduCommand);
      Cmd.CLA := $80; Cmd.INS := $82; Cmd.P1 := LevelByte; Cmd.Data := HostCryptogram;
      Cmd.HasLe := True; Cmd.Le := 256;
      Wire := Protect(Cmd, False);
      TCardCrypto.Clear(Response.Data);
      Response := TApduCodec.DecodeResponse(FTransport.Exchange(Wire));
      if Response.StatusWord <> $9000 then raise EGpSecureChannelError.CreateStatus(Response.StatusWord);
      if Length(Response.Data) <> 0 then Fail;
      FLevel := ALevel;
      FOpen := True;
    except
      try Close; except end;
      raise;
    end;
  finally
    TCardCrypto.Clear(Host); TCardCrypto.Clear(Card); TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Context); TCardCrypto.Clear(HostCryptogram);
    TCardCrypto.Clear(Wire); TCardCrypto.Clear(Sequence); TCardCrypto.Clear(Response.Data);
  end;
end;

function TGpSecureChannel.Protect(const ACommand: TApduCommand;
  const AEncrypt: Boolean): TBytes;
var
  Cmd: TApduCommand;
  Data, Header, Message, Mac, IV, Temp: TBytes;
  I: Integer;
begin
  if ACommand.IsExtended or not (ACommand.CLA in [$00, $80]) then Fail;
  Data := CopyBytes(ACommand.Data); Header := nil; Message := nil;
  Mac := nil; IV := nil; Temp := nil;
  try
    Cmd := ACommand;
    Cmd.CLA := Cmd.CLA or $04;
    if FProtocol = gspScp03 then
    begin
      if AEncrypt then
      begin
        I := 15;
        while (I >= 0) and (FCounter[I] = $FF) do
        begin
          FCounter[I] := 0;
          Dec(I);
        end;
        if I < 0 then Fail;
        FCounter[I] := FCounter[I] + 1;
        if Length(Data) > 0 then
        begin
          IV := FAes.EncryptCbc(FEnc, Zero(16), FCounter);
          if Length(IV) <> 16 then Fail;
          Temp := Pad(Data, 16);
          TCardCrypto.Clear(Data);
          Data := FAes.EncryptCbc(FEnc, IV, Temp);
          if Length(Data) <> Length(Temp) then Fail;
        end;
      end;
      if Length(Data) + FMacLength > 255 then Fail;
      Header := Zero(5);
      Header[0] := Cmd.CLA; Header[1] := Cmd.INS;
      Header[2] := Cmd.P1; Header[3] := Cmd.P2; Header[4] := Length(Data) + FMacLength;
      Message := Join(FChain, Join(Header, Data));
      Mac := TCardCrypto.Cmac(FAes, FMac, Message);
    end
    else
    begin
      if Length(Data) + 8 > 255 then Fail;
      Header := Zero(5);
      Header[0] := Cmd.CLA; Header[1] := Cmd.INS;
      Header[2] := Cmd.P1; Header[3] := Cmd.P2; Header[4] := Length(Data) + 8;
      Message := Join(Header, Data);
      // First EXTERNAL AUTHENTICATE uses zero ICV; subsequent i=15 ICVs use DES encryption.
      IV := CopyBytes(FChain);
      if FOpen then
        IV := TCardDesCrypto.Crypt(FDes, Copy(FMac, 0, 8), Zero(8), FChain, True);
      Mac := DesMac(FDes, FMac, IV, Message, True);
      if AEncrypt and (Length(Data) > 0) then
      begin
        Temp := Pad(Data, 8);
        TCardCrypto.Clear(Data);
        Data := TCardDesCrypto.Crypt(FDes, FEnc, Zero(8), Temp, True);
      end;
      if Length(Data) + 8 > 255 then Fail;
    end;
    TCardCrypto.Clear(FChain);
    FChain := CopyBytes(Mac);
    Cmd.Data := Join(Data, Copy(Mac, 0, FMacLength));
    try Result := TApduCodec.EncodeCommand(Cmd);
    finally TCardCrypto.Clear(Cmd.Data); end;
  finally
    TCardCrypto.Clear(Data); TCardCrypto.Clear(Header); TCardCrypto.Clear(Message);
    TCardCrypto.Clear(Mac); TCardCrypto.Clear(IV); TCardCrypto.Clear(Temp);
  end;
end;

function TGpSecureChannel.Unprotect(const AResponse: TApduResponse): TBytes;
var
  R: TApduResponse;
  Expected, Message, IV, Plain: TBytes;
  N: Integer;
begin
  R := AResponse; R.Data := CopyBytes(AResponse.Data);
  Expected := nil; Message := nil; IV := nil; Plain := nil;
  try
    if FLevel >= gslResponseMac then
    begin
      if not ((R.StatusWord = $9000) or (R.StatusWord shr 8 in [$62, $63])) then
      begin
        if Length(R.Data) <> 0 then Fail;
        Result := TApduCodec.EncodeResponse(R);
        Exit;
      end;
      if Length(R.Data) < FMacLength then Fail;
      N := Length(R.Data) - FMacLength;
      Message := Join(FChain, Copy(R.Data, 0, N));
      SetLength(Message, Length(Message) + 2);
      Message[High(Message) - 1] := R.StatusWord shr 8;
      Message[High(Message)] := R.StatusWord and $FF;
      Expected := TCardCrypto.Cmac(FAes, FRmac, Message);
      if not Equal(Copy(Expected, 0, FMacLength), Copy(R.Data, N, FMacLength)) then Fail;
      SetLength(R.Data, N);
      if (FLevel = gslFull) and (N > 0) then
      begin
        if N mod 16 <> 0 then Fail;
        IV := CopyBytes(FCounter); IV[0] := $80;
        Plain := FAes.EncryptCbc(FEnc, Zero(16), IV);
        if Length(Plain) <> 16 then Fail;
        TCardCrypto.Clear(IV); IV := Plain; Plain := nil;
        Plain := FAes.DecryptCbc(FEnc, IV, R.Data);
        if Length(Plain) <> N then Fail;
        while (N > 0) and (Plain[N - 1] = 0) do Dec(N);
        if (N = 0) or (Plain[N - 1] <> $80) or (Length(Plain) - N >= 16) then Fail;
        TCardCrypto.Clear(R.Data); R.Data := Copy(Plain, 0, N - 1);
      end;
    end;
    Result := TApduCodec.EncodeResponse(R);
  finally
    TCardCrypto.Clear(R.Data); TCardCrypto.Clear(Expected); TCardCrypto.Clear(Message);
    TCardCrypto.Clear(IV); TCardCrypto.Clear(Plain);
  end;
end;

function TGpSecureChannel.EncodeKey(const AKey: TBytes; const AIsAes: Boolean): TBytes;
var Cipher, Iv, CheckValue, Block: TBytes; I: Integer;
begin
  Result := nil; Cipher := nil; Iv := nil; CheckValue := nil; Block := nil;
  if not FOpen or (Length(FDek) <> 16) or (Length(AKey) <> 16) then Fail;
  try
    try
      if FProtocol = gspScp02 then
      begin
        SetLength(Iv, 8); SetLength(Cipher, 16);
        for I := 0 to 1 do
        begin
          Block := TCardDesCrypto.Crypt(FDes, FDek, Iv, Copy(AKey, I * 8, 8), True);
          Move(Block[0], Cipher[I * 8], 8); TCardCrypto.Clear(Block);
        end;
      end
      else
      begin
        SetLength(Iv, 16); Cipher := FAes.EncryptCbc(FDek, Iv, AKey);
        if Length(Cipher) <> 16 then Fail;
      end;
      CheckValue := TGpManagementCrypto.KeyCheckValue(FAes, FDes, AKey, AIsAes);
      if AIsAes then Result := Join(HexToBytes('881110'), Cipher)
      else Result := Join(HexToBytes('8010'), Cipher);
      Result := Join(Result, Join(HexToBytes('03'), CheckValue));
    except
      Close; TCardCrypto.Clear(Result); raise;
    end;
  finally
    TCardCrypto.Clear(Cipher); TCardCrypto.Clear(Iv); TCardCrypto.Clear(CheckValue); TCardCrypto.Clear(Block);
  end;
end;

function TGpSecureChannel.Exchange(const ACommand: TBytes): TBytes;
var
  Wire: TBytes;
  Response: TApduResponse;
begin
  Result := nil;
  if not FOpen then Fail;
  Wire := nil; Response := Default(TApduResponse);
  try
    try
      Wire := Protect(TApduCodec.DecodeCommand(ACommand),
        FLevel in [gslEncrypted, gslEncryptedResponseMac, gslFull]);
      Response := TApduCodec.DecodeResponse(FTransport.Exchange(Wire));
      Result := Unprotect(Response);
    except
      try Close; except end;
      raise;
    end;
  finally
    TCardCrypto.Clear(Wire); TCardCrypto.Clear(Response.Data);
  end;
end;

end.
