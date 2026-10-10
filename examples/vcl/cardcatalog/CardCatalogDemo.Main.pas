unit CardCatalogDemo.Main;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  ERD.Card.Bytes, ERD.Card.ATR, ERD.Card.ATR.Catalog, ERD.Card.ATR.Legacy,
  ERD.Card.APDU.Catalog, ERD.Card.EMV.Tags, ERD.Card.EMV.LegacyTags,
  ERD.Card.EMV.Aids, ERD.Card.PCSC.Monitor, ERD.Card.PCSC.Api;

type
  /// <summary>Independent card-catalog form with its own editable DFM and in-app reader discovery.</summary>
  TCardCatalogDemoForm = class(TForm)
  published
    /// <summary>Available native PC/SC reader selection label.</summary>
    ReaderLabel: TLabel;

    /// <summary>Available readers discovered within this demo.</summary>
    ReaderBox: TComboBox;

    /// <summary>Refresh the native reader list.</summary>
    RefreshButton: TButton;

    /// <summary>Read and inspect the offered card ATR from the selected reader.</summary>
    ReadAtrButton: TButton;

    /// <summary>Dictionary selection label.</summary>
    CatalogLabel: TLabel;

    /// <summary>ATR, EMV, APDU or AID inventory selection.</summary>
    CatalogBox: TComboBox;

    /// <summary>Inventory text-filter label.</summary>
    FilterLabel: TLabel;

    /// <summary>Case-insensitive metadata inventory filter.</summary>
    FilterEdit: TEdit;

    /// <summary>Exact lookup input label.</summary>
    LookupLabel: TLabel;

    /// <summary>ATR, tag/path, instruction, status or AID hexadecimal input.</summary>
    LookupEdit: TEdit;

    /// <summary>Run explicit offline metadata lookup.</summary>
    LookupButton: TButton;

    /// <summary>Every historical report, with all valid retained observations.</summary>
    InventoryBox: TListBox;

    /// <summary>Card metadata and lookup results.</summary>
    OutputMemo: TMemo;

    /// <summary>Latest native reader/card observation status.</summary>
    StatusLabel: TLabel;

    /// <summary>Creates owned lookup storage and starts native reader/card observation.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure FormCreate(Sender: TObject);

    /// <summary>Releases lookup storage owned by this form.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure FormDestroy(Sender: TObject);

    /// <summary>Restarts native inventory observation and preserves only the same selected reader.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure RefreshClick(Sender: TObject);

    /// <summary>Inspects the selected reader latest native offered-card ATR snapshot.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure ReadAtrClick(Sender: TObject);

    /// <summary>Refreshes the selected complete metadata inventory and its filter.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure CatalogChanged(Sender: TObject);

    /// <summary>Shows card metadata for the selected visible inventory row.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure InventorySelected(Sender: TObject);

    /// <summary>Looks up explicit metadata without probing card applications.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure LookupClick(Sender: TObject);

  private
    FMonitor: TSmartCardMonitor;
    FSnapshots: TPcscReaderSnapshots;
    FPreviousReader: string;
    FDetails: TStringList;
    procedure ReaderAdded(Sender: TObject; const AName: UnicodeString);
    procedure ReaderRemoved(Sender: TObject; const AName: UnicodeString);
    procedure CardChanged(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
    procedure MonitorError(Sender: TObject; const AStatus: Cardinal);
    procedure AddRow(const ACaption, ADetails: string);
  end;

var
  /// <summary>Application-owned independent catalog form.</summary>
  CardCatalogDemoForm: TCardCatalogDemoForm;

implementation

{$R *.dfm}

procedure TCardCatalogDemoForm.FormCreate(Sender: TObject);
begin
  FMonitor := TSmartCardMonitor.Create(Self);
  FMonitor.OnReaderAdded := ReaderAdded;
  FMonitor.OnReaderRemoved := ReaderRemoved;
  FMonitor.OnStateChanged := CardChanged;
  FMonitor.OnError := MonitorError;
  FDetails := TStringList.Create;
  CatalogBox.ItemIndex := 0;
  CatalogChanged(Self);
  RefreshClick(Self);
end;

procedure TCardCatalogDemoForm.FormDestroy(Sender: TObject);
begin
  FMonitor.Free;
  FDetails.Free;
end;

procedure TCardCatalogDemoForm.RefreshClick(Sender: TObject);
begin
  FPreviousReader := ReaderBox.Text;
  FMonitor.Stop;
  ReaderBox.Items.Clear;
  FSnapshots := nil;
  try
    FMonitor.Start;
    StatusLabel.Caption := 'Observing reader and card events';
  except
    on E: Exception do
      StatusLabel.Caption := E.ClassName + ': reader observation failed.';
  end;
end;

procedure TCardCatalogDemoForm.ReaderAdded(Sender: TObject; const AName: UnicodeString);
begin
  if ReaderBox.Items.IndexOf(AName) < 0 then
    ReaderBox.Items.Add(AName);
  if (FPreviousReader <> '') and (AName = FPreviousReader) then
    ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(AName);
  StatusLabel.Caption := 'Reader connected: ' + AName;
end;

procedure TCardCatalogDemoForm.ReaderRemoved(Sender: TObject; const AName: UnicodeString);
var
  I: Integer;
  Selected: string;
begin
  Selected := ReaderBox.Text;
  I := ReaderBox.Items.IndexOf(AName);
  if I >= 0 then
    ReaderBox.Items.Delete(I);
  ReaderBox.ItemIndex := ReaderBox.Items.IndexOf(Selected);
  for I := High(FSnapshots) downto 0 do
    if FSnapshots[I].ReaderName = AName then
    begin
      FSnapshots[I] := FSnapshots[High(FSnapshots)];
      SetLength(FSnapshots, Length(FSnapshots) - 1);
    end;
  StatusLabel.Caption := 'Reader disconnected: ' + AName;
end;

procedure TCardCatalogDemoForm.CardChanged(Sender: TObject; const ASnapshot: TPcscReaderSnapshot);
var
  I, Index: Integer;
begin
  Index := -1;
  for I := 0 to High(FSnapshots) do
    if FSnapshots[I].ReaderName = ASnapshot.ReaderName then
      Index := I;
  if Index < 0 then
  begin
    Index := Length(FSnapshots);
    SetLength(FSnapshots, Index + 1);
  end;
  FSnapshots[Index] := ASnapshot;
  FSnapshots[Index].Atr := CopyBytes(ASnapshot.Atr);
  if ASnapshot.State and PcscStatePresent <> 0 then
    StatusLabel.Caption := 'Card offered: ' + ASnapshot.ReaderName
  else
    StatusLabel.Caption := 'No card: ' + ASnapshot.ReaderName;
end;

procedure TCardCatalogDemoForm.MonitorError(Sender: TObject; const AStatus: Cardinal);
begin
  SetLength(FSnapshots, 0);
  ReaderBox.Items.Clear;
  StatusLabel.Caption := 'Reader observation stopped: ' + IntToHex(AStatus, 8);
end;

procedure TCardCatalogDemoForm.ReadAtrClick(Sender: TObject);
var
  I: Integer;
  Found: Boolean;
begin
  OutputMemo.Clear;
  try
    if not FMonitor.Active then
      raise Exception.Create('Reader observation is inactive.');
    if ReaderBox.ItemIndex < 0 then
      raise Exception.Create('Select an available reader.');
    Found := False;
    for I := 0 to High(FSnapshots) do
      if (FSnapshots[I].ReaderName = ReaderBox.Text) and
        (FSnapshots[I].State and PcscStatePresent <> 0) and
        (Length(FSnapshots[I].Atr) > 0) then
      begin
        LookupEdit.Text := BytesToHex(FSnapshots[I].Atr);
        Found := True;
        Break;
      end;
    if not Found then
      raise Exception.Create('No offered-card ATR snapshot available.');
    CatalogBox.ItemIndex := 0;
    CatalogChanged(Self);
    LookupClick(Self);
  except
    on E: Exception do
      OutputMemo.Text := 'Select a connected reader with an offered card.';
  end;
end;

procedure TCardCatalogDemoForm.AddRow(const ACaption, ADetails: string);
begin
  if (FilterEdit.Text <> '') and
    (Pos(UpperCase(FilterEdit.Text), UpperCase(ACaption + ADetails)) = 0) then
    Exit;
  InventoryBox.Items.Add(ACaption);
  FDetails.Add(ADetails);
end;

procedure TCardCatalogDemoForm.CatalogChanged(Sender: TObject);
var
  Reports: TLegacyAtrReports;
  Tags: TLegacyEmvTags;
  Instructions: TApduInstructionDescriptions;
  Statuses: TApduStatusDescriptions;
  Aids: TEmvAidDescriptions;
  I: Integer;
  Text, LabelText: string;
begin
  if FDetails = nil then
    Exit;
  InventoryBox.Items.BeginUpdate;
  try
    InventoryBox.Clear;
    FDetails.Clear;
    case CatalogBox.ItemIndex of
      0:
        begin
          Reports := TLegacyAtrCatalog.GetReports;
          for I := 0 to High(Reports) do
          begin
            Text := Reports[I].AtrHex + sLineBreak + Reports[I].Issuer + sLineBreak +
              'Scheme: ' + Reports[I].Scheme + '; type: ' + Reports[I].CardType +
              '; country: ' + Reports[I].Country + sLineBreak +
              'Category: ' + Reports[I].Category + sLineBreak +
              'Fingerprint is not a verified card identity.';
            LabelText := Reports[I].AtrHex + ' - ' + Reports[I].Issuer + ' - ' + Reports[I].Country;
            AddRow(LabelText, Text);
          end;
        end;
      1:
        begin
          Tags := TLegacyEmvTagCatalog.GetEntries;
          for I := 0 to High(Tags) do
            AddRow(Tags[I].PatternHex + ' - ' + Tags[I].Name,
              Tags[I].Name + sLineBreak + 'Tag/path meaning depends on issuer context and parent path.');
        end;
      2:
        begin
          Instructions := TApduCatalog.GetInstructions;
          for I := 0 to High(Instructions) do
            AddRow(IntToHex(Instructions[I].Instruction, 2) + ' - ' + Instructions[I].Description,
              Instructions[I].Description + sLineBreak + Instructions[I].Standard + sLineBreak +
              'Candidate meaning; CLA and card context still apply.');
        end;
      3:
        begin
          Statuses := TApduCatalog.GetHistoricalStatuses;
          for I := 0 to High(Statuses) do
          begin
            LabelText := IntToHex(Statuses[I].Pattern, 4) + ' - ' + Statuses[I].Description;
            AddRow(LabelText, Statuses[I].Description + sLineBreak +
              'Mask: ' + IntToHex(Statuses[I].Mask, 4));
          end;
        end;
      4:
        begin
          Aids := TEmvAidCatalog.GetEntries;
          for I := 0 to High(Aids) do
          begin
            LabelText := Aids[I].AidHex + ' - ' + Aids[I].Name;
            if Aids[I].PrefixOnly then
              LabelText := '[RID prefix] ' + LabelText;
            AddRow(LabelText, Aids[I].Name + sLineBreak +
              'No application selection or automatic card probing.');
          end;
        end;
    end;
  finally
    InventoryBox.Items.EndUpdate;
  end;
  OutputMemo.Text := IntToStr(InventoryBox.Items.Count) + ' matching inventory rows.';
end;

procedure TCardCatalogDemoForm.InventorySelected(Sender: TObject);
begin
  if (InventoryBox.ItemIndex >= 0) and (InventoryBox.ItemIndex < FDetails.Count) then
    OutputMemo.Text := FDetails[InventoryBox.ItemIndex];
end;

procedure TCardCatalogDemoForm.LookupClick(Sender: TObject);
var
  Catalog: TAtrCatalog;
  Matches: TAtrCatalogMatches;
  Tags: TEmvTagDescriptions;
  Paths: TLegacyEmvTags;
  Instructions: TApduInstructionDescriptions;
  Statuses: TApduStatusDescriptions;
  Aids: TEmvAidDescriptions;
  Data: TBytes;
  Number: Cardinal;
  I: Integer;
  Found: Boolean;
begin
  OutputMemo.Clear;
  try
    Data := HexToBytes(LookupEdit.Text, True);
    case CatalogBox.ItemIndex of
      0:
        begin
          Catalog := CreateDefaultAtrCatalog;
          try
            Matches := Catalog.FindMatches(Data);
            for I := 0 to High(Matches) do
              OutputMemo.Lines.Add(Matches[I].Description + ' - ' + Matches[I].Country +
                ' - ' + Matches[I].Scheme);
          finally
            Catalog.Free;
          end;
        end;
      1:
        begin
          if (Length(Data) < 1) or (Length(Data) > 4) then
            raise EConvertError.Create('Tag or path size');
          Number := 0;
          for I := 0 to High(Data) do
            Number := (Number shl 8) or Data[I];
          Tags := TEmvTagCatalog.FindDescriptions(Number);
          for I := 0 to High(Tags) do
            OutputMemo.Lines.Add(Tags[I].Name);
          Paths := TLegacyEmvTagCatalog.FindByPath(BytesToHex(Data));
          if Length(Tags) = 0 then
            for I := 0 to High(Paths) do
              OutputMemo.Lines.Add(Paths[I].Name + sLineBreak + 'Historical nested-path interpretation');
        end;
      2:
        begin
          if Length(Data) <> 1 then
            raise EConvertError.Create('Instruction size');
          Instructions := TApduCatalog.FindInstructions(Data[0]);
          for I := 0 to High(Instructions) do
            OutputMemo.Lines.Add(Instructions[I].Description + ' - ' + Instructions[I].Standard);
        end;
      3:
        begin
          if Length(Data) <> 2 then
            raise EConvertError.Create('Status-word size');
          Statuses := TApduCatalog.FindStatusDescriptions(Word(Data[0]) * 256 + Data[1]);
          for I := 0 to High(Statuses) do
            OutputMemo.Lines.Add(Statuses[I].Description);
        end;
      4:
        begin
          Aids := TEmvAidCatalog.GetEntries;
          Found := False;
          for I := 0 to High(Aids) do
            if Aids[I].AidHex = BytesToHex(Data) then
            begin
              Found := True;
              OutputMemo.Lines.Add(Aids[I].Name);
              if Aids[I].PrefixOnly then
                OutputMemo.Lines.Add('RID prefix; not an exact application instance.');
            end;
          if not Found then
            OutputMemo.Text := 'Unknown AID.';
        end;
    end;
    if OutputMemo.Lines.Count = 0 then
      OutputMemo.Text := 'No matching metadata.';
  except
    on E: Exception do
      OutputMemo.Text := E.ClassName + ': lookup input is invalid.';
  end;
end;

end.
