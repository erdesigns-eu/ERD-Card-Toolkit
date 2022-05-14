program KeyGen;

uses
  Vcl.Forms,
  untMain in 'untMain.pas' {Form5},
  untLicense in '..\CardStudio\untLicense.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
