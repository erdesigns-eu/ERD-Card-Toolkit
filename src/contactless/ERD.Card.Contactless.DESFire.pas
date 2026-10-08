unit ERD.Card.Contactless.DESFire;

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
  ERD.Card.Transport, ERD.Card.Crypto, ERD.Card.Contactless,
  ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.DESFire.EV1;

const
  /// <summary>Hard bound for an individual acquired/plain DESFire transfer; wire fields remain 24-bit.</summary>
  DesfireMaxTransferBytes = 1048500;
  /// <summary>Hard bound for additional-frame exchanges in one logical command.</summary>
  DesfireMaxFrames = 65536;

type
  /// <summary>Invalid or unsupported native DESFire configuration, response or access policy.</summary>
  EDesfireError = class(EContactlessError);
  /// <summary>Native DESFire status error retaining only its single status byte.</summary>
  EDesfireStatusError = class(EDesfireError)
  private
    FStatus: Byte;
  public
    /// <summary>Creates a native status failure without command or card contents.</summary>
    /// <param name="AStatus">Raw SW2 following SW1=91.</param>
    constructor Create(const AStatus: Byte); reintroduce;
    /// <summary>Native DESFire status; no automatic recovery or replay.</summary>
    property Status: Byte read FStatus;
  end;
  /// <summary>Explicit native access/security profile; no default keys or authentication fallback.</summary>
  TDesfireSecurity = (
    /// <summary>Unauthenticated legacy native commands, public plaintext access only.</summary>
    dfsPublic,
    /// <summary>AuthenticateEV2First with caller-supplied AES key and EV2 Plain/MACed/Full messaging.</summary>
    dfsEv2Aes,
    /// <summary>EV1 AuthenticateAES with chained-IV AES-CMAC and encrypted CRC32 messaging.</summary>
    dfsEv1Aes
  );
  /// <summary>Supported ordinary native DESFire file types; administration and transaction writes are separate.</summary>
  TDesfireFileType = (
    /// <summary>Standard data file; verified range writing is supported.</summary>
    dftStandard,
    /// <summary>Backup data file; reading only in this component.</summary>
    dftBackup,
    /// <summary>Signed value file with backup; reading only.</summary>
    dftValue,
    /// <summary>Linear record file with backup; reading only.</summary>
    dftLinearRecords,
    /// <summary>Cyclic record file with backup; reading only.</summary>
    dftCyclicRecords
  );
  /// <summary>Strict ordinary file settings in the selected native application.</summary>
  /// <remarks>RawBytes is owned; ordinary record assignment shares its array. Extended/SDM/TMAC settings are refused.</remarks>
  TDesfireFileSettings = record
    /// <summary>Explicit native file number, 0..31; not an ISO file identifier.</summary>
    FileNumber: Byte;
    /// <summary>Ordinary supported native file type.</summary>
    FileType: TDesfireFileType;
    /// <summary>Acquired Plain/MACed/Full communication requirement.</summary>
    Communication: TDesfireCommunication;
    /// <summary>Read access nibble; E means free and F denies this access route.</summary>
    ReadKey: Byte;
    /// <summary>Write access nibble; E means free and F denies this route.</summary>
    WriteKey: Byte;
    /// <summary>Alternative read/write access nibble.</summary>
    ReadWriteKey: Byte;
    /// <summary>Access-right modification nibble; this component never changes rights.</summary>
    ChangeKey: Byte;
    /// <summary>Data-file size, otherwise zero; little-endian 24-bit field.</summary>
    FileBytes: Integer;
    /// <summary>Signed lower value-file limit, otherwise zero.</summary>
    LowerLimit: Integer;
    /// <summary>Signed upper value-file limit, otherwise zero.</summary>
    UpperLimit: Integer;
    /// <summary>Acquired limited-credit value, otherwise zero; no credit operation is implemented.</summary>
    LimitedCreditValue: Integer;
    /// <summary>Raw value options 0..3: limited credit and free GetValue indicators.</summary>
    ValueOptions: Byte;
    /// <summary>Record byte size, otherwise zero; little-endian 24-bit field.</summary>
    RecordBytes: Integer;
    /// <summary>Record-file maximum capacity, otherwise zero.</summary>
    MaxRecords: Integer;
    /// <summary>Acquired record count, otherwise zero; does not establish an atomic snapshot.</summary>
    CurrentRecords: Integer;
    /// <summary>Independent complete settings response for coherence comparison.</summary>
    RawBytes: TBytes;
  end;
  /// <summary>Owned ordered array of acquired file settings.</summary>
  TDesfireFiles = array of TDesfireFileSettings;
  /// <summary>Ordered nonzero 24-bit native application identifiers as host integers.</summary>
  TDesfireApplicationIds = array of Cardinal;
  /// <summary>Strict independent 28-byte hardware/software/manufacturing version response.</summary>
  TDesfireVersion = record
    /// <summary>Complete owned version data; includes potentially identifying manufacturing information.</summary>
    RawBytes: TBytes;
    /// <summary>Hardware vendor identifier reported by the card; not authenticity proof.</summary>
    Vendor: Byte;
    /// <summary>Hardware product-type byte; not automatic profile selection.</summary>
    ProductType: Byte;
    /// <summary>Hardware major version byte.</summary>
    HardwareMajor: Byte;
    /// <summary>Software major version byte.</summary>
    SoftwareMajor: Byte;
    /// <summary>Software storage-size code, retained without guessed capacity.</summary>
    StorageCode: Byte;
  end;
  /// <summary>Pure strict codecs for wrapped ordinary DESFire native commands and settings.</summary>
  TDesfireCodec = class
  public
    /// <summary>Builds short native wrapping 90/INS/00/00 with trailing Le=00.</summary>
    /// <param name="AInstruction">Native command or AF continuation.</param>
    /// <param name="AData">Zero through 255 independent command data bytes.</param>
    /// <returns>Independent five-byte empty command, or six-byte framing plus data.</returns>
    /// <exception cref="EDesfireError">Data exceeds the short-command bound.</exception>
    class function Command(const AInstruction: Byte; const AData: TBytes): TBytes; static;
    /// <summary>Encodes an explicitly selected 24-bit native AID in little-endian transmission order.</summary>
    /// <param name="AAid">Zero for PICC level, or a nonzero value through FFFFFF.</param>
    /// <returns>Independent three bytes.</returns>
    /// <exception cref="EDesfireError">Value is out of range.</exception>
    class function ApplicationBytes(const AAid: Cardinal): TBytes; static;
    /// <summary>Decodes complete acquired application identifiers, rejecting root/duplicate entries.</summary>
    /// <param name="AData">Zero through 3072 bytes, divisible by three.</param>
    /// <returns>Independent ordered identifiers, at most 1024.</returns>
    /// <exception cref="EDesfireError">Length, duplicate or root identifier is invalid.</exception>
    class function ApplicationIds(const AData: TBytes): TDesfireApplicationIds; static;
    /// <summary>Decodes ordinary complete settings without inferring unsupported extensions.</summary>
    /// <param name="AFileNumber">Native number 0..31.</param>
    /// <param name="AData">Exact 7-byte data, 17-byte value or 13-byte record settings.</param>
    /// <returns>Independent validated file geometry/access settings.</returns>
    /// <exception cref="EDesfireError">Type, communication, size or geometry is unsupported.</exception>
    class function FileSettings(const AFileNumber: Byte; const AData: TBytes): TDesfireFileSettings; static;
    /// <summary>Decodes a complete 28-byte native version response without identity authentication.</summary>
    /// <param name="AData">Exactly 28 acquired data bytes.</param>
    /// <returns>Independent version metadata and complete source bytes.</returns>
    /// <exception cref="EDesfireError">Length is invalid.</exception>
    class function Version(const AData: TBytes): TDesfireVersion; static;
    /// <summary>Builds a native file/range header using 24-bit little-endian offsets and counts.</summary>
    /// <param name="AFileNumber">Native number 0..31.</param>
    /// <param name="AOffset">Nonnegative byte or newest-relative record offset, through FFFFFF.</param>
    /// <param name="ACount">Positive byte/record count, through FFFFFF; zero/all is deliberately refused.</param>
    /// <returns>Independent seven-byte header.</returns>
    /// <exception cref="EDesfireError">Arguments are invalid.</exception>
    class function RangeHeader(const AFileNumber: Byte; const AOffset, ACount: Integer): TBytes; static;
    /// <summary>Decodes one signed little-endian 32-bit value without unsigned overflow casts.</summary>
    /// <param name="AData">Exactly four bytes.</param>
    /// <returns>Signed acquired value.</returns>
    /// <exception cref="EDesfireError">Length is invalid.</exception>
    class function SignedValue(const AData: TBytes): Integer; static;
  end;
  /// <summary>Nonvisual native DESFire discovery, data/value/record reading and verified standard-data writing.</summary>
  /// <remarks>One caller thread, no reentrancy. Every operation selects its explicit native application in an
  /// exclusive transaction, optionally authenticates afresh and clears session secrets at release. No retries,
  /// default keys, implicit reset, formatting, key changes, backup commits/aborts, credits or record writes.</remarks>
  TDesfireCardReader = class(TComponent)
  private
    FTransport,FActiveTransport: ICardTransport;
    FProvider: ICardAesProvider;
    FTransaction: ICardTransaction;
    FKey,FRekey,FSessionIv: TBytes;
    FRekeyNumber,FSessionKeyNumber: Byte;
    FReauthenticated: Boolean;
    FKeyNumber: Byte;
    FSecurity: TDesfireSecurity;
    FMinimum: TDesfireCommunication;
    FMaxTransfer,FMaxFrameData: Integer;
    FBusy,FAuthenticated,FWriteAttempt: Boolean;
    FKeys: TDesfireEv2Keys;
    FTi: TBytes;
    FCounter: Integer;
    procedure SetTransport(const AValue: ICardTransport);
    procedure SetProvider(const AValue: ICardAesProvider);
    procedure SetKey(const AValue: TBytes);
    function GetKey: TBytes;
    procedure SetKeyNumber(const AValue: Byte);
    procedure SetSecurity(const AValue: TDesfireSecurity);
    procedure SetMinimum(const AValue: TDesfireCommunication);
    procedure SetMaxTransfer(const AValue: Integer);
    procedure SetMaxFrameData(const AValue: Integer);
    procedure Start(const AAid: Cardinal; const AAuthenticate: Boolean);
    procedure Finish(const ASucceeded: Boolean);
    procedure ValidateCredentials;
    procedure Authenticate(const AReauthenticate: Boolean = False);
    procedure SetRekey(const AValue: TBytes);
    function GetRekey: TBytes;
    procedure SetRekeyNumber(const AValue: Byte);
    function Frame(const AInstruction: Byte; const AData: TBytes; out AStatus: Byte;
      const AWrite: Boolean): TBytes;
    function Exchange(const AInstruction: Byte; const AData: TBytes; const AMaxResponse: Integer;
      const AWrite: Boolean): TBytes;
    function Send(const AInstruction: Byte; const AHeader,AData: TBytes;
      const AMode: TDesfireCommunication; const AExpected: Integer; const AWrite: Boolean): TBytes;
    function Settings(const AFile: Byte): TDesfireFileSettings;
    procedure CheckAccess(const ASettings: TDesfireFileSettings; const AWrite: Boolean);
    function ReadSelected(const ASettings: TDesfireFileSettings; const AOffset,ACount: Integer): TBytes;
    procedure CheckSettings(const ASettings: TDesfireFileSettings);
  public
    /// <summary>Creates an inactive component with public access, a 64 KiB transfer bound and 48-byte command frames.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Clears both locally retained authentication credentials and session bytes; callers must not destroy a busy component.</summary>
    destructor Destroy; override;
    /// <summary>Selects PICC level and reads version without authentication or automatic family selection.</summary>
    /// <returns>Complete independent version only after successful transaction release.</returns>
    /// <exception cref="EContactlessError">Transport, status, framing or release fails.</exception>
    function ReadVersion: TDesfireVersion;
    /// <summary>Selects PICC level and lists publicly visible native application IDs without authentication.</summary>
    /// <returns>Independent ordered application identifiers after release.</returns>
    /// <exception cref="Exception">Transport, configured authentication, status or decoding fails.</exception>
    function ReadApplicationIds: TDesfireApplicationIds;
    /// <summary>Selects an application, lists public directory entries and optionally authenticates to retrieve settings.</summary>
    /// <param name="AAid">Explicit nonzero native 24-bit application identifier.</param>
    /// <returns>Independent ordered settings; unknown extended file types fail rather than yield a partial list.</returns>
    /// <exception cref="Exception">Selection, authentication, directory/settings or release fails.</exception>
    function ReadFiles(const AAid: Cardinal): TDesfireFiles;
    /// <summary>Reads an explicit bounded range from a standard or backup data file.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <param name="AOffset">Zero-based byte offset.</param>
    /// <param name="ACount">Positive exact byte count, at most MaxTransferBytes and within acquired file size.</param>
    /// <returns>Independent plaintext only after required MAC/CRC verification, settings coherence and release.</returns>
    /// <exception cref="Exception">Access, secure messaging, bounds or transport fails.</exception>
    function ReadData(const AAid: Cardinal; const AFile: Byte; const AOffset,ACount: Integer): TBytes;
    /// <summary>Reads the signed current value from a value file; does not debit or credit.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native file number 0..31.</param>
    /// <returns>Acquired signed value within its settings bounds, after release.</returns>
    /// <exception cref="Exception">Type, access, authentication, secure messaging or transport fails.</exception>
    function ReadValue(const AAid: Cardinal; const AFile: Byte): Integer;
    /// <summary>Reads a bounded count of complete records in native newest-first response order.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native linear/cyclic record file number.</param>
    /// <param name="AOffset">Zero-based offset from the newest record.</param>
    /// <param name="ACount">Positive exact record count; total bytes must fit MaxTransferBytes.</param>
    /// <returns>Independent concatenated records after settings coherence and release.</returns>
    /// <exception cref="Exception">Type, access, range, secure messaging or transport fails.</exception>
    function ReadRecords(const AAid: Cardinal; const AFile: Byte; const AOffset,ACount: Integer): TBytes;
    /// <summary>Writes one explicit standard-data range and verifies it independently within the acquired session.</summary>
    /// <param name="AAid">Explicit nonzero native AID.</param>
    /// <param name="AFile">Native standard-data file number; backup files are deliberately separate transactions.</param>
    /// <param name="AOffset">Zero-based byte offset.</param>
    /// <param name="AData">Nonempty plaintext, copied before I/O; at most MaxTransferBytes.</param>
    /// <exception cref="Exception">Preflight, read/write rights or authentication fails before dispatch.</exception>
    /// <exception cref="EContactlessWriteUncertain">Any dispatched write, verification or release fails; never retry blindly.</exception>
    /// <remarks>Requires both read and write access. Matching acquired bytes are a verified no-op. Chained writes
    /// are not atomic; the component sends no rollback, commit or abort and preserves bytes outside the range.</remarks>
    procedure WriteData(const AAid: Cardinal; const AFile: Byte; const AOffset: Integer; const AData: TBytes);
    /// <summary>Retained connected native-wrapping transport with ICardTransaction; cannot change while busy.</summary>
    property Transport: ICardTransport read FTransport write SetTransport;
    /// <summary>Retained maintained AES backend; required for the explicit EV1/EV2 AES profiles.</summary>
    property CryptoProvider: ICardAesProvider read FProvider write SetProvider;
    /// <summary>Owned copy of exactly 16 authentication bytes, or empty to clear; getter returns a separate copy.</summary>
    property AuthenticationKey: TBytes read GetKey write SetKey;
    /// <summary>Explicit application authentication key number 0..13; not automatically guessed.</summary>
    property KeyNumber: Byte read FKeyNumber write SetKeyNumber;
    /// <summary>Optional owned EV2 NonFirst AES key; empty disables switching. Getter returns an independent copy.</summary>
    /// <remarks>Data/value/record reads and standard writes first retrieve settings under AuthenticationKey, then switch
    /// once before checking data access. TI and command counter remain unchanged. ReadFiles uses the initial key.</remarks>
    property ReauthenticationKey: TBytes read GetRekey write SetRekey;
    /// <summary>Explicit target application key number 0..13 for the optional EV2 NonFirst switch.</summary>
    property ReauthenticationKeyNumber: Byte read FRekeyNumber write SetRekeyNumber;
    /// <summary>Explicit public, EV1 AES or EV2 AES profile, default public; no downgrade/fallback.</summary>
    property Security: TDesfireSecurity read FSecurity write SetSecurity;
    /// <summary>Minimum acquired file mode for authenticated operations, default MACed; choose Plain explicitly if intended.</summary>
    property MinimumCommunication: TDesfireCommunication read FMinimum write SetMinimum;
    /// <summary>Per-operation plaintext transfer bound, 1..DesfireMaxTransferBytes, default 65536.</summary>
    property MaxTransferBytes: Integer read FMaxTransfer write SetMaxTransfer;
    /// <summary>Maximum native command data per short APDU, 16..255, default 48; select for actual card/reader.</summary>
    property MaxFrameDataBytes: Integer read FMaxFrameData write SetMaxFrameData;
    /// <summary>True throughout acquisition, authentication, commands and release; nested calls/configuration are refused.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

procedure InvalidDesfire;
begin raise EDesfireError.Create('Invalid or unsupported DESFire configuration, response or access.'); end;

constructor EDesfireStatusError.Create(const AStatus:Byte);
begin inherited CreateFmt('DESFire native status %2.2x.',[AStatus]); FStatus:=AStatus; end;

function Le24(const A:TBytes; const Offset:Integer):Integer;
begin Result:=Integer(A[Offset]) or (Integer(A[Offset+1]) shl 8) or (Integer(A[Offset+2]) shl 16); end;

class function TDesfireCodec.Command(const AInstruction:Byte; const AData:TBytes):TBytes;
begin
  Result:=nil; if Length(AData)>255 then InvalidDesfire;
  if Length(AData)=0 then SetLength(Result,5) else SetLength(Result,Length(AData)+6);
  Result[0]:=$90; Result[1]:=AInstruction;
  if Length(AData)>0 then begin Result[4]:=Length(AData); Move(AData[0],Result[5],Length(AData)); end;
end;

class function TDesfireCodec.ApplicationBytes(const AAid:Cardinal):TBytes;
begin
  Result:=nil; if AAid>$FFFFFF then InvalidDesfire;
  SetLength(Result,3); Result[0]:=AAid and $FF; Result[1]:=(AAid shr 8) and $FF; Result[2]:=AAid shr 16;
end;

class function TDesfireCodec.ApplicationIds(const AData:TBytes):TDesfireApplicationIds;
var I,J:Integer;
begin
  Result:=nil; if (Length(AData)>3072) or (Length(AData) mod 3<>0) then InvalidDesfire;
  SetLength(Result,Length(AData) div 3);
  for I:=0 to High(Result) do
  begin
    Result[I]:=Le24(AData,I*3); if Result[I]=0 then InvalidDesfire;
    for J:=0 to I-1 do if Result[J]=Result[I] then InvalidDesfire;
  end;
end;

class function TDesfireCodec.SignedValue(const AData:TBytes):Integer;
var Value:Int64;
begin
  if Length(AData)<>4 then InvalidDesfire;
  Value:=Int64(AData[0]) or (Int64(AData[1]) shl 8) or
    (Int64(AData[2]) shl 16) or (Int64(AData[3]) shl 24);
  if Value>High(Integer) then Dec(Value,Int64($100000000));
  Result:=Value;
end;

class function TDesfireCodec.FileSettings(const AFileNumber:Byte; const AData:TBytes):TDesfireFileSettings;
begin
  Result:=Default(TDesfireFileSettings);
  if (AFileNumber>31) or (Length(AData)<4) or (AData[0]>4) then InvalidDesfire;
  Result.FileNumber:=AFileNumber; Result.FileType:=TDesfireFileType(AData[0]);
  case AData[1] of
    0:Result.Communication:=dfcPlain;
    1:Result.Communication:=dfcMac;
    3:Result.Communication:=dfcFull;
  else InvalidDesfire; end;
  Result.ReadWriteKey:=AData[2] shr 4; Result.ChangeKey:=AData[2] and $F;
  Result.ReadKey:=AData[3] shr 4; Result.WriteKey:=AData[3] and $F;
  case Result.FileType of
    dftStandard,dftBackup:
      begin if Length(AData)<>7 then InvalidDesfire; Result.FileBytes:=Le24(AData,4);
        if Result.FileBytes=0 then InvalidDesfire; end;
    dftValue:
      begin
        if Length(AData)<>17 then InvalidDesfire;
        Result.LowerLimit:=SignedValue(Copy(AData,4,4)); Result.UpperLimit:=SignedValue(Copy(AData,8,4));
        Result.LimitedCreditValue:=SignedValue(Copy(AData,12,4)); Result.ValueOptions:=AData[16];
        if (Result.LowerLimit>Result.UpperLimit) or (Result.ValueOptions>3) then InvalidDesfire;
      end;
    dftLinearRecords,dftCyclicRecords:
      begin
        if Length(AData)<>13 then InvalidDesfire;
        Result.RecordBytes:=Le24(AData,4); Result.MaxRecords:=Le24(AData,7); Result.CurrentRecords:=Le24(AData,10);
        if (Result.RecordBytes=0) or (Result.MaxRecords=0) or (Result.CurrentRecords>Result.MaxRecords) then InvalidDesfire;
      end;
  end;
  Result.RawBytes:=CopyBytes(AData);
end;

class function TDesfireCodec.Version(const AData:TBytes):TDesfireVersion;
begin
  Result:=Default(TDesfireVersion); if Length(AData)<>28 then InvalidDesfire;
  Result.RawBytes:=CopyBytes(AData); Result.Vendor:=AData[0]; Result.ProductType:=AData[1];
  Result.HardwareMajor:=AData[3]; Result.SoftwareMajor:=AData[10]; Result.StorageCode:=AData[12];
end;

class function TDesfireCodec.RangeHeader(const AFileNumber:Byte; const AOffset,ACount:Integer):TBytes;
begin
  Result:=nil;
  if (AFileNumber>31) or (AOffset<0) or (AOffset>$FFFFFF) or (ACount<1) or (ACount>$FFFFFF) then InvalidDesfire;
  SetLength(Result,7); Result[0]:=AFileNumber;
  Result[1]:=AOffset and $FF; Result[2]:=(AOffset shr 8) and $FF; Result[3]:=AOffset shr 16;
  Result[4]:=ACount and $FF; Result[5]:=(ACount shr 8) and $FF; Result[6]:=ACount shr 16;
end;

constructor TDesfireCardReader.Create(AOwner:TComponent);
begin inherited Create(AOwner); FMinimum:=dfcMac; FMaxTransfer:=65536; FMaxFrameData:=48; end;

destructor TDesfireCardReader.Destroy;
begin
  TCardCrypto.Clear(FKey); TCardCrypto.Clear(FRekey);
  TDesfireEv2Codec.ClearKeys(FKeys); TCardCrypto.Clear(FTi); TCardCrypto.Clear(FSessionIv); inherited Destroy;
end;

procedure TDesfireCardReader.SetTransport(const AValue:ICardTransport);
begin if FBusy then InvalidDesfire; FTransport:=AValue; end;
procedure TDesfireCardReader.SetProvider(const AValue:ICardAesProvider);
begin if FBusy then InvalidDesfire; FProvider:=AValue; end;
procedure TDesfireCardReader.SetKey(const AValue:TBytes);
var B:TBytes;
begin
  if FBusy or not (Length(AValue) in [0,16]) then InvalidDesfire;
  B:=CopyBytes(AValue); TCardCrypto.Clear(FKey); FKey:=B;
end;
function TDesfireCardReader.GetKey:TBytes;
begin Result:=CopyBytes(FKey); end;
procedure TDesfireCardReader.SetRekey(const AValue:TBytes);
var B:TBytes;
begin
  if FBusy or not (Length(AValue) in [0,16]) then InvalidDesfire;
  B:=CopyBytes(AValue); TCardCrypto.Clear(FRekey); FRekey:=B;
end;
function TDesfireCardReader.GetRekey:TBytes;
begin Result:=CopyBytes(FRekey); end;
procedure TDesfireCardReader.SetRekeyNumber(const AValue:Byte);
begin if FBusy or (AValue>13) then InvalidDesfire; FRekeyNumber:=AValue; end;

procedure TDesfireCardReader.ValidateCredentials;
begin
  if (FSecurity<>dfsPublic) and ((FProvider=nil) or (Length(FKey)<>16)) then InvalidDesfire;
  if (Length(FRekey)>0) and (FSecurity<>dfsEv2Aes) then InvalidDesfire;
end;

procedure TDesfireCardReader.SetKeyNumber(const AValue:Byte);
begin if FBusy or (AValue>13) then InvalidDesfire; FKeyNumber:=AValue; end;
procedure TDesfireCardReader.SetSecurity(const AValue:TDesfireSecurity);
begin if FBusy or (Ord(AValue)<0) or (Ord(AValue)>Ord(High(TDesfireSecurity))) then InvalidDesfire; FSecurity:=AValue; end;
procedure TDesfireCardReader.SetMinimum(const AValue:TDesfireCommunication);
begin if FBusy or (Ord(AValue)<0) or (Ord(AValue)>Ord(High(TDesfireCommunication))) then InvalidDesfire; FMinimum:=AValue; end;
procedure TDesfireCardReader.SetMaxTransfer(const AValue:Integer);
begin if FBusy or (AValue<1) or (AValue>DesfireMaxTransferBytes) then InvalidDesfire; FMaxTransfer:=AValue; end;
procedure TDesfireCardReader.SetMaxFrameData(const AValue:Integer);
begin if FBusy or (AValue<16) or (AValue>255) then InvalidDesfire; FMaxFrameData:=AValue; end;

function TDesfireCardReader.Frame(const AInstruction:Byte; const AData:TBytes;
  out AStatus:Byte; const AWrite:Boolean):TBytes;
var R:TApduResponse; CommandBytes:TBytes;
begin
  Result:=nil; AStatus:=0; CommandBytes:=TDesfireCodec.Command(AInstruction,AData);
  try
    if AWrite then FWriteAttempt:=True;
    R:=TApduCodec.DecodeResponse(FActiveTransport.Exchange(CommandBytes));
    if ((R.StatusWord shr 8)<>$91) or (Length(R.Data)>256) then InvalidDesfire;
    AStatus:=R.StatusWord and $FF;
    if not (AStatus in [0,$AF]) then raise EDesfireStatusError.Create(AStatus);
    Result:=R.Data;
  finally TCardCrypto.Clear(CommandBytes); end;
end;

function TDesfireCardReader.Exchange(const AInstruction:Byte; const AData:TBytes;
  const AMaxResponse:Integer; const AWrite:Boolean):TBytes;
var Status,Instruction:Byte; Position,N,Received,Frames:Integer; Chunk,Part,Buffer:TBytes;
begin
  Result:=nil;
  if (AMaxResponse<0) or (AMaxResponse>DesfireMaxTransferBytes+32) or
    (Length(AData)>DesfireMaxTransferBytes+64) then InvalidDesfire;
  Buffer:=nil; Chunk:=nil; Part:=nil;
  try
    SetLength(Buffer,AMaxResponse); Position:=0; Received:=0; Frames:=0; Instruction:=AInstruction;
    repeat
      Inc(Frames); if Frames>DesfireMaxFrames then InvalidDesfire;
      N:=Length(AData)-Position; if N>FMaxFrameData then N:=FMaxFrameData;
      Chunk:=Copy(AData,Position,N); Inc(Position,N);
      Part:=Frame(Instruction,Chunk,Status,AWrite); TCardCrypto.Clear(Chunk);
      if Position<Length(AData) then
      begin
        if (Status<>$AF) or (Length(Part)<>0) then InvalidDesfire;
      end
      else
      begin
        if Length(Part)>AMaxResponse-Received then InvalidDesfire;
        if Length(Part)>0 then Move(Part[0],Buffer[Received],Length(Part)); Inc(Received,Length(Part));
        if (Status=$AF) and (Length(Part)=0) then InvalidDesfire;
      end;
      TCardCrypto.Clear(Part); Instruction:=$AF;
    until Status=0;
    if Position<>Length(AData) then InvalidDesfire;
    Result:=Copy(Buffer,0,Received);
  finally TCardCrypto.Clear(Buffer); TCardCrypto.Clear(Chunk); TCardCrypto.Clear(Part); end;
end;

procedure TDesfireCardReader.Authenticate(const AReauthenticate:Boolean);
var Key,Initial,Header,Cipher,RndA,RndB,Plain,Challenge,Rotated,Received:TBytes;
  Status,Instruction,Number:Byte; I,Expected,Offset:Integer;
begin
  if AReauthenticate and ((FSecurity<>dfsEv2Aes) or not FAuthenticated or
    (Length(FRekey)<>16) or FReauthenticated) then InvalidDesfire;
  Number:=FKeyNumber; Key:=CopyBytes(FKey);
  if AReauthenticate then begin TCardCrypto.Clear(Key); Key:=CopyBytes(FRekey); Number:=FRekeyNumber; end;
  Initial:=nil; Header:=nil; Cipher:=nil; RndA:=nil; RndB:=nil;
  Plain:=nil; Challenge:=nil; Rotated:=nil; Received:=nil;
  FAuthenticated:=False;
  try
    SetLength(Initial,16); SetLength(Header,1); Header[0]:=Number;
    Instruction:=$71; Expected:=32; Offset:=4;
    if FSecurity=dfsEv1Aes then begin Instruction:=$AA; Expected:=16; Offset:=0; end
    else if AReauthenticate then begin Instruction:=$77; Expected:=16; Offset:=0; end
    else SetLength(Header,2); // LenCap=0, explicit all-zero PCD capabilities.
    Cipher:=Frame(Instruction,Header,Status,False);
    if (Status<>$AF) or (Length(Cipher)<>16) then InvalidDesfire;
    RndB:=FProvider.DecryptCbc(Key,Initial,Cipher); if Length(RndB)<>16 then InvalidDesfire;
    if FSecurity=dfsEv1Aes then begin TCardCrypto.Clear(Initial); Initial:=CopyBytes(Cipher); end;
    RndA:=FProvider.RandomBytes(16); if Length(RndA)<>16 then InvalidDesfire;
    SetLength(Plain,32); Move(RndA[0],Plain[0],16);
    for I:=0 to 15 do Plain[16+I]:=RndB[(I+1) mod 16];
    Challenge:=FProvider.EncryptCbc(Key,Initial,Plain); if Length(Challenge)<>32 then InvalidDesfire;
    if FSecurity=dfsEv1Aes then begin TCardCrypto.Clear(Initial); Initial:=Copy(Challenge,16,16); end;
    TCardCrypto.Clear(Cipher); Cipher:=Frame($AF,Challenge,Status,False);
    if (Status<>0) or (Length(Cipher)<>Expected) then InvalidDesfire;
    TCardCrypto.Clear(Plain); Plain:=FProvider.DecryptCbc(Key,Initial,Cipher);
    if Length(Plain)<>Expected then InvalidDesfire;
    SetLength(Rotated,16); for I:=0 to 15 do Rotated[I]:=RndA[(I+1) mod 16];
    Received:=Copy(Plain,Offset,16);
    if not TCardCrypto.EqualSecret(Rotated,Received) then InvalidDesfire;
    TDesfireEv2Codec.ClearKeys(FKeys);
    if FSecurity=dfsEv1Aes then
    begin
      FKeys.Encryption:=TDesfireEv1Codec.DeriveKey(RndA,RndB);
      TCardCrypto.Clear(FSessionIv); SetLength(FSessionIv,16);
    end
    else
    begin
      if not AReauthenticate then
      begin
        for I:=26 to 31 do if Plain[I]<>0 then InvalidDesfire;
        FTi:=Copy(Plain,0,4); FCounter:=0;
      end;
      FKeys:=TDesfireEv2Codec.DeriveKeys(FProvider,Key,RndA,RndB);
    end;
    FSessionKeyNumber:=Number; FReauthenticated:=AReauthenticate; FAuthenticated:=True;
  finally
    TCardCrypto.Clear(Key); TCardCrypto.Clear(Initial); TCardCrypto.Clear(Header); TCardCrypto.Clear(Cipher);
    TCardCrypto.Clear(RndA); TCardCrypto.Clear(RndB); TCardCrypto.Clear(Plain);
    TCardCrypto.Clear(Challenge); TCardCrypto.Clear(Rotated); TCardCrypto.Clear(Received);
  end;
end;

procedure TDesfireCardReader.Start(const AAid:Cardinal; const AAuthenticate:Boolean);
var Data,Selected:TBytes; Owns:Boolean;
begin
  if FBusy or (FTransport=nil) or (AAid>$FFFFFF) then InvalidDesfire;
  if AAuthenticate then ValidateCredentials;
  if not Supports(FTransport,ICardTransaction,FTransaction) then InvalidDesfire;
  FBusy:=True; FActiveTransport:=FTransport; FWriteAttempt:=False; FAuthenticated:=False; FReauthenticated:=False;
  Owns:=False; Data:=nil; Selected:=nil;
  try
    try
      FTransaction.BeginTransaction; Owns:=True;
      Data:=TDesfireCodec.ApplicationBytes(AAid); Selected:=Exchange($5A,Data,0,False);
      if Length(Selected)<>0 then InvalidDesfire;
      if AAuthenticate and (FSecurity<>dfsPublic) then Authenticate;
    except
      if Owns then try FTransaction.EndTransaction; except end;
      TDesfireEv2Codec.ClearKeys(FKeys); TCardCrypto.Clear(FTi); TCardCrypto.Clear(FSessionIv);
      FActiveTransport:=nil; FTransaction:=nil; FBusy:=False; FAuthenticated:=False; raise;
    end;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(Selected); end;
end;

procedure TDesfireCardReader.Finish(const ASucceeded:Boolean);
begin
  try
    if ASucceeded then FTransaction.EndTransaction else try FTransaction.EndTransaction; except end;
  finally
    TDesfireEv2Codec.ClearKeys(FKeys); TCardCrypto.Clear(FTi); TCardCrypto.Clear(FSessionIv); FCounter:=0;
    FAuthenticated:=False; FReauthenticated:=False; FSessionKeyNumber:=0; FActiveTransport:=nil; FTransaction:=nil; FBusy:=False;
  end;
end;

function TDesfireCardReader.Send(const AInstruction:Byte; const AHeader,AData:TBytes;
  const AMode:TDesfireCommunication; const AExpected:Integer; const AWrite:Boolean):TBytes;
var Packet,Wire:TBytes; Limit:Integer;
begin
  Result:=nil; Packet:=nil; Wire:=nil;
  try
    if FAuthenticated and (FSecurity=dfsEv1Aes) then
    begin
      Packet:=TDesfireEv1Codec.EncodeCommand(FProvider,FKeys.Encryption,FSessionIv,
        AInstruction,AHeader,AData,AMode,AWrite);
      Limit:=AExpected+8;
      if (AMode=dfcFull) and not AWrite then Limit:=((AExpected+4+15) div 16)*16;
      Wire:=Exchange(AInstruction,Packet,Limit,AWrite);
      if AWrite then
        Result:=TDesfireEv1Codec.DecodeResponse(FProvider,FKeys.Encryption,FSessionIv,Wire,dfcMac,AExpected)
      else Result:=TDesfireEv1Codec.DecodeResponse(FProvider,FKeys.Encryption,FSessionIv,Wire,AMode,AExpected);
    end
    else if FAuthenticated then
    begin
      Packet:=TDesfireEv2Codec.EncodeCommand(FProvider,FKeys,FTi,FCounter,AInstruction,AHeader,AData,AMode);
      Limit:=AExpected;
      if AMode=dfcFull then begin if Limit>0 then Limit:=((Limit div 16)+1)*16; end;
      if AMode<>dfcPlain then Inc(Limit,8);
      Wire:=Exchange(AInstruction,Packet,Limit,AWrite); Inc(FCounter);
      Result:=TDesfireEv2Codec.DecodeResponse(FProvider,FKeys,FTi,FCounter,Wire,AMode,AExpected);
    end
    else
    begin
      if (AMode<>dfcPlain) or (Length(AData)<>0) then InvalidDesfire;
      Result:=Exchange(AInstruction,AHeader,AExpected,AWrite);
      if Length(Result)<>AExpected then InvalidDesfire;
    end;
  finally TCardCrypto.Clear(Packet); TCardCrypto.Clear(Wire); end;
end;

function TDesfireCardReader.Settings(const AFile:Byte):TDesfireFileSettings;
var H,Wire,Packet:TBytes;
begin
  if AFile>31 then InvalidDesfire;
  H:=nil; Wire:=nil; Packet:=nil;
  try
    SetLength(H,1); H[0]:=AFile;
    if FAuthenticated and (FSecurity=dfsEv1Aes) then
    begin
      Packet:=TDesfireEv1Codec.EncodeCommand(FProvider,FKeys.Encryption,FSessionIv,$F5,H,nil,dfcPlain,False);
      Wire:=Exchange($F5,Packet,25,False); if Length(Wire)<8 then InvalidDesfire;
      Packet:=TDesfireEv1Codec.DecodeResponse(FProvider,FKeys.Encryption,FSessionIv,Wire,dfcMac,Length(Wire)-8);
      Result:=TDesfireCodec.FileSettings(AFile,Packet);
    end
    else if FAuthenticated then
    begin
      Packet:=TDesfireEv2Codec.EncodeCommand(FProvider,FKeys,FTi,FCounter,$F5,H,nil,dfcMac);
      Wire:=Exchange($F5,Packet,25,False); Inc(FCounter);
      if Length(Wire)<8 then InvalidDesfire;
      Packet:=TDesfireEv2Codec.DecodeResponse(FProvider,FKeys,FTi,FCounter,Wire,dfcMac,Length(Wire)-8);
      Result:=TDesfireCodec.FileSettings(AFile,Packet);
    end
    else
    begin
      Wire:=Exchange($F5,H,17,False); Result:=TDesfireCodec.FileSettings(AFile,Wire);
    end;
  finally TCardCrypto.Clear(H); TCardCrypto.Clear(Wire); TCardCrypto.Clear(Packet); end;
end;

procedure TDesfireCardReader.CheckAccess(const ASettings:TDesfireFileSettings; const AWrite:Boolean);
var Key:Byte; FreeValue:Boolean;
  function Granted(const K:Byte):Boolean;
  begin Result:=(K=$E) or (FAuthenticated and (K=FSessionKeyNumber)); end;
begin
  if FAuthenticated then
  begin if Ord(ASettings.Communication)<Ord(FMinimum) then InvalidDesfire; end
  else if ASettings.Communication<>dfcPlain then InvalidDesfire;
  if FAuthenticated and (Length(FRekey)>0) and not FReauthenticated then Authenticate(True);
  if AWrite then Key:=ASettings.WriteKey else Key:=ASettings.ReadKey;
  FreeValue:=not AWrite and (ASettings.FileType=dftValue) and ((ASettings.ValueOptions and 2)<>0);
  if not (Granted(Key) or Granted(ASettings.ReadWriteKey) or FreeValue) then InvalidDesfire;
end;

procedure TDesfireCardReader.CheckSettings(const ASettings:TDesfireFileSettings);
var Current:TDesfireFileSettings;
begin
  Current:=Settings(ASettings.FileNumber);
  if not BytesEqual(Current.RawBytes,ASettings.RawBytes) then InvalidDesfire;
end;

function TDesfireCardReader.ReadSelected(const ASettings:TDesfireFileSettings;
  const AOffset,ACount:Integer):TBytes;
var Cmd:Byte;
begin
  Result:=nil;
  if not (ASettings.FileType in [dftStandard,dftBackup]) or (AOffset<0) or (ACount<1) or
    (ACount>FMaxTransfer) or (AOffset>ASettings.FileBytes-ACount) then InvalidDesfire;
  CheckAccess(ASettings,False); Cmd:=$BD; if FAuthenticated and (FSecurity=dfsEv2Aes) then Cmd:=$AD;
  Result:=Send(Cmd,TDesfireCodec.RangeHeader(ASettings.FileNumber,AOffset,ACount),nil,
    ASettings.Communication,ACount,False);
end;

function TDesfireCardReader.ReadVersion:TDesfireVersion;
var Snapshot:TDesfireVersion; Good:Boolean;
begin
  Result:=Default(TDesfireVersion); Start(0,False); Good:=False;
  try Snapshot:=TDesfireCodec.Version(Exchange($60,nil,28,False)); Good:=True;
  finally Finish(Good); end;
  Result:=Snapshot;
end;

function TDesfireCardReader.ReadApplicationIds:TDesfireApplicationIds;
var Ids:TDesfireApplicationIds; Good:Boolean; Wire:TBytes;
begin
  Result:=nil; Start(0,False); Good:=False; Wire:=nil;
  try
    if FAuthenticated and (FCounter>=65535) then InvalidDesfire;
    Wire:=Exchange($6A,nil,3072,False); if FAuthenticated then Inc(FCounter);
    Ids:=TDesfireCodec.ApplicationIds(Wire); Good:=True;
  finally TCardCrypto.Clear(Wire); Finish(Good); end;
  Result:=Ids;
end;

function TDesfireCardReader.ReadFiles(const AAid:Cardinal):TDesfireFiles;
var Files:TDesfireFiles; Ids:TBytes; I,J:Integer; Good:Boolean;
begin
  Result:=nil; if (AAid=0) or (AAid>$FFFFFF) then InvalidDesfire;
  ValidateCredentials;
  Start(AAid,False); Good:=False; Ids:=nil;
  try
    Ids:=Exchange($6F,nil,32,False);
    if FSecurity<>dfsPublic then Authenticate;
    SetLength(Files,Length(Ids));
    for I:=0 to High(Ids) do
    begin
      if Ids[I]>31 then InvalidDesfire;
      for J:=0 to I-1 do if Ids[J]=Ids[I] then InvalidDesfire;
      Files[I]:=Settings(Ids[I]);
    end;
    Good:=True;
  finally TCardCrypto.Clear(Ids); Finish(Good); end;
  Result:=Files;
end;

function TDesfireCardReader.ReadData(const AAid:Cardinal; const AFile:Byte;
  const AOffset,ACount:Integer):TBytes;
var S:TDesfireFileSettings; Data:TBytes; Good:Boolean;
begin
  Result:=nil;
  if (AAid=0) or (AAid>$FFFFFF) or (AFile>31) or (AOffset<0) or (AOffset>$FFFFFF) or
    (ACount<1) or (ACount>FMaxTransfer) then InvalidDesfire;
  Start(AAid,True); Good:=False;
  try S:=Settings(AFile); Data:=ReadSelected(S,AOffset,ACount); CheckSettings(S); Good:=True;
  finally Finish(Good); end;
  Result:=Data;
end;

function TDesfireCardReader.ReadValue(const AAid:Cardinal; const AFile:Byte):Integer;
var S:TDesfireFileSettings; Data,H:TBytes; Value:Integer; Good:Boolean;
begin
  Result:=0; if (AAid=0) or (AAid>$FFFFFF) or (AFile>31) or (FMaxTransfer<4) then InvalidDesfire;
  Start(AAid,True); Good:=False; Data:=nil; H:=nil;
  try
    S:=Settings(AFile); if S.FileType<>dftValue then InvalidDesfire; CheckAccess(S,False);
    SetLength(H,1); H[0]:=AFile; Data:=Send($6C,H,nil,S.Communication,4,False);
    Value:=TDesfireCodec.SignedValue(Data);
    if (Value<S.LowerLimit) or (Value>S.UpperLimit) then InvalidDesfire;
    CheckSettings(S); Good:=True;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(H); Finish(Good); end;
  Result:=Value;
end;

function TDesfireCardReader.ReadRecords(const AAid:Cardinal; const AFile:Byte;
  const AOffset,ACount:Integer):TBytes;
var S:TDesfireFileSettings; Data:TBytes; Cmd:Byte; Good:Boolean;
begin
  Result:=nil;
  if (AAid=0) or (AAid>$FFFFFF) or (AFile>31) or (AOffset<0) or (AOffset>$FFFFFF) or
    (ACount<1) or (ACount>FMaxTransfer) then InvalidDesfire;
  Start(AAid,True); Good:=False;
  try
    S:=Settings(AFile); if not (S.FileType in [dftLinearRecords,dftCyclicRecords]) then InvalidDesfire;
    CheckAccess(S,False);
    if (AOffset>S.CurrentRecords-ACount) or (ACount>FMaxTransfer div S.RecordBytes) then InvalidDesfire;
    Cmd:=$BB; if FAuthenticated and (FSecurity=dfsEv2Aes) then Cmd:=$AB;
    Data:=Send(Cmd,TDesfireCodec.RangeHeader(AFile,AOffset,ACount),nil,S.Communication,ACount*S.RecordBytes,False);
    CheckSettings(S); Good:=True;
  finally Finish(Good); end;
  Result:=Data;
end;

procedure TDesfireCardReader.WriteData(const AAid:Cardinal; const AFile:Byte;
  const AOffset:Integer; const AData:TBytes);
var S:TDesfireFileSettings; Data,Old,Reply,Header:TBytes; Good:Boolean; Cmd:Byte;
begin
  if (AAid=0) or (AAid>$FFFFFF) or (AFile>31) or (AOffset<0) or (AOffset>$FFFFFF) or
    (Length(AData)<1) or (Length(AData)>FMaxTransfer) then InvalidDesfire;
  Data:=CopyBytes(AData); Old:=nil; Reply:=nil; Header:=nil;
  try
    Start(AAid,True); Good:=False;
    try
      try
        S:=Settings(AFile); if S.FileType<>dftStandard then InvalidDesfire;
        CheckAccess(S,True); Old:=ReadSelected(S,AOffset,Length(Data)); CheckSettings(S);
        if not BytesEqual(Old,Data) then
        begin
          Header:=TDesfireCodec.RangeHeader(AFile,AOffset,Length(Data)); Cmd:=$3D;
          if FAuthenticated and (FSecurity=dfsEv2Aes) then Cmd:=$8D;
          if FAuthenticated then Reply:=Send(Cmd,Header,Data,S.Communication,0,True)
          else
          begin
            Reply:=Copy(Header,0,Length(Header)); SetLength(Reply,Length(Header)+Length(Data));
            Move(Data[0],Reply[Length(Header)],Length(Data)); Reply:=Exchange(Cmd,Reply,0,True);
          end;
          TCardCrypto.Clear(Old); Old:=ReadSelected(S,AOffset,Length(Data));
          if not BytesEqual(Old,Data) then InvalidDesfire; CheckSettings(S);
        end;
        Good:=True;
      finally Finish(Good); end;
    except on E:Exception do begin if FWriteAttempt then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally TCardCrypto.Clear(Data); TCardCrypto.Clear(Old); TCardCrypto.Clear(Reply); TCardCrypto.Clear(Header); end;
end;

end.
