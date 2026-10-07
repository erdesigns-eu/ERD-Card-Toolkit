unit ERD.Card.Contactless.Raw;

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
  ERD.Card.Contactless, ERD.Card.Contactless.UID, ERD.Card.Contactless.UID.Profiles;

type
  /// <summary>One raw ISO 14443-A RF response; bytes include any card-supplied CRC.</summary>
  /// <remarks>Ordinary record assignment shares Data. A timeout is not a successful empty response.</remarks>
  TRawRfResponse = record
    /// <summary>Independent received bytes, least-significant bits first within a partial final byte.</summary>
    Data: TBytes;
    /// <summary>Total valid received bits; four-bit MIFARE acknowledgments are distinguishable from full bytes.</summary>
    BitCount: Integer;
    /// <summary>True only for a reader-reported RF response timeout; Data is empty and BitCount is zero.</summary>
    TimedOut: Boolean;
  end;
  /// <summary>Exclusive raw Type A reader session, independent of PC/SC storage pseudo-APDUs.</summary>
  /// <remarks>Implementations must send each frame once, retain RF selection between exchanges,
  /// disable automatic CRC insertion/removal and retries, and bound RF timeouts.
  /// Use on one caller thread without reentrancy. A failed BeginSession cleans up its own acquisition.</remarks>
  IRawContactlessReader = interface
    ['{5C583F91-6033-49CA-9AF7-730278A66079}']
    /// <summary>Acquires one exclusive session; does not program card memory.</summary>
    procedure BeginSession;
    /// <summary>Releases the session, clears temporary RF unlock state and restores framing; failure must still attempt exclusive-lock release.</summary>
    procedure EndSession;
    /// <summary>Cycles the RF field and performs fresh Type A selection without cached PC/SC UID data.</summary>
    /// <returns>Independent selected UID of four, seven or ten bytes.</returns>
    /// <remarks>Discards authentication/unlock state. Requires an active session and exactly one card in the field.</remarks>
    function Activate: TBytes;
    /// <summary>Transmits one explicitly framed RF message without CRC generation, retries or RF reset.</summary>
    /// <param name="AFrame">Nonempty caller-owned frame, including any required CRC-A bytes; never modified.</param>
    /// <param name="ABitCount">Valid outgoing bits, using all preceding bytes and one to eight bits in the final byte.</param>
    /// <returns>Independent raw response including CRC, partial-bit count and explicit RF timeout state.</returns>
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
  end;
  /// <summary>Explicit Classic-compatible volatile RF unlock dialect; never a fuse or permanent configuration change.</summary>
  TClassicRawUidProfile = (
    /// <summary>Reprogrammable four-byte Gen1a: seven-bit 40 followed by byte 43.</summary>
    crupGen1a,
    /// <summary>Unsealed four-byte UFUID using Gen1a wakeup; sealed variants fail instead of being unfused.</summary>
    crupUnsealedUfuid
  );
  /// <summary>Completed seven-byte DirectWrite Type 2 UID programming and fresh RF activation.</summary>
  /// <remarks>Ordinary record assignment shares arrays; the method returns independent copies.</remarks>
  TType2UidResult = record
    /// <summary>Independent original seven-byte UID verified against manufacturer pages.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested seven-byte UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent verified pages zero through three, including preserved internal, lock and OTP/CC bytes.</summary>
    ManufacturerPages: TBytes;
    /// <summary>True on every returned result: fresh RF selection reports RequestedUid.</summary>
    ActiveUidVerified: Boolean;
  end;
  /// <summary>Bounded raw Type A CRC and reprogrammable Type 2 manufacturer-page codecs.</summary>
  TRawUidCodec = class
  public
    /// <summary>Copies a frame and appends ISO 14443-A CRC, least-significant byte first.</summary>
    /// <param name="AData">Zero to 253 caller-owned payload bytes.</param>
    /// <returns>Independent payload followed by two CRC-A bytes.</returns>
    /// <exception cref="EContactlessError">Input exceeds the supported frame limit.</exception>
    class function AppendCrcA(const AData: TBytes): TBytes; static;
    /// <summary>Validates and removes CRC-A from an exact full-byte response.</summary>
    /// <param name="AResponse">Non-timeout response including two CRC bytes.</param>
    /// <param name="ADataSize">Required payload size, zero to 253 bytes.</param>
    /// <returns>Independent payload after length, framing and CRC validation.</returns>
    /// <exception cref="EContactlessError">Size, framing, timeout or CRC is invalid.</exception>
    class function DecodeCrcA(const AResponse: TRawRfResponse; const ADataSize: Integer): TBytes; static;
    /// <summary>Validates Type 2 manufacturer-page BCC values and copies the seven-byte UID.</summary>
    /// <param name="APages">Exactly sixteen bytes from pages zero through three.</param>
    /// <returns>Independent UID assembled from page zero and page one.</returns>
    /// <exception cref="EProgrammableUidError">Size, cascade position or either BCC is invalid.</exception>
    class function DecodeType2Uid(const APages: TBytes): TBytes; static;
    /// <summary>Replaces a Type 2 UID and both BCC bytes while preserving every other byte.</summary>
    /// <param name="APages">Existing sixteen-byte manufacturer-page snapshot with valid BCC values.</param>
    /// <param name="ANewUid">Exactly seven caller-owned UID bytes.</param>
    /// <returns>Independent sixteen-byte pages; bytes nine through fifteen remain unchanged.</returns>
    /// <exception cref="EProgrammableUidError">Existing pages or requested UID are invalid.</exception>
    class function PrepareType2Pages(const APages, ANewUid: TBytes): TBytes; static;
  end;
  /// <summary>Nonvisual UID programmer for caller-identified reprogrammable raw-RF card profiles.</summary>
  /// <remarks>No automatic card detection, key discovery, fusing, wiping or rollback.
  /// Ordinary production cards and write-once variants are not covered. Requires one card in the field.</remarks>
  TRawUidProgrammer = class(TComponent)
  private
    FReader: IRawContactlessReader;
    procedure RequireReader;
    procedure ReleaseSession(const ASucceeded: Boolean);
    procedure RequireAck(const AResponse: TRawRfResponse);
    procedure UnlockClassic;
    function ReadManufacturer: TBytes;
    procedure CheckActivation(const ARequestedUid: TBytes);
    procedure RequireStatus9000(const AResponse: TRawRfResponse);
    function ExchangeGen4(const APassword: TBytes; const ACommand: Byte; const AData: TBytes;
      var AWriteDispatched: Boolean): TRawRfResponse;
    function ReadGen4Configuration(const APassword: TBytes): TBytes;
    function ReadGen4Blocks(const ALayout: TGen4UidLayout; const APassword: TBytes): TUidManufacturerBlocks;
  public
    /// <summary>Programs a four-byte UID using Gen1a or unsealed UFUID volatile unlock.</summary>
    /// <param name="AProfile">Caller-identified reprogrammable Gen1a or unsealed UFUID dialect.</param>
    /// <param name="ANewUid">Exactly four bytes; copied without modification.</param>
    /// <returns>Independent block/UID snapshot after full read-back, fresh selection and successful release.</returns>
    /// <exception cref="EProgrammableUidError">Requested UID is invalid.</exception>
    /// <exception cref="EContactlessError">Configuration, unlock or original UID/block is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">A write handshake was dispatched and completion cannot be verified.</exception>
    /// <remarks>Preserves bytes five through fifteen; never sends wipe, seal or permanent lock commands.
    /// A matching UID is a verified no-op. Any failure after the write handshake is uncertain; never blindly retry.</remarks>
    function ProgramClassicUid(const AProfile: TClassicRawUidProfile; const ANewUid: TBytes): TProgrammableUidResult;
    /// <summary>Programs a seven-byte UID on an explicitly identified reprogrammable Type 2 DirectWrite variant.</summary>
    /// <param name="ANewUid">Exactly seven bytes; copied without modification.</param>
    /// <returns>Independent manufacturer pages and UIDs after read-back, fresh selection and successful release.</returns>
    /// <exception cref="EProgrammableUidError">Requested UID or existing manufacturer pages are invalid.</exception>
    /// <exception cref="EContactlessError">Reader or original UID/page consistency is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any manufacturer-page write was dispatched and completion cannot be verified.</exception>
    /// <remarks>Writes pages zero, one and two in one retained RF session; preserves lock/internal/OTP/CC bytes.
    /// Multi-page writes are not atomic. Partial programming requires inspection and recovery, never automatic replay.</remarks>
    function ProgramType2DirectWriteUid(const ANewUid: TBytes): TType2UidResult;
    /// <summary>Programs an independent four/seven-byte Gen3 UID register without writing manufacturer block zero.</summary>
    /// <param name="ASize">Caller-identified existing four-byte or seven-byte Gen3 register.</param>
    /// <param name="ANewUid">Requested UID copied without modification.</param>
    /// <returns>Independent identifiers and unchanged manufacturer block after fresh selection and successful release.</returns>
    /// <exception cref="EProgrammableUidError">Size, UID length or cascade position is invalid.</exception>
    /// <exception cref="EContactlessError">Reader, original selection or manufacturer read is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">UID command was dispatched and completion could not be verified.</exception>
    /// <remarks>Raw backend must allow at least two seconds for response. After accepted writing, waits one second
    /// for card memory reset before fresh activation. No freeze or block-write command; old block UID may differ from RF UID.</remarks>
    function ProgramGen3Uid(const ASize: TGen3UidSize; const ANewUid: TBytes): TGen3UidResult;
    /// <summary>Programs a UID on an already configured Gen4 UMC Classic/Type 2 four/seven/ten-byte variant.</summary>
    /// <param name="ALayout">Existing configured emulation layout; does not change card protocol or UID length.</param>
    /// <param name="ANewUid">Requested UID copied without modification.</param>
    /// <param name="APassword">Exactly four supplied backdoor-password bytes; never guessed, retained or modified.</param>
    /// <returns>Independent full manufacturer blocks and identifiers after fresh activation, stable configuration and successful release.</returns>
    /// <exception cref="EProgrammableUidError">Layout, UID, password size, configuration or original manufacturer data is invalid.</exception>
    /// <exception cref="EContactlessError">Reader or original RF UID/block consistency is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any manufacturer-block write was dispatched and completion could not be verified.</exception>
    /// <remarks>Requires stable GTU mode 02 and a raw backend allowing at least one second for response without automatic RATS.
    /// Preserves configuration, metadata, internal/lock bytes and hidden block tails. Split Type 2 writes are not atomic.
    /// Local password-bearing commands/configuration are overwritten on all exits; backend/transport copies are outside that guarantee.</remarks>
    function ProgramGen4Uid(const ALayout: TGen4UidLayout; const ANewUid, APassword: TBytes): TGen4UidResult;
    /// <summary>Retained raw-reader interface; caller configures an adapter matching the hardware before any operation.</summary>
    property Reader: IRawContactlessReader read FReader write FReader;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EContactlessError.Create('Raw UID operation failed: ' + AReason + '.');
end;

procedure TRawUidProgrammer.RequireStatus9000(const AResponse: TRawRfResponse);
var Data: TBytes;
begin
  Data := TRawUidCodec.DecodeCrcA(AResponse, 2);
  if (Data[0] <> $90) or (Data[1] <> 0) then Fail('card rejected UID command');
end;

function TRawUidProgrammer.ExchangeGen4(const APassword: TBytes; const ACommand: Byte;
  const AData: TBytes; var AWriteDispatched: Boolean): TRawRfResponse;
var Payload, Wire: TBytes;
begin
  SetLength(Payload, 6 + Length(AData));
  try
    Payload[0] := $CF;
    Move(APassword[0], Payload[1], 4);
    Payload[5] := ACommand;
    if Length(AData) > 0 then Move(AData[0], Payload[6], Length(AData));
    Wire := TRawUidCodec.AppendCrcA(Payload);
  finally FillChar(Payload[0], Length(Payload), 0); end;
  try
    if ACommand = $CD then AWriteDispatched := True;
    Result := FReader.Exchange(Wire, Length(Wire) * 8);
  finally FillChar(Wire[0], Length(Wire), 0); end;
end;

function TRawUidProgrammer.ReadGen4Configuration(const APassword: TBytes): TBytes;
var Response: TRawRfResponse; Size: Integer; Dispatched: Boolean;
begin
  Result := nil;
  Dispatched := False;
  Response := ExchangeGen4(APassword, $C6, nil, Dispatched);
  try
    Size := Length(Response.Data) - 2;
    if not (Size in [30, 32]) then Fail('unsupported Gen4 configuration response');
    Result := TRawUidCodec.DecodeCrcA(Response, Size);
  finally if Length(Response.Data) > 0 then FillChar(Response.Data[0], Length(Response.Data), 0); end;
end;

function TRawUidProgrammer.ReadGen4Blocks(const ALayout: TGen4UidLayout;
  const APassword: TBytes): TUidManufacturerBlocks;
var Data: TBytes; I: Integer; Dispatched: Boolean;
begin
  Result := nil;
  SetLength(Result, TGen4UidCodec.ManufacturerBlockCount(ALayout));
  SetLength(Data, 1);
  Dispatched := False;
  for I := 0 to Length(Result) - 1 do
  begin
    Data[0] := Byte(I);
    Result[I] := TRawUidCodec.DecodeCrcA(ExchangeGen4(APassword, $CE, Data, Dispatched), 16);
  end;
end;

function TRawUidProgrammer.ProgramGen3Uid(const ASize: TGen3UidSize; const ANewUid: TBytes): TGen3UidResult;
var Data: TGen3UidResult; Wire, Verified: TBytes; Succeeded, Dispatched: Boolean;
begin
  Result := Default(TGen3UidResult);
  Wire := TRawUidCodec.AppendCrcA(TGen3UidCodec.BuildUidCommand(ASize, ANewUid));
  RequireReader;
  Data := Default(TGen3UidResult);
  Data.UidSize := ASize;
  Data.RequestedUid := CopyBytes(ANewUid);
  Succeeded := False;
  Dispatched := False;
  FReader.BeginSession;
  try
    try
      Data.PreviousUid := FReader.Activate;
      if Length(Data.PreviousUid) <> TGen3UidCodec.UidLength(ASize) then Fail('Gen3 original UID size mismatch');
      Data.ManufacturerBlock := ReadManufacturer;
      // The Gen3 UID register is independent; never require it to match the embedded block-zero UID.
      if not BytesEqual(Data.PreviousUid, Data.RequestedUid) then
      begin
        Dispatched := True;
        RequireStatus9000(FReader.Exchange(Wire, Length(Wire) * 8));
        TThread.Sleep(1000);
        CheckActivation(Data.RequestedUid);
        Verified := ReadManufacturer;
        if not BytesEqual(Verified, Data.ManufacturerBlock) then Fail('Gen3 manufacturer block changed');
      end;
      Data.ActiveUidVerified := True;
      Succeeded := True;
    finally ReleaseSession(Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

function TRawUidProgrammer.ProgramGen4Uid(const ALayout: TGen4UidLayout;
  const ANewUid, APassword: TBytes): TGen4UidResult;
var Data: TGen4UidResult; Original, Verified: TUidManufacturerBlocks;
  Config, NewConfig, OriginalUid, WriteData: TBytes; I: Integer; Succeeded, Dispatched: Boolean;
begin
  Result := Default(TGen4UidResult);
  TGen4UidCodec.ValidateUid(ALayout, ANewUid);
  if Length(APassword) <> 4 then raise EProgrammableUidError.Create('Invalid Gen4 password size.');
  RequireReader;
  Data := Default(TGen4UidResult);
  Data.Layout := ALayout;
  Data.RequestedUid := CopyBytes(ANewUid);
  Succeeded := False;
  Dispatched := False;
  FReader.BeginSession;
  try
    try
      try
        Data.PreviousUid := FReader.Activate;
        if Length(Data.PreviousUid) <> TGen4UidCodec.UidLength(ALayout) then Fail('Gen4 original UID size mismatch');
        Config := ReadGen4Configuration(APassword);
        TGen4UidCodec.ValidateConfiguration(ALayout, Config);
        Original := ReadGen4Blocks(ALayout, APassword);
        OriginalUid := TGen4UidCodec.DecodeUid(ALayout, Original);
        if not BytesEqual(OriginalUid, Data.PreviousUid) then Fail('Gen4 original RF UID/block mismatch');
        if not BytesEqual(Data.PreviousUid, Data.RequestedUid) then
        begin
          Data.ManufacturerBlocks := TGen4UidCodec.PrepareBlocks(ALayout, Original, Data.RequestedUid);
          for I := 0 to Length(Data.ManufacturerBlocks) - 1 do
          begin
            SetLength(WriteData, 17);
            WriteData[0] := Byte(I);
            Move(Data.ManufacturerBlocks[I][0], WriteData[1], 16);
            RequireStatus9000(ExchangeGen4(APassword, $CD, WriteData, Dispatched));
          end;
          // Verify persistent data after reactivation, not a transient shadow view.
          CheckActivation(Data.RequestedUid);
          NewConfig := ReadGen4Configuration(APassword);
          if not BytesEqual(Config, NewConfig) then Fail('Gen4 configuration changed');
          Verified := ReadGen4Blocks(ALayout, APassword);
          for I := 0 to Length(Verified) - 1 do
            if not BytesEqual(Verified[I], Data.ManufacturerBlocks[I]) then Fail('Gen4 manufacturer read-back mismatch');
        end
        else
        begin
          SetLength(Data.ManufacturerBlocks, Length(Original));
          for I := 0 to Length(Original) - 1 do Data.ManufacturerBlocks[I] := CopyBytes(Original[I]);
        end;
        Data.ActiveUidVerified := True;
        Succeeded := True;
      finally
        if Length(Config) > 0 then FillChar(Config[0], Length(Config), 0);
        if Length(NewConfig) > 0 then FillChar(NewConfig[0], Length(NewConfig), 0);
      end;
    finally ReleaseSession(Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

function CrcA(const AData: TBytes): Word;
var I, J: Integer; Value: Cardinal;
begin
  Value := $6363;
  for I := 0 to Length(AData) - 1 do
  begin
    Value := Value xor AData[I];
    for J := 1 to 8 do
      if (Value and 1) <> 0 then Value := (Value shr 1) xor $8408
      else Value := Value shr 1;
  end;
  Result := Word(Value);
end;

class function TRawUidCodec.AppendCrcA(const AData: TBytes): TBytes;
var Crc: Word; Size: Integer;
begin
  Size := Length(AData);
  if Size > 253 then Fail('frame exceeds limit');
  Crc := CrcA(AData);
  Result := CopyBytes(AData);
  SetLength(Result, Size + 2);
  Result[Size] := Byte(Crc and $FF);
  Result[Size + 1] := Byte(Crc shr 8);
end;

class function TRawUidCodec.DecodeCrcA(const AResponse: TRawRfResponse; const ADataSize: Integer): TBytes;
var Data, Expected: TBytes;
begin
  Result := nil;
  if (ADataSize < 0) or (ADataSize > 253) then Fail('invalid response size');
  if AResponse.TimedOut or (Length(AResponse.Data) <> ADataSize + 2) or
    (AResponse.BitCount <> (ADataSize + 2) * 8) then Fail('invalid response framing');
  Data := Copy(AResponse.Data, 0, ADataSize);
  try
    Expected := AppendCrcA(Data);
    if not BytesEqual(Expected, AResponse.Data) then Fail('response CRC mismatch');
    Result := Data;
  finally
    if Length(Expected) > 0 then FillChar(Expected[0], Length(Expected), 0);
    if (Length(Result) = 0) and (Length(Data) > 0) then FillChar(Data[0], Length(Data), 0);
  end;
end;

class function TRawUidCodec.DecodeType2Uid(const APages: TBytes): TBytes;
begin
  Result := nil;
  if Length(APages) <> 16 then raise EProgrammableUidError.Create('Invalid Type 2 manufacturer-page size.');
  if (($88 xor APages[0] xor APages[1] xor APages[2]) <> APages[3]) or
    ((APages[4] xor APages[5] xor APages[6] xor APages[7]) <> APages[8]) then
    raise EProgrammableUidError.Create('Invalid Type 2 manufacturer-page checksum.');
  SetLength(Result, 7);
  Move(APages[0], Result[0], 3);
  Move(APages[4], Result[3], 4);
  TProgrammableUidCodec.ValidateUid(cgum7Byte, Result);
end;

class function TRawUidCodec.PrepareType2Pages(const APages, ANewUid: TBytes): TBytes;
var Previous: TBytes;
begin
  TProgrammableUidCodec.ValidateUid(cgum7Byte, ANewUid);
  Previous := DecodeType2Uid(APages);
  if Length(Previous) <> 7 then Fail('invalid manufacturer UID');
  Result := CopyBytes(APages);
  Move(ANewUid[0], Result[0], 3);
  Result[3] := $88 xor ANewUid[0] xor ANewUid[1] xor ANewUid[2];
  Move(ANewUid[3], Result[4], 4);
  Result[8] := ANewUid[3] xor ANewUid[4] xor ANewUid[5] xor ANewUid[6];
end;

procedure TRawUidProgrammer.RequireReader;
begin
  if FReader = nil then Fail('raw reader missing');
end;

procedure TRawUidProgrammer.ReleaseSession(const ASucceeded: Boolean);
begin
  if ASucceeded then FReader.EndSession
  else
    try FReader.EndSession;
    except
      // Preserve the primary operation failure; the adapter must still release exclusivity.
    end;
end;

procedure TRawUidProgrammer.RequireAck(const AResponse: TRawRfResponse);
begin
  if AResponse.TimedOut or (AResponse.BitCount <> 4) or (Length(AResponse.Data) <> 1) then
    Fail('missing four-bit acknowledgment');
  if (AResponse.Data[0] and $0F) <> $0A then Fail('card rejected command');
end;

procedure TRawUidProgrammer.UnlockClassic;
var Wire: TBytes; Response: TRawRfResponse;
begin
  Wire := TRawUidCodec.AppendCrcA(HexToBytes('5000'));
  Response := FReader.Exchange(Wire, Length(Wire) * 8);
  if not Response.TimedOut or (Length(Response.Data) <> 0) or (Response.BitCount <> 0) then
    Fail('HALT did not report expected RF timeout');
  RequireAck(FReader.Exchange(HexToBytes('40'), 7));
  RequireAck(FReader.Exchange(HexToBytes('43'), 8));
end;

function TRawUidProgrammer.ReadManufacturer: TBytes;
var Wire: TBytes;
begin
  Wire := TRawUidCodec.AppendCrcA(HexToBytes('3000'));
  Result := TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire, Length(Wire) * 8), 16);
end;

procedure TRawUidProgrammer.CheckActivation(const ARequestedUid: TBytes);
var ActiveUid: TBytes;
begin
  ActiveUid := FReader.Activate;
  if not BytesEqual(ActiveUid, ARequestedUid) then Fail('fresh RF UID mismatch');
end;

function TRawUidProgrammer.ProgramClassicUid(const AProfile: TClassicRawUidProfile;
  const ANewUid: TBytes): TProgrammableUidResult;
var Data: TProgrammableUidResult; OldBlock, OldUid, Verified, Wire: TBytes;
  Succeeded, Dispatched: Boolean;
begin
  Result := Default(TProgrammableUidResult);
  if not (AProfile in [crupGen1a, crupUnsealedUfuid]) then Fail('invalid Classic raw profile');
  TProgrammableUidCodec.ValidateUid(cgum4Byte, ANewUid);
  RequireReader;
  Data := Default(TProgrammableUidResult);
  Data.Model := cgum4Byte;
  Data.RequestedUid := CopyBytes(ANewUid);
  Succeeded := False;
  Dispatched := False;
  FReader.BeginSession;
  try
    try
      Data.PreviousUid := FReader.Activate;
      if Length(Data.PreviousUid) <> 4 then Fail('current UID is not four bytes');
      UnlockClassic;
      OldBlock := ReadManufacturer;
      OldUid := TProgrammableUidCodec.DecodeGen2Uid(cgum4Byte, OldBlock);
      if not BytesEqual(OldUid, Data.PreviousUid) then Fail('original UID/block mismatch');
      Data.ManufacturerBlock := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, OldBlock, Data.RequestedUid);
      if not BytesEqual(Data.PreviousUid, Data.RequestedUid) then
      begin
        Wire := TRawUidCodec.AppendCrcA(HexToBytes('A000'));
        Dispatched := True;
        RequireAck(FReader.Exchange(Wire, Length(Wire) * 8));
        Wire := TRawUidCodec.AppendCrcA(Data.ManufacturerBlock);
        RequireAck(FReader.Exchange(Wire, Length(Wire) * 8));
        Verified := ReadManufacturer;
        if not BytesEqual(Verified, Data.ManufacturerBlock) then Fail('manufacturer read-back mismatch');
        CheckActivation(Data.RequestedUid);
      end;
      Data.ActiveUidVerified := True;
      Succeeded := True;
    finally ReleaseSession(Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

function TRawUidProgrammer.ProgramType2DirectWriteUid(const ANewUid: TBytes): TType2UidResult;
var Data: TType2UidResult; OldPages, OldUid, Verified, Wire: TBytes;
  Succeeded, Dispatched: Boolean; Page: Integer;
begin
  Result := Default(TType2UidResult);
  TProgrammableUidCodec.ValidateUid(cgum7Byte, ANewUid);
  RequireReader;
  Data := Default(TType2UidResult);
  Data.RequestedUid := CopyBytes(ANewUid);
  Succeeded := False;
  Dispatched := False;
  FReader.BeginSession;
  try
    try
      Data.PreviousUid := FReader.Activate;
      if Length(Data.PreviousUid) <> 7 then Fail('current UID is not seven bytes');
      OldPages := ReadManufacturer;
      OldUid := TRawUidCodec.DecodeType2Uid(OldPages);
      if not BytesEqual(OldUid, Data.PreviousUid) then Fail('original UID/pages mismatch');
      Data.ManufacturerPages := TRawUidCodec.PrepareType2Pages(OldPages, Data.RequestedUid);
      if not BytesEqual(Data.PreviousUid, Data.RequestedUid) then
      begin
        for Page := 0 to 2 do
        begin
          SetLength(Wire, 6);
          Wire[0] := $A2;
          Wire[1] := Byte(Page);
          Move(Data.ManufacturerPages[Page * 4], Wire[2], 4);
          Wire := TRawUidCodec.AppendCrcA(Wire);
          Dispatched := True;
          RequireAck(FReader.Exchange(Wire, Length(Wire) * 8));
        end;
        Verified := ReadManufacturer;
        if not BytesEqual(Verified, Data.ManufacturerPages) then Fail('manufacturer-page read-back mismatch');
        CheckActivation(Data.RequestedUid);
      end;
      Data.ActiveUidVerified := True;
      Succeeded := True;
    finally ReleaseSession(Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
  Result := Data;
end;

end.
