unit DesfireWorkflowDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, ERD.Card.Bytes, ERD.Card.MagStripe,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.FamilyWorkflows;

type
  /// <summary>Independent workflow demo with its own editable DFM and background execution.</summary>
  TDesfireWorkflowDemoForm = class(TForm)
  published
    /// <summary>Source device selector owned by this form.</summary>
    SourceReaderBox: TComboBox;
    /// <summary>Explicit family-specific numeric configuration, separated by commas.</summary>
    RangeEdit: TEdit;
    /// <summary>Destination device selector owned by this form.</summary>
    TargetReaderBox: TComboBox;
    /// <summary>Capture, copy, compare or restore/template action.</summary>
    ActionBox: TComboBox;
    /// <summary>Explicit public, AES or DES/3DES authentication profile.</summary>
    ModelBox: TComboBox;
    /// <summary>Explicit fresh/discard-pending transaction authority.</summary>
    CoercivityBox: TComboBox;
    /// <summary>Explicit source authentication key or PICC key for provisioning.</summary>
    SourceKeyEdit: TEdit;
    /// <summary>Explicit destination application authentication key.</summary>
    TargetKeyEdit: TEdit;
    /// <summary>Editable complete family snapshot or explicit provisioning template.</summary>
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
    /// <summary>Source credential label.</summary>
    SourceKeyLabel: TLabel;
    /// <summary>Destination credential label.</summary>
    TargetKeyLabel: TLabel;
    /// <summary>Explicit family policy label.</summary>
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
    /// <summary>Loads a local snapshot with a three-MiB input limit.</summary>
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
  DesfireWorkflowDemoForm: TDesfireWorkflowDemoForm;

implementation

{$R *.dfm}

procedure TDesfireWorkflowDemoForm.FormCreate(Sender: TObject);
begin
  FController := TCardDemoController.Create(ddkPcsc,
    CreateCardFamilyWorkflowOperations, SetBusy, ShowResult, CloseAfterWork);
  FEvents := TCardDemoReaderEvents.Create(ReaderInventory, ReaderStatus);
  CoercivityBox.ItemIndex := 0;
end;

procedure TDesfireWorkflowDemoForm.FormShow(Sender: TObject);
begin
  if FStarted then Exit;
  FStarted := True;
  RefreshClick(Sender);
end;

destructor TDesfireWorkflowDemoForm.Destroy;
begin
  WorkerTimer.Enabled := False;
  FEvents.Free;
  FController.Free;
  inherited Destroy;
end;

function TDesfireWorkflowDemoForm.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if (FController <> nil) and not FController.CanClose then Result := False;
end;

procedure TDesfireWorkflowDemoForm.CloseAfterWork;
begin
  Close;
end;

procedure TDesfireWorkflowDemoForm.SetBusy(const AValue: Boolean);
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
end;

function TDesfireWorkflowDemoForm.DeviceName(const ABox: TComboBox): UnicodeString;
begin
  Result := '';
  if (ABox.ItemIndex >= 0) and (ABox.ItemIndex < Length(FDevices)) then
    Result := FDevices[ABox.ItemIndex].Address;
end;

procedure TDesfireWorkflowDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
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

procedure TDesfireWorkflowDemoForm.ReaderStatus(const AText: string);
begin
  EventStatusLabel.Caption := AText;
end;

procedure TDesfireWorkflowDemoForm.RefreshClick(Sender: TObject);
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

procedure TDesfireWorkflowDemoForm.RunClick(Sender: TObject);
var Request: TCardDemoRequest; I: Integer; Range: TStringList;
begin
  Request := Default(TCardDemoRequest);
  Range := TStringList.Create;
  try
    try
      if (ActionBox.ItemIndex < 0) or (ModelBox.ItemIndex < 0) then
        raise EArgumentException.Create('Choose an action and explicit profile.');
      if Length(SnapshotMemo.Text) > 3 * 1024 * 1024 then
        raise EArgumentException.Create('Snapshot/template exceeds three MiB.');

      Request.Operation := cdoFamily;
      Request.FamilyName := 'DesfireWorkflowDemo';
      Request.FamilyAction := ActionBox.ItemIndex;
      Request.ReaderName := DeviceName(SourceReaderBox);
      Request.MutationAcknowledged := AcknowledgeCheck.Checked;
      Request.Coercivity := mscLow;
      if CoercivityBox.ItemIndex = 1 then Request.Coercivity := mscHigh;
      SetLength(Request.Arguments, 4);
      Request.Arguments[0] := DeviceName(TargetReaderBox);
      Request.Arguments[1] := IntToStr(ModelBox.ItemIndex);
      Request.Arguments[2] := SnapshotMemo.Text;
      SetLength(Request.Credentials, 3);
      Range.StrictDelimiter := True; Range.Delimiter := ','; Range.DelimitedText := RangeEdit.Text;
      if Range.Count <> 6 then raise EArgumentException.Create('Configuration needs source AID,target AID,key number,minimum communication,transfer bound,frame bound.');
      Range.Delimiter := '|'; Request.Arguments[3] := Range.DelimitedText + '|' + IntToStr(CoercivityBox.ItemIndex);
      if (ActionBox.ItemIndex in [0, 1, 2, 4]) and (Trim(SourceKeyEdit.Text) <> '') then Request.Credentials[0] := HexToBytes(SourceKeyEdit.Text);
      if (ActionBox.ItemIndex <> 0) and (Trim(TargetKeyEdit.Text) <> '') then Request.Credentials[1] := HexToBytes(TargetKeyEdit.Text);
      OutputMemo.Clear;
      FController.StartRequest(Request);
    except
      on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message);
    end;
    for I := 0 to High(Request.Credentials) do
      if Length(Request.Credentials[I]) <> 0 then
        FillChar(Request.Credentials[I][0], Length(Request.Credentials[I]), 0);
  finally Range.Free; end;
end;

procedure TDesfireWorkflowDemoForm.ShowResult(const AResult: TCardDemoResult);
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

procedure TDesfireWorkflowDemoForm.LoadClick(Sender: TObject);
var Stream: TFileStream;
begin
  if not OpenDialog.Execute then Exit;
  try
    Stream := TFileStream.Create(OpenDialog.FileName, fmOpenRead or fmShareDenyWrite);
    try
      if Stream.Size > 3 * 1024 * 1024 then raise EArgumentException.Create('Snapshot exceeds three MiB.');
      SnapshotMemo.Lines.LoadFromStream(Stream, TEncoding.UTF8);
    finally Stream.Free; end;
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TDesfireWorkflowDemoForm.SaveClick(Sender: TObject);
begin
  if not SaveDialog.Execute then Exit;
  try SnapshotMemo.Lines.SaveToFile(SaveDialog.FileName, TEncoding.UTF8);
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TDesfireWorkflowDemoForm.PollTimer(Sender: TObject);
begin
  if FController <> nil then FController.Poll;
end;

end.
