program Iso15693Demo;

uses
  Vcl.Forms,
  Iso15693Demo.Main in 'Iso15693Demo.Main.pas',
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
  ConfigureCardFamilyDemo(dfIso15693);
  Application.CreateForm(TIso15693DemoForm, Iso15693DemoForm);
  Application.Run;
end.
