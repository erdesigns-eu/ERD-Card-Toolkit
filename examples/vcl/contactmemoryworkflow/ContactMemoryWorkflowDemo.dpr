program ContactMemoryWorkflowDemo;

uses
  Vcl.Forms,
  ContactMemoryWorkflowDemo.Main in 'ContactMemoryWorkflowDemo.Main.pas' {ContactMemoryWorkflowDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TContactMemoryWorkflowDemoForm, ContactMemoryWorkflowDemoForm);
  Application.Run;
end.
