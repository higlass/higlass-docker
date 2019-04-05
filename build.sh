#!/usr/bin/env bash
set -e

STAMP='default'

WEB_APP_VERSION='1.1.0'
HIPILER_VERSION='1.3.1'
SERVER_VERSION='1.10.2'
LIBRARY_VERSION='1.5.2'
MULTIVEC_VERSION='0.2.0'
CLODIUS_VERSION='0.10.4'
TIME_INTERVAL_TRACK_VERSION='0.2.0-rc.2'

usage() {
  echo "USAGE: $0 -w WORKERS [-s STAMP] [-l]" >&2
  exit 1
}

while getopts 's:w:l' OPT; do
  case $OPT in
    s)
      STAMP=$OPTARG
      ;;
    w)
      WORKERS=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z $WORKERS ]; then
  usage
fi

set -o verbose # Keep this after the usage message to reduce clutter.

# modify web-context/Dockerfile.template
perl -pne "s/<TIME_INTERVAL_TRACK_VERSION>/$TIME_INTERVAL_TRACK_VERSION/g; s/<CLODIUS_VERSION>/$CLODIUS_VERSION/g; s/<HGTILES_VERSION>/$HGTILES_VERSION/g; s/<MULTIVEC_VERSION>/$MULTIVEC_VERSION/g; s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<WEB_APP_VERSION>/$WEB_APP_VERSION/g; s/<LIBRARY_VERSION>/$LIBRARY_VERSION/g; s/<HIPILER_VERSION>/$HIPILER_VERSION/g" \
          web-context/Dockerfile.template > web-context/Dockerfile

echo "Used AWS buckets are:"
echo $AWS_BUCKET
echo $AWS_BUCKET2
echo $AWS_BUCKET3
echo $AWS_BUCKET4

# 4dn uses our own higlass-docker image
REPO=4dndcic/higlass-docker
docker pull $REPO # Defaults to "latest", but just speeds up the build, so precise version doesn't matter.
#docker build --cache-from image-$STAMP \
docker build --cache-from $REPO \
             --build-arg WORKERS=$WORKERS \
	         --build-arg KEY=$AWS_ACCESS_KEY_ID \
	         --build-arg SECRET=$AWS_SECRET_ACCESS_KEY \
	         --build-arg BUCKET=$AWS_BUCKET \
	         --build-arg BUCKET2=$AWS_BUCKET2 \
             --build-arg BUCKET3=$AWS_BUCKET3 \
	         --build-arg BUCKET4=$AWS_BUCKET4 \
             --tag image-$STAMP \
             web-context

rm web-context/Dockerfile # Ephemeral: We want to prevent folks from editing it by mistake.
