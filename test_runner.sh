#!/usr/bin/env bash
set -e

error_report() {
  docker ps -a
  docker logs container-$STAMP$SUFFIX
  docker exec -it container-$STAMP$SUFFIX /home/higlass/projects/logs.sh
}

trap 'error_report' ERR

export STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
./build.sh -l -w 4 -s $STAMP


test_standalone() {
    # Keep this simple: We want folks just to be able to run the bare Docker container.
    # If this starts to get sufficiently complicated that we want to put it in a script
    # by itself, then it has gotten too complicated.
    export SUFFIX=-standalone
    docker run --name container-$STAMP$SUFFIX \
               --detach \
               --publish-all \
               image-$STAMP

    ./test_suite.sh $STAMP $SUFFIX
    python tests.py
}

test_redis() {
    SUFFIX=-with-redis
    ./start_production.sh -s $STAMP -i image-$STAMP
    ./test_suite.sh $STAMP $SUFFIX
    python tests.py
}

test_standalone
test_redis