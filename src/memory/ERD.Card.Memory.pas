unit ERD.Card.Memory;

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
  ERD.Card.Transport;

const
  /// <summary>Maximum complete supported memory image: one 1024-kilobit I2C chip.</summary>
  MemoryCardMaxBytes = 131072;
  /// <summary>Maximum payload per read or ordinary write; avoids ambiguous zero-length APDUs.</summary>
  MemoryCardChunkBytes = 128;

type
  /// <summary>Invalid geometry, operation, framing, protection or reader status; messages contain no card bytes.</summary>
  EMemoryCardError = class(Exception);
  /// <summary>A PIN attempt was dispatched but could not be verified; never automatically repeat it.</summary>
  EMemoryCardAuthenticationError = class(EMemoryCardError);

  /// <summary>A dispatched mutation may have changed card state; no replay or rollback is performed.</summary>
  EMemoryCardWriteUncertain = class(EMemoryCardError)
  private
    FVerified: Boolean;
    FOriginalErrorClass: string;
  public
    /// <summary>Creates a sanitized mutation failure, retaining read-back evidence.</summary>
    /// <param name="AOriginalErrorClass">Original exception class only; no backend message.</param>
    /// <param name="AVerified">True if requested state was verified before a later release failure.</param>
    constructor Create(const AOriginalErrorClass: string;
      const AVerified: Boolean); reintroduce;
    /// <summary>True if requested state was verified; cleanup can still have failed.</summary>
    property Verified: Boolean read FVerified;
    /// <summary>Original exception class without potentially sensitive text.</summary>
    property OriginalErrorClass: string read FOriginalErrorClass;
  end;

  /// <summary>Caller-identified chip geometry; selection does not prove chip identity.</summary>
  TMemoryCardModel = (
    /// <summary>256-byte two-wire memory without a PIN.</summary>
    mcmSle4432,
    /// <summary>256-byte two-wire memory with a three-byte PIN.</summary>
    mcmSle4442,
    /// <summary>256-byte two-wire memory without a PIN.</summary>
    mcmSle5532,
    /// <summary>256-byte two-wire memory with a three-byte PIN.</summary>
    mcmSle5542,
    /// <summary>1024-byte three-wire memory without a PIN.</summary>
    mcmSle4418,
    /// <summary>1024-byte three-wire memory with a two-byte PIN.</summary>
    mcmSle4428,
    /// <summary>1024-byte three-wire memory without a PIN.</summary>
    mcmSle5518,
    /// <summary>1024-byte three-wire memory with a two-byte PIN.</summary>
    mcmSle5528,
    /// <summary>Explicit 1-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c1Kbit,
    /// <summary>Explicit 2-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c2Kbit,
    /// <summary>Explicit 4-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c4Kbit,
    /// <summary>Explicit 8-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c8Kbit,
    /// <summary>Explicit 16-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c16Kbit,
    /// <summary>Explicit 32-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c32Kbit,
    /// <summary>Explicit 64-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c64Kbit,
    /// <summary>Explicit 128-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c128Kbit,
    /// <summary>Explicit 256-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c256Kbit,
    /// <summary>Explicit 512-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c512Kbit,
    /// <summary>Explicit 1024-kilobit I2C memory geometry; physical page size must also be supplied.</summary>
    mcmI2c1024Kbit);
  /// <summary>Explicit documented ACS reader dialect; response shapes are never guessed.</summary>
  TAcsMemoryDialect = (
    /// <summary>ACR38x CCID reference 6.05; two-wire reads return requested bytes only.</summary>
    amdAcr38Ccid,
    /// <summary>ACR39 Series reference 1.05; two-wire reads additionally return four protection bytes.</summary>
    amdAcr39);
  /// <summary>Physical I2C write page size; never inferred from capacity or ATR.</summary>
  TMemoryCardPageSize = (
    /// <summary>Eight bytes per physical page.</summary>
    mps8,
    /// <summary>Sixteen bytes per physical page.</summary>
    mps16,
    /// <summary>Thirty-two bytes per physical page.</summary>
    mps32,
    /// <summary>Sixty-four bytes per physical page.</summary>
    mps64,
    /// <summary>One hundred twenty-eight bytes per physical page.</summary>
    mps128);

  /// <summary>Bounded geometry for an explicitly identified chip model.</summary>
  TMemoryCardLayout = record
    /// <summary>Main-memory bytes: 256, 1024 or 128 through 131072.</summary>
    Capacity: Integer;
    /// <summary>Required PIN length: zero, two or three bytes.</summary>
    PinBytes: Integer;
    /// <summary>Bytes with irreversible protection bits: 32, 1024 or zero.</summary>
    ProtectableBytes: Integer;
    /// <summary>ACS SELECT_CARD_TYPE selector: 01, 02, 05 or 06.</summary>
    Selector: Byte;
  end;

  /// <summary>PIN retry bitmap; an erased counter is not proof that the caller authenticated.</summary>
  TMemoryCardSecurityStatus = record
    /// <summary>Reader-reported retry bitmap, at most seven for two-wire chips.</summary>
    Counter: Byte;
    /// <summary>Number of remaining set retry bits: zero through three or eight.</summary>
    RemainingAttempts: Integer;
    /// <summary>True when no retry bits remain; no authentication is then attempted.</summary>
    Blocked: Boolean;
  end;

  /// <summary>Complete independently allocated main memory and protection snapshot.</summary>
  /// <remarks>Record assignment shares dynamic arrays; use Copy when making another owned copy.</remarks>
  TMemoryCardSnapshot = record
    /// <summary>Caller-supplied model, not a detected chip identity.</summary>
    Model: TMemoryCardModel;
    /// <summary>Main memory in ascending physical byte order.</summary>
    Data: TBytes;
    /// <summary>Protection bitmap in card order; bit zero controls byte zero, zero means locked.</summary>
    Protection: TBytes;
    /// <summary>True only for PIN-equipped SLE models.</summary>
    HasSecurity: Boolean;
    /// <summary>PIN retry status when HasSecurity is true; no PIN bytes are returned.</summary>
    Security: TMemoryCardSecurityStatus;
  end;

  /// <summary>Pure geometry and ACS pseudo-APDU builders; no I/O, probing or PIN guessing.</summary>
  TMemoryCardCodec = class
  public
    /// <summary>Returns validated model geometry.</summary>
    /// <param name="AModel">Explicit supported chip model.</param>
    /// <returns>Geometry; invalid enum values raise EMemoryCardError.</returns>
    class function Layout(const AModel: TMemoryCardModel)
      : TMemoryCardLayout; static;
    /// <summary>Builds ACS selection, which power-cycles and resets the card.</summary>
    /// <param name="AModel">Explicit supported chip model.</param>
    /// <returns>Owned FF A4 00 00 01 selector.</returns>
    class function Select(const AModel: TMemoryCardModel): TBytes; static;
    /// <summary>Builds explicit I2C page-size configuration.</summary>
    /// <param name="APageSize">Known physical page size, eight through 128 bytes.</param>
    /// <returns>Owned FF 01 command; invalid enum values raise.</returns>
    class function SelectPage(const APageSize: TMemoryCardPageSize)
      : TBytes; static;
    /// <summary>Builds a bounded main-memory read, including the 17th I2C address bit.</summary>
    /// <param name="AModel">Explicit geometry.</param>
    /// <param name="AAddress">Zero-based address within main memory.</param>
    /// <param name="ACount">One through 128 bytes; must not cross capacity or a 64-KiB bank.</param>
    /// <returns>Owned FF B0/B1 pseudo-APDU; no zero length.</returns>
    class function Read(const AModel: TMemoryCardModel;
      const AAddress, ACount: Integer): TBytes; static;
    /// <summary>Builds one ordinary write without crossing I2C pages or address banks.</summary>
    /// <param name="AModel">Explicit geometry.</param>
    /// <param name="APageSize">Known physical I2C page size; validated even for SLE.</param>
    /// <param name="AAddress">Zero-based address within main memory.</param>
    /// <param name="AData">One through 128 borrowed bytes; copied without modification.</param>
    /// <returns>Owned FF D0/D1 command. D1 is the high bank for 1024-kilobit I2C, not an SLE protection command.</returns>
    class function Write(const AModel: TMemoryCardModel;
      const APageSize: TMemoryCardPageSize; const AAddress: Integer;
      const AData: TBytes): TBytes; static;
    /// <summary>Builds a complete SLE protection-bitmap read.</summary>
    /// <param name="AModel">SLE two-wire or three-wire model; I2C is rejected.</param>
    /// <returns>Owned FF B2; four bytes for two-wire and 128 for three-wire.</returns>
    class function ReadProtection(const AModel: TMemoryCardModel)
      : TBytes; static;
    /// <summary>Builds a PIN retry-counter read.</summary>
    /// <param name="AModel">PIN-equipped SLE model; other models are rejected.</param>
    /// <returns>Owned FF B1 with four or three response bytes, including dummy bytes.</returns>
    class function ReadCounter(const AModel: TMemoryCardModel): TBytes; static;
    /// <summary>Builds one supplied-PIN attempt.</summary>
    /// <param name="AModel">PIN-equipped SLE model.</param>
    /// <param name="APin">Exactly two or three card-order bytes; copied, never guessed.</param>
    /// <returns>Owned PIN-bearing FF 20 command; caller must wipe it.</returns>
    class function Verify(const AModel: TMemoryCardModel; const APin: TBytes)
      : TBytes; static;
    /// <summary>Builds the documented two-wire PIN replacement.</summary>
    /// <param name="AModel">SLE4442 or SLE5542; three-wire PIN changes are not documented and are rejected.</param>
    /// <param name="ANewPin">Exactly three borrowed card-order bytes.</param>
    /// <returns>Owned PIN-bearing FF D2 00 01 03 command; caller must wipe it.</returns>
    class function ChangePin(const AModel: TMemoryCardModel;
      const ANewPin: TBytes): TBytes; static;
    /// <summary>Builds irreversible compare-and-lock protection for an SLE range.</summary>
    /// <param name="AModel">Explicit SLE model; I2C has no supported protection bitmap.</param>
    /// <param name="AAddress">Start within ProtectableBytes.</param>
    /// <param name="AExpected">One through 128 expected main-memory bytes, wholly inside the protectable region.</param>
    /// <returns>Owned FF D1 command; matching bytes become permanently write-protected.</returns>
    class function Protect(const AModel: TMemoryCardModel;
      const AAddress: Integer; const AExpected: TBytes): TBytes; static;
    /// <summary>Validates the explicit reader data shape and copies only main-memory bytes.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <param name="ADialect">Known ACR38 CCID or ACR39 dialect.</param>
    /// <param name="ACount">Requested byte count, one through 128.</param>
    /// <param name="AData">Borrowed successful response data, excluding status bytes.</param>
    /// <returns>Owned exact ACount bytes; ACR39 two-wire protection trailer is stripped.</returns>
    class function DecodeRead(const AModel: TMemoryCardModel;
      const ADialect: TAcsMemoryDialect; const ACount: Integer;
      const AData: TBytes): TBytes; static;
    /// <summary>Validates and decodes a reader retry counter without exposing dummy bytes.</summary>
    /// <param name="AModel">PIN-equipped SLE model.</param>
    /// <param name="AData">Exactly three or four successful response bytes; dummy data is ignored.</param>
    /// <returns>Bitmap/popcount/blocked status; no credentials or inferred authenticated state.</returns>
    class function DecodeSecurity(const AModel: TMemoryCardModel;
      const AData: TBytes): TMemoryCardSecurityStatus; static;
  end;

  /// <summary>Nonvisual verified memory access through an explicitly selected ACS reader dialect.</summary>
  /// <remarks>Use on one owning thread without reentrancy. Every operation requires an exclusive
  /// ICardTransaction, resets/selects once, and never retries APDUs. PINs are supplied per operation;
  /// local PIN-bearing copies are wiped, but external transport copies are outside that guarantee.
  /// No Java applet, payment, ATR probing, default PIN or secure messaging is involved.</remarks>
  TMemoryCardReaderWriter = class(TComponent)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FModel: TMemoryCardModel;
    FDialect: TAcsMemoryDialect;
    FPageSize: TMemoryCardPageSize;
    FMinimumPinAttempts: Integer;
    FBusy: Boolean;
    procedure RequireIdle;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetModel(const AValue: TMemoryCardModel);
    procedure SetDialect(const AValue: TAcsMemoryDialect);
    procedure SetPageSize(const AValue: TMemoryCardPageSize);
    procedure SetMinimumPinAttempts(const AValue: Integer);
    procedure ValidatePin(const APin: TBytes);
    procedure BeginOperation;
    procedure FinishOperation(const ASucceeded: Boolean);
    procedure SelectCard;
    function Send(const ACommand: TBytes;
      const AExpectedStatus: Word = $9000): TBytes;
    function ReadSelected(const AAddress, ACount: Integer): TBytes;
    function ProtectionSelected: TBytes;
    function SecuritySelected: TMemoryCardSecurityStatus;
    function Authenticate(const APin: TBytes): TMemoryCardSecurityStatus;
    procedure CheckUnlocked(const AAddress, ACount: Integer;
      const AProtection: TBytes);
  public
    /// <summary>Creates an inactive SLE4442/ACR38-CCID component with an eight-byte I2C page default.</summary>
    /// <param name="AOwner">Optional component owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads a bounded public main-memory range in one exclusive transaction.</summary>
    /// <param name="AAddress">Zero-based start within the selected model.</param>
    /// <param name="ACount">One through remaining capacity; no PIN attempt is made.</param>
    /// <returns>Owned bytes only after successful transaction release; no partial result on failure.</returns>
    function ReadMemory(const AAddress, ACount: Integer): TBytes;
    /// <summary>Reads complete main memory, SLE protection and available PIN retry status.</summary>
    /// <returns>Independent snapshot after release; no authentication and no PIN/dummy bytes.</returns>
    function ReadSnapshot: TMemoryCardSnapshot;
    /// <summary>Verifies a supplied PIN once and checks the restored counter in the retained transaction.</summary>
    /// <param name="APin">Two or three card-order bytes for a PIN-equipped SLE model.</param>
    /// <returns>Verified counter after successful release; authentication is not retained for a later operation.</returns>
    /// <exception cref="EMemoryCardAuthenticationError">The dispatched attempt was rejected or not verified.</exception>
    function VerifyPin(const APin: TBytes): TMemoryCardSecurityStatus;
    /// <summary>Writes an unlocked range once per chunk and independently verifies every changed chunk.</summary>
    /// <param name="AAddress">Start within main memory; locked SLE bytes are rejected before authentication/writing.</param>
    /// <param name="AData">Nonempty bytes within remaining capacity; copied before I/O.</param>
    /// <param name="APin">Required card-order PIN for secured SLE; empty for plain SLE/I2C.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after mutation dispatch, including release.</exception>
    /// <remarks>I2C chunks stay within physical pages and 64-KiB banks. Identical data is a no-op,
    /// with no PIN attempt; this does not authenticate the supplied PIN. No rollback or replay.</remarks>
    procedure WriteMemory(const AAddress: Integer; const AData, APin: TBytes);
    /// <summary>Changes a SLE4442/5542 PIN and verifies it after an explicit reset in the same transaction.</summary>
    /// <param name="AOldPin">Exactly three supplied current PIN bytes; one attempt.</param>
    /// <param name="ANewPin">Exactly three new PIN bytes; verified once after update and reset.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after the PIN-change command was dispatched.</exception>
    /// <remarks>Three-wire PIN replacement is not documented by these reader profiles and is rejected before I/O.
    /// Success requires new-PIN proof and successful release. No fallback to the old PIN or automatic retry.</remarks>
    procedure ChangePin(const AOldPin, ANewPin: TBytes);
    /// <summary>Irreversibly locks an SLE range after matching its supplied expected contents.</summary>
    /// <param name="AAddress">Start within the model's protectable region.</param>
    /// <param name="AExpected">Nonempty expected current bytes; mismatch is rejected before locking.</param>
    /// <param name="APin">Required PIN for secured SLE; empty for plain SLE.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after protection dispatch.</exception>
    /// <remarks>Zero protection bits cannot be erased. Success verifies locked bits and unchanged data.
    /// An already fully locked matching range is a no-op without a PIN attempt.</remarks>
    procedure ProtectMemory(const AAddress: Integer;
      const AExpected, APin: TBytes);
    /// <summary>Connected caller-owned transport retained by interface; must support exclusive ICardTransaction.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
  published
    /// <summary>Explicit chip model; defaults to SLE4442. Never inferred from an ATR or failed command.</summary>
    property Model: TMemoryCardModel read FModel write SetModel
      default mcmSle4442;
    /// <summary>Documented reader dialect; defaults to ACR38 CCID. Set ACR39 explicitly for its read trailer.</summary>
    property Dialect: TAcsMemoryDialect read FDialect write SetDialect
      default amdAcr38Ccid;
    /// <summary>Known physical I2C page size; default eight. Ignored for SLE writes.</summary>
    property PageSize: TMemoryCardPageSize read FPageSize write SetPageSize
      default mps8;
    /// <summary>Minimum remaining retry bits before a PIN attempt, one through eight; default one.</summary>
    property MinimumPinAttempts: Integer read FMinimumPinAttempts
      write SetMinimumPinAttempts default 1;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EMemoryCardError.Create('Memory card operation failed: ' +
    AReason + '.');
end;

procedure Wipe(var ABytes: TBytes);
var
  I: Integer;
begin
  for I := 0 to Length(ABytes) - 1 do
    ABytes[I] := 0;
  ABytes := nil;
end;

function PageBytes(const ASize: TMemoryCardPageSize): Integer;
begin
  if not(ASize in [mps8 .. mps128]) then
    Fail('page size');
  Result := 8 shl Ord(ASize);
end;

procedure ValidateRange(const AModel: TMemoryCardModel;
  const AAddress, ACount: Integer);
var
  L: TMemoryCardLayout;
begin
  L := TMemoryCardCodec.Layout(AModel);
  if (AAddress < 0) or (AAddress >= L.Capacity) or (ACount < 1) or
    (ACount > L.Capacity - AAddress) then
    Fail('range');
end;

procedure ValidateChunk(const AModel: TMemoryCardModel;
  const AAddress, ACount: Integer);
begin
  ValidateRange(AModel, AAddress, ACount);
  if (ACount > MemoryCardChunkBytes) or (ACount > 65536 - (AAddress and $FFFF))
  then
    Fail('chunk');
end;

function Command(const AIns: Byte; const AAddress, ALength: Integer;
  const AData: TBytes): TBytes;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, 5 + Length(AData));
  Result[0] := $FF;
  Result[1] := AIns;
  Result[2] := Byte((AAddress shr 8) and $FF);
  Result[3] := Byte(AAddress and $FF);
  Result[4] := Byte(ALength);
  for I := 0 to Length(AData) - 1 do
    Result[5 + I] := AData[I];
end;

constructor EMemoryCardWriteUncertain.Create(const AOriginalErrorClass: string;
  const AVerified: Boolean);
begin
  inherited Create
    ('Memory card mutation outcome is uncertain; inspect card state before any further mutation.');
  FOriginalErrorClass := AOriginalErrorClass;
  FVerified := AVerified;
end;

class function TMemoryCardCodec.Layout(const AModel: TMemoryCardModel)
  : TMemoryCardLayout;
begin
  Result := Default (TMemoryCardLayout);
  case AModel of
    mcmSle4432, mcmSle4442, mcmSle5532, mcmSle5542:
      begin
        Result.Capacity := 256;
        Result.ProtectableBytes := 32;
        Result.Selector := 6;
      end;
    mcmSle4418, mcmSle4428, mcmSle5518, mcmSle5528:
      begin
        Result.Capacity := 1024;
        Result.ProtectableBytes := 1024;
        Result.Selector := 5;
      end;
    mcmI2c1Kbit .. mcmI2c1024Kbit:
      begin
        Result.Capacity := 128 shl (Ord(AModel) - Ord(mcmI2c1Kbit));
        if Result.Capacity <= 2048 then
          Result.Selector := 1
        else
          Result.Selector := 2;
      end;
  else
    Fail('model');
  end;
  case AModel of
    mcmSle4442, mcmSle5542:
      Result.PinBytes := 3;
    mcmSle4428, mcmSle5528:
      Result.PinBytes := 2;
  end;
end;

class function TMemoryCardCodec.Select(const AModel: TMemoryCardModel): TBytes;
var
  B: TBytes;
  L: TMemoryCardLayout;
begin
  L := Layout(AModel);
  B := nil;
  SetLength(B, 1);
  B[0] := L.Selector;
  Result := Command($A4, 0, 1, B);
end;

class function TMemoryCardCodec.SelectPage(const APageSize
  : TMemoryCardPageSize): TBytes;
var
  B: TBytes;
begin
  PageBytes(APageSize);
  B := nil;
  SetLength(B, 1);
  B[0] := Byte(Ord(APageSize) + 3);
  Result := Command($01, 0, 1, B);
end;

class function TMemoryCardCodec.Read(const AModel: TMemoryCardModel;
  const AAddress, ACount: Integer): TBytes;
begin
  ValidateChunk(AModel, AAddress, ACount);
  Result := Command(Byte($B0 or (AAddress shr 16)), AAddress, ACount, nil);
end;

class function TMemoryCardCodec.Write(const AModel: TMemoryCardModel;
  const APageSize: TMemoryCardPageSize; const AAddress: Integer;
  const AData: TBytes): TBytes;
var
  L: TMemoryCardLayout;
  Size: Integer;
begin
  L := Layout(AModel);
  Size := PageBytes(APageSize);
  ValidateChunk(AModel, AAddress, Length(AData));
  if (L.Selector <= 2) and (Length(AData) > Size - (AAddress mod Size)) then
    Fail('page crossing');
  Result := Command(Byte($D0 or (AAddress shr 16)), AAddress,
    Length(AData), AData);
end;

class function TMemoryCardCodec.ReadProtection(const AModel
  : TMemoryCardModel): TBytes;
var
  L: TMemoryCardLayout;
begin
  L := Layout(AModel);
  if L.ProtectableBytes = 0 then
    Fail('no protection bitmap');
  Result := Command($B2, 0, L.ProtectableBytes div 8, nil);
end;

class function TMemoryCardCodec.ReadCounter(const AModel
  : TMemoryCardModel): TBytes;
var
  L: TMemoryCardLayout;
begin
  L := Layout(AModel);
  if L.PinBytes = 0 then
    Fail('no PIN');
  Result := Command($B1, 0, L.PinBytes + 1, nil);
end;

class function TMemoryCardCodec.Verify(const AModel: TMemoryCardModel;
  const APin: TBytes): TBytes;
var
  L: TMemoryCardLayout;
begin
  L := Layout(AModel);
  if (L.PinBytes = 0) or (Length(APin) <> L.PinBytes) then
    Fail('PIN length');
  Result := Command($20, 0, L.PinBytes, APin);
end;

class function TMemoryCardCodec.ChangePin(const AModel: TMemoryCardModel;
  const ANewPin: TBytes): TBytes;
begin
  if not(AModel in [mcmSle4442, mcmSle5542]) then
    Fail('PIN change unsupported');
  if Length(ANewPin) <> 3 then
    Fail('PIN length');
  Result := Command($D2, 1, 3, ANewPin);
end;

class function TMemoryCardCodec.Protect(const AModel: TMemoryCardModel;
  const AAddress: Integer; const AExpected: TBytes): TBytes;
var
  L: TMemoryCardLayout;
begin
  L := Layout(AModel);
  ValidateChunk(AModel, AAddress, Length(AExpected));
  if (L.ProtectableBytes = 0) or (AAddress >= L.ProtectableBytes) or
    (Length(AExpected) > L.ProtectableBytes - AAddress) then
    Fail('protection range');
  Result := Command($D1, AAddress, Length(AExpected), AExpected);
end;

class function TMemoryCardCodec.DecodeRead(const AModel: TMemoryCardModel;
  const ADialect: TAcsMemoryDialect; const ACount: Integer;
  const AData: TBytes): TBytes;
var
  L: TMemoryCardLayout;
  Extra: Integer;
begin
  L := Layout(AModel);
  if not(ADialect in [amdAcr38Ccid, amdAcr39]) then
    Fail('reader dialect');
  if (ACount < 1) or (ACount > MemoryCardChunkBytes) then
    Fail('read size');
  Extra := 0;
  if (ADialect = amdAcr39) and (L.Selector = 6) then
    Extra := 4;
  if Length(AData) <> ACount + Extra then
    Fail('read response length');
  Result := Copy(AData, 0, ACount);
end;

class function TMemoryCardCodec.DecodeSecurity(const AModel: TMemoryCardModel;
  const AData: TBytes): TMemoryCardSecurityStatus;
var
  L: TMemoryCardLayout;
  Bits, I: Integer;
begin
  L := Layout(AModel);
  if (L.PinBytes = 0) or (Length(AData) <> L.PinBytes + 1) then
    Fail('counter response length');
  Result := Default (TMemoryCardSecurityStatus);
  Result.Counter := AData[0];
  Bits := 8;
  if L.PinBytes = 3 then
  begin
    Bits := 3;
    if AData[0] > 7 then
      Fail('counter reserved bits');
  end;
  for I := 0 to Bits - 1 do
    if (AData[0] and (1 shl I)) <> 0 then
      Inc(Result.RemainingAttempts);
  Result.Blocked := Result.RemainingAttempts = 0;
end;

constructor TMemoryCardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModel := mcmSle4442;
  FMinimumPinAttempts := 1;
end;

procedure TMemoryCardReaderWriter.RequireIdle;
begin
  if FBusy then
    Fail('operation already active');
end;

procedure TMemoryCardReaderWriter.SetTransport(const AValue: ICardTransport);
begin
  RequireIdle;
  FTransport := AValue;
end;

procedure TMemoryCardReaderWriter.SetModel(const AValue: TMemoryCardModel);
begin
  RequireIdle;
  TMemoryCardCodec.Layout(AValue);
  FModel := AValue;
end;

procedure TMemoryCardReaderWriter.SetDialect(const AValue: TAcsMemoryDialect);
begin
  RequireIdle;
  if not(AValue in [amdAcr38Ccid, amdAcr39]) then
    Fail('reader dialect');
  FDialect := AValue;
end;

procedure TMemoryCardReaderWriter.SetPageSize(const AValue
  : TMemoryCardPageSize);
begin
  RequireIdle;
  PageBytes(AValue);
  FPageSize := AValue;
end;

procedure TMemoryCardReaderWriter.SetMinimumPinAttempts(const AValue: Integer);
begin
  RequireIdle;
  if (AValue < 1) or (AValue > 8) then
    Fail('retry policy');
  FMinimumPinAttempts := AValue;
end;

procedure TMemoryCardReaderWriter.ValidatePin(const APin: TBytes);
var
  L: TMemoryCardLayout;
begin
  L := TMemoryCardCodec.Layout(FModel);
  if Length(APin) <> L.PinBytes then
    Fail('PIN length');
end;

procedure TMemoryCardReaderWriter.BeginOperation;
begin
  RequireIdle;
  if (FTransport = nil) or not Supports(FTransport, ICardTransaction,
    FTransaction) then
    Fail('exclusive transaction required');
  FBusy := True;
  try
    FTransaction.BeginTransaction;
  except
    FTransaction := nil;
    FBusy := False;
    raise;
  end;
end;

procedure TMemoryCardReaderWriter.FinishOperation(const ASucceeded: Boolean);
var
  Transaction: ICardTransaction;
begin
  Transaction := FTransaction;
  FTransaction := nil;
  try
    if Transaction <> nil then
      if ASucceeded then
        Transaction.EndTransaction
      else
        try
          Transaction.EndTransaction;
        except
        end;
  finally
    FBusy := False;
  end;
end;

function TMemoryCardReaderWriter.Send(const ACommand: TBytes;
  const AExpectedStatus: Word): TBytes;
var
  Wire: TBytes;
  Status: Word;
begin
  Wire := nil;
  try
    Wire := FTransport.Exchange(ACommand);
    if (Length(Wire) < 2) or (Length(Wire) > MemoryCardChunkBytes + 6) then
      Fail('response framing');
    Status := (Word(Wire[Length(Wire) - 2]) shl 8) or Wire[Length(Wire) - 1];
    if Status <> AExpectedStatus then
      Fail('reader status');
    Result := Copy(Wire, 0, Length(Wire) - 2);
  finally
    Wipe(Wire);
  end;
end;

procedure TMemoryCardReaderWriter.SelectCard;
var
  Reply: TBytes;
  L: TMemoryCardLayout;
begin
  Reply := Send(TMemoryCardCodec.Select(FModel));
  if Length(Reply) <> 0 then
    Fail('selection response');
  L := TMemoryCardCodec.Layout(FModel);
  if L.Selector <= 2 then
  begin
    Reply := Send(TMemoryCardCodec.SelectPage(FPageSize));
    if Length(Reply) <> 0 then
      Fail('page response');
  end;
end;

function TMemoryCardReaderWriter.ReadSelected(const AAddress,
  ACount: Integer): TBytes;
var
  Offset, Count, I: Integer;
  Data, Part: TBytes;
begin
  ValidateRange(FModel, AAddress, ACount);
  Result := nil;
  SetLength(Result, ACount);
  Offset := 0;
  while Offset < ACount do
  begin
    Count := ACount - Offset;
    if Count > MemoryCardChunkBytes then
      Count := MemoryCardChunkBytes;
    if Count > 65536 - ((AAddress + Offset) and $FFFF) then
      Count := 65536 - ((AAddress + Offset) and $FFFF);
    Data := Send(TMemoryCardCodec.Read(FModel, AAddress + Offset, Count));
    Part := TMemoryCardCodec.DecodeRead(FModel, FDialect, Count, Data);
    for I := 0 to Count - 1 do
      Result[Offset + I] := Part[I];
    Inc(Offset, Count);
  end;
end;

function TMemoryCardReaderWriter.ProtectionSelected: TBytes;
var
  L: TMemoryCardLayout;
begin
  L := TMemoryCardCodec.Layout(FModel);
  Result := nil;
  if L.ProtectableBytes = 0 then
    Exit;
  Result := Send(TMemoryCardCodec.ReadProtection(FModel));
  if Length(Result) <> L.ProtectableBytes div 8 then
    Fail('protection response');
end;

function TMemoryCardReaderWriter.SecuritySelected: TMemoryCardSecurityStatus;
var
  Data: TBytes;
begin
  Data := nil;
  try
    Data := Send(TMemoryCardCodec.ReadCounter(FModel));
    Result := TMemoryCardCodec.DecodeSecurity(FModel, Data);
  finally
    Wipe(Data);
  end;
end;

function TMemoryCardReaderWriter.Authenticate(const APin: TBytes)
  : TMemoryCardSecurityStatus;
var
  Wire, Reply: TBytes;
  Expected: Word;
  L: TMemoryCardLayout;
begin
  ValidatePin(APin);
  L := TMemoryCardCodec.Layout(FModel);
  if L.PinBytes = 0 then
    Fail('no PIN');
  Result := SecuritySelected;
  if Result.RemainingAttempts < FMinimumPinAttempts then
    Fail('insufficient PIN attempt budget');
  Expected := $90FF;
  if L.PinBytes = 3 then
    Expected := $9007;
  Wire := TMemoryCardCodec.Verify(FModel, APin);
  Reply := nil;
  try
    try
      Reply := Send(Wire, Expected);
      if Length(Reply) <> 0 then
        Fail('PIN response data');
      Result := SecuritySelected;
      if Result.Counter <> Byte(Expected and $FF) then
        Fail('PIN counter not restored');
    except
      on E: Exception do
        raise EMemoryCardAuthenticationError.Create
          ('PIN attempt was not verified; original error class: ' +
          E.ClassName + '.');
    end;
  finally
    Wipe(Wire);
    Wipe(Reply);
  end;
end;

procedure TMemoryCardReaderWriter.CheckUnlocked(const AAddress, ACount: Integer;
  const AProtection: TBytes);
var
  I, Limit: Integer;
  L: TMemoryCardLayout;
begin
  L := TMemoryCardCodec.Layout(FModel);
  if Length(AProtection) <> L.ProtectableBytes div 8 then
    Fail('protection bitmap length');
  Limit := AAddress + ACount;
  if Limit > L.ProtectableBytes then
    Limit := L.ProtectableBytes;
  for I := AAddress to Limit - 1 do
    if (AProtection[I div 8] and (1 shl (I mod 8))) = 0 then
      Fail('range write protected');
end;

function TMemoryCardReaderWriter.ReadMemory(const AAddress,
  ACount: Integer): TBytes;
var
  Data: TBytes;
  Good: Boolean;
begin
  ValidateRange(FModel, AAddress, ACount);
  BeginOperation;
  Good := False;
  try
    SelectCard;
    Data := ReadSelected(AAddress, ACount);
    Good := True;
  finally
    FinishOperation(Good);
  end;
  Result := Data;
end;

function TMemoryCardReaderWriter.ReadSnapshot: TMemoryCardSnapshot;
var
  Snapshot: TMemoryCardSnapshot;
  L: TMemoryCardLayout;
  Good: Boolean;
begin
  L := TMemoryCardCodec.Layout(FModel);
  Snapshot := Default (TMemoryCardSnapshot);
  Snapshot.Model := FModel;
  BeginOperation;
  Good := False;
  try
    SelectCard;
    Snapshot.Data := ReadSelected(0, L.Capacity);
    Snapshot.Protection := ProtectionSelected;
    Snapshot.HasSecurity := L.PinBytes <> 0;
    if Snapshot.HasSecurity then
      Snapshot.Security := SecuritySelected;
    Good := True;
  finally
    FinishOperation(Good);
  end;
  Result := Snapshot;
end;

function TMemoryCardReaderWriter.VerifyPin(const APin: TBytes)
  : TMemoryCardSecurityStatus;
var
  Status: TMemoryCardSecurityStatus;
  Good: Boolean;
  Pin: TBytes;
  L: TMemoryCardLayout;
begin
  ValidatePin(APin);
  L := TMemoryCardCodec.Layout(FModel);
  if L.PinBytes = 0 then
    Fail('no PIN');
  Pin := CopyBytes(APin);
  try
    BeginOperation;
    Good := False;
    try
      SelectCard;
      Status := Authenticate(Pin);
      Good := True;
    finally
      FinishOperation(Good);
    end;
    Result := Status;
  finally
    Wipe(Pin);
  end;
end;

procedure TMemoryCardReaderWriter.WriteMemory(const AAddress: Integer;
  const AData, APin: TBytes);
var
  Pin, Data, Current, Protection, Part, Wire, Reply: TBytes;
  L: TMemoryCardLayout;
  Offset, Count, Size: Integer;
  Good, Dispatched, Verified: Boolean;
begin
  ValidateRange(FModel, AAddress, Length(AData));
  ValidatePin(APin);
  L := TMemoryCardCodec.Layout(FModel);
  Size := PageBytes(FPageSize);
  Data := CopyBytes(AData);
  Wire := nil;
  Good := False;
  Dispatched := False;
  Verified := False;
  Pin := CopyBytes(APin);
  try
    try
      BeginOperation;
      try
        SelectCard;
        Current := ReadSelected(AAddress, Length(Data));
        if not BytesEqual(Current, Data) then
        begin
          Protection := ProtectionSelected;
          CheckUnlocked(AAddress, Length(Data), Protection);
          if L.PinBytes <> 0 then
            Authenticate(Pin);
          Offset := 0;
          while Offset < Length(Data) do
          begin
            Count := Length(Data) - Offset;
            if Count > MemoryCardChunkBytes then
              Count := MemoryCardChunkBytes;
            if L.Selector <= 2 then
              if Count > Size - ((AAddress + Offset) mod Size) then
                Count := Size - ((AAddress + Offset) mod Size);
            Part := Copy(Data, Offset, Count);
            Wire := TMemoryCardCodec.Write(FModel, FPageSize,
              AAddress + Offset, Part);
            Dispatched := True;
            Reply := Send(Wire);
            if Length(Reply) <> 0 then
              Fail('write response');
            Current := ReadSelected(AAddress + Offset, Count);
            if not BytesEqual(Current, Part) then
              Fail('write verification');
            Inc(Offset, Count);
          end;
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    Wipe(Pin);
  end;
end;

procedure TMemoryCardReaderWriter.ChangePin(const AOldPin, ANewPin: TBytes);
var
  Wire, Reply, OldPin, NewPin: TBytes;
  Good, Dispatched, Verified: Boolean;
begin
  ValidatePin(AOldPin);
  Wire := nil;
  OldPin := nil;
  NewPin := nil;
  Good := False;
  Dispatched := False;
  Verified := False;
  try
    Wire := TMemoryCardCodec.ChangePin(FModel, ANewPin);
    OldPin := CopyBytes(AOldPin);
    NewPin := CopyBytes(ANewPin);
    try
      BeginOperation;
      try
        SelectCard;
        Authenticate(OldPin);
        Dispatched := True;
        Reply := Send(Wire);
        if Length(Reply) <> 0 then
          Fail('PIN change response');
        SelectCard;
        Authenticate(NewPin);
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    Wipe(Wire);
    Wipe(Reply);
    Wipe(OldPin);
    Wipe(NewPin);
  end;
end;

procedure TMemoryCardReaderWriter.ProtectMemory(const AAddress: Integer;
  const AExpected, APin: TBytes);
var
  Pin, Expected, Current, Protection, Part, Wire, Reply: TBytes;
  L: TMemoryCardLayout;
  Offset, Count, I: Integer;
  Good, Dispatched, Verified, AlreadyLocked: Boolean;
begin
  ValidatePin(APin);
  L := TMemoryCardCodec.Layout(FModel);
  ValidateRange(FModel, AAddress, Length(AExpected));
  if (L.ProtectableBytes = 0) or (AAddress >= L.ProtectableBytes) or
    (Length(AExpected) > L.ProtectableBytes - AAddress) then
    Fail('protection range');
  Expected := CopyBytes(AExpected);
  Good := False;
  Dispatched := False;
  Verified := False;
  Pin := CopyBytes(APin);
  try
    try
      BeginOperation;
      try
        SelectCard;
        Current := ReadSelected(AAddress, Length(Expected));
        if not BytesEqual(Current, Expected) then
          Fail('protection data mismatch');
        Protection := ProtectionSelected;
        AlreadyLocked := True;
        for I := AAddress to AAddress + Length(Expected) - 1 do
          if (Protection[I div 8] and (1 shl (I mod 8))) <> 0 then
            AlreadyLocked := False;
        if not AlreadyLocked then
        begin
          if L.PinBytes <> 0 then
            Authenticate(Pin);
          Offset := 0;
          while Offset < Length(Expected) do
          begin
            Count := Length(Expected) - Offset;
            if Count > MemoryCardChunkBytes then
              Count := MemoryCardChunkBytes;
            Part := Copy(Expected, Offset, Count);
            Wire := TMemoryCardCodec.Protect(FModel, AAddress + Offset, Part);
            Dispatched := True;
            Reply := Send(Wire);
            if Length(Reply) <> 0 then
              Fail('protection write response');
            Inc(Offset, Count);
          end;
          Protection := ProtectionSelected;
          for I := AAddress to AAddress + Length(Expected) - 1 do
            if (Protection[I div 8] and (1 shl (I mod 8))) <> 0 then
              Fail('protection verification');
          Current := ReadSelected(AAddress, Length(Expected));
          if not BytesEqual(Current, Expected) then
            Fail('protected data changed');
        end;
        Verified := True;
        Good := True;
      finally
        FinishOperation(Good);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally
    Wipe(Pin);
  end;
end;

end.
