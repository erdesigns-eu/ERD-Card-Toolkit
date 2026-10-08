program ReadIcaoDocument;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}
  SysUtils,Classes,
{$ELSE}
  System.SysUtils,System.Classes,
{$ENDIF}
  ERD.Card.Bytes,ERD.Card.Crypto,ERD.Card.Crypto.EAC,ERD.Card.Crypto.EAC.OpenSSL,
  ERD.Card.PCSC.Api,ERD.Card.PCSC.Reader,ERD.Card.EID.Access,
  ERD.Card.EID.ICAO,ERD.Card.EID.DocumentReader;
procedure Run;
var Card:TSmartCardReader;Reader:TICAODocumentReader;Data:TIcaoDocumentData;
  Infos:TIcaoPaceInfos;Password:TBytes;Stream:TFileStream;I:Integer;Suffix,Path:string;
begin
  if (ParamCount=0) or ((ParamCount=1) and (ParamStr(1)='--help')) then
  begin
    Writeln('Usage: ReadIcaoDocument --cardaccess HEX');
    Writeln('       ReadIcaoDocument --read EXACT_READER bac|pace mrz|can PASSWORD_FILE brainpool|nist CRYPTO_LIBRARY IMAGE_PREFIX');
    Writeln('PASSWORD_FILE: exact raw ASCII MRZ access information or six-digit CAN, without newline.');
    Writeln('Use TIcaoAccessCodec.MrzInformation to derive access information from a full validated MRZ.');
    Writeln('CRYPTO_LIBRARY: explicit OpenSSL 3 library path, or - for the platform default.');
    Writeln('IMAGE_PREFIX: - to skip saving, otherwise filename prefix; .0.jpg/.0.jp2 etc are added.');
    Writeln('Exclusive Windows PC/SC. BAC/PACE is document access, not SOD signature or issuer-trust verification.');
    Exit;
  end;
  if (ParamCount=2) and (ParamStr(1)='--cardaccess') then
  begin
    Infos:=TIcaoCardAccessCodec.Decode(HexToBytes(ParamStr(2)));
    Writeln('PACE infos: ',Length(Infos));
    for I:=0 to High(Infos) do Writeln('Version: ',Infos[I].Version,' parameter: ',Infos[I].ParameterId,' supported: ',Infos[I].Supported);
    Exit;
  end;
  if (ParamCount<>8) or (ParamStr(1)<>'--read') or
    not ((ParamStr(3)='bac') or (ParamStr(3)='pace')) or
    not ((ParamStr(4)='mrz') or (ParamStr(4)='can')) or
    not ((ParamStr(6)='brainpool') or (ParamStr(6)='nist')) or
    ((ParamStr(3)='bac') and (ParamStr(4)<>'mrz')) then
    raise EIcaoAccessError.Create('Use --help for explicit document-access arguments.');
  Reader:=TICAODocumentReader.Create(nil);Card:=nil;Password:=nil;
  try
    if ParamStr(3)='bac' then Reader.Security:=iasBac;
    if ParamStr(4)='can' then Reader.PasswordKind:=ipkCan;
    if ParamStr(6)='nist' then Reader.PaceCurve:=ppcNistP256;
    Stream:=TFileStream.Create(ParamStr(5),fmOpenRead or fmShareDenyWrite);
    try
      if (Stream.Size<1) or (Stream.Size>64) then raise EIcaoAccessError.Create('Invalid password-file size.');
      SetLength(Password,Stream.Size);Stream.ReadBuffer(Password[0],Length(Password));
    finally Stream.Free;end;
    TIcaoAccessCodec.ValidatePassword(Password,Reader.PasswordKind);Reader.AccessPassword:=Password;
    Path:=ParamStr(7);if Path='-' then Path:='';Reader.CryptoProvider:=TCardEacOpenSslProvider.Create(Path);
    Card:=TSmartCardReader.Create(nil);Card.ReaderName:=UnicodeString(ParamStr(2));Card.ShareMode:=psmExclusive;Card.Connect;
    Reader.Transport:=Card.Transport;Data:=Reader.ReadDocument;Card.Disconnect;
    Writeln('Name: ',Data.Identity.GivenNames,' ',Data.Identity.Surname);
    Writeln('Encoded images: ',Length(Data.Biometrics.Images));
    for I:=0 to High(Data.Biometrics.Images) do
    begin
      Writeln('Image ',I,' bytes: ',Length(Data.Biometrics.Images[I].Data));
      if ParamStr(8)<>'-' then
      begin
        if Data.Biometrics.Images[I].Format=iffJpeg then Suffix:='.jpg' else Suffix:='.jp2';
        Stream:=TFileStream.Create(ParamStr(8)+'.'+IntToStr(I)+Suffix,fmCreate);
        try Stream.WriteBuffer(Data.Biometrics.Images[I].Data[0],Length(Data.Biometrics.Images[I].Data));finally Stream.Free;end;
      end;
    end;
  finally TCardCrypto.Clear(Password);Reader.Free;Card.Free;end;
end;
begin
  try Run;except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
