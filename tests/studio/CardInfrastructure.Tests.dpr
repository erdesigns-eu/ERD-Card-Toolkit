program CardInfrastructureTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF UNIX}cthreads,{$ENDIF}
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
 ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Session, ERD.Card.Operation, ERD.Card.Workflow,
 ERD.Card.Operation.Executor, ERD.Card.Keys, ERD.Card.Project, ERD.Card.Project.Schema,
 ERD.Card.HID, ERD.Card.HID.Monitor, ERD.Card.HID.Session, ERD.Card.HID.Registry,
 ERD.Card.PCSC.Registry, ERD.Card.PCSC.Api, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks,
 ERD.Card.Contactless.Project, ERD.Card.Contactless.Calypso, ERD.Card.Project.Artifacts,
 ERD.Card.MagStripe.Workflow, ERD.Card.MagStripe.Session, ERD.Card.Ndef, ERD.Card.Ndef.Project,
 ERD.Card.SIM.Data, ERD.Card.SIM.Workflow, ERD.Card.SIM.Project,
 ERD.Card.Memory, ERD.Card.Memory.Project, ERD.Card.Operation.Workflow;
type
 TWire = class(TInterfacedObject, ICardTransport)
   function Exchange(const ACommand: TBytes): TBytes;
 end;
 THid = class(TInterfacedObject, IHidReportDevice)
   Opens,Closes,Reads,Writes: Integer;
   ChangeOnRead,ChangeOnWrite,FailClose: Boolean;
   Manager: TCardSessionManager;
   Id: string;
   function Open(const AWriteAccess: Boolean): THidDeviceInfo;
   procedure Close;
   function Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
   procedure Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
 end;
 TNotifications = class(TInterfacedObject, IHidDeviceNotifications)
   Handler: THidNotification;
   procedure Start(const AHandler: THidNotification);
   procedure Stop;
 end;
 TFactory = class(TInterfacedObject, ICardHidDeviceFactory)
   Device: IHidReportDevice;
   function CreateDevice(const APath: UnicodeString): IHidReportDevice;
 end;
 TStripe = class(TInterfacedObject, IMagStripeDevice)
   Acquires,Releases,Reads,Writes: Integer;
   Manager: TCardSessionManager;
   ChangeOnWrite: Boolean;
   function GetCapabilities: TMagStripeCapabilities;
   procedure Acquire;
   procedure Release;
   function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
   function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
     const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
 end;
 TStatusStripe = class(TStripe, IMagStripeStatusWriter)
   function GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
   function ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
     const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
 end;
 TBinder = class
   Reader: TMagStripeReaderWriter;
   procedure Bind(const ASession: ICardResourceLease; const AWorkflow: TCardWorkflow);
 end;
 TMigration = class(TInterfacedObject, ICardArtifactMigration)
   Target: string;
   Calls: Integer;
   Fail,BadId: Boolean;
   function Convert(const AArtifact: TCardProjectArtifact): TCardProjectArtifact;
 end;
 TJob = class(TInterfacedObject, ICardResourceOperation)
   Calls: Integer;
   function ExecuteResource(const ASession: ICardResourceLease; const ACancellation: ICardCancellation): TCardWorkflowState;
 end;
 TProbe = class(TThread)
   Device: IHidReportDevice;
   Refused: Boolean;
   procedure Execute; override;
 end;
var Checks: Integer;
procedure Check(const Value: Boolean; const Name: string);
begin Inc(Checks); if not Value then raise Exception.Create(Name); end;
function TWire.Exchange(const ACommand: TBytes): TBytes;
begin Result := HexToBytes('9000'); end;
function THid.Open(const AWriteAccess: Boolean): THidDeviceInfo;
begin Inc(Opens); Result := Default(THidDeviceInfo); Result.InputBytes := 2; Result.OutputBytes := 2; Result.FeatureBytes := 2; end;
procedure THid.Close;
begin Inc(Closes); if FailClose then raise EHidError.Create('Synthetic close failure.'); end;
function THid.Receive(const AKind: THidReportKind; const AReportId: Byte; const ATimeoutMs: Cardinal): TBytes;
begin Inc(Reads); if ChangeOnRead then Manager.CardChanged(Id); Result := HexToBytes('0001'); end;
procedure THid.Send(const AKind: THidReportKind; const AReport: TBytes; const ATimeoutMs: Cardinal);
begin Inc(Writes); if ChangeOnWrite then Manager.CardChanged(Id); end;
procedure TNotifications.Start(const AHandler: THidNotification);
begin Handler := AHandler; end;
procedure TNotifications.Stop;
begin Handler := nil; end;
function TFactory.CreateDevice(const APath: UnicodeString): IHidReportDevice;
begin Result := Device; end;
function TStripe.GetCapabilities: TMagStripeCapabilities;
begin Result := Default(TMagStripeCapabilities); Result.ReadTracks := [mstTrack2]; Result.WriteTracks := [mstTrack2]; Result.Coercivities := [mscCurrent]; Result.VerifiedWrite := True; end;
procedure TStripe.Acquire;
begin Inc(Acquires); end;
procedure TStripe.Release;
begin Inc(Releases); end;
function TStripe.Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin Inc(Reads); Result := Default(TMagStripeTracks); Result[mstTrack2] := '1234'; end;
function TStripe.Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
 const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin Inc(Writes); if ChangeOnWrite then Manager.CardChanged('stripe'); Result := AData; end;
function TStatusStripe.GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
begin Result := Default(TMagStripeStatusWriteCapabilities); Result.Selections := [mswsTrack2]; Result.Coercivities := [mscCurrent]; end;
function TStatusStripe.ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
 const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
begin Inc(Writes); if ChangeOnWrite then Manager.CardChanged('stripe'); Result := $30; end;
procedure TBinder.Bind(const ASession: ICardResourceLease; const AWorkflow: TCardWorkflow);
var Device: IMagStripeDevice;
begin
 if (AWorkflow=nil) or not Supports(ASession.Resource,IMagStripeDevice,Device) then raise Exception.Create('Missing stripe capability.');
 Reader.Device := Device;
end;
function TMigration.Convert(const AArtifact: TCardProjectArtifact): TCardProjectArtifact;
begin
 Inc(Calls); if Fail then raise ECardProjectError.Create('Synthetic conversion failure.');
 Result := AArtifact; Result.Data := CopyBytes(AArtifact.Data); Result.Profile := Target;
 if BadId then Result.Id := 'wrong';
end;
function TJob.ExecuteResource(const ASession: ICardResourceLease; const ACancellation: ICardCancellation): TCardWorkflowState;
var Device: IHidReportDevice; Info: THidDeviceInfo; Data: TBytes;
begin
 Inc(Calls);
 if not Supports(ASession.Resource,IHidReportDevice,Device) then raise Exception.Create('Missing typed HID device.');
 Info := Device.Open(False); Data := Device.Receive(hrkInterrupt,0,1); Device.Close;
 if (Info.InputBytes<>2) or (BytesToHex(Data)<>'0001') then raise Exception.Create('Wrong HID data.');
 if ACancellation.Requested then Result := cwsCancelled else Result := cwsCompleted;
end;
procedure TProbe.Execute;
var Data: TBytes;
begin
 try Data := Device.Receive(hrkInterrupt,0,1); if Length(Data)<>2 then raise Exception.Create('Wrong data'); except on E: ECardSessionError do Refused := True; end;
end;
procedure Devices;
var M: TCardSessionManager; H: THid; Native,Hid: IHidReportDevice; Provider: THidSessionProvider;
 ReservedBackend: ICardTransport; Lease: ICardResourceLease; Bad: Boolean; Data: TBytes; Info: THidDeviceInfo; Wire: ICardSessionLease;
 Probe: TProbe; Q: TCardOperationQueue; Executor: TCardOperationExecutor; Job: TJob;
 Operation: ICardResourceOperation; R: TCardOperationResult; I: Integer;
 StripeProvider: TMagStripeSessionProvider; StripeNative: TStripe; Stripe,GuardedStripe: IMagStripeDevice;
 Binder: TBinder; Reader: TMagStripeReaderWriter; Flow: TMagStripeCopyWorkflow;
 Tracks: TMagStripeTracks; Status: IMagStripeStatusWriter;
begin
 M := TCardSessionManager.Create(nil); Provider := THidSessionProvider.Create(nil);
 StripeProvider := TMagStripeSessionProvider.Create(nil); Q := TCardOperationQueue.Create(nil);
 H := THid.Create; Native := H; H.Manager := M; H.Id := 'hid';
 try
  Provider.Device := Native; Provider.RegisterDevice(M,'hid'); Check(H.Opens=0,'Registration opens no HID');
  Bad := False; try Wire := M.Acquire('hid'); except on E: ECardSessionError do Bad := True; end;
  Check(Bad and (H.Opens=0),'Typed device has no fabricated APDU transport');
  Bad := False; try Provider.RegisterDevice(M,'alias'); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Separate registrations of the same HID backend are refused');
  Lease := M.AcquireResource('hid'); Check(H.Opens=1,'Acquire opens HID once');
  ReservedBackend := TWire.Create;
  Bad := False; try M.BindReader('hid',ReservedBackend); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Same registry reserves across types');
  Check(Supports(Lease.Resource,IHidReportDevice,Hid),'Typed HID capability'); Info := Hid.Open(False);
  Check(Info.InputBytes=2,'Copied descriptor');
  Probe := TProbe.Create(True); Probe.Device := Hid;
  try Probe.Start; Probe.WaitFor; Check(Probe.Refused and (H.Reads=0),'Foreign thread cannot dispatch'); finally Probe.Free; end;
  Bad := False; try Hid.Send(hrkInterrupt,HexToBytes('0001'),1); except on E: EHidError do Bad := True; end;
  Check(Bad and (H.Writes=0),'Read-only policy preserved');
  Data := Hid.Receive(hrkInterrupt,0,1); Check(BytesToHex(Data)='0001','Guarded receive'); Hid.Close;
  Lease.Close; Lease.Close; Check(H.Closes=1,'Native close once');
  Bad := False; try Info := Hid.Open(False); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Retained wrapper revoked after close'); Lease := nil; Hid := nil;
  Provider.WriteAccess := True; Provider.RegisterDevice(M,'hid'); Lease := M.AcquireResource('hid');
  Supports(Lease.Resource,IHidReportDevice,Hid); Info := Hid.Open(True); H.ChangeOnWrite := True; Bad := False;
  try Hid.Send(hrkInterrupt,HexToBytes('0001'),1); except on E: EHidSendUncertain do Bad := True; end;
  Check(Bad and (H.Writes=1),'Changed generation after send is uncertain'); Lease.Close; Lease := nil; Hid := nil;
  H.ChangeOnWrite := False;
  Job := TJob.Create; Operation := Job; Q.EnqueueResource('hid-job','hid',Operation);
  Executor := TCardOperationExecutor.Create(nil);
  try
   Executor.Manager := M; Executor.Queue := Q; Executor.Start;
   for I := 1 to 2000 do begin Executor.DispatchResults; if Executor.LastResult.Id='hid-job' then Break; TThread.Sleep(1); end;
   R := Executor.LastResult; Executor.Stop;
   Check((R.State=cwsCompleted) and (R.Id='hid-job') and (Job.Calls=1),'Typed job executes on background worker');
  finally Executor.Free; end;
  StripeNative := TStripe.Create; Stripe := StripeNative; StripeNative.Manager := M;
  StripeProvider.Device := Stripe; StripeProvider.RegisterDevice(M,'stripe'); Check(StripeNative.Acquires=0,'Inactive stripe registration');
  Lease := M.AcquireResource('stripe'); Supports(Lease.Resource,IMagStripeDevice,GuardedStripe);
  Check(not Supports(Lease.Resource,IMagStripeStatusWriter,Status),'Optional status capability not invented');
  GuardedStripe.Acquire; Tracks := GuardedStripe.Read([mstTrack2],1); Check(Tracks[mstTrack2]='1234','Typed stripe read');
  StripeNative.ChangeOnWrite := True; Bad := False;
  try Tracks := GuardedStripe.Write([mstTrack2],Tracks,mscCurrent,1); except on E: EMagStripeWriteUncertain do Bad := True; end;
  Check(Bad and (StripeNative.Writes=1),'Stripe write generation failure remains uncertain'); Lease.Close;
  Check((StripeNative.Acquires=1) and (StripeNative.Releases=1),'Stripe native ownership spans lease');
  Lease := nil; GuardedStripe := nil; StripeNative.ChangeOnWrite := False;
  Reader := TMagStripeReaderWriter.Create(nil); Binder := TBinder.Create; Flow := TMagStripeCopyWorkflow.Create(nil);
  try
   Binder.Reader := Reader; Reader.Device := Stripe; Flow.PrepareCopy(Reader,nil,[mstTrack2]);
   Operation := CreateCardResourceWorkflowOperation(Flow,Binder.Bind);
   Q.EnqueueResource('stripe-workflow','stripe',Operation); Check(Q.ExecuteNext(M,R),'Resource workflow consumed');
   Check((R.State=cwsCompleted) and (Flow.Data[mstTrack2]='1234'),'Concrete existing magstripe workflow bridge');
  finally Operation := nil; Flow.Free; Binder.Free; Reader.Free; end;
  StripeNative := TStatusStripe.Create; Stripe := StripeNative; StripeNative.Manager := M;
  StripeProvider.Device := Stripe; StripeProvider.RegisterDevice(M,'stripe'); Lease := M.AcquireResource('stripe');
  Check(Supports(Lease.Resource,IMagStripeStatusWriter,Status),'Actual optional status interface preserved');
  Supports(Lease.Resource,IMagStripeDevice,GuardedStripe); GuardedStripe.Acquire;
  Check(Status.ProgramStatus([mstTrack2],Tracks,mscCurrent,1)=$30,'Status evidence forwarded without fabricated read-back');
  GuardedStripe.Release; Lease.Close; Lease := nil; GuardedStripe := nil; Status := nil;
  Lease := M.AcquireResource('hid'); Supports(Lease.Resource,IHidReportDevice,Hid); Info := Hid.Open(False);
  H.ChangeOnRead := True; Bad := False;
  try Data := Hid.Receive(hrkInterrupt,0,1); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Generation change refuses received bytes'); Lease.Close; Lease := nil; Hid := nil; H.ChangeOnRead := False;
  Lease := M.AcquireResource('hid'); H.FailClose := True; Bad := False;
  try Lease.Close; except on E: EHidError do Bad := True; end;
  Check(Bad,'Native close failure propagated'); Lease.Close; Lease := nil; H.FailClose := False;
  Bad := False; try Lease := M.AcquireResource('hid'); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Failed device registration quarantined without replay');
 finally
  GuardedStripe := nil; Stripe := nil; Hid := nil; Lease := nil; Operation := nil;
  if Wire<>nil then Wire.Close; Wire := nil; ReservedBackend := nil;
  Q.Free; StripeProvider.Free; Provider.Free; M.Free;
 end;
end;
procedure Inventory;
var M: TCardSessionManager; P: TCardPcscSessionRegistry; Registry: TCardHidSessionRegistry;
 Snapshot: TPcscReaderSnapshot; Wire: ICardSessionLease; Resource: ICardResourceLease;
 Backend: ICardTransport; Hid: IHidReportDevice; H: THid; Notifications: TNotifications;
 Api: IHidDeviceNotifications; Factory: TFactory; FactoryRef: ICardHidDeviceFactory;
 Names: TStringList; Bad: Boolean; Data: TBytes;
begin
 M := TCardSessionManager.Create(nil); P := TCardPcscSessionRegistry.Create(nil);
 Notifications := TNotifications.Create; Api := Notifications;
 Registry := TCardHidSessionRegistry.CreateWithApi(nil,Api);
 H := THid.Create; Hid := H; Factory := TFactory.Create; FactoryRef := Factory; Factory.Device := Hid;
 try
  P.Manager := M; P.ObserveReaderAdded('Reader'); Backend := TWire.Create; M.BindReader('pcsc:Reader',Backend);
  Snapshot := Default(TPcscReaderSnapshot); Snapshot.ReaderName := 'Reader'; Snapshot.State := PcscStatePresent;
  Snapshot.Atr := HexToBytes('3B00'); P.ObserveState(Snapshot); Wire := M.Acquire('pcsc:Reader');
  Snapshot.State := Snapshot.State or PcscStateInUse or PcscStateUnpowered; P.ObserveState(Snapshot);
  Data := Wire.Transport.Exchange(HexToBytes('00')); Check(BytesToHex(Data)='9000','Usage-only event does not invalidate own job');
  Snapshot.Atr := HexToBytes('3B01'); P.ObserveState(Snapshot); Bad := False;
  try Data := Wire.Transport.Exchange(HexToBytes('00')); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'ATR change invalidates card generation');
  P.ObserveReaderRemoved('Reader'); P.ObserveReaderAdded('Reader');
  Bad := False; try M.BindReader('pcsc:Reader',Backend); except on E: ECardSessionError do Bad := True; end;
  Check(Bad,'Reappeared reader waits behind old lease'); Wire.Close; Wire := nil;
  Names := M.ReaderIds; try Check(Names.IndexOf('pcsc:Reader')>=0,'Deferred provider promoted on release'); finally Names.Free; end;
  Registry.Manager := M; Registry.Factory := FactoryRef; Registry.Start;
  Notifications.Handler('path',True); Notifications.Handler('PATH',True); Check(H.Opens=0,'Hotplug never opens hardware');
  Resource := M.AcquireResource('hid:path'); Check(H.Opens=1,'Hotplug resource can be acquired');
  Notifications.Handler('PATH',False); Notifications.Handler('PATH',True); Resource.Close; Resource := nil;
  Resource := M.AcquireResource('hid:path'); Resource.Close; Resource := nil;
  Check((H.Opens=2) and (H.Closes=2),'HID reappearance promoted behind detached lease');
  P.Stop; Registry.Stop; Names := M.ReaderIds; try Check(Names.Count=0,'Stop detaches owned inventory'); finally Names.Free; end;
  Check(not Assigned(Notifications.Handler),'Notification adapter stopped');
 finally Resource := nil; Wire := nil; P.Free; Registry.Free; M.Free; end;
end;
procedure KeysAndSchemas;
var Stream: TMemoryStream; I: Integer;
 Mobib: TMobibSnapshot;
 Keys: TCardKeyProvider; Provider: ICardKeyProvider; Key,Got: TBytes; Bad: Boolean;
 P: TCardProject; Registry: TCardProjectSchemaRegistry; Item: TCardProjectArtifact;
 Step1,Step2: TMigration; First,Second: ICardArtifactMigration; Before: string;
begin
 Keys := TCardKeyProvider.Create(nil); P := TCardProject.Create(nil); Registry := TCardProjectSchemaRegistry.Create(nil);
 try
  Key := HexToBytes('01020304'); Keys.Put('main','desfire',Key); Provider := Keys.Snapshot; Key[0] := 99;
  Got := Provider.Resolve('main','desfire'); Check(Got[0]=1,'Key provider copies input'); Got[0] := 88;
  Got := Provider.Resolve('main','desfire'); Check(Got[0]=1,'Resolved key copy isolation');
  Stream := TMemoryStream.Create;
  try
   Keys.Name := 'ScopedKeys'; Stream.WriteComponent(Keys);
   SetLength(Got,NativeInt(Stream.Size)); Stream.Position := 0; Stream.ReadBuffer(Got[0],Length(Got));
   Check(Pos('01020304',BytesToHex(Got))=0,'DFM component streaming excludes key buffers');
  finally Stream.Free; end;
  Bad := False; try Got := Provider.Resolve('main','sim'); except on E: EArgumentException do Bad := True; end;
  Check(Bad,'Wrong purpose refused'); Keys.Clear; Keys.Free; Keys := nil;
  Got := Provider.Resolve('main','desfire'); Check(Got[0]=1,'Immutable key provider survives component destruction');
  Keys := TCardKeyProvider.Create(nil);
  for I := 1 to 256 do Keys.Put('key'+IntToStr(I),'test',HexToBytes('00'));
  Bad := False; try Keys.Put('overflow','test',HexToBytes('00')); except on E: EArgumentException do Bad := True; end;
  Check(Bad,'Key-entry budget enforced'); Keys.Remove('key1','test'); Keys.Put('replacement','test',HexToBytes('01'));
  Check(BytesToHex(Keys.Snapshot.Resolve('replacement','test'))='01','Removal frees one key slot');
  Bad := False; try Keys.Put('invalid id','test',HexToBytes('00')); except on E: EArgumentException do Bad := True; end;
  Check(Bad,'Invalid scoped identifier refused');
  P.NewProject('schema'); Item := Default(TCardProjectArtifact); Item.Id := 'item'; Item.Profile := 'v1'; Item.Data := HexToBytes('1234'); P.Put(Item);
  Step1 := TMigration.Create; First := Step1; Step1.Target := 'v2';
  Step2 := TMigration.Create; Second := Step2; Step2.Target := 'v3';
  Registry.RegisterMigration('v1','v2',First); Registry.RegisterMigration('v2','v3',Second);
  Before := P.ExportText; Step2.Fail := True; Bad := False;
  try Registry.MigratePath(P,'item',['v2','v3']); except on E: ECardProjectError do Bad := True; end;
  Check(Bad and (Before=P.ExportText),'Failed later migration preserves complete original');
  Step2.Fail := False; Step2.BadId := True; Bad := False;
  try Registry.MigratePath(P,'item',['v2','v3']); except on E: ECardProjectError do Bad := True; end;
  Check(Bad and (Before=P.ExportText),'Wrong migration identity refused'); Step2.BadId := False;
  Registry.MigratePath(P,'item',['v2','v3']); Item := P.Get('item'); Check((Item.Profile='v3') and (BytesToHex(Item.Data)='1234'),'Explicit schema chain');
  Bad := False; try Registry.MigratePath(P,'item',['v1']); except on E: ECardProjectError do Bad := True; end;
  Check(Bad,'No implicit downgrade');
  RegisterContactlessProjectMigrations(Registry);
  TCardProjectArtifacts.PutArchive(P,'mobib','mobib.v1','MOBIB-RECORDS 1'+#10+'T -'+#10+'F 2020 9000 6A83 0 -'+#10+'R 2020 1 1234'+#10);
  Registry.MigratePath(P,'mobib',['mobib.v2']); Mobib := TContactlessProjectArtifacts.GetMobib(P,'mobib');
  Check((Length(Mobib.Files)=1) and (BytesToHex(Mobib.Files[0].Records[0].Data)='1234'),'Native legacy MOBIB archive upgrade preserves records');
  Check(not Mobib.Application.Valid,'Migration does not invent missing application evidence');
 finally Keys.Free; Registry.Free; P.Free; end;
end;
procedure Artifacts;
var P: TCardProject; Msg,Got: TNdefMessage; Sim,SimGot: TSimWorkflowSnapshot;
 Memory,MemoryGot: TMemoryCardSnapshot; Item: TCardProjectArtifact; Bad: Boolean;
begin
 P := TCardProject.Create(nil);
 try
  P.NewProject('families'); SetLength(Msg,1); Msg[0] := TNdefCodec.NewRecord(ntfUnknown,nil,nil,HexToBytes('1234'));
  TNdefProjectArtifacts.Put(P,'ndef',Msg); Got := TNdefProjectArtifacts.Get(P,'ndef');
  Check(BytesToHex(Got[0].Payload)='1234','Typed NDEF roundtrip'); Got[0].Payload[0] := 99;
  Got := TNdefProjectArtifacts.Get(P,'ndef'); Check(Got[0].Payload[0]=$12,'NDEF independent bytes');
  Sim := Default(TSimWorkflowSnapshot); Sim.Kind := swkPhonebook; Sim.Profile := scpGsmSim; Sim.Iccid := '8912345678901234567';
  SetLength(Sim.Files,1); Sim.Files[0].Address := TSimCodec.FileAddress(sfrMasterFile,[$7F10,$6F3A]);
  SetLength(Sim.Files[0].Records,1); Sim.Files[0].Records[0] := TSimCodec.EncodeAdn('ALICE','1234',20);
  TSimProjectArtifacts.Put(P,'sim',Sim); SimGot := TSimProjectArtifacts.Get(P,'sim');
  Check((SimGot.Iccid=Sim.Iccid) and BytesEqual(SimGot.Files[0].Records[0],Sim.Files[0].Records[0]),'Typed SIM roundtrip');
  Memory := Default(TMemoryCardSnapshot); Memory.Model := mcmI2c1Kbit; SetLength(Memory.Data,128); Memory.Data[0] := $AA;
  TContactMemoryProjectArtifacts.Put(P,'contact',Memory); MemoryGot := TContactMemoryProjectArtifacts.Get(P,'contact');
  Check((Length(MemoryGot.Data)=128) and (MemoryGot.Data[0]=$AA),'Typed contact memory roundtrip');
  Item := P.Get('ndef'); Item.Profile := 'ndef.v2'; P.Put(Item); Bad := False;
  try Got := TNdefProjectArtifacts.Get(P,'ndef'); except on E: ECardProjectError do Bad := True; end;
  Check(Bad,'Unknown NDEF schema refused');
 finally P.Free; end;
end;
begin
 try Devices; Inventory; KeysAndSchemas; Artifacts; Writeln('PASS: ',Checks,' infrastructure assertions.');
 except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode := 1; end; end;
end.
