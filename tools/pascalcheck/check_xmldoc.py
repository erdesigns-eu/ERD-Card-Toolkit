"""Check Delphi XML-doc coverage and signatures on the selected public API.

Reads declarations, not implementations. Unsupported declaration shapes fail
visibly rather than returning a misleading clean result. This is not a compiler
or a proof that Help Insight renders correctly in a particular Delphi release.
"""
from dataclasses import dataclass
import os
import re
import sys
import xml.etree.ElementTree as ET

from common import load, pas_files, ROOT

ROUTINES = {'function', 'procedure', 'constructor', 'destructor', 'operator'}
SECTIONS = {'type', 'const', 'var', 'threadvar', 'resourcestring'}
VISIBILITY = {'private', 'protected', 'public', 'published', 'automated'}
FLAGS = {
    'overload', 'override', 'virtual', 'dynamic', 'abstract', 'reintroduce',
    'static', 'inline', 'cdecl', 'stdcall', 'safecall', 'register', 'pascal',
    'deprecated', 'platform', 'experimental', 'dispid', 'message', 'default',
    'nodefault', 'stored', 'implements', 'external', 'forward',
}
TAGS = {'summary', 'para', 'c', 'code', 'remarks', 'param', 'see',
        'returns', 'exception', 'permission'}


@dataclass
class Declaration:
    name: str
    kind: str
    line: int
    params: tuple = ()
    returns: bool = False


def declarations(src, toks):
    """Read exported types, globals and visible members with token positions."""
    words = [t.lower() for _, t, _ in toks]
    start = words.index('interface') + 1
    stop = words.index('implementation', start)
    scopes = []
    mode = None
    entries = []

    def visible():
        return not scopes or (scopes[-1]['exposed'] and
                              scopes[-1]['visibility'] != 'private')

    def entry(index, name, kind, params=(), returns=False):
        if visible():
            prefix = scopes[-1]['name'] + '.' if scopes else ''
            line = src.count('\n', 0, toks[index][2]) + 1
            entries.append(Declaration(prefix + name, kind, line, tuple(params), returns))

    def end_statement(index):
        depth = 0
        for j in range(index, stop):
            if words[j] in ('(', '['):
                depth += 1
            elif words[j] in (')', ']'):
                depth -= 1
            elif words[j] == ';' and depth == 0:
                return j + 1
        raise ValueError('unterminated declaration')

    def matching(index):
        opening = words[index]
        closing = ')' if opening == '(' else ']'
        depth = 0
        for j in range(index, stop):
            if words[j] == opening:
                depth += 1
            elif words[j] == closing:
                depth -= 1
                if depth == 0:
                    return j
        raise ValueError('unclosed parameter, enum or ancestor list')

    def signature(index, end):
        params = []
        opening = next((j for j in range(index, end) if words[j] in ('(', '[', ':')), end)
        return_start = index
        if opening < end and words[opening] in ('(', '['):
            last = matching(opening)
            return_start = last + 1
            group_start = opening + 1
            depth = 0
            for j in range(group_start, last + 1):
                word = words[j]
                if j == last or (word == ';' and depth == 0):
                    group = list(toks[group_start:j])
                    # Parameter attributes are not part of the parameter name.
                    while group and group[0][1] == '[':
                        close = next(k for k, token in enumerate(group) if token[1] == ']')
                        group = group[close + 1:]
                    while group and group[0][1].lower() in ('const', 'var', 'out', 'constref'):
                        group.pop(0)
                    if group:
                        colon = next((k for k, token in enumerate(group) if token[1] == ':'), None)
                        if colon is None:
                            raise ValueError('parameter group has no type')
                        params.extend(token[1].lstrip('&') for token in group[:colon]
                                      if token[0] == 'id')
                    group_start = j + 1
                elif word in ('(', '['):
                    depth += 1
                elif word in (')', ']'):
                    depth -= 1
        has_return = any(words[j] == ':' for j in range(return_start, end))
        return params, has_return

    i = start
    while i < stop:
        word = words[i]
        if word == ';':
            i += 1
            continue
        if word == 'uses' and not scopes:
            mode = 'uses'
            i += 1
            continue
        if mode == 'uses' and word not in SECTIONS | ROUTINES:
            i += 1
            continue
        if word in SECTIONS:
            mode = word
            i += 1
            continue
        if word == 'strict' and i + 1 < stop and words[i + 1] in VISIBILITY:
            i += 1
            continue
        if word in VISIBILITY and scopes:
            scopes[-1]['visibility'] = word
            mode = 'fields'
            i += 1
            continue
        if word == 'end' and scopes:
            mode = scopes.pop()['parent_mode']
            i += 1
            continue
        if word == '[':  # attributes and interface GUIDs
            i = matching(i) + 1
            continue
        if word == 'class' and i + 1 < stop and words[i + 1] in ('var', 'const'):
            mode = words[i + 1]
            i += 2
            continue

        method_start = i
        if word == 'class' and i + 1 < stop and words[i + 1] in ROUTINES | {'property'}:
            i += 1
            word = words[i]
        if word in ROUTINES | {'property'}:
            end = end_statement(i)
            name = toks[i + 1][1].lstrip('&')
            params, returns = signature(i + 2, end)
            entry(method_start, name, word, params,
                  word in ('function', 'operator') and returns)
            i = end
            continue
        if word in FLAGS and (i + 1 >= stop or words[i + 1] not in (':', '=')):
            i = end_statement(i)
            continue

        if toks[i][0] == 'id' and mode == 'type':
            equal = i + 1
            if equal < stop and words[equal] == '<':
                while equal < stop and words[equal] != '>':
                    equal += 1
                equal += 1
            if equal >= stop or words[equal] != '=':
                raise ValueError('unsupported type declaration near ' + toks[i][1])
            body = equal + 1
            if words[body] == 'packed':
                body += 1
            kind = words[body]
            name = toks[i][1].lstrip('&')
            if kind in ('class', 'record', 'interface', 'dispinterface', 'object'):
                entry(i, name, kind)
                j = body + 1
                if kind == 'class' and words[j] == 'of':
                    i = end_statement(j)
                    continue
                if words[j] in ('sealed', 'abstract'):
                    j += 1
                if words[j] == '(':
                    j = matching(j) + 1
                if words[j] == 'helper':
                    j += 1
                    if words[j] == 'for':
                        j += 2
                if words[j] == ';':
                    i = j + 1
                    continue
                prefix = scopes[-1]['name'] + '.' if scopes else ''
                scopes.append({'name': prefix + name, 'visibility': 'public',
                               'exposed': visible(), 'parent_mode': mode})
                mode = 'fields'
                i = j
                continue
            if kind == '(':
                entry(i, name, 'enum')
                end = matching(body)
                j = body + 1
                while j < end:
                    entry(j, toks[j][1].lstrip('&'), 'enum value')
                    j += 1
                    while j < end and words[j] != ',':
                        j += 1
                    j += 1
                i = end + 1
                continue
            end = end_statement(body)
            callable_start = body + 2 if words[body:body + 2] == ['reference', 'to'] else body
            if words[callable_start] in ('function', 'procedure'):
                params, returns = signature(callable_start + 1, end)
                entry(i, name, 'callback', params, words[callable_start] == 'function' and returns)
            else:
                if any(words[j] == 'record' for j in range(body, end)):
                    raise ValueError('anonymous structured type requires explicit checker support')
                entry(i, name, 'type')
            i = end
            continue

        if toks[i][0] == 'id' and mode in ('fields', 'const', 'var', 'threadvar', 'resourcestring'):
            end = end_statement(i)
            j = i
            names = [toks[j][1].lstrip('&')]
            while j + 2 < end and words[j + 1] == ',':
                j += 2
                names.append(toks[j][1].lstrip('&'))
            if j + 1 >= end or words[j + 1] not in (':', '='):
                raise ValueError('unsupported declaration near ' + toks[i][1])
            if any(words[k] == 'record' for k in range(j + 1, end)):
                raise ValueError('anonymous record requires explicit checker support')
            for name in names:
                entry(i, name, mode)
            i = end
            continue
        raise ValueError('unsupported declaration token ' + toks[i][1])
    if scopes:
        raise ValueError('unclosed structured type')
    return entries


def documentation(lines, line):
    index = line - 2
    comments = []
    while index >= 0 and lines[index].lstrip().startswith('///'):
        comments.append(lines[index].lstrip()[3:])
        index -= 1
    return '\n'.join(reversed(comments))


def inspect_source(path):
    src, clean, directives, starts, toks = load(str(path))
    errors = []
    try:
        api = declarations(src, toks)
    except (ValueError, IndexError, StopIteration) as error:
        return 0, [('?', 'cannot inspect public API: ' + str(error))]
    lines = src.splitlines()
    for decl in api:
        label = '%s %s' % (decl.kind, decl.name)
        text = documentation(lines, decl.line)
        if not text:
            errors.append((decl.line, label + ': missing XML documentation'))
            continue
        try:
            doc = ET.fromstring('<doc>' + text + '</doc>')
        except ET.ParseError as error:
            errors.append((decl.line, label + ': invalid XML: ' + str(error)))
            continue
        summaries = doc.findall('summary')
        if len(summaries) != 1 or not ''.join(summaries[0].itertext()).strip():
            errors.append((decl.line, label + ': requires one nonempty summary'))
        for node in doc.iter():
            if node.tag != 'doc' and node.tag not in TAGS:
                errors.append((decl.line, label + ': unsupported XML tag ' + node.tag))
            if node.tag in ('exception', 'permission', 'see') and not node.get('cref'):
                errors.append((decl.line, label + ': ' + node.tag + ' requires cref'))
            if node.tag in ('param', 'returns') and not ''.join(node.itertext()).strip():
                errors.append((decl.line, label + ': empty ' + node.tag))
        params = [node.get('name') for node in doc.findall('param')]
        if len(params) != len(set(params)) or set(params) != set(decl.params):
            errors.append((decl.line, label + ': param names do not match ' + repr(decl.params)))
        returns = doc.findall('returns')
        if decl.returns and len(returns) != 1:
            errors.append((decl.line, label + ': requires exactly one returns tag'))
        if not decl.returns and returns:
            errors.append((decl.line, label + ': returns tag on a declaration without a return value'))
    return len(api), errors


def main():
    paths = sorted(path for path in pas_files() if path.lower().endswith('.pas'))
    print('=== Delphi public API XML documentation ===')
    total = 0
    inspected = 0
    if not paths:
        print('  no unit sources selected')
        total += 1
    for path in paths:
        count, errors = inspect_source(path)
        inspected += count
        rel = os.path.relpath(path, ROOT)
        print('  %s: %d declaration(s)' % (rel, count))
        for line, error in errors:
            print('  %s:%s  %s' % (rel, line, error))
        total += len(errors)
    print('  inspected public declarations:', inspected)
    if inspected == 0 and total == 0:
        print('  no public declarations inspected')
        total += 1
    print('  total:', total)


if __name__ == '__main__':
    main()
