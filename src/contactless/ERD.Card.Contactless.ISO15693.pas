unit ERD.Card.Contactless.ISO15693;

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
  ERD.Card.Transport, ERD.Card.Contactless;

const
  /// <summary>Maximum supported complete ISO 15693 user memory, in bytes.</summary>
  Iso15693MaxMemoryBytes = 262144;

type
  /// <summary>Invalid or unsupported ISO 15693 geometry, framing or operation.</summary>
  EIso15693Error = class(EContactlessError);
  /// <summary>Native ISO 15693 error response; retains only the raw error code, never card contents.</summary>
  EIso15693StatusError = class(EIso15693Error)
  private
    FErrorCode: Byte;
  public
    /// <summary>Creates a native card-status failure without payload or UID data.</summary>
    /// <param name="AErrorCode">Raw byte following native response Error_flag.</param>
    constructor Create(const AErrorCode: Byte); reintroduce;
    /// <summary>Native error code; interpretation depends on the standard/card profile.</summary>
    property ErrorCode: Byte read FErrorCode;
  end;
  /// <summary>Explicit block-address/system-information dialect; never selected by retry.</summary>
  TIso15693AddressMode = (
    /// <summary>Commands 20/21/2B/2C with one-byte block addresses, at most 256 blocks.</summary>
    iam8Bit,
    /// <summary>Commands 30/31/3B/3C with little-endian two-byte block addresses.</summary>
    iam16Bit
  );
  /// <summary>Explicit reader response convention; no automatic header guessing.</summary>
  TIso15693ResponseFormat = (
    /// <summary>Returned data includes the native ISO 15693 response flags, excluding RF CRC.</summary>
    irfNativeFlags,
    /// <summary>Reader strips native flags and reports native errors through APDU status.</summary>
    irfPayloadOnly
  );
  /// <summary>Decoded ISO 15693 system information and bounded physical geometry.</summary>
  /// <remarks>UID is independent canonical MSB-first E0-prefixed bytes; record assignment shares arrays.</remarks>
  TIso15693SystemInfo = record
    /// <summary>Independent eight-byte canonical UID; reversed relative to ISO transmission order.</summary>
    Uid: TBytes;
    /// <summary>Raw information flags; optional field availability is explicit.</summary>
    InformationFlags: Byte;
    /// <summary>True if a DSFID byte was supplied.</summary>
    HasDsfid: Boolean;
    /// <summary>DSFID, or zero if absent; not an access authorization.</summary>
    Dsfid: Byte;
    /// <summary>True if an AFI byte was supplied.</summary>
    HasAfi: Boolean;
    /// <summary>AFI, or zero if absent.</summary>
    Afi: Byte;
    /// <summary>True if an IC-reference byte was supplied.</summary>
    HasIcReference: Boolean;
    /// <summary>Raw IC reference, or zero if absent; not an authenticated chip identity.</summary>
    IcReference: Byte;
    /// <summary>Physical user-memory block count; memory-size field is required.</summary>
    BlockCount: Integer;
    /// <summary>Bytes per block, one through 32, from the memory-size field.</summary>
    BlockSize: Integer;
  end;
  /// <summary>Exclusive addressed ISO 15693 session used by raw-memory and Type 5 components.</summary>
  /// <remarks>One caller thread, no reentrancy. Failed acquisition grants no ownership. EndSession
  /// clears local ownership even on error. A failed operation poisons the session until release.
  /// Card writes occur once; no automatic retransmission, RF reset or authentication fallback.</remarks>
  IIso15693Session = interface
    ['{2B43650C-3171-4F18-AC2B-F8083DDC0B06}']
    /// <summary>Acquires exclusivity and validates addressed system information without writing memory.</summary>
    /// <returns>Independent UID and bounded geometry for the retained session.</returns>
    function BeginSession: TIso15693SystemInfo;
    /// <summary>Releases acquired exclusivity exactly once, including after failed I/O.</summary>
    procedure EndSession;
    /// <summary>Reads one complete physical user-memory block.</summary>
    /// <param name="ABlock">Zero-based block within acquired geometry.</param>
    /// <returns>Independent exact BlockSize bytes.</returns>
    function ReadBlock(const ABlock: Integer): TBytes;
    /// <summary>Queries one block's standard security status without changing protection.</summary>
    /// <param name="ABlock">Zero-based block within acquired geometry.</param>
    /// <returns>Zero for writable, one for locked; unsupported/reserved responses raise.</returns>
    function SecurityStatus(const ABlock: Integer): Byte;
    /// <summary>Dispatches one full-block write once; callers handle uncertain completion and read-back.</summary>
    /// <param name="ABlock">Zero-based block within acquired geometry.</param>
    /// <param name="AData">Exactly BlockSize bytes; copied, not retained or modified.</param>
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
  end;
  /// <summary>Optional addressed multiple-block read capability; the original session ABI is unchanged.</summary>
  IIso15693BlockReader = interface
    ['{13F76F58-27E7-4C6D-831E-E36968DFF82B}']
    /// <summary>Reads a bounded contiguous range in one retained session, without single-block fallback.</summary>
    /// <param name="AFirstBlock">First physical block in acquired geometry.</param>
    /// <param name="ACount">Positive block count within geometry.</param>
    /// <returns>Exact concatenated block bytes after all chunks succeed.</returns>
    function ReadMultipleBlocks(const AFirstBlock, ACount: Integer): TBytes;
  end;
  /// <summary>Optional addressed manufacturer-command channel within an acquired ISO 15693 session.</summary>
  IIso15693CustomCommands = interface
    ['{6CCFE061-A5E4-4652-8219-1DB878BB7949}']
    /// <summary>Dispatches one custom command with the acquired UID; no replay or RF reset.</summary>
    /// <param name="AManufacturer">Must match the acquired UID manufacturer byte.</param>
    /// <param name="ACommand">Custom command code A0..DF.</param>
    /// <param name="AParameters">Independent command-specific bytes; never retained.</param>
    /// <returns>Native payload without response flags or CRC.</returns>
    /// <remarks>Raw custom writes require caller uncertainty handling. An I/O failure poisons the session.</remarks>
    function ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
  end;
  /// <summary>Explicit supported RF user-memory password dialect; no automatic chip guessing.</summary>
  TIso15693PasswordProfile = (
    /// <summary>NXP SL2S2602 ICODE SLIX2, four-byte read/write passwords and random-number XOR.</summary>
    ippSlix2,
    /// <summary>ST25DV04K/16K/64K DS10925, eight-byte RF user passwords 1..3; excludes KC and ST25TV.</summary>
    ippSt25Dv
  );
  /// <summary>One supplied password in ISO transmission byte order, copied by the session wrapper.</summary>
  TIso15693Password = record
    /// <summary>SLIX2: 1 = read, 2 = write; ST25DV: RF password number 1..3.</summary>
    Identifier: Byte;
    /// <summary>SLIX2: four bytes; ST25DV: eight bytes, least significant byte first.</summary>
    Value: TBytes;
  end;
  /// <summary>Ordered credentials; no duplicate identifiers, default passwords or retry candidates.</summary>
  TIso15693Passwords = array of TIso15693Password;
  /// <summary>Authenticates a verified chip profile before exposing an exclusive memory/Type 5 session.</summary>
  /// <remarks>One caller thread. Credentials are owned copies wiped on destruction. Transaction release does
  /// not reset the RF field: the tag can retain authentication until power loss. No password rotation or protection changes.</remarks>
  TIso15693PasswordSession = class(TInterfacedObject, IIso15693Session, IIso15693BlockReader)
  private
    FInner: IIso15693Session;
    FCustom: IIso15693CustomCommands;
    FProfile: TIso15693PasswordProfile;
    FPasswords: TIso15693Passwords;
    FInfo: TIso15693SystemInfo;
    FActive, FBusy, FPoisoned: Boolean;
    procedure CheckState(const ABlock: Integer);
  public
    /// <summary>Copies and validates explicit credentials without I/O.</summary>
    /// <param name="AInner">Inactive exclusive session supporting IIso15693CustomCommands.</param>
    /// <param name="AProfile">SLIX2 or original ST25DV RF user-password dialect.</param>
    /// <param name="APasswords">SLIX2: one or two unique credentials; ST25DV: exactly one RF user password, in wire byte order.</param>
    constructor Create(const AInner: IIso15693Session; const AProfile: TIso15693PasswordProfile;
      const APasswords: TIso15693Passwords);
    /// <summary>Wipes owned credentials and best-effort releases an acquired transaction.</summary>
    destructor Destroy; override;
    /// <summary>Acquires, checks UID/type/geometry, then submits each supplied password exactly once.</summary>
    /// <returns>Independent acquired system information only after all passwords succeed.</returns>
    /// <remarks>An invalid SLIX2 password blocks further commands until an external RF power-on reset.</remarks>
    function BeginSession: TIso15693SystemInfo;
    /// <summary>Releases exclusivity and clears local state even when release fails; does not reset RF.</summary>
    procedure EndSession;
    /// <summary>Reads one physical block after successful authentication.</summary>
    /// <param name="ABlock">Index within acquired geometry.</param>
    /// <returns>Exact block bytes.</returns>
    function ReadBlock(const ABlock: Integer): TBytes;
    /// <summary>Obtains standard lock status after authentication.</summary>
    /// <param name="ABlock">Index within acquired geometry.</param>
    /// <returns>Zero or one; unsupported or reserved responses raise.</returns>
    function SecurityStatus(const ABlock: Integer): Byte;
    /// <summary>Dispatches a full-block write once; SLIX2 counter block 79 is reserved.</summary>
    /// <param name="ABlock">Acquired user-memory index.</param>
    /// <param name="AData">Exactly BlockSize bytes.</param>
    /// <remarks>Use TIso15693CardReader or TType5NdefCardReader for verification and uncertain completion.</remarks>
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
    /// <summary>Delegates an explicit multiple-block read; absence of capability raises before dispatch.</summary>
    /// <param name="AFirstBlock">First physical block.</param>
    /// <param name="ACount">Positive count in geometry.</param>
    /// <returns>Exact concatenated bytes.</returns>
    function ReadMultipleBlocks(const AFirstBlock, ACount: Integer): TBytes;
  end;
  /// <summary>Pure ISO 15693 payload and ACR1552U FF-FB addressed command codecs.</summary>
  TIso15693Codec = class
  public
    /// <summary>Builds addressed Read Multiple Blocks (23/33), option clear and no RF CRC.</summary>
    /// <param name="AUid">Canonical E0-prefixed UID.</param>
    /// <param name="AMode">One- or two-byte little-endian block/count fields.</param>
    /// <param name="AFirstBlock">First physical block in the selected address space.</param>
    /// <param name="ACount">Positive range count; count minus one is encoded.</param>
    /// <returns>FF-FB short APDU.</returns>
    class function MultipleReadCommand(const AUid: TBytes; const AMode: TIso15693AddressMode;
      const AFirstBlock, ACount: Integer): TBytes; static;
    /// <summary>Builds one addressed custom command with manufacturer before UID.</summary>
    /// <param name="AUid">Canonical UID matching AManufacturer.</param>
    /// <param name="AManufacturer">UID manufacturer byte.</param>
    /// <param name="ACommand">Custom command code A0..DF.</param>
    /// <param name="AParameters">At most 245 bytes following UID.</param>
    /// <returns>FF-FB short APDU with addressed high-rate flags.</returns>
    class function CustomCommand(const AUid: TBytes; const AManufacturer, ACommand: Byte;
      const AParameters: TBytes): TBytes; static;
    /// <summary>Validates acquired geometry and canonical UID.</summary>
    /// <param name="AInfo">One-to-32-byte blocks; at most 65536 blocks and Iso15693MaxMemoryBytes.</param>
    /// <exception cref="EIso15693Error">UID, geometry or capacity is invalid.</exception>
    class procedure ValidateInfo(const AInfo: TIso15693SystemInfo); static;
    /// <summary>Converts one ISO-transmission-order UID to canonical order.</summary>
    /// <param name="AWireUid">Exactly eight bytes ending with E0.</param>
    /// <returns>Independent reversed UID beginning with E0.</returns>
    /// <exception cref="EIso15693Error">UID size or prefix is invalid.</exception>
    class function UidFromTransmission(const AWireUid: TBytes): TBytes; static;
    /// <summary>Decodes normalized system-information payload without native response flags/CRC.</summary>
    /// <param name="APayload">Information flags, wire UID and advertised optional fields; exact complete payload.</param>
    /// <param name="AMode">Explicit ordinary or extended memory-size encoding; no fallback.</param>
    /// <returns>Independent identity and geometry; absent memory-size information is refused.</returns>
    /// <exception cref="EIso15693Error">Flags, layout, bounds or geometry is unsupported.</exception>
    class function DecodeSystemInfo(const APayload: TBytes;
      const AMode: TIso15693AddressMode): TIso15693SystemInfo; static;
    /// <summary>Normalizes explicitly selected native or reader-stripped response framing.</summary>
    /// <param name="AData">APDU data, excluding SW1/SW2 and RF CRC.</param>
    /// <param name="AFormat">Explicit flag convention verified for the actual firmware.</param>
    /// <returns>Independent payload only after native error/RFU checks when flags are present.</returns>
    /// <exception cref="EIso15693Error">Length, format or native response flags are invalid.</exception>
    class function DecodePayload(const AData: TBytes;
      const AFormat: TIso15693ResponseFormat): TBytes; static;
    /// <summary>Builds an addressed system-information FF-FB command.</summary>
    /// <param name="AUid">Canonical eight-byte E0-prefixed UID.</param>
    /// <param name="AMode">2B or 3B with parameter-request 14 before UID for extended information.</param>
    /// <returns>Independent command using high-data-rate/addressed flags 22, without Le or RF CRC.</returns>
    /// <exception cref="EIso15693Error">UID or mode is invalid.</exception>
    class function SystemInfoCommand(const AUid: TBytes;
      const AMode: TIso15693AddressMode): TBytes; static;
    /// <summary>Builds an addressed read-single-block command.</summary>
    /// <param name="AUid">Canonical UID.</param>
    /// <param name="AMode">Explicit 20 or 30 dialect.</param>
    /// <param name="ABlock">Zero-based block representable by the mode.</param>
    /// <returns>Independent FF-FB command with no option flag and no Le.</returns>
    /// <exception cref="EIso15693Error">Arguments are invalid.</exception>
    class function ReadCommand(const AUid: TBytes; const AMode: TIso15693AddressMode;
      const ABlock: Integer): TBytes; static;
    /// <summary>Builds a one-block security-status command with encoded count minus one equal to zero.</summary>
    /// <param name="AUid">Canonical UID.</param>
    /// <param name="AMode">Explicit 2C or 3C dialect.</param>
    /// <param name="ABlock">Zero-based block representable by the mode.</param>
    /// <returns>Independent addressed FF-FB command.</returns>
    /// <exception cref="EIso15693Error">Arguments are invalid.</exception>
    class function SecurityCommand(const AUid: TBytes; const AMode: TIso15693AddressMode;
      const ABlock: Integer): TBytes; static;
    /// <summary>Builds one ordinary/extended write-single-block command, with option flag clear.</summary>
    /// <param name="AUid">Canonical UID.</param>
    /// <param name="AMode">Explicit 21 or 31 dialect.</param>
    /// <param name="ABlock">Zero-based block representable by the mode.</param>
    /// <param name="AData">One through 32 bytes; caller also checks acquired block size and protection.</param>
    /// <returns>Independent addressed FF-FB command; no RF CRC or Le.</returns>
    /// <exception cref="EIso15693Error">Arguments are invalid.</exception>
    class function WriteCommand(const AUid: TBytes; const AMode: TIso15693AddressMode;
      const ABlock: Integer; const AData: TBytes): TBytes; static;
  end;
  /// <summary>Concrete ACR1552U-M/ACM1552U-Y/Z ISO 15693 FF-FB pass-through session.</summary>
  /// <remarks>Targets ACS Reference Manual 1.09, section 5.3.4.2; requires the documented minimum
  /// firmware and an existing connected ICardTransaction transport. Constructor opens no hardware.
  /// FF-CA-80 obtains DSFID/UID in transmission order; addressed system information must agree.
  /// Response-header convention and address mode are explicit; optional-command failure is not retried.</remarks>
  TAcr1552Iso15693Session = class(TInterfacedObject, IIso15693Session, IIso15693BlockReader, IIso15693CustomCommands)
  private
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FMode: TIso15693AddressMode;
    FFormat: TIso15693ResponseFormat;
    FInfo: TIso15693SystemInfo;
    FActive, FBusy, FPoisoned: Boolean;
    function Send(const ACommand: TBytes): TBytes;
    procedure CheckBlock(const ABlock: Integer);
  public
    /// <summary>Reads chunks of at most 240 data bytes with explicit 23/33 commands; no fallback.</summary>
    /// <param name="AFirstBlock">First acquired physical block.</param>
    /// <param name="ACount">Positive bounded contiguous count.</param>
    /// <returns>Exact bytes after every chunk succeeds.</returns>
    function ReadMultipleBlocks(const AFirstBlock, ACount: Integer): TBytes;
    /// <summary>Dispatches one manufacturer command in the active addressed session.</summary>
    /// <param name="AManufacturer">Must match the acquired UID.</param>
    /// <param name="ACommand">Custom opcode A0..DF.</param>
    /// <param name="AParameters">Wire-order command data; temporary APDU is wiped after dispatch.</param>
    /// <returns>Normalized native payload.</returns>
    function ExchangeCustom(const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
    /// <summary>Creates an inactive explicitly configured pass-through adapter.</summary>
    /// <param name="ATransport">Retained connected transport; must support ICardTransaction.</param>
    /// <param name="AMode">Ordinary or extended command dialect supported by the card.</param>
    /// <param name="AFormat">Observed native-flags or stripped-payload response convention; never guessed.</param>
    /// <exception cref="EIso15693Error">Transport or configuration is invalid.</exception>
    constructor Create(const ATransport: ICardTransport; const AMode: TIso15693AddressMode;
      const AFormat: TIso15693ResponseFormat);
    /// <summary>Best-effort releases an active transaction, suppressing destructor cleanup exceptions.</summary>
    destructor Destroy; override;
    /// <summary>Acquires a transaction, obtains UID and confirms addressed memory geometry.</summary>
    /// <returns>Independent system information only after complete acquisition succeeds.</returns>
    /// <exception cref="EContactlessError">Acquisition, status, framing, UID or geometry fails.</exception>
    function BeginSession: TIso15693SystemInfo;
    /// <summary>Releases an acquired transaction and clears ownership even if release fails.</summary>
    procedure EndSession;
    /// <summary>Reads one bounded addressed block without replay.</summary>
    /// <param name="ABlock">Index within acquired memory.</param>
    /// <returns>Independent exact block bytes.</returns>
    /// <exception cref="EContactlessError">State, index, response or status fails.</exception>
    function ReadBlock(const ABlock: Integer): TBytes;
    /// <summary>Queries standard security status for one addressed block.</summary>
    /// <param name="ABlock">Index within acquired memory.</param>
    /// <returns>Zero or one; unsupported optional commands raise.</returns>
    /// <exception cref="EContactlessError">State, index or status fails.</exception>
    function SecurityStatus(const ABlock: Integer): Byte;
    /// <summary>Sends one addressed full-block write; does not change UID, AFI, DSFID or locks.</summary>
    /// <param name="ABlock">Index within acquired memory.</param>
    /// <param name="AData">Exact acquired block-size payload.</param>
    /// <exception cref="EContactlessError">State, preflight or device status fails.</exception>
    /// <remarks>Direct use requires caller protection checks and uncertain-write handling; component wrappers provide them.</remarks>
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
  end;
  /// <summary>Nonvisual bounded ISO 15693 user-memory component.</summary>
  /// <remarks>Configure an inactive instance; one caller thread without reentrancy. Raw writes reserve
  /// blocks zero and one for possible Type 5 CC metadata. Use Type 5 methods for structured NDEF updates.</remarks>
  TIso15693CardReader = class(TComponent)
  private
    FSession: IIso15693Session;
    FBusy, FUseMultipleBlockRead: Boolean;
    procedure SetSession(const AValue: IIso15693Session);
    procedure SetMultipleRead(const AValue: Boolean);
  public
    /// <summary>Acquires and returns validated system information, then releases the session.</summary>
    /// <returns>Independent identity/geometry only after successful release.</returns>
    /// <exception cref="EContactlessError">Configuration, acquisition or release fails.</exception>
    function ReadInformation: TIso15693SystemInfo;
    /// <summary>Reads a contiguous bounded range of complete blocks in one exclusive session.</summary>
    /// <param name="AFirstBlock">First physical block, zero-based.</param>
    /// <param name="ACount">Positive number of blocks within acquired geometry.</param>
    /// <returns>Independent concatenated bytes after successful release.</returns>
    /// <exception cref="EContactlessError">Range, configuration or acquired block data fails.</exception>
    function ReadBlocks(const AFirstBlock, ACount: Integer): TBytes;
    /// <summary>Writes and independently verifies one unlocked data block once.</summary>
    /// <param name="ABlock">Physical index at least two; zero/one are reserved.</param>
    /// <param name="AData">Exact acquired block-size data, copied before I/O.</param>
    /// <exception cref="EContactlessError">Preflight or security status fails before dispatch.</exception>
    /// <exception cref="EContactlessWriteUncertain">Dispatched write, acquired comparison or release fails.</exception>
    /// <remarks>Matching acquired data is a verified no-op; no lock, formatting, password or UID operation.</remarks>
    procedure WriteBlock(const ABlock: Integer; const AData: TBytes);
    /// <summary>Retained exclusive backend; requires a connected concrete reader adapter.</summary>
    property Session: IIso15693Session read FSession write SetSession;
    /// <summary>Explicit optional bulk-read selection, false by default; unsupported commands never fall back.</summary>
    property UseMultipleBlockRead: Boolean read FUseMultipleBlockRead write SetMultipleRead;
    /// <summary>True during acquisition/I/O/release; nested operations are refused.</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.APDU;

procedure InvalidIso15693;
begin raise EIso15693Error.Create('Invalid or unsupported ISO 15693 operation or response.'); end;

constructor EIso15693StatusError.Create(const AErrorCode:Byte);
begin
  inherited CreateFmt('ISO 15693 card error %2.2x.',[AErrorCode]); FErrorCode:=AErrorCode;
end;

procedure CheckMode(const M: TIso15693AddressMode);
begin if (Ord(M)<Ord(Low(TIso15693AddressMode))) or (Ord(M)>Ord(High(TIso15693AddressMode))) then InvalidIso15693; end;

procedure CheckUid(const U: TBytes);
begin if Length(U)<>8 then InvalidIso15693; if U[0]<>$E0 then InvalidIso15693; end;

class procedure TIso15693Codec.ValidateInfo(const AInfo: TIso15693SystemInfo);
begin
  CheckUid(AInfo.Uid);
  if (AInfo.BlockSize<1) or (AInfo.BlockSize>32) or (AInfo.BlockCount<1) or
    (AInfo.BlockCount>65536) then InvalidIso15693;
  if AInfo.BlockCount>Iso15693MaxMemoryBytes div AInfo.BlockSize then InvalidIso15693;
end;

class function TIso15693Codec.UidFromTransmission(const AWireUid: TBytes): TBytes;
var I: Integer;
begin
  Result:=nil;
  if Length(AWireUid)<>8 then InvalidIso15693;
  SetLength(Result,8); for I:=0 to 7 do Result[I]:=AWireUid[7-I]; CheckUid(Result);
end;

class function TIso15693Codec.DecodeSystemInfo(const APayload: TBytes;
  const AMode: TIso15693AddressMode): TIso15693SystemInfo;
var P,N: Integer; Flags: Byte;
  function Take: Byte;
  begin if P>=Length(APayload) then InvalidIso15693; Result:=APayload[P]; Inc(P); end;
begin
  Result:=Default(TIso15693SystemInfo); CheckMode(AMode);
  if (Length(APayload)<11) or (Length(APayload)>15) then InvalidIso15693;
  Flags:=APayload[0];
  if (Flags and $E0)<>0 then InvalidIso15693;
  if (Flags and 4)=0 then InvalidIso15693;
  if ((AMode=iam8Bit) and ((Flags and $10)<>0)) or
    ((AMode=iam16Bit) and ((Flags and $10)=0)) then InvalidIso15693;
  Result.InformationFlags:=Flags; Result.Uid:=UidFromTransmission(Copy(APayload,1,8)); P:=9;
  Result.HasDsfid:=(Flags and 1)<>0; if Result.HasDsfid then Result.Dsfid:=Take;
  Result.HasAfi:=(Flags and 2)<>0; if Result.HasAfi then Result.Afi:=Take;
  N:=Take; if AMode=iam16Bit then N:=N or (Integer(Take) shl 8);
  Result.BlockCount:=N+1; N:=Take; if (N and $E0)<>0 then InvalidIso15693; Result.BlockSize:=N+1;
  Result.HasIcReference:=(Flags and 8)<>0; if Result.HasIcReference then Result.IcReference:=Take;
  if P<>Length(APayload) then InvalidIso15693; ValidateInfo(Result);
end;

class function TIso15693Codec.DecodePayload(const AData: TBytes;
  const AFormat: TIso15693ResponseFormat): TBytes;
begin
  Result:=nil;
  if Length(AData)>256 then InvalidIso15693;
  case AFormat of
    irfNativeFlags:
      begin
        if Length(AData)<1 then InvalidIso15693;
        if AData[0]=1 then
        begin
          if Length(AData)<>2 then InvalidIso15693;
          raise EIso15693StatusError.Create(AData[1]);
        end;
        if AData[0]<>0 then InvalidIso15693;
        Result:=Copy(AData,1,Length(AData)-1);
      end;
    irfPayloadOnly: Result:=CopyBytes(AData);
  else InvalidIso15693; end;
end;

function Wrap(const Native: TBytes): TBytes;
begin
  Result:=nil; if (Length(Native)<1) or (Length(Native)>255) then InvalidIso15693;
  SetLength(Result,Length(Native)+5); Result[0]:=$FF; Result[1]:=$FB; Result[2]:=0;
  Result[3]:=$22; Result[4]:=Length(Native); Move(Native[0],Result[5],Length(Native));
end;

function NativeCommand(const U: TBytes; const Cmd: Byte; const Prefix: TBytes): TBytes;
var I,P: Integer;
begin
  CheckUid(U); Result:=nil; SetLength(Result,9+Length(Prefix)); Result[0]:=Cmd;
  P:=1; if Length(Prefix)>0 then begin Move(Prefix[0],Result[P],Length(Prefix)); Inc(P,Length(Prefix)); end;
  for I:=0 to 7 do Result[P+I]:=U[7-I];
end;

class function TIso15693Codec.SystemInfoCommand(const AUid: TBytes;
  const AMode: TIso15693AddressMode): TBytes;
var P: TBytes;
begin
  CheckMode(AMode); P:=nil;
  if AMode=iam16Bit then begin SetLength(P,1); P[0]:=$14; Result:=Wrap(NativeCommand(AUid,$3B,P)); end
  else Result:=Wrap(NativeCommand(AUid,$2B,P));
end;

function BlockCommand(const U: TBytes; const M: TIso15693AddressMode;
  const Cmd8,Cmd16: Byte; const Block: Integer; const Tail: TBytes): TBytes;
var B: TBytes; P,N: Integer;
begin
  CheckMode(M); if (Block<0) or (Block>65535) then InvalidIso15693;
  if (M=iam8Bit) and (Block>255) then InvalidIso15693;
  if M=iam8Bit then begin B:=NativeCommand(U,Cmd8,nil); N:=1; end
  else begin B:=NativeCommand(U,Cmd16,nil); N:=2; end;
  P:=Length(B); SetLength(B,P+N+Length(Tail)); B[P]:=Block and $FF;
  if N=2 then B[P+1]:=Block shr 8;
  if Length(Tail)>0 then Move(Tail[0],B[P+N],Length(Tail)); Result:=Wrap(B);
end;

class function TIso15693Codec.ReadCommand(const AUid: TBytes;
  const AMode: TIso15693AddressMode; const ABlock: Integer): TBytes;
begin Result:=BlockCommand(AUid,AMode,$20,$30,ABlock,nil); end;

class function TIso15693Codec.SecurityCommand(const AUid: TBytes;
  const AMode: TIso15693AddressMode; const ABlock: Integer): TBytes;
var Tail: TBytes;
begin
  CheckMode(AMode); Tail:=nil; SetLength(Tail,Ord(AMode)+1);
  Result:=BlockCommand(AUid,AMode,$2C,$3C,ABlock,Tail);
end;

class function TIso15693Codec.WriteCommand(const AUid: TBytes;
  const AMode: TIso15693AddressMode; const ABlock: Integer; const AData: TBytes): TBytes;
begin
  if (Length(AData)<1) or (Length(AData)>32) then InvalidIso15693;
  Result:=BlockCommand(AUid,AMode,$21,$31,ABlock,AData);
end;

constructor TAcr1552Iso15693Session.Create(const ATransport: ICardTransport;
  const AMode: TIso15693AddressMode; const AFormat: TIso15693ResponseFormat);
begin
  inherited Create; CheckMode(AMode);
  if (ATransport=nil) or (Ord(AFormat)<Ord(Low(TIso15693ResponseFormat))) or
    (Ord(AFormat)>Ord(High(TIso15693ResponseFormat))) then InvalidIso15693;
  if not Supports(ATransport,ICardTransaction,FTransaction) then InvalidIso15693;
  FTransport:=ATransport; FMode:=AMode; FFormat:=AFormat;
end;

destructor TAcr1552Iso15693Session.Destroy;
begin if FActive then try EndSession; except end; inherited Destroy; end;

function TAcr1552Iso15693Session.Send(const ACommand: TBytes): TBytes;
var R: TApduResponse;
begin
  R:=TApduCodec.DecodeResponse(FTransport.Exchange(ACommand));
  if R.StatusWord<>ApduStatusSuccess then raise EContactlessStatusError.Create(R.StatusWord);
  if Length(R.Data)>256 then InvalidIso15693; Result:=R.Data;
end;

function TAcr1552Iso15693Session.BeginSession: TIso15693SystemInfo;
var Activation,Payload,Uid: TBytes; Owns: Boolean;
begin
  Result:=Default(TIso15693SystemInfo);
  if FActive or FBusy then InvalidIso15693;
  FBusy:=True; Owns:=False;
  try
    try
      FTransaction.BeginTransaction; Owns:=True;
      Activation:=Send(HexToBytes('FFCA800000')); if Length(Activation)<>9 then InvalidIso15693;
      Uid:=TIso15693Codec.UidFromTransmission(Copy(Activation,1,8));
      Payload:=TIso15693Codec.DecodePayload(Send(TIso15693Codec.SystemInfoCommand(Uid,FMode)),FFormat);
      FInfo:=TIso15693Codec.DecodeSystemInfo(Payload,FMode);
      if not BytesEqual(Uid,FInfo.Uid) then InvalidIso15693;
      if FInfo.HasDsfid and (FInfo.Dsfid<>Activation[0]) then InvalidIso15693;
      if (FMode=iam8Bit) and (FInfo.BlockCount>256) then InvalidIso15693;
      Result:=FInfo; Result.Uid:=CopyBytes(FInfo.Uid); FActive:=True; FPoisoned:=False;
    except
      FInfo:=Default(TIso15693SystemInfo);
      if Owns then try FTransaction.EndTransaction; except end;
      raise;
    end;
  finally FBusy:=False; end;
end;

procedure TAcr1552Iso15693Session.EndSession;
begin
  if not FActive or FBusy then InvalidIso15693;
  FBusy:=True;
  try FTransaction.EndTransaction;
  finally FActive:=False; FPoisoned:=False; FInfo:=Default(TIso15693SystemInfo); FBusy:=False; end;
end;

procedure TAcr1552Iso15693Session.CheckBlock(const ABlock: Integer);
begin
  if not FActive or FBusy or FPoisoned or (ABlock<0) or (ABlock>=FInfo.BlockCount) then InvalidIso15693;
end;

function TAcr1552Iso15693Session.ReadBlock(const ABlock: Integer): TBytes;
begin
  CheckBlock(ABlock); FBusy:=True;
  try
    try
      Result:=TIso15693Codec.DecodePayload(Send(TIso15693Codec.ReadCommand(FInfo.Uid,FMode,ABlock)),FFormat);
      if Length(Result)<>FInfo.BlockSize then InvalidIso15693;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

function TAcr1552Iso15693Session.SecurityStatus(const ABlock: Integer): Byte;
var B: TBytes;
begin
  CheckBlock(ABlock); FBusy:=True;
  try
    try
      B:=TIso15693Codec.DecodePayload(Send(TIso15693Codec.SecurityCommand(FInfo.Uid,FMode,ABlock)),FFormat);
      if Length(B)<>1 then InvalidIso15693; if B[0]>1 then InvalidIso15693; Result:=B[0];
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

procedure TAcr1552Iso15693Session.WriteBlock(const ABlock: Integer; const AData: TBytes);
var B: TBytes;
begin
  CheckBlock(ABlock); if Length(AData)<>FInfo.BlockSize then InvalidIso15693; FBusy:=True;
  try
    try
      B:=TIso15693Codec.DecodePayload(Send(TIso15693Codec.WriteCommand(FInfo.Uid,FMode,ABlock,AData)),FFormat);
      if Length(B)<>0 then InvalidIso15693;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

class function TIso15693Codec.MultipleReadCommand(const AUid: TBytes;
  const AMode: TIso15693AddressMode; const AFirstBlock, ACount: Integer): TBytes;
var Tail: TBytes; Limit: Integer;
begin
  CheckMode(AMode); Limit:=65536; if AMode=iam8Bit then Limit:=256;
  if (AFirstBlock<0) or (AFirstBlock>=Limit) or (ACount<1) or (ACount>Limit-AFirstBlock) then InvalidIso15693;
  SetLength(Tail,Ord(AMode)+1); Tail[0]:=(ACount-1) and $FF;
  if AMode=iam16Bit then Tail[1]:=(ACount-1) shr 8;
  Result:=BlockCommand(AUid,AMode,$23,$33,AFirstBlock,Tail);
end;

class function TIso15693Codec.CustomCommand(const AUid: TBytes;
  const AManufacturer, ACommand: Byte; const AParameters: TBytes): TBytes;
var B,P: TBytes; N: Integer;
begin
  CheckUid(AUid);
  if (AUid[1]<>AManufacturer) or (ACommand<$A0) or (ACommand>$DF) or
    (Length(AParameters)>245) then InvalidIso15693;
  SetLength(P,1); P[0]:=AManufacturer; B:=NativeCommand(AUid,ACommand,P);
  try
    N:=Length(B); SetLength(B,N+Length(AParameters));
    if Length(AParameters)>0 then Move(AParameters[0],B[N],Length(AParameters));
    Result:=Wrap(B);
  finally if Length(B)>0 then FillChar(B[0],Length(B),0); end;
end;

function TAcr1552Iso15693Session.ReadMultipleBlocks(const AFirstBlock, ACount: Integer): TBytes;
var Data,B: TBytes; Count,Offset,Chunk: Integer;
begin
  Result:=nil; CheckBlock(AFirstBlock);
  if (ACount<1) or (ACount>FInfo.BlockCount-AFirstBlock) then InvalidIso15693;
  FBusy:=True;
  try
    try
      SetLength(Data,ACount*FInfo.BlockSize); Offset:=0;
      while Offset<ACount do begin
        Count:=ACount-Offset; Chunk:=240 div FInfo.BlockSize; if Count>Chunk then Count:=Chunk;
        B:=TIso15693Codec.DecodePayload(Send(TIso15693Codec.MultipleReadCommand(FInfo.Uid,FMode,AFirstBlock+Offset,Count)),FFormat);
        if Length(B)<>Count*FInfo.BlockSize then InvalidIso15693;
        Move(B[0],Data[Offset*FInfo.BlockSize],Length(B)); Inc(Offset,Count);
      end;
      Result:=Data;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

function TAcr1552Iso15693Session.ExchangeCustom(const AManufacturer, ACommand: Byte;
  const AParameters: TBytes): TBytes;
var Wire: TBytes;
begin
  CheckBlock(0); Wire:=TIso15693Codec.CustomCommand(FInfo.Uid,AManufacturer,ACommand,AParameters);
  FBusy:=True;
  try
    try Result:=TIso15693Codec.DecodePayload(Send(Wire),FFormat);
    except FPoisoned:=True; raise; end;
  finally
    if Length(Wire)>0 then FillChar(Wire[0],Length(Wire),0); FBusy:=False;
  end;
end;

constructor TIso15693PasswordSession.Create(const AInner: IIso15693Session;
  const AProfile: TIso15693PasswordProfile; const APasswords: TIso15693Passwords);
var I,J,Size: Integer;
begin
  inherited Create;
  if (AInner=nil) or not Supports(AInner,IIso15693CustomCommands,FCustom) or
    (Ord(AProfile)<0) or (Ord(AProfile)>Ord(High(TIso15693PasswordProfile))) or
    (Length(APasswords)<1) or (Length(APasswords)>2) or
    ((AProfile=ippSt25Dv) and (Length(APasswords)<>1)) then InvalidIso15693;
  Size:=4; if AProfile=ippSt25Dv then Size:=8;
  for I:=0 to High(APasswords) do begin
    if (Length(APasswords[I].Value)<>Size) or (APasswords[I].Identifier<1) or
      (APasswords[I].Identifier>2+Ord(AProfile)) then InvalidIso15693;
    for J:=0 to I-1 do if APasswords[J].Identifier=APasswords[I].Identifier then InvalidIso15693;
  end;
  FInner:=AInner; FProfile:=AProfile; SetLength(FPasswords,Length(APasswords));
  for I:=0 to High(APasswords) do begin
    FPasswords[I].Identifier:=APasswords[I].Identifier; FPasswords[I].Value:=CopyBytes(APasswords[I].Value);
  end;
end;

destructor TIso15693PasswordSession.Destroy;
var I: Integer;
begin
  if FActive then try EndSession; except end;
  for I:=0 to High(FPasswords) do if Length(FPasswords[I].Value)>0 then
    FillChar(FPasswords[I].Value[0],Length(FPasswords[I].Value),0);
  FPasswords:=nil; inherited Destroy;
end;

function TIso15693PasswordSession.BeginSession: TIso15693SystemInfo;
var Info: TIso15693SystemInfo; P,Random,B: TBytes; I,J: Integer; Owns: Boolean;
begin
  Result:=Default(TIso15693SystemInfo);
  if FActive or FBusy then InvalidIso15693;
  FBusy:=True; Owns:=False; P:=nil; Random:=nil; B:=nil;
  try
    try
      Info:=FInner.BeginSession; Owns:=True; TIso15693Codec.ValidateInfo(Info);
      if Info.BlockSize<>4 then InvalidIso15693;
      if FProfile=ippSlix2 then begin
        if (Info.Uid[1]<>$04) or (Info.Uid[2]<>$01) or ((Info.Uid[3] and $18)<>$08) or
          (Info.BlockCount<>80) then InvalidIso15693;
      end else begin
        if (Info.Uid[1]<>$02) or not Info.HasIcReference then InvalidIso15693;
        if Info.BlockCount=128 then begin
          if (Info.IcReference<>$24) or (Info.Uid[2]<>$24) then InvalidIso15693;
        end else if (Info.BlockCount=512) or (Info.BlockCount=2048) then begin
          if (Info.IcReference<>$26) or (Info.Uid[2]<>$26) then InvalidIso15693;
        end else InvalidIso15693;
      end;
      for I:=0 to High(FPasswords) do begin
        SetLength(P,1+Length(FPasswords[I].Value)); P[0]:=FPasswords[I].Identifier;
        if FProfile=ippSlix2 then begin
          Random:=FCustom.ExchangeCustom($04,$B2,nil); if Length(Random)<>2 then InvalidIso15693;
          for J:=0 to 3 do P[J+1]:=FPasswords[I].Value[J] xor Random[J mod 2];
        end else Move(FPasswords[I].Value[0],P[1],8);
        B:=FCustom.ExchangeCustom(Info.Uid[1],$B3,P); if Length(B)<>0 then InvalidIso15693;
        FillChar(P[0],Length(P),0);
      end;
      FInfo:=Info; FInfo.Uid:=CopyBytes(Info.Uid); FActive:=True; FPoisoned:=False;
      Result:=Info; Result.Uid:=CopyBytes(Info.Uid);
    except
      if Owns then try FInner.EndSession; except end; raise;
    end;
  finally
    if Length(P)>0 then FillChar(P[0],Length(P),0);
    if Length(Random)>0 then FillChar(Random[0],Length(Random),0); FBusy:=False;
  end;
end;

procedure TIso15693PasswordSession.EndSession;
begin
  if not FActive or FBusy then InvalidIso15693; FBusy:=True;
  try FInner.EndSession;
  finally FActive:=False; FPoisoned:=False; FInfo:=Default(TIso15693SystemInfo); FBusy:=False; end;
end;

procedure TIso15693PasswordSession.CheckState(const ABlock: Integer);
begin
  if not FActive or FBusy or FPoisoned or (ABlock<0) or (ABlock>=FInfo.BlockCount) then InvalidIso15693;
end;

function TIso15693PasswordSession.ReadBlock(const ABlock: Integer): TBytes;
begin
  CheckState(ABlock); FBusy:=True;
  try
    try Result:=FInner.ReadBlock(ABlock); if Length(Result)<>FInfo.BlockSize then InvalidIso15693;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

function TIso15693PasswordSession.SecurityStatus(const ABlock: Integer): Byte;
begin
  CheckState(ABlock); FBusy:=True;
  try
    try Result:=FInner.SecurityStatus(ABlock); if Result>1 then InvalidIso15693;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

procedure TIso15693PasswordSession.WriteBlock(const ABlock: Integer; const AData: TBytes);
begin
  CheckState(ABlock);
  if (Length(AData)<>FInfo.BlockSize) or ((FProfile=ippSlix2) and (ABlock=79)) then InvalidIso15693;
  FBusy:=True;
  try
    try FInner.WriteBlock(ABlock,AData);
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

function TIso15693PasswordSession.ReadMultipleBlocks(const AFirstBlock, ACount: Integer): TBytes;
var Bulk: IIso15693BlockReader;
begin
  Result:=nil; CheckState(AFirstBlock);
  if (ACount<1) or (ACount>FInfo.BlockCount-AFirstBlock) or
    not Supports(FInner,IIso15693BlockReader,Bulk) then InvalidIso15693;
  FBusy:=True;
  try
    try Result:=Bulk.ReadMultipleBlocks(AFirstBlock,ACount);
      if Length(Result)<>ACount*FInfo.BlockSize then InvalidIso15693;
    except FPoisoned:=True; raise; end;
  finally FBusy:=False; end;
end;

procedure TIso15693CardReader.SetSession(const AValue: IIso15693Session);
begin if FBusy then InvalidIso15693; FSession:=AValue; end;
procedure TIso15693CardReader.SetMultipleRead(const AValue: Boolean);
begin if FBusy then InvalidIso15693; FUseMultipleBlockRead:=AValue; end;

procedure Release(const Session: IIso15693Session; const Succeeded: Boolean);
begin if Succeeded then Session.EndSession else try Session.EndSession; except end; end;

function TIso15693CardReader.ReadInformation: TIso15693SystemInfo;
var S: IIso15693Session; Info: TIso15693SystemInfo; Succeeded: Boolean;
begin
  Result:=Default(TIso15693SystemInfo); if FBusy or (FSession=nil) then InvalidIso15693;
  S:=FSession; FBusy:=True;
  try
    Info:=S.BeginSession; Succeeded:=False;
    try TIso15693Codec.ValidateInfo(Info); Succeeded:=True;
    finally Release(S,Succeeded); end;
    Result:=Info; Result.Uid:=CopyBytes(Info.Uid);
  finally FBusy:=False; end;
end;

function TIso15693CardReader.ReadBlocks(const AFirstBlock, ACount: Integer): TBytes;
var S: IIso15693Session; Bulk: IIso15693BlockReader; Info: TIso15693SystemInfo; Succeeded: Boolean; B,Data: TBytes; I: Integer;
begin
  Result:=nil; if FBusy or (FSession=nil) or (AFirstBlock<0) or (ACount<1) or
    (ACount>65536) then InvalidIso15693;
  if FUseMultipleBlockRead and not Supports(FSession,IIso15693BlockReader,Bulk) then InvalidIso15693;
  S:=FSession; FBusy:=True;
  try
    Info:=S.BeginSession; Succeeded:=False;
    try
      TIso15693Codec.ValidateInfo(Info);
      if (AFirstBlock>=Info.BlockCount) or (ACount>Info.BlockCount-AFirstBlock) then InvalidIso15693;
      if FUseMultipleBlockRead then begin
        Data:=Bulk.ReadMultipleBlocks(AFirstBlock,ACount);
        if Length(Data)<>ACount*Info.BlockSize then InvalidIso15693;
      end else begin
        SetLength(Data,ACount*Info.BlockSize);
        for I:=0 to ACount-1 do
        begin B:=S.ReadBlock(AFirstBlock+I); if Length(B)<>Info.BlockSize then InvalidIso15693;
          Move(B[0],Data[I*Info.BlockSize],Info.BlockSize); end;
      end;
      Succeeded:=True;
    finally Release(S,Succeeded); end;
    Result:=Data;
  finally FBusy:=False; end;
end;

procedure TIso15693CardReader.WriteBlock(const ABlock: Integer; const AData: TBytes);
var S: IIso15693Session; Info: TIso15693SystemInfo; Succeeded,Dispatched: Boolean; Data,Old: TBytes;
begin
  if FBusy or (FSession=nil) or (ABlock<2) or (ABlock>65535) or
    (Length(AData)<1) or (Length(AData)>32) then InvalidIso15693;
  Data:=CopyBytes(AData); S:=FSession; FBusy:=True; Dispatched:=False;
  try
    try
      Info:=S.BeginSession; Succeeded:=False;
      try
        TIso15693Codec.ValidateInfo(Info);
        if (ABlock>=Info.BlockCount) or (Length(Data)<>Info.BlockSize) then InvalidIso15693;
        if S.SecurityStatus(ABlock)<>0 then InvalidIso15693;
        Old:=S.ReadBlock(ABlock); if Length(Old)<>Info.BlockSize then InvalidIso15693;
        if not BytesEqual(Old,Data) then
        begin
          Dispatched:=True; S.WriteBlock(ABlock,Data);
          if not BytesEqual(S.ReadBlock(ABlock),Data) then InvalidIso15693;
        end;
        Succeeded:=True;
      finally Release(S,Succeeded); end;
    except on E: Exception do begin if Dispatched then raise EContactlessWriteUncertain.Create(E.ClassName); raise; end; end;
  finally FBusy:=False; end;
end;

end.
