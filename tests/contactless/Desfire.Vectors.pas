unit Desfire.Vectors;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

type
  /// <summary>Synthetic independently generated command/response pair; contains published test keys only.</summary>
  TDesfireWirePair = record
    /// <summary>Literal complete wrapped command hex.</summary>
    Command: string;
    /// <summary>Literal complete response hex, including native status.</summary>
    Response: string;
  end;
  /// <summary>Owned ordered synthetic transcript.</summary>
  TDesfireWirePairs = array of TDesfireWirePair;

/// <summary>Returns independently generated synthetic Ev2ReadPlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadPlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WritePlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WritePlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WritePlainChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WritePlainChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WriteMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WriteMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WriteMacChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WriteMacChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WriteFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WriteFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WriteFullChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WriteFullChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadBackup transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadBackup: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadValue transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadValue: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadLinear transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadLinear: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2ReadCyclic transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2ReadCyclic: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2Directory transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2Directory: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2DeniedRead transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2DeniedRead: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2WriteWithoutRead transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2WriteWithoutRead: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic PublicWriteChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function PublicWriteChained: TDesfireWirePairs;

implementation

function Ev2ReadPlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00000000200000B5C6E64A1EB7E6D39100';
  Result[4].Command:='90AD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F1011121314151617189100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00000000200000AADA2424B1DC45529100';
end;

function Ev2WritePlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00000000200000B5C6E64A1EB7E6D39100';
  Result[4].Command:='90AD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F1011121314151617189100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00000000200000AADA2424B1DC45529100';
  Result[6].Command:='908D000020000000001900002222222222222222222222222222222222222222222222222200';
  Result[6].Response:='9100';
  Result[7].Command:='90AD0000070000000019000000';
  Result[7].Response:='222222222222222222222222222222222222222222222222229100';
  Result[8].Command:='90F500000900052CDFF01D36A18300';
  Result[8].Response:='00000000200000B452148AD974ADC09100';
end;

function Ev2WritePlainChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,22);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0000000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='B5C6E64A1EB7E691AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='D39100';
  Result[6].Command:='90AD0000070000000019000000';
  Result[6].Response:='0001020304050691AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='0708090A0B0C0D91AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='0E0F101112131491AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='151617189100';
  Result[10].Command:='90F500000900E6D90E75774A4C3700';
  Result[10].Response:='0000000020000091AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='AADA2424B1DC4591AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='529100';
  Result[13].Command:='908D0000100000000019000022222222222222222200';
  Result[13].Response:='91AF';
  Result[14].Command:='90AF0000102222222222222222222222222222222200';
  Result[14].Response:='9100';
  Result[15].Command:='90AD0000070000000019000000';
  Result[15].Response:='2222222222222291AF';
  Result[16].Command:='90AF000000';
  Result[16].Response:='2222222222222291AF';
  Result[17].Command:='90AF000000';
  Result[17].Response:='2222222222222291AF';
  Result[18].Command:='90AF000000';
  Result[18].Response:='222222229100';
  Result[19].Command:='90F500000900052CDFF01D36A18300';
  Result[19].Response:='0000000020000091AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='B452148AD974AD91AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='C09100';
end;

function Ev2ReadMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0001000020000005BD39D216D298009100';
  Result[4].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F101112131415161718893D13DCF4E028179100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00010000200000F3C7B33EFDF6EDBB9100';
end;

function Ev2WriteMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0001000020000005BD39D216D298009100';
  Result[4].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F101112131415161718893D13DCF4E028179100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00010000200000F3C7B33EFDF6EDBB9100';
  Result[6].Command:='908D00002800000000190000222222222222222222222222222222222222222222222222228C0CABE01C0D07BB00';
  Result[6].Response:='2EE19EB463051C689100';
  Result[7].Command:='90AD00000F00000000190000E18286A367BFD9ED00';
  Result[7].Response:='2222222222222222222222222222222222222222222222222232237DEB87C38E4F9100';
  Result[8].Command:='90F500000900052CDFF01D36A18300';
  Result[8].Response:='00010000200000835BE22825FE45989100';
end;

function Ev2WriteMacChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,26);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0001000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='05BD39D216D29891AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='009100';
  Result[6].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[6].Response:='0001020304050691AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='0708090A0B0C0D91AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='0E0F101112131491AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='15161718893D1391AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='DCF4E028179100';
  Result[11].Command:='90F500000900E6D90E75774A4C3700';
  Result[11].Response:='0001000020000091AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='F3C7B33EFDF6ED91AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='BB9100';
  Result[14].Command:='908D0000100000000019000022222222222222222200';
  Result[14].Response:='91AF';
  Result[15].Command:='90AF0000102222222222222222222222222222222200';
  Result[15].Response:='91AF';
  Result[16].Command:='90AF0000088C0CABE01C0D07BB00';
  Result[16].Response:='2EE19EB463051C91AF';
  Result[17].Command:='90AF000000';
  Result[17].Response:='689100';
  Result[18].Command:='90AD00000F00000000190000E18286A367BFD9ED00';
  Result[18].Response:='2222222222222291AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='2222222222222291AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='2222222222222291AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='2222222232237D91AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='EB87C38E4F9100';
  Result[23].Command:='90F500000900052CDFF01D36A18300';
  Result[23].Response:='0001000020000091AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='835BE22825FE4591AF';
  Result[25].Command:='90AF000000';
  Result[25].Response:='989100';
end;

function Ev2ReadFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='000300002000004E197857F6B8DAC69100';
  Result[4].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[4].Response:='EDA39596ACFEF9B7DAC14FEADCA1913823C092BD2312F0F836205DE9B91AF2A86AC9ADC3EA9DB0119100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00030000200000F2B021C7608A6F8C9100';
end;

function Ev2WriteFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='000300002000004E197857F6B8DAC69100';
  Result[4].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[4].Response:='EDA39596ACFEF9B7DAC14FEADCA1913823C092BD2312F0F836205DE9B91AF2A86AC9ADC3EA9DB0119100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='00030000200000F2B021C7608A6F8C9100';
  Result[6].Command:='908D00002F000000001900009FE96D37C41E283DF41084AE5D94B372D7E3EEC518C69FEE8B8B46FB0C67F751AEAD3CEAB63DF82B00';
  Result[6].Response:='2EE19EB463051C689100';
  Result[7].Command:='90AD00000F00000000190000E18286A367BFD9ED00';
  Result[7].Response:='C4CB886804BBE9C01F0E9CA057A86865FA52555B122F4E5CF96D91870D622C140A960DFD5B0B70469100';
  Result[8].Command:='90F500000900052CDFF01D36A18300';
  Result[8].Response:='00030000200000FA93133E8517C0659100';
end;

function Ev2WriteFullChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,28);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0003000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='4E197857F6B8DA91AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='C69100';
  Result[6].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[6].Response:='EDA39596ACFEF991AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='B7DAC14FEADCA191AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='913823C092BD2391AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='12F0F836205DE991AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='B91AF2A86AC9AD91AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='C3EA9DB0119100';
  Result[12].Command:='90F500000900E6D90E75774A4C3700';
  Result[12].Response:='0003000020000091AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='F2B021C7608A6F91AF';
  Result[14].Command:='90AF000000';
  Result[14].Response:='8C9100';
  Result[15].Command:='908D000010000000001900009FE96D37C41E283DF400';
  Result[15].Response:='91AF';
  Result[16].Command:='90AF0000101084AE5D94B372D7E3EEC518C69FEE8B00';
  Result[16].Response:='91AF';
  Result[17].Command:='90AF00000F8B46FB0C67F751AEAD3CEAB63DF82B00';
  Result[17].Response:='2EE19EB463051C91AF';
  Result[18].Command:='90AF000000';
  Result[18].Response:='689100';
  Result[19].Command:='90AD00000F00000000190000E18286A367BFD9ED00';
  Result[19].Response:='C4CB886804BBE991AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='C01F0E9CA057A891AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='6865FA52555B1291AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='2F4E5CF96D918791AF';
  Result[23].Command:='90AF000000';
  Result[23].Response:='0D622C140A960D91AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='FD5B0B70469100';
  Result[25].Command:='90F500000900052CDFF01D36A18300';
  Result[25].Response:='0003000020000091AF';
  Result[26].Command:='90AF000000';
  Result[26].Response:='FA93133E8517C091AF';
  Result[27].Command:='90AF000000';
  Result[27].Response:='659100';
end;

function Ev2ReadBackup: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='010300002000005B962CD80C18E6C39100';
  Result[4].Command:='90AD00000F000000001900007069910147E66AB900';
  Result[4].Response:='EDA39596ACFEF9B7DAC14FEADCA1913823C092BD2312F0F836205DE9B91AF2A86AC9ADC3EA9DB0119100';
  Result[5].Command:='90F500000900E6D90E75774A4C3700';
  Result[5].Response:='01030000200000834AF1E3591B86539100';
end;

function Ev2ReadValue: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000902F75E91FABFB99DAB00';
  Result[3].Response:='020300009CFFFFFF64000000000000000091B0FCC0937D19A49100';
  Result[4].Command:='906C00000902E9F3D96648EC760D00';
  Result[4].Response:='C6FE3E8E17E31EAB061215EAE65D49C4C4861A59B5A475B89100';
  Result[5].Command:='90F5000009029F2AF2D840D51E4C00';
  Result[5].Response:='020300009CFFFFFF640000000000000000EBDC2DA5B77001099100';
end;

function Ev2ReadLinear: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F50000090386BBFCD7466BDD4500';
  Result[3].Response:='03030000040000030000020000CC76B20332FDA3D19100';
  Result[4].Command:='90AB00000F03000000020000A1995D4A528A63D800';
  Result[4].Response:='078033C118601E5356A824DBEEBD29E17EE0587E9E37C92A9100';
  Result[5].Command:='90F5000009039FD2870DC716986800';
  Result[5].Response:='03030000040000030000020000DC306C3E053ED8019100';
end;

function Ev2ReadCyclic: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F50000090448172BA65C64597300';
  Result[3].Response:='040300000400000300000200006287B0B8EE0CD99D9100';
  Result[4].Command:='90AB00000F0400000002000006F40C4B00B2CB2200';
  Result[4].Response:='078033C118601E5356A824DBEEBD29E17EE0587E9E37C92A9100';
  Result[5].Command:='90F5000009041A862E9EE46C38EC00';
  Result[5].Response:='04030000040000030000020000018CD38E30F76A0F9100';
end;

function Ev2Directory: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='906F000000';
  Result[1].Response:='00010203049100';
  Result[2].Command:='9071000002000000';
  Result[2].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[3].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[3].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[4].Command:='90F500000900CA78BF43070253F000';
  Result[4].Response:='000300002000004E197857F6B8DAC69100';
  Result[5].Command:='90F5000009013E6E3A7494582EDE00';
  Result[5].Response:='01030000200000DB5EF5DE153D014A9100';
  Result[6].Command:='90F5000009029F2AF2D840D51E4C00';
  Result[6].Response:='020300009CFFFFFF640000000000000000EBDC2DA5B77001099100';
  Result[7].Command:='90F500000903031383A122BEA1D900';
  Result[7].Response:='0303000004000003000002000000A47E26A669457B9100';
  Result[8].Command:='90F500000904F5D2CAD62C09BC3E00';
  Result[8].Response:='0403000004000003000002000042EDAB2593A76FBB9100';
end;

function Ev2DeniedRead: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00031010200000FE64652B0CE608C69100';
end;

function Ev2WriteWithoutRead: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,4);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0003F0F0200000824BFEC9D63AEEDA9100';
end;

function PublicWriteChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,14);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90F50000010000';
  Result[1].Response:='0000EEEEE803009100';
  Result[2].Command:='90BD0000070000000019000000';
  Result[2].Response:='0001020304050691AF';
  Result[3].Command:='90AF000000';
  Result[3].Response:='0708090A0B0C0D91AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='0E0F101112131491AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='151617189100';
  Result[6].Command:='90F50000010000';
  Result[6].Response:='0000EEEEE803009100';
  Result[7].Command:='903D0000100000000019000022222222222222222200';
  Result[7].Response:='91AF';
  Result[8].Command:='90AF0000102222222222222222222222222222222200';
  Result[8].Response:='9100';
  Result[9].Command:='90BD0000070000000019000000';
  Result[9].Response:='2222222222222291AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='2222222222222291AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='2222222222222291AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='222222229100';
  Result[13].Command:='90F50000010000';
  Result[13].Response:='0000EEEEE803009100';
end;

end.
