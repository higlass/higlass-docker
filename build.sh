#!/usr/bin/env bash
set -e
# DO NOT set -x: We do not want to risk credentials in travis logs.

error_report() {
  docker logs container-$STAMP
}

trap 'error_report' ERR

STAMP='default'
SERVER_VERSION=0.2.4 # python latest.py hms-dbmi/higlass-server
WEBSITE_VERSION=0.3.15 # python latest.py hms-dbmi/higlass-website

while getopts 'dlp:v:w:' OPT; do
  case $OPT in
    p)
      PORT=$OPTARG
      ;;
    v)
      VOLUME=$OPTARG
      ;;
    w)
      WORKERS=$OPTARG
      ;;
    d)
      PORT=8080
      VOLUME=/tmp/higlass-docker/volume-$STAMP
      WORKERS=2
      ;;
    l)
      STAMP=`date +"%Y-%m-%d_%H-%M-%S"`
      SERVER_VERSION=`python latest.py hms-dbmi/higlass-server` \
        || ( echo "'sudo pip install requests' should fix this."; exit 1 )
      WEBSITE_VERSION=`python latest.py hms-dbmi/higlass-website`
      echo "SERVER_VERSION: $SERVER_VERSION"
      echo "WEBSITE_VERSION: $WEBSITE_VERSION"
      PORT=0 # Kernel will assign randomly.
      VOLUME=/tmp/higlass-docker/volume-$STAMP
      WORKERS=2
  esac
done

mkdir -p $VOLUME/log || echo "Log directory already exists"

if [ -z $PORT ] || [ -z $VOLUME ] || [ -z $WORKERS ]; then
  echo \
"USAGE: $0 -d                           # For a stable default build
       $0 -l                           # Pull the latest dependencies, and timestamp container
       $0 -p PORT -v VOLUME -w WORKERS # If one is given, all are required." >&2
  exit 1
fi

set -o verbose # Keep this after the usage message to reduce clutter.

docker network create --driver bridge network-$STAMP

docker run --name container-redis-$STAMP \
           --network network-$STAMP \
           --volume $VOLUME:/data \
           --detach redis:3.2.7-alpine \
            redis-server 

# When development settles down, consider going back to static Dockerfile.
perl -pne "s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<WEBSITE_VERSION>/$WEBSITE_VERSION/g;" \
          web-context/Dockerfile.template > web-context/Dockerfile

REPO=gehlenborglab/higlass
docker pull $REPO:latest
docker build --cache-from $REPO:latest \
             --build-arg WORKERS=$WORKERS \
             --build-arg SERVER_VERSION=$SERVER_VERSION \
             --build-arg WEBSITE_VERSION=$WEBSITE_VERSION \
             --tag image-$STAMP \
             web-context

mkdir -p $VOLUME
docker run --name container-$STAMP \
           --network network-$STAMP \
           --publish $PORT:80 \
           --volume $VOLUME:/data \
           --volume $VOLUME/tmp:/tmp \
           --env REDIS_HOST=container-redis-$STAMP \
           --env REDIS_PORT=6379 \
           --detach --publish-all image-$STAMP


docker ps -a

export STAMP
export PORT
./test.sh
