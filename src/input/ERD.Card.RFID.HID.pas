unit ERD.Card.RFID.HID;

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
  ERD.Card.RFID.Input;

type
  /// <summary>Concrete input-report formats; select from the actual descriptor/protocol, never from frequency.</summary>
  TRfidHidReportKind = (
    /// <summary>USB HID 1.11 Appendix B eight-byte boot keyboard input, with US key mapping.</summary>
    rhkBootKeyboard,
    /// <summary>The same keyboard report with one explicitly selected report-ID byte.</summary>
    rhkBootKeyboardWithId,
    /// <summary>Caller-declared printable ASCII field in one exact-length report; not a guessed vendor protocol.</summary>
    rhkAsciiField
  );
  /// <summary>Explicit previous boot keyboard state, independent of OS keyboard/caps-lock state.</summary>
  TRfidHidKeyboardState = record
    /// <summary>Previously held USB keyboard usages, including zero padding.</summary>
    Keys: array[0..5] of Byte;
    /// <summary>Explicit initial caps-lock state, toggled only by new caps-lock usages.</summary>
    CapsLock: Boolean;
  end;
  /// <summary>Caller-known fixed report field; actual reader status/UID semantics are not inferred.</summary>
  TRfidHidAsciiField = record
    /// <summary>Exact complete OS-delivered report length, one through 1024 bytes.</summary>
    ReportBytes: Integer;
    /// <summary>Zero-based first field byte; must exclude a configured report-ID byte.</summary>
    Offset: Integer;
    /// <summary>Field byte width, one through 192, including known padding/prefix/suffix.</summary>
    FieldBytes: Integer;
    /// <summary>Whether report byte zero carries a descriptor-defined ID.</summary>
    HasReportId: Boolean;
    /// <summary>Exact ID to require when HasReportId is true.</summary>
    ReportId: Byte;
    /// <summary>Explicit trailing field padding: NUL or ASCII space only.</summary>
    PaddingByte: Byte;
  end;
  /// <summary>Strict boot-keyboard and declared fixed-field report decoders, without USB opening.</summary>
  TRfidHidCodec = class
  public
    /// <summary>Decodes newly pressed US keys from one exact boot report, suppressing held-key repetition.</summary>
    /// <param name="AReport">Exactly eight bytes, or nine with an explicitly configured report ID.</param>
    /// <param name="AHasReportId">Whether byte zero is an ID, including OS-added zero IDs; never inferred.</param>
    /// <param name="AReportId">Exact required ID when present.</param>
    /// <param name="AState">Caller-owned previous usages/caps state; unchanged on malformed reports.</param>
    /// <returns>Zero or one mapped ASCII character, including CR/tab; modifier-only changes return empty.</returns>
    /// <remarks>Rejects rollover/errors, duplicates, control/alt/GUI combinations, unsupported usages,
    /// and simultaneous new keys whose text order cannot be proven. This is not arbitrary NKRO/vendor HID.</remarks>
    class function DecodeKeyboard(const AReport: TBytes; const AHasReportId: Boolean;
      const AReportId: Byte; var AState: TRfidHidKeyboardState): UnicodeString; static;
    /// <summary>Extracts one explicitly declared ASCII field and removes only its selected trailing padding.</summary>
    /// <param name="AReport">Exact complete report, not transfer fragments or concatenated packets.</param>
    /// <param name="AField">Known layout/ID/padding from reader documentation or descriptor.</param>
    /// <returns>Printable ASCII field; identifier encoding/prefix/suffix checks are separate.</returns>
    /// <remarks>No status/error-byte interpretation or device authenticity is implied by field extraction.</remarks>
    class function DecodeAsciiField(const AReport: TBytes; const AField: TRfidHidAsciiField): UnicodeString; static;
  end;
  /// <summary>Host-fed HID report adapter with the same framing and identifier events as keyboard input.</summary>
  /// <remarks>Supply complete reports from a selected bounded HID source. This component neither
  /// enumerates nor opens USB devices and does not bypass Windows keyboard-driver ownership.
  /// Vendor card-read/write commands remain separate documented protocols.</remarks>
  TRfidHidReportReader = class(TRfidKeyboardReader)
  private
    FReportKind: TRfidHidReportKind;
    FReportId: Byte;
    FInitialCapsLock: Boolean;
    FState: TRfidHidKeyboardState;
    FAsciiField: TRfidHidAsciiField;
    procedure SetReportKind(const AValue: TRfidHidReportKind);
    procedure SetReportId(const AValue: Byte);
    procedure SetInitialCapsLock(const AValue: Boolean);
    procedure SetAsciiField(const AValue: TRfidHidAsciiField);
  public
    /// <summary>Starts fresh framing and keyboard state using the explicitly selected initial caps-lock flag.</summary>
    /// <remarks>Boot profiles require CR or Tab; fixed ASCII fields support every configured terminator.</remarks>
    procedure Start; override;
    /// <summary>Feeds one selected-source report; fixed ASCII reports each represent one complete field.</summary>
    /// <param name="AReport">Complete report matching ReportKind/AsciiField exactly; not retained.</param>
    /// <param name="ATimeMs">Monotonic report timestamp in milliseconds.</param>
    /// <returns>True only for a completed valid identifier; key releases/held keys return false.</returns>
    /// <remarks>A malformed keyboard report discards the unfinished scan through its delimiter.
    /// ASCII fields are complete packet boundaries and never combined across reports.</remarks>
    function FeedReport(const AReport: TBytes; const ATimeMs: UInt64): Boolean;
    /// <summary>Explicit fixed ASCII packet layout; set while capture is inactive.</summary>
    property AsciiField: TRfidHidAsciiField read FAsciiField write SetAsciiField;
  published
    /// <summary>Explicit report format; default is eight-byte boot keyboard, not descriptor auto-detection.</summary>
    property ReportKind: TRfidHidReportKind read FReportKind write SetReportKind default rhkBootKeyboard;
    /// <summary>Required ID for the nine-byte boot variant; zero is permitted when explicitly selected.</summary>
    property ReportId: Byte read FReportId write SetReportId default 0;
    /// <summary>Known source caps-lock state at Start; false by default and independent of the OS.</summary>
    property InitialCapsLock: Boolean read FInitialCapsLock write SetInitialCapsLock default False;
  end;

implementation

procedure Fail;
begin raise ERfidInputError.Create('Invalid or unsupported RFID HID report.'); end;

function Held(const AKey: Byte; const AKeys: TRfidHidKeyboardState): Boolean;
var I: Integer;
begin Result := False; for I := 0 to 5 do if AKeys.Keys[I] = AKey then begin Result := True; Exit; end; end;

function MapUsKey(const AKey: Byte; const AShift, ACaps: Boolean): WideChar;
const Normal: string = '1234567890'; Shifted: string = '!@#$%^&*()';
  Punctuation: string = '-=[]\;''`,./'; ShiftPunctuation: string = '_+{}|:"~<>?';
var I: Integer;
begin
  if AKey in [$04..$1D] then
  begin
    Result := WideChar(Ord('a') + AKey - $04);
    if AShift xor ACaps then Result := WideChar(Ord(Result) - 32);
    Exit;
  end;
  if AKey in [$1E..$27] then
  begin
    I := AKey - $1E + 1; if AShift then Result := WideChar(Shifted[I]) else Result := WideChar(Normal[I]); Exit;
  end;
  case AKey of
    $28, $58: Result := #13;
    $2B: Result := #9;
    $2C: Result := ' ';
    $2D..$31, $33..$38:
      begin
        I := AKey - $2D + 1; if AKey >= $33 then Dec(I);
        if AShift then Result := WideChar(ShiftPunctuation[I]) else Result := WideChar(Punctuation[I]);
      end;
    $59..$61: Result := WideChar(Ord('1') + AKey - $59);
    $62: Result := '0';
    $63: Result := '.';
  else Fail; Result := #0; end;
end;

class function TRfidHidCodec.DecodeKeyboard(const AReport: TBytes;
  const AHasReportId: Boolean; const AReportId: Byte; var AState: TRfidHidKeyboardState): UnicodeString;
var Offset, I, J, NewCount: Integer; Key, NewKey, Modifiers: Byte;
  State: TRfidHidKeyboardState; Shift: Boolean; Mapped: WideChar;
begin
  Offset := 0; if AHasReportId then Offset := 1;
  if Length(AReport) <> 8 + Offset then Fail;
  if AHasReportId and (AReport[0] <> AReportId) then Fail;
  Modifiers := AReport[Offset];
  if (AReport[Offset + 1] <> 0) or ((Modifiers and $DD) <> 0) then Fail;
  State := AState; NewCount := 0; NewKey := 0;
  for I := 0 to 5 do
  begin
    Key := AReport[Offset + 2 + I]; State.Keys[I] := Key;
    if Key = 0 then Continue;
    if (Key <= 3) or (Key in [$E0..$E7]) then Fail;
    if Key <> $39 then
    begin Mapped := MapUsKey(Key,False,False); if Mapped = #0 then Fail; end;
    for J := 0 to I - 1 do if State.Keys[J] = Key then Fail;
    if not Held(Key,AState) then begin Inc(NewCount); NewKey := Key; end;
  end;
  if NewCount > 1 then Fail;
  Result := '';
  if NewCount = 1 then
  begin
    if NewKey = $39 then State.CapsLock := not State.CapsLock
    else
    begin
      Shift := (Modifiers and $22) <> 0;
      Result := UnicodeString(MapUsKey(NewKey,Shift,State.CapsLock));
    end;
  end;
  AState := State;
end;

class function TRfidHidCodec.DecodeAsciiField(const AReport: TBytes;
  const AField: TRfidHidAsciiField): UnicodeString;
var I, Count: Integer;
begin
  if (AField.ReportBytes < 1) or (AField.ReportBytes > 1024) or
    (Length(AReport) <> AField.ReportBytes) or (AField.Offset < 0) or
    (AField.Offset >= AField.ReportBytes) or (AField.FieldBytes < 1) or
    (AField.FieldBytes > 192) or (AField.FieldBytes > AField.ReportBytes - AField.Offset) or
    not (AField.PaddingByte in [0,32]) then Fail;
  if AField.HasReportId then
    if (AField.Offset = 0) or (AReport[0] <> AField.ReportId) then Fail;
  Count := AField.FieldBytes;
  while (Count > 0) and (AReport[AField.Offset + Count - 1] = AField.PaddingByte) do Dec(Count);
  if Count = 0 then Fail;
  Result := ''; SetLength(Result,Count);
  for I := 0 to Count - 1 do
  begin
    if (AReport[AField.Offset + I] < 32) or (AReport[AField.Offset + I] > 126) then Fail;
    Result[I + 1] := WideChar(AReport[AField.Offset + I]);
  end;
end;

procedure TRfidHidReportReader.SetReportKind(const AValue: TRfidHidReportKind);
begin CheckConfigurable; if not (AValue in [rhkBootKeyboard..rhkAsciiField]) then Fail; FReportKind := AValue; end;

procedure TRfidHidReportReader.SetReportId(const AValue: Byte);
begin CheckConfigurable; FReportId := AValue; end;

procedure TRfidHidReportReader.SetInitialCapsLock(const AValue: Boolean);
begin CheckConfigurable; FInitialCapsLock := AValue; end;

procedure TRfidHidReportReader.SetAsciiField(const AValue: TRfidHidAsciiField);
begin CheckConfigurable; FAsciiField := AValue; end;

procedure TRfidHidReportReader.Start;
begin
  CheckConfigurable;
  if (FReportKind <> rhkAsciiField) and not (Terminator in [ritCr,ritTab]) then
    raise ERfidInputError.Create('Boot keyboard profiles support CR or Tab framing.');
  inherited Start; FState := Default(TRfidHidKeyboardState); FState.CapsLock := FInitialCapsLock;
end;

function TRfidHidReportReader.FeedReport(const AReport: TBytes; const ATimeMs: UInt64): Boolean;
var Text: UnicodeString; I: Integer;
begin
  CheckNotDispatching;
  if not Active then raise ERfidInputError.Create('RFID report capture is inactive.');
  Result := False;
  if FReportKind = rhkAsciiField then
  begin
    Reset; Text := TRfidHidCodec.DecodeAsciiField(AReport,FAsciiField);
    for I := 1 to Length(Text) do FeedCharacter(Text[I],ATimeMs);
    case Terminator of
      ritCr: Result := FeedCharacter(#13,ATimeMs);
      ritCrLf: begin FeedCharacter(#13,ATimeMs); Result := FeedCharacter(#10,ATimeMs); end;
      ritLf: Result := FeedCharacter(#10,ATimeMs);
      ritTab: Result := FeedCharacter(#9,ATimeMs);
    end;
  end
  else
  begin
    try Text := TRfidHidCodec.DecodeKeyboard(AReport,FReportKind = rhkBootKeyboardWithId,FReportId,FState);
    except DiscardFrame; raise; end;
    if Text <> '' then Result := FeedCharacter(Text[1],ATimeMs);
  end;
end;

end.
