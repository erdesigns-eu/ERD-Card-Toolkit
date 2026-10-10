unit ERD.Card.Contactless.Type1.Ndef;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}Classes, SysUtils, {$ELSE}System.Classes, System.SysUtils, {$ENDIF}
  ERD.Card.Contactless.Topaz, ERD.Card.Ndef;

type
  /// <summary>Invalid, unsupported or uninitialized Topaz Type 1 NDEF mapping.</summary>
  EType1NdefError = class(ETopazError);

  /// <summary>Owned complete card snapshot and exact initialized Type 1 NDEF contents.</summary>
  TType1NdefSnapshot = record
    /// <summary>Complete identity, physical preimage and lock map.</summary>
    Card: TTopazSnapshot;
    /// <summary>True when CC advertises write access 0F.</summary>
    ReadOnly: Boolean;
    /// <summary>Logical TLV byte count excluding CC/control/static-reserved/dynamic-reserved bytes.</summary>
    LogicalCapacity: Integer;
    /// <summary>NDEF TLV type position in the logical stream, preserving all prefix TLVs.</summary>
    TlvIndex: Integer;
    /// <summary>Independent exact message bytes, without TLV header or padding.</summary>
    MessageBytes: TBytes;
    /// <summary>Decoded NDEF records; empty for a zero-length message.</summary>
    Records: TNdefMessage;
  end;

  /// <summary>Strict Type 1 version 1.0 mapping for Topaz 96 and canonical Topaz 512 lock/memory-control TLVs.</summary>
  /// <remarks>Existing initialized NDEF only; no formatting, arbitrary control layouts or permanent locks.</remarks>
  TType1NdefMapping = class
  public
    /// <summary>Validates CC, canonical control bytes, one NDEF TLV, lengths and record framing.</summary>
    /// <param name="ACard">Complete valid acquired Topaz snapshot.</param>
    /// <returns>Owned card/message snapshot; malformed or unsupported layout is refused.</returns>
    class function Decode(const ACard: TTopazSnapshot)
      : TType1NdefSnapshot; static;
    /// <summary>Builds a desired image preserving metadata and prefix TLVs, clearing only NDEF TLV storage and its tail.</summary>
    /// <param name="ABefore">Valid initialized mapping.</param>
    /// <param name="ANdef">Valid complete message; empty clears NDEF.</param>
    /// <param name="APublished">False keeps the length marker zero until the payload is verified.</param>
    /// <returns>Independent complete physical image.</returns>
    class function Image(const ABefore: TType1NdefSnapshot; const ANdef: TBytes;
      const APublished: Boolean): TBytes; static;
    /// <summary>Maps a logical TLV byte to a physical address while skipping reserved memory.</summary>
    /// <param name="AModel">Explicit Topaz profile.</param>
    /// <param name="AIndex">Zero-based logical TLV byte, within 92 or 466 bytes.</param>
    /// <returns>Physical address within complete memory.</returns>
    class function Address(const AModel: TTopazModel; const AIndex: Integer)
      : Integer; static;
  end;

  /// <summary>Palette Type 1 NDEF reader/writer using exact full-card preimages and verified length-last publication.</summary>
  /// <remarks>No automatic replay/rollback; partial writes remain uncertain. Eight-byte Topaz 512 writes preserve neighboring
  /// control bytes but are not physically atomic across power loss. Configure and call on one thread.</remarks>
  TType1NdefCardReader = class(TTopazCardReader)
  public
    /// <summary>Reads an initialized NDEF mapping and decodes all records.</summary>
    /// <returns>Owned physical preimage and exact message after successful session release.</returns>
    function ReadMessage: TType1NdefSnapshot;
    /// <summary>Replaces or clears existing NDEF with invalidation, verified payload and final length publication.</summary>
    /// <param name="AExpectedUid">Exact seven-byte UID from ReadMessage.</param>
    /// <param name="AExpectedMemory">Exact complete 120/512-byte physical preimage.</param>
    /// <param name="ANdef">Complete valid message; empty clears existing NDEF.</param>
    /// <returns>Independently verified final snapshot after release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch, including cleanup.</exception>
    function WriteMessageVerified(const AExpectedUid, AExpectedMemory,
      ANdef: TBytes): TType1NdefSnapshot;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Contactless;

procedure Invalid;
begin
  raise EType1NdefError.Create
    ('Invalid or unsupported Type 1 NDEF layout or operation.');
end;

class function TType1NdefMapping.Address(const AModel: TTopazModel;
  const AIndex: Integer): Integer;
var
  Start, Limit: Integer;
begin
  TTopazCodec.MemorySize(AModel);
  Start := 12;
  Limit := 92;
  if AModel = tmTopaz512 then
  begin
    Start := 22;
    Limit := 466;
  end;
  if (AIndex < 0) or (AIndex >= Limit) then
    Invalid;
  Result := Start + AIndex;
  if (AModel = tmTopaz512) and (Result >= 104) then
    Inc(Result, 24);
end;

class function TType1NdefMapping.Decode(const ACard: TTopazSnapshot)
  : TType1NdefSnapshot;
var
  I, P, L, Header, NdefEnd: Integer;
  Logical, Controls: TBytes;
  Found: Boolean;
begin
  Result := Default (TType1NdefSnapshot);
  Result.Card := TTopazCodec.Decode(ACard.Model, ACard.Target, ACard.Memory);
  if (ACard.Memory[8] <> $E1) or (ACard.Memory[9] <> $10) or
    ((Integer(ACard.Memory[10]) + 1) * 8 <> Length(ACard.Memory)) or
    not(ACard.Memory[11] in [0, $0F]) then
    Invalid;
  Result.ReadOnly := ACard.Memory[11] = $0F;
  Result.LogicalCapacity := 92;
  if ACard.Model = tmTopaz512 then
  begin
    Controls := HexToBytes('0103F230330203F00203');
    if not BytesEqual(Copy(ACard.Memory, 12, 10), Controls) then
      Invalid;
    Result.LogicalCapacity := 466;
  end;
  Logical := nil;
  SetLength(Logical, Result.LogicalCapacity);
  for I := 0 to High(Logical) do
    Logical[I] := ACard.Memory[Address(ACard.Model, I)];
  P := 0;
  Found := False;
  NdefEnd := 0;
  while P < Length(Logical) do
  begin
    if Logical[P] = 0 then
    begin
      Inc(P);
      Continue;
    end;
    if Logical[P] = $FE then
    begin
      Inc(P);
      Break;
    end;
    if Found or not(Logical[P] in [3, $FD]) or (P + 1 >= Length(Logical)) then
      Invalid;
    L := Logical[P + 1];
    Header := 2;
    if L = $FF then
    begin
      if P + 3 >= Length(Logical) then
        Invalid;
      Header := 4;
      L := (Integer(Logical[P + 2]) shl 8) or Logical[P + 3];
      if L < 255 then
        Invalid;
    end;
    if L > Length(Logical) - P - Header then
      Invalid;
    if Logical[P] = 3 then
    begin
      Found := True;
      Result.TlvIndex := P;
      Result.MessageBytes := Copy(Logical, P + Header, L);
      NdefEnd := P + Header + L;
    end;
    Inc(P, Header + L);
  end;
  if not Found then
    Invalid;
  // Bytes after the Terminator TLV are storage padding, not additional TLVs.
  if NdefEnd > Length(Logical) then
    Invalid;
  if Length(Result.MessageBytes) > 0 then
    Result.Records := TNdefCodec.Decode(Result.MessageBytes);
end;

class function TType1NdefMapping.Image(const ABefore: TType1NdefSnapshot;
  const ANdef: TBytes; const APublished: Boolean): TBytes;
var
  S: TType1NdefSnapshot;
  I, P, Header: Integer;
  Logical: TBytes;
begin
  S := Decode(ABefore.Card);
  if S.ReadOnly then
    Invalid;
  if Length(ANdef) > 0 then
    TNdefCodec.Decode(ANdef);
  Header := 2;
  if Length(ANdef) >= 255 then
    Header := 4;
  if Length(ANdef) > S.LogicalCapacity - S.TlvIndex - Header then
    Invalid;
  SetLength(Logical, S.LogicalCapacity);
  for I := 0 to S.TlvIndex - 1 do
    Logical[I] := S.Card.Memory[Address(S.Card.Model, I)];
  P := S.TlvIndex;
  Logical[P] := 3;
  if Header = 4 then
  begin
    Logical[P + 2] := Length(ANdef) shr 8;
    Logical[P + 3] := Length(ANdef) and $FF;
    if APublished then
      Logical[P + 1] := $FF;
  end
  else if APublished then
    Logical[P + 1] := Length(ANdef);
  for I := 0 to High(ANdef) do
    Logical[P + Header + I] := ANdef[I];
  if P + Header + Length(ANdef) < Length(Logical) then
    Logical[P + Header + Length(ANdef)] := $FE;
  Result := CopyBytes(S.Card.Memory);
  for I := 0 to High(Logical) do
    Result[Address(S.Card.Model, I)] := Logical[I];
end;

function TType1NdefCardReader.ReadMessage: TType1NdefSnapshot;
var
  S: TType1NdefSnapshot;
  Ok: Boolean;
begin
  Acquire;
  Ok := False;
  try
    S := TType1NdefMapping.Decode(Snapshot);
    Ok := True;
  finally
    Release(Ok);
  end;
  Result := S;
end;

function TType1NdefCardReader.WriteMessageVerified(const AExpectedUid,
  AExpectedMemory, ANdef: TBytes): TType1NdefSnapshot;
var
  Uid, Expected, Ndef, Invalidated, Payload, FinalImage: TBytes;
  S, Final: TType1NdefSnapshot;
  Current: TTopazSnapshot;
  Ok, Dispatched: Boolean;
  LengthAddress: Integer;
begin
  Result := Default (TType1NdefSnapshot);
  Uid := CopyBytes(AExpectedUid);
  Expected := CopyBytes(AExpectedMemory);
  Ndef := CopyBytes(ANdef);
  if (Length(Uid) <> 7) or (Length(Expected) <> TTopazCodec.MemorySize(Model))
    or not BytesEqual(Copy(Expected, 0, 7), Uid) then
    Invalid;
  if Length(Ndef) > 0 then
    TNdefCodec.Decode(Ndef);
  S := TType1NdefMapping.Decode(TTopazCodec.Preimage(Model, Uid, Expected));
  if S.ReadOnly then
    Invalid;
  if not BytesEqual(S.MessageBytes, Ndef) then
  begin
    FinalImage := TType1NdefMapping.Image(S, Ndef, True);
    Payload := TType1NdefMapping.Image(S, Ndef, False);
    Invalidated := CopyBytes(Expected);
    LengthAddress := TType1NdefMapping.Address(Model, S.TlvIndex + 1);
    Invalidated[LengthAddress] := 0;
    TTopazCodec.CheckImage(S.Card, Invalidated);
    TTopazCodec.CheckImage(S.Card, Payload);
    TTopazCodec.CheckImage(S.Card, FinalImage);
  end;
  Dispatched := False;
  try
    Acquire;
    Ok := False;
    try
      S := TType1NdefMapping.Decode(Snapshot);
      if not BytesEqual(S.Card.Uid, Uid) or not BytesEqual(S.Card.Memory,
        Expected) then
        Invalid;
      if S.ReadOnly then
        Invalid;
      if not BytesEqual(S.MessageBytes, Ndef) then
      begin
        FinalImage := TType1NdefMapping.Image(S, Ndef, True);
        Payload := TType1NdefMapping.Image(S, Ndef, False);
        Invalidated := CopyBytes(S.Card.Memory);
        LengthAddress := TType1NdefMapping.Address(Model, S.TlvIndex + 1);
        Invalidated[LengthAddress] := 0;
        TTopazCodec.CheckImage(S.Card, Invalidated);
        TTopazCodec.CheckImage(S.Card, Payload);
        TTopazCodec.CheckImage(S.Card, FinalImage);
        TTopazCodec.ProgramImage(Session, S.Card, Invalidated, Dispatched);
        Current := TTopazCodec.Decode(Model, S.Card.Target, Invalidated);
        TTopazCodec.ProgramImage(Session, Current, Payload, Dispatched);
        Current := TTopazCodec.Decode(Model, S.Card.Target, Payload);
        TTopazCodec.ProgramImage(Session, Current, FinalImage, Dispatched);
      end;
      Final := TType1NdefMapping.Decode(Snapshot);
      if not BytesEqual(Final.MessageBytes, Ndef) then
        Invalid;
      Ok := True;
    finally
      Release(Ok);
    end;
  except
    if Dispatched then
      raise EContactlessWriteUncertain.Create
        ('Type 1 NDEF write outcome is uncertain; do not retry automatically.');
    raise;
  end;
  Result := Final;
end;

end.
