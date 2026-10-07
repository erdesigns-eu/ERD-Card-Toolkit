unit ERD.Card.Contactless.Type2.Ndef;

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
  ERD.Card.Transport, ERD.Card.Contactless, ERD.Card.Contactless.Type2, ERD.Card.Ndef;

type
  /// <summary>Invalid or unsupported Type 2 NDEF mapping; no memory contents in messages.</summary>
  EType2NdefError = class(EContactlessError);
  /// <summary>Decoded contiguous Type 2 data area, bounded by the Capability Container.</summary>
  /// <remarks>Returned buffers are independent. Ordinary record assignment shares them.</remarks>
  TType2NdefSnapshot = record
    /// <summary>Independent four-byte Capability Container.</summary>
    CapabilityContainer: TBytes;
    /// <summary>Advertised data-area capacity, not physical user-memory capacity.</summary>
    Capacity: Integer;
    /// <summary>True for CC write access F; physical locks are checked separately before writes.</summary>
    ReadOnly: Boolean;
    /// <summary>Distinguishes an absent TLV from an empty NDEF TLV.</summary>
    HasNdef: Boolean;
    /// <summary>User-memory offset of the NDEF TLV tag, or minus one when absent.</summary>
    TlvOffset: Integer;
    /// <summary>Two for a short TLV header, four for an extended header, zero when absent.</summary>
    HeaderBytes: Integer;
    /// <summary>True when another non-NULL TLV follows nonempty NDEF; empty-message tails are not interpreted.</summary>
    HasTrailingTlv: Boolean;
    /// <summary>Exact independent NDEF bytes, without TLV header or storage padding.</summary>
    MessageBytes: TBytes;
    /// <summary>Independent logical records; empty for an absent or zero-length NDEF TLV.</summary>
    Records: TNdefMessage;
  end;
  /// <summary>Four full user-memory images for a bounded, length-last NDEF replacement.</summary>
  /// <remarks>Images preserve bytes outside the new TLV/terminator. Assignment shares buffers.
  /// A failed multi-page update is not atomic; no automatic retry or rollback is safe.</remarks>
  TType2NdefWritePlan = record
    /// <summary>Original TLV with its existing length zeroed.</summary>
    Invalidated: TBytes;
    /// <summary>Zero-length short header used before changing header width.</summary>
    ShortEmpty: TBytes;
    /// <summary>Final payload/header/terminator with a zero published length; apply pages descending.</summary>
    Prepared: TBytes;
    /// <summary>Final memory with the message length published in one page.</summary>
    Committed: TBytes;
  end;
  /// <summary>Pure CC/TLV decoding and conservative contiguous-layout update planning.</summary>
  /// <remarks>Mapping version 1.0, public reads and CC write access zero/F are supported.
  /// Control TLVs outside the advertised data area are preserved; internal reserved holes are rejected.</remarks>
  TType2NdefMapping = class
  public
    /// <summary>Decodes a complete user snapshot and independently supplied CC.</summary>
    /// <param name="AModel">Caller-identified supported physical layout.</param>
    /// <param name="ACc">Exactly four CC bytes from page three.</param>
    /// <param name="AMemory">Complete physical user memory, including bytes beyond CC capacity.</param>
    /// <returns>Independent mapping snapshot; empty NDEF is distinguished from absence.</returns>
    /// <exception cref="EType2NdefError">CC, TLV lengths or reserved-memory layout are unsupported.</exception>
    /// <exception cref="ENdefError">Nonempty NDEF framing is invalid.</exception>
    class function Decode(const AModel: TType2TagModel; const ACc, AMemory: TBytes): TType2NdefSnapshot; static;
    /// <summary>Plans replacement of the existing last NDEF TLV without formatting or moving other TLVs.</summary>
    /// <param name="AModel">Explicit physical model.</param>
    /// <param name="ACc">Four CC bytes with public write access.</param>
    /// <param name="AMemory">Complete current user memory; never modified.</param>
    /// <param name="ANdef">Valid complete NDEF bytes, or empty to clear the existing TLV.</param>
    /// <returns>Independent phase images; physical lock checks are still required by the writer.</returns>
    /// <exception cref="EType2NdefError">Read-only, absent/trailing TLVs, capacity or cross-page extended-length publication is unsupported.</exception>
    /// <exception cref="ENdefError">Existing or requested nonempty NDEF is malformed.</exception>
    class function Prepare(const AModel: TType2TagModel;
      const ACc, AMemory, ANdef: TBytes): TType2NdefWritePlan; static;
  end;
  /// <summary>Non-visual transaction-scoped public Type 2 NDEF reader and verified writer.</summary>
  /// <remarks>No constructor I/O. Configure/call on one thread without reentrancy.
  /// Supplied page profile and ICardTransaction transport are mandatory. Password sessions,
  /// CC formatting, locking and automatic recovery are separate operations. Writes reject enabled
  /// mirror modes and password protection covering any user page; configuration is never changed.</remarks>
  TType2NdefCardReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FProfile: IType2ReaderProfile;
    function BeginOperation: ICardTransaction;
    procedure EndOperation(const ATx: ICardTransaction; const ASucceeded: Boolean);
    function Send(const ACommand: TBytes; const ASize: Integer): TBytes;
    function ReadPage(const APage: Integer): TBytes;
    function ReadMemory(const AModel: TType2TagModel): TBytes;
    procedure CheckLocks(const AModel: TType2TagModel);
    procedure CheckWriteAccess(const AModel: TType2TagModel);
    procedure Replace(const AModel: TType2TagModel; const ANdef: TBytes);
  public
    /// <summary>Creates an inactive component without opening a reader.</summary>
    /// <param name="AOwner">Optional component owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads CC and complete user memory in one exclusive transaction.</summary>
    /// <param name="AModel">Caller-identified physical model.</param>
    /// <returns>Complete decoded snapshot only after successful transaction release.</returns>
    /// <exception cref="EContactlessError">Configuration, reader status, mapping or response size fails.</exception>
    /// <exception cref="ENdefError">Message framing is malformed.</exception>
    function ReadMessage(const AModel: TType2TagModel): TType2NdefSnapshot;
    /// <summary>Replaces an existing NDEF TLV, checking public access, mirror configuration, model locks and each written page.</summary>
    /// <param name="AModel">Explicit supported model; public unprotected user memory is required.</param>
    /// <param name="AMessage">Nonempty records encoded before acquiring the transaction.</param>
    /// <exception cref="EContactlessError">Preflight, mapping, lock or reader checks fail before writing.</exception>
    /// <exception cref="ENdefError">Requested or existing message is invalid.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any failure after first write dispatch, including release.</exception>
    /// <remarks>Length is invalidated and verified before payload changes, then published last.
    /// Multi-page writes are not atomic. Exact full memory and unchanged CC are verified before release.</remarks>
    procedure WriteMessage(const AModel: TType2TagModel; const AMessage: TNdefMessage);
    /// <summary>Sets an existing NDEF TLV to zero length with the same guarded update protocol.</summary>
    /// <param name="AModel">Explicit physical model.</param>
    /// <exception cref="EContactlessError">Preflight or lock checks fail.</exception>
    /// <exception cref="EContactlessWriteUncertain">A dispatched write cannot be established as complete.</exception>
    procedure ClearMessage(const AModel: TType2TagModel);
    /// <summary>Retained caller-supplied transport with exclusive transaction capability.</summary>
    property Transport: ICardTransport read FTransport write FTransport;
    /// <summary>Explicit reader-compatible four-byte page command profile; no automatic reader detection.</summary>
    property Profile: IType2ReaderProfile read FProfile write FProfile;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Apdu;

procedure Fail;
begin raise EType2NdefError.Create('Invalid or unsupported Type 2 NDEF mapping or access.'); end;

class function TType2NdefMapping.Decode(const AModel: TType2TagModel;
  const ACc, AMemory: TBytes): TType2NdefSnapshot;
var P, TagOffset, N, Header, Position, PageUnit, Reserved: Integer; Tag: Byte;
begin
  Result := Default(TType2NdefSnapshot); Result.TlvOffset := -1;
  if Length(AMemory) <> TType2Layout.UserByteCount(AModel) then Fail;
  if Length(ACc) <> 4 then Fail;
  if (ACc[0] <> $E1) or (ACc[1] <> $10) or (ACc[2] = 0) or
    not ((ACc[3] = 0) or (ACc[3] = $0F)) then Fail;
  Result.Capacity := Integer(ACc[2]) * 8;
  if Result.Capacity > Length(AMemory) then Fail;
  Result.CapabilityContainer := CopyBytes(ACc); Result.ReadOnly := ACc[3] = $0F;
  P := 0;
  while P < Result.Capacity do
  begin
    TagOffset := P; Tag := AMemory[P]; Inc(P);
    if Tag = 0 then Continue;
    if Tag = $FE then Break;
    if not (Tag in [1, 2, 3, $FD]) then Fail;
    if P >= Result.Capacity then Fail;
    N := AMemory[P]; Inc(P); Header := 2;
    if N = $FF then
    begin
      if Result.Capacity - P < 2 then Fail;
      N := (Integer(AMemory[P]) shl 8) or AMemory[P + 1]; Inc(P, 2); Header := 4;
      // Zero is accepted for the transient empty extended header during updates.
      if (N <> 0) and (N < 255) then Fail;
    end;
    if N > Result.Capacity - P then Fail;
    if Tag in [1, 2] then
    begin
      if N <> 3 then Fail;
      PageUnit := 1 shl (AMemory[P + 2] and $0F);
      if (AMemory[P] and $0F) >= PageUnit then Fail;
      Position := (Integer(AMemory[P] shr 4) * PageUnit) + (AMemory[P] and $0F);
      Reserved := AMemory[P + 1]; if Reserved = 0 then Reserved := 256;
      if Tag = 1 then Reserved := (Reserved + 7) div 8
      else if (AMemory[P + 2] and $F0) <> 0 then Fail;
      // Only out-of-data-area control bytes: internal holes require another mapping implementation.
      if (Position < 16 + Result.Capacity) or
        (Position > TType2Layout.PageCount(AModel) * 4 - Reserved) then Fail;
      if Tag = 1 then
      begin
        // Only the model's real dynamic lock bytes; the writer checks all three.
        if AModel in [ttmUltralight, ttmUltralightEv1_48] then Fail;
        if (Position < (TType2Layout.LastUserPage(AModel) + 1) * 4) or
          (Position + Reserved > (TType2Layout.LastUserPage(AModel) + 1) * 4 + 3) then Fail;
      end;
    end;
    if Tag = 3 then
    begin
      if Result.HasNdef then Fail;
      Result.HasNdef := True; Result.TlvOffset := TagOffset; Result.HeaderBytes := Header;
      Result.MessageBytes := Copy(AMemory, P, N);
      if N > 0 then Result.Records := TNdefCodec.Decode(Result.MessageBytes)
      else Break; // A zero length also denotes an update in progress; payload bytes are not TLVs.
    end
    else if Result.HasNdef then Result.HasTrailingTlv := True;
    Inc(P, N);
  end;
end;

class function TType2NdefMapping.Prepare(const AModel: TType2TagModel;
  const ACc, AMemory, ANdef: TBytes): TType2NdefWritePlan;
var S: TType2NdefSnapshot; O, N, Header, EndOffset, I: Integer;
begin
  Result := Default(TType2NdefWritePlan); S := Decode(AModel, ACc, AMemory);
  if (Length(ANdef) > 0) then TNdefCodec.Decode(ANdef);
  if S.ReadOnly or not S.HasNdef or S.HasTrailingTlv then Fail;
  if Length(S.MessageBytes) = 0 then
  begin
    // Do not overwrite trailing TLVs or automatically recover an interrupted payload update.
    for I := S.TlvOffset + S.HeaderBytes to S.Capacity - 1 do
    begin
      if AMemory[I] = $FE then Break;
      if AMemory[I] <> 0 then Fail;
    end;
  end;
  N := Length(ANdef); O := S.TlvOffset; Header := 2;
  if N >= 255 then Header := 4;
  if N > S.Capacity - O - Header then Fail;
  // Both existing invalidation and final extended-length publication must fit one page.
  if ((S.HeaderBytes = 4) or (Header = 4)) and ((O + 2) div 4 <> (O + 3) div 4) then Fail;
  Result.Invalidated := CopyBytes(AMemory);
  if S.HeaderBytes = 2 then Result.Invalidated[O + 1] := 0
  else begin Result.Invalidated[O + 2] := 0; Result.Invalidated[O + 3] := 0; end;
  Result.ShortEmpty := CopyBytes(Result.Invalidated); Result.ShortEmpty[O + 1] := 0;
  Result.Committed := CopyBytes(AMemory);
  Result.Committed[O] := 3;
  if Header = 2 then Result.Committed[O + 1] := N
  else
  begin
    Result.Committed[O + 1] := $FF; Result.Committed[O + 2] := N shr 8;
    Result.Committed[O + 3] := N and $FF;
  end;
  if N > 0 then Move(ANdef[0], Result.Committed[O + Header], N);
  EndOffset := O + Header + N;
  if EndOffset < S.Capacity then Result.Committed[EndOffset] := $FE;
  Result.Prepared := CopyBytes(Result.Committed);
  if Header = 2 then Result.Prepared[O + 1] := 0
  else begin Result.Prepared[O + 2] := 0; Result.Prepared[O + 3] := 0; end;
end;

constructor TType2NdefCardReader.Create(AOwner: TComponent);
begin inherited Create(AOwner); end;

function TType2NdefCardReader.BeginOperation: ICardTransaction;
begin
  Result := nil;
  if (FTransport = nil) or (FProfile = nil) then Fail;
  if not Supports(FTransport, ICardTransaction, Result) then Fail;
  Result.BeginTransaction;
end;

procedure TType2NdefCardReader.EndOperation(const ATx: ICardTransaction; const ASucceeded: Boolean);
begin
  if ASucceeded then ATx.EndTransaction
  else begin try ATx.EndTransaction; except end; end;
end;

function TType2NdefCardReader.Send(const ACommand: TBytes; const ASize: Integer): TBytes;
var R: TApduResponse;
begin
  R := TApduCodec.DecodeResponse(FTransport.Exchange(ACommand));
  if R.StatusWord <> ApduStatusSuccess then raise EContactlessStatusError.Create(R.StatusWord);
  if Length(R.Data) <> ASize then Fail;
  Result := R.Data;
end;

function TType2NdefCardReader.ReadPage(const APage: Integer): TBytes;
begin Result := Send(FProfile.ReadPageCommand(Byte(APage)), 4); end;

function TType2NdefCardReader.ReadMemory(const AModel: TType2TagModel): TBytes;
var P: Integer; B: TBytes;
begin
  Result := nil; SetLength(Result, TType2Layout.UserByteCount(AModel));
  for P := 4 to TType2Layout.LastUserPage(AModel) do
  begin B := ReadPage(P); Move(B[0], Result[(P - 4) * 4], 4); end;
end;

procedure TType2NdefCardReader.CheckLocks(const AModel: TType2TagModel);
var B: TBytes;
begin
  B := ReadPage(2);
  // CC/block-lock bits alone do not lock user pages. Refuse any static user-page lock.
  if ((B[2] and $F0) <> 0) or (B[3] <> 0) then Fail;
  if not (AModel in [ttmUltralight, ttmUltralightEv1_48]) then
  begin
    B := ReadPage(TType2Layout.LastUserPage(AModel) + 1);
    // Conservative: also refuse dynamic block-lock/RFUI bits, without modifying them.
    if (B[0] <> 0) or (B[1] <> 0) or (B[2] <> 0) then Fail;
  end;
end;

procedure TType2NdefCardReader.CheckWriteAccess(const AModel: TType2TagModel);
var ConfigPage: Integer; B: TBytes;
begin
  if AModel = ttmUltralight then Exit;
  if AModel = ttmUltralightEv1_48 then ConfigPage := 16
  else ConfigPage := TType2Layout.LastUserPage(AModel) + 2;
  B := ReadPage(ConfigPage);
  // Require the entire user region to be publicly writable, without inheriting authentication.
  if B[3] <= TType2Layout.LastUserPage(AModel) then Fail;
  if (AModel in [ttmNtag213, ttmNtag215, ttmNtag216]) and ((B[0] and $C0) <> 0) then Fail;
end;

function TType2NdefCardReader.ReadMessage(const AModel: TType2TagModel): TType2NdefSnapshot;
var Tx: ICardTransaction; Cc, Memory: TBytes; S: TType2NdefSnapshot; Succeeded: Boolean;
begin
  Result := Default(TType2NdefSnapshot); TType2Layout.PageCount(AModel);
  Tx := BeginOperation; Succeeded := False;
  try
    Cc := ReadPage(3); Memory := ReadMemory(AModel); S := TType2NdefMapping.Decode(AModel, Cc, Memory);
    Succeeded := True;
  finally EndOperation(Tx, Succeeded); end;
  Result := S;
end;

procedure TType2NdefCardReader.Replace(const AModel: TType2TagModel; const ANdef: TBytes);
var Tx: ICardTransaction; Cc, Current, Verify, Wire, PageData: TBytes;
  S: TType2NdefSnapshot; Plan: TType2NdefWritePlan; Succeeded, Dispatched: Boolean;
  procedure Apply(const ATarget: TBytes; const ADescending: Boolean);
  var Index, PageIndex, Pages: Integer;
  begin
    Pages := Length(Current) div 4;
    for Index := 0 to Pages - 1 do
    begin
      if ADescending then PageIndex := Pages - Index - 1 else PageIndex := Index;
      PageData := Copy(ATarget, PageIndex * 4, 4);
      if BytesEqual(PageData, Copy(Current, PageIndex * 4, 4)) then Continue;
      Wire := FProfile.WritePageCommand(Byte(PageIndex + 4), PageData);
      Dispatched := True;
      Send(Wire, 0);
      if not BytesEqual(ReadPage(PageIndex + 4), PageData) then Fail;
      Move(PageData[0], Current[PageIndex * 4], 4);
    end;
  end;
begin
  TType2Layout.PageCount(AModel); Tx := BeginOperation;
  Succeeded := False; Dispatched := False;
  try
    try
      CheckWriteAccess(AModel); Cc := ReadPage(3); Current := ReadMemory(AModel);
      S := TType2NdefMapping.Decode(AModel, Cc, Current);
      Plan := TType2NdefMapping.Prepare(AModel, Cc, Current, ANdef); CheckLocks(AModel);
      if not BytesEqual(S.MessageBytes, ANdef) then
      begin
        Apply(Plan.Invalidated, False); Apply(Plan.ShortEmpty, False);
        Apply(Plan.Prepared, True); Apply(Plan.Committed, False);
        Verify := ReadMemory(AModel);
        if not BytesEqual(Verify, Plan.Committed) or not BytesEqual(ReadPage(3), Cc) then Fail;
      end;
      Succeeded := True;
    finally EndOperation(Tx, Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

procedure TType2NdefCardReader.WriteMessage(const AModel: TType2TagModel; const AMessage: TNdefMessage);
var Wire: TBytes;
begin Wire := TNdefCodec.Encode(AMessage); Replace(AModel, Wire); end;

procedure TType2NdefCardReader.ClearMessage(const AModel: TType2TagModel);
begin Replace(AModel, nil); end;

end.
