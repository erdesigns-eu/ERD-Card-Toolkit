unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm4 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Button1: TButton;
    Memo3: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.Button1Click(Sender: TObject);

  function DelText(const S: string; const Index: Integer) : string;
  var
    L : TStringList;
  begin
    L := TStringList.Create;
    L.StrictDelimiter := True;
    L.Delimiter := ',';
    try
      L.DelimitedText := S;
      if L.Count > Index then
        Result := Lowercase(L[Index])
      else
        Result := '';
    finally
      L.Free;
    end;
  end;

var
  I, P1 : Integer;
  S     : string;
begin
  Memo2.Lines.BeginUpdate;
  for I := 0 to Memo1.Lines.Count -1 do
  begin
    if DelText(Memo1.Lines[I], 1) = 'ENROUTE' then
    begin
      Memo2.Lines.Add(Memo1.Lines[I]);
    end;
  end;
  Memo2.Lines.EndUpdate;
end;

{
TBINRec = packed record
  iin_start      : Integer;
  iin_end        : Integer;
  iin_scheme     : TCardScheme;
  iin_type       : TCardType;
  iin_country    : TCountryCode;
  iin_currency   : TCurrencyCode;
  iin_issuer     : string;
  iin_issuer_url : string;
  iin_category   : TBINCategory;
end;
}

procedure TForm4.Button2Click(Sender: TObject);

  function IIN_START(const S: string) : string;
  var
    P : integer;
  begin
    P := Pos('-', S);
    if (P > 0) then
    begin
      Result := Copy(S, 1, P);
    end else
    begin
      Result := S;
    end;
  end;

  function IIN_END(const S: string) : string;
  var
    P : integer;
  begin
    P := Pos('-', S);
    if (P > 0) then
    begin
      Result := Copy(S, P +1, Length(S) - P);
    end else
    begin
      Result := S;
    end;
  end;

  function CARD_TYPE(const S: string) : string;
  begin
    if Pos('credit', Lowercase(S)) > 0 then
    begin
      Result := 'ctCREDIT';
    end else
    if Pos('debit', Lowercase(S)) > 0 then
    begin
      Result := 'ctDEBIT';
    end else
    if Pos('charge', Lowercase(S)) > 0 then
    begin
      Result := 'ctCHARGE';
    end else
    begin
      Result := 'ctUNKNOWN';
    end;
  end;

  function COUNTRY_CODE(const SS: TStringList) : string;
  var
    S : string;
  begin
    if (SS.Count > 6) then S := SS[6] else S := '';
    Result := 'ccUNKNOWN';
    if Pos('usa', Lowercase(S)) > 0 then Result := 'ccUNITEDSTATESOFAMERICA';
    if Pos('pol', Lowercase(S)) > 0 then Result := 'ccPOLAND';
    if Pos('can', Lowercase(S)) > 0 then Result := 'ccCANADA';
    if Pos('kor', Lowercase(S)) > 0 then Result := 'ccKOREAREPUBLIC';
    if Pos('ind', Lowercase(S)) > 0 then Result := 'ccINDIA';
    if Pos('bel', Lowercase(S)) > 0 then Result := 'ccBELGIUM';
    if Pos('col', Lowercase(S)) > 0 then Result := 'ccCOLOMBIA';
    if Pos('pan', Lowercase(S)) > 0 then Result := 'ccPANAMA';
    if Pos('ven', Lowercase(S)) > 0 then Result := 'ccVENEZUELA';
    if Pos('chn', Lowercase(S)) > 0 then Result := 'ccCHINA';
    if Pos('mex', Lowercase(S)) > 0 then Result := 'ccMEXICO';
    if Pos('bhs', Lowercase(S)) > 0 then Result := 'ccBAHAMAS';
    if Pos('pri', Lowercase(S)) > 0 then Result := 'ccPUERTORICO';
    if Pos('vir', Lowercase(S)) > 0 then Result := 'ccVIRGINISLANDSUS';
    if Pos('bmu', Lowercase(S)) > 0 then Result := 'ccBERMUDA';
    if Pos('tto', Lowercase(S)) > 0 then Result := 'ccTRINIDADANDTOBAGO';
    if Pos('isr', Lowercase(S)) > 0 then Result := 'ccISRAEL';
    if Pos('cym', Lowercase(S)) > 0 then Result := 'ccCAYMANISLANDS';
    if Pos('aut', Lowercase(S)) > 0 then Result := 'ccAUSTRIA';
    if Pos('gbr', Lowercase(S)) > 0 then Result := 'ccUNITEDKINGDOM';
    if Pos('phl', Lowercase(S)) > 0 then Result := 'ccPHILIPPINES';
    if Pos('egy', Lowercase(S)) > 0 then Result := 'ccEGYPT';
    if Pos('bhr', Lowercase(S)) > 0 then Result := 'ccBAHRAIN';
    if Pos('lbn', Lowercase(S)) > 0 then Result := 'ccLEBANON';
    if Pos('ita', Lowercase(S)) > 0 then Result := 'ccITALY';
    if Pos('jor', Lowercase(S)) > 0 then Result := 'ccJORDAN';
    if Pos('are', Lowercase(S)) > 0 then Result := 'ccUNITEDARABEMIRATES';
    if Pos('mwi', Lowercase(S)) > 0 then Result := 'ccMALAWI';
    if Pos('mys', Lowercase(S)) > 0 then Result := 'ccMALAYSIA';
    if Pos('fra', Lowercase(S)) > 0 then Result := 'ccFRANCE';
    if Pos('deu', Lowercase(S)) > 0 then Result := 'ccGERMANY';
    if Pos('dnk', Lowercase(S)) > 0 then Result := 'ccDENMARK';
    if Pos('bra', Lowercase(S)) > 0 then Result := 'ccBRAZIL';
    if Pos('fin', Lowercase(S)) > 0 then Result := 'ccFINLAND';
    if Pos('rus', Lowercase(S)) > 0 then Result := 'ccRUSSIANFEDERATION';
    if Pos('nld', Lowercase(S)) > 0 then Result := 'ccNETHERLANDS';
    if Pos('nor', Lowercase(S)) > 0 then Result := 'ccNORWAY';
    if Pos('aus', Lowercase(S)) > 0 then Result := 'ccAUSTRALIA';
    if Pos('cze', Lowercase(S)) > 0 then Result := 'ccCZECHIA';
    if Pos('irl', Lowercase(S)) > 0 then Result := 'ccIRELAND';
    if Pos('idn', Lowercase(S)) > 0 then Result := 'ccINDONESIA';
    if Pos('grc', Lowercase(S)) > 0 then Result := 'ccGREECE';
    if Pos('est', Lowercase(S)) > 0 then Result := 'ccESTONIA';
    if Pos('tur', Lowercase(S)) > 0 then Result := 'ccTURKEY';
    if Pos('prt', Lowercase(S)) > 0 then Result := 'ccPORTUGAL';
    if Pos('esp', Lowercase(S)) > 0 then Result := 'ccSPAIN';
    if Pos('swe', Lowercase(S)) > 0 then Result := 'ccSWEDEN';
    if Pos('che', Lowercase(S)) > 0 then Result := 'ccSWITZERLAND';
    if Pos('hkg', Lowercase(S)) > 0 then Result := 'ccHONGKONG';
    if Pos('jpn', Lowercase(S)) > 0 then Result := 'ccJAPAN';
    if Pos('sgp', Lowercase(S)) > 0 then Result := 'ccSINGAPORE';
    if Pos('pak', Lowercase(S)) > 0 then Result := 'ccPAKISTAN';
    if Pos('tha', Lowercase(S)) > 0 then Result := 'ccTHAILAND';
    if Pos('twn', Lowercase(S)) > 0 then Result := 'ccTAIWAN';
    if Pos('arg', Lowercase(S)) > 0 then Result := 'ccARGENTINA';
    if Pos('sau', Lowercase(S)) > 0 then Result := 'ccSAUDIARABIA';
    if Pos('lka', Lowercase(S)) > 0 then Result := 'ccSRILANKA';
    if Pos('ecu', Lowercase(S)) > 0 then Result := 'ccECUADOR';
    if Pos('nga', Lowercase(S)) > 0 then Result := 'ccNIGERIA';
    if Pos('zaf', Lowercase(S)) > 0 then Result := 'ccSOUTHAFRICA';
    if Pos('nzl', Lowercase(S)) > 0 then Result := 'ccNEWZEALAND';
    if Pos('hrv', Lowercase(S)) > 0 then Result := 'ccCROATIA';
    if Pos('bih', Lowercase(S)) > 0 then Result := 'ccBOSNIA';
    if Pos('srb', Lowercase(S)) > 0 then Result := 'ccSERBIA';
    if Pos('svk', Lowercase(S)) > 0 then Result := 'ccSLOVAKIA';
    if Pos('svn', Lowercase(S)) > 0 then Result := 'ccSLOVENIA';
    if Pos('bgr', Lowercase(S)) > 0 then Result := 'ccBULGARIA';
    if Pos('mdv', Lowercase(S)) > 0 then Result := 'ccMALDIVES';
    if Pos('cri', Lowercase(S)) > 0 then Result := 'ccCOSTARICA';
    if Pos('gtm', Lowercase(S)) > 0 then Result := 'ccGUATEMALA';
    if Pos('slv', Lowercase(S)) > 0 then Result := 'ccELSALVADOR';
    if Pos('hnd', Lowercase(S)) > 0 then Result := 'ccHONDURAS';
    if Pos('per', Lowercase(S)) > 0 then Result := 'ccPERU';
    if Pos('cyp', Lowercase(S)) > 0 then Result := 'ccCYPRUS';
    if Pos('rou', Lowercase(S)) > 0 then Result := 'ccROMANIA';
    if Pos('chl', Lowercase(S)) > 0 then Result := 'ccCHILE';
    if Pos('hun', Lowercase(S)) > 0 then Result := 'ccHUNGARY';
    if Pos('atg', Lowercase(S)) > 0 then Result := 'ccANTIGUAANDBARBUDA';
    if Pos('qat', Lowercase(S)) > 0 then Result := 'ccQATAR';
  end;

  function CURRENCY_CODE(const SS: TStringList) : string;
  var
    S : string;
  begin
    if (SS.Count > 6) then S := SS[6] else S := '';
    Result := 'ccUNK';
    if Pos('usa', Lowercase(S)) > 0 then Result := 'ccUSD';
    if Pos('pol', Lowercase(S)) > 0 then Result := 'ccPLN';
    if Pos('can', Lowercase(S)) > 0 then Result := 'ccCAD';
    if Pos('kor', Lowercase(S)) > 0 then Result := 'ccKRW';
    if Pos('ind', Lowercase(S)) > 0 then Result := 'ccINR';
    if Pos('bel', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('col', Lowercase(S)) > 0 then Result := 'ccCOP';
    if Pos('pan', Lowercase(S)) > 0 then Result := 'ccPAB';
    if Pos('ven', Lowercase(S)) > 0 then Result := 'ccVEF';
    if Pos('chn', Lowercase(S)) > 0 then Result := 'ccCNY';
    if Pos('mex', Lowercase(S)) > 0 then Result := 'ccMXN';
    if Pos('bhs', Lowercase(S)) > 0 then Result := 'ccBSD';
    if Pos('pri', Lowercase(S)) > 0 then Result := 'ccUSD';
    if Pos('vir', Lowercase(S)) > 0 then Result := 'ccUSD';
    if Pos('bmu', Lowercase(S)) > 0 then Result := 'ccBMD';
    if Pos('tto', Lowercase(S)) > 0 then Result := 'ccTTD';
    if Pos('isr', Lowercase(S)) > 0 then Result := 'ccILS';
    if Pos('cym', Lowercase(S)) > 0 then Result := 'ccKYD';
    if Pos('aut', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('gbr', Lowercase(S)) > 0 then Result := 'ccGBP';
    if Pos('phl', Lowercase(S)) > 0 then Result := 'ccPHP';
    if Pos('egy', Lowercase(S)) > 0 then Result := 'ccEGP';
    if Pos('bhr', Lowercase(S)) > 0 then Result := 'ccBHD';
    if Pos('lbn', Lowercase(S)) > 0 then Result := 'ccLBP';
    if Pos('ita', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('jor', Lowercase(S)) > 0 then Result := 'ccJOD';
    if Pos('are', Lowercase(S)) > 0 then Result := 'ccAED';
    if Pos('mwi', Lowercase(S)) > 0 then Result := 'ccMWK';
    if Pos('mys', Lowercase(S)) > 0 then Result := 'ccMYR';
    if Pos('fra', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('deu', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('dnk', Lowercase(S)) > 0 then Result := 'ccDKK';
    if Pos('bra', Lowercase(S)) > 0 then Result := 'ccBRL';
    if Pos('fin', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('rus', Lowercase(S)) > 0 then Result := 'ccRUB';
    if Pos('nld', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('nor', Lowercase(S)) > 0 then Result := 'ccNOK';
    if Pos('aus', Lowercase(S)) > 0 then Result := 'ccAUD';
    if Pos('cze', Lowercase(S)) > 0 then Result := 'ccCZK';
    if Pos('irl', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('idn', Lowercase(S)) > 0 then Result := 'ccIDR';
    if Pos('grc', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('est', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('tur', Lowercase(S)) > 0 then Result := 'ccTRY';
    if Pos('prt', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('esp', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('swe', Lowercase(S)) > 0 then Result := 'ccSEK';
    if Pos('che', Lowercase(S)) > 0 then Result := 'ccCHF';
    if Pos('hkg', Lowercase(S)) > 0 then Result := 'ccHKD';
    if Pos('jpn', Lowercase(S)) > 0 then Result := 'ccJPY';
    if Pos('sgp', Lowercase(S)) > 0 then Result := 'ccSGD';
    if Pos('pak', Lowercase(S)) > 0 then Result := 'ccPKR';
    if Pos('tha', Lowercase(S)) > 0 then Result := 'ccTHB';
    if Pos('twn', Lowercase(S)) > 0 then Result := 'ccTWD';
    if Pos('arg', Lowercase(S)) > 0 then Result := 'ccARS';
    if Pos('sau', Lowercase(S)) > 0 then Result := 'ccSAR';
    if Pos('lka', Lowercase(S)) > 0 then Result := 'ccLKR';
    if Pos('ecu', Lowercase(S)) > 0 then Result := 'ccUSD';
    if Pos('nga', Lowercase(S)) > 0 then Result := 'ccNGN';
    if Pos('zaf', Lowercase(S)) > 0 then Result := 'ccZAR';
    if Pos('nzl', Lowercase(S)) > 0 then Result := 'ccNZD';
    if Pos('hrv', Lowercase(S)) > 0 then Result := 'ccHRK';
    if Pos('bih', Lowercase(S)) > 0 then Result := 'ccBAM';
    if Pos('srb', Lowercase(S)) > 0 then Result := 'ccRSD';
    if Pos('svk', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('svn', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('bgr', Lowercase(S)) > 0 then Result := 'ccBGN';
    if Pos('mdv', Lowercase(S)) > 0 then Result := 'ccMVR';
    if Pos('cri', Lowercase(S)) > 0 then Result := 'ccCRC';
    if Pos('gtm', Lowercase(S)) > 0 then Result := 'ccGTQ';
    if Pos('slv', Lowercase(S)) > 0 then Result := 'ccSVC';
    if Pos('hnd', Lowercase(S)) > 0 then Result := 'ccHNL';
    if Pos('per', Lowercase(S)) > 0 then Result := 'ccPEN';
    if Pos('cyp', Lowercase(S)) > 0 then Result := 'ccEUR';
    if Pos('rou', Lowercase(S)) > 0 then Result := 'ccRON';
    if Pos('chl', Lowercase(S)) > 0 then Result := 'ccCLP';
    if Pos('hun', Lowercase(S)) > 0 then Result := 'ccHUF';
    if Pos('atg', Lowercase(S)) > 0 then Result := 'ccXCD';
    if Pos('qat', Lowercase(S)) > 0 then Result := 'ccQAR';
  end;

  function BANK_URL(const S: TStringList) : string;
  begin
    if (S.Count >= 12) then
      Result := S[11]
    else
      Result := '';
  end;

const
  BIN = '('                                          + #13#10 +
    '  iin_start      : %s;'                         + #13#10 +
    '  iin_end        : %s;'                         + #13#10 +
    '  iin_scheme     : %s;'                         + #13#10 +
    '  iin_type       : %s;'                         + #13#10 +
    '  iin_country    : %s;'                         + #13#10 +
    '  iin_currency   : %s;'                         + #13#10 +
    '  iin_issuer     : ' + '''' + '%s' + '''' + ';' + #13#10 +
    '  iin_issuer_url : ' + '''' + '%s' + '''' + ';' + #13#10 +
    '  iin_category   : ' + '''' + '%s' + '''' + ';' + #13#10 +
    '),';

var
  I : Integer;
  S : TStringList;
begin
  S := TStringList.Create;
  S.Delimiter := ',';
  S.StrictDelimiter := True;
  try
    Memo3.Lines.BeginUpdate;
    for I := 0 to Memo2.Lines.Count -1 do
    begin
      S.Clear;
      S.DelimitedText := Memo2.Lines[I];

      // Add BIN
      Memo3.Lines.Add(Format(BIN, [
        IIN_START(S[0]),
        IIN_END(S[0]),
        'csDINERSCLUBINTERNATIONAL',
        CARD_TYPE(S[2]),
        COUNTRY_CODE(S),
        CURRENCY_CODE(S),
        StringReplace(S[4], '''', '', [rfReplaceAll, rfIgnoreCase]),
        BANK_URL(S),
        StringReplace(S[3], '''', '', [rfReplaceAll, rfIgnoreCase])
      ]));

      // Filter out country codes
      //if (COUNTRY_CODE(S) = '') and (Memo3.Lines.IndexOf(S[6]) < 0) then Memo3.Lines.Add(S[6]);
    end;
    Memo3.Lines.EndUpdate;
  finally
    S.Free;
  end;
end;

end.
