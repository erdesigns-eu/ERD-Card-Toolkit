unit untARQCCalculator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls;

type
  TfrmARQCCalculator = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnCalculate: TButton;
    gbSK: TGroupBox;
    edtSK: TEdit;
    gbTD: TGroupBox;
    memTD: TMemo;
    gbOutput: TGroupBox;
    memOutput: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCalculateClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmARQCCalculator: TfrmARQCCalculator;

implementation

{$R *.dfm}

uses untCipher, untEMVTools;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmARQCCalculator.FormCreate(Sender: TObject);
var
  I : Integer;
begin
  // Set width and height
  Width  := 550;
  Height := 460;
  // Clear memo's
  memOutput.Clear;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmARQCCalculator.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  Release;
end;

{*******************************************************}
{                    Calculate ARQC                     }
{*******************************************************}
procedure TfrmARQCCalculator.btnCalculateClick(Sender: TObject);
begin
  if (Length(edtSK.Text) = 32) and (Length(memTD.Text) > 0) then
  memOutput.Text := CalculateARQC(Hex2Bin(edtSK.Text), Hex2Bin(memTD.Text), 18);
end;

end.
