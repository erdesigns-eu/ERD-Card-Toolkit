unit untNew;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Imaging.pngimage, Vcl.ComCtrls;

type
  TfrmNew = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    gbAuthor: TGroupBox;
    edtAuthor: TEdit;
    gbWebsite: TGroupBox;
    edtWebsite: TEdit;
    gbEmail: TGroupBox;
    edtEmail: TEdit;
    gbTelegram: TGroupBox;
    edtTelegram: TEdit;
    gbComment: TGroupBox;
    memComment: TMemo;
    Panel2: TPanel;
    btnHelp: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LoadSettings;
    function Execute : TModalResult;
  end;

var
  frmNew: TfrmNew;

implementation

{$R *.dfm}

uses Registry, untConst;

{*******************************************************}
{             Load Settings from Registry               }
{*******************************************************}
procedure TfrmNew.LoadSettings;
var
  R : TRegistry;
begin
  R := TRegistry.Create;
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKey(ApplicationRegKey, True) then
    begin
      // Project Author
      if R.ValueExists(ProjectAuthor) then
      edtAuthor.Text := R.ReadString(ProjectAuthor);
      // Project Website
      if R.ValueExists(ProjectWebsite) then
      edtWebsite.Text := R.ReadString(ProjectWebsite);
      // Project Email
      if R.ValueExists(ProjectEmail) then
      edtEmail.Text := R.ReadString(ProjectEmail);
      // Project Telegram
      if R.ValueExists(ProjectTelegram) then
      edtTelegram.Text := R.ReadString(ProjectTelegram);
    end;
  finally
    R.Free;
  end;
end;

{*******************************************************}
{                   Execute Dialog                      }
{*******************************************************}
function TfrmNew.Execute : TModalResult;
begin
  LoadSettings;
  // Show
  Result := ShowModal;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmNew.FormCreate(Sender: TObject);
var
  I : Integer;
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Captions
  Caption        := Format('New %s Project', [ApplicationTitle]);;
  Label1.Caption := Format('New %s Project', [ApplicationTitle]);
  Label2.Caption := Format('Create a new %s project file..', [ApplicationTitle]);
  // Reset controls
  for I := 0 to ComponentCount -1 do
  begin
    // Memo's
    if Components[I].ClassNameIs('TMemo') and ((Components[I] as TMemo).Tag = 0) then
    (Components[I] as TMemo).Clear;
    // Edit's
    if Components[I].ClassNameIs('TEdit') and ((Components[I] as TEdit).Tag = 0) then
    (Components[I] as TEdit).Clear;
  end;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmNew.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  Release;
end;

end.
