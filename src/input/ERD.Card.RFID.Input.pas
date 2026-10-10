unit ERD.Card.RFID.Input;

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
  ERD.Card.Bytes;

const
  /// <summary>Maximum presented identifier characters; prefix/suffix are bounded separately.</summary>
  RfidInputMaxCharacters = 128;
  /// <summary>Maximum explicitly converted identifier byte width.</summary>
  RfidInputMaxBytes = 64;

type
  /// <summary>Invalid reader text, configuration or framing; messages contain no presented identifier.</summary>
  ERfidInputError = class(Exception);
  /// <summary>An unfinished scan timed out and is discarded through its delimiter; no tail is accepted.</summary>
  ERfidInputTimeout = class(ERfidInputError);
  /// <summary>Explicit interpretation of reader-presented text, not automatic tag/frequency detection.</summary>
  TRfidInputEncoding = (
    /// <summary>Printable ASCII identifier; no UID bytes or numeric semantics are inferred.</summary>
    rieAscii,
    /// <summary>Even-length hexadecimal bytes, in the reader's presented order.</summary>
    rieHexadecimal,
    /// <summary>Decimal digit string; leading zeros are preserved, not interpreted as facility/card fields.</summary>
    rieDecimal);
  /// <summary>Explicit configured reader terminator; no CR/LF guessing or trimming.</summary>
  TRfidInputTerminator = (
    /// <summary>A single carriage return.</summary>
    ritCr,
    /// <summary>A carriage return followed by line feed.</summary>
    ritCrLf,
    /// <summary>A single line feed.</summary>
    ritLf,
    /// <summary>A single tab character.</summary>
    ritTab);
  /// <summary>Explicit byte order for converting a presented number; never a claim of RF UID byte order.</summary>
  TRfidInputByteOrder = (
    /// <summary>Most significant byte first.</summary>
    ribBigEndian,
    /// <summary>Least significant byte first.</summary>
    ribLittleEndian);

  /// <summary>One complete reader-presented identifier; source identity and card authenticity are not established.</summary>
  TRfidInputIdentifier = record
    /// <summary>Exact unframed text, including leading zeros and original letter case.</summary>
    Text: UnicodeString;
    /// <summary>Explicit interpretation selected by the application.</summary>
    Encoding: TRfidInputEncoding;
    /// <summary>Owned presented hexadecimal bytes; empty for ASCII/decimal until explicit conversion.</summary>
    Bytes: TBytes;
  end;

  /// <summary>Pure strict decoders and explicit numeric conversion for generic reader text.</summary>
  TRfidInputCodec = class
  public
    /// <summary>Validates one unframed identifier without trimming, guessing or numeric padding.</summary>
    /// <param name="AText">One through 128 printable ASCII characters.</param>
    /// <param name="AEncoding">Explicit ASCII, hexadecimal or decimal interpretation.</param>
    /// <param name="AExpectedCharacters">Zero for variable length, otherwise exact one-through-128 length.</param>
    /// <returns>Owned identifier; only explicit hexadecimal input populates Bytes.</returns>
    class function Decode(const AText: UnicodeString;
      const AEncoding: TRfidInputEncoding;
      const AExpectedCharacters: Integer = 0): TRfidInputIdentifier; static;
    /// <summary>Converts explicitly numeric text to a requested byte width/order without guessing UID layout.</summary>
    /// <param name="AIdentifier">Hexadecimal or decimal text; revalidated rather than trusting its Bytes field.</param>
    /// <param name="AWidth">One through 64 bytes; hex must already have that width, decimal must fit it.</param>
    /// <param name="AOrder">Explicit big or little endian numeric representation.</param>
    /// <returns>Independent exact-width bytes; overflow, ASCII and unknown order are refused.</returns>
    class function ToBytes(const AIdentifier: TRfidInputIdentifier;
      const AWidth: Integer; const AOrder: TRfidInputByteOrder): TBytes; static;
  end;

  /// <summary>Caller-thread notification for a complete reader-presented identifier.</summary>
  /// <param name="Sender">The input component.</param>
  /// <param name="AIdentifier">Owned event data; caller may copy it; LastIdentifier has separate byte storage.</param>
  TRfidIdentifierEvent = procedure(Sender: TObject;
    const AIdentifier: TRfidInputIdentifier) of object;

  /// <summary>Brand-independent bounded framing for RFID readers configured as USB-HID keyboards.</summary>
  /// <remarks>Construction and Start do not open a USB device. The host supplies characters
  /// from a dedicated keyboard input control or isolated device source, using the actual key mapping.
  /// Generic keyboard events do not prove device identity. This reads the presented identifier only:
  /// no raw vendor HID-report protocol, card memory, RF UID proof or writing is implied. Use one
  /// owning thread; do not free the component, recursively feed or change configuration in its event.</remarks>
  TRfidKeyboardReader = class(TComponent)
  private
    FEncoding: TRfidInputEncoding;
    FTerminator: TRfidInputTerminator;
    FPrefix, FSuffix, FBuffer: UnicodeString;
    FMaxCharacters, FExpectedCharacters: Integer;
    FInterCharacterTimeoutMs: Cardinal;
    FActive, FDispatching, FDiscarding, FPendingCr, FHaveTime: Boolean;
    FLastTime: UInt64;
    FLast: TRfidInputIdentifier;
    FOnIdentifier: TRfidIdentifierEvent;
    procedure RequireConfigurable;
    procedure RequireNotDispatching;
    procedure SetEncoding(const AValue: TRfidInputEncoding);
    procedure SetTerminator(const AValue: TRfidInputTerminator);
    procedure SetPrefix(const AValue: UnicodeString);
    procedure SetSuffix(const AValue: UnicodeString);
    procedure SetMaxCharacters(const AValue: Integer);
    procedure SetExpectedCharacters(const AValue: Integer);
    procedure SetInterCharacterTimeoutMs(const AValue: Cardinal);
    procedure SetOnIdentifier(const AValue: TRfidIdentifierEvent);
    function GetLastIdentifier: TRfidInputIdentifier;
    function IsDelimiter(const ACharacter: WideChar): Boolean;
    function CompleteFrame: Boolean;
    procedure DiscardCharacter(const ACharacter: WideChar);
  protected
    /// <summary>Rejects configuration changes during capture or event publication for descendant adapters.</summary>
    procedure CheckConfigurable;
    /// <summary>Rejects recursive input before descendant adapters mutate their own state.</summary>
    procedure CheckNotDispatching;
  public
    /// <summary>Creates inactive ASCII/CR framing with a 128-character limit and 500 ms inter-character deadline.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Starts an explicit fresh capture without opening hardware; configuration is frozen until Stop.</summary>
    procedure Start; virtual;
    /// <summary>Stops and discards unfinished input; safe to repeat outside an event callback.</summary>
    procedure Stop;
    /// <summary>Discards partial input and any discard state while retaining the last complete result.</summary>
    /// <remarks>Use only at a known frame boundary, such as after cancelling the source.</remarks>
    procedure Reset;
    /// <summary>Discards unfinished input and refuses its tail through the next configured delimiter.</summary>
    /// <remarks>Use after a lost or invalid source report, rather than accepting later bytes as a new scan.</remarks>
    procedure DiscardFrame;
    /// <summary>Feeds one mapped character from an explicitly chosen host input source.</summary>
    /// <param name="ACharacter">Mapped ASCII payload or configured delimiter; no keyboard-layout inference.</param>
    /// <param name="ATimeMs">Monotonic total milliseconds, such as GetTickCount64; time reversal is refused.</param>
    /// <returns>True only when one complete valid frame was decoded and its event returned.</returns>
    /// <exception cref="ERfidInputTimeout">A partial frame exceeded its inter-character budget.</exception>
    /// <exception cref="ERfidInputError">Input, framing, configuration or lifecycle is invalid.</exception>
    /// <remarks>Timeout, overflow and invalid control characters discard through the configured delimiter,
    /// preventing a truncated tail from becoming another identifier. Closed malformed frames are consumed.
    /// Consumer event exceptions propagate once; no frame is replayed.</remarks>
    function FeedCharacter(const ACharacter: WideChar;
      const ATimeMs: UInt64): Boolean;
    /// <summary>Whether host-fed capture is active; no physical device connection is implied.</summary>
    property Active: Boolean read FActive;
    /// <summary>Independent last complete identifier; empty before the first successful frame after Start.</summary>
    property LastIdentifier: TRfidInputIdentifier read GetLastIdentifier;
  published
    /// <summary>Explicit interpretation; defaults to preserving printable ASCII.</summary>
    property Encoding: TRfidInputEncoding read FEncoding write SetEncoding
      default rieAscii;
    /// <summary>Actual configured reader terminator; CR by default.</summary>
    property Terminator: TRfidInputTerminator read FTerminator
      write SetTerminator default ritCr;
    /// <summary>Exact printable ASCII reader prefix, at most 32 characters; empty by default.</summary>
    property Prefix: UnicodeString read FPrefix write SetPrefix;
    /// <summary>Exact printable ASCII reader suffix before the delimiter, at most 32 characters.</summary>
    property Suffix: UnicodeString read FSuffix write SetSuffix;
    /// <summary>Identifier bound, one through 128 characters; default 128.</summary>
    property MaxCharacters: Integer read FMaxCharacters write SetMaxCharacters
      default RfidInputMaxCharacters;
    /// <summary>Required identifier length; zero is variable, otherwise one through MaxCharacters.</summary>
    property ExpectedCharacters: Integer read FExpectedCharacters
      write SetExpectedCharacters default 0;
    /// <summary>Maximum inter-character gap, one through 60000 milliseconds; default 500.</summary>
    property InterCharacterTimeoutMs: Cardinal read FInterCharacterTimeoutMs
      write SetInterCharacterTimeoutMs default 500;
    /// <summary>Caller-thread event emitted once per complete valid frame; repeated scans are not deduplicated.</summary>
    property OnIdentifier: TRfidIdentifierEvent read FOnIdentifier
      write SetOnIdentifier;
  end;

implementation

procedure Fail(const AReason: string);
begin
  raise ERfidInputError.Create('Invalid RFID input: ' + AReason + '.');
end;

procedure ValidateAscii(const AText: UnicodeString; const AMax: Integer);
var
  I: Integer;
begin
  if Length(AText) > AMax then
    Fail('text bound');
  for I := 1 to Length(AText) do
    if (Ord(AText[I]) < 32) or (Ord(AText[I]) > 126) then
      Fail('ASCII mapping');
end;

class function TRfidInputCodec.Decode(const AText: UnicodeString;
  const AEncoding: TRfidInputEncoding; const AExpectedCharacters: Integer)
  : TRfidInputIdentifier;
var
  I: Integer;
begin
  if (AExpectedCharacters < 0) or (AExpectedCharacters > RfidInputMaxCharacters)
  then
    Fail('expected length');
  if (Length(AText) = 0) or ((AExpectedCharacters <> 0) and
    (Length(AText) <> AExpectedCharacters)) then
    Fail('identifier length');
  ValidateAscii(AText, RfidInputMaxCharacters);
  Result := Default (TRfidInputIdentifier);
  Result.Text := AText;
  Result.Encoding := AEncoding;
  case AEncoding of
    rieAscii:
      ;
    rieHexadecimal:
      begin
        if (Length(AText) mod 2) <> 0 then
          Fail('hexadecimal width');
        for I := 1 to Length(AText) do
          if not(Ord(AText[I]) in [48 .. 57, 65 .. 70, 97 .. 102]) then
            Fail('hexadecimal digit');
        Result.Bytes := HexToBytes(string(AText));
      end;
    rieDecimal:
      for I := 1 to Length(AText) do
        if not(Ord(AText[I]) in [48 .. 57]) then
          Fail('decimal digit');
  else
    Fail('encoding');
  end;
end;

class function TRfidInputCodec.ToBytes(const AIdentifier: TRfidInputIdentifier;
  const AWidth: Integer; const AOrder: TRfidInputByteOrder): TBytes;
var
  D: TRfidInputIdentifier;
  I, J, Carry, V: Integer;
  B: Byte;
begin
  if (AWidth < 1) or (AWidth > RfidInputMaxBytes) then
    Fail('byte width');
  if not(AOrder in [ribBigEndian, ribLittleEndian]) then
    Fail('byte order');
  D := Decode(AIdentifier.Text, AIdentifier.Encoding);
  case D.Encoding of
    rieHexadecimal:
      begin
        if Length(D.Bytes) <> AWidth then
          Fail('hexadecimal width');
        Result := CopyBytes(D.Bytes);
      end;
    rieDecimal:
      begin
        Result := nil;
        SetLength(Result, AWidth);
        for I := 1 to Length(D.Text) do
        begin
          Carry := Ord(D.Text[I]) - Ord('0');
          for J := AWidth - 1 downto 0 do
          begin
            V := Integer(Result[J]) * 10 + Carry;
            Result[J] := Byte(V and $FF);
            Carry := V shr 8;
          end;
          if Carry <> 0 then
            Fail('numeric overflow');
        end;
      end;
  else
    Fail('ASCII has no numeric byte interpretation');
  end;
  if AOrder = ribLittleEndian then
    for I := 0 to AWidth div 2 - 1 do
    begin
      J := AWidth - 1 - I;
      B := Result[I];
      Result[I] := Result[J];
      Result[J] := B;
    end;
end;

constructor TRfidKeyboardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxCharacters := RfidInputMaxCharacters;
  FInterCharacterTimeoutMs := 500;
end;

procedure TRfidKeyboardReader.RequireNotDispatching;
begin
  if FDispatching then
    Fail('event callback reentrancy');
end;

procedure TRfidKeyboardReader.RequireConfigurable;
begin
  RequireNotDispatching;
  if FActive then
    Fail('configuration is active');
end;

procedure TRfidKeyboardReader.CheckNotDispatching;
begin
  RequireNotDispatching;
end;

procedure TRfidKeyboardReader.CheckConfigurable;
begin
  RequireConfigurable;
end;

procedure TRfidKeyboardReader.SetEncoding(const AValue: TRfidInputEncoding);
begin
  RequireConfigurable;
  if not(AValue in [rieAscii .. rieDecimal]) then
    Fail('encoding');
  FEncoding := AValue;
end;

procedure TRfidKeyboardReader.SetTerminator(const AValue: TRfidInputTerminator);
begin
  RequireConfigurable;
  if not(AValue in [ritCr .. ritTab]) then
    Fail('terminator');
  FTerminator := AValue;
end;

procedure TRfidKeyboardReader.SetPrefix(const AValue: UnicodeString);
begin
  RequireConfigurable;
  ValidateAscii(AValue, 32);
  FPrefix := AValue;
end;

procedure TRfidKeyboardReader.SetSuffix(const AValue: UnicodeString);
begin
  RequireConfigurable;
  ValidateAscii(AValue, 32);
  FSuffix := AValue;
end;

procedure TRfidKeyboardReader.SetMaxCharacters(const AValue: Integer);
begin
  RequireConfigurable;
  if (AValue < 1) or (AValue > RfidInputMaxCharacters) or
    (FExpectedCharacters > AValue) then
    Fail('character bound');
  FMaxCharacters := AValue;
end;

procedure TRfidKeyboardReader.SetExpectedCharacters(const AValue: Integer);
begin
  RequireConfigurable;
  if (AValue < 0) or (AValue > FMaxCharacters) then
    Fail('expected length');
  FExpectedCharacters := AValue;
end;

procedure TRfidKeyboardReader.SetInterCharacterTimeoutMs
  (const AValue: Cardinal);
begin
  RequireConfigurable;
  if (AValue < 1) or (AValue > 60000) then
    Fail('deadline');
  FInterCharacterTimeoutMs := AValue;
end;

procedure TRfidKeyboardReader.SetOnIdentifier(const AValue
  : TRfidIdentifierEvent);
begin
  RequireConfigurable;
  FOnIdentifier := AValue;
end;

function TRfidKeyboardReader.GetLastIdentifier: TRfidInputIdentifier;
begin
  Result := FLast;
  Result.Bytes := CopyBytes(FLast.Bytes);
end;

procedure TRfidKeyboardReader.Start;
begin
  RequireConfigurable;
  Reset;
  FLast := Default (TRfidInputIdentifier);
  FActive := True;
end;

procedure TRfidKeyboardReader.Stop;
begin
  RequireNotDispatching;
  FActive := False;
  Reset;
end;

procedure TRfidKeyboardReader.Reset;
begin
  RequireNotDispatching;
  FBuffer := '';
  FDiscarding := False;
  FPendingCr := False;
  FHaveTime := False;
end;

procedure TRfidKeyboardReader.DiscardFrame;
begin
  RequireNotDispatching;
  FBuffer := '';
  FDiscarding := True;
  FPendingCr := False;
  FHaveTime := False;
end;

function TRfidKeyboardReader.IsDelimiter(const ACharacter: WideChar): Boolean;
begin
  case FTerminator of
    ritCr:
      Result := ACharacter = #13;
    ritCrLf:
      Result := FPendingCr and (ACharacter = #10);
    ritLf:
      Result := ACharacter = #10;
    ritTab:
      Result := ACharacter = #9;
  else
    Fail('terminator');
    Result := False;
  end;
end;

procedure TRfidKeyboardReader.DiscardCharacter(const ACharacter: WideChar);
begin
  if IsDelimiter(ACharacter) then
    Reset
  else
    FPendingCr := (FTerminator = ritCrLf) and (ACharacter = #13);
end;

function TRfidKeyboardReader.CompleteFrame: Boolean;
var
  Text: UnicodeString;
  D: TRfidInputIdentifier;
begin
  Text := FBuffer;
  Reset;
  if (Length(Text) <= Length(FPrefix) + Length(FSuffix)) or
    (Copy(Text, 1, Length(FPrefix)) <> FPrefix) or
    (Copy(Text, Length(Text) - Length(FSuffix) + 1, Length(FSuffix)) <> FSuffix)
  then
    Fail('prefix/suffix');
  Text := Copy(Text, Length(FPrefix) + 1, Length(Text) - Length(FPrefix) -
    Length(FSuffix));
  if Length(Text) > FMaxCharacters then
    Fail('identifier bound');
  D := TRfidInputCodec.Decode(Text, FEncoding, FExpectedCharacters);
  FLast := D;
  FLast.Bytes := CopyBytes(D.Bytes);
  FDispatching := True;
  try
    if Assigned(FOnIdentifier) then
      FOnIdentifier(Self, D);
  finally
    FDispatching := False;
  end;
  Result := True;
end;

function TRfidKeyboardReader.FeedCharacter(const ACharacter: WideChar;
  const ATimeMs: UInt64): Boolean;
var
  TimedOut: Boolean;
begin
  RequireNotDispatching;
  if not FActive then
    Fail('capture is inactive');
  Result := False;
  if FHaveTime and (ATimeMs < FLastTime) then
  begin
    FBuffer := '';
    FDiscarding := True;
    DiscardCharacter(ACharacter);
    Fail('clock moved backwards');
  end;
  TimedOut := False;
  if FHaveTime and ((FBuffer <> '') or FPendingCr) and not FDiscarding then
    TimedOut := ATimeMs - FLastTime > FInterCharacterTimeoutMs;
  FHaveTime := True;
  FLastTime := ATimeMs;
  if TimedOut then
  begin
    FBuffer := '';
    FDiscarding := True;
    DiscardCharacter(ACharacter);
    raise ERfidInputTimeout.Create
      ('RFID scan timed out; incomplete input is discarded through its delimiter.');
  end;
  if FDiscarding then
  begin
    DiscardCharacter(ACharacter);
    Exit;
  end;
  if IsDelimiter(ACharacter) then
  begin
    Result := CompleteFrame;
    Exit;
  end;
  if (FTerminator = ritCrLf) and not FPendingCr and (ACharacter = #13) then
  begin
    FPendingCr := True;
    Exit;
  end;
  if FPendingCr or (Ord(ACharacter) < 32) or (Ord(ACharacter) > 126) or
    (Length(FBuffer) >= FMaxCharacters + Length(FPrefix) + Length(FSuffix)) then
  begin
    FBuffer := '';
    FDiscarding := True;
    DiscardCharacter(ACharacter);
    Fail('character, terminator or frame bound');
  end;
  FBuffer := FBuffer + ACharacter;
end;

end.
