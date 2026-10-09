program Sle4404Demo;

uses
  Vcl.Forms,
  Sle4404Demo.Main in 'Sle4404Demo.Main.pas' {Sle4404DemoForm},
  ERD.Card.Demo.Families in '..\shared\ERD.Card.Demo.Families.pas',
  ERD.Card.Demo.FamilyOperations in '..\shared\ERD.Card.Demo.FamilyOperations.pas',
  ERD.Card.Demo.Controller in '..\shared\ERD.Card.Demo.Controller.pas',
  ERD.Card.Demo.Job in '..\shared\ERD.Card.Demo.Job.pas',
  ERD.Card.Demo.Operations in '..\shared\ERD.Card.Demo.Operations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSle4404DemoForm, Sle4404DemoForm);
  Application.Run;
end.
