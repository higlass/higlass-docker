#!/usr/bin/env bash
set -e

error_report() {
  docker ps -a
  docker logs container-$STAMP$SUFFIX
  docker exec -it container-$STAMP$SUFFIX /home/higlass/projects/logs.sh
}

trap 'error_report' ERR

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
./build.sh -l -w 2 -s $STAMP


test_standalone() {
    SUFFIX=-standalone
    docker run --name container-$STAMP$SUFFIX \
               --detach \
               --publish-all \
               image-$STAMP

    ./test_suite.sh $STAMP $SUFFIX
}

test_redis() {
    docker network create --driver bridge network-$STAMP

    VOLUME=/tmp/higlass-docker/volume-$STAMP
    for DIR in redis-data hg-data/log hg-tmp; do
      mkdir -p $VOLUME/$DIR || echo "$VOLUME/$DIR already exists"
    done

    REDIS_HOST=container-redis-$STAMP

    docker run --name $REDIS_HOST \
               --network network-$STAMP \
               --volume $VOLUME/redis-data:/data \
               --detach redis:3.2.7-alpine \
               redis-server

    SUFFIX=-with-redis
    docker run --name container-$STAMP$SUFFIX \
               --network network-$STAMP \
               --volume $VOLUME/hg-data:/data \
               --volume $VOLUME/hg-tmp:/tmp \
               --env REDIS_HOST=$REDIS_HOST \
               --env REDIS_PORT=6379 \
               --detach \
               --publish-all \
               image-$STAMP

    ./test_suite.sh $STAMP $SUFFIX
}

test_standalone
test_redis