program GlobalPlatformDemo;

uses
  Vcl.Forms,
  GlobalPlatformDemo.Main in 'GlobalPlatformDemo.Main.pas' {GlobalPlatformDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TGlobalPlatformDemoForm, GlobalPlatformDemoForm);
  Application.Run;
end.
