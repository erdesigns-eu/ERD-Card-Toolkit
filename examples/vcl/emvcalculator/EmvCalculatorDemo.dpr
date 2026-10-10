program EmvCalculatorDemo;

uses
  Vcl.Forms,
  EmvCalculatorDemo.Main in 'EmvCalculatorDemo.Main.pas' {EmvCalculatorDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEmvCalculatorDemoForm, EmvCalculatorDemoForm);
  Application.Run;
end.
