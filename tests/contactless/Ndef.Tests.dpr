program NdefTests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Ndef, ERD.Card.Ndef.Records, ERD.Card.Transport,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2, ERD.Card.Contactless.Type2.Ndef;

type
  TMemoryScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Memory, Cc, StaticLocks, DynamicLocks, Configuration: TBytes;
    Commands: array of TBytes;
    Images: array of TBytes;
    Model: TType2TagModel;
    Begins, Ends, Reads, Writes, FailWrite, FailRead, BadRead, FinalLength, Offset: Integer;
    Active, BeginFails, EndFails, RejectWrite, SuppressWrite, CorruptCc: Boolean;
    constructor Create(const AModel: TType2TagModel; const AInitial: TBytes; const AOffset: Integer = 0);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
var Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin Inc(Checks); if not AValue then raise Exception.Create(AMessage); end;

function One(const R: TNdefRecord): TNdefMessage;
begin Result := nil; SetLength(Result, 1); Result[0] := R; end;

function Unknown(const N: Integer): TNdefMessage;
var B: TBytes; I: Integer;
begin
  SetLength(B, N); for I := 0 to N - 1 do B[I] := Byte(I and $FF);
  Result := One(TNdefCodec.NewRecord(ntfUnknown, nil, nil, B));
end;

function CcFor(const M: TType2TagModel): TBytes;
begin
  Result := HexToBytes('E1100000');
  case M of
    ttmUltralight, ttmUltralightEv1_48, ttmNtag210: Result[2] := 6;
    ttmUltralightEv1_128, ttmNtag212: Result[2] := $10;
    ttmNtag213: Result[2] := $12;
    ttmNtag215: Result[2] := $3E;
    ttmNtag216: Result[2] := $6D;
  end;
end;

function Store(const M: TType2TagModel; const Wire: TBytes; const Offset: Integer = 0): TBytes;
var I, Header: Integer;
begin
  Result := nil; SetLength(Result, TType2Layout.UserByteCount(M));
  for I := 0 to High(Result) do Result[I] := 0;
  Header := 2; if Length(Wire) >= 255 then Header := 4;
  Check(Offset + Header + Length(Wire) <= Length(Result), 'Fixture fits memory');
  Result[Offset] := 3;
  if Header = 2 then Result[Offset + 1] := Length(Wire)
  else begin Result[Offset + 1] := $FF; Result[Offset + 2] := Length(Wire) shr 8; Result[Offset + 3] := Length(Wire) and $FF; end;
  if Length(Wire) > 0 then Move(Wire[0], Result[Offset + Header], Length(Wire));
  I := Offset + Header + Length(Wire);
  if I < Length(Result) then Result[I] := $FE;
end;

procedure BadWire(const S: string);
var M: TNdefMessage; Failed: Boolean;
begin
  Failed := False;
  try M := TNdefCodec.Decode(HexToBytes(S)); except on ENdefError do Failed := True; end;
  Check(Failed, 'Reject malformed NDEF ' + S);
end;

procedure Framing;
var M, D, Clone: TNdefMessage; B, CopyB, P: TBytes; I, J, N: Integer; Failed: Boolean;
begin
  // Independent NFC Forum short-record vectors, not produced by the encoder.
  B := HexToBytes('D101055402656E4869'); D := TNdefCodec.Decode(B);
  Check((Length(D) = 1) and (D[0].Tnf = ntfWellKnown) and
    (BytesToHex(D[0].RecordType) = '54') and (BytesToHex(D[0].Payload) = '02656E4869'), 'Text wire vector');
  Check(BytesEqual(TNdefCodec.Encode(D), B), 'Canonical text vector');
  D := TNdefCodec.Decode(HexToBytes('D00000'));
  Check((D[0].Tnf = ntfEmpty) and (Length(D[0].Payload) = 0), 'Empty record is a nonempty message');
  // Leading/middle/final chunks, including identifier on the leading chunk only.
  D := TNdefCodec.Decode(HexToBytes('B90102015449616236000263645600026566'));
  Check((Length(D) = 1) and (BytesToHex(D[0].Id) = '49') and
    (BytesToHex(D[0].Payload) = '616263646566'), 'Three chunks reassemble type and id');
  Check(BytesToHex(TNdefCodec.Encode(D)) = 'D90106015449616263646566', 'Chunks normalize');
  for N := 0 to 520 do
  begin
    M := Unknown(N); B := TNdefCodec.Encode(M); D := TNdefCodec.Decode(B);
    Check(BytesEqual(D[0].Payload, M[0].Payload), 'SR/32-bit payload boundary');
    if N <= 255 then Check((B[0] and $10) <> 0, 'Short payload length')
    else Check((B[0] and $10) = 0, 'Long payload length');
  end;
  M := One(TNdefRecords.Uri('https://www.example.org')); SetLength(M, 2); M[1] := TNdefRecords.Text('Hello', 'en');
  B := TNdefCodec.Encode(M); D := TNdefCodec.Decode(B);
  Check((B[0] and $C0) = $80, 'Only MB on first record');
  Check(Length(D) = 2, 'Multiple records');
  Clone := TNdefCodec.Clone(D); CopyB := CopyBytes(B); D[0].Payload[0] := 99;
  Check(BytesEqual(TNdefCodec.Encode(Clone), CopyB), 'Deep clone and decode ownership');
  B[0] := 0; Check(BytesEqual(TNdefCodec.Encode(Clone), CopyB), 'Wire input does not alias decoded arrays');
  for I := 1 to Length(CopyB) - 1 do
  begin
    Failed := False;
    try D := TNdefCodec.Decode(Copy(CopyB, 0, I)); except on ENdefError do Failed := True; end;
    Check(Failed, 'Every truncation of multi-record vector');
  end;
  BadWire(''); BadWire('51010055'); BadWire('D70000'); BadWire('D60000');
  BadWire('D00001FF'); BadWire('D50100AA'); BadWire('D101005400');
  BadWire('F1010054'); BadWire('B1010054'); BadWire('B101005456010055');
  BadWire('B1010054D60000'); BadWire('B10100545E000000');
  BadWire('C101FFFFFFFF54'); BadWire('C1010000000154');
  BadWire('91010054D1010054'); BadWire('9101005411010054');
  Failed := False;
  try D := TNdefCodec.Decode(CopyB, Length(CopyB) - 1); except on ENdefError do Failed := True; end;
  Check(Failed, 'Caller byte bound'); Failed := False;
  try D := TNdefCodec.Decode(CopyB, NdefMaxMessageBytes, 1); except on ENdefError do Failed := True; end;
  Check(Failed, 'Caller record bound');
  SetLength(M, NdefMaxRecords); for I := 0 to High(M) do M[I] := TNdefCodec.NewRecord(ntfEmpty, nil, nil, nil);
  Check(Length(TNdefCodec.Decode(TNdefCodec.Encode(M))) = NdefMaxRecords, 'Maximum record count');
  SetLength(M, NdefMaxRecords + 1); Failed := False;
  try B := TNdefCodec.Encode(M); except on ENdefError do Failed := True; end; Check(Failed, 'Record overflow');
  SetLength(P, 255); SetLength(B, 255);
  for J := 0 to 254 do begin P[J] := Byte(J); B[J] := Byte(254 - J); end;
  M := One(TNdefCodec.NewRecord(ntfMime, P, B, nil)); D := TNdefCodec.Decode(TNdefCodec.Encode(M));
  Check(BytesEqual(D[0].RecordType, P) and BytesEqual(D[0].Id, B), 'Maximum type/id sizes');
  SetLength(B, 256); Failed := False;
  try M := One(TNdefCodec.NewRecord(ntfUnknown, nil, B, nil)); except on ENdefError do Failed := True; end;
  Check(Failed, 'Identifier overflow');
  M := Unknown(NdefMaxMessageBytes - 6); B := TNdefCodec.Encode(M);
  Check(Length(B) = NdefMaxMessageBytes, 'Maximum message size including header');
  Check(Length(TNdefCodec.Decode(B)[0].Payload) = NdefMaxMessageBytes - 6, 'Maximum message decode');
  M := Unknown(NdefMaxMessageBytes - 5); Failed := False;
  try B := TNdefCodec.Encode(M); except on ENdefError do Failed := True; end; Check(Failed, 'Total message overflow');
  M := Unknown(600000); SetLength(M, 2); M[1] := M[0]; Failed := False;
  try Clone := TNdefCodec.Clone(M); except on ENdefError do Failed := True; end;
  Check(Failed, 'Clone validates combined size before copying payloads');
  // A single logical record is still bounded by the physical chunk count.
  SetLength(B, NdefMaxChunks * 3);
  for I := 0 to NdefMaxChunks - 1 do
  begin B[I * 3] := $36; B[I * 3 + 1] := 0; B[I * 3 + 2] := 0; end;
  B[0] := $B5; B[Length(B) - 3] := $56;
  D := TNdefCodec.Decode(B); Check((Length(D) = 1) and (Length(D[0].Payload) = 0), 'Maximum zero-byte chunks');
  B[Length(B) - 3] := $36; SetLength(B, Length(B) + 3);
  B[Length(B) - 3] := $56; B[Length(B) - 2] := 0; B[Length(B) - 1] := 0; Failed := False;
  try D := TNdefCodec.Decode(B); except on ENdefError do Failed := True; end; Check(Failed, 'Physical chunk budget');
  // Deterministic wire mutations must either fail structurally or normalize to stable logical records.
  for I := 0 to High(CopyB) do for J := 0 to 7 do
  begin
    B := CopyBytes(CopyB); B[I] := B[I] xor (1 shl J); Failed := False;
    try D := TNdefCodec.Decode(B); except on ENdefError do Failed := True; end;
    if not Failed then
    begin
      P := TNdefCodec.Encode(D); Clone := TNdefCodec.Decode(P);
      Check(BytesEqual(TNdefCodec.Encode(Clone), P), 'Accepted mutation normalizes consistently');
    end;
  end;
  Writeln('PASS: NDEF framing, chunks, ownership and bounds');
end;

procedure BadText(const S: string);
var T: TNdefText; R: TNdefRecord; Failed: Boolean;
begin
  R := TNdefCodec.NewRecord(ntfWellKnown, HexToBytes('54'), nil, HexToBytes(S)); Failed := False;
  try T := TNdefRecords.DecodeText(R); except on ENdefError do Failed := True; end;
  Check(Failed, 'Malformed Text RTD ' + S);
end;

procedure Records;
var R: TNdefRecord; T: TNdefText; S: UnicodeString; B: TBytes; M, D: TNdefMessage;
  I: Integer; Failed: Boolean;
begin
  S := UnicodeString('Hello ') + WideChar($00E9) + WideChar($D83D) + WideChar($DE03);
  for I := 0 to 1 do
  begin
    R := TNdefRecords.Text(S, 'nl-BE', I = 1); T := TNdefRecords.DecodeText(R);
    Check((T.Text = S) and (T.Language = 'nl-BE') and (T.Utf16 = (I = 1)), 'Unicode Text RTD round trip');
  end;
  R := TNdefCodec.NewRecord(ntfWellKnown, HexToBytes('54'), nil, HexToBytes('800041D83DDE03'));
  T := TNdefRecords.DecodeText(R); Check(T.Text = UnicodeString('A') + WideChar($D83D) + WideChar($DE03), 'UTF16 default big endian');
  R.Payload := HexToBytes('80FFFE41003DD803DE'); T := TNdefRecords.DecodeText(R);
  Check(T.Text = UnicodeString('A') + WideChar($D83D) + WideChar($DE03), 'UTF16 little endian BOM');
  BadText(''); BadText('40'); BadText('0265'); BadText('0120');
  BadText('00C080'); BadText('00EDA080'); BadText('00F4908080'); BadText('00F09F');
  BadText('8000'); BadText('80D800'); BadText('80DC00'); BadText('80D8000041');
  Failed := False;
  try R := TNdefRecords.Text(UnicodeString(WideChar($D800)), 'en'); except on ENdefError do Failed := True; end;
  Check(Failed, 'Unpaired application surrogate');
  R := TNdefRecords.Uri('https://www.example.org'); Check(R.Payload[0] = 2, 'Longest web prefix');
  Check(TNdefRecords.DecodeUri(R) = 'https://www.example.org', 'URI vector');
  R := TNdefRecords.Uri('urn:epc:id:test'); Check(R.Payload[0] = $1E, 'Longest URN prefix');
  R := TNdefRecords.Uri('custom:' + S); Check(TNdefRecords.DecodeUri(R) = 'custom:' + S, 'Opaque URI scheme and Unicode');
  for I := 0 to 35 do
  begin
    B := HexToBytes('0078'); B[0] := I;
    R := TNdefCodec.NewRecord(ntfWellKnown, HexToBytes('55'), nil, B);
    Check(TNdefRecords.DecodeUri(TNdefRecords.Uri(TNdefRecords.DecodeUri(R))) = TNdefRecords.DecodeUri(R), 'All URI prefixes');
  end;
  R.Payload := HexToBytes('24'); Failed := False;
  try S := TNdefRecords.DecodeUri(R); except on ENdefError do Failed := True; end; Check(Failed, 'Reserved URI prefix');
  R.Payload := HexToBytes('00'); Failed := False;
  try S := TNdefRecords.DecodeUri(R); except on ENdefError do Failed := True; end; Check(Failed, 'Empty URI');
  B := HexToBytes('DEADBEEF'); R := TNdefRecords.Mime('Application/Octet-Stream', B); B[0] := 0;
  Check((BytesToHex(R.Payload) = 'DEADBEEF') and (BytesToHex(R.RecordType) = '6170706C69636174696F6E2F6F637465742D73747265616D'), 'MIME lowercase and ownership');
  Failed := False;
  try R := TNdefRecords.Mime('text/plain; charset=utf-8', nil); except on ENdefError do Failed := True; end;
  Check(Failed, 'Bare media type requirement');
  R := TNdefRecords.External('Example.ORG', 'Card+Data', B);
  Check(BytesToHex(R.RecordType) = '6578616D706C652E6F72673A636172642B64617461', 'External normalization');
  Failed := False;
  try R := TNdefRecords.External('bad..org', 'data', nil); except on ENdefError do Failed := True; end;
  Check(Failed, 'Empty external domain label');
  SetLength(M, 4); M[0] := TNdefRecords.Uri('https://example.org'); M[1] := TNdefRecords.Text('Titel', 'nl');
  M[2] := TNdefRecords.Text('Title', 'en'); M[3] := TNdefRecords.External('example.org', 'opaque', HexToBytes('0102'));
  R := TNdefRecords.SmartPoster(M); D := TNdefRecords.DecodeSmartPoster(R);
  Check((Length(D) = 4) and BytesEqual(D[3].Payload, M[3].Payload), 'Smart Poster preserves extensions');
  D[3].Payload[0] := $FF; Check(R.Payload[High(R.Payload) - 1] = 1, 'Poster decode independent');
  M[2] := TNdefRecords.Text('Duplicate', 'NL'); Failed := False;
  try R := TNdefRecords.SmartPoster(M); except on ENdefError do Failed := True; end; Check(Failed, 'Duplicate title language');
  M := One(TNdefRecords.Text('Missing URI', 'en')); Failed := False;
  try R := TNdefRecords.SmartPoster(M); except on ENdefError do Failed := True; end; Check(Failed, 'Poster needs URI');
  M := One(TNdefRecords.Uri('https://example.org')); R := TNdefRecords.SmartPoster(M); SetLength(M, 2); M[1] := R;
  Failed := False;
  try R := TNdefRecords.SmartPoster(M); except on ENdefError do Failed := True; end; Check(Failed, 'Nested posters bounded');
  M[1] := TNdefCodec.NewRecord(ntfWellKnown, HexToBytes('616374'), nil, HexToBytes('03')); Failed := False;
  try R := TNdefRecords.SmartPoster(M); except on ENdefError do Failed := True; end; Check(Failed, 'Invalid poster action');
  Writeln('PASS: strict Text/URI, MIME/external and Smart Poster records');
end;

procedure Mapping;
var M: TType2TagModel; Memory, Cc, Wire, Original: TBytes; S: TType2NdefSnapshot;
  Plan: TType2NdefWritePlan; O, I: Integer; Failed: Boolean;
begin
  Wire := HexToBytes('D101045503616263');
  for M := Low(TType2TagModel) to High(TType2TagModel) do
  begin
    Memory := Store(M, Wire); Cc := CcFor(M); S := TType2NdefMapping.Decode(M, Cc, Memory);
    Check(S.HasNdef and not S.ReadOnly and (S.Capacity = Integer(Cc[2]) * 8) and
      BytesEqual(S.MessageBytes, Wire), 'All physical/CC capacities');
    Cc[3] := $0F; S := TType2NdefMapping.Decode(M, Cc, Memory); Check(S.ReadOnly, 'Read-only CC readable');
    Failed := False;
    try Plan := TType2NdefMapping.Prepare(M, Cc, Memory, Wire); except on EType2NdefError do Failed := True; end;
    Check(Failed, 'Read-only CC write refusal');
  end;
  // Actual NTAG213 factory control TLV: dynamic lock address 160, 12 bits, outside CC data.
  Memory := Store(ttmNtag213, nil, 5); Move(HexToBytes('0103A00C34')[0], Memory[0], 5);
  Cc := CcFor(ttmNtag213); S := TType2NdefMapping.Decode(ttmNtag213, Cc, Memory);
  Check(S.HasNdef and (S.TlvOffset = 5) and (Length(S.Records) = 0), 'NTAG213 factory mapping');
  Plan := TType2NdefMapping.Prepare(ttmNtag213, Cc, Memory, Wire);
  Check(BytesEqual(Copy(Plan.Committed, 0, 5), HexToBytes('0103A00C34')), 'Lock TLV prefix preserved');
  Memory[2] := $40; Failed := False;
  try S := TType2NdefMapping.Decode(ttmNtag213, Cc, Memory); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'Internal reserved hole not interpreted as contiguous NDEF');
  Memory[2] := $A4; Failed := False;
  try S := TType2NdefMapping.Decode(ttmNtag213, Cc, Memory); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'Lock TLV cannot redirect lock checks to configuration bytes');
  Memory := Store(ttmNtag216, nil); Cc := CcFor(ttmNtag216); Original := CopyBytes(Memory);
  Plan := TType2NdefMapping.Prepare(ttmNtag216, Cc, Memory, TNdefCodec.Encode(Unknown(300)));
  Check(BytesEqual(Original, Memory), 'Planner leaves caller memory unchanged');
  S := TType2NdefMapping.Decode(ttmNtag216, Cc, Plan.Invalidated); Check(Length(S.Records) = 0, 'Invalidated phase empty');
  S := TType2NdefMapping.Decode(ttmNtag216, Cc, Plan.Prepared); Check(Length(S.Records) = 0, 'Prepared extended phase empty');
  S := TType2NdefMapping.Decode(ttmNtag216, Cc, Plan.Committed); Check(Length(S.MessageBytes) = 306, 'Extended TLV message length');
  for O := 0 to 3 do
  begin
    Memory := Store(ttmNtag216, nil, O); Failed := False;
    try Plan := TType2NdefMapping.Prepare(ttmNtag216, Cc, Memory, TNdefCodec.Encode(Unknown(300)));
    except on EType2NdefError do Failed := True; end;
    Check(Failed = (O = 1), 'Extended publication rejects only split length field');
  end;
  Memory := Store(ttmNtag215, Wire); Cc := CcFor(ttmNtag215);
  for I := 496 to High(Memory) do Memory[I] := $A5;
  Plan := TType2NdefMapping.Prepare(ttmNtag215, Cc, Memory, TNdefCodec.Encode(Unknown(300)));
  Check(BytesEqual(Copy(Memory, 496, 8), Copy(Plan.Committed, 496, 8)), 'Physical bytes beyond advertised capacity preserved');
  Cc[2] := 64; Failed := False;
  try S := TType2NdefMapping.Decode(ttmNtag215, Cc, Memory); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'CC capacity exceeds physical user region');
  Memory := Store(ttmUltralight, Wire); Cc := CcFor(ttmUltralight);
  Memory[10] := $FD; Memory[11] := 1; Memory[12] := $A5; Memory[13] := $FE;
  S := TType2NdefMapping.Decode(ttmUltralight, Cc, Memory); Check(S.HasTrailingTlv, 'Trailing proprietary TLV retained');
  Failed := False;
  try Plan := TType2NdefMapping.Prepare(ttmUltralight, Cc, Memory, Wire); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'No shifting trailing TLVs');
  Memory := Store(ttmUltralight, nil); Memory[0] := $FE;
  S := TType2NdefMapping.Decode(ttmUltralight, Cc, Memory); Check(not S.HasNdef, 'Absent versus empty TLV');
  Failed := False;
  try Plan := TType2NdefMapping.Prepare(ttmUltralight, Cc, Memory, Wire); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'No implicit formatting');
  Memory := Store(ttmUltralight, nil); Memory[2] := $FD; Memory[3] := 1;
  Memory[4] := $A5; Memory[5] := $FE; Failed := False;
  try Plan := TType2NdefMapping.Prepare(ttmUltralight, Cc, Memory, Wire); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'Empty NDEF does not overwrite trailing TLVs');
  Memory[2] := $D1; Failed := False;
  try Plan := TType2NdefMapping.Prepare(ttmUltralight, Cc, Memory, Wire); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'Interrupted empty-header payload requires explicit recovery');
  Memory := Store(ttmUltralight, nil); Memory[1] := 49; Failed := False;
  try S := TType2NdefMapping.Decode(ttmUltralight, Cc, Memory); except on EType2NdefError do Failed := True; end;
  Check(Failed, 'Truncated storage TLV');
  Writeln('PASS: CC bounds, factory lock TLV, mapping and write phases');
end;

constructor TMemoryScript.Create(const AModel: TType2TagModel; const AInitial: TBytes; const AOffset: Integer);
begin
  inherited Create; Model := AModel; Memory := CopyBytes(AInitial); Offset := AOffset;
  Cc := CcFor(Model); StaticLocks := HexToBytes('11000000'); DynamicLocks := HexToBytes('000000BD'); Configuration := HexToBytes('040000FF');
end;

procedure TMemoryScript.BeginTransaction;
begin
  Inc(Begins); if BeginFails then raise ECardTransportError.Create('acquire');
  Check(not Active, 'One nonnested transaction'); Active := True;
end;

procedure TMemoryScript.EndTransaction;
begin Inc(Ends); Check(Active, 'Own transaction release'); Active := False;
  if EndFails then raise ECardTransportError.Create('release'); end;

function TMemoryScript.Exchange(const ACommand: TBytes): TBytes;
var P, I, L: Integer; Data: TBytes;
begin
  Check(Active, 'Every command inside exclusive transaction');
  I := Length(Commands); SetLength(Commands, I + 1); Commands[I] := CopyBytes(ACommand);
  Check((Length(ACommand) >= 5) and (ACommand[0] = $FF) and (ACommand[2] = 0), 'Explicit PC/SC page profile');
  P := ACommand[3];
  if ACommand[1] = $B0 then
  begin
    Inc(Reads); Check((Length(ACommand) = 5) and (ACommand[4] = 4), 'Exactly four-byte page read');
    if Reads = FailRead then raise ECardTransportError.Create('read failure');
    if P = 2 then Data := CopyBytes(StaticLocks)
    else if P = 3 then
    begin Data := CopyBytes(Cc); if CorruptCc and (Writes > 0) then Data[3] := $0F; end
    else if ((Model in [ttmUltralightEv1_48,ttmNtag210]) and (P = 16)) or
      (not (Model in [ttmUltralightEv1_48,ttmNtag210]) and (Model <> ttmUltralight) and
       (P = TType2Layout.LastUserPage(Model) + 2)) then Data := CopyBytes(Configuration)
    else if P = TType2Layout.LastUserPage(Model) + 1 then Data := CopyBytes(DynamicLocks)
    else
    begin
      Check((P >= 4) and (P <= TType2Layout.LastUserPage(Model)), 'Bounded user-page reads');
      Data := Copy(Memory, (P - 4) * 4, 4);
    end;
    if Reads = BadRead then SetLength(Data, 3);
  end
  else
  begin
    Check((ACommand[1] = $D6) and (Length(ACommand) = 9) and (ACommand[4] = 4), 'Single page write command');
    Check((P >= 4) and (P <= TType2Layout.LastUserPage(Model)), 'Never write CC/manufacturer/lock/config pages');
    Inc(Writes);
    if RejectWrite and (Writes = FailWrite) then begin Result := HexToBytes('6982'); Exit; end;
    if not SuppressWrite then Move(ACommand[5], Memory[(P - 4) * 4], 4);
    I := Length(Images); SetLength(Images, I + 1); Images[I] := CopyBytes(Memory);
    L := Memory[Offset + 1];
    if L = $FF then L := (Integer(Memory[Offset + 2]) shl 8) or Memory[Offset + 3];
    Check((L = 0) or (L = FinalLength), 'Only empty or final length published, including header transitions');
    if Writes = FailWrite then raise ECardTransportError.Create('ambiguous write');
    Data := nil;
  end;
  Result := CopyBytes(Data); SetLength(Result, Length(Data) + 2);
  Result[Length(Data)] := $90; Result[Length(Data) + 1] := 0;
end;

procedure Attach(const M: TType2TagModel; const Memory: TBytes;
  out Script: TMemoryScript; out Reader: TType2NdefCardReader; const Offset: Integer = 0);
begin
  Script := TMemoryScript.Create(M, Memory, Offset); Reader := TType2NdefCardReader.Create(nil);
  Reader.Transport := Script; Reader.Profile := TPcscStorageProfile.Create;
end;

procedure ReaderAndWriter;
var M: TType2TagModel; Script: TMemoryScript; Reader: TType2NdefCardReader;
  S: TType2NdefSnapshot; Plan: TType2NdefWritePlan; Original, Wire: TBytes;
  Records: TNdefMessage; I, O, TotalWrites: Integer;
begin
  Records := One(TNdefRecords.Uri('https://example.org')); Wire := TNdefCodec.Encode(Records);
  for M := Low(TType2TagModel) to High(TType2TagModel) do
  begin
    Original := Store(M, HexToBytes('D101045503616263'));
    Attach(M, Original, Script, Reader);
    try
      Script.FinalLength := Length(Wire); Reader.WriteMessage(M, Records);
      Plan := TType2NdefMapping.Prepare(M, Script.Cc, Original, Wire);
      Check(BytesEqual(Script.Memory, Plan.Committed), 'All model guarded writers');
      Check((Script.Begins = 1) and (Script.Ends = 1) and (Script.Writes > 0), 'Single transaction includes publication and verification');
      if M = ttmUltralight then I := 0 else I := 1;
      Check(BytesToHex(Script.Commands[I]) = 'FFB0000304', 'CC read before memory');
      TotalWrites := Script.Writes; Reader.WriteMessage(M, Records); Check(Script.Writes = TotalWrites, 'Same message is a no-op');
      S := Reader.ReadMessage(M); Check(BytesEqual(S.MessageBytes, Wire), 'Read complete message');
      Script.FinalLength := 0; Reader.ClearMessage(M); S := Reader.ReadMessage(M);
      Check(S.HasNdef and (Length(S.Records) = 0), 'Clear preserves empty NDEF TLV');
    finally Reader.Free; end;
  end;
  // Factory NTAG213 offset five supports short messages, and explicitly rejects split extended length.
  Original := Store(ttmNtag213, nil, 5); Wire := HexToBytes('0103A00C34'); Move(Wire[0], Original[0], 5);
  Attach(ttmNtag213, Original, Script, Reader, 5);
  try
    Script.FinalLength := Length(TNdefCodec.Encode(Records)); Reader.WriteMessage(ttmNtag213, Records);
    Check(BytesEqual(Copy(Script.Memory, 0, 5), Wire), 'Factory prefix preserved through physical writes');
  finally Reader.Free; end;
  // Both header widths and every supported alignment, with each transitional image checked by the fake.
  for O := 0 to 3 do if O <> 1 then
  begin
    Original := Store(ttmNtag216, TNdefCodec.Encode(Unknown(4)), O);
    Attach(ttmNtag216, Original, Script, Reader, O);
    try
      Script.FinalLength := Length(TNdefCodec.Encode(Unknown(300))); Reader.WriteMessage(ttmNtag216, Unknown(300));
      Script.FinalLength := Length(TNdefCodec.Encode(Unknown(400))); Reader.WriteMessage(ttmNtag216, Unknown(400));
      Script.FinalLength := Length(TNdefCodec.Encode(Unknown(3))); Reader.WriteMessage(ttmNtag216, Unknown(3));
      for I := 872 to High(Script.Memory) do Check(Script.Memory[I] = Original[I], 'NTAG216 bytes outside CC unchanged');
    finally Reader.Free; end;
  end;
  Writeln('PASS: all model readers/writers, no-op, clear and short/extended transitions');
end;

procedure Failures;
var Script: TMemoryScript; Reader: TType2NdefCardReader; S: TType2NdefSnapshot;
  Initial, Wire: TBytes; Records: TNdefMessage; I, N, InitialReads: Integer; Failed: Boolean;
begin
  Initial := Store(ttmUltralight, HexToBytes('D101045503616263'));
  Records := One(TNdefRecords.Text('Updated', 'en')); Wire := TNdefCodec.Encode(Records);
  Attach(ttmUltralight, Initial, Script, Reader);
  try
    Script.FinalLength := Length(Wire); Reader.WriteMessage(ttmUltralight, Records);
    N := Script.Writes;
  finally Reader.Free; end;
  for I := 1 to N do
  begin
    Attach(ttmUltralight, Initial, Script, Reader);
    try
      Script.FinalLength := Length(Wire); Script.FailWrite := I; Script.EndFails := True; Failed := False;
      try Reader.WriteMessage(ttmUltralight, Records); except on E: EContactlessWriteUncertain do
      begin Failed := True; Check(E.OriginalErrorClass = 'ECardTransportError', 'Primary ambiguous failure wins release'); end; end;
      Check(Failed and (Script.Writes = I) and (Script.Ends = 1), 'Every partial write stops without retry');
    finally Reader.Free; end;
  end;
  for I := 0 to 4 do
  begin
    Attach(ttmUltralight, Initial, Script, Reader);
    try
      Script.FinalLength := Length(Wire);
      case I of
        0: begin Script.RejectWrite := True; Script.FailWrite := 1; end;
        1: Script.SuppressWrite := True;
        2: Script.EndFails := True;
        3: Script.CorruptCc := True;
        4: Script.BadRead := 15; // CC + 12 pages + static locks, then first read-back.
      end;
      Failed := False;
      try Reader.WriteMessage(ttmUltralight, Records); except on EContactlessWriteUncertain do Failed := True; end;
      Check(Failed and (Script.Writes > 0) and (Script.Ends = 1), 'Status/read-back/full-snapshot/CC/release failures are uncertain');
    finally Reader.Free; end;
  end;
  for I := 0 to 1 do
  begin
    if I = 0 then Attach(ttmNtag210, Store(ttmNtag210,nil), Script, Reader)
    else Attach(ttmNtag212, Store(ttmNtag212,nil), Script, Reader);
    try
      Script.Configuration[2] := 4; Script.FinalLength := Length(Wire); Failed := False;
      try if I = 0 then Reader.WriteMessage(ttmNtag210,Records) else Reader.WriteMessage(ttmNtag212,Records);
      except on E: EContactlessError do Failed := True; end;
      Check(Failed and (Script.Writes = 0) and (Script.Ends = 1),'NTAG210/212 MIRROR_PAGE refuses NDEF writes before dispatch');
    finally Reader.Free; end;
  end;
  for I := 0 to 7 do
  begin
    Attach(ttmNtag213, Store(ttmNtag213, nil), Script, Reader);
    try
      Script.FinalLength := Length(Wire);
      case I of
        0: Script.Cc[3] := $0F;
        1: Script.StaticLocks[2] := $10;
        2: Script.StaticLocks[3] := $80;
        3: Script.DynamicLocks[0] := 1;
        4: Script.DynamicLocks[2] := 1;
        5: Script.Cc[1] := $20;
        6: Script.Configuration[3] := 4;
        7: Script.Configuration[0] := $44;
      end;
      Failed := False;
      try Reader.WriteMessage(ttmNtag213, Records); except on EType2NdefError do Failed := True; end;
      Check(Failed and (Script.Writes = 0) and (Script.Ends = 1), 'CC/version/static/dynamic locks, AUTH0 and mirrors block writes');
    finally Reader.Free; end;
  end;
  // CC lock and block-lock bits alone still permit user-memory writes.
  Attach(ttmUltralight, Initial, Script, Reader);
  try
    Script.StaticLocks[2] := $0F; Script.FinalLength := Length(Wire); Reader.WriteMessage(ttmUltralight, Records);
    Check(Script.Writes > 0, 'CC/block-lock bits are not user-page locks');
  finally Reader.Free; end;
  InitialReads := 1 + 12;
  for I := 1 to InitialReads do
  begin
    Attach(ttmUltralight, Initial, Script, Reader);
    try
      Script.FailRead := I; Script.EndFails := True; Failed := False;
      try Reader.WriteMessage(ttmUltralight, Records); except on ECardTransportError do Failed := True; end;
      Check(Failed and (Script.Writes = 0) and (Script.Reads = I) and (Script.Ends = 1), 'Read preflight failure no writes and primary preserved');
    finally Reader.Free; end;
  end;
  Attach(ttmUltralight, Initial, Script, Reader);
  try
    Script.BeginFails := True; Failed := False;
    try S := Reader.ReadMessage(ttmUltralight); except on ECardTransportError do Failed := True; end;
    Check(Failed and (Script.Ends = 0) and (Script.Reads = 0), 'Failed acquire does not release unowned transaction');
  finally Reader.Free; end;
  Attach(ttmUltralight, Initial, Script, Reader);
  try
    Script.EndFails := True; Failed := False;
    try S := Reader.ReadMessage(ttmUltralight); except on ECardTransportError do Failed := True; end;
    Check(Failed and (Script.Writes = 0), 'Read result requires successful release');
  finally Reader.Free; end;
  Writeln('PASS: lock preflight, every partial write, no replay and release precedence');
end;

begin
  try
    Framing; Records; Mapping; ReaderAndWriter; Failures;
    Writeln('PASS: ', Checks, ' assertions in five groups.');
  except on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end; end;
end.
