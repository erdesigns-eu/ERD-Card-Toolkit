unit ERD.Card.Contactless.Workflow.UltralightC;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Crypto.DES,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.Workflow.Password;

/// <summary>Creates an owned Ultralight C 3DES user-memory backend without card I/O.</summary>
/// <param name="AReader">Inactive exclusive raw Type A reader retained by the adapter.</param>
/// <param name="AProvider">Maintained Triple DES/CSPRNG provider; never selected implicitly.</param>
/// <param name="AKey">Sixteen cryptographic-order K1/K2 bytes, independently copied.</param>
/// <param name="AExpectedUid">Optional seven-byte UID, otherwise pin first activation before authentication.</param>
/// <returns>Four-byte page adapter for TProtectedMemoryWorkflow with credential cleanup.</returns>
/// <remarks>Only pages 4..39; no UID, lock, counter, configuration or key backup.
/// Conservative static/dynamic user-lock preflight; every write uses native read-back verification.</remarks>
function CreateUltralightCWorkflowMemory(const AReader: IRawContactlessReader;
  const AProvider: ICardDesProvider; const AKey: TBytes;
  const AExpectedUid: TBytes = nil): ICardWorkflowMemory;

implementation

uses ERD.Card.Crypto, ERD.Card.Contactless, ERD.Card.Contactless.UltralightC;

type
  TUltralightMemory = class(TInterfacedObject, ICardWorkflowMemory,
    ICardWorkflowWritePreflight, ICardWorkflowCredentialCleanup)
  private
    FReader: TUltralightCCardReaderWriter;
    FRaw: IRawContactlessReader;
    FKey: TBytes;
    procedure Ready;
  public
    constructor Create(const AReader: IRawContactlessReader;
      const AProvider: ICardDesProvider; const AKey, AUid: TBytes);
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

constructor TUltralightMemory.Create(const AReader: IRawContactlessReader;
  const AProvider: ICardDesProvider; const AKey, AUid: TBytes);
begin
  inherited Create;
  if (AProvider = nil) or (Length(AKey) <> 16) then
    raise ECardWorkflowError.Create('Explicit Ultralight C crypto provider and key required.');
  FRaw := CreateType2WorkflowIdentityGuard(AReader, AUid);
  FReader := TUltralightCCardReaderWriter.Create(nil);
  FReader.Reader := FRaw;
  FReader.CryptoProvider := AProvider;
  FKey := CopyBytes(AKey);
end;

destructor TUltralightMemory.Destroy;
begin
  ClearCredentials;
  FReader.Free;
  inherited Destroy;
end;

procedure TUltralightMemory.ClearCredentials;
begin
  TCardCrypto.Clear(FKey);
end;

procedure TUltralightMemory.Ready;
begin
  if Length(FKey) <> 16 then
    raise ECardWorkflowError.Create('Ultralight C credentials consumed.');
end;

function TUltralightMemory.Layout: string;
begin
  Result := 'ULTRALIGHT-C';
end;

function TUltralightMemory.UnitSize: Integer;
begin
  Result := 4;
end;

procedure TUltralightMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  Ready;
  if (AAddress < 4) or (AAddress > 39) then
    raise ECardWorkflowError.Create('Only Ultralight C user pages are permitted.');
end;

function TUltralightMemory.ReadUid: TBytes;
var
  Success: Boolean;
begin
  Ready;
  FRaw.BeginSession;
  Success := False;
  try
    Result := FRaw.Activate;
    Success := True;
  finally
    if Success then FRaw.EndSession else try FRaw.EndSession; except end;
  end;
end;

function TUltralightMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  ValidateUnit(AAddress, False);
  Result := FReader.ReadUserPage(AAddress, FKey);
end;

procedure TUltralightMemory.CheckWritable(const AAddress: Integer);
begin
  ValidateUnit(AAddress, True);
  FReader.CheckUserMemoryWritable(FKey);
end;

procedure TUltralightMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  try
    ValidateUnit(AAddress, True);
    if Length(AData) <> 4 then raise ECardWorkflowError.Create('Four page bytes required.');
    FReader.CheckUserMemoryWritable(FKey);
    FReader.WriteUserPageVerified(AAddress, AData, FKey);
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;

function CreateUltralightCWorkflowMemory(const AReader: IRawContactlessReader;
  const AProvider: ICardDesProvider; const AKey, AExpectedUid: TBytes): ICardWorkflowMemory;
begin
  Result := TUltralightMemory.Create(AReader, AProvider, AKey, AExpectedUid);
end;

end.
