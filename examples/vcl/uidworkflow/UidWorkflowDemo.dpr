program UidWorkflowDemo;

uses
  Vcl.Forms,
  UidWorkflowDemo.Main in 'UidWorkflowDemo.Main.pas' {UidWorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUidWorkflowDemoForm, UidWorkflowDemoForm);
  Application.Run;
end.
