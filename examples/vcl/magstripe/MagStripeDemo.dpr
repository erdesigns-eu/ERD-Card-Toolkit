program MagStripeDemo;

uses
  Vcl.Forms,
  MagStripeDemo.Main in 'MagStripeDemo.Main.pas' {MagStripeForm},
  ERD.Card.Demo.Form in '..\shared\ERD.Card.Demo.Form.pas',
  ERD.Card.Demo.Job in '..\shared\ERD.Card.Demo.Job.pas',
  ERD.Card.Demo.Operations in '..\shared\ERD.Card.Demo.Operations.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMagStripeDemoForm, MagStripeForm);
  Application.Run;
end.
