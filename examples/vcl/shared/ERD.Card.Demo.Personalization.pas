unit ERD.Card.Demo.Personalization;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Workflows;

/// <summary>Creates inactive workers for independent SLE and DESFire personalization forms.</summary>
/// <param name="AReaders">Optional injected inactive factory; nil selects native PC/SC.</param>
/// <returns>Metadata validator and bounded workflow executor.</returns>
function CreateCardPersonalizationDemoOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

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
  ERD.Card.Transport, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Workflow,
  ERD.Card.Memory.Sle4404, ERD.Card.Memory.Counter, ERD.Card.Memory.Workflow.Sle,
  ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.Workflow.DESFire, ERD.Card.Contactless.Workflow.Personalization;

type
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
    Readers: ICardWorkflowDemoReaders;
    Log: string;
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    procedure Sle(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure Desfire(const R: TCardDemoRequest; var D: TCardDemoResult);
  end;
procedure Invalid;
begin raise ECardWorkflowError.Create('Check the explicit profile, geometry, keys and acknowledgement.'); end;
function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
begin
  AError := 'Choose a reader, bounded explicit profile and acknowledge mutations.';
  Result := (ARequest.Operation = cdoFamily) and
    (Length(ARequest.Arguments) = 4) and (Length(ARequest.Credentials) <= 256) and
    (Length(ARequest.Arguments[2]) <= 300000) and (ARequest.FamilyAction in [0..3]) and
    ((ARequest.FamilyName = 'Sle4404WorkflowDemo') or (ARequest.FamilyName = 'SleCounterWorkflowDemo') or
     (ARequest.FamilyName = 'DesfirePersonalizationDemo'));
  if Result then Result := (ARequest.ReaderName <> '') or
    ((ARequest.FamilyAction = 3) and (ARequest.FamilyName <> 'DesfirePersonalizationDemo'));
  if Result then
    if ARequest.FamilyName = 'DesfirePersonalizationDemo' then
      Result := (ARequest.FamilyAction <= 2) and ((ARequest.FamilyAction <> 0) or ARequest.MutationAcknowledged)
    else Result := (ARequest.FamilyAction <> 2) or ARequest.MutationAcknowledged;
  if Result then AError := '';
end;
procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin Log := Log + CardWorkflowStateName(AState) + ' ' + IntToStr(ADone) + '/' + IntToStr(ATotal) + #13#10; end;
procedure Fields(const Text: string; const Count: Integer; const Values: TStringList);
begin
  Values.StrictDelimiter := True; Values.Delimiter := '|'; Values.DelimitedText := Text;
  if Values.Count <> Count then Invalid;
end;
function Number(const S: string; const Minimum, Maximum: Integer): Integer;
begin if not TryStrToInt(S, Result) or (Result < Minimum) or (Result > Maximum) then Invalid; end;
procedure Finish(const F: TCardWorkflow; var D: TCardDemoResult; const Log: string);
var R: TCardWorkflowUnits; P: TDesfirePersonalizationResults; I: Integer;
begin
  D.Success := F.State = cwsCompleted; D.ErrorClass := F.ErrorClass;
  D.Text := UnicodeString(Log + 'Outcome: ' + CardWorkflowStateName(F.State) + #13#10);
  R := nil;
  if F is TSleProgrammingWorkflow then R := TSleProgrammingWorkflow(F).Results;

  for I := 0 to High(R) do D.Text := D.Text + UnicodeString('Step ' + IntToStr(I + 1) + ': ' +
    CardWorkflowUnitStateName(R[I].State) + #13#10);
  if F is TDesfirePersonalizationWorkflow then
  begin
    P := TDesfirePersonalizationWorkflow(F).Results;
    for I := 0 to High(P) do
      D.Text := D.Text + UnicodeString('Step ' + IntToStr(I + 1) + ': ' + CardWorkflowStateName(P[I].State) +
        ', attempted=' + BoolToStr(P[I].Attempted, True) + ', revalidated=' + BoolToStr(P[I].Revalidated, True) + #13#10);
  end;
  if F is TDesfirePersonalizationWorkflow then
    if TDesfirePersonalizationWorkflow(F).LastChild <> nil then
      D.Text := D.Text + UnicodeString('Last child: ' +
        TDesfirePersonalizationWorkflow(F).LastChild.ClassName + ', ' +
        CardWorkflowStateName(TDesfirePersonalizationWorkflow(F).LastChild.State) + #13#10);
end;
procedure TOperations.Sle(const R: TCardDemoRequest; var D: TCardDemoResult);
var Reader: TSle4404CardReaderWriter; Counter: TSleCounterCardReaderWriter; C: ISleWorkflowCard;
  L: TSle4404AccessLayout; Config: TStringList; Steps: TSleWorkflowSteps;
  F: TSleProgrammingWorkflow; Prefix, Base, Count, Model: Integer; Text: string;
  UserCode, MemoryCode: TBytes; Snapshot: TSleWorkflowSnapshot; Action: TSleWorkflowAction;
begin
  Reader := nil; Counter := nil; F := nil; Config := TStringList.Create;
  UserCode := nil; MemoryCode := nil;
  try
    // Parse complete plan and geometry before requesting even an inactive transport.
    Steps := nil; if R.FamilyAction in [1, 2] then Steps := TSleWorkflowArchive.DecodePlan(string(R.Arguments[2]));
    Model := Number(string(R.Arguments[1]), 0, 3);
    if R.FamilyName = 'Sle4404WorkflowDemo' then
    begin
      Fields(string(R.Arguments[3]), 13, Config);
      Base := Number(Config[0], 0, 255); Count := Number(Config[1], 1, 256);
      Reader := TSle4404CardReaderWriter.Create(nil);
      Reader.ReadableBytes := Number(Config[2], 1, 256);
      L := Reader.Layout; L.UserCounterAddress := Number(Config[3], -1, 255);
      L.UserCounterMask := Number(Config[4], 0, 255); L.MemoryCounterAddress := Number(Config[5], -1, 255);
      L.ScratchPadAddress := Number(Config[6], -1, 255); L.ScratchPadBytes := Number(Config[7], 0, 256);
      L.ApplicationAddress := Number(Config[8], -1, 255); L.ApplicationBytes := Number(Config[9], 0, 256);
      Reader.Layout := L; Reader.MinimumUserCodeAttempts := Number(Config[10], 1, 4);
      Reader.MinimumMemoryCodeAttempts := Number(Config[11], 1, 64); Prefix := Number(Config[12], 0, 256);
      if Length(R.Credentials) <> 2 then Invalid;
      UserCode := CopyBytes(R.Credentials[0]); MemoryCode := CopyBytes(R.Credentials[1]);
      C := TSle4404WorkflowCard.Create(Reader, Base, Count, UserCode, MemoryCode);
      F := TSle4404Workflow.Create(nil);
    end
    else
    begin
      Fields(string(R.Arguments[3]), 2, Config);
      Counter := TSleCounterCardReaderWriter.Create(nil); Counter.Model := TSleCounterModel(Model);
      Counter.ReadableBytes := Number(Config[0], 1, 256); Prefix := Number(Config[1], 0, 256);
      C := TSleCounterWorkflowCard.Create(Counter); F := TSleCounterWorkflow.Create(nil);
    end;
    if R.FamilyAction = 3 then
    begin
      Snapshot := TSleWorkflowArchive.DecodeSnapshot(string(R.Arguments[2]));
      Action := swaProgram; if Counter <> nil then Action := swaCounterByte;
      Steps := TSleWorkflowPlanner.ProgramPlan(Snapshot, HexToBytes(string(R.Arguments[0])), C, Action);
      D.Success := True; D.Text := UnicodeString('Differing bytes: ' +
        IntToStr(Length(TSleWorkflowPlanner.Compare(Snapshot, HexToBytes(string(R.Arguments[0]))))) + #13#10);
      if Length(Steps) = 0 then begin D.Text := D.Text + 'No programming required.'; Exit; end;
      Text := TSleWorkflowArchive.EncodePlan(Steps);
      SetLength(D.Artifacts, 1); D.Artifacts[0].Name := 'sle.erdplan';
      D.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(Text)); Exit;
    end;
    if R.FamilyAction = 0 then F.PrepareBackup(C)
    else F.Prepare(C, Steps, R.FamilyAction = 1, Prefix);
    // Rebuild the frozen backend with the validated native connection configuration.
    C := nil;
    if Reader <> nil then
    begin Reader.Transport := Readers.CreateTransport(R.ReaderName);
      C := TSle4404WorkflowCard.Create(Reader, Base, Count, UserCode, MemoryCode); end
    else
    begin Counter.Transport := Readers.CreateTransport(R.ReaderName); C := TSleCounterWorkflowCard.Create(Counter); end;
    if R.FamilyAction = 0 then F.PrepareBackup(C) else F.Prepare(C, Steps, R.FamilyAction = 1, Prefix);
    F.OnProgress := Progress; F.Execute; Finish(F, D, Log);
    if D.Success and (R.FamilyAction = 0) then
    begin
      Text := TSleWorkflowArchive.EncodeSnapshot(F.Snapshot);
      SetLength(D.Artifacts, 1); D.Artifacts[0].Name := 'sle.erdsnapshot';
      D.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(Text));
      D.Text := D.Text + UnicodeString(Text);
    end;
  finally F.Free; C := nil; Reader.Free; Counter.Free; Config.Free;
    TCardCrypto.Clear(UserCode); TCardCrypto.Clear(MemoryCode); end;
end;
procedure TOperations.Desfire(const R: TCardDemoRequest; var D: TCardDemoResult);
var Config, Lines, Values, Definitions, Def: TStringList; Steps: TDesfirePersonalizationSteps;
  Security, Limit, Frame, Minimum, Prefix, K: Integer;
  Identity: TBytes; Reader: TDesfireCardReader; Transport: ICardTransport;
  F: TDesfirePersonalizationWorkflow; C: IDesfireWorkflowCard; Content: TDesfireWorkflowSnapshot; Stream: TFileStream; Data: TBytes;
  function N(const Index, Min, Max: Integer): Integer;
  begin Result := Number(Values[Index], Min, Max); end;
  function Key(const Index: Integer): TBytes;
  begin
    Result := nil; if Index = -1 then Exit;
    if (Index < 0) or (Index >= Length(R.Credentials)) then Invalid;
    Result := CopyBytes(R.Credentials[Index]);
  end;
  function Card(const AuthNumber, SecretIndex: Integer): IDesfireWorkflowCard;
  var Secret: TBytes; Width: Integer;
  begin
    Reader := TDesfireCardReader.Create(nil); Secret := nil;
    try
      Reader.Security := TDesfireSecurity(Security); Reader.KeyNumber := AuthNumber;
      Secret := Key(SecretIndex); Width := 16;
      case Security of 0: Width := 0; 4: Width := 24; 5: Width := 8; end;
      if Length(Secret) <> Width then Invalid;
      Reader.AuthenticationKey := Secret;
      Reader.MinimumCommunication := TDesfireCommunication(Minimum);
      Reader.MaxTransferBytes := Limit; Reader.MaxFrameDataBytes := Frame;
{$IFDEF MSWINDOWS}
      Reader.CryptoProvider := TCardWindowsAesProvider.Create;
{$ELSE}
      Reader.CryptoProvider := TCardOpenSslAesProvider.Create;
{$ENDIF}
      Reader.Transport := Transport; Result := TDesfireWorkflowCard.Create(Reader);
    finally TCardCrypto.Clear(Secret); Reader.Free; Reader := nil; end;
  end;
  function Proof(const AuthNumber, SecretIndex: Integer): IDesfirePersonalizationKeyProof;
  var Secret: TBytes; Width: Integer;
  begin
    Reader := TDesfireCardReader.Create(nil); Secret := nil;
    try
      Reader.Security := TDesfireSecurity(Security); Reader.KeyNumber := AuthNumber;
      Secret := Key(SecretIndex); Width := 16;
      case Security of 0: Width := 0; 4: Width := 24; 5: Width := 8; end;
      if Length(Secret) <> Width then Invalid;
      Reader.AuthenticationKey := Secret;
{$IFDEF MSWINDOWS}
      Reader.CryptoProvider := TCardWindowsAesProvider.Create;
{$ELSE}
      Reader.CryptoProvider := TCardOpenSslAesProvider.Create;
{$ENDIF}
      Reader.Transport := Transport; Result := CreateDesfirePersonalizationKeyProof(Reader);
    finally TCardCrypto.Clear(Secret); Reader.Free; Reader := nil; end;
  end;
  procedure Parse;
  var I, J, KeyIndex: Integer;
  begin
    for I := 0 to High(Steps) do
    begin
      Values.StrictDelimiter := True; Values.Delimiter := '|'; Values.DelimitedText := Lines[I + 1];
      if Values.Count < 5 then Invalid;
      Steps[I].VerificationCard := nil;
      if (Values.Count >= 8) and (Values[Values.Count - 3] = 'V') then
      begin
        Steps[I].VerificationCard := Card(Number(Values[Values.Count - 2], 0, 13),
          Number(Values[Values.Count - 1], -1, 255));
        Values.Delete(Values.Count - 1); Values.Delete(Values.Count - 1); Values.Delete(Values.Count - 1);
      end;
      Steps[I].Aid := N(0, 1, $FFFFFF); Steps[I].Action := TDesfirePersonalizationAction(N(1, 0, 5));
      Steps[I].Card := Card(N(2, 0, 13), N(3, -1, 255));
      case Steps[I].Action of
        dpaProvision:
          begin
            if Values.Count <> 10 then Invalid;
            Steps[I].KeySettings := N(4, 0, 255); Steps[I].KeyCount := N(5, 1, 14);
            Steps[I].KeyType := TDesfireApplicationKeyType(N(6, 0, 2));
            Steps[I].ApplicationCard := Card(N(7, 0, 13), N(8, -1, 255));
            Definitions.StrictDelimiter := True; Definitions.Delimiter := ';'; Definitions.DelimitedText := Values[9];
            if Values[9] = '-' then Definitions.Clear;
            if Definitions.Count > 32 then Invalid;
            SetLength(Steps[I].Definitions, Definitions.Count);
            for J := 0 to Definitions.Count - 1 do
            begin
              Def.StrictDelimiter := True; Def.Delimiter := ','; Def.DelimitedText := Definitions[J];
              if Def.Count <> 14 then Invalid;
              with Steps[I].Definitions[J] do
              begin
                FileNumber := Number(Def[0], 0, 31); FileType := TDesfireFileType(Number(Def[1], 0, 4));
                Communication := TDesfireCommunication(Number(Def[2], 0, 2));
                ReadKey := Number(Def[3], 0, 15); WriteKey := Number(Def[4], 0, 15);
                ReadWriteKey := Number(Def[5], 0, 15); ChangeKey := Number(Def[6], 0, 15);
                FileBytes := Number(Def[7], 0, $FFFFFF); LowerLimit := Number(Def[8], Low(Integer), High(Integer));
                UpperLimit := Number(Def[9], Low(Integer), High(Integer)); InitialValue := Number(Def[10], Low(Integer), High(Integer));
                LimitedCreditEnabled := Number(Def[11], 0, 1) = 1;
                RecordBytes := Number(Def[12], 0, $FFFFFF); MaxRecords := Number(Def[13], 0, $FFFFFF);
              end;
            end;
          end;
        dpaContent:
          begin
            if Values.Count <> 5 then Invalid;
            Steps[I].Content := Content; Steps[I].Access := dsaFreshTransaction;
            if N(4, 0, 1) = 1 then Steps[I].Access := dsaDiscardPending;
          end;
        dpaAesKey, dpaDesKey:
          begin
            if Values.Count <> 9 then Invalid;
            Steps[I].KeyNumber := N(4, 0, 13); Steps[I].NewVersion := N(5, 0, 255); Steps[I].OldVersion := N(6, 0, 255);
            KeyIndex := N(7, 0, 255); Steps[I].NewKey := Key(KeyIndex); Steps[I].OldKey := Key(N(8, -1, 255));
            Steps[I].KeyProof := Proof(Steps[I].KeyNumber, KeyIndex);
          end;
        dpaFileAccess:
          begin
            if Values.Count <> 10 then Invalid;
            Steps[I].FileNumber := N(4, 0, 31); Steps[I].Communication := TDesfireCommunication(N(5, 0, 2));
            Steps[I].ReadKey := N(6, 0, 15); Steps[I].WriteKey := N(7, 0, 15);
            Steps[I].ReadWriteKey := N(8, 0, 15); Steps[I].ChangeKey := N(9, 0, 15);
          end;
        dpaKeyPolicy:
          begin if Values.Count <> 5 then Invalid; Steps[I].KeySettings := N(4, 0, 255); end;
      end;
    end;
  end;
begin
  Config := TStringList.Create; Lines := TStringList.Create; Values := TStringList.Create;
  Definitions := TStringList.Create; Def := TStringList.Create; F := nil; Reader := nil;
  Steps := nil;
  try
    Security := Number(string(R.Arguments[1]), 0, 6); Fields(string(R.Arguments[3]), 5, Config);
    Identity := HexToBytes(Config[0]); Prefix := Number(Config[1], 0, 256);
    Limit := Number(Config[2], 1, DesfireMaxTransferBytes); Frame := Number(Config[3], 1, 248);
    Minimum := Number(Config[4], 0, 2);
    if R.FamilyAction = 2 then
    begin
      Transport := Readers.CreateTransport(R.ReaderName);
      Reader := TDesfireCardReader.Create(nil); Reader.Transport := Transport;
      C := TDesfireWorkflowCard.Create(Reader);
      D.Text := UnicodeString('Native manufacturing UID: ' + BytesToHex(C.ReadIdentity));
      D.Success := True; Exit;
    end;
    if Length(Identity) <> 7 then Invalid;
    Content := Default(TDesfireWorkflowSnapshot);
    if Trim(string(R.Arguments[0])) <> '' then
    begin
      Stream := TFileStream.Create(string(R.Arguments[0]), fmOpenRead or fmShareDenyWrite);
      try
        if Stream.Size > 3 * 1024 * 1024 then Invalid;
        SetLength(Data, Integer(Stream.Size)); if Length(Data) > 0 then Stream.ReadBuffer(Data[0], Length(Data));
        if (Length(Data) >= 3) and (Data[0] = $EF) and (Data[1] = $BB) and (Data[2] = $BF) then
          Data := Copy(Data, 3, Length(Data) - 3);
        Content := TDesfireWorkflowArchive.Decode(string(TEncoding.UTF8.GetString(Data)));
      finally Stream.Free; end;
    end;
    Lines.Text := string(R.Arguments[2]);
    if (Lines.Count < 2) or (Lines.Count > 257) or (Lines[0] <> 'ERD-DESFIRE-PERSONALIZE 1') then Invalid;
    SetLength(Steps, Lines.Count - 1);
    Parse; F := TDesfirePersonalizationWorkflow.Create(nil);
    if R.FamilyAction = 1 then Prefix := Length(Steps);
    F.Prepare(Steps, Identity, Prefix);
    // All inputs and profile structure have now been checked without connection creation.
    Transport := Readers.CreateTransport(R.ReaderName);
    for K := 0 to High(Steps) do
    begin Steps[K].Card := nil; Steps[K].ApplicationCard := nil; Steps[K].KeyProof := nil; Steps[K].VerificationCard := nil;
      TCardCrypto.Clear(Steps[K].NewKey); TCardCrypto.Clear(Steps[K].OldKey); end;
    Parse; F.Prepare(Steps, Identity, Prefix); F.OnProgress := Progress;
    F.Execute; Finish(F, D, Log);
  finally
    for K := 0 to High(Steps) do
    begin TCardCrypto.Clear(Steps[K].NewKey); TCardCrypto.Clear(Steps[K].OldKey); end;
    F.Free; Reader.Free; Config.Free; Lines.Free; Values.Free; Definitions.Free; Def.Free;
  end;
end;
procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var Error: UnicodeString;
begin
  AResult := Default(TCardDemoResult); AResult.Operation := ARequest.Operation;
  Log := '';
  try
    if not TryValidateRequest(ARequest, Error) then Invalid;
    if ARequest.FamilyName = 'DesfirePersonalizationDemo' then Desfire(ARequest, AResult)
    else Sle(ARequest, AResult);
  except on E: Exception do
    begin AResult.Success := False; AResult.ErrorClass := E.ClassName;
      AResult.Text := UnicodeString(Log + 'Preparation/input failure: ' + E.ClassName + #13#10); end;
  end;
end;
function CreateCardPersonalizationDemoOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var O: TOperations;
begin
  O := TOperations.Create; Result := O; O.Readers := AReaders;
  if O.Readers = nil then O.Readers := CreateNativeCardWorkflowDemoReaders;
end;

end.
