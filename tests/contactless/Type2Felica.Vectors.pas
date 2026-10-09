unit Type2Felica.Vectors;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
interface
type
 /// <summary>One independently generated synthetic protocol exchange.</summary>
 TProtocolPair=record
  /// <summary>Complete literal outgoing frame.</summary>
  Command:string;
  /// <summary>Complete literal response frame.</summary>
  Response:string;
 end;
 /// <summary>Ordered complete synthetic exchange transcript.</summary>
 TProtocolPairs=array of TProtocolPair;
/// <summary>Selects a fixed independently generated synthetic exchange transcript.</summary>
/// <param name="Name">Exact developer fixture name.</param>
/// <returns>Independent ordered pairs; no production credentials.</returns>
function ProtocolPairs(const Name:string):TProtocolPairs;
implementation
uses {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF};
function ProtocolPairs(const Name:string):TProtocolPairs;
begin
 Result:=nil;
 if Name='FelicaRead' then begin
  SetLength(Result,1);
  Result[0].Command:='13060102030405060708010B00028003000001'; Result[0].Response:='2D070102030405060708000002000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';
  Exit;
 end;
 if Name='FelicaWrite' then begin
  SetLength(Result,3);
  Result[0].Command:='13060102030405060708010B00028003000001'; Result[0].Response:='2D070102030405060708000002000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';
  Result[1].Command:='33080102030405060708010900028003000001202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F'; Result[1].Response:='0C0901020304050607080000';
  Result[2].Command:='13060102030405060708010B00028003000001'; Result[2].Response:='2D070102030405060708000002202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F';
  Exit;
 end;
 if Name='Type3Read' then begin
  SetLength(Result,3);
  Result[0].Command:='10060102030405060708010B00018000'; Result[0].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Result[1].Command:='10060102030405060708010B00018001'; Result[1].Response:='1D070102030405060708000001D101045402656E41CCCCCCCCCCCCCCCC';
  Result[2].Command:='10060102030405060708010B00018000'; Result[2].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Exit;
 end;
 if Name='Type3Write' then begin
  SetLength(Result,16);
  Result[0].Command:='10060102030405060708010B00018000'; Result[0].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Result[1].Command:='10060102030405060708010B00018001'; Result[1].Response:='1D070102030405060708000001D101045402656E41CCCCCCCCCCCCCCCC';
  Result[2].Command:='10060102030405060708010B00018000'; Result[2].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Result[3].Command:='20080102030405060708010900018000100302012C000000000F01000008005A'; Result[3].Response:='0C0901020304050607080000';
  Result[4].Command:='10060102030405060708010B00018000'; Result[4].Response:='1D070102030405060708000001100302012C000000000F01000008005A';
  Result[5].Command:='12060102030405060708010B000280018002'; Result[5].Response:='2D070102030405060708000002D101045402656E41CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC';
  Result[6].Command:='320801020304050607080109000280018002D101295402656E42424242424242424242424242424242424242424242424242'; Result[6].Response:='0C0901020304050607080000';
  Result[7].Command:='12060102030405060708010B000280018002'; Result[7].Response:='2D070102030405060708000002D101295402656E42424242424242424242424242424242424242424242424242';
  Result[8].Command:='10060102030405060708010B00018003'; Result[8].Response:='1D070102030405060708000001CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC';
  Result[9].Command:='2008010203040506070801090001800342424242424242424242424242CCCCCC'; Result[9].Response:='0C0901020304050607080000';
  Result[10].Command:='10060102030405060708010B00018003'; Result[10].Response:='1D07010203040506070800000142424242424242424242424242CCCCCC';
  Result[11].Command:='20080102030405060708010900018000100302012C00000000000100002D0070'; Result[11].Response:='0C0901020304050607080000';
  Result[12].Command:='10060102030405060708010B00018000'; Result[12].Response:='1D070102030405060708000001100302012C00000000000100002D0070';
  Result[13].Command:='10060102030405060708010B00018000'; Result[13].Response:='1D070102030405060708000001100302012C00000000000100002D0070';
  Result[14].Command:='14060102030405060708010B0003800180028003'; Result[14].Response:='3D070102030405060708000003D101295402656E4242424242424242424242424242424242424242424242424242424242424242424242424242CCCCCC';
  Result[15].Command:='10060102030405060708010B00018000'; Result[15].Response:='1D070102030405060708000001100302012C00000000000100002D0070';
  Exit;
 end;
 if Name='Type3Clear' then begin
  SetLength(Result,9);
  Result[0].Command:='10060102030405060708010B00018000'; Result[0].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Result[1].Command:='10060102030405060708010B00018001'; Result[1].Response:='1D070102030405060708000001D101045402656E41CCCCCCCCCCCCCCCC';
  Result[2].Command:='10060102030405060708010B00018000'; Result[2].Response:='1D070102030405060708000001100302012C000000000001000008004B';
  Result[3].Command:='20080102030405060708010900018000100302012C000000000F01000008005A'; Result[3].Response:='0C0901020304050607080000';
  Result[4].Command:='10060102030405060708010B00018000'; Result[4].Response:='1D070102030405060708000001100302012C000000000F01000008005A';
  Result[5].Command:='20080102030405060708010900018000100302012C0000000000010000000043'; Result[5].Response:='0C0901020304050607080000';
  Result[6].Command:='10060102030405060708010B00018000'; Result[6].Response:='1D070102030405060708000001100302012C0000000000010000000043';
  Result[7].Command:='10060102030405060708010B00018000'; Result[7].Response:='1D070102030405060708000001100302012C0000000000010000000043';
  Result[8].Command:='10060102030405060708010B00018000'; Result[8].Response:='1D070102030405060708000001100302012C0000000000010000000043';
  Exit;
 end;
 if Name='T2Config0' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A101159C4'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure0' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A101159C4'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A211BB556677492D'; Result[2].Response:='0A';
  Result[3].Command:='A21008220004181E'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A101159C4'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials0' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A213C3D40000D1E4'; Result[1].Response:='0A';
  Result[2].Command:='A212050607082164'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Counter0' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='39001A7F'; Result[1].Response:='5634127F12';
  Exit;
 end;
 if Name='T2Config1' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A25267F49'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure1' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A25267F49'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A226BB55667744C9'; Result[2].Response:='0A';
  Result[3].Command:='A225082200049DEC'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A25267F49'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials1' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A228C3D40000EC77'; Result[1].Response:='0A';
  Result[2].Command:='A22705060708A496'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Counter1' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='39001A7F'; Result[1].Response:='5634127F12';
  Exit;
 end;
 if Name='T2Config2' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A292AB32A'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure2' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A292AB32A'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A22ABB55667774BE'; Result[2].Response:='0A';
  Result[3].Command:='A22908220004AD9B'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A292AB32A'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials2' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A22CC3D40000FC5A'; Result[1].Response:='0A';
  Result[2].Command:='A22B0506070894E1'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Counter2' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3902085C'; Result[1].Response:='5634127F12';
  Exit;
 end;
 if Name='T2Config3' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A83844834'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure3' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A83844834'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A284BB5566770835'; Result[2].Response:='0A';
  Result[3].Command:='A28308220004C13D'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A83844834'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials3' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A286C3D4000090FC'; Result[1].Response:='0A';
  Result[2].Command:='A28505060708E86A'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Counter3' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3902085C'; Result[1].Response:='5634127F12';
  Exit;
 end;
 if Name='T2Config4' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3AE3E41B32'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure4' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3AE3E41B32'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A2E4BB556677BB94'; Result[2].Response:='0A';
  Result[3].Command:='A2E308220004729C'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3AE3E41B32'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials4' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A2E6C3D40000235D'; Result[1].Response:='0A';
  Result[2].Command:='A2E5050607085BCB'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Counter4' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3902085C'; Result[1].Response:='5634127F12';
  Exit;
 end;
 if Name='T2Config5' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A101159C4'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure5' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A101159C4'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A211BB556677492D'; Result[2].Response:='0A';
  Result[3].Command:='A21008220004181E'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A101159C4'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials5' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A213C3D40000D1E4'; Result[1].Response:='0A';
  Result[2].Command:='A212050607082164'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2Config6' then begin
  SetLength(Result,2);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A25267F49'; Result[1].Response:='082200FF385566772DFC';
  Exit;
 end;
 if Name='T2Configure6' then begin
  SetLength(Result,6);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A25267F49'; Result[1].Response:='082200FF385566772DFC';
  Result[2].Command:='A226BB55667744C9'; Result[2].Response:='0A';
  Result[3].Command:='A225082200049DEC'; Result[3].Response:='0A';
  Result[4].Command:='1B01020304B536'; Result[4].Response:='A1B21E3E';
  Result[5].Command:='3A25267F49'; Result[5].Response:='08220004BB556677C42C';
  Exit;
 end;
 if Name='T2Credentials6' then begin
  SetLength(Result,4);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='A228C3D40000EC77'; Result[1].Response:='0A';
  Result[2].Command:='A22705060708A496'; Result[2].Response:='0A';
  Result[3].Command:='1B05060708348A'; Result[3].Response:='C3D4CB6E';
  Exit;
 end;
 if Name='T2NdefRead' then begin
  SetLength(Result,3);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A03033348'; Result[1].Response:='E1100600742F';
  Result[2].Command:='3A040F57CF'; Result[2].Response:='0308D101045402656E41FE00000000000000000000000000000000000000000000000000000000000000000000000000F0C2';
  Exit;
 end;
 if Name='T2NdefWrite' then begin
  SetLength(Result,13);
  Result[0].Command:='1B01020304B536'; Result[0].Response:='A1B21E3E';
  Result[1].Command:='3A101159C4'; Result[1].Response:='00000004800000004455';
  Result[2].Command:='3A03033348'; Result[2].Response:='E1100600742F';
  Result[3].Command:='3A040F57CF'; Result[3].Response:='0308D101045402656E41FE00000000000000000000000000000000000000000000000000000000000000000000000000F0C2';
  Result[4].Command:='3A02026240'; Result[4].Response:='000000000056';
  Result[5].Command:='A2040300D10190E0'; Result[5].Response:='0A';
  Result[6].Command:='3A04048471'; Result[6].Response:='0300D101A724';
  Result[7].Command:='A2066E42FE00CFE6'; Result[7].Response:='0A';
  Result[8].Command:='3A06062661'; Result[8].Response:='6E42FE007034';
  Result[9].Command:='A2040308D1015226'; Result[9].Response:='0A';
  Result[10].Command:='3A04048471'; Result[10].Response:='0308D10165E2';
  Result[11].Command:='3A040F57CF'; Result[11].Response:='0308D101045402656E42FE00000000000000000000000000000000000000000000000000000000000000000000000000C21D';
  Result[12].Command:='3A03033348'; Result[12].Response:='E1100600742F';
  Exit;
 end;
 raise Exception.Create('Unknown synthetic protocol fixture.');
end;
end.
