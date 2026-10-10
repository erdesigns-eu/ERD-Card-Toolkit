unit ERD.Card.GlobalPlatform.CAP;

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
  /// <summary>Maximum uncompressed CAP load image; short LOAD numbering may impose a smaller bound.</summary>
  GpMaxCapBytes = 1048576;

type
  /// <summary>Malformed, unsupported or ambiguous CAP archive/component data.</summary>
  EGpCapError = class(EConvertError);

  /// <summary>Complete binary CAP components, each including tag and two-byte body length.</summary>
  TGpCapComponents = array of TBytes;

  /// <summary>Independent JavaCard applet AIDs; ordinary array assignment shares nested buffers.</summary>
  TGpAppletAids = array of TBytes;

  /// <summary>Structurally checked JavaCard CAP 2.1/2.2/2.3 load image and installation identities.</summary>
  /// <remarks>No ZIP library is required for FromComponents. FromFile uses Delphi System.Zip,
  /// never an external DLL. Descriptor/debug data are not loaded. Own returned buffers.</remarks>
  TGpCapFile = class
  private
    FPackageAid, FImage: TBytes;
    FApplets: TGpAppletAids;
    function GetPackageAid: TBytes;
    function GetImage: TBytes;
    function GetLoadData: TBytes;
    function GetApplets: TGpAppletAids;
  public
    /// <summary>Validates components and builds canonical GP C4 load-file data.</summary>
    /// <param name="AComponents">Unique tags 1..12, exact component lengths, mandatory executable components.</param>
    /// <returns>Caller-owned validated CAP object; does not retain borrowed buffers.</returns>
    /// <exception cref="EGpCapError">Missing/duplicate/malformed components or unsupported header version.</exception>
    class function FromComponents(const AComponents: TGpCapComponents): TGpCapFile; static;

{$IFNDEF FPC}
    /// <summary>Reads one unambiguous JavaCard package from a bounded ZIP CAP archive.</summary>
    /// <param name="AFileName">Existing ZIP file; unrelated entries are ignored, duplicate CAP entries refused.</param>
    /// <returns>Caller-owned validated object; ZIP sizes checked before decompression.</returns>
    /// <exception cref="EGpCapError">Archive is malformed, encrypted, oversized or contains multiple packages.</exception>
    class function FromFile(const AFileName: string): TGpCapFile; static;
{$ENDIF}

    /// <summary>Independent package AID extracted from Header.cap, five through sixteen bytes.</summary>
    property PackageAid: TBytes read GetPackageAid;

    /// <summary>Independent applet AIDs extracted from Applet.cap; empty for library-only packages.</summary>
    property Applets: TGpAppletAids read GetApplets;

    /// <summary>Independent canonical component bytes preceded by C4 and BER length.</summary>
    property LoadImage: TBytes read GetImage;

    /// <summary>Independent raw canonical components without C4 framing, used for GP hashes and DAP signatures.</summary>
    property LoadFileData: TBytes read GetLoadData;
  end;

implementation

{$IFNDEF FPC}
uses
  System.Zip, System.Classes;
{$ENDIF}

procedure Invalid;
begin
  raise EGpCapError.Create('Invalid or unsupported JavaCard CAP package.');
end;

function BerLength(const N: Integer): TBytes;
begin
  Result := nil;
  if N < 128 then
  begin
    SetLength(Result, 1); Result[0] := N;
  end
  else if N <= 255 then
  begin
    SetLength(Result, 2); Result[0] := $81; Result[1] := N;
  end
  else if N <= 65535 then
  begin
    SetLength(Result, 3); Result[0] := $82;
    Result[1] := N shr 8; Result[2] := N and $FF;
  end
  else
  begin
    SetLength(Result, 4); Result[0] := $83;
    Result[1] := N shr 16; Result[2] := (N shr 8) and $FF;
    Result[3] := N and $FF;
  end;
end;

class function TGpCapFile.FromComponents(const AComponents: TGpCapComponents): TGpCapFile;
const
  Order: array[0..9] of Byte = (1, 2, 4, 3, 6, 7, 8, 10, 5, 9);
var
  Parts: array[1..12] of TBytes;
  I, J, Tag, Size, Total, Posn, N, Offset, Count: Integer;
  Header, Applet, L: TBytes;
begin
  if (Length(AComponents) < 8) or (Length(AComponents) > 12) then Invalid;
  Total := 0;
  for I := 1 to 12 do Parts[I] := nil;
  for I := 0 to High(AComponents) do
  begin
    if Length(AComponents[I]) < 3 then Invalid;
    Tag := AComponents[I][0];
    if (Tag < 1) or (Tag > 12) then Invalid;
    if Length(Parts[Tag]) <> 0 then Invalid;
    Size := Integer(AComponents[I][1]) * 256 + AComponents[I][2];
    if Length(AComponents[I]) <> Size + 3 then Invalid;
    if Total > GpMaxCapBytes - Length(AComponents[I]) then Invalid;
    Inc(Total, Length(AComponents[I]));
    Parts[Tag] := AComponents[I];
  end;
  for I := 1 to 9 do
    if (I <> 3) and (Length(Parts[I]) = 0) then Invalid;
  Header := Parts[1];
  if Length(Header) < 18 then Invalid;
  if (Header[3] <> $DE) or (Header[4] <> $CA) or (Header[5] <> $FF) or
    (Header[6] <> $ED) or (Header[8] <> 2) or not (Header[7] in [1, 2, 3]) then Invalid;
  if Header[9] and $F8 <> 0 then Invalid;
  N := Header[12];
  if (N < 5) or (N > 16) or (Length(Header) < 13 + N) then Invalid;
  // CAP 2.2+ can carry package_name after AID; enforce exact optional framing.
  if Header[7] = 1 then
  begin
    if Length(Header) <> 13 + N then Invalid;
  end
  else if Length(Header) <> 13 + N then
  begin
    if Length(Header) < 14 + N then Invalid;
    if Length(Header) <> 14 + N + Header[13 + N] then Invalid;
  end;
  // Directory declares body sizes for every standard component.
  Count := 12;
  if Header[7] = 1 then Count := 11;
  if Length(Parts[2]) < 3 + Count * 2 + 9 then Invalid;
  for I := 1 to Count do
  begin
    Offset := 3 + (I - 1) * 2;
    Size := Integer(Parts[2][Offset]) * 256 + Parts[2][Offset + 1];
    if Length(Parts[I]) = 0 then
    begin
      if Size <> 0 then Invalid;
    end
    else if Size <> Length(Parts[I]) - 3 then Invalid;
  end;
  if (Count = 11) and (Length(Parts[12]) <> 0) then Invalid;
  Offset := 3 + Count * 2 + 6;
  if (Length(Parts[4]) < 4) or (Parts[2][Offset] <> Parts[4][3]) then Invalid;
  if Length(Parts[3]) > 0 then
  begin
    if (Length(Parts[3]) < 4) or (Parts[2][Offset + 1] <> Parts[3][3]) then Invalid;
  end
  else if Parts[2][Offset + 1] <> 0 then Invalid;
  if ((Header[9] and $04) <> 0) <> (Parts[2][Offset + 1] > 0) then Invalid;
  if Parts[2][Offset + 2] <> 0 then Invalid;
  if Length(Parts[2]) <> Offset + 3 then Invalid;
  Result := TGpCapFile.Create;
  try
    Result.FPackageAid := Copy(Header, 13, N);
    Applet := Parts[3];
    if Length(Applet) > 0 then
    begin
      if Length(Applet) < 4 then Invalid;
      Count := Applet[3]; Posn := 4;
      SetLength(Result.FApplets, Count);
      for I := 0 to Count - 1 do
      begin
        if Posn >= Length(Applet) then Invalid;
        N := Applet[Posn]; Inc(Posn);
        if (N < 5) or (N > 16) or (Posn + N + 2 > Length(Applet)) then Invalid;
        Result.FApplets[I] := Copy(Applet, Posn, N);
        for J := 0 to I - 1 do
          if BytesToHex(Result.FApplets[J]) = BytesToHex(Result.FApplets[I]) then Invalid;
        Inc(Posn, N + 2);
      end;
      if Posn <> Length(Applet) then Invalid;
    end;
    Total := 0;
    for I := 0 to High(Order) do Inc(Total, Length(Parts[Order[I]]));
    L := BerLength(Total);
    SetLength(Result.FImage, 1 + Length(L) + Total);
    Result.FImage[0] := $C4;
    Move(L[0], Result.FImage[1], Length(L));
    Posn := 1 + Length(L);
    for I := 0 to High(Order) do
    begin
      N := Length(Parts[Order[I]]);
      if N > 0 then Move(Parts[Order[I]][0], Result.FImage[Posn], N);
      Inc(Posn, N);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{$IFNDEF FPC}
class function TGpCapFile.FromFile(const AFileName: string): TGpCapFile;
const
  Names: array[1..12] of string = ('Header.cap', 'Directory.cap', 'Applet.cap',
    'Import.cap', 'ConstantPool.cap', 'Class.cap', 'Method.cap', 'StaticField.cap',
    'RefLocation.cap', 'Export.cap', 'Descriptor.cap', 'Debug.cap');
var
  Zip: TZipFile;
  Source: TFileStream;
  Entry: TStream;
  LocalHeader: TZipHeader;
  Extra: Byte;
  Parts: TGpCapComponents;
  I, N, Total, Slash: Integer;
  Name, Prefix, FoundPrefix: string;
  Bytes: TBytes;
begin
  Source := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if Source.Size > GpMaxCapBytes * 4 then Invalid;
    Zip := TZipFile.Create;
    try
      Zip.Open(Source, zmRead);
      if Zip.FileCount > 4096 then Invalid;
      Total := 0; FoundPrefix := '';
      for I := 0 to Zip.FileCount - 1 do
      begin
        Name := StringReplace(Zip.FileNames[I], '\', '/', [rfReplaceAll]);
        if not SameText(Copy(Name, Length(Name) - 3, 4), '.cap') then Continue;
        Slash := LastDelimiter('/', Name);
        Prefix := Copy(Name, 1, Slash);
        if Length(Parts) = 0 then FoundPrefix := Prefix
        else if Prefix <> FoundPrefix then Invalid;
        if (Zip.FileInfo[I].UncompressedSize > GpMaxCapBytes) or
          (Zip.FileInfo[I].Flag and 1 <> 0) then Invalid;
        if Total > GpMaxCapBytes - Integer(Zip.FileInfo[I].UncompressedSize) then Invalid;
        Inc(Total, Integer(Zip.FileInfo[I].UncompressedSize));
        Entry := nil;
      Zip.Read(I, Entry, LocalHeader, True);
      try
        SetLength(Bytes, Integer(Zip.FileInfo[I].UncompressedSize));
        if Length(Bytes) > 0 then Entry.ReadBuffer(Bytes[0], Length(Bytes));
        if Entry.Read(Extra, 1) <> 0 then Invalid;
      finally
        Entry.Free;
      end;
        if (Length(Bytes) < 3) or not (Bytes[0] in [1..12]) then Invalid;
        if not SameText(Copy(Name, Slash + 1, MaxInt), Names[Bytes[0]]) then Invalid;
        if Length(Bytes) <> Integer(Zip.FileInfo[I].UncompressedSize) then Invalid;
        N := Length(Parts); SetLength(Parts, N + 1); Parts[N] := Bytes;
      end;
      Result := FromComponents(Parts);
    finally
      Zip.Free;
    end;
  finally
    Source.Free;
  end;
end;
{$ENDIF}

function TGpCapFile.GetPackageAid: TBytes;
begin
  Result := CopyBytes(FPackageAid);
end;

function TGpCapFile.GetLoadData: TBytes;
var Offset: Integer;
begin
  Offset := 2;
  if FImage[1] >= $80 then Offset := 2 + (FImage[1] and $7F);
  Result := Copy(FImage, Offset, Length(FImage) - Offset);
end;

function TGpCapFile.GetImage: TBytes;
begin
  Result := CopyBytes(FImage);
end;

function TGpCapFile.GetApplets: TGpAppletAids;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FApplets));
  for I := 0 to High(FApplets) do Result[I] := CopyBytes(FApplets[I]);
end;

end.
