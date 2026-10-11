program ProtectedWorkflowTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Workflow, ERD.Card.Workflow.Archive,
  ERD.Card.Contactless, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Type2.Password, ERD.Card.Contactless.ISO15693,
  ERD.Card.Demo.Job, ERD.Card.Demo.Workflows, ERD.Card.Demo.ProtectedWorkflows,
  ERD.Card.Contactless.Workflow.Password, ERD.Card.Contactless.Workflow.Security;
type
  TRawTag = class(TInterfacedObject, IRawContactlessReader)
    Pages: array[0..255] of TBytes;
    Uid, Password, Pack: TBytes;
    Active, Authenticated, FailWrite, FailEnd, SuppressWrite: Boolean;
    Begins, Ends, Activations, Auths, Writes, SwapAt: Integer;
    Config: Integer;
    constructor Create(const AModel: TType2TagModel);
    procedure BeginSession;
    procedure EndSession;
    function Activate: TBytes;
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
  end;
  TIsoTag = class(TInterfacedObject, IIso15693Session, IIso15693CustomCommands, IIso15693FieldReset)
    Info: TIso15693SystemInfo;
    Data: array of TBytes;
    Passwords: array[0..3] of TBytes;
    Authenticated: array[0..3] of Boolean;
    Protection, Registers: TBytes;
    Active, Locked, FailWrite, FailEnd, SuppressWrite: Boolean;
    Begins, Ends, Auths, Writes, Resets, SwapAt: Integer;
    Profile: TIso15693PasswordProfile;
    constructor Create(const AProfile: TIso15693PasswordProfile);
    function BeginSession: TIso15693SystemInfo;
    procedure EndSession;
    function ReadBlock(const ABlock: Integer): TBytes;
    function SecurityStatus(const ABlock: Integer): Byte;
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
    function ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
    function ResetField: TIso15693SystemInfo;
  end;
  TNoIoTransport = class(TInterfacedObject, ICardTransport, ICardTransaction)
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
    Created: Integer;
    Transport: ICardTransport;
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;
  TConfigurationWire = class(TInterfacedObject, ICardTransport, ICardTransaction)
    Kind, Begins, Ends, Auths, Selections, SwapAt: Integer;
    Active: Boolean;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
  end;
  TCancel = class
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
  end;
var Checks: Integer;
function TNoIoTransport.Exchange(const ACommand: TBytes): TBytes;
begin Result := nil; raise Exception.Create('Preview attempted I/O'); end;
procedure TNoIoTransport.BeginTransaction;
begin raise Exception.Create('Preview acquired hardware'); end;
procedure TNoIoTransport.EndTransaction;
begin raise Exception.Create('Preview released hardware'); end;
function TReaders.CreateTransport(const AName: UnicodeString): ICardTransport;
begin Inc(Created); if Transport = nil then Result := TNoIoTransport.Create else Result := Transport; end;
procedure Check(const B: Boolean; const M: string);
begin
  Inc(Checks);
  if not B then raise Exception.Create(M);
end;
constructor TRawTag.Create(const AModel: TType2TagModel);
var I: Integer;
begin
  inherited Create;
  Uid := HexToBytes('04112233445566');
  Password := HexToBytes('01020304'); Pack := HexToBytes('A1B2');
  for I := 0 to 255 do Pages[I] := HexToBytes('00000000');
  Config := TType2Layout.LastUserPage(AModel) + 2;
  if AModel in [ttmUltralightEv1_48, ttmNtag210] then Dec(Config);
  Pages[Config][3] := $FF;
  Pages[4] := HexToBytes('11223344');
end;
procedure TRawTag.BeginSession;
begin
  Check(not Active, 'No nested raw sessions'); Active := True; Inc(Begins);
end;
procedure TRawTag.EndSession;
begin
  Check(Active, 'Owned raw release'); Active := False; Authenticated := False; Inc(Ends);
  if FailEnd then raise ECardTransportError.Create('Synthetic release');
end;
function TRawTag.Activate: TBytes;
begin
  Check(Active, 'Activation requires session'); Inc(Activations); Authenticated := False;
  Result := CopyBytes(Uid);
  if Activations = SwapAt then Result[6] := Result[6] xor 1;
end;
function TRawTag.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
var Payload, B: TBytes; I, N: Integer;
begin
  Check(Active and (ABitCount = Length(AFrame) * 8), 'Exact full raw frame');
  Payload := Copy(AFrame, 0, Length(AFrame) - 2);
  Check(BytesEqual(AFrame, TRawUidCodec.AppendCrcA(Payload)), 'Outgoing CRC checked');
  Result := Default(TRawRfResponse);
  case Payload[0] of
    $1B:
      begin
        Inc(Auths);
        if not BytesEqual(Copy(Payload, 1, 4), Password) then raise ECardTransportError.Create('Wrong synthetic password');
        Authenticated := True; B := CopyBytes(Pack);
      end;
    $3A:
      begin
        Check(Authenticated, 'Read follows authentication');
        SetLength(B, (Payload[2] - Payload[1] + 1) * 4);
        N := 0;
        for I := Payload[1] to Payload[2] do begin Move(Pages[I][0], B[N], 4); Inc(N, 4); end;
      end;
    $A2:
      begin
        Check(Authenticated, 'Write follows authentication'); Inc(Writes);
        if not SuppressWrite then begin
          Pages[Payload[1]] := Copy(Payload, 2, 4);
          if Payload[1] = Config + 2 then Password := Copy(Payload, 2, 4);
          if Payload[1] = Config + 3 then Pack := Copy(Payload, 2, 2);
        end;
        if FailWrite then raise ECardTransportError.Create('Synthetic response lost after dispatch');
        Result.Data := HexToBytes('0A'); Result.BitCount := 4; Exit;
      end;
  else raise Exception.Create('Unexpected RF command'); end;
  Result.Data := TRawUidCodec.AppendCrcA(B); Result.BitCount := Length(Result.Data) * 8;
end;
constructor TIsoTag.Create(const AProfile: TIso15693PasswordProfile);
var I: Integer;
begin
  inherited Create; Profile := AProfile;
  Info := Default(TIso15693SystemInfo); Info.BlockSize := 4;
  Info.Uid := HexToBytes('E004010802030405'); Info.BlockCount := 80;
  if Profile = ippSt25Dv then begin
    Info.Uid := HexToBytes('E002240102030405'); Info.BlockCount := 128;
    Info.HasIcReference := True; Info.IcReference := $24;
  end;
  SetLength(Data, Info.BlockCount);
  for I := 0 to High(Data) do Data[I] := HexToBytes('11223344');
  for I := 0 to 3 do begin
    Passwords[I] := HexToBytes('01020304');
    if Profile = ippSt25Dv then Passwords[I] := HexToBytes('0102030405060708');
  end;
  Protection := HexToBytes('0533007F070000'); Registers := HexToBytes('0003A00400050000');
end;
function TIsoTag.BeginSession: TIso15693SystemInfo;
var I: Integer;
begin
  Check(not Active, 'No nested ISO session'); Active := True; Inc(Begins);
  for I := 0 to 3 do Authenticated[I] := False;
  Result := Info; Result.Uid := CopyBytes(Info.Uid);
  if Begins = SwapAt then Result.Uid[7] := Result.Uid[7] xor 1;
end;
procedure TIsoTag.EndSession;
begin
  Check(Active, 'Owned ISO release'); Active := False; Inc(Ends);
  if FailEnd then raise ECardTransportError.Create('Synthetic ISO release');
end;
function TIsoTag.ReadBlock(const ABlock: Integer): TBytes;
begin
  Check(Active and (Auths > 0), 'ISO read authenticated'); Result := CopyBytes(Data[ABlock]);
end;
function TIsoTag.SecurityStatus(const ABlock: Integer): Byte;
begin Check(Active, 'ISO lock read session'); Result := Ord(Locked); end;
procedure TIsoTag.WriteBlock(const ABlock: Integer; const AData: TBytes);
begin
  Check(Active and (Auths > 0) and not Locked, 'ISO write authenticated and unlocked'); Inc(Writes);
  if not SuppressWrite then Data[ABlock] := CopyBytes(AData);
  if FailWrite then raise ECardTransportError.Create('Synthetic ISO write response lost');
end;
function TIsoTag.ResetField: TIso15693SystemInfo;
var I: Integer;
begin
  Check(Active, 'Reset inside ISO session'); Inc(Resets);
  for I := 0 to 3 do Authenticated[I] := False;
  Result := Info; Result.Uid := CopyBytes(Info.Uid);
end;
function TIsoTag.ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
var P: TBytes; Id, I: Integer;
begin
  Check(Active, 'Manufacturer command in session');
  Check(AManufacturer = Info.Uid[1], 'Exact manufacturer'); Result := nil;
  case ACommand of
    $B2: Result := HexToBytes('1234');
    $B3:
      begin
        Id := AParameters[0]; P := Copy(AParameters, 1, Length(AParameters) - 1); Inc(Auths);
        if Profile = ippSlix2 then for I := 0 to 3 do begin
          if I mod 2 = 0 then P[I] := P[I] xor $12 else P[I] := P[I] xor $34;
        end;
        if not BytesEqual(P, Passwords[Id]) then raise EIso15693StatusError.Create($0F);
        Authenticated[Id] := True;
      end;
    $AB: Result := CopyBytes(Protection);
    $A0:
      begin Id := AParameters[0] - 4; if AParameters[0] = $0F then Id := 7;
        SetLength(Result, 1); Result[0] := Registers[Id]; end;
    $AD: Result := HexToBytes('00');
    $B4, $B1:
      begin
        Id := AParameters[0]; Check(Authenticated[Id], 'Credential update authenticated'); Inc(Writes);
        if not SuppressWrite then Passwords[Id] := Copy(AParameters, 1, Length(AParameters) - 1);
        if FailWrite then raise ECardTransportError.Create('Credential response lost');
      end;
    $B6:
      begin
        Check(Authenticated[1] and Authenticated[2], 'Both SLIX2 credentials required'); Inc(Writes);
        if not SuppressWrite then begin Protection[0] := AParameters[0]; Protection[1] := AParameters[1]; end;
        if FailWrite then raise ECardTransportError.Create('Policy response lost');
      end;
    $A1:
      begin
        Check(Authenticated[0], 'Configuration password required'); Inc(Writes);
        if not SuppressWrite then Registers[AParameters[0] - 4] := AParameters[1];
        if FailWrite then raise ECardTransportError.Create('Policy response lost');
      end;
  else raise Exception.Create('Unexpected manufacturer command'); end;
end;
procedure TCancel.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin if AState = cwsWriting then TCardWorkflow(Sender).Cancel; end;
function Addresses: TCardWorkflowAddresses;
begin Result := nil; SetLength(Result, 2); Result[0] := 4; Result[1] := 5; end;
procedure TestType2Memory;
var Source, Target: TRawTag; A, B: ICardWorkflowMemory; W: TProtectedMemoryWorkflow;
  Model: TType2TagModel; Mode: Integer; Failed: Boolean; S: TCardWorkflowSnapshot; Cancel: TCancel;
begin
  for Model := ttmUltralightEv1_48 to High(TType2TagModel) do
    for Mode := 0 to 12 do begin
      Source := TRawTag.Create(Model); Target := TRawTag.Create(Model);
      A := CreateType2PasswordWorkflowMemory(Source, Model, Source.Password, Source.Pack);
      B := CreateType2PasswordWorkflowMemory(Target, Model, Target.Password, Target.Pack);
      Target.Pages[4] := HexToBytes('55667788'); Target.Pages[5] := HexToBytes('99AABBCC');
      W := TProtectedMemoryWorkflow.Create(nil); Cancel := TCancel.Create;
      try
        W.PrepareProtectedCopy(A, B, Addresses, Mode = 1);
        Check((Source.Begins = 0) and (Target.Begins = 0), 'Prepare performs no I/O');
        case Mode of
          2: Target.Pages[2][2] := $10;
          3: Target.FailWrite := True;
          4: Source.SwapAt := 2;
          5: Target.Password[0] := $AA;
          6: Target.SuppressWrite := True;
          7: W.OnProgress := Cancel.Progress;
          8: Target.FailEnd := True;
          10: if Model in [ttmUltralightEv1_48, ttmNtag210] then Target.Pages[2][3] := 1
          else Target.Pages[Target.Config - 1][0] := 1;
          11: Target.SwapAt := 9;
          12: Target.SwapAt := 10;
          9: if Model in [ttmNtag213, ttmNtag215, ttmNtag216] then Target.Pages[Target.Config][0] := $40
          else Target.Pages[2][3] := 1;
        end;
        case Mode of
          0, 1: Check(W.Execute = cwsCompleted, 'Copy/compare completes');
          3, 6: Check(W.Execute = cwsUncertain, 'Post-dispatch ambiguity retained');
          7: Check(W.Execute = cwsCancelled, 'Cancellation before write');
        else Check(W.Execute = cwsFailed, 'Pre-dispatch rejection fails ' + IntToStr(Ord(Model)) + ':' + IntToStr(Mode) + ' ' + CardWorkflowStateName(W.State) + ' ' + W.ErrorClass); end;
        if Mode in [1, 2, 4, 5, 7, 8, 9, 10, 11, 12] then Check(Target.Writes = 0, 'Rejected or read-only request does not write');
        if Mode in [11, 12] then Check(W.Results[0].State = cwusPending, 'Known pre-write refusal stays pending');
        if Mode = 0 then Check((Target.Writes = 2) and (W.Results[0].State = cwusVerified), 'Every different page verified');
        if Mode in [3, 6] then Check((Target.Writes = 1) and (W.Results[0].State = cwusUncertain), 'No retry after ambiguous write');
        Check(not Source.Active and not Target.Active, 'Sessions released');
        S := W.Snapshot;
        if Mode in [0, 1] then Check(Pos('01020304', TCardWorkflowArchive.Encode(S)) = 0, 'Archive excludes password');
        Failed := False; try A.ReadUnit(4); except on E: ECardWorkflowError do Failed := True; end;
        Check(Failed, 'Source credential backend consumed');
        Failed := False; try B.ReadUnit(4); except on E: ECardWorkflowError do Failed := True; end;
        Check(Failed, 'Target credential backend consumed');
      finally W.Free; Cancel.Free; A := nil; B := nil; end;
    end;
end;
procedure TestIsoMemory;
var Source, Target: TIsoTag; A, B: ICardWorkflowMemory; P: TIso15693Passwords;
  SourceSession, TargetSession: IIso15693Session;
  W: TProtectedMemoryWorkflow; Profile: TIso15693PasswordProfile; Mode: Integer; Failed: Boolean;
begin
  for Profile := Low(TIso15693PasswordProfile) to High(TIso15693PasswordProfile) do
    for Mode := 0 to 7 do begin
      Source := TIsoTag.Create(Profile); Target := TIsoTag.Create(Profile);
      SourceSession := Source; TargetSession := Target;
      SetLength(P, 1); P[0].Identifier := 1; P[0].Value := CopyBytes(Source.Passwords[1]);
      A := CreateIso15693PasswordWorkflowMemory(SourceSession, Profile, P, Source.Info.BlockCount, 4);
      B := CreateIso15693PasswordWorkflowMemory(TargetSession, Profile, P, Target.Info.BlockCount, 4);
      P[0].Value[0] := $CC; Target.Data[4] := HexToBytes('99887766');
      W := TProtectedMemoryWorkflow.Create(nil);
      try
        W.PrepareProtectedCopy(A, B, Addresses, Mode = 1);
        Check((Source.Begins = 0) and (Target.Begins = 0), 'ISO preparation frozen and local');
        case Mode of
          2: Target.Locked := True;
          3: Target.FailWrite := True;
          4: Source.SwapAt := 2;
          5: Target.Passwords[1][0] := $EE;
          6: Target.Info.BlockCount := Target.Info.BlockCount - 1;
          7: Target.SuppressWrite := True;
        end;
        case Mode of
          0, 1: Check(W.Execute = cwsCompleted, 'ISO copy or compare completes');
          3, 7: Check(W.Execute = cwsUncertain, 'ISO uncertain write');
        else Check(W.Execute = cwsFailed, 'ISO pre-dispatch rejection'); end;
        if Mode in [1, 2, 4, 5, 6] then Check(Target.Writes = 0, 'ISO rejection no write');
        if Mode = 6 then Check(Target.Auths = 0, 'Geometry checked before password');
        Check(not Source.Active and not Target.Active, 'ISO sessions released');
        Failed := False; try A.ReadUnit(4); except on E: ECardWorkflowError do Failed := True; end;
        Check(Failed, 'ISO credentials consumed');
      finally W.Free; A := nil; B := nil; SourceSession := nil; TargetSession := nil; end;
    end;
end;
procedure TestSecurity;
var Raw: TRawTag; Iso: TIsoTag; Op: ICardSecurityOperation; W: TCardSecurityWorkflow;
  R: IRawContactlessReader; Session: IIso15693Session; P: TCardSecurityPlan;
  Mode, Kind: Integer; Failed: Boolean; Profile: TIso15693PasswordProfile;
begin
  for Kind := 0 to 1 do for Mode := 0 to 4 do begin
    Raw := TRawTag.Create(ttmNtag213); R := Raw;
    if Kind = 0 then Op := CreateType2CredentialOperation(R, ttmNtag213, Raw.Uid,
      Raw.Password, Raw.Pack, HexToBytes('55667788'), HexToBytes('CCDD'))
    else Op := CreateType2ProtectionOperation(R, ttmNtag213, Raw.Uid,
      HexToBytes('000000FF00000000'), Raw.Password, Raw.Pack, 4, True, 0);
    W := TCardSecurityWorkflow.Create(nil);
    try
      W.Prepare(Op); P := W.Plan; P.Uid[0] := $AA;
      Check(W.Plan.Uid[0] = 4, 'Plan deep copy'); Check(Raw.Begins = 0, 'Review local');
      case Mode of
        1: Raw.SwapAt := 1;
        2: Raw.Password[0] := $EE;
        3: Raw.FailWrite := True;
        4: if Kind = 0 then Raw.SuppressWrite := True else Raw.Pages[Raw.Config][0] := $10;
      end;
      if Mode = 0 then Check(W.Execute = cwsCompleted, 'Type2 security verified')
      else if (Mode = 3) or ((Mode = 4) and (Kind = 0)) then Check(W.Execute = cwsUncertain, 'Type2 security uncertainty')
      else Check(W.Execute = cwsFailed, 'Type2 security refused');
      if Mode in [1, 2] then Check(Raw.Writes = 0, 'No write after UID/auth mismatch');
      if Mode = 1 then Check(Raw.Auths = 0, 'Wrong UID before password');
      if Mode = 0 then Check((W.ResultState = cwusVerified) and (Raw.Activations >= 2), 'Fresh authentication proof');
      Failed := False; try Op.Validate; except on E: ECardWorkflowError do Failed := True; end;
      Check(Failed and not Raw.Active, 'Security operation consumed and released');
    finally W.Free; Op := nil; R := nil; end;
  end;
  for Profile := Low(TIso15693PasswordProfile) to High(TIso15693PasswordProfile) do
    for Kind := 0 to 1 do for Mode := 0 to 4 do begin
      Iso := TIsoTag.Create(Profile); Session := Iso;
      if Kind = 0 then begin
        if Profile = ippSlix2 then Op := CreateIso15693CredentialOperation(Session, Profile, Iso.Info.Uid, 80, 4, 1,
          Iso.Passwords[1], HexToBytes('55667788'))
        else Op := CreateIso15693CredentialOperation(Session, Profile, Iso.Info.Uid, 128, 4, 1,
          Iso.Passwords[1], HexToBytes('8877665544332211'));
      end else if Profile = ippSlix2 then Op := CreateSlix2ProtectionOperation(Session, Iso.Info.Uid,
        Iso.Passwords[1], Iso.Passwords[2], Iso.Protection, 10, $23)
      else Op := CreateSt25ProtectionOperation(Session, Iso.Info.Uid, 128, Iso.Passwords[0], Iso.Registers, 2, 2, 1);
      W := TCardSecurityWorkflow.Create(nil);
      try
        W.Prepare(Op); Check(Iso.Begins = 0, 'ISO security review local');
        case Mode of
          1: Iso.SwapAt := 1;
          2: if Kind = 0 then Iso.Passwords[1][0] := $EE else Iso.Passwords[0][0] := $EE;
          3: Iso.FailWrite := True;
          4: Iso.SuppressWrite := True;
        end;
        // SLIX2 policy uses passwords 1 and 2, not password zero.
        if (Mode = 2) and (Kind = 1) and (Profile = ippSlix2) then Iso.Passwords[1][0] := $EE;
        if Mode = 0 then Check(W.Execute = cwsCompleted, 'ISO security verified')
        else if Mode in [3, 4] then Check(W.Execute = cwsUncertain, 'ISO security ambiguous')
        else Check(W.Execute = cwsFailed, 'ISO security refused');
        if Mode in [1, 2] then Check(Iso.Writes = 0, 'ISO mismatch no write');
        if Mode = 1 then Check(Iso.Auths = 0, 'ISO UID checked before password');
        if Mode = 0 then Check((W.ResultState = cwusVerified) and (Iso.Resets >= 2), 'ISO fresh RF proof');
        Failed := False; try Op.Validate; except on E: ECardWorkflowError do Failed := True; end;
        Check(Failed and not Iso.Active, 'ISO security consumed and released');
      finally W.Free; Op := nil; Session := nil; end;
    end;
end;
procedure TestBackupRestore;
var Source, Target: TRawTag; A, B: ICardWorkflowMemory; W: TProtectedMemoryWorkflow;
  S: TCardWorkflowSnapshot; Failed: Boolean;
begin
  Source := TRawTag.Create(ttmNtag213);
  A := CreateType2PasswordWorkflowMemory(Source, ttmNtag213, Source.Password, Source.Pack);
  W := TProtectedMemoryWorkflow.Create(nil);
  try
    W.PrepareProtectedBackup(A, Addresses);
    Check(W.Execute = cwsCompleted, 'Password backup completes');
    S := TCardWorkflowArchive.Decode(TCardWorkflowArchive.Encode(W.Snapshot));
    Check(Source.Writes = 0, 'Backup never writes source');
    Target := TRawTag.Create(ttmNtag213);
    B := CreateType2PasswordWorkflowMemory(Target, ttmNtag213, Target.Password, Target.Pack);
    Target.Pages[4] := HexToBytes('99887766');
    W.PrepareProtectedRestore(S, B);
    S.Units[0].Data[0] := $FF;
    Check(W.Execute = cwsCompleted, 'Independent archive restore completes');
    Check(BytesToHex(Target.Pages[4]) = '11223344', 'Prepared image frozen');
    A := CreateType2PasswordWorkflowMemory(Source, ttmNtag213, Source.Password, Source.Pack);
    Failed := False;
    try W.PrepareProtectedBackup(A, nil); except on E: ECardWorkflowError do Failed := True; end;
    Check(Failed, 'Invalid preparation refused');
    Failed := False;
    try A.ReadUnit(4); except on E: ECardWorkflowError do Failed := True; end;
    Check(Failed, 'Failed preparation clears supplied credentials');
  finally W.Free; A := nil; B := nil; end;
end;
procedure TConfigurationWire.BeginTransaction;
begin Check(not Active, 'Configuration transaction not nested'); Active := True; Inc(Begins); end;
procedure TConfigurationWire.EndTransaction;
begin Check(Active, 'Configuration transaction released'); Active := False; Inc(Ends); end;
function TConfigurationWire.Exchange(const ACommand: TBytes): TBytes;
var P, B, WireUid: TBytes; N, Id: Integer;
begin
  Check(Active, 'Configuration command exclusive');
  if Kind = 0 then begin
    Check(BytesEqual(Copy(ACommand, 0, 4), HexToBytes('FF000000')), 'PN532 direct envelope');
    P := Copy(ACommand, 5, Length(ACommand) - 5);
    case P[1] of
      $32: B := HexToBytes('D533');
      $08: B := HexToBytes('D509');
      $4A:
        begin
          Inc(Selections); B := HexToBytes('D54B01010000000704112233445566');
          if Selections = SwapAt then B[14] := B[14] xor 1;
        end;
      $06:
        begin
          if Length(P) = 8 then B := HexToBytes('D507000000')
          else B := HexToBytes('D50700');
        end;
      $42:
        begin
          if P[2] = $1B then begin
            Inc(Auths); Check(BytesEqual(Copy(P, 2, Length(P)-2),
              TRawUidCodec.AppendCrcA(HexToBytes('1B01020304'))), 'Capture explicit password frame');
            P := TRawUidCodec.AppendCrcA(HexToBytes('A1B2'));
          end else begin
            Check(BytesEqual(Copy(P, 2, Length(P)-2),
              TRawUidCodec.AppendCrcA(HexToBytes('3A292A'))), 'Capture only configuration pages');
            P := TRawUidCodec.AppendCrcA(HexToBytes('000000FF00000000'));
          end;
          B := HexToBytes('D54300'); N := Length(B); SetLength(B, N + Length(P)); Move(P[0], B[N], Length(P));
        end;
    else raise Exception.Create('Unexpected configuration PN532 command'); end;
  end else begin
    WireUid := HexToBytes('05040302080104E0');
    if Kind = 2 then WireUid := HexToBytes('05040302012402E0');
    if BytesEqual(ACommand, HexToBytes('FFCA800000')) then begin
      SetLength(B, 9); B[0] := 0; Move(WireUid[0], B[1], 8);
    end else begin
      Check((ACommand[0] = $FF) and (ACommand[1] = $FB) and (ACommand[3] = $22), 'Addressed configuration envelope');
      P := Copy(ACommand, 5, Length(ACommand)-5);
      case P[0] of
        $2B:
          begin
            Inc(Selections);
            B := HexToBytes('0405040302080104E04F03');
            if Kind = 2 then B := HexToBytes('0C05040302012402E07F0324');
            if Selections = SwapAt then B[1] := B[1] xor 1;
          end;
        $AB:
          begin
            Check(BytesEqual(Copy(P, 2, 8), WireUid) and (P[1] = 4), 'Acquired SLIX2 UID');
            B := HexToBytes('0533007F070000');
          end;
        $A0:
          begin
            Check(BytesEqual(Copy(P, 2, 8), WireUid) and (P[1] = 2), 'Acquired ST25DV UID');
            Id := P[10] - 4; if P[10] = $0F then Id := 7;
            P := HexToBytes('0003A00400050000'); SetLength(B, 1); B[0] := P[Id];
          end;
      else raise Exception.Create('Configuration read dispatched unexpected command'); end;
      N := Length(B); SetLength(B, N+1); if N > 0 then Move(B[0], B[1], N); B[0] := 0;
    end;
  end;
  Result := B; N := Length(Result); SetLength(Result, N+2); Result[N] := $90; Result[N+1] := 0;
end;
procedure TestReviewRefusals;
var Raw: TRawTag; R: IRawContactlessReader; Iso: TIsoTag; Session: IIso15693Session;
  Op: ICardSecurityOperation; Memory: ICardWorkflowMemory; Passwords: TIso15693Passwords;
  Before: TBytes; P: TCardSecurityPlan; Failed: Boolean; Mode: Integer;
begin
  Raw := TRawTag.Create(ttmNtag213); R := Raw;
  Before := HexToBytes('123456FF38AABBCC');
  Op := CreateType2ProtectionOperation(R, ttmNtag213, Raw.Uid, Before, Raw.Password, Raw.Pack, 4, True, 3);
  Before[0] := $FF; P := Op.Plan;
  Check((P.Before[0] = $12) and (P.After[4] = $BB) and (P.After[7] = $CC), 'Preserve non-policy bits and own preimage');
  P.After[0] := $FF;
  Check(Op.Plan.After[0] = $12, 'Policy plan deeply owned');
  Check(Raw.Begins = 0, 'Exact policy planning no I/O');
  Op := nil; R := nil;
  for Mode := 0 to 3 do begin
    Iso := TIsoTag.Create(ippSlix2); Session := Iso; Failed := False;
    try
      case Mode of
        0: begin
          Before := HexToBytes('0533087F070000');
          Op := CreateSlix2ProtectionOperation(Session, Iso.Info.Uid, Iso.Passwords[1], Iso.Passwords[2], Before, 5, $33);
        end;
        1: begin
          Before := HexToBytes('05330000000000');
          Op := CreateSlix2ProtectionOperation(Session, Iso.Info.Uid, Iso.Passwords[1], Iso.Passwords[2], Before, 5, $33);
        end;
        2: begin
          SetLength(Passwords, 1); Passwords[0].Identifier := 1; Passwords[0].Value := HexToBytes('01020304');
          Memory := CreateIso15693PasswordWorkflowMemory(Session, ippSlix2, Passwords, 128, 4);
        end;
        3: begin
          SetLength(Passwords, 1); Passwords[0].Identifier := 1; Passwords[0].Value := HexToBytes('01020304');
          Memory := CreateIso15693PasswordWorkflowMemory(Session, ippSlix2, Passwords, 80, 4);
          Memory.ValidateUnit(79, True);
        end;
      end;
    except on E: ECardWorkflowError do Failed := True; end;
    Check(Failed and (Iso.Begins = 0) and (Iso.Auths = 0), 'Unsupported or locked request refused before hardware');
    Op := nil; Memory := nil; Session := nil;
  end;
end;
procedure TestConfigurationCapture;
var Wire: TConfigurationWire; Readers: TReaders; Factory: ICardWorkflowDemoReaders;
  Ops: ICardDemoOperations; V: ICardDemoRequestValidator; R: TCardDemoRequest;
  Result: TCardDemoResult; Error, Text: UnicodeString; Kind, Mode: Integer; Failed: Boolean;
begin
  for Kind := 0 to 2 do for Mode := 0 to 1 do begin
    Wire := TConfigurationWire.Create; Wire.Kind := Kind;
    Readers := TReaders.Create; Readers.Transport := Wire; Factory := Readers;
    Ops := CreateProtectedWorkflowOperations(Factory); Supports(Ops, ICardDemoRequestValidator, V);
    R := Default(TCardDemoRequest); R.Operation := cdoFamily; R.FamilyAction := 8;
    R.FamilyName := 'ProtectedType2WorkflowDemo'; SetLength(R.Arguments, 4);
    R.Arguments[0] := 'Synthetic reader'; R.Arguments[1] := '3';
    SetLength(R.Credentials, 3); R.Credentials[1] := HexToBytes('01020304A1B2');
    if Kind > 0 then begin
      R.FamilyName := 'ProtectedIso15693WorkflowDemo'; R.Arguments[1] := '0';
      R.Credentials[1] := nil; // Public configuration read never attempts a password.
      if Kind = 2 then begin R.Arguments[1] := '1'; R.Arguments[3] := 'blocks=128'; end;
    end;
    Check(V.TryValidateRequest(R, Error) and (Wire.Begins = 0), 'Capture validation hardware free');
    if Mode = 1 then Wire.SwapAt := 2;
    Result := Default(TCardDemoResult); Failed := False;
    try Ops.Run(R, Result); except on E: Exception do Failed := True; end;
    Check(Failed = (Mode = 1), 'Capture same-card guard');
    Check(not Wire.Active and (Wire.Begins = Wire.Ends), 'Capture releases every transaction');
    if Mode = 1 then Check(Wire.Auths = 0, 'Capture UID swap before authentication')
    else begin
      Check(Result.Success and (Length(Result.Artifacts) = 1), 'Current configuration artifact');
      Check(Result.Artifacts[0].Name = 'protected-options.txt', 'Separate configuration artifact');
      Text := TEncoding.UTF8.GetString(Result.Artifacts[0].Data);
      Check((Pos('uid=', string(Text)) > 0) and (Pos('before=', string(Text)) > 0), 'Capture editable UID and preimage');
      Check((Pos('01020304A1B2', string(Text)) = 0) and
        (Pos('password=', string(Text)) = 0), 'Capture artifact excludes password');
      if Kind = 0 then Check(Wire.Auths = 1, 'Type2 configuration authenticates once')
      else Check(Wire.Auths = 0, 'ISO public configuration no password');
    end;
    V := nil; Ops := nil; Factory := nil;
  end;
end;
procedure TestDemoPreview;
var Readers: TReaders; Factory: ICardWorkflowDemoReaders; Ops: ICardDemoOperations;
  V: ICardDemoRequestValidator; R: TCardDemoRequest; Result: TCardDemoResult; Error: UnicodeString; Kind: Integer;
begin
  Readers := TReaders.Create; Factory := Readers; Ops := CreateProtectedWorkflowOperations(Factory);
  Check(Supports(Ops, ICardDemoRequestValidator, V), 'Demo validator exposed');
  for Kind := 0 to 1 do begin
    R := Default(TCardDemoRequest); R.Operation := cdoFamily; R.FamilyAction := 4;
    R.FamilyName := 'ProtectedType2WorkflowDemo';
    SetLength(R.Arguments, 4); R.Arguments[0] := 'Synthetic reader'; R.Arguments[1] := '3';
    R.Arguments[3] := 'uid=04112233445566';
    SetLength(R.Credentials, 3); R.Credentials[1] := HexToBytes('01020304A1B2');
    R.Credentials[2] := HexToBytes('55667788CCDD');
    if Kind = 1 then begin
      R.FamilyName := 'ProtectedIso15693WorkflowDemo'; R.Arguments[1] := '0';
      R.Arguments[3] := 'uid=E004010802030405';
      R.Credentials[1] := HexToBytes('01020304'); R.Credentials[2] := HexToBytes('55667788');
    end;
    Check(V.TryValidateRequest(R, Error), 'Valid security preview inputs');
    Result := Default(TCardDemoResult); Ops.Run(R, Result);
    Check(Result.Success and (Pos('55667788', string(Result.Text)) = 0), 'Preview no I/O and excludes password');
    R.FamilyAction := 5;
    Check(not V.TryValidateRequest(R, Error), 'Apply requires acknowledgement');
    R.MutationAcknowledged := True;
    Check(V.TryValidateRequest(R, Error), 'Acknowledged apply validation stays offline');
    R.Arguments[3] := R.Arguments[3] + #13#10 + 'unknown=1';
    Check(not V.TryValidateRequest(R, Error), 'Unknown config rejected');
  end;
  Check(Readers.Created > 0, 'Deferred transport factory exercised');
end;
begin
  try
    TestBackupRestore; TestDemoPreview; TestConfigurationCapture; TestReviewRefusals; TestType2Memory; TestIsoMemory; TestSecurity;
    Writeln('PASS: ', Checks, ' protected memory and security assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
