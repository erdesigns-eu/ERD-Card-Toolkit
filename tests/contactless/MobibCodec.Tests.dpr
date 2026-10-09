program MobibCodecTests;
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes, ERD.Card.Contactless.Calypso, ERD.Card.MOBIB.Data;
var Checks: Integer;
procedure Check(const V: Boolean; const M: string);
begin Inc(Checks); if not V then raise Exception.Create(M); end;
procedure PutBits(var B: TBytes; const Offset,Count: Integer; const V: Cardinal);
var I,P: Integer;
begin
 for I := 0 to Count-1 do begin P := Offset+I;
  if ((V shr (Count-1-I)) and 1) <> 0 then B[P div 8] := B[P div 8] or Byte(1 shl (7-P mod 8));
 end;
end;
procedure PutBcd(var B: TBytes; const Offset: Integer; const V: string);
var I: Integer;
begin for I := 1 to Length(V) do PutBits(B,Offset+(I-1)*4,4,Ord(V[I])-Ord('0')); end;
procedure TestPrimitives;
var B: TBytes; Offset,Count,I: Integer; Expected: UInt64; Raised: Boolean;
begin
 B := HexToBytes('01234567');
 for Offset := 0 to 31 do for Count := 1 to 32-Offset do begin
  Expected := (UInt64($01234567) shr (32-Offset-Count)) and ((UInt64(1) shl Count)-1);
  Check(TMobibCodec.Bits(B,Offset,Count) = Expected,'Independent cross-byte bit vector');
 end;
 Check(TMobibCodec.Bits(HexToBytes('FFFFFFFF'),0,32) = $FFFFFFFF,'Unsigned full-width field');
 Check(TMobibCodec.Bcd(HexToBytes('A0012300'),4,5) = '00123','Unaligned BCD/leading zeros');
 for I := 0 to 3 do begin Raised := False;
  try case I of
   0: TMobibCodec.Bits(B,High(Integer),32);
   1: TMobibCodec.Bits(B,-1,1);
   2: TMobibCodec.Bits(B,0,33);
   3: TMobibCodec.Bcd(HexToBytes('AF'),0,2);
  end; except on E: EMobibDecodeError do Raised := True; end;
  Check(Raised,'Invalid ranges/BCD fail without overflow');
 end;
end;
procedure TestSnapshot;
const Number = '0000123456789012345';
var S: TMobibSnapshot; D: TMobibData; Full,Event,Contract,Counters: TBytes;
 I,J: Integer; Raised: Boolean;
begin
 S := Default(TMobibSnapshot); SetLength(S.Files,6);
 for I := 0 to High(S.Files) do begin
  S.Files[I].SelectionStatus := $9000; SetLength(S.Files[I].Records,1);
  S.Files[I].Records[0].Number := 1; SetLength(S.Files[I].Records[0].Data,29);
 end;
 S.Files[0].LogicalId := $2001; PutBits(S.Files[0].Records[0].Data,6,7,1);
 PutBcd(S.Files[0].Records[0].Data,13,'056'); PutBcd(S.Files[0].Records[0].Data,25,'001');
 S.Files[1].LogicalId := $3F1C; SetLength(S.Files[1].Records,2);
 SetLength(Full,58); PutBcd(Full,18,Number); PutBcd(Full,168,'19900423'); PutBits(Full,200,2,1);
 for I := 0 to 30 do PutBits(Full,205+I*5,5,31);
 // Clear the fixture name area, then encode ALICE independently.
 for I := 205 to 359 do Full[I div 8] := Full[I div 8] and not Byte(1 shl (7-I mod 8));
 for I := 0 to 30 do begin
  case I of 0:J:=1; 1:J:=12; 2:J:=9; 3:J:=3; 4:J:=5; else J:=31; end;
  PutBits(Full,205+I*5,5,Cardinal(J));
 end;
 S.Files[1].Records[0].Data := Copy(Full,0,29); S.Files[1].Records[1].Data := Copy(Full,29,29);
 S.Files[1].Records[1].Number := 2;
 S.Files[2].LogicalId := $2010; SetLength(Event,29);
 PutBits(Event,6,14,42); PutBits(Event,20,11,754); PutBits(Event,99,5,15);
 PutBits(Event,71,12,123); PutBits(Event,92,7,12); PutBits(Event,139,23,66051);
 PutBits(Event,186,14,41); PutBits(Event,200,11,100); S.Files[2].Records[0].Data := Event;
 S.Files[3].LogicalId := $2020; SetLength(Contract,29); PutBits(Contract,41,14,200); S.Files[3].Records[0].Data := Contract;
 S.Files[4].LogicalId := $2069; SetLength(Counters,29); PutBits(Counters,0,24,$010203); S.Files[4].Records[0].Data := Counters;
 S.Files[5].LogicalId := $2050; PutBits(S.Files[5].Records[0].Data,0,4,2);
 D := TMobibCodec.Decode(S,mlLegacy056001);
 Check(D.LayoutMatched and D.HasNetwork and (D.CountryCode = 56) and (D.NetworkCode = 1),'Explicit environment match');
 Check(D.Holder.Present and (D.Holder.Number = Number) and (D.Holder.Name = 'ALICE'),'Two-record holder/name/leading zeros');
 Check(D.Holder.HasBirthDate and (D.Holder.BirthDate = EncodeDate(1990,4,23)) and (D.Holder.GenderCode = 1),'BCD civil birth date and raw gender');
 Check((Length(D.Events) = 1) and (D.Events[0].Date = EncodeDate(1997,1,1)+42) and
  (D.Events[0].Minutes = 754) and (D.Events[0].LocationId = 123) and (D.Events[0].BusRoute = 12) and
  (D.Events[0].CouponCount = 66051),'Known event fields, civil epoch and bus location');
 Check((Length(D.Contracts) = 1) and (D.Contracts[0].PurchaseDate = EncodeDate(1997,1,1)+200),'Known contract date field');
 Check((Length(D.Counters) = 9) and (D.Counters[0].Value = $010203) and (D.Counters[8].Value = 0),'24-bit counter value, zero slots and no byte-sum bug');
 Check(D.HasContractCount and (D.ContractCount = 2),'Contract-list first nibble');
 S.Files[1].Records[0].Data[0] := $FF;
 Check(D.Raw.Files[1].Records[0].Data[0] <> $FF,'Decoded raw bytes own storage');
 S.Files[1].Records[0].Data := Copy(Full,0,29);
 D := TMobibCodec.Decode(S,mlRaw); Check(not D.LayoutMatched and not D.Holder.Present,'Raw mode never applies known layout');
 S.Files[0].Records[0].Data := nil; SetLength(S.Files[0].Records[0].Data,29);
 PutBits(S.Files[0].Records[0].Data,6,7,1); PutBcd(S.Files[0].Records[0].Data,13,'056'); PutBcd(S.Files[0].Records[0].Data,25,'002');
 D := TMobibCodec.Decode(S,mlLegacy056001); Check(not D.LayoutMatched and not D.Holder.Present and (Length(D.Raw.Files) = 6),'Unknown network not mislabelled as known MOBIB');
 S.Files[0].Records[0].Data := nil; SetLength(S.Files[0].Records[0].Data,29);
 PutBits(S.Files[0].Records[0].Data,6,7,1); PutBcd(S.Files[0].Records[0].Data,13,'056'); PutBcd(S.Files[0].Records[0].Data,25,'001');
 S.Files[1].Records[0].Data := nil; SetLength(S.Files[1].Records[0].Data,29);
 PutBits(S.Files[1].Records[0].Data,18,4,15); Raised := False;
 try D := TMobibCodec.Decode(S,mlLegacy056001); except on E: EMobibDecodeError do Raised := True; end;
 Check(Raised,'Malformed known holder BCD does not produce false identity');
end;
begin
 try TestPrimitives; TestSnapshot; Writeln('PASS: ',Checks,' MOBIB codec assertions.');
 except on E: Exception do begin Writeln('FAIL: ',E.ClassName,': ',E.Message); Halt(1); end; end;
end.
