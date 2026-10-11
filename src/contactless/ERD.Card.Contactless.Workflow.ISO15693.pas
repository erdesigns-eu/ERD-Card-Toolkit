unit ERD.Card.Contactless.Workflow.ISO15693;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Contactless,
  ERD.Card.Contactless.ISO15693;

type
  /// <summary>Addressed ISO15693 memory backend with exact geometry and live lock preflight.</summary>
  /// <remarks>The supplied session may already implement password authentication. It must be
  /// exclusively controlled by the executing application. Geometry is explicit and constructor
  /// performs no I/O. First ReadUid pins the observed UID; each subsequent session checks it.
  /// Blocks zero and one are excluded from writes to preserve possible Type5 capability data.
  /// Does not copy UID, passwords, AFI, DSFID, locks or vendor configuration. Every dispatched
  /// write is verified before release; failure after dispatch is uncertain and never retried.</remarks>
  TIso15693WorkflowMemory = class(TInterfacedObject, ICardWorkflowMemory,
    ICardWorkflowWritePreflight)
  private
    FSession: IIso15693Session;
    FBlockCount, FBlockSize: Integer;
    FUid: TBytes;
    function Acquire: TIso15693SystemInfo;
    procedure Release(const ASucceeded: Boolean);
  public
    /// <summary>Creates a no-I/O memory adapter with explicit expected geometry.</summary>
    /// <param name="ASession">Retained addressed session, including optional authenticated wrapper.</param>
    /// <param name="ABlockCount">One through 65536 blocks, within ISO memory byte limit.</param>
    /// <param name="ABlockSize">One through 32 bytes per block.</param>
    constructor Create(const ASession: IIso15693Session;
      const ABlockCount, ABlockSize: Integer);
    /// <summary>Returns the exact ISO15693 geometry identifier without I/O.</summary>
    /// <returns>Stable layout identifier shared by compatible geometry.</returns>
    function Layout: string;
    /// <summary>Checks bounds and reserved write addresses without I/O.</summary>
    /// <param name="AAddress">Physical block number.</param>
    /// <param name="AWriting">True rejects blocks zero and one.</param>
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    /// <summary>Returns the explicit block byte width.</summary>
    /// <returns>Configured block size.</returns>
    function UnitSize: Integer;
    /// <summary>Reads and pins card UID, checking configured geometry and previous identity.</summary>
    /// <returns>Independent canonical eight-byte UID.</returns>
    function ReadUid: TBytes;
    /// <summary>Reads one complete block under a fresh addressed session.</summary>
    /// <param name="AAddress">Readable physical block.</param>
    /// <returns>Independent complete block bytes.</returns>
    function ReadUnit(const AAddress: Integer): TBytes;
    /// <summary>Checks a differing target block's live security status before the write phase.</summary>
    /// <param name="AAddress">Writable physical block.</param>
    procedure CheckWritable(const AAddress: Integer);
    /// <summary>Writes once and independently verifies within one retained session.</summary>
    /// <param name="AAddress">Writable physical block.</param>
    /// <param name="AData">Exact full block bytes.</param>
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
    /// <summary>Builds one bounded selection, allowing large memories to be processed in windows.</summary>
    /// <param name="AFirstBlock">First selected block; at least two for writable selections.</param>
    /// <param name="ACount">One through 4096 blocks within configured geometry.</param>
    /// <param name="AWriting">True protects reserved blocks zero and one.</param>
    /// <returns>Ascending physical block addresses.</returns>
    function Addresses(const AFirstBlock, ACount: Integer;
      const AWriting: Boolean = True): TCardWorkflowAddresses;
  end;
  /// <summary>Palette component for selected ISO15693 backup, comparison and verified restore.</summary>
  TIso15693MemoryWorkflow = class(TCardMemoryCopyWorkflow)
  end;

implementation

constructor TIso15693WorkflowMemory.Create(const ASession: IIso15693Session;
  const ABlockCount, ABlockSize: Integer);
begin
  inherited Create;
  if (ASession = nil) or (ABlockCount < 1) or (ABlockCount > 65536) or
    (ABlockSize < 1) or (ABlockSize > 32) or
    (Int64(ABlockCount) * ABlockSize > Iso15693MaxMemoryBytes) then
    raise ECardWorkflowError.Create('Invalid ISO15693 session or geometry.');
  FSession := ASession; FBlockCount := ABlockCount; FBlockSize := ABlockSize;
end;

function TIso15693WorkflowMemory.Layout: string;
begin
  Result := 'ISO15693-' + IntToStr(FBlockCount) + 'x' + IntToStr(FBlockSize);
end;

function TIso15693WorkflowMemory.UnitSize: Integer;
begin
  Result := FBlockSize;
end;

procedure TIso15693WorkflowMemory.ValidateUnit(const AAddress: Integer;
  const AWriting: Boolean);
begin
  if (AAddress < 0) or (AAddress >= FBlockCount) or
    (AWriting and (AAddress < 2)) then
    raise ECardWorkflowError.Create('Invalid or reserved ISO15693 block.');
end;

function TIso15693WorkflowMemory.Acquire: TIso15693SystemInfo;
begin
  Result := FSession.BeginSession;
  try
    TIso15693Codec.ValidateInfo(Result);
    if (Result.BlockCount <> FBlockCount) or (Result.BlockSize <> FBlockSize) or
      ((Length(FUid) > 0) and not BytesEqual(Result.Uid, FUid)) then
      raise ECardWorkflowError.Create('ISO15693 geometry or card identity changed.');
  except
    try FSession.EndSession; except end;
    raise;
  end;
end;

procedure TIso15693WorkflowMemory.Release(const ASucceeded: Boolean);
begin
  if ASucceeded then FSession.EndSession
  else try FSession.EndSession; except end;
end;

function TIso15693WorkflowMemory.ReadUid: TBytes;
var Info: TIso15693SystemInfo; Success: Boolean;
begin
  Info := Acquire; Success := False;
  try
    Result := CopyBytes(Info.Uid); Success := True;
  finally Release(Success); end;
  if Length(FUid) = 0 then FUid := CopyBytes(Result);
end;

function TIso15693WorkflowMemory.ReadUnit(const AAddress: Integer): TBytes;
var Success: Boolean;
begin
  ValidateUnit(AAddress, False);
  Acquire; Success := False;
  try
    Result := CopyBytes(FSession.ReadBlock(AAddress));
    if Length(Result) <> FBlockSize then
      raise ECardWorkflowError.Create('Incomplete ISO15693 block.');
    Success := True;
  finally Release(Success); end;
end;

procedure TIso15693WorkflowMemory.CheckWritable(const AAddress: Integer);
var Success: Boolean;
begin
  ValidateUnit(AAddress, True);
  Acquire; Success := False;
  try
    if FSession.SecurityStatus(AAddress) <> 0 then
      raise ECardWorkflowError.Create('ISO15693 block locked or protection unsupported.');
    Success := True;
  finally Release(Success); end;
end;

procedure TIso15693WorkflowMemory.WriteUnit(const AAddress: Integer;
  const AData: TBytes);
var Success, Dispatched: Boolean; Data: TBytes;
begin
  ValidateUnit(AAddress, True);
  if Length(AData) <> FBlockSize then
    raise ECardWorkflowError.Create('Invalid ISO15693 block width.');
  Data := CopyBytes(AData); Dispatched := False;
  try
    Acquire; Success := False;
    try
      if FSession.SecurityStatus(AAddress) <> 0 then
        raise ECardWorkflowError.Create('ISO15693 block became locked.');
      Dispatched := True;
      FSession.WriteBlock(AAddress, Data);
      if not BytesEqual(FSession.ReadBlock(AAddress), Data) then
        raise ECardWorkflowError.Create('ISO15693 read-back mismatch.');
      Success := True;
    finally Release(Success); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

function TIso15693WorkflowMemory.Addresses(const AFirstBlock, ACount: Integer;
  const AWriting: Boolean): TCardWorkflowAddresses;
var I: Integer;
begin
  if (ACount < 1) or (ACount > 4096) or (AFirstBlock < 0) or
    (AFirstBlock >= FBlockCount) or (ACount > FBlockCount - AFirstBlock) then
    raise ECardWorkflowError.Create('Invalid ISO15693 selection window.');
  ValidateUnit(AFirstBlock, AWriting);
  Result := nil; SetLength(Result, ACount);
  for I := 0 to ACount - 1 do Result[I] := AFirstBlock + I;
end;

end.
