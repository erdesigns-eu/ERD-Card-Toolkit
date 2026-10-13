unit ERD.Card.Project;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes;

type
  /// <summary>Invalid bounded project identifier, data or versioned archive.</summary>
  ECardProjectError = class(Exception);
  /// <summary>One copied card artifact, with an explicit schema/profile identifier.</summary>
  TCardProjectArtifact = record
    /// <summary>Unique case-sensitive ASCII identifier, at most 128 characters.</summary>
    Id: string;
    /// <summary>Explicit ASCII schema/profile identifier, at most 128 characters.</summary>
    Profile: string;
    /// <summary>Independent snapshot/report bytes; not a live reader, key store or executable operation.</summary>
    Data: TBytes;
  end;
  /// <summary>Nonvisual bounded project container with atomic import and copy-isolated artifacts.</summary>
  /// <remarks>Version-one ASCII archives contain raw artifact bytes, without encryption/signatures.
  /// Connections, live sessions and queued jobs are never serialized. Never add secrets to artifacts.
  /// Use on one owner thread. File dialogs, protected storage and key stores remain separate policies.</remarks>
  TCardProject = class(TComponent)
  private
    FId: string;
    FItems: array of TCardProjectArtifact;
    FDirty: Boolean;
  public
    /// <summary>Starts an empty project, discarding previous owned artifacts.</summary>
    /// <param name="AId">Explicit valid ASCII identifier.</param>
    procedure NewProject(const AId: string);
    /// <summary>Adds or replaces a copied artifact, within a 16 MiB total payload and 1024-entry budget.</summary>
    /// <param name="AArtifact">Validated ID/profile and at most 1 MiB of data.</param>
    procedure Put(const AArtifact: TCardProjectArtifact);
    /// <summary>Returns an independently copied artifact.</summary>
    /// <param name="AId">Exact artifact ID.</param>
    /// <returns>Owned bytes; unknown IDs raise without changing the project.</returns>
    function Get(const AId: string): TCardProjectArtifact;
    /// <summary>Removes one artifact; absent IDs leave dirty state unchanged.</summary>
    /// <param name="AId">Exact artifact ID.</param>
    procedure Remove(const AId: string);
    /// <summary>Lists owned artifact IDs in insertion order.</summary>
    /// <returns>Owned list; caller frees it.</returns>
    function ArtifactIds: TStringList;
    /// <summary>Exports deterministic version-one archive text without marking it saved.</summary>
    /// <returns>ASCII text; no filesystem mutation or credential serialization.</returns>
    function ExportText: string;
    /// <summary>Atomically imports a strict version-one archive after complete bounded validation.</summary>
    /// <param name="AText">At most 34 MiB of ASCII project text.</param>
    /// <remarks>Malformed/duplicate/unsupported input preserves the existing project. Success clears Dirty.</remarks>
    procedure ImportText(const AText: string);
    /// <summary>Marks an externally persisted current project clean, without performing I/O.</summary>
    procedure MarkSaved;
    /// <summary>Writes the complete archive at the stream position and marks clean only after success.</summary>
    /// <param name="AStream">Non-nil caller-owned writable stream; flush/durability and atomic file replacement remain storage policy.</param>
    /// <remarks>Failure preserves Dirty but may leave partial bytes in the supplied stream.</remarks>
    procedure SaveToStream(const AStream: TStream);
    /// <summary>Imports the bounded remaining bytes of a readable stream atomically.</summary>
    /// <param name="AStream">Non-nil caller-owned seekable stream; non-ASCII or malformed data is refused.</param>
    /// <remarks>Failure preserves the current project; the stream position may have advanced.</remarks>
    procedure LoadFromStream(const AStream: TStream);
    /// <summary>Current project identifier; empty until initialized or imported.</summary>
    property ProjectId: string read FId;
    /// <summary>True after a content change; exporting alone does not clear it.</summary>
    property Dirty: Boolean read FDirty;
  end;

implementation

procedure ValidateId(const Id: string);
var I: Integer;
begin
  if (Length(Id)<1) or (Length(Id)>128) then raise ECardProjectError.Create('Invalid project identifier.');
  for I := 1 to Length(Id) do
    if not CharInSet(Id[I],['A'..'Z','a'..'z','0'..'9','-','_','.']) then
      raise ECardProjectError.Create('Invalid project identifier.');
end;

procedure TCardProject.NewProject(const AId: string);
begin
  ValidateId(AId); FId := AId; FItems := nil; FDirty := True;
end;

procedure TCardProject.Put(const AArtifact: TCardProjectArtifact);
var I, N, Index, Total: Integer; Item: TCardProjectArtifact;
begin
  ValidateId(FId); ValidateId(AArtifact.Id); ValidateId(AArtifact.Profile);
  if Length(AArtifact.Data)>1024*1024 then raise ECardProjectError.Create('Artifact budget exceeded.');
  Index := -1; Total := Length(AArtifact.Data);
  for I := 0 to High(FItems) do
    if FItems[I].Id=AArtifact.Id then Index := I else Inc(Total,Length(FItems[I].Data));
  if Total>16*1024*1024 then raise ECardProjectError.Create('Project budget exceeded.');
  Item := AArtifact; Item.Data := CopyBytes(AArtifact.Data);
  if Index<0 then begin
    N := Length(FItems); if N>=1024 then raise ECardProjectError.Create('Project entry budget exceeded.');
    SetLength(FItems,N+1); Index := N;
  end;
  if (FItems[Index].Id=Item.Id) and (FItems[Index].Profile=Item.Profile) and
    BytesEqual(FItems[Index].Data,Item.Data) then Exit;
  FItems[Index] := Item; FDirty := True;
end;

function TCardProject.Get(const AId: string): TCardProjectArtifact;
var I: Integer;
begin
  Result := Default(TCardProjectArtifact);
  for I := 0 to High(FItems) do if FItems[I].Id=AId then begin
    Result := FItems[I]; Result.Data := CopyBytes(FItems[I].Data); Exit;
  end;
  raise ECardProjectError.Create('Unknown artifact.');
end;

procedure TCardProject.Remove(const AId: string);
var I, J: Integer;
begin
  for I := 0 to High(FItems) do if FItems[I].Id=AId then begin
    for J := I to High(FItems)-1 do FItems[J] := FItems[J+1];
    SetLength(FItems,Length(FItems)-1); FDirty := True; Exit;
  end;
end;

function TCardProject.ArtifactIds: TStringList;
var I: Integer;
begin
  Result := TStringList.Create;
  for I := 0 to High(FItems) do Result.Add(FItems[I].Id);
end;

function TCardProject.ExportText: string;
var I: Integer;
begin
  ValidateId(FId); Result := 'ERD-PROJECT 1'+#10+'P '+FId+#10;
  for I := 0 to High(FItems) do
    Result := Result+'A '+FItems[I].Id+' '+FItems[I].Profile+' '+BytesToHex(FItems[I].Data)+#10;
end;

procedure TCardProject.ImportText(const AText: string);
var Lines: TStringList; Temp: TCardProject; I, J, P, Q: Integer;
  Line, Hex: string; Item: TCardProjectArtifact;
begin
  if (Length(AText)<1) or (Length(AText)>34*1024*1024) then
    raise ECardProjectError.Create('Project archive size exceeded.');
  for I := 1 to Length(AText) do if (Ord(AText[I])>127) or
    ((Ord(AText[I])<32) and not CharInSet(AText[I],[#10,#13])) then
      raise ECardProjectError.Create('Invalid project text.');
  Lines := TStringList.Create; Temp := TCardProject.Create(nil);
  try
    Lines.Text := AText;
    if (Lines.Count<2) or (Lines.Count>1026) then raise ECardProjectError.Create('Invalid project entry count.');
    if (Lines[0]<>'ERD-PROJECT 1') or (Copy(Lines[1],1,2)<>'P ') then
      raise ECardProjectError.Create('Unsupported project header.');
    Temp.NewProject(Copy(Lines[1],3,Length(Lines[1])));
    for I := 2 to Lines.Count-1 do begin
      Line := Lines[I];
      if Copy(Line,1,2)<>'A ' then raise ECardProjectError.Create('Invalid artifact line.');
      Delete(Line,1,2); P := Pos(' ',Line);
      if P=0 then raise ECardProjectError.Create('Invalid artifact fields.');
      Item.Id := Copy(Line,1,P-1); Delete(Line,1,P); Q := Pos(' ',Line);
      if Q=0 then raise ECardProjectError.Create('Invalid artifact fields.');
      Item.Profile := Copy(Line,1,Q-1); Hex := Copy(Line,Q+1,Length(Line));
      if Odd(Length(Hex)) or (Length(Hex)>2*1024*1024) then raise ECardProjectError.Create('Invalid artifact width.');
      for J := 1 to Length(Hex) do if not CharInSet(Hex[J],['0'..'9','A'..'F','a'..'f']) then
        raise ECardProjectError.Create('Invalid artifact hex.');
      for J := 0 to High(Temp.FItems) do if Temp.FItems[J].Id=Item.Id then
        raise ECardProjectError.Create('Duplicate project artifact.');
      Item.Data := HexToBytes(Hex); Temp.Put(Item);
    end;
    FId := Temp.FId; FItems := Temp.FItems; FDirty := False;
  finally Temp.Free; Lines.Free; end;
end;

procedure TCardProject.SaveToStream(const AStream: TStream);
var Text: string; Data: TBytes; I: Integer;
begin
  if AStream=nil then raise ECardProjectError.Create('A project stream is required.');
  Text := ExportText; SetLength(Data,Length(Text));
  for I := 1 to Length(Text) do Data[I-1] := Byte(Ord(Text[I]));
  AStream.WriteBuffer(Data[0],Length(Data)); FDirty := False;
end;

procedure TCardProject.LoadFromStream(const AStream: TStream);
var Text: string; Data: TBytes; I: Integer; Remaining: Int64;
begin
  if AStream=nil then raise ECardProjectError.Create('A project stream is required.');
  Remaining := AStream.Size-AStream.Position;
  if (Remaining<1) or (Remaining>34*1024*1024) then raise ECardProjectError.Create('Project stream size exceeded.');
  SetLength(Data,Integer(Remaining)); AStream.ReadBuffer(Data[0],Length(Data));
  SetLength(Text,Length(Data));
  for I := 0 to High(Data) do begin
    if Data[I]>127 then raise ECardProjectError.Create('Invalid project stream encoding.');
    Text[I+1] := Char(Data[I]);
  end;
  ImportText(Text);
end;

procedure TCardProject.MarkSaved;
begin
  ValidateId(FId); FDirty := False;
end;

end.
