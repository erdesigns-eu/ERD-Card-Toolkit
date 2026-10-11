program Sle4404WorkflowDemo;

uses
  Vcl.Forms,
  Sle4404WorkflowDemo.Main in 'Sle4404WorkflowDemo.Main.pas' {Sle4404WorkflowDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSle4404WorkflowDemoForm, Sle4404WorkflowDemoForm);
  Application.Run;
end.
