DOCKER_VERSION='0.10.4'
REPO=higlass/higlass-docker

sudo docker login -u $DOCKER_USER -p $DOCKER_PASS
sudo docker push ${REPO}:${DOCKER_VERSION}
sudo docker push ${REPO}:latest
