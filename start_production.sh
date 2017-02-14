#!/usr/bin/env bash
set -e
set -v

IMAGE=gehlenborglab/higlass:latest
STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
PORT=0

# NOTE: No parameters should change the behavior in a deep way:
# We want the tests to cover the same setup as in production.

while getopts 'i:s:p:v:n:' OPT; do
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
  esac
done

if [ -z "$VOLUME" ]; then
    VOLUME=/tmp/higlass-docker/volume-$STAMP-with-redis
fi

docker network create --driver bridge network-$STAMP

for DIR in redis-data hg-data/log hg-tmp; do
  mkdir -p $VOLUME/$DIR || echo "$VOLUME/$DIR already exists"
done

REDIS_HOST=container-redis-$STAMP

docker run --name $REDIS_HOST \
           --network network-$STAMP \
           --volume $VOLUME/redis-data:/data \
           --detach redis:3.2.7-alpine \
           redis-server

docker run --name container-$STAMP-with-redis \
           --network network-$STAMP \
           --publish $PORT:80 \
           --volume $VOLUME/hg-data:/data \
           --volume $VOLUME/hg-tmp:/tmp \
           --env REDIS_HOST=$REDIS_HOST \
           --env REDIS_PORT=6379 \
           --detach \
           --publish-all \
           $IMAGE