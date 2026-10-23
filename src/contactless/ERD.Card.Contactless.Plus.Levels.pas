unit ERD.Card.Contactless.Plus.Levels;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Contactless,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.Plus;

type
  /// <summary>Explicit Plus SL1 AES authentication and one-way level management using raw Type A framing.</summary>
  /// <remarks>Inactive by construction. RawReader must suppress automatic RATS and retain exclusive RF ownership.
  /// Commands are sent once. SL2 completion has nonce proof/acknowledgement; SL3 also requires fresh protected data proof.</remarks>
  TMifarePlusLevelManager = class(TComponent)
  private
    FRaw: IRawContactlessReader;
    FSl3: IMifarePlusSession;
    FProvider: ICardAesProvider;
    FUid: TBytes;
    FModel: TMifarePlusModel;
    FBusy: Boolean;
    procedure Ready;
    procedure SetRaw(const V: IRawContactlessReader);
    procedure SetSl3(const V: IMifarePlusSession);
    procedure SetProvider(const V: ICardAesProvider);
    procedure SetUid(const V: TBytes);
    function GetUid: TBytes;
    procedure SetModel(const V: TMifarePlusModel);
    function Exchange(const B: TBytes; const AExpected: Integer): TBytes;
    procedure AuthenticateRaw(const ASlot: Word; const AKey: TBytes;
      const AMutating: Boolean; var ADispatched: Boolean;
      const AFirstAuth: Boolean = False);
    procedure SwitchToSl3(const ASwitchKey: TBytes;
      const AProofKeyNumber: Word; const AProofKey: TBytes;
      const AProofBlock: Integer; const AExpectedData: TBytes;
      const AAcknowledge, AFirstAuth: Boolean);
  public
    /// <summary>Creates an inactive explicit 2K profile without reader, thread or credentials.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases retained reader/provider references without activating hardware.</summary>
    destructor Destroy; override;
    /// <summary>Proves the supplied SL1 card-authentication key through native 76/72 mutual AES authentication.</summary>
    /// <param name="AKey">Exactly sixteen supplied bytes for native key 9004; copied before I/O.</param>
    /// <remarks>Nonmutating card authentication only; not a sector data session or inferred security-level detection.</remarks>
    procedure AuthenticateSl1(const AKey: TBytes);
    /// <summary>Authenticates with the explicit SL2 switch key and requires successful native nonce proof and release.</summary>
    /// <param name="ASwitchKey">Exactly sixteen supplied bytes for native key 9002.</param>
    /// <param name="AAcknowledge">Explicit acknowledgement of the irreversible native level change.</param>
    /// <remarks>No independent SL2 sector/session proof is claimed; requires a card explicitly known to be SL1.</remarks>
    /// <exception cref="EContactlessWriteUncertain">Transition dispatch, proof or release cannot be established.</exception>
    procedure SwitchSl1ToSl2Acknowledged(const ASwitchKey: TBytes;
      const AAcknowledge: Boolean);
    /// <summary>Switches one explicit SL1 card to SL3 and proves fresh same-card encrypted data with a supplied sector key.</summary>
    /// <param name="ASwitchKey">Exactly sixteen supplied bytes for native key 9003.</param>
    /// <param name="AProofKeyNumber">Explicit 4000..404F sector key matching model and proof block.</param>
    /// <param name="AProofKey">Exactly sixteen supplied resulting SL3 sector key bytes.</param>
    /// <param name="AProofBlock">Ordinary data block within the proof key's sector.</param>
    /// <param name="AExpectedData">Exactly sixteen expected proof bytes, frozen before raw I/O.</param>
    /// <param name="AAcknowledge">Explicit acknowledgement of the irreversible native level change.</param>
    /// <remarks>Uses separate raw and ISO14443-4 acquisitions; both pin ExpectedUid. No transition/authentication replay or fallback.</remarks>
    /// <exception cref="EContactlessWriteUncertain">Transition or subsequent fresh SL3 proof/release cannot be established.</exception>
    procedure SwitchSl1ToSl3Verified(const ASwitchKey: TBytes;
      const AProofKeyNumber: Word; const AProofKey: TBytes;
      const AProofBlock: Integer; const AExpectedData: TBytes;
      const AAcknowledge: Boolean);
    /// <summary>Switches an explicit SL2 card using raw first AES authentication and proves fresh same-card SL3 data.</summary>
    /// <param name="ASwitchKey">Exactly sixteen supplied bytes for native key 9003.</param>
    /// <param name="AProofKeyNumber">Explicit resulting SL3 sector key address matching model and proof block.</param>
    /// <param name="AProofKey">Exactly sixteen supplied resulting SL3 sector key bytes.</param>
    /// <param name="AProofBlock">Ordinary data block covered by the proof key.</param>
    /// <param name="AExpectedData">Exact sixteen-byte expected proof data, frozen before raw I/O.</param>
    /// <param name="AAcknowledge">Explicit acknowledgement of the irreversible level change.</param>
    /// <remarks>Uses raw 70/72 with empty PCD capabilities, nonce/capability verification and separate fresh ISO14443-4 proof.
    /// No Crypto1 sector session, SL2 key-modifier derivation, level probing or 76/70 fallback is performed.</remarks>
    /// <exception cref="EContactlessWriteUncertain">Transition dispatch or later SL3 proof/release cannot be established.</exception>
    procedure SwitchSl2ToSl3Verified(const ASwitchKey: TBytes;
      const AProofKeyNumber: Word; const AProofKey: TBytes;
      const AProofBlock: Integer; const AExpectedData: TBytes;
      const AAcknowledge: Boolean);
    /// <summary>Retained exclusive raw Type A reader; disable automatic RATS in its explicit configuration.</summary>
    property RawReader: IRawContactlessReader read FRaw write SetRaw;
    /// <summary>Retained exclusive ISO14443-4 backend used only for fresh SL3 post-transition proof.</summary>
    property Sl3Session: IMifarePlusSession read FSl3 write SetSl3;
    /// <summary>Maintained AES/CSPRNG provider; no deterministic or fallback production nonces.</summary>
    property CryptoProvider: ICardAesProvider read FProvider write SetProvider;
    /// <summary>Required copied four/seven/ten-byte UID checked before credentials in each acquisition.</summary>
    property ExpectedUid: TBytes read GetUid write SetUid;
    /// <summary>True during complete raw authentication/transition and fresh SL3 verification.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Explicit geometry for SL3 proof; default 2K, never probed.</summary>
    property Model: TMifarePlusModel read FModel write SetModel default mpm2K;
  end;

implementation

procedure Invalid;
begin
  raise EMifarePlusError.Create('Invalid explicit Plus level profile, identity or authentication.');
end;

constructor TMifarePlusLevelManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TMifarePlusLevelManager.Destroy;
begin
  FRaw := nil;
  FSl3 := nil;
  FProvider := nil;
  inherited Destroy;
end;

procedure TMifarePlusLevelManager.Ready;
begin
  if FBusy then
    Invalid;
end;

procedure TMifarePlusLevelManager.SetRaw(const V: IRawContactlessReader);
begin
  Ready;
  FRaw := V;
end;

procedure TMifarePlusLevelManager.SetSl3(const V: IMifarePlusSession);
begin
  Ready;
  FSl3 := V;
end;

procedure TMifarePlusLevelManager.SetProvider(const V: ICardAesProvider);
begin
  Ready;
  FProvider := V;
end;

procedure TMifarePlusLevelManager.SetUid(const V: TBytes);
begin
  Ready;
  if not (Length(V) in [0, 4, 7, 10]) then
    Invalid;
  FUid := CopyBytes(V);
end;

function TMifarePlusLevelManager.GetUid: TBytes;
begin
  Result := CopyBytes(FUid);
end;

procedure TMifarePlusLevelManager.SetModel(const V: TMifarePlusModel);
begin
  Ready;
  if not (V in [mpm2K, mpm4K]) then
    Invalid;
  FModel := V;
end;

function TMifarePlusLevelManager.Exchange(const B: TBytes;
  const AExpected: Integer): TBytes;
var
  Frame: TBytes;
  R: TRawRfResponse;
begin
  Frame := TRawUidCodec.AppendCrcA(B);
  R := Default(TRawRfResponse);
  try
    R := FRaw.Exchange(Frame, Length(Frame) * 8);
    Result := TRawUidCodec.DecodeCrcA(R, AExpected);
    if (Length(Result) < 1) or (Result[0] <> $90) then
      Invalid;
  finally
    TCardCrypto.Clear(Frame);
    TCardCrypto.Clear(R.Data);
  end;
end;

procedure TMifarePlusLevelManager.AuthenticateRaw(const ASlot: Word;
  const AKey: TBytes; const AMutating: Boolean; var ADispatched: Boolean;
  const AFirstAuth: Boolean);
var
  Key, Uid, Zero, R, A, B, Rotated, Plain, Cipher, Packet: TBytes;
  I, ResponseLength, NonceOffset: Integer;
  Ok: Boolean;
begin
  if (FRaw = nil) or (FProvider = nil) or (Length(FUid) = 0) or
    (Length(AKey) <> 16) then
    Invalid;
  Key := CopyBytes(AKey);
  Zero := nil;
  SetLength(Zero, 16);
  Ok := False;
  try
    FRaw.BeginSession;
    try
      Uid := FRaw.Activate;
      if not BytesEqual(Uid, FUid) then
        Invalid;
      Packet := HexToBytes('760000');
      if AFirstAuth then
        Packet := HexToBytes('70000000');
      Packet[1] := Byte(ASlot and $FF);
      Packet[2] := Byte(ASlot shr 8);
      R := Exchange(Packet, 17);
      B := FProvider.DecryptCbc(Key, Zero, Copy(R, 1, 16));
      if Length(B) <> 16 then
        Invalid;
      A := FProvider.RandomBytes(16);
      if Length(A) <> 16 then
        Invalid;
      Plain := nil;
      SetLength(Plain, 32);
      Move(A[0], Plain[0], 16);
      for I := 0 to 15 do
        Plain[16 + I] := B[(I + 1) mod 16];
      Cipher := FProvider.EncryptCbc(Key, Zero, Plain);
      if Length(Cipher) <> 32 then
        Invalid;
      Packet := nil;
      SetLength(Packet, 33);
      Packet[0] := $72;
      Move(Cipher[0], Packet[1], 32);
      if AMutating then
        ADispatched := True;
      ResponseLength := 17;
      NonceOffset := 0;
      if AFirstAuth then
      begin
        ResponseLength := 33;
        NonceOffset := 4;
      end;
      R := Exchange(Packet, ResponseLength);
      TCardCrypto.Clear(Plain);
      Plain := FProvider.DecryptCbc(Key, Zero, Copy(R, 1, ResponseLength - 1));
      if Length(Plain) <> ResponseLength - 1 then
        Invalid;
      Rotated := nil;
      SetLength(Rotated, 16);
      for I := 0 to 15 do
        Rotated[I] := A[(I + 1) mod 16];
      if not TCardCrypto.EqualSecret(Copy(Plain, NonceOffset, 16), Rotated) then
        Invalid;
      if AFirstAuth then
        for I := 26 to 31 do
          if Plain[I] <> 0 then
            Invalid;
      Ok := True;
    finally
      if Ok then
        FRaw.EndSession
      else
        try FRaw.EndSession; except end;
    end;
  finally
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(A);
    TCardCrypto.Clear(B);
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(Packet);
    TCardCrypto.Clear(R);
    TCardCrypto.Clear(Rotated);
  end;
end;

procedure TMifarePlusLevelManager.AuthenticateSl1(const AKey: TBytes);
var
  Dispatched: Boolean;
begin
  Ready;
  Dispatched := False;
  FBusy := True;
  try
    AuthenticateRaw($9004, AKey, False, Dispatched);
  finally
    FBusy := False;
  end;
end;

procedure TMifarePlusLevelManager.SwitchSl1ToSl2Acknowledged(
  const ASwitchKey: TBytes; const AAcknowledge: Boolean);
var
  Dispatched: Boolean;
begin
  Ready;
  if not AAcknowledge then
    Invalid;
  Dispatched := False;
  FBusy := True;
  try
    try
      AuthenticateRaw($9002, ASwitchKey, True, Dispatched);
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    FBusy := False;
  end;
end;

procedure TMifarePlusLevelManager.SwitchToSl3(const ASwitchKey: TBytes;
  const AProofKeyNumber: Word; const AProofKey: TBytes;
  const AProofBlock: Integer; const AExpectedData: TBytes;
  const AAcknowledge, AFirstAuth: Boolean);
var
  Key, Expected, Data: TBytes;
  Proof: TMifarePlusCardReaderWriter;
  Sector: Integer;
  Dispatched: Boolean;
begin
  Ready;
  if not AAcknowledge or (FSl3 = nil) or (Length(AProofKey) <> 16) or
    (Length(AExpectedData) <> 16) then
    Invalid;
  Sector := TMifarePlusCodec.DataSector(FModel, AProofBlock);
  if (AProofKeyNumber < $4000) or (AProofKeyNumber > $404F) or
    ((AProofKeyNumber - $4000) div 2 <> Sector) then
    Invalid;
  Key := CopyBytes(ASwitchKey);
  Expected := CopyBytes(AExpectedData);
  Proof := nil;
  Dispatched := False;
  FBusy := True;
  try
    Proof := TMifarePlusCardReaderWriter.Create(nil);
    Proof.Session := FSl3;
    Proof.CryptoProvider := FProvider;
    Proof.Model := FModel;
    Proof.Communication := mpcFull;
    Proof.KeyNumber := AProofKeyNumber;
    Proof.Key := AProofKey;
    Proof.ExpectedUid := FUid;
    try
      AuthenticateRaw($9003, Key, True, Dispatched, AFirstAuth);
      Data := Proof.ReadBlocks(AProofBlock, 1);
      if not BytesEqual(Data, Expected) then
        Invalid;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    Proof.Free;
    TCardCrypto.Clear(Key);
    TCardCrypto.Clear(Expected);
    TCardCrypto.Clear(Data);
    FBusy := False;
  end;
end;

procedure TMifarePlusLevelManager.SwitchSl1ToSl3Verified(const ASwitchKey: TBytes;
  const AProofKeyNumber: Word; const AProofKey: TBytes;
  const AProofBlock: Integer; const AExpectedData: TBytes;
  const AAcknowledge: Boolean);
begin
  SwitchToSl3(ASwitchKey, AProofKeyNumber, AProofKey, AProofBlock,
    AExpectedData, AAcknowledge, False);
end;

procedure TMifarePlusLevelManager.SwitchSl2ToSl3Verified(const ASwitchKey: TBytes;
  const AProofKeyNumber: Word; const AProofKey: TBytes;
  const AProofBlock: Integer; const AExpectedData: TBytes;
  const AAcknowledge: Boolean);
begin
  SwitchToSl3(ASwitchKey, AProofKeyNumber, AProofKey, AProofBlock,
    AExpectedData, AAcknowledge, True);
end;

end.
