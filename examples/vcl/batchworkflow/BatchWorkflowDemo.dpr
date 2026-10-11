program BatchWorkflowDemo;

uses
  Vcl.Forms,
  BatchWorkflowDemo.Main in 'BatchWorkflowDemo.Main.pas' {BatchWorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBatchWorkflowDemoForm, BatchWorkflowDemoForm);
  Application.Run;
end.
