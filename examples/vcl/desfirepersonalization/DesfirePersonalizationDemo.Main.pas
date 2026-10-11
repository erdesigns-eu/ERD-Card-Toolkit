unit DesfirePersonalizationDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, ERD.Card.Bytes, ERD.Card.MagStripe,
  ERD.Card.Demo.Job, ERD.Card.Demo.Controller, ERD.Card.Demo.Devices,
  ERD.Card.Demo.ReaderEvents, ERD.Card.Demo.Personalization;

type
  /// <summary>Independent workflow demo with its own editable DFM and background execution.</summary>
  TDesfirePersonalizationDemoForm = class(TForm)
  published
    /// <summary>Source device selector owned by this form.</summary>
    SourceReaderBox: TComboBox;
    /// <summary>Explicit pipe-separated native geometry/policy fields.</summary>
    RangeEdit: TEdit;
    /// <summary>Capture, copy, compare or restore/template action.</summary>
    ActionBox: TComboBox;
    /// <summary>Explicit caller-identified chip or DESFire security profile.</summary>
    ModelBox: TComboBox;
    /// <summary>Reserved inactive control; not used by these workflows.</summary>
    CoercivityBox: TComboBox;
    /// <summary>Masked credential bytes, copied independently into the worker.</summary>
    SourceKeyEdit: TEdit;
    /// <summary>Explicit memory code or separate content snapshot path.</summary>
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
  DesfirePersonalizationDemoForm: TDesfirePersonalizationDemoForm;

implementation

{$R *.dfm}

procedure TDesfirePersonalizationDemoForm.FormCreate(Sender: TObject);
begin
  FController := TCardDemoController.Create(ddkPcsc,
    CreateCardPersonalizationDemoOperations, SetBusy, ShowResult, CloseAfterWork);
  FEvents := TCardDemoReaderEvents.Create(ReaderInventory, ReaderStatus);
  CoercivityBox.Visible := False; CoercivityLabel.Visible := False;
  ActionBox.ItemIndex := 0; ModelBox.ItemIndex := 0;
end;

procedure TDesfirePersonalizationDemoForm.FormShow(Sender: TObject);
begin
  if FStarted then Exit;
  FStarted := True;
  RefreshClick(Sender);
end;

destructor TDesfirePersonalizationDemoForm.Destroy;
begin
  WorkerTimer.Enabled := False;
  FEvents.Free;
  FController.Free;
  inherited Destroy;
end;

function TDesfirePersonalizationDemoForm.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if (FController <> nil) and not FController.CanClose then Result := False;
end;

procedure TDesfirePersonalizationDemoForm.CloseAfterWork;
begin
  Close;
end;

procedure TDesfirePersonalizationDemoForm.SetBusy(const AValue: Boolean);
begin
  RunButton.Enabled := not AValue;
  RefreshButton.Enabled := not AValue;
  LoadButton.Enabled := not AValue;
  SaveButton.Enabled := not AValue;
  SourceReaderBox.Enabled := not AValue;
  ActionBox.Enabled := not AValue;
  ModelBox.Enabled := not AValue;
  SourceKeyEdit.Enabled := not AValue;
  TargetKeyEdit.Enabled := not AValue;
  SnapshotMemo.Enabled := not AValue;
  AcknowledgeCheck.Enabled := not AValue;
  CoercivityBox.Enabled := not AValue; RangeEdit.Enabled := not AValue;
end;

function TDesfirePersonalizationDemoForm.DeviceName(const ABox: TComboBox): UnicodeString;
begin
  Result := '';
  if (ABox.ItemIndex >= 0) and (ABox.ItemIndex < Length(FDevices)) then
    Result := FDevices[ABox.ItemIndex].Address;
end;

procedure TDesfirePersonalizationDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var Source: UnicodeString; I: Integer;
begin
  Source := DeviceName(SourceReaderBox);
  FDevices := Copy(ADevices, 0, Length(ADevices));
  SourceReaderBox.Items.Clear;
  for I := 0 to High(FDevices) do
  begin
    SourceReaderBox.Items.Add(string(FDevices[I].DisplayName));
    if FDevices[I].Address = Source then SourceReaderBox.ItemIndex := I;
  end;
end;

procedure TDesfirePersonalizationDemoForm.ReaderStatus(const AText: string);
begin
  EventStatusLabel.Caption := AText;
end;

procedure TDesfirePersonalizationDemoForm.RefreshClick(Sender: TObject);
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

procedure TDesfirePersonalizationDemoForm.RunClick(Sender: TObject);
var Request: TCardDemoRequest; I: Integer; Keys: TStringList;
begin
  Request := Default(TCardDemoRequest); Keys := TStringList.Create;
  try
    try
      if (ActionBox.ItemIndex < 0) or (ModelBox.ItemIndex < 0) then
        raise EArgumentException.Create('Choose an action and explicit model/security.');
      if Length(SnapshotMemo.Text) > 300000 then raise EArgumentException.Create('Plan exceeds 300000 characters.');
      Request.Operation := cdoFamily; Request.FamilyName := 'DesfirePersonalizationDemo';
      Request.FamilyAction := ActionBox.ItemIndex; Request.ReaderName := DeviceName(SourceReaderBox);
      Request.MutationAcknowledged := AcknowledgeCheck.Checked;
      SetLength(Request.Arguments, 4); Request.Arguments[1] := IntToStr(ModelBox.ItemIndex);
      Request.Arguments[2] := SnapshotMemo.Text; Request.Arguments[3] := RangeEdit.Text;
      Keys.StrictDelimiter := True; Keys.Delimiter := ';'; Keys.DelimitedText := SourceKeyEdit.Text;
      if Trim(SourceKeyEdit.Text) = '' then Keys.Clear;
      if Keys.Count > 256 then raise EArgumentException.Create('At most 256 explicit keys.');
      SetLength(Request.Credentials, Keys.Count);
      for I := 0 to Keys.Count - 1 do Request.Credentials[I] := HexToBytes(Keys[I]);
      Request.Arguments[0] := TargetKeyEdit.Text;
      OutputMemo.Clear; FController.StartRequest(Request);
      SourceKeyEdit.Clear;
    except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
  finally
    for I := 0 to High(Request.Credentials) do
      if Length(Request.Credentials[I]) > 0 then FillChar(Request.Credentials[I][0], Length(Request.Credentials[I]), 0);
    Keys.Free;
  end;
end;

procedure TDesfirePersonalizationDemoForm.ShowResult(const AResult: TCardDemoResult);
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

procedure TDesfirePersonalizationDemoForm.LoadClick(Sender: TObject);
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

procedure TDesfirePersonalizationDemoForm.SaveClick(Sender: TObject);
begin
  if not SaveDialog.Execute then Exit;
  try SnapshotMemo.Lines.SaveToFile(SaveDialog.FileName, TEncoding.UTF8);
  except on E: Exception do OutputMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;

procedure TDesfirePersonalizationDemoForm.PollTimer(Sender: TObject);
begin
  if FController <> nil then FController.Poll;
end;

end.
