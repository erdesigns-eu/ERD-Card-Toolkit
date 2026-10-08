#!/usr/bin/env python3
"""Generate independent synthetic DESFire session transcripts, never production keys."""
from pathlib import Path
import generate_desfire_fixtures as crypto

ROOT = Path(__file__).resolve().parents[1]


class Card:
    def __init__(self, generation, mode=3, aid=crypto.AID, nonfirst=False, frame=48):
        self.generation, self.mode, self.frame = generation, mode, frame
        self.pairs = [(crypto.wrap(0x5A, aid), bytes.fromhex('9100'))]
        self.counter, self.current_iv = 0, bytes(16)
        self.enc, self.mac = crypto.ENC, crypto.MAC
        self.nonfirst = nonfirst
        if generation == 'Ev2':
            crypto.authenticate(self.pairs)
        elif generation == 'Ev1':
            challenge_b = crypto.aes(crypto.KEY, bytes(16), crypto.RNDB)
            challenge = crypto.aes(crypto.KEY, challenge_b, crypto.RNDA + crypto.RNDB[1:] + crypto.RNDB[:1])
            self.pairs += [(crypto.wrap(0xAA, b'\0'), challenge_b + bytes.fromhex('91AF')),
                           (crypto.wrap(0xAF, challenge), crypto.aes(crypto.KEY, challenge[-16:], crypto.RNDA[1:] + crypto.RNDA[:1]) + bytes.fromhex('9100'))]
            self.ev1_key = crypto.RNDA[:4] + crypto.RNDB[:4] + crypto.RNDA[12:] + crypto.RNDB[12:]

    def exchange(self, cmd, header=b'', body=b'', returned=b'', mode=None, writing=False):
        communication = self.mode if mode is None else mode
        response_frame = 7 if self.frame == 16 else 256
        if self.generation == 'Public':
            request, response = header + body, returned
        elif self.generation == 'Ev2':
            old_enc, old_mac = crypto.ENC, crypto.MAC
            crypto.ENC, crypto.MAC = self.enc, self.mac
            try:
                request = crypto.packet(cmd, header, body, self.counter, communication)
                self.counter += 1
                response = crypto.answer(returned, self.counter, communication)
            finally:
                crypto.ENC, crypto.MAC = old_enc, old_mac
        else:
            message = bytes([cmd]) + header + body
            if writing and communication == 3:
                padded = body + crypto.crc32(message)
                padded += bytes(-len(padded) % 16)
                encrypted = crypto.aes(self.ev1_key, self.current_iv, padded)
                self.current_iv = encrypted[-16:]
                request = header + encrypted
            else:
                self.current_iv = crypto.chained_cmac(self.ev1_key, self.current_iv, message)
                request = header + body + (self.current_iv[:8] if writing and communication == 1 else b'')
            if communication == 3 and not writing:
                padded = returned + crypto.crc32(returned + b'\0')
                padded += bytes(-len(padded) % 16)
                response = crypto.aes(self.ev1_key, self.current_iv, padded)
                self.current_iv = response[-16:]
            else:
                self.current_iv = crypto.chained_cmac(self.ev1_key, self.current_iv, returned + b'\0')
                response = returned + self.current_iv[:8]
        crypto.exchange(self.pairs, cmd, request, response, self.frame, response_frame)

    def metadata(self, cmd, header=b'', returned=b''):
        self.exchange(cmd, header=header, returned=returned, mode=1)

    def switch(self):
        if not self.nonfirst:
            return
        self.nonfirst = False
        self.pairs += [(crypto.wrap(0x77, b'\1'), crypto.aes(crypto.SECOND_KEY, bytes(16), crypto.SECOND_RNDB) + bytes.fromhex('91AF')),
                       (crypto.wrap(0xAF, crypto.aes(crypto.SECOND_KEY, bytes(16), crypto.SECOND_RNDA + crypto.SECOND_RNDB[1:] + crypto.SECOND_RNDB[:1])),
                        crypto.aes(crypto.SECOND_KEY, bytes(16), crypto.SECOND_RNDA[1:] + crypto.SECOND_RNDA[:1]) + bytes.fromhex('9100'))]
        self.enc, self.mac = crypto.SECOND_ENC, crypto.SECOND_MAC


def raw_settings(kind, mode, count=2, access=b'\0\0', limits=(-100, 100), initial=10, allowance=20, limited=True):
    head = bytes([kind, mode]) + access
    if kind < 2:
        return head + (32).to_bytes(3, 'little')
    if kind == 2:
        return head + b''.join(v.to_bytes(4, 'little', signed=True) for v in (*limits, allowance)) + bytes([int(limited)])
    return head + (4).to_bytes(3, 'little') + (3).to_bytes(3, 'little') + count.to_bytes(3, 'little')


LINEAR = bytes.fromhex('1112131421222324')
CYCLIC = LINEAR + bytes.fromhex('31323334')


def transaction(generation, mode, abort=False, discard=False, nonfirst=False, frame=48, clear=False, mismatch=False):
    card = Card(generation, mode, nonfirst=nonfirst, frame=frame)
    access = bytes.fromhex('1011') if nonfirst else (bytes.fromhex('EEEE') if generation == 'Public' else b'\0\0')
    rows = {i: raw_settings(i, mode, count=3 if i == 4 else 2, access=access) for i in range(1, 5)}
    card.metadata(0x6F, returned=bytes(range(1, 5)))
    for file, raw in rows.items():
        card.metadata(0xF5, bytes([file]), raw)
    if discard:
        card.metadata(0xA7)

    def settings(file):
        card.metadata(0xF5, bytes([file]), rows[file])

    def snapshot(file, cmd, header, data):
        card.exchange(cmd, header, returned=data)
        settings(file)

    read_data, write_data = (0xAD, 0x8D) if generation == 'Ev2' else (0xBD, 0x3D)
    read_record, write_record = (0xAB, 0x8B) if generation == 'Ev2' else (0xBB, 0x3B)
    backup = bytearray(crypto.MEMORY)
    settings(1); card.switch()
    snapshot(1, read_data, bytes.fromhex('01000000200000'), bytes(backup))
    card.exchange(write_data, bytes.fromhex('01040000040000'), bytes.fromhex('AABBCCDD'), writing=True)
    backup[4:8] = bytes.fromhex('AABBCCDD')
    if abort:
        card.metadata(0xA7)
        return card.pairs
    settings(1)
    card.exchange(write_data, bytes.fromhex('01060000020000'), bytes.fromhex('EEFF'), writing=True)
    backup[6:8] = bytes.fromhex('EEFF')
    settings(1)  # Matching expected staged bytes: verified no additional write.
    settings(2)
    snapshot(2, 0x6C, b'\2', (10).to_bytes(4, 'little', signed=True))
    card.exchange(0x0C, b'\2', (10).to_bytes(4, 'little'), writing=True)
    settings(2); card.exchange(0xDC, b'\2', (3).to_bytes(4, 'little'), writing=True)
    settings(2); card.exchange(0x1C, b'\2', (2).to_bytes(4, 'little'), writing=True)
    settings(3); snapshot(3, read_record, bytes.fromhex('03000000020000'), LINEAR)
    card.exchange(write_record, bytes.fromhex('03000000040000'), bytes.fromhex('41424344'), writing=True)
    settings(4); snapshot(4, read_record, bytes.fromhex('04000000030000'), CYCLIC)
    card.exchange(write_record, bytes.fromhex('04000000040000'), bytes.fromhex('51525354'), writing=True)
    settings(4); card.exchange(write_record, bytes.fromhex('04000000040000'), bytes.fromhex('61626364'), writing=True)
    settings(3); card.metadata(0xEB, b'\3')
    settings(3); card.exchange(write_record, bytes.fromhex('03000000040000'), bytes.fromhex('71727374'), writing=True)
    if clear:
        settings(4); card.metadata(0xEB, b'\4')
    card.metadata(0xC7, b'\0' if generation == 'Ev2' else b'')
    if mismatch:
        backup[0] ^= 1
    settings(1); snapshot(1, read_data, bytes.fromhex('01000000200000'), bytes(backup))
    settings(2); snapshot(2, 0x6C, b'\2', (19).to_bytes(4, 'little', signed=True))
    rows[3] = raw_settings(3, mode, count=1, access=access)
    settings(3); snapshot(3, read_record, bytes.fromhex('03000000010000'), bytes.fromhex('71727374'))
    rows[4] = raw_settings(4, mode, count=0 if clear else 3, access=access)
    settings(4)
    if not clear:
        card.exchange(read_record, bytes.fromhex('04000000030000'), returned=bytes.fromhex('616263645152535411121314'))
    settings(4)
    return card.pairs


def manage_files(generation, mode):
    card = Card(generation, mode)
    current = []
    for kind in range(5):
        card.metadata(0x45, returned=bytes.fromhex('0F81'))
        card.metadata(0x6F, returned=bytes(current))
        head = bytes([kind, mode, 0, 0])
        if kind < 2:
            header, cmd = head + (32).to_bytes(3, 'little'), 0xCD if kind == 0 else 0xCB
        elif kind == 2:
            header, cmd = head + b''.join(v.to_bytes(4, 'little', signed=True) for v in (-100, 100, 10)) + b'\1', 0xCC
        else:
            header, cmd = head + bytes.fromhex('040000030000'), 0xC1 if kind == 3 else 0xC0
        card.metadata(cmd, header)
        card.metadata(0xF5, bytes([kind]), raw_settings(kind, mode, count=0, allowance=10))
        current.append(kind)
    for kind in reversed(range(5)):
        card.metadata(0x45, returned=bytes.fromhex('0F81'))
        card.metadata(0x6F, returned=bytes(current))
        card.metadata(0xF5, bytes([kind]), raw_settings(kind, mode, count=0, allowance=10))
        card.metadata(0xDF, bytes([kind])); current.remove(kind)
        card.metadata(0x6F, returned=bytes(current))
    return card.pairs


def manage_apps(generation):
    card = Card(generation, aid=bytes(3))
    existing = bytes.fromhex('563412')
    card.metadata(0x45, returned=bytes.fromhex('0F81'))
    card.metadata(0x6A, returned=existing)
    card.metadata(0xCA, crypto.AID + bytes.fromhex('0F81'))
    card.metadata(0x6A, returned=existing + crypto.AID)
    card.metadata(0x45, returned=bytes.fromhex('0F81'))
    card.metadata(0x6A, returned=existing + crypto.AID)
    card.metadata(0xDA, crypto.AID)
    card.metadata(0x6A, returned=existing)
    return card.pairs


vectors = {}
for generation in ['Public', 'Ev1', 'Ev2']:
    for mode, label in [(0, 'Plain'), (1, 'Mac'), (3, 'Full')]:
        if generation == 'Public' and mode:
            continue
        vectors[generation + label + 'Transaction'] = transaction(generation, mode)
        vectors[generation + label + 'Abort'] = transaction(generation, mode, abort=True, discard=True)
        vectors[generation + label + 'ManageFiles'] = manage_files(generation, mode)
    vectors[generation + 'ManageApplications'] = manage_apps(generation)
vectors['Ev2NonFirstTransaction'] = transaction('Ev2', 3, discard=True, nonfirst=True)
vectors['Ev2ChainedTransaction'] = transaction('Ev2', 3, discard=True, frame=16)
vectors['Ev1ChainedTransaction'] = transaction('Ev1', 3, discard=True, frame=16)
vectors['Ev2ClearTransaction'] = transaction('Ev2', 3, clear=True)

# Public quota transcript: exactly 256 changes, then a local refusal and a valid commit.
card = Card('Public', 0)
raw = raw_settings(2, 0, access=bytes.fromhex('EEEE'), limits=(0, 1000), allowance=0, limited=False)
card.metadata(0x6F, returned=b'\2'); card.metadata(0xF5, b'\2', raw)
for n in range(256):
    card.metadata(0xF5, b'\2', raw)
    if n == 0:
        card.exchange(0x6C, b'\2', returned=bytes(4)); card.metadata(0xF5, b'\2', raw)
    card.exchange(0x0C, b'\2', b'\1\0\0\0', writing=True)
card.metadata(0xC7); card.metadata(0xF5, b'\2', raw)
card.exchange(0x6C, b'\2', returned=(256).to_bytes(4, 'little')); card.metadata(0xF5, b'\2', raw)
vectors['PublicMutationQuota'] = card.pairs

# Correctly authenticated metadata for negative management and ownership cases.
card = Card('Ev2', 3); card.metadata(0x6F, returned=b'\5')
card.metadata(0xF5, b'\5', bytes.fromhex('0500FFFF0000'))
vectors['Ev2TransactionMacPreflight'] = card.pairs
card = Card('Ev2', 3); card.metadata(0x6F, returned=b'')
card.pairs.append((crypto.wrap(0xA7, crypto.tag(1, 0xA7, b'')), bytes.fromhex('910C')))
vectors['Ev2AbortNoChanges'] = card.pairs
card = Card('Ev2', 3)
card.pairs[1] = (crypto.wrap(0x71, bytes.fromhex('0100')), card.pairs[1][1])
card.metadata(0x45, returned=bytes.fromhex('0B81'))
vectors['Ev2DeniedManagement'] = card.pairs

# Semantic failures carry valid integrity protection, independently of bit-flip tests.
vectors['Ev2WrongCommittedData'] = transaction('Ev2', 3, mismatch=True)
vectors['Ev1WrongCommittedData'] = transaction('Ev1', 3, mismatch=True)
for label, access, cmd, amount, initial, limits, success in [
    ('CreditWriteOnlyDenied', 'FF F0', 0x0C, 1, 10, (-100, 100), False),
    ('DebitReadOnly', 'FF 0F', 0xDC, 3, 10, (-100, 100), True),
    ('LimitedWriteOnly', 'FF F0', 0x1C, 2, 10, (-100, 100), True),
    ('UpperOverflow', '00 00', 0x0C, 1, 2147483647, (-2147483648, 2147483647), False),
    ('LowerOverflow', '00 00', 0xDC, 1, -2147483648, (-2147483648, 2147483647), False),
    ('LimitedAllowanceExceeded', '00 00', 0x1C, 21, 10, (-100, 100), False),
]:
    card = Card('Ev2', 3)
    raw = raw_settings(2, 3, access=bytes.fromhex(access), limits=limits)
    card.metadata(0x6F, returned=b'\2'); card.metadata(0xF5, b'\2', raw)
    card.metadata(0xF5, b'\2', raw)
    if label != 'CreditWriteOnlyDenied':
        card.exchange(0x6C, b'\2', returned=initial.to_bytes(4, 'little', signed=True))
        card.metadata(0xF5, b'\2', raw)
    if success:
        card.exchange(cmd, b'\2', amount.to_bytes(4, 'little'), writing=True)
        card.metadata(0xC7, b'\0'); card.metadata(0xF5, b'\2', raw)
        value = initial - amount if cmd == 0xDC else initial + amount
        card.exchange(0x6C, b'\2', returned=value.to_bytes(4, 'little', signed=True))
        card.metadata(0xF5, b'\2', raw)
    vectors['Ev2' + label] = card.pairs

card = Card('Ev2', 3)
raw = raw_settings(1, 3, access=bytes.fromhex('FFF0'))
card.metadata(0x6F, returned=b'\1'); card.metadata(0xF5, b'\1', raw)
card.metadata(0xF5, b'\1', raw)
vectors['Ev2BackupReadDenied'] = card.pairs
card = Card('Ev2', 3)
raw = raw_settings(3, 3, count=3)
card.metadata(0x6F, returned=b'\3'); card.metadata(0xF5, b'\3', raw)
card.metadata(0xF5, b'\3', raw)
card.exchange(0xAB, bytes.fromhex('03000000030000'), returned=CYCLIC)
card.metadata(0xF5, b'\3', raw)
vectors['Ev2FullLinearDenied'] = card.pairs

for generation in ['Public', 'Ev1', 'Ev2']:
    card = Card(generation, 0 if generation == 'Public' else 3)
    mode = card.mode
    access = bytes.fromhex('EEEE') if generation == 'Public' else bytes(2)
    card.metadata(0x45, returned=bytes.fromhex('0F81'))
    card.metadata(0x6F, returned=bytes(range(5)))
    for kind in range(5):
        card.metadata(0xF5, bytes([kind]), raw_settings(kind, mode, count=3 if kind == 4 else 2, access=access))
    card.metadata(0xF5, b'\1', raw_settings(1, mode, access=access))
    card.exchange(0xAD if generation == 'Ev2' else 0xBD, bytes.fromhex('01040000040000'), returned=crypto.MEMORY[4:8])
    card.metadata(0xF5, b'\1', raw_settings(1, mode, access=access))
    card.metadata(0xF5, b'\2', raw_settings(2, mode, access=access))
    card.exchange(0x6C, b'\2', returned=(10).to_bytes(4, 'little'))
    card.metadata(0xF5, b'\2', raw_settings(2, mode, access=access))
    card.metadata(0xF5, b'\3', raw_settings(3, mode, access=access))
    card.exchange(0xAB if generation == 'Ev2' else 0xBB, bytes.fromhex('03000000020000'), returned=LINEAR)
    card.metadata(0xF5, b'\3', raw_settings(3, mode, access=access))
    vectors[generation + 'SessionReads'] = card.pairs

card = Card('Ev2', 3)
raw_backup, raw_value = raw_settings(1, 3), raw_settings(2, 3)
card.metadata(0x6F, returned=b'\1\2')
card.metadata(0xF5, b'\1', raw_backup); card.metadata(0xF5, b'\2', raw_value)
card.metadata(0xF5, b'\1', raw_backup)
vectors['Ev2OversizeBackupJournal'] = card.pairs.copy()
card.exchange(0xAD, bytes.fromhex('01000000200000'), returned=crypto.MEMORY)
card.metadata(0xF5, b'\1', raw_backup)
card.exchange(0x8D, bytes.fromhex('01040000040000'), bytes.fromhex('AABBCCDD'), writing=True)
card.metadata(0xF5, b'\2', raw_value)
vectors['Ev2AggregateJournalBound'] = card.pairs

card = Card('Ev2', 3); raw = raw_settings(3, 3, count=2)
card.metadata(0x6F, returned=b'\3'); card.metadata(0xF5, b'\3', raw)
card.metadata(0xF5, b'\3', raw)
card.exchange(0xAB, bytes.fromhex('03000000020000'), returned=LINEAR)
card.metadata(0xF5, b'\3', raw)
vectors['Ev2RecordGrowthBound'] = card.pairs

card = Card('Ev2', 3); raw = raw_settings(2, 3)
card.metadata(0x6F, returned=b'\2'); card.metadata(0xF5, b'\2', raw)
card.metadata(0xF5, b'\2', raw); card.exchange(0x6C, b'\2', returned=(10).to_bytes(4, 'little'))
card.metadata(0xF5, b'\2', raw)
card.exchange(0x1C, b'\2', (2).to_bytes(4, 'little'), writing=True)
card.metadata(0xF5, b'\2', raw)
vectors['Ev2RepeatedLimitedCredit'] = card.pairs

card = Card('Ev2', 3)
card.metadata(0x45, returned=bytes.fromhex('0F81'))
card.metadata(0x6F, returned=b'\5')
card.metadata(0xF5, b'\5', bytes.fromhex('0500FFFF0000'))
vectors['Ev2ExtendedDeleteDenied'] = card.pairs
card = Card('Ev2', 3)
card.metadata(0x45, returned=bytes.fromhex('0F81'))
card.metadata(0x6F, returned=b'')
head = bytes.fromhex('020300009CFFFFFF640000000A00000001')
card.metadata(0xCC, head)
raw = bytearray(raw_settings(2, 3, allowance=10)); raw[-1] = 3
card.metadata(0xF5, b'\2', bytes(raw))
vectors['Ev2UnexpectedValueOptions'] = card.pairs

if __name__ == '__main__':
    text = ['unit Desfire.SessionVectors;', '', '{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}', '', 'interface', '', 'uses Desfire.Vectors;', '']
    for name in vectors:
        text += ['/// <summary>Independent synthetic ' + name + ' transcript.</summary>',
                 '/// <returns>Owned literal command/response pairs; published test credentials only.</returns>',
                 'function ' + name + ': TDesfireWirePairs;']
    text += ['', 'implementation', '']
    for name, pairs in vectors.items():
        text += ['function ' + name + ': TDesfireWirePairs;', 'begin', '  Result:=nil; SetLength(Result,' + str(len(pairs)) + ');']
        for i, (command, response) in enumerate(pairs):
            text += [f"  Result[{i}].Command:='{command.hex().upper()}';", f"  Result[{i}].Response:='{response.hex().upper()}';"]
        text += ['end;', '']
    text += ['end.', '']
    (ROOT / 'tests/contactless/Desfire.SessionVectors.pas').write_text('\n'.join(text))
    print('Generated', len(vectors), 'independent session transcripts.')
