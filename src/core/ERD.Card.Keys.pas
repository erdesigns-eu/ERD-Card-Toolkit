unit ERD.Card.Keys;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes, System.SyncObjs,{$ENDIF}
  ERD.Card.Bytes;
type
  /// <summary>Explicit scoped key lookup; never discovers, guesses or serializes credentials.</summary>
  ICardKeyProvider = interface
    ['{B6A181E8-BB93-49CE-BDB9-E162233D8568}']
    /// <summary>Returns an independent key for an exact case-sensitive identifier and purpose.</summary>
    /// <param name="AId">Explicit key reference.</param>
    /// <param name="APurpose">Explicit protocol/use scope; another purpose is refused.</param>
    /// <returns>Owned secret bytes; caller clears them after configuring a workflow.</returns>
    function Resolve(const AId, APurpose: string): TBytes;
  end;
  /// <summary>Private owned scoped entry; not streamed by Delphi.</summary>
  TCardKeyEntry = record
    /// <summary>Case-sensitive bounded key identifier.</summary>
    Id: string;
    /// <summary>Case-sensitive bounded purpose identifier.</summary>
    Purpose: string;
    /// <summary>Owned bounded secret; copied on every provider boundary.</summary>
    Data: TBytes;
  end;
  /// <summary>Explicit scoped owned entry collection.</summary>
  TCardKeyEntries = array of TCardKeyEntry;
  /// <summary>Inactive in-memory key provider configuration with independent immutable snapshots for jobs.</summary>
  /// <remarks>Not a persistent vault. No keys enter project archives or DFM streaming. Owner-thread configuration;
  /// retain an immutable Snapshot for worker use. Copies are wiped at provider destruction; callers wipe resolved copies.</remarks>
  TCardKeyProvider = class(TComponent)
  private
    FEntries: TCardKeyEntries;
  public
    /// <summary>Clears all owned key buffers before component destruction.</summary>
    destructor Destroy; override;
    /// <summary>Copies an explicit key, replacing only the matching ID/purpose entry.</summary>
    /// <param name="AId">Valid ASCII identifier, one through 128 characters.</param>
    /// <param name="APurpose">Valid explicit ASCII protocol/use scope.</param>
    /// <param name="AKey">One through 4096 bytes; at most 256 entries.</param>
    procedure Put(const AId, APurpose: string; const AKey: TBytes);
    /// <summary>Removes and wipes one exact scoped entry; absent entries are harmless.</summary>
    /// <param name="AId">Exact key identifier.</param>
    /// <param name="APurpose">Exact purpose.</param>
    procedure Remove(const AId, APurpose: string);
    /// <summary>Clears every owned key without changing independent snapshots.</summary>
    procedure Clear;
    /// <summary>Creates an immutable independently owned provider safe for concurrent worker lookups.</summary>
    /// <returns>Retained snapshot surviving configuration changes and component destruction.</returns>
    function Snapshot: ICardKeyProvider;
  end;
implementation
uses ERD.Card.Crypto;
type
  TSnapshot = class(TInterfacedObject, ICardKeyProvider)
  public
    Entries: TCardKeyEntries;
    destructor Destroy; override;
    function Resolve(const AId, APurpose: string): TBytes;
  end;
procedure Validate(const Text: string);
var I: Integer;
begin
  if (Length(Text)<1) or (Length(Text)>128) then raise EArgumentException.Create('Invalid scoped key identifier.');
  for I := 1 to Length(Text) do if not CharInSet(Text[I],['A'..'Z','a'..'z','0'..'9','-','_','.']) then
    raise EArgumentException.Create('Invalid scoped key identifier.');
end;
destructor TSnapshot.Destroy;
var I: Integer;
begin
  for I := 0 to High(Entries) do TCardCrypto.Clear(Entries[I].Data);
  inherited Destroy;
end;
function TSnapshot.Resolve(const AId, APurpose: string): TBytes;
var I: Integer;
begin
  Validate(AId); Validate(APurpose);
  for I := 0 to High(Entries) do if (Entries[I].Id=AId) and (Entries[I].Purpose=APurpose) then
    Exit(CopyBytes(Entries[I].Data));
  raise EArgumentException.Create('Scoped key is unavailable.');
end;
destructor TCardKeyProvider.Destroy;
begin Clear; inherited Destroy; end;
procedure TCardKeyProvider.Put(const AId, APurpose: string; const AKey: TBytes);
var I,N: Integer; Data: TBytes;
begin
  Validate(AId); Validate(APurpose);
  if (Length(AKey)<1) or (Length(AKey)>4096) then raise EArgumentException.Create('Invalid key budget.');
  N := -1;
  for I := 0 to High(FEntries) do if (FEntries[I].Id=AId) and (FEntries[I].Purpose=APurpose) then N := I;
  if (N<0) and (Length(FEntries)>=256) then raise EArgumentException.Create('Key entry budget exceeded.');
  Data := CopyBytes(AKey);
  try
    if N<0 then begin N := Length(FEntries); SetLength(FEntries,N+1); end;
    TCardCrypto.Clear(FEntries[N].Data); FEntries[N].Id := AId; FEntries[N].Purpose := APurpose;
    FEntries[N].Data := Data; Data := nil;
  finally TCardCrypto.Clear(Data); end;
end;
procedure TCardKeyProvider.Remove(const AId, APurpose: string);
var I,J: Integer;
begin
  for I := 0 to High(FEntries) do if (FEntries[I].Id=AId) and (FEntries[I].Purpose=APurpose) then begin
    TCardCrypto.Clear(FEntries[I].Data);
    for J := I to High(FEntries)-1 do FEntries[J] := FEntries[J+1];
    SetLength(FEntries,Length(FEntries)-1); Exit;
  end;
end;
procedure TCardKeyProvider.Clear;
var I: Integer;
begin
  for I := 0 to High(FEntries) do TCardCrypto.Clear(FEntries[I].Data);
  FEntries := nil;
end;
function TCardKeyProvider.Snapshot: ICardKeyProvider;
var Provider: TSnapshot; I: Integer;
begin
  Provider := TSnapshot.Create; Result := Provider;
  SetLength(Provider.Entries,Length(FEntries));
  for I := 0 to High(FEntries) do begin
    Provider.Entries[I].Id := FEntries[I].Id; Provider.Entries[I].Purpose := FEntries[I].Purpose;
    Provider.Entries[I].Data := CopyBytes(FEntries[I].Data);
  end;
end;
end.
