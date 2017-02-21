#!/usr/bin/env bash
set -e

docker_version() {
  grep DOCKER_VERSION start_production.sh \
    | head -n1 \
    | perl -pne 's/.*=//'
}

STAMP='default'
DOCKER_VERSION=$(docker_version)
SERVER_VERSION='0.2.4' # python latest.py hms-dbmi/higlass-server
WEBSITE_VERSION='0.5.5' # python latest.py hms-dbmi/higlass-website

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
    l)
      DOCKER_VERSION='latest'
      SERVER_VERSION=`python latest.py hms-dbmi/higlass-server` \
        || ( echo "'sudo pip install requests' should fix this."; exit 1 )
      WEBSITE_VERSION=`python latest.py hms-dbmi/higlass-website`
      echo "SERVER_VERSION: $SERVER_VERSION"
      echo "WEBSITE_VERSION: $WEBSITE_VERSION"
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
perl -pne "s/<SERVER_VERSION>/$SERVER_VERSION/g; s/<WEBSITE_VERSION>/$WEBSITE_VERSION/g;" \
          web-context/Dockerfile.template > web-context/Dockerfile

REPO=gehlenborglab/higlass
docker pull $REPO:$DOCKER_VERSION
docker build --cache-from $REPO:$DOCKER_VERSION \
             --build-arg WORKERS=$WORKERS \
             --tag image-$STAMP \
             web-context

rm web-context/Dockerfile # Ephemeral: We want to prevent folks from editing it by mistake.

