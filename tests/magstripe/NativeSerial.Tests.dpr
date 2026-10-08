program NativeSerialTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR206;

// Linux test-shim exports only; never run this project against Windows kernel32.
procedure Configure(const AMode: Integer); cdecl;
  external 'kernel32.dll' name 'CardSerialTestConfigure';
function Count(const AKind: Integer): Integer; cdecl;
  external 'kernel32.dll' name 'CardSerialTestCount';
function Deadline: Cardinal; cdecl;
  external 'kernel32.dll' name 'CardSerialTestDeadline';

var
  Assertions: Integer;

procedure Check(const ACondition: Boolean; const ALabel: string);
begin
  Inc(Assertions);
  if not ACondition then raise Exception.Create(ALabel);
end;

procedure NativeTests;
var
  Port: IMagStripeSerialPort;
  I, Before: Integer;
  Raised: Boolean;
  Value: Byte;
  Component: TMagStripeReaderWriter;
  Data: TMagStripeTracks;
  Receipt: TMagStripeProgrammingReceipt;
begin
  Configure(0);
  Port := CreateWindowsMagStripeSerialPort('com12');
  Check(Count(0)=0,'Inactive factory');
  Check(Port.NowMs=UInt64($100000001),'Native 64-bit monotonic clock');
  Port.Open;
  Check((Count(0)=1) and (Count(2)=1) and (Count(3)=1) and (Count(4)=1), 'Native Unicode exclusive handle/DCB/timeouts/RX purge');
  Check(Deadline=1000,'Initial bounded serial timeout');
  Raised := False;
  try Port.Open; except on E: EMagStripeError do Raised:=True; end;
  Check(Raised and (Count(0)=1),'Nested native opening refused');
  Port.Send(HexToBytes('1B65'),37);
  Check((Count(5)=1) and (Deadline=37),'One native send with supplied deadline');
  Value := Port.ReceiveByte(19);
  Check((Value=$79) and (Count(6)=1) and (Deadline=19),'One-byte native receive and remaining deadline');
  Port.DiscardInput;
  Check(Count(4)=2,'Native RX-only purge');
  for I := 0 to 3 do
  begin
    Raised := False;
    Before := Count(5);
    try
      case I of
        0: Port.Send(nil,1);
        1: Port.Send(HexToBytes('1B65'),0);
        2: Port.Send(HexToBytes('1B65'),600001);
        3: Value := Port.ReceiveByte(0);
      end;
    except on E: EMagStripeError do Raised:=True; end;
    Check(Raised and (Count(5)=Before),'Native local preflight without send');
  end;
  Port.Close;
  Check(Count(1)=1,'Native handle closed once');
  Port := nil;
  Check(Count(1)=1,'Destructor never double closes');
  for I := 1 to 4 do
  begin
    Configure(I);
    Port := CreateWindowsMagStripeSerialPort('COM12');
    Raised := False;
    try Port.Open; except on E: EMagStripeError do Raised:=True; end;
    Check(Raised,'Every native setup failure reported');
    if I=1 then Check(Count(1)=0,'Failed CreateFile grants no handle')
    else Check(Count(1)=1,'Acquired setup-failure handle closed');
    Port:=nil;
  end;
  for I := 5 to 11 do
  begin
    Configure(0);
    Port := CreateWindowsMagStripeSerialPort('COM12');
    Port.Open;
    Configure(I);
    Raised := False;
    try
      if I in [5,10,11] then Port.Send(HexToBytes('1B65'),20)
      else if I=9 then Port.Close
      else Value:=Port.ReceiveByte(20);
    except on E: EMagStripeError do Raised:=True; end;
    Check(Raised,'Native short/overreported/failed/timeout I/O or failed close');
    if I in [5,10,11] then Check(Count(5)=1,'Never continue or replay a partial native write')
    else if I<>9 then Check(Count(6)=1,'Never repeat invalid/failed native receive');
    Port:=nil;
    Check(Count(1)=1,'Cleanup relinquishes native ownership once, including close failure');
  end;

  Configure(20);
  Port := CreateWindowsMagStripeSerialPort('COM12');
  Component := TMagStripeReaderWriter.Create(nil);
  try
    Component.Device := TMsr206MagStripeAdapter.Create(Port,msrp206ThreeTrackHL);
    Component.TimeoutMs := 4321;
    Data[mstTrack1] := '01'; Data[mstTrack2] := '23'; Data[mstTrack3] := '45';
    Receipt := Component.ProgramTracks([mstTrack1,mstTrack2,mstTrack3],Data,mscHigh);
    Check((Receipt.DeviceStatus=$30) and not Receipt.HostReadBackVerified,'Full component/adapter/native COM chain reports status only');
    Check((Count(0)=1) and (Count(1)=1) and (Count(5)=9) and (Count(6)=18), 'Actual native calls follow exact protocol and cleanup without replay');
    Check(Count(4)=2,'Open and operation each discard RX only');
  finally Component.Free; end;
  Port:=nil;
end;

begin
  try
    NativeTests;
    Writeln('PASS: ',Assertions,' assertions against Linux native Windows serial ABI shim.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
