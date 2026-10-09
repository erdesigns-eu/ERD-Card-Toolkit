unit ERD.Card.Events;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}Classes,SysUtils;{$ELSE}System.Classes,System.SysUtils;{$ENDIF}
type
 /// <summary>Invalid event lifecycle, dispatch thread or bounded queue overflow.</summary>
 ECardEventError = class(Exception);
 /// <summary>Owned event payload; implementations copy mutable data and invoke one callback last.</summary>
 ICardQueuedEvent = interface
  ['{3901E99F-7DED-42C4-ABCC-2A2759466999}']
  /// <summary>Invokes the retained callback on the queue creator's thread; may stop/free its component.</summary>
  procedure Invoke;
 end;
 /// <summary>Bounded thread-safe FIFO with creator-thread dispatch and irreversible lifetime invalidation.</summary>
 ICardEventQueue = interface
  ['{A21A47AC-3F84-477B-8B54-7E5B21F5FB44}']
  /// <summary>Retains one owned event; disabled queues discard it without scheduling.</summary>
  /// <param name="AEvent">Non-nil immutable notification payload.</param>
  /// <returns>True only when the caller must schedule a dispatcher; false means already scheduled or disabled.</returns>
  /// <exception cref="ECardEventError">The bounded pending queue is full.</exception>
  function Add(const AEvent: ICardQueuedEvent): Boolean;
  /// <summary>Replaces pending notifications with one terminal failure, making overflow explicitly observable.</summary>
  /// <param name="AEvent">Non-nil terminal error notification.</param>
  /// <returns>True when a new dispatcher must be scheduled.</returns>
  function Replace(const AEvent: ICardQueuedEvent): Boolean;
  /// <summary>Dispatches a finite batch on the creator thread; invalidation inside callbacks discards the rest.</summary>
  /// <remarks>Retain this interface locally while dispatching. Handler exceptions propagate normally.</remarks>
  procedure Dispatch;
  /// <summary>Irreversibly disables delivery and discards pending notifications; safe to repeat.</summary>
  procedure Disable;
 end;
/// <summary>Creates an inactive bounded queue without registering an OS notification or starting a thread.</summary>
/// <param name="AMaxPending">Maximum undelivered payload count, 1..65536.</param>
/// <returns>Retained queue; dispatch belongs to the creating thread.</returns>
function CreateCardEventQueue(const AMaxPending: Integer = 1024): ICardEventQueue;
implementation
{$IFNDEF FPC}uses System.SyncObjs;{$ENDIF}
type
{$IFDEF FPC}
 TQueueLock=TRTLCriticalSection;
{$ELSE}
 TQueueLock=TCriticalSection;
{$ENDIF}
 TCardQueuedEvents = array of ICardQueuedEvent;
 TEventQueue=class(TInterfacedObject,ICardEventQueue)
 private
  FLock:TQueueLock;
  FEvents:TCardQueuedEvents;
  FEnabled,FScheduled:Boolean; FMax:Integer; FThread:NativeUInt;
  procedure Enter;
  procedure Leave;
 public
  constructor Create(const AMax:Integer);
  destructor Destroy;override;
  function Add(const AEvent:ICardQueuedEvent):Boolean;
  function Replace(const AEvent:ICardQueuedEvent):Boolean;
  procedure Dispatch; reintroduce;
  procedure Disable;
 end;
constructor TEventQueue.Create(const AMax:Integer);
begin
 inherited Create;FMax:=AMax;FEnabled:=True;FThread:=NativeUInt(TThread.CurrentThread.ThreadID);
{$IFDEF FPC}InitCriticalSection(FLock);{$ELSE}FLock:=TCriticalSection.Create;{$ENDIF}
end;
destructor TEventQueue.Destroy;
begin
{$IFDEF FPC}DoneCriticalSection(FLock);{$ELSE}FLock.Free;{$ENDIF}
 inherited Destroy;
end;
procedure TEventQueue.Enter;
begin
{$IFDEF FPC}EnterCriticalSection(FLock);{$ELSE}FLock.Enter;{$ENDIF}
end;
procedure TEventQueue.Leave;
begin
{$IFDEF FPC}LeaveCriticalSection(FLock);{$ELSE}FLock.Leave;{$ENDIF}
end;
function TEventQueue.Add(const AEvent:ICardQueuedEvent):Boolean;
var N:Integer;
begin
 Result:=False;if AEvent=nil then raise ECardEventError.Create('An event payload is required.');
 Enter;
 try
  if not FEnabled then Exit;N:=Length(FEvents);
  if N>=FMax then raise ECardEventError.Create('The event queue capacity was exceeded.');
  SetLength(FEvents,N+1);FEvents[N]:=AEvent;Result:=not FScheduled;FScheduled:=True;
 finally Leave;end;
end;
function TEventQueue.Replace(const AEvent:ICardQueuedEvent):Boolean;
begin
 Result:=False;if AEvent=nil then raise ECardEventError.Create('An event payload is required.');
 Enter;
 try if not FEnabled then Exit;FEvents:=nil;SetLength(FEvents,1);FEvents[0]:=AEvent;Result:=not FScheduled;FScheduled:=True;
 finally Leave;end;
end;
procedure TEventQueue.Disable;
begin Enter;try FEnabled:=False;FEvents:=nil;finally Leave;end;end;
procedure TEventQueue.Dispatch;
var Batch:TCardQueuedEvents;I:Integer;Enabled:Boolean;
begin
 if NativeUInt(TThread.CurrentThread.ThreadID)<>FThread then raise ECardEventError.Create('Dispatch belongs to the queue creator thread.');
 Enter;try Batch:=FEvents;FEvents:=nil;FScheduled:=False;finally Leave;end;
 for I:=0 to High(Batch) do begin
  Enter;try Enabled:=FEnabled;finally Leave;end;
  if not Enabled then Exit;Batch[I].Invoke;
 end;
end;
function CreateCardEventQueue(const AMaxPending:Integer):ICardEventQueue;
begin
 if (AMaxPending<1) or (AMaxPending>65536) then raise ECardEventError.Create('Invalid event queue capacity.');
 Result:=TEventQueue.Create(AMaxPending);
end;
end.
