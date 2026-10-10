unit ERD.Card.Demo.GlobalPlatform.Operations;

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
  ERD.Card.Demo.Job;

/// <summary>Creates a nonvisual single-request GP executor for the independent designer demo.</summary>
/// <returns>Retained worker operations; no hardware or crypto library opened until Run.</returns>
function CreateGlobalPlatformDemoOperations: ICardDemoOperations;

implementation

uses
  ERD.Card.Bytes, ERD.Card.PCSC.Reader, ERD.Card.APDU, ERD.Card.Crypto,
  ERD.Card.GlobalPlatform, ERD.Card.GlobalPlatform.CAP,
  ERD.Card.GlobalPlatform.SecureChannel, ERD.Card.GlobalPlatform.Management,
  ERD.Card.Crypto.RSA, ERD.Card.Crypto.Hash, ERD.Card.Crypto.RSA.Native,
{$IFDEF MSWINDOWS}
  ERD.Card.Crypto.Windows, ERD.Card.Crypto.Hash.Windows;
{$ELSE}
  ERD.Card.Crypto.OpenSSL, ERD.Card.Crypto.Hash.OpenSSL;
{$ENDIF}

type
  TGpDemoOperations = class(TInterfacedObject, ICardDemoOperations)
  private
    FLog: TStringList;
    procedure Progress(Sender: TObject; const Done, Total: Integer);
  public
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure TGpDemoOperations.Progress(Sender: TObject; const Done, Total: Integer);
begin
  FLog.Add(Format('Acknowledged LOAD: %d / %d bytes', [Done, Total]));
end;

procedure TGpDemoOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var
  Reader: TSmartCardReader;
  Manager: TGlobalPlatformCardManager;
  Cap: TGpCapFile;
  Keys: TGpCardKeys;
  R: TApduResponse;
  Entries: TGpRegistryEntries;
  Fields: TGpCplcFields;
  Domain, LoadHash, Dap, RsaN, RsaE: TBytes;
  NewKeys: TGpCardKeys;
  Hash: ICardHashProvider;
  Rsa: ICardRsaProvider;
  KeyInfo: TGpKeyInformationList;
  Receipt: TGpReceiptVerifier;
  NewVersion, NewId, OldVersion, KeyType, TokenType, ReceiptType, LastCounter: Integer;
  I, Version, KeyId, Lifecycle, BlockSize, Protocol, Level: Integer;
  NeedsAuthentication, WriteAction: Boolean;
begin
  if (ARequest.Operation <> cdoFamily) or (ARequest.FamilyName <> 'GlobalPlatform') or
    (ARequest.FamilyAction < 0) or (ARequest.FamilyAction > 16) or
    (Length(ARequest.Arguments) <> 29) or (Length(ARequest.Credentials) <> 11) then
    raise EArgumentException.Create('Invalid GlobalPlatform demo request.');
  WriteAction := ARequest.FamilyAction in [6..9, 11..16];
  NeedsAuthentication := WriteAction or (ARequest.FamilyAction = 5) or (ARequest.Arguments[15] = '1');
  if NeedsAuthentication and not ARequest.MutationAcknowledged then
    raise EArgumentException.Create('Acknowledge this authentication or management operation.');
  Protocol := StrToInt(string(ARequest.Arguments[1]));
  Level := StrToInt(string(ARequest.Arguments[2]));
  if (Protocol < 0) or (Protocol > 1) or (Level < 0) or (Level > 4) then
    raise EArgumentException.Create('Select an explicit protocol and protection level.');
  Domain := HexToBytes(string(ARequest.Arguments[0]), True);
  Version := StrToInt(string(ARequest.Arguments[3])); KeyId := StrToInt(string(ARequest.Arguments[4]));
  Lifecycle := StrToInt('$' + string(ARequest.Arguments[12]));
  BlockSize := StrToInt(string(ARequest.Arguments[14]));
  if (Version < 0) or (Version > 255) or (KeyId < 0) or (KeyId > 255) or
    (Lifecycle < 0) or (Lifecycle > 255) or
    (Length(Domain) < 5) or (Length(Domain) > 16) then
    raise EArgumentException.Create('Invalid GlobalPlatform input bounds.');
  if (Length(ARequest.Credentials[2]) <> 0) and (Length(ARequest.Credentials[2]) <> 16) then
    raise EArgumentException.Create('Session DEK must be empty or sixteen bytes.');
  if NeedsAuthentication and ((Length(ARequest.Credentials[0]) <> 16) or
    (Length(ARequest.Credentials[1]) <> 16)) then
    raise EArgumentException.Create('Supply explicit sixteen-byte card keys.');
  NewVersion := StrToInt(string(ARequest.Arguments[16])); NewId := StrToInt(string(ARequest.Arguments[17]));
  KeyType := StrToInt(string(ARequest.Arguments[18])); TokenType := StrToInt(string(ARequest.Arguments[19]));
  ReceiptType := StrToInt(string(ARequest.Arguments[20])); LastCounter := StrToInt(string(ARequest.Arguments[22]));
  OldVersion := StrToInt(string(ARequest.Arguments[28]));
  if (NewVersion < 1) or (NewVersion > 127) or (NewId < 1) or (NewId > 127) or
    (OldVersion < 0) or (OldVersion > 127) or (KeyType < 0) or (KeyType > 1) or
    (TokenType < 0) or (TokenType > 2) or (ReceiptType < 0) or (ReceiptType > 2) or
    (LastCounter < -1) or (LastCounter > 65535) then
    raise EArgumentException.Create('Invalid explicit management policy.');
  if ARequest.FamilyAction in [11, 12] then
  begin
    if (Length(ARequest.Credentials[2]) <> 16) or (Length(ARequest.Credentials[3]) <> 16) then
      raise EArgumentException.Create('Symmetric PUT KEY requires DEK and new key.');
    if (ARequest.FamilyAction = 12) and ((NewId > 125) or
      (Length(ARequest.Credentials[4]) <> 16) or (Length(ARequest.Credentials[5]) <> 16)) then
      raise EArgumentException.Create('Supply all three new keys and an explicit first identifier.');
  end;
  if (ARequest.FamilyAction = 13) and (OldVersion = 0) then
    raise EArgumentException.Create('Key deletion requires an exact nonzero version.');
  if (TokenType = 1) and (Length(ARequest.Credentials[6]) <> 16) then
    raise EArgumentException.Create('Supply an AES token key.');
  if (ReceiptType <> 0) and ((Length(ARequest.Credentials[7]) <> 16) or (ARequest.Arguments[21] = '')) then
    raise EArgumentException.Create('Receipt verification requires key and expected card identity.');
  RsaN := HexToBytes(string(ARequest.Arguments[27]), True); RsaE := HexToBytes(string(ARequest.Arguments[26]), True);
  Reader := nil; Manager := nil; Cap := nil; Keys := Default(TGpCardKeys); NewKeys := Default(TGpCardKeys);
  Receipt := nil;
  FLog := TStringList.Create;
  try
    try
    if ARequest.FamilyAction in [6, 7] then
    begin
{$IFDEF FPC}
      raise EGpCapError.Create('Archive import requires Delphi System.Zip.');
{$ELSE}
      Cap := TGpCapFile.FromFile(string(ARequest.Arguments[6]));
{$ENDIF}
      FLog.Add('CAP package: ' + BytesToHex(Cap.PackageAid));
    end;
{$IFDEF MSWINDOWS}
    Hash := TCardWindowsHashProvider.Create;
{$ELSE}
    Hash := TCardOpenSSLHashProvider.Create;
{$ENDIF}
    if TokenType = 2 then Rsa := TCardNativeRsaProvider.Create(Hash, RsaN, RsaE,
      ARequest.Credentials[8], ARequest.Credentials[9], ARequest.Credentials[10]);
    LoadHash := HexToBytes(string(ARequest.Arguments[23]), True);
    Dap := HexToBytes(string(ARequest.Arguments[24]), True);
    if (Cap <> nil) and ((Length(Dap) > 0) or (TokenType <> 0)) and (Length(LoadHash) = 0) then LoadHash := Hash.Sha1(Cap.LoadFileData);
    Reader := TSmartCardReader.Create(nil);
    Reader.ReaderName := ARequest.ReaderName; Reader.Connect;
    Manager := TGlobalPlatformCardManager.Create(nil);
    Manager.Transport := Reader.Transport; Manager.OnLoadProgress := Progress;
    R := Manager.SelectSecurityDomain(Domain);
    if R.StatusWord <> $9000 then raise EGpCardError.CreateStatus(R.StatusWord);
    if NeedsAuthentication then
    begin
{$IFDEF MSWINDOWS}
      Manager.DesProvider := TCardWindowsAesProvider.Create;
{$ELSE}
      Manager.DesProvider := TCardOpenSslAesProvider.Create;
{$ENDIF}
      Manager.AesProvider := Manager.DesProvider;
      Keys.Enc := CopyBytes(ARequest.Credentials[0]); Keys.Mac := CopyBytes(ARequest.Credentials[1]);
      Keys.Dek := CopyBytes(ARequest.Credentials[2]);
      Manager.Authenticate(TGpSecureProtocol(Protocol), Keys,
        Version, KeyId, TGpSecurityLevel(Level), ARequest.Arguments[5] = '1');
      FLog.Add('Secure channel authenticated; keys are not displayed.');
    end;
    if TokenType = 1 then Manager.TokenSigner := TGpAesTokenSigner.Create(Manager.AesProvider, ARequest.Credentials[6]);
    if TokenType = 2 then Manager.TokenSigner := TGpRsaTokenSigner.Create(Rsa);
    if ReceiptType = 1 then Receipt := TGpReceiptVerifier.CreateDes(Manager.DesProvider,
      ARequest.Credentials[7], HexToBytes(string(ARequest.Arguments[21]), True), LastCounter);
    if ReceiptType = 2 then Receipt := TGpReceiptVerifier.CreateAes(Manager.AesProvider,
      ARequest.Credentials[7], HexToBytes(string(ARequest.Arguments[21]), True), LastCounter);
    if Receipt <> nil then Manager.ReceiptVerifier := Receipt;
    AResult.WriteUncertain := WriteAction;
    case ARequest.FamilyAction of
      0:
        begin
          Fields := Manager.ReadCplc;
          for I := 0 to High(Fields) do FLog.Add(Fields[I].Name + ': ' + BytesToHex(Fields[I].Value));
        end;
      1..4:
        begin
          Entries := Manager.GetStatus(TGpRegistryKind(ARequest.FamilyAction - 1), ARequest.Arguments[13] = '1');
          for I := 0 to High(Entries) do
            FLog.Add(Format('AID %s; lifecycle %s; privileges %s; modules %d',
              [BytesToHex(Entries[I].Aid), IntToHex(Entries[I].LifeCycle, 2),
               BytesToHex(Entries[I].Privileges), Length(Entries[I].Modules)]));
          FLog.Add(Format('%d registry entries.', [Length(Entries)]));
        end;
      5: FLog.Add('Authentication complete. This demo closes the session after each action.');
      6: Manager.LoadCap(Cap, Domain, BlockSize, HexToBytes(string(ARequest.Arguments[10]), True), LoadHash, Dap);
      7: Manager.InstallApplet(Cap, HexToBytes(string(ARequest.Arguments[7]), True),
          HexToBytes(string(ARequest.Arguments[8]), True), HexToBytes(string(ARequest.Arguments[9]), True),
          HexToBytes(string(ARequest.Arguments[10]), True));
      8: Manager.DeleteObject(HexToBytes(string(ARequest.Arguments[8]), True), ARequest.Arguments[11] = '1');
      9: Manager.SetStatus(grkApplications, HexToBytes(string(ARequest.Arguments[8]), True), Lifecycle);
      10:
        begin
          KeyInfo := Manager.ReadKeyInformation;
          for I := 0 to High(KeyInfo) do FLog.Add(Format('Key ID %d; version %d; component types/lengths %s',
            [KeyInfo[I].KeyId, KeyInfo[I].Version, BytesToHex(KeyInfo[I].Components)]));
        end;
      11: Manager.PutKey(OldVersion, NewVersion, NewId, ARequest.Credentials[3], KeyType = 1);
      12:
        begin
          NewKeys.Enc := CopyBytes(ARequest.Credentials[3]); NewKeys.Mac := CopyBytes(ARequest.Credentials[4]);
          NewKeys.Dek := CopyBytes(ARequest.Credentials[5]);
          Manager.PutKeySet(OldVersion, NewVersion, NewId, NewKeys, KeyType = 1);
        end;
      13: Manager.DeleteKey(OldVersion, NewId);
      14: Manager.PutRsaPublicKey(OldVersion, NewVersion, NewId, RsaN, RsaE);
      15: Manager.MakeSelectable(HexToBytes(string(ARequest.Arguments[8]), True),
            HexToBytes(string(ARequest.Arguments[9]), True), HexToBytes(string(ARequest.Arguments[7]), True));
      16: Manager.Extradite(HexToBytes(string(ARequest.Arguments[8]), True),
            HexToBytes(string(ARequest.Arguments[7]), True), HexToBytes(string(ARequest.Arguments[25]), True));
    end;
    if WriteAction then
    begin
      FLog.Add('Management operation acknowledged by the card; no automatic rollback or retry.');
      FLog.Add('Last confirmation: ' + BytesToHex(Manager.LastConfirmation));
    end;
    if Receipt <> nil then FLog.Add('Persist last verified receipt counter: ' + IntToStr(Receipt.LastCounter));
    Manager.CloseSession; Reader.Disconnect;
    AResult.WriteUncertain := False;
    AResult.Text := UnicodeString(FLog.Text); AResult.Success := True;
    except
      on E: EGpCardError do
      begin
        AResult.ErrorClass := E.ClassName; AResult.Success := False;
        if E.StatusWord <> 0 then AResult.Text := UnicodeString('Card status: ' + IntToHex(E.StatusWord, 4));
      end;
      on E: EGpSecureChannelError do
      begin
        AResult.ErrorClass := E.ClassName; AResult.Success := False;
        if E.StatusWord <> 0 then AResult.Text := UnicodeString('Authentication status: ' + IntToHex(E.StatusWord, 4));
      end;
      on E: Exception do
      begin
        AResult.ErrorClass := E.ClassName; AResult.Success := False;
      end;
    end;
    if not AResult.Success then
    begin
      if Receipt <> nil then
        FLog.Add('Persist last verified receipt counter: ' + IntToStr(Receipt.LastCounter));
      if FLog.Count > 0 then AResult.Text := AResult.Text + UnicodeString(sLineBreak + FLog.Text);
    end;
  finally
    TCardCrypto.Clear(Keys.Enc); TCardCrypto.Clear(Keys.Mac); TCardCrypto.Clear(Keys.Dek);
    TCardCrypto.Clear(NewKeys.Enc); TCardCrypto.Clear(NewKeys.Mac); TCardCrypto.Clear(NewKeys.Dek);
    Manager.Free; Reader.Free; Cap.Free; FreeAndNil(FLog);
  end;
end;

function CreateGlobalPlatformDemoOperations: ICardDemoOperations;
begin
  Result := TGpDemoOperations.Create;
end;

end.
