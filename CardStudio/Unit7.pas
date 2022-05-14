unit Unit7;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm7 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Memo2: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form7: TForm7;

implementation

{$R *.dfm}

uses untASN1Parser;


procedure TForm7.Button1Click(Sender: TObject);
var
  P : TAsn1Parser;
  I : Integer;
begin
  P := TAsn1Parser.Create;
  try
    P.Parse(memo1.Text);
    for I := 0 to P.Tree.childNodes.length -1 do
    memo2.Lines.Add(P.Tree.childNodes.item[I].nodeName);
  finally
    P.Free;
  end;
end;

end.
