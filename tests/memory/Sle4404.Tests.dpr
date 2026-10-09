program Sle4404Tests;

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
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Memory, ERD.Card.Memory.Counter,
  ERD.Card.Memory.Capabilities, ERD.Card.Memory.Sle4404;

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

procedure Configure(const C: TSle4404CardReaderWriter);
var L: TSle4404AccessLayout;
begin
  C.ReadableBytes := 64; L := C.Layout;
  L.UserCounterAddress := 10; L.UserCounterMask := $0F;
  L.MemoryCounterAddress := 44; L.ScratchPadAddress := 2; L.ScratchPadBytes := 4;
  L.ApplicationAddress := 12; L.ApplicationBytes := 4; C.Layout := L;
end;

procedure AddUser(const S: TScript; const BeforeCounter: string = 'FF'; const AfterCounter: string = 'FF');
begin
  S.Add('FFB0000A01',BeforeCounter + '9000');
  S.Add('FF200408021234','9000'); S.Add('FFB0000A01',AfterCounter + '9000');
end;

procedure AddProgram(const S: TScript; const WithCode: Boolean);
begin
  S.Add('FFA400000108','9000'); if WithCode then AddUser(S);
  S.Add('FFB0000C04','FFFFFFFF9000'); S.Add('FFD0000C047FFEEF00','9000');
  S.Add('FFB0000C04','7FFEEF009000');
end;

procedure AddScratch(const S: TScript);
begin
  S.Add('FFA400000108','9000'); S.Add('FFB0000204','000000009000');
  S.Add('FFD2000200','9000'); S.Add('FFB0000204','FFFFFFFF9000');
end;

procedure AddApplication(const S: TScript);
begin
  S.Add('FFA400000108','9000'); S.Add('FFB0002C08','FFFFFFFFFFFFFFFF9000');
  AddUser(S); S.Add('FFB0000C04','000000009000');
  S.Add('FF2040280456789ABC','9000'); S.Add('FFB0000C04','FFFFFFFF9000');
end;

procedure TestCodecs;
var A, N: Integer; B: TBytes; Rejected: Boolean;
begin
  Check(BytesToHex(TSle4404Codec.Select) = 'FFA400000108','Selector');
  Check(BytesToHex(TSle4404Codec.UserCode(HexToBytes('1234'))) = 'FF200408021234','User code literal');
  Check(BytesToHex(TSle4404Codec.MemoryCode(HexToBytes('56789ABC'))) = 'FF2040280456789ABC','Memory code literal');
  Check(BytesToHex(TSle4404Codec.EraseScratchPad(2)) = 'FFD2000200','Scratch erase literal');
  Check(BytesToHex(TSle4404Codec.ProgramCommand(12,HexToBytes('01020304'))) = 'FFD0000C0401020304','Program literal');
  for A := 0 to 255 do
    for N := 1 to 128 do
    begin
      Rejected := False;
      try B := TSle4404Codec.Read(A,N); except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected = (N > 256 - A),'Codec boundary');
      if not Rejected then Check((B[3] = A) and (B[4] = N),'Reader address/count');
    end;
end;

procedure TestPublicAndProtected;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter; B, Pin: TBytes;
  Status: TMemoryCardSecurityStatus;
begin
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    Configure(C); C.Transport := T;
    S.Add('FFA400000108','9000'); S.Add('FFB0000C04','010203049000');
    B := C.ReadMemory(12,4,nil); Check(BytesToHex(B) = '01020304','Public read');
    B[0] := 0; Check(S.Steps[1].Response[0] = 1,'Independent bytes'); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    Configure(C); C.Transport := T; S.Add('FFA400000108','9000'); AddUser(S,'F3');
    Pin := HexToBytes('1234'); S.MutatePin := Pin;
    Status := C.VerifyUserCode(Pin);
    Check((Status.Counter = $FF) and (Status.RemainingAttempts = 4) and not Status.Blocked,'Counter proof');
    Check(Pin[0] = $EE,'Caller mutation was not exercised'); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    Configure(C); C.Transport := T; S.Add('FFA400000108','9000'); AddUser(S);
    S.Add('FFB0000C04','ABCD01239000');
    B := C.ReadMemory(12,4,HexToBytes('1234')); Check(BytesToHex(B) = 'ABCD0123','Protected read'); Complete(S);
  finally C.Free; T := nil; end;
end;

procedure TestAuthenticationFailures;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter;
  I, ExpectedCalls: Integer; Rejected: Boolean; Status: TMemoryCardSecurityStatus;
begin
  for I := 0 to 5 do
  begin
    S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
    try
      Configure(C); C.Transport := T; S.Add('FFA400000108','9000'); AddUser(S);
      ExpectedCalls := 4;
      case I of
        0: begin S.Steps[1].Response := HexToBytes('F09000'); ExpectedCalls := 2; end;
        1: begin S.Steps[1].Response := HexToBytes('F19000'); C.MinimumUserCodeAttempts := 2; ExpectedCalls := 2; end;
        2: begin S.Steps[2].Response := HexToBytes('6300'); ExpectedCalls := 3; end;
        3: S.Steps[3].Response := HexToBytes('FE9000');
        4: begin S.FailAt := 2; ExpectedCalls := 3; end;
        5: S.EndFails := True;
      end;
      Rejected := False;
      try Status := C.VerifyUserCode(HexToBytes('1234'));
      except
        on E: EMemoryCardAuthenticationError do
        begin Check(I >= 2,'Pre-dispatch budget became authentication uncertainty');
          Check(Pos('Sensitive',E.Message) = 0,'Credential-bearing backend text leaked'); Rejected := True; end;
        on E: EMemoryCardError do begin Check(I < 2,'Dispatched code failure not typed'); Rejected := True; end;
      end;
      Check(Rejected and (S.Position = ExpectedCalls) and (S.Ends = 1),'Retry/release boundary');
    finally C.Free; T := nil; end;
  end;
end;

procedure TestMutations;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter; I: Integer;
begin
  for I := 0 to 3 do
  begin
    S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
    try
      Configure(C); C.Transport := T;
      case I of
        0: begin AddProgram(S,False); C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('7FFEEF00'),nil); end;
        1: begin AddProgram(S,True); C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('7FFEEF00'),HexToBytes('1234')); end;
        2: begin AddScratch(S); C.EraseScratchPad(HexToBytes('00000000'),nil); end;
        3: begin AddApplication(S); C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC')); end;
      end;
      Complete(S);
    finally C.Free; T := nil; end;
  end;
end;

procedure TestMutationFailures;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter;
  Kind, I, MaxStep, Dispatch: Integer; Rejected, Uncertain: Boolean;
begin
  for Kind := 0 to 2 do
  begin
    MaxStep := 3; Dispatch := 2; if Kind = 2 then begin MaxStep := 7; Dispatch := 6; end;
    for I := 0 to MaxStep do
    begin
      S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
      try
        Configure(C); C.Transport := T;
        case Kind of 0: AddProgram(S,False); 1: AddScratch(S); 2: AddApplication(S); end;
        S.FailAt := I; Rejected := False; Uncertain := False;
        try
          case Kind of
            0: C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('7FFEEF00'),nil);
            1: C.EraseScratchPad(HexToBytes('00000000'),nil);
            2: C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC'));
          end;
        except
          on E: EMemoryCardWriteUncertain do
          begin Rejected := True; Uncertain := True; Check(not E.Verified,'Unproven mutation marked verified'); end;
          on E: EMemoryCardAuthenticationError do Rejected := True;
          on E: ECardTransportError do Rejected := True;
        end;
        Check(Rejected and (Uncertain = (I >= Dispatch)),'Mutation dispatch boundary');
        Check((S.Position = I + 1) and (S.Ends = 1),'Unexpected replay/release');
      finally C.Free; T := nil; end;
    end;
    S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
    try
      Configure(C); C.Transport := T;
      case Kind of 0: AddProgram(S,False); 1: AddScratch(S); 2: AddApplication(S); end;
      S.EndFails := True; Rejected := False;
      try
        case Kind of
          0: C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('7FFEEF00'),nil);
          1: C.EraseScratchPad(HexToBytes('00000000'),nil);
          2: C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC'));
        end;
      except on E: EMemoryCardWriteUncertain do Rejected := E.Verified; end;
      Check(Rejected,'Cleanup lost read-back proof'); Complete(S);
    finally C.Free; T := nil; end;
  end;
end;

procedure TestProofCorruptionAndBudgets;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter;
  I, Kind: Integer; Rejected: Boolean;
begin
  for Kind := 0 to 2 do
    for I := 0 to 31 do
    begin
      S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
      try
        Configure(C); C.Transport := T;
        case Kind of 0: AddProgram(S,False); 1: AddScratch(S); 2: AddApplication(S); end;
        S.Steps[High(S.Steps)].Response[I div 8] :=
          S.Steps[High(S.Steps)].Response[I div 8] xor Byte(1 shl (I mod 8));
        Rejected := False;
        try
          case Kind of
            0: C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('7FFEEF00'),nil);
            1: C.EraseScratchPad(HexToBytes('00000000'),nil);
            2: C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC'));
          end;
        except on E: EMemoryCardWriteUncertain do Rejected := not E.Verified; end;
        Check(Rejected,'Corrupted area proof accepted'); Complete(S);
      finally C.Free; T := nil; end;
    end;
  for I := 0 to 3 do
  begin
    S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
    try
      Configure(C); C.Transport := T; AddApplication(S);
      case I of
        0: S.Steps[1].Response := HexToBytes('00000000000000009000');
        1: begin S.Steps[1].Response := HexToBytes('01000000000000009000'); C.MinimumMemoryCodeAttempts := 2; end;
        2: S.Steps[6].Response := HexToBytes('6300');
        3: S.Steps[5].Response := HexToBytes('FFFFFFFF9000');
      end;
      Rejected := False;
      try C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC'));
      except
        on E: EMemoryCardWriteUncertain do begin Rejected := True; Check(I = 2,'Pre-dispatch failure treated as erase dispatch'); end;
        on E: EMemoryCardError do begin Rejected := True; Check(I <> 2,'Dispatched memory code failure not uncertain'); end;
      end;
      Check(Rejected and (S.Ends = 1),'Memory budget/stale state accepted');
      case I of
        0,1: Check(S.Position = 2,'Memory budget consumed a user-code attempt');
        2: Check(S.Position = 7,'Rejected memory code replayed');
        3: Check(S.Position = 6,'Already-erased actual area presented memory code');
      end;
    finally C.Free; T := nil; end;
  end;
end;

procedure TestChunkingAndOwnership;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter;
  Before, Data, UserCode, MemoryCode, B: TBytes;
begin
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    C.ReadableBytes := 256; C.Transport := T;
    Before := HexToBytes(StringOfChar('F',512)); Data := CopyBytes(Before);
    Data[127] := $7F; Data[128] := $7F;
    S.Add('FFA400000108','9000');
    S.Add('FFB0000080',StringOfChar('F',256) + '9000');
    S.Add('FFB0008080',StringOfChar('F',256) + '9000');
    S.Add('FFD0000080' + StringOfChar('F',254) + '7F','9000');
    S.Add('FFB0000080',StringOfChar('F',254) + '7F9000');
    S.Add('FFD0008080' + '7F' + StringOfChar('F',254),'9000');
    S.Add('FFB0008080','7F' + StringOfChar('F',254) + '9000');
    S.MutatePin := Data;
    C.ProgramMemory(0,Before,Data,nil);
    Check((Data[0] = $EE) and (Before[0] = $FF),'Owned chunk copies/caller preservation'); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    Configure(C); C.Transport := T; AddApplication(S);
    UserCode := HexToBytes('1234'); MemoryCode := HexToBytes('56789ABC');
    S.MutatePin := MemoryCode;
    C.EraseApplication(HexToBytes('00000000'),UserCode,MemoryCode);
    Check((BytesToHex(UserCode) = '1234') and (MemoryCode[0] = $EE),'Caller code arrays overwritten by local cleanup'); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    C.ReadableBytes := 256; C.Transport := T;
    S.Add('FFA400000108','9000'); S.Add('FFB0000080',StringOfChar('F',256) + '9000');
    S.Add('FFB0008080',StringOfChar('0',256) + '9000');
    B := C.ReadMemory(0,256,nil);
    Check((Length(B) = 256) and (B[127] = $FF) and (B[128] = 0),'Chunked public read'); Complete(S);
  finally C.Free; T := nil; end;
end;

procedure TestInvalidAndNoops;
var S: TScript; T: ICardTransport; C: TSle4404CardReaderWriter;
  L: TSle4404AccessLayout; B: TBytes; Rejected: Boolean; I: Integer;
begin
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    C.Transport := T; Rejected := False;
    try B := C.ReadMemory(0,1,nil); except on E: EMemoryCardError do Rejected := True; end;
    Check(Rejected and (S.Begins = 0),'Guessed window'); Configure(C);
    for I := 0 to 5 do
    begin
      Rejected := False;
      try
        case I of
          0: C.ProgramMemory(12,HexToBytes('00'),HexToBytes('FF'),nil);
          1: C.EraseApplication(HexToBytes('FFFFFFFF'),HexToBytes('1234'),HexToBytes('56789ABC'));
          2: C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56'));
          3: begin L := C.Layout; L.UserCounterMask := $1F; C.Layout := L; C.VerifyUserCode(HexToBytes('1234')); end;
          4: begin Configure(C); L := C.Layout; L.ApplicationAddress := 8; C.Layout := L;
                   C.EraseApplication(HexToBytes('00000000'),HexToBytes('1234'),HexToBytes('56789ABC')); end;
          5: begin Configure(C); C.ProgramMemory(63,HexToBytes('FFFF'),HexToBytes('0000'),nil); end;
        end;
      except on E: EMemoryCardError do Rejected := True; end;
      Check(Rejected and (S.Begins = 0),'Invalid request touched hardware');
    end;
    Configure(C); S.Add('FFA400000108','9000'); S.Add('FFB0000204','FFFFFFFF9000');
    C.EraseScratchPad(HexToBytes('FFFFFFFF'),nil); Complete(S);
  finally C.Free; T := nil; end;
  S := TScript.Create; T := S; C := TSle4404CardReaderWriter.Create(nil);
  try
    Configure(C); C.Transport := T; S.Add('FFA400000108','9000'); S.Add('FFB0000C04','FFFFFFFF9000');
    C.ProgramMemory(12,HexToBytes('FFFFFFFF'),HexToBytes('FFFFFFFF'),nil); Complete(S);
  finally C.Free; T := nil; end;
end;

begin
  try
    TestCodecs; TestPublicAndProtected; TestAuthenticationFailures; TestMutations;
    TestMutationFailures; TestProofCorruptionAndBudgets; TestChunkingAndOwnership; TestInvalidAndNoops;
    Writeln('PASS: ',Checks,' SLE4404 assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
