#!/usr/bin/env python3
"""Regenerate synthetic interoperability vectors using pyemv 1.5.0 and cryptography.

These packages are optional fixture-generation dependencies, never runtime code.
Run with PYTHONPATH pointing at a separately installed pyemv 1.5.0 directory.
The committed fixtures allow normal tests to run without Python crypto packages.
"""
from importlib.metadata import version
from pathlib import Path
import hashlib
import random
import warnings

warnings.filterwarnings('ignore', category=Warning)
from pyemv import ac, kd, sm, tools
from pyemv import cvn
from cryptography.hazmat.primitives.cmac import CMAC
from cryptography.hazmat.primitives.ciphers import algorithms

if version('pyemv') != '1.5.0':
    raise RuntimeError('Fixture generation requires pyemv 1.5.0')

rng = random.Random(0xE4CA1C)
rows = []

def binary(count):
    return bytes(rng.randrange(256) for _ in range(count))

def add(operation, key=b'', a=b'', b=b'', c=b'', result=b''):
    def encoded(value):
        return value if isinstance(value, str) else value.hex().upper()
    rows.append('|'.join(encoded(v) for v in (operation, key, a, b, c, result)))

# Independent published pyemv examples, followed by reproducible variable-size cases.
add('AC2', bytes.fromhex('29B33180E567CE38EA4CBC9D753B0E61'),
    bytes.fromhex('0123456789ABCDEF0123456789ABCDEF'), result=bytes.fromhex('FA624250B008B59A'))
add('ARPC1', bytes.fromhex('29B33180E567CE38EA4CBC9D753B0E61'),
    bytes.fromhex('FA624250B008B59A'), bytes.fromhex('0000'), result=bytes.fromhex('45D4255EEF10C920'))
add('ARPC2', bytes.fromhex('29B33180E567CE38EA4CBC9D753B0E61'),
    bytes.fromhex('FA624250B008B59A'), bytes(4), result=bytes.fromhex('CB56FA40'))
for index in range(100):
    key, r, atc, un = binary(16), binary(8), binary(2), binary(4)
    pan = ''.join(str(rng.randrange(10)) for _ in range(1 + index % 19))
    psn = str(index % 100).zfill(2)
    add('UDKA', key, pan, psn, result=kd.derive_icc_mk_a(key, pan, psn))
    add('UDKB', key, pan, psn, result=kd.derive_icc_mk_b(key, pan, psn))
    add('COMMON', key, r, result=kd.derive_common_sk(key, r))
    add('ATC', key, atc, result=kd.derive_common_sk(key, atc + bytes(6)))
    add('MC', key, atc, un, result=kd.derive_common_sk(key, atc + bytes(2) + un))
    add('VISA', key, atc, result=kd.derive_visa_sm_sk(key, atc))
    for height, branch in ((8, 4), (16, 2), (4, 16), (2, 256)):
        iv = binary(16)
        add('TREE', key, atc, iv, str(height) + ',' + str(branch),
            kd.derive_emv2000_tree_sk(key, atc, height=height, branch_factor=branch, iv=iv))
    data = binary(index)
    for padding, name in ((ac.PaddingType.VISA, 'AC1'), (ac.PaddingType.EMV, 'AC2')):
        add(name, key, data, result=ac.generate_ac(key, data, padding))
    arqc, rc, csu, auth = binary(8), binary(2), binary(4), binary(index % 9)
    add('ARPC1', key, arqc, rc, result=ac.generate_arpc_1(key, arqc, rc))
    add('ARPC2', key, arqc, csu, auth, ac.generate_arpc_2(key, arqc, csu, auth))
    add('KCV', key, result=tools.key_check_digits(key, 8))
    add('PARITY', key, result=tools.adjust_key_parity(key))
    add('SCRIPTMAC', key, data, result=sm.generate_command_mac(key, data))
    for mode, name in ((sm.EncryptionType.VISA, 'SCRIPT_VISA'),
                       (sm.EncryptionType.MASTERCARD, 'SCRIPT_MC'),
                       (sm.EncryptionType.EMV, 'SCRIPT_EMV')):
        if not data and mode == sm.EncryptionType.MASTERCARD:
            add(name, key, data, result=b'')
        else:
            add(name, key, data, result=sm.encrypt_command_data(key, data, mode))
    pin = ''.join(str(rng.randrange(10)) for _ in range(4 + index % 9))
    old = ''.join(str(rng.randrange(10)) for _ in range(4 + (index + 1) % 9))
    add('PIN2', a=pin, result=sm.format_iso9564_2_pin_block(pin))
    add('PINVISA', key, pin, old, result=sm.format_vis_pin_block(key, pin, old))
    add('PINVISA', key, pin, '', result=sm.format_vis_pin_block(key, pin))
    cmac = CMAC(algorithms.AES(key)); cmac.update(data)
    add('CMAC', key, data, result=cmac.finalize())
    add('HASH', a=data, result=hashlib.sha1(data).digest())

# Scheme/CVN wrappers: full data assembly and AC/ARPC key differences.
classes = [cvn.VisaCVN10, cvn.VisaCVN18, cvn.VisaCVN22,
           cvn.MasterCardCVN16, cvn.MasterCardCVN17, cvn.MasterCardCVN20,
           cvn.MasterCardCVN21, cvn.InteracCVN133]
base = dict(tag_9f02=bytes.fromhex('000000009999'), tag_9f03=bytes(6),
            tag_9f1a=bytes.fromhex('0840'), tag_95=bytes.fromhex('8000048000'),
            tag_5f2a=bytes.fromhex('0840'), tag_9a=bytes.fromhex('991231'),
            tag_9c=bytes.fromhex('01'), tag_9f37=bytes.fromhex('52BF4585'),
            tag_82=bytes.fromhex('1800'), tag_9f36=bytes.fromhex('0FFF'))
for index, cls in enumerate(classes):
    for sequence in range(12):
        issuer = binary(16)
        card = cls(issuer, bytes(16), bytes(16), '1234567890123456', '00')
        args = dict(base)
        args['tag_9f36'] = binary(2); args['tag_9f37'] = binary(4)
        tail = binary(7)
        if index == 0:
            tail = binary(4); args['cvr'] = tail
        elif index in (3, 4, 5, 6):
            tail = binary(6); args['cvr'] = tail
            if index in (4, 6):
                counters = binary(8); args['counters'] = counters
            else:
                counters = b''
        else:
            args['tag_9f10'] = tail
        counter_data = args.get('counters', b'')
        result = card.generate_ac(**args)
        packed = b''.join(args[k] for k in base)
        add('PROFILE' + str(index), card.icc_mk_ac, packed, tail, counter_data, result)
        if index in (1, 2):
            response = card.generate_arpc(result, args['tag_9f36'], bytes(4))
        elif index == 0:
            response = card.generate_arpc(result, bytes(2))
        elif index == 7:
            response = card.generate_arpc(tag_9f26=result, tag_9f36=args['tag_9f36'],
                                          tag_9f37=args['tag_9f37'], arpc_rc=bytes(2))
        elif index in (3, 4):
            response = card.generate_arpc(result, bytes(2))
        else:
            response = card.generate_arpc(result, args['tag_9f36'], bytes(2))
        add('PROFILE_ARPC' + str(index), card.icc_mk_ac,
            args['tag_9f36'] + args['tag_9f37'], result, result=response)

out = Path(__file__).resolve().parents[1] / 'tests/emv/fixtures/calculators.txt'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text('# Synthetic vectors; pyemv 1.5.0; seed E4CA1C; no production keys\n' +
               '\n'.join(rows) + '\n', encoding='ascii')
print(f'Wrote {len(rows)} independent EMV vectors to {out}')
