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
  ERD.Card.MagStripe, ERD.Card.MagStripe.Serial, ERD.Card.MagStripe.MSR2067HL;

type
  TDemoOperations = class(TInterfacedObject, ICardDemoOperations)
  private
    procedure Validate(const R: TCardDemoRequest);
    procedure RunTracks(const R: TCardDemoRequest; var D: TCardDemoResult);
    procedure RunCard(const R: TCardDemoRequest; const Card: TSmartCardReader;
      var D: TCardDemoResult);
  public
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure TDemoOperations.Validate(const R: TCardDemoRequest);
var T: TMagStripeTrack; Message: TNdefMessage;
begin
  if (Ord(R.Operation) < Ord(Low(TCardDemoOperation))) or
    (Ord(R.Operation) > Ord(High(TCardDemoOperation))) then
    raise EArgumentException.Create('Unknown demo operation.');
  if R.Operation in [cdoUid, cdoBelgianEid, cdoIcao, cdoEmvPse, cdoEmvPpse,
    cdoDesfireVersion, cdoType2Read, cdoType4Read, cdoType2Write, cdoType4Write] then
    if Trim(R.ReaderName) = '' then raise EArgumentException.Create('Select an exact reader name.');
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
  case R.Operation of
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
var Card: TSmartCardReader; Message: TNdefMessage;
begin
  Validate(ARequest);
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
