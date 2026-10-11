unit ERD.Card.Memory.Workflow.Sle;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Memory,
  ERD.Card.Memory.Sle4404, ERD.Card.Memory.Counter;

type
  /// <summary>Explicit single-dispatch SLE memory operation.</summary>
  TSleWorkflowAction = (
    /// <summary>Program a SLE4404 byte range from one bits to zero bits.</summary>
    swaProgram,
    /// <summary>Erase the declared SLE4404 scratchpad.</summary>
    swaEraseScratchPad,
    /// <summary>Present both supplied codes to erase the declared SLE4404 application area.</summary>
    swaEraseApplication,
    /// <summary>Program one counter byte with explicit carry/backup effects.</summary>
    swaCounterByte);
  /// <summary>One reviewed transition; images describe the complete selected window.</summary>
  TSleWorkflowStep = record
    /// <summary>Explicit operation, never inferred from a desired zero-to-one transition.</summary>
    Action: TSleWorkflowAction;
    /// <summary>Physical byte address; erase actions require the configured area start.</summary>
    Address: Integer;
    /// <summary>Explicit counter programming mode; scwProgram for SLE4404.</summary>
    Mode: TSleCounterWriteMode;
    /// <summary>Complete original selected window, not a credential.</summary>
    Before: TBytes;
    /// <summary>Complete requested selected window, including caller-known carry effects.</summary>
    After: TBytes;
    /// <summary>SLE4404 programming count; counter actions use one, erases use the area length.</summary>
    Count: Integer;
  end;
  /// <summary>At most 256 contiguous reviewed transitions.</summary>
  TSleWorkflowSteps = array of TSleWorkflowStep;
  /// <summary>Public-memory snapshot; no implied chip UID or secret storage.</summary>
  TSleWorkflowSnapshot = record
    /// <summary>Exact explicit model, geometry and area configuration.</summary>
    Layout: string;
    /// <summary>First physical byte in the selected readable window.</summary>
    Address: Integer;
    /// <summary>Complete independently acquired selected bytes.</summary>
    Data: TBytes;
  end;
  /// <summary>Explicit physical backend; methods must not retry mutations.</summary>
  ISleWorkflowCard = interface
    ['{88843B6F-41BC-46D7-8870-C49195A30971}']
    /// <summary>Returns immutable geometry/configuration without I/O.</summary>
    /// <returns>Exact model and geometry identifier.</returns>
    function Layout: string;
    /// <summary>Returns the selected physical byte offset without I/O.</summary>
    /// <returns>Physical start byte.</returns>
    function Address: Integer;
    /// <summary>Returns one through 256 selected bytes without I/O.</summary>
    /// <returns>Positive selected readable byte count.</returns>
    function ByteCount: Integer;
    /// <summary>Validates one complete transition without authentication or I/O.</summary>
    /// <param name="AStep">Owned reviewed images and explicit action.</param>
    procedure ValidateStep(const AStep: TSleWorkflowStep);
    /// <summary>Reads the complete selected window without presenting credentials.</summary>
    /// <returns>Independent complete public memory bytes.</returns>
    function ReadWindow: TBytes;
    /// <summary>Dispatches once and requires native read-back; post-dispatch failures raise EMemoryCardWriteUncertain.</summary>
    /// <param name="AStep">Previously validated exact transition.</param>
    procedure Apply(const AStep: TSleWorkflowStep);
  end;
  /// <summary>Owned frozen SLE4404 native adapter; exclusively own the physical connection across the workflow.</summary>
  /// <remarks>Snapshot ranges exclude counters and secret code storage. Codes are copied, used only
  /// for explicitly requested mutations and wiped on destruction. Each native step authenticates once.</remarks>
  TSle4404WorkflowCard = class(TInterfacedObject, ISleWorkflowCard)
  private
    FReader: TSle4404CardReaderWriter;
    FAddress, FCount: Integer;
    FUserCode, FMemoryCode: TBytes;
  public
    /// <summary>Copies native configuration and secrets without hardware I/O.</summary>
    /// <param name="AReader">Caller-configured ACR38x reader; original may be freed afterwards.</param>
    /// <param name="AAddress">Start of an explicit public data window.</param>
    /// <param name="ACount">Positive window within declared readable geometry.</param>
    /// <param name="AUserCode">Empty for public programming, otherwise exactly two card-order bytes.</param>
    /// <param name="AMemoryCode">Empty unless application erase is requested; otherwise four bytes.</param>
    constructor Create(const AReader: TSle4404CardReaderWriter;
      const AAddress, ACount: Integer; const AUserCode, AMemoryCode: TBytes);
    /// <summary>Wipes independently retained code buffers and releases the frozen reader.</summary>
    destructor Destroy; override;
    /// <summary>Returns exact declared SLE4404 geometry and access layout.</summary>
    /// <returns>Exact model and geometry identifier.</returns>
    function Layout: string;
    /// <summary>Returns selected start address.</summary>
    /// <returns>Physical start byte.</returns>
    function Address: Integer;
    /// <summary>Returns selected byte count.</summary>
    /// <returns>Positive selected readable byte count.</returns>
    function ByteCount: Integer;
    /// <summary>Checks allowed region, one-way bits and explicit erase result without I/O.</summary>
    /// <param name="AStep">Complete reviewed transition.</param>
    procedure ValidateStep(const AStep: TSleWorkflowStep);
    /// <summary>Reads selected public bytes without consuming code attempts.</summary>
    /// <returns>Independent complete public memory bytes.</returns>
    function ReadWindow: TBytes;
    /// <summary>Executes one native verified programming or erase operation.</summary>
    /// <param name="AStep">Complete validated transition.</param>
    procedure Apply(const AStep: TSleWorkflowStep);
  end;
  /// <summary>Owned frozen counter-chip adapter; selected window is the complete declared readable memory.</summary>
  TSleCounterWorkflowCard = class(TInterfacedObject, ISleWorkflowCard)
  private
    FReader: TSleCounterCardReaderWriter;
  public
    /// <summary>Copies native model, geometry and transport without I/O.</summary>
    /// <param name="AReader">Explicit caller-identified chip and ACR38x reader.</param>
    constructor Create(const AReader: TSleCounterCardReaderWriter);
    /// <summary>Releases the owned native reader.</summary>
    destructor Destroy; override;
    /// <summary>Returns exact counter model and geometry.</summary>
    /// <returns>Exact model and geometry identifier.</returns>
    function Layout: string;
    /// <summary>Returns zero for the complete declared window.</summary>
    /// <returns>Physical start byte.</returns>
    function Address: Integer;
    /// <summary>Returns the declared readable byte count.</summary>
    /// <returns>Positive selected readable byte count.</returns>
    function ByteCount: Integer;
    /// <summary>Checks model capabilities, one-way programming and explicit carry image without I/O.</summary>
    /// <param name="AStep">Complete reviewed counter transition.</param>
    procedure ValidateStep(const AStep: TSleWorkflowStep);
    /// <summary>Reads complete public memory without presenting a code.</summary>
    /// <returns>Independent complete public memory bytes.</returns>
    function ReadWindow: TBytes;
    /// <summary>Dispatches one native write and verifies the complete expected window.</summary>
    /// <param name="AStep">Complete reviewed counter transition.</param>
    procedure Apply(const AStep: TSleWorkflowStep);
  end;
  /// <summary>Pure public-memory comparison and one-way program-plan construction.</summary>
  TSleWorkflowPlanner = class
  public
    /// <summary>Returns physical addresses of differing selected bytes without hardware I/O.</summary>
    /// <param name="ASnapshot">Complete selected source image.</param>
    /// <param name="ADesired">Complete requested image of equal length.</param>
    /// <returns>Independent ordered addresses; empty when equal.</returns>
    class function Compare(const ASnapshot: TSleWorkflowSnapshot; const ADesired: TBytes): TCardWorkflowAddresses; static;
    /// <summary>Builds exact chained one-way programming transitions; no erase or carry is inferred.</summary>
    /// <param name="ASnapshot">Complete image acquired earlier; exact backend layout and offset must match.</param>
    /// <param name="ADesired">Complete requested image; all zero-to-one changes are refused.</param>
    /// <param name="ACard">Pure native geometry/validation backend; no card I/O occurs.</param>
    /// <param name="AAction">Explicit swaProgram or swaCounterByte; counter steps use plain programming only.</param>
    /// <returns>Independent reviewed transitions; empty when equal.</returns>
    class function ProgramPlan(const ASnapshot: TSleWorkflowSnapshot; const ADesired: TBytes;
      const ACard: ISleWorkflowCard; const AAction: TSleWorkflowAction): TSleWorkflowSteps; static;
  end;
  /// <summary>Bounded canonical ASCII public-memory snapshots and explicit plans; credentials are excluded.</summary>
  TSleWorkflowArchive = class
  public
    /// <summary>Encodes a complete selected public-memory snapshot.</summary>
    /// <param name="ASnapshot">Exact layout, address and one through 256 bytes.</param>
    /// <returns>Canonical ERD-SLE-SNAPSHOT 1 text.</returns>
    class function EncodeSnapshot(const ASnapshot: TSleWorkflowSnapshot): string; static;
    /// <summary>Decodes strict canonical public-memory snapshot text.</summary>
    /// <param name="AText">At most 2048 ASCII characters.</param>
    /// <returns>Independent complete snapshot.</returns>
    class function DecodeSnapshot(const AText: string): TSleWorkflowSnapshot; static;
    /// <summary>Encodes explicit ordered before/after images without secrets.</summary>
    /// <param name="ASteps">One through 256 reviewed steps; actual chip validation is separate.</param>
    /// <returns>Canonical ERD-SLE-PLAN 1 text.</returns>
    class function EncodePlan(const ASteps: TSleWorkflowSteps): string; static;
    /// <summary>Decodes a bounded canonical explicit plan without hardware or code attempts.</summary>
    /// <param name="AText">At most 300000 ASCII characters.</param>
    /// <returns>Independent complete transitions, still requiring native chip validation.</returns>
    class function DecodePlan(const AText: string): TSleWorkflowSteps; static;
  end;
  /// <summary>Shared synchronous SLE plan lifecycle, snapshots and per-step evidence.</summary>
  /// <remarks>No general SLE UID exists. Keep the same physical card under exclusive application
  /// ownership. Resume requires exact original planned prefix state, freshly read before any write;
  /// it never guesses whether a failed command ran. Erases and carry are explicit, never rollback.</remarks>
  TSleProgrammingWorkflow = class abstract(TCardWorkflow)
  private
    FCard: ISleWorkflowCard;
    FSteps: TSleWorkflowSteps;
    FSnapshot: TSleWorkflowSnapshot;
    FResults: TCardWorkflowUnits;
    FResume: Integer;
    FPrepared, FConsumed, FPreview: Boolean;
    function GetSnapshot: TSleWorkflowSnapshot;
    function GetResults: TCardWorkflowUnits;
  protected
    /// <summary>Rejects unprepared or consumed requests before callbacks or I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Reads, checks and executes the explicit plan without retries.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares public-memory acquisition with no hardware I/O.</summary>
    /// <param name="ACard">Frozen native adapter or compatible application backend.</param>
    procedure PrepareBackup(const ACard: ISleWorkflowCard);
    /// <summary>Copies and validates an entire ordered plan before hardware I/O.</summary>
    /// <param name="ACard">Frozen adapter retained through execution.</param>
    /// <param name="ASteps">One through 256 exact chained transitions.</param>
    /// <param name="APreviewOnly">True reads/checks but never authenticates or writes.</param>
    /// <param name="ACompletedPrefix">Explicit prefix length; fresh state must equal its final image.</param>
    procedure Prepare(const ACard: ISleWorkflowCard; const ASteps: TSleWorkflowSteps;
      const APreviewOnly: Boolean = False; const ACompletedPrefix: Integer = 0);
    /// <summary>Independently owned public-memory snapshot, including the last successfully observed bytes.</summary>
    property Snapshot: TSleWorkflowSnapshot read GetSnapshot;
    /// <summary>Independent per-step evidence; pending remains distinct from uncertain dispatch.</summary>
    property Results: TCardWorkflowUnits read GetResults;
  end;
  /// <summary>Palette workflow for SLE4404 reviewed programming and explicit erase plans.</summary>
  TSle4404Workflow = class(TSleProgrammingWorkflow)
  end;
  /// <summary>Palette workflow for SLE4406/4436/5536/6636 explicit counter programming plans.</summary>
  TSleCounterWorkflow = class(TSleProgrammingWorkflow)
  end;

implementation

uses ERD.Card.Crypto;

procedure Invalid;
begin
  raise ECardWorkflowError.Create('Invalid explicit SLE window or programming plan.');
end;

procedure CheckImages(const S: TSleWorkflowStep; const Base, Count: Integer);
begin
  if (Length(S.Before) <> Count) or (Length(S.After) <> Count) or
    (S.Address < Base) or (S.Count < 1) or (S.Count > Count) or
    (S.Address - Base > Count - S.Count) then Invalid;
end;

constructor TSle4404WorkflowCard.Create(const AReader: TSle4404CardReaderWriter;
  const AAddress, ACount: Integer; const AUserCode, AMemoryCode: TBytes);
var L: TSle4404AccessLayout;
  function Overlaps(const P, N: Integer): Boolean;
  begin Result := (P >= 0) and (AAddress < P + N) and (P < AAddress + ACount); end;
begin
  inherited Create;
  if (AReader = nil) or (AAddress < 0) or (ACount < 1) or
    (AAddress > AReader.ReadableBytes - ACount) or
    not (Length(AUserCode) in [0, 2]) or not (Length(AMemoryCode) in [0, 4]) then Invalid;
  L := AReader.Layout;
  if Overlaps($08, 2) or Overlaps($28, 4) or
    Overlaps(L.UserCounterAddress, 1) or Overlaps(L.MemoryCounterAddress, 8) then Invalid;
  FReader := TSle4404CardReaderWriter.Create(nil);
  FReader.Layout := L; FReader.ReadableBytes := AReader.ReadableBytes;
  FReader.MinimumUserCodeAttempts := AReader.MinimumUserCodeAttempts;
  FReader.MinimumMemoryCodeAttempts := AReader.MinimumMemoryCodeAttempts;
  FReader.Transport := AReader.Transport; FAddress := AAddress; FCount := ACount;
  FUserCode := CopyBytes(AUserCode); FMemoryCode := CopyBytes(AMemoryCode);
end;

destructor TSle4404WorkflowCard.Destroy;
begin
  TCardCrypto.Clear(FUserCode); TCardCrypto.Clear(FMemoryCode);
  FReader.Free; inherited;
end;

function TSle4404WorkflowCard.Layout: string;
var L: TSle4404AccessLayout;
begin
  L := FReader.Layout;
  Result := 'SLE4404:' + IntToStr(FReader.ReadableBytes) + ':' +
    IntToStr(L.UserCounterAddress) + ':' + IntToStr(L.UserCounterMask) + ':' +
    IntToStr(L.MemoryCounterAddress) + ':' + IntToStr(L.ScratchPadAddress) + ':' +
    IntToStr(L.ScratchPadBytes) + ':' + IntToStr(L.ApplicationAddress) + ':' + IntToStr(L.ApplicationBytes);
end;
function TSle4404WorkflowCard.Address: Integer;
begin Result := FAddress; end;
function TSle4404WorkflowCard.ByteCount: Integer;
begin Result := FCount; end;
function TSle4404WorkflowCard.ReadWindow: TBytes;
begin Result := FReader.ReadMemory(FAddress, FCount, nil); end;

procedure TSle4404WorkflowCard.ValidateStep(const AStep: TSleWorkflowStep);
var I, Start, Area, AreaCount, Bits: Integer; L: TSle4404AccessLayout; Changed: Boolean;
begin
  CheckImages(AStep, FAddress, FCount); L := FReader.Layout;
  if AStep.Mode <> scwProgram then Invalid;
  Start := AStep.Address - FAddress;
  if Length(FUserCode) <> 0 then
  begin
    Bits := 0;
    for I := 0 to 7 do if (L.UserCounterMask and (1 shl I)) <> 0 then Inc(Bits);
    if (Bits <> 4) or (L.UserCounterAddress < 0) or
      (L.UserCounterAddress >= FReader.ReadableBytes) or
      (L.UserCounterAddress in [$08, $09, $28, $29, $2A, $2B]) then Invalid;
  end;
  case AStep.Action of
    swaProgram:
      begin
        TSle4404Codec.ProgramCommand(AStep.Address, Copy(AStep.After, Start, AStep.Count));
        for I := Start to Start + AStep.Count - 1 do
          if (AStep.Before[I] and AStep.After[I]) <> AStep.After[I] then Invalid;
      end;
    swaEraseScratchPad, swaEraseApplication:
      begin
        Area := L.ScratchPadAddress; AreaCount := L.ScratchPadBytes;
        if AStep.Action = swaEraseApplication then
        begin
          Area := L.ApplicationAddress; AreaCount := L.ApplicationBytes;
          if (Length(FUserCode) <> 2) or (Length(FMemoryCode) <> 4) or
            (L.MemoryCounterAddress < 0) or (L.MemoryCounterAddress > FReader.ReadableBytes - 8) or
            ((L.MemoryCounterAddress <= L.UserCounterAddress) and
             (L.UserCounterAddress < L.MemoryCounterAddress + 8)) or
            ((L.MemoryCounterAddress < $0A) and ($08 < L.MemoryCounterAddress + 8)) or
            ((L.MemoryCounterAddress < $2C) and ($28 < L.MemoryCounterAddress + 8)) then Invalid;
        end;
        if (AStep.Address <> Area) or (AStep.Count <> AreaCount) then Invalid;
        Changed := False;
        for I := Start to Start + AStep.Count - 1 do
        begin
          if AStep.After[I] <> $FF then Invalid;
          Changed := Changed or (AStep.Before[I] <> $FF);
        end;
        if (AStep.Action = swaEraseApplication) and not Changed then Invalid;
      end;
  else Invalid;
  end;
  for I := 0 to FCount - 1 do
    if ((I < Start) or (I >= Start + AStep.Count)) and (AStep.Before[I] <> AStep.After[I]) then Invalid;
end;

procedure TSle4404WorkflowCard.Apply(const AStep: TSleWorkflowStep);
var Before, After: TBytes; Start: Integer;
begin
  ValidateStep(AStep); Start := AStep.Address - FAddress;
  Before := Copy(AStep.Before, Start, AStep.Count); After := Copy(AStep.After, Start, AStep.Count);
  case AStep.Action of
    swaProgram: FReader.ProgramMemory(AStep.Address, Before, After, FUserCode);
    swaEraseScratchPad: FReader.EraseScratchPad(Before, FUserCode);
    swaEraseApplication: FReader.EraseApplication(Before, FUserCode, FMemoryCode);
  else Invalid;
  end;
end;

constructor TSleCounterWorkflowCard.Create(const AReader: TSleCounterCardReaderWriter);
begin
  inherited Create;
  if (AReader = nil) or (AReader.ReadableBytes < 1) or (AReader.ReadableBytes > 256) then Invalid;
  FReader := TSleCounterCardReaderWriter.Create(nil); FReader.Model := AReader.Model;
  FReader.ReadableBytes := AReader.ReadableBytes; FReader.Transport := AReader.Transport;
end;
destructor TSleCounterWorkflowCard.Destroy;
begin FReader.Free; inherited; end;
function TSleCounterWorkflowCard.Layout: string;
begin Result := 'SLE-COUNTER:' + IntToStr(Ord(FReader.Model)) + ':' + IntToStr(FReader.ReadableBytes); end;
function TSleCounterWorkflowCard.Address: Integer;
begin Result := 0; end;
function TSleCounterWorkflowCard.ByteCount: Integer;
begin Result := FReader.ReadableBytes; end;
function TSleCounterWorkflowCard.ReadWindow: TBytes;
begin Result := FReader.ReadMemory(0, FReader.ReadableBytes); end;
procedure TSleCounterWorkflowCard.ValidateStep(const AStep: TSleWorkflowStep);
var I: Integer;
begin
  CheckImages(AStep, 0, FReader.ReadableBytes);
  if (AStep.Action <> swaCounterByte) or (AStep.Count <> 1) then Invalid;
  TSleCounterCodec.Write(FReader.Model, AStep.Address, AStep.After[AStep.Address], AStep.Mode);
  if (AStep.Before[AStep.Address] and AStep.After[AStep.Address]) <> AStep.After[AStep.Address] then Invalid;
  if AStep.Mode in [scwProgram, scwBackup] then
    for I := 0 to FReader.ReadableBytes - 1 do
      if (I <> AStep.Address) and (AStep.Before[I] <> AStep.After[I]) then Invalid;
end;
procedure TSleCounterWorkflowCard.Apply(const AStep: TSleWorkflowStep);
begin
  ValidateStep(AStep);
  FReader.WriteByte(AStep.Address, AStep.After[AStep.Address], AStep.Mode, AStep.Before, AStep.After);
end;

class function TSleWorkflowPlanner.Compare(const ASnapshot: TSleWorkflowSnapshot;
  const ADesired: TBytes): TCardWorkflowAddresses;
var I, N: Integer;
begin
  TSleWorkflowArchive.EncodeSnapshot(ASnapshot);
  if Length(ADesired) <> Length(ASnapshot.Data) then Invalid;
  Result := nil; N := 0;
  for I := 0 to High(ADesired) do if ASnapshot.Data[I] <> ADesired[I] then
  begin SetLength(Result, N + 1); Result[N] := ASnapshot.Address + I; Inc(N); end;
end;
class function TSleWorkflowPlanner.ProgramPlan(const ASnapshot: TSleWorkflowSnapshot;
  const ADesired: TBytes; const ACard: ISleWorkflowCard; const AAction: TSleWorkflowAction): TSleWorkflowSteps;
var I, Start, Count, N: Integer; Current: TBytes; S: TSleWorkflowStep;
begin
  Result := nil; TSleWorkflowArchive.EncodeSnapshot(ASnapshot);
  if (ACard = nil) or not (AAction in [swaProgram, swaCounterByte]) or
    (ASnapshot.Layout <> ACard.Layout) or (ASnapshot.Address <> ACard.Address) or
    (Length(ASnapshot.Data) <> ACard.ByteCount) or (Length(ADesired) <> ACard.ByteCount) then Invalid;
  for I := 0 to High(ADesired) do
    if (ASnapshot.Data[I] and ADesired[I]) <> ADesired[I] then Invalid;
  Current := CopyBytes(ASnapshot.Data); I := 0; N := 0;
  while I < Length(Current) do
  begin
    if Current[I] = ADesired[I] then begin Inc(I); Continue; end;
    Start := I; Count := 1;
    if AAction = swaProgram then
      while (Start + Count < Length(Current)) and (Count < 128) and
        (Current[Start + Count] <> ADesired[Start + Count]) do Inc(Count);
    S := Default(TSleWorkflowStep); S.Action := AAction; S.Address := ASnapshot.Address + Start;
    S.Count := Count; S.Mode := scwProgram; S.Before := CopyBytes(Current);
    Move(ADesired[Start], Current[Start], Count); S.After := CopyBytes(Current);
    ACard.ValidateStep(S); SetLength(Result, N + 1); Result[N] := S; Inc(N); Inc(I, Count);
  end;
end;

class function TSleWorkflowArchive.EncodeSnapshot(const ASnapshot: TSleWorkflowSnapshot): string;
var I: Integer;
begin
  if (Length(ASnapshot.Layout) < 1) or (Length(ASnapshot.Layout) > 256) or
    (Length(ASnapshot.Data) < 1) or (Length(ASnapshot.Data) > 256) or
    (ASnapshot.Address < 0) or (ASnapshot.Address > 256 - Length(ASnapshot.Data)) then Invalid;
  for I := 1 to Length(ASnapshot.Layout) do
    if (Ord(ASnapshot.Layout[I]) < 33) or (Ord(ASnapshot.Layout[I]) > 126) then Invalid;
  Result := 'ERD-SLE-SNAPSHOT 1' + #13#10 + ASnapshot.Layout + #13#10 +
    IntToStr(ASnapshot.Address) + #13#10 + BytesToHex(ASnapshot.Data) + #13#10;
end;
class function TSleWorkflowArchive.DecodeSnapshot(const AText: string): TSleWorkflowSnapshot;
var Lines: TStringList;
begin
  Result := Default(TSleWorkflowSnapshot);
  if Length(AText) > 2048 then Invalid;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count <> 4) or (Lines[0] <> 'ERD-SLE-SNAPSHOT 1') then Invalid;
    Result.Layout := Lines[1];
    if not TryStrToInt(Lines[2], Result.Address) then Invalid;
    Result.Data := HexToBytes(Lines[3]);
    if EncodeSnapshot(Result) <> AText then Invalid;
  finally Lines.Free; end;
end;
class function TSleWorkflowArchive.EncodePlan(const ASteps: TSleWorkflowSteps): string;
var I: Integer; S: TSleWorkflowStep;
begin
  if (Length(ASteps) < 1) or (Length(ASteps) > 256) then Invalid;
  Result := 'ERD-SLE-PLAN 1' + #13#10;
  for I := 0 to High(ASteps) do
  begin
    S := ASteps[I];
    if (Ord(S.Action) > Ord(High(TSleWorkflowAction))) or (Ord(S.Mode) > 3) or
      (S.Address < 0) or (S.Address > 255) or (S.Count < 1) or (S.Count > 256) or
      (Length(S.Before) < 1) or (Length(S.Before) > 256) or
      (Length(S.Before) <> Length(S.After)) then Invalid;
    Result := Result + IntToStr(Ord(S.Action)) + '|' + IntToStr(S.Address) + '|' +
      IntToStr(S.Count) + '|' + IntToStr(Ord(S.Mode)) + '|' + BytesToHex(S.Before) + '|' + BytesToHex(S.After) + #13#10;
  end;
end;
class function TSleWorkflowArchive.DecodePlan(const AText: string): TSleWorkflowSteps;
var Lines, Fields: TStringList; I, Action, Mode: Integer;
begin
  Result := nil;
  if Length(AText) > 300000 then Invalid;
  Lines := TStringList.Create; Fields := TStringList.Create;
  try
    Lines.Text := AText;
    if (Lines.Count < 2) or (Lines.Count > 257) or (Lines[0] <> 'ERD-SLE-PLAN 1') then Invalid;
    SetLength(Result, Lines.Count - 1); Fields.StrictDelimiter := True; Fields.Delimiter := '|';
    for I := 0 to High(Result) do
    begin
      Fields.DelimitedText := Lines[I + 1];
      if (Fields.Count <> 6) or not TryStrToInt(Fields[0], Action) or not TryStrToInt(Fields[3], Mode) or
        not (Action in [0..3]) or not (Mode in [0..3]) then Invalid;
      Result[I].Action := TSleWorkflowAction(Action); Result[I].Mode := TSleCounterWriteMode(Mode);
      if not TryStrToInt(Fields[1], Result[I].Address) or not TryStrToInt(Fields[2], Result[I].Count) then Invalid;
      Result[I].Before := HexToBytes(Fields[4]); Result[I].After := HexToBytes(Fields[5]);
    end;
    if EncodePlan(Result) <> AText then Invalid;
  finally Fields.Free; Lines.Free; end;
end;

procedure CheckCard(const ACard: ISleWorkflowCard);
begin
  if (ACard = nil) or (ACard.Layout = '') or (ACard.ByteCount < 1) or
    (ACard.ByteCount > 256) or (ACard.Address < 0) or
    (ACard.Address > 256 - ACard.ByteCount) then Invalid;
end;
procedure TSleProgrammingWorkflow.PrepareBackup(const ACard: ISleWorkflowCard);
begin
  RequireIdle; CheckCard(ACard); FCard := ACard; FSteps := nil; FResults := nil;
  FSnapshot := Default(TSleWorkflowSnapshot); FResume := 0;
  FPreview := True; FPrepared := True; FConsumed := False;
end;
procedure TSleProgrammingWorkflow.Prepare(const ACard: ISleWorkflowCard;
  const ASteps: TSleWorkflowSteps; const APreviewOnly: Boolean; const ACompletedPrefix: Integer);
var I: Integer; Steps: TSleWorkflowSteps;
begin
  RequireIdle; CheckCard(ACard);
  if (Length(ASteps) < 1) or (Length(ASteps) > 256) or
    (ACompletedPrefix < 0) or (ACompletedPrefix > Length(ASteps)) then Invalid;
  SetLength(Steps, Length(ASteps));
  for I := 0 to High(Steps) do
  begin
    Steps[I] := ASteps[I]; Steps[I].Before := CopyBytes(ASteps[I].Before);
    Steps[I].After := CopyBytes(ASteps[I].After); ACard.ValidateStep(Steps[I]);
    if (I > 0) and not BytesEqual(Steps[I - 1].After, Steps[I].Before) then Invalid;
  end;
  FCard := ACard; FSteps := Steps; FResults := nil; FSnapshot := Default(TSleWorkflowSnapshot);
  FResume := ACompletedPrefix; FPreview := APreviewOnly; FPrepared := True; FConsumed := False;
end;
procedure TSleProgrammingWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed then Invalid; end;
function TSleProgrammingWorkflow.GetSnapshot: TSleWorkflowSnapshot;
begin Result := FSnapshot; Result.Data := CopyBytes(FSnapshot.Data); end;
function TSleProgrammingWorkflow.GetResults: TCardWorkflowUnits;
var I: Integer;
begin
  Result := Copy(FResults, 0, Length(FResults));
  for I := 0 to High(Result) do Result[I].Data := CopyBytes(FResults[I].Data);
end;
procedure TSleProgrammingWorkflow.DoExecute;
var I: Integer; Expected, Actual: TBytes;
begin
  FConsumed := True;
  if not RequestCard(cwrTarget) then Exit;
  Progress(cwsReading, 0, 1); Actual := FCard.ReadWindow;
  if Length(Actual) <> FCard.ByteCount then Invalid;
  FSnapshot.Layout := FCard.Layout; FSnapshot.Address := FCard.Address; FSnapshot.Data := CopyBytes(Actual);
  if Length(FSteps) = 0 then Exit;
  Expected := FSteps[0].Before;
  if FResume > 0 then Expected := FSteps[FResume - 1].After;
  SetLength(FResults, Length(FSteps));
  for I := 0 to High(FSteps) do
  begin
    FResults[I].Address := FSteps[I].Address; FResults[I].Data := CopyBytes(FSteps[I].After);
    FResults[I].State := cwusPending;
  end;
  Progress(cwsChecking, 0, Length(FSteps));
  if not BytesEqual(Actual, Expected) then Invalid;
  for I := 0 to FResume - 1 do FResults[I].State := cwusUnchanged;
  if FPreview then Exit;
  for I := FResume to High(FSteps) do
  begin
    if CancelRequested then Exit;
    Actual := FCard.ReadWindow;
    if not BytesEqual(Actual, FSteps[I].Before) then Invalid;
    if BytesEqual(FSteps[I].Before, FSteps[I].After) and
      not ((FSteps[I].Action = swaCounterByte) and (FSteps[I].Mode in [scwCarry, scwCarryBackup])) then
    begin FResults[I].State := cwusUnchanged; Continue; end;
    Progress(cwsWriting, I, Length(FSteps));
    if CancelRequested then Exit;
    try
      try FCard.Apply(FSteps[I]);
      except
        on E: EMemoryCardWriteUncertain do
        begin MutationPending(True); FResults[I].State := cwusUncertain; raise; end;
      end;
      MutationPending(True); FResults[I].State := cwusUncertain;
      Progress(cwsVerifying, I, Length(FSteps)); Actual := FCard.ReadWindow;
      FSnapshot.Data := CopyBytes(Actual);
      if not BytesEqual(Actual, FSteps[I].After) then Invalid;
      FResults[I].State := cwusVerified; MutationPending(False);
    except raise; end;
    Progress(cwsVerifying, I + 1, Length(FSteps));
  end;
end;

end.
