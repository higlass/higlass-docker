#!/usr/bin/env bash
set -e
# DO NOT set -x: We do not want credentials in travis logs.

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

# $PORT may be 0 if defaults were used, so we do need to look it up.
PORT=`docker port container-$STAMP | perl -pne 's/.*://'`
URL=http://localhost:$PORT/api/v1/tilesets/

set +o verbose # Less clutter on test output
echo
echo "## TESTS ##"
echo
echo "If tests fail, or $URL doesn't work, try:"
echo "  docker exec --interactive --tty container-$STAMP bash"

set +e # So we don't exit travis, instead of exiting the loop.
TRY=0;
until $(curl --output /dev/null --silent --fail --globoff $URL) || [[ $TRY -gt 20 ]]; do
    echo "try $TRY"
    (( TRY++ ))
    sleep 1
done
set -e

JSON=`curl -s $URL`
echo "API: $JSON"
HTML=`curl -s http://localhost:$PORT/`
echo "homepage: $HTML" | head -c 200

[ "$JSON" == '{"count": 0, "results": []}' ] \
    && ( echo $HTML | grep -o 'HiGlass' ) \
    && ( echo $HTML | grep -o 'Peter Kerpedjiev' ) \
    && ( echo $HTML | grep -o 'Department of Biomedical Informatics' ) \
    && echo && echo 'PASS!' \
    && echo "  visit:   http://localhost:$PORT" \
    && echo "  connect: docker exec --interactive --tty container-$STAMP bash" \
    && echo "  volume:  $VOLUME" \
    && echo "  db:      $DB"
