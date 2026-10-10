unit ERD.Card.MagStripe.MSR2067HL;

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
  ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe.Serial;

type
  /// <summary>Pure bounded USI1 framing for MSR206-7HL PM036 Rev F.</summary>
  /// <remarks>Not the ESC command family of MSR206/MSR605. Seven-bit payload, STX/ETX/XOR BCC.</remarks>
  TMsr2067HLCodec = class
  public
    /// <summary>Frames one nonempty seven-bit USI1 message.</summary>
    /// <param name="AMessage">1..105 bytes without STX or ETX; EOT is allowed for data loading.</param>
    /// <returns>Independent STX/message/ETX/BCC bytes; BCC includes STX and ETX.</returns>
    /// <exception cref="EMagStripeError">Length or payload is invalid.</exception>
    class function Encode(const AMessage: TBytes): TBytes; static;
    /// <summary>Validates and strips one complete USI1 frame.</summary>
    /// <param name="AFrame">Exactly one bounded frame; no trailing bytes or resynchronization.</param>
    /// <returns>Independent message after length, seven-bit data and XOR validation.</returns>
    /// <exception cref="EMagStripeError">Frame or checksum is invalid.</exception>
    class function Decode(const AFrame: TBytes): TBytes; static;
    /// <summary>Validates a decoded ISO track response, without physical sentinels or LRC.</summary>
    /// <param name="ATrack">Physical track using its standard ISO format.</param>
    /// <param name="AMessage">Bounded nonempty decoded message; singleton plus means no data.</param>
    /// <returns>Unframed payload, or empty for the documented no-data response.</returns>
    /// <exception cref="EMagStripeError">Device error, ambiguous singleton error byte or invalid length.</exception>
    /// <exception cref="EMagStripeFormatError">Returned ISO payload is invalid.</exception>
    /// <remarks>Singleton error characters cannot be distinguished from literal Track 1 payloads;
    /// they are handled as status, never accepted as successful card contents.</remarks>
    class function DecodeTrack(const ATrack: TMagStripeTrack;
      const AMessage: TBytes): string; static;
  end;

  /// <summary>Three-track MSR206-7HL reader and same-swipe verified writer, PM036 Rev F.</summary>
  /// <remarks>Inactive constructor, exclusive injected channel, default 9600/7O1. Warm reset initializes
  /// USI0; commands then explicitly select USI1. Only loaded tracks are written, preserving other tracks.
  /// Write uses @ RAW verification and retrieves the same swipe's read buffers without rearming.
  /// One total deadline; failed sessions are poisoned until release. No replay or EEPROM modification.</remarks>
  TMsr2067HLMagStripeAdapter = class(TInterfacedObject, IMagStripeDevice)
  private
    FPort: IMagStripeSerialPort;
    FAcquired, FBusy, FPoisoned, FNeedsReset: Boolean;
    FStarted, FLastByteAt: UInt64;
    FTimeoutMs: Cardinal;
    procedure BeginIo(const ATracks: TMagStripeTrackSet;
      const ATimeoutMs: Cardinal);
    function Remaining: Cardinal;
    procedure SendMessage(const AMessage: TBytes);
    function ReceiveMessage: TBytes;
    function ReceiveFirst: Byte;
    function ReceiveContinuation: Byte;
    procedure ExpectAck;
    procedure CommandAck(const ACommand: Byte);
    procedure Prepare;
    procedure SetCoercivity(const ACoercivity: TMagStripeCoercivity);
    function ReadBuffers(const ATracks: TMagStripeTrackSet): TMagStripeTracks;
  public
    /// <summary>Creates an inactive explicit MSR206-7HL three-track adapter.</summary>
    /// <param name="APort">Retained exclusive channel configured to match the reader, normally 9600/7O1.</param>
    /// <exception cref="EMagStripeError">Channel is nil.</exception>
    constructor Create(const APort: IMagStripeSerialPort);
    /// <summary>Best-effort resets and closes an acquired channel; suppresses cleanup exceptions.</summary>
    /// <remarks>Explicit Release reports errors.</remarks>
    destructor Destroy; override;
    /// <summary>Reports all three read/write tracks and independently verified writing.</summary>
    /// <returns>All nonempty track combinations, explicit low/high coercivity, VerifiedWrite=true.</returns>
    /// <remarks>Requires the documented three-track VC hardware; configuration/current is checked before arming.</remarks>
    function GetCapabilities: TMagStripeCapabilities;
    /// <summary>Opens the retained port once; failed opening grants no ownership.</summary>
    procedure Acquire;
    /// <summary>Sends one unframed warm reset if commands were sent, then closes exactly once.</summary>
    /// <remarks>Separate 500 ms send budget; reset report is not awaited. Host transmission alone does
    /// not prove device cancellation. Always clears ownership, preserving reset failure over close failure.</remarks>
    procedure Release;
    /// <summary>Resets, confirms configuration and reads one physical swipe using USI1.</summary>
    /// <param name="ATracks">Nonempty requested physical tracks; others return empty.</param>
    /// <param name="ATimeoutMs">Total protocol budget including reset and swipe wait, 1..600000 ms.</param>
    /// <returns>Independent unframed payloads after device ISO integrity checks.</returns>
    /// <exception cref="EMagStripeError">State, protocol, configuration, deadline or device status fails.</exception>
    /// <exception cref="EMagStripeFormatError">A returned selected payload is invalid.</exception>
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal)
      : TMagStripeTracks;
    /// <summary>Programs selected tracks once and compares independently acquired same-swipe buffers.</summary>
    /// <param name="ATracks">Any nonempty physical combination; unselected tracks remain untouched.</param>
    /// <param name="AData">Nonempty selected unframed payloads, empty unselected entries; not retained.</param>
    /// <param name="ACoercivity">Explicit low (036) or high (255) temporary VC current; current setting is refused.</param>
    /// <param name="ATimeoutMs">Shared total budget including setup, loading, swipe and read-back, 1..600000 ms.</param>
    /// <returns>Selected independently acquired payloads only after RAW status and exact comparison succeed.</returns>
    /// <exception cref="EMagStripeError">Preflight or setup fails before arm dispatch.</exception>
    /// <exception cref="EMagStripeFormatError">Input is invalid before I/O.</exception>
    /// <exception cref="EMagStripeWriteUncertain">Arm dispatch, RAW result or acquired read-back fails; never replay.</exception>
    /// <remarks>Standard ISO-length media only. Current recommendations are device settings, not measurements
    /// of card coercivity. No second swipe, no input echo, no permanent default-current write.</remarks>
    function Write(const ATracks: TMagStripeTrackSet;
      const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
      const ATimeoutMs: Cardinal): TMagStripeTracks;
  end;

implementation

procedure ProtocolError;
begin
  raise EMagStripeError.Create('Invalid or unsupported MSR206-7HL response.');
end;

function One(const AValue: Byte): TBytes;
begin
  Result := nil;
  SetLength(Result, 1);
  Result[0] := AValue;
end;

function IsErrorByte(const AValue: Byte): Boolean;
begin
  Result := AValue in [$21, $2A, $2B, $2D, $2F, $3F, $7E];
end;

class function TMsr2067HLCodec.Encode(const AMessage: TBytes): TBytes;
var
  I: Integer;
  Bcc: Byte;
begin
  Result := nil;
  if (Length(AMessage) < 1) or (Length(AMessage) > 105) then
    ProtocolError;
  SetLength(Result, Length(AMessage) + 3);
  Result[0] := 2;
  Bcc := 2 xor 3;
  for I := 0 to High(AMessage) do
  begin
    if (AMessage[I] > $7F) or (AMessage[I] in [2, 3]) then
      ProtocolError;
    Result[I + 1] := AMessage[I];
    Bcc := Bcc xor AMessage[I];
  end;
  Result[Length(Result) - 2] := 3;
  Result[High(Result)] := Bcc;
end;

class function TMsr2067HLCodec.Decode(const AFrame: TBytes): TBytes;
var
  I: Integer;
  Bcc: Byte;
begin
  Result := nil;
  if (Length(AFrame) < 4) or (Length(AFrame) > 108) then
    ProtocolError;
  if (AFrame[0] <> 2) or (AFrame[Length(AFrame) - 2] <> 3) then
    ProtocolError;
  Bcc := 0;
  for I := 0 to High(AFrame) do
  begin
    if AFrame[I] > $7F then
      ProtocolError;
    if (I > 0) and (I < Length(AFrame) - 2) and (AFrame[I] in [2, 3]) then
      ProtocolError;
    Bcc := Bcc xor AFrame[I];
  end;
  if Bcc <> 0 then
    ProtocolError;
  Result := Copy(AFrame, 1, Length(AFrame) - 3);
end;

class function TMsr2067HLCodec.DecodeTrack(const ATrack: TMagStripeTrack;
  const AMessage: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  if (Length(AMessage) < 1) or
    (Length(AMessage) > TMagStripeTrackCodec.MaxPayloadLength(ATrack)) then
    ProtocolError;
  if (Length(AMessage) = 1) and IsErrorByte(AMessage[0]) then
  begin
    if AMessage[0] = $2B then
      Exit;
    ProtocolError;
  end;
  SetLength(Result, Length(AMessage));
  for I := 0 to High(AMessage) do
    Result[I + 1] := Char(AMessage[I]);
  TMagStripeTrackCodec.ValidatePayload(ATrack, Result);
end;

constructor TMsr2067HLMagStripeAdapter.Create(const APort
  : IMagStripeSerialPort);
begin
  inherited Create;
  if APort = nil then
    raise EMagStripeError.Create
      ('An explicit MSR206-7HL serial channel is required.');
  FPort := APort;
end;

destructor TMsr2067HLMagStripeAdapter.Destroy;
begin
  if FAcquired then
    try
      Release;
    except { Explicit release reports failures. } end;
  inherited Destroy;
end;

function TMsr2067HLMagStripeAdapter.GetCapabilities: TMagStripeCapabilities;
begin
  Result.ReadTracks := [mstTrack1, mstTrack2, mstTrack3];
  Result.WriteTracks := Result.ReadTracks;
  Result.Coercivities := [mscLow, mscHigh];
  Result.VerifiedWrite := True;
end;

procedure TMsr2067HLMagStripeAdapter.Acquire;
begin
  if FAcquired or FBusy then
    raise EMagStripeError.Create('MSR206-7HL session is already acquired.');
  FPort.Open;
  FAcquired := True;
  FPoisoned := False;
  FNeedsReset := False;
end;

procedure TMsr2067HLMagStripeAdapter.Release;
var
  B: TBytes;
  Succeeded: Boolean;
begin
  if not FAcquired or FBusy then
    raise EMagStripeError.Create
      ('MSR206-7HL cannot be released in this state.');
  Succeeded := False;
  try
    try
      if FNeedsReset then
      begin
        B := One($7F);
        FPort.Send(B, 500);
      end;
      Succeeded := True;
    finally
      if Succeeded then
        FPort.Close
      else
        try
          FPort.Close;
        except { Preserve primary reset failure. } end;
    end;
  finally
    FAcquired := False;
    FPoisoned := False;
    FNeedsReset := False;
  end;
end;

procedure TMsr2067HLMagStripeAdapter.BeginIo(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal);
begin
  if not FAcquired or FBusy or FPoisoned or (ATracks = []) or (ATimeoutMs < 1)
    or (ATimeoutMs > 600000) then
    raise EMagStripeError.Create
      ('Invalid MSR206-7HL session, selection or deadline.');
  FStarted := FPort.NowMs;
  FTimeoutMs := ATimeoutMs;
  FBusy := True;
end;

function TMsr2067HLMagStripeAdapter.Remaining: Cardinal;
var
  Now, Elapsed: UInt64;
begin
  Now := FPort.NowMs;
  if Now < FStarted then
    raise EMagStripeError.Create('Serial clock moved backwards.');
  Elapsed := Now - FStarted;
  if Elapsed >= FTimeoutMs then
    raise EMagStripeError.Create('MSR206-7HL operation deadline expired.');
  Result := FTimeoutMs - Cardinal(Elapsed);
end;

procedure TMsr2067HLMagStripeAdapter.SendMessage(const AMessage: TBytes);
var
  Frame: TBytes;
begin
  Frame := TMsr2067HLCodec.Encode(AMessage);
  try
    FNeedsReset := True;
    FPort.Send(Frame, Remaining);
  finally
    if Length(Frame) > 0 then
      FillChar(Frame[0], Length(Frame), 0);
  end;
end;

function TMsr2067HLMagStripeAdapter.ReceiveFirst: Byte;
begin
  Result := FPort.ReceiveByte(Remaining);
  FLastByteAt := FPort.NowMs;
  Remaining;
end;

function TMsr2067HLMagStripeAdapter.ReceiveContinuation: Byte;
var
  Timeout: Cardinal;
  Now, Elapsed: UInt64;
begin
  Timeout := Remaining;
  Now := FPort.NowMs;
  if Now < FLastByteAt then
    raise EMagStripeError.Create('Serial clock moved backwards.');
  Elapsed := Now - FLastByteAt;
  if Elapsed >= 65 then
    raise EMagStripeError.Create('USI1 inter-character deadline expired.');
  if Timeout > 65 - Cardinal(Elapsed) then
    Timeout := 65 - Cardinal(Elapsed);
  Result := FPort.ReceiveByte(Timeout);
  Now := FPort.NowMs;
  if Now < FLastByteAt then
    raise EMagStripeError.Create('Serial clock moved backwards.');
  if Now - FLastByteAt > 65 then
    raise EMagStripeError.Create('USI1 inter-character deadline expired.');
  FLastByteAt := Now;
end;

function TMsr2067HLMagStripeAdapter.ReceiveMessage: TBytes;
var
  Frame: TBytes;
  Count: Integer;
  Value: Byte;
begin
  Frame := One(ReceiveFirst);
  if Frame[0] <> 2 then
    ProtocolError;
  Count := 1;
  repeat
    if Count >= 107 then
      ProtocolError;
    Value := ReceiveContinuation;
    SetLength(Frame, Count + 1);
    Frame[Count] := Value;
    Inc(Count);
  until Value = 3;
  SetLength(Frame, Count + 1);
  Frame[Count] := ReceiveContinuation;
  Remaining;
  Result := TMsr2067HLCodec.Decode(Frame);
end;

procedure TMsr2067HLMagStripeAdapter.ExpectAck;
var
  Reply: TBytes;
begin
  Reply := ReceiveMessage;
  if (Length(Reply) <> 1) or (Reply[0] <> $5E) then
    ProtocolError;
end;

procedure TMsr2067HLMagStripeAdapter.CommandAck(const ACommand: Byte);
begin
  SendMessage(One(ACommand));
  ExpectAck;
end;

procedure TMsr2067HLMagStripeAdapter.Prepare;
var
  First: Byte;
  Frame, Reply: TBytes;
  I: Integer;
begin
  FPort.DiscardInput;
  FNeedsReset := True;
  FPort.Send(One($7F), Remaining);
  First := ReceiveFirst;
  if First = 2 then
  begin
    SetLength(Frame, 4);
    Frame[0] := First;
    for I := 1 to 3 do
      Frame[I] := ReceiveContinuation;
    Reply := TMsr2067HLCodec.Decode(Frame);
    if (Length(Reply) <> 1) or (Reply[0] <> $3A) then
      ProtocolError;
  end
  else if First <> $3A then
    ProtocolError;
  Remaining;
  // The first valid USI1 command selects USI1 after reset, independently of the power report format.
  SendMessage(One($23));
  Reply := ReceiveMessage;
  if (Length(Reply) <> 1) or (Reply[0] <> $77) then
    raise EMagStripeError.Create
      ('MSR206-7HL three-track read/write configuration was not confirmed.');
end;

procedure TMsr2067HLMagStripeAdapter.SetCoercivity(const ACoercivity
  : TMagStripeCoercivity);
var
  Command, Reply: TBytes;
  Current: string;
  I: Integer;
begin
  if ACoercivity = mscLow then
    Current := '036'
  else
    Current := '255';
  SetLength(Command, 4);
  Command[0] := $3C;
  for I := 1 to 3 do
    Command[I] := Ord(Current[I]);
  SendMessage(Command);
  ExpectAck;
  SendMessage(One($3E));
  Reply := ReceiveMessage;
  if Length(Reply) <> 3 then
    ProtocolError;
  for I := 0 to 2 do
    if Reply[I] <> Ord(Current[I + 1]) then
      raise EMagStripeError.Create
        ('Temporary MSR206-7HL write current was not confirmed.');
end;

function TMsr2067HLMagStripeAdapter.ReadBuffers(const ATracks
  : TMagStripeTrackSet): TMagStripeTracks;
var
  T: TMagStripeTrack;
begin
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    Result[T] := '';
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if T in ATracks then
    begin
      SendMessage(One($51 + Ord(T)));
      Result[T] := TMsr2067HLCodec.DecodeTrack(T, ReceiveMessage);
    end;
end;

function TMsr2067HLMagStripeAdapter.Read(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
begin
  BeginIo(ATracks, ATimeoutMs);
  try
    try
      Prepare;
      CommandAck($50);
      ExpectAck;
      Result := ReadBuffers(ATracks);
    except
      FPoisoned := True;
      raise;
    end;
  finally
    FBusy := False;
  end;
end;

function TMsr2067HLMagStripeAdapter.Write(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  T: TMagStripeTrack;
  Command, Frame: TBytes;
  I: Integer;
  Dispatched: Boolean;
  Timeout: Cardinal;
begin
  if (ATracks = []) or not(ACoercivity in [mscLow, mscHigh]) then
    raise EMagStripeError.Create
      ('Nonempty tracks and explicit low/high coercivity are required.');
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    TMagStripeTrackCodec.ValidatePayload(T, AData[T]);
    if ((T in ATracks) and (AData[T] = '')) or
      (not(T in ATracks) and (AData[T] <> '')) then
      raise EMagStripeError.Create
        ('Selected payloads must be nonempty; unselected payloads must be empty.');
    if (Length(AData[T]) = 1) and IsErrorByte(Ord(AData[T][1])) then
      raise EMagStripeError.Create
        ('Singleton status characters cannot be independently verified.');
  end;
  BeginIo(ATracks, ATimeoutMs);
  Dispatched := False;
  try
    try
      Prepare;
      SetCoercivity(ACoercivity);
      CommandAck($4F);
      CommandAck($6E); // Density before any Load Data command.
      for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
        if T in ATracks then
        begin
          CommandAck($41 + Ord(T));
          SetLength(Command, Length(AData[T]) + 1);
          for I := 1 to Length(AData[T]) do
            Command[I - 1] := Ord(AData[T][I]);
          Command[High(Command)] := 4;
          try
            SendMessage(Command);
            ExpectAck;
          finally
            FillChar(Command[0], Length(Command), 0);
            Command := nil;
          end;
        end;
      Frame := TMsr2067HLCodec.Encode(One($40));
      Timeout := Remaining;
      Dispatched := True;
      FPort.Send(Frame, Timeout);
      ExpectAck;
      ExpectAck;
      Result := ReadBuffers(ATracks);
      for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
        if T in ATracks then
          if Result[T] <> AData[T] then
            raise EMagStripeError.Create
              ('Acquired same-swipe data differs from the request.');
    except
      on E: Exception do
      begin
        FPoisoned := True;
        if Dispatched then
          raise EMagStripeWriteUncertain.Create
            ('MSR206-7HL writing is uncertain (' + E.ClassName + ').');
        raise;
      end;
    end;
  finally
    FBusy := False;
  end;
end;

end.
