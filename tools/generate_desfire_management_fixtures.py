#!/usr/bin/env python3
"""Independent DESFire AES administration transcripts with published test secrets.

Optional developer generator. EV1 native CRC/chained IV and EV2 Full/key-change
rules cross-checked against pinned libfreefare/Proxmark sources in DESFIRE.md.
Production never imports this code; Pascal tests consume literal APDUs.
"""
from pathlib import Path
import generate_desfire_fixtures as crypto
from generate_desfire_session_fixtures import Card, raw_settings

ROOT = Path(__file__).resolve().parents[1]
NEW = bytes.fromhex('000102030405060708090A0B0C0D0E0F')
OLD = bytes.fromhex('101112131415161718191A1B1C1D1E1F')
NEXT_RNDA = bytes.fromhex('112233445566778899AABBCCDDEEFF00')
NEXT_RNDB = bytes.fromhex('FFEEDDCCBBAA99887766554433221100')


def fresh_auth(card, key_number):
    challenge_b = crypto.aes(NEW, bytes(16), NEXT_RNDB)
    if card.generation == 'Ev1':
        challenge = crypto.aes(NEW, challenge_b, NEXT_RNDA+NEXT_RNDB[1:]+NEXT_RNDB[:1])
        answer = crypto.aes(NEW, challenge[-16:], NEXT_RNDA[1:]+NEXT_RNDA[:1])
        instruction, header = 0xAA, bytes([key_number])
        card.ev1_key = NEXT_RNDA[:4]+NEXT_RNDB[:4]+NEXT_RNDA[12:]+NEXT_RNDB[12:]
        card.current_iv = bytes(16)
    else:
        challenge = crypto.aes(NEW, bytes(16), NEXT_RNDA+NEXT_RNDB[1:]+NEXT_RNDB[:1])
        answer = crypto.aes(NEW, bytes(16), crypto.TI+NEXT_RNDA[1:]+NEXT_RNDA[:1]+bytes(12))
        instruction, header = 0x71, bytes([key_number, 0])
        vector = NEXT_RNDA[:2]+bytes(a ^ b for a, b in zip(NEXT_RNDA[2:8], NEXT_RNDB[:6]))+NEXT_RNDB[6:]+NEXT_RNDA[8:]
        card.enc = crypto.cmac(NEW, bytes.fromhex('A55A00010080')+vector)
        card.mac = crypto.cmac(NEW, bytes.fromhex('5AA500010080')+vector)
        card.counter = 0
    card.pairs += [(crypto.wrap(instruction, header), challenge_b+bytes.fromhex('91AF')),
                   (crypto.wrap(0xAF, challenge), answer+bytes.fromhex('9100'))]


def admin(generation, free=False):
    card = Card(generation, 3)
    card.metadata(0x45, returned=bytes.fromhex('0F82'))
    card.metadata(0x64, b'\1', b'\x21')
    card.metadata(0x45, returned=bytes.fromhex('0F82'))
    card.exchange(0x54, body=b'\xEF', mode=3, writing=True)
    card.metadata(0x45, returned=bytes.fromhex('EF82'))
    card.metadata(0x45, returned=bytes.fromhex('EF82'))
    before = raw_settings(0, 3, access=b'\x0E\x00' if free else bytes(2))
    card.metadata(0xF5, b'\0', before)
    body = bytes.fromhex('0110E1')  # MACed, RW=1, change=0, read=free, write=1
    card.exchange(0x5F, b'\0', body, mode=0 if free and generation == 'Ev1' else 3, writing=True)
    card.metadata(0xF5, b'\0', before[:1]+body+before[4:])
    return card.pairs


def rotate(generation, target=0, root=False, protected=False, wrong_version=False):
    card = Card(generation, 3, aid=bytes(3) if root else crypto.AID)
    card.metadata(0x45, returned=bytes.fromhex('0F81' if root else '0F82'))
    key_number = target | (0x80 if root else 0)
    body = (bytes(a ^ b for a, b in zip(NEW, OLD)) if target else NEW)+b'\x42'
    if generation == 'Ev1':
        body += crypto.crc32(bytes([0xC4, key_number])+body)
        if target: body += crypto.crc32(NEW)
        body += bytes(-len(body) % 16)
        cipher = crypto.aes(card.ev1_key, card.current_iv, body)
        card.current_iv = cipher[-16:]
        request = bytes([key_number])+cipher
        response = b''
        if target or protected:
            card.current_iv = crypto.chained_cmac(card.ev1_key, card.current_iv, b'\0')
            response = card.current_iv[:8]
        crypto.exchange(card.pairs, 0xC4, request, response)
    else:
        if target: body += crypto.crc32(NEW)
        card.exchange(0xC4, bytes([key_number]), body, mode=3, writing=True)
        if not target and not protected:
            request, response = card.pairs[-1];card.pairs[-1] = (request, bytes.fromhex('9100'))
    fresh_auth(card, target)
    card.metadata(0x64, bytes([target]), b'\x43' if wrong_version else b'\x42')
    # Additional metadata uses the new session/key/counter, without changing source component credentials.
    card.metadata(0x45, returned=bytes.fromhex('0F81' if root else '0F82'))
    return card.pairs


def generate():
    vectors = {}
    for generation in ('Ev1', 'Ev2'):
        vectors[generation+'Admin'] = admin(generation)
        vectors[generation+'FreeAccess'] = admin(generation, True)
        for label, target, root, protected in [('RotateCurrent', 0, False, False),
              ('RotateProtectedCurrent', 0, False, True), ('RotateOther', 1, False, False),
              ('RotateRoot', 0, True, False)]:
            vectors[generation+label] = rotate(generation, target, root, protected)
        vectors[generation+'WrongVersion'] = rotate(generation, wrong_version=True)[:-1]
        card = Card(generation, 3, aid=bytes(3));card.metadata(0x6E, returned=bytes.fromhex('563412'))
        vectors[generation+'FreeMemory'] = card.pairs
        card = Card(generation, 3);card.metadata(0x45, returned=bytes.fromhex('0782'))
        vectors[generation+'FixedSettings'] = card.pairs
        card = Card(generation, 3);card.metadata(0x45, returned=bytes.fromhex('FE82'))
        vectors[generation+'DeniedRotation'] = card.pairs
        card = Card(generation, 3);card.metadata(0x45, returned=bytes.fromhex('0F82'))
        card.metadata(0xF5, b'\0', raw_settings(0, 3, access=bytes.fromhex('0F00')))
        vectors[generation+'DeniedFileChange'] = card.pairs
        # Valid protected responses containing incorrect post-write evidence.
        card = Card(generation, 3);card.metadata(0x45, returned=bytes.fromhex('0F82'))
        card.exchange(0x54, body=b'\xEF', mode=3, writing=True)
        card.metadata(0x45, returned=bytes.fromhex('0F82'))
        vectors[generation+'SettingsMismatch'] = card.pairs
        card = Card(generation, 3);card.metadata(0x45, returned=bytes.fromhex('0F82'))
        card.metadata(0xF5, b'\0', raw_settings(0, 3))
        card.exchange(0x5F, b'\0', bytes.fromhex('0110E1'), mode=3, writing=True)
        card.metadata(0xF5, b'\0', raw_settings(0, 1, access=bytes.fromhex('10E1'))[:4]+bytes.fromhex('210000'))
        vectors[generation+'GeometryMismatch'] = card.pairs
    text = ['unit Desfire.ManagementVectors;', '', '{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}', '', 'interface', '', 'uses Desfire.Vectors;', '']
    for name in vectors:
        text += ['/// <summary>Independent synthetic '+name+' administration transcript.</summary>',
                 '/// <returns>Owned literal pairs with published test credentials.</returns>', 'function '+name+':TDesfireWirePairs;']
    text += ['', 'implementation', '']
    for name, pairs in vectors.items():
        text += ['function '+name+':TDesfireWirePairs;', 'begin', '  Result:=nil;SetLength(Result,'+str(len(pairs))+');']
        for i, (command, response) in enumerate(pairs):
            text += [f"  Result[{i}].Command:='{command.hex().upper()}';", f"  Result[{i}].Response:='{response.hex().upper()}';"]
        text += ['end;', '']
    text += ['end.', '']
    (ROOT/'tests/contactless/Desfire.ManagementVectors.pas').write_text('\n'.join(text))
    print('Generated', len(vectors), 'independent administration transcripts.')


if __name__ == '__main__':
    generate()
