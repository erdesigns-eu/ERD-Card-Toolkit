unit ERD.Card.Memory.Sle4404;

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
  /// <summary>Caller-known SLE4404 byte regions; no addresses or area lengths are guessed.</summary>
  /// <remarks>Set only fields required by the intended operation. Zero lengths and minus-one
  /// addresses mean unconfigured. Code storage addresses 08/28 hex are fixed by the ACS protocol.</remarks>
  TSle4404AccessLayout = record
    /// <summary>Readable byte containing the four-bit user error counter; minus one when unknown.</summary>
    UserCounterAddress: Integer;
    /// <summary>Exactly four set bits locating the user counter within its readable byte.</summary>
    UserCounterMask: Byte;
    /// <summary>First readable byte of the 64-bit, non-restorable memory-code error counter.</summary>
    MemoryCounterAddress: Integer;
    /// <summary>Explicit scratchpad address passed to FF D2; typical 02 is not a default.</summary>
    ScratchPadAddress: Integer;
    /// <summary>Known readable scratchpad length in bytes.</summary>
    ScratchPadBytes: Integer;
    /// <summary>First readable byte of the application area erased by the memory-code command.</summary>
    ApplicationAddress: Integer;
    /// <summary>Known readable application-area length in bytes.</summary>
    ApplicationBytes: Integer;
  end;
  /// <summary>Pure ACR38x CCID section 9.3.8 SLE4404 commands; no ACR39 compatibility is implied.</summary>
  TSle4404Codec = class
  public
    /// <summary>Builds the selector 08 card reset.</summary>
    /// <returns>Owned FF A4 00 00 01 08 command.</returns>
    class function Select: TBytes; static;
    /// <summary>Builds an explicit bounded public-memory read.</summary>
    /// <param name="AAddress">Reader byte address, zero through 255.</param>
    /// <param name="ACount">One through 128 bytes without crossing address 255.</param>
    /// <returns>Owned FF B0 command; actual chip geometry must also be checked.</returns>
    class function Read(const AAddress, ACount: Integer): TBytes; static;
    /// <summary>Builds bit programming, without an implicit erase.</summary>
    /// <param name="AAddress">Explicit byte address, zero through 255.</param>
    /// <param name="AData">One through 128 bytes within the reader address range.</param>
    /// <returns>Owned FF D0 command; current bits must permit one-to-zero programming.</returns>
    class function ProgramCommand(const AAddress: Integer; const AData: TBytes): TBytes; static;
    /// <summary>Builds an explicit scratchpad erase; this is not ordinary programming.</summary>
    /// <param name="AAddress">Caller-known scratchpad address.</param>
    /// <returns>Owned FF D2 00 address 00 command.</returns>
    class function EraseScratchPad(const AAddress: Integer): TBytes; static;
    /// <summary>Builds one user-code presentation with four error-counter bits.</summary>
    /// <param name="ACode">Exactly two supplied card-order bytes.</param>
    /// <returns>Owned credential-bearing FF 20 04 08 02 command; caller must wipe it.</returns>
    /// <remarks>9000 alone is insufficient: success requires reading an erased FF user-counter byte.</remarks>
    class function UserCode(const ACode: TBytes): TBytes; static;
    /// <summary>Builds memory-code presentation, which can erase the application area.</summary>
    /// <param name="ACode">Exactly four supplied card-order bytes.</param>
    /// <returns>Owned credential-bearing FF 20 40 28 04 command; caller must wipe it.</returns>
    /// <remarks>The 64-bit memory error counter cannot be restored. 9000 alone does not
    /// prove correctness; verify that a previously non-erased application area became FF.</remarks>
    class function MemoryCode(const ACode: TBytes): TBytes; static;
  end;
  /// <summary>SLE4404 access, bit programming and explicit verified erases through ACR38x CCID.</summary>
  /// <remarks>Supply the actual accessible window and relevant Layout fields from the chip/application
  /// data sheet. Use on one owning thread. Every operation selects once in an exclusive transaction;
  /// no code guessing, fallback, automatic retry or authentication retention occurs. Owned code and
  /// command buffers are cleared locally; transport/backend copies are outside this guarantee.</remarks>
  TSle4404CardReaderWriter = class(TComponent)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FLayout: TSle4404AccessLayout;
    FReadableBytes, FMinimumUserCodeAttempts, FMinimumMemoryCodeAttempts: Integer;
    FBusy: Boolean;
    procedure RequireIdle;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetLayout(const AValue: TSle4404AccessLayout);
    procedure SetReadableBytes(const AValue: Integer);
    procedure SetMinimumUserCodeAttempts(const AValue: Integer);
    procedure SetMinimumMemoryCodeAttempts(const AValue: Integer);
    procedure ValidateRange(const AAddress, ACount: Integer);
    procedure ValidateUserLayout;
    procedure ValidateArea(const AAddress, ACount: Integer);
    procedure ValidateCode(const ACode: TBytes; const ARequired: Boolean);
    procedure BeginOperation;
    procedure FinishOperation(const ASucceeded: Boolean);
    procedure SelectCard;
    function Send(const ACommand: TBytes; const ACount: Integer): TBytes;
    function ReadSelected(const AAddress, ACount: Integer): TBytes;
    function AuthenticateUser(const ACode: TBytes): TMemoryCardSecurityStatus;
    procedure EraseArea(const AScratchPad: Boolean; const AExpectedBefore, AUserCode, AMemoryCode: TBytes);
  public
    /// <summary>Creates an inactive component with an unset layout/window and one-attempt minimum budgets.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads a known range, optionally presenting a supplied user code once in the same transaction.</summary>
    /// <param name="AAddress">Start inside ReadableBytes.</param>
    /// <param name="ACount">Positive range length.</param>
    /// <param name="AUserCode">Empty for public reads, otherwise exactly two card-order bytes.</param>
    /// <returns>Independent raw bytes after successful release; supplied code copies are not returned.</returns>
    function ReadMemory(const AAddress, ACount: Integer; const AUserCode: TBytes): TBytes;
    /// <summary>Presents a supplied user code once and requires counter read-back FF.</summary>
    /// <param name="ACode">Exactly two card-order bytes; the original array is unchanged.</param>
    /// <returns>Verified retry status after release; authentication is not retained across operations.</returns>
    /// <exception cref="EMemoryCardAuthenticationError">A dispatched attempt or its cleanup could not be proven successful.</exception>
    function VerifyUserCode(const ACode: TBytes): TMemoryCardSecurityStatus;
    /// <summary>Programs a range from one bits to zero bits with stale-state and independent read-back checks.</summary>
    /// <param name="AAddress">Explicit start within ReadableBytes.</param>
    /// <param name="AExpectedBefore">Nonempty expected current range, copied before I/O.</param>
    /// <param name="AData">Requested bytes of equal length; zero-to-one changes are refused before I/O.</param>
    /// <param name="AUserCode">Empty for public programming, otherwise two supplied bytes.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after programming dispatch, including release.</exception>
    /// <remarks>If supplied, the user code is verified before acquiring protected range contents.
    /// Identical data skips programming but does not skip that explicitly requested code attempt.</remarks>
    procedure ProgramMemory(const AAddress: Integer; const AExpectedBefore, AData, AUserCode: TBytes);
    /// <summary>Deliberately erases the configured scratchpad and verifies all its readable bytes are FF.</summary>
    /// <param name="AExpectedBefore">Exactly Layout.ScratchPadBytes expected current bytes.</param>
    /// <param name="AUserCode">Empty for public scratchpad access, otherwise two supplied bytes.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after erase dispatch, including release.</exception>
    /// <remarks>A matching already-erased scratchpad is a no-op. Verification covers the declared area only.</remarks>
    procedure EraseScratchPad(const AExpectedBefore, AUserCode: TBytes);
    /// <summary>Deliberately presents both codes to erase the configured application area, with read-back proof.</summary>
    /// <param name="AExpectedBefore">Exactly Layout.ApplicationBytes expected data, with at least one non-FF byte.</param>
    /// <param name="AUserCode">Exactly two supplied user-code bytes.</param>
    /// <param name="AMemoryCode">Exactly four supplied memory-code bytes; attempted once.</param>
    /// <exception cref="EMemoryCardWriteUncertain">Any failure after the memory-code/erase dispatch, including release.</exception>
    /// <remarks>Requires both configured error counters and budgets. The memory counter cannot
    /// be restored. An already-erased area is refused before I/O because it cannot prove this code.</remarks>
    procedure EraseApplication(const AExpectedBefore, AUserCode, AMemoryCode: TBytes);
    /// <summary>Connected ACR38x CCID transport implementing exclusive ICardTransaction.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
    /// <summary>Caller-known byte areas and error-counter locations; set only while idle.</summary>
    property Layout: TSle4404AccessLayout read FLayout write SetLayout;
  published
    /// <summary>Declared accessible byte window, one through 256; zero is unconfigured.</summary>
    property ReadableBytes: Integer read FReadableBytes write SetReadableBytes default 0;
    /// <summary>Minimum remaining user-counter bits before one code attempt; one through four, default one.</summary>
    property MinimumUserCodeAttempts: Integer read FMinimumUserCodeAttempts write SetMinimumUserCodeAttempts default 1;
    /// <summary>Minimum remaining memory-counter bits before one application erase; one through 64, default one.</summary>
    property MinimumMemoryCodeAttempts: Integer read FMinimumMemoryCodeAttempts write SetMinimumMemoryCodeAttempts default 1;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto;

procedure Fail(const AReason: string);
begin raise EMemoryCardError.Create('Invalid SLE4404 operation: ' + AReason + '.'); end;

function BitCount(const AValue: Byte): Integer;
var I: Integer;
begin Result := 0; for I := 0 to 7 do if (AValue and (1 shl I)) <> 0 then Inc(Result); end;

function Erased(const AData: TBytes): Boolean;
var I: Integer;
begin
  Result := False; if Length(AData) = 0 then Exit;
  for I := 0 to Length(AData) - 1 do if AData[I] <> $FF then Exit;
  Result := True;
end;

function Overlap(const AAddress, ACount, BAddress, BCount: Integer): Boolean;
begin Result := (AAddress < BAddress + BCount) and (BAddress < AAddress + ACount); end;

class function TSle4404Codec.Select: TBytes;
begin Result := HexToBytes('FFA400000108'); end;

class function TSle4404Codec.Read(const AAddress, ACount: Integer): TBytes;
begin
  if (AAddress < 0) or (AAddress > 255) or (ACount < 1) or
    (ACount > 128) or (ACount > 256 - AAddress) then Fail('reader range');
  Result := HexToBytes('FFB0000000'); Result[3] := Byte(AAddress); Result[4] := Byte(ACount);
end;

class function TSle4404Codec.ProgramCommand(const AAddress: Integer; const AData: TBytes): TBytes;
begin
  Result := Read(AAddress, Length(AData)); Result[1] := $D0;
  SetLength(Result, 5 + Length(AData)); Move(AData[0], Result[5], Length(AData));
end;

class function TSle4404Codec.EraseScratchPad(const AAddress: Integer): TBytes;
begin
  if (AAddress < 0) or (AAddress > 255) then Fail('scratchpad address');
  Result := HexToBytes('FFD2000000'); Result[3] := Byte(AAddress);
end;

class function TSle4404Codec.UserCode(const ACode: TBytes): TBytes;
begin
  if Length(ACode) <> 2 then Fail('user-code length');
  Result := HexToBytes('FF200408020000'); Move(ACode[0], Result[5], 2);
end;

class function TSle4404Codec.MemoryCode(const ACode: TBytes): TBytes;
begin
  if Length(ACode) <> 4 then Fail('memory-code length');
  Result := HexToBytes('FF2040280400000000'); Move(ACode[0], Result[5], 4);
end;

constructor TSle4404CardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FMinimumUserCodeAttempts := 1; FMinimumMemoryCodeAttempts := 1;
  FLayout.UserCounterAddress := -1; FLayout.MemoryCounterAddress := -1;
  FLayout.ScratchPadAddress := -1; FLayout.ApplicationAddress := -1;
end;

procedure TSle4404CardReaderWriter.RequireIdle;
begin if FBusy then Fail('operation active'); end;

procedure TSle4404CardReaderWriter.SetTransport(const AValue: ICardTransport);
begin RequireIdle; FTransport := AValue; end;

procedure TSle4404CardReaderWriter.SetLayout(const AValue: TSle4404AccessLayout);
begin
  RequireIdle;
  if (AValue.UserCounterAddress < -1) or (AValue.UserCounterAddress > 255) or
    (AValue.MemoryCounterAddress < -1) or (AValue.MemoryCounterAddress > 255) or
    (AValue.ScratchPadAddress < -1) or (AValue.ScratchPadAddress > 255) or
    (AValue.ApplicationAddress < -1) or (AValue.ApplicationAddress > 255) or
    (AValue.ScratchPadBytes < 0) or (AValue.ScratchPadBytes > 256) or
    (AValue.ApplicationBytes < 0) or (AValue.ApplicationBytes > 256) then Fail('layout');
  FLayout := AValue;
end;

procedure TSle4404CardReaderWriter.SetReadableBytes(const AValue: Integer);
begin RequireIdle; if (AValue < 0) or (AValue > 256) then Fail('window'); FReadableBytes := AValue; end;

procedure TSle4404CardReaderWriter.SetMinimumUserCodeAttempts(const AValue: Integer);
begin RequireIdle; if (AValue < 1) or (AValue > 4) then Fail('user-code budget'); FMinimumUserCodeAttempts := AValue; end;

procedure TSle4404CardReaderWriter.SetMinimumMemoryCodeAttempts(const AValue: Integer);
begin RequireIdle; if (AValue < 1) or (AValue > 64) then Fail('memory-code budget'); FMinimumMemoryCodeAttempts := AValue; end;

procedure TSle4404CardReaderWriter.ValidateRange(const AAddress, ACount: Integer);
begin
  if (FReadableBytes = 0) or (AAddress < 0) or (AAddress >= FReadableBytes) or
    (ACount < 1) or (ACount > FReadableBytes - AAddress) then Fail('declared range');
end;

procedure TSle4404CardReaderWriter.ValidateUserLayout;
begin
  ValidateRange(FLayout.UserCounterAddress, 1);
  if BitCount(FLayout.UserCounterMask) <> 4 then Fail('four-bit user-counter mask');
  if Overlap(FLayout.UserCounterAddress, 1, $08, 2) or
    Overlap(FLayout.UserCounterAddress, 1, $28, 4) then Fail('counter overlaps code storage');
end;

procedure TSle4404CardReaderWriter.ValidateArea(const AAddress, ACount: Integer);
begin
  ValidateRange(AAddress, ACount);
  if Overlap(AAddress, ACount, $08, 2) or Overlap(AAddress, ACount, $28, 4) then
    Fail('erase area overlaps code storage');
  if (FLayout.UserCounterAddress >= 0) and Overlap(AAddress, ACount, FLayout.UserCounterAddress, 1) then
    Fail('erase area overlaps user counter');
  if (FLayout.MemoryCounterAddress >= 0) and Overlap(AAddress, ACount, FLayout.MemoryCounterAddress, 8) then
    Fail('erase area overlaps memory counter');
end;

procedure TSle4404CardReaderWriter.ValidateCode(const ACode: TBytes; const ARequired: Boolean);
begin
  if (Length(ACode) <> 2) and (ARequired or (Length(ACode) <> 0)) then Fail('user-code length');
  if Length(ACode) <> 0 then ValidateUserLayout;
end;

procedure TSle4404CardReaderWriter.BeginOperation;
begin
  RequireIdle;
  if (FTransport = nil) or not Supports(FTransport, ICardTransaction, FTransaction) then
    Fail('exclusive transaction required');
  FBusy := True;
  try FTransaction.BeginTransaction;
  except FTransaction := nil; FBusy := False; raise; end;
end;

procedure TSle4404CardReaderWriter.FinishOperation(const ASucceeded: Boolean);
var Transaction: ICardTransaction;
begin
  Transaction := FTransaction; FTransaction := nil;
  try
    if ASucceeded then Transaction.EndTransaction
    else try Transaction.EndTransaction; except { Preserve the original error. } end;
  finally FBusy := False; end;
end;

function TSle4404CardReaderWriter.Send(const ACommand: TBytes; const ACount: Integer): TBytes;
var Wire: TBytes; Status: Word;
begin
  Wire := nil;
  try
    Wire := FTransport.Exchange(ACommand);
    if Length(Wire) <> ACount + 2 then Fail('response length');
    Status := (Word(Wire[Length(Wire) - 2]) shl 8) or Wire[Length(Wire) - 1];
    if Status <> $9000 then Fail('reader status');
    Result := Copy(Wire, 0, ACount);
  finally TCardCrypto.Clear(Wire); end;
end;

procedure TSle4404CardReaderWriter.SelectCard;
begin Send(TSle4404Codec.Select, 0); end;

function TSle4404CardReaderWriter.ReadSelected(const AAddress, ACount: Integer): TBytes;
var Done, Count: Integer; Part: TBytes;
begin
  Result := nil; SetLength(Result, ACount); Done := 0;
  while Done < ACount do
  begin
    Count := ACount - Done; if Count > 128 then Count := 128;
    Part := Send(TSle4404Codec.Read(AAddress + Done, Count), Count);
    Move(Part[0], Result[Done], Count); Inc(Done, Count);
  end;
end;

function TSle4404CardReaderWriter.AuthenticateUser(const ACode: TBytes): TMemoryCardSecurityStatus;
var Counter, Wire: TBytes; Dispatched: Boolean;
begin
  Result := Default(TMemoryCardSecurityStatus);
  Counter := ReadSelected(FLayout.UserCounterAddress, 1);
  if BitCount(Counter[0] and FLayout.UserCounterMask) < FMinimumUserCodeAttempts then Fail('user-code retry budget');
  Wire := nil; Dispatched := False;
  try
    Wire := TSle4404Codec.UserCode(ACode);
    try
      Dispatched := True; Send(Wire, 0);
      Counter := ReadSelected(FLayout.UserCounterAddress, 1);
      if Counter[0] <> $FF then Fail('user-code counter proof');
      Result.Counter := Counter[0]; Result.RemainingAttempts := 4;
    except
      on E: Exception do
      begin
        if Dispatched then raise EMemoryCardAuthenticationError.Create('SLE4404 user-code attempt was not verified: ' + E.ClassName + '.');
        raise;
      end;
    end;
  finally TCardCrypto.Clear(Wire); end;
end;

function TSle4404CardReaderWriter.ReadMemory(const AAddress, ACount: Integer;
  const AUserCode: TBytes): TBytes;
var Code: TBytes; Succeeded: Boolean;
begin
  RequireIdle; ValidateRange(AAddress, ACount); ValidateCode(AUserCode, False);
  Code := CopyBytes(AUserCode);
  try
    BeginOperation; Succeeded := False;
    try
      SelectCard; if Length(Code) <> 0 then AuthenticateUser(Code);
      Result := ReadSelected(AAddress, ACount); Succeeded := True;
    finally FinishOperation(Succeeded); end;
  finally TCardCrypto.Clear(Code); end;
end;

function TSle4404CardReaderWriter.VerifyUserCode(const ACode: TBytes): TMemoryCardSecurityStatus;
var Code: TBytes; Succeeded, Proven: Boolean;
begin
  RequireIdle; ValidateCode(ACode, True); Code := CopyBytes(ACode);
  try
    BeginOperation; Succeeded := False; Proven := False;
    try
      try SelectCard; Result := AuthenticateUser(Code); Proven := True; Succeeded := True;
      finally FinishOperation(Succeeded); end;
    except
      on E: Exception do
      begin
        if Proven then raise EMemoryCardAuthenticationError.Create('SLE4404 code proof obtained but cleanup failed: ' + E.ClassName + '.');
        raise;
      end;
    end;
  finally TCardCrypto.Clear(Code); end;
end;

procedure TSle4404CardReaderWriter.ProgramMemory(const AAddress: Integer;
  const AExpectedBefore, AData, AUserCode: TBytes);
var Before, Data, Code, Actual, Part, Wire: TBytes; I, Done, Count: Integer;
  Succeeded, Dispatched, Verified: Boolean;
begin
  RequireIdle; ValidateRange(AAddress, Length(AData)); ValidateCode(AUserCode, False);
  if Length(AExpectedBefore) <> Length(AData) then Fail('expected range length');
  for I := 0 to Length(AData) - 1 do
    if (AExpectedBefore[I] and AData[I]) <> AData[I] then Fail('zero-to-one programming');
  Code := nil; Wire := nil;
  try
    Before := CopyBytes(AExpectedBefore); Data := CopyBytes(AData); Code := CopyBytes(AUserCode);
    BeginOperation; Succeeded := False; Dispatched := False; Verified := False;
    try
      try
        SelectCard; if Length(Code) <> 0 then AuthenticateUser(Code);
        Actual := ReadSelected(AAddress, Length(Data));
        if not BytesEqual(Actual, Before) then Fail('preflight mismatch');
        Done := 0;
        while Done < Length(Data) do
        begin
          Count := Length(Data) - Done; if Count > 128 then Count := 128;
          Part := Copy(Data, Done, Count);
          if not BytesEqual(Part, Copy(Before, Done, Count)) then
          begin
            Wire := TSle4404Codec.ProgramCommand(AAddress + Done, Part);
            Dispatched := True; Send(Wire, 0); TCardCrypto.Clear(Wire);
            Actual := ReadSelected(AAddress + Done, Count);
            if not BytesEqual(Actual, Part) then Fail('programming read-back');
          end;
          Inc(Done, Count);
        end;
        Verified := True; Succeeded := True;
      finally FinishOperation(Succeeded); end;
    except
      on E: Exception do
      begin
        if Dispatched then raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally TCardCrypto.Clear(Code); TCardCrypto.Clear(Wire); end;
end;

procedure TSle4404CardReaderWriter.EraseArea(const AScratchPad: Boolean;
  const AExpectedBefore, AUserCode, AMemoryCode: TBytes);
var Before, Code, Memory, Wire, Actual, Counter: TBytes;
  Address, Count, I, Attempts: Integer; Succeeded, Dispatched, Verified: Boolean;
begin
  RequireIdle;
  if AScratchPad then begin Address := FLayout.ScratchPadAddress; Count := FLayout.ScratchPadBytes; end
  else begin Address := FLayout.ApplicationAddress; Count := FLayout.ApplicationBytes; end;
  ValidateArea(Address, Count); ValidateCode(AUserCode, not AScratchPad);
  if Length(AExpectedBefore) <> Count then Fail('expected area length');
  if not AScratchPad then
  begin
    if Length(AMemoryCode) <> 4 then Fail('memory-code length');
    ValidateRange(FLayout.MemoryCounterAddress, 8);
    if Overlap(FLayout.MemoryCounterAddress, 8, FLayout.UserCounterAddress, 1) or
      Overlap(FLayout.MemoryCounterAddress, 8, $08, 2) or
      Overlap(FLayout.MemoryCounterAddress, 8, $28, 4) then Fail('memory-counter overlap');
    if Erased(AExpectedBefore) then Fail('already-erased area cannot prove memory code');
  end;
  Code := nil; Memory := nil; Wire := nil;
  try
    Before := CopyBytes(AExpectedBefore); Code := CopyBytes(AUserCode); Memory := CopyBytes(AMemoryCode);
    BeginOperation; Succeeded := False; Dispatched := False; Verified := False;
    try
      try
        SelectCard;
        if not AScratchPad then
        begin
          Counter := ReadSelected(FLayout.MemoryCounterAddress, 8); Attempts := 0;
          for I := 0 to 7 do Inc(Attempts, BitCount(Counter[I]));
          if Attempts < FMinimumMemoryCodeAttempts then Fail('memory-code retry budget');
        end;
        if Length(Code) <> 0 then AuthenticateUser(Code);
        Actual := ReadSelected(Address, Count);
        if not BytesEqual(Actual, Before) then Fail('preflight mismatch');
        if not AScratchPad or not Erased(Before) then
        begin
          if AScratchPad then Wire := TSle4404Codec.EraseScratchPad(Address)
          else Wire := TSle4404Codec.MemoryCode(Memory);
          Dispatched := True; Send(Wire, 0);
          Actual := ReadSelected(Address, Count);
          if not Erased(Actual) then Fail('erase read-back proof');
        end;
        Verified := True; Succeeded := True;
      finally FinishOperation(Succeeded); end;
    except
      on E: Exception do
      begin
        if Dispatched then raise EMemoryCardWriteUncertain.Create(E.ClassName, Verified);
        raise;
      end;
    end;
  finally TCardCrypto.Clear(Code); TCardCrypto.Clear(Memory); TCardCrypto.Clear(Wire); end;
end;

procedure TSle4404CardReaderWriter.EraseScratchPad(const AExpectedBefore, AUserCode: TBytes);
begin EraseArea(True, AExpectedBefore, AUserCode, nil); end;

procedure TSle4404CardReaderWriter.EraseApplication(const AExpectedBefore, AUserCode, AMemoryCode: TBytes);
begin EraseArea(False, AExpectedBefore, AUserCode, AMemoryCode); end;

end.
