unit ERD.Card.EID.Reader;

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
  ERD.Card.Transport, ERD.Card.APDU, ERD.Card.EID.Data;

type
  /// <summary>An unsuccessful card status in a Belgian eID read operation.</summary>
  /// <remarks>Does not retain or report commands, response data or personal information.</remarks>
  EBelgianEidStatusError = class(EBelgianEidError)
  private
    FStatusWord: Word;
  public
    /// <summary>Creates an error containing only the operation name and status word.</summary>
    /// <param name="AOperation">A fixed operation label, without any personal data.</param>
    /// <param name="AStatusWord">The returned SW1/SW2 word.</param>
    constructor Create(const AOperation: string; const AStatusWord: Word);
      reintroduce;
    /// <summary>The card's SW1/SW2 word, independent of transport errors.</summary>
    property StatusWord: Word read FStatusWord;
  end;

  /// <summary>Non-visual reader for public files of the documented Belpic 1.7/1.8 contact profiles.</summary>
  /// <remarks>Construction performs no hardware access. Assign a connected ICardTransport.
  /// All calls and configuration belong to one caller thread; the component is not
  /// reentrant. A read selects the Belpic AID and changes the current EF. No PIN,
  /// reset, write, signing or authenticity verification is performed. Contactless
  /// PACE and undisclosed future applet profiles are not implemented.</remarks>
  TBelgianEIDReader = class(TComponent)
  private
    FTransport: ICardTransport;
    FUseTransactions: Boolean;
    FChunkSize: Integer;
    FMaxFileBytes: Integer;
    procedure SetChunkSize(const AValue: Integer);
    procedure SetMaxFileBytes(const AValue: Integer);
    function Select(const AData: TBytes; const AP1: Byte): TApduResponse;
    procedure RequireSuccess(const AResponse: TApduResponse;
      const AOperation: string);
    function ReadResponse(const ACommand: TApduCommand): TApduResponse;
    function ReadSelectedFile: TBytes;
    function ReadFile(const ADirectory, AFile: Word; const AOptional: Boolean;
      out AMissing: Boolean): TBytes;
    function ReadCardInternal(const ASections: TEidSections): TBelgianEidData;
  public
    /// <summary>Creates an inactive reader with 248-byte reads and mandatory transactions.</summary>
    /// <param name="AOwner">Optional component owner; nil makes the caller responsible for Free.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Reads the requested public files as one operation.</summary>
    /// <param name="ASections">Nonempty selection; defaults to identity, address and photograph.</param>
    /// <returns>A complete independent result; no partial data is returned on any failure.</returns>
    /// <exception cref="EBelgianEidError">Configuration, data, protocol or a configured bound is invalid.</exception>
    /// <exception cref="EBelgianEidStatusError">A required file or card operation returns an error status.</exception>
    /// <remarks>Transport exceptions propagate without replay. Successful transaction-release
    /// failures propagate; when a read already failed its original exception is preserved.
    /// Byte-array fields share storage on ordinary record assignment. Certificate DER
    /// framing is checked, but trust, signatures, photo hashes and X.509 contents are not.</remarks>
    function ReadCard(const ASections: TEidSections = [esIdentity, esAddress,
      esPhoto]): TBelgianEidData;
    /// <summary>Connected byte transport retained until reassignment or component destruction.</summary>
    /// <remarks>The interface keeps its object alive, but its owner may close the connection.
    /// With UseTransactions enabled the object must also implement ICardTransaction.</remarks>
    property Transport: ICardTransport read FTransport write FTransport;
  published
    /// <summary>Whether ReadCard acquires an exclusive ICardTransaction; defaults to true.</summary>
    /// <remarks>Set false only when the caller guarantees exclusive access for the entire
    /// read, such as an externally owned transaction. Nested transactions are unsupported.</remarks>
    property UseTransactions: Boolean read FUseTransactions
      write FUseTransactions default True;
    /// <summary>Requested READ BINARY data size, 1..256 bytes; defaults to 248.</summary>
    /// <remarks>Short Le zero means 256 on the wire. Values outside this range raise EBelgianEidError.</remarks>
    property ChunkSize: Integer read FChunkSize write SetChunkSize default 248;
    /// <summary>Per-file byte limit, 1..32768; defaults to EidMaxFileBytes.</summary>
    /// <remarks>An EOF probe at the limit is required. A file ending at offset 32768
    /// cannot be proved complete using a 15-bit offset and is rejected. Out-of-range
    /// assignments raise EBelgianEidError.</remarks>
    property MaxFileBytes: Integer read FMaxFileBytes write SetMaxFileBytes
      default EidMaxFileBytes;
  end;

implementation

uses ERD.Card.Bytes;

procedure ProtocolError(const AReason: string);
begin
  raise EBelgianEidError.Create('Belgian eID read failed: ' + AReason + '.');
end;

constructor EBelgianEidStatusError.Create(const AOperation: string;
  const AStatusWord: Word);
begin
  inherited CreateFmt('Belgian eID %s returned status %.4x.',
    [AOperation, AStatusWord]);
  FStatusWord := AStatusWord;
end;

constructor TBelgianEIDReader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUseTransactions := True;
  FChunkSize := 248;
  FMaxFileBytes := EidMaxFileBytes;
end;

procedure TBelgianEIDReader.SetChunkSize(const AValue: Integer);
begin
  if (AValue < 1) or (AValue > 256) then
    ProtocolError('chunk size');
  FChunkSize := AValue;
end;

procedure TBelgianEIDReader.SetMaxFileBytes(const AValue: Integer);
begin
  if (AValue < 1) or (AValue > EidMaxFileBytes) then
    ProtocolError('file limit');
  FMaxFileBytes := AValue;
end;

function TBelgianEIDReader.Select(const AData: TBytes; const AP1: Byte)
  : TApduResponse;
var
  Command: TApduCommand;
begin
  Command := Default (TApduCommand);
  Command.INS := $A4;
  Command.P1 := AP1;
  Command.P2 := $0C;
  Command.Data := AData;
  Result := TApduCodec.DecodeResponse
    (FTransport.Exchange(TApduCodec.EncodeCommand(Command)));
  if Length(Result.Data) <> 0 then
    ProtocolError('unexpected SELECT data');
end;

procedure TBelgianEIDReader.RequireSuccess(const AResponse: TApduResponse;
  const AOperation: string);
begin
  if AResponse.StatusWord <> ApduStatusSuccess then
    raise EBelgianEidStatusError.Create(AOperation, AResponse.StatusWord);
end;

function TBelgianEIDReader.ReadResponse(const ACommand: TApduCommand)
  : TApduResponse;
var
  Command: TApduCommand;
  Response: TApduResponse;
  Buffer: TBytes;
  Count, Steps, CorrectLe, I: Integer;
  Corrected: Boolean;
begin
  Result := Default (TApduResponse);
  Buffer := nil;
  SetLength(Buffer, Integer(ACommand.Le));
  Command := ACommand;
  Count := 0;
  Corrected := False;
  for Steps := 1 to 32 do
  begin
    Response := TApduCodec.DecodeResponse
      (FTransport.Exchange(TApduCodec.EncodeCommand(Command)));
    if (Response.StatusWord and $FF00) = $6C00 then
    begin
      if Corrected or (Length(Response.Data) <> 0) then
        ProtocolError('invalid Le correction');
      CorrectLe := Response.StatusWord and $FF;
      if CorrectLe = 0 then
        CorrectLe := 256;
      if CorrectLe > Integer(Command.Le) then
        ProtocolError('Le correction exceeds request');
      Command.Le := Cardinal(CorrectLe);
      if Command.INS = $B0 then
        SetLength(Buffer, CorrectLe);
      Corrected := True;
      Continue;
    end;
    if (Length(Response.Data) > Integer(Command.Le)) or
      (Length(Response.Data) > Length(Buffer) - Count) then
      ProtocolError('response exceeds request');
    if (Response.StatusWord <> ApduStatusSuccess) and
      ((Response.StatusWord and $FF00) <> $6100) then
    begin
      if (Length(Response.Data) <> 0) or (Count <> 0) then
        ProtocolError('error status with data');
      Result.StatusWord := Response.StatusWord;
      Exit;
    end;
    for I := 0 to Length(Response.Data) - 1 do
      Buffer[Count + I] := Response.Data[I];
    Inc(Count, Length(Response.Data));
    if Response.StatusWord = ApduStatusSuccess then
    begin
      SetLength(Buffer, Count);
      Result.Data := Buffer;
      Result.StatusWord := ApduStatusSuccess;
      Exit;
    end;
    CorrectLe := Response.StatusWord and $FF;
    if CorrectLe = 0 then
      CorrectLe := 256;
    if CorrectLe > Length(Buffer) - Count then
      ProtocolError('GET RESPONSE exceeds request');
    Command := Default (TApduCommand);
    Command.INS := $C0;
    Command.HasLe := True;
    Command.Le := Cardinal(CorrectLe);
    Corrected := False;
  end;
  ProtocolError('GET RESPONSE step limit');
end;

function TBelgianEIDReader.ReadSelectedFile: TBytes;
var
  Command: TApduCommand;
  Response: TApduResponse;
  Offset, Requested, I: Integer;
begin
  Result := nil;
  SetLength(Result, FMaxFileBytes);
  Offset := 0;
  while True do
  begin
    if Offset >= EidMaxFileBytes then
      ProtocolError('15-bit offset limit');
    Requested := FChunkSize;
    if Requested > FMaxFileBytes - Offset then
      Requested := FMaxFileBytes - Offset;
    if Requested = 0 then
      Requested := 1; // Probe EOF without accepting data beyond the limit.
    Command := Default (TApduCommand);
    Command.INS := $B0;
    Command.P1 := Byte(Offset shr 8);
    Command.P2 := Byte(Offset and $FF);
    Command.HasLe := True;
    Command.Le := Cardinal(Requested);
    Response := ReadResponse(Command);
    if (Response.StatusWord = $6B00) and (Offset > 0) then
    begin
      SetLength(Result, Offset);
      Exit;
    end;
    RequireSuccess(Response, 'READ BINARY');
    if Length(Response.Data) = 0 then
      ProtocolError('read made no progress');
    if Length(Response.Data) > FMaxFileBytes - Offset then
      ProtocolError('file limit exceeded');
    for I := 0 to Length(Response.Data) - 1 do
      Result[Offset + I] := Response.Data[I];
    Inc(Offset, Length(Response.Data));
  end;
end;

function TBelgianEIDReader.ReadFile(const ADirectory, AFile: Word;
  const AOptional: Boolean; out AMissing: Boolean): TBytes;
var
  Response: TApduResponse;
  Id: TBytes;
begin
  Result := nil;
  AMissing := False;
  SetLength(Id, 2);
  Id[0] := $3F;
  Id[1] := 0;
  RequireSuccess(Select(Id, $02), 'SELECT MF');
  Id[0] := Byte(ADirectory shr 8);
  Id[1] := Byte(ADirectory and $FF);
  RequireSuccess(Select(Id, $02), 'SELECT DF');
  Id[0] := Byte(AFile shr 8);
  Id[1] := Byte(AFile and $FF);
  Response := Select(Id, $02);
  if AOptional and (Response.StatusWord = $6A82) then
  begin
    AMissing := True;
    Exit;
  end;
  RequireSuccess(Response, 'SELECT EF');
  Result := ReadSelectedFile;
end;

function TBelgianEIDReader.ReadCardInternal(const ASections: TEidSections)
  : TBelgianEidData;
var
  Missing: Boolean;
  Bytes: TBytes;
  Kind: TEidCertificateKind;
begin
  Result := Default (TBelgianEidData);
  RequireSuccess(Select(HexToBytes(EidBelpicAidHex), $04), 'SELECT Belpic');
  if esIdentity in ASections then
    Result.Identity := TBelgianEidCodec.DecodeIdentity
      (ReadFile($DF01, $4031, False, Missing));
  if esAddress in ASections then
    Result.Address := TBelgianEidCodec.DecodeAddress
      (ReadFile($DF01, $4033, False, Missing));
  if esPhoto in ASections then
  begin
    Result.Photo := ReadFile($DF01, $4035, False, Missing);
    if (Length(Result.Photo) < 3) or (Result.Photo[0] <> $FF) or
      (Result.Photo[1] <> $D8) or (Result.Photo[2] <> $FF) then
      ProtocolError('photo JPEG header');
  end;
  if esSignatures in ASections then
  begin
    Result.IdentitySignature := ReadFile($DF01, $4032, False, Missing);
    Result.AddressSignature := ReadFile($DF01, $4034, False, Missing);
  end;
  if esCertificates in ASections then
  begin
    SetLength(Result.Certificates, Ord(High(TEidCertificateKind)) + 1);
    for Kind := Low(TEidCertificateKind) to High(TEidCertificateKind) do
    begin
      Bytes := ReadFile($DF00, $5038 + Ord(Kind), True, Missing);
      if Missing then
      begin
        Result.Certificates[Ord(Kind)].Kind := Kind;
        Result.Certificates[Ord(Kind)].State := ecsMissing;
      end
      else
        Result.Certificates[Ord(Kind)] := TBelgianEidCodec.DecodeCertificate
          (Bytes, Kind);
    end;
  end;
  Result.Sections := ASections;
end;

function TBelgianEIDReader.ReadCard(const ASections: TEidSections)
  : TBelgianEidData;
var
  Transaction: ICardTransaction;
  Data: TBelgianEidData;
  Succeeded: Boolean;
begin
  Result := Default (TBelgianEidData);
  Transaction := nil;
  if FTransport = nil then
    ProtocolError('no transport');
  if ASections = [] then
    ProtocolError('no sections requested');
  if FUseTransactions then
  begin
    if not Supports(FTransport, ICardTransaction, Transaction) then
      ProtocolError('transport has no transaction capability');
    Transaction.BeginTransaction;
  end;
  Succeeded := False;
  try
    Data := ReadCardInternal(ASections);
    Succeeded := True;
  finally
    if Transaction <> nil then
      if Succeeded then
        Transaction.EndTransaction
      else
      begin
        try
          Transaction.EndTransaction;
        except
          // Preserve the primary read/transport exception after best-effort release.
        end;
      end;
  end;
  Result := Data;
end;

end.
