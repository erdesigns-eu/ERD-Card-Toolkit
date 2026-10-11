program DesfirePersonalizationDemo;

uses
  Vcl.Forms,
  DesfirePersonalizationDemo.Main in 'DesfirePersonalizationDemo.Main.pas' {DesfirePersonalizationDemoForm},
  ERD.Card.Demo.FamilyWorkflows in '..\shared\ERD.Card.Demo.FamilyWorkflows.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDesfirePersonalizationDemoForm, DesfirePersonalizationDemoForm);
  Application.Run;
end.
