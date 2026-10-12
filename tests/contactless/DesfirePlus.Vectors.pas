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
end.
