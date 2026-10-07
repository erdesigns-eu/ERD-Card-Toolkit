unit ERD.Card.Contactless.UID.USCUID;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils,
{$ELSE}
  System.SysUtils,
{$ENDIF}
  ERD.Card.Contactless.UID;

type
  /// <summary>Caller-identified enabled USCUID/GDM volatile wakeup dialect; no automatic probing.</summary>
  TUscuidWakeupStyle = (
    /// <summary>Seven-bit 40 followed by eight-bit 43; configuration byte two must be 00.</summary>
    uwsGen1a,
    /// <summary>Seven-bit 20 followed by eight-bit 23; configuration byte two must be 85.</summary>
    uwsGdm
  );
  /// <summary>Already configured USCUID/GDM UID source; no personalization or configuration changes.</summary>
  TUscuidUidLayout = (
    /// <summary>Four UID bytes and BCC in public manufacturer block zero; configuration mode 00/FF.</summary>
    uulPublic4,
    /// <summary>Four UID bytes and BCC in hidden block one; configuration personalization mode 69.</summary>
    uulHiddenF3_4,
    /// <summary>Seven cascaded UID bytes in hidden block zero; existing personalization mode 5A/C3/A5.</summary>
    uulHiddenF0F1_7
  );
  /// <summary>Completed USCUID/GDM UID programming with preserved configuration, full blocks and fresh selection.</summary>
  /// <remarks>Independent buffers on return; ordinary record assignment shares arrays.</remarks>
  TUscuidUidResult = record
    /// <summary>Explicit volatile wakeup style.</summary>
    WakeupStyle: TUscuidWakeupStyle;
    /// <summary>Existing configured UID source.</summary>
    Layout: TUscuidUidLayout;
    /// <summary>Independent original freshly selected UID verified against its configured source.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent sixteen-byte configuration verified unchanged; never contains sector keys.</summary>
    Configuration: TBytes;
    /// <summary>Independent full public manufacturer block; unchanged for hidden F3 mode.</summary>
    PublicManufacturerBlock: TBytes;
    /// <summary>Independent full hidden manufacturer block, or empty for public-only mode.</summary>
    HiddenManufacturerBlock: TBytes;
    /// <summary>True on every returned result: fresh selection or a verified no-op reports RequestedUid.</summary>
    ActiveUidVerified: Boolean;
  end;
  /// <summary>Stateless explicit USCUID/GDM configuration and public/hidden UID layouts.</summary>
  TUscuidUidCodec = class
  public
    /// <summary>Returns the UID length for a configured source.</summary>
    /// <param name="ALayout">Public/hidden four-byte or hidden seven-byte layout.</param>
    /// <returns>Four or seven bytes.</returns>
    /// <exception cref="EProgrammableUidError">Layout is invalid.</exception>
    class function UidLength(const ALayout: TUscuidUidLayout): Integer; static;
    /// <summary>Returns the hidden block holding the UID, if applicable.</summary>
    /// <param name="ALayout">Configured source.</param>
    /// <returns>Minus one for public mode, one for F3, zero for F0/F1.</returns>
    /// <exception cref="EProgrammableUidError">Layout is invalid.</exception>
    class function HiddenBlockIndex(const ALayout: TUscuidUidLayout): Integer; static;
    /// <summary>Checks requested size and ISO 14443-A cascade position.</summary>
    /// <param name="ALayout">Explicit existing source.</param>
    /// <param name="AUid">Caller-owned target UID; never modified.</param>
    /// <exception cref="EProgrammableUidError">Layout, UID length or cascade position is invalid.</exception>
    class procedure ValidateUid(const ALayout: TUscuidUidLayout; const AUid: TBytes); static;
    /// <summary>Requires enabled matching wakeup, disabled shadow mode and the existing selected UID source.</summary>
    /// <param name="AStyle">Explicit Gen1a or GDM wakeup.</param>
    /// <param name="ALayout">Existing public/F3/F0-F1 source.</param>
    /// <param name="AConfiguration">Exactly sixteen bytes from E0 00, without RF CRC; never modified or retained.</param>
    /// <exception cref="EProgrammableUidError">Format, wakeup enable/style, shadow or personalization mode is unsupported.</exception>
    /// <remarks>Does not enable wakeup, change personalization, configure keys or issue a fuse command.</remarks>
    class procedure ValidateConfiguration(const AStyle: TUscuidWakeupStyle; const ALayout: TUscuidUidLayout;
      const AConfiguration: TBytes); static;
    /// <summary>Validates the active source block and copies its UID.</summary>
    /// <param name="ALayout">Existing configured source.</param>
    /// <param name="ABlock">Exactly sixteen bytes from the selected public or hidden block.</param>
    /// <returns>Independent UID after BCC, cascade-tag and hidden SAK-cascade checks.</returns>
    /// <exception cref="EProgrammableUidError">Layout, block, BCC, cascade framing or UID is invalid.</exception>
    class function DecodeUid(const ALayout: TUscuidUidLayout; const ABlock: TBytes): TBytes; static;
    /// <summary>Replaces UID/BCC bytes in the active source while preserving all other bytes.</summary>
    /// <param name="ALayout">Explicit existing public/hidden source.</param>
    /// <param name="ABlock">Original valid sixteen-byte source block.</param>
    /// <param name="ANewUid">Validated target UID; never modified.</param>
    /// <returns>Independent source block retaining SAK, ATQA and hidden metadata.</returns>
    /// <exception cref="EProgrammableUidError">Layout, original block or target UID is invalid.</exception>
    class function PrepareSourceBlock(const ALayout: TUscuidUidLayout; const ABlock, ANewUid: TBytes): TBytes; static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Invalid;
begin
  raise EProgrammableUidError.Create('Invalid or unsupported USCUID profile data.');
end;

class function TUscuidUidCodec.UidLength(const ALayout: TUscuidUidLayout): Integer;
begin
  case ALayout of
    uulPublic4, uulHiddenF3_4: Result := 4;
    uulHiddenF0F1_7: Result := 7;
  else Invalid; Result := 0; end;
end;

class function TUscuidUidCodec.HiddenBlockIndex(const ALayout: TUscuidUidLayout): Integer;
begin
  case ALayout of
    uulPublic4: Result := -1;
    uulHiddenF3_4: Result := 1;
    uulHiddenF0F1_7: Result := 0;
  else Invalid; Result := -1; end;
end;

class procedure TUscuidUidCodec.ValidateUid(const ALayout: TUscuidUidLayout; const AUid: TBytes);
begin
  if UidLength(ALayout) = 4 then TProgrammableUidCodec.ValidateUid(cgum4Byte, AUid)
  else TProgrammableUidCodec.ValidateUid(cgum7Byte, AUid);
end;

class procedure TUscuidUidCodec.ValidateConfiguration(const AStyle: TUscuidWakeupStyle;
  const ALayout: TUscuidUidLayout; const AConfiguration: TBytes);
var StyleByte: Byte; Size: Integer;
begin
  case AStyle of
    uwsGen1a: StyleByte := 0;
    uwsGdm: StyleByte := $85;
  else Invalid; StyleByte := 0; end;
  Size := UidLength(ALayout);
  if (Size = 0) or (Length(AConfiguration) <> 16) then Invalid;
  if (AConfiguration[0] <> $7A) or (AConfiguration[1] <> $FF) or
    (AConfiguration[2] <> StyleByte) or (AConfiguration[10] <> 0) then Invalid;
  case ALayout of
    uulPublic4: if not (AConfiguration[9] in [0, $FF]) then Invalid;
    uulHiddenF3_4: if AConfiguration[9] <> $69 then Invalid;
    uulHiddenF0F1_7: if not (AConfiguration[9] in [$5A, $C3, $A5]) then Invalid;
  end;
end;

class function TUscuidUidCodec.DecodeUid(const ALayout: TUscuidUidLayout; const ABlock: TBytes): TBytes;
begin
  Result := nil;
  if Length(ABlock) <> 16 then Invalid;
  if UidLength(ALayout) = 4 then
  begin
    Result := TProgrammableUidCodec.DecodeGen2Uid(cgum4Byte, ABlock);
    if (ALayout = uulHiddenF3_4) and ((ABlock[5] and $04) <> 0) then Invalid;
  end
  else
  begin
    if (ABlock[0] <> $88) or ((ABlock[0] xor ABlock[1] xor ABlock[2] xor ABlock[3]) <> ABlock[4]) or
      ((ABlock[6] xor ABlock[7] xor ABlock[8] xor ABlock[9]) <> ABlock[10]) or
      ((ABlock[5] and $04) = 0) or ((ABlock[11] and $04) <> 0) then Invalid;
    SetLength(Result, 7);
    Move(ABlock[1], Result[0], 3);
    Move(ABlock[6], Result[3], 4);
  end;
  ValidateUid(ALayout, Result);
end;

class function TUscuidUidCodec.PrepareSourceBlock(const ALayout: TUscuidUidLayout;
  const ABlock, ANewUid: TBytes): TBytes;
var OldUid: TBytes;
begin
  ValidateUid(ALayout, ANewUid);
  OldUid := DecodeUid(ALayout, ABlock);
  if Length(OldUid) = 4 then Result := TProgrammableUidCodec.PrepareGen2Block(cgum4Byte, ABlock, ANewUid)
  else
  begin
    Result := CopyBytes(ABlock);
    Move(ANewUid[0], Result[1], 3);
    Result[4] := $88 xor ANewUid[0] xor ANewUid[1] xor ANewUid[2];
    Move(ANewUid[3], Result[6], 4);
    Result[10] := ANewUid[3] xor ANewUid[4] xor ANewUid[5] xor ANewUid[6];
  end;
end;

end.
