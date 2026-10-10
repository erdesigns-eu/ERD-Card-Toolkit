#!/usr/bin/env python3
"""Generate synthetic native GP management vectors independently with cryptography.

Keys are public test material only. Production providers use the OS CSPRNG.
"""
from pathlib import Path
import sys, hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
import generate_globalplatform_fixtures as g
from cryptography.hazmat.primitives.asymmetric import rsa,padding
from cryptography.hazmat.primitives import hashes
root=Path(__file__).resolve().parents[1] / 'tests/globalplatform/fixtures'
rows=[]
key=rsa.generate_private_key(65537,1024).private_numbers()
def b(i,n=None): return i.to_bytes(n or (i.bit_length()+7)//8,'big')
rows.append(('RSA',b(key.public_numbers.n).hex(),b(key.public_numbers.e).hex(),b(key.d).hex(),b(key.p,64).hex(),b(key.q,64).hex()))
priv=rsa.RSAPrivateNumbers(key.p,key.q,key.d,key.dmp1,key.dmq1,key.iqmp,key.public_numbers).private_key()
for i in range(40):
 k=g.rand(16); msg=g.rand(i*7); domain=bytes.fromhex('A000000151000000'); identity=bytes.fromhex('01020304')
 cmd=bytes.fromhex('0200')+bytes([len(msg)])+msg if len(msg)<=220 else b'\x02\x00\x00'
 if len(msg)>220: msg=msg[:220]; cmd=bytes([2,0,len(msg)])+msg
 rows.append(('M',k.hex(),msg.hex(),g.retail(k,msg,bytes(8)).hex(),g.cmac(k,msg).hex(),g.crypt(k,bytes(8),bytes(8),False)[:3].hex(),g.crypt(k,b'\x01'*16,bytes(16))[:3].hex()))
 rows.append(('T',msg.hex(),priv.sign(cmd,padding.PKCS1v15(),hashes.SHA1()).hex(),g.cmac(k,cmd).hex()))
 raw=g.rand(125+i); digest=hashlib.sha1(raw).digest(); dap=priv.sign(digest,padding.PKCS1v15(),hashes.SHA1())
 rows.append(('D',raw.hex(),digest.hex(),dap.hex(),g.retail(k,digest,bytes(8)).hex(),g.cmac(k,digest).hex()))
 context=bytes([len(domain)])+domain
 cd=b'\x02'+(i+1).to_bytes(2,'big')+bytes([len(identity)])+identity
 for aes in [False,True]:
  mac=g.cmac(k,cd+context) if aes else g.retail(k,cd+context,bytes(8))
  conf=bytes([1+len(mac)+len(cd),len(mac)])+mac+cd
  rows.append(('R',str(int(aes)),k.hex(),identity.hex(),context.hex(),conf.hex()))
(root/'management-crypto.txt').write_text('\n'.join('|'.join(r) for r in rows)+'\n')
# Key update transcripts regenerate the same session using saved RNG state.
rows=[]
for protocol,level,s16 in [(2,0,False),(2,1,False),(3,0,False),(3,4,False),(3,4,True)]:
 for aes in [False,True]:
  state=g.RNG.getstate(); initial=g.session(protocol,level,s16,0,[],domain=domain,double_select=True)
  dek=bytes(range(16)); init=bytes.fromhex([r for r in initial if r[0]=='A' and r[1].startswith('8050')][0][2])
  sdek=g.crypt(dek,b'\x01\x81'+init[12:14]+bytes(12),bytes(8),False) if protocol==2 else dek
  fresh=[bytes(range(j,j+16)) for j in [16,32,48]]
  entries=[]; kcvs=[]
  for k in fresh:
   cipher=(g.crypt(sdek,k[:8],bytes(8),False)+g.crypt(sdek,k[8:],bytes(8),False)) if protocol==2 else g.crypt(sdek,k,bytes(16))
   kcv=g.crypt(k,b'\x01'*16,bytes(16))[:3] if aes else g.crypt(k,bytes(8),bytes(8),False)[:3]
   entries.append((bytes.fromhex('881110') if aes else bytes.fromhex('8010'))+cipher+b'\x03'+kcv);kcvs.append(kcv)
  g.RNG.setstate(state)
  ops=[(0x80,0xD8,1,0x81,b'\x02'+b''.join(entries),True,b'\x02'+b''.join(kcvs))]
  transcript=g.session(protocol,level,s16,0,ops,domain=domain,double_select=True)
  transcript[0]=transcript[0]+(dek.hex(),str(int(aes)))
  rows+=transcript
(root/'key-updates.txt').write_text('\n'.join('|'.join(r) for r in rows)+'\n')

# End-to-end manager transcripts include DAP, issuer tokens and authenticated receipts.
source=(root/'management.txt').read_text().splitlines()
image=b''
for line in source:
 if line.startswith('X|'):
  command=bytes.fromhex(line.split('|')[1])
  if command[1]==0xE8: image+=command[5:5+command[4]]
  elif command[1]==0xE6 and command[2]==0x0C: break
assert image[0]==0xC4
raw=image[2:]; digest=hashlib.sha1(raw).digest()
package=bytes.fromhex('A000000151000101'); module=bytes.fromhex('A000000151000102')
instance=bytes.fromhex('A000000151000103'); newdomain=bytes.fromhex('A000000151000001')
lv=lambda x: bytes([len(x)])+x
ber=lambda x: bytes([x]) if x<128 else bytes([0x81,x])
dap_signature=priv.sign(digest,padding.PKCS1v15(),hashes.SHA1())
dap_body=b'\x4f'+lv(domain)+b'\xc3'+ber(len(dap_signature))+dap_signature
dap=b'\xe2'+ber(len(dap_body))+dap_body
(root/'dap-block.txt').write_text(dap.hex()+'\n')
load=dap+image; tokenkey=bytes(range(64,80)); receiptkey=bytes(range(80,96)); uid=bytes.fromhex('01020304')
rows=[]
for protocol,level,s16 in [(2,1,False),(3,4,False),(3,4,True)]:
 for rsa_mode in [False,True]:
  count=0
  def receipt(ctx):
   global count
   count+=1; cd=b'\x02'+count.to_bytes(2,'big')+lv(uid)
   mac=g.retail(receiptkey,cd+ctx,bytes(8)) if protocol==2 else g.cmac(receiptkey,cd+ctx)
   payload=lv(mac)+cd; return lv(payload)
  def tokenize(ins,p1,p2,data):
   signed=bytes([p1,p2,len(data)])+data
   token=priv.sign(signed,padding.PKCS1v15(),hashes.SHA1()) if rsa_mode else g.cmac(tokenkey,signed)
   return data+(b'\x9e' if ins==0xE4 else b'')+ber(len(token))+token
  data=lv(package)+lv(domain)+lv(digest)+b'\x00'
  ops=[(0x80,0xE6,2,0,tokenize(0xE6,2,0,data),True,b'\x00')]
  blocks=[load[i:i+40] for i in range(0,len(load),40)]
  ops += [(0x80,0xE8,0x80 if i==len(blocks)-1 else 0,i,block,True,
           receipt(lv(package)+lv(domain)) if i==len(blocks)-1 else b'\x00') for i,block in enumerate(blocks)]
  data=lv(package)+lv(module)+lv(instance)+lv(b'\x00')+lv(bytes.fromhex('C9020102'))
  ops.append((0x80,0xE6,0x0C,0,tokenize(0xE6,0x0C,0,data),True,receipt(lv(package)+lv(instance))))
  data=lv(newdomain)+b'\x00'+lv(instance)+b'\x00\x00'
  ops.append((0x80,0xE6,0x10,0,tokenize(0xE6,0x10,0,data),True,receipt(lv(domain)+lv(instance)+lv(newdomain))))
  data=b'\x4f'+lv(instance)
  ops.append((0x80,0xE4,0,0x80,tokenize(0xE4,0,0x80,data),True,receipt(lv(instance))))
  transcript=g.session(protocol,level,s16,0,ops,domain=domain,double_select=True)
  transcript[0]=transcript[0]+('', '0',tokenkey.hex(),receiptkey.hex(),str(int(rsa_mode)))
  rows+=transcript
(root/'delegated-management.txt').write_text('\n'.join('|'.join(r) for r in rows)+'\n')
print('Generated management primitives, ten key-update and six delegated-management transcripts.')

# Verification-key provisioning and exact-key deletion (both close the old session).
rows=[]
modulus=b(key.public_numbers.n); exponent=b(key.public_numbers.e)
public_data=b'\x02\xa1\x81\x80'+modulus+b'\xa0'+lv(exponent)+b'\x00'
for protocol,level in [(2,1),(3,4)]:
 for delete in [False,True]:
  if delete:
   ops=[(0x80,0xE4,0,0,bytes.fromhex('D00101D20102'),True,b'')]
  else:
   ops=[(0x80,0xCA,0,0xE0,b'',True,bytes.fromhex('E006C00401018810')),
        (0x80,0xE6,8,0,b'\x00\x00'+lv(instance)+lv(b'\x00')+b'\x00\x00',True,b'\x00'),
        (0x80,0xF0,0x80,7,b'',True,b'\x00'),
        (0x80,0xD8,1,1,public_data,True,b'\x02')]
  rows+=g.session(protocol,level,False,0,ops,domain=domain,double_select=True)
(root/'key-administration.txt').write_text('\n'.join('|'.join(r) for r in rows)+'\n')
