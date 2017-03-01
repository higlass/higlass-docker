# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass/).

## Running locally

You can see HiGlass in action at [higlass.io](http://higlass.io/).

It is also easy to launch your own. Install Docker, and then:
```bash
docker run --detach \
           --publish 8888:80 \
           --volume ~/hg-data:/data \
           --volume ~/hg-tmp:/tmp \
           --name higlass-container \
           gehlenborglab/higlass:v0.0.15
```
The two `--volume` options are necessary to prevent the files you upload from consuming
all of relatively small space allocated for the root volume.

For ingest, you'll need to put your files in one of the shared directories: Then it will
be available to scripts running inside the container.
```bash
# For example...
COOLER=dixon2012-h1hesc-hindiii-allreps-filtered.1000kb.multires.cool 
wget -P ~/hg-tmp https://s3.amazonaws.com/pkerp/public/$COOLER

# Confirm that the file is visible inside the container:
docker exec higlass-container ls /tmp

# Ingest:
ID=cooler-demo
docker exec higlass-container python higlass-server/manage.py ingest_tileset --filename /tmp/$COOLER --filetype cooler --datatype matrix --uid $ID
```

You can now hit the API to confirm that the file was ingested successfully:
```
# Summary:
curl http://localhost:8888/api/v1/tileset_info/?d=$ID
# Details:
curl http://localhost:8888/api/v1/tiles/?d=$ID.0.0.0
```

The default viewconfig points to UIDs which won't be on a new instance,
so you'll need a new empty viewconfig:
```json
{TODO: minimal viewconfig, or have default install be empty}
```

Then load it via the API:
```bash
ID=$(docker exec higlass-container ./create_viewconf.sh "`cat  your-config.json`")
```
**TODO**: This is ugly. Could it read stdin? Or should we just tell folks to curl?

You should be able to download your viewconfig from the API,
and it should define a functional UI:
```bash
echo http://localhost:8888/api/v1/viewconfs/?d=$ID
echo http://localhost:8888/?config=$ID
```

Visit that URL to see an empty HiGlass.

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

You data is now available, and you can add it to a view in the UI.


## Deployment

Only one Docker container is required, but in production, you'll probably
want other containers for nginx, redis, etc. Docker Compose is the usual tool
for this, but at the present it does not support an analog to the `--from-cache`
option. Instead, for the moment, we are doing this:
```
curl https://raw.githubusercontent.com/hms-dbmi/higlass-docker/v0.0.8/start_production.sh | bash
```

For more details, read [README-DEPLOY](README-DEPLOY.md).


## Development

To develop [higlass-client](https://github.com/hms-dbmi/higlass) and
[higlass-server](https://github.com/hms-dbmi/higlass-server),
check out the corresponding repos. 

To work on the Docker deployment, checkout this repo, install Docker, and then:

```bash
./test_runner.sh

# You can see the containers that have started:
docker ps

# View all the logs from the container:
docker exec container-TIMESTAMP ./logs.sh

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
