program Type4NdefDemo;

uses
  Vcl.Forms,
  Type4NdefDemo.Main in 'Type4NdefDemo.Main.pas',
  ERD.Card.Demo.FamilyForm in '..\shared\ERD.Card.Demo.FamilyForm.pas',
  ERD.Card.Demo.Families in '..\shared\ERD.Card.Demo.Families.pas',
  ERD.Card.Demo.FamilyOperations in '..\shared\ERD.Card.Demo.FamilyOperations.pas',
  ERD.Card.Demo.Form in '..\shared\ERD.Card.Demo.Form.pas',
  ERD.Card.Demo.Job in '..\shared\ERD.Card.Demo.Job.pas',
  ERD.Card.Demo.Operations in '..\shared\ERD.Card.Demo.Operations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  ConfigureCardFamilyDemo(dfType4);
  Application.CreateForm(TType4NdefDemoForm, Type4NdefDemoForm);
  Application.Run;
end.
