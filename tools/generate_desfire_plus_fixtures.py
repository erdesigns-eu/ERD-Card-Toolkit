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
def auth(pairs,key=K,plus=False,slot=0x4000):
 if plus:
  pairs.append((b'\x70'+le(slot)+b'\x00',b'\x90'+enc(key,Z,B)))
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
# SL3 sector-key replacement: secure encrypted write at the full 16-bit key address,
# protected acknowledgement, RF release, fresh mutual authentication with the new key.
for target in [0x4000, 0x4001, 0x4040]:
 p=[];authority=target if target==0x4040 else 0x4000
 auth(p,plus=True,slot=authority)
 cipher=enc(PE,TI+bytes(12),NEW);h=b'\xA1'+le(target)+cipher
 p.append((h+mac(PM,h[:1]+le(0)+TI+h[1:]),b'\x90'+mac(PM,b'\x90'+le(1)+TI)))
 auth(p,key=NEW,plus=True,slot=target)
 vectors['PlusRotate'+hex(target)[2:].upper()]=p
# Explicit SL0 plan writes and commit, then independent fresh SL3 proofs for
# sector key, master/configuration keys and selected data. Switch key is ack-only.
p=[];entries=[(0x9000,K),(0x9001,K),(0x9003,K),(0x4000,NEW),(2,DATA)]
for addr,data in entries:p.append((b'\xA8'+le(addr)+data,b'\x90'))
p.append((b'\xAA',b'\x90'));auth(p,key=NEW,plus=True)
for slot in [0x9000,0x9001,0x4000]:auth(p,key=NEW if slot==0x4000 else K,plus=True,slot=slot)
auth(p,key=NEW,plus=True)
v=A[11:]+B[11:]+bytes(x^y for x,y in zip(A[4:9],B[4:9]))+b'\x11';e=enc(NEW,Z,v)
v=A[7:12]+B[7:12]+bytes(x^y for x,y in zip(A[:5],B[:5]))+b'\x22';m=enc(NEW,Z,v)
h=bytes.fromhex('31020001');payload=enc(e,le(1)+le(0)+le(1)+le(0)+le(1)+le(0)+TI,DATA)
p.append((h+mac(m,h[:1]+le(0)+TI+h[1:]),b'\x90'+payload+mac(m,b'\x90'+le(1)+TI+h[1:]+payload)))
vectors['PlusPersonalize']=p
# Raw Plus SL1 76/72 uses full-byte Type A frames, independent CRC-A and zero-IV AES.
def crc_a(data):
 crc=0x6363
 for byte in data:
  crc^=byte
  for bit in range(8):crc=(crc>>1)^ (0x8408 if crc&1 else 0)
 return data+le(crc)
for slot in [0x9004,0x9002,0x9003]:
 p=[(crc_a(b'\x76'+le(slot)),crc_a(b'\x90'+enc(K,Z,B))),
    (crc_a(b'\x72'+enc(K,Z,A+B[1:]+B[:1])),crc_a(b'\x90'+enc(K,Z,A[1:]+A[:1])))]
 vectors['PlusLevel'+hex(slot)[2:].upper()]=p
 if slot==0x9003:vectors['PlusLevel3Proof']=p+vectors['PlusFullRead']
# Complete ACR122 no-RATS raw authentication: bounded configuration, saved framing,
# independent CRC-bearing InCommunicateThru frames and baseline restoration.
def wrapped(payload,reply):return bytes.fromhex('FF000000')+bytes([len(payload)])+payload,reply+bytes.fromhex('9000')
p=[]
for cmd,resp in [('D43202000B0D','D533'),('D4320400','D533'),('D43205000000','D533'),
 ('D41224','D513'),('D4320100','D533'),('D4320101','D533'),
 ('D44A0100','D54B01010400080704112233445566'),('D40663026303633D','D507808000'),
 ('D408630200630300633D00','D509')]:p.append(wrapped(bytes.fromhex(cmd),bytes.fromhex(resp)))
for cmd,resp in vectors['PlusLevel9004']:
 p.append(wrapped(bytes.fromhex('D408630200630300633D00'),bytes.fromhex('D509')))
 p.append(wrapped(b'\xD4\x42'+cmd,b'\xD5\x43\x00'+resp))
 p.append(wrapped(bytes.fromhex('D406633C'),bytes.fromhex('D50700')))
for cmd,resp in [('D408630280630380633D00','D509'),('D4320100','D533'),('D41234','D513')]:
 p.append(wrapped(bytes.fromhex(cmd),bytes.fromhex(resp)))
vectors['PlusLevelAcr']=p
# Value-block read/write uses existing SL3 secured ordinary memory commands,
# including signed values and the stored logical address. No invented Bx commands.
def valueblock(value,addr):
 v=le(value&0xffffffff,4);return v+bytes(x^255 for x in v)+v+bytes([addr,addr^255,addr,addr^255])
for writing in [False,True]:
 p=[];auth(p,plus=True);rc=wc=0
 def read_value(value):
  global rc,wc
  h=bytes.fromhex('31020001');packet=h+mac(PM,h[:1]+le(rc)+TI+h[1:]);rc+=1
  payload=enc(PE,(le(rc)+le(wc))*3+TI,value)
  p.append((packet,b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload)))
 read_value(valueblock(-42,2))
 if writing:
  cipher=enc(PE,TI+(le(rc)+le(wc))*3,valueblock(100,2));h=bytes.fromhex('A10200')+cipher
  packet=h+mac(PM,h[:1]+le(wc)+TI+h[1:]);wc+=1
  p.append((packet,b'\x90'+mac(PM,b'\x90'+le(wc)+TI)));read_value(valueblock(100,2))
 vectors['PlusValue'+('Write' if writing else 'Read')]=p
# Explicit SL2 first-authentication switch, CRC framed, followed by a fresh SL3 proof.
p=[];auth(p,plus=True,slot=0x9003)
vectors['PlusLevel2To3']=[(crc_a(c),crc_a(resp)) for c,resp in p]+vectors['PlusFullRead']
# Native value workflows: independent amount mode-2 padding, AES IV and write MAC.
# No ordinary A1 data write substitutes for B1/B3/B5/B7/B9/C3.
for operation in range(5):
 for separate in [False,True]:
  source=1 if separate else 2;target=2;old=valueblock(100,source);previous=valueblock(7,target) if separate else old
  result=100 if operation==4 else (142 if operation in [0,2] else 58)
  p=[];auth(p,plus=True);rc=wc=0
  def native_read(block,value):
   global rc,wc
   h=b'\x31'+le(block)+b'\x01';request=h+mac(PM,h[:1]+le(rc)+TI+h[1:]);rc+=1
   payload=enc(PE,(le(rc)+le(wc))*3+TI,value)
   p.append((request,b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload)))
  def native_value(cmd,block,destination=0,amount=42):
   global wc
   h=bytes([cmd])+le(block)
   if cmd in [0xB7,0xB9]:h+=le(destination)
   if cmd in [0xB1,0xB3,0xB7,0xB9]:h+=enc(PE,TI+(le(rc)+le(wc))*3,le(amount,4)+b'\x80'+bytes(11))
   request=h+mac(PM,h[:1]+le(wc)+TI+h[1:]);wc+=1
   p.append((request,b'\x90'+mac(PM,b'\x90'+le(wc)+TI)))
  native_read(source,old)
  if separate:native_read(target,previous)
  desired=valueblock(result,target)
  if desired!=previous:
   cmd=[0xB1,0xB3,0xB7,0xB9,0xC3][operation];native_value(cmd,source,target)
   if operation in [0,1,4]:native_value(0xB5,target)
   native_read(target,desired)
   if separate:native_read(source,old)
  vectors['PlusNative'+str(operation)+('Cross' if separate else 'Same')]=p
# 4K boundary vectors exercise 32-bit unsigned amounts and high physical addresses.
for decrement in [False,True]:
 p=[];auth(p,plus=True,slot=0x4040);rc=wc=0
 old=valueblock(2147483647 if decrement else -2147483648,128);previous=valueblock(7,129)
 def boundary_read(block,value):
  global rc,wc
  h=b'\x31'+le(block)+b'\x01';request=h+mac(PM,h[:1]+le(rc)+TI+h[1:]);rc+=1
  payload=enc(PE,(le(rc)+le(wc))*3+TI,value)
  p.append((request,b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload)))
 boundary_read(128,old);boundary_read(129,previous)
 h=bytes([0xB9 if decrement else 0xB7])+le(128)+le(129)+enc(PE,TI+(le(rc)+le(wc))*3,bytes.fromhex('FFFFFFFF80')+bytes(11))
 request=h+mac(PM,h[:1]+le(wc)+TI+h[1:]);wc+=1
 p.append((request,b'\x90'+mac(PM,b'\x90'+le(wc)+TI)))
 boundary_read(129,valueblock(-2147483648 if decrement else 2147483647,129));boundary_read(128,old)
 vectors['PlusNative4K'+('Decrement' if decrement else 'Increment')]=p
# Authenticated semantic failures: valid response MAC but incorrect destination or changed source.
for source_changed in [False,True]:
 p=list(vectors['PlusNative2Cross']);block=1 if source_changed else 2;rc=4 if source_changed else 3
 h=b'\x31'+le(block)+b'\x01';value=valueblock(101,1) if source_changed else valueblock(143,2)
 payload=enc(PE,(le(rc)+le(1))*3+TI,value)
 response=b'\x90'+payload+mac(PM,b'\x90'+le(rc)+TI+h[1:]+payload)
 index=-1 if source_changed else -2;p[index]=(p[index][0],response)
 vectors['PlusNativeBad'+('Source' if source_changed else 'Target')]=p
# ISO and EV2 file-management transcripts, independent AES/MAC and frame-preserved directories.
old_iso=bytes.fromhex('02000000E2')+b'OLD';new_iso=bytes.fromhex('56341205E1D276000085010100')
def df_directory(f,entries):
 before=len(f.p);f.cmd(0x6D,reply=b''.join(entries));command,response=f.p.pop()
 if not entries:f.p.append((command,response));return
 for index,entry in enumerate(entries):
  final=index==len(entries)-1
  f.p.append((command if index==0 else apdu(0xAF),entry+(response[-10:] if final else bytes.fromhex('91AF'))))
f=DF(0);f.cmd(0x45,reply=bytes.fromhex('0F81'));df_directory(f,[old_iso,new_iso,bytes.fromhex('03000002E2')+b'abcdefghijklmnop']);vectors['DfIsoDirectory']=f.p
f=DF(0);f.cmd(0x45,reply=bytes.fromhex('0F81'));f.cmd(0x6A,reply=bytes.fromhex('020000'));df_directory(f,[old_iso]);
f.cmd(0xCA,bytes.fromhex('5634120FA305E1D276000085010100'));df_directory(f,[old_iso,new_iso]);vectors['DfIsoCreateApplication']=f.p
f=DF();f.settings();f.cmd(0x61,reply=bytes.fromhex('03E104E1'));vectors['DfIsoFileIds']=f.p
for kind,command,tail in [(0,0xCD,bytes.fromhex('040000')),(1,0xCB,bytes.fromhex('040000')),(3,0xC1,bytes.fromhex('040000020000')),(4,0xC0,bytes.fromhex('040000020000'))]:
 f=DF();f.cmd(0x45,reply=bytes.fromhex('0FA3'));f.cmd(0x45,reply=bytes.fromhex('0FA3'));f.cmd(0x6F);f.cmd(0x61)
 f.cmd(command,bytes.fromhex('0004E1030000')+tail)
 settings=bytes([kind])+bytes.fromhex('030000')+tail+(bytes(3) if kind in [3,4] else b'')
 f.cmd(0xF5,b'\0',reply=settings);f.cmd(0x61,reply=bytes.fromhex('04E1'));vectors['DfIsoCreateFile'+str(kind)]=f.p
multi_old=bytes.fromhex('0003F0FF040000');multi_new=bytes.fromhex('0083F0FF040000010F00');data=bytes.fromhex('01020304');newdata=bytes.fromhex('AABBCCDD')
f=DF();f.settings();f.cmd(0xF5,b'\0',reply=multi_new);vectors['DfMultiSettings']=f.p
f=DF();f.settings();f.settings();f.cmd(0xF5,b'\0',reply=multi_old);f.cmd(0x5F,b'\0',bytes.fromhex('83F0FF010F00'),full=True);f.cmd(0xF5,b'\0',reply=multi_new);vectors['DfMultiChange']=f.p
def df_read_full(f,file,data):
 iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));padded=data+b'\x80'+bytes((15-len(data))%16)
 f.cmd(0xAD,bytes([file])+le(0,3)+le(len(data),3),reply=enc(f.e,iv,padded))
for writing in [False,True]:
 f=DF();f.settings();f.cmd(0xF5,b'\0',reply=multi_new);f.settings();df_read_full(f,0,data);f.cmd(0xF5,b'\0',reply=multi_new)
 if writing:
  f.cmd(0x8D,bytes.fromhex('00000000040000'),newdata,full=True);df_read_full(f,0,newdata);f.cmd(0xF5,b'\0',reply=multi_new)
 vectors['DfMulti'+('Write' if writing else 'Read')]=f.p
tmac=bytes.fromhex('0500F0EF0234')
f=DF();f.settings();f.settings();f.cmd(0x6F);f.cmd(0xCE,bytes.fromhex('0100F0EF02'),NEW+b'\x34',full=True);f.cmd(0xF5,b'\x01',reply=tmac);vectors['DfTmacCreate']=f.p
f=DF();f.settings();f.cmd(0xF5,b'\x01',reply=tmac);vectors['DfTmacSettings']=f.p
f=DF();f.settings();f.cmd(0xF5,b'\x01',reply=tmac);f.p.append((apdu(0xAD,bytes.fromhex('010000000C0000')),bytes.fromhex('FFFFFFFF11223344556677889100')));f.ctr+=1;f.cmd(0xF5,b'\x01',reply=tmac);vectors['DfTmacRecord']=f.p
# AES TMAC transaction profile follows public MF2DLHX0 section 10.3 canonical TMI.
UID=bytes.fromhex('04112233445566');READER=bytes.fromhex('102132435465768798A9BACBDCEDFE0F')
TM_MAC=cmac(NEW,bytes.fromhex('5A00010080')+le(1,4)+UID)
TM_ENC=cmac(NEW,bytes.fromhex('A500010080')+le(1,4)+UID)
def align(data):return data+bytes((-len(data))%16)
def tmi_data(command,file,value):return align(bytes([command,file])+le(0,3)+le(len(value),3))+align(value)
for reader_id in [False,True]:
 for action in ['write','read','abort']:
  f=DF();f.cmd(0x6F,reply=bytes.fromhex('0001'));backup=bytes.fromhex('01030000040000');tmsettings=bytes.fromhex('050000EF0234') if reader_id else bytes.fromhex('0500F0EF0234')
  f.cmd(0xF5,b'\0',reply=backup);f.cmd(0xF5,b'\x01',reply=tmsettings)
  iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
  tmi=b''
  if reader_id:
   enc_tmri=enc(TM_ENC,Z,bytes(16));iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8))
   f.cmd(0xC8,READER,reply=enc_tmri);tmi+=align(b'\xC8'+READER+enc_tmri)
  old=bytes.fromhex('01020304');new=bytes.fromhex('AABBCCDD')
  f.cmd(0xF5,b'\0',reply=backup)
  df_read_full(f,0,old);tmi+=tmi_data(0xAD,0,old);f.cmd(0xF5,b'\0',reply=backup)
  if action=='write':
   f.cmd(0x8D,bytes.fromhex('00000000040000'),new,full=True);tmi+=tmi_data(0x8D,0,new)
  if action=='abort':f.cmd(0xA7)
  else:
   f.cmd(0xF5,b'\x01',reply=tmsettings);receipt=le(1,4)+mac(TM_MAC,tmi);f.cmd(0xC7,b'\x01',reply=receipt)
   if action=='write':
    f.cmd(0xF5,b'\0',reply=backup);df_read_full(f,0,new);f.cmd(0xF5,b'\0',reply=backup)
  vectors['DfTmac'+('Reader' if reader_id else '')+action.title()]=f.p
# Valid secure-session MAC with incorrect transaction MAC or counter must fail offline receipt validation.
for bad_counter in [False,True]:
 p=list(vectors['DfTmacWrite']);index=next(i for i,(c,resp) in enumerate(p) if c[1]==0xC7)
 command,response=p[index];data=response[:12];ctr=8 # 6F,F5,F5,51,F5,AD,8D,F5,C7 -> response counter 9
 ctr=index-2
 if bad_counter:data=le(2,4)+data[4:]
 else:data=data[:4]+bytes([data[4]^1])+data[5:]
 p[index]=(command,data+mac(evkeys(K)[1],b'\0'+le(ctr)+TI+data)+bytes.fromhex('9100'))
 vectors['DfTmacBad'+('Counter' if bad_counter else 'Mac')]=p
# Independent literal cryptographic helpers, encoded as value pairs rather than APDU exchanges.
vectors['DfTmacCrypto']=[(bytes.fromhex('5A00010080')+le(1,4)+UID,TM_MAC),
 (bytes.fromhex('A500010080')+le(1,4)+UID,TM_ENC),
 (tmi_data(0xAD,0,bytes.fromhex('01020304'))+tmi_data(0x8D,0,bytes.fromhex('AABBCCDD')),mac(TM_MAC,tmi_data(0xAD,0,bytes.fromhex('01020304'))+tmi_data(0x8D,0,bytes.fromhex('AABBCCDD')))),
 (READER,enc(TM_ENC,Z,READER))]
# TMAC communication modes, AES counter-limit update/deletion and nonmaster multi-access.
for mode in [1,3]:
 f=DF();metadata=bytes([5,mode])+bytes.fromhex('F0EF0234');f.settings();f.cmd(0xF5,b'\x01',reply=metadata)
 record=bytes.fromhex('010000001122334455667788')
 if mode==3:df_read_full(f,1,record)
 else:f.cmd(0xAD,bytes.fromhex('010000000C0000'),reply=record)
 f.cmd(0xF5,b'\x01',reply=metadata);vectors['DfTmacRecord'+('Mac' if mode==1 else 'Full')]=f.p
f=DF();f.settings();f.settings();f.cmd(0xF5,b'\x01',reply=tmac);f.cmd(0x5F,b'\x01',bytes.fromhex('33F0EFE8030000'),full=True);f.cmd(0xF5,b'\x01',reply=bytes.fromhex('0533F0EF0234E8030000'));vectors['DfTmacLimitChange']=f.p
f=DF();f.settings();f.cmd(0xF5,b'\x01',reply=tmac);f.cmd(0xDF,b'\x01');f.cmd(0x6F,reply=b'\0');vectors['DfTmacDelete']=f.p
f=DF();f.p[1]=(apdu(0x71,b'\x01\x00'),f.p[1][1]);settings=bytes.fromhex('0B930101021000');rights=bytes.fromhex('0083F0FF040000011F11')
f.cmd(0x45,reply=settings);f.cmd(0xF5,b'\0',reply=rights);f.cmd(0x45,reply=settings);df_read_full(f,0,bytes.fromhex('01020304'));f.cmd(0xF5,b'\0',reply=rights);vectors['DfMultiNonMasterRead']=f.p
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
