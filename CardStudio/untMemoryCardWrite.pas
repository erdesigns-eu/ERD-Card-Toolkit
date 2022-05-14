unit untMemoryCardWrite;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, untPCSC, untUSB, Registry;

type
  TfrmMemoryCardWrite = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnWrite: TButton;
    btnSettings: TButton;
    gbReader: TGroupBox;
    cbReader: TComboBox;
    pnlCardHolder: TPanel;
    gbAddress: TGroupBox;
    edtAddress: TEdit;
    gbPINCode: TGroupBox;
    edtPINCode: TEdit;
    gbData: TGroupBox;
    memData: TMemo;
    gbResponse: TGroupBox;
    memResponse: TMemo;
    btnSave: TButton;
    SaveDialog: TSaveDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    { Private declarations }
    PCSC         : TPCSC;
    FUSBNotifier : TComponentUSB;
    FSelectCard  : Boolean;

    procedure USBArrivalRemoval(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmMemoryCardWrite: TfrmMemoryCardWrite;

implementation

{$R *.dfm}

uses untConst, untEMVTools, untAPDUParser, untSettings, Math;

{*******************************************************}
{               USB Insert/Remove Event                 }
{*******************************************************}
procedure TfrmMemoryCardWrite.USBArrivalRemoval(Sender: TObject);
begin
  // Reload SmartCard Reader/Writers
  PCSC.Init;
  // Populate list
  cbReader.Items.Assign(PCSC.ReaderList);
  if cbReader.Items.Count > 0 then
  begin
    PCSC.UseReaderNum := 0;
    cbReader.ItemIndex := 0;
  end;
  // Disconnect PCSC
  PCSC.Disconnect;
  PCSC.Close;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmMemoryCardWrite.FormCreate(Sender: TObject);
var
  R : TRegistry;
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Create PCSC
  PCSC := TPCSC.Create;
  PCSC.Init;
  // Populate SmartCard readers/writers
  cbReader.Items.Assign(PCSC.ReaderList);
  if cbReader.Items.Count > 0 then
  begin
    R := TRegistry.Create;
    try
      R.RootKey := HKEY_CURRENT_USER;
      if R.OpenKey(ApplicationRegKey, True) and R.ValueExists(MCDefault) and R.ValueExists(MCSLE4442Select) and R.ValueExists(MCSLE4442PIN) then
      begin
        cbReader.ItemIndex := cbReader.Items.IndexOf(R.ReadString(MCDefault));
        PCSC.UseReaderNum := cbReader.ItemIndex;
        FSelectCard := R.ReadBool(MCSLE4442Select);
        edtPINCode.Text := R.ReadString(MCSLE4442PIN);
      end else
      begin
        PCSC.UseReaderNum := 0;
        cbReader.ItemIndex := 0;
        FSelectCard := False;
        edtPINCode.Text := '';
      end;
    finally
      R.Free;
    end;
  end;
  // Disconnect PCSC
  PCSC.Disconnect;
  PCSC.Close;
  // Create USB insert/remove notifier component
  FUSBNotifier := TComponentUSB.Create(Self);
  FUSBNotifier.OnUSBArrival := USBArrivalRemoval;
  FUSBNotifier.OnUSBRemove  := USBArrivalRemoval;
  // Clear data memo
  memData.Clear;
  // Clear response memo
  memResponse.Clear;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmMemoryCardWrite.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  // Free USB insert/remove notifier component
  FUSBNotifier.Destroy;
  // Free PCSC
  PCSC.Free;
  // Free Form
  Action := caFree;
  Release;
end;

{*******************************************************}
{                Show Settings Dialog                   }
{*******************************************************}
procedure TfrmMemoryCardWrite.btnSettingsClick(Sender: TObject);
begin
  with TfrmSettings.Create(Application) do
  if Execute(8) = MROK then SaveSettings;
  // Enable/Disable controls
  FormCreate(Self);
end;

{*******************************************************}
{                   Write Memory Card                   }
{*******************************************************}
procedure TfrmMemoryCardWrite.btnWriteClick(Sender: TObject);

  function FormatData(const D: string) : string;
  var
    I, X : Integer;
  begin
    Result := '';
    X := 1;
    for I := 1 to Ceil(Length(D) / 2) do
    begin
      Result := Result + Copy(D, X, 2) + ' ';
      Inc(X, 2);
    end;
    Result := Trim(Result);
  end;

  function SelectCard : Boolean;
  begin
    Result := Bin2HexExt(PCSC.GetResponseFromCard(Hex2Bin('FF A4 00 00 01 06'))) = '90 00';
  end;

  function WritePinCode(const PINCode: AnsiString) : Boolean;
  begin
    Result := Bin2HexExt(PCSC.GetResponseFromCard(Hex2Bin(
      Format('FF 20 00 00 %.*x %s', [2, Length(PINCode) div 2, FormatData(PINCode)])
      //
    ))) = '90 00';
  end;

  function WriteMemoryCard(const Address: AnsiString; const Data: AnsiString) : string;
  begin
    Result := Bin2HexExt(PCSC.GetResponseFromCard(Hex2Bin(
      Format('FF D6 00 %s %.*x %s', [Address, 2, Length(Data) div 2, FormatData(Data)])
    )));
  end;

const
  DataLen = 32;
var
  S : AnsiString;
  P : TAPDUParser;
  I,
  L : Integer;
  B : Boolean;
begin
  B := True;
  if not TryStrToInt('$' + edtAddress.Text, L) then
  begin
    B := False;
    Application.MessageBox('Address needs to be valid HEX format!', ApplicationTitle, MB_ICONWARNING or MB_OK);
  end;
  if TryStrToInt('$' + edtAddress.Text, L) and (L = 0) then
  begin
    B := False;
    Application.MessageBox('Address needs to be higher than zero!', ApplicationTitle, MB_ICONWARNING or MB_OK);
  end;
  if (edtPINCode.Text <> '') and (not TryStrToInt('$' + edtPINCode.Text, L)) then
  begin
    B := False;
    Application.MessageBox('PIN Code needs to be valid HEX format!', ApplicationTitle, MB_ICONWARNING or MB_OK);
  end;
  if (cbReader.ItemIndex = -1) or (not B) then Exit;
  // Initialize Card Reader/Writer
  PCSC.Init;
  PCSC.UseReaderNum := cbReader.ItemIndex;
  if PCSC.Open and PCSC.Connect then
  with memResponse.Lines do
  begin
    BeginUpdate;
    // Clear
    Clear;
    // Header
    Add(MCWriteHeader);
    // Select Card
    if FSelectCard then
    begin
      if SelectCard then
      begin
        if WritePinCode(edtPINCode.Text) then
        begin
          // Write to card
          S := WriteMemoryCard(edtAddress.Text, StringReplace(StringReplace(StringReplace(memData.Text, ' ', '', [rfReplaceAll]), #10, ' ', [rfReplaceAll]), #13, ' ', [rfReplaceAll]));
          // Create parser
          P := TAPDUParser.Create('', StringReplace(S, ' ', '', [rfReplaceAll]));
          try
            // SW 1
            Add(Format(MCWriteRespSW1, [2, P.Response.SW1]));
            // SW 2
            Add(Format(MCWriteRespSW2, [2, P.Response.SW2]));
            // Response code description
            Add(Format(MCWriteRespStatus, [P.ResponseStatus.Description]));
            // Data
            L := 1;
            for I := 1 to Ceil(Length(memData.Text) / DataLen) do
            begin
              if I = 1 then
              begin
                Add(FormatData(Copy(memData.Text, L, DataLen)));
                Inc(L, DataLen);
              end else
              begin
                Add(FormatData(Copy(memData.Text, L, DataLen)));
                Inc(L, DataLen);
              end;
            end;
          finally
            P.Free;
          end;
        end else
        begin
          Add('Invalid PIN Code!');
        end;
      end else
      begin
        Add('Failed to select the card!');
      end;
    end else
    begin
      if WritePinCode(edtPINCode.Text) then
      begin
        // Write to card
        S := WriteMemoryCard(edtAddress.Text, StringReplace(StringReplace(StringReplace(memData.Text, ' ', '', [rfReplaceAll]), #10, ' ', [rfReplaceAll]), #13, ' ', [rfReplaceAll]));
        // Create parser
        P := TAPDUParser.Create('', StringReplace(S, ' ', '', [rfReplaceAll]));
        try
          // SW 1
          Add(Format(MCWriteRespSW1, [2, P.Response.SW1]));
          // SW 2
          Add(Format(MCWriteRespSW2, [2, P.Response.SW2]));
          // Response code description
          Add(Format(MCWriteRespStatus, [P.ResponseStatus.Description]));
          // Data
          L := 1;
          for I := 1 to Ceil(Length(memData.Text) / DataLen) do
          begin
            if I = 1 then
            begin
              Add(FormatData(Copy(memData.Text, L, DataLen)));
              Inc(L, DataLen);
            end else
            begin
              Add(FormatData(Copy(memData.Text, L, DataLen)));
              Inc(L, DataLen);
            end;
          end;
        finally
          P.Free;
        end;
      end else
      begin
        Add('Invalid PIN Code!');
      end;
    end;
    EndUpdate;
  end;
  PCSC.Disconnect;
  PCSC.Close;
  //
  btnSave.Enabled := memResponse.Text <> '';
end;

{*******************************************************}
{                Save Decoded APDU Data                 }
{*******************************************************}
procedure TfrmMemoryCardWrite.btnSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute(Handle) and (SaveDialog.FileName <> '') then
  begin
    memResponse.Lines.SaveToFile(SaveDialog.FileName);
  end;
end;

end.
