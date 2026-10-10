unit ERD.Card.Reader.TWN4;

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
  ERD.Card.Contactless, ERD.Card.Contactless.Type2;

type
  /// <summary>Invalid TWN4 configuration, serial framing or command result; no credential/payload text is included.</summary>
  ETwn4Error = class(Exception);

  /// <summary>A card write was dispatched and its complete outcome or cleanup could not be proven.</summary>
  ETwn4WriteUncertain = class(ETwn4Error)
  private
    FVerified: Boolean;
  public
    /// <summary>Creates a sanitized uncertainty error without retaining a backend exception message.</summary>
    /// <param name="AVerified">Whether independent card read-back had already matched before failure.</param>
    constructor Create(const AVerified: Boolean); reintroduce;
    /// <summary>Read-back proof obtained before a later failure; does not imply successful cleanup.</summary>
    property VerifiedReadBack: Boolean read FVerified;
  end;

  /// <summary>Exclusive host byte channel for TWN4 Simple Protocol ASCII/CDC, not keyboard HID reports.</summary>
  /// <remarks>Use on one thread. Failed Open grants no ownership. Send is once-only and errors
  /// on partial completion. No automatic retries, protocol switching or device selection occurs.</remarks>
  ITwn4ByteChannel = interface
    ['{DA06B217-BC10-413A-8D1D-F2EB7D307269}']
    /// <summary>Opens the explicitly configured channel exclusively; no reader command is sent.</summary>
    procedure Open;
    /// <summary>Closes an acquired channel and clears ownership, even when cleanup raises.</summary>
    procedure Close;
    /// <summary>Sends one complete owned-by-caller byte array once, without resuming partial writes.</summary>
    /// <param name="ABytes">Bounded ASCII request, not retained.</param>
    /// <param name="ATimeoutMs">Remaining I/O deadline in milliseconds.</param>
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    /// <summary>Receives one byte or raises on timeout/failure, never inventing an empty byte.</summary>
    /// <param name="ATimeoutMs">Remaining I/O deadline in milliseconds.</param>
    /// <returns>One actually acquired byte.</returns>
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    /// <summary>Returns an unsigned monotonic millisecond clock without opening hardware.</summary>
    /// <returns>Total milliseconds on a clock that does not move backwards.</returns>
    function NowMs: UInt64;
  end;

  /// <summary>Reader-visible tag identity from SearchTag; no RF/card authenticity is asserted.</summary>
  TTwn4TagInfo = record
    /// <summary>Whether a complete successful SearchTag result reported a tag.</summary>
    Found: Boolean;
    /// <summary>Opaque ELATEC tag type; 80 hex is the documented ISO14443A/MIFARE category.</summary>
    TagType: Byte;
    /// <summary>Valid identifier bits as reported by the reader.</summary>
    IdBitCount: Byte;
    /// <summary>Independent raw identifier bytes in reader order; no canonical byte-order guess.</summary>
    Id: TBytes;
  end;

  /// <summary>Pure bounded TWN4 Simple Protocol ASCII framing, with optional documented CRC.</summary>
  TTwn4Codec = class
  public
    /// <summary>Encodes a raw API/function request as uppercase hex and CR, optionally appending CRC little endian.</summary>
    /// <param name="ACommand">Two through 256 raw bytes, including API and function numbers.</param>
    /// <param name="AUseCrc">Explicitly match configured PRS firmware mode; never auto-detected.</param>
    /// <returns>Owned credential-bearing ASCII buffer when the command contains a key; wipe after use.</returns>
    class function EncodeAscii(const ACommand: TBytes; const AUseCrc: Boolean)
      : TBytes; static;
    /// <summary>Validates one exact ASCII/CR response and CRC before interpreting protocol status.</summary>
    /// <param name="ALine">Complete bounded line without echo, LF, whitespace or trailing bytes.</param>
    /// <param name="AUseCrc">Explicit response CRC mode matching the request.</param>
    /// <returns>Owned raw response after zero protocol status; status byte is retained.</returns>
    class function DecodeAscii(const ALine: TBytes; const AUseCrc: Boolean)
      : TBytes; static;
    /// <summary>Decodes a complete SearchTag response with bounded consistent ID bits/bytes.</summary>
    /// <param name="AResponse">Status-first response already validated by DecodeAscii.</param>
    /// <returns>Owned tag identity; no-tag responses expose no stale identifier.</returns>
    class function DecodeTag(const AResponse: TBytes): TTwn4TagInfo; static;
  end;

  /// <summary>Explicit TWN4 PRS/USB-CDC tag reads and guarded Classic/Type 2 memory operations.</summary>
  /// <remarks>Requires suitable ELATEC Simple Protocol firmware in ASCII mode; not generic HID.
  /// No firmware change, tag-family probing, default keys or UID programming occurs. Each call
  /// opens an exclusive channel, selects/checks the expected tag, then closes. Successful chains
  /// turn RF off before closing; failed chains close without sending speculative cleanup commands.
  /// Owned key/command copies are wiped; backend copies are outside this guarantee.
  /// Card contents can change/removal can occur between commands: ID checks are not authentication.</remarks>
  TTwn4CardReaderWriter = class(TComponent)
  private
    FChannel: ITwn4ByteChannel;
    FTimeoutMs: Cardinal;
    FUseCrc, FBusy, FAcquired: Boolean;
    FStarted, FLastClock: UInt64;
    procedure RequireIdle;
    procedure SetChannel(const AValue: ITwn4ByteChannel);
    procedure SetTimeoutMs(const AValue: Cardinal);
    procedure SetUseCrc(const AValue: Boolean);
    procedure BeginOperation;
    procedure FinishOperation(const ASucceeded: Boolean);
    function Remaining: Cardinal;
    function Command(const ARaw: TBytes): TBytes;
    function ExchangeCommand(const ARaw: TBytes; const ACardWrite: Boolean;
      var ADispatched: Boolean): TBytes;
    procedure SelectExpected(const AExpectedId: TBytes);
    procedure ValidateId(const AExpectedId: TBytes);
    procedure ValidateClassic(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AReaderSector: Byte;
      const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
    procedure Login(const ASector: Byte; const AKeyType: TMifareClassicKeyType;
      const AKey: TBytes);
    function ReadData(const AClassic: Boolean; const AAddress: Byte): TBytes;
    procedure WriteData(const AClassic: Boolean; const AAddress: Byte;
      const AData: TBytes; var ADispatched: Boolean);
    function ClassicOperation(const AWrite: Boolean;
      const AModel: TMifareClassicModel; const ABlock: Integer;
      const AReaderSector: Byte; const AKeyType: TMifareClassicKeyType;
      const AKey, AExpectedId, AExpectedBefore, AData: TBytes): TBytes;
    function Type2Operation(const AWrite: Boolean; const AModel: TType2TagModel;
      const APage: Integer; const AExpectedId, AExpectedBefore,
      AData: TBytes): TBytes;
  public
    /// <summary>Creates an inactive component, with a 3000 ms shared I/O budget and ASCII CRC disabled.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads a bounded version string without selecting or reconfiguring a tag.</summary>
    /// <returns>ASCII version after channel cleanup; no firmware capability certification.</returns>
    function ReadVersion: string;
    /// <summary>Searches/selects at most one tag through RF SearchTag, then turns RF off and closes.</summary>
    /// <returns>Owned reader-reported tag identity after cleanup; low-frequency IDs are readable too.</returns>
    function ReadTag: TTwn4TagInfo;
    /// <summary>Reads one explicit Classic block using a supplied sector key and expected tag ID.</summary>
    /// <param name="AModel">Explicit Mini/1K/4K geometry.</param>
    /// <param name="ABlock">In-range physical block.</param>
    /// <param name="AReaderSector">Documented reader-sector byte; low sectors must match block div four.
    /// For 4K blocks 128 onward supply firmware-defined sector encoding explicitly; it is not guessed.</param>
    /// <param name="AKeyType">A maps to TWN4 zero; B to one.</param>
    /// <param name="AKey">Exactly six supplied bytes, copied and wiped locally.</param>
    /// <param name="AExpectedId">Previously acquired 4/7/10-byte ID, checked before login.</param>
    /// <returns>Owned sixteen-byte block after RF/channel cleanup.</returns>
    function ReadClassicBlock(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AReaderSector: Byte;
      const AKeyType: TMifareClassicKeyType;
      const AKey, AExpectedId: TBytes): TBytes;
    /// <summary>Writes a Classic data block once after expected-state comparison and verifies by independent read-back.</summary>
    /// <param name="AModel">Explicit Mini/1K/4K geometry.</param>
    /// <param name="ABlock">Data block only; manufacturer and every sector trailer are refused before I/O.</param>
    /// <param name="AReaderSector">Explicit firmware reader-sector encoding as for ReadClassicBlock.</param>
    /// <param name="AKeyType">Explicit supplied key A or B.</param>
    /// <param name="AKey">Six bytes; owned copies are wiped.</param>
    /// <param name="AExpectedId">4/7/10-byte expected ID, checked before login and immediately before programming.</param>
    /// <param name="AExpectedBefore">Sixteen expected current bytes; mismatch prevents programming.</param>
    /// <param name="AData">Sixteen replacement bytes; a matching no-op skips programming.</param>
    /// <exception cref="ETwn4WriteUncertain">Any failure after write dispatch, including cleanup; never retry automatically.</exception>
    procedure WriteClassicDataBlock(const AModel: TMifareClassicModel;
      const ABlock: Integer; const AReaderSector: Byte;
      const AKeyType: TMifareClassicKeyType;
      const AKey, AExpectedId, AExpectedBefore, AData: TBytes);
    /// <summary>Reads one public Type 2 user page; the reader's sixteen-byte READ is bounded and reduced to four bytes.</summary>
    /// <param name="AModel">Explicit supported Ultralight/EV1/NTAG geometry.</param>
    /// <param name="APage">User page only, including the final user page.</param>
    /// <param name="AExpectedId">Expected seven-byte ID.</param>
    /// <returns>Owned first four acquired bytes after RF/channel cleanup; no PWD_AUTH is issued.</returns>
    function ReadType2UserPage(const AModel: TType2TagModel;
      const APage: Integer; const AExpectedId: TBytes): TBytes;
    /// <summary>Writes a public Type 2 user page once and requires exact before/after read-back.</summary>
    /// <param name="AModel">Explicit supported geometry; model does not prove locks or firmware support.</param>
    /// <param name="APage">User-data page; manufacturer/lock/configuration pages are refused before I/O.</param>
    /// <param name="AExpectedId">Seven-byte ID checked before reading and immediately before programming.</param>
    /// <param name="AExpectedBefore">Exactly four expected current bytes.</param>
    /// <param name="AData">Exactly four replacement bytes; matching data skips programming.</param>
    /// <exception cref="ETwn4WriteUncertain">Failure after write dispatch or cleanup; acquired proof is exposed.</exception>
    procedure WriteType2UserPage(const AModel: TType2TagModel;
      const APage: Integer; const AExpectedId, AExpectedBefore, AData: TBytes);
    /// <summary>Runtime exclusive ASCII byte channel; set only while idle.</summary>
    property Channel: ITwn4ByteChannel read FChannel write SetChannel;
  published
    /// <summary>Shared per-call I/O deadline, one through 600000 milliseconds; native Open/Close driver latency is separate.</summary>
    property TimeoutMs: Cardinal read FTimeoutMs write SetTimeoutMs
      default 3000;
    /// <summary>Explicit ASCII CRC mode matching installed PRS firmware; false by default, never auto-switched.</summary>
    property UseCrc: Boolean read FUseCrc write SetUseCrc default False;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto;

procedure Fail;
begin
  raise ETwn4Error.Create('Invalid TWN4 state, framing or command result.');
end;

function Crc(const B: TBytes): Word;
var
  I, J: Integer;
  V: Cardinal;
begin
  V := $FFFF;
  for I := 0 to Length(B) - 1 do
  begin
    V := V xor B[I];
    for J := 0 to 7 do
      if (V and 1) <> 0 then
        V := (V shr 1) xor $8408
      else
        V := V shr 1;
  end;
  Result := Word(V);
end;

constructor ETwn4WriteUncertain.Create(const AVerified: Boolean);
begin
  inherited Create
    ('TWN4 card write outcome or cleanup is uncertain; no automatic retry.');
  FVerified := AVerified;
end;

class function TTwn4Codec.EncodeAscii(const ACommand: TBytes;
  const AUseCrc: Boolean): TBytes;
const
  Digits = '0123456789ABCDEF';
var
  B: TBytes;
  I, N: Integer;
  C: Word;
begin
  if (Length(ACommand) < 2) or (Length(ACommand) > 256) then
    Fail;
  B := CopyBytes(ACommand);
  try
    if AUseCrc then
    begin
      C := Crc(B);
      N := Length(B);
      SetLength(B, N + 2);
      B[N] := Byte(C and $FF);
      B[N + 1] := Byte(C shr 8);
    end;
    Result := nil;
    SetLength(Result, Length(B) * 2 + 1);
    for I := 0 to Length(B) - 1 do
    begin
      Result[I * 2] := Ord(Digits[(B[I] shr 4) + 1]);
      Result[I * 2 + 1] := Ord(Digits[(B[I] and $0F) + 1]);
    end;
    Result[Length(Result) - 1] := 13;
  finally
    TCardCrypto.Clear(B);
  end;
end;

class function TTwn4Codec.DecodeAscii(const ALine: TBytes;
  const AUseCrc: Boolean): TBytes;
var
  I, N, V: Integer;
  B: TBytes;
  C: Word;
  function Digit(const Ch: Byte): Integer;
  begin
    case Ch of
      48 .. 57:
        Result := Ch - 48;
      65 .. 70:
        Result := Ch - 55;
      97 .. 102:
        Result := Ch - 87;
    else
      Fail;
      Result := 0;
    end;
  end;

begin
  N := Length(ALine);
  if (N < 3) or (N > 517) or (ALine[N - 1] <> 13) or ((N mod 2) <> 1) then
    Fail;
  B := nil;
  SetLength(B, (N - 1) div 2);
  for I := 0 to Length(B) - 1 do
  begin
    V := Digit(ALine[I * 2]) * 16 + Digit(ALine[I * 2 + 1]);
    B[I] := Byte(V);
  end;
  if AUseCrc then
  begin
    if Length(B) < 3 then
      Fail;
    N := Length(B) - 2;
    C := Word(B[N]) or (Word(B[N + 1]) shl 8);
    SetLength(B, N);
    if Crc(B) <> C then
      Fail;
  end;
  if (Length(B) > 256) or (B[0] <> 0) then
    Fail;
  Result := B;
end;

class function TTwn4Codec.DecodeTag(const AResponse: TBytes): TTwn4TagInfo;
var
  N: Integer;
begin
  Result := Default (TTwn4TagInfo);
  if (Length(AResponse) < 2) or (AResponse[0] <> 0) or (AResponse[1] > 1) then
    Fail;
  if AResponse[1] = 0 then
  begin
    if Length(AResponse) = 2 then
      Exit;
    if (Length(AResponse) <> 5) or (AResponse[2] <> 0) or (AResponse[3] <> 0) or
      (AResponse[4] <> 0) then
      Fail;
    Exit;
  end;
  if Length(AResponse) < 5 then
    Fail;
  N := AResponse[4];
  if (N < 1) or (N > 16) or (Length(AResponse) <> N + 5) or (AResponse[3] = 0)
    or (AResponse[3] > N * 8) or (AResponse[3] <= (N - 1) * 8) then
    Fail;
  Result.Found := True;
  Result.TagType := AResponse[2];
  Result.IdBitCount := AResponse[3];
  Result.Id := Copy(AResponse, 5, N);
end;

constructor TTwn4CardReaderWriter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimeoutMs := 3000;
end;

procedure TTwn4CardReaderWriter.RequireIdle;
begin
  if FBusy then
    Fail;
end;

procedure TTwn4CardReaderWriter.SetChannel(const AValue: ITwn4ByteChannel);
begin
  RequireIdle;
  FChannel := AValue;
end;

procedure TTwn4CardReaderWriter.SetTimeoutMs(const AValue: Cardinal);
begin
  RequireIdle;
  if (AValue < 1) or (AValue > 600000) then
    Fail;
  FTimeoutMs := AValue;
end;

procedure TTwn4CardReaderWriter.SetUseCrc(const AValue: Boolean);
begin
  RequireIdle;
  FUseCrc := AValue;
end;

procedure TTwn4CardReaderWriter.BeginOperation;
begin
  RequireIdle;
  if FChannel = nil then
    Fail;
  FBusy := True;
  FAcquired := False;
  try
    FStarted := FChannel.NowMs;
    FLastClock := FStarted;
    FChannel.Open;
    FAcquired := True;
  except
    FBusy := False;
    raise ETwn4Error.Create('TWN4 channel acquisition failed.');
  end;
end;

function TTwn4CardReaderWriter.Remaining: Cardinal;
var
  NowValue: UInt64;
begin
  NowValue := FChannel.NowMs;
  if (NowValue < FLastClock) or (NowValue - FStarted >= FTimeoutMs) then
    Fail;
  FLastClock := NowValue;
  Result := FTimeoutMs - Cardinal(NowValue - FStarted);
end;

function TTwn4CardReaderWriter.Command(const ARaw: TBytes): TBytes;
var
  Ignored: Boolean;
begin
  Ignored := False;
  Result := ExchangeCommand(ARaw, False, Ignored);
end;

function TTwn4CardReaderWriter.ExchangeCommand(const ARaw: TBytes;
  const ACardWrite: Boolean; var ADispatched: Boolean): TBytes;
var
  Wire, Line: TBytes;
  B: Byte;
  N: Integer;
  Budget: Cardinal;
begin
  Wire := nil;
  Line := nil;
  try
    Wire := TTwn4Codec.EncodeAscii(ARaw, FUseCrc);
    try
      Budget := Remaining;
      if ACardWrite then
        ADispatched := True;
      FChannel.Send(Wire, Budget);
      repeat
        B := FChannel.ReceiveByte(Remaining);
        N := Length(Line);
        if N >= 517 then
          Fail;
        SetLength(Line, N + 1);
        Line[N] := B;
      until B = 13;
      Result := TTwn4Codec.DecodeAscii(Line, FUseCrc);
    except
      on E: Exception do
        raise ETwn4Error.Create
          ('TWN4 command failed; response or transport is invalid.');
    end;
  finally
    TCardCrypto.Clear(Wire);
  end;
end;

procedure TTwn4CardReaderWriter.FinishOperation(const ASucceeded: Boolean);
var
  B: TBytes;
begin
  try
    if ASucceeded then
    begin
      try
        B := Command(HexToBytes('0501'));
        if Length(B) <> 1 then
          Fail;
      except
        if FAcquired then
          try
            FChannel.Close;
          except
          end;
        FAcquired := False;
        raise;
      end;
      try
        FChannel.Close;
      except
        raise ETwn4Error.Create('TWN4 channel cleanup failed.');
      end;
    end
    else if FAcquired then
      try
        FChannel.Close;
      except
      end;
  finally
    FAcquired := False;
    FBusy := False;
  end;
end;

function TTwn4CardReaderWriter.ReadVersion: string;
var
  B: TBytes;
  I: Integer;
  Success: Boolean;
begin
  BeginOperation;
  Success := False;
  try
    B := Command(HexToBytes('00047E'));
    if (Length(B) < 2) or ((B[1] = 0) or (B[1] > 126)) or (Length(B) <> 2 + B[1])
    then
      Fail;
    Result := '';
    SetLength(Result, B[1]);
    for I := 0 to Integer(B[1]) - 1 do
    begin
      if (B[I + 2] < 32) or (B[I + 2] > 126) then
        Fail;
      Result[I + 1] := Char(B[I + 2]);
    end;
    Success := True;
  finally
    FinishOperation(Success);
  end;
end;

function TTwn4CardReaderWriter.ReadTag: TTwn4TagInfo;
var
  Success: Boolean;
begin
  BeginOperation;
  Success := False;
  try
    Result := TTwn4Codec.DecodeTag(Command(HexToBytes('050010')));
    Success := True;
  finally
    FinishOperation(Success);
  end;
end;

procedure TTwn4CardReaderWriter.ValidateId(const AExpectedId: TBytes);
begin
  if not(Length(AExpectedId) in [4, 7, 10]) then
    Fail;
end;

procedure TTwn4CardReaderWriter.SelectExpected(const AExpectedId: TBytes);
var
  T: TTwn4TagInfo;
begin
  T := TTwn4Codec.DecodeTag(Command(HexToBytes('050010')));
  if not T.Found or (T.TagType <> $80) or
    (T.IdBitCount <> Length(AExpectedId) * 8) or
    not BytesEqual(T.Id, AExpectedId) then
    Fail;
end;

procedure TTwn4CardReaderWriter.ValidateClassic(const AModel
  : TMifareClassicModel; const ABlock: Integer; const AReaderSector: Byte;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
begin
  if (ABlock < 0) or (ABlock >= TMifareClassicLayout.BlockCount(AModel)) or
    (Length(AKey) <> 6) or not(AKeyType in [mckA, mckB]) then
    Fail;
  if (ABlock < 128) and (AReaderSector <> ABlock div 4) then
    Fail;
end;

procedure TTwn4CardReaderWriter.Login(const ASector: Byte;
  const AKeyType: TMifareClassicKeyType; const AKey: TBytes);
var
  B, R: TBytes;
begin
  B := HexToBytes('0B000000000000000000');
  try
    Move(AKey[0], B[2], 6);
    B[8] := Byte(Ord(AKeyType));
    B[9] := ASector;
    R := Command(B);
    if (Length(R) <> 2) or (R[1] <> 1) then
      Fail;
  finally
    TCardCrypto.Clear(B);
  end;
end;

function TTwn4CardReaderWriter.ReadData(const AClassic: Boolean;
  const AAddress: Byte): TBytes;
var
  B, R: TBytes;
begin
  if AClassic then
    B := HexToBytes('0B0100')
  else
    B := HexToBytes('0C0000');
  B[2] := AAddress;
  R := Command(B);
  if (Length(R) <> 18) or (R[1] <> 1) then
    Fail;
  if AClassic then
    Result := Copy(R, 2, 16)
  else
    Result := Copy(R, 2, 4);
end;

procedure TTwn4CardReaderWriter.WriteData(const AClassic: Boolean;
  const AAddress: Byte; const AData: TBytes; var ADispatched: Boolean);
var
  B, R: TBytes;
begin
  if AClassic then
    B := HexToBytes('0B0200')
  else
    B := HexToBytes('0C0100');
  B[2] := AAddress;
  SetLength(B, 3 + Length(AData));
  Move(AData[0], B[3], Length(AData));
  R := ExchangeCommand(B, True, ADispatched);
  if (Length(R) <> 2) or (R[1] <> 1) then
    Fail;
end;

function TTwn4CardReaderWriter.ClassicOperation(const AWrite: Boolean;
  const AModel: TMifareClassicModel; const ABlock: Integer;
  const AReaderSector: Byte; const AKeyType: TMifareClassicKeyType;
  const AKey, AExpectedId, AExpectedBefore, AData: TBytes): TBytes;
var
  Key, Id, Before, Data, Actual: TBytes;
  Success, Dispatched, Verified: Boolean;
begin
  RequireIdle;
  ValidateId(AExpectedId);
  ValidateClassic(AModel, ABlock, AReaderSector, AKeyType, AKey);
  if AWrite and ((ABlock = 0) or TMifareClassicLayout.IsTrailer(AModel, ABlock)
    or (Length(AExpectedBefore) <> 16) or (Length(AData) <> 16)) then
    Fail;
  Key := nil;
  try
    Key := CopyBytes(AKey);
    Id := CopyBytes(AExpectedId);
    Before := CopyBytes(AExpectedBefore);
    Data := CopyBytes(AData);
    BeginOperation;
    Success := False;
    Dispatched := False;
    Verified := False;
    try
      try
        SelectExpected(Id);
        Login(AReaderSector, AKeyType, Key);
        Actual := ReadData(True, Byte(ABlock));
        if AWrite then
        begin
          if not BytesEqual(Actual, Before) then
            Fail;
          if not BytesEqual(Before, Data) then
          begin
            // SearchTag may invalidate authentication: authenticate again after the final ID check.
            SelectExpected(Id);
            Login(AReaderSector, AKeyType, Key);
            Actual := ReadData(True, Byte(ABlock));
            if not BytesEqual(Actual, Before) then
              Fail;
            WriteData(True, Byte(ABlock), Data, Dispatched);
            Actual := ReadData(True, Byte(ABlock));
            if not BytesEqual(Actual, Data) then
              Fail;
          end;
          Verified := True;
        end;
        Result := Actual;
        Success := True;
      finally
        FinishOperation(Success);
      end;
    except
      on E: Exception do
      begin
        if Dispatched then
          raise ETwn4WriteUncertain.Create(Verified);
        raise;
      end;
    end;
  finally
    TCardCrypto.Clear(Key);
  end;
end;

function TTwn4CardReaderWriter.Type2Operation(const AWrite: Boolean;
  const AModel: TType2TagModel; const APage: Integer;
  const AExpectedId, AExpectedBefore, AData: TBytes): TBytes;
var
  Id, Before, Data, Actual: TBytes;
  Success, Dispatched, Verified: Boolean;
begin
  RequireIdle;
  if (Length(AExpectedId) <> 7) or not TType2Layout.IsUserPage(AModel, APage)
  then
    Fail;
  if AWrite and ((Length(AExpectedBefore) <> 4) or (Length(AData) <> 4)) then
    Fail;
  Id := CopyBytes(AExpectedId);
  Before := CopyBytes(AExpectedBefore);
  Data := CopyBytes(AData);
  BeginOperation;
  Success := False;
  Dispatched := False;
  Verified := False;
  try
    try
      SelectExpected(Id);
      Actual := ReadData(False, Byte(APage));
      if AWrite then
      begin
        if not BytesEqual(Actual, Before) then
          Fail;
        if not BytesEqual(Before, Data) then
        begin
          SelectExpected(Id);
          Actual := ReadData(False, Byte(APage));
          if not BytesEqual(Actual, Before) then
            Fail;
          WriteData(False, Byte(APage), Data, Dispatched);
          Actual := ReadData(False, Byte(APage));
          if not BytesEqual(Actual, Data) then
            Fail;
        end;
        Verified := True;
      end;
      Result := Actual;
      Success := True;
    finally
      FinishOperation(Success);
    end;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise ETwn4WriteUncertain.Create(Verified);
      raise;
    end;
  end;
end;

function TTwn4CardReaderWriter.ReadClassicBlock(const AModel
  : TMifareClassicModel; const ABlock: Integer; const AReaderSector: Byte;
  const AKeyType: TMifareClassicKeyType;
  const AKey, AExpectedId: TBytes): TBytes;
begin
  Result := ClassicOperation(False, AModel, ABlock, AReaderSector, AKeyType,
    AKey, AExpectedId, nil, nil);
end;

procedure TTwn4CardReaderWriter.WriteClassicDataBlock
  (const AModel: TMifareClassicModel; const ABlock: Integer;
  const AReaderSector: Byte; const AKeyType: TMifareClassicKeyType;
  const AKey, AExpectedId, AExpectedBefore, AData: TBytes);
begin
  ClassicOperation(True, AModel, ABlock, AReaderSector, AKeyType, AKey,
    AExpectedId, AExpectedBefore, AData);
end;

function TTwn4CardReaderWriter.ReadType2UserPage(const AModel: TType2TagModel;
  const APage: Integer; const AExpectedId: TBytes): TBytes;
begin
  Result := Type2Operation(False, AModel, APage, AExpectedId, nil, nil);
end;

procedure TTwn4CardReaderWriter.WriteType2UserPage(const AModel: TType2TagModel;
  const APage: Integer; const AExpectedId, AExpectedBefore, AData: TBytes);
begin
  Type2Operation(True, AModel, APage, AExpectedId, AExpectedBefore, AData);
end;

end.
