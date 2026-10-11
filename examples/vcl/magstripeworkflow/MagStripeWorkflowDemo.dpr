program MagStripeWorkflowDemo;

uses
  Vcl.Forms,
  MagStripeWorkflowDemo.Main in 'MagStripeWorkflowDemo.Main.pas' {MagStripeWorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMagStripeWorkflowDemoForm, MagStripeWorkflowDemoForm);
  Application.Run;
end.
