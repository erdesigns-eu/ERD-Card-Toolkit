program MagStripeTests;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe, ERD.Card.MagStripe.MagTek;

type
  TFakeDevice = class(TInterfacedObject, IMagStripeDevice)
  private
    FCaps: TMagStripeCapabilities;
    FData, FWritten: TMagStripeTracks;
    FAcquires, FReleases, FReads, FWrites: Integer;
    FAcquireFail, FReleaseFail, FReadFail, FWriteFail, FMismatch, FBadOutput: Boolean;
    FComponent: TMagStripeReaderWriter;
    function GetCapabilities: TMagStripeCapabilities;
    procedure Acquire;
    procedure Release;
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
  end;
  TFakeSource = class(TInterfacedObject, IMagStripeFrameSource)
  private
    FBytes: TBytes;
    FAcquireFail, FReleaseFail, FReceiveFail: Boolean;
    FAcquires, FReleases, FReceives, FBound: Integer;
    procedure Acquire;
    procedure Release;
    function Receive(const AMaxBytes: Integer; const ATimeoutMs: Cardinal): TBytes;
  end;

var
  Assertions: Integer;

procedure Check(const ACondition: Boolean; const ALabel: string);
begin
  Inc(Assertions);
  if not ACondition then raise Exception.Create(ALabel);
end;

function Bits(const S: string): TBytes;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do Result[I - 1] := Ord(S[I]) - Ord('0');
end;

function TextBytes(const S: string): TBytes;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do Result[I - 1] := Ord(S[I]);
end;

procedure BadBits(const T: TMagStripeTrack; const B: TBytes);
var
  Raised: Boolean;
  S: string;
begin
  Raised := False;
  try S := TMagStripeTrackCodec.DecodeBits(T, B);
  except on E: EMagStripeFormatError do Raised := True; end;
  Check(Raised, 'Malformed bits refused');
end;

procedure BadText(const T: TMagStripeTrack; const S: string; const Framed: Boolean);
var
  Raised: Boolean;
  Decoded: string;
begin
  Raised := False;
  try
    if Framed then Decoded := TMagStripeTrackCodec.Unframe(T, S)
    else TMagStripeTrackCodec.ValidatePayload(T, S);
  except on E: EMagStripeFormatError do
    begin Raised := True; if Length(S) > 2 then Check(Pos(S, E.Message) = 0, 'Track content absent from format error'); end;
  end;
  Check(Raised, 'Malformed text refused');
end;

procedure TrackTests;
var
  T: TMagStripeTrack;
  B, Damaged: TBytes;
  S: string;
  I, J, N, Width: Integer;
begin
  // MagTek D99875148 Rev 6 section 1, published forward bit-order examples.
  B := Bits('101000110000110010110110010011111000011100');
  Check(TMagStripeTrackCodec.DecodeBits(mstTrack1, B) = 'AT3', 'Published Track 1 AT3 vector');
  Check(BytesEqual(TMagStripeTrackCodec.EncodeBits(mstTrack1, 'AT3'), B), 'Independent Track 1 encoding');
  Check(TMagStripeTrackCodec.LrcSymbol(mstTrack1, 'AT3') = $1C, 'Published Track 1 LRC');
  B := Bits('110101000001000110011111100100');
  for T := mstTrack2 to mstTrack3 do
  begin
    Check(TMagStripeTrackCodec.DecodeBits(T, B) = '123', 'Published numeric 123 vector');
    Check(BytesEqual(TMagStripeTrackCodec.EncodeBits(T, '123'), B), 'Independent numeric encoding');
    Check(TMagStripeTrackCodec.LrcSymbol(T, '123') = 4, 'Published numeric LRC');
  end;
  Check(TMagStripeTrackCodec.Frame(mstTrack3, '123') = ';123?', 'Physical Track 3 canonical sentinel');
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
  begin
    if T = mstTrack1 then Width := 7 else Width := 5;
    for N := 0 to TMagStripeTrackCodec.MaxPayloadLength(T) do
    begin
      S := StringOfChar('1', N);
      B := TMagStripeTrackCodec.EncodeBits(T, S);
      Check(Length(B) = (N + 3) * Width, 'SS/ES/LRC capacity');
      Check(TMagStripeTrackCodec.DecodeBits(T, B) = S, 'Every supported payload size');
      Check(TMagStripeTrackCodec.Unframe(T, TMagStripeTrackCodec.Frame(T, S)) = S, 'Character framing');
      // Every bit of every frame, including all sentinel and LRC parity bits.
      for I := 0 to Length(B) - 1 do
      begin
        Damaged := CopyBytes(B);
        Damaged[I] := Damaged[I] xor 1;
        BadBits(T, Damaged);
      end;
    end;
    B := TMagStripeTrackCodec.EncodeBits(T, '123');
    for I := 0 to Length(B) - 1 do
    begin
      Damaged := CopyBytes(B);
      Damaged[I] := 2;
      BadBits(T, Damaged);
    end;
    // Flip two data bits in one symbol: odd parity survives but LRC must fail.
    for I := 0 to Width - 3 do
      for J := I + 1 to Width - 2 do
      begin
        Damaged := CopyBytes(B);
        Damaged[Width + I] := Damaged[Width + I] xor 1;
        Damaged[Width + J] := Damaged[Width + J] xor 1;
        BadBits(T, Damaged);
      end;
    BadBits(T, nil);
    BadBits(T, Copy(B, 0, Length(B) - 1));
    Damaged := CopyBytes(B);
    SetLength(Damaged, Length(B) + 1);
    Damaged[Length(B)] := 0;
    BadBits(T, Damaged);
    BadText(T, StringOfChar('1', TMagStripeTrackCodec.MaxPayloadLength(T) + 1), False);
    BadText(T, '12?3', False);
    BadText(T, 'secret', False);
    BadText(T, #0, False);
    BadText(T, '123', True);
    BadText(T, '%123?X', True);
  end;
  // Exercise the whole representable ASCII alphabet, reserving sentinels.
  for I := 0 to 255 do
    for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    begin
      S := Char(I);
      if ((T = mstTrack1) and (I >= $20) and (I <= $5F) and (I <> Ord('%')) and (I <> Ord('?'))) or
        ((T <> mstTrack1) and (I >= $30) and (I <= $3F) and (I <> Ord(';')) and (I <> Ord('?'))) then
        Check(TMagStripeTrackCodec.DecodeBits(T, TMagStripeTrackCodec.EncodeBits(T, S)) = S, 'All legal characters')
      else BadText(T, S, False);
    end;
  BadText(mstTrack3, '+123?', True);
  BadText(mstTrack2, ';12;3?', True);
  BadText(mstTrack1, '%A%B?', True);
  Writeln('PASS: Track 1/2/3 character, published bit vectors, parity, LRC and bounds.');
end;

procedure FinancialTests;
var
  D: TMagStripeFinancialData;
  S: string;
  I: Integer;
  Raised: Boolean;
begin
  D := TMagStripeFinancialCodec.DecodeTrack1('B1234567890123456^DOE/JOHN  ^2912201OPAQUE');
  Check(D.PAN = '1234567890123456', 'Synthetic PAN');
  Check(D.Name = 'DOE/JOHN  ', 'Name whitespace preserved');
  Check((D.ExpiryYYMM = '2912') and (D.ServiceCode = '201'), 'Expiry/service fields');
  Check(D.DiscretionaryData = 'OPAQUE', 'No inferred security-field split');
  Check(TMagStripeFinancialCodec.EncodeTrack1(D) = 'B1234567890123456^DOE/JOHN  ^2912201OPAQUE', 'Financial Track 1');
  D := TMagStripeFinancialCodec.DecodeTrack2('1234567890123456=291220112345');
  Check((D.Name = '') and (D.DiscretionaryData = '12345'), 'Financial Track 2');
  Check(TMagStripeFinancialCodec.EncodeTrack2(D) = '1234567890123456=291220112345', 'Financial Track 2 encode');
  D.ExpiryYYMM := '0000';
  S := TMagStripeFinancialCodec.EncodeTrack2(D);
  Check(Pos('=0000201', S) <> 0, 'Explicit unspecified expiry');
  for I := 0 to 16 do
  begin
    Raised := False;
    try
      case I of
        0: D := TMagStripeFinancialCodec.DecodeTrack1('A1^^2912201');
        1: D := TMagStripeFinancialCodec.DecodeTrack1('B1^NAME^2913201');
        2: D := TMagStripeFinancialCodec.DecodeTrack1('B1^NAME^2900201');
        3: D := TMagStripeFinancialCodec.DecodeTrack1('B1^NAME^2912201^');
        4: D := TMagStripeFinancialCodec.DecodeTrack1('B1^NAME');
        5: D := TMagStripeFinancialCodec.DecodeTrack1('B1^' + StringOfChar('N', 27) + '^2912201');
        6: D := TMagStripeFinancialCodec.DecodeTrack1('B12345678901234567890^^2912201');
        7: D := TMagStripeFinancialCodec.DecodeTrack2('1=2912201=');
        8: D := TMagStripeFinancialCodec.DecodeTrack2('1=291220');
        9: D := TMagStripeFinancialCodec.DecodeTrack2('=2912201');
        10: D := TMagStripeFinancialCodec.DecodeTrack2('1=2912201:');
        11: D := TMagStripeFinancialCodec.DecodeTrack1('B1^^29AA201');
        12: D := TMagStripeFinancialCodec.DecodeTrack1('BA^^2912201');
        13: D := TMagStripeFinancialCodec.DecodeTrack1('B1^^29122A1');
        14: begin D := TMagStripeFinancialCodec.DecodeTrack2('1=2912201'); D.Name := 'NAME'; S := TMagStripeFinancialCodec.EncodeTrack2(D); end;
        15: begin D := TMagStripeFinancialCodec.DecodeTrack1('B1^^2912201'); D.DiscretionaryData := '^'; S := TMagStripeFinancialCodec.EncodeTrack1(D); end;
        16: begin D := TMagStripeFinancialCodec.DecodeTrack1('B1^^2912201'); D.Name := StringOfChar('N', 26); D.DiscretionaryData := StringOfChar('X', 76); S := TMagStripeFinancialCodec.EncodeTrack1(D); end;
      end;
    except on E: EMagStripeFormatError do Raised := True; end;
    Check(Raised, 'Malformed financial field refused');
  end;
  Writeln('PASS: Financial fields, issuer-opaque data and malformed formats.');
end;

function TFakeDevice.GetCapabilities: TMagStripeCapabilities;
begin Result := FCaps; end;
procedure TFakeDevice.Acquire;
begin
  Inc(FAcquires);
  if FAcquireFail then raise EMagStripeError.Create('Acquire failed');
end;
procedure TFakeDevice.Release;
begin
  Inc(FReleases);
  if FReleaseFail then raise EMagStripeError.Create('Release failed');
end;
function TFakeDevice.Read(const ATracks: TMagStripeTrackSet;
  const ATimeoutMs: Cardinal): TMagStripeTracks;
begin
  Inc(FReads);
  Check(ATimeoutMs = 4321, 'Read timeout propagated');
  if FReadFail then raise EMagStripeError.Create('Read primary');
  Result := FData;
end;
function TFakeDevice.Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
var
  Raised: Boolean;
  T: TMagStripeTrack;
begin
  Inc(FWrites);
  Check(ATimeoutMs = 4321, 'Write timeout propagated');
  Check(ACoercivity = mscHigh, 'Explicit coercivity propagated');
  Check(ATracks = [mstTrack2], 'Selected tracks propagated');
  Check(FComponent.Busy, 'Busy during dispatch');
  Raised := False;
  try FComponent.Device := nil; except on E: EMagStripeError do Raised := True; end;
  Check(Raised, 'Cannot change backend during dispatch');
  Raised := False;
  try FComponent.TimeoutMs := 9; except on E: EMagStripeError do Raised := True; end;
  Check(Raised, 'Cannot change deadline during dispatch');
  Raised := False;
  try Result := FComponent.ReadTracks([mstTrack2]); except on E: EMagStripeError do Raised := True; end;
  Check(Raised, 'Nested operation refused');
  FWritten := AData;
  // A simulated partial write happens before the reported failure.
  FData[mstTrack2] := 'PARTIAL';
  if FWriteFail then raise EMagStripeError.Create('secret track write error');
  Result := AData;
  if FMismatch then Result[mstTrack2] := '123';
  if FBadOutput then Result[mstTrack2] := 'SECRET';
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if T in ATracks then FData[T] := Result[T];
end;

procedure ComponentTests;
var
  Obj: TFakeDevice;
  Device: IMagStripeDevice;
  C: TMagStripeReaderWriter;
  Data, Output: TMagStripeTracks;
  I: Integer;
  Raised, Uncertain: Boolean;
begin
  for I := 0 to 14 do
  begin
    Obj := TFakeDevice.Create;
    Device := Obj;
    Obj.FCaps.ReadTracks := [mstTrack1, mstTrack2, mstTrack3];
    Obj.FCaps.WriteTracks := [mstTrack2];
    Obj.FCaps.Coercivities := [mscHigh];
    Obj.FCaps.VerifiedWrite := True;
    C := TMagStripeReaderWriter.Create(nil);
    try
      Check((Obj.FAcquires = 0) and (not C.Busy) and (C.TimeoutMs = 10000), 'Inactive construction');
      C.Device := Device;
      C.TimeoutMs := 4321;
      Obj.FComponent := C;
      Data[mstTrack1] := '';
      Data[mstTrack2] := '456=2912201';
      Data[mstTrack3] := '';
      Obj.FData[mstTrack1] := 'UNCHANGED';
      Obj.FData[mstTrack2] := '789';
      Obj.FData[mstTrack3] := '123';
      case I of
        1: Obj.FAcquireFail := True;
        2: Obj.FWriteFail := True;
        3: Obj.FMismatch := True;
        4: Obj.FBadOutput := True;
        5: Obj.FReleaseFail := True;
        6: begin Obj.FWriteFail := True; Obj.FReleaseFail := True; end;
        7: Obj.FCaps.VerifiedWrite := False;
        8: Obj.FCaps.WriteTracks := [];
        9: Obj.FCaps.Coercivities := [];
        10: Data[mstTrack2] := '';
        11: Data[mstTrack2] := 'secret';
        12: Data[mstTrack1] := 'UNSELECTED';
        13: C.Device := nil;
        14: begin
          Raised := False;
          try C.TimeoutMs := 0; except on E: EMagStripeError do Raised := True; end;
          Check(Raised and (C.TimeoutMs = 4321), 'Timeout zero rejected without mutation');
          Raised := False;
          try C.TimeoutMs := 600001; except on E: EMagStripeError do Raised := True; end;
          Check(Raised, 'Timeout upper bound');
        end;
      end;
      Raised := False;
      Uncertain := False;
      try
        Output := C.WriteTracks([mstTrack2], Data, mscHigh);
      except
        on E: EMagStripeWriteUncertain do
        begin
          Raised := True;
          Uncertain := True;
          Check(Pos('secret', E.Message) = 0, 'Uncertain error excludes backend payload');
          if I = 6 then Check(Pos('EMagStripeError', E.Message) > 0, 'Primary failure preserved');
        end;
        on E: EMagStripeError do Raised := True;
        on E: EMagStripeFormatError do Raised := True;
      end;
      Check(Raised = ((I > 0) and (I < 14)), 'Expected failure class');
      Check(Uncertain = ((I >= 2) and (I <= 6)), 'Only dispatched failures uncertain');
      Check(not C.Busy, 'Busy cleared on every exit');
      if (I = 0) or (I = 14) then
      begin
        Check(Output[mstTrack2] = Data[mstTrack2], 'Verified selected write');
        Check(Obj.FData[mstTrack1] = 'UNCHANGED', 'Unselected Track 1 preserved');
        Check(Obj.FData[mstTrack3] = '123', 'Unselected Track 3 preserved');
        Check(Obj.FWritten[mstTrack2] = Data[mstTrack2], 'Exact unframed input');
      end;
      if (I >= 7) and (I <= 13) then
        Check((Obj.FAcquires = 0) and (Obj.FWrites = 0) and (Obj.FReleases = 0), 'Preflight before all device I/O')
      else if I = 1 then
        Check((Obj.FAcquires = 1) and (Obj.FWrites = 0) and (Obj.FReleases = 0), 'Failed acquire grants nothing')
      else
        Check((Obj.FAcquires = 1) and (Obj.FWrites = 1) and (Obj.FReads = 0) and
          (Obj.FReleases = 1), 'One write, no replay or separate swipe verification');
    finally C.Free; end;
    Device := nil;
  end;
  for I := 0 to 4 do
  begin
    Obj := TFakeDevice.Create;
    Device := Obj;
    Obj.FCaps.ReadTracks := [mstTrack2];
    Obj.FData[mstTrack2] := '123';
    C := TMagStripeReaderWriter.Create(nil);
    try
      C.Device := Device;
      C.TimeoutMs := 4321;
      case I of
        1: Obj.FReadFail := True;
        2: begin Obj.FReadFail := True; Obj.FReleaseFail := True; end;
        3: Obj.FData[mstTrack1] := 'UNREQUESTED';
        4: Obj.FReleaseFail := True;
      end;
      Raised := False;
      try Output := C.ReadTracks([mstTrack2]);
      except on E: EMagStripeError do
        begin
          Raised := True;
          if I = 2 then Check(E.Message = 'Read primary', 'Read primary beats cleanup');
        end;
      end;
      Check(Raised = (I <> 0), 'Read lifecycle failure');
      Check((Obj.FAcquires = 1) and (Obj.FReads = 1) and (Obj.FReleases = 1) and
        (Obj.FWrites = 0) and (not C.Busy), 'Read exactly once');
      Raised := False;
      try Output := C.ReadTracks([]); except on E: EMagStripeError do Raised := True; end;
      Check(Raised and (Obj.FAcquires = 1), 'Empty selection before I/O');
      Raised := False;
      try Output := C.ReadTracks([mstTrack1]); except on E: EMagStripeError do Raised := True; end;
      Check(Raised and (Obj.FAcquires = 1), 'Unsupported selection before I/O');
    finally C.Free; end;
    Device := nil;
  end;
  Writeln('PASS: Reader/writer capability preflight, exclusivity, preservation and uncertain failures.');
end;

procedure TFakeSource.Acquire;
begin
  Inc(FAcquires);
  if FAcquireFail then raise EMagStripeError.Create('Source acquire');
end;
procedure TFakeSource.Release;
begin
  Inc(FReleases);
  if FReleaseFail then raise EMagStripeError.Create('Source release');
end;
function TFakeSource.Receive(const AMaxBytes: Integer; const ATimeoutMs: Cardinal): TBytes;
begin
  Inc(FReceives);
  FBound := AMaxBytes;
  Check(ATimeoutMs = 4321, 'Source timeout propagated');
  if FReceiveFail then raise EMagStripeError.Create('Source timeout');
  Result := CopyBytes(FBytes);
end;

function HidFixture: TBytes;
var
  I: Integer;
  S: string;
begin
  Result := nil;
  SetLength(Result, 337);
  // Undefined trailing field bytes are intentionally nonzero and must be ignored.
  for I := 7 to 336 do Result[I] := $FE;
  Result[0] := 0; Result[1] := 0; Result[2] := 0;
  Result[3] := 5; Result[4] := 5; Result[5] := 5; Result[6] := 0;
  S := '%AT3?'; for I := 1 to 5 do Result[6 + I] := Ord(S[I]);
  S := ';123?'; for I := 1 to 5 do Result[116 + I] := Ord(S[I]);
  S := ';456?'; for I := 1 to 5 do Result[226 + I] := Ord(S[I]);
end;

procedure FrameTests;
var
  B, Prefixed: TBytes;
  Data: TMagStripeTracks;
  Source: IMagStripeFrameSource;
  Device: IMagStripeDevice;
  Obj: TFakeSource;
  C: TMagStripeReaderWriter;
  I, J: Integer;
  S: string;
  Raised: Boolean;
begin
  B := HidFixture;
  Data := TMagTekFrameCodec.DecodeHid(B, [mstTrack1, mstTrack2, mstTrack3]);
  Check((Data[mstTrack1] = 'AT3') and (Data[mstTrack2] = '123') and
    (Data[mstTrack3] = '456'), 'Independent fixed HID offsets');
  SetLength(Prefixed, 338);
  Prefixed[0] := 0;
  for I := 0 to 336 do Prefixed[I + 1] := B[I];
  Data := TMagTekFrameCodec.DecodeHid(Prefixed, [mstTrack2], True);
  Check((Data[mstTrack2] = '123') and (Data[mstTrack1] = ''), 'Explicit zero report ID and physical selection');
  B := HidFixture; B[0] := 1; B[3] := 0;
  Data := TMagTekFrameCodec.DecodeHid(B, [mstTrack2]);
  Check(Data[mstTrack2] = '123', 'Unrequested decode error does not masquerade as absence');
  for I := 0 to 14 do
  begin
    B := HidFixture;
    Raised := False;
    try
      case I of
        0: SetLength(B, 336);
        1: SetLength(B, 338);
        2: B[6] := 1;
        3: B[6] := 2;
        4: B[6] := 4;
        5: B[6] := 5;
        6: B[6] := 6;
        7: B[0] := 2;
        8: B[0] := 1;
        9: B[4] := 111;
        10: B[117] := 0;
        11: begin B[1] := 1; B[4] := 0; end;
        12: B[6] := 3;
        13: B[4] := 40;
        14: begin Prefixed[0] := 1; B := Prefixed; end;
      end;
      Data := TMagTekFrameCodec.DecodeHid(B, [mstTrack1, mstTrack2], I = 14);
    except on E: EMagStripeError do Raised := True;
      on E: EMagStripeFormatError do Raised := True;
    end;
    Check(Raised, 'Invalid HID shape/status/encoding/data refused');
  end;
  SetLength(B, 337); FillChar(B[0], 337, 0); B[6] := 3;
  Data := TMagTekFrameCodec.DecodeHid(B, [mstTrack1, mstTrack2, mstTrack3]);
  Check((Data[mstTrack1] = '') and (Data[mstTrack2] = '') and (Data[mstTrack3] = ''), 'Explicit blank card');
  B := TextBytes('%AT3?;123?+456?'#13);
  Data := TMagTekFrameCodec.DecodeKeyboard(B, [mstTrack1, mstTrack2, mstTrack3]);
  Check((Data[mstTrack1] = 'AT3') and (Data[mstTrack2] = '123') and
    (Data[mstTrack3] = '456'), 'Independent default keyboard framing');
  Data := TMagTekFrameCodec.DecodeKeyboard(TextBytes('+123?'#13), [mstTrack3]);
  Check(Data[mstTrack3] = '123', 'Omitted earlier tracks retain physical identity');
  Data := TMagTekFrameCodec.DecodeKeyboard(TextBytes(#13), [mstTrack2]);
  Check(Data[mstTrack2] = '', 'Blank keyboard swipe');
  S := '%' + StringOfChar('A', 76) + '?;' + StringOfChar('1', 37) + '?+' + StringOfChar('2', 104) + '?'#13;
  Check(Length(S) = 224, 'All maximum ISO tracks include final CR');
  Data := TMagTekFrameCodec.DecodeKeyboard(TextBytes(S), [mstTrack3]);
  Check(Length(Data[mstTrack3]) = 104, 'Maximum keyboard frame');
  for I := 0 to 13 do
  begin
    case I of
      0: S := '';
      1: S := ';123?';
      2: S := ';123?'#13#10;
      3: S := ';123?;456?'#13;
      4: S := '+123?;456?'#13;
      5: S := ';123?%AT3?'#13;
      6: S := '%lower?'#13;
      7: S := ';1234'#13;
      8: S := '#123?'#13;
      9: S := 'E'#13;
      10: S := '%'#0'?'#13;
      11: S := '%AT3?<;'#13;
      12: S := StringOfChar('1', 225);
      13: S := ';123?'#13'X'#13;
    end;
    Raised := False;
    try Data := TMagTekFrameCodec.DecodeKeyboard(TextBytes(S), [mstTrack2]);
    except on E: EMagStripeError do Raised := True;
      on E: EMagStripeFormatError do Raised := True;
    end;
    Check(Raised, 'Invalid/ambiguous keyboard frame refused');
  end;
  for I := 0 to 2 do
    for J := 0 to 4 do
    begin
      Obj := TFakeSource.Create;
      Source := Obj;
      if I = 0 then Obj.FBytes := HidFixture
      else if I = 1 then
      begin
        Obj.FBytes := CopyBytes(Prefixed);
        Obj.FBytes[0] := 0;
      end
      else Obj.FBytes := TextBytes('%AT3?;123?+456?'#13);
      case J of
        1: Obj.FAcquireFail := True;
        2: Obj.FReceiveFail := True;
        3: Obj.FReleaseFail := True;
        4: begin Obj.FReceiveFail := True; Obj.FReleaseFail := True; end;
      end;
      Device := TMagTekReadAdapter.Create(Source, I = 2, I = 1);
      C := TMagStripeReaderWriter.Create(nil);
      try
        C.Device := Device;
        C.TimeoutMs := 4321;
        Raised := False;
        try Data := C.ReadTracks([mstTrack2]);
        except on E: EMagStripeError do
          begin Raised := True; if J = 4 then Check(E.Message = 'Source timeout', 'Source primary beats release'); end;
        end;
        Check(Raised = (J <> 0), 'Concrete adapter lifecycle');
        if J <> 1 then
        begin
          Check((Obj.FReceives = 1) and (Obj.FReleases = 1), 'One receive and release');
          if I = 2 then Check(Obj.FBound = 224, 'Keyboard allocation bound')
          else Check(Obj.FBound = 337 + I, 'Explicit report allocation bound');
        end
        else Check((Obj.FReceives = 0) and (Obj.FReleases = 0), 'No cleanup of unacquired source');
        if J = 0 then Check(Data[mstTrack2] = '123', 'Complete component/adapter/source chain');
        Raised := False;
        Data[mstTrack1] := ''; Data[mstTrack2] := '123'; Data[mstTrack3] := '';
        try Data := C.WriteTracks([mstTrack2], Data);
        except on E: EMagStripeError do Raised := True; end;
        Check(Raised and (Obj.FAcquires = 1), 'Read-only capability refuses write before source I/O');
      finally C.Free; end;
      Device := nil;
      Source := nil;
    end;
  for I := 0 to 336 do
  begin
    B := HidFixture;
    SetLength(B, I);
    Raised := False;
    try Data := TMagTekFrameCodec.DecodeHid(B, [mstTrack2]);
    except on E: EMagStripeError do Raised := True; end;
    Check(Raised, 'Every truncated HID size refused');
  end;
  for I := 0 to 1 do
  begin
    Obj := TFakeSource.Create;
    Source := Obj;
    Obj.FBytes := HidFixture;
    Obj.FReleaseFail := I = 1;
    Device := TMagTekReadAdapter.Create(Source, False);
    Check(Obj.FAcquires = 0, 'Adapter construction does not acquire');
    Raised := False;
    try Data := Device.Read([mstTrack2], 4321);
    except on E: EMagStripeError do Raised := True; end;
    Check(Raised and (Obj.FReceives = 0), 'Direct read requires acquisition');
    Device.Acquire;
    Raised := False;
    try Device.Acquire;
    except on E: EMagStripeError do Raised := True; end;
    Check(Raised and (Obj.FAcquires = 1), 'Adapter nested acquisition refused');
    Device := nil;
    Check(Obj.FReleases = 1, 'Destructor best-effort cleanup including release failure');
    Source := nil;
  end;
  Raised := False;
  try Device := TMagTekReadAdapter.Create(nil, False);
  except on E: EMagStripeError do Raised := True; end;
  Check(Raised, 'Nil frame source refused');
  Obj := TFakeSource.Create;
  Source := Obj;
  Raised := False;
  try Device := TMagTekReadAdapter.Create(Source, True, True);
  except on E: EMagStripeError do Raised := True; end;
  Check(Raised and (Obj.FAcquires = 0), 'Keyboard report-ID configuration refused without I/O');
  Source := nil;
  Writeln('PASS: MagTek fixed HID/default keyboard codecs and full read adapter chains.');
end;

begin
  try
    TrackTests;
    FinancialTests;
    ComponentTests;
    FrameTests;
    Writeln('PASS: 4 magstripe test groups; ', Assertions, ' assertions.');
  except
    on E: Exception do
    begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end;
  end;
end.
