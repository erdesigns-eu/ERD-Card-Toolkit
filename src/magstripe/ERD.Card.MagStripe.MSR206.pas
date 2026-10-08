unit ERD.Card.MagStripe.MSR206;

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

const
  /// <summary>Maximum complete ISO read frame for three standard tracks, including status.</summary>
  Msr206MaxReadBytes = 235;
  /// <summary>Maximum ISO programming command with three full unframed payloads.</summary>
  Msr206MaxWriteBytes = 229;

type
  /// <summary>Explicit three-track protocol profile; never detected by trial programming.</summary>
  TMsr206Profile = (
    /// <summary>MSR206-3HL, PM017-U Rev G: 7/5/5 BPC, fixed 210/75/210 BPI.</summary>
    msrp206ThreeTrackHL,
    /// <summary>MSR605 three-track, manual cover Rev B: explicit 210/75/210 BPI setup.</summary>
    msrp605ThreeTrack
  );
  /// <summary>Pure standard ISO MSR206/MSR605 command and response framing.</summary>
  /// <remarks>Not the incompatible MSR206-7HL Rev F protocol, raw data, AAMVA or proprietary formats.</remarks>
  TMsr206Codec = class
  public
    /// <summary>Builds one ISO write command for all three tracks with nonempty payloads.</summary>
    /// <param name="AData">Unframed standard payloads; all three must be supplied.</param>
    /// <returns>Independent ESC-w/ESC-s/track fields/question-mark/FS command without physical SS/ES/LRC.</returns>
    /// <exception cref="EMagStripeError">Any physical track is empty.</exception>
    /// <exception cref="EMagStripeFormatError">Payload character or capacity is invalid.</exception>
    /// <remarks>Partial/empty programming is refused because these manuals do not establish preservation semantics.</remarks>
    class function WriteCommand(const AData: TMagStripeTracks): TBytes; static;
    /// <summary>Decodes exactly one complete bounded ISO read response with a successful status.</summary>
    /// <param name="AFrame">ESC-s, ordered track fields, block ?/FS, ESC/status; no trailing bytes.</param>
    /// <param name="ATracks">Nonempty physical selection; absent and unselected entries return empty.</param>
    /// <returns>Unframed selected payloads after global status and every supplied track are validated.</returns>
    /// <exception cref="EMagStripeError">Header, order, duplicates, terminator or status is invalid.</exception>
    /// <exception cref="EMagStripeFormatError">A supplied track's standard framing is invalid.</exception>
    class function DecodeRead(const AFrame: TBytes;
      const ATracks: TMagStripeTrackSet): TMagStripeTracks; static;
    /// <summary>Checks the exact two-byte device status reply.</summary>
    /// <param name="AReply">Exactly ESC followed by ASCII zero; no echo or trailing bytes.</param>
    /// <returns>Raw success status 30 hexadecimal; does not supply acquired track read-back.</returns>
    /// <exception cref="EMagStripeError">Reply is malformed or does not report success.</exception>
    class function DecodeSuccess(const AReply: TBytes): Byte; static;
  end;
  /// <summary>Concrete synchronous ISO MSR206/MSR605 reader and device-status programmer.</summary>
  /// <remarks>Constructor is inactive. Retains an injected serial port; Windows factory provides native COM I/O.
  /// Every operation resets, tests communication, verifies three-track model and sets standard encoding.
  /// Only all-three nonempty programming is supported; no host read-back or automatic second swipe.
  /// Operations share one deadline, never replay, and poison a failed session until reset/close release.</remarks>
  TMsr206MagStripeAdapter = class(TInterfacedObject, IMagStripeDevice, IMagStripeStatusWriter)
  private
    FPort: IMagStripeSerialPort;
    FProfile: TMsr206Profile;
    FAcquired, FBusy, FPoisoned, FNeedsReset: Boolean;
    FStarted: UInt64;
    FTimeoutMs: Cardinal;
    procedure BeginIo(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal);
    function Remaining: Cardinal;
    procedure Send(const ABytes: TBytes);
    function Receive(const ACount: Integer): TBytes;
    procedure Prepare;
    procedure SetCoercivity(const ACoercivity: TMagStripeCoercivity);
  public
    /// <summary>Creates an inactive configured three-track adapter.</summary>
    /// <param name="APort">Retained exclusive serial channel; must not be nil.</param>
    /// <param name="AProfile">Explicit protocol/profile choice; no fallback or firmware-version inference.</param>
    /// <exception cref="EMagStripeError">Port or profile is invalid.</exception>
    constructor Create(const APort: IMagStripeSerialPort; const AProfile: TMsr206Profile);
    /// <summary>Best-effort resets/closes an acquired channel, suppressing destructor cleanup exceptions.</summary>
    /// <remarks>Use explicit Release to observe cleanup failures.</remarks>
    destructor Destroy; override;
    /// <summary>Reports three-track reading and no independent verified-read-back writing.</summary>
    /// <returns>ReadTracks all three; WriteTracks/Coercivities empty and VerifiedWrite=false.</returns>
    function GetCapabilities: TMagStripeCapabilities;
    /// <summary>Reports only all-three status programming with explicit low/high coercivity.</summary>
    /// <returns>Exact all-three selection and low/high modes; current-setting requests are refused.</returns>
    function GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
    /// <summary>Opens the port exclusively once; failed opening grants no adapter ownership.</summary>
    procedure Acquire;
    /// <summary>Attempts one bounded reset when commands were sent, then closes and clears ownership.</summary>
    /// <remarks>Reset has no acknowledgement. Cleanup uses a separate 500 ms send budget; primary reset
    /// failure is preserved if close also fails. No reset is sent for an untouched acquired channel.</remarks>
    procedure Release;
    /// <summary>Prepares standard ISO mode and reads one swipe without replay or partial output.</summary>
    /// <param name="ATracks">Nonempty requested physical tracks.</param>
    /// <param name="ATimeoutMs">Total protocol deadline, including preparation, 1..600000 ms.</param>
    /// <returns>Selected unframed payloads after complete framing/status validation.</returns>
    /// <exception cref="EMagStripeError">State, deadline, model, command or response is invalid.</exception>
    /// <exception cref="EMagStripeFormatError">A returned track is invalid.</exception>
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    /// <summary>Refuses verified writing because this protocol returns status rather than acquired read-back.</summary>
    /// <param name="ATracks">Unused write selection.</param>
    /// <param name="AData">Unused payloads; not retained.</param>
    /// <param name="ACoercivity">Unused mode.</param>
    /// <param name="ATimeoutMs">Unused deadline.</param>
    /// <returns>No successful result.</returns>
    /// <exception cref="EMagStripeError">Use explicit status-only ProgramStatus instead.</exception>
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
    /// <summary>Programs all three tracks once and returns raw device success, without host read-back.</summary>
    /// <param name="ATracks">Exactly all three physical tracks; partial selections are refused before I/O.</param>
    /// <param name="AData">Nonempty unframed standard payloads, not retained.</param>
    /// <param name="ACoercivity">Explicit low/high; confirmed before programming. Current mode is refused because reset may alter it.</param>
    /// <param name="ATimeoutMs">Total deadline including setup and swipe wait, 1..600000 ms.</param>
    /// <returns>Raw status 30 hexadecimal after device-reported completion; not acquired track data.</returns>
    /// <exception cref="EMagStripeError">Preflight, setup or state fails before programming dispatch.</exception>
    /// <exception cref="EMagStripeFormatError">Input payload is invalid before I/O.</exception>
    /// <exception cref="EMagStripeWriteUncertain">Programming dispatch or completion failed; never replay.</exception>
    function ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
  end;

implementation

function Pair(const ASecond: Byte): TBytes;
begin
  Result := nil;
  SetLength(Result, 2);
  Result[0] := $1B;
  Result[1] := ASecond;
end;

procedure ProtocolError;
begin
  raise EMagStripeError.Create('Invalid or unsupported MSR206 protocol response.');
end;

class function TMsr206Codec.WriteCommand(const AData: TMagStripeTracks): TBytes;
var
  T: TMagStripeTrack;
  I, P, Count: Integer;
begin
  Result := nil;
  Count := 12; // ESC-w, ESC-s, three track headers, ?/FS.
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    TMagStripeTrackCodec.ValidatePayload(T, AData[T]);
    if AData[T] = '' then raise EMagStripeError.Create('All three programming payloads must be nonempty.');
    Inc(Count, Length(AData[T]));
  end;
  SetLength(Result, Count);
  Result[0] := $1B; Result[1] := $77; Result[2] := $1B; Result[3] := $73;
  P := 4;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    Result[P] := $1B; Result[P + 1] := Ord(T) + 1;
    Inc(P, 2);
    for I := 1 to Length(AData[T]) do
    begin Result[P] := Ord(AData[T][I]); Inc(P); end;
  end;
  Result[P] := $3F; Result[P + 1] := $1C;
end;

class function TMsr206Codec.DecodeSuccess(const AReply: TBytes): Byte;
begin
  if Length(AReply) <> 2 then ProtocolError;
  if (AReply[0] <> $1B) or (AReply[1] <> $30) then ProtocolError;
  Result := AReply[1];
end;

class function TMsr206Codec.DecodeRead(const AFrame: TBytes;
  const ATracks: TMagStripeTrackSet): TMagStripeTracks;
var
  T, ClearTrack: TMagStripeTrack;
  P, Start, Last, EndFields, I: Integer;
  Text, Payload: string;
begin
  for ClearTrack := Low(TMagStripeTrack) to High(TMagStripeTrack) do Result[ClearTrack] := '';
  if (ATracks = []) or (Length(AFrame) < 6) or (Length(AFrame) > Msr206MaxReadBytes) then ProtocolError;
  if (AFrame[0] <> $1B) or (AFrame[1] <> $73) then ProtocolError;
  EndFields := Length(AFrame) - 4;
  if (AFrame[EndFields] <> $3F) or (AFrame[EndFields + 1] <> $1C) then ProtocolError;
  DecodeSuccess(Copy(AFrame, EndFields + 2, 2));
  P := 2;
  Last := 0;
  while P < EndFields do
  begin
    if (P + 1 >= EndFields) or (AFrame[P] <> $1B) then ProtocolError;
    if (AFrame[P + 1] < 1) or (AFrame[P + 1] > 3) or (AFrame[P + 1] <= Last) then ProtocolError;
    Last := AFrame[P + 1];
    T := TMagStripeTrack(Last - 1);
    Inc(P, 2);
    Start := P;
    while (P < EndFields) and (AFrame[P] <> $1B) do Inc(P);
    Payload := '';
    if P <> Start then
    begin
      if P - Start > TMagStripeTrackCodec.MaxPayloadLength(T) + 2 then ProtocolError;
      SetLength(Text, P - Start);
      for I := Start to P - 1 do
      begin
        if (AFrame[I] < $20) or (AFrame[I] > $5F) then ProtocolError;
        Text[I - Start + 1] := Char(AFrame[I]);
      end;
      Payload := TMagStripeTrackCodec.Unframe(T, Text);
    end;
    if T in ATracks then Result[T] := Payload;
  end;
end;

constructor TMsr206MagStripeAdapter.Create(const APort: IMagStripeSerialPort;
  const AProfile: TMsr206Profile);
begin
  inherited Create;
  if (APort = nil) or (Ord(AProfile) < Ord(Low(TMsr206Profile))) or
    (Ord(AProfile) > Ord(High(TMsr206Profile))) then
    raise EMagStripeError.Create('Serial port and explicit MSR206 profile are required.');
  FPort := APort;
  FProfile := AProfile;
end;

destructor TMsr206MagStripeAdapter.Destroy;
begin
  if FAcquired then try Release; except { Explicit Release reports cleanup errors. } end;
  inherited Destroy;
end;

function TMsr206MagStripeAdapter.GetCapabilities: TMagStripeCapabilities;
begin
  Result.ReadTracks := [mstTrack1, mstTrack2, mstTrack3];
  Result.WriteTracks := [];
  Result.Coercivities := [];
  Result.VerifiedWrite := False;
end;

function TMsr206MagStripeAdapter.GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
begin
  Result.Selections := [mswsAllTracks];
  Result.Coercivities := [mscLow, mscHigh];
end;

procedure TMsr206MagStripeAdapter.Acquire;
begin
  if FAcquired or FBusy then raise EMagStripeError.Create('MSR206 session is already acquired.');
  FPort.Open;
  FAcquired := True;
  FPoisoned := False;
  FNeedsReset := False;
end;

procedure TMsr206MagStripeAdapter.Release;
var
  Succeeded: Boolean;
begin
  if not FAcquired or FBusy then raise EMagStripeError.Create('MSR206 session cannot be released in this state.');
  Succeeded := False;
  try
    try
      if FNeedsReset then FPort.Send(Pair($61), 500);
      Succeeded := True;
    finally
      if Succeeded then FPort.Close
      else try FPort.Close; except { Preserve reset failure. } end;
    end;
  finally
    FAcquired := False;
    FPoisoned := False;
    FNeedsReset := False;
  end;
end;

procedure TMsr206MagStripeAdapter.BeginIo(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal);
begin
  if not FAcquired or FBusy or FPoisoned or (ATracks = []) or
    (ATimeoutMs < 1) or (ATimeoutMs > 600000) then
    raise EMagStripeError.Create('Invalid MSR206 session, selection or deadline.');
  FStarted := FPort.NowMs;
  FTimeoutMs := ATimeoutMs;
  FBusy := True;
end;

function TMsr206MagStripeAdapter.Remaining: Cardinal;
var
  Now, Elapsed: UInt64;
begin
  Now := FPort.NowMs;
  if Now < FStarted then raise EMagStripeError.Create('Serial operation clock moved backwards.');
  Elapsed := Now - FStarted;
  if Elapsed >= FTimeoutMs then raise EMagStripeError.Create('MSR206 operation deadline expired.');
  Result := FTimeoutMs - Cardinal(Elapsed);
end;

procedure TMsr206MagStripeAdapter.Send(const ABytes: TBytes);
begin
  FNeedsReset := True;
  FPort.Send(ABytes, Remaining);
end;

function TMsr206MagStripeAdapter.Receive(const ACount: Integer): TBytes;
var
  I: Integer;
begin
  Result := nil;
  if (ACount < 1) or (ACount > Msr206MaxReadBytes) then ProtocolError;
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do Result[I] := FPort.ReceiveByte(Remaining);
  Remaining;
end;

procedure TMsr206MagStripeAdapter.Prepare;
var
  Reply, Command: TBytes;
begin
  FPort.DiscardInput;
  Send(Pair($61)); // Reset has no response.
  Send(Pair($65));
  Reply := Receive(2);
  if (Reply[0] <> $1B) or (Reply[1] <> $79) then ProtocolError;
  Send(Pair($74));
  Reply := Receive(3);
  if (Reply[0] <> $1B) or (Reply[1] <> $33) or (Reply[2] <> $53) then
    raise EMagStripeError.Create('Configured three-track MSR206 model was not confirmed.');
  Command := Pair($6F);
  SetLength(Command, 5);
  Command[2] := 7; Command[3] := 5; Command[4] := 5;
  Send(Command);
  Reply := Receive(5);
  if (Reply[0] <> $1B) or (Reply[1] <> $30) or (Reply[2] <> 7) or
    (Reply[3] <> 5) or (Reply[4] <> 5) then ProtocolError;
  Command := Pair($62);
  SetLength(Command, 3);
  Command[2] := $4B;
  Send(Command);
  TMsr206Codec.DecodeSuccess(Receive(2));
  if FProfile = msrp605ThreeTrack then
  begin
    Command[2] := $A1; Send(Command); TMsr206Codec.DecodeSuccess(Receive(2));
    Command[2] := $C1; Send(Command); TMsr206Codec.DecodeSuccess(Receive(2));
  end;
end;

procedure TMsr206MagStripeAdapter.SetCoercivity(const ACoercivity: TMagStripeCoercivity);
var
  Reply: TBytes;
begin
  case ACoercivity of
    mscCurrent: raise EMagStripeError.Create('An explicit programming coercivity is required.');
    mscLow: begin Send(Pair($79)); TMsr206Codec.DecodeSuccess(Receive(2)); end;
    mscHigh: begin Send(Pair($78)); TMsr206Codec.DecodeSuccess(Receive(2)); end;
  else
    raise EMagStripeError.Create('Invalid programming coercivity.');
  end;
  Send(Pair($64));
  Reply := Receive(2);
  if (Reply[0] <> $1B) or not (Reply[1] in [$48, $4C]) then ProtocolError;
  if ((ACoercivity = mscLow) and (Reply[1] <> $4C)) or
    ((ACoercivity = mscHigh) and (Reply[1] <> $48)) then
    raise EMagStripeError.Create('Programming coercivity setting was not confirmed.');
end;

function TMsr206MagStripeAdapter.Read(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  Frame, Part: TBytes;
  Count: Integer;
  Value: Byte;
begin
  BeginIo(ATracks, ATimeoutMs);
  try
    try
      Prepare;
      Send(Pair($72));
      Frame := Receive(2);
      if (Frame[0] <> $1B) or (Frame[1] <> $73) then ProtocolError;
      Count := 2;
      repeat
        if Count >= Msr206MaxReadBytes - 2 then ProtocolError;
        Value := FPort.ReceiveByte(Remaining);
        SetLength(Frame, Count + 1);
        Frame[Count] := Value;
        Inc(Count);
      until Value = $1C;
      Part := Receive(2);
      SetLength(Frame, Count + 2);
      Frame[Count] := Part[0]; Frame[Count + 1] := Part[1];
      Result := TMsr206Codec.DecodeRead(Frame, ATracks);
    except
      FPoisoned := True;
      raise;
    end;
  finally FBusy := False; end;
end;

function TMsr206MagStripeAdapter.Write(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  T: TMagStripeTrack;
begin
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do Result[T] := '';
  raise EMagStripeError.Create('MSR206 provides device status only; use explicit programming.');
end;

function TMsr206MagStripeAdapter.ProgramStatus(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
  const ATimeoutMs: Cardinal): Byte;
var
  Command: TBytes;
  Dispatched: Boolean;
  Timeout: Cardinal;
begin
  if ATracks <> [mstTrack1, mstTrack2, mstTrack3] then
    raise EMagStripeError.Create('Only all-three nonempty MSR206 programming is supported.');
  if (Ord(ACoercivity) < Ord(Low(TMagStripeCoercivity))) or
    (Ord(ACoercivity) > Ord(High(TMagStripeCoercivity))) then
    raise EMagStripeError.Create('Invalid programming coercivity.');
  if ACoercivity = mscCurrent then
    raise EMagStripeError.Create('An explicit programming coercivity is required.');
  Command := TMsr206Codec.WriteCommand(AData);
  BeginIo(ATracks, ATimeoutMs);
  Dispatched := False;
  try
    try
      Prepare;
      SetCoercivity(ACoercivity);
      Timeout := Remaining;
      Dispatched := True;
      FPort.Send(Command, Timeout);
      Result := TMsr206Codec.DecodeSuccess(Receive(2));
    except
      on E: Exception do
      begin
        FPoisoned := True;
        if Dispatched then
          raise EMagStripeWriteUncertain.Create('MSR206 programming completion is uncertain (' + E.ClassName + ').');
        raise;
      end;
    end;
  finally
    if Length(Command) > 0 then FillChar(Command[0], Length(Command), 0);
    FBusy := False;
  end;
end;

end.
