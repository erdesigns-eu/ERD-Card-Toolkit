unit DesignIntf;

{$MODE DELPHI}

// FPC-only registration capture. Never add this folder to a Delphi IDE library path.
interface

uses Classes;

type
  /// <summary>Captured palette component classes for headless RTL streaming checks.</summary>
  TCapturedComponents = array of TComponentClass;

var
  /// <summary>Classes registered by the actual production Register procedure.</summary>
  CapturedComponents: TCapturedComponents;

/// <summary>Captures registrations without simulating RAD Studio designer APIs.</summary>
/// <param name="Page">Expected nonempty palette category.</param>
/// <param name="ComponentClasses">Inactive component classes to capture.</param>
procedure RegisterComponents(const Page: string; const ComponentClasses: array of TComponentClass);

implementation

uses SysUtils;

procedure RegisterComponents(const Page: string; const ComponentClasses: array of TComponentClass);
var C: TComponentClass; N: Integer;
begin
  if Page = '' then raise Exception.Create('Palette page is empty.');
  for C in ComponentClasses do
  begin
    N := Length(CapturedComponents); SetLength(CapturedComponents, N + 1);
    CapturedComponents[N] := C;
    RegisterClass(C);
  end;
end;

end.
