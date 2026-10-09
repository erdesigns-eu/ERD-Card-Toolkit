program CalypsoSamTests;
{$IFDEF FPC}{$MODE DELPHI}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}
uses
{$IFDEF FPC}SysUtils,{$ELSE}System.SysUtils,{$ENDIF}
 ERD.Card.Bytes, ERD.Card.Transport, ERD.Card.Contactless.Calypso,
 ERD.Card.Contactless.Calypso.SAM;
type
 TStep=record C,R:TBytes; Fails:Boolean; end;
 TScript=class(TInterfacedObject,ICardTransport,ICardTransaction)
 public
  Steps:array of TStep; Position,Begins,Ends:Integer; Active,EndFails:Boolean;
  procedure Add(const C,R:string);
  function Exchange(const C:TBytes):TBytes;
  procedure BeginTransaction;
  procedure EndTransaction;
 end;
var Checks:Integer;
procedure Check(const V:Boolean);
begin Inc(Checks);if not V then raise Exception.Create('Native Calypso regression.');end;
procedure TScript.Add(const C,R:string);
var N:Integer;
begin N:=Length(Steps);SetLength(Steps,N+1);Steps[N].C:=HexToBytes(StringReplace(C,' ','',[rfReplaceAll]));Steps[N].R:=HexToBytes(StringReplace(R,' ','',[rfReplaceAll]));end;
function TScript.Exchange(const C:TBytes):TBytes;
begin Check(Position<Length(Steps));Check(BytesToHex(C)=BytesToHex(Steps[Position].C));Result:=Copy(Steps[Position].R,0,Length(Steps[Position].R));Inc(Position);if Steps[Position-1].Fails then raise ECardTransportError.Create('Injected primary exchange failure.');end;
procedure TScript.BeginTransaction;
begin Check(not Active);Active:=True;Inc(Begins);end;
procedure TScript.EndTransaction;
begin Check(Active);Active:=False;Inc(Ends);if EndFails then raise ECardTransportError.Create('Injected release failure.');end;
procedure Run(const Rev:TCalypsoSessionRevision;const BadMac,ReadError,RejectWrite,Abandon:Boolean);
var Card,Sam:TScript;CT,ST,Adapter:ICardTransport;Provider:ICalypsoSecureSessionProvider;
 Session:ICalypsoSecureReadSession;Cla,OpenCommand,OpenData,Challenge,Mac,Init:string;Dialect:TCalypsoDialect;Failed:Boolean;B:TBytes;
begin
 Card:=TScript.Create;CT:=Card;Sam:=TScript.Create;ST:=Sam;
 Cla:='94';Dialect:=cdLegacy94;Challenge:='01020304';Mac:='11223344';Init:='80 8A 00 FF';
 case Rev of
  csrRevision1:begin OpenCommand:='94 8A 01 00 04';OpenData:='10203040';end;
  csrRevision2:begin OpenCommand:='94 8A 81 00 04';OpenData:='2210203040';end;
  csrRevision3:begin Cla:='00';Dialect:=cdIso00;OpenCommand:='00 8A 01 01 04';OpenData:='1020304000112200';end;
  csrRevision32:begin Cla:='00';Dialect:=cdIso00;OpenCommand:='00 8A 01 02 09 00';OpenData:='102030405060708002112200';Challenge:='0102030405060708';Mac:='1122334455667788';Init:='80 8A 02 FF';end;
 end;
 Sam.Add('80 14 00 00 08 0102030405060708','9000');
 if Rev=csrRevision32 then Sam.Add('80 84 00 00 08',Challenge+'9000') else Sam.Add('80 84 00 00 04',Challenge+'9000');
 Card.Add(OpenCommand+Challenge+'00',OpenData+'9000');
 Sam.Add(Init+IntToHex(Length(HexToBytes(OpenData))+2,2)+'1122'+OpenData,'9000');
 if not (RejectWrite or Abandon) then begin
  if ReadError then Card.Add(Cla+' B2 01 04 1D','6982') else begin
   if Cla='94' then Card.Add(Cla+' A4 00 00 02 2020 00','AABB9000') else Card.Add(Cla+' A4 09 00 02 2020 00','AABB9000');
   if Cla='94' then Sam.Add('80 8C 00 00 07 94A40000022020','9000') else Sam.Add('80 8C 00 00 07 00A40900022020','9000');
   Sam.Add('80 8C 00 00 04 AABB9000','9000');
   Card.Add(Cla+' B2 01 04 1D','CAFE9000');Sam.Add('80 8C 00 00 05 '+Cla+'B201041D','9000');Sam.Add('80 8C 00 00 04 CAFE9000','9000');
   if Rev=csrRevision32 then Sam.Add('80 8E 00 00 08',Mac+'9000') else Sam.Add('80 8E 00 00 04',Mac+'9000');
   Card.Add(Cla+'8E8000'+IntToHex(Length(HexToBytes(Mac)),2)+Mac+'00',Mac+'9000');
   if BadMac then Sam.Add('80 82 00 00 '+IntToHex(Length(HexToBytes(Mac)),2)+Mac,'6988') else Sam.Add('80 82 00 00 '+IntToHex(Length(HexToBytes(Mac)),2)+Mac,'9000');
  end;
 end;
 if ReadError or RejectWrite or Abandon then Card.Add(Cla+'8E000000','9000');
 Provider:=TCalypsoSamSessionProvider.Create(ST,Rev,HexToBytes('0102030405060708'),1,$11,$22);
 Session:=Provider.Open(CT,Dialect,nil);Adapter:=Session.GetTransport;
 if Abandon then begin Adapter:=nil;Session:=nil;end
 else if RejectWrite then begin Failed:=False;try Adapter.Exchange(HexToBytes(Cla+'D6000001AA'));except on E:ECalypsoError do Failed:=True;end;Check(Failed);Session.Abort;end
 else if ReadError then begin Failed:=False;try Adapter.Exchange(HexToBytes(Cla+'B201041D'));except on E:ECalypsoError do Failed:=True;end;Check(Failed);Session.Abort;end
 else begin
  if Cla='94' then B:=Adapter.Exchange(HexToBytes(Cla+'A4000002202000')) else B:=Adapter.Exchange(HexToBytes(Cla+'A4090002202000'));
  Check(BytesToHex(B)='AABB9000');B:=Adapter.Exchange(HexToBytes(Cla+'B201041D'));Check(BytesToHex(B)='CAFE9000');
  Failed:=False;try Session.Finish;except on E:ECalypsoError do Failed:=True;end;Check(Failed=BadMac);
  Failed:=False;try Adapter.Exchange(HexToBytes(Cla+'B201041D'));except on E:ECalypsoError do Failed:=True;end;Check(Failed);
 end;
 Check(Card.Position=Length(Card.Steps));Check(Sam.Position=Length(Sam.Steps));Check(Sam.Begins=1);Check(Sam.Ends=1);Check(not Sam.Active);
 Adapter:=nil;Session:=nil;Provider:=nil;CT:=nil;ST:=nil;
end;
procedure Invalid;
var S:TScript;ST:ICardTransport;P:ICalypsoSecureSessionProvider;Failed:Boolean;I:Integer;
begin
 S:=TScript.Create;ST:=S;
 for I:=0 to 3 do begin Failed:=False;try
  case I of
   0:P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,nil,1,1,1);
   1:P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,HexToBytes('0102030405060708'),0,1,1);
   2:P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,HexToBytes('0102030405060708'),1,0,1);
   3:P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,HexToBytes('0102030405060708'),1,1,1,$00);
  end;
 except on E:ECalypsoError do Failed:=True;end;Check(Failed);Check(S.Position=0);Check(S.Begins=0);end;
 P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,HexToBytes('0102030405060708'),1,1,1);
 Failed:=False;try P.Open(ST,cdIso00,nil);except on E:ECalypsoError do Failed:=True;end;Check(Failed);Check(S.Begins=0);P:=nil;ST:=nil;
end;
procedure OpenFailures;
var Card,Sam:TScript; CT,ST:ICardTransport;P:ICalypsoSecureSessionProvider;
 Session:ICalypsoSecureReadSession;I:Integer;Failed:Boolean;
begin
 for I:=0 to 4 do begin
  Card:=TScript.Create;CT:=Card;Sam:=TScript.Create;ST:=Sam;
  Sam.Add('80140000080102030405060708','9000');
  if I=0 then Sam.Add('8084000004','0102039000') else Sam.Add('8084000004','010203049000');
  if I>0 then begin
   case I of
    1:Card.Add('008A0101040102030400','10203040003322009000');
    2:begin Card.Add('008A0101040102030400','10203040001122009000');Sam.Add('808A00FF0A11221020304000112200','6985');end;
    3:begin Card.Add('008A0101040102030400','');Card.Steps[0].Fails:=True;Sam.EndFails:=True;end;
    4:Card.Add('008A0101040102030400','6988');
   end;
   Card.Add('008E000000','9000');
  end;
  P:=TCalypsoSamSessionProvider.Create(ST,csrRevision3,HexToBytes('0102030405060708'),1,$11,$22);
  Failed:=False;try Session:=P.Open(CT,cdIso00,nil);
  except on E:Exception do begin Failed:=True;if I=3 then Check(E.Message='Injected primary exchange failure.');end;end;
  Check(Failed);Check(Session=nil);Check(Card.Position=Length(Card.Steps));Check(Sam.Position=Length(Sam.Steps));Check(Sam.Ends=1);Check(not Sam.Active);
  P:=nil;CT:=nil;ST:=nil;
 end;
end;
var R:TCalypsoSessionRevision;
begin
 try
  for R:=Low(TCalypsoSessionRevision) to High(TCalypsoSessionRevision) do begin
   Run(R,False,False,False,False);Run(R,True,False,False,False);
   Run(R,False,True,False,False);Run(R,False,False,True,False);Run(R,False,False,False,True);
  end;
  Invalid;OpenFailures;Writeln('Native Calypso SAM: ',Checks,' assertions passed.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);Halt(1);end;end;
end.
