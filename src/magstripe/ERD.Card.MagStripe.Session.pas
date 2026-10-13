unit ERD.Card.MagStripe.Session;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Session, ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks;
type
  /// <summary>Inactive magstripe provider retaining an explicitly configured device, without opening it.</summary>
  TMagStripeSessionProvider = class(TComponent)
  private
    FDevice: IMagStripeDevice;
  public
    /// <summary>Registers a lazy typed device in the common exclusive physical reader namespace.</summary>
    /// <param name="AManager">Non-nil shared session registry.</param>
    /// <param name="AId">Unique physical device identity.</param>
    procedure RegisterDevice(const AManager: TCardSessionManager; const AId: string);
    /// <summary>Retained explicitly configured reader/writer backend; copied into each registration.</summary>
    property Device: IMagStripeDevice read FDevice write FDevice;
  end;
implementation
type
  TStripe = class(TInterfacedObject, IMagStripeDevice)
  public
    Device: IMagStripeDevice;
    Guard: ICardResourceGuard;
    Acquired: Boolean;
    function GetCapabilities: TMagStripeCapabilities;
    procedure Acquire;
    procedure Release;
    function Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
    function Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
  end;
  TStatusStripe = class(TStripe, IMagStripeStatusWriter)
  public
    Status: IMagStripeStatusWriter;
    function GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
    function ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
      const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
  end;
  TConnection = class(TInterfacedObject, ICardResourceConnection)
  public
    Device: IMagStripeDevice;
    Opened: Boolean;
    function Open(const AGuard: ICardResourceGuard): IInterface;
    function Identity: IInterface;
    procedure Close;
  end;
function TStripe.GetCapabilities: TMagStripeCapabilities;
begin
  Guard.BeginCall;
  try Result := Device.GetCapabilities; except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
procedure TStripe.Acquire;
begin
  Guard.BeginCall;
  try
    if Acquired then raise ECardSessionError.Create('Stripe wrapper already acquired.');
    Acquired := True;
  except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
procedure TStripe.Release;
begin
  Guard.BeginCall;
  try Acquired := False; except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
function TStripe.Read(const ATracks: TMagStripeTrackSet; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin
  Guard.BeginCall;
  try
    if not Acquired then raise ECardSessionError.Create('Acquire stripe wrapper first.');
    Result := Device.Read(ATracks,ATimeoutMs);
  except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
function TStripe.Write(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): TMagStripeTracks;
begin
  Guard.BeginCall;
  try
    if not Acquired then raise ECardSessionError.Create('Acquire stripe wrapper first.');
    Result := Device.Write(ATracks,AData,ACoercivity,ATimeoutMs);
  except Guard.CancelCall; raise; end;
  try Guard.EndCall;
  except raise EMagStripeWriteUncertain.Create('Stripe generation changed after programming.'); end;
end;
function TStatusStripe.GetStatusWriteCapabilities: TMagStripeStatusWriteCapabilities;
begin
  Guard.BeginCall;
  try Result := Status.GetStatusWriteCapabilities; except Guard.CancelCall; raise; end;
  Guard.EndCall;
end;
function TStatusStripe.ProgramStatus(const ATracks: TMagStripeTrackSet; const AData: TMagStripeTracks;
  const ACoercivity: TMagStripeCoercivity; const ATimeoutMs: Cardinal): Byte;
begin
  Guard.BeginCall;
  try
    if not Acquired then raise ECardSessionError.Create('Acquire stripe wrapper first.');
    Result := Status.ProgramStatus(ATracks,AData,ACoercivity,ATimeoutMs);
  except Guard.CancelCall; raise; end;
  try Guard.EndCall;
  except raise EMagStripeWriteUncertain.Create('Stripe generation changed after programming.'); end;
end;
function TConnection.Open(const AGuard: ICardResourceGuard): IInterface;
var Wrapper: TStripe; Retained: IMagStripeDevice; Status: IMagStripeStatusWriter;
begin
  if Opened then raise ECardSessionError.Create('Stripe connection already acquired.');
  Device.Acquire; Opened := True;
  try
    if Supports(Device,IMagStripeStatusWriter,Status) then begin
      Wrapper := TStatusStripe.Create; Retained := Wrapper; TStatusStripe(Wrapper).Status := Status;
    end else begin Wrapper := TStripe.Create; Retained := Wrapper; end;
    Wrapper.Device := Device; Wrapper.Guard := AGuard; Result := Retained;
  except try Close; except end; raise; end;
end;
function TConnection.Identity: IInterface;
begin Result := Device; end;
procedure TConnection.Close;
begin
  if not Opened then Exit;
  Opened := False; Device.Release;
end;
procedure TMagStripeSessionProvider.RegisterDevice(const AManager: TCardSessionManager; const AId: string);
var Connection: TConnection; Retained: ICardResourceConnection;
begin
  if (AManager=nil) or (FDevice=nil) then raise ECardSessionError.Create('A manager and stripe device are required.');
  Connection := TConnection.Create; Retained := Connection; Connection.Device := FDevice;
  AManager.BindResourceConnection(AId,Retained);
end;
end.
