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
  ERD.Card.Transport;

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
    mcm4K
  );
  /// <summary>Caller-selected Classic sector key; no default keys or key discovery.</summary>
  TMifareClassicKeyType = (
    /// <summary>Authenticate using key A, reader key type 60.</summary>
    mckA,
    /// <summary>Authenticate using key B, reader key type 61.</summary>
    mckB
  );
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
    function AuthenticateCommand(const ABlock: Byte; const AKeyType: TMifareClassicKeyType;
      const ASlot: Byte): TBytes;
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
  /// <summary>Opt-in PC/SC storage pseudo-APDU profile: FF CA/82/86/B0/D6.</summary>
  /// <remarks>Targets the documented ACR122U-compatible storage command dialect. Other readers
  /// may implement it, require another profile, or lack Classic hardware support entirely.
  /// Slot zero is the portable starting point; accepted slot numbers are reader dependent.</remarks>
  TPcscStorageProfile = class(TInterfacedObject, IContactlessReaderProfile)
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
    function AuthenticateCommand(const ABlock: Byte; const AKeyType: TMifareClassicKeyType;
      const ASlot: Byte): TBytes;
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
  end;
  /// <summary>Stateless MIFARE Classic layout checks.</summary>
  TMifareClassicLayout = class
  public
    /// <summary>Returns block capacity for an explicit original Classic model.</summary>
    /// <param name="AModel">Mini, 1K or 4K.</param>
    /// <returns>20, 64 or 256 sixteen-byte blocks.</returns>
    /// <exception cref="EContactlessError">Model is invalid.</exception>
    class function BlockCount(const AModel: TMifareClassicModel): Integer; static;
    /// <summary>Identifies trailer blocks containing access bits and sector keys.</summary>
    /// <param name="AModel">Explicit memory layout.</param>
    /// <param name="ABlock">Block number within that layout.</param>
    /// <returns>True for a sector trailer.</returns>
    /// <exception cref="EContactlessError">Model or block number is invalid.</exception>
    class function IsTrailer(const AModel: TMifareClassicModel; const ABlock: Integer): Boolean; static;
  end;
  /// <summary>Non-visual UID and authenticated Classic block reader/writer using an explicit reader profile.</summary>
  /// <remarks>Construction performs no hardware work. Configure/call on one caller thread, without
  /// reentrancy. Every operation holds one exclusive transaction by default. No probing, reset,
  /// response chaining, APDU replay, default keys, value operations or access-bit changes are performed.</remarks>
  TContactlessCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FProfile: IContactlessReaderProfile;
    FUseTransactions: Boolean;
    function BeginOperation: ICardTransaction;
    procedure EndOperation(const ATransaction: ICardTransaction; const ASucceeded: Boolean);
    function Send(const ACommand: TBytes; const AExpectedSize: Integer): TBytes;
    procedure Authenticate(const ABlock: Byte; const AKeyType: TMifareClassicKeyType;
      const AKey: TBytes; const ASlot: Byte);
    procedure ValidateBlock(const AModel: TMifareClassicModel; const ABlock: Integer;
      const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
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
    function ReadClassicBlock(const AModel: TMifareClassicModel; const ABlock: Integer;
      const AKeyType: TMifareClassicKeyType; const AKey: TBytes; const ASlot: Byte = 0): TBytes;
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
    procedure WriteClassicDataBlock(const AModel: TMifareClassicModel; const ABlock: Integer;
      const AKeyType: TMifareClassicKeyType; const AKey, AData: TBytes; const ASlot: Byte = 0);
    /// <summary>Connected byte transport retained by the component; its owner may disconnect it.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Explicit matching reader command profile; nil disables all hardware operations.</summary>
    property Profile: IContactlessReaderProfile read FProfile write FProfile;
  published
    /// <summary>Acquire one exclusive ICardTransaction per complete operation; defaults to true.</summary>
    /// <remarks>False requires caller-guaranteed exclusive access. Existing transactions cannot nest.</remarks>
    property UseTransactions: Boolean read FUseTransactions write FUseTransactions default True;
  end;

implementation

uses ERD.Card.APDU, ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EContactlessError.Create('Contactless operation failed: ' + AReason + '.');
end;

function Command(const AIns, AP2: Byte; const AData: TBytes; const ALe: Integer): TBytes;
var Apdu: TApduCommand;
begin
  Apdu := Default(TApduCommand);
  Apdu.CLA := $FF;
  Apdu.INS := AIns;
  Apdu.P2 := AP2;
  Apdu.Data := AData;
  Apdu.HasLe := ALe > 0;
  Apdu.Le := Cardinal(ALe);
  Result := TApduCodec.EncodeCommand(Apdu);
end;

constructor EContactlessStatusError.Create(const AStatusWord: Word);
begin
  inherited CreateFmt('Contactless command returned status %.4x.', [AStatusWord]);
  FStatusWord := AStatusWord;
end;

constructor EContactlessWriteUncertain.Create(const AOriginalErrorClass: string);
begin
  inherited Create('Contactless write outcome is uncertain; inspect the card before retrying.');
  FOriginalErrorClass := AOriginalErrorClass;
end;

function TPcscStorageProfile.UidCommand: TBytes;
begin
  Result := Command($CA, 0, nil, 256);
end;

function TPcscStorageProfile.LoadKeyCommand(const AKey: TBytes; const ASlot: Byte): TBytes;
begin
  if Length(AKey) <> 6 then Fail('key size');
  Result := Command($82, ASlot, AKey, 0);
end;

function TPcscStorageProfile.AuthenticateCommand(const ABlock: Byte;
  const AKeyType: TMifareClassicKeyType; const ASlot: Byte): TBytes;
var Data: TBytes;
begin
  if not (AKeyType in [mckA, mckB]) then Fail('key type');
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

function TPcscStorageProfile.WriteBlockCommand(const ABlock: Byte; const AData: TBytes): TBytes;
begin
  if Length(AData) <> 16 then Fail('data block size');
  Result := Command($D6, ABlock, AData, 0);
end;

class function TMifareClassicLayout.BlockCount(const AModel: TMifareClassicModel): Integer;
begin
  case AModel of
    mcmMini: Result := 20;
    mcm1K: Result := 64;
    mcm4K: Result := 256;
  else Fail('Classic model'); Result := 0; end;
end;

class function TMifareClassicLayout.IsTrailer(const AModel: TMifareClassicModel;
  const ABlock: Integer): Boolean;
begin
  if (ABlock < 0) or (ABlock >= BlockCount(AModel)) then Fail('block range');
  if ABlock < 128 then Result := (ABlock mod 4) = 3
  else Result := (ABlock mod 16) = 15;
end;

constructor TContactlessCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUseTransactions := True;
end;

function TContactlessCardReader.BeginOperation: ICardTransaction;
begin
  Result := nil;
  if FTransport = nil then Fail('no transport');
  if FProfile = nil then Fail('no reader profile');
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Result) then Fail('transaction capability missing');
    Result.BeginTransaction;
  end;
end;

procedure TContactlessCardReader.EndOperation(const ATransaction: ICardTransaction;
  const ASucceeded: Boolean);
begin
  if ATransaction = nil then Exit;
  if ASucceeded then ATransaction.EndTransaction
  else
  begin
    try ATransaction.EndTransaction;
    except
      // Retain the primary operation failure, including an ambiguous write outcome.
    end;
  end;
end;

function TContactlessCardReader.Send(const ACommand: TBytes; const AExpectedSize: Integer): TBytes;
var Response: TApduResponse;
begin
  Response := TApduCodec.DecodeResponse(FTransport.Exchange(ACommand));
  if Response.StatusWord <> ApduStatusSuccess then
    raise EContactlessStatusError.Create(Response.StatusWord);
  if AExpectedSize >= 0 then
  begin
    if Length(Response.Data) <> AExpectedSize then Fail('response size');
  end
  else if (Length(Response.Data) < 1) or (Length(Response.Data) > 32) then Fail('UID size');
  Result := Response.Data;
end;

procedure TContactlessCardReader.ValidateBlock(const AModel: TMifareClassicModel;
  const ABlock: Integer; const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
begin
  if (ABlock < 0) or (ABlock >= TMifareClassicLayout.BlockCount(AModel)) then Fail('block range');
  if not (AKeyType in [mckA, mckB]) then Fail('key type');
  if Length(AKey) <> 6 then Fail('key size');
end;

procedure TContactlessCardReader.Authenticate(const ABlock: Byte;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes; const ASlot: Byte);
var Wire: TBytes; I: Integer;
begin
  Wire := FProfile.LoadKeyCommand(AKey, ASlot);
  try Send(Wire, 0);
  finally
    for I := 0 to Length(Wire) - 1 do Wire[I] := 0;
  end;
  Send(FProfile.AuthenticateCommand(ABlock, AKeyType, ASlot), 0);
end;

function TContactlessCardReader.ReadUid: TBytes;
var Transaction: ICardTransaction; Data: TBytes; Succeeded: Boolean;
begin
  Result := nil;
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Data := Send(FProfile.UidCommand, -1);
    Succeeded := True;
  finally EndOperation(Transaction, Succeeded); end;
  Result := Data;
end;

function TContactlessCardReader.ReadClassicBlock(const AModel: TMifareClassicModel;
  const ABlock: Integer; const AKeyType: TMifareClassicKeyType; const AKey: TBytes;
  const ASlot: Byte): TBytes;
var Transaction: ICardTransaction; Data: TBytes; Succeeded: Boolean;
begin
  Result := nil;
  ValidateBlock(AModel, ABlock, AKeyType, AKey);
  Transaction := BeginOperation;
  Succeeded := False;
  try
    Authenticate(Byte(ABlock), AKeyType, AKey, ASlot);
    Data := Send(FProfile.ReadBlockCommand(Byte(ABlock)), 16);
    Succeeded := True;
  finally EndOperation(Transaction, Succeeded); end;
  Result := Data;
end;

procedure TContactlessCardReader.WriteClassicDataBlock(const AModel: TMifareClassicModel;
  const ABlock: Integer; const AKeyType: TMifareClassicKeyType; const AKey, AData: TBytes;
  const ASlot: Byte);
var Transaction: ICardTransaction; Succeeded, Dispatched: Boolean; Wire: TBytes;
begin
  ValidateBlock(AModel, ABlock, AKeyType, AKey);
  if (ABlock = 0) or TMifareClassicLayout.IsTrailer(AModel, ABlock) then Fail('protected block');
  if Length(AData) <> 16 then Fail('data block size');
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
    finally EndOperation(Transaction, Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched and not (E is EContactlessStatusError) then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

end.
