unit ERD.Card.Demo.FamilyWorkflows;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Workflows;

/// <summary>Creates inactive workers for the independent contact-memory and DESFire workflow forms.</summary>
/// <param name="AReaders">Optional injected inactive connection factory; nil uses native PC/SC.</param>
/// <returns>Nonvisual request executor and metadata validator.</returns>
function CreateCardFamilyWorkflowOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

implementation

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows,
{$ELSE}
  ERD.Card.Crypto.OpenSSL,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Workflow, ERD.Card.Memory,
  ERD.Card.Memory.Workflow, ERD.Card.Contactless.DESFire,
  ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.Workflow.DESFire;

type
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
    Readers: ICardWorkflowDemoReaders;
    Log: string;
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    procedure Finish(const AFlow: TCardWorkflow; var AResult: TCardDemoResult);
    procedure Memory(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure Desfire(const R: TCardDemoRequest; var D: TCardDemoResult);
  end;
function KeyWidth(const Security: Integer): Integer;
begin
  Result := 16; case Security of 0: Result := 0; 4: Result := 24; 5: Result := 8; end;
end;
function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
var Model: Integer; L: TMemoryCardLayout;
begin
  AError := 'Choose readers, explicit geometry/security and acknowledge writes.';
  Result := (ARequest.Operation = cdoFamily) and (Length(ARequest.Arguments) = 4) and
    (Length(ARequest.Credentials) = 3) and (ARequest.FamilyAction in [0 .. 4]);
  if not Result then Exit;
  Result := (ARequest.FamilyName = 'ContactMemoryWorkflowDemo') or (ARequest.FamilyName = 'DesfireWorkflowDemo');
  if not Result then Exit;
  if ARequest.FamilyAction in [0 .. 2] then Result := ARequest.ReaderName <> '';
  if ARequest.FamilyAction <> 0 then Result := Result and (ARequest.Arguments[0] <> '');
  if ARequest.FamilyAction in [1, 2] then Result := Result and (ARequest.ReaderName <> ARequest.Arguments[0]);
  if ARequest.FamilyAction in [1, 3, 4] then Result := Result and ARequest.MutationAcknowledged;
  if not TryStrToInt(string(ARequest.Arguments[1]), Model) then Result := False;
  if not Result then Exit;
  if ARequest.FamilyName = 'ContactMemoryWorkflowDemo' then
  begin
    Result := (Model >= Ord(Low(TMemoryCardModel))) and (Model <= Ord(High(TMemoryCardModel))) and
      (ARequest.FamilyAction < 4);
    if Result then begin L := TMemoryCardCodec.Layout(TMemoryCardModel(Model));
      if ARequest.FamilyAction in [1, 3] then Result := Length(ARequest.Credentials[1]) = L.PinBytes; end;
  end
  else
  begin
    Result := Model in [0 .. 6];
    if Result then begin
      if ARequest.FamilyAction in [0, 1, 2, 4] then Result := Length(ARequest.Credentials[0]) = KeyWidth(Model);
      if ARequest.FamilyAction <> 0 then Result := Result and (Length(ARequest.Credentials[1]) = KeyWidth(Model));
    end;
  end;
  Result := Result and (Length(ARequest.Arguments[2]) <= 3 * 1024 * 1024);
  if Result then AError := '';
end;
procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin Log := Log + CardWorkflowStateName(AState) + ': ' + IntToStr(ADone) + '/' + IntToStr(ATotal) + #13#10; end;
procedure TOperations.Finish(const AFlow: TCardWorkflow; var AResult: TCardDemoResult);
begin
  AFlow.OnProgress := Progress; AResult.Success := AFlow.Execute = cwsCompleted;
  AResult.ErrorClass := AFlow.ErrorClass;
  AResult.Text := UnicodeString(Log + 'Outcome: ' + CardWorkflowStateName(AFlow.State) + #13#10);
  if AFlow.State = cwsUncertain then AResult.Text := AResult.Text + 'Inspect the card before preparing another write.' + #13#10;
end;
procedure Artifact(var D: TCardDemoResult; const Name, Text: string);
begin
  SetLength(D.Artifacts, 1); D.Artifacts[0].Name := Name;
  D.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(Text));
end;
procedure Numbers(const Text: UnicodeString; const Count: Integer; const Values: TStringList);
var I, N: Integer;
begin
  Values.StrictDelimiter := True; Values.Delimiter := '|'; Values.DelimitedText := string(Text);
  if Values.Count <> Count then raise ECardWorkflowError.Create('Wrong number of explicit configuration fields.');
  for I := 0 to Values.Count - 1 do if not TryStrToInt(Values[I], N) then
    raise ECardWorkflowError.Create('Invalid decimal configuration field.');
end;
procedure TOperations.Memory(const R: TCardDemoRequest; var D: TCardDemoResult);
var Source, Target: TMemoryCardReaderWriter; S, T: IContactMemoryWorkflowCard;
  Config: TStringList; Page, I, Address, Count, Attempts, Dialect: Integer;
  Flow: TContactMemoryWorkflow; Snapshot: TMemoryCardSnapshot;
  function Reader(const Name: UnicodeString): TMemoryCardReaderWriter;
  begin
    Result := TMemoryCardReaderWriter.Create(nil);
    try
      Result.Model := TMemoryCardModel(StrToInt(string(R.Arguments[1])));
      Result.PageSize := TMemoryCardPageSize(Page); Result.Dialect := TAcsMemoryDialect(Dialect);
      Result.MinimumPinAttempts := Attempts; Result.Transport := Readers.CreateTransport(Name);
    except Result.Free; raise; end;
  end;
begin
  Config := TStringList.Create; Source := nil; Target := nil; Flow := TContactMemoryWorkflow.Create(nil);
  try
    Numbers(R.Arguments[3], 5, Config); Page := -1;
    for I := 0 to 4 do if (8 shl I) = StrToInt(Config[0]) then Page := I;
    Dialect := StrToInt(Config[1]); Address := StrToInt(Config[2]); Count := StrToInt(Config[3]); Attempts := StrToInt(Config[4]);
    if (Page < 0) or not (Dialect in [0 .. 1]) or (Attempts < 1) or (Attempts > 8) then
      raise ECardWorkflowError.Create('Invalid contact page size, dialect or PIN budget.');
    if R.FamilyAction = 3 then Snapshot := TContactMemoryWorkflowArchive.Decode(string(R.Arguments[2]));
    if R.FamilyAction in [0 .. 2] then begin Source := Reader(R.ReaderName); S := TContactMemoryWorkflowCard.Create(Source); end;
    if R.FamilyAction <> 0 then begin Target := Reader(R.Arguments[0]); T := TContactMemoryWorkflowCard.Create(Target); end;
    case R.FamilyAction of
      0: Flow.PrepareBackup(S);
      1, 2: Flow.PrepareCopy(S, T, Address, Count, R.Credentials[1], R.FamilyAction = 2);
      3: Flow.PrepareRestore(Snapshot, T, Address, Count, R.Credentials[1]);
    end;
    Finish(Flow, D);
    for I := 0 to High(Flow.Results) do D.Text := D.Text + UnicodeString('Byte ' +
      IntToStr(Flow.Results[I].Address) + ', count ' + IntToStr(Length(Flow.Results[I].Data)) + ': ' +
      CardWorkflowUnitStateName(Flow.Results[I].State) + #13#10);
    if D.Success then Artifact(D, 'contact-memory.erdsnapshot', TContactMemoryWorkflowArchive.Encode(Flow.Snapshot));
  finally Flow.Free; S := nil; T := nil; Source.Free; Target.Free; Config.Free; end;
end;
procedure TOperations.Desfire(const R: TCardDemoRequest; var D: TCardDemoResult);
var Source, Target: TDesfireCardReader; S, T: IDesfireWorkflowCard; Config, Lines, Fields: TStringList;
  SourceAid, TargetAid: Cardinal; KeyNumber, Minimum, Limit, Frame, Security, I, J: Integer;
  Access: TDesfireSessionAccess; Flow: TDesfireApplicationWorkflow; Provision: TDesfireProvisionWorkflow;
  Snapshot: TDesfireWorkflowSnapshot; Definitions: TDesfireWorkflowDefinitions;
  Policy, Keys, Storage: Integer;
  function Reader(const Name: UnicodeString; const Key: TBytes): TDesfireCardReader;
  begin
    Result := TDesfireCardReader.Create(nil);
    try
      Result.Security := TDesfireSecurity(Security); Result.KeyNumber := KeyNumber;
      Result.MinimumCommunication := TDesfireCommunication(Minimum); Result.AuthenticationKey := Key;
      Result.MaxTransferBytes := Limit; Result.MaxFrameDataBytes := Frame;
      if Security <> 0 then
{$IFDEF MSWINDOWS}
        Result.CryptoProvider := TCardWindowsAesProvider.Create;
{$ELSE}
        Result.CryptoProvider := TCardOpenSslAesProvider.Create;
{$ENDIF}
      Result.Transport := Readers.CreateTransport(Name);
    except Result.Free; raise; end;
  end;
  function Number(const Index: Integer): Integer;
  begin Result := StrToInt(Fields[Index]); end;
begin
  Config := TStringList.Create; Lines := TStringList.Create; Fields := TStringList.Create;
  Source := nil; Target := nil; Flow := nil; Provision := nil;
  try
    Numbers(R.Arguments[3], 7, Config); Security := StrToInt(string(R.Arguments[1]));
    I := StrToInt(Config[0]); J := StrToInt(Config[1]);
    if (I < 1) or (I > $FFFFFF) or (J < 1) or (J > $FFFFFF) then raise ECardWorkflowError.Create('Invalid native AID.');
    SourceAid := I; TargetAid := J; KeyNumber := StrToInt(Config[2]); Minimum := StrToInt(Config[3]);
    Limit := StrToInt(Config[4]); Frame := StrToInt(Config[5]);
    if not (StrToInt(Config[6]) in [0 .. 1]) then raise ECardWorkflowError.Create('Choose an explicit transaction policy.');
    Access := dsaFreshTransaction; if StrToInt(Config[6]) = 1 then Access := dsaDiscardPending;
    if (KeyNumber < 0) or (KeyNumber > 13) or not (Minimum in [0 .. 2]) or
      (Limit < 1) or (Limit > DesfireMaxTransferBytes) or (Frame < 1) or (Frame > 248) then
      raise ECardWorkflowError.Create('Invalid DESFire key, communication or transfer limits.');
    if R.FamilyAction = 3 then Snapshot := TDesfireWorkflowArchive.Decode(string(R.Arguments[2]));
    if R.FamilyAction = 4 then
    begin
      Lines.Text := string(R.Arguments[2]);
      if (Lines.Count < 2) or (Lines.Count > 34) or (Lines[0] <> 'ERD-DESFIRE-PROVISION 1') then
        raise ECardWorkflowError.Create('Provide a bounded explicit provisioning template.');
      Numbers(UnicodeString(Lines[1]), 3, Fields); Policy := Number(0); Keys := Number(1); Storage := Number(2);
      if (Policy < 0) or (Policy > 255) or (Keys < 1) or (Keys > 14) or not (Storage in [0 .. 2]) then
        raise ECardWorkflowError.Create('Invalid application policy or key type.');
      SetLength(Definitions, Lines.Count - 2);
      for I := 2 to Lines.Count - 1 do
      begin
        Numbers(UnicodeString(Lines[I]), 14, Fields);
        for J := 0 to 6 do if (Number(J) < 0) or (Number(J) > 255) then
          raise ECardWorkflowError.Create('Invalid file definition byte.');
        if not (Number(1) in [0 .. 4]) or not (Number(2) in [0 .. 2]) or not (Number(11) in [0 .. 1]) then
          raise ECardWorkflowError.Create('Invalid file type, communication or flag.');
        Definitions[I - 2] := Default(TDesfireFileDefinition);
        with Definitions[I - 2] do begin
          FileNumber := Number(0); FileType := TDesfireFileType(Number(1)); Communication := TDesfireCommunication(Number(2));
          ReadKey := Number(3); WriteKey := Number(4); ReadWriteKey := Number(5); ChangeKey := Number(6);
          FileBytes := Number(7); LowerLimit := Number(8); UpperLimit := Number(9); InitialValue := Number(10);
          LimitedCreditEnabled := Number(11) = 1; RecordBytes := Number(12); MaxRecords := Number(13);
        end;
        TDesfireCodec.ValidateDefinition(Definitions[I - 2]);
      end;
      Source := Reader(R.Arguments[0], R.Credentials[0]); S := TDesfireWorkflowCard.Create(Source);
      Target := Reader(R.Arguments[0], R.Credentials[1]); T := TDesfireWorkflowCard.Create(Target);
      Provision := TDesfireProvisionWorkflow.Create(nil);
      Provision.Prepare(S, T, TargetAid, Policy, Keys, TDesfireApplicationKeyType(Storage), Definitions);
      Finish(Provision, D); D.Text := D.Text + UnicodeString('Application created: ' + BoolToStr(Provision.ApplicationCreated, True) + #13#10);
      for I := 0 to High(Provision.Results) do D.Text := D.Text + UnicodeString('File ' + IntToStr(Provision.Results[I].Address) + ': ' + CardWorkflowUnitStateName(Provision.Results[I].State) + #13#10);
      Exit;
    end;
    if R.FamilyAction in [0 .. 2] then begin Source := Reader(R.ReaderName, R.Credentials[0]); S := TDesfireWorkflowCard.Create(Source); end;
    if R.FamilyAction <> 0 then begin Target := Reader(R.Arguments[0], R.Credentials[1]); T := TDesfireWorkflowCard.Create(Target); end;
    Flow := TDesfireApplicationWorkflow.Create(nil);
    case R.FamilyAction of
      0: Flow.PrepareBackup(S, SourceAid);
      1, 2: Flow.PrepareCopy(S, T, SourceAid, TargetAid, Access, R.FamilyAction = 2);
      3: Flow.PrepareRestore(Snapshot, T, TargetAid, Access);
    end;
    Finish(Flow, D);
    for I := 0 to High(Flow.Results) do D.Text := D.Text + UnicodeString('File ' + IntToStr(Flow.Results[I].Address) + ': ' + CardWorkflowUnitStateName(Flow.Results[I].State) + #13#10);
    if D.Success then Artifact(D, 'desfire.erdsnapshot', TDesfireWorkflowArchive.Encode(Flow.Snapshot));
  finally Flow.Free; Provision.Free; S := nil; T := nil; Source.Free; Target.Free; Config.Free; Lines.Free; Fields.Free; end;
end;
procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var Error: UnicodeString;
begin
  if not TryValidateRequest(ARequest, Error) then raise ECardWorkflowError.Create(string(Error));
  Log := ''; AResult := Default(TCardDemoResult); AResult.Operation := cdoFamily;
  if ARequest.FamilyName = 'ContactMemoryWorkflowDemo' then Memory(ARequest, AResult)
  else Desfire(ARequest, AResult);
end;
function CreateCardFamilyWorkflowOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var Operations: TOperations;
begin
  Operations := TOperations.Create; Result := Operations; Operations.Readers := AReaders;
  if Operations.Readers = nil then Operations.Readers := CreateNativeCardWorkflowDemoReaders;
end;

end.
