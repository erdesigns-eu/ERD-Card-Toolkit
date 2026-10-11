program CardInspectionTests;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$R+}{$Q+}

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Workflow, ERD.Card.Inspection,
  ERD.Card.EMV.Data, ERD.Card.EMV.Reader, ERD.Card.EMV.Inspection,
  ERD.Card.EID.Data, ERD.Card.EID.Reader, ERD.Card.EID.DocumentReader, ERD.Card.EID.Inspection,
  ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Report, ERD.Card.MOBIB.Inspection,
  ERD.Card.Demo.Job, ERD.Card.Demo.Workflows, ERD.Card.Demo.Inspections;

type
  TStep = record
    Command, Response: TBytes;
    Fails: Boolean;
  end;
  TScript = class(TInterfacedObject, ICardTransport, ICardTransaction)
  public
    Steps: array of TStep;
    Position, Begins, Ends: Integer;
    Active, EndFails, BeginFails: Boolean;
    procedure Add(const ACommand, AResponse: string; const AFails: Boolean = False);
    procedure BeginTransaction;
    procedure EndTransaction;
    function Exchange(const ACommand: TBytes): TBytes;
  end;
  TBareTransport = class(TInterfacedObject, ICardTransport)
  public
    function Exchange(const ACommand: TBytes): TBytes;
  end;

const
  AidHex = 'A0000000031010'; // Public scheme AID; no physical account/card fixture.
  SelectHex = '00A4040007' + AidHex + '00';
var
  Checks: Integer = 0;

procedure Check(const AValue: Boolean; const AMessage: string);
begin
  Inc(Checks);
  if not AValue then raise Exception.Create(AMessage);
end;

procedure TScript.Add(const ACommand, AResponse: string; const AFails: Boolean);
var I: Integer;
begin
  I := Length(Steps);
  SetLength(Steps, I + 1);
  Steps[I].Command := HexToBytes(ACommand);
  Steps[I].Response := HexToBytes(AResponse);
  Steps[I].Fails := AFails;
end;

procedure TScript.BeginTransaction;
begin
  Inc(Begins);
  if BeginFails then raise ECardTransportError.Create('synthetic begin failure');
  Check(not Active, 'Exclusive transaction is not nested');
  Active := True;
end;

procedure TScript.EndTransaction;
begin
  Inc(Ends);
  Check(Active, 'Transaction active on release');
  Active := False;
  if EndFails then raise ECardTransportError.Create('synthetic end failure');
end;

function TScript.Exchange(const ACommand: TBytes): TBytes;
begin
  Check(Position < Length(Steps), 'No unexpected APDU or replay');
  Check(BytesEqual(ACommand, Steps[Position].Command), 'Exact APDU at step ' + IntToStr(Position));
  Inc(Position);
  if Steps[Position - 1].Fails then raise ECardTransportError.Create('synthetic exchange failure');
  Result := CopyBytes(Steps[Position - 1].Response);
end;

function TBareTransport.Exchange(const ACommand: TBytes): TBytes;
begin
  Result := nil;
  raise Exception.Create('Bare transport must not be invoked');
end;

function Tlv(const ATag, ABody: string): string;
var N: Integer;
begin
  N := Length(ABody) div 2;
  if N < 128 then Result := ATag + IntToHex(N, 2) + ABody
  else Result := ATag + '81' + IntToHex(N, 2) + ABody;
end;

function Fci(const ADol: string = ''): string;
var Body: string;
begin
  Body := '500454455354';
  if ADol <> '' then Body := Body + Tlv('9F38', ADol);
  Result := Tlv('6F', '8407' + AidHex + Tlv('A5', Body));
end;

function Value(const ATag, AData: string): TEmvValue;
begin
  Result.Tag := HexToBytes(ATag);
  Result.Value := HexToBytes(AData);
end;


type
  TTestInspectionWorkflow = class(TCardInspectionWorkflow);
  TSource = class(TInterfacedObject, ICardInspectionSource)
  public
    Reads, FailAt: Integer;
    Mode: TCardInspectionStatus;
    function Family: string;
    procedure Validate;
    function SectionCount: Integer;
    function Describe(const AIndex: Integer): TCardInspectionSection;
    function ReadSection(const AIndex: Integer): TCardInspectionSection;
  end;
  TObserver = class
  public
    Count, Auth, Partial: Integer;
    CancelAt, RaiseAt: Integer;
    procedure Section(Sender: TObject);
    procedure Authentication(Sender: TObject);
    procedure Incomplete(Sender: TObject);
  end;
  TReaders = class(TInterfacedObject, ICardWorkflowDemoReaders)
  public
    Transport: ICardTransport;
    function CreateTransport(const AName: UnicodeString): ICardTransport;
  end;

function TSource.Family: string;
begin Result := 'Synthetic inspection'; end;
procedure TSource.Validate;
begin end;
function TSource.SectionCount: Integer;
begin Result := 3; end;
function TSource.Describe(const AIndex: Integer): TCardInspectionSection;
begin
  Result := Default(TCardInspectionSection); Result.Key := 'section.' + IntToStr(AIndex);
  Result.Caption := UnicodeString(Result.Key);
end;
function TSource.ReadSection(const AIndex: Integer): TCardInspectionSection;
begin
  Inc(Reads);
  if Reads = FailAt then raise ECardTransportError.Create('Never export this private exception message.');
  Result := Describe(AIndex); Result.Status := Mode;
  if Mode = cisAuthenticationRequired then Result.StatusWord := $6982;
  AddCardInspectionField(Result, 'public', 'Public', 'a"b' + WideChar(92) + #10 + WideChar($00E9));
  AddCardInspectionField(Result, 'personal', 'Personal', 'PRIVATE-NAME', True);
  AddCardInspectionField(Result, 'raw', 'Raw', '', False, True, HexToBytes('FACE'));
  AddCardInspectionField(Result, 'personalRaw', 'Personal raw', '', True, True, HexToBytes('DEADBEEF'));
end;
procedure TObserver.Section(Sender: TObject);
begin
  Inc(Count);
  if Count = CancelAt then TCardInspectionWorkflow(Sender).Cancel;
  if Count = RaiseAt then raise EConvertError.Create('Observer');
end;
procedure TObserver.Authentication(Sender: TObject);
begin Inc(Auth); end;
procedure TObserver.Incomplete(Sender: TObject);
begin Inc(Partial); end;
function TReaders.CreateTransport(const AName: UnicodeString): ICardTransport;
begin Result := Transport; end;

procedure TestLifecycle;
var S: TSource; Source: ICardInspectionSource; W: TCardInspectionWorkflow; O: TObserver;
  T: TScript; Transport: ICardTransport; R, CopyR: TCardInspectionReport;
  Policy: TCardInspectionExportOptions; Json, Text: UnicodeString; I, Fail, Cancel, Mode: Integer; Raised: Boolean;
begin
  for Fail := 0 to 3 do
    for Cancel := 0 to 3 do
      for Mode := Ord(cisRead) to Ord(cisPartial) do
      begin
        S := TSource.Create; Source := S; S.FailAt := Fail; S.Mode := TCardInspectionStatus(Mode);
        T := TScript.Create; Transport := T;
        W := TTestInspectionWorkflow.Create(nil); O := TObserver.Create;
        try
          O.CancelAt := Cancel; O.RaiseAt := 2;
          W.OnSectionRead := O.Section; W.OnAuthenticationRequired := O.Authentication; W.OnPartialRead := O.Incomplete;
          W.Prepare(Source, Transport); Check((S.Reads = 0) and (T.Begins = 0), 'Prepare performs no I/O');
          W.Execute; R := W.Report;
          Check((T.Begins = 1) and (T.Ends = 1), 'One released exclusive transaction');
          Check(R.Complete = ((Fail = 0) and (Cancel = 0) and (Mode = Ord(cisRead))), 'Complete requires every section and no interruption');
          Check(O.Partial = Ord(not R.Complete), 'One incomplete notification');
          Check(O.Count = S.Reads, 'Every attempted section has one retained outcome');
          Check((S.Reads >= 1) and (S.Reads <= 3), 'Bounded acquisition');
          if W.State = cwsFailed then Check(W.ErrorClass = 'ECardTransportError', 'Primary error preserved');
          CopyR := W.Report;
          for I := 0 to High(R.Sections) do
            if Length(R.Sections[I].Fields) > 0 then
            begin
              R.Sections[I].Fields[2].Data[0] := 0;
              Check(CopyR.Sections[I].Fields[2].Data[0] = $FA, 'Independent result byte buffers');
            end;
          Policy := Default(TCardInspectionExportOptions); Json := CardInspectionToJson(CopyR, Policy); Text := CardInspectionToText(CopyR, Policy);
          Check((Pos('PRIVATE-NAME', Json) = 0) and (Pos('DEADBEEF', Json) = 0) and (Pos('FACE', Json) = 0), 'Default JSON excludes personal/raw values');
          Check((Pos('PRIVATE-NAME', Text) = 0) and (Pos('Never export', Text) = 0), 'Text excludes personal/error message');
          if Fail <> 1 then Check(Pos('\u00E9', Json) > 0, 'Unicode escaped in ASCII JSON');
          Policy.IncludeRaw := True; Json := CardInspectionToJson(CopyR, Policy);
          Check(Pos('DEADBEEF', Json) = 0, 'Raw permission alone never reveals personal bytes');
          Policy.IncludePersonal := True; Json := CardInspectionToJson(CopyR, Policy);
          if Fail <> 1 then Check((Pos('PRIVATE-NAME', Json) > 0) and (Pos('DEADBEEF', Json) > 0), 'Explicit combined export policy');
          Raised := False; try W.Execute; except on E: ECardWorkflowError do Raised := True; end;
          Check(Raised, 'Consumed requests cannot replay');
        finally O.Free; W.Free; Source := nil; Transport := nil; end;
      end;
  S := TSource.Create; Source := S; S.Mode := cisRead; T := TScript.Create; Transport := T;
  W := TTestInspectionWorkflow.Create(nil); O := TObserver.Create;
  try
    W.OnPartialRead := O.Incomplete; W.Prepare(Source, Transport); T.EndFails := True;
    Check(W.Execute = cwsFailed, 'Cleanup error fails workflow');
    Check(not W.Report.Complete and (O.Partial = 1), 'Cleanup error never claims complete');
    Check(Length(W.Report.Sections[2].Fields) = 4, 'Successful data survives cleanup failure');
  finally W.Free; O.Free; Source := nil; Transport := nil; end;
end;

procedure TestEmv;
var R: TEMVCardReader; W: TEmvInspectionWorkflow; S: TScript; T: ICardTransport;
  Apps: TEmvInspectionApplications; O: TEmvInspectionOptions; Report: TCardInspectionReport; I: Integer;
begin
  for I := 0 to 2 do
  begin
    S := TScript.Create; T := S; R := TEMVCardReader.Create(nil); W := TEmvInspectionWorkflow.Create(nil);
    try
      R.Transport := T; SetLength(Apps, 1); Apps[0].Aid := HexToBytes(AidHex);
      O := Default(TEmvInspectionOptions); O.ReadCounters := True; O.ReadLog := True;
      S.Add(SelectHex, Fci + '9000'); S.Add('80A8000002830000', '80060000080101009000', I = 1);
      if I <> 1 then
      begin
        S.Add('00B2010C00', '700A5A0812345678901234569000');
        S.Add(SelectHex, Fci + '9000'); S.Add('80CA9F3600', '9F360200079000');
        S.Add(SelectHex, Fci + '9000'); S.Add('80CA9F1300', '6A88');
        S.Add(SelectHex, Fci + '9000'); S.Add('80CA9F1700', '6982');
        S.Add(SelectHex, Fci + '9000');
      end;
      W.PrepareEmv(R, Apps, O); R.Transport := nil; Apps[0].Aid[0] := 0;
      Check(S.Position = 0, 'Frozen EMV preparation has no I/O');
      if I = 2 then S.EndFails := True;
      W.Execute; Report := W.Report;
      Check((S.Begins = 1) and (S.Ends = 1) and (S.Position = Length(S.Steps)), 'EMV one transaction, exact commands, no GPO replay');
      if I = 1 then Check((W.State = cwsFailed) and (Report.Sections[1].Status = cisPending), 'GPO failure stops all later reads')
      else
      begin
        Check(Report.Sections[0].Status = cisRead, 'AFL record acquired');
        Check(Report.Sections[2].Status = cisUnavailable, 'Optional absent counter');
        Check((Report.Sections[3].Status = cisAuthenticationRequired) and (Report.Sections[3].StatusWord = $6982), 'Restricted counter status retained');
        Check(Report.Sections[4].Status = cisUnavailable, 'Absent log explicit');
        Check(not Report.Complete, 'Gaps prevent complete');
      end;
    finally W.Free; R.Free; T := nil; end;
  end;
end;

procedure TestBelgian;
var R: TBelgianEIDReader; W: TEidInspectionWorkflow; S: TScript; T: ICardTransport; Report: TCardInspectionReport;
begin
  S := TScript.Create; T := S; R := TBelgianEIDReader.Create(nil); W := TEidInspectionWorkflow.Create(nil);
  try
    R.Transport := T; R.ChunkSize := 4;
    S.Add('00A4040C0F' + EidBelpicAidHex, '9000'); S.Add('00A4020C023F00', '9000');
    S.Add('00A4020C02DF01', '9000'); S.Add('00A4020C024031', '9000');
    S.Add('00B0000004', '070241429000'); S.Add('00B0000404', '6B00');
    S.Add('00A4040C0F' + EidBelpicAidHex, '6982');
    W.PrepareBelgian(R, [esIdentity, esAddress]); R.Transport := nil;
    Check(W.Execute = cwsCompleted, 'Known refusal permits completed inspection'); Report := W.Report;
    Check((Report.Sections[0].Status = cisRead) and (Report.Sections[0].Fields[0].Value = 'AB'), 'Decoded identity retained');
    Check(Report.Sections[1].Status = cisAuthenticationRequired, 'Address restriction explicit');
    Check((S.Begins = 1) and (S.Ends = 1) and (S.Position = 7), 'Belgian sections under one exclusive transaction');
  finally W.Free; R.Free; T := nil; end;
end;

procedure TestMobibAndIcao;
var S: TScript; T: ICardTransport; M: TCalypsoCardReader; MW: TMobibInspectionWorkflow;
  R: TICAODocumentReader; W: TEidInspectionWorkflow; Plan: TCalypsoFileRefs;
  O: TMobibReportOptions;
begin
  S := TScript.Create; T := S; M := TCalypsoCardReader.Create(nil); MW := TMobibInspectionWorkflow.Create(nil);
  R := TICAODocumentReader.Create(nil); W := TEidInspectionWorkflow.Create(nil);
  try
    M.Transport := T; M.RequireSecureSession := True; SetLength(Plan, 1); Plan[0] := TCalypsoCardReader.FileRef(0, $2001);
    O := TMobibReport.DefaultOptions; MW.PrepareMobib(M, Plan, mlRaw, O);
    Check(MW.Execute = cwsCompleted, 'Missing SAM is an explicit inspection outcome');
    Check(MW.Report.Sections[0].Status = cisAuthenticationRequired, 'Missing SAM provider reported');
    R.Transport := T; W.PrepareIcao(R); W.Execute;
    Check(W.Report.Sections[0].Status = cisAuthenticationRequired, 'Missing ICAO access credentials reported');
    Check((S.Position = 0) and (S.Begins = 0), 'Missing authentication never opens card transaction');
    M.RequireSecureSession := False;
    S.Add('94A4000002200000', '9000'); S.Add('94A4000002200100', '9000');
    S.Add('94B201041D', '00009000'); S.Add('94B202041D', '6A83');
    MW.PrepareMobib(M, Plan, mlRaw, O); MW.Execute;
    Check((S.Position = 4) and (S.Begins = 1) and (S.Ends = 1), 'MOBIB one bounded read plan');
    Check(MW.Report.Complete, 'Requested MOBIB file acquired with end marker');
  finally W.Free; R.Free; MW.Free; M.Free; T := nil; end;
end;

procedure TestDemo;
var F: TReaders; Readers: ICardWorkflowDemoReaders; S: TScript; Ops: ICardDemoOperations;
  V: ICardDemoRequestValidator; R: TCardDemoRequest; D: TCardDemoResult; Error: UnicodeString;
begin
  S := TScript.Create; F := TReaders.Create; Readers := F; F.Transport := S;
  Ops := CreateCardInspectionOperations(Readers); Check(Supports(Ops, ICardDemoRequestValidator, V), 'Demo has hardware-free validator');
  R := Default(TCardDemoRequest); R.Operation := cdoFamily; R.FamilyName := 'EmvInspectionDemo'; R.ReaderName := 'fake';
  SetLength(R.Arguments, 3); R.Arguments[0] := ''; R.Arguments[1] := '0'; R.Arguments[2] := '0'; SetLength(R.Credentials, 1);
  Check(V.TryValidateRequest(R, Error) and (S.Position = 0) and (S.Begins = 0), 'Demo validation does not connect');
  S.Add('00A404000E325041592E5359532E444446303100', '6A82');
  D := Default(TCardDemoResult); Ops.Run(R, D);
  Check(D.Success and (Length(D.Artifacts) = 1), 'Completed partial demo produces JSON');
  Check(Pos('Unavailable', D.Text) > 0, 'Partial report visible');
  R.Arguments[0] := 'scna=1'; Check(not V.TryValidateRequest(R, Error), 'Unknown option refused before I/O');
end;

begin
  try
    TestLifecycle; TestEmv; TestBelgian; TestMobibAndIcao; TestDemo;
    Writeln('PASS: ', Checks, ' inspection lifecycle, privacy, native transcript and demo assertions.');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
