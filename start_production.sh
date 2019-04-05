#!/usr/bin/env bash
set -e
set -v

# Docker image is pinned here, so that you can checkout older
# versions of this script, and get reproducible deployments.
# DOCKER_VERSION is the version of 4dndcic/higlass-docker
DOCKER_VERSION=v0.0.1
IMAGE=4dndcic/higlass-docker:$DOCKER_VERSION
STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
PORT=80

# NOTE: No parameters should change the behavior in a deep way:
# We want the tests to cover the same setup as in production.

usage() {
  echo "USAGE: $0 [-i IMAGE] [-s STAMP] [-p PORT] [-v VOLUME]" >&2
  exit 1
}

while getopts 'i:s:p:v:' OPT; do
  case $OPT in
    i)
      IMAGE=$OPTARG
      ;;
    s)
      STAMP=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    v)
      VOLUME=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$VOLUME" ]; then
    VOLUME=/tmp/higlass-docker/volume-$STAMP-with-redis
fi

docker network create --driver bridge network-$STAMP

# Create all directories we need. These will be mounted to data, so really
# /hg-data/media/$AWS_BUCKET is /data/media/$AWS_BUCKET, for example
for DIR in redis-data hg-data/log hg-tmp hg-data/media hg-data/media/$AWS_BUCKET hg-data/media/$AWS_BUCKET2 hg-data/media/$AWS_BUCKET3 hg-data/media/$AWS_BUCKET4; do
  mkdir -p $VOLUME/$DIR || echo "$VOLUME/$DIR already exists"
done

REDIS_HOST=container-redis-$STAMP

# TODO: Should probably make a Dockerfile if configuration gets any more complicated.
SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )
REDIS_CONF=/usr/local/etc/redis/redis.conf
docker run --name $REDIS_HOST \
           --network network-$STAMP \
           --volume $VOLUME/redis-data:/data \
           --volume $SCRIPT_DIR/redis-context/redis.conf:$REDIS_CONF \
           --detach redis:5.0.3-alpine \
           redis-server $REDIS_CONF

docker run --name container-$STAMP-with-redis \
           --network network-$STAMP \
           --publish $PORT:80 \
           --volume $VOLUME/hg-data:/data \
           --volume $VOLUME/hg-tmp:/tmp \
           --env REDIS_HOST=$REDIS_HOST \
           --env REDIS_PORT=6379 \
	       --privileged \
           --detach \
           --publish-all \
           $IMAGE
