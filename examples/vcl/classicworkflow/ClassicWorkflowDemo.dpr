program ClassicWorkflowDemo;

uses
  Vcl.Forms,
  ClassicWorkflowDemo.Main in 'ClassicWorkflowDemo.Main.pas' {ClassicWorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TClassicWorkflowDemoForm, ClassicWorkflowDemoForm);
  Application.Run;
end.
