#!/usr/bin/env python3
"""Generate synthetic DESFire EV2 management and Plus SL3 transcripts.

Uses Python cryptography independently of the Pascal implementation. No hardware,
real credentials or card data. Run with --check to verify checked-in fixture bytes.
"""
import argparse
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher,algorithms,modes
from cryptography.hazmat.primitives.cmac import CMAC
import zlib
r=Path(__file__).resolve().parents[1]
Z=bytes(16);K=Z;A=bytes.fromhex('B04D0787C93EE0CC8CACC8E86F16C6FE');B=bytes.fromhex('0102030405060708090A0B0C0D0E0F10');TI=bytes.fromhex('11223344');NEW=bytes.fromhex('112233445566778899AABBCCDDEEFF00')
def enc(k,iv,d):return Cipher(algorithms.AES(k),modes.CBC(iv)).encryptor().update(d)
def cmac(k,d):c=CMAC(algorithms.AES(k));c.update(d);return c.finalize()
def mac(k,d):return cmac(k,d)[1::2]
def le(n,size=2):return n.to_bytes(size,'little')
def apdu(cmd,d=b''):return bytes([0x90,cmd,0,0])+ (bytes([len(d)])+d if d else b'')+b'\x00'
def evkeys(k):
 v=bytes.fromhex('A55A00010080')+A[:2]+bytes(x^y for x,y in zip(A[2:8],B[:6]))+B[6:]+A[8:]
 return cmac(k,v),cmac(k,bytes.fromhex('5AA5')+v[2:])
def auth(pairs,key=K,plus=False):
 if plus:
  pairs.append((bytes.fromhex('70004000'),b'\x90'+enc(key,Z,B)))
  pairs.append((b'\x72'+enc(key,Z,A+B[1:]+B[:1]),b'\x90'+enc(key,Z,TI+A[1:]+A[:1]+bytes(12))))
 else:
  pairs.append((apdu(0x71,b'\0\0'),enc(key,Z,B)+bytes.fromhex('91AF')))
  pairs.append((apdu(0xAF,enc(key,Z,A+B[1:]+B[:1])),enc(key,Z,TI+A[1:]+A[:1]+bytes(12))+bytes.fromhex('9100')))
class DF:
 def __init__(self,aid=1):self.p=[(apdu(0x5A,le(aid,3)),bytes.fromhex('9100'))];auth(self.p);self.e,self.m=evkeys(K);self.ctr=0
 def cmd(self,c,h=b'',body=b'',reply=b'',full=False):
  if full and body:
   padded=body+b'\x80'+bytes((15-len(body))%16);iv=enc(self.e,Z,bytes.fromhex('A55A')+TI+le(self.ctr)+bytes(8));body=enc(self.e,iv,padded)
  data=h+body;packet=data+mac(self.m,bytes([c])+le(self.ctr)+TI+data)
  self.ctr+=1;response=reply+mac(self.m,b'\0'+le(self.ctr)+TI+reply)+bytes.fromhex('9100')
  self.p.append((apdu(c,packet),response))
 def settings(self):self.cmd(0x45,reply=bytes.fromhex('0F930101021000'))
 def fresh(self,key=NEW):auth(self.p,key);self.e,self.m=evkeys(key);self.ctr=0
vectors={}
f=DF();f.settings();f.cmd(0x56,b'\x01\x02');vectors['DfInitialize']=f.p
f=DF();f.settings();f.cmd(0xC6,b'\x01\x01',NEW+b'\x34'+le(zlib.crc32(NEW)^0xFFFFFFFF,4),full=True);f.cmd(0x64,b'\x41\x01',reply=b'\x34');vectors['DfChangeInactive']=f.p
f=DF();f.settings();f.cmd(0x57,b'\x01\x21');vectors['DfFinalize']=f.p
f=DF();f.settings();f.settings();f.cmd(0x55,b'\x01');f.fresh();f.cmd(0x64,b'\0',reply=b'\x34');vectors['DfRoll']=f.p
f=DF(0);f.cmd(0x5C,b'\x02',bytes.fromhex('067777710280'),full=True);vectors['DfConfigAts']=f.p
f=DF();f.cmd(0x5C,b'\x09',bytes.fromhex('0300000000E80300000000000001'),full=True);vectors['DfConfigValue']=f.p
old=bytes.fromhex('000000E0000100');desired=bytes.fromhex('004000E0000100C1F121200000430000430000')
f=DF();f.settings();f.cmd(0xF5,b'\0',reply=old);f.cmd(0x5F,b'\0',desired[1:4]+desired[7:],full=True);f.cmd(0xF5,b'\0',reply=desired);vectors['DfSdmChange']=f.p
f=DF();f.cmd(0xF5,b'\0',reply=desired);vectors['DfSdmRead']=f.p
f=DF();f.settings();f.cmd(0x64,bytes.fromhex('4080'),reply=bytes.fromhex('0121'));vectors['DfSetVersions']=f.p
f=DF(0);f.cmd(0x45,reply=bytes.fromhex('0F81'));f.cmd(0x6A);header=bytes.fromhex('5634120F930101021000');f.cmd(0xCA,header)
f.p.append((apdu(0x5A,bytes.fromhex('563412')),bytes.fromhex('9100')));f.p.append((apdu(0x45),header[3:]+bytes.fromhex('9100')))
f.p.append((apdu(0x5A,bytes(3)),bytes.fromhex('9100')));auth(f.p);vectors['DfCreate']=f.p
# Plus SL3 vectors use the documented 16-bit counters, independent AES/CMAC.
v=A[11:]+B[11:]+bytes(x^y for x,y in zip(A[4:9],B[4:9]))+b'\x11';PE=enc(K,Z,v)
v=A[7:12]+B[7:12]+bytes(x^y for x,y in zip(A[:5],B[:5]))+b'\x22';PM=enc(K,Z,v)
OLD=bytes(range(16));DATA=bytes(range(16,32))
for mode in [0,1]:
 for write in [False,True]:
  p=[];auth(p,plus=True);rc=wc=0
  def read(value):
   global rc,wc
   h=bytes([0x33 if mode==0 else 0x31,2,0,1]);packet=h+mac(PM,h[:1]+le(rc)+TI+h[1:]);rc+=1
   iv=(le(rc)+le(wc))*3+TI;payload=value if mode==0 else enc(PE,iv,value)
   response=b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload);p.append((packet,response))
  read(OLD)
  if write:
   iv=TI+(le(rc)+le(wc))*3;payload=DATA if mode==0 else enc(PE,iv,DATA);h=bytes([0xA3 if mode==0 else 0xA1,2,0])+payload
   packet=h+mac(PM,h[:1]+le(wc)+TI+h[1:]);wc+=1;p.append((packet,b'\x90'+mac(PM,b'\x90'+le(wc)+TI)));read(DATA)
  vectors['Plus'+('Mac' if mode==0 else 'Full')+('Write' if write else 'Read')]=p
  if mode==1 and not write:
   pn=list(p); h=bytes.fromhex('31020001'); cipher=enc(PE,(le(1)+le(0))*3+TI,DATA)
   pn[-1]=(pn[-1][0],b'\x90'+cipher+mac(PM,b'\x90'+le(1)+TI+h[1:]+cipher));vectors['PlusFullReadNew']=pn
# Explicit 4K high-sector and full fifteen-block read, with the same independent primitive vectors.
for writing in [False,True]:
 p=[];auth(p,plus=True);p[0]=(bytes.fromhex('70404000'),p[0][1]);rc=wc=0
 def high_read(value,count):
  global rc,wc
  h=bytes([0x31,128,0,count]);packet=h+mac(PM,h[:1]+le(rc)+TI+h[1:]);rc+=1
  payload=enc(PE,(le(rc)+le(wc))*3+TI,value)
  p.append((packet,b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload)))
 high_read(OLD if writing else bytes(range(240)),1 if writing else 15)
 if writing:
  payload=enc(PE,TI+(le(rc)+le(wc))*3,DATA);h=bytes.fromhex('A18000')+payload
  packet=h+mac(PM,h[:1]+le(wc)+TI+h[1:]);wc+=1
  p.append((packet,b'\x90'+mac(PM,b'\x90'+le(wc)+TI)));high_read(DATA,1)
 vectors['Plus4K'+('Write' if writing else 'Read')]=p
s='''unit DesfirePlus.Vectors;
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
'''
for name in vectors:s+=f'/// <summary>Returns independent synthetic {name} native protocol vector.</summary>\n/// <returns>Owned literal command/response pairs.</returns>\nfunction {name}: TExtendedPairs;\n'
s+='implementation\n'
for name,p in vectors.items():
 s+=f'function {name}: TExtendedPairs;\nbegin\n  Result := nil; SetLength(Result,{len(p)});\n'
 for i,(c,resp) in enumerate(p):s+=f"  Result[{i}].Command := '{c.hex().upper()}';\n  Result[{i}].Response := '{resp.hex().upper()}';\n"
 s+='end;\n'
s+='end.\n'
output=b'\xef\xbb\xbf'+s.replace('\n','\r\n').encode()
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check',action='store_true')
args=parser.parse_args()
target=r/'tests/contactless/DesfirePlus.Vectors.pas'
if args.check:
 if target.read_bytes()!=output: raise SystemExit('Fixture bytes differ; regenerate and review changes.')
 print('PASS: independent DESFire/Plus fixtures match checked-in bytes.')
else:
 target.write_bytes(output)
 print('Generated',len(vectors),'independent transcripts.')
