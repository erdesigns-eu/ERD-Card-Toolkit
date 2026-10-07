"""Regression tests for documentation coverage and actual source selection."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'tools/pascalcheck'))
from check_xmldoc import inspect_source
import typemap
from symbols import UnitSyms


FIXTURE = '''unit Fixture;
interface
type
  /// <summary>An exported enumeration.</summary>
  TKind = (
    /// <summary>The first choice.</summary>
    kFirst,
    /// <summary>The second choice.</summary>
    kSecond
  );
  /// <summary>A callback type.</summary>
  /// <param name="Value">The callback argument.</param>
  TCallback = procedure(const Value: Integer) of object;
  /// <summary>A method reference.</summary>
  /// <param name="Value">The function argument.</param>
  /// <returns>The result.</returns>
  TFactory = reference to function(const Value: Integer): Integer;
  /// <summary>An interface.</summary>
  IFoo = interface
    /// <summary>Gets a value.</summary>
    /// <returns>The value.</returns>
    function Read: Integer;
  end;
  /// <summary>A record.</summary>
  TRec = record
    /// <summary>A visible record field.</summary>
    Value: Integer;
  end;
  /// <summary>A helper.</summary>
  TRecHelper = record helper for TRec
    /// <summary>Changes a value.</summary>
    /// <param name="Value">The new value.</param>
    procedure Change(Value: Integer);
  end;
  /// <summary>An exported class.</summary>
  TFoo = class
  private
    FHidden: Integer;
    procedure Hidden;
  protected
    /// <summary>An extension point.</summary>
    procedure Extend; virtual;
  public
    /// <summary>Creates the object.</summary>
    constructor Create;
    /// <summary>A public field.</summary>
    Value: Integer;
    /// <summary>A visible property.</summary>
    property Number: Integer read FHidden;
    /// <summary>An indexed property.</summary>
    /// <param name="Index">The selected index.</param>
    property Items[Index: Integer]: Integer read GetItem;
    /// <summary>A first overload.</summary>
    /// <param name="Value">The input.</param>
    /// <returns>The output.</returns>
    function Read(Value: Integer): Integer; overload;
    /// <summary>A second overload.</summary>
    /// <param name="Value">The input.</param>
    /// <param name="Other">The second input.</param>
    /// <returns>The output.</returns>
    function Read(Value, Other: Integer): Integer; overload;
  published
    /// <summary>An event.</summary>
    property OnRead: TCallback read FCallback write FCallback;
  end;
const
  /// <summary>A constant.</summary>
  Default = 3;
var
  /// <summary>A global variable.</summary>
  Current: Integer;
threadvar
  /// <summary>A thread-local variable.</summary>
  Local: Integer;
resourcestring
  /// <summary>A localizable message.</summary>
  MessageText = 'Message';
/// <summary>An exported procedure.</summary>
/// <param name="Value">The input.</param>
procedure Process(const Value: Integer);
/// <summary>An exported function with no parameters.</summary>
/// <returns>The answer.</returns>
function Answer: Integer;
implementation
end.
'''


class DocumentationTests(unittest.TestCase):
    def scan(self, source):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Fixture.pas'
            path.write_text(source)
            return inspect_source(path)

    def test_documented_api_shapes(self):
        count, errors = self.scan(FIXTURE)
        self.assertEqual(errors, [])
        self.assertEqual(count, 26)

    def test_missing_summary_detects_every_public_declaration(self):
        count, errors = self.scan(FIXTURE)
        self.assertFalse(errors)
        # Delete one declaration's own documentation at a time, then restore it.
        for line in FIXTURE.splitlines():
            if '/// <summary>' in line:
                with self.subTest(comment=line):
                    modified = FIXTURE.replace(line + '\n', '', 1)
                    self.assertTrue(self.scan(modified)[1])

    def test_malformed_xml(self):
        source = FIXTURE.replace('An exported class.</summary>', 'An exported class.')
        self.assertTrue(any('invalid XML' in e for _, e in self.scan(source)[1]))

    def test_wrong_parameter_name(self):
        source = FIXTURE.replace('name="Other"', 'name="Wrong"')
        self.assertTrue(any('param names' in e for _, e in self.scan(source)[1]))

    def test_missing_and_duplicate_parameter(self):
        for replacement in ('', '/// <param name="Other">Again.</param>\n'):
            source = FIXTURE.replace('/// <param name="Other">The second input.</param>', replacement)
            self.assertTrue(self.scan(source)[1])

    def test_return_contract(self):
        source = FIXTURE.replace('/// <returns>The answer.</returns>\n', '')
        self.assertTrue(any('returns tag' in e for _, e in self.scan(source)[1]))
        source = FIXTURE.replace('procedure Process', '/// <returns>Invalid.</returns>\nprocedure Process')
        self.assertTrue(any('without a return value' in e for _, e in self.scan(source)[1]))

    def test_private_members_need_no_public_documentation(self):
        source = FIXTURE.replace('procedure Hidden;', 'procedure Hidden(const Secret: Integer);')
        self.assertFalse(self.scan(source)[1])

    def test_unknown_xml_tag_is_not_silently_accepted(self):
        source = FIXTURE.replace('/// <summary>A global variable.</summary>', '/// <summary>A global variable.</summary>\n/// <unknown>Text</unknown>')
        self.assertTrue(any('unsupported XML tag' in e for _, e in self.scan(source)[1]))

    def test_unsupported_variant_record_fails_visibly(self):
        source = FIXTURE.replace('Value: Integer;\n  end;', 'case Boolean of True: (Value: Integer);\n  end;', 1)
        self.assertTrue(any('cannot inspect public API' in e for _, e in self.scan(source)[1]))


class RunnerTests(unittest.TestCase):
    def run_checker(self, *arguments, env=None):
        return subprocess.run(
            [sys.executable, str(REPO / 'tools/pascalcheck/run.py'), *arguments],
            cwd=REPO, env=env, text=True, capture_output=True,
        )

    def test_explicit_inputs_and_no_duplicate_discovery(self):
        result = self.run_checker('--profile', 'core', '--source-root', 'src/core',
                                  '--source-root', 'src/core/ERD.Card.Bytes.pas', 'xmldoc')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        expected = sorted(path.name for path in (REPO / 'src/core').glob('*.pas'))
        self.assertIn(f'Selected {len(expected)} Pascal source file(s)', result.stdout)
        for name in expected:
            self.assertEqual(result.stdout.count('src/core/' + name), 1)

    def test_empty_missing_and_wrong_extension_inputs_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            for path in (directory, str(Path(directory) / 'missing'), 'README.md'):
                with self.subTest(path=path):
                    result = self.run_checker('--profile', 'core', '--source-root', path)
                    self.assertEqual(result.returncode, 2)

    def test_source_selection_cannot_claim_fixed_path_checker_coverage(self):
        result = self.run_checker('--profile', 'all', '--source-root', 'src/core')
        self.assertEqual(result.returncode, 2)

    def test_invalid_source_environment_fails(self):
        for value in ('not JSON', '{}', '[]', '[1]', json.dumps(['does-not-exist'])):
            with self.subTest(value=value):
                env = os.environ.copy()
                env['PASCALCHECK_SOURCE_ROOTS'] = value
                result = self.run_checker('--profile', 'core', 'xmldoc', env=env)
                self.assertEqual(result.returncode, 2)

    def test_no_api_is_not_a_passing_documentation_run(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Empty.pas'
            path.write_text('unit Empty; interface implementation end.')
            result = self.run_checker('--profile', 'core', '--source-root', str(path), 'xmldoc')
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_namespace_type_resolution(self):
        with tempfile.TemporaryDirectory() as directory:
            provider = Path(directory) / 'Example.Provider.pas'
            provider.write_text('unit Example.Provider; interface type TShared = class end; implementation end.')
            consumer = Path(directory) / 'Example.Consumer.pas'
            consumer.write_text('unit Example.Consumer; interface uses Example.Provider; implementation end.')
            old_cache = typemap._cache.copy()
            try:
                unit = UnitSyms(provider)
                typemap._cache.clear()
                typemap._cache['example.provider'] = unit
                self.assertIs(typemap.find_type('TShared', UnitSyms(consumer)), unit.types['tshared'])
            finally:
                typemap._cache.clear()
                typemap._cache.update(old_cache)


if __name__ == '__main__':
    unittest.main()
