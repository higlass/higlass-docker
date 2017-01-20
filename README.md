# higlass-docker

Builds a docker container wrapping 
[higlass-server](https://github.com/hms-dbmi/higlass-server) and 
[higlass-client](https://github.com/hms-dbmi/higlass) in nginx,
tests that it works, and if there are no errors in the PR,
pushes the image to [DockerHub](https://hub.docker.com/r/gehlenborglab/higlass-server/).

For development, checkout this repo, install Docker, and then:

```bash
# build:
docker build --tag higlass-image .

# run:
#   Port 8000 is hardcoded in the image;
#   Port 8001 is what it should be mapped to on the host.
docker run --name higlass-container --detach --publish 8001:8000 higlass-image
curl http://localhost:8001/

# connect to an already running container:
docker exec --interactive --tty higlass-container bash

# remove all containers (use with caution):
docker ps -a -q | xargs docker stop | xargs docker rm
```
