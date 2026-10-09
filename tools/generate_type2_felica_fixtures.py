#!/usr/bin/env python3
"""Generate fixed synthetic Type 2/FeliCa transcripts independently of the Pascal code."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
idm=bytes.fromhex('0102030405060708')
def crc(x):
 v=0x6363
 for b in x:
  b^=v&255;b^=(b<<4)&255;v=((v>>8)^(b<<8)^(b<<3)^(b>>4))&65535
 return v.to_bytes(2,'little')
def rf(x):return x+crc(x)
def cmd(service,blocks,data=None):
 b=bytearray([0,6 if data is None else 8])+idm+bytes([1])+service.to_bytes(2,'little')+bytes([len(blocks)])
 for block in blocks:b+=(bytes([128,block]) if block<256 else bytes([0])+block.to_bytes(2,'little'))
 if data is not None:b+=data
 b[0]=len(b);return bytes(b)
def rsp(data=None):
 b=bytearray([0,9 if data is None else 7])+idm+b'\0\0'
 if data is not None:b+=bytes([len(data)//16])+data
 b[0]=len(b);return bytes(b)
def attribute(length,updating=False):
 b=bytearray.fromhex('100302012C0000000000010000000000');b[9]=15 if updating else 0;b[11:14]=length.to_bytes(3,'big');b[14:16]=sum(b[:14]).to_bytes(2,'big');return bytes(b)
def t3(read=False,clear=False):
 old=bytes.fromhex('D101045402656E41');new=bytes.fromhex('D101295402656E')+b'B'*38
 if clear:new=b''
 storage=bytearray([0xcc]*4800);storage[:len(old)]=old;attr=attribute(len(old));pairs=[]
 def readblocks(first,count):pairs.append((cmd(11,list(range(first,first+count))),rsp(attr if first==0 else storage[(first-1)*16:(first-1+count)*16])))
 def writeblocks(first,data):
  nonlocal attr
  pairs.append((cmd(9,list(range(first,first+len(data)//16)),data),rsp()))
  if first==0:attr=data
  else:storage[(first-1)*16:(first-1)*16+len(data)]=data
  readblocks(first,len(data)//16)
 readblocks(0,1);readblocks(1,1);readblocks(0,1)
 if read:return pairs
 writeblocks(0,attribute(len(old),True))
 for first in range(1,(len(new)+15)//16+1,2):
  count=min(2,(len(new)+15)//16-first+1);readblocks(first,count)
  data=bytearray(storage[(first-1)*16:(first-1+count)*16]);replacement=new[(first-1)*16:(first-1+count)*16];data[:len(replacement)]=replacement;writeblocks(first,data)
 writeblocks(0,attribute(len(new)))
 readblocks(0,1)
 if new:readblocks(1,(len(new)+15)//16)
 readblocks(0,1);return pairs
vectors={'FelicaRead':[(cmd(11,[3,256]),rsp(bytes(range(32))))], 'FelicaWrite':[(cmd(11,[3,256]),rsp(bytes(range(32)))),(cmd(9,[3,256],bytes(range(32,64))),rsp()),(cmd(11,[3,256]),rsp(bytes(range(32,64))))], 'Type3Read':t3(read=True),'Type3Write':t3(),'Type3Clear':t3(clear=True)}
# Seven models with independent EEPROM layouts, no production credentials.
configpages=[16,37,41,131,227,16,37]
for m,page in enumerate(configpages):
 cfg=bytes.fromhex('082200FF38556677') # preserved MOD/mirror/RFUI and counter bits
 auth=(rf(bytes.fromhex('1B01020304')),rf(bytes.fromhex('A1B2')))
 readcfg=(rf(bytes([0x3a,page,page+1])),rf(cfg));base=[auth,readcfg]
 vectors[f'T2Config{m}']=base
 desired=bytearray(cfg);desired[3]=4;desired[4]=(desired[4]&0x78)|0x83
 vectors[f'T2Configure{m}']=base+[(rf(bytes([0xa2,page+1])+desired[4:]),b'\x0a'),(rf(bytes([0xa2,page])+desired[:4]),b'\x0a'),auth,(rf(bytes([0x3a,page,page+1])),rf(desired))]
 vectors[f'T2Credentials{m}']=[auth,(rf(bytes([0xa2,page+3])+bytes.fromhex('C3D40000')),b'\x0a'),(rf(bytes([0xa2,page+2])+bytes.fromhex('05060708')),b'\x0a'),(rf(bytes.fromhex('1B05060708')),rf(bytes.fromhex('C3D4')))]
 if m<5:
  idx=0 if m<2 else 2;vectors[f'T2Counter{m}']=[auth,(rf(bytes([0x39,idx])),rf(bytes.fromhex('563412')))]
# Protected EV1-48 NDEF mapping, independent fixed page-phase transcript.
old=bytes.fromhex('D101045402656E41');new=bytes.fromhex('D101045402656E42');cc=bytes.fromhex('E1100600');mem=bytearray(48);mem[:11]=bytes([3,8])+old+bytes([0xfe]);cfg=bytes.fromhex('0000000480000000');auth=(rf(bytes.fromhex('1B01020304')),rf(bytes.fromhex('A1B2')))
def fast(first,count,data):return (rf(bytes([0x3a,first,first+count-1])),rf(data))
vectors['T2NdefRead']=[auth,fast(3,1,cc),fast(4,12,mem)]
pairs=[auth,fast(16,2,cfg),fast(3,1,cc),fast(4,12,mem),fast(2,1,bytes(4))]
def apply(target,descending=False):
 for i in (range(11,-1,-1) if descending else range(12)):
  data=target[i*4:i*4+4]
  if mem[i*4:i*4+4]==data:continue
  pairs.append((rf(bytes([0xa2,i+4])+data),b'\x0a'));mem[i*4:i*4+4]=data;pairs.append(fast(i+4,1,data))
a=bytearray(mem);a[1]=0;apply(a)
a=bytearray(mem);a[2:10]=new;apply(a,True)
a=bytearray(mem);a[1]=8;apply(a)
pairs+=[fast(4,12,mem),fast(3,1,cc)];vectors['T2NdefWrite']=pairs
lines=['unit Type2Felica.Vectors;','{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}','interface','type',' /// <summary>One independently generated synthetic protocol exchange.</summary>',' TProtocolPair=record','  /// <summary>Complete literal outgoing frame.</summary>','  Command:string;','  /// <summary>Complete literal response frame.</summary>','  Response:string;',' end;',' /// <summary>Ordered complete synthetic exchange transcript.</summary>',' TProtocolPairs=array of TProtocolPair;','/// <summary>Selects a fixed independently generated synthetic exchange transcript.</summary>','/// <param name="Name">Exact developer fixture name.</param>','/// <returns>Independent ordered pairs; no production credentials.</returns>','function ProtocolPairs(const Name:string):TProtocolPairs;','implementation','uses {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF};','function ProtocolPairs(const Name:string):TProtocolPairs;','begin',' Result:=nil;']
for name,pairs in vectors.items():
 lines+= [f" if Name='{name}' then begin",f'  SetLength(Result,{len(pairs)});']
 for i,(command,response) in enumerate(pairs):lines += [f"  Result[{i}].Command:='{command.hex().upper()}'; Result[{i}].Response:='{response.hex().upper()}';"]
 lines+=['  Exit;',' end;']
lines+= [" raise Exception.Create('Unknown synthetic protocol fixture.');",'end;','end.']
(ROOT/'tests/contactless/Type2Felica.Vectors.pas').write_bytes(('\n'.join(lines)+'\n').replace('\n','\r\n').encode())
