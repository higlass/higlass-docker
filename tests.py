import unittest
import subprocess

class CommandlineTest(unittest.TestCase):
    def setUp(self):
        pass

    def assertRun(self, command, res=[r'']):
        for re in res:
            self.assertRegexpMatches(subprocess.check_output(command , shell=True).strip(), re)

    def test_hello(self):
        self.assertRun('echo "hello?"', [r'hello'])

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(CommandlineTest)
    unittest.TextTestRunner(verbosity=2).run(suite)