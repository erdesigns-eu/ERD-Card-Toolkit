unit DesfirePlus.Vectors;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
type
  /// <summary>Independent synthetic native command/response strings, generated with Python cryptography.</summary>
  TExtendedPair = record
    /// <summary>Exact expected command bytes.</summary>
    Command: string;
    /// <summary>Exact synthetic response bytes.</summary>
    Response: string;
  end;
  /// <summary>Owned ordered protocol fixture with no real card data.</summary>
  TExtendedPairs = array of TExtendedPair;
/// <summary>Returns independent synthetic DfInitialize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfInitialize: TExtendedPairs;
/// <summary>Returns independent synthetic DfChangeInactive native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfChangeInactive: TExtendedPairs;
/// <summary>Returns independent synthetic DfFinalize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfFinalize: TExtendedPairs;
/// <summary>Returns independent synthetic DfRoll native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfRoll: TExtendedPairs;
/// <summary>Returns independent synthetic DfConfigAts native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfConfigAts: TExtendedPairs;
/// <summary>Returns independent synthetic DfConfigValue native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfConfigValue: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfSdmRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSdmRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfSetVersions native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfSetVersions: TExtendedPairs;
/// <summary>Returns independent synthetic DfCreate native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfCreate: TExtendedPairs;
/// <summary>Returns independent synthetic PlusMacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusMacRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusMacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusMacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullReadNew native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullReadNew: TExtendedPairs;
/// <summary>Returns independent synthetic PlusFullWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusFullWrite: TExtendedPairs;
/// <summary>Returns independent synthetic Plus4KRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function Plus4KRead: TExtendedPairs;
/// <summary>Returns independent synthetic Plus4KWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function Plus4KWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4000 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4000: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4001 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4001: TExtendedPairs;
/// <summary>Returns independent synthetic PlusRotate4040 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusRotate4040: TExtendedPairs;
/// <summary>Returns independent synthetic PlusPersonalize native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusPersonalize: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9004 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9004: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9002 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9002: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel9003 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel9003: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel3Proof native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel3Proof: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevelAcr native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevelAcr: TExtendedPairs;
/// <summary>Returns independent synthetic PlusValueRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusValueRead: TExtendedPairs;
/// <summary>Returns independent synthetic PlusValueWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusValueWrite: TExtendedPairs;
/// <summary>Returns independent synthetic PlusLevel2To3 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusLevel2To3: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative0Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative0Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative0Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative0Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative1Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative1Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative1Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative1Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative2Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative2Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative2Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative2Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative3Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative3Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative3Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative3Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4Same native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4Same: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4Cross native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4Cross: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4KIncrement native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4KIncrement: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNative4KDecrement native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNative4KDecrement: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNativeBadTarget native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNativeBadTarget: TExtendedPairs;
/// <summary>Returns independent synthetic PlusNativeBadSource native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function PlusNativeBadSource: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoDirectory native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoDirectory: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateApplication native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateApplication: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoFileIds native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoFileIds: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile0 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile0: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile1 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile1: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile3 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile3: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateFile4 native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateFile4: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiSettings native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiSettings: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacCreate native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacCreate: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacSettings native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacSettings: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecord native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecord: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacReaderAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacReaderAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacBadMac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacBadMac: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacBadCounter native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacBadCounter: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacCrypto native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacCrypto: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecordMac native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecordMac: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacRecordFull native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacRecordFull: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacLimitChange native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacLimitChange: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacDelete native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacDelete: TExtendedPairs;
/// <summary>Returns independent synthetic DfMultiNonMasterRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfMultiNonMasterRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateKeySets native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateKeySets: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadGeometry native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadGeometry: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadFid native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadFid: TExtendedPairs;
/// <summary>Returns independent synthetic DfIsoCreateBadName native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfIsoCreateBadName: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardOverlap native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardOverlap: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDisjoint native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDisjoint: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardNoop native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardNoop: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardAbort native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardAbort: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardRepeat native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardRepeat: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardPreimage native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardPreimage: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardImmediateMismatch native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardImmediateMismatch: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardCommitMismatch native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardCommitMismatch: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDeniedWrite native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDeniedWrite: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardDeniedRead native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardDeniedRead: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardWrongFile native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardWrongFile: TExtendedPairs;
/// <summary>Returns independent synthetic DfTmacStandardBounds native protocol vector.</summary>
/// <returns>Owned literal command/response pairs.</returns>
function DfTmacStandardBounds: TExtendedPairs;
implementation
function DfInitialize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '905600000A01029688731516D1623400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
end;
function DfChangeInactive: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90C600002A010111CC601EC19ABA33BF9FE3B2807CF68667A0306AEC2CF4D6B87E1B5102E3E1A485119FEFF3021DE400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
  Result[5].Command := '906400000A41013A5105B3DFE8D3DB00';
  Result[5].Response := '34C662C9D35CB6771E9100';
end;
function DfFinalize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '905700000A012153EF72E0D48BB1D400';
  Result[4].Response := '2815BB17AD6EAF2F9100';
end;
function DfRoll: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '905500000901267ACB61A7E6557E00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9071000002000000';
  Result[6].Response := 'D0EA8B2030A9A14763EF94BEFCB4AB8991AF';
  Result[7].Command := '90AF000020FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A85900';
  Result[7].Response := 'AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF086169100';
  Result[8].Command := '9064000009001E3288A2F0EB85E300';
  Result[8].Response := '342E92780A2DD8DC579100';
end;
function DfConfigAts: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '905C00001902CE69F3DF2C9428855C9F52D34E8FF6CF3426E8FA17F99AC500';
  Result[3].Response := 'FA0E3F508A694E089100';
end;
function DfConfigValue: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '905C00001909984B8CD7D715F4E4315F2B571EBD20F88E73F9992890FA6E00';
  Result[3].Response := 'FA0E3F508A694E089100';
end;
function DfSdmChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '000000E00001002358DF7643B0182A9100';
  Result[5].Command := '905F00001900FF07F33052793813ED0FD16D2C0E09F129F6960964CFD31400';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '90F5000009003F8EDE83A22FBA2B00';
  Result[6].Response := '004000E0000100C1F12120000043000043000003C530E29B79BC979100';
end;
function DfSdmRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90F500000900C88DBE6B1DBE53DD00';
  Result[3].Response := '004000E0000100C1F1212000004300004300006CBF9073B793052A9100';
end;
function DfSetVersions: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '906400000A40801BBEA2CE05D9CFD000';
  Result[4].Response := '01212FA2A134083358CB9100';
end;
function DfCreate: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '2815BB17AD6EAF2F9100';
  Result[5].Command := '90CA0000125634120F930101021000DCC96054EE7326A600';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '905A00000356341200';
  Result[6].Response := '9100';
  Result[7].Command := '9045000000';
  Result[7].Response := '0F9301010210009100';
  Result[8].Command := '905A00000300000000';
  Result[8].Response := '9100';
  Result[9].Command := '9071000002000000';
  Result[9].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[10].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[10].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
end;
function PlusMacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '33020001B962854D170390D8';
  Result[2].Response := '90000102030405060708090A0B0C0D0E0FE5108F0C63C71F1D';
end;
function PlusMacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '33020001B962854D170390D8';
  Result[2].Response := '90000102030405060708090A0B0C0D0E0FE5108F0C63C71F1D';
  Result[3].Command := 'A30200101112131415161718191A1B1C1D1E1FCA61C76CB9317345';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '330200012EABF89882D898A3';
  Result[4].Response := '90101112131415161718191A1B1C1D1E1FF35A2D89339ADF8A';
end;
function PlusFullRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusFullReadNew: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '906BFA847A3CE7BAE0AF291ABBFA4DCC7536F785C07F279DDC';
end;
function PlusFullWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
  Result[3].Command := 'A10200585B9898BC05641C3B98209E55F8EA539704EE50FA73991E';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '9058A307E7000115EACBFE4F105768A13695FCFD61C7953DB7';
end;
function Plus4KRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '3180000F6F229F6B72FE15A9';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEFCEB3A884E9FDA58F2182E69133D2C91D433EB6910809AE453341A9ABE04615EAAC63C31B2AF9D38A1DED093341BF669F44623B950C81FBFBD994D9660D0ECDDEA81C53D0F606BF8D5702E7DE08CBC805475C615CC0C67837F2FD77297BBABDCD4DDDA53E04AB72718FFBD1676B8E9DD1EE0AFAC5A8B53B9919F694129728EE63B55F7522D37EDB924E73577D9B1458C242FBEF99229DDE6CA10D7E27BD30C975E05D3775729A29D2C9BF8452B8618B7C9021A79AB08A6CACB20FFDE68714AC5714537835CEC40D02F1A9E4F756F130E3B2F5D20B3CAC714F4515E4BB95848525A22B49D401C89C87';
end;
function Plus4KWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '9035FD196EBDD0A4D6630D801014BB9AEFD84C74E07E7B7682';
  Result[3].Command := 'A18000585B9898BC05641C3B98209E55F8EA53513648DF64902204';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '318000018DEAD33AF3D04754';
  Result[4].Response := '9058A307E7000115EACBFE4F105768A136F2548BFA7808B382';
end;
function PlusRotate4000: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A100408C0722BCBD7472670951A8348A597F07746B721B16C13813';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70004000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusRotate4001: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A101408C0722BCBD7472670951A8348A597F07F33EB15D4E41458B';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70014000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusRotate4040: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := 'A140408C0722BCBD7472670951A8348A597F079030FAE0C59C1C34';
  Result[2].Response := '90416B03900FD11506';
  Result[3].Command := '70404000';
  Result[3].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[4].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[4].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
end;
function PlusPersonalize: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := 'A8009000000000000000000000000000000000';
  Result[0].Response := '90';
  Result[1].Command := 'A8019000000000000000000000000000000000';
  Result[1].Response := '90';
  Result[2].Command := 'A8039000000000000000000000000000000000';
  Result[2].Response := '90';
  Result[3].Command := 'A80040112233445566778899AABBCCDDEEFF00';
  Result[3].Response := '90';
  Result[4].Command := 'A80200101112131415161718191A1B1C1D1E1F';
  Result[4].Response := '90';
  Result[5].Command := 'AA';
  Result[5].Response := '90';
  Result[6].Command := '70004000';
  Result[6].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[7].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[7].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[8].Command := '70009000';
  Result[8].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[9].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[9].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[10].Command := '70019000';
  Result[10].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[11].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[11].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[12].Command := '70004000';
  Result[12].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[13].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[13].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[14].Command := '70004000';
  Result[14].Response := '90D0EA8B2030A9A14763EF94BEFCB4AB89';
  Result[15].Command := '72FE68BF7C457FA5E25521C79492701E566B5F13E1018939080C2038F5EFB3A859';
  Result[15].Response := '90AFBE4E722E00E1E2C05FE7818794E558397B4E8B556284230FE90E1FCEF08616';
  Result[16].Command := '310200019179A55A0E015456';
  Result[16].Response := '90435BEFA021830E187FD611C3775C2250197B45A320E5D653';
end;
function PlusLevel9004: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '760490FC00';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel9002: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '7602902C54';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel9003: TExtendedPairs;
begin
  Result := nil; SetLength(Result,2);
  Result[0].Command := '760390F44D';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
end;
function PlusLevel3Proof: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '760390F44D';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9042557CACA75FB489EB682F716D9123D7FF81';
  Result[2].Command := '70004000';
  Result[2].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[3].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[3].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[4].Command := '31020001EFD4D960788D6239';
  Result[4].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusLevelAcr: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := 'FF00000006D43202000B0D';
  Result[0].Response := 'D5339000';
  Result[1].Command := 'FF00000004D4320400';
  Result[1].Response := 'D5339000';
  Result[2].Command := 'FF00000006D43205000000';
  Result[2].Response := 'D5339000';
  Result[3].Command := 'FF00000003D41224';
  Result[3].Response := 'D5139000';
  Result[4].Command := 'FF00000004D4320100';
  Result[4].Response := 'D5339000';
  Result[5].Command := 'FF00000004D4320101';
  Result[5].Response := 'D5339000';
  Result[6].Command := 'FF00000004D44A0100';
  Result[6].Response := 'D54B010104000807041122334455669000';
  Result[7].Command := 'FF00000008D40663026303633D';
  Result[7].Response := 'D5078080009000';
  Result[8].Command := 'FF0000000BD408630200630300633D00';
  Result[8].Response := 'D5099000';
  Result[9].Command := 'FF0000000BD408630200630300633D00';
  Result[9].Response := 'D5099000';
  Result[10].Command := 'FF00000007D442760490FC00';
  Result[10].Response := 'D5430090659F2ABFC5BC0708FB96E7A44AF9D595C3299000';
  Result[11].Command := 'FF00000004D406633C';
  Result[11].Response := 'D507009000';
  Result[12].Command := 'FF0000000BD408630200630300633D00';
  Result[12].Response := 'D5099000';
  Result[13].Command := 'FF00000025D442723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[13].Response := 'D543009042557CACA75FB489EB682F716D9123D7FF819000';
  Result[14].Command := 'FF00000004D406633C';
  Result[14].Response := 'D507009000';
  Result[15].Command := 'FF0000000BD408630280630380633D00';
  Result[15].Response := 'D5099000';
  Result[16].Command := 'FF00000004D4320100';
  Result[16].Response := 'D5339000';
  Result[17].Command := 'FF00000003D41234';
  Result[17].Response := 'D5139000';
end;
function PlusValueRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9079095FA26BD6F25E93D1798B5C27C9B4D8B7B44731A38B1D';
end;
function PlusValueWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '9079095FA26BD6F25E93D1798B5C27C9B4D8B7B44731A38B1D';
  Result[3].Command := 'A102003AA22A67FF99CAD402F581058CF743A2206B69FE6D3ADA8F';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90B5D09DAE3CA7B0AAEBC5B2076A626F27B3F763A041EE8A03';
end;
function PlusLevel2To3: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '700390007CFA';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595C329';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F352C81';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A2F35';
  Result[2].Command := '70004000';
  Result[2].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[3].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[3].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[4].Command := '31020001EFD4D960788D6239';
  Result[4].Response := '9035FD196EBDD0A4D6630D801014BB9AEF16C53C220430BE84';
end;
function PlusNative0Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B102004FC00F89220D6158A829FB9ABBD2F96077AC2E83902CF25A';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := 'B50200112B398F0CEF7805';
  Result[4].Response := '903F8C6E54AB4A6196';
  Result[5].Command := '31020001CF8B21CA913DC3BB';
  Result[5].Response := '90AEFF9D6CDED8D03A8EB4DAE4FD62733DF17EA6258D05E1E5';
end;
function PlusNative0Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B10100063F3A9FD5021CC7AA6D4A3D1B59BE8663AE73ECA0D03E8B';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '9083378EA50274A0B993B1910451B9819E94FF07C5342D1E20';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative1Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,6);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B302004FC00F89220D6158A829FB9ABBD2F960BBD09CD66819E39F';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := 'B50200112B398F0CEF7805';
  Result[4].Response := '903F8C6E54AB4A6196';
  Result[5].Command := '31020001CF8B21CA913DC3BB';
  Result[5].Response := '90955E85CD5B650EBC6BBD4D38DD593AB6A280A3002563B93E';
end;
function PlusNative1Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B30100063F3A9FD5021CC7AA6D4A3D1B59BE86F6C1BF67104DB70B';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '9053A654A435DE7705E09F137519127ED63F24899933BBAFF1';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative2Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B7020002004FC00F89220D6158A829FB9ABBD2F9604978A91865B26559';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90C682E7657B8E4F29CEFDF10819FEA289A8FF6511A0EE8997';
end;
function PlusNative2Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '9032978C6EFD58A740A4503700504115FBF1FB5639510171B0';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNative3Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
  Result[3].Command := 'B9020002004FC00F89220D6158A829FB9ABBD2F960C19FCCBAC657C15B';
  Result[3].Response := '90416B03900FD11506';
  Result[4].Command := '31020001CF8B21CA913DC3BB';
  Result[4].Response := '90D261AC46687BE8D2E7538A827357A3FD8E9E2EE7C711A108';
end;
function PlusNative3Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B901000200063F3A9FD5021CC7AA6D4A3D1B59BE869866A0835EA63126';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '905CB39122DE612C8967F093712271D0366C0BD5D749174226';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNative4Same: TExtendedPairs;
begin
  Result := nil; SetLength(Result,3);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31020001EFD4D960788D6239';
  Result[2].Response := '90AD9A0E089F68CE08F262E9443EC36E22658CC0EBE7F8110D';
end;
function PlusNative4Cross: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'C301005469F7B3009E64F2';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := 'B50200112B398F0CEF7805';
  Result[5].Response := '903F8C6E54AB4A6196';
  Result[6].Command := '31020001CFAD4EC39476ED53';
  Result[6].Response := '904632B75ADCDC37FA4E2C4659737A600CE991A6FB93052144';
  Result[7].Command := '31010001EED82CD11D548F19';
  Result[7].Response := '904D2CFE6D0104169B02D828A4E02D8DA31C07FB18E84F474E';
end;
function PlusNative4KIncrement: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '903D5A3DA07BACCC82807A2829339094A083733EEDE5DD7F8A';
  Result[3].Command := '31810001FC6FFA5540A2E090';
  Result[3].Response := '9005F5E56BBE5A2FEE18DE5D9D0E6CA4528CB0988647C79CA7';
  Result[4].Command := 'B78000810036ED82193E74D473DB247091AD153714E0B4B0A12BAB83ED';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '318100012E607DC4A0B52C92';
  Result[5].Response := '907C88A0DACD7BE51117479D7E26078C3BE7B7DE139D5AE275';
  Result[6].Command := '31800001B706F65869502F10';
  Result[6].Response := '90660CB2005C50CD1597897585488F79EA4A2CB736948B1141';
end;
function PlusNative4KDecrement: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70404000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '31800001A9B5529816B9639C';
  Result[2].Response := '90D0BA914791E4521B1D26864BEF200EF88030024118B158B6';
  Result[3].Command := '31810001FC6FFA5540A2E090';
  Result[3].Response := '9005F5E56BBE5A2FEE18DE5D9D0E6CA4528CB0988647C79CA7';
  Result[4].Command := 'B98000810036ED82193E74D473DB247091AD1537140D084A36CC2A54BE';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '318100012E607DC4A0B52C92';
  Result[5].Response := '90D1A174BCD2CA507CB19FBABA9987FEA90B59077C1D9A30D7';
  Result[6].Command := '31800001B706F65869502F10';
  Result[6].Response := '90FAB9192FE548A003A2FC735CE264611A7AE810C5ADABCAD4';
end;
function PlusNativeBadTarget: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '90C682E7657B8E4F29CEFDF10819FEA289A740C82354AE1B7E';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90BFCBEE628D9A71F0B4D84A0D0769D229F6CFCF16DAD02DDB';
end;
function PlusNativeBadSource: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '70004000';
  Result[0].Response := '90659F2ABFC5BC0708FB96E7A44AF9D595';
  Result[1].Command := '723B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F35';
  Result[1].Response := '9079087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A';
  Result[2].Command := '310100018DC15380DA1936A0';
  Result[2].Response := '906D92648F6FEBD6BEADF3207B6F1CAE9A9A1F09EBAF4AE89D';
  Result[3].Command := '31020001CF8B21CA913DC3BB';
  Result[3].Response := '90D121D4EC7993D3E73195E000DE9C84B9209F334B193F7C42';
  Result[4].Command := 'B701000200063F3A9FD5021CC7AA6D4A3D1B59BE860745B3BC601E0D96';
  Result[4].Response := '90416B03900FD11506';
  Result[5].Command := '31020001CFAD4EC39476ED53';
  Result[5].Response := '9032978C6EFD58A740A4503700504115FBF1FB5639510171B0';
  Result[6].Command := '31010001EED82CD11D548F19';
  Result[6].Response := '90AC2FA85C6696172DCEEBE79B4F50D7620B2CAA4D8B010C8D';
end;
function DfIsoDirectory: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906D000008664B64207BDFFE8900';
  Result[4].Response := '02000000E24F4C4491AF';
  Result[5].Command := '90AF000000';
  Result[5].Response := '56341205E1D27600008501010091AF';
  Result[6].Command := '90AF000000';
  Result[6].Response := '03000002E26162636465666768696A6B6C6D6E6F70B52558F18278A6A99100';
end;
function DfIsoCreateApplication: TExtendedPairs;
begin
  Result := nil; SetLength(Result,9);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA0000175634120FA305E1D276000085010100E92D702F899994E100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
end;
function DfIsoFileIds: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '9061000008E1540C530D81F4BE00';
  Result[4].Response := '03E104E1E5FC3D8F5E8EE1179100';
end;
function DfIsoCreateFile0: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90CD0000110004E103000004000005538B74CE5657FF00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '000300000400002F03BE66DED156B69100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile1: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90CB0000110004E1030000040000D84D78D7FA0A5E8E00';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile3: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90C10000140004E10300000400000200005A9CAF1DCD5EFB0900';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '030300000400000200000000009290F963DC6913239100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfIsoCreateFile4: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0FA34CD9CE33F77CF9D79100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0FA35E414E3F513D2E4D9100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '9061000008165FB4AF4A3F91A600';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90C00000140004E10300000400000200000EC4F9A0EE54125700';
  Result[7].Response := '1A4B5CB5980618979100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '0403000004000002000000000025A1E0BEDD3AB05A9100';
  Result[9].Command := '9061000008A7403968204984B500';
  Result[9].Response := '04E1F906E276FE3F27D69100';
end;
function DfMultiSettings: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
end;
function DfMultiChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '90F500000900BCFFE1398690DDB700';
  Result[5].Response := '0003F0FF040000830DD90CD2E63EBF9100';
  Result[6].Command := '905F00001900E4F92DC9DBE9A01DC76F6B5A334E6B9F7BCA03CF57CAE2C300';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
end;
function DfMultiRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
end;
function DfMultiWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000010F00DDE94042D3EE0D079100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0F9301010210003112C3AC03F0ED249100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000010F00A40C259BF35B21AB9100';
  Result[8].Command := '908D00001F00000000040000852C874E29DEF102F3768072C74E5125B4FEA9D3F44EF4EC00';
  Result[8].Response := 'E03FB3C38F9C73D19100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '6C0BE84E012C7D96451BE0C0F041E90CD12844ECEBE31CBA9100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '0083F0FF040000010F00B20778C44F9A8EB39100';
end;
function DfTmacCreate: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '906F000008A672EC5153013EFF00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '90CE00002D0100F0EF02EA04D5506B2B2EB33D6000E3E69C603273BD4C5087D081C7BB52D66F782CFBBDD4F65DC67F5408BF00';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F50000090107A6CE993490A06700';
  Result[7].Response := '0500F0EF02349288E7CCF0F545359100';
end;
function DfTmacSettings: TExtendedPairs;
begin
  Result := nil; SetLength(Result,5);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
end;
function DfTmacRecord: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
  Result[5].Command := '90AD000007010000000C000000';
  Result[5].Response := 'FFFFFFFF11223344556677889100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0500F0EF02341D4DD36D81A35A149100';
end;
function DfTmacWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000007A75C6BA5C12A26BAF0F1CCBC58EB56B9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '90F500000901BD9E1EE3DAE270A200';
  Result[10].Response := '0500F0EF0234FEA7D038B648C7B99100';
  Result[11].Command := '90C7000009017DBEC65F62F8F97800';
  Result[11].Response := '0100000003A31C0E3D32DD3FBDD300DF526C488A9100';
end;
function DfTmacAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,11);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '90A700000869B342C10F4E007000';
  Result[10].Response := 'DCF5C762E10055089100';
end;
function DfTmacReaderWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '908D00001F00000000040000A0A61C830A4BCB5EAB8557573B2A737BBD93F21079A31CCF00';
  Result[11].Response := '0ACE7A1CA867FB5D9100';
  Result[12].Command := '90F500000901D5EB2C680B27291D00';
  Result[12].Response := '050000EF02345419BD6CEB8D16A09100';
  Result[13].Command := '90C7000009012771B5EEAC8707FC00';
  Result[13].Response := '010000008A84BE4B5EF84B691E801FDE8344EB3F9100';
  Result[14].Command := '90F5000009002015F8825CE1C7FB00';
  Result[14].Response := '01030000040000A8C22CB30570BC6D9100';
  Result[15].Command := '90AD00000F0000000004000064008CFA2407E7D900';
  Result[15].Response := '450EDEEE51E6276F1DBD4F95B59A4E65A418B009637ADFD49100';
  Result[16].Command := '90F500000900DA36FB6C287E16A900';
  Result[16].Response := '01030000040000A551C17DEE3C83059100';
end;
function DfTmacReaderRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,13);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '050000EF0234E53D780A6654F4039100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000001E4BE138CFA127FF3AAB02311881A85A9100';
end;
function DfTmacReaderAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '050000EF023477FCE7F83BE464F59100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90C8000018102132435465768798A9BACBDCEDFE0F4AEB360EBDBED01E00';
  Result[7].Response := '214B55834A24B4DC523EC09CE230C9E8A57FB137213D8A189100';
  Result[8].Command := '90F5000009002B40A61528387FA400';
  Result[8].Response := '01030000040000DAF94F8106BE32629100';
  Result[9].Command := '90AD00000F00000000040000CFF4603C6C93976D00';
  Result[9].Response := '47C8539101B50B2A4147E45DC7898E9302CACAD84D3844E99100';
  Result[10].Command := '90F500000900BA8F5B04BD348EAA00';
  Result[10].Response := '01030000040000BBD67F7D09FFA0459100';
  Result[11].Command := '90A7000008B09FF675403D9FBC00';
  Result[11].Response := '0ACE7A1CA867FB5D9100';
end;
function DfTmacBadMac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '010000007B75C6BA5C12A26B5945096FF86551CD9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacBadCounter: TExtendedPairs;
begin
  Result := nil; SetLength(Result,16);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '010300000400001339173BEC889A419100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '010300000400001F73A6995F2A59809100';
  Result[8].Command := '90AD00000F000000000400008A5D2D85F6B9912E00';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '010300000400009F615C592C6050579100';
  Result[10].Command := '908D00001F00000000040000FF45F7B48A16322A2176FB5A3196D3293911A4A8CC4484DB00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90F500000901B9543631F9571ADD00';
  Result[11].Response := '0500F0EF0234D77B7DD11D2F3DCA9100';
  Result[12].Command := '90C7000009010A7D06B4709406E400';
  Result[12].Response := '020000007A75C6BA5C12A26B6F7FCF8E652A4F5E9100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0103000004000038C3501A59A21B369100';
  Result[14].Command := '90AD00000F00000000040000A28345832D404ACA00';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '01030000040000153E4ED0D7BC3B7B9100';
end;
function DfTmacCrypto: TExtendedPairs;
begin
  Result := nil; SetLength(Result,4);
  Result[0].Command := '5A000100800100000004112233445566';
  Result[0].Response := '104FEBF2F6929C6A5A02D798D113F8FD';
  Result[1].Command := 'A5000100800100000004112233445566';
  Result[1].Response := '00B477D3F23DA9C3A93EBA9AD07B05C8';
  Result[2].Command := 'AD000000000400000000000000000000010203040000000000000000000000008D000000000400000000000000000000AABBCCDD000000000000000000000000';
  Result[2].Response := '7A75C6BA5C12A26B';
  Result[3].Command := '102132435465768798A9BACBDCEDFE0F';
  Result[3].Response := 'B1C4F20D1FF15A5B4180AC116D2D8957';
end;
function DfTmacRecordMac: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0501F0EF0234B0F60D59C16C79519100';
  Result[5].Command := '90AD00000F010000000C000026256C8EC1719FE300';
  Result[5].Response := '010000001122334455667788E15E3F2C1E76B86D9100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0501F0EF0234659598FF75EB3E2A9100';
end;
function DfTmacRecordFull: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0503F0EF02349BC69A6228FB102E9100';
  Result[5].Command := '90AD00000F010000000C000026256C8EC1719FE300';
  Result[5].Response := 'E1F5150FF050C93281F749D7F2188ED47E3AB52ADF8AF1119100';
  Result[6].Command := '90F50000090156AAD283BC66223200';
  Result[6].Response := '0503F0EF0234E9E123BE3118D89A9100';
end;
function DfTmacLimitChange: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90450000083CF4E07AFAF054C100';
  Result[4].Response := '0F9301010210000F85847F7A1809D79100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '905F0000190180B7A8E7E0C17635835E3C5C0DA7F444CE4346C4DF57324E00';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '90F50000090107A6CE993490A06700';
  Result[7].Response := '0533F0EF0234E803000006BDD70FBF1666A59100';
end;
function DfTmacDelete: TExtendedPairs;
begin
  Result := nil; SetLength(Result,7);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F9301010210008F655C5D0A7F9D6F9100';
  Result[4].Command := '90F500000901E04533322C27B73800';
  Result[4].Response := '0500F0EF023420CF7179D98267169100';
  Result[5].Command := '90DF00000901968AC3F3ECD3858B00';
  Result[5].Response := '1C521DD1BBDA2C289100';
  Result[6].Command := '906F0000089588797C6DB9E6F300';
  Result[6].Response := '00EB0AA364DA638D069100';
end;
function DfMultiNonMasterRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002010000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0B93010102100040D9E2E071BE0DB89100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0083F0FF040000011F11D97F68358B0C03639100';
  Result[5].Command := '9045000008F63E7701FF6E28F400';
  Result[5].Response := '0B930101021000880A9C6A5B51EC0E9100';
  Result[6].Command := '90AD00000F0000000004000011602F58CE31EBE800';
  Result[6].Response := 'D75908CD81A37C2ABAF06B548E8F56B606C63163B5690ECF9100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0083F0FF040000011F117C4D7ADEED961ACA9100';
end;
function DfIsoCreateKeySets: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadGeometry: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D27600008501010059A53775212989EA9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301200410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadFid: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341204E1D2760000850101004703A53523AC26E69100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfIsoCreateBadName: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000300000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '90450000085888703EC1CC8E6D00';
  Result[3].Response := '0F813A00CA07FE8B45CB9100';
  Result[4].Command := '906A000008E0C4D4775C0BBB2100';
  Result[4].Response := '020000CAE375372463AFE79100';
  Result[5].Command := '906D000008EAE4F5B3EE90ADBC00';
  Result[5].Response := '02000000E24F4C4488CF2236F648E01B9100';
  Result[6].Command := '90CA00001C5634120FB3012104100105E1D276000085010100FF73DD831363351100';
  Result[6].Response := '803E7446496C9FA29100';
  Result[7].Command := '906D0000081B6A592BED4BE9E300';
  Result[7].Response := '02000000E24F4C4491AF';
  Result[8].Command := '90AF000000';
  Result[8].Response := '56341205E1D376000085010100E9EAC91D560BAE6A9100';
  Result[9].Command := '905A00000356341200';
  Result[9].Response := '9100';
  Result[10].Command := '9045000000';
  Result[10].Response := '0FB301210410019100';
  Result[11].Command := '905A00000300000000';
  Result[11].Response := '9100';
  Result[12].Command := '9071000002000000';
  Result[12].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[13].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[13].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[14].Command := '90450000085888703EC1CC8E6D00';
  Result[14].Response := '0F813A00CA07FE8B45CB9100';
  Result[15].Command := '906D000008664B64207BDFFE8900';
  Result[15].Response := '02000000E24F4C4491AF';
  Result[16].Command := '90AF000000';
  Result[16].Response := '56341205E1D2760000850101002DF92EA32F22A5B69100';
end;
function DfTmacStandardWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,18);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F500000901A709321D9022932200';
  Result[13].Response := '0500F0EF0234A3DBCA3E22B5233C9100';
  Result[14].Command := '90C70000090171635D463985581800';
  Result[14].Response := '01000000CE8C4411FEE732D2D9096F5EEDB8C4189100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '90AD00000F00020000040000C9DEE8F8FD07B69600';
  Result[16].Response := 'FAB3D8354D83280EE86B297CFDCCADFA46DF6CA8F977BF859100';
  Result[17].Command := '90F5000009006BF71ECCD1FEC69100';
  Result[17].Response := '00030000080000B99999740B9C34809100';
end;
function DfTmacStandardOverlap: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F00030000020000DCC4523C6916678A00';
  Result[14].Response := 'BD4DEC5E571DBA1A7A89845B10AB8236E4E7F3894D753DC19100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F0003000002000065EE0304668328A539ED0A42B543201AE42E4EEAFF43B05100';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00030000020000306F06F3A5DCDC0B00';
  Result[17].Response := 'EAAA37773469441C1EC6A3A9E095D27FFC8835CD86F598B49100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '01000000E9DA5EC82619B00468DB1AB3F97EFE2F9100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F0002000004000032C8999A513BFC0500';
  Result[22].Response := '2B10D933910777531943F5E2712A74440D92B55ED8340F0D9100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F0003000002000099CD883367F711EF00';
  Result[25].Response := '14C817A55A7FF6751D4D2A9CA439B0952A207B0647A0AF609100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardDisjoint: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F000000000200006E5CC666AFC62D3500';
  Result[8].Response := '66F60A7B98F8128DCB317DDD3C3029B6F7B15C74293945389100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F0000000002000085F65EFB8667F132955DB617C0AE1B59381FAE06FAC0A32D00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F000000000200005022A9C2FEA1C4F200';
  Result[11].Response := 'FDEA37AA0F53D030A618660D1B743EE4AC9BC364F2FA6FDA9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F00060000020000999F35A78F2D771A00';
  Result[14].Response := '1CE929F9A6C95239343D5F2FFE2CAF115A3681A2D8B07E3F9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F000600000200005C0EBADDCAF7885F0EB327823F86B804CB3DF5B3C261705500';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00060000020000D4D15B6D5BD5E2D100';
  Result[17].Response := '3B4DE5D33A80D161337B16CC0EB6C1DBDCAD4E7276CF1F2D9100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '01000000081FE2E81BC103EF732DC4CBC8F765219100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F000000000200001DC73049277C208B00';
  Result[22].Response := 'E91A50090C0EC00DD3D29E27CABF5E32CC12F484F4C96D279100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F000600000200008ADF83580BA4F5AB00';
  Result[25].Response := 'CF57C7BBBF3CC6DEF98D748644A4CBC4AF15399B57E8D31B9100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardNoop: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '90F500000901BD9E1EE3DAE270A200';
  Result[10].Response := '0500F0EF0234FEA7D038B648C7B99100';
  Result[11].Command := '90C7000009017DBEC65F62F8F97800';
  Result[11].Response := '010000004B76CE5D0DCD3B0FAF23C8CD2FAF042C9100';
end;
function DfTmacStandardAbort: TExtendedPairs;
begin
  Result := nil; SetLength(Result,14);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90A7000008A67C6ACD1805183700';
  Result[13].Response := 'F45ECAB117B00EE09100';
end;
function DfTmacStandardRepeat: TExtendedPairs;
begin
  Result := nil; SetLength(Result,27);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F5000009002F375AAD1953B61B00';
  Result[13].Response := '0003000008000009799F67A5AB9DDC9100';
  Result[14].Command := '90AD00000F0002000004000098F01F2E3955B56700';
  Result[14].Response := '1F564073D7AF62E107760B0306C044C367B8E805C5B9C6FD9100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '908D00001F000200000400004EB9D24CF6819DF3DD0B72F1269D3732FDAD4948ABA9D77500';
  Result[16].Response := '72256E5ADC44636D9100';
  Result[17].Command := '90AD00000F00020000040000DDC9E0F3489A885500';
  Result[17].Response := 'CCDAE2032BC1D2B351CD0DF8C5FAE4DC86696E11BD27F4059100';
  Result[18].Command := '90F50000090010834270A478EF8500';
  Result[18].Response := '00030000080000602B9405BB3154AA9100';
  Result[19].Command := '90F500000901655F0EBCF1EA180F00';
  Result[19].Response := '0500F0EF02340084EEA36F021E699100';
  Result[20].Command := '90C700000901EB1C5F898013DB1900';
  Result[20].Response := '0100000028A4C4706990BA79875AF4D425A116FC9100';
  Result[21].Command := '90F500000900011382CCAE703DCF00';
  Result[21].Response := '00030000080000F0679ABCF03A86429100';
  Result[22].Command := '90AD00000F0002000004000032C8999A513BFC0500';
  Result[22].Response := '644039ABD05137D4B6858618356D8C70226569713E8828119100';
  Result[23].Command := '90F500000900C248A61FEC03E17600';
  Result[23].Response := '00030000080000E7F12B709606961E9100';
  Result[24].Command := '90F500000900E6EE352662BBC37A00';
  Result[24].Response := '000300000800006EB861AEE02D8E9E9100';
  Result[25].Command := '90AD00000F00020000040000E20079BC694DD3C200';
  Result[25].Response := '372D0AE0D54EBF6F2AE670645F97E8C42AE22F6009D8BBDC9100';
  Result[26].Command := '90F500000900C7DA9ECA18EA8CEC00';
  Result[26].Response := '00030000080000723359DBCF3CA9D29100';
end;
function DfTmacStandardPreimage: TExtendedPairs;
begin
  Result := nil; SetLength(Result,10);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
end;
function DfTmacStandardImmediateMismatch: TExtendedPairs;
begin
  Result := nil; SetLength(Result,12);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '060FF812981C8D16CBBD9929177A027687BC0E1C1464A0559100';
end;
function DfTmacStandardCommitMismatch: TExtendedPairs;
begin
  Result := nil; SetLength(Result,17);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
  Result[8].Command := '90AD00000F00020000040000E1E48F5E9ED361A600';
  Result[8].Response := '768820CA17EF864008A87251D458EE391ADA4C7BD0809C3C9100';
  Result[9].Command := '90F500000900E6C48DB58B3A4E5000';
  Result[9].Response := '000300000800004F2F4025276D981F9100';
  Result[10].Command := '908D00001F00020000040000FF45F7B48A16322A2176FB5A3196D3294B07F7D610DD216A00';
  Result[10].Response := 'DCF5C762E10055089100';
  Result[11].Command := '90AD00000F0002000004000012D220B25A9C003B00';
  Result[11].Response := '38EFC37599D6B7D3B546F3FA405D4783527E53078AF275DD9100';
  Result[12].Command := '90F50000090008B058DF21788E4A00';
  Result[12].Response := '000300000800006C5A9ACE4E0D15589100';
  Result[13].Command := '90F500000901A709321D9022932200';
  Result[13].Response := '0500F0EF0234A3DBCA3E22B5233C9100';
  Result[14].Command := '90C70000090171635D463985581800';
  Result[14].Response := '01000000CE8C4411FEE732D2D9096F5EEDB8C4189100';
  Result[15].Command := '90F50000090009EC3F2BEDE4E96E00';
  Result[15].Response := '000300000800006D2FC62BE038C6CB9100';
  Result[16].Command := '90AD00000F00020000040000C9DEE8F8FD07B69600';
  Result[16].Response := '92B839A2D94255534714467D1E5BA18AE0DF206241D1D8369100';
end;
function DfTmacStandardDeniedWrite: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0003F00F080000559E30FA720FBA4D9100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0003F00F0800001A9BD622459E11569100';
end;
function DfTmacStandardDeniedRead: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '0003F0F0080000B787B9185CE391709100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '0003F0F008000077945004613DBFF79100';
end;
function DfTmacStandardWrongFile: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '01030000080000C01AC4857CB7DA999100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '01030000080000FE734FDB6FA97D669100';
end;
function DfTmacStandardBounds: TExtendedPairs;
begin
  Result := nil; SetLength(Result,8);
  Result[0].Command := '905A00000301000000';
  Result[0].Response := '9100';
  Result[1].Command := '9071000002000000';
  Result[1].Response := '659F2ABFC5BC0708FB96E7A44AF9D59591AF';
  Result[2].Command := '90AF0000203B50445F21D21D77D500794DEB245E5AE06311AD0A25E1B100BA29D33DAF3F3500';
  Result[2].Response := '79087FC6E02C870D256F0F54D097C887CA74FEEA1314CED1ABFCA97E950F631A9100';
  Result[3].Command := '906F000008B8A773BEDD5F982B00';
  Result[3].Response := '0001DA8CC717E990CDDC9100';
  Result[4].Command := '90F5000009001F9015C357E6E7C000';
  Result[4].Response := '00030000080000D7A0D21985DAD3A99100';
  Result[5].Command := '90F50000090112257581972D316000';
  Result[5].Response := '0500F0EF02347427680484294D489100';
  Result[6].Command := '90510000084895FFB41CAB99D900';
  Result[6].Response := 'D9B0901C6551F4AA3FDEAD0728B8A455352D7CD5EEA8AF569100';
  Result[7].Command := '90F5000009008428DE102013DFA700';
  Result[7].Response := '000300000800006294F3B40A6CEEEA9100';
end;
end.
