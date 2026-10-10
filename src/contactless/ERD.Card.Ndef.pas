unit ERD.Card.Ndef;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes;

const
  /// <summary>Hard upper bound on one encoded message, including all record headers.</summary>
  NdefMaxMessageBytes = 1048576;
  /// <summary>Hard upper bound on logical records per message.</summary>
  NdefMaxRecords = 256;
  /// <summary>Hard upper bound on physical records, including continuation chunks.</summary>
  NdefMaxChunks = 1024;

type
  /// <summary>Malformed, unsupported or oversized NDEF data; messages contain no record contents.</summary>
  ENdefError = class(EConvertError);
  /// <summary>Logical type-name format; continuation chunks are reassembled before exposure.</summary>
  TNdefTypeNameFormat = (
    /// <summary>Empty record, without type, identifier or payload.</summary>
    ntfEmpty,
    /// <summary>NFC Forum well-known record type.</summary>
    ntfWellKnown,
    /// <summary>RFC media type carried in the type field.</summary>
    ntfMime,
    /// <summary>Absolute URI carried in the type field.</summary>
    ntfAbsoluteUri,
    /// <summary>External domain:type record.</summary>
    ntfExternal,
    /// <summary>Opaque payload without a type field.</summary>
    ntfUnknown);

  /// <summary>Logical record with independent buffers when created or decoded by the codec.</summary>
  /// <remarks>Ordinary record assignment shares arrays; clone before modifying an assigned copy.</remarks>
  TNdefRecord = record
    /// <summary>Logical TNF value zero through five.</summary>
    Tnf: TNdefTypeNameFormat;
    /// <summary>Type bytes, at most 255; interpretation depends on Tnf.</summary>
    RecordType: TBytes;
    /// <summary>Optional opaque identifier, at most 255 bytes.</summary>
    Id: TBytes;
    /// <summary>Application payload; chunk framing has been removed.</summary>
    Payload: TBytes;
  end;

  /// <summary>Ordered logical records; assignment shares the array and its member buffers.</summary>
  TNdefMessage = array of TNdefRecord;

  /// <summary>Transport-independent bounded NDEF framing and chunk reassembly.</summary>
  /// <remarks>Reserved TNF seven is rejected by policy. Encoding uses unchunked records,
  /// shortest payload lengths and omits IL for empty identifiers. RTD semantics are separate.</remarks>
  TNdefCodec = class
  public
    /// <summary>Creates and validates an independently owned logical record.</summary>
    /// <param name="ATnf">Logical TNF, not a continuation marker.</param>
    /// <param name="AType">Type bytes; input is never modified.</param>
    /// <param name="AId">Identifier bytes; input is never modified.</param>
    /// <param name="APayload">Payload bytes; input is never modified.</param>
    /// <returns>Validated record with copied buffers.</returns>
    /// <exception cref="ENdefError">Lengths or TNF constraints are invalid.</exception>
    class function NewRecord(const ATnf: TNdefTypeNameFormat;
      const AType, AId, APayload: TBytes): TNdefRecord; static;
    /// <summary>Validates structural TNF and field-size constraints, without I/O.</summary>
    /// <param name="ARecord">Caller-owned logical record.</param>
    /// <exception cref="ENdefError">TNF or an individual field exceeds supported bounds.</exception>
    class procedure ValidateRecord(const ARecord: TNdefRecord); static;
    /// <summary>Deep-copies all message records and buffers after validation.</summary>
    /// <param name="AMessage">One through NdefMaxRecords logical records.</param>
    /// <returns>Independent message.</returns>
    /// <exception cref="ENdefError">A record, record count or total encoded size is invalid.</exception>
    class function Clone(const AMessage: TNdefMessage): TNdefMessage; static;
    /// <summary>Encodes one complete message using canonical unchunked framing.</summary>
    /// <param name="AMessage">Nonempty ordered logical records; never modified.</param>
    /// <returns>Independent encoded bytes with MB/ME framing.</returns>
    /// <exception cref="ENdefError">A record or total size exceeds supported bounds.</exception>
    class function Encode(const AMessage: TNdefMessage): TBytes; static;
    /// <summary>Decodes exactly one complete message and reassembles bounded chunks.</summary>
    /// <param name="AWire">Complete message, without storage TLV framing or padding.</param>
    /// <param name="AMaxBytes">Caller size bound, from one through NdefMaxMessageBytes.</param>
    /// <param name="AMaxRecords">Caller logical-record bound, from one through NdefMaxRecords.</param>
    /// <returns>Independent logical records; no partial message on failure.</returns>
    /// <exception cref="ENdefError">Framing, chunking, TNF, lengths or bounds are invalid.</exception>
    class function Decode(const AWire: TBytes;
      const AMaxBytes: Integer = NdefMaxMessageBytes;
      const AMaxRecords: Integer = NdefMaxRecords): TNdefMessage; static;
  end;

implementation

procedure Fail;
begin
  raise ENdefError.Create('Invalid or unsupported NDEF message.');
end;

class procedure TNdefCodec.ValidateRecord(const ARecord: TNdefRecord);
begin
  if (Ord(ARecord.Tnf) > Ord(ntfUnknown)) or (Ord(ARecord.Tnf) < 0) or
    (Length(ARecord.RecordType) > 255) or (Length(ARecord.Id) > 255) or
    (Length(ARecord.Payload) > NdefMaxMessageBytes) then
    Fail;
  case ARecord.Tnf of
    ntfEmpty:
      if (Length(ARecord.RecordType) <> 0) or (Length(ARecord.Id) <> 0) or
        (Length(ARecord.Payload) <> 0) then
        Fail;
    ntfUnknown:
      if Length(ARecord.RecordType) <> 0 then
        Fail;
    ntfWellKnown, ntfMime, ntfAbsoluteUri, ntfExternal:
      if Length(ARecord.RecordType) = 0 then
        Fail;
  end;
end;

class function TNdefCodec.NewRecord(const ATnf: TNdefTypeNameFormat;
  const AType, AId, APayload: TBytes): TNdefRecord;
begin
  Result := Default (TNdefRecord);
  Result.Tnf := ATnf;
  Result.RecordType := AType;
  Result.Id := AId;
  Result.Payload := APayload;
  ValidateRecord(Result);
  Result.RecordType := CopyBytes(AType);
  Result.Id := CopyBytes(AId);
  Result.Payload := CopyBytes(APayload);
end;

function EncodedMessageSize(const AMessage: TNdefMessage): Integer;
var
  I, ItemSize: Integer;
begin
  if (Length(AMessage) < 1) or (Length(AMessage) > NdefMaxRecords) then
    Fail;
  Result := 0;
  for I := 0 to High(AMessage) do
  begin
    TNdefCodec.ValidateRecord(AMessage[I]);
    ItemSize := 3 + Length(AMessage[I].RecordType) + Length(AMessage[I].Id) +
      Length(AMessage[I].Payload);
    if Length(AMessage[I].Payload) > 255 then
      Inc(ItemSize, 3);
    if Length(AMessage[I].Id) > 0 then
      Inc(ItemSize);
    if ItemSize > NdefMaxMessageBytes - Result then
      Fail;
    Inc(Result, ItemSize);
  end;
end;

class function TNdefCodec.Clone(const AMessage: TNdefMessage): TNdefMessage;
var
  I: Integer;
begin
  Result := nil;
  EncodedMessageSize(AMessage);
  SetLength(Result, Length(AMessage));
  for I := 0 to High(AMessage) do
    Result[I] := NewRecord(AMessage[I].Tnf, AMessage[I].RecordType,
      AMessage[I].Id, AMessage[I].Payload);
end;

class function TNdefCodec.Encode(const AMessage: TNdefMessage): TBytes;
var
  I, P, Size, N: Integer;
  Flags: Byte;
  procedure Put(const AData: TBytes);
  begin
    if Length(AData) > 0 then
      Move(AData[0], Result[P], Length(AData));
    Inc(P, Length(AData));
  end;

begin
  Result := nil;
  Size := EncodedMessageSize(AMessage);
  SetLength(Result, Size);
  P := 0;
  for I := 0 to High(AMessage) do
  begin
    N := Length(AMessage[I].Payload);
    Flags := Ord(AMessage[I].Tnf);
    if I = 0 then
      Flags := Flags or $80;
    if I = High(AMessage) then
      Flags := Flags or $40;
    if N <= 255 then
      Flags := Flags or $10;
    if Length(AMessage[I].Id) > 0 then
      Flags := Flags or $08;
    Result[P] := Flags;
    Inc(P);
    Result[P] := Length(AMessage[I].RecordType);
    Inc(P);
    if N <= 255 then
    begin
      Result[P] := N;
      Inc(P);
    end
    else
    begin
      Result[P] := Byte(Cardinal(N) shr 24);
      Result[P + 1] := Byte(Cardinal(N) shr 16);
      Result[P + 2] := Byte(Cardinal(N) shr 8);
      Result[P + 3] := Byte(N and $FF);
      Inc(P, 4);
    end;
    if Length(AMessage[I].Id) > 0 then
    begin
      Result[P] := Length(AMessage[I].Id);
      Inc(P);
    end;
    Put(AMessage[I].RecordType);
    Put(AMessage[I].Id);
    Put(AMessage[I].Payload);
  end;
end;

class function TNdefCodec.Decode(const AWire: TBytes;
  const AMaxBytes, AMaxRecords: Integer): TNdefMessage;
var
  P, Physical, Count, TypeLen, IdLen, N, Total: Integer;
  Flags, Tnf: Byte;
  PayloadLen: Cardinal;
  InChunk, First, CF, ME, IL: Boolean;
  Current: TNdefRecord;
  ChunkData: TBytes;
  function TakeByte: Byte;
  begin
    if P >= Length(AWire) then
      Fail;
    Result := AWire[P];
    Inc(P);
  end;
  function Take(const ACount: Integer): TBytes;
  begin
    if ACount > Length(AWire) - P then
      Fail;
    Result := Copy(AWire, P, ACount);
    Inc(P, ACount);
  end;

begin
  Result := nil;
  if (AMaxBytes < 1) or (AMaxBytes > NdefMaxMessageBytes) or (AMaxRecords < 1)
    or (AMaxRecords > NdefMaxRecords) or (Length(AWire) = 0) or
    (Length(AWire) > AMaxBytes) then
    Fail;
  P := 0;
  Physical := 0;
  Count := 0;
  Total := 0;
  InChunk := False;
  First := True;
  repeat
    Inc(Physical);
    if Physical > NdefMaxChunks then
      Fail;
    Flags := TakeByte;
    Tnf := Flags and 7;
    CF := (Flags and $20) <> 0;
    ME := (Flags and $40) <> 0;
    IL := (Flags and $08) <> 0;
    if (((Flags and $80) <> 0) <> First) or (CF and ME) or (Tnf = 7) then
      Fail;
    First := False;
    TypeLen := TakeByte;
    if (Flags and $10) <> 0 then
      PayloadLen := TakeByte
    else
    begin
      PayloadLen := Cardinal(TakeByte) shl 24;
      PayloadLen := PayloadLen or (Cardinal(TakeByte) shl 16);
      PayloadLen := PayloadLen or (Cardinal(TakeByte) shl 8);
      PayloadLen := PayloadLen or Cardinal(TakeByte);
    end;
    if PayloadLen > Cardinal(Length(AWire) - P) then
      Fail;
    N := Integer(PayloadLen);
    if IL then
      IdLen := TakeByte
    else
      IdLen := 0;
    if InChunk then
    begin
      if (Tnf <> 6) or IL or (TypeLen <> 0) then
        Fail;
    end
    else
    begin
      if (Tnf = 6) or ((Tnf = 0) and CF) then
        Fail;
      Current := Default (TNdefRecord);
      Current.Tnf := TNdefTypeNameFormat(Tnf);
      Current.RecordType := Take(TypeLen);
      Current.Id := Take(IdLen);
      Total := 0;
      if CF then
        SetLength(ChunkData, Length(AWire));
    end;
    if N > Length(AWire) - P then
      Fail;
    if CF or InChunk then
    begin
      if N > Length(ChunkData) - Total then
        Fail;
      if N > 0 then
        Move(AWire[P], ChunkData[Total], N);
      Inc(Total, N);
      Inc(P, N);
      if not CF then
        Current.Payload := Copy(ChunkData, 0, Total);
    end
    else
      Current.Payload := Take(N);
    if not CF then
    begin
      ValidateRecord(Current);
      if Count >= AMaxRecords then
        Fail;
      SetLength(Result, Count + 1);
      Result[Count] := Current;
      Inc(Count);
      ChunkData := nil;
    end;
    InChunk := CF;
    if ME then
    begin
      if InChunk or (P <> Length(AWire)) then
        Fail;
      Break;
    end;
    if P = Length(AWire) then
      Fail;
  until False;
end;

end.
