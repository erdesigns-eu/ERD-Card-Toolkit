unit ERD.Card.Contactless.UID.Partial;

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
  /// <summary>Caller-identified partial USCUID four-byte variant using enabled Gen1a wakeup.</summary>
  /// <remarks>Never inferred from UID or configuration alone. PFUID has reversed configuration commands.</remarks>
  TPartialUscuidProfile = (
    /// <summary>Unsealed UFUID with BAFA marker and E0 configuration read; no seal or unfuse operation.</summary>
    pupUnsealedUfuid,
    /// <summary>ZUID with zero reserved marker and E0 configuration read; no hidden blocks.</summary>
    pupZuid,
    /// <summary>PFUID with BAFA3585 marker and E1 configuration read; no configuration data is written.</summary>
    pupPfuid);

  /// <summary>Verified partial-USCUID manufacturer block and unchanged configuration after fresh selection.</summary>
  /// <remarks>Buffers are independent on return; ordinary record assignment shares arrays.</remarks>
  TPartialUscuidUidResult = record
    /// <summary>Explicitly selected partial variant; not an automatically detected chip type.</summary>
    Profile: TPartialUscuidProfile;
    /// <summary>Independent original four-byte RF UID verified against block zero.</summary>
    PreviousUid: TBytes;
    /// <summary>Independent requested four-byte UID.</summary>
    RequestedUid: TBytes;
    /// <summary>Independent full sixteen-byte configuration verified unchanged.</summary>
    Configuration: TBytes;
    /// <summary>Independent full sixteen-byte manufacturer block, including preserved bytes five through fifteen.</summary>
    ManufacturerBlock: TBytes;
    /// <summary>True on every returned result: fresh selection or a verified no-op reports RequestedUid.</summary>
    ActiveUidVerified: Boolean;
  end;

  /// <summary>Explicit partial-USCUID configuration shapes, without full-USCUID personalization interpretation.</summary>
  TPartialUscuidUidCodec = class
  public
    /// <summary>Returns the configuration-read opcode for the explicitly selected variant.</summary>
    /// <param name="AProfile">Caller-identified unsealed UFUID, ZUID or PFUID.</param>
    /// <returns>E0 for UFUID/ZUID; E1 for PFUID, followed by block byte00 and CRC-A by the raw programmer.</returns>
    /// <exception cref="EProgrammableUidError">Profile is invalid.</exception>
    /// <remarks>Never probe E1 on another variant: it can start a configuration-write handshake there.</remarks>
    class function ConfigurationReadCommand(const AProfile
      : TPartialUscuidProfile): Byte; static;
    /// <summary>Validates a documented enabled four-byte partial configuration without modifying it.</summary>
    /// <param name="AProfile">Explicit variant, not automatically inferred from the response.</param>
    /// <param name="AConfiguration">Exactly sixteen caller-owned bytes from the variant's configuration read.</param>
    /// <exception cref="EProgrammableUidError">Profile, length, enable/header, known marker, flags or final-cascade SAK is unsupported.</exception>
    /// <remarks>Requires 7AFF00000000 header, bytes six/seven each 00 or 5A, the selected reserved marker
    /// and a final-cascade SAK. Bytes eight through fourteen are opaque variant markers, not full-USCUID
    /// personalization, shadow or Magic Auth settings. Unknown marker variants require a separate profile.</remarks>
    class procedure ValidateConfiguration(const AProfile: TPartialUscuidProfile;
      const AConfiguration: TBytes); static;
  end;

implementation

uses ERD.Card.Bytes;

procedure Invalid;
begin
  raise EProgrammableUidError.Create
    ('Invalid or unsupported partial USCUID profile data.');
end;

class function TPartialUscuidUidCodec.ConfigurationReadCommand
  (const AProfile: TPartialUscuidProfile): Byte;
begin
  case AProfile of
    pupUnsealedUfuid, pupZuid:
      Result := $E0;
    pupPfuid:
      Result := $E1;
  else
    Invalid;
    Result := 0;
  end;
end;

class procedure TPartialUscuidUidCodec.ValidateConfiguration(const AProfile
  : TPartialUscuidProfile; const AConfiguration: TBytes);
var
  Expected: TBytes;
  I: Integer;
begin
  case AProfile of
    pupUnsealedUfuid:
      Expected := HexToBytes('7AFF000000000000BAFA000000000008');
    pupZuid:
      Expected := HexToBytes('7AFF0000000000000000000000000008');
    pupPfuid:
      Expected := HexToBytes('7AFF000000000000BAFA358500000008');
  else
    Invalid;
  end;
  if Length(AConfiguration) <> 16 then
    Invalid;
  for I := 0 to 14 do
    if I in [6, 7] then
    begin
      if not(AConfiguration[I] in [0, $5A]) then
        Invalid;
    end
    else if AConfiguration[I] <> Expected[I] then
      Invalid;
  if (AConfiguration[15] and $04) <> 0 then
    Invalid;
end;

end.
