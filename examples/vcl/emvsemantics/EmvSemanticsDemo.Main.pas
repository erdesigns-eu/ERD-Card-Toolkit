unit EmvSemanticsDemo.Main;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls;

type
  /// <summary>Independent offline EMV semantic demo with its own designer-editable DFM.</summary>
  TEmvSemanticsDemoForm = class(TForm)
  published
    /// <summary>EMV data object label.</summary>
    TagLabel: TLabel;

    /// <summary>Explicit AIP/AUC/TVR/IAC/CVM List tag.</summary>
    TagBox: TComboBox;

    /// <summary>Specification version label.</summary>
    VersionLabel: TLabel;

    /// <summary>Explicit EMV Book 3 4.3 or 4.4.</summary>
    VersionBox: TComboBox;

    /// <summary>Raw hexadecimal value label.</summary>
    ValueLabel: TLabel;

    /// <summary>Unmodified hexadecimal value, no card access.</summary>
    ValueEdit: TEdit;

    /// <summary>Decode supplied metadata offline.</summary>
    DecodeButton: TButton;

    /// <summary>Fill synthetic selected-tag example.</summary>
    ExampleButton: TButton;

    /// <summary>Display unset bits as well as set bits.</summary>
    ShowUnsetCheck: TCheckBox;

    /// <summary>Display reserved bits without guessed semantics.</summary>
    ShowReservedCheck: TCheckBox;

    /// <summary>Version-dependent meanings and IAC/CVM interpretation.</summary>
    HelpMemo: TMemo;

    /// <summary>All decoded flags or ordered CVM rules.</summary>
    OutputMemo: TMemo;

    /// <summary>Initializes explicit tag/version choices.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure FormCreate(Sender: TObject);

    /// <summary>Decodes supplied bytes without any card command.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure DecodeClick(Sender: TObject);

    /// <summary>Fills a synthetic example for the selected tag.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure ExampleClick(Sender: TObject);

    /// <summary>Explains selected-tag and version semantics.</summary>
    /// <param name="Sender">The form or initiating designer control.</param>
    procedure TagChanged(Sender: TObject);

  end;

var
  /// <summary>Application-owned independent offline semantic form.</summary>
  EmvSemanticsDemoForm: TEmvSemanticsDemoForm;

implementation

uses
  ERD.Card.Bytes, ERD.Card.EMV.Semantics;

{$R *.dfm}

procedure TEmvSemanticsDemoForm.FormCreate(Sender: TObject);
begin
  TagBox.ItemIndex := 0; VersionBox.ItemIndex := 1;
  TagChanged(Self); ExampleClick(Self);
end;

procedure TEmvSemanticsDemoForm.TagChanged(Sender: TObject);
begin
  OutputMemo.Clear;
  HelpMemo.Text := 'Select Book 3 version explicitly. Contactless-reserved bits require a kernel specification. IAC bits are issuer policy criteria, not observed failures. CVM amounts are binary application-currency thresholds; rules are decoded without execution.';
end;

procedure TEmvSemanticsDemoForm.ExampleClick(Sender: TObject);
begin
  case TagBox.ItemIndex of
    0: ValueEdit.Text := '1800';
    1: ValueEdit.Text := 'FF80';
    2: ValueEdit.Text := '0080040800';
    3..5: ValueEdit.Text := '8000000000';
    6: ValueEdit.Text := '00000064000003E842031F00';
  end;
  OutputMemo.Clear;
end;

procedure TEmvSemanticsDemoForm.DecodeClick(Sender: TObject);
const
  Tags: array[0..5] of Cardinal = ($82, $9F07, $95, $9F0D, $9F0E, $9F0F);
var
  Data: TBytes;
  Bits: TEmvBitMeanings;
  List: TEmvCvmList;
  Version: TEmvSemanticVersion;
  I: Integer;
  Marker: string;
begin
  OutputMemo.Clear;
  try
    if (TagBox.ItemIndex < 0) or (VersionBox.ItemIndex < 0) then
      raise EEmvSemanticError.Create('Choose a tag and version.');
    Version := TEmvSemanticVersion(VersionBox.ItemIndex);
    Data := HexToBytes(ValueEdit.Text, True);
    if TagBox.ItemIndex = 6 then
    begin
      List := TEmvSemanticCodec.DecodeCvmList(Data, Version);
      OutputMemo.Lines.Add('Amount X: ' + UIntToStr(List.AmountX));
      OutputMemo.Lines.Add('Amount Y: ' + UIntToStr(List.AmountY));
      for I := 0 to High(List.Rules) do
      begin
        OutputMemo.Lines.Add(Format('Rule %d: %s; %s', [I + 1,
          List.Rules[I].MethodMeaning, List.Rules[I].ConditionMeaning]));
        OutputMemo.Lines.Add(Format('  Raw method %s; condition %s; continue on failure %s; reserved bit %s',
          [IntToHex(List.Rules[I].RawMethod, 2), IntToHex(List.Rules[I].Condition, 2),
           BoolToStr(List.Rules[I].ContinueOnFailure, True), BoolToStr(List.Rules[I].ReservedBitSet, True)]));
      end;
    end
    else
    begin
      Bits := TEmvSemanticCodec.DecodeBits(Tags[TagBox.ItemIndex], Data, Version);
      for I := 0 to High(Bits) do
      begin
        if not Bits[I].IsSet and not ShowUnsetCheck.Checked then Continue;
        if not Bits[I].Known and not ShowReservedCheck.Checked then Continue;
        Marker := '0'; if Bits[I].IsSet then Marker := '1';
        OutputMemo.Lines.Add(Format('Byte %d bit %d = %s: %s',
          [Bits[I].ByteNumber, Bits[I].BitNumber, Marker, Bits[I].Meaning]));
      end;
      if OutputMemo.Lines.Count = 0 then OutputMemo.Text := 'No bits matching the display filters.';
    end;
  except
    on E: Exception do OutputMemo.Text := E.ClassName + ': check exact value length and hexadecimal input.';
  end;
end;

end.
