#!/usr/bin/env bash
set -e

STAMP='default'
SERVER_VERSION='1.5.2'
WEB_APP_VERSION='0.9.2'
LIBRARY_VERSION='1.2.3'
HIPILER_VERSION='1.1.7'

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

# When development settles down, consider going back to static Dockerfile.
perl -pne "s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<WEB_APP_VERSION>/$WEB_APP_VERSION/g; s/<LIBRARY_VERSION>/$LIBRARY_VERSION/g; s/<HIPILER_VERSION>/$HIPILER_VERSION/g" \
          web-context/Dockerfile.template > web-context/Dockerfile

REPO=gehlenborglab/higlass
docker pull $REPO # Defaults to "latest", but just speeds up the build, so precise version doesn't matter.
docker build --cache-from $REPO \
             --build-arg WORKERS=$WORKERS \
             --tag image-$STAMP \
             web-context

rm web-context/Dockerfile # Ephemeral: We want to prevent folks from editing it by mistake.

