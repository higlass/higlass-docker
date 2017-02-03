import re
import requests
import sys

def latest(repo):
	tags = requests.get('https://api.github.com/repos/%s/tags' % repo).json()
	names = [tag['name'] for tag in tags]
	matches = [re.match(r'^v(\d+\.\d+\.\d+)$', name) for name in names]
	version = [match.group(1) for match in matches if match][0]
	return version
	
print latest(sys.argv[1])