program RegistrationTests;

{$MODE DELPHI}

uses SysUtils, Classes, DesignIntf, ERD.Card.Design.Register;

var C: TComponentClass; Original, Loaded: TComponent;
  Stream: TMemoryStream; Checks: Integer;
begin
  try
    ERD.Card.Design.Register.Register;
    if Length(CapturedComponents) <> 26 then raise Exception.Create('Expected twenty-six palette components.');
    Checks := 1;
    for C in CapturedComponents do
    begin
      Original := C.Create(nil);
      try
        Original.Name := 'InactiveCardComponent';
        Stream := TMemoryStream.Create;
        try
          Stream.WriteComponent(Original); Stream.Position := 0;
          Loaded := Stream.ReadComponent(nil);
          try
            if (Loaded.ClassType <> C) or (Loaded.Name <> Original.Name) then
              raise Exception.Create('Component streaming differs.');
            Inc(Checks);
          finally Loaded.Free; end;
        finally Stream.Free; end;
      finally Original.Free; end;
      UnRegisterClass(C);
    end;
    Writeln('PASS: ', Checks, ' inactive registration/RTL streaming assertions (no IDE).');
  except on E: Exception do begin Writeln(E.ClassName, ': ', E.Message); ExitCode := 1; end; end;
end.
