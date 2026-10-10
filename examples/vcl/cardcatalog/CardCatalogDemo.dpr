program CardCatalogDemo;

uses
  Vcl.Forms,
  CardCatalogDemo.Main in 'CardCatalogDemo.Main.pas' {CardCatalogDemoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TCardCatalogDemoForm, CardCatalogDemoForm);
  Application.Run;
end.
