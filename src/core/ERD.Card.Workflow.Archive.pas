unit ERD.Card.Workflow.Archive;

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
  ERD.Card.Bytes, ERD.Card.Workflow;

type
  /// <summary>Bounded versioned memory snapshot files; contains raw data but never supplied keys.</summary>
  /// <remarks>ASCII hex format preserves exact selected bytes. No encryption or authenticity
  /// guarantee; applications decide where and how to protect backups. Unit states are runtime
  /// evidence and deliberately excluded from the archive.</remarks>
  TCardWorkflowArchive = class
  public
    /// <summary>Serializes one complete selected-memory snapshot.</summary>
    /// <param name="ASnapshot">Nonempty bounded layout, UID and unique complete units.</param>
    /// <returns>ASCII version-one archive text.</returns>
    class function Encode(const ASnapshot: TCardWorkflowSnapshot): string; static;
    /// <summary>Strictly parses a version-one snapshot without touching hardware.</summary>
    /// <param name="AText">At most three MiB of ASCII archive text.</param>
    /// <returns>Independent selected-memory buffers; restore still checks target compatibility.</returns>
    class function Decode(const AText: string): TCardWorkflowSnapshot; static;
  end;

implementation

procedure Validate(const ASnapshot: TCardWorkflowSnapshot);
var I, J, Width: Integer;
begin
  if (Length(ASnapshot.Layout) < 1) or (Length(ASnapshot.Layout) > 128) or
    (Length(ASnapshot.Uid) < 1) or (Length(ASnapshot.Uid) > 64) or
    (Length(ASnapshot.Units) < 1) or (Length(ASnapshot.Units) > 4096) then
    raise ECardWorkflowError.Create('Invalid archive geometry.');
  for I := 1 to Length(ASnapshot.Layout) do
    if not CharInSet(ASnapshot.Layout[I], ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '-', '_', '.']) then
      raise ECardWorkflowError.Create('Invalid layout identifier.');
  Width := Length(ASnapshot.Units[0].Data);
  if (Width < 1) or (Width > 256) then raise ECardWorkflowError.Create('Invalid unit width.');
  for I := 0 to High(ASnapshot.Units) do
  begin
    if (ASnapshot.Units[I].Address < 0) or (ASnapshot.Units[I].Address > 65535) or
      (Length(ASnapshot.Units[I].Data) <> Width) then
      raise ECardWorkflowError.Create('Invalid archive unit.');
    for J := 0 to I - 1 do
      if ASnapshot.Units[I].Address = ASnapshot.Units[J].Address then
        raise ECardWorkflowError.Create('Duplicate archive address.');
  end;
end;

class function TCardWorkflowArchive.Encode(const ASnapshot: TCardWorkflowSnapshot): string;
var I: Integer; Lines: TStringList;
begin
  Validate(ASnapshot);
  Lines := TStringList.Create;
  try
    Lines.Add('ERD-MEMORY 1');
    Lines.Add('L ' + ASnapshot.Layout);
    Lines.Add('I ' + BytesToHex(ASnapshot.Uid));
    for I := 0 to High(ASnapshot.Units) do
      Lines.Add('U ' + IntToStr(ASnapshot.Units[I].Address) + ' ' + BytesToHex(ASnapshot.Units[I].Data));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function StrictHex(const AText: string): TBytes;
var I: Integer;
begin
  if (Length(AText) < 2) or (Length(AText) > 512) or Odd(Length(AText)) then
    raise ECardWorkflowError.Create('Invalid archive hex width.');
  for I := 1 to Length(AText) do
    if not CharInSet(AText[I], ['0' .. '9', 'A' .. 'F', 'a' .. 'f']) then
      raise ECardWorkflowError.Create('Invalid archive hex.');
  Result := HexToBytes(AText);
end;

class function TCardWorkflowArchive.Decode(const AText: string): TCardWorkflowSnapshot;
var Lines: TStringList; I, P, Address: Integer; Line, Number: string;
begin
  Result.Layout := '';
  Result.Uid := nil;
  Result.Units := nil;
  if (Length(AText) < 1) or (Length(AText) > 3 * 1024 * 1024) then
    raise ECardWorkflowError.Create('Archive input size.');
  for I := 1 to Length(AText) do
    if not(Ord(AText[I]) in [10, 13, 32 .. 126]) then
      raise ECardWorkflowError.Create('Archive character.');
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count < 4) or (Lines.Count > 4099) or (Lines[0] <> 'ERD-MEMORY 1') or
      (Copy(Lines[1], 1, 2) <> 'L ') or (Copy(Lines[2], 1, 2) <> 'I ') then
      raise ECardWorkflowError.Create('Archive header.');
    Result.Layout := Copy(Lines[1], 3, MaxInt);
    Result.Uid := StrictHex(Copy(Lines[2], 3, MaxInt));
    SetLength(Result.Units, Lines.Count - 3);
    for I := 3 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      if Copy(Line, 1, 2) <> 'U ' then raise ECardWorkflowError.Create('Archive row.');
      Delete(Line, 1, 2);
      P := Pos(' ', Line);
      if P < 2 then raise ECardWorkflowError.Create('Archive address.');
      Number := Copy(Line, 1, P - 1);
      if not TryStrToInt(Number, Address) or (IntToStr(Address) <> Number) then
        raise ECardWorkflowError.Create('Noncanonical archive address.');
      Result.Units[I - 3].Address := Address;
      Result.Units[I - 3].Data := StrictHex(Copy(Line, P + 1, MaxInt));
      Result.Units[I - 3].State := cwusPending;
    end;
    Validate(Result);
  finally
    Lines.Free;
  end;
end;

end.
