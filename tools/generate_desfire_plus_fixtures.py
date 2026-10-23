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
  chunks=[packet[i:i+48] for i in range(0,len(packet),48)] or [b'']
  for i,chunk in enumerate(chunks):self.p.append((apdu(c if i==0 else 0xAF,chunk),response if i==len(chunks)-1 else bytes.fromhex('91AF')))
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
# ISO FID/DF name follow the complete AES key-set header; FID is native LE.
f=DF(0);f.cmd(0x45,reply=bytes.fromhex('0F81'));f.cmd(0x6A,reply=bytes.fromhex('020000'));df_directory(f,[old_iso])
iso_key_header=bytes.fromhex('5634120FB3012104100105E1D276000085010100')
f.cmd(0xCA,iso_key_header);df_directory(f,[old_iso,new_iso])
f.p.append((apdu(0x5A,bytes.fromhex('563412')),bytes.fromhex('9100')))
f.p.append((apdu(0x45),iso_key_header[3:10]+bytes.fromhex('9100')))
f.p.append((apdu(0x5A,bytes(3)),bytes.fromhex('9100')));auth(f.p)
f.e,f.m=evkeys(K);f.ctr=0
# A subsequent PICC directory operation proves authentication and counters were restored.
f.cmd(0x45,reply=bytes.fromhex('0F81'));df_directory(f,[old_iso,new_iso]);vectors['DfIsoCreateKeySets']=f.p
for error in ['Geometry','Fid','Name']:
 p=list(vectors['DfIsoCreateKeySets'])
 if error=='Geometry':
  i=next(i for i,(c,resp) in enumerate(p) if c==apdu(0x45))
  c,resp=p[i];p[i]=(c,resp[:3]+bytes([resp[3]^1])+resp[4:])
 else:
  # Alter the post-create ISO tuple and recompute its valid aggregate session MAC.
  i=next(i for i,(c,resp) in enumerate(p) if c==apdu(0xCA,iso_key_header+mac(evkeys(K)[1],b'\xCA'+le(3)+TI+iso_key_header)))
  i+=2;c,resp=p[i];entry=bytearray(resp[:-10]);entry[3 if error=='Fid' else 5]^=1
  aggregate=old_iso+bytes(entry);p[i]=(c,bytes(entry)+mac(evkeys(K)[1],b'\0'+le(5)+TI+aggregate)+bytes.fromhex('9100'))
 vectors['DfIsoCreateBad'+error]=p
# Standard writes are immediate; each range is verified and captured in TMI,
# then all final overlapping/disjoint ranges are checked after receipt verification.
for action in ['Write','Overlap','Disjoint','Noop','Abort','Repeat','Preimage','ImmediateMismatch','CommitMismatch']:
 f=DF();f.cmd(0x6F,reply=bytes.fromhex('0001'));standard=bytes.fromhex('00030000080000');tmsettings=bytes.fromhex('0500F0EF0234')
 f.cmd(0xF5,b'\0',reply=standard);f.cmd(0xF5,b'\x01',reply=tmsettings)
 iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
 tmi=b'';journal=[]
 changes=[(2,bytes.fromhex('01020304'),bytes.fromhex('AABBCCDD'))]
 if action=='Overlap':changes+=[(3,bytes.fromhex('BBCC'),bytes.fromhex('5566'))]
 if action=='Repeat':changes+=[(2,bytes.fromhex('AABBCCDD'),bytes.fromhex('22334455'))]
 if action=='Disjoint':changes=[(0,bytes.fromhex('0102'),bytes.fromhex('AABB')),(6,bytes.fromhex('0708'),bytes.fromhex('CCDD'))]
 if action=='Noop':changes=[(2,bytes.fromhex('01020304'),bytes.fromhex('01020304'))]
 def read_range(offset,value,capture=True):
  global tmi
  h=b'\0'+le(offset,3)+le(len(value),3)
  iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8))
  f.cmd(0xAD,h,reply=enc(f.e,iv,value+b'\x80'+bytes((15-len(value))%16)))
  if capture:tmi+=align(b'\xAD'+h)+align(value)
 for offset,before,after in changes:
  f.cmd(0xF5,b'\0',reply=standard);read_range(offset,before);f.cmd(0xF5,b'\0',reply=standard)
  if action=='Preimage':break
  if before==after:continue
  h=b'\0'+le(offset,3)+le(len(after),3);f.cmd(0x8D,h,after,full=True);tmi+=align(b'\x8D'+h)+align(after)
  for j,(start,current) in enumerate(journal):
   current=bytearray(current)
   for k in range(len(current)):
    if offset<=start+k<offset+len(after):current[k]=after[start+k-offset]
   journal[j]=(start,bytes(current))
  journal.append((offset,after))
  read_range(offset,before if action=='ImmediateMismatch' else after)
  if action=='ImmediateMismatch':break
  f.cmd(0xF5,b'\0',reply=standard)
 if action=='Abort':f.cmd(0xA7)
 elif action not in ['Preimage','ImmediateMismatch']:
  f.cmd(0xF5,b'\x01',reply=tmsettings);f.cmd(0xC7,b'\x01',reply=le(1,4)+mac(TM_MAC,tmi))
  for offset,after in journal:
   f.cmd(0xF5,b'\0',reply=standard)
   read_range(offset,bytes(len(after)) if action=='CommitMismatch' else after,False)
   if action=='CommitMismatch':break
   f.cmd(0xF5,b'\0',reply=standard)
 vectors['DfTmacStandard'+action]=f.p
# Acquired file type, write/read authority and bounds must refuse before any data mutation.
for name,metadata in [('DeniedWrite','0003F00F080000'),('DeniedRead','0003F0F0080000'),('WrongFile','01030000080000'),('Bounds','00030000080000')]:
 f=DF();f.cmd(0x6F,reply=bytes.fromhex('0001'));settings=bytes.fromhex(metadata);tmsettings=bytes.fromhex('0500F0EF0234')
 f.cmd(0xF5,b'\0',reply=settings);f.cmd(0xF5,b'\x01',reply=tmsettings)
 iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
 f.cmd(0xF5,b'\0',reply=settings);vectors['DfTmacStandard'+name]=f.p
# Combined GetFileSettings puts additional tuples after ordinary geometry, before SDM fields.
plain_sdm=bytes.fromhex('000000E0000100')
sdm_only=bytes.fromhex('004000E0000100C1F121200000430000430000')
combined_sdm=bytes.fromhex('00C000E0000100010101C1F121200000430000430000')
combined_plain=bytes.fromhex('008000E0000100010101')
f=DF();f.settings();f.cmd(0xF5,b'\0',reply=combined_sdm);vectors['DfSdmAccessRead']=f.p
for name,old_settings,new_settings in [('Enable',plain_sdm,combined_sdm),('DisableSdm',combined_sdm,combined_plain),('RemoveRights',combined_sdm,sdm_only),('RemoveBoth',combined_sdm,plain_sdm),('Noop',combined_sdm,combined_sdm),('BadPreimage',combined_sdm,combined_sdm),('BadPostimage',plain_sdm,combined_sdm)]:
 f=DF();f.settings();f.settings();f.settings();f.cmd(0xF5,b'\0',reply=old_settings)
 if name not in ['Noop','BadPreimage']:
  f.cmd(0x5F,b'\0',new_settings[1:4]+new_settings[7:],full=True)
  post=new_settings
  if name=='BadPostimage':post=new_settings[:8]+bytes.fromhex('0202')+new_settings[10:]
  f.cmd(0xF5,b'\0',reply=post)
 vectors['DfSdmAccess'+name]=f.p
# Full-record native BA update within one owned cyclic-record transaction.
for with_tmac in [False,True]:
 for action in ['Write','Repeat','Abort','Noop','Preimage','AppendConflict','ClearConflict','DifferentConflict','WrongCommit','AppendFirstConflict','ClearFirstConflict']:
  f=DF();settings=bytes.fromhex('04030000100000040000020000');tmsettings=bytes.fromhex('0500F0EF0234');records=OLD+DATA
  f.cmd(0x6F,reply=bytes.fromhex('0001') if with_tmac else b'\0');f.cmd(0xF5,b'\0',reply=settings)
  if with_tmac:
   f.cmd(0xF5,b'\x01',reply=tmsettings);iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
  tmi=b'';f.cmd(0xF5,b'\0',reply=settings)
  h=b'\0'+le(0,3)+le(2,3);iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0xAB,h,reply=enc(f.e,iv,records+b'\x80'+bytes(15)));tmi+=align(b'\xAB'+h)+records
  f.cmd(0xF5,b'\0',reply=settings)
  if action=='Preimage':vectors['DfRecord'+('Tmac' if with_tmac else '')+action]=f.p;continue
  if action in ['AppendFirstConflict','ClearFirstConflict']:
   if action=='AppendFirstConflict':
    h=b'\0'+le(0,3)+le(16,3);f.cmd(0x8B,h,NEW,full=True)
   else:f.cmd(0xEB,b'\0')
   f.cmd(0xF5,b'\0',reply=settings)
   vectors['DfRecord'+('Tmac' if with_tmac else '')+action]=f.p;continue
  changed=action!='Noop'
  if changed:
   h=b'\0'+le(1,3)+le(0,3)+le(16,3);f.cmd(0xBA,h,NEW,full=True);tmi+=align(b'\xBA'+h)+NEW;records=OLD+NEW
  if action=='Repeat':
   f.cmd(0xF5,b'\0',reply=settings);f.cmd(0xBA,h,OLD,full=True);tmi+=align(b'\xBA'+h)+OLD;records=OLD+OLD
  if action in ['AppendConflict','ClearConflict','DifferentConflict']:
   f.cmd(0xF5,b'\0',reply=settings);vectors['DfRecord'+('Tmac' if with_tmac else '')+action]=f.p;continue
  if action=='Abort' or (action=='Noop' and not with_tmac):
   if changed or with_tmac:f.cmd(0xA7)
  else:
   if with_tmac:f.cmd(0xF5,b'\x01',reply=tmsettings)
   f.cmd(0xC7,b'\x01' if with_tmac else b'\0',reply=le(1,4)+mac(TM_MAC,tmi) if with_tmac else b'')
   f.cmd(0xF5,b'\0',reply=settings);h=b'\0'+le(0,3)+le(2,3);iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));proof=bytes(32) if action=='WrongCommit' else records
   f.cmd(0xAB,h,reply=enc(f.e,iv,proof+b'\x80'+bytes(15)))
   if action!='WrongCommit':f.cmd(0xF5,b'\0',reply=settings)
  vectors['DfRecord'+('Tmac' if with_tmac else '')+action]=f.p
# Independent LRP implementation using the published AN12304 algorithms.
# No Pascal implementation is called to generate or verify these values.
import json
class LRP:
 def __init__(self,key,index=0):
  seed=enc(key,Z,b'\x55'*16);self.pt=[]
  for _ in range(16):self.pt.append(enc(seed,Z,b'\xAA'*16));seed=enc(seed,Z,b'\x55'*16)
  seed=enc(key,Z,b'\xAA'*16)
  for _ in range(index+1):self.uk=enc(seed,Z,b'\xAA'*16);seed=enc(seed,Z,b'\x55'*16)
 def evaluate(self,nibbles,final=True):
  current=self.uk
  for nibble in nibbles:current=enc(current,Z,self.pt[nibble])
  return enc(current,Z,Z) if final else current
 def block(self,data):return self.evaluate([int(x,16) for x in data.hex()])
 def cmac(self,data):
  def double(x):n=int.from_bytes(x,'big');return (((n<<1)&((1<<128)-1))^(0x87 if n>>127 else 0)).to_bytes(16,'big')
  k1=double(self.block(Z));k2=double(k1);whole=len(data)>0 and len(data)%16==0
  data=data if whole else data+b'\x80'+bytes((-len(data)-1)%16)
  data=data[:-16]+bytes(x^y for x,y in zip(data[-16:],k1 if whole else k2));state=Z
  for i in range(0,len(data),16):state=self.block(bytes(x^y for x,y in zip(state,data[i:i+16])))
  return state
 def crypt(self,data,counter,padding=True):
  if padding:data=data+b'\x80'+bytes((-len(data)-1)%16)
  out=b'';width=len(counter);n=int.from_bytes(counter,'big')
  for i in range(0,len(data),16):out+=enc(self.block((n%(1<<(width*8))).to_bytes(width,'big')),Z,data[i:i+16]);n+=1
  return out,n
published=json.loads((r/'tests/contactless/fixtures/lrp-nxp.json').read_text())['vectors']
vectors['LrpPublishedEval']=[]
for v in published['eval']:
 key=bytes.fromhex(v['KEY']);nibbles=bytes(int(x,16) for x in v['IV']);expected=bytes.fromhex(v['RES']);index=int(v['UPDATEDKEY']);final=v['FINALIZE']=='1'
 assert LRP(key,index).evaluate(nibbles,final)==expected
 vectors['LrpPublishedEval'].append((key+bytes([index,int(final)])+nibbles,expected))
vectors['LrpPublishedCrypt']=[]
for v in published['crypt']:
 key=bytes.fromhex(v['KEY']);counter=bytes.fromhex(v['IV']);plain=bytes.fromhex(v['PT']);cipher=bytes.fromhex(v['CT']);padding=v['USEPADDING']=='1'
 assert LRP(key).crypt(plain,counter,padding)[0]==cipher
 vectors['LrpPublishedCrypt'].append((key+bytes([int(padding)])+counter+plain,cipher))
vectors['LrpPublishedCmac']=[]
for v in published['cmac']:
 key=bytes.fromhex(v['KEY']);message=bytes.fromhex(v['MSG']);expected=bytes.fromhex(v['MAC']);assert LRP(key).cmac(message)==expected
 vectors['LrpPublishedCmac'].append((key+message,expected))
sv=bytes.fromhex('00010080')+A[:2]+bytes(x^y for x,y in zip(A[2:8],B[:6]))+B[6:]+A[8:]+bytes.fromhex('9669')
master=LRP(K).cmac(sv);lm=LRP(master);lecrypt=LRP(master,1)
cap=bytes.fromhex('020000000000');authcipher=lecrypt.crypt(TI+bytes(6)+cap,bytes(4),False)[0]
vectors['LrpAuth']=[(K+A+B,master),(A+B,A+lm.cmac(A+B)),(B+A,authcipher+lm.cmac(B+A+authcipher)),(B+A,lm.cmac(B+A))]
# Correct-MAC wrong capability echo must fail after MAC verification.
wrongcipher=lecrypt.crypt(TI+bytes(6)+bytes(6),bytes(4),False)[0]
vectors['LrpAuthBadCapability']=[(b'',wrongcipher+lm.cmac(B+A+wrongcipher))]
for mode in [0,1,2]:
 for writing in [False,True]:
  h=bytes.fromhex('00000000100000');counter=1
  payload=DATA if writing else b''
  if mode==2 and writing:payload,counter=lecrypt.crypt(DATA,counter.to_bytes(4,'big'))
  packet=h+payload
  if mode:packet+=lm.cmac(b'\x8D'+le(0)+TI+packet)[1::2] if writing else lm.cmac(b'\xAD'+le(0)+TI+packet)[1::2]
  response=b'' if writing else OLD
  if mode==2 and not writing:response,counter=lecrypt.crypt(OLD,counter.to_bytes(4,'big'))
  if mode:response+=lm.cmac(b'\0'+le(1)+TI+response)[1::2]
  vectors['Lrp'+['Plain','Mac','Full'][mode]+('Write' if writing else 'Read')]=[(packet,response)]
# Correct MAC with invalid method-two padding, and authentic but wrong plaintext length.
for name,plain in [('BadPadding',bytes(16)),('BadLength',OLD+DATA+b'\x80'+bytes(15))]:
 response=lecrypt.crypt(plain,(1).to_bytes(4,'big'),False)[0]
 vectors['Lrp'+name]=[(b'',response+lm.cmac(b'\0'+le(1)+TI+response)[1::2])]
# Automatic native application LRP reader and retained-session transcripts.
def lrp_master(key,rnda,rndb):
 vector=bytes.fromhex('00010080')+rnda[:2]+bytes(x^y for x,y in zip(rnda[2:8],rndb[:6]))+rndb[6:]+rnda[8:]+bytes.fromhex('9669')
 return LRP(key).cmac(vector)
class LF:
 def __init__(self):
  self.p=[(apdu(0x5A,le(1,3)),bytes.fromhex('9100'))];self.ctr=0;self.ec=0;self.authenticate()
 def authenticate(self,key=K,number=0,nonfirst=False):
  nonce=bytes(range(32,48)) if nonfirst else B;master=lrp_master(key,A,nonce);self.m=LRP(master);self.e=LRP(master,1)
  self.p.append((apdu(0x77 if nonfirst else 0x71,bytes([number]) if nonfirst else bytes([number,6])+cap),(nonce if nonfirst else b'\x01'+nonce)+bytes.fromhex('91AF')))
  response=self.m.cmac(nonce+A)
  if not nonfirst:
   cipher,_=self.e.crypt(TI+bytes(6)+cap,bytes(4),False);response=cipher+self.m.cmac(nonce+A+cipher);self.ctr=0
  self.p.append((apdu(0xAF,A+self.m.cmac(A+nonce)),response+bytes.fromhex('9100')));self.ec=0 if nonfirst else 1
 def cmd(self,c,h=b'',body=b'',reply=b'',mode=1):
  if mode==2 and body:body,self.ec=self.e.crypt(body,self.ec.to_bytes(4,'big'))
  packet=h+body
  if mode:packet+=self.m.cmac(bytes([c])+le(self.ctr)+TI+packet)[1::2]
  self.ctr+=1
  if mode==2 and reply:reply,self.ec=self.e.crypt(reply,self.ec.to_bytes(4,'big'))
  response=reply+(self.m.cmac(b'\0'+le(self.ctr)+TI+reply)[1::2] if mode else b'')+bytes.fromhex('9100')
  chunks=[packet[i:i+48] for i in range(0,len(packet),48)] or [b'']
  for i,chunk in enumerate(chunks):self.p.append((apdu(c if i==0 else 0xAF,chunk),response if i==len(chunks)-1 else bytes.fromhex('91AF')))
 def read(self,data,offset=0,mode=2,file=0):self.cmd(0xAD,bytes([file])+le(offset,3)+le(len(data),3),reply=data,mode=mode)
for mode in range(3):
 for writing in [False,True]:
  f=LF();metadata=bytes([0,[0,1,3][mode]])+bytes.fromhex('0000040000');f.cmd(0xF5,b'\0',reply=metadata);f.read(bytes.fromhex('01020304'),mode=mode);f.cmd(0xF5,b'\0',reply=metadata)
  if writing:
   f.cmd(0x8D,bytes.fromhex('00000000040000'),bytes.fromhex('AABBCCDD'),mode=mode);f.read(bytes.fromhex('AABBCCDD'),mode=mode);f.cmd(0xF5,b'\0',reply=metadata)
  vectors['LrpNative'+['Plain','Mac','Full'][mode]+('Write' if writing else 'Read')]=f.p
f=LF();metadata=bytes.fromhex('00031111040000');f.cmd(0xF5,b'\0',reply=metadata);f.authenticate(NEW,1,True);f.read(bytes.fromhex('01020304'));f.cmd(0xF5,b'\0',reply=metadata);vectors['LrpNativeNonFirstRead']=f.p
# Valid native LRP session MAC with wrong capability echo is rejected during first authentication.
f=LF();wrongcipher=LRP(lrp_master(K,A,B),1).crypt(TI+bytes(12),bytes(4),False)[0];f.p[2]=(f.p[2][0],wrongcipher+LRP(lrp_master(K,A,B)).cmac(B+A+wrongcipher)+bytes.fromhex('9100'));vectors['LrpNativeBadCapability']=f.p
f=LF();f.p[1]=(f.p[1][0],b'\x02'+B+bytes.fromhex('91AF'));vectors['LrpNativeBadMode']=f.p[:2]
for kind in ['Backup','Value','Record','Abort']:
 f=LF();record=kind=='Record';value=kind=='Value';metadata=bytes.fromhex('04030000100000040000020000') if record else bytes.fromhex('0203000000000000E80300000000000000') if value else bytes.fromhex('01030000040000')
 f.cmd(0x6F,reply=b'\0');f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\0',reply=metadata)
 if record:
  h=b'\0'+le(0,3)+le(2,3);f.cmd(0xAB,h,reply=OLD+DATA,mode=2)
 elif value:f.cmd(0x6C,b'\0',reply=le(42,4),mode=2)
 else:f.read(bytes.fromhex('01020304'))
 f.cmd(0xF5,b'\0',reply=metadata)
 if record:f.cmd(0xBA,b'\0'+le(1,3)+le(0,3)+le(16,3),NEW,mode=2)
 elif value:f.cmd(0x0C,b'\0',le(5,4),mode=2)
 else:f.cmd(0x8D,bytes.fromhex('00000000040000'),bytes.fromhex('AABBCCDD'),mode=2)
 f.cmd(0xA7 if kind=='Abort' else 0xC7,b'' if kind=='Abort' else b'\0')
 if kind!='Abort':
  f.cmd(0xF5,b'\0',reply=metadata)
  if record:f.cmd(0xAB,h,reply=OLD+NEW,mode=2)
  elif value:f.cmd(0x6C,b'\0',reply=le(47,4),mode=2)
  else:f.read(bytes.fromhex('AABBCCDD'))
  f.cmd(0xF5,b'\0',reply=metadata)
 vectors['LrpOwned'+kind]=f.p
# LRP TMAC: counter parts are actLE || sesLE. Only derivation is LRP; TMV/EncTMRI use ordinary AES.
act=24;ses=3
lrp_tm_mac=LRP(NEW).cmac(bytes.fromhex('00010080')+le(act)+le(ses)+UID+b'\x5A')
lrp_tm_enc=LRP(NEW).cmac(bytes.fromhex('00010080')+le(act)+le(ses)+UID+b'\xA5')
vectors['LrpTransactionCrypto']=[(bytes.fromhex('00010080')+le(act)+le(ses)+UID+b'\x5A',lrp_tm_mac),(bytes.fromhex('00010080')+le(act)+le(ses)+UID+b'\xA5',lrp_tm_enc),(tmi_data(0xAD,0,bytes.fromhex('01020304')),mac(lrp_tm_mac,tmi_data(0xAD,0,bytes.fromhex('01020304')))),(READER,enc(lrp_tm_enc,Z,READER))]
for reader_id in [False,True]:
 for action in ['Write','Read','Abort','Standard','Record','WrongReceipt','WrongAct','WrongSession','WrongPostimage','LimitReached']:
  f=LF();standard=action=='Standard';record=action=='Record';metadata=bytes.fromhex('00030000080000') if standard else bytes.fromhex('04030000100000040000020000') if record else bytes.fromhex('01030000040000')
  tmsettings=bytes.fromhex('052000EF02342000') if reader_id else bytes.fromhex('0520F0EF02342000')
  f.cmd(0x6F,reply=bytes.fromhex('0001'));f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\x01',reply=tmsettings)
  if action=='LimitReached':vectors['LrpTmac'+('Reader' if reader_id else '')+action]=f.p;continue
  f.cmd(0x51,reply=UID,mode=2);tmi=b''
  if reader_id:
   previous=enc(lrp_tm_enc,Z,READER);f.cmd(0xC8,READER,reply=previous);tmi+=align(b'\xC8'+READER+previous)
  f.cmd(0xF5,b'\0',reply=metadata)
  if record:
   h=b'\0'+le(0,3)+le(2,3);f.cmd(0xAB,h,reply=OLD+DATA,mode=2);tmi+=align(b'\xAB'+h)+OLD+DATA
  else:
   h=b'\0'+le(2 if standard else 0,3)+le(4,3);f.read(bytes.fromhex('01020304'),offset=2 if standard else 0);tmi+=align(b'\xAD'+h)+align(bytes.fromhex('01020304'))
  f.cmd(0xF5,b'\0',reply=metadata)
  if action not in ['Read','Abort']:
   if record:
    h=b'\0'+le(1,3)+le(0,3)+le(16,3);f.cmd(0xBA,h,NEW,mode=2);tmi+=align(b'\xBA'+h)+NEW
   else:f.cmd(0x8D,h,bytes.fromhex('AABBCCDD'),mode=2);tmi+=align(b'\x8D'+h)+align(bytes.fromhex('AABBCCDD'))
   if standard:
    f.read(bytes.fromhex('AABBCCDD'),offset=2);tmi+=align(b'\xAD'+h)+align(bytes.fromhex('AABBCCDD'));f.cmd(0xF5,b'\0',reply=metadata)
  if action=='Abort':f.cmd(0xA7)
  else:
   f.cmd(0xF5,b'\x01',reply=tmsettings);tag=mac(lrp_tm_mac,tmi)
   if action=='WrongReceipt':tag=bytes([tag[0]^1])+tag[1:]
   counter=le(act+1 if action=='WrongAct' else act)+le(ses+1 if action=='WrongSession' else ses)
   f.cmd(0xC7,b'\x01',reply=counter+tag)
   if action not in ['Read','WrongReceipt','WrongAct','WrongSession']:
    f.cmd(0xF5,b'\0',reply=metadata)
    if record:f.cmd(0xAB,b'\0'+le(0,3)+le(2,3),reply=OLD+NEW,mode=2)
    else:f.read(bytes(4) if action=='WrongPostimage' else bytes.fromhex('AABBCCDD'),offset=2 if standard else 0)
    if action!='WrongPostimage':f.cmd(0xF5,b'\0',reply=metadata)
  vectors['LrpTmac'+('Reader' if reader_id else '')+action]=f.p
# Deferred ReaderID profiles acquire the hidden counter from an authenticated, offline-verified receipt.
for resulting_session in [1,7,65535]:
 f=LF();metadata=bytes.fromhex('01030000040000');tmsettings=bytes.fromhex('050000EF0234')
 f.cmd(0x6F,reply=bytes.fromhex('0001'));f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\x01',reply=tmsettings);f.cmd(0x51,reply=UID,mode=2)
 ek=LRP(NEW).cmac(bytes.fromhex('00010080')+le(24)+le(resulting_session)+UID+b'\xA5')
 mk=LRP(NEW).cmac(bytes.fromhex('00010080')+le(24)+le(resulting_session)+UID+b'\x5A')
 previous=enc(ek,Z,READER);f.cmd(0xC8,READER,reply=previous);tmi=align(b'\xC8'+READER+previous)
 f.cmd(0xF5,b'\0',reply=metadata);f.read(bytes.fromhex('01020304'));tmi+=tmi_data(0xAD,0,bytes.fromhex('01020304'));f.cmd(0xF5,b'\0',reply=metadata)
 f.cmd(0x8D,bytes.fromhex('00000000040000'),bytes.fromhex('AABBCCDD'),mode=2);tmi+=tmi_data(0x8D,0,bytes.fromhex('AABBCCDD'))
 f.cmd(0xF5,b'\x01',reply=tmsettings);f.cmd(0xC7,b'\x01',reply=le(24)+le(resulting_session)+mac(mk,tmi))
 f.cmd(0xF5,b'\0',reply=metadata);f.read(bytes.fromhex('AABBCCDD'));f.cmd(0xF5,b'\0',reply=metadata)
 vectors['LrpTmacAcquired'+str(resulting_session)]=f.p
# A zero hidden-session component with a valid session response MAC is never accepted.
f=LF();metadata=bytes.fromhex('01030000040000');tmsettings=bytes.fromhex('0500F0EF0234')
f.cmd(0x6F,reply=bytes.fromhex('0001'));f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\x01',reply=tmsettings);f.cmd(0x51,reply=UID,mode=2)
f.cmd(0xF5,b'\0',reply=metadata);f.read(bytes.fromhex('01020304'));f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\x01',reply=tmsettings)
f.cmd(0xC7,b'\x01',reply=le(24)+le(0)+bytes(8));vectors['LrpTmacZeroSession']=f.p
# Public reader helpers expose protected real UID and stored TMAC without receipt-key claims.
f=LF();f.cmd(0x51,reply=UID,mode=2);vectors['LrpNativeUid']=f.p
f=DF();iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)));vectors['DfNativeUid']=f.p
for mode in range(3):
 f=LF();metadata=bytes([5,[0,1,3][mode]])+bytes.fromhex('F0EF0234');stored=le(23)+le(9)+bytes.fromhex('1122334455667788')
 f.cmd(0xF5,b'\x01',reply=metadata);f.read(stored,mode=mode,file=1);f.cmd(0xF5,b'\x01',reply=metadata);vectors['LrpStoredTmac'+['Plain','Mac','Full'][mode]]=f.p
# DESFire Light: fixed five-key LRP layout; no nonexistent GetKeySettings command.
for number in [0,1,4]:
 f=LF();body=NEW+bytes([0x34])
 if number:body+=le(zlib.crc32(NEW)^0xffffffff,4)
 f.cmd(0xC4,bytes([number]),body,mode=2)
 if number==0:f.p[-1]=(f.p[-1][0],bytes.fromhex('9100'))
 f.authenticate(NEW,number);f.cmd(0x64,bytes([number]),reply=b'\x34')
 vectors['LrpLightKey'+str(number)]=f.p
 if number==1:
  wrong=LF();wrong.p=list(f.p[:-1]);wrong.m=f.m;wrong.e=f.e;wrong.ctr=f.ctr-1;wrong.ec=f.ec
  wrong.cmd(0x64,b'\x01',reply=b'\x35');vectors['LrpLightWrongVersion']=wrong.p
light_configs={0:'22',2:'0577008102',3:'2000',4:'0004',5:'00000000020000001122',
 6:'84A00000010000000000000000000000000110',8:'030001011002030210',
 9:'0300000000E80300000000000001',10:'01E8030A00',11:'01'}
for option,data in light_configs.items():
 f=LF();f.cmd(0x5C,bytes([option]),bytes.fromhex(data),mode=2);vectors['LrpLightConfig'+str(option)]=f.p
# Explicit owned EV2 multi-access transactions: primary denied; extra tuple grants key zero.
for action in ['Backup','Abort','Credit','Debit','Limited','Linear','Cyclic','Clear','WrongData','WrongRights','CreditDenied']:
 f=DF();record=action in ['Linear','Cyclic','Clear'];value=action in ['Credit','Debit','Limited','CreditDenied']
 metadata=(bytes.fromhex('0283FFFF')+le(0,4)+le(100,4)+le(10,4)+b'\x01' if value else
  bytes([4 if action=='Cyclic' else 3])+bytes.fromhex('83FFFF')+le(4,3)+le(2,3)+le(2 if action=='Cyclic' else 1,3) if record else bytes.fromhex('0183FFFF040000'))
 metadata+=bytes.fromhex('01FF0F' if action=='CreditDenied' else '010000')
 f.cmd(0x6F,reply=b'\0');f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\0',reply=metadata)
 if action=='CreditDenied':vectors['DfMultiTx'+action]=f.p;continue
 if value:
  iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x6C,b'\0',reply=enc(f.e,iv,le(10,4)+b'\x80'+bytes(11)))
 elif record:
  old=bytes.fromhex('0102030405060708' if action=='Cyclic' else '01020304');iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8))
  f.cmd(0xAB,b'\0'+le(0,3)+le(len(old)//4,3),reply=enc(f.e,iv,old+b'\x80'+bytes(15-len(old))))
 else:df_read_full(f,0,bytes.fromhex('01020304'))
 f.cmd(0xF5,b'\0',reply=metadata)
 if value:f.cmd({'Credit':0x0C,'Debit':0xDC,'Limited':0x1C}[action],b'\0',le(5,4),full=True)
 elif action=='Clear':f.cmd(0xEB,b'\0')
 else:f.cmd(0x8B if record else 0x8D,b'\0'+le(0,3)+le(4,3),bytes.fromhex('AABBCCDD'),full=True)
 if action=='Abort':f.cmd(0xA7);vectors['DfMultiTx'+action]=f.p;continue
 f.cmd(0xC7,b'\0');after=bytearray(metadata)
 if record:after[10:13]=le(0 if action=='Clear' else 2,3)
 if action=='WrongRights':after[-1]=1
 f.cmd(0xF5,b'\0',reply=bytes(after))
 if action=='WrongRights':vectors['DfMultiTx'+action]=f.p;continue
 if value:
  iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x6C,b'\0',reply=enc(f.e,iv,le(5 if action=='Debit' else 15,4)+b'\x80'+bytes(11)))
 elif record and action!='Clear':
  expected=bytes.fromhex('AABBCCDD01020304');iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8))
  f.cmd(0xAB,b'\0'+le(0,3)+le(2,3),reply=enc(f.e,iv,expected+b'\x80'+bytes(7)))
 elif not record:df_read_full(f,0,bytes.fromhex('00000000' if action=='WrongData' else 'AABBCCDD'))
 if action!='WrongData':f.cmd(0xF5,b'\0',reply=bytes(after))
 vectors['DfMultiTx'+action]=f.p
for mode in [0,1]:
 f=DF();metadata=bytes([1,0x80|mode])+bytes.fromhex('FFFF040000010000')
 f.cmd(0x6F,reply=b'\0');f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\0',reply=metadata)
 h=bytes.fromhex('00000000040000')
 if mode:f.cmd(0xAD,h,reply=bytes.fromhex('01020304'))
 else:f.p.append((apdu(0xAD,h),bytes.fromhex('010203049100')));f.ctr+=1
 f.cmd(0xF5,b'\0',reply=metadata)
 if mode:f.cmd(0x8D,h,bytes.fromhex('AABBCCDD'))
 else:f.p.append((apdu(0x8D,h+bytes.fromhex('AABBCCDD')),bytes.fromhex('9100')));f.ctr+=1
 f.cmd(0xC7,b'\0');f.cmd(0xF5,b'\0',reply=metadata)
 if mode:f.cmd(0xAD,h,reply=bytes.fromhex('AABBCCDD'))
 else:f.p.append((apdu(0xAD,h),bytes.fromhex('AABBCCDD9100')));f.ctr+=1
 f.cmd(0xF5,b'\0',reply=metadata);vectors['DfMultiTx'+['Plain','Mac'][mode]]=f.p
for name,metadata in [('Sdm','004000E0000100C1F121200000430000430000'),
 ('Tmac','0500F0EF0234'),('Malformed','0183FFFF040000020000'),('Unknown','06000000040000')]:
 f=DF();f.cmd(0x6F,reply=b'\0');f.cmd(0xF5,b'\0',reply=bytes.fromhex(metadata));vectors['DfMultiTxReject'+name]=f.p
# Combined multiple-access AES TMAC transactions: full extra tuples remain in the journal proof.
for action in ['Write','BadRights','BadReceipt']:
 f=DF();f.cmd(0x6F,reply=bytes.fromhex('0001'))
 metadata=bytes.fromhex('0183FFFF040000010000');tmsettings=bytes.fromhex('0500F0EF0234')
 f.cmd(0xF5,b'\0',reply=metadata);f.cmd(0xF5,b'\x01',reply=tmsettings)
 iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
 old=bytes.fromhex('01020304');new=bytes.fromhex('AABBCCDD');f.cmd(0xF5,b'\0',reply=metadata)
 df_read_full(f,0,old);f.cmd(0xF5,b'\0',reply=metadata)
 f.cmd(0x8D,b'\0'+le(0,3)+le(4,3),new,full=True)
 f.cmd(0xF5,b'\x01',reply=tmsettings);tmi=tmi_data(0xAD,0,old)+tmi_data(0x8D,0,new)
 receipt=le(1,4)+mac(TM_MAC,tmi)
 if action=='BadReceipt':receipt=receipt[:-1]+bytes([receipt[-1]^1])
 f.cmd(0xC7,b'\x01',reply=receipt)
 if action!='BadReceipt':
  after=metadata if action!='BadRights' else metadata[:-1]+b'\x01';f.cmd(0xF5,b'\0',reply=after)
  if action!='BadRights':df_read_full(f,0,new);f.cmd(0xF5,b'\0',reply=metadata)
 vectors['DfMultiTmac'+action]=f.p
# Authenticated Plain stored-template commands: no SDM mirrors or invented data MAC.
# Explicit TMAC read-owner close discards its calculation without incrementing the counter.
f=DF();f.cmd(0x6F,reply=bytes.fromhex('0001'));f.cmd(0xF5,b'\0',reply=bytes.fromhex('0183FFFF040000010000'))
f.cmd(0xF5,b'\x01',reply=bytes.fromhex('0500F0EF0234'))
iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
f.cmd(0xF5,b'\0',reply=bytes.fromhex('0183FFFF040000010000'));df_read_full(f,0,bytes.fromhex('01020304'));f.cmd(0xF5,b'\0',reply=bytes.fromhex('0183FFFF040000010000'))
f.cmd(0xA7);vectors['DfMultiTmacCaptureClose']=f.p
def plain(f,c,h=b'',body=b'',reply=b''):
 packet=h+body;chunks=[packet[i:i+48] for i in range(0,len(packet),48)] or [b'']
 for i,chunk in enumerate(chunks):f.p.append((apdu(c if i==0 else 0xAF,chunk),reply+b'\x91\0' if i==len(chunks)-1 else b'\x91\xAF'))
 f.ctr+=1
sdm=bytes.fromhex('00C0FFFF400000010000C1F1E1')+le(0,3)+le(14,3)+le(0,3)+le(20,3)
for action in ['Read','Write','Noop','BadPreimage','BadSettings','BadData','TmacRejected']:
 f=DF();f.settings();f.cmd(0x6F,reply=b'\0');f.cmd(0xF5,b'\0',reply=tmsettings if action=='TmacRejected' else sdm)
 if action=='TmacRejected':vectors['DfSdmTemplate'+action]=f.p;continue
 f.cmd(0xF5,b'\0',reply=sdm)
 if action!='Read':f.cmd(0xF5,b'\0',reply=sdm)
 iv=enc(f.e,Z,bytes.fromhex('5AA5')+TI+le(f.ctr+1)+bytes(8));f.cmd(0x51,reply=enc(f.e,iv,UID+b'\x80'+bytes(8)))
 old=bytes(range(64));new=bytes(range(64,128));plain(f,0xAD,b'\0'+le(0,3)+le(64,3),reply=old if action!='BadPreimage' else bytes(64))
 if action=='BadPreimage':vectors['DfSdmTemplate'+action]=f.p;continue
 if action not in ['Read','Noop']:
  plain(f,0x8D,b'\0'+le(0,3)+le(64,3),new)
  plain(f,0xAD,b'\0'+le(0,3)+le(64,3),reply=new if action!='BadData' else old)
  if action=='BadData':vectors['DfSdmTemplate'+action]=f.p;continue
 f.cmd(0xF5,b'\0',reply=sdm if action!='BadSettings' else sdm[:-1]+b'\x01')
 vectors['DfSdmTemplate'+action]=f.p
# Native L3 first AES authentication + independent SL2 KMF equation + reader Crypto1 calls.
classic=bytes.fromhex('A0A1A2A3A4A5');sv=A[11:]+B[11:]+bytes(x^y for x,y in zip(A[4:9],B[4:9]))+b'\x33'
kmf=enc(K,Z,sv)[:6];modified=bytes(x^y for x,y in zip(classic,kmf))
vectors['PlusSl2Modifier']=[(sv,kmf),(classic,modified)]
trailer=bytes.fromhex('000000000000FF078069000000000000')
for action in ['Read','Write','Noop','BadPreimage','BadReadback','Trailer']:
 p=[];auth(p,plus=True);block=3 if action=='Trailer' else 2
 p.append((bytes([0x60,block])+modified,b''));p.append((bytes([0x30,3]),trailer))
 if action!='Trailer':
  p.append((bytes([0x30,2]),OLD))
  if action not in ['Read','Noop','BadPreimage']:
   p.append((bytes([0xA0,2])+DATA,b''));p.append((bytes([0x30,2]),DATA if action!='BadReadback' else OLD))
 vectors['PlusSl2'+action]=p
# Complete SL2 trailer programming, then fresh key A and readable key B evidence.
newclassic=bytes.fromhex('010203040506');newb=bytes.fromhex('101112131415');newtrailer=newclassic+bytes.fromhex('FF078069')+newb
p=[];auth(p,plus=True);p.append((b'\x60\x03'+modified,b''));p.append((b'\x30\x03',trailer));p.append((b'\xA0\x03'+newtrailer,b''))
auth(p,plus=True);p.append((b'\x60\x03'+bytes(x^y for x,y in zip(newclassic,kmf)),b''))
p.append((b'\x30\x03',bytes(6)+bytes.fromhex('FF078069')+newb));vectors['PlusSl2TrailerWrite']=p
# Trailer with non-readable B: fresh A and B Crypto1 proofs independently.
newtrailer=newclassic+bytes.fromhex('7F078869')+newb;visible=bytes(6)+bytes.fromhex('7F078869')+bytes(6)
p=[];auth(p,plus=True);p.append((b'\x60\x03'+modified,b''));p.append((b'\x30\x03',trailer));p.append((b'\xA0\x03'+newtrailer,b''))
for kind,key in [(0x60,newclassic),(0x61,newb)]:
 auth(p,plus=True);p.append((bytes([kind,3])+bytes(x^y for x,y in zip(key,kmf)),b''));p.append((b'\x30\x03',visible))
vectors['PlusSl2TrailerBothKeys']=p
# End-to-end ACR122/PN532 SL2 read: raw AES CRC frames then native hardware Crypto1.
p=[]
def pn(cmd,code,data=b''):
 p.append((bytes.fromhex('FF000000')+bytes([len(cmd)])+cmd,bytes([0xD5,code])+data+bytes.fromhex('9000')))
for c in ['D43202000B0D','D4320400','D43205000000']:pn(bytes.fromhex(c),0x33)
pn(bytes.fromhex('D41224'),0x13)
pn(bytes.fromhex('D4320100'),0x33);pn(bytes.fromhex('D4320101'),0x33)
pn(bytes.fromhex('D44A0100'),0x4B,bytes.fromhex('010104002007')+UID)
pn(bytes.fromhex('D40663026303633D'),0x07,bytes.fromhex('808000'))
pn(bytes.fromhex('D408630200630300633D00'),0x09)
for cmd,reply in vectors['PlusSl2Read'][:2]:
 pn(bytes.fromhex('D408630200630300633D00'),0x09)
 pn(b'\xD4\x42'+crc_a(cmd),0x43,b'\0'+crc_a(reply));pn(bytes.fromhex('D406633C'),0x07,b'\0')
pn(bytes.fromhex('D408630280630380633D00'),0x09)
pn(bytes.fromhex('D440016002')+modified+UID[-4:],0x41,b'\0')
pn(bytes.fromhex('D440013003'),0x41,b'\0'+trailer);pn(bytes.fromhex('D440013002'),0x41,b'\0'+OLD)
pn(bytes.fromhex('D408630280630380633D00'),0x09);pn(bytes.fromhex('D4320100'),0x33);pn(bytes.fromhex('D41234'),0x13)
vectors['PlusSl2Acr122Read']=p
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
