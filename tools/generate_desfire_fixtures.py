#!/usr/bin/env python3
"""Regenerate synthetic DESFire transcripts using independent Python cryptography.

Optional developer tool, not a runtime/test-runner dependency. All keys/nonces are
published test values, never credentials. NXP AN12343 Table 16 anchors authentication.
The Pascal suite consumes fixed literal transcripts and never invokes this generator.
"""
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.cmac import CMAC

ROOT = Path(__file__).resolve().parents[1]
KEY = bytes(16)
RNDA = bytes.fromhex('B04D0787C93EE0CC8CACC8E86F16C6FE')
RNDB = bytes.fromhex('FA659AD0DCA738DD65DC7DC38612AD81')
TI = bytes.fromhex('8CF141F3')
AID = bytes.fromhex('01EFCD')
MEMORY = bytes(range(32))


def aes(key, iv, data):
    operation = Cipher(algorithms.AES(key), modes.CBC(iv)).encryptor()
    return operation.update(data) + operation.finalize()


def cmac(key, data):
    operation = CMAC(algorithms.AES(key))
    operation.update(data)
    return operation.finalize()


vector = RNDA[:2] + bytes(a ^ b for a, b in zip(RNDA[2:8], RNDB[:6])) + RNDB[6:] + RNDA[8:]
ENC = cmac(KEY, bytes.fromhex('A55A00010080') + vector)
MAC = cmac(KEY, bytes.fromhex('5AA500010080') + vector)
assert ENC.hex().upper() == '63DC07286289A7A6C0334CA31C314A04'
assert MAC.hex().upper() == '774F26743ECE6AF5033B6AE8522946F6'
assert aes(KEY, bytes(16), RNDB).hex().upper() == '24677DDBD46349E623798FD729006E79'


def wrap(command, data=b''):
    return bytes([0x90, command, 0, 0]) + (bytes([len(data)]) + data if data else b'') + b'\0'


def tag(counter, code, body):
    return cmac(MAC, bytes([code]) + counter.to_bytes(2, 'little') + TI + body)[1::2]


def iv(counter, response):
    return aes(ENC, bytes(16), (bytes.fromhex('5AA5') if response else bytes.fromhex('A55A')) + TI + counter.to_bytes(2, 'little') + bytes(8))


def pad(data):
    return data + b'\x80' + bytes(15 - len(data) % 16)


def packet(command, header, body, counter, mode):
    if mode == 3 and body:
        body = aes(ENC, iv(counter, False), pad(body))
    result = header + body
    return result + tag(counter, command, result) if mode else result


def answer(body, counter, mode):
    if mode == 3 and body:
        body = aes(ENC, iv(counter, True), pad(body))
    return body + tag(counter, 0, body) if mode else body


def exchange(pairs, command, data, response, frame=48, response_frame=256):
    while len(data) > frame:
        pairs.append((wrap(command, data[:frame]), bytes.fromhex('91AF')))
        data = data[frame:]
        command = 0xAF
    while len(response) > response_frame:
        pairs.append((wrap(command, data), response[:response_frame] + bytes.fromhex('91AF')))
        command, data, response = 0xAF, b'', response[response_frame:]
    pairs.append((wrap(command, data), response + bytes.fromhex('9100')))


def start():
    return [(wrap(0x5A, AID), bytes.fromhex('9100'))]


def authenticate(pairs):
    pairs.append((wrap(0x71, b'\0\0'), aes(KEY, bytes(16), RNDB) + bytes.fromhex('91AF')))
    pairs.append((wrap(0xAF, aes(KEY, bytes(16), RNDA + RNDB[1:] + RNDB[:1])),
                  aes(KEY, bytes(16), TI + RNDA[1:] + RNDA[:1] + bytes(12)) + bytes.fromhex('9100')))


def settings(mode, kind=0):
    header = bytes([kind, mode, 0, 0])
    if kind in (0, 1):
        return header + (32).to_bytes(3, 'little')
    if kind == 2:
        return header + (-100).to_bytes(4, 'little', signed=True) + (100).to_bytes(4, 'little', signed=True) + bytes(5)
    return header + (4).to_bytes(3, 'little') + (3).to_bytes(3, 'little') + (2).to_bytes(3, 'little')


def read_write(mode, write=False, chained=False, kind=0):
    pairs = start()
    authenticate(pairs)
    counter = 0
    frame, response_frame = (16, 7) if chained else (48, 256)
    file = 0 if kind in (0, 1) else kind
    raw = settings(mode, kind)

    def command(code, header, data, returned, communication):
        nonlocal counter
        request = packet(code, header, data, counter, communication)
        counter += 1
        response = answer(returned, counter, communication)
        exchange(pairs, code, request, response, frame, response_frame)

    def metadata():
        command(0xF5, bytes([file]), b'', raw, 1)

    metadata()
    count = 25 if kind in (0, 1) else (4 if kind == 2 else 2)
    header = bytes([file]) + bytes(3) + count.to_bytes(3, 'little')
    code = 0xAD if kind in (0, 1) else (0x6C if kind == 2 else 0xAB)
    if kind == 2:
        header = bytes([file])
        acquired = (-17).to_bytes(4, 'little', signed=True)
    elif kind in (3, 4):
        acquired = bytes.fromhex('1112131421222324')
    else:
        acquired = MEMORY[:count]
    command(code, header, b'', acquired, mode)
    metadata()
    if write:
        command(0x8D, header, b'\x22' * count, b'', mode)
        command(0xAD, header, b'', b'\x22' * count, mode)
        metadata()
    return pairs


vectors = {}
for mode, label in [(0, 'Plain'), (1, 'Mac'), (3, 'Full')]:
    vectors['Ev2Read' + label] = read_write(mode)
    vectors['Ev2Write' + label] = read_write(mode, write=True)
    vectors['Ev2Write' + label + 'Chained'] = read_write(mode, write=True, chained=True)
for kind, label in [(1, 'Backup'), (2, 'Value'), (3, 'Linear'), (4, 'Cyclic')]:
    vectors['Ev2Read' + label] = read_write(3, kind=kind)

# Authenticated metadata and access-policy transcripts, independently MACed.
pairs = start()
exchange(pairs, 0x6F, b'', bytes([0, 1, 2, 3, 4]))
authenticate(pairs)
for counter, kind in enumerate(range(5)):
    exchange(pairs, 0xF5, packet(0xF5, bytes([kind]), b'', counter, 1),
             answer(settings(3, kind), counter + 1, 1))
vectors['Ev2Directory'] = pairs
for label, access in [('Ev2DeniedRead', bytes.fromhex('1010')), ('Ev2WriteWithoutRead', bytes.fromhex('F0F0'))]:
    pairs = start()
    authenticate(pairs)
    raw = bytes([0, 3]) + access + (32).to_bytes(3, 'little')
    exchange(pairs, 0xF5, packet(0xF5, b'\0', b'', 0, 1), answer(raw, 1, 1))
    vectors[label] = pairs

# Legacy public standard-file write with both outbound/inbound continuation chains.
pairs = start()
raw = bytes.fromhex('0000EEEEE80300')  # 1000 bytes, all free rights
exchange(pairs, 0xF5, b'\0', raw)
exchange(pairs, 0xBD, bytes.fromhex('00000000190000'), MEMORY[:25], response_frame=7)
exchange(pairs, 0xF5, b'\0', raw)
exchange(pairs, 0x3D, bytes.fromhex('00000000190000') + b'\x22' * 25, b'', frame=16)
exchange(pairs, 0xBD, bytes.fromhex('00000000190000'), b'\x22' * 25, response_frame=7)
exchange(pairs, 0xF5, b'\0', raw)
vectors['PublicWriteChained'] = pairs

# EV1 AES: independently synthesized chained-IV transcripts. CRC uses zlib's
# finalized implementation, inverted to DESFire's unfinalized convention.
import zlib


def crc32(data):
    return (zlib.crc32(data) ^ 0xFFFFFFFF).to_bytes(4, 'little')


def chained_cmac(key, initial, data):
    # Standard CMAC subkeys stay independent of the session starting IV.
    def double(block):
        number = int.from_bytes(block, 'big')
        return (((number << 1) & ((1 << 128) - 1)) ^ (0x87 if number >> 127 else 0)).to_bytes(16, 'big')
    k1 = double(aes(key, bytes(16), bytes(16)))
    k2 = double(k1)
    complete = bool(data) and len(data) % 16 == 0
    padded = data if complete else pad(data)
    last = bytes(a ^ b for a, b in zip(padded[-16:], k1 if complete else k2))
    return aes(key, initial, padded[:-16] + last)[-16:]


# Anchors the separately implemented chained variant to maintained standard CMAC.
for length in range(65):
    message = bytes(range(length))
    assert chained_cmac(KEY, bytes(16), message) == cmac(KEY, message)


def ev1_read_write(mode, write=False, chained=False, kind=0, count=25, malformed=None):
    pairs = start()
    first_cipher = aes(KEY, bytes(16), RNDB)
    challenge = aes(KEY, first_cipher, RNDA + RNDB[1:] + RNDB[:1])
    pairs.append((wrap(0xAA, b'\0'), first_cipher + bytes.fromhex('91AF')))
    pairs.append((wrap(0xAF, challenge), aes(KEY, challenge[-16:], RNDA[1:] + RNDA[:1]) + bytes.fromhex('9100')))
    key = RNDA[:4] + RNDB[:4] + RNDA[12:] + RNDB[12:]
    current_iv = bytes(16)
    frame, response_frame = (16, 7) if chained else (48, 256)
    file = 0 if kind in (0, 1) else kind
    raw = settings(mode, kind)

    def command(code, header, body, returned, communication, writing=False, corrupt=None):
        nonlocal current_iv
        message = bytes([code]) + header + body
        if writing and communication == 3:
            padded = body + crc32(message)
            padded += bytes(-len(padded) % 16)
            encrypted = aes(key, current_iv, padded)
            current_iv = encrypted[-16:]
            request = header + encrypted
        else:
            current_iv = chained_cmac(key, current_iv, message)
            request = header + body + (current_iv[:8] if writing and communication == 1 else b'')
        if communication == 3 and not writing:
            check = crc32(returned + b'\0')
            if corrupt == 'crc':
                check = bytes([check[0] ^ 1]) + check[1:]
            padded = returned + check + bytes(-(len(returned) + 4) % 16)
            if corrupt in ('pad', 'marker'):
                padding_start = len(returned) + 4
                assert padding_start < len(padded)
                padded = padded[:padding_start] + bytes([0x80 if corrupt == 'marker' else 1]) + padded[padding_start + 1:]
            response = aes(key, current_iv, padded)
            current_iv = response[-16:]
        else:
            current_iv = chained_cmac(key, current_iv, returned + b'\0')
            response = returned + current_iv[:8]
        exchange(pairs, code, request, response, frame, response_frame)

    def metadata():
        command(0xF5, bytes([file]), b'', raw, 0)

    metadata()
    if kind == 2:
        acquired = (-17).to_bytes(4, 'little', signed=True)
        header, code = bytes([file]), 0x6C
    elif kind in (3, 4):
        acquired = bytes.fromhex('1112131421222324')
        header, code = bytes([file]) + bytes(3) + (2).to_bytes(3, 'little'), 0xBB
    else:
        acquired = MEMORY[:count]
        header, code = bytes([file]) + bytes(3) + count.to_bytes(3, 'little'), 0xBD
    command(code, header, b'', acquired, mode, corrupt=malformed)
    metadata()
    if write:
        command(0x3D, header, b'\x22' * count, b'', mode, writing=True)
        command(0xBD, header, b'', b'\x22' * count, mode)
        metadata()
    return pairs


for mode, label in [(0, 'Plain'), (1, 'Mac'), (3, 'Full')]:
    vectors['Ev1Read' + label] = ev1_read_write(mode)
    vectors['Ev1Write' + label] = ev1_read_write(mode, write=True)
    vectors['Ev1Write' + label + 'Chained'] = ev1_read_write(mode, write=True, chained=True)
for kind, label in [(1, 'Backup'), (2, 'Value'), (3, 'Linear'), (4, 'Cyclic')]:
    vectors['Ev1Read' + label] = ev1_read_write(3, kind=kind)
for count in [12, 13, 16, 28, 29]:
    vectors['Ev1ReadLength' + str(count)] = ev1_read_write(3, count=count)
for label, corrupt in [('BadCrc', 'crc'), ('BadPadding', 'pad'), ('MarkerPadding', 'marker')]:
    vectors['Ev1Read' + label] = ev1_read_write(3, malformed=corrupt)


# EV2 NonFirst uses distinct credentials and card/reader nonces. The first
# authenticated F5 consumes counter 1 before switching; TI and counter persist.
SECOND_KEY = bytes(range(16))
SECOND_RNDA = bytes.fromhex('112233445566778899AABBCCDDEEFF00')
SECOND_RNDB = bytes.fromhex('102030405060708090A0B0C0D0E0F001')
second_vector = SECOND_RNDA[:2] + bytes(a ^ b for a, b in zip(SECOND_RNDA[2:8], SECOND_RNDB[:6])) + SECOND_RNDB[6:] + SECOND_RNDA[8:]
SECOND_ENC = cmac(SECOND_KEY, bytes.fromhex('A55A00010080') + second_vector)
SECOND_MAC = cmac(SECOND_KEY, bytes.fromhex('5AA500010080') + second_vector)


def nonfirst_read_write(mode, write=False, chained=False, kind=0):
    global ENC, MAC
    pairs = start()
    authenticate(pairs)
    file = 0 if kind in (0, 1) else kind
    raw = settings(mode, kind)[:2] + bytes.fromhex('1011') + settings(mode, kind)[4:]
    frame, response_frame = (16, 7) if chained else (48, 256)
    exchange(pairs, 0xF5, packet(0xF5, bytes([file]), b'', 0, 1), answer(raw, 1, 1), frame, response_frame)
    pairs.append((wrap(0x77, b'\1'), aes(SECOND_KEY, bytes(16), SECOND_RNDB) + bytes.fromhex('91AF')))
    pairs.append((wrap(0xAF, aes(SECOND_KEY, bytes(16), SECOND_RNDA + SECOND_RNDB[1:] + SECOND_RNDB[:1])),
                  aes(SECOND_KEY, bytes(16), SECOND_RNDA[1:] + SECOND_RNDA[:1]) + bytes.fromhex('9100')))
    old_enc, old_mac = ENC, MAC
    ENC, MAC = SECOND_ENC, SECOND_MAC
    try:
        counter = 1
        if kind == 2:
            header, code, acquired = bytes([file]), 0x6C, (-17).to_bytes(4, 'little', signed=True)
        elif kind in (3, 4):
            header, code, acquired = bytes([file]) + bytes(3) + (2).to_bytes(3, 'little'), 0xAB, bytes.fromhex('1112131421222324')
        else:
            header, code, acquired = bytes([file]) + bytes(3) + (25).to_bytes(3, 'little'), 0xAD, MEMORY[:25]

        def command(code, hdr, body, returned, communication):
            nonlocal counter
            request = packet(code, hdr, body, counter, communication)
            counter += 1
            exchange(pairs, code, request, answer(returned, counter, communication), frame, response_frame)

        command(code, header, b'', acquired, mode)
        command(0xF5, bytes([file]), b'', raw, 1)
        if write:
            command(0x8D, header, b'\x22' * 25, b'', mode)
            command(0xAD, header, b'', b'\x22' * 25, mode)
            command(0xF5, b'\0', b'', raw, 1)
    finally:
        ENC, MAC = old_enc, old_mac
    return pairs


for mode, label in [(0, 'Plain'), (1, 'Mac'), (3, 'Full')]:
    vectors['Ev2NonFirstRead' + label] = nonfirst_read_write(mode)
    vectors['Ev2NonFirstWrite' + label] = nonfirst_read_write(mode, write=True)
    vectors['Ev2NonFirstWrite' + label + 'Chained'] = nonfirst_read_write(mode, write=True, chained=True)

for kind, label in [(1, 'Backup'), (2, 'Value'), (3, 'Linear'), (4, 'Cyclic')]:
    vectors['Ev2NonFirstRead' + label] = nonfirst_read_write(3, kind=kind)

# EV1 metadata directory: public enumeration, then AuthenticateAES and five
# chained-IV/CMAC-protected settings. Reuse independently synthesized settings.
pairs = start()
exchange(pairs, 0x6F, b'', bytes(range(5)))
first_cipher = aes(KEY, bytes(16), RNDB)
challenge = aes(KEY, first_cipher, RNDA + RNDB[1:] + RNDB[:1])
pairs.append((wrap(0xAA, b'\0'), first_cipher + bytes.fromhex('91AF')))
pairs.append((wrap(0xAF, challenge), aes(KEY, challenge[-16:], RNDA[1:] + RNDA[:1]) + bytes.fromhex('9100')))
key = RNDA[:4] + RNDB[:4] + RNDA[12:] + RNDB[12:]
current_iv = bytes(16)
for kind in range(5):
    current_iv = chained_cmac(key, current_iv, bytes([0xF5, kind]))
    raw = settings(3, kind)
    current_iv = chained_cmac(key, current_iv, raw + b'\0')
    exchange(pairs, 0xF5, bytes([kind]), raw + current_iv[:8])
vectors['Ev1Directory'] = pairs

text = ['unit Desfire.Vectors;', '', '{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}', '', 'interface', '', 'type',
        '  /// <summary>Synthetic independently generated command/response pair; contains published test keys only.</summary>',
        '  TDesfireWirePair = record',
        '    /// <summary>Literal complete wrapped command hex.</summary>', '    Command: string;',
        '    /// <summary>Literal complete response hex, including native status.</summary>', '    Response: string;', '  end;',
        '  /// <summary>Owned ordered synthetic transcript.</summary>', '  TDesfireWirePairs = array of TDesfireWirePair;', '']
for name in vectors:
    text += ['/// <summary>Returns independently generated synthetic ' + name + ' transcript.</summary>',
             '/// <returns>Owned command/response pairs, never physical card data.</returns>', 'function ' + name + ': TDesfireWirePairs;']
text += ['', 'implementation', '']
for name, pairs in vectors.items():
    text += ['function ' + name + ': TDesfireWirePairs;', 'begin', '  Result:=nil; SetLength(Result,' + str(len(pairs)) + ');']
    for index, (command, response) in enumerate(pairs):
        text += [f"  Result[{index}].Command:='{command.hex().upper()}';", f"  Result[{index}].Response:='{response.hex().upper()}';"]
    text += ['end;', '']
text += ['end.', '']
if __name__ == '__main__':
    (ROOT / 'tests/contactless/Desfire.Vectors.pas').write_text('\n'.join(text))
    print('Generated', len(vectors), 'independent synthetic transcripts.')
