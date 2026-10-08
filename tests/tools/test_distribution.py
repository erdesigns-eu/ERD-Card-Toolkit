"""Negative fixtures for the bounded Delphi distribution readers."""
from contextlib import contextmanager
import importlib.util
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('distribution', Path(__file__).resolve().parents[2] / 'tools/check_distribution.py')
distribution = importlib.util.module_from_spec(spec)
spec.loader.exec_module(distribution)


@contextmanager
def copied_core_project():
    """Isolate the real package and its source references for negative mutations."""
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        package = root / 'packages/runtime'
        package.mkdir(parents=True)
        for suffix in ['.dproj', '.dpk']:
            shutil.copyfile(distribution.REPO / ('packages/runtime/ERDCardCore' + suffix),
                            package / ('ERDCardCore' + suffix))
        for folder in ['core', 'crypto', 'pcsc', 'eid', 'emv', 'magstripe', 'contactless']:
            (root / 'src' / folder).mkdir(parents=True)
        for source in (distribution.REPO / 'src/core').glob('*.pas'):
            shutil.copyfile(source, root / 'src/core' / source.name)
        yield package / 'ERDCardCore.dproj'


def write_project(path, root):
    ET.register_namespace('', distribution.NS['m'])
    ET.indent(root, space='    ')
    text = ET.tostring(root, encoding='unicode') + '\n'
    path.write_bytes(b'\xef\xbb\xbf' + text.replace('\n', '\r\n').encode('utf-8'))


class DistributionTests(unittest.TestCase):
    def test_shipped_distribution(self):
        self.assertEqual(distribution.check_packages(distribution.REPO), [])
        self.assertEqual(distribution.check_registration(distribution.REPO), [])
        for path in list(distribution.REPO.glob('packages/**/*.dproj')) + list(distribution.REPO.glob('examples/vcl/**/*.dproj')) + list(distribution.REPO.glob('packages/**/*.groupproj')) + list(distribution.REPO.glob('examples/vcl/**/*.groupproj')):
            self.assertEqual(distribution.check_project(path), [])
        for path in distribution.REPO.glob('examples/vcl/**/*.dfm'):
            self.assertEqual(distribution.check_form(path), [])

    def test_missing_main_and_unisolated_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'broken.dproj'
            path.write_text('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003"><PropertyGroup><MainSource>missing.dpr</MainSource><DCC_DcuOutput>dist</DCC_DcuOutput></PropertyGroup><ItemGroup><DCCReference Include="missing.pas"><Form>MissingForm</Form></DCCReference></ItemGroup></Project>')
            errors = distribution.check_project(path)
            self.assertTrue(any('MainSource' in e for e in errors))
            self.assertTrue(any('DCC_DcuOutput' in e for e in errors))
            self.assertTrue(any('targets missing' in e for e in errors))
            self.assertTrue(any('DCCReference' in e for e in errors))
            self.assertTrue(any('designer form resource' in e for e in errors))

    def test_bad_xml_and_missing_group_reference(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'bad.dproj'
            path.write_text('<Project>')
            self.assertTrue(distribution.check_project(path))
            path = path.with_suffix('.groupproj')
            path.write_text('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003"><ItemGroup><Projects Include="missing.dproj"/></ItemGroup></Project>')
            self.assertTrue(any('missing group' in e for e in distribution.check_project(path)))

    def test_dfm_field_event_and_balance(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Example.Main.dfm'
            path.with_suffix('.pas').write_text('unit Example.Main; interface type TExample = class(TForm) published Button: TButton; procedure Click(Sender: TObject); end; implementation {$R *.dfm} procedure TExample.Click(Sender: TObject); begin end; end.')
            good = 'object Example: TExample\n  object Button: TButton\n    OnClick = Click\n  end\nend\n'
            path.write_text(good)
            self.assertEqual(distribution.check_form(path), [])
            path.write_text(good.replace('Button: TButton', 'Button: TEdit').replace('OnClick = Click', 'OnClick = Missing')[:-4])
            errors = distribution.check_form(path)
            self.assertTrue(any('field/type' in e for e in errors))
            self.assertTrue(any('handler Missing' in e for e in errors))
            self.assertTrue(any('unclosed' in e for e in errors))

    def test_package_duplicate_ownership_and_design_dependency(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            packages = root / 'packages/runtime'
            packages.mkdir(parents=True)
            (root / 'unit.pas').write_text('unit ERD.Card.Unit; interface implementation end.')
            for name in ['A', 'B']:
                (packages / (name + '.dpk')).write_text("package " + name + "; {$RUNONLY} requires rtl, designide; contains ERD.Card.Unit in '../../unit.pas'; end.")
            errors = distribution.check_packages(root)
            self.assertTrue(any('already belongs' in e for e in errors))
            self.assertTrue(any('runtime depends' in e for e in errors))

    def test_palette_missing_unknown_and_duplicate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'src/design').mkdir(parents=True)
            (root / 'src/Reader.pas').write_text('unit Reader; interface type TReader = class(TComponent) end; implementation end.')
            (root / 'src/design/ERD.Card.Design.Register.pas').write_text("RegisterComponents('Cards', [TUnknown, TUnknown]);")
            errors = distribution.check_registration(root)
            self.assertTrue(any('unregistered component TReader' in e for e in errors))
            self.assertTrue(any('unknown component TUnknown' in e for e in errors))
            self.assertTrue(any('duplicate component' in e for e in errors))

    def test_package_configuration_matrix_and_native_reference(self):
        native = ET.parse(distribution.REPO / 'Delphi Packages/Core.dproj').getroot()
        shipped = ET.parse(distribution.REPO / 'packages/runtime/ERDCardCore.dproj').getroot()
        for config, flag in [('Debug', 'Cfg_1'), ('Release', 'Cfg_2')]:
            original = distribution.evaluate_properties(native, config, 'Win32')
            for platform in ['Win32', 'Win64']:
                actual = distribution.evaluate_properties(shipped, config, platform)
                for name in ['GenDll', 'GenPackage', 'DCC_E', 'DCC_N', 'DCC_S', 'DCC_F', 'DCC_K']:
                    self.assertEqual(actual[name], original[name])
                self.assertEqual(actual['Base_' + platform], 'true')
                self.assertEqual(actual[flag + '_' + platform], 'true')
                self.assertNotIn('Cfg_2' if config == 'Debug' else 'Cfg_1', actual)
                self.assertEqual(actual['DCC_IntegerOverflowCheck'], 'true')
                self.assertIn(platform + '\\' + config, actual['DCC_DcuOutput'])
                if config == 'Release':
                    self.assertEqual(actual['DCC_DebugInformation'], original['DCC_DebugInformation'])
        with copied_core_project() as path:
            self.assertEqual(distribution.check_project(path), [])

    def test_missing_base_and_platform_configuration(self):
        with copied_core_project() as path:
            root = ET.parse(path).getroot()
            group = root.find('m:ItemGroup', distribution.NS)
            group.remove(group.find("m:BuildConfiguration[@Include='Base']", distribution.NS))
            for group in root.findall('m:PropertyGroup', distribution.NS):
                if group.find('m:Base_Win64', distribution.NS) is not None:
                    root.remove(group)
            write_project(path, root)
            errors = distribution.check_project(path)
            self.assertTrue(any('Base/Debug/Release' in e for e in errors))
            self.assertTrue(any('activation Base_Win64 missing' in e for e in errors))

    def test_ide_package_identity_matches_native_project(self):
        native = ET.parse(distribution.REPO / 'Delphi Packages/Core.dproj').getroot()
        expected = native.findtext('m:ProjectExtensions/m:Borland.ProjectType', namespaces=distribution.NS)
        self.assertEqual(expected, 'Package')
        for path in distribution.REPO.glob('packages/**/*.dproj'):
            actual = ET.parse(path).findtext('m:ProjectExtensions/m:Borland.ProjectType', namespaces=distribution.NS)
            self.assertEqual(actual, expected)
        with copied_core_project() as path:
            root = ET.parse(path).getroot()
            root.find('m:ProjectExtensions/m:Borland.ProjectType', distribution.NS).text = None
            write_project(path, root)
            self.assertTrue(any('IDE Borland.ProjectType' in e for e in distribution.check_project(path)))

    def test_package_generation_flags_are_required(self):
        with copied_core_project() as path:
            root = ET.parse(path).getroot()
            root.find('.//m:GenPackage', distribution.NS).text = 'false'
            root.find('.//m:GenDll', distribution.NS).text = 'false'
            write_project(path, root)
            errors = distribution.check_project(path)
            self.assertTrue(any('GenPackage differs' in e for e in errors))
            self.assertTrue(any('GenDll differs' in e for e in errors))

    def test_wrong_native_compiler_property_types(self):
        with copied_core_project() as path:
            root = ET.parse(path).getroot()
            root.find('.//m:DCC_DebugInformation', distribution.NS).text = 'false'
            for group in root.findall('m:PropertyGroup', distribution.NS):
                for prop in group.findall('m:DCC_IntegerOverflowCheck', distribution.NS):
                    prop.tag = '{' + distribution.NS['m'] + '}DCC_OverflowChecking'
            write_project(path, root)
            errors = distribution.check_project(path)
            self.assertTrue(any('must be numeric' in e for e in errors))
            self.assertTrue(any('use native DCC_IntegerOverflowCheck' in e for e in errors))
            self.assertTrue(any('DCC_IntegerOverflowCheck is not enabled' in e for e in errors))

    def test_dependency_metadata_and_resource_directive(self):
        with copied_core_project() as path:
            root = ET.parse(path).getroot()
            root.find('.//m:DCCReference', distribution.NS).set('Include', 'vcl.dcp')
            write_project(path, root)
            dpk = path.with_suffix('.dpk')
            dpk.write_bytes(dpk.read_bytes().replace(b'{$R *.res}', b''))
            errors = distribution.check_project(path)
            self.assertTrue(any('DCP references differ' in e for e in errors))
            self.assertTrue(any('resource directive missing' in e for e in errors))

    def test_native_utf8_bom_and_crlf(self):
        with copied_core_project() as path:
            data = path.read_bytes()
            path.write_bytes(data[3:].replace(b'\r\n', b'\n', 1))
            errors = distribution.check_delphi_text(path)
            self.assertTrue(any('BOM missing' in e for e in errors))
            self.assertTrue(any('non-CRLF' in e for e in errors))
            path.write_bytes(b'\xef\xbb\xbf\xff\r\n')
            self.assertTrue(any('invalid UTF-8' in e for e in distribution.check_delphi_text(path)))

    def test_condition_reader_rejects_unhandled_syntax(self):
        self.assertTrue(distribution.evaluate_condition("'a'=='A' or ('b'!='B' and 'c'=='d')", {}))
        self.assertFalse(distribution.evaluate_condition("'a'=='A' and ('b'!='B' or 'c'=='d')", {}))
        self.assertTrue(distribution.evaluate_condition("'$(Base)'=='true'", {'BASE': 'TRUE'}))
        for expression in ["Exists('file')", "'a'=='a' trailing", "('a'=='a'", "'a'=="]:
            with self.assertRaises(ValueError):
                distribution.evaluate_condition(expression, {})


if __name__ == '__main__':
    unittest.main()
