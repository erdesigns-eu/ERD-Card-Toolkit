unit ERD.Card.Contactless.UID.Profiles;

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
  /// <summary>Caller-identified Gen3 UID-register size, independent of manufacturer block zero.</summary>
  TGen3UidSize = (
    /// <summary>Four-byte Gen3 UID register.</summary>
    g3us4Byte,
    /// <summary>Seven-byte Gen3 UID register.</summary>
    g3us7Byte);

  /// <summary>Completed Gen3 UID-register programming with unchanged manufacturer block and fresh RF verification.</summary>
  /// <remarks>Buffers are independent on return; ordinary record assignment shares arrays.</remarks>
  TGen3UidResult = record
    /// <summary>Explicit selected UID-register size.</summary>
    UidSize: TGen3UidSize;
    /// <summary>Independent original freshly selected UID; need not equal the UID embedded in block zero.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent sixteen-byte manufacturer block verified unchanged after programming.</summary>
    ManufacturerBlock: TBytes;
    /// <summary>True on every returned result: fresh selection or a verified no-op reports RequestedUid.</summary>
    ActiveUidVerified: Boolean;
  end;

  /// <summary>Existing Gen4 UMC Type A emulation layout; UID size and protocol are not reconfigured.</summary>
  TGen4UidLayout = (
    /// <summary>Classic mode: four contiguous UID bytes and a stored BCC at byte four.</summary>
    g4ulClassic4,
    /// <summary>Classic mode: seven contiguous UID bytes; metadata begins at byte seven.</summary>
    g4ulClassic7,
    /// <summary>Classic mode: ten contiguous UID bytes; metadata begins at byte ten.</summary>
    g4ulClassic10,
    /// <summary>Type 2 mode: four contiguous UID bytes in backdoor block zero.</summary>
    g4ulType2_4,
    /// <summary>Type 2 mode: seven UID bytes split over backdoor blocks zero/one, with BCCs in blocks zero/two.</summary>
    g4ulType2_7,
    /// <summary>Type 2 mode: ten contiguous UID bytes in backdoor block zero.</summary>
    g4ulType2_10);
  /// <summary>Ordered independently copied sixteen-byte manufacturer blocks; ordinary array assignment shares elements.</summary>
  TUidManufacturerBlocks = array of TBytes;

  /// <summary>Completed Gen4 UMC UID programming, preserved configuration and fresh RF verification.</summary>
  /// <remarks>No password or configuration response is retained in the result. Ordinary record assignment shares arrays.</remarks>
  TGen4UidResult = record
    /// <summary>Caller-selected existing emulation layout.</summary>
    Layout: TGen4UidLayout;
    /// <summary>Independent original selected UID verified against manufacturer blocks.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent full blocks zero..two for Type 2 seven-byte mode, otherwise only block zero.</summary>
    ManufacturerBlocks: TUidManufacturerBlocks;
    /// <summary>True on every returned result: fresh selection or a verified no-op reports RequestedUid.</summary>
    ActiveUidVerified: Boolean;
  end;

  /// <summary>Stateless Gen3 UID-register validation and raw command framing, without I/O.</summary>
  TGen3UidCodec = class
  public
    /// <summary>Returns the explicitly selected Gen3 UID length.</summary>
    /// <param name="ASize">Four-byte or seven-byte register.</param>
    /// <returns>Four or seven bytes.</returns>
    /// <exception cref="EProgrammableUidError">Size is invalid.</exception>
    class function UidLength(const ASize: TGen3UidSize): Integer; static;
    /// <summary>Builds the Gen3 UID-only RF payload, without CRC-A.</summary>
    /// <param name="ASize">Caller-identified existing register size.</param>
    /// <param name="AUid">Exactly four or seven bytes; copied without modification.</param>
    /// <returns>Independent 90 FB CC CC 07 payload followed by UID bytes; the legacy 07 field stays fixed for both sizes.</returns>
    /// <exception cref="EProgrammableUidError">Size, UID length or cascade position is invalid.</exception>
    /// <remarks>This APDU-shaped payload is sent as raw RF, not as an ISO 7816 transport command. No block-write or freeze command.</remarks>
    class function BuildUidCommand(const ASize: TGen3UidSize;
      const AUid: TBytes): TBytes; static;
  end;

  /// <summary>Stateless Gen4 UMC manufacturer layouts and existing configuration checks.</summary>
  TGen4UidCodec = class
  public
    /// <summary>Returns the UID length of an explicit existing Gen4 layout.</summary>
    /// <param name="ALayout">Classic or Type 2 layout with four, seven or ten bytes.</param>
    /// <returns>Four, seven or ten bytes.</returns>
    /// <exception cref="EProgrammableUidError">Layout is invalid.</exception>
    class function UidLength(const ALayout: TGen4UidLayout): Integer; static;
    /// <summary>Returns the number of complete manufacturer backdoor blocks needed for a layout.</summary>
    /// <param name="ALayout">Explicit existing emulation layout.</param>
    /// <returns>Three for Type 2 seven-byte layout; one otherwise.</returns>
    /// <exception cref="EProgrammableUidError">Layout is invalid.</exception>
    class function ManufacturerBlockCount(const ALayout: TGen4UidLayout)
      : Integer; static;
    /// <summary>Validates UID length and ISO 14443-A cascade position for the chosen layout.</summary>
    /// <param name="ALayout">Explicit four, seven or ten-byte layout.</param>
    /// <param name="AUid">Caller-owned UID, never modified.</param>
    /// <exception cref="EProgrammableUidError">Layout/length is invalid, four-byte UID0 is 88, or seven/ten-byte UID3 is 88.</exception>
    class procedure ValidateUid(const ALayout: TGen4UidLayout;
      const AUid: TBytes); static;
    /// <summary>Checks an acquired Gen4 configuration against an existing layout and stable storage mode.</summary>
    /// <param name="ALayout">Caller-selected protocol and UID length.</param>
    /// <param name="AConfiguration">Exactly thirty or thirty-two bytes, excluding RF CRC; may contain password bytes.</param>
    /// <exception cref="EProgrammableUidError">Format, protocol, UID length, ATS length or GTU mode is unsupported.</exception>
    /// <remarks>Requires GTU mode 02; shadow/restore and unknown modes fail before programming. Does not retain or modify configuration.</remarks>
    class procedure ValidateConfiguration(const ALayout: TGen4UidLayout;
      const AConfiguration: TBytes); static;
    /// <summary>Validates manufacturer block sizes and copies their configured UID.</summary>
    /// <param name="ALayout">Caller-identified existing layout.</param>
    /// <param name="ABlocks">One or three complete sixteen-byte blocks according to the layout.</param>
    /// <returns>Independent UID; split Type 2 layouts also validate both stored BCC bytes.</returns>
    /// <exception cref="EProgrammableUidError">Layout, blocks, split-layout BCC or UID is invalid.</exception>
    /// <remarks>Contiguous Gen4 layouts generate RF BCC on-card; stored four-byte Classic BCC is corrected on preparation.</remarks>
    class function DecodeUid(const ALayout: TGen4UidLayout;
      const ABlocks: TUidManufacturerBlocks): TBytes; static;
    /// <summary>Replaces UID/BCC bytes while preserving all other visible and hidden manufacturer bytes.</summary>
    /// <param name="ALayout">Existing configured protocol and UID size.</param>
    /// <param name="ABlocks">Original complete blocks validated against the selected layout.</param>
    /// <param name="ANewUid">Exactly the configured number of caller-owned UID bytes.</param>
    /// <returns>Deep independent blocks; split Type 2 internal/lock bytes and every block's hidden tail are preserved.</returns>
    /// <exception cref="EProgrammableUidError">Layout, original blocks or requested UID is invalid.</exception>
    class function PrepareBlocks(const ALayout: TGen4UidLayout;
      const ABlocks: TUidManufacturerBlocks; const ANewUid: TBytes)
      : TUidManufacturerBlocks; static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Fail;
begin
  raise EProgrammableUidError.Create
    ('Invalid or unsupported programmable UID profile data.');
end;

class function TGen3UidCodec.UidLength(const ASize: TGen3UidSize): Integer;
begin
  case ASize of
    g3us4Byte:
      Result := 4;
    g3us7Byte:
      Result := 7;
  else
    Fail;
    Result := 0;
  end;
end;

class function TGen3UidCodec.BuildUidCommand(const ASize: TGen3UidSize;
  const AUid: TBytes): TBytes;
var
  Size: Integer;
begin
  Size := UidLength(ASize);
  if Size = 4 then
    TProgrammableUidCodec.ValidateUid(cgum4Byte, AUid)
  else
    TProgrammableUidCodec.ValidateUid(cgum7Byte, AUid);
  Result := HexToBytes('90FBCCCC07');
  SetLength(Result, 5 + Size);
  Move(AUid[0], Result[5], Size);
end;

class function TGen4UidCodec.UidLength(const ALayout: TGen4UidLayout): Integer;
begin
  case ALayout of
    g4ulClassic4, g4ulType2_4:
      Result := 4;
    g4ulClassic7, g4ulType2_7:
      Result := 7;
    g4ulClassic10, g4ulType2_10:
      Result := 10;
  else
    Fail;
    Result := 0;
  end;
end;

class function TGen4UidCodec.ManufacturerBlockCount(const ALayout
  : TGen4UidLayout): Integer;
var
  Size: Integer;
begin
  Size := UidLength(ALayout);
  if Size = 0 then
    Fail;
  if ALayout = g4ulType2_7 then
    Result := 3
  else
    Result := 1;
end;

class procedure TGen4UidCodec.ValidateUid(const ALayout: TGen4UidLayout;
  const AUid: TBytes);
var
  Size: Integer;
begin
  Size := UidLength(ALayout);
  if Length(AUid) <> Size then
    Fail;
  if ((Size = 4) and (AUid[0] = $88)) or ((Size <> 4) and (AUid[3] = $88)) then
    Fail;
end;

class procedure TGen4UidCodec.ValidateConfiguration(const ALayout
  : TGen4UidLayout; const AConfiguration: TBytes);
var
  Size: Integer;
  Protocol, LengthCode: Byte;
begin
  Size := UidLength(ALayout);
  if not(Length(AConfiguration) in [30, 32]) then
    Fail;
  if ALayout in [g4ulClassic4, g4ulClassic7, g4ulClassic10] then
    Protocol := 0
  else
    Protocol := 1;
  case Size of
    4:
      LengthCode := 0;
    7:
      LengthCode := 1;
    10:
      LengthCode := 2;
  else
    Fail;
    LengthCode := 0;
  end;
  if (AConfiguration[0] <> Protocol) or (AConfiguration[1] <> LengthCode) or
    (AConfiguration[6] <> 2) or (AConfiguration[7] > 16) then
    Fail;
end;

procedure ValidateBlocks(const ALayout: TGen4UidLayout;
  const ABlocks: TUidManufacturerBlocks);
var
  I: Integer;
begin
  if Length(ABlocks) <> TGen4UidCodec.ManufacturerBlockCount(ALayout) then
    Fail;
  for I := 0 to Length(ABlocks) - 1 do
    if Length(ABlocks[I]) <> 16 then
      Fail;
end;

class function TGen4UidCodec.DecodeUid(const ALayout: TGen4UidLayout;
  const ABlocks: TUidManufacturerBlocks): TBytes;
begin
  Result := nil;
  ValidateBlocks(ALayout, ABlocks);
  if ALayout = g4ulType2_7 then
  begin
    if (($88 xor ABlocks[0][0] xor ABlocks[0][1] xor ABlocks[0][2]) <>
      ABlocks[0][3]) or
      ((ABlocks[1][0] xor ABlocks[1][1] xor ABlocks[1][2] xor ABlocks[1][3]) <>
      ABlocks[2][0]) then
      Fail;
    SetLength(Result, 7);
    Move(ABlocks[0][0], Result[0], 3);
    Move(ABlocks[1][0], Result[3], 4);
  end
  else
    Result := Copy(ABlocks[0], 0, UidLength(ALayout));
  ValidateUid(ALayout, Result);
end;

class function TGen4UidCodec.PrepareBlocks(const ALayout: TGen4UidLayout;
  const ABlocks: TUidManufacturerBlocks; const ANewUid: TBytes)
  : TUidManufacturerBlocks;
var
  Previous: TBytes;
  I: Integer;
begin
  Result := nil;
  ValidateUid(ALayout, ANewUid);
  Previous := DecodeUid(ALayout, ABlocks);
  if Length(Previous) <> Length(ANewUid) then
    Fail;
  SetLength(Result, Length(ABlocks));
  for I := 0 to Length(ABlocks) - 1 do
    Result[I] := CopyBytes(ABlocks[I]);
  if ALayout = g4ulType2_7 then
  begin
    Move(ANewUid[0], Result[0][0], 3);
    Result[0][3] := $88 xor ANewUid[0] xor ANewUid[1] xor ANewUid[2];
    Move(ANewUid[3], Result[1][0], 4);
    Result[2][0] := ANewUid[3] xor ANewUid[4] xor ANewUid[5] xor ANewUid[6];
  end
  else
  begin
    Move(ANewUid[0], Result[0][0], Length(ANewUid));
    if ALayout = g4ulClassic4 then
      Result[0][4] := ANewUid[0] xor ANewUid[1] xor ANewUid[2] xor ANewUid[3];
  end;
end;

end.
