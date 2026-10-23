unit ERD.Card.Project.Files;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Project, ERD.Card.Project.Secure;

type
  /// <summary>Filesystem persistence failure; card operations are never replayed.</summary>
  ECardProjectFileError = class(Exception);
  /// <summary>Nonvisual project file storage with exclusive sibling temporary files and atomic replacement.</summary>
  /// <remarks>Native Windows and FPC Linux. Saves flush content before replacement; Linux also syncs the directory.
  /// Network filesystem and power-loss guarantees depend on the filesystem. Use on one owner thread.
  /// Concurrent saves use last-replacement-wins semantics, not optimistic revision locking.</remarks>
  TCardProjectFileStore = class(TComponent)
  private
    FProtectedStore: TCardProtectedProjectStore;
    FLastSaveReplaced: Boolean;
    procedure SetProtectedStore(const Value: TCardProtectedProjectStore);
    procedure WriteProject(const AProject: TCardProject; const AFileName: string; const Protected: Boolean);
    procedure ReadProject(const AProject: TCardProject; const AFileName: string; const Protected: Boolean);
  protected
    /// <summary>Disconnects a destroyed protected-stream component before future I/O.</summary>
    /// <param name="AComponent">Component being removed.</param>
    /// <param name="Operation">Notification kind.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Saves through the selected protection policy, with no plaintext fallback.</summary>
    /// <param name="AProject">Initialized project; marked clean only after replacement and flush succeed.</param>
    /// <param name="AFileName">Destination; its parent directory must already exist.</param>
    procedure Save(const AProject: TCardProject; const AFileName: string);
    /// <summary>Authenticates and atomically imports one bounded protected project file.</summary>
    /// <param name="AProject">Destination project; unchanged on any validation failure.</param>
    /// <param name="AFileName">Existing protected file.</param>
    procedure Load(const AProject: TCardProject; const AFileName: string);
    /// <summary>Explicitly opts into unencrypted atomic filesystem storage.</summary>
    /// <param name="AProject">Initialized source project.</param>
    /// <param name="AFileName">Destination file.</param>
    procedure SavePlain(const AProject: TCardProject; const AFileName: string);
    /// <summary>Explicitly loads a strict unencrypted project archive.</summary>
    /// <param name="AProject">Destination project; unchanged on invalid input.</param>
    /// <param name="AFileName">Existing plain project file.</param>
    procedure LoadPlain(const AProject: TCardProject; const AFileName: string);
    /// <summary>True once the latest save replaced the destination, including a subsequent directory-sync failure.</summary>
    /// <remarks>Failure after replacement leaves the source Dirty; inspect the file before retrying.</remarks>
    property LastSaveReplaced: Boolean read FLastSaveReplaced;
  published
    /// <summary>Authenticated stream storage component used by Save/Load; nil refuses those methods.</summary>
    property ProtectedStore: TCardProtectedProjectStore read FProtectedStore write SetProtectedStore;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  {$IFDEF FPC}Windows{$ELSE}Winapi.Windows{$ENDIF}
{$ELSE}
  {$IFDEF FPC}{$IFDEF LINUX}BaseUnix, Unix{$ELSE}ERD.Card.Bytes{$ENDIF}{$ELSE}ERD.Card.Bytes{$ENDIF}
{$ENDIF};

function OpenNew(const Name: string): THandle;
begin
{$IFDEF MSWINDOWS}
  Result := CreateFile(PChar(Name),GENERIC_WRITE,0,nil,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,0);
  if Result=INVALID_HANDLE_VALUE then raise ECardProjectFileError.Create('Cannot create exclusive temporary project file.');
{$ELSE}
  {$IFDEF FPC}{$IFDEF LINUX}
  Result := fpOpen(PChar(Name),O_WRONLY or O_CREAT or O_EXCL,&600);
  if Result=THandle(-1) then raise ECardProjectFileError.Create('Cannot create exclusive temporary project file.');
  {$ELSE}Result := 0; raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}{$ELSE}Result := 0; raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}
{$ENDIF}
end;

procedure Flush(const Handle: THandle);
begin
{$IFDEF MSWINDOWS}
  if not FlushFileBuffers(Handle) then raise ECardProjectFileError.Create('Cannot flush project content.');
{$ELSE}
  {$IFDEF FPC}{$IFDEF LINUX}
  if fpFsync(Handle)<>0 then raise ECardProjectFileError.Create('Cannot flush project content.');
  {$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}{$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}
{$ENDIF}
end;

procedure CloseNativeFile(const Handle: THandle);
begin
{$IFDEF MSWINDOWS}
  if not CloseHandle(Handle) then raise ECardProjectFileError.Create('Cannot close project file handle.');
{$ELSE}
  {$IFDEF FPC}{$IFDEF LINUX}
  if fpClose(Handle)<>0 then raise ECardProjectFileError.Create('Cannot close project file handle.');
  {$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}
  {$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}
{$ENDIF}
end;

procedure ReplaceFile(const Source, Destination: string);
begin
{$IFDEF MSWINDOWS}
  if not MoveFileEx(PChar(Source),PChar(Destination),MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
    raise ECardProjectFileError.Create('Cannot replace project destination.');
{$ELSE}
  {$IFDEF FPC}{$IFDEF LINUX}
  if fpRename(PChar(Source),PChar(Destination))<>0 then
    raise ECardProjectFileError.Create('Cannot replace project destination.');
  {$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}{$ELSE}raise ECardProjectFileError.Create('Native atomic project storage is unavailable on this platform.');{$ENDIF}
{$ENDIF}
end;

procedure SyncDirectory(const Name: string);
{$IFDEF FPC}{$IFDEF LINUX}var Handle: THandle;{$ENDIF}{$ENDIF}
begin
{$IFDEF FPC}{$IFDEF LINUX}
  Handle := fpOpen(PChar(Name),O_RDONLY or O_DIRECTORY);
  if Handle=THandle(-1) then raise ECardProjectFileError.Create('Cannot open project directory for synchronization.');
  try
    if fpFsync(Handle)<>0 then raise ECardProjectFileError.Create('Cannot synchronize project directory.');
  finally CloseNativeFile(Handle); end;
{$ENDIF}{$ENDIF}
end;

procedure TCardProjectFileStore.SetProtectedStore(const Value: TCardProtectedProjectStore);
begin
  if (Value<>nil) and (csDestroying in Value.ComponentState) then
    raise ECardProjectFileError.Create('A live protected storage component is required.');
  if FProtectedStore<>nil then FProtectedStore.RemoveFreeNotification(Self);
  FProtectedStore := Value;
  if Value<>nil then Value.FreeNotification(Self);
end;

procedure TCardProjectFileStore.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation=opRemove) and (AComponent=FProtectedStore) then FProtectedStore := nil;
  inherited Notification(AComponent,Operation);
end;

procedure TCardProjectFileStore.WriteProject(const AProject: TCardProject;
  const AFileName: string; const Protected: Boolean);
var Snapshot: TCardProject; Data: TMemoryStream; Target, Temp, DirectoryName, Archive: string;
  Guid: TGUID; Handle: THandle; FileStream: THandleStream; Created: Boolean;
begin
  FLastSaveReplaced := False;
  if (AProject=nil) or (AFileName='') or (Pos(#0,AFileName)<>0) then
    raise ECardProjectFileError.Create('A project and destination file are required.');
  if Protected and (FProtectedStore=nil) then
    raise ECardProjectFileError.Create('Protected storage is required.');
  Target := ExpandFileName(AFileName); DirectoryName := ExtractFileDir(Target);
  Snapshot := TCardProject.Create(nil); Data := TMemoryStream.Create; Created := False;
  try
    Archive := AProject.ExportText; Snapshot.ImportText(Archive);
    if Protected then FProtectedStore.Save(Snapshot,Data) else Snapshot.SaveToStream(Data);
    if CreateGUID(Guid)<>0 then raise ECardProjectFileError.Create('Cannot create temporary project identifier.');
    Temp := IncludeTrailingPathDelimiter(DirectoryName)+'.erd-project-'+GUIDToString(Guid)+'.tmp';
    Handle := OpenNew(Temp); Created := True;
    try
      FileStream := THandleStream.Create(Handle);
      try
        Data.Position := 0; FileStream.CopyFrom(Data,Data.Size); Flush(Handle);
      finally FileStream.Free; end;
    finally CloseNativeFile(Handle); end;
    ReplaceFile(Temp,Target); FLastSaveReplaced := True; Created := False;
    SyncDirectory(DirectoryName);
    if AProject.ExportText=Archive then AProject.MarkSaved;
  finally
    if Created then DeleteFile(PChar(Temp));
    if Data.Size>0 then FillChar(Data.Memory^,NativeInt(Data.Size),0);
    Data.Free; Snapshot.Free;
  end;
end;

procedure TCardProjectFileStore.ReadProject(const AProject: TCardProject;
  const AFileName: string; const Protected: Boolean);
var Stream: TFileStream;
begin
  if (AProject=nil) or (AFileName='') or (Pos(#0,AFileName)<>0) then
    raise ECardProjectFileError.Create('A project and source file are required.');
  if Protected and (FProtectedStore=nil) then
    raise ECardProjectFileError.Create('Protected storage is required.');
  Stream := TFileStream.Create(AFileName,fmOpenRead or fmShareDenyWrite);
  try
    if Protected then FProtectedStore.Load(AProject,Stream) else AProject.LoadFromStream(Stream);
  finally Stream.Free; end;
end;

procedure TCardProjectFileStore.Save(const AProject: TCardProject; const AFileName: string);
begin WriteProject(AProject,AFileName,True); end;
procedure TCardProjectFileStore.Load(const AProject: TCardProject; const AFileName: string);
begin ReadProject(AProject,AFileName,True); end;
procedure TCardProjectFileStore.SavePlain(const AProject: TCardProject; const AFileName: string);
begin WriteProject(AProject,AFileName,False); end;
procedure TCardProjectFileStore.LoadPlain(const AProject: TCardProject; const AFileName: string);
begin ReadProject(AProject,AFileName,False); end;

end.
