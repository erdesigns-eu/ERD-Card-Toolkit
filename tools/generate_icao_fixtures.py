#!/usr/bin/env python3
"""Generate independent ICAO BAC/PACE transcripts from published test values.

Optional developer tool requiring Python cryptography, never a runtime dependency.
ICAO Doc 9303 Part 11 Appendices D/G. EC arithmetic below exists only in this
fixture generator; production delegates all curve operations to OpenSSL.
"""
from pathlib import Path
from hashlib import sha1
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.decrepit.ciphers.algorithms import TripleDES
from cryptography.hazmat.primitives.cmac import CMAC
from cryptography.hazmat.primitives.asymmetric import ec

ROOT = Path(__file__).resolve().parents[1]
H = bytes.fromhex
BAC_PASSWORD = b'L898902C<369080619406236'
PACE_PASSWORD = b'T22000129364081251010318'
NONCE = H('3F00C4D39D153F2B2A214A078D899B22')
MAP_TERMINAL = H('7F4EF07B9EA82FD78AD689B38D0BC78CF21F249D953BC46F4C6E19259C010F99')
AGREE_TERMINAL = H('A73FB703AC1436A18E0CFA5ABB3F7BEC7A070E7A6788486BEE230C4A22762595')
MAP_CARD = H('498FF49756F2DC1587840041839A85982BE7761D14715FB091EFA7BCE9058560')
AGREE_CARD = H('107CF58696EF6155053340FD633392BA81909DF7B9706F226F32086C7AFF974A')
OID = H('04007F00070202040202')
TD1 = b'I<UTOD231458907<<<<<<<<<<<<<<<7408122F1204159UTO<<<<<<<<<<<6ERIKSSON<<ANNA<MARIA<<<<<<<<<<'


def tlv(tag, value):
    size = len(value)
    length = bytes([size]) if size < 128 else (size.to_bytes((size.bit_length()+7)//8, 'big'))
    if size >= 128:
        length = bytes([0x80 | len(length)]) + length
    return tag + length + value


def pad(data, block):
    return data + b'\x80' + bytes(block - 1 - len(data) % block)


def crypt(key, iv, data, des=False, encrypt=True):
    op = Cipher(TripleDES(key) if des else algorithms.AES(key), modes.CBC(iv))
    action = op.encryptor() if encrypt else op.decryptor()
    return action.update(data) + action.finalize()


def cmac(key, data):
    op = CMAC(algorithms.AES(key)); op.update(data)
    return op.finalize()


def retail(key, data):
    last = crypt(key[:8]*3, bytes(8), pad(data, 8), True)[-8:]
    last = crypt(key[8:]*3, bytes(8), last, True, False)
    return crypt(key[:8]*3, bytes(8), last, True)


def derive(seed, counter, des=False):
    key = sha1(seed + counter.to_bytes(4, 'big')).digest()[:16]
    if des:
        key = bytes((b & 0xFE) | (1 ^ ((b & 0xFE).bit_count() % 2)) for b in key)
    return key


def apdu(ins, p1=0, p2=0, data=b'', le=0, cla=0):
    return bytes([cla, ins, p1, p2]) + (bytes([len(data)])+data if data else b'') + (bytes([le & 255]) if le else b'')


class Secure:
    def __init__(self, enc, mac, ssc, des=False):
        self.enc, self.mac, self.ssc, self.des = enc, mac, int.from_bytes(ssc, 'big'), des
        self.block = 8 if des else 16

    def advance(self):
        self.ssc += 1
        return self.ssc.to_bytes(self.block, 'big')

    def encrypt(self, data, counter):
        iv = bytes(8) if self.des else crypt(self.enc, bytes(16), counter)
        key = self.enc + self.enc[:8] if self.des else self.enc
        return crypt(key, iv, data, self.des)

    def tag(self, counter, message):
        return retail(self.mac, counter+message) if self.des else cmac(self.mac, pad(counter+message, 16))[:8]

    def exchange(self, ins, p1=0, p2=0, data=b'', le=0, returned=b'', status=0x9000, bad_padding=False):
        counter = self.advance()
        body = b''
        if data:
            encrypted = self.encrypt(pad(data, self.block), counter)
            body = tlv(b'\x85' if ins & 1 else b'\x87', encrypted if ins & 1 else b'\1'+encrypted)
        if le:
            body += tlv(b'\x97', bytes([le & 255]))
        header = bytes([0x0C, ins, p1, p2])
        body += tlv(b'\x8E', self.tag(counter, pad(header, self.block)+body))
        request = apdu(ins, p1, p2, body, 256, 0x0C)
        counter = self.advance(); response = b''
        if returned or bad_padding:
            payload = bytes(self.block) if bad_padding else pad(returned, self.block)
            encrypted = self.encrypt(payload, counter)
            response = tlv(b'\x85' if ins & 1 else b'\x87', encrypted if ins & 1 else b'\1'+encrypted)
        response += tlv(b'\x99', status.to_bytes(2, 'big'))
        response += tlv(b'\x8E', self.tag(counter, response))
        return request, response+b'\x90\0'


def bac():
    seed = sha1(BAC_PASSWORD).digest()[:16]
    enc, mac = derive(seed, 1, True), derive(seed, 2, True)
    rnd_card, rnd_terminal = H('4608F91988702212'), H('781723860C06C226')
    kt, kc = H('0B795240CB7049B01C19B33E32804F0B'), H('0B4F80323EB3191CB04970CB4052790B')
    encrypted = crypt(enc+enc[:8], bytes(8), rnd_terminal+rnd_card+kt, True)
    assert encrypted == H('72C29C2371CC9BDB65B779B8E8D37B29ECC154AA56A8799FAE2F498F76ED92F2')
    assert retail(mac, encrypted) == H('5F1448EEA8AD90A7')
    answer = crypt(enc+enc[:8], bytes(8), rnd_card+rnd_terminal+kc, True)
    assert answer == H('46B9342A41396CD7386BF5803104D7CEDC122B9132139BAF2EEDC94EE178534F')
    assert retail(mac, answer) == H('2F2D235D074D7449')
    pairs = [(apdu(0xA4, 4, 12, H('A0000002471001')), H('9000')),
             (apdu(0x84, le=8), rnd_card+H('9000')),
             (apdu(0x82, data=encrypted+retail(mac, encrypted), le=40), answer+retail(mac, answer)+H('9000'))]
    session = bytes(a ^ b for a, b in zip(kt, kc))
    secure = Secure(derive(session, 1, True), derive(session, 2, True), rnd_card[4:]+rnd_terminal[4:], True)
    # Published Appendix D.4 SM select/read anchor, independent of the reader's chunks.
    anchor = Secure(secure.enc, secure.mac, rnd_card[4:]+rnd_terminal[4:], True)
    assert anchor.exchange(0xA4, 2, 12, H('011E')) == (
        H('0CA4020C158709016375432908C044F68E08BF8B92D635FF24F800'),
        H('990290008E08FA855A5D4C50A8ED9000'))
    assert anchor.exchange(0xB0, le=4, returned=H('60145F01')) == (
        H('0CB000000D9701048E08ED6705417E96BA5500'),
        H('8709019FF0EC34F9922651990290008E08AD55CC17140B2DED9000'))
    return pairs, secure


CURVES = {
    12: (ec.SECP256R1(), int('FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF', 16),
         int('FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC', 16)),
    13: (ec.BrainpoolP256R1(), int('A9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377', 16),
         int('7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9', 16)),
}


def add(left, right, p, a):
    if left is None: return right
    if right is None: return left
    x, y = left; u, v = right
    if x == u and (y + v) % p == 0: return None
    slope = ((3*x*x+a)*pow(2*y, -1, p) if left == right else (v-y)*pow(u-x, -1, p)) % p
    nx = (slope*slope-x-u) % p
    return nx, (slope*(x-nx)-y) % p


def mul(scalar, point, p, a):
    result = None
    while scalar:
        if scalar & 1: result = add(result, point, p, a)
        point = add(point, point, p, a); scalar >>= 1
    return result


def encode(point):
    return b'\4'+point[0].to_bytes(32, 'big')+point[1].to_bytes(32, 'big')


def pace(parameter=13, can=False, dual=False):
    curve, prime, a = CURVES[parameter]
    generator = ec.derive_private_key(1, curve).public_key().public_numbers()
    g = generator.x, generator.y
    tm, cm, ta, ca = (int.from_bytes(value, 'big') for value in (MAP_TERMINAL, MAP_CARD, AGREE_TERMINAL, AGREE_CARD))
    terminal_map, card_map = mul(tm, g, prime, a), mul(cm, g, prime, a)
    mapped = add(mul(int.from_bytes(NONCE, 'big'), g, prime, a), mul(tm, card_map, prime, a), prime, a)
    terminal_key, card_key = mul(ta, mapped, prime, a), mul(ca, mapped, prime, a)
    shared = mul(ta, card_key, prime, a)[0].to_bytes(32, 'big')
    enc, mac = derive(shared, 1), derive(shared, 2)
    prefix = H('7F494F060A')+OID+H('8641')
    terminal_token = cmac(mac, prefix+encode(card_key))[:8]
    card_token = cmac(mac, prefix+encode(terminal_key))[:8]
    if parameter == 13:
        assert encode(terminal_map) == H('047ACF3EFC982EC45565A4B155129EFBC74650DCBFA6362D896FC70262E0C2CC5E544552DCB6725218799115B55C9BAA6D9F6BC3A9618E70C25AF71777A9C4922D')
        assert shared == H('28768D20701247DAE81804C9E780EDE582A9996DB4A315020B2733197DB84925')
        assert enc == H('F5F0E35C0D7161EE6724EE513A0D9A7F')
        assert mac == H('FE251C7858B356B24514B3BD5F4297D1')
        assert terminal_token == H('C2B0BD78D94BA866') and card_token == H('3ABB9674BCE93C08')
    info = lambda param: tlv(b'\x30', tlv(b'\6', OID)+H('020102')+bytes([2, 1, param]))
    card_access = tlv(b'\x31', b''.join(sorted([info(12), info(13)])) if dual else info(parameter))
    password = b'123456' if can else PACE_PASSWORD
    seed = password if can else sha1(password).digest()
    kpi = derive(seed, 3)
    nonce_enc = crypt(kpi, bytes(16), NONCE)
    if not can: assert nonce_enc == H('95A3A016522EE98D01E76CB6B98B42C3')
    pairs = [(apdu(0xA4, 0, 12, H('3F00')), H('9000')),
             (apdu(0xA4, 2, 12, H('011C')), H('9000')),
             (apdu(0xB0, le=2), card_access[:2]+H('9000')),
             (apdu(0xB0, 0, 2, le=len(card_access)-2), card_access[2:]+H('9000')),
             (apdu(0xA4, 4, 12, H('A0000002471001')), H('9000'))]
    mse = tlv(b'\x80', OID)+tlv(b'\x83', bytes([2 if can else 1]))
    if dual: mse += tlv(b'\x84', bytes([parameter]))
    pairs.append((apdu(0x22, 0xC1, 0xA4, mse), H('9000')))
    for send, recv, data, answer, cla in [(None, 0x80, b'', nonce_enc, 0x10),
                                         (0x81, 0x82, encode(terminal_map), encode(card_map), 0x10),
                                         (0x83, 0x84, encode(terminal_key), encode(card_key), 0x10),
                                         (0x85, 0x86, terminal_token, card_token, 0)]:
        pairs.append((apdu(0x86, data=tlv(b'\x7C', tlv(bytes([send]), data) if send else b''), le=256, cla=cla),
                      tlv(b'\x7C', tlv(bytes([recv]), answer))+H('9000')))
    return pairs, Secure(enc, mac, bytes(16))


def dg2(image_size=4):
    image = H('FFD8FFAA') + bytes(i % 251 for i in range(image_size-4))
    face = bytearray(H('4641430030313000000000320001' + '0000002400000000000000000000000000000000' + '0000009600C3000000000000'))
    assert len(face) == 46
    face[8:12] = (46+len(image)).to_bytes(4, 'big')
    face[14:18] = (32+len(image)).to_bytes(4, 'big')
    face += image
    template = tlv(H('A1'), H('8702010188020008'))+tlv(H('5F2E'), bytes(face))
    return tlv(b'\x75', tlv(H('7F61'), H('020101')+tlv(H('7F60'), template)))


def document(pairs, secure, large=False, error=False, bad_padding=False):
    files = [(0x0101, tlv(b'\x61', tlv(H('5F1F'), TD1))), (0x0102, dg2(66000 if large else 4)),
             (0x011E, H('60065C0461757776')), (0x011D, H('770430020500'))]
    for index, (file, data) in enumerate(files):
        pairs.append(secure.exchange(0xA4, 2, 12, file.to_bytes(2, 'big'), status=0x6982 if error else 0x9000, bad_padding=bad_padding))
        if error or bad_padding: break
        pairs.append(secure.exchange(0xB0, le=2, returned=data[:2]))
        position = 2
        if data[1] >= 128:
            count = data[1] & 127
            pairs.append(secure.exchange(0xB0, 0, 2, le=count, returned=data[2:2+count])); position += count
        while position < len(data):
            count = min(208, len(data)-position); returned = data[position:position+count]
            if position <= 0x7FFF:
                pairs.append(secure.exchange(0xB0, position >> 8, position & 255, le=count, returned=returned))
            else:
                returned = tlv(b'\x53', returned)
                offset = position.to_bytes(2 if position <= 65535 else 3, 'big')
                pairs.append(secure.exchange(0xB1, data=tlv(b'\x54', offset), le=len(returned), returned=returned))
            position += count
    return pairs


def generate():
    vectors = {}
    for name, factory, large, error, padding in [('BacDocument', bac, False, False, False),
          ('PaceBrainpoolDocument', pace, False, False, False),
          ('PaceNistDocument', lambda: pace(12), False, False, False),
          ('PaceCanDocument', lambda: pace(13, True), False, False, False),
          ('PaceDualDocument', lambda: pace(13, False, True), False, False, False),
          ('PaceLargeDocument', pace, True, False, False),
          ('BacProtectedError', bac, False, True, False),
          ('BacBadPadding', bac, False, False, True),
          ('PaceBadPadding', pace, False, False, True)]:
        pairs, secure = factory(); vectors[name] = document(pairs, secure, large, error, padding)
    text = ['unit Icao.Vectors;', '', '{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}', '', 'interface', '', 'type',
            '  /// <summary>Independent synthetic ICAO command/response hex pair.</summary>', '  TIcaoWirePair = record',
            '    /// <summary>Exact command APDU; published test values only.</summary>', '    Command:string;',
            '    /// <summary>Exact response APDU.</summary>', '    Response:string;', '  end;',
            '  /// <summary>Owned ordered transcript.</summary>', '  TIcaoWirePairs = array of TIcaoWirePair;', '']
    for name in vectors:
        text += ['/// <summary>Independent '+name+' BAC/PACE and secure-messaging transcript.</summary>',
                 '/// <returns>Owned literal test pairs; never production credentials.</returns>', 'function '+name+':TIcaoWirePairs;']
    text += ['', 'implementation', '']
    for name, pairs in vectors.items():
        text += ['function '+name+':TIcaoWirePairs;', 'begin', '  Result:=nil; SetLength(Result,'+str(len(pairs))+');']
        for i, (command, response) in enumerate(pairs):
            text += [f"  Result[{i}].Command:='{command.hex().upper()}';", f"  Result[{i}].Response:='{response.hex().upper()}';"]
        text += ['end;', '']
    text += ['end.', '']
    (ROOT/'tests/eid/Icao.Vectors.pas').write_text('\n'.join(text))
    print('Generated', len(vectors), 'independent ICAO transcripts.')


if __name__ == '__main__':
    generate()
