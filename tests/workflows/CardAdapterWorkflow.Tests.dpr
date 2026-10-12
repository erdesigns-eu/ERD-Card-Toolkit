program CardAdapterWorkflowTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Workflow, ERD.Card.Workflow.Archive,
  ERD.Card.Ndef, ERD.Card.Crypto, ERD.Card.Crypto.DES, ERD.Card.Crypto.OpenSSL,
  ERD.Card.Contactless, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Type2.Password, ERD.Card.Contactless.ISO15693,
  ERD.Card.Contactless.Type5.Ndef, ERD.Card.Contactless.Workflow,
  ERD.Card.Contactless.Workflow.Ndef, ERD.Card.Contactless.Workflow.Ndef.Protected,
  ERD.Card.Contactless.Workflow.Password, ERD.Card.Contactless.Workflow.Security,
  ERD.Card.Contactless.Workflow.UltralightC, ERD.Card.Reader.TWN4, ERD.Card.Reader.TWN4.Workflow;
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
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse; virtual;
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
  TUltralightTag = class(TRawTag)
    Provider: ICardDesProvider;
    Challenge: TBytes;
    constructor Create(const AProvider: ICardDesProvider);
    function Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse; override;
  end;
  TKeys = class(TInterfacedObject, IClassicWorkflowKeys, ITwn4WorkflowSectors)
    Calls: Integer;
    function GetKey(const ABlock: Integer; const AWriting: Boolean; out AKeyType: TMifareClassicKeyType): TBytes;
    function ReaderSector(const ABlock: Integer): Byte;
  end;
  TTwnChannel = class(TInterfacedObject, ITwn4ByteChannel)
    Active, Classic, FailWrite, Swap, BadFamily: Boolean;
    Data, Reply: TBytes;
    Opens, Closes, Writes, Position, Logins, ExpectedSector, ExpectedBlock: Integer;
    procedure Open;
    procedure Close;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
  end;
  TCancelObserver = class
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
  end;
  TNdefFake = class(TInterfacedObject, ICardWorkflowNdef, ICardWorkflowCredentialCleanup)
    Bytes: TBytes;
    Reads, Writes, Clears, Mode: Integer;
    function ReadMessage: TBytes;
    procedure WriteMessage(const ABytes: TBytes);
    procedure ClearCredentials;
  end;
var Checks: Integer;
procedure Check(const B: Boolean; const M: string);
begin Inc(Checks); if not B then raise Exception.Create(M); end;
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

constructor TUltralightTag.Create(const AProvider: ICardDesProvider);
begin
  inherited Create(ttmNtag213); Provider := AProvider;
  Config := 42; Password := HexToBytes('000102030405060708090A0B0C0D0E0F');
  Pages[41] := HexToBytes('00000000'); Pages[42] := HexToBytes('30000000');
  Pages[43] := HexToBytes('01000000');
end;
function TUltralightTag.Exchange(const AFrame: TBytes; const ABitCount: Integer): TRawRfResponse;
var P, B, Plain, Nonce, Zero, KeyData: TBytes; I: Integer;
begin
  Check(Active and (ABitCount = Length(AFrame) * 8), 'Exclusive Ultralight C frame');
  P := Copy(AFrame, 0, Length(AFrame)-2);
  Check(BytesEqual(AFrame, TRawUidCodec.AppendCrcA(P)), 'Ultralight C outgoing CRC');
  Result := Default(TRawRfResponse);
  case P[0] of
    $1A:
      begin
        Inc(Auths); Zero := HexToBytes('0000000000000000');
        Challenge := TCardDesCrypto.Crypt(Provider, Password, Zero, HexToBytes('0102030405060708'), True);
        SetLength(B, 9); B[0] := $AF; Move(Challenge[0], B[1], 8);
      end;
    $AF:
      begin
        Plain := TCardDesCrypto.Crypt(Provider, Password, Challenge, Copy(P, 1, 16), False);
        Check(BytesToHex(Copy(Plain, 8, 8)) = '0203040506070801', 'Mutual card nonce proof');
        Nonce := Copy(Plain, 0, 8); SetLength(Plain, 8);
        for I := 0 to 7 do Plain[I] := Nonce[(I+1) mod 8];
        Plain := TCardDesCrypto.Crypt(Provider, Password, Copy(P, 9, 8), Plain, True);
        SetLength(B, 9); B[0] := 0; Move(Plain[0], B[1], 8); Authenticated := True;
      end;
    $30:
      begin
        Check(Authenticated, 'Ultralight C authenticated read');
        SetLength(B, 16); for I := 0 to 3 do Move(Pages[P[1]+I][0], B[I*4], 4);
      end;
    $A2:
      begin
        Check(Authenticated, 'Ultralight C authenticated write'); Inc(Writes);
        if not SuppressWrite then Pages[P[1]] := Copy(P, 2, 4);
        if (P[1] = 47) and not SuppressWrite then begin
          SetLength(KeyData, 16); for I := 0 to 3 do Move(Pages[44+I][0], KeyData[I*4], 4);
          for I := 0 to 7 do begin Password[I] := KeyData[7-I]; Password[8+I] := KeyData[15-I]; end;
        end;
        if FailWrite then raise ECardTransportError.Create('Ultralight response lost');
        Result.Data := HexToBytes('0A'); Result.BitCount := 4; Exit;
      end;
  else raise Exception.Create('Unexpected Ultralight C frame'); end;
  Result.Data := TRawUidCodec.AppendCrcA(B); Result.BitCount := Length(Result.Data)*8;
end;
function TKeys.GetKey(const ABlock: Integer; const AWriting: Boolean; out AKeyType: TMifareClassicKeyType): TBytes;
begin Inc(Calls); AKeyType := mckA; Result := HexToBytes('A0A1A2A3A4A5'); end;
function TKeys.ReaderSector(const ABlock: Integer): Byte;
begin Result := Byte(32 + (ABlock-128) div 16); end;
procedure TTwnChannel.Open;
begin Check(not Active, 'TWN exclusive open'); Active := True; Inc(Opens); end;
procedure TTwnChannel.Close;
begin Check(Active, 'TWN owned close'); Active := False; Inc(Closes); end;
procedure TTwnChannel.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
var S, Hex: string; P, B: TBytes; I: Integer;
begin
  Check(Active and (ATimeoutMs > 0), 'TWN bounded send'); S := '';
  for I := 0 to Length(ABytes)-2 do S := S + Chr(ABytes[I]); P := HexToBytes(S);
  case P[0] of
    $05:
      if P[1] = 0 then begin
        B := HexToBytes('000180380704112233445566');
        if Classic then B := HexToBytes('000180200466CF4DC2');
        if Swap then B[High(B)] := B[High(B)] xor 1;
        if BadFamily then B[2] := $40;
      end else B := HexToBytes('00');
    $0B, $0C:
      begin
        if (P[0] = $0B) and (P[1] = 0) then begin
          Check(BytesToHex(Copy(P,2,6)) = 'A0A1A2A3A4A5', 'Explicit temporary TWN key');
          Check(P[9] = ExpectedSector, 'TWN explicit firmware sector dispatched');
          Inc(Logins); B := HexToBytes('0001');
        end else if ((P[0] = $0B) and (P[1] = 2)) or ((P[0] = $0C) and (P[1] = 1)) then begin
          Check(P[2] = ExpectedBlock, 'TWN exact native write address');
          Inc(Writes); Data := Copy(P,3,Length(P)-3);
          if FailWrite then raise ECardTransportError.Create('TWN response lost');
          B := HexToBytes('0001');
        end else begin
          B := HexToBytes('0001'); SetLength(B,18); FillChar(B[2],16,0); Move(Data[0],B[2],Length(Data));
        end;
      end;
  else raise Exception.Create('Unexpected TWN command'); end;
  Hex := BytesToHex(B); SetLength(Reply,Length(Hex)+1);
  for I := 1 to Length(Hex) do Reply[I-1] := Ord(Hex[I]); Reply[High(Reply)] := 13; Position := 0;
end;
function TTwnChannel.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
begin Check(Active and (Position < Length(Reply)), 'TWN bounded receive'); Result := Reply[Position]; Inc(Position); end;
function TTwnChannel.NowMs: UInt64;
begin Result := 1; end;
function TNdefFake.ReadMessage: TBytes;
begin Inc(Reads); Result := CopyBytes(Bytes); end;
procedure TNdefFake.WriteMessage(const ABytes: TBytes);
begin
  Inc(Writes);
  if Mode = 1 then raise ECardWorkflowWriteRefused.Create('Refused');
  Bytes := CopyBytes(ABytes);
  if Mode = 2 then raise Exception.Create('Unknown dispatch outcome');
  if Mode = 3 then raise EContactlessWriteUncertain.Create('Unknown native outcome');
end;
procedure TNdefFake.ClearCredentials;
begin Inc(Clears); end;
procedure TestUltralight;
var Tag: TUltralightTag; Raw: IRawContactlessReader; Memory: ICardWorkflowMemory;
  Provider: ICardDesProvider; W: TProtectedMemoryWorkflow; Sec: TCardSecurityWorkflow;
  A: TCardWorkflowAddresses; S: TCardWorkflowSnapshot; Op: ICardSecurityOperation; Kind, Mode: Integer; Failed: Boolean;
begin
  Provider := TCardOpenSslAesProvider.Create; SetLength(A,1); A[0] := 4;
  for Kind := 0 to 2 do for Mode := 0 to 4 do begin
    Tag := TUltralightTag.Create(Provider); Raw := Tag;
    W := TProtectedMemoryWorkflow.Create(nil); Sec := TCardSecurityWorkflow.Create(nil);
    try
      if Kind = 0 then begin
        Memory := CreateUltralightCWorkflowMemory(Raw, Provider, Tag.Password);
        S := Default(TCardWorkflowSnapshot); S.Layout := 'ULTRALIGHT-C'; S.Uid := CopyBytes(Tag.Uid);
        SetLength(S.Units,1); S.Units[0].Address := 4; S.Units[0].Data := HexToBytes('AABBCCDD');
        W.PrepareProtectedRestore(S, Memory);
      end else begin
        if Kind = 1 then Op := CreateUltralightCKeyOperation(Raw, Provider, Tag.Uid,
          Tag.Password, HexToBytes('112233445566778899AABBCCDDEEFF00'))
        else Op := CreateUltralightCProtectionOperation(Raw, Provider, Tag.Uid,
          HexToBytes('3000000001000000'), Tag.Password, 4, True);
        Sec.Prepare(Op);
      end;
      Check(Tag.Begins = 0, 'Ultralight prepare no I/O');
      case Mode of
        1: Tag.SwapAt := 1;
        2: if Kind = 0 then Tag.Pages[2][3] := 1 else Tag.Pages[40][1] := $E0;
        3: Tag.FailWrite := True;
        4: Tag.SuppressWrite := True;
      end;
      if Kind = 0 then begin
        case Mode of
          0: Check(W.Execute = cwsCompleted, 'Ultralight restore verified');
          3,4: Check(W.Execute = cwsUncertain, 'Ultralight uncertain write');
        else Check(W.Execute = cwsFailed, 'Ultralight preflight refused'); end;
        Failed := False; try Memory.ReadUnit(4); except on E: ECardWorkflowError do Failed := True; end;
        Check(Failed, 'Ultralight key consumed');
      end else begin
        case Mode of
          0: Check(Sec.Execute = cwsCompleted, 'Ultralight security verified');
          3,4: Check(Sec.Execute = cwsUncertain, 'Ultralight security ambiguous');
        else Check(Sec.Execute = cwsFailed, 'Ultralight security refused'); end;
      end;
      Check(not Tag.Active, 'Ultralight released');
      if Mode in [1,2] then Check(Tag.Writes = 0, 'Ultralight refusal no write');
    finally W.Free; Sec.Free; Memory := nil; Op := nil; Raw := nil; end;
  end;
end;
procedure TestNdefNative;
var Tag: TRawTag; Raw: IRawContactlessReader; Iso: TIsoTag; Session: IIso15693Session;
  Backend: ICardWorkflowNdef; P: TIso15693Passwords; W: TProtectedNdefWorkflow;
  Bytes, Config: TBytes; Family, Mode, I: Integer; Failed: Boolean;
begin
  for Family := 0 to 2 do for Mode := 0 to 7 do begin
    Raw := nil; Session := nil; Tag := nil; Iso := nil;
    Bytes := HexToBytes('0308D101045402656E41FE0000');
    if Family = 0 then begin
      Tag := TRawTag.Create(ttmNtag213); Raw := Tag; Tag.Pages[3] := HexToBytes('E1101200');
      for I := 0 to 2 do Tag.Pages[4+I] := Copy(Bytes,I*4,4);
      Backend := CreateType2PasswordWorkflowNdef(Raw,ttmNtag213,Tag.Password,Tag.Pack);
    end else begin
      Iso := TIsoTag.Create(TIso15693PasswordProfile(Family-1)); Session := Iso;
      for I := 0 to High(Iso.Data) do Iso.Data[I] := HexToBytes('00000000');
      Iso.Data[0] := HexToBytes('E1400200');
      if Mode = 7 then Iso.Data[0][1] := $43;
      if Mode = 6 then Iso.Data[0][1] := $4A; // Explicit proprietary read/write.
      for I := 0 to 2 do Iso.Data[1+I] := Copy(Bytes,I*4,4);
      SetLength(P,1); P[0].Identifier := 1; P[0].Value := CopyBytes(Iso.Passwords[1]);
      Backend := CreateIso15693PasswordWorkflowNdef(Session,TIso15693PasswordProfile(Family-1),P,Iso.Info.BlockCount);
    end;
    W := TProtectedNdefWorkflow.Create(nil);
    try
      W.PrepareWrite(Backend,TNdefCodec.Decode(HexToBytes('D101045402656E42')),Mode = 1);
      if Family = 0 then begin
        Check(Tag.Begins = 0,'Type2 NDEF prepare no I/O');
        case Mode of 7: Tag.Pages[2][3] := 1; 2: Tag.Pages[2][3] := 1; 3: Tag.FailWrite := True; 4: Tag.SwapAt := 2; 5: Tag.SuppressWrite := True; end;
      end else begin
        Check(Iso.Begins = 0,'Type5 NDEF prepare no I/O');
        case Mode of 2: Iso.Locked := True; 3: Iso.FailWrite := True; 4: Iso.SwapAt := 2; 5: Iso.SuppressWrite := True; end;
      end;
      case Mode of
        0,1,6: Check(W.Execute = cwsCompleted,'Native NDEF template/compare completes');
        3,5: Check(W.Execute = cwsUncertain,'Native NDEF uncertain evidence');
      else Check(W.Execute = cwsFailed,'Native NDEF preflight refusal'); end;
      if Mode in [0,6] then Check(W.ReadBackVerified,'Native NDEF logical proof');
      if Family = 0 then Check(not Tag.Active,'Raw NDEF release') else Check(not Iso.Active,'ISO NDEF release');
      Failed := False; try Config := Backend.ReadMessage; Check(Length(Config) < 0, 'Consumed backend unexpectedly readable'); except on E: ECardWorkflowError do Failed := True; end;
      Check(Failed,'NDEF credentials consumed');
    finally W.Free; Backend := nil; Raw := nil; Session := nil; end;
  end;
end;
procedure TestType5AccessBoundaries;
var Iso: TIsoTag; Session: IIso15693Session; Backend: ICardWorkflowNdef;
  W: TProtectedNdefWorkflow; P: TIso15693Passwords; Bytes: TBytes;
  Snapshot: TType5NdefSnapshot; Info: TIso15693SystemInfo; Failed: Boolean; I: Integer;
begin
  Info := Default(TIso15693SystemInfo); Info.BlockSize := 4; Info.BlockCount := 80;
  Info.Uid := HexToBytes('E004010802030405');
  Bytes := HexToBytes('E14A02000308D101045402656E41FE0000000000');
  Failed := False;
  try Snapshot := TType5NdefCodec.DecodeSnapshot(Info,Bytes);
  except on E: EContactlessError do Failed := True; end;
  Check(Failed,'Default codec refuses proprietary CC access');
  Snapshot := TType5NdefCodec.DecodeSnapshot(Info,Bytes,True);
  Check(BytesToHex(Snapshot.MessageBytes) = 'D101045402656E41','Explicit codec profile decodes proprietary mapping');
  Bytes[1] := $45; Failed := False;
  try Snapshot := TType5NdefCodec.DecodeSnapshot(Info,Bytes,True);
  except on E: EContactlessError do Failed := True; end;
  Check(Failed,'Reserved access code refused even with explicit profile');
  Iso := TIsoTag.Create(ippSlix2); Session := Iso;
  for I := 0 to High(Iso.Data) do Iso.Data[I] := HexToBytes('00000000');
  Iso.Data[0] := HexToBytes('E1400000'); Iso.Data[1] := HexToBytes('00000027');
  Bytes := HexToBytes('0308D101045402656E41FE0000');
  for I := 0 to 2 do Iso.Data[2+I] := Copy(Bytes,I*4,4);
  SetLength(P,1); P[0].Identifier := 1; P[0].Value := CopyBytes(Iso.Passwords[1]);
  Backend := CreateIso15693PasswordWorkflowNdef(Session,ippSlix2,P,80);
  W := TProtectedNdefWorkflow.Create(nil);
  try
    W.PrepareWrite(Backend,TNdefCodec.Decode(HexToBytes('D101045402656E42')));
    Check(W.Execute = cwsFailed,'SLIX2 NDEF mapped counter overlap refused');
    Check(Iso.Writes = 0,'Counter overlap refused before length invalidation');
    Check(not Iso.Active,'Counter overlap releases session');
  finally W.Free; Backend := nil; Session := nil; end;
end;
procedure TestNdefEvidence;
var Source, Target: TNdefFake; A, B: ICardWorkflowNdef; W: TProtectedNdefWorkflow; Mode: Integer;
begin
  for Mode := 0 to 4 do begin
    Source := TNdefFake.Create; Target := TNdefFake.Create; A := Source; B := Target;
    Source.Bytes := HexToBytes('D101045402656E41'); Target.Mode := Mode;
    W := TProtectedNdefWorkflow.Create(nil);
    try
      W.PrepareCopy(A,B,Mode = 4);
      case Mode of
        0,4: Check(W.Execute = cwsCompleted,'NDEF copy/compare');
        1: Check(W.Execute = cwsFailed,'Known NDEF refusal');
      else Check(W.Execute = cwsUncertain,'Unknown NDEF dispatch remains uncertain'); end;
      Check((Source.Clears > 0) and (Target.Clears > 0),'NDEF cleanup every exit');
      if Mode = 4 then Check(Target.Writes = 0,'Comparison never writes');
    finally W.Free; A := nil; B := nil; end;
  end;
end;
procedure TCancelObserver.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin if AState = cwsWriting then TCardWorkflow(Sender).Cancel; end;
procedure TestNdefLifecycle;
var Source, Target: TNdefFake; A, B: ICardWorkflowNdef; W: TProtectedNdefWorkflow;
  Observer: TCancelObserver; Mode: Integer; Failed: Boolean; Message: TNdefMessage;
begin
  for Mode := 0 to 5 do begin
    Source := TNdefFake.Create; Target := TNdefFake.Create; A := Source; B := Target;
    Source.Bytes := HexToBytes('D101045402656E41');
    W := TProtectedNdefWorkflow.Create(nil); Observer := TCancelObserver.Create;
    try
      case Mode of
        0: W.PrepareCopy(A,nil);
        1: begin Target.Bytes := CopyBytes(Source.Bytes); W.PrepareCopy(A,B); end;
        2: begin W.PrepareCopy(A,B); W.OnProgress := Observer.Progress; end;
        3: W.PrepareWrite(B,nil,True);
        4: W.PrepareWrite(B,nil,False,True);
        5: begin
          Failed := False; try W.PrepareWrite(B,nil); except on E: ECardWorkflowError do Failed := True; end;
          Check(Failed and (Target.Clears = 1),'Invalid clear preparation wipes credentials');
          Continue;
        end;
      end;
      Check((Source.Reads = 0) and (Target.Reads = 0),'NDEF preparation no I/O');
      if Mode = 2 then Check(W.Execute = cwsCancelled,'NDEF cancellation before write')
      else Check(W.Execute = cwsCompleted,'NDEF backup/clear/no-op completes');
      Check(Target.Writes = 0,'No-op and cancelled writes skipped');
      if Mode = 0 then Check(BytesToHex(W.MessageBytes) = 'D101045402656E41','NDEF backup exact logical bytes');
      Failed := False; try W.Execute; except on E: ECardWorkflowError do Failed := True; end;
      Check(Failed,'NDEF request single-use');
      // Fresh template is independently owned.
      Message := TNdefCodec.Decode(HexToBytes('D101045402656E42'));
      W.PrepareWrite(B,Message,True); Message[0].Payload[0] := $FF;
      Check(BytesToHex(W.MessageBytes) = 'D101045402656E42','Prepared template frozen');
    finally W.Free; Observer.Free; A := nil; B := nil; end;
  end;
end;
procedure TestTwn;
var Channel: TTwnChannel; Held: ITwn4ByteChannel; Reader: TTwn4CardReaderWriter;
  Keys: IClassicWorkflowKeys; Sectors: ITwn4WorkflowSectors; Memory: ICardWorkflowMemory;
  W: TProtectedMemoryWorkflow; Snapshot: TCardWorkflowSnapshot; Family, Mode: Integer;
begin
  for Family := 0 to 2 do for Mode := 0 to 4 do begin
    Channel := TTwnChannel.Create; Held := Channel; Channel.Classic := Family > 0;
    Channel.ExpectedBlock := 4;
    if Family = 1 then Channel.ExpectedBlock := 2;
    if Family = 2 then begin Channel.ExpectedBlock := 128; Channel.ExpectedSector := 32; end;
    Channel.Data := HexToBytes('01020304'); if Channel.Classic then Channel.Data := HexToBytes('000102030405060708090A0B0C0D0E0F');
    Reader := TTwn4CardReaderWriter.Create(nil); Reader.Channel := Held; Keys := TKeys.Create; Sectors := Keys as ITwn4WorkflowSectors;
    if Family = 2 then Memory := CreateTwn4ClassicWorkflowMemory(Reader,mcm4K,Keys,Sectors)
    else if Channel.Classic then Memory := CreateTwn4ClassicWorkflowMemory(Reader,mcm1K,Keys)
    else Memory := CreateTwn4Type2WorkflowMemory(Reader,ttmNtag213);
    Reader.Free; // Adapter owns independent settings and reader.
    Snapshot := Default(TCardWorkflowSnapshot); Snapshot.Layout := Memory.Layout;
    Snapshot.Uid := HexToBytes('04112233445566'); SetLength(Snapshot.Units,1);
    Snapshot.Units[0].Address := 4; Snapshot.Units[0].Data := HexToBytes('AABBCCDD');
    if Channel.Classic then begin Snapshot.Units[0].Address := Channel.ExpectedBlock; Snapshot.Units[0].Data := HexToBytes('101112131415161718191A1B1C1D1E1F'); end;
    W := TProtectedMemoryWorkflow.Create(nil);
    try
      W.PrepareProtectedRestore(Snapshot,Memory,Mode = 1);
      Check(Channel.Opens = 0,'TWN preparation hardware free');
      case Mode of 2: Channel.BadFamily := True; 3: Channel.FailWrite := True; 4: Channel.Swap := True; end;
      // Pin an explicit intended ID for the swap case: first acquisition otherwise defines the target.
      if Mode = 4 then begin
        W.Free; W := TProtectedMemoryWorkflow.Create(nil); Memory := nil;
        Reader := TTwn4CardReaderWriter.Create(nil); Reader.Channel := Held;
        if Family = 2 then Memory := CreateTwn4ClassicWorkflowMemory(Reader,mcm4K,Keys,Sectors,HexToBytes('66CF4DC2'))
        else if Channel.Classic then Memory := CreateTwn4ClassicWorkflowMemory(Reader,mcm1K,Keys,nil,HexToBytes('66CF4DC2'))
        else Memory := CreateTwn4Type2WorkflowMemory(Reader,ttmNtag213,HexToBytes('04112233445566'));
        Reader.Free; W.PrepareProtectedRestore(Snapshot,Memory);
      end;
      case Mode of
        0,1: Check(W.Execute = cwsCompleted,'TWN restore/compare');
        3: Check(W.Execute = cwsUncertain,'TWN lost dispatch uncertain');
      else Check(W.Execute = cwsFailed,'TWN identity/family refused'); end;
      Check(not Channel.Active and (Channel.Opens = Channel.Closes),'TWN all channels closed');
      if Mode in [1,2,4] then Check(Channel.Writes = 0,'TWN no unrequested write');
      if Mode = 4 then Check(Channel.Logins = 0,'TWN ID before key');
    finally W.Free; Memory := nil; Held := nil; Keys := nil; Sectors := nil; end;
  end;
  // 4K mapping is explicit and frozen without channel I/O.
  Channel := TTwnChannel.Create; Held := Channel; Reader := TTwn4CardReaderWriter.Create(nil); Reader.Channel := Held;
  Keys := TKeys.Create; Sectors := Keys as ITwn4WorkflowSectors;
  try
    Memory := CreateTwn4ClassicWorkflowMemory(Reader,mcm4K,Keys,Sectors);
    Memory.ValidateUnit(128,True);
    Check(Channel.Opens = 0,'4K mapping preparation no I/O');
  finally Memory := nil; Reader.Free; Held := nil; Keys := nil; Sectors := nil; end;
end;
begin
  try
    TestUltralight; TestNdefNative; TestType5AccessBoundaries; TestNdefEvidence; TestNdefLifecycle; TestTwn;
    Writeln('PASS: ',Checks,' card adapter workflow assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
