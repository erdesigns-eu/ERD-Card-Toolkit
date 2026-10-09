unit LegacyMifare.Vectors;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
type
  /// <summary>Independent literal command/response pair using synthetic public credentials.</summary>
  TLegacyWirePair=record
    /// <summary>Exact outgoing bytes encoded as hex.</summary>
    Command:string;
    /// <summary>Exact incoming bytes including protocol framing.</summary>
    Response:string;
  end;
  /// <summary>Owned ordered protocol transcript.</summary>
  TLegacyWirePairs=array of TLegacyWirePair;
/// <summary>Independent synthetic D0M0W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M0W0:TLegacyWirePairs;
/// <summary>Independent synthetic D0M0W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M0W1:TLegacyWirePairs;
/// <summary>Independent synthetic S0M0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S0M0:TLegacyWirePairs;
/// <summary>Independent synthetic D0M1W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M1W0:TLegacyWirePairs;
/// <summary>Independent synthetic D0M1W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M1W1:TLegacyWirePairs;
/// <summary>Independent synthetic S0M1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S0M1:TLegacyWirePairs;
/// <summary>Independent synthetic D0M3W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M3W0:TLegacyWirePairs;
/// <summary>Independent synthetic D0M3W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D0M3W1:TLegacyWirePairs;
/// <summary>Independent synthetic S0M3 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S0M3:TLegacyWirePairs;
/// <summary>Independent synthetic C0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function C0:TLegacyWirePairs;
/// <summary>Independent synthetic D1M0W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M0W0:TLegacyWirePairs;
/// <summary>Independent synthetic D1M0W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M0W1:TLegacyWirePairs;
/// <summary>Independent synthetic S1M0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S1M0:TLegacyWirePairs;
/// <summary>Independent synthetic D1M1W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M1W0:TLegacyWirePairs;
/// <summary>Independent synthetic D1M1W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M1W1:TLegacyWirePairs;
/// <summary>Independent synthetic S1M1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S1M1:TLegacyWirePairs;
/// <summary>Independent synthetic D1M3W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M3W0:TLegacyWirePairs;
/// <summary>Independent synthetic D1M3W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D1M3W1:TLegacyWirePairs;
/// <summary>Independent synthetic S1M3 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S1M3:TLegacyWirePairs;
/// <summary>Independent synthetic C1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function C1:TLegacyWirePairs;
/// <summary>Independent synthetic D2M0W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M0W0:TLegacyWirePairs;
/// <summary>Independent synthetic D2M0W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M0W1:TLegacyWirePairs;
/// <summary>Independent synthetic S2M0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S2M0:TLegacyWirePairs;
/// <summary>Independent synthetic D2M1W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M1W0:TLegacyWirePairs;
/// <summary>Independent synthetic D2M1W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M1W1:TLegacyWirePairs;
/// <summary>Independent synthetic S2M1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S2M1:TLegacyWirePairs;
/// <summary>Independent synthetic D2M3W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M3W0:TLegacyWirePairs;
/// <summary>Independent synthetic D2M3W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D2M3W1:TLegacyWirePairs;
/// <summary>Independent synthetic S2M3 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S2M3:TLegacyWirePairs;
/// <summary>Independent synthetic C2 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function C2:TLegacyWirePairs;
/// <summary>Independent synthetic D3M0W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M0W0:TLegacyWirePairs;
/// <summary>Independent synthetic D3M0W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M0W1:TLegacyWirePairs;
/// <summary>Independent synthetic S3M0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S3M0:TLegacyWirePairs;
/// <summary>Independent synthetic D3M1W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M1W0:TLegacyWirePairs;
/// <summary>Independent synthetic D3M1W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M1W1:TLegacyWirePairs;
/// <summary>Independent synthetic S3M1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S3M1:TLegacyWirePairs;
/// <summary>Independent synthetic D3M3W0 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M3W0:TLegacyWirePairs;
/// <summary>Independent synthetic D3M3W1 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function D3M3W1:TLegacyWirePairs;
/// <summary>Independent synthetic S3M3 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function S3M3:TLegacyWirePairs;
/// <summary>Independent synthetic C3 transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function C3:TLegacyWirePairs;
/// <summary>Independent synthetic Uread transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function Uread:TLegacyWirePairs;
/// <summary>Independent synthetic Umemory transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function Umemory:TLegacyWirePairs;
/// <summary>Independent synthetic Uwrite transcript; never a production credential.</summary>
/// <returns>Owned fixed literal wire pairs.</returns>
function Uwrite:TLegacyWirePairs;
implementation
function D0M0W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00000000200000D2CED2883D54A1909100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607AC4E1E1506FB492E9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00000000200000FEBDAA7922DFA9C79100';
end;
function D0M0W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00000000200000D2CED2883D54A1909100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607AC4E1E1506FB492E9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00000000200000FEBDAA7922DFA9C79100';
 Result[6].Command:='903D00000B00040000040000AABBCCDD00';Result[6].Response:='E764E7B430971F319100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD849AA72E86BAFC6B9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='0000000020000078831358E03099819100';
end;
function S0M0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='906F000000';Result[3].Response:='0102030459C14D7103B36B629100';
 Result[4].Command:='90F50000010100';Result[4].Response:='01000000200000EFBCCDF498763A8B9100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020000009CFFFFFF6400000014000000017C91B7625FB9603F9100';
 Result[6].Command:='90F50000010300';Result[6].Response:='03000000040000030000020000F7BA91785E7F8D4D9100';
 Result[7].Command:='90F50000010400';Result[7].Response:='04000000040000030000030000C5AABC4B6F7C625E9100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010000002000007C65754799A2080C9100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1FEE770458858CDF4F9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='0100000020000034DB47908122F9979100';
 Result[11].Command:='903D00000B01040000040000AABBCCDD00';Result[11].Response:='DB0D1302DDEA44D09100';
 Result[12].Command:='90F50000010100';Result[12].Response:='01000000200000CE6503409265D5BF9100';
 Result[13].Command:='903D00000901060000020000EEFF00';Result[13].Response:='99821FA8C2DDBB139100';
 Result[14].Command:='90F50000010100';Result[14].Response:='01000000200000D7146CAA2A2138389100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020000009CFFFFFF6400000014000000013D8D1127F5925E8D9100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A000000CBB2FA945AEEE3549100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020000009CFFFFFF640000001400000001742AFA630868CB1E9100';
 Result[18].Command:='900C000005020A00000000';Result[18].Response:='6300AAF70FA6ACE59100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020000009CFFFFFF64000000140000000111FE65A7A45CB05C9100';
 Result[20].Command:='90DC000005020300000000';Result[20].Response:='405940CF07D8DC629100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020000009CFFFFFF64000000140000000134A828C1B59605D29100';
 Result[22].Command:='901C000005020200000000';Result[22].Response:='540DD09427B9D0799100';
 Result[23].Command:='90F50000010300';Result[23].Response:='03000000040000030000020000EA3F1313261F577F9100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='111213142122232467FA7DA41246116A9100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030000000400000300000200003CAC1ECBD23C46569100';
 Result[26].Command:='903B00000B030000000400004142434400';Result[26].Response:='C409E411614036619100';
 Result[27].Command:='90F50000010400';Result[27].Response:='04000000040000030000030000B80B6A32654A22499100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='1112131421222324313233342214842A2B29F76D9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='04000000040000030000030000112880F0F3A5FE739100';
 Result[30].Command:='903B00000B040000000400005152535400';Result[30].Response:='268BB738719B7E789100';
 Result[31].Command:='90F50000010400';Result[31].Response:='0400000004000003000003000046CE8E329ADCA24C9100';
 Result[32].Command:='903B00000B040000000400006162636400';Result[32].Response:='63F20D8F7494BFCD9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='0300000004000003000002000009AC8E51025BD89D9100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='5E74408589D1B2649100';
 Result[35].Command:='90F50000010300';Result[35].Response:='03000000040000030000020000FD8033922916243D9100';
 Result[36].Command:='903B00000B030000000400007172737400';Result[36].Response:='A5441A766AF48DD89100';
 Result[37].Command:='90C7000000';Result[37].Response:='4CB509AB8687C7129100';
 Result[38].Command:='90F50000010100';Result[38].Response:='01000000200000013E1B93556051EB9100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F6BD05B3C91D47D649100';
 Result[40].Command:='90F50000010100';Result[40].Response:='0100000020000085349B25E81502A49100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020000009CFFFFFF64000000140000000147A2AE2B032C8CCF9100';
 Result[42].Command:='906C0000010200';Result[42].Response:='13000000FE133B695558ED0B9100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020000009CFFFFFF6400000014000000019E73AF1AFEECC6809100';
 Result[44].Command:='90F50000010300';Result[44].Response:='03000000040000030000010000A3C1798B93DA69399100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='71727374FB102AE69D588CAC9100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030000000400000300000100001F747278FD067CB99100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040000000400000300000300005CFDBE7C47EB50699100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213145E7CB26F8DED10279100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040000000400000300000300003942A187C1B5A5279100';
end;
function D0M1W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000003C9012F5F0ABAF5F9100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='0405060703CD36BF5441BF1C9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000004D52EE19DEA3C7319100';
end;
function D0M1W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000003C9012F5F0ABAF5F9100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='0405060703CD36BF5441BF1C9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000004D52EE19DEA3C7319100';
 Result[6].Command:='903D00001300040000040000AABBCCDD17EC5B92B3569CCA00';Result[6].Response:='CBD0A2C9F7996C399100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD9A6BF2406DD1E0D59100';
 Result[8].Command:='90F50000010000';Result[8].Response:='00010000200000F85818A3046510699100';
end;
function S0M1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='906F000000';Result[3].Response:='0102030459C14D7103B36B629100';
 Result[4].Command:='90F50000010100';Result[4].Response:='01010000200000FAE88CA9DF79FD129100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020100009CFFFFFF640000001400000001CC26DF8165DDF91B9100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030100000400000300000200008DE2FC90651114DE9100';
 Result[7].Command:='90F50000010400';Result[7].Response:='0401000004000003000003000069DC74EC97D3FA7C9100';
 Result[8].Command:='90F50000010100';Result[8].Response:='01010000200000EC161E3D9BBA2EEB9100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1FDAC50ED3206CDFEC9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='01010000200000F0EA4B90B1C3BAE89100';
 Result[11].Command:='903D00001301040000040000AABBCCDD7A9864C3196D8B5600';Result[11].Response:='9D8C730BE3AC82149100';
 Result[12].Command:='90F50000010100';Result[12].Response:='0101000020000021C1FE31EF8934BA9100';
 Result[13].Command:='903D00001101060000020000EEFFDF6EE468B47980DE00';Result[13].Response:='E2E99B1300EBB85E9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010100002000002C2F0FEDEC9BFCF39100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020100009CFFFFFF640000001400000001A367EBBFA5F6CAE19100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A000000F04913076D67D3F79100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020100009CFFFFFF640000001400000001ECE80D4AAAA99F659100';
 Result[18].Command:='900C00000D020A0000008BD2C64DB0C6FB7200';Result[18].Response:='9DF0FB4CC32D20589100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020100009CFFFFFF64000000140000000150B2BE4EE082761E9100';
 Result[20].Command:='90DC00000D0203000000AD7CD0ABB992661E00';Result[20].Response:='BE132C687E13A4949100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020100009CFFFFFF64000000140000000167E50265622FEDE89100';
 Result[22].Command:='901C00000D02020000008CA882342E2D15C600';Result[22].Response:='CD58EB014B5BD3A79100';
 Result[23].Command:='90F50000010300';Result[23].Response:='03010000040000030000020000ED42CBF00163E2A69100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='1112131421222324D52E045B7098A0CB9100';
 Result[25].Command:='90F50000010300';Result[25].Response:='0301000004000003000002000012672A1055A5B1989100';
 Result[26].Command:='903B000013030000000400004142434422EA137162D8DF1700';Result[26].Response:='98A77587EB34E1019100';
 Result[27].Command:='90F50000010400';Result[27].Response:='04010000040000030000030000FFE52F25AEB8FC419100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='111213142122232431323334CD3AD183D9A36D589100';
 Result[29].Command:='90F50000010400';Result[29].Response:='0401000004000003000003000078C98B6F5C7F133F9100';
 Result[30].Command:='903B000013040000000400005152535415203C4BCF3F192200';Result[30].Response:='6E3C1A126A40C1A89100';
 Result[31].Command:='90F50000010400';Result[31].Response:='04010000040000030000030000F3B84A5755B548D99100';
 Result[32].Command:='903B0000130400000004000061626364F7806C7D4376847900';Result[32].Response:='2BB93CD728412A389100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030100000400000300000200007AF5C42006F3E1E59100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='194429DC528A195A9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='0301000004000003000002000005D4371EBF71E05B9100';
 Result[36].Command:='903B0000130300000004000071727374EC9E95F31318535E00';Result[36].Response:='4B5181077DF91A379100';
 Result[37].Command:='90C7000000';Result[37].Response:='3F326C84549DB3639100';
 Result[38].Command:='90F50000010100';Result[38].Response:='0101000020000013B0CEE8DD0955709100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F599740C6CC96288F9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='01010000200000C489A6E8301261689100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020100009CFFFFFF64000000140000000186C376EEB996E5249100';
 Result[42].Command:='906C0000010200';Result[42].Response:='13000000D597560EFCAEBD839100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020100009CFFFFFF640000001400000001809A7A724BB5801D9100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030100000400000300000100007D68E2CE2CFB079D9100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='71727374346A53FAE543E0049100';
 Result[46].Command:='90F50000010300';Result[46].Response:='0301000004000003000001000049760E5B2469E14B9100';
 Result[47].Command:='90F50000010400';Result[47].Response:='04010000040000030000030000EF00FAFC0B30118F9100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='616263645152535411121314ACC8D8EE470088689100';
 Result[49].Command:='90F50000010400';Result[49].Response:='04010000040000030000030000BAA6536FD07B1B3D9100';
end;
function D0M3W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00030000200000E39D213621B302D19100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='8D1A4182A4A688329100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00030000200000E8602F05EDF9C1939100';
end;
function D0M3W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00030000200000E39D213621B302D19100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='8D1A4182A4A688329100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00030000200000E8602F05EDF9C1939100';
 Result[6].Command:='903D00000F00040000040000B169D797D157FACD00';Result[6].Response:='AECE00FB6A418D509100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='ED6322B370EF51209100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000300002000009B8418EE0C9445469100';
end;
function S0M3:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='906F000000';Result[3].Response:='0102030459C14D7103B36B629100';
 Result[4].Command:='90F50000010100';Result[4].Response:='0103000020000082BBAD2152AABA0E9100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020300009CFFFFFF64000000140000000198ED553AF3F03BD89100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030300000400000300000200008484E6D5DDC662BD9100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040300000400000300000300005F1AAEBF8D27C8E29100';
 Result[8].Command:='90F50000010100';Result[8].Response:='01030000200000563F44708CAC19AF9100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='982DD52A107E6C79F139A52B7E3FEA73A746CC2DD04E5C5E9780E4BFD2D739136FEFE88862E9DDD69100';
 Result[10].Command:='90F50000010100';Result[10].Response:='0103000020000026C3B8EE4565DE119100';
 Result[11].Command:='903D00000F010400000400005DBE5DA87BAE00A000';Result[11].Response:='AC9BD7F23F70205B9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='01030000200000CA7C59C7860043FE9100';
 Result[13].Command:='903D00000F0106000002000030F996BC8EE481D700';Result[13].Response:='A767C59ADB87B0799100';
 Result[14].Command:='90F50000010100';Result[14].Response:='01030000200000C81BE8F1646D951B9100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020300009CFFFFFF64000000140000000106FEFCFB786A800F9100';
 Result[16].Command:='906C0000010200';Result[16].Response:='43C1672246E7D7389100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020300009CFFFFFF640000001400000001E37D8DEC35024F509100';
 Result[18].Command:='900C0000090259FC41807A4D376400';Result[18].Response:='F29D0D321C4A43069100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020300009CFFFFFF640000001400000001EFFB1AEC0BDDE2139100';
 Result[20].Command:='90DC000009026837F05ADDA673B100';Result[20].Response:='9EEAF90136031BEE9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020300009CFFFFFF640000001400000001D20611D5A1965D1D9100';
 Result[22].Command:='901C000009029FD91EC1ECDD5E8E00';Result[22].Response:='F6F294D8140721149100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030300000400000300000200009FF09F1774DEC5E69100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='46A583DCFC4512EA25058C8C764BE63A9100';
 Result[25].Command:='90F50000010300';Result[25].Response:='0303000004000003000002000034A0B3E1181DC4849100';
 Result[26].Command:='903B00000F030000000400003777AFC7E9AB8D9B00';Result[26].Response:='A2DA69965D9DF9F89100';
 Result[27].Command:='90F50000010400';Result[27].Response:='0403000004000003000003000007D238938A5F9FA89100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='F99979A8EA3C262D3CCE2E1D02AAEA809100';
 Result[29].Command:='90F50000010400';Result[29].Response:='04030000040000030000030000FF043FC52D64635D9100';
 Result[30].Command:='903B00000F040000000400003970B13A66DB3E9300';Result[30].Response:='62FA69FDCF5BD68E9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='04030000040000030000030000284A1DCD56BFB0609100';
 Result[32].Command:='903B00000F0400000004000027DF80356F5AAAD700';Result[32].Response:='4EF293ADE5534C969100';
 Result[33].Command:='90F50000010300';Result[33].Response:='0303000004000003000002000022F62FC5977419C19100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='3803AA0385D1AF9F9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030300000400000300000200004AC78EC4DF03210F9100';
 Result[36].Command:='903B00000F03000000040000218A33EF6EBFFA7700';Result[36].Response:='5E5C83E529CBBCA89100';
 Result[37].Command:='90C7000000';Result[37].Response:='639A845603B79CE59100';
 Result[38].Command:='90F50000010100';Result[38].Response:='0103000020000067E1997861C7F0799100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='289F6730C420D7C0C955832730E337644CB8CF040DFC7846FA82F6888AF29EE4330342A33FF9E47D9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010300002000002B3E9BC701B9ACA19100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020300009CFFFFFF6400000014000000011A49D04EC57ACC179100';
 Result[42].Command:='906C0000010200';Result[42].Response:='C654EF249093004F9100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020300009CFFFFFF64000000140000000145158D45618014869100';
 Result[44].Command:='90F50000010300';Result[44].Response:='0303000004000003000001000002537F44A15193659100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='AD5030B0B042B52E9100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030300000400000300000100004CE2DEE15AA90C9C9100';
 Result[47].Command:='90F50000010400';Result[47].Response:='04030000040000030000030000C5A68343BC94F1C29100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='1AB74D660B1277038F0A1C2D947739679100';
 Result[49].Command:='90F50000010400';Result[49].Response:='04030000040000030000030000DC924AA88F2E5BB49100';
end;
function C0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,28);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF000010A55F1267F8000613831E17D57181DE6F00';Result[2].Response:='29E6705DFB2FCEA89100';
 Result[3].Command:='90F50000010000';Result[3].Response:='0003000020000091AF';
 Result[4].Command:='90AF000000';Result[4].Response:='E39D213621B30291AF';
 Result[5].Command:='90AF000000';Result[5].Response:='D19100';
 Result[6].Command:='90BD0000070000000020000000';Result[6].Response:='AB55457FAFE6CD91AF';
 Result[7].Command:='90AF000000';Result[7].Response:='6B29AA02A699EE91AF';
 Result[8].Command:='90AF000000';Result[8].Response:='4911E51342617C91AF';
 Result[9].Command:='90AF000000';Result[9].Response:='F063DBF60776F891AF';
 Result[10].Command:='90AF000000';Result[10].Response:='D17F2412F884DA91AF';
 Result[11].Command:='90AF000000';Result[11].Response:='24A7E28DE39100';
 Result[12].Command:='90F50000010000';Result[12].Response:='0003000020000091AF';
 Result[13].Command:='90AF000000';Result[13].Response:='F8B76EB39E59B491AF';
 Result[14].Command:='90AF000000';Result[14].Response:='989100';
 Result[15].Command:='903D00001000000000200000C8FC46B119B869808800';Result[15].Response:='91AF';
 Result[16].Command:='90AF0000102509B1E93D118C010B19BCC77749383100';Result[16].Response:='91AF';
 Result[17].Command:='90AF00000FD4D14EF51C34A25049462F0852F25C00';Result[17].Response:='C752A562771CE491AF';
 Result[18].Command:='90AF000000';Result[18].Response:='249100';
 Result[19].Command:='90BD0000070000000020000000';Result[19].Response:='BC8E67E2B5F73A91AF';
 Result[20].Command:='90AF000000';Result[20].Response:='3CE14BB34F070291AF';
 Result[21].Command:='90AF000000';Result[21].Response:='F5D7B260C892E491AF';
 Result[22].Command:='90AF000000';Result[22].Response:='45E876045DA40B91AF';
 Result[23].Command:='90AF000000';Result[23].Response:='DA02B5F302BC1291AF';
 Result[24].Command:='90AF000000';Result[24].Response:='081AD30DA29100';
 Result[25].Command:='90F50000010000';Result[25].Response:='0003000020000091AF';
 Result[26].Command:='90AF000000';Result[26].Response:='29C46544DA545D91AF';
 Result[27].Command:='90AF000000';Result[27].Response:='149100';
end;
function D1M0W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000000F155C72E99281339100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506075284C6E6DFC3C90C9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00000000200000725AF957E506C8249100';
end;
function D1M0W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000000F155C72E99281339100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506075284C6E6DFC3C90C9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00000000200000725AF957E506C8249100';
 Result[6].Command:='903D00000B00040000040000AABBCCDD00';Result[6].Response:='2697EEC7D6EEA3EB9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDDE6F2613902EC66869100';
 Result[8].Command:='90F50000010000';Result[8].Response:='00000000200000CE83D00910C7D2C29100';
end;
function S1M0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='906F000000';Result[3].Response:='01020304F8764F2FA5E1D5F19100';
 Result[4].Command:='90F50000010100';Result[4].Response:='01000000200000B7F6EFE593C28B279100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020000009CFFFFFF6400000014000000018E6CAD963BBBF8859100';
 Result[6].Command:='90F50000010300';Result[6].Response:='03000000040000030000020000C9BEA0B281634A149100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040000000400000300000300001666AD7AFB0520A19100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010000002000002623263A56DFD6C19100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1FBA4C67DACCAFC36D9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010000002000007C44B44C62EB0D959100';
 Result[11].Command:='903D00000B01040000040000AABBCCDD00';Result[11].Response:='C34B4AEFC97BFEA29100';
 Result[12].Command:='90F50000010100';Result[12].Response:='01000000200000554C78DC290D4E7A9100';
 Result[13].Command:='903D00000901060000020000EEFF00';Result[13].Response:='6FEF4E18BC4D0F459100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010000002000001287349A2B44E1B69100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020000009CFFFFFF640000001400000001E6E06A5361F26CE39100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A000000CBB3AB5F2CB4B9F89100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020000009CFFFFFF64000000140000000158D6A42E9EA436F99100';
 Result[18].Command:='900C000005020A00000000';Result[18].Response:='D06E13D52423D6789100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020000009CFFFFFF6400000014000000013513B3C749201E5F9100';
 Result[20].Command:='90DC000005020300000000';Result[20].Response:='C547732DB03598739100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020000009CFFFFFF640000001400000001E5498DBE7744C4529100';
 Result[22].Command:='901C000005020200000000';Result[22].Response:='2EAC793CA49D451B9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='03000000040000030000020000D3960E3415F1CB319100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='1112131421222324C1BF74302D89C8679100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030000000400000300000200001D20F4EB1CD2B9D49100';
 Result[26].Command:='903B00000B030000000400004142434400';Result[26].Response:='41A6405A71D5DFDB9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040000000400000300000300001D0DC5C11B7D5A0B9100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='111213142122232431323334BA5D06017F9275B99100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040000000400000300000300009E22AC00A08EB0AD9100';
 Result[30].Command:='903B00000B040000000400005152535400';Result[30].Response:='684058E95EE2FEDF9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='04000000040000030000030000513B1F6FC54A32939100';
 Result[32].Command:='903B00000B040000000400006162636400';Result[32].Response:='EE6FD51ABF32A0AA9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='03000000040000030000020000B49DB49D279211639100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='C5CDDED524D56C849100';
 Result[35].Command:='90F50000010300';Result[35].Response:='0300000004000003000002000032DF5A8B19EA74A69100';
 Result[36].Command:='903B00000B030000000400007172737400';Result[36].Response:='2E4B36D7EEF0700F9100';
 Result[37].Command:='90C7000000';Result[37].Response:='6BD44F6D973293109100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010000002000009BC5244C69B5392A9100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1FA133B108145128779100';
 Result[40].Command:='90F50000010100';Result[40].Response:='01000000200000B404B749F1F167489100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020000009CFFFFFF6400000014000000014B817FCB222BD6AD9100';
 Result[42].Command:='906C0000010200';Result[42].Response:='13000000169FC150C3687A609100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020000009CFFFFFF64000000140000000183D10930668670B89100';
 Result[44].Command:='90F50000010300';Result[44].Response:='03000000040000030000010000A608497E3607BD849100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='71727374E59A92DB34F5B6B49100';
 Result[46].Command:='90F50000010300';Result[46].Response:='03000000040000030000010000C5FFFCB6E85CE70E9100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040000000400000300000300000427590D5900B3269100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213142E4364268B1250A89100';
 Result[49].Command:='90F50000010400';Result[49].Response:='04000000040000030000030000902EE6A418704BF79100';
end;
function D1M1W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000000AD298B490A182D29100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079C15E050273BEBF19100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00010000200000A46CD06C630F27A49100';
end;
function D1M1W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000000AD298B490A182D29100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079C15E050273BEBF19100';
 Result[5].Command:='90F50000010000';Result[5].Response:='00010000200000A46CD06C630F27A49100';
 Result[6].Command:='903D00001300040000040000AABBCCDD98503FFE6DC8E17700';Result[6].Response:='FBAA54EECB14ECAA9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD8ADAFDD3F1BD0BAF9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='00010000200000BD69DC3BBC982BBA9100';
end;
function S1M1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='906F000000';Result[3].Response:='01020304F8764F2FA5E1D5F19100';
 Result[4].Command:='90F50000010100';Result[4].Response:='01010000200000B644A9B381CF6B699100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020100009CFFFFFF64000000140000000126EF972CF9D556719100';
 Result[6].Command:='90F50000010300';Result[6].Response:='0301000004000003000002000021A1746A662032939100';
 Result[7].Command:='90F50000010400';Result[7].Response:='04010000040000030000030000AF1DF6E16FDD699E9100';
 Result[8].Command:='90F50000010100';Result[8].Response:='01010000200000C3373D3C15DE6BBB9100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F27CDF60FE374549A9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='0101000020000091ABEC124D478AD99100';
 Result[11].Command:='903D00001301040000040000AABBCCDD0FD9B5B22DE84E5500';Result[11].Response:='DDDA214D8C8B1EDE9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='0101000020000036A4900305447B039100';
 Result[13].Command:='903D00001101060000020000EEFF377B7A2707AD74C800';Result[13].Response:='0DA3CF9A9538C2EE9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='01010000200000A116C7536685A2549100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020100009CFFFFFF640000001400000001575DD711519F67CB9100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A000000D2CFF1B69CEFFF4C9100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020100009CFFFFFF640000001400000001E6B30EFBC75B8A269100';
 Result[18].Command:='900C00000D020A00000085F180478918CA4A00';Result[18].Response:='4B32F3232807CD909100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020100009CFFFFFF6400000014000000013DD109537E30FB309100';
 Result[20].Command:='90DC00000D020300000039F06C234BD102F800';Result[20].Response:='600ACDB0414333149100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020100009CFFFFFF64000000140000000144217DC41DF9F5129100';
 Result[22].Command:='901C00000D0202000000405BE1313611E97900';Result[22].Response:='FC8AEA3EC3C6EF039100';
 Result[23].Command:='90F50000010300';Result[23].Response:='0301000004000003000002000011C0AA587E30095F9100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='1112131421222324A1CEC8E3F683E1809100';
 Result[25].Command:='90F50000010300';Result[25].Response:='03010000040000030000020000F68855695F0F7ADA9100';
 Result[26].Command:='903B0000130300000004000041424344A9CC095FCB1196DF00';Result[26].Response:='3AC426A4E286AF569100';
 Result[27].Command:='90F50000010400';Result[27].Response:='04010000040000030000030000B221396575EF5CEA9100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='11121314212223243132333427E23D8D5A33BDCD9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040100000400000300000300006E4AEE2859863F2F9100';
 Result[30].Command:='903B00001304000000040000515253542052F591F3F3E81600';Result[30].Response:='315173880B07FB5A9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040100000400000300000300002A90CB6226F9E0BC9100';
 Result[32].Command:='903B0000130400000004000061626364F1C94896044E734400';Result[32].Response:='27C0793C6F4EAF129100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030100000400000300000200009A2F2A869C3548389100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='7FE465FED21571BF9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030100000400000300000200000AD6D2B1E827B6049100';
 Result[36].Command:='903B00001303000000040000717273743E56B72A1E6D909300';Result[36].Response:='1AD323003FA91C549100';
 Result[37].Command:='90C7000000';Result[37].Response:='A386DF1605DE96809100';
 Result[38].Command:='90F50000010100';Result[38].Response:='0101000020000058C87FF0AEFF7CD19100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F11287D34D6F0A44A9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010100002000007078F93D32BF24B59100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020100009CFFFFFF6400000014000000013AC1DB8CE8CBD2589100';
 Result[42].Command:='906C0000010200';Result[42].Response:='1300000091EFA6B387F81AE29100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020100009CFFFFFF6400000014000000017D6732C173DEEEB89100';
 Result[44].Command:='90F50000010300';Result[44].Response:='03010000040000030000010000446E5C6DDA6997659100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='71727374A21FFD7E99C3B1689100';
 Result[46].Command:='90F50000010300';Result[46].Response:='03010000040000030000010000A166B66522CDB6319100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040100000400000300000300007FC41E9541915EBE9100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213149A114151AA447A319100';
 Result[49].Command:='90F50000010400';Result[49].Response:='04010000040000030000030000B6D222D6E046B51A9100';
end;
function D1M3W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00030000200000D347FCD6CF38B1219100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='0CFFC0271045DB1E9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000008CAC358DE7EEE0B49100';
end;
function D1M3W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='00030000200000D347FCD6CF38B1219100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='0CFFC0271045DB1E9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000008CAC358DE7EEE0B49100';
 Result[6].Command:='903D00000F00040000040000D46EF6E4CF9E2F7500';Result[6].Response:='D8D2C04AFA05E73B9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='D2CEA61B97B3CF139100';
 Result[8].Command:='90F50000010000';Result[8].Response:='00030000200000D33E2B5839F8D8799100';
end;
function S1M3:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='906F000000';Result[3].Response:='01020304F8764F2FA5E1D5F19100';
 Result[4].Command:='90F50000010100';Result[4].Response:='0103000020000058A4DBCDA8BC67DD9100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020300009CFFFFFF6400000014000000013639D43E95568E189100';
 Result[6].Command:='90F50000010300';Result[6].Response:='03030000040000030000020000FB7C8DBE8EBC79899100';
 Result[7].Command:='90F50000010400';Result[7].Response:='04030000040000030000030000717F8310FA73A74A9100';
 Result[8].Command:='90F50000010100';Result[8].Response:='01030000200000DE21C35CE62C57239100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='E9AE83458CC825DD8F3A159186F332BD5AEFAFDBCF68A67F83F7AA5082F26A25C358386C4FA86D439100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010300002000008F694DDF7BCA72C99100';
 Result[11].Command:='903D00000F01040000040000768310ACE1FA733800';Result[11].Response:='93EF4FF2980F52059100';
 Result[12].Command:='90F50000010100';Result[12].Response:='0103000020000077E994DD21D348029100';
 Result[13].Command:='903D00000F010600000200000B15D2003A20290100';Result[13].Response:='D69110CD20BF6D249100';
 Result[14].Command:='90F50000010100';Result[14].Response:='0103000020000003A7E9A16FEECE369100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020300009CFFFFFF640000001400000001AD6DFB6B54F39BAB9100';
 Result[16].Command:='906C0000010200';Result[16].Response:='A596C0473915BD5D9100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020300009CFFFFFF6400000014000000017D7051281A5F24E59100';
 Result[18].Command:='900C0000090205CC3B567325C92A00';Result[18].Response:='75FE7DC41B49D29B9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020300009CFFFFFF64000000140000000156D760EF85FEC8DF9100';
 Result[20].Command:='90DC000009021BEC7F9CEB39263100';Result[20].Response:='F303B36A26D067659100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020300009CFFFFFF640000001400000001EA953EF9C557B7789100';
 Result[22].Command:='901C0000090229861FFAD6497A7C00';Result[22].Response:='9109D305D909CCD29100';
 Result[23].Command:='90F50000010300';Result[23].Response:='03030000040000030000020000113A30C49830D6809100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='CC8BA81308958205EC65F804D46ECA359100';
 Result[25].Command:='90F50000010300';Result[25].Response:='0303000004000003000002000077E13AF018007A979100';
 Result[26].Command:='903B00000F030000000400005CF0F76D6D13000F00';Result[26].Response:='3D0E00F66F7945029100';
 Result[27].Command:='90F50000010400';Result[27].Response:='04030000040000030000030000DA649A9EA0A5D3F79100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='25B6D21037EED751A57D1E30C607AE8E9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='04030000040000030000030000D24E50E57C99F1769100';
 Result[30].Command:='903B00000F04000000040000E96C4257B9CD9DA600';Result[30].Response:='74D8F6D7AAEAC0519100';
 Result[31].Command:='90F50000010400';Result[31].Response:='0403000004000003000003000013C72E9AA26ED5ED9100';
 Result[32].Command:='903B00000F04000000040000A817CA045873CE6100';Result[32].Response:='6A1D385A018F6D069100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030300000400000300000200007526F24F12F1A4229100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='A0808BAE7FD722EB9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='03030000040000030000020000CE75C31807F56B1C9100';
 Result[36].Command:='903B00000F03000000040000E5A06986B5B3B3F500';Result[36].Response:='CEEC984F6488D77C9100';
 Result[37].Command:='90C7000000';Result[37].Response:='2D0206FA1255047D9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='01030000200000BB59AA871F090D3E9100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='368D74DFB381D41165014D9454B5C5E93E713B27BCEF1E527A3D9E214DA3F28EDF22601E45C2449C9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='01030000200000B8CCBEBEB46949279100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020300009CFFFFFF640000001400000001583365CD16684A1F9100';
 Result[42].Command:='906C0000010200';Result[42].Response:='7A4937C5D1911B2E9100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020300009CFFFFFF640000001400000001AA0112234A3427259100';
 Result[44].Command:='90F50000010300';Result[44].Response:='0303000004000003000001000006BA602CEEF3EFCE9100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='591299A9070B74DB9100';
 Result[46].Command:='90F50000010300';Result[46].Response:='03030000040000030000010000FD9ED62E0ADF26BC9100';
 Result[47].Command:='90F50000010400';Result[47].Response:='0403000004000003000003000099FB7344365E35BE9100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='5E6386FA92D8ED936EE0EE3A55A73F079100';
 Result[49].Command:='90F50000010400';Result[49].Response:='0403000004000003000003000018F6AB142050F4469100';
end;
function C1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,28);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='901A0000010000';Result[1].Response:='C0489F69BEC54FA24FB6B1A32A7E422591AF';
 Result[2].Command:='90AF000020B0CF98B7C6608F7B1ADE6431E091CC2C61C857C07C04856BE6D522015DE2E27500';Result[2].Response:='4A50EF9039792F1F21C71AA745EC26909100';
 Result[3].Command:='90F50000010000';Result[3].Response:='0003000020000091AF';
 Result[4].Command:='90AF000000';Result[4].Response:='D347FCD6CF38B191AF';
 Result[5].Command:='90AF000000';Result[5].Response:='219100';
 Result[6].Command:='90BD0000070000000020000000';Result[6].Response:='E18C98D680D15291AF';
 Result[7].Command:='90AF000000';Result[7].Response:='5A849FD652FE5091AF';
 Result[8].Command:='90AF000000';Result[8].Response:='37A4B5FDB6E6B291AF';
 Result[9].Command:='90AF000000';Result[9].Response:='61F60914B9160091AF';
 Result[10].Command:='90AF000000';Result[10].Response:='69778E8FC9581E91AF';
 Result[11].Command:='90AF000000';Result[11].Response:='673D9C10D49100';
 Result[12].Command:='90F50000010000';Result[12].Response:='0003000020000091AF';
 Result[13].Command:='90AF000000';Result[13].Response:='1FC9C938632A5791AF';
 Result[14].Command:='90AF000000';Result[14].Response:='749100';
 Result[15].Command:='903D000010000000002000000CC131D5E47DC936EC00';Result[15].Response:='91AF';
 Result[16].Command:='90AF000010911B1ECC505FDFC882590A649CBAC34700';Result[16].Response:='91AF';
 Result[17].Command:='90AF00000F65CA77E01D6E3246816B9BE6EBAC4000';Result[17].Response:='4E591B89EAAF4D91AF';
 Result[18].Command:='90AF000000';Result[18].Response:='6D9100';
 Result[19].Command:='90BD0000070000000020000000';Result[19].Response:='88DFB26C4B0CB191AF';
 Result[20].Command:='90AF000000';Result[20].Response:='9B380C1AD8670B91AF';
 Result[21].Command:='90AF000000';Result[21].Response:='D398B74AAAAE4F91AF';
 Result[22].Command:='90AF000000';Result[22].Response:='EC8D8AE07A69E091AF';
 Result[23].Command:='90AF000000';Result[23].Response:='AD2C876118A51391AF';
 Result[24].Command:='90AF000000';Result[24].Response:='59AD60CB669100';
 Result[25].Command:='90F50000010000';Result[25].Response:='0003000020000091AF';
 Result[26].Command:='90AF000000';Result[26].Response:='53EBE88E8FABE091AF';
 Result[27].Command:='90AF000000';Result[27].Response:='4D9100';
end;
function D2M0W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000000002000009100';
end;
function D2M0W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000000002000009100';
 Result[6].Command:='903D00000B00040000040000AABBCCDD00';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000000002000009100';
end;
function S2M0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010000002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020000009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030000000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040000000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010000002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010000002000009100';
 Result[11].Command:='903D00000B01040000040000AABBCCDD00';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010000002000009100';
 Result[13].Command:='903D00000901060000020000EEFF00';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010000002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020000009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A0000009100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020000009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C000005020A00000000';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020000009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC000005020300000000';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020000009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C000005020200000000';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030000000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='11121314212223249100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030000000400000300000200009100';
 Result[26].Command:='903B00000B030000000400004142434400';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040000000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='1112131421222324313233349100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040000000400000300000300009100';
 Result[30].Command:='903B00000B040000000400005152535400';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040000000400000300000300009100';
 Result[32].Command:='903B00000B040000000400006162636400';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030000000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030000000400000300000200009100';
 Result[36].Command:='903B00000B030000000400007172737400';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010000002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010000002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020000009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='130000009100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020000009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030000000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='717273749100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030000000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040000000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213149100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040000000400000300000300009100';
end;
function D2M1W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607B49B14FD9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000009100';
end;
function D2M1W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607B49B14FD9100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000009100';
 Result[6].Command:='903D00000F00040000040000AABBCCDD74DD05D500';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD74DD05D59100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000100002000009100';
end;
function S2M1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010100002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020100009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030100000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040100000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010100002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F62646FDD9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010100002000009100';
 Result[11].Command:='903D00000F01040000040000AABBCCDD74DD05D500';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010100002000009100';
 Result[13].Command:='903D00000D01060000020000EEFFF219712200';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010100002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020100009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A000000990B71829100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020100009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C000009020A000000990B718200';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020100009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC000009020300000045A2D09B00';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020100009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C00000902020000005D0936AC00';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030100000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='111213142122232481D858BB9100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030100000400000300000200009100';
 Result[26].Command:='903B00000F030000000400004142434417E246D800';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040100000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='111213142122232431323334736690DE9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040100000400000300000300009100';
 Result[30].Command:='903B00000F04000000040000515253544D3E2F4400';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040100000400000300000300009100';
 Result[32].Command:='903B00000F0400000004000061626364C9BA147600';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030100000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030100000400000300000200009100';
 Result[36].Command:='903B00000F03000000040000717273746BE5AC7600';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010100002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F4EC987E99100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010100002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020100009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='1300000061703A719100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020100009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030100000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='717273746BE5AC769100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030100000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040100000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213142EFECFCC9100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040100000400000300000300009100';
end;
function D2M3W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='34D4BA41FAB909F69100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000009100';
end;
function D2M3W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='34D4BA41FAB909F69100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000009100';
 Result[6].Command:='903D00000F0004000004000013AB36F82D6D5E8B00';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='5A15806628F782FA9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000300002000009100';
end;
function S2M3:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010300002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020300009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030300000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040300000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010300002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='02F4CC8A1EB0059809FD2FA953D221C488A17C4C45BAB3F362646FDDC21016FAC0747E58A6D6B2F29100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010300002000009100';
 Result[11].Command:='903D00000F0104000004000013AB36F82D6D5E8B00';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010300002000009100';
 Result[13].Command:='903D00000F01060000020000BB0B00F6074DF31C00';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010300002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020300009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='DDC74928170B9EAD9100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020300009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C00000902036BF3736B1CFF3400';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020300009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC000009022028E2EE7BE8245F00';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020300009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C00000902A24B02F0CA592E8100';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030300000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='81D858BBF7E8A4A865314338DE90DF5E9100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030300000400000300000200009100';
 Result[26].Command:='903B00000F030000000400003877DDCA4698D9BF00';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040300000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='81D858BBF7E8A4A86999AFBD06CA30349100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040300000400000300000300009100';
 Result[30].Command:='903B00000F0400000004000056B1A925F6AB995E00';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040300000400000300000300009100';
 Result[32].Command:='903B00000F04000000040000459F0EB202B9977900';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030300000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030300000400000300000200009100';
 Result[36].Command:='903B00000F0300000004000073DE7F28575093EB00';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010300002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='DCC9DB172DFC8287DAE2223B58AAE5CF003DCC393A17EE8F4EC987E9379C62976B98CC18BD1A7C279100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010300002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020300009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='B6B637A20FDC35BF9100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020300009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030300000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='345044A83A84532C9100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030300000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040300000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='4173AAEDAD01531A2849F45BCCDCB1F59100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040300000400000300000300009100';
end;
function C2:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,21);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='EDD076666F6AE13091AF';
 Result[2].Command:='90AF000010285089A5EBE5BC9E273DF193EC99F16400';Result[2].Response:='32146EB46D7FA6549100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070000000020000000';Result[4].Response:='02F4CC8A1EB00591AF';
 Result[5].Command:='90AF000000';Result[5].Response:='9809FD2FA953D291AF';
 Result[6].Command:='90AF000000';Result[6].Response:='21C488A17C4C4591AF';
 Result[7].Command:='90AF000000';Result[7].Response:='BAB3F362646FDD91AF';
 Result[8].Command:='90AF000000';Result[8].Response:='C21016FAC0747E91AF';
 Result[9].Command:='90AF000000';Result[9].Response:='58A6D6B2F29100';
 Result[10].Command:='90F50000010000';Result[10].Response:='000300002000009100';
 Result[11].Command:='903D00001000000000200000002FB36E23DEDB5B0B00';Result[11].Response:='91AF';
 Result[12].Command:='90AF000010678DA6126532070D994EF99BAED1426700';Result[12].Response:='91AF';
 Result[13].Command:='90AF00000F751D9985FF242AFE0C9FEEBCC0611B00';Result[13].Response:='9100';
 Result[14].Command:='90BD0000070000000020000000';Result[14].Response:='A3DE3F4D67A52491AF';
 Result[15].Command:='90AF000000';Result[15].Response:='D6B8FC348A67B091AF';
 Result[16].Command:='90AF000000';Result[16].Response:='73C2CD167F1ACE91AF';
 Result[17].Command:='90AF000000';Result[17].Response:='19FBA3406FCD7891AF';
 Result[18].Command:='90AF000000';Result[18].Response:='71C4308023C2EC91AF';
 Result[19].Command:='90AF000000';Result[19].Response:='BEA391A9299100';
 Result[20].Command:='90F50000010000';Result[20].Response:='000300002000009100';
end;
function D3M0W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000000002000009100';
end;
function D3M0W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000000002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='040506079100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000000002000009100';
 Result[6].Command:='903D00000B00040000040000AABBCCDD00';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000000002000009100';
end;
function S3M0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010000002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020000009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030000000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040000000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010000002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010000002000009100';
 Result[11].Command:='903D00000B01040000040000AABBCCDD00';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010000002000009100';
 Result[13].Command:='903D00000901060000020000EEFF00';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010000002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020000009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A0000009100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020000009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C000005020A00000000';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020000009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC000005020300000000';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020000009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C000005020200000000';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030000000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='11121314212223249100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030000000400000300000200009100';
 Result[26].Command:='903B00000B030000000400004142434400';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040000000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='1112131421222324313233349100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040000000400000300000300009100';
 Result[30].Command:='903B00000B040000000400005152535400';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040000000400000300000300009100';
 Result[32].Command:='903B00000B040000000400006162636400';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030000000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030000000400000300000200009100';
 Result[36].Command:='903B00000B030000000400007172737400';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010000002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010000002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020000009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='130000009100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020000009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030000000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='717273749100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030000000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040000000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='6162636451525354111213149100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040000000400000300000300009100';
end;
function D3M1W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607D4C529159100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000009100';
end;
function D3M1W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000100002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='04050607D4C529159100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000100002000009100';
 Result[6].Command:='903D00000F00040000040000AABBCCDD9D8EC55100';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='AABBCCDD9D8EC5519100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000100002000009100';
end;
function S3M1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010100002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020100009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030100000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040100000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010100002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F56900ACF9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010100002000009100';
 Result[11].Command:='903D00000F01040000040000AABBCCDD9D8EC55100';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010100002000009100';
 Result[13].Command:='903D00000D01060000020000EEFFA4A4C6D800';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010100002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020100009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0A0000006835060F9100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020100009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C000009020A0000006835060F00';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020100009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC00000902030000007060A95800';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020100009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C0000090202000000AFFC1C9300';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030100000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='1112131421222324A7D839339100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030100000400000300000200009100';
 Result[26].Command:='903B00000F0300000004000041424344E1B90D1100';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040100000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='111213142122232431323334BA6BB87D9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040100000400000300000300009100';
 Result[30].Command:='903B00000F040000000400005152535421A049A000';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040100000400000300000300009100';
 Result[32].Command:='903B00000F0400000004000061626364AB1AF6BC00';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030100000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030100000400000300000200009100';
 Result[36].Command:='903B00000F03000000040000717273746D76CC3B00';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010100002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='00010203AABBEEFF08090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F8BCE3B1B9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010100002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020100009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='13000000879863969100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020100009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030100000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='717273746D76CC3B9100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030100000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040100000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='616263645152535411121314BC045D029100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040100000400000300000300009100';
end;
function D3M3W0:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,6);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='D58D4B12FA26FDA39100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000009100';
end;
function D3M3W1:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,9);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070004000004000000';Result[4].Response:='D58D4B12FA26FDA39100';
 Result[5].Command:='90F50000010000';Result[5].Response:='000300002000009100';
 Result[6].Command:='903D00000F000400000400008D523FAFC3D28DA600';Result[6].Response:='9100';
 Result[7].Command:='90BD0000070004000004000000';Result[7].Response:='80E384B2C1BB408A9100';
 Result[8].Command:='90F50000010000';Result[8].Response:='000300002000009100';
end;
function S3M3:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,50);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='906F000000';Result[3].Response:='010203049100';
 Result[4].Command:='90F50000010100';Result[4].Response:='010300002000009100';
 Result[5].Command:='90F50000010200';Result[5].Response:='020300009CFFFFFF6400000014000000019100';
 Result[6].Command:='90F50000010300';Result[6].Response:='030300000400000300000200009100';
 Result[7].Command:='90F50000010400';Result[7].Response:='040300000400000300000300009100';
 Result[8].Command:='90F50000010100';Result[8].Response:='010300002000009100';
 Result[9].Command:='90BD0000070100000020000000';Result[9].Response:='1E05E42F511C29A1DD670B0A39597F0313B794B24A9F67BF56900ACF16B62ABE99009D5EC7ACC5DB9100';
 Result[10].Command:='90F50000010100';Result[10].Response:='010300002000009100';
 Result[11].Command:='903D00000F010400000400008D523FAFC3D28DA600';Result[11].Response:='9100';
 Result[12].Command:='90F50000010100';Result[12].Response:='010300002000009100';
 Result[13].Command:='903D00000F01060000020000F382292C6729F28E00';Result[13].Response:='9100';
 Result[14].Command:='90F50000010100';Result[14].Response:='010300002000009100';
 Result[15].Command:='90F50000010200';Result[15].Response:='020300009CFFFFFF6400000014000000019100';
 Result[16].Command:='906C0000010200';Result[16].Response:='0BE196C1562A7E5B9100';
 Result[17].Command:='90F50000010200';Result[17].Response:='020300009CFFFFFF6400000014000000019100';
 Result[18].Command:='900C00000902C05DDB63560A6E9700';Result[18].Response:='9100';
 Result[19].Command:='90F50000010200';Result[19].Response:='020300009CFFFFFF6400000014000000019100';
 Result[20].Command:='90DC000009029E6C191408BB29E600';Result[20].Response:='9100';
 Result[21].Command:='90F50000010200';Result[21].Response:='020300009CFFFFFF6400000014000000019100';
 Result[22].Command:='901C00000902028C95AEA8B672A600';Result[22].Response:='9100';
 Result[23].Command:='90F50000010300';Result[23].Response:='030300000400000300000200009100';
 Result[24].Command:='90BB0000070300000002000000';Result[24].Response:='A7D83933BEF13ED73C0CC11AE2BF26759100';
 Result[25].Command:='90F50000010300';Result[25].Response:='030300000400000300000200009100';
 Result[26].Command:='903B00000F0300000004000058B4A864010C039C00';Result[26].Response:='9100';
 Result[27].Command:='90F50000010400';Result[27].Response:='040300000400000300000300009100';
 Result[28].Command:='90BB0000070400000003000000';Result[28].Response:='A7D83933BEF13ED7203A55BE82009EAB9100';
 Result[29].Command:='90F50000010400';Result[29].Response:='040300000400000300000300009100';
 Result[30].Command:='903B00000F04000000040000F4D829A5B12487F100';Result[30].Response:='9100';
 Result[31].Command:='90F50000010400';Result[31].Response:='040300000400000300000300009100';
 Result[32].Command:='903B00000F04000000040000C3C547199884596F00';Result[32].Response:='9100';
 Result[33].Command:='90F50000010300';Result[33].Response:='030300000400000300000200009100';
 Result[34].Command:='90EB0000010300';Result[34].Response:='9100';
 Result[35].Command:='90F50000010300';Result[35].Response:='030300000400000300000200009100';
 Result[36].Command:='903B00000F030000000400005DD77B51392C39D000';Result[36].Response:='9100';
 Result[37].Command:='90C7000000';Result[37].Response:='9100';
 Result[38].Command:='90F50000010100';Result[38].Response:='010300002000009100';
 Result[39].Command:='90BD0000070100000020000000';Result[39].Response:='8E3B8A7879574AB5753C798C89BD45475EA4B3251474CDD68BCE3B1B9DD3D25078927793DB488D5C9100';
 Result[40].Command:='90F50000010100';Result[40].Response:='010300002000009100';
 Result[41].Command:='90F50000010200';Result[41].Response:='020300009CFFFFFF6400000014000000019100';
 Result[42].Command:='906C0000010200';Result[42].Response:='3E36D3A3DE0BE7749100';
 Result[43].Command:='90F50000010200';Result[43].Response:='020300009CFFFFFF6400000014000000019100';
 Result[44].Command:='90F50000010300';Result[44].Response:='030300000400000300000100009100';
 Result[45].Command:='90BB0000070300000001000000';Result[45].Response:='DAF5F21DEB261C879100';
 Result[46].Command:='90F50000010300';Result[46].Response:='030300000400000300000100009100';
 Result[47].Command:='90F50000010400';Result[47].Response:='040300000400000300000300009100';
 Result[48].Command:='90BB0000070400000003000000';Result[48].Response:='E2BE7A13E3044BD5FF16C8703508A27F9100';
 Result[49].Command:='90F50000010400';Result[49].Response:='040300000400000300000300009100';
end;
function C3:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,21);
 Result[0].Command:='905A00000301EFCD00';Result[0].Response:='9100';
 Result[1].Command:='900A0000010000';Result[1].Response:='C0489F69BEC54FA291AF';
 Result[2].Command:='90AF0000104A37C9D6B574D003B00B25A069581CC700';Result[2].Response:='FE5F5CE1966AAE2A9100';
 Result[3].Command:='90F50000010000';Result[3].Response:='000300002000009100';
 Result[4].Command:='90BD0000070000000020000000';Result[4].Response:='1E05E42F511C2991AF';
 Result[5].Command:='90AF000000';Result[5].Response:='A1DD670B0A395991AF';
 Result[6].Command:='90AF000000';Result[6].Response:='7F0313B794B24A91AF';
 Result[7].Command:='90AF000000';Result[7].Response:='9F67BF56900ACF91AF';
 Result[8].Command:='90AF000000';Result[8].Response:='16B62ABE99009D91AF';
 Result[9].Command:='90AF000000';Result[9].Response:='5EC7ACC5DB9100';
 Result[10].Command:='90F50000010000';Result[10].Response:='000300002000009100';
 Result[11].Command:='903D00001000000000200000984F33C1EA41126BAF00';Result[11].Response:='91AF';
 Result[12].Command:='90AF0000103D3DA99846685D656FDC257F9090AA0C00';Result[12].Response:='91AF';
 Result[13].Command:='90AF00000F49F591C787D7FD99229A79D3CC4DB000';Result[13].Response:='9100';
 Result[14].Command:='90BD0000070000000020000000';Result[14].Response:='980E1CA9336C4691AF';
 Result[15].Command:='90AF000000';Result[15].Response:='2E08D839E30E9091AF';
 Result[16].Command:='90AF000000';Result[16].Response:='0088B876EA805B91AF';
 Result[17].Command:='90AF000000';Result[17].Response:='3E99DBACBBF47491AF';
 Result[18].Command:='90AF000000';Result[18].Response:='65112E9C656B6491AF';
 Result[19].Command:='90AF000000';Result[19].Response:='E7216A26019100';
 Result[20].Command:='90F50000010000';Result[20].Response:='000300002000009100';
end;
function Uread:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,3);
 Result[0].Command:='1A004176';Result[0].Response:='AFC0489F69BEC54FA2B0B9';
 Result[1].Command:='AFA55F1267F8000613831E17D57181DE6F77E0';Result[1].Response:='0029E6705DFB2FCEA807B5';
 Result[2].Command:='302424CF';Result[2].Response:='909192939495969798999A9B9C9D9E9F8A02';
end;
function Umemory:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,11);
 Result[0].Command:='1A004176';Result[0].Response:='AFC0489F69BEC54FA2B0B9';
 Result[1].Command:='AFA55F1267F8000613831E17D57181DE6F77E0';Result[1].Response:='0029E6705DFB2FCEA807B5';
 Result[2].Command:='300426EE';Result[2].Response:='101112131415161718191A1B1C1D1E1F22E8';
 Result[3].Command:='30084A24';Result[3].Response:='202122232425262728292A2B2C2D2E2FDDCF';
 Result[4].Command:='300C6E62';Result[4].Response:='303132333435363738393A3B3C3D3E3F88D2';
 Result[5].Command:='301083B8';Result[5].Response:='404142434445464748494A4B4C4D4E4F2380';
 Result[6].Command:='3014A7FE';Result[6].Response:='505152535455565758595A5B5C5D5E5F769D';
 Result[7].Command:='3018CB34';Result[7].Response:='606162636465666768696A6B6C6D6E6F89BA';
 Result[8].Command:='301CEF72';Result[8].Response:='707172737475767778797A7B7C7D7E7FDCA7';
 Result[9].Command:='30200089';Result[9].Response:='808182838485868788898A8B8C8D8E8FDF1F';
 Result[10].Command:='302424CF';Result[10].Response:='909192939495969798999A9B9C9D9E9F8A02';
end;
function Uwrite:TLegacyWirePairs;
begin
 Result:=nil;SetLength(Result,4);
 Result[0].Command:='1A004176';Result[0].Response:='AFC0489F69BEC54FA2B0B9';
 Result[1].Command:='AFA55F1267F8000613831E17D57181DE6F77E0';Result[1].Response:='0029E6705DFB2FCEA807B5';
 Result[2].Command:='A227AABBCCDD7F5C';Result[2].Response:='0A';
 Result[3].Command:='302424CF';Result[3].Response:='909192939495969798999A9BAABBCCDD5151';
end;
end.
