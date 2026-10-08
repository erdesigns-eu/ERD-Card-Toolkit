unit ERD.Card.Demo.Operations;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Demo.Job;

/// <summary>Creates an inactive executor for explicit PC/SC, ICAO and MSR206-7HL demo requests.</summary>
/// <returns>Worker executor; no device or native cryptographic library is opened by this factory.</returns>
function CreateCardDemoOperations: ICardDemoOperations;

implementation

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.EAC,
  ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.PCSC.Api, ERD.Card.PCSC.Reader,
  ERD.Card.EID.Reader, ERD.Card.EID.Data, ERD.Card.EID.DocumentReader,
  ERD.Card.EID.Access, ERD.Card.EID.ICAO,
  ERD.Card.EMV.Reader, ERD.Card.EMV.Data,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2,
  ERD.Card.Contactless.Type2.Ndef, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Contactless.DESFire, ERD.Card.Ndef, ERD.Card.MagStripe.Tracks,
  ERD.Card.Memory, ERD.Card.Memory.Counter, ERD.Card.Memory.Sle4404, ERD.Card.Memory.Capabilities,
  ERD.Card.MagStripe, ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL;

type
  TDemoOperations = class(TInterfacedObject, ICardDemoOperations)
  private
    procedure Validate(const R: TCardDemoRequest);
    procedure RunTracks(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure RunMemory(const R: TCardDemoRequest; const Card: TSmartCardReader;
      var D: TCardDemoResult);
    procedure RunCard(const R: TCardDemoRequest; const Card: TSmartCardReader;
      var D: TCardDemoResult);
  public
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure TDemoOperations.Validate(const R: TCardDemoRequest);
var T: TMagStripeTrack; Message: TNdefMessage; L: TMemoryCardLayout;
  Capabilities: TAcsMemoryCapabilities; CounterWire: TBytes;
begin
  if (Ord(R.Operation) < Ord(Low(TCardDemoOperation))) or
    (Ord(R.Operation) > Ord(High(TCardDemoOperation))) then
    raise EArgumentException.Create('Unknown demo operation.');
  if R.Operation in [cdoUid, cdoBelgianEid, cdoIcao, cdoEmvPse, cdoEmvPpse,
    cdoDesfireVersion, cdoType2Read, cdoType4Read, cdoType2Write, cdoType4Write,
    cdoReaderStatus, cdoMemorySnapshot, cdoMemoryRead, cdoMemoryVerify, cdoMemoryWrite, cdoCounterRead, cdoSle4404Read] then
    if Trim(R.ReaderName) = '' then raise EArgumentException.Create('Select an exact reader name.');
  if R.Operation in [cdoMemoryCapabilities, cdoMemorySnapshot, cdoMemoryRead,
    cdoMemoryVerify, cdoMemoryWrite, cdoCounterRead, cdoSle4404Read] then
  begin
    Capabilities := TAcsMemoryCapabilityCatalog.ForDialect(R.MemoryDialect);
    if (R.Operation = cdoCounterRead) and not (R.CounterModel in Capabilities.CounterModels) then
      raise EArgumentException.Create('Counter cards require the ACR38x CCID profile.');
    if (R.Operation = cdoSle4404Read) and not (sfPublicRead in Capabilities.Sle4404Features) then
      raise EArgumentException.Create('SLE4404 requires the ACR38x CCID profile.');
  end;
  if R.Operation in [cdoMemorySnapshot, cdoMemoryRead, cdoMemoryVerify, cdoMemoryWrite] then
  begin
    L := TMemoryCardCodec.Layout(R.MemoryModel);
    if not (R.MemoryPageSize in [mps8..mps128]) then
      raise EArgumentException.Create('Select a supported physical page size.');
    if (R.MinimumPinAttempts < 1) or (R.MinimumPinAttempts > 8) then
      raise EArgumentException.Create('Minimum PIN attempts must be 1..8.');
    if R.Operation in [cdoMemoryVerify, cdoMemoryWrite] then
      if (Length(R.Password) <> L.PinBytes) or
        ((R.Operation = cdoMemoryVerify) and (L.PinBytes = 0)) then
        raise EArgumentException.Create('Supply the exact card-order PIN for the selected model.');
    if R.Operation in [cdoMemoryRead, cdoMemoryWrite] then
    begin
      if (R.MemoryAddress < 0) or (R.MemoryAddress >= L.Capacity) then
        raise EArgumentException.Create('Memory address is outside the selected chip.');
      if R.Operation = cdoMemoryRead then
      begin
        if (R.MemoryCount < 1) or (R.MemoryCount > L.Capacity - R.MemoryAddress) then
          raise EArgumentException.Create('Memory read exceeds the selected chip.');
      end
      else if (Length(R.MemoryBytes) < 1) or
        (Length(R.MemoryBytes) > L.Capacity - R.MemoryAddress) then
        raise EArgumentException.Create('Memory write exceeds the selected chip.');
    end;
  end;
  if R.Operation = cdoSle4404Read then
    if (R.CounterReadableBytes < 1) or (R.CounterReadableBytes > 256) or
      (R.MemoryAddress < 0) or (R.MemoryAddress >= R.CounterReadableBytes) or
      (R.MemoryCount < 1) or (R.MemoryCount > R.CounterReadableBytes - R.MemoryAddress) then
      raise EArgumentException.Create('Supply a valid SLE4404 readable window and range.');
  if R.Operation = cdoCounterRead then
  begin
    CounterWire := TSleCounterCodec.Select(R.CounterModel);
    if Length(CounterWire) <> 6 then raise EArgumentException.Create('Invalid counter selector.');
    if (R.CounterReadableBytes < 1) or (R.CounterReadableBytes > 256) or
      (R.MemoryAddress < 0) or (R.MemoryAddress >= R.CounterReadableBytes) or
      (R.MemoryCount < 1) or (R.MemoryCount > R.CounterReadableBytes - R.MemoryAddress) then
      raise EArgumentException.Create('Supply a valid counter-card readable window and range.');
  end;
  if R.Operation in [cdoType2Read, cdoType2Write] then
    if (Ord(R.Type2Model) < Ord(Low(TType2TagModel))) or
      (Ord(R.Type2Model) > Ord(High(TType2TagModel))) then
      raise EArgumentException.Create('Select a Type 2 model.');
  if R.Operation in [cdoType2Write, cdoType4Write, cdoNdefInspect] then
  begin
    Message := TNdefCodec.Decode(R.NdefBytes);
    if Length(Message) = 0 then raise EArgumentException.Create('Supply a complete NDEF message.');
  end;
  if R.Operation = cdoIcao then
  begin
    if not (R.Security in [iasBac, iasPaceGmAes128]) then
      raise EArgumentException.Create('Select BAC or PACE explicitly.');
    if not (R.PaceCurve in [ppcNistP256, ppcBrainpoolP256]) then
      raise EArgumentException.Create('Select a supported PACE curve.');
    if (R.Security = iasBac) and (R.PasswordKind <> ipkMrz) then
      raise EArgumentException.Create('BAC requires MRZ information.');
    TIcaoAccessCodec.ValidatePassword(R.Password, R.PasswordKind);
  end;
  if R.Operation in [cdoTrackInspect, cdoTrackRead, cdoTrackWrite] then
  begin
    if R.TrackSelection = [] then raise EArgumentException.Create('Select at least one track.');
    if R.Operation in [cdoTrackRead, cdoTrackWrite] then
    begin
      if Trim(R.PortName) = '' then raise EArgumentException.Create('Supply a COM port.');
      if (R.TimeoutMs < 1) or (R.TimeoutMs > 600000) then
        raise EArgumentException.Create('Timeout must be 1..600000 milliseconds.');
    end;
    if R.Operation in [cdoTrackInspect, cdoTrackWrite] then
      for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
        if T in R.TrackSelection then
        begin
          TMagStripeTrackCodec.ValidatePayload(T, R.Tracks[T]);
          if (R.Operation = cdoTrackWrite) and (R.Tracks[T] = '') then
            raise EArgumentException.Create('Selected write tracks cannot be empty.');
        end;
    if (R.Operation = cdoTrackWrite) and not (R.Coercivity in [mscLow, mscHigh]) then
      raise EArgumentException.Create('Select low or high coercivity explicitly.');
  end;
end;

procedure TDemoOperations.RunTracks(const R: TCardDemoRequest; var D: TCardDemoResult);
var Writer: TMagStripeReaderWriter; T: TMagStripeTrack; Bits: TBytes;
begin
  if R.Operation = cdoTrackInspect then
  begin
    for T := Low(TMagStripeTrack) to High(TMagStripeTrack) do
      if T in R.TrackSelection then
      begin
        Bits := TMagStripeTrackCodec.EncodeBits(T, R.Tracks[T]);
        D.Text := D.Text + 'Track ' + UnicodeString(IntToStr(Ord(T) + 1)) + ': ' +
          UnicodeString(IntToStr(Length(R.Tracks[T]))) + ' characters, ' + UnicodeString(IntToStr(Length(Bits))) +
          ' bits including parity and LRC.' + #13#10;
      end;
    Exit;
  end;
  Writer := TMagStripeReaderWriter.Create(nil);
  try
    Writer.Device := TMsr2067HLMagStripeAdapter.Create(
      CreateWindowsMagStripeSerialPort(R.PortName, mssf7O1));
    Writer.TimeoutMs := R.TimeoutMs;
    if R.Operation = cdoTrackWrite then
    begin
      D.Tracks := Writer.WriteTracks(R.TrackSelection, R.Tracks, R.Coercivity);
      D.WriteVerified := True;
      D.Text := 'Selected tracks written and independently verified.';
    end
    else
    begin
      D.Tracks := Writer.ReadTracks(R.TrackSelection);
      D.Text := 'Swipe acquired; payloads shown in the track fields.';
    end;
  finally Writer.Free; end;
end;

procedure TDemoOperations.RunMemory(const R: TCardDemoRequest;
  const Card: TSmartCardReader; var D: TCardDemoResult);
var Memory: TMemoryCardReaderWriter; Counter: TSleCounterCardReaderWriter;
  Sle4404: TSle4404CardReaderWriter;
begin
  if R.Operation = cdoSle4404Read then
  begin
    Sle4404 := TSle4404CardReaderWriter.Create(nil);
    try
      Sle4404.ReadableBytes := R.CounterReadableBytes; Sle4404.Transport := Card.Transport;
      D.CounterBytes := Sle4404.ReadMemory(R.MemoryAddress, R.MemoryCount, nil);
      D.Text := 'SLE4404 public memory read; no code presentation, programming or erasing.';
    finally Sle4404.Free; end;
    Exit;
  end;
  if R.Operation = cdoCounterRead then
  begin
    Counter := TSleCounterCardReaderWriter.Create(nil);
    try
      Counter.Model := R.CounterModel; Counter.ReadableBytes := R.CounterReadableBytes;
      Counter.Transport := Card.Transport;
      D.CounterBytes := Counter.ReadMemory(R.MemoryAddress, R.MemoryCount);
      D.Text := 'Counter public memory read; no code presentation or counter update.';
    finally Counter.Free; end;
    Exit;
  end;
  Memory := TMemoryCardReaderWriter.Create(nil);
  try
    Memory.Model := R.MemoryModel; Memory.Dialect := R.MemoryDialect;
    Memory.PageSize := R.MemoryPageSize; Memory.MinimumPinAttempts := R.MinimumPinAttempts;
    Memory.Transport := Card.Transport; D.Memory.Model := R.MemoryModel;
    case R.Operation of
      cdoMemorySnapshot:
        begin
          D.Memory := Memory.ReadSnapshot;
          D.Text := 'Main memory and protection acquired without a PIN attempt.';
        end;
      cdoMemoryRead:
        begin
          D.Memory.Data := Memory.ReadMemory(R.MemoryAddress, R.MemoryCount);
          D.Text := 'Selected main-memory range acquired.';
        end;
      cdoMemoryVerify:
        begin
          D.Memory.Security := Memory.VerifyPin(R.Password); D.Memory.HasSecurity := True;
          D.Text := 'Supplied PIN verified once. Authentication is not retained for a later request.';
        end;
      cdoMemoryWrite:
        begin
          try Memory.WriteMemory(R.MemoryAddress, R.MemoryBytes, R.Password);
          except
            on E: EMemoryCardWriteUncertain do
            begin D.WriteVerified := E.Verified; raise; end;
          end;
          D.WriteVerified := True;
          D.Text := 'Requested memory state independently verified; identical bytes need no write or PIN attempt.';
        end;
    end;
  finally Memory.Free; end;
end;

procedure TDemoOperations.RunCard(const R: TCardDemoRequest;
  const Card: TSmartCardReader; var D: TCardDemoResult);
var Contactless: TContactlessCardReader; Belgian: TBelgianEIDReader;
  Icao: TICAODocumentReader; Emv: TEMVCardReader; Desfire: TDesfireCardReader;
  Type2: TType2NdefCardReader; Type4: TType4NdefCardReader;
  BelgianData: TBelgianEidData; IcaoData: TIcaoDocumentData;
  Directory: TEmvDirectoryData; Version: TDesfireVersion;
  Snapshot2: TType2NdefSnapshot; Snapshot4: TType4NdefSnapshot;
  Message: TNdefMessage; I: Integer;
begin
  if R.Operation in [cdoMemorySnapshot, cdoMemoryRead, cdoMemoryVerify, cdoMemoryWrite, cdoCounterRead, cdoSle4404Read] then
  begin RunMemory(R, Card, D); Exit; end;
  case R.Operation of
    cdoReaderStatus:
      begin
        D.Text := 'ATR: ' + UnicodeString(BytesToHex(Card.ReadAtr)) + #13#10;
        if Card.Protocol = pcpT0 then D.Text := D.Text + 'Negotiated protocol: T=0.'
        else D.Text := D.Text + 'Negotiated protocol: T=1.';
        D.Text := D.Text + #13#10 + 'This does not establish memory, RF or write capabilities.';
      end;
    cdoUid:
      begin
        Contactless := TContactlessCardReader.Create(nil);
        try
          Contactless.Transport := Card.Transport;
          Contactless.Profile := TPcscStorageProfile.Create;
          D.Text := 'UID: ' + UnicodeString(BytesToHex(Contactless.ReadUid));
        finally Contactless.Free; end;
      end;
    cdoBelgianEid:
      begin
        Belgian := TBelgianEIDReader.Create(nil);
        try
          Belgian.Transport := Card.Transport;
          BelgianData := Belgian.ReadCard;
          D.Text := BelgianData.Identity.GivenNames + ' ' + BelgianData.Identity.Surname + #13#10 +
            'Birth date: ' + BelgianData.Identity.BirthDate + #13#10 +
            BelgianData.Address.StreetAndNumber + #13#10 +
            BelgianData.Address.PostalCode + ' ' + BelgianData.Address.Municipality;
          D.Photo := BelgianData.Photo;
        finally Belgian.Free; end;
      end;
    cdoIcao:
      begin
        Icao := TICAODocumentReader.Create(nil);
        try
          Icao.Transport := Card.Transport;
          Icao.Security := R.Security; Icao.PasswordKind := R.PasswordKind;
          Icao.PaceCurve := R.PaceCurve; Icao.AccessPassword := R.Password;
          Icao.CryptoProvider := TCardEacOpenSslProvider.Create(R.CryptoLibrary);
          IcaoData := Icao.ReadDocument;
          D.Text := IcaoData.Identity.GivenNames + ' ' + IcaoData.Identity.Surname + #13#10 +
            'Access completed; issuer authenticity has not been verified.' + #13#10 +
            'Face images: ' + UnicodeString(IntToStr(Length(IcaoData.Biometrics.Images)));
          if Length(IcaoData.Biometrics.Images) > 0 then
          begin
            D.Photo := IcaoData.Biometrics.Images[0].Data;
            D.PhotoIsJpeg2000 := IcaoData.Biometrics.Images[0].Format = iffJpeg2000;
          end;
        finally Icao.Free; end;
      end;
    cdoEmvPse, cdoEmvPpse:
      begin
        Emv := TEMVCardReader.Create(nil);
        try
          Emv.Transport := Card.Transport;
          if R.Operation = cdoEmvPse then Directory := Emv.DiscoverApplications(edContactPse)
          else Directory := Emv.DiscoverApplications(edContactlessPpse);
          if not Directory.Present then D.Text := 'Selected directory is absent.'
          else D.Text := 'Applications: ' + UnicodeString(IntToStr(Length(Directory.Applications)));
          for I := 0 to High(Directory.Applications) do
            D.Text := D.Text + #13#10 + 'AID: ' + UnicodeString(BytesToHex(Directory.Applications[I].Aid));
        finally Emv.Free; end;
      end;
    cdoDesfireVersion:
      begin
        Desfire := TDesfireCardReader.Create(nil);
        try
          Desfire.Transport := Card.Transport;
          Version := Desfire.ReadVersion;
          D.Text := 'Vendor: ' + UnicodeString(IntToHex(Version.Vendor, 2)) + #13#10 +
            'Hardware/software major: ' + UnicodeString(IntToStr(Version.HardwareMajor)) + '/' +
            UnicodeString(IntToStr(Version.SoftwareMajor));
        finally Desfire.Free; end;
      end;
    cdoType2Read, cdoType2Write:
      begin
        Type2 := TType2NdefCardReader.Create(nil);
        try
          Type2.Transport := Card.Transport; Type2.Profile := TPcscStorageProfile.Create;
          if R.Operation = cdoType2Write then
          begin
            Message := TNdefCodec.Decode(R.NdefBytes);
            Type2.WriteMessage(R.Type2Model, Message);
            D.WriteVerified := True;
            D.NdefBytes := TNdefCodec.Encode(Message);
            D.Text := 'Type 2 NDEF replaced and verified.';
          end
          else
          begin
            Snapshot2 := Type2.ReadMessage(R.Type2Model);
            D.NdefBytes := Snapshot2.MessageBytes;
            D.Text := 'Type 2 NDEF records: ' + UnicodeString(IntToStr(Length(Snapshot2.Records)));
          end;
        finally Type2.Free; end;
      end;
    cdoType4Read, cdoType4Write:
      begin
        Type4 := TType4NdefCardReader.Create(nil);
        try
          Type4.Transport := Card.Transport;
          if R.Operation = cdoType4Write then
          begin
            Message := TNdefCodec.Decode(R.NdefBytes);
            Type4.WriteMessage(Message);
            D.WriteVerified := True;
            D.NdefBytes := TNdefCodec.Encode(Message);
            D.Text := 'Type 4 NDEF replaced and verified.';
          end
          else
          begin
            Snapshot4 := Type4.ReadMessage;
            D.NdefBytes := Snapshot4.MessageBytes;
            D.Text := 'Type 4 NDEF records: ' + UnicodeString(IntToStr(Length(Snapshot4.Records)));
          end;
        finally Type4.Free; end;
      end;
  else raise EArgumentException.Create('Unknown card operation.');
  end;
end;

procedure TDemoOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var Card: TSmartCardReader; Message: TNdefMessage; Capabilities: TAcsMemoryCapabilities;
  Model: TMemoryCardModel; CounterModel: TSleCounterModel;
begin
  Validate(ARequest);
  if ARequest.Operation = cdoMemoryCapabilities then
  begin
    Capabilities := TAcsMemoryCapabilityCatalog.ForDialect(ARequest.MemoryDialect);
    AResult.Text := 'Offline capabilities of the explicitly selected ACS profile.' + #13#10 +
      'Actual reader/firmware support is not detected or certified.';
    for Model := Low(TMemoryCardModel) to High(TMemoryCardModel) do
    begin
      AResult.Text := AResult.Text + #13#10 + UnicodeString(TAcsMemoryCapabilityCatalog.ModelName(Model)) + ': read / verified write';
      if Model in Capabilities.PinModels then AResult.Text := AResult.Text + ' / supplied PIN';
      if Model in Capabilities.PinChangeModels then AResult.Text := AResult.Text + ' / PIN change';
      if Model in Capabilities.ProtectionModels then AResult.Text := AResult.Text + ' / irreversible lock';
    end;
    for CounterModel := Low(TSleCounterModel) to High(TSleCounterModel) do
      if CounterModel in Capabilities.CounterModels then
        AResult.Text := AResult.Text + #13#10 + UnicodeString(TAcsMemoryCapabilityCatalog.CounterName(CounterModel)) + ': counter read / verified bit and carry write';
    if sfPublicRead in Capabilities.Sle4404Features then
      AResult.Text := AResult.Text + #13#10 + 'SLE4404: public/code read / verified bit programming / supplied user-code proof / explicit scratch and application erase';
    Exit;
  end;
  if ARequest.Operation in [cdoTrackInspect, cdoTrackRead, cdoTrackWrite] then
  begin RunTracks(ARequest, AResult); Exit; end;
  if ARequest.Operation = cdoNdefInspect then
  begin
    Message := TNdefCodec.Decode(ARequest.NdefBytes);
    AResult.NdefBytes := Copy(ARequest.NdefBytes, 0, Length(ARequest.NdefBytes));
    AResult.Text := 'NDEF records: ' + UnicodeString(IntToStr(Length(Message)));
    Exit;
  end;
  Card := TSmartCardReader.Create(nil);
  try
    if ARequest.Operation = cdoReaders then
    begin
      AResult.Readers := Card.ListReaders;
      AResult.Text := 'Readers: ' + UnicodeString(IntToStr(Length(AResult.Readers)));
      Exit;
    end;
    Card.ReaderName := ARequest.ReaderName;
    Card.ShareMode := psmExclusive;
    Card.Connect;
    try
      RunCard(ARequest, Card, AResult);
    except
      try Card.Disconnect; except { Preserve the original operation exception. } end;
      raise;
    end;
    Card.Disconnect;
  finally Card.Free; end;
end;

function CreateCardDemoOperations: ICardDemoOperations;
begin
  Result := TDemoOperations.Create;
end;

end.
