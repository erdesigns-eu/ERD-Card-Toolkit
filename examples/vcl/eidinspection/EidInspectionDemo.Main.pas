unit EidInspectionDemo.Main;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Dialogs, ERD.Card.Bytes, ERD.Card.Demo.Job,
  ERD.Card.Demo.Controller, ERD.Card.Demo.Devices, ERD.Card.Demo.ReaderEvents,
  ERD.Card.Demo.Inspections;

type
  /// <summary>Independent inspection application with its own editable DFM form.</summary>
  TEidInspectionDemoForm = class(TForm)
  published
    /// <summary>Available reader selector, maintained by native reader events.</summary>
    ReaderBox: TComboBox;
    /// <summary>Explicit family and access profile.</summary>
    ProfileBox: TComboBox;
    /// <summary>Optional ICAO access password; copied to a wiped worker credential buffer.</summary>
    PasswordEdit: TEdit;
    /// <summary>Explicit key=value acquisition settings.</summary>
    ConfigMemo: TMemo;
    /// <summary>Readable policy-filtered report.</summary>
    TextMemo: TMemo;
    /// <summary>JSON using the same export policy.</summary>
    JsonMemo: TMemo;
    /// <summary>Start native reader inventory observation.</summary>
    RefreshButton: TButton;
    /// <summary>Acquire one prepared inspection on a background worker.</summary>
    RunButton: TButton;
    /// <summary>Export the displayed readable report.</summary>
    SaveTextButton: TButton;
    /// <summary>Export the displayed JSON report.</summary>
    SaveJsonButton: TButton;
    /// <summary>Explicit permission to include personal fields in this report.</summary>
    PersonalCheck: TCheckBox;
    /// <summary>Explicit permission to include raw bytes.</summary>
    RawCheck: TCheckBox;
    /// <summary>Consume worker completions on the main thread.</summary>
    WorkerTimer: TTimer;
    /// <summary>Form-owned report destination selector.</summary>
    SaveDialog: TSaveDialog;
    /// <summary>Family-specific acquisition instructions.</summary>
    GuideLabel: TLabel;
    /// <summary>Reader selection caption.</summary>
    ReaderLabel: TLabel;
    /// <summary>Access profile caption.</summary>
    ProfileLabel: TLabel;
    /// <summary>Credential caption.</summary>
    PasswordLabel: TLabel;
    /// <summary>Reader/card presence status.</summary>
    StatusLabel: TLabel;
    /// <summary>Create inactive nonvisual controller and reader observer.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormCreate(Sender: TObject);
    /// <summary>Start native reader observation when visible.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure FormShow(Sender: TObject);
    /// <summary>Refresh reader inventory inside this demo.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RefreshClick(Sender: TObject);
    /// <summary>Freeze explicit profile and report policy for one inspection.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure RunClick(Sender: TObject);
    /// <summary>Save displayed text as UTF-8.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SaveTextClick(Sender: TObject);
    /// <summary>Save displayed JSON as UTF-8.</summary>
    /// <param name="Sender">VCL event sender.</param>
    procedure SaveJsonClick(Sender: TObject);
    /// <summary>Consume worker completion without card polling.</summary>
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
    function ReaderName: UnicodeString;
    procedure SaveReport(const AMemo: TMemo; const AExtension: string);
  protected
    /// <summary>Delay close until the active worker is finished.</summary>
    /// <returns>True when the form can close.</returns>
    function CloseQuery: Boolean; override;
  public
    /// <summary>Join reader observation and worker before releasing this form.</summary>
    destructor Destroy; override;
  end;

var
  /// <summary>Application-owned independent inspection form.</summary>
  EidInspectionDemoForm: TEidInspectionDemoForm;

implementation

{$R *.dfm}

procedure TEidInspectionDemoForm.FormCreate(Sender: TObject);
begin
  FController := TCardDemoController.Create(ddkPcsc, CreateCardInspectionOperations,
    SetBusy, ShowResult, CloseAfterWork);
  FEvents := TCardDemoReaderEvents.Create(ReaderInventory, ReaderStatus);
  ProfileBox.ItemIndex := 0;
end;
procedure TEidInspectionDemoForm.FormShow(Sender: TObject);
begin
  if FStarted then Exit;
  FStarted := True; RefreshClick(Sender);
end;
destructor TEidInspectionDemoForm.Destroy;
begin
  WorkerTimer.Enabled := False; FEvents.Free; FController.Free; inherited Destroy;
end;
function TEidInspectionDemoForm.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if (FController <> nil) and not FController.CanClose then Result := False;
end;
procedure TEidInspectionDemoForm.CloseAfterWork;
begin Close; end;
procedure TEidInspectionDemoForm.SetBusy(const AValue: Boolean);
begin
  RunButton.Enabled := not AValue; RefreshButton.Enabled := not AValue;
  ReaderBox.Enabled := not AValue; ProfileBox.Enabled := not AValue;
  PasswordEdit.Enabled := not AValue; ConfigMemo.Enabled := not AValue;
  PersonalCheck.Enabled := not AValue; RawCheck.Enabled := not AValue;
  SaveTextButton.Enabled := not AValue; SaveJsonButton.Enabled := not AValue;
end;
function TEidInspectionDemoForm.ReaderName: UnicodeString;
begin
  Result := '';
  if (ReaderBox.ItemIndex >= 0) and (ReaderBox.ItemIndex < Length(FDevices)) then
    Result := FDevices[ReaderBox.ItemIndex].Address;
end;
procedure TEidInspectionDemoForm.ReaderInventory(const ADevices: TCardDemoDevices);
var Old: UnicodeString; I: Integer;
begin
  Old := ReaderName; FDevices := Copy(ADevices, 0, Length(ADevices));
  ReaderBox.Items.Clear;
  for I := 0 to High(FDevices) do
  begin
    ReaderBox.Items.Add(string(FDevices[I].DisplayName));
    if FDevices[I].Address = Old then ReaderBox.ItemIndex := I;
  end;
  if (ReaderBox.ItemIndex < 0) and (Length(FDevices) = 1) then ReaderBox.ItemIndex := 0;
end;
procedure TEidInspectionDemoForm.ReaderStatus(const AText: string);
begin StatusLabel.Caption := AText; end;
procedure TEidInspectionDemoForm.RefreshClick(Sender: TObject);
begin
  try FEvents.Start;
  except on E: Exception do TextMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;
procedure TEidInspectionDemoForm.RunClick(Sender: TObject);
var R: TCardDemoRequest;
begin
  R := Default(TCardDemoRequest);
  try
    try
      R.Operation := cdoFamily; R.FamilyName := 'EidInspectionDemo';
      R.ReaderName := ReaderName; R.FamilyAction := ProfileBox.ItemIndex;
      SetLength(R.Arguments, 3); R.Arguments[0] := ConfigMemo.Text;
      R.Arguments[1] := IntToStr(Ord(PersonalCheck.Checked));
      R.Arguments[2] := IntToStr(Ord(RawCheck.Checked));
      SetLength(R.Credentials, 1); R.Credentials[0] := TEncoding.ASCII.GetBytes(PasswordEdit.Text);
      TextMemo.Clear; JsonMemo.Clear; FController.StartRequest(R);
    except on E: Exception do TextMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
  finally
    if (Length(R.Credentials) > 0) and (Length(R.Credentials[0]) > 0) then
      FillChar(R.Credentials[0][0], Length(R.Credentials[0]), 0);
  end;
end;
procedure TEidInspectionDemoForm.ShowResult(const AResult: TCardDemoResult);
begin
  TextMemo.Text := string(AResult.Text);
  if AResult.ErrorClass <> '' then TextMemo.Lines.Add(AResult.ErrorClass);
  if Length(AResult.Artifacts) > 0 then
    JsonMemo.Text := TEncoding.UTF8.GetString(AResult.Artifacts[0].Data);
end;
procedure TEidInspectionDemoForm.SaveReport(const AMemo: TMemo; const AExtension: string);
begin
  SaveDialog.DefaultExt := AExtension;
  SaveDialog.Filter := 'Report (*.' + AExtension + ')|*.' + AExtension;
  if not SaveDialog.Execute then Exit;
  try AMemo.Lines.SaveToFile(SaveDialog.FileName, TEncoding.UTF8);
  except on E: Exception do TextMemo.Lines.Add(E.ClassName + ': ' + E.Message); end;
end;
procedure TEidInspectionDemoForm.SaveTextClick(Sender: TObject);
begin SaveReport(TextMemo, 'txt'); end;
procedure TEidInspectionDemoForm.SaveJsonClick(Sender: TObject);
begin SaveReport(JsonMemo, 'json'); end;
procedure TEidInspectionDemoForm.PollTimer(Sender: TObject);
begin FController.Poll; end;

end.
