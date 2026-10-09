program Twn4Tests;

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
  ERD.Card.Bytes, ERD.Card.Contactless, ERD.Card.Contactless.Type2,
  ERD.Card.Reader.TWN4, ERD.Card.Reader.TWN4.Serial;

type
  TStep = record Request, Response: TBytes; end;
  TScript = class(TInterfacedObject,ITwn4ByteChannel)
  public
    Steps: array of TStep;
    Index, Offset, Opens, Closes, IoCount, FailAt, ExpireAfterStep: Integer;
    Active, FailOpen, FailClose, SawWrite, ReadBackComplete, ExpireOnWrite, ReverseOnWrite: Boolean;
    Clock, ClockStep: UInt64;
    MutateKey, MutateId, MutateBefore, MutateData: TBytes;
    constructor Create;
    procedure Add(const Request, Response: string);
    procedure Open;
    procedure Close;
    procedure Send(const B: TBytes; const Timeout: Cardinal);
    function ReceiveByte(const Timeout: Cardinal): Byte;
    function NowMs: UInt64;
  end;

var Checks: Integer;

procedure Check(const V: Boolean; const Why: string);
begin Inc(Checks); if not V then raise Exception.Create(Why); end;

function Ascii(const S: string): TBytes;
var I: Integer;
begin Result := nil; SetLength(Result,Length(S)); for I := 1 to Length(S) do Result[I - 1] := Ord(S[I]); end;

constructor TScript.Create;
begin inherited Create; FailAt := -1; ExpireAfterStep := -1; end;

procedure TScript.Add(const Request, Response: string);
var N: Integer;
begin N := Length(Steps); SetLength(Steps,N + 1); Steps[N].Request := Ascii(Request + #13); Steps[N].Response := Ascii(Response + #13); end;

procedure TScript.Open;
begin
  Check(not Active,'No nested open'); Inc(Opens);
  if FailOpen then raise Exception.Create('Sensitive acquisition text');
  Active := True;
  if Length(MutateKey) <> 0 then MutateKey[0] := $EE;
  if Length(MutateId) <> 0 then MutateId[0] := $EE;
  if Length(MutateBefore) <> 0 then MutateBefore[0] := $EE;
  if Length(MutateData) <> 0 then MutateData[0] := $EE;
end;

procedure TScript.Close;
begin Check(Active,'Owned close'); Inc(Closes); Active := False; if FailClose then raise Exception.Create('Sensitive close text'); end;

procedure TScript.Send(const B: TBytes; const Timeout: Cardinal);
begin
  Check(Active and (Timeout > 0),'Owned bounded send');
  Check((Index < Length(Steps)) and (Offset = 0),'No extra/replayed send');
  Check(BytesEqual(B,Steps[Index].Request),'Independent literal request');
  if (Length(B) >= 4) and (((B[0] = Ord('0')) and (B[1] = Ord('C')) and (B[2] = Ord('0')) and (B[3] = Ord('1'))) or
    ((B[0] = Ord('0')) and (B[1] = Ord('B')) and (B[2] = Ord('0')) and (B[3] = Ord('2')))) then SawWrite := True;
  if SawWrite then
  begin if ExpireOnWrite then Inc(Clock,3000); if ReverseOnWrite then Dec(Clock); end;
  Inc(IoCount); if IoCount - 1 = FailAt then raise Exception.Create('Sensitive send text');
end;

function TScript.ReceiveByte(const Timeout: Cardinal): Byte;
begin
  Check(Active and (Timeout > 0),'Owned bounded receive'); Inc(IoCount);
  if IoCount - 1 = FailAt then raise Exception.Create('Sensitive receive text');
  Check((Index < Length(Steps)) and (Offset < Length(Steps[Index].Response)),'Bounded literal receive');
  Result := Steps[Index].Response[Offset]; Inc(Offset);
  if Offset = Length(Steps[Index].Response) then
  begin
    if SawWrite and (Length(Steps[Index].Request) >= 4) and
      ((Steps[Index].Request[3] = Ord('0')) or (Steps[Index].Request[3] = Ord('1'))) and
      (Length(Steps[Index].Response) = 37) then ReadBackComplete := True;
    if Index = ExpireAfterStep then Inc(Clock,3000);
    Inc(Index); Offset := 0;
  end;
end;

function TScript.NowMs: UInt64;
begin Result := Clock; Inc(Clock,ClockStep); end;

procedure Complete(const S: TScript);
begin Check((S.Index = Length(S.Steps)) and (S.Opens = 1) and (S.Closes = 1) and not S.Active,'Complete closed transcript'); end;

function Setup(const S: TScript): TTwn4CardReaderWriter;
begin Result := TTwn4CardReaderWriter.Create(nil); Result.Channel := S; end;

procedure Type2Script(const S: TScript; const Write, Changed: Boolean);
begin
  S.Add('050010','000180380704010203040506');
  S.Add('0C0004','000100010203101112132021222330313233');
  if Write and Changed then
  begin
    S.Add('050010','000180380704010203040506');
    S.Add('0C0004','000100010203101112132021222330313233');
    S.Add('0C0104AABBCCDD','0001');
    S.Add('0C0004','0001AABBCCDD101112132021222330313233');
  end;
  S.Add('0501','00');
end;

procedure ClassicScript(const S: TScript; const Write: Boolean; const KeyB: Boolean = False);
var Login: string;
begin
  Login := '0B00A0A1A2A3A4A50000'; if KeyB then Login := '0B00A0A1A2A3A4A50100';
  S.Add('050010','000180200466CF4DC2'); S.Add(Login,'0001');
  S.Add('0B0102','0001000102030405060708090A0B0C0D0E0F');
  if Write then
  begin
    S.Add('050010','000180200466CF4DC2'); S.Add(Login,'0001');
    S.Add('0B0102','0001000102030405060708090A0B0C0D0E0F');
    S.Add('0B0202101112131415161718191A1B1C1D1E1F','0001');
    S.Add('0B0102','0001101112131415161718191A1B1C1D1E1F');
  end;
  S.Add('0501','00');
end;

procedure CodecTests;
var B, Line: TBytes; T: TTwn4TagInfo; I, J: Integer; Failed: Boolean;
begin
  Check(BytesEqual(TTwn4Codec.EncodeAscii(HexToBytes('0005'),False),Ascii('0005'#13)),'Manual ASCII reference');
  Check(BytesEqual(TTwn4Codec.EncodeAscii(HexToBytes('0005'),True),Ascii('000515A7'#13)),'Manual command CRC reference');
  Check(BytesToHex(TTwn4Codec.DecodeAscii(Ascii('000131E1'#13),True)) = '0001','Manual response CRC reference');
  T := TTwn4Codec.DecodeTag(HexToBytes('000180200466CF4DC2'));
  Check(T.Found and (T.IdBitCount = 32) and (BytesToHex(T.Id) = '66CF4DC2'),'Manual SearchTag literal');
  T := TTwn4Codec.DecodeTag(HexToBytes('0000000000')); Check(not T.Found and (Length(T.Id) = 0),'No tag canonical fields');
  T := TTwn4Codec.DecodeTag(HexToBytes('0000')); Check(not T.Found,'No tag short form');
  for I := 0 to 8 do
  begin
    Failed := False;
    try
      case I of
        0: B := TTwn4Codec.DecodeAscii(Ascii('0001'),False);
        1: B := TTwn4Codec.DecodeAscii(Ascii('0'#13),False);
        2: B := TTwn4Codec.DecodeAscii(Ascii('00 01'#13),False);
        3: B := TTwn4Codec.DecodeAscii(Ascii('00GG'#13),False);
        4: B := TTwn4Codec.DecodeAscii(Ascii('01'#13),False);
        5: B := TTwn4Codec.DecodeAscii(Ascii('000131E0'#13),True);
        6: B := TTwn4Codec.DecodeAscii(Ascii('00'#13#10),False);
        7: T := TTwn4Codec.DecodeTag(HexToBytes('0001802003AABBCC'));
        8: T := TTwn4Codec.DecodeTag(HexToBytes('0002000000'));
      end;
    except on ETwn4Error do Failed := True; end;
    Check(Failed,'Strict framing / status / bits');
  end;
  // Every corrupted bit of the independently documented CRC response is refused.
  Line := HexToBytes('000131E1');
  for I := 0 to 3 do for J := 0 to 7 do
  begin
    B := CopyBytes(Line); B[I] := B[I] xor (1 shl J); Failed := False;
    try B := TTwn4Codec.DecodeAscii(Ascii(BytesToHex(B) + #13),True); except on ETwn4Error do Failed := True; end;
    Check(Failed,'CRC response bit corruption');
  end;
end;

procedure SuccessTests;
var S: TScript; R: TTwn4CardReaderWriter; B, Key, Id, Before, Data: TBytes; T: TTwn4TagInfo;
  KeyType: TMifareClassicKeyType;
begin
  for KeyType := mckA to mckB do
  begin
    S := TScript.Create; R := Setup(S);
    try ClassicScript(S,False,KeyType = mckB);
      B := R.ReadClassicBlock(mcm1K,2,0,KeyType,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'));
      Check(BytesToHex(B) = '000102030405060708090A0B0C0D0E0F','Authenticated Classic read'); Complete(S);
    finally R.Free; end;
  end;
  S := TScript.Create; R := Setup(S);
  try
    ClassicScript(S,True); Key := HexToBytes('A0A1A2A3A4A5'); Id := HexToBytes('66CF4DC2');
    Before := HexToBytes('000102030405060708090A0B0C0D0E0F'); Data := HexToBytes('101112131415161718191A1B1C1D1E1F');
    S.MutateKey := Key; S.MutateId := Id; S.MutateBefore := Before; S.MutateData := Data;
    R.WriteClassicDataBlock(mcm1K,2,0,mckA,Key,Id,Before,Data);
    Check(S.SawWrite and S.ReadBackComplete,'Classic acquired write proof'); Complete(S);
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try Type2Script(S,False,False);
    B := R.ReadType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'));
    Check(BytesToHex(B) = '00010203','Only selected Type 2 page returned'); Complete(S);
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try Type2Script(S,True,True);
    R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
    Check(S.SawWrite and S.ReadBackComplete,'Type 2 acquired proof'); Complete(S);
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try Type2Script(S,True,False);
    R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('00010203'));
    Check(not S.SawWrite,'No-op skips programming'); Complete(S);
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try S.Add('00047E','000454574E34'); S.Add('0501','00'); Check(R.ReadVersion = 'TWN4','Bounded version'); Complete(S);
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try S.Add('050010','000101280566CF4DC201'); S.Add('0501','00'); T := R.ReadTag;
    Check(T.Found and (T.IdBitCount = 40) and (Length(T.Id) = 5),'Low-frequency opaque ID'); Complete(S);
  finally R.Free; end;
end;

procedure FailureTests;
var S: TScript; R: TTwn4CardReaderWriter; I, Count, Kind, Bit: Integer;
  Failed, Uncertain, Verified: Boolean; Line: TBytes;
begin
  for Kind := 0 to 1 do
  begin
    S := TScript.Create; R := Setup(S);
    try
      if Kind = 0 then Type2Script(S,True,True) else ClassicScript(S,True);
      if Kind = 0 then R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'))
      else R.WriteClassicDataBlock(mcm1K,2,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'),HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
      Count := S.IoCount;
    finally R.Free; end;
    for I := 0 to Count - 1 do
    begin
      S := TScript.Create; R := Setup(S);
      try
        if Kind = 0 then Type2Script(S,True,True) else ClassicScript(S,True);
        S.FailAt := I; Failed := False; Uncertain := False; Verified := False;
        try
          if Kind = 0 then R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'))
          else R.WriteClassicDataBlock(mcm1K,2,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'),HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
        except
          on E: ETwn4WriteUncertain do begin Failed := True; Uncertain := True; Verified := E.VerifiedReadBack; end;
          on E: ETwn4Error do begin Failed := True; Check(Pos('Sensitive',E.Message) = 0,'Sanitized backend messages'); end;
        end;
        Check(Failed,'Every byte I/O failure'); Check(Uncertain = S.SawWrite,'Dispatch uncertainty boundary');
        Check(Verified = (S.SawWrite and S.ReadBackComplete),'Acquired read-back evidence');
        Check((S.Closes = 1) and not S.Active,'Failure closes without replay');
      finally R.Free; end;
    end;
  end;
  for I := 0 to 3 do for Bit := 0 to 7 do
  begin
    S := TScript.Create; R := Setup(S);
    try
      Type2Script(S,True,True); Line := HexToBytes('0001AABBCCDD101112132021222330313233');
      Line[I + 2] := Line[I + 2] xor (1 shl Bit); S.Steps[5].Response := Ascii(BytesToHex(Line) + #13);
      Uncertain := False;
      try R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
      except on E: ETwn4WriteUncertain do begin Uncertain := True; Check(not E.VerifiedReadBack,'Corrupt readback has no proof'); end; end;
      Check(Uncertain,'Every selected-page read-back bit'); Check((S.Closes = 1) and not S.Active,'Corrupt read-back closes');
    finally R.Free; end;
  end;
  S := TScript.Create; R := Setup(S);
  try Type2Script(S,True,True); S.FailClose := True; Uncertain := False;
    try R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
    except on E: ETwn4WriteUncertain do begin Uncertain := True; Check(E.VerifiedReadBack,'Cleanup retains proof'); end; end;
    Check(Uncertain and not S.Active,'Uncertain release');
  finally R.Free; end;
  S := TScript.Create; R := Setup(S);
  try S.FailOpen := True; Failed := False;
    try R.ReadTag; except on ETwn4Error do Failed := True; end;
    Check(Failed and (S.Closes = 0),'Failed open grants no ownership');
    S.FailOpen := False; S.Add('050010','0000'); S.Add('0501','00'); R.ReadTag;
    Check(S.Closes = 1,'Acquisition recovery');
  finally R.Free; end;
end;

procedure GuardTests;
var S: TScript; R: TTwn4CardReaderWriter; I: Integer; Failed: Boolean;
  Channel: ITwn4ByteChannel;
begin
  S := TScript.Create; R := Setup(S);
  try
    for I := 0 to 6 do
    begin
      Failed := False;
      try
        case I of
          0: R.WriteClassicDataBlock(mcm1K,0,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'),HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
          1: R.WriteClassicDataBlock(mcm1K,3,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'),HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
          2: R.ReadClassicBlock(mcm1K,4,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'));
          3: R.ReadClassicBlock(mcmMini,20,5,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'));
          4: R.WriteType2UserPage(ttmNtag213,3,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
          5: R.WriteType2UserPage(ttmNtag213,40,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
          6: R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
        end;
      except on Exception do Failed := True; end;
      Check(Failed and (S.Opens = 0),'Invalid mutation/configuration fails before I/O');
    end;
  finally R.Free; end;
  Channel := CreateWindowsTwn4CdcChannel('COM17'); Check(Channel <> nil,'Native factory inactive');
  Failed := False;
  try Channel := CreateWindowsTwn4CdcChannel('not-a-device'); except on Exception do Failed := True; end;
  Check(Failed,'Native port validation');
end;

procedure ExtraTests;
var S: TScript; R: TTwn4CardReaderWriter; B: TBytes; T: TTwn4TagInfo;
  I, Bit, CaseNo: Integer; Failed, Uncertain: Boolean;
begin
  S := TScript.Create; R := Setup(S);
  try
    R.UseCrc := True;
    S.Add('0500100F10','000180200466CF4DC2E960'); S.Add('0501899F','00870F');
    T := R.ReadTag; Check(T.Found and (BytesToHex(T.Id) = '66CF4DC2'),'CRC-framed literal tag chain'); Complete(S);
  finally R.Free; end;
  for CaseNo := 0 to 9 do
  begin
    S := TScript.Create; R := Setup(S);
    try
      Type2Script(S,True,True);
      case CaseNo of
        0: S.Steps[0].Response := Ascii('000180380705010203040506'#13); // Wrong tag before reading.
        1: S.Steps[1].Response := Ascii('0001FFFFFFFF101112132021222330313233'#13); // Stale initial contents.
        2: S.Steps[2].Response := Ascii('000180380705010203040506'#13); // Tag changed before write.
        3: S.Steps[3].Response := Ascii('0001FFFFFFFF101112132021222330313233'#13); // Stale final preflight.
        4: S.Steps[4].Response := Ascii('0000'#13); // False device write acknowledgement.
        5: S.Steps[4].Response := Ascii('0002'#13); // Non-boolean result.
        6: S.Steps[5].Response := Ascii('0001AABBCCDD'#13); // Truncated READ.
        7: begin S.Clock := 1000; S.ExpireOnWrite := True; end;
        8: begin S.Clock := 1000; S.ReverseOnWrite := True; end;
        9: begin S.Clock := 1000; S.ExpireAfterStep := 3; end;
      end;
      Failed := False; Uncertain := False;
      try R.WriteType2UserPage(ttmNtag213,4,HexToBytes('04010203040506'),HexToBytes('00010203'),HexToBytes('AABBCCDD'));
      except
        on E: ETwn4WriteUncertain do begin Failed := True; Uncertain := True; Check(not E.VerifiedReadBack,'No premature read-back proof'); end;
        on ETwn4Error do Failed := True;
      end;
      Check(Failed and (Uncertain = (CaseNo in [4..8])),'Guarded dispatch / wrong response / deadline');
      Check((S.Closes = 1) and not S.Active,'Guard failure closes');
    finally R.Free; end;
  end;
  // Classic read-back proof checks every bit of all sixteen bytes.
  for I := 0 to 15 do for Bit := 0 to 7 do
  begin
    S := TScript.Create; R := Setup(S);
    try
      ClassicScript(S,True); B := HexToBytes('0001101112131415161718191A1B1C1D1E1F');
      B[I + 2] := B[I + 2] xor (1 shl Bit); S.Steps[7].Response := Ascii(BytesToHex(B) + #13);
      Uncertain := False;
      try R.WriteClassicDataBlock(mcm1K,2,0,mckA,HexToBytes('A0A1A2A3A4A5'),HexToBytes('66CF4DC2'),HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'));
      except on E: ETwn4WriteUncertain do begin Uncertain := True; Check(not E.VerifiedReadBack,'Classic corrupt proof'); end; end;
      Check(Uncertain and not S.Active,'Every Classic read-back bit');
    finally R.Free; end;
  end;
  // Native channel construction is inactive on Linux: actual opening stays unsupported.
{$IFNDEF MSWINDOWS}
  S := nil;
  with TTwn4CardReaderWriter.Create(nil) do
  try
    Channel := CreateWindowsTwn4CdcChannel('COM17'); Failed := False;
    try ReadTag; except on ETwn4Error do Failed := True; end;
    Check(Failed,'Non-Windows native opening is explicit unsupported');
  finally Free; end;
{$ENDIF}
end;

begin
  try CodecTests; SuccessTests; FailureTests; GuardTests; ExtraTests;
    Writeln('PASS: ',Checks,' TWN4 protocol/reader assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
