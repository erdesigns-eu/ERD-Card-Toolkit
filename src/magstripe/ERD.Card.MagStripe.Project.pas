unit ERD.Card.MagStripe.Project;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Project, ERD.Card.MagStripe.Tracks;

type
  /// <summary>Explicit physical track selection with independently owned unframed payloads.</summary>
  TMagStripeProjectSnapshot = record
    /// <summary>Nonempty selected physical tracks; unselected payloads must be empty.</summary>
    Tracks: TMagStripeTrackSet;
    /// <summary>Validated unframed track strings; may contain personal data.</summary>
    Data: TMagStripeTracks;
  end;
  /// <summary>Strict versioned project adapter for magstripe templates and read-only backups.</summary>
  /// <remarks>Does not imply device capabilities, coercivity, programming or read-back verification.</remarks>
  TMagStripeProjectArtifacts = class
  public
    /// <summary>Validates and copies a selected-track snapshot into a project.</summary>
    /// <param name="AProject">Initialized destination.</param>
    /// <param name="AId">Artifact identifier.</param>
    /// <param name="ASnapshot">Nonempty selection and valid track payloads.</param>
    class procedure Put(const AProject: TCardProject; const AId: string;
      const ASnapshot: TMagStripeProjectSnapshot); static;
    /// <summary>Decodes and validates an exact version-one track artifact without device I/O.</summary>
    /// <param name="AProject">Source project.</param>
    /// <param name="AId">Track artifact identifier.</param>
    /// <returns>Owned selected track payloads, suitable for explicit workflow preparation.</returns>
    class function Get(const AProject: TCardProject; const AId: string): TMagStripeProjectSnapshot; static;
  end;

implementation

procedure Validate(const S: TMagStripeProjectSnapshot);
var T: TMagStripeTrack;
begin
  if S.Tracks=[] then raise ECardProjectError.Create('A track selection is required.');
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
    if T in S.Tracks then begin
      if S.Data[T]='' then raise ECardProjectError.Create('Selected track payload is empty.');
      TMagStripeTrackCodec.ValidatePayload(T,S.Data[T]);
    end else if S.Data[T]<>'' then raise ECardProjectError.Create('Unselected track payload is present.');
end;

class procedure TMagStripeProjectArtifacts.Put(const AProject: TCardProject; const AId: string;
  const ASnapshot: TMagStripeProjectSnapshot);
var Item: TCardProjectArtifact; T: TMagStripeTrack; I, N, P: Integer;
begin
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Validate(ASnapshot); Item := Default(TCardProjectArtifact);
  Item.Id := AId; Item.Profile := 'magstripe.v1'; N := 1;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do Inc(N,2+Length(ASnapshot.Data[T]));
  SetLength(Item.Data,N); Item.Data[0] := 0; P := 1;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do begin
    if T in ASnapshot.Tracks then Item.Data[0] := Item.Data[0] or (1 shl Ord(T));
    N := Length(ASnapshot.Data[T]); Item.Data[P] := Byte(N and $FF); Item.Data[P+1] := Byte(N shr 8); Inc(P,2);
    for I := 1 to N do begin Item.Data[P] := Byte(Ord(ASnapshot.Data[T][I])); Inc(P); end;
  end;
  AProject.Put(Item);
end;

class function TMagStripeProjectArtifacts.Get(const AProject: TCardProject;
  const AId: string): TMagStripeProjectSnapshot;
var Item: TCardProjectArtifact; T: TMagStripeTrack; I, N, P: Integer;
begin
  Result := Default(TMagStripeProjectSnapshot);
  if AProject=nil then raise ECardProjectError.Create('A project is required.');
  Item := AProject.Get(AId);
  if (Item.Profile<>'magstripe.v1') or (Length(Item.Data)<7) then
    raise ECardProjectError.Create('Unsupported track artifact.');
  if (Item.Data[0]<1) or (Item.Data[0]>7) then raise ECardProjectError.Create('Invalid track selection.');
  P := 1;
  for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do begin
    if (Item.Data[0] and (1 shl Ord(T)))<>0 then Include(Result.Tracks,T);
    if P+2>Length(Item.Data) then raise ECardProjectError.Create('Truncated track length.');
    N := Integer(Item.Data[P]) or (Integer(Item.Data[P+1]) shl 8); Inc(P,2);
    if (N>TMagStripeTrackCodec.MaxPayloadLength(T)) or (N>Length(Item.Data)-P) then raise ECardProjectError.Create('Invalid track length.');
    SetLength(Result.Data[T],N);
    for I := 1 to N do begin Result.Data[T][I] := Char(Item.Data[P]); Inc(P); end;
  end;
  if P<>Length(Item.Data) then raise ECardProjectError.Create('Trailing track artifact bytes.');
  Validate(Result);
end;

end.
