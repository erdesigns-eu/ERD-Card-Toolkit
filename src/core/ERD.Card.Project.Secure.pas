unit ERD.Card.Project.Secure;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Project;

type
  /// <summary>Bounded protected-project storage or protection-provider failure.</summary>
  ECardProjectProtectionError = class(Exception);
  /// <summary>Application-selected authenticated protection; no credentials are automatically serialized.</summary>
  ICardProjectProtection = interface
    ['{207B568F-46D6-41A9-8AB5-067A6997B8B9}']
    /// <summary>Protects owned plaintext with confidentiality and integrity; returns independent ciphertext.</summary>
    /// <param name="APlain">Nonempty bounded bytes, not retained.</param>
    /// <returns>Owned protected bytes; empty output is invalid.</returns>
    function Protect(const APlain: TBytes): TBytes;
    /// <summary>Authenticates protected bytes before exposing plaintext; failures must raise.</summary>
    /// <param name="AProtected">Exact bounded protected bytes, not retained.</param>
    /// <returns>Owned authenticated plaintext; no unauthenticated fallback is permitted.</returns>
    function Unprotect(const AProtected: TBytes): TBytes;
  end;
  /// <summary>Nonvisual encrypted project stream storage with namespace/version checks and atomic import.</summary>
  /// <remarks>Use on one owner thread with an explicit protection provider. Failed writes preserve Dirty,
  /// but may leave partial ciphertext in the stream; durable atomic file replacement is a separate policy.</remarks>
  TCardProtectedProjectStore = class(TComponent)
  private
    FProtection: ICardProjectProtection;
    FProvider: TComponent;
    procedure SetProvider(const Value: TComponent);
    procedure SetProtection(const Value: ICardProjectProtection);
  protected
    /// <summary>Clears a component-backed protection policy before its provider is destroyed.</summary>
    /// <param name="AComponent">Provider being removed.</param>
    /// <param name="Operation">Component notification kind.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    /// <summary>Protects a complete project archive and marks saved only after successful stream writing.</summary>
    /// <param name="AProject">Initialized project; artifacts are never passed directly to the stream.</param>
    /// <param name="AStream">Non-nil caller-owned writable stream.</param>
    procedure Save(const AProject: TCardProject; const AStream: TStream);
    /// <summary>Authenticates, validates and imports a complete protected envelope without modifying the old project on failure.</summary>
    /// <param name="AProject">Non-nil destination project, changed only after full validation.</param>
    /// <param name="AStream">Non-nil caller-owned seekable stream positioned at the envelope.</param>
    procedure Load(const AProject: TCardProject; const AStream: TStream);
    /// <summary>Explicit authenticated protection policy; nil refuses protected I/O.</summary>
    property Protection: ICardProjectProtection read FProtection write SetProtection;
  published
    /// <summary>Live component implementing ICardProjectProtection; connect a Windows user protection component here.</summary>
    /// <remarks>Free-notifications clear this policy; direct interface assignment removes the component binding.</remarks>
    property Provider: TComponent read FProvider write SetProvider;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.Crypto;

const Magic: array[0..7] of Byte = ($45,$52,$44,$50,$52,$4A,$30,$31);

procedure CheckMagic(const Data: TBytes);
var I: Integer;
begin
  if Length(Data)<=Length(Magic) then raise ECardProjectProtectionError.Create('Invalid protected project envelope.');
  for I := 0 to High(Magic) do if Data[I]<>Magic[I] then
    raise ECardProjectProtectionError.Create('Unsupported protected project envelope.');
end;

procedure TCardProtectedProjectStore.SetProvider(const Value: TComponent);
var Policy: ICardProjectProtection;
begin
  Policy := nil;
  if Value<>nil then
    if (csDestroying in Value.ComponentState) or not Supports(Value,ICardProjectProtection,Policy) then
      raise ECardProjectProtectionError.Create('An authenticated protection component is required.');
  if FProvider<>nil then FProvider.RemoveFreeNotification(Self);
  FProvider := Value; FProtection := Policy;
  if Value<>nil then Value.FreeNotification(Self);
end;

procedure TCardProtectedProjectStore.SetProtection(const Value: ICardProjectProtection);
begin
  if FProvider<>nil then FProvider.RemoveFreeNotification(Self);
  FProvider := nil; FProtection := Value;
end;

procedure TCardProtectedProjectStore.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation=opRemove) and (AComponent=FProvider) then begin
    FProvider := nil; FProtection := nil;
  end;
  inherited Notification(AComponent,Operation);
end;

procedure TCardProtectedProjectStore.Save(const AProject: TCardProject; const AStream: TStream);
var Text: string; Plain, Cipher, Envelope: TBytes; I: Integer;
begin
  if (AProject=nil) or (AStream=nil) or (FProtection=nil) then
    raise ECardProjectProtectionError.Create('A project, stream and protection policy are required.');
  try
    Text := AProject.ExportText; SetLength(Plain,8+Length(Text));
    Move(Magic[0],Plain[0],8);
    for I := 1 to Length(Text) do Plain[I+7] := Byte(Ord(Text[I]));
    Cipher := FProtection.Protect(Plain);
    if (Length(Cipher)<1) or (Length(Cipher)>35*1024*1024) then
      raise ECardProjectProtectionError.Create('Protected project budget exceeded.');
    SetLength(Envelope,8+Length(Cipher)); Move(Magic[0],Envelope[0],8);
    Move(Cipher[0],Envelope[8],Length(Cipher));
    AStream.WriteBuffer(Envelope[0],Length(Envelope)); AProject.MarkSaved;
  finally
    TCardCrypto.Clear(Plain); TCardCrypto.Clear(Cipher); TCardCrypto.Clear(Envelope);
  end;
end;

procedure TCardProtectedProjectStore.Load(const AProject: TCardProject; const AStream: TStream);
var Envelope, Cipher, Plain: TBytes; Remaining: Int64; Text: string; I: Integer;
begin
  if (AProject=nil) or (AStream=nil) or (FProtection=nil) then
    raise ECardProjectProtectionError.Create('A project, stream and protection policy are required.');
  Remaining := AStream.Size-AStream.Position;
  if (Remaining<=8) or (Remaining>35*1024*1024+8) then
    raise ECardProjectProtectionError.Create('Protected project stream size exceeded.');
  try
    SetLength(Envelope,Integer(Remaining)); AStream.ReadBuffer(Envelope[0],Length(Envelope));
    CheckMagic(Envelope); Cipher := Copy(Envelope,8,Length(Envelope)-8);
    Plain := FProtection.Unprotect(Cipher); CheckMagic(Plain);
    if Length(Plain)>34*1024*1024+8 then raise ECardProjectProtectionError.Create('Plain project budget exceeded.');
    SetLength(Text,Length(Plain)-8);
    for I := 8 to High(Plain) do begin
      if Plain[I]>127 then raise ECardProjectProtectionError.Create('Invalid authenticated project encoding.');
      Text[I-7] := Char(Plain[I]);
    end;
    AProject.ImportText(Text);
  finally
    TCardCrypto.Clear(Envelope); TCardCrypto.Clear(Cipher); TCardCrypto.Clear(Plain);
  end;
end;

end.
