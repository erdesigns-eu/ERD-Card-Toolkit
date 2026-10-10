unit ERD.Card.Contactless.Type3.Ndef;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}Classes, SysUtils, {$ELSE}System.Classes, System.SysUtils, {$ENDIF}
  ERD.Card.Contactless.Felica, ERD.Card.Ndef;

const
  /// <summary>NFC Forum Type 3 NDEF polling system code.</summary>
  Type3NdefSystemCode = $12FC;
  /// <summary>Read Without Encryption service for Type 3 NDEF storage.</summary>
  Type3NdefReadService = $000B;
  /// <summary>Write Without Encryption service for writable Type 3 NDEF storage.</summary>
  Type3NdefWriteService = $0009;

type
  /// <summary>Invalid or unsupported Type 3 NDEF mapping; no card contents in error messages.</summary>
  EType3NdefError = class(EFelicaError);

  /// <summary>Strict acquired Type 3 version 1.0 Attribute Information Block.</summary>
  TType3NdefAttribute = record
    /// <summary>Independent sixteen-byte block zero, including reserved bytes and checksum.</summary>
    RawBytes: TBytes;
    /// <summary>Advertised blocks per Read Without Encryption command; batching also applies the frame limit.</summary>
    ReadBlocks: Byte;
    /// <summary>Advertised blocks per write; zero disables writing.</summary>
    WriteBlocks: Byte;
    /// <summary>Advertised data blocks, excluding attribute block zero.</summary>
    MaxBlocks: Word;
    /// <summary>True for WriteF 0F; normal NDEF reads/writes refuse an interrupted update.</summary>
    Updating: Boolean;
    /// <summary>True for RWFlag zero or zero writable block count.</summary>
    ReadOnly: Boolean;
    /// <summary>Exact acquired 24-bit NDEF byte length, bounded by MaxBlocks times sixteen.</summary>
    MessageBytes: Integer;
  end;

  /// <summary>Owned Type 3 NDEF snapshot and selected FeliCa target.</summary>
  TType3NdefSnapshot = record
    /// <summary>Owned fresh polling identity and parameters for system 12FC.</summary>
    Target: TFelicaTarget;
    /// <summary>Owned stable attribute block verified after all data reads.</summary>
    Attribute: TType3NdefAttribute;
    /// <summary>Independent exact NDEF bytes without storage padding.</summary>
    MessageBytes: TBytes;
    /// <summary>Independent decoded records; empty when published length is zero.</summary>
    Records: TNdefMessage;
  end;

  /// <summary>Pure strict Type 3 attribute checksum, bounds and length-publication codec.</summary>
  TType3NdefMapping = class
  public
    /// <summary>Validates sixteen-byte version 1.0 attribute data and its additive big-endian checksum.</summary>
    /// <param name="AData">Complete acquired attribute block; never modified.</param>
    /// <returns>Owned parsed attribute, including explicit updating/read-only state.</returns>
    class function DecodeAttribute(const AData: TBytes)
      : TType3NdefAttribute; static;
    /// <summary>Preserves all unrelated attribute bytes while replacing WriteF/length and recalculating checksum.</summary>
    /// <param name="AAttribute">Valid acquired attribute block.</param>
    /// <param name="ALength">Explicit byte length inside the acquired capacity.</param>
    /// <param name="AUpdating">True publishes WriteF 0F; false publishes a completed length.</param>
    /// <returns>Independent sixteen-byte attribute block; caller input remains unchanged.</returns>
    class function Publish(const AAttribute: TBytes; const ALength: Integer;
      const AUpdating: Boolean): TBytes; static;
  end;

  /// <summary>Nonvisual Type 3 NDEF reader and length-last writer over an explicit FeliCa reader adapter.</summary>
  /// <remarks>Only existing version 1.0 NDEF systems/services; no card formatting, encrypted-service access or automatic recovery.
  /// Writes retain exclusivity, verify each phase and never replay an uncertain command. Configure/call on one thread.</remarks>
  TType3NdefCardReader = class(TComponent)
  private
    FReader: IFelicaReader;
    FBusy: Boolean;
    FTarget: TFelicaTarget;
    procedure SetReader(const AValue: IFelicaReader);
    procedure Acquire;
    procedure Release(const ASucceeded: Boolean);
    function ReadBlocks(const AFirst, ACount: Integer): TBytes;
    function Snapshot: TType3NdefSnapshot;
    procedure ProgramBlocks(const AFirst: Integer; const AData: TBytes;
      var ADispatched: Boolean);
  public
    /// <summary>Creates inactive access without opening a reader.</summary>
    /// <param name="AOwner">Optional owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads attribute block zero without treating an interrupted update as a valid NDEF message.</summary>
    /// <returns>Owned attribute after fresh system-12FC polling and successful release.</returns>
    function ReadAttribute: TType3NdefAttribute;
    /// <summary>Reads exact published NDEF bytes, decodes records and checks the attribute remains unchanged.</summary>
    /// <returns>Independent complete snapshot after successful exclusive-session release.</returns>
    function ReadMessage: TType3NdefSnapshot;
    /// <summary>Replaces existing NDEF after exact attribute preimage, using WriteF invalidation, verified payload and length-last publication.</summary>
    /// <param name="AExpectedAttribute">Exact sixteen-byte attribute from the previous snapshot; stale/locked/updating attributes are refused.</param>
    /// <param name="ANdef">Complete valid NDEF bytes; empty publishes an empty message without erasing other storage.</param>
    /// <returns>Independent final snapshot after exact data/attribute verification and release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch; no retry or rollback.</exception>
    function WriteMessageVerified(const AExpectedAttribute, ANdef: TBytes)
      : TType3NdefSnapshot;
    /// <summary>Explicit inactive FeliCa adapter; changes are refused during an operation.</summary>
    property Reader: IFelicaReader read FReader write SetReader;
    /// <summary>True while this component owns an exclusive RF operation.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Contactless;

procedure Invalid;
begin
  raise EType3NdefError.Create
    ('Invalid or unsupported Type 3 NDEF mapping or operation.');
end;

class function TType3NdefMapping.DecodeAttribute(const AData: TBytes)
  : TType3NdefAttribute;
var
  I, Sum: Integer;
begin
  Result := Default (TType3NdefAttribute);
  if Length(AData) <> 16 then
    Invalid;
  Sum := 0;
  for I := 0 to 13 do
    Inc(Sum, AData[I]);
  if (Sum <> (Integer(AData[14]) shl 8) + AData[15]) or (AData[0] <> $10) or
    (AData[1] = 0) or not(AData[9] in [0, $0F]) or not(AData[10] in [0, 1]) then
    Invalid;
  Result.ReadBlocks := AData[1];
  Result.WriteBlocks := AData[2];
  Result.MaxBlocks := (Word(AData[3]) shl 8) or AData[4];
  Result.MessageBytes := (Integer(AData[11]) shl 16) or
    (Integer(AData[12]) shl 8) or AData[13];
  if (Result.MaxBlocks = 0) or (Result.MessageBytes > Integer(Result.MaxBlocks)
    * 16) then
    Invalid;
  Result.Updating := AData[9] = $0F;
  Result.ReadOnly := (AData[10] = 0) or (AData[2] = 0);
  Result.RawBytes := CopyBytes(AData);
end;

class function TType3NdefMapping.Publish(const AAttribute: TBytes;
  const ALength: Integer; const AUpdating: Boolean): TBytes;
var
  A: TType3NdefAttribute;
  I, Sum: Integer;
begin
  A := DecodeAttribute(AAttribute);
  if (ALength < 0) or (ALength > Integer(A.MaxBlocks) * 16) then
    Invalid;
  Result := CopyBytes(AAttribute);
  Result[9] := 0;
  if AUpdating then
    Result[9] := $0F;
  Result[11] := (ALength shr 16) and $FF;
  Result[12] := (ALength shr 8) and $FF;
  Result[13] := ALength and $FF;
  Sum := 0;
  for I := 0 to 13 do
    Inc(Sum, Result[I]);
  Result[14] := Sum shr 8;
  Result[15] := Sum and $FF;
end;

function Blocks(const AFirst, ACount: Integer): TFelicaBlocks;
var
  I: Integer;
begin
  Result := nil;
  if (AFirst < 0) or (ACount < 1) or (ACount > 15) or (AFirst > 65536 - ACount)
  then
    Invalid;
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
    Result[I] := AFirst + I;
end;

constructor TType3NdefCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TType3NdefCardReader.SetReader(const AValue: IFelicaReader);
begin
  if FBusy then
    Invalid;
  FReader := AValue;
end;

procedure TType3NdefCardReader.Acquire;
begin
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
    FTarget := FReader.Activate(Type3NdefSystemCode);
    if (Length(FTarget.Idm) <> 8) or (Length(FTarget.Pmm) <> 8) or
      (FTarget.SystemCode <> Type3NdefSystemCode) then
      Invalid;
    FTarget.Idm := CopyBytes(FTarget.Idm);
    FTarget.Pmm := CopyBytes(FTarget.Pmm);
  except
    Release(False);
    raise;
  end;
end;

procedure TType3NdefCardReader.Release(const ASucceeded: Boolean);
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
    FTarget := Default (TFelicaTarget);
  end;
end;

function TType3NdefCardReader.ReadBlocks(const AFirst, ACount: Integer): TBytes;
begin
  Result := TFelicaCodec.DecodeBlocks
    (FReader.Exchange(TFelicaCodec.BlockCommand(FTarget.Idm,
    Type3NdefReadService, Blocks(AFirst, ACount), False, nil)), FTarget.Idm,
    False, ACount);
end;

function TType3NdefCardReader.Snapshot: TType3NdefSnapshot;
var
  First, Count, Total, Limit: Integer;
  Chunk: TBytes;
begin
  Result := Default (TType3NdefSnapshot);
  Result.Attribute := TType3NdefMapping.DecodeAttribute(ReadBlocks(0, 1));
  if Result.Attribute.Updating then
    Invalid;
  Total := (Result.Attribute.MessageBytes + 15) div 16;
  SetLength(Result.MessageBytes, Total * 16);
  First := 1;
  Limit := Result.Attribute.ReadBlocks;
  if Limit > 15 then
    Limit := 15;
  while First <= Total do
  begin
    Count := Total - First + 1;
    if Count > Limit then
      Count := Limit;
    Chunk := ReadBlocks(First, Count);
    Move(Chunk[0], Result.MessageBytes[(First - 1) * 16], Length(Chunk));
    Inc(First, Count);
  end;
  SetLength(Result.MessageBytes, Result.Attribute.MessageBytes);
  if not BytesEqual(ReadBlocks(0, 1), Result.Attribute.RawBytes) then
    Invalid;
  if Length(Result.MessageBytes) > 0 then
    Result.Records := TNdefCodec.Decode(Result.MessageBytes);
  Result.Target.Idm := CopyBytes(FTarget.Idm);
  Result.Target.Pmm := CopyBytes(FTarget.Pmm);
  Result.Target.SystemCode := FTarget.SystemCode;
end;

function TType3NdefCardReader.ReadAttribute: TType3NdefAttribute;
var
  A: TType3NdefAttribute;
  Succeeded: Boolean;
begin
  Acquire;
  Succeeded := False;
  try
    A := TType3NdefMapping.DecodeAttribute(ReadBlocks(0, 1));
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := A;
end;

function TType3NdefCardReader.ReadMessage: TType3NdefSnapshot;
var
  S: TType3NdefSnapshot;
  Succeeded: Boolean;
begin
  Acquire;
  Succeeded := False;
  try
    S := Snapshot;
    Succeeded := True;
  finally
    Release(Succeeded);
  end;
  Result := S;
end;

procedure TType3NdefCardReader.ProgramBlocks(const AFirst: Integer;
  const AData: TBytes; var ADispatched: Boolean);
var
  Wire: TBytes;
  Count: Integer;
begin
  Count := Length(AData) div 16;
  if (Count < 1) or (Count > 12) or (Length(AData) <> Count * 16) then
    Invalid;
  Wire := TFelicaCodec.BlockCommand(FTarget.Idm, Type3NdefWriteService,
    Blocks(AFirst, Count), True, AData);
  ADispatched := True;
  TFelicaCodec.DecodeBlocks(FReader.Exchange(Wire), FTarget.Idm, True, Count);
  if not BytesEqual(ReadBlocks(AFirst, Count), AData) then
    Invalid;
end;

function TType3NdefCardReader.WriteMessageVerified(const AExpectedAttribute,
  ANdef: TBytes): TType3NdefSnapshot;
var
  Expected, Ndef, Updating, Committed, Data: TBytes;
  Original, Final: TType3NdefSnapshot;
  First, Count, Total, Limit, Bytes: Integer;
  Succeeded, Dispatched: Boolean;
begin
  Result := Default (TType3NdefSnapshot);
  Dispatched := False;
  Expected := CopyBytes(AExpectedAttribute);
  Ndef := CopyBytes(ANdef);
  TType3NdefMapping.DecodeAttribute(Expected);
  if Length(Ndef) > 0 then
    TNdefCodec.Decode(Ndef);
  try
    Acquire;
    Succeeded := False;
    try
      Original := Snapshot;
      if not BytesEqual(Original.Attribute.RawBytes, Expected) or
        Original.Attribute.ReadOnly or
        (Length(Ndef) > Integer(Original.Attribute.MaxBlocks) * 16) then
        Invalid;
      if not BytesEqual(Original.MessageBytes, Ndef) then
      begin
        Updating := TType3NdefMapping.Publish(Expected,
          Original.Attribute.MessageBytes, True);
        ProgramBlocks(0, Updating, Dispatched);
        Total := (Length(Ndef) + 15) div 16;
        First := 1;
        Limit := Original.Attribute.WriteBlocks;
        if Limit > 12 then
          Limit := 12;
        if Limit > Original.Attribute.ReadBlocks then
          Limit := Original.Attribute.ReadBlocks;
        while First <= Total do
        begin
          Count := Total - First + 1;
          if Count > Limit then
            Count := Limit;
          Data := ReadBlocks(First, Count);
          Bytes := Length(Ndef) - (First - 1) * 16;
          if Bytes > Length(Data) then
            Bytes := Length(Data);
          Move(Ndef[(First - 1) * 16], Data[0], Bytes);
          ProgramBlocks(First, Data, Dispatched);
          Inc(First, Count);
        end;
        Committed := TType3NdefMapping.Publish(Expected, Length(Ndef), False);
        ProgramBlocks(0, Committed, Dispatched);
        Final := Snapshot;
        if not BytesEqual(Final.MessageBytes, Ndef) or
          not BytesEqual(Final.Attribute.RawBytes, Committed) then
          Invalid;
      end
      else
        Final := Original;
      Succeeded := True;
    finally
      Release(Succeeded);
    end;
    Result := Final;
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
