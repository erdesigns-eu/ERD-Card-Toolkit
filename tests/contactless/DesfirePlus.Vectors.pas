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
end.
