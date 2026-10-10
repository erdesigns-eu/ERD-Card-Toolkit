unit ERD.Card.ATR;

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

const
  /// <summary>The maximum asynchronous ISO 7816 ATR size, in bytes.</summary>
  AtrMaxSize = 33;

type
  /// <summary>The transmission protocols advertised by TD bytes; T=15 is excluded.</summary>
  TAtrProtocols = set of 0 .. 14;

  /// <summary>One group of optional TA, TB, TC and TD interface bytes.</summary>
  TAtrInterfaceGroup = record
    /// <summary>Whether TA is present in this group.</summary>
    HasTA: Boolean;
    /// <summary>The TA value; zero if absent.</summary>
    TA: Byte;
    /// <summary>Whether TB is present in this group.</summary>
    HasTB: Boolean;
    /// <summary>The TB value; zero if absent.</summary>
    TB: Byte;
    /// <summary>Whether TC is present in this group.</summary>
    HasTC: Boolean;
    /// <summary>The TC value; zero if absent.</summary>
    TC: Byte;
    /// <summary>Whether TD is present in this group.</summary>
    HasTD: Boolean;
    /// <summary>The TD value, including the next group mask and protocol number.</summary>
    TD: Byte;
  end;

  /// <summary>Interface groups in ATR order; array index zero denotes TA1 through TD1.</summary>
  TAtrInterfaceGroups = array of TAtrInterfaceGroup;

  /// <summary>A completely validated asynchronous ATR in logical-byte form.</summary>
  /// <remarks>
  /// PC/SC supplies logical bytes for both conventions; this codec does not decode
  /// electrical signalling. Ordinary record assignment shares the dynamic arrays.
  /// Decoding allocates independent Raw, HistoricalBytes and InterfaceGroups arrays.
  /// </remarks>
  TAtrInfo = record
    /// <summary>An independent copy of the entire validated ATR.</summary>
    Raw: TBytes;
    /// <summary>The initial convention byte: 3B for direct or 3F for inverse convention.</summary>
    TS: Byte;
    /// <summary>The first interface-presence mask and historical-byte count.</summary>
    T0: Byte;
    /// <summary>Present interface groups in order; may be empty.</summary>
    InterfaceGroups: TAtrInterfaceGroups;
    /// <summary>The uninterpreted historical bytes, with at most fifteen bytes.</summary>
    HistoricalBytes: TBytes;
    /// <summary>Advertised transmission protocols; implicit T=0 if none are advertised.</summary>
    Protocols: TAtrProtocols;
    /// <summary>Whether a mandatory TCK checksum was present and validated.</summary>
    HasTck: Boolean;
    /// <summary>The validated TCK byte, or zero when no checksum is required.</summary>
    Tck: Byte;
  end;

  /// <summary>Describes an ATR syntax or checksum failure.</summary>
  TAtrErrorCode = (
    /// <summary>No error occurred.</summary>
    aicNone,
    /// <summary>TS or T0 is missing.</summary>
    aicHeaderTruncated,
    /// <summary>TS is neither 3B nor 3F.</summary>
    aicInvalidConvention,
    /// <summary>An interface byte announced by a mask is missing.</summary>
    aicInterfaceTruncated,
    /// <summary>The historical-byte count exceeds the remaining bytes.</summary>
    aicHistoricalTruncated,
    /// <summary>A nonzero TD protocol requires a missing TCK.</summary>
    aicChecksumMissing,
    /// <summary>XOR from T0 through TCK is not zero.</summary>
    aicChecksumMismatch,
    /// <summary>Bytes remain after the complete ATR.</summary>
    aicTrailingData,
    /// <summary>The ATR exceeds the thirty-three-byte limit.</summary>
    aicTooLong);

  /// <summary>Describes an ATR failure without retaining card data.</summary>
  TAtrError = record
    /// <summary>The failure category; aicNone on success.</summary>
    Code: TAtrErrorCode;
    /// <summary>The zero-based offending position, input length for missing bytes, or minus one on success.</summary>
    Offset: Integer;
  end;

  /// <summary>An exception containing a structured ATR failure without input contents.</summary>
  EAtrFormatError = class(EConvertError)
  private
    FError: TAtrError;
  public
    /// <summary>Creates an error from an ATR failure code and byte position.</summary>
    /// <param name="AError">The failure details.</param>
    constructor Create(const AError: TAtrError); reintroduce;
    /// <summary>The failure details, with a zero-based offset.</summary>
    property Error: TAtrError read FError;
  end;

  /// <summary>Validates asynchronous ISO 7816 ATR syntax and its required checksum.</summary>
  /// <remarks>Stateless and independent of VCL, hardware and issuer-identification catalogs.</remarks>
  TAtrCodec = class
  public
    /// <summary>Decodes an ATR only when all declared bytes and the required TCK are valid.</summary>
    /// <param name="ABytes">Complete logical ATR bytes from the reader.</param>
    /// <param name="AInfo">Independent decoded information, or a cleared record on failure.</param>
    /// <param name="AError">Failure details, or aicNone and offset minus one on success.</param>
    /// <returns>True for a complete, valid ATR with no trailing bytes.</returns>
    /// <remarks>
    /// Nonzero TD protocols, including global-interface T=15, require TCK.
    /// T=15 is not added to the transmission-protocol set. Input must not alias
    /// a dynamic-array field of the out record. Allocation failures may propagate.
    /// </remarks>
    class function TryDecode(const ABytes: TBytes; out AInfo: TAtrInfo;
      out AError: TAtrError): Boolean; static;
    /// <summary>Decodes a complete ATR and raises a structured exception on invalid input.</summary>
    /// <param name="ABytes">Complete logical ATR bytes.</param>
    /// <returns>Independent validated ATR information.</returns>
    /// <exception cref="EAtrFormatError">ATR syntax or the required checksum is invalid.</exception>
    class function Decode(const ABytes: TBytes): TAtrInfo; static;
  end;

implementation

procedure AtrError(out AError: TAtrError; const ACode: TAtrErrorCode;
  const AOffset: Integer);
begin
  AError.Code := ACode;
  AError.Offset := AOffset;
end;

constructor EAtrFormatError.Create(const AError: TAtrError);
begin
  inherited CreateFmt('Invalid ATR: error %d at byte offset %d.',
    [Ord(AError.Code), AError.Offset]);
  FError := AError;
end;

class function TAtrCodec.TryDecode(const ABytes: TBytes; out AInfo: TAtrInfo;
  out AError: TAtrError): Boolean;
var
  Info: TAtrInfo;
  Group: TAtrInterfaceGroup;
  Mask: Byte;
  Protocol: Byte;
  NeedTck: Boolean;
  Checksum: Byte;
  Position: Integer;
  Size: Integer;
  HistorySize: Integer;
  GroupCount: Integer;
  I: Integer;

  function ReadInterface(out AValue: Byte): Boolean;
  begin
    Result := Position < Size;
    if not Result then
      AtrError(AError, aicInterfaceTruncated, Position)
    else
    begin
      AValue := ABytes[Position];
      Inc(Position);
    end;
  end;

begin
  AInfo := Default (TAtrInfo);
  AtrError(AError, aicNone, -1);
  if Length(ABytes) > AtrMaxSize then
  begin
    AtrError(AError, aicTooLong, AtrMaxSize);
    Exit(False);
  end;
  Size := Length(ABytes);
  if Size < 2 then
  begin
    AtrError(AError, aicHeaderTruncated, Size);
    Exit(False);
  end;
  if (ABytes[0] <> $3B) and (ABytes[0] <> $3F) then
  begin
    AtrError(AError, aicInvalidConvention, 0);
    Exit(False);
  end;
  Info := Default (TAtrInfo);
  Info.TS := ABytes[0];
  Info.T0 := ABytes[1];
  Mask := Info.T0 shr 4;
  Position := 2;
  NeedTck := False;
  while Mask <> 0 do
  begin
    Group := Default (TAtrInterfaceGroup);
    Group.HasTA := (Mask and 1) <> 0;
    Group.HasTB := (Mask and 2) <> 0;
    Group.HasTC := (Mask and 4) <> 0;
    Group.HasTD := (Mask and 8) <> 0;
    if Group.HasTA then
      if not ReadInterface(Group.TA) then
        Exit(False);
    if Group.HasTB then
      if not ReadInterface(Group.TB) then
        Exit(False);
    if Group.HasTC then
      if not ReadInterface(Group.TC) then
        Exit(False);
    if Group.HasTD then
      if not ReadInterface(Group.TD) then
        Exit(False);
    GroupCount := Length(Info.InterfaceGroups);
    SetLength(Info.InterfaceGroups, GroupCount + 1);
    Info.InterfaceGroups[GroupCount] := Group;
    Mask := 0;
    if Group.HasTD then
    begin
      Protocol := Group.TD and $0F;
      if Protocol <> 15 then
        Include(Info.Protocols, Protocol);
      if Protocol <> 0 then
        NeedTck := True;
      Mask := Group.TD shr 4;
    end;
  end;
  if Info.Protocols = [] then
    Include(Info.Protocols, 0);
  HistorySize := Info.T0 and $0F;
  if HistorySize > Size - Position then
  begin
    AtrError(AError, aicHistoricalTruncated, Size);
    Exit(False);
  end;
  Info.HistoricalBytes := Copy(ABytes, Position, HistorySize);
  Inc(Position, HistorySize);
  if NeedTck then
  begin
    if Position >= Size then
    begin
      AtrError(AError, aicChecksumMissing, Position);
      Exit(False);
    end;
    Checksum := 0;
    for I := 1 to Position do
      Checksum := Checksum xor ABytes[I];
    if Checksum <> 0 then
    begin
      AtrError(AError, aicChecksumMismatch, Position);
      Exit(False);
    end;
    Info.HasTck := True;
    Info.Tck := ABytes[Position];
    Inc(Position);
  end;
  if Position <> Size then
  begin
    AtrError(AError, aicTrailingData, Position);
    Exit(False);
  end;
  Info.Raw := Copy(ABytes, 0, Size);
  AInfo := Info;
  Result := True;
end;

class function TAtrCodec.Decode(const ABytes: TBytes): TAtrInfo;
var
  Error: TAtrError;
begin
  if not TryDecode(ABytes, Result, Error) then
    raise EAtrFormatError.Create(Error);
end;

end.
