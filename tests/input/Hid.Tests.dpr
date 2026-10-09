program HidTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils,Classes,{$ELSE}System.SysUtils,System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.HID;
type
  TDevice = class(TInterfacedObject,IHidReportDevice)
  public
    Opens,Closes,Reads,Writes: Integer;
    OpenFails,CloseFails,ReadFails,WriteFails,Writable,Active: Boolean;
    Info: THidDeviceInfo;
    Input,Retained: TBytes;
    Component: TUsbHidReaderWriter;
    function Open(const AWriteAccess: Boolean): THidDeviceInfo;
    procedure Close;
    function Receive(const K: THidReportKind; const Id: Byte; const Timeout: Cardinal): TBytes;
    procedure Send(const K: THidReportKind; const Data: TBytes; const Timeout: Cardinal);
  end;
var Checks: Integer;
procedure Check(const V: Boolean);
begin Inc(Checks); if not V then raise Exception.Create('HID contract assertion failed.'); end;
function TDevice.Open(const AWriteAccess: Boolean): THidDeviceInfo;
begin Check(not Active); Check(Component.Busy); Inc(Opens); if OpenFails then raise EHidError.Create('Open failed'); Active := True; Writable := AWriteAccess; Result := Info; end;
procedure TDevice.Close;
begin Check(Active); Inc(Closes); Active := False; if CloseFails then raise EHidError.Create('Close failed'); end;
function TDevice.Receive(const K: THidReportKind; const Id: Byte; const Timeout: Cardinal): TBytes;
begin Check(Active and not Writable); Check(Timeout = 123); Check(Id = 7); Inc(Reads); if ReadFails then raise EHidError.Create('Read failed'); Result := Input; end;
procedure TDevice.Send(const K: THidReportKind; const Data: TBytes; const Timeout: Cardinal);
var Failed: Boolean;
begin
  Check(Active and Writable); Check(Timeout = 123); Inc(Writes); Retained := Data;
  Failed := False; try Component.TimeoutMs := 9; except on E: EHidError do Failed := True; end; Check(Failed);
  Failed := False; try Component.Device := nil; except on E: EHidError do Failed := True; end; Check(Failed);
  if WriteFails then raise EHidError.Create('Sensitive transfer failure');
end;
procedure Run;
var K: THidReportKind; C: TUsbHidReaderWriter; Dev: TDevice; Device: IHidReportDevice;
  Data,ResultData: TBytes; I,J: Integer; Failed,Uncertain: Boolean;
begin
  for K := Low(THidReportKind) to High(THidReportKind) do
    for I := 0 to 11 do
    begin
      Dev := TDevice.Create; Device := Dev; C := TUsbHidReaderWriter.Create(nil); Dev.Component := C;
      try
        C.Device := Device; C.TimeoutMs := 123;
        Dev.Info.InputBytes := 4; Dev.Info.OutputBytes := 4; Dev.Info.FeatureBytes := 4; Dev.Input := HexToBytes('07010203'); Data := HexToBytes('07010203');
        Dev.OpenFails := I = 1; Dev.ReadFails := I = 2; Dev.CloseFails := I in [3,10]; Dev.WriteFails := I = 9;
        if I = 4 then Dev.Input[0] := 8;
        if I = 5 then SetLength(Dev.Input,3);
        if I = 6 then begin Dev.Info.InputBytes := 0; Dev.Info.FeatureBytes := 0; end;
        if I = 7 then SetLength(Data,3);
        if I = 11 then begin Dev.Info.OutputBytes := 4097; Dev.Info.FeatureBytes := 4097; end;
        Failed := False; Uncertain := False; ResultData := nil;
        try if I < 7 then ResultData := C.ReadReport(K,7) else C.SendReport(K,Data);
        except on E: EHidSendUncertain do begin Failed := True; Uncertain := True; Check(Pos('07010203',E.Message) = 0); end;
          on E: EHidError do Failed := True;
        end;
        Check(Failed = not (I in [0,8])); Check(Uncertain = (I in [9,10])); Check(not C.Busy and not Dev.Active);
        Check(Dev.Opens = 1); Check(Dev.Closes = Ord(I <> 1)); Check(Dev.Reads <= 1); Check(Dev.Writes <= 1);
        if I = 0 then begin Check(BytesEqual(ResultData,Dev.Input)); ResultData[1] := 99; Check(Dev.Input[1] = 1); end;
        if I in [7,11] then Check(Dev.Writes = 0);
        if I in [8,9,10] then begin Check(BytesEqual(Data,HexToBytes('07010203'))); for J := 0 to High(Dev.Retained) do Check(Dev.Retained[J] = 0); end;
      finally C.Free; Device := nil; end;
    end;
  C := TUsbHidReaderWriter.Create(nil);
  try
    Check(C.TimeoutMs = 3000); Check(not C.Busy); Failed := False;
    try C.ReadReport(hrkInterrupt,0); except on E: EHidError do Failed := True; end; Check(Failed);
    for I := 0 to 1 do begin Failed := False; try if I = 0 then C.TimeoutMs := 0 else C.TimeoutMs := 600001; except on E: EHidError do Failed := True; end; Check(Failed); end;
  finally C.Free; end;
{$IFNDEF MSWINDOWS}
  Failed := False; try EnumerateWindowsHidDevices; except on E: EHidError do Failed := True; end; Check(Failed);
  Failed := False; try CreateWindowsHidReportDevice('device'); except on E: EHidError do Failed := True; end; Check(Failed);
{$ENDIF}
end;
begin try Run; Writeln('PASS: ',Checks,' HID report assertions.'); except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end; end.
