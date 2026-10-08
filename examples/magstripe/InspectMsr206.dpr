program InspectMsr206;

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
  ERD.Card.Bytes, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe,
  ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR206;

procedure Inspect;
var
  Component: TMagStripeReaderWriter;
  Data: TMagStripeTracks;
  Profile: TMsr206Profile;
  T: TMagStripeTrack;
  Timeout: Integer;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: InspectMsr206 --frame-hex HEX');
    Writeln('       InspectMsr206 --port COM12 --profile msr206|msr605 [--timeout 10000]');
    Writeln('Hardware mode reads one swipe using the explicit three-track ISO profile.');
    Writeln('Shows payload lengths only; never programs a card. Native COM requires Windows.');
    Exit;
  end;
  if (ParamCount=2) and (ParamStr(1)='--frame-hex') then
  begin
    if Length(ParamStr(2)) > Msr206MaxReadBytes*2 then
      raise EMagStripeError.Create('Hex frame exceeds ISO response capacity.');
    Data := TMsr206Codec.DecodeRead(HexToBytes(ParamStr(2)),[mstTrack1,mstTrack2,mstTrack3]);
  end
  else
  begin
    if not (ParamCount in [4,6]) or (ParamStr(1)<>'--port') or (ParamStr(3)<>'--profile') then
      raise EMagStripeError.Create('Invalid arguments; use --help.');
    if ParamStr(4)='msr206' then Profile:=msrp206ThreeTrackHL
    else if ParamStr(4)='msr605' then Profile:=msrp605ThreeTrack
    else raise EMagStripeError.Create('Unknown profile; no fallback is performed.');
    Timeout := 10000;
    if ParamCount=6 then
      if (ParamStr(5)<>'--timeout') or not TryStrToInt(ParamStr(6),Timeout) then
        raise EMagStripeError.Create('Invalid timeout option.');
    if (Timeout<1) or (Timeout>600000) then raise EMagStripeError.Create('Timeout must be 1..600000 ms.');
    Component := TMagStripeReaderWriter.Create(nil);
    try
      Component.Device := TMsr206MagStripeAdapter.Create(CreateWindowsMagStripeSerialPort(ParamStr(2)),Profile);
      Component.TimeoutMs := Timeout;
      Data := Component.ReadTracks([mstTrack1,mstTrack2,mstTrack3]);
    finally Component.Free; end;
  end;
  for T:=Low(TMagStripeTrack) to High(TMagStripeTrack) do
    Writeln('Track ',Ord(T)+1,' payload characters: ',Length(Data[T]));
end;

begin
  try Inspect;
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
