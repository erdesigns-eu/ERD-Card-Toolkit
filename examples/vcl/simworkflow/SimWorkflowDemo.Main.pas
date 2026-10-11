unit SimWorkflowDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, ERD.Card.Bytes, ERD.Card.MagStripe,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.SimWorkflows;

type
  /// <summary>Independent workflow demo with its own editable DFM and background execution.</summary>
  TSimWorkflowDemoForm = class(TForm)
  published
    /// <summary>Source device selector owned by this form.</summary>
    SourceReaderBox: TComboBox;
    /// <summary>Explicit EF root and directory/file path.</summary>
    RangeEdit: TEdit;
    /// <summary>Selected PBR record, zero for standalone contacts or SMS.</summary>
    PbrEdit: TEdit;
    /// <summary>Offline name TAB number contacts or explicit semicolon-separated SMS records.</summary>
    ImportMemo: TMemo;
    /// <summary>Explicitly includes standard classic EXT1 in a contact backup.</summary>
    IncludeClassicExtCheck: TCheckBox;
    /// <summary>Actual EF address guidance.</summary>
    AddressLabel: TLabel;
    /// <summary>Selected PBR record guidance.</summary>
    PbrLabel: TLabel;
    /// <summary>Snapshot/plan field label.</summary>
    SnapshotLabel: TLabel;
    /// <summary>Offline import/grouping field label.</summary>
    ImportLabel: TLabel;
    /// <summary>Destination device selector owned by this form.</summary>
    TargetReaderBox: TComboBox;
    /// <summary>Capture, copy, compare or restore/template action.</summary>
    ActionBox: TComboBox;
    /// <summary>Explicit classic GSM SIM or UICC/USIM protocol profile.</summary>
    ModelBox: TComboBox;
    /// <summary>Explicit minimum remaining PIN retry budget.</summary>
    CoercivityBox: TComboBox;
    /// <summary>Full selected USIM application AID in hexadecimal.</summary>
    SourceKeyEdit: TEdit;
    /// <summary>Optional masked ASCII PIN digits for this operation.</summary>
    TargetKeyEdit: TEdit;
    /// <summary>Editable complete SIM snapshot or reviewed target-bound plan.</summary>
    SnapshotMemo: TMemo;
    /// <summary>Workflow phase log and per-unit completion evidence.</summary>
    OutputMemo: TMemo;
    /// <summary>Discover devices within this demo.</summary>
    RefreshButton: TButton;
    /// <summary>Execute one explicitly prepared workflow on a worker.</summary>
    RunButton: TButton;
    /// <summary>Load a bounded local template or snapshot.</summary>
    LoadButton: TButton;
    /// <summary>Save the displayed snapshot or template.</summary>
    SaveButton: TButton;
    /// <summary>Explicit acknowledgement before target mutation.</summary>
    AcknowledgeCheck: TCheckBox;
    /// <summary>Main-thread completion polling; does not poll cards.</summary>
    WorkerTimer: TTimer;
    /// <summary>This demo own snapshot file picker.</summary>
    OpenDialog: TOpenDialog;
    /// <summary>This demo own export file picker.</summary>
    SaveDialog: TSaveDialog;
    /// <summary>Workflow and backend guidance.</summary>
    GuideLabel: TLabel;
    /// <summary>Native reader/card presence status.</summary>
    EventStatusLabel: TLabel;
    /// <summary>Source selector label.</summary>
    SourceLabel: TLabel;
    /// <summary>Destination selector label.</summary>
    TargetLabel: TLabel;
    /// <summary>Action selector label.</summary>
    ActionLabel: TLabel;
    /// <summary>Explicit profile selector label.</summary>
    ModelLabel: TLabel;
    /// <summary>Full USIM AID label.</summary>
    SourceKeyLabel: TLabel;
    /// <summary>Optional ASCII PIN label.</summary>
    TargetKeyLabel: TLabel;
    /// <summary>PIN retry budget label.</summary>
    CoercivityLabel: TLabel;
    /// <summary>Creates the inactive worker controller.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormCreate(Sender: TObject);
    /// <summary>Starts device discovery once the form is visible.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormShow(Sender: TObject);
    /// <summary>Refreshes reader names without card commands.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RefreshClick(Sender: TObject);
    /// <summary>Copies explicit UI inputs into one worker request.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RunClick(Sender: TObject);
    /// <summary>Loads a local snapshot with a ten-MiB input limit.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure LoadClick(Sender: TObject);
    /// <summary>Saves the displayed template as UTF-8.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SaveClick(Sender: TObject);
    /// <summary>Consumes worker completion on the main thread.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure PollTimer(Sender: TObject);
  private
    FController: TCardDemoController;
    FEvents: TCardDemoReaderEvents;
    FDevices: TCardDemoDevices;
    FStarted: Boolean;
    procedure SetBusy(const AValue: Boolean);
    procedure ShowResult(const AResult: TCardDemoResult);
    procedure CloseAfterWork;
    procedure ReaderInventory(const ADevices: TCardDemoDevices);
    procedure ReaderStatus(const AText: string);
    function DeviceName(const ABox: TComboBox): UnicodeString;
  protected
    /// <summary>Defers close until the active workflow worker is finished.</summary>
    /// <returns>True when no worker remains.</returns>
    function CloseQuery: Boolean; override;
  public
    /// <summary>Joins event observation and outstanding worker before releasing the form.</summary>
    destructor Destroy; override;
  end;

var
  /// <summary>Application-owned independent demo form.</summary>
  SimWorkflowDemoForm: TSimWorkflowDemoForm;

implementation

{$R *.dfm}

procedure TSimWorkflowDemoForm.FormCreate(Sender: TObject);
begin
  FController := TCardDemoController.Create(ddkPcsc,
    CreateSimWorkflowDemoOperations, SetBusy, ShowResult, CloseAfterWork);
  FEvents := TCardDemoReaderEvents.Create(ReaderInventory, ReaderStatus);
  CoercivityBox.ItemIndex := 0; SourceKeyEdit.Text := '8';
end;

procedure TSimWorkflowDemoForm.FormShow(Sender: TObject);
begin
  if FStarted then Exit;
  FStarted := True;
  RefreshClick(Sender);
end;

destructor TSimWorkflowDemoForm.Destroy;
begin
  WorkerTimer.Enabled := False;
  FEvents.Free;
  FController.Free;
  inherited Destroy;
end;

function TSimWorkflowDemoForm.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if (FController <> nil) and not FController.CanClose then Result := False;
end;

procedure TSimWorkflowDemoForm.CloseAfterWork;
begin
  Close;
end;

procedure TSimWorkflowDemoForm.SetBusy(const AValue: Boolean);
begin
  RunButton.Enabled := not AValue;
  RefreshButton.Enabled := not AValue;
  LoadButton.Enabled := not AValue;
  SaveButton.Enabled := not AValue;
  SourceReaderBox.Enabled := not AValue;
  TargetReaderBox.Enabled := not AValue;
  ActionBox.Enabled := not AValue;
  ModelBox.Enabled := not AValue;
  SourceKeyEdit.Enabled := not AValue;
  TargetKeyEdit.Enabled := not AValue;
  SnapshotMemo.Enabled := not AValue;
  AcknowledgeCheck.Enabled := not AValue;
  CoercivityBox.Enabled := not AValue; RangeEdit.Enabled := not AValue;
  PbrEdit.Enabled := not AValue; ImportMemo.Enabled := not AValue; IncludeClassicExtCheck.Enabled := not AValue;
end;

function TSimWorkflowDemoForm.DeviceName(const ABox: TComboBox): UnicodeString;
begin
  Result := '';
  if (ABox.ItemIndex >= 0) and (ABox.ItemIndex < Length(FDevices)) then
    Result := FDevices[ABox.ItemIndex].Address;
end;

procedure TSimWorkflowDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var Source, Target: UnicodeString; I: Integer;
begin
  Source := DeviceName(SourceReaderBox);
  Target := DeviceName(TargetReaderBox);
  FDevices := Copy(ADevices, 0, Length(ADevices));
  SourceReaderBox.Items.Clear;
  TargetReaderBox.Items.Clear;
  for I := 0 to High(FDevices) do
  begin
    SourceReaderBox.Items.Add(string(FDevices[I].DisplayName));
    TargetReaderBox.Items.Add(string(FDevices[I].DisplayName));
    if FDevices[I].Address = Source then SourceReaderBox.ItemIndex := I;
    if FDevices[I].Address = Target then TargetReaderBox.ItemIndex := I;
  end;
end;

procedure TSimWorkflowDemoForm.ReaderStatus(const AText: string);
begin
  EventStatusLabel.Caption := AText;
end;

procedure TSimWorkflowDemoForm.RefreshClick(Sender: TObject);
var Request: TCardDemoRequest;
begin
  try
    if FEvents <> nil then FEvents.Start
    else
    begin
      Request := Default(TCardDemoRequest);
      Request.Operation := cdoDemoDevices;
      FController.StartRequest(Request);
    end;
  except
    on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message);
  end;
end;

procedure TSimWorkflowDemoForm.RunClick(Sender: TObject);
var Request: TCardDemoRequest; I: Integer;
begin
  Request := Default(TCardDemoRequest);
  try
    if (ActionBox.ItemIndex < 0) or (ModelBox.ItemIndex < 0) then
      raise EArgumentException.Create('Choose an action and explicit SIM profile.');
    Request.Operation := cdoFamily; Request.FamilyName := 'SimWorkflowDemo';
    Request.FamilyAction := ActionBox.ItemIndex; Request.ReaderName := DeviceName(SourceReaderBox);
    Request.MutationAcknowledged := AcknowledgeCheck.Checked;
    SetLength(Request.Arguments, 7); SetLength(Request.Credentials, 1);
    Request.Arguments[0] := DeviceName(TargetReaderBox);
    Request.Arguments[1] := IntToStr(ModelBox.ItemIndex); Request.Arguments[2] := SnapshotMemo.Text;
    Request.Arguments[3] := RangeEdit.Text; Request.Arguments[4] := SourceKeyEdit.Text;
    Request.Arguments[5] := PbrEdit.Text + '|' + IntToStr(CoercivityBox.ItemIndex + 1) + '|' + IntToStr(Ord(IncludeClassicExtCheck.Checked));
    Request.Arguments[6] := ImportMemo.Text;
    if ActionBox.ItemIndex in [0, 1, 2, 3, 6] then
    begin
      SetLength(Request.Credentials[0], Length(TargetKeyEdit.Text));
      for I := 1 to Length(TargetKeyEdit.Text) do begin
        if not CharInSet(TargetKeyEdit.Text[I], ['0' .. '9']) then raise EArgumentException.Create('PIN must contain ASCII digits.');
        Request.Credentials[0][I - 1] := Ord(TargetKeyEdit.Text[I]); end;
    end;
    OutputMemo.Clear; FController.StartRequest(Request);
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
  if Length(Request.Credentials) > 0 then
    if Length(Request.Credentials[0]) > 0 then FillChar(Request.Credentials[0][0], Length(Request.Credentials[0]), 0);
  TargetKeyEdit.Clear;
end;

procedure TSimWorkflowDemoForm.ShowResult(const AResult: TCardDemoResult);
begin
  if AResult.Operation = cdoDemoDevices then
  begin
    ReaderInventory(AResult.Devices);
    if AResult.ErrorClass <> '' then OutputMemo.Text := AResult.Text;
    Exit;
  end;
  OutputMemo.Text := AResult.Text;
  if AResult.ErrorClass <> '' then OutputMemo.Lines.Add(AResult.ErrorClass);
  if AResult.Success and (Length(AResult.Artifacts) > 0) then
    SnapshotMemo.Text := TEncoding.UTF8.GetString(AResult.Artifacts[0].Data);
end;

procedure TSimWorkflowDemoForm.LoadClick(Sender: TObject);
var Stream: TFileStream;
begin
  if not OpenDialog.Execute then Exit;
  try
    Stream := TFileStream.Create(OpenDialog.FileName, fmOpenRead or fmShareDenyWrite);
    try
      if Stream.Size > 10 * 1024 * 1024 then raise EArgumentException.Create('Snapshot exceeds ten MiB.');
      SnapshotMemo.Lines.LoadFromStream(Stream, TEncoding.UTF8);
    finally Stream.Free; end;
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TSimWorkflowDemoForm.SaveClick(Sender: TObject);
begin
  if not SaveDialog.Execute then Exit;
  try SnapshotMemo.Lines.SaveToFile(SaveDialog.FileName, TEncoding.UTF8);
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TSimWorkflowDemoForm.PollTimer(Sender: TObject);
begin
  if FController <> nil then FController.Poll;
end;

end.
