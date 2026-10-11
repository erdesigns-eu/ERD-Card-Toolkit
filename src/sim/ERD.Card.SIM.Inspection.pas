unit ERD.Card.SIM.Inspection;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils, Classes,
{$ELSE}
  System.SysUtils, System.Classes,
{$ENDIF}
  ERD.Card.Bytes, ERD.Card.Workflow, ERD.Card.SIM.Data, ERD.Card.SIM.Reader;

type
  /// <summary>One card inspection section; refusal is explicit rather than synthesized data.</summary>
  TSimInspectionSection = record
    /// <summary>Stable section label.</summary>
    Name: string;
    /// <summary>True only when this section was successfully read.</summary>
    Available: Boolean;
    /// <summary>Exact card refusal status; zero when absent.</summary>
    StatusWord: Word;
    /// <summary>Sanitized unavailable-section exception class, excluding personal data.</summary>
    ErrorClass: string;
    /// <summary>Decoded Unicode content; empty on card refusal.</summary>
    Text: UnicodeString;
  end;
  /// <summary>Ordered independent inspection section results.</summary>
  TSimInspectionSections = array of TSimInspectionSection;
  /// <summary>Explicit SIM/USIM inspection with ICCID, PIN state, IMSI, provider, services and EF.DIR.</summary>
  /// <remarks>No automatic AID selection, network authentication, PIN guessing or writes.
  /// Successful completion means the inspection finished; check each section's Available/StatusWord.
  /// Card status refusals are reported per section; transport/malformed-response errors fail the workflow.</remarks>
  TSimInspectionWorkflow = class(TCardWorkflow)
  private
    FReader: TSimCardReaderWriter;
    FPin: TBytes;
    FSections: TSimInspectionSections;
    FPrepared, FConsumed: Boolean;
    function GetSections: TSimInspectionSections;
    function GetReport: UnicodeString;
  protected
    /// <summary>Validates a fresh explicitly prepared request without I/O.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Reads each declared section once, reporting card refusals individually.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Releases frozen reader settings and wipes independently owned PIN bytes.</summary>
    destructor Destroy; override;
    /// <summary>Copies explicit reader settings and PIN without card I/O.</summary>
    /// <param name="AReader">Idle reader with explicit profile, full USIM AID if applicable and PIN retry policy.</param>
    /// <param name="APin">Optional four through eight ASCII digit bytes, copied and cleared after execution.</param>
    procedure Prepare(const AReader: TSimCardReaderWriter; const APin: TBytes = nil);
    /// <summary>Independent section evidence, including exact card refusal statuses.</summary>
    property Sections: TSimInspectionSections read GetSections;
    /// <summary>Human-readable report containing personal data; store appropriately.</summary>
    property Report: UnicodeString read GetReport;
  end;

implementation

uses ERD.Card.Crypto;

procedure TSimInspectionWorkflow.Prepare(const AReader: TSimCardReaderWriter; const APin: TBytes);
var R: TSimCardReaderWriter; I: Integer; A: TBytes;
begin
  RequireIdle; if (AReader = nil) or AReader.Busy then raise ECardWorkflowError.Create('Configure an idle SIM reader.');
  if Length(APin) > 0 then begin if (Length(APin) < 4) or (Length(APin) > 8) then raise ECardWorkflowError.Create('Invalid ASCII PIN.');
    for I := 0 to High(APin) do if not (APin[I] in [Ord('0') .. Ord('9')]) then raise ECardWorkflowError.Create('Invalid ASCII PIN.'); end;
  A := AReader.ApplicationAid; if (AReader.Profile = scpUiccUsim) and ((Length(A) < 5) or (Length(A) > 16)) then
    raise ECardWorkflowError.Create('Choose the full USIM AID.');
  R := TSimCardReaderWriter.Create(nil);
  try R.Profile := AReader.Profile; R.ApplicationAid := A; R.Transport := AReader.Transport;
    R.PinReference := AReader.PinReference; R.MinimumPinAttempts := AReader.MinimumPinAttempts;
    FReader.Free; FReader := R; R := nil;
    TCardCrypto.Clear(FPin); FPin := CopyBytes(APin); FSections := nil; FPrepared := True; FConsumed := False;
  finally R.Free; end;
end;
procedure TSimInspectionWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed or (FReader = nil) then raise ECardWorkflowError.Create('Prepare a new SIM inspection.'); end;
destructor TSimInspectionWorkflow.Destroy;
begin TCardCrypto.Clear(FPin); FReader.Free; inherited Destroy; end;
function TSimInspectionWorkflow.GetSections: TSimInspectionSections;
begin Result := Copy(FSections, 0, Length(FSections)); end;
function TSimInspectionWorkflow.GetReport: UnicodeString;
var I: Integer;
begin Result := ''; for I := 0 to High(FSections) do begin Result := Result + UnicodeString(FSections[I].Name) + ': ';
  if FSections[I].Available then Result := Result + FSections[I].Text
  else if FSections[I].ErrorClass = 'NotApplicable' then Result := Result + 'Not applicable to classic SIM'
  else Result := Result + UnicodeString('Unavailable, SW=' + IntToHex(FSections[I].StatusWord, 4));
  Result := Result + #13#10; end;
end;
procedure TSimInspectionWorkflow.DoExecute;
var I, J: Integer; Pin: TSimPinStatus; Services: TSimServices; Apps: TSimApplications; Spn: TSimServiceProvider; Identity: UnicodeString;
begin
  FConsumed := True;
  try
    if not RequestCard(cwrSource) then begin Cancel; Exit; end;
    Progress(cwsReading, 0, 6); if CancelRequested then Exit;
    Identity := FReader.ReadIccid;
    if Length(FPin) > 0 then begin Pin := FReader.GetPinStatus;
      if not Pin.Disabled and not (Pin.VerificationKnown and Pin.Verified) then FReader.VerifyPin(FPin); end;
    TCardCrypto.Clear(FPin); SetLength(FSections, 6);
    for I := 0 to 5 do
    begin
      if CancelRequested then Exit;
      case I of 0: FSections[I].Name := 'ICCID'; 1: FSections[I].Name := 'PIN state';
        2: FSections[I].Name := 'IMSI'; 3: FSections[I].Name := 'Provider';
        4: FSections[I].Name := 'Services'; 5: FSections[I].Name := 'Applications'; end;
      if (I = 5) and (FReader.Profile = scpGsmSim) then begin FSections[I].ErrorClass := 'NotApplicable'; Continue; end;
      try
        case I of
          0: FSections[I].Text := Identity;
          1: begin Pin := FReader.GetPinStatus; FSections[I].Text := UnicodeString('Retries ' + IntToStr(Pin.RemainingAttempts) +
            ', verified known ' + BoolToStr(Pin.VerificationKnown, True) + ', verified ' + BoolToStr(Pin.Verified, True)); end;
          2: FSections[I].Text := FReader.ReadImsi;
          3: begin Spn := FReader.ReadSpn; FSections[I].Text := Spn.Name; end;
          4: begin Services := FReader.ReadServices; for J := 0 to High(Services) do begin
            FSections[I].Text := FSections[I].Text + UnicodeString(IntToStr(Services[J].Number) +
              ': available=' + BoolToStr(Services[J].Available, True));
            if FReader.Profile = scpGsmSim then FSections[I].Text := FSections[I].Text +
              UnicodeString(', legacy active=' + BoolToStr(Services[J].Active, True));
            FSections[I].Text := FSections[I].Text + ' '; end; end;
          5: begin Apps := FReader.ReadApplications; for J := 0 to High(Apps) do
            FSections[I].Text := FSections[I].Text + UnicodeString(BytesToHex(Apps[J].Aid)) + ' ' + Apps[J].LabelText + #13#10; end;
        end;
        FSections[I].Available := True;
      except on E: ESimCardStatusError do begin FSections[I].StatusWord := E.StatusWord;
        FSections[I].ErrorClass := E.ClassName; FSections[I].Text := ''; end; end;
      Progress(cwsReading, I + 1, 6);
    end;
    if Identity <> FReader.ReadIccid then raise ECardWorkflowError.Create('SIM card identity changed.');
  finally TCardCrypto.Clear(FPin); end;
end;

end.
