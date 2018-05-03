#!/usr/bin/python

import argparse
import subprocess as sp
import sys
import webbrowser

def main():
    parser = argparse.ArgumentParser(description="""
    
    python start_higlass.py data_directory

    Start a local HiGlass instance. Requires Docker.
""")

    parser.add_argument('data_dir')
    parser.add_argument('-v', '--version', default=None,
    					 help="The version of the higlass container to start", 
                                         type=str)
    parser.add_argument('-p', '--port', default=8989,
    					 help="The port to run the Docker container on", 
                                         type=int)
    parser.add_argument('-t', '--temp-dir', default='/tmp/higlass-docker',
    					 help="The temp directory to use", 
                                         type=str)
    parser.add_argument('-n', '--name', default='higlass-container',
    					 help='The name of the container to use', 
                                         type=str)
    #parser.add_argument('-u', '--useless', action='store_true', 
    #					 help='Another useless option')

    args = parser.parse_args()

    version_addition = '' if args.version is None else ':{}'.format(args.version)

    sp.call(['docker', 'pull', 
        'gehlenborglab/higlass'])

    sp.call(['docker', 'run', '--detach',
        '--publish', str(args.port) + ':80',
        '--volume', args.temp_dir + ':/tmp',
        '--volume', args.data_dir + ':/data',
        '--name', 'higlass-container',
        'gehlenborglab/higlass'])

    
    webbrowser.open('http://localhost:{port}/'.format(port=args.port))

if __name__ == '__main__':
    main()


