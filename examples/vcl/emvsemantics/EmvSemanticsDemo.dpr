program EmvSemanticsDemo;

uses
  Vcl.Forms,
  EmvSemanticsDemo.Main in 'EmvSemanticsDemo.Main.pas' {EmvSemanticsDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEmvSemanticsDemoForm, EmvSemanticsDemoForm);
  Application.Run;
end.
