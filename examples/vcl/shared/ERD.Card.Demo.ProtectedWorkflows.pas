unit ERD.Card.Demo.ProtectedWorkflows;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Workflows;

/// <summary>Creates nonvisual protected-memory and reviewed-security workers for independent DFM demos.</summary>
/// <param name="AReaders">Optional inactive injected transport factory; nil uses native PC/SC.</param>
/// <returns>Executor and hardware-free input validator.</returns>
function CreateProtectedWorkflowOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

implementation

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Workflow, ERD.Card.Workflow.Archive,
  ERD.Card.Contactless.ACR122, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Workflow, ERD.Card.Contactless.ISO15693,
  ERD.Card.Contactless.Type2.Password,
  ERD.Card.Contactless.Workflow.Password, ERD.Card.Contactless.Workflow.Security;

type
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
  private
    Readers: ICardWorkflowDemoReaders;
    Log: UnicodeString;
    function Configuration(const R: TCardDemoRequest): TStringList;
    function Memory(const R: TCardDemoRequest): TProtectedMemoryWorkflow;
    function Security(const R: TCardDemoRequest): TCardSecurityWorkflow;
    procedure CaptureConfiguration(const R: TCardDemoRequest; const ACapture: Boolean; var AResult: TCardDemoResult);
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
  public
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

function Number(const L: TStringList; const Key: string; const Default: Integer): Integer;
begin
  Result := Default;
  if L.IndexOfName(Key) >= 0 then
    if not TryStrToInt(L.Values[Key], Result) then raise ECardWorkflowError.Create('Invalid numeric protected-workflow option.');
end;

function Flag(const L: TStringList; const Key: string; const Default: Integer): Boolean;
var
  N: Integer;
begin
  N := Number(L, Key, Default);
  if not (N in [0, 1]) then raise ECardWorkflowError.Create('Boolean options require zero or one.');
  Result := N = 1;
end;

function ByteNumber(const L: TStringList; const Key: string; const Default: Integer): Byte;
var
  N: Integer;
begin
  N := Number(L, Key, Default);
  if (N < 0) or (N > 255) then raise ECardWorkflowError.Create('Option outside byte range.');
  Result := Byte(N);
end;

function PlanText(const P: TCardSecurityPlan): UnicodeString;
begin
  Result := UnicodeString(P.Family + #13#10 + P.Operation + #13#10 +
    'Target UID: ' + BytesToHex(P.Uid) + #13#10 + 'Identifier/area: ' + IntToStr(P.Identifier) + #13#10 +
    'Before: ' + BytesToHex(P.Before) + #13#10 + 'After: ' + BytesToHex(P.After) + #13#10 +
    'Credentials are excluded from the review plan.' + #13#10);
end;

function TOperations.Configuration(const R: TCardDemoRequest): TStringList;
var
  I, J: Integer;
  Key: string;
  Known: Boolean;
begin
  if (R.Operation <> cdoFamily) or (Length(R.Arguments) <> 4) or (Length(R.Credentials) <> 3) or
    not (R.FamilyAction in [0 .. 8]) or (Length(R.Arguments[2]) > 3 * 1024 * 1024) or
    (Length(R.Arguments[3]) > 65536) or
    not ((R.FamilyName = 'ProtectedType2WorkflowDemo') or (R.FamilyName = 'ProtectedIso15693WorkflowDemo')) then
    raise ECardWorkflowError.Create('Invalid protected workflow request.');
  if (R.FamilyAction in [0 .. 2]) and (R.ReaderName = '') then raise ECardWorkflowError.Create('Choose a source reader.');
  if (R.FamilyAction <> 0) and (R.Arguments[0] = '') then raise ECardWorkflowError.Create('Choose a target reader.');
  if (R.FamilyAction in [1, 2]) and (R.ReaderName = R.Arguments[0]) then raise ECardWorkflowError.Create('Copy/compare requires two selected readers.');
  if (R.FamilyAction in [1, 3, 5, 7]) and not R.MutationAcknowledged then raise ECardWorkflowError.Create('Acknowledge the intended target mutation.');
  Result := TStringList.Create;
  try
    Result.Text := string(R.Arguments[3]);
    for I := 0 to Result.Count - 1 do
    begin
      if Trim(Result[I]) = '' then Continue;
      Key := Result.Names[I];
      if Key = '' then raise ECardWorkflowError.Create('Options require key=value lines.');
      for J := 0 to I - 1 do if SameText(Key, Result.Names[J]) then raise ECardWorkflowError.Create('Duplicate protected-workflow option.');
      Known := (Key = 'first') or (Key = 'count') or (Key = 'uid') or (Key = 'before');
      if R.FamilyName = 'ProtectedType2WorkflowDemo' then
        Known := Known or (Key = 'auth0') or (Key = 'protectReads') or (Key = 'authlim')
      else Known := Known or (Key = 'blocks') or (Key = 'blockBytes') or (Key = 'addressing') or
        (Key = 'responseFormat') or (Key = 'sourceId') or (Key = 'targetId') or (Key = 'pointer') or
        (Key = 'conditions') or (Key = 'area') or (Key = 'passwordNumber') or (Key = 'protectionCode') or (Key = 'powerStable');
      if not Known then raise ECardWorkflowError.Create('Unknown protected-workflow option.');
    end;
  except Result.Free; Result := nil; raise; end;
end;

function Passwords(const Value: TBytes; const Profile, Identifier: Integer): TIso15693Passwords;
begin
  Result := nil;
  if Profile = 0 then
  begin
    if Length(Value) = 8 then
    begin
      SetLength(Result, 2); Result[0].Identifier := 1; Result[0].Value := Copy(Value, 0, 4);
      Result[1].Identifier := 2; Result[1].Value := Copy(Value, 4, 4); Exit;
    end;
    if (Length(Value) <> 4) or not (Identifier in [1, 2]) then raise ECardWorkflowError.Create('SLIX2 needs four bytes with ID 1/2 or read+write eight bytes.');
  end
  else if (Length(Value) <> 8) or not (Identifier in [1 .. 3]) then
    raise ECardWorkflowError.Create('ST25DV memory needs eight bytes with user password ID 1..3.');
  SetLength(Result, 1); Result[0].Identifier := Byte(Identifier); Result[0].Value := CopyBytes(Value);
end;

procedure ClearPasswords(var P: TIso15693Passwords);
var
  I: Integer;
begin for I := 0 to High(P) do TCardCrypto.Clear(P[I].Value); P := nil; end;

function TOperations.Memory(const R: TCardDemoRequest): TProtectedMemoryWorkflow;
var
  C: TStringList;
  Source, Target: ICardWorkflowMemory;
  A: TCardWorkflowAddresses;
  Profile, First, Count, I, Blocks, Size, Addressing, FormatCode: Integer;
  function Backend(const Name: UnicodeString; const Credential: TBytes; const Identifier: Integer): ICardWorkflowMemory;
  var Raw: IRawContactlessReader; S: IIso15693Session; P: TIso15693Passwords; Password, Pack: TBytes;
  begin
    if R.FamilyName = 'ProtectedType2WorkflowDemo' then
    begin
      if Length(Credential) <> 6 then raise ECardWorkflowError.Create('Type 2 requires four password bytes followed by two expected PACK bytes.');
      Raw := TAcr122RawReader.Create(Readers.CreateTransport(Name));
      Password := Copy(Credential, 0, 4); Pack := Copy(Credential, 4, 2);
      try Result := CreateType2PasswordWorkflowMemory(Raw, TType2TagModel(Profile), Password, Pack);
      finally TCardCrypto.Clear(Password); TCardCrypto.Clear(Pack); end;
    end
    else
    begin
      S := TAcr1552Iso15693Session.Create(Readers.CreateTransport(Name), TIso15693AddressMode(Addressing), TIso15693ResponseFormat(FormatCode));
      P := Passwords(Credential, Profile, Identifier);
      try Result := CreateIso15693PasswordWorkflowMemory(S, TIso15693PasswordProfile(Profile), P, Blocks, Size);
      finally ClearPasswords(P); end;
    end;
  end;
begin
  Result := nil; C := Configuration(R);
  try
    try
      if not TryStrToInt(string(R.Arguments[1]), Profile) then raise ECardWorkflowError.Create('Choose an explicit password profile.');
      Blocks := Number(C, 'blocks', 80); Size := Number(C, 'blockBytes', 4);
      Addressing := Number(C, 'addressing', 0); FormatCode := Number(C, 'responseFormat', 0);
      First := Number(C, 'first', 4); Count := Number(C, 'count', 1);
      if R.FamilyName = 'ProtectedType2WorkflowDemo' then
      begin
        if not (Profile in [1 .. 7]) then raise ECardWorkflowError.Create('Original Ultralight has no PWD_AUTH profile.');
        if (First < 4) or (Count < 1) or (Count > 4096) or (First > TType2Layout.LastUserPage(TType2TagModel(Profile)) - Count + 1) then
          raise ECardWorkflowError.Create('Select only complete Type 2 user pages.');
      end
      else
      begin
        if not (Profile in [0, 1]) or not (Addressing in [0, 1]) or not (FormatCode in [0, 1]) or
          (Blocks < 1) or (Blocks > 65536) or (Size < 1) or (Size > 32) or
          ((Addressing = 0) and (Blocks > 256)) or
          (First < 0) or (Count < 1) or (Count > 4096) or (First > Blocks - Count) then
          raise ECardWorkflowError.Create('Invalid protected ISO profile, geometry or selection.');
      end;
      A := nil; SetLength(A, Count); for I := 0 to Count - 1 do A[I] := First + I;
      Source := nil; Target := nil;
      if R.FamilyAction in [0 .. 2] then Source := Backend(R.ReaderName, R.Credentials[0], Number(C, 'sourceId', 1));
      if R.FamilyAction <> 0 then Target := Backend(R.Arguments[0], R.Credentials[1], Number(C, 'targetId', 2));
      Result := TProtectedMemoryWorkflow.Create(nil);
      case R.FamilyAction of
        0: Result.PrepareProtectedBackup(Source, A);
        1, 2: Result.PrepareProtectedCopy(Source, Target, A, R.FamilyAction = 2);
        3: Result.PrepareProtectedRestore(TCardWorkflowArchive.Decode(string(R.Arguments[2])), Target);
      else raise ECardWorkflowError.Create('Select a memory action.'); end;
      Result.CheckPrepared;
    except Result.Free; Result := nil; raise; end;
  finally C.Free; end;
end;

function TOperations.Security(const R: TCardDemoRequest): TCardSecurityWorkflow;
var
  C: TStringList;
  Op: ICardSecurityOperation;
  Raw: IRawContactlessReader;
  S: IIso15693Session;
  Profile, Addressing, FormatCode, Blocks, Size: Integer; Uid, Before, P, K, NewP, NewK: TBytes;
begin
  Result := nil; C := Configuration(R); P := nil; K := nil; NewP := nil; NewK := nil;
  try
    try
      if not TryStrToInt(string(R.Arguments[1]), Profile) then raise ECardWorkflowError.Create('Choose an explicit password profile.');
      Uid := HexToBytes(C.Values['uid']); Before := HexToBytes(C.Values['before']);
      if R.FamilyName = 'ProtectedType2WorkflowDemo' then
      begin
        if not (Profile in [1 .. 7]) or (Length(R.Credentials[1]) <> 6) then raise ECardWorkflowError.Create('Type 2 current password+PACK requires six bytes.');
        P := Copy(R.Credentials[1], 0, 4); K := Copy(R.Credentials[1], 4, 2);
        Raw := TAcr122RawReader.Create(Readers.CreateTransport(R.Arguments[0]));
        if R.FamilyAction in [4, 5] then
        begin
          if Length(R.Credentials[2]) <> 6 then raise ECardWorkflowError.Create('Replacement password+PACK requires six bytes.');
          NewP := Copy(R.Credentials[2], 0, 4); NewK := Copy(R.Credentials[2], 4, 2);
          Op := CreateType2CredentialOperation(Raw, TType2TagModel(Profile), Uid, P, K, NewP, NewK);
        end
        else Op := CreateType2ProtectionOperation(Raw, TType2TagModel(Profile), Uid, Before, P, K,
          ByteNumber(C, 'auth0', 255), Flag(C, 'protectReads', 0), ByteNumber(C, 'authlim', 0));
      end
      else
      begin
        Addressing := Number(C, 'addressing', 0); FormatCode := Number(C, 'responseFormat', 0);
        Blocks := Number(C, 'blocks', 80); Size := Number(C, 'blockBytes', 4);
        if not (Profile in [0, 1]) or not (Addressing in [0, 1]) or not (FormatCode in [0, 1]) or
          ((Addressing = 0) and (Blocks > 256)) then raise ECardWorkflowError.Create('Invalid explicit ISO profile.');
        S := TAcr1552Iso15693Session.Create(Readers.CreateTransport(R.Arguments[0]), TIso15693AddressMode(Addressing), TIso15693ResponseFormat(FormatCode));
        if R.FamilyAction in [4, 5] then
          Op := CreateIso15693CredentialOperation(S, TIso15693PasswordProfile(Profile), Uid, Blocks, Size,
            ByteNumber(C, 'targetId', 2), R.Credentials[1], R.Credentials[2], Flag(C, 'powerStable', 0))
        else if Profile = 0 then
        begin
          if (Length(R.Credentials[1]) <> 8) or (Blocks <> 80) or (Size <> 4) then raise ECardWorkflowError.Create('SLIX2 policy needs 80x4 geometry and read+write passwords.');
          P := Copy(R.Credentials[1], 0, 4); K := Copy(R.Credentials[1], 4, 4);
          Op := CreateSlix2ProtectionOperation(S, Uid, P, K, Before, ByteNumber(C, 'pointer', 0), ByteNumber(C, 'conditions', 0));
        end
        else
        begin
          if Size <> 4 then raise ECardWorkflowError.Create('ST25DV uses four-byte blocks.');
          Op := CreateSt25ProtectionOperation(S, Uid, Blocks, R.Credentials[1], Before,
            ByteNumber(C, 'area', 1), ByteNumber(C, 'passwordNumber', 0), ByteNumber(C, 'protectionCode', 0), Flag(C, 'powerStable', 0));
        end;
      end;
      Result := TCardSecurityWorkflow.Create(nil); Result.Prepare(Op); Result.CheckPrepared;
    except Result.Free; Result := nil; raise; end;
  finally TCardCrypto.Clear(P); TCardCrypto.Clear(K); TCardCrypto.Clear(NewP); TCardCrypto.Clear(NewK); C.Free; end;
end;

procedure TOperations.CaptureConfiguration(const R: TCardDemoRequest;
  const ACapture: Boolean; var AResult: TCardDemoResult);
var
  C: TStringList;
  Raw: IRawContactlessReader;
  Session: IIso15693Session;
  Type2: TType2PasswordCardReader;
  Iso: TIso15693SecurityManager;
  Profile, Blocks, Size, Addressing, FormatCode, Area: Integer;
  Uid, P, K, Before: TBytes;
  Info: TIso15693SystemInfo;
  Config: TType2AuthenticationConfiguration;
  Slix: TSlix2Protection;
  St: TSt25RfConfiguration;
  Success: Boolean;
begin
  C := Configuration(R);
  Type2 := nil;
  Iso := nil;
  P := nil;
  K := nil;
  try
    if not TryStrToInt(string(R.Arguments[1]), Profile) then
      raise ECardWorkflowError.Create('Choose an explicit configuration profile.');
    Uid := HexToBytes(C.Values['uid']);
    if R.FamilyName = 'ProtectedType2WorkflowDemo' then
    begin
      if not (Profile in [1 .. 7]) or (Length(R.Credentials[1]) <> 6) then
        raise ECardWorkflowError.Create('Type 2 configuration needs current password and PACK.');
      P := Copy(R.Credentials[1], 0, 4);
      K := Copy(R.Credentials[1], 4, 2);
      TType2PasswordCodec.ValidateCredentials(TType2TagModel(Profile), P, K);
      Raw := TAcr122RawReader.Create(Readers.CreateTransport(R.Arguments[0]));
      Raw := CreateType2WorkflowIdentityGuard(Raw, Uid);
      Type2 := TType2PasswordCardReader.Create(nil);
      Type2.Reader := Raw;
      if not ACapture then Exit;
      Raw.BeginSession;
      Success := False;
      try
        Uid := Raw.Activate;
        Success := True;
      finally
        if Success then Raw.EndSession else try Raw.EndSession; except end;
      end;
      Config := Type2.ReadConfiguration(TType2TagModel(Profile), P, K);
      Before := Config.RawPages;
      C.Values['auth0'] := IntToStr(Config.FirstProtectedPage);
      C.Values['protectReads'] := IntToStr(Ord(Config.ProtectReads));
      C.Values['authlim'] := IntToStr(Config.AuthenticationLimit);
    end
    else
    begin
      Blocks := Number(C, 'blocks', 80);
      Size := Number(C, 'blockBytes', 4);
      Addressing := Number(C, 'addressing', 0);
      FormatCode := Number(C, 'responseFormat', 0);
      Area := Number(C, 'area', 1);
      if (Area < 1) or (Area > 4) then raise ECardWorkflowError.Create('Area must be one through four.');
      if not (Profile in [0, 1]) or (Size <> 4) or
        ((Profile = 0) and (Blocks <> 80)) or
        ((Profile = 1) and (Blocks <> 128) and (Blocks <> 512) and (Blocks <> 2048)) or
        not (Addressing in [0, 1]) or not (FormatCode in [0, 1]) or
        ((Addressing = 0) and (Blocks > 256)) then
        raise ECardWorkflowError.Create('Explicit supported configuration profile/geometry required.');
      Session := TAcr1552Iso15693Session.Create(Readers.CreateTransport(R.Arguments[0]),
        TIso15693AddressMode(Addressing), TIso15693ResponseFormat(FormatCode));
      Session := CreateIso15693WorkflowIdentityGuard(Session, Blocks, Size, Uid);
      Iso := TIso15693SecurityManager.Create(nil);
      Iso.Session := Session;
      if not ACapture then Exit;
      Info := Session.BeginSession;
      Success := False;
      try
        TIso15693Codec.ValidatePasswordProfile(Info, TIso15693PasswordProfile(Profile));
        Uid := CopyBytes(Info.Uid);
        Success := True;
      finally
        if Success then Session.EndSession else try Session.EndSession; except end;
      end;
      if Profile = 0 then
      begin
        Slix := Iso.ReadSlix2Protection;
        Before := Slix.Raw;
        C.Values['pointer'] := IntToStr(Slix.PointerBlock);
        C.Values['conditions'] := IntToStr(Slix.Conditions);
      end
      else
      begin
        St := Iso.ReadSt25Configuration;
        Before := St.Raw;
        C.Values['passwordNumber'] := IntToStr(St.Areas[Area - 1].PasswordNumber);
        C.Values['protectionCode'] := IntToStr(St.Areas[Area - 1].ProtectionCode);
      end;
    end;
    C.Values['uid'] := BytesToHex(Uid);
    C.Values['before'] := BytesToHex(Before);
    AResult.Text := 'Current configuration acquired; edit desired options, then preview the policy.' + #13#10 + UnicodeString(C.Text);
    SetLength(AResult.Artifacts, 1);
    AResult.Artifacts[0].Name := 'protected-options.txt';
    AResult.Artifacts[0].Data := TEncoding.UTF8.GetBytes(UnicodeString(C.Text));
    AResult.Success := True;
  finally
    Type2.Free;
    Iso.Free;
    TCardCrypto.Clear(P);
    TCardCrypto.Clear(K);
    C.Free;
  end;
end;

function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
var
  W: TCardWorkflow;
  Preview: TCardDemoResult;
begin
  W := nil; AError := ''; Result := False;
  try
    try
      if ARequest.FamilyAction = 8 then
      begin
        Preview := Default(TCardDemoResult);
        CaptureConfiguration(ARequest, False, Preview);
      end
      else if ARequest.FamilyAction in [0 .. 3] then W := Memory(ARequest) else W := Security(ARequest);
      Result := True;
    except on E: Exception do AError := UnicodeString(E.ClassName + ': check explicit profile, credentials, reader and preimage inputs.'); end;
  finally W.Free; end;
end;

procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin
  Log := Log + UnicodeString(CardWorkflowStateName(AState) + ' ' + IntToStr(ADone) + '/' + IntToStr(ATotal)) + #13#10;
end;

procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var
  M: TProtectedMemoryWorkflow;
  W: TCardSecurityWorkflow;
  Units: TCardWorkflowUnits;
  I: Integer;
  Text: UnicodeString;
begin
  Log := '';
  if ARequest.FamilyAction = 8 then
  begin
    CaptureConfiguration(ARequest, True, AResult);
    Exit;
  end;
  if ARequest.FamilyAction in [0 .. 3] then
  begin
    M := Memory(ARequest);
    try
      M.OnProgress := Progress; AResult.Success := M.Execute = cwsCompleted; AResult.ErrorClass := M.ErrorClass;
      AResult.Text := Log + UnicodeString('Outcome: ' + CardWorkflowStateName(M.State)) + #13#10;
      Units := M.Results; for I := 0 to High(Units) do
        AResult.Text := AResult.Text + UnicodeString(IntToStr(Units[I].Address) + ': ' + CardWorkflowUnitStateName(Units[I].State)) + #13#10;
      if AResult.Success then
      begin
        SetLength(AResult.Artifacts, 1); AResult.Artifacts[0].Name := 'protected-memory.erdsnapshot';
        Text := UnicodeString(TCardWorkflowArchive.Encode(M.Snapshot)); AResult.Artifacts[0].Data := TEncoding.UTF8.GetBytes(Text);
      end;
    finally M.Free; end;
  end
  else
  begin
    W := Security(ARequest);
    try
      Text := PlanText(W.Plan);
      if ARequest.FamilyAction in [4, 6] then
      begin AResult.Success := True; AResult.Text := 'Review only: no reader/card I/O.' + #13#10 + Text; end
      else
      begin
        W.OnProgress := Progress; AResult.Success := W.Execute = cwsCompleted; AResult.ErrorClass := W.ErrorClass;
        AResult.Text := Log + Text + UnicodeString('Outcome: ' + CardWorkflowStateName(W.State) +
          ', evidence: ' + CardWorkflowUnitStateName(W.ResultState));
      end;
    finally W.Free; end;
  end;
end;

function CreateProtectedWorkflowOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var
  O: TOperations;
begin
  O := TOperations.Create; Result := O; O.Readers := AReaders;
  if O.Readers = nil then O.Readers := CreateNativeCardWorkflowDemoReaders;
end;

end.
