unit ERD.Card.MOBIB.Archive;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Contactless.Calypso;

type
  /// <summary>Malformed offline snapshot; messages never contain record bytes.</summary>
  EMobibArchiveError = class(Exception);
  /// <summary>Versioned, bounded offline snapshot interchange; performs no reader or file I/O.</summary>
  TMobibArchive = class
  public
    /// <summary>Serializes records and observed selection/read statuses as ASCII text.</summary>
    /// <param name="ASnapshot">At most 64 unique files, 255 unique records per file, 256 bytes per record and 4096 selection bytes.</param>
    /// <returns>MOBIB-RECORDS 2 header with T/A/F/R lines; empty byte arrays use a dash.</returns>
    /// <remarks>Application and file metadata are reconstructed from captured response/header bytes.</remarks>
    /// <exception cref="EMobibArchiveError">Invalid bounds, duplicate identifiers or records.</exception>
    class function Encode(const ASnapshot: TMobibSnapshot): UnicodeString; static;
    /// <summary>Restores independent bytes and every captured status without assuming authorization.</summary>
    /// <param name="AText">ASCII interchange text, at most 16 MiB characters; ordered T/A, F and R lines; legacy version one is accepted.</param>
    /// <returns>Owned raw snapshot suitable for explicit TMobibCodec.Decode layout selection.</returns>
    /// <exception cref="EMobibArchiveError">Malformed header/fields, excessive data or duplicates.</exception>
    class function Decode(const AText: UnicodeString): TMobibSnapshot; static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail;
begin raise EMobibArchiveError.Create('Invalid MOBIB snapshot archive.'); end;

function Hex(const Data: TBytes): string;
begin if Length(Data) = 0 then Result := '-' else Result := BytesToHex(Data); end;

function Bytes(const Text: string; const MaxBytes: Integer): TBytes;
var I: Integer;
begin
  Result := nil; if Text = '-' then Exit;
  if (Length(Text) = 0) or (Length(Text) > MaxBytes*2) or Odd(Length(Text)) then Fail;
  for I := 1 to Length(Text) do
    if not (Text[I] in ['0'..'9','A'..'F','a'..'f']) then Fail;
  Result := HexToBytes(Text);
end;

function WordHex(const Text: string): Word;
var B: TBytes;
begin B := Bytes(Text,2); if Length(B) <> 2 then Fail; Result := (Word(B[0]) shl 8) or B[1]; end;

function SameAddress(const A, B: TCalypsoFile): Boolean;
var AF, BF: Word;
begin
  AF := A.Folder; if AF = 0 then AF := $2000;
  BF := B.Folder; if BF = 0 then BF := $2000;
  Result := (AF = BF) and (A.BySfi = B.BySfi);
  if A.BySfi then Result := Result and (A.Sfi = B.Sfi)
  else Result := Result and (A.LogicalId = B.LogicalId);
end;

class function TMobibArchive.Encode(const ASnapshot: TMobibSnapshot): UnicodeString;
var Lines: TStringList; I, J, K: Integer; F: TCalypsoFile; Revision2: Boolean; InfoBytes: TBytes;
begin
  if (Length(ASnapshot.Files) > 64) or (Length(ASnapshot.TicketingSelection) > 4096) or (Length(ASnapshot.Application.Response) > 4096) then Fail;
  Lines := TStringList.Create;
  try
    Lines.Add('MOBIB-RECORDS 2'); Lines.Add('T '+Hex(ASnapshot.TicketingSelection));
    Lines.Add('A '+IntToHex(ASnapshot.Application.StatusWord,4)+' '+Hex(ASnapshot.Application.Response));
    for I := 0 to High(ASnapshot.Files) do begin
      F := ASnapshot.Files[I];
      if ((not F.BySfi) and (F.LogicalId = 0)) or (Length(F.Records) > 255) or (Length(F.SelectionData) > 4096) then Fail;
      if F.BySfi and ((F.Sfi < 1) or (F.Sfi > 30)) then Fail;
      for K := 0 to I-1 do if SameAddress(ASnapshot.Files[K],F) then Fail;
      Revision2 := False; InfoBytes := nil;
      if F.Info.Present then begin
        InfoBytes := F.Info.Raw; if Length(InfoBytes) <> 23 then Fail;
        if F.Info.LogicalId <> ((Word(InfoBytes[21]) shl 8) or InfoBytes[22]) then begin
          if F.Info.LogicalId <> ((Word(InfoBytes[20]) shl 8) or InfoBytes[21]) then Fail;
          Revision2 := True;
        end;
      end;
      Lines.Add('F '+IntToHex(F.Folder,4)+' '+IntToHex(F.LogicalId,4)+' '+IntToStr(Ord(F.BySfi))+' '+
        IntToStr(F.Sfi)+' '+IntToHex(F.SelectionStatus,4)+' '+IntToHex(F.LastRecordStatus,4)+' '+
        IntToStr(Ord(F.Truncated))+' '+IntToStr(Ord(Revision2))+' '+Hex(InfoBytes)+' '+Hex(F.SelectionData));
      for J := 0 to High(F.Records) do begin
        if (F.Records[J].Number = 0) or (Length(F.Records[J].Data) > 256) then Fail;
        for K := 0 to J-1 do if F.Records[K].Number = F.Records[J].Number then Fail;
        Lines.Add('R '+IntToHex(F.LogicalId,4)+' '+IntToStr(F.Records[J].Number)+' '+Hex(F.Records[J].Data));
      end;
    end;
    Result := UnicodeString(Lines.Text);
  finally Lines.Free; end;
end;

class function TMobibArchive.Decode(const AText: UnicodeString): TMobibSnapshot;
var Lines, Fields: TStringList; I, J, N, RecordNumber, Current, FirstFileLine: Integer; Id, AppStatus: Word; Version2: Boolean; F: TCalypsoFile; AppBytes, InfoBytes: TBytes;
  function Number(const Text: string): Integer;
  var K: Integer;
  begin
    if Length(Text) = 0 then Fail;
    for K := 1 to Length(Text) do if not (Text[K] in ['0'..'9']) then Fail;
    if not TryStrToInt(Text,Result) then Fail;
  end;
begin
  Result := Default(TMobibSnapshot);
  if (Length(AText) = 0) or (Length(AText) > 16*1024*1024) then Fail;
  for I := 1 to Length(AText) do
    if not ((AText[I] = #10) or (AText[I] = #13) or
      ((AText[I] >= #32) and (AText[I] <= #126))) then Fail;
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.Text := string(AText);
    if (Lines.Count < 2) or ((Lines[0] <> 'MOBIB-RECORDS 1') and (Lines[0] <> 'MOBIB-RECORDS 2')) then Fail;
    Version2 := Lines[0] = 'MOBIB-RECORDS 2';
    Fields.StrictDelimiter := True; Fields.Delimiter := ' '; Fields.QuoteChar := #0;
    Fields.DelimitedText := Lines[1];
    if (Fields.Count <> 2) or (Fields[0] <> 'T') then Fail;
    Result.TicketingSelection := Bytes(Fields[1],4096); Current := -1; FirstFileLine := 2;
    if Version2 then begin
      if Lines.Count < 3 then Fail;
      Fields.DelimitedText := Lines[2]; if (Fields.Count <> 3) or (Fields[0] <> 'A') then Fail;
      AppStatus := WordHex(Fields[1]); AppBytes := Bytes(Fields[2],4096);
      if Length(AppBytes) > 0 then begin
        try Result.Application := TCalypsoFci.DecodeApplication(AppBytes); except on E: Exception do Fail; end;
      end;
      Result.Application.StatusWord := AppStatus;
      if AppStatus <> $9000 then Result.Application.Valid := False;
      FirstFileLine := 3;
    end;
    for I := FirstFileLine to Lines.Count-1 do begin
      if (Lines[I] = '') and (I = Lines.Count-1) then Continue;
      Fields.DelimitedText := Lines[I]; if Fields.Count < 1 then Fail;
      if Fields[0] = 'F' then begin
        F := Default(TCalypsoFile);
        if Version2 then begin
          if Fields.Count <> 11 then Fail;
          F.Folder := WordHex(Fields[1]); Id := WordHex(Fields[2]);
          if (Fields[3] <> '0') and (Fields[3] <> '1') then Fail;
          F.BySfi := Fields[3] = '1'; J := Number(Fields[4]); if J > 255 then Fail; F.Sfi := J;
          if F.BySfi and ((F.Sfi < 1) or (F.Sfi > 30)) then Fail;
          F.SelectionStatus := WordHex(Fields[5]); F.LastRecordStatus := WordHex(Fields[6]);
          if (Fields[7] <> '0') and (Fields[7] <> '1') then Fail;
          F.Truncated := Fields[7] = '1';
          if (Fields[8] <> '0') and (Fields[8] <> '1') then Fail;
          InfoBytes := Bytes(Fields[9],23);
          if Length(InfoBytes) > 0 then begin
            if Length(InfoBytes) <> 23 then Fail;
            try F.Info := TCalypsoFci.DecodeFileInfo(HexToBytes('8517'+BytesToHex(InfoBytes)),Fields[8] = '1');
            except on E: Exception do Fail; end;
          end else if Fields[8] <> '0' then Fail;
          F.SelectionData := Bytes(Fields[10],4096);
        end else begin
          if Fields.Count <> 6 then Fail;
          Id := WordHex(Fields[1]); F.SelectionStatus := WordHex(Fields[2]); F.LastRecordStatus := WordHex(Fields[3]);
          if (Fields[4] <> '0') and (Fields[4] <> '1') then Fail;
          F.Truncated := Fields[4] = '1'; F.SelectionData := Bytes(Fields[5],4096);
        end;
        if (Id = 0) and not F.BySfi then Fail; F.LogicalId := Id;
        N := Length(Result.Files); if N >= 64 then Fail;
        for J := 0 to N-1 do if SameAddress(Result.Files[J],F) then Fail;
        SetLength(Result.Files,N+1); Current := N; Result.Files[N] := F;
      end else if Fields[0] = 'R' then begin
        if (Fields.Count <> 4) or (Current < 0) then Fail;
        if WordHex(Fields[1]) <> Result.Files[Current].LogicalId then Fail;
        RecordNumber := Number(Fields[2]); if (RecordNumber < 1) or (RecordNumber > 255) then Fail;
        N := Length(Result.Files[Current].Records); if N >= 255 then Fail;
        for J := 0 to N-1 do if Result.Files[Current].Records[J].Number = RecordNumber then Fail;
        SetLength(Result.Files[Current].Records,N+1);
        Result.Files[Current].Records[N].Number := RecordNumber;
        Result.Files[Current].Records[N].Data := Bytes(Fields[3],256);
      end else Fail;
    end;
  finally Fields.Free; Lines.Free; end;
end;

end.
