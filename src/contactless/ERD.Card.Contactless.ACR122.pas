unit ERD.Card.Contactless.ACR122;

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
  ERD.Card.Transport, ERD.Card.Contactless.Raw;

type
  /// <summary>Opt-in ACS ACR122U/PN532 direct-transmit adapter for raw Type A frames.</summary>
  /// <remarks>Requires a connected PICC ICardTransport supporting ICardTransaction and FF 00 direct transmit.
  /// Use on one caller thread with one card in the field. No automatic reader detection or Escape/Control fallback.
  /// Sessions set bounded PN532 RF timings and zero communication/activation retries; these settings persist
  /// until reader reset or deliberate reconfiguration. Temporary CRC/framing registers are restored on release.
  /// The caller must dedicate the reader to this adapter during use. Construction performs no I/O.</remarks>
  TAcr122RawReader = class(TInterfacedObject, IRawContactlessReader)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FActive, FHasRegisters: Boolean;
    FResponseTimeoutCode: Byte;
    FSkipAutomaticRats, FParametersChanged: Boolean;
    FTxMode, FRxMode, FBitFraming: Byte;
    function Send(const APayload: TBytes; const AResponseCode: Byte): TBytes;
    procedure RequireActive;
    procedure RestoreRegisters;
    procedure StopRf;
    procedure RestoreParameters;
    procedure ReleaseHardware;
    procedure SetRawFraming(const ALastBits: Byte);
  public
    /// <summary>Retains a connected injectable transport; does not open the hardware.</summary>
    /// <param name="ATransport">Non-nil transport supporting exclusive transactions.</param>
    /// <param name="AResponseTimeoutCode">PN532 non-DEP timeout code 01..10 hex; default 0D is 409.6 ms, 10 is 3276.8 ms.</param>
    /// <param name="ASkipAutomaticRats">Use PN532 initiator parameters 24 during sessions, then restore documented baseline 34 on release.</param>
    /// <exception cref="EContactlessError">Transport is nil, lacks transactions, or timeout code is zero/out of range.</exception>
    /// <remarks>For Gen3/Gen4 raw commands use code 10 and skip automatic RATS; no infinite timeout is accepted.</remarks>
    constructor Create(const ATransport: ICardTransport;
      const AResponseTimeoutCode: Byte = $0D;
      const ASkipAutomaticRats: Boolean = False);
    /// <summary>Attempts to release an abandoned active session without raising; explicit EndSession is required to observe failures.</summary>
    destructor Destroy; override;
    /// <summary>Acquires a transaction and sets bounded RF timing and zero PN532 retries.</summary>
    /// <exception cref="EContactlessError">A session is already active or the reader rejects configuration.</exception>
    /// <remarks>RF activation is performed separately by Activate; acquisition/configuration failures release the transaction.</remarks>
    procedure BeginSession;
    /// <summary>Restores saved CRC/framing registers and releases exclusivity even when restoration fails.</summary>
    /// <exception cref="EContactlessError">No session is active or reader cleanup fails.</exception>
    /// <remarks>Turns off the RF field to clear temporary unlock state. Timeout/retry settings remain as documented on the class.</remarks>
    procedure EndSession;
    /// <summary>Cycles the RF field, selects one 106-kbit/s Type A target and configures manual CRC framing.</summary>
    /// <returns>Independent freshly selected four, seven or ten-byte UID.</returns>
    /// <exception cref="EContactlessError">Session is inactive, target/ATS framing is invalid or a reader command fails.</exception>
    /// <remarks>Uses PN532 InListPassiveTarget rather than reader-cached FF CA UID data; destroys prior card unlock/authentication state.</remarks>
    function Activate: TBytes;
    /// <summary>Sends one PN532 InCommunicateThru frame with explicit bit count and manual CRC.</summary>
    /// <param name="AFrame">One to 253 caller-owned bytes, including any required CRC; never modified.</param>
    /// <param name="ABitCount">Valid bits, using all preceding bytes and one to eight bits in the final byte.</param>
    /// <returns>Independent received bytes and exact bit count; PN532 status 01 is an explicit timeout.</returns>
    /// <exception cref="EContactlessError">Frame/session is invalid, PN532 status is not success/timeout, or response framing is malformed.</exception>
    /// <remarks>Does not retry, reset RF, insert CRC or translate four-bit acknowledgments into full bytes.</remarks>
    function Exchange(const AFrame: TBytes; const ABitCount: Integer)
      : TRawRfResponse;
    /// <summary>Configured bounded non-DEP response timeout code, immutable after construction.</summary>
    property ResponseTimeoutCode: Byte read FResponseTimeoutCode;
    /// <summary>Whether sessions disable automatic RATS and restore PN532 baseline parameters on release.</summary>
    property SkipAutomaticRats: Boolean read FSkipAutomaticRats;
  end;

implementation

uses ERD.Card.APDU, ERD.Card.Bytes, ERD.Card.Contactless;

procedure RawFailure(const AReason: string);
begin
  raise EContactlessError.Create('ACR122 raw reader failed: ' + AReason + '.');
end;

constructor TAcr122RawReader.Create(const ATransport: ICardTransport;
  const AResponseTimeoutCode: Byte; const ASkipAutomaticRats: Boolean);
var
  Transaction: ICardTransaction;
begin
  inherited Create;
  if (ATransport = nil) or not Supports(ATransport, ICardTransaction,
    Transaction) then
    RawFailure('exclusive transport required');
  if (AResponseTimeoutCode = 0) or (AResponseTimeoutCode > $10) then
    RawFailure('invalid bounded timeout');
  FTransport := ATransport;
  FResponseTimeoutCode := AResponseTimeoutCode;
  FSkipAutomaticRats := ASkipAutomaticRats;
end;

destructor TAcr122RawReader.Destroy;
begin
  if FActive then
    try
      EndSession;
    except
      // Destruction is best effort; explicit release is the observable cleanup path.
    end;
  inherited Destroy;
end;

function TAcr122RawReader.Send(const APayload: TBytes;
  const AResponseCode: Byte): TBytes;
var
  Wire, RawResponse: TBytes;
  Response: TApduResponse;
begin
  Result := nil;
  if (Length(APayload) < 2) or (Length(APayload) > 255) or (APayload[0] <> $D4)
  then
    RawFailure('invalid direct-transmit payload');
  SetLength(Wire, 5 + Length(APayload));
  Wire[0] := $FF;
  Wire[1] := 0;
  Wire[2] := 0;
  Wire[3] := 0;
  Wire[4] := Byte(Length(APayload));
  Move(APayload[0], Wire[5], Length(APayload));
  try
    RawResponse := FTransport.Exchange(Wire);
    Response := TApduCodec.DecodeResponse(RawResponse);
  finally
    FillChar(Wire[0], Length(Wire), 0);
    if Length(RawResponse) > 0 then
      FillChar(RawResponse[0], Length(RawResponse), 0);
  end;
  try
    if Response.StatusWord <> $9000 then
      raise EContactlessStatusError.Create(Response.StatusWord);
    if (Length(Response.Data) < 2) or (Response.Data[0] <> $D5) or
      (Response.Data[1] <> AResponseCode) then
      RawFailure('unexpected PN532 response');
    Result := Copy(Response.Data, 2, Length(Response.Data) - 2);
  finally
    if Length(Response.Data) > 0 then
      FillChar(Response.Data[0], Length(Response.Data), 0);
  end;
end;

procedure TAcr122RawReader.RequireActive;
begin
  if not FActive then
    RawFailure('session not active');
end;

procedure TAcr122RawReader.BeginSession;
var
  Data, Timing: TBytes;
begin
  if FActive then
    RawFailure('session already active');
  if not Supports(FTransport, ICardTransaction, FTransaction) then
    RawFailure('transaction unavailable');
  try
    FTransaction.BeginTransaction;
  except
    FTransaction := nil;
    raise;
  end;
  FActive := True;
  try
    // RFConfiguration: bounded ATR/non-DEP timing, no communication retry, one activation attempt.
    Timing := HexToBytes('D43202000B00');
    Timing[5] := FResponseTimeoutCode;
    Data := Send(Timing, $33);
    if Length(Data) <> 0 then
      RawFailure('RF timing response contains data');
    Data := Send(HexToBytes('D4320400'), $33);
    if Length(Data) <> 0 then
      RawFailure('RF retry response contains data');
    Data := Send(HexToBytes('D43205000000'), $33);
    if Length(Data) <> 0 then
      RawFailure('activation retry response contains data');
    if FSkipAutomaticRats then
    begin
      FParametersChanged := True;
      // Dispatch may change reader state even if the response is lost.
      Data := Send(HexToBytes('D41224'), $13);
      if Length(Data) <> 0 then
        RawFailure('parameter response contains data');
    end;
  except
    try
      EndSession;
    except
      // Preserve configuration failure; EndSession still attempts transaction release.
    end;
    raise;
  end;
end;

procedure TAcr122RawReader.RestoreRegisters;
var
  Wire, Data: TBytes;
begin
  if not FHasRegisters then
    Exit;
  Wire := HexToBytes('D408630200630300633D00');
  Wire[4] := FTxMode;
  Wire[7] := FRxMode;
  Wire[10] := FBitFraming and $7F;
  // Never replay the write-only StartSend strobe.
  Data := Send(Wire, $09);
  if Length(Data) <> 0 then
    RawFailure('register restoration response contains data');
  FHasRegisters := False;
end;

procedure TAcr122RawReader.EndSession;
var
  Succeeded: Boolean;
  Transaction: ICardTransaction;
begin
  RequireActive;
  Transaction := FTransaction;
  Succeeded := False;
  try
    try
      ReleaseHardware;
      Succeeded := True;
    finally
      FActive := False;
      FHasRegisters := False;
      FParametersChanged := False;
      FTransaction := nil;
      if Succeeded then
        Transaction.EndTransaction
      else
        try
          Transaction.EndTransaction;
        except
          // Preserve the register restoration failure over a secondary release failure.
        end;
    end;
  finally
    Transaction := nil;
  end;
end;

procedure TAcr122RawReader.RestoreParameters;
var
  Data: TBytes;
begin
  if not FParametersChanged then
    Exit;
  Data := Send(HexToBytes('D41234'), $13);
  if Length(Data) <> 0 then
    RawFailure('baseline parameter response contains data');
  FParametersChanged := False;
end;

procedure TAcr122RawReader.ReleaseHardware;
var
  Restored, Stopped: Boolean;
begin
  Restored := False;
  Stopped := False;
  try
    try
      RestoreRegisters;
      Restored := True;
    finally
      if Restored then
        StopRf
      else
        try
          StopRf;
        except
          // Preserve restoration failure while attempting to clear volatile card state.
        end;
    end;
    Stopped := True;
  finally
    if Stopped then
      RestoreParameters
    else
      try
        RestoreParameters;
      except
        // Still release exclusivity; preserve the primary framing/RF-off error.
      end;
  end;
end;

procedure TAcr122RawReader.StopRf;
var
  Data: TBytes;
begin
  Data := Send(HexToBytes('D4320100'), $33);
  if Length(Data) <> 0 then
    RawFailure('RF-off response contains data');
end;

procedure TAcr122RawReader.SetRawFraming(const ALastBits: Byte);
var
  Wire, Data: TBytes;
begin
  Wire := HexToBytes('D408630200630300633D00');
  Wire[4] := FTxMode and $7F;
  Wire[7] := FRxMode and $7F;
  Wire[10] := (FBitFraming and $08) or ALastBits; // RxAlign=0 and StartSend=0.
  Data := Send(Wire, $09);
  if Length(Data) <> 0 then
    RawFailure('raw framing response contains data');
end;

function TAcr122RawReader.Activate: TBytes;
var
  Data, Registers: TBytes;
  Size, AfterUid, AtsSize: Integer;
begin
  Result := nil;
  RequireActive;
  RestoreRegisters;
  Data := Send(HexToBytes('D4320100'), $33);
  if Length(Data) <> 0 then
    RawFailure('RF-off response contains data');
  TThread.Sleep(10);
  // Allow card power-down before fresh selection; not a retry.
  Data := Send(HexToBytes('D4320101'), $33);
  if Length(Data) <> 0 then
    RawFailure('RF-on response contains data');
  Data := Send(HexToBytes('D44A0100'), $4B);
  if (Length(Data) < 6) or (Data[0] <> 1) or (Data[1] <> 1) then
    RawFailure('single Type A target not found');
  Size := Data[5];
  if not(Size in [4, 7, 10]) then
    RawFailure('invalid selected UID length');
  AfterUid := 6 + Size;
  if Length(Data) < AfterUid then
    RawFailure('truncated selected UID');
  if ((Data[4] and $20) <> 0) and not FSkipAutomaticRats then
  begin
    if Length(Data) <= AfterUid then
      RawFailure('missing ATS');
    AtsSize := Data[AfterUid];
    if (AtsSize < 1) or (AtsSize > 20) or (Length(Data) <> AfterUid + AtsSize)
    then
      RawFailure('invalid ATS framing');
  end
  else if Length(Data) <> AfterUid then
    RawFailure('unexpected target data');
  Registers := Send(HexToBytes('D40663026303633D'), $07);
  if Length(Registers) <> 3 then
    RawFailure('invalid register snapshot');
  FTxMode := Registers[0];
  FRxMode := Registers[1];
  FBitFraming := Registers[2];
  FHasRegisters := True;
  SetRawFraming(0);
  Result := Copy(Data, 6, Size);
end;

function TAcr122RawReader.Exchange(const AFrame: TBytes;
  const ABitCount: Integer): TRawRfResponse;
var
  Wire, Data, Control: TBytes;
  LastBits: Integer;
begin
  Result := Default (TRawRfResponse);
  RequireActive;
  if not FHasRegisters then
    RawFailure('target not activated');
  if (Length(AFrame) < 1) or (Length(AFrame) > 253) then
    RawFailure('invalid frame size');
  if (ABitCount <= (Length(AFrame) - 1) * 8) or (ABitCount > Length(AFrame) * 8)
  then
    RawFailure('invalid outgoing bit count');
  SetRawFraming(Byte(ABitCount mod 8));
  SetLength(Wire, Length(AFrame) + 2);
  Wire[0] := $D4;
  Wire[1] := $42;
  Move(AFrame[0], Wire[2], Length(AFrame));
  try
    Data := Send(Wire, $43);
  finally
    FillChar(Wire[0], Length(Wire), 0);
  end;
  try
    if Length(Data) < 1 then
      RawFailure('missing RF status');
    if Data[0] = $01 then
    begin
      if Length(Data) <> 1 then
        RawFailure('timeout contains data');
      Result.TimedOut := True;
      Exit;
    end;
    if Data[0] <> 0 then
      RawFailure('PN532 RF exchange status failure');
    if (Length(Data) < 2) or (Length(Data) > 254) then
      RawFailure('invalid RF response size');
    Control := Send(HexToBytes('D406633C'), $07);
    if Length(Control) <> 1 then
      RawFailure('invalid received-bit status');
    LastBits := Control[0] and $07;
    Result.Data := Copy(Data, 1, Length(Data) - 1);
    Result.BitCount := Length(Result.Data) * 8;
    if LastBits <> 0 then
      Result.BitCount := Result.BitCount - 8 + LastBits;
  finally
    if Length(Data) > 0 then
      FillChar(Data[0], Length(Data), 0);
  end;
end;

end.
