program InspectCardTools;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.ATR, ERD.Card.ATR.Catalog, ERD.Card.EMV.Tags;

procedure Run;
var Catalog:TAtrCatalog; Matches:TAtrCatalogMatches; Tag:TEmvTagDescription;
  Bytes:TBytes; Value:Cardinal; I:Integer;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: InspectCardTools --atr HEX');
    Writeln('       InspectCardTools --tag HEX');
    Writeln('Hardware-free source-attributed diagnostic hints; no identity or payment assertion.'); Exit;
  end;
  if ParamCount<>2 then raise EConvertError.Create('Use --help for supported arguments.');
  if ParamStr(1)='--atr' then
  begin
    if Length(ParamStr(2))>AtrMaxSize*2 then raise EConvertError.Create('ATR exceeds supported length.');
    Bytes:=HexToBytes(ParamStr(2)); Catalog:=CreateDefaultAtrCatalog;
    try
      Matches:=Catalog.FindMatches(Bytes); Writeln('ATR hints: ',Length(Matches));
      for I:=0 to High(Matches) do Writeln(Matches[I].Id,': ',Matches[I].Description,' [',Matches[I].Source,']');
    finally Catalog.Free; end;
  end
  else if ParamStr(1)='--tag' then
  begin
    if (Length(ParamStr(2))<2) or (Length(ParamStr(2))>8) then raise EConvertError.Create('Tag requires one through four encoded bytes.');
    Bytes:=HexToBytes(ParamStr(2)); Value:=0;
    for I:=0 to High(Bytes) do Value:=(Value shl 8) or Bytes[I];
    if TEmvTagCatalog.TryDescribe(Value,Tag) then
      Writeln(Tag.Name,'; length=',Tag.MinLength,'..',Tag.MaxLength,' sensitive=',Tag.Sensitive,' [',Tag.Source,']')
    else Writeln('Unknown tag; no description assigned.');
  end
  else raise EConvertError.Create('Use --help for supported arguments.');
end;

begin
  try Run; except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
