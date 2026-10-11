unit ERD.Card.Contactless.Workflow.Ndef;

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
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.Ndef,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Type1.Ndef, ERD.Card.Contactless.Type2.Ndef,
  ERD.Card.Contactless.Type3.Ndef, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Contactless.Type5.Ndef;

type
  /// <summary>Configured NDEF mapping backend, with bounded writes and uncertain-mutation exceptions.</summary>
  /// <remarks>Connection and card ownership stay with the caller. No card swaps during a phase.</remarks>
  ICardWorkflowNdef = interface
    ['{402F6923-60E0-4855-BBD0-88159FA8DBC5}']
    /// <summary>Reads and normalizes logical NDEF records.</summary>
    /// <returns>Independent canonical message bytes, or empty for no message.</returns>
    function ReadMessage: TBytes;
    /// <summary>Validates mapping/capacity before mutation and writes once with mapping verification.</summary>
    /// <param name="ABytes">Canonical message bytes; empty explicitly clears storage.</param>
    /// <remarks>Raise EContactlessWriteUncertain if any dispatched mutation lacks evidence.</remarks>
    procedure WriteMessage(const ABytes: TBytes);
  end;
  /// <summary>Native Type 1 through Type 5 NDEF adapters; readers must outlive returned interfaces.</summary>
  TNdefWorkflowAdapters = class
  public
    /// <summary>Creates a Topaz NDEF adapter.</summary>
    /// <param name="AReader">Configured Type 1 reader.</param>
    /// <returns>Inactive adapter.</returns>
    class function Type1(const AReader: TType1NdefCardReader): ICardWorkflowNdef; static;
    /// <summary>Creates an Ultralight/NTAG NDEF adapter.</summary>
    /// <param name="AReader">Configured Type 2 reader.</param>
    /// <param name="AModel">Explicit memory geometry.</param>
    /// <returns>Inactive adapter.</returns>
    class function Type2(const AReader: TType2NdefCardReader;
      const AModel: TType2TagModel): ICardWorkflowNdef; static;
    /// <summary>Creates a FeliCa NDEF adapter.</summary>
    /// <param name="AReader">Configured Type 3 reader.</param>
    /// <returns>Inactive adapter.</returns>
    class function Type3(const AReader: TType3NdefCardReader): ICardWorkflowNdef; static;
    /// <summary>Creates an ISO 7816 NDEF adapter.</summary>
    /// <param name="AReader">Configured Type 4 reader.</param>
    /// <param name="AFileId">Explicit file, or zero for the uniquely advertised file.</param>
    /// <returns>Inactive adapter.</returns>
    class function Type4(const AReader: TType4NdefCardReader;
      const AFileId: Word = 0): ICardWorkflowNdef; static;
    /// <summary>Creates an ISO 15693 NDEF adapter.</summary>
    /// <param name="AReader">Configured addressed Type 5 reader.</param>
    /// <returns>Inactive adapter.</returns>
    class function Type5(const AReader: TType5NdefCardReader): ICardWorkflowNdef; static;
  end;
  /// <summary>Read, copy across tag families, or template-write logical NDEF messages.</summary>
  /// <remarks>Hardware metadata, passwords and locks are preserved by the mapping writers.
  /// Read-back compares canonical logical records, including opaque record contents.</remarks>
  TNdefTransferWorkflow = class(TCardWorkflow)
  private
    FSource, FTarget: ICardWorkflowNdef;
    FBytes: TBytes;
    FPrepared, FConsumed, FAllowClear, FVerified: Boolean;
    function GetBytes: TBytes;
  protected
    /// <summary>Checks preparation and single-execution lifecycle.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Acquires optional source and writes/reads the destination once.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Prepares NDEF copy or read-only backup.</summary>
    /// <param name="ASource">Configured source mapping.</param>
    /// <param name="ATarget">Configured destination, or nil for reading only.</param>
    /// <param name="AAllowClear">Explicit permission to clear destination when source has no message.</param>
    procedure PrepareCopy(const ASource, ATarget: ICardWorkflowNdef;
      const AAllowClear: Boolean = False);
    /// <summary>Prepares logical NDEF template programming.</summary>
    /// <param name="ATarget">Configured destination.</param>
    /// <param name="AMessage">Complete logical message, independently copied through the codec.</param>
    /// <param name="AAllowClear">Required true for an empty message.</param>
    procedure PrepareWrite(const ATarget: ICardWorkflowNdef;
      const AMessage: TNdefMessage; const AAllowClear: Boolean = False);
    /// <summary>Independent canonical acquired/template bytes.</summary>
    property MessageBytes: TBytes read GetBytes;
    /// <summary>True only after destination read-back matches all canonical records.</summary>
    property ReadBackVerified: Boolean read FVerified;
  end;

implementation

type
  TNdefAdapter = class(TInterfacedObject, ICardWorkflowNdef)
    Reader1: TType1NdefCardReader;
    Reader2: TType2NdefCardReader;
    Reader3: TType3NdefCardReader;
    Reader4: TType4NdefCardReader;
    Reader5: TType5NdefCardReader;
    Model: TType2TagModel;
    FileId: Word;
    function ReadMessage: TBytes;
    procedure WriteMessage(const ABytes: TBytes);
  end;

function Canonical(const ARecords: TNdefMessage): TBytes;
begin
  if Length(ARecords) = 0 then Result := nil else Result := TNdefCodec.Encode(ARecords);
end;

function TNdefAdapter.ReadMessage: TBytes;
begin
  if Reader1 <> nil then Result := Canonical(Reader1.ReadMessage.Records)
  else if Reader2 <> nil then Result := Canonical(Reader2.ReadMessage(Model).Records)
  else if Reader3 <> nil then Result := Canonical(Reader3.ReadMessage.Records)
  else if Reader4 <> nil then Result := Canonical(Reader4.ReadMessage(FileId).Records)
  else Result := Canonical(Reader5.ReadMessage.Records);
end;

procedure TNdefAdapter.WriteMessage(const ABytes: TBytes);
var Message: TNdefMessage; Before1: TType1NdefSnapshot; Before3: TType3NdefSnapshot;
begin
  Message := nil;
  if Length(ABytes) <> 0 then Message := TNdefCodec.Decode(ABytes);
  if Reader1 <> nil then
  begin
    Before1 := Reader1.ReadMessage;
    Reader1.WriteMessageVerified(Before1.Card.Uid, Before1.Card.Memory, ABytes);
  end
  else if Reader2 <> nil then
  begin
    if Length(ABytes) = 0 then Reader2.ClearMessage(Model)
    else Reader2.WriteMessage(Model, Message);
  end
  else if Reader3 <> nil then
  begin
    Before3 := Reader3.ReadMessage;
    Reader3.WriteMessageVerified(Before3.Attribute.RawBytes, ABytes);
  end
  else if Reader4 <> nil then
  begin
    if Length(ABytes) = 0 then Reader4.ClearMessage(FileId)
    else Reader4.WriteMessage(Message, FileId);
  end
  else
  begin
    if Length(ABytes) = 0 then Reader5.ClearMessage else Reader5.WriteMessage(Message);
  end;
end;

class function TNdefWorkflowAdapters.Type1(const AReader: TType1NdefCardReader): ICardWorkflowNdef;
var Adapter: TNdefAdapter;
begin
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  Adapter := TNdefAdapter.Create; Result := Adapter; Adapter.Reader1 := AReader;
end;

class function TNdefWorkflowAdapters.Type2(const AReader: TType2NdefCardReader;
  const AModel: TType2TagModel): ICardWorkflowNdef;
var Adapter: TNdefAdapter;
begin
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  TType2Layout.PageCount(AModel);
  Adapter := TNdefAdapter.Create; Result := Adapter; Adapter.Reader2 := AReader; Adapter.Model := AModel;
end;

class function TNdefWorkflowAdapters.Type3(const AReader: TType3NdefCardReader): ICardWorkflowNdef;
var Adapter: TNdefAdapter;
begin
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  Adapter := TNdefAdapter.Create; Result := Adapter; Adapter.Reader3 := AReader;
end;

class function TNdefWorkflowAdapters.Type4(const AReader: TType4NdefCardReader;
  const AFileId: Word): ICardWorkflowNdef;
var Adapter: TNdefAdapter;
begin
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  Adapter := TNdefAdapter.Create; Result := Adapter; Adapter.Reader4 := AReader; Adapter.FileId := AFileId;
end;

class function TNdefWorkflowAdapters.Type5(const AReader: TType5NdefCardReader): ICardWorkflowNdef;
var Adapter: TNdefAdapter;
begin
  if AReader = nil then raise ECardWorkflowError.Create('Reader required.');
  Adapter := TNdefAdapter.Create; Result := Adapter; Adapter.Reader5 := AReader;
end;

function TNdefTransferWorkflow.GetBytes: TBytes;
begin
  Result := CopyBytes(FBytes);
end;

procedure TNdefTransferWorkflow.PrepareCopy(const ASource, ATarget: ICardWorkflowNdef;
  const AAllowClear: Boolean);
begin
  RequireIdle;
  FPrepared := False;
  if ASource = nil then raise ECardWorkflowError.Create('Source required.');
  FSource := ASource; FTarget := ATarget; FBytes := nil;
  FAllowClear := AAllowClear; FVerified := False; FConsumed := False; FPrepared := True;
end;

procedure TNdefTransferWorkflow.PrepareWrite(const ATarget: ICardWorkflowNdef;
  const AMessage: TNdefMessage; const AAllowClear: Boolean);
begin
  RequireIdle;
  FPrepared := False;
  if ATarget = nil then raise ECardWorkflowError.Create('Target required.');
  if (Length(AMessage) = 0) and not AAllowClear then raise ECardWorkflowError.Create('Explicit clear permission required.');
  FBytes := Canonical(AMessage);
  FSource := nil; FTarget := ATarget; FAllowClear := AAllowClear;
  FVerified := False; FConsumed := False; FPrepared := True;
end;

procedure TNdefTransferWorkflow.ValidatePrepared;
begin
  if not FPrepared or FConsumed then raise ECardWorkflowError.Create('Prepare a new NDEF request.');
end;

procedure TNdefTransferWorkflow.DoExecute;
begin
  FConsumed := True;
  if FSource <> nil then
  begin
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, 1);
    if CancelRequested then Exit;
    FBytes := CopyBytes(FSource.ReadMessage);
    if Length(FBytes) <> 0 then FBytes := Canonical(TNdefCodec.Decode(FBytes));
    Progress(cwsReading, 1, 1);
  end;
  if FTarget = nil then Exit;
  if (Length(FBytes) = 0) and not FAllowClear then
    raise ECardWorkflowError.Create('Source is empty; clearing was not requested.');
  if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
  Progress(cwsWriting, 0, 1);
  if CancelRequested then Exit;
  try
    FTarget.WriteMessage(CopyBytes(FBytes));
  except
    on E: EContactlessWriteUncertain do begin MutationPending(True); raise; end;
  end;
  MutationPending(True);
  Progress(cwsVerifying, 0, 1);
  if not BytesEqual(FTarget.ReadMessage, FBytes) then
    raise ECardWorkflowError.Create('NDEF read-back mismatch.');
  FVerified := True;
  MutationPending(False);
  Progress(cwsVerifying, 1, 1);
end;

end.
