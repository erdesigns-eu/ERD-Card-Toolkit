unit ERD.Card.Demo.ReaderEvents;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes,SysUtils,{$ELSE}System.Classes,System.SysUtils,{$ENDIF}
 ERD.Card.PCSC.Api,ERD.Card.PCSC.Monitor,ERD.Card.Demo.Devices;
type
 /// <summary>Main-thread owned reader inventory for a demo's own combobox.</summary>
 /// <param name="ADevices">Independent array of exact PC/SC reader names.</param>
 TCardDemoReaderInventoryEvent=procedure(const ADevices:TCardDemoDevices) of object;
 /// <summary>Main-thread presence or monitor-error text; never starts card I/O.</summary>
 /// <param name="AText">Reader identity and sanitized state description.</param>
 TCardDemoReaderStatusEvent=procedure(const AText:string) of object;
 /// <summary>Nonvisual native PC/SC event bridge; each demo retains its own form and DFM.</summary>
 /// <remarks>Main-thread lifecycle. No selected reader, card connection, APDU or application polling.</remarks>
 TCardDemoReaderEvents=class
 private
  FMonitor:TSmartCardMonitor;FDevices:TCardDemoDevices;
  FInventory:TCardDemoReaderInventoryEvent;FStatus:TCardDemoReaderStatusEvent;
  procedure Added(Sender:TObject;const Name:UnicodeString);
  procedure Removed(Sender:TObject;const Name:UnicodeString);
  procedure Inserted(Sender:TObject;const Snapshot:TPcscReaderSnapshot);
  procedure CardRemoved(Sender:TObject;const Snapshot:TPcscReaderSnapshot);
  procedure Failed(Sender:TObject;const Code:Cardinal);
  procedure Configure;procedure Publish;function GetActive:Boolean;
 public
  /// <summary>Creates an inactive native bridge retaining only nonvisual callbacks.</summary>
  /// <param name="AInventory">Inventory consumer; may be nil.</param>
  /// <param name="AStatus">Presence/error consumer; may be nil.</param>
  constructor Create(const AInventory:TCardDemoReaderInventoryEvent;const AStatus:TCardDemoReaderStatusEvent);
  /// <summary>Creates an inactive injectable bridge for deterministic lifecycle tests.</summary>
  /// <param name="AApi">Thread-safe API supporting IPcscMonitorApi.</param>
  /// <param name="AInventory">Inventory consumer; may be nil.</param>
  /// <param name="AStatus">Presence/error consumer; may be nil.</param>
  constructor CreateWithApi(const AApi:IPcscApi;const AInventory:TCardDemoReaderInventoryEvent;const AStatus:TCardDemoReaderStatusEvent);
  /// <summary>Discards queued callbacks and joins observation before the owning form dies.</summary>
  destructor Destroy;override;
  /// <summary>Starts or explicitly restarts observation and publishes an empty initial inventory.</summary>
  procedure Start;
  /// <summary>Stops native observation and invalidates queued callbacks; safe to repeat.</summary>
  procedure Stop;
  /// <summary>True while native observation is active.</summary>
  property Active:Boolean read GetActive;
 end;
implementation
uses ERD.Card.Bytes;
constructor TCardDemoReaderEvents.Create(const AInventory:TCardDemoReaderInventoryEvent;const AStatus:TCardDemoReaderStatusEvent);
begin inherited Create;FInventory:=AInventory;FStatus:=AStatus;FMonitor:=TSmartCardMonitor.Create(nil);Configure;end;
constructor TCardDemoReaderEvents.CreateWithApi(const AApi:IPcscApi;const AInventory:TCardDemoReaderInventoryEvent;const AStatus:TCardDemoReaderStatusEvent);
begin inherited Create;FInventory:=AInventory;FStatus:=AStatus;FMonitor:=TSmartCardMonitor.CreateWithApi(nil,AApi);Configure;end;
procedure TCardDemoReaderEvents.Configure;
begin FMonitor.OnReaderAdded:=Added;FMonitor.OnReaderRemoved:=Removed;FMonitor.OnCardInserted:=Inserted;FMonitor.OnCardRemoved:=CardRemoved;FMonitor.OnError:=Failed;end;
destructor TCardDemoReaderEvents.Destroy;begin FMonitor.Free;inherited Destroy;end;
function TCardDemoReaderEvents.GetActive:Boolean;begin Result:=(FMonitor<>nil) and FMonitor.Active;end;
procedure TCardDemoReaderEvents.Start;
begin FMonitor.Stop;FMonitor.Start;FDevices:=nil;Publish;end;
procedure TCardDemoReaderEvents.Stop;begin FMonitor.Stop;end;
procedure TCardDemoReaderEvents.Publish;
var Owned:TCardDemoDevices;
begin Owned:=Copy(FDevices,0,Length(FDevices));if Assigned(FInventory) then FInventory(Owned);end;
procedure TCardDemoReaderEvents.Added(Sender:TObject;const Name:UnicodeString);
var I:Integer;
begin for I:=0 to High(FDevices) do if FDevices[I].Address=Name then Exit;
 I:=Length(FDevices);SetLength(FDevices,I+1);FDevices[I].Address:=Name;FDevices[I].DisplayName:=Name;Publish;end;
procedure TCardDemoReaderEvents.Removed(Sender:TObject;const Name:UnicodeString);
var I,J:Integer;
begin for I:=0 to High(FDevices) do if FDevices[I].Address=Name then begin
 for J:=I to High(FDevices)-1 do FDevices[J]:=FDevices[J+1];SetLength(FDevices,Length(FDevices)-1);Publish;Exit;end;end;
procedure TCardDemoReaderEvents.Inserted(Sender:TObject;const Snapshot:TPcscReaderSnapshot);
begin if Assigned(FStatus) then FStatus('Card offered: '+string(Snapshot.ReaderName)+'; ATR '+BytesToHex(Snapshot.Atr));end;
procedure TCardDemoReaderEvents.CardRemoved(Sender:TObject;const Snapshot:TPcscReaderSnapshot);
begin if Assigned(FStatus) then FStatus('Card removed: '+string(Snapshot.ReaderName));end;
procedure TCardDemoReaderEvents.Failed(Sender:TObject;const Code:Cardinal);
begin if Assigned(FStatus) then FStatus('Reader events stopped ('+IntToHex(Code,8)+'). Use Refresh devices to restart.');end;
end.
