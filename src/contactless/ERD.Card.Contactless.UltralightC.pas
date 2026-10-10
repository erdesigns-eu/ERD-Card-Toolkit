unit ERD.Card.Contactless.UltralightC;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}Classes, SysUtils, {$ELSE}System.Classes, System.SysUtils, {$ENDIF}
  ERD.Card.Crypto.DES, ERD.Card.Contactless.Raw;

const
  /// <summary>First physical Ultralight C user page; manufacturer/static-lock/OTP bytes are excluded.</summary>
  UltralightCFirstUserPage = 4;
  /// <summary>Last physical user page; dynamic locks, counter, authentication configuration and keys are excluded.</summary>
  UltralightCLastUserPage = 39;
  /// <summary>Complete user region, 36 four-byte pages.</summary>
  UltralightCUserBytes = 144;

type
  /// <summary>Owned acquired Ultralight C authentication settings and dynamic-lock evidence, never key bytes.</summary>
  TUltralightCConfiguration = record
    /// <summary>AUTH0 address 3..48; 48 disables memory protection.</summary>
    FirstProtectedPage: Byte;
    /// <summary>True when both reads and writes require authentication; false restricts writes only.</summary>
    ProtectReads: Boolean;
    /// <summary>AUTH0 page permanently locked by dynamic lock byte 3 bit 5.</summary>
    Auth0Locked: Boolean;
    /// <summary>AUTH1 page permanently locked by dynamic lock byte 3 bit 6.</summary>
    Auth1Locked: Boolean;
    /// <summary>All key pages permanently locked by dynamic lock byte 3 bit 7.</summary>
    KeyLocked: Boolean;
    /// <summary>Independent exact eight bytes of pages 42/43, usable as a configuration preimage.</summary>
    AuthenticationPages: TBytes;
    /// <summary>Independent sixteen bytes from READ page 40: locks, counter, AUTH0 and AUTH1.</summary>
    RawPages: TBytes;
  end;

  /// <summary>Nonvisual explicitly keyed Ultralight C mutual authentication, user memory and explicit key/configuration management.</summary>
  /// <remarks>Uses one retained raw Type A session, explicit CRC-A, fresh eight-byte CSPRNG nonce and native
  /// two-key Triple DES. Explicit configuration/key management verifies fresh activation; no key discovery, retries, lock writes or encrypted memory messaging.
  /// Ultralight C authenticates access but subsequent memory data remain plaintext. Configure/use on one thread.</remarks>
  TUltralightCCardReaderWriter = class(TComponent)
  private
    FReader: IRawContactlessReader;
    FProvider: ICardDesProvider;
    FBusy: Boolean;
    FSelectedUid: TBytes;
    procedure SetReader(const AValue: IRawContactlessReader);
    procedure SetProvider(const AValue: ICardDesProvider);
    procedure Acquire(const AKey: TBytes);
    procedure Release(const ASucceeded: Boolean);
    procedure Authenticate(const AKey: TBytes);
    function ReadPage(const APage: Integer): TBytes;
    function Configuration: TUltralightCConfiguration;
    procedure WritePage(const APage: Byte; const Data: TBytes;
      var Dispatched: Boolean);
    procedure Reactivate(const Key: TBytes);
  public
    /// <summary>Constructs inactive access without opening readers or retaining a key.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Authenticates with a supplied key and returns one exact user page.</summary>
    /// <param name="APage">Physical page 4..39.</param>
    /// <param name="AKey">Exactly 16 K1/K2 bytes in cryptographic order; no default or reversal.</param>
    /// <returns>Owned four-byte page after successful session release.</returns>
    function ReadUserPage(const APage: Integer; const AKey: TBytes): TBytes;
    /// <summary>Authenticates once and reads all 36 user pages in ascending four-page READ blocks.</summary>
    /// <param name="AKey">Exactly 16 supplied bytes; borrowed, copied and locally wiped.</param>
    /// <returns>Owned 144 bytes corresponding to physical pages 4..39 after successful release.</returns>
    function ReadUserMemory(const AKey: TBytes): TBytes;
    /// <summary>Authenticates once, submits one four-byte user write and independently verifies the same RF session.</summary>
    /// <param name="APage">Physical page 4..39; manufacturer/configuration/key regions are excluded.</param>
    /// <param name="AData">Exactly four borrowed bytes, copied before I/O.</param>
    /// <param name="AKey">Exactly 16 supplied cryptographic-order bytes.</param>
    /// <returns>Independent verified four-byte read-back after successful release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch, including ACK/read-back/release.</exception>
    function WriteUserPageVerified(const APage: Integer;
      const AData, AKey: TBytes): TBytes;
    /// <summary>Authenticates and reads only pages 40..43, returning owned configuration and lock evidence.</summary>
    /// <param name="AKey">Exactly 16 supplied bytes in cryptographic order.</param>
    /// <returns>Configuration after successful session release; key pages are never read.</returns>
    function ReadConfiguration(const AKey: TBytes): TUltralightCConfiguration;
    /// <summary>Preserves reserved bytes, checks preimage/locks, changes AUTH1 then AUTH0 and verifies after fresh activation.</summary>
    /// <param name="AFirstProtectedPage">AUTH0 address 3..48; 48 explicitly disables protection.</param>
    /// <param name="AProtectReads">True protects reads and writes; false protects writes only.</param>
    /// <param name="AExpectedPages">Exact eight-byte pages 42/43 preimage from ReadConfiguration.</param>
    /// <param name="AKey">Exactly 16 supplied current key bytes.</param>
    /// <returns>Owned configuration after matching UID, fresh authentication, full readback and release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after configuration write dispatch; no retry or rollback.</exception>
    function ConfigureAuthenticationVerified(const AFirstProtectedPage: Byte;
      const AProtectReads: Boolean; const AExpectedPages, AKey: TBytes)
      : TUltralightCConfiguration;
    /// <summary>Programs the four key pages once in storage byte order and proves the new key after RF reset.</summary>
    /// <param name="ACurrentKey">Exactly 16 current key bytes in cryptographic order, copied before I/O.</param>
    /// <param name="ANewKey">Exactly 16 replacement bytes; each eight-byte subkey is reversed only for EEPROM storage.</param>
    /// <returns>True only after same-UID reactivation, mutual authentication with the new key and successful release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after the first key page dispatch, including partial programming or proof/release.</exception>
    /// <remarks>Key pages cannot be read. No-op keys still receive fresh authentication proof; locked keys are refused before writing.</remarks>
    function ChangeKeyVerified(const ACurrentKey, ANewKey: TBytes): Boolean;
    /// <summary>Explicit inactive raw RF adapter; change only outside an operation.</summary>
    property Reader: IRawContactlessReader read FReader write SetReader;
    /// <summary>Maintained DES/CSPRNG backend; change only outside an operation.</summary>
    property CryptoProvider: ICardDesProvider read FProvider write SetProvider;
    /// <summary>True while one operation owns its RF session and local execution.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Contactless,
  ERD.Card.Contactless.Type2.Password;

procedure Invalid;
begin
  raise EContactlessError.Create('Invalid Ultralight C operation or response.');
end;

procedure CheckPage(const APage: Integer);
begin
  if (APage < UltralightCFirstUserPage) or (APage > UltralightCLastUserPage)
  then
    Invalid;
end;

constructor TUltralightCCardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TUltralightCCardReaderWriter.SetReader(const AValue
  : IRawContactlessReader);
begin
  if FBusy then
    Invalid;
  FReader := AValue;
end;

procedure TUltralightCCardReaderWriter.SetProvider(const AValue
  : ICardDesProvider);
begin
  if FBusy then
    Invalid;
  FProvider := AValue;
end;

procedure TUltralightCCardReaderWriter.Authenticate(const AKey: TBytes);
var
  Key, Zero, Nonce, Payload, Wire, Response, RndB, Plain, Challenge, Rotated,
    CheckNonce: TBytes;
  Dispatched: Boolean;
  I: Integer;
  Raw: TRawRfResponse;
begin
  Key := CopyBytes(AKey);
  Zero := nil;
  Nonce := nil;
  Payload := nil;
  Wire := nil;
  Response := nil;
  RndB := nil;
  Plain := nil;
  Challenge := nil;
  Rotated := nil;
  CheckNonce := nil;
  Raw := Default (TRawRfResponse);
  Dispatched := False;
  try
    try
      Nonce := FProvider.RandomBytes(8);
      if Length(Nonce) <> 8 then
        Invalid;
      SetLength(Zero, 8);
      Payload := HexToBytes('1A00');
      Wire := TRawUidCodec.AppendCrcA(Payload);
      Dispatched := True;
      Raw := FReader.Exchange(Wire, Length(Wire) * 8);
      Response := TRawUidCodec.DecodeCrcA(Raw, 9);
      if Response[0] <> $AF then
        Invalid;
      RndB := TCardDesCrypto.Crypt(FProvider, Key, Zero,
        Copy(Response, 1, 8), False);
      SetLength(Plain, 16);
      Move(Nonce[0], Plain[0], 8);
      for I := 0 to 7 do
        Plain[8 + I] := RndB[(I + 1) mod 8];
      Challenge := TCardDesCrypto.Crypt(FProvider, Key, Copy(Response, 1, 8),
        Plain, True);
      TCardCrypto.Clear(Payload);
      SetLength(Payload, 17);
      Payload[0] := $AF;
      Move(Challenge[0], Payload[1], 16);
      TCardCrypto.Clear(Wire);
      Wire := TRawUidCodec.AppendCrcA(Payload);
      TCardCrypto.Clear(Raw.Data);
      Raw := FReader.Exchange(Wire, Length(Wire) * 8);
      TCardCrypto.Clear(Response);
      Response := TRawUidCodec.DecodeCrcA(Raw, 9);
      if Response[0] <> 0 then
        Invalid;
      CheckNonce := TCardDesCrypto.Crypt(FProvider, Key, Copy(Challenge, 8, 8),
        Copy(Response, 1, 8), False);
      SetLength(Rotated, 8);
      for I := 0 to 7 do
        Rotated[I] := Nonce[(I + 1) mod 8];
      if not TCardCrypto.EqualSecret(Rotated, CheckNonce) then
        Invalid;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EType2AuthenticationError.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Nonce);
    TCardCrypto.Clear(Payload);
    TCardCrypto.Clear(Wire);
    TCardCrypto.Clear(Response);
    TCardCrypto.Clear(RndB);
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Challenge);
    TCardCrypto.Clear(Rotated);
    TCardCrypto.Clear(CheckNonce);
    TCardCrypto.Clear(Raw.Data);
  end;
end;

procedure TUltralightCCardReaderWriter.Acquire(const AKey: TBytes);
var
  Uid, Key: TBytes;
begin
  if FBusy or (FReader = nil) or (FProvider = nil) or (Length(AKey) <> 16) then
    Invalid;
  Key := CopyBytes(AKey);
  FBusy := True;
  try
    try
      FReader.BeginSession;
      try
        Uid := FReader.Activate;
        if Length(Uid) <> 7 then
          Invalid;
        FSelectedUid := CopyBytes(Uid);
        Authenticate(Key);
      except
        try
          FReader.EndSession;
        except
        end;
        raise;
      end;
    except
      TCardCrypto.Clear(FSelectedUid);
      FBusy := False;
      raise;
    end;
  finally
    TCardCrypto.Clear(Key);
  end;
end;

procedure TUltralightCCardReaderWriter.Release(const ASucceeded: Boolean);
begin
  try
    if ASucceeded then
      FReader.EndSession
    else
      try
        FReader.EndSession;
      except
      end;
  finally
    TCardCrypto.Clear(FSelectedUid);
    FBusy := False;
  end;
end;

function TUltralightCCardReaderWriter.ReadPage(const APage: Integer): TBytes;
var
  First: Integer;
  Payload, Wire, Block: TBytes;
begin
  CheckPage(APage);
  First := APage;
  if First > 36 then
    First := 36;
  SetLength(Payload, 2);
  Payload[0] := $30;
  Payload[1] := First;
  Wire := TRawUidCodec.AppendCrcA(Payload);
  Block := TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,
    Length(Wire) * 8), 16);
  Result := Copy(Block, (APage - First) * 4, 4);
end;

function TUltralightCCardReaderWriter.ReadUserPage(const APage: Integer;
  const AKey: TBytes): TBytes;
var
  Data: TBytes;
  Succeeded: Boolean;
begin
  Result := nil;
  CheckPage(APage);
  Acquire(AKey);
  Succeeded := False;
  try
    Data := ReadPage(APage);
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := Data;
end;

function TUltralightCCardReaderWriter.ReadUserMemory
  (const AKey: TBytes): TBytes;
var
  Data, Payload, Wire, Block: TBytes;
  Page: Integer;
  Succeeded: Boolean;
begin
  Result := nil;
  Acquire(AKey);
  Succeeded := False;
  try
    SetLength(Data, UltralightCUserBytes);
    Page := 4;
    while Page <= 36 do
    begin
      SetLength(Payload, 2);
      Payload[0] := $30;
      Payload[1] := Page;
      Wire := TRawUidCodec.AppendCrcA(Payload);
      Block := TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,
        Length(Wire) * 8), 16);
      Move(Block[0], Data[(Page - 4) * 4], 16);
      Inc(Page, 4);
    end;
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := Data;
end;

function TUltralightCCardReaderWriter.WriteUserPageVerified
  (const APage: Integer; const AData, AKey: TBytes): TBytes;
var
  Data, Payload, Wire, Readback: TBytes;
  Raw: TRawRfResponse;
  Succeeded, Dispatched: Boolean;
begin
  Result := nil;
  CheckPage(APage);
  if Length(AData) <> 4 then
    Invalid;
  Data := CopyBytes(AData);
  Dispatched := False;
  try
    Acquire(AKey);
    Succeeded := False;
    try
      SetLength(Payload, 6);
      Payload[0] := $A2;
      Payload[1] := APage;
      Move(Data[0], Payload[2], 4);
      Wire := TRawUidCodec.AppendCrcA(Payload);
      Dispatched := True;
      Raw := FReader.Exchange(Wire, Length(Wire) * 8);
      if Raw.TimedOut or (Raw.BitCount <> 4) or (Length(Raw.Data) <> 1) or
        ((Raw.Data[0] and $F) <> $A) then
        Invalid;
      Readback := ReadPage(APage);
      if not BytesEqual(Data, Readback) then
        Invalid;
      Succeeded := True;
    finally
      Release(Succeeded);
    end;
    Result := Readback;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

function TUltralightCCardReaderWriter.Configuration: TUltralightCConfiguration;
var
  Command: TBytes;
begin
  Result := Default (TUltralightCConfiguration);
  Command := TRawUidCodec.AppendCrcA(HexToBytes('3028'));
  Result.RawPages := TRawUidCodec.DecodeCrcA(FReader.Exchange(Command,
    Length(Command) * 8), 16);
  Result.AuthenticationPages := Copy(Result.RawPages, 8, 8);
  Result.FirstProtectedPage := Result.AuthenticationPages[0];
  if (Result.FirstProtectedPage < 3) or (Result.FirstProtectedPage > 48) then
    Invalid;
  Result.ProtectReads := (Result.AuthenticationPages[4] and 1) = 0;
  Result.Auth0Locked := (Result.RawPages[1] and $20) <> 0;
  Result.Auth1Locked := (Result.RawPages[1] and $40) <> 0;
  Result.KeyLocked := (Result.RawPages[1] and $80) <> 0;
end;

procedure TUltralightCCardReaderWriter.WritePage(const APage: Byte;
  const Data: TBytes; var Dispatched: Boolean);
var
  Payload, Wire: TBytes;
  Raw: TRawRfResponse;
begin
  Payload := nil;
  Wire := nil;
  Raw := Default (TRawRfResponse);
  try
    if Length(Data) <> 4 then
      Invalid;
    SetLength(Payload, 6);
    Payload[0] := $A2;
    Payload[1] := APage;
    Move(Data[0], Payload[2], 4);
    Wire := TRawUidCodec.AppendCrcA(Payload);
    Dispatched := True;
    Raw := FReader.Exchange(Wire, Length(Wire) * 8);
    if Raw.TimedOut or (Raw.BitCount <> 4) or (Length(Raw.Data) <> 1) or
      ((Raw.Data[0] and $F) <> $A) then
      Invalid;
  finally
    TCardCrypto.Clear(Payload);
    TCardCrypto.Clear(Wire);
    TCardCrypto.Clear(Raw.Data);
  end;
end;

procedure TUltralightCCardReaderWriter.Reactivate(const Key: TBytes);
var
  Uid: TBytes;
begin
  Uid := FReader.Activate;
  if not BytesEqual(Uid, FSelectedUid) then
    Invalid;
  Authenticate(Key);
end;

function TUltralightCCardReaderWriter.ReadConfiguration(const AKey: TBytes)
  : TUltralightCConfiguration;
var
  Value: TUltralightCConfiguration;
  Succeeded: Boolean;
begin
  Result := Default (TUltralightCConfiguration);
  Acquire(AKey);
  Succeeded := False;
  try
    Value := Configuration;
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := Value;
end;

function TUltralightCCardReaderWriter.ConfigureAuthenticationVerified
  (const AFirstProtectedPage: Byte; const AProtectReads: Boolean;
  const AExpectedPages, AKey: TBytes): TUltralightCConfiguration;
var
  Expected, Desired, Key: TBytes;
  Original, Actual: TUltralightCConfiguration;
  Succeeded, Dispatched: Boolean;
begin
  Result := Default (TUltralightCConfiguration);
  Dispatched := False;
  Expected := nil;
  Desired := nil;
  Key := nil;
  if (AFirstProtectedPage < 3) or (AFirstProtectedPage > 48) or
    (Length(AExpectedPages) <> 8) or (Length(AKey) <> 16) then
    Invalid;
  try
    Expected := CopyBytes(AExpectedPages);
    Key := CopyBytes(AKey);
    Desired := CopyBytes(Expected);
    Desired[0] := AFirstProtectedPage;
    Desired[4] := Desired[4] and $FE;
    if not AProtectReads then
      Desired[4] := Desired[4] or 1;
    try
      Acquire(Key);
      Succeeded := False;
      try
        Original := Configuration;
        if not BytesEqual(Expected, Original.AuthenticationPages) then
          Invalid;
        if ((Desired[0] <> Expected[0]) and Original.Auth0Locked) or
          ((Desired[4] <> Expected[4]) and Original.Auth1Locked) then
          Invalid;
        if Desired[4] <> Expected[4] then
          WritePage(43, Copy(Desired, 4, 4), Dispatched);
        if Desired[0] <> Expected[0] then
          WritePage(42, Copy(Desired, 0, 4), Dispatched);
        Reactivate(Key);
        Actual := Configuration;
        if not BytesEqual(Desired, Actual.AuthenticationPages) or
          not BytesEqual(Copy(Original.RawPages, 0, 8),
          Copy(Actual.RawPages, 0, 8)) then
          Invalid;
        Succeeded := True;
      finally
        Release(Succeeded);
      end;
      Result := Actual;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Desired);
    TCardCrypto.Clear(Key);
  end;
end;

function TUltralightCCardReaderWriter.ChangeKeyVerified(const ACurrentKey,
  ANewKey: TBytes): Boolean;
var
  Current, Replacement, Storage, Page: TBytes;
  State: TUltralightCConfiguration;
  I: Integer;
  Succeeded, Dispatched: Boolean;
begin
  Current := nil;
  Replacement := nil;
  Storage := nil;
  Page := nil;
  Dispatched := False;
  if (Length(ACurrentKey) <> 16) or (Length(ANewKey) <> 16) then
    Invalid;
  try
    Current := CopyBytes(ACurrentKey);
    Replacement := CopyBytes(ANewKey);
    SetLength(Storage, 16);
    for I := 0 to 7 do
    begin
      Storage[I] := Replacement[7 - I];
      Storage[I + 8] := Replacement[15 - I];
    end;
    try
      Acquire(Current);
      Succeeded := False;
      try
        State := Configuration;
        if not TCardCrypto.EqualSecret(Current, Replacement) then
        begin
          if State.KeyLocked then
            Invalid;
          for I := 0 to 3 do
          begin
            Page := Copy(Storage, I * 4, 4);
            try
              WritePage(44 + I, Page, Dispatched);
            finally
              TCardCrypto.Clear(Page);
            end;
          end;
        end;
        Reactivate(Replacement);
        Succeeded := True;
      finally
        Release(Succeeded);
      end;
      Result := True;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Current);
    TCardCrypto.Clear(Replacement);
    TCardCrypto.Clear(Storage);
    TCardCrypto.Clear(Page);
  end;
end;

end.
