program SleCounterWorkflowDemo;

uses
  Vcl.Forms,
  SleCounterWorkflowDemo.Main in 'SleCounterWorkflowDemo.Main.pas' {SleCounterWorkflowDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSleCounterWorkflowDemoForm, SleCounterWorkflowDemoForm);
  Application.Run;
end.
