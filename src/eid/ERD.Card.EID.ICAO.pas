unit ERD.Card.EID.ICAO;

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
  ERD.Card.EID.MRZ;

const
  /// <summary>Maximum decoded LDS data-group size, in bytes: one MiB.</summary>
  IcaoMaxDataGroupBytes = 1048576;
  /// <summary>Maximum accumulated face images in one decoded DG2.</summary>
  IcaoMaxFaceImages = 16;

type
  /// <summary>Malformed or oversized ICAO LDS/biometric data; messages contain no personal data.</summary>
  EIcaoDataError = class(EConvertError);
  /// <summary>Image encodings defined by ISO/IEC 19794-5 first-edition facial records.</summary>
  TIcaoFaceFormat = (
    /// <summary>JPEG image data; the application supplies its image decoder.</summary>
    iffJpeg,
    /// <summary>JPEG 2000 image data; no JPEG 2000 decoder is bundled.</summary>
    iffJpeg2000);

  /// <summary>One encoded face image, without VCL or pixel-decoding dependencies.</summary>
  TIcaoFaceImage = record
    /// <summary>The encoding declared by the facial record.</summary>
    Format: TIcaoFaceFormat;
    /// <summary>Declared image width in pixels.</summary>
    Width: Word;
    /// <summary>Declared image height in pixels.</summary>
    Height: Word;
    /// <summary>Independent encoded image bytes; framing is checked, not image pixels.</summary>
    Data: TBytes;
  end;

  /// <summary>Independent images in biometric-template and record order.</summary>
  TIcaoFaceImages = array of TIcaoFaceImage;

  /// <summary>One CBEFF biometric block with explicit format metadata.</summary>
  TIcaoBiometricBlock = record
    /// <summary>Two-byte format owner from BHT tag 87.</summary>
    FormatOwner: Word;
    /// <summary>Two-byte format type from BHT tag 88.</summary>
    FormatType: Word;
    /// <summary>Canonical TLV encoding of the 5F2E/7F2E block; exact original bytes remain in RawData.</summary>
    EncodedData: TBytes;
    /// <summary>True only for 5F2E owner 0101/type 0008 and supported FAC 010 records.</summary>
    ImagesDecoded: Boolean;
  end;

  /// <summary>Biometric templates, including preserved unsupported formats.</summary>
  TIcaoBiometricBlocks = array of TIcaoBiometricBlock;

  /// <summary>DG2 contents; unsupported biometric formats remain available as encoded blocks.</summary>
  /// <remarks>Inputs and image buffers are copied. Ordinary record assignment shares
  /// arrays. No signature, hash, chip authenticity or biometric matching is verified.</remarks>
  TIcaoBiometrics = record
    /// <summary>Exact complete DG2 input, retained for later SOD/hash verification.</summary>
    RawData: TBytes;
    /// <summary>All CBEFF templates with declared format metadata.</summary>
    Blocks: TIcaoBiometricBlocks;
    /// <summary>Extracted JPEG/JPEG 2000 images from supported first-edition FAC records.</summary>
    Images: TIcaoFaceImages;
  end;

  /// <summary>Transport-independent decoders for shared ICAO LDS identity/face data.</summary>
  /// <remarks>Requires already acquired DG files. Does not implement BAC, PACE,
  /// secure messaging or national online-eID services. Country compatibility depends
  /// on the document's application, edition, access controls and biometric format.</remarks>
  TIcaoDataCodec = class
  public
    /// <summary>Decodes DG1 tag 61 containing the MRZ data object 5F1F.</summary>
    /// <param name="ABytes">Complete DG1, at most IcaoMaxDataGroupBytes bytes.</param>
    /// <returns>Checksum-validated TD1, TD2 or TD3 identity values.</returns>
    /// <exception cref="EIcaoDataError">DG1 structure or size is invalid.</exception>
    /// <exception cref="EMrzError">MRZ layout, syntax or checksums are invalid.</exception>
    /// <remarks>Malformed BER syntax raises the core ETlvFormatError.</remarks>
    class function DecodeDG1(const ABytes: TBytes): TMrzIdentity; static;
    /// <summary>Decodes DG2/CBEFF templates and extracts supported FAC 010 face images.</summary>
    /// <param name="ABytes">Complete DG2, at most IcaoMaxDataGroupBytes bytes.</param>
    /// <returns>Independent raw data, all biometric blocks and supported encoded images.</returns>
    /// <exception cref="EIcaoDataError">Templates, counts, format metadata or supported face records are malformed.</exception>
    /// <remarks>BER errors raise ETlvFormatError. New ISO/IEC 39794 7F2E formats are
    /// preserved, not mistaken for ISO/IEC 19794 JPEG records. No image codec is invoked.</remarks>
    class function DecodeDG2(const ABytes: TBytes): TIcaoBiometrics; static;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.TLV;

procedure Fail;
begin
  raise EIcaoDataError.Create
    ('Invalid or unsupported ICAO data-group structure.');
end;

function TagIs(const ANode: TTlvNode; const ATag: string): Boolean;
begin
  Result := BytesEqual(ANode.Tag, HexToBytes(ATag));
end;

function SingleChild(const AParent: TTlvNode; const ATag: string): TTlvNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AParent.ChildCount - 1 do
    if TagIs(AParent.Children[I], ATag) then
    begin
      if Result <> nil then
        Fail;
      Result := AParent.Children[I];
    end;
  if Result = nil then
    Fail;
end;

function DecodeGroup(const ABytes: TBytes; const ATag: string): TTlvDocument;
var
  Options: TTlvDecodeOptions;
  Error: TTlvError;
begin
  if (Length(ABytes) = 0) or (Length(ABytes) > IcaoMaxDataGroupBytes) then
    Fail;
  Options := DefaultTlvOptions;
  Options.MaxDepth := 16;
  Options.MaxNodes := 1024;
  Options.MaxInputBytes := IcaoMaxDataGroupBytes;
  Result := nil;
  if not TTlvCodec.TryDecode(ABytes, Options, Result, Error) then
    raise ETlvFormatError.Create(Error);
  try
    if (Result.Count <> 1) or not TagIs(Result.Roots[0], ATag) then
      Fail;
  except
    Result.Free;
    raise;
  end;
end;

function ReadWord(const ABytes: TBytes; const AOffset: Integer): Word;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 2) then
    Fail;
  Result := Word((Integer(ABytes[AOffset]) shl 8) or ABytes[AOffset + 1]);
end;

function ReadSize(const ABytes: TBytes; const AOffset: Integer): Integer;
var
  Value: Cardinal;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 4) then
    Fail;
  Value := (Cardinal(ABytes[AOffset]) shl 24) or
    (Cardinal(ABytes[AOffset + 1]) shl 16) or
    (Cardinal(ABytes[AOffset + 2]) shl 8) or ABytes[AOffset + 3];
  if Value > Cardinal(Length(ABytes)) then
    Fail;
  Result := Integer(Value);
end;

procedure DecodeFaces(const ABytes: TBytes; var AImages: TIcaoFaceImages);
var
  Count, Offset, Size, Points, Info, I, Index: Integer;
begin
  if (Length(ABytes) < 14) or not BytesEqual(Copy(ABytes, 0, 8),
    HexToBytes('4641430030313000')) then
    Fail;
  if ReadSize(ABytes, 8) <> Length(ABytes) then
    Fail;
  Count := ReadWord(ABytes, 12);
  if (Count = 0) or (Count > IcaoMaxFaceImages - Length(AImages)) then
    Fail;
  Offset := 14;
  for I := 1 to Count do
  begin
    Size := ReadSize(ABytes, Offset);
    if (Size < 33) or (Size > Length(ABytes) - Offset) then
      Fail;
    Points := ReadWord(ABytes, Offset + 4);
    if Points > (Size - 33) div 8 then
      Fail;
    Info := Offset + 20 + Points * 8;
    Index := Length(AImages);
    SetLength(AImages, Index + 1);
    case ABytes[Info + 1] of
      0:
        AImages[Index].Format := iffJpeg;
      1:
        AImages[Index].Format := iffJpeg2000;
    else
      Fail;
    end;
    AImages[Index].Width := ReadWord(ABytes, Info + 2);
    AImages[Index].Height := ReadWord(ABytes, Info + 4);
    if (AImages[Index].Width = 0) or (AImages[Index].Height = 0) then
      Fail;
    AImages[Index].Data := Copy(ABytes, Info + 12, Offset + Size - Info - 12);
    Inc(Offset, Size);
  end;
  if Offset <> Length(ABytes) then
    Fail;
end;

class function TIcaoDataCodec.DecodeDG1(const ABytes: TBytes): TMrzIdentity;
var
  Document: TTlvDocument;
  Value: TBytes;
  Text: UnicodeString;
  I: Integer;
begin
  Result := Default (TMrzIdentity);
  Document := DecodeGroup(ABytes, '61');
  try
    if Document.Roots[0].ChildCount <> 1 then
      Fail;
    Value := SingleChild(Document.Roots[0], '5F1F').Value;
    Text := '';
    SetLength(Text, Length(Value));
    for I := 0 to Length(Value) - 1 do
      Text[I + 1] := WideChar(Value[I]);
    Result := TMrzCodec.Decode(Text);
  finally
    Document.Free;
  end;
end;

class function TIcaoDataCodec.DecodeDG2(const ABytes: TBytes): TIcaoBiometrics;
var
  Document: TTlvDocument;
  Group, Template, Header, Block: TTlvNode;
  Value: TBytes;
  I, Index, Count: Integer;
begin
  Result := Default (TIcaoBiometrics);
  Document := DecodeGroup(ABytes, '75');
  try
    Group := SingleChild(Document.Roots[0], '7F61');
    Value := SingleChild(Group, '02').Value;
    if (Length(Value) <> 1) or (Value[0] = 0) or (Value[0] > IcaoMaxFaceImages)
    then
      Fail;
    Count := Value[0];
    for I := 0 to Group.ChildCount - 1 do
      if TagIs(Group.Children[I], '7F60') then
      begin
        Template := Group.Children[I];
        Header := SingleChild(Template, 'A1');
        Index := Length(Result.Blocks);
        if Index >= Count then
          Fail;
        SetLength(Result.Blocks, Index + 1);
        Value := SingleChild(Header, '87').Value;
        if Length(Value) <> 2 then
          Fail;
        Result.Blocks[Index].FormatOwner := ReadWord(Value, 0);
        Value := SingleChild(Header, '88').Value;
        if Length(Value) <> 2 then
          Fail;
        Result.Blocks[Index].FormatType := ReadWord(Value, 0);
        if Template.ChildCount <> 2 then
          Fail;
        Block := Template.Children[1];
        if not TagIs(Block, '5F2E') and not TagIs(Block, '7F2E') then
          Fail;
        Result.Blocks[Index].EncodedData := TTlvCodec.EncodeNode(Block);
        if TagIs(Block, '5F2E') and (Result.Blocks[Index].FormatOwner = $0101)
          and (Result.Blocks[Index].FormatType = $0008) then
        begin
          DecodeFaces(Block.Value, Result.Images);
          Result.Blocks[Index].ImagesDecoded := True;
        end;
      end;
    if Length(Result.Blocks) <> Count then
      Fail;
    Result.RawData := CopyBytes(ABytes);
  finally
    Document.Free;
  end;
end;

end.
