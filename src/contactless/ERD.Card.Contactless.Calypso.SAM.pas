unit ERD.Card.Contactless.Calypso.SAM;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, {$ELSE}System.SysUtils, {$ENDIF}
  ERD.Card.Transport, ERD.Card.Contactless.Calypso;

type
  /// <summary>Explicit Calypso symmetric secure-session wire generation.</summary>
  TCalypsoSessionRevision = (
    /// <summary>Revision 1 legacy CLA 94, four-byte challenge and MAC.</summary>
    csrRevision1,
    /// <summary>Revision 2 legacy CLA 94, four-byte challenge and MAC.</summary>
    csrRevision2,
    /// <summary>Revision 3 ISO CLA 00 in compatibility mode, four-byte challenge and MAC.</summary>
    csrRevision3,
    /// <summary>Revision 3.2 ISO CLA 00 in extended, authenticated plaintext mode with eight-byte challenge and MAC.</summary>
    csrRevision32);

  /// <summary>Native read-only Calypso engine using a provisioned legacy Calypso SAM through a separate transport.</summary>
  /// <remarks>Owns no issuer secrets. SAM must already be selected/unlocked when required by its provisioning.
  /// Retain separate card and SAM connections on one thread; never share the SAM while a session is active.
  /// Encrypted sessions, PKI and card updates are deliberately not negotiated.</remarks>
  TCalypsoSamSessionProvider = class(TInterfacedObject,
    ICalypsoSecureSessionProvider)
  private
    FSam: ICardTransport;
    FRevision: TCalypsoSessionRevision;
    FSerial: TBytes;
    FSamClass, FKeyIndex, FKif, FKvc: Byte;
  public
    /// <summary>Configures an inactive native SAM session provider; performs no I/O.</summary>
    /// <param name="ASam">Distinct SAM transport with exclusive transaction capability.</param>
    /// <param name="ARevision">Explicit card generation; no automatic downgrade.</param>
    /// <param name="ACardSerial">Exact eight-byte card serial/diversifier obtained by the application.</param>
    /// <param name="AKeyIndex">Card session key index, 1..3.</param>
    /// <param name="AKif">Authorized nonzero SAM key identifier; must match a revision-3 card.</param>
    /// <param name="AKvc">Authorized nonzero key version; must match the card when returned.</param>
    /// <param name="ASamClass">SAM APDU class, 80h or 94h, as documented for the SAM.</param>
    constructor Create(const ASam: ICardTransport;
      const ARevision: TCalypsoSessionRevision; const ACardSerial: TBytes;
      const AKeyIndex, AKif, AKvc: Byte; const ASamClass: Byte = $80);
    /// <summary>Opens a plaintext read session with fresh SAM challenge; mutual authentication completes at Finish.</summary>
    /// <param name="ATransport">Exclusively held card transport, distinct from the SAM.</param>
    /// <param name="ADialect">Reader dialect matching the configured card generation.</param>
    /// <param name="ASelectionData">Previously acquired directory bytes; not used as a guessed serial.</param>
    /// <returns>Session retaining both transports until successful Finish or Abort.</returns>
    /// <remarks>Only successful SELECT FILE and READ RECORD commands are accepted inside this profile.
    /// Missing records, restricted files and chaining abort acquisition; use an exact known file/record plan.
    /// Bytes become authenticated only after Finish; the reader already enforces this boundary.</remarks>
    function Open(const ATransport: ICardTransport;
      const ADialect: TCalypsoDialect; const ASelectionData: TBytes)
      : ICalypsoSecureReadSession;
  end;

implementation

uses ERD.Card.Bytes;

type
  TSamSession = class(TInterfacedObject, ICalypsoSecureReadSession,
    ICardTransport)
  private
    FCard, FSam: ICardTransport;
    FTransaction: ICardTransaction;
    FCla, FSamCla: Byte;
    FMacBytes: Integer;
    FCardOpen, FSamHeld, FDone, FBusy: Boolean;
    function SAM(const AIns, AP1, AP2: Byte; const AData: TBytes;
      const ALe: Integer = -1): TBytes;
    procedure Update(const AData: TBytes);
    procedure ReleaseSam;
  public
    constructor Create(const ACard, ASam: ICardTransport;
      const ARevision: TCalypsoSessionRevision; const ASerial: TBytes;
      const AIndex, AKif, AKvc, ASamCla: Byte);
    destructor Destroy; override;
    function GetTransport: ICardTransport;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure Finish;
    procedure Abort;
  end;

procedure AuthenticationError;
begin
  raise ECalypsoError.Create
    ('Calypso SAM authentication or session state failed.');
end;

function Command(const ACla, AIns, AP1, AP2: Byte; const AData: TBytes;
  const ALe: Integer): TBytes;
var
  N: Integer;
begin
  Result := nil;
  if (Length(AData) > 255) or (ALe < -1) or (ALe > 255) then
    AuthenticationError;
  N := 4;
  if Length(AData) > 0 then
    Inc(N, Length(AData) + 1);
  if ALe >= 0 then
    Inc(N);
  SetLength(Result, N);
  Result[0] := ACla;
  Result[1] := AIns;
  Result[2] := AP1;
  Result[3] := AP2;
  if Length(AData) > 0 then
  begin
    Result[4] := Byte(Length(AData));
    Move(AData[0], Result[5], Length(AData));
  end;
  if ALe >= 0 then
    Result[N - 1] := Byte(ALe);
end;

function Successful(const AResponse: TBytes): TBytes;
var
  N: Integer;
begin
  N := Length(AResponse);
  if (N < 2) or (N > 257) then
    AuthenticationError;
  if (AResponse[N - 2] <> $90) or (AResponse[N - 1] <> 0) then
    AuthenticationError;
  Result := Copy(AResponse, 0, N - 2);
end;

constructor TCalypsoSamSessionProvider.Create(const ASam: ICardTransport;
  const ARevision: TCalypsoSessionRevision; const ACardSerial: TBytes;
  const AKeyIndex, AKif, AKvc: Byte; const ASamClass: Byte);
var
  T: ICardTransaction;
begin
  inherited Create;
  if (ASam = nil) or not Supports(ASam, ICardTransaction, T) or
    (Length(ACardSerial) <> 8) or (AKeyIndex < 1) or (AKeyIndex > 3) or
    (AKif = 0) or (AKvc = 0) or not(ASamClass in [$80, $94]) or
    (Ord(ARevision) > Ord(High(TCalypsoSessionRevision))) then
    AuthenticationError;
  FSam := ASam;
  FSerial := Copy(ACardSerial, 0, 8);
  FRevision := ARevision;
  FSamClass := ASamClass;
  FKeyIndex := AKeyIndex;
  FKif := AKif;
  FKvc := AKvc;
end;

function TCalypsoSamSessionProvider.Open(const ATransport: ICardTransport;
  const ADialect: TCalypsoDialect; const ASelectionData: TBytes)
  : ICalypsoSecureReadSession;
begin
  Result := nil;
  if (ATransport = nil) or (ATransport = FSam) or
    (Length(ASelectionData) > 4096) or
    ((FRevision in [csrRevision1, csrRevision2]) and (ADialect <> cdLegacy94))
    or ((FRevision in [csrRevision3, csrRevision32]) and (ADialect <> cdIso00))
  then
    AuthenticationError;
  Result := TSamSession.Create(ATransport, FSam, FRevision, FSerial, FKeyIndex,
    FKif, FKvc, FSamClass);
end;

function TSamSession.SAM(const AIns, AP1, AP2: Byte; const AData: TBytes;
  const ALe: Integer): TBytes;
begin
  Result := Successful(FSam.Exchange(Command(FSamCla, AIns, AP1, AP2,
    AData, ALe)));
end;

constructor TSamSession.Create(const ACard, ASam: ICardTransport;
  const ARevision: TCalypsoSessionRevision; const ASerial: TBytes;
  const AIndex, AKif, AKvc, ASamCla: Byte);
var
  Challenge, Data, Response, B: TBytes;
  P1, P2: Byte;
  K: Integer;
begin
  inherited Create;
  FCard := ACard;
  FSam := ASam;
  FSamCla := ASamCla;
  if ARevision in [csrRevision1, csrRevision2] then
    FCla := $94
  else
    FCla := 0;
  FMacBytes := 4;
  if ARevision = csrRevision32 then
    FMacBytes := 8;
  if not Supports(FSam, ICardTransaction, FTransaction) then
    AuthenticationError;
  FTransaction.BeginTransaction;
  FSamHeld := True;
  try
    B := SAM($14, 0, 0, ASerial);
    if Length(B) <> 0 then
      AuthenticationError;
    Challenge := SAM($84, 0, 0, nil, FMacBytes);
    if Length(Challenge) <> FMacBytes then
      AuthenticationError;
    P1 := AIndex;
    P2 := 0;
    if ARevision = csrRevision2 then
      P1 := P1 or $80;
    if ARevision = csrRevision3 then
      P2 := 1;
    Data := Challenge;
    if ARevision = csrRevision32 then
    begin
      P2 := 2;
      SetLength(Data, 9);
      Data[0] := 0;
      Move(Challenge[0], Data[1], 8);
    end;
    { Opening can fail after the card has accepted it. Abort even on transport failure. }
    FCardOpen := True;
    Response := Successful(FCard.Exchange(Command(FCla, $8A, P1, P2, Data, 0)));
    case ARevision of
      csrRevision1:
        if not(Length(Response) in [4, 6]) then
          AuthenticationError;
      csrRevision2:
        begin
          if not(Length(Response) in [5, 7]) then
            AuthenticationError;
          if Response[0] <> AKvc then
            AuthenticationError;
        end;
      csrRevision3, csrRevision32:
        begin
          K := 0;
          if ARevision = csrRevision32 then
            K := 4;
          if Length(Response) <> 8 + K then
            AuthenticationError;
          if (Response[5 + K] <> AKif) or (Response[6 + K] <> AKvc) or
            (Response[7 + K] <> 0) then
            AuthenticationError;
          if (ARevision = csrRevision32) and ((Response[8] and 2) = 0) then
            AuthenticationError;
        end;
    end;
    SetLength(Data, Length(Response) + 2);
    Data[0] := AKif;
    Data[1] := AKvc;
    Move(Response[0], Data[2], Length(Response));
    P1 := 0;
    if ARevision = csrRevision32 then
      P1 := 2;
    B := SAM($8A, P1, $FF, Data);
    if Length(B) <> 0 then
      AuthenticationError;
  except
    Abort;
    raise;
  end;
end;

destructor TSamSession.Destroy;
begin
  Abort;
  inherited Destroy;
end;

function TSamSession.GetTransport: ICardTransport;
begin
  if FDone then
    AuthenticationError;
  Result := Self;
end;

procedure TSamSession.Update(const AData: TBytes);
var
  B: TBytes;
begin
  if (Length(AData) < 1) or (Length(AData) > 255) then
    AuthenticationError;
  B := SAM($8C, 0, 0, AData);
  if Length(B) <> 0 then
    AuthenticationError;
end;

function TSamSession.Exchange(const ACommand: TBytes): TBytes;
var
  B, Digest: TBytes;
  N, Le: Integer;
begin
  Result := nil;
  if FDone or FBusy then
    AuthenticationError;
  { Strict read-only allowlist. Validate complete short APDU framing before any I/O. }
  N := Length(ACommand);
  if (N < 5) or (ACommand[0] <> FCla) then
    AuthenticationError;
  case ACommand[1] of
    $A4:
      begin
        if (N <> 8) or (ACommand[4] <> 2) or (ACommand[3] <> 0) or
          ((FCla = $94) and (ACommand[2] <> 0)) or
          ((FCla = 0) and (ACommand[2] <> 9)) then
          AuthenticationError;
        Digest := Copy(ACommand, 0, 7); { Case 4 excludes Le. }
      end;
    $B2:
      begin
        if (N <> 5) or (ACommand[2] = 0) or (ACommand[3] <> 4) then
          AuthenticationError;
        Le := ACommand[4];
        if (Le = 0) or (Le > 253) then
          AuthenticationError;
        Digest := Copy(ACommand, 0, N);
      end;
  else
    AuthenticationError;
  end;
  FBusy := True;
  try
    Result := FCard.Exchange(ACommand);
    B := Successful(Result);
    { Failed/chained responses cannot be safely inferred into this authenticated profile. }
    if Length(B) + 2 > 255 then
      AuthenticationError;
    Update(Digest);
    Update(Result);
  except
    Result := nil;
    Abort;
    raise;
  end;
  FBusy := False;
end;

procedure TSamSession.ReleaseSam;
begin
  if FSamHeld then
  begin
    FSamHeld := False;
    FTransaction.EndTransaction;
  end;
  FTransaction := nil;
end;

procedure TSamSession.Finish;
var
  Mac, B: TBytes;
begin
  if FDone or FBusy then
    AuthenticationError;
  FBusy := True;
  try
    Mac := SAM($8E, 0, 0, nil, FMacBytes);
    if Length(Mac) <> FMacBytes then
      AuthenticationError;
    B := Successful(FCard.Exchange(Command(FCla, $8E, $80, 0, Mac, 0)));
    FCardOpen := False;
    if Length(B) <> FMacBytes then
      AuthenticationError;
    B := SAM($82, 0, 0, B);
    if Length(B) <> 0 then
      AuthenticationError;
    FDone := True;
    ReleaseSam;
  except
    Abort;
    raise;
  end;
  FBusy := False;
end;

procedure TSamSession.Abort;
begin
  if FCardOpen then
  begin
    FCardOpen := False;
    try
      FCard.Exchange(Command(FCla, $8E, 0, 0, nil, 0));
    except
    end;
  end;
  FDone := True;
  FBusy := False;
  try
    ReleaseSam;
  except
  end;
end;

end.
