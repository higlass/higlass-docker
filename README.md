# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass/).

## Running locally

You can see HiGlass in action at [higlass.io](http://higlass.io/).

It is also easy to launch your own. Install Docker, and then:
```
docker run --detach --publish 8888:80 gehlenborglab/higlass:v0.0.3
```

Then visit [localhost:8888](http://localhost:8888/) in your browser.


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
./build.sh -l

# If that doesn't work, check the port mapping:
docker ps

# and then check the logs
docker logs container-TIMESTAMP

# or connect to an already running container:
docker exec --interactive --tty container-TIMESTAMP bash

# remove all containers (use with caution):
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
