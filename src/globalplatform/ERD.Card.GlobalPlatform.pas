unit ERD.Card.GlobalPlatform;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Transport, ERD.Card.TLV,
  ERD.Card.Crypto, ERD.Card.Crypto.DES,
  ERD.Card.GlobalPlatform.SecureChannel, ERD.Card.GlobalPlatform.CAP,
  ERD.Card.GlobalPlatform.Management;

type
  /// <summary>Invalid GP metadata, lifecycle, bounds or returned card status.</summary>
  EGpCardError = class(Exception)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a card-status failure with no command or response data.</summary>
    /// <param name="AStatusWord">Returned SW1/SW2; zero is reserved for local failures.</param>
    constructor CreateStatus(const AStatusWord: Word);

    /// <summary>Returned card status, or zero for local format/crypto/state failures.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>GET STATUS object category; no automatic discovery of other categories.</summary>
  TGpRegistryKind = (
    /// <summary>Issuer security domain, GET STATUS P1=80.</summary>
    grkIssuerDomain,
    /// <summary>Applications and supplementary security domains, P1=40.</summary>
    grkApplications,
    /// <summary>Executable load files, P1=20.</summary>
    grkLoadFiles,
    /// <summary>Executable load files and module identities, P1=10.</summary>
    grkLoadFilesAndModules);

  /// <summary>Owned registry entry, retaining unknown fields and executable-module identities.</summary>
  TGpRegistryEntry = record
    /// <summary>Requested category; security domains may also occur in Applications.</summary>
    Kind: TGpRegistryKind;
    /// <summary>Independent five- through sixteen-byte AID.</summary>
    Aid: TBytes;
    /// <summary>Raw one-byte lifecycle value, interpreted using Kind and card version.</summary>
    LifeCycle: Byte;
    /// <summary>Raw one- or three-byte privileges; empty for load files.</summary>
    Privileges: TBytes;
    /// <summary>Executable-module AIDs, when advertised.</summary>
    Modules: TGpAppletAids;
    /// <summary>Canonical complete entry bytes, including unfamiliar TLVs.</summary>
    Raw: TBytes;
  end;

  /// <summary>Ordered independent registry entries; record assignment shares arrays.</summary>
  TGpRegistryEntries = array of TGpRegistryEntry;

  /// <summary>One returned C0 key-information entry; no secret material is exposed.</summary>
  TGpKeyInformation = record
    /// <summary>Raw key identifier.</summary>
    KeyId: Byte;
    /// <summary>Raw key version.</summary>
    Version: Byte;
    /// <summary>Independent type/length pairs for each key component; unknown types are retained.</summary>
    Components: TBytes;
  end;

  /// <summary>Owned key-information entries from an E0 template.</summary>
  TGpKeyInformationList = array of TGpKeyInformation;

  /// <summary>One CPLC field; dates are retained as raw protocol values.</summary>
  TGpCplcField = record
    /// <summary>GlobalPlatform field name.</summary>
    Name: string;
    /// <summary>Independent two- or four-byte field; unknown date decades are not guessed.</summary>
    Value: TBytes;
  end;

  /// <summary>Ordered eighteen-field CPLC data decoded from exactly forty-two bytes.</summary>
  TGpCplcFields = array of TGpCplcField;

  /// <summary>LOAD progress notification on the initiating thread, after an acknowledged block.</summary>
  /// <param name="Sender">The manager.</param>
  /// <param name="ACompleted">Acknowledged load-image bytes.</param>
  /// <param name="ATotal">Complete DAP/C4 load-image size.</param>
  TGpLoadProgressEvent = procedure(Sender: TObject; const ACompleted, ATotal: Integer) of object;

  /// <summary>GlobalPlatform card management and JavaCard loading; opens no hardware at construction.</summary>
  /// <remarks>Use on one thread, with a connected basic-channel transport. Authentication holds
  /// its exclusive transaction until CloseSession. Reads require exclusive transaction capability.
  /// State-changing commands require authentication and are never retried. No default keys,
  /// automatic deletion is supplied. Provisioned keys and delegated-management policies are explicit.</remarks>
  TGlobalPlatformCardManager = class(TComponent)
  private
    FTransport: ICardTransport;
    FSelectedAid: TBytes;
    FAes: ICardAesProvider;
    FDes: ICardDesProvider;
    FChannel: ICardTransport;
    FSecure: TGpSecureChannel;
    FOnProgress: TGpLoadProgressEvent;
    FConfirmation: TBytes;
    FTokenSigner: ICardGpTokenSigner;
    FReceiptVerifier: ICardGpReceiptVerifier;
    function Tokenize(const Ins, P1, P2: Byte; const Data: TBytes): TBytes;
    function GetConfirmation: TBytes;
    procedure Acknowledge(const AResponse: TApduResponse; const AContext: TBytes = nil);
    procedure SetTransport(const AValue: ICardTransport);
    function GetAuthenticated: Boolean;
    function EnterRead: ICardTransaction;
    function Send(const Ins, P1, P2: Byte; const Data: TBytes;
      const ReadResponse: Boolean): TApduResponse;
    procedure RequireSession;
  public
    /// <summary>Releases the secure session and retained interfaces without sending commands.</summary>
    destructor Destroy; override;

    /// <summary>Selects an explicit security-domain AID, closing any existing session first.</summary>
    /// <param name="AAid">Five through sixteen bytes; no wildcard/default selection.</param>
    /// <returns>Independent SELECT response with FCI or card error.</returns>
    function SelectSecurityDomain(const AAid: TBytes): TApduResponse;

    /// <summary>Authenticates selected domain using an explicitly chosen secure-channel profile.</summary>
    /// <param name="AProtocol">SCP02 i=15 or SCP03 S8/S16; selected domain is reselected in the secure transaction.</param>
    /// <param name="AKeys">Borrowed sixteen-byte ENC/MAC and optional DEK; owned session secrets are cleared on CloseSession.</param>
    /// <param name="AKeyVersion">Explicit version; zero permits card selection.</param>
    /// <param name="AKeyId">SCP02 identifier; zero for SCP03.</param>
    /// <param name="ALevel">Explicit protection; response protection requires SCP03 support.</param>
    /// <param name="AS16">Request SCP03 sixteen-byte authentication.</param>
    procedure Authenticate(const AProtocol: TGpSecureProtocol; const AKeys: TGpCardKeys;
      const AKeyVersion, AKeyId: Byte; const ALevel: TGpSecurityLevel;
      const AS16: Boolean = False);

    /// <summary>Closes local session state and releases the owned card transaction.</summary>
    procedure CloseSession;

    /// <summary>Reads and parses CPLC without inferring date decades.</summary>
    /// <returns>Independent eighteen-field CPLC snapshot; no certificate/trust claim.</returns>
    function ReadCplc: TGpCplcFields;

    /// <summary>Reads one registry category with bounded GET STATUS continuation.</summary>
    /// <param name="AKind">Explicit issuer/application/load-file category.</param>
    /// <param name="ATagged">True requests E3 TLV; false explicitly requests legacy positional format.</param>
    /// <returns>Entries including raw bytes; empty on 6A88. No automatic format fallback.</returns>
    function GetStatus(const AKind: TGpRegistryKind;
      const ATagged: Boolean = True): TGpRegistryEntries;

    /// <summary>Preflights and loads a validated CAP using INSTALL for load and numbered LOAD blocks.</summary>
    /// <param name="ACap">Non-nil validated package; borrowed for this call.</param>
    /// <param name="ASecurityDomain">Explicit target domain AID, five through sixteen bytes.</param>
    /// <param name="ABlockSize">Clear LOAD bytes per command, one through 220; at most 256 blocks.</param>
    /// <param name="ALoadParameters">Explicit GP load parameters, zero through 100 bytes.</param>
    /// <param name="ALoadHash">Explicit raw-component hash, empty or 20/32/48/64 bytes; required with DAP blocks.</param>
    /// <param name="ADapBlocks">Complete validated E2 DAP blocks prepended before C4; empty omits DAP.</param>
    /// <remarks>No rollback/delete/retry on partial load; progress callbacks run on this thread.</remarks>
    procedure LoadCap(const ACap: TGpCapFile; const ASecurityDomain: TBytes;
      const ABlockSize: Integer = 220; const ALoadParameters: TBytes = nil;
      const ALoadHash: TBytes = nil; const ADapBlocks: TBytes = nil);

    /// <summary>Sends explicit INSTALL for install and make selectable.</summary>
    /// <param name="ACap">Validated loaded package containing the requested module AID.</param>
    /// <param name="AModuleAid">Applet AID present in CAP Applet.cap.</param>
    /// <param name="AInstanceAid">New five- through sixteen-byte instance AID.</param>
    /// <param name="APrivileges">Explicit one- or three-byte privilege mask.</param>
    /// <param name="AApplicationParameters">Raw application parameters wrapped in C9, zero through 100 bytes.</param>
    /// <remarks>No implicit loading or default privileges; TokenSigner supplies optional issuer authorization.</remarks>
    procedure InstallApplet(const ACap: TGpCapFile; const AModuleAid, AInstanceAid,
      APrivileges, AApplicationParameters: TBytes);

    /// <summary>Deletes one explicitly supplied AID; dependent objects only when requested.</summary>
    /// <param name="AAid">Five through sixteen bytes; no implicit removal of existing instances.</param>
    /// <param name="ADeleteRelated">True sets GP delete-related-objects bit; false deletes only this object.</param>
    procedure DeleteObject(const AAid: TBytes; const ADeleteRelated: Boolean = False);

    /// <summary>Sends one explicit SET STATUS with caller-chosen category/lifecycle.</summary>
    /// <param name="AKind">Issuer domain or application; executable load files are refused.</param>
    /// <param name="AAid">Explicit object AID; issuer status requires the selected domain and sends no data field.</param>
    /// <param name="ALifeCycle">Raw target lifecycle according to the selected card specification.</param>
    procedure SetStatus(const AKind: TGpRegistryKind; const AAid: TBytes;
      const ALifeCycle: Byte);

    /// <summary>Reads E0/C0 key information for the selected security domain.</summary>
    /// <returns>Owned key identifiers, versions and raw component type/length pairs; never keys.</returns>
    function ReadKeyInformation: TGpKeyInformationList;

    /// <summary>Deletes one exact key identifier/version and closes the current session.</summary>
    /// <param name="AVersion">Explicit persistent version, one through 127; no wildcard.</param>
    /// <param name="AKeyId">Exact identifier, one through 127.</param>
    /// <remarks>Requires authentication; no retries or implicit replacement keys.</remarks>
    procedure DeleteKey(const AVersion, AKeyId: Byte);

    /// <summary>Provisions a RSA verification public key using GP A1 modulus and A0 exponent components.</summary>
    /// <param name="AOldVersion">Zero adds; nonzero replaces the explicitly supplied version.</param>
    /// <param name="ANewVersion">Persistent new version, one through 127.</param>
    /// <param name="AKeyId">Explicit key identifier, one through 127.</param>
    /// <param name="AModulus">Unsigned big-endian 1024-bit modulus for the short-APDU RSA GP profile.</param>
    /// <param name="AExponent">Unsigned big-endian public exponent, one through eight bytes, odd.</param>
    /// <remarks>Used for legacy issuer-token or DAP verification keys; no private key is transmitted.</remarks>
    procedure PutRsaPublicKey(const AOldVersion, ANewVersion, AKeyId: Byte;
      const AModulus, AExponent: TBytes);

    /// <summary>Adds or replaces one explicitly identified symmetric key and closes the old session.</summary>
    /// <param name="AOldVersion">Zero adds a key; nonzero replaces this explicit version.</param>
    /// <param name="ANewVersion">New persistent key version, one through 127.</param>
    /// <param name="AKeyId">Explicit key identifier, one through 127.</param>
    /// <param name="AKey">Sixteen-byte AES or double-length DES key, borrowed and never logged.</param>
    /// <param name="AIsAes">Explicit key type; independent from the wrapping session protocol.</param>
    /// <remarks>Requires session DEK. Validates returned version and KCV; any submitted PUT KEY ends the session.</remarks>
    procedure PutKey(const AOldVersion, ANewVersion, AKeyId: Byte;
      const AKey: TBytes; const AIsAes: Boolean);

    /// <summary>Adds or replaces an ENC/MAC/DEK set starting at an explicit identifier.</summary>
    /// <param name="AOldVersion">Zero adds; nonzero replaces the specified old version.</param>
    /// <param name="ANewVersion">New version, one through 127.</param>
    /// <param name="AFirstKeyId">First of three consecutive identifiers, one through 125.</param>
    /// <param name="AKeys">New explicit sixteen-byte ENC, MAC and DEK keys.</param>
    /// <param name="AIsAes">True for AES, false for double-length DES.</param>
    /// <remarks>Validates all three returned KCVs and closes the session after submission; never retries.</remarks>
    procedure PutKeySet(const AOldVersion, ANewVersion, AFirstKeyId: Byte;
      const AKeys: TGpCardKeys; const AIsAes: Boolean);

    /// <summary>Makes an explicitly installed application selectable with optional delegated authorization.</summary>
    /// <param name="AAid">Five- through sixteen-byte instance AID.</param>
    /// <param name="APrivileges">Explicit one- or three-byte privilege mask.</param>
    /// <param name="ALoadFileAid">Explicit owning package for receipt context; required when a receipt policy is configured.</param>
    procedure MakeSelectable(const AAid, APrivileges: TBytes; const ALoadFileAid: TBytes = nil);

    /// <summary>Extradites an object between explicit security domains, with optional issuer token and verified receipt.</summary>
    /// <param name="AAid">Application or load-file AID.</param>
    /// <param name="AOldDomain">Current domain used in receipt context.</param>
    /// <param name="ANewDomain">New associated security domain.</param>
    procedure Extradite(const AAid, AOldDomain, ANewDomain: TBytes);

    /// <summary>Optional explicit issuer token signer used for INSTALL and DELETE; retained until replaced.</summary>
    property TokenSigner: ICardGpTokenSigner read FTokenSigner write FTokenSigner;

    /// <summary>Optional receipt policy; when set, final LOAD, INSTALL, DELETE and extradition require valid receipts.</summary>
    property ReceiptVerifier: ICardGpReceiptVerifier read FReceiptVerifier write FReceiptVerifier;

    /// <summary>Connected retained basic-channel transport; changing it closes the session.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;

    /// <summary>AES-128/CSPRNG provider used by newly opened SCP03 sessions.</summary>
    property AesProvider: ICardAesProvider read FAes write FAes;

    /// <summary>DES/CSPRNG provider used by newly opened SCP02 sessions.</summary>
    property DesProvider: ICardDesProvider read FDes write FDes;

    /// <summary>True while the successfully authenticated retained channel remains active.</summary>
    property Authenticated: Boolean read GetAuthenticated;

    /// <summary>Independent last management confirmation including its length byte; verification is mandatory when ReceiptVerifier is configured.</summary>
    property LastConfirmation: TBytes read GetConfirmation;
  published
    /// <summary>LOAD progress on the initiating thread; marshal to the UI in background callers.</summary>
    property OnLoadProgress: TGpLoadProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

constructor EGpCardError.CreateStatus(const AStatusWord: Word);
begin
  inherited Create('GlobalPlatform card status ' + IntToHex(AStatusWord, 4) + '.');
  FStatusWord := AStatusWord;
end;

procedure Invalid;
begin
  raise EGpCardError.Create('Invalid GlobalPlatform card operation or response.');
end;

procedure AidCheck(const A: TBytes);
begin
  if (Length(A) < 5) or (Length(A) > 16) then Invalid;
end;

function LV(const A: TBytes): TBytes;
begin
  Result := nil;
  if Length(A) > 255 then Invalid;
  SetLength(Result, Length(A) + 1);
  Result[0] := Length(A);
  if Length(A) > 0 then Move(A[0], Result[1], Length(A));
end;

procedure Append(var A: TBytes; const B: TBytes);
var
  N: Integer;
begin
  N := Length(A); SetLength(A, N + Length(B));
  if Length(B) > 0 then Move(B[0], A[N], Length(B));
end;

function JoinVersion(const V: Byte; const B: TBytes): TBytes;
begin
  Result := nil;
  SetLength(Result, 1); Result[0] := V; Append(Result, B);
end;

function Category(const K: TGpRegistryKind): Byte;
begin
  case K of
    grkIssuerDomain: Result := $80;
    grkApplications: Result := $40;
    grkLoadFiles: Result := $20;
    grkLoadFilesAndModules: Result := $10;
  else
    Invalid;
    Result := 0;
  end;
end;

destructor TGlobalPlatformCardManager.Destroy;
begin
  try CloseSession; except end;
  inherited Destroy;
end;

procedure TGlobalPlatformCardManager.SetTransport(const AValue: ICardTransport);
begin
  CloseSession;
  FTransport := AValue;
  FSelectedAid := nil;
end;

function TGlobalPlatformCardManager.GetAuthenticated: Boolean;
begin
  Result := (FSecure <> nil) and FSecure.Active;
end;

procedure TGlobalPlatformCardManager.CloseSession;
begin
  try
    if FSecure <> nil then FSecure.Close;
  finally
    FSecure := nil;
    FChannel := nil;
    TCardCrypto.Clear(FConfirmation);
  end;
end;

function TGlobalPlatformCardManager.EnterRead: ICardTransaction;
begin
  Result := nil;
  if Authenticated then Exit;
  if FChannel <> nil then Invalid;
  if (FTransport = nil) or not Supports(FTransport, ICardTransaction, Result) then Invalid;
  Result.BeginTransaction;
end;

procedure TGlobalPlatformCardManager.RequireSession;
begin
  if not Authenticated then Invalid;
end;

function TGlobalPlatformCardManager.Send(const Ins, P1, P2: Byte;
  const Data: TBytes; const ReadResponse: Boolean): TApduResponse;
var
  Cmd: TApduCommand;
  Count, N: Integer;
  Extra: TApduResponse;
  Channel: ICardTransport;
begin
  if FTransport = nil then Invalid;
  Channel := FTransport;
  if FChannel <> nil then
  begin
    RequireSession;
    Channel := FChannel;
  end;
  Cmd := Default(TApduCommand);
  Cmd.CLA := $80; Cmd.INS := Ins; Cmd.P1 := P1; Cmd.P2 := P2; Cmd.Data := Data;
  Cmd.HasLe := ReadResponse;
  if ReadResponse then Cmd.Le := 256;
  Result := TApduCodec.DecodeResponse(Channel.Exchange(TApduCodec.EncodeCommand(Cmd)));
  Count := 0;
  while ReadResponse and (Result.StatusWord shr 8 = $61) do
  begin
    Inc(Count);
    if (Count > 32) or (Length(Result.Data) > 8192) then Invalid;
    Cmd := Default(TApduCommand);
    Cmd.INS := $C0; Cmd.HasLe := True; Cmd.Le := Result.StatusWord and $FF;
    if Cmd.Le = 0 then Cmd.Le := 256;
    Extra := TApduCodec.DecodeResponse(Channel.Exchange(TApduCodec.EncodeCommand(Cmd)));
    N := Length(Result.Data);
    if N + Length(Extra.Data) > 8192 then Invalid;
    Append(Result.Data, Extra.Data);
    Result.StatusWord := Extra.StatusWord;
  end;
end;

function TGlobalPlatformCardManager.SelectSecurityDomain(const AAid: TBytes): TApduResponse;
var
  Txn: ICardTransaction;
  Cmd: TApduCommand;
begin
  AidCheck(AAid);
  CloseSession;
  FSelectedAid := nil;
  Txn := EnterRead;
  try
    Cmd := Default(TApduCommand);
    Cmd.INS := $A4; Cmd.P1 := $04; Cmd.Data := AAid; Cmd.HasLe := True; Cmd.Le := 256;
    Result := TApduCodec.DecodeResponse(FTransport.Exchange(TApduCodec.EncodeCommand(Cmd)));
    if Result.StatusWord = $9000 then FSelectedAid := CopyBytes(AAid);
  finally
    if Txn <> nil then Txn.EndTransaction;
  end;
end;

procedure TGlobalPlatformCardManager.Authenticate(const AProtocol: TGpSecureProtocol;
  const AKeys: TGpCardKeys; const AKeyVersion, AKeyId: Byte;
  const ALevel: TGpSecurityLevel; const AS16: Boolean);
begin
  if (FChannel <> nil) or (Length(FSelectedAid) = 0) then Invalid;
  FSecure := TGpSecureChannel.Create(FTransport, FAes, FDes);
  FChannel := FSecure;
  try
    FSecure.Open(AProtocol, AKeys, AKeyVersion, AKeyId, ALevel, AS16, FSelectedAid);
  except
    CloseSession;
    raise;
  end;
end;

function TGlobalPlatformCardManager.GetConfirmation: TBytes;
begin
  Result := CopyBytes(FConfirmation);
end;

procedure TGlobalPlatformCardManager.Acknowledge(const AResponse: TApduResponse;
  const AContext: TBytes);
var
  Posn, N, I: Integer;
begin
  if AResponse.StatusWord <> $9000 then raise EGpCardError.CreateStatus(AResponse.StatusWord);
  N := Length(AResponse.Data);
  // GP confirmations are length-prefixed; tolerate deployed cards returning no data.
  if N > 0 then
  begin
    if (N > 256) or (AResponse.Data[0] <> N - 1) then Invalid;
    if N > 1 then
    begin
      Posn := 1;
      for I := 0 to 2 do
      begin
        if Posn >= N then Invalid;
        if (I = 1) and (AResponse.Data[Posn] <> 2) then Invalid;
        if (I = 2) and (AResponse.Data[Posn] = 0) then Invalid;
        Inc(Posn, 1 + AResponse.Data[Posn]);
        if Posn > N then Invalid;
      end;
      if Posn <> N then Invalid;
    end;
  end;
  if (FReceiptVerifier <> nil) and (Length(AContext) > 0) then
  begin
    try FReceiptVerifier.Verify(AResponse.Data, AContext);
    except CloseSession; raise; end;
  end;
  TCardCrypto.Clear(FConfirmation);
  FConfirmation := CopyBytes(AResponse.Data);
end;

function TGlobalPlatformCardManager.ReadCplc: TGpCplcFields;
const
  Names: array[0..17] of string = ('IC fabricator', 'IC type', 'OS identifier',
    'OS release date', 'OS release level', 'IC fabrication date', 'IC serial number',
    'IC batch identifier', 'IC module fabricator', 'IC module packaging date',
    'ICC manufacturer', 'IC embedding date', 'IC prepersonalizer',
    'IC prepersonalization equipment date', 'IC prepersonalization equipment identifier',
    'IC personalizer', 'IC personalization date', 'IC personalization equipment identifier');
var
  Txn: ICardTransaction;
  R: TApduResponse;
  I, Posn, N: Integer;
begin
  Result := nil;
  Txn := EnterRead;
  try
    R := Send($CA, $9F, $7F, nil, True);
    if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
    if (Length(R.Data) = 45) and (R.Data[0] = $9F) and (R.Data[1] = $7F) and
      (R.Data[2] = 42) then R.Data := Copy(R.Data, 3, 42);
    if Length(R.Data) <> 42 then Invalid;
    SetLength(Result, 18); Posn := 0;
    for I := 0 to 17 do
    begin
      N := 2;
      if I in [6, 14, 17] then N := 4;
      Result[I].Name := Names[I]; Result[I].Value := Copy(R.Data, Posn, N);
      Inc(Posn, N);
    end;
  finally
    if Txn <> nil then Txn.EndTransaction;
  end;
end;

function TGlobalPlatformCardManager.GetStatus(const AKind: TGpRegistryKind;
  const ATagged: Boolean): TGpRegistryEntries;
var
  Txn: ICardTransaction;
  R: TApduResponse;
  Doc: TTlvDocument;
  Node, Field: TTlvNode;
  I, J, N, Posn, Start, Size, Pages: Integer;
  P2: Byte;
  Entry: TGpRegistryEntry;
  SeenAid, SeenState, SeenPrivileges: Boolean;
begin
  Result := nil;
  Category(AKind);
  P2 := 0;
  if ATagged then P2 := 2;
  Txn := EnterRead;
  try
    Pages := 0;
    repeat
      Inc(Pages);
      if Pages > 64 then Invalid;
      R := Send($F2, Category(AKind), P2, HexToBytes('4F00'), True);
      if R.StatusWord = $6A88 then
      begin
        if Length(R.Data) <> 0 then Invalid;
        Break;
      end;
      if (R.StatusWord <> $9000) and (R.StatusWord <> $6310) then
        raise EGpCardError.CreateStatus(R.StatusWord);
      if (R.StatusWord = $6310) and (Length(R.Data) = 0) then Invalid;
      if ATagged then
      begin
        Doc := TTlvCodec.Decode(R.Data);
        try
          for I := 0 to Doc.Count - 1 do
          begin
            Node := Doc.Roots[I];
            if BytesToHex(Node.Tag) <> 'E3' then Invalid;
            Entry := Default(TGpRegistryEntry); Entry.Kind := AKind;
            SeenAid := False; SeenState := False; SeenPrivileges := False;
            for J := 0 to Node.ChildCount - 1 do
            begin
              Field := Node.Children[J];
              if BytesToHex(Field.Tag) = '4F' then
              begin
                if SeenAid then Invalid;
                SeenAid := True; Entry.Aid := Field.Value; AidCheck(Entry.Aid);
              end
              else if BytesToHex(Field.Tag) = '9F70' then
              begin
                if SeenState or (Field.ValueSize <> 1) then Invalid;
                SeenState := True; Entry.LifeCycle := Field.Value[0];
              end
              else if BytesToHex(Field.Tag) = 'C5' then
              begin
                if SeenPrivileges or not (Field.ValueSize in [1, 3]) then Invalid;
                SeenPrivileges := True; Entry.Privileges := Field.Value;
              end
              else if BytesToHex(Field.Tag) = '84' then
              begin
                AidCheck(Field.Value); N := Length(Entry.Modules);
                SetLength(Entry.Modules, N + 1); Entry.Modules[N] := Field.Value;
              end;
            end;
            if not SeenAid or not SeenState then Invalid;
            Entry.Raw := TTlvCodec.EncodeNode(Node);
            N := Length(Result); if N >= 4096 then Invalid;
            SetLength(Result, N + 1); Result[N] := Entry;
          end;
        finally
          Doc.Free;
        end;
      end
      else
      begin
        Posn := 0;
        while Posn < Length(R.Data) do
        begin
          Start := Posn; Entry := Default(TGpRegistryEntry); Entry.Kind := AKind;
          Size := R.Data[Posn]; Inc(Posn);
          if Posn + Size + 2 > Length(R.Data) then Invalid;
          Entry.Aid := Copy(R.Data, Posn, Size); AidCheck(Entry.Aid); Inc(Posn, Size);
          Entry.LifeCycle := R.Data[Posn]; Inc(Posn);
          Entry.Privileges := Copy(R.Data, Posn, 1); Inc(Posn);
          if AKind = grkLoadFilesAndModules then
          begin
            if Posn >= Length(R.Data) then Invalid;
            Size := R.Data[Posn]; Inc(Posn); SetLength(Entry.Modules, Size);
            for I := 0 to Size - 1 do
            begin
              if Posn >= Length(R.Data) then Invalid;
              N := R.Data[Posn]; Inc(Posn);
              if Posn + N > Length(R.Data) then Invalid;
              Entry.Modules[I] := Copy(R.Data, Posn, N); AidCheck(Entry.Modules[I]); Inc(Posn, N);
            end;
          end;
          Entry.Raw := Copy(R.Data, Start, Posn - Start);
          N := Length(Result); if N >= 4096 then Invalid;
          SetLength(Result, N + 1); Result[N] := Entry;
        end;
      end;
      P2 := P2 or 1;
    until R.StatusWord = $9000;
  finally
    if Txn <> nil then Txn.EndTransaction;
  end;
end;

procedure TGlobalPlatformCardManager.LoadCap(const ACap: TGpCapFile;
  const ASecurityDomain: TBytes; const ABlockSize: Integer;
  const ALoadParameters, ALoadHash, ADapBlocks: TBytes);
var
  Image, Data: TBytes;
  R: TApduResponse;
  I, Offset, Size, Count: Integer;
  P1: Byte;
  Doc: TTlvDocument;
  J: Integer;
begin
  RequireSession;
  AidCheck(ASecurityDomain);
  if (ACap = nil) or (ABlockSize < 1) or (ABlockSize > 220) or
    (Length(ALoadParameters) > 100) then Invalid;
  if not ((Length(ALoadHash) = 0) or (Length(ALoadHash) in [20, 32, 48, 64])) or
    (Length(ADapBlocks) > 8192) or (((Length(ADapBlocks) > 0) or (FTokenSigner <> nil)) and (Length(ALoadHash) = 0)) then Invalid;
  if Length(ADapBlocks) > 0 then
  begin
    Doc := TTlvCodec.Decode(ADapBlocks);
    try
      if Doc.Count = 0 then Invalid;
      for J := 0 to Doc.Count - 1 do
      begin
        if (BytesToHex(Doc.Roots[J].Tag) <> 'E2') or (Doc.Roots[J].ChildCount <> 2) then Invalid;
        if (BytesToHex(Doc.Roots[J].Children[0].Tag) <> '4F') or
          (BytesToHex(Doc.Roots[J].Children[1].Tag) <> 'C3') then Invalid;
        AidCheck(Doc.Roots[J].Children[0].Value);
        if BytesToHex(TGpManagementCrypto.DapBlock(Doc.Roots[J].Children[0].Value,
          Doc.Roots[J].Children[1].Value)) <> BytesToHex(TTlvCodec.EncodeNode(Doc.Roots[J])) then Invalid;
      end;
    finally Doc.Free; end;
  end;
  Image := CopyBytes(ADapBlocks); Append(Image, ACap.LoadImage);
  Count := (Length(Image) + ABlockSize - 1) div ABlockSize;
  if (Count < 1) or (Count > 256) then Invalid;
  Data := LV(ACap.PackageAid); Append(Data, LV(ASecurityDomain));
  Append(Data, LV(ALoadHash)); Append(Data, LV(ALoadParameters));
  Data := Tokenize($E6, $02, 0, Data);
  R := Send($E6, $02, 0, Data, True);
  Acknowledge(R);
  Offset := 0;
  for I := 0 to Count - 1 do
  begin
    Size := Length(Image) - Offset;
    if Size > ABlockSize then Size := ABlockSize;
    P1 := 0;
    if I = Count - 1 then P1 := $80;
    R := Send($E8, P1, I, Copy(Image, Offset, Size), True);
    if I = Count - 1 then Acknowledge(R, TGpManagementCrypto.ReceiptContext([ACap.PackageAid, ASecurityDomain]))
    else Acknowledge(R);
    Inc(Offset, Size);
    if Assigned(FOnProgress) then FOnProgress(Self, Offset, Length(Image));
  end;
end;

procedure TGlobalPlatformCardManager.InstallApplet(const ACap: TGpCapFile;
  const AModuleAid, AInstanceAid, APrivileges, AApplicationParameters: TBytes);
var
  Data, Params: TBytes;
  Applets: TGpAppletAids;
  I: Integer;
  Found: Boolean;
  R: TApduResponse;
begin
  RequireSession;
  AidCheck(AModuleAid); AidCheck(AInstanceAid);
  if (ACap = nil) or not (Length(APrivileges) in [1, 3]) or
    (Length(AApplicationParameters) > 100) then Invalid;
  Found := False; Applets := ACap.Applets;
  for I := 0 to High(Applets) do
    if BytesToHex(Applets[I]) = BytesToHex(AModuleAid) then Found := True;
  if not Found then Invalid;
  Params := HexToBytes('C9'); Append(Params, LV(AApplicationParameters));
  Data := LV(ACap.PackageAid); Append(Data, LV(AModuleAid)); Append(Data, LV(AInstanceAid));
  Append(Data, LV(APrivileges)); Append(Data, LV(Params));
  Data := Tokenize($E6, $0C, 0, Data);
  R := Send($E6, $0C, 0, Data, True);
  Acknowledge(R, TGpManagementCrypto.ReceiptContext([ACap.PackageAid, AInstanceAid]));
end;

procedure TGlobalPlatformCardManager.DeleteObject(const AAid: TBytes;
  const ADeleteRelated: Boolean);
var
  Data: TBytes;
  P2: Byte;
  R: TApduResponse;
begin
  RequireSession; AidCheck(AAid);
  Data := HexToBytes('4F'); Append(Data, LV(AAid));
  P2 := 0; if ADeleteRelated then P2 := $80;
  Data := Tokenize($E4, 0, P2, Data);
  R := Send($E4, 0, P2, Data, True);
  Acknowledge(R, TGpManagementCrypto.ReceiptContext([AAid]));
end;

procedure TGlobalPlatformCardManager.SetStatus(const AKind: TGpRegistryKind;
  const AAid: TBytes; const ALifeCycle: Byte);
var
  R: TApduResponse;
begin
  RequireSession; AidCheck(AAid);
  if not (AKind in [grkIssuerDomain, grkApplications]) then Invalid;
  if AKind = grkIssuerDomain then
  begin
    if not TCardCrypto.EqualSecret(AAid, FSelectedAid) then Invalid;
    R := Send($F0, $80, ALifeCycle, nil, True);
  end
  else R := Send($F0, $40, ALifeCycle, AAid, True);
  Acknowledge(R);
end;

function TGlobalPlatformCardManager.Tokenize(const Ins, P1, P2: Byte;
  const Data: TBytes): TBytes;
var Cmd: TApduCommand; Token: TBytes;
begin
  Result := CopyBytes(Data);
  if FTokenSigner <> nil then
  begin
    Cmd := Default(TApduCommand); Cmd.CLA := $80; Cmd.INS := Ins;
    Cmd.P1 := P1; Cmd.P2 := P2; Cmd.Data := Data;
    Token := FTokenSigner.Sign(Cmd);
    if (Length(Token) < 8) or (Length(Token) > 192) then Invalid;
    if Ins = $E4 then
    begin
      Append(Result, HexToBytes('9E'));
      if Length(Token) >= 128 then Append(Result, HexToBytes('81'));
    end;
    // Token LV uses BER length for signatures of 128 bytes or more.
    if (Ins <> $E4) and (Length(Token) >= 128) then Append(Result, HexToBytes('81'));
    Append(Result, LV(Token));
  end
  else if Ins <> $E4 then Append(Result, LV(nil));
  if Length(Result) > 220 then Invalid;
end;

procedure TGlobalPlatformCardManager.PutKey(const AOldVersion, ANewVersion, AKeyId: Byte;
  const AKey: TBytes; const AIsAes: Boolean);
var Data, Expected: TBytes; R: TApduResponse;
begin
  RequireSession;
  if (AOldVersion > 127) or (ANewVersion = 0) or (ANewVersion > 127) or
    (AKeyId = 0) or (AKeyId > 127) or (Length(AKey) <> 16) then Invalid;
  Data := nil; Expected := nil;
  try
    Data := FSecure.EncodeKey(AKey, AIsAes);
    Expected := Copy(Data, Length(Data) - 3, 3);
    Data := JoinVersion(ANewVersion, Data);
    try
      R := Send($D8, AOldVersion, AKeyId, Data, True);
      if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
      if (Length(R.Data) <> 4) then Invalid;
      if (R.Data[0] <> ANewVersion) or
        not TCardCrypto.EqualSecret(Copy(R.Data, 1, 3), Expected) then Invalid;
    finally CloseSession; end;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(Expected); end;
end;

procedure TGlobalPlatformCardManager.PutKeySet(const AOldVersion, ANewVersion, AFirstKeyId: Byte;
  const AKeys: TGpCardKeys; const AIsAes: Boolean);
var Data, Entry, Expected: TBytes; R: TApduResponse; I: Integer;
  Keys: array[0..2] of TBytes;
begin
  RequireSession;
  if (AOldVersion > 127) or (ANewVersion = 0) or (ANewVersion > 127) or
    (AFirstKeyId = 0) or (AFirstKeyId > 125) or (Length(AKeys.Enc) <> 16) or
    (Length(AKeys.Mac) <> 16) or (Length(AKeys.Dek) <> 16) then Invalid;
  Data := nil; Expected := nil; Entry := nil;
  Keys[0] := AKeys.Enc; Keys[1] := AKeys.Mac; Keys[2] := AKeys.Dek;
  try
    SetLength(Data, 1); Data[0] := ANewVersion;
    for I := 0 to 2 do
    begin
      Entry := FSecure.EncodeKey(Keys[I], AIsAes);
      Append(Data, Entry); Append(Expected, Copy(Entry, Length(Entry) - 3, 3));
      TCardCrypto.Clear(Entry);
    end;
    try
      R := Send($D8, AOldVersion, AFirstKeyId or $80, Data, True);
      if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
      if Length(R.Data) <> 10 then Invalid;
      if (R.Data[0] <> ANewVersion) or
        not TCardCrypto.EqualSecret(Copy(R.Data, 1, 9), Expected) then Invalid;
    finally CloseSession; end;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(Expected); TCardCrypto.Clear(Entry); end;
end;

procedure TGlobalPlatformCardManager.MakeSelectable(const AAid, APrivileges: TBytes;
  const ALoadFileAid: TBytes);
var Data: TBytes; R: TApduResponse;
begin
  RequireSession; AidCheck(AAid);
  if not (Length(APrivileges) in [1, 3]) then Invalid;
  if (FReceiptVerifier <> nil) or (Length(ALoadFileAid) > 0) then AidCheck(ALoadFileAid);
  Data := HexToBytes('0000'); Append(Data, LV(AAid)); Append(Data, LV(APrivileges));
  Append(Data, LV(nil)); Data := Tokenize($E6, $08, 0, Data);
  R := Send($E6, $08, 0, Data, True);
  if Length(ALoadFileAid) > 0 then Acknowledge(R, TGpManagementCrypto.ReceiptContext([ALoadFileAid, AAid]))
  else Acknowledge(R);
end;

procedure TGlobalPlatformCardManager.Extradite(const AAid, AOldDomain, ANewDomain: TBytes);
var Data: TBytes; R: TApduResponse;
begin
  RequireSession; AidCheck(AAid); AidCheck(AOldDomain); AidCheck(ANewDomain);
  Data := LV(ANewDomain); Append(Data, LV(nil)); Append(Data, LV(AAid));
  Append(Data, HexToBytes('0000')); Data := Tokenize($E6, $10, 0, Data);
  R := Send($E6, $10, 0, Data, True);
  Acknowledge(R, TGpManagementCrypto.ReceiptContext([AOldDomain, AAid, ANewDomain]));
end;

function TGlobalPlatformCardManager.ReadKeyInformation: TGpKeyInformationList;
var Txn: ICardTransaction; R: TApduResponse; Doc: TTlvDocument;
  Node: TTlvNode; I, J, N: Integer; Value: TBytes;
begin
  Result := nil; Txn := EnterRead;
  try
    R := Send($CA, 0, $E0, nil, True);
    if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
    Doc := TTlvCodec.Decode(R.Data);
    try
      if (Doc.Count <> 1) then Invalid;
      Node := Doc.Roots[0]; if BytesToHex(Node.Tag) <> 'E0' then Invalid;
      if Node.ChildCount > 256 then Invalid;
      SetLength(Result, Node.ChildCount);
      for I := 0 to Node.ChildCount - 1 do
      begin
        if BytesToHex(Node.Children[I].Tag) <> 'C0' then Invalid;
        Value := Node.Children[I].Value; N := Length(Value);
        if (N < 4) or (N mod 2 <> 0) then Invalid;
        for J := 0 to (N - 2) div 2 - 1 do
          if Value[3 + J * 2] = 0 then Invalid;
        Result[I].KeyId := Value[0]; Result[I].Version := Value[1];
        Result[I].Components := Copy(Value, 2, N - 2);
      end;
    finally Doc.Free; end;
  finally if Txn <> nil then Txn.EndTransaction; end;
end;

procedure TGlobalPlatformCardManager.DeleteKey(const AVersion, AKeyId: Byte);
var Data: TBytes; R: TApduResponse;
begin
  RequireSession;
  if (AVersion = 0) or (AVersion > 127) or (AKeyId = 0) or (AKeyId > 127) then Invalid;
  Data := HexToBytes('D001'); Append(Data, JoinVersion(AKeyId, HexToBytes('D201')));
  SetLength(Data, Length(Data) + 1); Data[High(Data)] := AVersion;
  try
    R := Send($E4, 0, 0, Data, True);
    if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
  finally CloseSession; end;
end;

procedure TGlobalPlatformCardManager.PutRsaPublicKey(const AOldVersion, ANewVersion, AKeyId: Byte;
  const AModulus, AExponent: TBytes);
var Data: TBytes; R: TApduResponse;
begin
  RequireSession;
  if (AOldVersion > 127) or (ANewVersion = 0) or (ANewVersion > 127) or
    (AKeyId = 0) or (AKeyId > 127) or (Length(AModulus) <> 128) or
    (AModulus[0] < $80) or (Length(AExponent) < 1) or (Length(AExponent) > 8) then Invalid;
  if (AExponent[0] = 0) or (AExponent[High(AExponent)] and 1 = 0) or
    ((Length(AExponent) = 1) and (AExponent[0] < 3)) then Invalid;
  Data := JoinVersion(ANewVersion, HexToBytes('A18180')); Append(Data, AModulus);
  Append(Data, HexToBytes('A0')); Append(Data, LV(AExponent)); Append(Data, HexToBytes('00'));
  try
    R := Send($D8, AOldVersion, AKeyId, Data, True);
    if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
    if (Length(R.Data) <> 1) then Invalid;
    if R.Data[0] <> ANewVersion then Invalid;
  finally CloseSession; end;
end;

end.
