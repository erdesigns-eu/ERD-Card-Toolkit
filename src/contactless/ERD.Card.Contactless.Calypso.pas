unit ERD.Card.Contactless.Calypso;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes, {$ELSE}System.SysUtils, System.Classes, {$ENDIF}
  ERD.Card.APDU, ERD.Card.Transport;

type
  /// <summary>Explicit Calypso command dialect; no automatic alternate-class retry.</summary>
  TCalypsoDialect = (
    /// <summary>Legacy Calypso proprietary command class 94.</summary>
    cdLegacy94,
    /// <summary>Revision 3 compatible ISO class 00 with logical-path selection P1 09.</summary>
    cdIso00);

  /// <summary>Live read-only secure session supplied by a trusted Calypso SDK/SAM adapter.</summary>
  /// <remarks>The provider must return authenticated/decrypted APDU responses, enforce the requested
  /// read-only command policy and verify final session authentication. Keys remain owned by the provider.</remarks>
  ICalypsoSecureReadSession = interface
    ['{899FB7B8-C21C-47A7-ABBA-6CE2E1EFA140}']
    /// <summary>Returns a nonnil APDU adapter for this already-opened secure session.</summary>
    /// <returns>Authenticated plaintext exchange transport; never a raw unverified fallback.</returns>
    function GetTransport: ICardTransport;
    /// <summary>Closes and verifies the secure session; any authentication failure must raise.</summary>
    procedure Finish;
    /// <summary>Best-effort read-session abort after failure; must not commit a debit or update.</summary>
    procedure Abort;
  end;

  /// <summary>Injected authentication implementation using caller-owned legitimate keys or a SAM.</summary>
  /// <remarks>This library does not implement a native Calypso MAC/SAM engine. Use an adapter for
  /// the actual card revision and SDK. No issuer keys, defaults, guesses or key searches are provided.</remarks>
  ICalypsoSecureSessionProvider = interface
    ['{48B73A50-BFB5-4A7C-A6AE-187985A0E9D6}']
    /// <summary>Authenticates and opens one read-only session inside the reader's exclusive transaction.</summary>
    /// <param name="ATransport">Raw connected transport, exclusively retained for this read.</param>
    /// <param name="ADialect">Explicit selected Calypso command dialect.</param>
    /// <param name="ASelectionData">Owned selection bytes of the current directory/file; do not retain mutable aliases.</param>
    /// <returns>Authenticated session; nil is an error, never permission to downgrade to public reads.</returns>
    /// <remarks>Provider cleans up a partially opened session if Open raises. It owns all key material
    /// and revision-specific authentication/SAM commands. Transport errors must not replay authentication.</remarks>
    function Open(const ATransport: ICardTransport;
      const ADialect: TCalypsoDialect; const ASelectionData: TBytes)
      : ICalypsoSecureReadSession;
  end;

  /// <summary>Calypso configuration, malformed response or unexpected card status.</summary>
  ECalypsoError = class(Exception);

  /// <summary>Unexpected card status, retaining no command or personal record data.</summary>
  ECalypsoStatusError = class(ECalypsoError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates a sanitized failure carrying the returned status word.</summary>
    /// <param name="AStatusWord">Unexpected SW1/SW2.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Returned card status for diagnosing dialect or access failures.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>One successfully read, uninterpreted transit record.</summary>
  TCalypsoRecord = record
    /// <summary>Absolute record number, 1..255.</summary>
    Number: Byte;
    /// <summary>Independent raw record bytes; no issuer-specific schema is inferred.</summary>
    Data: TBytes;
  end;

  /// <summary>Successful records in ascending absolute-record order.</summary>
  TCalypsoRecords = array of TCalypsoRecord;

  /// <summary>One logical file selection and its public read outcomes.</summary>
  TCalypsoFile = record
    /// <summary>Explicit logical file identifier.</summary>
    LogicalId: Word;
    /// <summary>Exact successful SELECT response bytes, without status.</summary>
    SelectionData: TBytes;
    /// <summary>SELECT status; 6A82 means absent, 6982/6985 means restricted.</summary>
    SelectionStatus: Word;
    /// <summary>Successful public records; permission failures do not trigger authentication.</summary>
    Records: TCalypsoRecords;
    /// <summary>Last READ RECORD status; zero when no record was attempted.</summary>
    LastRecordStatus: Word;
    /// <summary>True when the caller's record bound was reached without an end marker.</summary>
    Truncated: Boolean;
  end;

  /// <summary>Caller-owned file snapshots, retaining absent and restricted file states.</summary>
  TCalypsoFiles = array of TCalypsoFile;

  /// <summary>Raw MOBIB ticketing snapshot; no subscription validity or fare entitlement is inferred.</summary>
  TMobibSnapshot = record
    /// <summary>Exact successful selection response of ticketing directory 2000.</summary>
    TicketingSelection: TBytes;
    /// <summary>Environment, holder, events, contracts, counters, contract list and extended holder files.</summary>
    Files: TCalypsoFiles;
  end;

  /// <summary>Inactive read-only Calypso logical-file/record component with a public MOBIB file profile.</summary>
  /// <remarks>Requires a connected contactless PC/SC/APDU transport, not a keyboard-only reader.
  /// Supplied dialect is explicit. Authentication requires an explicit external SDK/SAM provider; no native authentication engine, update, debit or reload is supplied.
  /// Raw files are preserved because schemas vary by issuer and card generation.</remarks>
  TCalypsoCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FDialect: TCalypsoDialect;
    FRecordBytes: Integer;
    FUseTransactions: Boolean;
    FRequireSecureSession: Boolean;
    FSecureSessionProvider: ICalypsoSecureSessionProvider;
    FSecureSession: ICalypsoSecureReadSession;
    FReadTransport: ICardTransport;
    procedure OpenSecureSession(const Selection: TBytes);
    procedure SetDialect(const V: TCalypsoDialect);
    procedure SetRecordBytes(const V: Integer);
    function Exchange(const C: TApduCommand): TApduResponse;
    function SelectFile(const Id: Word): TApduResponse;
    function ReadFileInternal(const Id: Word; const Limit: Integer)
      : TCalypsoFile;
    function BeginRead: ICardTransaction;
    procedure EndRead(const T: ICardTransaction; const Success: Boolean);
  public
    /// <summary>Creates an inactive legacy-94 reader with 29-byte record Le and exclusive transactions.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Selects a known logical file and reads public records up to the caller's bound.</summary>
    /// <param name="ALogicalId">Known nonzero logical file identifier in the current application.</param>
    /// <param name="AMaxRecords">Maximum absolute records to attempt, 1..255.</param>
    /// <returns>Owned successful records plus absence/restriction/end or truncation state.</returns>
    /// <remarks>6A83 ends record reading. 6982/6985 preserves restriction status and any preceding reads.
    /// Unexpected statuses and transport errors abort without a snapshot. No fallback or authentication.</remarks>
    function ReadFile(const ALogicalId: Word; const AMaxRecords: Integer = 16)
      : TCalypsoFile;
    /// <summary>Selects ticketing directory 2000 and reads the defined public MOBIB logical-file profile.</summary>
    /// <param name="AMaxRecordsPerFile">Explicit per-file bound, 1..255.</param>
    /// <returns>Raw environment 2001, holder 2002, events 2010/2040, contracts 2020, counters 2069,
    /// contract list 2050 and extended holder 3F1C, with per-file status and truncation.</returns>
    /// <remarks>A missing or restricted ticketing directory aborts; missing/restricted elementary files
    /// are represented explicitly. A successful directory selection does not certify a card as MOBIB.</remarks>
    function ReadMobib(const AMaxRecordsPerFile: Integer = 16): TMobibSnapshot;
    /// <summary>Reads a caller-defined MOBIB logical-file plan within one ticketing and optional secure session.</summary>
    /// <param name="ALogicalIds">One to 64 nonzero unique logical IDs, in desired read order.</param>
    /// <param name="AMaxRecordsPerFile">Explicit record bound per file, 1..255.</param>
    /// <returns>Exact acquired files and status outcomes, without limiting reads to the standard eight-file profile.</returns>
    /// <remarks>Selects ticketing directory 2000 once. The selected reader and secure provider determine
    /// which files are accessible; there is no guessed enumeration or authentication fallback.</remarks>
    function ReadMobibFiles(const ALogicalIds: array of Word;
      const AMaxRecordsPerFile: Integer = 16): TMobibSnapshot;
    /// <summary>Connected APDU transport retained by the reader.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Trusted external authentication/SAM adapter, used only when RequireSecureSession is true.</summary>
    /// <remarks>Its key material stays outside this component. The provider must outlive the read.</remarks>
    property SecureSessionProvider: ICalypsoSecureSessionProvider
      read FSecureSessionProvider write FSecureSessionProvider;
  published
    /// <summary>Explicit legacy-94 or ISO-00 dialect, default legacy-94.</summary>
    property Dialect: TCalypsoDialect read FDialect write SetDialect
      default cdLegacy94;
    /// <summary>Initial record Le, 1..256, default 29; one card-requested 6C length correction is permitted.</summary>
    property RecordBytes: Integer read FRecordBytes write SetRecordBytes
      default 29;
    /// <summary>Require verified provider-backed reads, default false; missing provider fails before card I/O.</summary>
    /// <remarks>No fallback to public reads on authentication or final-verification failure.</remarks>
    property RequireSecureSession: Boolean read FRequireSecureSession
      write FRequireSecureSession default False;
    /// <summary>Acquire one exclusive transaction for the whole read, default true; false requires caller exclusivity.</summary>
    property UseTransactions: Boolean read FUseTransactions
      write FUseTransactions default True;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail;
begin
  raise ECalypsoError.Create
    ('Calypso read failed; inspect configuration or card status.');
end;

constructor ECalypsoStatusError.Create(const AStatusWord: Word);
begin
  inherited Create('Calypso card status ' + IntToHex(AStatusWord, 4) + '.');
  FStatusWord := AStatusWord;
end;

constructor TCalypsoCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRecordBytes := 29;
  FUseTransactions := True;
end;

procedure TCalypsoCardReader.SetDialect(const V: TCalypsoDialect);
begin
  if (Ord(V) < Ord(Low(TCalypsoDialect))) or
    (Ord(V) > Ord(High(TCalypsoDialect))) then
    Fail;
  FDialect := V;
end;

procedure TCalypsoCardReader.SetRecordBytes(const V: Integer);
begin
  if (V < 1) or (V > 256) then
    Fail;
  FRecordBytes := V;
end;

function TCalypsoCardReader.BeginRead: ICardTransaction;
begin
  Result := nil;
  if (FTransport = nil) or (FReadTransport <> nil) or
    (FRequireSecureSession and (FSecureSessionProvider = nil)) then
    Fail;
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Result) then
      Fail;
    Result.BeginTransaction;
  end;
  FReadTransport := FTransport;
end;

procedure TCalypsoCardReader.OpenSecureSession(const Selection: TBytes);
begin
  if not FRequireSecureSession or (FSecureSession <> nil) then
    Exit;
  FSecureSession := FSecureSessionProvider.Open(FTransport, FDialect,
    CopyBytes(Selection));
  if FSecureSession = nil then
    Fail;
  FReadTransport := FSecureSession.GetTransport;
  if FReadTransport = nil then
    Fail;
end;

procedure TCalypsoCardReader.EndRead(const T: ICardTransaction;
  const Success: Boolean);
begin
  if Success and (FSecureSession <> nil) then
    try
      FSecureSession.Finish;
    except
      try
        FSecureSession.Abort;
      except
      end;
      FSecureSession := nil;
      FReadTransport := nil;
      if T <> nil then
        try
          T.EndTransaction;
        except
        end;
      raise;
    end
  else if FSecureSession <> nil then
    try
      FSecureSession.Abort;
    except
    end;
  FSecureSession := nil;
  FReadTransport := nil;
  if T = nil then
    Exit;
  if Success then
    T.EndTransaction
  else
  begin
    try
      T.EndTransaction;
    except
    end;
  end;
end;

function TCalypsoCardReader.Exchange(const C: TApduCommand): TApduResponse;
var
  Command: TApduCommand;
  R: TApduResponse;
  Data: TBytes;
  Step, I, N: Integer;
  Corrected: Boolean;
begin
  Command := C;
  Data := nil;
  Corrected := False;
  Result := Default (TApduResponse);
  for Step := 1 to 16 do
  begin
    R := TApduCodec.DecodeResponse
      (FReadTransport.Exchange(TApduCodec.EncodeCommand(Command)));
    if ((R.StatusWord shr 8) = $6C) and not Corrected then
    begin
      if Length(R.Data) <> 0 then
        Fail;
      Command.HasLe := True;
      Command.Le := (R.StatusWord and $FF);
      if Command.Le = 0 then
        Command.Le := 256;
      Corrected := True;
      Continue;
    end;
    if (Length(Data) + Length(R.Data) > 4096) then
      Fail;
    N := Length(Data);
    SetLength(Data, N + Length(R.Data));
    for I := 0 to High(R.Data) do
      Data[N + I] := R.Data[I];
    if (R.StatusWord shr 8) <> $61 then
    begin
      Result := R;
      Result.Data := Data;
      Exit;
    end;
    Command := Default (TApduCommand);
    Command.CLA := C.CLA;
    Command.INS := $C0;
    Command.HasLe := True;
    Command.Le := (R.StatusWord and $FF);
    if Command.Le = 0 then
      Command.Le := 256;
    Corrected := False;
  end;
  Fail;
end;

function TCalypsoCardReader.SelectFile(const Id: Word): TApduResponse;
var
  C: TApduCommand;
begin
  C := Default (TApduCommand);
  if FDialect = cdLegacy94 then
    C.CLA := $94;
  if FDialect = cdIso00 then
    C.P1 := $09;
  C.INS := $A4;
  SetLength(C.Data, 2);
  C.Data[0] := Byte(Id shr 8);
  C.Data[1] := Byte(Id and $FF);
  C.HasLe := True;
  C.Le := 256;
  Result := Exchange(C);
end;

function TCalypsoCardReader.ReadFileInternal(const Id: Word;
  const Limit: Integer): TCalypsoFile;
var
  R: TApduResponse;
  C: TApduCommand;
  N, I: Integer;
begin
  Result := Default (TCalypsoFile);
  Result.LogicalId := Id;
  R := SelectFile(Id);
  Result.SelectionStatus := R.StatusWord;
  case R.StatusWord of
    $6A82, $6982, $6985:
      Exit;
    $9000:
      ;
  else
    raise ECalypsoStatusError.Create(R.StatusWord);
  end;
  Result.SelectionData := R.Data;
  OpenSecureSession(R.Data);
  for N := 1 to Limit do
  begin
    C := Default (TApduCommand);
    if FDialect = cdLegacy94 then
      C.CLA := $94;
    C.INS := $B2;
    C.P1 := Byte(N);
    C.P2 := 4;
    C.HasLe := True;
    C.Le := Cardinal(FRecordBytes);
    R := Exchange(C);
    Result.LastRecordStatus := R.StatusWord;
    case R.StatusWord of
      $6A83, $6982, $6985:
        Exit;
      $9000:
        ;
    else
      raise ECalypsoStatusError.Create(R.StatusWord);
    end;
    if (Length(R.Data) = 0) or (Length(R.Data) > 256) then
      Fail;
    I := Length(Result.Records);
    SetLength(Result.Records, I + 1);
    Result.Records[I].Number := Byte(N);
    Result.Records[I].Data := R.Data;
  end;
  Result.Truncated := True;
end;

function TCalypsoCardReader.ReadFile(const ALogicalId: Word;
  const AMaxRecords: Integer): TCalypsoFile;
var
  T: ICardTransaction;
  D: TCalypsoFile;
  Success: Boolean;
begin
  Result := Default (TCalypsoFile);
  if (ALogicalId = 0) or (AMaxRecords < 1) or (AMaxRecords > 255) then
    Fail;
  T := BeginRead;
  Success := False;
  try
    OpenSecureSession(nil);
    D := ReadFileInternal(ALogicalId, AMaxRecords);
    Success := True;
  finally
    EndRead(T, Success);
  end;
  Result := D;
end;

function TCalypsoCardReader.ReadMobib(const AMaxRecordsPerFile: Integer)
  : TMobibSnapshot;
const
  Ids: array [0 .. 7] of Word = ($2001, $2002, $2010, $2020, $2069, $2050,
    $2040, $3F1C);
begin
  Result := ReadMobibFiles(Ids, AMaxRecordsPerFile);
end;

function TCalypsoCardReader.ReadMobibFiles(const ALogicalIds: array of Word;
  const AMaxRecordsPerFile: Integer): TMobibSnapshot;
var
  T: ICardTransaction;
  D: TMobibSnapshot;
  R: TApduResponse;
  Success: Boolean;
  I, J: Integer;
begin
  Result := Default (TMobibSnapshot);
  D := Default (TMobibSnapshot);
  if (AMaxRecordsPerFile < 1) or (AMaxRecordsPerFile > 255) or
    (Length(ALogicalIds) < 1) or (Length(ALogicalIds) > 64) then
    Fail;
  for I := 0 to High(ALogicalIds) do
  begin
    if ALogicalIds[I] = 0 then
      Fail;
    for J := 0 to I - 1 do
      if ALogicalIds[I] = ALogicalIds[J] then
        Fail;
  end;
  T := BeginRead;
  Success := False;
  try
    R := SelectFile($2000);
    if R.StatusWord <> $9000 then
      raise ECalypsoStatusError.Create(R.StatusWord);
    D.TicketingSelection := R.Data;
    OpenSecureSession(R.Data);
    SetLength(D.Files, Length(ALogicalIds));
    for I := 0 to High(ALogicalIds) do
      D.Files[I] := ReadFileInternal(ALogicalIds[I], AMaxRecordsPerFile);
    Success := True;
  finally
    EndRead(T, Success);
  end;
  Result := D;
end;

end.
