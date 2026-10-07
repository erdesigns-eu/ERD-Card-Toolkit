program InspectMagStripe;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.MagStripe.Tracks;

procedure Inspect;
var
  Track: TMagStripeTrack;
  Payload, BitText: string;
  Encoded: TBytes;
  I, Number: Integer;
begin
  if (ParamCount = 0) or ((ParamCount = 1) and (ParamStr(1) = '--help')) then
  begin
    Writeln('Usage: InspectMagStripe --track 1|2|3 --frame "SSpayload?"');
    Writeln('       InspectMagStripe --track 1|2|3 --bits "0101..."');
    Writeln('Canonical Track 3 SS is semicolon; bit input excludes clocking zeros.');
    Writeln('Reports lengths and LRC only; no hardware or payload output.');
    Exit;
  end;
  if (ParamCount <> 4) or (ParamStr(1) <> '--track') or
    not TryStrToInt(ParamStr(2), Number) then
    raise EMagStripeFormatError.Create('Invalid arguments; use --help.');
  case Number of
    1: Track := mstTrack1;
    2: Track := mstTrack2;
    3: Track := mstTrack3;
  else
    raise EMagStripeFormatError.Create('Track must be 1, 2 or 3.');
  end;
  if ParamStr(3) = '--frame' then
    Payload := TMagStripeTrackCodec.Unframe(Track, ParamStr(4))
  else if ParamStr(3) = '--bits' then
  begin
    BitText := ParamStr(4);
    if Length(BitText) > (TMagStripeTrackCodec.MaxPayloadLength(Track) + 3) * 7 then
      raise EMagStripeFormatError.Create('Bit input exceeds track capacity.');
    SetLength(Encoded, Length(BitText));
    for I := 1 to Length(BitText) do
    begin
      if not CharInSet(BitText[I], ['0', '1']) then
        raise EMagStripeFormatError.Create('Bits must contain only zero and one.');
      Encoded[I - 1] := Ord(BitText[I]) - Ord('0');
    end;
    Payload := TMagStripeTrackCodec.DecodeBits(Track, Encoded);
  end
  else raise EMagStripeFormatError.Create('Invalid input mode; use --help.');
  Encoded := TMagStripeTrackCodec.EncodeBits(Track, Payload);
  Writeln('Track: ', Number, ' Payload characters: ', Length(Payload));
  Writeln('Frame bits: ', Length(Encoded), ' LRC symbol: ', IntToHex(TMagStripeTrackCodec.LrcSymbol(Track, Payload), 2));
  if ParamStr(3) = '--bits' then Writeln('Input parity and LRC: verified')
  else Writeln('Text has no source parity/LRC; output integrity bits were generated.');
end;

begin
  try Inspect;
  except
    on E: Exception do
    begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end;
  end;
end.
