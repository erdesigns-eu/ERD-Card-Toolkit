unit ERD.Card.EMV.Data;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Malformed or unsupported EMV application data; messages contain no account or card data.</summary>
  EEmvDataError = class(EConvertError);
  /// <summary>Standard payment application directories.</summary>
  TEmvDirectory = (
    /// <summary>Contact PSE: 1PAY.SYS.DDF01, with an SFI record directory.</summary>
    edContactPse,
    /// <summary>Contactless PPSE: 2PAY.SYS.DDF01, with application templates in the FCI.</summary>
    edContactlessPpse);

  /// <summary>A directory entry without application selection or payment execution.</summary>
  TEmvApplicationInfo = record
    /// <summary>Exact application identifier, 5..16 bytes.</summary>
    Aid: TBytes;
    /// <summary>Tag 50 application label rendered byte-for-byte as Latin-1, or empty when absent.</summary>
    LabelText: UnicodeString;
    /// <summary>Whether the application priority indicator tag 87 exists.</summary>
    HasPriority: Boolean;
    /// <summary>Priority 0..15; zero means no assigned priority.</summary>
    Priority: Byte;
    /// <summary>Bit 8 of tag 87; user confirmation is required before payment selection.</summary>
    ConfirmationRequired: Boolean;
  end;

  /// <summary>Discovered applications in directory order; no implicit preference is selected.</summary>
  TEmvApplications = array of TEmvApplicationInfo;

  /// <summary>Directory discovery result; absence differs from an existing empty directory.</summary>
  TEmvDirectoryData = record
    /// <summary>The directory requested by the caller.</summary>
    Directory: TEmvDirectory;
    /// <summary>False only when SELECT returns 6A82; other failures raise.</summary>
    Present: Boolean;
    /// <summary>Exact directory FCI bytes without SW1/SW2, or empty when absent.</summary>
    Fci: TBytes;
    /// <summary>Independent application entries in directory order.</summary>
    Applications: TEmvApplications;
  end;

  /// <summary>A primitive EMV tag and byte value for terminal inputs or collected card fields.</summary>
  TEmvValue = record
    /// <summary>Complete encoded tag identifier, at most three bytes.</summary>
    Tag: TBytes;
    /// <summary>Exact bytes; never hexadecimal text or a borrowed TLV buffer.</summary>
    Value: TBytes;
  end;

  /// <summary>Tag/value entries; terminal inputs require unique tags, card fields may repeat.</summary>
  TEmvValues = array of TEmvValue;
  /// <summary>Explicitly supported optional GET DATA objects; no PIN verification is performed.</summary>
  TEmvDataObject = (
    /// <summary>Application Transaction Counter, tag 9F36, two bytes.</summary>
    edoAtc,
    /// <summary>Last Online ATC Register, tag 9F13, two bytes.</summary>
    edoLastOnlineAtc,
    /// <summary>Remaining offline PIN attempts, tag 9F17, one byte.</summary>
    edoPinTryCounter,
    /// <summary>Transaction log data-object list, tag 9F4F.</summary>
    edoLogFormat);

  /// <summary>Optional GET DATA result with an explicit absence/unsupported status.</summary>
  TEmvDataObjectResult = record
    /// <summary>Requested object.</summary>
    DataObject: TEmvDataObject;
    /// <summary>True only for a validated 9000 response.</summary>
    Present: Boolean;
    /// <summary>9000, or an accepted 6A88/6A81/6D00 absence/unsupported status.</summary>
    StatusWord: Word;
    /// <summary>Complete response object, including tag and length but without status bytes.</summary>
    RawData: TBytes;
    /// <summary>Independent object value, or empty when unavailable.</summary>
    Value: TBytes;
    /// <summary>True only for a present ATC, Last Online ATC or PIN counter.</summary>
    HasNumericValue: Boolean;
    /// <summary>Unsigned big-endian counter; meaningful only when HasNumericValue is true.</summary>
    NumericValue: Word;
  end;

  /// <summary>One cyclic transaction-log record; values are not BER-TLV encoded.</summary>
  TEmvLogRecord = record
    /// <summary>Record number, starting at one for the most recent entry.</summary>
    Number: Byte;
    /// <summary>Independent concatenated value bytes without status words.</summary>
    RawData: TBytes;
    /// <summary>Decoded values in Log Format order, retaining repeated and unknown tags.</summary>
    Fields: TEmvValues;
  end;

  /// <summary>Transaction-log records in newest-first order.</summary>
  TEmvLogRecords = array of TEmvLogRecord;

  /// <summary>Complete optional card transaction-log snapshot; not a payment authorization result.</summary>
  /// <remarks>Ordinary record assignment shares arrays. Log availability and contents are issuer dependent.</remarks>
  TEmvTransactionLogData = record
    /// <summary>True when the selected FCI advertises Log Entry 9F4D.</summary>
    Supported: Boolean;
    /// <summary>Exact selected application FCI without status bytes.</summary>
    Fci: TBytes;
    /// <summary>Log file SFI, 11..30 when supported.</summary>
    Sfi: Byte;
    /// <summary>Advertised maximum record count, 1..255 when supported.</summary>
    MaximumRecords: Byte;
    /// <summary>Independent Log Format 9F4F value, empty when unsupported.</summary>
    LogFormat: TBytes;
    /// <summary>All existing records up to the advertised maximum; no partial snapshot on failure.</summary>
    Records: TEmvLogRecords;
  end;

  /// <summary>One data-object-list request, whose length is a single byte rather than BER length encoding.</summary>
  TEmvDolEntry = record
    /// <summary>Requested primitive terminal tag.</summary>
    Tag: TBytes;
    /// <summary>Requested terminal-value size in bytes, including a possible zero length.</summary>
    Size: Byte;
  end;

  /// <summary>DOL requests in card-provided order, including repeated requests.</summary>
  TEmvDolEntries = array of TEmvDolEntry;

  /// <summary>One validated Application File Locator entry.</summary>
  TEmvAflEntry = record
    /// <summary>Short file identifier, 1..30.</summary>
    Sfi: Byte;
    /// <summary>First record number, 1..255.</summary>
    FirstRecord: Byte;
    /// <summary>Last record number, not below FirstRecord.</summary>
    LastRecord: Byte;
    /// <summary>Number of initial records used for offline authentication; no authentication is performed here.</summary>
    OfflineAuthRecords: Byte;
  end;

  /// <summary>Validated AFL entries; overlapping record ranges are rejected.</summary>
  TEmvAfl = array of TEmvAflEntry;

  /// <summary>One successfully read application record.</summary>
  TEmvRecord = record
    /// <summary>Source short file identifier.</summary>
    Sfi: Byte;
    /// <summary>Source record number.</summary>
    Number: Byte;
    /// <summary>Independent complete record bytes without SW1/SW2; issuer records may be opaque.</summary>
    RawData: TBytes;
  end;

  /// <summary>Read records in AFL order.</summary>
  TEmvRecords = array of TEmvRecord;

  /// <summary>Outcome of one additional caller-requested record probe.</summary>
  TEmvRecordProbe = record
    /// <summary>Requested short file identifier, 1..30.</summary>
    Sfi: Byte;
    /// <summary>Requested absolute record, 1..255.</summary>
    Number: Byte;
    /// <summary>Card status: 9000 read, 6A82/6A83 absent, 6982/6985 access or state restricted.</summary>
    StatusWord: Word;
  end;

  /// <summary>Additional probes in ascending SFI and record order; advertised records are not probed twice.</summary>
  TEmvRecordProbes = array of TEmvRecordProbe;

  /// <summary>Complete data result from one selected application.</summary>
  /// <remarks>Fields are optional; an IBAN is not guaranteed. Ordinary record assignment
  /// shares arrays. No issuer lookup, account ownership or cryptographic authenticity
  /// is inferred. The reader executes GPO initialization but no payment cryptogram.</remarks>
  TEmvApplicationData = record
    /// <summary>Selected application's exact AID and FCI label/priority.</summary>
    ApplicationInfo: TEmvApplicationInfo;
    /// <summary>Exact application FCI without status bytes.</summary>
    Fci: TBytes;
    /// <summary>Exact GET PROCESSING OPTIONS response data.</summary>
    Gpo: TBytes;
    /// <summary>The two-byte application interchange profile.</summary>
    Aip: TBytes;
    /// <summary>Validated application file locator.</summary>
    Afl: TEmvAfl;
    /// <summary>All successfully requested records; no partial result is returned on failure.</summary>
    Records: TEmvRecords;
    /// <summary>Optional extra range-scan outcomes; empty for a normal AFL-only read.</summary>
    Probes: TEmvRecordProbes;
    /// <summary>Primitive fields from FCI, GPO and BER record templates, retaining unknown and repeated tags.</summary>
    Fields: TEmvValues;
    /// <summary>PAN digits from tag 5A or Track 2 tag 57, preserving leading zeroes; empty when absent.</summary>
    Pan: UnicodeString;
    /// <summary>Tag 5F24 expiry as YYMMDD without inferred century; empty when absent.</summary>
    ExpiryDate: UnicodeString;
    /// <summary>Expiry YYMM from tag 5F24 or Track 2, without inventing a day or century.</summary>
    ExpiryMonth: UnicodeString;
    /// <summary>Three-digit service code from Track 2, or empty when absent.</summary>
    ServiceCode: UnicodeString;
    /// <summary>Tag 5F20 cardholder name rendered byte-for-byte as Latin-1; empty when absent.</summary>
    CardholderName: UnicodeString;
    /// <summary>Tag 5F53 text, when present; its checksum/account status is not verified.</summary>
    Iban: UnicodeString;
    /// <summary>Independent tag 57 Track 2 equivalent data, or empty; not a magstripe wire format.</summary>
    Track2Equivalent: TBytes;
  end;

  /// <summary>Stateless DOL, AFL, transaction-log and optional card-field decoding with explicit bounds.</summary>
  TEmvCodec = class
  public
    /// <summary>Validates a transaction-log DOL and computes its concatenated record size.</summary>
    /// <param name="AFormat">Log Format 9F4F value, at most 252 bytes.</param>
    /// <returns>Required record length, 1..256 bytes.</returns>
    /// <exception cref="EEmvDataError">The DOL is invalid or its total size is outside the supported bound.</exception>
    class function LogRecordSize(const AFormat: TBytes): Integer; static;
    /// <summary>Splits concatenated transaction-log values using a card-provided DOL.</summary>
    /// <param name="AFormat">Log Format 9F4F value, at most 252 bytes; repeated tags are retained.</param>
    /// <param name="ARecord">Exact concatenated values, 1..256 bytes; no outer 70 template.</param>
    /// <returns>Independent tags and values in format order.</returns>
    /// <exception cref="EEmvDataError">The format is invalid or empty, total length exceeds 256, or record size differs.</exception>
    /// <remarks>No amount, date, currency or successful-payment interpretation is inferred.</remarks>
    class function DecodeLogRecord(const AFormat, ARecord: TBytes)
      : TEmvValues; static;
    /// <summary>Parses primitive EMV tags followed by one-byte requested sizes.</summary>
    /// <param name="ABytes">A PDOL value, at most 252 bytes; empty is allowed.</param>
    /// <returns>Independent requests in original order.</returns>
    /// <exception cref="EEmvDataError">Tags, lengths or the input bound are invalid.</exception>
    class function DecodeDol(const ABytes: TBytes): TEmvDolEntries; static;
    /// <summary>Builds GPO data object 83 from explicitly supplied terminal values.</summary>
    /// <param name="ADol">Card-provided PDOL bytes; empty produces 8300.</param>
    /// <param name="AValues">Unique valid tags with exactly matching value sizes; extra values are allowed.</param>
    /// <returns>Independent encoded 83 object fitting short APDU Lc, at most 255 bytes.</returns>
    /// <exception cref="EEmvDataError">A requested value is missing, ambiguous, wrong-sized or exceeds short-APDU capacity.</exception>
    /// <remarks>No capabilities, country, currency, amounts or unpredictable numbers are fabricated.</remarks>
    class function BuildDolData(const ADol: TBytes; const AValues: TEmvValues)
      : TBytes; static;
    /// <summary>Validates file/record ranges, offline-authentication counts and cumulative bounds.</summary>
    /// <param name="ABytes">AFL bytes, at most 252 and a multiple of four; empty is permitted.</param>
    /// <param name="AMaxRecords">Maximum total requested records, 1..1024.</param>
    /// <returns>Independent AFL entries; no overlapping file/record pair.</returns>
    /// <exception cref="EEmvDataError">A field, overlap or bound is invalid.</exception>
    class function DecodeAfl(const ABytes: TBytes;
      const AMaxRecords: Integer = 256): TEmvAfl; static;
    /// <summary>Copies one optional tag, accepting equal repeats and rejecting conflicting values.</summary>
    /// <param name="AFields">Collected primitive card fields.</param>
    /// <param name="ATag">Complete encoded tag to look up.</param>
    /// <returns>Independent value bytes; empty when absent or empty.</returns>
    /// <exception cref="EEmvDataError">Repeated copies of the tag disagree.</exception>
    class function ConsistentValue(const AFields: TEmvValues;
      const ATag: TBytes): TBytes; static;
    /// <summary>Validates and extracts optional PAN, expiry, name, IBAN and Track 2 values.</summary>
    /// <param name="AData">Snapshot whose Fields have been populated; convenient values are overwritten and may change before an error.</param>
    /// <exception cref="EEmvDataError">Known field encodings, lengths or repeated values are inconsistent.</exception>
    /// <remarks>Track 2 is also preserved as bytes; duplicate PAN/expiry sources must agree.
    /// Missing values stay empty; neither Luhn,
    /// IBAN checksum, expiry calendar validity nor issuer ownership is asserted.</remarks>
    class procedure DecodeCardFields(var AData: TEmvApplicationData); static;
  end;

implementation

uses ERD.Card.Bytes;

function LogSize(const AEntries: TEmvDolEntries): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(AEntries) - 1 do
    Inc(Result, AEntries[I].Size);
  if (Result < 1) or (Result > 256) then
    raise EEmvDataError.Create('Invalid EMV log format size.');
end;

class function TEmvCodec.LogRecordSize(const AFormat: TBytes): Integer;
begin
  Result := LogSize(DecodeDol(AFormat));
end;

class function TEmvCodec.DecodeLogRecord(const AFormat, ARecord: TBytes)
  : TEmvValues;
var
  Entries: TEmvDolEntries;
  I, Size, Offset: Integer;
begin
  Result := nil;
  Entries := DecodeDol(AFormat);
  Size := LogSize(Entries);
  if Length(ARecord) <> Size then
    raise EEmvDataError.Create('Invalid EMV log record size.');
  SetLength(Result, Length(Entries));
  Offset := 0;
  for I := 0 to Length(Entries) - 1 do
  begin
    Result[I].Tag := CopyBytes(Entries[I].Tag);
    Result[I].Value := Copy(ARecord, Offset, Entries[I].Size);
    Inc(Offset, Entries[I].Size);
  end;
end;

procedure Fail(const AReason: string);
begin
  raise EEmvDataError.Create('Invalid EMV data: ' + AReason + '.');
end;

function ReadTag(const ABytes: TBytes; var AOffset: Integer): TBytes;
var
  Start: Integer;
  B: Byte;
begin
  Result := nil;
  if AOffset >= Length(ABytes) then
    Fail('missing tag');
  Start := AOffset;
  B := ABytes[AOffset];
  Inc(AOffset);
  if (B = 0) or (B = $FF) or ((B and $20) <> 0) then
    Fail('primitive tag');
  if (B and $1F) = $1F then
  begin
    repeat
      if (AOffset >= Length(ABytes)) or (AOffset - Start >= 3) then
        Fail('tag length');
      B := ABytes[AOffset];
      if (AOffset = Start + 1) and ((B and $7F) = 0) then
        Fail('tag encoding');
      Inc(AOffset);
    until (B and $80) = 0;
  end;
  Result := Copy(ABytes, Start, AOffset - Start);
end;

class function TEmvCodec.DecodeDol(const ABytes: TBytes): TEmvDolEntries;
var
  Offset, Index: Integer;
  Tag: TBytes;
begin
  Result := nil;
  if Length(ABytes) > 252 then
    Fail('DOL limit');
  Offset := 0;
  while Offset < Length(ABytes) do
  begin
    Tag := ReadTag(ABytes, Offset);
    if Offset >= Length(ABytes) then
      Fail('DOL size missing');
    Index := Length(Result);
    SetLength(Result, Index + 1);
    Result[Index].Tag := Tag;
    Result[Index].Size := ABytes[Offset];
    Inc(Offset);
  end;
end;

class function TEmvCodec.BuildDolData(const ADol: TBytes;
  const AValues: TEmvValues): TBytes;
var
  Entries: TEmvDolEntries;
  Buffer, Tag: TBytes;
  Offset, I, J, K, Found, Size: Integer;
begin
  Result := nil;
  Buffer := nil;
  Entries := DecodeDol(ADol);
  if Length(AValues) > 256 then
    Fail('terminal value count');
  for I := 0 to Length(AValues) - 1 do
  begin
    Offset := 0;
    Tag := ReadTag(AValues[I].Tag, Offset);
    if Offset <> Length(AValues[I].Tag) then
      Fail('terminal tag');
    for J := 0 to I - 1 do
      if BytesEqual(Tag, AValues[J].Tag) then
        Fail('duplicate terminal tag');
  end;
  Size := 0;
  for I := 0 to Length(Entries) - 1 do
  begin
    if Entries[I].Size > 252 - Size then
      Fail('GPO data limit');
    Inc(Size, Entries[I].Size);
  end;
  SetLength(Buffer, Size);
  Offset := 0;
  for I := 0 to Length(Entries) - 1 do
  begin
    Found := -1;
    for J := 0 to Length(AValues) - 1 do
      if BytesEqual(Entries[I].Tag, AValues[J].Tag) then
        Found := J;
    if Found < 0 then
    begin
      if Entries[I].Size = 0 then
        Continue;
      Fail('terminal value missing');
    end;
    if Length(AValues[Found].Value) <> Entries[I].Size then
      Fail('terminal value size');
    for K := 0 to Entries[I].Size - 1 do
      Buffer[Offset + K] := AValues[Found].Value[K];
    Inc(Offset, Entries[I].Size);
  end;
  if Size < 128 then
  begin
    SetLength(Result, Size + 2);
    Result[0] := $83;
    Result[1] := Byte(Size);
    Offset := 2;
  end
  else
  begin
    SetLength(Result, Size + 3);
    Result[0] := $83;
    Result[1] := $81;
    Result[2] := Byte(Size);
    Offset := 3;
  end;
  for I := 0 to Size - 1 do
    Result[Offset + I] := Buffer[I];
end;

class function TEmvCodec.DecodeAfl(const ABytes: TBytes;
  const AMaxRecords: Integer): TEmvAfl;
var
  I, J, Count, Total: Integer;
begin
  Result := nil;
  if (AMaxRecords < 1) or (AMaxRecords > 1024) or (Length(ABytes) > 252) or
    (Length(ABytes) mod 4 <> 0) then
    Fail('AFL limit');
  Count := Length(ABytes) div 4;
  SetLength(Result, Count);
  Total := 0;
  for I := 0 to Count - 1 do
  begin
    if (ABytes[I * 4] and 7) <> 0 then
      Fail('AFL reserved bits');
    Result[I].Sfi := ABytes[I * 4] shr 3;
    Result[I].FirstRecord := ABytes[I * 4 + 1];
    Result[I].LastRecord := ABytes[I * 4 + 2];
    Result[I].OfflineAuthRecords := ABytes[I * 4 + 3];
    if (Result[I].Sfi < 1) or (Result[I].Sfi > 30) or
      (Result[I].FirstRecord = 0) or
      (Result[I].LastRecord < Result[I].FirstRecord) then
      Fail('AFL record range');
    J := Integer(Result[I].LastRecord) - Result[I].FirstRecord + 1;
    if Result[I].OfflineAuthRecords > J then
      Fail('AFL authentication count');
    Inc(Total, J);
    if Total > AMaxRecords then
      Fail('AFL record limit');
    for J := 0 to I - 1 do
      if (Result[I].Sfi = Result[J].Sfi) and
        (Result[I].FirstRecord <= Result[J].LastRecord) and
        (Result[J].FirstRecord <= Result[I].LastRecord) then
        Fail('overlapping AFL records');
  end;
end;

class function TEmvCodec.ConsistentValue(const AFields: TEmvValues;
  const ATag: TBytes): TBytes;
var
  I: Integer;
  Found: Boolean;
begin
  Result := nil;
  Found := False;
  for I := 0 to Length(AFields) - 1 do
    if BytesEqual(AFields[I].Tag, ATag) then
    begin
      if Found and not BytesEqual(Result, AFields[I].Value) then
        Fail('conflicting card fields');
      if not Found then
        Result := CopyBytes(AFields[I].Value);
      Found := True;
    end;
end;

function DecimalText(const ABytes: TBytes; const AAllowPadding: Boolean)
  : UnicodeString;
var
  I, Digit, Count: Integer;
begin
  Result := '';
  SetLength(Result, Length(ABytes) * 2);
  Count := 0;
  for I := 0 to Length(ABytes) * 2 - 1 do
  begin
    if I mod 2 = 0 then
      Digit := ABytes[I div 2] shr 4
    else
      Digit := ABytes[I div 2] and $0F;
    if (Digit = 15) and AAllowPadding and (I = Length(ABytes) * 2 - 1) then
      Break;
    if Digit > 9 then
      Fail('decimal field encoding');
    Inc(Count);
    Result[Count] := WideChar(Ord('0') + Digit);
  end;
  SetLength(Result, Count);
end;

function LatinText(const ABytes: TBytes): UnicodeString;
var
  I: Integer;
begin
  Result := '';
  SetLength(Result, Length(ABytes));
  for I := 0 to Length(ABytes) - 1 do
    Result[I + 1] := WideChar(ABytes[I]);
end;

function Track2Text(const ABytes: TBytes): UnicodeString;
var
  I, Nibble, Count: Integer;
begin
  Result := '';
  SetLength(Result, Length(ABytes) * 2);
  Count := 0;
  for I := 0 to Length(ABytes) * 2 - 1 do
  begin
    if I mod 2 = 0 then
      Nibble := ABytes[I div 2] shr 4
    else
      Nibble := ABytes[I div 2] and $0F;
    if (Nibble = 15) and (I = Length(ABytes) * 2 - 1) then
      Break;
    Inc(Count);
    if Nibble <= 9 then
      Result[Count] := WideChar(Ord('0') + Nibble)
    else if Nibble = 13 then
      Result[Count] := 'D'
    else
      Fail('Track 2 encoding');
  end;
  SetLength(Result, Count);
end;

class procedure TEmvCodec.DecodeCardFields(var AData: TEmvApplicationData);
var
  Value: TBytes;
  Track, TrackPan, TrackExpiry: UnicodeString;
  I, Separator: Integer;
begin
  Value := ConsistentValue(AData.Fields, HexToBytes('5A'));
  if Length(Value) > 10 then
    Fail('PAN size');
  AData.Pan := DecimalText(Value, True);
  if Length(AData.Pan) > 19 then
    Fail('PAN digit count');
  Value := ConsistentValue(AData.Fields, HexToBytes('5F24'));
  if (Length(Value) <> 0) and (Length(Value) <> 3) then
    Fail('expiry size');
  AData.ExpiryDate := DecimalText(Value, False);
  AData.ExpiryMonth := Copy(AData.ExpiryDate, 1, 4);
  AData.ServiceCode := '';
  Value := ConsistentValue(AData.Fields, HexToBytes('5F20'));
  if Length(Value) > 26 then
    Fail('cardholder name size');
  AData.CardholderName := LatinText(Value);
  Value := ConsistentValue(AData.Fields, HexToBytes('5F53'));
  AData.Iban := LatinText(Value);
  if Length(Value) <> 0 then
  begin
    if (Length(Value) < 15) or (Length(Value) > 34) then
      Fail('IBAN size');
    for I := 1 to Length(AData.Iban) do
      if not(((AData.Iban[I] >= 'A') and (AData.Iban[I] <= 'Z')) or
        ((AData.Iban[I] >= '0') and (AData.Iban[I] <= '9'))) then
        Fail('IBAN encoding');
    if (AData.Iban[1] < 'A') or (AData.Iban[1] > 'Z') or (AData.Iban[2] < 'A')
      or (AData.Iban[2] > 'Z') or (AData.Iban[3] < '0') or (AData.Iban[3] > '9')
      or (AData.Iban[4] < '0') or (AData.Iban[4] > '9') then
      Fail('IBAN header');
  end;
  AData.Track2Equivalent := ConsistentValue(AData.Fields, HexToBytes('57'));
  if Length(AData.Track2Equivalent) > 19 then
    Fail('Track 2 size');
  if Length(AData.Track2Equivalent) <> 0 then
  begin
    Track := Track2Text(AData.Track2Equivalent);
    Separator := Pos('D', Track);
    if (Separator < 2) or (Separator > 20) or (Length(Track) - Separator < 7) or
      (Pos('D', Copy(Track, Separator + 1, Length(Track))) <> 0) then
      Fail('Track 2 structure');
    TrackPan := Copy(Track, 1, Separator - 1);
    TrackExpiry := Copy(Track, Separator + 1, 4);
    if (AData.Pan <> '') and (AData.Pan <> TrackPan) then
      Fail('conflicting PAN sources');
    if (AData.ExpiryMonth <> '') and (AData.ExpiryMonth <> TrackExpiry) then
      Fail('conflicting expiry sources');
    AData.Pan := TrackPan;
    AData.ExpiryMonth := TrackExpiry;
    AData.ServiceCode := Copy(Track, Separator + 5, 3);
  end;
end;

end.
