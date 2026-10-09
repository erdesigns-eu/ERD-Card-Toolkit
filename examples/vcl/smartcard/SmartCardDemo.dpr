program SmartCardDemo;

uses
  Vcl.Forms,
  SmartCardDemo.Main in 'SmartCardDemo.Main.pas' {SmartCardForm},
  ERD.Card.Demo.Controller in '..\shared\ERD.Card.Demo.Controller.pas',
  ERD.Card.Demo.Job in '..\shared\ERD.Card.Demo.Job.pas',
  ERD.Card.Demo.Operations in '..\shared\ERD.Card.Demo.Operations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSmartCardDemoForm, SmartCardForm);
  Application.Run;
end.
