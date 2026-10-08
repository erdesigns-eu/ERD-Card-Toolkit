unit ERD.Card.Demo.FamilyForm;

interface

uses System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, ERD.Card.Demo.Form, ERD.Card.Demo.Job, ERD.Card.Demo.Families,
  ERD.Card.RFID.Input;

type
  /// <summary>Shared native VCL host for separate family projects; no hardware opens during construction.</summary>
  TCardFamilyForm = class(TCardDemoForm)
  private
    FFamily: TCardDemoFamily;
    FActions: TCardFamilyActions;
    FAction: TComboBox;
    FReader: TEdit;
    FFields: TScrollBox;
    FInputs: TArray<TWinControl>;
    FAcknowledge: TCheckBox;
    FRun: TButton;
    FOutput, FCaptureInput: TMemo;
    FCapture: TRfidKeyboardReader;
    FBusy: Boolean;
    procedure ActionChanged(Sender: TObject);
    procedure RunClick(Sender: TObject);
    procedure CaptureKey(Sender: TObject; var Key: Char);
    procedure Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
    procedure StopCapture;
    function Request: TCardDemoRequest;
    procedure ClearCredentials;
  protected
    /// <summary>Creates an inactive executor for this form's explicit family.</summary>
    /// <returns>Executor retained by the background job.</returns>
    function CreateOperations: ICardDemoOperations; override;
    /// <summary>Freezes request controls while a worker or live capture owns their configuration.</summary>
    /// <param name="AValue">Whether a background operation is active.</param>
    procedure SetBusy(const AValue: Boolean); override;
    /// <summary>Displays sanitized completion, including uncertain writes and proven read-back.</summary>
    /// <param name="AResult">Owned worker result.</param>
    procedure Complete(const AResult: TCardDemoResult); override;
    /// <summary>Stops foreground capture, then uses the shared worker close/join policy.</summary>
    /// <returns>True only when the shared host permits closing.</returns>
    function CloseQuery: Boolean; override;
  public
    /// <summary>Loads the shared DFM and builds controls for the configured family.</summary>
    /// <param name="AOwner">Standard VCL form owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Stops capture before the shared host joins its worker and destroys controls.</summary>
    destructor Destroy; override;
  end;

/// <summary>Selects the family explicitly before Application.CreateForm; performs no device I/O.</summary>
/// <param name="AFamily">Family implemented by the launching project.</param>
procedure ConfigureCardFamilyDemo(const AFamily: TCardDemoFamily);

implementation

{$R *.dfm}

uses Winapi.Windows, ERD.Card.Bytes, ERD.Card.Crypto, ERD.Card.Demo.FamilyOperations;

var SelectedFamily: TCardDemoFamily; FamilyConfigured: Boolean;

procedure ConfigureCardFamilyDemo(const AFamily: TCardDemoFamily);
begin CardFamilyName(AFamily); SelectedFamily := AFamily; FamilyConfigured := True; end;

constructor TCardFamilyForm.Create(AOwner: TComponent);
var P, Bottom: TPanel; L: TLabel; A: TCardFamilyAction;
begin
  inherited Create(AOwner);
  if not FamilyConfigured then raise EInvalidOpException.Create('Configure the demo family first.');
  FFamily := SelectedFamily; FActions := CardFamilyActions(FFamily); Caption := CardFamilyName(FFamily);
  P := TPanel.Create(Self); P.Parent := Self; P.Align := alTop; P.Height := 126;
  L := TLabel.Create(Self); L.Parent := P; L.SetBounds(12,8,650,18);
  L.Caption := 'Explicit action and reader; no automatic detection, code attempts or retries.';
  FAction := TComboBox.Create(Self); FAction.Parent := P; FAction.Style := csDropDownList;
  FAction.SetBounds(12,30,720,25); FAction.Anchors := [akLeft,akTop,akRight];
  for A in FActions do FAction.Items.Add(A.LabelText);
  FAction.OnChange := ActionChanged;
  L := TLabel.Create(Self); L.Parent := P; L.SetBounds(12,64,700,18);
  L.Caption := 'Exact PC/SC reader name (use ReaderToolsDemo to list names):';
  FReader := TEdit.Create(Self); FReader.Parent := P; FReader.SetBounds(12,86,720,25);
  FReader.Anchors := [akLeft,akTop,akRight];
  Bottom := TPanel.Create(Self); Bottom.Parent := Self; Bottom.Align := alBottom; Bottom.Height := 330;
  FAcknowledge := TCheckBox.Create(Self); FAcknowledge.Parent := Bottom;
  FAcknowledge.SetBounds(12,8,650,20); FAcknowledge.Anchors := [akLeft,akTop,akRight];
  FAcknowledge.Caption := 'I authorize this exact operation, including code attempts or permanent changes.';
  FRun := TButton.Create(Self); FRun.Parent := Bottom; FRun.SetBounds(12,34,170,30);
  FRun.Caption := 'Run selected action'; FRun.OnClick := RunClick;
  FCaptureInput := TMemo.Create(Self); FCaptureInput.Parent := Bottom; FCaptureInput.SetBounds(196,34,536,45);
  FCaptureInput.Anchors := [akLeft,akTop,akRight]; FCaptureInput.WantTabs := True;
  FCaptureInput.WantReturns := True; FCaptureInput.OnKeyPress := CaptureKey;
  FCaptureInput.Enabled := False; FCaptureInput.Visible := FFamily = dfRfid;
  FCaptureInput.Text := 'Live capture: keep focus here; only complete delimited frames are accepted.';
  FOutput := TMemo.Create(Self); FOutput.Parent := Bottom; FOutput.SetBounds(12,86,720,232);
  FOutput.Anchors := [akLeft,akTop,akRight,akBottom]; FOutput.ReadOnly := True;
  FOutput.ScrollBars := ssBoth; FOutput.WordWrap := False;
  FFields := TScrollBox.Create(Self); FFields.Parent := Self; FFields.Align := alClient;
  FAction.ItemIndex := 0; ActionChanged(nil);
end;

destructor TCardFamilyForm.Destroy;
begin StopCapture; inherited Destroy; end;

procedure TCardFamilyForm.ActionChanged(Sender: TObject);
var I, J: Integer; A: TCardFamilyAction; L: TLabel; E: TEdit; C: TComboBox; Choices: TStringList;
begin
  if FBusy or (FCapture <> nil) then Exit;
  while FFields.ControlCount > 0 do FFields.Controls[0].Free;
  FInputs := nil; FAcknowledge.Checked := False;
  if FAction.ItemIndex < 0 then Exit;
  A := FActions[FAction.ItemIndex]; SetLength(FInputs,Length(A.Fields));
  FReader.Enabled := A.Pcsc; FAcknowledge.Enabled := A.Mutation;
  for I := 0 to High(A.Fields) do
  begin
    L := TLabel.Create(Self); L.Parent := FFields; L.SetBounds(12,I*62+8,690,18);
    L.Caption := A.Fields[I].LabelText;
    if A.Fields[I].Choices <> '' then
    begin
      C := TComboBox.Create(Self); C.Parent := FFields; C.Style := csDropDownList;
      C.SetBounds(12,I*62+28,690,25); C.Anchors := [akLeft,akTop,akRight];
      Choices := TStringList.Create;
      try Choices.StrictDelimiter := True; Choices.Delimiter := '|'; Choices.DelimitedText := A.Fields[I].Choices;
        C.Items.Assign(Choices); finally Choices.Free; end;
      if TryStrToInt(A.Fields[I].DefaultText,J) then C.ItemIndex := J else C.ItemIndex := -1;
      FInputs[I] := C;
    end else
    begin
      E := TEdit.Create(Self); E.Parent := FFields; E.SetBounds(12,I*62+28,690,25);
      E.Anchors := [akLeft,akTop,akRight]; E.Text := A.Fields[I].DefaultText;
      if A.Fields[I].Secret then begin E.PasswordChar := '*'; E.MaxLength := 128; end
      else E.MaxLength := 262144;
      FInputs[I] := E;
    end;
  end;
  FFields.VertScrollBar.Position := 0;
end;

procedure TCardFamilyForm.ClearCredentials;
var I: Integer;
begin
  if FAction.ItemIndex < 0 then Exit;
  for I := 0 to High(FInputs) do if FActions[FAction.ItemIndex].Fields[I].Secret then TEdit(FInputs[I]).Clear;
end;

function TCardFamilyForm.Request: TCardDemoRequest;
var I: Integer;
begin
  Result := Default(TCardDemoRequest);
  if FAction.ItemIndex < 0 then raise EArgumentException.Create('Select an action.');
  Result.Operation := cdoFamily; Result.FamilyName := CardFamilyName(FFamily);
  Result.FamilyAction := FAction.ItemIndex; Result.ReaderName := FReader.Text;
  Result.MutationAcknowledged := FAcknowledge.Checked;
  SetLength(Result.Arguments,Length(FInputs)); SetLength(Result.Credentials,Length(FInputs));
  try
    for I := 0 to High(FInputs) do
      if FInputs[I] is TComboBox then
        Result.Arguments[I] := IntToStr(TComboBox(FInputs[I]).ItemIndex)
      else if FActions[FAction.ItemIndex].Fields[I].Secret then
        Result.Credentials[I] := HexToBytes(TEdit(FInputs[I]).Text)
      else Result.Arguments[I] := TEdit(FInputs[I]).Text;
  except
    for I := 0 to High(Result.Credentials) do TCardCrypto.Clear(Result.Credentials[I]);
    raise;
  end;
end;

procedure TCardFamilyForm.RunClick(Sender: TObject);
var R: TCardDemoRequest; I: Integer;
begin
  if FCapture <> nil then begin StopCapture; Exit; end;
  R := Default(TCardDemoRequest);
  try
    try
      R := Request;
      if (FFamily = dfRfid) and (FActions[FAction.ItemIndex].Id = 'keyboard') then
      begin
        FCapture := CreateCardFamilyRfidCapture(R);
        try FCapture.OnIdentifier := Identifier; FCapture.Start;
        except FreeAndNil(FCapture); raise; end;
        SetBusy(False); FCaptureInput.Enabled := True; FCaptureInput.SetFocus;
        FRun.Caption := 'Stop capture';
        FOutput.Text := 'Capture active. Use the reader actual delimiter; Enter emits CR. No USB device is opened.';
      end else begin FOutput.Clear; StartRequest(R); end;
    except
      on E: Exception do FOutput.Text := 'Operation refused / failed: ' + E.ClassName + '. Check the inputs; no automatic retry.';
    end;
  finally
    for I := 0 to High(R.Credentials) do TCardCrypto.Clear(R.Credentials[I]);
    ClearCredentials; FAcknowledge.Checked := False;
  end;
end;

procedure TCardFamilyForm.StopCapture;
begin
  if FCapture = nil then Exit;
  FCapture.Stop; FreeAndNil(FCapture);
  FCaptureInput.Enabled := False; FRun.Caption := 'Run selected action'; SetBusy(False);
end;

procedure TCardFamilyForm.CaptureKey(Sender: TObject; var Key: Char);
begin
  if FCapture <> nil then
    try FCapture.FeedCharacter(Key,GetTickCount64);
    except on E: Exception do begin FCapture.DiscardFrame;
      FOutput.Text := 'Frame discarded: ' + E.ClassName + '. Waiting for its delimiter.'; end; end;
  Key := #0;
end;

procedure TCardFamilyForm.Identifier(Sender: TObject; const AIdentifier: TRfidInputIdentifier);
begin
  if Length(FOutput.Text) > 8192 then FOutput.Clear;
  FOutput.Lines.Add(AIdentifier.Text + '  Explicit hex bytes: ' + BytesToHex(AIdentifier.Bytes));
end;

function TCardFamilyForm.CreateOperations: ICardDemoOperations;
begin Result := CreateCardFamilyOperations(FFamily); end;

procedure TCardFamilyForm.SetBusy(const AValue: Boolean);
var I: Integer; Frozen: Boolean;
begin
  FBusy := AValue; Frozen := AValue or (FCapture <> nil);
  FAction.Enabled := not Frozen; FFields.Enabled := not Frozen;
  FReader.Enabled := not Frozen and FActions[FAction.ItemIndex].Pcsc;
  FAcknowledge.Enabled := not Frozen and FActions[FAction.ItemIndex].Mutation;
  for I := 0 to High(FInputs) do FInputs[I].Enabled := not Frozen;
  FRun.Enabled := not AValue;
end;

procedure TCardFamilyForm.Complete(const AResult: TCardDemoResult);
var I: Integer;
begin
  FOutput.Text := AResult.Text;
  for I := 0 to High(AResult.Readers) do FOutput.Lines.Add(AResult.Readers[I]);
  if AResult.WriteVerified then FOutput.Lines.Add('Independent verification completed.');
  if AResult.WriteUncertain then FOutput.Lines.Add('WRITE OUTCOME / CLEANUP UNCERTAIN. Inspect the card; do not repeat automatically.');
  if not AResult.Success then FOutput.Lines.Add('Operation failed: ' + AResult.ErrorClass + '. No automatic retry.');
end;

function TCardFamilyForm.CloseQuery: Boolean;
begin StopCapture; Result := inherited CloseQuery; end;

end.
