program Type2WorkflowDemo;

uses
  Vcl.Forms,
  Type2WorkflowDemo.Main in 'Type2WorkflowDemo.Main.pas' {Type2WorkflowDemoForm},
  ERD.Card.Demo.Workflows in '..\shared\ERD.Card.Demo.Workflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TType2WorkflowDemoForm, Type2WorkflowDemoForm);
  Application.Run;
end.
