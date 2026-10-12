unit ERD.Card.Contactless.Project;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Project, ERD.Card.Contactless.Workflow.DESFire, ERD.Card.Contactless.Calypso;

type
  /// <summary>Typed DESFire and MOBIB project artifacts, validated by their archive codecs without adding credentials.</summary>
  TContactlessProjectArtifacts = class
  public
    /// <summary>Stores complete readable ordinary DESFire files, settings and observed identity.</summary>
    /// <param name="AProject">Initialized project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Complete ordinary application snapshot; no keys.</param>
    class procedure PutDesfire(const AProject: TCardProject; const AId: string;
      const ASnapshot: TDesfireWorkflowSnapshot); static;
    /// <summary>Restores a validated ordinary DESFire snapshot without card operations.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">DESFire artifact identifier.</param>
    /// <returns>Independent identity, settings and file bytes.</returns>
    class function GetDesfire(const AProject: TCardProject; const AId: string): TDesfireWorkflowSnapshot; static;
    /// <summary>Stores acquired MOBIB records and selection/read status evidence.</summary>
    /// <param name="AProject">Initialized project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Captured records, including unreadable-file status evidence.</param>
    class procedure PutMobib(const AProject: TCardProject; const AId: string;
      const ASnapshot: TMobibSnapshot); static;
    /// <summary>Restores a validated MOBIB capture for existing offline parsing/reporting components.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">MOBIB artifact identifier.</param>
    /// <returns>Independent raw evidence; operator rules are applied separately.</returns>
    class function GetMobib(const AProject: TCardProject; const AId: string): TMobibSnapshot; static;
  end;

implementation

uses ERD.Card.Project.Artifacts, ERD.Card.MOBIB.Archive;

class procedure TContactlessProjectArtifacts.PutDesfire(const AProject: TCardProject;
  const AId: string; const ASnapshot: TDesfireWorkflowSnapshot);
begin
  TCardProjectArtifacts.PutArchive(AProject,AId,'desfire.v1',TDesfireWorkflowArchive.Encode(ASnapshot));
end;

class function TContactlessProjectArtifacts.GetDesfire(const AProject: TCardProject;
  const AId: string): TDesfireWorkflowSnapshot;
begin
  Result := TDesfireWorkflowArchive.Decode(TCardProjectArtifacts.GetArchive(AProject,AId,'desfire.v1'));
end;

class procedure TContactlessProjectArtifacts.PutMobib(const AProject: TCardProject;
  const AId: string; const ASnapshot: TMobibSnapshot);
begin
  TCardProjectArtifacts.PutArchive(AProject,AId,'mobib.v2',string(TMobibArchive.Encode(ASnapshot)));
end;

class function TContactlessProjectArtifacts.GetMobib(const AProject: TCardProject;
  const AId: string): TMobibSnapshot;
begin
  Result := TMobibArchive.Decode(UnicodeString(TCardProjectArtifacts.GetArchive(AProject,AId,'mobib.v2')));
end;

end.
