unit ERD.Card.Project.Artifacts;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Project, ERD.Card.Workflow;

type
  /// <summary>Strict versioned ASCII archive bridge and typed selected-memory project artifacts.</summary>
  /// <remarks>Adapters do not add credentials; card payloads may contain sensitive data. A decoded snapshot is not write permission.</remarks>
  TCardProjectArtifacts = class
  public
    /// <summary>Copies an ASCII archive into a project after checking its encoding and size.</summary>
    /// <param name="AProject">Initialized destination project.</param>
    /// <param name="AId">Unique artifact identifier.</param>
    /// <param name="AProfile">Exact adapter schema/version identifier.</param>
    /// <param name="AText">Nonempty ASCII archive, at most one MiB.</param>
    class procedure PutArchive(const AProject: TCardProject; const AId, AProfile, AText: string); static;
    /// <summary>Reads an independent ASCII archive only when its schema exactly matches.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Existing artifact identifier.</param>
    /// <param name="AProfile">Required adapter schema/version.</param>
    /// <returns>Independent archive text; malformed encoding and other profiles are refused.</returns>
    class function GetArchive(const AProject: TCardProject; const AId, AProfile: string): string; static;
    /// <summary>Validates and stores a selected-memory backup using the existing memory archive codec.</summary>
    /// <param name="AProject">Initialized destination project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Complete bounded selected-memory image.</param>
    class procedure PutMemory(const AProject: TCardProject; const AId: string;
      const ASnapshot: TCardWorkflowSnapshot); static;
    /// <summary>Validates and restores independently owned selected-memory data without reader I/O.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Memory artifact identifier.</param>
    /// <returns>Decoded snapshot; target compatibility and permissions remain workflow checks.</returns>
    class function GetMemory(const AProject: TCardProject; const AId: string): TCardWorkflowSnapshot; static;
  end;

implementation

uses ERD.Card.Workflow.Archive;

class procedure TCardProjectArtifacts.PutArchive(const AProject: TCardProject;
  const AId, AProfile, AText: string);
var Item: TCardProjectArtifact; I: Integer;
begin
  if (AProject=nil) or (Length(AText)<1) or (Length(AText)>1024*1024) then
    raise ECardProjectError.Create('Invalid project archive size.');
  Item := Default(TCardProjectArtifact); Item.Id := AId; Item.Profile := AProfile;
  SetLength(Item.Data,Length(AText));
  for I := 1 to Length(AText) do begin
    if not (Ord(AText[I]) in [10,13,32..126]) then
      raise ECardProjectError.Create('Invalid project archive encoding.');
    Item.Data[I-1] := Byte(Ord(AText[I]));
  end;
  AProject.Put(Item);
end;

class function TCardProjectArtifacts.GetArchive(const AProject: TCardProject;
  const AId, AProfile: string): string;
var Item: TCardProjectArtifact; I: Integer;
begin
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Item := AProject.Get(AId);
  if (Item.Profile<>AProfile) or (Length(Item.Data)<1) then
    raise ECardProjectError.Create('Unsupported project artifact schema.');
  SetLength(Result,Length(Item.Data));
  for I := 0 to High(Item.Data) do begin
    if not (Item.Data[I] in [10,13,32..126]) then
      raise ECardProjectError.Create('Invalid project archive encoding.');
    Result[I+1] := Char(Item.Data[I]);
  end;
end;

class procedure TCardProjectArtifacts.PutMemory(const AProject: TCardProject; const AId: string;
  const ASnapshot: TCardWorkflowSnapshot);
begin
  PutArchive(AProject,AId,'memory.v1',TCardWorkflowArchive.Encode(ASnapshot));
end;

class function TCardProjectArtifacts.GetMemory(const AProject: TCardProject;
  const AId: string): TCardWorkflowSnapshot;
begin
  Result := TCardWorkflowArchive.Decode(GetArchive(AProject,AId,'memory.v1'));
end;

end.
