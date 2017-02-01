#!/usr/bin/env bash
set -e
# DO NOT set -x: We do not want to risk credentials in travis logs.

error_report() {
  docker logs container-$STAMP
}

trap 'error_report' ERR

STAMP=`date +"%Y-%m-%d_%H-%M-%S"`

while getopts 'dp:v:' OPT; do
  case $OPT in
    p)
      PORT=$OPTARG
      ;;
    v)
      VOLUME=$OPTARG
      ;;
    d)
      PORT=0 # Kernel will assign randomly.
      VOLUME=/tmp/higlass-docker/volume-$STAMP
      ;;
  esac
done

if [ -z $PORT ] || [ -z $VOLUME ]; then
  echo \
"USAGE: $0 -d              # For defaults, or...
       $0 -pPORT -vVOLUME # If one is given, all are required." >&2
  exit 1
fi

set -o verbose # Keep this after the usage message to reduce clutter.

REDIS_HOST=redis
docker run --hostname $REDIS_HOST --detach redis:3.2.7-alpine

REPO=gehlenborglab/higlass-server
docker pull $REPO:latest
docker build --cache-from $REPO:latest \
             --build-arg WORKERS=2 \
             --tag image-$STAMP \
             web-context

mkdir -p $VOLUME
DB=/tmp/higlass-docker/db-$STAMP.sqlite3
touch $DB
docker run --name container-$STAMP \
           --publish $PORT:80 \
           --volume $VOLUME:/home/higlass/projects/higlass-server/data \
           --volume $DB:/home/higlass/projects/higlass-server/db.sqlite3 \
           --env REDIS_HOST=$REDIS_HOST \
           --env REDIS_PORT=6379 \
           --detach --publish-all image-$STAMP
docker ps -a

export STAMP
export PORT
./test.sh