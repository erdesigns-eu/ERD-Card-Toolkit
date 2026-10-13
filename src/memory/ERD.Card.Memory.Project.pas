unit ERD.Card.Memory.Project;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses ERD.Card.Project, ERD.Card.Memory, ERD.Card.Memory.Workflow;
type
  /// <summary>Typed bounded project adapter using the existing family archive validation.</summary>
  TContactMemoryProjectArtifacts = class
  public
    /// <summary>Validates and copies a complete family snapshot without credentials or live sessions.</summary>
    /// <param name="AProject">Initialized project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Complete captured snapshot; security metadata is diagnostic.</param>
    class procedure Put(const AProject: TCardProject; const AId: string; const ASnapshot: TMemoryCardSnapshot); static;
    /// <summary>Checks the exact schema and returns independently decoded data without I/O.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Existing family artifact identifier.</param>
    /// <returns>Validated snapshot; restore permissions and live compatibility remain workflow checks.</returns>
    class function Get(const AProject: TCardProject; const AId: string): TMemoryCardSnapshot; static;
  end;
implementation
uses ERD.Card.Project.Artifacts;
class procedure TContactMemoryProjectArtifacts.Put(const AProject: TCardProject; const AId: string; const ASnapshot: TMemoryCardSnapshot);
begin TCardProjectArtifacts.PutArchive(AProject,AId,'contact-memory.v1',TContactMemoryWorkflowArchive.Encode(ASnapshot)); end;
class function TContactMemoryProjectArtifacts.Get(const AProject: TCardProject; const AId: string): TMemoryCardSnapshot;
begin Result := TContactMemoryWorkflowArchive.Decode(TCardProjectArtifacts.GetArchive(AProject,AId,'contact-memory.v1')); end;
end.
