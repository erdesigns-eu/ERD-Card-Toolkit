unit ERD.Card.TLV;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

const
  /// <summary>The default maximum TLV nesting depth; root nodes have depth one.</summary>
  TlvDefaultMaxDepth = 32;
  /// <summary>The hard nesting limit for decoding and explicit tree construction.</summary>
  TlvHardMaxDepth = 256;
  /// <summary>The default maximum total number of nodes in a document.</summary>
  TlvDefaultMaxNodes = 10000;
  /// <summary>The hard node limit for decoding, cloning and document construction.</summary>
  TlvHardMaxNodes = 1000000;
  /// <summary>The default maximum input size in bytes: one MiB.</summary>
  TlvDefaultMaxInputBytes = 1048576;
  /// <summary>The maximum encoded identifier size in bytes.</summary>
  TlvMaxTagBytes = 32;

type
  /// <summary>Describes TLV syntax, resource-limit or construction failures.</summary>
  TTlvErrorCode = (
    /// <summary>No failure occurred.</summary>
    tecNone,
    /// <summary>An identifier or its continuation byte is missing.</summary>
    tecTagTruncated,
    /// <summary>An identifier is reserved, malformed or contains trailing bytes.</summary>
    tecInvalidTag,
    /// <summary>The identifier exceeds the configured byte limit.</summary>
    tecTagLimit,
    /// <summary>A length field is incomplete.</summary>
    tecLengthTruncated,
    /// <summary>Indefinite lengths are not supported.</summary>
    tecIndefiniteLength,
    /// <summary>A length requires over four bytes or exceeds MaxInt.</summary>
    tecInvalidLength,
    /// <summary>The declared value exceeds its containing byte span.</summary>
    tecValueTruncated,
    /// <summary>The configured nesting limit is exceeded.</summary>
    tecDepthLimit,
    /// <summary>The configured total node limit is exceeded.</summary>
    tecNodeLimit,
    /// <summary>The input exceeds the configured byte limit.</summary>
    tecInputLimit,
    /// <summary>The supplied resource limits are outside their supported ranges.</summary>
    tecInvalidOptions,
    /// <summary>A nil node/document or a conflicting constructed flag was supplied.</summary>
    tecInvalidNode
  );
  /// <summary>TLV failure details that do not retain card data.</summary>
  TTlvError = record
    /// <summary>The failure category; tecNone on success.</summary>
    Code: TTlvErrorCode;
    /// <summary>
    /// The zero-based offending byte or containing-span end for missing bytes.
    /// Minus one denotes success or a construction/options failure without an input position.
    /// </summary>
    Offset: Integer;
  end;
  /// <summary>Explicit limits for decoding untrusted definite-length card TLV streams.</summary>
  TTlvDecodeOptions = record
    /// <summary>Maximum nesting depth, from one through TlvHardMaxDepth.</summary>
    MaxDepth: Integer;
    /// <summary>Maximum total nodes, from one through TlvHardMaxNodes.</summary>
    MaxNodes: Integer;
    /// <summary>Maximum input bytes, from zero through MaxInt; zero permits only empty input.</summary>
    MaxInputBytes: Integer;
    /// <summary>Maximum identifier bytes, from one through TlvMaxTagBytes.</summary>
    MaxTagBytes: Integer;
    /// <summary>Whether to ignore 00 and FF padding between nodes at every constructed level.</summary>
    AllowPadding: Boolean;
  end;
  /// <summary>An exception containing TLV error details without input contents.</summary>
  ETlvFormatError = class(EConvertError)
  private
    FError: TTlvError;
  public
    /// <summary>Creates an error from a failure category and byte position.</summary>
    /// <param name="AError">The failure details.</param>
    constructor Create(const AError: TTlvError); reintroduce;
    /// <summary>The failure category and offset.</summary>
    property Error: TTlvError read FError;
  end;
  /// <summary>An immutable node owning its child nodes.</summary>
  TTlvNode = class;
  /// <summary>An array of node references; its owner determines node lifetimes.</summary>
  TTlvNodes = array of TTlvNode;
  /// <summary>An immutable ISO 7816 BER-TLV node with an encoded identifier.</summary>
  /// <remarks>
  /// A document or parent owns borrowed nodes returned by index properties.
  /// Never free a borrowed node. Explicit constructors and Clone create caller-owned
  /// nodes; constructed nodes clone supplied children rather than taking ownership.
  /// Values and tags are returned as independent buffers. No schema or EMV tag
  /// dictionary is assumed. Construction is bounded by the hard depth/node limits.
  /// </remarks>
  TTlvNode = class
  private
    FTag: TBytes;
    FValue: TBytes;
    FChildren: TTlvNodes;
    FValueSize: Integer;
    FEncodedSize: Integer;
    constructor Create; reintroduce;
    function GetTag: TBytes;
    function GetValue: TBytes;
    function GetConstructed: Boolean;
    function GetChildCount: Integer;
    function GetChild(const AIndex: Integer): TTlvNode;
  public
    /// <summary>Creates a caller-owned primitive node with independent tag/value buffers.</summary>
    /// <param name="ATag">One complete identifier whose constructed bit is clear.</param>
    /// <param name="AValue">Uninterpreted bytes, including an empty value.</param>
    /// <exception cref="ETlvFormatError">The tag is invalid or declares a constructed node.</exception>
    /// <exception cref="ERangeError">The encoded node cannot fit in an Integer-sized buffer.</exception>
    constructor CreatePrimitive(const ATag: TBytes; const AValue: TBytes);
    /// <summary>Creates a caller-owned constructed node with deep copies of its children.</summary>
    /// <param name="ATag">One complete identifier whose constructed bit is set.</param>
    /// <param name="AChildren">Child nodes to clone; nil entries are rejected.</param>
    /// <exception cref="ETlvFormatError">Tag, nodes or hard construction limits are invalid.</exception>
    /// <exception cref="ERangeError">The encoded node exceeds the supported buffer size.</exception>
    constructor CreateConstructed(const ATag: TBytes; const AChildren: array of TTlvNode);
    /// <summary>Frees this owned node and every owned descendant.</summary>
    destructor Destroy; override;
    /// <summary>Creates a deep copy with independent buffers and descendants.</summary>
    /// <returns>A caller-owned node that remains valid after the original owner is freed.</returns>
    function Clone: TTlvNode;
    /// <summary>An independent copy of the encoded identifier, not a numeric ASN.1 tag number.</summary>
    property Tag: TBytes read GetTag;
    /// <summary>
    /// An independent primitive value or the canonical encoding of constructed children.
    /// Original nonminimal lengths and optional inter-node padding are not retained.
    /// </summary>
    property Value: TBytes read GetValue;
    /// <summary>Whether the identifier declares constructed content.</summary>
    property IsConstructed: Boolean read GetConstructed;
    /// <summary>The canonical value size in bytes.</summary>
    property ValueSize: Integer read FValueSize;
    /// <summary>The number of owned children; zero for primitive nodes.</summary>
    property ChildCount: Integer read GetChildCount;
    /// <summary>A borrowed child valid until this node's owner is destroyed.</summary>
    /// <param name="AIndex">A zero-based child index.</param>
    /// <exception cref="ERangeError">The child index is out of range.</exception>
    property Children[const AIndex: Integer]: TTlvNode read GetChild;
  end;
  /// <summary>An immutable document owning its ordered root nodes.</summary>
  TTlvDocument = class
  private
    FNodes: TTlvNodes;
    function GetCount: Integer;
    function GetRoot(const AIndex: Integer): TTlvNode;
  public
    /// <summary>Creates an empty caller-owned document.</summary>
    constructor Create; overload;
    /// <summary>Creates a caller-owned document by deep-copying supplied root nodes.</summary>
    /// <param name="ANodes">Ordered roots to clone; nil entries are rejected.</param>
    /// <exception cref="ETlvFormatError">Nodes or hard construction limits are invalid.</exception>
    constructor Create(const ANodes: array of TTlvNode); overload;
    /// <summary>Frees all owned root nodes and their descendants.</summary>
    destructor Destroy; override;
    /// <summary>Deep-copies this document, including every node and buffer.</summary>
    /// <returns>An independent caller-owned document.</returns>
    function Clone: TTlvDocument;
    /// <summary>The number of ordered root nodes.</summary>
    property Count: Integer read GetCount;
    /// <summary>A borrowed root valid until this document is freed.</summary>
    /// <param name="AIndex">A zero-based root index.</param>
    /// <exception cref="ERangeError">The root index is out of range.</exception>
    property Roots[const AIndex: Integer]: TTlvNode read GetRoot;
  end;
  /// <summary>Decodes bounded definite-length ISO 7816 BER-TLV and encodes canonical lengths.</summary>
  /// <remarks>
  /// EMV encoded tag identifiers such as 9F02 are supported; this is not a full
  /// ASN.1 schema validator. Indefinite lengths are rejected. Nonminimal definite
  /// lengths are accepted and normalized on encoding. Preserve original input
  /// separately for signatures or other operations requiring exact wire bytes.
  /// Independent documents may be used on different threads; do not free their
  /// owners concurrently with readers. No VCL or hardware is required.
  /// </remarks>
  TTlvCodec = class
  public
    /// <summary>Decodes a complete stream using the default resource limits.</summary>
    /// <param name="ABytes">Binary TLV bytes; empty input is valid.</param>
    /// <param name="ADocument">A new caller-owned document, or nil on failure.</param>
    /// <param name="AError">Failure details, or tecNone and minus one on success.</param>
    /// <returns>True if the complete input is valid within the default limits.</returns>
    /// <remarks>Free any earlier document before reusing the output variable. Allocation exceptions may propagate.</remarks>
    class function TryDecode(const ABytes: TBytes; out ADocument: TTlvDocument;
      out AError: TTlvError): Boolean; overload; static;
    /// <summary>Decodes a complete stream with explicit padding and resource limits.</summary>
    /// <param name="ABytes">Binary TLV bytes; not retained by the document.</param>
    /// <param name="AOptions">Limits and optional 00/FF inter-node padding support.</param>
    /// <param name="ADocument">A new caller-owned document, or nil on failure.</param>
    /// <param name="AError">Failure details, or tecNone and minus one on success.</param>
    /// <returns>True if all non-padding bytes form valid bounded nodes.</returns>
    /// <remarks>Free any earlier output document first. No partial document is returned on failure.</remarks>
    class function TryDecode(const ABytes: TBytes; const AOptions: TTlvDecodeOptions;
      out ADocument: TTlvDocument; out AError: TTlvError): Boolean; overload; static;
    /// <summary>Decodes a stream with the default limits or raises a structured error.</summary>
    /// <param name="ABytes">The complete binary stream.</param>
    /// <returns>A caller-owned document.</returns>
    /// <exception cref="ETlvFormatError">Syntax or resource limits are invalid.</exception>
    class function Decode(const ABytes: TBytes): TTlvDocument; static;
    /// <summary>Encodes all document roots with minimal definite lengths and no padding.</summary>
    /// <param name="ADocument">A non-nil document; an empty document produces empty bytes.</param>
    /// <returns>A newly allocated canonical TLV stream.</returns>
    /// <exception cref="ETlvFormatError">The document is nil.</exception>
    /// <exception cref="ERangeError">The output exceeds the supported buffer size.</exception>
    class function Encode(const ADocument: TTlvDocument): TBytes; static;
    /// <summary>Encodes one node and its descendants with canonical definite lengths.</summary>
    /// <param name="ANode">A non-nil borrowed or owned node; ownership is unchanged.</param>
    /// <returns>Newly allocated tag, length and value bytes.</returns>
    /// <exception cref="ETlvFormatError">The node is nil.</exception>
    class function EncodeNode(const ANode: TTlvNode): TBytes; static;
  end;

/// <summary>Returns default bounded decoding options without padding support.</summary>
/// <returns>Limits of depth 32, 10000 nodes, one MiB and 32 identifier bytes.</returns>
function DefaultTlvOptions: TTlvDecodeOptions;

implementation

procedure TlvError(out AError: TTlvError; const ACode: TTlvErrorCode;
  const AOffset: Integer);
begin
  AError.Code := ACode;
  AError.Offset := AOffset;
end;

procedure RaiseTlvError(const ACode: TTlvErrorCode; const AOffset: Integer = -1);
var
  Error: TTlvError;
begin
  TlvError(Error, ACode, AOffset);
  raise ETlvFormatError.Create(Error);
end;

function DefaultTlvOptions: TTlvDecodeOptions;
begin
  Result.MaxDepth := TlvDefaultMaxDepth;
  Result.MaxNodes := TlvDefaultMaxNodes;
  Result.MaxInputBytes := TlvDefaultMaxInputBytes;
  Result.MaxTagBytes := TlvMaxTagBytes;
  Result.AllowPadding := False;
end;

constructor ETlvFormatError.Create(const AError: TTlvError);
begin
  inherited CreateFmt('Invalid TLV: error %d at byte offset %d.',
    [Ord(AError.Code), AError.Offset]);
  FError := AError;
end;

procedure FreeNodes(var ANodes: TTlvNodes);
var
  I: Integer;
begin
  for I := 0 to Length(ANodes) - 1 do
    ANodes[I].Free;
  ANodes := nil;
end;

function ReadTag(const ABytes: TBytes; var APosition: Integer;
  const AEnd: Integer; const AMaxTagBytes: Integer; out ATag: TBytes;
  out AError: TTlvError): Boolean;
var
  Start: Integer;
  B: Byte;
begin
  ATag := nil;
  Start := APosition;
  if APosition >= AEnd then
  begin
    TlvError(AError, tecTagTruncated, AEnd);
    Exit(False);
  end;
  B := ABytes[APosition];
  if (B = 0) or (B = $FF) then
  begin
    TlvError(AError, tecInvalidTag, APosition);
    Exit(False);
  end;
  Inc(APosition);
  if (B and $1F) = $1F then
  begin
    repeat
      if APosition >= AEnd then
      begin
        TlvError(AError, tecTagTruncated, AEnd);
        Exit(False);
      end;
      if APosition - Start >= AMaxTagBytes then
      begin
        TlvError(AError, tecTagLimit, APosition);
        Exit(False);
      end;
      B := ABytes[APosition];
      if (APosition = Start + 1) and ((B and $7F) = 0) then
      begin
        TlvError(AError, tecInvalidTag, APosition);
        Exit(False);
      end;
      Inc(APosition);
    until (B and $80) = 0;
  end;
  ATag := Copy(ABytes, Start, APosition - Start);
  Result := True;
end;

procedure ValidateTag(const ATag: TBytes; const AConstructed: Boolean);
var
  Position: Integer;
  Parsed: TBytes;
  Error: TTlvError;
begin
  if Length(ATag) > TlvMaxTagBytes then
    RaiseTlvError(tecTagLimit, TlvMaxTagBytes);
  Position := 0;
  if not ReadTag(ATag, Position, Length(ATag), TlvMaxTagBytes, Parsed, Error) then
    raise ETlvFormatError.Create(Error);
  if Position <> Length(ATag) then
    RaiseTlvError(tecInvalidTag, Position);
  if ((ATag[0] and $20) <> 0) <> AConstructed then
    RaiseTlvError(tecInvalidNode, 0);
end;

function LengthSize(const ASize: Integer): Integer;
var
  Remaining: Integer;
begin
  Result := 1;
  if ASize < 128 then Exit;
  Remaining := ASize;
  while Remaining > 0 do
  begin
    Inc(Result);
    Remaining := Remaining shr 8;
  end;
end;

function CheckedSize(const ALeft: Integer; const ARight: Integer): Integer;
begin
  if ARight > MaxInt - ALeft then
    raise ERangeError.Create('TLV output exceeds the supported buffer size.');
  Result := ALeft + ARight;
end;

procedure UpdateSizes(const ANode: TTlvNode);
var
  I: Integer;
begin
  if ANode.IsConstructed then
  begin
    ANode.FValueSize := 0;
    for I := 0 to Length(ANode.FChildren) - 1 do
      ANode.FValueSize := CheckedSize(ANode.FValueSize, ANode.FChildren[I].FEncodedSize);
  end
  else
    ANode.FValueSize := Length(ANode.FValue);
  ANode.FEncodedSize := CheckedSize(CheckedSize(Length(ANode.FTag),
    LengthSize(ANode.FValueSize)), ANode.FValueSize);
end;

function CloneNode(const ANode: TTlvNode; const ADepth: Integer;
  var ACount: Integer): TTlvNode;
var
  I: Integer;
begin
  if ANode = nil then RaiseTlvError(tecInvalidNode);
  if ADepth > TlvHardMaxDepth then RaiseTlvError(tecDepthLimit);
  if ACount >= TlvHardMaxNodes then RaiseTlvError(tecNodeLimit);
  Inc(ACount);
  Result := TTlvNode.Create;
  try
    Result.FTag := Copy(ANode.FTag, 0, Length(ANode.FTag));
    Result.FValue := Copy(ANode.FValue, 0, Length(ANode.FValue));
    Result.FValueSize := ANode.FValueSize;
    Result.FEncodedSize := ANode.FEncodedSize;
    SetLength(Result.FChildren, Length(ANode.FChildren));
    for I := 0 to Length(ANode.FChildren) - 1 do
      Result.FChildren[I] := CloneNode(ANode.FChildren[I], ADepth + 1, ACount);
  except
    Result.Free;
    raise;
  end;
end;

procedure WriteNode(const ANode: TTlvNode; var ABytes: TBytes; var APosition: Integer);
var
  I: Integer;
  Count: Integer;
begin
  for I := 0 to Length(ANode.FTag) - 1 do
  begin
    ABytes[APosition] := ANode.FTag[I];
    Inc(APosition);
  end;
  if ANode.FValueSize < 128 then
  begin
    ABytes[APosition] := Byte(ANode.FValueSize);
    Inc(APosition);
  end
  else
  begin
    Count := LengthSize(ANode.FValueSize) - 1;
    ABytes[APosition] := Byte($80 or Count);
    Inc(APosition);
    for I := Count - 1 downto 0 do
    begin
      ABytes[APosition] := Byte((ANode.FValueSize shr (I * 8)) and $FF);
      Inc(APosition);
    end;
  end;
  if ANode.IsConstructed then
  begin
    for I := 0 to Length(ANode.FChildren) - 1 do
      WriteNode(ANode.FChildren[I], ABytes, APosition);
  end
  else
    for I := 0 to Length(ANode.FValue) - 1 do
    begin
      ABytes[APosition] := ANode.FValue[I];
      Inc(APosition);
    end;
end;

function EncodeNodes(const ANodes: TTlvNodes): TBytes;
var
  I: Integer;
  Size: Integer;
  Position: Integer;
begin
  Result := nil;
  Size := 0;
  for I := 0 to Length(ANodes) - 1 do
    Size := CheckedSize(Size, ANodes[I].FEncodedSize);
  SetLength(Result, Size);
  Position := 0;
  for I := 0 to Length(ANodes) - 1 do
    WriteNode(ANodes[I], Result, Position);
end;

constructor TTlvNode.Create;
begin
  inherited Create;
end;

constructor TTlvNode.CreatePrimitive(const ATag: TBytes; const AValue: TBytes);
begin
  inherited Create;
  ValidateTag(ATag, False);
  if Length(AValue) > MaxInt then
    raise ERangeError.Create('TLV value exceeds the supported buffer size.');
  FTag := Copy(ATag, 0, Length(ATag));
  FValue := Copy(AValue, 0, Length(AValue));
  UpdateSizes(Self);
end;

constructor TTlvNode.CreateConstructed(const ATag: TBytes;
  const AChildren: array of TTlvNode);
var
  I: Integer;
  Count: Integer;
begin
  inherited Create;
  ValidateTag(ATag, True);
  if Length(AChildren) >= TlvHardMaxNodes then RaiseTlvError(tecNodeLimit);
  FTag := Copy(ATag, 0, Length(ATag));
  SetLength(FChildren, Length(AChildren));
  Count := 1;
  for I := 0 to Length(AChildren) - 1 do
    FChildren[I] := CloneNode(AChildren[I], 2, Count);
  UpdateSizes(Self);
end;

destructor TTlvNode.Destroy;
begin
  FreeNodes(FChildren);
  inherited Destroy;
end;

function TTlvNode.Clone: TTlvNode;
var
  Count: Integer;
begin
  Count := 0;
  Result := CloneNode(Self, 1, Count);
end;

function TTlvNode.GetTag: TBytes;
begin
  Result := Copy(FTag, 0, Length(FTag));
end;

function TTlvNode.GetValue: TBytes;
begin
  if IsConstructed then
    Result := EncodeNodes(FChildren)
  else
    Result := Copy(FValue, 0, Length(FValue));
end;

function TTlvNode.GetConstructed: Boolean;
begin
  Result := (FTag[0] and $20) <> 0;
end;

function TTlvNode.GetChildCount: Integer;
begin
  Result := Length(FChildren);
end;

function TTlvNode.GetChild(const AIndex: Integer): TTlvNode;
begin
  if (AIndex < 0) or (AIndex >= Length(FChildren)) then
    raise ERangeError.Create('TLV child index is out of range.');
  Result := FChildren[AIndex];
end;

constructor TTlvDocument.Create;
begin
  inherited Create;
end;

constructor TTlvDocument.Create(const ANodes: array of TTlvNode);
var
  I: Integer;
  Count: Integer;
begin
  inherited Create;
  if Length(ANodes) > TlvHardMaxNodes then RaiseTlvError(tecNodeLimit);
  Count := 0;
  SetLength(FNodes, Length(ANodes));
  for I := 0 to Length(ANodes) - 1 do
    FNodes[I] := CloneNode(ANodes[I], 1, Count);
end;

destructor TTlvDocument.Destroy;
begin
  FreeNodes(FNodes);
  inherited Destroy;
end;

function TTlvDocument.Clone: TTlvDocument;
begin
  Result := TTlvDocument.Create(FNodes);
end;

function TTlvDocument.GetCount: Integer;
begin
  Result := Length(FNodes);
end;

function TTlvDocument.GetRoot(const AIndex: Integer): TTlvNode;
begin
  if (AIndex < 0) or (AIndex >= Length(FNodes)) then
    raise ERangeError.Create('TLV root index is out of range.');
  Result := FNodes[AIndex];
end;

function ReadLength(const ABytes: TBytes; var APosition: Integer;
  const AEnd: Integer; out ASize: Integer; out AError: TTlvError): Boolean;
var
  B: Byte;
  Count: Integer;
  I: Integer;
begin
  ASize := 0;
  if APosition >= AEnd then
  begin
    TlvError(AError, tecLengthTruncated, AEnd);
    Exit(False);
  end;
  B := ABytes[APosition];
  Inc(APosition);
  if B < $80 then
  begin
    ASize := B;
    Exit(True);
  end;
  Count := B and $7F;
  if Count = 0 then
  begin
    TlvError(AError, tecIndefiniteLength, APosition - 1);
    Exit(False);
  end;
  if Count > 4 then
  begin
    TlvError(AError, tecInvalidLength, APosition - 1);
    Exit(False);
  end;
  if Count > AEnd - APosition then
  begin
    TlvError(AError, tecLengthTruncated, AEnd);
    Exit(False);
  end;
  for I := 1 to Count do
  begin
    B := ABytes[APosition];
    if ASize > (MaxInt - B) div 256 then
    begin
      TlvError(AError, tecInvalidLength, APosition);
      Exit(False);
    end;
    ASize := ASize * 256 + B;
    Inc(APosition);
  end;
  Result := True;
end;

function ParseNodes(const ABytes: TBytes; var APosition: Integer;
  const AEnd: Integer; const ADepth: Integer; const AOptions: TTlvDecodeOptions;
  var ANodeCount: Integer; out ANodes: TTlvNodes; out AError: TTlvError): Boolean;
var
  Node: TTlvNode;
  Tag: TBytes;
  ValueSize: Integer;
  ValueEnd: Integer;
  Count: Integer;
  Capacity: Integer;
begin
  ANodes := nil;
  Node := nil;
  Count := 0;
  Result := False;
  try
    while APosition < AEnd do
    begin
      if AOptions.AllowPadding and
        ((ABytes[APosition] = 0) or (ABytes[APosition] = $FF)) then
      begin
        Inc(APosition);
        Continue;
      end;
      if ADepth > AOptions.MaxDepth then
      begin
        TlvError(AError, tecDepthLimit, APosition);
        Exit(False);
      end;
      if ANodeCount >= AOptions.MaxNodes then
      begin
        TlvError(AError, tecNodeLimit, APosition);
        Exit(False);
      end;
      if not ReadTag(ABytes, APosition, AEnd, AOptions.MaxTagBytes, Tag, AError) then
        Exit(False);
      if not ReadLength(ABytes, APosition, AEnd, ValueSize, AError) then
        Exit(False);
      if ValueSize > AEnd - APosition then
      begin
        TlvError(AError, tecValueTruncated, AEnd);
        Exit(False);
      end;
      ValueEnd := APosition + ValueSize;
      Node := TTlvNode.Create;
      Node.FTag := Tag;
      Inc(ANodeCount);
      if Node.IsConstructed then
      begin
        if not ParseNodes(ABytes, APosition, ValueEnd, ADepth + 1,
          AOptions, ANodeCount, Node.FChildren, AError) then
          Exit(False);
      end
      else
      begin
        Node.FValue := Copy(ABytes, APosition, ValueSize);
        APosition := ValueEnd;
      end;
      UpdateSizes(Node);
      if Count = Length(ANodes) then
      begin
        Capacity := Count * 2;
        if Capacity < 4 then Capacity := 4;
        if Capacity > AOptions.MaxNodes then Capacity := AOptions.MaxNodes;
        SetLength(ANodes, Capacity);
      end;
      ANodes[Count] := Node;
      Node := nil;
      Inc(Count);
    end;
    SetLength(ANodes, Count);
    Result := True;
  finally
    Node.Free;
    if not Result then FreeNodes(ANodes);
  end;
end;

class function TTlvCodec.TryDecode(const ABytes: TBytes;
  out ADocument: TTlvDocument; out AError: TTlvError): Boolean;
begin
  Result := TryDecode(ABytes, DefaultTlvOptions, ADocument, AError);
end;

class function TTlvCodec.TryDecode(const ABytes: TBytes;
  const AOptions: TTlvDecodeOptions; out ADocument: TTlvDocument;
  out AError: TTlvError): Boolean;
var
  Document: TTlvDocument;
  Position: Integer;
  Count: Integer;
begin
  ADocument := nil;
  TlvError(AError, tecNone, -1);
  if (AOptions.MaxDepth < 1) or (AOptions.MaxDepth > TlvHardMaxDepth) or
    (AOptions.MaxNodes < 1) or (AOptions.MaxNodes > TlvHardMaxNodes) or
    (AOptions.MaxInputBytes < 0) or (AOptions.MaxTagBytes < 1) or
    (AOptions.MaxTagBytes > TlvMaxTagBytes) then
  begin
    TlvError(AError, tecInvalidOptions, -1);
    Exit(False);
  end;
  if Length(ABytes) > AOptions.MaxInputBytes then
  begin
    TlvError(AError, tecInputLimit, AOptions.MaxInputBytes);
    Exit(False);
  end;
  Document := TTlvDocument.Create;
  try
    Position := 0;
    Count := 0;
    if not ParseNodes(ABytes, Position, Length(ABytes), 1, AOptions,
      Count, Document.FNodes, AError) then Exit(False);
    ADocument := Document;
    Document := nil;
    Result := True;
  finally
    Document.Free;
  end;
end;

class function TTlvCodec.Decode(const ABytes: TBytes): TTlvDocument;
var
  Error: TTlvError;
begin
  if not TryDecode(ABytes, Result, Error) then
    raise ETlvFormatError.Create(Error);
end;

class function TTlvCodec.Encode(const ADocument: TTlvDocument): TBytes;
begin
  if ADocument = nil then RaiseTlvError(tecInvalidNode);
  Result := EncodeNodes(ADocument.FNodes);
end;

class function TTlvCodec.EncodeNode(const ANode: TTlvNode): TBytes;
var
  Position: Integer;
begin
  Result := nil;
  if ANode = nil then RaiseTlvError(tecInvalidNode);
  SetLength(Result, ANode.FEncodedSize);
  Position := 0;
  WriteNode(ANode, Result, Position);
end;

end.
