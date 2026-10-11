program SimWorkflowDemo;

uses
  Vcl.Forms,
  SimWorkflowDemo.Main in 'SimWorkflowDemo.Main.pas' {SimWorkflowDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSimWorkflowDemoForm, SimWorkflowDemoForm);
  Application.Run;
end.
