unit ERD.Card.PCSC.Windows;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{$ALIGN 8}

interface

uses
  ERD.Card.PCSC.Api;

/// <summary>Creates the Windows Unicode PC/SC adapter without opening hardware.</summary>
/// <returns>A thread-safe adapter; on other platforms its operations report unsupported.</returns>
/// <remarks>Native calls and structures follow the Microsoft Windows SDK; no vendor DLL is required.</remarks>
function CreateSystemPcscApi: IPcscApi;

implementation

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Transport;

type
  TSystemPcscApi = class(TInterfacedObject, IPcscApi, IPcscMonitorApi)
  public
    function Establish(out AContext: TPcscHandle): Cardinal;
    function Release(const AContext: TPcscHandle): Cardinal;
    function ListReaders(const AContext: TPcscHandle;
      out ANames: TPcscReaderNames): Cardinal;
    function Connect(const AContext: TPcscHandle;
      const AReaderName: UnicodeString; const AShareMode: TPcscShareMode;
      const AProtocols: Cardinal; out ACard: TPcscHandle;
      out AActiveProtocol: Cardinal): Cardinal;
    function Disconnect(const ACard: TPcscHandle;
      const ADisposition: TPcscDisposition): Cardinal;
    function BeginTransaction(const ACard: TPcscHandle): Cardinal;
    function EndTransaction(const ACard: TPcscHandle;
      const ADisposition: TPcscDisposition): Cardinal;
    function Transmit(const ACard: TPcscHandle; const AProtocol: Cardinal;
      const ACommand: TBytes; const AMaxResponseBytes: Integer;
      out AResponse: TBytes): Cardinal;
    function ReadAtr(const ACard: TPcscHandle; out AAtr: TBytes): Cardinal;
    function WaitStatus(const AContext: TPcscHandle;
      const AReaderName: UnicodeString; const ACurrentState: Cardinal;
      const ATimeoutMs: Cardinal; out ASnapshot: TPcscReaderSnapshot): Cardinal;
    function WaitReaders(const AContext: TPcscHandle;
      const ACurrent: TPcscReaderSnapshots; const ATimeoutMs: Cardinal;
      out ASnapshots: TPcscReaderSnapshots): Cardinal;
    function Cancel(const AContext: TPcscHandle): Cardinal;
  end;

{$IFDEF MSWINDOWS}

const
  MaxReaderCharacters = 1048576;
  MaxDiscoveryAttempts = 4;

type
  TNativeIoRequest = record
    Protocol: Cardinal;
    Size: Cardinal;
  end;

  PNativeIoRequest = ^TNativeIoRequest;

  TNativeReaderState = record
    ReaderName: PWideChar;
    UserData: Pointer;
    CurrentState: Cardinal;
    EventState: Cardinal;
    AtrSize: Cardinal;
    Atr: array [0 .. PcscMaxAtrBytes - 1] of Byte;
  end;

  PNativeReaderState = ^TNativeReaderState;

  // WINAPI returns LONG status bits; Cardinal preserves the same 32-bit ABI.
function NativeEstablish(const AScope: Cardinal; const AReserved1: Pointer;
  const AReserved2: Pointer; out AContext: TPcscHandle): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardEstablishContext';
function NativeRelease(const AContext: TPcscHandle): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardReleaseContext';
function NativeListReaders(const AContext: TPcscHandle;
  const AGroups: PWideChar; const AReaders: PWideChar;
  var ACharacters: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardListReadersW';
function NativeConnect(const AContext: TPcscHandle; const AReader: PWideChar;
  const AShareMode: Cardinal; const AProtocols: Cardinal;
  out ACard: TPcscHandle; out AProtocol: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardConnectW';
function NativeDisconnect(const ACard: TPcscHandle;
  const ADisposition: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardDisconnect';
function NativeBeginTransaction(const ACard: TPcscHandle): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardBeginTransaction';
function NativeEndTransaction(const ACard: TPcscHandle;
  const ADisposition: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardEndTransaction';
function NativeTransmit(const ACard: TPcscHandle;
  const ASendPci: PNativeIoRequest; const ASend: Pointer;
  const ASendSize: Cardinal; const AReceivePci: PNativeIoRequest;
  const AReceive: Pointer; var AReceiveSize: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardTransmit';
function NativeStatus(const ACard: TPcscHandle; const AReaders: PWideChar;
  const AReaderSize: PCardinal; const AState: PCardinal;
  const AProtocol: PCardinal; const AAtr: Pointer; var AAtrSize: Cardinal)
  : Cardinal; stdcall; external 'winscard.dll' name 'SCardStatusW';
function NativeWaitStatus(const AContext: TPcscHandle; const ATimeout: Cardinal;
  const AStates: PNativeReaderState; const ACount: Cardinal): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardGetStatusChangeW';
function NativeCancel(const AContext: TPcscHandle): Cardinal; stdcall;
  external 'winscard.dll' name 'SCardCancel';

function NativeLayoutValid: Boolean;
begin
  Result := (SizeOf(TNativeIoRequest) = 8) and
    (((SizeOf(Pointer) = 4) and (SizeOf(TNativeReaderState) = 56)) or
    ((SizeOf(Pointer) = 8) and (SizeOf(TNativeReaderState) = 64)));
end;

function ParseReaderNames(const ABuffer: UnicodeString;
  const ACharacters: Cardinal; out ANames: TPcscReaderNames): Boolean;
var
  Position: Integer;
  Start: Integer;
  Count: Integer;
  Used: Integer;
  Names: TPcscReaderNames;
begin
  ANames := nil;
  if (ACharacters < 2) or (ACharacters > Cardinal(Length(ABuffer))) then
    Exit(False);
  Used := Integer(ACharacters);
  if (ABuffer[Used] <> #0) or (ABuffer[Used - 1] <> #0) then
    Exit(False);
  Position := 1;
  Count := 0;
  while Position < Used do
  begin
    if ABuffer[Position] = #0 then
      Break;
    Start := Position;
    while (Position < Used) and (ABuffer[Position] <> #0) do
      Inc(Position);
    SetLength(Names, Count + 1);
    Names[Count] := Copy(ABuffer, Start, Position - Start);
    Inc(Count);
    Inc(Position);
  end;
  // Only the final terminator may follow the last nonempty name.
  if Position <> Used then
  begin
    if (Count <> 0) or (Used <> 2) then
      Exit(False);
  end;
  ANames := Names;
  Result := True;
end;
{$ENDIF}

function CreateSystemPcscApi: IPcscApi;
begin
  Result := TSystemPcscApi.Create;
end;

function TSystemPcscApi.Establish(out AContext: TPcscHandle): Cardinal;
begin
  AContext := 0;
{$IFDEF MSWINDOWS}
  if not NativeLayoutValid then
    Exit(PcscInternalError);
  Result := NativeEstablish(0, nil, nil, AContext);
  if Result <> PcscSuccess then
    AContext := 0;
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.Release(const AContext: TPcscHandle): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := NativeRelease(AContext);
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.ListReaders(const AContext: TPcscHandle;
  out ANames: TPcscReaderNames): Cardinal;
{$IFDEF MSWINDOWS}
var
  Characters: Cardinal;
  Buffer: UnicodeString;
  Attempt: Integer;
{$ENDIF}
begin
  ANames := nil;
{$IFDEF MSWINDOWS}
  for Attempt := 1 to MaxDiscoveryAttempts do
  begin
    Characters := 0;
    Result := NativeListReaders(AContext, nil, nil, Characters);
    if Result <> PcscSuccess then
      Exit;
    if (Characters < 2) or (Characters > MaxReaderCharacters) then
      Exit(PcscInternalError);
    SetLength(Buffer, Integer(Characters));
    Result := NativeListReaders(AContext, nil, PWideChar(Buffer), Characters);
    if Result = PcscInsufficientBuffer then
      Continue;
    if Result <> PcscSuccess then
      Exit;
    if not ParseReaderNames(Buffer, Characters, ANames) then
      Exit(PcscInternalError);
    Exit(PcscSuccess);
  end;
  Result := PcscInsufficientBuffer;
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.Connect(const AContext: TPcscHandle;
  const AReaderName: UnicodeString; const AShareMode: TPcscShareMode;
  const AProtocols: Cardinal; out ACard: TPcscHandle;
  out AActiveProtocol: Cardinal): Cardinal;
{$IFDEF MSWINDOWS}
var
  ShareMode: Cardinal;
{$ENDIF}
begin
  ACard := 0;
  AActiveProtocol := 0;
{$IFDEF MSWINDOWS}
  if (AReaderName = '') or (Pos(#0, AReaderName) <> 0) or (AProtocols = 0) or
    ((AProtocols and not Cardinal(3)) <> 0) then
    Exit(PcscInvalidParameter);
  case AShareMode of
    psmExclusive:
      ShareMode := 1;
    psmShared:
      ShareMode := 2;
  else
    Exit(PcscInvalidParameter);
  end;
  Result := NativeConnect(AContext, PWideChar(AReaderName), ShareMode,
    AProtocols, ACard, AActiveProtocol);
  if Result <> PcscSuccess then
  begin
    ACard := 0;
    AActiveProtocol := 0;
  end;
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.Disconnect(const ACard: TPcscHandle;
  const ADisposition: TPcscDisposition): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := NativeDisconnect(ACard, Cardinal(Ord(ADisposition)));
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.BeginTransaction(const ACard: TPcscHandle): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := NativeBeginTransaction(ACard);
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.EndTransaction(const ACard: TPcscHandle;
  const ADisposition: TPcscDisposition): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := NativeEndTransaction(ACard, Cardinal(Ord(ADisposition)));
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.Transmit(const ACard: TPcscHandle;
  const AProtocol: Cardinal; const ACommand: TBytes;
  const AMaxResponseBytes: Integer; out AResponse: TBytes): Cardinal;
{$IFDEF MSWINDOWS}
var
  Request: TNativeIoRequest;
  Response: TBytes;
  Size: Cardinal;
{$ENDIF}
begin
  AResponse := nil;
{$IFDEF MSWINDOWS}
  if (Length(ACommand) = 0) or (Length(ACommand) > CardMaxCommandBytes) or
    (AMaxResponseBytes < 2) or (AMaxResponseBytes > CardMaxResponseBytes) or
    ((AProtocol <> PcscProtocolT0) and (AProtocol <> PcscProtocolT1)) then
    Exit(PcscInvalidParameter);
  Request.Protocol := AProtocol;
  Request.Size := SizeOf(Request);
  SetLength(Response, AMaxResponseBytes);
  Size := Cardinal(AMaxResponseBytes);
  Result := NativeTransmit(ACard, @Request, @ACommand[0],
    Cardinal(Length(ACommand)), nil, @Response[0], Size);
  // No retry, even if the driver reports a larger required receive capacity.
  if Result <> PcscSuccess then
    Exit;
  if Size > Cardinal(AMaxResponseBytes) then
    Exit(PcscInternalError);
  SetLength(Response, Integer(Size));
  AResponse := Response;
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.ReadAtr(const ACard: TPcscHandle; out AAtr: TBytes)
  : Cardinal;
{$IFDEF MSWINDOWS}
var
  Buffer: array [0 .. PcscMaxAtrBytes - 1] of Byte;
  Size: Cardinal;
{$ENDIF}
begin
  AAtr := nil;
{$IFDEF MSWINDOWS}
  Size := SizeOf(Buffer);
  Result := NativeStatus(ACard, nil, nil, nil, nil, @Buffer[0], Size);
  if Result <> PcscSuccess then
    Exit;
  if Size > Cardinal(Length(Buffer)) then
    Exit(PcscInternalError);
  SetLength(AAtr, Integer(Size));
  if Size <> 0 then
    Move(Buffer[0], AAtr[0], Integer(Size));
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.WaitStatus(const AContext: TPcscHandle;
  const AReaderName: UnicodeString; const ACurrentState: Cardinal;
  const ATimeoutMs: Cardinal; out ASnapshot: TPcscReaderSnapshot): Cardinal;
{$IFDEF MSWINDOWS}
var
  State: TNativeReaderState;
{$ENDIF}
begin
  ASnapshot := Default (TPcscReaderSnapshot);
{$IFDEF MSWINDOWS}
  if (AReaderName = '') or (Pos(#0, AReaderName) <> 0) or
    (ATimeoutMs = High(Cardinal)) then
    Exit(PcscInvalidParameter);
  State := Default (TNativeReaderState);
  State.ReaderName := PWideChar(AReaderName);
  State.CurrentState := ACurrentState and not PcscStateChanged;
  Result := NativeWaitStatus(AContext, ATimeoutMs, @State, 1);
  if Result <> PcscSuccess then
    Exit;
  if State.AtrSize > Cardinal(Length(State.Atr)) then
    Exit(PcscInternalError);
  ASnapshot.ReaderName := AReaderName;
  ASnapshot.State := State.EventState and not PcscStateChanged;
  SetLength(ASnapshot.Atr, Integer(State.AtrSize));
  if State.AtrSize <> 0 then
    Move(State.Atr[0], ASnapshot.Atr[0], Integer(State.AtrSize));
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.WaitReaders(const AContext: TPcscHandle;
  const ACurrent: TPcscReaderSnapshots; const ATimeoutMs: Cardinal;
  out ASnapshots: TPcscReaderSnapshots): Cardinal;
{$IFDEF MSWINDOWS}
var
  States: array of TNativeReaderState;
  I, J: Integer;
{$ENDIF}
begin
  ASnapshots := nil;
{$IFDEF MSWINDOWS}
  if not NativeLayoutValid then
    Exit(PcscInternalError);
  if (Length(ACurrent) < 1) or (Length(ACurrent) > 1025) or
    (ATimeoutMs = High(Cardinal)) then
    Exit(PcscInvalidParameter);
  SetLength(States, Length(ACurrent));
  for I := 0 to High(ACurrent) do
  begin
    if (ACurrent[I].ReaderName = '') or (Pos(#0, ACurrent[I].ReaderName) <> 0)
    then
      Exit(PcscInvalidParameter);
    for J := 0 to I - 1 do
      if ACurrent[J].ReaderName = ACurrent[I].ReaderName then
        Exit(PcscInvalidParameter);
    States[I].ReaderName := PWideChar(ACurrent[I].ReaderName);
    if ACurrent[I].ReaderName = PcscPnpNotification then
      States[I].CurrentState := ACurrent[I].State
    else
      States[I].CurrentState := ACurrent[I].State and not PcscStateChanged;
  end;
  Result := NativeWaitStatus(AContext, ATimeoutMs, @States[0], Length(States));
  if Result <> PcscSuccess then
    Exit;
  for I := 0 to High(States) do
    if States[I].AtrSize > PcscMaxAtrBytes then
      Exit(PcscInternalError);
  SetLength(ASnapshots, Length(States));
  for I := 0 to High(States) do
  begin
    ASnapshots[I].ReaderName := ACurrent[I].ReaderName;
    if ACurrent[I].ReaderName = PcscPnpNotification then
      ASnapshots[I].State := States[I].EventState
    else
      ASnapshots[I].State := States[I].EventState and not PcscStateChanged;
    SetLength(ASnapshots[I].Atr, States[I].AtrSize);
    if States[I].AtrSize > 0 then
      Move(States[I].Atr[0], ASnapshots[I].Atr[0], States[I].AtrSize);
  end;
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

function TSystemPcscApi.Cancel(const AContext: TPcscHandle): Cardinal;
begin
{$IFDEF MSWINDOWS}
  Result := NativeCancel(AContext);
{$ELSE}
  Result := PcscUnsupportedFeature;
{$ENDIF}
end;

end.
