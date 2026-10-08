unit ERD.Card.SIM.Data;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}

type
  /// <summary>Malformed SIM data or unsupported explicitly selected file/profile geometry.</summary>
  ESimCardError = class(Exception);
  /// <summary>Explicit command dialect; no automatic GSM-to-UICC probing or fallback.</summary>
  TSimCardProfile = (
    /// <summary>Classic GSM SIM using TS 51.011 A0-class commands and legacy file headers.</summary>
    scpGsmSim,
    /// <summary>UICC with an explicitly selected USIM application and TS 102 221 FCP metadata.</summary>
    scpUiccUsim
  );
  /// <summary>Starting directory for a caller-specified file path.</summary>
  TSimFileRoot = (
    /// <summary>Master file 3F00; for ICCID, EF.DIR and classic SIM directories.</summary>
    sfrMasterFile,
    /// <summary>Explicit complete USIM AID; available only in the UICC profile.</summary>
    sfrUsimApplication
  );
  /// <summary>Owned numeric directory/file identifiers after the selected root.</summary>
  TSimFilePath = array of Word;
  /// <summary>Explicit root and bounded directory/EF path; assignment shares Path.</summary>
  TSimFileAddress = record
    /// <summary>Master file or explicitly configured USIM application.</summary>
    Root: TSimFileRoot;
    /// <summary>One through eight identifiers; no embedded MF, zero or FFFF selector.</summary>
    Path: TSimFilePath;
  end;
  /// <summary>Decoded file structure; cyclic records are read-only in the initial component profile.</summary>
  TSimFileStructure = (
    /// <summary>Directory rather than an elementary file.</summary>
    sfsDirectory,
    /// <summary>Transparent byte file.</summary>
    sfsTransparent,
    /// <summary>Fixed-size absolute records.</summary>
    sfsLinearFixed,
    /// <summary>Cyclic fixed records; no implicit append or pointer-changing writes.</summary>
    sfsCyclic
  );
  /// <summary>Strict selected-file geometry; metadata is not a grant of access rights.</summary>
  TSimFileInfo = record
    /// <summary>Returned FID; zero only for an ADF without an FID.</summary>
    FileId: Word;
    /// <summary>Directory, transparent, linear-fixed or cyclic structure.</summary>
    Structure: TSimFileStructure;
    /// <summary>Declared EF bytes; zero for directories.</summary>
    Size: Integer;
    /// <summary>Fixed record bytes, one through 255; zero for transparent/directory files.</summary>
    RecordBytes: Integer;
    /// <summary>Absolute record count, one through 255; zero for transparent/directory files.</summary>
    RecordCount: Integer;
    /// <summary>Owned exact legacy header or UICC FCP bytes, including unparsed access attributes.</summary>
    Raw: TBytes;
    /// <summary>Returned ADF name when present; independently owned.</summary>
    ApplicationAid: TBytes;
  end;
  /// <summary>Owned independent record buffers; assignment shares the outer and inner arrays.</summary>
  TSimRecords = array of TBytes;
  /// <summary>PIN status without retaining a PIN; unknown retry counts are never guessed.</summary>
  TSimPinStatus = record
    /// <summary>Known retry budget, zero through fifteen; minus one means unknown.</summary>
    RemainingAttempts: Integer;
    /// <summary>Whether the reported retry budget proves the code is blocked.</summary>
    Blocked: Boolean;
    /// <summary>Legacy CHV1 disabled flag; UICC already-verified state may also mean no check is needed.</summary>
    Disabled: Boolean;
    /// <summary>Whether the card explicitly reported a verified current state.</summary>
    Verified: Boolean;
    /// <summary>Whether Verified is known; classic directory headers do not expose session verification.</summary>
    VerificationKnown: Boolean;
    /// <summary>Whether a classic code is initialized; true for a recognized UICC PIN-status response.</summary>
    Initialized: Boolean;
  end;
  /// <summary>One service-table bit pair or USIM availability bit; no network provisioning is implied.</summary>
  TSimServiceInfo = record
    /// <summary>One-based service number from the selected SIM/USIM specification.</summary>
    Number: Integer;
    /// <summary>Declared available service bit.</summary>
    Available: Boolean;
    /// <summary>Legacy activation bit; for USIM equals Available and does not describe EF.EST.</summary>
    Active: Boolean;
  end;
  /// <summary>Owned service-table states in specification numbering order.</summary>
  TSimServices = array of TSimServiceInfo;
  /// <summary>One explicit USIM phonebook file reference from a PBR template; links are not followed automatically.</summary>
  TSimPhonebookReference = record
    /// <summary>Physical template index within this PBR record, zero based.</summary>
    TemplateIndex: Integer;
    /// <summary>Template tag A8 (same-index), A9 (IAP-linked) or AA (independent).</summary>
    TemplateTag: Byte;
    /// <summary>Zero-based position among this template's references, needed for type-2 IAP interpretation.</summary>
    ReferenceIndex: Integer;
    /// <summary>File-role tag C0 through CB; unknown roles are refused.</summary>
    RoleTag: Byte;
    /// <summary>Explicit two-byte elementary file identifier, interpreted within the actual phonebook DF.</summary>
    FileId: Word;
    /// <summary>Optional short file identifier 1 through 30; minus one means absent.</summary>
    ShortFileId: Integer;
  end;
  /// <summary>Owned PBR file references in physical template/reference order.</summary>
  TSimPhonebookReferences = array of TSimPhonebookReference;
  /// <summary>Decoded service-provider name, with original display-condition flags.</summary>
  TSimServiceProvider = record
    /// <summary>Uninterpreted profile-specific display condition.</summary>
    DisplayCondition: Byte;
    /// <summary>Decoded GSM/UCS-2 alpha identifier.</summary>
    Name: UnicodeString;
  end;
  /// <summary>ADN-style contact, including unresolved extension/capability references.</summary>
  TSimPhonebookEntry = record
    /// <summary>One-based physical record number when supplied by a reader.</summary>
    RecordNumber: Integer;
    /// <summary>True only when the complete record is erased FF.</summary>
    Empty: Boolean;
    /// <summary>GSM/UCS-2 alpha identifier, without FF padding.</summary>
    Name: UnicodeString;
    /// <summary>Inline dial string; international TON gets a leading plus; extension digits are not invented.</summary>
    Number: UnicodeString;
    /// <summary>Raw type-of-number/numbering-plan byte.</summary>
    TonNpi: Byte;
    /// <summary>Capability/configuration EF reference; FF means absent.</summary>
    CapabilityRecord: Byte;
    /// <summary>Extension EF record reference; FF means absent.</summary>
    ExtensionRecord: Byte;
    /// <summary>Owned exact original record, including unresolved fields.</summary>
    Raw: TBytes;
  end;
  /// <summary>Owned decoded contact array; record Raw arrays remain independently allocated.</summary>
  TSimPhonebookEntries = array of TSimPhonebookEntry;
  /// <summary>Stored SMS state; body remains an exact PDU-containing field, not decoded message text.</summary>
  TSimSmsState = (
    /// <summary>Unallocated record; remaining bytes may contain stale data.</summary>
    sssFree,
    /// <summary>Received message already read.</summary>
    sssReceivedRead,
    /// <summary>Received message waiting to be read.</summary>
    sssReceivedUnread,
    /// <summary>Outgoing message waiting to be sent.</summary>
    sssUnsent,
    /// <summary>Sent message with one of the defined status-report states.</summary>
    sssSent,
    /// <summary>Reserved or unknown status; no direction/state is guessed.</summary>
    sssUnknown
  );
  /// <summary>Exact 176-byte EF.SMS record with state metadata.</summary>
  TSimSmsRecord = record
    /// <summary>Uninterpreted original status byte.</summary>
    StatusByte: Byte;
    /// <summary>Recognized allocation/message state.</summary>
    State: TSimSmsState;
    /// <summary>Owned 175-byte SMSC/TPDU/padding field; terminal FF bytes are not trimmed.</summary>
    Body: TBytes;
  end;
  /// <summary>One EF.DIR application entry; enumeration does not select it.</summary>
  TSimApplicationInfo = record
    /// <summary>Owned complete application identifier, five through sixteen bytes.</summary>
    Aid: TBytes;
    /// <summary>Decoded GSM/UCS-2 label when present.</summary>
    LabelText: UnicodeString;
    /// <summary>Owned exact alpha-label bytes.</summary>
    LabelBytes: TBytes;
  end;
  /// <summary>Owned EF.DIR application entries.</summary>
  TSimApplications = array of TSimApplicationInfo;
  /// <summary>Pure bounded SIM/USIM metadata, BCD, alpha, ADN, SMS and directory codecs.</summary>
  TSimCodec = class
  public
    /// <summary>Creates a validated independent explicit file address.</summary>
    /// <param name="ARoot">Master file or configured USIM ADF.</param>
    /// <param name="APath">One through eight directory/EF identifiers.</param>
    /// <returns>Owned validated address.</returns>
    class function FileAddress(const ARoot: TSimFileRoot; const APath: array of Word): TSimFileAddress; static;
    /// <summary>Decodes complete legacy SELECT metadata or one exact UICC FCP.</summary>
    /// <param name="AProfile">Explicit command/metadata dialect.</param>
    /// <param name="AData">Exact SELECT/GET RESPONSE data, without status words.</param>
    /// <returns>Owned strict file geometry; no access-right inference.</returns>
    class function DecodeFileInfo(const AProfile: TSimCardProfile; const AData: TBytes): TSimFileInfo; static;
    /// <summary>Decodes ten EF.ICCID bytes in low-nibble-first decimal order.</summary>
    /// <param name="AData">Exactly ten BCD bytes; optional final F filler only.</param>
    /// <returns>Nineteen or twenty decimal digits; no Luhn/operator inference.</returns>
    class function DecodeIccid(const AData: TBytes): UnicodeString; static;
    /// <summary>Encodes an explicit ICCID for offline use; grants no issuer write rights.</summary>
    /// <param name="ADigits">Nineteen or twenty decimal digits.</param>
    /// <returns>Ten independently allocated BCD bytes.</returns>
    class function EncodeIccid(const ADigits: UnicodeString): TBytes; static;
    /// <summary>Decodes length/parity-checked nine-byte EF.IMSI.</summary>
    /// <param name="AData">Exact EF.IMSI bytes with unused bytes padded FF.</param>
    /// <returns>Five through fifteen decimal digits.</returns>
    class function DecodeImsi(const AData: TBytes): UnicodeString; static;
    /// <summary>Encodes an explicit IMSI for offline use; does not personalize a network subscription.</summary>
    /// <param name="ADigits">Five through fifteen decimal digits.</param>
    /// <returns>Nine independently allocated length/parity/BCD bytes.</returns>
    class function EncodeImsi(const ADigits: UnicodeString): TBytes; static;
    /// <summary>Decodes unpacked GSM default/extension alphabet or SIM UCS-2 80/81/82 coding.</summary>
    /// <param name="AData">Bounded alpha field, at most 255 bytes, with explicit FF padding.</param>
    /// <returns>Unicode text; malformed padding, escape, UCS-2 and compressed lengths are refused.</returns>
    class function DecodeAlpha(const AData: TBytes): UnicodeString; static;
    /// <summary>Encodes GSM text when representable, otherwise UCS-2 80, without truncation.</summary>
    /// <param name="AText">Unicode text; supplementary characters cannot be represented by UCS-2.</param>
    /// <param name="AFieldBytes">Exact alpha-field capacity, zero through 255.</param>
    /// <returns>Fixed-size independently allocated FF-padded field.</returns>
    class function EncodeAlpha(const AText: UnicodeString; const AFieldBytes: Integer): TBytes; static;
    /// <summary>Decodes classic SST availability/activation pairs or USIM UST availability bits.</summary>
    /// <param name="AProfile">Explicit SIM/USIM service-table format.</param>
    /// <param name="AData">One through 255 service-table bytes.</param>
    /// <returns>Numbered bit states; unknown service names and EF.EST activation are not inferred.</returns>
    class function DecodeServices(const AProfile: TSimCardProfile; const AData: TBytes): TSimServices; static;
    /// <summary>Decodes a complete USIM PBR record into explicit file roles and link kinds.</summary>
    /// <param name="AData">One through 255 bytes containing A8/A9/AA templates and trailing FF padding.</param>
    /// <returns>Owned ordered references; malformed geometry and roles are refused; repeated file roles retain their actual positions.</returns>
    class function DecodePhonebookReferences(const AData: TBytes): TSimPhonebookReferences; static;
    /// <summary>Decodes the exact seventeen-byte service-provider-name file.</summary>
    /// <param name="AData">Display condition followed by sixteen alpha bytes.</param>
    /// <returns>Display flags and decoded name.</returns>
    class function DecodeSpn(const AData: TBytes): TSimServiceProvider; static;
    /// <summary>Encodes a fixed seventeen-byte service-provider-name value for offline use.</summary>
    /// <param name="AName">Name fitting sixteen alpha bytes.</param>
    /// <param name="ADisplayCondition">Explicit display flags zero through three.</param>
    /// <returns>Owned flags/alpha bytes.</returns>
    class function EncodeSpn(const AName: UnicodeString; const ADisplayCondition: Byte): TBytes; static;
    /// <summary>Decodes one ADN/MSISDN-style fixed record without following linked EFs.</summary>
    /// <param name="AData">Fourteen through 255 bytes with the standard fourteen-byte tail.</param>
    /// <returns>Owned contact with unresolved CCP/EXT references retained.</returns>
    class function DecodeAdn(const AData: TBytes): TSimPhonebookEntry; static;
    /// <summary>Encodes a standalone contact with no CCP/extension links.</summary>
    /// <param name="AName">GSM/UCS-2 name fitting the available alpha field.</param>
    /// <param name="ANumber">At most twenty TBCD symbols 0-9, star, hash, a/b/c; optional initial plus.</param>
    /// <param name="ARecordBytes">Actual record capacity, fourteen through 255.</param>
    /// <returns>Owned FF-padded complete record; no number/name truncation.</returns>
    class function EncodeAdn(const AName, ANumber: UnicodeString; const ARecordBytes: Integer): TBytes; static;
    /// <summary>Decodes EF.SMS allocation/status and preserves the exact PDU-containing field.</summary>
    /// <param name="AData">Exactly 176 bytes; includes status, SMSC/TPDU and padding.</param>
    /// <returns>Recognized state and owned untrimmed body; does not decode SMS text.</returns>
    class function DecodeSms(const AData: TBytes): TSimSmsRecord; static;
    /// <summary>Creates a complete stored-SMS record from an explicit status and body.</summary>
    /// <param name="AStatus">Defined free/received/unsent/sent status, including status-report forms.</param>
    /// <param name="ABody">Already encoded SMSC/TPDU field, at most 175 bytes; not interpreted.</param>
    /// <returns>Owned 176-byte record padded FF; no message transmission occurs.</returns>
    class function EncodeSms(const AStatus: Byte; const ABody: TBytes): TBytes; static;
    /// <summary>Decodes one EF.DIR application template without truncating trailing AID bytes.</summary>
    /// <param name="AData">One BER-TLV 61 template, optionally followed by FF padding.</param>
    /// <returns>Owned entry; an all-FF record returns an empty AID.</returns>
    class function DecodeDirectoryRecord(const AData: TBytes): TSimApplicationInfo; static;
  end;

implementation

uses ERD.Card.Bytes, ERD.Card.TLV;

const
  GsmAlphabet: array[0..127] of Word = (
    $0040,$00A3,$0024,$00A5,$00E8,$00E9,$00F9,$00EC,$00F2,$00C7,$000A,$00D8,$00F8,$000D,$00C5,$00E5,
    $0394,$005F,$03A6,$0393,$039B,$03A9,$03A0,$03A8,$03A3,$0398,$039E,$001B,$00C6,$00E6,$00DF,$00C9,
    $0020,$0021,$0022,$0023,$00A4,$0025,$0026,$0027,$0028,$0029,$002A,$002B,$002C,$002D,$002E,$002F,
    $0030,$0031,$0032,$0033,$0034,$0035,$0036,$0037,$0038,$0039,$003A,$003B,$003C,$003D,$003E,$003F,
    $00A1,$0041,$0042,$0043,$0044,$0045,$0046,$0047,$0048,$0049,$004A,$004B,$004C,$004D,$004E,$004F,
    $0050,$0051,$0052,$0053,$0054,$0055,$0056,$0057,$0058,$0059,$005A,$00C4,$00D6,$00D1,$00DC,$00A7,
    $00BF,$0061,$0062,$0063,$0064,$0065,$0066,$0067,$0068,$0069,$006A,$006B,$006C,$006D,$006E,$006F,
    $0070,$0071,$0072,$0073,$0074,$0075,$0076,$0077,$0078,$0079,$007A,$00E4,$00F6,$00F1,$00FC,$00E0
  );

procedure Fail;
begin raise ESimCardError.Create('Malformed or unsupported SIM data.'); end;

function AllFf(const B: TBytes; const Start: Integer): Boolean;
var I: Integer;
begin Result := True; for I := Start to High(B) do if B[I] <> $FF then Exit(False); end;

procedure RequireDecimal(const S: UnicodeString; const Min, Max: Integer);
var I: Integer;
begin
  if (Length(S) < Min) or (Length(S) > Max) then Fail;
  for I := 1 to Length(S) do if (S[I] < '0') or (S[I] > '9') then Fail;
end;

function ExtensionChar(const B: Byte): WideChar;
begin
  case B of
    $0A: Result := #$000C; $14: Result := '^'; $28: Result := '{'; $29: Result := '}';
    $2F: Result := '\'; $3C: Result := '['; $3D: Result := '~'; $3E: Result := ']';
    $40: Result := '|'; $65: Result := #$20AC;
  else Fail; Result := #0; end;
end;

function EncodeGsmChar(const C: WideChar; out AFirst, ASecond: Byte): Integer;
var I: Integer;
begin
  AFirst := 0; ASecond := 0; Result := 0;
  for I := 0 to 127 do if (I <> $1B) and (GsmAlphabet[I] = Ord(C)) then
  begin AFirst := I; Exit(1); end;
  AFirst := $1B;
  case C of
    #$000C: ASecond := $0A; '^': ASecond := $14; '{': ASecond := $28; '}': ASecond := $29;
    '\': ASecond := $2F; '[': ASecond := $3C; '~': ASecond := $3D; ']': ASecond := $3E;
    '|': ASecond := $40; #$20AC: ASecond := $65;
  else Exit; end;
  Result := 2;
end;

procedure AppendUcs2(var S: UnicodeString; const Code: Cardinal);
begin
  if (Code > $FFFF) or ((Code >= $D800) and (Code <= $DFFF)) then Fail;
  S := S + WideChar(Code);
end;

class function TSimCodec.FileAddress(const ARoot: TSimFileRoot;
  const APath: array of Word): TSimFileAddress;
var I: Integer;
begin
  Result := Default(TSimFileAddress);
  if not (ARoot in [sfrMasterFile,sfrUsimApplication]) or
    (Length(APath) < 1) or (Length(APath) > 8) then Fail;
  Result.Root := ARoot; SetLength(Result.Path,Length(APath));
  for I := 0 to High(APath) do
  begin
    if (APath[I] = $0000) or (APath[I] = $3F00) or (APath[I] = $FFFF) then Fail;
    Result.Path[I] := APath[I];
  end;
end;

class function TSimCodec.DecodeFileInfo(const AProfile: TSimCardProfile;
  const AData: TBytes): TSimFileInfo;
var Doc: TTlvDocument; Root, Node: TTlvNode; Fd, Fid, Size, Aid: TBytes;
  I, J, N: Integer; Tag: string; SeenFd, SeenFid, SeenSize, SeenAid: Boolean;
begin
  Result := Default(TSimFileInfo);
  if AProfile = scpGsmSim then
  begin
    if (Length(AData) < 15) or (Length(AData) > 255) or
      (Length(AData) <> 13 + AData[12]) then Fail;
    Result.FileId := (Word(AData[4]) shl 8) or AData[5];
    if AData[6] in [1,2] then
    begin if Length(AData) < 22 then Fail; Result.Structure := sfsDirectory; end
    else
    begin
      if AData[6] <> 4 then Fail;
      Result.Size := (Integer(AData[2]) shl 8) or AData[3];
      case AData[13] of
        0: Result.Structure := sfsTransparent;
        1: Result.Structure := sfsLinearFixed;
        3: Result.Structure := sfsCyclic;
      else Fail; end;
      if Result.Structure in [sfsLinearFixed,sfsCyclic] then
      begin
        Result.RecordBytes := AData[14];
        if (Result.RecordBytes = 0) or (Result.Size = 0) or
          (Result.Size mod Result.RecordBytes <> 0) then Fail;
        Result.RecordCount := Result.Size div Result.RecordBytes;
        if Result.RecordCount > 255 then Fail;
      end;
    end;
  end
  else if AProfile = scpUiccUsim then
  begin
    if (Length(AData) < 2) or (Length(AData) > 4096) then Fail;
    Doc := TTlvCodec.Decode(AData);
    try
      if Doc.Count <> 1 then Fail; Root := Doc.Roots[0];
      if (BytesToHex(Root.Tag) <> '62') or not Root.IsConstructed then Fail;
      Fd := nil; Fid := nil; Size := nil; Aid := nil;
      SeenFd := False; SeenFid := False; SeenSize := False; SeenAid := False;
      for I := 0 to Root.ChildCount - 1 do
      begin
        Node := Root.Children[I]; Tag := BytesToHex(Node.Tag);
        if Tag = '82' then begin if SeenFd then Fail; SeenFd := True; Fd := Node.Value; end
        else if Tag = '83' then begin if SeenFid then Fail; SeenFid := True; Fid := Node.Value; end
        else if Tag = '80' then begin if SeenSize then Fail; SeenSize := True; Size := Node.Value; end
        else if Tag = '84' then begin if SeenAid then Fail; SeenAid := True; Aid := Node.Value; end;
      end;
      if (Length(Fd) <> 2) and (Length(Fd) <> 5) then Fail;
      if (Fd[0] and $80 <> 0) or (Fd[1] <> $21) then Fail;
      if Length(Fid) > 0 then begin if Length(Fid) <> 2 then Fail;
        Result.FileId := (Word(Fid[0]) shl 8) or Fid[1]; end;
      if Fd[0] and $38 = $38 then
      begin if (Length(Fd) <> 2) or (Fd[0] and 7 <> 0) then Fail; Result.Structure := sfsDirectory; end
      else
      begin
        if (Fd[0] and $38 <> 0) or (Length(Fid) <> 2) then Fail;
        case Fd[0] and 7 of
          1: Result.Structure := sfsTransparent;
          2: Result.Structure := sfsLinearFixed;
          6: Result.Structure := sfsCyclic;
        else Fail; end;
        if (Length(Size) < 2) or (Length(Size) > 4) then Fail;
        N := 0;
        for J := 0 to High(Size) do
        begin if N > 131072 div 256 then Fail; N := N*256 + Size[J]; if N > 131072 then Fail; end;
        Result.Size := N;
        if Result.Structure = sfsTransparent then begin if Length(Fd) <> 2 then Fail; end
        else
        begin
          if Length(Fd) <> 5 then Fail;
          Result.RecordBytes := (Integer(Fd[2]) shl 8) or Fd[3]; Result.RecordCount := Fd[4];
          if (Result.RecordBytes < 1) or (Result.RecordBytes > 255) or
            (Result.RecordCount < 1) or (Result.Size <> Result.RecordBytes*Result.RecordCount) then Fail;
        end;
      end;
      if Length(Aid) > 0 then
      begin if (Length(Aid) < 5) or (Length(Aid) > 16) then Fail; Result.ApplicationAid := CopyBytes(Aid); end;
    finally Doc.Free; end;
  end else Fail;
  Result.Raw := CopyBytes(AData);
end;

class function TSimCodec.DecodeIccid(const AData: TBytes): UnicodeString;
var I, LowNibble, HighNibble: Integer;
begin
  if Length(AData) <> 10 then Fail; Result := '';
  for I := 0 to 9 do
  begin
    LowNibble := AData[I] and 15; HighNibble := AData[I] shr 4;
    if LowNibble > 9 then Fail; Result := Result + WideChar(Ord('0')+LowNibble);
    if HighNibble = 15 then begin if I <> 9 then Fail; end
    else begin if HighNibble > 9 then Fail; Result := Result + WideChar(Ord('0')+HighNibble); end;
  end;
end;

class function TSimCodec.EncodeIccid(const ADigits: UnicodeString): TBytes;
var I, H: Integer;
begin
  RequireDecimal(ADigits,19,20); Result := nil; SetLength(Result,10);
  for I := 0 to 9 do
  begin if I*2+2 <= Length(ADigits) then H := Ord(ADigits[I*2+2])-Ord('0') else H := 15;
    Result[I] := (H shl 4) or (Ord(ADigits[I*2+1])-Ord('0')); end;
end;

class function TSimCodec.DecodeImsi(const AData: TBytes): UnicodeString;
var I, Used, Digits, Nibble: Integer; Odd: Boolean;
begin
  if Length(AData) <> 9 then Fail;
  Used := AData[0]; if (Used < 3) or (Used > 8) then Fail;
  if not (AData[1] and 15 in [1,9]) or not AllFf(AData,Used+1) then Fail;
  Odd := AData[1] and 8 <> 0; Digits := Used*2-1; if not Odd then Dec(Digits);
  if (Digits < 5) or (Digits > 15) then Fail;
  Result := '';
  for I := 0 to Digits - 1 do
  begin
    if I = 0 then Nibble := AData[1] shr 4
    else if I mod 2 = 1 then Nibble := AData[1+(I+1) div 2] and 15
    else Nibble := AData[1+(I+1) div 2] shr 4;
    if Nibble > 9 then Fail; Result := Result + WideChar(Ord('0')+Nibble);
  end;
  if not Odd and (AData[Used] shr 4 <> 15) then Fail;
end;

class function TSimCodec.EncodeImsi(const ADigits: UnicodeString): TBytes;
var I, Index, V: Integer;
begin
  RequireDecimal(ADigits,5,15); Result := nil; SetLength(Result,9); FillChar(Result[0],9,$FF);
  Result[0] := (Length(ADigits)+2) div 2;
  Result[1] := ((Ord(ADigits[1])-Ord('0')) shl 4) or 1;
  if Length(ADigits) mod 2 = 1 then Result[1] := Result[1] or 8;
  for I := 2 to Length(ADigits) do
  begin Index := 1 + I div 2; V := Ord(ADigits[I])-Ord('0');
    if I mod 2 = 0 then Result[Index] := (Result[Index] and $F0) or V
    else Result[Index] := (Result[Index] and $0F) or (V shl 4); end;
end;

class function TSimCodec.DecodeAlpha(const AData: TBytes): UnicodeString;
var I, Start, Count, B: Integer; Base, Code: Cardinal;
begin
  Result := ''; if Length(AData) > 255 then Fail; if Length(AData) = 0 then Exit;
  if AData[0] = $80 then
  begin
    I := 1;
    while I+1 < Length(AData) do
    begin
      Code := (Cardinal(AData[I]) shl 8) or AData[I+1];
      if Code = $FFFF then begin if not AllFf(AData,I) then Fail; Exit; end;
      AppendUcs2(Result,Code); Inc(I,2);
    end;
    if (I < Length(AData)) and (AData[I] <> $FF) then Fail;
    Exit;
  end;
  Start := 0; Count := Length(AData); Base := 0;
  if AData[0] = $81 then
  begin if Length(AData) < 3 then Fail; Start := 3; Count := AData[1]; Base := Cardinal(AData[2]) shl 7; end
  else if AData[0] = $82 then
  begin if Length(AData) < 4 then Fail; Start := 4; Count := AData[1]; Base := (Cardinal(AData[2]) shl 8) or AData[3]; end;
  if Start > 0 then
  begin if Count > Length(AData)-Start then Fail; if not AllFf(AData,Start+Count) then Fail; end;
  I := Start;
  while I < Start+Count do
  begin
    B := AData[I]; Inc(I);
    if (Start = 0) and (B = $FF) then begin if not AllFf(AData,I) then Fail; Exit; end;
    if B < $80 then
    begin
      if B = $1B then begin if I >= Start+Count then Fail;
        Result := Result + ExtensionChar(AData[I]); Inc(I); end
      else Result := Result + WideChar(GsmAlphabet[B]);
    end else begin if Start = 0 then Fail; AppendUcs2(Result,Base+Cardinal(B and $7F)); end;
  end;
end;

class function TSimCodec.EncodeAlpha(const AText: UnicodeString; const AFieldBytes: Integer): TBytes;
var I, J, N, Total: Integer; First, Second: Byte; Gsm: Boolean;
begin
  if (AFieldBytes < 0) or (AFieldBytes > 255) or (Length(AText) > 255) then Fail;
  Gsm := True; Total := 0;
  for I := 1 to Length(AText) do
  begin N := EncodeGsmChar(AText[I],First,Second); if N = 0 then Gsm := False; Inc(Total,N); end;
  if not Gsm then Total := 1+Length(AText)*2;
  if Total > AFieldBytes then Fail;
  Result := nil; SetLength(Result,AFieldBytes); if AFieldBytes > 0 then FillChar(Result[0],AFieldBytes,$FF);
  J := 0;
  if not Gsm then begin Result[0] := $80; J := 1; end;
  for I := 1 to Length(AText) do
    if Gsm then
    begin
      N := EncodeGsmChar(AText[I],First,Second); Result[J] := First; Inc(J);
      if N = 2 then begin Result[J] := Second; Inc(J); end;
    end else
    begin
      if (Ord(AText[I]) >= $D800) and (Ord(AText[I]) <= $DFFF) or (Ord(AText[I]) = $FFFF) then Fail;
      Result[J] := Ord(AText[I]) shr 8; Result[J+1] := Ord(AText[I]) and $FF; Inc(J,2);
    end;
end;

class function TSimCodec.DecodeServices(const AProfile: TSimCardProfile; const AData: TBytes): TSimServices;
var I, PerByte, Shift: Integer;
begin
  if not (AProfile in [scpGsmSim,scpUiccUsim]) or (Length(AData) < 1) or (Length(AData) > 255) then Fail;
  if AProfile = scpGsmSim then PerByte := 4 else PerByte := 8;
  Result := nil; SetLength(Result,Length(AData)*PerByte);
  for I := 0 to High(Result) do
  begin
    Result[I].Number := I+1; Shift := I mod PerByte;
    if AProfile = scpGsmSim then Shift := Shift*2;
    Result[I].Available := (AData[I div PerByte] and (1 shl Shift)) <> 0;
    if AProfile = scpGsmSim then Result[I].Active := (AData[I div PerByte] and (2 shl Shift)) <> 0
    else Result[I].Active := Result[I].Available;
  end;
end;

class function TSimCodec.DecodeSpn(const AData: TBytes): TSimServiceProvider;
begin
  if Length(AData) <> 17 then Fail; Result := Default(TSimServiceProvider);
  Result.DisplayCondition := AData[0]; Result.Name := DecodeAlpha(Copy(AData,1,16));
end;
class function TSimCodec.EncodeSpn(const AName: UnicodeString; const ADisplayCondition: Byte): TBytes;
var B: TBytes;
begin
  if ADisplayCondition > 3 then Fail; B := EncodeAlpha(AName,16);
  Result := nil; SetLength(Result,17); Result[0] := ADisplayCondition; Move(B[0],Result[1],16);
end;

function DialChar(const N: Integer): WideChar;
const Symbols: UnicodeString = '0123456789*#abc';
begin if (N < 0) or (N > 14) then Fail; Result := Symbols[N+1]; end;

class function TSimCodec.DecodeAdn(const AData: TBytes): TSimPhonebookEntry;
var Tail, N, I, Lo, Hi: Integer;
begin
  Result := Default(TSimPhonebookEntry);
  if (Length(AData) < 14) or (Length(AData) > 255) then Fail;
  Result.Raw := CopyBytes(AData); Result.Empty := AllFf(AData,0); Tail := Length(AData)-14;
  Result.Name := DecodeAlpha(Copy(AData,0,Tail)); Result.TonNpi := AData[Tail+1];
  Result.CapabilityRecord := AData[Length(AData)-2]; Result.ExtensionRecord := AData[Length(AData)-1];
  N := AData[Tail]; if N in [0,$FF] then Exit;
  if (N < 1) or (N > 11) or (Result.TonNpi and $80 = 0) then Fail;
  for I := 0 to N-2 do
  begin
    Lo := AData[Tail+2+I] and 15; Hi := AData[Tail+2+I] shr 4;
    Result.Number := Result.Number + DialChar(Lo);
    if Hi = 15 then begin if I <> N-2 then Fail; end
    else Result.Number := Result.Number + DialChar(Hi);
  end;
  if (Result.Number <> '') and (Result.TonNpi and $70 = $10) then Result.Number := '+' + Result.Number;
end;

class function TSimCodec.EncodeAdn(const AName, ANumber: UnicodeString; const ARecordBytes: Integer): TBytes;
var Alpha: TBytes; Tail, I, N, Code: Integer; Number: UnicodeString; International: Boolean;
const Symbols: UnicodeString = '0123456789*#abc';
begin
  if (ARecordBytes < 14) or (ARecordBytes > 255) then Fail;
  Tail := ARecordBytes-14; Alpha := EncodeAlpha(AName,Tail); Number := ANumber;
  International := (Number <> '') and (Number[1] = '+'); if International then Delete(Number,1,1);
  if (Length(Number) > 20) or (International and (Number = '')) then Fail;
  Result := nil; SetLength(Result,ARecordBytes); FillChar(Result[0],ARecordBytes,$FF);
  if Tail > 0 then Move(Alpha[0],Result[0],Tail);
  if Number = '' then Exit;
  N := (Length(Number)+1) div 2; Result[Tail] := N+1;
  if International then Result[Tail+1] := $91 else Result[Tail+1] := $81;
  for I := 1 to Length(Number) do
  begin
    Code := Pos(Number[I],Symbols)-1; if Code < 0 then Fail;
    if I mod 2 = 1 then Result[Tail+2+(I-1) div 2] := $F0 or Code
    else Result[Tail+2+(I-1) div 2] := (Result[Tail+2+(I-1) div 2] and 15) or (Code shl 4);
  end;
end;

class function TSimCodec.DecodeSms(const AData: TBytes): TSimSmsRecord;
begin
  if Length(AData) <> 176 then Fail; Result := Default(TSimSmsRecord);
  Result.StatusByte := AData[0]; Result.Body := Copy(AData,1,175); Result.State := sssUnknown;
  if AllFf(AData,0) or (AData[0] and 1 = 0) then Result.State := sssFree
  else if AData[0] and $E0 = 0 then case AData[0] and 7 of
    1: if AData[0] and $F8 = 0 then Result.State := sssReceivedRead;
    3: if AData[0] and $F8 = 0 then Result.State := sssReceivedUnread;
    7: if AData[0] and $F8 = 0 then Result.State := sssUnsent;
    5: if AData[0] and $1F in [$05,$0D,$15,$1D] then Result.State := sssSent;
  end;
end;
class function TSimCodec.EncodeSms(const AStatus: Byte; const ABody: TBytes): TBytes;
begin
  if not (AStatus in [$00,$01,$03,$05,$07,$0D,$15,$1D]) or (Length(ABody) > 175) then Fail;
  Result := nil; SetLength(Result,176); FillChar(Result[0],176,$FF); Result[0] := AStatus;
  if Length(ABody) > 0 then Move(ABody[0],Result[1],Length(ABody));
end;

class function TSimCodec.DecodeDirectoryRecord(const AData: TBytes): TSimApplicationInfo;
var Doc: TTlvDocument; Root, Node: TTlvNode; I, Count, HeaderBytes, Encoded: Integer; Tag: string; SeenLabel: Boolean;
begin
  Result := Default(TSimApplicationInfo); SeenLabel := False;
  if (Length(AData) < 1) or (Length(AData) > 255) then Fail;
  if AllFf(AData,0) then Exit;
  if (Length(AData) < 2) or (AData[0] <> $61) then Fail;
  HeaderBytes := 2; Count := AData[1];
  if Count = $81 then begin if Length(AData) < 3 then Fail; Count := AData[2]; HeaderBytes := 3; if Count < 128 then Fail; end
  else if Count >= $80 then Fail;
  Encoded := HeaderBytes+Count;
  if (Encoded > Length(AData)) or not AllFf(AData,Encoded) then Fail;
  Doc := TTlvCodec.Decode(Copy(AData,0,Encoded));
  try
    if Doc.Count <> 1 then Fail; Root := Doc.Roots[0];
    for I := 0 to Root.ChildCount-1 do
    begin
      Node := Root.Children[I]; Tag := BytesToHex(Node.Tag);
      if Tag = '4F' then begin if Result.Aid <> nil then Fail; Result.Aid := Node.Value;
        if (Length(Result.Aid) < 5) or (Length(Result.Aid) > 16) then Fail; end
      else if Tag = '50' then begin if SeenLabel then Fail; SeenLabel := True; Result.LabelBytes := Node.Value;
        Result.LabelText := DecodeAlpha(Result.LabelBytes); end;
    end;
    if Result.Aid = nil then Fail;
  finally Doc.Free; end;
end;

class function TSimCodec.DecodePhonebookReferences(const AData: TBytes): TSimPhonebookReferences;
var Position, Count, Header, Ending, I, J, N: Integer; Doc: TTlvDocument;
  Root, Node: TTlvNode; Tag, Value: TBytes; Ref: TSimPhonebookReference;
begin
  Result := nil;
  if (Length(AData) < 1) or (Length(AData) > 255) then Fail;
  Position := 0;
  while Position < Length(AData) do
  begin
    if AData[Position] = $FF then begin if not AllFf(AData,Position) then Fail; Break; end;
    if not ((AData[Position] = $A8) or (AData[Position] = $A9) or (AData[Position] = $AA)) then Fail;
    if Position+1 >= Length(AData) then Fail;
    Count := AData[Position+1]; Header := 2;
    if Count = $81 then begin if Position+2 >= Length(AData) then Fail; Count := AData[Position+2]; Header := 3; if Count < 128 then Fail; end
    else if Count >= $80 then Fail;
    Ending := Position+Header+Count; if (Count = 0) or (Ending > Length(AData)) then Fail;
    Position := Ending;
  end;
  if Position = 0 then Exit;
  Doc := TTlvCodec.Decode(Copy(AData,0,Position));
  try
    for I := 0 to Doc.Count-1 do
    begin
      Root := Doc.Roots[I]; Tag := Root.Tag;
      if (Length(Tag) <> 1) or (Root.ChildCount = 0) then Fail;
      for J := 0 to Root.ChildCount-1 do
      begin
        Node := Root.Children[J]; Tag := Node.Tag; Value := Node.Value;
        if (Length(Tag) <> 1) or (Tag[0] < $C0) or (Tag[0] > $CB) or
          ((Length(Value) <> 2) and (Length(Value) <> 3)) then Fail;
        Ref.TemplateIndex := I; Ref.TemplateTag := Root.Tag[0]; Ref.ReferenceIndex := J;
        Ref.RoleTag := Tag[0]; Ref.FileId := Word(Value[0]) shl 8 or Value[1]; Ref.ShortFileId := -1;
        if (Ref.FileId = 0) or (Ref.FileId = $3F00) or (Ref.FileId = $FFFF) then Fail;
        if Length(Value) = 3 then begin if (Value[2] < 1) or (Value[2] > 30) then Fail; Ref.ShortFileId := Value[2]; end;
        N := Length(Result); SetLength(Result,N+1); Result[N] := Ref;
      end;
    end;
  finally Doc.Free; end;
end;

end.
