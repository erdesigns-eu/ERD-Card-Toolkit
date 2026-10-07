program ProtocolCoreTests;

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
  ERD.Card.Bytes,
  ERD.Card.ATR,
  ERD.Card.TLV;

var
  Checks: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure InvalidAtr(const AHex: string; const ACode: TAtrErrorCode;
  const AOffset: Integer);
var
  Info: TAtrInfo;
  Error: TAtrError;
  Raised: Boolean;
begin
  Info := TAtrCodec.Decode(HexToBytes('3B01AA'));
  Check(not TAtrCodec.TryDecode(HexToBytes(AHex), Info, Error), 'Invalid ATR rejected');
  Check((Error.Code = ACode) and (Error.Offset = AOffset), 'ATR failure details');
  Check((Length(Info.Raw) = 0) and (Length(Info.HistoricalBytes) = 0) and
    (Length(Info.InterfaceGroups) = 0) and (Info.Protocols = []) and
    (Info.TS = 0) and (Info.T0 = 0) and (not Info.HasTck) and (Info.Tck = 0),
    'ATR failure clears output');
  Raised := False;
  try
    Info := TAtrCodec.Decode(HexToBytes(AHex));
  except
    on E: EAtrFormatError do
    begin
      Raised := True;
      Check((E.Error.Code = ACode) and (E.Error.Offset = AOffset), 'ATR exception details');
    end;
  end;
  Check(Raised, 'ATR throwing wrapper');
end;

procedure TestAtr;
var
  Info: TAtrInfo;
  Wire: TBytes;
  Error: TAtrError;
  I: Integer;
begin
  Info := TAtrCodec.Decode(HexToBytes('3B00'));
  Check((Info.Protocols = [0]) and (not Info.HasTck), 'Implicit T=0');
  Check(Length(Info.InterfaceGroups) = 0, 'No interface bytes');
  Info := TAtrCodec.Decode(HexToBytes('3F00'));
  Check(Info.TS = $3F, 'Logical inverse convention');
  Info := TAtrCodec.Decode(HexToBytes('3B8000'));
  Check((Info.Protocols = [0]) and (not Info.HasTck), 'Explicit T=0');
  Info := TAtrCodec.Decode(HexToBytes('3B800181'));
  Check((Info.Protocols = [1]) and Info.HasTck and (Info.Tck = $81), 'T=1 checksum');
  Info := TAtrCodec.Decode(HexToBytes('3B80800101'));
  Check((Info.Protocols = [0, 1]) and (Length(Info.InterfaceGroups) = 2), 'Multiple protocols');
  Info := TAtrCodec.Decode(HexToBytes('3B800F8F'));
  Check((Info.Protocols = [0]) and Info.HasTck, 'T=15 global bytes require checksum');
  Info := TAtrCodec.Decode(HexToBytes('3BF011223301F1'));
  Check(Info.InterfaceGroups[0].HasTA and (Info.InterfaceGroups[0].TA = $11), 'TA presence');
  Check(Info.InterfaceGroups[0].HasTB and (Info.InterfaceGroups[0].TB = $22), 'TB presence');
  Check(Info.InterfaceGroups[0].HasTC and (Info.InterfaceGroups[0].TC = $33), 'TC presence');
  Check(Info.InterfaceGroups[0].HasTD and (Info.InterfaceGroups[0].TD = $01), 'TD presence');
  Wire := HexToBytes('3B03AABBCC');
  Check(TAtrCodec.TryDecode(Wire, Info, Error), 'Historical bytes');
  Check((Error.Code = aicNone) and (Error.Offset = -1), 'ATR success error state');
  Wire[2] := 0;
  Check((Info.Raw[2] = $AA) and (Info.HistoricalBytes[0] = $AA), 'Input copied');
  Info.Raw[2] := 0;
  Check(Info.HistoricalBytes[0] = $AA, 'Raw and historical buffers independent');
  SetLength(Wire, AtrMaxSize);
  Wire[0] := $3B;
  Wire[1] := $FF;
  for I := 2 to 17 do
    Wire[I] := 0;
  Wire[5] := $F0;
  Wire[9] := $F0;
  Wire[13] := $F0;
  for I := 18 to 32 do
    Wire[I] := Byte(I);
  Check(TAtrCodec.TryDecode(Wire, Info, Error), 'Maximum size ATR');
  Check((Length(Info.InterfaceGroups) = 4) and (Length(Info.HistoricalBytes) = 15), 'Maximum ATR layout');
  InvalidAtr('', aicHeaderTruncated, 0);
  InvalidAtr('3B', aicHeaderTruncated, 1);
  InvalidAtr('0000', aicInvalidConvention, 0);
  InvalidAtr('3BF000', aicInterfaceTruncated, 3);
  InvalidAtr('3B02AA', aicHistoricalTruncated, 3);
  InvalidAtr('3B8001', aicChecksumMissing, 3);
  InvalidAtr('3B800180', aicChecksumMismatch, 3);
  InvalidAtr('3B0000', aicTrailingData, 2);
  InvalidAtr('3B80018100', aicTrailingData, 4);
  SetLength(Wire, AtrMaxSize + 1);
  InvalidAtr(BytesToHex(Wire), aicTooLong, AtrMaxSize);
end;

procedure InvalidTlv(const AHex: string; const ACode: TTlvErrorCode;
  const AOffset: Integer);
var
  Document: TTlvDocument;
  Error: TTlvError;
  Raised: Boolean;
begin
  Document := nil;
  Check(not TTlvCodec.TryDecode(HexToBytes(AHex), Document, Error), 'Invalid TLV rejected');
  Check(Document = nil, 'No partial TLV document');
  Check((Error.Code = ACode) and (Error.Offset = AOffset), 'TLV failure details for ' + AHex);
  Raised := False;
  try
    Document := TTlvCodec.Decode(HexToBytes(AHex));
    Document.Free;
  except
    on E: ETlvFormatError do
    begin
      Raised := True;
      Check((E.Error.Code = ACode) and (E.Error.Offset = AOffset), 'TLV exception details');
    end;
  end;
  Check(Raised, 'TLV throwing wrapper');
end;

procedure TlvVector(const AHex: string; const ACanonicalHex: string;
  const ACount: Integer);
var
  Document: TTlvDocument;
  Error: TTlvError;
begin
  Check(TTlvCodec.TryDecode(HexToBytes(AHex), Document, Error), 'TLV vector ' + AHex);
  try
    Check((Error.Code = tecNone) and (Error.Offset = -1), 'TLV success error state');
    Check(Document.Count = ACount, 'TLV root count');
    Check(BytesToHex(TTlvCodec.Encode(Document)) = ACanonicalHex, 'TLV canonical bytes');
  finally
    Document.Free;
  end;
end;

procedure TestTlvSyntax;
begin
  TlvVector('', '', 0);
  TlvVector('5A00', '5A00', 1);
  TlvVector('9F0206000000000100', '9F0206000000000100', 1);
  TlvVector('9F810101AA', '9F810101AA', 1);
  TlvVector('5A01AA5F200142', '5A01AA5F200142', 2);
  TlvVector('E1075A01AA5F200142', 'E1075A01AA5F200142', 1);
  TlvVector('E100', 'E100', 1);
  TlvVector('5A8101AA', '5A01AA', 1);
  TlvVector('E1075A820001AA5A00', 'E1055A01AA5A00', 1);
  InvalidTlv('00', tecInvalidTag, 0);
  InvalidTlv('FF', tecInvalidTag, 0);
  InvalidTlv('9F', tecTagTruncated, 1);
  InvalidTlv('9F80', tecInvalidTag, 1);
  InvalidTlv('9F8100', tecLengthTruncated, 3);
  InvalidTlv('5A', tecLengthTruncated, 1);
  InvalidTlv('5A81', tecLengthTruncated, 2);
  InvalidTlv('5A82AA', tecLengthTruncated, 3);
  InvalidTlv('5A80', tecIndefiniteLength, 1);
  InvalidTlv('5A850000000000', tecInvalidLength, 1);
  InvalidTlv('5A8480000000', tecInvalidLength, 5);
  InvalidTlv('5A02AA', tecValueTruncated, 3);
  InvalidTlv('5A00E1035A02AA', tecValueTruncated, 7);
  InvalidTlv('E1015A5A00', tecLengthTruncated, 3);
  InvalidTlv('E1035A02AA5A00', tecValueTruncated, 5);
end;

procedure LimitedTlv(const AHex: string; const AOptions: TTlvDecodeOptions;
  const ACode: TTlvErrorCode; const AOffset: Integer);
var
  Document: TTlvDocument;
  Error: TTlvError;
begin
  Check(not TTlvCodec.TryDecode(HexToBytes(AHex), AOptions, Document, Error), 'TLV limit rejected');
  Check(Document = nil, 'Limits leave no partial document');
  Check((Error.Code = ACode) and (Error.Offset = AOffset), 'TLV limit details');
end;

procedure TestTlvLimits;
var
  Options: TTlvDecodeOptions;
  Document: TTlvDocument;
  Error: TTlvError;
  Wire: TBytes;
  Node: TTlvNode;
  Parent: TTlvNode;
  I: Integer;
begin
  Options := DefaultTlvOptions;
  Options.MaxDepth := 1;
  LimitedTlv('E1025A00', Options, tecDepthLimit, 2);
  Check(TTlvCodec.TryDecode(HexToBytes('E100'), Options, Document, Error), 'Empty constructed node at depth limit');
  Document.Free;
  Options := DefaultTlvOptions;
  Options.MaxNodes := 1;
  LimitedTlv('5A005A00', Options, tecNodeLimit, 2);
  LimitedTlv('E1025A00', Options, tecNodeLimit, 2);
  Options := DefaultTlvOptions;
  Options.MaxInputBytes := 0;
  LimitedTlv('5A00', Options, tecInputLimit, 0);
  Check(TTlvCodec.TryDecode(nil, Options, Document, Error), 'Zero limit permits empty input');
  Document.Free;
  Options := DefaultTlvOptions;
  Options.MaxTagBytes := 1;
  LimitedTlv('9F0200', Options, tecTagLimit, 1);
  Options := DefaultTlvOptions;
  Options.MaxDepth := 0;
  LimitedTlv('', Options, tecInvalidOptions, -1);
  Options := DefaultTlvOptions;
  Options.MaxNodes := TlvHardMaxNodes + 1;
  LimitedTlv('', Options, tecInvalidOptions, -1);
  Options := DefaultTlvOptions;
  Options.MaxInputBytes := -1;
  LimitedTlv('', Options, tecInvalidOptions, -1);
  Options := DefaultTlvOptions;
  Options.MaxTagBytes := TlvMaxTagBytes + 1;
  LimitedTlv('', Options, tecInvalidOptions, -1);
  Options := DefaultTlvOptions;
  Options.AllowPadding := True;
  Check(TTlvCodec.TryDecode(HexToBytes('00FFE105005A00FFFF00'), Options, Document, Error), 'Padding at each level');
  try
    Check(BytesToHex(TTlvCodec.Encode(Document)) = 'E1025A00', 'Padding removed');
  finally
    Document.Free;
  end;
  Node := TTlvNode.CreatePrimitive(HexToBytes('5A'), nil);
  try
    for I := 2 to 33 do
    begin
      Parent := TTlvNode.CreateConstructed(HexToBytes('E1'), [Node]);
      Node.Free;
      Node := Parent;
    end;
    Wire := TTlvCodec.EncodeNode(Node);
    Check(not TTlvCodec.TryDecode(Wire, Document, Error), 'Default depth bound');
    Check((Error.Code = tecDepthLimit) and (Document = nil), 'Deep partial tree freed');
    Options := DefaultTlvOptions;
    Options.MaxDepth := 33;
    Check(TTlvCodec.TryDecode(Wire, Options, Document, Error), 'Explicit depth bound');
    Document.Free;
  finally
    Node.Free;
  end;
end;

procedure TestTlvOwnership;
var
  Primitive: TTlvNode;
  Parent: TTlvNode;
  NodeCopy: TTlvNode;
  Document: TTlvDocument;
  DocumentCopy: TTlvDocument;
  Tag: TBytes;
  Value: TBytes;
  Raised: Boolean;
begin
  Tag := HexToBytes('5A');
  Value := HexToBytes('AABB');
  Primitive := TTlvNode.CreatePrimitive(Tag, Value);
  try
    Tag[0] := 0;
    Value[0] := 0;
    Check(BytesToHex(Primitive.Tag) = '5A', 'Builder copies tag');
    Check(BytesToHex(Primitive.Value) = 'AABB', 'Builder copies value');
    Tag := Primitive.Tag;
    Value := Primitive.Value;
    Tag[0] := 0;
    Value[0] := 0;
    Check(BytesToHex(TTlvCodec.EncodeNode(Primitive)) = '5A02AABB', 'Getters copy buffers');
    Parent := TTlvNode.CreateConstructed(HexToBytes('E1'), [Primitive]);
  finally
    Primitive.Free;
  end;
  try
    Check(Parent.IsConstructed and (Parent.ChildCount = 1) and (Parent.ValueSize = 4), 'Constructed shape');
    Check(BytesToHex(Parent.Value) = '5A02AABB', 'Constructed value stream');
    NodeCopy := Parent.Children[0].Clone;
    Document := TTlvDocument.Create([Parent]);
  finally
    Parent.Free;
  end;
  try
    Check(BytesToHex(TTlvCodec.EncodeNode(NodeCopy)) = '5A02AABB', 'Borrowed child can be cloned independently');
  finally
    NodeCopy.Free;
  end;
  try
    DocumentCopy := Document.Clone;
    Raised := False;
    try
      Primitive := Document.Roots[-1];
    except
      on E: ERangeError do Raised := True;
    end;
    Check(Raised, 'Negative root index');
    Raised := False;
    try
      Primitive := Document.Roots[0].Children[1];
    except
      on E: ERangeError do Raised := True;
    end;
    Check(Raised, 'Child upper bound');
  finally
    Document.Free;
  end;
  try
    Check(BytesToHex(TTlvCodec.Encode(DocumentCopy)) = 'E1045A02AABB', 'Document clone survives owner');
  finally
    DocumentCopy.Free;
  end;
end;

procedure TestTlvSizes;
const
  Sizes: array[0..8] of Integer = (0, 1, 127, 128, 255, 256, 65535, 65536, 100000);
var
  I: Integer;
  J: Integer;
  Value: TBytes;
  Wire: TBytes;
  Node: TTlvNode;
  Document: TTlvDocument;
begin
  for I := Low(Sizes) to High(Sizes) do
  begin
    SetLength(Value, Sizes[I]);
    for J := 0 to Length(Value) - 1 do Value[J] := Byte(J and $FF);
    Node := TTlvNode.CreatePrimitive(HexToBytes('9F02'), Value);
    try
      Wire := TTlvCodec.EncodeNode(Node);
      Check(Node.ValueSize = Sizes[I], 'Cached value size');
    finally
      Node.Free;
    end;
    Document := TTlvCodec.Decode(Wire);
    try
      Check(BytesEqual(Document.Roots[0].Value, Value), 'Length boundary data');
      Check(BytesEqual(TTlvCodec.Encode(Document), Wire), 'Length boundary round-trip');
      if Sizes[I] < 128 then Check(Wire[2] = Sizes[I], 'Short length')
      else if Sizes[I] < 256 then Check(Wire[2] = $81, 'One long length byte')
      else if Sizes[I] < 65536 then Check(Wire[2] = $82, 'Two long length bytes')
      else Check(Wire[2] = $83, 'Three long length bytes');
    finally
      Document.Free;
    end;
  end;
end;

procedure TestTlvInvalidBuilders;
var
  Node: TTlvNode;
  Document: TTlvDocument;
  Wire: TBytes;
  Raised: Boolean;
  I: Integer;
begin
  for I := 0 to 6 do
  begin
    Node := nil;
    Document := nil;
    Raised := False;
    try
      case I of
        0: Node := TTlvNode.CreatePrimitive(nil, nil);
        1: Node := TTlvNode.CreatePrimitive(HexToBytes('E1'), nil);
        2: Node := TTlvNode.CreateConstructed(HexToBytes('5A'), []);
        3: Node := TTlvNode.CreateConstructed(HexToBytes('E1'), [nil]);
        4: Document := TTlvDocument.Create([nil]);
        5: Wire := TTlvCodec.Encode(nil);
        6: Wire := TTlvCodec.EncodeNode(nil);
      end;
    except
      on E: ETlvFormatError do Raised := True;
    end;
    Node.Free;
    Document.Free;
    Check(Raised, 'Invalid TLV builder rejected');
  end;
end;

procedure TestBoundedInputs;
var
  Wire: TBytes;
  Prefix: TBytes;
  Canonical: TBytes;
  Document: TTlvDocument;
  SecondDocument: TTlvDocument;
  Error: TTlvError;
  Info: TAtrInfo;
  AtrError: TAtrError;
  Options: TTlvDecodeOptions;
  Node: TTlvNode;
  Parent: TTlvNode;
  I: Integer;
  J: Integer;
  Raised: Boolean;
begin
  // A complete constructed root: every nonempty proper prefix is truncated.
  Wire := HexToBytes('E1075A01AA5F200142');
  for I := 1 to Length(Wire) - 1 do
  begin
    Prefix := Copy(Wire, 0, I);
    Check(not TTlvCodec.TryDecode(Prefix, Document, Error), 'Truncated constructed prefix');
    Check(Document = nil, 'Truncated prefix clears document');
  end;
  // Enumerate all one-byte inputs, then length/tag bytes inside fixed spans.
  SetLength(Wire, 1);
  for I := 0 to 255 do
  begin
    Wire[0] := Byte(I);
    Check(not TTlvCodec.TryDecode(Wire, Document, Error), 'Single-byte TLV cannot be complete');
    Check(Document = nil, 'Single-byte TLV has no partial document');
    Check(not TAtrCodec.TryDecode(Wire, Info, AtrError), 'Single-byte ATR cannot be complete');
    for J := 0 to 2 do
    begin
      Prefix := HexToBytes('E1035A0100');
      Prefix[J + 2] := Byte(I);
      if TTlvCodec.TryDecode(Prefix, Document, Error) then
      begin
        try
          Canonical := TTlvCodec.Encode(Document);
          SecondDocument := TTlvCodec.Decode(Canonical);
          try
            Check(BytesEqual(TTlvCodec.Encode(SecondDocument), Canonical), 'Canonical encoding is stable');
          finally
            SecondDocument.Free;
          end;
        finally
          Document.Free;
        end;
      end
      else
        Check(Document = nil, 'Small-span failure has no partial tree');
    end;
  end;
  SetLength(Wire, TlvMaxTagBytes + 1);
  Wire[0] := $9F;
  for I := 1 to TlvMaxTagBytes - 2 do Wire[I] := $81;
  Wire[TlvMaxTagBytes - 1] := $01;
  Wire[TlvMaxTagBytes] := 0;
  Check(TTlvCodec.TryDecode(Wire, Document, Error), 'Maximum tag size');
  Document.Free;
  Wire[TlvMaxTagBytes - 1] := $81;
  Check(not TTlvCodec.TryDecode(Wire, Document, Error), 'Oversized tag rejected');
  Check((Error.Code = tecTagLimit) and (Error.Offset = TlvMaxTagBytes), 'Tag hard limit');
  SetLength(Wire, (TlvDefaultMaxNodes + 1) * 2);
  for I := 0 to TlvDefaultMaxNodes do
  begin
    Wire[I * 2] := $5A;
    Wire[I * 2 + 1] := 0;
  end;
  Check(not TTlvCodec.TryDecode(Wire, Document, Error), 'Default broad-tree limit');
  Check((Error.Code = tecNodeLimit) and (Document = nil), 'Broad partial tree released');
  Options := DefaultTlvOptions;
  Options.MaxNodes := TlvDefaultMaxNodes + 1;
  Check(TTlvCodec.TryDecode(Wire, Options, Document, Error), 'Explicit broad-tree limit');
  try
    Check(Document.Count = TlvDefaultMaxNodes + 1, 'Broad document preserves every root');
  finally
    Document.Free;
  end;
  Node := TTlvNode.CreatePrimitive(HexToBytes('5A'), nil);
  try
    for I := 2 to TlvHardMaxDepth do
    begin
      Parent := TTlvNode.CreateConstructed(HexToBytes('E1'), [Node]);
      Node.Free;
      Node := Parent;
    end;
    Raised := False;
    try
      Parent := TTlvNode.CreateConstructed(HexToBytes('E1'), [Node]);
      Parent.Free;
    except
      on E: ETlvFormatError do
      begin
        Raised := True;
        Check(E.Error.Code = tecDepthLimit, 'Builder hard depth error');
      end;
    end;
    Check(Raised, 'Builder hard depth bound');
    Options := DefaultTlvOptions;
    Options.MaxDepth := TlvHardMaxDepth;
    Check(TTlvCodec.TryDecode(TTlvCodec.EncodeNode(Node), Options, Document, Error), 'Decode hard maximum depth');
    Document.Free;
  finally
    Node.Free;
  end;
end;

begin
  try
    TestAtr;
    TestTlvSyntax;
    TestTlvLimits;
    TestTlvOwnership;
    TestTlvSizes;
    TestTlvInvalidBuilders;
    TestBoundedInputs;
    Writeln('PASS: ', Checks, ' assertions across 7 ATR/TLV test groups.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
