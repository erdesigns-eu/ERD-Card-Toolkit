#!/usr/bin/env python3
"""Generate independent synthetic Ultralight C and DESFire DES transcripts.

Uses Python cryptography's maintained Triple DES implementation. Keys/nonces are
published synthetic test values. Pascal tests consume fixed fixtures, not this
optional developer generator. Legacy/ISO wire dialects are explicitly separate.
"""
from pathlib import Path
import ast
from types import SimpleNamespace
from cryptography.hazmat.primitives.ciphers import Cipher, modes
try:
    from cryptography.hazmat.decrepit.ciphers.algorithms import TripleDES
except ImportError:
    from cryptography.hazmat.primitives.ciphers.algorithms import TripleDES
ROOT = Path(__file__).resolve().parents[1]
A = bytes.fromhex('102132435465768798A9BACBDCEDFE0F')
B = bytes.fromhex('8899AABBCCDDEEFF0011223344556677')
KEY = bytes.fromhex('0123456789ABCDEFFEDCBA98765432100123456789ABCDEF')
MEMORY = bytes(range(32))

def expand(key):
    return key*3 if len(key)==8 else key+key[:8] if len(key)==16 else key

def crypt(key, iv, data, encrypt=True):
    ctx = Cipher(TripleDES(expand(key)), modes.CBC(iv)).encryptor() if encrypt else Cipher(TripleDES(expand(key)), modes.CBC(iv)).decryptor()
    return ctx.update(data)+ctx.finalize()

def xor(a,b): return bytes(x^y for x,y in zip(a,b))
def double(block):
    n=int.from_bytes(block,'big');return ((n<<1 & ((1<<64)-1)) ^ (0x1b if n>>63 else 0)).to_bytes(8,'big')
def mac(key, iv, msg):
    k1=double(crypt(key,bytes(8),bytes(8)));k2=double(k1)
    if msg and len(msg)%8==0: body=msg[:-8]+xor(msg[-8:],k1)
    else:
        rest=msg[len(msg)//8*8:];body=msg[:len(msg)//8*8]+xor(rest+b'\x80'+bytes(7-len(rest)),k2)
    return crypt(key,iv,body)[-8:]
def crc16(data):
    n=0x6363
    for byte in data:
        n^=byte
        for _ in range(8): n=(n>>1)^(0x8408 if n&1 else 0)
    return n.to_bytes(2,'little')
def crc32(data):
    n=0xffffffff
    for byte in data:
        n^=byte
        for _ in range(8): n=(n>>1)^(0xedb88320 if n&1 else 0)
    return n.to_bytes(4,'little')
def pad(data): return data+bytes(-len(data)%8)
def inverse_send(key,data):
    result=b'';last=bytes(8)
    for i in range(0,len(data),8):last=crypt(key,bytes(8),xor(data[i:i+8],last),False);result+=last
    return result

def wrap(cmd,data=b''):return bytes([0x90,cmd,0,0])+ (bytes([len(data)])+data if data else b'')+b'\0'
class Card:
    def __init__(self,profile,mode,**kwargs):
        self.legacy=profile>=2;self.key=kwargs.get('key',KEY[:8 if profile==2 else 24 if profile==1 else 16])
        n=16 if profile==1 else 8;a,b=A[:n],B[:n]
        rb=crypt(self.key,bytes(8),b)
        challenge=inverse_send(self.key,a+b[1:]+b[:1]) if self.legacy else crypt(self.key,rb[-8:],a+b[1:]+b[:1])
        ra=crypt(self.key,bytes(8) if self.legacy else challenge[-8:],a[1:]+a[:1])
        self.pairs=[(wrap(0x5a,kwargs.get('aid',bytes.fromhex('01EFCD'))),bytes.fromhex('9100')),
                    (wrap(0x0a if self.legacy else 0x1a,bytes([kwargs.get('key_number',0)])),rb+bytes.fromhex('91AF')),
                    (wrap(0xaf,challenge),ra+bytes.fromhex('9100'))]
        self.session=a[:4]+b[:4]
        if profile==1:self.session+=a[6:10]+b[6:10]+a[12:]+b[12:]
        elif profile!=2:self.session+=a[4:8]+b[4:8]
        self.app_config=(0x40 if profile==1 else 0)|1;self.iv=bytes(8);self.mode=mode;self.frame=kwargs.get("frame",48);self.response_chunk=kwargs.get("response_chunk",1048576)
    def exchange(self,cmd,header=b'',body=b'',returned=b'',mode=None,write=False,writing=False):
        write=write or writing
        mode=self.mode if mode is None else mode;request=header+body
        if self.legacy:
            if write and mode==1:request+=crypt(self.session,bytes(8),pad(body))[-8:-4]
            if write and mode==3:request=header+inverse_send(self.session,pad(body+crc16(body)))
            if write or mode==0:response=returned
            elif mode==1:response=returned+crypt(self.session,bytes(8),pad(returned))[-8:-4]
            else:response=crypt(self.session,bytes(8),pad(returned+crc16(returned)))
        else:
            if write and mode==3:
                encrypted=crypt(self.session,self.iv,pad(body+crc32(bytes([cmd])+header+body)));request=header+encrypted;self.iv=encrypted[-8:]
            else:
                self.iv=mac(self.session,self.iv,bytes([cmd])+header+body)
                if write and mode==1:request+=self.iv
            if mode==3 and not write:
                response=crypt(self.session,self.iv,pad(returned+crc32(returned+b'\0')));self.iv=response[-8:]
            else:self.iv=mac(self.session,self.iv,returned+b'\0');response=returned+self.iv
        pieces=[request[i:i+self.frame] for i in range(0,len(request),self.frame)] or [b'']
        for i,part in enumerate(pieces[:-1]):
            self.pairs.append((wrap(cmd if i==0 else 0xaf,part),bytes.fromhex('91AF')))
        chunks=[response[i:i+self.response_chunk] for i in range(0,len(response),self.response_chunk)] or [b'']
        self.pairs.append((wrap(cmd if len(pieces)==1 else 0xaf,pieces[-1]),chunks[0]+bytes.fromhex('91AF' if len(chunks)>1 else '9100')))
        for i,part in enumerate(chunks[1:],1):
            self.pairs.append((wrap(0xaf),part+bytes.fromhex('91AF' if i<len(chunks)-1 else '9100')))

    def metadata(self,cmd,header=b'',returned=b''):
        if cmd==0x45 and returned==bytes.fromhex('0F81'):returned=bytes([0x0b,self.app_config])
        self.exchange(cmd,header,returned=returned,mode=0)
    def switch(self): pass
    def settings(self):self.exchange(0xf5,b'\0',returned=bytes([0,self.mode,0,0,32,0,0]),mode=0)

def desfire(profile,mode,write,chained=False):
    c=Card(profile,mode,frame=16 if chained else 48,response_chunk=7 if chained else 1048576);c.settings()
    header=bytes.fromhex('00000000200000' if chained else '00040000040000')
    original=MEMORY if chained else MEMORY[4:8]
    replacement=bytes(range(128,160)) if chained else bytes.fromhex('AABBCCDD')
    if write:
        c.exchange(0xbd,header,returned=original);c.settings()
        c.exchange(0x3d,header,replacement,write=True)
        c.exchange(0xbd,header,returned=replacement);c.settings()
    else:c.exchange(0xbd,header,returned=original);c.settings()
    return c.pairs

def rf(data):return data+crc16(data)
def ulc(action,page=39):
    key=KEY[:16];a,b=A[:8],B[:8];rb=crypt(key,bytes(8),b);challenge=crypt(key,rb,a+b[1:]+b[:1]);ra=crypt(key,challenge[-8:],a[1:]+a[:1])
    pairs=[(rf(bytes.fromhex('1A00')),rf(b'\xaf'+rb)),(rf(b'\xaf'+challenge),rf(b'\0'+ra))]
    mem=bytearray(range(192))
    if action=='write':
        pairs.append((rf(bytes([0xa2,page])+b'\xaa\xbb\xcc\xdd'),b'\x0a'));mem[page*4:page*4+4]=b'\xaa\xbb\xcc\xdd'
    for first in range(4,40,4) if action=='memory' else [min(page,36)]:pairs.append((rf(bytes([0x30,first])),rf(bytes(mem[first*4:first*4+16]))))
    return pairs

# Reuse only the protocol-independent workload definitions, without executing
# the AES generator or importing its cryptographic implementation.
workloads=ast.parse((ROOT/'tools/generate_desfire_session_fixtures.py').read_text())
workloads.body=[node for node in workloads.body if isinstance(node,ast.FunctionDef) and node.name in ('raw_settings','transaction','manage_files')]
namespace={'crypto':SimpleNamespace(MEMORY=MEMORY),'LINEAR':bytes.fromhex('1112131421222324'),'CYCLIC':bytes.fromhex('111213142122232431323334')}
exec(compile(workloads,'independent-session-workload','exec'),namespace)
def session(profile,mode):
    namespace['Card']=lambda generation,mode,**kwargs: Card(profile,mode,**kwargs)
    return namespace['transaction']('Ev1',mode)

def files(profile,mode):
    namespace['Card']=lambda generation,mode,**kwargs: Card(profile,mode,**kwargs)
    return namespace['manage_files']('Ev1',mode)
def applications(profile):
    card=Card(profile,0,aid=bytes(3));current=[bytes.fromhex('563412')]
    card.metadata(0x6e,returned=(1000).to_bytes(3,'little'))
    card.metadata(0x45,returned=bytes([0x0b,card.app_config]));card.metadata(0x64,b'\0',returned=b'\5')
    for kind in (0,0x40,0x80):
        aid=bytes([kind+1,0xef,0xcd])
        card.metadata(0x45,returned=bytes([0x0b,card.app_config]))
        card.metadata(0x6a,returned=b''.join(current))
        card.metadata(0xca,aid+bytes([0x0b,kind|1]));current.append(aid)
        card.metadata(0x6a,returned=b''.join(current))
    for aid in current[:0:-1]:
        card.metadata(0x45,returned=bytes([0x0b,card.app_config]))
        card.metadata(0x6a,returned=b''.join(current))
        card.metadata(0xda,aid);current.remove(aid)
        card.metadata(0x6a,returned=b''.join(current))
    return card.pairs

NEW_KEY=bytes.fromhex('1032547698BADCFE0123456789ABCDEFFEDCBA9876543210')
def version_key(material,version,new=True):
    out=bytearray(material)
    for i in range(8):
        bit=version>>(7-i)&1;out[i]=(out[i]&0xfe)|bit
        if new and len(out)==16:out[i+8]=(out[i+8]&0xfe)|(bit^1)
    return bytes(out)
def des_admin(profile,action,root=False,free=False):
    card=Card(profile,3,aid=bytes(3) if root else bytes.fromhex('01EFCD'))
    config=(0x40 if profile==1 else 0)|2
    card.metadata(0x45,returned=bytes([0x0f,config]))
    if action=='policy':
        card.exchange(0x54,body=b'\xef',mode=3,write=True)
        card.metadata(0x45,returned=bytes([0xef,config]))
    elif action=='access':
        original=bytes.fromhex('00030e0e200000') if free else bytes.fromhex('00030000200000')
        updated=bytes.fromhex('000110e1200000')
        card.metadata(0xf5,b'\0',original)
        card.exchange(0x5f,b'\0',updated[1:4],mode=0 if free else 3,write=True)
        card.metadata(0xf5,b'\0',updated)
    else:
        current=action=='current';size=8 if profile==2 else 24 if profile==1 else 16
        new=version_key(NEW_KEY[:size],0x42);old=version_key(KEY[:size],0x21,False)
        new_wire=new*2 if size==8 else new;old_wire=old*2 if size==8 else old
        number=(0x40 if root and profile==1 else 0) | (0 if current else 1)
        body=new_wire if current else xor(new_wire,old_wire)
        body+=crc16(body) if card.legacy else crc32(bytes([0xc4,number])+body)
        if not current:body+=crc16(new_wire) if card.legacy else crc32(new_wire)
        encrypted=inverse_send(card.session,pad(body)) if card.legacy else crypt(card.session,card.iv,pad(body))
        if card.legacy:response=b''
        else:
            card.iv=encrypted[-8:];card.iv=mac(card.session,card.iv,b'\0');response=card.iv
        # A changed current key loses authentication, so the native response may be bare.
        card.pairs.append((wrap(0xc4,bytes([number])+encrypted),(b'' if current else response)+bytes.fromhex('9100')))
        fresh=Card(profile,3,key=new,key_number=0 if current else 1)
        card.pairs.extend(fresh.pairs[1:]);card.session=fresh.session;card.iv=fresh.iv
        card.metadata(0x64,bytes([0 if current else 1]),b'\x42')
        card.metadata(0x45,returned=bytes([0x0f,config]))
    return card.pairs

def ulc_auth(key):
    a,b=A[:8],B[:8];rb=crypt(key,bytes(8),b);challenge=crypt(key,rb,a+b[1:]+b[:1]);ra=crypt(key,challenge[-8:],a[1:]+a[:1])
    return [(rf(bytes.fromhex('1A00')),rf(b'\xaf'+rb)),(rf(b'\xaf'+challenge),rf(b'\0'+ra))]
def ulc_admin(action,locked=0):
    key=KEY[:16];new=NEW_KEY[:16];config=bytearray.fromhex('000000BD0000000030AABBCCF1DDEEFF');config[1]=locked
    pairs=ulc_auth(key)+[(rf(bytes.fromhex('3028')),rf(config))]
    if action=='read' or locked:return pairs
    if action=='config':
        config[12]&=0xfe;pairs.append((rf(b'\xa2\x2b'+config[12:16]),b'\x0a'))
        config[8]=4;pairs.append((rf(b'\xa2\x2a'+config[8:12]),b'\x0a'))
    if action=='key':
        stored=new[:8][::-1]+new[8:][::-1]
        for i in range(4):pairs.append((rf(bytes([0xa2,44+i])+stored[i*4:i*4+4]),b'\x0a'))
    pairs+=ulc_auth(new if action=='key' else key)
    if action=='config' or action=='noop':pairs.append((rf(bytes.fromhex('3028')),rf(config)))
    return pairs

vectors={}
for profile in range(4):
    for mode in (0,1,3):
        for write in (False,True):vectors[f'D{profile}M{mode}W{int(write)}']=desfire(profile,mode,write)
        vectors[f'S{profile}M{mode}']=session(profile,mode)
        vectors[f'F{profile}M{mode}']=files(profile,mode)
    vectors[f'C{profile}']=desfire(profile,3,True,chained=True)
    vectors[f'A{profile}']=applications(profile)
    for action in ('policy','access','current','other'):
        vectors[f'K{profile}{action}']=des_admin(profile,action)
    vectors[f'K{profile}root']=des_admin(profile,'current',root=True)
    vectors[f'K{profile}free']=des_admin(profile,'access',free=True)
for action in ('read','memory','write'):vectors['U'+action]=ulc(action)
for action in ('read','config','key','noop','samekey'):vectors['UC'+action]=ulc_admin(action)
vectors['UClockedconfig']=ulc_admin('config',0x60)
vectors['UClockedkey']=ulc_admin('key',0x80)
text=['unit LegacyMifare.Vectors;','{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}','interface','type',
      '  /// <summary>Independent literal command/response pair using synthetic public credentials.</summary>',
      '  TLegacyWirePair=record','    /// <summary>Exact outgoing bytes encoded as hex.</summary>','    Command:string;',
      '    /// <summary>Exact incoming bytes including protocol framing.</summary>','    Response:string;','  end;',
      '  /// <summary>Owned ordered protocol transcript.</summary>','  TLegacyWirePairs=array of TLegacyWirePair;']
for name in vectors:text += [f'/// <summary>Independent synthetic {name} transcript; never a production credential.</summary>',
                             '/// <returns>Owned fixed literal wire pairs.</returns>',f'function {name}:TLegacyWirePairs;']
text += ['implementation']
for name,pairs in vectors.items():
    text += [f'function {name}:TLegacyWirePairs;','begin',f' Result:=nil;SetLength(Result,{len(pairs)});']
    for i,(cmd,rsp) in enumerate(pairs):text += [f" Result[{i}].Command:='{cmd.hex().upper()}';Result[{i}].Response:='{rsp.hex().upper()}';"]
    text+=['end;']
text += ['end.','']
(ROOT/'tests/contactless/LegacyMifare.Vectors.pas').write_bytes('\n'.join(text).replace('\n','\r\n').encode())
