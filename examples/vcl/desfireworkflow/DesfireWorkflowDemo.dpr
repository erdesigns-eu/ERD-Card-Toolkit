program DesfireWorkflowDemo;

uses
  Vcl.Forms,
  DesfireWorkflowDemo.Main in 'DesfireWorkflowDemo.Main.pas' {DesfireWorkflowDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDesfireWorkflowDemoForm, DesfireWorkflowDemoForm);
  Application.Run;
end.
