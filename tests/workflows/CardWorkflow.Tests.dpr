program CardWorkflowTests;

{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Workflow, ERD.Card.Workflow.Archive,
  ERD.Card.Contactless, ERD.Card.Contactless.Workflow, ERD.Card.Contactless.Workflow.UID,
  ERD.Card.Contactless.Workflow.Ndef, ERD.Card.Contactless.Classic.Access,
  ERD.Card.Contactless.Workflow.Credentials, ERD.Card.Demo.Job, ERD.Card.Demo.Workflows,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.UID,
  ERD.Card.Contactless.Type2, ERD.Card.Ndef, ERD.Card.Ndef.Records,
  ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe.Workflow;

type
  TMemory = class(TInterfacedObject, ICardWorkflowMemory)
    Identity: TBytes;
    Blocks: array [0 .. 3] of TBytes;
    Reads, Writes, FailReadAt, FailWriteAt, SwapAt: Integer;
    ChangedUid, WrongReadBack: Boolean;
    LayoutName: string;
    constructor Create;
    function Layout: string;
    function UnitSize: Integer;
    procedure ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
    function ReadUid: TBytes;
    function ReadUnit(const AAddress: Integer): TBytes;
    procedure WriteUnit(const AAddress: Integer; const AData: TBytes);
  end;
  TObserver = class
    CancelPhase: TCardWorkflowState;
    CancelAfter: Integer;
    CancelEnabled, RejectCard, RaiseProgress, Reenter, Reentered: Boolean;
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState;
      const ADone, ATotal: Integer);
    procedure Card(Sender: TObject; const ARole: TCardWorkflowRole; var AReady: Boolean);
  end;
  TNdefMemory = class(TInterfacedObject, ICardWorkflowNdef)
    Data: TBytes;
    Writes: Integer;
    FailWrite, Mismatch: Boolean;
    function ReadMessage: TBytes;
    procedure WriteMessage(const ABytes: TBytes);
  end;
  TStripe = class(TInterfacedObject, IMagStripeDevice, IMagStripeStatusWriter)
    Payload: TMagStripeTracks;
    Reads, Writes, Begins, Ends: Integer;
    Verified, Fails, ReleaseFails: Boolean;
    function GetCapabilities: TMagStripeCapabilities;
    procedure Acquire;
    procedure Release;
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
    function ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
  end;
  TCard = class(TInterfacedObject, ICardTransport, ICardTransaction)
    Blocks: array [0 .. 63] of TBytes;
    Exchanges, Writes, Begins, Ends: Integer;
    FailWrite, FailEnd, CachedUid: Boolean;
    FailWriteAt: Integer;
    constructor Create;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TKeys = class(TInterfacedObject, IClassicWorkflowKeys)
    function GetKey(const ABlock: Integer; const AWriting: Boolean;
      out AKeyType: TMifareClassicKeyType): TBytes;
  end;
  TReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
    Source, Target: ICardTransport;
    Factories: Integer;
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;
var Checks: Integer;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

constructor TMemory.Create;
var I: Integer;
begin
  inherited Create;
  LayoutName := 'SYNTHETIC-4';
  Identity := HexToBytes('11223344');
  for I := 0 to 3 do Blocks[I] := HexToBytes('00000000');
end;
function TMemory.Layout: string;
begin Result := LayoutName; end;
function TMemory.UnitSize: Integer;
begin Result := 4; end;
procedure TMemory.ValidateUnit(const AAddress: Integer; const AWriting: Boolean);
begin
  if (AAddress < 0) or (AAddress > 3) then raise ECardWorkflowError.Create('Range.');
end;
function TMemory.ReadUid: TBytes;
begin
  if ChangedUid or ((SwapAt > 0) and (Reads >= SwapAt)) then Result := HexToBytes('55667788')
  else Result := CopyBytes(Identity);
end;
function TMemory.ReadUnit(const AAddress: Integer): TBytes;
begin
  Inc(Reads);
  if (FailReadAt > 0) and (Reads = FailReadAt) then raise ECardWorkflowError.Create('Read.');
  Result := CopyBytes(Blocks[AAddress]);
  if WrongReadBack and (Writes > 0) then Result[0] := Result[0] xor $FF;
end;
procedure TMemory.WriteUnit(const AAddress: Integer; const AData: TBytes);
begin
  Inc(Writes);
  Blocks[AAddress] := CopyBytes(AData);
  if (FailWriteAt > 0) and (Writes = FailWriteAt) then raise ECardWorkflowError.Create('Write.');
end;
procedure TObserver.Progress(Sender: TObject; const AState: TCardWorkflowState;
  const ADone, ATotal: Integer);
begin
  if Reenter and not Reentered then
  begin
    Reentered := True;
    try TCardWorkflow(Sender).Execute; Check(False, 'Reentrant Execute refused');
    except on E: ECardWorkflowError do Check(True, 'Reentrancy guard'); end;
  end;
  if CancelEnabled and (AState = CancelPhase) and (ADone >= CancelAfter) then
    TCardWorkflow(Sender).Cancel;
  if RaiseProgress then raise EArgumentException.Create('Observer.');
end;
procedure TObserver.Card(Sender: TObject; const ARole: TCardWorkflowRole; var AReady: Boolean);
begin AReady := not RejectCard; end;

procedure MemoryTests;
var Source, Target: TMemory; S, T: ICardWorkflowMemory;
  Flow: TCardMemoryCopyWorkflow; Addresses: TCardWorkflowAddresses;
  Snapshot, Decoded: TCardWorkflowSnapshot; Results: TCardWorkflowUnits;
  Observer: TObserver; Text: string; I: Integer;
begin
  Source := TMemory.Create; S := Source; Target := TMemory.Create; T := Target;
  Source.Blocks[1] := HexToBytes('01020304'); Source.Blocks[2] := HexToBytes('05060708');
  Addresses := nil; SetLength(Addresses, 3); Addresses[0] := 0; Addresses[1] := 1; Addresses[2] := 2;
  Flow := TCardMemoryCopyWorkflow.Create(nil); Observer := TObserver.Create;
  try
    Flow.OnProgress := Observer.Progress;
    Flow.OnCardRequired := Observer.Card;
    Flow.PrepareCopy(S, T, Addresses);
    Addresses[1] := 3;
    Observer.Reenter := True;
    Check(Flow.Execute = cwsCompleted, 'Copy completes');
    Check(Target.Writes = 2, 'Skip unchanged unit');
    Results := Flow.Results;
    Check((Results[0].State = cwusUnchanged) and (Results[1].State = cwusVerified), 'Per-unit evidence');
    Snapshot := Flow.Snapshot; Snapshot.Units[1].Data[0] := $AA;
    Check(Flow.Snapshot.Units[1].Data[0] = 1, 'Snapshot output is independent');
    Results[1].Data[0] := $BB;
    Check(Flow.Results[1].Data[0] = 1, 'Plan output is independent');
    try Flow.Execute; Check(False, 'Consumed request refused');
    except on E: ECardWorkflowError do Check(True, 'Single execution'); end;
    Snapshot := Flow.Snapshot;
    Text := TCardWorkflowArchive.Encode(Snapshot); Decoded := TCardWorkflowArchive.Decode(Text);
    Check(BytesEqual(Decoded.Units[2].Data, Snapshot.Units[2].Data), 'Archive bytes round trip');
    Check((Decoded.Layout = Snapshot.Layout) and BytesEqual(Decoded.Uid, Snapshot.Uid), 'Archive metadata');
    for I := 0 to 4 do
    begin
      case I of
        0: Text := TCardWorkflowArchive.Encode(Snapshot) + 'U 1 01020304' + #10;
        1: Text := 'ERD-MEMORY 2' + #10;
        2: Text := TCardWorkflowArchive.Encode(Snapshot) + #0;
        3: Text := StringReplace(TCardWorkflowArchive.Encode(Snapshot), 'U 1 ', 'U +1 ', []);
        4: Text := StringReplace(TCardWorkflowArchive.Encode(Snapshot), '01020304', '0102', []);
      end;
      try TCardWorkflowArchive.Decode(Text); Check(False, 'Malformed archive rejected');
      except on E: ECardWorkflowError do Check(True, 'Archive strictness'); end;
    end;
    Flow.PrepareRestore(Snapshot, T, True);
    Snapshot.Units[1].Data[0] := $CC;
    Check(Flow.Execute = cwsCompleted, 'Comparison completes');
    Check(Target.Writes = 2, 'Compare sends no writes');
    Check(Flow.Snapshot.Units[1].Data[0] = 1, 'Restore input is independent');
    Target.Blocks[1] := HexToBytes('00000000'); Target.Blocks[2] := HexToBytes('00000000');
    Target.Reads := 0; Target.FailReadAt := 3;
    Snapshot := Decoded;
    Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsFailed, 'Late target read failure');
    Check(Target.Writes = 2, 'All target preflight before first write');
    Target.FailReadAt := 0; Target.Reads := 0; Target.FailWriteAt := 4;
    Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsUncertain, 'Second write transport failure is uncertain');
    Results := Flow.Results;
    Check((Results[1].State = cwusVerified) and (Results[2].State = cwusUncertain), 'Partial ledger survives');
    Check(Target.Writes = 4, 'No write replay');
    Target.FailWriteAt := 0; Target.WrongReadBack := True;
    Target.Blocks[1] := HexToBytes('00000000');
    Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsUncertain, 'Readback mismatch is uncertain');
    Target.WrongReadBack := False; Target.Blocks[1] := HexToBytes('00000000');
    Observer.CancelEnabled := True; Observer.CancelPhase := cwsWriting; Observer.CancelAfter := 0;
    I := Target.Writes; Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsCancelled, 'Cancel in before-write observer');
    Check(Target.Writes = I, 'Before-write cancellation dispatches nothing');
    Observer.CancelPhase := cwsVerifying;
    Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsCancelled, 'Cancel during verification');
    Check(Flow.Results[1].State = cwusVerified, 'In-flight write verification completes before cancel');
    Observer.CancelEnabled := False; Observer.RaiseProgress := True;
    Flow.PrepareRestore(Snapshot, T);
    Check(Flow.Execute = cwsCompleted, 'Observer failure isolated');
    Check(Flow.ObserverErrorClass = 'EArgumentException', 'Observer class recorded');
    Observer.RaiseProgress := False; Observer.RejectCard := True;
    I := Source.Reads; Flow.PrepareBackup(S, Addresses);
    Check(Flow.Execute = cwsCancelled, 'Card presentation rejected');
    Check(Source.Reads = I, 'No source I/O after card rejection');
    Observer.RejectCard := False;
    Source.Reads := 0; Source.SwapAt := 1;
    Flow.PrepareBackup(S, Addresses);
    Check(Flow.Execute = cwsFailed, 'Source identity change detected');
    Check(Length(Flow.Snapshot.Units) = 0, 'Incomplete snapshot not published');
    Source.SwapAt := 0; Source.Reads := 0; Source.FailReadAt := 2;
    Flow.PrepareCopy(S, T, Addresses); I := Target.Writes;
    Check(Flow.Execute = cwsFailed, 'Source acquisition failure');
    Check(Target.Writes = I, 'No writes after source failure');
    Addresses[1] := Addresses[0]; I := Source.Reads;
    try Flow.PrepareCopy(S, T, Addresses); Check(False, 'Duplicate selection rejected');
    except on E: ECardWorkflowError do Check(True, 'Duplicate check'); end;
    Check(Source.Reads = I, 'Preparation has no I/O');
    Target.LayoutName := 'OTHER';
    try Flow.PrepareRestore(Decoded, T); Check(False, 'Incompatible target rejected');
    except on E: ECardWorkflowError do Check(True, 'Layout check'); end;
  finally Observer.Free; Flow.Free; S := nil; T := nil; end;
end;

function TNdefMemory.ReadMessage: TBytes;
begin Result := CopyBytes(Data); if Mismatch then Result := nil; end;
procedure TNdefMemory.WriteMessage(const ABytes: TBytes);
begin
  Inc(Writes); Data := CopyBytes(ABytes);
  if FailWrite then raise EContactlessWriteUncertain.Create('Synthetic.');
end;
procedure NdefTests;
var S, T: ICardWorkflowNdef; Source, Target: TNdefMemory;
  Flow: TNdefTransferWorkflow; Message: TNdefMessage; Bytes: TBytes;
begin
  Source := TNdefMemory.Create; S := Source; Target := TNdefMemory.Create; T := Target;
  Message := nil; SetLength(Message, 1); Message[0] := TNdefRecords.Text('Workflow', 'en');
  Source.Data := TNdefCodec.Encode(Message); Flow := TNdefTransferWorkflow.Create(nil);
  try
    Flow.PrepareCopy(S, T); Check(Flow.Execute = cwsCompleted, 'Cross-mapping NDEF transfer');
    Check(Flow.ReadBackVerified and BytesEqual(Target.Data, Source.Data), 'NDEF verification');
    Bytes := Flow.MessageBytes; Bytes[0] := 0;
    Check(Flow.MessageBytes[0] <> 0, 'NDEF buffers independent');
    Target.Mismatch := True; Flow.PrepareWrite(T, Message);
    Check(Flow.Execute = cwsUncertain, 'NDEF mismatch is uncertain');
    Target.Mismatch := False; Target.FailWrite := True; Flow.PrepareWrite(T, Message);
    Check(Flow.Execute = cwsUncertain, 'NDEF write exception stays uncertain');
    Target.FailWrite := False; Source.Data := nil; Flow.PrepareCopy(S, T);
    Check(Flow.Execute = cwsFailed, 'Empty source cannot silently clear target');
    Check(Target.Writes = 3, 'No implicit clear');
    Flow.PrepareCopy(S, T, True); Check(Flow.Execute = cwsCompleted, 'Explicit NDEF clear');
    Check(Length(Target.Data) = 0, 'Clear verifies no message');
    Flow.PrepareCopy(S, nil); Check(Flow.Execute = cwsCompleted, 'NDEF backup without target');
    Check(not Flow.ReadBackVerified, 'Read-only is not verified programming');
  finally Flow.Free; S := nil; T := nil; end;
end;

function TStripe.GetCapabilities: TMagStripeCapabilities;
begin
  Result.ReadTracks := [mstTrack1, mstTrack2, mstTrack3];
  Result.WriteTracks := Result.ReadTracks; Result.VerifiedWrite := Verified;
  Result.Coercivities := [mscLow, mscHigh];
end;
procedure TStripe.Acquire;
begin Inc(Begins); end;
procedure TStripe.Release;
begin Inc(Ends); if ReleaseFails then raise EMagStripeError.Create('Release.'); end;
function TStripe.Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin Inc(Reads); Result := Payload; end;
function TStripe.Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin
  Inc(Writes); Payload := AData; Result := Payload;
  if Fails then raise EMagStripeError.Create('Synthetic.');
end;
function TStripe.GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
begin Result.Selections := [mswsTrack2]; Result.Coercivities := [mscLow, mscHigh]; end;
function TStripe.ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
begin Inc(Writes); Payload := AData; Result := $30; end;
procedure StripeTests;
var Source, Target: TStripe; Reader, Writer: TMagStripeReaderWriter;
  Flow: TMagStripeCopyWorkflow;
begin
  Reader := TMagStripeReaderWriter.Create(nil); Writer := TMagStripeReaderWriter.Create(nil);
  Flow := TMagStripeCopyWorkflow.Create(nil); Source := TStripe.Create; Target := TStripe.Create;
  Reader.Device := Source; Writer.Device := Target;
  Source.Payload[mstTrack2] := '123456=2712101'; Target.Verified := True;
  try
    Flow.PrepareCopy(Reader, Writer, [mstTrack2], mscHigh);
    Check(Flow.Execute = cwsCompleted, 'Stripe copy');
    Check(Flow.ReadBackVerified and (Target.Payload[mstTrack2] = Source.Payload[mstTrack2]), 'Same-card stripe verification');
    Check((Source.Reads = 1) and (Target.Reads = 0), 'No arbitrary second-swipe verification');
    Target.Verified := False;
    try Flow.PrepareCopy(Reader, Writer, [mstTrack2], mscHigh); Flow.Execute;
      Check(False, 'Unverified mode requires explicit request');
    except on E: ECardWorkflowError do Check(True, 'Verified capability enforced'); end;
    Flow.PrepareCopy(Reader, Writer, [mstTrack2], mscHigh, True);
    Check(Flow.Execute = cwsCompleted, 'Explicit status-only copy');
    Check(not Flow.ReadBackVerified and not Flow.Receipt.HostReadBackVerified, 'Status is not readback');
    Check(Flow.Receipt.DeviceStatus = $30, 'Preserved device receipt');
    Flow.PrepareCopy(Reader, nil, [mstTrack2], mscHigh);
    Check(Flow.Execute = cwsCompleted, 'Stripe read-only backup');
    Target.Verified := True; Target.Fails := True;
    Flow.PrepareWrite(Writer, [mstTrack2], Source.Payload, mscHigh);
    Check(Flow.Execute = cwsUncertain, 'Stripe dispatch failure uncertain');
    Check(Target.Writes = 3, 'Stripe no replay');
    Target.Fails := False; Target.ReleaseFails := True;
    Flow.PrepareWrite(Writer, [mstTrack2], Source.Payload, mscHigh);
    Check(Flow.Execute = cwsUncertain, 'Stripe release failure uncertain');
    Check(Target.Begins = Target.Ends, 'Every stripe session released');
  finally Flow.Free; Reader.Free; Writer.Free; end;
end;

constructor TCard.Create;
var I: Integer;
begin
  inherited Create;
  for I := 0 to High(Blocks) do Blocks[I] := HexToBytes('00000000000000000000000000000000');
  Blocks[0] := HexToBytes('11223344440804006263646566676869');
end;
function TCard.Exchange(const ACommand: TBytes): TBytes;
var Data: TBytes;
begin
  Inc(Exchanges); Data := nil;
  case ACommand[1] of
    $CA:
      if CachedUid then Data := HexToBytes('11223344') else Data := Copy(Blocks[0], 0, 4);
    $82, $86: ;
    $B0: begin Data := CopyBytes(Blocks[ACommand[3]]);
      if TMifareClassicLayout.IsTrailer(mcm1K, ACommand[3]) then FillChar(Data[0], 6, 0);
      end;
    $D6: begin
      Inc(Writes); Blocks[ACommand[3]] := Copy(ACommand, 5, 16);
      if FailWrite or ((FailWriteAt > 0) and (Writes = FailWriteAt)) then
        raise ECardTransportError.Create('Synthetic.');
      end;
  else raise Exception.Create('Unexpected APDU.'); end;
  Result := Data; SetLength(Result, Length(Data) + 2);
  Result[Length(Result) - 2] := $90; Result[Length(Result) - 1] := 0;
end;
procedure TCard.BeginTransaction;
begin Inc(Begins); end;
procedure TCard.EndTransaction;
begin Inc(Ends); if FailEnd then raise ECardTransportError.Create('Release.'); end;
function TKeys.GetKey(const ABlock: Integer; const AWriting: Boolean;
  out AKeyType: TMifareClassicKeyType): TBytes;
begin AKeyType := mckA; Result := HexToBytes('010203040506'); end;

function TReaders.CreateTransport(const AName: UnicodeString): ICardTransport;
begin
  Inc(Factories);
  if AName = 'source' then Result := Source
  else if AName = 'target' then Result := Target
  else raise ECardWorkflowError.Create('Unknown synthetic reader.');
end;

procedure DemoTests;
var Readers: TReaders; Factory: ICardWorkflowDemoReaders; Source, Target: TCard;
  Operations: ICardDemoOperations; Validator: ICardDemoRequestValidator;
  Request: TCardDemoRequest; Result: TCardDemoResult; Error: UnicodeString; I: Integer;
begin
  Readers := TReaders.Create; Factory := Readers;
  Source := TCard.Create; Target := TCard.Create;
  Readers.Source := Source; Readers.Target := Target;
  Source.Blocks[1] := HexToBytes('01020304050607080910111213141516');
  Operations := CreateCardWorkflowDemoOperations(Factory);
  Supports(Operations, ICardDemoRequestValidator, Validator);
  Request := Default(TCardDemoRequest); Request.Operation := cdoFamily;
  Request.FamilyName := 'ClassicWorkflowDemo'; Request.FamilyAction := 0;
  Request.ReaderName := 'source'; SetLength(Request.Arguments, 4); SetLength(Request.Credentials, 3);
  Request.Arguments[0] := 'target'; Request.Arguments[1] := '1';
  Request.Credentials[0] := HexToBytes('010203040506'); Request.Credentials[1] := HexToBytes('AABBCCDDEEFF');
  Check(Validator.TryValidateRequest(Request, Error), 'Demo metadata valid');
  Request.Credentials[0] := nil;
  Check(not Validator.TryValidateRequest(Request, Error), 'Missing source key rejected without I/O');
  Check(Readers.Factories = 0, 'Metadata rejection does not create readers');
  Request.Credentials[0] := HexToBytes('010203040506');
  Operations.Run(Request, Result);
  Check(Result.Success and (Source.Exchanges > 0) and (Target.Exchanges = 0), 'Demo backup acquires source only');
  Check((Length(Result.Artifacts) = 1) and (Result.Artifacts[0].Name = 'memory.erdsnapshot'), 'Demo artifact');
  Request.Arguments[2] := TEncoding.UTF8.GetString(Result.Artifacts[0].Data);
  Request.FamilyAction := 3; Request.MutationAcknowledged := True;
  Operations.Run(Request, Result);
  Check(Result.Success and (Target.Writes = 1), 'Demo restore uses snapshot and skips equal units');
  Check(Pos('Verified', string(Result.Text)) > 0, 'Readable per-unit evidence in demo');
  Request.Arguments[2] := 'malformed'; I := Target.Exchanges;
  try Operations.Run(Request, Result); Check(False, 'Bad archive rejected');
  except on E: ECardWorkflowError do Check(True, 'Demo archive preflight'); end;
  Check(Target.Exchanges = I, 'Malformed restore has no hardware acquisition');
  Request.FamilyAction := 1; Request.MutationAcknowledged := False;
  Check(not Validator.TryValidateRequest(Request, Error), 'Copy acknowledgement enforced');
  Request.MutationAcknowledged := True; Request.Arguments[0] := 'source';
  Check(not Validator.TryValidateRequest(Request, Error), 'Two-reader copy rejects same reader');
  Request.Arguments[0] := 'target'; Request.FamilyAction := 4;
  Request.Arguments[2] := '3' + #13#10 + '7'; Request.Arguments[3] := 'FF078069';
  Request.Credentials[2] := HexToBytes('112233445566');
  Operations.Run(Request, Result);
  Check(Result.Success and (Pos('Trailer 7: Verified', string(Result.Text)) > 0), 'Demo credential migration');
  Check(Length(Result.Artifacts) = 0, 'No credential export artifact');
  Request.Arguments[3] := 'FE078069'; I := Target.Exchanges;
  try Operations.Run(Request, Result); Check(False, 'Invalid credential rights');
  except on E: EClassicAccessError do Check(True, 'Demo access-bit preflight'); end;
  Check(Target.Exchanges = I, 'Invalid credential rights do not acquire hardware');
  Validator := nil; Operations := nil; Factory := nil;
end;

procedure CredentialTests;
var Reader: TContactlessCardReader; Card: TCard; Transport: ICardTransport;
  Flow: TClassicCredentialWorkflow; Changes: TClassicSectorChanges; Results: TCardWorkflowUnits;
begin
  Card := TCard.Create; Transport := Card; Reader := TContactlessCardReader.Create(nil);
  Reader.Transport := Transport; Reader.Profile := TPcscStorageProfile.Create;
  Flow := TClassicCredentialWorkflow.Create(nil); Changes := nil; SetLength(Changes, 2);
  Changes[0].TrailerBlock := 3; Changes[0].CurrentKeyType := mckA;
  Changes[0].CurrentKey := HexToBytes('010203040506');
  Changes[0].NewTrailer := HexToBytes('112233445566FF078069778899AABBCC');
  Changes[1] := Changes[0]; Changes[1].TrailerBlock := 7;
  try
    Flow.Prepare(Reader, mcm1K, Changes);
    Changes[0].NewTrailer[0] := $FF;
    Card.FailWriteAt := 2;
    Check(Flow.Execute = cwsUncertain, 'Credential second-step uncertainty');
    Results := Flow.Results;
    Check((Results[0].State = cwusVerified) and (Results[1].State = cwusUncertain), 'Credential partial evidence');
    Check((Length(Results[0].Data) = 0) and (Length(Results[1].Data) = 0), 'Credential results contain no secret data');
    Check(Card.Blocks[3][0] = $11, 'Credential request buffers independent');
    Check((Card.Writes = 2) and (Card.Begins = Card.Ends), 'Credential no replay and session release');
  finally Flow.Free; Reader.Free; Transport := nil; end;
end;

procedure ClassicTests;
var Conditions, Decoded: TClassicAccessConditions; Access, Bad, Trailer, Key: TBytes;
  I, J, K, L, Bit: Integer; Reader: TContactlessCardReader; Card: TCard;
  Transport: ICardTransport; Memory: ICardWorkflowMemory; Keys: IClassicWorkflowKeys;
  Flow: TUidProgrammingWorkflow; Options: TUidWorkflowOptions;
begin
  for I := 0 to 7 do for J := 0 to 7 do for K := 0 to 7 do for L := 0 to 7 do
  begin
    Conditions[0] := I; Conditions[1] := J; Conditions[2] := K; Conditions[3] := L;
    Access := TClassicAccessCodec.Encode(Conditions); Decoded := TClassicAccessCodec.Decode(Access);
    Check((Decoded[0] = I) and (Decoded[1] = J) and (Decoded[2] = K) and (Decoded[3] = L), 'All access encodings');
  end;
  Access := HexToBytes('FF0780'); Decoded := TClassicAccessCodec.Decode(Access);
  Check((Decoded[0] = 0) and (Decoded[3] = 1), 'Known transport access condition');
  for Bit := 0 to 23 do
  begin
    Bad := CopyBytes(Access); Bad[Bit div 8] := Bad[Bit div 8] xor (1 shl (Bit mod 8));
    try TClassicAccessCodec.Decode(Bad); Check(False, 'Redundant access-bit error refused');
    except on E: EClassicAccessError do Check(True, 'Single-bit access corruption'); end;
  end;
  Check(Length(TClassicWorkflowMemory.DataAddresses(mcmMini)) = 14, 'Mini data geometry');
  Check(Length(TClassicWorkflowMemory.DataAddresses(mcm1K)) = 47, '1K data geometry');
  Check(Length(TClassicWorkflowMemory.DataAddresses(mcm4K)) = 215, '4K data geometry');
  Check(Length(TType2WorkflowMemory.DataAddresses(ttmNtag216)) = 222, 'Type2 geometry');
  Reader := TContactlessCardReader.Create(nil); Card := TCard.Create; Transport := Card;
  Reader.Transport := Transport; Reader.Profile := TPcscStorageProfile.Create;
  Flow := TUidProgrammingWorkflow.Create(nil);
  try
    Keys := TKeys.Create; Memory := TClassicWorkflowMemory.Create(Reader, mcm1K, Keys);
    try Memory.ValidateUnit(3, False); Check(False, 'Masked trailer excluded from data snapshots');
    except on E: ECardWorkflowError do Check(True, 'Trailer exclusion'); end;
    Key := HexToBytes('010203040506');
    Trailer := HexToBytes('112233445566FF078069778899AABBCC');
    Reader.WriteClassicSectorTrailer(mcm1K, 3, mckA, Key, Trailer);
    Check(Card.Writes = 1, 'One sector-trailer mutation');
    Check(BytesEqual(Card.Blocks[3], Trailer), 'Exact caller-supplied credentials and rights');
    I := Card.Exchanges; Bad := CopyBytes(Trailer); Bad[6] := Bad[6] xor 1;
    try Reader.WriteClassicSectorTrailer(mcm1K, 3, mckA, Key, Bad);
      Check(False, 'Invalid access rejected');
    except on E: EClassicAccessError do Check(True, 'Access preflight'); end;
    Check(Card.Exchanges = I, 'Invalid trailer produces no I/O');
    Card.FailWrite := True;
    try Reader.WriteClassicSectorTrailer(mcm1K, 3, mckA, Key, Trailer);
      Check(False, 'Trailer uncertainty');
    except on E: EContactlessWriteUncertain do Check(True, 'Trailer failure uncertain'); end;
    Card.FailWrite := False;
    Options := Default(TUidWorkflowOptions); Options.Profile := uwpGen2;
    Options.Key := Key; Options.KeyType := mckA; Options.Gen2Model := cgum4Byte;
    Flow.Prepare(Reader, nil, Options, HexToBytes('A1B2C3D4'));
    Key[0] := $AA; Options.Key[0] := $BB;
    Check(Flow.Execute = cwsCompleted, 'Gen2 workflow');
    Check(Flow.ActiveUidVerified and BytesEqual(Flow.PreviousUid, HexToBytes('11223344')), 'UID evidence');
    Check(BytesEqual(Flow.RequestedUid, HexToBytes('A1B2C3D4')), 'Independent requested UID');
    Options.Key := HexToBytes('010203040506'); Card.CachedUid := True;
    Card.Blocks[0] := HexToBytes('11223344440804006263646566676869');
    Flow.Prepare(Reader, nil, Options, HexToBytes('A1B2C3D4'));
    Check(Flow.Execute = cwsNeedsVerification, 'Cached UID is not a fresh verification');
    Check(not Flow.ActiveUidVerified, 'Fresh UID evidence explicit');
    Card.CachedUid := False; Card.FailWrite := True;
    Flow.Prepare(Reader, nil, Options, HexToBytes('01020304'));
    Check(Flow.Execute = cwsUncertain, 'UID uncertain result preserved');
    Check(Card.Begins = Card.Ends, 'Every contactless transaction released');
    Memory := nil; Keys := nil;
  finally Flow.Free; Reader.Free; Transport := nil; end;
end;

begin
  try
    MemoryTests; NdefTests; StripeTests; ClassicTests; CredentialTests; DemoTests;
    Writeln('PASS: ', Checks, ' workflow/uncertainty/access-bit assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
