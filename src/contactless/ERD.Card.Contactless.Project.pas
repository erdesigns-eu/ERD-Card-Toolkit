unit ERD.Card.Contactless.Project;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Project, ERD.Card.Project.Schema, ERD.Card.Contactless.Workflow.DESFire, ERD.Card.Contactless.Calypso;

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

/// <summary>Registers the explicit MOBIB version-one to version-two archive upgrade without inventing absent application metadata.</summary>
/// <param name="ARegistry">Non-nil schema registry; duplicate registration is refused.</param>
procedure RegisterContactlessProjectMigrations(const ARegistry: TCardProjectSchemaRegistry);

implementation

uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Project.Artifacts, ERD.Card.MOBIB.Archive;
type
  TMobibMigration = class(TInterfacedObject, ICardArtifactMigration)
    function Convert(const AArtifact: TCardProjectArtifact): TCardProjectArtifact;
  end;
function TMobibMigration.Convert(const AArtifact: TCardProjectArtifact): TCardProjectArtifact;
var Temp: TCardProject; Text: string; Snapshot: TMobibSnapshot;
begin
  Temp := TCardProject.Create(nil);
  try
    Temp.NewProject('upgrade'); Temp.Put(AArtifact);
    Text := TCardProjectArtifacts.GetArchive(Temp,AArtifact.Id,'mobib.v1');
    if Copy(Text,1,15)<>'MOBIB-RECORDS 1' then raise ECardProjectError.Create('A version-one MOBIB archive is required.');
    Snapshot := TMobibArchive.Decode(UnicodeString(Text));
    TContactlessProjectArtifacts.PutMobib(Temp,AArtifact.Id,Snapshot);
    Result := Temp.Get(AArtifact.Id);
  finally Temp.Free; end;
end;
procedure RegisterContactlessProjectMigrations(const ARegistry: TCardProjectSchemaRegistry);
var Migration: ICardArtifactMigration;
begin
  if ARegistry=nil then raise ECardProjectError.Create('A schema registry is required.');
  Migration := TMobibMigration.Create;
  ARegistry.RegisterMigration('mobib.v1','mobib.v2',Migration);
end;

class procedure TContactlessProjectArtifacts.PutDesfire(const AProject: TCardProject;
  const AId: string; const ASnapshot: TDesfireWorkflowSnapshot);
var Text,Profile: string;
begin
  Text := TDesfireWorkflowArchive.Encode(ASnapshot); Profile := 'desfire.v1';
  if Copy(Text,1,Length('ERD-DESFIRE 2'))='ERD-DESFIRE 2' then Profile := 'desfire.v2';
  TCardProjectArtifacts.PutArchive(AProject,AId,Profile,Text);
end;

class function TContactlessProjectArtifacts.GetDesfire(const AProject: TCardProject;
  const AId: string): TDesfireWorkflowSnapshot;
var Item: TCardProjectArtifact; Text: string;
begin
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Item := AProject.Get(AId);
  if not ((Item.Profile='desfire.v1') or (Item.Profile='desfire.v2')) then
    raise ECardProjectError.Create('Unsupported DESFire artifact schema.');
  Text := TCardProjectArtifacts.GetArchive(AProject,AId,Item.Profile);
  if ((Item.Profile='desfire.v1') and (Copy(Text,1,Length('ERD-DESFIRE 1'))<>'ERD-DESFIRE 1')) or
    ((Item.Profile='desfire.v2') and (Copy(Text,1,Length('ERD-DESFIRE 2'))<>'ERD-DESFIRE 2')) then
    raise ECardProjectError.Create('DESFire artifact version mismatch.');
  Result := TDesfireWorkflowArchive.Decode(Text);
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
