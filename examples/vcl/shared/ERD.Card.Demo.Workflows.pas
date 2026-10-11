unit ERD.Card.Demo.Workflows;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Transport;

type
  /// <summary>Inactive PC/SC workflow connection factory, injectable for application tests.</summary>
  ICardWorkflowDemoReaders = interface
    ['{176D9821-0456-4692-98D7-DB23FEE4D6AF}']
    /// <summary>Creates a retained transport without connecting; first exchange/transaction opens it.</summary>
    /// <param name="AName">Exact caller-selected reader name.</param>
    /// <returns>Transport supporting ICardTransaction and owning its connection lifecycle.</returns>
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;

/// <summary>Creates the nonvisual executor used by the independent workflow demo forms.</summary>
/// <param name="AReaders">Optional inactive injected reader factory; nil uses native Windows PC/SC.</param>
/// <returns>Inactive executor; workers own readers and workflows for one request only.</returns>
function CreateCardWorkflowDemoOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

implementation

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.PCSC.Reader, ERD.Card.Workflow, ERD.Card.Workflow.Archive,
  ERD.Card.Contactless, ERD.Card.Contactless.Workflow,
  ERD.Card.Contactless.Workflow.UID, ERD.Card.Contactless.Workflow.Ndef,
  ERD.Card.Contactless.Workflow.Credentials, ERD.Card.Contactless.Classic.Access,
  ERD.Card.Contactless.Workflow.ISO15693, ERD.Card.Contactless.ISO15693,
  ERD.Card.Workflow.Batch,
  ERD.Card.Contactless.UID, ERD.Card.Contactless.UID.Profiles,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.ACR122,
  ERD.Card.Contactless.Type2, ERD.Card.Contactless.Type2.Ndef, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Ndef, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks,
  ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL, ERD.Card.MagStripe.Workflow;

type
  TDemoKeys = class(TInterfacedObject, IClassicWorkflowKeys)
    Key: TBytes;
    destructor Destroy; override;
    function GetKey(const ABlock: Integer; const AWriting: Boolean;
      out AKeyType: TMifareClassicKeyType): TBytes;
  end;
  TDeferredReader = class(TInterfacedObject, ICardTransport, ICardTransaction)
    Reader: TSmartCardReader;
    constructor Create(const AName: UnicodeString);
    destructor Destroy; override;
    procedure Connect;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TNativeReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;
  TBatchTemplates = class(TInterfacedObject, ICardBatchFactory)
    Readers: ICardWorkflowDemoReaders;
    Model: TType2TagModel;
    Rows: TStringList;
    Components: TList;
    constructor Create;
    destructor Destroy; override;
    function CreateWorkflow(const AIdentifier: string): TCardWorkflow;
  end;
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
    Log: string;
    Readers: ICardWorkflowDemoReaders;
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
    procedure Memory(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
      var D: TCardDemoResult);
    procedure Uid(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
      var D: TCardDemoResult);
    procedure Ndef(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
      var D: TCardDemoResult);
    procedure Stripe(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure IsoMemory(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure Batch(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure Finish(const AFlow: TCardWorkflow; var D: TCardDemoResult);
  end;

constructor TDeferredReader.Create(const AName: UnicodeString);
begin
  inherited Create;
  Reader := TSmartCardReader.Create(nil);
  Reader.ReaderName := AName;
end;

destructor TDeferredReader.Destroy;
begin Reader.Free; inherited Destroy; end;

procedure TDeferredReader.Connect;
begin if not Reader.Connected then Reader.Connect; end;

function TDeferredReader.Exchange(const ACommand: TBytes): TBytes;
begin Connect; Result := Reader.Transport.Exchange(ACommand); end;

procedure TDeferredReader.BeginTransaction;
begin Connect; Reader.BeginTransaction; end;

procedure TDeferredReader.EndTransaction;
begin Reader.EndTransaction; end;

function TNativeReaders.CreateTransport(const AName: UnicodeString): ICardTransport;
begin Result := TDeferredReader.Create(AName); end;

destructor TDemoKeys.Destroy;
var I: Integer;
begin for I := 0 to High(Key) do Key[I] := 0; inherited Destroy; end;
function TDemoKeys.GetKey(const ABlock: Integer; const AWriting: Boolean;
  out AKeyType: TMifareClassicKeyType): TBytes;
begin AKeyType := mckA; Result := CopyBytes(Key); end;

procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin Log := Log + 'Phase ' + CardWorkflowStateName(AState) + ': ' + IntToStr(ADone) + '/' + IntToStr(ATotal) + #13#10; end;

function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
var Model: Integer;
begin
  AError := 'Choose the action, model, source/target devices and acknowledge writes.';
  Result := (ARequest.Operation = cdoFamily) and (Length(ARequest.Arguments) = 4) and
    (Length(ARequest.Credentials) = 3) and (ARequest.FamilyAction in [0 .. 4]);
  if not Result then Exit;
  Result := (ARequest.FamilyName = 'ClassicWorkflowDemo') or
    (ARequest.FamilyName = 'Type2WorkflowDemo') or (ARequest.FamilyName = 'UidWorkflowDemo') or
    (ARequest.FamilyName = 'MagStripeWorkflowDemo') or (ARequest.FamilyName = 'NdefWorkflowDemo') or
    (ARequest.FamilyName = 'Iso15693WorkflowDemo') or (ARequest.FamilyName = 'BatchWorkflowDemo');
  if not Result then Exit;
  if (ARequest.FamilyName = 'BatchWorkflowDemo') and (ARequest.FamilyAction <> 3) then Result := False;
  if (ARequest.FamilyAction = 4) and (ARequest.FamilyName <> 'ClassicWorkflowDemo') then Result := False;
  if ARequest.FamilyAction in [0 .. 2] then Result := Result and (ARequest.ReaderName <> '');
  if (ARequest.FamilyAction <> 0) and (ARequest.FamilyName <> 'BatchWorkflowDemo') then
    Result := Result and (ARequest.Arguments[0] <> '');
  if ARequest.FamilyAction in [1, 2] then Result := Result and (ARequest.ReaderName <> ARequest.Arguments[0]);
  if ARequest.FamilyAction in [1, 3, 4] then Result := Result and ARequest.MutationAcknowledged;
  if (ARequest.FamilyAction = 2) and ((ARequest.FamilyName = 'UidWorkflowDemo') or
    (ARequest.FamilyName = 'NdefWorkflowDemo') or (ARequest.FamilyName = 'MagStripeWorkflowDemo')) then Result := False;
  if not TryStrToInt(string(ARequest.Arguments[1]), Model) then Result := False;
  if Result then
  begin
    if ARequest.FamilyName = 'ClassicWorkflowDemo' then
    begin
      Result := Model in [0 .. 2];
      if ARequest.FamilyAction in [0, 1, 2, 4] then Result := Result and (Length(ARequest.Credentials[0]) = 6);
      if ARequest.FamilyAction = 4 then Result := Result and (Length(ARequest.Credentials[2]) = 6);
      if ARequest.FamilyAction <> 0 then Result := Result and (Length(ARequest.Credentials[1]) = 6);
    end
    else if (ARequest.FamilyName = 'Type2WorkflowDemo') or
      (ARequest.FamilyName = 'BatchWorkflowDemo') then Result := Model in [0 .. 7]
    else if ARequest.FamilyName = 'Iso15693WorkflowDemo' then Result := Model in [0 .. 1]
    else if ARequest.FamilyName = 'NdefWorkflowDemo' then Result := Model in [0 .. 8]
    else if ARequest.FamilyName = 'MagStripeWorkflowDemo' then
      Result := (Model in [0 .. 6]) and (ARequest.Coercivity in [mscLow, mscHigh])
    else if ARequest.FamilyName = 'UidWorkflowDemo' then
    begin
      Result := Model in [0 .. 11];
      if ARequest.FamilyAction <> 0 then
        if Model in [0 .. 2] then Result := Result and (Length(ARequest.Credentials[1]) = 6)
        else if Model in [9 .. 11] then Result := Result and (Length(ARequest.Credentials[1]) = 4);
    end;
  end;
  Result := Result and (Length(ARequest.Arguments[2]) <= 3 * 1024 * 1024);
  if Result then AError := '';
end;

procedure TOperations.Finish(const AFlow: TCardWorkflow; var D: TCardDemoResult);
begin
  D.Success := AFlow.Execute in [cwsCompleted, cwsNeedsVerification];
  D.ErrorClass := AFlow.ErrorClass;
  D.Text := UnicodeString(Log + 'Outcome: ' + CardWorkflowStateName(AFlow.State) + #13#10);
  if AFlow.State = cwsUncertain then D.Text := D.Text + 'Inspect the target before preparing another write.' + #13#10;
  if AFlow.State = cwsNeedsVerification then D.Text := D.Text + 'Reactivate the RF field and verify the active UID.' + #13#10;
end;

procedure Artifact(var D: TCardDemoResult; const Name, Text: string);
begin
  SetLength(D.Artifacts, 1); D.Artifacts[0].Name := Name;
  D.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(Text));
end;

procedure TOperations.Memory(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
  var D: TCardDemoResult);
var Flow: TCardMemoryCopyWorkflow; S, T: ICardWorkflowMemory; K: TDemoKeys;
  Keys: IClassicWorkflowKeys; Addresses: TCardWorkflowAddresses;
  Model: Integer; Snapshot: TCardWorkflowSnapshot; Results: TCardWorkflowUnits; I: Integer;
  CredentialFlow: TClassicCredentialWorkflow; Changes: TClassicSectorChanges;
  Lines: TStringList; Access: TBytes;
begin
  Model := StrToInt(string(R.Arguments[1])); S := nil; T := nil;
  if R.FamilyAction = 4 then
  begin
    if not(Model in [0 .. 2]) then raise ECardWorkflowError.Create('Classic model.');
    CredentialFlow := TClassicCredentialWorkflow.Create(nil); Lines := TStringList.Create;
    Changes := nil;
    try
      Access := HexToBytes(string(R.Arguments[3]));
      if Length(Access) <> 4 then raise ECardWorkflowError.Create('Three access bytes and one GPB required.');
      Lines.Text := string(R.Arguments[2]);
      if (Lines.Count < 1) or (Lines.Count > 40) then raise ECardWorkflowError.Create('One trailer address per line required.');
      SetLength(Changes, Lines.Count);
      for I := 0 to High(Changes) do
      begin
        Changes[I].TrailerBlock := StrToInt(Trim(Lines[I]));
        Changes[I].CurrentKeyType := mckA;
        Changes[I].CurrentKey := CopyBytes(R.Credentials[1]);
        SetLength(Changes[I].NewTrailer, 16);
        Move(R.Credentials[0][0], Changes[I].NewTrailer[0], 6);
        Move(Access[0], Changes[I].NewTrailer[6], 4);
        Move(R.Credentials[2][0], Changes[I].NewTrailer[10], 6);
      end;
      CredentialFlow.OnProgress := Progress;
      CredentialFlow.Prepare(Target, TMifareClassicModel(Model), Changes);
      Finish(CredentialFlow, D);
      Results := CredentialFlow.Results;
      for I := 0 to High(Results) do D.Text := D.Text + 'Trailer ' + UnicodeString(IntToStr(Results[I].Address)) + ': ' +
        UnicodeString(CardWorkflowUnitStateName(Results[I].State)) + #13#10;
    finally
      for I := 0 to High(Changes) do
      begin
        if Length(Changes[I].CurrentKey) > 0 then FillChar(Changes[I].CurrentKey[0], Length(Changes[I].CurrentKey), 0);
        if Length(Changes[I].NewTrailer) > 0 then FillChar(Changes[I].NewTrailer[0], Length(Changes[I].NewTrailer), 0);
      end;
      CredentialFlow.Free; Lines.Free;
    end;
    Exit;
  end;
  if R.FamilyName = 'ClassicWorkflowDemo' then
  begin
    if not (Model in [0 .. 2]) then raise ECardWorkflowError.Create('Classic model.');
    if Source <> nil then
    begin
      K := TDemoKeys.Create; Keys := K; K.Key := CopyBytes(R.Credentials[0]);
      S := TClassicWorkflowMemory.Create(Source, TMifareClassicModel(Model), Keys);
    end;
    if Target <> nil then
    begin
      K := TDemoKeys.Create; Keys := K; K.Key := CopyBytes(R.Credentials[1]);
      T := TClassicWorkflowMemory.Create(Target, TMifareClassicModel(Model), Keys);
    end;
    Addresses := TClassicWorkflowMemory.DataAddresses(TMifareClassicModel(Model));
    Flow := TMifareClassicCopyWorkflow.Create(nil);
  end
  else
  begin
    if not (Model in [0 .. 7]) then raise ECardWorkflowError.Create('Type 2 model.');
    if Source <> nil then S := TType2WorkflowMemory.Create(Source, TType2TagModel(Model));
    if Target <> nil then T := TType2WorkflowMemory.Create(Target, TType2TagModel(Model));
    Addresses := TType2WorkflowMemory.DataAddresses(TType2TagModel(Model));
    Flow := TType2MemoryWorkflow.Create(nil);
  end;
  try
    Flow.OnProgress := Progress;
    case R.FamilyAction of
      0: Flow.PrepareBackup(S, Addresses);
      1, 2: Flow.PrepareCopy(S, T, Addresses, R.FamilyAction = 2);
      3: begin Snapshot := TCardWorkflowArchive.Decode(string(R.Arguments[2])); Flow.PrepareRestore(Snapshot, T); end;
    end;
    Finish(Flow, D);
    Results := Flow.Results;
    for I := 0 to High(Results) do
      D.Text := D.Text + 'Unit ' + UnicodeString(IntToStr(Results[I].Address)) + ': ' +
        UnicodeString(CardWorkflowUnitStateName(Results[I].State)) + #13#10;
    if D.Success then Artifact(D, 'memory.erdsnapshot', TCardWorkflowArchive.Encode(Flow.Snapshot));
  finally Flow.Free; end;
end;

procedure TOperations.Uid(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
  var D: TCardDemoResult);
var Flow: TUidProgrammingWorkflow; Options: TUidWorkflowOptions; Raw: TRawUidProgrammer;
  Model: Integer; Requested: TBytes;
begin
  if R.FamilyAction = 0 then
  begin Artifact(D, 'uid.txt', BytesToHex(Source.ReadUid)); D.Success := True; Exit; end;
  if R.FamilyAction = 2 then raise ECardWorkflowError.Create('UID comparison uses independent UID reads.');
  Options := Default(TUidWorkflowOptions); Model := StrToInt(string(R.Arguments[1]));
  Options.KeyType := mckA; Options.Key := R.Credentials[1];
  case Model of
    0: begin Options.Profile := uwpGen2; Options.Gen2Model := cgum4Byte; end;
    1: begin Options.Profile := uwpGen2; Options.Gen2Model := cgum7Byte; end;
    2: Options.Profile := uwpFuid;
    3: begin Options.Profile := uwpRawClassic; Options.RawClassicProfile := crupGen1a; end;
    4: begin Options.Profile := uwpRawClassic; Options.RawClassicProfile := crupGen1b; end;
    5: begin Options.Profile := uwpRawClassic; Options.RawClassicProfile := crupUnsealedUfuid; end;
    6: Options.Profile := uwpType2Direct;
    7: begin Options.Profile := uwpGen3; Options.Gen3Size := g3us4Byte; end;
    8: begin Options.Profile := uwpGen3; Options.Gen3Size := g3us7Byte; end;
    9, 10, 11: begin Options.Profile := uwpGen4; Options.Gen4Layout := TGen4UidLayout(Model - 9);
      Options.Password := R.Credentials[1]; end;
  else raise ECardWorkflowError.Create('Select an explicit UID profile.'); end;
  Requested := nil;
  if R.FamilyAction = 3 then Requested := HexToBytes(Trim(string(R.Arguments[2])));
  Flow := TUidProgrammingWorkflow.Create(nil); Raw := TRawUidProgrammer.Create(nil);
  try
    if not(Options.Profile in [uwpGen2, uwpFuid]) then
      Raw.Reader := TAcr122RawReader.Create(Target.Transport, $0A, True);
    Flow.OnProgress := Progress;
    Flow.Prepare(Target, Raw, Options, Requested, Source);
    Finish(Flow, D);
    D.WriteVerified := Flow.ActiveUidVerified;
    D.Text := D.Text + 'Active UID verified: ' + UnicodeString(BoolToStr(Flow.ActiveUidVerified, True));
    if D.Success then Artifact(D, 'uid.txt', BytesToHex(Flow.RequestedUid));
  finally Flow.Free; Raw.Free; end;
end;

procedure TOperations.Ndef(const R: TCardDemoRequest; const Source, Target: TContactlessCardReader;
  var D: TCardDemoResult);
var Flow: TNdefTransferWorkflow; S, T: ICardWorkflowNdef;
  S2, T2: TType2NdefCardReader; S4, T4: TType4NdefCardReader; Model: Integer;
  Message: TNdefMessage;
begin
  if R.FamilyAction = 2 then raise ECardWorkflowError.Create('Use read-back to inspect NDEF.');
  Model := StrToInt(string(R.Arguments[1]));
  S2 := TType2NdefCardReader.Create(nil); T2 := TType2NdefCardReader.Create(nil);
  S4 := TType4NdefCardReader.Create(nil); T4 := TType4NdefCardReader.Create(nil);
  Flow := TNdefTransferWorkflow.Create(nil);
  try
    S := nil; T := nil;
    if Model < 8 then
    begin
      if Source <> nil then begin S2.Transport := Source.Transport; S2.Profile := TPcscStorageProfile.Create;
        S := TNdefWorkflowAdapters.Type2(S2, TType2TagModel(Model)); end;
      if Target <> nil then begin T2.Transport := Target.Transport; T2.Profile := TPcscStorageProfile.Create;
        T := TNdefWorkflowAdapters.Type2(T2, TType2TagModel(Model)); end;
    end
    else if Model = 8 then
    begin
      if Source <> nil then begin S4.Transport := Source.Transport; S := TNdefWorkflowAdapters.Type4(S4); end;
      if Target <> nil then begin T4.Transport := Target.Transport; T := TNdefWorkflowAdapters.Type4(T4); end;
    end
    else raise ECardWorkflowError.Create('NDEF model.');
    Flow.OnProgress := Progress;
    if R.FamilyAction = 3 then
    begin
      Message := TNdefCodec.Decode(HexToBytes(Trim(string(R.Arguments[2]))));
      Flow.PrepareWrite(T, Message);
    end
    else Flow.PrepareCopy(S, T);
    Finish(Flow, D); D.WriteVerified := Flow.ReadBackVerified;
    if D.Success then Artifact(D, 'ndef.hex', BytesToHex(Flow.MessageBytes));
  finally S := nil; T := nil; Flow.Free; S2.Free; T2.Free; S4.Free; T4.Free; end;
end;

procedure TOperations.Stripe(const R: TCardDemoRequest; var D: TCardDemoResult);
var Flow: TMagStripeCopyWorkflow; Source, Target: TMagStripeReaderWriter;
  Tracks: TMagStripeTracks; Lines: TStringList; I: Integer; Mask: Integer; Selection: TMagStripeTrackSet;
begin
  if R.FamilyAction = 2 then raise ECardWorkflowError.Create('Stripe comparison requires confirmed same-card read-back.');
  Mask := StrToInt(string(R.Arguments[1])) + 1; Selection := [];
  for I := 0 to 2 do if (Mask and (1 shl I)) <> 0 then Include(Selection, TMagStripeTrack(I));
  Source := TMagStripeReaderWriter.Create(nil); Target := TMagStripeReaderWriter.Create(nil);
  Flow := TMagStripeCopyWorkflow.Create(nil); Lines := TStringList.Create;
  try
    Source.TimeoutMs := 30000; Target.TimeoutMs := 30000;
    if R.FamilyAction <> 3 then Source.Device := TMsr2067HLMagStripeAdapter.Create(
      CreateWindowsMagStripeSerialPort(string(R.ReaderName), mssf7O1));
    if R.FamilyAction <> 0 then Target.Device := TMsr2067HLMagStripeAdapter.Create(
      CreateWindowsMagStripeSerialPort(string(R.Arguments[0]), mssf7O1));
    Flow.OnProgress := Progress;
    if R.FamilyAction = 0 then Flow.PrepareCopy(Source, nil, Selection, R.Coercivity)
    else if R.FamilyAction = 1 then Flow.PrepareCopy(Source, Target, Selection, R.Coercivity)
    else
    begin
      Lines.Text := string(R.Arguments[2]);
      if Lines.Count <> 3 then raise ECardWorkflowError.Create('Template must contain exactly three track lines.');
      for I := 0 to 2 do Tracks[TMagStripeTrack(I)] := Lines[I];
      Flow.PrepareWrite(Target, Selection, Tracks, R.Coercivity);
    end;
    Finish(Flow, D); D.WriteVerified := Flow.ReadBackVerified;
    if D.Success then
    begin
      Tracks := Flow.Data; Lines.Clear;
      for I := 0 to 2 do Lines.Add(Tracks[TMagStripeTrack(I)]);
      Artifact(D, 'tracks.txt', Lines.Text);
    end;
  finally Flow.Free; Source.Free; Target.Free; Lines.Free; end;
end;

constructor TBatchTemplates.Create;
begin inherited; Rows := TStringList.Create; Components := TList.Create; end;

destructor TBatchTemplates.Destroy;
var I: Integer;
begin
  for I := Components.Count - 1 downto 0 do TObject(Components[I]).Free;
  Components.Free; Rows.Free; inherited;
end;

function TBatchTemplates.CreateWorkflow(const AIdentifier: string): TCardWorkflow;
var Fields: TStringList; I: Integer; Transport: ICardTransport;
  Reader: TContactlessCardReader; Ndef: TType2NdefCardReader;
  Flow: TNdefTransferWorkflow; Message: TNdefMessage;
begin
  Result := nil; Fields := TStringList.Create;
  try
    Fields.StrictDelimiter := True; Fields.Delimiter := '|';
    for I := 0 to Rows.Count - 1 do
    begin
      Fields.DelimitedText := Rows[I];
      if Fields[0] <> AIdentifier then Continue;
      Message := TNdefCodec.Decode(HexToBytes(Fields[2]));
      Transport := Readers.CreateTransport(UnicodeString(Fields[1]));
      Reader := TContactlessCardReader.Create(nil); Components.Add(Reader);
      Reader.Transport := Transport; Reader.Profile := TPcscStorageProfile.Create;
      Ndef := TType2NdefCardReader.Create(nil); Components.Add(Ndef);
      Ndef.Transport := Reader.Transport; Ndef.Profile := TPcscStorageProfile.Create;
      Flow := TNdefTransferWorkflow.Create(nil);
      try Flow.PrepareWrite(TNdefWorkflowAdapters.Type2(Ndef, Model), Message);
      except Flow.Free; raise; end;
      Result := Flow; Exit;
    end;
    raise ECardWorkflowError.Create('Batch template not found.');
  finally Fields.Free; end;
end;

procedure TOperations.Batch(const R: TCardDemoRequest; var D: TCardDemoResult);
var Templates: TBatchTemplates; Factory: ICardBatchFactory;
  Flow: TCardBatchWorkflow; Fields, UsedReaders: TStringList;
  Ids: TCardBatchIdentifiers; I: Integer; Results: TCardBatchResults;
begin
  Templates := TBatchTemplates.Create; Factory := Templates;
  Flow := TCardBatchWorkflow.Create(nil); Fields := TStringList.Create; UsedReaders := TStringList.Create;
  try
    Templates.Readers := Readers; Templates.Model := TType2TagModel(StrToInt(string(R.Arguments[1])));
    Templates.Rows.Text := string(R.Arguments[2]);
    if (Templates.Rows.Count < 1) or (Templates.Rows.Count > 256) then
      raise ECardWorkflowError.Create('Provide one through 256 batch rows.');
    SetLength(Ids, Templates.Rows.Count);
    Fields.StrictDelimiter := True; Fields.Delimiter := '|';
    UsedReaders.CaseSensitive := True;
    for I := 0 to Templates.Rows.Count - 1 do
    begin
      Fields.DelimitedText := Templates.Rows[I];
      if (Fields.Count <> 3) or (Fields[1] = '') or (Fields[2] = '') then
        raise ECardWorkflowError.Create('Each row needs identifier|reader|NDEF hex.');
      if UsedReaders.IndexOf(Fields[1]) >= 0 then
        raise ECardWorkflowError.Create('This demo requires a distinct reader and presented card per row.');
      UsedReaders.Add(Fields[1]); Ids[I] := Fields[0];
      TNdefCodec.Decode(HexToBytes(Fields[2]));
    end;
    Flow.Prepare(Ids, Factory); Flow.OnProgress := Progress;
    Finish(Flow, D); Results := Flow.Results;
    for I := 0 to High(Results) do
      D.Text := D.Text + UnicodeString(Results[I].Identifier + ': attempted=' + BoolToStr(Results[I].Attempted, True) +
        ', ' + CardWorkflowStateName(Results[I].State) + ' ' + Results[I].ErrorClass + #13#10);
  finally Flow.Free; Fields.Free; UsedReaders.Free; Factory := nil; end;
end;

procedure TOperations.IsoMemory(const R: TCardDemoRequest; var D: TCardDemoResult);
var Flow: TIso15693MemoryWorkflow; Source, Target: ICardWorkflowMemory;
  Session: IIso15693Session; Adapter: TIso15693WorkflowMemory;
  Addresses: TCardWorkflowAddresses; Snapshot: TCardWorkflowSnapshot;
  Config: TStringList; Values: array [0 .. 4] of Integer; I: Integer;
begin
  Config := TStringList.Create; Flow := TIso15693MemoryWorkflow.Create(nil);
  try
    Config.StrictDelimiter := True; Config.Delimiter := '|'; Config.DelimitedText := string(R.Arguments[3]);
    if Config.Count <> 5 then raise ECardWorkflowError.Create('Provide ISO geometry, selection and response format.');
    for I := 0 to 4 do
      if not TryStrToInt(Config[I], Values[I]) then raise ECardWorkflowError.Create('Invalid ISO numeric configuration.');
    if not (Values[4] in [0 .. 1]) then raise ECardWorkflowError.Create('Invalid ISO response format.');
    if R.FamilyAction = 3 then Snapshot := TCardWorkflowArchive.Decode(string(R.Arguments[2]));
    if R.FamilyAction in [0 .. 2] then
    begin
      Session := TAcr1552Iso15693Session.Create(Readers.CreateTransport(R.ReaderName),
        TIso15693AddressMode(StrToInt(string(R.Arguments[1]))), TIso15693ResponseFormat(Values[4]));
      Adapter := TIso15693WorkflowMemory.Create(Session, Values[0], Values[1]); Source := Adapter;
      Addresses := Adapter.Addresses(Values[2], Values[3], False);
    end;
    if R.FamilyAction <> 0 then
    begin
      Session := TAcr1552Iso15693Session.Create(Readers.CreateTransport(R.Arguments[0]),
        TIso15693AddressMode(StrToInt(string(R.Arguments[1]))), TIso15693ResponseFormat(Values[4]));
      Adapter := TIso15693WorkflowMemory.Create(Session, Values[0], Values[1]); Target := Adapter;
      Adapter.Addresses(Values[2], Values[3], True);
    end;
    case R.FamilyAction of
      0: Flow.PrepareBackup(Source, Addresses);
      1, 2: Flow.PrepareCopy(Source, Target, Addresses, R.FamilyAction = 2);
      3: Flow.PrepareRestore(Snapshot, Target);
    end;
    Flow.OnProgress := Progress; Finish(Flow, D);
    for I := 0 to High(Flow.Results) do
      D.Text := D.Text + UnicodeString('Block ' + IntToStr(Flow.Results[I].Address) + ': ' +
        CardWorkflowUnitStateName(Flow.Results[I].State) + #13#10);
    if D.Success then Artifact(D, 'iso15693.erdsnapshot', TCardWorkflowArchive.Encode(Flow.Snapshot));
  finally Flow.Free; Config.Free; end;
end;

procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var S, T: TContactlessCardReader; Error: UnicodeString;
begin
  if not TryValidateRequest(ARequest, Error) then raise ECardWorkflowError.Create(string(Error));
  Log := ''; AResult := Default(TCardDemoResult); AResult.Operation := cdoFamily;
  if ARequest.FamilyName = 'MagStripeWorkflowDemo' then begin Stripe(ARequest, AResult); Exit; end;
  if ARequest.FamilyName = 'Iso15693WorkflowDemo' then begin IsoMemory(ARequest, AResult); Exit; end;
  if ARequest.FamilyName = 'BatchWorkflowDemo' then begin Batch(ARequest, AResult); Exit; end;
  S := nil; T := nil;
  try
    if ARequest.FamilyAction in [0 .. 2] then
    begin
      S := TContactlessCardReader.Create(nil);
      S.Transport := Readers.CreateTransport(ARequest.ReaderName); S.Profile := TPcscStorageProfile.Create;
    end;
    if ARequest.FamilyAction <> 0 then
    begin
      T := TContactlessCardReader.Create(nil);
      T.Transport := Readers.CreateTransport(ARequest.Arguments[0]); T.Profile := TPcscStorageProfile.Create;
    end;
    if ARequest.FamilyName = 'UidWorkflowDemo' then Uid(ARequest, S, T, AResult)
    else if ARequest.FamilyName = 'NdefWorkflowDemo' then Ndef(ARequest, S, T, AResult)
    else Memory(ARequest, S, T, AResult);
  finally S.Free; T.Free; end;
end;

function CreateCardWorkflowDemoOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var Operations: TOperations;
begin
  Operations := TOperations.Create; Result := Operations;
  Operations.Readers := AReaders;
  if Operations.Readers = nil then Operations.Readers := TNativeReaders.Create;
end;

end.
