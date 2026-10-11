unit ERD.Card.Demo.SimWorkflows;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Workflows;

/// <summary>Creates inactive workers for the independent SIM workflow form.</summary>
/// <param name="AReaders">Optional inactive test/application reader factory; nil uses native PC/SC.</param>
/// <returns>Nonvisual execution and metadata validation; no connection at construction.</returns>
function CreateSimWorkflowDemoOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

implementation

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.SIM.Data, ERD.Card.SIM.Reader,
  ERD.Card.SIM.Workflow, ERD.Card.SIM.Inspection;

type
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
    Readers: ICardWorkflowDemoReaders;
    Log: string;
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    procedure Finish(const AFlow: TCardWorkflow; var AResult: TCardDemoResult);
  end;
function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
var Profile, I: Integer;
begin
  AError := 'Choose the explicit SIM profile, reader, actual EF path and reviewed plan; acknowledge writes.';
  Result := (ARequest.Operation = cdoFamily) and (ARequest.FamilyName = 'SimWorkflowDemo') and
    (ARequest.FamilyAction in [0 .. 9]) and (Length(ARequest.Arguments) = 7) and (Length(ARequest.Credentials) = 1);
  if not Result then Exit;
  if ARequest.FamilyAction in [0, 1, 6] then Result := ARequest.ReaderName <> '';
  if ARequest.FamilyAction in [2, 3] then Result := ARequest.Arguments[0] <> '';
  if ARequest.FamilyAction = 3 then Result := Result and ARequest.MutationAcknowledged;
  if not TryStrToInt(string(ARequest.Arguments[1]), Profile) then Result := False
  else Result := Result and (Profile in [0 .. 1]);
  Result := Result and (Length(ARequest.Arguments[2]) <= 10 * 1024 * 1024) and (Length(ARequest.Arguments[6]) <= 1024 * 1024);
  if Length(ARequest.Credentials[0]) > 0 then begin Result := Result and (Length(ARequest.Credentials[0]) >= 4) and
    (Length(ARequest.Credentials[0]) <= 8); for I := 0 to High(ARequest.Credentials[0]) do
      Result := Result and (ARequest.Credentials[0][I] in [Ord('0') .. Ord('9')]); end;
  if Result then AError := '';
end;
procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin Log := Log + CardWorkflowStateName(AState) + ': ' + IntToStr(ADone) + '/' + IntToStr(ATotal) + #13#10; end;
procedure TOperations.Finish(const AFlow: TCardWorkflow; var AResult: TCardDemoResult);
begin AFlow.OnProgress := Progress; AResult.Success := AFlow.Execute = cwsCompleted;
  AResult.ErrorClass := AFlow.ErrorClass; AResult.Text := UnicodeString(Log + 'Outcome: ' + CardWorkflowStateName(AFlow.State) + #13#10); end;
procedure Artifact(var R: TCardDemoResult; const Name, Value: string);
begin SetLength(R.Artifacts, 1); R.Artifacts[0].Name := Name; R.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(Value)); end;
function Address(const Text: UnicodeString): TSimFileAddress;
var L, P: TStringList; I, Root: Integer; B: TBytes;
begin
  L := TStringList.Create; P := TStringList.Create;
  try
    L.StrictDelimiter := True; L.Delimiter := '|'; L.QuoteChar := #0; L.DelimitedText := string(Text);
    if L.Count <> 2 then raise ECardWorkflowError.Create('Use root|FIDhex,FIDhex for the actual file path.');
    Root := StrToInt(L[0]); if not (Root in [0 .. 1]) then raise ECardWorkflowError.Create('Invalid file root.');
    P.StrictDelimiter := True; P.Delimiter := ','; P.QuoteChar := #0; P.DelimitedText := L[1];
    if (P.Count < 1) or (P.Count > 8) then raise ECardWorkflowError.Create('Invalid file path length.');
    Result.Root := TSimFileRoot(Root); SetLength(Result.Path, P.Count);
    for I := 0 to P.Count - 1 do begin B := HexToBytes(P[I]); if Length(B) <> 2 then raise ECardWorkflowError.Create('Use four hex digits per FID.');
      Result.Path[I] := Word(B[0]) shl 8 or B[1]; end;
    Result := TSimCodec.FileAddress(Result.Root, Result.Path);
  finally P.Free; L.Free; end;
end;
procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var Error, Name: UnicodeString; Reader: TSimCardReaderWriter; Backend: ISimWorkflowCard;
  Flow: TSimRecordWorkflow; Inspection: TSimInspectionWorkflow; Snapshot: TSimWorkflowSnapshot;
  Plan: TSimWorkflowPlan; Results: TSimWorkflowResults; L, Fields: TStringList; Contacts: TSimPhonebookEntries; Rich: TSimWorkflowContacts; Records: TSimRecords;
  Joined: TSimAssembledSms; FileAddress: TSimFileAddress; I, Profile, Pbr, Attempts, IncludeExt: Integer; Aid: TBytes;
begin
  if not TryValidateRequest(ARequest, Error) then raise ECardWorkflowError.Create(string(Error));
  AResult := Default(TCardDemoResult); AResult.Operation := cdoFamily; Log := '';
  Reader := nil; Flow := nil; Inspection := nil; L := TStringList.Create; Fields := TStringList.Create;
  try
    if ARequest.FamilyAction in [2, 4, 5, 8, 9] then Snapshot := TSimWorkflowCodec.DecodeSnapshot(string(ARequest.Arguments[2]));
    if ARequest.FamilyAction = 3 then Plan := TSimWorkflowCodec.DecodePlan(string(ARequest.Arguments[2]));
    if ARequest.FamilyAction in [4, 5, 7, 8, 9] then
    begin
      if ARequest.FamilyAction = 8 then AResult.Text := TSimWorkflowCodec.Report(Snapshot)
      else if ARequest.FamilyAction = 4 then
      begin
        L.Text := string(ARequest.Arguments[6]); if (L.Count < 1) or (L.Count > 255) then raise ECardWorkflowError.Create('Provide name TAB number, one contact per line.');
        SetLength(Contacts, L.Count); SetLength(Rich, L.Count);
        for I := 0 to L.Count - 1 do
        begin
          Fields.StrictDelimiter := True; Fields.Delimiter := #9; Fields.QuoteChar := #0; Fields.DelimitedText := L[I];
          if (Fields.Count < 2) or (Fields.Count > 4) then raise ECardWorkflowError.Create('Use name TAB number [TAB email TAB ANR].');
          Rich[I].Name := UnicodeString(Fields[0]); Rich[I].Number := UnicodeString(Fields[1]);
          if Fields.Count > 2 then Rich[I].Email := UnicodeString(Fields[2]);
          if Fields.Count > 3 then Rich[I].AdditionalNumber := UnicodeString(Fields[3]);
          Contacts[I] := Default(TSimPhonebookEntry); Contacts[I].Name := Rich[I].Name; Contacts[I].Number := Rich[I].Number;
          Contacts[I].CapabilityRecord := $FF; Contacts[I].ExtensionRecord := $FF;
        end;
        if Length(Snapshot.Files) > 1 then Plan := TSimWorkflowCodec.ImportLinkedContacts(Snapshot, Rich)
        else begin
          for I := 0 to High(Rich) do if (Rich[I].Email <> '') or (Rich[I].AdditionalNumber <> '') then
            raise ECardWorkflowError.Create('Capture an explicit linked layout for EMAIL/ANR.');
          Plan := TSimWorkflowCodec.ImportContacts(Snapshot, Contacts);
        end;
        Artifact(AResult, 'sim.erdplan', TSimWorkflowCodec.EncodePlan(Plan));
      end
      else
      begin
        L.StrictDelimiter := True; L.Delimiter := ';'; L.QuoteChar := #0; L.DelimitedText := string(ARequest.Arguments[6]);
        if (L.Count < 1) or (L.Count > 255) then raise ECardWorkflowError.Create('Provide explicit complete SMS records separated by semicolons.');
        SetLength(Records, L.Count); for I := 0 to L.Count - 1 do Records[I] := HexToBytes(Trim(L[I]));
        if ARequest.FamilyAction in [5, 9] then begin
          if ARequest.FamilyAction = 9 then Plan := TSimWorkflowCodec.ImportSmsGroup(Snapshot, Records)
          else Plan := TSimWorkflowCodec.ImportSms(Snapshot, Records);
          Artifact(AResult, 'sim.erdplan', TSimWorkflowCodec.EncodePlan(Plan)); end
        else begin Joined := TSimCodec.AssembleSms(Records); if Joined.TextDecoded then AResult.Text := Joined.Text
          else AResult.Text := UnicodeString(BytesToHex(Joined.BinaryPayload)); end;
      end;
      if ARequest.FamilyAction in [4, 5, 9] then AResult.Text := UnicodeString('Planned records: ' + IntToStr(Length(Plan.Changes)) + #13#10);
      AResult.Success := True; Exit;
    end;
    Profile := StrToInt(string(ARequest.Arguments[1])); Aid := HexToBytes(string(ARequest.Arguments[4]));
    if ((Profile = 0) and (Length(Aid) <> 0)) or ((Profile = 1) and ((Length(Aid) < 5) or (Length(Aid) > 16))) then
      raise ECardWorkflowError.Create('Supply a full USIM AID or leave it empty for classic SIM.');
    L.StrictDelimiter := True; L.Delimiter := '|'; L.QuoteChar := #0; L.DelimitedText := string(ARequest.Arguments[5]);
    if L.Count <> 3 then raise ECardWorkflowError.Create('Provide PBR record, retry budget and explicit classic EXT choice.');
    Pbr := StrToInt(L[0]); Attempts := StrToInt(L[1]); IncludeExt := StrToInt(L[2]);
    if not (IncludeExt in [0 .. 1]) then raise ECardWorkflowError.Create('Invalid classic EXT choice.'); if (Pbr < 0) or (Pbr > 255) or (Attempts < 1) or (Attempts > 15) then
      raise ECardWorkflowError.Create('Invalid PBR record or PIN retry budget.');
    if ARequest.FamilyAction in [0, 1] then FileAddress := Address(ARequest.Arguments[3]);
    Reader := TSimCardReaderWriter.Create(nil); Reader.Profile := TSimCardProfile(Profile); Reader.ApplicationAid := Aid;
    Reader.MinimumPinAttempts := Attempts; Name := ARequest.ReaderName;
    if ARequest.FamilyAction in [2, 3] then Name := ARequest.Arguments[0];
    Reader.Transport := Readers.CreateTransport(Name);
    if ARequest.FamilyAction = 6 then
    begin
      Inspection := TSimInspectionWorkflow.Create(nil); Inspection.Prepare(Reader, ARequest.Credentials[0]);
      Finish(Inspection, AResult); AResult.Text := AResult.Text + Inspection.Report; Exit;
    end;
    Backend := TSimWorkflowCard.Create(Reader);
    if (ARequest.FamilyAction = 1) or ((ARequest.FamilyAction = 2) and (Snapshot.Kind = swkSms)) or
      ((ARequest.FamilyAction = 3) and (Plan.Kind = swkSms)) then Flow := TSimSmsWorkflow.Create(nil)
    else Flow := TSimPhonebookWorkflow.Create(nil);
    case ARequest.FamilyAction of
      0, 1: if (ARequest.FamilyAction = 0) and (IncludeExt = 1) then
        begin
          if (FileAddress.Root <> sfrMasterFile) or (Length(FileAddress.Path) <> 2) or
            (FileAddress.Path[0] <> $7F10) or (FileAddress.Path[1] <> $6F3A) or (Pbr <> 0) then
            raise ECardWorkflowError.Create('Classic EXT backup requires standard ADN and no PBR.');
          TSimPhonebookWorkflow(Flow).PrepareClassicBackup(Backend, ARequest.Credentials[0]);
        end
        else Flow.PrepareBackup(Backend, FileAddress, Pbr, ARequest.Credentials[0]);
      2: Flow.PreparePreview(Backend, Snapshot, ARequest.Credentials[0]);
      3: Flow.PrepareApply(Backend, Plan, ARequest.Credentials[0]);
    end;
    Finish(Flow, AResult);
    if AResult.Success then
      case ARequest.FamilyAction of
        0, 1: begin Snapshot := Flow.Snapshot; AResult.Text := AResult.Text + TSimWorkflowCodec.Report(Snapshot);
          Artifact(AResult, 'sim.erdsnapshot', TSimWorkflowCodec.EncodeSnapshot(Snapshot)); end;
        2: begin Plan := Flow.Plan; AResult.Text := AResult.Text + UnicodeString('Planned records: ' + IntToStr(Length(Plan.Changes)) + #13#10);
          Artifact(AResult, 'sim.erdplan', TSimWorkflowCodec.EncodePlan(Plan)); end;
      end;
    if ARequest.FamilyAction in [2, 3] then
    begin
      Plan := Flow.Plan; Results := Flow.Results;
      for I := 0 to High(Plan.Changes) do
      begin
        AResult.Text := AResult.Text + UnicodeString('EF ' + IntToHex(Plan.Changes[I].FileAddress.Path[High(Plan.Changes[I].FileAddress.Path)], 4) +
          ' record ' + IntToStr(Plan.Changes[I].RecordNumber) + ': ');
        if ARequest.FamilyAction = 3 then begin
          if I < Length(Results) then AResult.Text := AResult.Text + UnicodeString(CardWorkflowUnitStateName(Results[I].State))
          else AResult.Text := AResult.Text + 'Not attempted';
        end
        else AResult.Text := AResult.Text + UnicodeString(BytesToHex(Plan.Changes[I].ExpectedBefore) + ' -> ' + BytesToHex(Plan.Changes[I].Data));
        AResult.Text := AResult.Text + #13#10;
      end;
    end;
  finally Flow.Free; Inspection.Free; Backend := nil; Reader.Free; Fields.Free; L.Free; end;
end;
function CreateSimWorkflowDemoOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var O: TOperations;
begin O := TOperations.Create; Result := O; O.Readers := AReaders;
  if O.Readers = nil then O.Readers := CreateNativeCardWorkflowDemoReaders; end;

end.
