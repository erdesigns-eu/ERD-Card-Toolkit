unit untCardStudioProject;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls,
  untCardStudioFile, Vcl.ToolWin, Vcl.Menus;

type
  TfrmCardStudioProject = class(TForm)
    tvCard: TTreeView;
    Splitter: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FFile : TCardStudioFile;
  public
    { Public declarations }
    procedure LoadFromFile(const Filename: string);
    procedure NewFile(const Author: string; const Website: string; const Email: string; const Telegram: string; const Comment: string);

    property &File: TCardStudioFile read FFile;
  end;

var
  frmCardStudioProject: TfrmCardStudioProject;

implementation

{$R *.dfm}

uses untASNParser, untConst, untEMVTools;

{*******************************************************}
{              Load project from Filename               }
{*******************************************************}
procedure TfrmCardStudioProject.LoadFromFile(const Filename: string);
begin
  if FileExists(Filename) then &File.LoadFromFile(Filename);
end;

{*******************************************************}
{                 Create new project                    }
{*******************************************************}
procedure TfrmCardStudioProject.NewFile(const Author: string; const Website: string;
  const Email: string; const Telegram: string; const Comment: string);
begin
  with &File do
  begin
    FileInformation.Author   := Author;
    FileInformation.Website  := Website;
    FileInformation.Email    := Email;
    FileInformation.Telegram := Telegram;
    FileInformation.Comments := Comment;
  end;
end;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmCardStudioProject.FormCreate(Sender: TObject);
begin
  // Set width and height
  Width  := 640;
  Height := 480;
  // Ceate CardStudio Project File Class
  FFile := TCardStudioFile.Create;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmCardStudioProject.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FFile.Free;
  Action := caFree;
  Release;
end;

end.
