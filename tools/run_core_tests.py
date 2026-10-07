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
               '-Fu' + str(REPO / 'src/core'), '-Fu' + str(REPO / 'src/pcsc'),
               '-Fu' + str(REPO / 'src/eid'),
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
    for project in ('tests/core/CardCore.Tests.dpr', 'tests/core/ProtocolCore.Tests.dpr',
                    'tests/transport/CardTransport.Tests.dpr', 'tests/eid/BelgianEid.Tests.dpr',
                    'tests/eid/Icao.Tests.dpr',
                    'examples/core/InspectApdu.dpr', 'examples/pcsc/InspectReader.dpr',
                    'examples/eid/ReadBelgianEid.dpr'):
        subprocess.run(command + [project], cwd=REPO, check=True)
    suffix = '.exe' if os.name == 'nt' else ''
    for project in ('CardCore.Tests', 'ProtocolCore.Tests', 'CardTransport.Tests', 'BelgianEid.Tests', 'Icao.Tests'):
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
    else:
        print('SKIP: native PC/SC ABI shim requires Linux and GCC.', flush=True)
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
