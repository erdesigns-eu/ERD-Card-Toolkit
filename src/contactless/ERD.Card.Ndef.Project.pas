unit ERD.Card.Ndef.Project;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses ERD.Card.Project, ERD.Card.Ndef;
type
  /// <summary>Typed canonical NDEF artifacts; no tag storage mapping or lock policy is inferred.</summary>
  TNdefProjectArtifacts = class
  public
    /// <summary>Encodes and stores a validated nonempty logical message.</summary>
    /// <param name="AProject">Initialized project.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="AMessage">Validated records with copied encoded payloads.</param>
    class procedure Put(const AProject: TCardProject; const AId: string; const AMessage: TNdefMessage); static;
    /// <summary>Checks schema and decodes independently owned logical records.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">NDEF artifact identifier.</param>
    /// <returns>Decoded message, without hardware I/O or tag-write authorization.</returns>
    class function Get(const AProject: TCardProject; const AId: string): TNdefMessage; static;
  end;
implementation
class procedure TNdefProjectArtifacts.Put(const AProject: TCardProject; const AId: string; const AMessage: TNdefMessage);
var Item: TCardProjectArtifact;
begin
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Item := Default(TCardProjectArtifact); Item.Id := AId; Item.Profile := 'ndef.v1';
  Item.Data := TNdefCodec.Encode(AMessage); AProject.Put(Item);
end;
class function TNdefProjectArtifacts.Get(const AProject: TCardProject; const AId: string): TNdefMessage;
var Item: TCardProjectArtifact;
begin
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Item := AProject.Get(AId);
  if Item.Profile<>'ndef.v1' then raise ECardProjectError.Create('Unsupported NDEF artifact schema.');
  Result := TNdefCodec.Decode(Item.Data);
end;
end.
