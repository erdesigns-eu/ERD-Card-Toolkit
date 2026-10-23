unit ERD.Card.Contactless.Plus.Workflow;

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
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Workflow, ERD.Card.Contactless.Plus,
  ERD.Card.Contactless, ERD.Card.Contactless.Plus.SL2;

type
  /// <summary>Application-owned Plus sector AES keys; never serialized into snapshots.</summary>
  IPlusWorkflowKeys = interface
    ['{0850C7C0-70A5-4E2A-B0DC-F92DB4C35E25}']
    /// <summary>Returns a temporary independent AES key for the requested ordinary block and direction.</summary>
    /// <param name="ABlock">Explicit ordinary physical block.</param>
    /// <param name="AWriting">True for preflight/write/verification credentials, false for source reads.</param>
    /// <param name="AKeyNumber">Explicit native sector key address 4000 through 404F, matching the block.</param>
    /// <returns>Exactly sixteen temporary secret bytes, wiped by the caller.</returns>
    function GetKey(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word): TBytes;
  end;

  /// <summary>Explicit temporary AES plus Classic sector credentials; never serialized into selected-memory archives.</summary>
  IPlusSl2WorkflowKeys = interface
    ['{76664FA4-6C09-4508-AF63-8245759C26B2}']
    /// <summary>Returns independently owned credentials for one ordinary source or target block.</summary>
    /// <param name="ABlock">Selected physical ordinary block.</param>
    /// <param name="AWriting">True for target preflight/write credentials.</param>
    /// <param name="AKeyNumber">Explicit native sector AES slot.</param>
    /// <param name="AKeyType">Explicit Classic A/B choice.</param>
    /// <param name="AClassicKey">Owned six-byte static Classic key, wiped after use.</param>
    /// <returns>Owned sixteen-byte AES key, wiped after use.</returns>
    function GetKeys(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word;
      out AKeyType: TMifareClassicKeyType; out AClassicKey: TBytes): TBytes;
  end;

/// <summary>Creates a selected ordinary-memory SL2 backup/compare/restore backend with pinned UID and live ACL checks.</summary>
/// <param name="ASession">Explicit native SL2 and reader Crypto1 backend.</param>
/// <param name="AProvider">Maintained AES/CSPRNG provider.</param>
/// <param name="AModel">Explicit 2K/4K geometry.</param>
/// <param name="AKeys">Retained scoped sector credential provider.</param>
/// <param name="AExpectedUid">Optional pinned four/seven-byte UID; first acquisition pins when omitted.</param>
/// <returns>Owned PLUS-SL2-ordinal sixteen-byte memory backend, excluding manufacturer/trailer and keys.</returns>
function CreatePlusSl2WorkflowMemory(const ASession: IMifarePlusSl2Session; const AProvider: ICardAesProvider;
  const AModel: TMifarePlusModel; const AKeys: IPlusSl2WorkflowKeys; const AExpectedUid: TBytes = nil): ICardWorkflowMemory;

/// <summary>Creates an owned Plus SL3 memory backend for backup/copy/compare/restore engines.</summary>
/// <param name="ASession">Retained native ISO14443-4 backend; exclusive ownership during workflow execution.</param>
/// <param name="AProvider">Explicit maintained AES/CSPRNG provider.</param>
/// <param name="AModel">Explicit 2K or 4K geometry.</param>
/// <param name="AKeys">Retained application-owned sector key provider; temporary keys are cleared after use.</param>
/// <param name="AExpectedUid">Optional exact four/seven/ten-byte UID; otherwise first acquisition pins identity.</param>
/// <returns>Owned Full-message sixteen-byte ordinary-memory backend with consumable credential cleanup.</returns>
/// <remarks>Compatible with TProtectedMemoryWorkflow. Archives use PLUS-SL3-ordinal layouts and exclude keys,
/// block zero and trailers. Cleanup drops the application provider reference; it cannot wipe caller-owned stored keys.</remarks>
function CreatePlusWorkflowMemory(const ASession: IMifarePlusSession; const AProvider: ICardAesProvider;
  const AModel: TMifarePlusModel; const AKeys: IPlusWorkflowKeys; const AExpectedUid: TBytes = nil): ICardWorkflowMemory;

implementation

uses ERD.Card.Contactless.Workflow.Password;

type
  TPlusMemory = class(TInterfacedObject,ICardWorkflowMemory,ICardWorkflowWritePreflight,ICardWorkflowCredentialCleanup)
  private
    FReader: TMifarePlusCardReaderWriter;
    FKeys: IPlusWorkflowKeys;
    FModel: TMifarePlusModel;
    FBefore: array of TBytes;
    FConsumed: Boolean;
    procedure Ready;
    procedure Credentials(const ABlock: Integer; const AWriting: Boolean);
  public
    constructor Create(const S: IMifarePlusSession; const P: ICardAesProvider;
      const M: TMifarePlusModel; const K: IPlusWorkflowKeys; const U: TBytes);
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
  TSl2Memory = class(TInterfacedObject,ICardWorkflowMemory,ICardWorkflowWritePreflight,ICardWorkflowCredentialCleanup)
  private
    FReader: TMifarePlusSl2ReaderWriter;
    FKeys: IPlusSl2WorkflowKeys;
    FModel: TMifarePlusModel;
    FBefore: array of TBytes;
    FConsumed: Boolean;
    procedure Ready;
    procedure Credentials(const ABlock: Integer; const AWriting: Boolean);
  public
    constructor Create(const S: IMifarePlusSl2Session; const P: ICardAesProvider;
      const M: TMifarePlusModel; const K: IPlusSl2WorkflowKeys; const U: TBytes);
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
constructor TPlusMemory.Create(const S: IMifarePlusSession; const P: ICardAesProvider;
  const M: TMifarePlusModel; const K: IPlusWorkflowKeys; const U: TBytes);
begin
  inherited Create;
  if (S=nil) or (P=nil) or (K=nil) then raise ECardWorkflowError.Create('Explicit Plus backend, crypto and keys required.');
  FReader:=TMifarePlusCardReaderWriter.Create(nil); FReader.Session:=S; FReader.CryptoProvider:=P;
  FReader.Model:=M; FReader.ExpectedUid:=U; FModel:=M; FKeys:=K;
  SetLength(FBefore,256); if M=mpm2K then SetLength(FBefore,128);
end;
destructor TPlusMemory.Destroy;
begin ClearCredentials; FReader.Free; inherited Destroy; end;
procedure TPlusMemory.ClearCredentials;
begin FConsumed:=True; FKeys:=nil; if FReader<>nil then FReader.Key:=nil; end;
procedure TPlusMemory.Ready;
begin if FConsumed then raise ECardWorkflowError.Create('Plus workflow backend consumed.'); end;
procedure TPlusMemory.Credentials(const ABlock: Integer; const AWriting: Boolean);
var Key: TBytes; N: Word;
begin
  Ready; if Length(FReader.ExpectedUid)=0 then ReadUid;
  N:=0; Key:=FKeys.GetKey(ABlock,AWriting,N);
  try FReader.KeyNumber:=N; FReader.Key:=Key; finally TCardCrypto.Clear(Key); end;
end;
function TPlusMemory.Layout: string;
begin Result:='PLUS-SL3-'+IntToStr(Ord(FModel)); end;
function TPlusMemory.UnitSize: Integer;
begin Result:=16; end;
procedure TPlusMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
var S: Integer;
begin Ready; S:=TMifarePlusCodec.DataSector(FModel,AAddress); if S<0 then raise ECardWorkflowError.Create('Invalid sector.'); end;
function TPlusMemory.ReadUid: TBytes;
begin Ready; Result:=FReader.ReadUid; FReader.ExpectedUid:=Result; end;
function TPlusMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  ValidateUnit(AAddress,False); Credentials(AAddress,False);
  try Result:=FReader.ReadBlocks(AAddress,1); FBefore[AAddress]:=CopyBytes(Result);
  finally FReader.Key:=nil; end;
end;
procedure TPlusMemory.CheckWritable(const AAddress: Integer);
var B: TBytes;
begin
  ValidateUnit(AAddress,True); if Length(FBefore[AAddress])<>16 then raise ECardWorkflowError.Create('Plus preimage required.');
  Credentials(AAddress,True);
  try B:=FReader.ReadBlocks(AAddress,1);
    if not BytesEqual(B,FBefore[AAddress]) then raise ECardWorkflowError.Create('Plus preimage changed.');
  finally FReader.Key:=nil; end;
end;
procedure TPlusMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  try
    ValidateUnit(AAddress,True); Credentials(AAddress,True);
    try FReader.WriteBlockVerified(AAddress,FBefore[AAddress],AData); finally FReader.Key:=nil; end;
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;
constructor TSl2Memory.Create(const S: IMifarePlusSl2Session; const P: ICardAesProvider;
  const M: TMifarePlusModel; const K: IPlusSl2WorkflowKeys; const U: TBytes);
begin
  inherited Create;
  if (S=nil) or (P=nil) or (K=nil) then raise ECardWorkflowError.Create('Explicit Plus backend, crypto and keys required.');
  FReader:=TMifarePlusSl2ReaderWriter.Create(nil); FReader.Session:=S; FReader.CryptoProvider:=P;
  FReader.Model:=M; FReader.ExpectedUid:=U; FModel:=M; FKeys:=K;
  SetLength(FBefore,256); if M=mpm2K then SetLength(FBefore,128);
end;
destructor TSl2Memory.Destroy;
begin ClearCredentials; FReader.Free; inherited Destroy; end;
procedure TSl2Memory.ClearCredentials;
begin FConsumed:=True; FKeys:=nil; if FReader<>nil then begin FReader.Key:=nil; FReader.ClassicKey:=nil; end; end;
procedure TSl2Memory.Ready;
begin if FConsumed then raise ECardWorkflowError.Create('Plus workflow backend consumed.'); end;
procedure TSl2Memory.Credentials(const ABlock: Integer; const AWriting: Boolean);
var Key,Classic: TBytes; N: Word; Kind: TMifareClassicKeyType;
begin
  Ready; if Length(FReader.ExpectedUid)=0 then ReadUid;
  N := 0; Kind := mckA;
  try
    Key := FKeys.GetKeys(ABlock,AWriting,N,Kind,Classic);
    FReader.KeyNumber := N; FReader.KeyType := Kind; FReader.Key := Key; FReader.ClassicKey := Classic;
  finally TCardCrypto.Clear(Key); TCardCrypto.Clear(Classic); end;
end;
function TSl2Memory.Layout: string;
begin Result:='PLUS-SL2-'+IntToStr(Ord(FModel)); end;
function TSl2Memory.UnitSize: Integer;
begin Result:=16; end;
procedure TSl2Memory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
var S: Integer;
begin Ready; S:=TMifarePlusCodec.DataSector(FModel,AAddress); if S<0 then raise ECardWorkflowError.Create('Invalid sector.'); end;
function TSl2Memory.ReadUid: TBytes;
begin Ready; Result:=FReader.ReadUid; FReader.ExpectedUid:=Result; end;
function TSl2Memory.ReadUnit(const AAddress: Integer): TBytes;
begin
  ValidateUnit(AAddress,False); Credentials(AAddress,False);
  try Result:=FReader.ReadBlock(AAddress); FBefore[AAddress]:=CopyBytes(Result);
  finally FReader.Key:=nil; FReader.ClassicKey:=nil; end;
end;
procedure TSl2Memory.CheckWritable(const AAddress: Integer);
var B: TBytes;
begin
  ValidateUnit(AAddress,True); if Length(FBefore[AAddress])<>16 then raise ECardWorkflowError.Create('Plus preimage required.');
  Credentials(AAddress,True);
  try B:=FReader.ReadBlock(AAddress);
    if not BytesEqual(B,FBefore[AAddress]) then raise ECardWorkflowError.Create('Plus preimage changed.');
  finally FReader.Key:=nil; FReader.ClassicKey:=nil; end;
end;
procedure TSl2Memory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  try
    ValidateUnit(AAddress,True); Credentials(AAddress,True);
    try FReader.WriteBlockVerified(AAddress,FBefore[AAddress],AData); finally FReader.Key:=nil; FReader.ClassicKey:=nil; end;
  except
    on E: EContactlessWriteUncertain do raise;
    on E: Exception do raise ECardWorkflowWriteRefused.Create(E.ClassName);
  end;
end;
function CreatePlusWorkflowMemory(const ASession: IMifarePlusSession; const AProvider: ICardAesProvider;
  const AModel: TMifarePlusModel; const AKeys: IPlusWorkflowKeys; const AExpectedUid: TBytes): ICardWorkflowMemory;
begin Result:=TPlusMemory.Create(ASession,AProvider,AModel,AKeys,AExpectedUid); end;

function CreatePlusSl2WorkflowMemory(const ASession: IMifarePlusSl2Session; const AProvider: ICardAesProvider;
  const AModel: TMifarePlusModel; const AKeys: IPlusSl2WorkflowKeys; const AExpectedUid: TBytes): ICardWorkflowMemory;
begin Result := TSl2Memory.Create(ASession,AProvider,AModel,AKeys,AExpectedUid); end;

end.
