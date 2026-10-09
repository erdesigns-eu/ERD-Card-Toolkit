unit ERD.Card.Demo.Job;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes, System.SyncObjs,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.PCSC.Api, ERD.Card.MagStripe.Tracks,
  ERD.Card.MagStripe, ERD.Card.Contactless.Type2, ERD.Card.EID.Access,
  ERD.Card.Crypto.EAC, ERD.Card.Memory, ERD.Card.Memory.Counter;

type
{$IFDEF FPC}
  /// <summary>RTL critical-section storage used by the headless FPC worker tests.</summary>
  TCardDemoLock = TRTLCriticalSection;
{$ELSE}
  /// <summary>Delphi RTL critical section for polling publication.</summary>
  TCardDemoLock = TCriticalSection;
{$ENDIF}
  /// <summary>Explicit demo operation; no automatic probing, fallback or payment processing.</summary>
  TCardDemoOperation = (
    /// <summary>Enumerate PC/SC readers without connecting a card.</summary>
    cdoReaders,
    /// <summary>Read UID with the explicit PC/SC storage profile.</summary>
    cdoUid,
    /// <summary>Read Belgian contact identity, address and JPEG photo.</summary>
    cdoBelgianEid,
    /// <summary>Read ICAO DG1/DG2 using explicitly configured BAC or PACE.</summary>
    cdoIcao,
    /// <summary>Discover contact EMV PSE applications.</summary>
    cdoEmvPse,
    /// <summary>Discover contactless EMV PPSE applications.</summary>
    cdoEmvPpse,
    /// <summary>Read public native DESFire version.</summary>
    cdoDesfireVersion,
    /// <summary>Read public Type 2 NDEF for the selected model.</summary>
    cdoType2Read,
    /// <summary>Read the unique public Type 4 mapping 2.0 NDEF file.</summary>
    cdoType4Read,
    /// <summary>Replace Type 2 NDEF with verified read-back.</summary>
    cdoType2Write,
    /// <summary>Replace Type 4 mapping 2.0 NDEF with verified read-back.</summary>
    cdoType4Write,
    /// <summary>Decode NDEF bytes without hardware.</summary>
    cdoNdefInspect,
    /// <summary>Validate selected raw tracks and calculate bit-frame lengths offline.</summary>
    cdoTrackInspect,
    /// <summary>Read one swipe with the explicit MSR206-7HL adapter.</summary>
    cdoTrackRead,
    /// <summary>Program selected tracks with independent MSR206-7HL read-back verification.</summary>
    cdoTrackWrite,
    /// <summary>Inspect explicit ACS memory-profile capabilities offline.</summary>
    cdoMemoryCapabilities,
    /// <summary>Read the connected card ATR and negotiated protocol without selecting a memory profile.</summary>
    cdoReaderStatus,
    /// <summary>Read ordinary main memory and protection without a PIN attempt.</summary>
    cdoMemorySnapshot,
    /// <summary>Read a bounded ordinary-memory range.</summary>
    cdoMemoryRead,
    /// <summary>Verify one supplied ordinary-memory PIN using the configured retry budget.</summary>
    cdoMemoryVerify,
    /// <summary>Write a selected ordinary-memory range with independent read-back.</summary>
    cdoMemoryWrite,
    /// <summary>Read a caller-declared public counter-chip range through ACR38x CCID.</summary>
    cdoCounterRead,
    /// <summary>Read an explicit public SLE4404 range through ACR38x CCID.</summary>
    cdoSle4404Read,
    /// <summary>Execute one explicit operation in the separately selected family demo.</summary>
    cdoFamily
  );
  /// <summary>Non-secret named-form values in catalog field order; strings use copy-on-write.</summary>
  TCardDemoArguments = array of UnicodeString;
  /// <summary>Credential buffers aligned with form fields; each worker copy is independently owned and wiped.</summary>
  TCardDemoCredentials = array of TBytes;
  /// <summary>One explicit request copied by the job before its worker starts.</summary>
  TCardDemoRequest = record
    /// <summary>Single operation, executed once.</summary>
    Operation: TCardDemoOperation;
    /// <summary>Exact family catalog name; validated against the injected executor.</summary>
    FamilyName: string;
    /// <summary>Explicit zero-based catalog operation; no implicit action.</summary>
    FamilyAction: Integer;
    /// <summary>Non-secret input values aligned with the selected action's field definitions.</summary>
    Arguments: TCardDemoArguments;
    /// <summary>Secret decoded bytes aligned with fields; matching Arguments entries must be empty.</summary>
    Credentials: TCardDemoCredentials;
    /// <summary>Explicit per-action acknowledgement of writes, code attempts, erases or permanent changes.</summary>
    MutationAcknowledged: Boolean;
    /// <summary>Exact PC/SC reader name; no default selection.</summary>
    ReaderName: UnicodeString;
    /// <summary>Complete NDEF message bytes, copied at the thread boundary.</summary>
    NdefBytes: TBytes;
    /// <summary>Explicit Type 2 memory layout.</summary>
    Type2Model: TType2TagModel;
    /// <summary>Explicit ICAO access protocol; no downgrade.</summary>
    Security: TIcaoAccessSecurity;
    /// <summary>MRZ information or six-digit CAN, as appropriate for Security.</summary>
    PasswordKind: TIcaoPasswordKind;
    /// <summary>PACE ECDH-GM domain parameter 12 or 13.</summary>
    PaceCurve: TCardPaceCurve;
    /// <summary>ICAO access bytes or card-order memory PIN; the job wipes its owned copy on completion.</summary>
    Password: TBytes;
    /// <summary>OpenSSL 3 library path; empty uses provider default.</summary>
    CryptoLibrary: string;
    /// <summary>Explicit Windows COM port for MSR206-7HL.</summary>
    PortName: string;
    /// <summary>Nonempty explicit physical track selection.</summary>
    TrackSelection: TMagStripeTrackSet;
    /// <summary>Unframed selected-track payloads; no sentinels or LRC.</summary>
    Tracks: TMagStripeTracks;
    /// <summary>Low or high coercivity for writes; current is refused by the demo.</summary>
    Coercivity: TMagStripeCoercivity;
    /// <summary>Serial swipe deadline in milliseconds, from 1 through 600000.</summary>
    TimeoutMs: Cardinal;
    /// <summary>Explicit ordinary-memory chip geometry.</summary>
    MemoryModel: TMemoryCardModel;
    /// <summary>Explicit ACS reader command/response dialect.</summary>
    MemoryDialect: TAcsMemoryDialect;
    /// <summary>Known physical I2C page size for writes.</summary>
    MemoryPageSize: TMemoryCardPageSize;
    /// <summary>Minimum remaining ordinary SLE PIN attempts before verification or writing.</summary>
    MinimumPinAttempts: Integer;
    /// <summary>Zero-based address for an explicit memory range.</summary>
    MemoryAddress: Integer;
    /// <summary>Positive byte count for a memory read.</summary>
    MemoryCount: Integer;
    /// <summary>Selected write payload, copied before the worker starts.</summary>
    MemoryBytes: TBytes;
    /// <summary>Explicit SLE counter-chip profile.</summary>
    CounterModel: TSleCounterModel;
    /// <summary>Caller-declared counter/SLE4404 readable window, one through 256 bytes.</summary>
    CounterReadableBytes: Integer;
  end;
  /// <summary>One owned acquired/demo file available for explicit local export.</summary>
  TCardDemoArtifact = record
    /// <summary>Suggested plain filename generated by the demo, never a caller path.</summary>
    Name: string;
    /// <summary>Exact file bytes, retained only for a completed successful result.</summary>
    Data: TBytes;
  end;
  /// <summary>Owned file list; ordinary assignment shares buffers.</summary>
  TCardDemoArtifacts = array of TCardDemoArtifact;
  /// <summary>Completed worker output, including explicitly exportable acquired files.</summary>
  TCardDemoResult = record
    /// <summary>Operation that produced this completion.</summary>
    Operation: TCardDemoOperation;
    /// <summary>True only if the operation and its cleanup completed successfully.</summary>
    Success: Boolean;
    /// <summary>True after component write verification, even if later disconnect fails.</summary>
    WriteVerified: Boolean;
    /// <summary>A dispatched write has an uncertain outcome or cleanup; never retry automatically.</summary>
    WriteUncertain: Boolean;
    /// <summary>Exception class only; credential-bearing exception messages are not copied.</summary>
    ErrorClass: string;
    /// <summary>Display text; may contain identity or UID data from the selected operation.</summary>
    Text: UnicodeString;
    /// <summary>Reader names returned by explicit enumeration.</summary>
    Readers: TPcscReaderNames;
    /// <summary>First acquired face image, or Belgian photo; empty when absent.</summary>
    Photo: TBytes;
    /// <summary>Exact successful acquired files for explicit local export, never automatically written.</summary>
    Artifacts: TCardDemoArtifacts;
    /// <summary>JPEG 2000 when true; JPEG otherwise. No image conversion is attempted.</summary>
    PhotoIsJpeg2000: Boolean;
    /// <summary>Complete acquired or inspected NDEF wire message.</summary>
    NdefBytes: TBytes;
    /// <summary>Acquired swipe or verified written payloads, indexed by track.</summary>
    Tracks: TMagStripeTracks;
    /// <summary>Owned ordinary-memory data, protection and retry status; no supplied PIN copies.</summary>
    Memory: TMemoryCardSnapshot;
    /// <summary>Owned public counter/SLE4404 range; ordinary-memory geometry does not apply.</summary>
    CounterBytes: TBytes;
  end;
  /// <summary>Worker-only operation executor; implementations must not access VCL controls.</summary>
  ICardDemoOperations = interface
    ['{D078B61F-065D-4A8B-9829-BB0F6B2C52B8}']
    /// <summary>Executes exactly one request on the job's worker thread.</summary>
    /// <param name="ARequest">Job-owned request, valid until Run returns; do not retain buffers.</param>
    /// <param name="AResult">Owned data; WriteVerified survives a later cleanup exception.</param>
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;
  /// <summary>One non-cancelling worker with polling completion and no queued UI callbacks.</summary>
  /// <remarks>Free joins the worker. Poll to completion before freeing on the UI thread.
  /// Closing a form must wait for an active write; termination cannot establish card state.</remarks>
  TCardDemoJob = class(TThread)
  private
    FLock: TCardDemoLock;
    FLockReady, FStarted, FDone, FDelivered: Boolean;
    FRequest: TCardDemoRequest;
    FResult: TCardDemoResult;
    FOperations: ICardDemoOperations;
    procedure Lock;
    procedure Unlock;
  protected
    /// <summary>Runs one operation, sanitizes failure details and publishes completion under a lock.</summary>
    procedure Execute; override;
  public
    /// <summary>Copies request buffers into a suspended worker; call StartWork after construction returns.</summary>
    /// <param name="ARequest">Caller-owned request; later caller edits do not affect the job.</param>
    /// <param name="AOperations">Non-nil worker executor, retained until worker completion.</param>
    constructor Create(const ARequest: TCardDemoRequest; const AOperations: ICardDemoOperations);
    /// <summary>Starts the fully constructed worker exactly once on the caller thread.</summary>
    /// <exception cref="EInvalidOpException">This job has already been started.</exception>
    /// <remarks>Do not call inherited Start directly or start from a constructor: Delphi's
    /// TThread.AfterConstruction must complete its suspended-thread initialization first.</remarks>
    procedure StartWork;
    /// <summary>Joins the worker, clears owned access bytes and releases its lock.</summary>
    destructor Destroy; override;
    /// <summary>Moves completed data to the caller once without waiting for a running operation.</summary>
    /// <param name="AResult">Replaced only on success; caller owns returned arrays.</param>
    /// <returns>True once, after the worker has finished using hardware and buffers.</returns>
    function TryTakeResult(var AResult: TCardDemoResult): Boolean;
  end;

implementation

uses ERD.Card.Crypto;

constructor TCardDemoJob.Create(const ARequest: TCardDemoRequest;
  const AOperations: ICardDemoOperations);
var I: Integer;
begin
  inherited Create(True);
  FreeOnTerminate := False;
{$IFDEF FPC}
  InitCriticalSection(FLock);
{$ELSE}
  FLock := TCriticalSection.Create;
{$ENDIF}
  FLockReady := True;
  if AOperations = nil then raise EArgumentException.Create('Worker executor is required.');
  FRequest := ARequest;
  FRequest.Password := nil; FRequest.NdefBytes := nil; FRequest.MemoryBytes := nil;
  FRequest.Arguments := nil; FRequest.Credentials := nil;
  FRequest.Arguments := Copy(ARequest.Arguments,0,Length(ARequest.Arguments));
  SetLength(FRequest.Credentials,Length(ARequest.Credentials));
  for I := 0 to High(ARequest.Credentials) do FRequest.Credentials[I] := CopyBytes(ARequest.Credentials[I]);
  FRequest.Password := Copy(ARequest.Password, 0, Length(ARequest.Password));
  FRequest.NdefBytes := Copy(ARequest.NdefBytes, 0, Length(ARequest.NdefBytes));
  FRequest.MemoryBytes := Copy(ARequest.MemoryBytes, 0, Length(ARequest.MemoryBytes));
  FOperations := AOperations;
end;

procedure TCardDemoJob.StartWork;
begin
  if FStarted then raise EInvalidOpException.Create('Worker has already been started.');
  FStarted := True;
  try inherited Start; except FStarted := False; raise; end;
end;

destructor TCardDemoJob.Destroy;
var I: Integer;
begin
  if FStarted then WaitFor;
  inherited Destroy;
  TCardCrypto.Clear(FRequest.Password);
  for I := 0 to High(FRequest.Credentials) do TCardCrypto.Clear(FRequest.Credentials[I]);
  if FLockReady then
{$IFDEF FPC}
    DoneCriticalSection(FLock);
{$ELSE}
    FLock.Free;
{$ENDIF}
end;

procedure TCardDemoJob.Lock;
begin
{$IFDEF FPC}
  EnterCriticalSection(FLock);
{$ELSE}
  FLock.Acquire;
{$ENDIF}
end;

procedure TCardDemoJob.Unlock;
begin
{$IFDEF FPC}
  LeaveCriticalSection(FLock);
{$ELSE}
  FLock.Release;
{$ENDIF}
end;

procedure TCardDemoJob.Execute;
var Completed: TCardDemoResult; I: Integer;
begin
  if not FStarted then Exit;
  Completed := Default(TCardDemoResult);
  Completed.Operation := FRequest.Operation;
  try
    FOperations.Run(FRequest, Completed);
    Completed.Success := True;
  except
    on E: Exception do
    begin
      Completed.Success := False;
      Completed.ErrorClass := E.ClassName; Completed.Artifacts := nil;
      if not Completed.WriteVerified then
      begin
        Completed.Text := ''; Completed.Photo := nil;
        Completed.NdefBytes := nil; Completed.Readers := nil;
        Completed.Tracks := Default(TMagStripeTracks);
        Completed.Memory := Default(TMemoryCardSnapshot); Completed.CounterBytes := nil;
      end;
    end;
  end;
  TCardCrypto.Clear(FRequest.Password);
  for I := 0 to High(FRequest.Credentials) do TCardCrypto.Clear(FRequest.Credentials[I]);
  FRequest := Default(TCardDemoRequest);
  FOperations := nil;
  Lock;
  try FResult := Completed; FDone := True;
  finally Unlock; end;
end;

function TCardDemoJob.TryTakeResult(var AResult: TCardDemoResult): Boolean;
begin
  Lock;
  try
    Result := FDone and not FDelivered;
    if Result then
    begin
      AResult := FResult;
      FResult := Default(TCardDemoResult);
      FDelivered := True;
    end;
  finally Unlock; end;
end;

end.
