unit untCRC16;

interface

function CalcCRC16(AData: PByte; ASize: Integer): Word;

implementation

function CalcCRC16(AData: PByte; ASize: Integer): Word;
var
  LBitFlag: Boolean;
  LBitsRead: Byte;
  LCRC, I, J: Word;
begin
  Assert((AData <> nil) or (ASize = 0));
  Result := 0;
  LBitsRead := 0;

  while ASize > 0 do
  begin
    LBitFlag := (Result shr 15) <> 0;

    // Get next bit
    Result := Result shl 1;
    Result := Result or ((AData^ shr LBitsRead) and 1); // item a) work from the least significant bits

    // Increment bit counter
    Inc(LBitsRead);
    if LBitsRead > 7 then
    begin
      LBitsRead := 0;
      Inc(AData);
      Dec(ASize);
    end;

    // Cycle check
    if LBitFlag then
      Result := Result xor $8005;
  end;

  // item b) "push out" the last 16 bits
  for I := 0  to 15 do
  begin
    LBitFlag := (Result shr 15) <> 0;
    Result := Result shl 1;
    if LBitFlag then
      Result := Result xor $8005;
  end;

  // item c) reverse the bits
  LCRC := 0;
  I := $8000;
  J := $0001;
  repeat
    if (I and Result) <> 0 then
      LCRC := LCRC or J;
    J := J shl 1;
    I := I shr 1;
  until I = 0;
  Result := LCRC;
end;

end.
