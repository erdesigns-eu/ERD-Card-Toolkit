program EmvInspectionDemo;

uses
  Vcl.Forms,
  EmvInspectionDemo.Main in 'EmvInspectionDemo.Main.pas' {EmvInspectionDemoForm},
  ERD.Card.Demo.Inspections in '..\shared\ERD.Card.Demo.Inspections.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEmvInspectionDemoForm, EmvInspectionDemoForm);
  Application.Run;
end.
