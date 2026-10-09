unit ERD.Card.Demo.FamilyOperations;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Families, ERD.Card.Transport,
  ERD.Card.Reader.TWN4, ERD.Card.RFID.Input;

type
  /// <summary>Explicit hardware boundary for family executors, with injectable scripted implementations.</summary>
  ICardFamilyHardware = interface
    ['{E325621B-AC2C-4B6E-9F7C-C5460AB6E611}']
    /// <summary>Connects the exact named PC/SC reader after component preflight.</summary>
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

/// <summary>Creates an inactive worker executor for one separately runnable family.</summary>
/// <param name="AFamily">Explicit family matching the request catalog.</param>
/// <param name="AHardware">Optional injected hardware; nil selects native Windows adapters.</param>
/// <returns>Executor that preflights component arguments before device acquisition.</returns>
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
  ERD.Card.EMV.Data, ERD.Card.EMV.Reader, ERD.Card.EID.Data, ERD.Card.EID.Reader,
  ERD.Card.EID.DocumentReader, ERD.Card.EID.ICAO, ERD.Card.Crypto.EAC, ERD.Card.Crypto.EAC.OpenSSL,
  ERD.Card.EID.Access, ERD.Card.Bytes, ERD.Card.APDU, ERD.Card.ATR, ERD.Card.ATR.Catalog,
  ERD.Card.TLV, ERD.Card.EMV.Tags, ERD.Card.Ndef,
  ERD.Card.Memory, ERD.Card.Memory.Counter, ERD.Card.Memory.Sle4404,
  ERD.Card.SIM.Data, ERD.Card.SIM.Reader, ERD.Card.Memory.Capabilities, ERD.Card.PCSC.Reader,
  ERD.Card.Contactless.Type2.Ndef, ERD.Card.Contactless.Type4.Ndef,
  ERD.Card.Contactless, ERD.Card.Contactless.Type2, ERD.Card.RFID.HID,
  ERD.Card.Reader.TWN4.Serial, ERD.Card.Demo.Operations;

type
  EPreflightComplete = class(Exception);
  TPreflight = class(TInterfacedObject, ICardTransport, ICardTransaction, ITwn4ByteChannel)
  public
    ReachedBoundary: Boolean;
    function Exchange(const ACommand: TBytes): TBytes;
    procedure BeginTransaction;
    procedure EndTransaction;
    procedure Open;
    procedure Close;
    procedure Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
    function ReceiveByte(const ATimeoutMs: Cardinal): Byte;
    function NowMs: UInt64;
  end;
  TNativeHardware = class(TInterfacedObject, ICardFamilyHardware)
  private FReader: TSmartCardReader;
  public
    destructor Destroy; override;
    function AcquireReader(const AName: string): ICardTransport;
    procedure ReleaseReader;
    function CreateTwn4Channel(const APort: string): ITwn4ByteChannel;
  end;
  TFamilyOperations = class(TInterfacedObject, ICardDemoOperations)
  private
    FFamily: TCardDemoFamily;
    FHardware: ICardFamilyHardware;
    procedure Execute(const R: TCardDemoRequest; const A: TCardFamilyAction;
      const T: ICardTransport; const C: ITwn4ByteChannel; var D: TCardDemoResult);
  public
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

procedure Fail;
begin raise EArgumentException.Create('Check the explicit action inputs and acknowledgement.'); end;

procedure Wipe(var B: TBytes);
begin if Length(B) > 0 then FillChar(B[0],Length(B),0); B := nil; end;

function Action(const F: TCardDemoFamily; const R: TCardDemoRequest): TCardFamilyAction;
var Catalog: TCardFamilyActions; I, J, Choices: Integer;
begin
  if (R.Operation <> cdoFamily) or (R.FamilyName <> CardFamilyName(F)) then Fail;
  Catalog := CardFamilyActions(F);
  if (R.FamilyAction < 0) or (R.FamilyAction >= Length(Catalog)) then Fail;
  Result := Catalog[R.FamilyAction];
  if (Length(R.Arguments) <> Length(Result.Fields)) or
    (Length(R.Credentials) <> Length(Result.Fields)) then Fail;
  if Result.Mutation and not R.MutationAcknowledged then Fail;
  if Result.Pcsc and (Trim(R.ReaderName) = '') then Fail;
  for I := 0 to High(Result.Fields) do
  begin
    if Length(R.Arguments[I]) > 262144 then Fail;
    if Result.Fields[I].Secret then
    begin if R.Arguments[I] <> '' then Fail; if Length(R.Credentials[I]) > 64 then Fail; end
    else if Length(R.Credentials[I]) <> 0 then Fail;
    if Result.Fields[I].Choices <> '' then
    begin
      Choices := 1;
      for J := 1 to Length(Result.Fields[I].Choices) do
        if Result.Fields[I].Choices[J] = '|' then Inc(Choices);
      if not TryStrToInt(string(R.Arguments[I]),J) then Fail;
      if (J < 0) or (J >= Choices) then Fail;
    end;
  end;
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

function TPreflight.Exchange(const ACommand: TBytes): TBytes;
begin Result := nil; raise EInvalidOpException.Create('Unexpected preflight I/O.'); end;
procedure TPreflight.BeginTransaction;
begin ReachedBoundary := True; raise EPreflightComplete.Create('Validated.'); end;
procedure TPreflight.EndTransaction;
begin raise EInvalidOpException.Create('Unexpected preflight release.'); end;
procedure TPreflight.Open;
begin ReachedBoundary := True; raise EPreflightComplete.Create('Validated.'); end;
procedure TPreflight.Close;
begin raise EInvalidOpException.Create('Unexpected preflight close.'); end;
procedure TPreflight.Send(const ABytes: TBytes; const ATimeoutMs: Cardinal);
begin raise EInvalidOpException.Create('Unexpected preflight send.'); end;
function TPreflight.ReceiveByte(const ATimeoutMs: Cardinal): Byte;
begin Result := 0; raise EInvalidOpException.Create('Unexpected preflight receive.'); end;
function TPreflight.NowMs: UInt64;
begin Result := 0; end;

destructor TNativeHardware.Destroy;
begin FReader.Free; inherited Destroy; end;
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

procedure TFamilyOperations.Execute(const R: TCardDemoRequest; const A: TCardFamilyAction;
  const T: ICardTransport; const C: ITwn4ByteChannel; var D: TCardDemoResult);
var Emv: TEMVCardReader; Belgian: TBelgianEIDReader; Icao: TICAODocumentReader;
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
  Catalog: TAtrCatalog; Matches: TAtrCatalogMatches; Tag: TEmvTagDescription;
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
            'Encoded: ' + BytesToHex(TApduCodec.EncodeCommand(Apdu)); end
        else if A.Id = 'response' then
        begin Response := TApduCodec.DecodeResponse(Data);
          Output := 'Status: ' + IntToHex(Response.StatusWord,4) + sLineBreak + 'Data: ' + BytesToHex(Response.Data) +
            sLineBreak + 'Encoded: ' + BytesToHex(TApduCodec.EncodeResponse(Response)); end
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
          if TEmvTagCatalog.TryDescribe(TagId,Tag) then Output := Tag.Name + sLineBreak + 'Length metadata: ' + IntToStr(Tag.MinLength) + '..' + IntToStr(Tag.MaxLength) +
            sLineBreak + 'Sensitive data: ' + BoolToStr(Tag.Sensitive,True) + sLineBreak + Tag.Source
          else Output := 'No catalog entry for this tag.';
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
            I := Number(R,A,'type2model',0,5); Address := Number(R,A,'page',0,255); Id := Bytes(R,A,'id');
            if A.Id = 'type2read' then
            begin Data := W.ReadType2UserPage(TType2TagModel(I),Address,Id); Output := BytesToHex(Data); end
            else begin W.WriteType2UserPage(TType2TagModel(I),Address,Id,Bytes(R,A,'before'),Bytes(R,A,'data'));
              D.WriteVerified := True; Output := 'Type 2 page independently verified.'; end;
          end else Fail;
        finally W.Free; end;
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
                Data := TEmvCodec.BuildDolData(nil,Values); Application := Emv.ReadApplication(Id,Values);
              finally Parts.Free; Lines.Free; end;
              Output := 'Name '+string(Application.CardholderName)+' PAN '+string(Application.Pan)+' expiry '+string(Application.ExpiryDate)+' IBAN '+string(Application.Iban)+sLineBreak;
              Artifact(D,'application-fci.bin',Application.Fci); Artifact(D,'gpo.bin',Application.Gpo);
              for I := 0 to High(Application.Records) do Artifact(D,'record-'+IntToStr(Application.Records[I].Sfi)+'-'+IntToStr(Application.Records[I].Number)+'.bin',Application.Records[I].RawData);
              for I := 0 to High(Application.Fields) do Output := Output+BytesToHex(Application.Fields[I].Tag)+'='+BytesToHex(Application.Fields[I].Value)+sLineBreak;
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
            I := Number(R,A,'type2model',0,5);
            if A.Id = 'page' then Output := BytesToHex(Contact.ReadType2Page(TType2TagModel(I),Number(R,A,'page',0,255)))
            else if A.Id = 'memory' then begin UserMemory := Contact.ReadType2UserMemory(TType2TagModel(I)); Output := BytesToHex(UserMemory.Data); end
            else if A.Id = 'writepage' then begin Contact.WriteType2UserPage(TType2TagModel(I),Number(R,A,'page',0,255),Bytes(R,A,'data')); Output := 'Reader write status accepted; independent read-back has not been performed.'; end
            else if A.Id = 'readndef' then begin T2Snapshot := T2.ReadMessage(TType2TagModel(I)); Output := BytesToHex(T2Snapshot.MessageBytes); end
            else if A.Id = 'writendef' then begin Ndef := TNdefCodec.Decode(Bytes(R,A,'ndef')); T2.WriteMessage(TType2TagModel(I),Ndef); D.WriteVerified := True; Output := 'Type 2 NDEF independently verified.'; end
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

procedure TFamilyOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var A: TCardFamilyAction; T: ICardTransport; C: ITwn4ByteChannel;
  P: TPreflight; Probe: TCardDemoResult; H: ICardFamilyHardware; Validated: Boolean;
begin
  A := Action(FFamily,ARequest); AResult := Default(TCardDemoResult); AResult.Operation := cdoFamily;
  if (A.Pcsc and (FFamily <> dfTools)) or (FFamily = dfTwn4) then
  begin
    P := TPreflight.Create; T := P; C := P; Validated := False; Probe := Default(TCardDemoResult);
    try Execute(ARequest,A,T,C,Probe);
    except on E: Exception do
      if P.ReachedBoundary then Validated := True else raise; end;
    T := nil; C := nil;
    if not Validated then raise EInvalidOpException.Create('Component did not reach its acquisition boundary.');
    H := FHardware; if H = nil then H := TNativeHardware.Create;
    if FFamily = dfTwn4 then C := H.CreateTwn4Channel(string(Text(ARequest,A,'port')))
    else T := H.AcquireReader(string(ARequest.ReaderName));
    try
      try Execute(ARequest,A,T,C,AResult);
      except
        on E: EMemoryCardWriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.Verified; raise; end;
        on E: EContactlessWriteUncertain do begin AResult.WriteUncertain := True; raise; end;
        on E: ESimCardWriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.VerifiedReadBack; raise; end;
        on E: ETwn4WriteUncertain do begin AResult.WriteUncertain := True; AResult.WriteVerified := E.VerifiedReadBack; raise; end;
      end;
    except
      if FFamily <> dfTwn4 then try H.ReleaseReader; except end;
      raise;
    end;
    if FFamily <> dfTwn4 then
      try H.ReleaseReader;
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
