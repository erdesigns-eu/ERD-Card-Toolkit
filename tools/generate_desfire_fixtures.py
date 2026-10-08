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
(ROOT / 'tests/contactless/Desfire.Vectors.pas').write_text('\n'.join(text))
print('Generated', len(vectors), 'independent synthetic transcripts.')
