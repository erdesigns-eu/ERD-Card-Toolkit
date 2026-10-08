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
/// <summary>Returns independently generated synthetic Ev1ReadPlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadPlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WritePlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WritePlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WritePlainChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WritePlainChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WriteMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WriteMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WriteMacChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WriteMacChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WriteFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WriteFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1WriteFullChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1WriteFullChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadBackup transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadBackup: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadValue transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadValue: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLinear transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLinear: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadCyclic transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadCyclic: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLength12 transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLength12: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLength13 transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLength13: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLength16 transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLength16: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLength28 transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLength28: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadLength29 transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadLength29: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadBadCrc transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadBadCrc: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadBadPadding transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadBadPadding: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1ReadMarkerPadding transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1ReadMarkerPadding: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadPlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadPlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWritePlain transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWritePlain: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWritePlainChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWritePlainChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWriteMac transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWriteMac: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWriteMacChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWriteMacChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWriteFull transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWriteFull: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstWriteFullChained transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstWriteFullChained: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadBackup transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadBackup: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadValue transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadValue: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadLinear transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadLinear: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev2NonFirstReadCyclic transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev2NonFirstReadCyclic: TDesfireWirePairs;
/// <summary>Returns independently generated synthetic Ev1Directory transcript.</summary>
/// <returns>Owned command/response pairs, never physical card data.</returns>
function Ev1Directory: TDesfireWirePairs;

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

function Ev1ReadPlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00000000200000E9B11C8A037806EC9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F1011121314151617184DF556093D3B5F599100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00000000200000EF7FFDC0AEAF99659100';
end;

function Ev1WritePlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00000000200000E9B11C8A037806EC9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F1011121314151617184DF556093D3B5F599100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00000000200000EF7FFDC0AEAF99659100';
  Result[6].Command:='903D000020000000001900002222222222222222222222222222222222222222222222222200';
  Result[6].Response:='0B3137733C65400C9100';
  Result[7].Command:='90BD0000070000000019000000';
  Result[7].Response:='22222222222222222222222222222222222222222222222222349D9DC5DE6A37769100';
  Result[8].Command:='90F50000010000';
  Result[8].Response:='00000000200000AD18147DCE0E16339100';
end;

function Ev1WritePlainChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,25);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='0000000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='E9B11C8A03780691AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='EC9100';
  Result[6].Command:='90BD0000070000000019000000';
  Result[6].Response:='0001020304050691AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='0708090A0B0C0D91AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='0E0F101112131491AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='151617184DF55691AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='093D3B5F599100';
  Result[11].Command:='90F50000010000';
  Result[11].Response:='0000000020000091AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='EF7FFDC0AEAF9991AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='659100';
  Result[14].Command:='903D0000100000000019000022222222222222222200';
  Result[14].Response:='91AF';
  Result[15].Command:='90AF0000102222222222222222222222222222222200';
  Result[15].Response:='0B3137733C654091AF';
  Result[16].Command:='90AF000000';
  Result[16].Response:='0C9100';
  Result[17].Command:='90BD0000070000000019000000';
  Result[17].Response:='2222222222222291AF';
  Result[18].Command:='90AF000000';
  Result[18].Response:='2222222222222291AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='2222222222222291AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='22222222349D9D91AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='C5DE6A37769100';
  Result[22].Command:='90F50000010000';
  Result[22].Response:='0000000020000091AF';
  Result[23].Command:='90AF000000';
  Result[23].Response:='AD18147DCE0E1691AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='339100';
end;

function Ev1ReadMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='000100002000007C5D4C3F0EB92B3A9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F101112131415161718DE0083DDD6F94E259100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='000100002000001323C7ABE68CFB1A9100';
end;

function Ev1WriteMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='000100002000007C5D4C3F0EB92B3A9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='000102030405060708090A0B0C0D0E0F101112131415161718DE0083DDD6F94E259100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='000100002000001323C7ABE68CFB1A9100';
  Result[6].Command:='903D000028000000001900002222222222222222222222222222222222222222222222222283EA3CC110A0099900';
  Result[6].Response:='99F6B73392B8273E9100';
  Result[7].Command:='90BD0000070000000019000000';
  Result[7].Response:='22222222222222222222222222222222222222222222222222BCAB50D94133281D9100';
  Result[8].Command:='90F50000010000';
  Result[8].Response:='00010000200000F3E67B4179DA52269100';
end;

function Ev1WriteMacChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,26);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='0001000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='7C5D4C3F0EB92B91AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='3A9100';
  Result[6].Command:='90BD0000070000000019000000';
  Result[6].Response:='0001020304050691AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='0708090A0B0C0D91AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='0E0F101112131491AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='15161718DE008391AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='DDD6F94E259100';
  Result[11].Command:='90F50000010000';
  Result[11].Response:='0001000020000091AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='1323C7ABE68CFB91AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='1A9100';
  Result[14].Command:='903D0000100000000019000022222222222222222200';
  Result[14].Response:='91AF';
  Result[15].Command:='90AF0000102222222222222222222222222222222200';
  Result[15].Response:='91AF';
  Result[16].Command:='90AF00000883EA3CC110A0099900';
  Result[16].Response:='99F6B73392B82791AF';
  Result[17].Command:='90AF000000';
  Result[17].Response:='3E9100';
  Result[18].Command:='90BD0000070000000019000000';
  Result[18].Response:='2222222222222291AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='2222222222222291AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='2222222222222291AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='22222222BCAB5091AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='D94133281D9100';
  Result[23].Command:='90F50000010000';
  Result[23].Response:='0001000020000091AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='F3E67B4179DA5291AF';
  Result[25].Command:='90AF000000';
  Result[25].Response:='269100';
end;

function Ev1ReadFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='C27EC18B2DDF0376FF085C3916FBD0B1AB3E86879738F8B7A640778F665BCDD89100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000BB66EE7E6B3A7BB19100';
end;

function Ev1WriteFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='C27EC18B2DDF0376FF085C3916FBD0B1AB3E86879738F8B7A640778F665BCDD89100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000BB66EE7E6B3A7BB19100';
  Result[6].Command:='903D0000270000000019000045421325AE49DB687856C3EF8591EA9757C18AA017679B1C8D33E70F74AFC1DC00';
  Result[6].Response:='813F685D6C7A0CDD9100';
  Result[7].Command:='90BD0000070000000019000000';
  Result[7].Response:='F26E86539303E49A5E2EB916870A80A07988E874553712BC2CD8BCF3F118A6889100';
  Result[8].Command:='90F50000010000';
  Result[8].Response:='000300002000007DC1D0C345E595119100';
end;

function Ev1WriteFullChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,26);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='0003000020000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='686C51D9DF26CA91AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='7F9100';
  Result[6].Command:='90BD0000070000000019000000';
  Result[6].Response:='C27EC18B2DDF0391AF';
  Result[7].Command:='90AF000000';
  Result[7].Response:='76FF085C3916FB91AF';
  Result[8].Command:='90AF000000';
  Result[8].Response:='D0B1AB3E86879791AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='38F8B7A640778F91AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='665BCDD89100';
  Result[11].Command:='90F50000010000';
  Result[11].Response:='0003000020000091AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='BB66EE7E6B3A7B91AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='B19100';
  Result[14].Command:='903D0000100000000019000045421325AE49DB687800';
  Result[14].Response:='91AF';
  Result[15].Command:='90AF00001056C3EF8591EA9757C18AA017679B1C8D00';
  Result[15].Response:='91AF';
  Result[16].Command:='90AF00000733E70F74AFC1DC00';
  Result[16].Response:='813F685D6C7A0C91AF';
  Result[17].Command:='90AF000000';
  Result[17].Response:='DD9100';
  Result[18].Command:='90BD0000070000000019000000';
  Result[18].Response:='F26E86539303E491AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='9A5E2EB916870A91AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='80A07988E8745591AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='3712BC2CD8BCF391AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='F118A6889100';
  Result[23].Command:='90F50000010000';
  Result[23].Response:='0003000020000091AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='7DC1D0C345E59591AF';
  Result[25].Command:='90AF000000';
  Result[25].Response:='119100';
end;

function Ev1ReadBackup: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='010300002000007F3EBC3A6906DFCE9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='7EB6378869E7D8D3DA266FF40D88B528B6331612EF99538C89FB2A7F352D89F19100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='01030000200000289E0671E3CBC58C9100';
end;

function Ev1ReadValue: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010200';
  Result[3].Response:='020300009CFFFFFF640000000000000000B7CF4B84D1BE54519100';
  Result[4].Command:='906C0000010200';
  Result[4].Response:='CA014D0FF013F0ADF3BDA71699AD66D59100';
  Result[5].Command:='90F50000010200';
  Result[5].Response:='020300009CFFFFFF640000000000000000258D5CA1F144867F9100';
end;

function Ev1ReadLinear: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010300';
  Result[3].Response:='03030000040000030000020000A7147972A02BA76C9100';
  Result[4].Command:='90BB0000070300000002000000';
  Result[4].Response:='75B0E30845526FD158FF4CD22768C6B29100';
  Result[5].Command:='90F50000010300';
  Result[5].Response:='030300000400000300000200004ED9AA80E9ADD9119100';
end;

function Ev1ReadCyclic: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010400';
  Result[3].Response:='04030000040000030000020000CC3B9F274B9BADB39100';
  Result[4].Command:='90BB0000070400000002000000';
  Result[4].Response:='985F4D58765D75EDB22BFCE98E83236F9100';
  Result[5].Command:='90F50000010400';
  Result[5].Response:='040300000400000300000200008F87B9149AE232579100';
end;

function Ev1ReadLength12: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD000007000000000C000000';
  Result[4].Response:='2F1C07FC28A0792E240C416B93C1FD359100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='0003000020000013C1A9A247F3D9AE9100';
end;

function Ev1ReadLength13: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD000007000000000D000000';
  Result[4].Response:='4654CA8A228866497CBC629EF21FB3376EFDCD1ABD4E8A66FE3DD586EE8BD0169100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='000300002000001E717325EDF794109100';
end;

function Ev1ReadLength16: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000010000000';
  Result[4].Response:='3CFA0D904161AFF375EAA2A89E6423FC4AA0E89071A7763C0BB86F7207EE64939100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='0003000020000005B7F62FC250E2C59100';
end;

function Ev1ReadLength28: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD000007000000001C000000';
  Result[4].Response:='B9B5C52A26269B78924240200FC3AD5886F7A025CC50E085C0536800C540F99F9100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000B473B8380E4303ED9100';
end;

function Ev1ReadLength29: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD000007000000001D000000';
  Result[4].Response:='C3BE4F7143933D60DCB15F96A33C6CAB3EED33CD3FE321AC0FA6CC4BD44EC565C1ACCD940D83CF2A350A4D156EA34B799100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000817D78365B08A7919100';
end;

function Ev1ReadBadCrc: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='C27EC18B2DDF0376FF085C3916FBD0B11E1CF6D0736024CBA44198E4047E38B79100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000DF7C6A92364869559100';
end;

function Ev1ReadBadPadding: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='C27EC18B2DDF0376FF085C3916FBD0B12C902C0CAB632DA80D54063A67974FB49100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='000300002000000A4461AE1ECDB52F9100';
end;

function Ev1ReadMarkerPadding: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,6);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='90AA0000010000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[2].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[3].Command:='90F50000010000';
  Result[3].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[4].Command:='90BD0000070000000019000000';
  Result[4].Response:='C27EC18B2DDF0376FF085C3916FBD0B1F2316DEEF50C5CC5B4B4CDD6BDBF8F109100';
  Result[5].Command:='90F50000010000';
  Result[5].Response:='00030000200000860A21134CC0B0519100';
end;

function Ev2NonFirstReadPlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0000101120000044904599D9E80C409100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD0000070000000019000000';
  Result[6].Response:='000102030405060708090A0B0C0D0E0F1011121314151617189100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='000010112000002B557F97EF8176099100';
end;

function Ev2NonFirstWritePlain: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,11);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0000101120000044904599D9E80C409100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD0000070000000019000000';
  Result[6].Response:='000102030405060708090A0B0C0D0E0F1011121314151617189100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='000010112000002B557F97EF8176099100';
  Result[8].Command:='908D000020000000001900002222222222222222222222222222222222222222222222222200';
  Result[8].Response:='9100';
  Result[9].Command:='90AD0000070000000019000000';
  Result[9].Response:='222222222222222222222222222222222222222222222222229100';
  Result[10].Command:='90F500000900A64F038303BB7BB900';
  Result[10].Response:='0000101120000060B205002BA27F439100';
end;

function Ev2NonFirstWritePlainChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,24);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0000101120000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='44904599D9E80C91AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='409100';
  Result[6].Command:='90770000010100';
  Result[6].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[7].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[7].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[8].Command:='90AD0000070000000019000000';
  Result[8].Response:='0001020304050691AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='0708090A0B0C0D91AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='0E0F101112131491AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='151617189100';
  Result[12].Command:='90F50000090009B27884D84C3BE000';
  Result[12].Response:='0000101120000091AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='2B557F97EF817691AF';
  Result[14].Command:='90AF000000';
  Result[14].Response:='099100';
  Result[15].Command:='908D0000100000000019000022222222222222222200';
  Result[15].Response:='91AF';
  Result[16].Command:='90AF0000102222222222222222222222222222222200';
  Result[16].Response:='9100';
  Result[17].Command:='90AD0000070000000019000000';
  Result[17].Response:='2222222222222291AF';
  Result[18].Command:='90AF000000';
  Result[18].Response:='2222222222222291AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='2222222222222291AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='222222229100';
  Result[21].Command:='90F500000900A64F038303BB7BB900';
  Result[21].Response:='0000101120000091AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='60B205002BA27F91AF';
  Result[23].Command:='90AF000000';
  Result[23].Response:='439100';
end;

function Ev2NonFirstReadMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00011011200000D9126E9560C3A9049100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[6].Response:='000102030405060708090A0B0C0D0E0F101112131415161718B976BA08ADE6531B9100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='000110112000003C8499B63538858D9100';
end;

function Ev2NonFirstWriteMac: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,11);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00011011200000D9126E9560C3A9049100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[6].Response:='000102030405060708090A0B0C0D0E0F101112131415161718B976BA08ADE6531B9100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='000110112000003C8499B63538858D9100';
  Result[8].Command:='908D00002800000000190000222222222222222222222222222222222222222222222222220FE9915B8DA8B76200';
  Result[8].Response:='30A2E9B76DE8B72C9100';
  Result[9].Command:='90AD00000F0000000019000094DCFA5BA2AB134A00';
  Result[9].Response:='222222222222222222222222222222222222222222222222226E548C1B906F02C39100';
  Result[10].Command:='90F500000900A64F038303BB7BB900';
  Result[10].Response:='00011011200000A8C56568B875AFFE9100';
end;

function Ev2NonFirstWriteMacChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,28);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0001101120000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='D9126E9560C3A991AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='049100';
  Result[6].Command:='90770000010100';
  Result[6].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[7].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[7].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[8].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[8].Response:='0001020304050691AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='0708090A0B0C0D91AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='0E0F101112131491AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='15161718B976BA91AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='08ADE6531B9100';
  Result[13].Command:='90F50000090009B27884D84C3BE000';
  Result[13].Response:='0001101120000091AF';
  Result[14].Command:='90AF000000';
  Result[14].Response:='3C8499B635388591AF';
  Result[15].Command:='90AF000000';
  Result[15].Response:='8D9100';
  Result[16].Command:='908D0000100000000019000022222222222222222200';
  Result[16].Response:='91AF';
  Result[17].Command:='90AF0000102222222222222222222222222222222200';
  Result[17].Response:='91AF';
  Result[18].Command:='90AF0000080FE9915B8DA8B76200';
  Result[18].Response:='30A2E9B76DE8B791AF';
  Result[19].Command:='90AF000000';
  Result[19].Response:='2C9100';
  Result[20].Command:='90AD00000F0000000019000094DCFA5BA2AB134A00';
  Result[20].Response:='2222222222222291AF';
  Result[21].Command:='90AF000000';
  Result[21].Response:='2222222222222291AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='2222222222222291AF';
  Result[23].Command:='90AF000000';
  Result[23].Response:='222222226E548C91AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='1B906F02C39100';
  Result[25].Command:='90F500000900A64F038303BB7BB900';
  Result[25].Response:='0001101120000091AF';
  Result[26].Command:='90AF000000';
  Result[26].Response:='A8C56568B875AF91AF';
  Result[27].Command:='90AF000000';
  Result[27].Response:='FE9100';
end;

function Ev2NonFirstReadFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00031011200000284646910886D6419100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[6].Response:='A63E462E95DB654846F5C9F5BD3EAE5B98FCF65B970B92DAB2A866787EEB65A1E5089800F76876069100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='0003101120000014B30FB12E663F3A9100';
end;

function Ev2NonFirstWriteFull: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,11);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='00031011200000284646910886D6419100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[6].Response:='A63E462E95DB654846F5C9F5BD3EAE5B98FCF65B970B92DAB2A866787EEB65A1E5089800F76876069100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='0003101120000014B30FB12E663F3A9100';
  Result[8].Command:='908D00002F000000001900004F22221CE02B794A8A5EE03ED9E43527B1FFC331DE87B9845D732DF0DE4B8F3BF3B7A521273E439500';
  Result[8].Response:='30A2E9B76DE8B72C9100';
  Result[9].Command:='90AD00000F0000000019000094DCFA5BA2AB134A00';
  Result[9].Response:='4F0B2369E61A397EB9913C040DB98B9F25A449D04CEBFAFBB43D0CB1B1E4A414C751863E313A54199100';
  Result[10].Command:='90F500000900A64F038303BB7BB900';
  Result[10].Response:='000310112000003CCED9EF9E0C81D19100';
end;

function Ev2NonFirstWriteFullChained: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,30);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='0003101120000091AF';
  Result[4].Command:='90AF000000';
  Result[4].Response:='284646910886D691AF';
  Result[5].Command:='90AF000000';
  Result[5].Response:='419100';
  Result[6].Command:='90770000010100';
  Result[6].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[7].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[7].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[8].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[8].Response:='A63E462E95DB6591AF';
  Result[9].Command:='90AF000000';
  Result[9].Response:='4846F5C9F5BD3E91AF';
  Result[10].Command:='90AF000000';
  Result[10].Response:='AE5B98FCF65B9791AF';
  Result[11].Command:='90AF000000';
  Result[11].Response:='0B92DAB2A8667891AF';
  Result[12].Command:='90AF000000';
  Result[12].Response:='7EEB65A1E5089891AF';
  Result[13].Command:='90AF000000';
  Result[13].Response:='00F76876069100';
  Result[14].Command:='90F50000090009B27884D84C3BE000';
  Result[14].Response:='0003101120000091AF';
  Result[15].Command:='90AF000000';
  Result[15].Response:='14B30FB12E663F91AF';
  Result[16].Command:='90AF000000';
  Result[16].Response:='3A9100';
  Result[17].Command:='908D000010000000001900004F22221CE02B794A8A00';
  Result[17].Response:='91AF';
  Result[18].Command:='90AF0000105EE03ED9E43527B1FFC331DE87B9845D00';
  Result[18].Response:='91AF';
  Result[19].Command:='90AF00000F732DF0DE4B8F3BF3B7A521273E439500';
  Result[19].Response:='30A2E9B76DE8B791AF';
  Result[20].Command:='90AF000000';
  Result[20].Response:='2C9100';
  Result[21].Command:='90AD00000F0000000019000094DCFA5BA2AB134A00';
  Result[21].Response:='4F0B2369E61A3991AF';
  Result[22].Command:='90AF000000';
  Result[22].Response:='7EB9913C040DB991AF';
  Result[23].Command:='90AF000000';
  Result[23].Response:='8B9F25A449D04C91AF';
  Result[24].Command:='90AF000000';
  Result[24].Response:='EBFAFBB43D0CB191AF';
  Result[25].Command:='90AF000000';
  Result[25].Response:='B1E4A414C7518691AF';
  Result[26].Command:='90AF000000';
  Result[26].Response:='3E313A54199100';
  Result[27].Command:='90F500000900A64F038303BB7BB900';
  Result[27].Response:='0003101120000091AF';
  Result[28].Command:='90AF000000';
  Result[28].Response:='3CCED9EF9E0C8191AF';
  Result[29].Command:='90AF000000';
  Result[29].Response:='D19100';
end;

function Ev2NonFirstReadBackup: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000900CA78BF43070253F000';
  Result[3].Response:='010310112000006DC8CBDB8C7EBB2C9100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AD00000F00000000190000980779A96C88BF6B00';
  Result[6].Response:='A63E462E95DB654846F5C9F5BD3EAE5B98FCF65B970B92DAB2A866787EEB65A1E5089800F76876069100';
  Result[7].Command:='90F50000090009B27884D84C3BE000';
  Result[7].Response:='01031011200000E56C7C2296EF259F9100';
end;

function Ev2NonFirstReadValue: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F500000902F75E91FABFB99DAB00';
  Result[3].Response:='020310119CFFFFFF64000000000000000092FFF789C8C3D9B69100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='906C00000902267198BE9FE1476B00';
  Result[6].Response:='E35E17DDA8D308477CC0F0458273BED416A27400D2AE8AC89100';
  Result[7].Command:='90F50000090242C129B48F80887200';
  Result[7].Response:='020310119CFFFFFF640000000000000000E35F9F1727D96AAE9100';
end;

function Ev2NonFirstReadLinear: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F50000090386BBFCD7466BDD4500';
  Result[3].Response:='030310110400000300000200008C7794D4124349719100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AB00000F0300000002000022FAF3687B9333F600';
  Result[6].Response:='63354ED5561DB1A40D53A6C300DDF55D35CE89E0674D17569100';
  Result[7].Command:='90F5000009035C4BA233281991CC00';
  Result[7].Response:='03031011040000030000020000FCE97795506387C89100';
end;

function Ev2NonFirstReadCyclic: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,8);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='9071000002000000';
  Result[1].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[2].Command:='90AF0000203B50445F21D21D77D500794DEB245E5A754F5F901844259F4C9B31A5C7335ACD00';
  Result[2].Response:='04C6DBD67417ED0D31DDDE4D2E3FFAC2B4B074F638EEF7FFF9254963B65C77599100';
  Result[3].Command:='90F50000090448172BA65C64597300';
  Result[3].Response:='040310110400000300000200008BB3B5F40DA510C89100';
  Result[4].Command:='90770000010100';
  Result[4].Response:='F867844C0106A748F28A37DA526B511F91AF';
  Result[5].Command:='90AF0000200DBEDD87A7840AE695DE334E94D35E50E96978EA307EA1D65A246BB16B9E8D7F00';
  Result[5].Response:='2AC550660AC17019FAAE1D9C4DB9DC159100';
  Result[6].Command:='90AB00000F04000000020000DDE9CFE51660C77D00';
  Result[6].Response:='63354ED5561DB1A40D53A6C300DDF55D35CE89E0674D17569100';
  Result[7].Command:='90F500000904AA90C46E9549874000';
  Result[7].Response:='0403101104000003000002000070C176F332417D4D9100';
end;

function Ev1Directory: TDesfireWirePairs;
begin
  Result:=nil; SetLength(Result,9);
  Result[0].Command:='905A00000301EFCD00';
  Result[0].Response:='9100';
  Result[1].Command:='906F000000';
  Result[1].Response:='00010203049100';
  Result[2].Command:='90AA0000010000';
  Result[2].Response:='24677DDBD46349E623798FD729006E7991AF';
  Result[3].Command:='90AF000020E78D01C3FDBD5608F1230753B67AFD391CD17132129F6310610E0398E90E889200';
  Result[3].Response:='54EC58F32C3F9B62EE7DA1B3636B47299100';
  Result[4].Command:='90F50000010000';
  Result[4].Response:='00030000200000686C51D9DF26CA7F9100';
  Result[5].Command:='90F50000010100';
  Result[5].Response:='0103000020000010DE2CD2ECAF7D829100';
  Result[6].Command:='90F50000010200';
  Result[6].Response:='020300009CFFFFFF640000000000000000D424A247A61393949100';
  Result[7].Command:='90F50000010300';
  Result[7].Response:='03030000040000030000020000ABC34DD9EE4ABE799100';
  Result[8].Command:='90F50000010400';
  Result[8].Response:='040300000400000300000200001FF946498A40114F9100';
end;

end.
