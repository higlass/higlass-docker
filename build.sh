#!/usr/bin/env bash
set -e
# DO NOT set -x: We do not want to risk credentials in travis logs.

error_report() {
  echo
  echo "docker logs redis-container-$STAMP:"
  docker logs redis-container-$STAMP

  echo
  echo "docker logs higlass-stable-name:"
  docker logs higlass-stable-name

  echo
  echo "docker logs nginx-container-$STAMP:"
  docker logs nginx-container-$STAMP
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
"USAGE: $0 -d                           # For defaults, or...
       $0 -p PORT -v VOLUME -w WORKERS # If one is given, all are required." >&2
  exit 1
fi

set -o verbose # Keep this after the usage message to reduce clutter.


# Network
docker network create --driver bridge network-$STAMP


# Redis
docker run --name redis-container-$STAMP \
           --network network-$STAMP \
           --detach redis:3.2.7-alpine


# HiGlass
HG_HOST=higlass
REPO=gehlenborglab/higlass-server
docker pull $REPO:latest
docker build --cache-from $REPO:latest \
             --build-arg WORKERS=$WORKERS \
             --tag hg-image-$STAMP \
             hg-context
mkdir -p $VOLUME
# TODO: Going to have name collisions, but envvars in nginxconf is tricky.
# --name hg-container-$STAMP \
docker run --name higlass-stable-name \
           --network network-$STAMP \
           --hostname $HG_HOST \
           --volume $VOLUME:/data \
           --volume $VOLUME/tmp:/tmp \
           --env REDIS_HOST=container-redis-$STAMP \
           --env REDIS_PORT=6379 \
           --detach \
           hg-image-$STAMP


# Nginx
docker build --tag nginx-image-$STAMP nginx-context
docker run --name nginx-container-$STAMP \
           --network network-$STAMP \
           --publish $PORT:80 \
           --detach \
           --publish-all \
           nginx-image-$STAMP




docker ps -a | grep $STAMP

./test.sh $STAMP
