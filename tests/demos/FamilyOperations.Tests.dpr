program FamilyOperationsTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF UNIX}
  cthreads,
{$ENDIF}
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Demo.Job, ERD.Card.Demo.Families,
  ERD.Card.Demo.FamilyOperations, ERD.Card.Reader.TWN4, ERD.Card.RFID.Input,
  ERD.Card.Memory, ERD.Card.Demo.Operations;

type
  EReachedHardware = class(Exception);
  TStep = record Command, Response: TBytes; end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends, FailAt: Integer;
    Active, EndFails: Boolean;
    constructor Create;
    procedure Add(const Command, Response: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const Command: TBytes): TBytes;
  end;
  TChannel = class(TInterfacedObject, ITwn4ByteChannel)
  public
    Steps: array of TStep;
    Position, Offset, Opens, Closes: Integer;
    Active, FailClose: Boolean;
    procedure Add(const Command, Response: string);
    procedure Open;
    procedure Close;
    procedure Send(const B: TBytes; const Timeout: Cardinal);
    function ReceiveByte(const Timeout: Cardinal): Byte;
    function NowMs: UInt64;
  end;
  THardware = class(TInterfacedObject, ICardFamilyHardware)
  public
    Acquires, Releases, Channels: Integer;
    Transport: ICardTransport;
    Channel: ITwn4ByteChannel;
    FailRelease: Boolean;
    function AcquireReader(const AName: string): ICardTransport;
    procedure ReleaseReader;
    function CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
  end;

var Checks: Integer;
procedure Check(const V: Boolean; const Why: string);
begin Inc(Checks); if not V then raise Exception.Create(Why); end;

constructor TScript.Create;
begin inherited Create; FailAt := -1; end;
procedure TScript.Add(const Command, Response: string);
var N: Integer;
begin N := Length(Steps); SetLength(Steps,N+1); Steps[N].Command := HexToBytes(Command); Steps[N].Response := HexToBytes(Response); end;
procedure TScript.BeginTransaction;
begin Check(not Active,'No nested transaction'); Inc(Begins); Active := True; end;
procedure TScript.EndTransaction;
begin Check(Active,'Only acquired release'); Inc(Ends); Active := False;
  if EndFails then raise ECardTransportError.Create('Sensitive cleanup'); end;
function TScript.Exchange(const Command: TBytes): TBytes;
var N: Integer;
begin
  Check(Active,'Exclusive commands'); N := Position; Inc(Position);
  Check(N < Length(Steps),'No extra/replayed command');
  Check(BytesEqual(Command,Steps[N].Command),'Literal command transcript');
  if N = FailAt then raise ECardTransportError.Create('Sensitive backend message');
  Result := CopyBytes(Steps[N].Response);
end;
function THardware.AcquireReader(const AName: string): ICardTransport;
begin Inc(Acquires); Check(AName = 'Exact test reader','Exact reader passed');
  if Transport = nil then raise EReachedHardware.Create('Reached'); Result := Transport; end;
procedure THardware.ReleaseReader;
begin Inc(Releases); if FailRelease then raise ECardTransportError.Create('Sensitive connection cleanup'); end;
function THardware.CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
begin Result := nil; Inc(Channels); Check(APort = 'COM87','Exact port passed'); if Channel = nil then raise EReachedHardware.Create('Reached'); Result := Channel; end;

function Ascii(const S: string): TBytes;
var I: Integer;
begin Result := nil; SetLength(Result,Length(S)); for I := 1 to Length(S) do Result[I-1] := Ord(S[I]); end;
procedure TChannel.Add(const Command, Response: string);
var N: Integer;
begin N := Length(Steps); SetLength(Steps,N+1); Steps[N].Command := Ascii(Command+#13); Steps[N].Response := Ascii(Response+#13); end;
procedure TChannel.Open;
begin Check(not Active,'Exclusive CDC open'); Inc(Opens); Active := True; end;
procedure TChannel.Close;
begin Check(Active,'Owned CDC close'); Inc(Closes); Active := False;
  if FailClose then raise Exception.Create('Sensitive CDC cleanup'); end;
procedure TChannel.Send(const B: TBytes; const Timeout: Cardinal);
begin
  Check(Active and (Timeout > 0),'CDC bounded I/O');
  Check((Position < Length(Steps)) and (Offset = 0),'No CDC replay');
  Check(BytesEqual(B,Steps[Position].Command),'Literal CDC request');
end;
function TChannel.ReceiveByte(const Timeout: Cardinal): Byte;
begin
  Check(Active and (Timeout > 0),'CDC bounded response');
  Check((Position < Length(Steps)) and (Offset < Length(Steps[Position].Response)),'Complete CDC response');
  Result := Steps[Position].Response[Offset]; Inc(Offset);
  if Offset = Length(Steps[Position].Response) then begin Offset := 0; Inc(Position); end;
end;
function TChannel.NowMs: UInt64;
begin Result := 0; end;

procedure Put(var R: TCardDemoRequest; const F: TCardDemoFamily; const Name, Value: string);
var A: TCardFamilyActions; I: Integer;
begin
  A := CardFamilyActions(F);
  for I := 0 to High(A[R.FamilyAction].Fields) do
    if A[R.FamilyAction].Fields[I].Name = Name then
    begin
      if A[R.FamilyAction].Fields[I].Secret then R.Credentials[I] := HexToBytes(Value)
      else R.Arguments[I] := UnicodeString(Value);
      Exit;
    end;
end;

function Request(const F: TCardDemoFamily; const ActionId: string): TCardDemoRequest;
var A: TCardFamilyActions; I, J: Integer;
begin
  Result := Default(TCardDemoRequest); Result.Operation := cdoFamily;
  Result.FamilyName := CardFamilyName(F); Result.ReaderName := 'Exact test reader';
  Result.MutationAcknowledged := True; A := CardFamilyActions(F); J := -1;
  for I := 0 to High(A) do if A[I].Id = ActionId then J := I;
  Check(J >= 0,'Action exists'); Result.FamilyAction := J;
  SetLength(Result.Arguments,Length(A[J].Fields)); SetLength(Result.Credentials,Length(A[J].Fields));
  for I := 0 to High(A[J].Fields) do
  begin Result.Arguments[I] := A[J].Fields[I].DefaultText;
    if A[J].Fields[I].Choices <> '' then Result.Arguments[I] := '0'; end;
  Put(Result,F,'model','1'); Put(Result,F,'dialect','0'); Put(Result,F,'pin','123456');
  Put(Result,F,'newpin','654321'); Put(Result,F,'address','0'); Put(Result,F,'count','1');
  Put(Result,F,'before','F0'); Put(Result,F,'data','E0'); Put(Result,F,'page','0');
  Put(Result,F,'countermodel','1'); Put(Result,F,'window','1'); Put(Result,F,'value','E0');
  Put(Result,F,'after','E0'); Put(Result,F,'keyselect','00'); Put(Result,F,'clocks','01');
  Put(Result,F,'challenge','000102030405'); Put(Result,F,'code','123456');
  if F = dfSle4404 then
  begin
    Put(Result,F,'window','64'); Put(Result,F,'pin','1234'); Put(Result,F,'usercounter','0');
    Put(Result,F,'usermask','0F'); Put(Result,F,'address','16');
    Put(Result,F,'scratchaddress','16'); Put(Result,F,'scratchbytes','4');
    Put(Result,F,'applicationaddress','48'); Put(Result,F,'applicationbytes','4');
    Put(Result,F,'memorycounter','32'); Put(Result,F,'memorycode','01020304');
    if (ActionId = 'scratch') or (ActionId = 'application') then Put(Result,F,'before','F0F0F0F0');
  end;
  if F = dfTwn4 then
  begin
    Put(Result,F,'port','COM87'); Put(Result,F,'classicmodel','1'); Put(Result,F,'block','1');
    Put(Result,F,'sector','0'); Put(Result,F,'key','010203040506'); Put(Result,F,'id','01020304');
    Put(Result,F,'before','00000000000000000000000000000000');
    Put(Result,F,'data','0102030405060708090A0B0C0D0E0F10');
    if (ActionId = 'type2read') or (ActionId = 'type2write') then
    begin Put(Result,F,'page','4'); Put(Result,F,'id','01020304050607');
      Put(Result,F,'before','00000000'); Put(Result,F,'data','01020304'); end;
  end;
end;

procedure TestOffline;
var R: TCardDemoRequest; D: TCardDemoResult; O: ICardDemoOperations; K: TRfidKeyboardReader; Rejected: Boolean;
begin
  O := CreateCardFamilyOperations(dfTools);
  R := Request(dfTools,'apdu'); O.Run(R,D); Check(Pos('00A4040000',string(D.Text)) > 0,'APDU roundtrip');
  R := Request(dfTools,'response'); O.Run(R,D); Check(Pos('01029000',string(D.Text)) > 0,'APDU response roundtrip');
  R := Request(dfTools,'atr'); O.Run(R,D); Check(Pos('Validated ATR: 3B00',string(D.Text)) > 0,'ATR decoder');
  R := Request(dfTools,'tlv'); O.Run(R,D); Check(Pos('5A021234',string(D.Text)) > 0,'TLV roundtrip');
  R := Request(dfTools,'ndef'); O.Run(R,D); Check(Pos('D101055402656E4869',string(D.Text)) > 0,'NDEF roundtrip');
  R := Request(dfTools,'tag'); O.Run(R,D); Check(Pos('PAN',string(D.Text)) > 0,'EMV tag catalog');
  R := Request(dfMemory,'capabilities'); Rejected := False;
  try CreateCardDemoOperations.Run(R,D); except on E: EArgumentException do Rejected := True; end;
  Check(Rejected,'Legacy executor refuses a family action before hardware');
  R := Request(dfMemory,'capabilities'); CreateCardFamilyOperations(dfMemory).Run(R,D);
  Check(Pos('SLE4442',string(D.Text)) > 0,'Memory capability catalog');
  R := Request(dfCounter,'codeframe'); CreateCardFamilyOperations(dfCounter).Run(R,D);
  Check((Pos('9 bytes',string(D.Text)) > 0) and (Pos('123456',string(D.Text)) = 0),'Credential command not displayed');
  R := Request(dfRfid,'text'); Put(R,dfRfid,'encoding','2'); Put(R,dfRfid,'width','4');
  CreateCardFamilyOperations(dfRfid).Run(R,D); Check(Pos('000004D2',string(D.Text)) > 0,'Explicit decimal conversion');
  R := Request(dfRfid,'reports'); Put(R,dfRfid,'reports','00001E0000000000;0000000000000000;0000280000000000');
  CreateCardFamilyOperations(dfRfid).Run(R,D); Check(Pos('Completed frames: 1',string(D.Text)) > 0,'Boot reports complete frame');
  Put(R,dfRfid,'kind','2'); Put(R,dfRfid,'reportbytes','4'); Put(R,dfRfid,'fieldbytes','4'); Put(R,dfRfid,'reports','30303100');
  CreateCardFamilyOperations(dfRfid).Run(R,D); Check(Pos('001',string(D.Text)) > 0,'Fixed ASCII report');
  R := Request(dfRfid,'keyboard'); K := CreateCardFamilyRfidCapture(R);
  try Check(not K.Active,'Factory inactive'); K.Start;
    Check(not K.FeedCharacter('1',0),'Partial scan withheld');
    Check(K.FeedCharacter(#13,1),'Complete scan'); Check(K.LastIdentifier.Text = '1','Owned scan');
  finally K.Free; end;
end;

procedure TestPreflight;
var F: TCardDemoFamily; A: TCardFamilyActions; I,J: Integer; R: TCardDemoRequest;
  D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware; O: ICardDemoOperations;
  Reached, Rejected: Boolean; Prev: Integer;
begin
  for F := dfMemory to dfTwn4 do
  begin
    A := CardFamilyActions(F); H := THardware.Create; Hardware := H;
    O := CreateCardFamilyOperations(F,Hardware);
    for I := 0 to High(A) do
      if A[I].Pcsc or (F = dfTwn4) then
      begin
        R := Request(F,A[I].Id); Reached := False;
        try O.Run(R,D); except on E: EReachedHardware do Reached := True; end;
        Check(Reached,'Valid action did not reach acquisition: ' + A[I].Id);
        Check(H.Releases = 0,'Failed acquisition must not release');
        if A[I].Mutation then
        begin
          Prev := H.Acquires + H.Channels; R.MutationAcknowledged := False; Rejected := False;
          try O.Run(R,D); except on E: EArgumentException do Rejected := True; end;
          Check(Rejected and (Prev = H.Acquires + H.Channels),'Acknowledgement before I/O'); R.MutationAcknowledged := True;
        end;
        for J := 0 to High(A[I].Fields) do
          if A[I].Fields[J].Choices <> '' then
          begin
            R := Request(F,A[I].Id); R.Arguments[J] := '-1'; Prev := H.Acquires + H.Channels; Rejected := False;
            try O.Run(R,D); except on E: EArgumentException do Rejected := True; end;
            Check(Rejected and (Prev = H.Acquires + H.Channels),'Unknown choice before I/O');
          end;
      end;
    O := nil; Hardware := nil;
  end;
  H := THardware.Create; Hardware := H; O := CreateCardFamilyOperations(dfMemory,Hardware);
  R := Request(dfMemory,'write'); Put(R,dfMemory,'pin','00'); Rejected := False;
  try O.Run(R,D); except on E: EMemoryCardError do Rejected := True; end;
  Check(Rejected and (H.Acquires = 0),'Exact PIN length preflight');
  R := Request(dfMemory,'protect'); Put(R,dfMemory,'before',''); Rejected := False;
  try O.Run(R,D); except on E: EMemoryCardError do Rejected := True; end;
  Check(Rejected and (H.Acquires = 0),'Expected protection range preflight');
  R := Request(dfMemory,'verify'); R.Arguments[2] := '123456'; Rejected := False;
  try O.Run(R,D); except on E: EArgumentException do Rejected := True; end;
  Check(Rejected and (H.Acquires = 0),'Credentials refused in public arguments');
end;

procedure TestMemoryWrite(const FailAt: Integer; const FailEnd, FailRelease: Boolean);
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware;
  S: TScript; T: ICardTransport; O: ICardDemoOperations; Failed: Boolean;
begin
  S := TScript.Create; T := S; S.FailAt := FailAt; S.EndFails := FailEnd;
  S.Add('FFA400000106','9000'); S.Add('FFB0000001','F09000'); S.Add('FFB2000004','FFFFFFFF9000');
  S.Add('FFB1000004','070000009000'); S.Add('FF20000003123456','9007'); S.Add('FFB1000004','070000009000');
  S.Add('FFD0000001E0','9000'); S.Add('FFB0000001','E09000');
  H := THardware.Create; Hardware := H; H.Transport := T; H.FailRelease := FailRelease;
  O := CreateCardFamilyOperations(dfMemory,Hardware); R := Request(dfMemory,'write'); Failed := False;
  try O.Run(R,D); except on E: Exception do Failed := True; end;
  Check(Failed = ((FailAt >= 0) or FailEnd or FailRelease),'Correct completion state');
  Check((H.Acquires = 1) and (H.Releases = 1),'Exact acquired lifetime');
  Check((S.Begins = 1) and (S.Ends = 1) and not S.Active,'One transaction, no preflight I/O');
  Check(D.WriteUncertain = Failed,'Uncertainty retained');
  Check(D.WriteVerified = (FailAt < 0),'Read-back evidence retained across cleanup failure');
  Check(BytesToHex(R.Credentials[4]) = '123456','Caller credentials preserved');
  if FailAt < 0 then Check(S.Position = 8,'Complete literal transcript')
  else Check(S.Position = FailAt + 1,'Failure never retried');
end;

procedure TestCounterAndSleRoutes;
var F: TCardDemoFamily; I: Integer; S: TScript; T: ICardTransport; H: THardware;
  Hardware: ICardFamilyHardware; R: TCardDemoRequest; D: TCardDemoResult;
begin
  for I := 0 to 3 do
  begin
    S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
    if I < 2 then F := dfCounter else F := dfSle4404;
    case I of
      0: begin R := Request(F,'write');
        S.Add('FFA400000107','9000'); S.Add('FFB0000001','F09000');
        S.Add('FFD000000200E0','9000'); S.Add('FFB0000001','E09000'); end;
      1: begin R := Request(F,'certificate');
        S.Add('FFA400000107','9000'); S.Add('FF840000080001000102030405','6102'); S.Add('FFC0000002','12349000'); end;
      2: begin R := Request(F,'read'); Put(R,F,'pin','');
        S.Add('FFA400000108','9000'); S.Add('FFB0001001','F09000'); end;
      3: begin R := Request(F,'program');
        S.Add('FFA400000108','9000'); S.Add('FFB0000001','FF9000');
        S.Add('FF200408021234','9000'); S.Add('FFB0000001','FF9000');
        S.Add('FFB0001001','F09000'); S.Add('FFD0001001E0','9000'); S.Add('FFB0001001','E09000'); end;
    end;
    CreateCardFamilyOperations(F,Hardware).Run(R,D);
    Check(D.Success and (S.Position = Length(S.Steps)),'Complete family transcript');
    Check((H.Acquires = 1) and (H.Releases = 1) and (S.Begins = 1) and (S.Ends = 1),'Family operation lifetime');
    if I in [0,3] then Check(D.WriteVerified,'Family write proof')
    else if I = 1 then Check(Pos('1234',string(D.Text)) > 0,'Raw certificate displayed')
    else Check(D.Text = 'F0','Public SLE4404 range');
    Hardware := nil; T := nil;
  end;
end;

procedure TestTwnRoutes(const Kind: Integer; const FailClose: Boolean);
var C: TChannel; Channel: ITwn4ByteChannel; H: THardware; Hardware: ICardFamilyHardware;
  R: TCardDemoRequest; D: TCardDemoResult; Failed: Boolean;
begin
  C := TChannel.Create; Channel := C; C.FailClose := FailClose;
  H := THardware.Create; Hardware := H; H.Channel := Channel;
  case Kind of
    0: begin R := Request(dfTwn4,'version'); C.Add('00047E','000454574E34'); end;
    1: begin R := Request(dfTwn4,'tag'); C.Add('050010','000180200466CF4DC2'); end;
    2: begin
      R := Request(dfTwn4,'classicread'); Put(R,dfTwn4,'id','66CF4DC2'); Put(R,dfTwn4,'keytype','1');
      C.Add('050010','000180200466CF4DC2'); C.Add('0B000102030405060100','0001');
      C.Add('0B0101','0001000102030405060708090A0B0C0D0E0F');
    end;
    3: begin
      R := Request(dfTwn4,'type2write'); Put(R,dfTwn4,'type2model','3'); Put(R,dfTwn4,'id','04010203040506');
      Put(R,dfTwn4,'before','00010203'); Put(R,dfTwn4,'data','AABBCCDD');
      C.Add('050010','000180380704010203040506'); C.Add('0C0004','000100010203101112132021222330313233');
      C.Add('050010','000180380704010203040506'); C.Add('0C0004','000100010203101112132021222330313233');
      C.Add('0C0104AABBCCDD','0001'); C.Add('0C0004','0001AABBCCDD101112132021222330313233');
    end;
  end;
  C.Add('0501','00'); Failed := False;
  try CreateCardFamilyOperations(dfTwn4,Hardware).Run(R,D);
  except on E: ETwn4WriteUncertain do Failed := True; end;
  Check(Failed = FailClose,'TWN4 cleanup uncertainty');
  Check((H.Channels = 1) and (H.Acquires = 0) and (H.Releases = 0),'CDC separate from PC/SC');
  Check((C.Opens = 1) and (C.Closes = 1) and not C.Active and (C.Position = Length(C.Steps)),'Complete owned CDC transcript');
  if Kind = 0 then Check(D.Text = 'TWN4','Version result')
  else if Kind = 1 then Check(Pos('66CF4DC2',string(D.Text)) > 0,'Tag identity result')
  else if Kind = 2 then Check(D.Text = '000102030405060708090A0B0C0D0E0F','Authenticated Classic data')
  else Check(D.WriteVerified and (D.WriteUncertain = FailClose),'TWN4 proof retained');
end;

procedure TestSimRoutes;
var S: TScript; T: ICardTransport; H: THardware; Hardware: ICardFamilyHardware;
  R: TCardDemoRequest; D: TCardDemoResult; Failed: Boolean; I: Integer;
begin
  R := Request(dfSim,'decode'); Put(R,dfSim,'kind','0'); Put(R,dfSim,'hex','981032547698103254F6');
  CreateCardFamilyOperations(dfSim).Run(R,D); Check(D.Text = '8901234567890123456','Literal offline ICCID');
  R := Request(dfSim,'encodealpha'); Put(R,dfSim,'name','ALICE'); Put(R,dfSim,'width','6');
  CreateCardFamilyOperations(dfSim).Run(R,D); Check(D.Text = '414C494345FF','Literal offline alpha');
  for I := 0 to 2 do
  begin
    S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
    R := Request(dfSim,'iccid');
    if I = 1 then begin R := Request(dfSim,'record'); Put(R,dfSim,'path','7F10/6F3A'); Put(R,dfSim,'pin',''); end;
    if I = 2 then begin R := Request(dfSim,'read'); Put(R,dfSim,'path','3F00/2FE2'); Put(R,dfSim,'pin',''); end;
    if I < 2 then
    begin
      S.Add('A0A40000023F00','000000003F00010000000000090000000200838A838A9000');
      if I = 0 then begin S.Add('A0A40000022FE2','0000000A2FE20400000000010200009000'); S.Add('A0B000000A','981032547698103254F69000'); end
      else begin S.Add('A0A40000027F10','000000007F10020000000000090000000200838A838A9000'); S.Add('A0A40000026F3A','000000146F3A0400000000010201149000'); S.Add('A0B2010414','414C494345FF04912143F5FFFFFFFFFFFFFFFFFF9000'); end;
    end;
    Failed := False;
    try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: Exception do Failed := True; end;
    Check(Failed = (I = 2),'SIM route preflight / success');
    if I = 2 then Check(H.Acquires = 0,'Bad SIM path before hardware')
    else begin Check((S.Position = Length(S.Steps)) and (H.Acquires = 1) and (H.Releases = 1),'SIM complete transcript');
      if I = 0 then Check(D.Text = '8901234567890123456','Live ICCID')
      else Check(D.Text = '414C494345FF04912143F5FFFFFFFFFFFFFFFFFF','Live complete ADN record'); end;
    Hardware := nil; T := nil;
  end;
end;

begin
  try
    TestSimRoutes; TestOffline; TestPreflight; TestCounterAndSleRoutes;
    TestTwnRoutes(0,False); TestTwnRoutes(1,False); TestTwnRoutes(2,False); TestTwnRoutes(3,False); TestTwnRoutes(3,True);
    TestMemoryWrite(-1,False,False); TestMemoryWrite(6,False,False);
    TestMemoryWrite(7,False,False); TestMemoryWrite(-1,True,False); TestMemoryWrite(-1,False,True);
    Writeln('PASS: ',Checks,' family demo assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
