program MemoryCardTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Memory;

type
  TStep = record Command, Response: TBytes; end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends, FailAt: Integer;
    Active, BeginFails, EndFails: Boolean;
    MutatePin: TBytes;
    constructor Create;
    procedure Add(const Command, Response: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const Command: TBytes): TBytes;
  end;
  TBare = class(TInterfacedObject, ICardTransport)
  public
    Calls: Integer;
    function Exchange(const Command: TBytes): TBytes;
  end;

var Checks: Integer;

procedure Check(const Condition: Boolean; const Message: string);
begin Inc(Checks); if not Condition then raise Exception.Create(Message); end;

constructor TScript.Create;
begin inherited Create; FailAt := -1; end;

procedure TScript.Add(const Command, Response: string);
var N: Integer;
begin
  N := Length(Steps); SetLength(Steps, N + 1);
  Steps[N].Command := HexToBytes(Command); Steps[N].Response := HexToBytes(Response);
end;

procedure TScript.BeginTransaction;
begin
  Check(not Active, 'Nested acquisition'); Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('Injected acquisition failure');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Check(Active, 'Release without acquisition'); Inc(Ends); Active := False;
  if EndFails then raise ECardTransportError.Create('Sensitive cleanup message');
end;

function TScript.Exchange(const Command: TBytes): TBytes;
var N: Integer;
begin
  Check(Active, 'Command without transaction'); N := Position; Inc(Position);
  Check(N < Length(Steps), 'Extra/replayed command');
  Check(BytesEqual(Command, Steps[N].Command), 'Literal wire transcript mismatch');
  if (N = 0) and (Length(MutatePin) <> 0) then MutatePin[0] := $EE;
  if N = FailAt then raise ECardTransportError.Create('Sensitive transport message');
  Result := CopyBytes(Steps[N].Response);
end;

function TBare.Exchange(const Command: TBytes): TBytes;
begin Inc(Calls); Result := HexToBytes('9000'); end;

procedure Complete(const Script: TScript);
begin
  Check(Script.Position = Length(Script.Steps), 'Missing command');
  Check((Script.Begins = 1) and (Script.Ends = 1) and not Script.Active, 'Transaction lifetime');
end;

procedure AddAuthentication(const S: TScript; const ThreeByte: Boolean; const Pin: string);
begin
  if ThreeByte then
  begin S.Add('FFB1000004', '070000009000'); S.Add('FF20000003' + Pin, '9007'); S.Add('FFB1000004', '070000009000'); end
  else
  begin S.Add('FFB1000003', 'FF00009000'); S.Add('FF20000002' + Pin, '90FF'); S.Add('FFB1000003', 'FF00009000'); end;
end;

procedure WriteScript(const S: TScript);
begin
  S.Add('FFA400000106','9000'); S.Add('FFB0001E04','000000009000');
  S.Add('FFB2000004','FFFFFFFF9000'); AddAuthentication(S, True, '123456');
  S.Add('FFD0001E04AABBCCDD','9000'); S.Add('FFB0001E04','AABBCCDD9000');
end;

procedure TestGeometryAndCodecs;
var M: TMemoryCardModel; L: TMemoryCardLayout; B, D: TBytes;
  I, N, J, Bits: Integer; Status: TMemoryCardSecurityStatus; Rejected: Boolean;
begin
  for M := Low(TMemoryCardModel) to High(TMemoryCardModel) do
  begin
    L := TMemoryCardCodec.Layout(M);
    Check((L.Capacity >= 128) and (L.Capacity <= MemoryCardMaxBytes), 'Model capacity');
    B := TMemoryCardCodec.Select(M); Check((Length(B) = 6) and (B[5] = L.Selector), 'Selector');
    B := TMemoryCardCodec.Read(M,L.Capacity - 1,1);
    Check(B[1] = Byte($B0 or ((L.Capacity - 1) shr 16)), 'Last read bank');
    Check((B[2] = Byte(((L.Capacity - 1) shr 8) and $FF)) and (B[3] = $FF mod L.Capacity), 'Last address');
    B := TMemoryCardCodec.Write(M,mps8,L.Capacity - 1,HexToBytes('AB'));
    Check(B[1] = Byte($D0 or ((L.Capacity - 1) shr 16)), 'Last write bank');
    for I := 0 to 3 do
    begin
      Rejected := False;
      try case I of
        0: B := TMemoryCardCodec.Read(M,-1,1);
        1: B := TMemoryCardCodec.Read(M,L.Capacity,1);
        2: B := TMemoryCardCodec.Read(M,L.Capacity - 1,2);
        3: B := TMemoryCardCodec.Read(M,0,0);
      end; except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected,'Bad range accepted');
    end;
  end;
  Check(BytesToHex(TMemoryCardCodec.Read(mcmI2c1024Kbit,65536,128)) = 'FFB1000080','Literal high-bank read');
  Check(BytesToHex(TMemoryCardCodec.Write(mcmI2c1024Kbit,mps8,65536,HexToBytes('AB'))) = 'FFD1000001AB','Literal high-bank write');
  for I := 0 to 255 do
  begin
    B := HexToBytes('000000'); B[0] := Byte(I); Status := TMemoryCardCodec.DecodeSecurity(mcmSle4428,B);
    Bits := 0; for J := 0 to 7 do if (I and (1 shl J)) <> 0 then Inc(Bits);
    Check(Status.RemainingAttempts = Bits,'Eight-bit popcount'); Check(Status.Blocked = (I = 0),'Counter blocked');
    if I < 8 then
    begin SetLength(B,4); Status := TMemoryCardCodec.DecodeSecurity(mcmSle4442,B); Check(Status.RemainingAttempts = Bits,'Three-bit popcount'); end;
  end;
  for I := 0 to 4 do
    Check(TMemoryCardCodec.SelectPage(TMemoryCardPageSize(I))[5] = I + 3,'Physical page selector');
  for I := 0 to 7 do
  begin
    Rejected := False;
    try case I of
      0: B := TMemoryCardCodec.Read(mcmI2c1024Kbit,65535,2);
      1: B := TMemoryCardCodec.Write(mcmI2c16Kbit,mps8,7,HexToBytes('AABB'));
      2: B := TMemoryCardCodec.Protect(mcmSle4442,31,HexToBytes('AABB'));
      3: B := TMemoryCardCodec.ChangePin(mcmSle4428,HexToBytes('1234'));
      4: B := TMemoryCardCodec.Verify(mcmSle4442,HexToBytes('1234'));
      5: B := TMemoryCardCodec.ReadCounter(mcmSle4432);
      6: Status := TMemoryCardCodec.DecodeSecurity(mcmSle4442,HexToBytes('FF000000'));
      7: B := TMemoryCardCodec.ReadProtection(mcmI2c1Kbit);
    end; except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected,'Excluded operation accepted');
  end;
  B := HexToBytes('AABBFFFFFFFF'); D := TMemoryCardCodec.DecodeRead(mcmSle4442,amdAcr39,2,B);
  B[0] := 0; Check(BytesToHex(D) = 'AABB','Independent trailer-free read');
  for I := 0 to 1 do
  begin
    Rejected := False;
    try if I = 0 then D := TMemoryCardCodec.DecodeRead(mcmSle4442,amdAcr38Ccid,2,B)
      else D := TMemoryCardCodec.DecodeRead(mcmSle4442,amdAcr39,2,HexToBytes('AABB'));
    except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected,'Read dialect guessed');
  end;
  N := 0; for M := mcmI2c1Kbit to mcmI2c1024Kbit do begin L := TMemoryCardCodec.Layout(M); Check(L.Capacity = 128 shl N,'I2C geometry'); Inc(N); end;
end;

procedure TestWriteFailures;
var I: Integer; S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; Failed: Boolean;
  Data, Pin: TBytes;
begin
  for I := -1 to 8 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
    WriteScript(S); S.FailAt := I; S.EndFails := I = 8;
    Data := HexToBytes('AABBCCDD'); Pin := HexToBytes('123456'); Failed := False;
    try
      try R.WriteMemory(30,Data,Pin);
      except
        on E: EMemoryCardWriteUncertain do
        begin Failed := True; Check(I >= 6,'Uncertainty before write'); Check(E.Verified = (I = 8),'Release evidence'); Check(Pos('Sensitive',E.Message) = 0,'Backend message leaked'); end;
        on E: EMemoryCardAuthenticationError do begin Failed := True; Check(I in [4,5],'Wrong authentication boundary'); end;
        on E: ECardTransportError do begin Failed := True; Check(I < 6,'Mutation failure not marked uncertain'); end;
      end;
      Check(Failed = (I <> -1),'Failure injection missed');
      Check((S.Ends = 1) and not S.Active,'Failed operation release');
      if I >= 0 then Check(S.Position = I + 1 - Ord(I = 8),'Failure replay/continued I/O');
      if I = -1 then Complete(S);
      if I = 8 then Check(S.Position = 8,'Release dispatched extra command');
      Check(BytesToHex(Data) = 'AABBCCDD','Caller data changed'); Check(BytesToHex(Pin) = '123456','Caller PIN wiped');
    finally R.Free; T := nil; end;
  end;
end;

procedure TestMutationResponseCorruption;
var S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport;
  I, Index, BitNumber: Integer; Failed: Boolean;
begin
  // Every status bit on the write acknowledgement, and every read-back data bit.
  for I := 0 to 47 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T; WriteScript(S);
    if I < 16 then begin Index := I div 8; BitNumber := I mod 8; S.Steps[6].Response[Index] := S.Steps[6].Response[Index] xor Byte(1 shl BitNumber); end
    else begin Index := (I - 16) div 8; BitNumber := (I - 16) mod 8; S.Steps[7].Response[Index] := S.Steps[7].Response[Index] xor Byte(1 shl BitNumber); end;
    Failed := False;
    try
      try R.WriteMemory(30,HexToBytes('AABBCCDD'),HexToBytes('123456'));
      except on E: EMemoryCardWriteUncertain do begin Failed := True; Check(not E.Verified,'Corruption marked verified'); end; end;
      Check(Failed,'Corrupt mutation accepted'); Check(S.Ends = 1,'Corruption cleanup');
      if I < 16 then Check(S.Position = 7,'Bad write acknowledgement continued') else Check(S.Position = 8,'Read-back was retried');
    finally R.Free; T := nil; end;
  end;
end;

procedure TestAcquisitionRecovery;
var S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; Failed: Boolean; Data: TBytes;
begin
  S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
  S.Add('FFA400000106','9000'); S.Add('FFB0000001','AB9000'); S.BeginFails := True;
  try
    Failed := False; try Data := R.ReadMemory(0,1); except on E: ECardTransportError do Failed := True; end;
    Check(Failed and (S.Position = 0) and (S.Ends = 0),'Failed acquisition grants ownership');
    S.BeginFails := False; Data := R.ReadMemory(0,1);
    Check(BytesToHex(Data) = 'AB','Acquisition failure poisoned component forever');
    Check((S.Begins = 2) and (S.Ends = 1),'Acquisition recovery lifetime');
  finally R.Free; T := nil; end;
end;

procedure TestSnapshot;
var S: TScript; T: ICardTransport; R: TMemoryCardReaderWriter; Snapshot: TMemoryCardSnapshot;
  I: Integer; Bytes: string;
begin
  S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T; R.Dialect := amdAcr39;
  S.Add('FFA400000106','9000'); Bytes := ''; for I := 0 to 127 do Bytes := Bytes + IntToHex(I,2);
  S.Add('FFB0000080',Bytes + 'FFFFFFFF9000'); S.Add('FFB0008080',Bytes + 'FFFFFFFF9000');
  S.Add('FFB2000004','FFFFFFFF9000'); S.Add('FFB1000004','030000009000');
  try
    Snapshot := R.ReadSnapshot; Complete(S);
    Check(Length(Snapshot.Data) = 256,'Snapshot capacity'); Check(Snapshot.Data[127] = 127,'Snapshot order');
    Check(Snapshot.Data[128] = 0,'Snapshot concatenation'); Check(Length(Snapshot.Protection) = 4,'Protection separated');
    Check(Snapshot.HasSecurity and (Snapshot.Security.RemainingAttempts = 2),'Retry bitmap count');
    S.Steps[1].Response[0] := $FF; Check(Snapshot.Data[0] = 0,'Snapshot aliased transport');
  finally R.Free; T := nil; end;
end;

procedure TestAuthenticationAndPreflight;
var I: Integer; S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; Failed: Boolean;
  Status: TMemoryCardSecurityStatus; B: TBare;
begin
  for I := 0 to 6 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
    S.Add('FFA400000106','9000');
    if I = 0 then S.Add('FFB1000004','000000009000')
    else if I = 1 then begin R.MinimumPinAttempts := 2; S.Add('FFB1000004','010000009000'); end
    else
    begin
      S.Add('FFB1000004','070000009000');
      case I of
        2: S.Add('FF20000003123456','9000');
        3: S.Add('FF20000003123456','9003');
        4: S.Add('FF20000003123456','009007');
      else
        S.Add('FF20000003123456','9007');
        if I = 5 then S.Add('FFB1000004','030000009000') else S.Add('FFB1000004','070000009000');
      end;
    end;
    Failed := False;
    try
      try Status := R.VerifyPin(HexToBytes('123456'));
      except on E: EMemoryCardError do Failed := True; end;
      Check(Failed = (I <> 6),'PIN accepted without exact proof'); Complete(S);
      if I = 6 then Check(Status.RemainingAttempts = 3,'Verified counter');
    finally R.Free; T := nil; end;
  end;
  B := TBare.Create; T := B; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
  try
    Failed := False; try R.ReadMemory(0,1); except on E: EMemoryCardError do Failed := True; end;
    Check(Failed and (B.Calls = 0),'Bare non-exclusive transport used');
  finally R.Free; T := nil; end;
  S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
  try
    for I := 0 to 2 do
    begin
      Failed := False;
      try case I of
        0: R.WriteMemory(255,HexToBytes('AABB'),HexToBytes('123456'));
        1: R.ChangePin(HexToBytes('1234'),HexToBytes('ABCDEF'));
        2: begin R.Model := mcmSle4428; R.ChangePin(HexToBytes('1234'),HexToBytes('5678')); end;
      end; except on E: EMemoryCardError do Failed := True; end;
      Check(Failed and (S.Begins = 0),'Invalid arguments performed I/O');
    end;
  finally R.Free; T := nil; end;
end;

procedure TestOtherModelsAndPages;
var S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; I: Integer; Protection: string;
begin
  for I := 0 to 3 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
    case I of
      0: begin
        R.Model := mcmSle4428; S.Add('FFA400000105','9000'); S.Add('FFB003FE02','00009000');
        Protection := StringOfChar('F',256); S.Add('FFB2000080',Protection + '9000');
        AddAuthentication(S,False,'1234'); S.Add('FFD003FE02AABB','9000'); S.Add('FFB003FE02','AABB9000');
      end;
      1: begin
        R.Model := mcmSle4432; S.Add('FFA400000106','9000'); S.Add('FFB0002002','00009000');
        S.Add('FFB2000004','FFFFFFFF9000'); S.Add('FFD0002002AABB','9000'); S.Add('FFB0002002','AABB9000');
      end;
      2: begin
        R.Model := mcmI2c1Kbit; S.Add('FFA400000101','9000'); S.Add('FF0100000103','9000');
        S.Add('FFB0000702','00009000'); S.Add('FFD0000701AA','9000'); S.Add('FFB0000701','AA9000');
        S.Add('FFD0000801BB','9000'); S.Add('FFB0000801','BB9000');
      end;
      3: begin
        R.Model := mcmI2c1024Kbit; S.Add('FFA400000102','9000'); S.Add('FF0100000103','9000');
        S.Add('FFB0FFFF01','009000'); S.Add('FFB1000001','009000');
        S.Add('FFD0FFFF01AA','9000'); S.Add('FFB0FFFF01','AA9000');
        S.Add('FFD1000001BB','9000'); S.Add('FFB1000001','BB9000');
      end;
    end;
    try
      case I of
        0: R.WriteMemory(1022,HexToBytes('AABB'),HexToBytes('1234'));
        1: R.WriteMemory(32,HexToBytes('AABB'),nil);
        2: R.WriteMemory(7,HexToBytes('AABB'),nil);
        3: R.WriteMemory(65535,HexToBytes('AABB'),nil);
      end; Complete(S);
    finally R.Free; T := nil; end;
  end;
end;

procedure TestChangePin;
var S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; I: Integer; Failed: Boolean;
begin
  for I := -1 to 8 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
    S.Add('FFA400000106','9000'); AddAuthentication(S,True,'123456');
    S.Add('FFD2000103ABCDEF','9000'); S.Add('FFA400000106','9000'); AddAuthentication(S,True,'ABCDEF');
    S.FailAt := I; Failed := False;
    try
      try R.ChangePin(HexToBytes('123456'),HexToBytes('ABCDEF'));
      except
        on E: EMemoryCardWriteUncertain do begin Failed := True; Check(I >= 4,'PIN change dispatch boundary'); end;
        on E: EMemoryCardError do begin Failed := True; Check(I < 4,'Changed PIN uncertainty lost'); end;
        on E: ECardTransportError do begin Failed := True; Check(I < 4,'Changed PIN transport uncertainty lost'); end;
      end;
      Check(Failed = (I <> -1),'PIN change failure missed');
      if I = -1 then Complete(S) else Check(S.Position = I + 1,'PIN change retry/fallback');
      Check(S.Ends = 1,'PIN change cleanup');
    finally R.Free; T := nil; end;
  end;
end;

procedure TestProtectionAndNoop;
var S: TScript; R: TMemoryCardReaderWriter; T: ICardTransport; I: Integer; Failed: Boolean; Pin: TBytes;
begin
  for I := 0 to 4 do
  begin
    S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T; R.Model := mcmSle4432;
    S.Add('FFA400000106','9000'); S.Add('FFB0000102','12349000');
    if I = 0 then S.Add('FFB2000004','F9FFFFFF9000')
    else if I = 1 then S.Add('FFB2000004','F9FFFFFF9000')
    else
    begin
      S.Add('FFB2000004','FFFFFFFF9000'); S.Add('FFD10001021234','9000');
      if I = 3 then S.Add('FFB2000004','FFFFFFFF9000')
      else begin S.Add('FFB2000004','F9FFFFFF9000'); S.Add('FFB0000102','12349000'); end;
    end;
    if I = 4 then S.EndFails := True;
    Failed := False;
    try
      try if I = 1 then R.WriteMemory(1,HexToBytes('FFFF'),nil) else R.ProtectMemory(1,HexToBytes('1234'),nil);
      except
        on E: EMemoryCardWriteUncertain do begin Failed := True; Check(I in [3,4],'Protection uncertainty'); Check(E.Verified = (I = 4),'Protection cleanup evidence'); end;
        on E: EMemoryCardError do begin Failed := True; Check(I = 1,'Unexpected protection preflight'); end;
      end;
      Check(Failed = (I in [1,3,4]),'Protection result'); Complete(S);
    finally R.Free; T := nil; end;
  end;
  S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T;
  S.Add('FFA400000106','9000'); S.Add('FFB0002002','AABB9000');
  try R.WriteMemory(32,HexToBytes('AABB'),HexToBytes('000000')); Complete(S);
  finally R.Free; T := nil; end;
  S := TScript.Create; T := S; R := TMemoryCardReaderWriter.Create(nil); R.Transport := T; WriteScript(S);
  Pin := HexToBytes('123456'); S.MutatePin := Pin;
  try R.WriteMemory(30,HexToBytes('AABBCCDD'),Pin); Complete(S); Check(Pin[0] = $EE,'Mutation fixture did not execute');
  finally R.Free; T := nil; end;
end;

begin
  try
    TestGeometryAndCodecs; TestSnapshot; TestWriteFailures; TestAuthenticationAndPreflight;
    TestOtherModelsAndPages; TestChangePin; TestProtectionAndNoop;
    TestMutationResponseCorruption; TestAcquisitionRecovery;
    Writeln('PASS: ',Checks,' memory-card assertions across nine groups.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
