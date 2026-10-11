unit ERD.Card.Contactless.Classic.Access;

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

type
  /// <summary>Invalid or inconsistent Classic sector access-bit encoding.</summary>
  EClassicAccessError = class(EConvertError)
  end;
  /// <summary>Four three-bit C1/C2/C3 access conditions, with trailer at index three.</summary>
  TClassicAccessConditions = array [0 .. 3] of Byte;
  /// <summary>Pure MIFARE Classic access-bit codec; conditions retain native card semantics.</summary>
  TClassicAccessCodec = class
  public
    /// <summary>Decodes three access bytes and checks every inverted redundant bit.</summary>
    /// <param name="ABytes">Exactly bytes six through eight of a trailer.</param>
    /// <returns>Four values zero through seven in C1/C2/C3 order.</returns>
    class function Decode(const ABytes: TBytes): TClassicAccessConditions; static;
    /// <summary>Encodes four conditions with valid inverted copies.</summary>
    /// <param name="AConditions">Four values zero through seven.</param>
    /// <returns>Independent three-byte access field.</returns>
    class function Encode(const AConditions: TClassicAccessConditions): TBytes; static;
    /// <summary>Reports trailer modes where Key B is readable data and cannot authenticate.</summary>
    /// <param name="ATrailerCondition">Native trailer C1/C2/C3 condition zero through seven.</param>
    /// <returns>True for conditions zero, one or two.</returns>
    class function KeyBReadable(const ATrailerCondition: Byte): Boolean; static;
  end;

implementation

class function TClassicAccessCodec.Decode(const ABytes: TBytes): TClassicAccessConditions;
var I, C1, C2, C3: Integer;
begin
  if Length(ABytes) <> 3 then raise EClassicAccessError.Create('Access field size.');
  for I := 0 to 3 do
  begin
    C1 := (ABytes[1] shr (4 + I)) and 1;
    C2 := (ABytes[2] shr I) and 1;
    C3 := (ABytes[2] shr (4 + I)) and 1;
    if (((ABytes[0] shr I) and 1) = C1) or
      (((ABytes[0] shr (4 + I)) and 1) = C2) or
      (((ABytes[1] shr I) and 1) = C3) then
      raise EClassicAccessError.Create('Inconsistent access bits.');
    Result[I] := Byte((C1 shl 2) or (C2 shl 1) or C3);
  end;
end;

class function TClassicAccessCodec.Encode(const AConditions: TClassicAccessConditions): TBytes;
var I, C1, C2, C3: Integer;
begin
  Result := nil;
  SetLength(Result, 3);
  for I := 0 to 3 do
  begin
    if AConditions[I] > 7 then raise EClassicAccessError.Create('Access condition range.');
    C1 := (AConditions[I] shr 2) and 1;
    C2 := (AConditions[I] shr 1) and 1;
    C3 := AConditions[I] and 1;
    Result[0] := Result[0] or Byte(((C1 xor 1) shl I) or ((C2 xor 1) shl (4 + I)));
    Result[1] := Result[1] or Byte((C1 shl (4 + I)) or ((C3 xor 1) shl I));
    Result[2] := Result[2] or Byte((C2 shl I) or (C3 shl (4 + I)));
  end;
end;

class function TClassicAccessCodec.KeyBReadable(const ATrailerCondition: Byte): Boolean;
begin
  if ATrailerCondition > 7 then raise EClassicAccessError.Create('Trailer condition range.');
  Result := ATrailerCondition in [0, 1, 2];
end;

end.
