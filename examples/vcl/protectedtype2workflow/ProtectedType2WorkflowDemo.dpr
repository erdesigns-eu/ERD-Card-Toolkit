program ProtectedType2WorkflowDemo;

uses
  Vcl.Forms,
  ProtectedType2WorkflowDemo.Main in 'ProtectedType2WorkflowDemo.Main.pas' {ProtectedType2WorkflowDemoForm},
  ERD.Card.Demo.ProtectedWorkflows in '..\shared\ERD.Card.Demo.ProtectedWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TProtectedType2WorkflowDemoForm, ProtectedType2WorkflowDemoForm);
  Application.Run;
end.
