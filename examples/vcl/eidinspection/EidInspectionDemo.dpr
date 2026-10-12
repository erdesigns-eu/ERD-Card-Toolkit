program EidInspectionDemo;

uses
  Vcl.Forms,
  EidInspectionDemo.Main in 'EidInspectionDemo.Main.pas' {EidInspectionDemoForm},
  ERD.Card.Demo.Inspections in '..\shared\ERD.Card.Demo.Inspections.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEidInspectionDemoForm, EidInspectionDemoForm);
  Application.Run;
end.
