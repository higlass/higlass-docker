# higlass-docker

Builds a docker container wrapping higlass-client and higlass-server in nginx,
tests that it works, and if there are no errors in the PR, pushes the image to 
[DockerHub](https://hub.docker.com/r/gehlenborglab/higlass-server/).

## Running

You can see HiGlass in action at [higlass.gehlenborglab.org](http://higlass.gehlenborglab.org/).

It is also easy to launch your own. Install Docker, and then:
```
docker pull gehlenborglab/higlass-server
docker run --detach --publish 8001:8000 gehlenborglab/higlass-server
```

Then visit [localhost:8001](http://localhost:8001/) in your browser.


## Developing

To develop [higlass-client](https://github.com/hms-dbmi/higlass) and
[higlass-server](https://github.com/hms-dbmi/higlass-server),
check out the corresponding repos. 

To work on the Docker deployment, checkout this repo, install Docker, and then:

```bash
# build:
docker build --tag higlass-image .

# run:
#   Port 8000 is hardcoded in the image;
#   Port 8001 is what it should be mapped to on the host.
docker run --name higlass-container --detach --publish 8001:8000 higlass-image

# test:
curl http://localhost:8001/

# If that doesn't work, look at the logs:
docker logs higlass-container

# or connect to an already running container:
docker exec --interactive --tty higlass-container bash

# remove all containers (use with caution):
docker ps -a -q | xargs docker stop | xargs docker rm
```
