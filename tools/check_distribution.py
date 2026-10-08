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


def check_delphi_text(path):
    """Validate the native project's encoding contract in the actual working tree."""
    data = path.read_bytes()
    errors = []
    if not data.startswith(b'\xef\xbb\xbf'):
        errors.append(f'{path.name}: UTF-8 BOM missing')
    try:
        data.decode('utf-8-sig')
    except UnicodeDecodeError:
        errors.append(f'{path.name}: invalid UTF-8')
    remainder = data.replace(b'\r\n', b'')
    if b'\n' in remainder or b'\r' in remainder:
        errors.append(f'{path.name}: non-CRLF line endings')
    return errors


def expand_properties(value, properties):
    """Expand previously evaluated MSBuild properties, with case-insensitive names."""
    def replace(match):
        return next((v for k, v in properties.items() if k.casefold() == match[1].casefold()), '')
    return re.sub(r'\$\(([^)]+)\)', replace, value)


def evaluate_condition(condition, properties):
    """Read only the comparison/and/or grammar used by the native property groups.

    This is not an MSBuild engine: unknown syntax is rejected, and no property
    functions, imports, tasks, file writes or project targets are executed.
    """
    if condition is None:
        return True
    source = expand_properties(condition, properties).strip()
    tokens = []
    while source:
        match = re.match(r"\s*('[^']*'|==|!=|\(|\)|and\b|or\b)", source, re.I)
        if not match:
            raise ValueError('unsupported property-group condition')
        tokens.append(match[1]); source = source[match.end():]
    position = 0

    def term():
        nonlocal position
        if position >= len(tokens):
            raise ValueError('incomplete property-group condition')
        if tokens[position] == '(':
            position += 1
            result = expression()
            if position >= len(tokens) or tokens[position] != ')':
                raise ValueError('unbalanced property-group condition')
            position += 1
            return result
        if position + 2 >= len(tokens):
            raise ValueError('incomplete property comparison')
        left, operator, right = tokens[position:position + 3]
        position += 3
        if not left.startswith("'") or not right.startswith("'") or operator not in ('==', '!='):
            raise ValueError('unsupported property comparison')
        same = left[1:-1].casefold() == right[1:-1].casefold()
        return same if operator == '==' else not same

    def conjunction():
        nonlocal position
        result = term()
        while position < len(tokens) and tokens[position].casefold() == 'and':
            position += 1
            other = term()  # Consume both sides, regardless of boolean result.
            result = result and other
        return result

    def expression():
        nonlocal position
        result = conjunction()
        while position < len(tokens) and tokens[position].casefold() == 'or':
            position += 1
            other = conjunction()
            result = result or other
        return result

    result = expression()
    if position != len(tokens):
        raise ValueError('trailing property-group condition tokens')
    return result


def evaluate_properties(root, config, platform):
    """Evaluate explicit property groups for one requested configuration/target."""
    properties = {'Config': config, 'Platform': platform}
    for group in root.findall('m:PropertyGroup', NS):
        if not evaluate_condition(group.get('Condition'), properties):
            continue
        for child in group:
            name = child.tag.rsplit('}', 1)[-1]
            if name in ('Config', 'Platform') or not evaluate_condition(child.get('Condition'), properties):
                continue
            value = expand_properties(child.text or '', properties)
            key = next((k for k in properties if k.casefold() == name.casefold()), name)
            properties[key] = value
    return properties


def check_project(path):
    errors = check_delphi_text(path)
    try:
        tree = ET.parse(path)
    except (ET.ParseError, OSError) as error:
        return errors + [f'{path.name}: invalid MSBuild XML: {error}']
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
    source = local_path(path.parent, main or '')
    if not main or not source.is_file():
        errors.append(f'{path.name}: missing MainSource')
    else:
        errors.extend(check_delphi_text(source))
        if '{$R *.res}' not in source.read_text(encoding='utf-8-sig'):
            errors.append(f'{path.name}: project resource directive missing')
    package = root.findtext('.//m:AppType', namespaces=NS) == 'Package'
    if package and root.findtext('m:ProjectExtensions/m:Borland.ProjectType', namespaces=NS) != 'Package':
        errors.append(f'{path.name}: IDE Borland.ProjectType must be Package')
    references = root.findall('.//m:DCCReference', NS)
    dcp_refs = []
    for ref in references:
        include = ref.get('Include', '')
        # Named DCPs are resolved by Delphi's SDK/package search path at build time.
        # They are not source files expected to exist in a fresh checkout.
        if include.lower().endswith('.dcp'):
            if not re.fullmatch(r'\w+\.dcp', include, re.I):
                errors.append(f'{path.name}: package dependency must be a named DCP')
            dcp_refs.append(include[:-4]); continue
        ref_source = local_path(path.parent, include)
        if not ref_source.is_file():
            errors.append(f'{path.name}: missing DCCReference {include}')
        if ref.find('m:Form', NS) is not None and not ref_source.with_suffix('.dfm').is_file():
            errors.append(f'{path.name}: designer form resource missing')
    if package and source.is_file():
        requires = re.search(r'\brequires\s+(.+?);', source.read_text(encoding='utf-8-sig'), re.I | re.S)
        deps = re.findall(r'\w+', requires[1]) if requires else []
        if dcp_refs != deps:
            errors.append(f'{path.name}: DCP references differ from requires order')
    configs = root.findall('.//m:BuildConfiguration', NS)
    if [c.get('Include') for c in configs] != ['Base', 'Debug', 'Release']:
        errors.append(f'{path.name}: Base/Debug/Release configurations missing or duplicated')
    else:
        for c, key in zip(configs, ['Base', 'Cfg_1', 'Cfg_2']):
            parent = c.findtext('m:CfgParent', namespaces=NS)
            if c.findtext('m:Key', namespaces=NS) != key or parent != (None if key == 'Base' else 'Base'):
                errors.append(f'{path.name}: invalid configuration Key/CfgParent')
    for prop in ('DCC_DcuOutput', 'DCC_ExeOutput', 'DCC_BplOutput', 'DCC_DcpOutput'):
        dest = root.findtext('.//m:' + prop, default='', namespaces=NS)
        if '$(Platform)' not in dest or '$(Config)' not in dest:
            errors.append(f'{path.name}: {prop} must isolate Platform and Config')
    if root.find('.//m:DCC_OverflowChecking', NS) is not None:
        errors.append(f'{path.name}: use native DCC_IntegerOverflowCheck property')
    for element in root.findall('.//m:DCC_DebugInformation', NS):
        if not re.fullmatch(r'\d+', element.text or ''):
            errors.append(f'{path.name}: DCC_DebugInformation must be numeric, not boolean')
    for config, flag in [('Debug', 'Cfg_1'), ('Release', 'Cfg_2')]:
        for platform in ['Win32', 'Win64']:
            context = f'{path.name} {config}/{platform}'
            try:
                props = evaluate_properties(root, config, platform)
            except ValueError as error:
                errors.append(f'{context}: {error}'); continue
            for name in ['Base', 'Base_' + platform, flag, flag + '_' + platform]:
                if props.get(name, '').lower() != 'true':
                    errors.append(f'{context}: configuration activation {name} missing')
            for name in ['GenDll', 'GenPackage']:
                if props.get(name) != ('true' if package else 'false'):
                    errors.append(f'{context}: {name} differs from project type')
            if props.get('ProjectName') != path.stem or props.get('SanitizedProjectName') != path.stem:
                errors.append(f'{context}: project name metadata differs')
            for name in ['DCC_RangeChecking', 'DCC_IntegerOverflowCheck', 'DCC_GenerateDocumentation']:
                if props.get(name) != 'true':
                    errors.append(f'{context}: {name} is not enabled')
            if props.get('VerInfo_IncludeVerInfo') != 'true':
                errors.append(f'{context}: project resource generation is not enabled')
            if config == 'Release' and props.get('DCC_DebugInformation') != '0':
                errors.append(f'{context}: release debug-information value differs')
            for ref in props.get('DCC_UnitSearchPath', '').split(';'):
                if ref and '$(' not in ref and not local_path(path.parent, ref).is_dir() and 'dist' not in Path(ref.replace('\\', '/')).parts:
                    errors.append(f'{context}: missing unit search directory {ref}')
    imports = root.findall('m:Import', NS)
    if not any(ref.get('Project') == '$(BDS)\\Bin\\CodeGear.Delphi.Targets' for ref in imports):
        errors.append(f'{path.name}: Delphi MSBuild targets missing')
    return errors


def check_form(path):
    errors = []
    source = path.with_suffix('.pas')
    if not source.is_file():
        return [f'{path.name}: form Pascal source missing']
    pas = source.read_text(encoding='utf-8-sig')
    if '{$R *.dfm}' not in pas:
        errors.append(f'{path.name}: form resource directive missing')
    stack, seen = [], set()
    for line in path.read_text(encoding='utf-8-sig').splitlines():
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
    source = path.read_text(encoding='utf-8-sig')
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
        source = path.read_text(encoding='utf-8-sig')
        errors.extend(check_delphi_text(path))
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
