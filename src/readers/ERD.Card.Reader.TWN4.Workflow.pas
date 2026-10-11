unit ERD.Card.Reader.TWN4.Workflow;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Reader.TWN4,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Workflow, ERD.Card.Contactless.Workflow.Password;

type
  /// <summary>Explicit hardware-free firmware sector map for Classic 4K high sectors.</summary>
  ITwn4WorkflowSectors = interface
    ['{03CF5DAA-05A3-4F2D-A96B-8F64C6C5C6BD}']
    /// <summary>Returns firmware-defined sector byte; copied for every block during construction.</summary>
    /// <param name="ABlock">Physical block 128..255; no card I/O is permitted.</param>
    /// <returns>Explicit documented sector encoding, never inferred.</returns>
    function ReaderSector(const ABlock: Integer): Byte;
  end;

/// <summary>Creates an owned TWN4 Classic data-memory backend compatible with existing snapshots.</summary>
/// <param name="AReader">Inactive configured reader; channel/CRC/deadline are frozen, source may be freed.</param>
/// <param name="AModel">Explicit Mini/1K/4K geometry.</param>
/// <param name="AKeys">Retained application provider returning temporary independent sector keys.</param>
/// <param name="ASectors">Required for 4K; hardware-free high-block firmware mapping.</param>
/// <param name="AExpectedId">Optional exact 4/7/10-byte reader-order ID, else pin first acquisition.</param>
/// <returns>Owned sixteen-byte ordinary data backend; excludes block zero and trailers.</returns>
/// <remarks>Live write-key read/preimage preflight precedes any copy write. No keys in archives;
/// native writes compare the acquired preimage and verify before RF-off/close. Provider keys remain caller-owned.</remarks>
function CreateTwn4ClassicWorkflowMemory(const AReader: TTwn4CardReaderWriter;
  const AModel: TMifareClassicModel; const AKeys: IClassicWorkflowKeys;
  const ASectors: ITwn4WorkflowSectors = nil; const AExpectedId: TBytes = nil): ICardWorkflowMemory;

/// <summary>Creates an owned public TWN4 Type 2 backend compatible with existing model snapshots.</summary>
/// <param name="AReader">Inactive configured reader; source component may be freed after construction.</param>
/// <param name="AModel">Explicit public Ultralight/EV1/NTAG geometry.</param>
/// <param name="AExpectedId">Optional seven-byte ID, else pin first acquisition.</param>
/// <returns>Owned four-byte user-page backend; no password, UID or configuration programming.</returns>
/// <remarks>Reads all originals before copy and rechecks each native preimage before writing.
/// TWN4 has no lock-status query in this profile; no full-lock preflight is claimed.</remarks>
function CreateTwn4Type2WorkflowMemory(const AReader: TTwn4CardReaderWriter;
  const AModel: TType2TagModel; const AExpectedId: TBytes = nil): ICardWorkflowMemory;

implementation

uses ERD.Card.Crypto;

type
  TTwnMemory = class(TInterfacedObject, ICardWorkflowMemory,
    ICardWorkflowWritePreflight, ICardWorkflowCredentialCleanup)
  private
    FReader: TTwn4CardReaderWriter;
    FClassic: Boolean;
    FClassicModel: TMifareClassicModel;
    FType2Model: TType2TagModel;
    FKeys: IClassicWorkflowKeys;
    FId: TBytes;
    FBefore: array of TBytes;
    FSectors: array of Byte;
    FCleared: Boolean;
    procedure Ready;
    function ReadNative(const AAddress: Integer; const AWriting: Boolean): TBytes;
  public
    constructor Create(const AReader: TTwn4CardReaderWriter; const AClassic: Boolean;
      const AModel: Integer; const AKeys: IClassicWorkflowKeys;
      const ASectors: ITwn4WorkflowSectors; const AId: TBytes);
    destructor Destroy; override;
    procedure ClearCredentials;
    function Layout: string;
    function UnitSize: Integer;
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    function ReadUid: TBytes;
    function ReadUnit(const AAddress: Integer): TBytes;
    procedure CheckWritable(const AAddress: Integer);
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
  end;

constructor TTwnMemory.Create(const AReader: TTwn4CardReaderWriter; const AClassic: Boolean;
  const AModel: Integer; const AKeys: IClassicWorkflowKeys;
  const ASectors: ITwn4WorkflowSectors; const AId: TBytes);
var
  I, Count: Integer;
begin
  inherited Create;
  if (AReader = nil) or (AReader.Channel = nil) then
    raise ECardWorkflowError.Create('Explicit inactive TWN4 channel required.');
  FClassic := AClassic;
  if AClassic then
  begin
    if not (AModel in [0..2]) or (AKeys = nil) or
      ((Length(AId) <> 0) and not (Length(AId) in [4, 7, 10])) then
      raise ECardWorkflowError.Create('Explicit Classic geometry, keys and identity required.');
    FClassicModel := TMifareClassicModel(AModel);
    Count := TMifareClassicLayout.BlockCount(FClassicModel);
    if (Count > 128) and (ASectors = nil) then
      raise ECardWorkflowError.Create('Explicit TWN4 4K firmware sector map required.');
    SetLength(FSectors, Count);
    for I := 0 to Count - 1 do
      if I < 128 then FSectors[I] := Byte(I div 4) else FSectors[I] := ASectors.ReaderSector(I);
    FKeys := AKeys;
  end
  else
  begin
    if (AModel < 0) or (AModel > Ord(High(TType2TagModel))) or
      ((Length(AId) <> 0) and (Length(AId) <> 7)) then
      raise ECardWorkflowError.Create('Explicit Type 2 model and seven-byte identity required.');
    FType2Model := TType2TagModel(AModel);
    Count := TType2Layout.PageCount(FType2Model);
  end;
  FReader := TTwn4CardReaderWriter.Create(nil);
  FReader.Channel := AReader.Channel;
  FReader.UseCrc := AReader.UseCrc;
  FReader.TimeoutMs := AReader.TimeoutMs;
  FId := CopyBytes(AId);
  SetLength(FBefore, Count);
end;

destructor TTwnMemory.Destroy;
begin
  ClearCredentials;
  FReader.Free;
  inherited Destroy;
end;

procedure TTwnMemory.ClearCredentials;
begin
  FKeys := nil;
  FCleared := True;
end;

procedure TTwnMemory.Ready;
begin
  if FCleared then raise ECardWorkflowError.Create('TWN4 workflow backend consumed.');
end;

function TTwnMemory.Layout: string;
begin
  if FClassic then Result := 'MIFARE-CLASSIC-' + IntToStr(Ord(FClassicModel))
  else Result := 'TYPE2-' + IntToStr(Ord(FType2Model));
end;

function TTwnMemory.UnitSize: Integer;
begin
  if FClassic then Result := 16 else Result := 4;
end;

procedure TTwnMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  Ready;
  if FClassic then
  begin
    if (AAddress < 1) or (AAddress >= Length(FBefore)) or
      TMifareClassicLayout.IsTrailer(FClassicModel, AAddress) then
      raise ECardWorkflowError.Create('Only ordinary Classic data blocks allowed.');
  end
  else if (AAddress < 4) or (AAddress > TType2Layout.LastUserPage(FType2Model)) then
    raise ECardWorkflowError.Create('Only public Type 2 user pages allowed.');
end;

function TTwnMemory.ReadUid: TBytes;
var
  Tag: TTwn4TagInfo;
begin
  Ready;
  Tag := FReader.ReadTag;
  if not Tag.Found or (Tag.TagType <> $80) or (Tag.IdBitCount <> Length(Tag.Id) * 8) or
    (FClassic and not (Length(Tag.Id) in [4, 7, 10])) or
    (not FClassic and (Length(Tag.Id) <> 7)) or
    ((Length(FId) > 0) and not BytesEqual(Tag.Id, FId)) then
    raise ECardWorkflowError.Create('TWN4 identity changed or wrong family.');
  if Length(FId) = 0 then FId := CopyBytes(Tag.Id);
  Result := CopyBytes(Tag.Id);
end;

function TTwnMemory.ReadNative(const AAddress: Integer; const AWriting: Boolean): TBytes;
var
  Key: TBytes;
  Kind: TMifareClassicKeyType;
begin
  if Length(FId) = 0 then ReadUid;
  if not FClassic then Result := FReader.ReadType2UserPage(FType2Model, AAddress, FId)
  else
  begin
    Key := FKeys.GetKey(AAddress, AWriting, Kind);
    try
      Result := FReader.ReadClassicBlock(FClassicModel, AAddress, FSectors[AAddress], Kind, Key, FId);
    finally
      TCardCrypto.Clear(Key);
    end;
  end;
end;

function TTwnMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  ValidateUnit(AAddress, False);
  Result := ReadNative(AAddress, False);
  FBefore[AAddress] := CopyBytes(Result);
end;

procedure TTwnMemory.CheckWritable(const AAddress: Integer);
begin
  ValidateUnit(AAddress, True);
  if (Length(FBefore[AAddress]) <> UnitSize) or
    not BytesEqual(ReadNative(AAddress, True), FBefore[AAddress]) then
    raise ECardWorkflowError.Create('TWN4 target preimage changed.');
end;

procedure TTwnMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
var
  Key: TBytes;
  Kind: TMifareClassicKeyType;
begin
  try
    ValidateUnit(AAddress, True);
    if (Length(AData) <> UnitSize) or (Length(FBefore[AAddress]) <> UnitSize) then
      raise ECardWorkflowError.Create('Acquire exact TWN4 preimage before writing.');
    if FClassic then
    begin
      Key := FKeys.GetKey(AAddress, True, Kind);
      try
        FReader.WriteClassicDataBlock(FClassicModel, AAddress, FSectors[AAddress], Kind,
          Key, FId, FBefore[AAddress], AData);
      finally
        TCardCrypto.Clear(Key);
      end;
    end
    else FReader.WriteType2UserPage(FType2Model, AAddress, FId, FBefore[AAddress], AData);
  except
    on E: ETwn4WriteUncertain do raise EContactlessWriteUncertain.Create(E.ClassName);
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;

function CreateTwn4ClassicWorkflowMemory(const AReader: TTwn4CardReaderWriter;
  const AModel: TMifareClassicModel; const AKeys: IClassicWorkflowKeys;
  const ASectors: ITwn4WorkflowSectors; const AExpectedId: TBytes): ICardWorkflowMemory;
begin
  Result := TTwnMemory.Create(AReader, True, Ord(AModel), AKeys, ASectors, AExpectedId);
end;

function CreateTwn4Type2WorkflowMemory(const AReader: TTwn4CardReaderWriter;
  const AModel: TType2TagModel; const AExpectedId: TBytes): ICardWorkflowMemory;
begin
  Result := TTwnMemory.Create(AReader, False, Ord(AModel), nil, nil, AExpectedId);
end;

end.
