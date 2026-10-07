unit ERD.Card.Contactless.UID;

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
  /// <summary>Invalid programmable UID or manufacturer-block layout; messages contain no identifiers.</summary>
  EProgrammableUidError = class(EConvertError);
  /// <summary>Explicit Gen2/CUID manufacturer-block layout; not inferred from a requested UID length.</summary>
  TClassicGen2UidModel = (
    /// <summary>Four UID bytes, BCC at byte four and metadata at bytes five through fifteen.</summary>
    cgum4Byte,
    /// <summary>Seven UID bytes and metadata at bytes seven through fifteen; no stored BCC byte.</summary>
    cgum7Byte
  );
  /// <summary>Result after successful Classic manufacturer-block verification and transaction release.</summary>
  /// <remarks>Ordinary record assignment shares arrays. The active RF UID may remain old until
  /// reactivation with Gen2/CUID; raw-RF programming additionally requires fresh activation before returning.</remarks>
  TProgrammableUidResult = record
    /// <summary>Caller-selected manufacturer-block layout.</summary>
    Model: TClassicGen2UidModel;
    /// <summary>Independent original reader UID verified against the original manufacturer block.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested UID of the selected layout's size.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent complete sixteen-byte manufacturer block verified after writing.</summary>
    ManufacturerBlock: TBytes;
    /// <summary>True only if the reader also reports RequestedUid after the block write; false means it still reports PreviousUid.</summary>
    ActiveUidVerified: Boolean;
  end;
  /// <summary>Verified manufacturer-block write on a caller-identified four-byte factory FUID variant.</summary>
  /// <remarks>Independent buffers on return; ordinary record assignment shares arrays.
  /// A false active-UID flag requires fresh caller-controlled RF activation before provisioning is complete.</remarks>
  TFuidUidResult = record
    /// <summary>Independent original factory UID AA55C396, verified against manufacturer block zero.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested four-byte UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent complete sixteen-byte manufacturer block verified after the single write.</summary>
    ManufacturerBlock: TBytes;
    /// <summary>True if reader reports RequestedUid; false if it still caches the factory UID.</summary>
    ActiveUidVerified: Boolean;
  end;
  /// <summary>Independent manufacturer-block preparation for explicitly identified four/seven-byte Classic Gen2/CUID cards.</summary>
  /// <remarks>Does not detect a programmable card or implement RF unlock, one-time fuses, ten-byte layouts or UID emulation.</remarks>
  TProgrammableUidCodec = class
  public
    /// <summary>Returns the UID length for an explicit Gen2/CUID layout.</summary>
    /// <param name="AModel">Four-byte or seven-byte layout.</param>
    /// <returns>Four or seven bytes.</returns>
    /// <exception cref="EProgrammableUidError">Model is invalid.</exception>
    class function UidLength(const AModel: TClassicGen2UidModel): Integer; static;
    /// <summary>Validates requested UID size and ISO 14443-A cascade-tag position.</summary>
    /// <param name="AModel">Explicit four-byte or seven-byte layout.</param>
    /// <param name="AUid">Caller-owned target UID; never modified.</param>
    /// <exception cref="EProgrammableUidError">Model/length is invalid, four-byte UID0 is 88, or seven-byte UID3 is 88.</exception>
    /// <remarks>No uniqueness, manufacturer ownership or access-control authorization is inferred.</remarks>
    class procedure ValidateUid(const AModel: TClassicGen2UidModel; const AUid: TBytes); static;
    /// <summary>Validates a manufacturer-block layout and copies its UID.</summary>
    /// <param name="AModel">Caller-identified four-byte or seven-byte layout.</param>
    /// <param name="ABlock">Exactly sixteen bytes from an identified Gen2/CUID layout.</param>
    /// <returns>Independent UID; a four-byte layout's BCC must be its UID XOR.</returns>
    /// <exception cref="EProgrammableUidError">Model, block size or BCC is invalid.</exception>
    class function DecodeGen2Uid(const AModel: TClassicGen2UidModel; const ABlock: TBytes): TBytes; static;
    /// <summary>Replaces UID bytes and the four-byte layout's BCC while preserving all other manufacturer bytes.</summary>
    /// <param name="AModel">Caller-identified four-byte or seven-byte layout.</param>
    /// <param name="ABlock">Existing sixteen-byte block with a valid selected layout.</param>
    /// <param name="ANewUid">Exactly four or seven caller-owned UID bytes according to AModel.</param>
    /// <returns>Independent block preserving metadata from byte five or seven, respectively.</returns>
    /// <exception cref="EProgrammableUidError">UID length/cascade position, block size or existing BCC is invalid.</exception>
    class function PrepareGen2Block(const AModel: TClassicGen2UidModel; const ABlock, ANewUid: TBytes): TBytes; static;
  end;

implementation

uses ERD.Card.Bytes;

class function TProgrammableUidCodec.UidLength(const AModel: TClassicGen2UidModel): Integer;
begin
  case AModel of
    cgum4Byte: Result := 4;
    cgum7Byte: Result := 7;
  else raise EProgrammableUidError.Create('Invalid programmable UID layout.'); end;
end;

class procedure TProgrammableUidCodec.ValidateUid(const AModel: TClassicGen2UidModel;
  const AUid: TBytes);
var Size: Integer;
begin
  Size := UidLength(AModel);
  if Length(AUid) <> Size then
    raise EProgrammableUidError.Create('Programmable UID length does not match the selected layout.');
  if ((Size = 4) and (AUid[0] = $88)) or ((Size = 7) and (AUid[3] = $88)) then
    raise EProgrammableUidError.Create('Invalid programmable UID cascade position.');
end;

procedure ValidateGen2Block(const AModel: TClassicGen2UidModel; const ABlock: TBytes);
var Size: Integer;
begin
  Size := TProgrammableUidCodec.UidLength(AModel);
  if (Length(ABlock) <> 16) then
    raise EProgrammableUidError.Create('Invalid programmable UID block size.');
  if (Size = 4) and ((ABlock[0] xor ABlock[1] xor ABlock[2] xor ABlock[3]) <> ABlock[4]) then
    raise EProgrammableUidError.Create('Invalid programmable UID block checksum.');
end;

class function TProgrammableUidCodec.DecodeGen2Uid(const AModel: TClassicGen2UidModel; const ABlock: TBytes): TBytes;
begin
  ValidateGen2Block(AModel, ABlock);
  Result := Copy(ABlock, 0, UidLength(AModel));
end;

class function TProgrammableUidCodec.PrepareGen2Block(const AModel: TClassicGen2UidModel;
  const ABlock, ANewUid: TBytes): TBytes;
var I, Size: Integer;
begin
  Result := nil;
  Size := UidLength(AModel);
  ValidateUid(AModel, ANewUid);
  ValidateGen2Block(AModel, ABlock);
  Result := CopyBytes(ABlock);
  for I := 0 to Size - 1 do Result[I] := ANewUid[I];
  if Size = 4 then Result[4] := ANewUid[0] xor ANewUid[1] xor ANewUid[2] xor ANewUid[3];
end;

end.
