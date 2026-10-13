unit ERD.Card.SIM.Project;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses ERD.Card.Project, ERD.Card.SIM.Workflow;
type
  /// <summary>Typed bounded project adapter using the existing family archive validation.</summary>
  TSimProjectArtifacts = class
  public
    /// <summary>Validates and copies a complete family snapshot without credentials or live sessions.</summary>
    /// <param name="AProject">Initialized project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Complete captured snapshot; security metadata is diagnostic.</param>
    class procedure Put(const AProject: TCardProject; const AId: string; const ASnapshot: TSimWorkflowSnapshot); static;
    /// <summary>Checks the exact schema and returns independently decoded data without I/O.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Existing family artifact identifier.</param>
    /// <returns>Validated snapshot; restore permissions and live compatibility remain workflow checks.</returns>
    class function Get(const AProject: TCardProject; const AId: string): TSimWorkflowSnapshot; static;
  end;
implementation
uses ERD.Card.Project.Artifacts;
class procedure TSimProjectArtifacts.Put(const AProject: TCardProject; const AId: string; const ASnapshot: TSimWorkflowSnapshot);
begin TCardProjectArtifacts.PutArchive(AProject,AId,'sim.v1',TSimWorkflowCodec.EncodeSnapshot(ASnapshot)); end;
class function TSimProjectArtifacts.Get(const AProject: TCardProject; const AId: string): TSimWorkflowSnapshot;
begin Result := TSimWorkflowCodec.DecodeSnapshot(TCardProjectArtifacts.GetArchive(AProject,AId,'sim.v1')); end;
end.
