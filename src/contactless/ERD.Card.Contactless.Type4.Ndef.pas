unit ERD.Card.Contactless.Type4.Ndef;

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
  ERD.Card.Transport, ERD.Card.Contactless, ERD.Card.Ndef;

const
  /// <summary>ISO identifier of the NFC Forum Type 4 Capability Container file.</summary>
  Type4CapabilityFileId = $E103;
  /// <summary>Maximum supported complete Type 4 CC bytes, including CCLEN.</summary>
  Type4MaxCapabilityBytes = 4096;
  /// <summary>Maximum number of supported ordinary NDEF file descriptors in one CC.</summary>
  Type4MaxNdefFiles = 16;
  /// <summary>Maximum ordinary NDEF file size, including two-byte NLEN; no extended-offset commands.</summary>
  Type4MaxFileBytes = $7FFF;

type
  /// <summary>Invalid or unsupported Type 4 mapping, access, size or reader configuration.</summary>
  EType4NdefError = class(EContactlessError);
  /// <summary>Explicit NDEF application-selection dialect; never tried as a fallback.</summary>
  TType4ApplicationVersion = (
    /// <summary>Mapping 1.0: AID D2760000850100 and SELECT FILE P2=00.</summary>
    t4av1,
    /// <summary>Mapping 2.0: AID D2760000850101 and SELECT FILE P2=0C.</summary>
    t4av2
  );
  /// <summary>Ordinary tag-04 NDEF file-control descriptor, without authentication inference.</summary>
  TType4NdefFile = record
    /// <summary>ISO file identifier, not a DESFire native file number.</summary>
    FileId: Word;
    /// <summary>Complete file capacity including two-byte NLEN, from five through 32767.</summary>
    MaxFileBytes: Integer;
    /// <summary>Raw access byte; zero is public, 80..FE requires a separate proprietary access layer.</summary>
    ReadAccess: Byte;
    /// <summary>Raw access byte; zero is public, FF is read-only, 80..FE is proprietary.</summary>
    WriteAccess: Byte;
  end;
  /// <summary>Ordered supported ordinary NDEF files; assignment shares the array.</summary>
  TType4NdefFiles = array of TType4NdefFile;
  /// <summary>Complete decoded mapping 1.0/2.0 CC with independent source bytes and file array.</summary>
  /// <remarks>Ordinary record assignment shares dynamic arrays. RawBytes retains opaque optional TLVs.</remarks>
  TType4CapabilityContainer = record
    /// <summary>Exact complete CC bytes, including length, header and optional TLVs.</summary>
    RawBytes: TBytes;
    /// <summary>Exactly 10 or 20 hexadecimal; unknown minor/major mappings are refused.</summary>
    MappingVersion: Byte;
    /// <summary>Card-advertised maximum READ BINARY response-data bytes, excluding SW1/SW2.</summary>
    MLe: Integer;
    /// <summary>Card-advertised maximum UPDATE BINARY command-data bytes, excluding APDU framing.</summary>
    MLc: Integer;
    /// <summary>Independent descriptor array; a caller must disambiguate multiple files.</summary>
    Files: TType4NdefFiles;
  end;
  /// <summary>Complete NDEF file snapshot returned only after successful transaction release.</summary>
  /// <remarks>Ordinary assignment shares buffers; codec outputs themselves are independent.</remarks>
  TType4NdefSnapshot = record
    /// <summary>CC acquired in the same transaction as the message.</summary>
    Capabilities: TType4CapabilityContainer;
    /// <summary>Explicitly resolved ISO NDEF file descriptor.</summary>
    FileInfo: TType4NdefFile;
    /// <summary>Exact independent message bytes; empty for NLEN zero.</summary>
    MessageBytes: TBytes;
    /// <summary>Independent logical NDEF records; empty for NLEN zero.</summary>
    Records: TNdefMessage;
  end;
  /// <summary>Bounded CC parser and short ISO 7816 Type 4 command builders; no I/O.</summary>
  /// <remarks>Ordinary two-byte NLEN files only. Extended tag-06 descriptors, mapping 3.x,
  /// extended APDUs and proprietary authentication require separate implementations.</remarks>
  TType4NdefCodec = class
  public
    /// <summary>Decodes exactly one complete CC with mandatory first tag-04 descriptor.</summary>
    /// <param name="ABytes">15..Type4MaxCapabilityBytes, exactly matching CCLEN.</param>
    /// <returns>Independent complete CC and ordinary NDEF descriptors; opaque optional TLVs retained.</returns>
    /// <exception cref="EType4NdefError">Header, TLV, identifier, access, size, duplicates or mapping is invalid.</exception>
    class function DecodeCapabilities(const ABytes: TBytes): TType4CapabilityContainer; static;
    /// <summary>Resolves a caller-selected NDEF file, refusing an ambiguous default.</summary>
    /// <param name="ACapabilities">Decoded CC; not modified.</param>
    /// <param name="AFileId">Explicit ISO identifier, or zero only when exactly one descriptor exists.</param>
    /// <returns>Validated descriptor copied by value.</returns>
    /// <exception cref="EType4NdefError">Identifier is unavailable, reserved or ambiguous.</exception>
    class function FindFile(const ACapabilities: TType4CapabilityContainer;
      const AFileId: Word = 0): TType4NdefFile; static;
    /// <summary>Builds the explicitly selected NDEF application SELECT, without fallback.</summary>
    /// <param name="AVersion">Version 1.0 without Le, or 2.0 with short Le=256.</param>
    /// <returns>Independent SELECT-by-name command with P2=00.</returns>
    /// <exception cref="EType4NdefError">Version is invalid.</exception>
    class function SelectApplication(const AVersion: TType4ApplicationVersion): TBytes; static;
    /// <summary>Builds SELECT FILE for CC or an ordinary ISO NDEF file.</summary>
    /// <param name="AFileId">CC E103 or a non-reserved NDEF file identifier.</param>
    /// <param name="AVersion">Explicit P2 dialect.</param>
    /// <returns>Independent short command without Le.</returns>
    /// <exception cref="EType4NdefError">Identifier or dialect is invalid.</exception>
    class function SelectFile(const AFileId: Word; const AVersion: TType4ApplicationVersion): TBytes; static;
    /// <summary>Builds one bounded READ BINARY using a 15-bit offset and short Le.</summary>
    /// <param name="AOffset">Zero-based byte offset; offset plus count must not exceed Type4MaxFileBytes.</param>
    /// <param name="ACount">One through 256 bytes, additionally bounded by the caller's MLe.</param>
    /// <returns>Independent five-byte command, with Le zero representing 256.</returns>
    /// <exception cref="EType4NdefError">Offset or count is invalid.</exception>
    class function ReadBinary(const AOffset, ACount: Integer): TBytes; static;
    /// <summary>Builds one bounded UPDATE BINARY; this builder does not select or authorize a file.</summary>
    /// <param name="AOffset">Zero-based selected-file offset.</param>
    /// <param name="AData">One through 255 bytes, copied; caller also enforces MLc and selected-file rights.</param>
    /// <returns>Independent short command without Le.</returns>
    /// <exception cref="EType4NdefError">Offset, data length or range is invalid.</exception>
    class function UpdateBinary(const AOffset: Integer; const AData: TBytes): TBytes; static;
  end;
  /// <summary>Non-visual public Type 4 NDEF component through an ISO 7816 APDU transport.</summary>
  /// <remarks>Inactive constructor; configure and call on one thread without reentrancy.
  /// Every operation requires ICardTransaction. No application fallback, RF reset, 61xx/6Cxx replay,
  /// file creation, native DESFire commands, authentication or CC/access-right updates.</remarks>
  TType4NdefCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FApplicationVersion: TType4ApplicationVersion;
    FMaxReadChunk, FMaxWriteChunk: Integer;
    function BeginOperation: ICardTransaction;
    procedure EndOperation(const ATx: ICardTransaction; const ASucceeded: Boolean);
    function Send(const ACommand: TBytes; const AExpectedSize: Integer): TBytes;
    function ReadRange(const AOffset, ACount, AMLe: Integer): TBytes;
    function Discover: TType4CapabilityContainer;
    function ReadSelected(const ACc: TType4CapabilityContainer;
      const AFile: TType4NdefFile): TType4NdefSnapshot;
    procedure Replace(const AFileId: Word; const ANdef: TBytes);
  public
    /// <summary>Creates an inactive mapping-2.0 component with short read/write limits 256/255.</summary>
    /// <param name="AOwner">Optional owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Selects the configured application and reads its complete CC in one transaction.</summary>
    /// <returns>Independent CC only after successful release; proprietary descriptors can be inspected.</returns>
    /// <exception cref="EContactlessError">Configuration, status, size or mapping validation fails.</exception>
    function ReadCapabilities: TType4CapabilityContainer;
    /// <summary>Reads and decodes one public NDEF file with bounded MLe chunks.</summary>
    /// <param name="AFileId">Explicit file identifier, or zero for a single-file CC.</param>
    /// <returns>Independent complete snapshot; NLEN zero returns no records.</returns>
    /// <exception cref="EContactlessError">Selection, ambiguity, access, length or reader checks fail.</exception>
    /// <exception cref="ENdefError">Acquired nonempty NDEF is malformed.</exception>
    function ReadMessage(const AFileId: Word = 0): TType4NdefSnapshot;
    /// <summary>Replaces an existing publicly readable/writable NDEF file, publishing NLEN last.</summary>
    /// <param name="AMessage">Nonempty logical records, encoded before I/O.</param>
    /// <param name="AFileId">Explicit file identifier, or zero for a single-file CC.</param>
    /// <exception cref="EContactlessError">Preflight selection, access, capacity or MLc fails.</exception>
    /// <exception cref="ENdefError">Requested or existing NDEF framing is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any exception after an UPDATE dispatch, including release.</exception>
    /// <remarks>Invalidation and every payload chunk are read back before proceeding. Final CC and
    /// NLEN/message are verified. Multi-command writes are not atomic; no retry or rollback.</remarks>
    procedure WriteMessage(const AMessage: TNdefMessage; const AFileId: Word = 0);
    /// <summary>Sets an existing public NDEF file's NLEN to zero; former payload bytes remain present.</summary>
    /// <param name="AFileId">Explicit file identifier, or zero for a single-file CC.</param>
    /// <exception cref="EContactlessError">Preflight fails.</exception>
    /// <exception cref="EContactlessWriteUncertain">A dispatched update cannot be established as complete.</exception>
    procedure ClearMessage(const AFileId: Word = 0);
    /// <summary>Retained connected ISO 7816 transport with exclusive transaction capability.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Explicit NDEF selection dialect; default mapping 2.0, never automatically changed.</summary>
    property ApplicationVersion: TType4ApplicationVersion read FApplicationVersion write FApplicationVersion;
    /// <summary>Local response-data limit, 15..256; also clamped by card MLe.</summary>
    property MaxReadChunk: Integer read FMaxReadChunk write FMaxReadChunk;
    /// <summary>Local update-data limit, 2..255; also clamped by card MLc.</summary>
    property MaxWriteChunk: Integer read FMaxWriteChunk write FMaxWriteChunk;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

procedure Fail;
begin raise EType4NdefError.Create('Invalid or unsupported Type 4 NDEF mapping or access.'); end;

function ReadWord(const B: TBytes; const P: Integer): Word;
begin Result := (Word(B[P]) shl 8) or B[P + 1]; end;

function WordBytes(const W: Word): TBytes;
begin Result := nil; SetLength(Result, 2); Result[0] := W shr 8; Result[1] := W and $FF; end;

procedure CheckId(const Id: Word);
begin
  case Id of $0000, $E102, $E103, $3F00, $3FFF, $FFFF: Fail; end;
end;

procedure CheckFile(const F: TType4NdefFile);
begin
  CheckId(F.FileId);
  if (F.MaxFileBytes < 5) or (F.MaxFileBytes > Type4MaxFileBytes) then Fail;
  if (F.ReadAccess <> 0) and not ((F.ReadAccess >= $80) and (F.ReadAccess <= $FE)) then Fail;
  if (F.WriteAccess <> 0) and (F.WriteAccess < $80) then Fail;
end;

class function TType4NdefCodec.DecodeCapabilities(const ABytes: TBytes): TType4CapabilityContainer;
var P, N, I, Count: Integer; Tag: Byte; F: TType4NdefFile;
begin
  Result := Default(TType4CapabilityContainer);
  if (Length(ABytes) < 15) or (Length(ABytes) > Type4MaxCapabilityBytes) then Fail;
  if ReadWord(ABytes, 0) <> Length(ABytes) then Fail;
  if not (ABytes[2] in [$10, $20]) then Fail;
  Result.MappingVersion := ABytes[2]; Result.MLe := ReadWord(ABytes, 3); Result.MLc := ReadWord(ABytes, 5);
  if (Result.MLe < 15) or (Result.MLc < 1) or (ABytes[7] <> 4) then Fail;
  P := 7; Count := 0;
  while P < Length(ABytes) do
  begin
    Tag := ABytes[P]; Inc(P);
    if (Tag = 0) or (Tag = $FE) or (Tag = 6) then Fail;
    if P >= Length(ABytes) then Fail;
    N := ABytes[P]; Inc(P);
    if (N = $FF) or (N > Length(ABytes) - P) then Fail;
    if Tag = 4 then
    begin
      if (N <> 6) or (Count >= Type4MaxNdefFiles) then Fail;
      F.FileId := ReadWord(ABytes, P); F.MaxFileBytes := ReadWord(ABytes, P + 2);
      F.ReadAccess := ABytes[P + 4]; F.WriteAccess := ABytes[P + 5]; CheckFile(F);
      for I := 0 to Count - 1 do if Result.Files[I].FileId = F.FileId then Fail;
      SetLength(Result.Files, Count + 1); Result.Files[Count] := F; Inc(Count);
    end;
    Inc(P, N);
  end;
  if Count = 0 then Fail;
  Result.RawBytes := CopyBytes(ABytes);
end;

class function TType4NdefCodec.FindFile(const ACapabilities: TType4CapabilityContainer;
  const AFileId: Word): TType4NdefFile;
var I: Integer;
begin
  Result := Default(TType4NdefFile);
  if (Length(ACapabilities.Files) < 1) or (Length(ACapabilities.Files) > Type4MaxNdefFiles) then Fail;
  if AFileId = 0 then
  begin
    if Length(ACapabilities.Files) <> 1 then Fail;
    Result := ACapabilities.Files[0]; CheckFile(Result); Exit;
  end;
  CheckId(AFileId);
  for I := 0 to High(ACapabilities.Files) do if ACapabilities.Files[I].FileId = AFileId then
  begin Result := ACapabilities.Files[I]; CheckFile(Result); Exit; end;
  Fail;
end;

class function TType4NdefCodec.SelectApplication(const AVersion: TType4ApplicationVersion): TBytes;
begin
  case AVersion of
    t4av1: Result := HexToBytes('00A4040007D2760000850100');
    t4av2: Result := HexToBytes('00A4040007D276000085010100');
  else Fail; Result := nil; end;
end;

class function TType4NdefCodec.SelectFile(const AFileId: Word; const AVersion: TType4ApplicationVersion): TBytes;
var C: TApduCommand;
begin
  if AFileId <> Type4CapabilityFileId then CheckId(AFileId);
  C := Default(TApduCommand); C.INS := $A4; C.Data := WordBytes(AFileId);
  case AVersion of t4av1: C.P2 := 0; t4av2: C.P2 := $0C; else Fail; end;
  Result := TApduCodec.EncodeCommand(C);
end;

procedure CheckRange(const Offset, Count, MaxCount: Integer);
begin
  if (Offset < 0) or (Offset >= Type4MaxFileBytes) or (Count < 1) or
    (Count > MaxCount) then Fail;
  if Count > Type4MaxFileBytes - Offset then Fail;
end;

class function TType4NdefCodec.ReadBinary(const AOffset, ACount: Integer): TBytes;
var C: TApduCommand;
begin
  CheckRange(AOffset, ACount, 256); C := Default(TApduCommand);
  C.INS := $B0; C.P1 := AOffset shr 8; C.P2 := AOffset and $FF;
  C.HasLe := True; C.Le := ACount; Result := TApduCodec.EncodeCommand(C);
end;

class function TType4NdefCodec.UpdateBinary(const AOffset: Integer; const AData: TBytes): TBytes;
var C: TApduCommand;
begin
  CheckRange(AOffset, Length(AData), 255); C := Default(TApduCommand);
  C.INS := $D6; C.P1 := AOffset shr 8; C.P2 := AOffset and $FF; C.Data := AData;
  Result := TApduCodec.EncodeCommand(C);
end;

constructor TType4NdefCardReader.Create(AOwner: TComponent);
begin inherited Create(AOwner); FApplicationVersion := t4av2; FMaxReadChunk := 256; FMaxWriteChunk := 255; end;

function TType4NdefCardReader.BeginOperation: ICardTransaction;
begin
  Result := nil;
  TType4NdefCodec.SelectApplication(FApplicationVersion);
  if (FTransport = nil) or (FMaxReadChunk < 15) or (FMaxReadChunk > 256) or
    (FMaxWriteChunk < 2) or (FMaxWriteChunk > 255) then Fail;
  if not Supports(FTransport, ICardTransaction, Result) then Fail;
  Result.BeginTransaction;
end;

procedure TType4NdefCardReader.EndOperation(const ATx: ICardTransaction; const ASucceeded: Boolean);
begin
  if ASucceeded then ATx.EndTransaction
  else begin try ATx.EndTransaction; except end; end;
end;

function TType4NdefCardReader.Send(const ACommand: TBytes; const AExpectedSize: Integer): TBytes;
var R: TApduResponse;
begin
  R := TApduCodec.DecodeResponse(FTransport.Exchange(ACommand));
  if R.StatusWord <> ApduStatusSuccess then raise EContactlessStatusError.Create(R.StatusWord);
  if (AExpectedSize >= 0) and (Length(R.Data) <> AExpectedSize) then Fail;
  if (AExpectedSize < 0) and (Length(R.Data) > 256) then Fail;
  Result := R.Data;
end;

function TType4NdefCardReader.ReadRange(const AOffset, ACount, AMLe: Integer): TBytes;
var P, N, Limit: Integer; B: TBytes;
begin
  Result := nil;
  if (ACount < 0) or (AOffset < 0) or (ACount > Type4MaxFileBytes) or
    (AOffset > Type4MaxFileBytes - ACount) or (AMLe < 15) then Fail;
  Limit := FMaxReadChunk; if AMLe < Limit then Limit := AMLe;
  SetLength(Result, ACount); P := 0;
  while P < ACount do
  begin
    N := ACount - P; if N > Limit then N := Limit;
    B := Send(TType4NdefCodec.ReadBinary(AOffset + P, N), N);
    Move(B[0], Result[P], N); Inc(P, N);
  end;
end;

function TType4NdefCardReader.Discover: TType4CapabilityContainer;
var First, Raw, Rest: TBytes; N, MLe: Integer;
begin
  Send(TType4NdefCodec.SelectApplication(FApplicationVersion), -1);
  Send(TType4NdefCodec.SelectFile(Type4CapabilityFileId, FApplicationVersion), 0);
  First := Send(TType4NdefCodec.ReadBinary(0, 15), 15);
  N := ReadWord(First, 0); MLe := ReadWord(First, 3);
  if (N < 15) or (N > Type4MaxCapabilityBytes) or (MLe < 15) or
    (ReadWord(First, 5) < 1) or (First[2] <> (Ord(FApplicationVersion) + 1) * $10) then Fail;
  Raw := CopyBytes(First);
  if N > 15 then
  begin
    Rest := ReadRange(15, N - 15, MLe); SetLength(Raw, N); Move(Rest[0], Raw[15], Length(Rest));
  end;
  Result := TType4NdefCodec.DecodeCapabilities(Raw);
end;

function TType4NdefCardReader.ReadSelected(const ACc: TType4CapabilityContainer;
  const AFile: TType4NdefFile): TType4NdefSnapshot;
var N: Integer; LengthBytes: TBytes;
begin
  Result := Default(TType4NdefSnapshot);
  if AFile.ReadAccess <> 0 then Fail;
  LengthBytes := ReadRange(0, 2, ACc.MLe); N := ReadWord(LengthBytes, 0);
  if N > AFile.MaxFileBytes - 2 then Fail;
  Result.MessageBytes := ReadRange(2, N, ACc.MLe);
  if N > 0 then Result.Records := TNdefCodec.Decode(Result.MessageBytes);
  // Detect NLEN changes during acquisition; no automatic restart or partial snapshot.
  if not BytesEqual(ReadRange(0, 2, ACc.MLe), LengthBytes) then Fail;
  Result.Capabilities := ACc; Result.FileInfo := AFile;
end;

function TType4NdefCardReader.ReadCapabilities: TType4CapabilityContainer;
var Tx: ICardTransaction; Cc: TType4CapabilityContainer; Succeeded: Boolean;
begin
  Result := Default(TType4CapabilityContainer); Tx := BeginOperation; Succeeded := False;
  try Cc := Discover; Succeeded := True;
  finally EndOperation(Tx, Succeeded); end;
  Result := Cc;
end;

function TType4NdefCardReader.ReadMessage(const AFileId: Word): TType4NdefSnapshot;
var Tx: ICardTransaction; Cc: TType4CapabilityContainer; F: TType4NdefFile;
  S: TType4NdefSnapshot; Succeeded: Boolean;
begin
  Result := Default(TType4NdefSnapshot); if AFileId <> 0 then CheckId(AFileId);
  Tx := BeginOperation; Succeeded := False;
  try
    Cc := Discover; F := TType4NdefCodec.FindFile(Cc, AFileId);
    if F.ReadAccess <> 0 then Fail;
    Send(TType4NdefCodec.SelectFile(F.FileId, FApplicationVersion), 0);
    S := ReadSelected(Cc, F); Succeeded := True;
  finally EndOperation(Tx, Succeeded); end;
  Result := S;
end;

procedure TType4NdefCardReader.Replace(const AFileId: Word; const ANdef: TBytes);
var Tx: ICardTransaction; Cc: TType4CapabilityContainer; F: TType4NdefFile;
  Previous, Verified: TType4NdefSnapshot; Dispatched, Succeeded: Boolean;
  Limit, P, N: Integer; Data, Raw: TBytes;
  procedure UpdateVerified(const AOffset: Integer; const AData: TBytes);
  var Wire: TBytes;
  begin
    Wire := TType4NdefCodec.UpdateBinary(AOffset, AData); Dispatched := True;
    Send(Wire, 0);
    if not BytesEqual(ReadRange(AOffset, Length(AData), Cc.MLe), AData) then Fail;
  end;
begin
  if AFileId <> 0 then CheckId(AFileId);
  Tx := BeginOperation; Dispatched := False; Succeeded := False;
  try
    try
      Cc := Discover; F := TType4NdefCodec.FindFile(Cc, AFileId);
      if (F.ReadAccess <> 0) or (F.WriteAccess <> 0) or (Cc.MLc < 2) or
        (Length(ANdef) > F.MaxFileBytes - 2) then Fail;
      Send(TType4NdefCodec.SelectFile(F.FileId, FApplicationVersion), 0);
      Previous := ReadSelected(Cc, F);
      if not BytesEqual(Previous.MessageBytes, ANdef) then
      begin
        if Length(Previous.MessageBytes) <> 0 then UpdateVerified(0, WordBytes(0));
        Limit := FMaxWriteChunk; if Cc.MLc < Limit then Limit := Cc.MLc;
        P := 0;
        while P < Length(ANdef) do
        begin
          N := Length(ANdef) - P; if N > Limit then N := Limit;
          Data := Copy(ANdef, P, N); UpdateVerified(2 + P, Data); Inc(P, N);
        end;
        if Length(ANdef) > 0 then UpdateVerified(0, WordBytes(Word(Length(ANdef))));
        Send(TType4NdefCodec.SelectFile(Type4CapabilityFileId, FApplicationVersion), 0);
        Raw := ReadRange(0, Length(Cc.RawBytes), Cc.MLe);
        if not BytesEqual(Raw, Cc.RawBytes) then Fail;
        Send(TType4NdefCodec.SelectFile(F.FileId, FApplicationVersion), 0);
        Verified := ReadSelected(Cc, F);
        if not BytesEqual(Verified.MessageBytes, ANdef) then Fail;
      end;
      Succeeded := True;
    finally EndOperation(Tx, Succeeded); end;
  except
    on E: Exception do begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

procedure TType4NdefCardReader.WriteMessage(const AMessage: TNdefMessage; const AFileId: Word);
var Wire: TBytes;
begin Wire := TNdefCodec.Encode(AMessage); Replace(AFileId, Wire); end;

procedure TType4NdefCardReader.ClearMessage(const AFileId: Word);
begin Replace(AFileId, nil); end;

end.
