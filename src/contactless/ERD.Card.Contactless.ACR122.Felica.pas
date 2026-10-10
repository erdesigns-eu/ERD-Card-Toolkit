unit ERD.Card.Contactless.ACR122.Felica;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Transport, ERD.Card.Contactless.Felica;

type
  /// <summary>Explicit PN532 FeliCa bitrate; no reader-brand inference or automatic fallback.</summary>
  TFelicaBitrate = (
    /// <summary>212 kilobits per second, PN532 BrTy 01.</summary>
    fbr212,
    /// <summary>424 kilobits per second, PN532 BrTy 02.</summary>
    fbr424);

  /// <summary>Opt-in ACR122U/PN532 FF00 direct-transmit FeliCa adapter with bounded timing and zero retries.</summary>
  /// <remarks>Uses InListPassiveTarget and InDataExchange; FeliCa length/CRC framing is separate from raw Type A.
  /// RF timing/retry configuration persists until reader reset or deliberate reconfiguration. One target must be present.</remarks>
  TAcr122FelicaReader = class(TInterfacedObject, IFelicaReader)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FActive, FSelected: Boolean;
    FBitrate: TFelicaBitrate;
    function Send(const AData: TBytes; const ACode: Byte): TBytes;
  public
    /// <summary>Retains a connected exclusive direct-transmit transport without performing I/O.</summary>
    /// <param name="ATransport">Non-nil PC/SC transport supporting ICardTransaction.</param>
    /// <param name="ABitrate">Explicit 212 or 424 kilobit polling; defaults to 212.</param>
    constructor Create(const ATransport: ICardTransport;
      const ABitrate: TFelicaBitrate = fbr212);
    /// <summary>Best-effort cleanup; use EndSession to observe cleanup failures.</summary>
    destructor Destroy; override;
    /// <summary>Acquires exclusivity and configures finite 409.6 ms RF timeout, zero communication/activation retries.</summary>
    procedure BeginSession;
    /// <summary>Turns RF off and releases exclusivity even after cleanup failure.</summary>
    procedure EndSession;
    /// <summary>Cycles RF and polls one target with explicit system-code request and one time slot.</summary>
    /// <param name="ASystemCode">Explicit big-endian system code or FFFF wildcard.</param>
    /// <returns>Owned eight-byte IDm/PMm and returned system code.</returns>
    function Activate(const ASystemCode: Word): TFelicaTarget;
    /// <summary>Transmits one FeliCa frame through PN532 InDataExchange without retries.</summary>
    /// <param name="AFrame">Complete length-prefixed frame of 2..252 bytes; no RF CRC supplied.</param>
    /// <returns>Independent complete FeliCa response after native status checks.</returns>
    function Exchange(const AFrame: TBytes): TBytes;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

procedure Invalid;
begin
  raise EFelicaError.Create('Invalid ACR122 FeliCa operation or response.');
end;

constructor TAcr122FelicaReader.Create(const ATransport: ICardTransport;
  const ABitrate: TFelicaBitrate);
var
  Tx: ICardTransaction;
begin
  inherited Create;
  if (ATransport = nil) or not Supports(ATransport, ICardTransaction, Tx) or
    not(ABitrate in [fbr212, fbr424]) then
    Invalid;
  FTransport := ATransport;
  FBitrate := ABitrate;
end;

destructor TAcr122FelicaReader.Destroy;
begin
  if FActive then
    try
      EndSession;
    except
    end;
  inherited Destroy;
end;

function TAcr122FelicaReader.Send(const AData: TBytes;
  const ACode: Byte): TBytes;
var
  Wire: TBytes;
  Response: TApduResponse;
begin
  Result := nil;
  if (Length(AData) < 2) or (Length(AData) > 255) or (AData[0] <> $D4) then
    Invalid;
  SetLength(Wire, Length(AData) + 5);
  Wire[0] := $FF;
  Wire[4] := Length(AData);
  Move(AData[0], Wire[5], Length(AData));
  Response := TApduCodec.DecodeResponse(FTransport.Exchange(Wire));
  if (Response.StatusWord <> $9000) or (Length(Response.Data) < 2) or
    (Response.Data[0] <> $D5) or (Response.Data[1] <> ACode) then
    Invalid;
  Result := Copy(Response.Data, 2, Length(Response.Data) - 2);
end;

procedure TAcr122FelicaReader.BeginSession;
begin
  if FActive or not Supports(FTransport, ICardTransaction, FTransaction) then
    Invalid;
  try
    FTransaction.BeginTransaction;
  except
    FTransaction := nil;
    raise;
  end;
  FActive := True;
  FSelected := False;
  try
    if Length(Send(HexToBytes('D43202000B0D'), $33)) <> 0 then
      Invalid;
    if Length(Send(HexToBytes('D4320400'), $33)) <> 0 then
      Invalid;
    if Length(Send(HexToBytes('D43205000000'), $33)) <> 0 then
      Invalid;
  except
    try
      EndSession;
    except
    end;
    raise;
  end;
end;

procedure TAcr122FelicaReader.EndSession;
var
  Tx: ICardTransaction;
  Succeeded: Boolean;
begin
  if not FActive then
    Invalid;
  Tx := FTransaction;
  Succeeded := False;
  try
    try
      if Length(Send(HexToBytes('D4320100'), $33)) <> 0 then
        Invalid;
      Succeeded := True;
    finally
      FActive := False;
      FSelected := False;
      FTransaction := nil;
      if Succeeded then
        Tx.EndTransaction
      else
        try
          Tx.EndTransaction;
        except
        end;
    end;
  finally
    Tx := nil;
  end;
end;

function TAcr122FelicaReader.Activate(const ASystemCode: Word): TFelicaTarget;
var
  Wire, Data: TBytes;
begin
  Result := Default (TFelicaTarget);
  if not FActive then
    Invalid;
  FSelected := False;
  if Length(Send(HexToBytes('D4320100'), $33)) <> 0 then
    Invalid;
  if Length(Send(HexToBytes('D4320101'), $33)) <> 0 then
    Invalid;
  Wire := HexToBytes('D44A010100FFFF0100');
  Wire[3] := 1 + Ord(FBitrate);
  Wire[5] := ASystemCode shr 8;
  Wire[6] := ASystemCode and $FF;
  Data := Send(Wire, $4B);
  if (Length(Data) <> 22) or (Data[0] <> 1) or (Data[1] <> 1) or (Data[2] <> 20)
    or (Data[3] <> 1) then
    Invalid;
  Result.Idm := Copy(Data, 4, 8);
  Result.Pmm := Copy(Data, 12, 8);
  Result.SystemCode := (Word(Data[20]) shl 8) or Data[21];
  if (ASystemCode <> $FFFF) and (Result.SystemCode <> ASystemCode) then
    Invalid;
  FSelected := True;
end;

function TAcr122FelicaReader.Exchange(const AFrame: TBytes): TBytes;
var
  Wire, Data: TBytes;
begin
  Result := nil;
  if not FActive or not FSelected or (Length(AFrame) < 2) or
    (Length(AFrame) > 252) or (AFrame[0] <> Length(AFrame)) then
    Invalid;
  SetLength(Wire, Length(AFrame) + 3);
  Wire[0] := $D4;
  Wire[1] := $40;
  Wire[2] := 1;
  Move(AFrame[0], Wire[3], Length(AFrame));
  Data := Send(Wire, $41);
  if (Length(Data) < 3) or (Data[0] <> 0) then
    Invalid;
  Result := Copy(Data, 1, Length(Data) - 1);
  if Result[0] <> Length(Result) then
    Invalid;
end;

end.
