unit ERD.Card.Demo.Inspections;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses ERD.Card.Demo.Job, ERD.Card.Demo.Workflows;

/// <summary>Creates nonvisual workers for the three independent inspection DFM forms.</summary>
/// <param name="AReaders">Optional inactive injectable reader factory; nil uses native PC/SC.</param>
/// <returns>Request executor and hardware-free request validator.</returns>
function CreateCardInspectionOperations(const AReaders: ICardWorkflowDemoReaders = nil): ICardDemoOperations;

implementation

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Crypto.EAC.OpenSSL, ERD.Card.Transport,
  ERD.Card.Workflow, ERD.Card.Inspection, ERD.Card.EID.Reader, ERD.Card.EID.Data,
  ERD.Card.EID.DocumentReader, ERD.Card.EID.Access, ERD.Card.Crypto.EAC,
  ERD.Card.EID.Inspection, ERD.Card.EMV.Reader, ERD.Card.EMV.Data, ERD.Card.EMV.Inspection,
  ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Report,
  ERD.Card.MOBIB.Lookup, ERD.Card.MOBIB.Inspection;

type
  TOperations = class(TInterfacedObject, ICardDemoOperations, ICardDemoRequestValidator)
  private
    Readers: ICardWorkflowDemoReaders;
    Log: UnicodeString;
    function Build(const ARequest: TCardDemoRequest; const AExecuting: Boolean): TCardInspectionWorkflow;
    procedure Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
    procedure Section(Sender: TObject);
  public
    function TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
    procedure Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
  end;

function ConfigNumber(const L: TStringList; const Key: string; const Default: Integer): Integer;
begin
  Result := Default;
  if L.IndexOfName(Key) >= 0 then
    if not TryStrToInt(L.Values[Key], Result) then raise ECardWorkflowError.Create('Invalid numeric inspection option.');
end;
function ConfigFlag(const L: TStringList; const Key: string; const Default: Integer): Boolean;
var N: Integer;
begin
  N := ConfigNumber(L, Key, Default);
  if not (N in [0, 1]) then raise ECardWorkflowError.Create('Boolean options require 0 or 1.');
  Result := N = 1;
end;

function TOperations.Build(const ARequest: TCardDemoRequest; const AExecuting: Boolean): TCardInspectionWorkflow;
var L, Aids: TStringList; T: ICardTransport; B: TBelgianEIDReader; Icao: TICAODocumentReader;
  E: TEMVCardReader; M: TCalypsoCardReader; Apps: TEmvInspectionApplications;
  O: TEmvInspectionOptions; MO: TMobibReportOptions; I, J, K, N: Integer;
begin
  Result := nil;
  if (ARequest.Operation <> cdoFamily) or (ARequest.ReaderName = '') or
    (Length(ARequest.Arguments) <> 3) or (Length(ARequest.Credentials) <> 1) or
    (Length(ARequest.Arguments[0]) > 65536) or not (ARequest.FamilyAction in [0 .. 3]) then
    raise ECardWorkflowError.Create('Choose a reader and explicit inspection profile.');
  if not ((ARequest.Arguments[1] = '0') or (ARequest.Arguments[1] = '1')) or
    not ((ARequest.Arguments[2] = '0') or (ARequest.Arguments[2] = '1')) then
    raise ECardWorkflowError.Create('Invalid export options.');
  L := TStringList.Create; Aids := TStringList.Create;
  try
    try
    L.Text := string(ARequest.Arguments[0]);
    for I := 0 to L.Count - 1 do
    begin
      if Trim(L[I]) = '' then Continue;
      if Pos('=', L[I]) < 2 then raise ECardWorkflowError.Create('Configuration requires key=value lines.');
      for J := 0 to I - 1 do if SameText(L.Names[I], L.Names[J]) then raise ECardWorkflowError.Create('Duplicate configuration option.');
      if ARequest.FamilyName = 'EidInspectionDemo' then
        N := Ord(SameText(L.Names[I], 'library'))
      else if ARequest.FamilyName = 'EmvInspectionDemo' then
        N := Ord((L.Names[I] = 'aids')  or (L.Names[I] = 'counters') or
          (L.Names[I] = 'log') or (L.Names[I] = 'scan') or (L.Names[I] = 'firstSfi') or
          (L.Names[I] = 'lastSfi') or (L.Names[I] = 'firstRecord') or (L.Names[I] = 'lastRecord') or
          (L.Names[I] = 'maxRecords') or (Copy(L.Names[I], 1, 5) = 'pdol.'))
      else if ARequest.FamilyName = 'MobibInspectionDemo' then
        N := Ord((L.Names[I] = 'dialect') or (L.Names[I] = 'context') or (L.Names[I] = 'records') or
          (L.Names[I] = 'recordBytes') or (L.Names[I] = 'recordSizeFromCard') or (L.Names[I] = 'application'))
      else raise ECardWorkflowError.Create('Unknown inspection demo.');
      if N = 0 then raise ECardWorkflowError.Create('Unknown inspection option.');
    end;
    T := Readers.CreateTransport(ARequest.ReaderName);
    if ARequest.FamilyName = 'EidInspectionDemo' then
    begin
      Result := TEidInspectionWorkflow.Create(nil);
      if ARequest.FamilyAction = 0 then
      begin
        B := TBelgianEIDReader.Create(nil);
        try B.Transport := T; TEidInspectionWorkflow(Result).PrepareBelgian(B, [esIdentity, esAddress, esPhoto, esSignatures, esCertificates]);
        finally B.Free; end;
      end
      else
      begin
        Icao := TICAODocumentReader.Create(nil);
        try
          Icao.Transport := T; Icao.AccessPassword := ARequest.Credentials[0];
          if ARequest.FamilyAction = 1 then begin Icao.Security := iasBac; Icao.PasswordKind := ipkMrz; end
          else begin Icao.Security := iasPaceGmAes128; Icao.PasswordKind := ipkCan;
            if ARequest.FamilyAction = 2 then Icao.PaceCurve := ppcNistP256 else Icao.PaceCurve := ppcBrainpoolP256; end;
          if AExecuting and (Length(ARequest.Credentials[0]) > 0) then Icao.CryptoProvider := TCardEacOpenSslProvider.Create(L.Values['library']);
          TEidInspectionWorkflow(Result).PrepareIcao(Icao, [idsIdentity, idsFace, idsCommon, idsSecurityObject]);
        finally Icao.Free; end;
      end;
    end
    else if ARequest.FamilyName = 'EmvInspectionDemo' then
    begin
      if ARequest.FamilyAction > 2 then raise ECardWorkflowError.Create('Invalid EMV action.');
      O := Default(TEmvInspectionOptions); O.ReadDirectory := True;
      if ARequest.FamilyAction = 1 then O.Directory := edContactPse else O.Directory := edContactlessPpse;
      O.ReadCounters := ConfigFlag(L, 'counters', 1); O.ReadLog := ConfigFlag(L, 'log', 1);
      O.ScanRecords := ConfigFlag(L, 'scan', 0);
      O.FirstSfi := ConfigNumber(L, 'firstSfi', 1); O.LastSfi := ConfigNumber(L, 'lastSfi', 10);
      O.FirstRecord := ConfigNumber(L, 'firstRecord', 1); O.LastRecord := ConfigNumber(L, 'lastRecord', 10);
      Apps := nil;
      if ARequest.FamilyAction <> 0 then
      begin
        Aids.StrictDelimiter := True; Aids.Delimiter := ';'; Aids.DelimitedText := L.Values['aids'];
        if (Aids.Count < 1) or (Aids.Count > 16) then raise ECardWorkflowError.Create('Supply one through sixteen exact AIDs.');
        SetLength(Apps, Aids.Count);
        for I := 0 to High(Apps) do
        begin
          Apps[I].Aid := HexToBytes(Aids[I]);
          for J := 0 to L.Count - 1 do if Copy(L.Names[J], 1, 5) = 'pdol.' then
          begin
            K := Length(Apps[I].TerminalValues); SetLength(Apps[I].TerminalValues, K + 1);
            Apps[I].TerminalValues[K].Tag := HexToBytes(Copy(L.Names[J], 6, Length(L.Names[J])));
            Apps[I].TerminalValues[K].Value := HexToBytes(L.ValueFromIndex[J]);
          end;
        end;
      end;
      E := TEMVCardReader.Create(nil);
      try
        E.Transport := T; E.MaxRecords := ConfigNumber(L, 'maxRecords', 256);
        Result := TEmvInspectionWorkflow.Create(nil); TEmvInspectionWorkflow(Result).PrepareEmv(E, Apps, O);
      finally E.Free; end;
    end
    else if ARequest.FamilyName = 'MobibInspectionDemo' then
    begin
      if ARequest.FamilyAction > 1 then raise ECardWorkflowError.Create('Invalid MOBIB layout.');
      MO := TMobibReport.DefaultOptions; N := ConfigNumber(L, 'context', 0);
      if not (N in [0 .. 4]) then raise ECardWorkflowError.Create('Invalid operator context.');
      MO.Context := TMobibOperatorContext(N);
      M := TCalypsoCardReader.Create(nil);
      try
        M.Transport := T; N := ConfigNumber(L, 'dialect', 0);
        if not (N in [0, 1]) then raise ECardWorkflowError.Create('Invalid Calypso dialect.');
        M.Dialect := TCalypsoDialect(N); M.RecordBytes := ConfigNumber(L, 'recordBytes', 29);
        M.RecordSizeFromCard := ConfigFlag(L, 'recordSizeFromCard', 0); M.ApplicationName := L.Values['application'];
        Result := TMobibInspectionWorkflow.Create(nil);
        TMobibInspectionWorkflow(Result).PrepareMobib(M, TCalypsoCardReader.MobibInventoryPlan,
          TMobibLayout(ARequest.FamilyAction), MO, ConfigNumber(L, 'records', 16));
      finally M.Free; end;
    end
    else raise ECardWorkflowError.Create('Unknown inspection demo.');
    Result.CheckPrepared;
  except Result.Free; Result := nil; raise;
  end;
  finally Aids.Free; L.Free; end;
end;

function TOperations.TryValidateRequest(const ARequest: TCardDemoRequest; out AError: UnicodeString): Boolean;
var W: TCardInspectionWorkflow;
begin
  W := nil; AError := ''; Result := False;
  try
    try W := Build(ARequest, False); Result := True;
    except on E: Exception do AError := UnicodeString(E.ClassName + ': check explicit inspection inputs.'); end;
  finally W.Free; end;
end;
procedure TOperations.Progress(Sender: TObject; const AState: TCardWorkflowState; const ADone, ATotal: Integer);
begin Log := Log + UnicodeString(CardWorkflowStateName(AState) + ' ' + IntToStr(ADone) + '/' + IntToStr(ATotal)) + #13#10; end;
procedure TOperations.Section(Sender: TObject);
var W: TCardInspectionWorkflow; R: TCardInspectionReport;
begin
  W := TCardInspectionWorkflow(Sender); R := W.Report;
  if W.CurrentSection >= 0 then Log := Log + R.Sections[W.CurrentSection].Caption + #13#10;
end;
procedure TOperations.Run(const ARequest: TCardDemoRequest; var AResult: TCardDemoResult);
var W: TCardInspectionWorkflow; O: TCardInspectionExportOptions; R: TCardInspectionReport; S: UnicodeString;
begin
  W := Build(ARequest, True);
  try
    Log := ''; W.OnProgress := Progress; W.OnSectionRead := Section;
    AResult.Success := W.Execute = cwsCompleted; AResult.ErrorClass := W.ErrorClass;
    R := W.Report; O := Default(TCardInspectionExportOptions);
    O.IncludePersonal := ARequest.Arguments[1] = '1'; O.IncludeRaw := ARequest.Arguments[2] = '1';
    AResult.Text := Log + CardInspectionToText(R, O);
    SetLength(AResult.Artifacts, 1); AResult.Artifacts[0].Name := 'inspection.json';
    S := CardInspectionToJson(R, O); AResult.Artifacts[0].Data := TEncoding.UTF8.GetBytes(S);
  finally W.Free; end;
end;
function CreateCardInspectionOperations(const AReaders: ICardWorkflowDemoReaders): ICardDemoOperations;
var O: TOperations;
begin
  O := TOperations.Create; Result := O; O.Readers := AReaders;
  if O.Readers = nil then O.Readers := CreateNativeCardWorkflowDemoReaders;
end;

end.
