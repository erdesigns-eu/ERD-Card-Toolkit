program MobibInspectionDemo;

uses
  Vcl.Forms,
  MobibInspectionDemo.Main in 'MobibInspectionDemo.Main.pas' {MobibInspectionDemoForm},
  ERD.Card.Demo.Inspections in '..\shared\ERD.Card.Demo.Inspections.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMobibInspectionDemoForm, MobibInspectionDemoForm);
  Application.Run;
end.
