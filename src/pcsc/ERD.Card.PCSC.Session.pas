unit ERD.Card.PCSC.Session;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.PCSC.Api, ERD.Card.Session;

type
  /// <summary>Inactive nonvisual factory configuration for worker-owned PC/SC connections.</summary>
  /// <remarks>Registration copies configuration. Each lease opens once and disconnects with Leave.
  /// No reset/reconnect/authentication/commit is inferred. Connect failure removes the registration.</remarks>
  TCardPcscSessionProvider = class(TComponent)
  private
    FApi: IPcscApi;
    FReaderName: UnicodeString;
    FProtocols: Cardinal;
    FShareMode: TPcscShareMode;
  public
    /// <summary>Creates inactive system-PC/SC configuration.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Creates inactive configuration with an injected thread-safe adapter.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    /// <param name="AApi">Non-nil PC/SC adapter retained by registered factories.</param>
    constructor CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
    /// <summary>Registers a copied lazy connection on the given session manager.</summary>
    /// <param name="AManager">Non-nil manager; binding does not access hardware.</param>
    /// <param name="AReaderId">Stable physical-reader identity, matching event invalidation IDs.</param>
    /// <remarks>Later property changes/destruction do not affect already registered configuration.</remarks>
    procedure RegisterReader(const AManager: TCardSessionManager; const AReaderId: string);
  published
    /// <summary>Exact Unicode system reader name; never selected by index or guessed.</summary>
    property ReaderName: UnicodeString read FReaderName write FReaderName;
    /// <summary>Requested T=0/T=1 protocol mask, 1, 2 or 3.</summary>
    property Protocols: Cardinal read FProtocols write FProtocols default 3;
    /// <summary>Explicit shared or exclusive native connection mode.</summary>
    property ShareMode: TPcscShareMode read FShareMode write FShareMode default psmShared;
  end;

implementation

uses ERD.Card.Transport, ERD.Card.PCSC.Reader;

type
  TPcscSessionConnection = class(TInterfacedObject, ICardSessionConnection)
  private
    FApi: IPcscApi;
    FName: UnicodeString;
    FProtocols: Cardinal;
    FShareMode: TPcscShareMode;
    FReader: TSmartCardReader;
    FThread: NativeUInt;
  public
    constructor Create(const Api: IPcscApi; const Name: UnicodeString;
      const Protocols: Cardinal; const ShareMode: TPcscShareMode);
    destructor Destroy; override;
    function Open: ICardTransport;
    procedure Close;
  end;

constructor TPcscSessionConnection.Create(const Api: IPcscApi; const Name: UnicodeString;
  const Protocols: Cardinal; const ShareMode: TPcscShareMode);
begin
  inherited Create; FApi := Api; FName := Name; FProtocols := Protocols; FShareMode := ShareMode;
end;

destructor TPcscSessionConnection.Destroy;
begin
  FReader.Free; inherited Destroy;
end;

function TPcscSessionConnection.Open: ICardTransport;
begin
  Result := nil;
  if FReader<>nil then raise ECardSessionError.Create('PC/SC connection is already open.');
  FThread := NativeUInt(TThread.CurrentThread.ThreadID);
  if FApi=nil then FReader := TSmartCardReader.Create(nil)
  else FReader := TSmartCardReader.CreateWithApi(nil,FApi);
  try
    FReader.ReaderName := FName; FReader.Protocols := FProtocols; FReader.ShareMode := FShareMode;
    FReader.Connect; Result := FReader.Transport;
  except FReader.Free; FReader := nil; raise; end;
end;

procedure TPcscSessionConnection.Close;
begin
  if FReader=nil then Exit;
  if NativeUInt(TThread.CurrentThread.ThreadID)<>FThread then
    raise ECardSessionError.Create('PC/SC connection belongs to its lease thread.');
  try FReader.Disconnect(pcdLeave);
  finally FReader.Free; FReader := nil; end;
end;

constructor TCardPcscSessionProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FProtocols := 3; FShareMode := psmShared;
end;

constructor TCardPcscSessionProvider.CreateWithApi(AOwner: TComponent; const AApi: IPcscApi);
begin
  Create(AOwner); if AApi=nil then raise ECardSessionError.Create('A PC/SC adapter is required.'); FApi := AApi;
end;

procedure TCardPcscSessionProvider.RegisterReader(const AManager: TCardSessionManager; const AReaderId: string);
var Connection: ICardSessionConnection;
begin
  if (AManager=nil) or (Length(FReaderName)<1) or (Length(FReaderName)>1024) or
    (Pos(#0,FReaderName)<>0) or not (FProtocols in [1,2,3]) or
    not (FShareMode in [psmShared,psmExclusive]) then
    raise ECardSessionError.Create('Explicit valid PC/SC configuration is required.');
  Connection := TPcscSessionConnection.Create(FApi,FReaderName,FProtocols,FShareMode);
  AManager.BindConnection(AReaderId,Connection);
end;

end.
