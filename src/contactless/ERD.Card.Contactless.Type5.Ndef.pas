unit ERD.Card.Contactless.Type5.Ndef;

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
  ERD.Card.Contactless, ERD.Card.Contactless.ISO15693, ERD.Card.Ndef;

const
  /// <summary>Maximum ordinary extended NDEF TLV value length, in bytes.</summary>
  Type5MaxMessageBytes = 65535;

type
  /// <summary>Invalid or unsupported Type 5 CC, contiguous TLV mapping or selected access profile.</summary>
  EType5NdefError = class(EContactlessError);

  /// <summary>Strict NFC Forum Type 5 mapping 1.0 capability container.</summary>
  /// <remarks>Four/eight-byte CC, memory length excludes the CC. Legacy Android full-memory
  /// length interpretation and proprietary access require separate profiles.</remarks>
  TType5CapabilityContainer = record
    /// <summary>Independent exact four/eight-byte CC; ordinary assignment shares arrays.</summary>
    RawBytes: TBytes;
    /// <summary>E1 for one-byte addressing or E2 for two-byte addressing.</summary>
    Magic: Byte;
    /// <summary>Exactly 40 hexadecimal, mapping 1.0 without access bits.</summary>
    MappingVersion: Byte;
    /// <summary>Zero for public or two for proprietary reading.</summary>
    ReadAccess: Byte;
    /// <summary>Zero for public, two for proprietary or three for read-only.</summary>
    WriteAccess: Byte;
    /// <summary>Raw supported feature bits: multiple-block read, lock-block and special-frame indicators.</summary>
    Features: Byte;
    /// <summary>CC length, four or eight bytes.</summary>
    HeaderBytes: Integer;
    /// <summary>Advertised T5T data-area bytes, MLEN times eight, excluding the CC.</summary>
    DataAreaBytes: Integer;
  end;

  /// <summary>Complete independently acquired Type 5 NDEF snapshot.</summary>
  /// <remarks>Ordinary assignment shares arrays; output buffers are independently allocated.</remarks>
  TType5NdefSnapshot = record
    /// <summary>Addressed UID and physical geometry acquired in the same session.</summary>
    Information: TIso15693SystemInfo;
    /// <summary>Acquired and validated CC.</summary>
    Capabilities: TType5CapabilityContainer;
    /// <summary>Independent complete physical blocks covering the mapped area, including partial-block tails.</summary>
    PhysicalBytes: TBytes;
    /// <summary>Absolute byte offset of the single existing NDEF TLV tag.</summary>
    TlvOffset: Integer;
    /// <summary>Existing TLV header length, two or four; message length zero uses two.</summary>
    TlvHeaderBytes: Integer;
    /// <summary>Independent exact NDEF bytes; empty for an initialized empty message.</summary>
    MessageBytes: TBytes;
    /// <summary>Independent logical records, empty for a zero-length message.</summary>
    Records: TNdefMessage;
  end;

  /// <summary>Pure bounded Type 5 CC and contiguous NDEF TLV codecs.</summary>
  /// <remarks>NULL and proprietary TLVs may precede one NDEF TLV; an immediate terminator is required.
  /// Lock/memory-control TLVs and unsupported mappings are refused rather than treated as data holes.</remarks>
  TType5NdefCodec = class
  public
    /// <summary>Decodes a complete CC and checks it against acquired physical geometry/address mode.</summary>
    /// <param name="ABytes">Exactly four bytes, or eight when MLEN byte two is zero.</param>
    /// <param name="AInfo">Validated physical geometry; extended information MOI must agree with E1/E2.</param>
    /// <returns>Independent strict mapping-1.0 CC with data-area length excluding its header.</returns>
    /// <exception cref="EContactlessError">Magic, version, access, RFU, feature or capacity is unsupported.</exception>
    class function DecodeCapabilities(const ABytes: TBytes;
      const AInfo: TIso15693SystemInfo): TType5CapabilityContainer; static;
    /// <summary>Decodes acquired mapped memory and the single existing NDEF message under the selected access profile.</summary>
    /// <param name="AInfo">Acquired system information; not modified.</param>
    /// <param name="AAllowProprietaryAccess">Explicit known authenticated profile permits CC access code two; no authentication is performed by the codec.</param>
    /// <param name="AMemory">Complete physical blocks covering CC plus advertised data area, bounded by geometry.</param>
    /// <returns>Independent snapshot, retaining opaque prefix and block-tail bytes.</returns>
    /// <exception cref="EContactlessError">Mapping, access, TLV or acquired memory is invalid.</exception>
    /// <exception cref="ENdefError">Nonempty NDEF payload is malformed.</exception>
    class function DecodeSnapshot(const AInfo: TIso15693SystemInfo;
      const AMemory: TBytes; const AAllowProprietaryAccess: Boolean = False): TType5NdefSnapshot; static;
  end;

  /// <summary>Nonvisual Type 5 NDEF reader and verified length-last updater; public access by default.</summary>
  /// <remarks>Inactive constructor, existing initialized tags only. Single exclusive ISO 15693 session;
  /// no auto-format, permanent lock, AFI/DSFID/UID update, authentication, replay or rollback.
  /// Writes preserve CC, preceding proprietary TLVs and every byte outside the changed message region.
  /// Multi-block updates are not atomic; a failed dispatched write is explicitly uncertain.</remarks>
  TType5NdefCardReader = class(TComponent)
  private
    FSession, FActiveSession: IIso15693Session;
    FBusy, FAllowProprietaryAccess: Boolean;
    procedure SetAllowProprietaryAccess(const AValue: Boolean);
    procedure SetSession(const AValue: IIso15693Session);
    function BeginOperation: TIso15693SystemInfo;
    procedure EndOperation(const ASucceeded: Boolean);
    function ReadRange(const AInfo: TIso15693SystemInfo;
      const AOffset, ACount: Integer): TBytes;
    function Discover(const AInfo: TIso15693SystemInfo): TType5NdefSnapshot;
    procedure Replace(const AMessageBytes: TBytes);
  public
    /// <summary>Reads an existing NDEF message under the selected access profile and confirms CC/header coherence before release.</summary>
    /// <returns>Independent complete snapshot only after successful release.</returns>
    /// <exception cref="EContactlessError">Session, geometry, mapping, access or coherence fails.</exception>
    /// <exception cref="ENdefError">Acquired nonempty message is malformed.</exception>
    function ReadMessage: TType5NdefSnapshot;
    /// <summary>Replaces a writable existing NDEF TLV under the selected access profile and publishes its length last.</summary>
    /// <param name="AMessage">Nonempty logical records; encoded before hardware acquisition.</param>
    /// <exception cref="EContactlessError">Existing mapping, access, capacity or block-security preflight fails.</exception>
    /// <exception cref="ENdefError">Requested or existing NDEF framing is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any write dispatch, read-back, final comparison or release fails.</exception>
    /// <remarks>Preflights every affected physical block; invalidates length first, stages and verifies full
    /// read-modify-write blocks, then publishes one length byte. Extended length bytes are staged before FF.
    /// Matching acquired contents are a verified no-op. CC and complete message are checked again.</remarks>
    procedure WriteMessage(const AMessage: TNdefMessage);
    /// <summary>Publishes an initialized empty NDEF TLV while preserving unused former payload bytes.</summary>
    /// <exception cref="EContactlessError">Preflight fails.</exception>
    /// <exception cref="EContactlessWriteUncertain">A dispatched update or release cannot be established as complete.</exception>
    procedure ClearMessage;
    /// <summary>Retained ISO 15693 backend; cannot change while an operation is busy.</summary>
    property Session: IIso15693Session read FSession write SetSession;
    /// <summary>Explicit authenticated-session profile allows proprietary CC access code two; false by default.</summary>
    /// <remarks>Caller must supply authenticated Session; read-only code three remains rejected for writes.</remarks>
    property AllowProprietaryAccess: Boolean read FAllowProprietaryAccess write SetAllowProprietaryAccess;
    /// <summary>True throughout acquisition, protocol I/O and cleanup; nested calls are refused.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes;

procedure InvalidType5;
begin
  raise EType5NdefError.Create
    ('Invalid or unsupported Type 5 NDEF mapping or access.');
end;

class function TType5NdefCodec.DecodeCapabilities(const ABytes: TBytes;
  const AInfo: TIso15693SystemInfo): TType5CapabilityContainer;
var
  Units: Integer;
begin
  Result := Default (TType5CapabilityContainer);
  TIso15693Codec.ValidateInfo(AInfo);
  if not(Length(ABytes) in [4, 8]) then
    InvalidType5;
  if not(ABytes[0] in [$E1, $E2]) or ((ABytes[1] and $F0) <> $40) then
    InvalidType5;
  Result.Magic := ABytes[0];
  Result.MappingVersion := $40;
  Result.ReadAccess := (ABytes[1] shr 2) and 3;
  Result.WriteAccess := ABytes[1] and 3;
  if not(Result.ReadAccess in [0, 2]) or not(Result.WriteAccess in [0, 2, 3])
  then
    InvalidType5;
  Result.Features := ABytes[3];
  if (Result.Features and $E6) <> 0 then
    InvalidType5;
  Units := ABytes[2];
  if Units = 0 then
  begin
    if Length(ABytes) <> 8 then
      InvalidType5;
    if (ABytes[4] <> 0) or (ABytes[5] <> 0) then
      InvalidType5;
    Units := (Integer(ABytes[6]) shl 8) or ABytes[7];
  end
  else if Length(ABytes) <> 4 then
    InvalidType5;
  if Units = 0 then
    InvalidType5;
  if ((Result.Magic = $E2) and ((AInfo.InformationFlags and $10) = 0)) or
    ((Result.Magic = $E1) and ((AInfo.InformationFlags and $10) <> 0)) then
    InvalidType5;
  Result.HeaderBytes := Length(ABytes);
  Result.DataAreaBytes := Units * 8;
  if Result.DataAreaBytes > AInfo.BlockCount * AInfo.BlockSize - Result.HeaderBytes
  then
    InvalidType5;
  Result.RawBytes := CopyBytes(ABytes);
end;

class function TType5NdefCodec.DecodeSnapshot(const AInfo: TIso15693SystemInfo;
  const AMemory: TBytes; const AAllowProprietaryAccess: Boolean): TType5NdefSnapshot;
var
  CcSize, P, Limit, N, Header: Integer;
  Tag: Byte;
  procedure LengthField;
  begin
    if P >= Limit then
      InvalidType5;
    N := AMemory[P];
    Inc(P);
    Header := 2;
    if N = $FF then
    begin
      if P > Limit - 2 then
        InvalidType5;
      N := (Integer(AMemory[P]) shl 8) or AMemory[P + 1];
      Inc(P, 2);
      Header := 4;
      if N < 255 then
        InvalidType5;
    end;
    if N > Limit - P then
      InvalidType5;
  end;

begin
  Result := Default (TType5NdefSnapshot);
  TIso15693Codec.ValidateInfo(AInfo);
  if (Length(AMemory) < 8) or (Length(AMemory) > AInfo.BlockCount *
    AInfo.BlockSize) or (Length(AMemory) mod AInfo.BlockSize <> 0) then
    InvalidType5;
  CcSize := 4;
  if AMemory[2] = 0 then
    CcSize := 8;
  Result.Capabilities := DecodeCapabilities(Copy(AMemory, 0, CcSize), AInfo);
  if (Result.Capabilities.ReadAccess <> 0) and not AAllowProprietaryAccess then
    InvalidType5;
  Limit := CcSize + Result.Capabilities.DataAreaBytes;
  if Limit > Length(AMemory) then
    InvalidType5;
  P := CcSize;
  while P < Limit do
  begin
    Tag := AMemory[P];
    Inc(P);
    if Tag = 0 then
      Continue;
    if not(Tag in [3, $FD]) then
      InvalidType5;
    Result.TlvOffset := P - 1;
    LengthField;
    if Tag = $FD then
    begin
      Inc(P, N);
      Continue;
    end;
    if (P + N >= Limit) or (AMemory[P + N] <> $FE) then
      InvalidType5;
    Result.TlvHeaderBytes := Header;
    Result.MessageBytes := Copy(AMemory, P, N);
    if N > 0 then
      Result.Records := TNdefCodec.Decode(Result.MessageBytes);
    Result.Information := AInfo;
    Result.Information.Uid := CopyBytes(AInfo.Uid);
    Result.PhysicalBytes := CopyBytes(AMemory);
    Exit;
  end;
  InvalidType5;
end;

procedure TType5NdefCardReader.SetAllowProprietaryAccess(const AValue: Boolean);
begin
  if FBusy then InvalidType5;
  FAllowProprietaryAccess := AValue;
end;

procedure TType5NdefCardReader.SetSession(const AValue: IIso15693Session);
begin
  if FBusy then
    InvalidType5;
  FSession := AValue;
end;

function TType5NdefCardReader.BeginOperation: TIso15693SystemInfo;
begin
  Result := Default (TIso15693SystemInfo);
  if FBusy or (FSession = nil) then
    InvalidType5;
  FBusy := True;
  FActiveSession := FSession;
  try
    Result := FActiveSession.BeginSession;
  except
    FActiveSession := nil;
    FBusy := False;
    raise;
  end;
end;

procedure TType5NdefCardReader.EndOperation(const ASucceeded: Boolean);
begin
  try
    if ASucceeded then
      FActiveSession.EndSession
    else
      try
        FActiveSession.EndSession;
      except
      end;
  finally
    FActiveSession := nil;
    FBusy := False;
  end;
end;

function TType5NdefCardReader.ReadRange(const AInfo: TIso15693SystemInfo;
  const AOffset, ACount: Integer): TBytes;
var
  Block, Offset, P, N: Integer;
  B: TBytes;
begin
  Result := nil;
  if (AOffset < 0) or (ACount < 1) or
    (ACount > AInfo.BlockCount * AInfo.BlockSize - AOffset) then
    InvalidType5;
  SetLength(Result, ACount);
  P := 0;
  while P < ACount do
  begin
    Block := (AOffset + P) div AInfo.BlockSize;
    Offset := (AOffset + P) mod AInfo.BlockSize;
    B := FActiveSession.ReadBlock(Block);
    if Length(B) <> AInfo.BlockSize then
      InvalidType5;
    N := AInfo.BlockSize - Offset;
    if N > ACount - P then
      N := ACount - P;
    Move(B[Offset], Result[P], N);
    Inc(P, N);
  end;
end;

function TType5NdefCardReader.Discover(const AInfo: TIso15693SystemInfo)
  : TType5NdefSnapshot;
var
  Head, Memory: TBytes;
  Cc: TType5CapabilityContainer;
  N: Integer;
begin
  TIso15693Codec.ValidateInfo(AInfo);
  Head := ReadRange(AInfo, 0, 8);
  N := 4;
  if Head[2] = 0 then
    N := 8;
  Cc := TType5NdefCodec.DecodeCapabilities(Copy(Head, 0, N), AInfo);
  if (Cc.ReadAccess <> 0) and not FAllowProprietaryAccess then
    InvalidType5;
  N := Cc.HeaderBytes + Cc.DataAreaBytes;
  N := ((N + AInfo.BlockSize - 1) div AInfo.BlockSize) * AInfo.BlockSize;
  Memory := ReadRange(AInfo, 0, N);
  Result := TType5NdefCodec.DecodeSnapshot(AInfo, Memory, FAllowProprietaryAccess);
  if not BytesEqual(Result.Capabilities.RawBytes, Cc.RawBytes) or
    not BytesEqual(ReadRange(AInfo, 0, Cc.HeaderBytes), Cc.RawBytes) or
    not BytesEqual(ReadRange(AInfo, Result.TlvOffset, Result.TlvHeaderBytes),
    Copy(Memory, Result.TlvOffset, Result.TlvHeaderBytes)) then
    InvalidType5;
end;

function TType5NdefCardReader.ReadMessage: TType5NdefSnapshot;
var
  Info: TIso15693SystemInfo;
  Snapshot: TType5NdefSnapshot;
  Succeeded: Boolean;
begin
  Result := Default (TType5NdefSnapshot);
  Info := BeginOperation;
  Succeeded := False;
  try
    Snapshot := Discover(Info);
    Succeeded := True;
  finally
    EndOperation(Succeeded);
  end;
  Result := Snapshot;
end;

procedure TType5NdefCardReader.Replace(const AMessageBytes: TBytes);
var
  Info: TIso15693SystemInfo;
  Old, Verified: TType5NdefSnapshot;
  Working, Target, FinalBytes, BlockData: TBytes;
  Succeeded, Dispatched: Boolean;
  Header, LengthOffset, EndOffset, Block, I, Size: Integer;
  procedure Update(const Index: Integer; const Data: TBytes);
  begin
    Dispatched := True;
    FActiveSession.WriteBlock(Index, Data);
    if not BytesEqual(FActiveSession.ReadBlock(Index), Data) then
      InvalidType5;
    Move(Data[0], Working[Index * Size], Size);
  end;
  function DifferentBlock(const A, B: TBytes; const Index: Integer): Boolean;
  var
    J: Integer;
  begin
    Result := False;
    for J := Index * Size to (Index + 1) * Size - 1 do
      if A[J] <> B[J] then
      begin
        Result := True;
        Exit;
      end;
  end;

begin
  if Length(AMessageBytes) > Type5MaxMessageBytes then
    InvalidType5;
  Info := BeginOperation;
  Succeeded := False;
  Dispatched := False;
  try
    try
      Old := Discover(Info);
      if (Old.Capabilities.WriteAccess <> 0) and
        not (FAllowProprietaryAccess and (Old.Capabilities.WriteAccess = 2)) then
        InvalidType5;
      if not BytesEqual(Old.MessageBytes, AMessageBytes) then
      begin
        Header := 2;
        if Length(AMessageBytes) >= 255 then
          Header := 4;
        EndOffset := Old.TlvOffset + Header + Length(AMessageBytes);
        if EndOffset >= Old.Capabilities.HeaderBytes + Old.Capabilities.DataAreaBytes
        then
          InvalidType5;
        Size := Info.BlockSize;
        LengthOffset := Old.TlvOffset + 1;
        Working := CopyBytes(Old.PhysicalBytes);
        Target := CopyBytes(Working);
        Target[LengthOffset] := 0;
        if Header = 4 then
        begin
          Target[LengthOffset + 1] := Length(AMessageBytes) shr 8;
          Target[LengthOffset + 2] := Length(AMessageBytes) and $FF;
        end;
        if Length(AMessageBytes) > 0 then
          Move(AMessageBytes[0], Target[Old.TlvOffset + Header],
            Length(AMessageBytes));
        Target[EndOffset] := $FE;
        FinalBytes := CopyBytes(Target);
        if Header = 4 then
          FinalBytes[LengthOffset] := $FF
        else
          FinalBytes[LengthOffset] := Length(AMessageBytes);
        // All required block security checks precede the first dispatched write.
        for I := 0 to Length(Working) div Size - 1 do
          if DifferentBlock(Working, FinalBytes, I) or
            (I = LengthOffset div Size) then
            if FActiveSession.SecurityStatus(I) <> 0 then
              InvalidType5;
        Block := LengthOffset div Size;
        if Working[LengthOffset] <> 0 then
        begin
          BlockData := Copy(Working, Block * Size, Size);
          BlockData[LengthOffset mod Size] := 0;
          Update(Block, BlockData);
        end;
        for I := 0 to Length(Working) div Size - 1 do
          if DifferentBlock(Working, Target, I) then
            Update(I, Copy(Target, I * Size, Size));
        if FinalBytes[LengthOffset] <> 0 then
          Update(Block, Copy(FinalBytes, Block * Size, Size));
        Verified := Discover(Info);
        if not BytesEqual(Verified.Capabilities.RawBytes,
          Old.Capabilities.RawBytes) or not BytesEqual(Verified.MessageBytes,
          AMessageBytes) or not BytesEqual(Verified.PhysicalBytes, FinalBytes)
        then
          InvalidType5;
      end;
      Succeeded := True;
    finally
      EndOperation(Succeeded);
    end;
  except
    on E: Exception do
    begin
      if Dispatched then
        raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

procedure TType5NdefCardReader.WriteMessage(const AMessage: TNdefMessage);
var
  B: TBytes;
begin
  B := TNdefCodec.Encode(AMessage);
  Replace(B);
end;

procedure TType5NdefCardReader.ClearMessage;
begin
  Replace(nil);
end;

end.
