program CardCatalogsTests;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$R+}
{$Q+}

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.ATR, ERD.Card.ATR.Catalog, ERD.Card.EMV.Tags;

var Assertions:Integer;
procedure Check(const B:Boolean; const Msg:string);
begin Inc(Assertions); if not B then raise Exception.Create(Msg); end;

procedure AtrTests;
var C:TAtrCatalog; Matches:TAtrCatalogMatches; E:TAtrCatalogEntries;
  B,Original:TBytes; I,J:Integer; Failed:Boolean;
begin
  C:=CreateDefaultAtrCatalog(False);
  try
    B:=HexToBytes('3B8F8001804F0CA0000003060B00350000000056');
    Matches:=C.FindMatches(B);
    Check((Length(Matches)=2) and (Matches[0].Id='acs-icode-slix') and
      (Matches[1].Kind=ahkFamily),'ACS SLIX/SLIX2 reported model plus protocol-family hint');
    Check((Pos('SLIX/SLIX2',Matches[0].Description)>0) and (Pos('1.09',Matches[0].Source)>0),'Shared fingerprint and provenance explicit');
    Matches[0].Description:='changed'; Matches:=C.FindMatches(B);
    Check(Matches[0].Description<>'changed','Lookup results do not mutate catalog');
    Matches:=C.FindMatches(HexToBytes('3B00')); Check(Length(Matches)=0,'Unknown valid ATR remains unknown');
    Original:=CopyBytes(B);
    for I:=0 to 255 do if I<>Original[19] then
    begin
      B:=CopyBytes(Original); B[19]:=I; Failed:=False;
      try Matches:=C.FindMatches(B); except on EAtrFormatError do Failed:=True; end;
      Check(Failed,'Every corrupt TCK rejected before masked matching');
    end;
    // Unknown card-name values still yield only a family hint, with valid recalculated TCK.
    B:=CopyBytes(Original); B[13]:=$7F; B[14]:=$11; B[19]:=0;
    for J:=1 to 18 do B[19]:=B[19] xor B[J];
    Matches:=C.FindMatches(B); Check((Length(Matches)=1) and (Matches[0].Kind=ahkFamily),'Masked family without invented chip identity');
    Matches:=C.FindMatches(HexToBytes('3B8F8001804F0CA000000306030001000000006A'));
    Check((Length(Matches)=1) and (Pos('emulation',Matches[0].Description)>0),'Classic fingerprint does not falsely distinguish emulation');
  finally C.Free; end;
  SetLength(E,2);
  for I:=0 to 1 do
  begin
    E[I].Id:='hint-'+IntToStr(I); E[I].Description:='Advisory custom hint'; E[I].Source:='Synthetic test fixture';
    E[I].Pattern:=HexToBytes('3B00'); E[I].Mask:=HexToBytes('FFFF');
  end;
  C:=TAtrCatalog.Create(E);
  try
    E[0].Pattern[0]:=0; E[1].Mask[0]:=0;
    Matches:=C.FindMatches(HexToBytes('3B00')); Check(Length(Matches)=2,'Custom source buffers copied and every overlapping match retained');
  finally C.Free; end;
  for I:=0 to 6 do
  begin
    E[0].Pattern:=HexToBytes('3B00'); E[0].Mask:=HexToBytes('FFFF');
    E[0].Id:='hint-0'; E[0].Source:='Fixture'; E[0].Description:='Hint';
    E[1]:=E[0]; E[1].Id:='hint-1';
    case I of
      0:E[0].Mask:=HexToBytes('0000'); 1:E[0].Mask:=HexToBytes('FF');
      2:E[0].Pattern:=HexToBytes('3B'); 3:E[0].Source:='';
      4:E[0].Id:=''; 5:E[1].Id:=E[0].Id; 6:E[0].Mask:=HexToBytes('0FFF');
    end;
    Failed:=False;
    try C:=TAtrCatalog.Create(E); C.Free; except on EAtrCatalogError do Failed:=True; end;
    Check(Failed,'Invalid masks, metadata and duplicate identifiers refused: '+IntToStr(I));
  end;
  Writeln('PASS: ATR exact/masked hints, ambiguous identities, unknown inputs, ownership and invalid definitions.');
end;

procedure EmvTests;
var D:TEmvTagDescription; I,N:Integer; Known:Boolean;
begin
  Check(TEmvTagCatalog.TryDescribe($9F26,D) and (D.Name='Application Cryptogram') and
    (D.MinLength=8) and (D.MaxLength=8) and D.Sensitive,'EMV Annex A cryptogram metadata');
  Check(TEmvTagCatalog.TryDescribe($9F38,D) and (D.Encoding=eteDol),'PDOL is not a TLV value stream');
  Check(TEmvTagCatalog.TryDescribe($57,D) and (D.Encoding=eteTrack2) and
    (D.MaxLength=19) and D.Sensitive,'Track 2 equivalent distinct from physical framing');
  Check(TEmvTagCatalog.TryDescribe($5F20,D) and (D.MinLength=2) and (D.MaxLength=26),'Cardholder-name Book 3 bounds');
  Check(TEmvTagCatalog.TryDescribe($9F4D,D) and (D.MaxLength=2),'Log-entry descriptor metadata');
  N:=0;
  for I:=0 to 65535 do
  begin
    Known:=TEmvTagCatalog.TryDescribe(I,D);
    if Known then
    begin
      Inc(N); Check((D.Tag=Cardinal(I)) and (D.Name<>'') and (D.Source<>'') and
        (D.MinLength>=0) and ((D.MaxLength=-1) or (D.MaxLength>=D.MinLength)),'Every known tag has consistent source-attributed metadata');
    end
    else Check((D.Tag=0) and (D.Name='') and (D.Source=''),'Every unknown tag clears result without inventing identity');
  end;
  Check(N=46,'Curated catalog count');
  Check(not TEmvTagCatalog.TryDescribe($DF0101,D),'Private tag namespace remains unknown');
  Writeln('PASS: Curated EMV tag descriptions, representation/length metadata and unknown-tag behavior.');
end;

begin
  try AtrTests; EmvTests; Writeln('PASS: 2 card-catalog groups; ',Assertions,' assertions.');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
