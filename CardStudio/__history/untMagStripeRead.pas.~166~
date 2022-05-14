unit untMagStripeRead;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, Vcl.Menus, Vcl.ComCtrls,
  Vcl.PlatformDefaultStyleActnCtrls, System.Actions, Vcl.ActnList, Vcl.ActnMan,
  Vcl.StdActns, System.DateUtils;

type
  TfrmMagStripeRead = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel2: TPanel;
    btnHelp: TButton;
    btnRead: TButton;
    btnDecode: TButton;
    PopupMenu: TPopupMenu;
    Savetofile1: TMenuItem;
    AddToDB1: TMenuItem;
    SavetoDB2: TMenuItem;
    Decode1: TMenuItem;
    NB: TNotebook;
    GridPanel1: TGridPanel;
    gbTrack1: TGroupBox;
    memTrack1: TMemo;
    gbTrack2: TGroupBox;
    memTrack2: TMemo;
    gbTrack3: TGroupBox;
    memTrack3: TMemo;
    Panel3: TPanel;
    lblReadStatus: TLabel;
    SelectAll1: TMenuItem;
    N1: TMenuItem;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    N2: TMenuItem;
    Delete1: TMenuItem;
    Undo1: TMenuItem;
    N3: TMenuItem;
    btnCancel: TButton;
    N4: TMenuItem;
    WriteTracks1: TMenuItem;
    N5: TMenuItem;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure WriteTracks1Click(Sender: TObject);
    procedure PopupMenuPopup(Sender: TObject);
    procedure Savetofile1Click(Sender: TObject);
    procedure btnDecodeClick(Sender: TObject);
    procedure AddToDB1Click(Sender: TObject);
  private
    { Private declarations }
    CancelLoop : Boolean;
  public
    { Public declarations }
  end;

var
  frmMagStripeRead: TfrmMagStripeRead;

implementation

{$R *.dfm}

uses untMain, untConst, untLIB160, untMSR_API, untMagStripeWrite, JSON, 
     untDecodeTracks, untDatabaseAdd;

{*******************************************************}
{                  Form Create Event                    }
{*******************************************************}
procedure TfrmMagStripeRead.FormCreate(Sender: TObject);
begin
  // Try to connect to the magstripe reader if not already connected
  frmMain.TryMagStripeConnect;
  // Set width and height
  Width  := 640;
  Height := 480;
  // Clear memo's
  memTrack1.Clear;
  memTrack2.Clear;
  memTrack3.Clear;
  // Set view to page 1
  NB.PageIndex := 0;
  // Set Cancel Loop to false
  CancelLoop := False;
end;

{*******************************************************}
{                   Form Close Event                    }
{*******************************************************}
procedure TfrmMagStripeRead.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  CancelLoop := True;
  Action := caFree;
  Release;
  frmMagStripeRead := nil;
end;

{*******************************************************}
{                Form Activate Event                    }
{*******************************************************}
procedure TfrmMagStripeRead.FormActivate(Sender: TObject);
var
  CanRead : Boolean;
begin
  // Check if a magstripe reader is connected
  CanRead := (frmMain.YL160Connected = True) or (frmMain.MSRConnected = True);
  // Enable / Disable controls
  memTrack1.Enabled   := CanRead;
  memTrack2.Enabled   := CanRead;
  memTrack3.Enabled   := CanRead;
  btnRead.Enabled     := CanRead;
  btnDecode.Enabled   := CanRead;
  Savetofile1.Enabled := CanRead;
  AddtoDB1.Enabled    := CanRead;
  Decode1.Enabled     := CanRead;
end;

{*******************************************************}
{                    Read MagStripe                     }
{*******************************************************}
procedure TfrmMagStripeRead.btnReadClick(Sender: TObject);
var
  Swiped  : Boolean;
  Counter : Integer;
  TK1Dat  : array [0..1024] of AnsiChar;
  TK2Dat  : array [0..1024] of AnsiChar;
  TK3Dat  : array [0..1024] of AnsiChar;
  TKDatS  : AnsiString;
  TKDatX  : AnsiString;

  function Track(const S: AnsiString; const Track1: Boolean) : string;
  var
    PS, PE : Integer;
    SS, ES : string;
  begin
    // Set Start Sentinel - based on track 1 or 2/3
    if Track1 then SS := MST1StartSentinel else SS := MST2StartSentinel;
    // Set End Sentinel
    ES := MSTEndSentinel;
    // Find Sentinels
    PS := Pos(SS, String(S));
    PE := Pos(ES, String(S), 2);
    // Return track data between Sentinels
    if (PS > 0) and (PE > 0) and (PS < PE) then
    begin
      Result := Copy(S, PS +1, Length(S));
      Result := Copy(Result, 1, Pos(ES, Result) -1);
    end else
      Result := '';
  end;

  procedure ReadYL160;
  begin
    // Set YL160 busy status
    frmMain.YL160Busy := True;
    // Reset MagStripe
    MagReset;
    // Set counter to zero
    Counter := 0;
    // Set cancel loop to false
    CancelLoop := False;
    repeat
      Swiped := MagSwiped = 0;
      if Swiped then
      begin
        MagRead_DES(TK1Dat, TK2Dat, TK3Dat);
        Sleep(250);
        // Track 1
        SetString(TKDatS, TK1Dat, Length(TK1Dat));
        memTrack1.Text := Track(TKDatS, True);
        // Track 2
        SetString(TKDatS, TK2Dat, Length(TK2Dat));
        memTrack2.Text := Track(TKDatS, False);
        // Track 3
        SetString(TKDatS, TK3Dat, Length(TK3Dat));
        memTrack3.Text := Track(TKDatS, False);
      end else
      begin
        // Sleep
        Sleep(100);
        // Process messages
        Application.ProcessMessages;
      end;
      Inc(Counter);
    until Swiped or (Counter >= 100) or CancelLoop;
    // Reset MSR
    if (not Swiped) and ((Counter >= 100) or CancelLoop) then MagReset;
    // Back to the first view
    NB.PageIndex      := 0;
    btnRead.Enabled   := True;
    btnDecode.Enabled := True;
    // Set YL160 busy status
    frmMain.YL160Busy := False;
  end;

  procedure ReadMSR;
  begin
    // Set MSR busy status
    frmMain.MSRBusy := True;
    // Reset MSR
    MSR_Reset;
    // Initiate reading
    if MSR_Read = 48 then
    begin
      // Set counter to zero
      Counter := 0;
      // Set cancel loop to false
      CancelLoop := False;
      repeat
        Swiped := MSR_Get_Read_Data(TK1Dat, TK2Dat, TK3Dat) = 48;
        if Swiped then
        begin
          // Track 1
          SetString(TKDatS, TK1Dat, Length(TK1Dat));
          SetString(TKDatX, TK1Dat, Length(TK1Dat));
          memTrack1.Text := Track(TKDatS, True);
          // Track 2
          SetString(TKDatS, TK2Dat, Length(TK2Dat));
          memTrack2.Text := Track(TKDatS, False);
          // Check if track 2 data is in track 1 (MSR)
          if (Length(memTrack2.Text) = 0) and (Pos(MST2StartSentinel, TKDatX) > 0) then
          memTrack2.Text := Track(TKDatX, False);
          // Track 3
          SetString(TKDatS, TK3Dat, Length(TK3Dat));
          memTrack3.Text := Track(TKDatS, False);
        end else
        begin
          // Sleep
          Sleep(100);
          // Process messages
          Application.ProcessMessages;
        end;
        Inc(Counter);
      until Swiped or (Counter >= 100) or CancelLoop;
    end;
    // Reset MSR
    if (not Swiped) and ((Counter >= 100) or CancelLoop) then MSR_Reset;
    // Back to the first view
    NB.PageIndex      := 0;
    btnRead.Enabled   := True;
    btnDecode.Enabled := True;
    // Set MSR busy status
    frmMain.MSRBusy := False;
  end;

begin
  // Read YL160 magstripe
  if frmMain.YL160Connected and (not frmMain.YL160Busy) then
  begin
    NB.PageIndex      := 1;
    btnRead.Enabled   := False;
    btnDecode.Enabled := False;
    ReadYL160;
  end else

  // Read MSR magstripe
  if frmMain.MSRConnected and (not frmMain.MSRBusy) then
  begin
    NB.PageIndex := 1;
    btnRead.Enabled   := False;
    btnDecode.Enabled := False;
    ReadMSR;
  end;
end;

{*******************************************************}
{              Cancel Reading MagStripe                 }
{*******************************************************}
procedure TfrmMagStripeRead.btnCancelClick(Sender: TObject);
begin
  CancelLoop := True;
  Application.ProcessMessages;
end;


{*******************************************************}
{            Enable copy to writer menuitem             }
{*******************************************************}
procedure TfrmMagStripeRead.PopupMenuPopup(Sender: TObject);
begin
  WriteTracks1.Enabled := Assigned(frmMagStripeWrite) and (not frmMain.MSRBusy);
end;

{*******************************************************}
{           Copy Tracks to MagStripe Writer             }
{*******************************************************}
procedure TfrmMagStripeRead.WriteTracks1Click(Sender: TObject);
begin
  // Copy tracks to writer window
  if Assigned(frmMagStripeWrite) then
  begin
    frmMagStripeWrite.memTrack1.Text := memTrack1.Text;
    frmMagStripeWrite.memTrack2.Text := memTrack2.Text;
    frmMagStripeWrite.memTrack3.Text := memTrack3.Text;
  end;
end;

{*******************************************************}
{                 Write tracks to file                  }
{*******************************************************}
procedure TfrmMagStripeRead.Savetofile1Click(Sender: TObject);
var
  TRFile : TJSONObject;
  TSFile : TStringList;
begin
  TSFile := TStringList.Create;
  try
    TRFile := TJSONObject.Create();
    try
      TRFile.AddPair('dt', DateTimeToUnix(Now).ToString);
      TRFile.AddPair('t1', memTrack1.Text);
      TRFile.AddPair('t2', memTrack2.Text);
      TRFile.AddPair('t3', memTrack3.Text);
      TSFile.Text := TRFile.ToJSON;
      if SaveDialog.Execute(Handle) then
      begin
        TSFile.SaveToFile(SaveDialog.FileName);
      end;
    finally
      TRFile.free;
    end;
  finally
    TSFile.Free;
  end;
end;

{*******************************************************}
{                    Decode Tracks                      }
{*******************************************************}
procedure TfrmMagStripeRead.btnDecodeClick(Sender: TObject);

  procedure CopyToDecoder(const S: string; const T: Integer);
  begin
    with TfrmTracksDecode.Create(Application) do
    begin
      memTrack.Text := S;
      cbTrack.ItemIndex := T -1;
      btnDecode.Click;
      Show;
    end;
  end;

begin
  // If sender is Decode1 menuitem, copy the track from active memo
  if (Sender = Decode1) then
  begin
    case (PopupMenu.PopupComponent as TMemo).Tag of
      1 : CopyToDecoder(memTrack1.Text, 1);
      2 : CopyToDecoder(memTrack2.Text, 2);
      3 : CopyToDecoder(memTrack3.Text, 3);
    end;
  end else
  // Otherwise check which track memo has data, and copy the first ocurrence
  begin
    if (Length(memTrack1.Text) > 0) then
      CopyToDecoder(memTrack1.Text, 1)
    else
    if (Length(memTrack2.Text) > 0) then
      CopyToDecoder(memTrack2.Text, 2)
    else
    if (Length(memTrack3.Text) > 0) then
      CopyToDecoder(memTrack3.Text, 3);
  end;
end;

{*******************************************************}
{                   Add to Database                     }
{*******************************************************}
procedure TfrmMagStripeRead.AddToDB1Click(Sender: TObject);
begin
  with TfrmDatabaseAdd.Create(Application) do
  begin
    memTrack1.Text := frmMagStripeRead.memTrack1.Text;
    memTrack2.Text := frmMagStripeRead.memTrack2.Text;
    memTrack3.Text := frmMagStripeRead.memTrack3.Text;
    LoadFromTracks(
      frmMagStripeRead.memTrack1.Text,
      frmMagStripeRead.memTrack2.Text,
      frmMagStripeRead.memTrack3.Text
    );
    Show;
  end;
end;

end.
