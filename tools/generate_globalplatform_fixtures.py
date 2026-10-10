#!/usr/bin/env python3
"""Generate synthetic SCP02/SCP03 transcripts independently with cryptography.

No card keys, recorded sessions, native GlobalPlatform library or deterministic
production RNG are used. This generator is optional; committed vectors are used
by the Pascal tests. Implements GP 2.1.1 Appendix E and Amendment D KDF/SM math.
"""
from pathlib import Path
import random
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.cmac import CMAC
from cryptography.hazmat.decrepit.ciphers.algorithms import TripleDES

ROOT = Path(__file__).resolve().parents[1]
RNG = random.Random(0x47504341)


def rand(n):
    return bytes(RNG.randrange(256) for _ in range(n))


def crypt(k, data, iv, aes=True):
    if not aes and len(k) == 16:
        k = k + k[:8]
    cipher = Cipher(algorithms.AES(k) if aes else TripleDES(k), modes.CBC(iv))
    c = cipher.encryptor()
    return c.update(data) + c.finalize()


def pad(data, block):
    return data + b'\x80' + bytes((-len(data) - 1) % block)


def cmac(k, data):
    c = CMAC(algorithms.AES(k))
    c.update(data)
    return c.finalize()


def retail(k, data, iv):
    # Independently express ISO9797 alg3 as DES CBC, decrypt K2 then encrypt K1.
    padded = pad(data, 8)
    des = TripleDES(k[:8] * 3)
    c = Cipher(des, modes.CBC(iv)).encryptor()
    last = (c.update(padded) + c.finalize())[-8:]
    d = Cipher(TripleDES(k[8:] * 3), modes.ECB()).decryptor()
    middle = d.update(last) + d.finalize()
    e = Cipher(des, modes.ECB()).encryptor()
    return e.update(middle) + e.finalize()


def kdf(k, context, constant, bits=128):
    return cmac(k, bytes(11) + bytes([constant, 0]) + bits.to_bytes(2, 'big') + b'\x01' + context)[:bits // 8]


def apdu(cla, ins, p1, p2, data=b'', le=False):
    return bytes([cla, ins, p1, p2]) + (bytes([len(data)]) + data if data else b'') + (b'\x00' if le else b'')


def session(protocol, level, s16, n, operations=None, pseudo=False, domain=b'', double_select=False):
    enc, mac = rand(16), rand(16)
    size = 16 if s16 else 8
    host, card = rand(size), rand(size)
    if pseudo:
        domain = domain or bytes.fromhex('A000000151000000')
        sequence3 = rand(3)
        card = kdf(enc, sequence3 + domain, 2, size * 8)
    rows = [('S', enc.hex(), mac.hex(), host.hex(), str(protocol), str(level), str(int(s16)), domain.hex())]
    if domain:
        rows.append(('A', apdu(0, 0xA4, 4, 0, domain, True).hex(), '9000'))
        if double_select:
            rows.append(('A', apdu(0, 0xA4, 4, 0, domain, True).hex(), '9000'))
    if protocol == 2:
        sequence, challenge = card[:2], card[2:]
        senc = crypt(enc, b'\x01\x82' + sequence + bytes(12), bytes(8), False)
        smac = crypt(mac, b'\x01\x01' + sequence + bytes(12), bytes(8), False)
        cardcrypt = crypt(senc, pad(host + card, 8), bytes(8), False)[-8:]
        hostcrypt = crypt(senc, pad(card + host, 8), bytes(8), False)[-8:]
        init = rand(10) + bytes([1, 2]) + sequence + challenge + cardcrypt
        chain = bytes(8)
    else:
        context = host + card
        senc, smac, srmac = (kdf(k, context, c) for k, c in [(enc, 4), (mac, 6), (mac, 7)])
        cardcrypt, hostcrypt = (kdf(smac, context, c, size * 8) for c in [0, 1])
        init = rand(10) + bytes([1, 3, 0x60 | int(s16) | (0x10 if pseudo else 0)]) + card + cardcrypt + (sequence3 if pseudo else b'')
        chain = bytes(16)
    rows.append(('A', apdu(0x80, 0x50, 1, 0, host, True).hex(), (init + b'\x90\x00').hex()))
    security = [1, 3, 0x11, 0x13, 0x33][level]
    eahead = bytes([0x84, 0x82, security, 0, len(hostcrypt) + size])
    chain = retail(smac, eahead + hostcrypt, chain) if protocol == 2 else cmac(smac, chain + eahead + hostcrypt)
    rows.append(('A', (eahead + hostcrypt + chain[:size] + b'\x00').hex(), '9000'))
    counter = 0
    if operations is None:
        operations = [(0x80, 0xCA, n % 256, index, rand(length), True, rand(index * 3))
                      for index, length in enumerate([0, 1, 8, 16, 31, 64, 127, 220])]
    for cla, ins, p1, p2, plain, le, response in operations:
        length = len(plain)
        cmd = apdu(cla, ins, p1, p2, plain, le)
        encrypted = level in [1, 3, 4]
        if protocol == 2:
            iv = crypt(smac[:8] * 3, chain, bytes(8), False)
            chain = retail(smac, bytes([cla | 4, ins, p1, p2, length + 8]) + plain, iv)
            body = crypt(senc, pad(plain, 8), bytes(8), False) if encrypted and plain else plain
        else:
            if encrypted:
                counter += 1
            iv = crypt(senc, counter.to_bytes(16, 'big'), bytes(16))
            body = crypt(senc, pad(plain, 16), iv) if encrypted and plain else plain
            chain = cmac(smac, chain + bytes([cla | 4, ins, p1, p2, len(body) + size]) + body)
        wire = apdu(cla | 4, ins, p1, p2, body + chain[:size], le)
        status = b'\x90\x00'
        data = response
        if level == 4 and response:
            riv = crypt(senc, b'\x80' + counter.to_bytes(16, 'big')[1:], bytes(16))
            data = crypt(senc, pad(response, 16), riv)
        if level >= 2:
            data += cmac(srmac, chain + data + status)[:size]
        rows.append(('X', cmd.hex(), wire.hex(), (data + status).hex(), (response + status).hex()))
    rows.append(('E',))
    return rows


def main():
    rows = []
    for protocol, levels, widths in [(2, range(2), [False]), (3, range(5), [False, True])]:
        for level in levels:
            for s16 in widths:
                for n in range(12):
                    rows.extend(session(protocol, level, s16, n))
    for s16 in [False, True]:
        for level in range(5):
            rows.extend(session(3, level, s16, 99, pseudo=True))
    path = ROOT / 'tests/globalplatform/fixtures/secure-channels.txt'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('# Synthetic independent GP transcripts: 154 sessions, 1232 protected exchanges\n' +
                    '\n'.join('|'.join(r) for r in rows) + '\n')

    # Separate manager-level transcripts cover actual CAP installation commands.
    def component(tag, body):
        return bytes([tag]) + len(body).to_bytes(2, 'big') + body
    parts = {1: component(1, bytes.fromhex('DECAFFED020204000108A000000151000101')),
             3: component(3, bytes.fromhex('0108A0000001510001020000')),
             4: component(4, b'\x00'), 5: component(5, bytes(2)),
             6: component(6, b'\x00'), 7: component(7, b'\x00'),
             8: component(8, bytes(10)), 9: component(9, bytes(4))}
    directory = b''.join((33 if i == 2 else len(parts.get(i, b'\x00\x00\x00')) - 3).to_bytes(2, 'big')
                         for i in range(1, 13)) + bytes(6) + bytes([0, 1, 0])
    parts[2] = component(2, directory)
    body = b''.join(parts.get(i, b'') for i in [1, 2, 4, 3, 6, 7, 8, 10, 5, 9])
    assert len(body) < 128
    image = b'\xc4' + bytes([len(body)]) + body
    domain = bytes.fromhex('A000000151000000')
    package = bytes.fromhex('A000000151000101')
    module = bytes.fromhex('A000000151000102')
    instance = bytes.fromhex('A000000151000103')
    lv = lambda b: bytes([len(b)]) + b
    commands = [(0x80, 0xE6, 2, 0, lv(package) + lv(domain) + bytes(3), True, b'\x00')]
    blocks = [image[i:i+20] for i in range(0, len(image), 20)]
    commands += [(0x80, 0xE8, 0x80 if i == len(blocks)-1 else 0, i, b, True, b'\x00')
                 for i, b in enumerate(blocks)]
    parameters = bytes.fromhex('C9020102')
    confirmation = bytes.fromhex('110801020304050607080200010401020304')
    commands += [(0x80, 0xE6, 0x0C, 0, lv(package) + lv(module) + lv(instance) + lv(b'\x00') + lv(parameters) + b'\x00', True, confirmation),
                 (0x80, 0xF0, 0x40, 7, instance, True, b'\x00'),
                 (0x80, 0xE4, 0, 0x80, b'\x4f' + lv(instance), True, b'\x00')]
    management = []
    for protocol, level, s16 in [(2, 1, False), (3, 4, False), (3, 4, True)]:
        management += session(protocol, level, s16, 0, commands, domain=domain, double_select=True)
    (path.parent / 'management.txt').write_text('# Independent manager command transcripts\n' +
                                              '\n'.join('|'.join(r) for r in management) + '\n')
    print('Generated 154 authentication sessions and 1232 protected command/response pairs.')


if __name__ == '__main__':
    main()
