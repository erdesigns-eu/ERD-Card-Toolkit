"""Negative fixtures for the bounded Delphi distribution readers."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('distribution', Path(__file__).resolve().parents[2] / 'tools/check_distribution.py')
distribution = importlib.util.module_from_spec(spec)
spec.loader.exec_module(distribution)


class DistributionTests(unittest.TestCase):
    def test_shipped_distribution(self):
        self.assertEqual(distribution.check_packages(distribution.REPO), [])
        self.assertEqual(distribution.check_registration(distribution.REPO), [])
        for path in distribution.REPO.glob('packages/**/*.dproj'):
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


if __name__ == '__main__':
    unittest.main()
