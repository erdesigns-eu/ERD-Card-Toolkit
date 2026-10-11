unit ERD.Card.Contactless.Plus.ACR122;

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
  ERD.Card.Transport, ERD.Card.Contactless.Plus, ERD.Card.Contactless.Raw;

/// <summary>Creates an inactive explicit ACR122U/PN532 ISO14443-4 Plus native backend.</summary>
/// <param name="ATransport">Connected PICC transport with exclusive ICardTransaction support and FF 00 direct transmit.</param>
/// <param name="ATimeoutCode">Bounded PN532 timeout 01 through 10 hex; default 0D.</param>
/// <returns>Retained backend; fresh selection/ATS validation, bounded exchanges and RF-off release.</returns>
/// <remarks>Requires a dedicated reader and one card in the field. No reader auto-detection, Escape fallback,
/// CRC guessing, raw Crypto1 or APDU emulation. RF timeout/retry settings persist until reader reset.</remarks>
function CreateAcr122PlusSession(const ATransport: ICardTransport;
  const ATimeoutCode: Byte = $0D): IMifarePlusSession;

/// <summary>Creates an inactive ACR122U raw reader for explicit Plus SL1 native authentication/level commands.</summary>
/// <param name="ATransport">Connected transport with exclusive transaction and FF 00 direct-transmit support.</param>
/// <param name="ATimeoutCode">Bounded PN532 timeout 01..10 hex, default 0D.</param>
/// <returns>Owned raw reader configured to suppress RATS and restore CRC/framing on release.</returns>
/// <remarks>Use with TMifarePlusLevelManager.RawReader; SL3 proof uses CreateAcr122PlusSession separately.</remarks>
function CreateAcr122PlusLevelReader(const ATransport: ICardTransport;
  const ATimeoutCode: Byte = $0D): IRawContactlessReader;

implementation

uses ERD.Card.APDU, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Contactless.ACR122;

type
  TAcrSession = class(TInterfacedObject,IMifarePlusSession)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FActive: Boolean;
    FTimeout: Byte;
    function Send(const B: TBytes; const AResponse: Byte): TBytes;
  public
    constructor Create(const T: ICardTransport; const ATimeout: Byte);
    destructor Destroy; override;
    function BeginSession: TBytes;
    function ExchangeNative(const ACommand: TBytes): TBytes;
    procedure EndSession;
  end;
procedure Invalid;
begin raise EMifarePlusError.Create('ACR122 Plus session framing or lifecycle failure.'); end;
constructor TAcrSession.Create(const T: ICardTransport; const ATimeout: Byte);
var Transaction: ICardTransaction;
begin
  inherited Create;
  if (T=nil) or not Supports(T,ICardTransaction,Transaction) or (ATimeout<1) or (ATimeout>$10) then Invalid;
  FTransport:=T; FTimeout:=ATimeout;
end;
destructor TAcrSession.Destroy;
begin if FActive then try EndSession; except end; inherited Destroy; end;
function TAcrSession.Send(const B: TBytes; const AResponse: Byte): TBytes;
var H,Wire: TBytes; Reply: TApduResponse;
begin
  if (Length(B)<2) or (Length(B)>250) then Invalid;
  H:=nil; Wire:=nil; Reply:=Default(TApduResponse);
  try
    SetLength(H,Length(B)+5); H[0]:=$FF; H[4]:=Byte(Length(B)); Move(B[0],H[5],Length(B));
    Wire:=FTransport.Exchange(H); Reply:=TApduCodec.DecodeResponse(Wire);
    if (Reply.StatusWord<>$9000) or (Length(Reply.Data)<2) or
      (Reply.Data[0]<>$D5) or (Reply.Data[1]<>AResponse) then Invalid;
    Result:=Copy(Reply.Data,2,Length(Reply.Data)-2);
  finally TCardCrypto.Clear(H); TCardCrypto.Clear(Wire); TCardCrypto.Clear(Reply.Data); end;
end;
function TAcrSession.BeginSession: TBytes;
var B,H: TBytes; N,P: Integer;
  procedure Empty(const Command: TBytes; const Code: Byte);
  begin B:=Send(Command,Code); if Length(B)<>0 then Invalid; end;
begin
  if FActive or not Supports(FTransport,ICardTransaction,FTransaction) then Invalid;
  try FTransaction.BeginTransaction; except FTransaction:=nil; raise; end;
  FActive:=True;
  try
    H:=HexToBytes('D43202000B00'); H[5]:=FTimeout; Empty(H,$33);
    Empty(HexToBytes('D4320400'),$33); Empty(HexToBytes('D43205000000'),$33);
    Empty(HexToBytes('D41234'),$13); // Automatic RATS/ISO14443-4 handling, no manual CRC registers.
    Empty(HexToBytes('D4320100'),$33); TThread.Sleep(10);
    Empty(HexToBytes('D4320101'),$33);
    B:=Send(HexToBytes('D44A0100'),$4B);
    if (Length(B)<6) or (B[0]<>1) or (B[1]<>1) or ((B[4] and $20)=0) then Invalid;
    N:=B[5]; if not (N in [4,7,10]) then Invalid; P:=6+N;
    if (Length(B)<=P) or (B[P]<2) or (B[P]>20) or (Length(B)<>P+B[P]) then Invalid;
    Result:=Copy(B,6,N);
  except try EndSession; except end; raise; end;
end;
function TAcrSession.ExchangeNative(const ACommand: TBytes): TBytes;
var H,B: TBytes;
begin
  if not FActive or (Length(ACommand)<1) or (Length(ACommand)>247) then Invalid;
  H:=nil;
  try
    SetLength(H,Length(ACommand)+3); H[0]:=$D4; H[1]:=$40; H[2]:=1;
    Move(ACommand[0],H[3],Length(ACommand)); B:=Send(H,$41);
    if (Length(B)<2) or (B[0]<>0) then Invalid; // MI/NAD flags are refused, never continued automatically.
    Result:=Copy(B,1,Length(B)-1); if Length(Result)>249 then Invalid;
  finally TCardCrypto.Clear(H); end;
end;
procedure TAcrSession.EndSession;
var T: ICardTransaction; Ok: Boolean; B: TBytes;
begin
  if not FActive then Invalid; T:=FTransaction; Ok:=False;
  try
    B:=Send(HexToBytes('D4320100'),$33); if Length(B)<>0 then Invalid; Ok:=True;
  finally
    FActive:=False; FTransaction:=nil;
    if Ok then T.EndTransaction else try T.EndTransaction; except end;
  end;
end;
function CreateAcr122PlusSession(const ATransport: ICardTransport; const ATimeoutCode: Byte): IMifarePlusSession;
begin Result:=TAcrSession.Create(ATransport,ATimeoutCode); end;

function CreateAcr122PlusLevelReader(const ATransport: ICardTransport;
  const ATimeoutCode: Byte): IRawContactlessReader;
begin
  Result := TAcr122RawReader.Create(ATransport, ATimeoutCode, True);
end;

end.
