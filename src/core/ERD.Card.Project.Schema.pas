unit ERD.Card.Project.Schema;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Project;
type
  /// <summary>Explicit offline schema conversion; never execute card operations or modify the source project.</summary>
  ICardArtifactMigration = interface
    ['{CBA22764-9BA4-47A3-AE2F-46C11D825D81}']
    /// <summary>Returns independently owned converted data for a registered schema edge.</summary>
    /// <param name="AArtifact">Copied source with exact registered ID and schema.</param>
    /// <returns>Same ID and exact target schema; credentials and executable jobs must not be introduced.</returns>
    function Convert(const AArtifact: TCardProjectArtifact): TCardProjectArtifact;
  end;
  /// <summary>One explicit offline migration registration, without executable card operations.</summary>
  TCardArtifactMigrationEdge = record
    /// <summary>Exact source schema identifier.</summary>
    Source: string;
    /// <summary>Exact target schema identifier.</summary>
    Target: string;
    /// <summary>Retained offline converter.</summary>
    Migration: ICardArtifactMigration;
  end;
  /// <summary>Inactive bounded offline schema registry; migrations are explicit, never guessed on project load.</summary>
  /// <remarks>Owner-thread API. Only the final valid artifact is applied; a failed path leaves the original unchanged.</remarks>
  TCardProjectSchemaRegistry = class(TComponent)
  private
    FEdges: array of TCardArtifactMigrationEdge;
  public
    /// <summary>Registers one unique explicit source-to-target conversion, within 256 edges.</summary>
    /// <param name="ASource">Valid source schema identifier.</param>
    /// <param name="ATarget">Different valid target identifier.</param>
    /// <param name="AMigration">Retained non-nil offline converter.</param>
    procedure RegisterMigration(const ASource, ATarget: string; const AMigration: ICardArtifactMigration);
    /// <summary>Converts through one to eight caller-selected schema edges, with atomic final replacement.</summary>
    /// <param name="AProject">Initialized owner-thread project.</param>
    /// <param name="AId">Existing artifact identifier.</param>
    /// <param name="ATargets">Ordered exact target schemas; no path search or implicit downgrade.</param>
    procedure MigratePath(const AProject: TCardProject; const AId: string; const ATargets: array of string);
    /// <summary>Releases registered converters without changing projects.</summary>
    procedure Clear;
  end;
implementation
procedure TCardProjectSchemaRegistry.RegisterMigration(const ASource, ATarget: string; const AMigration: ICardArtifactMigration);
var I,N: Integer; Temp: TCardProject; Item: TCardProjectArtifact;
begin
  if (AMigration=nil) or (ASource=ATarget) then raise ECardProjectError.Create('An explicit schema conversion is required.');
  Temp := TCardProject.Create(nil);
  try
    Temp.NewProject('schema'); Item := Default(TCardProjectArtifact); Item.Id := 'validate';
    Item.Profile := ASource; Temp.Put(Item); Item.Profile := ATarget; Temp.Put(Item);
  finally Temp.Free; end;
  for I := 0 to High(FEdges) do if (FEdges[I].Source=ASource) and (FEdges[I].Target=ATarget) then
    raise ECardProjectError.Create('Duplicate schema migration.');
  N := Length(FEdges); if N>=256 then raise ECardProjectError.Create('Schema registry budget exceeded.');
  SetLength(FEdges,N+1); FEdges[N].Source := ASource; FEdges[N].Target := ATarget; FEdges[N].Migration := AMigration;
end;
procedure TCardProjectSchemaRegistry.MigratePath(const AProject: TCardProject; const AId: string; const ATargets: array of string);
var Item,Converted: TCardProjectArtifact; I,J,Found: Integer; Temp: TCardProject; Original: string;
  Migrations: array of ICardArtifactMigration; Source: string;
begin
  if (AProject=nil) or (Length(ATargets)<1) or (Length(ATargets)>8) then
    raise ECardProjectError.Create('An explicit bounded migration path is required.');
  Original := AProject.ExportText; Item := AProject.Get(AId); Source := Item.Profile;
  SetLength(Migrations,Length(ATargets));
  for I := 0 to High(ATargets) do begin
    Found := -1;
    for J := 0 to High(FEdges) do if (FEdges[J].Source=Source) and (FEdges[J].Target=ATargets[I]) then Found := J;
    if Found<0 then raise ECardProjectError.Create('Unregistered schema migration.');
    Migrations[I] := FEdges[Found].Migration; Source := ATargets[I];
  end;
  Temp := TCardProject.Create(nil);
  try
    Temp.NewProject('migration');
    for I := 0 to High(ATargets) do begin
      Converted := Migrations[I].Convert(Item);
      if (Converted.Id<>AId) or (Converted.Profile<>ATargets[I]) then
        raise ECardProjectError.Create('Invalid schema conversion result.');
      Temp.Put(Converted); Item := Temp.Get(AId);
    end;
    if AProject.ExportText<>Original then raise ECardProjectError.Create('Project changed during schema conversion.');
    AProject.Put(Item);
  finally Temp.Free; end;
end;
procedure TCardProjectSchemaRegistry.Clear;
begin FEdges := nil; end;
end.
