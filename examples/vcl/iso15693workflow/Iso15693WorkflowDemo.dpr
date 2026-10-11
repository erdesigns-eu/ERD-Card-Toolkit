program Iso15693WorkflowDemo;

uses
  Vcl.Forms,
  Iso15693WorkflowDemo.Main in 'Iso15693WorkflowDemo.Main.pas' {Iso15693WorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TIso15693WorkflowDemoForm, Iso15693WorkflowDemoForm);
  Application.Run;
end.
