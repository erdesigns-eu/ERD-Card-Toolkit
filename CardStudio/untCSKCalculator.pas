unit untCSKCalculator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls;

type
  TfrmCSKCalculator = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnCalculate: TButton;
    gbUDK: TGroupBox;
    edtUDK: TEdit;
    gbATC: TGroupBox;
    edtATC: TEdit;
    gbOutput: TGroupBox;
    memOutput: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnCalculateClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCSKCalculator: TfrmCSKCalculator;

implementation

{$R *.dfm}

uses untCipher, untEMVTools;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmCSKCalculator.FormCreate(Sender: TObject);
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
procedure TfrmCSKCalculator.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  Release;
end;

{*******************************************************}
{                    Calculate CSK                      }
{*******************************************************}
procedure TfrmCSKCalculator.btnCalculateClick(Sender: TObject);
begin
  if (Length(edtUDK.Text) = 32) and (Length(edtATC.Text) = 4) then
  memOutput.Text := CalculateCommonSessionKey(Hex2Bin(edtUDK.Text), Hex2Bin(edtATC.Text));
end;

end.
