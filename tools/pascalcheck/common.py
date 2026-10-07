import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paslex import strip_code, tokens, linemap, lineof

def find_root(start=None):
    """The repository root, found by walking up from this file.

    Checkers are run from anywhere - the IDE's Tools menu, a shell in any
    directory, a build step - so the root is worked out rather than assumed.
    Set REPO to point the suite at a different checkout.
    """
    env = os.environ.get('REPO')
    if env:
        return os.path.abspath(env)
    here = os.path.dirname(os.path.abspath(start or __file__))
    while True:
        # .git, or the shape of the checkout itself. Not "contains a .dpr":
        # tools/ holds two of those and would be mistaken for the root.
        if (os.path.isdir(os.path.join(here, '.git')) or
                (os.path.isdir(os.path.join(here, 'units')) and
                 os.path.isdir(os.path.join(here, 'forms')))):
            return here
        up = os.path.dirname(here)
        if up == here:
            # Nothing recognisable above us: fall back to two levels up,
            # which is where tools/pascalcheck sits in this repository.
            return os.path.dirname(os.path.dirname(
                os.path.dirname(os.path.abspath(__file__))))
        here = up

ROOT = find_root()
SKIP = ('Virtual-TreeView-master', '__history', 'Win32', '/typescript/')

def source_roots():
    """Explicit inputs supplied by run.py, or None for the legacy discovery."""
    value = os.environ.get('PASCALCHECK_SOURCE_ROOTS')
    if value is None:
        return None
    paths = json.loads(value)
    if not isinstance(paths, list) or not paths or not all(isinstance(p, str) for p in paths):
        raise ValueError('PASCALCHECK_SOURCE_ROOTS must be a nonempty JSON array of paths')
    resolved = [os.path.abspath(os.path.join(ROOT, p)) for p in paths]
    for path in resolved:
        if not os.path.exists(path):
            raise ValueError('source root does not exist: ' + path)
    return resolved

def selected_files(extensions):
    """Walk explicitly selected paths once, excluding generated/history files."""
    seen = set()
    for base in source_roots() or []:
        if os.path.isfile(base):
            candidates = [base]
        else:
            candidates = []
            for dp, dn, fn in os.walk(base):
                dn[:] = sorted(d for d in dn if d not in ('__history', '__pycache__', 'Win32', 'Win64', '.git', 'dist'))
                candidates.extend(os.path.join(dp, f) for f in sorted(fn))
        for path in candidates:
            identity = os.path.realpath(path)
            if path.lower().endswith(extensions) and identity not in seen:
                seen.add(identity)
                yield path

def pas_files(include_components=True):
    if source_roots() is not None:
        yield from selected_files(('.pas', '.dpr'))
        return
    seen = set()
    bases = ['units', 'forms', 'cli', 'tools', 'build', 'shell-extension',
             'workbench', 'tests', 'src', 'examples']
    if include_components: bases.append('components')
    for base in bases:
        d = os.path.join(ROOT, base)
        if not os.path.isdir(d): continue
        for dp, dn, fn in os.walk(d):
            if any(s.strip('/') in dp for s in SKIP): continue
            for f in fn:
                if f.lower().endswith(('.pas', '.dpr')):
                    p = os.path.join(dp, f)
                    if p not in seen: seen.add(p); yield p
    for f in sorted(os.listdir(ROOT)):
        if f.lower().endswith('.dpr'):
            p = os.path.join(ROOT, f)
            if p not in seen: seen.add(p); yield p

DFM_BASES = ('forms', 'components', 'units', 'workbench', 'shell-extension')

def dfm_files(bases=DFM_BASES):
    """Every form file in the checkout, in one place.

    Each DFM checker used to name its own folders, and a folder added to the
    project was then remembered in none of them: the workbench shipped two
    forms and a handful of frames that nothing here had ever read. Naming
    them once means a new folder is added once.
    """
    if source_roots() is not None:
        yield from selected_files(('.dfm',))
        return
    seen = set()
    for base in bases:
        d = os.path.join(ROOT, base)
        if not os.path.isdir(d):
            continue
        for dp, dn, fn in os.walk(d):
            if any(s.strip('/') in dp for s in SKIP):
                continue
            for f in sorted(fn):
                if f.lower().endswith('.dfm'):
                    p = os.path.join(dp, f)
                    if p not in seen:
                        seen.add(p)
                        yield p

def load(path):
    with open(path, encoding='utf-8', errors='replace') as source:
        src = source.read()
    clean, directives = strip_code(src)
    return src, clean, directives, linemap(src), list(tokens(clean))
