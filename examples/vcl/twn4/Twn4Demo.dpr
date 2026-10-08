program Twn4Demo;

uses
  Vcl.Forms,
  Twn4Demo.Main in 'Twn4Demo.Main.pas',
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
  ConfigureCardFamilyDemo(dfTwn4);
  Application.CreateForm(TTwn4DemoForm, Twn4DemoForm);
  Application.Run;
end.
