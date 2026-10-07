#!/usr/bin/env python3
"""Run every checker and report what each one found.

    python tools/pascalcheck/run.py            # one line per checker
    python tools/pascalcheck/run.py -v         # plus the findings themselves
    python tools/pascalcheck/run.py capture    # only checkers matching a name

Exits non-zero when anything was found, so it can stand in a build step.
"""
import argparse, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from common import ROOT, pas_files

# These readers use common.pas_files() and apply to standalone RTL units.
# UI/catalog/project-layout readers remain available through the default suite.
CORE_CHECKERS = {
    'arraylow', 'assigned', 'blocks', 'bracecomment', 'capture', 'caselabel',
    'declorder', 'dup', 'fieldorder', 'forvar', 'iface', 'impl', 'jsoncast',
    'loopcapture', 'loopvar', 'nestedcapture', 'reservedname', 'sections',
    'varargtype', 'varparam', 'xmldoc',
}
# A checker prints a heading, its findings, then a total. These are the shapes
# that total comes in.
TOTAL = re.compile(r'^\s*(?:total(?: distinct)?|mismatches):\s*(\d+)\s*$', re.M)
INLINE = re.compile(r'\bmismatches:\s*(\d+)\s*$|^--\s*(\d+) finding', re.M)


def count(output):
    """How many findings the output reports, or None when it says nothing."""
    hits = TOTAL.findall(output)
    if not hits:
        hits = [h for pair in INLINE.findall(output) for h in pair if h]
    if not hits:
        # A checker that printed nothing at all found nothing at all.
        return 0 if not output.strip() else None
    return sum(int(h) for h in hits)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('pattern', nargs='?', default='',
                    help='only run checkers whose name contains this')
    ap.add_argument('-v', '--verbose', action='store_true',
                    help='print the findings, not just the counts')
    ap.add_argument('--profile', choices=('all', 'core'), default='core',
                    help='core (default) runs source-aware readers; all includes legacy layout readers')
    ap.add_argument('--source-root', action='append', default=[], metavar='PATH',
                    help='file or directory to check; repeat for multiple inputs')
    args = ap.parse_args()

    if args.source_root and args.profile != 'core':
        ap.error('explicit source roots require --profile core; other readers may use fixed paths')
    if args.source_root:
        os.environ['PASCALCHECK_SOURCE_ROOTS'] = json.dumps(args.source_root)
    try:
        inputs = sorted(pas_files())
    except (ValueError, OSError) as error:
        ap.error(str(error))
    if not inputs:
        print('ERROR: no Pascal source files selected')
        return 2
    print('Selected %d Pascal source file(s):' % len(inputs))
    for path in inputs:
        print('  ' + os.path.relpath(path, ROOT))

    names = sorted(f for f in os.listdir(HERE)
                   if f.startswith('check_') and f.endswith('.py')
                   and args.pattern in f
                   and (args.profile != 'core' or f[6:-3] in CORE_CHECKERS))
    if not names:
        print('no checker matches %r' % args.pattern)
        return 2

    found = {}
    unclear = []
    for name in names:
        r = subprocess.run([sys.executable, os.path.join(HERE, name)],
                           capture_output=True, text=True, cwd=ROOT)
        out = (r.stdout or '') + (r.stderr or '')
        label = name[len('check_'):-len('.py')]
        if r.returncode != 0 or any(marker in out for marker in
                                   ('PARSE FAIL', 'SYMFAIL', 'Traceback (most recent call last)')):
            print('%-18s ERROR' % label)
            print(out.rstrip())
            unclear.append(label)
            continue
        n = count(out)
        if n is None:
            print('%-18s ?  (no total line)' % label)
            unclear.append(label)
        elif n:
            print('%-18s %d' % (label, n))
            found[label] = n
        else:
            print('%-18s .' % label)
        if args.verbose and (n or n is None):
            print(out.rstrip())
            print()

    print()
    if found:
        print('%d finding(s) across %d checker(s): %s' %
              (sum(found.values()), len(found), ', '.join(sorted(found))))
    else:
        print('clean across %d checkers' % len(names))
    if unclear:
        print('could not read a total from: %s' % ', '.join(unclear))
    return 1 if found or unclear else 0


if __name__ == '__main__':
    sys.exit(main())
