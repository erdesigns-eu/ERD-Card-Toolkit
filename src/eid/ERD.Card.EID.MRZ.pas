unit ERD.Card.EID.MRZ;

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
  /// <summary>An invalid ICAO MRZ layout, character or check digit; messages contain no identity data.</summary>
  EMrzError = class(EConvertError);
  /// <summary>Supported ICAO 9303 machine-readable document layouts.</summary>
  TMrzFormat = (
    /// <summary>Identity-card layout: three lines of thirty characters.</summary>
    mfTD1,
    /// <summary>Document layout: two lines of thirty-six characters.</summary>
    mfTD2,
    /// <summary>Passport layout: two lines of forty-four characters.</summary>
    mfTD3);

  /// <summary>Decoded and checksum-validated MRZ data; checksums do not prove authenticity.</summary>
  /// <remarks>Dates retain YYMMDD and unknown-position fillers. No century, country
  /// name, original accented spelling or complete date is inferred from MRZ text.</remarks>
  TMrzIdentity = record
    /// <summary>The detected TD1, TD2 or TD3 layout.</summary>
    Format: TMrzFormat;
    /// <summary>Exact MRZ characters after removal of CR/LF line separators.</summary>
    Raw: UnicodeString;
    /// <summary>The two-character document code, including fillers.</summary>
    DocumentCode: UnicodeString;
    /// <summary>The three-character issuing-state code, including fillers such as D&lt;&lt;.</summary>
    IssuingState: UnicodeString;
    /// <summary>Document number, including a validated TD1/TD2 extension where present; trailing fillers removed.</summary>
    DocumentNumber: UnicodeString;
    /// <summary>The three-character nationality code.</summary>
    Nationality: UnicodeString;
    /// <summary>Date of birth exactly as YYMMDD, permitting unknown-position fillers.</summary>
    BirthDate: UnicodeString;
    /// <summary>Expiry exactly as YYMMDD, permitting unknown-position fillers.</summary>
    ExpiryDate: UnicodeString;
    /// <summary>MRZ sex code M, F or the filler character.</summary>
    Sex: WideChar;
    /// <summary>Surname transliteration, with fillers converted to spaces.</summary>
    Surname: UnicodeString;
    /// <summary>Given-name transliterations, with fillers converted to spaces.</summary>
    GivenNames: UnicodeString;
    /// <summary>Exact first optional field, including extension data and fillers.</summary>
    OptionalData: UnicodeString;
    /// <summary>Exact second optional field for TD1; empty for TD2/TD3.</summary>
    OptionalData2: UnicodeString;
  end;

  /// <summary>Stateless ICAO TD1/TD2/TD3 parsing and 7/3/1 check-digit calculation.</summary>
  TMrzCodec = class
  public
    /// <summary>Calculates an ICAO check digit over uppercase MRZ characters.</summary>
    /// <param name="AText">Characters A..Z, 0..9 and the filler character; empty input is allowed.</param>
    /// <returns>One decimal character using repeating weights 7, 3, 1.</returns>
    /// <exception cref="EMrzError">Input contains characters outside the MRZ alphabet.</exception>
    class function CheckDigit(const AText: UnicodeString): WideChar; static;
    /// <summary>Parses a complete MRZ and validates document, date, optional and composite checksums.</summary>
    /// <param name="AText">90, 72 or 88 MRZ characters, optionally separated by CR/LF; spaces and lowercase are invalid.</param>
    /// <returns>Validated typed fields, preserving original date and country codes.</returns>
    /// <exception cref="EMrzError">Layout, alphabet, field syntax, extended number or a checksum is invalid.</exception>
    /// <remarks>TD1/TD2 long document numbers are supported. Visas and nonstandard
    /// national formats are not. Checksums detect transcription errors, not forgery.</remarks>
    class function Decode(const AText: UnicodeString): TMrzIdentity; static;
  end;

implementation

procedure Fail;
begin
  raise EMrzError.Create('Invalid ICAO machine-readable zone.');
end;

function CharacterValue(const AChar: WideChar): Integer;
begin
  if (AChar >= '0') and (AChar <= '9') then
    Result := Ord(AChar) - Ord('0')
  else if (AChar >= 'A') and (AChar <= 'Z') then
    Result := Ord(AChar) - Ord('A') + 10
  else if AChar = '<' then
    Result := 0
  else
  begin
    Fail;
    Result := 0;
  end;
end;

class function TMrzCodec.CheckDigit(const AText: UnicodeString): WideChar;
const
  Weights: array [0 .. 2] of Integer = (7, 3, 1);
var
  I, Sum: Integer;
begin
  Sum := 0;
  for I := 1 to Length(AText) do
    Sum := (Sum + CharacterValue(AText[I]) * Weights[(I - 1) mod 3]) mod 10;
  Result := WideChar(Ord('0') + Sum);
end;

procedure Verify(const AValue: UnicodeString; const ADigit: WideChar);
begin
  if TMrzCodec.CheckDigit(AValue) <> ADigit then
    Fail;
end;

function TrimFillers(const AValue: UnicodeString): UnicodeString;
begin
  Result := AValue;
  while (Length(Result) > 0) and (Result[Length(Result)] = '<') do
    SetLength(Result, Length(Result) - 1);
end;

function NameText(const AValue: UnicodeString): UnicodeString;
var
  I: Integer;
begin
  Result := TrimFillers(AValue);
  for I := 1 to Length(Result) do
    if Result[I] = '<' then
      Result[I] := ' ';
end;

procedure ValidateDate(const AValue: UnicodeString);
var
  I: Integer;
begin
  for I := 1 to Length(AValue) do
    if not(((AValue[I] >= '0') and (AValue[I] <= '9')) or (AValue[I] = '<'))
    then
      Fail;
end;

function DocumentNumber(const APrefix, AOptional: UnicodeString;
  const ADigit: WideChar; const AAllowExtension: Boolean): UnicodeString;
var
  Stop: Integer;
  Extension: UnicodeString;
begin
  if ADigit <> '<' then
  begin
    Verify(APrefix, ADigit);
    Exit(TrimFillers(APrefix));
  end;
  if not AAllowExtension then
    Fail;
  if Pos('<', APrefix) <> 0 then
    Fail;
  Stop := Pos('<', AOptional);
  if Stop < 3 then
    Fail;
  Extension := Copy(AOptional, 1, Stop - 2);
  Verify(APrefix + Extension, AOptional[Stop - 1]);
  Result := APrefix + Extension;
end;

procedure ValidateLetters(const AText: UnicodeString);
var
  I: Integer;
begin
  for I := 1 to Length(AText) do
    if not(((AText[I] >= 'A') and (AText[I] <= 'Z')) or (AText[I] = '<')) then
      Fail;
end;

class function TMrzCodec.Decode(const AText: UnicodeString): TMrzIdentity;
var
  Text, L1, L2, Names, Composite: UnicodeString;
  I, Count, Split: Integer;
begin
  Result := Default (TMrzIdentity);
  if Length(AText) > 96 then
    Fail;
  Text := '';
  SetLength(Text, Length(AText));
  Count := 0;
  for I := 1 to Length(AText) do
    if (AText[I] <> #13) and (AText[I] <> #10) then
    begin
      if CharacterValue(AText[I]) < 0 then
        Fail;
      Inc(Count);
      Text[Count] := AText[I];
    end;
  SetLength(Text, Count);
  Result.Raw := Text;
  case Count of
    90:
      begin
        Result.Format := mfTD1;
        L1 := Copy(Text, 1, 30);
        L2 := Copy(Text, 31, 30);
        Names := Copy(Text, 61, 30);
        Result.OptionalData := Copy(L1, 16, 15);
        Result.OptionalData2 := Copy(L2, 19, 11);
        Result.DocumentNumber := DocumentNumber(Copy(L1, 6, 9),
          Result.OptionalData, L1[15], True);
        Result.BirthDate := Copy(L2, 1, 6);
        Verify(Result.BirthDate, L2[7]);
        Result.Sex := L2[8];
        Result.ExpiryDate := Copy(L2, 9, 6);
        Verify(Result.ExpiryDate, L2[15]);
        Result.Nationality := Copy(L2, 16, 3);
        Composite := Copy(L1, 6, 25) + Copy(L2, 1, 7) + Copy(L2, 9, 7) +
          Result.OptionalData2;
        Verify(Composite, L2[30]);
      end;
    72, 88:
      begin
        if Count = 72 then
        begin
          Result.Format := mfTD2;
          Split := 36;
        end
        else
        begin
          Result.Format := mfTD3;
          Split := 44;
        end;
        L1 := Copy(Text, 1, Split);
        L2 := Copy(Text, Split + 1, Split);
        Names := Copy(L1, 6, Split - 5);
        if Count = 72 then
          Result.OptionalData := Copy(L2, 29, 7)
        else
          Result.OptionalData := Copy(L2, 29, 14);
        Result.DocumentNumber := DocumentNumber(Copy(L2, 1, 9),
          Result.OptionalData, L2[10], Count = 72);
        Result.Nationality := Copy(L2, 11, 3);
        Result.BirthDate := Copy(L2, 14, 6);
        Verify(Result.BirthDate, L2[20]);
        Result.Sex := L2[21];
        Result.ExpiryDate := Copy(L2, 22, 6);
        Verify(Result.ExpiryDate, L2[28]);
        if Count = 88 then
        begin
          if (L2[43] = '<') and (TrimFillers(Result.OptionalData) = '') then
            Verify(Result.OptionalData, '0')
          else
            Verify(Result.OptionalData, L2[43]);
        end;
        Composite := Copy(L2, 1, 10) + Copy(L2, 14, 7) +
          Copy(L2, 22, Split - 22);
        Verify(Composite, L2[Split]);
      end;
  else
    Fail;
  end;
  ValidateDate(Result.BirthDate);
  ValidateDate(Result.ExpiryDate);
  if (Result.Sex <> 'M') and (Result.Sex <> 'F') and (Result.Sex <> '<') then
    Fail;
  Result.DocumentCode := Copy(L1, 1, 2);
  Result.IssuingState := Copy(L1, 3, 3);
  ValidateLetters(Result.DocumentCode);
  if Result.DocumentCode[1] = '<' then
    Fail;
  ValidateLetters(Result.IssuingState);
  ValidateLetters(Result.Nationality);
  ValidateLetters(Names);
  Split := Pos('<<', Names);
  if Split = 0 then
    Result.Surname := NameText(Names)
  else
  begin
    Result.Surname := NameText(Copy(Names, 1, Split - 1));
    Result.GivenNames := NameText(Copy(Names, Split + 2, Length(Names)));
  end;
end;

end.
