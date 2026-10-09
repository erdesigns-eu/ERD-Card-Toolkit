program NativeHidTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses SysUtils,ERD.Card.Bytes,ERD.Card.HID;
procedure Configure(Mode: Integer); cdecl; external 'hid.dll' name 'HidTestConfigure';
function Count(Kind: Integer): Integer; cdecl; external 'hid.dll' name 'HidTestCount';
var Checks: Integer;
procedure Check(const V: Boolean);
begin Inc(Checks); if not V then raise Exception.Create('Native HID ABI/ownership assertion failed.'); end;
procedure Run;
var M,W: Integer; C: TUsbHidReaderWriter; D: IHidReportDevice; Data: TBytes; Kind: THidReportKind;
  Failed,Uncertain: Boolean; Devices: THidDevices;
begin
  Configure(0); Devices := EnumerateWindowsHidDevices;
  Check(Length(Devices) = 1); Check(Devices[0].DevicePath = 'hid:test');
  Check((Devices[0].VendorId = $1234) and (Devices[0].ProductId = $5678));
  Check((Devices[0].UsagePage = $FF00) and (Devices[0].InputBytes = 4));
  Check((Count(6) = 1) and (Count(2) = 1) and (Count(5) = 1));
  for M := 1 to 3 do begin Configure(M); Devices := EnumerateWindowsHidDevices; Check(Length(Devices) = 0); Check(Count(5) = 1); end;
  Configure(12); Failed := False; try EnumerateWindowsHidDevices; except on E: EHidError do Failed := True; end; Check(Failed);
  for Kind := Low(THidReportKind) to High(THidReportKind) do
    for W := 0 to 1 do
      for M := 0 to 13 do
      begin
        Configure(M); D := CreateWindowsHidReportDevice('hid:test'); C := TUsbHidReaderWriter.Create(nil);
        try
          C.Device := D; C.TimeoutMs := 123; Failed := False; Uncertain := False;
          try if W = 0 then Data := C.ReadReport(Kind,7) else C.SendReport(Kind,HexToBytes('07010203'));
          except on E: EHidSendUncertain do begin Failed := True; Uncertain := True; end; on E: EHidError do Failed := True; end;
          if Kind = hrkInterrupt then Check(Failed = (M in [1,2,3,5,7,8,9,11,13]))
          else Check(Failed = (M in [1,2,3,4,11]));
          Check(Uncertain = (Failed and (W = 1) and not (M in [1,2,3])));
          Check(not C.Busy); Check(Count(0) = 1); Check(Count(6) = Ord(M <> 1));
          if not Failed and (W = 0) then Check(BytesEqual(Data,HexToBytes('07010203')));
          if (Kind = hrkInterrupt) and (M in [7,8]) then Check((Count(10) = 1) and (Count(11) = 1));
          if (Kind = hrkInterrupt) and (M = 13) then Check((Count(10) = 1) and (Count(11) = 2));
          if (Kind = hrkInterrupt) and (M = 6) then Check((Count(10) = 0) and (Count(11) = 1));
          if (Kind = hrkInterrupt) and not (M in [1,2,3]) then Check(Count(7) = 1);
          Check((Count(8) <= 1) and (Count(9) <= 1) and (Count(3) <= 1) and (Count(4) <= 1));
        finally C.Free; D := nil; end;
      end;
end;
begin try Run; Writeln('PASS: ',Checks,' native HID ABI shim assertions (no Windows driver).'); except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); DumpExceptionBackTrace(Output); ExitCode := 1; end; end; end.
