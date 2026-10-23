program CardProtocolCompletionTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
 ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Transport, ERD.Card.Contactless,
 {$IFDEF MSWINDOWS}ERD.Card.Crypto.Windows,{$ELSE}ERD.Card.Crypto.OpenSSL,{$ENDIF}
 ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2, ERD.Card.Contactless.DESFire.Extensions,
 ERD.Card.Contactless.Classic.Access, ERD.Card.Contactless.Workflow.Password,
 ERD.Card.Contactless.Plus, ERD.Card.Contactless.Plus.SL2, ERD.Card.Contactless.Plus.Workflow,
 ERD.Card.Contactless.Workflow.DESFire, ERD.Card.Contactless.Workflow.SDM,
 ERD.Card.Workflow, ERD.Card.Project, ERD.Card.Contactless.Project, DesfirePlus.Vectors;
type
 TFixed = class(TInterfacedObject, ICardAesProvider)
   function EncryptCbc(const K,V,D: TBytes): TBytes;
   function DecryptCbc(const K,V,D: TBytes): TBytes;
   function RandomBytes(const N: Integer): TBytes;
 end;
 TWire = class(TInterfacedObject, ICardTransport, ICardTransaction, IMifarePlusSl2Session)
   Pairs: TExtendedPairs;
   Calls,Begins,Ends,Writes,FailAt,CorruptAt: Integer;
   Active,EndFails,WrongUid: Boolean;
   function Exchange(const Command: TBytes): TBytes;
   procedure BeginTransaction;
   procedure EndTransaction;
   function BeginSession: TBytes;
   function ExchangeNative(const ACommand: TBytes): TBytes;
   procedure AuthenticateClassic(const ABlock: Byte; const AKeyType: TMifareClassicKeyType; const AModifiedKey: TBytes);
   function ReadBlock(const ABlock: Byte): TBytes;
   procedure WriteBlock(const ABlock: Byte; const AData: TBytes);
   procedure EndSession;
 end;
 TCardRequest = class
   Seen: Integer;
   Role: TCardWorkflowRole;
   Deny: Boolean;
   procedure Required(Sender: TObject; const ARole: TCardWorkflowRole; var AReady: Boolean);
 end;
 TSl2Keys = class(TInterfacedObject, IPlusSl2WorkflowKeys)
   function GetKeys(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word;
     out AKeyType: TMifareClassicKeyType; out AClassicKey: TBytes): TBytes;
 end;
 TSdm = class(TInterfacedObject, IDesfireSdmWorkflowCard)
   Image: TDesfireSdmSnapshot;
   Writes,Captures: Integer;
   Uncertain: Boolean;
   function Capture(const AAid: Cardinal; const AFile: Byte): TDesfireSdmSnapshot;
   procedure WriteVerified(const AExpected: TDesfireSdmSnapshot; const AData: TBytes);
 end;
var Base,Provider: ICardAesProvider; Checks: Integer;
procedure Check(const V: Boolean; const Message: string);
begin Inc(Checks); if not V then raise Exception.Create(Message); end;
function TFixed.EncryptCbc(const K,V,D: TBytes): TBytes;
begin Result := Base.EncryptCbc(K,V,D); end;
function TFixed.DecryptCbc(const K,V,D: TBytes): TBytes;
begin Result := Base.DecryptCbc(K,V,D); end;
function TFixed.RandomBytes(const N: Integer): TBytes;
begin Check(N=16,'Fresh nonce length'); Result := HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE'); end;
function TWire.Exchange(const Command: TBytes): TBytes;
begin
 Check(Active,'Exclusive transport'); Inc(Calls);
 if (Length(Command)>1) and ((Command[1]=$8D) or (Command[1]=$3D) or (Command[0]=$A0)) then Inc(Writes);
 if Calls=FailAt then raise ECardTransportError.Create('Synthetic lost response.');
 Check(Calls<=Length(Pairs),'No extra commands');
 Check(BytesToHex(Command)=Pairs[Calls-1].Command,'Exact command '+IntToStr(Calls)+' got '+BytesToHex(Command)+' wanted '+Pairs[Calls-1].Command);
 Result := HexToBytes(Pairs[Calls-1].Response);
 if (Calls=CorruptAt) and (Length(Result)>0) then Result[0] := Result[0] xor 1;
end;
procedure TWire.BeginTransaction;
begin Check(not Active,'No overlapping sessions'); Active := True; Inc(Begins); end;
procedure TWire.EndTransaction;
begin Active := False; Inc(Ends); if EndFails then raise ECardTransportError.Create('Synthetic release failure.'); end;
function TWire.BeginSession: TBytes;
begin BeginTransaction; Result := HexToBytes('04112233445566'); if WrongUid then Result[0] := 0; end;
function TWire.ExchangeNative(const ACommand: TBytes): TBytes;
begin Result := Exchange(ACommand); end;
procedure TWire.AuthenticateClassic(const ABlock: Byte; const AKeyType: TMifareClassicKeyType; const AModifiedKey: TBytes);
var Command,Reply: TBytes;
begin
 SetLength(Command,2+Length(AModifiedKey)); Command[0] := $60; if AKeyType=mckB then Command[0] := $61;
 Command[1] := ABlock; Move(AModifiedKey[0],Command[2],Length(AModifiedKey)); Reply := Exchange(Command);
 Check(Length(Reply)=0,'Crypto1 acknowledgement');
end;
function TWire.ReadBlock(const ABlock: Byte): TBytes;
begin Result := Exchange(TBytes.Create($30,ABlock)); end;
procedure TWire.WriteBlock(const ABlock: Byte; const AData: TBytes);
var Command,Reply: TBytes;
begin
 SetLength(Command,18); Command[0] := $A0; Command[1] := ABlock; Move(AData[0],Command[2],16);
 Reply := Exchange(Command); Check(Length(Reply)=0,'Classic write acknowledgement');
end;
procedure TWire.EndSession;
begin EndTransaction; end;
procedure TCardRequest.Required(Sender: TObject; const ARole: TCardWorkflowRole; var AReady: Boolean);
begin Inc(Seen); Role := ARole; AReady := not Deny; end;
function TSl2Keys.GetKeys(const ABlock: Integer; const AWriting: Boolean; out AKeyNumber: Word;
 out AKeyType: TMifareClassicKeyType; out AClassicKey: TBytes): TBytes;
begin
 Check(ABlock=2,'Scoped selected-memory sector keys'); AKeyNumber := $4000; AKeyType := mckA;
 AClassicKey := HexToBytes('A0A1A2A3A4A5'); Result := HexToBytes(StringOfChar('0',32));
end;
function TSdm.Capture(const AAid: Cardinal; const AFile: Byte): TDesfireSdmSnapshot;
begin
 Inc(Captures); Result := TDesfireSdmArchive.Decode(TDesfireSdmArchive.Encode(Image)); Result.Aid := AAid; Result.FileNumber := AFile;
end;
procedure TSdm.WriteVerified(const AExpected: TDesfireSdmSnapshot; const AData: TBytes);
begin
 Inc(Writes); if Uncertain then raise EContactlessWriteUncertain.Create('Synthetic unknown write.');
 Check(BytesEqual(AExpected.Template.Data,Image.Template.Data),'Full target preimage'); Image.Template.Data := CopyBytes(AData);
end;
procedure Configure(const Reader: TDesfireCardReader; const Wire: TWire);
begin
 Reader.Transport := Wire; Reader.CryptoProvider := Provider; Reader.Security := dfsEv2Aes;
 Reader.AuthenticationKey := HexToBytes(StringOfChar('0',32));
end;
procedure MultiTmac;
var Reader: TDesfireCardReader; Wire: TWire; Hold: ICardTransport; Session: IDesfireTransactionMacDataSession;
 Receipt: TDesfireTmacRecord; I,Action,Fault: Integer; Bad: Boolean; Vectors: TExtendedPairs;
begin
 for Action := 0 to 2 do begin
  case Action of 0:Vectors := DfMultiTmacWrite; 1:Vectors := DfMultiTmacBadRights; else Vectors := DfMultiTmacBadReceipt; end;
  for Fault := 0 to Length(Vectors) do begin
   Wire := TWire.Create; Hold := Wire; Wire.Pairs := Vectors; Wire.FailAt := Fault; Reader := TDesfireCardReader.Create(nil);
   try
    Check(Hold<>nil,'Retained transport'); Configure(Reader,Wire); Bad := False;
    try
     Session := Reader.OpenMultiAccessTransactionMacSession(1,1,HexToBytes('04112233445566'),HexToBytes('112233445566778899AABBCCDDEEFF00'),0,True);
     Session.WriteBackup(0,0,HexToBytes('AABBCCDD')); Receipt := Session.CommitTransactionMacVerified;
     Check((Receipt.Counter=1) and Receipt.KeyVerified and Session.VerificationSucceeded,'Complete multi-right TMAC proof');
    except on E: Exception do begin Bad := True; if Wire.Writes>0 then Check(E is EContactlessWriteUncertain,'Dispatched TMAC failure uncertain'); end; end;
    if (Action=0) and (Fault=0) then Check(not Bad,'Multi-right receipt success') else Check(Bad,'No false TMAC completion');
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'TMAC cleanup');
    I := Wire.Calls;
    if Session<>nil then begin try Session.ReadData(0,0,4); except end; end;
    Check(Wire.Calls=I,'No replay after terminal session');
   finally Session := nil; Reader.Free; Hold := nil; end;
  end;
 end;
end;
function SdmImage: TDesfireSdmStoredTemplate;
var I: Integer;
begin
 Result := Default(TDesfireSdmStoredTemplate); Result.Uid := HexToBytes('04112233445566');
 Result.Settings := TDesfireExtensionCodec.DecodeSdmAccessSettings(HexToBytes('00C0FFFF400000010000C1F1E10000000E0000000000140000'));
 SetLength(Result.Data,64); for I := 0 to 63 do Result.Data[I] := Byte(I);
end;
procedure SdmNative;
var Reader: TDesfireCardReader; Wire: TWire; Hold: ICardTransport; Session: IDesfireSdmTemplateManagement;
 Image: TDesfireSdmStoredTemplate; Data: TBytes; Mode,Fault,I: Integer; Bad: Boolean; Vectors: TExtendedPairs;
begin
 for Mode := 0 to 6 do begin
  case Mode of 0:Vectors := DfSdmTemplateRead; 1:Vectors := DfSdmTemplateWrite; 2:Vectors := DfSdmTemplateNoop;
   3:Vectors := DfSdmTemplateBadPreimage; 4:Vectors := DfSdmTemplateBadSettings; 5:Vectors := DfSdmTemplateBadData;
   else Vectors := DfSdmTemplateTmacRejected; end;
  for Fault := 0 to Length(Vectors) do begin
   Wire := TWire.Create; Hold := Wire; Wire.Pairs := Vectors; Wire.FailAt := Fault; Reader := TDesfireCardReader.Create(nil);
   try
    Check(Hold<>nil,'Retained transport'); Configure(Reader,Wire); Reader.MinimumCommunication := dfcPlain; Bad := False;
    Image := SdmImage; Data := CopyBytes(Image.Data); if Mode<>2 then for I := 0 to High(Data) do Data[I] := Byte(I+64);
    try
     Session := Reader.OpenSdmTemplateManagementSession(1);
     if (Mode=0) or (Mode=6) then Image := Session.ReadStoredTemplate(0)
     else Session.WriteStoredTemplateVerified(0,Image,Data);
     Session.Close;
    except on E: Exception do begin Bad := True; if Wire.Writes>0 then Check(E is EContactlessWriteUncertain,'SDM partial write remains uncertain'); end; end;
    if (Mode<=2) and (Fault=0) then Check(not Bad,'Stored SDM success') else Check(Bad,'SDM failure cannot claim completion');
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'SDM cleanup');
   finally Session := nil; Reader.Free; Hold := nil; end;
  end;
 end;
end;
procedure Sl2;
var Reader: TMifarePlusSl2ReaderWriter; Wire: TWire; Hold: IMifarePlusSl2Session; Native: ICardTransport;
 Data,Expected,Modified: TBytes; Result: TMifarePlusSl2TrailerResult; Mode,Fault: Integer; Bad: Boolean; Pairs: TExtendedPairs;
begin
 Pairs := PlusSl2Modifier;
 Modified := TMifarePlusSl2Codec.Modifier(Provider,HexToBytes(StringOfChar('0',32)),HexToBytes('B04D0787C93EE0CC8CACC8E86F16C6FE'),HexToBytes('0102030405060708090A0B0C0D0E0F10'));
 Check(BytesToHex(Modified)=Pairs[0].Response,'Independent modifier equation');
 Check(BytesToHex(TMifarePlusSl2Codec.ModifiedKey(HexToBytes(Pairs[1].Command),Modified))=Pairs[1].Response,'Independent modified sector key');
 for Mode := 0 to 7 do begin
  case Mode of 0:Pairs := PlusSl2Read; 1:Pairs := PlusSl2Write; 2:Pairs := PlusSl2Noop;
   3:Pairs := PlusSl2BadPreimage; 4:Pairs := PlusSl2BadReadback; 5:Pairs := PlusSl2Trailer; 6:Pairs := PlusSl2TrailerWrite; else Pairs := PlusSl2TrailerBothKeys; end;
  for Fault := 0 to Length(Pairs) do begin
   Wire := TWire.Create; Hold := Wire; Wire.Pairs := Pairs; Wire.FailAt := Fault;
   Reader := TMifarePlusSl2ReaderWriter.Create(nil);
   try
    Reader.Session := Hold; Reader.CryptoProvider := Provider; Reader.Key := HexToBytes(StringOfChar('0',32));
    Reader.ClassicKey := HexToBytes('A0A1A2A3A4A5'); Reader.ExpectedUid := HexToBytes('04112233445566'); Bad := False;
    Expected := HexToBytes('000102030405060708090A0B0C0D0E0F');
    Data := HexToBytes('101112131415161718191A1B1C1D1E1F');
    if Mode=6 then Data := HexToBytes('010203040506FF078069101112131415');
    if Mode=7 then Data := HexToBytes('0102030405067F078869101112131415');
    if Mode=2 then Data := Expected; if Mode=3 then Expected[0] := 99;
    try
     case Mode of
      0: Data := Reader.ReadBlock(2);
      5: Data := Reader.ReadSectorTrailer(0);
      6,7: begin
       Result := Reader.WriteSectorTrailerVerified(0,HexToBytes('000000000000FF078069000000000000'),
        Data,True);
       if Mode=6 then Check(Result.KeyAVerified and Result.KeyBReadBackVerified and not Result.KeyBVerified,'Fresh A proof and readable B evidence')
       else Check(Result.KeyAVerified and Result.KeyBVerified and not Result.KeyBReadBackVerified,'Independent fresh A and B authentication proofs');
      end;
      else Reader.WriteBlockVerified(2,Expected,Data);
     end;
    except on E: Exception do begin Bad := True; if Wire.Writes>0 then Check(E is EContactlessWriteUncertain,'SL2 lost write evidence is uncertain'); end; end;
    if (Mode in [0,1,2,5,6,7]) and (Fault=0) then Check(not Bad,'SL2 success') else Check(Bad,'No false SL2 success');
    Check(not Wire.Active and (Wire.Begins=Wire.Ends),'SL2 RF cleanup');
   finally Reader.Free; Hold := nil; end;
  end;
 end;
 Wire := TWire.Create; Native := Wire; Wire.Pairs := PlusSl2Acr122Read; Reader := TMifarePlusSl2ReaderWriter.Create(nil);
 try
  Reader.Session := CreateAcr122PlusSl2Session(Native); Reader.CryptoProvider := Provider;
  Reader.Key := HexToBytes(StringOfChar('0',32)); Reader.ClassicKey := HexToBytes('A0A1A2A3A4A5'); Reader.ExpectedUid := HexToBytes('04112233445566');
  Data := Reader.ReadBlock(2); Check(BytesToHex(Data)='000102030405060708090A0B0C0D0E0F','End-to-end PN532 raw AES to hardware Crypto1');
  Check((Wire.Calls=Length(Wire.Pairs)) and not Wire.Active,'PN532 framing/RF restoration');
 finally Reader.Free; Native := nil; end;
end;
procedure Sl2Guards;
var Wire: TWire; Hold: IMifarePlusSl2Session; Reader: TMifarePlusSl2ReaderWriter;
 Conditions: TClassicAccessConditions; Trailer,Data: TBytes; Code,TrailerCode,Group,Kind,Writing: Integer;
 Allowed,Expected,Bad: Boolean;
begin
 for TrailerCode := 0 to 7 do for Code := 0 to 7 do for Group := 0 to 2 do
  for Kind := 0 to 1 do for Writing := 0 to 1 do begin
   FillChar(Conditions,SizeOf(Conditions),0); Conditions[3] := TrailerCode; Conditions[Group] := Code;
   Trailer := HexToBytes('00000000000000000069000000000000'); Data := TClassicAccessCodec.Encode(Conditions); Move(Data[0],Trailer[6],3);
   Expected := (Code in [0,1,2,4,6]) or ((Kind=1) and (Code in [3,5]));
   if Writing=1 then Expected := Expected and ((Code=0) or ((Kind=1) and (Code in [3,4,6])));
   if (Kind=1) and (TrailerCode in [0,1,2]) then Expected := False;
   Allowed := True;
   try TMifarePlusSl2Codec.CheckDataAccess(Trailer,Group,TMifareClassicKeyType(Kind),Writing=1); except Allowed := False; end;
   Check(Allowed=Expected,'All Classic data ACL/Key B-readable combinations');
  end;
 Check(TMifarePlusSl2Codec.Trailer(mpm2K,31)=127,'2K final trailer');
 Check(TMifarePlusSl2Codec.Trailer(mpm4K,32)=143,'4K high-sector first trailer');
 Check(TMifarePlusSl2Codec.Trailer(mpm4K,39)=255,'4K final trailer');
 for Kind := 0 to 2 do begin
  Wire := TWire.Create; Hold := Wire; Wire.Pairs := PlusSl2Read;
  Reader := TMifarePlusSl2ReaderWriter.Create(nil);
  try
   Reader.Session := Hold; Reader.CryptoProvider := Provider; Reader.Key := HexToBytes(StringOfChar('0',32));
   Reader.ClassicKey := HexToBytes('A0A1A2A3A4A5'); Reader.ExpectedUid := HexToBytes('04112233445566');
   Wire.WrongUid := Kind=0; if Kind=1 then Wire.CorruptAt := 2;
   if Kind=2 then begin Wire.Pairs := PlusSl2Write; Wire.EndFails := True; end;
   Bad := False;
   try
    if Kind=2 then Reader.WriteBlockVerified(2,HexToBytes('000102030405060708090A0B0C0D0E0F'),HexToBytes('101112131415161718191A1B1C1D1E1F'))
    else Data := Reader.ReadBlock(2);
   except on E: Exception do begin Bad := True; if Kind=2 then Check(E is EContactlessWriteUncertain,'Write release failure remains uncertain'); end; end;
   Check(Bad and not Wire.Active,'UID/nonce/release guard cleanup');
   if Kind=0 then Check(Wire.Calls=0,'Wrong UID refuses before sending supplied credentials');
   if Kind=1 then Check(Wire.Calls=2,'Bad AES proof refuses before Crypto1');
  finally Reader.Free; Hold := nil; end;
 end;
end;
procedure NativeAdapters;
var Wire: TWire; Hold: ICardTransport; Sl2Hold: IMifarePlusSl2Session; Reader: TDesfireCardReader;
 Card: IDesfireWorkflowCard; Policy: IDesfireWorkflowSessionPolicy; Session: IDesfireSession;
 Receipt: TDesfireTmacRecord; FilePolicies: TDesfireWorkflowFilePolicies; Definitions: TDesfireWorkflowDefinitions;
 Keys: IPlusSl2WorkflowKeys; Memory: ICardWorkflowMemory; Flow: TProtectedMemoryWorkflow;
 Cleanup: ICardWorkflowCredentialCleanup; Bad: Boolean; Mode,I: Integer;
begin
 for Mode := 0 to 2 do begin
  Wire := TWire.Create; Hold := Wire; Reader := TDesfireCardReader.Create(nil);
  if Mode=0 then Wire.Pairs := DfMultiTmacWrite else Wire.Pairs := DfMultiTmacCaptureClose;
  if Mode=2 then Wire.FailAt := Length(Wire.Pairs);
  try
   Check(Hold<>nil,'Adapter retained transport'); Configure(Reader,Wire);
   Card := TDesfireWorkflowCard.CreateMultiAccessTmac(Reader,1,1,HexToBytes('04112233445566'),
    HexToBytes('112233445566778899AABBCCDDEEFF00'),0,True);
   Reader.Free; Reader := nil; Check(Supports(Card,IDesfireWorkflowSessionPolicy,Policy),'Native profile policy');
   if Mode=0 then begin
    Session := Card.OpenSession(1,dsaFreshTransaction); Session.WriteBackup(0,0,HexToBytes('AABBCCDD'));
    Policy.CommitSession(Session); Receipt := Policy.Receipt; Check(Receipt.KeyVerified and (Receipt.Counter=1),'Workflow TMAC receipt');
    Receipt.Mac[0] := Receipt.Mac[0] xor 1; Check(not BytesEqual(Receipt.Mac,Policy.Receipt.Mac),'Receipt copied ownership');
    I := Wire.Calls; Bad := False;
    try Card.OpenSession(1,dsaFreshTransaction); except Bad := True; end;
    Check(Bad and (Wire.Calls=I),'TMAC write owner single-use');
   end else begin
    Session := Card.OpenSession(1,dsaReadOnly); Check(BytesToHex(Session.ReadData(0,0,4))='01020304','Captured protected data'); Bad := False;
    try Policy.CloseCapture(Session); except Bad := True; end;
    Check(Bad=(Mode=2),'Read capture Abort result'); Check(not Policy.Receipt.KeyVerified,'No receipt invented for read-only capture');
   end;
   Check(not Wire.Active and (Wire.Begins=Wire.Ends),'Frozen native adapter cleanup');
  finally Session := nil; Policy := nil; Card := nil; Reader.Free; Hold := nil; end;
 end;
 Wire := TWire.Create; Hold := Wire; Reader := TDesfireCardReader.Create(nil);
 try
  Configure(Reader,Wire); SetLength(Definitions,1); Definitions[0] := Default(TDesfireFileDefinition);
  Definitions[0].FileNumber := 0; Definitions[0].FileType := dftBackup; Definitions[0].Communication := dfcFull;
  Definitions[0].FileBytes := 4; SetLength(FilePolicies,1); FilePolicies[0].Rights := TDesfireAccessRightSets.Create($0000,$0010);
  Card := TDesfireWorkflowCard.CreateMultiAccess(Reader,FilePolicies); Check(Supports(Card,IDesfireWorkflowSessionPolicy,Policy),'Provisioning policy');
  Bad := False; try Policy.ValidateProvisioning(Definitions,1); except Bad := True; end;
  Check(Bad and (Wire.Calls=0),'Additional unknown key refused before creating application');
  Policy.ValidateProvisioning(Definitions,2); Check(Wire.Calls=0,'Provisioning validates without I/O');
  FilePolicies[0].Rights[1] := $00F0; Policy.ValidateProvisioning(Definitions,2); Check(Wire.Calls=0,'Frozen complete policy');
 finally Policy := nil; Card := nil; Reader.Free; Hold := nil; end;
 Wire := TWire.Create; Sl2Hold := Wire; Wire.Pairs := PlusSl2Read; Keys := TSl2Keys.Create; Flow := TProtectedMemoryWorkflow.Create(nil);
 try
  Memory := CreatePlusSl2WorkflowMemory(Sl2Hold,Provider,mpm2K,Keys,HexToBytes('04112233445566'));
  Flow.PrepareProtectedBackup(Memory,TCardWorkflowAddresses.Create(2)); Check(Flow.Execute=cwsCompleted,'Native SL2 selected-memory backup');
  Check((Wire.Calls=Length(Wire.Pairs)) and (Flow.Snapshot.Layout='PLUS-SL2-0'),'Distinct SL2 archive layout');
  Check(Supports(Memory,ICardWorkflowCredentialCleanup,Cleanup),'Consumable sector credentials');
  Bad := False; try Memory.ReadUnit(2); except Bad := True; end; Check(Bad,'Cleanup prevents reuse of retained credentials');
 finally Flow.Free; Cleanup := nil; Memory := nil; Keys := nil; Sl2Hold := nil; end;
end;
procedure ArchivesAndWorkflow;
var P: TCardProject; Snapshot,RoundTrip: TDesfireSdmSnapshot; Backend: TSdm; Card: IDesfireSdmWorkflowCard;
 Flow: TDesfireSdmTemplateWorkflow; Extended,Decoded: TDesfireWorkflowSnapshot; Multi: TDesfireMultiAccessSettings;
 Text: string; I: Integer; Request: TCardRequest;
begin
 Request := TCardRequest.Create;
 P := TCardProject.Create(nil); Flow := TDesfireSdmTemplateWorkflow.Create(nil); Backend := TSdm.Create; Card := Backend;
 try
  Check(CardWorkflowStateName(cwsNeedsVerification)='Needs verification','Shared verification state is not UID-specific');
  P.NewProject('protocols'); Snapshot := Default(TDesfireSdmSnapshot); Snapshot.Aid := 1; Snapshot.Template := SdmImage;
  TDesfireSdmArchive.PutProject(P,'stored',Snapshot); RoundTrip := TDesfireSdmArchive.GetProject(P,'stored');
  Check(BytesEqual(RoundTrip.Template.Data,Snapshot.Template.Data),'Stored template project roundtrip');
  Backend.Image := RoundTrip; Flow.OnCardRequired := Request.Required; Request.Deny := True;
  Flow.PrepareBackup(Card,1,0); Check((Flow.Execute=cwsCancelled) and (Backend.Captures=0) and (Request.Role=cwrSource),'Denied source refuses before I/O');
  Request.Deny := False; Flow.PrepareBackup(Card,1,0); Check(Flow.Execute=cwsCompleted,'SDM backup workflow');
  for I := 0 to 63 do Snapshot.Template.Data[I] := Byte(I+64);
  Flow.PrepareRestore(Snapshot,Card,1,0,True); Check((Flow.Execute=cwsCompleted) and (Backend.Writes=0) and not Flow.Matches and (Request.Role=cwrTarget),'SDM compare target presentation never writes');
  Flow.PrepareRestore(Snapshot,Card,1,0); Check((Flow.Execute=cwsCompleted) and Flow.Verified and (Backend.Writes=1),'Stored restore verified');
  Snapshot.Template.Data[0] := 1; Backend.Uncertain := True;
  Flow.PrepareRestore(Snapshot,Card,1,0); Check(Flow.Execute=cwsUncertain,'Workflow preserves native uncertainty');
  Extended := Default(TDesfireWorkflowSnapshot); Extended.Aid := 1; Extended.Identity := HexToBytes('04112233445566');
  SetLength(Extended.Files,1); Multi := TDesfireExtensionCodec.MultiAccessSettings(HexToBytes('0183FFFF040000010000'));
  Extended.Files[0].Settings := TDesfireCodec.FileSettings(0,Multi.BaseBytes); Extended.Files[0].Settings.RawBytes := Multi.RawBytes;
  Extended.Files[0].Data := HexToBytes('AABBCCDD'); Text := TDesfireWorkflowArchive.Encode(Extended);
  Check(Copy(Text,1,Length('ERD-DESFIRE 2'))='ERD-DESFIRE 2','Extended archive explicit version');
  Decoded := TDesfireWorkflowArchive.Decode(Text); Check(BytesEqual(Decoded.Files[0].Settings.RawBytes,Multi.RawBytes),'Archive preserves every access tuple');
  TContactlessProjectArtifacts.PutDesfire(P,'extended',Extended); Check(P.Get('extended').Profile='desfire.v2','Typed extended artifact schema');
  Decoded := TContactlessProjectArtifacts.GetDesfire(P,'extended'); Check(BytesEqual(Decoded.Files[0].Data,Extended.Files[0].Data),'Extended project roundtrip');
 finally Flow.Free; P.Free; Request.Free; end;
end;
begin
 try
  {$IFDEF MSWINDOWS}Base := TCardWindowsAesProvider.Create;{$ELSE}Base := TCardOpenSslAesProvider.Create;{$ENDIF}
  Provider := TFixed.Create; MultiTmac; SdmNative; Sl2; Sl2Guards; NativeAdapters; ArchivesAndWorkflow;
  Writeln('PASS: ',Checks,' protocol completion assertions.');
 except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
 Provider := nil; Base := nil;
end.
