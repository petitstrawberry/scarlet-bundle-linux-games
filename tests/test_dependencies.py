#!/usr/bin/env python3
"""Selection boundaries prevent unrequested dependencies and shell arguments."""
import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location('dependencies', pathlib.Path(__file__).resolve().parents[1] / 'producer/resolve_dependencies.py')
dependencies = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dependencies)


class Dependencies(unittest.TestCase):
    def test_none_has_no_packages_or_graphics(self):
        result = dependencies.resolve('none')
        self.assertEqual(result['packages'], [])
        self.assertFalse(result['requires_graphics'])

    def test_openttd_includes_missing_png_and_deduplicates(self):
        result = dependencies.resolve('openttd,openttd')
        self.assertEqual(result['games'], ['openttd'])
        self.assertIn('libpng16-16t64', result['packages'])
        self.assertTrue(result['requires_graphics'])

    def test_invalid_selection_is_rejected(self):
        for selection in ['', 'unknown', 'none,openttd', '../openttd', 'openttd,--allow-unauthenticated']:
            with self.subTest(selection=selection), self.assertRaises(ValueError):
                dependencies.resolve(selection)


if __name__ == '__main__':
    unittest.main()
