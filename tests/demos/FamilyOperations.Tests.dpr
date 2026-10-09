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
  ERD.Card.HID, ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Demo.Job, ERD.Card.SIM.Data, ERD.Card.Demo.Families,
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
  THardware = class(TInterfacedObject, ICardFamilyHardware, ICardFamilyHidHardware, ICardFamilySamHardware)
  public
    Acquires, Releases, Channels, HidFactories: Integer;
    ReportDevice: IHidReportDevice;
    SamTransport: ICardTransport; SamAcquires,SamReleases: Integer;
    Transport: ICardTransport;
    Channel: ITwn4ByteChannel;
    FailRelease: Boolean;
    function HidDevices: THidDevices;
    function HidDevice(const APath: UnicodeString): IHidReportDevice;
    function AcquireSam(const AName: string): ICardTransport;
    procedure ReleaseSam;
    function AcquireReader(const AName: string): ICardTransport;
    procedure ReleaseReader;
    function CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
  end;

  TReports = class(TInterfacedObject,IHidReportDevice)
  public
    Opens,Closes,Receives,Sends: Integer;
    RejectSend: Boolean;
    function Open(const AWriteAccess: Boolean): THidDeviceInfo;
    procedure Close;
    function Receive(const K: THidReportKind; const Id: Byte; const Timeout: Cardinal): TBytes;
    procedure Send(const K: THidReportKind; const Data: TBytes; const Timeout: Cardinal);
  end;

var Checks: Integer;
procedure Check(const V: Boolean; const Why: string);
begin Inc(Checks); if not V then raise Exception.Create(Why); end;

function THardware.HidDevices: THidDevices;
begin Result := nil; SetLength(Result,1); Result[0] := Default(THidDeviceInfo); Result[0].DevicePath := 'hid:test'; Result[0].VendorId := $1234; Result[0].InputBytes := 4; end;
function THardware.HidDevice(const APath: UnicodeString): IHidReportDevice;
begin Check(APath = 'hid:test','Exact native HID interface path'); Inc(HidFactories); Result := ReportDevice; end;
function TReports.Open(const AWriteAccess: Boolean): THidDeviceInfo;
begin Inc(Opens); Result := Default(THidDeviceInfo); Result.InputBytes := 4; Result.OutputBytes := 4; Result.FeatureBytes := 4; end;
procedure TReports.Close;
begin Inc(Closes); end;
function TReports.Receive(const K: THidReportKind; const Id: Byte; const Timeout: Cardinal): TBytes;
begin Check((Id = 7) and (Timeout = 123),'Exact HID ID and deadline'); Inc(Receives); Result := HexToBytes('07010203'); end;
procedure TReports.Send(const K: THidReportKind; const Data: TBytes; const Timeout: Cardinal);
begin Check(BytesEqual(Data,HexToBytes('07010203')) and (Timeout = 123),'Exact HID output and deadline'); Inc(Sends); if RejectSend then raise EHidError.Create('Private vendor failure'); end;

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
function THardware.AcquireSam(const AName: string): ICardTransport;
begin Inc(SamAcquires); Check(AName='SAM reader','Exact separate SAM selection'); Result:=SamTransport; end;
procedure THardware.ReleaseSam;
begin Inc(SamReleases); end;
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

procedure TestLegacyProfilePreflight;
var H:THardware;Hardware:ICardFamilyHardware;R:TCardDemoRequest;D:TCardDemoResult;
 A:TCardFamilyActions;I,Profile,Before:Integer;Reached,Rejected:Boolean;Key:string;
begin
 H:=THardware.Create;Hardware:=H;A:=CardFamilyActions(dfUltralightC);
 for I:=0 to High(A) do
 begin
  Check(A[I].Mutation and A[I].Pcsc,'ULC explicit acknowledgement and PC/SC reader');
  R:=Request(dfUltralightC,A[I].Id);Put(R,dfUltralightC,'key','0123456789ABCDEFFEDCBA9876543210');Put(R,dfUltralightC,'data','AABBCCDD');Put(R,dfUltralightC,'page','4');
  Reached:=False;
  try CreateCardFamilyOperations(dfUltralightC,Hardware).Run(R,D);except on E:EReachedHardware do Reached:=True;end;
  Check(Reached,'ULC valid supplied-key action reaches acquisition');Before:=H.Acquires;
  R.MutationAcknowledged:=False;Rejected:=False;
  try CreateCardFamilyOperations(dfUltralightC,Hardware).Run(R,D);except on E:EArgumentException do Rejected:=True;end;
  Check(Rejected and (H.Acquires=Before),'ULC credential attempt acknowledgement before hardware');
  R.MutationAcknowledged:=True;Put(R,dfUltralightC,'key','00');Rejected:=False;
  try CreateCardFamilyOperations(dfUltralightC,Hardware).Run(R,D);except on E:Exception do Rejected:=True;end;
  Check(Rejected and (H.Acquires=Before),'ULC wrong key size rejected before hardware');
 end;
 for Profile:=3 to 6 do
 begin
  Key:='0123456789ABCDEFFEDCBA9876543210';if Profile=4 then Key:=Key+'0011223344556677' else if Profile=5 then Key:='0123456789ABCDEF';
  R:=Request(dfDesfire,'read');Put(R,dfDesfire,'aid','66051');Put(R,dfDesfire,'security',IntToStr(Profile));Put(R,dfDesfire,'minimum','1');Put(R,dfDesfire,'key',Key);
  Put(R,dfDesfire,'file','0');Put(R,dfDesfire,'count','4');Put(R,dfDesfire,'offset','0');Reached:=False;
  try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);except on E:EReachedHardware do Reached:=True;end;
  Check(Reached,'Explicit DES profile uses optional provider capability in preflight');Before:=H.Acquires;
  Put(R,dfDesfire,'key','00');Rejected:=False;
  try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);except on E:Exception do Rejected:=True;end;
  Check(Rejected and (H.Acquires=Before),'DES profile exact key size checked before reader acquisition');
  for I:=0 to 2 do
  begin
   R:=Request(dfDesfire,'createapp');Put(R,dfDesfire,'security',IntToStr(Profile));Put(R,dfDesfire,'key',Key);
   Put(R,dfDesfire,'targetaid','263430');Put(R,dfDesfire,'settings','15');Put(R,dfDesfire,'keycount','1');Put(R,dfDesfire,'applicationkeytype',IntToStr(I));
   Reached:=False;
   try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);except on E:EReachedHardware do Reached:=True;end;
   Check(Reached,'DES profile plus explicit application storage type reaches acquisition');Before:=H.Acquires;
   Put(R,dfDesfire,'applicationkeytype','-1');Rejected:=False;
   try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);except on E:EArgumentException do Rejected:=True;end;
   Check(Rejected and (H.Acquires=Before),'Unselected storage type rejected before hardware');
   Put(R,dfDesfire,'applicationkeytype',IntToStr(I));Put(R,dfDesfire,'keycount','129');Rejected:=False;
   try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);except on E:EArgumentException do Rejected:=True;end;
   Check(Rejected and (H.Acquires=Before),'Raw configuration byte cannot substitute for key count');
  end;
 end;
 Check(H.Releases=0,'Rejected/failed hardware acquisitions are never released');Hardware:=nil;
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

procedure TestStorageDemos;
var F: TCardDemoFamily; Actions: TCardFamilyActions; R: TCardDemoRequest; D: TCardDemoResult;
  H: THardware; Hardware: ICardFamilyHardware; S: TScript; T: ICardTransport; I,J,K,Prev: Integer; Reached,Failed: Boolean;
begin
  for F := dfClassic to dfType4 do
  begin
    Actions := CardFamilyActions(F); H := THardware.Create; Hardware := H;
    for I := 0 to High(Actions) do
      if Actions[I].Pcsc then
      begin
        R := Request(F,Actions[I].Id); Put(R,F,'key','000102030405');
        if F = dfClassic then Put(R,F,'data','000102030405060708090A0B0C0D0E0F');
        if F = dfType2 then begin Put(R,F,'data','00010203'); Put(R,F,'page','4'); Put(R,F,'type2model','3'); Put(R,F,'password','01020304'); Put(R,F,'pack','0102'); end; Put(R,F,'ndef','D101055402656E4869');
        Reached := False; try CreateCardFamilyOperations(F,Hardware).Run(R,D); except on E: EReachedHardware do Reached := True; end;
        Check(Reached,'Valid storage action acquisition '+Actions[I].Id);
        Prev := H.Acquires;
        if Actions[I].Mutation then
        begin R.MutationAcknowledged := False; Failed := False;
          try CreateCardFamilyOperations(F,Hardware).Run(R,D); except on E: EArgumentException do Failed := True; end;
          Check(Failed and (H.Acquires = Prev),'Storage acknowledgement preflight'); R.MutationAcknowledged := True; end;
        for J := 0 to High(Actions[I].Fields) do
          if Actions[I].Fields[J].Choices <> '' then
          begin
            R.Arguments[J] := '-1'; Failed := False;
            try CreateCardFamilyOperations(F,Hardware).Run(R,D); except on E: EArgumentException do Failed := True; end;
            Check(Failed and (H.Acquires = Prev),'Storage enum preflight'); R.Arguments[J] := '0';
          end;
      end;
    Hardware := nil;
  end;
  R := Request(dfClassic,'layout'); CreateCardFamilyOperations(dfClassic).Run(R,D);
  Check(Pos('3 trailer True',string(D.Text)) > 0,'Classic offline sector trailer');
  R := Request(dfType4,'decodecc'); CreateCardFamilyOperations(dfType4).Run(R,D);
  Check(Pos('FID E104 capacity 256 read 00 write 00',string(D.Text)) > 0,'Literal CC offline inspection');
  for K := 0 to 4 do
  begin
    S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
    if K < 2 then
    begin
      F := dfClassic; if K = 0 then R := Request(F,'read') else R := Request(F,'write');
      Put(R,F,'key','000102030405'); Put(R,F,'data','000102030405060708090A0B0C0D0E0F');
      S.Add('FF82000006000102030405','9000'); S.Add('FF860000050100016000','9000');
      if K = 0 then S.Add('FFB0000110','000102030405060708090A0B0C0D0E0F9000')
      else S.Add('FFD6000110000102030405060708090A0B0C0D0E0F','9000');
    end
    else if K < 4 then
    begin
      F := dfType2; if K = 2 then R := Request(F,'page') else R := Request(F,'writepage');
      Put(R,F,'page','4'); Put(R,F,'data','00010203');
      if K = 2 then S.Add('FFB0000404','000102039000') else S.Add('FFD600040400010203','9000');
    end
    else
    begin
      F := dfType4; R := Request(F,'capabilities'); Put(R,F,'version','1');
      S.Add('00A4040007D276000085010100','9000'); S.Add('00A4000C02E103','9000'); S.Add('00B000000F','000F20003A00340406E104010000009000');
    end;
    CreateCardFamilyOperations(F,Hardware).Run(R,D);
    Check(D.Success and (S.Position = Length(S.Steps)) and (S.Begins = 1) and (S.Ends = 1),'Complete storage transcript');
    Check((H.Acquires = 1) and (H.Releases = 1),'Storage connection lifetime');
    if K in [1,3] then Check(not D.WriteVerified and (Pos('independent read-back has not',string(D.Text)) > 0),'Status receipt is not read-back proof');
    Hardware := nil; T := nil;
  end;
end;

procedure TestExtendedSimDemo;
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware; Failed: Boolean;
begin
  H := THardware.Create; Hardware := H;
  R := Request(dfSim,'changepin'); Put(R,dfSim,'pin','31323334'); Put(R,dfSim,'newpin','35363738');
  Failed := False; try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: EReachedHardware do Failed := True; end;
  Check(Failed and (H.Acquires = 1),'Credential action explicit acquisition');
  R := Request(dfSim,'linkedwrite'); Put(R,dfSim,'profile','1'); Put(R,dfSim,'aid','A0000000871002'); Put(R,dfSim,'pin',''); Put(R,dfSim,'plan','4F50:1:41420101:42420101');
  Failed := False; try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: EReachedHardware do Failed := True; end;
  Check(Failed and (H.Acquires = 2),'Linked plan explicit acquisition');
  Put(R,dfSim,'plan','4F30:1:41420101:42420101'); Failed := False;
  try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: ESimCardError do Failed := True; end;
  Check(Failed and (H.Acquires = 2),'PBR mutation rejected before acquisition'); Hardware := nil;
  R := Request(dfSim,'email'); Put(R,dfSim,'hex','610062FFFF0102'); Put(R,dfSim,'footer','1');
  CreateCardFamilyOperations(dfSim).Run(R,D); Check(D.Text = 'a@b','EMAIL demo explicit footer');
  R := Request(dfSim,'decode'); Put(R,dfSim,'kind','8');
  Put(R,dfSim,'hex','0300040B912143658709F100006201902143650005E8329BFD06'+StringOfChar('F',300));
  CreateCardFamilyOperations(dfSim).Run(R,D); Check(Pos('hello',string(D.Text)) > 0,'SMS text demo literal');
  H := THardware.Create; Hardware := H; R := Request(dfSim,'linkedcontact');
  Put(R,dfSim,'profile','1'); Put(R,dfSim,'aid','A0000000871002'); Put(R,dfSim,'pin',''); Put(R,dfSim,'adnfid','20282');
  Failed := False; try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: EReachedHardware do Failed := True; end;
  Check(Failed and (H.Acquires = 1),'Linked USIM valid acquisition boundary');
  Put(R,dfSim,'pbrrecord','0'); Failed := False;
  try CreateCardFamilyOperations(dfSim,Hardware).Run(R,D); except on E: EArgumentException do Failed := True; end;
  Check(Failed and (H.Acquires = 1),'Bad PBR before hardware');
  Hardware := nil;
end;

procedure TestDocumentAndEmvDemos;
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware;
  S: TScript; T: ICardTransport; Failed: Boolean; I: Integer;
begin
  R := Request(dfEmv,'dol'); Put(R,dfEmv,'hex','9F02069F1A02'); CreateCardFamilyOperations(dfEmv).Run(R,D);
  Check(Pos('9F02 bytes 6',string(D.Text)) > 0,'EMV offline DOL');
  R := Request(dfEmv,'logdecode'); Put(R,dfEmv,'format','9F3602'); Put(R,dfEmv,'hex','0001');
  CreateCardFamilyOperations(dfEmv).Run(R,D); Check(Pos('9F36=0001',string(D.Text)) > 0,'EMV offline raw log');
  R := Request(dfIcao,'cardaccess'); Put(R,dfIcao,'hex','31143012060A04007F0007020204020202010202010D');
  CreateCardFamilyOperations(dfIcao).Run(R,D); Check(Pos('1',string(D.Text)) > 0,'ICAO offline CardAccess');
  H := THardware.Create; Hardware := H; R := Request(dfBelgian,'read'); Failed := False;
  try CreateCardFamilyOperations(dfBelgian,Hardware).Run(R,D); except on E: EReachedHardware do Failed := True; end;
  Check(Failed and (H.Acquires = 1),'Belgian eID explicit acquisition'); Hardware := nil;
  for I := 0 to 3 do
  begin
    S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
    case I of
      0: begin R := Request(dfEmv,'discover'); S.Add('00A404000E315041592E5359532E444446303100','6A82'); end;
      1: begin R := Request(dfEmv,'getdata'); S.Add('00A4040007A000000003101000','6F0B8407A0000000031010A5009000'); S.Add('80CA9F3600','9F360200019000'); end;
      2: begin R := Request(dfEmv,'application'); S.Add('00A4040007A000000003101000','6F0B8407A0000000031010A5009000'); S.Add('80A8000002830000','800200009000'); end;
      3: begin R := Request(dfEmv,'log'); S.Add('00A4040007A000000003101000','6F0B8407A0000000031010A5009000'); end;
    end;
    Put(R,dfEmv,'aid','A0000000031010');
    CreateCardFamilyOperations(dfEmv,Hardware).Run(R,D);
    Check(D.Success and (S.Position = Length(S.Steps)) and (S.Begins = 1) and (S.Ends = 1),'EMV literal complete family transcript');
    Check((H.Acquires = 1) and (H.Releases = 1),'EMV connection lifetime');
    if I = 1 then Check((Length(D.Artifacts) = 1) and BytesEqual(D.Artifacts[0].Data,HexToBytes('9F36020001')),'GET DATA owned export')
    else if I = 2 then Check((Length(D.Artifacts) = 2) and (D.Artifacts[0].Name = 'application-fci.bin') and (D.Artifacts[1].Name = 'gpo.bin'),'Application FCI/GPO export');
    Hardware := nil; T := nil;
  end;
end;


procedure TestRecordAcquisitionDemos;
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware;
 S: TScript; T: ICardTransport; Failed: Boolean;
begin
 S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
 S.Add('00A4040007A000000003101000','6F0B8407A0000000031010A5009000');
 S.Add('80A8000002830000','80060000080101009000'); S.Add('00B2010C00','70035A01129000');
 S.Add('00B2020C00','6A83'); S.Add('00B2030C00','70045F3401019000');
 R := Request(dfEmv,'application'); Put(R,dfEmv,'aid','A0000000031010'); Put(R,dfEmv,'scan','1');
 Put(R,dfEmv,'firstsfi','1'); Put(R,dfEmv,'lastsfi','1'); Put(R,dfEmv,'lastrecord','3');
 CreateCardFamilyOperations(dfEmv,Hardware).Run(R,D);
 Check(D.Success and (S.Position = 5) and (Length(D.Artifacts) = 4),'EMV demo actually reads and exports both records');
 Check((Pos('SFI 1 record 3: 70045F340101',string(D.Text)) > 0) and
  (Pos('record 2 SW=6A83',string(D.Text)) > 0),'EMV demo displays raw records and missing probe status');
 S := TScript.Create; T := S; H.Transport := T;
 S.Add('94A4000002200100','9000'); S.Add('94B201041D','ABCD9000'); S.Add('94B202041D','6A83');
 R := Request(dfMobib,'file'); Put(R,dfMobib,'dialect','0');
 CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);
 Check(D.Success and (S.Position = 3) and (Length(D.Artifacts) = 1),'MOBIB demo acquires real records');
 Check((Pos('Record 1: ABCD',string(D.Text)) > 0) and (D.Artifacts[0].Name = 'file-2001-record-1.bin'),'MOBIB raw display/export');
 R := Request(dfMobib,'file'); Put(R,dfMobib,'dialect','0'); Put(R,dfMobib,'fid','00'); Failed := False;
 try CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D); except on E: EArgumentException do Failed := True; end;
 Check(Failed and (H.Acquires = 2),'MOBIB invalid FID rejected before acquisition');
end;


procedure TestMobibRulesDemo;
var R:TCardDemoRequest;D:TCardDemoResult;H:THardware;Hardware:ICardFamilyHardware;Failed:Boolean;
begin
 H:=THardware.Create;Hardware:=H;R:=Request(dfMobib,'rules');R.ReaderName:='';
 Put(R,dfMobib,'contract','000000140180000000000000000E740000000000000000000000000000');Put(R,dfMobib,'tariff','2803');
 Put(R,dfMobib,'operator','test-operator');Put(R,dfMobib,'source','Synthetic fixture v1');
 Put(R,dfMobib,'now','2026-03-29 10:00:00');Put(R,dfMobib,'anchor','2026-03-29 10:00:00');
 Put(R,dfMobib,'duration','2');Put(R,dfMobib,'amount','24');Put(R,dfMobib,'zones','1;2');
 Put(R,dfMobib,'journeyzones','1');Put(R,dfMobib,'trips','7');
 CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);
 Check(D.Success and (Pos('Eligible under supplied policy',string(D.Text))>0),'Offline rule assessment');
 Check(Pos('Exclusive end: 2026-03-30 10:00:00',string(D.Text))>0,'Explicit UTC window visible');
 Check(Pos('Synthetic fixture v1',string(D.Text))>0,'Rule provenance visible');
 Check((H.Acquires=0) and (H.SamAcquires=0),'Offline rules open neither reader');
 Put(R,dfMobib,'journeyzones','3');Put(R,dfMobib,'anchor','');
 CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);
 Check(Pos('Ineligible under supplied policy',string(D.Text))>0,'Known zone failure dominates missing start');
 Check((Pos('Outside permitted zones',string(D.Text))>0) and (Pos('Missing contract start',string(D.Text))>0),'Both independent reasons visible');
 Put(R,dfMobib,'zones','');CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);
 Check(Pos('Unknown under supplied policy',string(D.Text))>0,'Missing operator zones not unrestricted');
 Put(R,dfMobib,'now','2026-02-30 10:00:00');Failed:=False;
 try CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);except on E:EArgumentException do Failed:=True;end;
 Check(Failed and (H.Acquires=0),'Invalid date rejected offline');
 Put(R,dfMobib,'now','2026-+1-30 10:00:00');Failed:=False;
 try CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);except on E:EArgumentException do Failed:=True;end;
 Check(Failed and (H.Acquires=0),'Nondecimal ISO date rejected offline');
 Hardware:=nil;
end;

procedure TestNativeSamDemo;
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware;
 Card,Sam:TScript; CT,ST:ICardTransport; I:Integer; Failed:Boolean;
begin
 for I:=0 to 1 do begin
  Card:=TScript.Create; CT:=Card; Sam:=TScript.Create; ST:=Sam;
  H:=THardware.Create; Hardware:=H;H.Transport:=CT;H.SamTransport:=ST;
  Card.Add('008A0101040102030400','10203040001122009000');
  Card.Add('00A4090002202000','9000');Card.Add('00B201041D','ABCD9000');Card.Add('008E8000041122334400','556677889000');
  Sam.Add('80140000080102030405060708','9000');Sam.Add('8084000004','010203049000');
  Sam.Add('808A00FF0A11221020304000112200','9000');
  Sam.Add('808C00000700A40900022020','9000');Sam.Add('808C0000029000','9000');
  Sam.Add('808C00000500B201041D','9000');Sam.Add('808C000004ABCD9000','9000');Sam.Add('808E000004','112233449000');
  if I=0 then Sam.Add('808200000455667788','9000') else Sam.Add('808200000455667788','6988');
  R:=Request(dfMobib,'samfile');Put(R,dfMobib,'dialect','1');Put(R,dfMobib,'revision','2');
  Put(R,dfMobib,'samreader','SAM reader');Put(R,dfMobib,'serial','0102030405060708');Put(R,dfMobib,'kif','17');Put(R,dfMobib,'kvc','34');
  Failed:=False;try CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);except on E:Exception do Failed:=True;end;
  Check(Failed=(I=1),'Native SAM failure propagated');Check((H.Acquires=1) and (H.Releases=1),'Card connection released');
  Check((H.SamAcquires=1) and (H.SamReleases=1),'SAM connection released');
  Check((Card.Position=4) and (Sam.Position=9),'Native card/SAM transcript complete');
  Check((Sam.Begins=1) and (Sam.Ends=1) and (Card.Begins=1) and (Card.Ends=1),'Both native transactions released');
  if I=0 then Check(D.Success and (Pos('Mutual session MAC verified',string(D.Text))>0) and (Length(D.Artifacts)=1),'Authenticated file export')
  else Check(not D.Success and (Length(D.Artifacts)=0),'Failed authentication exports no data');
  Put(R,dfMobib,'serial','01');Failed:=False;try CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);except on E:Exception do Failed:=True;end;
  Check(Failed and (H.Acquires=1) and (H.SamAcquires=1),'Invalid native input before either reader acquisition');
  Hardware:=nil;CT:=nil;ST:=nil;
 end;
end;

procedure TestMobibParsedDemo;
const Ids: array[0..7] of Word = ($2001,$2002,$2010,$2020,$2069,$2050,$2040,$3F1C);
var R: TCardDemoRequest; D: TCardDemoResult; H: THardware; Hardware: ICardFamilyHardware;
 S: TScript; T: ICardTransport; I: Integer;
begin
 S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
 S.Add('94A4000002200000','9000');
 for I := 0 to High(Ids) do begin
  if I = 0 then begin
   S.Add('94A4000002200100','9000'); S.Add('94B201041D','00082B00080000000000000000000000000000000000000000000000009000'); S.Add('94B202041D','6A83');
  end else S.Add('94A4000002'+IntToHex(Ids[I],4)+'00','6A82');
 end;
 R := Request(dfMobib,'snapshot'); Put(R,dfMobib,'dialect','0'); Put(R,dfMobib,'layout','1');
 CreateCardFamilyOperations(dfMobib,Hardware).Run(R,D);
 Check(D.Success and (S.Position = 11) and (S.Begins = 1) and (S.Ends = 1),'Parsed MOBIB demo executes complete file plan');
 Check((Pos('Layout matched True',string(D.Text)) > 0) and (Pos('Country 56 network 1',string(D.Text)) > 0),'Parsed MOBIB demo displays network and match state');
 Check((Length(D.Artifacts) = 1) and (D.Artifacts[0].Name = 'file-2001-record-1.bin'),'Parsed view retains original export');
end;

procedure TestAdditionalFamilies;
var F: TCardDemoFamily; A: TCardFamilyActions; I: Integer; R: TCardDemoRequest; D: TCardDemoResult;
  H: THardware; Hardware: ICardFamilyHardware; S: TScript; T: ICardTransport; Reached, Failed: Boolean;
begin
  for F := dfIso15693 to dfUid do
  begin
    A := CardFamilyActions(F); H := THardware.Create; Hardware := H;
    for I := 0 to High(A) do
    begin
      R := Request(F,A[I].Id); Put(R,F,'block','2'); Put(R,F,'data','00010203'); Put(R,F,'count','1'); Put(R,F,'ndef','D101055402656E4869');
      Put(R,F,'uid','01020304'); Put(R,F,'key','000102030405'); Put(R,F,'password','01020304');
      if A[I].Id = 'direct' then Put(R,F,'uid','01020304050607');
      Reached := False;
      try CreateCardFamilyOperations(F,Hardware).Run(R,D); except on E: EReachedHardware do Reached := True; end;
      Check(Reached,'Additional explicit profile acquisition '+A[I].Id);
      R.ReaderName := ''; Failed := False;
      try CreateCardFamilyOperations(F,Hardware).Run(R,D); except on E: EArgumentException do Failed := True; end;
      Check(Failed,'Exact reader selection before acquisition');
    end;
    Hardware := nil;
  end;
  H := THardware.Create; Hardware := H;
  for I := 0 to 5 do
  begin
    case I of 0: R := Request(dfDesfire,'files'); 1: R := Request(dfDesfire,'read'); 2: R := Request(dfDesfire,'value'); 3: R := Request(dfDesfire,'records'); 4: R := Request(dfDesfire,'version'); 5: R := Request(dfDesfire,'applications'); end;
    Put(R,dfDesfire,'aid','66051'); Put(R,dfDesfire,'offset','0'); Put(R,dfDesfire,'count','1'); Put(R,dfDesfire,'file','0');
    Reached := False; try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D); except on E: EReachedHardware do Reached := True; end;
    Check(Reached,'DESFire public operation acquisition');
  end;
  A := CardFamilyActions(dfDesfire);
  for I := 0 to High(A) do
    if A[I].Pcsc and not (A[I].Id = 'version') and not (A[I].Id = 'applications') then
    begin
      R := Request(dfDesfire,A[I].Id); Put(R,dfDesfire,'aid','66051');
      Put(R,dfDesfire,'security','1'); Put(R,dfDesfire,'minimum','1'); Put(R,dfDesfire,'key','000102030405060708090A0B0C0D0E0F');
      Put(R,dfDesfire,'offset','0'); Put(R,dfDesfire,'count','1'); Put(R,dfDesfire,'file','0'); Put(R,dfDesfire,'data','01020304');
      Put(R,dfDesfire,'amount','1'); Put(R,dfDesfire,'settings','15'); Put(R,dfDesfire,'keycount','1'); Put(R,dfDesfire,'applicationkeytype','2'); Put(R,dfDesfire,'targetaid','263430');
      Put(R,dfDesfire,'readkey','0'); Put(R,dfDesfire,'writekey','0'); Put(R,dfDesfire,'readwritekey','0'); Put(R,dfDesfire,'changekey','0');
      Put(R,dfDesfire,'filebytes','16'); Put(R,dfDesfire,'keyversion','1'); Put(R,dfDesfire,'newkey','101112131415161718191A1B1C1D1E1F');
      Reached := False;
      try CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D); except on E: EReachedHardware do Reached := True; end;
      Check(Reached,'All explicit DESFire AES/action preflights '+A[I].Id);
    end;
  Hardware := nil;
  S := TScript.Create; T := S; H := THardware.Create; Hardware := H; H.Transport := T;
  S.Add('905A00000300000000','9100'); S.Add('906A000000','0302010605049100'); R := Request(dfDesfire,'applications'); CreateCardFamilyOperations(dfDesfire,Hardware).Run(R,D);
  Check((D.Text = '010203'+sLineBreak+'040506'+sLineBreak) and (S.Position = 2) and (S.Ends = 1),'Literal DESFire application IDs');
  Hardware := nil; T := nil;
  R := Request(dfMagProfiles,'bits'); Put(R,dfMagProfiles,'track','1'); Put(R,dfMagProfiles,'payload','123');
  CreateCardFamilyOperations(dfMagProfiles).Run(R,D); Check((Pos('123',string(D.Text)) = 1) and (Length(D.Artifacts) = 1),'Magstripe parity/LRC export');
  R := Request(dfMagProfiles,'keyboard'); Put(R,dfMagProfiles,'hex','3B3132333F0D'); Put(R,dfMagProfiles,'tracks','1');
  CreateCardFamilyOperations(dfMagProfiles).Run(R,D); Check(Pos('Track 2: 123',string(D.Text)) > 0,'Literal MagTek keyboard frame');
  R := Request(dfUid,'gen4'); Put(R,dfUid,'uid','01020304'); Put(R,dfUid,'password','010203');
  H := THardware.Create; Hardware := H; Failed := False;
  try CreateCardFamilyOperations(dfUid,Hardware).Run(R,D); except on E: Exception do Failed := True; end;
  Check(Failed and (H.Acquires = 0),'Wrong Gen4 credential size before hardware'); Hardware := nil;
end;

procedure TestNativeHidDemo;
var H: THardware; Hardware: ICardFamilyHardware; P: TReports; R: TCardDemoRequest; D: TCardDemoResult; Failed: Boolean; I: Integer;
begin
  H := THardware.Create; Hardware := H; P := TReports.Create; H.ReportDevice := P;
  R := Request(dfNativeHid,'devices'); CreateCardFamilyOperations(dfNativeHid,Hardware).Run(R,D);
  Check((Pos('VID 1234',string(D.Text)) > 0) and (H.HidFactories = 0),'HID metadata without device selection');
  for I := 0 to 1 do
  begin
    R := Request(dfNativeHid,'read'); Put(R,dfNativeHid,'path','hid:test'); Put(R,dfNativeHid,'kind',IntToStr(I)); Put(R,dfNativeHid,'reportid','7'); Put(R,dfNativeHid,'timeout','123');
    CreateCardFamilyOperations(dfNativeHid,Hardware).Run(R,D);
    Check((D.Text = '07010203') and (Length(D.Artifacts) = 1) and BytesEqual(D.Artifacts[0].Data,HexToBytes('07010203')),'Exact HID read/export result');
  end;
  R := Request(dfNativeHid,'send'); Put(R,dfNativeHid,'path','hid:test'); Put(R,dfNativeHid,'report','07010203'); Put(R,dfNativeHid,'timeout','123');
  CreateCardFamilyOperations(dfNativeHid,Hardware).Run(R,D); Check(D.Success and not D.WriteVerified,'HID transfer does not invent card proof');
  P.RejectSend := True; Failed := False;
  try CreateCardFamilyOperations(dfNativeHid,Hardware).Run(R,D); except on E: EHidSendUncertain do Failed := True; end;
  Check(Failed and D.WriteUncertain and not D.WriteVerified,'HID uncertain submission surfaced');
  Check((P.Opens = 4) and (P.Closes = 4) and (P.Receives = 2) and (P.Sends = 2),'Native demo resource ownership');
  for I := 0 to 2 do
  begin
    R := Request(dfNativeHid,'send'); Put(R,dfNativeHid,'path','hid:test'); Put(R,dfNativeHid,'report','07010203');
    if I = 0 then R.MutationAcknowledged := False;
    if I = 1 then Put(R,dfNativeHid,'path','');
    if I = 2 then Put(R,dfNativeHid,'report','0');
    Failed := False; try CreateCardFamilyOperations(dfNativeHid,Hardware).Run(R,D); except on E: Exception do Failed := True; end;
    Check(Failed and (H.HidFactories = 4),'HID request validation before device factory');
  end;
  Hardware := nil;
end;

begin
  try
    TestMobibParsedDemo; TestNativeSamDemo; TestMobibRulesDemo; TestRecordAcquisitionDemos; TestNativeHidDemo; TestAdditionalFamilies; TestDocumentAndEmvDemos; TestExtendedSimDemo; TestStorageDemos; TestSimRoutes; TestOffline; TestLegacyProfilePreflight; TestPreflight; TestCounterAndSleRoutes;
    TestTwnRoutes(0,False); TestTwnRoutes(1,False); TestTwnRoutes(2,False); TestTwnRoutes(3,False); TestTwnRoutes(3,True);
    TestMemoryWrite(-1,False,False); TestMemoryWrite(6,False,False);
    TestMemoryWrite(7,False,False); TestMemoryWrite(-1,True,False); TestMemoryWrite(-1,False,True);
    Writeln('PASS: ',Checks,' family demo assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
