#!/usr/bin/env bash
set -e
# DO NOT set -x: We do not want to risk credentials in travis logs.

error_report() {
  docker logs container-$STAMP
}

trap 'error_report' ERR

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

while getopts 'dp:v:w:' OPT; do
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
      PORT=0 # Kernel will assign randomly.
      VOLUME=/tmp/higlass-docker/volume-$STAMP
      WORKERS=2
      ;;
  esac
done

mkdir -p $VOLUME/log || echo "Log directory already exists"

if [ -z $PORT ] || [ -z $VOLUME ] || [ -z $WORKERS ]; then
  echo \
"USAGE: $0 -d              # For defaults, or...
       $0 -pPORT -vVOLUME -wWORKERS # If one is given, all are required." >&2
  exit 1
fi

set -o verbose # Keep this after the usage message to reduce clutter.

docker network create --driver bridge network-$STAMP

REDIS_HOST=redis
docker run --hostname $REDIS_HOST \
           --network network-$STAMP \
           --detach redis:3.2.7-alpine

REPO=gehlenborglab/higlass-server
docker pull $REPO:latest
docker build --cache-from $REPO:latest \
             --build-arg WORKERS=$WORKERS \
             --tag image-$STAMP \
             web-context

mkdir -p $VOLUME
docker run --name container-$STAMP \
           --publish $PORT:80 \
           --network network-$STAMP \
           --volume $VOLUME:/data \
           --env REDIS_HOST=$REDIS_HOST \
           --env REDIS_PORT=6379 \
           --detach --publish-all image-$STAMP
docker ps -a

export STAMP
export PORT
./test.sh
