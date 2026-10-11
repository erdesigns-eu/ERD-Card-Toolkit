unit ERD.Card.Contactless.Workflow;

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
  ERD.Card.Contactless.Type2;

type
  /// <summary>Application-owned sector credentials, obtained separately for source and target.</summary>
  IClassicWorkflowKeys = interface
    ['{FA2F2512-2C7C-4DD6-997D-5BE43464C1CA}']
    /// <summary>Returns a separate temporary six-byte key for the requested block operation.</summary>
    /// <param name="ABlock">Physical Classic block, identifying its sector.</param>
    /// <param name="AWriting">True for programming, false for reading or verification.</param>
    /// <param name="AKeyType">Selected Key A or Key B.</param>
    /// <returns>Independent six-byte key buffer; the adapter overwrites it after use.</returns>
    function GetKey(const ABlock: Integer; const AWriting: Boolean;
      out AKeyType: TMifareClassicKeyType): TBytes;
  end;
  /// <summary>Classic data-memory backend for copy, backup, compare and restore.</summary>
  /// <remarks>Reader must outlive this adapter. Manufacturer blocks and trailers are excluded:
  /// UID programming and credential changes are separate explicit operations.</remarks>
  TClassicWorkflowMemory = class(TInterfacedObject, ICardWorkflowMemory)
  private
    FReader: TContactlessCardReader;
    FModel: TMifareClassicModel;
    FKeys: IClassicWorkflowKeys;
  public
    /// <summary>Creates an adapter without hardware I/O.</summary>
    /// <param name="AReader">Configured reader retained by the caller.</param>
    /// <param name="AModel">Explicit Mini, 1K or 4K geometry.</param>
    /// <param name="AKeys">Application credential provider.</param>
    constructor Create(const AReader: TContactlessCardReader;
      const AModel: TMifareClassicModel; const AKeys: IClassicWorkflowKeys);
    /// <summary>Returns exact Classic geometry without I/O.</summary>
    /// <returns>Stable model identifier.</returns>
    function Layout: string;
    /// <summary>Rejects out-of-range, manufacturer and trailer blocks.</summary>
    /// <param name="AAddress">Physical block.</param>
    /// <param name="AWriting">Requested direction; both directions exclude credential fields.</param>
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    /// <summary>Returns Classic block width.</summary>
    /// <returns>Sixteen bytes.</returns>
    function UnitSize: Integer;
    /// <summary>Reads the current reader-visible UID.</summary>
    /// <returns>Independent UID bytes.</returns>
    function ReadUid: TBytes;
    /// <summary>Authenticates and reads one data block.</summary>
    /// <param name="AAddress">Permitted block.</param>
    /// <returns>Sixteen independent bytes.</returns>
    function ReadUnit(const AAddress: Integer): TBytes;
    /// <summary>Authenticates and dispatches one data-block write.</summary>
    /// <param name="AAddress">Permitted block.</param>
    /// <param name="AData">Exactly sixteen bytes.</param>
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
    /// <summary>Builds an ascending selection of every ordinary data block.</summary>
    /// <param name="AModel">Explicit Classic geometry.</param>
    /// <returns>All blocks except zero and sector trailers.</returns>
    class function DataAddresses(const AModel: TMifareClassicModel): TCardWorkflowAddresses; static;
  end;
  /// <summary>Ultralight/NTAG user-memory backend excluding UID, locks, passwords and configuration.</summary>
  /// <remarks>Reader must outlive the adapter; protected authentication requires a separate backend.</remarks>
  TType2WorkflowMemory = class(TInterfacedObject, ICardWorkflowMemory)
  private
    FReader: TContactlessCardReader;
    FModel: TType2TagModel;
  public
    /// <summary>Creates a user-page adapter without hardware I/O.</summary>
    /// <param name="AReader">Caller-owned configured reader.</param>
    /// <param name="AModel">Explicit supported Ultralight or NTAG model.</param>
    constructor Create(const AReader: TContactlessCardReader; const AModel: TType2TagModel);
    /// <summary>Returns the exact Type 2 model identifier.</summary>
    /// <returns>Stable model identifier.</returns>
    function Layout: string;
    /// <summary>Checks user-page bounds for either direction.</summary>
    /// <param name="AAddress">Physical page.</param>
    /// <param name="AWriting">Requested direction.</param>
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    /// <summary>Returns Type 2 page width.</summary>
    /// <returns>Four bytes.</returns>
    function UnitSize: Integer;
    /// <summary>Reads current UID.</summary>
    /// <returns>Independent UID bytes.</returns>
    function ReadUid: TBytes;
    /// <summary>Reads one permitted user page.</summary>
    /// <param name="AAddress">Physical page.</param>
    /// <returns>Four independent bytes.</returns>
    function ReadUnit(const AAddress: Integer): TBytes;
    /// <summary>Writes one permitted user page once.</summary>
    /// <param name="AAddress">Physical page.</param>
    /// <param name="AData">Exactly four bytes.</param>
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
    /// <summary>Builds the complete user-page selection.</summary>
    /// <param name="AModel">Explicit supported model.</param>
    /// <returns>Ascending permitted user pages.</returns>
    class function DataAddresses(const AModel: TType2TagModel): TCardWorkflowAddresses; static;
  end;
  /// <summary>Palette component for Classic data copy, backup, compare and restore.</summary>
  TMifareClassicCopyWorkflow = class(TCardMemoryCopyWorkflow)
  end;
  /// <summary>Palette component for Type 2 user-memory copy, backup, compare and restore.</summary>
  TType2MemoryWorkflow = class(TCardMemoryCopyWorkflow)
  end;

implementation

procedure Wipe(var AKey: TBytes);
var I: Integer;
begin
  for I := 0 to High(AKey) do AKey[I] := 0;
  AKey := nil;
end;

constructor TClassicWorkflowMemory.Create(const AReader: TContactlessCardReader;
  const AModel: TMifareClassicModel; const AKeys: IClassicWorkflowKeys);
begin
  inherited Create;
  if (AReader = nil) or (AKeys = nil) then
    raise ECardWorkflowError.Create('Reader and sector key provider required.');
  TMifareClassicLayout.BlockCount(AModel);
  FReader := AReader;
  FModel := AModel;
  FKeys := AKeys;
end;

function TClassicWorkflowMemory.Layout: string;
begin
  Result := 'MIFARE-CLASSIC-' + IntToStr(Ord(FModel));
end;

procedure TClassicWorkflowMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  if (AAddress < 1) or (AAddress >= TMifareClassicLayout.BlockCount(FModel)) or
    TMifareClassicLayout.IsTrailer(FModel, AAddress) then
    raise ECardWorkflowError.Create('Only ordinary Classic data blocks are copyable.');
end;

function TClassicWorkflowMemory.UnitSize: Integer;
begin
  Result := 16;
end;

function TClassicWorkflowMemory.ReadUid: TBytes;
begin
  Result := FReader.ReadUid;
end;

function TClassicWorkflowMemory.ReadUnit(const AAddress: Integer): TBytes;
var Key: TBytes; Kind: TMifareClassicKeyType;
begin
  ValidateUnit(AAddress, False);
  Key := FKeys.GetKey(AAddress, False, Kind);
  try
    Result := FReader.ReadClassicBlock(FModel, AAddress, Kind, Key);
  finally
    Wipe(Key);
  end;
end;

procedure TClassicWorkflowMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
var Key: TBytes; Kind: TMifareClassicKeyType;
begin
  ValidateUnit(AAddress, True);
  Key := FKeys.GetKey(AAddress, True, Kind);
  try
    FReader.WriteClassicDataBlock(FModel, AAddress, Kind, Key, AData);
  finally
    Wipe(Key);
  end;
end;

class function TClassicWorkflowMemory.DataAddresses(const AModel: TMifareClassicModel): TCardWorkflowAddresses;
var I, N: Integer;
begin
  Result := nil;
  SetLength(Result, TMifareClassicLayout.BlockCount(AModel));
  N := 0;
  for I := 1 to TMifareClassicLayout.BlockCount(AModel) - 1 do
    if not TMifareClassicLayout.IsTrailer(AModel, I) then
    begin
      Result[N] := I;
      Inc(N);
    end;
  SetLength(Result, N);
end;

constructor TType2WorkflowMemory.Create(const AReader: TContactlessCardReader; const AModel: TType2TagModel);
begin
  inherited Create;
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  TType2Layout.PageCount(AModel);
  FReader := AReader;
  FModel := AModel;
end;

function TType2WorkflowMemory.Layout: string;
begin
  Result := 'TYPE2-' + IntToStr(Ord(FModel));
end;

procedure TType2WorkflowMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  if (AAddress < Type2FirstUserPage) or (AAddress > TType2Layout.LastUserPage(FModel)) then
    raise ECardWorkflowError.Create('Only Type 2 user pages are copyable.');
end;

function TType2WorkflowMemory.UnitSize: Integer;
begin
  Result := 4;
end;

function TType2WorkflowMemory.ReadUid: TBytes;
begin
  Result := FReader.ReadUid;
end;

function TType2WorkflowMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  ValidateUnit(AAddress, False);
  Result := FReader.ReadType2Page(FModel, AAddress);
end;

procedure TType2WorkflowMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  ValidateUnit(AAddress, True);
  FReader.WriteType2UserPage(FModel, AAddress, AData);
end;

class function TType2WorkflowMemory.DataAddresses(const AModel: TType2TagModel): TCardWorkflowAddresses;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, TType2Layout.LastUserPage(AModel) - Type2FirstUserPage + 1);
  for I := 0 to High(Result) do Result[I] := Type2FirstUserPage + I;
end;

end.
