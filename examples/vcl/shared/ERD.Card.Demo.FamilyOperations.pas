unit ERD.Card.Demo.FamilyOperations;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Families, ERD.Card.Transport,
  ERD.Card.Reader.TWN4, ERD.Card.RFID.Input, ERD.Card.HID;

type
  /// <summary>Explicit hardware boundary for family executors, with injectable scripted implementations.</summary>
  ICardFamilyHardware = interface
    ['{E325621B-AC2C-4B6E-9F7C-C5460AB6E611}']
    /// <summary>Connects the exact named PC/SC reader at the component acquisition boundary.</summary>
    /// <param name="AName">Exact reader name, never auto-selected.</param>
    /// <returns>Retained transport with transaction capability.</returns>
    function AcquireReader(const AName: string): ICardTransport;
    /// <summary>Releases a successfully acquired connection; failures are not retried.</summary>
    procedure ReleaseReader;
    /// <summary>Creates an inactive channel for an explicit PRS USB-CDC port.</summary>
    /// <param name="APort">Exact COM device name.</param>
    /// <returns>Channel whose lifetime is managed by the TWN4 component.</returns>
    function CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
  end;

  /// <summary>Optional separate, caller-selected Calypso SAM connection for native authentication.</summary>
  ICardFamilySamHardware = interface
    ['{E0388894-B101-4C5B-8F74-96A24B2C3AE2}']
    /// <summary>Connects the selected provisioned SAM at the authentication acquisition boundary.</summary>
    /// <param name="AName">Exact PC/SC SAM reader name, distinct from the card reader.</param>
    /// <returns>Retained transport with exclusive transaction capability.</returns>
    function AcquireSam(const AName: string): ICardTransport;
    /// <summary>Releases the separate SAM after authentication or abort; never retries commands.</summary>
    procedure ReleaseSam;
  end;

  /// <summary>Optional injectable Windows HID boundary for descriptor enumeration and inactive device factories.</summary>
  ICardFamilyHidHardware = interface
    ['{C7E94CF9-D5E1-4B0B-A8D6-8C6A55B057CD}']
    /// <summary>Enumerates collection metadata; never selects a device or sends vendor commands.</summary>
    /// <returns>Independent native collection descriptors and exact paths.</returns>
    function HidDevices: THidDevices;
    /// <summary>Creates an inactive channel; the component controls acquisition and release.</summary>
    /// <param name="APath">Explicit selected Unicode device-interface path.</param>
    /// <returns>Retained report device; factory opens no hardware.</returns>
    function HidDevice(const APath: UnicodeString): IHidReportDevice;
  end;

/// <summary>Creates an inactive worker executor for one separately runnable family.</summary>
/// <param name="AFamily">Explicit family matching the request catalog.</param>
/// <param name="AHardware">Optional injected hardware; nil selects native Windows adapters.</param>
/// <returns>Executor that validates component arguments before deferred device acquisition.</returns>
function CreateCardFamilyOperations(const AFamily: TCardDemoFamily;
  const AHardware: ICardFamilyHardware = nil): ICardDemoOperations;

/// <summary>Validates a live-keyboard request and creates an inactive, caller-owned capture component.</summary>
/// <param name="ARequest">RFID keyboard action with exact catalog fields.</param>
/// <returns>Configured component; caller owns Start, Stop, events and Free.</returns>
function CreateCardFamilyRfidCapture(const ARequest: TCardDemoRequest): TRfidKeyboardReader;

implementation

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.MOBIB.Rules, ERD.Card.Contactless.Calypso.SAM, ERD.Card.MOBIB.Subscriptions, ERD.Card.MOBIB.Data, ERD.Card.Contactless.Calypso, ERD.Card.EMV.Data, ERD.Card.EMV.Reader, ERD.Card.EID.Data, ERD.Card.EID.Reader,
  ERD.Card.EID.DocumentReader, ERD.Card.EID.ICAO, ERD.Card.Crypto.EAC, ERD.Card.Crypto.EAC.OpenSSL,
  ERD.Card.EID.Access, ERD.Card.Bytes, ERD.Card.APDU.Catalog, ERD.Card.APDU, ERD.Card.ATR, ERD.Card.ATR.Catalog,
  ERD.Card.TLV, ERD.Card.EMV.Tags, ERD.Card.Ndef, ERD.Card.Ndef.Records,
  ERD.Card.Memory, ERD.Card.Memory.Counter, ERD.Card.Memory.Sle4404,
  ERD.Card.SIM.Data, ERD.Card.SIM.Reader, ERD.Card.Memory.Capabilities, ERD.Card.PCSC.Reader,
  ERD.Card.MagStripe, ERD.Card.MagStripe.Tracks, ERD.Card.MagStripe.MSR206,
  ERD.Card.MagStripe.MagTek, ERD.Card.MagStripe.Serial, ERD.Card.Crypto, ERD.Card.Crypto.DES, ERD.Card.Contactless.UltralightC, ERD.Card.Crypto.Windows, ERD.Card.Contactless.DESFire, ERD.Card.Contactless.DESFire.EV2,
  ERD.Card.Contactless.Raw, ERD.Card.Contactless.ACR122, ERD.Card.Contactless.UID,
  ERD.Card.Contactless.UID.Profiles, ERD.Card.Contactless.UID.USCUID, ERD.Card.Contactless.UID.Partial,
  ERD.Card.Contactless.ISO15693, ERD.Card.Contactless.Type5.Ndef, ERD.Card.Contactless.Type2.Password,
  ERD.Card.Contactless.Topaz, ERD.Card.Contactless.ACR122.Topaz, ERD.Card.Contactless.Type1.Ndef,
  ERD.Card.Contactless.Felica, ERD.Card.Contactless.ACR122.Felica, ERD.Card.Contactless.Type3.Ndef,
  ERD.Card.Contactless.Type2.Ndef, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2, ERD.Card.RFID.HID,
  ERD.Card.Reader.TWN4.Serial, ERD.Card.Demo.Operations;

type
  TDeferredConnection = class(TInterfacedObject, ICardTransport, ICardTransaction,
    ITwn4ByteChannel, ICardAesProvider, ICardDesProvider)
  private
    FHardware: ICardFamilyHardware;
    FSamHardware: ICardFamilySamHardware;
    FName: string;
    FSam, FReaderAcquired: Boolean;
    FTransport: ICardTransport;
    FTransaction: ICardTransaction;
    FChannel: ITwn4ByteChannel;
    FAes: ICardAesProvider;
    FDes: ICardDesProvider;
    procedure Connect;
    procedure Channel;
    function Aes: ICardAesProvider;
    function Des: ICardDesProvider;
  public
    constructor Create(const AHardware: ICardFamilyHardware; const AName: string;
      const ASam: Boolean = False);
    procedure Release;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
    procedure Open;
    procedure Close;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
    function EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
    function RandomBytes(const ACount: Integer): TBytes;
    function TripleDesCbc(const AKey, AIv, AData: TBytes; const AEncrypt: Boolean): TBytes;
  end;
  TNativeHardware = class(TInterfacedObject, ICardFamilyHardware, ICardFamilyHidHardware, ICardFamilySamHardware)
  private FReader, FSamReader: TSmartCardReader;
  public
    function AcquireSam(const AName: string): ICardTransport;
    procedure ReleaseSam;
    function HidDevices: THidDevices;
    function HidDevice(const APath: UnicodeString): IHidReportDevice;
    destructor Destroy; override;
    function AcquireReader(const AName: string): ICardTransport;
    procedure ReleaseReader;
    function CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
  end;
  TFamilyOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
  private
    FFamily: TCardDemoFamily;
    FHardware: ICardFamilyHardware;
    FSamTransport: ICardTransport;
    procedure Execute(const R: TCardDemoRequest; const A: TCardFamilyAction;
      const T: ICardTransport; const C: ITwn4ByteChannel; var D: TCardDemoResult);
  public
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure Fail;
begin raise EArgumentException.Create('Check the explicit action inputs and acknowledgement.'); end;

procedure Wipe(var B: TBytes);
begin if Length(B) > 0 then FillChar(B[0],Length(B),0); B := nil; end;

function DescribeNdef(const Records: TNdefMessage): string;
var I: Integer; T: TNdefText;
begin
  Result := 'Records: '+IntToStr(Length(Records))+sLineBreak;
  for I := 0 to High(Records) do
  begin
    Result := Result+'Record '+IntToStr(I+1)+' TNF '+IntToStr(Ord(Records[I].Tnf))+
      ' type '+BytesToHex(Records[I].RecordType)+' id '+BytesToHex(Records[I].Id)+sLineBreak+
      'Payload: '+BytesToHex(Records[I].Payload)+sLineBreak;
    try
      if TNdefRecords.IsType(Records[I],ntfWellKnown,'T') then
      begin T := TNdefRecords.DecodeText(Records[I]); Result := Result+'Text ('+string(T.Language)+'): '+string(T.Text)+sLineBreak; end
      else if TNdefRecords.IsType(Records[I],ntfWellKnown,'U') then Result := Result+'URI: '+string(TNdefRecords.DecodeUri(Records[I]))+sLineBreak;
    except on E: ENdefError do Result := Result+'RTD interpretation unavailable: '+E.ClassName+sLineBreak; end;
  end;
end;

function MobibFileName(const Id: Word): string;
begin
  case Id of
    $2001: Result := 'Environment';
    $2002: Result := 'Holder';
    $2010: Result := 'Validation events';
    $2020: Result := 'Contracts';
    $2069: Result := 'Counters';
    $2050: Result := 'Contract list';
    $2040: Result := 'Special events';
    $3F1C: Result := 'Extended holder';
  else Result := 'File'; end;
end;

function MobibTransportName(const Code: Byte): string;
begin
  case Code of
    0: Result := 'Metro';
    7: Result := 'Premetro';
    15: Result := 'Bus';
    22: Result := 'Tram';
  else Result := 'Unknown mode (code ' + IntToStr(Code) + ')'; end;
end;

function MobibTime(const Date: TDateTime; const Minutes: Word): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', Date) + Format(' %2.2d:%2.2d', [Minutes div 60, Minutes mod 60]);
end;

function DescribeMobib(const Data: TMobibData; const Subscriptions: TMobibSubscriptions): string;
var Lines: TStringList; I: Integer; S: TMobibSubscription; Counters: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('MOBIB CARD');
    if Data.LayoutMatched then Lines.Add('Data profile: MOBIB 056/001 (matched)')
    else Lines.Add('Data profile: no matching semantic layout');
    if Data.HasNetwork then
    begin
      if Data.CountryCode = 56 then Lines.Add('Country: Belgium (056)')
      else Lines.Add(Format('Country code: %3.3d', [Data.CountryCode]));
      Lines.Add(Format('Network: %3.3d', [Data.NetworkCode]));
    end;
    Lines.Add(''); Lines.Add('HOLDER');
    if Data.Holder.Present then
    begin
      Lines.Add('Name: ' + string(Data.Holder.Name));
      Lines.Add('Cardholder number: ' + string(Data.Holder.Number));
      if Data.Holder.HasBirthDate then Lines.Add('Birth date: ' + FormatDateTime('yyyy-mm-dd', Data.Holder.BirthDate));
      Lines.Add('Gender field: code ' + IntToStr(Data.Holder.GenderCode));
    end
    else Lines.Add('Holder details: not available in the decoded records');
    Lines.Add(''); Lines.Add(Format('CONTRACTS (%d decoded)', [Length(Subscriptions)]));
    if Data.HasContractCount then Lines.Add('Contract list count: ' + IntToStr(Data.ContractCount));
    for I := 0 to High(Subscriptions) do
    begin
      S := Subscriptions[I]; Lines.Add(''); Lines.Add('Contract ' + IntToStr(S.RecordNumber));
      if not S.LayoutMatched then
      begin
        Lines.Add('Unsupported record layout: version ' + IntToStr(S.Version)); Continue;
      end;
      if S.ProductName <> '' then Lines.Add('  Product: ' + S.ProductName)
      else Lines.Add('  Product: unidentified (tariff 0x' + IntToHex(S.Tariff, 4) + ')');
      Lines.Add(Format('  Purchase price: EUR %d.%2.2d', [S.PriceCents div 100, S.PriceCents mod 100]));
      if S.HasSaleDate then Lines.Add('  Purchase date: ' + FormatDateTime('yyyy-mm-dd', S.SaleDate))
      else Lines.Add('  Purchase date: not recorded');
      if S.HasDuration then Lines.Add(Format('  Recorded duration: %d (unit code %d; unit not mapped)', [S.DurationValue, S.DurationUnitCode]));
      if S.HasCounter then
      begin
        Lines.Add(Format('  Associated counter: %d (counter-use code %d)', [S.Counter, S.CounterUse]));
        if S.HasRemainingTrips and (S.ProductName <> '') then Lines.Add('  Remaining trips: ' + IntToStr(S.RemainingTrips));
      end
      else Lines.Add('  Associated counter: not acquired');
    end;
    if Length(Subscriptions) > 0 then Lines.Add('Validity / activation / zones: not available from these decoded contract fields');
    Lines.Add(''); Lines.Add(Format('VALIDATIONS (%d decoded)', [Length(Data.Events)]));
    if Length(Data.Events) = 0 then Lines.Add('No nonempty validation events decoded');
    for I := 0 to High(Data.Events) do
    begin
      Lines.Add(Format('Event %d: %s - %s', [Data.Events[I].RecordNumber,
        MobibTime(Data.Events[I].Date, Data.Events[I].Minutes), MobibTransportName(Data.Events[I].TransportCode)]));
      Lines.Add('  First validation: ' + MobibTime(Data.Events[I].FirstDate, Data.Events[I].FirstMinutes));
      if Data.Events[I].HasLocation then Lines.Add('  Location identifier: ' + IntToStr(Data.Events[I].LocationId));
      if Data.Events[I].TransportCode = 15 then Lines.Add('  Bus route: ' + IntToStr(Data.Events[I].BusRoute));
      Lines.Add('  Recorded coupon/count value: ' + IntToStr(Data.Events[I].CouponCount));
    end;
    Lines.Add(''); Lines.Add(Format('COUNTERS (%d slots)', [Length(Data.Counters)]));
    Counters := '';
    for I := 0 to High(Data.Counters) do
    begin
      if I > 0 then Counters := Counters + '; ';
      Counters := Counters + Format('record %d slot %d = %d',
        [Data.Counters[I].RecordNumber, Data.Counters[I].Slot, Data.Counters[I].Value]);
    end;
    if Counters = '' then Counters := 'No counters acquired';
    Lines.Add(Counters); Lines.Add(''); Lines.Add('ACQUIRED FILES');
    Result := Lines.Text;
  finally Lines.Free; end;
end;

function MobibFileSummary(const FileData: TCalypsoFile): string;
var I, J, EmptyCount: Integer; Empty: Boolean;
begin
  Result := MobibFileName(FileData.LogicalId) + ' (' + IntToHex(FileData.LogicalId, 4) + '): ';
  if FileData.SelectionStatus <> $9000 then
  begin
    case FileData.SelectionStatus of
      $6A82: Result := Result + 'not present';
      $6982, $6985: Result := Result + 'access denied';
    else Result := Result + 'unavailable'; end;
    Result := Result + ' (SW ' + IntToHex(FileData.SelectionStatus, 4) + ')'; Exit;
  end;
  EmptyCount := 0;
  for I := 0 to High(FileData.Records) do
  begin
    Empty := True;
    for J := 0 to High(FileData.Records[I].Data) do
      if FileData.Records[I].Data[J] <> 0 then Empty := False;
    if Empty then Inc(EmptyCount);
  end;
  Result := Result + Format('%d records acquired, %d zero-filled', [Length(FileData.Records), EmptyCount]);
  if FileData.Truncated then Result := Result + '; record limit reached';
  if (FileData.LastRecordStatus <> $0000) and
    (FileData.LastRecordStatus <> $9000) and
    (FileData.LastRecordStatus <> $6A83) then
    Result := Result + '; stopped at SW ' + IntToHex(FileData.LastRecordStatus, 4);
end;

function TryAction(const F: TCardDemoFamily; const R: TCardDemoRequest;
  out Selected: TCardFamilyAction; out ErrorText: UnicodeString): Boolean;
var Catalog: TCardFamilyActions; I, J, Choices: Integer;
begin
  Result := False; Selected := Default(TCardFamilyAction);
  ErrorText := 'Select an action for this demo.';
  if (R.Operation <> cdoFamily) or (R.FamilyName <> CardFamilyName(F)) then Exit;
  Catalog := CardFamilyActions(F);
  if (R.FamilyAction < 0) or (R.FamilyAction >= Length(Catalog)) then Exit;
  Selected := Catalog[R.FamilyAction];
  ErrorText := 'The request fields do not match this action.';
  if (Length(R.Arguments) <> Length(Selected.Fields)) or
    (Length(R.Credentials) <> Length(Selected.Fields)) then Exit;
  ErrorText := 'Confirm the acknowledgement for this action.';
  if Selected.Mutation and not R.MutationAcknowledged then Exit;
  ErrorText := 'Select a reader before running this action.';
  if Selected.Pcsc and (Trim(R.ReaderName) = '') then Exit;
  for I := 0 to High(Selected.Fields) do
  begin
    ErrorText := 'Check the input length for ' + UnicodeString(Selected.Fields[I].LabelText) + '.';
    if Length(R.Arguments[I]) > 262144 then Exit;
    if Selected.Fields[I].Secret then
    begin
      if (R.Arguments[I] <> '') or (Length(R.Credentials[I]) > 64) then Exit;
    end
    else if Length(R.Credentials[I]) <> 0 then Exit;
    if Selected.Fields[I].Choices <> '' then
    begin
      ErrorText := 'Choose ' + UnicodeString(Selected.Fields[I].LabelText) + '.';
      Choices := 1;
      for J := 1 to Length(Selected.Fields[I].Choices) do
        if Selected.Fields[I].Choices[J] = '|' then Inc(Choices);
      if not TryStrToInt(string(R.Arguments[I]),J) then Exit;
      if (J < 0) or (J >= Choices) then Exit;
    end;
  end;
  Result := True; ErrorText := '';
end;

function Action(const F: TCardDemoFamily; const R: TCardDemoRequest): TCardFamilyAction;
var ErrorText: UnicodeString;
begin
  if not TryAction(F, R, Result, ErrorText) then Fail;
end;

function Index(const A: TCardFamilyAction; const Name: string): Integer;
var I: Integer;
begin
  for I := 0 to High(A.Fields) do if A.Fields[I].Name = Name then Exit(I);
  Fail; Result := -1;
end;

function Text(const R: TCardDemoRequest; const A: TCardFamilyAction; const Name: string): UnicodeString;
begin Result := R.Arguments[Index(A,Name)]; end;

function Number(const R: TCardDemoRequest; const A: TCardFamilyAction; const Name: string;
  const Min, Max: Integer): Integer;
begin
  if not TryStrToInt(string(Text(R,A,Name)),Result) then Fail;
  if (Result < Min) or (Result > Max) then Fail;
end;

function Bytes(const R: TCardDemoRequest; const A: TCardFamilyAction; const Name: string): TBytes;
var I: Integer;
begin
  I := Index(A,Name);
  if A.Fields[I].Secret then Result := CopyBytes(R.Credentials[I])
  else Result := HexToBytes(string(R.Arguments[I]));
end;

function SingleByte(const R: TCardDemoRequest; const A: TCardFamilyAction; const Name: string): Byte;
var B: TBytes;
begin B := Bytes(R,A,Name); if Length(B) <> 1 then Fail; Result := B[0]; end;

procedure ConfigureCapture(const K: TRfidKeyboardReader; const R: TCardDemoRequest; const A: TCardFamilyAction);
begin
  K.Encoding := TRfidInputEncoding(Number(R,A,'encoding',0,2));
  K.Terminator := TRfidInputTerminator(Number(R,A,'terminator',0,3));
  K.Prefix := Text(R,A,'prefix'); K.Suffix := Text(R,A,'suffix');
  K.ExpectedCharacters := Number(R,A,'expected',0,128);
  K.InterCharacterTimeoutMs := Number(R,A,'gap',1,60000);
end;

function CreateCardFamilyRfidCapture(const ARequest: TCardDemoRequest): TRfidKeyboardReader;
var A: TCardFamilyAction;
begin
  A := Action(dfRfid,ARequest); if A.Id <> 'keyboard' then Fail;
  Result := TRfidKeyboardReader.Create(nil);
  try ConfigureCapture(Result,ARequest,A); except Result.Free; raise; end;
end;

constructor TDeferredConnection.Create(const AHardware: ICardFamilyHardware;
  const AName: string; const ASam: Boolean);
begin
  inherited Create;
  FHardware := AHardware; FName := AName; FSam := ASam;
end;

procedure TDeferredConnection.Connect;
begin
  if FReaderAcquired then Exit;
  if FSam then
  begin
    if not Supports(FHardware, ICardFamilySamHardware, FSamHardware) then Fail;
    FTransport := FSamHardware.AcquireSam(FName);
  end
  else FTransport := FHardware.AcquireReader(FName);
  FReaderAcquired := True;
  if FTransport = nil then raise ECardTransportError.Create('No card transport returned.');
end;

procedure TDeferredConnection.Channel;
begin
  if FChannel = nil then FChannel := FHardware.CreateTwn4Channel(FName);
  if FChannel = nil then raise ECardTransportError.Create('No reader channel returned.');
end;

procedure TDeferredConnection.Release;
begin
  FAes := nil; FDes := nil; FTransaction := nil; FTransport := nil; FChannel := nil;
  if not FReaderAcquired then Exit;
  FReaderAcquired := False;
  if FSam then FSamHardware.ReleaseSam else FHardware.ReleaseReader;
end;

function TDeferredConnection.Exchange(const ACommand: TBytes): TBytes;
begin
  if FTransport = nil then raise ECardTransportError.Create('Card transaction has not started.');
  Result := FTransport.Exchange(ACommand);
end;

procedure TDeferredConnection.BeginTransaction;
begin
  Connect;
  if not Supports(FTransport, ICardTransaction, FTransaction) then
    raise ECardTransportError.Create('Reader requires transaction support.');
  FTransaction.BeginTransaction;
end;

procedure TDeferredConnection.EndTransaction;
begin
  if FTransaction = nil then raise ECardTransportError.Create('Card transaction has not started.');
  FTransaction.EndTransaction; FTransaction := nil;
end;

procedure TDeferredConnection.Open;
begin Channel; FChannel.Open; end;
procedure TDeferredConnection.Close;
begin if FChannel <> nil then FChannel.Close; end;
procedure TDeferredConnection.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
begin Channel; FChannel.Send(ABytes, ATimeoutMs); end;
function TDeferredConnection.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
begin Channel; Result := FChannel.ReceiveByte(ATimeoutMs); end;
function TDeferredConnection.NowMs: UInt64;
begin Channel; Result := FChannel.NowMs; end;

function TDeferredConnection.Aes: ICardAesProvider;
begin
  Connect;
  if FAes = nil then
    if not Supports(FTransport, ICardAesProvider, FAes) then FAes := TCardWindowsAesProvider.Create;
  Result := FAes;
end;

function TDeferredConnection.Des: ICardDesProvider;
begin
  Connect;
  if FDes = nil then
    if not Supports(FTransport, ICardDesProvider, FDes) then FDes := TCardWindowsAesProvider.Create;
  Result := FDes;
end;

function TDeferredConnection.EncryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result := Aes.EncryptCbc(AKey, AIv, AData); end;
function TDeferredConnection.DecryptCbc(const AKey, AIv, AData: TBytes): TBytes;
begin Result := Aes.DecryptCbc(AKey, AIv, AData); end;
function TDeferredConnection.RandomBytes(const ACount: Integer): TBytes;
begin Result := Aes.RandomBytes(ACount); end;
function TDeferredConnection.TripleDesCbc(const AKey, AIv, AData: TBytes;
  const AEncrypt: Boolean): TBytes;
begin Result := Des.TripleDesCbc(AKey, AIv, AData, AEncrypt); end;

destructor TNativeHardware.Destroy;
begin FSamReader.Free; FReader.Free; inherited Destroy; end;
function TNativeHardware.AcquireSam(const AName: string): ICardTransport;
begin
  if FSamReader <> nil then Fail;
  FSamReader := TSmartCardReader.Create(nil);
  try FSamReader.ReaderName := UnicodeString(AName); FSamReader.Connect; Result := FSamReader.Transport;
  except FreeAndNil(FSamReader); raise; end;
end;
procedure TNativeHardware.ReleaseSam;
begin try if FSamReader <> nil then FSamReader.Disconnect; finally FreeAndNil(FSamReader); end; end;
function TNativeHardware.AcquireReader(const AName: string): ICardTransport;
begin
  if FReader <> nil then Fail;
  FReader := TSmartCardReader.Create(nil);
  try FReader.ReaderName := UnicodeString(AName); FReader.Connect; Result := FReader.Transport;
  except FreeAndNil(FReader); raise; end;
end;
procedure TNativeHardware.ReleaseReader;
begin try if FReader <> nil then FReader.Disconnect; finally FreeAndNil(FReader); end; end;
function TNativeHardware.CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
begin Result := CreateWindowsTwn4CdcChannel(APort); end;

function TlvText(const Node: TTlvNode; const Depth: Integer): string;
var I: Integer;
begin
  Result := StringOfChar(' ',Depth*2) + BytesToHex(Node.Tag) + ' (' + IntToStr(Node.ValueSize) + ' bytes)';
  if not Node.IsConstructed then Result := Result + ': ' + BytesToHex(Node.Value);
  for I := 0 to Node.ChildCount - 1 do Result := Result + sLineBreak + TlvText(Node.Children[I],Depth+1);
end;

procedure Artifact(var D: TCardDemoResult; const Name: string; const Data: TBytes);
var N: Integer;
begin
  if Length(Data) = 0 then Exit; N := Length(D.Artifacts); SetLength(D.Artifacts,N+1);
  D.Artifacts[N].Name := Name; D.Artifacts[N].Data := CopyBytes(Data);
end;

function TNativeHardware.HidDevices: THidDevices;
begin Result := EnumerateWindowsHidDevices; end;
function TNativeHardware.HidDevice(const APath: UnicodeString): IHidReportDevice;
begin Result := CreateWindowsHidReportDevice(APath); end;

function RuleTimestamp(const Value: UnicodeString; out Stamp: TDateTime): Boolean;
var Y,M,D,H,N,S,I: Integer; DatePart,TimePart: TDateTime; V:string;
begin
 Stamp:=0; V:=Trim(string(Value)); Result:=V<>''; if not Result then Exit;
 if (Length(V)<>19) or (V[5]<>'-') or (V[8]<>'-') or (V[11]<>' ') or (V[14]<>':') or (V[17]<>':') then Fail;
 for I:=1 to 19 do if not (I in [5,8,11,14,17]) and not (V[I] in ['0'..'9']) then Fail;
 if not TryStrToInt(Copy(V,1,4),Y) or not TryStrToInt(Copy(V,6,2),M) or not TryStrToInt(Copy(V,9,2),D) or
  not TryStrToInt(Copy(V,12,2),H) or not TryStrToInt(Copy(V,15,2),N) or not TryStrToInt(Copy(V,18,2),S) then Fail;
 if (Y<1900) or (Y>9999) or (M<1) or (M>12) or (D<1) or (D>31) or
  (H<0) or (H>23) or (N<0) or (N>59) or (S<0) or (S>59) then Fail;
 if not TryEncodeDate(Y,M,D,DatePart) or not TryEncodeTime(H,N,S,0,TimePart) then Fail;
 Stamp:=DatePart+TimePart;
end;
function RuleZones(const Value: UnicodeString): TMobibZones;
var List:TStringList; I,N:Integer;
begin
 Result:=nil; if Trim(Value)='' then Exit;
 List:=TStringList.Create;
 try
  List.StrictDelimiter:=True; List.Delimiter:=';'; List.DelimitedText:=string(Value);
  if (List.Count<1) or (List.Count>64) then Fail; SetLength(Result,List.Count);
  for I:=0 to List.Count-1 do begin
   if not TryStrToInt(Trim(List[I]),N) or (N<0) or (N>65535) then Fail;
   Result[I]:=Word(N);
  end;
 finally List.Free; end;
end;
function RuleCheckName(const Value:TMobibRuleCheck):string;
begin
 case Value of mrcNotRequired:Result:='Not required';mrcUnknown:Result:='Unknown';mrcPass:Result:='Pass';mrcFail:Result:='Fail';end;
end;
function RuleReasonName(const Value:TMobibRuleReason):string;
const Names:array[TMobibRuleReason] of string=(
 'Profile mismatch','Clock basis mismatch','Missing activation','Not activated',
 'Missing contract start','Missing first validation','Missing sale date','Missing exclusive end',
 'Missing/unmapped duration','Invalid date window','Before validity start','Expired',
 'Missing contract zones','Missing journey zones','Outside permitted zones','Missing trip counter','No remaining trips');
begin Result:=Names[Value];end;

procedure TFamilyOperations.Execute(const R: TCardDemoRequest; const A: TCardFamilyAction;
  const T: ICardTransport; const C: ITwn4ByteChannel; var D: TCardDemoResult);
var Hid: TUsbHidReaderWriter; HidHardware: ICardFamilyHidHardware; Devices: THidDevices; Path: UnicodeString;
  Mag: TMagStripeReaderWriter; MagTracks: TMagStripeTracks; TrackSet: TMagStripeTrackSet;
  MagReceipt: TMagStripeProgrammingReceipt; Financial: TMagStripeFinancialData; MagPort: string;
  Desfire: TDesfireCardReader; Session: IDesfireSession; Management: IDesfireManagement; ApplicationManagement: IDesfireApplicationManagement; DesManagement: IDesfireDesManagement;
  Definition: TDesfireFileDefinition; Files: TDesfireFiles; Applications: TDesfireApplicationIds;
  Aes: ICardAesProvider; Aid: Cardinal; Settings: TDesfireFileSettings;
  Felica: TFelicaCardReader; Type3: TType3NdefCardReader; FelicaReader: IFelicaReader; FelicaTarget: TFelicaTarget; FelicaBlocks: TFelicaBlocks; Type3Snapshot: TType3NdefSnapshot; Type3Attribute: TType3NdefAttribute;
  Topaz: TTopazCardReader; Type1: TType1NdefCardReader; TopazSession: ITopazSession; TopazSnapshot: TTopazSnapshot; Type1Snapshot: TType1NdefSnapshot;
  Type2Configuration: TType2AuthenticationConfiguration;
  Ulc: TUltralightCCardReaderWriter; UlcConfiguration: TUltralightCConfiguration; Des: ICardDesProvider;
  PasswordReader: TType2PasswordCardReader; RawUid: TRawUidProgrammer;
  IsoReader: TIso15693CardReader; Type5: TType5NdefCardReader; IsoSession: IIso15693Session; IsoInfo: TIso15693SystemInfo; IsoSecurity: TIso15693SecurityManager; SlixProtection: TSlix2Protection; StConfiguration: TSt25RfConfiguration; IsoPasswords: TIso15693Passwords; OtherKey: TBytes; Type5Snapshot: TType5NdefSnapshot;
  Rule: TMobibProductRule; Evidence: TMobibRuleEvidence; Assessment: TMobibRuleAssessment;
  Subscription: TMobibSubscription; Reason: TMobibRuleReason; Stamp: TDateTime; HasStamp: Boolean;
  SamCla: Byte;
  SamTransport: ICardTransport; SamProvider: ICalypsoSecureSessionProvider;
  Subscriptions: TMobibSubscriptions;
  ShowMobibRaw: Boolean;
  CalypsoIds: array of Word; ChosenMobibLayout: TMobibLayout; ParsedMobib: TMobibData; Calypso: TCalypsoCardReader; Mobib: TMobibSnapshot; TransitFile: TCalypsoFile;
  Emv: TEMVCardReader; Belgian: TBelgianEIDReader; Icao: TICAODocumentReader;
  Directory: TEmvDirectoryData; Application: TEmvApplicationData; ObjectData: TEmvDataObjectResult; Log: TEmvTransactionLogData;
  Values: TEmvValues; Dol: TEmvDolEntries; Eid: TBelgianEidData; Sections: TEidSections; Document: TIcaoDocumentData; PaceInfos: TIcaoPaceInfos;
  M: TMemoryCardReaderWriter; S: TSleCounterCardReaderWriter; L: TSle4404CardReaderWriter;
  Contact: TContactlessCardReader; T2: TType2NdefCardReader; T4: TType4NdefCardReader;
  CC: TType4CapabilityContainer; T4Snapshot: TType4NdefSnapshot; T2Snapshot: TType2NdefSnapshot; UserMemory: TType2UserMemory;
  Sim: TSimCardReaderWriter; SF: TSimFileAddress; SI: TSimFileInfo; PS: TSimPinStatus;
  SR: TSimRecords; SC: TSimPhonebookEntries; SA: TSimApplications; SD: TSimApplicationInfo; SS: TSimServices; SP: TSimServiceProvider; SE: TSimPhonebookEntry; Parts: TStringList; Changes: TSimRecordChanges; Receipt: TSimCredentialReceipt; Assembled: TSimAssembledSms; SMS: TSimSmsMessage; Linked: TSimLinkedContact; SM: TSimSmsRecord; PB: TSimPhonebookReferences;
  W: TTwn4CardReaderWriter; H: TRfidHidReportReader;
  Layout: TSle4404AccessLayout; Info: TTwn4TagInfo; Identifier: TRfidInputIdentifier;
  Field: TRfidHidAsciiField; P, NewP, Data, Key, Id, Wire: TBytes;
  Model: TMemoryCardModel; Cap: TAcsMemoryCapabilities; Sec: TMemoryCardSecurityStatus;
  Snapshot: TMemoryCardSnapshot; Ndef: TNdefMessage; Doc: TTlvDocument; Atr: TAtrInfo;
  Catalog: TAtrCatalog; Matches: TAtrCatalogMatches; TagHints: TEmvTagDescriptions;
  InstructionHints: TApduInstructionDescriptions; StatusHints: TApduStatusDescriptions;
  Apdu: TApduCommand; Response: TApduResponse; Lines: TStringList; I, J, N, Address, Count: Integer; TagId: Cardinal;
  Basic: TCardDemoRequest; Output: string;
begin
  P := nil; NewP := nil; Key := nil; Wire := nil; Output := '';
  try
    case FFamily of
      dfTools:
      begin
        if (A.Id = 'readers') or (A.Id = 'status') then
        begin
          Basic := Default(TCardDemoRequest); Basic.ReaderName := R.ReaderName;
          if A.Id = 'readers' then Basic.Operation := cdoReaders else Basic.Operation := cdoReaderStatus;
          CreateCardDemoOperations.Run(Basic,D); Exit;
        end;
        Data := Bytes(R,A,'hex');
        if A.Id = 'apdu' then
        begin Apdu := TApduCodec.DecodeCommand(Data);
          Output := 'CLA=' + IntToHex(Apdu.CLA,2) + ' INS=' + IntToHex(Apdu.INS,2) + ' P1=' + IntToHex(Apdu.P1,2) + ' P2=' + IntToHex(Apdu.P2,2) + sLineBreak +
            'Data: ' + BytesToHex(Apdu.Data) + sLineBreak +
            'Extended: ' + BoolToStr(Apdu.IsExtended,True) + ' Has Le: ' + BoolToStr(Apdu.HasLe,True) + ' Le: ' + IntToStr(Apdu.Le) + sLineBreak +
            'Encoded: ' + BytesToHex(TApduCodec.EncodeCommand(Apdu));
          InstructionHints := TApduCatalog.FindInstructions(Apdu.INS);
          for I := 0 to High(InstructionHints) do
            Output := Output + sLineBreak + InstructionHints[I].Description + ' (' + InstructionHints[I].Standard + '; CLA/card context applies)';
        end
        else if A.Id = 'response' then
        begin Response := TApduCodec.DecodeResponse(Data);
          Output := 'Status: ' + IntToHex(Response.StatusWord,4) + sLineBreak + 'Data: ' + BytesToHex(Response.Data) +
            sLineBreak + 'Encoded: ' + BytesToHex(TApduCodec.EncodeResponse(Response));
          StatusHints := TApduCatalog.FindStatusDescriptions(Response.StatusWord);
          for I := 0 to High(StatusHints) do
            Output := Output + sLineBreak + StatusHints[I].Description + ' (' + StatusHints[I].Source + ')';
        end
        else if A.Id = 'atr' then
        begin
          Atr := TAtrCodec.Decode(Data); Catalog := CreateDefaultAtrCatalog;
          try Matches := Catalog.FindMatches(Data);
            Output := 'Validated ATR: ' + BytesToHex(Atr.Raw) + sLineBreak + 'Historical: ' + BytesToHex(Atr.HistoricalBytes);
            for I := 0 to 14 do if I in Atr.Protocols then Output := Output + sLineBreak + 'Advertised protocol T=' + IntToStr(I);
            Output := Output + sLineBreak + 'TCK present and validated: ' + BoolToStr(Atr.HasTck,True);
            for I := 0 to High(Matches) do Output := Output + sLineBreak +
              'Hint: ' + Matches[I].Description + ' (' + Matches[I].Source + ')';
          finally Catalog.Free; end;
        end
        else if A.Id = 'tlv' then
        begin Doc := TTlvCodec.Decode(Data);
          try Output := 'Root nodes: ' + IntToStr(Doc.Count) + sLineBreak + 'Encoded: ' + BytesToHex(TTlvCodec.Encode(Doc));
            for I := 0 to Doc.Count - 1 do Output := Output + sLineBreak + TlvText(Doc.Roots[I],0);
          finally Doc.Free; end;
        end
        else if A.Id = 'ndef' then
        begin Ndef := TNdefCodec.Decode(Data); Output := 'Records: ' + IntToStr(Length(Ndef)) + sLineBreak +
          'Encoded: ' + BytesToHex(TNdefCodec.Encode(Ndef)); end
        else if A.Id = 'tag' then
        begin
          if (Length(Data) < 1) or (Length(Data) > 4) then Fail;
          TagId := 0; for I := 0 to High(Data) do TagId := (TagId shl 8) or Data[I];
          TagHints := TEmvTagCatalog.FindDescriptions(TagId);
          if Length(TagHints) = 0 then
            Output := 'No catalog entry for this tag.';
          for I := 0 to High(TagHints) do
            Output := Output + TagHints[I].Name + sLineBreak +
              'Length metadata: ' + IntToStr(TagHints[I].MinLength) + '..' + IntToStr(TagHints[I].MaxLength) +
              sLineBreak + TagHints[I].Source + sLineBreak;
        end else Fail;
      end;
      dfMemory:
      begin
        Cap := TAcsMemoryCapabilityCatalog.ForDialect(TAcsMemoryDialect(Number(R,A,'dialect',0,1)));
        if A.Id = 'capabilities' then
        begin
          Output := 'Implemented read profiles (not detected hardware):';
          for Model := Low(TMemoryCardModel) to High(TMemoryCardModel) do
            if Model in Cap.ReadModels then Output := Output + sLineBreak + TAcsMemoryCapabilityCatalog.ModelName(Model);
          Exit;
        end;
        M := TMemoryCardReaderWriter.Create(nil);
        try
          M.Model := TMemoryCardModel(Number(R,A,'model',0,Ord(High(TMemoryCardModel))));
          M.Dialect := Cap.Dialect; M.Transport := T;
          if (A.Id = 'verify') or (A.Id = 'write') or (A.Id = 'changepin') or (A.Id = 'protect') then
          begin P := Bytes(R,A,'pin'); M.MinimumPinAttempts := Number(R,A,'attempts',1,8); end;
          if A.Id = 'snapshot' then
          begin Snapshot := M.ReadSnapshot; D.Memory := Snapshot; Output := 'Memory: ' + BytesToHex(Snapshot.Data) +
            sLineBreak + 'Protection: ' + BytesToHex(Snapshot.Protection);
            if Snapshot.HasSecurity then Output := Output + sLineBreak + 'Remaining PIN attempts: ' + IntToStr(Snapshot.Security.RemainingAttempts); end
          else if A.Id = 'read' then
          begin D.Memory.Data := M.ReadMemory(Number(R,A,'address',0,131071),Number(R,A,'count',1,131072));
            Output := BytesToHex(D.Memory.Data); end
          else if A.Id = 'verify' then
          begin Sec := M.VerifyPin(P); Output := 'PIN proven. Remaining attempts: ' + IntToStr(Sec.RemainingAttempts); end
          else if A.Id = 'write' then
          begin M.PageSize := TMemoryCardPageSize(Number(R,A,'page',0,4));
            M.WriteMemory(Number(R,A,'address',0,131071),Bytes(R,A,'data'),P);
            D.WriteVerified := True; Output := 'Write verified by independent read-back.'; end
          else if A.Id = 'changepin' then
          begin NewP := Bytes(R,A,'newpin'); M.ChangePin(P,NewP); D.WriteVerified := True;
            Output := 'PIN replacement verified after reset; no credential is displayed.'; end
          else if A.Id = 'protect' then
          begin M.ProtectMemory(Number(R,A,'address',0,1023),Bytes(R,A,'before'),P);
            D.WriteVerified := True; Output := 'Permanent protection independently verified.'; end
          else Fail;
        finally M.Free; end;
      end;
      dfCounter:
      begin
        if A.Id = 'codeframe' then
        begin P := Bytes(R,A,'code'); Wire := TSleCounterCodec.PresentCode(P);
          Output := 'Validated code-presentation command: ' + IntToStr(Length(Wire)) + ' bytes. Credential-bearing bytes are withheld.'; Exit; end;
        S := TSleCounterCardReaderWriter.Create(nil);
        try
          S.Model := TSleCounterModel(Number(R,A,'countermodel',0,3));
          S.ReadableBytes := Number(R,A,'window',1,256); S.Transport := T;
          if A.Id = 'read' then
          begin Data := S.ReadMemory(Number(R,A,'address',0,255),Number(R,A,'count',1,256)); Output := BytesToHex(Data); end
          else if A.Id = 'write' then
          begin
            S.WriteByte(Number(R,A,'address',0,255),SingleByte(R,A,'value'),
              TSleCounterWriteMode(Number(R,A,'mode',0,3)),Bytes(R,A,'before'),Bytes(R,A,'after'));
            D.WriteVerified := True; Output := 'Complete expected window independently verified.';
          end
          else if A.Id = 'certificate' then
          begin Data := S.ReadCertificate(SingleByte(R,A,'keyselect'),SingleByte(R,A,'clocks'),Bytes(R,A,'challenge'));
            Output := 'Raw certificate (no issuer verification): ' + BytesToHex(Data); end else Fail;
        finally S.Free; end;
      end;
      dfSle4404:
      begin
        L := TSle4404CardReaderWriter.Create(nil);
        try
          L.ReadableBytes := Number(R,A,'window',1,256); L.Transport := T;
          P := Bytes(R,A,'pin'); Layout := L.Layout;
          if Length(P) > 0 then
          begin Layout.UserCounterAddress := Number(R,A,'usercounter',0,255);
            Layout.UserCounterMask := SingleByte(R,A,'usermask'); end;
          L.MinimumUserCodeAttempts := Number(R,A,'attempts',1,4);
          if A.Id = 'scratch' then
          begin Layout.ScratchPadAddress := Number(R,A,'scratchaddress',0,255);
            Layout.ScratchPadBytes := Number(R,A,'scratchbytes',1,256); end;
          if A.Id = 'application' then
          begin Layout.ApplicationAddress := Number(R,A,'applicationaddress',0,255);
            Layout.ApplicationBytes := Number(R,A,'applicationbytes',1,256);
            Layout.MemoryCounterAddress := Number(R,A,'memorycounter',0,248);
            L.MinimumMemoryCodeAttempts := Number(R,A,'memoryattempts',1,64);
            NewP := Bytes(R,A,'memorycode'); end;
          L.Layout := Layout;
          if A.Id = 'read' then
          begin Data := L.ReadMemory(Number(R,A,'address',0,255),Number(R,A,'count',1,256),P); Output := BytesToHex(Data); end
          else if A.Id = 'verify' then
          begin Sec := L.VerifyUserCode(P); Output := 'User code proven. Remaining attempts: ' + IntToStr(Sec.RemainingAttempts); end
          else if A.Id = 'program' then
          begin L.ProgramMemory(Number(R,A,'address',0,255),Bytes(R,A,'before'),Bytes(R,A,'data'),P);
            D.WriteVerified := True; Output := 'One-to-zero programming independently verified.'; end
          else if A.Id = 'scratch' then
          begin L.EraseScratchPad(Bytes(R,A,'before'),P); D.WriteVerified := True; Output := 'Scratchpad erase independently verified.'; end
          else if A.Id = 'application' then
          begin L.EraseApplication(Bytes(R,A,'before'),P,NewP); D.WriteVerified := True; Output := 'Application erase independently verified.'; end
          else Fail;
        finally L.Free; end;
      end;
      dfTwn4:
      begin
        if Trim(string(Text(R,A,'port'))) = '' then Fail;
        W := TTwn4CardReaderWriter.Create(nil);
        try
          W.Channel := C; W.UseCrc := Number(R,A,'crc',0,1) = 1;
          W.TimeoutMs := Number(R,A,'timeout',1,600000);
          if A.Id = 'version' then Output := W.ReadVersion
          else if A.Id = 'tag' then
          begin Info := W.ReadTag; if Info.Found then Output := 'Tag type: ' + IntToHex(Info.TagType,2) +
            ' ID bits: ' + IntToStr(Info.IdBitCount) + sLineBreak + 'Reader-order ID: ' + BytesToHex(Info.Id)
            else Output := 'No tag reported.'; end
          else if (A.Id = 'classicread') or (A.Id = 'classicwrite') then
          begin
            Key := Bytes(R,A,'key'); Id := Bytes(R,A,'id');
            I := Number(R,A,'classicmodel',0,2); Address := Number(R,A,'block',0,255);
            J := Number(R,A,'sector',0,255); N := Number(R,A,'keytype',0,1);
            if A.Id = 'classicread' then
            begin Data := W.ReadClassicBlock(TMifareClassicModel(I),Address,Byte(J),TMifareClassicKeyType(N),Key,Id); Output := BytesToHex(Data); end
            else begin W.WriteClassicDataBlock(TMifareClassicModel(I),Address,Byte(J),TMifareClassicKeyType(N),Key,Id,Bytes(R,A,'before'),Bytes(R,A,'data'));
              D.WriteVerified := True; Output := 'Classic data block independently verified.'; end;
          end
          else if (A.Id = 'type2read') or (A.Id = 'type2write') then
          begin
            I := Number(R,A,'type2model',0,Ord(High(TType2TagModel))); Address := Number(R,A,'page',0,255); Id := Bytes(R,A,'id');
            if A.Id = 'type2read' then
            begin Data := W.ReadType2UserPage(TType2TagModel(I),Address,Id); Output := BytesToHex(Data); end
            else begin W.WriteType2UserPage(TType2TagModel(I),Address,Id,Bytes(R,A,'before'),Bytes(R,A,'data'));
              D.WriteVerified := True; Output := 'Type 2 page independently verified.'; end;
          end else Fail;
        finally W.Free; end;
      end;
      dfMobib:
      begin
        if A.Id = 'rules' then begin
          Rule := Default(TMobibProductRule); Evidence := Default(TMobibRuleEvidence);
          Rule.OperatorId := string(Text(R,A,'operator')); Rule.Source := string(Text(R,A,'source'));
          Rule.CountryCode := 56; Rule.NetworkCode := 1; Rule.MaxVersion := 4;
          Id := Bytes(R,A,'tariff'); if Length(Id) <> 2 then Fail; Rule.Tariff := (Word(Id[0]) shl 8) or Id[1];
          Rule.ClockBasis := TMobibClockBasis(Number(R,A,'clock',0,1));
          Rule.ActivationSource := TMobibActivationSource(Number(R,A,'activation',0,3));
          Rule.DurationUnit := TMobibDurationUnit(Number(R,A,'duration',0,5)+1);
          Rule.DurationAmount := Cardinal(Number(R,A,'amount',0,1000000));
          Rule.EndFromMidnight := Number(R,A,'midnight',0,1)=1;
          if Trim(Text(R,A,'zones'))='*' then Rule.ZoneMode := mzmUnrestricted
          else if Trim(Text(R,A,'zones'))='' then Rule.ZoneMode := mzmContractSet
          else begin Rule.ZoneMode := mzmPolicySet; Rule.Zones := RuleZones(Text(R,A,'zones')); end;
          Rule.RequireRemainingTrip := Number(R,A,'requiretrips',0,1)=0;
          Evidence.OperatorId := Rule.OperatorId; Evidence.CountryCode := 56; Evidence.NetworkCode := 1;
          Evidence.ClockBasis := Rule.ClockBasis; if not RuleTimestamp(Text(R,A,'now'),Evidence.Now) then Fail;
          Evidence.ActivationState := TMobibActivationState(Number(R,A,'state',0,2));
          Evidence.HasEnd := RuleTimestamp(Text(R,A,'end'),Evidence.EndTime);
          HasStamp := RuleTimestamp(Text(R,A,'anchor'),Stamp);
          case Rule.ActivationSource of
            mavExplicitStart: begin Evidence.HasStart := HasStamp; Evidence.Start := Stamp; end;
            mavActivation: begin Evidence.HasActivationTime := HasStamp; Evidence.ActivationTime := Stamp; end;
            mavFirstValidation: begin Evidence.HasFirstValidation := HasStamp; Evidence.FirstValidation := Stamp; end;
            mavSaleDate: if HasStamp then Fail;
          end;
          Evidence.JourneyZones := RuleZones(Text(R,A,'journeyzones')); Evidence.HasJourneyZones := Length(Evidence.JourneyZones)>0;
          Count := 0; HasStamp := Trim(Text(R,A,'trips'))<>'';
          if HasStamp then Count := Number(R,A,'trips',0,$FFFFFF);
          Subscription := TMobibSubscriptionCodec.Decode(Bytes(R,A,'contract'),Byte(Number(R,A,'record',1,255)),HasStamp,Cardinal(Count));
          Assessment := TMobibRuleEngine.Evaluate(Rule,Subscription,Evidence);
          case Assessment.Verdict of
            mrvUnknown: Output := 'Unknown under supplied policy';
            mrvEligible: Output := 'Eligible under supplied policy';
            mrvIneligible: Output := 'Ineligible under supplied policy';
          end;
          Output := Output+sLineBreak+'Manual rule source: '+Rule.Source+sLineBreak+'Read-only assessment; no issuer authorization.'+sLineBreak;
          Output := Output+'Profile: '+RuleCheckName(Assessment.Profile)+'; activation: '+RuleCheckName(Assessment.Activation)+'; validity: '+RuleCheckName(Assessment.Validity)+'; zones: '+RuleCheckName(Assessment.Zones)+'; trips: '+RuleCheckName(Assessment.Trips)+sLineBreak;
          if Assessment.HasStart then Output := Output+'Inclusive start: '+FormatDateTime('yyyy-mm-dd hh:nn:ss',Assessment.Start)+sLineBreak;
          if Assessment.HasEnd then Output := Output+'Exclusive end: '+FormatDateTime('yyyy-mm-dd hh:nn:ss',Assessment.EndTime)+sLineBreak;
          for Reason := Low(TMobibRuleReason) to High(TMobibRuleReason) do if Reason in Assessment.Reasons then Output := Output+RuleReasonName(Reason)+sLineBreak;
        end else begin
        ShowMobibRaw := True;
        Calypso := TCalypsoCardReader.Create(nil);
        try
          Calypso.Transport := T; Calypso.Dialect := TCalypsoDialect(Number(R,A,'dialect',0,1));
          Calypso.RecordBytes := Number(R,A,'le',1,256); N := Number(R,A,'limit',1,255);
          if A.Id = 'samfile' then begin
            if (Trim(Text(R,A,'samreader')) = '') or (Text(R,A,'samreader') = R.ReaderName) then Fail;
            if Calypso.RecordBytes > 253 then Fail;
            Id := Bytes(R,A,'serial'); if Length(Id) <> 8 then Fail;
            I := Number(R,A,'revision',0,3); J := Number(R,A,'keyindex',1,3);
            Count := Number(R,A,'kif',1,255); Address := Number(R,A,'kvc',1,255);
            if Number(R,A,'samclass',0,1) = 0 then SamCla := $80 else SamCla := $94;
            if ((I < 2) and (Calypso.Dialect <> cdLegacy94)) or ((I >= 2) and (Calypso.Dialect <> cdIso00)) then Fail;
            SamTransport := FSamTransport; if SamTransport = nil then Fail;
            SamProvider := TCalypsoSamSessionProvider.Create(SamTransport,TCalypsoSessionRevision(I),Id,J,Count,Address,SamCla);
            Calypso.SecureSessionProvider := SamProvider; Calypso.RequireSecureSession := True;
          end;
          if A.Id = 'snapshot' then begin
            ChosenMobibLayout := TMobibLayout(Number(R,A,'layout',0,1));
            ShowMobibRaw := (ChosenMobibLayout = mlRaw) or (Number(R,A,'raw',0,1) = 1);
            Lines := TStringList.Create;
            try
              Lines.StrictDelimiter := True; Lines.Delimiter := ';'; Lines.DelimitedText := string(Text(R,A,'files'));
              if (Lines.Count < 1) or (Lines.Count > 64) then Fail; SetLength(CalypsoIds,Lines.Count);
              for I := 0 to Lines.Count-1 do begin
                Id := HexToBytes(Trim(Lines[I])); if Length(Id) <> 2 then Fail;
                CalypsoIds[I] := (Word(Id[0]) shl 8) or Id[1];
              end;
              ParsedMobib := TMobibCodec.Decode(Calypso.ReadMobibFiles(CalypsoIds,N),ChosenMobibLayout);
            finally Lines.Free; end;
            Mobib := ParsedMobib.Raw; Artifact(D,'ticketing-select.bin',Mobib.TicketingSelection);
            Subscriptions := TMobibSubscriptionCodec.DecodeSnapshot(ParsedMobib);
            Output := DescribeMobib(ParsedMobib, Subscriptions);
          end else if (A.Id = 'file') or (A.Id = 'samfile') then begin
            Id := Bytes(R,A,'fid'); if (Length(Id) <> 2) or ((Id[0] = 0) and (Id[1] = 0)) then Fail;
            SetLength(Mobib.Files,1); Mobib.Files[0] := Calypso.ReadFile((Word(Id[0]) shl 8) or Id[1],N);
            if A.Id = 'samfile' then Output := 'Mutual session MAC verified by SAM.'+sLineBreak;
          end else Fail;
          for I := 0 to High(Mobib.Files) do begin
            TransitFile := Mobib.Files[I];
            Output := Output + MobibFileSummary(TransitFile) + sLineBreak;
            Artifact(D,'file-'+IntToHex(TransitFile.LogicalId,4)+'-select.bin',TransitFile.SelectionData);
            for J := 0 to High(TransitFile.Records) do begin
              if ShowMobibRaw then Output := Output+'  Record '+IntToStr(TransitFile.Records[J].Number)+': '+BytesToHex(TransitFile.Records[J].Data)+sLineBreak;
              Artifact(D,'file-'+IntToHex(TransitFile.LogicalId,4)+'-record-'+IntToStr(TransitFile.Records[J].Number)+'.bin',TransitFile.Records[J].Data);
            end;
          end;
        finally Calypso.Free; end;
        end;
      end;
      dfEmv:
      begin
        Emv := TEMVCardReader.Create(nil);
        try
          Emv.Transport := T;
          if A.Id = 'discover' then
          begin
            Directory := Emv.DiscoverApplications(TEmvDirectory(Number(R,A,'directory',0,1)));
            Output := 'Directory present '+BoolToStr(Directory.Present,True)+sLineBreak; Artifact(D,'directory-fci.bin',Directory.Fci);
            for I := 0 to High(Directory.Applications) do Output := Output+BytesToHex(Directory.Applications[I].Aid)+' '+string(Directory.Applications[I].LabelText)+sLineBreak;
          end
          else if A.Id = 'dol' then begin Dol := TEmvCodec.DecodeDol(Bytes(R,A,'hex')); for I := 0 to High(Dol) do Output := Output+BytesToHex(Dol[I].Tag)+' bytes '+IntToStr(Dol[I].Size)+sLineBreak; end
          else if A.Id = 'logdecode' then begin Values := TEmvCodec.DecodeLogRecord(Bytes(R,A,'format'),Bytes(R,A,'hex')); for I := 0 to High(Values) do Output := Output+BytesToHex(Values[I].Tag)+'='+BytesToHex(Values[I].Value)+sLineBreak; end
          else
          begin
            Id := Bytes(R,A,'aid'); if (Length(Id) < 5) or (Length(Id) > 16) then Fail;
            if A.Id = 'application' then
            begin
              Values := nil; Lines := TStringList.Create; Parts := nil;
              try
                Parts := TStringList.Create; Lines.StrictDelimiter := True; Lines.Delimiter := ';'; Parts.StrictDelimiter := True; Parts.Delimiter := '=';
                Lines.DelimitedText := string(Text(R,A,'values')); if Lines.Count > 128 then Fail; SetLength(Values,Lines.Count);
                for I := 0 to Lines.Count-1 do begin Parts.DelimitedText := Lines[I]; if Parts.Count <> 2 then Fail; Values[I].Tag := HexToBytes(Parts[0]); Values[I].Value := HexToBytes(Parts[1]); end;
                Data := TEmvCodec.BuildDolData(nil,Values);
                if Number(R,A,'scan',0,1) = 0 then Application := Emv.ReadApplication(Id,Values)
                else Application := Emv.ReadApplicationWithRecordScan(Id,Values,Number(R,A,'firstsfi',1,30),Number(R,A,'lastsfi',1,30),Number(R,A,'firstrecord',1,255),Number(R,A,'lastrecord',1,255));
              finally Parts.Free; Lines.Free; end;
              Output := 'Name '+string(Application.CardholderName)+' PAN '+string(Application.Pan)+' expiry '+string(Application.ExpiryDate)+' IBAN '+string(Application.Iban)+sLineBreak;
              Artifact(D,'application-fci.bin',Application.Fci); Artifact(D,'gpo.bin',Application.Gpo);
              Output := Output+'Records actually read: '+IntToStr(Length(Application.Records))+sLineBreak;
              for I := 0 to High(Application.Records) do
              begin
                Output := Output+'SFI '+IntToStr(Application.Records[I].Sfi)+' record '+IntToStr(Application.Records[I].Number)+': '+BytesToHex(Application.Records[I].RawData)+sLineBreak;
                Artifact(D,'record-'+IntToStr(Application.Records[I].Sfi)+'-'+IntToStr(Application.Records[I].Number)+'.bin',Application.Records[I].RawData);
              end;
              for I := 0 to High(Application.Probes) do
                Output := Output+'Probe SFI '+IntToStr(Application.Probes[I].Sfi)+' record '+IntToStr(Application.Probes[I].Number)+' SW='+IntToHex(Application.Probes[I].StatusWord,4)+sLineBreak;
              for I := 0 to High(Application.Fields) do Output := Output+BytesToHex(Application.Fields[I].Tag)+'='+BytesToHex(Application.Fields[I].Value)+sLineBreak;
            end
            else if A.Id = 'pdol' then begin
              Data := Emv.ReadProcessingOptionsDol(Id); Dol := TEmvCodec.DecodeDol(Data);
              Output := 'PDOL '+BytesToHex(Data)+sLineBreak;
              for I := 0 to High(Dol) do Output := Output+BytesToHex(Dol[I].Tag)+' requires '+IntToStr(Dol[I].Size)+' bytes'+sLineBreak;
              if Length(Dol) = 0 then Output := Output+'No terminal values requested.'+sLineBreak;
              Artifact(D,'pdol.bin',Data);
            end
            else if A.Id = 'getdata' then begin ObjectData := Emv.ReadDataObject(Id,TEmvDataObject(Number(R,A,'object',0,3))); Output := 'Present '+BoolToStr(ObjectData.Present,True)+' status '+IntToHex(ObjectData.StatusWord,4)+' value '+BytesToHex(ObjectData.Value); Artifact(D,'get-data.bin',ObjectData.RawData); end
            else if A.Id = 'log' then begin Log := Emv.ReadTransactionLog(Id); Output := 'Log advertised '+BoolToStr(Log.Supported,True)+sLineBreak; Artifact(D,'log-format.bin',Log.LogFormat); for I := 0 to High(Log.Records) do begin Artifact(D,'log-'+IntToStr(Log.Records[I].Number)+'.bin',Log.Records[I].RawData); for J := 0 to High(Log.Records[I].Fields) do Output := Output+BytesToHex(Log.Records[I].Fields[J].Tag)+'='+BytesToHex(Log.Records[I].Fields[J].Value)+sLineBreak; end; end
            else Fail;
          end;
        finally Emv.Free; end;
      end;
      dfBelgian:
      begin
        case Number(R,A,'sections',0,5) of
          0: Sections := [esIdentity,esAddress,esPhoto,esSignatures,esCertificates];
          1: Sections := [esIdentity]; 2: Sections := [esAddress]; 3: Sections := [esPhoto];
          4: Sections := [esCertificates]; 5: Sections := [esSignatures];
        end;
        Belgian := TBelgianEIDReader.Create(nil);
        try
          Belgian.Transport := T; Eid := Belgian.ReadCard(Sections);
          Output := string(Eid.Identity.GivenNames)+' '+string(Eid.Identity.Surname)+sLineBreak+string(Eid.Address.StreetAndNumber)+sLineBreak+string(Eid.Address.PostalCode)+' '+string(Eid.Address.Municipality);
          Artifact(D,'identity.bin',Eid.Identity.Data.RawData); Artifact(D,'address.bin',Eid.Address.Data.RawData); Artifact(D,'photo.jpg',Eid.Photo);
          Artifact(D,'identity-signature.bin',Eid.IdentitySignature); Artifact(D,'address-signature.bin',Eid.AddressSignature);
          for I := 0 to High(Eid.Certificates) do begin Output := Output+sLineBreak+'Certificate '+IntToStr(Ord(Eid.Certificates[I].Kind))+' state '+IntToStr(Ord(Eid.Certificates[I].State)); Artifact(D,'certificate-'+IntToStr(I)+'.bin',Eid.Certificates[I].RawData); Artifact(D,'certificate-'+IntToStr(I)+'.der',Eid.Certificates[I].DerData); end;
        finally Belgian.Free; end;
      end;
      dfIcao:
      begin
        if A.Id = 'cardaccess' then begin PaceInfos := TIcaoCardAccessCodec.Decode(Bytes(R,A,'hex')); Output := 'Advertised PACE infos: '+IntToStr(Length(PaceInfos)); end
        else
        begin
          Icao := TICAODocumentReader.Create(nil);
          try
            Icao.Transport := T; Icao.Security := TIcaoAccessSecurity(Number(R,A,'security',0,1)); Icao.PasswordKind := TIcaoPasswordKind(Number(R,A,'passwordkind',0,1)); Icao.PaceCurve := TCardPaceCurve(Number(R,A,'curve',0,1));
            P := Bytes(R,A,'password'); Icao.AccessPassword := P; Icao.CryptoProvider := TCardEacOpenSslProvider.Create(string(Text(R,A,'library')));
            Document := Icao.ReadDocument([idsIdentity,idsFace,idsCommon,idsSecurityObject]);
            Output := string(Document.Identity.GivenNames)+' '+string(Document.Identity.Surname)+sLineBreak+'Images '+IntToStr(Length(Document.Biometrics.Images));
            Artifact(D,'cardaccess.bin',Document.CardAccess); Artifact(D,'dg1.bin',Document.DG1); Artifact(D,'dg2.bin',Document.DG2); Artifact(D,'com.bin',Document.Common); Artifact(D,'sod.bin',Document.SecurityObject);
            for I := 0 to High(Document.Biometrics.Images) do begin if Document.Biometrics.Images[I].Format = iffJpeg2000 then Artifact(D,'face-'+IntToStr(I)+'.jp2',Document.Biometrics.Images[I].Data) else Artifact(D,'face-'+IntToStr(I)+'.jpg',Document.Biometrics.Images[I].Data); end;
          finally Icao.Free; end;
        end;
      end;
      dfNativeHid:
      begin
        if A.Id = 'devices' then
        begin
          if not Supports(FHardware,ICardFamilyHidHardware,HidHardware) then HidHardware := TNativeHardware.Create;
          Devices := HidHardware.HidDevices;
          for I := 0 to High(Devices) do Output := Output+string(Devices[I].DevicePath)+sLineBreak+'VID '+IntToHex(Devices[I].VendorId,4)+' PID '+IntToHex(Devices[I].ProductId,4)+' usage '+IntToHex(Devices[I].UsagePage,4)+':'+IntToHex(Devices[I].Usage,4)+' input/output/feature bytes '+IntToStr(Devices[I].InputBytes)+'/'+IntToStr(Devices[I].OutputBytes)+'/'+IntToStr(Devices[I].FeatureBytes)+sLineBreak;
          if Output = '' then Output := 'No metadata-readable HID collections.';
        end
        else
        begin
          Path := Text(R,A,'path'); if (Trim(Path) = '') or (Pos(#0,Path) > 0) then Fail;
          I := Number(R,A,'kind',0,1); N := Number(R,A,'timeout',1,600000);
          if A.Id = 'read' then J := Number(R,A,'reportid',0,255)
          else begin Data := Bytes(R,A,'report'); if (Length(Data) < 1) or (Length(Data) > 4096) then Fail; end;
          if not Supports(FHardware,ICardFamilyHidHardware,HidHardware) then HidHardware := TNativeHardware.Create;
          Hid := TUsbHidReaderWriter.Create(nil);
          try
            Hid.TimeoutMs := N; Hid.Device := HidHardware.HidDevice(Path);
            if A.Id = 'read' then begin Data := Hid.ReadReport(THidReportKind(I),J); Output := BytesToHex(Data); Artifact(D,'hid-report.bin',Data); end
            else if A.Id = 'send' then
            begin
              try Hid.SendReport(THidReportKind(I),Data); except on E: EHidSendUncertain do begin D.WriteUncertain := True; raise; end; end;
              Output := 'HID transfer accepted; card-memory completion requires the documented vendor response. No card read-back proof.';
            end else Fail;
          finally Hid.Free; Wipe(Data); end;
        end;
      end;
      dfMagProfiles:
      begin
        if (A.Id = 'bits') or (A.Id = 'decodebits') then
        begin
          I := Number(R,A,'track',0,2);
          if A.Id = 'bits' then begin Data := TMagStripeTrackCodec.EncodeBits(TMagStripeTrack(I),string(Text(R,A,'payload'))); Output := TMagStripeTrackCodec.DecodeBits(TMagStripeTrack(I),Data)+sLineBreak+BytesToHex(Data); Artifact(D,'track-bits.bin',Data); end
          else Output := TMagStripeTrackCodec.DecodeBits(TMagStripeTrack(I),Bytes(R,A,'hex'));
        end
        else if A.Id = 'financial' then
        begin
          if Number(R,A,'track',0,1) = 0 then Financial := TMagStripeFinancialCodec.DecodeTrack1(string(Text(R,A,'payload')))
          else Financial := TMagStripeFinancialCodec.DecodeTrack2(string(Text(R,A,'payload')));
          Output := Financial.Pan+sLineBreak+Financial.Name;
        end
        else
        begin
          if A.Id = 'program' then TrackSet := [mstTrack1,mstTrack2,mstTrack3]
          else case Number(R,A,'tracks',0,6) of
            0: TrackSet := [mstTrack1]; 1: TrackSet := [mstTrack2]; 2: TrackSet := [mstTrack3];
            3: TrackSet := [mstTrack1,mstTrack2]; 4: TrackSet := [mstTrack1,mstTrack3];
            5: TrackSet := [mstTrack2,mstTrack3]; 6: TrackSet := [mstTrack1,mstTrack2,mstTrack3];
          end;
          if A.Id = 'hid' then MagTracks := TMagTekFrameCodec.DecodeHid(Bytes(R,A,'hex'),TrackSet,Number(R,A,'hasid',0,1) = 1)
          else if A.Id = 'keyboard' then MagTracks := TMagTekFrameCodec.DecodeKeyboard(Bytes(R,A,'hex'),TrackSet)
          else
          begin
            MagPort := string(Text(R,A,'port')); if Trim(MagPort) = '' then Fail;
            I := Number(R,A,'profile',0,1); N := Number(R,A,'timeout',1,600000);
            if A.Id = 'program' then
            begin
              MagTracks[mstTrack1] := string(Text(R,A,'track1')); MagTracks[mstTrack2] := string(Text(R,A,'track2')); MagTracks[mstTrack3] := string(Text(R,A,'track3'));
              for J := 0 to 2 do begin if MagTracks[TMagStripeTrack(J)] = '' then Fail; TMagStripeTrackCodec.ValidatePayload(TMagStripeTrack(J),MagTracks[TMagStripeTrack(J)]); end;
              Count := Number(R,A,'coercivity',0,1);
            end;
            Mag := TMagStripeReaderWriter.Create(nil);
            try
              Mag.Device := TMsr206MagStripeAdapter.Create(CreateWindowsMagStripeSerialPort(MagPort),TMsr206Profile(I)); Mag.TimeoutMs := N;
              if A.Id = 'read' then MagTracks := Mag.ReadTracks(TrackSet)
              else if A.Id = 'program' then
              begin
                if Count = 0 then MagReceipt := Mag.ProgramTracks(TrackSet,MagTracks,mscLow) else MagReceipt := Mag.ProgramTracks(TrackSet,MagTracks,mscHigh);
                Output := 'Device status '+IntToHex(MagReceipt.DeviceStatus,2)+'; host read-back '+BoolToStr(MagReceipt.HostReadBackVerified,True); Exit;
              end else Fail;
            finally Mag.Free; end;
          end;
          for I := 0 to 2 do if TMagStripeTrack(I) in TrackSet then Output := Output+'Track '+IntToStr(I+1)+': '+MagTracks[TMagStripeTrack(I)]+sLineBreak;
        end;
      end;
      dfDesfire:
      begin
        if A.Id = 'decode' then
        begin Settings := TDesfireCodec.FileSettings(Number(R,A,'file',0,31),Bytes(R,A,'hex')); Output := 'File type '+IntToStr(Ord(Settings.FileType))+' communication '+IntToStr(Ord(Settings.Communication))+sLineBreak+'Bytes '+IntToStr(Settings.FileBytes)+' records '+IntToStr(Settings.CurrentRecords); end
        else
        begin
          Desfire := TDesfireCardReader.Create(nil); Session := nil; Management := nil;
          try
            Desfire.Transport := T;
            if A.Id = 'version' then begin Data := Desfire.ReadVersion.RawBytes; Output := BytesToHex(Data); Artifact(D,'version.bin',Data); end
            else if A.Id = 'applications' then begin Applications := Desfire.ReadApplicationIds; for I := 0 to High(Applications) do Output := Output+IntToHex(Applications[I],6)+sLineBreak; end
            else
            begin
              Aid := Cardinal(Number(R,A,'aid',0,$FFFFFF));
              Desfire.Security := TDesfireSecurity(Number(R,A,'security',0,Ord(High(TDesfireSecurity))));
              Desfire.MinimumCommunication := TDesfireCommunication(Number(R,A,'minimum',0,2));
              Key := Bytes(R,A,'key'); Desfire.AuthenticationKey := Key; Desfire.KeyNumber := Number(R,A,'keynumber',0,13);
              NewP := Bytes(R,A,'rekey'); Desfire.ReauthenticationKey := NewP; Desfire.ReauthenticationKeyNumber := Number(R,A,'rekeynumber',0,13); Wipe(NewP);
              if Desfire.Security <> dfsPublic then
              begin
                if not Supports(T,ICardAesProvider,Aes) then Aes := TCardWindowsAesProvider.Create;
                Desfire.CryptoProvider := Aes; Aes := nil;
              end;
              if A.Id = 'files' then begin Files := Desfire.ReadFiles(Aid); for I := 0 to High(Files) do begin Output := Output+'File '+IntToStr(Files[I].FileNumber)+' type '+IntToStr(Ord(Files[I].FileType))+sLineBreak; Artifact(D,'settings-'+IntToStr(Files[I].FileNumber)+'.bin',Files[I].RawBytes); end; end
              else if A.Id = 'read' then begin Data := Desfire.ReadData(Aid,Number(R,A,'file',0,31),Number(R,A,'offset',0,$FFFFFF),Number(R,A,'count',1,$FFFFFF)); Output := BytesToHex(Data); Artifact(D,'data.bin',Data); end
              else if A.Id = 'value' then Output := IntToStr(Desfire.ReadValue(Aid,Number(R,A,'file',0,31)))
              else if A.Id = 'records' then begin Data := Desfire.ReadRecords(Aid,Number(R,A,'file',0,31),Number(R,A,'offset',0,$FFFFFF),Number(R,A,'count',1,$FFFFFF)); Output := BytesToHex(Data); Artifact(D,'records.bin',Data); end
              else if A.Id = 'write' then begin Desfire.WriteData(Aid,Number(R,A,'file',0,31),Number(R,A,'offset',0,$FFFFFF),Bytes(R,A,'data')); D.WriteVerified := True; Output := 'Standard data independently verified.'; end
              else if (A.Id = 'backup') or (A.Id = 'credit') or (A.Id = 'debit') or (A.Id = 'limited') or (A.Id = 'append') or (A.Id = 'clear') then
              begin
                I := Number(R,A,'access',0,1); J := Number(R,A,'finish',0,1); Address := Number(R,A,'file',0,31);
                Data := nil; N := 0; Count := 0;
                if (A.Id = 'backup') or (A.Id = 'append') then begin Data := Bytes(R,A,'data'); if Length(Data) = 0 then Fail; end;
                if A.Id = 'backup' then N := Number(R,A,'offset',0,$FFFFFF);
                if (A.Id = 'credit') or (A.Id = 'debit') or (A.Id = 'limited') then Count := Number(R,A,'amount',1,High(Integer));
                Session := Desfire.OpenSession(Aid,TDesfireSessionAccess(Ord(dsaFreshTransaction)+I));
                if A.Id = 'backup' then Session.WriteBackup(Address,N,Data)
                else if A.Id = 'credit' then Session.Credit(Address,Count)
                else if A.Id = 'debit' then Session.Debit(Address,Count)
                else if A.Id = 'limited' then Session.LimitedCredit(Address,Count)
                else if A.Id = 'append' then Session.AppendRecord(Address,Data)
                else Session.ClearRecords(Address);
                if J = 0 then Session.Commit else Session.Abort;
                D.WriteVerified := Session.VerificationSucceeded;
                Output := 'Transaction outcome '+IntToStr(Ord(Session.Outcome))+'; independent verification '+BoolToStr(D.WriteVerified,True);
              end
              else
              begin
                { Parse all explicit scalar/input fields before acquiring the management session. }
                Address := 0; N := 0; Count := 0; J := 0; Definition := Default(TDesfireFileDefinition);
                if (A.Id = 'createapp') or (A.Id = 'deleteapp') then Address := Number(R,A,'targetaid',1,$FFFFFF);
                if (A.Id = 'keyversion') or (A.Id = 'changekey') or (A.Id = 'changedeskey') then Address := Number(R,A,'targetkey',0,13);
                if (A.Id = 'keysettings') or (A.Id = 'createapp') then N := Number(R,A,'settings',0,255);
                if A.Id = 'createapp' then begin Count := Number(R,A,'keycount',1,14); J := Number(R,A,'applicationkeytype',0,Ord(High(TDesfireApplicationKeyType))); end;
                if (A.Id = 'deletefile') or (A.Id = 'fileaccess') or (A.Id = 'createfile') then Definition.FileNumber := Number(R,A,'file',0,31);
                if (A.Id = 'fileaccess') or (A.Id = 'createfile') then
                begin
                  Definition.Communication := TDesfireCommunication(Number(R,A,'communication',0,2));
                  Definition.ReadKey := Number(R,A,'readkey',0,15); Definition.WriteKey := Number(R,A,'writekey',0,15);
                  Definition.ReadWriteKey := Number(R,A,'readwritekey',0,15); Definition.ChangeKey := Number(R,A,'changekey',0,15);
                end;
                if A.Id = 'changekey' then begin N := Number(R,A,'keyversion',0,255); P := Bytes(R,A,'newkey'); NewP := Bytes(R,A,'oldkey'); if Length(P) <> 16 then Fail; if (Length(NewP) <> 0) and (Length(NewP) <> 16) then Fail; end;
                if A.Id = 'changedeskey' then begin N := Number(R,A,'keyversion',0,255); J := Number(R,A,'oldversion',0,255); P := Bytes(R,A,'newkey'); NewP := Bytes(R,A,'oldkey'); end;
                if A.Id = 'createfile' then
                begin
                  Definition.FileType := TDesfireFileType(Number(R,A,'type',0,4)); Definition.FileBytes := Number(R,A,'filebytes',0,$FFFFFF);
                  Definition.LowerLimit := Number(R,A,'lower',Low(Integer),High(Integer)); Definition.UpperLimit := Number(R,A,'upper',Low(Integer),High(Integer)); Definition.InitialValue := Number(R,A,'initial',Low(Integer),High(Integer));
                  Definition.LimitedCreditEnabled := Number(R,A,'limited',0,1) = 1; Definition.RecordBytes := Number(R,A,'recordbytes',0,$FFFFFF); Definition.MaxRecords := Number(R,A,'maxrecords',0,$FFFFFF);
                end;
                if A.Id = 'changedeskey' then begin DesManagement := Desfire.OpenDesManagementSession(Aid); Management := DesManagement; end
                else Management := Desfire.OpenManagementSession(Aid); Session := Management;
                if A.Id = 'settings' then begin Data := Session.ReadApplicationSettings.RawBytes; Output := BytesToHex(Data); Artifact(D,'application-settings.bin',Data); end
                else if A.Id = 'freememory' then Output := IntToStr(Management.ReadFreeMemory)
                else if A.Id = 'keyversion' then Output := IntToStr(Management.ReadKeyVersion(Address))
                else if A.Id = 'keysettings' then Management.ChangeKeySettings(N)
                else if A.Id = 'fileaccess' then Management.ChangeFileAccess(Definition.FileNumber,Definition.Communication,Definition.ReadKey,Definition.WriteKey,Definition.ReadWriteKey,Definition.ChangeKey)
                else if A.Id = 'changedeskey' then DesManagement.ChangeDesKey(Address,N,J,P,NewP)
                else if A.Id = 'changekey' then Management.ChangeAesKey(Address,N,P,NewP)
                else if A.Id = 'createapp' then begin if not Supports(Management,IDesfireApplicationManagement,ApplicationManagement) then Fail; ApplicationManagement.CreateApplicationWithKeyType(Address,N,Count,TDesfireApplicationKeyType(J)); ApplicationManagement := nil; end
                else if A.Id = 'deleteapp' then Session.DeleteApplication(Address)
                else if A.Id = 'deletefile' then Session.DeleteFile(Definition.FileNumber)
                else if A.Id = 'createfile' then Session.CreateFile(Definition)
                else Fail;
                if Output = '' then begin D.WriteVerified := True; Output := 'Management verification '+BoolToStr(D.WriteVerified,True); end;
              end;
              if Session <> nil then
                try Session.Close; except if D.WriteVerified then D.WriteUncertain := True; raise; end;
            end;
          except
            if Session <> nil then try Session.Close; except end;
            DesManagement := nil; ApplicationManagement := nil; Management := nil; Session := nil; Desfire.Free; raise;
          end;
          DesManagement := nil; ApplicationManagement := nil; Management := nil; Session := nil; Desfire.Free;
        end;
      end;
      dfIso15693, dfSlix2, dfSt25Dv:
      begin
        I:=Number(R,A,'mode',0,1); if (FFamily=dfSlix2) and (I<>0) then Fail;
        IsoSession := TAcr1552Iso15693Session.Create(T,TIso15693AddressMode(Number(R,A,'mode',0,1)),TIso15693ResponseFormat(Number(R,A,'format',0,1)));
        if (A.Id='protection') or (A.Id='configuration') or (A.Id='changepassword') or (A.Id='configure') then begin
          IsoSecurity:=TIso15693SecurityManager.Create(nil);
          try
            IsoSecurity.Session:=IsoSession;
            if A.Id='protection' then begin
              SlixProtection:=IsoSecurity.ReadSlix2Protection;Data:=SlixProtection.Raw;
              Output:='Preimage: '+BytesToHex(Data)+sLineBreak+'Page H starts at block '+IntToStr(SlixProtection.PointerBlock)+
                sLineBreak+'Protection RL/WL/RH/WH: '+IntToHex(SlixProtection.Conditions,2)+
                sLineBreak+'Locks AFI/EAS/DSFID/PPL: '+IntToHex(SlixProtection.LockBits,2)+
                sLineBreak+'Features: '+IntToHex(SlixProtection.Features,8)+' / '+IntToHex(SlixProtection.ExtendedFeatures,8);
              Artifact(D,'protection.bin',Data);
            end else if A.Id='configuration' then begin
              StConfiguration:=IsoSecurity.ReadSt25Configuration;Data:=StConfiguration.Raw;
              Output:='Preimage: '+BytesToHex(Data)+sLineBreak+'Configuration locked: '+BoolToStr(StConfiguration.ConfigurationLocked,True);
              for J:=0 to 3 do Output:=Output+sLineBreak+'Area '+IntToStr(J+1)+': first block '+IntToStr(StConfiguration.Areas[J].FirstBlock)+
                ', count '+IntToStr(StConfiguration.Areas[J].BlockCount)+', password '+IntToStr(StConfiguration.Areas[J].PasswordNumber)+
                ', protection '+IntToStr(StConfiguration.Areas[J].ProtectionCode)+', read needs password '+BoolToStr(StConfiguration.Areas[J].ReadRequiresPassword,True)+
                ', write needs password '+BoolToStr(StConfiguration.Areas[J].WriteRequiresPassword,True)+', write forbidden '+BoolToStr(StConfiguration.Areas[J].WriteForbidden,True);
              Artifact(D,'configuration.bin',Data);
            end else if A.Id='changepassword' then begin
              Key:=Bytes(R,A,'oldpassword');OtherKey:=Bytes(R,A,'newpassword');
              if FFamily=dfSlix2 then IsoSecurity.ChangeSlix2Password(Number(R,A,'identifier',1,2),Key,OtherKey)
              else IsoSecurity.ChangeSt25Password(Number(R,A,'identifier',0,3),Key,OtherKey,Number(R,A,'stablevcc',0,1)=1);
              D.WriteVerified:=True;Output:='Replacement password accepted after RF power-on reset.';
            end else begin
              if FFamily=dfSlix2 then begin
                Key:=Bytes(R,A,'readpassword');
                OtherKey:=Bytes(R,A,'writepassword');
                IsoSecurity.ConfigureSlix2Protection(Key,OtherKey,Bytes(R,A,'expected'),Number(R,A,'pointer',0,78),SingleByte(R,A,'conditions'));
              end else begin
                Key:=Bytes(R,A,'password');
                IsoSecurity.ConfigureSt25Area(Number(R,A,'area',1,4),Key,Bytes(R,A,'expected'),Number(R,A,'identifier',0,3),Number(R,A,'protection',0,3),Number(R,A,'stablevcc',0,1)=1);
              end;
              D.WriteVerified:=True;Output:='RF protection configuration independently verified after reset.';
            end;
          finally
            Wipe(Key);Wipe(OtherKey);IsoSecurity.Free;IsoSession:=nil;
          end;
          Exit;
        end;
        if FFamily<>dfIso15693 then begin
          IsoPasswords:=nil;
          try
            if FFamily=dfSlix2 then begin
              Key:=Bytes(R,A,'readpassword'); OtherKey:=Bytes(R,A,'writepassword');
              SetLength(IsoPasswords,Ord(Length(Key)>0)+Ord(Length(OtherKey)>0)); J:=0;
              if Length(Key)>0 then begin IsoPasswords[J].Identifier:=1; IsoPasswords[J].Value:=Key; Inc(J); end;
              if Length(OtherKey)>0 then begin IsoPasswords[J].Identifier:=2; IsoPasswords[J].Value:=OtherKey; end;
              IsoSession:=TIso15693PasswordSession.Create(IsoSession,ippSlix2,IsoPasswords);
            end else begin
              SetLength(IsoPasswords,1); IsoPasswords[0].Identifier:=Number(R,A,'identifier',1,3);
              Key:=Bytes(R,A,'password'); IsoPasswords[0].Value:=Key;
              IsoSession:=TIso15693PasswordSession.Create(IsoSession,ippSt25Dv,IsoPasswords);
            end;
          finally
            if Length(Key)>0 then FillChar(Key[0],Length(Key),0);
            if Length(OtherKey)>0 then FillChar(OtherKey[0],Length(OtherKey),0); IsoPasswords:=nil;
          end;
        end;
        IsoReader := TIso15693CardReader.Create(nil); Type5 := TType5NdefCardReader.Create(nil);
        try
          IsoReader.Session := IsoSession; Type5.Session := IsoSession;
          if A.Id = 'information' then begin IsoInfo := IsoReader.ReadInformation; Output := BytesToHex(IsoInfo.Uid)+' blocks '+IntToStr(IsoInfo.BlockCount)+' bytes per block '+IntToStr(IsoInfo.BlockSize); end
          else if (A.Id = 'read') or (A.Id = 'readmultiple') then begin
            IsoReader.UseMultipleBlockRead:=A.Id='readmultiple';
            if FFamily<>dfIso15693 then IsoReader.UseMultipleBlockRead:=Number(R,A,'bulk',0,1)=1;
            Data := IsoReader.ReadBlocks(Number(R,A,'block',0,65535),Number(R,A,'count',1,65536)); Output := BytesToHex(Data); Artifact(D,'blocks.bin',Data); end
          else if A.Id = 'write' then begin IsoReader.WriteBlock(Number(R,A,'block',0,65535),Bytes(R,A,'data')); D.WriteVerified := True; Output := 'Physical block independently verified.'; end
          else if A.Id = 'readndef' then begin Type5Snapshot := Type5.ReadMessage; Output := DescribeNdef(Type5Snapshot.Records); Artifact(D,'ndef.bin',Type5Snapshot.MessageBytes); end
          else if A.Id = 'writendef' then begin Data:=Bytes(R,A,'ndef'); if Length(Data)=0 then Type5.ClearMessage else begin Ndef := TNdefCodec.Decode(Data); Type5.WriteMessage(Ndef); end; D.WriteVerified := True; Output := 'Type 5 NDEF independently verified.'; end
          else if A.Id = 'clearndef' then begin Type5.ClearMessage; D.WriteVerified := True; Output := 'Empty Type 5 NDEF independently verified.'; end else Fail;
        finally Type5.Free; IsoReader.Free; IsoSession := nil; end;
      end;
      dfUid:
      begin
        Data := Bytes(R,A,'uid');
        if (A.Id = 'gen2') or (A.Id = 'fuid') then
        begin
          Contact := TContactlessCardReader.Create(nil);
          try
            Contact.Transport := T; Contact.Profile := TPcscStorageProfile.Create;
            Key := Bytes(R,A,'key'); I := Number(R,A,'keytype',0,1); N := Number(R,A,'slot',0,255);
            if A.Id = 'gen2' then Contact.ProgramClassicGen2Uid(TClassicGen2UidModel(Number(R,A,'size',0,1)),Data,TMifareClassicKeyType(I),Key,N)
            else Contact.ProgramFuidUidOnce(Data,TMifareClassicKeyType(I),Key,N);
          finally Contact.Free; end;
        end
        else
        begin
          RawUid := TRawUidProgrammer.Create(nil);
          try
            if (A.Id = 'gen3') or (A.Id = 'gen4') then RawUid.Reader := TAcr122RawReader.Create(T,$10,True)
            else RawUid.Reader := TAcr122RawReader.Create(T);
            if A.Id = 'gen1' then RawUid.ProgramClassicUid(TClassicRawUidProfile(Number(R,A,'profile',0,2)),Data)
            else if A.Id = 'direct' then RawUid.ProgramType2DirectWriteUid(Data)
            else if A.Id = 'gen3' then RawUid.ProgramGen3Uid(TGen3UidSize(Number(R,A,'size',0,1)),Data)
            else if A.Id = 'gen4' then begin P := Bytes(R,A,'password'); RawUid.ProgramGen4Uid(TGen4UidLayout(Number(R,A,'layout',0,5)),Data,P); end
            else if A.Id = 'uscuid' then RawUid.ProgramUscuidUid(TUscuidWakeupStyle(Number(R,A,'wakeup',0,1)),TUscuidUidLayout(Number(R,A,'layout',0,2)),Data)
            else if A.Id = 'partial' then RawUid.ProgramPartialUscuidUid(TPartialUscuidProfile(Number(R,A,'profile',0,2)),Data)
            else Fail;
          finally RawUid.Free; end;
        end;
        D.WriteVerified := True; Output := 'Fresh RF UID independently verified: '+BytesToHex(Data);
      end;
      dfTopaz:
      begin
        I:=Number(R,A,'topazmodel',0,1);J:=Number(R,A,'ack',0,1);
        Topaz:=TTopazCardReader.Create(nil);Type1:=TType1NdefCardReader.Create(nil);
        try
          Topaz.Model:=TTopazModel(I);Type1.Model:=TTopazModel(I);
          TopazSession:=TAcr122TopazSession.Create(T,TTopazByteAck(J));Topaz.Session:=TopazSession;Type1.Session:=TopazSession;
          if A.Id='snapshot' then TopazSnapshot:=Topaz.ReadSnapshot
          else if A.Id='read' then begin
            Data:=Topaz.ReadRange(Number(R,A,'address',0,511),Number(R,A,'count',1,512));
            Output:=BytesToHex(Data);Artifact(D,'physical-range.bin',Data);
          end
          else if A.Id='write' then begin
            TopazSnapshot:=Topaz.WriteUserRangeVerified(Bytes(R,A,'uid'),Bytes(R,A,'before'),Number(R,A,'address',0,511),Bytes(R,A,'data'));D.WriteVerified:=True;
          end
          else if (A.Id='readndef') or (A.Id='writendef') then begin
            if A.Id='readndef' then Type1Snapshot:=Type1.ReadMessage
            else begin Type1Snapshot:=Type1.WriteMessageVerified(Bytes(R,A,'uid'),Bytes(R,A,'before'),Bytes(R,A,'ndef'));D.WriteVerified:=True;end;
            TopazSnapshot:=Type1Snapshot.Card;Output:=DescribeNdef(Type1Snapshot.Records)+'NDEF: '+BytesToHex(Type1Snapshot.MessageBytes)+sLineBreak;
            Output:=Output+'CC read only: '+BoolToStr(Type1Snapshot.ReadOnly,True)+sLineBreak;Artifact(D,'message.ndef',Type1Snapshot.MessageBytes);
          end else Fail;
          if A.Id<>'read' then begin
            Output:=Output+'UID: '+BytesToHex(TopazSnapshot.Uid)+sLineBreak+'Header ROM: '+BytesToHex(TopazSnapshot.Target.HeaderRom)+sLineBreak+
              'Complete memory preimage: '+BytesToHex(TopazSnapshot.Memory)+sLineBreak+'Writable byte map (00/01): '+BytesToHex(TopazSnapshot.Writable);
            Artifact(D,'topaz-memory.bin',TopazSnapshot.Memory);Artifact(D,'topaz-writable.bin',TopazSnapshot.Writable);
          end;
        finally Topaz.Free;Type1.Free;TopazSession:=nil;end;
      end;
      dfFelica:
      begin
        J := Number(R,A,'bitrate',0,1); Felica := TFelicaCardReader.Create(nil); Type3 := TType3NdefCardReader.Create(nil);
        try
          if (A.Id = 'target') or (A.Id = 'read') or (A.Id = 'write') then
          begin
            N := Number(R,A,'system',0,65535);
            if A.Id <> 'target' then
            begin
              Address := Number(R,A,'firstblock',0,65535); Count := Number(R,A,'count',1,15);
              if Address > 65536-Count then Fail;
              SetLength(FelicaBlocks,Count); for I := 0 to Count-1 do FelicaBlocks[I] := Address+I;
              TagId := Number(R,A,'readservice',0,65535);
              if A.Id = 'write' then begin P := Bytes(R,A,'before'); NewP := Bytes(R,A,'data'); Aid := Number(R,A,'writeservice',0,65535); TFelicaCodec.BlockCommand(HexToBytes('0000000000000000'),Aid,FelicaBlocks,True,NewP); if Length(P) <> Length(NewP) then Fail; end;
            end;
            FelicaReader := TAcr122FelicaReader.Create(T,TFelicaBitrate(J)); Felica.Reader := FelicaReader;
            if A.Id = 'target' then begin FelicaTarget := Felica.ReadTarget(N); Output := 'IDm: '+BytesToHex(FelicaTarget.Idm)+sLineBreak+'PMm: '+BytesToHex(FelicaTarget.Pmm)+sLineBreak+'System: '+IntToHex(FelicaTarget.SystemCode,4); end
            else begin
              if A.Id = 'read' then Data := Felica.ReadBlocks(N,TagId,FelicaBlocks)
              else begin Data := Felica.WriteBlocksVerified(N,Aid,TagId,FelicaBlocks,P,NewP); D.WriteVerified := True; end;
              Output := BytesToHex(Data); Artifact(D,'service-blocks.bin',Data);
            end;
          end
          else
          begin
            if A.Id = 'writendef' then begin P := Bytes(R,A,'before'); TType3NdefMapping.DecodeAttribute(P); end;
            FelicaReader := TAcr122FelicaReader.Create(T,TFelicaBitrate(J)); Type3.Reader := FelicaReader;
            if A.Id = 'attribute' then Type3Attribute := Type3.ReadAttribute
            else begin
              if A.Id = 'readndef' then Type3Snapshot := Type3.ReadMessage
              else if A.Id = 'writendef' then begin Type3Snapshot := Type3.WriteMessageVerified(P,Bytes(R,A,'ndef')); D.WriteVerified := True; end
              else Fail;
              Type3Attribute := Type3Snapshot.Attribute;
              Output := 'IDm: '+BytesToHex(Type3Snapshot.Target.Idm)+sLineBreak+DescribeNdef(Type3Snapshot.Records)+'NDEF: '+BytesToHex(Type3Snapshot.MessageBytes)+sLineBreak;
              Artifact(D,'message.ndef',Type3Snapshot.MessageBytes);
            end;
            Output := Output+'Capacity: '+IntToStr(Integer(Type3Attribute.MaxBlocks)*16)+sLineBreak+
              'Published bytes: '+IntToStr(Type3Attribute.MessageBytes)+sLineBreak+'Read only: '+BoolToStr(Type3Attribute.ReadOnly,True)+sLineBreak+
              'Update in progress: '+BoolToStr(Type3Attribute.Updating,True)+sLineBreak+'Attribute preimage: '+BytesToHex(Type3Attribute.RawBytes);
            Artifact(D,'attribute-block.bin',Type3Attribute.RawBytes);
          end;
        finally Felica.Free; Type3.Free; FelicaReader := nil; end;
      end;
      dfUltralightC:
      begin
        Ulc := TUltralightCCardReaderWriter.Create(nil);
        try
          Ulc.Reader := TAcr122RawReader.Create(T);
          if not Supports(T,ICardDesProvider,Des) then Des := TCardWindowsAesProvider.Create;
          Ulc.CryptoProvider := Des; Des := nil; Key := Bytes(R,A,'key');
          if A.Id = 'page' then Data := Ulc.ReadUserPage(Number(R,A,'page',4,39),Key)
          else if A.Id = 'memory' then Data := Ulc.ReadUserMemory(Key)
          else if A.Id = 'write' then
          begin Data := Ulc.WriteUserPageVerified(Number(R,A,'page',4,39),Bytes(R,A,'data'),Key); D.WriteVerified := True; end
          else if A.Id = 'configuration' then UlcConfiguration := Ulc.ReadConfiguration(Key)
          else if A.Id = 'configure' then
          begin UlcConfiguration := Ulc.ConfigureAuthenticationVerified(Number(R,A,'firstpage',3,48),Number(R,A,'protectreads',0,1)=1,Bytes(R,A,'before'),Key); D.WriteVerified := True; end
          else if A.Id = 'changekey' then
          begin P := Bytes(R,A,'newkey'); D.WriteVerified := Ulc.ChangeKeyVerified(Key,P); Output := 'New key verified after same-UID RF activation.'; end
          else Fail;
          if (A.Id = 'configuration') or (A.Id = 'configure') then
          begin
            Data := UlcConfiguration.RawPages; Artifact(D,'configuration-pages-40-43.bin',Data);
            Output := 'First protected page: '+IntToStr(UlcConfiguration.FirstProtectedPage)+sLineBreak+
              'Protect reads: '+BoolToStr(UlcConfiguration.ProtectReads,True)+sLineBreak+
              'AUTH0 locked: '+BoolToStr(UlcConfiguration.Auth0Locked,True)+sLineBreak+
              'AUTH1 locked: '+BoolToStr(UlcConfiguration.Auth1Locked,True)+sLineBreak+
              'Key locked: '+BoolToStr(UlcConfiguration.KeyLocked,True)+sLineBreak+
              'Pages 42/43 preimage: '+BytesToHex(UlcConfiguration.AuthenticationPages);
          end
          else if A.Id <> 'changekey' then begin Output := BytesToHex(Data); Artifact(D,'user-memory.bin',Data); end;
        finally Ulc.Free; end;
      end;
      dfClassic, dfType2:
      begin
        Contact := TContactlessCardReader.Create(nil);
        T2 := TType2NdefCardReader.Create(nil);
        try
          Contact.Transport := T; Contact.Profile := TPcscStorageProfile.Create;
          T2.Transport := T; T2.Profile := TPcscStorageProfile.Create;
          if A.Id = 'uid' then Output := BytesToHex(Contact.ReadUid)
          else if FFamily = dfClassic then
          begin
            I := Number(R,A,'classicmodel',0,2);
            if A.Id = 'layout' then
            begin
              for J := 0 to TMifareClassicLayout.BlockCount(TMifareClassicModel(I))-1 do
                Output := Output+IntToStr(J)+' trailer '+BoolToStr(TMifareClassicLayout.IsTrailer(TMifareClassicModel(I),J),True)+sLineBreak;
            end
            else
            begin
              Address := Number(R,A,'block',0,255); Key := Bytes(R,A,'key'); J := Number(R,A,'keytype',0,1); N := Number(R,A,'slot',0,255);
              if A.Id = 'read' then Output := BytesToHex(Contact.ReadClassicBlock(TMifareClassicModel(I),Address,TMifareClassicKeyType(J),Key,N))
              else if A.Id = 'write' then begin Contact.WriteClassicDataBlock(TMifareClassicModel(I),Address,TMifareClassicKeyType(J),Key,Bytes(R,A,'data'),N); Output := 'Reader write status accepted; independent read-back has not been performed.'; end
              else Fail;
            end;
          end
          else
          begin
            I := Number(R,A,'type2model',0,Ord(High(TType2TagModel)));
            if A.Id = 'page' then Output := BytesToHex(Contact.ReadType2Page(TType2TagModel(I),Number(R,A,'page',0,255)))
            else if A.Id = 'memory' then begin UserMemory := Contact.ReadType2UserMemory(TType2TagModel(I)); Output := BytesToHex(UserMemory.Data); end
            else if A.Id = 'writepage' then begin Contact.WriteType2UserPage(TType2TagModel(I),Number(R,A,'page',0,255),Bytes(R,A,'data')); Output := 'Reader write status accepted; independent read-back has not been performed.'; end
            else if A.Id = 'readndef' then begin T2Snapshot := T2.ReadMessage(TType2TagModel(I)); Output := BytesToHex(T2Snapshot.MessageBytes); end
            else if A.Id = 'writendef' then begin Ndef := TNdefCodec.Decode(Bytes(R,A,'ndef')); T2.WriteMessage(TType2TagModel(I),Ndef); D.WriteVerified := True; Output := 'Type 2 NDEF independently verified.'; end
            else if Pos('pwd',A.Id)=1 then
            begin
              P := Bytes(R,A,'password'); Key := Bytes(R,A,'pack');
              PasswordReader := TType2PasswordCardReader.Create(nil);
              try
                PasswordReader.Reader := TAcr122RawReader.Create(T);
                if A.Id = 'pwdpage' then begin Data := PasswordReader.ReadUserPage(TType2TagModel(I),Number(R,A,'page',4,225),P,Key); Output := BytesToHex(Data); Artifact(D,'page.bin',Data); end
                else if A.Id = 'pwdmemory' then begin UserMemory := PasswordReader.ReadUserMemory(TType2TagModel(I),P,Key); Output := BytesToHex(UserMemory.Data); Artifact(D,'user-memory.bin',UserMemory.Data); end
                else if (A.Id = 'pwdconfig') or (A.Id = 'pwdconfigure') then
                begin
                  if A.Id = 'pwdconfig' then Type2Configuration := PasswordReader.ReadConfiguration(TType2TagModel(I),P,Key)
                  else begin Type2Configuration := PasswordReader.ConfigureAuthenticationVerified(TType2TagModel(I),Number(R,A,'firstpage',0,255),Number(R,A,'protectreads',0,1)=1,Number(R,A,'authlim',0,7),Bytes(R,A,'before'),P,Key); D.WriteVerified := True; end;
                  Artifact(D,'authentication-configuration.bin',Type2Configuration.RawPages);
                  Output := 'AUTH0: '+IntToStr(Type2Configuration.FirstProtectedPage)+sLineBreak+
                    'Protect reads: '+BoolToStr(Type2Configuration.ProtectReads,True)+sLineBreak+
                    'AUTHLIM: '+IntToStr(Type2Configuration.AuthenticationLimit)+sLineBreak+
                    'Configuration locked: '+BoolToStr(Type2Configuration.ConfigurationLocked,True)+sLineBreak+
                    'Mirror configured: '+BoolToStr(Type2Configuration.MirrorConfigured,True)+sLineBreak+
                    'NFC counter enabled: '+BoolToStr(Type2Configuration.NfcCounterEnabled,True)+sLineBreak+
                    'Exact preimage: '+BytesToHex(Type2Configuration.RawPages);
                end
                else if A.Id = 'pwdcredentials' then
                begin NewP := Bytes(R,A,'newpassword'); Wire := Bytes(R,A,'newpack'); D.WriteVerified := PasswordReader.ChangeCredentialsVerified(TType2TagModel(I),P,Key,NewP,Wire); Output := 'Replacement credentials verified after same-UID RF activation.'; end
                else if A.Id = 'pwdcounter' then Output := IntToStr(PasswordReader.ReadCounter(TType2TagModel(I),Number(R,A,'counter',0,2),P,Key))
                else if (A.Id = 'pwdreadndef') or (A.Id = 'pwdwritendef') then
                begin
                  if A.Id = 'pwdreadndef' then T2Snapshot := PasswordReader.ReadNdef(TType2TagModel(I),P,Key)
                  else begin T2Snapshot := PasswordReader.WriteNdefVerified(TType2TagModel(I),Bytes(R,A,'ndef'),P,Key); D.WriteVerified := True; end;
                  Output := DescribeNdef(T2Snapshot.Records)+'NDEF: '+BytesToHex(T2Snapshot.MessageBytes);
                  Artifact(D,'message.ndef',T2Snapshot.MessageBytes);
                end
                else begin PasswordReader.WriteUserPage(TType2TagModel(I),Number(R,A,'page',4,225),P,Key,Bytes(R,A,'data')); D.WriteVerified := True; Output := 'Authenticated user page independently verified.'; end;
              finally PasswordReader.Free; end;
            end
            else if A.Id = 'clearndef' then begin T2.ClearMessage(TType2TagModel(I)); D.WriteVerified := True; Output := 'Type 2 empty NDEF independently verified.'; end
            else Fail;
          end;
        finally T2.Free; Contact.Free; end;
      end;
      dfType4:
      begin
        T4 := TType4NdefCardReader.Create(nil);
        try
          T4.Transport := T;
          if A.Id = 'decodecc' then CC := TType4NdefCodec.DecodeCapabilities(Bytes(R,A,'hex'))
          else
          begin
            T4.ApplicationVersion := TType4ApplicationVersion(Number(R,A,'version',0,1));
            if A.Id = 'capabilities' then CC := T4.ReadCapabilities
            else
            begin
              Address := Number(R,A,'fileid',0,65535);
              if A.Id = 'read' then begin T4Snapshot := T4.ReadMessage(Address); Output := BytesToHex(T4Snapshot.MessageBytes); end
              else if A.Id = 'write' then begin Ndef := TNdefCodec.Decode(Bytes(R,A,'ndef')); T4.WriteMessage(Ndef,Address); D.WriteVerified := True; Output := 'Type 4 NDEF independently verified.'; end
              else if A.Id = 'clear' then begin T4.ClearMessage(Address); D.WriteVerified := True; Output := 'Type 4 empty NDEF independently verified.'; end
              else Fail;
            end;
          end;
          if (A.Id = 'decodecc') or (A.Id = 'capabilities') then
          begin
            Output := 'Mapping '+IntToHex(CC.MappingVersion,2)+' MLe '+IntToStr(CC.MLe)+' MLc '+IntToStr(CC.MLc)+sLineBreak+BytesToHex(CC.RawBytes)+sLineBreak;
            for I := 0 to High(CC.Files) do Output := Output+'FID '+IntToHex(CC.Files[I].FileId,4)+' capacity '+IntToStr(CC.Files[I].MaxFileBytes)+' read '+IntToHex(CC.Files[I].ReadAccess,2)+' write '+IntToHex(CC.Files[I].WriteAccess,2)+sLineBreak;
          end;
        finally T4.Free; end;
      end;
      dfSim:
      begin
        if A.Id = 'email' then Output := string(TSimCodec.DecodePhonebookEmail(Bytes(R,A,'hex'),Number(R,A,'footer',0,1) = 1))
        else if A.Id = 'anr' then begin SE := TSimCodec.DecodePhonebookAnr(Bytes(R,A,'hex'),Number(R,A,'footer',0,1) = 1); Output := string(SE.Number)+'; unresolved EXT '+IntToStr(SE.ExtensionRecord); end
        else if A.Id = 'smsjoin' then
        begin
          Lines := TStringList.Create;
          try
            Lines.StrictDelimiter := True; Lines.Delimiter := ';'; Lines.DelimitedText := string(Text(R,A,'records'));
            if (Lines.Count < 1) or (Lines.Count > 255) then Fail; SetLength(SR,Lines.Count);
            for I := 0 to Lines.Count-1 do SR[I] := HexToBytes(Lines[I]);
            Assembled := TSimCodec.AssembleSms(SR); Output := 'Segments '+IntToStr(Length(Assembled.Segments))+sLineBreak+string(Assembled.Text)+sLineBreak+'Binary '+BytesToHex(Assembled.BinaryPayload);
          finally Lines.Free; end;
        end
        else if A.Id = 'encodealpha' then Output := BytesToHex(TSimCodec.EncodeAlpha(Text(R,A,'name'),Number(R,A,'width',0,255)))
        else if A.Id = 'decode' then
        begin
          Data := Bytes(R,A,'hex');
          case Number(R,A,'kind',0,8) of
            0: Output := string(TSimCodec.DecodeIccid(Data));
            1: Output := string(TSimCodec.DecodeImsi(Data));
            2: Output := string(TSimCodec.DecodeAlpha(Data));
            3: begin SP := TSimCodec.DecodeSpn(Data); Output := string(SP.Name); end;
            4: begin SE := TSimCodec.DecodeAdn(Data); Output := string(SE.Name)+' / '+string(SE.Number)+' / raw '+BytesToHex(SE.Raw); end;
            5: begin SM := TSimCodec.DecodeSms(Data); Output := 'Status '+IntToStr(SM.StatusByte)+'; preserved body '+BytesToHex(SM.Body); end;
            6: begin SD := TSimCodec.DecodeDirectoryRecord(Data); Output := BytesToHex(SD.Aid)+' '+string(SD.LabelText); end;
            8: begin SMS := TSimCodec.DecodeSmsMessage(Data); Output := 'Address '+string(SMS.Address)+'; text decoded '+BoolToStr(SMS.TextDecoded,True)+sLineBreak+string(SMS.Text)+sLineBreak+'Concat '+BoolToStr(SMS.Concatenated,True)+' reference '+IntToStr(SMS.ConcatenationReference)+' segment '+IntToStr(SMS.SegmentNumber)+'/'+IntToStr(SMS.SegmentCount)+sLineBreak+'Raw UD '+BytesToHex(SMS.UserData); end;
            7: begin PB := TSimCodec.DecodePhonebookReferences(Data); for I := 0 to High(PB) do Output := Output+'Template '+IntToStr(PB[I].TemplateIndex)+' / '+IntToHex(PB[I].TemplateTag,2)+' role '+IntToHex(PB[I].RoleTag,2)+' FID '+IntToHex(PB[I].FileId,4)+' SFI '+IntToStr(PB[I].ShortFileId)+sLineBreak; end;
          end;
        end
        else
        begin
          Sim := TSimCardReaderWriter.Create(nil);
          try
            Sim.Profile := TSimCardProfile(Number(R,A,'profile',0,1)); Sim.ApplicationAid := Bytes(R,A,'aid');
            Sim.PinReference := Number(R,A,'pinref',1,255); Sim.MinimumPinAttempts := Number(R,A,'attempts',1,15); Sim.Transport := T;
            for I := 0 to High(A.Fields) do if A.Fields[I].Name = 'pin' then P := Bytes(R,A,'pin');
            N := -1; for I := 0 to High(A.Fields) do if A.Fields[I].Name = 'path' then N := I;
            if N >= 0 then
            begin
              Lines := TStringList.Create;
              try
                Lines.StrictDelimiter := True; Lines.Delimiter := '/'; Lines.DelimitedText := string(Text(R,A,'path'));
                SetLength(SF.Path,Lines.Count); SF.Root := TSimFileRoot(Number(R,A,'root',0,1));
                for I := 0 to Lines.Count-1 do begin Data := HexToBytes(Lines[I]); if Length(Data) <> 2 then Fail; SF.Path[I] := Word(Data[0]) shl 8 or Data[1]; end;
                SF := TSimCodec.FileAddress(SF.Root,SF.Path);
              finally Lines.Free; end;
            end;
            if A.Id = 'pukstatus' then begin PS := Sim.GetPukStatus; Output := 'Known PUK attempts '+IntToStr(PS.RemainingAttempts)+' blocked '+BoolToStr(PS.Blocked,True); end
            else if (A.Id = 'changepin') or (A.Id = 'unblockpin') then
            begin
              NewP := Bytes(R,A,'newpin');
              if A.Id = 'changepin' then Receipt := Sim.ChangePin(P,NewP)
              else begin Key := Bytes(R,A,'puk'); Receipt := Sim.UnblockPin(Key,NewP); end;
              Output := 'Credential command accepted '+BoolToStr(Receipt.CommandAccepted,True)+'; fresh-session new PIN verification has not been performed.';
            end
            else if A.Id = 'linkedwrite' then
            begin
              Lines := TStringList.Create; Parts := nil;
              try
                Parts := TStringList.Create; Lines.StrictDelimiter := True; Lines.Delimiter := ';';
                Parts.StrictDelimiter := True; Parts.Delimiter := ':'; Lines.DelimitedText := string(Text(R,A,'plan'));
                if (Lines.Count < 1) or (Lines.Count > 32) then Fail; SetLength(Changes,Lines.Count);
                for I := 0 to Lines.Count-1 do
                begin
                  Parts.DelimitedText := Lines[I]; if Parts.Count <> 4 then Fail;
                  Data := HexToBytes(Parts[0]); if Length(Data) <> 2 then Fail;
                  Changes[I].FileAddress := TSimCodec.FileAddress(sfrUsimApplication,[$5F3A,Word(Data[0]) shl 8 or Data[1]]);
                  if not TryStrToInt(Parts[1],N) then Fail; Changes[I].RecordNumber := N;
                  Changes[I].ExpectedBefore := HexToBytes(Parts[2]); Changes[I].Data := HexToBytes(Parts[3]);
                end;
                Sim.WriteLinkedPhonebookRecords(Changes,P); D.WriteVerified := True; Output := 'All planned linked records independently verified.';
              finally Parts.Free; Lines.Free; end;
            end
            else if A.Id = 'iccid' then Output := string(Sim.ReadIccid)
            else if A.Id = 'applications' then begin SA := Sim.ReadApplications; for I := 0 to High(SA) do Output := Output+BytesToHex(SA[I].Aid)+' '+string(SA[I].LabelText)+sLineBreak; end
            else if (A.Id = 'pinstatus') or (A.Id = 'verify') then
            begin
              if A.Id = 'verify' then PS := Sim.VerifyPin(P) else PS := Sim.GetPinStatus;
              Output := 'Remaining attempts: '+IntToStr(PS.RemainingAttempts)+'; blocked '+BoolToStr(PS.Blocked,True)+'; disabled '+BoolToStr(PS.Disabled,True)+'; verified '+BoolToStr(PS.Verified,True);
            end
            else if A.Id = 'imsi' then Output := string(Sim.ReadImsi(P))
            else if A.Id = 'spn' then begin SP := Sim.ReadSpn(P); Output := string(SP.Name)+'; display condition '+IntToStr(SP.DisplayCondition); end
            else if A.Id = 'services' then begin SS := Sim.ReadServices(P); for I := 0 to High(SS) do Output := Output+IntToStr(SS[I].Number)+' available '+BoolToStr(SS[I].Available,True)+' active '+BoolToStr(SS[I].Active,True)+sLineBreak; end
            else if A.Id = 'inspect' then begin SI := Sim.InspectFile(SF); Output := 'File '+IntToHex(SI.FileId,4)+'; size '+IntToStr(SI.Size)+'; record bytes '+IntToStr(SI.RecordBytes)+'; count '+IntToStr(SI.RecordCount)+sLineBreak+BytesToHex(SI.Raw); end
            else if A.Id = 'read' then Output := BytesToHex(Sim.ReadFile(SF,P))
            else if A.Id = 'range' then Output := BytesToHex(Sim.ReadBinaryRange(SF,Number(R,A,'address',0,32767),Number(R,A,'count',1,32768),P))
            else if A.Id = 'record' then Output := BytesToHex(Sim.ReadRecord(SF,Number(R,A,'record',1,255),P))
            else if A.Id = 'records' then begin SR := Sim.ReadRecords(SF,P); for I := 0 to High(SR) do Output := Output+IntToStr(I+1)+': '+BytesToHex(SR[I])+sLineBreak; end
            else if A.Id = 'linkedcontact' then
            begin
              Linked := Sim.ReadLinkedUsimContact(Number(R,A,'pbrrecord',1,255),Number(R,A,'adnfid',1,65535),Number(R,A,'record',1,255),P);
              Output := string(Linked.Contact.Name)+' / '+string(Linked.Contact.Number)+sLineBreak+'Original ADN '+BytesToHex(Linked.Contact.Raw)+sLineBreak;
              for I := 0 to High(Linked.Fields) do Output := Output+'Role '+IntToHex(Linked.Fields[I].Reference.RoleTag,2)+' FID '+IntToHex(Linked.Fields[I].Reference.FileId,4)+' record '+IntToStr(Linked.Fields[I].RecordNumber)+' raw '+BytesToHex(Linked.Fields[I].Raw)+sLineBreak;
              for I := 0 to High(Linked.Extensions) do Output := Output+'EXT '+BytesToHex(Linked.Extensions[I])+sLineBreak;
            end
            else if A.Id = 'contacts' then begin SC := Sim.ReadPhonebook(SF,P); for I := 0 to High(SC) do Output := Output+IntToStr(SC[I].RecordNumber)+': '+string(SC[I].Name)+' / '+string(SC[I].Number)+' / raw '+BytesToHex(SC[I].Raw)+sLineBreak; end
            else
            begin
              Data := Bytes(R,A,'before');
              if A.Id = 'write' then Sim.WriteFile(SF,Data,Bytes(R,A,'data'),P)
              else if A.Id = 'writerecord' then Sim.WriteRecord(SF,Number(R,A,'record',1,255),Data,Bytes(R,A,'data'),P)
              else if A.Id = 'contact' then Sim.WritePhonebookContact(SF,Number(R,A,'record',1,255),Data,Text(R,A,'name'),Text(R,A,'number'),P)
              else if A.Id = 'deletecontact' then Sim.DeletePhonebookContact(SF,Number(R,A,'record',1,255),Data,P)
              else Fail;
              D.WriteVerified := True; Output := 'SIM write independently verified.';
            end;
          finally Sim.Free; end;
        end;
      end;
      dfRfid:
      begin
        if A.Id = 'text' then
        begin
          Identifier := TRfidInputCodec.Decode(Text(R,A,'text'),TRfidInputEncoding(Number(R,A,'encoding',0,2)),Number(R,A,'expected',0,128));
          Count := Number(R,A,'width',0,64); I := Number(R,A,'order',0,1);
          Output := string(Identifier.Text) + sLineBreak + 'Explicit hex bytes: ' + BytesToHex(Identifier.Bytes);
          if Count > 0 then Output := Output + sLineBreak + 'Explicit numeric conversion: ' +
            BytesToHex(TRfidInputCodec.ToBytes(Identifier,Count,TRfidInputByteOrder(I)));
        end
        else if A.Id = 'reports' then
        begin
          H := TRfidHidReportReader.Create(nil); Lines := TStringList.Create;
          try
            ConfigureCapture(H,R,A); H.ReportKind := TRfidHidReportKind(Number(R,A,'kind',0,2));
            H.ReportId := Number(R,A,'reportid',0,255); H.InitialCapsLock := Number(R,A,'caps',0,1) = 1;
            Field := Default(TRfidHidAsciiField); Field.ReportBytes := Number(R,A,'reportbytes',0,1024);
            Field.Offset := Number(R,A,'offset',0,1023); Field.FieldBytes := Number(R,A,'fieldbytes',0,1024);
            Field.HasReportId := Number(R,A,'hasid',0,1) = 1; Field.ReportId := H.ReportId;
            if Number(R,A,'padding',0,1) = 1 then Field.PaddingByte := 32;
            H.AsciiField := Field; H.Start;
            Lines.StrictDelimiter := True; Lines.Delimiter := ';'; Lines.DelimitedText := string(Text(R,A,'reports'));
            if (Lines.Count < 1) or (Lines.Count > 4096) then Fail;
            N := 0; Output := '';
            for I := 0 to Lines.Count - 1 do
              if H.FeedReport(HexToBytes(Trim(Lines[I])),UInt64(I)*10) then
              begin Inc(N); Identifier := H.LastIdentifier;
                Output := Output + string(Identifier.Text) + sLineBreak; end;
            Output := 'Completed frames: ' + IntToStr(N) + sLineBreak + Output;
          finally H.Free; Lines.Free; end;
        end else Fail;
      end;
    else Fail;
    end;
  finally
    Wipe(P); Wipe(NewP); Wipe(Key); Wipe(Wire);
    if Output <> '' then D.Text := UnicodeString(Output);
  end;
end;

function TFamilyOperations.TryValidateRequest(const ARequest: TCardDemoRequest;
  out AError: UnicodeString): Boolean;
var Selected: TCardFamilyAction;
begin
  Result := TryAction(FFamily, ARequest, Selected, AError);
end;

procedure TFamilyOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var A: TCardFamilyAction; T: ICardTransport; C: ITwn4ByteChannel;
  Connection, SamConnection: TDeferredConnection;
  SamOwner: ICardTransport; H: ICardFamilyHardware;
begin
  A := Action(FFamily,ARequest); AResult := Default(TCardDemoResult); AResult.Operation := cdoFamily;
  if (A.Pcsc and (FFamily <> dfTools)) or (FFamily = dfTwn4) then
  begin
    H := FHardware; if H = nil then H := TNativeHardware.Create;
    if FFamily = dfTwn4 then Connection := TDeferredConnection.Create(H,string(Text(ARequest,A,'port')))
    else Connection := TDeferredConnection.Create(H,string(ARequest.ReaderName));
    T := Connection; C := Connection; SamConnection := nil;
    try
      if (FFamily = dfMobib) and (A.Id = 'samfile') then
      begin
        SamConnection := TDeferredConnection.Create(H,string(Text(ARequest,A,'samreader')),True);
        SamOwner := SamConnection; FSamTransport := SamOwner;
      end;
      try Execute(ARequest,A,T,C,AResult);
      except
        on E: EMemoryCardWriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.Verified; raise; end;
        on E: EContactlessWriteUncertain do begin AResult.WriteUncertain := True; raise; end;
        on E: ESimCardWriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.VerifiedReadBack; raise; end;
        on E: ETwn4WriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.VerifiedReadBack; raise; end;
      end;
    except
      FSamTransport := nil;
      if SamConnection <> nil then try SamConnection.Release; except end;
      try Connection.Release; except end;
      raise;
    end;
    FSamTransport := nil;
    try
      if SamConnection <> nil then SamConnection.Release;
    except
      try Connection.Release; except end;
      raise;
    end;
    try Connection.Release;
    except if AResult.WriteVerified then AResult.WriteUncertain := True; raise; end;
  end
  else Execute(ARequest,A,nil,nil,AResult);
  AResult.Success := True;
end;

function CreateCardFamilyOperations(const AFamily: TCardDemoFamily;
  const AHardware: ICardFamilyHardware): ICardDemoOperations;
var O: TFamilyOperations;
begin
  CardFamilyName(AFamily); O := TFamilyOperations.Create;
  O.FFamily := AFamily; O.FHardware := AHardware; Result := O;
end;

end.
