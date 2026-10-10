unit ERD.Card.MagStripe.MagTek;

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
  ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe;

const
  /// <summary>MagTek D99875191 Rev 20 fixed input-report bytes, excluding an OS-added zero report ID.</summary>
  MagTekHidReportBytes = 337;
  /// <summary>Maximum ISO keyboard frame: 78+39+106 framed track characters and one CR.</summary>
  MagTekKeyboardMaxBytes = 224;

type
  /// <summary>Host-provided exclusive bounded input source, independent of VCL and native HID APIs.</summary>
  /// <remarks>Deliver exactly one swipe, not concatenated frames or USB transfer fragments.
  /// Keyboard sources must isolate reader input, assemble a complete CR-terminated frame and
  /// use the intended key mapping. Do not assume keyboard text proves device identity.
  /// Acquire failures grant nothing; Release cancels pending input and relinquishes ownership.</remarks>
  IMagStripeFrameSource = interface
    ['{6A78FC0F-BC0B-48B7-9F47-6B9BE2264F44}']
    /// <summary>Acquires one non-nested exclusive caller-thread source session.</summary>
    procedure Acquire;
    /// <summary>Releases the session and cancels any pending input, even on a cleanup error.</summary>
    procedure Release;
    /// <summary>Receives exactly one complete swipe with an enforced allocation bound and total deadline.</summary>
    /// <param name="AMaxBytes">Reject larger input before allocating it.</param>
    /// <param name="ATimeoutMs">Total receive deadline in milliseconds; errors are never automatically replayed.</param>
    /// <returns>Independent complete frame; timeout/cancellation raises rather than returning partial input.</returns>
    function Receive(const AMaxBytes: Integer;
      const ATimeoutMs: Cardinal): TBytes;
  end;

  /// <summary>Pure parsers for documented unencrypted ISO MagTek input formats.</summary>
  /// <remarks>Not an encrypted DynaMag/DynaPro, AAMVA, CADL, JIS or arbitrary HID-report parser.</remarks>
  TMagTekFrameCodec = class
  public
    /// <summary>Parses one fixed unencrypted MagTek HID ISO/blank input report.</summary>
    /// <param name="AReport">337 bytes, or exactly 338 when a zero report ID is explicitly requested.</param>
    /// <param name="ATracks">Nonempty selected tracks; selected decode errors raise.</param>
    /// <param name="AHasZeroReportId">Whether byte zero is an OS-added zero report ID; never inferred.</param>
    /// <returns>Unframed selected payloads; unselected/absent tracks are empty. Undefined padding is ignored.</returns>
    /// <exception cref="EMagStripeError">Report shape, encoding, status or requested decode is unsupported.</exception>
    /// <exception cref="EMagStripeFormatError">A selected track's framed ASCII is invalid.</exception>
    class function DecodeHid(const AReport: TBytes;
      const ATracks: TMagStripeTrackSet;
      const AHasZeroReportId: Boolean = False): TMagStripeTracks; static;
    /// <summary>Parses exactly one default ISO keyboard frame ending in CR.</summary>
    /// <param name="AFrame">Ordered optional %, ; and + tracks, each ending in ?, followed by exactly one CR.</param>
    /// <param name="ATracks">Nonempty requested track set; other valid tracks are parsed then omitted.</param>
    /// <returns>Unframed selected payloads, mapping Track 3 plus to physical five-bit SS value B.</returns>
    /// <exception cref="EMagStripeError">Order, duplicates, terminator, byte range or format is invalid.</exception>
    /// <exception cref="EMagStripeFormatError">Any track payload is invalid.</exception>
    /// <remarks>Requires SS/ES enabled, LRC disabled, uppercase and no custom prefix/suffix/separators.
    /// Device error markers are rejected. Absent tracks may be omitted; CR-only is a blank swipe.
    /// ASCII contains no parity/LRC evidence; this method never claims host-verified integrity.</remarks>
    class function DecodeKeyboard(const AFrame: TBytes;
      const ATracks: TMagStripeTrackSet): TMagStripeTracks; static;
  end;

  /// <summary>Read-only MagTek ISO adapter using a retained host input source.</summary>
  /// <remarks>No I/O in constructor; calling-thread exclusive session required. Physical device opening,
  /// HID descriptor/identity validation and keyboard capture belong to the host source.
  /// Inactive source replacement and firmware configuration are not performed by this adapter.</remarks>
  TMagTekReadAdapter = class(TInterfacedObject, IMagStripeDevice)
  private
    FSource: IMagStripeFrameSource;
    FKeyboard, FZeroReportId, FAcquired: Boolean;
  public
    /// <summary>Configures a parser-backed source; does not open hardware.</summary>
    /// <param name="ASource">Retained bounded exclusive frame source; must not be nil.</param>
    /// <param name="AKeyboard">True for default ISO CR-terminated keyboard text; false for fixed HID reports.</param>
    /// <param name="AHasZeroReportId">Explicit HID OS prefix; must be false for keyboard input.</param>
    /// <exception cref="EMagStripeError">Source is nil or keyboard/report-ID configuration is invalid.</exception>
    constructor Create(const ASource: IMagStripeFrameSource;
      const AKeyboard: Boolean; const AHasZeroReportId: Boolean = False);
    /// <summary>Best-effort releases an acquired source, suppressing cleanup exceptions during destruction.</summary>
    /// <remarks>Use explicit Release to observe cancellation/cleanup errors before dropping the adapter.</remarks>
    destructor Destroy; override;
    /// <summary>Returns read-only support for all three ISO physical tracks without I/O.</summary>
    /// <returns>Empty write/coercivity capabilities and VerifiedWrite=false.</returns>
    function GetCapabilities: TMagStripeCapabilities;
    /// <summary>Acquires the host source once; nested sessions are refused.</summary>
    /// <exception cref="EMagStripeError">A session is already held.</exception>
    procedure Acquire;
    /// <summary>Releases the source once; a failed release still relinquishes adapter ownership.</summary>
    /// <exception cref="EMagStripeError">No session is held.</exception>
    procedure Release;
    /// <summary>Receives and parses exactly one bounded frame in the acquired session.</summary>
    /// <param name="ATracks">Nonempty physical selection.</param>
    /// <param name="ATimeoutMs">Total receive timeout, 1..600000 milliseconds.</param>
    /// <returns>Validated selected unframed payloads; no source buffer is retained.</returns>
    /// <exception cref="EMagStripeError">Session, selection, timeout or report is invalid.</exception>
    /// <exception cref="EMagStripeFormatError">Returned track is invalid.</exception>
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal)
      : TMagStripeTracks;
    /// <summary>Rejects writing before any source call; this adapter is read-only.</summary>
    /// <param name="ATracks">Unused write selection.</param>
    /// <param name="AData">Unused data; not retained.</param>
    /// <param name="ACoercivity">Unused write coercivity.</param>
    /// <param name="ATimeoutMs">Unused write deadline.</param>
    /// <returns>No successful result; always raises.</returns>
    /// <exception cref="EMagStripeError">Writing is unsupported.</exception>
    function Write(const ATracks: TMagStripeTrackSet;
      const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
      const ATimeoutMs: Cardinal): TMagStripeTracks;
  end;

implementation

procedure InvalidReport;
begin
  raise EMagStripeError.Create('Invalid or unsupported MagTek input frame.');
end;

function Ascii(const ABytes: TBytes; const AOffset, ACount: Integer): string;
var
  I: Integer;
begin
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
  begin
    if (ABytes[AOffset + I] < $20) or (ABytes[AOffset + I] > $7E) then
      InvalidReport;
    Result[I + 1] := Char(ABytes[AOffset + I]);
  end;
end;

class function TMagTekFrameCodec.DecodeHid(const AReport: TBytes;
  const ATracks: TMagStripeTrackSet; const AHasZeroReportId: Boolean)
  : TMagStripeTracks;
var
  Offset, Expected, I, Count: Integer;
  T: TMagStripeTrack;
begin
  Offset := 0;
  if AHasZeroReportId then
    Offset := 1;
  Expected := MagTekHidReportBytes + Offset;
  if (ATracks = []) or (Length(AReport) <> Expected) then
    InvalidReport;
  if AHasZeroReportId and (AReport[0] <> 0) then
    InvalidReport;
  if not(AReport[Offset + 6] in [0, 3]) then
    InvalidReport;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    I := Ord(T);
    Result[T] := '';
    Count := AReport[Offset + 3 + I];
    if (AReport[Offset + I] > 1) or (Count > 110) then
      InvalidReport;
    if (AReport[Offset + I] = 1) and (Count <> 0) then
      InvalidReport;
    if (AReport[Offset + 6] = 3) and ((Count <> 0) or (AReport[Offset + I] <> 0))
    then
      InvalidReport;
    if T in ATracks then
    begin
      if AReport[Offset + I] = 1 then
        raise EMagStripeError.Create
          ('Selected magnetic track could not be decoded by the device.');
      if Count <> 0 then
        Result[T] := TMagStripeTrackCodec.Unframe(T,
          Ascii(AReport, Offset + 7 + I * 110, Count));
    end;
  end;
end;

class function TMagTekFrameCodec.DecodeKeyboard(const AFrame: TBytes;
  const ATracks: TMagStripeTrackSet): TMagStripeTracks;
var
  P, Start, Last: Integer;
  T, ClearTrack: TMagStripeTrack;
  S: string;
begin
  for ClearTrack := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    Result[ClearTrack] := '';
  if (ATracks = []) or (Length(AFrame) < 1) or
    (Length(AFrame) > MagTekKeyboardMaxBytes) then
    InvalidReport;
  if AFrame[Length(AFrame) - 1] <> 13 then
    InvalidReport;
  P := 0;
  Last := -1;
  while P < Length(AFrame) - 1 do
  begin
    case AFrame[P] of
      Ord('%'):
        T := mstTrack1;
      Ord(';'):
        T := mstTrack2;
      Ord('+'):
        T := mstTrack3;
    else
      InvalidReport;
      T := mstTrack1;
    end;
    if Ord(T) <= Last then
      InvalidReport;
    Last := Ord(T);
    Start := P;
    Inc(P);
    while (P < Length(AFrame) - 1) and (AFrame[P] <> Ord('?')) do
      Inc(P);
    if P >= Length(AFrame) - 1 then
      InvalidReport;
    S := Ascii(AFrame, Start, P - Start + 1);
    if T = mstTrack3 then
      S[1] := ';';
    S := TMagStripeTrackCodec.Unframe(T, S);
    if T in ATracks then
      Result[T] := S;
    Inc(P);
  end;
end;

constructor TMagTekReadAdapter.Create(const ASource: IMagStripeFrameSource;
  const AKeyboard: Boolean; const AHasZeroReportId: Boolean);
begin
  inherited Create;
  if (ASource = nil) or (AKeyboard and AHasZeroReportId) then
    InvalidReport;
  FSource := ASource;
  FKeyboard := AKeyboard;
  FZeroReportId := AHasZeroReportId;
end;

destructor TMagTekReadAdapter.Destroy;
begin
  if FAcquired then
    try
      Release;
    except { Explicit Release is the error-reporting path. } end;
  inherited Destroy;
end;

function TMagTekReadAdapter.GetCapabilities: TMagStripeCapabilities;
begin
  Result.ReadTracks := [mstTrack1, mstTrack2, mstTrack3];
  Result.WriteTracks := [];
  Result.Coercivities := [];
  Result.VerifiedWrite := False;
end;

procedure TMagTekReadAdapter.Acquire;
begin
  if FAcquired then
    raise EMagStripeError.Create('MagTek adapter session is already acquired.');
  FSource.Acquire;
  FAcquired := True;
end;

procedure TMagTekReadAdapter.Release;
begin
  if not FAcquired then
    raise EMagStripeError.Create('MagTek adapter has no acquired session.');
  try
    FSource.Release;
  finally
    FAcquired := False;
  end;
end;

function TMagTekReadAdapter.Read(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  Frame: TBytes;
  MaxBytes: Integer;
begin
  if not FAcquired or (ATracks = []) or (ATimeoutMs < 1) or (ATimeoutMs > 600000)
  then
    InvalidReport;
  if FKeyboard then
    MaxBytes := MagTekKeyboardMaxBytes
  else
  begin
    MaxBytes := MagTekHidReportBytes;
    if FZeroReportId then
      Inc(MaxBytes);
  end;
  Frame := FSource.Receive(MaxBytes, ATimeoutMs);
  if FKeyboard then
    Result := TMagTekFrameCodec.DecodeKeyboard(Frame, ATracks)
  else
    Result := TMagTekFrameCodec.DecodeHid(Frame, ATracks, FZeroReportId);
end;

function TMagTekReadAdapter.Write(const ATracks: TMagStripeTrackSet;
  const AData: TMagStripeTracks; const ACoercivity: TMagStripeCoercivity;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  T: TMagStripeTrack;
begin
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    Result[T] := '';
  raise EMagStripeError.Create
    ('MagTek input adapter does not support writing.');
end;

end.
