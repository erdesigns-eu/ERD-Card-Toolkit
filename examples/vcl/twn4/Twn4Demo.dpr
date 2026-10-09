program Twn4Demo;

uses
  Vcl.Forms,
  Twn4Demo.Main in 'Twn4Demo.Main.pas' {Twn4DemoForm},
  ERD.Card.Demo.Families in '..\shared\ERD.Card.Demo.Families.pas',
  ERD.Card.Demo.FamilyOperations in '..\shared\ERD.Card.Demo.FamilyOperations.pas',
  ERD.Card.Demo.Controller in '..\shared\ERD.Card.Demo.Controller.pas',
  ERD.Card.Demo.Job in '..\shared\ERD.Card.Demo.Job.pas',
  ERD.Card.Demo.Operations in '..\shared\ERD.Card.Demo.Operations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTwn4DemoForm, Twn4DemoForm);
  Application.Run;
end.
