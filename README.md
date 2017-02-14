# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass/).

## Running locally

You can see HiGlass in action at [higlass.io](http://higlass.io/).

It is also easy to launch your own. Install Docker, and then:
```bash
docker run --detach --publish 8888:80 --name higlass-container gehlenborglab/higlass:v0.0.7
```

and then ingest data:
```bash
S3=https://s3.amazonaws.com/pkerp/public
COOLER=dixon2012-h1hesc-hindiii-allreps-filtered.1000kb.multires.cool
# Or pick a URL of your own
docker exec -t higlass-container ./upload.sh -u $S3/$COOLER -g hg19
```
Developer notes: 
- Without `-t` the script hangs and the temporary django is left running.
- **TODO**: Ideally, user specifies UID. Failing that, send all output to stdout,
except for ID, so this can be back-ticked.

The default viewconfig points to UIDs which won't be on a new instance,
so you'll need a new viewconfig that references the data you've uploaded:
```json
{TODO: minimal viewconfig}
```

Then load it via the API:
```bash
ID=$(docker exec higlass-container ./create_viewconf.sh "`cat  your-config.json`")
```
**TODO**: This is ugly. Could it read stdin? Or should we just tell folks to curl?

You should be able to download your config from the API,
and it should define a functional UI:
```bash
echo http://localhost:8888/api/v1/viewconfs/?d=$ID
echo http://localhost:8888/?config=$ID
```

Visit that URL to see your data in HiGlass.


## Deployment

Only one Docker container is required, but in production, you'll probably
want other containers for nginx, redis, etc. Our current
[deployment strategy](README-DEPLOY.md) wraps up most of the details in the
`build.sh` script.


## Development

To develop [higlass-client](https://github.com/hms-dbmi/higlass) and
[higlass-server](https://github.com/hms-dbmi/higlass-server),
check out the corresponding repos. 

To work on the Docker deployment, checkout this repo, install Docker, and then:

```bash
./test_runner.sh

# You can see the containers that it has started:
docker ps

# and you can connect to a running container:
docker exec --interactive --tty container-TIMESTAMP bash

# or remove all containers (use with caution):
docker ps -a -q | xargs docker stop | xargs docker rm
```


## Releasing updates

Travis will update `latest` on DockerHub with every successful run
with the name of the branch. This is used as a cache to speed up builds.

If it's tagged (ie `git tag v0.0.x && git push origin --tags`),
then that version number will be pushed to DockerHub.

If it's a PR, several informative tag names will be pushed:
- Branch name
- Git hash
- Travis run
