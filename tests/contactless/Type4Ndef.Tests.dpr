program Type4NdefTests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.Transport, ERD.Card.Ndef,
  ERD.Card.Ndef.Records, ERD.Card.Contactless, ERD.Card.Contactless.Type4.Ndef;

type
  TStep = record
    Wire, Response: TBytes;
    Fails: Boolean;
  end;
  TExactScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    Active, BeginFails, EndFails: Boolean;
    procedure Add(const Wire, Response: string);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TMemoryScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Cc, FileBytes, InitialTail: TBytes;
    Commands: array of TBytes;
    UpdateOffsets: array of Integer;
    Version: TType4ApplicationVersion;
    Selected: Word;
    Begins, Ends, Reads, Writes, FailWrite, BadReadAt, FailCommand, Position, NlenReads: Integer;
    FinalLength, RejectStatus, OverrideStatus: Integer;
    Active, BeginFails, EndFails, SuppressUpdate, CorruptCc, MutateNlen: Boolean;
    constructor Create(const ASize, AMLe, AMLc: Integer; const Initial: TBytes);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TNoTransaction = class(TInterfacedObject, ICardTransport)
    function Exchange(const ACommand: TBytes): TBytes;
  end;
var Checks: Integer = 0;

procedure Check(const Value: Boolean; const Msg: string);
begin Inc(Checks); if not Value then raise Exception.Create(Msg); end;

function WordHex(const N: Integer): string;
begin Result := IntToHex(N, 4); end;

function Capability(const Size, MLe, MLc: Integer; const Version: Byte = $20): TBytes;
begin
  Result := HexToBytes('000F' + IntToHex(Version, 2) + WordHex(MLe) + WordHex(MLc) + '0406E104' + WordHex(Size) + '0000');
end;

function MessageOf(const N: Integer): TNdefMessage;
var B: TBytes; I: Integer;
begin
  SetLength(B, N); for I := 0 to N - 1 do B[I] := Byte((I * 17 + 3) and $FF);
  Result := nil; SetLength(Result, 1); Result[0] := TNdefCodec.NewRecord(ntfUnknown, nil, nil, B);
end;

procedure BadCc(const B: TBytes);
var C: TType4CapabilityContainer; Failed: Boolean;
begin
  Failed := False;
  try C := TType4NdefCodec.DecodeCapabilities(B); except on EType4NdefError do Failed := True; end;
  Check(Failed, 'Malformed CC refused');
end;

procedure Codec;
var B, Original, Wire: TBytes; C: TType4CapabilityContainer; F: TType4NdefFile;
  Cmd: TApduCommand; I, J: Integer; Failed: Boolean;
begin
  // Independent synthetic CC using NXP AN11004 Rev. 2.4 MLe=003A/MLc=0034;
  // the selected file size 256 is a fixture, not a physical-card sample.
  B := HexToBytes('000F20003A00340406E10401000000'); Original := CopyBytes(B);
  C := TType4NdefCodec.DecodeCapabilities(B);
  Check((C.MLe = 58) and (C.MLc = 52) and (C.MappingVersion = $20) and (Length(C.Files) = 1), 'NXP CC header vector');
  F := TType4NdefCodec.FindFile(C); Check((F.FileId = $E104) and (F.MaxFileBytes = 256), 'NXP descriptor vector');
  B[0] := $FF; Check(BytesEqual(C.RawBytes, Original), 'CC buffers independent');
  for I := 0 to Length(Original) - 1 do BadCc(Copy(Original, 0, I));
  B := CopyBytes(Original); B[1] := 14; BadCc(B); B := CopyBytes(Original); B[1] := 16; BadCc(B);
  for I := 0 to 255 do if not (I in [$10, $20]) then
  begin B := CopyBytes(Original); B[2] := I; BadCc(B); end;
  B := CopyBytes(Original); B[4] := 14; BadCc(B);
  B := CopyBytes(Original); B[6] := 0; BadCc(B);
  B := CopyBytes(Original); B[7] := 6; BadCc(B); B[7] := 5; BadCc(B);
  B := CopyBytes(Original); B[8] := 5; BadCc(B); B[8] := 7; BadCc(B); B[8] := $FF; BadCc(B);
  for I := 0 to 2 do begin B := CopyBytes(Original); B[12] := I; B[11] := 0; BadCc(B); end;
  B := CopyBytes(Original); B[11] := $80; B[12] := 0; BadCc(B);
  for I := 1 to $7F do
  begin
    B := CopyBytes(Original); B[13] := I; BadCc(B);
    B := CopyBytes(Original); B[14] := I; BadCc(B);
  end;
  B := CopyBytes(Original); B[13] := $FF; BadCc(B);
  B := CopyBytes(Original); B[13] := $80; B[14] := $FE;
  C := TType4NdefCodec.DecodeCapabilities(B); Check(C.Files[0].ReadAccess = $80, 'Proprietary access is visible but not public');
  B[13] := 0; B[14] := $FF; C := TType4NdefCodec.DecodeCapabilities(B); Check(C.Files[0].WriteAccess = $FF, 'Read-only descriptor');
  // Additional ordinary file plus an opaque optional TLV; the whole CC is acquired.
  B := HexToBytes('001C20010000FF0406E104010000000406E10502000000FD03010203');
  C := TType4NdefCodec.DecodeCapabilities(B);
  Check((Length(C.Files) = 2) and BytesEqual(C.RawBytes, B), 'Multiple files and unknown TLV retained');
  Failed := False;
  try F := TType4NdefCodec.FindFile(C); except on EType4NdefError do Failed := True; end;
  Check(Failed, 'No silent first-file default');
  F := TType4NdefCodec.FindFile(C, $E105); Check(F.MaxFileBytes = 512, 'Explicit second file');
  B[17] := $E1; B[18] := $04; BadCc(B);
  B := CopyBytes(Original); SetLength(B, Type4MaxCapabilityBytes + 1); BadCc(B);
  B := HexToBytes('000F20000F00010406E104000500FF'); C := TType4NdefCodec.DecodeCapabilities(B);
  Check((C.MLc = 1) and (C.Files[0].MaxFileBytes = 5), 'Minimum readable mapping');
  for I := 1 to Type4MaxNdefFiles + 1 do
  begin
    B := HexToBytes(WordHex(7 + I * 8) + '20010000FF');
    for J := 1 to I do begin Wire := HexToBytes('0406' + WordHex($E103 + J) + '7FFF0000');
      B := Concat(B, Wire); end;
    if I <= Type4MaxNdefFiles then
    begin C := TType4NdefCodec.DecodeCapabilities(B); Check(Length(C.Files) = I, 'Bounded descriptor count'); end
    else BadCc(B);
  end;
  Check(BytesToHex(TType4NdefCodec.SelectApplication(t4av2)) = '00A4040007D276000085010100', 'Mapping 2.0 application SELECT vector');
  Check(BytesToHex(TType4NdefCodec.SelectApplication(t4av1)) = '00A4040007D2760000850100', 'Mapping 1.0 application SELECT vector');
  Check(BytesToHex(TType4NdefCodec.SelectFile($E103, t4av2)) = '00A4000C02E103', 'Mapping 2.0 CC SELECT vector');
  Check(BytesToHex(TType4NdefCodec.SelectFile($E104, t4av1)) = '00A4000002E104', 'Mapping 1.0 file SELECT vector');
  for I := 1 to 256 do
  begin
    Wire := TType4NdefCodec.ReadBinary(0, I); Cmd := TApduCodec.DecodeCommand(Wire);
    Check(Cmd.HasLe and (Cmd.Le = Cardinal(I)) and not Cmd.IsExtended and (Length(Wire) = 5), 'All short Le values');
  end;
  Check(BytesToHex(TType4NdefCodec.ReadBinary($7FFE, 1)) = '00B07FFE01', 'Final ordinary file byte');
  for I := 0 to 4 do
  begin
    Failed := False;
    try
      case I of
        0: Wire := TType4NdefCodec.ReadBinary(-1, 1);
        1: Wire := TType4NdefCodec.ReadBinary(0, 0);
        2: Wire := TType4NdefCodec.ReadBinary(0, 257);
        3: Wire := TType4NdefCodec.ReadBinary($7FFE, 2);
        4: Wire := TType4NdefCodec.UpdateBinary(0, nil);
      end;
    except on EType4NdefError do Failed := True; end;
    Check(Failed, 'Short command bounds');
  end;
  Wire := TType4NdefCodec.UpdateBinary(0, HexToBytes('0000'));
  Check(BytesToHex(Wire) = '00D60000020000', 'NLEN invalidation vector');
  Writeln('PASS: CC/APDU vectors, descriptors, bounds and ownership');
end;

procedure TExactScript.Add(const Wire, Response: string);
var I: Integer;
begin I := Length(Steps); SetLength(Steps, I + 1);
  Steps[I].Wire := HexToBytes(Wire); Steps[I].Response := HexToBytes(Response); end;

procedure TExactScript.BeginTransaction;
begin Inc(Begins); if BeginFails then raise ECardTransportError.Create('acquire');
  Check(not Active, 'No nested transaction'); Active := True; end;

procedure TExactScript.EndTransaction;
begin Inc(Ends); Check(Active, 'Release owns transaction'); Active := False;
  if EndFails then raise ECardTransportError.Create('release'); end;

function TExactScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Active and (Position < Length(Steps)), 'Every command in transaction, no extra command/retry');
  Check(BytesEqual(ACommand, Steps[Position].Wire), 'Independent exact APDU transcript');
  Inc(Position); if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic backend');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

procedure ExactTranscripts;
var Script: TExactScript; Reader: TType4NdefCardReader; S: TType4NdefSnapshot;
  V: TType4ApplicationVersion; M: TNdefMessage; Failed: Boolean;
begin
  for V := Low(TType4ApplicationVersion) to High(TType4ApplicationVersion) do
  begin
    Script := TExactScript.Create; Reader := TType4NdefCardReader.Create(nil);
    try
      Reader.Transport := Script; Reader.ApplicationVersion := V;
      if V = t4av1 then
      begin Script.Add('00A4040007D2760000850100', '9000'); Script.Add('00A4000002E103', '9000');
        Script.Add('00B000000F', '000F10003A00340406E104010000009000'); Script.Add('00A4000002E104', '9000'); end
      else
      begin Script.Add('00A4040007D276000085010100', '6F009000'); Script.Add('00A4000C02E103', '9000');
        Script.Add('00B000000F', '000F20003A00340406E104010000009000'); Script.Add('00A4000C02E104', '9000'); end;
      Script.Add('00B0000002', '00099000');
      Script.Add('00B0000209', 'D101055402656E48699000');
      Script.Add('00B0000002', '00099000'); S := Reader.ReadMessage;
      Check((TNdefRecords.DecodeText(S.Records[0]).Text = 'Hi') and (Script.Position = 7), 'Both mapping read transcripts');
      Check((Script.Begins = 1) and (Script.Ends = 1), 'One transaction');
    finally Reader.Free; end;
  end;
  Script := TExactScript.Create; Reader := TType4NdefCardReader.Create(nil);
  try
    Reader.Transport := Script;
    Script.Add('00A4040007D276000085010100', '9000'); Script.Add('00A4000C02E103', '9000');
    Script.Add('00B000000F', '000F20000F00040406E104004000009000'); Script.Add('00A4000C02E104', '9000');
    Script.Add('00B0000002', '00039000'); Script.Add('00B0000203', 'D000009000'); Script.Add('00B0000002', '00039000');
    Script.Add('00D60000020000', '9000'); Script.Add('00B0000002', '00009000');
    // New message is nine bytes, segmented by MLc=4. Every chunk read back before the next update.
    Script.Add('00D6000204D1010554', '9000'); Script.Add('00B0000204', 'D10105549000');
    Script.Add('00D600060402656E48', '9000'); Script.Add('00B0000604', '02656E489000');
    Script.Add('00D6000A0169', '9000'); Script.Add('00B0000A01', '699000');
    Script.Add('00D60000020009', '9000'); Script.Add('00B0000002', '00099000');
    Script.Add('00A4000C02E103', '9000'); Script.Add('00B000000F', '000F20000F00040406E104004000009000');
    Script.Add('00A4000C02E104', '9000'); Script.Add('00B0000002', '00099000');
    Script.Add('00B0000209', 'D101055402656E48699000'); Script.Add('00B0000002', '00099000');
    SetLength(M, 1); M[0] := TNdefRecords.Text('Hi', 'en'); Reader.WriteMessage(M);
    Check((Script.Position = Length(Script.Steps)) and (Script.Begins = 1) and (Script.Ends = 1), 'Exact length-last write/CC verification sequence');
  finally Reader.Free; end;
  Script := TExactScript.Create; Reader := TType4NdefCardReader.Create(nil);
  try
    Reader.Transport := Script; Script.Add('00A4040007D276000085010100', '6A82'); Failed := False;
    try S := Reader.ReadMessage; except on EContactlessStatusError do Failed := True; end;
    Check(Failed and (Script.Position = 1) and (Script.Ends = 1), 'Missing app has no version fallback');
  finally Reader.Free; end;
  Writeln('PASS: independent mapping 1/2 and length-last exact transcripts');
end;

constructor TMemoryScript.Create(const ASize, AMLe, AMLc: Integer; const Initial: TBytes);
var I: Integer;
begin
  inherited Create; Version := t4av2; Cc := Capability(ASize, AMLe, AMLc);
  SetLength(FileBytes, ASize); for I := 0 to High(FileBytes) do FileBytes[I] := $A5;
  FileBytes[0] := Length(Initial) shr 8; FileBytes[1] := Length(Initial) and $FF;
  if Length(Initial) > 0 then Move(Initial[0], FileBytes[2], Length(Initial));
  InitialTail := CopyBytes(FileBytes);
end;

procedure TMemoryScript.BeginTransaction;
begin Inc(Begins); if BeginFails then raise ECardTransportError.Create('acquire');
  Check(not Active, 'Non-nested transaction'); Active := True; Selected := 0; end;

procedure TMemoryScript.EndTransaction;
begin Inc(Ends); Check(Active, 'Release owns active transaction'); Active := False;
  if EndFails then raise ECardTransportError.Create('release'); end;

function TMemoryScript.Exchange(const ACommand: TBytes): TBytes;
var C: TApduCommand; Offset, N, I, LengthNow: Integer; Data, Source: TBytes;
begin
  Check(Active, 'Command inside transaction'); Inc(Position);
  I := Length(Commands); SetLength(Commands, I + 1); Commands[I] := CopyBytes(ACommand);
  if Position = FailCommand then raise ECardTransportError.Create('command failure');
  C := TApduCodec.DecodeCommand(ACommand);
  Check((C.CLA = 0) and not C.IsExtended, 'Only short ISO 7816 APDUs'); Data := nil;
  case C.INS of
    $A4:
      begin
        if C.P1 = 4 then
        begin
          if Version = t4av2 then Check(BytesToHex(ACommand) = '00A4040007D276000085010100', 'Explicit v2 application')
          else Check(BytesToHex(ACommand) = '00A4040007D2760000850100', 'Explicit v1 application');
          Selected := 0;
        end
        else
        begin
          Check((C.P1 = 0) and not C.HasLe and (Length(C.Data) = 2), 'Exact ISO file selection');
          if Version = t4av2 then Check(C.P2 = $0C, 'No FCI v2 selection') else Check(C.P2 = 0, 'V1 selection');
          Selected := (Word(C.Data[0]) shl 8) or C.Data[1];
          Check((Selected = $E103) or (Selected = $E104) or (Selected = $E105), 'Known ISO file');
        end;
      end;
    $B0:
      begin
        Inc(Reads); Check(C.HasLe and (Length(C.Data) = 0), 'READ without command data');
        Offset := (Integer(C.P1) shl 8) or C.P2; N := Integer(C.Le);
        if Selected = $E103 then Source := CopyBytes(Cc)
        else begin Check(Selected <> 0, 'Selected NDEF file'); Source := CopyBytes(FileBytes); end;
        Check((N <= ((Integer(Cc[3]) shl 8) or Cc[4])) and (N <= 256), 'MLe respected');
        Check((Offset + N <= Length(Source)) and (Offset < $8000), 'File-bounded read offset');
        if (Selected <> $E103) and (Offset = 0) then
        begin
          Inc(NlenReads);
          if MutateNlen and (NlenReads = 2) then Source[1] := Source[1] xor 1;
        end;
        if (Selected = $E103) and CorruptCc and (Writes > 0) then Source[14] := $FF;
        Data := Copy(Source, Offset, N); if Reads = BadReadAt then SetLength(Data, N - 1);
      end;
    $D6:
      begin
        Inc(Writes); Check((Selected = $E104) or (Selected = $E105), 'Never update CC');
        Check(not C.HasLe, 'UPDATE without Le');
        N := Length(C.Data); Offset := (Integer(C.P1) shl 8) or C.P2;
        Check((N > 0) and (N <= ((Integer(Cc[5]) shl 8) or Cc[6])) and (N <= 255), 'MLc and short Lc respected');
        Check((Offset + N <= Length(FileBytes)) and (Offset < $8000), 'File-bounded update');
        I := Length(UpdateOffsets); SetLength(UpdateOffsets, I + 1); UpdateOffsets[I] := Offset;
        if (Writes = FailWrite) and (RejectStatus <> 0) then
        begin Result := HexToBytes(WordHex(RejectStatus)); Exit; end;
        if not SuppressUpdate then Move(C.Data[0], FileBytes[Offset], N);
        LengthNow := (Integer(FileBytes[0]) shl 8) or FileBytes[1];
        if Offset = 0 then Check((LengthNow = 0) or (LengthNow = FinalLength), 'Only zero or final NLEN is published')
        else Check(LengthNow = 0, 'Payload updates while NLEN is zero');
        if Writes = FailWrite then raise ECardTransportError.Create('ambiguous update containing sensitive fixture');
      end;
  else Check(False, 'No unplanned instruction'); end;
  if OverrideStatus <> 0 then begin Result := HexToBytes(WordHex(OverrideStatus)); Exit; end;
  Result := CopyBytes(Data); SetLength(Result, Length(Data) + 2); Result[Length(Data)] := $90; Result[Length(Data) + 1] := 0;
end;

function TNoTransaction.Exchange(const ACommand: TBytes): TBytes;
begin Result := nil; raise Exception.Create('Must not dispatch without exclusive transaction'); end;

procedure Attach(const Size, MLe, MLc: Integer; const Initial: TBytes;
  out Script: TMemoryScript; out Reader: TType4NdefCardReader);
begin Script := TMemoryScript.Create(Size, MLe, MLc, Initial);
  Reader := TType4NdefCardReader.Create(nil); Reader.Transport := Script; end;

procedure BoundariesAndWrites;
var Script: TMemoryScript; Reader: TType4NdefCardReader; S: TType4NdefSnapshot;
  M: TNdefMessage; Wire, Original: TBytes; Sizes: array[0..5] of Integer;
  I, N, W, EndOffset: Integer;
begin
  Sizes[0] := 0; Sizes[1] := 1; Sizes[2] := 249; Sizes[3] := 255; Sizes[4] := 256; Sizes[5] := 32759;
  for I := 0 to High(Sizes) do
  begin
    M := MessageOf(Sizes[I]); Wire := TNdefCodec.Encode(M);
    Attach(Type4MaxFileBytes, 58, 52, HexToBytes('D00000'), Script, Reader);
    try
      Script.FinalLength := Length(Wire); Reader.MaxReadChunk := 31; Reader.MaxWriteChunk := 29;
      Original := CopyBytes(Script.FileBytes); Reader.WriteMessage(M);
      Check((Script.Begins = 1) and (Script.Ends = 1) and (Script.UpdateOffsets[0] = 0), 'Invalidation inside one operation');
      Check((Script.UpdateOffsets[High(Script.UpdateOffsets)] = 0) and
        (BytesToHex(Copy(Script.FileBytes, 2, Length(Wire))) = BytesToHex(Wire)), 'Final NLEN and payload');
      EndOffset := Length(Wire) + 2;
      Check(BytesEqual(Copy(Script.FileBytes, EndOffset, Length(Original) - EndOffset),
        Copy(Original, EndOffset, Length(Original) - EndOffset)), 'Tail beyond replacement preserved');
      S := Reader.ReadMessage; Check(BytesEqual(S.MessageBytes, Wire), 'MLe segmented read round trip');
      W := Script.Writes; Reader.WriteMessage(M); Check(Script.Writes = W, 'Same message no-op');
      Original := CopyBytes(Script.FileBytes); Script.FinalLength := 0; Reader.ClearMessage;
      Check(BytesEqual(Copy(Original, 2, Length(Original) - 2), Copy(Script.FileBytes, 2, Length(Original) - 2)), 'Clear preserves previous payload');
      S := Reader.ReadMessage; Check(Length(S.Records) = 0, 'NLEN zero is not an empty record');
      W := Script.Writes; Reader.ClearMessage; Check(Script.Writes = W, 'Clear empty file is no-op');
    finally Reader.Free; end;
  end;
  Attach(512, 256, 255, nil, Script, Reader);
  try
    M := MessageOf(300); Wire := TNdefCodec.Encode(M); Script.FinalLength := Length(Wire); Reader.WriteMessage(M);
    Check(Script.UpdateOffsets[0] = 2, 'Already zero NLEN avoids redundant invalidation');
    N := 0; for I := 0 to High(Script.Commands) do
      if (Length(Script.Commands[I]) = 5) and (Script.Commands[I][1] = $B0) and (Script.Commands[I][4] = 0) then Inc(N);
    Check(N > 0, '256-byte READ uses short Le zero');
  finally Reader.Free; end;
  // Discover a whole multi-file CC in MLe-sized chunks, select the requested second file.
  Attach(512, 15, 2, HexToBytes('D00000'), Script, Reader);
  try
    Script.Cc := HexToBytes('001720000F00020406E104010000000406E10502000000');
    S := Reader.ReadMessage($E105); Check(S.FileInfo.FileId = $E105, 'Explicit second file and complete CC');
    Check(BytesToHex(Script.Commands[3]) = '00B0000F08', 'CC remainder honors MLe');
  finally Reader.Free; end;
  Writeln('PASS: full capacity, MLe/MLc/local limits, no-op, clear and multiple files');
end;

procedure Failures;
var Script: TMemoryScript; Reader: TType4NdefCardReader; S: TType4NdefSnapshot;
  Cc: TType4CapabilityContainer; M: TNdefMessage; Initial, Wire: TBytes;
  I, N, TotalCommands, PreflightCommands: Integer; Failed: Boolean;
begin
  Initial := HexToBytes('D00000'); M := MessageOf(70); Wire := TNdefCodec.Encode(M);
  Attach(256, 15, 20, Initial, Script, Reader);
  try Script.FinalLength := Length(Wire); Reader.WriteMessage(M); N := Script.Writes;
    TotalCommands := Script.Position;
    PreflightCommands := 7; // app, CC select/read, NDEF select, NLEN/body/NLEN.
  finally Reader.Free; end;
  for I := 1 to N do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      Script.FinalLength := Length(Wire); Script.FailWrite := I; Script.EndFails := True; Failed := False;
      try Reader.WriteMessage(M); except on E: EContactlessWriteUncertain do
      begin Failed := True; Check(E.OriginalErrorClass = 'ECardTransportError', 'Primary update error wins release'); end; end;
      Check(Failed and (Script.Writes = I) and (Script.Ends = 1), 'Every partial UPDATE stops without retry/rollback');
    finally Reader.Free; end;
  end;
  for I := 0 to 5 do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      Script.FinalLength := Length(Wire);
      case I of
        0: begin Script.FailWrite := 1; Script.RejectStatus := $6982; end;
        1: Script.SuppressUpdate := True;
        2: Script.EndFails := True;
        3: Script.CorruptCc := True;
        4: Script.BadReadAt := 5; // first invalidation read-back, after four preflight reads.
        5: begin Script.FailWrite := 1; Script.RejectStatus := $6C02; end;
      end;
      Failed := False;
      try Reader.WriteMessage(M); except on EContactlessWriteUncertain do Failed := True; end;
      Check(Failed and (Script.Writes > 0) and (Script.Ends = 1), 'Rejected/suppressed/verify/CC/release updates uncertain');
      if I in [0, 1, 4, 5] then Check(Script.Writes = 1, 'No update after failed invalidation verification');
    finally Reader.Free; end;
  end;
  for I := 1 to PreflightCommands do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      Script.FailCommand := I; Script.EndFails := True; Failed := False;
      try Reader.WriteMessage(M); except on ECardTransportError do Failed := True; end;
      Check(Failed and (Script.Writes = 0) and (Script.Position = I) and (Script.Ends = 1), 'Every preflight failure preserves primary, no write');
    finally Reader.Free; end;
  end;
  // Fail each command after invalidation dispatch, including final file selections,
  // CC acquisition, payload verification and final NLEN check.
  for I := PreflightCommands + 2 to TotalCommands do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      Script.FinalLength := Length(Wire); Script.FailCommand := I; Failed := False;
      try Reader.WriteMessage(M); except on EContactlessWriteUncertain do Failed := True; end;
      Check(Failed and (Script.Position = I) and (Script.Ends = 1), 'Every later command failure is uncertain and stops immediately');
    finally Reader.Free; end;
  end;
  for I := 0 to 7 do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      case I of
        0: Script.Cc[14] := $FF;
        1: Script.Cc[14] := $80;
        2: Script.Cc[13] := $80;
        3: Script.Cc[6] := 1;
        4: begin Script.Cc[11] := 0; Script.Cc[12] := 5; end;
        5: Script.FileBytes[0] := $FF;
        6: Script.FileBytes[2] := $D7;
        7: Script.MutateNlen := True;
      end;
      Failed := False;
      try Reader.WriteMessage(M); except on EContactlessError do Failed := True; on ENdefError do Failed := True; end;
      Check(Failed and (Script.Writes = 0) and (Script.Ends = 1), 'Access/MLc/capacity/NLEN/framing/coherence preflight');
    finally Reader.Free; end;
  end;
  for I := 0 to 3 do
  begin
    Attach(256, 15, 20, Initial, Script, Reader);
    try
      case I of
        0: Script.OverrideStatus := $6101;
        1: Script.OverrideStatus := $6C00;
        2: Script.OverrideStatus := $6282;
        3: Script.OverrideStatus := $6A82;
      end;
      Failed := False;
      try S := Reader.ReadMessage; except on EContactlessStatusError do Failed := True; end;
      Check(Failed and (Script.Position = 1) and (Script.Writes = 0), 'Status never replayed/chained or used for application fallback');
    finally Reader.Free; end;
  end;
  Attach(256, 15, 20, Initial, Script, Reader);
  try
    Script.BeginFails := True; Failed := False;
    try Cc := Reader.ReadCapabilities; except on ECardTransportError do Failed := True; end;
    Check(Failed and (Script.Ends = 0) and (Script.Position = 0), 'Failed acquire not released');
  finally Reader.Free; end;
  Attach(256, 15, 20, Initial, Script, Reader);
  try
    Script.EndFails := True; Failed := False;
    try S := Reader.ReadMessage; except on ECardTransportError do Failed := True; end;
    Check(Failed and (Script.Writes = 0), 'No read snapshot after failed release');
  finally Reader.Free; end;
  Reader := TType4NdefCardReader.Create(nil);
  try
    Reader.Transport := TNoTransaction.Create; Failed := False;
    try Cc := Reader.ReadCapabilities; except on EType4NdefError do Failed := True; end;
    Check(Failed, 'Transaction capability is mandatory');
  finally Reader.Free; end;
  Attach(256, 15, 20, Initial, Script, Reader);
  try
    Reader.MaxReadChunk := 14; Failed := False;
    try S := Reader.ReadMessage; except on EType4NdefError do Failed := True; end;
    Check(Failed and (Script.Begins = 0), 'Invalid local limit before I/O');
    Reader.MaxReadChunk := 256; Failed := False;
    try S := Reader.ReadMessage($E103); except on EType4NdefError do Failed := True; end;
    Check(Failed and (Script.Begins = 0), 'CC cannot be selected as an NDEF target');
    Failed := False;
    try Reader.WriteMessage(nil); except on ENdefError do Failed := True; end;
    Check(Failed and (Script.Begins = 0), 'Malformed request before acquisition');
  finally Reader.Free; end;
  Writeln('PASS: preflight/status failures, every partial update and transaction precedence');
end;

begin
  try
    Codec; ExactTranscripts; BoundariesAndWrites; Failures;
    Writeln('PASS: ', Checks, ' assertions in four Type 4 NDEF groups.');
  except on E: Exception do begin Writeln('FAIL: ', E.ClassName, ': ', E.Message); Halt(1); end; end;
end.
