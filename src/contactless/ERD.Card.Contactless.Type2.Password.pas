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
  ERD.Card.Transport, ERD.Card.Contactless, ERD.Card.Contactless.Raw, ERD.Card.Contactless.Type2;

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
  /// <summary>Nonvisual supplied-password user-memory access for Ultralight EV1 and NTAG210/212/213/215/216.</summary>
  /// <remarks>Construction performs no I/O. Each operation acquires one exclusive raw Type A session,
  /// freshly selects, dispatches PWD_AUTH once, validates PACK, and retains authentication until release.
  /// Configure/call on one thread without reentrancy. No password guessing, retries or configuration updates.
  /// Password verification is plaintext access control, not secure messaging or proof of card authenticity.</remarks>
  TType2PasswordCardReader = class(TComponent)
  private
    FReader: IRawContactlessReader;
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
    /// <summary>Retained matching raw-reader backend; nil disables operations. Do not change during an active call.</summary>
    property Reader: IRawContactlessReader read FReader write FReader;
  end;

implementation

uses ERD.Card.Bytes;

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
  if ASucceeded then FReader.EndSession
  else
    try FReader.EndSession;
    except
      // The backend must still release exclusivity; retain the primary operation failure.
    end;
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
  if FReader = nil then Fail('raw reader missing');
  FReader.BeginSession;
  try
    Uid := FReader.Activate;
    if Length(Uid) <> 7 then Fail('selected UID must have seven bytes');
    if Uid[3] = $88 then Fail('selected UID has an invalid cascade position');
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

end.
