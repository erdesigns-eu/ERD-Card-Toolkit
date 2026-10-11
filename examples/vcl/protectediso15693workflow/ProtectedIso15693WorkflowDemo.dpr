program ProtectedIso15693WorkflowDemo;

uses
  Vcl.Forms,
  ProtectedIso15693WorkflowDemo.Main in 'ProtectedIso15693WorkflowDemo.Main.pas' {ProtectedIso15693WorkflowDemoForm},
  ERD.Card.Demo.ProtectedWorkflows in '..\shared\ERD.Card.Demo.ProtectedWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TProtectedIso15693WorkflowDemoForm, ProtectedIso15693WorkflowDemoForm);
  Application.Run;
end.
