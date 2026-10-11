program MobibAnalysisTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data,
  ERD.Card.MOBIB.Archive;
var Checks: Integer;
procedure Check(const Value: Boolean; const Message: string);
begin Inc(Checks); if not Value then raise Exception.Create(Message); end;
procedure RejectArchive(const Text: UnicodeString);
var Failed: Boolean;
begin
  Failed := False;
  try TMobibArchive.Decode(Text); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Malformed archive accepted');
end;
procedure TestArchive;
var S, D: TMobibSnapshot; Text: UnicodeString; I, J: Integer; Failed: Boolean;
begin
  S := Default(TMobibSnapshot); S.TicketingSelection := HexToBytes('6F020102'); SetLength(S.Files,3);
  for I := 0 to 2 do begin
    S.Files[I].LogicalId := $2001+I; S.Files[I].SelectionStatus := $9000;
    S.Files[I].LastRecordStatus := $6A83; S.Files[I].Truncated := I=2;
    S.Files[I].SelectionData := HexToBytes('85020102');
  end;
  S.Files[1].SelectionStatus := $6982; S.Files[1].LastRecordStatus := 0;
  SetLength(S.Files[0].Records,3);
  for I := 0 to 2 do begin S.Files[0].Records[I].Number := I+2; S.Files[0].Records[I].Data := HexToBytes('000001'); end;
  Text := TMobibArchive.Encode(S); D := TMobibArchive.Decode(Text);
  RejectArchive(Text+#0+'ignored'); RejectArchive(Text+#9);
  Check(Text = TMobibArchive.Encode(D),'Non-lossless archive round trip');
  Check(BytesEqual(D.TicketingSelection,S.TicketingSelection),'Ticketing bytes lost');
  for I := 0 to 2 do begin
    Check(D.Files[I].LogicalId = S.Files[I].LogicalId,'File identifier changed');
    Check(D.Files[I].SelectionStatus = S.Files[I].SelectionStatus,'SELECT status changed');
    Check(D.Files[I].LastRecordStatus = S.Files[I].LastRecordStatus,'READ status changed');
    Check(D.Files[I].Truncated = S.Files[I].Truncated,'Truncation evidence lost');
    Check(BytesEqual(D.Files[I].SelectionData,S.Files[I].SelectionData),'SELECT data changed');
    for J := 0 to High(S.Files[I].Records) do begin
      Check(D.Files[I].Records[J].Number = S.Files[I].Records[J].Number,'Record number changed');
      Check(BytesEqual(D.Files[I].Records[J].Data,S.Files[I].Records[J].Data),'Record bytes changed');
    end;
  end;
  D.Files[0].Records[0].Data[0] := 255; Check(S.Files[0].Records[0].Data[0] = 0,'Archive output aliases input');
  RejectArchive(''); RejectArchive('MOBIB-RECORDS 2'+sLineBreak+'T -');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'R 2001 1 AA');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T 0');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T GG');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 0000 9000 0000 0 -');
  RejectArchive('MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 2001 9000 0000 2 -');
  RejectArchive(Text+sLineBreak+'F 2001 9000 0000 0 -');
  Text := 'MOBIB-RECORDS 1'+sLineBreak+'T -'+sLineBreak+'F 2001 9000 6A83 0 -'+sLineBreak;
  RejectArchive(Text+'R 2002 1 AA'); RejectArchive(Text+'R 2001 0 AA'); RejectArchive(Text+'R 2001 256 AA');
  RejectArchive(Text+'R 2001 $1 AA'); RejectArchive(Text+'R 2001 1 '+UnicodeString(StringOfChar('A',514)));
  RejectArchive(Text+'R 2001 1 AA'+sLineBreak+'R 2001 1 BB');
  D := TMobibArchive.Decode(Text+'R 2001 1 -'); Check(Length(D.Files[0].Records[0].Data) = 0,'Empty bytes not retained');
  SetLength(S.Files[0].Records[0].Data,257); Failed := False;
  try Text := TMobibArchive.Encode(S); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Oversized record exported');
end;
procedure TestMetadata;
const Fci = '6F228408315449432E494341A516BF0C13C708000000001234567853070A3C2B05141001';
  FileSelection = '6F19851707040230011F101F100103010300200100000000002001';
var S, D: TMobibSnapshot; I: Integer; Text: UnicodeString; Failed: Boolean;
begin
  S := Default(TMobibSnapshot); S.Application := TCalypsoFci.DecodeApplication(HexToBytes(Fci));
  S.Application.StatusWord := $9000; SetLength(S.Files,4);
  for I := 0 to 1 do begin
    S.Files[I].LogicalId := $2001; if I = 1 then S.Files[I].Folder := $3F00;
    S.Files[I].SelectionStatus := $9000; S.Files[I].SelectionData := HexToBytes(FileSelection);
    S.Files[I].Info := TCalypsoFci.DecodeFileInfo(S.Files[I].SelectionData,I = 1);
    S.Files[I].Sfi := S.Files[I].Info.Sfi;
  end;
  for I := 2 to 3 do begin
    S.Files[I].BySfi := True; S.Files[I].Sfi := I-1; S.Files[I].Folder := $2000;
    S.Files[I].SelectionStatus := $9000; SetLength(S.Files[I].Records,1);
    S.Files[I].Records[0].Number := 1; S.Files[I].Records[0].Data := HexToBytes('010203');
  end;
  Text := TMobibArchive.Encode(S); D := TMobibArchive.Decode(Text);
  Check(Text = TMobibArchive.Encode(D),'Addressed snapshot failed canonical round trip');
  Check(D.Application.Valid and (D.Application.StatusWord = $9000),'Application outcome lost');
  Check(BytesEqual(D.Application.SerialNumber,S.Application.SerialNumber),'Application serial lost');
  Check(BytesEqual(D.Application.StartupInfo,S.Application.StartupInfo),'Startup information lost');
  Check(BytesEqual(D.Application.DfName,S.Application.DfName),'Application DF name lost');
  for I := 0 to 3 do begin
    Check(D.Files[I].Folder = S.Files[I].Folder,'Folder address lost');
    Check(D.Files[I].BySfi = S.Files[I].BySfi,'SFI addressing mode lost');
    Check(D.Files[I].Sfi = S.Files[I].Sfi,'Short file identifier lost');
  end;
  for I := 0 to 1 do begin
    Check(D.Files[I].Info.Present,'File header lost');
    Check(D.Files[I].Info.LogicalId = S.Files[I].Info.LogicalId,'Revision-specific header LID lost');
    Check(D.Files[I].Info.RecordSize = S.Files[I].Info.RecordSize,'Card record size lost');
    Check(BytesEqual(D.Files[I].Info.Raw,S.Files[I].Info.Raw),'Raw file header lost');
  end;
  S.Files[1].Folder := $2000; Failed := False;
  try TMobibArchive.Encode(S); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Equivalent ticketing folder aliases accepted twice');
  S.Files[1].Folder := $3F00; S.Files[3].Sfi := S.Files[2].Sfi; Failed := False;
  try TMobibArchive.Encode(S); except on E: EMobibArchiveError do Failed := True; end;
  Check(Failed,'Duplicate SFI address accepted');
end;
begin
  try TestArchive; TestMetadata; Writeln('PASS: ',Checks,' MOBIB archive integrity assertions.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); Halt(1); end; end;
end.
