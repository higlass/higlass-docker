import unittest
import subprocess
import os

class CommandlineTest(unittest.TestCase):
    def setUp(self):
        # self.suffix = os.environ['SUFFIX']
        # self.stamp = os.environ['STAMP']
        os.environ['PORT'] = subprocess.check_output(
            "docker port container-{STAMP}{SUFFIX} | perl -pne 's/.*://'".format(**os.environ),
            shell=True
        ).strip()
        os.environ['TILESETS_URL']='http://localhost:{PORT}/api/v1/tilesets/'.format(**os.environ)
        # TODO: Wait till server starts

    def assertRun(self, command, res=[r'']):
        output = subprocess.check_output(command.format(**os.environ), shell=True).strip()
        for re in res:
            self.assertRegexpMatches(output, re)

    def test_hello(self):
        self.assertRun('echo "hello?"', [r'hello'])

    def test_tilesets(self):
        self.assertRun(
            'curl -s http://localhost:{PORT}/api/v1/tilesets/',
            [r'\{"count":']
        )

    def test_tiles(self):
        self.assertRun(
            'curl -s http://localhost:{PORT}/api/v1/tiles/',
            [r'\{\}']
        )

    # def test_nginx_log(self):
    #     self.assertRun(
    #         'docker exec container-{STAMP}{SUFFIX} cat /var/log/nginx/error.log',
    #         [r'todo-nginx-log']
    #     )

    def test_version_txt(self):
        self.assertRun(
            'curl -s http://localhost:{PORT}/version.txt',
            [r'SERVER_VERSION: \d+\.\d+\.\d+', r'WEBSITE_VERSION: \d+\.\d+\.\d+']
        )

    def test_html(self):
        self.assertRun(
            'curl -s http://localhost:{PORT}/',
            [r'Peter Kerpedjiev', r'Harvard Medical School',
             r'HiGlass is a tool for exploring']
        )

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(CommandlineTest)
    unittest.TextTestRunner(verbosity=2).run(suite)