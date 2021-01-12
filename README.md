[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1308947.svg)](https://doi.org/10.5281/zenodo.1308947)

# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to
[DockerHub](https://hub.docker.com/r/higlass/higlass-docker/).

## Running Locally

You can see HiGlass in action at [higlass.io](http://higlass.io/).

It is also easy to launch your own. Install Docker, and then:
```bash
docker pull higlass/higlass-docker # Ensure that you have the latest.
docker run --detach \
           --publish 8888:80 \
           --volume ~/hg-data:/data \
           --volume ~/hg-tmp:/tmp \
           --name higlass-container \
           higlass/higlass-docker
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
docker exec higlass-container python higlass-server/manage.py ingest_tileset --filename /tmp/$COOLER --filetype cooler --datatype matrix
```

You can now hit the API to confirm that the file was ingested successfully by
first listing the available tilesets

```
curl http://localhost:8888/api/v1/tilesets/
```

And then trying to actually get some data from the tileset. In the examples
below, $ID is the uuid shown in the list of tilesets above.

```
# Summary:
curl http://localhost:8888/api/v1/tileset_info/?d=$ID
# Details:
curl http://localhost:8888/api/v1/tiles/?d=$ID.0.0.0
```

### Troubleshooting

* Error to launch the container because the container name is already in use (`docker: Error response from daemon: Conflict. The container name "/higlass-container" is already in use by container ...`). Use `docker rm higlass-container` and launch the container again.


### Django admin interface

The admin interface lets you interact with and inspect the data stored in the local higlass instance.
To access the admin interface you need to first create an admin user:

```bash
docker exec -it higlass-container higlass-server/manage.py createsuperuser
```

The admin interface can then be accessed at: `http://localhost:8888/admin/`

## Deployment

Only one Docker container is required, but in production, you'll probably
want other containers for nginx, redis, etc. Docker Compose is the usual tool
for this, but at the present it does not support an analog to the `--from-cache`
option. Instead, for the moment, we are doing this:
```
curl https://raw.githubusercontent.com/hms-dbmi/higlass-docker/start_production.sh | bash
```

For more details, read [README-DEPLOY](README-DEPLOY.md).


## Development

To develop [higlass-client](https://github.com/higlass/higlass) and
[higlass-server](https://github.com/higlass/higlass-server),
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

To manually test the a new image at http://localhost:8888 run:

```bash
./test_build.sh <NAME>

# You can log into the instance with:
docker exec -it cont-<NAME> bash
```


## Releasing updates

The CI workflow automatically pushes new builds to Dockerhub. All that's necessary is to update the changelog bump the version number and push to master:

1. Switch to master branch. Update the CHANGELOG to make sure the latest entry is labelled with the upcoming version number.

2. Bump the version number:

```
bumpversion [patch,minor,major]
```

3. Push the branch and tags to GitHub. This will kick off the build and release CI workflow.

```
git push origin master --tags
```


## License

The code in this repository is provided under the MIT License.
