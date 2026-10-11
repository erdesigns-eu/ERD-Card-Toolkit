unit ERD.Card.SIM.Workflow;

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
  /// <summary>Explicit record family; never infers a USIM ADN file identifier.</summary>
  TSimWorkflowKind = (
    /// <summary>ADN with optional complete PBR-linked phonebook files.</summary>
    swkPhonebook,
    /// <summary>Exact status/SMSC/TPDU/padding in EF.SMS records.</summary>
    swkSms);
  /// <summary>Complete explicitly addressed linear-fixed file image.</summary>
  TSimWorkflowFile = record
    /// <summary>Actual master/application root and directory/EF identifiers.</summary>
    Address: TSimFileAddress;
    /// <summary>Complete independently owned physical records.</summary>
    Records: TSimRecords;
  end;
  /// <summary>Complete bounded record-file images, main ADN/SMS first.</summary>
  TSimWorkflowFiles = array of TSimWorkflowFile;
  /// <summary>Complete record-family snapshot; no PIN or operator secret is included.</summary>
  TSimWorkflowSnapshot = record
    /// <summary>Contact or SMS interpretation.</summary>
    Kind: TSimWorkflowKind;
    /// <summary>Explicit protocol profile.</summary>
    Profile: TSimCardProfile;
    /// <summary>Full selected USIM AID, empty for classic SIM.</summary>
    ApplicationAid: TBytes;
    /// <summary>Observed ICCID; identity matching is not authentication.</summary>
    Iccid: UnicodeString;
    /// <summary>Selected PBR record, or zero for standalone ADN/SMS.</summary>
    PbrRecord: Integer;
    /// <summary>Main file followed by optional PBR and complete referenced EFs.</summary>
    Files: TSimWorkflowFiles;
  end;
  /// <summary>Logical portable contact input; encoding/allocation occurs only in an offline plan.</summary>
  TSimWorkflowContact = record
    /// <summary>GSM/UCS-2 contact name, never truncated.</summary>
    Name: UnicodeString;
    /// <summary>Dial string, including optional plus; EXT records allocated for long numbers.</summary>
    Number: UnicodeString;
    /// <summary>Optional email; requires one explicit supported PBR EMAIL reference.</summary>
    Email: UnicodeString;
    /// <summary>Optional inline additional number; requires one supported PBR ANR reference.</summary>
    AdditionalNumber: UnicodeString;
  end;
  /// <summary>Explicit logical contacts, without source-specific record pointers.</summary>
  TSimWorkflowContacts = array of TSimWorkflowContact;
  /// <summary>Frozen target-bound record changes; contains personal data but never a PIN.</summary>
  TSimWorkflowPlan = record
    /// <summary>Explicit record family.</summary>
    Kind: TSimWorkflowKind;
    /// <summary>Target profile, checked before execution.</summary>
    Profile: TSimCardProfile;
    /// <summary>Target full AID, independently copied.</summary>
    ApplicationAid: TBytes;
    /// <summary>Expected physical target ICCID.</summary>
    Iccid: UnicodeString;
    /// <summary>Complete current/replacement records in explicit dependency order.</summary>
    Changes: TSimRecordChanges;
  end;
  /// <summary>One target record's outcome, retained after partial failure.</summary>
  TSimWorkflowResult = record
    /// <summary>Actual EF address.</summary>
    Address: TSimFileAddress;
    /// <summary>One-based physical record.</summary>
    RecordNumber: Integer;
    /// <summary>Pending, unchanged, independently verified or uncertain.</summary>
    State: TCardWorkflowUnitState;
  end;
  /// <summary>Ordered independent per-record results.</summary>
  TSimWorkflowResults = array of TSimWorkflowResult;
  /// <summary>Inactive backend with explicit configuration and exclusive caller ownership.</summary>
  /// <remarks>Authentication is explicit and attempted at most once per workflow. Apply must check
  /// every original and ICCID inside one exclusive transaction, preserve evidence on errors and
  /// raise ESimCardWriteUncertain after any dispatched mutation. No automatic retry/reset.</remarks>
  ISimWorkflowCard = interface
    ['{A2D0E4D8-3A97-4A08-9076-1E9454812141}']
    /// <summary>Returns the configured profile without I/O.</summary>
    /// <returns>Classic or explicitly selected USIM.</returns>
    function Profile: TSimCardProfile;
    /// <summary>Returns an independently owned configured AID without I/O.</summary>
    /// <returns>Full USIM AID or empty classic value.</returns>
    function ApplicationAid: TBytes;
    /// <summary>Reads the exact card ICCID without authenticating.</summary>
    /// <returns>Decoded physical card identifier.</returns>
    function Identity: UnicodeString;
    /// <summary>Authenticates at most once if a supplied PIN is needed.</summary>
    /// <param name="APin">Borrowed read-only ASCII digits; never retained by this method.</param>
    procedure Authenticate(const APin: TBytes);
    /// <summary>Reads all records and enforces complete linear-fixed geometry.</summary>
    /// <param name="AFile">Explicit actual EF path.</param>
    /// <returns>Independently allocated complete records.</returns>
    function ReadRecords(const AFile: TSimFileAddress): TSimRecords;
    /// <summary>Applies the frozen complete plan once with independent read-back.</summary>
    /// <param name="APlan">Target identity and all expected/replacement records.</param>
    /// <param name="AResults">Evidence retained on exceptions.</param>
    procedure Apply(const APlan: TSimWorkflowPlan; out AResults: TSimRecordWriteResults);
  end;
  /// <summary>Native inactive adapter owning frozen reader settings, retaining transport interfaces.</summary>
  /// <remarks>The original reader may be freed after construction. Exclusively own the physical
  /// connection throughout the workflow; no competing reader, reset or card swap between steps.</remarks>
  TSimWorkflowCard = class(TInterfacedObject, ISimWorkflowCard)
  private
    FReader: TSimCardReaderWriter;
  public
    /// <summary>Copies explicit profile/AID/PIN policy without connecting or presenting a PIN.</summary>
    /// <param name="AReader">Inactive or idle configured native SIM reader.</param>
    constructor Create(const AReader: TSimCardReaderWriter);
    /// <summary>Releases the owned reader and retained transport.</summary>
    destructor Destroy; override;
    /// <summary>Returns the explicit configured protocol profile without I/O.</summary>
    /// <returns>Configured profile.</returns>
    function Profile: TSimCardProfile;
    /// <summary>Copies the complete configured USIM application name.</summary>
    /// <returns>Independent AID bytes.</returns>
    function ApplicationAid: TBytes;
    /// <summary>Reads master EF.ICCID without presenting a PIN.</summary>
    /// <returns>Observed card identifier.</returns>
    function Identity: UnicodeString;
    /// <summary>Uses known PIN state/budget and at most one supplied-code VERIFY.</summary>
    /// <param name="APin">Optional borrowed ASCII PIN, four through eight digits.</param>
    procedure Authenticate(const APin: TBytes);
    /// <summary>Reads complete linear-fixed records, refusing cyclic files.</summary>
    /// <param name="AFile">Explicit actual EF address.</param>
    /// <returns>Complete independently owned physical records.</returns>
    function ReadRecords(const AFile: TSimFileAddress): TSimRecords;
    /// <summary>Calls the native identity/preimage-checked record planner with retained evidence.</summary>
    /// <param name="APlan">Explicit target-bound plan.</param>
    /// <param name="AResults">Dispatch/read-back evidence even after failure.</param>
    procedure Apply(const APlan: TSimWorkflowPlan; out AResults: TSimRecordWriteResults);
  end;
  /// <summary>Offline snapshot validation, dependency planning and logical free-record imports.</summary>
  TSimWorkflowCodec = class
  public
    /// <summary>Validates complete geometry, explicit paths and contact/SMS interpretation without I/O.</summary>
    /// <param name="ASnapshot">Complete family snapshot; PBR references must resolve within it.</param>
    class procedure Validate(const ASnapshot: TSimWorkflowSnapshot); static;
    /// <summary>Validates complete unique target-bound record replacements without I/O.</summary>
    /// <param name="APlan">Explicit target identity, profile and unique full records.</param>
    class procedure ValidatePlan(const APlan: TSimWorkflowPlan); static;
    /// <summary>Plans exact compatible-layout restoration, including linked EFs; PBR is read-only.</summary>
    /// <param name="ASource">Complete source snapshot.</param>
    /// <param name="ATarget">Fresh complete target snapshot, including exact expected bytes.</param>
    /// <returns>Frozen target-bound changes; dependent data precedes IAP/ADN link records.</returns>
    class function RestorePlan(const ASource, ATarget: TSimWorkflowSnapshot): TSimWorkflowPlan; static;
    /// <summary>Allocates standalone ADN contacts in erased target slots; never overwrites or truncates.</summary>
    /// <param name="ATarget">Standalone complete ADN snapshot without linked references.</param>
    /// <param name="AContacts">Explicit nonempty name/number entries with no CCP/EXT links.</param>
    /// <returns>Complete allocation plan; insufficient space/encoding rejects the entire request.</returns>
    class function ImportContacts(const ATarget: TSimWorkflowSnapshot;
      const AContacts: TSimPhonebookEntries): TSimWorkflowPlan; static;
    /// <summary>Allocates contacts and linked EXT/EMAIL/ANR records from an explicit complete target layout.</summary>
    /// <param name="ATarget">PBR-linked USIM snapshot or classic standard ADN/EXT1 snapshot.</param>
    /// <param name="AContacts">Logical names, numbers, optional EMAIL/ANR; no implicit replacement.</param>
    /// <returns>All-or-nothing target-bound plan, dependent records before IAP/ADN. Unsupported or ambiguous layouts fail before I/O.</returns>
    /// <remarks>One ADN/IAP/EXT/EMAIL/ANR reference each; only supported A8/A9 bindings.
    /// All allocated records must be erased and unreferenced. Existing contacts/unknown bindings are never overwritten.</remarks>
    class function ImportLinkedContacts(const ATarget: TSimWorkflowSnapshot;
      const AContacts: TSimWorkflowContacts): TSimWorkflowPlan; static;
    /// <summary>Allocates explicit stored SMS records in free target slots, preserving all 176 bytes.</summary>
    /// <param name="ATarget">Complete EF.SMS snapshot.</param>
    /// <param name="ARecords">Allocated complete records, including supplied multipart segment sets.</param>
    /// <returns>All-or-nothing offline allocation plan; no sending or automatic grouping.</returns>
    class function ImportSms(const ATarget: TSimWorkflowSnapshot;
      const ARecords: TSimRecords): TSimWorkflowPlan; static;
    /// <summary>Validates and allocates one explicit complete multipart SMS group without sending.</summary>
    /// <param name="ATarget">Complete target EF.SMS snapshot.</param>
    /// <param name="ARecords">All segments of exactly one supplied group, in any order.</param>
    /// <returns>Status-preserving allocation plan; missing, mixed or duplicate segments are refused.</returns>
    class function ImportSmsGroup(const ATarget: TSimWorkflowSnapshot;
      const ARecords: TSimRecords): TSimWorkflowPlan; static;
    /// <summary>Formats physical capacity, decoded contacts/linked fields and SMS states/text.</summary>
    /// <param name="ASnapshot">Complete snapshot; unsupported SMS text remains exact raw bytes.</param>
    /// <returns>Human-readable Unicode report; contains personal data.</returns>
    class function Report(const ASnapshot: TSimWorkflowSnapshot): UnicodeString; static;
    /// <summary>Serializes an ASCII complete bounded snapshot without secrets.</summary>
    /// <param name="ASnapshot">Complete snapshot to validate and copy.</param>
    /// <returns>ERD-SIM-SNAPSHOT 1 text.</returns>
    class function EncodeSnapshot(const ASnapshot: TSimWorkflowSnapshot): string; static;
    /// <summary>Decodes a strict bounded snapshot before card access.</summary>
    /// <param name="AText">Canonical ASCII archive up to five MiB.</param>
    /// <returns>Independent validated snapshot.</returns>
    class function DecodeSnapshot(const AText: string): TSimWorkflowSnapshot; static;
    /// <summary>Serializes a target-bound preview/apply plan without a PIN.</summary>
    /// <param name="APlan">Complete validated explicit changes.</param>
    /// <returns>ERD-SIM-PLAN 1 text with exact expected/replacement records.</returns>
    class function EncodePlan(const APlan: TSimWorkflowPlan): string; static;
    /// <summary>Decodes and validates a bounded explicit plan before connecting.</summary>
    /// <param name="AText">Canonical ASCII plan up to ten MiB.</param>
    /// <returns>Independent target-bound plan.</returns>
    class function DecodePlan(const AText: string): TSimWorkflowPlan; static;
  end;
  /// <summary>Shared record-family workflow; use a concrete phonebook or SMS component.</summary>
  TSimRecordWorkflow = class abstract(TCardWorkflow)
  private
    FCard: ISimWorkflowCard;
    FSnapshot: TSimWorkflowSnapshot;
    FPlan: TSimWorkflowPlan;
    FResults: TSimWorkflowResults;
    FFile: TSimFileAddress;
    FPin: TBytes;
    FPbrRecord, FAction: Integer;
    FPrepared, FConsumed, FIncludeClassicExt: Boolean;
    function Capture: TSimWorkflowSnapshot;
    function GetSnapshot: TSimWorkflowSnapshot;
    function GetPlan: TSimWorkflowPlan;
    function GetResults: TSimWorkflowResults;
    procedure Initialize(const ACard: ISimWorkflowCard; const APin: TBytes);
  protected
    /// <summary>Identifies the concrete family without I/O.</summary>
    /// <returns>Phonebook or SMS family.</returns>
    function Kind: TSimWorkflowKind; virtual; abstract;
    /// <summary>Checks single-use request before events or hardware.</summary>
    procedure ValidatePrepared; override;
    /// <summary>Captures, previews or applies once, retaining per-record evidence.</summary>
    procedure DoExecute; override;
  public
    /// <summary>Clears independently owned PIN bytes and releases inactive backends.</summary>
    destructor Destroy; override;
    /// <summary>Prepares complete main-file acquisition and optional PBR-linked EF discovery.</summary>
    /// <param name="ACard">Inactive explicitly configured card backend.</param>
    /// <param name="AFile">Actual ADN/SMS EF address; USIM ADN is not inferred.</param>
    /// <param name="APbrRecord">Selected PBR record for linked USIM contacts; zero for standalone/SMS.</param>
    /// <param name="APin">Optional ASCII PIN, independently copied and wiped after execution.</param>
    procedure PrepareBackup(const ACard: ISimWorkflowCard; const AFile: TSimFileAddress;
      const APbrRecord: Integer = 0; const APin: TBytes = nil);
    /// <summary>Reads a fresh target and constructs a complete restore preview; never writes.</summary>
    /// <param name="ACard">Inactive target backend.</param>
    /// <param name="ASnapshot">Owned complete source snapshot; copied before execution.</param>
    /// <param name="APin">Optional ASCII PIN for reading protected target records.</param>
    procedure PreparePreview(const ACard: ISimWorkflowCard; const ASnapshot: TSimWorkflowSnapshot;
      const APin: TBytes = nil);
    /// <summary>Applies an already reviewed target-bound plan once; all originals are rechecked.</summary>
    /// <param name="ACard">Inactive target backend.</param>
    /// <param name="APlan">Explicit complete reviewed plan; independently copied.</param>
    /// <param name="APin">Optional supplied ASCII PIN; never serialized in a plan.</param>
    procedure PrepareApply(const ACard: ISimWorkflowCard; const APlan: TSimWorkflowPlan;
      const APin: TBytes = nil);
    /// <summary>Independently owned complete acquired/source snapshot.</summary>
    property Snapshot: TSimWorkflowSnapshot read GetSnapshot;
    /// <summary>Independent frozen target-bound plan, available after preview.</summary>
    property Plan: TSimWorkflowPlan read GetPlan;
    /// <summary>Independent per-record evidence after apply, including partial failures.</summary>
    property Results: TSimWorkflowResults read GetResults;
  end;
  /// <summary>Complete standalone or explicit PBR-linked contact backup, restore preview and apply.</summary>
  TSimPhonebookWorkflow = class(TSimRecordWorkflow)
  public
    /// <summary>Prepares explicit complete standard classic ADN/EXT1 acquisition, even with no current extension links.</summary>
    /// <param name="ACard">Explicit classic SIM backend; both standard EFs must be present.</param>
    /// <param name="APin">Optional independently owned ASCII PIN.</param>
    procedure PrepareClassicBackup(const ACard: ISimWorkflowCard; const APin: TBytes = nil);
  protected
    /// <summary>Returns the contact family without I/O.</summary>
    /// <returns>swkPhonebook.</returns>
    function Kind: TSimWorkflowKind; override;
  end;
  /// <summary>Complete EF.SMS backup, exact status-preserving restore preview and apply.</summary>
  TSimSmsWorkflow = class(TSimRecordWorkflow)
  protected
    /// <summary>Returns the stored SMS family without I/O.</summary>
    /// <returns>swkSms.</returns>
    function Kind: TSimWorkflowKind; override;
  end;

implementation

uses ERD.Card.Crypto;

procedure Invalid;
begin raise ECardWorkflowError.Create('Invalid SIM snapshot, plan or incompatible layout.'); end;
function AddressEqual(const A, B: TSimFileAddress): Boolean;
var I: Integer;
begin Result := (A.Root = B.Root) and (Length(A.Path) = Length(B.Path));
  if Result then for I := 0 to High(A.Path) do if A.Path[I] <> B.Path[I] then begin Result := False; Exit; end;
end;
function CopyAddress(const A: TSimFileAddress): TSimFileAddress;
begin Result.Root := A.Root; Result.Path := Copy(A.Path, 0, Length(A.Path)); end;
procedure AddressValid(const A: TSimFileAddress);
var B: TSimFileAddress;
begin if (Ord(A.Root) < 0) or (Ord(A.Root) > 1) then Invalid;
  B := TSimCodec.FileAddress(A.Root, A.Path); if not AddressEqual(A, B) then Invalid;
end;
procedure ProfileValid(const Profile: TSimCardProfile; const Aid: TBytes);
begin
  if not (Ord(Profile) in [0 .. 1]) then Invalid;
  if (Profile = scpGsmSim) and (Length(Aid) <> 0) then Invalid;
  if (Profile = scpUiccUsim) and ((Length(Aid) < 5) or (Length(Aid) > 16)) then Invalid;
end;
procedure ConfigValid(const Profile: TSimCardProfile; const Aid: TBytes; const Iccid: UnicodeString);
var B: TBytes;
begin ProfileValid(Profile, Aid); B := TSimCodec.EncodeIccid(Iccid); if Length(B) <> 10 then Invalid; end;
function PhoneFiles(const S: TSimWorkflowSnapshot): TSimPhonebookFiles;
var I: Integer;
begin Result := nil; SetLength(Result, Length(S.Files));
  for I := 0 to High(Result) do begin Result[I].FileId := S.Files[I].Address.Path[High(S.Files[I].Address.Path)];
    Result[I].Records := S.Files[I].Records; end;
end;
function PbrIndex(const S: TSimWorkflowSnapshot): Integer;
var I: Integer;
begin Result := -1; for I := 1 to High(S.Files) do if S.Files[I].Address.Path[High(S.Files[I].Address.Path)] = $4F30 then Result := I; end;
function References(const S: TSimWorkflowSnapshot): TSimPhonebookReferences;
var I: Integer;
begin
  Result := nil;
  if (S.PbrRecord = 0) and (S.Kind = swkPhonebook) and (Length(S.Files) = 2) then
  begin
    SetLength(Result, 2); Result[0].TemplateTag := $A8; Result[0].RoleTag := $C0;
    Result[0].FileId := S.Files[0].Address.Path[High(S.Files[0].Address.Path)]; Result[0].ShortFileId := -1;
    Result[1].TemplateTag := $AA; Result[1].RoleTag := $C2;
    Result[1].FileId := S.Files[1].Address.Path[High(S.Files[1].Address.Path)]; Result[1].ShortFileId := -1;
    Exit;
  end;
  I := PbrIndex(S); if (I < 0) or (S.PbrRecord < 1) or
  (S.PbrRecord > Length(S.Files[I].Records)) then Invalid;
  Result := TSimCodec.DecodePhonebookReferences(S.Files[I].Records[S.PbrRecord - 1]);
end;
class procedure TSimWorkflowCodec.Validate(const ASnapshot: TSimWorkflowSnapshot);
var I, J, K, Bytes, Total: Integer; Contact: TSimPhonebookEntry; Linked: TSimLinkedContact;
  Ref: TSimPhonebookReferences; Files: TSimPhonebookFiles;
begin
  ConfigValid(ASnapshot.Profile, ASnapshot.ApplicationAid, ASnapshot.Iccid);
  if not (Ord(ASnapshot.Kind) in [0 .. 1]) or (Length(ASnapshot.Files) < 1) or
    (Length(ASnapshot.Files) > 32) or (ASnapshot.PbrRecord < 0) or (ASnapshot.PbrRecord > 255) then Invalid;
  if (ASnapshot.Kind = swkSms) and ((Length(ASnapshot.Files) <> 1) or (ASnapshot.PbrRecord <> 0)) then Invalid;
  Total := 0;
  for I := 0 to High(ASnapshot.Files) do
  begin
    AddressValid(ASnapshot.Files[I].Address);
    if (ASnapshot.Profile = scpGsmSim) and (ASnapshot.Files[I].Address.Root <> sfrMasterFile) then Invalid;
    for J := 0 to I - 1 do if AddressEqual(ASnapshot.Files[I].Address, ASnapshot.Files[J].Address) then Invalid;
    if (Length(ASnapshot.Files[I].Records) < 1) or (Length(ASnapshot.Files[I].Records) > 255) then Invalid;
    Bytes := Length(ASnapshot.Files[I].Records[0]); if (Bytes < 1) or (Bytes > 255) then Invalid;
    for J := 0 to High(ASnapshot.Files[I].Records) do
    begin if Length(ASnapshot.Files[I].Records[J]) <> Bytes then Invalid; Inc(Total, Bytes); end;
    if Total > 2080800 then Invalid;
  end;
  if ASnapshot.PbrRecord > 0 then
  begin
    if (ASnapshot.Kind <> swkPhonebook) or (ASnapshot.Profile <> scpUiccUsim) then Invalid;
    for I := 0 to High(ASnapshot.Files) do
      if (ASnapshot.Files[I].Address.Root <> sfrUsimApplication) or (Length(ASnapshot.Files[I].Address.Path) <> 2) or
        (ASnapshot.Files[I].Address.Path[0] <> $5F3A) then Invalid;
    Ref := References(ASnapshot); Files := PhoneFiles(ASnapshot);
    for I := 0 to High(Ref) do begin K := -1; for J := 0 to High(Files) do if Files[J].FileId = Ref[I].FileId then K := J;
      if K < 0 then Invalid; end;
    for I := 0 to High(ASnapshot.Files[0].Records) do begin Linked := TSimCodec.ResolvePhonebookContact(Ref, Files,
      Files[0].FileId, I + 1); if not Linked.Contact.Empty and (Linked.Contact.RecordNumber <> I + 1) then Invalid; end;
  end
  else
  begin
    if (Length(ASnapshot.Files) <> 1) and (Length(ASnapshot.Files) <> 2) then Invalid;
    if Length(ASnapshot.Files) = 2 then
    begin
      if (ASnapshot.Kind <> swkPhonebook) or (ASnapshot.Profile <> scpGsmSim) or
        not AddressEqual(ASnapshot.Files[0].Address, TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F3A])) or
        not AddressEqual(ASnapshot.Files[1].Address, TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F4A])) then Invalid;
      Ref := References(ASnapshot); Files := PhoneFiles(ASnapshot);
    end;
    for I := 0 to High(ASnapshot.Files[0].Records) do
      if ASnapshot.Kind = swkSms then TSimCodec.DecodeSms(ASnapshot.Files[0].Records[I])
      else begin Contact := TSimCodec.DecodeAdn(ASnapshot.Files[0].Records[I]);
        if not Contact.Empty then begin
          if Contact.CapabilityRecord <> $FF then Invalid;
          if Length(ASnapshot.Files) = 2 then Linked := TSimCodec.ResolvePhonebookContact(Ref, Files, Files[0].FileId, I + 1)
          else if Contact.ExtensionRecord <> $FF then Invalid;
        end;
      end;
  end;
end;
class procedure TSimWorkflowCodec.ValidatePlan(const APlan: TSimWorkflowPlan);
var I, J: Integer;
begin
  ConfigValid(APlan.Profile, APlan.ApplicationAid, APlan.Iccid);
  if not (Ord(APlan.Kind) in [0 .. 1]) or (Length(APlan.Changes) > 8192) then Invalid;
  for I := 0 to High(APlan.Changes) do
  begin
    AddressValid(APlan.Changes[I].FileAddress);
    if (APlan.Profile = scpGsmSim) and (APlan.Changes[I].FileAddress.Root <> sfrMasterFile) then Invalid;
    if APlan.Changes[I].FileAddress.Path[High(APlan.Changes[I].FileAddress.Path)] = $4F30 then Invalid;
    if (APlan.Changes[I].RecordNumber < 1) or (APlan.Changes[I].RecordNumber > 255) or
      (Length(APlan.Changes[I].Data) < 1) or (Length(APlan.Changes[I].Data) > 255) or
      (Length(APlan.Changes[I].ExpectedBefore) <> Length(APlan.Changes[I].Data)) then Invalid;
    if APlan.Kind = swkSms then begin if Length(APlan.Changes[I].Data) <> 176 then Invalid; end;
    for J := 0 to I - 1 do if AddressEqual(APlan.Changes[I].FileAddress, APlan.Changes[J].FileAddress) and
      (APlan.Changes[I].RecordNumber = APlan.Changes[J].RecordNumber) then Invalid;
  end;
end;
function NewPlan(const S: TSimWorkflowSnapshot): TSimWorkflowPlan;
begin Result := Default(TSimWorkflowPlan); Result.Kind := S.Kind; Result.Profile := S.Profile;
  Result.ApplicationAid := CopyBytes(S.ApplicationAid); Result.Iccid := S.Iccid; end;
procedure AddChange(var P: TSimWorkflowPlan; const F: TSimWorkflowFile; const N: Integer; const D: TBytes);
var K: Integer;
begin K := Length(P.Changes); SetLength(P.Changes, K + 1); P.Changes[K].FileAddress := CopyAddress(F.Address);
  P.Changes[K].RecordNumber := N + 1; P.Changes[K].ExpectedBefore := CopyBytes(F.Records[N]); P.Changes[K].Data := CopyBytes(D); end;
class function TSimWorkflowCodec.RestorePlan(const ASource, ATarget: TSimWorkflowSnapshot): TSimWorkflowPlan;
var I, J, K, Priority, Rank, Pbr: Integer; Ref: TSimPhonebookReferences;
begin
  Validate(ASource); Validate(ATarget);
  if (ASource.Kind <> ATarget.Kind) or (ASource.Profile <> ATarget.Profile) or
    not BytesEqual(ASource.ApplicationAid, ATarget.ApplicationAid) or (ASource.PbrRecord <> ATarget.PbrRecord) or
    (Length(ASource.Files) <> Length(ATarget.Files)) then Invalid;
  Result := NewPlan(ATarget); Pbr := PbrIndex(ASource); Ref := nil;
  if Pbr >= 0 then Ref := References(ASource);
  for I := 0 to High(ASource.Files) do
  begin
    K := -1; for J := 0 to High(ATarget.Files) do if AddressEqual(ASource.Files[I].Address, ATarget.Files[J].Address) then K := J;
    if (K < 0) or (Length(ASource.Files[I].Records) <> Length(ATarget.Files[K].Records)) then Invalid;
    for J := 0 to High(ASource.Files[I].Records) do
    begin
      if Length(ASource.Files[I].Records[J]) <> Length(ATarget.Files[K].Records[J]) then Invalid;
      if (I = Pbr) and not BytesEqual(ASource.Files[I].Records[J], ATarget.Files[K].Records[J]) then Invalid;
    end;
  end;
  for Priority := 0 to 2 do for I := 0 to High(ASource.Files) do
  begin
    if I = Pbr then Continue;
    Rank := 0; if I = 0 then Rank := 2;
    for J := 0 to High(Ref) do if (Ref[J].RoleTag = $C1) and
      (Ref[J].FileId = ASource.Files[I].Address.Path[High(ASource.Files[I].Address.Path)]) then Rank := 1;
    if Rank <> Priority then Continue;
    K := -1; for J := 0 to High(ATarget.Files) do if AddressEqual(ASource.Files[I].Address, ATarget.Files[J].Address) then K := J;
    for J := 0 to High(ASource.Files[I].Records) do
      if not BytesEqual(ASource.Files[I].Records[J], ATarget.Files[K].Records[J]) then
        AddChange(Result, ATarget.Files[K], J, ASource.Files[I].Records[J]);
  end;
  ValidatePlan(Result);
end;
class function TSimWorkflowCodec.ImportContacts(const ATarget: TSimWorkflowSnapshot;
  const AContacts: TSimPhonebookEntries): TSimWorkflowPlan;
var I, N: Integer; D: TBytes; Entry: TSimPhonebookEntry;
begin
  Validate(ATarget); if (ATarget.Kind <> swkPhonebook) or (ATarget.PbrRecord <> 0) or
    (Length(AContacts) < 1) or (Length(AContacts) > 255) then Invalid;
  Result := NewPlan(ATarget); N := 0;
  for I := 0 to High(AContacts) do
  begin
    if AContacts[I].Empty or (AContacts[I].CapabilityRecord <> $FF) or (AContacts[I].ExtensionRecord <> $FF) then Invalid;
    while N < Length(ATarget.Files[0].Records) do begin Entry := TSimCodec.DecodeAdn(ATarget.Files[0].Records[N]);
      if Entry.Empty then Break; Inc(N); end;
    if N >= Length(ATarget.Files[0].Records) then Invalid;
    D := TSimCodec.EncodeAdn(AContacts[I].Name, AContacts[I].Number, Length(ATarget.Files[0].Records[N]));
    Entry := TSimCodec.DecodeAdn(D); if Entry.Empty then Invalid;
    AddChange(Result, ATarget.Files[0], N, D); Inc(N);
  end;
  ValidatePlan(Result);
end;
class function TSimWorkflowCodec.ImportLinkedContacts(const ATarget: TSimWorkflowSnapshot;
  const AContacts: TSimWorkflowContacts): TSimWorkflowPlan;
var Ref: TSimPhonebookReferences; Work: TSimWorkflowSnapshot; C: TSimPhonebookEntry;
  AdnRef, IapRef, ExtRef, EmailRef, AnrRef, I, J, K, Slot, N, Offset, Next, Last, Footer: Integer;
  Data, AdnBytes, IapData: TBytes; Number, Part: UnicodeString;
  function FileIndex(const R: Integer): Integer;
  var X: Integer;
  begin Result := -1; if R < 0 then Exit;
    for X := 0 to High(Work.Files) do if Work.Files[X].Address.Path[High(Work.Files[X].Address.Path)] = Ref[R].FileId then Result := X;
    if Result < 0 then Invalid;
  end;
  function Erased(const B: TBytes): Boolean;
  var X: Integer;
  begin Result := True; for X := 0 to High(B) do if B[X] <> $FF then begin Result := False; Exit; end; end;
  procedure Change(const F, RecordIndex: Integer; const B: TBytes);
  begin AddChange(Result, ATarget.Files[F], RecordIndex, B); Work.Files[F].Records[RecordIndex] := CopyBytes(B); end;
  function Allocate(const F: Integer): Integer;
  var X: Integer;
  begin Result := -1; if F < 0 then Invalid;
    for X := 0 to High(Work.Files[F].Records) do if (X < 254) and Erased(Work.Files[F].Records[X]) then begin Result := X; Exit; end;
    Invalid;
  end;
  procedure WriteField(const R: Integer; const Value: UnicodeString; const IsAnr: Boolean);
  var F, Index, Width: Integer; B, Encoded: TBytes;
  begin
    if Value = '' then Exit; if R < 0 then Invalid; F := FileIndex(R);
    Footer := 0; Index := Slot;
    if Ref[R].TemplateTag = $A9 then begin Footer := 2; Index := Allocate(F);
      if (IapRef < 0) or (Ref[R].ReferenceIndex >= Length(IapData)) or (Ref[AdnRef].ShortFileId < 1) then Invalid;
      IapData[Ref[R].ReferenceIndex] := Index + 1; end
    else if Ref[R].TemplateTag <> $A8 then Invalid;
    if (Index >= Length(Work.Files[F].Records)) or not Erased(Work.Files[F].Records[Index]) then Invalid;
    Width := Length(Work.Files[F].Records[Index]); SetLength(B, Width); FillChar(B[0], Width, $FF);
    if IsAnr then begin if Width - Footer < 15 then Invalid; Encoded := TSimCodec.EncodeAdn('', Value, 14);
      Move(Encoded[0], B[1], 14); end
    else begin Encoded := TSimCodec.EncodeAlpha(Value, Width - Footer); if Length(Encoded) > 0 then Move(Encoded[0], B[0], Length(Encoded)); end;
    if Footer = 2 then begin B[Width - 2] := Ref[AdnRef].ShortFileId; B[Width - 1] := Slot + 1; end;
    Change(F, Index, B);
  end;
begin
  Validate(ATarget); if (ATarget.Kind <> swkPhonebook) or (Length(ATarget.Files) < 2) or
    (Length(AContacts) < 1) or (Length(AContacts) > 255) then Invalid;
  Work := DecodeSnapshot(EncodeSnapshot(ATarget)); Ref := References(ATarget); Result := NewPlan(ATarget);
  AdnRef := -1; IapRef := -1; ExtRef := -1; EmailRef := -1; AnrRef := -1;
  for I := 0 to High(Ref) do
  begin
    case Ref[I].RoleTag of
      $C0: begin if AdnRef >= 0 then Invalid; AdnRef := I; end;
      $C1: begin if IapRef >= 0 then Invalid; IapRef := I; end;
      $C2: begin if ExtRef >= 0 then Invalid; ExtRef := I; end;
      $CA: begin if EmailRef >= 0 then Invalid; EmailRef := I; end;
      $C4: begin if AnrRef >= 0 then Invalid; AnrRef := I; end;
    else Invalid; end;
    if Ref[I].RoleTag <> $C2 then if not (Ref[I].TemplateTag in [$A8, $A9]) then Invalid;
  end;
  if (AdnRef < 0) or (Ref[AdnRef].TemplateTag <> $A8) or (FileIndex(AdnRef) <> 0) then Invalid;
  if (IapRef >= 0) and (Ref[IapRef].TemplateTag <> $A8) then Invalid;
  for I := 0 to High(AContacts) do
  begin
    Slot := -1;
    for J := 0 to High(Work.Files[0].Records) do
    begin
      C := TSimCodec.DecodeAdn(Work.Files[0].Records[J]); if not C.Empty then Continue;
      if IapRef >= 0 then begin K := FileIndex(IapRef); if (J >= Length(Work.Files[K].Records)) or
        not Erased(Work.Files[K].Records[J]) then Continue; end;
      if EmailRef >= 0 then if Ref[EmailRef].TemplateTag = $A8 then begin K := FileIndex(EmailRef);
        if (J >= Length(Work.Files[K].Records)) or not Erased(Work.Files[K].Records[J]) then Continue; end;
      if AnrRef >= 0 then if Ref[AnrRef].TemplateTag = $A8 then begin K := FileIndex(AnrRef);
        if (J >= Length(Work.Files[K].Records)) or not Erased(Work.Files[K].Records[J]) then Continue; end;
      if (J >= 254) and ((EmailRef >= 0) or (AnrRef >= 0)) then Continue;
      Slot := J; Break;
    end;
    if Slot < 0 then Invalid;
    if (AContacts[I].Name = '') and (AContacts[I].Number = '') then Invalid;
    Number := AContacts[I].Number; if Length(Number) > 5101 then Invalid; Part := Number; if (Length(Part) > 0) and (Part[1] = '+') then Delete(Part, 1, 1); if Pos('+', Part) > 0 then Invalid;
    Last := -1; Next := $FF; Offset := 20;
    while Offset < Length(Part) do
    begin
      if ExtRef < 0 then Invalid; K := FileIndex(ExtRef); N := Allocate(K);
      if Length(Work.Files[K].Records[N]) <> 13 then Invalid;
      AdnBytes := TSimCodec.EncodeAdn('', Copy(Part, Offset + 1, 20), 14);
      SetLength(Data, 13); FillChar(Data[0], 13, $FF); Data[0] := 2; Data[1] := AdnBytes[0] - 1; Move(AdnBytes[2], Data[2], 10);
      if Last >= 0 then begin Result.Changes[Last].Data[12] := N + 1;
        Work.Files[K].Records[Result.Changes[Last].RecordNumber - 1][12] := N + 1; end
      else Next := N + 1;
      Last := Length(Result.Changes); Change(K, N, Data); Inc(Offset, 20);
    end;
    Number := Copy(Part, 1, 20); if (Length(AContacts[I].Number) > 0) and (AContacts[I].Number[1] = '+') then Number := '+' + Number;
    AdnBytes := TSimCodec.EncodeAdn(AContacts[I].Name, Number, Length(Work.Files[0].Records[Slot])); AdnBytes[High(AdnBytes)] := Next;
    IapData := nil; if IapRef >= 0 then IapData := CopyBytes(Work.Files[FileIndex(IapRef)].Records[Slot]);
    WriteField(EmailRef, AContacts[I].Email, False); WriteField(AnrRef, AContacts[I].AdditionalNumber, True);
    if IapRef >= 0 then if not BytesEqual(IapData, Work.Files[FileIndex(IapRef)].Records[Slot]) then Change(FileIndex(IapRef), Slot, IapData);
    Change(0, Slot, AdnBytes);
  end;
  Validate(Work); ValidatePlan(Result);
end;
class function TSimWorkflowCodec.ImportSms(const ATarget: TSimWorkflowSnapshot;
  const ARecords: TSimRecords): TSimWorkflowPlan;
var I, N: Integer; Sms: TSimSmsRecord;
begin
  Validate(ATarget); if (ATarget.Kind <> swkSms) or (Length(ARecords) < 1) or (Length(ARecords) > 255) then Invalid;
  Result := NewPlan(ATarget); N := 0;
  for I := 0 to High(ARecords) do
  begin
    Sms := TSimCodec.DecodeSms(ARecords[I]); if Sms.State in [sssFree, sssUnknown] then Invalid;
    while N < Length(ATarget.Files[0].Records) do begin Sms := TSimCodec.DecodeSms(ATarget.Files[0].Records[N]);
      if Sms.State = sssFree then Break; Inc(N); end;
    if N >= Length(ATarget.Files[0].Records) then Invalid;
    AddChange(Result, ATarget.Files[0], N, ARecords[I]); Inc(N);
  end;
  ValidatePlan(Result);
end;
class function TSimWorkflowCodec.ImportSmsGroup(const ATarget: TSimWorkflowSnapshot;
  const ARecords: TSimRecords): TSimWorkflowPlan;
var Joined: TSimAssembledSms;
begin Joined := TSimCodec.AssembleSms(ARecords); if Length(Joined.Segments) <> Length(ARecords) then Invalid;
  Result := ImportSms(ATarget, ARecords); end;
function AddressText(const A: TSimFileAddress): string;
var I: Integer;
begin Result := IntToStr(Ord(A.Root)) + '|'; for I := 0 to High(A.Path) do begin if I > 0 then Result := Result + ',';
  Result := Result + IntToHex(A.Path[I], 4); end; end;
function TokenBytes(const B: TBytes): string;
begin Result := BytesToHex(B); if Result = '' then Result := '-'; end;
function Header(const K: TSimWorkflowKind; const P: TSimCardProfile; const A: TBytes; const C: UnicodeString): string;
begin Result := IntToStr(Ord(K)) + '|' + IntToStr(Ord(P)) + '|' + TokenBytes(A) + '|' + string(C); end;
class function TSimWorkflowCodec.EncodeSnapshot(const ASnapshot: TSimWorkflowSnapshot): string;
var I, J: Integer;
begin Validate(ASnapshot); Result := 'ERD-SIM-SNAPSHOT 1' + #13#10 +
  Header(ASnapshot.Kind, ASnapshot.Profile, ASnapshot.ApplicationAid, ASnapshot.Iccid) + '|' + IntToStr(ASnapshot.PbrRecord) + #13#10;
  for I := 0 to High(ASnapshot.Files) do begin Result := Result + 'F|' + AddressText(ASnapshot.Files[I].Address) + '|' +
    IntToStr(Length(ASnapshot.Files[I].Records)) + #13#10;
    for J := 0 to High(ASnapshot.Files[I].Records) do Result := Result + 'R|' + BytesToHex(ASnapshot.Files[I].Records[J]) + #13#10;
  end;
end;
class function TSimWorkflowCodec.EncodePlan(const APlan: TSimWorkflowPlan): string;
var I: Integer;
begin ValidatePlan(APlan); Result := 'ERD-SIM-PLAN 1' + #13#10 + Header(APlan.Kind, APlan.Profile, APlan.ApplicationAid, APlan.Iccid) + #13#10;
  for I := 0 to High(APlan.Changes) do Result := Result + AddressText(APlan.Changes[I].FileAddress) + '|' +
    IntToStr(APlan.Changes[I].RecordNumber) + '|' + BytesToHex(APlan.Changes[I].ExpectedBefore) + '|' + BytesToHex(APlan.Changes[I].Data) + #13#10;
end;
procedure Split(const S: string; const Count: Integer; const L: TStringList);
begin L.StrictDelimiter := True; L.Delimiter := '|'; L.QuoteChar := #0; L.DelimitedText := S; if L.Count <> Count then Invalid; end;
function Decimal(const S: string): Integer;
var I: Integer;
begin if S = '' then Invalid; for I := 1 to Length(S) do if not CharInSet(S[I], ['0' .. '9']) then Invalid;
  if not TryStrToInt(S, Result) then Invalid; end;
function DecodeBytes(const S: string): TBytes;
var I: Integer;
begin Result := nil; if S = '-' then Exit; if (Length(S) = 0) or (Length(S) mod 2 <> 0) then Invalid;
  for I := 1 to Length(S) do if not CharInSet(S[I], ['0' .. '9', 'A' .. 'F']) then Invalid;
  Result := HexToBytes(S); end;
function DecodeAddress(const Root, Path: string): TSimFileAddress;
var L: TStringList; I, N: Integer;
begin N := Decimal(Root); if not (N in [0 .. 1]) then Invalid;
  L := TStringList.Create; try L.StrictDelimiter := True; L.Delimiter := ','; L.QuoteChar := #0; L.DelimitedText := Path;
    if (L.Count < 1) or (L.Count > 8) then Invalid; Result.Root := TSimFileRoot(N); SetLength(Result.Path, L.Count);
    for I := 0 to L.Count - 1 do begin if Length(DecodeBytes(L[I])) <> 2 then Invalid;
      N := StrToInt('$' + L[I]); Result.Path[I] := N; end; AddressValid(Result);
  finally L.Free; end;
end;
procedure TextValid(const S: string; const Max: Integer);
var I: Integer;
begin if (Length(S) > Max) or (S = '') then Invalid;
  for I := 1 to Length(S) do if Ord(S[I]) > 127 then Invalid; end;
class function TSimWorkflowCodec.DecodeSnapshot(const AText: string): TSimWorkflowSnapshot;
var L, F: TStringList; I, J, K, N: Integer;
begin
  Result := Default(TSimWorkflowSnapshot); TextValid(AText, 5 * 1024 * 1024);
  L := TStringList.Create; F := TStringList.Create;
  try
    L.Text := AText; if (L.Count < 3) or (L[0] <> 'ERD-SIM-SNAPSHOT 1') then Invalid;
    Split(L[1], 5, F); K := Decimal(F[0]); N := Decimal(F[1]); if not (K in [0 .. 1]) or not (N in [0 .. 1]) then Invalid;
    Result.Kind := TSimWorkflowKind(K); Result.Profile := TSimCardProfile(N); Result.ApplicationAid := DecodeBytes(F[2]);
    Result.Iccid := UnicodeString(F[3]); Result.PbrRecord := Decimal(F[4]); I := 2;
    while I < L.Count do
    begin
      Split(L[I], 4, F); if F[0] <> 'F' then Invalid; K := Length(Result.Files); if K >= 32 then Invalid;
      SetLength(Result.Files, K + 1); Result.Files[K].Address := DecodeAddress(F[1], F[2]);
      N := Decimal(F[3]); if (N < 1) or (N > 255) or (N > L.Count - I - 1) then Invalid;
      SetLength(Result.Files[K].Records, N); Inc(I);
      for J := 0 to N - 1 do begin Split(L[I], 2, F); if F[0] <> 'R' then Invalid;
        if Length(F[1]) > 510 then Invalid; Result.Files[K].Records[J] := DecodeBytes(F[1]); Inc(I); end;
    end;
    Validate(Result); if EncodeSnapshot(Result) <> AText then Invalid;
  finally F.Free; L.Free; end;
end;
class function TSimWorkflowCodec.DecodePlan(const AText: string): TSimWorkflowPlan;
var L, F: TStringList; I, K, N: Integer;
begin
  Result := Default(TSimWorkflowPlan); TextValid(AText, 10 * 1024 * 1024);
  L := TStringList.Create; F := TStringList.Create;
  try
    L.Text := AText; if (L.Count < 2) or (L.Count > 8194) or (L[0] <> 'ERD-SIM-PLAN 1') then Invalid;
    Split(L[1], 4, F); K := Decimal(F[0]); N := Decimal(F[1]); if not (K in [0 .. 1]) or not (N in [0 .. 1]) then Invalid;
    Result.Kind := TSimWorkflowKind(K); Result.Profile := TSimCardProfile(N); Result.ApplicationAid := DecodeBytes(F[2]);
    Result.Iccid := UnicodeString(F[3]); SetLength(Result.Changes, L.Count - 2);
    for I := 2 to L.Count - 1 do
    begin Split(L[I], 5, F); K := I - 2; Result.Changes[K].FileAddress := DecodeAddress(F[0], F[1]);
      Result.Changes[K].RecordNumber := Decimal(F[2]); if (Length(F[3]) > 510) or (Length(F[4]) > 510) then Invalid;
      Result.Changes[K].ExpectedBefore := DecodeBytes(F[3]); Result.Changes[K].Data := DecodeBytes(F[4]); end;
    ValidatePlan(Result); if EncodePlan(Result) <> AText then Invalid;
  finally F.Free; L.Free; end;
end;
function SmsStateText(const State: TSimSmsState): string;
begin case State of
  sssFree: Result := 'Free'; sssReceivedRead: Result := 'Received, read';
  sssReceivedUnread: Result := 'Received, unread'; sssUnsent: Result := 'Outgoing, unsent';
  sssSent: Result := 'Sent'; else Result := 'Unknown stored status'; end;
end;
class function TSimWorkflowCodec.Report(const ASnapshot: TSimWorkflowSnapshot): UnicodeString;
var I, J, Used: Integer; Contact: TSimPhonebookEntry; Linked: TSimLinkedContact; Ref: TSimPhonebookReferences;
  Files: TSimPhonebookFiles; Sms: TSimSmsRecord; Message: TSimSmsMessage; V: UnicodeString;
begin
  Validate(ASnapshot); Result := 'ICCID ' + ASnapshot.Iccid + #13#10; Used := 0; Ref := nil; Files := nil;
  if Length(ASnapshot.Files) > 1 then begin Ref := References(ASnapshot); Files := PhoneFiles(ASnapshot); end;
  for I := 0 to High(ASnapshot.Files[0].Records) do
  begin
    if ASnapshot.Kind = swkPhonebook then
    begin
      Contact := TSimCodec.DecodeAdn(ASnapshot.Files[0].Records[I]); if Contact.Empty then Continue; Inc(Used);
      if Length(ASnapshot.Files) > 1 then begin Linked := TSimCodec.ResolvePhonebookContact(Ref, Files, Files[0].FileId, I + 1); Contact := Linked.Contact; end;
      Result := Result + UnicodeString('Contact ' + IntToStr(I + 1) + ': ') + Contact.Name + ' / ' + Contact.Number + #13#10;
      if ASnapshot.PbrRecord > 0 then for J := 0 to High(Linked.Fields) do
      begin
        V := UnicodeString(BytesToHex(Linked.Fields[J].Raw));
        try case Linked.Fields[J].Reference.RoleTag of
          $CA: V := TSimCodec.DecodePhonebookEmail(Linked.Fields[J].Raw, Linked.Fields[J].Reference.TemplateTag = $A9);
          $C4: begin Contact := TSimCodec.DecodePhonebookAnr(Linked.Fields[J].Raw, Linked.Fields[J].Reference.TemplateTag = $A9); V := Contact.Number; end;
        end; except on E: ESimCardError do V := 'Unsupported field layout; raw ' + V; end;
        Result := Result + UnicodeString('  Role ' + IntToHex(Linked.Fields[J].Reference.RoleTag, 2) +
          ' record ' + IntToStr(Linked.Fields[J].RecordNumber) + ': ') + V + #13#10;
      end;
    end
    else
    begin
      Sms := TSimCodec.DecodeSms(ASnapshot.Files[0].Records[I]); if Sms.State = sssFree then Continue; Inc(Used);
      Result := Result + UnicodeString('SMS record ' + IntToStr(I + 1) + ', ' + SmsStateText(Sms.State) + ' (status ' + IntToHex(Sms.StatusByte, 2) + '): ');
      try
        Message := TSimCodec.DecodeSmsMessage(ASnapshot.Files[0].Records[I]); Result := Result + Message.Address + ' ';
        if Message.Concatenated then Result := Result + UnicodeString('segment ' + IntToStr(Message.SegmentNumber) + '/' + IntToStr(Message.SegmentCount) +
          ', reference ' + IntToStr(Message.ConcatenationReference) + ' ');
        if Message.TextDecoded then Result := Result + Message.Text else Result := Result + UnicodeString(BytesToHex(Message.UserData));
      except on E: ESimCardError do Result := Result + 'Unsupported TPDU; raw ' + UnicodeString(BytesToHex(ASnapshot.Files[0].Records[I])); end;
      Result := Result + #13#10;
    end;
  end;
  Result := Result + UnicodeString('Capacity ' + IntToStr(Length(ASnapshot.Files[0].Records)) + ', used ' + IntToStr(Used) +
    ', free ' + IntToStr(Length(ASnapshot.Files[0].Records) - Used) + #13#10);
end;
constructor TSimWorkflowCard.Create(const AReader: TSimCardReaderWriter);
begin inherited Create; if (AReader = nil) or AReader.Busy then Invalid;
  FReader := TSimCardReaderWriter.Create(nil);
  FReader.Profile := AReader.Profile; FReader.ApplicationAid := AReader.ApplicationAid; FReader.PinReference := AReader.PinReference;
  FReader.MinimumPinAttempts := AReader.MinimumPinAttempts; FReader.Transport := AReader.Transport;
end;
destructor TSimWorkflowCard.Destroy;
begin FReader.Free; inherited Destroy; end;
function TSimWorkflowCard.Profile: TSimCardProfile;
begin Result := FReader.Profile; end;
function TSimWorkflowCard.ApplicationAid: TBytes;
begin Result := FReader.ApplicationAid; end;
function TSimWorkflowCard.Identity: UnicodeString;
begin Result := FReader.ReadIccid; end;
procedure TSimWorkflowCard.Authenticate(const APin: TBytes);
var S: TSimPinStatus;
begin if Length(APin) = 0 then Exit; S := FReader.GetPinStatus;
  if not S.Disabled and not (S.VerificationKnown and S.Verified) then FReader.VerifyPin(APin); end;
function TSimWorkflowCard.ReadRecords(const AFile: TSimFileAddress): TSimRecords;
var Info: TSimFileInfo;
begin Info := FReader.InspectFile(AFile); if Info.Structure <> sfsLinearFixed then Invalid;
  Result := FReader.ReadRecords(AFile); if Length(Result) <> Info.RecordCount then Invalid; end;
procedure TSimWorkflowCard.Apply(const APlan: TSimWorkflowPlan; out AResults: TSimRecordWriteResults);
begin FReader.WriteRecordPlan(APlan.Changes, APlan.Iccid, nil, AResults); end;
procedure TSimRecordWorkflow.Initialize(const ACard: ISimWorkflowCard; const APin: TBytes);
var I: Integer;
begin RequireIdle; if ACard = nil then Invalid;
  if Length(APin) > 0 then begin if (Length(APin) < 4) or (Length(APin) > 8) then Invalid;
    for I := 0 to High(APin) do if not (APin[I] in [Ord('0') .. Ord('9')]) then Invalid; end;
  ProfileValid(ACard.Profile, ACard.ApplicationAid);
  TCardCrypto.Clear(FPin); FPin := CopyBytes(APin); FCard := ACard;
  FPrepared := False; FConsumed := False; FIncludeClassicExt := False; FResults := nil;
end;
procedure TSimRecordWorkflow.PrepareBackup(const ACard: ISimWorkflowCard; const AFile: TSimFileAddress;
  const APbrRecord: Integer; const APin: TBytes);
begin RequireIdle; AddressValid(AFile);
  if (APbrRecord < 0) or (APbrRecord > 255) or ((Kind = swkSms) and (APbrRecord <> 0)) then Invalid;
  if (APbrRecord > 0) and ((ACard = nil) or (AFile.Root <> sfrUsimApplication) or
    (Length(AFile.Path) <> 2) or (AFile.Path[0] <> $5F3A)) then Invalid;
  Initialize(ACard, APin); FFile := CopyAddress(AFile); FPbrRecord := APbrRecord;
  FSnapshot := Default(TSimWorkflowSnapshot); FPlan := Default(TSimWorkflowPlan); FAction := 0; FPrepared := True;
end;
procedure TSimRecordWorkflow.PreparePreview(const ACard: ISimWorkflowCard; const ASnapshot: TSimWorkflowSnapshot; const APin: TBytes);
begin RequireIdle; TSimWorkflowCodec.Validate(ASnapshot); if ASnapshot.Kind <> Kind then Invalid;
  Initialize(ACard, APin); FSnapshot := TSimWorkflowCodec.DecodeSnapshot(TSimWorkflowCodec.EncodeSnapshot(ASnapshot));
  FFile := CopyAddress(FSnapshot.Files[0].Address); FPbrRecord := FSnapshot.PbrRecord;
  FPlan := Default(TSimWorkflowPlan); FAction := 1; FPrepared := True;
end;
procedure TSimRecordWorkflow.PrepareApply(const ACard: ISimWorkflowCard; const APlan: TSimWorkflowPlan; const APin: TBytes);
begin RequireIdle; TSimWorkflowCodec.ValidatePlan(APlan); if APlan.Kind <> Kind then Invalid;
  Initialize(ACard, APin); FPlan := TSimWorkflowCodec.DecodePlan(TSimWorkflowCodec.EncodePlan(APlan));
  FSnapshot := Default(TSimWorkflowSnapshot); FAction := 2; FPrepared := True;
end;
procedure TSimRecordWorkflow.ValidatePrepared;
begin if not FPrepared or FConsumed or (FCard = nil) then Invalid; end;
destructor TSimRecordWorkflow.Destroy;
begin TCardCrypto.Clear(FPin); inherited Destroy; end;
function TSimRecordWorkflow.GetSnapshot: TSimWorkflowSnapshot;
begin Result := Default(TSimWorkflowSnapshot); if Length(FSnapshot.Files) > 0 then
  Result := TSimWorkflowCodec.DecodeSnapshot(TSimWorkflowCodec.EncodeSnapshot(FSnapshot)); end;
function TSimRecordWorkflow.GetPlan: TSimWorkflowPlan;
begin Result := Default(TSimWorkflowPlan); if FPlan.Iccid <> '' then
  Result := TSimWorkflowCodec.DecodePlan(TSimWorkflowCodec.EncodePlan(FPlan)); end;
function TSimRecordWorkflow.GetResults: TSimWorkflowResults;
var I: Integer;
begin Result := nil; SetLength(Result, Length(FResults)); for I := 0 to High(Result) do
  begin Result[I] := FResults[I]; Result[I].Address := CopyAddress(FResults[I].Address); end; end;
function TSimRecordWorkflow.Capture: TSimWorkflowSnapshot;
var Pbr: TSimRecords; Ref: TSimPhonebookReferences; I, J, K: Integer; A: TSimFileAddress; Contact: TSimPhonebookEntry; NeedExt: Boolean;
begin
  Result := Default(TSimWorkflowSnapshot); Result.Kind := Kind; Result.Profile := FCard.Profile;
  Result.ApplicationAid := FCard.ApplicationAid; Result.Iccid := FCard.Identity; Result.PbrRecord := FPbrRecord;
  SetLength(Result.Files, 1); Result.Files[0].Address := CopyAddress(FFile);
  Result.Files[0].Records := FCard.ReadRecords(FFile); Progress(cwsReading, 1, 1);
  if CancelRequested then Exit;
  if FPbrRecord > 0 then
  begin
    A := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, $4F30]); Pbr := FCard.ReadRecords(A);
    if FPbrRecord > Length(Pbr) then Invalid;
    Ref := TSimCodec.DecodePhonebookReferences(Pbr[FPbrRecord - 1]); SetLength(Result.Files, 2);
    Result.Files[1].Address := A; Result.Files[1].Records := Pbr;
    for I := 0 to High(Ref) do
    begin
      if CancelRequested then Exit;
      A := TSimCodec.FileAddress(sfrUsimApplication, [$5F3A, Ref[I].FileId]); K := -1;
      for J := 0 to High(Result.Files) do if AddressEqual(A, Result.Files[J].Address) then K := J;
      if K >= 0 then Continue; K := Length(Result.Files); if K >= 32 then Invalid;
      SetLength(Result.Files, K + 1); Result.Files[K].Address := A; Result.Files[K].Records := FCard.ReadRecords(A);
      Progress(cwsReading, I + 1, Length(Ref));
    end;
  end;
  if (Kind = swkPhonebook) and (FPbrRecord = 0) and (Result.Profile = scpGsmSim) and
    AddressEqual(FFile, TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F3A])) then
  begin
    NeedExt := FIncludeClassicExt or ((FAction = 1) and (Length(FSnapshot.Files) = 2));
    for I := 0 to High(Result.Files[0].Records) do begin Contact := TSimCodec.DecodeAdn(Result.Files[0].Records[I]);
      if not Contact.Empty and (Contact.ExtensionRecord <> $FF) then NeedExt := True; end;
    if NeedExt then begin SetLength(Result.Files, 2); Result.Files[1].Address := TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F4A]);
      Result.Files[1].Records := FCard.ReadRecords(Result.Files[1].Address); end;
  end;
  if Result.Iccid <> FCard.Identity then Invalid; TSimWorkflowCodec.Validate(Result);
end;
procedure TSimRecordWorkflow.DoExecute;
var Current: TSimWorkflowSnapshot; Evidence: TSimRecordWriteResults; I: Integer;
begin
  FConsumed := True; Evidence := nil;
  try
    if FAction = 0 then begin if not RequestCard(cwrSource) then begin Cancel; Exit; end; end
    else if not RequestCard(cwrTarget) then begin Cancel; Exit; end;
    Progress(cwsChecking, 0, 1); if CancelRequested then Exit;
    if FAction = 1 then begin if (FCard.Profile <> FSnapshot.Profile) or not BytesEqual(FCard.ApplicationAid, FSnapshot.ApplicationAid) then Invalid; end;
    if FAction = 2 then begin if (FCard.Profile <> FPlan.Profile) or not BytesEqual(FCard.ApplicationAid, FPlan.ApplicationAid) or
      (FCard.Identity <> FPlan.Iccid) then Invalid; end;
    if (FAction = 2) and (Length(FPlan.Changes) = 0) then Exit;
    FCard.Authenticate(FPin); TCardCrypto.Clear(FPin); if CancelRequested then Exit;
    if FAction <> 2 then
    begin
      Progress(cwsReading, 0, 1); if CancelRequested then Exit;
      Current := Capture; if CancelRequested then Exit;
      if FAction = 0 then FSnapshot := Current else FPlan := TSimWorkflowCodec.RestorePlan(FSnapshot, Current);
      Exit;
    end;
    SetLength(FResults, Length(FPlan.Changes));
    for I := 0 to High(FResults) do begin FResults[I].Address := CopyAddress(FPlan.Changes[I].FileAddress);
      FResults[I].RecordNumber := FPlan.Changes[I].RecordNumber; FResults[I].State := cwusPending;
      if BytesEqual(FPlan.Changes[I].ExpectedBefore, FPlan.Changes[I].Data) then FResults[I].State := cwusUnchanged; end;
    if Length(FPlan.Changes) = 0 then Exit;
    Progress(cwsWriting, 0, Length(FResults)); if CancelRequested then Exit;
    MutationPending(True);
    try
      FCard.Apply(FPlan, Evidence);
      if Length(Evidence) <> Length(FResults) then begin
        for I := 0 to High(FResults) do FResults[I].State := cwusUncertain;
        raise ESimCardWriteUncertain.Create('MissingEvidence', False); end;
      for I := 0 to High(Evidence) do if not Evidence[I].Verified then begin
        FResults[I].State := cwusUncertain;
        raise ESimCardWriteUncertain.Create('IncompleteEvidence', False); end;
      MutationPending(False);
    except
      on E: ESimCardWriteUncertain do begin
        for I := Length(Evidence) to High(FResults) do FResults[I].State := cwusUncertain;
        raise; end;
      on E: Exception do begin MutationPending(False); raise; end;
    end;
    Progress(cwsVerifying, Length(FResults), Length(FResults));
  finally
    for I := 0 to High(FResults) do if I < Length(Evidence) then
      if Evidence[I].Verified then FResults[I].State := cwusVerified
      else if Evidence[I].Dispatched then FResults[I].State := cwusUncertain;
    TCardCrypto.Clear(FPin);
  end;
end;
procedure TSimPhonebookWorkflow.PrepareClassicBackup(const ACard: ISimWorkflowCard; const APin: TBytes);
begin RequireIdle; if (ACard = nil) or (ACard.Profile <> scpGsmSim) then Invalid;
  PrepareBackup(ACard, TSimCodec.FileAddress(sfrMasterFile, [$7F10, $6F3A]), 0, APin); FIncludeClassicExt := True; end;
function TSimPhonebookWorkflow.Kind: TSimWorkflowKind;
begin Result := swkPhonebook; end;
function TSimSmsWorkflow.Kind: TSimWorkflowKind;
begin Result := swkSms; end;

end.
