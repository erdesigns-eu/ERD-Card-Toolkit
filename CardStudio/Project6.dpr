program Project6;

uses
  Vcl.Forms,
  Unit7 in 'Unit7.pas' {Form7},
  untASN1Parser in 'untASN1Parser.pas',
  MSXml2 in 'MSXml2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm7, Form7);
  Application.Run;
end.
