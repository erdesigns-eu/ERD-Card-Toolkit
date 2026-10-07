unit ERD.Card.Bytes;

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

type
  /// <summary>Reports invalid hexadecimal text without including its contents.</summary>
  EHexFormatError = class(EConvertError)
  private
    FOffset: Integer;
  public
    /// <summary>Creates an error for a one-based input position.</summary>
    /// <param name="AOffset">The invalid character or unmatched final digit position.</param>
    constructor Create(const AOffset: Integer); reintroduce;
    /// <summary>The one-based position of the invalid input.</summary>
    property Offset: Integer read FOffset;
  end;

/// <summary>Converts hexadecimal text to a newly allocated byte array.</summary>
/// <param name="AHex">Hexadecimal digit pairs; an empty string is valid.</param>
/// <param name="ABytes">Decoded bytes on success; an empty array on failure.</param>
/// <param name="AErrorOffset">
/// The one-based invalid character or unmatched final digit position; zero on success.
/// </param>
/// <param name="AAllowWhitespace">Whether to ignore ASCII space, tab, CR and LF.</param>
/// <returns>True if every non-ignored character forms a complete hexadecimal pair.</returns>
/// <remarks>
/// Invalid text is reported without a conversion exception or partial output.
/// The input is not retained. Allocation failures are not converted into false.
/// </remarks>
function TryHexToBytes(const AHex: string; out ABytes: TBytes;
  out AErrorOffset: Integer; const AAllowWhitespace: Boolean = False): Boolean;

/// <summary>Converts hexadecimal text to a newly allocated byte array.</summary>
/// <param name="AHex">Hexadecimal digit pairs; an empty string is valid.</param>
/// <param name="AAllowWhitespace">Whether to ignore ASCII space, tab, CR and LF.</param>
/// <returns>The decoded bytes, with no retained reference to the input.</returns>
/// <exception cref="EHexFormatError">The text contains invalid or incomplete hexadecimal pairs.</exception>
function HexToBytes(const AHex: string;
  const AAllowWhitespace: Boolean = False): TBytes;

/// <summary>Formats bytes as hexadecimal digit pairs without separators.</summary>
/// <param name="ABytes">The bytes to format; an empty array produces an empty string.</param>
/// <param name="AUpperCase">Whether to use uppercase rather than lowercase digits.</param>
/// <returns>A new string containing exactly two characters per byte.</returns>
/// <exception cref="ERangeError">The output length cannot be represented by an Integer.</exception>
function BytesToHex(const ABytes: TBytes; const AUpperCase: Boolean = True): string;

/// <summary>Creates an independent copy of a byte array.</summary>
/// <param name="ABytes">The source bytes; the input is not modified.</param>
/// <returns>A copy that can be changed without changing the source array.</returns>
function CopyBytes(const ABytes: TBytes): TBytes;

/// <summary>Compares two arrays by length and byte contents.</summary>
/// <param name="ALeft">The first array.</param>
/// <param name="ARight">The second array.</param>
/// <returns>True if both arrays have identical contents, including two empty arrays.</returns>
/// <remarks>This is not a constant-time comparison for cryptographic secrets.</remarks>
function BytesEqual(const ALeft: TBytes; const ARight: TBytes): Boolean;

implementation

function HexNibble(const AChar: Char): Integer;
begin
  case AChar of
    '0'..'9': Result := Ord(AChar) - Ord('0');
    'A'..'F': Result := Ord(AChar) - Ord('A') + 10;
    'a'..'f': Result := Ord(AChar) - Ord('a') + 10;
  else
    Result := -1;
  end;
end;

function IsHexWhitespace(const AChar: Char): Boolean;
begin
  Result := (AChar = ' ') or (AChar = #9) or (AChar = #10) or (AChar = #13);
end;

constructor EHexFormatError.Create(const AOffset: Integer);
begin
  inherited CreateFmt('Invalid hexadecimal text at position %d.', [AOffset]);
  FOffset := AOffset;
end;

function TryHexToBytes(const AHex: string; out ABytes: TBytes;
  out AErrorOffset: Integer; const AAllowWhitespace: Boolean): Boolean;
var
  I: Integer;
  DigitCount: Integer;
  LastDigitOffset: Integer;
  Nibble: Integer;
  HighNibble: Integer;
  ByteIndex: Integer;
begin
  ABytes := nil;
  AErrorOffset := 0;
  DigitCount := 0;
  LastDigitOffset := 0;
  for I := 1 to Length(AHex) do
  begin
    if AAllowWhitespace and IsHexWhitespace(AHex[I]) then
      Continue;
    if HexNibble(AHex[I]) < 0 then
    begin
      AErrorOffset := I;
      Exit(False);
    end;
    Inc(DigitCount);
    LastDigitOffset := I;
  end;
  if Odd(DigitCount) then
  begin
    AErrorOffset := LastDigitOffset;
    Exit(False);
  end;

  SetLength(ABytes, DigitCount div 2);
  HighNibble := -1;
  ByteIndex := 0;
  for I := 1 to Length(AHex) do
  begin
    if AAllowWhitespace and IsHexWhitespace(AHex[I]) then
      Continue;
    Nibble := HexNibble(AHex[I]);
    if HighNibble < 0 then
      HighNibble := Nibble
    else
    begin
      ABytes[ByteIndex] := Byte((HighNibble shl 4) or Nibble);
      Inc(ByteIndex);
      HighNibble := -1;
    end;
  end;
  Result := True;
end;

function HexToBytes(const AHex: string; const AAllowWhitespace: Boolean): TBytes;
var
  ErrorOffset: Integer;
begin
  if not TryHexToBytes(AHex, Result, ErrorOffset, AAllowWhitespace) then
    raise EHexFormatError.Create(ErrorOffset);
end;

function BytesToHex(const ABytes: TBytes; const AUpperCase: Boolean): string;
const
  UpperDigits = '0123456789ABCDEF';
  LowerDigits = '0123456789abcdef';
var
  I: Integer;
  Digits: string;
begin
  if Length(ABytes) > MaxInt div 2 then
    raise ERangeError.Create('Hexadecimal output exceeds the supported string length.');
  if AUpperCase then
    Digits := UpperDigits
  else
    Digits := LowerDigits;
  SetLength(Result, Length(ABytes) * 2);
  for I := 0 to Length(ABytes) - 1 do
  begin
    Result[I * 2 + 1] := Digits[(ABytes[I] shr 4) + 1];
    Result[I * 2 + 2] := Digits[(ABytes[I] and $0F) + 1];
  end;
end;

function CopyBytes(const ABytes: TBytes): TBytes;
begin
  Result := Copy(ABytes, 0, Length(ABytes));
end;

function BytesEqual(const ALeft: TBytes; const ARight: TBytes): Boolean;
var
  I: Integer;
begin
  if Length(ALeft) <> Length(ARight) then
    Exit(False);
  for I := 0 to Length(ALeft) - 1 do
    if ALeft[I] <> ARight[I] then
      Exit(False);
  Result := True;
end;

end.
