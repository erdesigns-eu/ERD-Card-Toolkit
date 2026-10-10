unit ERD.Card.Contactless.Felica;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}Classes, SysUtils, {$ELSE}System.Classes, System.SysUtils, {$ENDIF}
  ERD.Card.Contactless;

type
  /// <summary>Malformed FeliCa framing or unsupported local command parameters.</summary>
  EFelicaError = class(EContactlessError);

  /// <summary>Card-reported unencrypted-service status, without card data in the message.</summary>
  EFelicaStatusError = class(EFelicaError)
  private
    FStatus1, FStatus2: Byte;
  public
    /// <summary>Retains the two acquired FeliCa status flags.</summary>
    /// <param name="AStatus1">First card status flag.</param>
    /// <param name="AStatus2">Second card status flag.</param>
    constructor Create(const AStatus1, AStatus2: Byte); reintroduce;
    /// <summary>First card status flag; zero is required for success.</summary>
    property Status1: Byte read FStatus1;
    /// <summary>Second card status flag; zero is required for success.</summary>
    property Status2: Byte read FStatus2;
  end;

  /// <summary>Owned identity and communication parameters from one fresh FeliCa polling response.</summary>
  TFelicaTarget = record
    /// <summary>Independent eight-byte IDm in transmission order.</summary>
    Idm: TBytes;
    /// <summary>Independent eight-byte PMm; no manufacturer interpretation is inferred.</summary>
    Pmm: TBytes;
    /// <summary>Acquired big-endian polling system code.</summary>
    SystemCode: Word;
  end;

  /// <summary>Explicit ordered FeliCa block numbers within one supplied service.</summary>
  TFelicaBlocks = array of Word;

  /// <summary>Retained exclusive FeliCa RF transport; frames include length/code and omit RF preamble/CRC.</summary>
  /// <remarks>Implementations select one target, preserve it between exchanges, bound timeouts and never retry writes.</remarks>
  IFelicaReader = interface
    ['{23E73E64-274A-4AF8-AD4A-62E4C5D1ACB2}']
    /// <summary>Acquires exclusive reader access; failed acquisition cleans up its own resources.</summary>
    procedure BeginSession;
    /// <summary>Stops RF and releases exclusivity even if RF cleanup fails.</summary>
    procedure EndSession;
    /// <summary>Freshly selects exactly one target for an explicit system code.</summary>
    /// <param name="ASystemCode">FFFF selects any system; 12FC selects NFC Forum Type 3.</param>
    /// <returns>Owned polling identity and parameters.</returns>
    function Activate(const ASystemCode: Word): TFelicaTarget;
    /// <summary>Sends one complete FeliCa length-prefixed frame without retry or RF reset.</summary>
    /// <param name="AFrame">Caller-owned frame; never modified.</param>
    /// <returns>Independent complete length-prefixed response; timeouts are failures.</returns>
    function Exchange(const AFrame: TBytes): TBytes;
  end;

  /// <summary>Pure length/identity/status validation and explicit single-service block framing.</summary>
  TFelicaCodec = class
  public
    /// <summary>Builds Read/Write Without Encryption with two- or three-byte block-list elements.</summary>
    /// <param name="AIdm">Exactly eight target identity bytes.</param>
    /// <param name="AService">Explicit service code, transmitted little-endian.</param>
    /// <param name="ABlocks">Ordered unique block numbers; 1..15 for reads, 1..12 for writes.</param>
    /// <param name="AWrite">True selects command 08; false selects command 06.</param>
    /// <param name="AData">Exactly sixteen bytes per written block, or empty for reads.</param>
    /// <returns>Owned complete length-prefixed frame, at most 252 bytes.</returns>
    class function BlockCommand(const AIdm: TBytes; const AService: Word;
      const ABlocks: TFelicaBlocks; const AWrite: Boolean; const AData: TBytes)
      : TBytes; static;
    /// <summary>Validates the complete response code, matching identity, both status flags and exact block count/length.</summary>
    /// <param name="AFrame">Complete response; never modified.</param>
    /// <param name="AIdm">Expected eight-byte selected target identity.</param>
    /// <param name="AWrite">True expects 09 with no payload; false expects 07 and block data.</param>
    /// <param name="ACount">Expected positive requested block count.</param>
    /// <returns>Independent read data or empty write acknowledgement.</returns>
    class function DecodeBlocks(const AFrame, AIdm: TBytes;
      const AWrite: Boolean; const ACount: Integer): TBytes; static;
  end;

  /// <summary>Nonvisual explicit-system FeliCa unencrypted-service reader and independently verified block writer.</summary>
  /// <remarks>No key discovery, service guessing, encrypted-service authentication or payment processing. Configure/call on one thread.</remarks>
  TFelicaCardReader = class(TComponent)
  private
    FReader: IFelicaReader;
    FBusy: Boolean;
    procedure SetReader(const AValue: IFelicaReader);
    function Acquire(const ASystemCode: Word): TFelicaTarget;
    procedure Release(const ASucceeded: Boolean);
  public
    /// <summary>Creates inactive access without opening hardware.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Freshly polls one explicitly selected system without reading blocks.</summary>
    /// <param name="ASystemCode">Explicit system code or FFFF wildcard.</param>
    /// <returns>Owned target information after successful release.</returns>
    function ReadTarget(const ASystemCode: Word): TFelicaTarget;
    /// <summary>Reads explicitly supplied blocks from one unencrypted service.</summary>
    /// <param name="ASystemCode">Explicit selected system or FFFF wildcard.</param>
    /// <param name="AService">Explicit unencrypted read service code.</param>
    /// <param name="ABlocks">One to fifteen unique blocks in output order.</param>
    /// <returns>Exactly sixteen independent bytes per block after release.</returns>
    function ReadBlocks(const ASystemCode, AService: Word;
      const ABlocks: TFelicaBlocks): TBytes;
    /// <summary>Writes blocks once and verifies all bytes through the supplied read service in the retained session.</summary>
    /// <param name="ASystemCode">Explicit system code or wildcard.</param>
    /// <param name="AWriteService">Explicit writable unencrypted service.</param>
    /// <param name="AReadService">Explicit verification service for the same storage.</param>
    /// <param name="ABlocks">One to twelve unique target blocks.</param>
    /// <param name="AExpected">Exact sixteen-byte-per-block preimage, checked before dispatch.</param>
    /// <param name="AData">Exact replacement bytes, copied before I/O.</param>
    /// <returns>Independent complete readback after successful release; no-op inputs still verify.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch, without retry or rollback.</exception>
    function WriteBlocksVerified(const ASystemCode, AWriteService,
      AReadService: Word; const ABlocks: TFelicaBlocks;
      const AExpected, AData: TBytes): TBytes;
    /// <summary>Explicit inactive reader adapter; change only outside an operation.</summary>
    property Reader: IFelicaReader read FReader write SetReader;
    /// <summary>True while this component owns its exclusive operation.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes;

procedure Invalid;
begin
  raise EFelicaError.Create('Invalid FeliCa command, response or operation.');
end;

constructor EFelicaStatusError.Create(const AStatus1, AStatus2: Byte);
begin
  inherited Create('FeliCa service access was rejected.');
  FStatus1 := AStatus1;
  FStatus2 := AStatus2;
end;

class function TFelicaCodec.BlockCommand(const AIdm: TBytes;
  const AService: Word; const ABlocks: TFelicaBlocks; const AWrite: Boolean;
  const AData: TBytes): TBytes;
var
  I, J, Size, Offset: Integer;
begin
  Result := nil;
  if (Length(AIdm) <> 8) or (Length(ABlocks) < 1) or (Length(ABlocks) > 15) or
    (AWrite and (Length(ABlocks) > 12)) or
    (AWrite and (Length(AData) <> Length(ABlocks) * 16)) or
    (not AWrite and (Length(AData) <> 0)) then
    Invalid;
  Size := 14;
  for I := 0 to High(ABlocks) do
  begin
    Inc(Size, 2);
    if ABlocks[I] > 255 then
      Inc(Size);
    for J := 0 to I - 1 do
      if ABlocks[I] = ABlocks[J] then
        Invalid;
  end;
  if AWrite then
    Inc(Size, Length(AData));
  if Size > 252 then
    Invalid;
  SetLength(Result, Size);
  Result[0] := Size;
  Result[1] := $06;
  if AWrite then
    Result[1] := $08;
  Move(AIdm[0], Result[2], 8);
  Result[10] := 1;
  Result[11] := AService and $FF;
  Result[12] := AService shr 8;
  Result[13] := Length(ABlocks);
  Offset := 14;
  for I := 0 to High(ABlocks) do
  begin
    Result[Offset] := $80;
    if ABlocks[I] > 255 then
      Result[Offset] := 0;
    Result[Offset + 1] := ABlocks[I] and $FF;
    Inc(Offset, 2);
    if ABlocks[I] > 255 then
    begin
      Result[Offset] := ABlocks[I] shr 8;
      Inc(Offset);
    end;
  end;
  if AWrite then
    Move(AData[0], Result[Offset], Length(AData));
end;

class function TFelicaCodec.DecodeBlocks(const AFrame, AIdm: TBytes;
  const AWrite: Boolean; const ACount: Integer): TBytes;
var
  Code: Byte;
begin
  Result := nil;
  Code := $07;
  if AWrite then
    Code := $09;
  if (Length(AIdm) <> 8) or (ACount < 1) or (ACount > 15) or
    (Length(AFrame) < 12) or (Length(AFrame) > 255) or
    (AFrame[0] <> Length(AFrame)) or (AFrame[1] <> Code) or
    not BytesEqual(Copy(AFrame, 2, 8), AIdm) then
    Invalid;
  if (AFrame[10] <> 0) or (AFrame[11] <> 0) then
  begin
    if Length(AFrame) <> 12 then
      Invalid;
    raise EFelicaStatusError.Create(AFrame[10], AFrame[11]);
  end;
  if AWrite then
  begin
    if Length(AFrame) <> 12 then
      Invalid;
  end
  else
  begin
    if (Length(AFrame) <> 13 + ACount * 16) or (AFrame[12] <> ACount) then
      Invalid;
    Result := Copy(AFrame, 13, ACount * 16);
  end;
end;

constructor TFelicaCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TFelicaCardReader.SetReader(const AValue: IFelicaReader);
begin
  if FBusy then
    Invalid;
  FReader := AValue;
end;

function TFelicaCardReader.Acquire(const ASystemCode: Word): TFelicaTarget;
begin
  Result := Default (TFelicaTarget);
  if FBusy or (FReader = nil) then
    Invalid;
  FBusy := True;
  try
    FReader.BeginSession;
  except
    FBusy := False;
    raise;
  end;
  try
    Result := FReader.Activate(ASystemCode);
    if (Length(Result.Idm) <> 8) or (Length(Result.Pmm) <> 8) or
      ((ASystemCode <> $FFFF) and (Result.SystemCode <> ASystemCode)) then
      Invalid;
  except
    Release(False);
    raise;
  end;
end;

procedure TFelicaCardReader.Release(const ASucceeded: Boolean);
begin
  try
    if ASucceeded then
      FReader.EndSession
    else
      try
        FReader.EndSession;
      except
      end;
  finally
    FBusy := False;
  end;
end;

function TFelicaCardReader.ReadTarget(const ASystemCode: Word): TFelicaTarget;
var
  Target: TFelicaTarget;
begin
  Target := Acquire(ASystemCode);
  Release(True);
  Result.Idm := CopyBytes(Target.Idm);
  Result.Pmm := CopyBytes(Target.Pmm);
  Result.SystemCode := Target.SystemCode;
end;

function TFelicaCardReader.ReadBlocks(const ASystemCode, AService: Word;
  const ABlocks: TFelicaBlocks): TBytes;
var
  Target: TFelicaTarget;
  Wire, Data: TBytes;
  Blocks: TFelicaBlocks;
  Succeeded: Boolean;
begin
  Result := nil;
  Blocks := Copy(ABlocks, 0, Length(ABlocks));
  TFelicaCodec.BlockCommand(HexToBytes('0000000000000000'), AService, Blocks,
    False, nil);
  Target := Acquire(ASystemCode);
  Succeeded := False;
  try
    Wire := TFelicaCodec.BlockCommand(Target.Idm, AService, Blocks, False, nil);
    Data := TFelicaCodec.DecodeBlocks(FReader.Exchange(Wire), Target.Idm, False,
      Length(Blocks));
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := Data;
end;

function TFelicaCardReader.WriteBlocksVerified(const ASystemCode, AWriteService,
  AReadService: Word; const ABlocks: TFelicaBlocks;
  const AExpected, AData: TBytes): TBytes;
var
  Target: TFelicaTarget;
  Blocks: TFelicaBlocks;
  Expected, Data, Readback, Wire: TBytes;
  Succeeded, Dispatched: Boolean;
  function Read: TBytes;
  begin
    Result := TFelicaCodec.DecodeBlocks
      (FReader.Exchange(TFelicaCodec.BlockCommand(Target.Idm, AReadService,
      Blocks, False, nil)), Target.Idm, False, Length(Blocks));
  end;

begin
  Result := nil;
  Dispatched := False;
  Blocks := Copy(ABlocks, 0, Length(ABlocks));
  Expected := CopyBytes(AExpected);
  Data := CopyBytes(AData);
  TFelicaCodec.BlockCommand(HexToBytes('0000000000000000'), AWriteService,
    Blocks, True, Data);
  if Length(Expected) <> Length(Data) then
    Invalid;
  try
    Target := Acquire(ASystemCode);
    Succeeded := False;
    try
      Readback := Read;
      if not BytesEqual(Readback, Expected) then
        Invalid;
      if not BytesEqual(Data, Expected) then
      begin
        Wire := TFelicaCodec.BlockCommand(Target.Idm, AWriteService, Blocks,
          True, Data);
        Dispatched := True;
        TFelicaCodec.DecodeBlocks(FReader.Exchange(Wire), Target.Idm, True,
          Length(Blocks));
        Readback := Read;
        if not BytesEqual(Readback, Data) then
          Invalid;
      end;
      Succeeded := True;
    finally
      Release(Succeeded);
    end;
    Result := Readback;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

end.
