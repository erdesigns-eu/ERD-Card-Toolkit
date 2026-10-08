#!/usr/bin/env python3
"""Compile and exercise card protocols and injected transport, then validate sources.

Free Pascal provides additional execution evidence. A separate Delphi build
and Help Insight inspection are still required for a supported Delphi release.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

REPO = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fpc', default='fpc', help='Free Pascal compiler executable')
    parser.add_argument('--rtl-dir', type=Path, help='RTL units directory for an extracted compiler')
    args = parser.parse_args()
    compiler = shutil.which(args.fpc)
    if compiler is None:
        parser.error('Free Pascal compiler not found; install FPC or supply --fpc')
    if args.rtl_dir is not None and not (args.rtl_dir / 'system.ppu').is_file():
        parser.error('--rtl-dir must contain system.ppu')
    build = REPO / 'dist/core/fpc'
    build.mkdir(parents=True, exist_ok=True)
    command = [compiler, '-B', '-Mdelphi', '-Cr', '-Co', '-gl', '-gh', '-vewn',
               '-Fu' + str(REPO / 'src/core'), '-Fu' + str(REPO / 'src/crypto'), '-Fu' + str(REPO / 'src/pcsc'),
               '-Fu' + str(REPO / 'src/eid'),
               '-Fu' + str(REPO / 'src/emv'),
               '-Fu' + str(REPO / 'src/magstripe'),
               '-Fu' + str(REPO / 'src/memory'),
               '-Fu' + str(REPO / 'src/input'),
               '-Fu' + str(REPO / 'src/readers'),
               '-Fu' + str(REPO / 'src/contactless'),
               '-Fu' + str(REPO / 'src/design'),
               '-Fu' + str(REPO / 'examples/vcl/shared'),
               '-FU' + str(build), '-FE' + str(build)]
    if args.rtl_dir is not None:
        command.extend(['-n', '-Fu' + str(args.rtl_dir.resolve())])
        # Extracted FPC has no global configuration pointing at GCC's CRT objects.
        cc = shutil.which('gcc') if sys.platform.startswith('linux') else None
        if cc:
            crt = subprocess.run([cc, '-print-file-name=crtbegin.o'], check=True,
                                 capture_output=True, text=True)
            crt_path = Path(crt.stdout.strip())
            if crt_path.is_file():
                command.append('-Fl' + str(crt_path.parent))
    for project in ('examples/readers/InspectTwn4.dpr', 'tests/readers/Twn4.Tests.dpr', 'tests/input/RfidInput.Tests.dpr', 'tests/memory/Sle4404.Tests.dpr', 'tests/memory/MemoryCounter.Tests.dpr', 'tests/memory/MemoryCard.Tests.dpr', 'examples/memory/InspectMemoryCard.dpr', 'examples/memory/InspectSle4404.dpr',
                    'tests/core/CardCore.Tests.dpr', 'tests/core/ProtocolCore.Tests.dpr',
                    'tests/core/CardCatalogs.Tests.dpr',
                    'tests/demos/DemoJob.Tests.dpr',
                    'tests/crypto/EacCrypto.Tests.dpr', 'tests/eid/IcaoDocument.Tests.dpr',
                    'tests/contactless/DesfireManagement.Tests.dpr',
                    'tests/crypto/CardCrypto.Tests.dpr', 'tests/contactless/Desfire.Tests.dpr', 'tests/contactless/DesfireSession.Tests.dpr',
                    'tests/transport/CardTransport.Tests.dpr', 'tests/eid/BelgianEid.Tests.dpr',
                    'tests/eid/Icao.Tests.dpr',
                    'tests/emv/Emv.Tests.dpr',
                    'tests/contactless/Contactless.Tests.dpr',
                    'tests/contactless/RawUid.Tests.dpr',
                    'tests/contactless/Type2Password.Tests.dpr',
                    'tests/contactless/Ndef.Tests.dpr',
                    'tests/contactless/Type4Ndef.Tests.dpr',
                    'tests/contactless/Iso15693Type5.Tests.dpr',
                    'tests/magstripe/MagStripe.Tests.dpr',
                    'tests/magstripe/Msr206.Tests.dpr',
                    'tests/magstripe/Msr2067HL.Tests.dpr',
                    'examples/core/InspectApdu.dpr', 'examples/pcsc/InspectReader.dpr',
                    'examples/eid/ReadIcaoDocument.dpr', 'examples/contactless/AdminDesfire.dpr',
                    'examples/eid/ReadBelgianEid.dpr', 'examples/emv/InspectEmv.dpr',
                    'examples/contactless/InspectContactless.dpr',
                    'examples/contactless/InspectNdef.dpr',
                    'examples/contactless/InspectType4Ndef.dpr',
                    'examples/contactless/InspectType5Ndef.dpr',
                    'examples/contactless/InspectDesfire.dpr', 'examples/contactless/ManageDesfire.dpr',
                    'examples/core/InspectCardTools.dpr',
                    'examples/magstripe/InspectMagStripe.dpr',
                    'examples/magstripe/InspectMsr206.dpr'):
        subprocess.run(command + [project], cwd=REPO, check=True)
    # FPC-only DesignIntf capture: never place this shim on a Delphi library path.
    subprocess.run(command + ['-Fu' + str(REPO / 'tests/design'),
                              'tests/design/Registration.Tests.dpr'], cwd=REPO, check=True)
    suffix = '.exe' if os.name == 'nt' else ''
    for project in ('Twn4.Tests', 'RfidInput.Tests', 'Sle4404.Tests', 'MemoryCounter.Tests', 'MemoryCard.Tests', 'DemoJob.Tests', 'Registration.Tests', 'EacCrypto.Tests', 'IcaoDocument.Tests', 'DesfireManagement.Tests', 'CardCore.Tests', 'ProtocolCore.Tests', 'CardCatalogs.Tests', 'CardCrypto.Tests', 'Desfire.Tests', 'DesfireSession.Tests', 'CardTransport.Tests', 'BelgianEid.Tests', 'Icao.Tests', 'Emv.Tests', 'Contactless.Tests', 'RawUid.Tests', 'Type2Password.Tests', 'Ndef.Tests', 'Type4Ndef.Tests', 'Iso15693Type5.Tests', 'MagStripe.Tests', 'Msr206.Tests', 'Msr2067HL.Tests'):
        result = subprocess.run([str(build / (project + suffix))], cwd=REPO,
                                capture_output=True, text=True)
        print(result.stdout, end='', flush=True)
        if result.stderr:
            print(result.stderr, file=sys.stderr, end='')
        result.check_returncode()
        if re.search(r'\b[1-9][0-9]* unfreed memory blocks', result.stderr):
            raise RuntimeError(project + ' leaked memory according to FPC heaptrc')
    # Exercise the Windows adapter's actual native-call branches against an isolated
    # C shim on Linux x86-64. This tests layout/arguments, not Windows calling conventions.
    if sys.platform.startswith('linux') and shutil.which('gcc'):
        native_build = REPO / 'dist/core/native'
        native_build.mkdir(parents=True, exist_ok=True)
        gcc = shutil.which('gcc')
        subprocess.run([gcc, '-std=c11', '-Wall', '-Wextra', '-Werror', '-shared', '-fPIC',
                        'tests/transport/native/winscard_stub.c', '-o',
                        str(native_build / 'libwinscard.dll.so')], cwd=REPO, check=True)
        native_command = [arg for arg in command if not arg.startswith(('-FU', '-FE'))]
        native_command.extend(['-dMSWINDOWS', '-Fl' + str(native_build),
                               '-FU' + str(native_build), '-FE' + str(native_build),
                               'tests/transport/NativePcsc.Tests.dpr'])
        subprocess.run(native_command, cwd=REPO, check=True)
        native_env = os.environ.copy()
        native_env['LD_LIBRARY_PATH'] = str(native_build) + os.pathsep + native_env.get('LD_LIBRARY_PATH', '')
        native = subprocess.run([str(native_build / 'NativePcsc.Tests')], cwd=REPO,
                                env=native_env, capture_output=True, text=True)
        print(native.stdout, end='', flush=True)
        if native.stderr:
            print(native.stderr, file=sys.stderr, end='')
        native.check_returncode()
        if re.search(r'\b[1-9][0-9]* unfreed memory blocks', native.stderr):
            raise RuntimeError('Native PC/SC shim test leaked memory')
        serial_build = REPO / 'dist/core/serial-native'
        serial_build.mkdir(parents=True, exist_ok=True)
        subprocess.run([gcc, '-std=c11', '-Wall', '-Wextra', '-Werror', '-shared', '-fPIC',
                        'tests/magstripe/native/kernel32_serial_stub.c', '-o',
                        str(serial_build / 'libkernel32.dll.so')], cwd=REPO, check=True)
        serial_command = [arg for arg in command if not arg.startswith(('-FU', '-FE'))]
        serial_command.extend(['-dMSWINDOWS', '-Fl' + str(serial_build),
                               '-FU' + str(serial_build), '-FE' + str(serial_build),
                               'tests/magstripe/NativeSerial.Tests.dpr'])
        subprocess.run(serial_command, cwd=REPO, check=True)
        serial_env = os.environ.copy()
        serial_env['LD_LIBRARY_PATH'] = str(serial_build) + os.pathsep + serial_env.get('LD_LIBRARY_PATH', '')
        serial_result = subprocess.run([str(serial_build / 'NativeSerial.Tests')], cwd=REPO,
                                       env=serial_env, capture_output=True, text=True)
        print(serial_result.stdout, end='', flush=True)
        if serial_result.stderr:
            print(serial_result.stderr, file=sys.stderr, end='')
        serial_result.check_returncode()
        if re.search(r'\b[1-9][0-9]* unfreed memory blocks', serial_result.stderr):
            raise RuntimeError('Native serial shim test leaked memory')
        # Exercise actual Windows CNG imports against an OpenSSL-backed Linux ABI shim.
        # This checks native buffers/ownership, not Windows calling conventions or OS policy.
        crypto_build = REPO / 'dist/core/crypto-native'
        crypto_build.mkdir(parents=True, exist_ok=True)
        subprocess.run([gcc, '-std=c11', '-Wall', '-Wextra', '-Werror', '-shared', '-fPIC',
                        'tests/crypto/native/bcrypt_stub.c', '-lcrypto', '-o',
                        str(crypto_build / 'libbcrypt.dll.so')], cwd=REPO, check=True)
        crypto_command = [arg for arg in command if not arg.startswith(('-FU', '-FE'))]
        crypto_command.extend(['-dMSWINDOWS', '-Fl' + str(crypto_build),
                               '-FU' + str(crypto_build), '-FE' + str(crypto_build)])
        crypto_env = os.environ.copy()
        crypto_env['LD_LIBRARY_PATH'] = str(crypto_build) + os.pathsep + crypto_env.get('LD_LIBRARY_PATH', '')
        for project in ('tests/crypto/NativeCrypto.Tests.dpr', 'tests/crypto/CardCrypto.Tests.dpr',
                        'tests/contactless/Desfire.Tests.dpr', 'tests/contactless/DesfireSession.Tests.dpr',
                        'tests/contactless/DesfireManagement.Tests.dpr'):
            subprocess.run(crypto_command + [project], cwd=REPO, check=True)
            native = subprocess.run([str(crypto_build / Path(project).stem)], cwd=REPO,
                                    env=crypto_env, capture_output=True, text=True)
            print(native.stdout, end='', flush=True)
            if native.stderr:
                print(native.stderr, file=sys.stderr, end='')
            native.check_returncode()
            if re.search(r'\b[1-9][0-9]* unfreed memory blocks', native.stderr):
                raise RuntimeError('Native CNG test leaked memory')
    else:
        print('SKIP: native PC/SC and serial ABI shims requires Linux and GCC.', flush=True)
    twn4 = str(build / ('InspectTwn4' + suffix))
    for argv, expected in [(['--help'], 'TWN4 PRS ASCII / USB-CDC'),
                           (['--frame', '0005'], '303030350D'),
                           (['--frame', '0005', '--crc'], '30303035313541370D')]:
        result = subprocess.run([twn4] + argv, capture_output=True, text=True, check=True)
        if expected not in result.stdout:
            raise RuntimeError('TWN4 offline example output mismatch')
    for argv in [[], ['--unknown'], ['--frame', '00'], ['--port', 'COM17', '--frame', '0005']]:
        result = subprocess.run([twn4] + argv, capture_output=True, text=True)
        if result.returncode == 0:
            raise RuntimeError('TWN4 example accepted invalid arguments')
    example = str(build / ('InspectApdu' + suffix))
    valid = subprocess.run([example, '0000000002AABB00'], capture_output=True, text=True, check=True)
    if 'Data bytes: 2' not in valid.stdout or 'Le: 256' not in valid.stdout:
        raise RuntimeError('Example did not decode the expected command data and Le')
    invalid = subprocess.run([example, '0000000002AA'], capture_output=True, text=True)
    if invalid.returncode != 1 or 'EApduFormatError' not in invalid.stdout:
        raise RuntimeError('Example did not reject a truncated command')
    print('PASS: console example accepts a valid command and rejects truncated data.', flush=True)
    reader_help = subprocess.run([str(build / ('InspectReader' + suffix)), '--help'],
                                 capture_output=True, text=True, check=True)
    if 'Usage: InspectReader' not in reader_help.stdout:
        raise RuntimeError('Reader example did not show its hardware-free help')
    eid_help = subprocess.run([str(build / ('ReadBelgianEid' + suffix)), '--help'],
                             capture_output=True, text=True, check=True)
    if 'Usage: ReadBelgianEid' not in eid_help.stdout:
        raise RuntimeError('eID example did not show its hardware-free help')
    emv_help = subprocess.run([str(build / ('InspectEmv' + suffix)), '--help'],
                             capture_output=True, text=True, check=True)
    if 'Usage: InspectEmv' not in emv_help.stdout:
        raise RuntimeError('EMV example did not show its hardware-free help')
    contactless_help = subprocess.run([str(build / ('InspectContactless' + suffix)), '--help'],
                                     capture_output=True, text=True, check=True)
    if 'Usage: InspectContactless' not in contactless_help.stdout:
        raise RuntimeError('Contactless example did not show its hardware-free help')
    ndef_example = str(build / ('InspectNdef' + suffix))
    ndef_help = subprocess.run([ndef_example, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectNdef' not in ndef_help.stdout:
        raise RuntimeError('NDEF example did not show its hardware-free help')
    ndef_valid = subprocess.run([ndef_example, 'D101055402656E4869'],
                                capture_output=True, text=True, check=True)
    if 'Records: 1' not in ndef_valid.stdout or 'TNF=1 TypeBytes=1 IdBytes=0 PayloadBytes=5' not in ndef_valid.stdout:
        raise RuntimeError('NDEF example did not decode the independent Text RTD vector')
    ndef_invalid = subprocess.run([ndef_example, 'D101055402656E48'], capture_output=True, text=True)
    if ndef_invalid.returncode != 1 or 'ENdefError' not in ndef_invalid.stdout:
        raise RuntimeError('NDEF example did not reject truncated payload')
    print('PASS: NDEF console example help and valid/invalid message cases.', flush=True)
    type4_example = str(build / ('InspectType4Ndef' + suffix))
    type4_help = subprocess.run([type4_example, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectType4Ndef' not in type4_help.stdout:
        raise RuntimeError('Type 4 example did not show its hardware-free help')
    type4_cc = '000F20003A00340406E10401000000'
    type4_valid = subprocess.run([type4_example, '--cc-hex', type4_cc],
                                 capture_output=True, text=True, check=True)
    if 'MLe: 58 MLc: 52' not in type4_valid.stdout or 'NDEF files: 1' not in type4_valid.stdout:
        raise RuntimeError('Type 4 example did not decode the independent CC fixture')
    type4_invalid = subprocess.run([type4_example, '--cc-hex', type4_cc[:-2]],
                                   capture_output=True, text=True)
    if type4_invalid.returncode != 1 or 'EType4NdefError' not in type4_invalid.stdout:
        raise RuntimeError('Type 4 example did not reject truncated CC')
    print('PASS: Type 4 console example help and valid/invalid CC cases.', flush=True)
    magstripe = str(build / ('InspectMagStripe' + suffix))
    mag_help = subprocess.run([magstripe, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectMagStripe' not in mag_help.stdout:
        raise RuntimeError('Magstripe example did not show hardware-free help')
    mag_frame = subprocess.run([magstripe, '--track', '1', '--frame', '%AT3?'],
                               capture_output=True, text=True, check=True)
    if 'Frame bits: 42 LRC symbol: 1C' not in mag_frame.stdout or 'AT3' in mag_frame.stdout:
        raise RuntimeError('Magstripe example did not summarize the published Track 1 vector')
    mag_bits = subprocess.run([magstripe, '--track', '2', '--bits',
                              '110101000001000110011111100100'],
                              capture_output=True, text=True, check=True)
    if 'Input parity and LRC: verified' not in mag_bits.stdout or 'Frame bits: 30 LRC symbol: 04' not in mag_bits.stdout:
        raise RuntimeError('Magstripe example did not validate the published numeric vector')
    mag_bad = subprocess.run([magstripe, '--track', '2', '--bits',
                             '010101000001000110011111100100'], capture_output=True, text=True)
    if mag_bad.returncode != 1 or 'EMagStripeFormatError' not in mag_bad.stdout:
        raise RuntimeError('Magstripe example did not reject corrupted parity')
    print('PASS: magstripe console help, text/bit vectors and corrupt parity.', flush=True)
    msr_example = str(build / ('InspectMsr206' + suffix))
    msr_help = subprocess.run([msr_example, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectMsr206' not in msr_help.stdout:
        raise RuntimeError('MSR206 example did not show hardware-free help')
    msr_fixture = '1B731B012530313F1B023B32333F1B033B34353F3F1C1B30'
    msr_valid = subprocess.run([msr_example, '--frame-hex', msr_fixture],
                               capture_output=True, text=True, check=True)
    if any('Track ' + str(track) + ' payload characters: 2' not in msr_valid.stdout for track in (1, 2, 3)):
        raise RuntimeError('MSR206 example did not decode the published frame')
    msr_bad = subprocess.run([msr_example, '--frame-hex', msr_fixture[:-2] + '31'],
                             capture_output=True, text=True)
    if msr_bad.returncode != 1 or 'EMagStripeError' not in msr_bad.stdout:
        raise RuntimeError('MSR206 example did not reject device-reported failure')
    print('PASS: MSR206 console help, published frame and failed status.', flush=True)
    type5 = str(build / ('InspectType5Ndef' + suffix))
    checked = subprocess.run([type5, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectType5Ndef' not in checked.stdout:
        raise RuntimeError('Type 5 example did not show hardware-free help')
    cc_args = ['--cc-hex', 'E1403F00', '--blocks', '128', '--block-size', '4', '--address', '8']
    checked = subprocess.run([type5] + cc_args, capture_output=True, text=True, check=True)
    if 'CC bytes: 4 data-area bytes: 504' not in checked.stdout:
        raise RuntimeError('Type 5 example did not decode AN4911 CC/geometry')
    cc_args[1] = 'E1404000'
    checked = subprocess.run([type5] + cc_args, capture_output=True, text=True)
    if checked.returncode != 1 or 'EType5NdefError' not in checked.stdout:
        raise RuntimeError('Type 5 example did not refuse over-capacity MLEN')
    catalog = str(build / ('InspectCardTools' + suffix))
    cases = [(['--help'], 'Usage: InspectCardTools'),
             (['--atr', '3B8F8001804F0CA0000003060B00350000000056'], 'ATR hints: 2'),
             (['--atr', '3B00'], 'ATR hints: 0'),
             (['--tag', '9F26'], 'Application Cryptogram'),
             (['--tag', 'DF0101'], 'Unknown tag')]
    for arguments, expected in cases:
        checked = subprocess.run([catalog] + arguments, capture_output=True, text=True, check=True)
        if expected not in checked.stdout:
            raise RuntimeError('Catalog example did not report expected diagnostic metadata')
    checked = subprocess.run([catalog, '--atr', '3B8F8001804F0CA0000003060B00350000000057'],
                             capture_output=True, text=True)
    if checked.returncode != 1 or 'EAtrFormatError' not in checked.stdout:
        raise RuntimeError('Catalog example accepted invalid ATR TCK')
    print('PASS: Type 5 CC bounds and source-attributed ATR/EMV catalog console cases.', flush=True)
    desfire = str(build / ('InspectDesfire' + suffix))
    inspected = subprocess.run([desfire, '--help'], capture_output=True, text=True, check=True)
    if 'Usage: InspectDesfire' not in inspected.stdout:
        raise RuntimeError('DESFire example did not show hardware-free help')
    inspected = subprocess.run([desfire, '--settings-hex', '00031234332211', '--file', '0'],
                               capture_output=True, text=True, check=True)
    if 'Data bytes: 1122867' not in inspected.stdout or 'communication: 2' not in inspected.stdout:
        raise RuntimeError('DESFire example did not inspect literal settings')
    inspected = subprocess.run([desfire, '--settings-hex', '000312343322', '--file', '0'],
                               capture_output=True, text=True)
    if inspected.returncode != 1 or 'EDesfireError' not in inspected.stdout:
        raise RuntimeError('DESFire example accepted truncated settings')
    print('PASS: DESFire console help and exact/truncated settings cases.', flush=True)

    manage = str(build / ('ManageDesfire' + suffix))
    for arguments, expected in [(['--help'], 'Usage: ManageDesfire'),
                                (['--plan'], 'Demo files: 5')]:
        inspected = subprocess.run([manage] + arguments, capture_output=True, text=True, check=True)
        if expected not in inspected.stdout:
            raise RuntimeError('DESFire management example did not show its offline mode')
    inspected = subprocess.run([manage, '--unknown'], capture_output=True, text=True)
    if inspected.returncode != 1 or 'EDesfireError' not in inspected.stdout:
        raise RuntimeError('DESFire management example did not reject invalid arguments')
    print('PASS: DESFire management offline help/plan and invalid arguments.', flush=True)
    sle4404 = str(build / ('InspectSle4404' + suffix))
    for bad_args in (['--window', '0'],
                     ['--window', '52', '--reader', 'must not connect', '--dialect', 'acr39'],
                     ['--window', '52', '--reader', 'must not connect', '--dialect', 'acr38-ccid',
                      '--address', '51', '--count', '2']):
        invalid = subprocess.run([sle4404] + bad_args, capture_output=True, text=True)
        if invalid.returncode != 1 or 'EMemoryCardError' not in invalid.stdout:
            raise RuntimeError('SLE4404 example did not reject invalid geometry/dialect before hardware')
    for project, cases in (
        ('InspectSle4404', [(['--help'], 'InspectSle4404 --window'),
                            (['--window', '52'], 'Caller-declared readable bytes: 52')]),
        ('InspectMemoryCard', [(['--help'], 'Usage: InspectMemoryCard'),
                               (['--model', 'sle4442'], 'Main bytes: 256 PIN bytes: 3'),
                               (['--model', 'sle4428'], 'Main bytes: 1024 PIN bytes: 2'),
                               (['--model', 'i2c1024kbit'], 'Main bytes: 131072 PIN bytes: 0')]),
        ('AdminDesfire', [(['--help'], 'Usage: AdminDesfire'), (['--plan'], 'AES administration:')]),
        ('ReadIcaoDocument', [(['--help'], 'Usage: ReadIcaoDocument'),
                             (['--cardaccess', '31143012060A04007F0007020204020202010202010D'], 'supported: TRUE')])):
        for arguments, expected in cases:
            checked = subprocess.run([str(build / (project + suffix))] + arguments,
                                     capture_output=True, text=True, check=True)
            if expected not in checked.stdout:
                raise RuntimeError(project + ' failed its offline inspection mode')
        checked = subprocess.run([str(build / (project + suffix)), '--unknown'],
                                 capture_output=True, text=True)
        if checked.returncode != 1:
            raise RuntimeError(project + ' accepted unknown hardware arguments')
    print('PASS: AES administration and ICAO document offline help/plan/CardAccess modes.', flush=True)
    subprocess.run([sys.executable, 'tools/check_distribution.py'], cwd=REPO, check=True)
    subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests/tools', '-v'],
                   cwd=REPO, check=True)
    subprocess.run([sys.executable, 'tools/pascalcheck/run.py', '--profile', 'core',
                    '--source-root', 'src', '--source-root', 'tests',
                    '--source-root', 'examples', '-v'], cwd=REPO, check=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
