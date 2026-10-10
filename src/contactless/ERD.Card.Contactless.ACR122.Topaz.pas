unit ERD.Card.Contactless.ACR122.Topaz;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Transport,ERD.Card.Contactless.Topaz;
type
 /// <summary>Explicit firmware WRITE-E acknowledgement shape; no response-shape guessing.</summary>
 TTopazByteAck=(
  /// <summary>PN532 documented status-only acknowledgement.</summary>
  tbaStatusOnly,
  /// <summary>Firmware-specific single programmed-byte echo following status.</summary>
  tbaByteEcho);
 /// <summary>Opt-in ACR122U FF00 PN532 Jewel adapter; Topaz 512 uses CIU READ8/WRITE-E8 with software CRC-B/parity checks.</summary>
 /// <remarks>Requires exclusive transport, finite RF timeout and zero retries. Settings persist until reader reset/reconfiguration.
 /// Does not implement arbitrary Type 1 cards, UID changes, non-erasing writes or permanent locks.</remarks>
 TAcr122TopazSession=class(TInterfacedObject,ITopazSession)
 private
  FTransport:ICardTransport;FTx:ICardTransaction;FActive,FSelected,FFailed:Boolean;
  FModel:TTopazModel;FTarget:TTopazTarget;FAck:TTopazByteAck;
  function Send(const AData:TBytes;const ACode:Byte):TBytes;
  function Native(const ACommand:TBytes):TBytes;
  function ReadRegisters(const ARegisters:array of Word):TBytes;
  procedure WriteRegisters(const ARegisters:array of Word;const AValues:array of Byte);
  function BlockExchange(const ACommand,ABlock:Byte;const AData:TBytes):TBytes;
  function StaticMemory:TBytes;
  procedure RequireActive;
 public
  /// <summary>Retains an explicit direct-transmit transport without reader I/O.</summary>
  /// <param name="ATransport">Connected ICardTransport supporting ICardTransaction.</param>
  /// <param name="AAck">Explicit WRITE-E byte acknowledgement dialect, default documented status only.</param>
  constructor Create(const ATransport:ICardTransport;const AAck:TTopazByteAck=tbaStatusOnly);
  /// <summary>Best-effort release; EndSession exposes cleanup errors.</summary>
  destructor Destroy;override;
  /// <summary>Acquires exclusivity, configures finite zero-retry RF, polls Jewel and validates RID model/identity.</summary>
  /// <param name="AModel">Exact Topaz 96 or 512 profile.</param>
  /// <returns>Owned SENS_RES, header ROM and UID echo.</returns>
  function BeginSession(const AModel:TTopazModel):TTopazTarget;
  /// <summary>Turns RF off and releases transaction even after failed exchange.</summary>
  procedure EndSession;
  /// <summary>Reads static RALL data and, for Topaz 512, remaining READ8 blocks.</summary>
  /// <returns>Owned complete memory in physical address order.</returns>
  function ReadMemory:TBytes;
  /// <summary>Reads eight bytes via RALL for Topaz 96 or CIU READ8 for Topaz 512.</summary>
  /// <param name="ABlock">Physical zero-based block within the model.</param>
  /// <returns>Owned eight-byte data after RF integrity/identity checks.</returns>
  function ReadBlock(const ABlock:Byte):TBytes;
  /// <summary>Dispatches one PN532 WRITE-E on Topaz 96, validating the configured acknowledgement.</summary>
  /// <param name="AAddress">Physical byte address, 0..119; high-level writer guards protected storage.</param>
  /// <param name="AValue">Replacement byte.</param>
  procedure WriteByte(const AAddress,AValue:Byte);
  /// <summary>Dispatches one native WRITE-E8 on Topaz 512, validating block/data echo, parity and CRC.</summary>
  /// <param name="ABlock">Physical block, 0..63; high-level writer guards protected storage.</param>
  /// <param name="AData">Exact eight replacement bytes.</param>
  procedure WriteBlock(const ABlock:Byte;const AData:TBytes);
 end;
implementation
uses ERD.Card.Bytes,ERD.Card.APDU;
const
 CommandReg=$6331;IrqReg=$6334;ErrorReg=$6336;FifoReg=$6339;LevelReg=$633A;
 ControlReg=$633C;FramingReg=$633D;ManualReg=$630D;TxModeReg=$6302;RxModeReg=$6303;
procedure Invalid;begin raise ETopazError.Create('Invalid ACR122 Topaz operation or RF response.');end;
constructor TAcr122TopazSession.Create(const ATransport:ICardTransport;const AAck:TTopazByteAck);
var Tx:ICardTransaction;
begin inherited Create;if (ATransport=nil) or not Supports(ATransport,ICardTransaction,Tx) or not (AAck in [tbaStatusOnly,tbaByteEcho]) then Invalid;FTransport:=ATransport;FAck:=AAck;end;
destructor TAcr122TopazSession.Destroy;begin if FActive then try EndSession;except end;inherited Destroy;end;
function TAcr122TopazSession.Send(const AData:TBytes;const ACode:Byte):TBytes;
var Wire:TBytes;Response:TApduResponse;
begin
 Result:=nil;if (Length(AData)<2) or (Length(AData)>255) or (AData[0]<>$D4) then Invalid;
 SetLength(Wire,Length(AData)+5);Wire[0]:=$FF;Wire[4]:=Length(AData);Move(AData[0],Wire[5],Length(AData));
 try
  Response:=TApduCodec.DecodeResponse(FTransport.Exchange(Wire));
  if (Response.StatusWord<>$9000) or (Length(Response.Data)<2) or (Response.Data[0]<>$D5) or (Response.Data[1]<>ACode) then Invalid;
  Result:=Copy(Response.Data,2,Length(Response.Data)-2);
 except FFailed:=True;raise;end;
end;
procedure TAcr122TopazSession.RequireActive;begin if not FActive or not FSelected or FFailed then Invalid;end;
function TAcr122TopazSession.Native(const ACommand:TBytes):TBytes;
var Wire,Data:TBytes;
begin
 RequireActive;Wire:=HexToBytes('D44001');SetLength(Wire,3+Length(ACommand));if Length(ACommand)>0 then Move(ACommand[0],Wire[3],Length(ACommand));
 try Data:=Send(Wire,$41);if (Length(Data)<1) or (Data[0]<>0) then Invalid;Result:=Copy(Data,1,Length(Data)-1);
 except FFailed:=True;raise;end;
end;
function TAcr122TopazSession.BeginSession(const AModel:TTopazModel):TTopazTarget;
var Data:TBytes;
begin
 TTopazCodec.MemorySize(AModel);if FActive or not Supports(FTransport,ICardTransaction,FTx) then Invalid;
 try FTx.BeginTransaction;except FTx:=nil;raise;end;FActive:=True;FSelected:=False;FFailed:=False;FModel:=AModel;
 try
  if Length(Send(HexToBytes('D43202000B0D'),$33))<>0 then Invalid;
  if Length(Send(HexToBytes('D4320400'),$33))<>0 then Invalid;
  if Length(Send(HexToBytes('D43205000000'),$33))<>0 then Invalid;
  if Length(Send(HexToBytes('D4320100'),$33))<>0 then Invalid;
  if Length(Send(HexToBytes('D4320101'),$33))<>0 then Invalid;
  Data:=Send(HexToBytes('D44A0104'),$4B);
  if (Length(Data)<>8) or (Data[0]<>1) or (Data[1]<>1) then Invalid;
  FTarget.SensRes:=Copy(Data,2,2);FTarget.UidEcho:=Copy(Data,4,4);FSelected:=True;
  Data:=Native(HexToBytes('72'));if (Length(Data)<>6) or not BytesEqual(Copy(Data,2,4),FTarget.UidEcho) then Invalid;
  FTarget.HeaderRom:=Copy(Data,0,2);TTopazCodec.CheckTarget(FModel,FTarget);
  Result.SensRes:=CopyBytes(FTarget.SensRes);Result.HeaderRom:=CopyBytes(FTarget.HeaderRom);Result.UidEcho:=CopyBytes(FTarget.UidEcho);
 except try EndSession;except end;raise;end;
end;
procedure TAcr122TopazSession.EndSession;
var Tx:ICardTransaction;Ok:Boolean;
begin
 if not FActive then Invalid;Tx:=FTx;Ok:=False;
 try
  try if Length(Send(HexToBytes('D4320100'),$33))<>0 then Invalid;Ok:=True;
  finally FActive:=False;FSelected:=False;FFailed:=False;FTx:=nil;FTarget:=Default(TTopazTarget);
   if Ok then Tx.EndTransaction else try Tx.EndTransaction;except end;
  end;
 finally Tx:=nil;end;
end;
function TAcr122TopazSession.StaticMemory:TBytes;
var Data:TBytes;
begin
 try
  Data:=Native(HexToBytes('00'));if (Length(Data)<>122) or not BytesEqual(Copy(Data,0,2),FTarget.HeaderRom) or
   not BytesEqual(Copy(Data,2,4),FTarget.UidEcho) then Invalid;Result:=Copy(Data,2,120);
 except FFailed:=True;raise;end;
end;
function TAcr122TopazSession.ReadRegisters(const ARegisters:array of Word):TBytes;
var Wire:TBytes;I:Integer;
begin
 if (Length(ARegisters)<1) or (Length(ARegisters)>126) then Invalid;SetLength(Wire,2+2*Length(ARegisters));Wire[0]:=$D4;Wire[1]:=6;
 for I:=0 to High(ARegisters) do begin Wire[2+2*I]:=ARegisters[I] shr 8;Wire[3+2*I]:=ARegisters[I] and $FF;end;
 try Result:=Send(Wire,7);if Length(Result)<>Length(ARegisters) then Invalid;except FFailed:=True;raise;end;
end;
procedure TAcr122TopazSession.WriteRegisters(const ARegisters:array of Word;const AValues:array of Byte);
var Wire:TBytes;I:Integer;
begin
 if (Length(ARegisters)<1) or (Length(ARegisters)>84) or (Length(ARegisters)<>Length(AValues)) then Invalid;
 SetLength(Wire,2+3*Length(ARegisters));Wire[0]:=$D4;Wire[1]:=8;
 for I:=0 to High(ARegisters) do begin Wire[2+3*I]:=ARegisters[I] shr 8;Wire[3+3*I]:=ARegisters[I] and $FF;Wire[4+3*I]:=AValues[I];end;
 try if Length(Send(Wire,9))<>0 then Invalid;except FFailed:=True;raise;end;
end;
function TAcr122TopazSession.BlockExchange(const ACommand,ABlock:Byte;const AData:TBytes):TBytes;
var Frame,Saved,State,Fifo,Decoded:TBytes;Registers:array of Word;Values:TBytes;
 I,J,K,N,Parity,Bit:Integer;C:Word;Started:UInt64;Ok:Boolean;
 procedure Add(const R:Word;const V:Byte);
 begin N:=Length(Registers);SetLength(Registers,N+1);SetLength(Values,N+1);Registers[N]:=R;Values[N]:=V;end;
 procedure Restore;
 begin WriteRegisters([CommandReg,LevelReg,ManualReg,FramingReg,TxModeReg,RxModeReg],[0,$80,Saved[0],Saved[1],Saved[2],Saved[3]]);end;
begin
 RequireActive;if (FModel<>tmTopaz512) or (ABlock>63) or not (ACommand in [2,$54]) or (Length(AData)<>8) then Invalid;
 Frame:=nil;SetLength(Frame,14);Frame[0]:=ACommand;Frame[1]:=ABlock;Move(AData[0],Frame[2],8);Move(FTarget.UidEcho[0],Frame[10],4);
 C:=TTopazCodec.CrcB(Frame);SetLength(Frame,16);Frame[14]:=C and $FF;Frame[15]:=C shr 8;
 Saved:=ReadRegisters([ManualReg,FramingReg,TxModeReg,RxModeReg]);Ok:=False;
 try
  try
   WriteRegisters([CommandReg,LevelReg,IrqReg,TxModeReg,RxModeReg],[0,$80,$7F,Saved[2] and $7F,Saved[3] and $7F]);
   Registers:=nil;Values:=nil;Add(FifoReg,Frame[0]);Add(FramingReg,7);Add(CommandReg,4);Add(FramingReg,0);Add(ManualReg,Saved[0] or $10);
   for I:=1 to High(Frame) do begin Add(FifoReg,Frame[I]);Add(CommandReg,4);Add(CommandReg,7);end;
   Add(CommandReg,8);WriteRegisters(Registers,Values);if ACommand=$54 then Sleep(6);
   Started:=GetTickCount64;
   repeat
    State:=ReadRegisters([IrqReg]);if (State[0] and $20)<>0 then Break;
    if ((State[0] and 1)<>0) or (GetTickCount64-Started>=500) then Invalid;Sleep(1);
   until False;
   State:=ReadRegisters([ErrorReg,LevelReg,ControlReg]);
   if (State[0]<>0) or (State[1]<>13) or ((State[2] and 7)<>3) then Invalid;
   SetLength(Registers,13);for I:=0 to 12 do Registers[I]:=FifoReg;Fifo:=ReadRegisters(Registers);
   SetLength(Decoded,11);
   for I:=0 to 10 do begin
    Decoded[I]:=0;Parity:=0;
    for J:=0 to 8 do begin K:=I*9+J;Bit:=(Fifo[K div 8] shr (K mod 8)) and 1;Parity:=Parity xor Bit;
     if J<8 then Decoded[I]:=Decoded[I] or (Bit shl J);
    end;
    if Parity<>1 then Invalid;
   end;
   C:=TTopazCodec.CrcB(Copy(Decoded,0,9));if (Decoded[9]<>(C and $FF)) or (Decoded[10]<>(C shr 8)) or (Decoded[0]<>ABlock) then Invalid;
   Result:=Copy(Decoded,1,8);if (ACommand=$54) and not BytesEqual(Result,AData) then Invalid;Ok:=True;
  finally if Ok then Restore else try Restore;except end;end;
 except FFailed:=True;raise;end;
end;
function TAcr122TopazSession.ReadMemory:TBytes;
var I:Integer;Data:TBytes;
begin
 RequireActive;Result:=StaticMemory;
 if FModel=tmTopaz512 then begin SetLength(Result,512);for I:=15 to 63 do begin Data:=ReadBlock(I);Move(Data[0],Result[I*8],8);end;end;
end;
function TAcr122TopazSession.ReadBlock(const ABlock:Byte):TBytes;
begin
 RequireActive;if ABlock>=TTopazCodec.MemorySize(FModel) div 8 then Invalid;
 if FModel=tmTopaz96 then Result:=Copy(StaticMemory,ABlock*8,8) else begin Result:=nil;SetLength(Result,8);Result:=BlockExchange(2,ABlock,Result);end;
end;
procedure TAcr122TopazSession.WriteByte(const AAddress,AValue:Byte);
var Wire,Data:TBytes;
begin
 RequireActive;if (FModel<>tmTopaz96) or (AAddress>=120) then Invalid;Wire:=HexToBytes('530000');Wire[1]:=AAddress;Wire[2]:=AValue;
 try Data:=Native(Wire);if FAck=tbaStatusOnly then begin if Length(Data)<>0 then Invalid;end
 else if (Length(Data)<>1) or (Data[0]<>AValue) then Invalid;
 except FFailed:=True;raise;end;
end;
procedure TAcr122TopazSession.WriteBlock(const ABlock:Byte;const AData:TBytes);
begin BlockExchange($54,ABlock,AData);end;
end.
