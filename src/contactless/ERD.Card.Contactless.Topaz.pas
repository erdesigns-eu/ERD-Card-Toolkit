unit ERD.Card.Contactless.Topaz;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes,SysUtils,{$ELSE}System.Classes,System.SysUtils,{$ENDIF}
 ERD.Card.Contactless;
type
 /// <summary>Invalid Topaz model, identity, memory geometry or operation.</summary>
 ETopazError=class(EContactlessError);
 /// <summary>Explicit Broadcom Topaz profile; unsupported header ROM values are refused.</summary>
 TTopazModel=(
  /// <summary>BCM20203T96, HR 11 48, 120 physical bytes.</summary>
  tmTopaz96,
  /// <summary>BCM20203T512, HR 12 4C, 512 physical bytes.</summary>
  tmTopaz512);
 /// <summary>Owned target parameters obtained by fresh Jewel activation and RID.</summary>
 TTopazTarget=record
  /// <summary>Two SENS_RES bytes in reader wire order; retained without guessed interpretation.</summary>
  SensRes:TBytes;
  /// <summary>Exact two-byte header ROM.</summary>
  HeaderRom:TBytes;
  /// <summary>Four-byte RID identity echo, matching the beginning of the full UID.</summary>
  UidEcho:TBytes;
 end;
 /// <summary>Complete owned physical memory and conservative user-write permissions.</summary>
 TTopazSnapshot=record
  /// <summary>Explicit selected profile.</summary>
  Model:TTopazModel;
  /// <summary>Independent fresh target metadata.</summary>
  Target:TTopazTarget;
  /// <summary>Seven-byte UID in card memory order.</summary>
  Uid:TBytes;
  /// <summary>All 120 or 512 bytes, including CC, locks, reserved bytes and OTP.</summary>
  Memory:TBytes;
  /// <summary>One byte per physical byte: one permits user data writes, zero protects metadata or locked storage.</summary>
  Writable:TBytes;
 end;
 /// <summary>Exclusive, freshly activated Type 1 reader session; providers must not retry writes.</summary>
 ITopazSession=interface
  ['{167F7F54-90AB-4932-9442-934CDBBEE70A}']
  /// <summary>Acquires exclusivity and activates exactly the requested model.</summary>
  /// <param name="AModel">Exact profile, checked against RID.</param>
  /// <returns>Independent target metadata.</returns>
  function BeginSession(const AModel:TTopazModel):TTopazTarget;
  /// <summary>Deactivates RF and releases exclusivity, including after errors.</summary>
  procedure EndSession;
  /// <summary>Reads complete physical memory with verified identity and geometry.</summary>
  /// <returns>Owned 120 or 512 bytes.</returns>
  function ReadMemory:TBytes;
  /// <summary>Reads one complete physical eight-byte block.</summary>
  /// <param name="ABlock">Zero-based block within the activated model.</param>
  /// <returns>Owned eight bytes.</returns>
  function ReadBlock(const ABlock:Byte):TBytes;
  /// <summary>Programs one static-memory byte with erase; Topaz 96 only.</summary>
  /// <param name="AAddress">Physical byte address.</param>
  /// <param name="AValue">Replacement byte.</param>
  procedure WriteByte(const AAddress,AValue:Byte);
  /// <summary>Programs an eight-byte block with erase; Topaz 512 only.</summary>
  /// <param name="ABlock">Physical block number.</param>
  /// <param name="AData">Exact eight replacement bytes.</param>
  procedure WriteBlock(const ABlock:Byte;const AData:TBytes);
 end;
 /// <summary>Pure model, identity, lock-map and CRC-B codec, plus explicitly acquired image verification.</summary>
 TTopazCodec=class
 public
  /// <summary>Returns exact physical profile size, refusing invalid enum values.</summary>
  /// <param name="AModel">Explicit profile.</param>
  /// <returns>120 or 512 bytes.</returns>
  class function MemorySize(const AModel:TTopazModel):Integer;static;
  /// <summary>Checks exact model header ROM and owned target lengths.</summary>
  /// <param name="AModel">Expected profile.</param>
  /// <param name="ATarget">Fresh activation metadata.</param>
  class procedure CheckTarget(const AModel:TTopazModel;const ATarget:TTopazTarget);static;
  /// <summary>Validates complete memory/UID and derives static/dynamic locks, excluding immutable/control bytes.</summary>
  /// <param name="AModel">Explicit profile.</param>
  /// <param name="ATarget">Fresh activation metadata.</param>
  /// <param name="AMemory">Complete physical bytes, never modified.</param>
  /// <returns>Independent snapshot and writable map.</returns>
  class function Decode(const AModel:TTopazModel;const ATarget:TTopazTarget;const AMemory:TBytes):TTopazSnapshot;static;
  /// <summary>Validates a caller-supplied complete preimage locally; does not establish a fresh card identity.</summary>
  /// <param name="AModel">Exact expected profile.</param>
  /// <param name="AExpectedUid">Seven bytes matching the beginning of AExpectedMemory.</param>
  /// <param name="AExpectedMemory">Complete physical preimage.</param>
  /// <returns>Independent preimage with derived lock map, for validation before reader I/O.</returns>
  class function Preimage(const AModel:TTopazModel;const AExpectedUid,AExpectedMemory:TBytes):TTopazSnapshot;static;
  /// <summary>Computes ISO/IEC 14443 CRC-B, initial FFFF, reflected polynomial 8408, final complement.</summary>
  /// <param name="AData">Exact RF bytes excluding CRC.</param>
  /// <returns>CRC word; transmit low byte first.</returns>
  class function CrcB(const AData:TBytes):Word;static;
  /// <summary>Checks a complete desired image against conservative write permissions before dispatch.</summary>
  /// <param name="ABefore">Validated complete preimage.</param>
  /// <param name="AAfter">Same-size desired memory with unchanged protected bytes.</param>
  class procedure CheckImage(const ABefore:TTopazSnapshot;const AAfter:TBytes);static;
  /// <summary>Programs only changed units and verifies each by independent readback; caller owns an active session.</summary>
  /// <param name="ASession">Exclusive activated session corresponding to ABefore.</param>
  /// <param name="ABefore">Complete validated current preimage.</param>
  /// <param name="AAfter">Complete desired image; protected bytes must match.</param>
  /// <param name="ADispatched">Set before any write call and never cleared.</param>
  class procedure ProgramImage(const ASession:ITopazSession;const ABefore:TTopazSnapshot;const AAfter:TBytes;var ADispatched:Boolean);static;
 end;
 /// <summary>Topaz memory reader/writer with exact UID/full-memory preimages and independent write verification.</summary>
 /// <remarks>Excludes UID, CC, control TLVs, locks, reserved bytes and OTP from raw writes. No formatting or lock programming.
 /// Configure and call on one thread. A failed dispatched write is uncertain and is never retried.</remarks>
 TTopazCardReader=class(TComponent)
 private
  FSession:ITopazSession;FModel:TTopazModel;FBusy:Boolean;FTarget:TTopazTarget;
  procedure SetSession(const AValue:ITopazSession);
  procedure SetModel(const AValue:TTopazModel);
 protected
  /// <summary>Acquires exclusive access and validates the selected target.</summary>
  procedure Acquire;
  /// <summary>Releases access, preserving a prior failure when cleanup also fails.</summary>
  /// <param name="ASucceeded">True exposes cleanup failures; false retains the original failure.</param>
  procedure Release(const ASucceeded:Boolean);
  /// <summary>Reads and validates complete memory in the currently acquired session.</summary>
  /// <returns>Independent physical snapshot.</returns>
  function Snapshot:TTopazSnapshot;
 public
  /// <summary>Creates inactive Topaz 96 access without reader I/O.</summary>
  /// <param name="AOwner">Optional component owner.</param>
  constructor Create(AOwner:TComponent);override;
  /// <summary>Reads all memory, identity and user-write permissions in one exclusive session.</summary>
  /// <returns>Independent snapshot after successful release.</returns>
  function ReadSnapshot:TTopazSnapshot;
  /// <summary>Reads an explicit physical byte range, including readable metadata.</summary>
  /// <param name="AAddress">Zero-based byte address.</param>
  /// <param name="ACount">Positive byte count within the profile.</param>
  /// <returns>Independent requested bytes.</returns>
  function ReadRange(const AAddress,ACount:Integer):TBytes;
  /// <summary>Replaces unlocked user bytes only after exact full-memory and UID comparison, preserving other storage.</summary>
  /// <param name="AExpectedUid">Exact seven-byte UID from a prior snapshot.</param>
  /// <param name="AExpectedMemory">Complete 120/512-byte prior snapshot.</param>
  /// <param name="AAddress">First physical user byte.</param>
  /// <param name="AData">Nonempty replacement bytes, entirely writable.</param>
  /// <returns>Complete independently verified final snapshot.</returns>
  /// <exception cref="EContactlessWriteUncertain">Any error after write dispatch, including release.</exception>
  function WriteUserRangeVerified(const AExpectedUid,AExpectedMemory:TBytes;const AAddress:Integer;const AData:TBytes):TTopazSnapshot;
  /// <summary>Explicit inactive reader adapter; cannot change during an operation.</summary>
  property Session:ITopazSession read FSession write SetSession;
  /// <summary>True during an exclusive operation.</summary>
  property Busy:Boolean read FBusy;
 published
  /// <summary>Exact expected Topaz model; defaults to Topaz 96.</summary>
  property Model:TTopazModel read FModel write SetModel default tmTopaz96;
 end;
implementation
uses ERD.Card.Bytes;
procedure Invalid;begin raise ETopazError.Create('Invalid or unsupported Topaz operation, identity or memory.');end;
class function TTopazCodec.MemorySize(const AModel:TTopazModel):Integer;
begin case AModel of tmTopaz96:Result:=120;tmTopaz512:Result:=512;else Invalid;Result:=0;end;end;
class procedure TTopazCodec.CheckTarget(const AModel:TTopazModel;const ATarget:TTopazTarget);
begin
 MemorySize(AModel);if (Length(ATarget.SensRes)<>2) or (Length(ATarget.HeaderRom)<>2) or (Length(ATarget.UidEcho)<>4) then Invalid;
 if AModel=tmTopaz96 then begin if (ATarget.HeaderRom[0]<>$11) or (ATarget.HeaderRom[1]<>$48) then Invalid;end
 else if (ATarget.HeaderRom[0]<>$12) or (ATarget.HeaderRom[1]<>$4C) then Invalid;
end;
class function TTopazCodec.Decode(const AModel:TTopazModel;const ATarget:TTopazTarget;const AMemory:TBytes):TTopazSnapshot;
var I,Block,Bit:Integer;Locked:Boolean;
begin
 Result:=Default(TTopazSnapshot);CheckTarget(AModel,ATarget);
 if (Length(AMemory)<>MemorySize(AModel)) or not BytesEqual(Copy(AMemory,0,4),ATarget.UidEcho) then Invalid;
 Result.Model:=AModel;Result.Target.SensRes:=CopyBytes(ATarget.SensRes);Result.Target.HeaderRom:=CopyBytes(ATarget.HeaderRom);
 Result.Target.UidEcho:=CopyBytes(ATarget.UidEcho);Result.Uid:=Copy(AMemory,0,7);Result.Memory:=CopyBytes(AMemory);
 SetLength(Result.Writable,Length(AMemory));
 for I:=12 to Length(AMemory)-1 do begin
  if (I>=104) and (I<128) then Continue;
  if (AModel=tmTopaz512) and (I<22) then Continue;
  if I<104 then begin Block:=I div 8;Locked:=(AMemory[112+Block div 8] and (1 shl (Block mod 8)))<>0;end
  else begin Bit:=(I-128) div 8;Locked:=(AMemory[122+Bit div 8] and (1 shl (Bit mod 8)))<>0;end;
  if not Locked then Result.Writable[I]:=1;
 end;
end;
class function TTopazCodec.Preimage(const AModel:TTopazModel;const AExpectedUid,AExpectedMemory:TBytes):TTopazSnapshot;
var Target:TTopazTarget;
begin
 if (Length(AExpectedUid)<>7) or (Length(AExpectedMemory)<>MemorySize(AModel)) or not BytesEqual(Copy(AExpectedMemory,0,7),AExpectedUid) then Invalid;
 Target:=Default(TTopazTarget);SetLength(Target.SensRes,2);Target.UidEcho:=Copy(AExpectedUid,0,4);
 if AModel=tmTopaz96 then Target.HeaderRom:=HexToBytes('1148') else Target.HeaderRom:=HexToBytes('124C');
 Result:=Decode(AModel,Target,AExpectedMemory);
end;
class function TTopazCodec.CrcB(const AData:TBytes):Word;
var C:Word;I,J:Integer;
begin C:=$FFFF;for I:=0 to High(AData) do begin C:=C xor AData[I];for J:=1 to 8 do if (C and 1)<>0 then C:=(C shr 1) xor $8408 else C:=C shr 1;end;Result:=C xor $FFFF;end;
class procedure TTopazCodec.CheckImage(const ABefore:TTopazSnapshot;const AAfter:TBytes);
var I:Integer;S:TTopazSnapshot;
begin
 S:=Decode(ABefore.Model,ABefore.Target,ABefore.Memory);if Length(AAfter)<>Length(S.Memory) then Invalid;
 for I:=0 to High(AAfter) do if (S.Memory[I]<>AAfter[I]) and (S.Writable[I]<>1) then Invalid;
end;
class procedure TTopazCodec.ProgramImage(const ASession:ITopazSession;const ABefore:TTopazSnapshot;const AAfter:TBytes;var ADispatched:Boolean);
var I,UnitSize:Integer;Data,BeforeData,Current:TBytes;
begin
 CheckImage(ABefore,AAfter);if ASession=nil then Invalid;UnitSize:=1;if ABefore.Model=tmTopaz512 then UnitSize:=8;I:=0;Current:=CopyBytes(ABefore.Memory);
 while I<Length(AAfter) do begin
  Data:=Copy(AAfter,I,UnitSize);BeforeData:=Copy(ABefore.Memory,I,UnitSize);
  if not BytesEqual(Data,BeforeData) then begin
   ADispatched:=True;
   if UnitSize=1 then ASession.WriteByte(I,Data[0]) else ASession.WriteBlock(I div 8,Data);
   Move(Data[0],Current[I],UnitSize);
   if not BytesEqual(ASession.ReadBlock(I div 8),Copy(Current,(I div 8)*8,8)) then Invalid;
  end;
  Inc(I,UnitSize);
 end;
 if not BytesEqual(ASession.ReadMemory,AAfter) then Invalid;
end;
constructor TTopazCardReader.Create(AOwner:TComponent);begin inherited Create(AOwner);FModel:=tmTopaz96;end;
procedure TTopazCardReader.SetSession(const AValue:ITopazSession);begin if FBusy then Invalid;FSession:=AValue;end;
procedure TTopazCardReader.SetModel(const AValue:TTopazModel);begin if FBusy then Invalid;TTopazCodec.MemorySize(AValue);FModel:=AValue;end;
procedure TTopazCardReader.Acquire;
begin
 if FBusy or (FSession=nil) then Invalid;FBusy:=True;
 try FTarget:=FSession.BeginSession(FModel);except FBusy:=False;raise;end;
 try TTopazCodec.CheckTarget(FModel,FTarget);except Release(False);raise;end;
end;
procedure TTopazCardReader.Release(const ASucceeded:Boolean);
begin try if ASucceeded then FSession.EndSession else try FSession.EndSession;except end;finally FBusy:=False;FTarget:=Default(TTopazTarget);end;end;
function TTopazCardReader.Snapshot:TTopazSnapshot;
begin Result:=TTopazCodec.Decode(FModel,FTarget,FSession.ReadMemory);end;
function TTopazCardReader.ReadSnapshot:TTopazSnapshot;
var S:TTopazSnapshot;Ok:Boolean;
begin Acquire;Ok:=False;try S:=Snapshot;Ok:=True;finally Release(Ok);end;Result:=S;end;
function TTopazCardReader.ReadRange(const AAddress,ACount:Integer):TBytes;
var S:TTopazSnapshot;
begin if (AAddress<0) or (ACount<1) or (ACount>TTopazCodec.MemorySize(FModel)) or (AAddress>TTopazCodec.MemorySize(FModel)-ACount) then Invalid;S:=ReadSnapshot;Result:=Copy(S.Memory,AAddress,ACount);end;
function TTopazCardReader.WriteUserRangeVerified(const AExpectedUid,AExpectedMemory:TBytes;const AAddress:Integer;const AData:TBytes):TTopazSnapshot;
var Uid,Expected,Data,Image:TBytes;I:Integer;S:TTopazSnapshot;Ok,Dispatched:Boolean;
begin
 Result:=Default(TTopazSnapshot);Uid:=CopyBytes(AExpectedUid);Expected:=CopyBytes(AExpectedMemory);Data:=CopyBytes(AData);
 if (Length(Uid)<>7) or (Length(Expected)<>TTopazCodec.MemorySize(FModel)) or (AAddress<0) or (Length(Data)=0) or
  (Length(Data)>Length(Expected)) or (AAddress>Length(Expected)-Length(Data)) then Invalid;
 if not BytesEqual(Copy(Expected,0,7),Uid) then Invalid;
 S:=TTopazCodec.Preimage(FModel,Uid,Expected);
 for I:=AAddress to AAddress+Length(Data)-1 do if S.Writable[I]<>1 then Invalid;
 Image:=CopyBytes(Expected);Move(Data[0],Image[AAddress],Length(Data));TTopazCodec.CheckImage(S,Image);Dispatched:=False;
 try
  Acquire;Ok:=False;
  try
   S:=Snapshot;if not BytesEqual(S.Uid,Uid) or not BytesEqual(S.Memory,Expected) then Invalid;
   for I:=AAddress to AAddress+Length(Data)-1 do if S.Writable[I]<>1 then Invalid;
   TTopazCodec.ProgramImage(FSession,S,Image,Dispatched);S:=Snapshot;if not BytesEqual(S.Memory,Image) then Invalid;Ok:=True;
  finally Release(Ok);end;
 except if Dispatched then raise EContactlessWriteUncertain.Create('Topaz write outcome is uncertain; do not retry automatically.');raise;end;
 Result:=S;
end;
end.
