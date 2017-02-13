#!/usr/bin/env bash
set -e

STAMP='default'
SERVER_VERSION=0.2.4 # python latest.py hms-dbmi/higlass-server
WEBSITE_VERSION=0.4.1 # python latest.py hms-dbmi/higlass-website
TAG='latest'

while getopts 's:w:l' OPT; do
  case $OPT in
    s)
      STAMP=$OPTARG
      ;;
    w)
      WORKERS=$OPTARG
      ;;
    l)
      SERVER_VERSION=`python latest.py hms-dbmi/higlass-server` \
        || ( echo "'sudo pip install requests' should fix this."; exit 1 )
      WEBSITE_VERSION=`python latest.py hms-dbmi/higlass-website`
      echo "SERVER_VERSION: $SERVER_VERSION"
      echo "WEBSITE_VERSION: $WEBSITE_VERSION"
  esac
done

if [ -z $WORKERS ]; then
  echo "USAGE: $0 [-l] -w WORKERS" >&2
  exit 1
fi

set -o verbose # Keep this after the usage message to reduce clutter.

# When development settles down, consider going back to static Dockerfile.
perl -pne "s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<WEBSITE_VERSION>/$WEBSITE_VERSION/g;" \
          web-context/Dockerfile.template > web-context/Dockerfile

REPO=gehlenborglab/higlass
docker pull $REPO:$TAG
docker build --cache-from $REPO:$TAG \
             --build-arg WORKERS=$WORKERS \
             --tag image-$STAMP \
             web-context

rm web-context/Dockerfile # Ephemeral: We want to prevent folks from editing it by mistake.

