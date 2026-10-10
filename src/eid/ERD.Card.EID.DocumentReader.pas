unit ERD.Card.EID.DocumentReader;

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
  ERD.Card.Transport, ERD.Card.APDU, ERD.Card.Crypto.EAC,
  ERD.Card.EID.Access, ERD.Card.EID.SecureMessaging, ERD.Card.EID.MRZ,
  ERD.Card.EID.ICAO;

type
  /// <summary>Authenticated inner or pre-authentication ICAO status error, retaining only SW1/SW2.</summary>
  EIcaoStatusError = class(EIcaoAccessError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a status error without document/password/APDU contents.</summary>
    /// <param name="AStatusWord">Acquired status word.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Acquired status word; no implicit downgrade or retry.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>Requested ICAO LDS files; fingerprint and national eID services are separate access profiles.</summary>
  TIcaoDocumentSection = (
    /// <summary>DG1 identity/MRZ file 0101, decoded after complete acquisition.</summary>
    idsIdentity,
    /// <summary>DG2 face file 0102, decoded to supported encoded JPEG/JPEG 2000 blocks.</summary>
    idsFace,
    /// <summary>Opaque complete EF.COM file 011E; no fabricated DG availability.</summary>
    idsCommon,
    /// <summary>Opaque complete EF.SOD file 011D; reading does not verify hashes/signatures/trust.</summary>
    idsSecurityObject);
  /// <summary>Explicit nonempty requested LDS file set.</summary>
  TIcaoDocumentSections = set of TIcaoDocumentSection;

  /// <summary>One PACEInfo from EF.CardAccess; unsupported algorithms/parameters remain visible.</summary>
  TIcaoPaceInfo = record
    /// <summary>Owned complete DER OID value bytes.</summary>
    AlgorithmOid: TBytes;
    /// <summary>Acquired positive version integer.</summary>
    Version: Integer;
    /// <summary>Acquired standardized domain parameter, or minus one if absent.</summary>
    ParameterId: Integer;
    /// <summary>True only for version 2 ECDH-GM/AES-128 and parameter 12/13.</summary>
    Supported: Boolean;
  end;

  /// <summary>Owned PACEInfo array in acquired order.</summary>
  TIcaoPaceInfos = array of TIcaoPaceInfo;

  /// <summary>Complete independent requested LDS data after access authentication, integrity checks and transport release.</summary>
  /// <remarks>Normal record assignment shares arrays. BAC/PACE establishes access; document/issuer authenticity
  /// is not inferred. SOD, chip authentication, EAC authorization and national eID services are separate work.</remarks>
  TIcaoDocumentData = record
    /// <summary>Exactly the requested, successfully acquired sections.</summary>
    Sections: TIcaoDocumentSections;
    /// <summary>Explicit access profile used; no fallback was attempted.</summary>
    Security: TIcaoAccessSecurity;
    /// <summary>Owned complete EF.CardAccess for PACE; empty for explicitly selected BAC.</summary>
    CardAccess: TBytes;
    /// <summary>Parsed advertised PACE infos, including unsupported profiles; empty for BAC.</summary>
    PaceInfos: TIcaoPaceInfos;
    /// <summary>Owned exact DG1 bytes, empty when unrequested.</summary>
    DG1: TBytes;
    /// <summary>Owned exact DG2 bytes, empty when unrequested.</summary>
    DG2: TBytes;
    /// <summary>Owned exact EF.COM, empty when unrequested.</summary>
    Common: TBytes;
    /// <summary>Owned exact EF.SOD, empty when unrequested; signature/trust not verified.</summary>
    SecurityObject: TBytes;
    /// <summary>Checksum-validated MRZ identity when idsIdentity was requested.</summary>
    Identity: TMrzIdentity;
    /// <summary>Decoded supported face blocks when idsFace was requested; images remain encoded bytes.</summary>
    Biometrics: TIcaoBiometrics;
  end;

  /// <summary>Strict EF.CardAccess parser for PACEInfo and its explicit supported-profile boundary.</summary>
  TIcaoCardAccessCodec = class
  public
    /// <summary>Parses a complete bounded DER SET of SecurityInfo, without guessing an algorithm/domain parameter.</summary>
    /// <param name="AData">Exact EF.CardAccess, at most 4096 bytes; unknown SecurityInfo OIDs are preserved in the caller's raw data.</param>
    /// <returns>Owned PACEInfo entries; duplicate algorithm/parameter pairs fail visibly.</returns>
    class function Decode(const AData: TBytes): TIcaoPaceInfos; static;
  end;

  /// <summary>Nonvisual ICAO eMRTD/LDS reader with explicit BAC or PACE ECDH-GM/AES-128 access and secure messaging.</summary>
  /// <remarks>Construction opens no hardware. European travel-document applications can use this shared reader
  /// where the exact document exposes A0000002471001 and the selected access profile. Country/model compatibility
  /// is not inferred. One caller thread; configuration changes/reentrancy while Busy fail before I/O.</remarks>
  TICAODocumentReader = class(TComponent)
  private
    FTransport, FActiveTransport: ICardTransport;
    FProvider: ICardEacProvider;
    FPassword: TBytes;
    FSecurity: TIcaoAccessSecurity;
    FPasswordKind: TIcaoPasswordKind;
    FCurve: TCardPaceCurve;
    FChunk, FMaxFile, FMaxTotal, FTotal: Integer;
    FBusy: Boolean;
    FSecure: TIcaoSecureMessaging;
    procedure RequireIdle;
    procedure SetTransport(const Value: ICardTransport);
    procedure SetProvider(const Value: ICardEacProvider);
    procedure SetPassword(const Value: TBytes);
    function GetPassword: TBytes;
    procedure SetSecurity(const Value: TIcaoAccessSecurity);
    procedure SetPasswordKind(const Value: TIcaoPasswordKind);
    procedure SetCurve(const Value: TCardPaceCurve);
    procedure SetChunk(const Value: Integer);
    procedure SetMaxFile(const Value: Integer);
    procedure SetMaxTotal(const Value: Integer);
    function Exchange(const Command: TApduCommand): TApduResponse;
    procedure Select(const P1: Byte; const Data: TBytes);
    function ReadChunk(const Offset, Count: Integer): TBytes;
    function ReadFile(const FileId: Word; const Tag: Byte;
      const Limit: Integer): TBytes;
    procedure AuthenticateBac;
    procedure AuthenticatePace(const Infos: TIcaoPaceInfos);
    function GeneralAuthenticate(const Cla, SendTag, ReceiveTag: Byte;
      const Data: TBytes): TBytes;
    function FreshScalar: TBytes;
    procedure ValidateConfiguration;
  public
    /// <summary>Creates an inactive reader, PACE/brainpool defaults, 208-byte reads, one MiB per file and two MiB aggregate.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Clears retained access-password bytes; callers must not destroy a Busy reader.</summary>
    destructor Destroy; override;
    /// <summary>Reads requested complete files in one exclusive transaction with fresh access authentication.</summary>
    /// <param name="ASections">Nonempty identity/face/COM/SOD set; identity and face by default.</param>
    /// <returns>Complete owned data only after integrity/decoding and successful transport release.</returns>
    /// <remarks>PACE reads MF/EF.CardAccess before selecting the ICAO AID; no application reselection occurs
    /// after secure messaging starts. Large files use B1/DO54/DO53 beyond the B0 offset range. No PIN guessing,
    /// BAC fallback, APDU replay, write or document-authenticity claim.</remarks>
    function ReadDocument(const ASections: TIcaoDocumentSections = [idsIdentity,
      idsFace]): TIcaoDocumentData;
    /// <summary>Connected byte transport retained by reference; must also implement exclusive ICardTransaction.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
    /// <summary>Explicit maintained crypto backend with SHA-1, Triple DES, AES and validated PACE agreement.</summary>
    property CryptoProvider: ICardEacProvider read FProvider write SetProvider;
    /// <summary>Copied ASCII MRZ access information or six-digit CAN; getter returns an independent copy.</summary>
    /// <remarks>Use TIcaoAccessCodec.MrzInformation for a full MRZ. Clear with nil when idle; no password is logged.</remarks>
    property AccessPassword: TBytes read GetPassword write SetPassword;
    /// <summary>True during an acquired read, including provider/transport callbacks and cleanup.</summary>
    property Busy: Boolean read FBusy;
  published
    /// <summary>Explicit BAC or PACE ECDH-GM/AES-128; PACE by default.</summary>
    property Security: TIcaoAccessSecurity read FSecurity write SetSecurity
      default iasPaceGmAes128;
    /// <summary>Explicit MRZ/CAN password reference; BAC only accepts MRZ.</summary>
    property PasswordKind: TIcaoPasswordKind read FPasswordKind
      write SetPasswordKind default ipkMrz;
    /// <summary>Explicit standardized PACE curve, which must be advertised by EF.CardAccess.</summary>
    property PaceCurve: TCardPaceCurve read FCurve write SetCurve
      default ppcBrainpoolP256;
    /// <summary>Positive read-data count 1..220; defaults to 208, leaving space for protected B1/DO53 framing.</summary>
    property ChunkSize: Integer read FChunk write SetChunk default 208;
    /// <summary>Per-file maximum 2..1048576, including its complete TLV envelope.</summary>
    property MaxFileBytes: Integer read FMaxFile write SetMaxFile
      default 1048576;
    /// <summary>Aggregate raw-file limit 2..4194304, including EF.CardAccess when acquired.</summary>
    property MaxTotalBytes: Integer read FMaxTotal write SetMaxTotal
      default 2097152;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.TLV;

procedure InvalidDocument;
begin
  raise EIcaoAccessError.Create('Invalid or unsupported ICAO document access.');
end;

constructor EIcaoStatusError.Create(const AStatusWord: Word);
begin
  inherited CreateFmt('ICAO status %.4x.', [AStatusWord]);
  FStatusWord := AStatusWord;
end;

function Joined(const A, B: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, Length(A) + Length(B));
  if Length(A) > 0 then
    Move(A[0], Result[0], Length(A));
  if Length(B) > 0 then
    Move(B[0], Result[Length(A)], Length(B));
end;

function NativeCommand(const Ins, P1, P2: Byte; const Data: TBytes;
  const Le: Integer = 0): TApduCommand;
begin
  Result := Default (TApduCommand);
  Result.Ins := Ins;
  Result.P1 := P1;
  Result.P2 := P2;
  Result.Data := Data;
  if Le > 0 then
  begin
    Result.HasLe := True;
    Result.Le := Le;
  end;
end;

function IntegerValue(const Node: TTlvNode): Integer;
var
  Bytes: TBytes;
  I: Integer;
begin
  if Node.IsConstructed or not BytesEqual(Node.Tag, HexToBytes('02')) then
    InvalidDocument;
  Bytes := Node.Value;
  if (Length(Bytes) < 1) or (Length(Bytes) > 3) or ((Bytes[0] and $80) <> 0) or
    ((Length(Bytes) > 1) and (Bytes[0] = 0) and ((Bytes[1] and $80) = 0)) then
    InvalidDocument;
  Result := 0;
  for I := 0 to High(Bytes) do
    Result := Result * 256 + Bytes[I];
end;

function ByteOrder(const A, B: TBytes): Integer;
var
  I, N: Integer;
begin
  N := Length(A);
  if Length(B) < N then
    N := Length(B);
  for I := 0 to N - 1 do
    if A[I] <> B[I] then
    begin
      Result := Integer(A[I]) - Integer(B[I]);
      Exit;
    end;
  Result := Length(A) - Length(B);
end;

class function TIcaoCardAccessCodec.Decode(const AData: TBytes): TIcaoPaceInfos;
var
  Options: TTlvDecodeOptions;
  Doc: TTlvDocument;
  Error: TTlvError;
  Entry: TTlvNode;
  I, J, Index: Integer;
  Oid, Prefix, Previous, Encoded: TBytes;
  Info: TIcaoPaceInfo;
begin
  Result := nil;
  if (Length(AData) < 2) or (Length(AData) > 4096) then
    InvalidDocument;
  Options := DefaultTlvOptions;
  Options.MaxDepth := 8;
  Options.MaxNodes := 128;
  Options.MaxInputBytes := 4096;
  Options.AllowPadding := False;
  if not TTlvCodec.TryDecode(AData, Options, Doc, Error) then
    InvalidDocument;
  try
    if (Doc.Count <> 1) or not BytesEqual(Doc.Roots[0].Tag, HexToBytes('31'))
    then
      InvalidDocument;
    if not BytesEqual(TTlvCodec.Encode(Doc), AData) then
      InvalidDocument;
    Previous := nil;
    Prefix := HexToBytes('04007F0007020204');
    for I := 0 to Doc.Roots[0].ChildCount - 1 do
    begin
      Entry := Doc.Roots[0].Children[I];
      Encoded := TTlvCodec.EncodeNode(Entry);
      if (I > 0) and (ByteOrder(Previous, Encoded) > 0) then
        InvalidDocument;
      Previous := Encoded;
      if not BytesEqual(Entry.Tag, HexToBytes('30')) or (Entry.ChildCount < 2)
        or not BytesEqual(Entry.Children[0].Tag, HexToBytes('06')) then
        InvalidDocument;
      Oid := Entry.Children[0].Value;
      if Length(Oid) = 0 then
        InvalidDocument;
      if (Length(Oid) = 10) and BytesEqual(Copy(Oid, 0, 8), Prefix) then
      begin
        if (Entry.ChildCount < 2) or (Entry.ChildCount > 3) then
          InvalidDocument;
        Info := Default (TIcaoPaceInfo);
        Info.AlgorithmOid := Copy(Oid, 0, Length(Oid));
        Info.Version := IntegerValue(Entry.Children[1]);
        Info.ParameterId := -1;
        if Entry.ChildCount = 3 then
          Info.ParameterId := IntegerValue(Entry.Children[2]);
        if Info.Version < 1 then
          InvalidDocument;
        Info.Supported := (Info.Version = 2) and (Info.ParameterId in [12, 13])
          and BytesEqual(Oid, HexToBytes('04007F00070202040202'));
        for J := 0 to High(Result) do
          if BytesEqual(Result[J].AlgorithmOid, Info.AlgorithmOid) and
            (Result[J].ParameterId = Info.ParameterId) then
            InvalidDocument;
        Index := Length(Result);
        SetLength(Result, Index + 1);
        Result[Index] := Info;
      end;
    end;
  finally
    Doc.Free;
  end;
end;

constructor TICAODocumentReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSecurity := iasPaceGmAes128;
  FCurve := ppcBrainpoolP256;
  FChunk := 208;
  FMaxFile := 1048576;
  FMaxTotal := 2097152;
end;

destructor TICAODocumentReader.Destroy;
begin
  TCardCrypto.Clear(FPassword);
  inherited Destroy;
end;

procedure TICAODocumentReader.RequireIdle;
begin
  if FBusy then
    InvalidDocument;
end;

procedure TICAODocumentReader.SetTransport(const Value: ICardTransport);
begin
  RequireIdle;
  FTransport := Value;
end;

procedure TICAODocumentReader.SetProvider(const Value: ICardEacProvider);
begin
  RequireIdle;
  FProvider := Value;
end;

procedure TICAODocumentReader.SetPassword(const Value: TBytes);
var
  CopyValue: TBytes;
begin
  RequireIdle;
  if Length(Value) > 64 then
    InvalidDocument;
  CopyValue := Copy(Value, 0, Length(Value));
  TCardCrypto.Clear(FPassword);
  FPassword := CopyValue;
end;

function TICAODocumentReader.GetPassword: TBytes;
begin
  Result := Copy(FPassword, 0, Length(FPassword));
end;

procedure TICAODocumentReader.SetSecurity(const Value: TIcaoAccessSecurity);
begin
  RequireIdle;
  if (Ord(Value) < 0) or (Ord(Value) > 1) then
    InvalidDocument;
  FSecurity := Value;
end;

procedure TICAODocumentReader.SetPasswordKind(const Value: TIcaoPasswordKind);
begin
  RequireIdle;
  if (Ord(Value) < 0) or (Ord(Value) > 1) then
    InvalidDocument;
  FPasswordKind := Value;
end;

procedure TICAODocumentReader.SetCurve(const Value: TCardPaceCurve);
begin
  RequireIdle;
  if (Ord(Value) < 0) or (Ord(Value) > 1) then
    InvalidDocument;
  FCurve := Value;
end;

procedure TICAODocumentReader.SetChunk(const Value: Integer);
begin
  RequireIdle;
  if (Value < 1) or (Value > 220) then
    InvalidDocument;
  FChunk := Value;
end;

procedure TICAODocumentReader.SetMaxFile(const Value: Integer);
begin
  RequireIdle;
  if (Value < 2) or (Value > 1048576) then
    InvalidDocument;
  FMaxFile := Value;
end;

procedure TICAODocumentReader.SetMaxTotal(const Value: Integer);
begin
  RequireIdle;
  if (Value < 2) or (Value > 4194304) then
    InvalidDocument;
  FMaxTotal := Value;
end;

procedure TICAODocumentReader.ValidateConfiguration;
begin
  RequireIdle;
  if (FTransport = nil) or (FProvider = nil) or
    ((FSecurity = iasBac) and (FPasswordKind <> ipkMrz)) then
    InvalidDocument;
  TIcaoAccessCodec.ValidatePassword(FPassword, FPasswordKind);
end;

function TICAODocumentReader.Exchange(const Command: TApduCommand)
  : TApduResponse;
var
  Request, Reply: TBytes;
begin
  Request := nil;
  Reply := nil;
  try
    try
      if FSecure <> nil then
        Request := FSecure.Protect(Command)
      else
        Request := TApduCodec.EncodeCommand(Command);
      Reply := FActiveTransport.Exchange(Request);
      if FSecure <> nil then
        Result := FSecure.Unprotect(Reply)
      else
        Result := TApduCodec.DecodeResponse(Reply);
    except
      if FSecure <> nil then
        FSecure.Clear;
      raise;
    end;
  finally
    TCardCrypto.Clear(Request);
    TCardCrypto.Clear(Reply);
  end;
end;

procedure TICAODocumentReader.Select(const P1: Byte; const Data: TBytes);
var
  Response: TApduResponse;
begin
  Response := Exchange(NativeCommand($A4, P1, $0C, Data));
  if Response.StatusWord <> $9000 then
    raise EIcaoStatusError.Create(Response.StatusWord);
  if Length(Response.Data) <> 0 then
    InvalidDocument;
end;

function TICAODocumentReader.ReadChunk(const Offset, Count: Integer): TBytes;
var
  C: TApduCommand;
  R: TApduResponse;
  Data: TBytes;
  Bytes, Position, I, Envelope: Integer;
begin
  Result := nil;
  if (Offset < 0) or (Offset > $FFFFFF) or (Count < 1) or (Count > 220) then
    InvalidDocument;
  if Offset <= $7FFF then
    C := NativeCommand($B0, (Offset shr 8) and $7F, Offset and $FF, nil, Count)
  else
  begin
    Bytes := 2;
    if Offset > $FFFF then
      Bytes := 3;
    SetLength(Data, Bytes + 2);
    Data[0] := $54;
    Data[1] := Bytes;
    for I := 0 to Bytes - 1 do
      Data[2 + I] := (Offset shr ((Bytes - I - 1) * 8)) and $FF;
    Envelope := 2;
    if Count >= 128 then
      Envelope := 3;
    C := NativeCommand($B1, 0, 0, Data, Count + Envelope);
  end;
  R := Exchange(C);
  if (R.StatusWord <> $9000) and (R.StatusWord <> $6282) then
    raise EIcaoStatusError.Create(R.StatusWord);
  if Offset <= $7FFF then
    Result := R.Data
  else
  begin
    if (Length(R.Data) < 2) or (R.Data[0] <> $53) then
      InvalidDocument;
    Position := 2;
    Bytes := R.Data[1];
    if Bytes = $81 then
    begin
      if Length(R.Data) < 3 then
        InvalidDocument;
      Position := 3;
      Bytes := R.Data[2];
      if Bytes < 128 then
        InvalidDocument;
    end
    else if Bytes >= 128 then
      InvalidDocument;
    if (Bytes <> Count) or (Length(R.Data) <> Position + Bytes) then
      InvalidDocument;
    Result := Copy(R.Data, Position, Bytes);
  end;
  if Length(Result) <> Count then
    InvalidDocument;
end;

function TICAODocumentReader.ReadFile(const FileId: Word; const Tag: Byte;
  const Limit: Integer): TBytes;
var
  Header, Extra, Chunk, Id: TBytes;
  Count, LengthBytes, Total, Position, N, I: Integer;
begin
  Result := nil;
  SetLength(Id, 2);
  Id[0] := FileId shr 8;
  Id[1] := FileId and $FF;
  Select($02, Id);
  Header := ReadChunk(0, 2);
  if Header[0] <> Tag then
    InvalidDocument;
  Count := Header[1];
  if Count >= $80 then
  begin
    LengthBytes := Count and $7F;
    if (LengthBytes < 1) or (LengthBytes > 3) then
      InvalidDocument;
    Extra := ReadChunk(2, LengthBytes);
    if Extra[0] = 0 then
      InvalidDocument;
    Count := 0;
    for I := 0 to High(Extra) do
      Count := Count * 256 + Extra[I];
    if Count < 128 then
      InvalidDocument;
    Header := Joined(Header, Extra);
  end;
  Total := Length(Header) + Count;
  if (Total > Limit) or (Total > FMaxTotal - FTotal) then
    InvalidDocument;
  SetLength(Result, Total);
  Move(Header[0], Result[0], Length(Header));
  Position := Length(Header);
  while Position < Total do
  begin
    N := Total - Position;
    if N > FChunk then
      N := FChunk;
    Chunk := ReadChunk(Position, N);
    Move(Chunk[0], Result[Position], N);
    Inc(Position, N);
    TCardCrypto.Clear(Chunk);
  end;
  Inc(FTotal, Total);
end;

procedure TICAODocumentReader.AuthenticateBac;
var
  Response: TApduResponse;
  Seed, Enc, MacKey, Key24, Zero, RndCard, RndReader, KReader, Plain, Cipher,
    Tag, Answer, KSeed, SessionEnc, SessionMac, Counter: TBytes;
  I: Integer;
begin
  try
    Seed := FProvider.Sha1(FPassword);
    if Length(Seed) <> 20 then
      InvalidDocument;
    SetLength(Seed, 16);
    Enc := TIcaoAccessCodec.DeriveKey(FProvider, Seed, 1, True);
    MacKey := TIcaoAccessCodec.DeriveKey(FProvider, Seed, 2, True);
    Response := Exchange(NativeCommand($84, 0, 0, nil, 8));
    if Response.StatusWord <> $9000 then
      raise EIcaoStatusError.Create(Response.StatusWord);
    RndCard := Response.Data;
    if Length(RndCard) <> 8 then
      InvalidDocument;
    RndReader := FProvider.RandomBytes(8);
    KReader := FProvider.RandomBytes(16);
    if (Length(RndReader) <> 8) or (Length(KReader) <> 16) then
      InvalidDocument;
    Plain := Joined(RndReader, Joined(RndCard, KReader));
    Key24 := TIcaoAccessCodec.ExpandDesKey(Enc);
    Zero := nil;
    SetLength(Zero, 8);
    Cipher := FProvider.TripleDesCbc(Key24, Zero, Plain, True);
    if Length(Cipher) <> 32 then
      InvalidDocument;
    Tag := TIcaoAccessCodec.RetailMac(FProvider, MacKey, Cipher);
    Response := Exchange(NativeCommand($82, 0, 0, Joined(Cipher, Tag), 40));
    if Response.StatusWord <> $9000 then
      raise EIcaoStatusError.Create(Response.StatusWord);
    if Length(Response.Data) <> 40 then
      InvalidDocument;
    Answer := Copy(Response.Data, 0, 32);
    TCardCrypto.Clear(Tag);
    Tag := TIcaoAccessCodec.RetailMac(FProvider, MacKey, Answer);
    if not TCardCrypto.EqualSecret(Tag, Copy(Response.Data, 32, 8)) then
      InvalidDocument;
    TCardCrypto.Clear(Plain);
    Plain := FProvider.TripleDesCbc(Key24, Zero, Answer, False);
    if (Length(Plain) <> 32) or not TCardCrypto.EqualSecret(RndCard,
      Copy(Plain, 0, 8)) or not TCardCrypto.EqualSecret(RndReader,
      Copy(Plain, 8, 8)) then
      InvalidDocument;
    KSeed := Copy(Plain, 16, 16);
    for I := 0 to 15 do
      KSeed[I] := KSeed[I] xor KReader[I];
    SessionEnc := TIcaoAccessCodec.DeriveKey(FProvider, KSeed, 1, True);
    SessionMac := TIcaoAccessCodec.DeriveKey(FProvider, KSeed, 2, True);
    Counter := Joined(Copy(RndCard, 4, 4), Copy(RndReader, 4, 4));
    FSecure := TIcaoSecureMessaging.Create(FProvider, iasBac, SessionEnc,
      SessionMac, Counter);
  finally
    TCardCrypto.Clear(Seed);
    TCardCrypto.Clear(Enc);
    TCardCrypto.Clear(MacKey);
    TCardCrypto.Clear(Key24);
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(RndCard);
    TCardCrypto.Clear(RndReader);
    TCardCrypto.Clear(KReader);
    TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(Tag);
    TCardCrypto.Clear(Answer);
    TCardCrypto.Clear(KSeed);
    TCardCrypto.Clear(SessionEnc);
    TCardCrypto.Clear(SessionMac);
    TCardCrypto.Clear(Counter);
  end;
end;

function TICAODocumentReader.GeneralAuthenticate(const Cla, SendTag,
  ReceiveTag: Byte; const Data: TBytes): TBytes;
var
  C: TApduCommand;
  R: TApduResponse;
  Wrapped: TBytes;
begin
  Wrapped := nil;
  if SendTag <> 0 then
  begin
    if Length(Data) > 127 then
      InvalidDocument;
    SetLength(Wrapped, Length(Data) + 2);
    Wrapped[0] := SendTag;
    Wrapped[1] := Length(Data);
    if Length(Data) > 0 then
      Move(Data[0], Wrapped[2], Length(Data));
  end;
  Wrapped := Joined(HexToBytes('7C' + IntToHex(Length(Wrapped), 2)), Wrapped);
  C := NativeCommand($86, 0, 0, Wrapped, 256);
  C.Cla := Cla;
  R := Exchange(C);
  if R.StatusWord <> $9000 then
    raise EIcaoStatusError.Create(R.StatusWord);
  if (Length(R.Data) < 4) or (R.Data[0] <> $7C) or
    (R.Data[1] <> Length(R.Data) - 2) or (R.Data[2] <> ReceiveTag) or
    (R.Data[3] <> Length(R.Data) - 4) then
    InvalidDocument;
  Result := Copy(R.Data, 4, Length(R.Data) - 4);
end;

function TICAODocumentReader.FreshScalar: TBytes;
var
  Order: TBytes;
  I, Attempt: Integer;
  Less, Nonzero: Boolean;
begin
  if FCurve = ppcNistP256 then
    Order := HexToBytes
      ('FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551')
  else
    Order := HexToBytes
      ('A9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7');
  Result := nil;
  for Attempt := 1 to 32 do
  begin
    TCardCrypto.Clear(Result);
    Result := FProvider.RandomBytes(32);
    if Length(Result) <> 32 then
      InvalidDocument;
    Less := False;
    Nonzero := False;
    for I := 0 to 31 do
      if Result[I] <> 0 then
        Nonzero := True;
    for I := 0 to 31 do
      if Result[I] <> Order[I] then
      begin
        Less := Result[I] < Order[I];
        Break;
      end;
    if Less and Nonzero then
      Exit;
  end;
  TCardCrypto.Clear(Result);
  InvalidDocument;
end;

procedure TICAODocumentReader.AuthenticatePace(const Infos: TIcaoPaceInfos);
var
  Parameter, I, Matches: Integer;
  Seed, KPi, Zero, Nonce, MappingSecret, AgreementSecret, OwnMapping,
    CardMapping, OwnAgreement, CardAgreement, Shared, SessionEnc, SessionMac,
    TokenInput, Token, Received, Counter: TBytes;
  Agreement: ICardPaceAgreement;
  R: TApduResponse;
  Ambiguous: Boolean;
begin
  Parameter := 12;
  if FCurve = ppcBrainpoolP256 then
    Parameter := 13;
  Matches := 0;
  for I := 0 to High(Infos) do
    if Infos[I].Supported and (Infos[I].ParameterId = Parameter) then
      Inc(Matches);
  if Matches <> 1 then
    InvalidDocument;
  Ambiguous := False;
  for I := 0 to High(Infos) do
    if (Infos[I].ParameterId >= 0) and (Infos[I].ParameterId <> Parameter) then
      Ambiguous := True;
  try
    if FPasswordKind = ipkMrz then
      Seed := FProvider.Sha1(FPassword)
    else
      Seed := Copy(FPassword, 0, Length(FPassword));
    if (FPasswordKind = ipkMrz) and (Length(Seed) <> 20) then
      InvalidDocument;
    KPi := TIcaoAccessCodec.DeriveKey(FProvider, Seed, 3, False);
    TokenInput := HexToBytes('800A04007F00070202040202830101');
    TokenInput[High(TokenInput)] := Ord(FPasswordKind) + 1;
    if Ambiguous then
      TokenInput := Joined(TokenInput,
        HexToBytes('8401' + IntToHex(Parameter, 2)));
    R := Exchange(NativeCommand($22, $C1, $A4, TokenInput));
    if R.StatusWord <> $9000 then
      raise EIcaoStatusError.Create(R.StatusWord);
    if Length(R.Data) <> 0 then
      InvalidDocument;
    Nonce := GeneralAuthenticate($10, 0, $80, nil);
    if Length(Nonce) <> 16 then
      InvalidDocument;
    Zero := nil;
    SetLength(Zero, 16);
    Received := FProvider.DecryptCbc(KPi, Zero, Nonce);
    if Length(Received) <> 16 then
      InvalidDocument;
    TCardCrypto.Clear(Nonce);
    Nonce := Received;
    Received := nil;
    MappingSecret := FreshScalar;
    AgreementSecret := FreshScalar;
    Agreement := FProvider.CreatePaceAgreement(FCurve, MappingSecret,
      AgreementSecret);
    if Agreement = nil then
      InvalidDocument;
    OwnMapping := Agreement.MappingPublicKey;
    if Length(OwnMapping) <> 65 then
      InvalidDocument;
    CardMapping := GeneralAuthenticate($10, $81, $82, OwnMapping);
    OwnAgreement := Agreement.MapAndGenerate(CardMapping, Nonce);
    if Length(OwnAgreement) <> 65 then
      InvalidDocument;
    CardAgreement := GeneralAuthenticate($10, $83, $84, OwnAgreement);
    Shared := Agreement.Agree(CardAgreement);
    if Length(Shared) <> 32 then
      InvalidDocument;
    SessionEnc := TIcaoAccessCodec.DeriveKey(FProvider, Shared, 1, False);
    SessionMac := TIcaoAccessCodec.DeriveKey(FProvider, Shared, 2, False);
    TokenInput := Joined(HexToBytes('7F494F060A04007F000702020402028641'),
      CardAgreement);
    Token := TCardCrypto.Cmac(FProvider, SessionMac, TokenInput);
    SetLength(Token, 8);
    Received := GeneralAuthenticate(0, $85, $86, Token);
    if Length(Received) <> 8 then
      InvalidDocument;
    TokenInput := Joined(HexToBytes('7F494F060A04007F000702020402028641'),
      OwnAgreement);
    TCardCrypto.Clear(Token);
    Token := TCardCrypto.Cmac(FProvider, SessionMac, TokenInput);
    SetLength(Token, 8);
    if not TCardCrypto.EqualSecret(Token, Received) then
      InvalidDocument;
    Counter := nil;
    SetLength(Counter, 16);
    FSecure := TIcaoSecureMessaging.Create(FProvider, iasPaceGmAes128,
      SessionEnc, SessionMac, Counter);
  finally
    Agreement := nil;
    TCardCrypto.Clear(Seed);
    TCardCrypto.Clear(KPi);
    TCardCrypto.Clear(Zero);
    TCardCrypto.Clear(Nonce);
    TCardCrypto.Clear(MappingSecret);
    TCardCrypto.Clear(AgreementSecret);
    TCardCrypto.Clear(Shared);
    TCardCrypto.Clear(SessionEnc);
    TCardCrypto.Clear(SessionMac);
    TCardCrypto.Clear(TokenInput);
    TCardCrypto.Clear(Token);
    TCardCrypto.Clear(Received);
    TCardCrypto.Clear(Counter);
  end;
end;

function TICAODocumentReader.ReadDocument(const ASections
  : TIcaoDocumentSections): TIcaoDocumentData;
var
  Transaction: ICardTransaction;
  Owns, Succeeded: Boolean;
  Data: TIcaoDocumentData;
  Limit: Integer;
begin
  Result := Default (TIcaoDocumentData);
  ValidateConfiguration;
  if ASections = [] then
    InvalidDocument;
  if not Supports(FTransport, ICardTransaction, Transaction) then
    InvalidDocument;
  FBusy := True;
  FActiveTransport := FTransport;
  FTotal := 0;
  Owns := False;
  Succeeded := False;
  try
    Transaction.BeginTransaction;
    Owns := True;
    Data := Default (TIcaoDocumentData);
    Data.Sections := ASections;
    Data.Security := FSecurity;
    if FSecurity = iasPaceGmAes128 then
    begin
      Select(0, HexToBytes('3F00'));
      Limit := FMaxFile;
      if Limit > 4096 then
        Limit := 4096;
      Data.CardAccess := ReadFile($011C, $31, Limit);
      Data.PaceInfos := TIcaoCardAccessCodec.Decode(Data.CardAccess);
    end;
    Select($04, HexToBytes('A0000002471001'));
    if FSecurity = iasBac then
      AuthenticateBac
    else
      AuthenticatePace(Data.PaceInfos);
    if idsIdentity in ASections then
    begin
      Data.DG1 := ReadFile($0101, $61, FMaxFile);
      Data.Identity := TIcaoDataCodec.DecodeDG1(Data.DG1);
    end;
    if idsFace in ASections then
    begin
      Data.DG2 := ReadFile($0102, $75, FMaxFile);
      Data.Biometrics := TIcaoDataCodec.DecodeDG2(Data.DG2);
    end;
    if idsCommon in ASections then
      Data.Common := ReadFile($011E, $60, FMaxFile);
    if idsSecurityObject in ASections then
      Data.SecurityObject := ReadFile($011D, $77, FMaxFile);
    Succeeded := True;
  finally
    try
      if Owns then
        if Succeeded then
          Transaction.EndTransaction
        else
          try
            Transaction.EndTransaction;
          except
          end;
    finally
      FreeAndNil(FSecure);
      FActiveTransport := nil;
      FBusy := False;
    end;
  end;
  Result := Data;
end;

end.
