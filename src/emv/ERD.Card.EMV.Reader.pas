unit ERD.Card.EMV.Reader;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Transport, ERD.Card.APDU, ERD.Card.TLV, ERD.Card.EMV.Data;

const
  /// <summary>Maximum retained primitive fields across one EMV application snapshot.</summary>
  EmvMaxCollectedFields = 8192;

type
  /// <summary>A card status failure without retaining APDUs, PANs or personal data.</summary>
  EEmvStatusError = class(EEmvDataError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates an EMV operation status error.</summary>
    /// <param name="AStatusWord">The received SW1/SW2 word.</param>
    constructor Create(const AStatusWord: Word); reintroduce;
    /// <summary>Received SW1/SW2, with SW1 in the high byte.</summary>
    property StatusWord: Word read FStatusWord;
  end;
  /// <summary>Non-visual EMV application discovery and application-data reader.</summary>
  /// <remarks>Construction performs no hardware work. Configure and call on one
  /// caller thread; the component is not reentrant. A connected transport is required.
  /// Discovery and each application read acquire one exclusive transaction by default.
  /// GPO initiates application processing and can change card state/counters. No PIN,
  /// GENERATE AC, issuer scripts, payment completion or kernel certification is provided.</remarks>
  TEMVCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FUseTransactions: Boolean;
    FMaxRecords: Integer;
    FMaxDirectoryRecords: Integer;
    FMaxLogRecords: Integer;
    procedure SetMaxRecords(const AValue: Integer);
    procedure SetMaxDirectoryRecords(const AValue: Integer);
    procedure SetMaxLogRecords(const AValue: Integer);
    function BeginRead: ICardTransaction;
    procedure EndRead(const ATransaction: ICardTransaction; const ASucceeded: Boolean);
    function Exchange(const ACommand: TApduCommand; const AAllowCorrection: Boolean): TApduResponse;
    function Select(const AName: TBytes): TApduResponse;
    function SelectApplicationFci(const AAid: TBytes; out AFci: TBytes): TTlvDocument;
    function GetData(const AObject: TEmvDataObject): TEmvDataObjectResult;
    function ReadLogInternal(const AAid: TBytes): TEmvTransactionLogData;
    function ReadRecord(const ASfi, ANumber: Byte): TApduResponse;
    function DecodeTemplate(const ABytes: TBytes; const ATag: string): TTlvDocument;
    function Child(const AParent: TTlvNode; const ATag: string; const ARequired: Boolean): TTlvNode;
    procedure CollectFields(const ANode: TTlvNode; var AFields: TEmvValues);
    function Info(const AParent: TTlvNode; const AAid: TBytes): TEmvApplicationInfo;
    procedure CollectApplications(const AParent: TTlvNode; var AApplications: TEmvApplications);
    function DiscoverInternal(const ADirectory: TEmvDirectory): TEmvDirectoryData;
    function ReadInternal(const AAid: TBytes; const ATerminalValues: TEmvValues): TEmvApplicationData;
  public
    /// <summary>Creates an inactive reader with mandatory transactions and bounded record reads.</summary>
    /// <param name="AOwner">Optional component owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads the selected PSE or PPSE directory, without choosing an application.</summary>
    /// <param name="ADirectory">Explicit contact or contactless directory to select.</param>
    /// <returns>Complete application entries; Present is false only for directory-not-found.</returns>
    /// <exception cref="EEmvDataError">Configuration, FCI, entries or a bound is invalid.</exception>
    /// <exception cref="EEmvStatusError">A card command fails, except permitted absence/end-of-directory statuses.</exception>
    /// <remarks>No guessed AID fallback. Transport/APDU errors propagate and failed commands
    /// are not replayed. A missing PSE is normal; an application can be selected by explicit AID.</remarks>
    function DiscoverApplications(const ADirectory: TEmvDirectory): TEmvDirectoryData;
    /// <summary>Selects an exact application and obtains its requested terminal-value DOL without GPO.</summary>
    /// <param name="AAid">Exact 5..16-byte AID; selected FCI must match.</param>
    /// <returns>Owned validated PDOL bytes; nil when tag 9F38 is absent.</returns>
    /// <remarks>One exclusive transaction, no GPO or fabricated terminal values. Use DecodeDol
    /// to inspect the tag/size requirements before calling ReadApplication.</remarks>
    function ReadProcessingOptionsDol(const AAid: TBytes): TBytes;
    /// <summary>Selects an exact AID, initializes GPO with supplied PDOL data and reads all AFL records.</summary>
    /// <param name="AAid">Exact AID of 5..16 bytes; selected FCI must return the same identifier.</param>
    /// <param name="ATerminalValues">Explicit PDOL inputs; nil requires that no nonempty values are requested.</param>
    /// <returns>A complete snapshot with optional typed fields and independent byte buffers.</returns>
    /// <exception cref="EEmvDataError">PDOL values, data, selected AID or resource bounds are invalid.</exception>
    /// <exception cref="EEmvStatusError">Selection, GPO or a required record fails.</exception>
    /// <remarks>GPO is sent once, even on 6Cxx or transport failure. Bounded GET RESPONSE
    /// may collect its output. SELECT/READ RECORD allow one bounded Le correction per APDU.
    /// No partial snapshot is returned; release failures preserve a primary read error.</remarks>
    function ReadApplication(const AAid: TBytes; const ATerminalValues: TEmvValues): TEmvApplicationData;
    /// <summary>Reads all AFL records and additionally probes an explicit bounded SFI/record rectangle.</summary>
    /// <param name="AAid">Exact application identifier, 5..16 bytes.</param>
    /// <param name="ATerminalValues">Explicit PDOL values used for the single GPO initialization.</param>
    /// <param name="AFirstSfi">First short file identifier, 1..30.</param>
    /// <param name="ALastSfi">Last short file identifier, not below the first.</param>
    /// <param name="AFirstRecord">First absolute record number, 1..255.</param>
    /// <param name="ALastRecord">Last record number, not below the first.</param>
    /// <returns>Owned application data, successful extra records and explicit absent/restricted probe statuses.</returns>
    /// <remarks>One exclusive transaction and one GPO. Scans every requested pair, including gaps;
    /// never repeats an AFL record. 6A82/6A83 and 6982/6985 are recorded, without authentication attempts.
    /// MaxRecords bounds both requested probes and total retained records. Unexpected statuses,
    /// malformed successful EMV records and transport failures abort without a partial snapshot.</remarks>
    function ReadApplicationWithRecordScan(const AAid: TBytes; const ATerminalValues: TEmvValues;
      const AFirstSfi, ALastSfi, AFirstRecord, ALastRecord: Integer): TEmvApplicationData;
    /// <summary>Selects an exact AID and retrieves an optional counter or log format without GPO.</summary>
    /// <param name="AAid">Exact application identifier, 5..16 bytes.</param>
    /// <param name="AObject">Explicit supported GET DATA object.</param>
    /// <returns>Validated independent value; Present is false only for 6A88, 6A81 or 6D00.</returns>
    /// <exception cref="EEmvDataError">Selection, returned tag/size, enum or a resource bound is invalid.</exception>
    /// <exception cref="EEmvStatusError">SELECT fails or GET DATA returns another failure status.</exception>
    /// <remarks>One exclusive operation. Transport exceptions are never replayed. SELECT and GET DATA
    /// allow bounded response chaining and Le correction; no PIN command or payment cryptogram is sent.</remarks>
    function ReadDataObject(const AAid: TBytes; const AObject: TEmvDataObject): TEmvDataObjectResult;
    /// <summary>Selects an exact AID and reads its optional cyclic transaction log without GPO.</summary>
    /// <param name="AAid">Exact application identifier, 5..16 bytes.</param>
    /// <returns>Complete snapshot; Supported is false only when FCI A5/BF0C has no Log Entry 9F4D.</returns>
    /// <exception cref="EEmvDataError">FCI, log entry, format, record or configured bound is invalid.</exception>
    /// <exception cref="EEmvStatusError">A required command fails; only 6A83 ends an incompletely filled log.</exception>
    /// <remarks>Advertised capacity above MaxLogRecords is rejected before log reads. Records are
    /// newest-first raw concatenations decoded by 9F4F, not BER templates. An advertised log requires
    /// a readable valid format. No partial snapshot is returned; release failure preserves a primary error.</remarks>
    function ReadTransactionLog(const AAid: TBytes): TEmvTransactionLogData;
    /// <summary>Connected byte transport retained by the component; its owner may still disconnect it.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
  published
    /// <summary>Acquire ICardTransaction for the complete operation; defaults to true.</summary>
    /// <remarks>False requires caller-guaranteed exclusive access for the whole operation.
    /// Existing transactions cannot nest; callers owning one must disable component acquisition.</remarks>
    property UseTransactions: Boolean read FUseTransactions write FUseTransactions default True;
    /// <summary>Maximum AFL records, 1..1024; defaults to 256. Invalid assignments raise EEmvDataError.</summary>
    property MaxRecords: Integer read FMaxRecords write SetMaxRecords default 256;
    /// <summary>Maximum contact-directory record probes, 1..255; defaults to 32.</summary>
    /// <remarks>Reaching the bound without a 6A83 end marker raises EEmvDataError.</remarks>
    property MaxDirectoryRecords: Integer read FMaxDirectoryRecords write SetMaxDirectoryRecords default 32;
    /// <summary>Maximum advertised log capacity, 1..255; defaults to 32. Invalid assignments raise EEmvDataError.</summary>
    property MaxLogRecords: Integer read FMaxLogRecords write SetMaxLogRecords default 32;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail(const AReason: string);
begin
  raise EEmvDataError.Create('EMV read failed: ' + AReason + '.');
end;

procedure RequireSuccess(const AResponse: TApduResponse);
begin
  if AResponse.StatusWord <> ApduStatusSuccess then raise EEmvStatusError.Create(AResponse.StatusWord);
end;

function IsTag(const ANode: TTlvNode; const ATag: string): Boolean;
begin
  Result := BytesEqual(ANode.Tag, HexToBytes(ATag));
end;

constructor EEmvStatusError.Create(const AStatusWord: Word);
begin
  inherited CreateFmt('EMV command returned status %.4x.', [AStatusWord]);
  FStatusWord := AStatusWord;
end;

constructor TEMVCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUseTransactions := True;
  FMaxRecords := 256;
  FMaxDirectoryRecords := 32;
  FMaxLogRecords := 32;
end;

procedure TEMVCardReader.SetMaxLogRecords(const AValue: Integer);
begin
  if (AValue < 1) or (AValue > 255) then Fail('log record limit');
  FMaxLogRecords := AValue;
end;

procedure TEMVCardReader.SetMaxRecords(const AValue: Integer);
begin
  if (AValue < 1) or (AValue > 1024) then Fail('record limit');
  FMaxRecords := AValue;
end;

procedure TEMVCardReader.SetMaxDirectoryRecords(const AValue: Integer);
begin
  if (AValue < 1) or (AValue > 255) then Fail('directory limit');
  FMaxDirectoryRecords := AValue;
end;

function TEMVCardReader.BeginRead: ICardTransaction;
begin
  Result := nil;
  if FTransport = nil then Fail('no transport');
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Result) then Fail('transaction capability missing');
    Result.BeginTransaction;
  end;
end;

procedure TEMVCardReader.EndRead(const ATransaction: ICardTransaction; const ASucceeded: Boolean);
begin
  if ATransaction = nil then Exit;
  if ASucceeded then ATransaction.EndTransaction
  else
  begin
    try ATransaction.EndTransaction;
    except
      // Preserve the primary read error after best-effort transaction release.
    end;
  end;
end;

function TEMVCardReader.Exchange(const ACommand: TApduCommand;
  const AAllowCorrection: Boolean): TApduResponse;
var
  Command: TApduCommand;
  Response: TApduResponse;
  Buffer: TBytes;
  Count, I, Step, Le: Integer;
  Corrected, AllowCorrection: Boolean;
begin
  Result := Default(TApduResponse);
  Command := ACommand;
  Count := 0;
  Buffer := nil;
  SetLength(Buffer, Integer(ACommand.Le));
  Corrected := False;
  AllowCorrection := AAllowCorrection;
  for Step := 1 to 32 do
  begin
    Response := TApduCodec.DecodeResponse(FTransport.Exchange(TApduCodec.EncodeCommand(Command)));
    if (Response.StatusWord and $FF00) = $6C00 then
    begin
      if Length(Response.Data) <> 0 then Fail('correction carrying data');
      if not AllowCorrection then Exit(Response);
      if Corrected then Fail('repeated Le correction');
      Le := Response.StatusWord and $FF;
      if Le = 0 then Le := 256;
      if Le > Integer(Command.Le) then Fail('Le correction exceeds request');
      Command.Le := Cardinal(Le);
      if Command.INS <> $C0 then SetLength(Buffer, Le);
      Corrected := True;
      Continue;
    end;
    if (Length(Response.Data) > Integer(Command.Le)) or
      (Length(Response.Data) > Length(Buffer) - Count) then Fail('response exceeds request');
    if (Response.StatusWord <> ApduStatusSuccess) and
      ((Response.StatusWord and $FF00) <> $6100) then
    begin
      if (Count <> 0) or (Length(Response.Data) <> 0) then Fail('error carrying data');
      Exit(Response);
    end;
    for I := 0 to Length(Response.Data) - 1 do Buffer[Count + I] := Response.Data[I];
    Inc(Count, Length(Response.Data));
    if Response.StatusWord = ApduStatusSuccess then
    begin
      SetLength(Buffer, Count);
      Result.Data := Buffer;
      Result.StatusWord := ApduStatusSuccess;
      Exit;
    end;
    Le := Response.StatusWord and $FF;
    if Le = 0 then Le := 256;
    if Le > Length(Buffer) - Count then Fail('GET RESPONSE exceeds request');
    Command := Default(TApduCommand);
    Command.INS := $C0;
    Command.HasLe := True;
    Command.Le := Cardinal(Le);
    AllowCorrection := True;
    Corrected := False;
  end;
  Fail('response step limit');
end;

function TEMVCardReader.Select(const AName: TBytes): TApduResponse;
var Command: TApduCommand;
begin
  Command := Default(TApduCommand);
  Command.INS := $A4;
  Command.P1 := 4;
  Command.Data := AName;
  Command.HasLe := True;
  Command.Le := 256;
  Result := Exchange(Command, True);
end;

function TEMVCardReader.SelectApplicationFci(const AAid: TBytes; out AFci: TBytes): TTlvDocument;
var Response: TApduResponse;
begin
  Response := Select(AAid);
  RequireSuccess(Response);
  AFci := Response.Data;
  Result := DecodeTemplate(AFci, '6F');
  try
    if not BytesEqual(Child(Result.Roots[0], '84', True).Value, AAid) then Fail('selected AID mismatch');
    Child(Result.Roots[0], 'A5', True);
  except
    Result.Free;
    raise;
  end;
end;

function TEMVCardReader.GetData(const AObject: TEmvDataObject): TEmvDataObjectResult;
var
  Command: TApduCommand;
  Response: TApduResponse;
  Tag: string;
  TagBytes: TBytes;
  Document: TTlvDocument;
  Size: Integer;
begin
  Result := Default(TEmvDataObjectResult);
  Result.DataObject := AObject;
  case AObject of
    edoAtc: Tag := '9F36';
    edoLastOnlineAtc: Tag := '9F13';
    edoPinTryCounter: Tag := '9F17';
    edoLogFormat: Tag := '9F4F';
  else Fail('GET DATA object'); end;
  Command := Default(TApduCommand);
  Command.CLA := $80;
  Command.INS := $CA;
  Command.P1 := $9F;
  TagBytes := HexToBytes(Tag);
  Command.P2 := TagBytes[1];
  Command.HasLe := True;
  Command.Le := 256;
  Response := Exchange(Command, True);
  Result.StatusWord := Response.StatusWord;
  if (Response.StatusWord = $6A88) or (Response.StatusWord = $6A81) or
    (Response.StatusWord = $6D00) then Exit;
  RequireSuccess(Response);
  Document := DecodeTemplate(Response.Data, Tag);
  try Result.Value := Document.Roots[0].Value;
  finally Document.Free; end;
  if AObject = edoLogFormat then
  begin
    // Validate the DOL and its total record length before accepting even an empty log.
    TEmvCodec.LogRecordSize(Result.Value);
  end
  else
  begin
    Size := Length(Result.Value);
    if AObject = edoPinTryCounter then
    begin
      if Size <> 1 then Fail('PIN counter size');
      Result.NumericValue := Result.Value[0];
    end
    else
    begin
      if Size <> 2 then Fail('ATC size');
      Result.NumericValue := (Word(Result.Value[0]) shl 8) or Result.Value[1];
    end;
    Result.HasNumericValue := True;
  end;
  Result.RawData := Response.Data;
  Result.Present := True;
end;

function TEMVCardReader.ReadRecord(const ASfi, ANumber: Byte): TApduResponse;
var Command: TApduCommand;
begin
  Command := Default(TApduCommand);
  Command.INS := $B2;
  Command.P1 := ANumber;
  Command.P2 := (ASfi shl 3) or 4;
  Command.HasLe := True;
  Command.Le := 256;
  Result := Exchange(Command, True);
end;

function TEMVCardReader.DecodeTemplate(const ABytes: TBytes; const ATag: string): TTlvDocument;
var
  Options: TTlvDecodeOptions;
  Error: TTlvError;
begin
  Options := DefaultTlvOptions;
  Options.MaxInputBytes := 256;
  Options.MaxDepth := 16;
  Options.MaxNodes := 256;
  Options.MaxTagBytes := 3;
  Options.AllowPadding := True;
  Result := nil;
  if not TTlvCodec.TryDecode(ABytes, Options, Result, Error) then raise ETlvFormatError.Create(Error);
  try
    if (Result.Count <> 1) or not IsTag(Result.Roots[0], ATag) then Fail('response template');
  except
    Result.Free;
    raise;
  end;
end;

function TEMVCardReader.Child(const AParent: TTlvNode; const ATag: string;
  const ARequired: Boolean): TTlvNode;
var I: Integer;
begin
  Result := nil;
  for I := 0 to AParent.ChildCount - 1 do
    if IsTag(AParent.Children[I], ATag) then
    begin
      if Result <> nil then Fail('duplicate required tag');
      Result := AParent.Children[I];
    end;
  if ARequired and (Result = nil) then Fail('required tag missing');
end;

procedure TEMVCardReader.CollectFields(const ANode: TTlvNode; var AFields: TEmvValues);
var I, Index: Integer;
begin
  if ANode.IsConstructed then
    for I := 0 to ANode.ChildCount - 1 do CollectFields(ANode.Children[I], AFields)
  else
  begin
    Index := Length(AFields);
    if Index >= EmvMaxCollectedFields then Fail('field count limit');
    SetLength(AFields, Index + 1);
    AFields[Index].Tag := ANode.Tag;
    AFields[Index].Value := ANode.Value;
  end;
end;

function TEMVCardReader.Info(const AParent: TTlvNode; const AAid: TBytes): TEmvApplicationInfo;
var
  Node: TTlvNode;
  Value: TBytes;
  I: Integer;
begin
  Result := Default(TEmvApplicationInfo);
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  Result.Aid := CopyBytes(AAid);
  Node := Child(AParent, '50', False);
  if Node <> nil then
  begin
    Value := Node.Value;
    if (Length(Value) = 0) or (Length(Value) > 16) then Fail('label size');
    SetLength(Result.LabelText, Length(Value));
    for I := 0 to Length(Value) - 1 do Result.LabelText[I + 1] := WideChar(Value[I]);
  end;
  Node := Child(AParent, '87', False);
  if Node <> nil then
  begin
    Value := Node.Value;
    if (Length(Value) <> 1) or ((Value[0] and $70) <> 0) then Fail('priority encoding');
    Result.HasPriority := True;
    Result.Priority := Value[0] and $0F;
    Result.ConfirmationRequired := (Value[0] and $80) <> 0;
  end;
end;

procedure TEMVCardReader.CollectApplications(const AParent: TTlvNode;
  var AApplications: TEmvApplications);
var I, Index: Integer;
begin
  for I := 0 to AParent.ChildCount - 1 do
    if IsTag(AParent.Children[I], '61') then
    begin
      Index := Length(AApplications);
      if Index >= 64 then Fail('application count limit');
      SetLength(AApplications, Index + 1);
      AApplications[Index] := Info(AParent.Children[I], Child(AParent.Children[I], '4F', True).Value);
    end;
end;

function TEMVCardReader.DiscoverInternal(const ADirectory: TEmvDirectory): TEmvDirectoryData;
var
  Name, Value: TBytes;
  Response: TApduResponse;
  Document, RecordDoc: TTlvDocument;
  A5: TTlvNode;
  Sfi: Byte;
  I: Integer;
begin
  Result := Default(TEmvDirectoryData);
  Result.Directory := ADirectory;
  if ADirectory = edContactPse then Name := HexToBytes('315041592E5359532E4444463031')
  else Name := HexToBytes('325041592E5359532E4444463031');
  Response := Select(Name);
  if Response.StatusWord = $6A82 then Exit;
  RequireSuccess(Response);
  Result.Present := True;
  Result.Fci := Response.Data;
  Document := DecodeTemplate(Result.Fci, '6F');
  try
    if not BytesEqual(Child(Document.Roots[0], '84', True).Value, Name) then Fail('directory name mismatch');
    A5 := Child(Document.Roots[0], 'A5', True);
    if ADirectory = edContactlessPpse then
      CollectApplications(Child(A5, 'BF0C', True), Result.Applications)
    else
    begin
      Value := Child(A5, '88', True).Value;
      if (Length(Value) <> 1) or (Value[0] < 1) or (Value[0] > 30) then Fail('directory SFI');
      Sfi := Value[0];
      for I := 1 to FMaxDirectoryRecords do
      begin
        Response := ReadRecord(Sfi, Byte(I));
        if Response.StatusWord = $6A83 then Exit;
        RequireSuccess(Response);
        RecordDoc := DecodeTemplate(Response.Data, '70');
        try CollectApplications(RecordDoc.Roots[0], Result.Applications);
        finally RecordDoc.Free; end;
      end;
      Fail('directory record limit without EOF');
    end;
  finally
    Document.Free;
  end;
end;

function TEMVCardReader.ReadInternal(const AAid: TBytes;
  const ATerminalValues: TEmvValues): TEmvApplicationData;
var
  Response: TApduResponse;
  Command: TApduCommand;
  Document: TTlvDocument;
  A5, Node: TTlvNode;
  Dol, AflBytes: TBytes;
  I, N, Index: Integer;
begin
  Result := Default(TEmvApplicationData);
  Document := SelectApplicationFci(AAid, Result.Fci);
  try
    A5 := Child(Document.Roots[0], 'A5', True);
    Result.ApplicationInfo := Info(A5, AAid);
    Dol := nil;
    Node := Child(A5, '9F38', False);
    if Node <> nil then Dol := Node.Value;
    CollectFields(Document.Roots[0], Result.Fields);
  finally
    Document.Free;
  end;
  Command := Default(TApduCommand);
  Command.CLA := $80;
  Command.INS := $A8;
  Command.Data := TEmvCodec.BuildDolData(Dol, ATerminalValues);
  Command.HasLe := True;
  Command.Le := 256;
  Response := Exchange(Command, False);
  RequireSuccess(Response);
  Result.Gpo := Response.Data;
  if Length(Result.Gpo) = 0 then Fail('empty GPO');
  if Result.Gpo[0] = $80 then
  begin
    Document := DecodeTemplate(Result.Gpo, '80');
    try
      Dol := Document.Roots[0].Value;
      if Length(Dol) < 2 then Fail('GPO AIP missing');
      Result.Aip := Copy(Dol, 0, 2);
      AflBytes := Copy(Dol, 2, Length(Dol) - 2);
      CollectFields(Document.Roots[0], Result.Fields);
    finally Document.Free; end;
  end
  else
  begin
    Document := DecodeTemplate(Result.Gpo, '77');
    try
      Result.Aip := Child(Document.Roots[0], '82', True).Value;
      AflBytes := Child(Document.Roots[0], '94', True).Value;
      if Length(Result.Aip) <> 2 then Fail('AIP size');
      CollectFields(Document.Roots[0], Result.Fields);
    finally Document.Free; end;
  end;
  Result.Afl := TEmvCodec.DecodeAfl(AflBytes, FMaxRecords);
  for I := 0 to Length(Result.Afl) - 1 do
    for N := Result.Afl[I].FirstRecord to Result.Afl[I].LastRecord do
    begin
      Response := ReadRecord(Result.Afl[I].Sfi, Byte(N));
      RequireSuccess(Response);
      if Length(Response.Data) = 0 then Fail('empty application record');
      Index := Length(Result.Records);
      SetLength(Result.Records, Index + 1);
      Result.Records[Index].Sfi := Result.Afl[I].Sfi;
      Result.Records[Index].Number := Byte(N);
      Result.Records[Index].RawData := Response.Data;
      if Result.Afl[I].Sfi <= 10 then
      begin
        Document := DecodeTemplate(Response.Data, '70');
        try CollectFields(Document.Roots[0], Result.Fields);
        finally Document.Free; end;
      end;
    end;
  TEmvCodec.DecodeCardFields(Result);
end;

function TEMVCardReader.ReadLogInternal(const AAid: TBytes): TEmvTransactionLogData;
var
  Document: TTlvDocument;
  Node: TTlvNode;
  Entry: TBytes;
  FormatData: TEmvDataObjectResult;
  Response: TApduResponse;
  N, Index: Integer;
begin
  Result := Default(TEmvTransactionLogData);
  Document := SelectApplicationFci(AAid, Result.Fci);
  try
    Node := Child(Child(Document.Roots[0], 'A5', True), 'BF0C', False);
    if Node = nil then Exit;
    Node := Child(Node, '9F4D', False);
    if Node = nil then Exit;
    Entry := Node.Value;
    if (Length(Entry) <> 2) or (Entry[0] < 11) or (Entry[0] > 30) or
      (Entry[1] = 0) then Fail('log entry');
    if Entry[1] > FMaxLogRecords then Fail('advertised log exceeds limit');
    Result.Supported := True;
    Result.Sfi := Entry[0];
    Result.MaximumRecords := Entry[1];
  finally Document.Free; end;
  FormatData := GetData(edoLogFormat);
  if not FormatData.Present then raise EEmvStatusError.Create(FormatData.StatusWord);
  Result.LogFormat := FormatData.Value;
  for N := 1 to Result.MaximumRecords do
  begin
    Response := ReadRecord(Result.Sfi, Byte(N));
    if Response.StatusWord = $6A83 then Exit;
    RequireSuccess(Response);
    Index := Length(Result.Records);
    SetLength(Result.Records, Index + 1);
    Result.Records[Index].Number := Byte(N);
    Result.Records[Index].RawData := Response.Data;
    Result.Records[Index].Fields := TEmvCodec.DecodeLogRecord(Result.LogFormat, Response.Data);
  end;
end;

function TEMVCardReader.ReadDataObject(const AAid: TBytes;
  const AObject: TEmvDataObject): TEmvDataObjectResult;
var
  Transaction: ICardTransaction;
  Data: TEmvDataObjectResult;
  Document: TTlvDocument;
  Fci: TBytes;
  Succeeded: Boolean;
begin
  Result := Default(TEmvDataObjectResult);
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  if (Ord(AObject) < Ord(Low(TEmvDataObject))) or
    (Ord(AObject) > Ord(High(TEmvDataObject))) then Fail('GET DATA object');
  Transaction := BeginRead;
  Succeeded := False;
  try
    Document := SelectApplicationFci(AAid, Fci);
    Document.Free;
    Data := GetData(AObject);
    Succeeded := True;
  finally EndRead(Transaction, Succeeded); end;
  Result := Data;
end;

function TEMVCardReader.ReadTransactionLog(const AAid: TBytes): TEmvTransactionLogData;
var
  Transaction: ICardTransaction;
  Data: TEmvTransactionLogData;
  Succeeded: Boolean;
begin
  Result := Default(TEmvTransactionLogData);
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  Transaction := BeginRead;
  Succeeded := False;
  try
    Data := ReadLogInternal(AAid);
    Succeeded := True;
  finally EndRead(Transaction, Succeeded); end;
  Result := Data;
end;

function TEMVCardReader.DiscoverApplications(const ADirectory: TEmvDirectory): TEmvDirectoryData;
var
  Transaction: ICardTransaction;
  Data: TEmvDirectoryData;
  Succeeded: Boolean;
begin
  Result := Default(TEmvDirectoryData);
  Transaction := BeginRead;
  Succeeded := False;
  try
    Data := DiscoverInternal(ADirectory);
    Succeeded := True;
  finally EndRead(Transaction, Succeeded); end;
  Result := Data;
end;

function TEMVCardReader.ReadApplication(const AAid: TBytes;
  const ATerminalValues: TEmvValues): TEmvApplicationData;
var
  Transaction: ICardTransaction;
  Data: TEmvApplicationData;
  Succeeded: Boolean;
begin
  Result := Default(TEmvApplicationData);
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  Transaction := BeginRead;
  Succeeded := False;
  try
    Data := ReadInternal(AAid, ATerminalValues);
    Succeeded := True;
  finally EndRead(Transaction, Succeeded); end;
  Result := Data;
end;


function TEMVCardReader.ReadApplicationWithRecordScan(const AAid: TBytes; const ATerminalValues: TEmvValues;
  const AFirstSfi, ALastSfi, AFirstRecord, ALastRecord: Integer): TEmvApplicationData;
var Transaction: ICardTransaction; Data: TEmvApplicationData; Response: TApduResponse;
  Document: TTlvDocument; Sfi,N,I,Index: Integer; Succeeded,AlreadyRead: Boolean;
begin
  Result := Default(TEmvApplicationData);
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  if (AFirstSfi < 1) or (ALastSfi > 30) or (ALastSfi < AFirstSfi) or
    (AFirstRecord < 1) or (ALastRecord > 255) or (ALastRecord < AFirstRecord) then Fail('scan range');
  if (ALastSfi-AFirstSfi+1)*(ALastRecord-AFirstRecord+1) > FMaxRecords then Fail('scan bound');
  Transaction := BeginRead; Succeeded := False;
  try
    Data := ReadInternal(AAid,ATerminalValues);
    for Sfi := AFirstSfi to ALastSfi do
      for N := AFirstRecord to ALastRecord do
      begin
        AlreadyRead := False;
        for I := 0 to High(Data.Records) do
          if (Data.Records[I].Sfi = Sfi) and (Data.Records[I].Number = N) then AlreadyRead := True;
        if AlreadyRead then Continue;
        if Length(Data.Records) >= FMaxRecords then Fail('combined record bound');
        Response := ReadRecord(Byte(Sfi),Byte(N));
        Index := Length(Data.Probes); SetLength(Data.Probes,Index+1);
        Data.Probes[Index].Sfi := Byte(Sfi); Data.Probes[Index].Number := Byte(N);
        Data.Probes[Index].StatusWord := Response.StatusWord;
        case Response.StatusWord of
          $6A82,$6A83,$6982,$6985: Continue;
          $9000: ;
        else RequireSuccess(Response); end;
        if Length(Response.Data) = 0 then Fail('empty scanned record');
        Index := Length(Data.Records); SetLength(Data.Records,Index+1);
        Data.Records[Index].Sfi := Byte(Sfi); Data.Records[Index].Number := Byte(N);
        Data.Records[Index].RawData := Response.Data;
        if Sfi <= 10 then
        begin
          Document := DecodeTemplate(Response.Data,'70');
          try CollectFields(Document.Roots[0],Data.Fields); finally Document.Free; end;
        end;
      end;
    TEmvCodec.DecodeCardFields(Data); Succeeded := True;
  finally EndRead(Transaction,Succeeded); end;
  Result := Data;
end;


function TEMVCardReader.ReadProcessingOptionsDol(const AAid: TBytes): TBytes;
var Transaction: ICardTransaction; Document: TTlvDocument; Node: TTlvNode;
  Fci,Data: TBytes; Entries: TEmvDolEntries; Succeeded: Boolean;
begin
  Result := nil; Data := nil;
  if (Length(AAid) < 5) or (Length(AAid) > 16) then Fail('AID size');
  Transaction := BeginRead; Succeeded := False;
  try
    Document := SelectApplicationFci(AAid,Fci);
    try
      Node := Child(Child(Document.Roots[0],'A5',True),'9F38',False);
      if Node <> nil then Data := CopyBytes(Node.Value);
      Entries := TEmvCodec.DecodeDol(Data);
      if Length(Entries) > EmvMaxCollectedFields then Fail('PDOL bound');
    finally Document.Free; end;
    Succeeded := True;
  finally EndRead(Transaction,Succeeded); end;
  Result := Data;
end;

end.
