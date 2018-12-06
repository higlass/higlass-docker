#!/usr/bin/env bash
set -e

export STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

while getopts 's:w:l' OPT; do
  case $OPT in
    s)
      STAMP=$OPTARG
      ;;
  esac
done

echo "stamp:", $STAMP

./build.sh -w 4 -s $STAMP

test_standalone() {
    # Keep this simple: We want folks just to be able to run the bare Docker container.
    # If this starts to get sufficiently complicated that we want to put it in a script
    # by itself, then it has gotten too complicated.
    export SUFFIX=-standalone
    echo "image-$STAMP"
    echo "container-$STAMP$SUFFIX"
    docker stop container-$STAMP$SUFFIX || true
    docker rm container-$STAMP$SUFFIX || true
    docker run --name container-$STAMP$SUFFIX \
               --detach \
               --publish-all \
               image-$STAMP
    python tests.py
}

test_redis() {
    export SUFFIX=-with-redis
    ./start_production.sh -s $STAMP -i image-$STAMP
    python tests.py
}

test_standalone
