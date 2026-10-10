unit ERD.Card.Memory.Counter;

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
  ERD.Card.Transport, ERD.Card.Memory;

type
  /// <summary>Explicit counter-chip command profile; no automatic identity or geometry detection.</summary>
  TSleCounterModel = (
    /// <summary>SLE4406; ordinary programming and carry, without backup or certificate commands.</summary>
    scmSle4406,
    /// <summary>SLE4436; backup writes and non-CBC certificate commands are available.</summary>
    scmSle4436,
    /// <summary>SLE5536; backup writes and CBC/non-CBC certificate commands are available.</summary>
    scmSle5536,
    /// <summary>SLE6636; backup writes and CBC/non-CBC certificate commands are available.</summary>
    scmSle6636);
  /// <summary>ACS counter-card write flags; these are not EEPROM erase-and-replace operations.</summary>
  TSleCounterWriteMode = (
    /// <summary>Program only the addressed byte, from one bits to zero bits.</summary>
    scwProgram,
    /// <summary>Program the addressed byte and erase the next lower counter stage.</summary>
    scwCarry,
    /// <summary>Program with the chip's backup option enabled.</summary>
    scwBackup,
    /// <summary>Program with carry and the chip's backup option enabled.</summary>
    scwCarryBackup);

  /// <summary>Pure ACR38x CCID section 9.3.7 commands; ACR39 is not assumed compatible.</summary>
  TSleCounterCodec = class
  public
    /// <summary>Builds the selector 07 reset command for an explicit supported chip.</summary>
    /// <param name="AModel">Caller-identified counter chip.</param>
    /// <returns>Owned FF A4 00 00 01 07 command.</returns>
    class function Select(const AModel: TSleCounterModel): TBytes; static;
    /// <summary>Builds a bounded reader-addressed read; caller must also know the actual chip geometry.</summary>
    /// <param name="AAddress">Byte address from zero through 255.</param>
    /// <param name="ACount">One through 128 bytes, without crossing address 255.</param>
    /// <returns>Owned FF B0 command.</returns>
    class function Read(const AAddress, ACount: Integer): TBytes; static;
    /// <summary>Builds one bit-programming/carry command; no implicit erase or PIN attempt.</summary>
    /// <param name="AModel">Backup modes are refused for SLE4406.</param>
    /// <param name="AAddress">Byte address from zero through 255.</param>
    /// <param name="AValue">Byte programmed LSB first by the reader.</param>
    /// <param name="AMode">Explicit programming, carry and backup flags.</param>
    /// <returns>Owned FF D0 00 address 02 mode value command.</returns>
    class function Write(const AModel: TSleCounterModel;
      const AAddress: Integer; const AValue: Byte;
      const AMode: TSleCounterWriteMode): TBytes; static;
    /// <summary>Builds code presentation, which consumes a presentation-counter bit.</summary>
    /// <param name="ACode">Exactly three supplied card-order bytes; caller owns and clears this array.</param>
    /// <returns>Owned PIN-bearing FF 20 command; caller must wipe it after use.</returns>
    /// <remarks>9000 confirms reader execution, not code correctness. The reader does not erase
    /// the presentation counter. This command is deliberately not automatically sent by the component.</remarks>
    class function PresentCode(const ACode: TBytes): TBytes; static;
    /// <summary>Builds the first half of the documented card-certificate calculation.</summary>
    /// <param name="AModel">SLE4436, SLE5536 or SLE6636.</param>
    /// <param name="AKey">00/01 for key 1/2; 80/81 CBC only for SLE5536/6636.</param>
    /// <param name="AClockPulses">Nonzero explicit clock pulses per certificate bit.</param>
    /// <param name="AChallenge">Exactly six challenge bytes.</param>
    /// <returns>Owned FF 84 command; the sole expected status is 6102.</returns>
    class function Challenge(const AModel: TSleCounterModel;
      const AKey, AClockPulses: Byte; const AChallenge: TBytes): TBytes; static;
    /// <summary>Builds the one documented certificate retrieval, not generic APDU retry handling.</summary>
    /// <returns>Owned FF C0 00 00 02 command.</returns>
    class function GetCertificate: TBytes; static;
  end;

  /// <summary>Explicit ACR38x CCID counter-card reads and verified programming.</summary>
  /// <remarks>Use on one owning thread. Supply ReadableBytes from the actual chip/application
  /// layout: it is a caller-declared readable window, not a claimed chip capacity. No counter
  /// arithmetic, personalisation unlock, automatic PIN presentation or certificate verification
  /// is inferred. Each operation resets/selects once inside an exclusive transaction.</remarks>
  TSleCounterCardReaderWriter = class(TComponent)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FModel: TSleCounterModel;
    FReadableBytes: Integer;
    FBusy: Boolean;
    procedure RequireIdle;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetModel(const AValue: TSleCounterModel);
    procedure SetReadableBytes(const AValue: Integer);
    procedure ValidateRange(const AAddress, ACount: Integer);
    procedure BeginOperation;
    procedure FinishOperation(const ASucceeded: Boolean);
    function Send(const ACommand: TBytes; const AStatus: Word;
      const ACount: Integer): TBytes;
    procedure SelectCard;
    function ReadSelected(const AAddress, ACount: Integer): TBytes;
  public
    /// <summary>Creates an inactive SLE4406 profile with an unset readable window.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads an explicit public byte range without presenting a code.</summary>
    /// <param name="AAddress">Start within the caller-declared readable window.</param>
    /// <param name="ACount">Positive count wholly inside that window.</param>
    /// <returns>Independent bytes after successful transaction release.</returns>
    function ReadMemory(const AAddress, ACount: Integer): TBytes;
    /// <summary>Programs one byte and checks the entire declared readable window.</summary>
    /// <param name="AAddress">Address within the window.</param>
    /// <param name="AValue">Requested programmed byte; zero-to-one transitions are refused.</param>
    /// <param name="AMode">Explicit mode; carry may erase other counter-stage bytes.</param>
    /// <param name="AExpectedBefore">Exactly ReadableBytes expected bytes, copied before I/O.</param>
    /// <param name="AExpectedAfter">Exactly ReadableBytes explicit result, including carry effects.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after dispatch, including release.</exception>
    /// <remarks>Plain/backup modes require other bytes unchanged. Carry modes require an
    /// explicit expected image derived from the actual chip layout. Verification covers this
    /// window only. No automatic retry, rollback or presentation-counter reset occurs.</remarks>
    procedure WriteByte(const AAddress: Integer; const AValue: Byte;
      const AMode: TSleCounterWriteMode;
      const AExpectedBefore, AExpectedAfter: TBytes);
    /// <summary>Calculates and acquires two raw certificate bytes with one challenge and one retrieval.</summary>
    /// <param name="AKey">Explicit key/CBC selection.</param>
    /// <param name="AClockPulses">Nonzero clock pulses per bit, typically A0 hex in the reader manual.</param>
    /// <param name="AChallenge">Six supplied challenge bytes, copied before I/O.</param>
    /// <returns>Owned raw certificate, LSB first within each byte; no issuer or key verification.</returns>
    function ReadCertificate(const AKey, AClockPulses: Byte;
      const AChallenge: TBytes): TBytes;
    /// <summary>Caller-owned connected ACR38x CCID transport implementing exclusive ICardTransaction.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
  published
    /// <summary>Explicit counter-chip model; SLE4406 by default.</summary>
    property Model: TSleCounterModel read FModel write SetModel
      default scmSle4406;
    /// <summary>Caller-declared readable byte window, one through 256; zero leaves the component unconfigured.</summary>
    property ReadableBytes: Integer read FReadableBytes write SetReadableBytes
      default 0;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

procedure Fail(const AReason: string);
begin
  raise EMemoryCardError.Create('Invalid SLE counter operation: ' +
    AReason + '.');
end;

procedure ValidateModel(const AModel: TSleCounterModel);
begin
  if (Ord(AModel) < Ord(Low(TSleCounterModel))) or
    (Ord(AModel) > Ord(High(TSleCounterModel))) then
    Fail('model');
end;

class function TSleCounterCodec.Select(const AModel: TSleCounterModel): TBytes;
begin
  ValidateModel(AModel);
  Result := HexToBytes('FFA400000107');
end;

class function TSleCounterCodec.Read(const AAddress, ACount: Integer): TBytes;
begin
  if (AAddress < 0) or (AAddress > 255) or (ACount < 1) or (ACount > 128) or
    (ACount > 256 - AAddress) then
    Fail('reader range');
  Result := HexToBytes('FFB0000000');
  Result[3] := Byte(AAddress);
  Result[4] := Byte(ACount);
end;

class function TSleCounterCodec.Write(const AModel: TSleCounterModel;
  const AAddress: Integer; const AValue: Byte;
  const AMode: TSleCounterWriteMode): TBytes;
begin
  ValidateModel(AModel);
  if (AAddress < 0) or (AAddress > 255) then
    Fail('reader address');
  if (Ord(AMode) < Ord(Low(TSleCounterWriteMode))) or
    (Ord(AMode) > Ord(High(TSleCounterWriteMode))) then
    Fail('write mode');
  if (AModel = scmSle4406) and (AMode in [scwBackup, scwCarryBackup]) then
    Fail('backup unavailable');
  Result := HexToBytes('FFD00000020000');
  Result[3] := Byte(AAddress);
  Result[5] := Byte(Ord(AMode));
  Result[6] := AValue;
end;

class function TSleCounterCodec.PresentCode(const ACode: TBytes): TBytes;
begin
  if Length(ACode) <> 3 then
    Fail('code length');
  Result := HexToBytes('FF2000000409000000');
  Move(ACode[0], Result[6], 3);
end;

class function TSleCounterCodec.Challenge(const AModel: TSleCounterModel;
  const AKey, AClockPulses: Byte; const AChallenge: TBytes): TBytes;
begin
  ValidateModel(AModel);
  if AModel = scmSle4406 then
    Fail('certificate unavailable');
  if not(AKey in [$00, $01, $80, $81]) then
    Fail('key');
  if (AModel = scmSle4436) and (AKey >= $80) then
    Fail('CBC unavailable');
  if (AClockPulses = 0) or (Length(AChallenge) <> 6) then
    Fail('challenge');
  Result := HexToBytes('FF840000080000000000000000');
  Result[5] := AKey;
  Result[6] := AClockPulses;
  Move(AChallenge[0], Result[7], 6);
end;

class function TSleCounterCodec.GetCertificate: TBytes;
begin
  Result := HexToBytes('FFC0000002');
end;

constructor TSleCounterCardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TSleCounterCardReaderWriter.RequireIdle;
begin
  if FBusy then
    Fail('operation active');
end;

procedure TSleCounterCardReaderWriter.SetTransport(const AValue
  : ICardTransport);
begin
  RequireIdle;
  FTransport := AValue;
end;

procedure TSleCounterCardReaderWriter.SetModel(const AValue: TSleCounterModel);
begin
  RequireIdle;
  ValidateModel(AValue);
  FModel := AValue;
end;

procedure TSleCounterCardReaderWriter.SetReadableBytes(const AValue: Integer);
begin
  RequireIdle;
  if (AValue < 0) or (AValue > 256) then
    Fail('readable window');
  FReadableBytes := AValue;
end;

procedure TSleCounterCardReaderWriter.ValidateRange(const AAddress,
  ACount: Integer);
begin
  RequireIdle;
  ValidateModel(FModel);
  if (FReadableBytes = 0) or (AAddress < 0) or (AAddress >= FReadableBytes) or
    (ACount < 1) or (ACount > FReadableBytes - AAddress) then
    Fail('readable range');
end;

procedure TSleCounterCardReaderWriter.BeginOperation;
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

procedure TSleCounterCardReaderWriter.FinishOperation(const ASucceeded
  : Boolean);
var
  Transaction: ICardTransaction;
begin
  Transaction := FTransaction;
  FTransaction := nil;
  try
    if ASucceeded then
      Transaction.EndTransaction
    else
      try
        Transaction.EndTransaction;
      except { Preserve the operation failure. } end;
  finally
    FBusy := False;
  end;
end;

function TSleCounterCardReaderWriter.Send(const ACommand: TBytes;
  const AStatus: Word; const ACount: Integer): TBytes;
var
  Wire: TBytes;
  Response: TApduResponse;
begin
  Wire := FTransport.Exchange(ACommand);
  if Length(Wire) <> ACount + 2 then
    Fail('response length');
  Response := TApduCodec.DecodeResponse(Wire);
  if Response.StatusWord <> AStatus then
    Fail('reader status');
  Result := CopyBytes(Response.Data);
end;

procedure TSleCounterCardReaderWriter.SelectCard;
begin
  Send(TSleCounterCodec.Select(FModel), $9000, 0);
end;

function TSleCounterCardReaderWriter.ReadSelected(const AAddress,
  ACount: Integer): TBytes;
var
  Done, Count: Integer;
  Part: TBytes;
begin
  Result := nil;
  SetLength(Result, ACount);
  Done := 0;
  while Done < ACount do
  begin
    Count := ACount - Done;
    if Count > 128 then
      Count := 128;
    Part := Send(TSleCounterCodec.Read(AAddress + Done, Count), $9000, Count);
    Move(Part[0], Result[Done], Count);
    Inc(Done, Count);
  end;
end;

function TSleCounterCardReaderWriter.ReadMemory(const AAddress,
  ACount: Integer): TBytes;
var
  Succeeded: Boolean;
begin
  ValidateRange(AAddress, ACount);
  BeginOperation;
  Succeeded := False;
  try
    SelectCard;
    Result := ReadSelected(AAddress, ACount);
    Succeeded := True;
  finally
    FinishOperation(Succeeded);
  end;
end;

procedure TSleCounterCardReaderWriter.WriteByte(const AAddress: Integer;
  const AValue: Byte; const AMode: TSleCounterWriteMode;
  const AExpectedBefore, AExpectedAfter: TBytes);
var
  Before, After, Actual, Wire: TBytes;
  I: Integer;
  Succeeded, Dispatched, Verified: Boolean;
begin
  ValidateRange(AAddress, 1);
  Wire := TSleCounterCodec.Write(FModel, AAddress, AValue, AMode);
  if (Length(AExpectedBefore) <> FReadableBytes) or
    (Length(AExpectedAfter) <> FReadableBytes) then
    Fail('expected window length');
  Before := CopyBytes(AExpectedBefore);
  After := CopyBytes(AExpectedAfter);
  if (Before[AAddress] and AValue) <> AValue then
    Fail('zero-to-one programming');
  if After[AAddress] <> AValue then
    Fail('expected programmed value');
  if AMode in [scwProgram, scwBackup] then
    for I := 0 to FReadableBytes - 1 do
      if (I <> AAddress) and (Before[I] <> After[I]) then
        Fail('unrelated expected change');
  Succeeded := False;
  Dispatched := False;
  Verified := False;
  BeginOperation;
  try
    try
      SelectCard;
      Actual := ReadSelected(0, FReadableBytes);
      if not BytesEqual(Actual, Before) then
        Fail('preflight mismatch');
      if (AMode in [scwProgram, scwBackup]) and BytesEqual(Before, After) then
        Verified := True
      else
      begin
        Dispatched := True;
        Send(Wire, $9000, 0);
        Actual := ReadSelected(0, FReadableBytes);
        if not BytesEqual(Actual, After) then
          Fail('verification mismatch');
        Verified := True;
      end;
      Succeeded := True;
    finally
      FinishOperation(Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
      raise;
    end;
  end;
end;

function TSleCounterCardReaderWriter.ReadCertificate(const AKey,
  AClockPulses: Byte; const AChallenge: TBytes): TBytes;
var
  Wire: TBytes;
  Succeeded: Boolean;
begin
  RequireIdle;
  Wire := TSleCounterCodec.Challenge(FModel, AKey, AClockPulses, AChallenge);
  BeginOperation;
  Succeeded := False;
  try
    SelectCard;
    Send(Wire, $6102, 0);
    Result := Send(TSleCounterCodec.GetCertificate, $9000, 2);
    Succeeded := True;
  finally
    FinishOperation(Succeeded);
  end;
end;

end.
