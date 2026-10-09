program MobibSubscriptionTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.MOBIB.Data, ERD.Card.MOBIB.Subscriptions;
var Checks:Integer;
procedure Check(const V:Boolean);
begin Inc(Checks);if not V then raise Exception.Create('MOBIB subscription regression.');end;
procedure Put(var B:TBytes;const Offset,Count:Integer;const V:Cardinal);
var I,P:Integer;
begin for I:=0 to Count-1 do begin P:=Offset+I;
 if (V and (Cardinal(1) shl (Count-I-1)))<>0 then B[P div 8]:=B[P div 8] or (1 shl (7-P mod 8));end;end;
procedure Tests;
var B:TBytes;D:TMobibSubscription;Snapshot:TMobibData;A:TMobibSubscriptions;I,Mask,Offset:Integer;Failed:Boolean;
begin
 for I:=0 to 3 do begin
  SetLength(B,29);FillChar(B[0],29,0);Put(B,0,6,I);Put(B,27,14,$2803);Put(B,41,14,200);Put(B,103,16,1850);
  D:=TMobibSubscriptionCodec.Decode(B,3,True,0);Check(D.LayoutMatched);Check(D.Version=I);Check(D.RecordNumber=3);
  Check(D.Tariff=$2803);Check(D.ProductName='JUMP 10 trips');Check(D.PriceCents=1850);Check(D.HasSaleDate);
  Check(D.SaleDate=EncodeDate(1997,1,1)+200);Check(D.HasRemainingTrips);Check(D.RemainingTrips=0);Check(D.Kind=mskTrips);Check(D.DecodedBits=232);
  B[0]:=$FF;Check(D.Raw[0]<>B[0]);
 end;
 for Mask:=0 to 31 do begin
  SetLength(B,29);FillChar(B[0],29,0);Put(B,0,6,4);Put(B,25,14,$303D);Put(B,89,16,850);Put(B,111,5,Mask);Offset:=116;
  for I:=0 to 4 do if (Mask and (1 shl I))<>0 then case I of
   0,1:Inc(Offset,5);
   2:begin Put(B,Offset,14,250);Inc(Offset,14);end;
   3:begin Put(B,Offset,2,3);Inc(Offset,2);Put(B,Offset,8,90);Inc(Offset,8);end;
   4:Inc(Offset,8);
  end;
  D:=TMobibSubscriptionCodec.Decode(B,1,True,12);Check(D.LayoutMatched);Check(D.Kind=mskTime);Check(D.Tariff=$303D);
  Check(not D.HasRemainingTrips);Check(D.Counter=12);Check(D.HasSaleDate=((Mask and 4)<>0));Check(D.HasDuration=((Mask and 8)<>0));Check(D.DecodedBits=Offset+24);
  if D.HasSaleDate then Check(D.SaleDate=EncodeDate(1997,1,1)+250);
  if D.HasDuration then begin Check(D.DurationUnitCode=3);Check(D.DurationValue=90);end;
 end;
 B:=nil;SetLength(B,29);Put(B,0,6,4);Put(B,25,14,$2801);
 D:=TMobibSubscriptionCodec.Decode(B,1,False,0);Check(not D.HasCounter);Check(not D.HasRemainingTrips);Check(not D.HasSaleDate);Check(not D.HasDuration);
 Put(B,0,6,63);D:=TMobibSubscriptionCodec.Decode(B,1,True,4);Check(not D.LayoutMatched);Check(D.Kind=mskUnknown);Check(D.Tariff=0);Check(D.ProductName='');Check(not D.HasRemainingTrips);
 SetLength(B,1);B[0]:=$10;Failed:=False;try D:=TMobibSubscriptionCodec.Decode(B,1,False,0);except on E:EMobibDecodeError do Failed:=True;end;Check(Failed);
 B:=nil;SetLength(B,29);Put(B,0,6,3);Put(B,27,14,$2803);
 Snapshot:=Default(TMobibData);Snapshot.LayoutMatched:=True;SetLength(Snapshot.Raw.Files,1);Snapshot.Raw.Files[0].LogicalId:=$2020;
 SetLength(Snapshot.Raw.Files[0].Records,1);Snapshot.Raw.Files[0].Records[0].Number:=3;Snapshot.Raw.Files[0].Records[0].Data:=B;
 SetLength(Snapshot.Counters,2);Snapshot.Counters[0].RecordNumber:=1;Snapshot.Counters[0].Slot:=1;Snapshot.Counters[0].Value:=99;
 Snapshot.Counters[1].RecordNumber:=1;Snapshot.Counters[1].Slot:=3;Snapshot.Counters[1].Value:=7;
 A:=TMobibSubscriptionCodec.DecodeSnapshot(Snapshot);Check(Length(A)=1);Check(A[0].Counter=7);Check(A[0].RemainingTrips=7);
 Snapshot.LayoutMatched:=False;A:=TMobibSubscriptionCodec.DecodeSnapshot(Snapshot);Check(Length(A)=0);
end;
begin try Tests;Writeln('MOBIB subscriptions: ',Checks,' assertions passed.');except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;end.
