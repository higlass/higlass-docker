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

    # Tests:

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
            [r'SERVER_VERSION: \d+\.\d+\.\d+',
             r'WEBSITE_VERSION: \d+\.\d+\.\d+']
        )

    def test_html(self):
        self.assertRun(
            'curl -s http://localhost:{PORT}/',
            [r'Peter Kerpedjiev', r'Harvard Medical School',
             r'HiGlass is a tool for exploring']
        )

    # def test_data_dir(self):
    #     self.assertRun(
    #         '''
    #         diff -y expected-data-dir.txt <(
    #         pushd /tmp/higlass-docker/volume-{STAMP} > /dev/null \
    #         && find . | sort | perl -pne 's/-\w+\.log/-XXXXXX.log/' \
    #         && popd > /dev/null )
    #         ''',
    #         [r'^$']
    #     )


    def test_upload(self):
        # TODO: There's a new right way to upload, so redo this...
        os.environ['S3'] = 'https://s3.amazonaws.com/pkerp/public'
        os.environ['COOLER'] = 'dixon2012-h1hesc-hindiii-allreps-filtered.1000kb.multires.cool'
        self.assertRun('docker exec -it container-{STAMP}{SUFFIX} ./upload.sh -u {S3}/{COOLER} -g hg19')
        self.assertRun('curl http://localhost:{PORT}/api/v1/tilesets/', [os.environ['COOLER']])


    def test_ingest(self):
        if os.environ['SUFFIX'] != '-standalone':
            os.environ['S3'] = 'https://s3.amazonaws.com/pkerp/public'
            os.environ['COOLER'] = 'dixon2012-h1hesc-hindiii-allreps-filtered.1000kb.multires.cool'
            self.assertRun('wget -P /tmp/higlass-docker/volume-{STAMP}{SUFFIX}/hg-tmp {S3}/{COOLER}')
            self.assertRun('docker exec container-{STAMP}{SUFFIX} ls /tmp', [os.environ['COOLER']])

            ingest_cmd = 'python manage.py ingest_tileset --filename /tmp/{COOLER} --filetype cooler --datatype matrix --uid cooler-demo-{STAMP}'
            self.assertRun('docker exec container-{STAMP}{SUFFIX} sh -c "cd higlass-server; ' + ingest_cmd + '"')
            self.assertRun('curl http://localhost:{PORT}/api/v1/tilesets/', [
                os.environ['COOLER'],
                'cooler-demo-\S+'
            ])

            self.assertRun('docker exec container-{STAMP}{SUFFIX} ping -c 1 container-redis-{STAMP}',
                           [r'1 packets received, 0% packet loss'])



if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(CommandlineTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    lines = [
        'browse:  http://localhost:{PORT}/',
        'shell:   docker exec --interactive --tty container-{STAMP}{SUFFIX} bash',
        'logs:    docker exec container-{STAMP}{SUFFIX} ./logs.sh'
    ]
    for line in lines:
        print(line.format(**os.environ))
    if result.wasSuccessful():
        print('PASS!')
    else:
        print('FAIL!')
        exit(1)
