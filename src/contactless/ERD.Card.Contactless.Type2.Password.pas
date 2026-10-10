unit ERD.Card.Contactless.Type2.Password;

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
  ERD.Card.Transport, ERD.Card.Contactless, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2, ERD.Card.Contactless.Type2.Ndef;

type
  /// <summary>A dispatched PWD_AUTH was rejected or could not be verified; no remaining attempt budget is inferred.</summary>
  /// <remarks>Never automatically retry: a failed or ambiguous attempt can consume the card's AUTHLIM budget.
  /// Messages retain no password, PACK, received bytes or backend exception message.</remarks>
  EType2AuthenticationError = class(EContactlessError)
  private
    FOriginalErrorClass: string;
  public
    /// <summary>Creates a sanitized authentication-attempt failure.</summary>
    /// <param name="AOriginalErrorClass">Class name of the original framing, verification or transport failure.</param>
    constructor Create(const AOriginalErrorClass: string); reintroduce;
    /// <summary>Original failure class, without its potentially sensitive message.</summary>
    property OriginalErrorClass: string read FOriginalErrorClass;
  end;
  /// <summary>Stateless password-model validation and bounded user-only FAST_READ commands.</summary>
  TType2PasswordCodec = class
  public
    /// <summary>Validates an explicit PWD_AUTH model and caller-supplied credentials without I/O.</summary>
    /// <param name="AModel">Ultralight EV1 48/128 or NTAG210/212/213/215/216; original Ultralight is excluded.</param>
    /// <param name="APassword">Exactly four bytes in card/wire order; never reversed or modified.</param>
    /// <param name="AExpectedPack">Exactly two expected response bytes in card/wire order; never modified.</param>
    /// <exception cref="EType2DataError">Model or credential length is unsupported.</exception>
    class procedure ValidateCredentials(const AModel: TType2TagModel;
      const APassword, AExpectedPack: TBytes); static;
    /// <summary>Checks a one-to-sixteen-page range wholly inside user memory.</summary>
    /// <param name="AModel">Explicit supported PWD_AUTH model.</param>
    /// <param name="AFirstPage">First physical user page, at least four.</param>
    /// <param name="APageCount">One to sixteen pages; range must end at or before LastUserPage.</param>
    /// <exception cref="EType2DataError">Model, page, count or range crosses a protected/configuration region.</exception>
    class procedure ValidateUserRange(const AModel: TType2TagModel;
      const AFirstPage, APageCount: Integer); static;
    /// <summary>Builds one bounded user-memory FAST_READ frame with explicit CRC-A.</summary>
    /// <param name="AModel">Supported PWD_AUTH model.</param>
    /// <param name="AFirstPage">First physical user page.</param>
    /// <param name="APageCount">One to sixteen user pages; no wraparound or excluded pages.</param>
    /// <returns>Independent five-byte 3A/start/end/CRC frame; no password data.</returns>
    /// <exception cref="EType2DataError">Requested model/range is invalid.</exception>
    class function BuildFastReadCommand(const AModel: TType2TagModel;
      const AFirstPage, APageCount: Integer): TBytes; static;
  end;
  /// <summary>Owned non-secret configuration pages for one explicit password-capable Type 2 model.</summary>
  TType2AuthenticationConfiguration = record
    /// <summary>Explicit physical model used to acquire this configuration.</summary>
    Model: TType2TagModel;
    /// <summary>First physical configuration page; PWD and PACK pages are excluded.</summary>
    FirstPage: Byte;
    /// <summary>AUTH0 address; values beyond the final user page disable user-memory protection.</summary>
    FirstProtectedPage: Byte;
    /// <summary>True protects reads and writes; false protects only writes.</summary>
    ProtectReads: Boolean;
    /// <summary>AUTHLIM value 0..7; zero disables the negative authentication limit.</summary>
    AuthenticationLimit: Byte;
    /// <summary>CFGLCK permanently locks these configuration pages, while credentials remain separately writable.</summary>
    ConfigurationLocked: Boolean;
    /// <summary>True when an NTAG mirror is configured; NDEF writes refuse mirrored memory.</summary>
    MirrorConfigured: Boolean;
    /// <summary>NFC_CNT_EN for NTAG213/215/216; false for models without this configuration bit.</summary>
    NfcCounterEnabled: Boolean;
    /// <summary>Independent eight-byte configuration preimage; no stored password or PACK bytes.</summary>
    RawPages: TBytes;
  end;
  /// <summary>Nonvisual supplied-password user-memory access for Ultralight EV1 and NTAG210/212/213/215/216.</summary>
  /// <remarks>Construction performs no I/O. Each operation acquires one exclusive raw Type A session,
  /// freshly selects, dispatches PWD_AUTH once, validates PACK, and retains authentication until release.
  /// Configure/call on one thread without reentrancy. No password guessing or retries. Dedicated management preserves locks and unrelated configuration.
  /// Password verification is plaintext access control, not secure messaging or proof of card authenticity.</remarks>
  TType2PasswordCardReader = class(TComponent)
  private
    FReader: IRawContactlessReader;
    FBusy: Boolean;
    FSelectedUid: TBytes;
    procedure SetReader(const AValue: IRawContactlessReader);
    procedure Reactivate(const APassword, APack: TBytes);
    function Configuration(const AModel: TType2TagModel): TType2AuthenticationConfiguration;
    function RawPages(const AModel: TType2TagModel; const APage, ACount: Integer): TBytes;
    function Memory(const AModel: TType2TagModel): TBytes;
    procedure ProgramPage(const APage: Byte; const AData: TBytes; var ADispatched: Boolean);
    procedure ReleaseSession(const ASucceeded: Boolean);
    procedure Authenticate(const APassword, AExpectedPack: TBytes);
    procedure AcquireAndAuthenticate(const APassword, AExpectedPack: TBytes);
    function ReadRange(const AModel: TType2TagModel; const AFirstPage, APageCount: Integer): TBytes;
    procedure RequireAck(const AResponse: TRawRfResponse);
  public
    /// <summary>Creates an inactive component without a raw reader.</summary>
    /// <param name="AOwner">Optional component owner; nil requires caller Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Authenticates once and reads exactly one user page in the same RF session.</summary>
    /// <param name="AModel">Caller-identified Ultralight EV1 48/128 or NTAG210/212/213/215/216.</param>
    /// <param name="APage">Physical user page; manufacturer, lock and configuration pages are excluded.</param>
    /// <param name="APassword">Exactly four supplied card-order bytes; never guessed, retained or modified.</param>
    /// <param name="AExpectedPack">Exactly two supplied card-order PACK bytes; comparison is mandatory.</param>
    /// <returns>Independent four-byte reader-visible page, only after successful release.</returns>
    /// <exception cref="EType2DataError">Model, page or credential sizes are invalid before I/O.</exception>
    /// <exception cref="EType2AuthenticationError">The sole dispatched authentication attempt is rejected or cannot be verified.</exception>
    /// <exception cref="EContactlessError">Reader, fresh selection, read response or CRC/framing is invalid.</exception>
    /// <exception cref="ECardTransportError">Backend acquisition, selection, range reading or release fails.</exception>
    /// <remarks>Local password-bearing command and authentication-response copies are overwritten on every exit;
    /// external backend/transport copies are outside that guarantee. AUTHLIM can permanently lock protected memory.
    /// Authentication and enabled automatic NFC counters can change card state even during a read operation.</remarks>
    function ReadUserPage(const AModel: TType2TagModel; const APage: Integer;
      const APassword, AExpectedPack: TBytes): TBytes;
    /// <summary>Authenticates once and reads the complete user region in bounded ascending FAST_READ ranges.</summary>
    /// <param name="AModel">Explicit supported PWD_AUTH model.</param>
    /// <param name="APassword">Four supplied card-order bytes; never modified or retained.</param>
    /// <param name="AExpectedPack">Two expected card-order PACK bytes; never modified.</param>
    /// <returns>Complete independent TType2UserMemory after successful release; no partial snapshot on failure.</returns>
    /// <exception cref="EType2DataError">Model or credential length is unsupported.</exception>
    /// <exception cref="EType2AuthenticationError">The sole authentication attempt failed verification or completion.</exception>
    /// <exception cref="EContactlessError">Reader, fresh selection or any range response is invalid.</exception>
    /// <exception cref="ECardTransportError">Backend acquisition, selection, range reading or release fails.</exception>
    /// <remarks>At most sixteen user pages per frame, without manufacturer/configuration reads or RF reset between
    /// ranges. At most 888 bytes per snapshot. Credential wiping and AUTHLIM/state effects match ReadUserPage.
    /// Enabled mirror features can affect reader-visible bytes; this is not an NDEF or backing-EEPROM interpretation.</remarks>
    function ReadUserMemory(const AModel: TType2TagModel;
      const APassword, AExpectedPack: TBytes): TType2UserMemory;
    /// <summary>Authenticates once, writes one user page once, and verifies all four bytes in the retained session.</summary>
    /// <param name="AModel">Explicit supported PWD_AUTH model.</param>
    /// <param name="APage">User page; every manufacturer, lock, OTP/CC and configuration page is rejected before I/O.</param>
    /// <param name="APassword">Four supplied card-order password bytes; never guessed or modified.</param>
    /// <param name="AExpectedPack">Two expected card-order PACK bytes; mandatory verification.</param>
    /// <param name="AData">Exactly four caller-owned page bytes; never modified.</param>
    /// <exception cref="EType2DataError">Model, user page, data or credential lengths are invalid before I/O.</exception>
    /// <exception cref="EType2AuthenticationError">The sole authentication attempt failed before page-write dispatch.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any failure after page-write dispatch, including NAK, read-back or release.</exception>
    /// <exception cref="EContactlessError">Reader or initial selection is invalid before writing.</exception>
    /// <exception cref="ECardTransportError">Backend acquisition or initial selection fails before page-write dispatch.</exception>
    /// <remarks>One A2 write with a four-bit ACK and one exact-page FAST_READ verification; no reset/reauthentication,
    /// replay, rollback, lock-bit changes or password updates. Success requires identical read-back and successful
    /// release; the card still enforces physical locks/access conditions. Inspect actual state after uncertain writing.
    /// Credential wiping, external-copy limits and AUTHLIM effects match ReadUserPage.</remarks>
    procedure WriteUserPage(const AModel: TType2TagModel; const APage: Integer;
      const APassword, AExpectedPack, AData: TBytes);
    /// <summary>Authenticates and reads the two public configuration pages without reading PWD/PACK storage.</summary>
    /// <param name="AModel">Explicit supported password-capable physical model.</param>
    /// <param name="APassword">Four supplied current password bytes.</param>
    /// <param name="AExpectedPack">Two expected current PACK bytes.</param>
    /// <returns>Owned configuration after successful session release.</returns>
    function ReadConfiguration(const AModel: TType2TagModel;
      const APassword, AExpectedPack: TBytes): TType2AuthenticationConfiguration;
    /// <summary>Changes only AUTH0, PROT and AUTHLIM after exact preimage/lock checks, then verifies fresh authentication and configuration.</summary>
    /// <param name="AModel">Explicit supported physical model.</param>
    /// <param name="AFirstProtectedPage">Explicit AUTH0 byte; no inferred protection boundary.</param>
    /// <param name="AProtectReads">True protects reads and writes; false protects only writes.</param>
    /// <param name="AAuthenticationLimit">AUTHLIM 0..7; zero disables the limit.</param>
    /// <param name="AExpectedPages">Exact eight configuration bytes from ReadConfiguration.</param>
    /// <param name="APassword">Four current bytes, copied before I/O.</param>
    /// <param name="AExpectedPack">Two expected PACK bytes, copied before I/O.</param>
    /// <returns>Owned verified configuration, preserving CFGLCK, mirror/counter and reserved bits.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after write dispatch; no replay or rollback.</exception>
    function ConfigureAuthenticationVerified(const AModel: TType2TagModel;
      const AFirstProtectedPage: Byte; const AProtectReads: Boolean; const AAuthenticationLimit: Byte;
      const AExpectedPages, APassword, AExpectedPack: TBytes): TType2AuthenticationConfiguration;
    /// <summary>Writes PACK then PWD once and proves the replacement through fresh same-UID RF authentication.</summary>
    /// <param name="AModel">Explicit supported model; no credential discovery.</param>
    /// <param name="ACurrentPassword">Four current password bytes, copied before I/O.</param>
    /// <param name="ACurrentPack">Two current expected PACK bytes.</param>
    /// <param name="ANewPassword">Four replacement bytes in wire order.</param>
    /// <param name="ANewPack">Two replacement bytes; PACK page RFUI bytes are written as mandated zero.</param>
    /// <returns>True only after fresh PWD_AUTH/PACK proof and successful release; unchanged credentials still receive fresh proof.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after first credential write; stored credentials cannot be read back.</exception>
    function ChangeCredentialsVerified(const AModel: TType2TagModel;
      const ACurrentPassword, ACurrentPack, ANewPassword, ANewPack: TBytes): Boolean;
    /// <summary>Reads one supported 24-bit counter after supplied-password authentication.</summary>
    /// <param name="AModel">Ultralight EV1 48/128 or NTAG213/215/216; NTAG210/212 have no READ_CNT profile.</param>
    /// <param name="ACounter">EV1 counter 0..2; NTAG NFC counter must be 2.</param>
    /// <param name="APassword">Four supplied current bytes.</param>
    /// <param name="AExpectedPack">Two mandatory expected PACK bytes.</param>
    /// <returns>Card-reported 24-bit little-endian value; no remaining authentication budget is inferred.</returns>
    function ReadCounter(const AModel: TType2TagModel; const ACounter: Byte;
      const APassword, AExpectedPack: TBytes): Cardinal;
    /// <summary>Reads complete NDEF through one retained password-authenticated RF session.</summary>
    /// <param name="AModel">Explicit supported physical model.</param>
    /// <param name="APassword">Four supplied current bytes.</param>
    /// <param name="AExpectedPack">Two mandatory expected PACK bytes.</param>
    /// <returns>Owned CC, NDEF bytes and parsed records after full read and release.</returns>
    function ReadNdef(const AModel: TType2TagModel;
      const APassword, AExpectedPack: TBytes): TType2NdefSnapshot;
    /// <summary>Replaces an existing contiguous NDEF TLV in one authenticated session using invalidation, length-last publication and full readback.</summary>
    /// <param name="AModel">Explicit supported model; enabled mirrors and existing user locks are refused.</param>
    /// <param name="ANdef">Complete valid NDEF bytes; empty clears an existing TLV.</param>
    /// <param name="APassword">Four current bytes, copied before I/O.</param>
    /// <param name="AExpectedPack">Two mandatory expected PACK bytes, copied before I/O.</param>
    /// <returns>Owned independently verified snapshot after unchanged CC, full memory comparison and release.</returns>
    /// <exception cref="EContactlessWriteUncertain">Any failure after first write; multi-page updates are not atomic and are never replayed.</exception>
    function WriteNdefVerified(const AModel: TType2TagModel;
      const ANdef, APassword, AExpectedPack: TBytes): TType2NdefSnapshot;
    /// <summary>True while this component owns one RF operation; not a card-presence indicator.</summary>
    property Busy: Boolean read FBusy;
    /// <summary>Retained matching raw-reader backend; nil disables operations. Do not change during an active call.</summary>
    property Reader: IRawContactlessReader read FReader write SetReader;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Ndef;

const ReadChunkPages = 16;

procedure Fail(const AReason: string);
begin
  raise EContactlessError.Create('Type 2 password operation failed: ' + AReason + '.');
end;

function LastUserPage(const AModel: TType2TagModel): Integer;
begin
  Result := TType2Layout.LastUserPage(AModel);
  if AModel = ttmUltralight then raise EType2DataError.Create('Original Ultralight has no PWD_AUTH profile.');
end;

constructor EType2AuthenticationError.Create(const AOriginalErrorClass: string);
begin
  inherited Create('Type 2 authentication was not verified; do not blindly repeat the attempt.');
  FOriginalErrorClass := AOriginalErrorClass;
end;

class procedure TType2PasswordCodec.ValidateCredentials(const AModel: TType2TagModel;
  const APassword, AExpectedPack: TBytes);
var LastPage: Integer;
begin
  LastPage := LastUserPage(AModel);
  if (LastPage < Type2FirstUserPage) or (Length(APassword) <> 4) or (Length(AExpectedPack) <> 2) then
    raise EType2DataError.Create('Invalid Type 2 password credential sizes.');
end;

class procedure TType2PasswordCodec.ValidateUserRange(const AModel: TType2TagModel;
  const AFirstPage, APageCount: Integer);
var LastPage: Integer;
begin
  LastPage := LastUserPage(AModel);
  if (AFirstPage < Type2FirstUserPage) or (AFirstPage > LastPage) then
    raise EType2DataError.Create('Invalid Type 2 user range.');
  if (APageCount < 1) or (APageCount > ReadChunkPages) then
    raise EType2DataError.Create('Invalid Type 2 read count.');
  if APageCount > LastPage - AFirstPage + 1 then
    raise EType2DataError.Create('Type 2 read range crosses excluded pages.');
end;

class function TType2PasswordCodec.BuildFastReadCommand(const AModel: TType2TagModel;
  const AFirstPage, APageCount: Integer): TBytes;
var Payload: TBytes;
begin
  ValidateUserRange(AModel, AFirstPage, APageCount);
  SetLength(Payload, 3);
  Payload[0] := $3A;
  Payload[1] := Byte(AFirstPage);
  Payload[2] := Byte(AFirstPage + APageCount - 1);
  Result := TRawUidCodec.AppendCrcA(Payload);
end;

constructor TType2PasswordCardReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TType2PasswordCardReader.ReleaseSession(const ASucceeded: Boolean);
begin
  try
    if ASucceeded then FReader.EndSession else try FReader.EndSession; except end;
  finally FSelectedUid := nil; FBusy := False; end;
end;

procedure TType2PasswordCardReader.Authenticate(const APassword, AExpectedPack: TBytes);
var Payload, Wire, Pack: TBytes; Response: TRawRfResponse; Dispatched: Boolean;
begin
  Response := Default(TRawRfResponse);
  Dispatched := False;
  try
    try
      SetLength(Payload, 5);
      Payload[0] := $1B;
      Move(APassword[0], Payload[1], 4);
      Wire := TRawUidCodec.AppendCrcA(Payload);
      Dispatched := True;
      Response := FReader.Exchange(Wire, Length(Wire) * 8);
      Pack := TRawUidCodec.DecodeCrcA(Response, 2);
      if ((Pack[0] xor AExpectedPack[0]) or (Pack[1] xor AExpectedPack[1])) <> 0 then
        Fail('PACK verification mismatch');
    except
      on E: Exception do
      begin
        if Dispatched then raise EType2AuthenticationError.Create(E.ClassName);
        raise;
      end;
    end;
  finally
    if Length(Payload) > 0 then FillChar(Payload[0], Length(Payload), 0);
    if Length(Wire) > 0 then FillChar(Wire[0], Length(Wire), 0);
    if Length(Pack) > 0 then FillChar(Pack[0], Length(Pack), 0);
    if Length(Response.Data) > 0 then FillChar(Response.Data[0], Length(Response.Data), 0);
  end;
end;

procedure TType2PasswordCardReader.AcquireAndAuthenticate(const APassword, AExpectedPack: TBytes);
var Uid: TBytes;
begin
  if FBusy then Fail('operation already active');
  if FReader = nil then Fail('raw reader missing');
  FBusy := True;
  try FReader.BeginSession; except FBusy := False; raise; end;
  try
    Uid := FReader.Activate;
    if Length(Uid) <> 7 then Fail('selected UID must have seven bytes');
    if Uid[3] = $88 then Fail('selected UID has an invalid cascade position');
    FSelectedUid := CopyBytes(Uid);
    Authenticate(APassword, AExpectedPack);
  except
    ReleaseSession(False);
    raise;
  end;
end;

function TType2PasswordCardReader.ReadRange(const AModel: TType2TagModel;
  const AFirstPage, APageCount: Integer): TBytes;
var Wire: TBytes;
begin
  Wire := TType2PasswordCodec.BuildFastReadCommand(AModel, AFirstPage, APageCount);
  Result := TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire, Length(Wire) * 8), APageCount * Type2PageBytes);
end;

procedure TType2PasswordCardReader.RequireAck(const AResponse: TRawRfResponse);
begin
  if AResponse.TimedOut or (AResponse.BitCount <> 4) or (Length(AResponse.Data) <> 1) then
    Fail('missing four-bit write acknowledgment');
  if (AResponse.Data[0] and $0F) <> $0A then Fail('card denied user-page write');
end;

function TType2PasswordCardReader.ReadUserPage(const AModel: TType2TagModel; const APage: Integer;
  const APassword, AExpectedPack: TBytes): TBytes;
var Data: TBytes; Succeeded: Boolean;
begin
  Result := nil;
  TType2PasswordCodec.ValidateCredentials(AModel, APassword, AExpectedPack);
  TType2PasswordCodec.ValidateUserRange(AModel, APage, 1);
  AcquireAndAuthenticate(APassword, AExpectedPack);
  Succeeded := False;
  try
    Data := ReadRange(AModel, APage, 1);
    Succeeded := True;
  finally ReleaseSession(Succeeded); end;
  Result := Data;
end;

function TType2PasswordCardReader.ReadUserMemory(const AModel: TType2TagModel;
  const APassword, AExpectedPack: TBytes): TType2UserMemory;
var Data: TType2UserMemory; Chunk: TBytes; Page, LastPage, Count, Offset: Integer; Succeeded: Boolean;
begin
  Result := Default(TType2UserMemory);
  TType2PasswordCodec.ValidateCredentials(AModel, APassword, AExpectedPack);
  LastPage := LastUserPage(AModel);
  Data := Default(TType2UserMemory);
  Data.Model := AModel;
  Data.FirstPage := Type2FirstUserPage;
  Data.PageCount := LastPage - Type2FirstUserPage + 1;
  SetLength(Data.Data, Data.PageCount * Type2PageBytes);
  AcquireAndAuthenticate(APassword, AExpectedPack);
  Succeeded := False;
  try
    Page := Type2FirstUserPage;
    Offset := 0;
    while Page <= LastPage do
    begin
      Count := LastPage - Page + 1;
      if Count > ReadChunkPages then Count := ReadChunkPages;
      Chunk := ReadRange(AModel, Page, Count);
      Move(Chunk[0], Data.Data[Offset], Length(Chunk));
      Inc(Offset, Length(Chunk));
      Inc(Page, Count);
    end;
    Succeeded := True;
  finally ReleaseSession(Succeeded); end;
  Result := Data;
end;

procedure TType2PasswordCardReader.WriteUserPage(const AModel: TType2TagModel; const APage: Integer;
  const APassword, AExpectedPack, AData: TBytes);
var Wire, Verified: TBytes; Succeeded, Dispatched: Boolean;
begin
  TType2PasswordCodec.ValidateCredentials(AModel, APassword, AExpectedPack);
  TType2PasswordCodec.ValidateUserRange(AModel, APage, 1);
  if Length(AData) <> Type2PageBytes then raise EType2DataError.Create('Invalid Type 2 page data size.');
  SetLength(Wire, 6);
  Wire[0] := $A2;
  Wire[1] := Byte(APage);
  Move(AData[0], Wire[2], Type2PageBytes);
  Wire := TRawUidCodec.AppendCrcA(Wire);
  AcquireAndAuthenticate(APassword, AExpectedPack);
  Succeeded := False;
  Dispatched := False;
  try
    try
      Dispatched := True;
      RequireAck(FReader.Exchange(Wire, Length(Wire) * 8));
      Verified := ReadRange(AModel, APage, 1);
      if not BytesEqual(Verified, AData) then Fail('user-page read-back mismatch');
      Succeeded := True;
    finally ReleaseSession(Succeeded); end;
  except
    on E: Exception do
    begin
      if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName);
      raise;
    end;
  end;
end;

procedure TType2PasswordCardReader.SetReader(const AValue: IRawContactlessReader);
begin if FBusy then Fail('operation already active'); FReader := AValue; end;

procedure TType2PasswordCardReader.Reactivate(const APassword, APack: TBytes);
var Uid: TBytes;
begin
  Uid := FReader.Activate;
  if not BytesEqual(Uid, FSelectedUid) then Fail('selected card changed');
  Authenticate(APassword, APack);
end;

function ConfigurationPage(const AModel: TType2TagModel): Integer;
begin LastUserPage(AModel); Result := TType2Layout.PageCount(AModel)-4; end;

function TType2PasswordCardReader.RawPages(const AModel: TType2TagModel; const APage, ACount: Integer): TBytes;
var Wire: TBytes;
begin
  if (APage<0) or (ACount<1) or (ACount>16) or (APage>TType2Layout.PageCount(AModel)-ACount) then Fail('invalid raw range');
  SetLength(Wire,3); Wire[0]:=$3A; Wire[1]:=APage; Wire[2]:=APage+ACount-1;
  Wire:=TRawUidCodec.AppendCrcA(Wire);
  Result:=TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,Length(Wire)*8),ACount*4);
end;

function TType2PasswordCardReader.Configuration(const AModel: TType2TagModel): TType2AuthenticationConfiguration;
begin
  Result:=Default(TType2AuthenticationConfiguration); Result.Model:=AModel;
  Result.FirstPage:=ConfigurationPage(AModel); Result.RawPages:=RawPages(AModel,Result.FirstPage,2);
  Result.FirstProtectedPage:=Result.RawPages[3]; Result.ProtectReads:=(Result.RawPages[4] and $80)<>0;
  Result.AuthenticationLimit:=Result.RawPages[4] and 7; Result.ConfigurationLocked:=(Result.RawPages[4] and $40)<>0;
  if AModel in [ttmNtag210,ttmNtag212] then Result.MirrorConfigured:=Result.RawPages[2]>3
  else if AModel in [ttmNtag213,ttmNtag215,ttmNtag216] then begin
    Result.MirrorConfigured:=(Result.RawPages[0] and $C0)<>0; Result.NfcCounterEnabled:=(Result.RawPages[4] and $10)<>0;
  end;
end;

function TType2PasswordCardReader.Memory(const AModel: TType2TagModel): TBytes;
var Page,Count,Last: Integer; Chunk: TBytes;
begin
  Result:=nil; Last:=LastUserPage(AModel); SetLength(Result,TType2Layout.UserByteCount(AModel)); Page:=4;
  while Page<=Last do begin
    Count:=Last-Page+1; if Count>16 then Count:=16;
    Chunk:=ReadRange(AModel,Page,Count); Move(Chunk[0],Result[(Page-4)*4],Length(Chunk)); Inc(Page,Count);
  end;
end;

procedure TType2PasswordCardReader.ProgramPage(const APage: Byte; const AData: TBytes; var ADispatched: Boolean);
var Payload,Wire: TBytes;
begin
  Payload:=nil; Wire:=nil;
  try
    if Length(AData)<>4 then Fail('invalid page size'); SetLength(Payload,6);
    Payload[0]:=$A2; Payload[1]:=APage; Move(AData[0],Payload[2],4); Wire:=TRawUidCodec.AppendCrcA(Payload);
    ADispatched:=True; RequireAck(FReader.Exchange(Wire,Length(Wire)*8));
  finally
    if Length(Payload)>0 then FillChar(Payload[0],Length(Payload),0);
    if Length(Wire)>0 then FillChar(Wire[0],Length(Wire),0);
  end;
end;

function TType2PasswordCardReader.ReadConfiguration(const AModel: TType2TagModel;
  const APassword, AExpectedPack: TBytes): TType2AuthenticationConfiguration;
var C: TType2AuthenticationConfiguration; Succeeded: Boolean;
begin
  Result:=Default(TType2AuthenticationConfiguration); TType2PasswordCodec.ValidateCredentials(AModel,APassword,AExpectedPack);
  AcquireAndAuthenticate(APassword,AExpectedPack); Succeeded:=False;
  try C:=Configuration(AModel); Succeeded:=True; finally ReleaseSession(Succeeded); end; Result:=C;
end;

function TType2PasswordCardReader.ConfigureAuthenticationVerified(const AModel: TType2TagModel;
  const AFirstProtectedPage: Byte; const AProtectReads: Boolean; const AAuthenticationLimit: Byte;
  const AExpectedPages, APassword, AExpectedPack: TBytes): TType2AuthenticationConfiguration;
var P,K,Expected,Desired: TBytes; Before,After: TType2AuthenticationConfiguration; Succeeded,Dispatched: Boolean;
begin
  Result:=Default(TType2AuthenticationConfiguration); Dispatched:=False;
  TType2PasswordCodec.ValidateCredentials(AModel,APassword,AExpectedPack);
  if (AAuthenticationLimit>7) or (Length(AExpectedPages)<>8) then Fail('invalid configuration input');
  P:=CopyBytes(APassword); K:=CopyBytes(AExpectedPack); Expected:=CopyBytes(AExpectedPages); Desired:=CopyBytes(Expected);
  try
    Desired[3]:=AFirstProtectedPage; Desired[4]:=(Desired[4] and $78) or AAuthenticationLimit;
    if AProtectReads then Desired[4]:=Desired[4] or $80;
    try
      AcquireAndAuthenticate(P,K); Succeeded:=False;
      try
        Before:=Configuration(AModel); if not BytesEqual(Before.RawPages,Expected) then Fail('configuration preimage changed');
        if not BytesEqual(Expected,Desired) and Before.ConfigurationLocked then Fail('configuration locked');
        if not BytesEqual(Copy(Expected,4,4),Copy(Desired,4,4)) then ProgramPage(Before.FirstPage+1,Copy(Desired,4,4),Dispatched);
        if not BytesEqual(Copy(Expected,0,4),Copy(Desired,0,4)) then ProgramPage(Before.FirstPage,Copy(Desired,0,4),Dispatched);
        Reactivate(P,K); After:=Configuration(AModel);
        if not BytesEqual(After.RawPages,Desired) then Fail('configuration verification failed'); Succeeded:=True;
      finally ReleaseSession(Succeeded); end;
      Result:=After;
    except on E: Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally FillChar(P[0],Length(P),0); FillChar(K[0],Length(K),0); end;
end;

function TType2PasswordCardReader.ChangeCredentialsVerified(const AModel: TType2TagModel;
  const ACurrentPassword, ACurrentPack, ANewPassword, ANewPack: TBytes): Boolean;
var P,K,NewP,NewK,PackPage: TBytes; Succeeded,Dispatched: Boolean; Page: Integer;
begin
  Dispatched:=False;
  TType2PasswordCodec.ValidateCredentials(AModel,ACurrentPassword,ACurrentPack);
  TType2PasswordCodec.ValidateCredentials(AModel,ANewPassword,ANewPack); Page:=ConfigurationPage(AModel);
  P:=CopyBytes(ACurrentPassword); K:=CopyBytes(ACurrentPack); NewP:=CopyBytes(ANewPassword); NewK:=CopyBytes(ANewPack);
  SetLength(PackPage,4); Move(NewK[0],PackPage[0],2);
  try
    try
      AcquireAndAuthenticate(P,K); Succeeded:=False;
      try
        if not BytesEqual(P,NewP) or not BytesEqual(K,NewK) then begin
          ProgramPage(Page+3,PackPage,Dispatched); ProgramPage(Page+2,NewP,Dispatched);
        end;
        Reactivate(NewP,NewK); Succeeded:=True;
      finally ReleaseSession(Succeeded); end;
      Result:=True;
    except on E: Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally
    FillChar(P[0],Length(P),0); FillChar(K[0],Length(K),0); FillChar(NewP[0],Length(NewP),0);
    FillChar(NewK[0],Length(NewK),0); FillChar(PackPage[0],Length(PackPage),0);
  end;
end;

function TType2PasswordCardReader.ReadCounter(const AModel: TType2TagModel; const ACounter: Byte;
  const APassword, AExpectedPack: TBytes): Cardinal;
var Wire,Data: TBytes; Succeeded: Boolean; Value: Cardinal;
begin
  TType2PasswordCodec.ValidateCredentials(AModel,APassword,AExpectedPack);
  if not (AModel in [ttmUltralightEv1_48,ttmUltralightEv1_128,ttmNtag213,ttmNtag215,ttmNtag216]) or
    (ACounter>2) or ((AModel in [ttmNtag213,ttmNtag215,ttmNtag216]) and (ACounter<>2)) then Fail('unsupported counter');
  Wire:=TRawUidCodec.AppendCrcA(TBytes.Create($39,ACounter)); AcquireAndAuthenticate(APassword,AExpectedPack); Succeeded:=False;
  try
    Data:=TRawUidCodec.DecodeCrcA(FReader.Exchange(Wire,Length(Wire)*8),3);
    Value:=Cardinal(Data[0]) or (Cardinal(Data[1]) shl 8) or (Cardinal(Data[2]) shl 16); Succeeded:=True;
  finally ReleaseSession(Succeeded); end; Result:=Value;
end;

function TType2PasswordCardReader.ReadNdef(const AModel: TType2TagModel;
  const APassword, AExpectedPack: TBytes): TType2NdefSnapshot;
var Cc,Data: TBytes; S: TType2NdefSnapshot; Succeeded: Boolean;
begin
  Result:=Default(TType2NdefSnapshot); TType2PasswordCodec.ValidateCredentials(AModel,APassword,AExpectedPack);
  AcquireAndAuthenticate(APassword,AExpectedPack); Succeeded:=False;
  try Cc:=RawPages(AModel,3,1); Data:=Memory(AModel); S:=TType2NdefMapping.Decode(AModel,Cc,Data);
    Succeeded:=True; finally ReleaseSession(Succeeded); end; Result:=S;
end;

function TType2PasswordCardReader.WriteNdefVerified(const AModel: TType2TagModel;
  const ANdef, APassword, AExpectedPack: TBytes): TType2NdefSnapshot;
var Cc,Current,Verify,Locks,P,K,Ndef: TBytes; Config: TType2AuthenticationConfiguration;
  Plan: TType2NdefWritePlan; Snapshot: TType2NdefSnapshot; Succeeded,Dispatched: Boolean;
  procedure Apply(const Target: TBytes; const Descending: Boolean);
  var I,PageIndex,Pages: Integer; Data: TBytes;
  begin
    Pages:=Length(Current) div 4;
    for I:=0 to Pages-1 do begin
      PageIndex:=I; if Descending then PageIndex:=Pages-I-1; Data:=Copy(Target,PageIndex*4,4);
      if BytesEqual(Data,Copy(Current,PageIndex*4,4)) then Continue;
      ProgramPage(PageIndex+4,Data,Dispatched);
      if not BytesEqual(ReadRange(AModel,PageIndex+4,1),Data) then Fail('NDEF page verification failed');
      Move(Data[0],Current[PageIndex*4],4);
    end;
  end;
begin
  Result:=Default(TType2NdefSnapshot); Dispatched:=False;
  TType2PasswordCodec.ValidateCredentials(AModel,APassword,AExpectedPack);
  P:=CopyBytes(APassword); K:=CopyBytes(AExpectedPack); Ndef:=CopyBytes(ANdef);
  try
    if Length(Ndef)>0 then TNdefCodec.Decode(Ndef);
    try
      AcquireAndAuthenticate(P,K); Succeeded:=False;
      try
        Config:=Configuration(AModel); if Config.MirrorConfigured then Fail('mirrored memory');
        Cc:=RawPages(AModel,3,1); Current:=Memory(AModel); Snapshot:=TType2NdefMapping.Decode(AModel,Cc,Current); Plan:=TType2NdefMapping.Prepare(AModel,Cc,Current,Ndef);
        Locks:=RawPages(AModel,2,1); if ((Locks[2] and $F0)<>0) or (Locks[3]<>0) then Fail('static user locks');
        if not (AModel in [ttmUltralightEv1_48,ttmNtag210]) then begin
          Locks:=RawPages(AModel,LastUserPage(AModel)+1,1);
          if (Locks[0]<>0) or (Locks[1]<>0) or (Locks[2]<>0) then Fail('dynamic user locks');
        end;
        if not BytesEqual(Snapshot.MessageBytes,Ndef) then begin
          Apply(Plan.Invalidated,False); Apply(Plan.ShortEmpty,False); Apply(Plan.Prepared,True); Apply(Plan.Committed,False);
          Verify:=Memory(AModel);
          if not BytesEqual(Verify,Plan.Committed) then Fail('NDEF full verification failed');
        end else Verify:=CopyBytes(Current);
        if not BytesEqual(RawPages(AModel,3,1),Cc) then Fail('NDEF CC verification failed');
        Snapshot:=TType2NdefMapping.Decode(AModel,Cc,Verify); Succeeded:=True;
      finally ReleaseSession(Succeeded); end;
      Result:=Snapshot;
    except on E: Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally FillChar(P[0],Length(P),0); FillChar(K[0],Length(K),0); end;
end;

end.
