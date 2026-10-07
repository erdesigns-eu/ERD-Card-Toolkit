program CardCoreTests;

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
  ERD.Card.Bytes,
  ERD.Card.APDU;

var
  Checks: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestHex;
var
  Bytes: TBytes;
  Other: TBytes;
  Offset: Integer;
  I: Integer;
  Raised: Boolean;
begin
  Check(TryHexToBytes('', Bytes, Offset), 'Empty hexadecimal input');
  Check((Length(Bytes) = 0) and (Offset = 0), 'Empty hexadecimal outputs');
  Check(TryHexToBytes('00aAfF', Bytes, Offset), 'Mixed hexadecimal case');
  Check(BytesToHex(Bytes) = '00AAFF', 'Uppercase hexadecimal output');
  Check(BytesToHex(Bytes, False) = '00aaff', 'Lowercase hexadecimal output');
  Check(not TryHexToBytes('0G', Bytes, Offset), 'Invalid character rejected');
  Check((Offset = 2) and (Length(Bytes) = 0), 'Invalid input clears output');
  Check(not TryHexToBytes('ABC', Bytes, Offset), 'Odd hexadecimal length rejected');
  Check(Offset = 3, 'Unmatched digit offset');
  Check(not TryHexToBytes('AA BB', Bytes, Offset), 'Whitespace rejected by default');
  Check(Offset = 3, 'Whitespace error offset');
  Check(TryHexToBytes(' A'#9'A '#13#10'bb ', Bytes, Offset, True), 'Explicit ASCII whitespace');
  Check(BytesToHex(Bytes) = 'AABB', 'Whitespace conversion');
  Check(not TryHexToBytes(' A ', Bytes, Offset, True), 'Odd input after whitespace');
  Check((Offset = 2) and (Length(Bytes) = 0), 'Unmatched digit before trailing whitespace');
  Check(not TryHexToBytes('AA'#$00A0'BB', Bytes, Offset, True), 'Non-ASCII whitespace rejected');
  Check(Offset = 3, 'Non-ASCII offset');
  Check(TryHexToBytes(#9#13#10' ', Bytes, Offset, True), 'Whitespace-only input is empty');
  Check(Length(Bytes) = 0, 'Whitespace-only output');

  SetLength(Bytes, 256);
  for I := 0 to 255 do
    Bytes[I] := Byte(I);
  Other := HexToBytes(BytesToHex(Bytes));
  Check(BytesEqual(Bytes, Other), 'All 256 byte values round-trip');
  Other := CopyBytes(Bytes);
  Other[0] := $FF;
  Check(Bytes[0] = 0, 'Byte copies do not share mutable buffers');
  Check(not BytesEqual(Bytes, Other), 'Different bytes compare unequal');
  SetLength(Other, 255);
  Check(not BytesEqual(Bytes, Other), 'Different lengths compare unequal');
  Bytes := nil;
  Other := nil;
  Check(BytesEqual(Bytes, Other), 'Two empty arrays compare equal');

  Raised := False;
  try
    Bytes := HexToBytes('0G');
  except
    on E: EHexFormatError do
    begin
      Raised := True;
      Check(E.Offset = 2, 'Hex exception offset');
      Check(Pos('0G', E.Message) = 0, 'Hex exception excludes input contents');
    end;
  end;
  Check(Raised, 'Hex decoding throws the documented exception');
end;

procedure CommandVector(const AHex: string; const ADataHex: string;
  const ALe: Cardinal; const AExtended: Boolean);
var
  Command: TApduCommand;
  Wire: TBytes;
  Error: TApduError;
begin
  Wire := HexToBytes(AHex);
  Check(TApduCodec.TryDecodeCommand(Wire, Command, Error), 'Command vector: ' + AHex);
  Check((Error.Code = aecNone) and (Error.Offset = -1), 'Successful command error state');
  Check(BytesToHex(Command.Data) = ADataHex, 'Command data excludes Le');
  Check(Command.HasLe = (ALe <> 0), 'Le presence');
  Check(Command.Le = ALe, 'Semantic Le value');
  Check(Command.IsExtended = AExtended, 'Length encoding preserved');
  Check(BytesEqual(TApduCodec.EncodeCommand(Command), Wire), 'Command wire round-trip');
end;

procedure TestCommandVectors;
begin
  CommandVector('12345678', '', 0, False);
  CommandVector('1234567801', '', 1, False);
  CommandVector('1234567800', '', 256, False);
  CommandVector('1234567802AABB', 'AABB', 0, False);
  CommandVector('1234567802AABB01', 'AABB', 1, False);
  CommandVector('0000000002AABB00', 'AABB', 256, False);
  CommandVector('12345678000001', '', 1, True);
  CommandVector('12345678000100', '', 256, True);
  CommandVector('12345678000000', '', 65536, True);
  CommandVector('12345678000002AABB', 'AABB', 0, True);
  CommandVector('12345678000002AABB0001', 'AABB', 1, True);
  CommandVector('12345678000002AABB0000', 'AABB', 65536, True);
end;

procedure InvalidCommand(const AHex: string; const ACode: TApduErrorCode;
  const AOffset: Integer);
var
  Command: TApduCommand;
  Error: TApduError;
  Raised: Boolean;
begin
  Command := TApduCodec.DecodeCommand(HexToBytes('1234567802AABB01'));
  Check(not TApduCodec.TryDecodeCommand(HexToBytes(AHex), Command, Error), 'Invalid command rejected');
  Check((Error.Code = ACode) and (Error.Offset = AOffset), 'Invalid command category and offset');
  Check((Command.CLA = 0) and (Command.INS = 0) and (Command.P1 = 0) and
    (Command.P2 = 0) and (Length(Command.Data) = 0) and (not Command.HasLe) and
    (Command.Le = 0) and (not Command.IsExtended), 'Failure clears all command fields');
  Raised := False;
  try
    Command := TApduCodec.DecodeCommand(HexToBytes(AHex));
  except
    on E: EApduFormatError do
    begin
      Raised := True;
      Check((E.Error.Code = ACode) and (E.Error.Offset = AOffset), 'Exception retains structured error');
    end;
  end;
  Check(Raised, 'Strict command decoder raises');
end;

procedure TestInvalidCommands;
begin
  InvalidCommand('', aecHeaderTruncated, 0);
  InvalidCommand('00', aecHeaderTruncated, 1);
  InvalidCommand('0000', aecHeaderTruncated, 2);
  InvalidCommand('000000', aecHeaderTruncated, 3);
  InvalidCommand('0000000002AA', aecDataLengthMismatch, 6);
  InvalidCommand('0000000001AABBCC', aecDataLengthMismatch, 7);
  InvalidCommand('000000000000', aecLengthTruncated, 6);
  InvalidCommand('00000000000000AA', aecInvalidCommand, 5);
  InvalidCommand('00000000000002AA', aecDataLengthMismatch, 8);
  InvalidCommand('00000000000002AABB00', aecLengthTruncated, 10);
  InvalidCommand('00000000000001AABBCCDD', aecDataLengthMismatch, 10);
end;

procedure RejectEncoding(const ACommand: TApduCommand);
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TApduCodec.EncodeCommand(ACommand);
  except
    on E: EApduFormatError do
    begin
      Raised := True;
      Check((E.Error.Code = aecInvalidCommand) and (E.Error.Offset = -1), 'Invalid record error');
    end;
  end;
  Check(Raised, 'Invalid command record rejected');
end;

procedure TestInvalidRecords;
var
  Command: TApduCommand;
  Wire: TBytes;
  Error: TApduError;
begin
  Command := Default(TApduCommand);
  Command.Le := 1;
  RejectEncoding(Command);
  Command.HasLe := True;
  Command.Le := 0;
  RejectEncoding(Command);
  Command.Le := 257;
  RejectEncoding(Command);
  Command.IsExtended := True;
  Command.Le := 65537;
  RejectEncoding(Command);
  Command.HasLe := False;
  Command.Le := 0;
  RejectEncoding(Command);
  Command.IsExtended := False;
  SetLength(Command.Data, 256);
  RejectEncoding(Command);
  Command.IsExtended := True;
  SetLength(Command.Data, 65536);
  RejectEncoding(Command);
  SetLength(Wire, ApduMaxExtendedDataLength + 10);
  Check(not TApduCodec.TryDecodeCommand(Wire, Command, Error), 'Oversized command rejected before parsing');
  Check((Error.Code = aecDataLengthMismatch) and
    (Error.Offset = ApduMaxExtendedDataLength + 9), 'Oversized command offset');
  Check(Length(Command.Data) = 0, 'Oversized command clears old output');
end;

procedure TestCommandBoundaries;
const
  DataSizes: array[0..7] of Integer = (0, 1, 2, 127, 128, 255, 256, 65535);
  LeValues: array[0..6] of Cardinal = (0, 1, 255, 256, 257, 65535, 65536);
var
  Command: TApduCommand;
  Decoded: TApduCommand;
  Wire: TBytes;
  D: Integer;
  L: Integer;
  X: Integer;
  I: Integer;
begin
  for X := 0 to 1 do
    for D := Low(DataSizes) to High(DataSizes) do
      for L := Low(LeValues) to High(LeValues) do
      begin
        if (X = 0) and ((DataSizes[D] > 255) or (LeValues[L] > 256)) then
          Continue;
        if (X = 1) and (DataSizes[D] = 0) and (LeValues[L] = 0) then
          Continue;
        Command := Default(TApduCommand);
        Command.CLA := $12;
        Command.INS := $34;
        Command.P1 := $56;
        Command.P2 := $78;
        Command.IsExtended := X = 1;
        Command.HasLe := LeValues[L] <> 0;
        Command.Le := LeValues[L];
        SetLength(Command.Data, DataSizes[D]);
        for I := 0 to Length(Command.Data) - 1 do
          Command.Data[I] := Byte(I and $FF);
        Wire := TApduCodec.EncodeCommand(Command);
        Decoded := TApduCodec.DecodeCommand(Wire);
        Check((Decoded.CLA = $12) and (Decoded.INS = $34) and
          (Decoded.P1 = $56) and (Decoded.P2 = $78), 'Header bytes preserved');
        Check(BytesEqual(Decoded.Data, Command.Data), 'Boundary command data');
        Check((Decoded.HasLe = Command.HasLe) and (Decoded.Le = Command.Le) and
          (Decoded.IsExtended = Command.IsExtended), 'Boundary command lengths');
        Check(BytesEqual(TApduCodec.EncodeCommand(Decoded), Wire), 'Boundary wire stability');
      end;
end;

procedure TestOwnershipAndReuse;
var
  Command: TApduCommand;
  Response: TApduResponse;
  Wire: TBytes;
  Encoded: TBytes;
begin
  Wire := HexToBytes('1234567802AABB01');
  Command := TApduCodec.DecodeCommand(Wire);
  Wire[5] := 0;
  Check(BytesToHex(Command.Data) = 'AABB', 'Decoded command does not share input data');
  Encoded := TApduCodec.EncodeCommand(Command);
  Command.Data[0] := 0;
  Check(Encoded[5] = $AA, 'Encoded command does not share record data');
  Command := TApduCodec.DecodeCommand(HexToBytes('00000000'));
  Check((Length(Command.Data) = 0) and (not Command.HasLe) and
    (Command.Le = 0), 'A following header-only decode has no stale state');
  Wire := HexToBytes('AABB9000');
  Response := TApduCodec.DecodeResponse(Wire);
  Wire[0] := 0;
  Check(BytesToHex(Response.Data) = 'AABB', 'Decoded response does not share input data');
  Encoded := TApduCodec.EncodeResponse(Response);
  Response.Data[0] := 0;
  Check(Encoded[0] = $AA, 'Encoded response does not share record data');
end;

procedure TestResponses;
var
  Response: TApduResponse;
  Error: TApduError;
  Wire: TBytes;
  I: Integer;
  Raised: Boolean;
begin
  Response := TApduCodec.DecodeResponse(HexToBytes('9000'));
  Check((Length(Response.Data) = 0) and (Response.StatusWord = ApduStatusSuccess), 'Status-only response');
  Response := TApduCodec.DecodeResponse(HexToBytes('AABB6A82'));
  Check((BytesToHex(Response.Data) = 'AABB') and (Response.StatusWord = $6A82), 'Error status is syntactically valid');
  Check(BytesToHex(TApduCodec.EncodeResponse(Response)) = 'AABB6A82', 'Response wire round-trip');
  Check(not TApduCodec.TryDecodeResponse(nil, Response, Error), 'Empty response rejected');
  Check((Error.Code = aecResponseTruncated) and (Error.Offset = 0), 'Empty response error');
  Check((Length(Response.Data) = 0) and (Response.StatusWord = 0), 'Failure clears response');
  Check(not TApduCodec.TryDecodeResponse(HexToBytes('90'), Response, Error), 'One status byte rejected');
  Check((Error.Code = aecResponseTruncated) and (Error.Offset = 1), 'Single byte response offset');
  SetLength(Response.Data, 65536);
  for I := 0 to High(Response.Data) do
    Response.Data[I] := Byte(I and $FF);
  Response.StatusWord := $6100;
  Wire := TApduCodec.EncodeResponse(Response);
  Check(Length(Wire) = 65538, 'Maximum response wire length');
  Response := TApduCodec.DecodeResponse(Wire);
  Check((Length(Response.Data) = 65536) and (Response.StatusWord = $6100), 'Maximum response decoded');
  Check(BytesEqual(TApduCodec.EncodeResponse(Response), Wire), 'Maximum response round-trip');
  SetLength(Wire, 65539);
  Check(not TApduCodec.TryDecodeResponse(Wire, Response, Error), 'Oversized wire response rejected');
  Check((Error.Code = aecResponseTooLong) and (Length(Response.Data) = 0), 'Oversized response error');
  Check(Error.Offset = 65538, 'Oversized response offset is the first excess byte');
  SetLength(Response.Data, 65537);
  Raised := False;
  try
    Wire := TApduCodec.EncodeResponse(Response);
  except
    on E: EApduFormatError do
    begin
      Raised := True;
      Check((E.Error.Code = aecResponseTooLong) and (E.Error.Offset = -1), 'Oversized response record error');
    end;
  end;
  Check(Raised, 'Oversized response encoding raises');
  Raised := False;
  try
    Response := TApduCodec.DecodeResponse(nil);
  except
    on E: EApduFormatError do
      Raised := E.Error.Code = aecResponseTruncated;
  end;
  Check(Raised, 'Strict response decoding raises');
end;

begin
  try
    TestHex;
    TestCommandVectors;
    TestInvalidCommands;
    TestInvalidRecords;
    TestCommandBoundaries;
    TestOwnershipAndReuse;
    TestResponses;
    Writeln('PASS: ', Checks, ' assertions across 7 test groups.');
  except
    on E: Exception do
    begin
      Writeln('FAIL after ', Checks, ' assertions: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
