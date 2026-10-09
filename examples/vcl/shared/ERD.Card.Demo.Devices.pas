unit ERD.Card.Demo.Devices;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes;{$ELSE}System.SysUtils, System.Classes;{$ENDIF}

type
  /// <summary>Device discovery transport; discovery sends no card command and selects no reader.</summary>
  TCardDemoDeviceKind = (
    /// <summary>PC/SC reader names from the installed smart-card service.</summary>
    ddkPcsc,
    /// <summary>Present Windows COM aliases, without probing their attached devices.</summary>
    ddkSerial,
    /// <summary>Metadata-readable native HID top-level collections.</summary>
    ddkHid
  );
  /// <summary>One display label and its exact operational device address.</summary>
  TCardDemoDevice = record
    /// <summary>Human-readable reader/port/VID-PID-usage label; never a card identity.</summary>
    DisplayName: UnicodeString;
    /// <summary>Exact PC/SC name, COM alias or HID interface path passed to the chosen backend.</summary>
    Address: UnicodeString;
  end;
  /// <summary>Owned discovered devices; an empty list means no usable discovery results.</summary>
  TCardDemoDevices = array of TCardDemoDevice;
  /// <summary>Injectable discovery source used by each demo's own reader combobox.</summary>
  ICardDemoDeviceSource = interface
    ['{E0829D66-B9A5-479D-A900-976B5FD4ABAC}']
    /// <summary>Lists the explicit transport's devices without opening a card or programming anything.</summary>
    /// <param name="AKind">PC/SC, serial or HID discovery.</param>
    /// <returns>Owned labels/addresses; inaccessible HID metadata is omitted.</returns>
    function Enumerate(const AKind: TCardDemoDeviceKind): TCardDemoDevices;
  end;

/// <summary>Creates an inactive platform discovery source; enumeration happens on the worker.</summary>
/// <returns>Source using PC/SC discovery, Windows COM aliases and native HID metadata.</returns>
function CreateCardDemoDeviceSource: ICardDemoDeviceSource;

implementation

uses ERD.Card.PCSC.Reader, ERD.Card.PCSC.Api, ERD.Card.HID;

type
  TNativeSource = class(TInterfacedObject, ICardDemoDeviceSource)
    function Enumerate(const AKind: TCardDemoDeviceKind): TCardDemoDevices;
  end;

{$IFDEF MSWINDOWS}
function QueryDosDeviceW(Name: PWideChar; Buffer: PWideChar; Count: Cardinal): Cardinal;
  stdcall; external 'kernel32.dll' name 'QueryDosDeviceW';
function NativeLastError: Cardinal; stdcall; external 'kernel32.dll' name 'GetLastError';
{$ENDIF}

function SerialPorts: TCardDemoDevices;
{$IFDEF MSWINDOWS}
var Buffer: array of WideChar; Capacity,Used,Start,I: Cardinal; Name: UnicodeString; Port,N: Integer;
  Names: TStringList;
{$ENDIF}
begin
  Result := nil;
{$IFDEF MSWINDOWS}
  Capacity := 4096;
  while True do
  begin
    SetLength(Buffer,Capacity); Used := QueryDosDeviceW(nil,@Buffer[0],Capacity);
    if Used <> 0 then Break;
    if (NativeLastError <> 122) or (Capacity >= 65536) then raise EInvalidOpException.Create('Serial-port discovery failed.');
    Capacity := Capacity*2;
  end;
  if Used > Capacity then raise EInvalidOpException.Create('Invalid serial-port discovery length.');
  Names := TStringList.Create;
  try
    Names.Sorted := True; Names.Duplicates := dupIgnore; Start := 0;
    for I := 0 to Used-1 do
      if Buffer[I] = #0 then
      begin
        SetString(Name,PWideChar(@Buffer[Start]),I-Start); Start := I+1;
        if (Copy(Name,1,3) = 'COM') and TryStrToInt(string(Copy(Name,4,Length(Name))),Port) and
          (Port > 0) and (Name = 'COM'+IntToStr(Port)) then Names.Add(string(Name));
      end;
    SetLength(Result,Names.Count);
    for N := 0 to Names.Count-1 do begin Result[N].DisplayName := UnicodeString(Names[N]); Result[N].Address := UnicodeString(Names[N]); end;
  finally Names.Free; end;
{$ELSE}
  raise EInvalidOpException.Create('Native serial discovery requires Windows.');
{$ENDIF}
end;

function TNativeSource.Enumerate(const AKind: TCardDemoDeviceKind): TCardDemoDevices;
var Reader: TSmartCardReader; Names: TPcscReaderNames; Devices: THidDevices; I: Integer;
begin
  Result := nil;
  case AKind of
    ddkPcsc:
      begin
        Reader := TSmartCardReader.Create(nil);
        try Names := Reader.ListReaders; finally Reader.Free; end;
        SetLength(Result,Length(Names));
        for I := 0 to High(Names) do begin Result[I].DisplayName := Names[I]; Result[I].Address := Names[I]; end;
      end;
    ddkSerial: Result := SerialPorts;
    ddkHid:
      begin
        Devices := EnumerateWindowsHidDevices; SetLength(Result,Length(Devices));
        for I := 0 to High(Devices) do
        begin
          Result[I].DisplayName := UnicodeString('HID '+IntToStr(I+1)+' - VID '+IntToHex(Devices[I].VendorId,4)+
            ' PID '+IntToHex(Devices[I].ProductId,4)+' usage '+IntToHex(Devices[I].UsagePage,4)+':'+IntToHex(Devices[I].Usage,4));
          Result[I].Address := Devices[I].DevicePath;
        end;
      end;
  else raise EArgumentException.Create('Select the device discovery transport.'); end;
end;

function CreateCardDemoDeviceSource: ICardDemoDeviceSource;
begin Result := TNativeSource.Create; end;

end.
