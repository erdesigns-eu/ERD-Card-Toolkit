#!/usr/bin/env python3
"""Check package ownership, MSBuild references and VCL DFM bindings without Delphi.

These bounded readers validate the shipped text formats. They do not resolve VCL
property types, execute MSBuild, render forms or replace the Delphi compiler/IDE.
"""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[1]
NS = {'m': 'http://schemas.microsoft.com/developer/msbuild/2003'}


def local_path(parent, reference):
    return parent / reference.replace('\\', '/')


def check_project(path):
    errors = []
    try:
        tree = ET.parse(path)
    except (ET.ParseError, OSError) as error:
        return [f'{path.name}: invalid MSBuild XML: {error}']
    root = tree.getroot()
    if root.tag != '{' + NS['m'] + '}Project':
        errors.append(f'{path.name}: MSBuild namespace missing')
    if path.suffix == '.groupproj':
        refs = root.findall('.//m:Projects', NS)
        if not refs:
            errors.append(f'{path.name}: empty project group')
        for ref in refs:
            if not local_path(path.parent, ref.get('Include', '')).is_file():
                errors.append(f'{path.name}: missing group project {ref.get("Include")}')
        return errors
    main = root.findtext('.//m:MainSource', namespaces=NS)
    if not main or not local_path(path.parent, main).is_file():
        errors.append(f'{path.name}: missing MainSource')
    for ref in root.findall('.//m:DCCReference', NS):
        source = local_path(path.parent, ref.get('Include', ''))
        if not source.is_file():
            errors.append(f'{path.name}: missing DCCReference {ref.get("Include")}')
        if ref.find('m:Form', NS) is not None and not source.with_suffix('.dfm').is_file():
            errors.append(f'{path.name}: designer form resource missing')
    unit_paths = root.findtext('.//m:DCC_UnitSearchPath', default='', namespaces=NS)
    for ref in unit_paths.split(';'):
        if ref and '$(' not in ref and not local_path(path.parent, ref).is_dir():
            errors.append(f'{path.name}: missing unit search directory {ref}')
    for prop in ('DCC_DcuOutput', 'DCC_ExeOutput', 'DCC_BplOutput', 'DCC_DcpOutput'):
        dest = root.findtext('.//m:' + prop, default='', namespaces=NS)
        if '$(Platform)' not in dest or '$(Config)' not in dest:
            errors.append(f'{path.name}: {prop} must isolate Platform and Config')
    for prop in ('DCC_RangeChecking', 'DCC_OverflowChecking', 'DCC_GenerateDocumentation'):
        if root.findtext('.//m:' + prop, default='', namespaces=NS) != 'true':
            errors.append(f'{path.name}: {prop} is not enabled')
    imports = root.findall('m:Import', NS)
    if not any(ref.get('Project') == '$(BDS)\\Bin\\CodeGear.Delphi.Targets' for ref in imports):
        errors.append(f'{path.name}: Delphi MSBuild targets missing')
    return errors


def check_form(path):
    errors = []
    source = path.with_suffix('.pas')
    if not source.is_file():
        return [f'{path.name}: form Pascal source missing']
    pas = source.read_text(encoding='utf-8')
    if '{$R *.dfm}' not in pas:
        errors.append(f'{path.name}: form resource directive missing')
    stack, seen = [], set()
    for line in path.read_text(encoding='utf-8').splitlines():
        obj = re.fullmatch(r'\s*object\s+(\w+):\s*(\w+)\s*', line)
        if obj:
            name, kind = obj.groups()
            if name.lower() in seen:
                errors.append(f'{path.name}: duplicate DFM object {name}')
            seen.add(name.lower())
            if not stack:
                if not re.search(r'\b' + re.escape(kind) + r'\s*=\s*class\(', pas):
                    errors.append(f'{path.name}: root class {kind} missing')
            elif not re.search(r'\b' + re.escape(name) + r'\s*:\s*' + re.escape(kind) + r'\s*;', pas):
                errors.append(f'{path.name}: field/type {name}: {kind} missing')
            stack.append(name)
        elif re.fullmatch(r'\s*end\s*', line):
            if not stack:
                errors.append(f'{path.name}: unmatched DFM end')
            else:
                stack.pop()
        event = re.fullmatch(r'\s*(On\w+)\s*=\s*(\w+)\s*', line)
        if event:
            handler = event.group(2)
            # The shipped demos use only TNotifyEvent bindings; no event-type inference.
            signature = r'procedure\s+' + re.escape(handler) + r'\(Sender:\s*TObject\);'
            if not re.search(signature, pas, re.I):
                errors.append(f'{path.name}: missing notify handler {handler}')
            if not re.search(r'procedure\s+\w+\.' + re.escape(handler) + r'\(Sender:\s*TObject\);', pas, re.I):
                errors.append(f'{path.name}: handler implementation {handler} missing')
    if stack:
        errors.append(f'{path.name}: unclosed DFM objects')
    return errors


def check_program(path):
    errors = []
    source = path.read_text(encoding='utf-8')
    for ref in re.findall(r"\bin\s+'([^']+)'", source, re.I):
        if not local_path(path.parent, ref).is_file():
            errors.append(f'{path.name}: missing project unit {ref}')
    create = re.search(r'Application\.CreateForm\((\w+),\s*(\w+)\)', source)
    main = path.with_name(path.stem + '.Main.pas')
    if not create or not main.is_file():
        errors.append(f'{path.name}: main form creation/source missing')
    elif not re.search(r'\b' + create.group(2) + r'\s*:\s*' + create.group(1) + r'\s*;', main.read_text()):
        errors.append(f'{path.name}: CreateForm class/global differ')
    return errors


def check_packages(root):
    errors, owners, deps = [], {}, {}
    for path in sorted((root / 'packages').rglob('*.dpk')):
        source = path.read_text(encoding='utf-8')
        requires = re.search(r'\brequires\s+(.+?);', source, re.I | re.S)
        deps[path.stem] = re.findall(r'\b\w+\b', requires.group(1)) if requires else []
        design = path.parent.name == 'design'
        if ('{$DESIGNONLY}' if design else '{$RUNONLY}') not in source:
            errors.append(f'{path.name}: package role directive missing')
        if not design and any(d.lower() in ('vcl', 'designide', 'erdcarddesign') for d in deps[path.stem]):
            errors.append(f'{path.name}: runtime depends on VCL/design-time code')
        for unit, ref in re.findall(r"(ERD\.[\w.]+)\s+in\s+'([^']+)'", source):
            if not local_path(path.parent, ref).is_file():
                errors.append(f'{path.name}: missing contained source {ref}')
            if unit.lower() in owners:
                errors.append(f'{path.name}: unit {unit} already belongs to {owners[unit.lower()]}')
            owners[unit.lower()] = path.stem
    known = set(deps) | {'rtl', 'vcl', 'designide'}
    for name, references in deps.items():
        for ref in references:
            if ref not in known:
                errors.append(f'{name}: missing dependency {ref}')
    group = root / 'packages/ERDCards.groupproj'
    if group.is_file():
        try:
            names = [Path(p.get('Include').replace('\\', '/')).stem
                     for p in ET.parse(group).findall('.//m:Projects', NS)]
        except ET.ParseError:
            errors.append('runtime group: invalid XML')
            names = []
        for index, name in enumerate(names):
            if name not in deps:
                errors.append(f'runtime group: unknown package {name}')
            for dep in deps.get(name, []):
                if dep.startswith('ERDCard') and dep not in names[:index]:
                    errors.append(f'runtime group: {name} precedes dependency {dep}')
        expected = {p.stem for p in (root / 'packages/runtime').glob('*.dpk')}
        if set(names) != expected or len(names) != len(expected):
            errors.append('runtime group: runtime package set differs')
    return errors


def check_registration(root):
    path = root / 'src/design/ERD.Card.Design.Register.pas'
    if not path.is_file():
        return ['palette registration source missing']
    expected = set()
    for unit in (root / 'src').rglob('*.pas'):
        expected.update(re.findall(r'\b(T\w+)\s*=\s*class\(TComponent\)', unit.read_text(), re.I))
    declared = []
    for names in re.findall(r"RegisterComponents\('[^']+',\s*\[([^]]+)\]\)", path.read_text(), re.S):
        declared.extend(re.findall(r'\bT\w+\b', names))
    errors = []
    if len(declared) != len(set(declared)):
        errors.append('palette: duplicate component registration')
    for name in sorted(expected - set(declared)):
        errors.append('palette: unregistered component ' + name)
    for name in sorted(set(declared) - expected):
        errors.append('palette: unknown component ' + name)
    return errors


def main():
    errors = check_packages(REPO) + check_registration(REPO)
    projects = sorted((REPO / 'packages').rglob('*.dproj')) + sorted((REPO / 'examples/vcl').rglob('*.dproj'))
    groups = sorted((REPO / 'packages').rglob('*.groupproj')) + sorted((REPO / 'examples/vcl').rglob('*.groupproj'))
    forms = sorted((REPO / 'examples/vcl').rglob('*.dfm'))
    for path in projects + groups:
        errors.extend(check_project(path))
    for path in forms:
        errors.extend(check_form(path))
    for path in sorted((REPO / 'examples/vcl').rglob('*.dpr')):
        errors.extend(check_program(path))
    for error in errors:
        print(error, file=sys.stderr)
    print(f'Distribution readers: {len(projects)} projects, {len(groups)} groups, {len(forms)} DFM forms; {len(errors)} findings.')
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
