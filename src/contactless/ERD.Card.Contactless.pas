unit ERD.Card.Contactless;

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
  ERD.Card.Transport, ERD.Card.Contactless.Classic.Access, ERD.Card.Contactless.Type2, ERD.Card.Contactless.UID;

type
  /// <summary>Invalid contactless configuration, data or requested operation; messages contain no keys.</summary>
  EContactlessError = class(EConvertError);

  /// <summary>Reader/card status failure; no key or command bytes are retained.</summary>
  EContactlessStatusError = class(EContactlessError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates an operation error from SW1/SW2.</summary>
    /// <param name="AStatusWord">Returned status word.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Received SW1/SW2 with SW1 in the high byte.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>A write was dispatched but completion could not be established; never retry blindly.</summary>
  EContactlessWriteUncertain = class(EContactlessError)
  private
    FOriginalErrorClass: string;
  public
    /// <summary>Creates an uncertain write error without retaining payloads or exception messages.</summary>
    /// <param name="AOriginalErrorClass">Class name of the transport, parse or release error.</param>
    constructor Create(const AOriginalErrorClass: string); reintroduce;
    /// <summary>Class of the original failure; its possibly sensitive message is not retained.</summary>
    property OriginalErrorClass: string read FOriginalErrorClass;
  end;

  /// <summary>Explicit original MIFARE Classic memory layout; no automatic card identification.</summary>
  TMifareClassicModel = (
    /// <summary>Mini: 20 blocks in five sectors.</summary>
    mcmMini,
    /// <summary>1K: 64 blocks in sixteen sectors.</summary>
    mcm1K,
    /// <summary>4K: 256 blocks; sectors 32..39 contain sixteen blocks each.</summary>
    mcm4K);
  /// <summary>Caller-selected Classic sector key; no default keys or key discovery.</summary>
  TMifareClassicKeyType = (
    /// <summary>Authenticate using key A, reader key type 60.</summary>
    mckA,
    /// <summary>Authenticate using key B, reader key type 61.</summary>
    mckB);

  /// <summary>Injectable reader command profile for UID and Classic storage operations.</summary>
  /// <remarks>Command builders perform no I/O. Their returned buffers belong to the caller.
  /// Only assign a profile known to match the selected reader/driver; PC/SC alone does not prove support.</remarks>
  IContactlessReaderProfile = interface
    ['{3161FCDB-09B9-42E6-BB8F-641FEE0A71E3}']
    /// <summary>Builds a UID retrieval command.</summary>
    /// <returns>One complete reader command, including response-length request.</returns>
    function UidCommand: TBytes;
    /// <summary>Builds a volatile reader key-slot load; never a sector-key update.</summary>
    /// <param name="AKey">Exactly six caller-owned key bytes.</param>
    /// <param name="ASlot">Reader-specific volatile slot identifier.</param>
    /// <returns>Independent command buffer containing a copy of the key.</returns>
    function LoadKeyCommand(const AKey: TBytes; const ASlot: Byte): TBytes;
    /// <summary>Builds authentication for one Classic block.</summary>
    /// <param name="ABlock">Validated block number, 0..255.</param>
    /// <param name="AKeyType">Key A or B.</param>
    /// <param name="ASlot">Previously loaded volatile slot identifier.</param>
    /// <returns>One complete authentication command.</returns>
    function AuthenticateCommand(const ABlock: Byte;
      const AKeyType: TMifareClassicKeyType; const ASlot: Byte): TBytes;
    /// <summary>Builds a sixteen-byte Classic block read.</summary>
    /// <param name="ABlock">Validated block number.</param>
    /// <returns>One complete block read command.</returns>
    function ReadBlockCommand(const ABlock: Byte): TBytes;
    /// <summary>Builds a sixteen-byte data-block write.</summary>
    /// <param name="ABlock">Validated writable data block, excluding manufacturer and trailer blocks.</param>
    /// <param name="AData">Exactly sixteen caller-owned bytes.</param>
    /// <returns>Independent complete write command.</returns>
    function WriteBlockCommand(const ABlock: Byte; const AData: TBytes): TBytes;
  end;

  /// <summary>Optional reader capability for four-byte Ultralight/NTAG page commands.</summary>
  /// <remarks>Separate interface preserves the existing IContactlessReaderProfile contract and GUID.</remarks>
  IType2ReaderProfile = interface
    ['{2BA77C12-D352-45C1-9767-92FE5E78A6E9}']
    /// <summary>Builds one page read without adjacent-page data in the returned response.</summary>
    /// <param name="APage">Validated physical page number, 0..230 for supported models.</param>
    /// <returns>Independent complete command; successful response must contain exactly four data bytes.</returns>
    function ReadPageCommand(const APage: Byte): TBytes;
    /// <summary>Builds one four-byte user-data page write.</summary>
    /// <param name="APage">Validated user-data page excluding manufacturer, OTP/CC, lock and configuration regions.</param>
    /// <param name="AData">Exactly four caller-owned bytes.</param>
    /// <returns>Independent complete command; successful response contains only status bytes.</returns>
    function WritePageCommand(const APage: Byte; const AData: TBytes): TBytes;
  end;

  /// <summary>Optional reader-command capability for explicitly selected Classic Gen2/CUID cards.</summary>
  /// <remarks>Reader capability does not detect a programmable card. The caller must identify a
  /// reprogrammable Gen2/CUID variant; one-time fused and RF-unlock variants require separate profiles.</remarks>
  IGen2UidReaderProfile = interface
    ['{BAE232D4-3D45-4147-A892-4C95DD1094B6}']
    /// <summary>Builds the dedicated Gen2 manufacturer-block write after sector-zero authentication.</summary>
    /// <param name="ABlock">Prepared sixteen-byte block preserving manufacturer metadata.</param>
    /// <returns>Independent complete command; successful response contains only status bytes.</returns>
    function WriteGen2ManufacturerCommand(const ABlock: TBytes): TBytes;
  end;

  /// <summary>Optional authenticated direct-write capability for caller-identified factory FUID cards.</summary>
  /// <remarks>Separate from reprogrammable Gen2 capability; factory UID alone does not identify this variant.</remarks>
  IFuidUidReaderProfile = interface
    ['{77BC05EB-650A-418A-9D4F-B7D91F93664E}']
    /// <summary>Builds the single factory-FUID manufacturer-block write after sector-zero authentication.</summary>
    /// <param name="ABlock">Exactly sixteen prepared bytes preserving manufacturer metadata.</param>
    /// <returns>Independent complete command; successful response contains only status bytes.</returns>
    function WriteFuidManufacturerCommand(const ABlock: TBytes): TBytes;
  end;

  /// <summary>Opt-in PC/SC storage pseudo-APDU profile: FF CA/82/86/B0/D6.</summary>
  /// <remarks>Targets the documented ACR122U-compatible storage command dialect. Other readers
  /// may implement it, require another profile, or lack Classic hardware support entirely.
  /// Slot zero is the portable starting point; accepted slot numbers are reader dependent.</remarks>
  TPcscStorageProfile = class(TInterfacedObject, IContactlessReaderProfile,
    IType2ReaderProfile, IGen2UidReaderProfile, IFuidUidReaderProfile)
  public
    /// <summary>Builds FF CA 00 00 00 to retrieve the reader-reported UID.</summary>
    /// <returns>Independent command bytes.</returns>
    function UidCommand: TBytes;
    /// <summary>Builds FF 82 with P1=00 for volatile key loading.</summary>
    /// <param name="AKey">Exactly six key bytes; copied, never modified.</param>
    /// <param name="ASlot">Reader volatile slot identifier.</param>
    /// <returns>Independent key-bearing command.</returns>
    /// <exception cref="EContactlessError">Key size is invalid.</exception>
    function LoadKeyCommand(const AKey: TBytes; const ASlot: Byte): TBytes;
    /// <summary>Builds FF 86 with version 01 and Classic key type 60/61.</summary>
    /// <param name="ABlock">Classic block number.</param>
    /// <param name="AKeyType">Key A or B.</param>
    /// <param name="ASlot">Reader volatile slot identifier.</param>
    /// <returns>Independent command bytes.</returns>
    /// <exception cref="EContactlessError">Key type is invalid.</exception>
    function AuthenticateCommand(const ABlock: Byte;
      const AKeyType: TMifareClassicKeyType; const ASlot: Byte): TBytes;
    /// <summary>Builds FF B0 with a sixteen-byte response request.</summary>
    /// <param name="ABlock">Classic block number.</param>
    /// <returns>Independent command bytes.</returns>
    function ReadBlockCommand(const ABlock: Byte): TBytes;
    /// <summary>Builds FF D6 with sixteen data bytes and no Le.</summary>
    /// <param name="ABlock">Classic data block number.</param>
    /// <param name="AData">Exactly sixteen data bytes, copied without modification.</param>
    /// <returns>Independent command bytes.</returns>
    /// <exception cref="EContactlessError">Data size is invalid.</exception>
    function WriteBlockCommand(const ABlock: Byte; const AData: TBytes): TBytes;
    /// <summary>Builds FF B0 with a four-byte page response request.</summary>
    /// <param name="APage">Validated Ultralight/NTAG page number.</param>
    /// <returns>Independent command bytes.</returns>
    function ReadPageCommand(const APage: Byte): TBytes;
    /// <summary>Builds FF D6 with four data bytes and no Le.</summary>
    /// <param name="APage">Validated user-data page number.</param>
    /// <param name="AData">Exactly four data bytes, copied without modification.</param>
    /// <returns>Independent command bytes.</returns>
    /// <exception cref="EContactlessError">Data size is invalid.</exception>
    function WritePageCommand(const APage: Byte; const AData: TBytes): TBytes;
    /// <summary>Builds FF D6 for a dedicated Gen2/CUID manufacturer-block write.</summary>
    /// <param name="ABlock">Exactly sixteen prepared manufacturer-block bytes.</param>
    /// <returns>Independent command bytes.</returns>
    /// <exception cref="EContactlessError">Block size is invalid.</exception>
    /// <remarks>No unlock/fuse commands or automatic programmable-card detection.</remarks>
    function WriteGen2ManufacturerCommand(const ABlock: TBytes): TBytes;
    /// <summary>Builds FF D6 for the single authenticated factory-FUID manufacturer-block write.</summary>
    /// <param name="ABlock">Exactly sixteen prepared manufacturer bytes; never modified.</param>
    /// <returns>Independent complete command.</returns>
    /// <exception cref="EContactlessError">Block size is invalid.</exception>
    /// <remarks>Does not configure, fuse or lock the card; variant selection and factory checks belong to the caller/API.</remarks>
    function WriteFuidManufacturerCommand(const ABlock: TBytes): TBytes;
  end;

  /// <summary>Stateless MIFARE Classic layout checks.</summary>
  TMifareClassicLayout = class
  public
    /// <summary>Returns block capacity for an explicit original Classic model.</summary>
    /// <param name="AModel">Mini, 1K or 4K.</param>
    /// <returns>20, 64 or 256 sixteen-byte blocks.</returns>
    /// <exception cref="EContactlessError">Model is invalid.</exception>
    class function BlockCount(const AModel: TMifareClassicModel)
      : Integer; static;
    /// <summary>Identifies trailer blocks containing access bits and sector keys.</summary>
    /// <param name="AModel">Explicit memory layout.</param>
    /// <param name="ABlock">Block number within that layout.</param>
    /// <returns>True for a sector trailer.</returns>
    /// <exception cref="EContactlessError">Model or block number is invalid.</exception>
    class function IsTrailer(const AModel: TMifareClassicModel;
      const ABlock: Integer): Boolean; static;
  end;

  /// <summary>Non-visual Classic/Type 2 storage and explicit programmable-UID operations using reader profiles.</summary>
  /// <remarks>Construction performs no hardware work. Configure/call on one caller thread, without
  /// reentrancy. Every operation holds one exclusive transaction by default. No probing, reset,
  /// response chaining, APDU replay, default keys, value operations or access-bit changes are performed.</remarks>
  TContactlessCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FProfile: IContactlessReaderProfile;
    FUseTransactions: Boolean;
    function BeginOperation: ICardTransaction;
    procedure EndOperation(const ATransaction: ICardTransaction;
      const ASucceeded: Boolean);
    function Send(const ACommand: TBytes; const AExpectedSize: Integer): TBytes;
    procedure Authenticate(const ABlock: Byte;
      const AKeyType: TMifareClassicKeyType; const AKey: TBytes;
      const ASlot: Byte);
    procedure ValidateBlock(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AKeyType: TMifareClassicKeyType;
      const AKey: TBytes);
    function RequireType2Profile: IType2ReaderProfile;
    function RequireGen2Profile: IGen2UidReaderProfile;
    function RequireFuidProfile: IFuidUidReaderProfile;
  public
    /// <summary>Creates an inactive component with no selected reader profile.</summary>
    /// <param name="AOwner">Optional owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Retrieves the reader-reported card UID without selecting an EMV application.</summary>
    /// <returns>Independent identifier bytes, 1..32; no card type or identity authenticity is inferred.</returns>
    /// <exception cref="EContactlessError">Configuration or response length is invalid.</exception>
    /// <exception cref="EContactlessStatusError">Reader command returns a failure status.</exception>
    function ReadUid: TBytes;
    /// <summary>Loads a supplied volatile key, authenticates and reads one Classic block atomically.</summary>
    /// <param name="AModel">Caller-identified Mini, 1K or 4K layout.</param>
    /// <param name="ABlock">Block number within the layout; trailer reads are allowed.</param>
    /// <param name="AKeyType">Key A or B.</param>
    /// <param name="AKey">Exactly six caller-owned bytes; not modified or retained by the component.</param>
    /// <param name="ASlot">Volatile reader key slot, default zero; support is profile/reader dependent.</param>
    /// <returns>Independent sixteen-byte block, only after successful transaction release.</returns>
    /// <exception cref="EContactlessError">Parameters, configuration or response size are invalid.</exception>
    /// <exception cref="EContactlessStatusError">Key loading, authentication or reading fails.</exception>
    /// <remarks>The local key-bearing command is overwritten on exit. Reader slots can retain the
    /// key until reset/disconnection; manage their lifecycle according to the reader documentation.
    /// This is not secure-memory storage: profile/transport copies are outside the component's control.</remarks>
    function ReadClassicBlock(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AKeyType: TMifareClassicKeyType;
      const AKey: TBytes; const ASlot: Byte = 0): TBytes;
    /// <summary>Authenticates and writes one Classic data block; manufacturer/trailer writes are rejected.</summary>
    /// <param name="AModel">Caller-identified Classic layout.</param>
    /// <param name="ABlock">Writable data block; block zero and all sector trailers are rejected before I/O.</param>
    /// <param name="AKeyType">Key A or B.</param>
    /// <param name="AKey">Exactly six caller-owned key bytes, not modified.</param>
    /// <param name="AData">Exactly sixteen caller-owned data bytes, not modified.</param>
    /// <param name="ASlot">Volatile reader key slot, default zero.</param>
    /// <exception cref="EContactlessError">Parameters, configuration or response size are invalid.</exception>
    /// <exception cref="EContactlessStatusError">Key loading, authentication or writing fails.</exception>
    /// <exception cref="EContactlessWriteUncertain">Dispatch occurred and a transport, parse or release error prevents confirming completion.</exception>
    /// <remarks>One write attempt only. A transport or release failure after dispatch can leave the
    /// write outcome unknown; inspect the card before any retry. This is not a rollback transaction.
    /// A successful status is not an independent read-back verification. Key-slot lifetime matches ReadClassicBlock.</remarks>
    procedure WriteClassicDataBlock(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AKeyType: TMifareClassicKeyType;
      const AKey, AData: TBytes; const ASlot: Byte = 0);
    /// <summary>Writes one explicit sector trailer and verifies access bytes and both supplied new keys.</summary>
    /// <param name="AModel">Explicit Classic geometry.</param>
    /// <param name="ABlock">Sector trailer address only.</param>
    /// <param name="AKeyType">Current authentication key type.</param>
    /// <param name="AKey">Six-byte current credential.</param>
    /// <param name="ANewTrailer">Sixteen bytes including supplied new A/B keys and valid access bits.</param>
    /// <param name="ASlot">Volatile reader key slot.</param>
    /// <remarks>One write only. Any failure after dispatch is uncertain. Key A is verified by
    /// fresh authentication; Key B by fresh authentication or readable bytes, according to the
    /// new trailer access condition. Masked key bytes are never copied from a trailer read.
    /// This operation may permanently restrict later writes; no automatic recovery or rollback.</remarks>
    procedure WriteClassicSectorTrailer(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AKeyType: TMifareClassicKeyType;
      const AKey, ANewTrailer: TBytes; const ASlot: Byte = 0);
    /// <summary>Reads one four-byte page within an explicit Ultralight/NTAG layout.</summary>
    /// <param name="AModel">Caller-identified supported memory layout.</param>
    /// <param name="APage">Physical page in the layout; non-user regions may be read when the card permits.</param>
    /// <returns>Independent four-byte reader-visible page after successful transaction release.</returns>
    /// <exception cref="EType2DataError">Model or page range is invalid.</exception>
    /// <exception cref="EContactlessError">Configuration, optional profile capability or response size is invalid.</exception>
    /// <exception cref="EContactlessStatusError">Reader/card denies the read.</exception>
    /// <remarks>No Classic authentication, password attempts, counters or RF fallback are sent.
    /// Masked password/configuration reads remain exactly as returned by the card.</remarks>
    function ReadType2Page(const AModel: TType2TagModel;
      const APage: Integer): TBytes;
    /// <summary>Reads every user-data page in one exclusive transaction without returning partial data.</summary>
    /// <param name="AModel">Caller-identified supported layout; largest snapshot is 888 bytes.</param>
    /// <returns>Complete independent ascending-page snapshot after successful release.</returns>
    /// <exception cref="EType2DataError">Model is invalid.</exception>
    /// <exception cref="EContactlessError">Configuration, profile capability or response length is invalid.</exception>
    /// <exception cref="EContactlessStatusError">Any required page read fails.</exception>
    /// <remarks>One four-byte request per page; no PC/SC requests outside the selected user region.
    /// Underlying RF read granularity depends on the reader/driver. Lock/password permissions are
    /// enforced by the card. Raw bytes are not an NDEF interpretation.</remarks>
    function ReadType2UserMemory(const AModel: TType2TagModel)
      : TType2UserMemory;
    /// <summary>Writes one four-byte user page while excluding manufacturer, OTP/CC, lock and configuration pages.</summary>
    /// <param name="AModel">Caller-identified supported layout.</param>
    /// <param name="APage">User-data page only.</param>
    /// <param name="AData">Exactly four caller-owned bytes, copied without modification.</param>
    /// <exception cref="EType2DataError">Model or page range is invalid.</exception>
    /// <exception cref="EContactlessError">Protected page, payload size, configuration or response size is invalid.</exception>
    /// <exception cref="EContactlessStatusError">Reader/card denies writing.</exception>
    /// <exception cref="EContactlessWriteUncertain">Dispatch occurred and completion could not be established.</exception>
    /// <remarks>One write attempt; no password guessing, lock updates, retries or independent read-back.
    /// A release/transport failure after dispatch can leave modified data; inspect before retrying.</remarks>
    procedure WriteType2UserPage(const AModel: TType2TagModel;
      const APage: Integer; const AData: TBytes);
    /// <summary>Programs a UID on an explicitly identified reprogrammable Classic Gen2/CUID card.</summary>
    /// <param name="AModel">Explicit four-byte or seven-byte manufacturer-block layout.</param>
    /// <param name="ANewUid">Exactly four or seven caller-owned bytes according to AModel.</param>
    /// <param name="AKeyType">Sector-zero key A or B.</param>
    /// <param name="AKey">Exactly six supplied sector-zero key bytes.</param>
    /// <param name="ASlot">Volatile reader key slot, default zero.</param>
    /// <returns>Verified manufacturer-block snapshot and explicit active-UID verification state after release.</returns>
    /// <exception cref="EProgrammableUidError">UID length/cascade position, existing block size or BCC is invalid.</exception>
    /// <exception cref="EContactlessError">Profile capability, configuration, identity or response size is invalid.</exception>
    /// <exception cref="EContactlessStatusError">Preparation or the write itself is explicitly denied.</exception>
    /// <exception cref="EContactlessWriteUncertain">Dispatch occurred and read-back, UID verification or release could not establish completion.</exception>
    /// <remarks>Explicit opt-in operation; never guesses card type or uses unlock/fuse commands.
    /// Validates the current reader UID against block zero, preserves all metadata, recomputes the
    /// four-byte layout's BCC and verifies all sixteen written bytes. False ActiveUidVerified means
    /// the reader still reports the old UID and caller-controlled RF reactivation is required.
    /// No reset/reconnect or write replay. Ordinary data writers still reject manufacturer blocks.</remarks>
    function ProgramClassicGen2Uid(const AModel: TClassicGen2UidModel;
      const ANewUid: TBytes; const AKeyType: TMifareClassicKeyType;
      const AKey: TBytes; const ASlot: Byte = 0): TProgrammableUidResult;
    /// <summary>Performs one authenticated UID write on an explicitly identified four-byte factory FUID card.</summary>
    /// <param name="ANewUid">Exactly four target bytes, different from factory UID AA55C396; never modified.</param>
    /// <param name="AKeyType">Supplied sector-zero key A or B.</param>
    /// <param name="AKey">Exactly six caller-owned sector-zero key bytes; never guessed or retained.</param>
    /// <param name="ASlot">Volatile reader key slot, default zero.</param>
    /// <returns>Independent block/UID snapshot and explicit cached-versus-active UID state after successful release.</returns>
    /// <exception cref="EProgrammableUidError">Target UID, original manufacturer layout or BCC is invalid.</exception>
    /// <exception cref="EContactlessError">Reader capability, supplied parameters or factory UID/block precondition fails.</exception>
    /// <exception cref="EContactlessStatusError">Reading, key loading or authentication is denied before write dispatch.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any failure after the sole write was dispatched, including denied status or release.</exception>
    /// <remarks>Requires fresh unprogrammed variant with factory UID AA55C396. Changing UID consumes its standard
    /// direct-write condition; this API does not prove all backdoors are fused or disabled. Preserves bytes five through
    /// fifteen, recomputes BCC and verifies all sixteen bytes. False ActiveUidVerified requires caller-controlled RF
    /// reactivation and ReadUid verification; never repeat this method after an uncertain result. No automatic replay,
    /// fuse commands or reconnect. Local key-command overwriting and reader key-slot lifetime match ReadClassicBlock.</remarks>
    function ProgramFuidUidOnce(const ANewUid: TBytes;
      const AKeyType: TMifareClassicKeyType; const AKey: TBytes;
      const ASlot: Byte = 0): TFuidUidResult;
    /// <summary>Connected byte transport retained by the component; its owner may disconnect it.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Explicit matching reader command profile; nil disables all hardware operations.</summary>
    property Profile: IContactlessReaderProfile read FProfile write FProfile;
  published
    /// <summary>Acquire one exclusive ICardTransaction per complete operation; defaults to true.</summary>
    /// <remarks>False requires caller-guaranteed exclusive access. Existing transactions cannot nest.</remarks>
    property UseTransactions: Boolean read FUseTransactions
      write FUseTransactions default True;
  end;

implementation

uses ERD.Card.APDU, ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EContactlessError.Create('Contactless operation failed: ' +
    AReason + '.');
end;

function Command(const AIns, AP2: Byte; const AData: TBytes;
  const ALe: Integer): TBytes;
var
  APDU: TApduCommand;
begin
  APDU := Default (TApduCommand);
  APDU.CLA := $FF;
  APDU.INS := AIns;
  APDU.P2 := AP2;
  APDU.Data := AData;
  APDU.HasLe := ALe > 0;
  APDU.Le := Cardinal(ALe);
  Result := TApduCodec.EncodeCommand(APDU);
end;

constructor EContactlessStatusError.Create(const AStatusWord: Word);
begin
  inherited CreateFmt('Contactless command returned status %.4x.',
    [AStatusWord]);
  FStatusWord := AStatusWord;
end;

constructor EContactlessWriteUncertain.Create(const AOriginalErrorClass
  : string);
begin
  inherited Create
    ('Contactless write outcome is uncertain; inspect the card before retrying.');
  FOriginalErrorClass := AOriginalErrorClass;
end;

function TPcscStorageProfile.UidCommand: TBytes;
begin
  Result := Command($CA, 0, nil, 256);
end;

function TPcscStorageProfile.LoadKeyCommand(const AKey: TBytes;
  const ASlot: Byte): TBytes;
begin
  if Length(AKey) <> 6 then
    Fail('key size');
  Result := Command($82, ASlot, AKey, 0);
end;

function TPcscStorageProfile.AuthenticateCommand(const ABlock: Byte;
  const AKeyType: TMifareClassicKeyType; const ASlot: Byte): TBytes;
var
  Data: TBytes;
begin
  if not(AKeyType in [mckA, mckB]) then
    Fail('key type');
  Data := HexToBytes('0100006000');
  Data[2] := ABlock;
  Data[3] := $60 + Ord(AKeyType);
  Data[4] := ASlot;
  Result := Command($86, 0, Data, 0);
end;

function TPcscStorageProfile.ReadBlockCommand(const ABlock: Byte): TBytes;
begin
  Result := Command($B0, ABlock, nil, 16);
end;

function TPcscStorageProfile.WriteBlockCommand(const ABlock: Byte;
  const AData: TBytes): TBytes;
begin
  if Length(AData) <> 16 then
    Fail('data block size');
  Result := Command($D6, ABlock, AData, 0);
end;

function TPcscStorageProfile.ReadPageCommand(const APage: Byte): TBytes;
begin
  Result := Command($B0, APage, nil, Type2PageBytes);
end;

function TPcscStorageProfile.WritePageCommand(const APage: Byte;
  const AData: TBytes): TBytes;
begin
  if Length(AData) <> Type2PageBytes then
    Fail('page data size');
  Result := Command($D6, APage, AData, 0);
end;

function TPcscStorageProfile.WriteGen2ManufacturerCommand
  (const ABlock: TBytes): TBytes;
begin
  if Length(ABlock) <> 16 then
    Fail('manufacturer block size');
  Result := Command($D6, 0, ABlock, 0);
end;

function TPcscStorageProfile.WriteFuidManufacturerCommand
  (const ABlock: TBytes): TBytes;
begin
  if Length(ABlock) <> 16 then
    Fail('manufacturer block size');
  Result := Command($D6, 0, ABlock, 0);
end;

class function TMifareClassicLayout.BlockCount(const AModel
  : TMifareClassicModel): Integer;
begin
  case AModel of
    mcmMini:
      Result := 20;
    mcm1K:
      Result := 64;
    mcm4K:
      Result := 256;
  else
    Fail('Classic model');
    Result := 0;
  end;
end;

class function TMifareClassicLayout.IsTrailer(const AModel: TMifareClassicModel;
  const ABlock: Integer): Boolean;
begin
  if (ABlock < 0) or (ABlock >= BlockCount(AModel)) then
    Fail('block range');
  if ABlock < 128 then
    Result := (ABlock mod 4) = 3
  else
    Result := (ABlock mod 16) = 15;
end;

constructor TContactlessCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUseTransactions := True;
end;

function TContactlessCardReader.BeginOperation: ICardTransaction;
begin
  Result := nil;
  if FTransport = nil then
    Fail('no transport');
  if FProfile = nil then
    Fail('no reader profile');
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Result) then
      Fail('transaction capability missing');
    Result.BeginTransaction;
  end;
end;

procedure TContactlessCardReader.EndOperation(const ATransaction
  : ICardTransaction; const ASucceeded: Boolean);
begin
  if ATransaction = nil then
    Exit;
  if ASucceeded then
    ATransaction.EndTransaction
  else
  begin
    try
      ATransaction.EndTransaction;
    except
      // Retain the primary operation failure, including an ambiguous write outcome.
    end;
  end;
end;

function TContactlessCardReader.Send(const ACommand: TBytes;
  const AExpectedSize: Integer): TBytes;
var
  Response: TApduResponse;
begin
  Response := TApduCodec.DecodeResponse(FTransport.Exchange(ACommand));
  if Response.StatusWord <> ApduStatusSuccess then
    raise EContactlessStatusError.Create(Response.StatusWord);
  if AExpectedSize >= 0 then
  begin
    if Length(Response.Data) <> AExpectedSize then
      Fail('response size');
  end
  else if (Length(Response.Data) < 1) or (Length(Response.Data) > 32) then
    Fail('UID size');
  Result := Response.Data;
end;

procedure TContactlessCardReader.ValidateBlock(const AModel
  : TMifareClassicModel; const ABlock: Integer;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
begin
  if (ABlock < 0) or (ABlock >= TMifareClassicLayout.BlockCount(AModel)) then
    Fail('block range');
  if not(AKeyType in [mckA, mckB]) then
    Fail('key type');
  if Length(AKey) <> 6 then
    Fail('key size');
end;

procedure TContactlessCardReader.Authenticate(const ABlock: Byte;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes; const ASlot: Byte);
var
  Wire: TBytes;
  I: Integer;
begin
  Wire := FProfile.LoadKeyCommand(AKey, ASlot);
  try
    Send(Wire, 0);
  finally
    for I := 0 to Length(Wire) - 1 do
      Wire[I] := 0;
  end;
  Send(FProfile.AuthenticateCommand(ABlock, AKeyType, ASlot), 0);
end;

function TContactlessCardReader.ReadUid: TBytes;
var
  Transaction: ICardTransaction;
  Data: TBytes;
  Succeeded: Boolean;
begin
  Result := nil;
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Data := Send(FProfile.UidCommand, -1);
    Succeeded := True;
  finally
    EndOperation(Transaction, Succeeded);
  end;
  Result := Data;
end;

function TContactlessCardReader.RequireType2Profile: IType2ReaderProfile;
begin
  Result := nil;
  if not Supports(FProfile, IType2ReaderProfile, Result) then
    Fail('Type 2 reader capability missing');
end;

function TContactlessCardReader.RequireGen2Profile: IGen2UidReaderProfile;
begin
  Result := nil;
  if not Supports(FProfile, IGen2UidReaderProfile, Result) then
    Fail('Gen2 UID reader capability missing');
end;

function TContactlessCardReader.RequireFuidProfile: IFuidUidReaderProfile;
begin
  Result := nil;
  if not Supports(FProfile, IFuidUidReaderProfile, Result) then
    Fail('FUID reader capability missing');
end;

function TContactlessCardReader.ReadType2Page(const AModel: TType2TagModel;
  const APage: Integer): TBytes;
var
  Profile: IType2ReaderProfile;
  Transaction: ICardTransaction;
  Data: TBytes;
  Succeeded: Boolean;
begin
  Result := nil;
  if (APage < 0) or (APage >= TType2Layout.PageCount(AModel)) then
    raise EType2DataError.Create('Invalid Type 2 page.');
  Profile := RequireType2Profile;
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Data := Send(Profile.ReadPageCommand(Byte(APage)), Type2PageBytes);
    Succeeded := True;
  finally
    EndOperation(Transaction, Succeeded);
  end;
  Result := Data;
end;

function TContactlessCardReader.ReadType2UserMemory(const AModel
  : TType2TagModel): TType2UserMemory;
var
  Profile: IType2ReaderProfile;
  Transaction: ICardTransaction;
  Data: TType2UserMemory;
  PageData: TBytes;
  Page, LastPage, Offset, I: Integer;
  Succeeded: Boolean;
begin
  Result := Default (TType2UserMemory);
  LastPage := TType2Layout.LastUserPage(AModel);
  Profile := RequireType2Profile;
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Data := Default (TType2UserMemory);
    Data.Model := AModel;
    Data.FirstPage := Type2FirstUserPage;
    Data.PageCount := LastPage - Type2FirstUserPage + 1;
    SetLength(Data.Data, Data.PageCount * Type2PageBytes);
    Offset := 0;
    for Page := Type2FirstUserPage to LastPage do
    begin
      PageData := Send(Profile.ReadPageCommand(Byte(Page)), Type2PageBytes);
      for I := 0 to Type2PageBytes - 1 do
        Data.Data[Offset + I] := PageData[I];
      Inc(Offset, Type2PageBytes);
    end;
    Succeeded := True;
  finally
    EndOperation(Transaction, Succeeded);
  end;
  Result := Data;
end;

procedure TContactlessCardReader.WriteType2UserPage(const AModel
  : TType2TagModel; const APage: Integer; const AData: TBytes);
var
  Profile: IType2ReaderProfile;
  Transaction: ICardTransaction;
  Wire: TBytes;
  Succeeded, Dispatched: Boolean;
begin
  if not TType2Layout.IsUserPage(AModel, APage) then
    Fail('protected Type 2 page');
  if Length(AData) <> Type2PageBytes then
    Fail('page data size');
  Profile := RequireType2Profile;
  Transaction := BeginOperation;
  Succeeded := False;
  Dispatched := False;
  try
    try
      Wire := Profile.WritePageCommand(Byte(APage), AData);
      Dispatched := True;
      Send(Wire, 0);
      Succeeded := True;
    finally
      EndOperation(Transaction, Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched and not(E is EContactlessStatusError) then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

function TContactlessCardReader.ProgramClassicGen2Uid
  (const AModel: TClassicGen2UidModel; const ANewUid: TBytes;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes; const ASlot: Byte)
  : TProgrammableUidResult;
var
  Profile: IGen2UidReaderProfile;
  Transaction: ICardTransaction;
  Data: TProgrammableUidResult;
  OldBlock, BlockUid, VerifiedBlock, ActiveUid, Wire: TBytes;
  Succeeded, Dispatched, WriteAccepted: Boolean;
  UidSize: Integer;
begin
  Result := Default (TProgrammableUidResult);
  UidSize := TProgrammableUidCodec.UidLength(AModel);
  TProgrammableUidCodec.ValidateUid(AModel, ANewUid);
  ValidateBlock(mcm1K, 0, AKeyType, AKey);
  Profile := RequireGen2Profile;
  Transaction := BeginOperation;
  Succeeded := False;
  Dispatched := False;
  WriteAccepted := False;
  try
    try
      Data := Default (TProgrammableUidResult);
      Data.Model := AModel;
      Data.RequestedUid := CopyBytes(ANewUid);
      Data.PreviousUid := Send(FProfile.UidCommand, -1);
      if Length(Data.PreviousUid) <> UidSize then
        Fail('current UID length does not match selected layout');
      Authenticate(0, AKeyType, AKey, ASlot);
      OldBlock := Send(FProfile.ReadBlockCommand(0), 16);
      BlockUid := TProgrammableUidCodec.DecodeGen2Uid(AModel, OldBlock);
      if not BytesEqual(BlockUid, Data.PreviousUid) then
        Fail('UID and manufacturer block disagree');
      Data.ManufacturerBlock := TProgrammableUidCodec.PrepareGen2Block(AModel,
        OldBlock, Data.RequestedUid);
      if BytesEqual(Data.RequestedUid, Data.PreviousUid) then
        Data.ActiveUidVerified := True
      else
      begin
        Wire := Profile.WriteGen2ManufacturerCommand(Data.ManufacturerBlock);
        Dispatched := True;
        Send(Wire, 0);
        WriteAccepted := True;
        VerifiedBlock := Send(FProfile.ReadBlockCommand(0), 16);
        if not BytesEqual(VerifiedBlock, Data.ManufacturerBlock) then
          Fail('manufacturer read-back mismatch');
        ActiveUid := Send(FProfile.UidCommand, -1);
        Data.ActiveUidVerified := BytesEqual(ActiveUid, Data.RequestedUid);
        if not Data.ActiveUidVerified and not BytesEqual(ActiveUid,
          Data.PreviousUid) then
          Fail('active UID verification mismatch');
      end;
      Succeeded := True;
    finally
      EndOperation(Transaction, Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched and (WriteAccepted or not(E is EContactlessStatusError))
      then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

function TContactlessCardReader.ProgramFuidUidOnce(const ANewUid: TBytes;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes; const ASlot: Byte)
  : TFuidUidResult;
var
  Profile: IFuidUidReaderProfile;
  Transaction: ICardTransaction;
  Data: TFuidUidResult;
  FactoryUid, OldBlock, BlockUid, Verified, ActiveUid, Wire: TBytes;
  Succeeded, Dispatched: Boolean;
begin
  Result := Default (TFuidUidResult);
  TProgrammableUidCodec.ValidateUid(cgum4Byte, ANewUid);
  FactoryUid := HexToBytes('AA55C396');
  if BytesEqual(ANewUid, FactoryUid) then
    Fail('target must differ from factory UID');
  ValidateBlock(mcm1K, 0, AKeyType, AKey);
  Profile := RequireFuidProfile;
  Data := Default (TFuidUidResult);
  Data.RequestedUid := CopyBytes(ANewUid);
  Succeeded := False;
  Dispatched := False;
  Transaction := BeginOperation;
  try
    try
      Data.PreviousUid := Send(FProfile.UidCommand, -1);
      if not BytesEqual(Data.PreviousUid, FactoryUid) then
        Fail('FUID factory UID precondition failed');
      Authenticate(0, AKeyType, AKey, ASlot);
      OldBlock := Send(FProfile.ReadBlockCommand(0), 16);
      BlockUid := TProgrammableUidCodec.DecodeGen2Uid(cgum4Byte, OldBlock);
      if not BytesEqual(BlockUid, FactoryUid) then
        Fail('FUID factory UID/block mismatch');
      Data.ManufacturerBlock := TProgrammableUidCodec.PrepareGen2Block
        (cgum4Byte, OldBlock, Data.RequestedUid);
      Wire := Profile.WriteFuidManufacturerCommand(Data.ManufacturerBlock);
      Dispatched := True;
      Send(Wire, 0);
      Verified := Send(FProfile.ReadBlockCommand(0), 16);
      if not BytesEqual(Verified, Data.ManufacturerBlock) then
        Fail('FUID manufacturer read-back mismatch');
      ActiveUid := Send(FProfile.UidCommand, -1);
      Data.ActiveUidVerified := BytesEqual(ActiveUid, Data.RequestedUid);
      if not Data.ActiveUidVerified and not BytesEqual(ActiveUid, FactoryUid)
      then
        Fail('FUID active UID mismatch');
      Succeeded := True;
    finally
      EndOperation(Transaction, Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

function TContactlessCardReader.ReadClassicBlock(const AModel
  : TMifareClassicModel; const ABlock: Integer;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes;
  const ASlot: Byte): TBytes;
var
  Transaction: ICardTransaction;
  Data: TBytes;
  Succeeded: Boolean;
begin
  Result := nil;
  ValidateBlock(AModel, ABlock, AKeyType, AKey);
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Authenticate(Byte(ABlock), AKeyType, AKey, ASlot);
    Data := Send(FProfile.ReadBlockCommand(Byte(ABlock)), 16);
    Succeeded := True;
  finally
    EndOperation(Transaction, Succeeded);
  end;
  Result := Data;
end;

procedure TContactlessCardReader.WriteClassicDataBlock
  (const AModel: TMifareClassicModel; const ABlock: Integer;
  const AKeyType: TMifareClassicKeyType; const AKey, AData: TBytes;
  const ASlot: Byte);
var
  Transaction: ICardTransaction;
  Succeeded, Dispatched: Boolean;
  Wire: TBytes;
begin
  ValidateBlock(AModel, ABlock, AKeyType, AKey);
  if (ABlock = 0) or TMifareClassicLayout.IsTrailer(AModel, ABlock) then
    Fail('protected block');
  if Length(AData) <> 16 then
    Fail('data block size');
  Transaction := BeginOperation;
  Succeeded := False;
  Dispatched := False;
  try
    try
      Authenticate(Byte(ABlock), AKeyType, AKey, ASlot);
      Wire := FProfile.WriteBlockCommand(Byte(ABlock), AData);
      Dispatched := True;
      Send(Wire, 0);
      Succeeded := True;
    finally
      EndOperation(Transaction, Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched and not(E is EContactlessStatusError) then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

procedure TContactlessCardReader.WriteClassicSectorTrailer(const AModel: TMifareClassicModel;
  const ABlock: Integer; const AKeyType: TMifareClassicKeyType;
  const AKey, ANewTrailer: TBytes; const ASlot: Byte);
var
  Transaction: ICardTransaction;
  Succeeded, Dispatched: Boolean;
  Wire, Verified, KeyA, KeyB: TBytes;
  Conditions: TClassicAccessConditions;
  I: Integer;
begin
  ValidateBlock(AModel, ABlock, AKeyType, AKey);
  if not TMifareClassicLayout.IsTrailer(AModel, ABlock) then Fail('trailer address');
  if Length(ANewTrailer) <> 16 then Fail('trailer size');
  Conditions := TClassicAccessCodec.Decode(Copy(ANewTrailer, 6, 3));
  KeyA := Copy(ANewTrailer, 0, 6);
  KeyB := Copy(ANewTrailer, 10, 6);
  Transaction := nil;
  Succeeded := False;
  Dispatched := False;
  try
    try
      Transaction := BeginOperation;
      try
        Authenticate(Byte(ABlock), AKeyType, AKey, ASlot);
        Wire := FProfile.WriteBlockCommand(Byte(ABlock), ANewTrailer);
        Dispatched := True;
        Send(Wire, 0);
        Authenticate(Byte(ABlock), mckA, KeyA, ASlot);
        Verified := Send(FProfile.ReadBlockCommand(Byte(ABlock)), 16);
        if not BytesEqual(Copy(Verified, 6, 4), Copy(ANewTrailer, 6, 4)) then
          Fail('trailer access verification');
        if TClassicAccessCodec.KeyBReadable(Conditions[3]) then
        begin
          if not BytesEqual(Copy(Verified, 10, 6), KeyB) then Fail('trailer key B verification');
        end
        else Authenticate(Byte(ABlock), mckB, KeyB, ASlot);
        Succeeded := True;
      finally
        EndOperation(Transaction, Succeeded);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    for I := 0 to High(Wire) do Wire[I] := 0;
    for I := 0 to High(KeyA) do KeyA[I] := 0;
    for I := 0 to High(KeyB) do KeyB[I] := 0;
  end;
end;

end.
