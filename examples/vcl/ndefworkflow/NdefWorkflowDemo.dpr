program NdefWorkflowDemo;

uses
  Vcl.Forms,
  NdefWorkflowDemo.Main in 'NdefWorkflowDemo.Main.pas' {NdefWorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TNdefWorkflowDemoForm, NdefWorkflowDemoForm);
  Application.Run;
end.
