#!/usr/bin/env python3
"""Compile and exercise the portable core, then run its validation readers.

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
               '-Fu' + str(REPO / 'src/core'), '-FU' + str(build), '-FE' + str(build)]
    if args.rtl_dir is not None:
        command.extend(['-n', '-Fu' + str(args.rtl_dir.resolve())])
    for project in ('tests/core/CardCore.Tests.dpr', 'tests/core/ProtocolCore.Tests.dpr',
                    'examples/core/InspectApdu.dpr'):
        subprocess.run(command + [project], cwd=REPO, check=True)
    suffix = '.exe' if os.name == 'nt' else ''
    for project in ('CardCore.Tests', 'ProtocolCore.Tests'):
        result = subprocess.run([str(build / (project + suffix))], cwd=REPO,
                                capture_output=True, text=True)
        print(result.stdout, end='', flush=True)
        if result.stderr:
            print(result.stderr, file=sys.stderr, end='')
        result.check_returncode()
        if re.search(r'\b[1-9][0-9]* unfreed memory blocks', result.stderr):
            raise RuntimeError(project + ' leaked memory according to FPC heaptrc')
    example = str(build / ('InspectApdu' + suffix))
    valid = subprocess.run([example, '0000000002AABB00'], capture_output=True, text=True, check=True)
    if 'Data bytes: 2' not in valid.stdout or 'Le: 256' not in valid.stdout:
        raise RuntimeError('Example did not decode the expected command data and Le')
    invalid = subprocess.run([example, '0000000002AA'], capture_output=True, text=True)
    if invalid.returncode != 1 or 'EApduFormatError' not in invalid.stdout:
        raise RuntimeError('Example did not reject a truncated command')
    print('PASS: console example accepts a valid command and rejects truncated data.', flush=True)
    subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests/tools', '-v'],
                   cwd=REPO, check=True)
    subprocess.run([sys.executable, 'tools/pascalcheck/run.py', '--profile', 'core',
                    '--source-root', 'src/core', '--source-root', 'tests/core',
                    '--source-root', 'examples/core', '-v'], cwd=REPO, check=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
