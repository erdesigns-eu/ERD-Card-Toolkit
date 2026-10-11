unit ERD.Card.Memory.Workflow;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Memory, ERD.Card.Transport;

type
  /// <summary>Contact-memory access contract with immutable explicit geometry and no fabricated UID.</summary>
  /// <remarks>Caller exclusively owns the presented card for each phase. Public SLE/I2C memory
  /// has no general unique identifier, so replacement cannot be detected from a UID. Failed
  /// post-dispatch writes must raise EMemoryCardWriteUncertain; never replay them.</remarks>
  IContactMemoryWorkflowCard = interface
    ['{27A59745-A6B1-4254-BCE1-66C59BDAF5B4}']
    /// <summary>Returns explicit model without I/O.</summary>
    /// <returns>Configured SLE or I2C model.</returns>
    function Model: TMemoryCardModel;
    /// <summary>Returns physical I2C page size without I/O.</summary>
    /// <returns>Configured page-size enum.</returns>
    function PageSize: TMemoryCardPageSize;
    /// <summary>Returns required remaining PIN attempts without I/O.</summary>
    /// <returns>One through eight attempts.</returns>
    function MinimumPinAttempts: Integer;
    /// <summary>Reads complete memory, protection and available retry counters; never authenticates.</summary>
    /// <returns>Complete independently allocated snapshot, or raises.</returns>
    function ReadSnapshot: TMemoryCardSnapshot;
    /// <summary>Reads one complete range without changing protection or authenticating.</summary>
    /// <param name="AAddress">Physical byte offset.</param>
    /// <param name="ACount">Bounded positive byte count.</param>
    /// <returns>Independent exact bytes.</returns>
    function ReadRange(const AAddress, ACount: Integer): TBytes;
    /// <summary>Writes a range once, checking live protection/retry budgets and verifying every native chunk.</summary>
    /// <param name="AAddress">Physical byte offset.</param>
    /// <param name="AData">Exact requested bytes.</param>
    /// <param name="APin">Borrowed read-only two/three-byte PIN, or empty for unsecured models; never retain it.</param>
    procedure WriteRange(const AAddress: Integer; const AData, APin: TBytes);
  end;
  /// <summary>Inactive adapter retaining a caller-owned native contact-memory reader.</summary>
  /// <remarks>Reader must outlive all adapters/workflows. Configuration changes are refused.
  /// Native reads are public; writes use only the supplied PIN, with no guessing or retries.</remarks>
  TContactMemoryWorkflowCard = class(TInterfacedObject, IContactMemoryWorkflowCard)
  private
    FReader: TMemoryCardReaderWriter;
    FTransport: ICardTransport;
    FModel: TMemoryCardModel;
    FPage: TMemoryCardPageSize;
    FDialect: TAcsMemoryDialect;
    FMinimum: Integer;
    procedure CheckConfiguration;
  public
    /// <summary>Captures explicit configuration without opening or selecting a card.</summary>
    /// <param name="AReader">Inactive caller-owned reader, used on one thread.</param>
    constructor Create(const AReader: TMemoryCardReaderWriter);
    /// <summary>Returns frozen model without I/O.</summary>
    /// <returns>Configured model.</returns>
    function Model: TMemoryCardModel;
    /// <summary>Returns frozen page geometry without I/O.</summary>
    /// <returns>Configured page size.</returns>
    function PageSize: TMemoryCardPageSize;
    /// <summary>Returns frozen retry-budget threshold without I/O.</summary>
    /// <returns>Minimum remaining attempts.</returns>
    function MinimumPinAttempts: Integer;
    /// <summary>Acquires a complete public snapshot after checking reader configuration.</summary>
    /// <returns>Independent snapshot after successful release.</returns>
    function ReadSnapshot: TMemoryCardSnapshot;
    /// <summary>Acquires one complete public byte range.</summary>
    /// <param name="AAddress">First physical byte.</param>
    /// <param name="ACount">Positive bounded count.</param>
    /// <returns>Independent bytes after release.</returns>
    function ReadRange(const AAddress, ACount: Integer): TBytes;
    /// <summary>Uses native guarded writing with independently supplied credentials.</summary>
    /// <param name="AAddress">First physical byte.</param>
    /// <param name="AData">Nonempty bytes.</param>
    /// <param name="APin">Explicit PIN or empty for unsecured models.</param>
    procedure WriteRange(const AAddress: Integer; const AData, APin: TBytes);
  end;
  /// <summary>Complete contact-memory snapshot codec; protection and counters are diagnostic only.</summary>
  TContactMemoryWorkflowArchive = class
  public
    /// <summary>Checks a complete snapshot without card I/O.</summary>
    /// <param name="ASnapshot">Complete model, data, protection and retry metadata.</param>
    class procedure Validate(const ASnapshot: TMemoryCardSnapshot); static;
    /// <summary>Encodes bounded ASCII memory/protection metadata without PINs or invented identifiers.</summary>
    /// <param name="ASnapshot">Complete independent snapshot.</param>
    /// <returns>ERD-CONTACT-MEMORY 1 text.</returns>
    class function Encode(const ASnapshot: TMemoryCardSnapshot): string; static;
    /// <summary>Decodes exact bounded ASCII input; diagnostic protection is never applied during restore.</summary>
    /// <param name="AText">At most 300000 ASCII characters.</param>
    /// <returns>Complete independently allocated snapshot.</returns>
    class function Decode(const AText: string): TMemoryCardSnapshot; static;
  end;
  /// <summary>Complete backup and selected-range copy/compare/restore for ordinary SLE/I2C memory.</summary>
  /// <remarks>All readable source/target memory and target protection are acquired before writing.
  /// Only differing contiguous runs are written, with physical page/chunk boundaries. Source
  /// protection, retry counters and PINs are never restored. PINs are copied and wiped after
  /// execution; each differing run may require a fresh native authentication. No PIN retry,
  /// irreversible lock, PIN replacement, synthesized identity, rollback or automatic replay.
  /// Results retain verified earlier runs when a later write fails. Execute on one owning thread.</remarks>
  TContactMemoryWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: IContactMemoryWorkflowCard;
    FSnapshot: TMemoryCardSnapshot;
    FResults: TCardWorkflowUnits;
    FPin: TBytes;
    FAddress, FCount: Integer;
    FPrepared, FConsumed, FCompare: Boolean;
    function GetSnapshot: TMemoryCardSnapshot;
    function GetResults: TCardWorkflowUnits;
    procedure WipePin;
    procedure Configure(const ASource, ATarget: IContactMemoryWorkflowCard;
      const AModel: TMemoryCardModel; const AAddress, ACount: Integer;
      const APin: TBytes; const ACompareOnly: Boolean);
  protected
    /// <summary>Checks the single-use prepared request without I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Acquires complete snapshots, preflights all differing bytes and verifies writes.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Wipes retained PIN bytes.</summary>
    destructor Destroy; override;
    /// <summary>Prepares a complete public-memory backup without authentication.</summary>
    /// <param name="ASource">Retained source backend.</param>
    procedure PrepareBackup(const ASource: IContactMemoryWorkflowCard);
    /// <summary>Prepares selected-byte data migration or comparison.</summary>
    /// <param name="ASource">Source backend.</param>
    /// <param name="ATarget">Compatible target backend.</param>
    /// <param name="AAddress">First byte.</param>
    /// <param name="ACount">Nonempty range within model capacity.</param>
    /// <param name="APin">Target PIN; empty only for unsecured models or comparison.</param>
    /// <param name="ACompareOnly">True performs no writes or authentication.</param>
    procedure PrepareCopy(const ASource, ATarget: IContactMemoryWorkflowCard;
      const AAddress, ACount: Integer; const APin: TBytes;
      const ACompareOnly: Boolean = False);
    /// <summary>Prepares selected-byte restoration from a complete snapshot.</summary>
    /// <param name="ASnapshot">Complete source image; independently copied.</param>
    /// <param name="ATarget">Compatible target backend.</param>
    /// <param name="AAddress">First byte.</param>
    /// <param name="ACount">Nonempty selected byte count.</param>
    /// <param name="APin">Target PIN, or empty for comparison/unsecured models.</param>
    /// <param name="ACompareOnly">True only acquires differences.</param>
    procedure PrepareRestore(const ASnapshot: TMemoryCardSnapshot;
      const ATarget: IContactMemoryWorkflowCard; const AAddress, ACount: Integer;
      const APin: TBytes; const ACompareOnly: Boolean = False);
    /// <summary>Independent complete source snapshot; unavailable when acquisition failed.</summary>
    property Snapshot: TMemoryCardSnapshot read GetSnapshot;
    /// <summary>Independent differing byte-run results; empty when the selected bytes already match.</summary>
    property Results: TCardWorkflowUnits read GetResults;
  end;

implementation

procedure Invalid;
begin raise ECardWorkflowError.Create('Invalid contact-memory workflow request.'); end;

function Clone(const S: TMemoryCardSnapshot): TMemoryCardSnapshot;
begin Result := S; Result.Data := CopyBytes(S.Data); Result.Protection := CopyBytes(S.Protection); end;

constructor TContactMemoryWorkflowCard.Create(const AReader: TMemoryCardReaderWriter);
begin
  inherited Create;
  if AReader = nil then Invalid;
  FReader := AReader; FTransport := AReader.Transport; FModel := AReader.Model; FPage := AReader.PageSize;
  FDialect := AReader.Dialect; FMinimum := AReader.MinimumPinAttempts;
end;
procedure TContactMemoryWorkflowCard.CheckConfiguration;
begin
  if (FReader.Transport <> FTransport) or (FReader.Model <> FModel) or (FReader.PageSize <> FPage) or
    (FReader.Dialect <> FDialect) or (FReader.MinimumPinAttempts <> FMinimum) then Invalid;
end;
function TContactMemoryWorkflowCard.Model: TMemoryCardModel;
begin Result := FModel; end;
function TContactMemoryWorkflowCard.PageSize: TMemoryCardPageSize;
begin Result := FPage; end;
function TContactMemoryWorkflowCard.MinimumPinAttempts: Integer;
begin Result := FMinimum; end;
function TContactMemoryWorkflowCard.ReadSnapshot: TMemoryCardSnapshot;
begin CheckConfiguration; Result := FReader.ReadSnapshot; end;
function TContactMemoryWorkflowCard.ReadRange(const AAddress, ACount: Integer): TBytes;
begin CheckConfiguration; Result := FReader.ReadMemory(AAddress, ACount); end;
procedure TContactMemoryWorkflowCard.WriteRange(const AAddress: Integer; const AData, APin: TBytes);
begin CheckConfiguration; FReader.WriteMemory(AAddress, AData, APin); end;

class procedure TContactMemoryWorkflowArchive.Validate(const ASnapshot: TMemoryCardSnapshot);
var L: TMemoryCardLayout; Counter: TBytes; Decoded: TMemoryCardSecurityStatus;
begin
  L := TMemoryCardCodec.Layout(ASnapshot.Model);
  if (Length(ASnapshot.Data) <> L.Capacity) or
    (Length(ASnapshot.Protection) <> (L.ProtectableBytes + 7) div 8) or
    (ASnapshot.HasSecurity <> (L.PinBytes <> 0)) then Invalid;
  if ASnapshot.HasSecurity then
  begin
    Counter := nil; SetLength(Counter, L.PinBytes + 1); Counter[0] := ASnapshot.Security.Counter;
    Decoded := TMemoryCardCodec.DecodeSecurity(ASnapshot.Model, Counter);
    if (Decoded.RemainingAttempts <> ASnapshot.Security.RemainingAttempts) or
      (Decoded.Blocked <> ASnapshot.Security.Blocked) then Invalid;
  end;
end;
class function TContactMemoryWorkflowArchive.Encode(const ASnapshot: TMemoryCardSnapshot): string;
var P, C: string;
begin
  Validate(ASnapshot); P := '-'; C := '-';
  if Length(ASnapshot.Protection) > 0 then P := BytesToHex(ASnapshot.Protection);
  if ASnapshot.HasSecurity then C := IntToStr(ASnapshot.Security.Counter);
  Result := 'ERD-CONTACT-MEMORY 1' + #13#10 + IntToStr(Ord(ASnapshot.Model)) + #13#10 +
    BytesToHex(ASnapshot.Data) + #13#10 + P + #13#10 + C + #13#10;
end;
class function TContactMemoryWorkflowArchive.Decode(const AText: string): TMemoryCardSnapshot;
var Lines: TStringList; I, M, C: Integer; Counter: TBytes; L: TMemoryCardLayout;
begin
  Result := Default(TMemoryCardSnapshot);
  if (Length(AText) < 1) or (Length(AText) > 300000) then Invalid;
  for I := 1 to Length(AText) do if not (Ord(AText[I]) in [10, 13, 32 .. 126]) then Invalid;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count <> 5) or (Lines[0] <> 'ERD-CONTACT-MEMORY 1') then Invalid;
    if not TryStrToInt(Lines[1], M) then Invalid;
    if (M < Ord(Low(TMemoryCardModel))) or (M > Ord(High(TMemoryCardModel))) or
      (IntToStr(M) <> Lines[1]) then Invalid;
    Result.Model := TMemoryCardModel(M); L := TMemoryCardCodec.Layout(Result.Model);
    Result.Data := HexToBytes(Lines[2]);
    if Lines[3] <> '-' then Result.Protection := HexToBytes(Lines[3]);
    Result.HasSecurity := L.PinBytes <> 0;
    if Result.HasSecurity then
    begin
      if not TryStrToInt(Lines[4], C) then Invalid;
      if (C < 0) or (C > 255) or (IntToStr(C) <> Lines[4]) then Invalid;
      SetLength(Counter, L.PinBytes + 1); Counter[0] := C;
      Result.Security := TMemoryCardCodec.DecodeSecurity(Result.Model, Counter);
    end
    else if Lines[4] <> '-' then Invalid;
    Validate(Result);
    if Encode(Result) <> StringReplace(StringReplace(AText, #13#10, #10, [rfReplaceAll]),
      #10, #13#10, [rfReplaceAll]) then Invalid;
  finally Lines.Free; end;
end;
procedure TContactMemoryWorkflow.WipePin;
var I: Integer;
begin for I := 0 to High(FPin) do FPin[I] := 0; FPin := nil; end;
destructor TContactMemoryWorkflow.Destroy;
begin WipePin; inherited; end;
procedure TContactMemoryWorkflow.Configure(const ASource, ATarget: IContactMemoryWorkflowCard;
  const AModel: TMemoryCardModel; const AAddress, ACount: Integer;
  const APin: TBytes; const ACompareOnly: Boolean);
var L: TMemoryCardLayout;
begin
  RequireIdle; L := TMemoryCardCodec.Layout(AModel);
  if (AAddress < 0) or (AAddress >= L.Capacity) or (ACount < 1) or
    (ACount > L.Capacity - AAddress) or ((ASource = nil) and (ATarget = nil)) then Invalid;
  if (ASource <> nil) and (ASource.Model <> AModel) then Invalid;
  if ATarget <> nil then
  begin
    if (ATarget.Model <> AModel) or not (ATarget.PageSize in [mps8 .. mps128]) or
      (ATarget.MinimumPinAttempts < 1) or (ATarget.MinimumPinAttempts > 8) then Invalid;
    if not ACompareOnly and (Length(APin) <> L.PinBytes) then Invalid;
  end;
  if ACompareOnly and (Length(APin) <> 0) then Invalid;
  WipePin; FPin := CopyBytes(APin); FSource := ASource; FTarget := ATarget;
  FAddress := AAddress; FCount := ACount; FCompare := ACompareOnly;
  FResults := nil; FPrepared := True; FConsumed := False;
end;
procedure TContactMemoryWorkflow.PrepareBackup(const ASource: IContactMemoryWorkflowCard);
begin
  if ASource = nil then Invalid;
  Configure(ASource, nil, ASource.Model, 0, TMemoryCardCodec.Layout(ASource.Model).Capacity, nil, False);
  FSnapshot := Default(TMemoryCardSnapshot);
end;
procedure TContactMemoryWorkflow.PrepareCopy(const ASource, ATarget: IContactMemoryWorkflowCard;
  const AAddress, ACount: Integer; const APin: TBytes; const ACompareOnly: Boolean);
begin
  if (ASource = nil) or (ATarget = nil) then Invalid;
  Configure(ASource, ATarget, ASource.Model, AAddress, ACount, APin, ACompareOnly);
  FSnapshot := Default(TMemoryCardSnapshot);
end;
procedure TContactMemoryWorkflow.PrepareRestore(const ASnapshot: TMemoryCardSnapshot;
  const ATarget: IContactMemoryWorkflowCard; const AAddress, ACount: Integer;
  const APin: TBytes; const ACompareOnly: Boolean);
begin
  if ATarget = nil then Invalid;
  TContactMemoryWorkflowArchive.Validate(ASnapshot);
  Configure(nil, ATarget, ASnapshot.Model, AAddress, ACount, APin, ACompareOnly);
  FSnapshot := Clone(ASnapshot);
end;
procedure TContactMemoryWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
function TContactMemoryWorkflow.GetSnapshot: TMemoryCardSnapshot;
begin Result := Clone(FSnapshot); end;
function TContactMemoryWorkflow.GetResults: TCardWorkflowUnits;
var I: Integer;
begin
  Result := nil; SetLength(Result, Length(FResults));
  for I := 0 to High(FResults) do begin Result[I] := FResults[I]; Result[I].Data := CopyBytes(FResults[I].Data); end;
end;
procedure TContactMemoryWorkflow.DoExecute;
var Target: TMemoryCardSnapshot; L: TMemoryCardLayout; P, Start, N, Size, I, J: Integer;
  Acquired: TMemoryCardSnapshot;
begin
  FConsumed := True;
  try
    if FSource <> nil then
    begin
      if not RequestCard(cwrSource) then begin Cancel; Exit; end;
      Progress(cwsReading, 0, 1); if CancelRequested then Exit;
      Acquired := FSource.ReadSnapshot; TContactMemoryWorkflowArchive.Validate(Acquired);
      if Acquired.Model <> FSource.Model then Invalid;
      FSnapshot := Clone(Acquired); Progress(cwsReading, 1, 1);
    end;
    if FTarget = nil then Exit;
    if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Progress(cwsChecking, 0, FCount); if CancelRequested then Exit;
    Target := FTarget.ReadSnapshot; TContactMemoryWorkflowArchive.Validate(Target);
    if Target.Model <> FSnapshot.Model then Invalid;
    L := TMemoryCardCodec.Layout(Target.Model); Size := MemoryCardChunkBytes;
    if L.Selector <= 2 then Size := 8 shl Ord(FTarget.PageSize);
    P := FAddress;
    while P < FAddress + FCount do
    begin
      if Target.Data[P] = FSnapshot.Data[P] then begin Inc(P); Continue; end;
      Start := P; N := 0;
      while (P < FAddress + FCount) and (N < MemoryCardChunkBytes) and
        ((P div Size) = (Start div Size)) and (Target.Data[P] <> FSnapshot.Data[P]) do
      begin
        if not FCompare and (P < L.ProtectableBytes) and
          ((Target.Protection[P div 8] and (1 shl (P mod 8))) = 0) then
          raise ECardWorkflowError.Create('A differing target byte is permanently protected.');
        Inc(P); Inc(N);
      end;
      I := Length(FResults); SetLength(FResults, I + 1);
      FResults[I].Address := Start; FResults[I].Data := Copy(FSnapshot.Data, Start, N);
      FResults[I].State := cwusPending;
    end;
    if not FCompare and (Length(FResults) > 0) and Target.HasSecurity and
      (Target.Security.RemainingAttempts < FTarget.MinimumPinAttempts) then
      raise ECardWorkflowError.Create('Insufficient target PIN retry budget.');
    Progress(cwsChecking, FCount, FCount);
    if FCompare or CancelRequested then Exit;
    for I := 0 to High(FResults) do
    begin
      if CancelRequested then Exit;
      Progress(cwsWriting, I, Length(FResults)); if CancelRequested then Exit;
      MutationPending(True); FResults[I].State := cwusUncertain;
      try
        FTarget.WriteRange(FResults[I].Address, CopyBytes(FResults[I].Data), FPin);
      except
        on E: EMemoryCardWriteUncertain do
        begin
          if E.Verified then FResults[I].State := cwusVerified;
          raise;
        end;
        on E: Exception do begin MutationPending(False); FResults[I].State := cwusPending; raise; end;
      end;
      Progress(cwsVerifying, I, Length(FResults));
      if not BytesEqual(FTarget.ReadRange(FResults[I].Address, Length(FResults[I].Data)), FResults[I].Data) then
        raise ECardWorkflowError.Create('Contact-memory read-back mismatch.');
      FResults[I].State := cwusVerified; MutationPending(False);
      Progress(cwsVerifying, I + 1, Length(FResults));
    end;
  finally
    for J := 0 to High(FPin) do FPin[J] := 0;
    WipePin;
  end;
end;

end.
