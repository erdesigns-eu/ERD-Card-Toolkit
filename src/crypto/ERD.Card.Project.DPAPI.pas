unit ERD.Card.Project.DPAPI;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ERD.Card.Project.Secure;

type
  /// <summary>Inactive nonvisual current-user Windows DPAPI policy, bindable to TCardProtectedProjectStore.Provider.</summary>
  /// <remarks>No native calls occur at creation/streaming. Data is user-profile bound; not a portable key vault.</remarks>
  TCardWindowsUserProtection = class(TComponent, ICardProjectProtection)
  private
    FPolicy: ICardProjectProtection;
  public
    /// <summary>Creates an inactive retained current-user DPAPI policy.</summary>
    /// <param name="AOwner">Optional component owner.</param>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Encrypts and authenticates project bytes under the current Windows user profile.</summary>
    /// <param name="APlain">Owned input is not retained; bounded nonempty plaintext.</param>
    /// <returns>Independent native protected bytes; other platforms raise.</returns>
    function Protect(const APlain: TBytes): TBytes;
    /// <summary>Authenticates and decrypts native profile-bound data without prompts or fallback.</summary>
    /// <param name="AProtected">Exact bounded native protected bytes.</param>
    /// <returns>Independent authenticated plaintext; wrong profile/tampering raises.</returns>
    function Unprotect(const AProtected: TBytes): TBytes;
  end;

/// <summary>Creates inactive Windows current-user DPAPI project protection without interactive prompts.</summary>
/// <returns>Retained provider; no hardware or native protection calls occur until Protect/Unprotect.</returns>
/// <remarks>Data is tied to the Windows user/profile and DPAPI recovery policy. This is not portable
/// password encryption, machine-wide sharing or a credential vault. Other platforms fail explicitly on use.</remarks>
function CreateWindowsUserProjectProtection: ICardProjectProtection;

implementation

uses
{$IFDEF MSWINDOWS}
{$IFDEF FPC}Windows,{$ELSE}Winapi.Windows,{$ENDIF}
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Crypto;

type
  TUserProtection = class(TInterfacedObject, ICardProjectProtection)
  private
    function Process(const Data: TBytes; const Encrypt: Boolean): TBytes;
  public
    function Protect(const APlain: TBytes): TBytes;
    function Unprotect(const AProtected: TBytes): TBytes;
  end;

{$IFDEF MSWINDOWS}
type
  TProjectBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PProjectBlob = ^TProjectBlob;
function ProjectProtect(var Input: TProjectBlob; Description: PWideChar;
  Entropy: PProjectBlob; Reserved, Prompt: Pointer; Flags: DWORD;
  var Output: TProjectBlob): BOOL; stdcall; external 'crypt32.dll' name 'CryptProtectData';
function ProjectUnprotect(var Input: TProjectBlob; Description: Pointer;
  Entropy: PProjectBlob; Reserved, Prompt: Pointer; Flags: DWORD;
  var Output: TProjectBlob): BOOL; stdcall; external 'crypt32.dll' name 'CryptUnprotectData';
{$ENDIF}

function TUserProtection.Process(const Data: TBytes; const Encrypt: Boolean): TBytes;
{$IFDEF MSWINDOWS}
var Input, Output: TProjectBlob; Owned: TBytes; Success: BOOL;
{$ENDIF}
begin
  Result := nil;
  if (Length(Data)<1) or (Length(Data)>35*1024*1024) then
    raise ECardProjectProtectionError.Create('Invalid DPAPI input budget.');
{$IFDEF MSWINDOWS}
  Owned := CopyBytes(Data); Output := Default(TProjectBlob);
  try
    Input.cbData := DWORD(Length(Owned)); Input.pbData := @Owned[0];
    if Encrypt then Success := ProjectProtect(Input,nil,nil,nil,nil,1,Output)
    else Success := ProjectUnprotect(Input,nil,nil,nil,nil,1,Output);
    if not Success or (Output.pbData=nil) or (Output.cbData=0) or (Output.cbData>35*1024*1024) then
      raise ECardProjectProtectionError.Create('Windows user-profile protection failed.');
    SetLength(Result,Integer(Output.cbData)); Move(Output.pbData^,Result[0],Length(Result));
  finally
    if Output.pbData<>nil then begin
      if Output.cbData<=35*1024*1024 then FillChar(Output.pbData^,Integer(Output.cbData),0);
      LocalFree(HLOCAL(Output.pbData));
    end;
    TCardCrypto.Clear(Owned);
  end;
{$ELSE}
  raise ECardProjectProtectionError.Create('Windows DPAPI is unavailable on this platform.');
{$ENDIF}
end;

function TUserProtection.Protect(const APlain: TBytes): TBytes;
begin Result := Process(APlain,True); end;
function TUserProtection.Unprotect(const AProtected: TBytes): TBytes;
begin Result := Process(AProtected,False); end;
function CreateWindowsUserProjectProtection: ICardProjectProtection;
begin Result := TUserProtection.Create; end;

constructor TCardWindowsUserProtection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FPolicy := CreateWindowsUserProjectProtection;
end;

function TCardWindowsUserProtection.Protect(const APlain: TBytes): TBytes;
begin Result := FPolicy.Protect(APlain); end;
function TCardWindowsUserProtection.Unprotect(const AProtected: TBytes): TBytes;
begin Result := FPolicy.Unprotect(AProtected); end;

end.
